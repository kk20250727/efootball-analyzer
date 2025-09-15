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
      
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR処理に失敗しました: $e');
    }
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
