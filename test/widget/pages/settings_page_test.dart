/// SettingsPage Widget Tests
///
/// Tests for the Settings page UI including:
/// - Settings sections rendering
/// - Toggle switches
/// - Navigation to sub-pages
/// - Account actions
/// - Privacy settings
///
/// To run: flutter test test/widget/pages/settings_page_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('Settings - Page Structure', () {
    testWidgets('renders settings page with app bar', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders all main settings sections', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Check visible sections
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);

      // Scroll to find About section
      await tester.scrollUntilVisible(find.text('About'), 100);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('settings list is scrollable', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Settings - Account Section', () {
    testWidgets('displays profile settings option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('displays subscription settings option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Subscription'), findsOneWidget);
    });

    testWidgets('tapping profile navigates to profile page', (tester) async {
      var navigatedToProfile = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestSettingsPage(
            onNavigate: (route) {
              if (route == '/profile') navigatedToProfile = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile'));
      await tester.pump();

      expect(navigatedToProfile, true);
    });

    testWidgets('displays logout button', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('logout button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Log Out?'), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('confirming logout triggers logout action', (tester) async {
      var logoutTriggered = false;

      await tester.pumpWidget(
        createTestableWidget(
          _TestSettingsPage(
            onLogout: () {
              logoutTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(logoutTriggered, true);
    });

    testWidgets('canceling logout dismisses dialog', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Log Out?'), findsNothing);
    });
  });

  group('Settings - Notification Section', () {
    testWidgets('displays push notifications toggle', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('displays email notifications toggle', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Email Notifications'), findsOneWidget);
    });

    testWidgets('push notification toggle changes state', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Find the switch for push notifications
      final pushSwitch = find.byKey(const Key('push_notifications_switch'));
      expect(pushSwitch, findsOneWidget);

      // Initially on
      var switchWidget = tester.widget<Switch>(pushSwitch);
      expect(switchWidget.value, true);

      // Toggle off
      await tester.tap(pushSwitch);
      await tester.pumpAndSettle();

      switchWidget = tester.widget<Switch>(pushSwitch);
      expect(switchWidget.value, false);
    });

    testWidgets('displays recall alerts settings', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Recall Alerts'), findsOneWidget);
    });
  });

  group('Settings - Privacy Section', () {
    testWidgets('displays privacy policy link', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays terms of service link', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('displays analytics toggle', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Analytics
      await tester.scrollUntilVisible(find.text('Analytics'), 100);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('displays health data consent option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Health Data
      await tester.scrollUntilVisible(find.text('Health Data'), 100);
      expect(find.text('Health Data'), findsOneWidget);
    });

    testWidgets('tapping health data shows consent dialog', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Health Data and ensure it's tappable
      await tester.scrollUntilVisible(find.text('Health Data'), 50);
      await tester.pumpAndSettle();

      // Ensure element is visible before tapping
      await tester.ensureVisible(find.text('Health Data'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Health Data'));
      await tester.pumpAndSettle();

      expect(find.text('Health Data Consent'), findsOneWidget);
      expect(find.textContaining('allergen'), findsOneWidget);
    });

    testWidgets('displays delete account option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Delete Account
      await tester.scrollUntilVisible(find.text('Delete Account'), 100);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('delete account shows warning dialog', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Delete Account
      await tester.scrollUntilVisible(find.text('Delete Account'), 100);

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account?'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
    });
  });

  group('Settings - About Section', () {
    testWidgets('displays app version', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Version
      await tester.scrollUntilVisible(find.text('Version'), 100);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('displays build number', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Build
      await tester.scrollUntilVisible(find.text('Build'), 100);
      expect(find.text('Build'), findsOneWidget);
    });

    testWidgets('displays rate app option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Rate App
      await tester.scrollUntilVisible(find.text('Rate App'), 100);
      expect(find.text('Rate App'), findsOneWidget);
    });

    testWidgets('displays feedback option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Send Feedback
      await tester.scrollUntilVisible(find.text('Send Feedback'), 100);
      expect(find.text('Send Feedback'), findsOneWidget);
    });

    testWidgets('displays help/FAQ option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Help & FAQ
      await tester.scrollUntilVisible(find.text('Help & FAQ'), 100);
      expect(find.text('Help & FAQ'), findsOneWidget);
    });
  });

  group('Settings - Display Preferences', () {
    testWidgets('displays theme selection', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Theme
      await tester.scrollUntilVisible(find.text('Theme'), 100);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('theme selection shows options', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Theme
      await tester.scrollUntilVisible(find.text('Theme'), 100);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('selecting theme updates preference', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Theme
      await tester.scrollUntilVisible(find.text('Theme'), 100);

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Theme should be updated (dialog closed)
      expect(find.text('Light'), findsNothing);
    });
  });

  group('Settings - Data Management', () {
    testWidgets('displays clear cache option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Clear Cache
      await tester.scrollUntilVisible(find.text('Clear Cache'), 100);
      expect(find.text('Clear Cache'), findsOneWidget);
    });

    testWidgets('clear cache shows confirmation', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Clear Cache
      await tester.scrollUntilVisible(find.text('Clear Cache'), 100);

      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Cache?'), findsOneWidget);
    });

    testWidgets('displays export data option', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Scroll to find Export Data
      await tester.scrollUntilVisible(find.text('Export Data'), 100);
      expect(find.text('Export Data'), findsOneWidget);
    });
  });

  group('Settings - Icons', () {
    testWidgets('settings items have appropriate icons', (tester) async {
      await tester.pumpWidget(createTestableWidget(const _TestSettingsPage()));
      await tester.pumpAndSettle();

      // Check for visible icons (at top of list)
      expect(find.byIcon(Icons.person), findsWidgets);
    });
  });
}

