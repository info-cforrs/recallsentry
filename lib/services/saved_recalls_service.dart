import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/recall_data.dart';
import '../config/app_config.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'usage_service.dart';
import 'subscription_service.dart';
import 'gamification_service.dart';

/// Exception thrown when saved recalls limit is reached
class SavedRecallsLimitException implements Exception {
  final String message;
  final int currentCount;
  final int limit;
  final SubscriptionTier currentTier;

  SavedRecallsLimitException({
    required this.message,
    required this.currentCount,
    required this.limit,
    required this.currentTier,
  });

  @override
  String toString() => message;
}

class SavedRecallsService {
  static const String _savedRecallsKey = 'saved_recalls';
  final AuthService _authService = AuthService();
  final UsageService _usageService = UsageService();
  final GamificationService _gamificationService = GamificationService();
  final String baseUrl = AppConfig.apiBaseUrl;
  final _secureStorage = const FlutterSecureStorage();

  /// SECURITY: Validate recall_id format before sending to API
  /// Allows alphanumeric characters, hyphens, underscores, and periods
  /// Max length 100 characters to prevent abuse
  static final RegExp _recallIdPattern = RegExp(r'^[A-Za-z0-9\-_.]{1,100}$');

  /// Validates that a recall ID has a safe format
  bool _isValidRecallId(String id) {
    if (id.isEmpty || id.length > 100) return false;
    return _recallIdPattern.hasMatch(id);
  }

  // Get all saved recalls
  Future<List<RecallData>> getSavedRecalls() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();

      if (!isLoggedIn) {
        // Fall back to local storage if not logged in
        return _getLocalSavedRecalls();
      }

      // Fetch from API
      final response = await _authService.authenticatedRequest(
        'GET',
        '/saved-recalls/',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Use ApiUtils to extract results list
        final List<dynamic> jsonList = ApiUtils.extractResultsList(responseData);

        final recalls = jsonList.map((json) {
          // The API returns the recall data nested in 'recall' field
          final recallJson = json['recall'];
          return RecallData.fromJson(recallJson);
        }).toList();

        return recalls;
      } else {
        return _getLocalSavedRecalls();
      }
    } catch (e) {
      // Fall back to local storage on error
      return _getLocalSavedRecalls();
    }
  }

  // Get saved recalls from local storage (fallback)
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<List<RecallData>> _getLocalSavedRecalls() async {
    try {
      final String? savedRecallsJson = await _secureStorage.read(key: _savedRecallsKey);

      if (savedRecallsJson == null) {
        return [];
      }

      final List<dynamic> savedRecallsList = jsonDecode(savedRecallsJson);
      return savedRecallsList.map((json) => RecallData.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save a recall
  Future<bool> saveRecall(RecallData recall) async {
    try {
      // SECURITY: Validate recall_id format before processing
      if (!_isValidRecallId(recall.id)) {
        throw Exception('Invalid recall ID format');
      }

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
        // Clear usage cache to force refresh
        _usageService.clearCache();
        // Record gamification action (updates SafetyScore)
        await _gamificationService.recordAction(GamificationService.actionSaveRecall);
        // Also save locally for offline access
        await _saveRecallLocally(recall);
        return true;
      } else if (response.statusCode == 400) {
        // Likely already saved
        return true;
      } else {
        // If authentication failed, fall back to local storage
        return _saveRecallLocally(recall);
      }
    } catch (e) {
      return _saveRecallLocally(recall);
    }
  }

  // Save recall to local storage
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<bool> _saveRecallLocally(RecallData recall) async {
    try {
      final savedRecalls = await _getLocalSavedRecalls();

      // Check if already saved
      if (savedRecalls.any((saved) => saved.id == recall.id)) {
        return true;
      }

      // Check saved recalls limit based on subscription tier
      final subscriptionService = SubscriptionService();
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
      final limit = subscriptionInfo.getSavedRecallsLimit();

      // Enforce limit (only for new saves, not existing)
      if (savedRecalls.length >= limit) {
        throw SavedRecallsLimitException(
          message: 'You have reached your saved recalls limit of $limit. Upgrade your plan to save more recalls.',
          currentCount: savedRecalls.length,
          limit: limit,
          currentTier: subscriptionInfo.tier,
        );
      }

      // Add to saved list
      savedRecalls.add(recall);

      // Save to FlutterSecureStorage (encrypted)
      final String savedRecallsJson = jsonEncode(
        savedRecalls.map((r) => r.toJson()).toList(),
      );

      await _secureStorage.write(
        key: _savedRecallsKey,
        value: savedRecallsJson,
      );

      return true;
    } on SavedRecallsLimitException {
      rethrow; // Re-throw limit exception for UI to handle
    } catch (e) {
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
        final responseData = jsonDecode(response.body);

        // Use ApiUtils to extract results list
        final List<dynamic> jsonList = ApiUtils.extractResultsList(responseData);

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
            // Clear usage cache to force refresh
            _usageService.clearCache();
            // Clear gamification cache (SafetyScore will update on next fetch)
            _gamificationService.clearCache();
            // Also remove locally
            await _removeRecallLocally(recallId);
            return true;
          } else {
            return _removeRecallLocally(recallId);
          }
        } else {
          return _removeRecallLocally(recallId);
        }
      } else {
        return _removeRecallLocally(recallId);
      }
    } catch (e) {
      return _removeRecallLocally(recallId);
    }
  }

  // Remove recall from local storage
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<bool> _removeRecallLocally(String recallId) async {
    try {
      final savedRecalls = await _getLocalSavedRecalls();

      // Remove from list
      savedRecalls.removeWhere((recall) => recall.id == recallId);

      // Save updated list to FlutterSecureStorage (encrypted)
      final String savedRecallsJson = jsonEncode(
        savedRecalls.map((r) => r.toJson()).toList(),
      );

      await _secureStorage.write(
        key: _savedRecallsKey,
        value: savedRecallsJson,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if a recall is saved
  Future<bool> isRecallSaved(String recallId) async {
    try {
      final savedRecalls = await getSavedRecalls();
      return savedRecalls.any((recall) => recall.id == recallId);
    } catch (e) {
      return false;
    }
  }

  // Clear all saved recalls
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<bool> clearAllSavedRecalls() async {
    try {
      await _secureStorage.delete(key: _savedRecallsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clean up saved recalls older than 6 months
  /// Should be called on app initialization
  /// Returns the number of recalls removed
  Future<int> cleanupOldSavedRecalls() async {
    try {
      final savedRecalls = await _getLocalSavedRecalls();
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

      // Filter out recalls older than 6 months
      final beforeCount = savedRecalls.length;
      final cleanedRecalls = savedRecalls.where((recall) {
        return recall.dateIssued.isAfter(sixMonthsAgo);
      }).toList();

      // Only update storage if we actually removed recalls
      final removedCount = beforeCount - cleanedRecalls.length;
      if (removedCount > 0) {
        final String savedRecallsJson = jsonEncode(
          cleanedRecalls.map((r) => r.toJson()).toList(),
        );

        await _secureStorage.write(
          key: _savedRecallsKey,
          value: savedRecallsJson,
        );
      }

      return removedCount;
    } catch (e) {
      return 0;
    }
  }
}
