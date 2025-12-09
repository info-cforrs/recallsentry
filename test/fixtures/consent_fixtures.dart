/// Consent Test Fixtures
///
/// Sample consent preference data for testing.
library;

/// Sample consent data for testing
class ConsentFixtures {
  /// Default consent preferences (opt-out model)
  static Map<String, dynamic> get defaultConsent => {
        'terms_of_service_accepted': true,
        'privacy_policy_accepted': true,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'gamification_enabled': true,
        'push_notifications_enabled': true,
        'health_data_consent_given': false,
        'consent_timestamp': '2024-01-01T00:00:00Z',
        'app_version': '1.0.0',
      };

  /// All consents enabled
  static Map<String, dynamic> get allConsentEnabled => {
        'terms_of_service_accepted': true,
        'privacy_policy_accepted': true,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'gamification_enabled': true,
        'push_notifications_enabled': true,
        'health_data_consent_given': true,
        'consent_timestamp': '2024-01-01T00:00:00Z',
        'app_version': '1.0.0',
      };

  /// Minimal consent (only required)
  static Map<String, dynamic> get minimalConsent => {
        'terms_of_service_accepted': true,
        'privacy_policy_accepted': true,
        'analytics_enabled': false,
        'crash_reporting_enabled': false,
        'gamification_enabled': false,
        'push_notifications_enabled': false,
        'health_data_consent_given': false,
        'consent_timestamp': '2024-01-01T00:00:00Z',
        'app_version': '1.0.0',
      };

  /// No consent given
  static Map<String, dynamic> get noConsent => {
        'terms_of_service_accepted': false,
        'privacy_policy_accepted': false,
        'analytics_enabled': false,
        'crash_reporting_enabled': false,
        'gamification_enabled': false,
        'push_notifications_enabled': false,
        'health_data_consent_given': false,
        'consent_timestamp': null,
        'app_version': null,
      };

  /// Missing required consent (ToS not accepted)
  static Map<String, dynamic> get missingTosConsent => {
        'terms_of_service_accepted': false,
        'privacy_policy_accepted': true,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'gamification_enabled': true,
        'push_notifications_enabled': true,
        'health_data_consent_given': false,
      };

  /// Missing required consent (Privacy Policy not accepted)
  static Map<String, dynamic> get missingPrivacyConsent => {
        'terms_of_service_accepted': true,
        'privacy_policy_accepted': false,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'gamification_enabled': true,
        'push_notifications_enabled': true,
        'health_data_consent_given': false,
      };

  /// Health data consent enabled (for allergy features)
  static Map<String, dynamic> get healthDataConsentEnabled => {
        'terms_of_service_accepted': true,
        'privacy_policy_accepted': true,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'gamification_enabled': true,
        'push_notifications_enabled': true,
        'health_data_consent_given': true,
        'consent_timestamp': '2024-01-15T10:30:00Z',
        'app_version': '1.0.0',
      };

  /// Consent with null/missing fields
  static Map<String, dynamic> get consentWithNulls => {
        'terms_of_service_accepted': null,
        'privacy_policy_accepted': null,
        'analytics_enabled': null,
        'crash_reporting_enabled': null,
        'gamification_enabled': null,
        'push_notifications_enabled': null,
        'health_data_consent_given': null,
        'consent_timestamp': null,
        'app_version': null,
      };

  /// Empty consent map
  static Map<String, dynamic> get emptyConsent => {};
}
