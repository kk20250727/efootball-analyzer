import 'package:flutter/foundation.dart';
import '../models/match_result.dart';

class MatchContext {
  String leftTeam = '';
  String rightTeam = '';
  String leftUser = '';
  String rightUser = '';
  DateTime? matchDate;
  
  bool get isValid {
    return leftUser.isNotEmpty && rightUser.isNotEmpty;
  }
}

class ParsedMatchData {
  final String myTeamName;
  final String opponentTeamName;
  final String myUsername;
  final String opponentUsername;
  final int myScore;
  final int opponentScore;
  final DateTime matchDate;

  ParsedMatchData({
    required this.myTeamName,
    required this.opponentTeamName,
    required this.myUsername,
    required this.opponentUsername,
    required this.myScore,
    required this.opponentScore,
    required this.matchDate,
  });
}

class MatchParserService {
  static List<ParsedMatchData> parseMatchData(String ocrText, String userEfootballUsername) {
    List<ParsedMatchData> matches = [];
    
    // テキストを行に分割し、空行を除去
    List<String> lines = ocrText.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    debugPrint('OCR解析開始: ${lines.length}行のテキスト');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // スコアパターンを検索（より柔軟なパターン）
      RegExp scorePattern = RegExp(r'(\d+)\s*[-:\s]\s*(\d+)');
      Match? scoreMatch = scorePattern.firstMatch(line);
      
      if (scoreMatch != null) {
        try {
          int score1 = int.parse(scoreMatch.group(1)!);
          int score2 = int.parse(scoreMatch.group(2)!);
          
          debugPrint('スコア発見: $score1 - $score2 (行 $i: $line)');
          
          // スコア周辺からマッチ情報を抽出
          MatchContext context = _extractMatchContext(lines, i, userEfootballUsername);
          
          if (context.isValid) {
            // ユーザーがどちら側かを判定
            bool userIsLeftSide = _determineUserSide(context, userEfootballUsername);
            
            int myScore = userIsLeftSide ? score1 : score2;
            int opponentScore = userIsLeftSide ? score2 : score1;
            String myTeamName = userIsLeftSide ? context.leftTeam : context.rightTeam;
            String opponentTeamName = userIsLeftSide ? context.rightTeam : context.leftTeam;
            String myUsername = userIsLeftSide ? context.leftUser : context.rightUser;
            String opponentUsername = userIsLeftSide ? context.rightUser : context.leftUser;
            
            matches.add(ParsedMatchData(
              myTeamName: myTeamName,
              opponentTeamName: opponentTeamName,
              myUsername: myUsername,
              opponentUsername: opponentUsername,
              myScore: myScore,
              opponentScore: opponentScore,
              matchDate: context.matchDate ?? DateTime.now(),
            ));
            
            debugPrint('マッチデータ追加: $myTeamName($myUsername) $myScore - $opponentScore $opponentTeamName($opponentUsername)');
          }
          
        } catch (e) {
          debugPrint('スコア解析エラー: $e');
          continue;
        }
      }
    }
    
