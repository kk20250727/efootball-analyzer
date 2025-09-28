#!/bin/bash

echo "=== eFootball Analyzer アプリ状態確認 ==="
echo "実行時刻: $(date)"
echo ""

echo "📁 プロジェクト構造確認:"
directories=("lib" "lib/screens" "lib/services" "lib/models" "lib/providers" "lib/utils" "lib/widgets" "ios" "web" "assets")
for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir"
    fi
done
echo ""

echo "📦 主要依存関係確認:"
if [ -f "pubspec.yaml" ]; then
    dependencies=("firebase_core" "firebase_auth" "cloud_firestore" "google_mlkit_text_recognition" "image_picker" "package_info_plus" "shared_preferences" "go_router" "provider" "fl_chart")
    for dep in "${dependencies[@]}"; do
        if grep -q "$dep:" pubspec.yaml; then
            echo "  ✅ $dep"
        else
            echo "  ❌ $dep"
        fi
    done
else
    echo "  ❌ pubspec.yaml not found"
fi
echo ""

echo "🔨 ビルド状態確認:"
build_files=("build" "build/ios" "build/web" ".dart_tool" "ios/Pods" "ios/Podfile.lock")
for file in "${build_files[@]}"; do
    if [ -e "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file"
    fi
done
echo ""

echo "🎯 機能実装確認:"
feature_files=(
    "lib/services/ocr_service.dart"
    "lib/services/match_parser_service.dart"
    "lib/services/ios_test_service.dart"
    "lib/services/cache_service.dart"
    "lib/services/performance_service.dart"
    "lib/screens/app_status_screen.dart"
    "lib/screens/test/ios_test_screen.dart"
    "lib/screens/home_screen.dart"
    "lib/screens/match/match_ocr_screen.dart"
)
for file in "${feature_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file"
    fi
done
echo ""

echo "📱 シミュレーター状態:"
xcrun simctl list devices available | grep Booted
echo ""

echo "🔧 Flutter環境:"
flutter doctor --android-licenses > /dev/null 2>&1
flutter doctor | head -20
echo ""

echo "💾 プロジェクトサイズ:"
echo "  プロジェクト合計: $(du -sh . | cut -f1)"
if [ -d "build" ]; then
    echo "  ビルドファイル: $(du -sh build | cut -f1)"
fi
if [ -d "ios/Pods" ]; then
    echo "  iOS依存関係: $(du -sh ios/Pods | cut -f1)"
fi
echo ""

echo "=== 状態確認完了 ==="
