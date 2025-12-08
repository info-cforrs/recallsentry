// Room Icon Helper
// Maps room types to their corresponding icon assets
// Organizes rooms into categories for better UX

class RoomType {
  // Living Spaces
  static const String livingRoom = 'living_room';
  static const String diningRoom = 'dining_room';
  static const String bedroom = 'bedroom';
  static const String nursery = 'nursery';
  static const String study = 'study';
  static const String office = 'office';
  static const String playroom = 'playroom';

  // Utility Spaces
  static const String kitchen = 'kitchen';
  static const String bathroom = 'bathroom';
  static const String laundry = 'laundry';
  static const String pantry = 'pantry';
  static const String closet = 'closet';

  // Storage Spaces
  static const String attic = 'attic';
  static const String basement = 'basement';
  static const String garage = 'garage';
  static const String wineCellar = 'wine_cellar';
  static const String workshop = 'workshop';

  // Vehicle & Special
  static const String vehicle = 'vehicle';
  static const String childSeat = 'child_seat';
  static const String tires = 'tires';
}

class RoomCategory {
  final String id;
  final String name;
  final List<RoomTemplate> rooms;

  const RoomCategory({
    required this.id,
    required this.name,
    required this.rooms,
  });
}

class RoomTemplate {
  final String roomType;
  final String defaultName;
  final String iconPath;
  final String? whiteIconPath;
  final bool allowMultiple;

  const RoomTemplate({
    required this.roomType,
    required this.defaultName,
    required this.iconPath,
    this.whiteIconPath,
    this.allowMultiple = false,
  });
}

class RoomIconHelper {
  /// Map of room types to icon paths
  static const Map<String, String> _roomIcons = {
    // Living Spaces
    RoomType.livingRoom: 'assets/images/living_room_icon.png',
    RoomType.diningRoom: 'assets/images/dining_room_icon.png',
    RoomType.bedroom: 'assets/images/bedroom_icon.png',
    RoomType.nursery: 'assets/images/nursery_icon.png',
    RoomType.study: 'assets/images/study_icon.png',
    RoomType.office: 'assets/images/office_icon.png',
    RoomType.playroom: 'assets/images/playroom_icon.png',

    // Utility Spaces
    RoomType.kitchen: 'assets/images/kitchen_icon.png',
    RoomType.bathroom: 'assets/images/bathroom_icon.png',
    RoomType.laundry: 'assets/images/laundry_icon.png',
    RoomType.pantry: 'assets/images/pantry_icon.png',
    RoomType.closet: 'assets/images/closet_icon.png',

    // Storage Spaces
    RoomType.attic: 'assets/images/attic_icon.png',
    RoomType.basement: 'assets/images/basement_icon.png',
    RoomType.garage: 'assets/images/garage_white_icon.png',
    RoomType.wineCellar: 'assets/images/wine_cellar_icon.png',
    RoomType.workshop: 'assets/images/workshop_icon.png',

    // Vehicle & Special
    RoomType.vehicle: 'assets/images/vehicle_icon.png',
    RoomType.childSeat: 'assets/images/child_seat_icon.png',
    RoomType.tires: 'assets/images/tires_icon.png',
  };

  /// Map of room types to white icon paths (for dark backgrounds)
  static const Map<String, String> _whiteRoomIcons = {
    RoomType.bedroom: 'assets/images/bedroom_white_icon.png',
    RoomType.bathroom: 'assets/images/bathroom_white_icon.png',
    RoomType.closet: 'assets/images/closet_white_icon.png',
    RoomType.garage: 'assets/images/garage_white_icon.png',
  };

  /// Get icon path for a room type
  static String getIconPath(String roomType) {
    return _roomIcons[roomType] ?? 'assets/images/Home_icon.png';
  }

  /// Get white icon path for a room type (returns null if not available)
  static String? getWhiteIconPath(String roomType) {
    return _whiteRoomIcons[roomType];
  }

  /// Check if a room type has a white variant icon
  static bool hasWhiteIcon(String roomType) {
    return _whiteRoomIcons.containsKey(roomType);
  }

