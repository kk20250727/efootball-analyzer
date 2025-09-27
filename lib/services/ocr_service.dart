import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'match_parser_service.dart';
import 'performance_service.dart';
import 'cache_service.dart';

/// OCRサービス - Google ML Kit Text Recognitionを使用
class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  
  /// 複数画像の選択
  static Future<List<XFile>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickMultiImage();
  }

  /// 画像からテキストを認識
  static Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR処理に失敗しました: $e');
    }
  }
  
  /// XFileからテキストを認識（Web対応版）
  static Future<String> recognizeTextFromXFile(XFile imageFile) async {
    return await PerformanceService.measureAsync('OCR処理', () async {
      try {
        // 画像ハッシュ値を生成してキャッシュをチェック
        final imageBytes = await imageFile.readAsBytes();
        final imageHash = _generateImageHash(imageBytes);
        
        // キャッシュから結果を取得
        final cachedResult = CacheService.getCachedOCRResult(imageHash);
        if (cachedResult != null) {
          debugPrint('🔄 OCRキャッシュヒット: ${imageFile.name}');
          return cachedResult;
        }
        
        debugPrint('🔍 新規OCR処理開始: ${imageFile.name}');
        
        // Web環境での特別処理
        if (kIsWeb) {
          print('Web環境でのOCR処理開始');
          return await _recognizeTextWeb(imageFile);
        }
        
        // モバイル環境での通常処理
        final inputImage = InputImage.fromFilePath(imageFile.path);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        
        // eFootball用のテキスト前処理
        String processedText = _processEFootballText(recognizedText);
        
        // 結果をキャッシュに保存
        await CacheService.cacheOCRResult(imageHash, processedText);
        
        debugPrint('=== OCR処理結果 ===');
        debugPrint('画像パス: ${imageFile.path}');
        debugPrint('画像ハッシュ: $imageHash');
        debugPrint('検出されたブロック数: ${recognizedText.blocks.length}');
        debugPrint('生テキスト:\n${recognizedText.text}');
        debugPrint('処理後テキスト:\n$processedText');
        
        return processedText;
      } catch (e) {
        debugPrint('OCR処理エラー: $e');
        throw Exception('OCR処理に失敗しました: $e');
      }
    });
  }
  
  /// 複数画像のテキスト認識（エラーハンドリング強化版）
  static Future<List<String>> recognizeMultipleImages(List<XFile> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw ArgumentError('画像ファイルが選択されていません');
    }
    
    final List<String> results = [];
    final List<String> errorMessages = [];
    int successCount = 0;
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('画像 ${i + 1}/${imageFiles.length} を処理中...');
        
        // ファイルサイズチェックと圧縮（10MB制限）
        Uint8List bytes = await imageFiles[i].readAsBytes();
        if (bytes.length > 10 * 1024 * 1024) {
          debugPrint('ファイルサイズが大きいため圧縮を試みます: ${bytes.length} bytes');
          bytes = await _compressImage(bytes);
          if (bytes.length > 10 * 1024 * 1024) {
            throw Exception('圧縮後もファイルサイズが10MBを超えています');
          }
          debugPrint('圧縮後サイズ: ${bytes.length} bytes');
        }
        
        // ファイル形式チェック
        final fileName = imageFiles[i].name.toLowerCase();
        if (!fileName.endsWith('.jpg') && 
            !fileName.endsWith('.jpeg') && 
            !fileName.endsWith('.png')) {
          throw Exception('サポートされていないファイル形式です（JPG/PNG のみ対応）');
        }
        
        final text = await recognizeTextFromXFile(imageFiles[i]);
        
        // 空のテキスト結果をチェック
        if (text.trim().isEmpty) {
          debugPrint('警告: 画像 ${i + 1} からテキストが検出されませんでした');
          results.add('');
          errorMessages.add('画像 ${i + 1}: テキストが検出されませんでした');
        } else {
          results.add(text);
          successCount++;
          debugPrint('成功: 画像 ${i + 1} から ${text.length}文字のテキストを抽出');
        }
        
      } catch (e) {
        final errorMsg = '画像 ${i + 1} の処理でエラー: $e';
        debugPrint(errorMsg);
        errorMessages.add(errorMsg);
        results.add('');
      }
    }
    
    // 結果サマリーを出力
    debugPrint('=== OCR処理完了サマリー ===');
    debugPrint('処理対象: ${imageFiles.length}枚');
    debugPrint('成功: ${successCount}枚');
    debugPrint('失敗: ${imageFiles.length - successCount}枚');
    
    if (errorMessages.isNotEmpty) {
      debugPrint('エラー詳細:');
      for (final error in errorMessages) {
        debugPrint('  - $error');
      }
    }
    
    // すべて失敗した場合は例外をスロー
    if (successCount == 0) {
      throw Exception('すべての画像でOCR処理に失敗しました:\n${errorMessages.join('\n')}');
    }
    
    // 部分的失敗の場合は警告を出力
    if (successCount < imageFiles.length) {
      debugPrint('警告: ${imageFiles.length - successCount}枚の画像でOCR処理に失敗しました');
    }
    
    return results;
  }
  
  /// 画像を処理してParsedMatchDataを返す
  static Future<List<Map<String, dynamic>>> processImages(List<XFile> imageFiles, String userEfootballUsername) async {
    try {
      final ocrResults = await recognizeMultipleImages(imageFiles);
      final allMatchData = <Map<String, dynamic>>[];
      
      for (int i = 0; i < ocrResults.length; i++) {
        final ocrText = ocrResults[i];
        if (ocrText.trim().isEmpty) continue;
        
        final parsedData = MatchParserService.parseMatchData(ocrText, userEfootballUsername);
        allMatchData.addAll(parsedData);
      }
      
      return allMatchData;
    } catch (e) {
      debugPrint('OCR処理エラー: $e');
      throw Exception('OCR処理に失敗しました: $e');
    }
  }

  /// Web環境でのテキスト認識（フォールバック）
  static Future<String> _recognizeTextWeb(XFile imageFile) async {
    // Web環境ではGoogle ML Kitが制限されるため、フォールバック処理
    print('Web環境でのOCR処理: ${imageFile.name}');
    throw UnimplementedError('Web環境でのOCR機能は現在サポートされていません。モバイル版をご利用ください。');
  }

  /// eFootball特有のOCRエラー修正（大幅強化）
  static String _correctEFootballOCRErrors(String text) {
    String correctedText = text;
    
    // 全角→半角変換（数字）
    final numberMap = {
      '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
      '５': '5', '６': '6', '７': '7', '８': '8', '９': '9'
    };
    
    // 全角→半角変換（記号）
    final symbolMap = {
      'ー': '-', '－': '-', '―': '-', '‐': '-',
      '：': ':', '；': ';', '？': '?', '！': '!',
      '／': '/', '＼': '\\', '｜': '|', '＿': '_',
      '．': '.', '，': ',', '（': '(', '）': ')',
      '［': '[', '］': ']', '｛': '{', '｝': '}',
      '＠': '@', '＃': '#', '％': '%', '＆': '&',
      '＊': '*', '＋': '+', '＝': '=', '＜': '<', '＞': '>'
    };
    
    // 一般的なOCR誤認識パターン修正
    final ocrErrorMap = {
      // 数字の誤認識
      'O': '0', 'o': '0', 'l': '1', 'I': '1', 'S': '5', 's': '5',
      'G': '6', 'B': '8', 'g': '9', 'q': '9',
      
      // アルファベットの誤認識
      '8': 'B', '0': 'O', '1': 'I', '5': 'S', '6': 'G',
      
      // 特殊文字の誤認識
      '|': 'l', '\\': '/', '"': '"', "'": "'",
    };
    
    // eFootball特有の誤認識パターン
    final efootballSpecificMap = {
      // Division表記
      'DIV': 'Div', 'div': 'Div', 'DlV': 'Div', 'D1V': 'Div',
      
      // Rank表記
      'RANK': 'Rank', 'rank': 'Rank', 'FANK': 'Rank', 'R4NK': 'Rank',
      
      // スコア区切り文字
      '一': '-', '–': '-', '—': '-', '~': '-',
      
      // 一般的な単語
      'VS': 'vs', 'Vs': 'vs', 'vS': 'vs',
      'WIN': 'Win', 'win': 'Win', 'W1N': 'Win',
      'LOSE': 'Lose', 'lose': 'Lose', 'L0SE': 'Lose',
      'DRAW': 'Draw', 'draw': 'Draw', 'DFAW': 'Draw',
    };
    
    // 数字変換を適用
    numberMap.forEach((original, replacement) {
      correctedText = correctedText.replaceAll(original, replacement);
    });
    
    // 記号変換を適用
    symbolMap.forEach((original, replacement) {
      correctedText = correctedText.replaceAll(original, replacement);
    });
    
    // eFootball特有の変換を適用
    efootballSpecificMap.forEach((original, replacement) {
      correctedText = correctedText.replaceAll(original, replacement);
    });
    
    // OCR誤認識修正（文脈を考慮）
    correctedText = _contextAwareOCRCorrection(correctedText);
    
    return correctedText;
  }
  
  /// 文脈を考慮したOCR誤認識修正
  static String _contextAwareOCRCorrection(String text) {
    String correctedText = text;
    
    // スコアパターンの修正 (例: "3一2" → "3-2")
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'(\d+)[一–—~](\d+)'),
      (match) => '${match.group(1)}-${match.group(2)}'
    );
    
    // 時刻パターンの修正 (例: "l2:34" → "12:34")
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'[lI](\d):(\d{2})'),
      (match) => '1${match.group(1)}:${match.group(2)}'
    );
    
    // 日付パターンの修正 (例: "2O25/9/17" → "2025/9/17")
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'2[oO](\d{2})'),
      (match) => '20${match.group(1)}'
    );
    
    // Division/Rankパターンの修正
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'[DdОо][1lI][vV]\s*(\d+)', caseSensitive: false),
      (match) => 'Div ${match.group(1)}'
    );
    
    // ユーザー名の@記号修正
    correctedText = correctedText.replaceAllMapped(
      RegExp(r'[＠@]([a-zA-Z0-9_-]+)'),
      (match) => '@${match.group(1)}'
    );
    
    return correctedText;
  }

  /// eFootball用のテキスト前処理
  static String _processEFootballText(RecognizedText recognizedText) {
    final buffer = StringBuffer();
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        String lineText = line.text;
        
        // eFootball特有のOCRエラーを修正
        lineText = _correctEFootballOCRErrors(lineText);
        
        // 改行を追加
        buffer.writeln(lineText);
      }
    }
    
    return buffer.toString();
  }
  
  /// 画像ハッシュ値を生成
  static String _generateImageHash(Uint8List imageBytes) {
    return PerformanceService.measureSync('画像ハッシュ生成', () {
      final digest = sha256.convert(imageBytes);
      return digest.toString().substring(0, 16); // 短縮版ハッシュ
    });
  }

  /// 画像圧縮（OCR精度を保ちつつファイルサイズを削減）
  static Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    return await PerformanceService.measureAsync('画像圧縮', () async {
      try {
        // 画像をデコード
        final image = img.decodeImage(imageBytes);
        if (image == null) {
          throw Exception('画像のデコードに失敗しました');
        }
        
        debugPrint('元画像サイズ: ${image.width}x${image.height}, ${imageBytes.length} bytes');
        
        // OCRに適した解像度にリサイズ（長辺を1920pxに制限）
        img.Image resizedImage = image;
        const maxDimension = 1920;
        
        if (image.width > maxDimension || image.height > maxDimension) {
          if (image.width > image.height) {
            resizedImage = img.copyResize(image, width: maxDimension);
          } else {
            resizedImage = img.copyResize(image, height: maxDimension);
          }
          debugPrint('画像リサイズ: ${image.width}x${image.height} → ${resizedImage.width}x${resizedImage.height}');
        }
        
        // OCR精度向上のための画像処理
        resizedImage = _enhanceImageForOCR(resizedImage);
        
        // 高品質JPEG圧縮（品質85%）
        final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
        
        final compressionRatio = ((1 - compressedBytes.length / imageBytes.length) * 100);
        debugPrint('圧縮完了: ${imageBytes.length} → ${compressedBytes.length} bytes (${compressionRatio.toStringAsFixed(1)}% 削減)');
        
        // メモリ使用量の監視
        PerformanceService.logMemoryUsage('画像圧縮後');
        
        return Uint8List.fromList(compressedBytes);
      } catch (e) {
        debugPrint('画像圧縮エラー: $e');
        // 圧縮に失敗した場合は元の画像を返す
        return imageBytes;
      }
    });
  }
  
  /// OCR精度向上のための画像処理
  static img.Image _enhanceImageForOCR(img.Image image) {
    try {
      // コントラスト調整（テキストを鮮明に）
      var enhanced = img.adjustColor(image, contrast: 1.2, brightness: 1.05);
      
      // 軽度のシャープネス適用（imageパッケージv4対応）
      enhanced = img.convolution(enhanced, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);
      
      return enhanced;
    } catch (e) {
      debugPrint('画像処理エラー: $e');
      // エラーが発生した場合は元の画像を返す
      return image;
    }
  }
}