    debugPrint('解析完了: ${matches.length}試合のデータを抽出');
    return matches;
  }
  
  static MatchContext _extractMatchContext(List<String> lines, int scoreIndex, String userEfootballUsername) {
    MatchContext context = MatchContext();
    
    // スコア行の前後10行を検索範囲とする
    int startIndex = (scoreIndex - 10).clamp(0, lines.length);
    int endIndex = (scoreIndex + 10).clamp(0, lines.length);
    
    for (int i = startIndex; i < endIndex; i++) {
      String line = lines[i];
      
      // 日付パターンを検索（複数のフォーマットに対応）
      if (context.matchDate == null) {
        context.matchDate = _parseDateTime(line);
      }
      
      // ユーザー名パターンを検索
      List<String> potentialUsers = _extractPotentialUsernames(line);
      for (String user in potentialUsers) {
        if (user == userEfootballUsername) {
          // ユーザー自身を発見
          if (context.leftUser.isEmpty) {
            context.leftUser = user;
            context.leftTeam = _findTeamName(lines, i);
          } else if (context.rightUser.isEmpty) {
            context.rightUser = user;
            context.rightTeam = _findTeamName(lines, i);
          }
        } else if (context.leftUser.isEmpty || context.rightUser.isEmpty) {
          // 相手ユーザーの候補
          if (context.leftUser.isEmpty) {
            context.leftUser = user;
            context.leftTeam = _findTeamName(lines, i);
          } else if (context.rightUser.isEmpty && user != context.leftUser) {
            context.rightUser = user;
            context.rightTeam = _findTeamName(lines, i);
          }
        }
      }
      
      // チーム名パターンを検索
      String potentialTeam = _extractPotentialTeamName(line);
      if (potentialTeam.isNotEmpty) {
        if (context.leftTeam.isEmpty) {
          context.leftTeam = potentialTeam;
        } else if (context.rightTeam.isEmpty && potentialTeam != context.leftTeam) {
          context.rightTeam = potentialTeam;
        }
      }
    }
    
    // デフォルト値を設定
    context.leftTeam = context.leftTeam.isEmpty ? 'Team A' : context.leftTeam;
    context.rightTeam = context.rightTeam.isEmpty ? 'Team B' : context.rightTeam;
    context.leftUser = context.leftUser.isEmpty ? userEfootballUsername : context.leftUser;
    context.rightUser = context.rightUser.isEmpty ? 'Opponent' : context.rightUser;
    context.matchDate ??= DateTime.now();
    
    return context;
  }
  
  static DateTime? _parseDateTime(String text) {
    // 複数の日付フォーマットに対応
    List<RegExp> datePatterns = [
      RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{1,2})'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2})'),
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{1,2})'),
      RegExp(r'(\d{4})年(\d{1,2})月(\d{1,2})日\s+(\d{1,2}):(\d{1,2})'),
    ];
    
    for (RegExp pattern in datePatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        try {
          int year, month, day, hour, minute;
          
          if (pattern.pattern.contains('年')) {
            // 日本語フォーマット
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
            hour = int.parse(match.group(4)!);
            minute = int.parse(match.group(5)!);
          } else if (pattern.pattern.startsWith(r'\(\d{1,2\}')) {
            // MM/DD/YYYY フォーマット
            month = int.parse(match.group(1)!);
            day = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);
            hour = int.parse(match.group(4)!);
            minute = int.parse(match.group(5)!);
          } else {
            // YYYY/MM/DD または YYYY-MM-DD フォーマット
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
            hour = int.parse(match.group(4)!);
            minute = int.parse(match.group(5)!);
          }
          
          return DateTime(year, month, day, hour, minute);
        } catch (e) {
          debugPrint('日付解析エラー: $e');
        }
      }
    }
    
    return null;
  }
  
  static List<String> _extractPotentialUsernames(String text) {
    List<String> usernames = [];
    
    // ユーザー名のパターン（英数字、アンダースコア、ハイフン）
    RegExp usernamePattern = RegExp(r'\b[A-Za-z0-9_\-\.]{3,20}\b');
    Iterable<Match> matches = usernamePattern.allMatches(text);
    
    for (Match match in matches) {
      String username = match.group(0)!;
      
      // 明らかにユーザー名ではない文字列を除外
      if (!_isLikelyNotUsername(username)) {
        usernames.add(username);
      }
    }
    
    return usernames;
  }
  
  static bool _isLikelyNotUsername(String text) {
    // 数字のみ
    if (RegExp(r'^\d+$').hasMatch(text)) return true;
    
    // 一般的でない単語
    List<String> excludeWords = [
      'vs', 'VS', '対戦', '年', '月', '日', '時', '分',
      'WIN', 'LOSE', 'DRAW', 'win', 'lose', 'draw',
      'eFootball', 'KONAMI', 'Football', 'Soccer'
    ];
    
    for (String word in excludeWords) {
      if (text.contains(word)) return true;
    }
    
    return false;
  }
  
  static String _extractPotentialTeamName(String text) {
    // チーム名の候補を抽出
    String trimmed = text.trim();
    
    // 短すぎるか長すぎる場合は除外
    if (trimmed.length < 3 || trimmed.length > 30) return '';
    
    // 数字のみは除外
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return '';
    
    // スコアパターンは除外
    if (RegExp(r'\d+\s*[-:]\s*\d+').hasMatch(trimmed)) return '';
    
    // 日付パターンは除外
    if (RegExp(r'\d{4}[/-]\d{1,2}[/-]\d{1,2}').hasMatch(trimmed)) return '';
    
    return trimmed;
  }
  
  static String _findTeamName(List<String> lines, int userIndex) {
    // ユーザー名の前後1行でチーム名を検索
    for (int offset in [-1, 1]) {
      int index = userIndex + offset;
      if (index >= 0 && index < lines.length) {
        String potentialTeam = _extractPotentialTeamName(lines[index]);
        if (potentialTeam.isNotEmpty) {
          return potentialTeam;
        }
      }
    }
    
    return '';
  }
  
  static bool _determineUserSide(MatchContext context, String userEfootballUsername) {
    // ユーザー名が左側にあるかどうかを判定
    return context.leftUser == userEfootballUsername;
  }

  static MatchResult determineResult(ParsedMatchData matchData, String userEfootballUsername) {
    // ユーザー名の一致を確認
    bool isMyScore = matchData.myUsername == userEfootballUsername;
    
    int myScore = isMyScore ? matchData.myScore : matchData.opponentScore;
    int opponentScore = isMyScore ? matchData.opponentScore : matchData.myScore;
    
    if (myScore > opponentScore) {
      return MatchResult.win;
    } else if (myScore < opponentScore) {
      return MatchResult.loss;
    } else {
      return MatchResult.draw;
    }
  }

  static List<String> extractUsernames(String ocrText) {
    List<String> usernames = [];
    
    // ユーザー名のパターンを検索（英数字と記号の組み合わせ）
    RegExp usernamePattern = RegExp(r'[A-Za-z0-9_\-\.]{3,20}');
    Iterable<Match> matches = usernamePattern.allMatches(ocrText);
    
    for (Match match in matches) {
      String username = match.group(0)!;
      // 明らかにユーザー名ではない文字列を除外
      if (!username.contains(RegExp(r'^\d+$')) && // 数字のみは除外
          !username.contains('vs') &&
          !username.contains('対戦') &&
          !username.contains('年') &&
          !username.contains('月') &&
          !username.contains('日')) {
        usernames.add(username);
      }
    }
    
    // 重複を除去
    return usernames.toSet().toList();
  }
}
