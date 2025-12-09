/// User Consent Preferences Model
///
/// Tracks user consent choices for various data processing activities.
///
/// Consent types:
/// - Required: Terms of Use, Privacy Policy (cannot use app without)
/// - Optional: Analytics, Crash Reporting, Gamification, Push Notifications
/// - Sensitive: Health Data (requires explicit consent when accessing feature)
library;

class ConsentPreferences {
  /// Required consent - Terms of Service
  final bool termsOfServiceAccepted;

  /// Required consent - Privacy Policy
  final bool privacyPolicyAccepted;

  /// Optional consent - Usage analytics tracking
  /// Tracks: recalls viewed, filters applied, searches performed
  final bool analyticsEnabled;

  /// Optional consent - Crash reporting via Firebase Crashlytics
  /// Shares: crash data, stack traces, device info with Google/Firebase
  final bool crashReportingEnabled;

  /// Optional consent - Gamification features
  /// Tracks: daily logins, safety scores, badges, streaks
  final bool gamificationEnabled;

  /// Optional consent - Push notifications
  final bool pushNotificationsEnabled;

  /// Sensitive data consent - Health data
  /// Required for allergy preferences feature
  /// This is sensitive data requiring explicit consent
  final bool healthDataConsentGiven;

  /// Timestamp when consent was given/updated
  final DateTime? consentTimestamp;

  /// App version when consent was given
  final String? appVersion;

  ConsentPreferences({
    this.termsOfServiceAccepted = false,
    this.privacyPolicyAccepted = false,
    this.analyticsEnabled = false,
    this.crashReportingEnabled = false,
    this.gamificationEnabled = false,
    this.pushNotificationsEnabled = false,
    this.healthDataConsentGiven = false,
    this.consentTimestamp,
    this.appVersion,
  });

  /// Check if all required consents are given
  bool get hasRequiredConsent =>
      termsOfServiceAccepted && privacyPolicyAccepted;

  /// Check if any optional consent is given
  bool get hasAnyOptionalConsent =>
      analyticsEnabled ||
      crashReportingEnabled ||
      gamificationEnabled ||
      pushNotificationsEnabled ||
      healthDataConsentGiven;

  /// Create default preferences for new users (opt-out model)
  /// Optional consents are enabled by default; users can disable in settings
  /// Health data consent remains false - requires explicit opt-in
  factory ConsentPreferences.defaults() {
    return ConsentPreferences(
      termsOfServiceAccepted: true,
      privacyPolicyAccepted: true,
      analyticsEnabled: true,
      crashReportingEnabled: true,
      gamificationEnabled: true,
      pushNotificationsEnabled: true,
      healthDataConsentGiven: false,
      consentTimestamp: DateTime.now(),
    );
  }

  /// Create preferences with all optional consents enabled
  factory ConsentPreferences.allEnabled() {
    return ConsentPreferences(
      termsOfServiceAccepted: true,
      privacyPolicyAccepted: true,
      analyticsEnabled: true,
      crashReportingEnabled: true,
      gamificationEnabled: true,
      pushNotificationsEnabled: true,
      healthDataConsentGiven: true,
      consentTimestamp: DateTime.now(),
    );
  }

  factory ConsentPreferences.fromJson(Map<String, dynamic> json) {
    return ConsentPreferences(
      termsOfServiceAccepted: json['terms_of_service_accepted'] ?? false,
      privacyPolicyAccepted: json['privacy_policy_accepted'] ?? false,
      analyticsEnabled: json['analytics_enabled'] ?? false,
      crashReportingEnabled: json['crash_reporting_enabled'] ?? false,
      gamificationEnabled: json['gamification_enabled'] ?? false,
      pushNotificationsEnabled: json['push_notifications_enabled'] ?? false,
      healthDataConsentGiven: json['health_data_consent_given'] ?? false,
      consentTimestamp: json['consent_timestamp'] != null
          ? DateTime.parse(json['consent_timestamp'])
          : null,
      appVersion: json['app_version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terms_of_service_accepted': termsOfServiceAccepted,
      'privacy_policy_accepted': privacyPolicyAccepted,
      'analytics_enabled': analyticsEnabled,
      'crash_reporting_enabled': crashReportingEnabled,
      'gamification_enabled': gamificationEnabled,
      'push_notifications_enabled': pushNotificationsEnabled,
      'health_data_consent_given': healthDataConsentGiven,
      'consent_timestamp': consentTimestamp?.toIso8601String(),
      'app_version': appVersion,
    };
  }

  ConsentPreferences copyWith({
    bool? termsOfServiceAccepted,
    bool? privacyPolicyAccepted,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? gamificationEnabled,
    bool? pushNotificationsEnabled,
    bool? healthDataConsentGiven,
    DateTime? consentTimestamp,
    String? appVersion,
  }) {
    return ConsentPreferences(
      termsOfServiceAccepted:
          termsOfServiceAccepted ?? this.termsOfServiceAccepted,
      privacyPolicyAccepted:
          privacyPolicyAccepted ?? this.privacyPolicyAccepted,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportingEnabled:
          crashReportingEnabled ?? this.crashReportingEnabled,
      gamificationEnabled: gamificationEnabled ?? this.gamificationEnabled,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      healthDataConsentGiven:
          healthDataConsentGiven ?? this.healthDataConsentGiven,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  String toString() {
    return 'ConsentPreferences('
        'terms: $termsOfServiceAccepted, '
        'privacy: $privacyPolicyAccepted, '
        'analytics: $analyticsEnabled, '
        'crash: $crashReportingEnabled, '
        'gamification: $gamificationEnabled, '
        'push: $pushNotificationsEnabled, '
        'health: $healthDataConsentGiven)';
  }
}
