class Squad {
  final String id;
  final String userId;
  final String name;
  final String formation;
  final String memo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Squad({
    required this.id,
    required this.userId,
    required this.name,
    required this.formation,
    required this.memo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'formation': formation,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Squad.fromMap(Map<String, dynamic> map) {
    return Squad(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      formation: map['formation'] ?? '',
      memo: map['memo'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Squad copyWith({
    String? id,
    String? userId,
    String? name,
    String? formation,
    String? memo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Squad(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      formation: formation ?? this.formation,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

