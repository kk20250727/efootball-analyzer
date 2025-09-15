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
    
    debugPrint('=== eFootball OCR解析開始 ===');
    debugPrint('ユーザー名: $userEfootballUsername');
    debugPrint('OCRテキスト:\n$ocrText');
    
    // 全てのユーザー名を検出
    List<String> detectedUsernames = extractUsernames(ocrText);
    debugPrint('検出されたユーザー名: $detectedUsernames');
    
    // 指定されたユーザー名が含まれていない場合、柔軟に対応
    String targetUsername = userEfootballUsername;
    if (!detectedUsernames.contains(userEfootballUsername)) {
      debugPrint('指定ユーザー名 "$userEfootballUsername" が見つかりません');
      if (detectedUsernames.isNotEmpty) {
        // 最初に見つかったユーザー名を使用
        targetUsername = detectedUsernames.first;
        debugPrint('代替ユーザー名として "$targetUsername" を使用');
      }
    }
    
    // eFootballの試合履歴画面に特化した解析
    matches = _parseEFootballMatchHistory(ocrText, targetUsername);
    
    debugPrint('解析完了: ${matches.length}試合のデータを抽出');
    return matches;
  }

  static List<ParsedMatchData> _parseEFootballMatchHistory(String ocrText, String userEfootballUsername) {
    List<ParsedMatchData> matches = [];
    
    // 全体のテキストから試合ブロックを抽出
    List<String> matchBlocks = _extractMatchBlocks(ocrText);
    
    for (String block in matchBlocks) {
      ParsedMatchData? matchData = _parseMatchBlock(block, userEfootballUsername);
      if (matchData != null) {
        matches.add(matchData);
        debugPrint('試合データ抽出成功: ${matchData.myTeamName} vs ${matchData.opponentTeamName}');
      }
    }
    
    return matches;
  }

  static List<String> _extractMatchBlocks(String ocrText) {
    List<String> blocks = [];
    
    // 日時パターンで区切って試合ブロックを抽出
    List<String> lines = ocrText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    List<String> currentBlock = [];
    
    for (String line in lines) {
      // 日時パターンを検出（eFootball形式: 2025/09/13 18:19）
      if (RegExp(r'\d{4}/\d{1,2}/\d{1,2}\s+\d{1,2}:\d{1,2}').hasMatch(line)) {
        // 前のブロックを保存
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock.join('\n'));
        }
        // 新しいブロック開始
        currentBlock = [line];
      } else {
        currentBlock.add(line);
      }
    }
    
    // 最後のブロックを追加
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock.join('\n'));
    }
    
    debugPrint('抽出した試合ブロック数: ${blocks.length}');
    for (int i = 0; i < blocks.length; i++) {
      debugPrint('ブロック ${i + 1}:\n${blocks[i]}\n---');
    }
    
    return blocks;
  }

  static ParsedMatchData? _parseMatchBlock(String block, String userEfootballUsername) {
    List<String> lines = block.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    if (lines.length < 3) return null; // 最低3行必要（日時、スコア、ユーザー名）
    
    DateTime? matchDate;
    int? score1, score2;
    String leftTeam = '', rightTeam = '';
    String leftUser = '', rightUser = '';
    
    for (String line in lines) {
      // 日時の抽出
      if (matchDate == null) {
        matchDate = _parseEFootballDateTime(line);
      }
      
      // スコアの抽出（例: "BOB 3 - 1 FC バルセロナ" または "3 - 1"）
      RegExp scorePattern = RegExp(r'(\d+)\s*[-–]\s*(\d+)');
      Match? scoreMatch = scorePattern.firstMatch(line);
      if (scoreMatch != null && score1 == null) {
        score1 = int.tryParse(scoreMatch.group(1)!);
        score2 = int.tryParse(scoreMatch.group(2)!);
        
        // スコア行からチーム名も抽出を試行
        String beforeScore = line.substring(0, scoreMatch.start).trim();
        String afterScore = line.substring(scoreMatch.end).trim();
        
        if (beforeScore.isNotEmpty && _isValidTeamName(beforeScore)) {
          leftTeam = beforeScore;
        }
        if (afterScore.isNotEmpty && _isValidTeamName(afterScore)) {
          rightTeam = afterScore;
        }
        
        debugPrint('スコア発見: $leftTeam $score1 - $score2 $rightTeam');
      }
      
      // ユーザー名の抽出（英数字、アンダースコア、ハイフンを含む）
      List<String> potentialUsers = _extractEFootballUsernames(line);
      for (String user in potentialUsers) {
        if (user == userEfootballUsername) {
          if (leftUser.isEmpty) {
            leftUser = user;
          } else if (rightUser.isEmpty) {
            rightUser = user;
          }
        } else {
          if (leftUser.isEmpty) {
            leftUser = user;
          } else if (rightUser.isEmpty && user != leftUser) {
            rightUser = user;
          }
        }
      }
      
      // チーム名の抽出（日本語チーム名に対応）
      if (_isValidTeamName(line) && !line.contains(RegExp(r'\d+\s*[-–]\s*\d+'))) {
        if (leftTeam.isEmpty) {
          leftTeam = line;
        } else if (rightTeam.isEmpty && line != leftTeam) {
          rightTeam = line;
        }
      }
    }
    
    // 抽出したデータの検証
    if (score1 == null || score2 == null || leftUser.isEmpty || rightUser.isEmpty) {
      debugPrint('必要データが不足: score1=$score1, score2=$score2, leftUser=$leftUser, rightUser=$rightUser');
      return null;
    }
    
    // デフォルト値設定
    leftTeam = leftTeam.isEmpty ? 'Team A' : leftTeam;
    rightTeam = rightTeam.isEmpty ? 'Team B' : rightTeam;
    matchDate ??= DateTime.now();
    
    // ユーザーがどちら側かを判定
    bool userIsLeftSide = leftUser == userEfootballUsername;
    
    return ParsedMatchData(
      myTeamName: userIsLeftSide ? leftTeam : rightTeam,
      opponentTeamName: userIsLeftSide ? rightTeam : leftTeam,
      myUsername: userIsLeftSide ? leftUser : rightUser,
      opponentUsername: userIsLeftSide ? rightUser : leftUser,
      myScore: userIsLeftSide ? score1 : score2,
      opponentScore: userIsLeftSide ? score2 : score1,
      matchDate: matchDate,
    );
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
  
  // eFootball特化のヘルパーメソッド
  static DateTime? _parseEFootballDateTime(String text) {
    // eFootball特有の日時フォーマット: 2025/09/13 18:19
    RegExp pattern = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{1,2})');
    Match? match = pattern.firstMatch(text);
    
    if (match != null) {
      try {
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        
        DateTime result = DateTime(year, month, day, hour, minute);
        debugPrint('日時解析成功: $text -> $result');
        return result;
      } catch (e) {
        debugPrint('日時解析エラー: $e');
      }
    }
    
    return null;
  }

  static List<String> _extractEFootballUsernames(String text) {
    List<String> usernames = [];
    
    // eFootballのユーザー名パターン（英数字、アンダースコア、ハイフン）
    RegExp pattern = RegExp(r'\b[A-Za-z0-9_\-]{3,20}\b');
    Iterable<Match> matches = pattern.allMatches(text);
    
    for (Match match in matches) {
      String username = match.group(0)!;
      
      // eFootball特有の除外パターン
      if (!_isEFootballSystemText(username)) {
        usernames.add(username);
        debugPrint('ユーザー名候補: $username');
      }
    }
    
    return usernames;
  }

  static bool _isEFootballSystemText(String text) {
    // eFootballのシステムテキスト・UIテキストを除外
    List<String> systemTexts = [
      'BOB', 'FIFA', 'PES', 'eFootball', 'KONAMI',
      'Division', 'Rank', 'GP', 'WIN', 'LOSE', 'DRAW',
      'vs', 'match', 'game', 'play', 'player',
      '2025', '2024', '2023', // 年数
    ];
    
    String upper = text.toUpperCase();
    for (String systemText in systemTexts) {
      if (upper.contains(systemText.toUpperCase())) {
        return true;
      }
    }
    
    // 数字のみは除外
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return true;
    }
    
    return false;
  }

  static bool _isValidTeamName(String text) {
    // チーム名として有効かチェック
    text = text.trim();
    
    // 長さチェック
    if (text.length < 2 || text.length > 50) return false;
    
    // 数字のみは除外
    if (RegExp(r'^\d+$').hasMatch(text)) return false;
    
    // スコアパターンは除外
    if (RegExp(r'\d+\s*[-–]\s*\d+').hasMatch(text)) return false;
    
    // 日時パターンは除外
    if (RegExp(r'\d{4}/\d{1,2}/\d{1,2}').hasMatch(text)) return false;
    
    // eFootballシステムテキストは除外
    if (_isEFootballSystemText(text)) return false;
    
    // 一般的なチーム名パターン（日本語含む）
    if (RegExp(r'^[A-Za-z0-9\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF\u3400-\u4DBF]+$').hasMatch(text)) {
      debugPrint('有効なチーム名: $text');
      return true;
    }
    
    return false;
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
    
    // eFootball特化のユーザー名パターンを使用
    List<String> allUsernames = _extractEFootballUsernames(ocrText);
    
    // より詳細なフィルタリング
    for (String username in allUsernames) {
      if (_isValidEFootballUsername(username)) {
        usernames.add(username);
      }
    }
    
    // 重複を除去してソート
    List<String> uniqueUsernames = usernames.toSet().toList();
    uniqueUsernames.sort();
    
    debugPrint('抽出されたユーザー名: $uniqueUsernames');
    return uniqueUsernames;
  }

  static bool _isValidEFootballUsername(String username) {
    // 長さチェック
    if (username.length < 3 || username.length > 20) return false;
    
    // 数字のみは除外
    if (RegExp(r'^\d+$').hasMatch(username)) return false;
    
    // eFootball特有の除外パターン
    if (_isEFootballSystemText(username)) return false;
    
    // 既知のeFootballユーザー名パターンをチェック
    List<String> knownUsernames = ['hisa_racer', 'visca-tzuyu', 'eftarigato', '0623SN'];
    if (knownUsernames.contains(username)) return true;
    
    // 一般的なユーザー名パターン（英数字、アンダースコア、ハイフン）
    if (RegExp(r'^[A-Za-z0-9_\-]{3,20}$').hasMatch(username)) return true;
    
    return false;
  }
}