  /// Room categories with templates for creating rooms
  static final List<RoomCategory> roomCategories = [
    RoomCategory(
      id: 'living_spaces',
      name: 'Living Spaces',
      rooms: [
        RoomTemplate(
          roomType: RoomType.livingRoom,
          defaultName: 'Living Room',
          iconPath: _roomIcons[RoomType.livingRoom]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.diningRoom,
          defaultName: 'Dining Room',
          iconPath: _roomIcons[RoomType.diningRoom]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.bedroom,
          defaultName: 'Bedroom',
          iconPath: _roomIcons[RoomType.bedroom]!,
          whiteIconPath: _whiteRoomIcons[RoomType.bedroom],
          allowMultiple: true, // Master Bedroom, Guest Bedroom, etc.
        ),
        RoomTemplate(
          roomType: RoomType.nursery,
          defaultName: 'Nursery',
          iconPath: _roomIcons[RoomType.nursery]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.study,
          defaultName: 'Study',
          iconPath: _roomIcons[RoomType.study]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.office,
          defaultName: 'Office',
          iconPath: _roomIcons[RoomType.office]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.playroom,
          defaultName: 'Playroom',
          iconPath: _roomIcons[RoomType.playroom]!,
          allowMultiple: false,
        ),
      ],
    ),
    RoomCategory(
      id: 'utility_spaces',
      name: 'Utility Spaces',
      rooms: [
        RoomTemplate(
          roomType: RoomType.kitchen,
          defaultName: 'Kitchen',
          iconPath: _roomIcons[RoomType.kitchen]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.bathroom,
          defaultName: 'Bathroom',
          iconPath: _roomIcons[RoomType.bathroom]!,
          whiteIconPath: _whiteRoomIcons[RoomType.bathroom],
          allowMultiple: true, // Master Bath, Guest Bath, etc.
        ),
        RoomTemplate(
          roomType: RoomType.laundry,
          defaultName: 'Laundry Room',
          iconPath: _roomIcons[RoomType.laundry]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.pantry,
          defaultName: 'Pantry',
          iconPath: _roomIcons[RoomType.pantry]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.closet,
          defaultName: 'Closet',
          iconPath: _roomIcons[RoomType.closet]!,
          whiteIconPath: _whiteRoomIcons[RoomType.closet],
          allowMultiple: true, // Hall Closet, Main Closet, etc.
        ),
      ],
    ),
    RoomCategory(
      id: 'storage_spaces',
      name: 'Storage Spaces',
      rooms: [
        RoomTemplate(
          roomType: RoomType.attic,
          defaultName: 'Attic',
          iconPath: _roomIcons[RoomType.attic]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.basement,
          defaultName: 'Basement',
          iconPath: _roomIcons[RoomType.basement]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.garage,
          defaultName: 'Garage',
          iconPath: _roomIcons[RoomType.garage]!,
          whiteIconPath: _whiteRoomIcons[RoomType.garage],
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.wineCellar,
          defaultName: 'Wine Cellar',
          iconPath: _roomIcons[RoomType.wineCellar]!,
          allowMultiple: false,
        ),
        RoomTemplate(
          roomType: RoomType.workshop,
          defaultName: 'Workshop',
          iconPath: _roomIcons[RoomType.workshop]!,
          allowMultiple: false,
        ),
      ],
    ),
    // NOTE: Vehicle, Child Seat, and Tires are now UserItems (not rooms)
    // stored in Garage. They have been moved to item_category in UserItem model.
    // Icon mappings kept in _roomIcons for backwards compatibility.
  ];

  /// Get all room templates organized by category
  static List<RoomCategory> getRoomCategories() {
    return roomCategories;
  }

  /// Get room template by room type
  static RoomTemplate? getRoomTemplate(String roomType) {
    for (var category in roomCategories) {
      for (var template in category.rooms) {
        if (template.roomType == roomType) {
          return template;
        }
      }
    }
    return null;
  }

  /// Get default name for a room type
  static String getDefaultName(String roomType) {
    final template = getRoomTemplate(roomType);
    return template?.defaultName ?? 'Room';
  }

  /// Check if a room type allows multiple instances
  static bool allowsMultiple(String roomType) {
    final template = getRoomTemplate(roomType);
    return template?.allowMultiple ?? false;
  }

  /// Get suggested names for rooms that allow multiple instances
  static List<String> getSuggestedNames(String roomType) {
    switch (roomType) {
      case RoomType.bedroom:
        return ['Master Bedroom', 'Guest Bedroom', 'Kid\'s Bedroom', 'Bedroom'];
      case RoomType.bathroom:
        return ['Master Bathroom', 'Guest Bathroom', 'Hall Bathroom', 'Bathroom'];
      case RoomType.closet:
        return ['Walk-In Closet', 'Hall Closet', 'Master Closet', 'Linen Closet', 'Coat Closet'];
      case RoomType.vehicle:
        return ['Car', 'Truck', 'SUV', 'Motorcycle', 'Van'];
      case RoomType.childSeat:
        return ['Child Seat', 'Infant Seat', 'Booster Seat'];
      case RoomType.tires:
        return ['Winter Tires', 'Summer Tires', 'Spare Tires'];
      default:
        return [getDefaultName(roomType)];
    }
  }
}
