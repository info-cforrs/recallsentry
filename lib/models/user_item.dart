/// Item category for special garage items
enum ItemCategory {
  general,
  vehicle,
  tires,
  childSeat;

  static ItemCategory fromString(String? value) {
    switch (value) {
      case 'vehicle':
        return ItemCategory.vehicle;
      case 'tires':
        return ItemCategory.tires;
      case 'child_seat':
        return ItemCategory.childSeat;
      default:
        return ItemCategory.general;
    }
  }

  String toApiString() {
    switch (this) {
      case ItemCategory.vehicle:
        return 'vehicle';
      case ItemCategory.tires:
        return 'tires';
      case ItemCategory.childSeat:
        return 'child_seat';
      case ItemCategory.general:
        return 'general';
    }
  }
}

class UserItem {
  final int id;
  final String manufacturer;
  final String brandName;
  final String productName;
  final String modelNumber;
  final String upc;
  final String sku;
  final String batchLotCode;
  final String serialNumber;
  final String? dateType;
  final DateTime? itemDate;
  final String? retailer;
  final int homeId;
  final String homeName;
  final int roomId;
  final String roomName;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Special item category for garage items (vehicles, tires, child seats)
  final ItemCategory itemCategory;

  // Vehicle-specific fields
  final String? vehicleYear;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleVin;

  // Tire-specific fields
  final String? tireDotCode;
  final String? tireSize;
  final int? tireQty;
  final String? tireProductionWeek;
  final String? tireProductionYear;

  // Child seat-specific fields
  final String? childSeatModelNumber;
  final String? childSeatProductionMonth;
  final String? childSeatProductionYear;

  UserItem({
    required this.id,
    required this.manufacturer,
    required this.brandName,
    required this.productName,
    required this.modelNumber,
    required this.upc,
    required this.sku,
    required this.batchLotCode,
    required this.serialNumber,
    this.dateType,
    this.itemDate,
    this.retailer,
    required this.homeId,
    required this.homeName,
    required this.roomId,
    required this.roomName,
    required this.photoUrls,
    required this.createdAt,
    required this.updatedAt,
    this.itemCategory = ItemCategory.general,
    this.vehicleYear,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleVin,
    this.tireDotCode,
    this.tireSize,
    this.tireQty,
    this.tireProductionWeek,
    this.tireProductionYear,
    this.childSeatModelNumber,
    this.childSeatProductionMonth,
    this.childSeatProductionYear,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] as int,
      manufacturer: json['manufacturer'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      modelNumber: json['model_number'] as String? ?? '',
      upc: json['upc'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      batchLotCode: json['batch_lot_code'] as String? ?? '',
      serialNumber: json['serial_number'] as String? ?? '',
      dateType: json['date_type'] as String?,
      itemDate: json['item_date'] != null
          ? DateTime.parse(json['item_date'] as String)
          : null,
      retailer: json['retailer'] as String?,
      homeId: json['home_id'] as int,
      homeName: json['home_name'] as String? ?? '',
      roomId: json['room_id'] as int,
      roomName: json['room_name'] as String? ?? '',
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // Item category for garage items
      itemCategory: ItemCategory.fromString(json['item_category'] as String?),
      // Vehicle-specific fields
      vehicleYear: json['vehicle_year'] as String?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleVin: json['vehicle_vin'] as String?,
      // Tire-specific fields
      tireDotCode: json['tire_dot_code'] as String?,
      tireSize: json['tire_size'] as String?,
      tireQty: json['tire_qty'] as int?,
      tireProductionWeek: json['tire_production_week'] as String?,
      tireProductionYear: json['tire_production_year'] as String?,
      // Child seat-specific fields
      childSeatModelNumber: json['child_seat_model_number'] as String?,
      childSeatProductionMonth: json['child_seat_production_month'] as String?,
      childSeatProductionYear: json['child_seat_production_year'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manufacturer': manufacturer,
      'brand_name': brandName,
      'product_name': productName,
      'model_number': modelNumber,
      'upc': upc,
      'sku': sku,
      'batch_lot_code': batchLotCode,
      'serial_number': serialNumber,
      'date_type': dateType,
      'item_date': itemDate?.toIso8601String(),
      'retailer': retailer,
      'home_id': homeId,
      'home_name': homeName,
      'room_id': roomId,
      'room_name': roomName,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Item category for garage items
      'item_category': itemCategory.toApiString(),
      // Vehicle-specific fields
      'vehicle_year': vehicleYear,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_vin': vehicleVin,
      // Tire-specific fields
      'tire_dot_code': tireDotCode,
      'tire_size': tireSize,
      'tire_qty': tireQty,
      'tire_production_week': tireProductionWeek,
      'tire_production_year': tireProductionYear,
      // Child seat-specific fields
      'child_seat_model_number': childSeatModelNumber,
      'child_seat_production_month': childSeatProductionMonth,
      'child_seat_production_year': childSeatProductionYear,
    };
  }

  /// Get display name for the item (brand + product name, avoiding duplication)
  String get displayName {
    if (brandName.isNotEmpty && productName.isNotEmpty) {
      // Avoid duplication if product name already starts with brand name
      if (productName.toLowerCase().startsWith(brandName.toLowerCase())) {
        return productName;
      }
      return '$brandName $productName';
    } else if (brandName.isNotEmpty) {
      return brandName;
    } else if (productName.isNotEmpty) {
      return productName;
    } else if (manufacturer.isNotEmpty) {
      return manufacturer;
    } else {
      return 'Unknown Item';
    }
  }

  /// Get location string (home -> room)
  String get location => '$homeName → $roomName';

  /// Get full photo URLs (prepend base URL if needed)
  List<String> get fullPhotoUrls {
    const baseUrl = 'https://api.centerforrecallsafety.com';
    return photoUrls.map((url) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      } else {
        // Remove leading slash if present to avoid double slashes
        final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
        return '$baseUrl/$cleanUrl';
      }
    }).toList();
  }

