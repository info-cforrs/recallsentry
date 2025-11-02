import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'subscription_service.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  final String baseUrl = AppConfig.apiBaseUrl;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  /// Register a new user
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
    final response = await http.post(
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
      throw Exception(json.decode(response.body));
    }
  }

  /// Login and store tokens
  Future<bool> login(String username, String password) async {
    final response = await http.post(
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

      // Clear subscription cache to force refresh after login
      SubscriptionService().clearCache();

      return true;
    }
    return false;
  }

  /// Logout and clear all user data
  Future<void> logout() async {
    // Clear auth tokens
    await _storage.deleteAll();

    // Clear subscription cache
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
    return token != null && !_isTokenExpired(token);
  }

  /// Refresh access token
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    final response = await http.post(
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
  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final response = await http.get(
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
        final retryResponse = await http.get(
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
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(uri, headers: headers, body: json.encode(body));
      case 'PATCH':
        return await http.patch(uri, headers: headers, body: json.encode(body));
      case 'DELETE':
        return await http.delete(uri, headers: headers);
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
