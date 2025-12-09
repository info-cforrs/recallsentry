/// Test Helpers
///
/// Common utilities and setup functions for tests.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Creates a mock HTTP response with the given status code and body
http.Response createMockResponse(
  int statusCode,
  Map<String, dynamic> body,
) {
  return http.Response(
    json.encode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// Creates a mock HTTP response with a string body
http.Response createMockStringResponse(
  int statusCode,
  String body,
) {
  return http.Response(
    body,
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// Creates a mock HTTP response for empty body
http.Response createEmptyResponse(int statusCode) {
  return http.Response(
    '',
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

/// Timeout exception for testing
class TestTimeoutException implements Exception {
  final String message;
  TestTimeoutException(this.message);
  @override
  String toString() => 'TestTimeoutException: $message';
}

/// Test constants
class TestConstants {
  static const Duration defaultTimeout = Duration(seconds: 5);
  static const String testBaseUrl = 'https://api.test.com';
}

/// Matcher for URI containing a path
Matcher uriContaining(String path) {
  return predicate<Uri>(
    (uri) => uri.toString().contains(path),
    'URI containing "$path"',
  );
}

/// Matcher for Map containing a key
Matcher mapContainingKey(String key) {
  return predicate<Map<String, dynamic>>(
    (map) => map.containsKey(key),
    'Map containing key "$key"',
  );
}
