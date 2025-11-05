import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'all_fda_recalls_page.dart';
import 'all_usda_recalls_page.dart';
import 'all_recalls_page.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../services/filter_state_service.dart';
import '../services/saved_recalls_service.dart';
import '../services/subscription_service.dart';
import 'category_filter_page.dart' as category;

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToRecalls;

  const HomePage({super.key, this.onNavigateToRecalls});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final RecallDataService _recallService = RecallDataService();
  final FilterStateService _filterStateService = FilterStateService();
  final SavedRecallsService _savedRecallsService = SavedRecallsService();
  final ScrollController _carouselScrollController = ScrollController();

  int _totalRecalls = 0;
  int _fdaRecalls = 0;
  int _usdaRecalls = 0;
  int _filteredRecalls = 0;
  int _savedRecalls = 0;
  final Map<String, int> _categoryCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecallCounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRecallCounts();
    }
  }

  void didPopNext() {
    // Called when coming back to this page via navigation
    _loadRecallCounts();
  }

  Future<void> _loadRecallCounts() async {
    try {
      // Get user subscription tier
      final subscriptionService = SubscriptionService();
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
      final tier = subscriptionInfo.tier;

      // Fetch FDA and USDA recalls from dedicated spreadsheets
      final fdaRecalls = await _recallService.getFdaRecalls();
      final usdaRecalls = await _recallService.getUsdaRecalls();
      print(
        '📊 Home Page: Received ${fdaRecalls.length} FDA, ${usdaRecalls.length} USDA recalls',
      );

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

      // Apply tier-based filtering
      final recentFdaRecalls = fdaRecalls
          .where((recall) => recall.dateIssued.isAfter(cutoff))
          .toList();
      final recentUsdaRecalls = usdaRecalls
          .where((recall) => recall.dateIssued.isAfter(cutoff))
          .toList();

      // All Recalls count is the sum of FDA and USDA
      final totalRecalls = recentFdaRecalls.length + recentUsdaRecalls.length;

      // Filter count: use the same logic as OnlyAdvancedFilteredRecallsPage
      final filterState = await _filterStateService.loadFilterState();
      List<RecallData> allRecentRecalls = [
        ...recentFdaRecalls,
        ...recentUsdaRecalls,
      ];
      List<RecallData> filtered = allRecentRecalls;
      if (filterState.brandFilters.isNotEmpty ||
          filterState.productFilters.isNotEmpty) {
        filtered = allRecentRecalls.where((recall) {
          bool matchesBrand = filterState.brandFilters.isEmpty;
          bool matchesProduct = filterState.productFilters.isEmpty;
          if (filterState.brandFilters.isNotEmpty) {
            matchesBrand = false;
            for (String brandFilter in filterState.brandFilters) {
              if (recall.brandName.toLowerCase().contains(
                brandFilter.toLowerCase(),
              )) {
                matchesBrand = true;
                break;
              }
            }
          }
          if (filterState.productFilters.isNotEmpty) {
            matchesProduct = false;
            for (String productFilter in filterState.productFilters) {
              if (recall.productName.toLowerCase().contains(
                productFilter.toLowerCase(),
              )) {
                matchesProduct = true;
                break;
              }
            }
          }
          // OR logic between brand and product filters
          return matchesBrand || matchesProduct;
        }).toList();
      }
      final filteredCount = filtered.length;

      // Count saved recalls
      print('🔍 HomePage: Fetching saved recalls...');
      final savedRecalls = await _savedRecallsService.getSavedRecalls();
      final savedCount = savedRecalls.length;
      print('📊 HomePage: Got ${savedCount} saved recalls');
      if (savedCount > 0) {
        print('   First 3 saved:');
        for (var i = 0; i < (savedCount > 3 ? 3 : savedCount); i++) {
          print('   - ${savedRecalls[i].id}: ${savedRecalls[i].productName}');
        }
      }

      // Calculate category counts
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

      final counts = <String, int>{};
      categories.forEach((key, keywords) {
        final fdaCount = recentFdaRecalls.where((recall) {
          final cat = recall.category.toLowerCase();
          return keywords.any((k) => cat.contains(k.toLowerCase()));
        }).length;

        final usdaCount = recentUsdaRecalls.where((recall) {
          final cat = recall.category.toLowerCase();
          return keywords.any((k) => cat.contains(k.toLowerCase()));
        }).length;

        counts[key] = fdaCount + usdaCount;
      });

      if (mounted) {
        setState(() {
          _totalRecalls = totalRecalls;
          _fdaRecalls = recentFdaRecalls.length;
          _usdaRecalls = recentUsdaRecalls.length;
          _filteredRecalls = filteredCount;
          _savedRecalls = savedCount;
          _categoryCounts.clear();
          _categoryCounts.addAll(counts);
        });

        print(
          '📊 Recall counts loaded (30-day rule): Total: $_totalRecalls, FDA: $_fdaRecalls, USDA: $_usdaRecalls, Filtered: $_filteredRecalls, Saved: $_savedRecalls',
        );
      }
    } catch (e) {
      print('❌ Error loading recall counts: $e');
      if (mounted) {
        setState(() {
          _totalRecalls = 0;
          _fdaRecalls = 0;
          _usdaRecalls = 0;
          _filteredRecalls = 0;
          _savedRecalls = 0;
        });
      }
    }
  }

  Widget _buildRecallBadge(int count) {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String? imagePath,
    required IconData icon,
    required String label,
    required int? badgeCount,
    required String categoryKey,
    required List<String> categories,
  }) {
    return GestureDetector(
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

        // Fetch FDA and USDA recalls
        final fdaRecalls = await _recallService.getFdaRecalls();
        final usdaRecalls = await _recallService.getUsdaRecalls();

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

        final filtered = [...recentFda, ...recentUsda];

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
      child: SizedBox(
        width: 85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF5DADE2), width: 3),
                  ),
                  child: ClipOval(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 36,
                                color: const Color(0xFF2C3E50),
                              );
                            },
                          )
                        : Icon(
                            icon,
                            size: 36,
                            color: const Color(0xFF2C3E50),
                          ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Solid dark blue-grey
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title for Category Carousel
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Recalls by Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category Carousel
                SizedBox(
                  height: 140,
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        final offset = pointerSignal.scrollDelta.dy;
                        _carouselScrollController.jumpTo(
                          _carouselScrollController.offset + offset,
                        );
                      }
                    },
                    child: Scrollbar(
                      controller: _carouselScrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _carouselScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                      _buildCategoryCard(
                        imagePath: 'assets/images/food_beverage_category_button.png',
                        icon: Icons.restaurant,
                        label: 'Food &\nBeverages',
                        badgeCount: _categoryCounts['food'],
                        categoryKey: 'food',
                        categories: ['food'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/cosmetics_category_button.png',
                        icon: Icons.brush,
                        label: 'Cosmetics &\nPersonal Care',
                        badgeCount: _categoryCounts['cosmetics'],
                        categoryKey: 'cosmetics',
                        categories: ['cosmetics', 'personal care'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/otc_category_button.png',
                        icon: Icons.medication,
                        label: 'OTC Drugs &\nSupplements',
                        badgeCount: _categoryCounts['drugs'],
                        categoryKey: 'drugs',
                        categories: ['otc drugs', 'supplements'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/home_furniture_category_button.png',
                        icon: Icons.chair,
                        label: 'Home &\nFurniture',
                        badgeCount: _categoryCounts['home'],
                        categoryKey: 'home',
                        categories: ['home', 'furniture'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/clothing_category_button.png',
                        icon: Icons.checkroom,
                        label: 'Clothing',
                        badgeCount: _categoryCounts['clothing'],
                        categoryKey: 'clothing',
                        categories: ['clothing', 'kids items'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/child_seats_category_button.png',
                        icon: Icons.child_care,
                        label: 'Child Seats &\nAccessories',
                        badgeCount: _categoryCounts['childSeats'],
                        categoryKey: 'childSeats',
                        categories: ['child seats', 'other accessories'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/power_tools_category_button.png',
                        icon: Icons.build,
                        label: 'Power Tools &\nLawn Care',
                        badgeCount: _categoryCounts['powerTools'],
                        categoryKey: 'powerTools',
                        categories: ['power tools', 'lawn care'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/electronics_category_button.png',
                        icon: Icons.devices,
                        label: 'Electronics &\nAppliances',
                        badgeCount: _categoryCounts['electronics'],
                        categoryKey: 'electronics',
                        categories: ['electronics', 'appliances'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/vehicles_category_button.png',
                        icon: Icons.directions_car,
                        label: 'Vehicles',
                        badgeCount: _categoryCounts['vehicles'],
                        categoryKey: 'vehicles',
                        categories: ['car', 'truck', 'suv'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/tires_category_button.png',
                        icon: Icons.trip_origin,
                        label: 'Tires',
                        badgeCount: _categoryCounts['tires'],
                        categoryKey: 'tires',
                        categories: ['tires'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/toys_category_button.png',
                        icon: Icons.toys,
                        label: 'Toys',
                        badgeCount: _categoryCounts['toys'],
                        categoryKey: 'toys',
                        categories: ['toys'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/pets_veterinary_category_button.png',
                        icon: Icons.pets,
                        label: 'Pets &\nVeterinary',
                        badgeCount: _categoryCounts['pets'],
                        categoryKey: 'pets',
                        categories: ['pet', 'veterinary', 'animal'],
                      ),
                    ],
                  ),
                ),
              ),
            ),

                const SizedBox(height: 24),

                // Main Content Card (like the Recalls card in the image)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF0C5876,
                    ), // Single color instead of gradient
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Make column take minimum space
                    children: [
                      // All Recalls Button
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // Navigate to All Recalls page
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AllRecallsPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF64B5F6,
                                ), // Light blue
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'All Recalls',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          _buildRecallBadge(
                            _totalRecalls,
                          ), // Dynamic total recalls count
                        ],
                      ),

                      const SizedBox(height: 26),
                      // FDA and USDA Buttons Row
                      Row(
                        children: [
                          // FDA Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 80, // Taller than other buttons
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AllFDARecallsPage(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          child: Image.asset(
                                            'assets/images/FDA_button.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF0066CC,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'FDA',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  _fdaRecalls,
                                ), // Dynamic FDA recalls count
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // USDA Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 80, // Taller than other buttons
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AllUSDARecallsPage(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          child: Image.asset(
                                            'assets/images/USDA_button.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF2E7D32,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'USDA',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  _usdaRecalls,
                                ), // Dynamic USDA recalls count
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ), // 20px spacing after last button row
                    ],
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
