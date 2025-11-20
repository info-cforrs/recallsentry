/// Error Reporting Service for RecallSentry
///
/// Integrates with Firebase Crashlytics to track errors and crashes
/// in production while providing useful debug information in development.
library;

import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';

/// Service for reporting errors to Firebase Crashlytics
class ErrorReportingService {
  static bool _initialized = false;

  /// Initialize error reporting service
  ///
  /// Should be called in main() before running the app
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Set up Crashlytics error handling
      if (!kIsWeb) {
        // Pass all uncaught Flutter errors to Crashlytics
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);

          // Also print in debug mode for development
          if (kDebugMode) {
            FlutterError.presentError(errorDetails);
          }
        };

        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stack,
            fatal: true,
          );
          return true;
        };

        // Set custom keys for better crash analysis
        await _setCustomKeys();

        _initialized = true;
        debugPrint('✅ Error Reporting Service initialized');
      } else {
        debugPrint('⚠️ Crashlytics not available on web platform');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to initialize Error Reporting Service: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Set custom keys for crash reports
  static Future<void> _setCustomKeys() async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey('app_name', 'RecallSentry');
      await FirebaseCrashlytics.instance.setCustomKey('environment', kDebugMode ? 'debug' : 'production');
    } catch (e) {
      debugPrint('⚠️ Failed to set custom keys: $e');
    }
  }

  /// Record a non-fatal exception
  ///
  /// Use this for caught exceptions that you want to track but aren't fatal
  static Future<void> recordException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalInfo,
    bool fatal = false,
  }) async {
    if (!_initialized || kIsWeb) {
      // Just log in debug mode if not initialized or on web
      if (kDebugMode) {
        debugPrint('🔴 Exception in $context: $exception');
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
      return;
    }

    try {
      // Check if we should report this error
      if (exception is AppException && !exception.shouldReport) {
        // Don't report expected errors (auth, validation, etc.)
        if (kDebugMode) {
          debugPrint('ℹ️ Skipping expected error: $exception');
        }
        return;
      }

      // Set context if provided
      if (context != null) {
        await FirebaseCrashlytics.instance.setCustomKey('error_context', context);
      }

      // Set additional info if provided
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(
            'info_${entry.key}',
            entry.value.toString(),
          );
        }
      }

      // Record the error
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: context,
        fatal: fatal,
      );

      if (kDebugMode) {
        debugPrint('📊 Reported error to Crashlytics: $exception');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to record exception: $e');
    }
  }

  /// Log a message to Crashlytics
  ///
  /// Useful for tracking application flow leading up to crashes
  static Future<void> log(String message) async {
    if (!_initialized || kIsWeb) {
      if (kDebugMode) {
        debugPrint('📝 Log: $message');
      }
      return;
    }

    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('⚠️ Failed to log message: $e');
    }
  }

  /// Set user identifier for crash reports
  ///
  /// Call this after user login to associate crashes with users
  static Future<void> setUserIdentifier(String userId) async {
    if (!_initialized || kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      debugPrint('👤 Set user identifier for crash reports: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to set user identifier: $e');
    }
  }

  /// Clear user identifier for crash reports
  ///
  /// Call this after user logout
  static Future<void> clearUserIdentifier() async {
    if (!_initialized || kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
      debugPrint('👤 Cleared user identifier for crash reports');
    } catch (e) {
      debugPrint('⚠️ Failed to clear user identifier: $e');
    }
  }

  /// Set custom key-value pair for crash context
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (!_initialized || kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to set custom key: $e');
    }
  }

  /// Enable/disable crash collection
  ///
  /// Useful for respecting user privacy preferences
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    if (!_initialized || kIsWeb) return;

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      debugPrint('🔧 Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('⚠️ Failed to set crashlytics collection: $e');
    }
  }

  /// Force a test crash (for testing crash reporting in debug mode)
  ///
  /// WARNING: Only use this for testing!
  static void testCrash() {
    if (kDebugMode) {
      debugPrint('💥 Forcing test crash...');
      FirebaseCrashlytics.instance.crash();
    }
  }
}
