import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'subscription_service.dart';
import 'fcm_service.dart';
import 'security_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.apiBaseUrl;
  final http.Client _httpClient = SecurityService().createSecureHttpClient();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _sessionStartKey = 'session_start_time';
  static const String _lastActivityKey = 'last_activity_time';

  // Session timeout configuration
  static const Duration _maxSessionDuration = Duration(days: 30);
  static const Duration _idleTimeout = Duration(hours: 4);

  /// Register a new user
  /// SECURITY: Uses certificate pinning
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? address,
    String? city,
    String? state,
    String? zipCode,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (address != null && address.isNotEmpty) 'address': address,
        if (city != null && city.isNotEmpty) 'city': city,
        if (state != null && state.isNotEmpty) 'state': state,
        if (zipCode != null && zipCode.isNotEmpty) 'zip_code': zipCode,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      // SECURITY: Don't expose full response body in exceptions (may contain sensitive data)
      final errorData = json.decode(response.body);
      final message = errorData['message'] ??
                      errorData['error'] ??
                      errorData['detail'] ??
                      'Registration failed. Please check your information and try again.';
      throw Exception(message);
    }
  }

  /// Login and store tokens
  /// SECURITY: Uses certificate pinning
  Future<bool> login(String username, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: _accessTokenKey, value: data['access']);
      await _storage.write(key: _refreshTokenKey, value: data['refresh']);
      await _storage.write(key: _usernameKey, value: username);

      // Decode JWT to get user_id
      final payload = _decodeToken(data['access']);
      await _storage.write(key: _userIdKey, value: payload['user_id'].toString());

      // SECURITY: Initialize session timestamps for timeout tracking
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _sessionStartKey, value: now);
      await _storage.write(key: _lastActivityKey, value: now);

      // Clear subscription cache to force refresh after login
      SubscriptionService().clearCache();

      // Register FCM token with backend after successful login
      final fcmToken = FCMService().token;
      if (fcmToken != null) {
        await FCMService().registerToken(fcmToken);
      }

      return true;
    }
    return false;
  }

  /// Logout and clear all user data
  /// SECURITY: Uses certificate pinning
  Future<void> logout() async {
    // 1. Invalidate tokens on backend FIRST (prevents token reuse after logout)
    try {
      final token = await getAccessToken();
      final refreshToken = await getRefreshToken();
      if (token != null) {
        await _httpClient.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'refresh_token': refreshToken,
          }),
        );
      }
    } catch (e) {
      // Continue with local cleanup even if backend invalidation fails
      // This ensures user can still logout if network is unavailable
    }

    // 2. Unregister FCM token
    await FCMService().unregisterToken();

    // 3. Clear auth tokens from secure storage
    await _storage.deleteAll();

    // 4. Clear subscription cache
    SubscriptionService().clearCache();

    // Clear saved recalls from local storage
    // (We can't clear backend saved recalls since we just logged out)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_recalls');
    } catch (e) {
      // Silently fail - not critical
    }

    // Clear filter preferences from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('advanced_brand_filters');
      await prefs.remove('advanced_product_filters');
      await prefs.remove('has_active_filters');
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Delete user account permanently
  /// SECURITY: Uses certificate pinning
  /// COMPLIANCE: Required by App Store (1.4.12) and GDPR Article 17
  Future<bool> deleteAccount() async {
    try {
      // 1. Get current auth token
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      // 2. Call backend API to delete account
      final response = await _httpClient.delete(
        Uri.parse('$baseUrl/auth/delete-account/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 3. Account deleted successfully on backend, now clean up locally
        // Unregister FCM token
        await FCMService().unregisterToken();

        // Clear auth tokens from secure storage
        await _storage.deleteAll();

        // Clear subscription cache
        SubscriptionService().clearCache();

        // Clear saved recalls from local storage
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('saved_recalls');
        } catch (e) {
          // Silently fail - not critical
        }

        // Clear filter preferences from local storage
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('advanced_brand_filters');
          await prefs.remove('advanced_product_filters');
          await prefs.remove('has_active_filters');
        } catch (e) {
          // Silently fail - not critical
        }

        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      } else {
        final errorData = json.decode(response.body);
        final message = errorData['message'] ??
                        errorData['error'] ??
                        errorData['detail'] ??
                        'Failed to delete account. Please try again.';
        throw Exception(message);
      }
    } catch (e) {
      print('❌ Account deletion failed: $e');
      rethrow;
    }
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || _isTokenExpired(token)) {
      return false;
    }

    // SECURITY: Check session timeout (idle timeout + max session duration)
    final sessionValid = await _isSessionValid();
    if (!sessionValid) {
      // Session expired - logout
      await logout();
      return false;
    }

    return true;
  }

  /// Check if session is still valid (not timed out)
  Future<bool> _isSessionValid() async {
    try {
      final sessionStartStr = await _storage.read(key: _sessionStartKey);
      final lastActivityStr = await _storage.read(key: _lastActivityKey);

      if (sessionStartStr == null || lastActivityStr == null) {
        return true; // No session tracking data, allow (legacy sessions)
      }

      final now = DateTime.now();
      final sessionStart = DateTime.fromMillisecondsSinceEpoch(int.parse(sessionStartStr));
      final lastActivity = DateTime.fromMillisecondsSinceEpoch(int.parse(lastActivityStr));

      // Check maximum session duration
      if (now.difference(sessionStart) > _maxSessionDuration) {
        return false; // Session exceeded max duration
      }

      // Check idle timeout
      if (now.difference(lastActivity) > _idleTimeout) {
        return false; // Session idle for too long
      }

      return true;
    } catch (e) {
      return true; // On error, don't force logout
    }
  }

  /// Update last activity time (called on each authenticated request)
  Future<void> _updateLastActivity() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _storage.write(key: _lastActivityKey, value: now);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Refresh access token
  /// SECURITY: Uses certificate pinning
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final response = await _httpClient.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _storage.write(key: _accessTokenKey, value: data['access']);
      return data['access'];
    }
    return null;
  }

  /// Get user profile
  /// SECURITY: Uses certificate pinning
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final response = await _httpClient.get(
      Uri.parse('$baseUrl/user/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Try to refresh token
      final newToken = await refreshAccessToken();
      if (newToken != null) {
        // Retry with new token
        final retryResponse = await _httpClient.get(
          Uri.parse('$baseUrl/user/'),
          headers: {'Authorization': 'Bearer $newToken'},
        );
        if (retryResponse.statusCode == 200) {
          return json.decode(retryResponse.body);
        }
      }
    }
    return null;
  }

  /// Make authenticated HTTP request with auto-refresh
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    String? token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // SECURITY: Update last activity timestamp for session timeout tracking
    await _updateLastActivity();

    var response = await _makeRequest(method, endpoint, token, body);

    // If unauthorized, try to refresh token
    if (response.statusCode == 401) {
      token = await refreshAccessToken();
      if (token != null) {
        response = await _makeRequest(method, endpoint, token, body);
      }
    }

    return response;
  }

  /// SECURITY: Uses certificate pinning for all requests
  Future<http.Response> _makeRequest(
    String method,
    String endpoint,
    String token,
    Map<String, dynamic>? body,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await _httpClient.get(uri, headers: headers);
      case 'POST':
        return await _httpClient.post(uri, headers: headers, body: json.encode(body));
      case 'PATCH':
        return await _httpClient.patch(uri, headers: headers, body: json.encode(body));
      case 'DELETE':
        return await _httpClient.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  /// Decode JWT token payload
  Map<String, dynamic> _decodeToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }

  /// Check if token is expired
  bool _isTokenExpired(String token) {
    try {
      final payload = _decodeToken(token);
      final exp = payload['exp'];
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  /// Get current username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }
}
