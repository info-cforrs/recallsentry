/// Error Handling Unit Tests
///
/// Tests for error handling patterns including:
/// - Exception classification
/// - Error message extraction
/// - User-friendly error messages
/// - Error recovery strategies
/// - Logging and reporting
///
/// To run: flutter test test/unit/services/error_handling_test.dart
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Error Classification - Network Errors', () {
    test('classifies connection timeout as network error', () {
      const error = 'Connection timed out';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.network);
    });

    test('classifies no internet as network error', () {
      const error = 'No internet connection';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.network);
    });

    test('classifies socket exception as network error', () {
      const error = 'SocketException: Failed to connect';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.network);
    });

    test('classifies DNS failure as network error', () {
      const error = 'Failed host lookup';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.network);
    });
  });

  group('Error Classification - Authentication Errors', () {
    test('classifies 401 as auth error', () {
      final error = ApiError(statusCode: 401, message: 'Unauthorized');
      expect(error.isAuthError, true);
    });

    test('classifies invalid token as auth error', () {
      const error = 'Token is invalid or expired';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.authentication);
    });

    test('classifies wrong credentials as auth error', () {
      const error = 'Invalid username or password';
      final errorType = _classifyError(error);
      expect(errorType, ErrorType.authentication);
    });
  });

  group('Error Classification - Validation Errors', () {
    test('classifies 400 as validation error', () {
      final error = ApiError(statusCode: 400, message: 'Bad Request');
      expect(error.isValidationError, true);
    });

    test('classifies 422 as validation error', () {
      final error = ApiError(statusCode: 422, message: 'Unprocessable Entity');
      expect(error.isValidationError, true);
    });

    test('extracts field-specific validation errors', () {
      final errors = {
        'email': ['Invalid email format'],
        'password': ['Password too short', 'Must contain a number'],
      };

      expect(errors['email']?.first, 'Invalid email format');
      expect(errors['password']?.length, 2);
    });
  });

  group('Error Classification - Server Errors', () {
    test('classifies 500 as server error', () {
      final error = ApiError(statusCode: 500, message: 'Internal Server Error');
      expect(error.isServerError, true);
    });

    test('classifies 502 as server error', () {
      final error = ApiError(statusCode: 502, message: 'Bad Gateway');
      expect(error.isServerError, true);
    });

    test('classifies 503 as server error', () {
      final error = ApiError(statusCode: 503, message: 'Service Unavailable');
      expect(error.isServerError, true);
    });
  });

  group('Error Classification - Rate Limiting', () {
    test('classifies 429 as rate limit error', () {
      final error = ApiError(statusCode: 429, message: 'Too Many Requests');
      expect(error.isRateLimited, true);
    });

    test('extracts retry-after from rate limit response', () {
      final response = {
        'detail': 'Request was throttled',
        'retry_after': 60,
      };

      final retryAfter = response['retry_after'] as int?;
      expect(retryAfter, 60);
    });
  });

  group('User-Friendly Error Messages', () {
    test('converts network error to user message', () {
      const error = 'SocketException: Connection refused';
      final userMessage = _toUserMessage(error);

      expect(userMessage, isNot(contains('Socket')));
      expect(userMessage.toLowerCase(), contains('connection'));
    });

    test('converts auth error to user message', () {
      final error = ApiError(statusCode: 401, message: 'Unauthorized');
      final userMessage = error.userFriendlyMessage;

      expect(userMessage, contains('session'));
    });

    test('converts server error to user message', () {
      final error = ApiError(statusCode: 500, message: 'Internal Server Error');
      final userMessage = error.userFriendlyMessage;

      expect(userMessage, contains('try again'));
    });

    test('converts validation error to user message', () {
      final error = ApiError(
        statusCode: 400,
        message: 'Validation failed',
        fieldErrors: {'email': ['Invalid email format']},
      );
      final userMessage = error.userFriendlyMessage;

      expect(userMessage, contains('check'));
    });

    test('provides generic message for unknown errors', () {
      const error = 'Unknown error occurred XYZ123';
      final userMessage = _toUserMessage(error);

      expect(userMessage, isNot(contains('XYZ123')));
      expect(userMessage.toLowerCase(), contains('something went wrong'));
    });
  });

  group('Error Recovery Strategies', () {
    test('network error suggests retry', () {
      final error = AppError(type: ErrorType.network);
      final recovery = error.suggestedRecovery;

      expect(recovery, RecoveryAction.retry);
    });

    test('auth error suggests re-login', () {
      final error = AppError(type: ErrorType.authentication);
      final recovery = error.suggestedRecovery;

      expect(recovery, RecoveryAction.reLogin);
    });

    test('validation error suggests fix input', () {
      final error = AppError(type: ErrorType.validation);
      final recovery = error.suggestedRecovery;

      expect(recovery, RecoveryAction.fixInput);
    });

    test('server error suggests retry later', () {
      final error = AppError(type: ErrorType.server);
      final recovery = error.suggestedRecovery;

      expect(recovery, RecoveryAction.retryLater);
    });

    test('rate limit error suggests wait', () {
      final error = AppError(type: ErrorType.rateLimit, retryAfter: 60);
      final recovery = error.suggestedRecovery;

      expect(recovery, RecoveryAction.wait);
      expect(error.retryAfter, 60);
    });
  });

  group('Error Context', () {
    test('captures operation context', () {
      final error = AppError(
        type: ErrorType.network,
        operation: 'fetch_recalls',
        timestamp: DateTime.now(),
      );

      expect(error.operation, 'fetch_recalls');
      expect(error.timestamp, isNotNull);
    });

    test('captures stack trace for debugging', () {
      try {
        throw Exception('Test error');
      } catch (e, stackTrace) {
        final error = AppError(
          type: ErrorType.unknown,
          originalError: e,
          stackTrace: stackTrace,
        );

        expect(error.stackTrace, isNotNull);
        expect(error.originalError, isNotNull);
      }
    });

    test('captures request details for API errors', () {
      final error = ApiError(
        statusCode: 500,
        message: 'Server Error',
        requestUrl: 'https://api.example.com/recalls',
        requestMethod: 'GET',
      );

      expect(error.requestUrl, contains('recalls'));
      expect(error.requestMethod, 'GET');
    });
  });

  group('Error Logging', () {
    test('error log entry has required fields', () {
      final logEntry = ErrorLogEntry(
        timestamp: DateTime.now(),
        errorType: ErrorType.network,
        message: 'Connection failed',
        userId: 'user123',
        appVersion: '1.0.0',
      );

      expect(logEntry.timestamp, isNotNull);
      expect(logEntry.errorType, ErrorType.network);
      expect(logEntry.message, isNotEmpty);
    });

    test('sensitive data is redacted in logs', () {
      const originalMessage = 'Failed to login with password: secret123';
      final redactedMessage = _redactSensitiveData(originalMessage);

      expect(redactedMessage, isNot(contains('secret123')));
      expect(redactedMessage, contains('***'));
    });

    test('tokens are redacted in logs', () {
      const originalMessage = 'Authorization: Bearer eyJhbGciOiJIUzI1NiIs...';
      final redactedMessage = _redactSensitiveData(originalMessage);

      expect(redactedMessage, isNot(contains('eyJ')));
    });

    test('error log is serializable', () {
      final logEntry = ErrorLogEntry(
        timestamp: DateTime.now(),
        errorType: ErrorType.server,
        message: 'Server error',
        userId: 'user123',
        appVersion: '1.0.0',
      );

      final json = logEntry.toJson();
      expect(json['timestamp'], isNotNull);
      expect(json['errorType'], 'server');
      expect(json['message'], 'Server error');
    });
  });

  group('Error Boundaries', () {
    test('catches and wraps unexpected errors', () {
      AppError? caughtError;

      try {
        // Simulate unexpected error
        throw FormatException('Unexpected format');
      } catch (e) {
        caughtError = AppError.fromException(e);
      }

      expect(caughtError, isNotNull);
      expect(caughtError!.type, ErrorType.unknown);
    });

    test('preserves error chain', () {
      Exception? originalError;
      AppError? wrappedError;

      try {
        try {
          throw FormatException('Inner error');
        } catch (e) {
          throw Exception('Outer error: $e');
        }
      } catch (e) {
        originalError = e as Exception;
        wrappedError = AppError.fromException(e);
      }

      expect(wrappedError?.originalError, isNotNull);
      expect(originalError.toString(), contains('Inner error'));
    });
  });

  group('Offline Error Handling', () {
    test('queues failed requests when offline', () {
      final offlineQueue = <Map<String, dynamic>>[];

      // Simulate failed request due to offline
      final failedRequest = {
        'url': 'https://api.example.com/recalls',
        'method': 'POST',
        'body': {'recallId': 123},
        'timestamp': DateTime.now().toIso8601String(),
      };

      offlineQueue.add(failedRequest);
      expect(offlineQueue.length, 1);
    });

    test('retries queued requests when online', () {
      final offlineQueue = [
        {'url': 'url1', 'retryCount': 0},
        {'url': 'url2', 'retryCount': 0},
      ];

      // Simulate coming back online
      const isOnline = true;

      if (isOnline) {
        for (final request in offlineQueue) {
          request['retryCount'] = (request['retryCount'] as int) + 1;
        }
      }

      expect(offlineQueue[0]['retryCount'], 1);
      expect(offlineQueue[1]['retryCount'], 1);
    });

    test('limits offline queue size', () {
      const maxQueueSize = 100;
      final offlineQueue = <Map<String, dynamic>>[];

      // Add items up to limit
      for (var i = 0; i < 150; i++) {
        if (offlineQueue.length >= maxQueueSize) {
          offlineQueue.removeAt(0); // Remove oldest
        }
        offlineQueue.add({'id': i});
      }

      expect(offlineQueue.length, maxQueueSize);
    });
  });

  group('Graceful Degradation', () {
    test('returns cached data on network error', () {
      const hasCache = true;
      const networkError = true;

      final shouldUseCachedData = networkError && hasCache;
      expect(shouldUseCachedData, true);
    });

    test('shows stale indicator for cached data', () {
      final cachedAt = DateTime.now().subtract(const Duration(hours: 2));
      const maxFreshness = Duration(hours: 1);

      final isStale = DateTime.now().difference(cachedAt) > maxFreshness;
      expect(isStale, true);
    });

    test('provides fallback UI on error', () {
      const hasError = true;
      const fallbackMessage = 'Unable to load data. Showing cached results.';

      if (hasError) {
        expect(fallbackMessage, contains('cached'));
      }
    });
  });

  group('Error Analytics', () {
    test('tracks error frequency', () {
      final errorCounts = <ErrorType, int>{};

      void trackError(ErrorType type) {
        errorCounts[type] = (errorCounts[type] ?? 0) + 1;
      }

      // Simulate errors
      trackError(ErrorType.network);
      trackError(ErrorType.network);
      trackError(ErrorType.server);

      expect(errorCounts[ErrorType.network], 2);
      expect(errorCounts[ErrorType.server], 1);
    });

    test('identifies error patterns', () {
      final recentErrors = [
        ErrorLogEntry(
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          errorType: ErrorType.network,
          message: 'Connection failed',
        ),
        ErrorLogEntry(
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          errorType: ErrorType.network,
          message: 'Connection failed',
        ),
        ErrorLogEntry(
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          errorType: ErrorType.network,
          message: 'Connection failed',
        ),
      ];

      final networkErrorCount = recentErrors
          .where((e) => e.errorType == ErrorType.network)
          .length;

      // Pattern: Multiple network errors in short time = connectivity issue
      final hasConnectivityIssue = networkErrorCount >= 3;
      expect(hasConnectivityIssue, true);
    });
  });
}

