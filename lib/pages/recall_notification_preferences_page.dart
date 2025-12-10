/// Recall Notification Preferences Page
/// Allows users to configure what recall updates they want to be notified about.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_update.dart';
import '../providers/data_providers.dart';
import '../providers/service_providers.dart';

class RecallNotificationPreferencesPage extends ConsumerStatefulWidget {
  const RecallNotificationPreferencesPage({super.key});

  @override
  ConsumerState<RecallNotificationPreferencesPage> createState() =>
      _RecallNotificationPreferencesPageState();
}

class _RecallNotificationPreferencesPageState
    extends ConsumerState<RecallNotificationPreferencesPage> {
  NotificationPreferences? _prefs;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Notifications'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: prefsAsync.when(
        data: (prefs) {
          _prefs ??= prefs;
          return _buildPreferencesForm(isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Unable to load preferences'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(notificationPreferencesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesForm(bool isDark) {
    if (_prefs == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Channels Section
        _buildSectionHeader('Notification Channels', isDark),
        _buildSwitchTile(
          'Push Notifications',
          'Receive push notifications on your device',
          _prefs!.pushEnabled,
          (value) => _updatePrefs(_prefs!.copyWith(pushEnabled: value)),
          Icons.notifications_active,
          isDark,
        ),
        _buildSwitchTile(
          'Email Notifications',
          'Receive email notifications',
          _prefs!.emailEnabled,
          (value) => _updatePrefs(_prefs!.copyWith(emailEnabled: value)),
          Icons.email_outlined,
          isDark,
        ),
        if (_prefs!.emailEnabled)
          _buildSwitchTile(
            'Daily Digest Only',
            'Receive one daily email instead of immediate notifications',
            _prefs!.emailDigestOnly,
            (value) => _updatePrefs(_prefs!.copyWith(emailDigestOnly: value)),
            Icons.schedule,
            isDark,
            indent: true,
          ),

        const SizedBox(height: 24),

        // Update Types Section
        _buildSectionHeader('What to Notify About', isDark),
        _buildSwitchTile(
          'Remedy Available',
          'When a fix or remedy becomes available',
          _prefs!.notifyRemedyAvailable,
          (value) => _updatePrefs(_prefs!.copyWith(notifyRemedyAvailable: value)),
          Icons.check_circle_outline,
          isDark,
          highlightColor: Colors.green,
        ),
        _buildSwitchTile(
          'Risk Level Changes',
          'When the risk level is updated',
          _prefs!.notifyRiskLevelChanged,
          (value) => _updatePrefs(_prefs!.copyWith(notifyRiskLevelChanged: value)),
          Icons.warning_amber_outlined,
          isDark,
          highlightColor: Colors.orange,
        ),
        _buildSwitchTile(
          'Status Changes',
          'When the recall status is updated',
          _prefs!.notifyStatusChanged,
          (value) => _updatePrefs(_prefs!.copyWith(notifyStatusChanged: value)),
          Icons.sync,
          isDark,
        ),
        _buildSwitchTile(
          'Affected Products Expanded',
          'When more products are added to the recall',
          _prefs!.notifyAffectedProducts,
          (value) => _updatePrefs(_prefs!.copyWith(notifyAffectedProducts: value)),
          Icons.add_circle_outline,
          isDark,
        ),
        _buildSwitchTile(
          'Completion Rate Updates',
          'When the recall completion rate is updated',
          _prefs!.notifyCompletionRate,
          (value) => _updatePrefs(_prefs!.copyWith(notifyCompletionRate: value)),
          Icons.trending_up,
          isDark,
        ),
        _buildSwitchTile(
          'Description Updates',
          'When the recall description is updated',
          _prefs!.notifyDescriptionUpdated,
          (value) => _updatePrefs(_prefs!.copyWith(notifyDescriptionUpdated: value)),
          Icons.edit_outlined,
          isDark,
        ),

        const SizedBox(height: 24),

        // Scope Section
        _buildSectionHeader('Which Recalls to Track', isDark),
        _buildSwitchTile(
          'RMC Enrolled Recalls',
          'Recalls you\'re actively managing',
          _prefs!.notifyRmcEnrolled,
          (value) => _updatePrefs(_prefs!.copyWith(notifyRmcEnrolled: value)),
          Icons.assignment_outlined,
          isDark,
        ),
        _buildSwitchTile(
          'RecallMatch Items',
          'Recalls matched to your inventory items',
          _prefs!.notifyRecallmatch,
          (value) => _updatePrefs(_prefs!.copyWith(notifyRecallmatch: value)),
          Icons.link,
          isDark,
        ),
        _buildSwitchTile(
          'Saved Recalls',
          'Recalls you\'ve bookmarked',
          _prefs!.notifySavedRecalls,
          (value) => _updatePrefs(_prefs!.copyWith(notifySavedRecalls: value)),
          Icons.bookmark_outline,
          isDark,
        ),
        _buildSwitchTile(
          'SmartFilter Matches',
          'Recalls matching your SmartFilters',
          _prefs!.notifySmartfilterMatches,
          (value) => _updatePrefs(_prefs!.copyWith(notifySmartfilterMatches: value)),
          Icons.filter_list,
          isDark,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    bool isDark, {
    Color? highlightColor,
    bool indent = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 32 : 0),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (highlightColor ?? Colors.blue).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: highlightColor ?? (isDark ? Colors.blue.shade300 : Colors.blue),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          trailing: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: highlightColor ?? Colors.blue,
          ),
        ),
      ),
    );
  }

  void _updatePrefs(NotificationPreferences newPrefs) {
    setState(() {
      _prefs = newPrefs;
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    if (_prefs == null) return;

    setState(() => _isSaving = true);

    try {
      final service = ref.read(recallUpdateServiceProvider);
      final success = await service.updateNotificationPreferences(_prefs!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences saved')),
          );
          setState(() => _hasChanges = false);
          ref.invalidate(notificationPreferencesProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save preferences')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
