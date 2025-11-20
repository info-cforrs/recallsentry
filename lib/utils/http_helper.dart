/// HTTP utility functions for authenticated API requests
///
/// Provides helpers for making authenticated requests with automatic
/// token refresh and retry logic.
library;

import 'package:http/http.dart' as http;
import '../exceptions/api_exceptions.dart';
import '../services/auth_service.dart';

/// Helper class for making authenticated HTTP requests with token refresh
///
/// Handles the common pattern of:
/// 1. Get access token
/// 2. Make request
/// 3. If 401, refresh token and retry
/// 4. Return response or throw exception
class HttpHelper {
  HttpHelper._(); // Private constructor to prevent instantiation

  /// Makes an authenticated HTTP request with automatic token refresh
  ///
  /// [client] - The HTTP client to use
  /// [makeRequest] - Function that makes the actual HTTP request with the token
  /// [authService] - Optional auth service (defaults to singleton)
  ///
  /// Returns the HTTP response.
  /// Throws [AuthException] if not authenticated or token refresh fails.
  ///
  /// Example:
  /// ```dart
  /// final response = await HttpHelper.withTokenRefresh(
  ///   _httpClient,
  ///   (token) => _httpClient.get(
  ///     Uri.parse('$baseUrl/user/'),
  ///     headers: ApiUtils.authHeaders(token),
  ///   ),
  /// );
  /// ```
  static Future<http.Response> withTokenRefresh(
    http.Client client,
    Future<http.Response> Function(String token) makeRequest, {
    AuthService? authService,
  }) async {
    final auth = authService ?? AuthService();

    // Get access token
    String? token = await auth.getAccessToken();
    if (token == null) {
      throw AuthException(
        'Not authenticated',
        shouldLogout: true,
      );
    }

    // Make initial request
    var response = await makeRequest(token);

    // If 401, try to refresh token and retry once
    if (response.statusCode == 401) {
      token = await auth.refreshAccessToken();

      if (token == null) {
        throw AuthException(
          'Token refresh failed',
          statusCode: 401,
          shouldLogout: true,
        );
      }

      // Retry request with new token
      response = await makeRequest(token);
    }

    return response;
  }

  /// Makes an authenticated HTTP request and parses the response
  ///
  /// Combines token refresh and response parsing with error handling.
  /// Returns the parsed data of type [T] or null on error.
  ///
  /// [client] - The HTTP client to use
  /// [makeRequest] - Function that makes the actual HTTP request with the token
  /// [parseResponse] - Function to parse the successful response
  /// [authService] - Optional auth service (defaults to singleton)
  ///
  /// Returns parsed data of type [T] or null if request fails.
  ///
  /// Example:
  /// ```dart
  /// final user = await HttpHelper.withTokenRefreshAndParse<UserProfile>(
  ///   _httpClient,
  ///   (token) => _httpClient.get(
  ///     Uri.parse('$baseUrl/user/'),
  ///     headers: ApiUtils.authHeaders(token),
  ///   ),
  ///   (response) => UserProfile.fromJson(json.decode(response.body)),
  /// );
  /// ```
  static Future<T?> withTokenRefreshAndParse<T>(
    http.Client client,
    Future<http.Response> Function(String token) makeRequest,
    T Function(http.Response response) parseResponse, {
    AuthService? authService,
  }) async {
    try {
      final response = await withTokenRefresh(
        client,
        makeRequest,
        authService: authService,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return parseResponse(response);
      }

      // Handle non-200/201 responses
      return null;
    } on AuthException {
      // Re-throw auth exceptions
      rethrow;
    } catch (e) {
      // Return null for other errors
      return null;
    }
  }

  /// Makes an authenticated request and returns success/failure
  ///
  /// Returns true if request succeeds (200-299), false otherwise.
  /// Useful for delete/update operations where you just need success status.
  ///
  /// Example:
  /// ```dart
  /// final success = await HttpHelper.withTokenRefreshBool(
  ///   _httpClient,
  ///   (token) => _httpClient.delete(
  ///     Uri.parse('$baseUrl/item/$id/'),
  ///     headers: ApiUtils.authHeaders(token),
  ///   ),
  /// );
  /// ```
  static Future<bool> withTokenRefreshBool(
    http.Client client,
    Future<http.Response> Function(String token) makeRequest, {
    AuthService? authService,
  }) async {
    try {
      final response = await withTokenRefresh(
        client,
        makeRequest,
        authService: authService,
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }

  /// Makes a request without authentication
  ///
  /// Simply wraps the request for consistency, useful for public endpoints.
  /// Throws appropriate exceptions based on response status.
  ///
  /// Example:
  /// ```dart
  /// final response = await HttpHelper.makeRequest(
  ///   () => http.get(Uri.parse('$baseUrl/public/recalls/')),
  /// );
  /// ```
  static Future<http.Response> makeRequest(
    Future<http.Response> Function() makeRequest,
  ) async {
    return await makeRequest();
  }

  /// Makes a request and handles common errors
  ///
  /// Wraps request execution and converts HTTP errors to typed exceptions.
  /// Useful for requests where you want automatic error handling.
  ///
  /// Example:
  /// ```dart
  /// final response = await HttpHelper.makeRequestWithErrorHandling(
  ///   () => http.get(Uri.parse(url)),
  ///   context: 'Fetching recalls',
  /// );
  /// ```
  static Future<http.Response> makeRequestWithErrorHandling(
    Future<http.Response> Function() makeRequest, {
    String? context,
  }) async {
    try {
      final response = await makeRequest();

      // Check for error status codes
      if (response.statusCode >= 400) {
        _throwForStatusCode(response, context);
      }

      return response;
    } on http.ClientException catch (e, stack) {
      throw NetworkException(
        context != null
            ? '$context: ${e.message}'
            : 'Network error: ${e.message}',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Throws appropriate exception based on status code
  static void _throwForStatusCode(http.Response response, String? context) {
    final statusCode = response.statusCode;
    String message = 'HTTP $statusCode';
    if (context != null) {
      message = '$context: $message';
    }

    switch (statusCode) {
      case 401:
        throw AuthException(
          message,
          statusCode: statusCode,
          shouldLogout: true,
        );
      case 403:
        throw AuthException(
          message,
          statusCode: statusCode,
          shouldLogout: false,
        );
      case 404:
        throw NotFoundException(message);
      case 429:
        throw RateLimitException(message, statusCode: statusCode);
      case >= 500:
        throw ServerException(message, statusCode: statusCode);
      default:
        throw ApiException(message, statusCode: statusCode);
    }
  }
}
