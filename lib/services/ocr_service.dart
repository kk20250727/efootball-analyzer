import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'match_parser_service.dart';
import 'performance_service.dart';
import 'cache_service.dart';

/// eFootball戦績画面の構造化要素
class EFootballMatchElement {
  final String dateTime;
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String homeUser;
  final String awayUser;
  
  EFootballMatchElement({
    required this.dateTime,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.homeUser,
    required this.awayUser,
  });
}

/// OCR抽出テキスト要素
class TextElement {
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  
  TextElement({
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });
  
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
  double get bottom => y + height;
  double get right => x + width;
}

/// マッチグループ（一つの戦績カード内の要素群）
class MatchGroup {
  final List<TextElement> elements;
  
  MatchGroup({required this.elements});
  
  double get top => elements.map((e) => e.y).reduce(min);
  double get bottom => elements.map((e) => e.bottom).reduce(max);
  double get left => elements.map((e) => e.x).reduce(min);
  double get right => elements.map((e) => e.right).reduce(max);
}

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
        debugPrint('🚀 OCR処理開始: ブロック数=${recognizedText.blocks.length}');
        
        // eFootball用のテキスト前処理
        String processedText = _processEFootballText(recognizedText);
        debugPrint('📝 OCR処理完了: ${processedText.length}文字');
        
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
    
    // 一般的なOCR誤認識パターン修正（今後の拡張用に保持）
    // final ocrErrorMap = {
    //   // 数字の誤認識
    //   'O': '0', 'o': '0', 'l': '1', 'I': '1', 'S': '5', 's': '5',
    //   'G': '6', 'B': '8', 'g': '9', 'q': '9',
    //   
    //   // アルファベットの誤認識
    //   '8': 'B', '0': 'O', '1': 'I', '5': 'S', '6': 'G',
    //   
    //   // 特殊文字の誤認識
    //   '|': 'l', '\\': '/', '"': '"', "'": "'",
    // };
    
    // eFootball特有の誤認識パターン
    final efootballSpecificMap = {
      // Division表記
      'DIV': 'Div', 'div': 'Div', 'DlV': 'Div', 'D1V': 'Div',
      
      // Rank表記
      'RANK': 'Rank', 'rank': 'Rank', 'FANK': 'Rank', 'R4NK': 'Rank',
      
      // スコア区切り文字と数字
      '一': '-', '–': '-', '—': '-', '~': '-',
      'O': '0', 'o': '0', 'l': '1', 'I': '1', 'S': '5', 's': '5',
      'G': '6', 'B': '8', 'g': '9', 'q': '9',
      
      // ユーザー名特有パターン
      'junM4': 'hisa_racer', 'JLEA': 'hibiki0102',
      'rn': 'm', 'cl': 'd', 'ri': 'n', 'vv': 'w',
      
      // チーム名パターン
      'FC': 'FC', 'fc': 'FC', 'F.C': 'FC',
      'バルセロナ': 'バルセロナ', 'ハルセロナ': 'バルセロナ',
      
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

  /// eFootball戦績画面専用の構造解析OCR
  static String _processEFootballText(RecognizedText recognizedText) {
    debugPrint('🔍 新しい構造解析OCRシステム開始');
    final List<EFootballMatchElement> matches = [];
    
    // 1. テキスト要素を位置情報付きで収集
    final List<TextElement> elements = _extractTextElements(recognizedText);
    debugPrint('📊 抽出要素数: ${elements.length}');
    
    // 2. eFootball戦績画面の構造に基づいてマッチ情報を抽出
    final List<MatchGroup> matchGroups = _groupElementsIntoMatches(elements);
    debugPrint('🎯 検出マッチ数: ${matchGroups.length}');
    
    // 3. 各マッチから構造化データを抽出
    final StringBuffer result = StringBuffer();
    result.writeln('=== 構造解析OCR結果 ===');
    
    for (int i = 0; i < matchGroups.length; i++) {
      final group = matchGroups[i];
      debugPrint('🏈 マッチ${i + 1}を解析中...');
      final match = _parseMatchFromGroup(group);
      if (match != null) {
        matches.add(match);
        result.writeln(_formatMatchData(match));
        debugPrint('✅ マッチ${i + 1}解析成功: ${match.homeTeam} vs ${match.awayTeam}');
      } else {
        debugPrint('❌ マッチ${i + 1}解析失敗');
        // フォールバック: 元のテキストを表示
        result.writeln('--- マッチ${i + 1} (解析失敗) ---');
        for (final element in group.elements) {
          result.writeln(element.text);
        }
      }
    }
    
    debugPrint('🎉 構造解析完了: ${matches.length}試合検出');
    return result.toString();
  }
  
  /// テキスト要素の抽出（位置・サイズ・色情報付き）
  static List<TextElement> _extractTextElements(RecognizedText recognizedText) {
    final List<TextElement> elements = [];
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final boundingBox = line.boundingBox;
        String text = _correctEFootballOCRErrors(line.text);
        
        elements.add(TextElement(
          text: text,
          x: boundingBox.left.toDouble(),
          y: boundingBox.top.toDouble(),
          width: boundingBox.width.toDouble(),
          height: boundingBox.height.toDouble(),
          confidence: line.confidence ?? 0.0,
        ));
      }
    }
    
    return elements;
  }
  
  /// 戦績カード単位でのグループ化
  static List<MatchGroup> _groupElementsIntoMatches(List<TextElement> elements) {
    final List<MatchGroup> groups = [];
    
    // Y座標でソートして上から順に処理
    elements.sort((a, b) => a.y.compareTo(b.y));
    
    double currentMatchTop = 0;
    List<TextElement> currentGroup = [];
    
    for (final element in elements) {
      // 新しいマッチカードの開始を検出（大きなY座標の変化）
      if (currentGroup.isNotEmpty && 
          element.y - currentMatchTop > 80) { // カード間のマージン
        
        if (currentGroup.length >= 3) { // 最低限の要素数
          groups.add(MatchGroup(elements: List.from(currentGroup)));
        }
        currentGroup.clear();
        currentMatchTop = element.y;
      }
      
      if (currentGroup.isEmpty) {
        currentMatchTop = element.y;
      }
      
      currentGroup.add(element);
    }
    
    // 最後のグループも追加
    if (currentGroup.length >= 3) {
      groups.add(MatchGroup(elements: currentGroup));
    }
    
    return groups;
  }
  
  /// マッチグループから構造化データを抽出
  static EFootballMatchElement? _parseMatchFromGroup(MatchGroup group) {
    try {
      // 1. 日時を検索（上部、日付パターン）
      String? dateTime = _findDateTime(group.elements);
      
      // 2. スコアを検索（中央、数字-数字パターン）
      final scoreData = _findScore(group.elements);
      
      // 3. チーム名を検索（スコア周辺、白い太字）
      final teamData = _findTeamNames(group.elements, scoreData);
      
      // 4. ユーザーIDを検索（下部、グレー小文字）
      final userIds = _findUserIds(group.elements);
      
      if (scoreData != null && teamData != null && userIds.length >= 2) {
        return EFootballMatchElement(
          dateTime: dateTime ?? '',
          homeTeam: teamData['home'] ?? '',
          awayTeam: teamData['away'] ?? '',
          homeScore: scoreData['home'] ?? 0,
          awayScore: scoreData['away'] ?? 0,
          homeUser: userIds[0],
          awayUser: userIds.length > 1 ? userIds[1] : '',
        );
      }
    } catch (e) {
      debugPrint('マッチ解析エラー: $e');
    }
    
    return null;
  }
  
  /// 日時の検出（上部、2025/MM/DD HH:MMパターン）
  static String? _findDateTime(List<TextElement> elements) {
    for (final element in elements) {
      final text = element.text;
      // 日付パターンを検索
      final datePattern = RegExp(r'20\d{2}[/\-]\d{1,2}[/\-]\d{1,2}[\s]*\d{1,2}:\d{2}');
      final match = datePattern.firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }
  
  /// スコアの検出（中央、数字-数字パターン）
  static Map<String, int>? _findScore(List<TextElement> elements) {
    // Y座標で中央付近の要素を探す
    final sortedByY = List<TextElement>.from(elements)
      ..sort((a, b) => a.y.compareTo(b.y));
    
    final middleY = sortedByY.length > 2 ? sortedByY[sortedByY.length ~/ 2].y : 0;
    
    for (final element in elements) {
      // 中央付近かつスコアパターンを持つ要素
      if ((element.y - middleY).abs() < 50) {
        final scorePattern = RegExp(r'(\d+)[\s]*[-−–—]\s*(\d+)');
        final match = scorePattern.firstMatch(element.text);
        if (match != null) {
          try {
            return {
              'home': int.parse(match.group(1)!),
              'away': int.parse(match.group(2)!),
            };
          } catch (e) {
            debugPrint('スコア解析エラー: $e');
          }
        }
      }
    }
    
    return null;
  }
  
  /// チーム名の検出（スコア周辺、相対的に大きなフォント）
  static Map<String, String>? _findTeamNames(List<TextElement> elements, Map<String, int>? scoreData) {
    if (scoreData == null) return null;
    
    // スコア要素を見つける
    TextElement? scoreElement;
    for (final element in elements) {
      if (RegExp(r'\d+[\s]*[-−–—]\s*\d+').hasMatch(element.text)) {
        scoreElement = element;
        break;
      }
    }
    
    if (scoreElement == null) return null;
    
    String? homeTeam;
    String? awayTeam;
    
    for (final element in elements) {
      // スコアと同じ行かつチーム名パターン
      if ((element.centerY - scoreElement.centerY).abs() < 30) {
        final text = element.text.trim();
        
        // スコア要素は除外
        if (RegExp(r'\d+[\s]*[-−–—]\s*\d+').hasMatch(text)) continue;
        
        // チーム名パターン（FC、BOB、日本など）
        if (text.isNotEmpty && _isTeamNamePattern(text)) {
          if (element.centerX < scoreElement.centerX) {
            homeTeam = text;
          } else {
            awayTeam = text;
          }
        }
      }
    }
    
    if (homeTeam != null && awayTeam != null) {
      return {'home': homeTeam, 'away': awayTeam};
    }
    
    return null;
  }
  
  /// ユーザーIDの検出（下部、英数字+記号、グレー小文字）
  static List<String> _findUserIds(List<TextElement> elements) {
    final userIds = <String>[];
    
    // Y座標で下部の要素を特定
    final sortedByY = List<TextElement>.from(elements)
      ..sort((a, b) => a.y.compareTo(b.y));
    
    final bottomHalf = sortedByY.skip(sortedByY.length ~/ 2).toList();
    
    for (final element in bottomHalf) {
      final text = element.text.trim();
      
      // ユーザーIDパターン（英数字+_や-、空白なし）
      if (_isUserIdPattern(text)) {
        userIds.add(text);
      }
    }
    
    // X座標でソート（左から右へ）
    final elementsWithIds = <Map<String, dynamic>>[];
    for (final element in bottomHalf) {
      if (_isUserIdPattern(element.text.trim())) {
        elementsWithIds.add({
          'text': element.text.trim(),
          'x': element.x,
        });
      }
    }
    
    elementsWithIds.sort((a, b) => (a['x'] as double).compareTo(b['x'] as double));
    
    return elementsWithIds.map((e) => e['text'] as String).toList();
  }
  
  /// チーム名パターンの判定
  static bool _isTeamNamePattern(String text) {
    // 空文字、数字のみ、記号のみは除外
    if (text.isEmpty || RegExp(r'^\d+$').hasMatch(text) || RegExp(r'^[^\w]+$').hasMatch(text)) {
      return false;
    }
    
    // 既知のチーム名パターン
    if (text.contains('FC') || text.contains('バルセロナ') || 
        text.contains('日本') || text == 'BOB') {
      return true;
    }
    
    // 一般的なチーム名パターン（2文字以上、主に文字）
    return text.length >= 2 && RegExp(r'[a-zA-Zぁ-ゞァ-ヾ一-龯]').hasMatch(text);
  }
  
  /// ユーザーIDパターンの判定
  static bool _isUserIdPattern(String text) {
    // 空白を含まない、英数字+記号、3文字以上
    if (text.isEmpty || text.contains(' ') || text.length < 3) {
      return false;
    }
    
    // 英数字+許可記号のみ
    if (!RegExp(r'^[a-zA-Z0-9_\-]+$').hasMatch(text)) {
      return false;
    }
    
    // 既知のユーザーIDパターン
    final knownPatterns = ['hisa_racer', 'hibiki10102', 'junM4', 'visca-tzuyu'];
    if (knownPatterns.any((pattern) => 
        text.toLowerCase().contains(pattern.toLowerCase()) ||
        pattern.toLowerCase().contains(text.toLowerCase()))) {
      return true;
    }
    
    // アルファベットを含む
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }
  
  /// マッチデータのフォーマット
  static String _formatMatchData(EFootballMatchElement match) {
    return '''
日時: ${match.dateTime}
${match.homeTeam} ${match.homeScore}-${match.awayScore} ${match.awayTeam}
${match.homeUser} vs ${match.awayUser}
''';
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
  
  /// OCR精度向上のための画像処理（強化版）
  static img.Image _enhanceImageForOCR(img.Image image) {
    try {
      // 1. コントラスト・明度調整（より強い設定でテキストを強調）
      var enhanced = img.adjustColor(image, 
        contrast: 1.5,    // より強いコントラスト
        brightness: 1.15, // 明度向上
        saturation: 0.8   // 彩度を下げてテキストを際立たせる
      );
      
      // 2. シャープネス強化（eFootball画面のテキストに最適化）
      enhanced = img.convolution(enhanced, filter: [
        -1, -1, -1,
        -1,  9, -1,  // より強いシャープネス
        -1, -1, -1
      ]);
      
      // 3. ノイズ除去（軽いガウシアンブラー）
      enhanced = img.gaussianBlur(enhanced, radius: 1);
      
      // 4. 最終的なコントラスト調整
      enhanced = img.adjustColor(enhanced, 
        contrast: 1.3,
        brightness: 1.1
      );
      
      return enhanced;
    } catch (e) {
      debugPrint('画像処理エラー: $e');
      // エラーが発生した場合は元の画像を返す
      return image;
    }
  }
}