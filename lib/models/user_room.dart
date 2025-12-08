class UserRoom {
  final int id;
  final int homeId;
  final String homeName;
  final String name;
  final String roomType;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserRoom({
    required this.id,
    required this.homeId,
    required this.homeName,
    required this.name,
    required this.roomType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRoom.fromJson(Map<String, dynamic> json) {
    return UserRoom(
      id: json['id'],
      homeId: json['home'],
      homeName: json['home_name'] ?? '',
      name: json['name'],
      roomType: json['room_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'home': homeId,
      'home_name': homeName,
      'name': name,
      'room_type': roomType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // For creating a new room (POST request)
  Map<String, dynamic> toCreateJson() {
    return {
      'home': homeId,
      'name': name,
      'room_type': roomType,
    };
  }

  // For updating a room (PUT/PATCH request)
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'room_type': roomType,
    };
  }
}
