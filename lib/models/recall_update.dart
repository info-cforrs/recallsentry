/// Recall Update model
/// Represents an update/change to a recall that users may want to be notified about.
library;

class RecallUpdate {
  final int id;
  final int recallId;
  final String updateType;
  final String fieldChanged;
  final String changeSummary;
  final String significance;
  final DateTime detectedAt;

  RecallUpdate({
    required this.id,
    required this.recallId,
    required this.updateType,
    required this.fieldChanged,
    required this.changeSummary,
    required this.significance,
    required this.detectedAt,
  });

  factory RecallUpdate.fromJson(Map<String, dynamic> json) {
    return RecallUpdate(
      id: json['id'] as int? ?? 0,
      recallId: json['recall_id'] as int? ?? 0,
      updateType: json['update_type']?.toString() ?? '',
      fieldChanged: json['field_changed']?.toString() ?? '',
      changeSummary: json['change_summary']?.toString() ?? '',
      significance: json['significance']?.toString() ?? 'low',
      detectedAt: json['detected_at'] != null
          ? DateTime.parse(json['detected_at'])
          : DateTime.now(),
    );
  }

  /// Returns a user-friendly title for the update type
  String get displayTitle {
    switch (updateType) {
      case 'remedy_available':
        return 'Remedy Available';
      case 'risk_level_changed':
        return 'Risk Level Changed';
      case 'status_changed':
        return 'Status Updated';
      case 'completion_rate_updated':
        return 'Completion Rate Updated';
      case 'affected_products_expanded':
        return 'More Products Affected';
      case 'description_updated':
        return 'Information Updated';
      case 'dates_updated':
        return 'Dates Updated';
      default:
        return 'Updated';
    }
  }

  /// Returns true if this is a high-priority update that should be prominently displayed
  bool get isHighPriority => significance == 'critical' || significance == 'high';
}

/// Recall Update Notification - tracks a specific notification sent to a user
class RecallUpdateNotification {
  final int id;
  final int recallId;
  final String recallName;
  final String? brandName;
  final String? riskLevel;
  final String updateType;
  final String changeSummary;
  final String significance;
  final String notificationReason;
  final String status;
  final DateTime createdAt;

  RecallUpdateNotification({
    required this.id,
    required this.recallId,
    required this.recallName,
    this.brandName,
    this.riskLevel,
    required this.updateType,
    required this.changeSummary,
    required this.significance,
    required this.notificationReason,
    required this.status,
    required this.createdAt,
  });

