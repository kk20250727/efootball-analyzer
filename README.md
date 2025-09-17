# eFootball Analyzer

🚀 **リリース済み！** eFootballの戦績を分析するモバイル・Webアプリです。OCR技術を使用してスクリーンショットから戦績データを自動読み取りし、多角的な分析を提供します。

## 🌐 Web版（すぐにお試し可能！）

**[👉 Web版はこちら](https://kk20250727.github.io/efootball-analyzer/)**

- デモアカウントでログイン: `demo@example.com` / `password`
- サンプルデータテスト機能で全機能体験可能
- OCR機能はモバイル版で利用可能

## 📱 モバイル版（準備中）

- **Android**: Google Play Store（申請準備中）
- **iOS**: App Store（申請準備中）
- 完全なOCR機能付き

## 機能

### 主要機能
- **OCRによる戦績自動入力**: eFootballの対戦履歴画面のスクリーンショットから戦績データを自動読み取り
- **対戦相手分析**: 対戦相手の最高Divisionと順位を分析
- **スカッド管理**: 使用したフォーメーションとスカッドを管理
- **データ分析・可視化**: 時間帯別、スカッド別の勝率分析

### 技術仕様
- **フレームワーク**: Flutter
- **認証**: Firebase Authentication
- **データベース**: Cloud Firestore
- **OCR**: Google ML Kit Text Recognition
- **グラフ**: fl_chart

## セットアップ

### 前提条件
- Flutter SDK 3.9.2以上
- Firebase プロジェクト
- Android Studio / Xcode (モバイル開発の場合)

### インストール

1. リポジトリをクローン
```bash
git clone https://github.com/your-username/efootball-analyzer.git
cd efootball-analyzer
```

2. 依存関係をインストール
```bash
flutter pub get
```

3. Firebase設定
   - Firebase コンソールでプロジェクトを作成
   - `lib/firebase_options.dart` を更新
   - Authentication と Firestore を有効化

4. アプリを実行
```bash
flutter run
```

## 使用方法

1. **アカウント作成**: 初回起動時にeFootballユーザー名を含むアカウントを作成
2. **戦績入力**: 対戦履歴画面のスクリーンショットをアップロード
3. **データ確認**: OCRで読み取ったデータを確認・修正
4. **スカッド管理**: 使用したフォーメーションを登録
5. **分析確認**: ダッシュボードで戦績を分析

## プライバシーポリシー

本アプリは以下の情報を収集・保存します：
- ユーザーアカウント情報（メールアドレス、eFootballユーザー名）
- 戦績データ（スコア、対戦相手、日時）
- スカッド情報（フォーメーション、メモ）

これらの情報はFirebaseに安全に保存され、ユーザーの戦績分析のみに使用されます。

## ライセンス

MIT License

## 貢献

プルリクエストやイシューの報告を歓迎します。

## サポート

問題が発生した場合は、GitHubのIssuesページで報告してください。