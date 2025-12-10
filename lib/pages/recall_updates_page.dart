/// Recall Updates Page
/// Shows all recall update notifications for the user.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/recall_update.dart';
import '../providers/data_providers.dart';
import '../providers/service_providers.dart';

class RecallUpdatesPage extends ConsumerStatefulWidget {
  const RecallUpdatesPage({super.key});

  @override
  ConsumerState<RecallUpdatesPage> createState() => _RecallUpdatesPageState();
}

class _RecallUpdatesPageState extends ConsumerState<RecallUpdatesPage> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(recallUpdateNotificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall Updates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllRead(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification settings',
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }
          return _buildNotificationList(notifications, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Unable to load notifications',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(recallUpdateNotificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No recall updates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When recalls you\'re tracking are updated, you\'ll see them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<RecallUpdateNotification> notifications, bool isDark) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recallUpdateNotificationsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, isDark);
        },
      ),
    );
  }

  Widget _buildNotificationCard(RecallUpdateNotification notification, bool isDark) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (_) => _markAsRead(notification.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: notification.isUnread ? 2 : 0,
        color: notification.isUnread
            ? (isDark ? Colors.grey.shade800 : Colors.white)
            : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
        child: InkWell(
          onTap: () => _openRecall(notification.recallId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Update type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getUpdateColor(notification.updateType).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getUpdateIcon(notification.updateType),
                    size: 20,
                    color: _getUpdateColor(notification.updateType),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getUpdateTitle(notification.updateType),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (notification.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Recall name
                      Text(
                        notification.recallName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Summary
                      Text(
                        notification.changeSummary,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Footer row
                      Row(
                        children: [
                          // Reason badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.reasonDisplay,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Time
                          Text(
                            dateFormat.format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUpdateTitle(String updateType) {
    switch (updateType) {
      case 'remedy_available':
        return 'Remedy Now Available';
      case 'risk_level_changed':
        return 'Risk Level Changed';
      case 'status_changed':
        return 'Status Updated';
      case 'completion_rate_updated':
        return 'Completion Rate Updated';
      case 'affected_products_expanded':
        return 'More Products Affected';
      case 'description_updated':
        return 'Information Updated';
      case 'dates_updated':
        return 'Dates Updated';
      default:
        return 'Recall Updated';
    }
  }

  IconData _getUpdateIcon(String updateType) {
    switch (updateType) {
      case 'remedy_available':
        return Icons.check_circle;
      case 'risk_level_changed':
        return Icons.warning_amber;
      case 'status_changed':
        return Icons.sync;
      case 'completion_rate_updated':
        return Icons.trending_up;
      case 'affected_products_expanded':
        return Icons.add_circle;
      case 'description_updated':
        return Icons.edit;
      case 'dates_updated':
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }

  Color _getUpdateColor(String updateType) {
    switch (updateType) {
      case 'remedy_available':
        return Colors.green;
      case 'risk_level_changed':
        return Colors.orange;
      case 'status_changed':
        return Colors.purple;
      case 'completion_rate_updated':
        return Colors.teal;
      case 'affected_products_expanded':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _markAsRead(int notificationId) async {
    final service = ref.read(recallUpdateServiceProvider);
    await service.markNotificationRead(notificationId);
    ref.invalidate(recallUpdateNotificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  void _markAllRead() async {
    final service = ref.read(recallUpdateServiceProvider);
    final count = await service.markAllNotificationsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked $count notifications as read')),
      );
    }
    ref.invalidate(recallUpdateNotificationsProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  void _openRecall(int recallId) {
    // Navigate to recall detail page
    // This will depend on your existing navigation setup
    Navigator.of(context).pop();
    // You may want to navigate to the recall detail page here
  }

  void _openSettings() {
    Navigator.of(context).pushNamed('/notification-preferences');
  }
}
