/// Core exception hierarchy for RecallSentry application
///
/// This file defines custom exceptions that provide better error handling
/// and user-friendly error messages across the application.
library;

import 'package:flutter/foundation.dart';

/// Base exception class for all application-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// User-friendly error message to display in UI
  String get displayMessage;

  /// Whether this error should be reported to crash analytics
  bool get shouldReport => true;

  @override
  String toString() {
    if (kDebugMode) {
      return 'AppException: $message (code: $code, original: $originalError)';
    }
    return displayMessage;
  }
}

/// Exception for network-related errors (connection, timeout, etc.)
class NetworkException extends AppException {
  final int? statusCode;

  NetworkException({
    required super.message,
    String? code,
    this.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: code ?? statusCode?.toString(),
        );

  @override
  String get displayMessage {
    if (code == '408' || message.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (statusCode != null && statusCode! >= 500) {
      return 'Server error. Please try again later.';
    }
    return 'Network error. Please check your connection and try again.';
  }

  @override
  bool get shouldReport => statusCode == null || statusCode! >= 500;
}

/// Exception for authentication and authorization errors
class AuthException extends AppException {
  final bool isTokenExpired;

  AuthException({
    required super.message,
    super.code,
    this.isTokenExpired = false,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get displayMessage {
    if (code == '401' || isTokenExpired) {
      return 'Your session has expired. Please log in again.';
    }
    if (code == '403') {
      return 'You do not have permission to perform this action.';
    }
    if (message.toLowerCase().contains('password')) {
      return 'Invalid username or password.';
    }
    return 'Authentication failed. Please log in again.';
  }

  @override
  bool get shouldReport => false; // Auth errors are expected, don't report
}

/// Exception for data validation errors
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException({
    required super.message,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'validation_error',
        );

  @override
  String get displayMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.values.expand((e) => e).take(3).join(', ');
      return 'Validation failed: $errors';
    }
    return message;
  }

  /// Get errors for a specific field
  List<String>? getFieldErrors(String fieldName) => fieldErrors?[fieldName];

  @override
  bool get shouldReport => false; // Validation errors are expected
}

/// Exception for rate limiting (429 responses)
class RateLimitException extends AppException {
  final int retryAfterSeconds;

  RateLimitException({
    required super.message,
    required this.retryAfterSeconds,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: '429',
        );

  @override
  String get displayMessage {
    if (retryAfterSeconds <= 60) {
      return 'Too many requests. Please wait $retryAfterSeconds seconds and try again.';
    }
    final minutes = (retryAfterSeconds / 60).ceil();
    return 'Too many requests. Please wait $minutes minutes and try again.';
  }

  @override
  bool get shouldReport => false; // Rate limits are expected behavior
}

/// Exception for server errors (5xx responses)
class ServerException extends AppException {
  final int statusCode;

  ServerException({
    required super.message,
    required this.statusCode,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: statusCode.toString(),
        );

  @override
  String get displayMessage {
    if (statusCode == 503) {
      return 'Service temporarily unavailable. Please try again later.';
    }
    if (statusCode == 502 || statusCode == 504) {
      return 'Gateway error. Please try again.';
    }
    return 'Server error. Please try again later.';
  }
}

/// Exception for data parsing errors
class DataException extends AppException {
  DataException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'data_error',
        );

  @override
  String get displayMessage => 'Failed to process data. Please try again.';
}

/// Exception for cache-related errors (non-critical)
class CacheException extends AppException {
  CacheException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'cache_error',
        );

  @override
  String get displayMessage => 'Cache error occurred.';

  @override
  bool get shouldReport => false; // Cache errors are not critical
}

/// Exception for local storage errors
class StorageException extends AppException {
  final bool isCritical;

  StorageException({
    required super.message,
    this.isCritical = false,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'storage_error',
        );

  @override
  String get displayMessage {
    if (isCritical) {
      return 'Storage error. Please ensure the app has proper permissions.';
    }
    return 'Failed to save data locally.';
  }

  @override
  bool get shouldReport => isCritical;
}

/// Exception for subscription/limit errors
class SubscriptionException extends AppException {
  final String currentTier;
  final int? currentCount;
  final int? limit;

  SubscriptionException({
    required super.message,
    required this.currentTier,
    this.currentCount,
    this.limit,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'subscription_limit',
        );

  @override
  String get displayMessage => message;

  @override
  bool get shouldReport => false; // Subscription limits are expected
}

/// Exception for offline/connectivity errors
class ConnectivityException extends AppException {
  ConnectivityException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'no_connection',
        );

  @override
  String get displayMessage =>
      'No internet connection. Please check your network settings.';

  @override
  bool get shouldReport => false; // Connectivity issues are expected
}

/// Exception for unknown/unexpected errors
class UnknownException extends AppException {
  UnknownException({
    required super.message,
    super.originalError,
    super.stackTrace,
  }) : super(
          code: 'unknown',
        );

  @override
  String get displayMessage =>
      'An unexpected error occurred. Please try again.';
}
