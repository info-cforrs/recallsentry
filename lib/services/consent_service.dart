/// Consent Service for RecallSentry
///
/// Manages user consent preferences for privacy compliance.
/// Stores preferences locally and syncs to backend.
///
/// Features:
/// - Persistent local storage of consent choices
/// - Backend synchronization
/// - Consent withdrawal support
/// - Audit trail via timestamps
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/consent_preferences.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'security_service.dart';
import 'error_reporting_service.dart';
import 'gamification_service.dart';

/// Service for managing user consent preferences
class ConsentService {
  // Singleton pattern
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;

  final _storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  // Storage key
  static const String _consentKey = 'consent_preferences';

  // Cached preferences
  ConsentPreferences? _cachedPreferences;

  // Listeners for consent changes
  final List<void Function(ConsentPreferences)> _listeners = [];

  ConsentService._internal() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  /// Add a listener for consent changes
  void addListener(void Function(ConsentPreferences) listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  void removeListener(void Function(ConsentPreferences) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners of consent changes
  void _notifyListeners(ConsentPreferences preferences) {
    for (final listener in _listeners) {
      listener(preferences);
    }
  }

  /// Get current consent preferences
  /// Returns cached preferences if available, otherwise loads from storage
  Future<ConsentPreferences> getPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    try {
      final stored = await _storage.read(key: _consentKey);
      if (stored != null) {
        _cachedPreferences = ConsentPreferences.fromJson(json.decode(stored));
        return _cachedPreferences!;
      }
    } catch (e) {
      debugPrint('Error loading consent preferences: $e');
    }

    // Return defaults if nothing stored
    _cachedPreferences = ConsentPreferences.defaults();
    return _cachedPreferences!;
  }

  /// Check if user has completed initial consent
  Future<bool> hasCompletedInitialConsent() async {
    final prefs = await getPreferences();
    return prefs.hasRequiredConsent;
  }

  /// Save consent preferences
  /// Updates local storage and syncs to backend if authenticated
  Future<void> savePreferences(ConsentPreferences preferences) async {
    // Add timestamp and version
    final updatedPreferences = preferences.copyWith(
      consentTimestamp: DateTime.now(),
      appVersion: AppConfig.appVersion,
    );

    try {
      // Save locally
      await _storage.write(
        key: _consentKey,
        value: json.encode(updatedPreferences.toJson()),
      );

      _cachedPreferences = updatedPreferences;

      // Apply consent choices to services
      await _applyConsentChoices(updatedPreferences);

      // Notify listeners
      _notifyListeners(updatedPreferences);

      // Sync to backend if authenticated
      await _syncToBackend(updatedPreferences);

      debugPrint('Consent preferences saved: $updatedPreferences');
    } catch (e) {
      debugPrint('Error saving consent preferences: $e');
      rethrow;
    }
  }

  /// Update a single consent preference
  Future<void> updatePreference({
    bool? termsOfServiceAccepted,
    bool? privacyPolicyAccepted,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? gamificationEnabled,
    bool? pushNotificationsEnabled,
    bool? healthDataConsentGiven,
  }) async {
    final current = await getPreferences();
    final updated = current.copyWith(
      termsOfServiceAccepted: termsOfServiceAccepted,
      privacyPolicyAccepted: privacyPolicyAccepted,
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
      gamificationEnabled: gamificationEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled,
      healthDataConsentGiven: healthDataConsentGiven,
    );
    await savePreferences(updated);
  }

  /// Apply consent choices to actual services
  Future<void> _applyConsentChoices(ConsentPreferences preferences) async {
    // Apply crash reporting consent
    try {
      await ErrorReportingService.setCrashlyticsCollectionEnabled(
        preferences.crashReportingEnabled,
      );
    } catch (e) {
      debugPrint('Error applying crash reporting consent: $e');
    }

    // Apply gamification consent
    try {
      GamificationService().setEnabled(preferences.gamificationEnabled);
    } catch (e) {
      debugPrint('Error applying gamification consent: $e');
    }

    // Note: Analytics and push notifications are handled by their respective services
    // when they check consent before tracking/sending
  }

  /// Sync consent preferences to backend
  Future<void> _syncToBackend(ConsentPreferences preferences) async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        // Not authenticated, skip backend sync
        return;
      }

      final response = await _httpClient.post(
        Uri.parse('$baseUrl/user/consent-preferences/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(preferences.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Consent preferences synced to backend');
      } else {
        debugPrint('Failed to sync consent to backend: ${response.statusCode}');
      }
    } catch (e) {
      // Don't fail if backend sync fails - local storage is primary
      debugPrint('Backend consent sync error (non-fatal): $e');
    }
  }

  /// Withdraw all optional consents
  Future<void> withdrawAllOptionalConsent() async {
    final current = await getPreferences();
    final updated = current.copyWith(
      analyticsEnabled: false,
      crashReportingEnabled: false,
      gamificationEnabled: false,
      pushNotificationsEnabled: false,
      healthDataConsentGiven: false,
    );
    await savePreferences(updated);
  }

  /// Clear all consent data (for logout/account deletion)
  Future<void> clearConsent() async {
    try {
      await _storage.delete(key: _consentKey);
      _cachedPreferences = null;
      debugPrint('Consent preferences cleared');
    } catch (e) {
      debugPrint('Error clearing consent preferences: $e');
    }
  }

  /// Check if analytics is consented
  Future<bool> isAnalyticsConsented() async {
    final prefs = await getPreferences();
    return prefs.analyticsEnabled;
  }

  /// Check if crash reporting is consented
  Future<bool> isCrashReportingConsented() async {
    final prefs = await getPreferences();
    return prefs.crashReportingEnabled;
  }

  /// Check if gamification is consented
  Future<bool> isGamificationConsented() async {
    final prefs = await getPreferences();
    return prefs.gamificationEnabled;
  }

  /// Check if health data consent is given (for allergy features)
  Future<bool> isHealthDataConsented() async {
    final prefs = await getPreferences();
    return prefs.healthDataConsentGiven;
  }

  /// Check if push notifications are consented
  Future<bool> isPushNotificationsConsented() async {
    final prefs = await getPreferences();
    return prefs.pushNotificationsEnabled;
  }
}
