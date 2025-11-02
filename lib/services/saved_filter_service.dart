import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/saved_filter.dart';
import 'auth_service.dart';

/// Service for managing saved filter presets via API
/// Integrates with backend /api/saved-filters/ endpoint
class SavedFilterService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

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

      print('🔍 Fetching saved filters from: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        print('✅ Successfully fetched ${results.length} saved filters');

        return results
            .map((json) => SavedFilter.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - user not logged in');
        throw Exception('Please log in to access saved filters');
      } else {
        print('❌ Error fetching saved filters: ${response.statusCode}');
        throw Exception('Failed to load saved filters: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching saved filters: $e');
      rethrow;
    }
  }

  /// Create a new saved filter
  /// POST /api/saved-filters/
  Future<SavedFilter> createSavedFilter({
    required String name,
    required String description,
    required List<String> brandFilters,
    required List<String> productFilters,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/');

      final body = json.encode({
        'name': name,
        'description': description,
        'filter_data': {
          'brand_filters': brandFilters,
          'product_filters': productFilters,
        },
      });

      print('📤 Creating saved filter: $name');

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully created saved filter: $name');
        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 403) {
        final errorData = json.decode(response.body);
        print('❌ Tier limit reached: ${errorData['error']}');
        throw TierLimitException(errorData['error']);
      } else if (response.statusCode == 401) {
        throw Exception('Please log in to save filters');
      } else {
        print('❌ Error creating saved filter: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception(
            'Failed to create saved filter: ${errorBody['error'] ?? response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception creating saved filter: $e');
      rethrow;
    }
  }

  /// Update an existing saved filter
  /// PUT /api/saved-filters/{id}/
  Future<SavedFilter> updateSavedFilter({
    required int id,
    required String name,
    required String description,
    required List<String> brandFilters,
    required List<String> productFilters,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/');

      final body = json.encode({
        'name': name,
        'description': description,
        'filter_data': {
          'brand_filters': brandFilters,
          'product_filters': productFilters,
        },
      });

      print('📝 Updating saved filter ID: $id');

      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully updated saved filter: $name');
        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Please log in to update filters');
      } else if (response.statusCode == 404) {
        throw Exception('Filter not found');
      } else {
        print('❌ Error updating saved filter: ${response.statusCode}');
        throw Exception('Failed to update saved filter: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception updating saved filter: $e');
      rethrow;
    }
  }

  /// Delete a saved filter
  /// DELETE /api/saved-filters/{id}/
  Future<void> deleteSavedFilter(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/');

      print('🗑️ Deleting saved filter ID: $id');

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 204) {
        print('✅ Successfully deleted saved filter ID: $id');
      } else if (response.statusCode == 401) {
        throw Exception('Please log in to delete filters');
      } else if (response.statusCode == 404) {
        throw Exception('Filter not found');
      } else {
        print('❌ Error deleting saved filter: ${response.statusCode}');
        throw Exception('Failed to delete saved filter: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception deleting saved filter: $e');
      rethrow;
    }
  }

  /// Apply a saved filter (marks as used)
  /// POST /api/saved-filters/{id}/apply/
  Future<SavedFilter> applySavedFilter(int id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/saved-filters/$id/apply/');

      print('⚡ Applying saved filter ID: $id');

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully applied saved filter ID: $id');
        return SavedFilter.fromJson(jsonData as Map<String, dynamic>);
      } else if (response.statusCode == 401) {
        throw Exception('Please log in to apply filters');
      } else if (response.statusCode == 404) {
        throw Exception('Filter not found');
      } else {
        print('❌ Error applying saved filter: ${response.statusCode}');
        throw Exception('Failed to apply saved filter: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception applying saved filter: $e');
      rethrow;
    }
  }
}

/// Exception thrown when user reaches tier limit for saved filters
class TierLimitException implements Exception {
  final String message;
  TierLimitException(this.message);

  @override
  String toString() => message;
}
