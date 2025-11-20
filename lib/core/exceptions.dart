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
    required String message,
    String? code,
    this.statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code ?? statusCode?.toString(),
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    String? code,
    this.isTokenExpired = false,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
          stackTrace: stackTrace,
        );

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
    required String message,
    this.fieldErrors,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'validation_error',
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    required this.retryAfterSeconds,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: '429',
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    required this.statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: statusCode.toString(),
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'data_error',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String get displayMessage => 'Failed to process data. Please try again.';
}

/// Exception for cache-related errors (non-critical)
class CacheException extends AppException {
  CacheException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'cache_error',
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    this.isCritical = false,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'storage_error',
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    required this.currentTier,
    this.currentCount,
    this.limit,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'subscription_limit',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String get displayMessage => message;

  @override
  bool get shouldReport => false; // Subscription limits are expected
}

/// Exception for offline/connectivity errors
class ConnectivityException extends AppException {
  ConnectivityException({
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'no_connection',
          originalError: originalError,
          stackTrace: stackTrace,
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
    required String message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
          message: message,
          code: 'unknown',
          originalError: originalError,
          stackTrace: stackTrace,
        );

  @override
  String get displayMessage =>
      'An unexpected error occurred. Please try again.';
}
