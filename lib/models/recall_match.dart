// RecallMatch Model
//
// Represents an automated match between a user's item and a recall.
// Created by the daily matching job or immediate re-matching.

import 'user_item.dart';
import 'recall_data.dart';

/// Match confidence levels
enum MatchConfidence {
  high,        // 90-100%
  mediumHigh,  // 75-89%
  medium,      // 70-74%
  low,         // 60-69%
}

/// Match status
enum MatchStatus {
  pendingReview,  // Awaiting user action
  confirmed,      // User confirmed and enrolled in RMC
  dismissed,      // User dismissed as false positive
  expired,        // Match expired (>30 days)
  invalidated,    // User edited item, match no longer valid
}

/// Lightweight RecallMatch for list views
class RecallMatchSummary {
  final int id;
  final UserItem userItem;  // Full nested UserItem object from backend
  final RecallData recall;  // Full nested Recall object from backend
  final double matchScore;
  final MatchConfidence matchConfidence;
  final String matchReason;
  final MatchStatus status;
  final DateTime matchedAt;
  final DateTime expiresAt;
  final bool isExpired;
  final int daysUntilExpiry;

  RecallMatchSummary({
    required this.id,
    required this.userItem,
    required this.recall,
    required this.matchScore,
    required this.matchConfidence,
    required this.matchReason,
    required this.status,
    required this.matchedAt,
    required this.expiresAt,
    required this.isExpired,
    required this.daysUntilExpiry,
  });

  factory RecallMatchSummary.fromJson(Map<String, dynamic> json) {
    // Safely parse nested objects with null checks
    final userItemData = json['user_item'];
    final recallData = json['recall'];

    // Skip this match if either user_item or recall is null
    if (userItemData == null || recallData == null) {
      throw FormatException('Missing user_item or recall data in match ${json['id']}');
    }

    return RecallMatchSummary(
      id: json['id'] as int? ?? 0,
      userItem: UserItem.fromJson(userItemData as Map<String, dynamic>),
      recall: RecallData.fromJson(recallData as Map<String, dynamic>),
      matchScore: double.tryParse(json['match_score']?.toString() ?? '0') ?? 0.0,
      matchConfidence: _parseConfidence(json['match_confidence'] as String?),
      matchReason: json['match_reason'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(Duration(days: 30)),
      isExpired: json['is_expired'] as bool? ?? false,
      daysUntilExpiry: json['days_until_expiry'] as int? ?? 0,
    );
  }

  /// Get color for match score display
  String getScoreColor() {
    if (matchScore >= 90) return '#28a745'; // Green
    if (matchScore >= 75) return '#FFA500'; // Orange
    return '#dc3545'; // Red
  }

  /// Get display text for confidence level
  String getConfidenceText() {
    switch (matchConfidence) {
      case MatchConfidence.high:
        return 'High Confidence';
      case MatchConfidence.mediumHigh:
        return 'Medium-High';
      case MatchConfidence.medium:
        return 'Medium';
      case MatchConfidence.low:
        return 'Low';
    }
  }

  /// Get display text for status
  String getStatusText() {
    switch (status) {
      case MatchStatus.pendingReview:
        return 'Pending Review';
      case MatchStatus.confirmed:
        return 'Confirmed';
      case MatchStatus.dismissed:
        return 'Dismissed';
      case MatchStatus.expired:
        return 'Expired';
      case MatchStatus.invalidated:
        return 'Invalidated';
    }
  }

  static MatchConfidence _parseConfidence(String? value) {
    switch (value?.toUpperCase()) {
      case 'HIGH':
        return MatchConfidence.high;
      case 'MEDIUM-HIGH':
        return MatchConfidence.mediumHigh;
      case 'MEDIUM':
        return MatchConfidence.medium;
      case 'LOW':
        return MatchConfidence.low;
      default:
        return MatchConfidence.medium;
    }
  }

  static MatchStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending_review':
        return MatchStatus.pendingReview;
      case 'confirmed':
        return MatchStatus.confirmed;
      case 'dismissed':
        return MatchStatus.dismissed;
      case 'expired':
        return MatchStatus.expired;
      case 'invalidated':
        return MatchStatus.invalidated;
      default:
        return MatchStatus.pendingReview;
    }
  }
}

