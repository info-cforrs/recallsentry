/// Consent Page for RecallSentry
///
/// GDPR Article 7 compliant consent collection with:
/// - Explicit opt-in checkboxes (not pre-ticked)
/// - Separation of required vs optional consent
/// - Clear descriptions of each data processing activity
/// - Links to full Privacy Policy and Terms of Service
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/consent_preferences.dart';
import '../services/consent_service.dart';
import 'intro_page2.dart';
import '../widgets/iphone_simulator.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  // Required consents
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

  // Optional consents (not pre-ticked per GDPR)
  bool _analyticsEnabled = false;
  bool _crashReportingEnabled = false;
  bool _gamificationEnabled = false;
  bool _pushNotificationsEnabled = false;

  bool _isSaving = false;

  bool get _canProceed => _termsAccepted && _privacyAccepted;

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveConsentAndProceed() async {
    if (!_canProceed) return;

    setState(() => _isSaving = true);

    try {
      final preferences = ConsentPreferences(
        termsOfServiceAccepted: _termsAccepted,
        privacyPolicyAccepted: _privacyAccepted,
        analyticsEnabled: _analyticsEnabled,
        crashReportingEnabled: _crashReportingEnabled,
        gamificationEnabled: _gamificationEnabled,
        pushNotificationsEnabled: _pushNotificationsEnabled,
        healthDataConsentGiven: false, // Will be requested separately when needed
      );

      await ConsentService().savePreferences(preferences);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const IPhoneSimulator(child: IntroPage2()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _selectAll() {
    setState(() {
      _analyticsEnabled = true;
      _crashReportingEnabled = true;
      _gamificationEnabled = true;
      _pushNotificationsEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review and accept our terms to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Required Section
                      _buildSectionHeader(
                        'Required',
                        'You must accept these to use RecallSentry',
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      _buildConsentTile(
                        title: 'Terms of Service',
                        description:
                            'I agree to the Terms of Service governing use of RecallSentry',
                        value: _termsAccepted,
                        onChanged: (v) =>
                            setState(() => _termsAccepted = v ?? false),
                        linkText: 'Read Terms',
                        linkUrl: 'https://centerforrecallsafety.com/terms/',
                        isRequired: true,
                      ),

                      _buildConsentTile(
                        title: 'Privacy Policy',
                        description:
                            'I have read and accept the Privacy Policy explaining how my data is collected and used',
                        value: _privacyAccepted,
                        onChanged: (v) =>
                            setState(() => _privacyAccepted = v ?? false),
                        linkText: 'Read Policy',
                        linkUrl:
                            'https://centerforrecallsafety.com/privacy-policy/',
                        isRequired: true,
                      ),

                      const Divider(height: 32),

                      // Optional Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildSectionHeader(
                              'Optional',
                              'Help us improve your experience',
                              isRequired: false,
                            ),
                          ),
                          TextButton(
                            onPressed: _selectAll,
                            child: const Text('Select All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildConsentTile(
                        title: 'Usage Analytics',
                        description:
                            'Allow tracking of app usage (recalls viewed, searches) to enforce usage limits and improve the app',
                        value: _analyticsEnabled,
                        onChanged: (v) =>
                            setState(() => _analyticsEnabled = v ?? false),
                        icon: Icons.analytics_outlined,
                      ),

                      _buildConsentTile(
                        title: 'Crash Reporting',
                        description:
                            'Send crash reports to Firebase Crashlytics to help us fix bugs and improve stability',
                        value: _crashReportingEnabled,
                        onChanged: (v) =>
                            setState(() => _crashReportingEnabled = v ?? false),
                        icon: Icons.bug_report_outlined,
                      ),

                      _buildConsentTile(
                        title: 'Gamification Features',
                        description:
                            'Track your Safety Score, badges, and streaks. This records your daily logins and app interactions',
                        value: _gamificationEnabled,
                        onChanged: (v) =>
                            setState(() => _gamificationEnabled = v ?? false),
                        icon: Icons.emoji_events_outlined,
                      ),

                      _buildConsentTile(
                        title: 'Push Notifications',
                        description:
                            'Receive alerts about new recalls matching your filters. Requires sharing a device token with our servers',
                        value: _pushNotificationsEnabled,
                        onChanged: (v) => setState(
                            () => _pushNotificationsEnabled = v ?? false),
                        icon: Icons.notifications_outlined,
                      ),

                      const SizedBox(height: 16),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can change these preferences anytime in Settings > Privacy & Data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canProceed && !_isSaving
                          ? _saveConsentAndProceed
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canProceed ? Colors.white : Colors.grey.shade400,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  if (!_canProceed) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Please accept the required terms above',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle,
      {required bool isRequired}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isRequired ? Colors.red.shade700 : Colors.grey.shade800,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildConsentTile({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? linkText,
    String? linkUrl,
    IconData? icon,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isRequired && !value
              ? Colors.red.shade200
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            if (linkText != null && linkUrl != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _launchUrl(linkUrl),
                child: Text(
                  linkText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
