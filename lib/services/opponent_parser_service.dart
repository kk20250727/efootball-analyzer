class ParsedOpponentData {
  final String username;
  final int highestDivision;
  final int highestRank;

  ParsedOpponentData({
    required this.username,
    required this.highestDivision,
    required this.highestRank,
  });
}

class OpponentParserService {
  static List<ParsedOpponentData> parseOpponentData(String ocrText) {
    List<ParsedOpponentData> opponents = [];
    
    // テキストを行に分割
    List<String> lines = ocrText.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      // ユーザー名のパターンを検索（ゲームプラン確認の上に表示される）
      if (line.contains('ゲームプラン確認') || line.contains('Game Plan')) {
        // 前の行からユーザー名を取得
        if (i > 0) {
          String username = lines[i - 1].trim();
          
          // 後続の行からDivisionと順位を検索
          int? division;
          int? rank;
          
          for (int j = i; j < (lines.length < i + 10 ? lines.length : i + 10); j++) {
            String checkLine = lines[j].trim();
            
            // Divisionパターンを検索
            if (division == null) {
              RegExp divisionPattern = RegExp(r'Division\s*(\d+)', caseSensitive: false);
              Match? divisionMatch = divisionPattern.firstMatch(checkLine);
              if (divisionMatch != null) {
                division = int.parse(divisionMatch.group(1)!);
              }
            }
            
            // 順位パターンを検索
            if (rank == null) {
              RegExp rankPattern = RegExp(r'順位[：:]\s*(\d+)位', caseSensitive: false);
              Match? rankMatch = rankPattern.firstMatch(checkLine);
              if (rankMatch != null) {
                rank = int.parse(rankMatch.group(1)!);
              }
            }
          }
          
          if (username.isNotEmpty && division != null && rank != null) {
            opponents.add(ParsedOpponentData(
              username: username,
              highestDivision: division,
              highestRank: rank,
            ));
          }
        }
      }
    }
    
    return opponents;
  }

  static List<String> extractUsernames(String ocrText) {
    List<String> usernames = [];
    
    // ユーザー名のパターンを検索
    RegExp usernamePattern = RegExp(r'[A-Za-z0-9_\-\.]{3,20}');
    Iterable<Match> matches = usernamePattern.allMatches(ocrText);
    
    for (Match match in matches) {
      String username = match.group(0)!;
      // 明らかにユーザー名ではない文字列を除外
      if (!username.contains(RegExp(r'^\d+$')) &&
          !username.contains('vs') &&
          !username.contains('対戦') &&
          !username.contains('年') &&
          !username.contains('月') &&
          !username.contains('日') &&
          !username.contains('Division') &&
          !username.contains('順位')) {
        usernames.add(username);
      }
    }
    
    // 重複を除去
    return usernames.toSet().toList();
  }
}