/// Full RecallMatch detail
class RecallMatch {
  final int id;
  final UserItem userItem;
  final RecallData recall;
  final double matchScore;
  final MatchConfidence matchConfidence;
  final Map<String, double> matchedFields;
  final String matchReason;
  final MatchStatus status;
  final DateTime matchedAt;
  final DateTime? reviewedAt;
  final DateTime? notifiedAt;
  final DateTime expiresAt;
  final DateTime? invalidatedAt;
  final int? timeToReviewSeconds;
  final String? dismissedReason;
  final String? invalidationReason;
  final bool isExpired;
  final int daysUntilExpiry;
  final bool canConfirm;
  final bool canDismiss;

  RecallMatch({
    required this.id,
    required this.userItem,
    required this.recall,
    required this.matchScore,
    required this.matchConfidence,
    required this.matchedFields,
    required this.matchReason,
    required this.status,
    required this.matchedAt,
    this.reviewedAt,
    this.notifiedAt,
    required this.expiresAt,
    this.invalidatedAt,
    this.timeToReviewSeconds,
    this.dismissedReason,
    this.invalidationReason,
    required this.isExpired,
    required this.daysUntilExpiry,
    required this.canConfirm,
    required this.canDismiss,
  });

  factory RecallMatch.fromJson(Map<String, dynamic> json) {
    // Create fallback user_item if null (should never happen in practice)
    final userItemData = json['user_item'] as Map<String, dynamic>? ?? {
      'id': 0,
      'manufacturer': '',
      'brand_name': '',
      'product_name': 'Unknown Item',
      'model_number': '',
      'upc': '',
      'sku': '',
      'batch_lot_code': '',
      'serial_number': '',
      'home_id': 0,
      'home_name': '',
      'room_id': 0,
      'room_name': '',
      'photo_urls': [],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Create fallback recall if null (should never happen in practice)
    final recallData = json['recall'] as Map<String, dynamic>? ?? {
      'id': '',
      'product_name': 'Unknown Recall',
      'brand_name': '',
      'agency': '',
      'date_issued': DateTime.now().toIso8601String(),
      'recall_type': '',
      'classification': '',
      'reason': '',
      'description': '',
      'instructions': '',
      'image_url': '',
      'created_at': DateTime.now().toIso8601String(),
    };

    return RecallMatch(
      id: json['id'] as int? ?? 0,
      userItem: UserItem.fromJson(userItemData),
      recall: RecallData.fromJson(recallData),
      matchScore: double.tryParse(json['match_score']?.toString() ?? '0') ?? 0.0,
      matchConfidence: _parseConfidence(json['match_confidence'] as String?),
      matchedFields: _parseMatchedFields(json['matched_fields'] as Map<String, dynamic>?),
      matchReason: json['match_reason'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      matchedAt: json['matched_at'] != null
          ? DateTime.parse(json['matched_at'] as String)
          : DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(Duration(days: 30)),
      invalidatedAt: json['invalidated_at'] != null
          ? DateTime.parse(json['invalidated_at'] as String)
          : null,
      timeToReviewSeconds: json['time_to_review_seconds'] as int?,
      dismissedReason: json['dismissed_reason'] as String?,
      invalidationReason: json['invalidation_reason'] as String?,
      isExpired: json['is_expired'] as bool? ?? false,
      daysUntilExpiry: json['days_until_expiry'] as int? ?? 0,
      canConfirm: json['can_confirm'] as bool? ?? false,
      canDismiss: json['can_dismiss'] as bool? ?? false,
    );
  }

  static Map<String, double> _parseMatchedFields(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  static MatchConfidence _parseConfidence(String? value) {
    switch (value?.toUpperCase()) {
      case 'HIGH':
        return MatchConfidence.high;
      case 'MEDIUM-HIGH':
        return MatchConfidence.mediumHigh;
      case 'MEDIUM':
        return MatchConfidence.medium;
      case 'LOW':
        return MatchConfidence.low;
      default:
        return MatchConfidence.medium;
    }
  }

  static MatchStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending_review':
        return MatchStatus.pendingReview;
      case 'confirmed':
        return MatchStatus.confirmed;
      case 'dismissed':
        return MatchStatus.dismissed;
      case 'expired':
        return MatchStatus.expired;
      case 'invalidated':
        return MatchStatus.invalidated;
      default:
        return MatchStatus.pendingReview;
    }
  }
}

/// Request model for confirming a match
class ConfirmMatchRequest {
  final String? lotNumber;
  final DateTime? purchaseDate;
  final String? purchaseLocation;

