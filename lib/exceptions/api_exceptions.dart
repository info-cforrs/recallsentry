/// Custom exception types for API and service layer errors
///
/// Provides a consistent exception hierarchy for better error handling
/// and more meaningful error messages throughout the application.
library;

/// Base exception for all API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;
  final StackTrace? stackTrace;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }
    return buffer.toString();
  }
}

/// Exception thrown when network connectivity issues occur
class NetworkException extends ApiException {
  NetworkException(
    super.message, {
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails or token is invalid
class AuthException extends ApiException {
  final bool shouldLogout;

  AuthException(
    super.message, {
    super.statusCode,
    this.shouldLogout = false,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when input validation fails
class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.statusCode,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ValidationException: $message');
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      buffer.write('\nField errors:');
      fieldErrors!.forEach((field, errors) {
        buffer.write('\n  $field: ${errors.join(", ")}');
      });
    }
    return buffer.toString();
  }
}

/// Exception thrown when a resource is not found (404)
class NotFoundException extends ApiException {
  final String? resourceType;
  final String? resourceId;

  NotFoundException(
    super.message, {
    this.resourceType,
    this.resourceId,
    super.originalException,
    super.stackTrace,
  }) : super(statusCode: 404);

  @override
  String toString() {
    final buffer = StringBuffer('NotFoundException: $message');
    if (resourceType != null) {
      buffer.write(' (Type: $resourceType');
      if (resourceId != null) {
        buffer.write(', ID: $resourceId');
      }
      buffer.write(')');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a tier/subscription limit is reached
class TierLimitException extends ApiException {
  final int currentCount;
  final int limit;
  final String feature;

  TierLimitException(
    super.message, {
    required this.currentCount,
    required this.limit,
    required this.feature,
    int? statusCode,
  }) : super(statusCode: statusCode ?? 403);

  @override
  String toString() =>
      'TierLimitException: $message (Feature: $feature, $currentCount/$limit)';
}

/// Exception thrown when rate limiting is applied
class RateLimitException extends ApiException {
  final DateTime? retryAfter;
  final int? remainingRequests;

  RateLimitException(
    super.message, {
    this.retryAfter,
    this.remainingRequests,
    int? statusCode,
  }) : super(statusCode: statusCode ?? 429);

  @override
  String toString() {
    final buffer = StringBuffer('RateLimitException: $message');
    if (retryAfter != null) {
      buffer.write(' (Retry after: $retryAfter)');
    }
    if (remainingRequests != null) {
      buffer.write(' (Remaining: $remainingRequests)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when cache operations fail
class CacheException extends ApiException {
  final String cacheKey;
  final String operation;

  CacheException(
    super.message, {
    required this.cacheKey,
    required this.operation,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() =>
      'CacheException: $message (Key: $cacheKey, Operation: $operation)';
}

/// Exception thrown when server returns 5xx errors
class ServerException extends ApiException {
  ServerException(
    super.message, {
    super.statusCode,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'ServerException: $message';
}

/// Exception thrown when data parsing/serialization fails
class SerializationException extends ApiException {
  final String dataType;

  SerializationException(
    super.message, {
    required this.dataType,
    super.originalException,
    super.stackTrace,
  });

  @override
  String toString() => 'SerializationException: $message (Type: $dataType)';
}
