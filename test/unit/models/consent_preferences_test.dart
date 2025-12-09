/// ConsentPreferences Model Unit Tests
///
/// Tests for the ConsentPreferences model including:
/// - JSON parsing
/// - Factory methods
/// - Required consent validation
/// - CopyWith functionality
///
/// To run: flutter test test/unit/models/consent_preferences_test.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:rs_flutter/models/consent_preferences.dart';
import '../../fixtures/consent_fixtures.dart';

void main() {
  group('ConsentPreferences - fromJson', () {
    test('parses default consent correctly', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.defaultConsent);

      expect(consent.termsOfServiceAccepted, true);
      expect(consent.privacyPolicyAccepted, true);
      expect(consent.analyticsEnabled, true);
      expect(consent.crashReportingEnabled, true);
      expect(consent.gamificationEnabled, true);
      expect(consent.pushNotificationsEnabled, true);
      expect(consent.healthDataConsentGiven, false);
    });

    test('parses all consent enabled', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.allConsentEnabled);

      expect(consent.termsOfServiceAccepted, true);
      expect(consent.privacyPolicyAccepted, true);
      expect(consent.analyticsEnabled, true);
      expect(consent.crashReportingEnabled, true);
      expect(consent.gamificationEnabled, true);
      expect(consent.pushNotificationsEnabled, true);
      expect(consent.healthDataConsentGiven, true);
    });

    test('parses minimal consent', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.minimalConsent);

      expect(consent.termsOfServiceAccepted, true);
      expect(consent.privacyPolicyAccepted, true);
      expect(consent.analyticsEnabled, false);
      expect(consent.crashReportingEnabled, false);
      expect(consent.gamificationEnabled, false);
      expect(consent.pushNotificationsEnabled, false);
      expect(consent.healthDataConsentGiven, false);
    });

    test('parses no consent', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.noConsent);

      expect(consent.termsOfServiceAccepted, false);
      expect(consent.privacyPolicyAccepted, false);
      expect(consent.analyticsEnabled, false);
      expect(consent.crashReportingEnabled, false);
      expect(consent.gamificationEnabled, false);
      expect(consent.pushNotificationsEnabled, false);
      expect(consent.healthDataConsentGiven, false);
    });

    test('parses timestamp and version', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.defaultConsent);

      expect(consent.consentTimestamp, isNotNull);
      expect(consent.appVersion, '1.0.0');
    });

    test('handles null values with defaults', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.consentWithNulls);

      expect(consent.termsOfServiceAccepted, false);
      expect(consent.privacyPolicyAccepted, false);
      expect(consent.analyticsEnabled, false);
      expect(consent.crashReportingEnabled, false);
      expect(consent.consentTimestamp, isNull);
      expect(consent.appVersion, isNull);
    });

    test('handles empty map', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.emptyConsent);

      expect(consent.termsOfServiceAccepted, false);
      expect(consent.privacyPolicyAccepted, false);
      expect(consent.analyticsEnabled, false);
    });
  });

  group('ConsentPreferences - Factory Methods', () {
    test('defaults() creates opt-out model', () {
      final consent = ConsentPreferences.defaults();

      expect(consent.termsOfServiceAccepted, true);
      expect(consent.privacyPolicyAccepted, true);
      expect(consent.analyticsEnabled, true);
      expect(consent.crashReportingEnabled, true);
      expect(consent.gamificationEnabled, true);
      expect(consent.pushNotificationsEnabled, true);
      expect(consent.healthDataConsentGiven, false); // Always explicit opt-in
      expect(consent.consentTimestamp, isNotNull);
    });

    test('allEnabled() enables everything', () {
      final consent = ConsentPreferences.allEnabled();

      expect(consent.termsOfServiceAccepted, true);
      expect(consent.privacyPolicyAccepted, true);
      expect(consent.analyticsEnabled, true);
      expect(consent.crashReportingEnabled, true);
      expect(consent.gamificationEnabled, true);
      expect(consent.pushNotificationsEnabled, true);
      expect(consent.healthDataConsentGiven, true);
    });

    test('constructor defaults to all false', () {
      final consent = ConsentPreferences();

      expect(consent.termsOfServiceAccepted, false);
      expect(consent.privacyPolicyAccepted, false);
      expect(consent.analyticsEnabled, false);
      expect(consent.crashReportingEnabled, false);
      expect(consent.gamificationEnabled, false);
      expect(consent.pushNotificationsEnabled, false);
      expect(consent.healthDataConsentGiven, false);
    });
  });

  group('ConsentPreferences - hasRequiredConsent', () {
    test('returns true when both ToS and Privacy accepted', () {
      final consent = ConsentPreferences(
        termsOfServiceAccepted: true,
        privacyPolicyAccepted: true,
      );

      expect(consent.hasRequiredConsent, true);
    });

    test('returns false when ToS not accepted', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.missingTosConsent);
      expect(consent.hasRequiredConsent, false);
    });

    test('returns false when Privacy Policy not accepted', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.missingPrivacyConsent);
      expect(consent.hasRequiredConsent, false);
    });

    test('returns false when neither accepted', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.noConsent);
      expect(consent.hasRequiredConsent, false);
    });

    test('required consent check ignores optional consents', () {
      final consent = ConsentPreferences(
        termsOfServiceAccepted: true,
        privacyPolicyAccepted: true,
        analyticsEnabled: false,
        crashReportingEnabled: false,
        gamificationEnabled: false,
        pushNotificationsEnabled: false,
        healthDataConsentGiven: false,
      );

      expect(consent.hasRequiredConsent, true);
    });
  });

  group('ConsentPreferences - hasAnyOptionalConsent', () {
    test('returns true when analytics enabled', () {
      final consent = ConsentPreferences(analyticsEnabled: true);
      expect(consent.hasAnyOptionalConsent, true);
    });

    test('returns true when crash reporting enabled', () {
      final consent = ConsentPreferences(crashReportingEnabled: true);
      expect(consent.hasAnyOptionalConsent, true);
    });

    test('returns true when gamification enabled', () {
      final consent = ConsentPreferences(gamificationEnabled: true);
      expect(consent.hasAnyOptionalConsent, true);
    });

    test('returns true when push notifications enabled', () {
      final consent = ConsentPreferences(pushNotificationsEnabled: true);
      expect(consent.hasAnyOptionalConsent, true);
    });

    test('returns true when health data consent given', () {
      final consent = ConsentPreferences(healthDataConsentGiven: true);
      expect(consent.hasAnyOptionalConsent, true);
    });

    test('returns false when no optional consents given', () {
      final consent = ConsentPreferences(
        termsOfServiceAccepted: true,
        privacyPolicyAccepted: true,
        analyticsEnabled: false,
        crashReportingEnabled: false,
        gamificationEnabled: false,
        pushNotificationsEnabled: false,
        healthDataConsentGiven: false,
      );

      expect(consent.hasAnyOptionalConsent, false);
    });
  });

  group('ConsentPreferences - toJson', () {
    test('serializes all fields', () {
      final consent = ConsentPreferences.allEnabled();
      final json = consent.toJson();

      expect(json['terms_of_service_accepted'], true);
      expect(json['privacy_policy_accepted'], true);
      expect(json['analytics_enabled'], true);
      expect(json['crash_reporting_enabled'], true);
      expect(json['gamification_enabled'], true);
      expect(json['push_notifications_enabled'], true);
      expect(json['health_data_consent_given'], true);
    });

    test('serializes timestamp as ISO string', () {
      final consent = ConsentPreferences.defaults();
      final json = consent.toJson();

      expect(json['consent_timestamp'], isA<String>());
    });

    test('handles null timestamp', () {
      final consent = ConsentPreferences();
      final json = consent.toJson();

      expect(json['consent_timestamp'], isNull);
    });

    test('round-trips through JSON correctly', () {
      final original = ConsentPreferences.allEnabled();
      final json = original.toJson();
      final restored = ConsentPreferences.fromJson(json);

      expect(restored.termsOfServiceAccepted, original.termsOfServiceAccepted);
      expect(restored.privacyPolicyAccepted, original.privacyPolicyAccepted);
      expect(restored.analyticsEnabled, original.analyticsEnabled);
      expect(restored.crashReportingEnabled, original.crashReportingEnabled);
      expect(restored.gamificationEnabled, original.gamificationEnabled);
      expect(restored.pushNotificationsEnabled, original.pushNotificationsEnabled);
      expect(restored.healthDataConsentGiven, original.healthDataConsentGiven);
    });
  });

  group('ConsentPreferences - copyWith', () {
    test('copies with single field change', () {
      final original = ConsentPreferences.defaults();
      final modified = original.copyWith(analyticsEnabled: false);

      expect(modified.termsOfServiceAccepted, true);
      expect(modified.privacyPolicyAccepted, true);
      expect(modified.analyticsEnabled, false);
      expect(modified.crashReportingEnabled, true);
    });

    test('copies with multiple field changes', () {
      final original = ConsentPreferences.defaults();
      final modified = original.copyWith(
        analyticsEnabled: false,
        crashReportingEnabled: false,
        healthDataConsentGiven: true,
      );

      expect(modified.analyticsEnabled, false);
      expect(modified.crashReportingEnabled, false);
      expect(modified.healthDataConsentGiven, true);
      expect(modified.gamificationEnabled, true); // Unchanged
    });

    test('copies with no changes returns equivalent object', () {
      final original = ConsentPreferences.defaults();
      final copy = original.copyWith();

      expect(copy.termsOfServiceAccepted, original.termsOfServiceAccepted);
      expect(copy.privacyPolicyAccepted, original.privacyPolicyAccepted);
      expect(copy.analyticsEnabled, original.analyticsEnabled);
    });

    test('copies with timestamp update', () {
      final original = ConsentPreferences.defaults();
      final newTimestamp = DateTime.now().add(const Duration(days: 1));
      final modified = original.copyWith(consentTimestamp: newTimestamp);

      expect(modified.consentTimestamp, newTimestamp);
    });

    test('copies with version update', () {
      final original = ConsentPreferences.defaults();
      final modified = original.copyWith(appVersion: '2.0.0');

      expect(modified.appVersion, '2.0.0');
    });
  });

  group('ConsentPreferences - toString', () {
    test('produces readable string', () {
      final consent = ConsentPreferences.defaults();
      final str = consent.toString();

      expect(str, contains('ConsentPreferences'));
      expect(str, contains('terms:'));
      expect(str, contains('privacy:'));
      expect(str, contains('analytics:'));
      expect(str, contains('crash:'));
      expect(str, contains('gamification:'));
      expect(str, contains('push:'));
      expect(str, contains('health:'));
    });
  });

  group('ConsentPreferences - Health Data Consent', () {
    test('health data consent requires explicit opt-in', () {
      // Default factory does NOT enable health data consent
      final defaults = ConsentPreferences.defaults();
      expect(defaults.healthDataConsentGiven, false);
    });

    test('health data consent can be enabled', () {
      final consent = ConsentPreferences.fromJson(ConsentFixtures.healthDataConsentEnabled);
      expect(consent.healthDataConsentGiven, true);
    });

    test('health data consent can be toggled via copyWith', () {
      final withoutConsent = ConsentPreferences.defaults();
      expect(withoutConsent.healthDataConsentGiven, false);

      final withConsent = withoutConsent.copyWith(healthDataConsentGiven: true);
      expect(withConsent.healthDataConsentGiven, true);

      final withdrawn = withConsent.copyWith(healthDataConsentGiven: false);
      expect(withdrawn.healthDataConsentGiven, false);
    });
  });
}
