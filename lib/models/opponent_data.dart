class OpponentData {
  final String id;
  final String userId;
  final String opponentUsername;
  final int highestDivision;
  final int highestRank;
  final DateTime createdAt;

  OpponentData({
    required this.id,
    required this.userId,
    required this.opponentUsername,
    required this.highestDivision,
    required this.highestRank,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'opponentUsername': opponentUsername,
      'highestDivision': highestDivision,
      'highestRank': highestRank,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OpponentData.fromMap(Map<String, dynamic> map) {
    return OpponentData(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      opponentUsername: map['opponentUsername'] ?? '',
      highestDivision: map['highestDivision'] ?? 0,
      highestRank: map['highestRank'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  OpponentData copyWith({
    String? id,
    String? userId,
    String? opponentUsername,
    int? highestDivision,
    int? highestRank,
    DateTime? createdAt,
  }) {
    return OpponentData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      opponentUsername: opponentUsername ?? this.opponentUsername,
      highestDivision: highestDivision ?? this.highestDivision,
      highestRank: highestRank ?? this.highestRank,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
