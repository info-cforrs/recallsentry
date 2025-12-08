/// Privacy & Data Settings Page
///
/// Allows users to manage their privacy consent preferences after onboarding.
/// Implements GDPR Article 7(3) - right to withdraw consent at any time.
///
/// Features:
/// - View and modify consent choices
/// - Export personal data (GDPR Article 20)
/// - Delete account (GDPR Article 17)
/// - View what data is collected
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/consent_preferences.dart';
import '../services/consent_service.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';

class PrivacyDataSettingsPage extends StatefulWidget {
  const PrivacyDataSettingsPage({super.key});

  @override
  State<PrivacyDataSettingsPage> createState() =>
      _PrivacyDataSettingsPageState();
}

class _PrivacyDataSettingsPageState extends State<PrivacyDataSettingsPage> {
  ConsentPreferences? _preferences;
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await ConsentService().getPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference({
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    bool? gamificationEnabled,
    bool? pushNotificationsEnabled,
    bool? healthDataConsentGiven,
  }) async {
    try {
      await ConsentService().updatePreference(
        analyticsEnabled: analyticsEnabled,
        crashReportingEnabled: crashReportingEnabled,
        gamificationEnabled: gamificationEnabled,
        pushNotificationsEnabled: pushNotificationsEnabled,
        healthDataConsentGiven: healthDataConsentGiven,
      );
      await _loadPreferences();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating preference: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to export your data')),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      final result = await UserProfileService().exportUserData();
      if (result.success && result.data != null) {
        final jsonString =
            const JsonEncoder.withIndent('  ').convert(result.data);

        if (mounted) {
          // Show data in a dialog with copy option
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Your Data Export'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: SelectableText(
                          jsonString,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap "Copy" to copy your data to clipboard',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Data copied to clipboard')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please log in to delete your account')),
        );
      }
      return;
    }

    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is permanent and cannot be undone. All your data will be deleted including:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text('- Your profile and account'),
            const Text('- All saved recalls and filters'),
            const Text('- RMC enrollments'),
            const Text('- Usage history and gamification data'),
            const SizedBox(height: 16),
            const Text(
              'Please enter your password to confirm:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty && mounted) {
      setState(() => _isDeleting = true);
      try {
        final result = await UserProfileService().deleteAccount(
          password: passwordController.text,
        );
        if (mounted) {
          if (result.success) {
            // Clear consent preferences
            await ConsentService().clearConsent();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to home/login
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
    passwordController.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        foregroundColor: Colors.white,
        title: const Text('Privacy & Data'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                Card(
                  color: Colors.blue.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade200, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage how your data is collected and used. Changes take effect immediately.',
                            style: TextStyle(
                              color: Colors.blue.shade100,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Data Collection Consents
                _buildSectionHeader('Data Collection'),
                Card(
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildConsentSwitch(
                        title: 'Usage Analytics',
                        subtitle:
                            'Track app usage for rate limiting and improvement',
                        icon: Icons.analytics_outlined,
                        value: _preferences?.analyticsEnabled ?? false,
                        onChanged: (v) =>
                            _updatePreference(analyticsEnabled: v),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      _buildConsentSwitch(
                        title: 'Crash Reporting',
                        subtitle:
                            'Send crash reports to Firebase Crashlytics',
                        icon: Icons.bug_report_outlined,
                        value: _preferences?.crashReportingEnabled ?? false,
                        onChanged: (v) =>
                            _updatePreference(crashReportingEnabled: v),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      _buildConsentSwitch(
                        title: 'Gamification',
                        subtitle:
                            'Track Safety Score, badges, and daily streaks',
                        icon: Icons.emoji_events_outlined,
                        value: _preferences?.gamificationEnabled ?? false,
                        onChanged: (v) =>
                            _updatePreference(gamificationEnabled: v),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      _buildConsentSwitch(
                        title: 'Push Notifications',
                        subtitle: 'Receive recall alerts via push notifications',
                        icon: Icons.notifications_outlined,
                        value: _preferences?.pushNotificationsEnabled ?? false,
                        onChanged: (v) =>
                            _updatePreference(pushNotificationsEnabled: v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Health Data (Special Category)
                _buildSectionHeader('Health Data (Special Category)'),
                Card(
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildConsentSwitch(
                        title: 'Allergy Preferences',
                        subtitle:
                            'Store allergy data for allergen recall alerts. This is health-related data protected under GDPR Article 9.',
                        icon: Icons.health_and_safety_outlined,
                        value: _preferences?.healthDataConsentGiven ?? false,
                        onChanged: (v) =>
                            _updatePreference(healthDataConsentGiven: v),
                        isHealthData: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Your Data Rights
                _buildSectionHeader('Your Data Rights'),
                Card(
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: _isExporting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_outlined,
                                color: Colors.white70),
                        title: const Text(
                          'Export My Data',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Download all your personal data (GDPR Article 20)',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.white70),
                        onTap: _isExporting ? null : _exportData,
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      ListTile(
                        leading: _isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined,
                                color: Colors.red),
                        title: const Text(
                          'Delete My Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Permanently delete all your data (GDPR Article 17)',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.white70),
                        onTap: _isDeleting ? null : _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal Documents
                _buildSectionHeader('Legal Documents'),
                Card(
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined,
                            color: Colors.white70),
                        title: const Text(
                          'Privacy Policy',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.open_in_new,
                            size: 16, color: Colors.white70),
                        onTap: () => _launchUrl(
                            'https://centerforrecallsafety.com/privacy-policy/'),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      ListTile(
                        leading: const Icon(Icons.description_outlined,
                            color: Colors.white70),
                        title: const Text(
                          'Terms of Service',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(Icons.open_in_new,
                            size: 16, color: Colors.white70),
                        onTap: () => _launchUrl(
                            'https://centerforrecallsafety.com/terms/'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Consent timestamp
                if (_preferences?.consentTimestamp != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Last updated: ${_formatDate(_preferences!.consentTimestamp!)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConsentSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isHealthData = false,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: isHealthData ? Colors.amber : Colors.white70,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (isHealthData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'Sensitive',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: value,
      activeTrackColor: const Color(0xFF64B5F6).withValues(alpha: 0.5),
      activeThumbColor: const Color(0xFF64B5F6),
      onChanged: onChanged,
    );
  }
}
