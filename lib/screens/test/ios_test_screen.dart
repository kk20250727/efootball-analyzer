import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ios_test_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/accessible_card.dart';

/// iOS版テスト専用画面
class IOSTestScreen extends StatefulWidget {
  const IOSTestScreen({super.key});

  @override
  State<IOSTestScreen> createState() => _IOSTestScreenState();
}

class _IOSTestScreenState extends State<IOSTestScreen> {
  bool _isRunningTests = false;
  Map<String, dynamic>? _testResults;
  String? _comprehensiveReport;

  /// 基本機能テスト実行
  Future<void> _runBasicTests() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final results = await IOSTestService.runBasicTests();
      setState(() {
        _testResults = results;
      });
      
      // ハプティックフィードバック（iOS特有）
      HapticFeedback.mediumImpact();
      
      debugPrint('✅ 基本テスト完了');
    } catch (e) {
      debugPrint('❌ テストエラー: $e');
      // エラーハプティック
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  /// OCR機能テスト実行
  Future<void> _runOCRTests() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final results = await IOSTestService.testOCRFeatures();
      setState(() {
        _testResults = {...(_testResults ?? {}), 'ocr_tests': results};
      });
      
      HapticFeedback.mediumImpact();
      debugPrint('✅ OCRテスト完了');
    } catch (e) {
      debugPrint('❌ OCRテストエラー: $e');
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  /// 総合レポート生成
  Future<void> _generateReport() async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final report = await IOSTestService.generateComprehensiveReport();
      setState(() {
        _comprehensiveReport = report;
      });
      
      HapticFeedback.lightImpact();
      debugPrint('📄 レポート生成完了');
    } catch (e) {
      debugPrint('❌ レポート生成エラー: $e');
      HapticFeedback.heavyImpact();
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS機能テスト'),
        backgroundColor: AppTheme.darkGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunningTests ? null : () {
              setState(() {
                _testResults = null;
                _comprehensiveReport = null;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: AppTheme.responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // テスト説明
                AccessibleCard(
                  semanticLabel: 'iOS機能テストの説明',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_iphone, color: AppTheme.cyan),
                          const SizedBox(width: 8),
                          Text(
                            'iOS版機能テスト',
                            style: TextStyle(
                              fontSize: AppTheme.responsiveFontSize(context, 18),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'iOS版eFootball Analyzerの機能とパフォーマンスをテストします。\n'
                        '• 基本機能テスト\n'
                        '• OCR機能テスト\n'
                        '• パフォーマンス測定\n'
                        '• デバイス固有機能確認',
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFontSize(context, 14),
                          color: AppTheme.veryLightGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // テストボタン群
                Expanded(
                  child: GridView.count(
                    crossAxisCount: AppTheme.getResponsiveColumns(context, mobile: 1, tablet: 2),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      // 基本機能テスト
                      AccessibleButton(
                        onPressed: _isRunningTests ? null : _runBasicTests,
                        semanticLabel: '基本機能テストを実行',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.settings,
                              color: AppTheme.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '基本機能テスト',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // OCR機能テスト
                      AccessibleButton(
                        onPressed: _isRunningTests ? null : _runOCRTests,
                        semanticLabel: 'OCR機能テストを実行',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: AppTheme.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'OCR機能テスト',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 総合レポート
                      AccessibleButton(
                        onPressed: _isRunningTests ? null : _generateReport,
                        semanticLabel: '総合レポートを生成',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assessment,
                              color: AppTheme.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '総合レポート',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // プログレス表示
                if (_isRunningTests) ...[
                  const SizedBox(height: 16),
                  ProgressIndicatorWidget(
                    progress: 0.5, // アニメーション用
                    label: 'テスト実行中...',
                    isVisible: true,
                  ),
                ],

                // テスト結果表示
                if (_testResults != null) ...[
                  const SizedBox(height: 16),
                  AccessibleCard(
                    semanticLabel: 'テスト結果',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'テスト結果',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cyan,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._buildTestResultWidgets(),
                      ],
                    ),
                  ),
                ],

                // 総合レポート表示
                if (_comprehensiveReport != null) ...[
                  const SizedBox(height: 16),
                  AccessibleCard(
                    semanticLabel: '総合レポート',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '総合レポート',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGray,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _comprehensiveReport!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.veryLightGray,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
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

  List<Widget> _buildTestResultWidgets() {
    final results = <Widget>[];
    
    if (_testResults!['tests'] != null) {
      final tests = _testResults!['tests'] as Map<String, dynamic>;
      
      tests.forEach((testName, testResult) {
        final status = testResult['status'] ?? 'unknown';
        final isSuccess = status == 'success';
        
        results.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppTheme.green : AppTheme.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  testName,
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  status,
                  style: TextStyle(
                    color: isSuccess ? AppTheme.green : AppTheme.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    
    return results;
  }
}
