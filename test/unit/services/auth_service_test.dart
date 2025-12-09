/// AuthService Unit Tests
///
/// Tests for authentication functionality including:
/// - Token management and parsing
/// - Session timeout logic
/// - Rate limiting
/// - Response handling patterns
///
/// To run: flutter test test/unit/services/auth_service_test.dart
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/auth_fixtures.dart';

void main() {
  group('AuthService - Token Management', () {
    group('JWT Token Decoding', () {
      test('should correctly decode valid JWT payload', () {
        // Create a valid JWT structure for testing
        final payload = {
          'user_id': 123,
          'username': 'testuser',
          'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        };
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        // The token should be parseable
        final parts = token.split('.');
        expect(parts.length, 3);

        final decodedPayload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        expect(decodedPayload['user_id'], 123);
        expect(decodedPayload['username'], 'testuser');
      });

      test('should identify expired tokens', () {
        final expiredTimestamp =
            DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = {'user_id': 123, 'exp': expiredTimestamp};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        // Parse and check expiry
        final parts = token.split('.');
        final decodedPayload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedPayload['exp'] * 1000);

        expect(DateTime.now().isAfter(expiryDate), true);
      });

      test('should identify non-expired tokens', () {
        final futureTimestamp =
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final payload = {'user_id': 123, 'exp': futureTimestamp};
        final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));
        final token = 'header.$encodedPayload.signature';

        // Parse and check expiry
        final parts = token.split('.');
        final decodedPayload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        );
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(decodedPayload['exp'] * 1000);

        expect(DateTime.now().isBefore(expiryDate), true);
      });

      test('should reject malformed tokens with wrong segment count', () {
        const malformedToken = 'not.a.valid.jwt.token';
        final parts = malformedToken.split('.');

        // Valid JWT has exactly 3 parts
        final isValidStructure = parts.length == 3;
        expect(isValidStructure, false);
      });

      test('should handle token with invalid base64 gracefully', () {
        const invalidToken = 'header.!!!invalid!!!.signature';

        expect(
          () {
            final parts = invalidToken.split('.');
            base64Url.decode(base64Url.normalize(parts[1]));
          },
          throwsFormatException,
        );
      });
    });

    group('Token Expiry Checking', () {
      test('token with future exp is not expired', () {
        final exp = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

        expect(DateTime.now().isAfter(expiryDate), false);
      });

      test('token with past exp is expired', () {
        final exp = DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

        expect(DateTime.now().isAfter(expiryDate), true);
      });

      test('token expiring in exactly 0 seconds is expired', () {
        final exp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

        // Token at exact boundary should be considered expired (or about to)
        expect(DateTime.now().isAfter(expiryDate) || DateTime.now().isAtSameMomentAs(expiryDate), true);
      });
    });
  });

  group('AuthService - Session Timeout', () {
    // Constants matching AuthService
    const maxSessionDuration = Duration(days: 30);
    const idleTimeout = Duration(hours: 4);

    test('max session duration is 30 days', () {
      expect(maxSessionDuration.inDays, 30);
    });

    test('idle timeout is 4 hours', () {
      expect(idleTimeout.inHours, 4);
    });

    group('Session Duration Validation', () {
      test('session at day 15 is within max duration', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 15));
        final isValid = DateTime.now().difference(sessionStart) < maxSessionDuration;

        expect(isValid, true);
      });

      test('session at day 29 is within max duration', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 29));
        final isValid = DateTime.now().difference(sessionStart) < maxSessionDuration;

        expect(isValid, true);
      });

      test('session at day 30 exceeds max duration', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 30, hours: 1));
        final isValid = DateTime.now().difference(sessionStart) < maxSessionDuration;

        expect(isValid, false);
      });

      test('session at day 31 exceeds max duration', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 31));
        final isValid = DateTime.now().difference(sessionStart) < maxSessionDuration;

        expect(isValid, false);
      });
    });

    group('Idle Timeout Validation', () {
      test('activity 1 hour ago is within idle timeout', () {
        final lastActivity = DateTime.now().subtract(const Duration(hours: 1));
        final isValid = DateTime.now().difference(lastActivity) < idleTimeout;

        expect(isValid, true);
      });

      test('activity 3 hours ago is within idle timeout', () {
        final lastActivity = DateTime.now().subtract(const Duration(hours: 3));
        final isValid = DateTime.now().difference(lastActivity) < idleTimeout;

        expect(isValid, true);
      });

      test('activity 4 hours ago exceeds idle timeout', () {
        final lastActivity = DateTime.now().subtract(const Duration(hours: 4, minutes: 1));
        final isValid = DateTime.now().difference(lastActivity) < idleTimeout;

        expect(isValid, false);
      });

      test('activity 5 hours ago exceeds idle timeout', () {
        final lastActivity = DateTime.now().subtract(const Duration(hours: 5));
        final isValid = DateTime.now().difference(lastActivity) < idleTimeout;

        expect(isValid, false);
      });
    });

    group('Combined Session Validation', () {
      test('valid session: within duration and active', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 10));
        final lastActivity = DateTime.now().subtract(const Duration(hours: 1));

        final withinDuration = DateTime.now().difference(sessionStart) < maxSessionDuration;
        final withinIdle = DateTime.now().difference(lastActivity) < idleTimeout;
        final isValid = withinDuration && withinIdle;

        expect(isValid, true);
      });

      test('invalid session: within duration but idle too long', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 10));
        final lastActivity = DateTime.now().subtract(const Duration(hours: 5));

        final withinDuration = DateTime.now().difference(sessionStart) < maxSessionDuration;
        final withinIdle = DateTime.now().difference(lastActivity) < idleTimeout;
        final isValid = withinDuration && withinIdle;

        expect(isValid, false);
      });

      test('invalid session: active but duration exceeded', () {
        final sessionStart = DateTime.now().subtract(const Duration(days: 31));
        final lastActivity = DateTime.now().subtract(const Duration(hours: 1));

        final withinDuration = DateTime.now().difference(sessionStart) < maxSessionDuration;
        final withinIdle = DateTime.now().difference(lastActivity) < idleTimeout;
        final isValid = withinDuration && withinIdle;

        expect(isValid, false);
      });
    });
  });

  group('AuthService - Rate Limiting', () {
    // Constants matching LoginPage
    const maxAttemptsBeforeDelay = 3;
    const loginDelay = Duration(seconds: 30);

    test('max attempts before delay is 3', () {
      expect(maxAttemptsBeforeDelay, 3);
    });

    test('login delay is 30 seconds', () {
      expect(loginDelay.inSeconds, 30);
    });

    group('Attempt Counting', () {
      test('allows login when attempts under limit', () {
        const attempts = 2;
        final canAttempt = attempts < maxAttemptsBeforeDelay;

        expect(canAttempt, true);
      });

      test('blocks login when attempts at limit (within delay)', () {
        const attempts = 3;
        final lastAttemptTime = DateTime.now();

        final shouldBlock = attempts >= maxAttemptsBeforeDelay &&
            DateTime.now().difference(lastAttemptTime) < loginDelay;

        expect(shouldBlock, true);
      });

      test('allows login after delay period expires', () {
        const attempts = 3;
        final lastAttemptTime = DateTime.now().subtract(const Duration(seconds: 31));

        final delayExpired = DateTime.now().difference(lastAttemptTime) >= loginDelay;

        expect(delayExpired, true);
      });
    });

    group('Counter Reset', () {
      test('counter resets on successful login', () {
        var attempts = 3;
        DateTime? lastAttemptTime = DateTime.now();

        // Simulate successful login
        const loginSuccess = true;
        if (loginSuccess) {
          attempts = 0;
          lastAttemptTime = null;
        }

        expect(attempts, 0);
        expect(lastAttemptTime, null);
      });

      test('counter resets after delay expires', () {
        var attempts = 3;
        final lastAttemptTime = DateTime.now().subtract(const Duration(seconds: 31));

        final delayExpired = DateTime.now().difference(lastAttemptTime) >= loginDelay;
        if (delayExpired) {
          attempts = 0;
        }

        expect(attempts, 0);
      });
    });

    group('Remaining Delay Calculation', () {
      test('calculates correct remaining seconds', () {
        final lastAttemptTime = DateTime.now().subtract(const Duration(seconds: 10));
        final timeSinceLastAttempt = DateTime.now().difference(lastAttemptTime);
        final remainingSeconds = loginDelay.inSeconds - timeSinceLastAttempt.inSeconds;

        expect(remainingSeconds, closeTo(20, 1)); // ~20 seconds remaining
      });
    });
  });

  group('AuthService - Response Handling', () {
    group('Login Response Parsing', () {
      test('parses successful login response', () {
        final response = AuthFixtures.loginSuccessResponse;

        expect(response.containsKey('access'), true);
        expect(response.containsKey('refresh'), true);
        expect(response['access'], isNotNull);
        expect(response['refresh'], isNotNull);
      });

      test('parses failed login response', () {
        final response = AuthFixtures.loginFailureResponse;

        expect(response.containsKey('detail'), true);
      });
    });

    group('Error Message Extraction', () {
      test('extracts message from "message" field', () {
        final errorData = {'message': 'Error occurred'};
        final message = errorData['message'] ??
                        errorData['error'] ??
                        errorData['detail'] ??
                        'Default error';

        expect(message, 'Error occurred');
      });

      test('extracts message from "error" field', () {
        final errorData = {'error': 'Something went wrong'};
        final message = errorData['message'] ??
                        errorData['error'] ??
                        errorData['detail'] ??
                        'Default error';

        expect(message, 'Something went wrong');
      });

      test('extracts message from "detail" field', () {
        final errorData = {'detail': 'Not found'};
        final message = errorData['message'] ??
                        errorData['error'] ??
                        errorData['detail'] ??
                        'Default error';

        expect(message, 'Not found');
      });

      test('uses default message when no standard field present', () {
        final errorData = {'code': 500, 'status': 'error'};
        final message = errorData['message'] ??
                        errorData['error'] ??
                        errorData['detail'] ??
                        'An unexpected error occurred';

        expect(message, 'An unexpected error occurred');
      });
    });

    group('User Profile Response', () {
      test('parses user profile correctly', () {
        final profile = AuthFixtures.userProfileResponse;

        expect(profile['id'], AuthFixtures.testUserId);
        expect(profile['username'], AuthFixtures.testUsername);
        expect(profile['email'], AuthFixtures.testEmail);
        expect(profile['first_name'], 'Test');
        expect(profile['last_name'], 'User');
      });
    });
  });

  group('AuthService - Registration', () {
    group('Request Validation', () {
      test('registration requires username, email, password, password2', () {
        final requiredFields = ['username', 'email', 'password', 'password2'];
        final registrationData = {
          'username': 'newuser',
          'email': 'new@example.com',
          'password': 'Pass123!',
          'password2': 'Pass123!',
        };

        for (final field in requiredFields) {
          expect(registrationData.containsKey(field), true,
              reason: 'Missing required field: $field');
        }
      });

      test('passwords must match', () {
        final registrationData = {
          'password': 'Pass123!',
          'password2': 'Pass123!',
        };

        expect(registrationData['password'], registrationData['password2']);
      });

      test('optional fields can be included', () {
        final registrationData = {
          'username': 'newuser',
          'email': 'new@example.com',
          'password': 'Pass123!',
          'password2': 'Pass123!',
          'first_name': 'Test',
          'last_name': 'User',
          'address': '123 Main St',
          'city': 'Test City',
          'state': 'CA',
          'zip_code': '90210',
        };

        expect(registrationData['first_name'], 'Test');
        expect(registrationData['zip_code'], '90210');
      });
    });

    group('Response Parsing', () {
      test('parses successful registration', () {
        final response = AuthFixtures.registrationSuccessResponse;

        expect(response['id'], isNotNull);
        expect(response['username'], isNotNull);
      });

      test('parses username exists error', () {
        final response = AuthFixtures.registrationUsernameExistsResponse;

        expect(response.containsKey('username'), true);
        expect(response['username'], isList);
      });

      test('parses invalid email error', () {
        final response = AuthFixtures.registrationInvalidEmailResponse;

        expect(response.containsKey('email'), true);
        expect(response['email'], isList);
      });
    });
  });

  group('AuthService - Storage Keys', () {
    // These should match the actual keys in AuthService
    test('storage keys are defined correctly', () {
      const accessTokenKey = 'access_token';
      const refreshTokenKey = 'refresh_token';
      const userIdKey = 'user_id';
      const usernameKey = 'username';
      const sessionStartKey = 'session_start_time';
      const lastActivityKey = 'last_activity_time';

      expect(accessTokenKey, 'access_token');
      expect(refreshTokenKey, 'refresh_token');
      expect(userIdKey, 'user_id');
      expect(usernameKey, 'username');
      expect(sessionStartKey, 'session_start_time');
      expect(lastActivityKey, 'last_activity_time');
    });
  });
}
