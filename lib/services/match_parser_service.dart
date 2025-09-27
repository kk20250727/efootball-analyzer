import 'package:flutter/foundation.dart';
import '../models/match_result.dart';

/// 試合結果解析用のデータクラス
class ParsedMatchData {
  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final String homeUsername;
  final String awayUsername;
  final DateTime? matchDate;
  final MatchResult result;
  final bool isUserHome;

  ParsedMatchData({
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.homeUsername,
    required this.awayUsername,
    this.matchDate,
    required this.result,
    required this.isUserHome,
  });

  // 後方互換性のためのゲッター
  String get myTeamName => isUserHome ? homeTeam : awayTeam;
  String get opponentTeamName => isUserHome ? awayTeam : homeTeam;
  String get myUsername => isUserHome ? homeUsername : awayUsername;
  String get opponentUsername => isUserHome ? awayUsername : homeUsername;
  int get myScore => isUserHome ? homeScore : awayScore;
  int get opponentScore => isUserHome ? awayScore : homeScore;

  /// MapからParsedMatchDataを作成
  factory ParsedMatchData.fromMap(Map<String, dynamic> map, String userEfootballUsername) {
    final homeUsername = map['homeUsername'] as String;
    final awayUsername = map['awayUsername'] as String;
    final homeScore = map['homeScore'] as int;
    final awayScore = map['awayScore'] as int;
    
    // ユーザーがホームかアウェイかを判定
    final isUserHome = homeUsername == userEfootballUsername;
    
    // 試合結果を判定
    MatchResult result;
    if (isUserHome) {
      if (homeScore > awayScore) {
        result = MatchResult.win;
      } else if (homeScore < awayScore) {
        result = MatchResult.loss;
      } else {
        result = MatchResult.draw;
      }
    } else {
      if (awayScore > homeScore) {
        result = MatchResult.win;
      } else if (awayScore < homeScore) {
        result = MatchResult.loss;
      } else {
        result = MatchResult.draw;
      }
    }

    return ParsedMatchData(
      homeTeam: map['homeTeam'] as String,
      awayTeam: map['awayTeam'] as String,
      homeScore: homeScore,
      awayScore: awayScore,
      homeUsername: homeUsername,
      awayUsername: awayUsername,
      matchDate: map['matchDate'] as DateTime? ?? DateTime.now(),
      result: result,
      isUserHome: isUserHome,
    );
  }

  /// ParsedMatchDataをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homeUsername': homeUsername,
      'awayUsername': awayUsername,
      'matchDate': matchDate?.toIso8601String(),
      'result': result.name,
      'isUserHome': isUserHome,
    };
  }
}

/// 試合結果解析サービス
class MatchParserService {
  
  /// ユーザー名を抽出（eFootball形式対応）
  static List<String> extractUsernames(String text) {
    final usernames = <String>[];
    
    // eFootball特有のユーザー名パターン
    final patterns = [
      RegExp(r'[a-zA-Z0-9_-]{3,16}'), // 一般的なユーザー名パターン
      RegExp(r'@[a-zA-Z0-9_-]{3,16}'), // @付きユーザー名
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        String username = match.group(0)!;
        if (username.startsWith('@')) {
          username = username.substring(1);
        }
        
        // 有効なユーザー名かチェック
        if (_isValidEFootballUsername(username)) {
          usernames.add(username);
        }
      }
    }
    