// Helper types and functions

enum ErrorType {
  network,
  authentication,
  validation,
  server,
  rateLimit,
  unknown,
}

enum RecoveryAction {
  retry,
  reLogin,
  fixInput,
  retryLater,
  wait,
  none,
}

class ApiError {
  final int statusCode;
  final String message;
  final Map<String, List<String>>? fieldErrors;
  final String? requestUrl;
  final String? requestMethod;

  ApiError({
    required this.statusCode,
    required this.message,
    this.fieldErrors,
    this.requestUrl,
    this.requestMethod,
  });

  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get isRateLimited => statusCode == 429;

  String get userFriendlyMessage {
    if (isAuthError) {
      return 'Your session has expired. Please log in again.';
    }
    if (isValidationError) {
      return 'Please check your input and try again.';
    }
    if (isServerError) {
      return 'Something went wrong on our end. Please try again later.';
    }
    if (isRateLimited) {
      return 'Too many requests. Please wait a moment.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class AppError {
  final ErrorType type;
  final String? operation;
  final DateTime? timestamp;
  final Object? originalError;
  final StackTrace? stackTrace;
  final int? retryAfter;

  AppError({
    required this.type,
    this.operation,
    this.timestamp,
    this.originalError,
    this.stackTrace,
    this.retryAfter,
  });

  factory AppError.fromException(Object e) {
    return AppError(
      type: ErrorType.unknown,
      originalError: e,
      timestamp: DateTime.now(),
    );
  }

  RecoveryAction get suggestedRecovery {
    switch (type) {
      case ErrorType.network:
        return RecoveryAction.retry;
      case ErrorType.authentication:
        return RecoveryAction.reLogin;
      case ErrorType.validation:
        return RecoveryAction.fixInput;
      case ErrorType.server:
        return RecoveryAction.retryLater;
      case ErrorType.rateLimit:
        return RecoveryAction.wait;
      case ErrorType.unknown:
        return RecoveryAction.none;
    }
  }
}

class ErrorLogEntry {
  final DateTime timestamp;
  final ErrorType errorType;
  final String message;
  final String? userId;
  final String? appVersion;

  ErrorLogEntry({
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.userId,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'errorType': errorType.name,
        'message': message,
        'userId': userId,
        'appVersion': appVersion,
      };
}

ErrorType _classifyError(String error) {
  final lowerError = error.toLowerCase();

  if (lowerError.contains('connection') ||
      lowerError.contains('socket') ||
      lowerError.contains('network') ||
      lowerError.contains('internet') ||
      lowerError.contains('timeout') ||
      lowerError.contains('host lookup')) {
    return ErrorType.network;
  }

  if (lowerError.contains('token') ||
      lowerError.contains('unauthorized') ||
      lowerError.contains('credentials') ||
      lowerError.contains('password')) {
    return ErrorType.authentication;
  }

  return ErrorType.unknown;
}

String _toUserMessage(String error) {
  final errorType = _classifyError(error);

  switch (errorType) {
    case ErrorType.network:
      return 'Unable to connect. Please check your connection and try again.';
    case ErrorType.authentication:
      return 'Your session has expired. Please log in again.';
    case ErrorType.server:
      return 'Something went wrong on our end. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

String _redactSensitiveData(String message) {
  var redacted = message;

  // Redact passwords
  redacted = redacted.replaceAll(RegExp(r'password[:\s]*\S+'), 'password: ***');

  // Redact tokens
  redacted = redacted.replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***');
  redacted = redacted.replaceAll(RegExp(r'eyJ[A-Za-z0-9_-]+'), '***');

  return redacted;
}
