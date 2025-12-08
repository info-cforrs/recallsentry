import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_home.dart';
import '../models/user_room.dart';
import '../models/user_item.dart';
import '../models/recall_match.dart';
import '../models/rmc_enrollment.dart';
import '../config/app_config.dart';
import '../exceptions/api_exceptions.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'api_service.dart';
import 'security_service.dart';
import 'error_logger.dart';

class RecallMatchService {
  final String baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  // Default timeout for API requests
  static const Duration _defaultTimeout = Duration(seconds: 30);

  RecallMatchService() {
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
            service: 'RecallMatchService',
            method: context,
            error: error,
            reportToAnalytics: true,
          );
          throw error;
        },
      );
    } on AuthException catch (e) {
      // If it's a 401 and we haven't retried yet, try refreshing the token
      if (retryOnAuth && e.statusCode == 401) {
        final newToken = await AuthService().refreshAccessToken();
        if (newToken != null) {
          // Retry the operation with the new token
          return _withTimeout(
            operation,
            timeout: timeout,
            context: context,
            retryOnAuth: false, // Don't retry again
          );
        }
      }
      rethrow;
    } catch (e, stack) {
      if (e is! ApiException) {
        ErrorLogger.log(
          message: 'API request failed',
          service: 'RecallMatchService',
          method: context,
          error: e,
          stackTrace: stack,
          reportToAnalytics: true,
        );
      }
      rethrow;
    }
  }

  // ==================== HOME METHODS ====================

  /// Get all homes for the authenticated user
  Future<List<UserHome>> getUserHomes() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-homes/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get user homes');

        final dynamic responseBody = json.decode(response.body);

        // Handle both paginated and non-paginated responses
        final List<dynamic> jsonList;
        if (responseBody is List) {
          // Non-paginated response (direct array)
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          // Paginated response (DRF format)
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          // Unexpected format
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => UserHome.fromJson(json)).toList();
      },
      context: 'getUserHomes',
    );
  }

  /// Get a specific home by ID
  Future<UserHome> getHome(int homeId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-homes/$homeId/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get home');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserHome.fromJson(jsonData);
      },
      context: 'getHome',
    );
  }

  /// Create a new home
  Future<UserHome> createHome(String name) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-homes/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
          }),
        );

        ApiUtils.checkResponse(response, context: 'Create home');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserHome.fromJson(jsonData);
      },
      context: 'createHome',
    );
  }

  /// Update a home
  Future<UserHome> updateHome(int homeId, String name) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-homes/$homeId/');
        final response = await _httpClient.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
          }),
        );

        ApiUtils.checkResponse(response, context: 'Update home');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserHome.fromJson(jsonData);
      },
      context: 'updateHome',
    );
  }

  /// Delete a home
  Future<void> deleteHome(int homeId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-homes/$homeId/');
        final response = await _httpClient.delete(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Delete home');
      },
      context: 'deleteHome',
    );
  }

  // ==================== ROOM METHODS ====================

  /// Get all rooms for the authenticated user
  Future<List<UserRoom>> getUserRooms() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get user rooms');

        final dynamic responseBody = json.decode(response.body);

        // Handle both paginated and non-paginated responses
        final List<dynamic> jsonList;
        if (responseBody is List) {
          // Non-paginated response (direct array)
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          // Paginated response (DRF format)
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          // Unexpected format
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => UserRoom.fromJson(json)).toList();
      },
      context: 'getUserRooms',
    );
  }

  /// Get rooms for a specific home
  Future<List<UserRoom>> getRoomsByHome(int homeId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/by_home/?home_id=$homeId');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get rooms by home');

        final dynamic responseBody = json.decode(response.body);

        // Handle both paginated and non-paginated responses
        final List<dynamic> jsonList;
        if (responseBody is List) {
          // Non-paginated response (direct array)
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          // Paginated response (DRF format)
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          // Unexpected format
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => UserRoom.fromJson(json)).toList();
      },
      context: 'getRoomsByHome',
    );
  }

  /// Get a specific room by ID
  Future<UserRoom> getRoom(int roomId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/$roomId/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get room');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserRoom.fromJson(jsonData);
      },
      context: 'getRoom',
    );
  }

  /// Create a new room
  Future<UserRoom> createRoom({
    required int homeId,
    required String name,
    String? roomType,
  }) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'home': homeId,
            'name': name,
            'room_type': roomType ?? '',
          }),
        );

        ApiUtils.checkResponse(response, context: 'Create room');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserRoom.fromJson(jsonData);
      },
      context: 'createRoom',
    );
  }

  /// Update a room
  Future<UserRoom> updateRoom({
    required int roomId,
    required String name,
    String? roomType,
  }) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/$roomId/');
        final response = await _httpClient.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': name,
            'room_type': roomType ?? '',
          }),
        );

        ApiUtils.checkResponse(response, context: 'Update room');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserRoom.fromJson(jsonData);
      },
      context: 'updateRoom',
    );
  }

  /// Delete a room
  Future<void> deleteRoom(int roomId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-rooms/$roomId/');
        final response = await _httpClient.delete(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Delete room');
      },
      context: 'deleteRoom',
    );
  }

  // ==================== USER ITEM METHODS ====================

  /// Get all items for the authenticated user
  Future<List<UserItem>> getUserItems() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get user items');

        final dynamic responseBody = json.decode(response.body);

        // Handle both paginated and non-paginated responses
        final List<dynamic> jsonList;
        if (responseBody is List) {
          // Non-paginated response (direct array)
          jsonList = responseBody;
        } else if (responseBody is Map && responseBody.containsKey('results')) {
          // Paginated response (DRF format)
          jsonList = responseBody['results'] as List<dynamic>;
        } else {
          // Unexpected format
          throw ApiException('Unexpected API response format');
        }

        return jsonList.map((json) => UserItem.fromJson(json)).toList();
      },
      context: 'getUserItems',
    );
  }

  /// Get a specific item by ID
  Future<UserItem> getUserItem(int itemId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/$itemId/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get user item');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserItem.fromJson(jsonData);
      },
      context: 'getUserItem',
    );
  }

  /// Delete a user item
  Future<void> deleteUserItem(int itemId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/$itemId/');
        final response = await _httpClient.delete(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Delete user item');
      },
      context: 'deleteUserItem',
    );
  }

  /// Move a user item to a different home and room
  Future<UserItem> moveUserItem(int itemId, int homeId, int roomId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/$itemId/');
        final response = await _httpClient.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'home_id': homeId,
            'room_id': roomId,
          }),
        );

        ApiUtils.checkResponse(response, context: 'Move user item');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserItem.fromJson(jsonData);
      },
      context: 'moveUserItem',
    );
  }

  /// Update a user item's details
  /// Used for renaming vehicles, updating make/model, tires, etc.
  Future<UserItem> updateUserItem({
    required int itemId,
    String? manufacturer,
    String? brandName,
    String? productName,
    String? modelNumber,
    String? upc,
    String? retailer,
    // Vehicle-specific fields
    String? vehicleYear,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleVin,
    // Tire-specific fields
    String? tireDotCode,
    String? tireSize,
    int? tireQty,
    String? tireProductionWeek,
    String? tireProductionYear,
    // Child seat-specific fields
    String? childSeatModelNumber,
    String? childSeatProductionMonth,
    String? childSeatProductionYear,
  }) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/$itemId/');

        // Build the update body with only non-null fields
        final Map<String, dynamic> body = {};
        if (manufacturer != null) body['manufacturer'] = manufacturer;
        if (brandName != null) body['brand_name'] = brandName;
        if (productName != null) body['product_name'] = productName;
        if (modelNumber != null) body['model_number'] = modelNumber;
        if (upc != null) body['upc'] = upc;
        if (retailer != null) body['retailer'] = retailer;
        // Vehicle fields
        if (vehicleYear != null) body['vehicle_year'] = vehicleYear;
        if (vehicleMake != null) body['vehicle_make'] = vehicleMake;
        if (vehicleModel != null) body['vehicle_model'] = vehicleModel;
        if (vehicleVin != null) body['vehicle_vin'] = vehicleVin;
        // Tire fields
        if (tireDotCode != null) body['tire_dot_code'] = tireDotCode;
        if (tireSize != null) body['tire_size'] = tireSize;
        if (tireQty != null) body['tire_qty'] = tireQty;
        if (tireProductionWeek != null) body['tire_production_week'] = tireProductionWeek;
        if (tireProductionYear != null) body['tire_production_year'] = tireProductionYear;
        // Child seat fields
        if (childSeatModelNumber != null) body['child_seat_model_number'] = childSeatModelNumber;
        if (childSeatProductionMonth != null) body['child_seat_production_month'] = childSeatProductionMonth;
        if (childSeatProductionYear != null) body['child_seat_production_year'] = childSeatProductionYear;

        final response = await _httpClient.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        ApiUtils.checkResponse(response, context: 'Update user item');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserItem.fromJson(jsonData);
      },
      context: 'updateUserItem',
    );
  }

  /// Create a new user item
  ///
  /// For vehicles, tires, and child seats, set itemCategory to the appropriate value
  /// and use the vehicle-specific fields (vehicleYear, vehicleMake, vehicleModel, vehicleVin)
  /// or tire-specific fields (tireDotCode, tireSize, tireQty)
  Future<UserItem> createUserItem({
    required int homeId,
    required int roomId,
    String? manufacturer,
    String? brandName,
    String? productName,
    String? modelNumber,
    String? upc,
    String? sku,
    String? batchLotCode,
    String? serialNumber,
    String? dateType,
    DateTime? itemDate,
    String? retailer,
    List<String>? photoUrls,
    // Item category for garage items (vehicle, tires, child_seat)
    String? itemCategory,
    // Vehicle-specific fields
    String? vehicleYear,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleVin,
    // Tire-specific fields
    String? tireDotCode,
    String? tireSize,
    int? tireQty,
    String? tireProductionWeek,
    String? tireProductionYear,
    // Child seat-specific fields
    String? childSeatModelNumber,
    String? childSeatProductionMonth,
    String? childSeatProductionYear,
  }) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/');
        final body = {
          'home_id': homeId,
          'room_id': roomId,
          'manufacturer': manufacturer ?? '',
          'brand_name': brandName ?? '',
          'product_name': productName ?? '',
          'model_number': modelNumber ?? '',
          'upc': upc ?? '',
          'sku': sku ?? '',
          'batch_lot_code': batchLotCode ?? '',
          'serial_number': serialNumber ?? '',
          'date_type': dateType,
          'item_date': itemDate?.toIso8601String(),
          'retailer': retailer,
          'photo_urls': photoUrls ?? [],
        };

        // Add item category if specified
        if (itemCategory != null) {
          body['item_category'] = itemCategory;
        }

        // Add vehicle-specific fields if this is a vehicle
        if (vehicleYear != null) {
          body['vehicle_year'] = vehicleYear;
        }
        if (vehicleMake != null) {
          body['vehicle_make'] = vehicleMake;
        }
        if (vehicleModel != null) {
          body['vehicle_model'] = vehicleModel;
        }
        if (vehicleVin != null) {
          body['vehicle_vin'] = vehicleVin;
        }

        // Add tire-specific fields if this is tires
        if (tireDotCode != null) {
          body['tire_dot_code'] = tireDotCode;
        }
        if (tireSize != null) {
          body['tire_size'] = tireSize;
        }
        if (tireQty != null) {
          body['tire_qty'] = tireQty;
        }
        if (tireProductionWeek != null) {
          body['tire_production_week'] = tireProductionWeek;
        }
        if (tireProductionYear != null) {
          body['tire_production_year'] = tireProductionYear;
        }

        // Add child seat-specific fields if this is a child seat
        if (childSeatModelNumber != null) {
          body['child_seat_model_number'] = childSeatModelNumber;
        }
        if (childSeatProductionMonth != null) {
          body['child_seat_production_month'] = childSeatProductionMonth;
        }
        if (childSeatProductionYear != null) {
          body['child_seat_production_year'] = childSeatProductionYear;
        }

        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );

        ApiUtils.checkResponse(response, context: 'Create user item');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserItem.fromJson(jsonData);
      },
      context: 'createUserItem',
    );
  }

  // ==================== RECALL MATCH METHODS ====================

  /// Get recall counts for all rooms in a home
  /// Returns a Map of roomId -> recall count
  ///
  /// TODO: Backend API endpoint needs to be implemented
  /// Expected endpoint: GET /user-rooms/recall-counts/?home_id={homeId}
  /// Expected response: {"room_id": recall_count, ...}
  Future<Map<int, int>> getRecallCountsByHome(int homeId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        try {
          final uri = Uri.parse('$baseUrl/user-rooms/recall-counts/?home_id=$homeId');
          final response = await _httpClient.get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          // If endpoint doesn't exist yet (404), return empty map
          if (response.statusCode == 404) {
            return {};
          }

          ApiUtils.checkResponse(response, context: 'Get recall counts by home');

          final Map<String, dynamic> jsonData = json.decode(response.body);

          // Convert string keys to int keys
          final Map<int, int> recallCounts = {};
          jsonData.forEach((key, value) {
            final roomId = int.tryParse(key);
            if (roomId != null && value is int) {
              recallCounts[roomId] = value;
            }
          });

          return recallCounts;
        } catch (e) {
          // If API endpoint doesn't exist yet, silently return empty map
          // This allows the UI to work while backend is being implemented
          if (e is ApiException && e.statusCode == 404) {
            return {};
          }
          rethrow;
        }
      },
      context: 'getRecallCountsByHome',
    );
  }

  /// Get recall count for a specific room
  Future<int> getRecallCountForRoom(int roomId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        try {
          final uri = Uri.parse('$baseUrl/user-rooms/$roomId/recall-count/');
          final response = await _httpClient.get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          // If endpoint doesn't exist yet (404), return 0
          if (response.statusCode == 404) {
            return 0;
          }

          ApiUtils.checkResponse(response, context: 'Get recall count for room');

          final Map<String, dynamic> jsonData = json.decode(response.body);
          return jsonData['recall_count'] as int? ?? 0;
        } catch (e) {
          // If API endpoint doesn't exist yet, silently return 0
          if (e is ApiException && e.statusCode == 404) {
            return 0;
          }
          rethrow;
        }
      },
      context: 'getRecallCountForRoom',
    );
  }

  /// Get total recall count for a specific home
  /// Returns the total number of active recalls (RMC status != Completed/Closed)
  ///
  /// Endpoint: GET /user-homes/{homeId}/recall-count/
  /// Returns: {"home_id": 1, "recall_count": 5}
  Future<int> getRecallCountForHome(int homeId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        try {
          final uri = Uri.parse('$baseUrl/user-homes/$homeId/recall-count/');
          final response = await _httpClient.get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          // If endpoint doesn't exist yet (404), return 0
          if (response.statusCode == 404) {
            return 0;
          }

          ApiUtils.checkResponse(response, context: 'Get recall count for home');

          final Map<String, dynamic> jsonData = json.decode(response.body);
          return jsonData['recall_count'] as int? ?? 0;
        } catch (e) {
          // If API endpoint doesn't exist yet, silently return 0
          if (e is ApiException && e.statusCode == 404) {
            return 0;
          }
          rethrow;
        }
      },
      context: 'getRecallCountForHome',
    );
  }

  /// Get recall counts for all homes
  /// Returns a Map of homeId -> recall count
  ///
  /// Endpoint: GET /user-homes/recall-counts/
  /// Returns: {"home_id_1": count, "home_id_2": count, ...}
  Future<Map<int, int>> getAllHomeRecallCounts() async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        try {
          final uri = Uri.parse('$baseUrl/user-homes/recall-counts/');
          final response = await _httpClient.get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          // If endpoint doesn't exist yet (404), return empty map
          if (response.statusCode == 404) {
            return {};
          }

          ApiUtils.checkResponse(response, context: 'Get all home recall counts');

          final Map<String, dynamic> jsonData = json.decode(response.body);

          // Convert string keys to int keys
          final Map<int, int> recallCounts = {};
          jsonData.forEach((key, value) {
            final homeId = int.tryParse(key);
            if (homeId != null && value is int) {
              recallCounts[homeId] = value;
            }
          });

          return recallCounts;
        } catch (e) {
          // If API endpoint doesn't exist yet, silently return empty map
          if (e is ApiException && e.statusCode == 404) {
            return {};
          }
          rethrow;
        }
      },
      context: 'getAllHomeRecallCounts',
    );
  }

  // ==================== RECALL MATCH API METHODS ====================

  /// Get all recall matches for the authenticated user
  ///
  /// Query params:
  /// - status: Filter by status (pending_review, confirmed, dismissed, expired, invalidated)
  /// - matchConfidence: Filter by confidence (HIGH, MEDIUM-HIGH, MEDIUM, LOW)
  /// - includeExpired: Include expired matches (default: false)
  Future<List<RecallMatchSummary>> getRecallMatches({
    MatchStatus? status,
    MatchConfidence? matchConfidence,
    bool includeExpired = false,
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
          queryParams['status'] = _statusToString(status);
        }
        if (matchConfidence != null) {
          queryParams['match_confidence'] = _confidenceToString(matchConfidence);
        }
        if (includeExpired) {
          queryParams['include_expired'] = 'true';
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get recall matches');

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

        // Filter out invalid matches (where user_item or recall is null) and parse valid ones
        final validMatches = <RecallMatchSummary>[];
        for (final json in jsonList) {
          try {
            if (json['user_item'] != null && json['recall'] != null) {
              validMatches.add(RecallMatchSummary.fromJson(json));
            } else {
              print('⚠️ Skipping match ${json['id']}: Missing user_item or recall');
            }
          } catch (e) {
            print('❌ Error parsing match ${json['id']}: $e');
          }
        }
        return validMatches;
      },
      context: 'getRecallMatches',
    );
  }

  /// Get a specific recall match by ID
  Future<RecallMatch> getRecallMatch(int matchId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/$matchId/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get recall match');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return RecallMatch.fromJson(jsonData);
      },
      context: 'getRecallMatch',
    );
  }

  /// Get RMC enrolled counts by room for a specific home
  /// Only counts items that are confirmed (enrolled in RMC) and NOT completed/closed
  /// Returns Map of roomId -> count
  Future<Map<int, int>> getRmcEnrolledCountsByHome(int homeId) async {
    try {
      // Get RMC enrollments to check completion status
      List<RmcEnrollment> enrollments = [];
      try {
        enrollments = await ApiService().fetchRmcEnrollments();
      } catch (e) {
        // Continue without enrollment check if fetch fails
      }

      // Get only confirmed matches (items enrolled in RMC)
      final confirmedMatches = await getRecallMatches(
        status: MatchStatus.confirmed,
        includeExpired: false,
      );

      // Filter to items in this home, exclude completed, and count by room
      final Map<int, int> roomCounts = {};
      for (final match in confirmedMatches) {
        if (match.userItem.homeId == homeId) {
          // Check if RMC enrollment is completed/closed
          bool isCompleted = false;
          final recallDbId = match.recall.databaseId;
          if (recallDbId != null && enrollments.isNotEmpty) {
            for (final e in enrollments) {
              if (e.recallId == recallDbId) {
                final enrollmentStatus = e.status.trim().toLowerCase();
                if (enrollmentStatus == 'completed' || enrollmentStatus == 'closed') {
                  isCompleted = true;
                }
                break;
              }
            }
          }
          if (!isCompleted) {
            final roomId = match.userItem.roomId;
            roomCounts[roomId] = (roomCounts[roomId] ?? 0) + 1;
          }
        }
      }
      return roomCounts;
    } catch (e) {
      print('❌ Error getting RMC enrolled counts: $e');
      return {};
    }
  }

  /// Get recall status for a specific item
  /// Returns: "Recall Started" if enrolled in RMC (and not completed), "Needs Review" if pending match, null if no match or completed
  Future<String?> getItemRecallStatus(int itemId) async {
    try {
      // Get RMC enrollments to check completion status
      List<RmcEnrollment> enrollments = [];
      try {
        enrollments = await ApiService().fetchRmcEnrollments();
      } catch (e) {
        // Continue without enrollment check if fetch fails
      }

      // Check for confirmed match first (enrolled in RMC)
      final confirmedMatches = await getRecallMatches(
        status: MatchStatus.confirmed,
        includeExpired: false,
      );
      for (final match in confirmedMatches) {
        if (match.userItem.id == itemId) {
          // Check if RMC enrollment is completed/closed
          final recallDbId = match.recall.databaseId;
          if (recallDbId != null && enrollments.isNotEmpty) {
            RmcEnrollment? enrollment;
            for (final e in enrollments) {
              if (e.recallId == recallDbId) {
                enrollment = e;
                break;
              }
            }
            if (enrollment != null) {
              final enrollmentStatus = enrollment.status.trim().toLowerCase();
              if (enrollmentStatus == 'completed' || enrollmentStatus == 'closed') {
                return null; // Recall is completed, no active status
              }
            }
          }
          return 'Recall Started';
        }
      }

      // Check for pending match (needs review)
      final pendingMatches = await getRecallMatches(
        status: MatchStatus.pendingReview,
        includeExpired: false,
      );
      for (final match in pendingMatches) {
        if (match.userItem.id == itemId) {
          return 'Needs Review';
        }
      }

      return null; // No recall status
    } catch (e) {
      print('❌ Error getting item recall status: $e');
      return null;
    }
  }

  /// Get recall statuses for multiple items in a room
  /// Returns Map of itemId -> status ("Recall Started", "Needs Review", or null for completed)
  Future<Map<int, String>> getItemRecallStatusesByRoom(int roomId) async {
    try {
      final Map<int, String> statuses = {};

      // Get RMC enrollments to check completion status
      List<RmcEnrollment> enrollments = [];
      try {
        enrollments = await ApiService().fetchRmcEnrollments();
      } catch (e) {
        // Continue without enrollment check if fetch fails
      }

      // Get confirmed matches (enrolled in RMC)
      final confirmedMatches = await getRecallMatches(
        status: MatchStatus.confirmed,
        includeExpired: false,
      );
      for (final match in confirmedMatches) {
        if (match.userItem.roomId == roomId) {
          // Check if RMC enrollment is completed/closed
          bool isCompleted = false;
          final recallDbId = match.recall.databaseId;
          if (recallDbId != null && enrollments.isNotEmpty) {
            for (final e in enrollments) {
              if (e.recallId == recallDbId) {
                final enrollmentStatus = e.status.trim().toLowerCase();
                if (enrollmentStatus == 'completed' || enrollmentStatus == 'closed') {
                  isCompleted = true;
                }
                break;
              }
            }
          }
          if (!isCompleted) {
            statuses[match.userItem.id] = 'Recall Started';
          }
        }
      }

      // Get pending matches (needs review)
      final pendingMatches = await getRecallMatches(
        status: MatchStatus.pendingReview,
        includeExpired: false,
      );
      for (final match in pendingMatches) {
        if (match.userItem.roomId == roomId && !statuses.containsKey(match.userItem.id)) {
          statuses[match.userItem.id] = 'Needs Review';
        }
      }

      return statuses;
    } catch (e) {
      print('❌ Error getting item recall statuses: $e');
      return {};
    }
  }

  /// Get the RecallMatchSummary for a specific item (if it has an active match)
  /// Returns null if no match found
  Future<RecallMatchSummary?> getMatchForItem(int itemId) async {
    try {
      // Check confirmed matches first
      final confirmedMatches = await getRecallMatches(
        status: MatchStatus.confirmed,
        includeExpired: false,
      );
      for (final match in confirmedMatches) {
        if (match.userItem.id == itemId) {
          return match;
        }
      }

      // Check pending matches
      final pendingMatches = await getRecallMatches(
        status: MatchStatus.pendingReview,
        includeExpired: false,
      );
      for (final match in pendingMatches) {
        if (match.userItem.id == itemId) {
          return match;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error getting match for item: $e');
      return null;
    }
  }

  /// Confirm a recall match and enroll in RMC
  ///
  /// Required:
  /// - lotNumber: Lot/batch number from the product
  /// - purchaseDate: Date when product was purchased
  ///
  /// Optional:
  /// - purchaseLocation: Store/location where product was purchased
  Future<ConfirmMatchResponse> confirmMatch(
    int matchId,
    ConfirmMatchRequest request,
  ) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/$matchId/confirm/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(request.toJson()),
        );

        ApiUtils.checkResponse(response, context: 'Confirm recall match');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ConfirmMatchResponse.fromJson(jsonData);
      },
      context: 'confirmMatch',
      timeout: const Duration(seconds: 45), // Longer timeout for RMC creation
    );
  }

  /// Dismiss a recall match as false positive
  Future<DismissMatchResponse> dismissMatch(
    int matchId,
    DismissMatchRequest request,
  ) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/$matchId/dismiss/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(request.toJson()),
        );

        ApiUtils.checkResponse(response, context: 'Dismiss recall match');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return DismissMatchResponse.fromJson(jsonData);
      },
      context: 'dismissMatch',
    );
  }

  /// Trigger immediate re-matching for a user item
  ///
  /// Called after user edits an item to check for new matches.
  /// Returns a task ID - user will be notified via FCM when matches are found.
  Future<Map<String, dynamic>> rematchUserItem(int itemId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/user-items/$itemId/rematch/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Rematch user item');

        return json.decode(response.body) as Map<String, dynamic>;
      },
      context: 'rematchUserItem',
    );
  }

  /// Get count of pending recall matches
  Future<int> getPendingMatchCount() async {
    final matches = await getRecallMatches(
      status: MatchStatus.pendingReview,
      includeExpired: false,
    );
    return matches.length;
  }

  /// Revalidate a match with user-provided identifier fields
  ///
  /// This re-runs the matching algorithm with additional fields provided by the user
  /// in the confirmation modal. If an identifier doesn't match, the match is disqualified.
  ///
  /// Returns updated match score and validation results, or disqualification info.
  Future<RevalidateMatchResponse> revalidateMatch(
    int matchId,
    RevalidateMatchRequest request,
  ) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/$matchId/revalidate/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(request.toJson()),
        );

        ApiUtils.checkResponse(response, context: 'Revalidate recall match');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return RevalidateMatchResponse.fromJson(jsonData);
      },
      context: 'revalidateMatch',
    );
  }

  /// Get available identifier fields for a recall
  ///
  /// Returns which fields (UPC, Model, Serial, Lot, Date) the recall has data for.
  /// Used to dynamically populate the confirmation modal.
  Future<RecallAvailableFields> getRecallAvailableFields(int matchId) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/recallmatch/matches/$matchId/available-fields/');
        final response = await _httpClient.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        ApiUtils.checkResponse(response, context: 'Get recall available fields');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return RecallAvailableFields.fromJson(jsonData);
      },
      context: 'getRecallAvailableFields',
    );
  }

  // ==================== VIN RECALL LOOKUP ====================

  /// Look up recalls for a VIN using NHTSA's direct VIN recall API
  ///
  /// Available to SmartFiltering and RecallMatch users via Quick Check.
  /// - SmartFiltering: Can view matching recalls only
  /// - RecallMatch: Can view and save vehicle to home/room
  ///
  /// Returns:
  /// {
  ///   "success": true,
  ///   "vin": "1HGBH41JXMN109186",
  ///   "vehicle": {"year": "2021", "make": "HONDA", "model": "CIVIC"},
  ///   "recalls": [...],
  ///   "recall_count": 2
  /// }
  Future<VinRecallLookupResult> getRecallsByVin(String vin) async {
    return _withTimeout(
      () async {
        final token = await AuthService().getAccessToken();
        if (token == null) {
          throw AuthException('Not authenticated', shouldLogout: true);
        }

        final uri = Uri.parse('$baseUrl/vin-recalls/');
        final response = await _httpClient.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'vin': vin.toUpperCase().trim()}),
        );

        // Handle upgrade required response
        if (response.statusCode == 403) {
          final jsonData = json.decode(response.body);
          if (jsonData['upgrade_required'] == true) {
            return VinRecallLookupResult(
              success: false,
              vin: vin,
              error: jsonData['error'] ?? 'Subscription upgrade required',
              upgradeRequired: true,
            );
          }
        }

        ApiUtils.checkResponse(response, context: 'VIN recall lookup');

        final Map<String, dynamic> jsonData = json.decode(response.body);
        return VinRecallLookupResult.fromJson(jsonData);
      },
      context: 'getRecallsByVin',
      timeout: const Duration(seconds: 45), // Longer timeout for NHTSA API call
    );
  }

  // Helper methods
  String _statusToString(MatchStatus status) {
    switch (status) {
      case MatchStatus.pendingReview:
        return 'pending_review';
      case MatchStatus.confirmed:
        return 'confirmed';
      case MatchStatus.dismissed:
        return 'dismissed';
      case MatchStatus.expired:
        return 'expired';
      case MatchStatus.invalidated:
        return 'invalidated';
    }
  }

  String _confidenceToString(MatchConfidence confidence) {
    switch (confidence) {
      case MatchConfidence.high:
        return 'HIGH';
      case MatchConfidence.mediumHigh:
        return 'MEDIUM-HIGH';
      case MatchConfidence.medium:
        return 'MEDIUM';
      case MatchConfidence.low:
        return 'LOW';
    }
  }
}