    return usernames.toSet().toList();
  }

  /// 結果判定メソッド（後方互換性）
  static MatchResult determineResult(int myScore, int opponentScore) {
    if (myScore > opponentScore) {
      return MatchResult.win;
    } else if (myScore < opponentScore) {
      return MatchResult.loss;
    } else {
      return MatchResult.draw;
    }
  }

  /// 試合結果を解析（ParsedMatchDataのリストを返す）
  static List<ParsedMatchData> parseMatchResults(String text, String userEfootballUsername) {
    final matchDataList = parseMatchData(text, userEfootballUsername);
    return matchDataList.map((data) => ParsedMatchData.fromMap(data, userEfootballUsername)).toList();
  }

  /// eFootball形式の試合データを解析
  static List<Map<String, dynamic>> parseMatchData(String text, String userEfootballUsername) {
    debugPrint('=== 試合データ解析開始 ===');
    debugPrint('ユーザー名: $userEfootballUsername');
    debugPrint('解析対象テキスト:\n$text');
    
    final matches = <Map<String, dynamic>>[];
    
    try {
      // eFootball試合履歴の解析
      final matchBlocks = _extractMatchBlocks(text);
      debugPrint('抽出された試合ブロック数: ${matchBlocks.length}');
      
      for (int i = 0; i < matchBlocks.length; i++) {
        final block = matchBlocks[i];
        debugPrint('試合ブロック ${i + 1}: $block');
        
        final matchData = _parseMatchBlock(block, userEfootballUsername);
        if (matchData != null) {
          // データの妥当性をチェック
          if (_isValidMatchData(matchData)) {
            matches.add(matchData);
            debugPrint('試合データ解析成功: $matchData');
          } else {
            debugPrint('試合データが無効のためスキップ: $matchData');
          }
        }
      }
      
      debugPrint('=== 解析完了: ${matches.length}件の試合データ ===');
      return matches;
    } catch (e) {
      debugPrint('試合データ解析エラー: $e');
      return [];
    }
  }

  /// 試合ブロックを抽出
  static List<String> _extractMatchBlocks(String text) {
    final blocks = <String>[];
    final lines = text.split('\n');
    
    String currentBlock = '';
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // スコアパターンを含む行を探す
      if (RegExp(r'\d+\s*-\s*\d+').hasMatch(trimmedLine)) {
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock);
        }
        currentBlock = trimmedLine;
      } else if (currentBlock.isNotEmpty) {
        currentBlock += '\n$trimmedLine';
      }
    }
    
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock);
    }
    
    return blocks;
  }

  /// 個別の試合ブロックを解析
  static Map<String, dynamic>? _parseMatchBlock(String block, String userEfootballUsername) {
    try {
      // スコアパターンを抽出
      final scoreMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(block);
      if (scoreMatch == null) return null;
      
      final homeScore = int.parse(scoreMatch.group(1)!);
      final awayScore = int.parse(scoreMatch.group(2)!);
      
      // ユーザー名を抽出
      final usernames = extractUsernames(block);
      debugPrint('ブロックから抽出されたユーザー名: $usernames');
      
      if (usernames.length < 2) {
        debugPrint('ユーザー名が不足: ${usernames.length}個');
        return null;
      }
      
      String homeUsername, awayUsername;
      
      // ユーザーのユーザー名を探す
      if (usernames.contains(userEfootballUsername)) {
        final userIndex = usernames.indexOf(userEfootballUsername);
        if (userIndex == 0) {
          homeUsername = usernames[0];
          awayUsername = usernames.length > 1 ? usernames[1] : 'Unknown';
        } else {
          homeUsername = usernames[0];
          awayUsername = usernames[userIndex];
        }
      } else {
        // フォールバック: 最初の2つのユーザー名を使用
        homeUsername = usernames[0];
        awayUsername = usernames.length > 1 ? usernames[1] : usernames[0];
      }
      
      // チーム名を推定（簡易版）
      final homeTeam = _extractTeamName(block, true) ?? 'ホームチーム';
      final awayTeam = _extractTeamName(block, false) ?? 'アウェイチーム';
      
      // 日時を解析
      final matchDate = _parseEFootballDateTime(block) ?? DateTime.now();
      
      return {
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'homeUsername': homeUsername,
        'awayUsername': awayUsername,
        'matchDate': matchDate,
      };
    } catch (e) {
      debugPrint('試合ブロック解析エラー: $e');
      return null;
    }
  }

  /// チーム名を抽出
  static String? _extractTeamName(String text, bool isHome) {
    // チーム名の一般的なパターン
    final teamPatterns = [
      RegExp(r'(FC\s+\w+)'),
      RegExp(r'(\w+\s+FC)'),
      RegExp(r'(AC\s+\w+)'),
      RegExp(r'(\w+\s+AC)'),
      RegExp(r'(\w+\s+United)'),
      RegExp(r'(\w+\s+City)'),
    ];
    
    for (final pattern in teamPatterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        final teamNames = matches.map((m) => m.group(1)!).toList();
        if (teamNames.length >= 2) {
          return isHome ? teamNames[0] : teamNames[1];
        } else if (teamNames.length == 1) {
          return teamNames[0];
        }
      }
    }
    
    return null;
  }

  /// eFootball形式の日時を解析
  static DateTime? _parseEFootballDateTime(String text) {
    final datePatterns = [
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})'),
      RegExp(r'(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{2})'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})'),
    ];
    
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount >= 5) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            final hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);
            
            return DateTime(year, month, day, hour, minute);
          } else if (match.groupCount >= 4) {
            // 年が省略されている場合は現在年を使用
            final currentYear = DateTime.now().year;
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            final hour = int.parse(match.group(3)!);
            final minute = int.parse(match.group(4)!);
            
            return DateTime(currentYear, month, day, hour, minute);
          }
        } catch (e) {
          debugPrint('日時解析エラー: $e');
        }
      }
    }
    
    return null;
  }

  /// 有効なeFootballユーザー名かチェック（強化版）
  static bool _isValidEFootballUsername(String username) {
    // 基本的な長さチェック
    if (username.length < 3 || username.length > 16) return false;
    
    // 英数字とアンダースコア、ハイフンのみ許可
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(username)) return false;
    
    // システムテキストを除外（拡張版）
    final systemTexts = [
      // 基本ゲーム用語
      'score', 'time', 'match', 'game', 'player', 'team',
      'home', 'away', 'goal', 'result', 'date', 'win', 'lose',
      'draw', 'vs', 'div', 'rank', 'level', 'point', 'rating',
      
      // eFootball特有用語
      'efootball', 'pes', 'myclub', 'legend', 'featured',
      'potw', 'im', 'base', 'maxed', 'lv', 'ovr', 'stats',
      
      // UI要素
      'menu', 'settings', 'options', 'back', 'next', 'confirm',
      'cancel', 'ok', 'yes', 'no', 'start', 'finish', 'exit',
      
      // 数値・記号
      'null', 'none', 'empty', 'unknown', 'default', 'test',
      
      // 一般的な除外対象
      'admin', 'system', 'user', 'guest', 'temp', 'demo'
    ];
    
    final lowerUsername = username.toLowerCase();
    
    // システムテキストとの完全一致チェック
    if (systemTexts.contains(lowerUsername)) return false;
    
    // システムテキストを含むかチェック
    for (final systemText in systemTexts) {
      if (lowerUsername.contains(systemText)) return false;
    }
    
    // 数字のみは無効
    if (RegExp(r'^\d+$').hasMatch(username)) return false;
    
    // アンダースコアやハイフンのみは無効
    if (RegExp(r'^[_-]+$').hasMatch(username)) return false;
    
    // 連続する同じ文字が多すぎる場合は無効（例: "aaaa", "1111"）
    if (RegExp(r'(.)\1{3,}').hasMatch(username)) return false;
    
    // 英文字が含まれているかチェック（純粋な数字列を避ける）
    if (!RegExp(r'[a-zA-Z]').hasMatch(username)) return false;
    
    return true;
  }
  
  /// 試合データの妥当性をチェック
  static bool _isValidMatchData(Map<String, dynamic> matchData) {
    try {
      // 必須フィールドの存在チェック
      final requiredFields = ['homeScore', 'awayScore', 'homeUsername', 'awayUsername'];
      for (final field in requiredFields) {
        if (!matchData.containsKey(field) || matchData[field] == null) {
          debugPrint('必須フィールドが不足: $field');
          return false;
        }
      }
      
      // スコアの妥当性チェック
      final homeScore = matchData['homeScore'];
      final awayScore = matchData['awayScore'];
      
      if (homeScore is! int || awayScore is! int) {
        debugPrint('スコアが整数ではありません: home=$homeScore, away=$awayScore');
        return false;
      }
      
      if (homeScore < 0 || awayScore < 0) {
        debugPrint('スコアが負の数です: home=$homeScore, away=$awayScore');
        return false;
      }
      
      // eFootball の現実的なスコア範囲チェック（0-20点）
      if (homeScore > 20 || awayScore > 20) {
        debugPrint('スコアが現実的ではありません: home=$homeScore, away=$awayScore');
        return false;
      }
      
      // ユーザー名の妥当性チェック
      final homeUsername = matchData['homeUsername'] as String;
      final awayUsername = matchData['awayUsername'] as String;
      
      if (!_isValidEFootballUsername(homeUsername)) {
        debugPrint('無効なホームユーザー名: $homeUsername');
        return false;
      }
      
      if (!_isValidEFootballUsername(awayUsername)) {
        debugPrint('無効なアウェイユーザー名: $awayUsername');
        return false;
      }
      
      // 同じユーザー名での試合は無効
      if (homeUsername == awayUsername) {
        debugPrint('同じユーザー名での試合: $homeUsername');
        return false;
      }
      
      // 日時の妥当性チェック
      if (matchData.containsKey('matchDate') && matchData['matchDate'] != null) {
        final matchDate = matchData['matchDate'];
        if (matchDate is DateTime) {
          final now = DateTime.now();
          final oneYearAgo = now.subtract(const Duration(days: 365));
          final oneWeekFromNow = now.add(const Duration(days: 7));
          
          if (matchDate.isBefore(oneYearAgo) || matchDate.isAfter(oneWeekFromNow)) {
            debugPrint('試合日時が現実的ではありません: $matchDate');
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('試合データ妥当性チェックエラー: $e');
      return false;
    }
  }
}