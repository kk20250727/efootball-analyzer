import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'match_parser_service.dart';

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
    try {
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
      
      debugPrint('=== OCR処理結果 ===');
      debugPrint('画像パス: ${imageFile.path}');
      debugPrint('検出されたブロック数: ${recognizedText.blocks.length}');
      debugPrint('生テキスト:\n${recognizedText.text}');
      debugPrint('処理後テキスト:\n$processedText');
      
      return processedText;
    } catch (e) {
      debugPrint('OCR処理エラー: $e');
      throw Exception('OCR処理に失敗しました: $e');
    }
  }
  
  /// 複数画像のテキスト認識
  static Future<List<String>> recognizeMultipleImages(List<XFile> imageFiles) async {
    final List<String> results = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        debugPrint('画像 ${i + 1}/${imageFiles.length} を処理中...');
        final text = await recognizeTextFromXFile(imageFiles[i]);
        results.add(text);
      } catch (e) {
        debugPrint('画像 ${i + 1} の処理でエラー: $e');
        results.add('');
      }
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

  /// eFootball特有のOCRエラー修正
  static String _correctEFootballOCRErrors(String text) {
    return text
        .replaceAll('１', '1')
        .replaceAll('２', '2')
        .replaceAll('３', '3')
        .replaceAll('４', '4')
        .replaceAll('５', '5')
        .replaceAll('６', '6')
        .replaceAll('７', '7')
        .replaceAll('８', '8')
        .replaceAll('９', '9')
        .replaceAll('０', '0')
        .replaceAll('ー', '-')
        .replaceAll('：', ':')
        .replaceAll('／', '/')
        .replaceAll('．', '.')
        .replaceAll('，', ',');
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
}