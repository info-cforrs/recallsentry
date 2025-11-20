import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main_navigation.dart';
import '../widgets/custom_back_button.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'auth_required_page.dart';

class EmailNotificationsPage extends StatefulWidget {
  const EmailNotificationsPage({super.key});

  @override
  State<EmailNotificationsPage> createState() => _EmailNotificationsPageState();
}

class _EmailNotificationsPageState extends State<EmailNotificationsPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  // General Notifications
  bool _allNotifications = true;

  // Recall Alerts
  bool _newRecalls = true;

  // App Features
  bool _newFeatures = true;
  bool _tipsAndTricks = false;

  // Marketing
  bool _promotionalOffers = false;
  bool _newsletters = false;

  // Recommendations and Rewards
  bool _replacementItemRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        if (mounted) {
          // Redirect to auth required page
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthRequiredPage(
                pageTitle: 'Email Notifications',
              ),
            ),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/preferences/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _allNotifications = data['notify_all'] ?? true;
            _newRecalls = data['notify_new_recalls'] ?? true;
            _replacementItemRecommendations = data['notify_replacement_recommendations'] ?? false;
            _newFeatures = data['notify_new_features'] ?? true;
            _tipsAndTricks = data['notify_tips_tricks'] ?? false;
            _promotionalOffers = data['notify_promotional'] ?? false;
            _newsletters = data['notify_newsletters'] ?? false;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load preferences');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(String field, bool value) async {
    setState(() => _isSaving = true);

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${AppConfig.apiBaseUrl}/notifications/preferences/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({field: value}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Preference saved'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to update preference');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D3547),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                        'assets/images/shield_logo4.png',
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
                  const SizedBox(width: 16),
                  const Text(
                    'Email Notifications',
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

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // General Notifications Section
                  _buildSectionHeader('General'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'All Notifications',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Enable or disable all email notifications',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _allNotifications,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _allNotifications = value;
                            });
                            _updatePreference('notify_all', value);
                          },
                          secondary: const Icon(
                            Icons.email,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recall Alerts Section
                  _buildSectionHeader('Recall Alerts'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'New Recalls',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Get notified about new product recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _newRecalls,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _newRecalls = value;
                            });
                            _updatePreference('notify_new_recalls', value);
                          },
                          secondary: const Icon(
                            Icons.new_releases,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recommendations and Rewards Section
                  _buildSectionHeader('Recommendations and Rewards'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Replacement Item Recommendations',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me with recommended replacement items',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _replacementItemRecommendations,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _replacementItemRecommendations = value;
                            });
                            _updatePreference('notify_replacement_recommendations', value);
                          },
                          secondary: const Icon(
                            Icons.shopping_bag,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Features Section
                  _buildSectionHeader('App Features'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'New Features',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Updates about new app features',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _newFeatures,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _newFeatures = value;
                            });
                            _updatePreference('notify_new_features', value);
                          },
                          secondary: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Tips & Tricks',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Helpful tips for using the app',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _tipsAndTricks,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _tipsAndTricks = value;
                            });
                            _updatePreference('notify_tips_tricks', value);
                          },
                          secondary: const Icon(
                            Icons.lightbulb,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Marketing Section
                  _buildSectionHeader('Marketing'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Promotional Offers',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Special deals and promotions',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _promotionalOffers,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _promotionalOffers = value;
                            });
                            _updatePreference('notify_promotional', value);
                          },
                          secondary: const Icon(
                            Icons.local_offer,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Newsletters',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Product safety news and updates',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _newsletters,
                          onChanged: _isSaving ? null : (value) {
                            setState(() {
                              _newsletters = value;
                            });
                            _updatePreference('notify_newsletters', value);
                          },
                          secondary: const Icon(
                            Icons.email,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.white54,
        currentIndex: 2,
        elevation: 8,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 2),
                ),
                (route) => false,
              );
              break;
          }
        },
        items: const [

          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        
        ],
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
}
