import 'package:flutter/material.dart';
import '../../services/ocr_service.dart';
import '../../services/opponent_parser_service.dart';
import '../../utils/app_theme.dart';

class OpponentUploadScreen extends StatefulWidget {
  const OpponentUploadScreen({super.key});

  @override
  State<OpponentUploadScreen> createState() => _OpponentUploadScreenState();
}

class _OpponentUploadScreenState extends State<OpponentUploadScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  List<ParsedOpponentData> _parsedOpponents = [];

  Future<void> _pickAndProcessImages() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _parsedOpponents = [];
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

      // 対戦相手データを解析
      final parsedOpponents = OpponentParserService.parseOpponentData(combinedText);

      if (parsedOpponents.isEmpty) {
        setState(() {
          _errorMessage = '対戦相手の最高戦績データが見つかりませんでした。画像を確認してください。';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _parsedOpponents = parsedOpponents;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '画像処理中にエラーが発生しました: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦相手分析'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // ヘッダー
                Container(
                  width: 100,
                  height: 100,
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
                    Icons.people,
                    size: 50,
                    color: AppTheme.primaryBlack,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  '対戦相手の最高戦績を分析',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '対戦相手のプロフィール画面のスクリーンショットを選択してください。\n最高Divisionと順位を自動で読み取ります。',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

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

                // 解析結果
                if (_parsedOpponents.isNotEmpty) ...[
                  Text(
                    '解析結果',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _parsedOpponents.length,
                      itemBuilder: (context, index) {
                        final opponent = _parsedOpponents[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: AppTheme.cyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      opponent.username,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        '最高Division',
                                        'Division ${opponent.highestDivision}',
                                        Icons.emoji_events,
                                        AppTheme.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatItem(
                                        '最高順位',
                                        '${opponent.highestRank}位',
                                        Icons.leaderboard,
                                        AppTheme.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
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
                            '• 対戦相手のプロフィール画面で「ゲームプラン確認」が表示されている画像を撮影してください\n'
                            '• 「最高成績（PVP）」の部分がはっきり見えるように撮影してください\n'
                            '• Divisionと順位の数字が読み取れるように明るい場所で撮影してください',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.lightGray,
          ),
        ),
      ],
    );
  }
}
