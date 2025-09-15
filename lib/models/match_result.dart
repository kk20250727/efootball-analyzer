enum MatchResult {
  win,
  loss,
  draw,
}

class MatchData {
  final String id;
  final String userId;
  final String myTeamName;
  final String opponentTeamName;
  final String myUsername;
  final String opponentUsername;
  final int myScore;
  final int opponentScore;
  final MatchResult result;
  final DateTime matchDate;
  final String? squadId;
  final DateTime createdAt;

  MatchData({
    required this.id,
    required this.userId,
    required this.myTeamName,
    required this.opponentTeamName,
    required this.myUsername,
    required this.opponentUsername,
    required this.myScore,
    required this.opponentScore,
    required this.result,
    required this.matchDate,
    this.squadId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'myTeamName': myTeamName,
      'opponentTeamName': opponentTeamName,
      'myUsername': myUsername,
      'opponentUsername': opponentUsername,
      'myScore': myScore,
      'opponentScore': opponentScore,
      'result': result.name,
      'matchDate': matchDate.toIso8601String(),
      'squadId': squadId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MatchData copyWith({
    String? id,
    String? userId,
    String? myTeamName,
    String? opponentTeamName,
    String? myUsername,
    String? opponentUsername,
    int? myScore,
    int? opponentScore,
    MatchResult? result,
    DateTime? matchDate,
    String? squadId,
    DateTime? createdAt,
  }) {
    return MatchData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      myTeamName: myTeamName ?? this.myTeamName,
      opponentTeamName: opponentTeamName ?? this.opponentTeamName,
      myUsername: myUsername ?? this.myUsername,
      opponentUsername: opponentUsername ?? this.opponentUsername,
      myScore: myScore ?? this.myScore,
      opponentScore: opponentScore ?? this.opponentScore,
      result: result ?? this.result,
      matchDate: matchDate ?? this.matchDate,
      squadId: squadId ?? this.squadId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MatchData.fromMap(Map<String, dynamic> map) {
    return MatchData(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      myTeamName: map['myTeamName'] ?? '',
      opponentTeamName: map['opponentTeamName'] ?? '',
      myUsername: map['myUsername'] ?? '',
      opponentUsername: map['opponentUsername'] ?? '',
      myScore: map['myScore'] ?? 0,
      opponentScore: map['opponentScore'] ?? 0,
      result: MatchResult.values.firstWhere(
        (e) => e.name == map['result'],
        orElse: () => MatchResult.draw,
      ),
      matchDate: DateTime.parse(map['matchDate'] ?? DateTime.now().toIso8601String()),
      squadId: map['squadId'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