  ConfirmMatchRequest({
    this.lotNumber,
    this.purchaseDate,
    this.purchaseLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      if (lotNumber != null && lotNumber!.isNotEmpty)
        'lot_number': lotNumber,
      if (purchaseDate != null)
        'purchase_date': purchaseDate!.toIso8601String().split('T')[0], // YYYY-MM-DD
      if (purchaseLocation != null && purchaseLocation!.isNotEmpty)
        'purchase_location': purchaseLocation,
    };
  }
}

/// Response model for confirming a match
class ConfirmMatchResponse {
  final bool success;
  final String message;
  final int matchId;
  final int rmcId;
  final String rmcStatus;
  final String matchStatus;
  final int timeToReviewSeconds;

  ConfirmMatchResponse({
    required this.success,
    required this.message,
    required this.matchId,
    required this.rmcId,
    required this.rmcStatus,
    required this.matchStatus,
    required this.timeToReviewSeconds,
  });

  factory ConfirmMatchResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmMatchResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      matchId: json['match_id'] as int? ?? 0,
      rmcId: json['rmc_id'] as int? ?? 0,
      rmcStatus: json['rmc_status'] as String? ?? '',
      matchStatus: json['match_status'] as String? ?? '',
      timeToReviewSeconds: json['time_to_review_seconds'] as int? ?? 0,
    );
  }
}

/// Request model for dismissing a match
class DismissMatchRequest {
  final String reason;
  final String? reasonCode;

  DismissMatchRequest({
    required this.reason,
    this.reasonCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      if (reasonCode != null) 'reason_code': reasonCode,
    };
  }
}

/// Response model for dismissing a match
class DismissMatchResponse {
  final bool success;
  final String message;
  final int matchId;
  final String matchStatus;
  final String dismissedReason;
  final int timeToReviewSeconds;

  DismissMatchResponse({
    required this.success,
    required this.message,
    required this.matchId,
    required this.matchStatus,
    required this.dismissedReason,
    required this.timeToReviewSeconds,
  });

  factory DismissMatchResponse.fromJson(Map<String, dynamic> json) {
    return DismissMatchResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      matchId: json['match_id'] as int? ?? 0,
      matchStatus: json['match_status'] as String? ?? '',
      dismissedReason: json['dismissed_reason'] as String? ?? '',
      timeToReviewSeconds: json['time_to_review_seconds'] as int? ?? 0,
    );
  }
}

/// Request model for revalidating a match with user-provided identifier fields
class RevalidateMatchRequest {
  final String? upc;
  final String? modelNumber;
  final String? serialNumber;
  final String? batchLotCode;
  final DateTime? itemDate;

  RevalidateMatchRequest({
    this.upc,
    this.modelNumber,
    this.serialNumber,
    this.batchLotCode,
    this.itemDate,
  });

  Map<String, dynamic> toJson() {
    return {
      if (upc != null && upc!.isNotEmpty) 'upc': upc,
      if (modelNumber != null && modelNumber!.isNotEmpty) 'model_number': modelNumber,
      if (serialNumber != null && serialNumber!.isNotEmpty) 'serial_number': serialNumber,
      if (batchLotCode != null && batchLotCode!.isNotEmpty) 'batch_lot_code': batchLotCode,
      if (itemDate != null) 'item_date': itemDate!.toIso8601String().split('T')[0],
    };
  }