  factory RecallUpdateNotification.fromJson(Map<String, dynamic> json) {
    return RecallUpdateNotification(
      id: json['id'] as int? ?? 0,
      recallId: json['recall_id'] as int? ?? 0,
      recallName: json['recall_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString(),
      riskLevel: json['risk_level']?.toString(),
      updateType: json['update_type']?.toString() ?? '',
      changeSummary: json['change_summary']?.toString() ?? '',
      significance: json['significance']?.toString() ?? 'low',
      notificationReason: json['notification_reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isUnread => status == 'pending';
  bool get isHighPriority => significance == 'critical' || significance == 'high';

  String get reasonDisplay {
    switch (notificationReason) {
      case 'rmc_enrolled':
        return 'You\'re tracking this recall';
      case 'recallmatch':
        return 'Matched to your item';
      case 'saved_recall':
        return 'In your saved recalls';
      case 'smartfilter':
        return 'Matches your filter';
      default:
        return '';
    }
  }
}

/// User's notification preferences
class NotificationPreferences {
  // Channel preferences
  final bool pushEnabled;
  final bool emailEnabled;
  final bool emailDigestOnly;

  // Update type preferences
  final bool notifyRemedyAvailable;
  final bool notifyRiskLevelChanged;
  final bool notifyStatusChanged;
  final bool notifyCompletionRate;
  final bool notifyAffectedProducts;
  final bool notifyDescriptionUpdated;

  // Scope preferences
  final bool notifyRmcEnrolled;
  final bool notifyRecallmatch;
  final bool notifySavedRecalls;
  final bool notifySmartfilterMatches;

  NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.emailDigestOnly = false,
    this.notifyRemedyAvailable = true,
    this.notifyRiskLevelChanged = true,
    this.notifyStatusChanged = true,
    this.notifyCompletionRate = false,
    this.notifyAffectedProducts = true,
    this.notifyDescriptionUpdated = false,
    this.notifyRmcEnrolled = true,
    this.notifyRecallmatch = true,
    this.notifySavedRecalls = true,
    this.notifySmartfilterMatches = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      emailDigestOnly: json['email_digest_only'] as bool? ?? false,
      notifyRemedyAvailable: json['notify_remedy_available'] as bool? ?? true,
      notifyRiskLevelChanged: json['notify_risk_level_changed'] as bool? ?? true,
      notifyStatusChanged: json['notify_status_changed'] as bool? ?? true,
      notifyCompletionRate: json['notify_completion_rate'] as bool? ?? false,
      notifyAffectedProducts: json['notify_affected_products'] as bool? ?? true,
      notifyDescriptionUpdated: json['notify_description_updated'] as bool? ?? false,
      notifyRmcEnrolled: json['notify_rmc_enrolled'] as bool? ?? true,
      notifyRecallmatch: json['notify_recallmatch'] as bool? ?? true,
      notifySavedRecalls: json['notify_saved_recalls'] as bool? ?? true,
      notifySmartfilterMatches: json['notify_smartfilter_matches'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'email_digest_only': emailDigestOnly,
      'notify_remedy_available': notifyRemedyAvailable,
      'notify_risk_level_changed': notifyRiskLevelChanged,
      'notify_status_changed': notifyStatusChanged,
      'notify_completion_rate': notifyCompletionRate,
      'notify_affected_products': notifyAffectedProducts,
      'notify_description_updated': notifyDescriptionUpdated,
      'notify_rmc_enrolled': notifyRmcEnrolled,
      'notify_recallmatch': notifyRecallmatch,
      'notify_saved_recalls': notifySavedRecalls,
      'notify_smartfilter_matches': notifySmartfilterMatches,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? emailDigestOnly,
    bool? notifyRemedyAvailable,
    bool? notifyRiskLevelChanged,
    bool? notifyStatusChanged,
    bool? notifyCompletionRate,
    bool? notifyAffectedProducts,
    bool? notifyDescriptionUpdated,
    bool? notifyRmcEnrolled,
    bool? notifyRecallmatch,
    bool? notifySavedRecalls,
    bool? notifySmartfilterMatches,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailDigestOnly: emailDigestOnly ?? this.emailDigestOnly,
      notifyRemedyAvailable: notifyRemedyAvailable ?? this.notifyRemedyAvailable,
      notifyRiskLevelChanged: notifyRiskLevelChanged ?? this.notifyRiskLevelChanged,
      notifyStatusChanged: notifyStatusChanged ?? this.notifyStatusChanged,
      notifyCompletionRate: notifyCompletionRate ?? this.notifyCompletionRate,
      notifyAffectedProducts: notifyAffectedProducts ?? this.notifyAffectedProducts,
      notifyDescriptionUpdated: notifyDescriptionUpdated ?? this.notifyDescriptionUpdated,
      notifyRmcEnrolled: notifyRmcEnrolled ?? this.notifyRmcEnrolled,
      notifyRecallmatch: notifyRecallmatch ?? this.notifyRecallmatch,
      notifySavedRecalls: notifySavedRecalls ?? this.notifySavedRecalls,
      notifySmartfilterMatches: notifySmartfilterMatches ?? this.notifySmartfilterMatches,
    );
  }
}

/// Recall with its recent updates
class RecallWithUpdates {
  final int recallId;
  final String recallName;
  final String? brandName;
  final String? riskLevel;
  final String? agency;
  final List<String> trackingReasons;
  final int updateCount;
  final DateTime? latestUpdate;
  final List<RecallUpdate> updates;

  RecallWithUpdates({
    required this.recallId,
    required this.recallName,
    this.brandName,
    this.riskLevel,
    this.agency,
    required this.trackingReasons,
    required this.updateCount,
    this.latestUpdate,
    required this.updates,
  });

  factory RecallWithUpdates.fromJson(Map<String, dynamic> json) {
    return RecallWithUpdates(
      recallId: json['recall_id'] as int? ?? 0,
      recallName: json['recall_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString(),
      riskLevel: json['risk_level']?.toString(),
      agency: json['agency']?.toString(),
      trackingReasons: (json['tracking_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      updateCount: json['update_count'] as int? ?? 0,
      latestUpdate: json['latest_update'] != null
          ? DateTime.parse(json['latest_update'])
          : null,
      updates: (json['updates'] as List<dynamic>?)
              ?.map((e) => RecallUpdate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasRecentUpdates => updateCount > 0;
}
