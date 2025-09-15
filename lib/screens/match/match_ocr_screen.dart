import 'package:flutter/material.dart';
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
      _statusMessage = 'OCR処理中...';
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
      final ocrTexts = await OCRService.recognizeMultipleImages(_selectedImages);
      
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

        final matchData = MatchParserService.parseMatchData(ocrText, userUsername);
        allMatchData.addAll(matchData);
        
        debugPrint('画像 ${i + 1}から${matchData.length}件の試合データを抽出');
      }

      debugPrint('=== 解析完了 ===');
      debugPrint('総抽出試合数: ${allMatchData.length}');

      if (allMatchData.isEmpty) {
        setState(() {
          _statusMessage = '試合データを検出できませんでした。\n\n確認事項：\n• eFootballの試合履歴画面のスクリーンショットか\n• 画像が鮮明でテキストが読み取れるか\n• ユーザー名「$userUsername」が画像に含まれているか\n• 日時とスコアが表示されているか';
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
      setState(() {
        _statusMessage = 'OCR処理エラー: $e\n\n画像の品質を確認するか、別の画像を試してください。';
        _isProcessing = false;
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
                          '1. eFootballの「Match History」画面のスクリーンショットを撮影\n'
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
}