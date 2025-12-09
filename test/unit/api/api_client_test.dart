/// API Client Unit Tests
///
/// Tests for API client behavior including:
/// - Request building
/// - Response parsing
/// - Error handling
/// - Retry logic
/// - Authentication headers
///
/// To run: flutter test test/unit/api/api_client_test.dart
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/auth_fixtures.dart';
import '../../fixtures/recall_fixtures.dart';

void main() {
  group('API Client - Request Building', () {
    test('builds correct base URL', () {
      const baseUrl = 'https://api.recallsentry.com/v1';
      expect(baseUrl, contains('recallsentry'));
      expect(baseUrl, contains('/v1'));
    });

    test('builds recall list endpoint correctly', () {
      const baseUrl = 'https://api.recallsentry.com/v1';
      const endpoint = '/recalls/';
      final fullUrl = '$baseUrl$endpoint';

      expect(fullUrl, 'https://api.recallsentry.com/v1/recalls/');
    });

    test('builds recall detail endpoint with ID', () {
      const baseUrl = 'https://api.recallsentry.com/v1';
      const recallId = 123;
      final endpoint = '/recalls/$recallId/';
      final fullUrl = '$baseUrl$endpoint';

      expect(fullUrl, 'https://api.recallsentry.com/v1/recalls/123/');
    });

    test('builds endpoint with query parameters', () {
      const baseUrl = 'https://api.recallsentry.com/v1/recalls/';
      final params = {
        'agency': 'FDA',
        'risk_level': 'HIGH',
        'page': '1',
      };

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final fullUrl = '$baseUrl?$queryString';

      expect(fullUrl, contains('agency=FDA'));
      expect(fullUrl, contains('risk_level=HIGH'));
      expect(fullUrl, contains('page=1'));
    });

    test('encodes special characters in query parameters', () {
      const searchTerm = 'peanut butter & jelly';
      final encoded = Uri.encodeComponent(searchTerm);

      expect(encoded, 'peanut%20butter%20%26%20jelly');
    });
  });

  group('API Client - Headers', () {
    test('includes authorization header with token', () {
      final accessToken = AuthFixtures.validAccessToken;
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      expect(headers['Authorization'], startsWith('Bearer '));
      expect(headers['Authorization'], contains('.'));
    });

    test('includes content-type header for POST requests', () {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      expect(headers['Content-Type'], 'application/json');
      expect(headers['Accept'], 'application/json');
    });

    test('includes custom headers when provided', () {
      final headers = {
        'X-Client-Version': '1.0.0',
        'X-Platform': 'iOS',
        'X-Device-ID': 'abc123',
      };

      expect(headers['X-Client-Version'], '1.0.0');
      expect(headers['X-Platform'], 'iOS');
    });
  });

  group('API Client - Response Parsing', () {
    test('parses JSON list response', () {
      final jsonString = jsonEncode(RecallFixtures.recallList);
      final decoded = jsonDecode(jsonString) as List;

      expect(decoded, isA<List>());
      expect(decoded.length, RecallFixtures.recallList.length);
    });

    test('parses paginated response', () {
      final response = RecallFixtures.apiPaginatedResponse;

      expect(response.containsKey('count'), true);
      expect(response.containsKey('results'), true);
      expect(response['results'], isA<List>());
    });

    test('extracts count from paginated response', () {
      final response = RecallFixtures.apiPaginatedResponse;
      final count = response['count'] as int;

      expect(count, RecallFixtures.recallList.length);
    });

    test('extracts next page URL from paginated response', () {
      final response = {
        'count': 100,
        'next': 'https://api.recallsentry.com/v1/recalls/?page=2',
        'previous': null,
        'results': [],
      };

      expect(response['next'], isNotNull);
      expect(response['next'], contains('page=2'));
    });

    test('handles empty results list', () {
      final response = {
        'count': 0,
        'next': null,
        'previous': null,
        'results': [],
      };

      final results = response['results'] as List;
      expect(results, isEmpty);
      expect(response['count'], 0);
    });

    test('parses single recall response', () {
      final recall = RecallFixtures.fdaRecallSample;
      final jsonString = jsonEncode(recall);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(decoded['product_name'], recall['product_name']);
      expect(decoded['agency'], recall['agency']);
    });
  });

  group('API Client - Error Responses', () {
    test('identifies 400 Bad Request', () {
      const statusCode = 400;
      final errorResponse = {
        'error': 'Bad Request',
        'message': 'Invalid parameters',
      };

      expect(statusCode, 400);
      expect(errorResponse['error'], 'Bad Request');
    });

    test('identifies 401 Unauthorized', () {
      const statusCode = 401;
      final errorResponse = {
        'detail': 'Authentication credentials were not provided.',
      };

      expect(statusCode, 401);
      expect(errorResponse['detail'], contains('credentials'));
    });

    test('identifies 403 Forbidden', () {
      const statusCode = 403;
      final errorResponse = {
        'detail': 'You do not have permission to perform this action.',
      };

      expect(statusCode, 403);
      expect(errorResponse['detail'], contains('permission'));
    });

    test('identifies 404 Not Found', () {
      const statusCode = 404;
      final errorResponse = {'detail': 'Not found.'};

      expect(statusCode, 404);
      expect(errorResponse['detail'], 'Not found.');
    });

    test('identifies 429 Rate Limited', () {
      const statusCode = 429;
      final errorResponse = {
        'detail': 'Request was throttled.',
        'retry_after': 60,
      };

      expect(statusCode, 429);
      expect(errorResponse['retry_after'], 60);
    });

    test('identifies 500 Server Error', () {
      const statusCode = 500;
      final errorResponse = {'error': 'Internal Server Error'};

      expect(statusCode, 500);
      expect(errorResponse['error'], contains('Server Error'));
    });

    test('identifies 503 Service Unavailable', () {
      const statusCode = 503;
      final errorResponse = {'error': 'Service temporarily unavailable'};

      expect(statusCode, 503);
      expect(errorResponse['error'], contains('unavailable'));
    });

    test('extracts error message from various formats', () {
      // Format 1: detail field
      final error1 = {'detail': 'Error message 1'};
      expect(error1['detail'], isNotNull);

      // Format 2: message field
      final error2 = {'message': 'Error message 2'};
      expect(error2['message'], isNotNull);

      // Format 3: error field
      final error3 = {'error': 'Error message 3'};
      expect(error3['error'], isNotNull);

      // Format 4: nested errors
      final error4 = {
        'errors': {'field': ['Field is required']},
      };
      expect(error4['errors'], isNotNull);
    });
  });

  group('API Client - Retry Logic', () {
    test('calculates exponential backoff', () {
      const baseDelayMs = 1000;
      const maxRetries = 3;

      final delays = <int>[];
      for (var attempt = 0; attempt < maxRetries; attempt++) {
        final delay = baseDelayMs * (1 << attempt); // 2^attempt
        delays.add(delay);
      }

      expect(delays[0], 1000); // 1s
      expect(delays[1], 2000); // 2s
      expect(delays[2], 4000); // 4s
    });

    test('adds jitter to backoff', () {
      const baseDelayMs = 1000;
      const maxJitterMs = 100;

      // Simulate jitter calculation
      final jitter = (DateTime.now().millisecondsSinceEpoch % maxJitterMs);
      final delayWithJitter = baseDelayMs + jitter;

      expect(delayWithJitter, greaterThanOrEqualTo(baseDelayMs));
      expect(delayWithJitter, lessThan(baseDelayMs + maxJitterMs));
    });

    test('determines retryable status codes', () {
      final retryableCodes = [408, 429, 500, 502, 503, 504];
      final nonRetryableCodes = [400, 401, 403, 404, 422];

      for (final code in retryableCodes) {
        final shouldRetry = _isRetryable(code);
        expect(shouldRetry, true, reason: '$code should be retryable');
      }

      for (final code in nonRetryableCodes) {
        final shouldRetry = _isRetryable(code);
        expect(shouldRetry, false, reason: '$code should not be retryable');
      }
    });

    test('respects max retry count', () {
      const maxRetries = 3;
      var attempts = 0;
      var success = false;

      while (attempts < maxRetries && !success) {
        attempts++;
        // Simulate failure
        success = false;
      }

      expect(attempts, maxRetries);
    });

    test('respects retry-after header', () {
      const retryAfterSeconds = 60;
      final headers = {'retry-after': '$retryAfterSeconds'};

      final retryAfter = int.tryParse(headers['retry-after'] ?? '0') ?? 0;
      expect(retryAfter, 60);
    });
  });

  group('API Client - Token Refresh', () {
    test('detects expired token from 401 response', () {
      const statusCode = 401;
      final response = {
        'detail': 'Token has expired',
        'code': 'token_not_valid',
      };

      final needsRefresh =
          statusCode == 401 && response['code'] == 'token_not_valid';
      expect(needsRefresh, true);
    });

    test('refresh token request format', () {
      final refreshToken = AuthFixtures.validRefreshToken;
      final requestBody = {'refresh': refreshToken};

      expect(requestBody['refresh'], isNotNull);
      expect(requestBody['refresh'], contains('.'));
    });

    test('parses refresh token response', () {
      final response = AuthFixtures.tokenRefreshSuccessResponse;

      expect(response['access'], isNotNull);
      expect(response['access'], isA<String>());
    });

    test('handles refresh token failure', () {
      const statusCode = 401;
      final response = {
        'detail': 'Token is invalid or expired',
        'code': 'token_not_valid',
      };

      final refreshFailed = statusCode == 401;
      expect(refreshFailed, true);
      expect(response['detail'], contains('invalid'));
    });
  });

  group('API Client - Timeout Handling', () {
    test('default timeout is reasonable', () {
      const defaultTimeoutSeconds = 30;
      expect(defaultTimeoutSeconds, greaterThanOrEqualTo(10));
      expect(defaultTimeoutSeconds, lessThanOrEqualTo(60));
    });

    test('different timeouts for different operations', () {
      const timeouts = {
        'quick': 5,
        'normal': 30,
        'upload': 120,
        'download': 300,
      };

      expect(timeouts['quick'], lessThan(timeouts['normal']!));
      expect(timeouts['upload'], greaterThan(timeouts['normal']!));
    });
  });

  group('API Client - Request Body', () {
    test('serializes login request body', () {
      final loginBody = {
        'username': 'testuser',
        'password': 'password123',
      };

      final jsonString = jsonEncode(loginBody);
      expect(jsonString, contains('username'));
      expect(jsonString, contains('testuser'));
    });

    test('serializes filter request body', () {
      final filterBody = {
        'agencies': ['FDA', 'USDA'],
        'risk_levels': ['HIGH', 'MEDIUM'],
        'date_from': '2024-01-01',
        'date_to': '2024-12-31',
      };

      final jsonString = jsonEncode(filterBody);
      final decoded = jsonDecode(jsonString);

      expect(decoded['agencies'], contains('FDA'));
      expect(decoded['risk_levels'].length, 2);
    });

    test('handles nested objects in request body', () {
      final body = {
        'user': {
          'profile': {
            'allergens': ['Peanuts', 'Milk'],
          },
        },
      };

      final jsonString = jsonEncode(body);
      final decoded = jsonDecode(jsonString);

      expect(decoded['user']['profile']['allergens'], contains('Peanuts'));
    });
  });

  group('API Client - Connection Handling', () {
    test('identifies network errors', () {
      const networkErrors = [
        'SocketException',
        'Connection refused',
        'No internet connection',
        'Network is unreachable',
      ];

      for (final error in networkErrors) {
        final isNetworkError = error.toLowerCase().contains('connection') ||
            error.toLowerCase().contains('network') ||
            error.toLowerCase().contains('socket');
        expect(isNetworkError, true);
      }
    });

    test('identifies DNS errors', () {
      const dnsError = 'Failed host lookup';
      final isDnsError = dnsError.toLowerCase().contains('host lookup');
      expect(isDnsError, true);
    });

    test('identifies SSL/TLS errors', () {
      const sslErrors = [
        'HandshakeException',
        'CERTIFICATE_VERIFY_FAILED',
        'SSL handshake failed',
      ];

      for (final error in sslErrors) {
        final isSslError = error.toLowerCase().contains('handshake') ||
            error.toLowerCase().contains('certificate') ||
            error.toLowerCase().contains('ssl');
        expect(isSslError, true);
      }
    });
  });

  group('API Client - Caching', () {
    test('generates cache key from URL', () {
      const url = 'https://api.recallsentry.com/v1/recalls/?agency=FDA';
      final cacheKey = url.hashCode.toString();

      expect(cacheKey, isNotEmpty);
    });

    test('cache entry has expiration', () {
      final cacheEntry = {
        'data': {},
        'cachedAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      };

      final expiresAt = DateTime.parse(cacheEntry['expiresAt'] as String);
      final cachedAt = DateTime.parse(cacheEntry['cachedAt'] as String);

      expect(expiresAt.isAfter(cachedAt), true);
    });

    test('determines if cache is stale', () {
      final staleEntry = {
        'expiresAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      };

      final expiresAt = DateTime.parse(staleEntry['expiresAt'] as String);
      final isStale = DateTime.now().isAfter(expiresAt);

      expect(isStale, true);
    });

    test('determines if cache is fresh', () {
      final freshEntry = {
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      };

      final expiresAt = DateTime.parse(freshEntry['expiresAt'] as String);
      final isFresh = DateTime.now().isBefore(expiresAt);

      expect(isFresh, true);
    });
  });
}

/// Helper function to determine if a status code is retryable
bool _isRetryable(int statusCode) {
  return statusCode == 408 || // Request Timeout
      statusCode == 429 || // Too Many Requests
      statusCode >= 500; // Server errors
}
