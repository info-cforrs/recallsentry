/// Status enum for vehicle recall alerts
enum VehicleRecallAlertStatus {
  pending,
  notAffected,
  affected,
  dismissed;

  static VehicleRecallAlertStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return VehicleRecallAlertStatus.pending;
      case 'not_affected':
        return VehicleRecallAlertStatus.notAffected;
      case 'affected':
        return VehicleRecallAlertStatus.affected;
      case 'dismissed':
        return VehicleRecallAlertStatus.dismissed;
      default:
        return VehicleRecallAlertStatus.pending;
    }
  }

  String toApiString() {
    switch (this) {
      case VehicleRecallAlertStatus.pending:
        return 'pending';
      case VehicleRecallAlertStatus.notAffected:
        return 'not_affected';
      case VehicleRecallAlertStatus.affected:
        return 'affected';
      case VehicleRecallAlertStatus.dismissed:
        return 'dismissed';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleRecallAlertStatus.pending:
        return 'Pending Check';
      case VehicleRecallAlertStatus.notAffected:
        return 'Not Affected';
      case VehicleRecallAlertStatus.affected:
        return 'Affected';
      case VehicleRecallAlertStatus.dismissed:
        return 'Dismissed';
    }
  }
}

/// Embedded UserItem data within VehicleRecallAlert
class AlertUserItem {
  final int id;
  final String? vehicleYear;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleVin;
  final String displayName;

  AlertUserItem({
    required this.id,
    this.vehicleYear,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleVin,
    required this.displayName,
  });

  factory AlertUserItem.fromJson(Map<String, dynamic> json) {
    return AlertUserItem(
      id: json['id'] as int,
      vehicleYear: json['vehicle_year'] as String?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleVin: json['vehicle_vin'] as String?,
      displayName: json['display_name'] as String? ?? 'Vehicle',
    );
  }

  /// Get full vehicle name (e.g., "2024 Chevrolet Silverado")
  String get fullVehicleName {
    final parts = <String>[];
    if (vehicleYear != null && vehicleYear!.isNotEmpty) parts.add(vehicleYear!);
    if (vehicleMake != null && vehicleMake!.isNotEmpty) parts.add(vehicleMake!);
    if (vehicleModel != null && vehicleModel!.isNotEmpty) parts.add(vehicleModel!);
    return parts.isNotEmpty ? parts.join(' ') : displayName;
  }
}

/// Vehicle Recall Alert model
/// Tracks potential vehicle recalls based on Year/Make/Model matching
/// before user verification on NHTSA.gov
class VehicleRecallAlert {
  final int id;
  final int userItemId;
  final AlertUserItem? userItem;
  final String campaignNumber;
  final int? recallId;
  final Map<String, dynamic>? recallData;
  final DateTime recallDate;
  final String component;
  final String summary;
  final String manufacturer;
  final VehicleRecallAlertStatus status;
  final DateTime? checkedAt;
  final DateTime? respondedAt;
  final int? rmcEnrollmentId;
  final DateTime? notificationSentAt;
  final DateTime? notificationClickedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleRecallAlert({
    required this.id,
    required this.userItemId,
    this.userItem,
    required this.campaignNumber,
    this.recallId,
    this.recallData,
    required this.recallDate,
    this.component = '',
    this.summary = '',
    this.manufacturer = '',
    required this.status,
    this.checkedAt,
    this.respondedAt,
    this.rmcEnrollmentId,
    this.notificationSentAt,
    this.notificationClickedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleRecallAlert.fromJson(Map<String, dynamic> json) {
    return VehicleRecallAlert(
      id: json['id'] as int,
      userItemId: json['user_item_id'] as int? ?? json['user_item'] as int,
      userItem: json['user_item_data'] != null
          ? AlertUserItem.fromJson(json['user_item_data'] as Map<String, dynamic>)
          : null,
      campaignNumber: json['campaign_number'] as String? ?? '',
      recallId: json['recall'] as int?,
      recallData: json['recall_data'] as Map<String, dynamic>?,
      recallDate: DateTime.parse(json['recall_date'] as String),
      component: json['component'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      status: VehicleRecallAlertStatus.fromString(json['status'] as String?),
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      rmcEnrollmentId: json['rmc_enrollment'] as int?,
      notificationSentAt: json['notification_sent_at'] != null
          ? DateTime.parse(json['notification_sent_at'] as String)
          : null,
      notificationClickedAt: json['notification_clicked_at'] != null
          ? DateTime.parse(json['notification_clicked_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_item': userItemId,
      'campaign_number': campaignNumber,
      'recall': recallId,
      'recall_date': recallDate.toIso8601String().split('T')[0],
      'component': component,
      'summary': summary,
      'manufacturer': manufacturer,
      'status': status.toApiString(),
      'checked_at': checkedAt?.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'rmc_enrollment': rmcEnrollmentId,
      'notification_sent_at': notificationSentAt?.toIso8601String(),
      'notification_clicked_at': notificationClickedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VehicleRecallAlert copyWith({
    int? id,
    int? userItemId,
    AlertUserItem? userItem,
    String? campaignNumber,
    int? recallId,
    Map<String, dynamic>? recallData,
    DateTime? recallDate,
    String? component,
    String? summary,
    String? manufacturer,
    VehicleRecallAlertStatus? status,
    DateTime? checkedAt,
    DateTime? respondedAt,
    int? rmcEnrollmentId,
    DateTime? notificationSentAt,
    DateTime? notificationClickedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VehicleRecallAlert(
      id: id ?? this.id,
      userItemId: userItemId ?? this.userItemId,
      userItem: userItem ?? this.userItem,
      campaignNumber: campaignNumber ?? this.campaignNumber,
      recallId: recallId ?? this.recallId,
      recallData: recallData ?? this.recallData,
      recallDate: recallDate ?? this.recallDate,
      component: component ?? this.component,
      summary: summary ?? this.summary,
      manufacturer: manufacturer ?? this.manufacturer,
      status: status ?? this.status,
      checkedAt: checkedAt ?? this.checkedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rmcEnrollmentId: rmcEnrollmentId ?? this.rmcEnrollmentId,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      notificationClickedAt: notificationClickedAt ?? this.notificationClickedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate NHTSA VIN check URL
  String get nhtsaUrl {
    final vin = userItem?.vehicleVin;
    if (vin != null && vin.isNotEmpty) {
      return 'https://www.nhtsa.gov/recalls?vin=$vin';
    }
    return 'https://www.nhtsa.gov/recalls';
  }

  /// Get vehicle display name from embedded userItem or placeholder
  String get vehicleName {
    return userItem?.fullVehicleName ?? 'Vehicle';
  }

  /// Check if this alert is actionable (pending status)
  bool get isPending => status == VehicleRecallAlertStatus.pending;

  /// Check if user has checked NHTSA.gov
  bool get hasCheckedNhtsa => checkedAt != null;

  /// Get a short summary (first 150 chars)
  String get shortSummary {
    if (summary.length <= 150) return summary;
    return '${summary.substring(0, 147)}...';
  }
}
