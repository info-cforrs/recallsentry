/// Auth Test Fixtures
///
/// Sample data for authentication-related tests.
library;

import 'dart:convert';

/// Sample JWT tokens for testing
class AuthFixtures {
  /// Valid access token (expires in 1 hour from a fixed point)
  /// Payload: {"user_id": 123, "username": "testuser", "exp": future_timestamp}
  static String get validAccessToken {
    final now = DateTime.now();
    final exp = now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final payload = base64Url.encode(utf8.encode(
      '{"user_id": 123, "username": "testuser", "exp": $exp}',
    ));
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.$payload.signature';
  }

  /// Expired access token
  static String get expiredAccessToken {
    final exp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
    final payload = base64Url.encode(utf8.encode(
      '{"user_id": 123, "username": "testuser", "exp": $exp}',
    ));
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.$payload.signature';
  }

  /// Valid refresh token (JWT format for consistency)
  static String get validRefreshToken {
    final exp = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    final payload = base64Url.encode(utf8.encode(
      '{"user_id": 123, "token_type": "refresh", "exp": $exp}',
    ));
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.$payload.refresh_signature';
  }

  /// Invalid/malformed token
  static const String malformedToken = 'not.a.valid.jwt';

  /// Test user credentials
  static const String testUsername = 'testuser';
  static const String testPassword = 'TestPassword123!';
  static const String testEmail = 'test@example.com';
  static const int testUserId = 123;

  /// Login success response
  static Map<String, dynamic> get loginSuccessResponse => {
        'access': validAccessToken,
        'refresh': validRefreshToken,
      };

  /// Login failure response (invalid credentials)
  static Map<String, dynamic> get loginFailureResponse => {
        'detail': 'No active account found with the given credentials',
      };

  /// Token refresh success response
  static Map<String, dynamic> get tokenRefreshSuccessResponse => {
        'access': validAccessToken,
      };

  /// User profile response
  static Map<String, dynamic> get userProfileResponse => {
        'id': testUserId,
        'username': testUsername,
        'email': testEmail,
        'first_name': 'Test',
        'last_name': 'User',
        'address': '123 Test St',
        'city': 'Test City',
        'state': 'CA',
        'zip_code': '90210',
        'date_joined': '2024-01-01T00:00:00Z',
      };

  /// Registration success response
  static Map<String, dynamic> get registrationSuccessResponse => {
        'id': testUserId,
        'username': testUsername,
        'email': testEmail,
        'message': 'User registered successfully',
      };

  /// Registration failure response (username exists)
  static Map<String, dynamic> get registrationUsernameExistsResponse => {
        'username': ['A user with that username already exists.'],
      };

  /// Registration failure response (invalid email)
  static Map<String, dynamic> get registrationInvalidEmailResponse => {
        'email': ['Enter a valid email address.'],
      };

  /// Account deletion success response
  static Map<String, dynamic> get accountDeletionSuccessResponse => {
        'message': 'Account deleted successfully',
      };
}
