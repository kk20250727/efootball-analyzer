import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/match_parser_service.dart';
import '../../utils/app_theme.dart';

class MatchUploadScreen extends StatefulWidget {
  const MatchUploadScreen({super.key});

  @override
  State<MatchUploadScreen> createState() => _MatchUploadScreenState();
}

class _MatchUploadScreenState extends State<MatchUploadScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickAndProcessImages() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 画像を選択
      final images = await OCRService.pickImages();
      if (images.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // OCR処理
      final ocrTexts = await OCRService.recognizeMultipleImages(images);
      final combinedText = ocrTexts.join('\n');

      // ユーザー情報を取得
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      // 戦績データを解析
      final parsedMatches = MatchParserService.parseMatchData(
        combinedText,
        user.efootballUsername,
      );

      if (parsedMatches.isEmpty) {
        setState(() {
          _errorMessage = '戦績データが見つかりませんでした。画像を確認してください。';
          _isProcessing = false;
        });
        return;
      }

      // ユーザー名の一致確認
      final usernames = MatchParserService.extractUsernames(combinedText);
      final matchingUsernames = usernames.where(
        (username) => username == user.efootballUsername,
      ).toList();

      if (matchingUsernames.isEmpty) {
        // ユーザー名が一致しない場合、選択画面を表示
        if (mounted) {
          final convertedMatches = parsedMatches.map((data) => 
              ParsedMatchData.fromMap(data as Map<String, dynamic>, authProvider.user?.efootballUsername ?? '')).toList();
          _showUsernameSelectionDialog(convertedMatches, combinedText, usernames);
        }
      } else {
        // データ確認画面へ
        if (mounted) {
          context.go('/match-confirm', extra: {
            'matchData': parsedMatches,
            'ocrText': combinedText,
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = '画像処理中にエラーが発生しました: $e';
        _isProcessing = false;
      });
    }
  }

  void _showUsernameSelectionDialog(
    List<ParsedMatchData> parsedMatches,
    String ocrText,
    List<String> usernames,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('どちらがあなたですか？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: usernames.map((username) {
            return ListTile(
              title: Text(username),
              onTap: () {
                Navigator.of(context).pop();
                _updateUsernameAndProceed(username, parsedMatches, ocrText);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUsernameAndProceed(
    String newUsername,
    List<ParsedMatchData> parsedMatches,
    String ocrText,
  ) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.updateEfootballUsername(newUsername);

    setState(() {
      _isProcessing = false;
    });

    if (mounted) {
      context.go('/match-confirm', extra: {
        'matchData': parsedMatches,
        'ocrText': ocrText,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('戦績を追加'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    size: 60,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 32),

                // タイトル
                Text(
                  '戦績をアップロード',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 説明
                Text(
                  'eFootballの対戦履歴画面のスクリーンショットを選択してください。\n複数の画像を同時に選択できます。',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // エラーメッセージ
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: AppTheme.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // アップロードボタン
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _pickAndProcessImages,
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlack,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('処理中...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library),
                              SizedBox(width: 8),
                              Text('画像を選択'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ヒント
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: AppTheme.yellow,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ヒント',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 対戦履歴画面でスコア、チーム名、ユーザー名がはっきり見えるように撮影してください\n'
                          '• 複数の試合が写っている画像でも自動で解析できます\n'
                          '• 画像が暗い場合は明るい場所で撮影してください',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightGray,
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
