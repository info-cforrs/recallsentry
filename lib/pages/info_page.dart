import 'package:flutter/material.dart';
import 'advanced_filter_page.dart';
import 'saved_recalls_page.dart';
import 'saved_filters_page.dart';
import 'subscribe_page.dart';
import 'all_recalls_page.dart';
import 'main_navigation.dart';
import 'rmc_page.dart';
import 'recalls_by_category_page.dart';
import '../services/subscription_service.dart';

class InfoPage extends StatefulWidget {
  final VoidCallback? onNavigateToRecalls;

  const InfoPage({super.key, this.onNavigateToRecalls});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  SubscriptionTier _subscriptionTier = SubscriptionTier.free;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionTier();
  }

  Future<void> _loadSubscriptionTier() async {
    try {
      final subscriptionService = SubscriptionService();
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
      if (mounted) {
        setState(() {
          _subscriptionTier = subscriptionInfo.tier;
        });
      }
    } catch (e) {
      // Silently fail - subscription tier will remain guest
    }
  }

  void _showSmartFiltersUpgradeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Text(
                'Upgrade Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'SmartFilters is a premium feature. Upgrade to SmartFiltering to save up to 10 filters, or RecallMatch for unlimited filters.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRmcUpgradeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 8),
              Text(
                'Upgrade Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Recall Management Center (RMC) is an exclusive RecallMatch feature. Upgrade to RecallMatch (\$4.99/month) to access step-by-step recall resolution workflows, household inventory tracking, SmartScan, and automated RecallMatch engine.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF2A4A5C),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Upgrade to RecallMatch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      backgroundColor: const Color(0xFF1D3547),
      body: Container(
        color: const Color(0xFF1D3547),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header with App Icon and RecallSentry Text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      // App Icon - Clickable to return to Home
                      GestureDetector(
                        onTap: () {
                          // Navigate to main home page with bottom navigation
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
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
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
                      const SizedBox(width: 10), // 10px spacing as requested
                      // RecallSentry Text
                      const Text(
                        'RecallSentry',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Atlanta',
                          color: Colors
                              .white, // Changed to white for dark background
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search recalls...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (value) {
                      // Navigate to All Recalls page with search query
                      if (value.trim().isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AllRecallsPage(
                              initialSearchQuery: value.trim(),
                              showBottomNavigation: false,
                            ),
                          ),
                        );
                      } else {
                        // If search is empty, just navigate to All Recalls page without filter
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AllRecallsPage(
                              showBottomNavigation: false,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 32),


                // Button rows styled like Settings page
                Card(
                  elevation: 2,
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.filter_alt, color: Colors.white70),
                        title: const Text(
                          'Filter Recalls',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Advanced filtering options',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdvancedFilterPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.white70),
                        title: const Text(
                          'Saved Recalls',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'View your saved recalls',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white70,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavedRecallsPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      ListTile(
                        leading: Icon(
                          Icons.filter_list,
                          color: _subscriptionTier == SubscriptionTier.smartFiltering ||
                                  _subscriptionTier == SubscriptionTier.recallMatch
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        title: Text(
                          'SmartFilter Recalls',
                          style: TextStyle(
                            color: _subscriptionTier == SubscriptionTier.smartFiltering ||
                                    _subscriptionTier == SubscriptionTier.recallMatch
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Manage your SmartFilter presets',
                          style: TextStyle(
                            color: _subscriptionTier == SubscriptionTier.smartFiltering ||
                                    _subscriptionTier == SubscriptionTier.recallMatch
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _subscriptionTier == SubscriptionTier.smartFiltering ||
                                  _subscriptionTier == SubscriptionTier.recallMatch
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        tileColor: _subscriptionTier == SubscriptionTier.smartFiltering ||
                                _subscriptionTier == SubscriptionTier.recallMatch
                            ? null
                            : const Color(0xFFD1D1D1),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        onTap: () {
                          if (_subscriptionTier == SubscriptionTier.smartFiltering ||
                              _subscriptionTier == SubscriptionTier.recallMatch) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SavedFiltersPage(),
                              ),
                            );
                          } else {
                            _showSmartFiltersUpgradeModal();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Recalls by Category row
                Card(
                  elevation: 2,
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.category, color: Colors.white70),
                    title: const Text(
                      'Recalls by Category',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Browse recalls by product category',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white70,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RecallsByCategoryPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Recall Management Center row
                Card(
                  elevation: 2,
                  color: const Color(0xFF2A4A5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.verified_user,
                      color: _subscriptionTier == SubscriptionTier.recallMatch
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    title: Text(
                      'Recall Management Center',
                      style: TextStyle(
                        color: _subscriptionTier == SubscriptionTier.recallMatch
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      'Track and manage your recalls',
                      style: TextStyle(
                        color: _subscriptionTier == SubscriptionTier.recallMatch
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _subscriptionTier == SubscriptionTier.recallMatch
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    tileColor: _subscriptionTier == SubscriptionTier.recallMatch
                        ? null
                        : const Color(0xFFD1D1D1),
                    onTap: () {
                      if (_subscriptionTier == SubscriptionTier.recallMatch) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RmcPage(),
                          ),
                        );
                      } else {
                        _showRmcUpgradeModal();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Subscribe Button at bottom
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscribePage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.star,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Subscribe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
