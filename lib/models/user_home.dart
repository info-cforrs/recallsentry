class UserHome {
  final int id;
  final int userId;
  final String name;
  final int roomCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserHome({
    required this.id,
    required this.userId,
    required this.name,
    required this.roomCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserHome.fromJson(Map<String, dynamic> json) {
    return UserHome(
      id: json['id'],
      userId: json['user'],
      name: json['name'],
      roomCount: json['room_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'name': name,
      'room_count': roomCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating a new home (POST request)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
    };
  }

  // For updating a home (PUT/PATCH request)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
    };
  }
}
