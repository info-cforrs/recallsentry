/// Recall Update Service
/// Handles API calls for recall updates, notifications, and preferences.
library;

import 'dart:convert';
import '../models/recall_update.dart';
import 'auth_service.dart';

class RecallUpdateService {
  static final RecallUpdateService _instance = RecallUpdateService._internal();
  factory RecallUpdateService() => _instance;
  RecallUpdateService._internal();

  /// Fetch updates for a specific recall
  Future<List<RecallUpdate>> getRecallUpdates(int recallId) async {
    try {
      final response = await AuthService().authenticatedRequest(
        'GET',
        '/recalls/$recallId/updates/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updates = jsonData['updates'] as List<dynamic>? ?? [];
        return updates
            .map((e) => RecallUpdate.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Fetch user's recall update notifications
  Future<List<RecallUpdateNotification>> getUserNotifications({
    String status = 'pending',
    int limit = 20,
  }) async {
    try {
      final response = await AuthService().authenticatedRequest(
        'GET',
        '/notifications/recall-updates/?status=$status&limit=$limit',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final notifications = jsonData['notifications'] as List<dynamic>? ?? [];
        return notifications
            .map((e) => RecallUpdateNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await AuthService().authenticatedRequest(
        'GET',
        '/notifications/recall-updates/?status=pending&limit=1',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark a notification as read
  Future<bool> markNotificationRead(int notificationId) async {
    try {
      final response = await AuthService().authenticatedRequest(
        'POST',
        '/notifications/recall-updates/$notificationId/read/',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllNotificationsRead() async {
    try {
      final response = await AuthService().authenticatedRequest(
        'POST',
        '/notifications/recall-updates/mark-all-read/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['marked_read'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get user's notification preferences
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final response = await AuthService().authenticatedRequest(
        'GET',
        '/notifications/update-preferences/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return NotificationPreferences.fromJson(jsonData);
      }
      return NotificationPreferences();
    } catch (e) {
      return NotificationPreferences();
    }
  }

  /// Update user's notification preferences
  Future<bool> updateNotificationPreferences(NotificationPreferences prefs) async {
    try {
      final response = await AuthService().authenticatedRequest(
        'PUT',
        '/notifications/update-preferences/',
        body: prefs.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get recalls the user is tracking that have recent updates
  Future<List<RecallWithUpdates>> getRecallsWithUpdates({int days = 30}) async {
    try {
      final response = await AuthService().authenticatedRequest(
        'GET',
        '/recalls/with-updates/?days=$days',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final recalls = jsonData['recalls_with_updates'] as List<dynamic>? ?? [];
        return recalls
            .map((e) => RecallWithUpdates.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Check if a specific recall has recent updates (last 30 days)
  Future<bool> hasRecentUpdates(int recallId) async {
    final updates = await getRecallUpdates(recallId);
    if (updates.isEmpty) return false;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return updates.any((u) => u.detectedAt.isAfter(thirtyDaysAgo));
  }
}
