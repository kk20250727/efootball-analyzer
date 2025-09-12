import 'package:flutter/foundation.dart';
import '../models/match_result.dart';

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
    
    // テキストを行に分割
    List<String> lines = ocrText.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      // スコアパターンを検索（例: "2 - 1", "3-0", "1:2"）
      RegExp scorePattern = RegExp(r'(\d+)\s*[-:]\s*(\d+)');
      Match? scoreMatch = scorePattern.firstMatch(line);
      
      if (scoreMatch != null) {
        try {
          int myScore = int.parse(scoreMatch.group(1)!);
          int opponentScore = int.parse(scoreMatch.group(2)!);
          
          // 前後の行からチーム名とユーザー名を取得
          String? myTeamName;
          String? opponentTeamName;
          String? myUsername;
          String? opponentUsername;
          DateTime? matchDate;
          
          // 前後の行を確認してチーム名とユーザー名を取得
          for (int j = (i - 5 < 0 ? 0 : i - 5); j < (lines.length < i + 5 ? lines.length : i + 5); j++) {
            String checkLine = lines[j].trim();
            
            // 日付パターンを検索
            if (matchDate == null) {
              RegExp datePattern = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s+(\d{1,2}):(\d{1,2})');
              Match? dateMatch = datePattern.firstMatch(checkLine);
              if (dateMatch != null) {
                int year = int.parse(dateMatch.group(1)!);
                int month = int.parse(dateMatch.group(2)!);
                int day = int.parse(dateMatch.group(3)!);
                int hour = int.parse(dateMatch.group(4)!);
                int minute = int.parse(dateMatch.group(5)!);
                matchDate = DateTime(year, month, day, hour, minute);
              }
            }
            
            // チーム名とユーザー名のパターンを検索
            // これは実際のeFootballの画面レイアウトに基づいて調整が必要
            if (checkLine.contains(userEfootballUsername)) {
              myUsername = userEfootballUsername;
              // ユーザー名の前後からチーム名を取得
              if (j > 0) {
                myTeamName = lines[j - 1].trim();
              }
            } else if (checkLine.length > 3 && 
                      !checkLine.contains(RegExp(r'\d')) && 
                      !checkLine.contains('vs') &&
                      !checkLine.contains('対戦') &&
                      myTeamName == null) {
              // ユーザー名ではない可能性が高いテキストをチーム名として候補に
              if (checkLine.length < 20) { // 長すぎるテキストは除外
                myTeamName = checkLine;
              }
            }
          }
          
          // デフォルト値で埋める
          myTeamName ??= 'Unknown Team';
          opponentTeamName ??= 'Opponent Team';
          myUsername ??= userEfootballUsername;
          opponentUsername ??= 'Opponent';
          matchDate ??= DateTime.now();
          
          matches.add(ParsedMatchData(
            myTeamName: myTeamName,
            opponentTeamName: opponentTeamName,
            myUsername: myUsername,
            opponentUsername: opponentUsername,
            myScore: myScore,
            opponentScore: opponentScore,
            matchDate: matchDate,
          ));
          
        } catch (e) {
          debugPrint('スコア解析エラー: $e');
          continue;
        }
      }
    }
    
    return matches;
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
