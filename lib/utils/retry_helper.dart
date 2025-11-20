/// Retry Helper with Exponential Backoff
///
/// Provides retry logic for operations that may fail transiently,
/// such as network requests. Uses exponential backoff to avoid
/// overwhelming servers during outages.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';

/// Configuration for retry behavior
class RetryConfig {
  /// Maximum number of retry attempts
  final int maxRetries;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Whether to retry on all errors or only specific ones
  final bool retryOnAllErrors;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryOnAllErrors = false,
  });

  /// Aggressive retry config for critical operations
  static const aggressive = RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 200),
    backoffMultiplier: 1.5,
    maxDelay: Duration(seconds: 10),
  );

  /// Conservative retry config for non-critical operations
  static const conservative = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 3.0,
    maxDelay: Duration(seconds: 60),
  );

  /// Default retry config
  static const standard = RetryConfig();
}

/// Helper class for retrying operations with exponential backoff
class RetryHelper {
  /// Retry an operation with exponential backoff
  ///
  /// Example:
  /// ```dart
  /// final data = await RetryHelper.retry(
  ///   () => apiService.fetchData(),
  ///   config: RetryConfig.standard,
  /// );
  /// ```
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    String? operationName,
  }) async {
    int attempt = 0;
    Duration currentDelay = config.initialDelay;

    while (true) {
      try {
        // Log attempt in debug mode
        if (kDebugMode && attempt > 0) {
          debugPrint('🔄 Retry attempt $attempt/${config.maxRetries} for ${operationName ?? 'operation'}');
        }

        // Execute the operation
        return await operation();
      } catch (e) {
        attempt++;

        // Log error in debug mode
        if (kDebugMode) {
          debugPrint('❌ Attempt $attempt failed: $e');
        }

        // Check if we've exhausted retries
        if (attempt >= config.maxRetries) {
          if (kDebugMode) {
            debugPrint('🚫 Max retries ($attempt) reached for ${operationName ?? 'operation'}');
          }
          rethrow;
        }

        // Check if this error should be retried
        if (!config.retryOnAllErrors && !_shouldRetry(e)) {
          if (kDebugMode) {
            debugPrint('🚫 Error not retryable: ${e.runtimeType}');
          }
          rethrow;
        }

        // Wait before retrying with exponential backoff
        if (kDebugMode) {
          debugPrint('⏳ Waiting ${currentDelay.inMilliseconds}ms before retry...');
        }
        await Future.delayed(currentDelay);

        // Calculate next delay with exponential backoff
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * config.backoffMultiplier).round(),
        );

        // Cap at max delay
        if (currentDelay > config.maxDelay) {
          currentDelay = config.maxDelay;
        }
      }
    }
  }

  /// Retry an operation with a simple retry count (no backoff)
  ///
  /// Useful for quick operations where backoff isn't necessary
  static Future<T> retrySimple<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow;
        }

        if (!_shouldRetry(e)) {
          rethrow;
        }

        await Future.delayed(delay);
      }
    }
  }

  /// Determine if an error should be retried
  ///
  /// Returns true for transient errors (network, timeout, server errors)
  /// Returns false for permanent errors (auth, validation, rate limits)
  static bool _shouldRetry(dynamic error) {
    // Don't retry authentication errors
    if (error is AuthException) {
      return false;
    }

    // Don't retry validation errors
    if (error is ValidationException) {
      return false;
    }

    // Don't retry rate limit errors
    if (error is RateLimitException) {
      return false;
    }

    // Don't retry subscription/limit errors
    if (error is SubscriptionException) {
      return false;
    }

    // Retry network errors
    if (error is NetworkException) {
      // Retry timeouts
      if (error.code == '408') return true;

      // Retry server errors (5xx)
      if (error.statusCode != null && error.statusCode! >= 500) {
        return true;
      }

      // Retry connection errors
      return true;
    }

    // Retry connectivity errors
    if (error is ConnectivityException) {
      return true;
    }

    // Retry server errors
    if (error is ServerException) {
      return true;
    }

    // For unknown errors, check the message
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('network')) {
      return true;
    }

    // Don't retry other errors by default
    return false;
  }

  /// Check if an error is retryable
  ///
  /// Public method for checking if an operation should be retried
  static bool isRetryable(dynamic error) {
    return _shouldRetry(error);
  }
}

/// Extension on Future to add retry capability
extension RetryExtension<T> on Future<T> Function() {
  /// Retry this future with exponential backoff
  Future<T> withRetry({
    RetryConfig config = const RetryConfig(),
    String? operationName,
  }) {
    return RetryHelper.retry(
      this,
      config: config,
      operationName: operationName,
    );
  }

  /// Retry this future with simple retry
  Future<T> withSimpleRetry({
    int maxRetries = 3,
    Duration delay = const Duration(milliseconds: 500),
  }) {
    return RetryHelper.retrySimple(
      this,
      maxRetries: maxRetries,
      delay: delay,
    );
  }
}