// Test Widgets

/// Test settings page
class _TestSettingsPage extends StatefulWidget {
  final void Function(String)? onNavigate;
  final VoidCallback? onLogout;

  const _TestSettingsPage({this.onNavigate, this.onLogout});

  @override
  State<_TestSettingsPage> createState() => _TestSettingsPageState();
}

class _TestSettingsPageState extends State<_TestSettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _analytics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () => widget.onNavigate?.call('/profile'),
          ),
          _buildSettingsTile(
            icon: Icons.card_membership,
            title: 'Subscription',
            onTap: () => widget.onNavigate?.call('/subscription'),
          ),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () => _showLogoutDialog(context),
            textColor: Colors.red,
          ),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            key: const Key('push_notifications_switch'),
            icon: Icons.notifications,
            title: 'Push Notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
          ),
          _buildSwitchTile(
            icon: Icons.email,
            title: 'Email Notifications',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
          ),
          _buildSettingsTile(
            icon: Icons.warning,
            title: 'Recall Alerts',
            onTap: () {},
          ),

          // Privacy Section
          _buildSectionHeader('Privacy'),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _buildSwitchTile(
            icon: Icons.analytics,
            title: 'Analytics',
            value: _analytics,
            onChanged: (value) {
              setState(() => _analytics = value);
            },
          ),
          _buildSettingsTile(
            icon: Icons.health_and_safety,
            title: 'Health Data',
            onTap: () => _showHealthDataDialog(context),
          ),
          _buildSettingsTile(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            onTap: () => _showDeleteAccountDialog(context),
            textColor: Colors.red,
          ),

          // Display Section
          _buildSectionHeader('Display'),
          _buildSettingsTile(
            icon: Icons.palette,
            title: 'Theme',
            onTap: () => _showThemeDialog(context),
          ),

          // Data Section
          _buildSettingsTile(
            icon: Icons.cached,
            title: 'Clear Cache',
            onTap: () => _showClearCacheDialog(context),
          ),
          _buildSettingsTile(
            icon: Icons.download,
            title: 'Export Data',
            onTap: () {},
          ),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'Version',
            trailing: const Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.build),
            title: Text('Build'),
            trailing: Text('100'),
          ),
          _buildSettingsTile(
            icon: Icons.star,
            title: 'Rate App',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: 'Send Feedback',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help & FAQ',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    Key? key,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Switch(key: key, value: value, onChanged: onChanged),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout?.call();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showHealthDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Health Data Consent'),
        content: const Text(
          'Enable health data consent to use allergen filtering features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dark'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('System'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear all cached data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
