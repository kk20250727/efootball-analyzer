import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// パフォーマンス監視サービス
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};
  final Queue<PerformanceMetric> _metrics = Queue<PerformanceMetric>();
  static const int _maxMetrics = 100;

  /// パフォーマンス計測開始
  static void startTimer(String operationName) {
    _instance._timers[operationName] = Stopwatch()..start();
    debugPrint('⏱️ タイマー開始: $operationName');
  }

  /// パフォーマンス計測終了
  static Duration? stopTimer(String operationName) {
    final timer = _instance._timers.remove(operationName);
    if (timer == null) {
      debugPrint('⚠️ タイマーが見つかりません: $operationName');
      return null;
    }

    timer.stop();
    final duration = timer.elapsed;
    
    // メトリクスに記録
    _instance._addMetric(PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
    ));

    debugPrint('✅ $operationName 完了: ${duration.inMilliseconds}ms');
    return duration;
  }

  /// 非同期操作のパフォーマンス測定
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      debugPrint('❌ $operationName でエラー: $e');
      rethrow;
    }
  }

  /// 同期操作のパフォーマンス測定
  static T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      debugPrint('❌ $operationName でエラー: $e');
      rethrow;
    }
  }

  /// メトリクスを追加
  void _addMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // 最大数を超えた場合は古いものを削除
    while (_metrics.length > _maxMetrics) {
      _metrics.removeFirst();
    }

    // 警告しきい値チェック
    _checkPerformanceThresholds(metric);
  }

  /// パフォーマンス警告しきい値チェック
  void _checkPerformanceThresholds(PerformanceMetric metric) {
    const Map<String, int> thresholds = {
      'OCR処理': 5000,  // 5秒
      '画像圧縮': 3000,  // 3秒
      'データ解析': 2000, // 2秒
      'キャッシュ保存': 1000, // 1秒
      'Firebase操作': 3000, // 3秒
    };

    for (final entry in thresholds.entries) {
      if (metric.operationName.contains(entry.key) && 
          metric.duration.inMilliseconds > entry.value) {
        debugPrint('🐌 パフォーマンス警告: ${metric.operationName} が${entry.value}msを超過 (${metric.duration.inMilliseconds}ms)');
      }
    }
  }

  /// パフォーマンスレポートを生成
  static Map<String, dynamic> generateReport() {
    final metrics = _instance._metrics.toList();
    
    if (metrics.isEmpty) {
      return {'message': 'パフォーマンスデータがありません'};
    }

    // 操作別の統計
    final Map<String, List<Duration>> operationDurations = {};
    for (final metric in metrics) {
      operationDurations.putIfAbsent(metric.operationName, () => []);
      operationDurations[metric.operationName]!.add(metric.duration);
    }

    final Map<String, Map<String, dynamic>> operationStats = {};
    
    for (final entry in operationDurations.entries) {
      final durations = entry.value;
      durations.sort();
      
      final total = durations.fold<Duration>(Duration.zero, (a, b) => a + b);
      final average = Duration(microseconds: total.inMicroseconds ~/ durations.length);
      final median = durations[durations.length ~/ 2];
      final min = durations.first;
      final max = durations.last;
      
      operationStats[entry.key] = {
        'count': durations.length,
        'averageMs': average.inMilliseconds,
        'medianMs': median.inMilliseconds,
        'minMs': min.inMilliseconds,
        'maxMs': max.inMilliseconds,
        'totalMs': total.inMilliseconds,
      };
    }

    // 全体統計
    final allDurations = metrics.map((m) => m.duration).toList();
    allDurations.sort();
    
    final totalOperations = metrics.length;
    final timeRange = metrics.isNotEmpty 
        ? metrics.last.timestamp.difference(metrics.first.timestamp)
        : Duration.zero;

    return {
      'overview': {
        'totalOperations': totalOperations,
        'timeRangeMinutes': timeRange.inMinutes,
        'averageOperationsPerMinute': timeRange.inMinutes > 0 
            ? (totalOperations / timeRange.inMinutes).toStringAsFixed(2)
            : '0',
      },
      'operationStats': operationStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// パフォーマンスレポートをコンソールに出力
  static void printReport() {
    final report = generateReport();
    
    debugPrint('\n📊 === パフォーマンスレポート ===');
    debugPrint('📈 概要:');
    
    final overview = report['overview'] as Map<String, dynamic>?;
    if (overview != null) {
      debugPrint('  • 総操作数: ${overview['totalOperations']}');
      debugPrint('  • 測定期間: ${overview['timeRangeMinutes']}分');
      debugPrint('  • 平均操作頻度: ${overview['averageOperationsPerMinute']}回/分');
    }

    debugPrint('\n⏱️ 操作別統計:');
    final operationStats = report['operationStats'] as Map<String, dynamic>?;
    if (operationStats != null) {
      for (final entry in operationStats.entries) {
        final stats = entry.value as Map<String, dynamic>;
        debugPrint('  📌 ${entry.key}:');
        debugPrint('    • 実行回数: ${stats['count']}回');
        debugPrint('    • 平均時間: ${stats['averageMs']}ms');
        debugPrint('    • 中央値: ${stats['medianMs']}ms');
        debugPrint('    • 最短/最長: ${stats['minMs']}ms / ${stats['maxMs']}ms');
      }
    }
    
    debugPrint('================================\n');
  }

  /// メトリクスをクリア
  static void clearMetrics() {
    _instance._metrics.clear();
    debugPrint('📊 パフォーマンスメトリクスをクリアしました');
  }

  /// アクティブなタイマー数を取得
  static int getActiveTimersCount() {
    return _instance._timers.length;
  }

  /// アクティブなタイマーの一覧を取得
  static List<String> getActiveTimers() {
    return _instance._timers.keys.toList();
  }

  /// メモリ使用量監視（概算）
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // メモリ使用量の簡易監視（実際の値ではなく目安）
      debugPrint('💾 メモリ使用量チェック: $context');
    }
  }

  /// パフォーマンス最適化の提案
  static List<String> getOptimizationSuggestions() {
    final report = generateReport();
    final suggestions = <String>[];
    
    final operationStats = report['operationStats'] as Map<String, dynamic>?;
    if (operationStats != null) {
      for (final entry in operationStats.entries) {
        final stats = entry.value as Map<String, dynamic>;
        final averageMs = stats['averageMs'] as int;
        final maxMs = stats['maxMs'] as int;
        
        if (entry.key.contains('OCR') && averageMs > 3000) {
          suggestions.add('OCR処理が遅いです。画像のサイズを小さくするか、品質を調整してください。');
        }
        
        if (entry.key.contains('Firebase') && averageMs > 2000) {
          suggestions.add('Firebase操作が遅いです。インターネット接続を確認するか、キャッシュの利用を検討してください。');
        }
        
        if (maxMs > averageMs * 3) {
          suggestions.add('${entry.key}で処理時間にばらつきがあります。安定性の向上を検討してください。');
        }
      }
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('パフォーマンスは良好です！');
    }
    
    return suggestions;
  }
}

/// パフォーマンスメトリクスのデータクラス
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceMetric(operationName: $operationName, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp)';
  }
}
