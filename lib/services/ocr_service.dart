import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<List<XFile>> pickImages() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickMultiImage();
  }

  static Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR処理に失敗しました: $e');
    }
  }
  
  static Future<String> recognizeTextFromXFile(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // eFootball用のテキスト前処理
      String processedText = _processEFootballText(recognizedText);
      
      debugPrint('=== OCR処理結果 ===');
      debugPrint('画像パス: ${imageFile.path}');
      debugPrint('検出されたブロック数: ${recognizedText.blocks.length}');
      debugPrint('生テキスト:\n${recognizedText.text}');
      debugPrint('生テキスト長さ: ${recognizedText.text.length}文字');
      debugPrint('処理後テキスト:\n$processedText');
      debugPrint('処理後テキスト長さ: ${processedText.length}文字');
      
      // Web環境でも確認できるようにprint
      print('OCR結果: ${recognizedText.text.isEmpty ? "テキストなし" : "${recognizedText.text.length}文字検出"}');
      if (recognizedText.text.isNotEmpty) {
        print('OCR生テキスト(最初の200文字): ${recognizedText.text.length > 200 ? recognizedText.text.substring(0, 200) + "..." : recognizedText.text}');
      }
      
      return processedText;
    } catch (e) {
      throw Exception('OCR処理に失敗しました: $e');
    }
  }

  static String _processEFootballText(RecognizedText recognizedText) {
    List<String> processedLines = [];
    
    // ブロック単位で処理（座標順にソート）
    List<TextBlock> sortedBlocks = recognizedText.blocks.toList();
    sortedBlocks.sort((a, b) {
      // Y座標（上から下）を優先、次にX座標（左から右）
      int yCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
      if (yCompare != 0) return yCompare;
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });
    
    for (TextBlock block in sortedBlocks) {
      List<String> blockLines = [];
      
      // ライン単位で処理
      List<TextLine> sortedLines = block.lines.toList();
      sortedLines.sort((a, b) {
        int yCompare = a.boundingBox.top.compareTo(b.boundingBox.top);
        if (yCompare != 0) return yCompare;
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      });
      
      for (TextLine line in sortedLines) {
        String lineText = line.text.trim();
        
        // eFootball特有のOCR誤認識を修正
        lineText = _correctEFootballOCRErrors(lineText);
        
        if (lineText.isNotEmpty) {
          blockLines.add(lineText);
        }
      }
      
      if (blockLines.isNotEmpty) {
        processedLines.addAll(blockLines);
      }
    }
    
    return processedLines.join('\n');
  }

  static String _correctEFootballOCRErrors(String text) {
    // eFootballでよくあるOCR誤認識を修正
    Map<String, String> corrections = {
      // スコア関連
      'l': '1', 'I': '1', '|': '1', 'O': '0', 'o': '0',
      // 日時関連
      'l0': '10', 'Il': '11', 'l2': '12', 'l3': '13', 'l4': '14', 'l5': '15',
      'l6': '16', 'l7': '17', 'l8': '18', 'l9': '19', '2O': '20', '2l': '21',
      // チーム名関連（よくある誤認識）
      'FCパルセロナ': 'FC バルセロナ',
      'ＦＣバルセロナ': 'FC バルセロナ',
      'レアルマドリード': 'レアル・マドリード',
      // ユーザー名関連
      'hisa_racer': 'hisa_racer', // 正確に認識されている場合はそのまま
      'visca-tzuyu': 'visca-tzuyu',
    };
    
    String corrected = text;
    
    // 基本的な文字置換
    for (var entry in corrections.entries) {
      corrected = corrected.replaceAll(entry.key, entry.value);
    }
    
    // スコアパターンの修正（l-1 -> 1-1 など）
    corrected = RegExp(r'([lo])\s*[-–]\s*(\d+)').allMatches(corrected).fold(corrected, (str, match) {
      return str.replaceAll(match.group(0)!, '1 - ${match.group(2)}');
    });
    
    corrected = RegExp(r'(\d+)\s*[-–]\s*([lo])').allMatches(corrected).fold(corrected, (str, match) {
      return str.replaceAll(match.group(0)!, '${match.group(1)} - 1');
    });
    
    // 日時パターンの修正
    corrected = RegExp(r'(\d{4})[/\\](\d{1,2})[/\\](\d{1,2})\s+(\d{1,2}):(\d{1,2})').allMatches(corrected).fold(corrected, (str, match) {
      return str.replaceAll(match.group(0)!, '${match.group(1)}/${match.group(2)}/${match.group(3)} ${match.group(4)}:${match.group(5)}');
    });
    
    return corrected;
  }

  static Future<List<String>> recognizeMultipleImages(List<XFile> imageFiles) async {
    List<String> results = [];
    
    for (XFile imageFile in imageFiles) {
      try {
        final text = await recognizeTextFromXFile(imageFile);
        results.add(text);
      } catch (e) {
        debugPrint('画像の処理に失敗しました: ${imageFile.path} - $e');
        results.add(''); // エラーの場合は空文字を追加
      }
    }
    
    return results;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
