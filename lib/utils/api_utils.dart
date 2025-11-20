/// Utility functions for API operations
///
/// Provides common functionality for parsing responses, extracting data,
/// and handling common API patterns across all services.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/api_exceptions.dart';

/// Extracts a list of results from API response data
///
/// Handles both direct array responses and paginated responses
/// with a 'results' field. Returns empty list if data is null or invalid.
///
/// Example:
/// ```dart
/// final data = json.decode(response.body);
/// final list = ApiUtils.extractResultsList(data);
/// ```
class ApiUtils {
  ApiUtils._(); // Private constructor to prevent instantiation

  /// Extracts results list from various API response formats
  static List<dynamic> extractResultsList(dynamic responseData) {
    if (responseData == null) return [];

    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map) {
      // Try 'results' field (Django REST Framework pagination)
      if (responseData.containsKey('results')) {
        final results = responseData['results'];
        return results is List ? results : [];
      }

      // Try 'data' field (common API pattern)
      if (responseData.containsKey('data')) {
        final data = responseData['data'];
        if (data is List) return data;
        if (data is Map && data.containsKey('results')) {
          final results = data['results'];
          return results is List ? results : [];
        }
      }
    }

    return [];
  }

  /// Parses JSON response and extracts results list
  ///
  /// Combines JSON decoding and list extraction in one step.
  /// Throws [SerializationException] if JSON is invalid.
  static List<dynamic> parseJsonList(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      return extractResultsList(decoded);
    } on FormatException catch (e, stack) {
      throw SerializationException(
        'Failed to parse JSON response',
        dataType: 'JSON',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Parses JSON response and extracts a single map
  ///
  /// Throws [SerializationException] if JSON is invalid or not a Map.
  static Map<String, dynamic> parseJsonMap(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw SerializationException(
          'Expected JSON object, got ${decoded.runtimeType}',
          dataType: 'Map<String, dynamic>',
        );
      }
      return decoded;
    } on FormatException catch (e, stack) {
      throw SerializationException(
        'Failed to parse JSON response',
        dataType: 'JSON',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Checks HTTP response and throws appropriate exceptions
  ///
  /// Handles common HTTP status codes and throws typed exceptions.
  /// Returns the response if status is successful (200-299).
  ///
  /// Example:
  /// ```dart
  /// final response = await http.get(uri);
  /// ApiUtils.checkResponse(response); // Throws on error
  /// ```
  static http.Response checkResponse(
    http.Response response, {
    String? context,
  }) {
    final statusCode = response.statusCode;

    // Success range (200-299)
    if (statusCode >= 200 && statusCode < 300) {
      return response;
    }

    // Build error message
    String message = 'HTTP $statusCode';
    if (context != null) {
      message = '$context: $message';
    }

    // Try to extract error message from response body
    String? errorDetail;
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        errorDetail = body['detail'] ??
            body['error'] ??
            body['message'] ??
            body['non_field_errors']?.toString();
      }
    } catch (_) {
      // Ignore JSON parsing errors for error messages
    }

    if (errorDetail != null) {
      message = '$message - $errorDetail';
    }

    // Throw appropriate exception based on status code
    switch (statusCode) {
      case 400:
        // Try to extract field errors for validation
        Map<String, List<String>>? fieldErrors;
        try {
          final body = json.decode(response.body);
          if (body is Map) {
            fieldErrors = body.map((key, value) {
              if (value is List) {
                return MapEntry(
                    key, value.map((e) => e.toString()).toList());
              }
              return MapEntry(key, [value.toString()]);
            });
          }
        } catch (_) {
          // Ignore
        }

        throw ValidationException(
          message,
          statusCode: statusCode,
          fieldErrors: fieldErrors,
        );

      case 401:
        throw AuthException(
          message,
          statusCode: statusCode,
          shouldLogout: true,
        );

      case 403:
        // Could be tier limit or general permission issue
        throw AuthException(
          message,
          statusCode: statusCode,
          shouldLogout: false,
        );

      case 404:
        throw NotFoundException(
          message,
          originalException: response.body,
        );

      case 429:
        // Try to extract retry-after header
        DateTime? retryAfter;
        final retryAfterHeader = response.headers['retry-after'];
        if (retryAfterHeader != null) {
          final seconds = int.tryParse(retryAfterHeader);
          if (seconds != null) {
            retryAfter = DateTime.now().add(Duration(seconds: seconds));
          }
        }

        throw RateLimitException(
          message,
          statusCode: statusCode,
          retryAfter: retryAfter,
        );

      case >= 500:
        throw ServerException(
          message,
          statusCode: statusCode,
          originalException: response.body,
        );

      default:
        throw ApiException(
          message,
          statusCode: statusCode,
          originalException: response.body,
        );
    }
  }

  /// Extracts error message from response body
  ///
  /// Tries multiple common error field names and returns
  /// a user-friendly message or a default message.
  static String extractErrorMessage(
    String responseBody, {
    String defaultMessage = 'An error occurred',
  }) {
    try {
      final body = json.decode(responseBody);
      if (body is Map) {
        // Try common error field names
        final message = body['detail'] ??
            body['error'] ??
            body['message'] ??
            body['error_description'];

        if (message != null) {
          return message.toString();
        }

        // Try non_field_errors (Django REST Framework)
        final nonFieldErrors = body['non_field_errors'];
        if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
          return nonFieldErrors.first.toString();
        }
      }
    } catch (_) {
      // If parsing fails, return default
    }

    return defaultMessage;
  }

  /// Builds authorization header map
  ///
  /// Creates standard authorization headers with Bearer token.
  static Map<String, String> authHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Builds standard JSON headers without authorization
  static Map<String, String> jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Safely converts dynamic value to int
  ///
  /// Handles string numbers, doubles, and null values.
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely converts dynamic value to double
  ///
  /// Handles string numbers, ints, and null values.
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Safely converts dynamic value to bool
  ///
  /// Handles string booleans ('true', 'false', '1', '0'),
  /// integers (1 = true, 0 = false), and null values.
  static bool? toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  /// Safely gets string from dynamic value
  ///
  /// Returns null for null values, empty string for empty values,
  /// and string representation for all other values.
  static String? asString(dynamic value, {bool emptyAsNull = false}) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (emptyAsNull && str.isEmpty) return null;
    return str;
  }

  /// Validates that required fields are present in a map
  ///
  /// Throws [ValidationException] if any required field is missing.
  static void validateRequired(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    final missing = <String>[];

    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        missing.add(field);
      }
    }

    if (missing.isNotEmpty) {
      throw ValidationException(
        'Missing required fields: ${missing.join(", ")}',
        fieldErrors: {
          for (final field in missing) field: ['This field is required']
        },
      );
    }
  }
}
