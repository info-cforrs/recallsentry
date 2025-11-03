import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'subscribe_page.dart';
import 'login_page.dart';
import 'sign_up_page.dart';
import 'all_recalls_page.dart';
import 'only_advanced_filtered_recalls_page.dart';
import 'saved_recalls_page.dart';
import 'all_fda_recalls_page.dart';
import 'all_usda_recalls_page.dart';
import '../services/filter_state_service.dart';
import '../services/recall_data_service.dart';
import '../services/subscription_service.dart';
import 'category_filter_page.dart' as category;

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> {
  final int _currentIndex = 0; // Home tab (since this is accessed from Home)

  // Category counts
  final Map<String, int> _categoryCounts = {};
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryCounts();
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final subscriptionService = SubscriptionService();
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
      final tier = subscriptionInfo.tier;

      final recallService = RecallDataService();
      final fdaRecalls = await recallService.getFdaRecalls();
      final usdaRecalls = await recallService.getUsdaRecalls();

      // Determine cutoff date based on tier
      final now = DateTime.now();
      final DateTime cutoff;
      if (tier == SubscriptionTier.guest || tier == SubscriptionTier.free) {
        // Last 30 days for Guest/Free users
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        // Since Jan 1 of current year for SmartFiltering/RecallMatch users
        cutoff = DateTime(now.year, 1, 1);
      }

      // Define categories with their filter keywords
      final categories = {
        'food': ['food'],
        'cosmetics': ['cosmetics', 'personal care'],
        'drugs': ['otc drugs', 'supplements'],
        'home': ['home', 'furniture'],
        'clothing': ['clothing', 'kids items'],
        'childSeats': ['child seats', 'other accessories'],
        'powerTools': ['power tools', 'lawn care'],
        'electronics': ['electronics', 'appliances'],
        'vehicles': ['car', 'truck', 'suv'],
        'tires': ['tires'],
        'toys': ['toys'],
        'pets': ['pet', 'veterinary', 'animal'],
      };

      // Calculate counts for each category
      final counts = <String, int>{};
      categories.forEach((key, keywords) {
        final fdaCount = fdaRecalls.where((recall) {
          if (!recall.dateIssued.isAfter(cutoff)) return false;
          final cat = recall.category.toLowerCase();
          return keywords.any((k) => cat.contains(k.toLowerCase()));
        }).length;

        final usdaCount = usdaRecalls.where((recall) {
          if (!recall.dateIssued.isAfter(cutoff)) return false;
          final cat = recall.category.toLowerCase();
          return keywords.any((k) => cat.contains(k.toLowerCase()));
        }).length;

        counts[key] = fdaCount + usdaCount;
      });

      if (mounted) {
        setState(() {
          _categoryCounts.addAll(counts);
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      print('Error loading category counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon and Main Menu Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
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
                  // Main Menu Text
                  const Text(
                    'Main Menu',
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

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Top Action Buttons Row - Three equally sized buttons
                    Row(
                      children: [
                        // Sign-Up Button
                        Expanded(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to Sign-Up page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DADE2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Sign-Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Login Button
                        Expanded(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to Login page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DADE2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Subscribe Button
                        Expanded(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(left: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate directly to Subscribe page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SubscribePage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DADE2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Category Section Header
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5DADE2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'By Category',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Icons Row - First Row (Food, Cosmetics, Drugs)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryWithFilter('Food &\nBeverages', 'food_beverage_category_button.png', Icons.restaurant, ['food'], 'food'),
                        _buildCategoryWithFilter('Cosmetics &\nPersonal Care', 'cosmetics_category_button.png', Icons.brush, ['cosmetics', 'personal care'], 'cosmetics'),
                        _buildCategoryWithFilter('OTC Drugs &\nSupplements', 'otc_category_button.png', Icons.medication, ['otc drugs', 'supplements'], 'drugs'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Icons Row - Second Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryWithFilter('Home &\nFurniture', 'home_furniture_category_button.png', Icons.home, ['home', 'furniture'], 'home'),
                        _buildCategoryWithFilter('Clothing', 'clothing_category_button.png', Icons.checkroom, ['clothing', 'kids items'], 'clothing'),
                        _buildCategoryWithFilter('Child Seats &\nAccessories', 'child_seats_category_button.png', Icons.child_care, ['child seats', 'other accessories'], 'childSeats'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Icons Row - Third Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryWithFilter('Power Tools &\nLawn Care', 'power_tools_category_button.png', Icons.build, ['power tools', 'lawn care'], 'powerTools'),
                        _buildCategoryWithFilter('Electronics &\nAppliances', 'electronics_category_button.png', Icons.devices, ['electronics', 'appliances'], 'electronics'),
                        _buildCategoryWithFilter('Vehicles', 'vehicles_category_button.png', Icons.directions_car, ['car', 'truck', 'suv'], 'vehicles'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Category Icons Row - Fourth Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryWithFilter('Tires', 'tires_category_button.png', Icons.trip_origin, ['tires'], 'tires'),
                        _buildCategoryWithFilter('Toys', 'toys_category_button.png', Icons.toys, ['toys'], 'toys'),
                        _buildCategoryWithFilter('Pets &\nVeterinary', 'pets_veterinary_category_button.png', Icons.pets, ['pet', 'veterinary', 'animal'], 'pets'),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              // Navigate back to Home page (pop current page to return to Home)
              Navigator.of(context).pop();
              break;
            case 1:
              // Navigate to Recalls tab in main navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              // Navigate to Settings tab in main navigation
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
        backgroundColor: const Color(0xFF2C3E50), // Dark blue-grey background
        selectedItemColor: const Color(0xFF64B5F6), // Light blue for selected
        unselectedItemColor: Colors.grey.shade500, // Grey for unselected
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Recalls'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    String? imagePath,
    IconData? icon,
    required VoidCallback onTap,
    int? count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon ?? Icons.category,
                              size: 40,
                              color: const Color(0xFF1D3547),
                            );
                          },
                        )
                      : Icon(
                          icon ?? Icons.category,
                          size: 40,
                          color: const Color(0xFF1D3547),
                        ),
                ),
              ),
              // Red badge with count in upper right corner
              if (count != null && count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1D3547),
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build category item with category filter
  Widget _buildCategoryWithFilter(
    String title,
    String imageName,
    IconData fallbackIcon,
    List<String> categories,
    String categoryKey,
  ) {
    return _buildCategoryItem(
      title: title,
      imagePath: 'assets/images/$imageName',
      icon: fallbackIcon,
      count: _categoryCounts[categoryKey] ?? 0,
      onTap: () async {
        // Get subscription tier to determine cutoff date
        final subscriptionService = SubscriptionService();
        final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
        final tier = subscriptionInfo.tier;

        final now = DateTime.now();
        final DateTime cutoff;
        if (tier == SubscriptionTier.guest || tier == SubscriptionTier.free) {
          // Last 30 days for Guest/Free users
          cutoff = now.subtract(const Duration(days: 30));
        } else {
          // Since Jan 1 of current year for SmartFiltering/RecallMatch users
          cutoff = DateTime(now.year, 1, 1);
        }

        final recallService = RecallDataService();

        // Use working FDA and USDA endpoints
        final fdaRecalls = await recallService.getFdaRecalls();
        final usdaRecalls = await recallService.getUsdaRecalls();

        print('🟢 Total FDA recalls: ${fdaRecalls.length}');
        print('🟢 Total USDA recalls: ${usdaRecalls.length}');
        print('🟢 Using cutoff date: $cutoff (Tier: $tier)');

        // Filter by cutoff date and matching categories
        final recentFda = fdaRecalls.where((recall) {
          if (!recall.dateIssued.isAfter(cutoff)) return false;
          final cat = recall.category.toLowerCase();
          return categories.any((c) => cat.contains(c.toLowerCase()));
        }).toList();

        final recentUsda = usdaRecalls.where((recall) {
          if (!recall.dateIssued.isAfter(cutoff)) return false;
          final cat = recall.category.toLowerCase();
          return categories.any((c) => cat.contains(c.toLowerCase()));
        }).toList();

        print('🟢 FDA $title recalls (after cutoff): ${recentFda.length}');
        print('🟢 USDA $title recalls (after cutoff): ${recentUsda.length}');

        final filtered = [...recentFda, ...recentUsda];
        print('🟢 Total filtered recalls to show: ${filtered.length}');

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => category.FilteredRecallsPage(
                filteredRecalls: filtered,
              ),
            ),
          );
        }
      },
    );
  }
}
