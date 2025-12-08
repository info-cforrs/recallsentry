import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/saved_filter.dart';
import '../exceptions/api_exceptions.dart';
import 'auth_service.dart';
import 'gamification_service.dart';

/// Service for managing saved filter presets via API
/// Integrates with backend /api/saved-filters/ endpoint
class SavedFilterService {
  // Singleton pattern - ensures all SavedFilterService() calls return the same instance
  static final SavedFilterService _instance = SavedFilterService._internal();
  factory SavedFilterService() => _instance;

  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

  SavedFilterService._internal();

  /// Sanitize user input before sending to API
  /// SECURITY: Defense-in-depth input validation
  String _sanitizeInput(String input) {
    // Trim whitespace
    String sanitized = input.trim();

    // Remove leading/trailing special characters
    sanitized = sanitized.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');

    // Limit consecutive spaces to single space
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    return sanitized;
  }

  /// Get authorization headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all saved filters for current user
  /// GET /api/saved-filters/
  Future<List<SavedFilter>> fetchSavedFilters() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        return results
            .map((json) => SavedFilter.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw AuthException(
          'Please log in to access saved filters',
          statusCode: 401,
          shouldLogout: true,
        );
      } else {
        throw ApiException(
          'Failed to load saved filters',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to load saved filters',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Create a new saved filter
  /// POST /api/saved-filters/
  /// SECURITY: Validates and sanitizes all input before sending to API
  Future<SavedFilter> createSavedFilter({
    required String name,
    required String description,
    required List<String> brandFilters,
    required List<String> productFilters,
    List<String>? stateFilters,
    List<String>? allergenFilters,
  }) async {
    // Validate input lengths
    if (name.trim().isEmpty) {
      throw ValidationException('Filter name is required');
    }
    if (name.length > 50) {
      throw ValidationException('Filter name must be 50 characters or less');
    }
    if (description.length > 200) {
      throw ValidationException('Description must be 200 characters or less');
    }

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/');

      final body = json.encode({
        'name': _sanitizeInput(name),
        'description': _sanitizeInput(description),
        'filter_data': {
          'brand_filters': brandFilters.map((f) => _sanitizeInput(f)).toList(),
          'product_filters': productFilters.map((f) => _sanitizeInput(f)).toList(),
          // SECURITY: Apply sanitization to all filter arrays
          'state_filters': (stateFilters ?? []).map((f) => _sanitizeInput(f)).toList(),
          'allergen_filters': (allergenFilters ?? []).map((f) => _sanitizeInput(f)).toList(),
        },
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);

        // Record filter creation for gamification (non-blocking)
        GamificationService().recordAction(GamificationService.actionCreateFilter);

        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        throw TierLimitException(
          errorData['error'] ?? 'Filter limit reached - upgrade your plan',
        );
      } else if (response.statusCode == 401) {
        throw AuthException(
          'Please log in to save filters',
          statusCode: 401,
          shouldLogout: true,
        );
      } else {
        final errorBody = json.decode(response.body);
        throw ApiException(
          'Failed to create saved filter: ${errorBody['error'] ?? response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TierLimitException {
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to create saved filter',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Update an existing saved filter
  /// PUT /api/saved-filters/{id}/
  /// SECURITY: Validates and sanitizes all input before sending to API
  Future<SavedFilter> updateSavedFilter({
    required int id,
    required String name,
    required String description,
    required List<String> brandFilters,
    required List<String> productFilters,
  }) async {
    // Validate input lengths
    if (name.trim().isEmpty) {
      throw ValidationException('Filter name is required');
    }
    if (name.length > 50) {
      throw ValidationException('Filter name must be 50 characters or less');
    }
    if (description.length > 200) {
      throw ValidationException('Description must be 200 characters or less');
    }

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/');

      final body = json.encode({
        'name': _sanitizeInput(name),
        'description': _sanitizeInput(description),
        'filter_data': {
          'brand_filters': brandFilters.map((f) => _sanitizeInput(f)).toList(),
          'product_filters': productFilters.map((f) => _sanitizeInput(f)).toList(),
        },
      });

      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw AuthException('Please log in to update filters', statusCode: 401, shouldLogout: true);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Filter not found', resourceType: 'SavedFilter', resourceId: id.toString());
      } else {
        throw ApiException('Failed to update saved filter', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException('Failed to update saved filter', originalException: e, stackTrace: stack);
    }
  }

  /// Delete a saved filter
  /// DELETE /api/saved-filters/{id}/
  Future<void> deleteSavedFilter(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/');

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 204) {
        // Successfully deleted
      } else if (response.statusCode == 401) {
        throw AuthException('Please log in to delete filters', statusCode: 401, shouldLogout: true);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Filter not found', resourceType: 'SavedFilter', resourceId: id.toString());
      } else {
        throw ApiException('Failed to delete saved filter', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException('Failed to delete saved filter', originalException: e, stackTrace: stack);
    }
  }

  /// Apply a saved filter (marks as used)
  /// POST /api/saved-filters/{id}/apply/
  Future<SavedFilter> applySavedFilter(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/apply/');

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw AuthException('Please log in to apply filters', statusCode: 401, shouldLogout: true);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Filter not found', resourceType: 'SavedFilter', resourceId: id.toString());
      } else {
        throw ApiException('Failed to apply saved filter', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException('Failed to apply saved filter', originalException: e, stackTrace: stack);
    }
  }
}

/// Exception thrown when user reaches tier limit for saved filters
/// Kept for backward compatibility with existing catch blocks in UI code
class TierLimitException implements Exception {
  final String message;
  TierLimitException(this.message);

  @override
  String toString() => message;
}