  // ==================== Vehicle Helper Methods ====================

  /// Check if this item is a vehicle
  bool get isVehicle => itemCategory == ItemCategory.vehicle;

  /// Check if this item is tires
  bool get isTires => itemCategory == ItemCategory.tires;

  /// Check if this item is a child seat
  bool get isChildSeat => itemCategory == ItemCategory.childSeat;

  /// Check if this is a special garage item (vehicle, tires, or child seat)
  bool get isGarageItem =>
      itemCategory == ItemCategory.vehicle ||
      itemCategory == ItemCategory.tires ||
      itemCategory == ItemCategory.childSeat;

  /// Get vehicle display name (Make Model or product name fallback)
  String get vehicleDisplayName {
    if (vehicleMake != null && vehicleModel != null) {
      return '$vehicleMake $vehicleModel';
    } else if (vehicleMake != null) {
      return vehicleMake!;
    } else if (vehicleModel != null) {
      return vehicleModel!;
    }
    // Fallback to regular display name
    return displayName;
  }

  /// Get full vehicle name with year (e.g., "2024 Chevy Silverado")
  String get fullVehicleName {
    final makeModel = vehicleDisplayName;
    if (vehicleYear != null && vehicleYear!.isNotEmpty) {
      return '$vehicleYear $makeModel';
    }
    return makeModel;
  }

  // ==================== Tire Helper Methods ====================

  /// Get tire display name (Manufacturer Model or product name fallback)
  String get tireDisplayName {
    if (manufacturer.isNotEmpty && modelNumber.isNotEmpty) {
      return '$manufacturer $modelNumber';
    } else if (manufacturer.isNotEmpty) {
      return manufacturer;
    } else if (modelNumber.isNotEmpty) {
      return modelNumber;
    }
    // Fallback to regular display name
    return displayName;
  }

  /// Get full tire name with size (e.g., "Michelin Defender - 265/70R17")
  String get fullTireName {
    final name = tireDisplayName;
    if (tireSize != null && tireSize!.isNotEmpty) {
      return '$name - $tireSize';
    }
    return name;
  }

  /// Get tire quantity display (e.g., "Qty: 4" or empty if not set)
  String get tireQtyDisplay {
    if (tireQty != null && tireQty! > 0) {
      return 'Qty: $tireQty';
    }
    return '';
  }

  // ==================== Child Seat Helper Methods ====================

  /// Get child seat display name (Manufacturer Model or product name fallback)
  String get childSeatDisplayName {
    if (manufacturer.isNotEmpty && modelNumber.isNotEmpty) {
      return '$manufacturer $modelNumber';
    } else if (manufacturer.isNotEmpty) {
      return manufacturer;
    } else if (modelNumber.isNotEmpty) {
      return modelNumber;
    }
    // Fallback to regular display name
    return displayName;
  }

  /// Get full child seat name (Manufacturer Model)
  String get fullChildSeatName {
    return childSeatDisplayName;
  }
}
