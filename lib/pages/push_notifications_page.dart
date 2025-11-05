import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../widgets/custom_back_button.dart';

class PushNotificationsPage extends StatefulWidget {
  const PushNotificationsPage({super.key});

  @override
  State<PushNotificationsPage> createState() => _PushNotificationsPageState();
}

class _PushNotificationsPageState extends State<PushNotificationsPage> {
  // General Notifications
  bool _allNotifications = true;

  // Recall Alerts
  bool _newRecalls = true;
  bool _recallUpdates = true;
  bool _savedRecallChanges = true;

  // App Features
  bool _newFeatures = true;
  bool _tipsAndTricks = false;

  // Marketing
  bool _promotionalOffers = false;
  bool _newsletters = false;

  // App Usage
  bool _savedRecallLimitReached = true;
  bool _appliedFiltersLimitReached = true;

  // Recall Updates
  bool _smartFilterRecallUpdates = true;
  bool _followedRecallUpdates = true;
  bool _brandFilterRecallUpdates = true;
  bool _productNameRecallUpdates = true;

  // Recommendations and Rewards
  bool _replacementItemRecommendations = true;
  bool _rewardMilestones = true;
  bool _safetyStreakGoals = true;
  bool _safetyScoreGoals = true;

  @override
  Widget build(BuildContext context) {
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
                        'assets/images/app_icon.png',
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
                    'Push Notifications',
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
                            'Enable or disable all push notifications',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _allNotifications,
                          onChanged: (value) {
                            setState(() {
                              _allNotifications = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.notifications,
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
                          onChanged: (value) {
                            setState(() {
                              _newRecalls = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.new_releases,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Recall Updates',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Updates to existing recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _recallUpdates,
                          onChanged: (value) {
                            setState(() {
                              _recallUpdates = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.update,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Saved Recall Changes',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Changes to recalls you\'ve saved',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _savedRecallChanges,
                          onChanged: (value) {
                            setState(() {
                              _savedRecallChanges = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.bookmark,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Usage Section
                  _buildSectionHeader('App Usage'),
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
                            'Saved Recall Limit Reached',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me when I reach my saved recall limit',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _savedRecallLimitReached,
                          onChanged: (value) {
                            setState(() {
                              _savedRecallLimitReached = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.bookmark_border,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Applied Filters Limit Reached',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me when I reach my applied filters limit',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _appliedFiltersLimitReached,
                          onChanged: (value) {
                            setState(() {
                              _appliedFiltersLimitReached = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.filter_alt,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recall Updates Section
                  _buildSectionHeader('Recall Updates'),
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
                            'SmartFilter Recall Updates',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me with updates on new SmartFilter recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _smartFilterRecallUpdates,
                          onChanged: (value) {
                            setState(() {
                              _smartFilterRecallUpdates = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.filter_list,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Followed Recall Updates',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me with updates on Followed recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _followedRecallUpdates,
                          onChanged: (value) {
                            setState(() {
                              _followedRecallUpdates = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.follow_the_signs,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Brand Filter Recall Updates',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me with updates on Brand filter recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _brandFilterRecallUpdates,
                          onChanged: (value) {
                            setState(() {
                              _brandFilterRecallUpdates = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.branding_watermark,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Product Name Recall Updates',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me with updates on Product Name recalls',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _productNameRecallUpdates,
                          onChanged: (value) {
                            setState(() {
                              _productNameRecallUpdates = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.label,
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
                          onChanged: (value) {
                            setState(() {
                              _replacementItemRecommendations = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.shopping_bag,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Reward Milestones',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me when reaching Reward milestones',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _rewardMilestones,
                          onChanged: (value) {
                            setState(() {
                              _rewardMilestones = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.emoji_events,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Safety Streak Goals',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me when I reach a Safety Streak goal',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _safetyStreakGoals,
                          onChanged: (value) {
                            setState(() {
                              _safetyStreakGoals = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white70,
                          ),
                          activeThumbColor: Colors.green,
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            'Safety Score Goals',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            'Notify me when I reach a Safety Score goal',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: _safetyScoreGoals,
                          onChanged: (value) {
                            setState(() {
                              _safetyScoreGoals = value;
                            });
                          },
                          secondary: const Icon(
                            Icons.score,
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
                          onChanged: (value) {
                            setState(() {
                              _newFeatures = value;
                            });
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
                          onChanged: (value) {
                            setState(() {
                              _tipsAndTricks = value;
                            });
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
                          onChanged: (value) {
                            setState(() {
                              _promotionalOffers = value;
                            });
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
                          onChanged: (value) {
                            setState(() {
                              _newsletters = value;
                            });
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
        currentIndex: 2, // Settings tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 2),
                ),
                (route) => false,
              );
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF2C3E50),
        selectedItemColor: const Color(0xFF64B5F6),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 10,
        iconSize: 24,
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