  /// Check if any field has been provided
  bool get hasData {
    return (upc != null && upc!.isNotEmpty) ||
           (modelNumber != null && modelNumber!.isNotEmpty) ||
           (serialNumber != null && serialNumber!.isNotEmpty) ||
           (batchLotCode != null && batchLotCode!.isNotEmpty) ||
           itemDate != null;
  }
}

/// Response model for revalidating a match
class RevalidateMatchResponse {
  final bool success;
  final String message;
  final int matchId;
  final double matchScore;
  final double baseScore;
  final double bonusPoints;
  final String matchConfidence;
  final String matchReason;
  final bool disqualified;
  final String? disqualifiedField;
  final String? disqualifiedMessage;
  final Map<String, dynamic> validatedFields;
  final Map<String, bool> recallAvailableFields;

  RevalidateMatchResponse({
    required this.success,
    required this.message,
    required this.matchId,
    required this.matchScore,
    required this.baseScore,
    required this.bonusPoints,
    required this.matchConfidence,
    required this.matchReason,
    required this.disqualified,
    this.disqualifiedField,
    this.disqualifiedMessage,
    required this.validatedFields,
    required this.recallAvailableFields,
  });

  factory RevalidateMatchResponse.fromJson(Map<String, dynamic> json) {
    // Parse recall_available_fields
    final availableFieldsJson = json['recall_available_fields'] as Map<String, dynamic>? ?? {};
    final availableFields = availableFieldsJson.map(
      (key, value) => MapEntry(key, value as bool? ?? false),
    );

    return RevalidateMatchResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      matchId: json['match_id'] as int? ?? 0,
      matchScore: double.tryParse(json['match_score']?.toString() ?? '0') ?? 0.0,
      baseScore: double.tryParse(json['base_score']?.toString() ?? '0') ?? 0.0,
      bonusPoints: double.tryParse(json['bonus_points']?.toString() ?? '0') ?? 0.0,
      matchConfidence: json['match_confidence'] as String? ?? 'MEDIUM',
      matchReason: json['match_reason'] as String? ?? '',
      disqualified: json['disqualified'] as bool? ?? false,
      disqualifiedField: json['disqualified_field'] as String?,
      disqualifiedMessage: json['disqualified_message'] as String?,
      validatedFields: json['validated_fields'] as Map<String, dynamic>? ?? {},
      recallAvailableFields: availableFields,
    );
  }
}

/// Model for fields available in a recall for the confirmation modal
class RecallAvailableFields {
  final bool hasUpc;
  final bool hasModelNumber;
  final bool hasSerialNumber;
  final bool hasBatchLotCode;
  final bool hasDate;

  RecallAvailableFields({
    required this.hasUpc,
    required this.hasModelNumber,
    required this.hasSerialNumber,
    required this.hasBatchLotCode,
    required this.hasDate,
  });

  factory RecallAvailableFields.fromRecallData(dynamic recall) {
    // Handle RecallData object
    return RecallAvailableFields(
      hasUpc: _hasValue(recall.upc),
      hasModelNumber: _hasValue(recall.cpscModel),
      hasSerialNumber: _hasValue(recall.cpscSerialNumber),
      hasBatchLotCode: _hasValue(recall.batchLotCode),
      hasDate: _hasValue(recall.productionDateStart) ||
               _hasValue(recall.productionDateEnd) ||
               _hasValue(recall.bestUsedByDate) ||
               _hasValue(recall.bestUsedByDateEnd) ||
               _hasValue(recall.expDate) ||
               _hasValue(recall.sellByDate),
    );
  }

