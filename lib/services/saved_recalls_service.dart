import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recall_data.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'usage_service.dart';

class SavedRecallsService {
  static const String _savedRecallsKey = 'saved_recalls';
  final AuthService _authService = AuthService();
  final UsageService _usageService = UsageService();
  final String baseUrl = AppConfig.apiBaseUrl;

  // Get all saved recalls
  Future<List<RecallData>> getSavedRecalls() async {
    try {
      // Check if user is logged in
      print('🔍 SavedRecallsService.getSavedRecalls() called');
      final isLoggedIn = await _authService.isLoggedIn();
      print('   isLoggedIn: $isLoggedIn');

      if (!isLoggedIn) {
        // Fall back to local storage if not logged in
        print('   ⚠️ User not logged in, using local storage');
        return _getLocalSavedRecalls();
      }

      // Fetch from API
      print('   📡 Fetching from API: /saved-recalls/');
      final response = await _authService.authenticatedRequest(
        'GET',
        '/saved-recalls/',
      );
      print('   API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('   Response data type: ${responseData.runtimeType}');

        // Handle paginated response
        final List<dynamic> jsonList = responseData is List
            ? responseData
            : (responseData['results'] ?? []);
        print('   📊 Got ${jsonList.length} saved recalls from API');

        final recalls = jsonList.map((json) {
          // The API returns the recall data nested in 'recall' field
          final recallJson = json['recall'];
          return RecallData.fromJson(recallJson);
        }).toList();

        print('   ✅ Returning ${recalls.length} saved recalls');
        return recalls;
      } else {
        print('❌ Failed to fetch saved recalls from API: ${response.statusCode}');
        print('   Response body: ${response.body}');
        return _getLocalSavedRecalls();
      }
    } catch (e) {
      print('❌ Error getting saved recalls from API: $e');
      // Fall back to local storage on error
      return _getLocalSavedRecalls();
    }
  }

  // Get saved recalls from local storage (fallback)
  Future<List<RecallData>> _getLocalSavedRecalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedRecallsJson = prefs.getString(_savedRecallsKey);

      if (savedRecallsJson == null) {
        return [];
      }

      final List<dynamic> savedRecallsList = jsonDecode(savedRecallsJson);
      return savedRecallsList.map((json) => RecallData.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting local saved recalls: $e');
      return [];
    }
  }

  // Save a recall
  Future<bool> saveRecall(RecallData recall) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();

      if (!isLoggedIn) {
        // Fall back to local storage if not logged in
        return _saveRecallLocally(recall);
      }

      // First, we need to find the database ID for this recall
      // The API uses the recall's string ID (like "USDA-034-2025-R1-1000-S")
      // to look up and save the recall
      final response = await _authService.authenticatedRequest(
        'POST',
        '/saved-recalls/',
        body: {
          'recall_id': recall.id,  // This is the recall_id string
        },
      );

      if (response.statusCode == 201) {
        print('✅ Saved recall to API: ${recall.id} - ${recall.productName}');
        // Clear usage cache to force refresh
        _usageService.clearCache();
        // Also save locally for offline access
        await _saveRecallLocally(recall);
        return true;
      } else if (response.statusCode == 400) {
        // Likely already saved
        print('ℹ️ Recall ${recall.id} already saved on server');
        return true;
      } else {
        print('❌ Failed to save recall to API: ${response.statusCode}');
        print('❌ API Response: ${response.body}');
        // If authentication failed, fall back to local storage
        return _saveRecallLocally(recall);
      }
    } catch (e) {
      print('❌ Error saving recall to API: $e');
      return _saveRecallLocally(recall);
    }
  }

  // Save recall to local storage
  Future<bool> _saveRecallLocally(RecallData recall) async {
    try {
      final savedRecalls = await _getLocalSavedRecalls();

      // Check if already saved
      if (savedRecalls.any((saved) => saved.id == recall.id)) {
        print('ℹ️ Recall ${recall.id} already saved locally');
        return true;
      }

      // Add to saved list
      savedRecalls.add(recall);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String savedRecallsJson = jsonEncode(
        savedRecalls.map((r) => r.toJson()).toList(),
      );

      final bool success = await prefs.setString(
        _savedRecallsKey,
        savedRecallsJson,
      );

      if (success) {
        print('✅ Saved recall locally: ${recall.id} - ${recall.productName}');
      }

      return success;
    } catch (e) {
      print('❌ Error saving recall locally: $e');
      return false;
    }
  }

  // Remove a saved recall
  Future<bool> removeSavedRecall(String recallId) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();

      if (!isLoggedIn) {
        // Fall back to local storage if not logged in
        return _removeRecallLocally(recallId);
      }

      // First get the saved recalls to find the database ID
      final response = await _authService.authenticatedRequest(
        'GET',
        '/saved-recalls/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);

        // Find the saved recall with matching recall_id
        final savedRecall = jsonList.firstWhere(
          (json) => json['recall']['recall_id'] == recallId,
          orElse: () => null,
        );

        if (savedRecall != null) {
          final int savedRecallDbId = savedRecall['id'];

          // Delete from API
          final deleteResponse = await _authService.authenticatedRequest(
            'DELETE',
            '/saved-recalls/$savedRecallDbId/',
          );

          if (deleteResponse.statusCode == 204) {
            print('✅ Removed saved recall from API: $recallId');
            // Clear usage cache to force refresh
            _usageService.clearCache();
            // Also remove locally
            await _removeRecallLocally(recallId);
            return true;
          } else {
            print('❌ Failed to remove recall from API: ${deleteResponse.statusCode}');
            return _removeRecallLocally(recallId);
          }
        } else {
          print('ℹ️ Recall $recallId not found on server');
          return _removeRecallLocally(recallId);
        }
      } else {
        return _removeRecallLocally(recallId);
      }
    } catch (e) {
      print('❌ Error removing saved recall from API: $e');
      return _removeRecallLocally(recallId);
    }
  }

  // Remove recall from local storage
  Future<bool> _removeRecallLocally(String recallId) async {
    try {
      final savedRecalls = await _getLocalSavedRecalls();

      // Remove from list
      savedRecalls.removeWhere((recall) => recall.id == recallId);

      // Save updated list to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String savedRecallsJson = jsonEncode(
        savedRecalls.map((r) => r.toJson()).toList(),
      );

      final bool success = await prefs.setString(
        _savedRecallsKey,
        savedRecallsJson,
      );

      if (success) {
        print('✅ Removed saved recall locally: $recallId');
      }

      return success;
    } catch (e) {
      print('❌ Error removing saved recall locally: $e');
      return false;
    }
  }

  // Check if a recall is saved
  Future<bool> isRecallSaved(String recallId) async {
    try {
      final savedRecalls = await getSavedRecalls();
      return savedRecalls.any((recall) => recall.id == recallId);
    } catch (e) {
      print('❌ Error checking if recall is saved: $e');
      return false;
    }
  }

  // Clear all saved recalls
  Future<bool> clearAllSavedRecalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool success = await prefs.remove(_savedRecallsKey);

      if (success) {
        print('✅ Cleared all saved recalls');
      }

      return success;
    } catch (e) {
      print('❌ Error clearing saved recalls: $e');
      return false;
    }
  }
}
