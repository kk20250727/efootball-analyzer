import 'dart:io';
import 'package:flutter/foundation.dart';

/// アプリ状態をコマンドラインで確認するスクリプト
void main() async {
  print('=== eFootball Analyzer アプリ状態確認 ===');
  print('実行時刻: ${DateTime.now()}');
  print('');

  // 1. プロジェクト構造確認
  await checkProjectStructure();
  
  // 2. 依存関係確認
  await checkDependencies();
  
  // 3. ビルド状態確認
  await checkBuildStatus();
  
  // 4. 機能実装確認
  await checkFeatureImplementation();
  
  print('');
  print('=== 状態確認完了 ===');
}

Future<void> checkProjectStructure() async {
  print('📁 プロジェクト構造確認:');
  
  final directories = [
    'lib',
    'lib/screens',
    'lib/services',
    'lib/models',
    'lib/providers',
    'lib/utils',
    'lib/widgets',
    'ios',
    'web',
    'assets',
  ];
  
  for (final dir in directories) {
    final exists = await Directory(dir).exists();
    print('  ${exists ? "✅" : "❌"} $dir');
  }
  print('');
}

Future<void> checkDependencies() async {
  print('📦 主要依存関係確認:');
  
  try {
    final pubspecFile = File('pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      
      final dependencies = [
        'firebase_core',
        'firebase_auth',
        'cloud_firestore',
        'google_mlkit_text_recognition',
        'image_picker',
        'package_info_plus',
        'shared_preferences',
        'go_router',
        'provider',
        'fl_chart',
      ];
      
      for (final dep in dependencies) {
        final hasKey = content.contains('$dep:');
        print('  ${hasKey ? "✅" : "❌"} $dep');
      }
    } else {
      print('  ❌ pubspec.yaml not found');
    }
  } catch (e) {
    print('  ❌ Error reading pubspec.yaml: $e');
  }
  print('');
}

Future<void> checkBuildStatus() async {
  print('🔨 ビルド状態確認:');
  
  final buildFiles = [
    'build',
    'build/ios',
    'build/web',
    '.dart_tool',
    'ios/Pods',
    'ios/Podfile.lock',
  ];
  
  for (final file in buildFiles) {
    final fileExists = await File(file).exists().catchError((_) => false);
    final dirExists = await Directory(file).exists().catchError((_) => false);
    final exists = fileExists || dirExists;
    print('  ${exists ? "✅" : "❌"} $file');
  }
  print('');
}

Future<void> checkFeatureImplementation() async {
  print('🎯 機能実装確認:');
  
  final featureFiles = [
    'lib/services/ocr_service.dart',
    'lib/services/match_parser_service.dart',
    'lib/services/ios_test_service.dart',
    'lib/services/cache_service.dart',
    'lib/services/performance_service.dart',
    'lib/screens/app_status_screen.dart',
    'lib/screens/test/ios_test_screen.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/match/match_ocr_screen.dart',
  ];
  
  for (final file in featureFiles) {
    final exists = await File(file).exists();
    print('  ${exists ? "✅" : "❌"} $file');
  }
  print('');
}
