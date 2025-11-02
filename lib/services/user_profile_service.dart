import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class UserProfileService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConfig.apiBaseUrl;

  /// Get current user's profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('🔐 No auth token found - user not logged in');
        return null;
      }

      print('🔐 Fetching user profile with token...');
      final response = await http.get(
        Uri.parse('$baseUrl/user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ User profile loaded successfully');
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 401) {
        print('⚠️ Token expired, attempting refresh...');
        // Try to refresh token
        final newToken = await _authService.refreshAccessToken();
        if (newToken != null) {
          final retryResponse = await http.get(
            Uri.parse('$baseUrl/user/'),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          );
          if (retryResponse.statusCode == 200) {
            final data = json.decode(retryResponse.body);
            print('✅ User profile loaded with refreshed token');
            return UserProfile.fromJson(data);
          }
        }
        print('❌ Token refresh failed - user needs to login again');
        // Clear invalid tokens
        await _authService.logout();
        return null;
      }

      print('❌ Failed to load user profile: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> body = {};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;

      final response = await http.patch(
        Uri.parse('$baseUrl/user/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 401) {
        // Try to refresh token
        final newToken = await _authService.refreshAccessToken();
        if (newToken != null) {
          final retryResponse = await http.patch(
            Uri.parse('$baseUrl/user/'),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          );
          if (retryResponse.statusCode == 200) {
            final data = json.decode(retryResponse.body);
            return UserProfile.fromJson(data);
          }
        }
      }

      throw Exception('Failed to update profile: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  /// Change user password
  Future<PasswordChangeResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        return PasswordChangeResult(
          success: false,
          message: 'Not authenticated',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/change-password/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return PasswordChangeResult(
          success: true,
          message: 'Password changed successfully',
        );
      } else if (response.statusCode == 401) {
        // Try to refresh token
        final newToken = await _authService.refreshAccessToken();
        if (newToken != null) {
          final retryResponse = await http.post(
            Uri.parse('$baseUrl/change-password/'),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          );
          if (retryResponse.statusCode == 200) {
            return PasswordChangeResult(
              success: true,
              message: 'Password changed successfully',
            );
          } else {
            final errorData = json.decode(retryResponse.body);
            return PasswordChangeResult(
              success: false,
              message: _extractErrorMessage(errorData),
            );
          }
        }
      } else {
        final errorData = json.decode(response.body);
        return PasswordChangeResult(
          success: false,
          message: _extractErrorMessage(errorData),
        );
      }

      return PasswordChangeResult(
        success: false,
        message: 'Failed to change password',
      );
    } catch (e) {
      print('Error changing password: $e');
      return PasswordChangeResult(
        success: false,
        message: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Extract error message from API response
  String _extractErrorMessage(Map<String, dynamic> errorData) {
    if (errorData.containsKey('old_password')) {
      return errorData['old_password'][0];
    } else if (errorData.containsKey('new_password')) {
      return errorData['new_password'][0];
    } else if (errorData.containsKey('detail')) {
      return errorData['detail'];
    } else if (errorData.containsKey('message')) {
      return errorData['message'];
    }
    return 'An error occurred';
  }
}

/// User Profile Model
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}

/// Password Change Result
class PasswordChangeResult {
  final bool success;
  final String message;

  PasswordChangeResult({
    required this.success,
    required this.message,
  });
}
