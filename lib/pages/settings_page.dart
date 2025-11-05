import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_profile.dart';
import 'subscribe_page.dart';
import 'report_illness_page.dart';
import 'share_app_page.dart';
import 'main_navigation.dart';
import 'app_usage_page.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import 'push_notifications_page.dart';
import 'email_notifications_page.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/custom_back_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _locationEnabled = true;
  UserProfile? _userProfile;
  bool _isLoadingProfile = false;
  SubscriptionTier _subscriptionTier = SubscriptionTier.guest;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSubscriptionTier();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    final profile = await UserProfileService().getUserProfile();

    if (profile != null && mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadSubscriptionTier() async {
    final info = await SubscriptionService().getSubscriptionInfo();
    if (mounted) {
      setState(() {
        _subscriptionTier = info.tier;
      });
    }
  }

  bool get _isLoggedIn {
    return _subscriptionTier != SubscriptionTier.guest;
  }

  void _showLoginSignupModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Sign In Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please sign in or create an account to track your app usage statistics.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white70, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Custom Header with App Icon and Settings Text (matching Home page)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  const SizedBox(width: 8),
                  // App Icon - Clickable to return to Home
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainNavigation(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/shield_logo3.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // 10px spacing as in Home page
                  // Settings Text
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Atlanta',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Profile section
            _buildSectionHeader('Profile'),
            Card(
              elevation: 2,
              color: const Color(
                0xFF2A4A5C,
              ), // Slightly lighter than background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: _userProfile != null
                          ? Text(
                              _userProfile!.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      _userProfile?.fullName ?? 'Guest User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _userProfile?.email ?? 'Not logged in',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UserProfilePage(),
                        ),
                      );
                      // Reload profile when returning from profile page
                      _loadUserProfile();
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.white70),
                    title: const Text(
                      'Subscriptions',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscribePage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.login, color: Colors.white70),
                    title: const Text(
                      'Log In',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.white70),
                    title: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: Icon(
                      Icons.bar_chart,
                      color: _isLoggedIn ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      'App Usage',
                      style: TextStyle(
                        color: _isLoggedIn ? Colors.white : Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _isLoggedIn ? Colors.white70 : Colors.black54,
                    ),
                    tileColor: _isLoggedIn ? null : const Color(0xFFD1D1D1),
                    onTap: () {
                      if (_isLoggedIn) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AppUsagePage(),
                          ),
                        );
                      } else {
                        _showLoginSignupModal(context);
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.white70),
                    title: const Text(
                      'Report Illness',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReportIllnessPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white70),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      _showSignOutDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preferences section
            _buildSectionHeader('Preferences'),
            Card(
              elevation: 2,
              color: const Color(
                0xFF2A4A5C,
              ), // Slightly lighter than background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Push Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PushNotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Email Notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailNotificationsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  SwitchListTile(
                    title: const Text(
                      'Location Services',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                    },
                    secondary: const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                    ),
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General section
            _buildSectionHeader('General'),
            Card(
              elevation: 2,
              color: const Color(
                0xFF2A4A5C,
              ), // Slightly lighter than background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url =
                          'https://centerforrecallsafety.com/privacy-policy/';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Terms of Service',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url = 'https://centerforrecallsafety.com/terms/';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.white70),
                    title: const Text(
                      'Share App',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ShareAppPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Support section
            _buildSectionHeader('Support'),
            Card(
              elevation: 2,
              color: const Color(
                0xFF2A4A5C,
              ), // Slightly lighter than background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Help Center',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.feedback, color: Colors.white70),
                    title: const Text(
                      'Contact Us',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url = 'https://centerforrecallsafety.com/contact/';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.quiz, color: Colors.white70),
                    title: const Text(
                      'FAQs',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url = 'https://centerforrecallsafety.com/faqs/';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'About',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url = 'https://centerforrecallsafety.com/about/';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.tag, color: Colors.white70),
                    title: const Text(
                      'Version',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Text(
                      'v0.1',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: null, // No action needed for version
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Follow Us section
            _buildSectionHeader('Follow Us'),
            Card(
              elevation: 2,
              color: const Color(
                0xFF2A4A5C,
              ), // Slightly lighter than background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.alternate_email,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Twitter',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Instagram',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.facebook, color: Colors.white70),
                    title: const Text(
                      'Facebook',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.business, color: Colors.white70),
                    title: const Text(
                      'LinkedIn',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.white70),
                    title: const Text(
                      'Website',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () async {
                      const url = 'https://www.centerforrecallsafety.com';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();

                // Perform logout
                await AuthService().logout();
                SubscriptionService().clearCache();

                // Show success message
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Successfully signed out'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Navigate to home and refresh
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
