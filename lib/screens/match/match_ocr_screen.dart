import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/match_parser_service.dart';
import '../../utils/app_theme.dart';

class MatchOCRScreen extends StatefulWidget {
  const MatchOCRScreen({super.key});

  @override
  State<MatchOCRScreen> createState() => _MatchOCRScreenState();
}

class _MatchOCRScreenState extends State<MatchOCRScreen> {
  bool _isProcessing = false;
  String? _statusMessage;
  List<XFile> _selectedImages = [];
  // TODO: 次のアップデートでプログレス表示機能を実装
  // double _processingProgress = 0.0;
  // int _currentImageIndex = 0;

  Future<void> _selectImages() async {
    try {
      final images = await OCRService.pickImages();
      setState(() {
        _selectedImages = images;
        _statusMessage = '${images.length}枚の画像を選択しました';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '画像選択エラー: $e';
      });
    }
  }

  Future<void> _processImages() async {
    if (_selectedImages.isEmpty) {
      setState(() {
        _statusMessage = '画像を選択してください';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      // _processingProgress = 0.0;
      // _currentImageIndex = 0;
      _statusMessage = 'OCR処理を開始しています...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userUsername = authProvider.user?.efootballUsername ?? '';

      if (userUsername.isEmpty) {
        setState(() {
          _statusMessage = 'eFootballユーザー名が設定されていません。設定画面で設定してください。';
          _isProcessing = false;
        });
        return;
      }

      debugPrint('=== eFootball OCR処理開始 ===');
      debugPrint('ユーザー名: $userUsername');
      debugPrint('選択画像数: ${_selectedImages.length}');

      setState(() {
        _statusMessage = '${_selectedImages.length}枚の画像を解析中...';
      });

      // OCR処理
      final ocrTexts = <String>[];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _statusMessage = '画像 ${i + 1}/${_selectedImages.length} を処理中...';
        });
        
        final text = await OCRService.recognizeTextFromXFile(_selectedImages[i]);
        ocrTexts.add(text);
      }
      
      // OCR結果をコンソールとUIに表示
      print('=== OCR処理完了 ===');
      for (int i = 0; i < ocrTexts.length; i++) {
        print('画像${i + 1}: ${ocrTexts[i].isEmpty ? "テキストなし" : "${ocrTexts[i].length}文字"}');
        if (ocrTexts[i].isNotEmpty) {
          print('内容: ${ocrTexts[i].substring(0, ocrTexts[i].length > 100 ? 100 : ocrTexts[i].length)}...');
        }
      }
      
      if (ocrTexts.isEmpty) {
        setState(() {
          _statusMessage = 'テキストが検出されませんでした。画像を確認してください。';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _statusMessage = 'OCR完了。試合データを解析中...';
      });

      // マッチデータ解析
      final allMatchData = <ParsedMatchData>[];
      for (int i = 0; i < ocrTexts.length; i++) {
        final ocrText = ocrTexts[i];
        debugPrint('=== 画像 ${i + 1} の解析結果 ===');
        debugPrint('OCRテキスト:\n$ocrText');
        
        if (ocrText.trim().isEmpty) {
          debugPrint('画像 ${i + 1}: OCRでテキストを検出できませんでした');
          continue;
        }

        final matchDataRaw = MatchParserService.parseMatchData(ocrText, userUsername);
        final matchData = matchDataRaw.map((data) => ParsedMatchData.fromMap(data, userUsername)).toList();
        allMatchData.addAll(matchData);
        
        debugPrint('画像 ${i + 1}から${matchData.length}件の試合データを抽出');
      }

      debugPrint('=== 解析完了 ===');
      debugPrint('総抽出試合数: ${allMatchData.length}');

      if (allMatchData.isEmpty) {
        // OCRで抽出されたテキストをデバッグ表示
        debugPrint('=== OCR抽出テキスト全文 ===');
        for (int i = 0; i < ocrTexts.length; i++) {
          debugPrint('画像 ${i + 1}:\n${ocrTexts[i]}\n---');
        }
        
        // 検出されたユーザー名を表示
        final allUsernames = <String>[];
        final allRawText = <String>[];
        for (final ocrText in ocrTexts) {
          allRawText.add(ocrText);
          final usernames = MatchParserService.extractUsernames(ocrText);
          allUsernames.addAll(usernames);
          debugPrint('この画像から検出されたユーザー名: $usernames');
        }
        final uniqueUsernames = allUsernames.toSet().toList();
        
        String detailInfo = '';
        if (allRawText.isNotEmpty && allRawText.first.trim().isNotEmpty) {
          // OCRでテキストは抽出できている場合
          if (uniqueUsernames.isNotEmpty) {
            detailInfo = '\n\n🔍 検出されたユーザー名:\n${uniqueUsernames.join(', ')}\n\n💡 設定ユーザー名「$userUsername」と一致しません。';
          } else {
            detailInfo = '\n\n⚠️ ユーザー名が検出されませんでした。\n\n📝 OCRで抽出されたテキスト（一部）:\n${allRawText.first.substring(0, allRawText.first.length > 100 ? 100 : allRawText.first.length)}...';
          }
        } else {
          detailInfo = '\n\n❌ OCRでテキストを抽出できませんでした。\n画像が不鮮明か、文字が認識できない可能性があります。';
        }
        
        setState(() {
          _statusMessage = '試合データを検出できませんでした。$detailInfo\n\n確認事項：\n• eFootballの試合履歴画面のスクリーンショットか\n• 画像が鮮明でテキストが読み取れるか\n• 日時とスコアが表示されているか\n• ユーザー名が正しく設定されているか';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _statusMessage = '✅ ${allMatchData.length}件の試合データを検出しました！';
        _isProcessing = false;
      });

      // 少し待ってから確認画面に遷移
      await Future.delayed(const Duration(milliseconds: 1500));

      // 確認画面に遷移
      if (mounted) {
        context.push('/match/confirm', extra: {
          'matchData': allMatchData,
          'ocrText': ocrTexts.join('\n\n=== 次の画像 ===\n\n'),
        });
      }
    } catch (e) {
      debugPrint('OCR処理エラー: $e');
      
      String userFriendlyMessage;
      
      if (e.toString().contains('画像ファイルが選択されていません')) {
        userFriendlyMessage = '❌ 画像を選択してから処理を開始してください';
      } else if (e.toString().contains('ファイルサイズが10MBを超えています')) {
        userFriendlyMessage = '📏 ファイルサイズが大きすぎます\n（10MB以下にしてください）';
      } else if (e.toString().contains('サポートされていないファイル形式')) {
        userFriendlyMessage = '📸 JPGまたはPNG形式の画像を選択してください';
      } else if (e.toString().contains('すべての画像でOCR処理に失敗')) {
        userFriendlyMessage = '🔍 画像からテキストを読み取れませんでした\n\n💡 改善のヒント:\n• 画像の解像度を上げてください\n• 文字がはっきり見える画像を使用してください\n• 照明が良い環境で撮影してください';
      } else if (e.toString().contains('Web環境でのOCR機能は現在サポートされていません')) {
        userFriendlyMessage = '📱 OCR機能はモバイル版でのみ利用可能です\n\nWeb版では手動でのデータ入力をご利用ください';
      } else {
        userFriendlyMessage = '⚠️ OCR処理中にエラーが発生しました\n\n💡 解決方法:\n• 画像の品質を確認してください\n• 別の画像で再試行してください\n• アプリを再起動してみてください';
      }
      
      setState(() {
        _statusMessage = userFriendlyMessage;
        _isProcessing = false;
        // _processingProgress = 0.0;
        // _currentImageIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('戦績データ読み取り'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 説明カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.cyan),
                            const SizedBox(width: 8),
                            Text(
                              '使用方法',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          kIsWeb 
                            ? '⚠️ Web環境では画像OCR機能が制限されています。\n'
                              '「サンプルデータでテスト」をお試しいただくか、\n'
                              'モバイルアプリ版をご利用ください。\n\n'
                              '1. eFootballの「Match History」画面のスクリーンショットを撮影\n'
                              '2. 「画像を選択」ボタンで画像をアップロード\n'
                              '3. 「OCR処理開始」ボタンで試合データを読み取り\n'
                              '4. 検出されたデータを確認・編集'
                            : '1. eFootballの「Match History」画面のスクリーンショットを撮影\n'
                              '2. 「画像を選択」ボタンで画像をアップロード\n'
                              '3. 「OCR処理開始」ボタンで試合データを読み取り\n'
                              '4. 検出されたデータを確認・編集',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.veryLightGray,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 画像選択セクション
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '画像選択',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _selectImages,
                          icon: const Icon(Icons.photo_library),
                          label: Text(_selectedImages.isEmpty 
                              ? '画像を選択' 
                              : '${_selectedImages.length}枚選択済み'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '選択された画像: ${_selectedImages.length}枚',
                            style: TextStyle(
                              color: AppTheme.veryLightGray,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // OCR処理セクション
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OCR処理',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: (_isProcessing || _selectedImages.isEmpty) 
                              ? null 
                              : _processImages,
                          icon: _isProcessing 
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryBlack
                                    ),
                                  ),
                                )
                              : const Icon(Icons.text_fields),
                          label: Text(_isProcessing ? '処理中...' : 'OCR処理開始'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: _isProcessing 
                                ? AppTheme.mediumGray 
                                : AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _testWithSampleData,
                          icon: const Icon(Icons.science),
                          label: const Text('サンプルデータでテスト'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                            foregroundColor: AppTheme.cyan,
                            side: const BorderSide(color: AppTheme.cyan),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ステータス表示
                if (_statusMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _isProcessing 
                                ? Icons.hourglass_empty 
                                : _statusMessage!.contains('エラー')
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                            color: _isProcessing 
                                ? AppTheme.cyan
                                : _statusMessage!.contains('エラー')
                                    ? AppTheme.red
                                    : AppTheme.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // フッター情報
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates, 
                             color: AppTheme.yellow, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ヒント: 複数の画像を一度に選択して、まとめて処理することができます',
                            style: TextStyle(
                              color: AppTheme.veryLightGray,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _testWithSampleData() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'サンプルデータでテスト中...';
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userUsername = authProvider.user?.efootballUsername ?? '';

      // サンプルのOCRテキスト（前回の画像から想定されるテキスト）
      const sampleOcrText = '''
Division 3
2025/09/13 18:19
BOB 3 - 1 FC バルセロナ
visca-tzuyu    hisa_racer

2025/09/13 01:12
FC バルセロナ 2 - 2 FC バルセロナ
eftarigato    hisa_racer

2025/09/13 01:02
FC バルセロナ 1 - 2 道南の村長
hisa_racer    0623SN
''';

      print('=== サンプルデータテスト ===');
      print('サンプルOCRテキスト:\n$sampleOcrText');
      print('ユーザー名: $userUsername');

      // サンプルデータで解析
      final matchData = MatchParserService.parseMatchData(sampleOcrText, userUsername);
      print('解析結果: ${matchData.length}件の試合データ');

      if (matchData.isEmpty) {
        // ユーザー名を抽出してみる
        final usernames = MatchParserService.extractUsernames(sampleOcrText);
        print('検出されたユーザー名: $usernames');
        
        setState(() {
          _statusMessage = 'サンプルデータでも試合データを検出できませんでした。\n\n検出されたユーザー名: ${usernames.join(', ')}\n設定ユーザー名: $userUsername';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _statusMessage = '✅ サンプルデータで${matchData.length}件の試合データを検出しました！';
        _isProcessing = false;
      });

      // 確認画面に遷移
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.push('/match/confirm', extra: {
          'matchData': matchData,
          'ocrText': sampleOcrText,
        });
      }
    } catch (e) {
      print('サンプルデータテストエラー: $e');
      setState(() {
        _statusMessage = 'サンプルデータテストエラー: $e';
        _isProcessing = false;
      });
    }
  }
}