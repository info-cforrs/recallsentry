import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import '../utils/http_helper.dart';
import '../utils/api_utils.dart';
import 'security_service.dart';

class UserProfileService {
  final AuthService _authService = AuthService();
  final String baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  UserProfileService() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  /// Get current user's profile
  /// SECURITY: Uses certificate pinning
  Future<UserProfile?> getUserProfile() async {
    return await HttpHelper.withTokenRefreshAndParse<UserProfile>(
      _httpClient,
      (token) => _httpClient.get(
        Uri.parse('$baseUrl/user/'),
        headers: ApiUtils.authHeaders(token),
      ),
      (response) => UserProfile.fromJson(json.decode(response.body)),
      authService: _authService,
    );
  }

  /// Update user profile
  /// SECURITY: Uses certificate pinning
  Future<UserProfile?> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final Map<String, dynamic> body = {};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;

    return await HttpHelper.withTokenRefreshAndParse<UserProfile>(
      _httpClient,
      (token) => _httpClient.patch(
        Uri.parse('$baseUrl/user/'),
        headers: ApiUtils.authHeaders(token),
        body: json.encode(body),
      ),
      (response) => UserProfile.fromJson(json.decode(response.body)),
      authService: _authService,
    );
  }

  /// Change user password
  /// SECURITY: Uses certificate pinning
  Future<PasswordChangeResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await HttpHelper.withTokenRefresh(
        _httpClient,
        (token) => _httpClient.post(
          Uri.parse('$baseUrl/change-password/'),
          headers: ApiUtils.authHeaders(token),
          body: json.encode({
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        ),
        authService: _authService,
      );

      if (response.statusCode == 200) {
        // SECURITY: Force re-login after password change to invalidate all existing tokens
        await _authService.logout();
        return PasswordChangeResult(
          success: true,
          message: 'Password changed successfully. Please log in again.',
          requiresRelogin: true,
        );
      } else {
        final errorData = json.decode(response.body);
        return PasswordChangeResult(
          success: false,
          message: _extractErrorMessage(errorData),
        );
      }
    } catch (e) {
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

  /// Export all user data (GDPR Article 20 - Right to Data Portability)
  /// SECURITY: Uses certificate pinning
  Future<DataExportResult> exportUserData() async {
    try {
      final response = await HttpHelper.withTokenRefresh(
        _httpClient,
        (token) => _httpClient.get(
          Uri.parse('$baseUrl/user/export-data/'),
          headers: ApiUtils.authHeaders(token),
        ),
        authService: _authService,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return DataExportResult(
          success: true,
          message: 'Data exported successfully',
          data: data,
        );
      } else {
        final errorData = json.decode(response.body);
        return DataExportResult(
          success: false,
          message: _extractErrorMessage(errorData),
        );
      }
    } catch (e) {
      return DataExportResult(
        success: false,
        message: 'Failed to export data: ${e.toString()}',
      );
    }
  }

  /// Delete user account (GDPR Article 17 - Right to Erasure)
  /// SECURITY: Uses certificate pinning, requires password re-authentication
  Future<AccountDeletionResult> deleteAccount({
    required String password,
  }) async {
    try {
      final response = await HttpHelper.withTokenRefresh(
        _httpClient,
        (token) => _httpClient.delete(
          Uri.parse('$baseUrl/user/delete-account/'),
          headers: ApiUtils.authHeaders(token),
          body: json.encode({
            'password': password,
          }),
        ),
        authService: _authService,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Account deleted successfully - clear local data
        await _authService.logout();
        return AccountDeletionResult(
          success: true,
          message: 'Account deleted successfully',
        );
      } else {
        final errorData = json.decode(response.body);
        return AccountDeletionResult(
          success: false,
          message: _extractErrorMessage(errorData),
        );
      }
    } catch (e) {
      return AccountDeletionResult(
        success: false,
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }
}

/// User Profile Model
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String subscriptionPlan;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.subscriptionPlan,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      subscriptionPlan: json['subscription_plan'] ?? 'Free/All Notifications',
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
  final bool requiresRelogin;

  PasswordChangeResult({
    required this.success,
    required this.message,
    this.requiresRelogin = false,
  });
}

/// Data Export Result (GDPR Article 20 - Right to Data Portability)
class DataExportResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  DataExportResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// Account Deletion Result (GDPR Article 17 - Right to Erasure)
class AccountDeletionResult {
  final bool success;
  final String message;

  AccountDeletionResult({
    required this.success,
    required this.message,
  });
}
