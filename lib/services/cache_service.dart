import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_result.dart';

/// キャッシュサービス - パフォーマンス向上のためのデータキャッシュ
class CacheService {
  static SharedPreferences? _prefs;
  static const Duration _defaultCacheExpiry = Duration(hours: 24);
  
  // キャッシュキー定数
  static const String _userDataKey = 'user_data_cache';
  static const String _matchDataKey = 'match_data_cache';
  static const String _squadDataKey = 'squad_data_cache';
  static const String _ocrResultKey = 'ocr_result_cache';
  static const String _lastCacheUpdateKey = 'last_cache_update';

  /// SharedPreferencesの初期化
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('CacheService初期化完了');
    } catch (e) {
      debugPrint('CacheService初期化エラー: $e');
    }
  }

  /// キャッシュの有効性をチェック
  static bool _isCacheValid(String key, {Duration? customExpiry}) {
    if (_prefs == null) return false;
    
    final lastUpdate = _prefs!.getInt('${key}_timestamp');
    if (lastUpdate == null) return false;
    
    final expiryDuration = customExpiry ?? _defaultCacheExpiry;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate).add(expiryDuration);
    
    return DateTime.now().isBefore(expiryTime);
  }

  /// データをキャッシュに保存
  static Future<bool> _saveToCache<T>(String key, T data) async {
    if (_prefs == null) {
      await initialize();
      if (_prefs == null) return false;
    }

    try {
      final jsonString = jsonEncode(data);
      final success = await _prefs!.setString(key, jsonString);
      
      if (success) {
        await _prefs!.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
        debugPrint('キャッシュ保存成功: $key');
      }
      
      return success;
    } catch (e) {
      debugPrint('キャッシュ保存エラー: $key - $e');
      return false;
    }
  }

  /// キャッシュからデータを取得
  static T? _getFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    if (_prefs == null || !_isCacheValid(key)) return null;

    try {
      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      final jsonData = jsonDecode(jsonString);
      return fromJson(jsonData as Map<String, dynamic>);
    } catch (e) {
      debugPrint('キャッシュ取得エラー: $key - $e');
      return null;
    }
  }

  /// リストデータをキャッシュから取得
  static List<T>? _getListFromCache<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    if (_prefs == null || !_isCacheValid(key)) return null;

    try {
      final jsonString = _prefs!.getString(key);
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('キャッシュリスト取得エラー: $key - $e');
      return null;
    }
  }

  /// 試合データをキャッシュに保存
  static Future<bool> cacheMatchData(List<Map<String, dynamic>> matchData) async {
    return _saveToCache(_matchDataKey, matchData);
  }

  /// 試合データをキャッシュから取得
  static List<Map<String, dynamic>>? getCachedMatchData() {
    return _getListFromCache(_matchDataKey, (json) => json);
  }

  /// スカッドデータをキャッシュに保存
  static Future<bool> cacheSquadData(List<Map<String, dynamic>> squadData) async {
    return _saveToCache(_squadDataKey, squadData);
  }

  /// スカッドデータをキャッシュから取得
  static List<Map<String, dynamic>>? getCachedSquadData() {
    return _getListFromCache(_squadDataKey, (json) => json);
  }

  /// OCR結果をキャッシュに保存（一時的な結果保持）
  static Future<bool> cacheOCRResult(String imageHash, String ocrText) async {
    final cacheData = {
      'imageHash': imageHash,
      'ocrText': ocrText,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return _saveToCache('${_ocrResultKey}_$imageHash', cacheData);
  }

  /// OCR結果をキャッシュから取得
  static String? getCachedOCRResult(String imageHash) {
    final cacheData = _getFromCache<Map<String, dynamic>>(
      '${_ocrResultKey}_$imageHash',
      (json) => json,
    );
    
    if (cacheData == null) return null;
    
    // OCR結果は1時間のみ有効
    final timestamp = cacheData['timestamp'] as int?;
    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final isExpired = DateTime.now().difference(cacheTime).inHours > 1;
      if (isExpired) {
        clearOCRCache(imageHash);
        return null;
      }
    }
    
    return cacheData['ocrText'] as String?;
  }

  /// ユーザーデータをキャッシュに保存
  static Future<bool> cacheUserData(Map<String, dynamic> userData) async {
    return _saveToCache(_userDataKey, userData);
  }

  /// ユーザーデータをキャッシュから取得
  static Map<String, dynamic>? getCachedUserData() {
    return _getFromCache(_userDataKey, (json) => json);
  }

  /// 特定のキャッシュを削除
  static Future<bool> clearCache(String key) async {
    if (_prefs == null) return false;
    
    try {
      await _prefs!.remove(key);
      await _prefs!.remove('${key}_timestamp');
      debugPrint('キャッシュ削除: $key');
      return true;
    } catch (e) {
      debugPrint('キャッシュ削除エラー: $key - $e');
      return false;
    }
  }

  /// OCRキャッシュを削除
  static Future<void> clearOCRCache([String? imageHash]) async {
    if (imageHash != null) {
      await clearCache('${_ocrResultKey}_$imageHash');
    } else {
      // 全てのOCRキャッシュを削除
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => key.startsWith(_ocrResultKey));
        for (final key in keys) {
          await _prefs!.remove(key);
        }
        debugPrint('全OCRキャッシュ削除完了');
      }
    }
  }

  /// 全キャッシュを削除
  static Future<void> clearAllCache() async {
    if (_prefs == null) return;
    
    try {
      await _prefs!.clear();
      debugPrint('全キャッシュ削除完了');
    } catch (e) {
      debugPrint('全キャッシュ削除エラー: $e');
    }
  }

  /// キャッシュサイズを取得（概算）
  static Future<int> getCacheSize() async {
    if (_prefs == null) return 0;
    
    try {
      final keys = _prefs!.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          totalSize += value.length * 2; // UTF-16エンコーディングの概算
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('キャッシュサイズ取得エラー: $e');
      return 0;
    }
  }

  /// キャッシュ統計情報を取得
  static Future<Map<String, dynamic>> getCacheStats() async {
    final size = await getCacheSize();
    final keys = _prefs?.getKeys() ?? <String>{};
    
    return {
      'totalSize': size,
      'totalEntries': keys.length,
      'sizeInKB': (size / 1024).toStringAsFixed(2),
      'sizeInMB': (size / (1024 * 1024)).toStringAsFixed(2),
      'lastUpdate': _prefs?.getInt(_lastCacheUpdateKey),
    };
  }

  /// キャッシュ最適化（古いキャッシュを自動削除）
  static Future<void> optimizeCache() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys().toList();
      final now = DateTime.now();
      int deletedCount = 0;
      
      for (final key in keys) {
        if (key.endsWith('_timestamp')) continue;
        
        final timestampKey = '${key}_timestamp';
        final timestamp = _prefs!.getInt(timestampKey);
        
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final age = now.difference(cacheTime);
          
          // 24時間以上古いキャッシュを削除
          if (age.inHours > 24) {
            await _prefs!.remove(key);
            await _prefs!.remove(timestampKey);
            deletedCount++;
          }
        }
      }
      
      debugPrint('キャッシュ最適化完了: ${deletedCount}件削除');
      await _prefs!.setInt(_lastCacheUpdateKey, now.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('キャッシュ最適化エラー: $e');
    }
  }
}