  factory RecallAvailableFields.fromJson(Map<String, dynamic> json) {
    return RecallAvailableFields(
      hasUpc: json['upc'] as bool? ?? false,
      hasModelNumber: json['model_number'] as bool? ?? false,
      hasSerialNumber: json['serial_number'] as bool? ?? false,
      hasBatchLotCode: json['batch_lot_code'] as bool? ?? false,
      hasDate: json['date'] as bool? ?? false,
    );
  }

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.isNotEmpty;
    if (value is DateTime) return true;
    return true;
  }

  /// Check if any identifier fields are available
  bool get hasAnyFields {
    return hasUpc || hasModelNumber || hasSerialNumber || hasBatchLotCode || hasDate;
  }
}

/// Vehicle info from VIN decode
class VinVehicleInfo {
  final String year;
  final String make;
  final String model;

  VinVehicleInfo({
    required this.year,
    required this.make,
    required this.model,
  });

  factory VinVehicleInfo.fromJson(Map<String, dynamic> json) {
    return VinVehicleInfo(
      year: json['year']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
    );
  }
}

/// Individual recall from VIN lookup
class VinRecall {
  final String nhtsaCampaignNumber;
  final String manufacturer;
  final String component;
  final String summary;
  final String consequence;
  final String remedy;
  final String reportReceivedDate;
  final String modelYear;
  final String make;
  final String model;
  final bool parkOutside;
  final bool parkIt;

  VinRecall({
    required this.nhtsaCampaignNumber,
    required this.manufacturer,
    required this.component,
    required this.summary,
    required this.consequence,
    required this.remedy,
    required this.reportReceivedDate,
    required this.modelYear,
    required this.make,
    required this.model,
    required this.parkOutside,
    required this.parkIt,
  });

  factory VinRecall.fromJson(Map<String, dynamic> json) {
    return VinRecall(
      nhtsaCampaignNumber: json['nhtsa_campaign_number']?.toString() ?? '',
      manufacturer: json['manufacturer']?.toString() ?? '',
      component: json['component']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      consequence: json['consequence']?.toString() ?? '',
      remedy: json['remedy']?.toString() ?? '',
      reportReceivedDate: json['report_received_date']?.toString() ?? '',
      modelYear: json['model_year']?.toString() ?? '',
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      parkOutside: json['park_outside'] == true,
      parkIt: json['park_it'] == true,
    );
  }

  /// Returns true if this is a "Do Not Drive" recall
  bool get isDoNotDrive => parkIt;

  /// Returns true if the vehicle should be parked outside
  bool get shouldParkOutside => parkOutside;
}

/// Result from VIN recall lookup
class VinRecallLookupResult {
  final bool success;
  final String vin;
  final VinVehicleInfo? vehicle;
  final List<VinRecall> recalls;
  final int recallCount;
  final String? error;
  final bool upgradeRequired;
  final String? message;

  VinRecallLookupResult({
    required this.success,
    required this.vin,
    this.vehicle,
    this.recalls = const [],
    this.recallCount = 0,
    this.error,
    this.upgradeRequired = false,
    this.message,
  });

  factory VinRecallLookupResult.fromJson(Map<String, dynamic> json) {
    final recallsList = <VinRecall>[];
    if (json['recalls'] != null && json['recalls'] is List) {
      for (final recall in json['recalls'] as List) {
        if (recall is Map<String, dynamic>) {
          recallsList.add(VinRecall.fromJson(recall));
        }
      }
    }

    VinVehicleInfo? vehicleInfo;
    if (json['vehicle'] != null && json['vehicle'] is Map<String, dynamic>) {
      vehicleInfo = VinVehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>);
    }

    return VinRecallLookupResult(
      success: json['success'] as bool? ?? false,
      vin: json['vin']?.toString() ?? '',
      vehicle: vehicleInfo,
      recalls: recallsList,
      recallCount: json['recall_count'] as int? ?? recallsList.length,
      error: json['error']?.toString(),
      upgradeRequired: json['upgrade_required'] as bool? ?? false,
      message: json['message']?.toString(),
    );
  }

  /// Returns true if any recall is a "Do Not Drive" recall
  bool get hasDoNotDriveRecall => recalls.any((r) => r.isDoNotDrive);

  /// Returns true if any recall recommends parking outside
  bool get hasParkOutsideRecall => recalls.any((r) => r.shouldParkOutside);
}
