import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/ios_test_service.dart';
import '../services/performance_service.dart';
import '../services/cache_service.dart';
import '../utils/app_theme.dart';
import '../widgets/accessible_card.dart';

/// アプリの現在状態表示画面
class AppStatusScreen extends StatefulWidget {
  const AppStatusScreen({super.key});

  @override
  State<AppStatusScreen> createState() => _AppStatusScreenState();
}

class _AppStatusScreenState extends State<AppStatusScreen> {
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _appStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppStatus();
  }

  Future<void> _loadAppStatus() async {
    try {
      // アプリ情報取得
      final packageInfo = await PackageInfo.fromPlatform();
      
      // キャッシュ統計
      final cacheStats = await CacheService.getCacheStats();
      
      // パフォーマンスレポート
      final performanceReport = PerformanceService.generateReport();
      
      // デバイス情報
      final deviceInfo = await _getDeviceInfo();
      
      setState(() {
        _packageInfo = packageInfo;
        _appStatus = {
          'app_info': {
            'name': packageInfo.appName,
            'version': packageInfo.version,
            'build_number': packageInfo.buildNumber,
            'package_name': packageInfo.packageName,
          },
          'cache_stats': cacheStats,
          'performance': performanceReport,
          'device_info': deviceInfo,
          'build_time': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('アプリ状態取得エラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final binding = WidgetsBinding.instance;
      final window = binding.platformDispatcher.views.first;
      final size = window.physicalSize;
      final devicePixelRatio = window.devicePixelRatio;
      
      return {
        'platform': Theme.of(context).platform.toString(),
        'screen_size': {
          'width': size.width,
          'height': size.height,
          'logical_width': size.width / devicePixelRatio,
          'logical_height': size.height / devicePixelRatio,
          'device_pixel_ratio': devicePixelRatio,
        },
        'is_ios': Theme.of(context).platform == TargetPlatform.iOS,
        'is_debug': !const bool.fromEnvironment('dart.vm.product'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリ状態'),
        backgroundColor: AppTheme.darkGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAppStatus();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  padding: AppTheme.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // アプリ基本情報
                      if (_packageInfo != null) _buildAppInfoCard(),
                      const SizedBox(height: 16),
                      
                      // デバイス情報
                      if (_appStatus?['device_info'] != null) _buildDeviceInfoCard(),
                      const SizedBox(height: 16),
                      
                      // キャッシュ統計
                      if (_appStatus?['cache_stats'] != null) _buildCacheStatsCard(),
                      const SizedBox(height: 16),
                      
                      // パフォーマンス統計
                      if (_appStatus?['performance'] != null) _buildPerformanceCard(),
                      const SizedBox(height: 16),
                      
                      // アクションボタン
                      _buildActionButtons(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return AccessibleCard(
      semanticLabel: 'アプリケーション情報',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: AppTheme.cyan),
              const SizedBox(width: 8),
              Text(
                'アプリ情報',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('アプリ名', _packageInfo!.appName),
          _buildInfoRow('バージョン', _packageInfo!.version),
          _buildInfoRow('ビルド番号', _packageInfo!.buildNumber),
          _buildInfoRow('パッケージID', _packageInfo!.packageName),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    final deviceInfo = _appStatus!['device_info'] as Map<String, dynamic>;
    final screenSize = deviceInfo['screen_size'] as Map<String, dynamic>?;
    
    return AccessibleCard(
      semanticLabel: 'デバイス情報',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: AppTheme.green),
              const SizedBox(width: 8),
              Text(
                'デバイス情報',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('プラットフォーム', deviceInfo['platform']?.toString() ?? 'Unknown'),
          _buildInfoRow('iOS', deviceInfo['is_ios'] == true ? 'Yes' : 'No'),
          _buildInfoRow('デバッグモード', deviceInfo['is_debug'] == true ? 'Yes' : 'No'),
          if (screenSize != null) ...[
            _buildInfoRow('画面サイズ', '${screenSize['logical_width']?.toInt()} x ${screenSize['logical_height']?.toInt()}'),
            _buildInfoRow('密度', '${screenSize['device_pixel_ratio']?.toStringAsFixed(1)}x'),
          ],
        ],
      ),
    );
  }

  Widget _buildCacheStatsCard() {
    final cacheStats = _appStatus!['cache_stats'] as Map<String, dynamic>;
    
    return AccessibleCard(
      semanticLabel: 'キャッシュ統計',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: AppTheme.orange),
              const SizedBox(width: 8),
              Text(
                'キャッシュ統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('総エントリ数', cacheStats['totalEntries']?.toString() ?? '0'),
          _buildInfoRow('サイズ (KB)', cacheStats['sizeInKB']?.toString() ?? '0'),
          _buildInfoRow('サイズ (MB)', cacheStats['sizeInMB']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    final performance = _appStatus!['performance'] as Map<String, dynamic>;
    final overview = performance['overview'] as Map<String, dynamic>?;
    
    return AccessibleCard(
      semanticLabel: 'パフォーマンス統計',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: AppTheme.yellow),
              const SizedBox(width: 8),
              Text(
                'パフォーマンス統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (overview != null) ...[
            _buildInfoRow('総操作数', overview['totalOperations']?.toString() ?? '0'),
            _buildInfoRow('測定期間', '${overview['timeRangeMinutes']?.toString() ?? '0'}分'),
            _buildInfoRow('操作頻度', '${overview['averageOperationsPerMinute'] ?? '0'}/分'),
          ] else ...[
            Text(
              'パフォーマンスデータなし',
              style: TextStyle(color: AppTheme.veryLightGray),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final report = await IOSTestService.generateComprehensiveReport();
                    _showReportDialog(report);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('レポート生成エラー: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.assessment),
                label: const Text('総合レポート'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _formatAppStatusAsText()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('アプリ状態をクリップボードにコピーしました')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('情報コピー'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _loadAppStatus();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('状態を更新'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.veryLightGray,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('総合レポート'),
        content: SingleChildScrollView(
          child: SelectableText(
            report,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('レポートをコピーしました')),
              );
            },
            child: const Text('コピー'),
          ),
        ],
      ),
    );
  }

  String _formatAppStatusAsText() {
    if (_appStatus == null) return 'アプリ状態データなし';
    
    final buffer = StringBuffer();
    buffer.writeln('=== eFootball Analyzer 状態レポート ===');
    buffer.writeln('生成日時: ${DateTime.now()}');
    buffer.writeln('');
    
    if (_packageInfo != null) {
      buffer.writeln('アプリ情報:');
      buffer.writeln('  - 名前: ${_packageInfo!.appName}');
      buffer.writeln('  - バージョン: ${_packageInfo!.version}');
      buffer.writeln('  - ビルド: ${_packageInfo!.buildNumber}');
      buffer.writeln('');
    }
    
    final deviceInfo = _appStatus!['device_info'];
    if (deviceInfo != null) {
      buffer.writeln('デバイス情報:');
      buffer.writeln('  - プラットフォーム: ${deviceInfo['platform']}');
      buffer.writeln('  - iOS: ${deviceInfo['is_ios']}');
      buffer.writeln('  - デバッグ: ${deviceInfo['is_debug']}');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}
