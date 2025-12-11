import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/vehicle_recall_alert.dart';
import '../config/app_config.dart';
import '../exceptions/api_exceptions.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'security_service.dart';
import 'error_logger.dart';

/// Service for managing Vehicle Recall Alerts
///
/// These alerts are created when a new recall is detected for a user's vehicle
/// based on Year/Make/Model matching. The user must check NHTSA.gov to verify
/// if their specific VIN is affected.
class VehicleRecallAlertService {
  // Singleton pattern
  static final VehicleRecallAlertService _instance = VehicleRecallAlertService._internal();
  factory VehicleRecallAlertService() => _instance;

  final String baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  static const Duration _defaultTimeout = Duration(seconds: 30);

  VehicleRecallAlertService._internal() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  /// Wraps HTTP requests with timeout, error logging, and token refresh
  Future<T> _withTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    String? context,
    bool retryOnAuth = true,
  }) async {
    try {
      return await operation().timeout(
        timeout ?? _defaultTimeout,
        onTimeout: () {
          final error = NetworkException(
            'Request timeout after ${(timeout ?? _defaultTimeout).inSeconds} seconds',
          );
          ErrorLogger.log(
            message: 'Request timeout',
            service: 'VehicleRecallAlertService',
            method: context,
            error: error,
            reportToAnalytics: true,
          );
          throw error;
        },
      );
    } on AuthException catch (e) {
      if (retryOnAuth && e.statusCode == 401) {
        final newToken = await AuthService().refreshAccessToken();
        if (newToken != null) {
          return _withTimeout(
            operation,
            timeout: timeout,
            context: context,
            retryOnAuth: false,
          );
        }
      }
      rethrow;
    } catch (e, stack) {
      if (e is! ApiException) {
        ErrorLogger.log(
          message: 'API request failed',
          service: 'VehicleRecallAlertService',
          method: context,
          error: e,
          stackTrace: stack,
          reportToAnalytics: true,
        );
      }
      rethrow;
    }
  }

  // ==================== ALERT METHODS ====================

  /// Get all vehicle recall alerts for the authenticated user
  Future<List<VehicleRecallAlert>> getAlerts({
    VehicleRecallAlertStatus? status,
  }) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        // Build query parameters
        final queryParams = <String, String>{};
        if (status != null) {
          queryParams['status'] = status.toApiString();
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get vehicle recall alerts');

        final dynamic responseBody = json.decode(response.body);

        // Handle both paginated and non-paginated responses
        final List<dynamic> jsonList;
        if (responseBody is List) {
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => VehicleRecallAlert.fromJson(json)).toList();
      },
      context: 'getAlerts',
    );
  }

  /// Get only pending alerts (awaiting user verification)
  Future<List<VehicleRecallAlert>> getPendingAlerts() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/pending/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get pending vehicle recall alerts');

        final dynamic responseBody = json.decode(response.body);

        final List<dynamic> jsonList;
        if (responseBody is List) {
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => VehicleRecallAlert.fromJson(json)).toList();
      },
      context: 'getPendingAlerts',
    );
  }

  /// Get count of pending alerts (for badge display)
  Future<int> getPendingAlertCount() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/pending-count/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get pending alert count');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['count'] as int? ?? 0;
      },
      context: 'getPendingAlertCount',
    );
  }

  /// Get a specific alert by ID
  Future<VehicleRecallAlert> getAlert(int alertId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/$alertId/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get vehicle recall alert');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return VehicleRecallAlert.fromJson(jsonData);
      },
      context: 'getAlert',
    );
  }

  /// Get alerts for a specific user item (vehicle)
  Future<List<VehicleRecallAlert>> getAlertsForItem(int userItemId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/by-item/?user_item_id=$userItemId');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get alerts for item');

        final dynamic responseBody = json.decode(response.body);

        final List<dynamic> jsonList;
        if (responseBody is List) {
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => VehicleRecallAlert.fromJson(json)).toList();
      },
      context: 'getAlertsForItem',
    );
  }

  // ==================== ALERT ACTIONS ====================

  /// Mark that the user has clicked to check NHTSA.gov
  ///
  /// Records the timestamp and returns the NHTSA URL for the VIN
  Future<MarkCheckedResponse> markChecked(int alertId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/$alertId/mark-checked/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Mark alert checked');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MarkCheckedResponse.fromJson(jsonData);
      },
      context: 'markChecked',
    );
  }

  /// Respond to an alert after checking NHTSA.gov
  ///
  /// response: 'not_affected' - User verified VIN is NOT on recall list
  /// response: 'affected' - User verified VIN IS on recall list (creates RMC enrollment)
  Future<RespondToAlertResponse> respond(int alertId, String responseType) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/$alertId/respond/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'response': responseType}),
        );

        ApiUtils.checkResponse(response, context: 'Respond to alert');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return RespondToAlertResponse.fromJson(jsonData);
      },
      context: 'respond',
      timeout: const Duration(seconds: 45), // Longer timeout for RMC creation
    );
  }

  /// Respond "Not Affected" to an alert
  Future<RespondToAlertResponse> respondNotAffected(int alertId) async {
    return respond(alertId, 'not_affected');
  }

  /// Respond "Affected" to an alert (creates RMC enrollment)
  Future<RespondToAlertResponse> respondAffected(int alertId) async {
    return respond(alertId, 'affected');
  }

  /// Dismiss an alert (hide without responding)
  Future<void> dismissAlert(int alertId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vehicle-recall-alerts/$alertId/dismiss/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Dismiss alert');
      },
      context: 'dismissAlert',
    );
  }
}

// ==================== RESPONSE MODELS ====================

/// Response from mark-checked endpoint
class MarkCheckedResponse {
  final String status;
  final DateTime? checkedAt;
  final String nhtsaUrl;

  MarkCheckedResponse({
    required this.status,
    this.checkedAt,
    required this.nhtsaUrl,
  });

  factory MarkCheckedResponse.fromJson(Map<String, dynamic> json) {
    return MarkCheckedResponse(
      status: json['status'] as String? ?? 'checked',
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      nhtsaUrl: json['nhtsa_url'] as String? ?? 'https://www.nhtsa.gov/recalls',
    );
  }
}

/// Response from respond endpoint
class RespondToAlertResponse {
  final String status;
  final String? message;
  final int? rmcEnrollmentId;

  RespondToAlertResponse({
    required this.status,
    this.message,
    this.rmcEnrollmentId,
  });

  factory RespondToAlertResponse.fromJson(Map<String, dynamic> json) {
    return RespondToAlertResponse(
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
      rmcEnrollmentId: json['rmc_enrollment_id'] as int?,
    );
  }

  /// Check if user responded "affected" and RMC was created
  bool get createdRmcEnrollment =>
      status == 'affected' && rmcEnrollmentId != null;
}
