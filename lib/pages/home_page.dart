import 'package:flutter/material.dart';
import 'main_menu_page.dart';
import 'advanced_filter_page.dart';
import 'saved_recalls_page.dart';
import 'saved_filters_page.dart';
import 'subscribe_page.dart';
import 'all_fda_recalls_page.dart';
import 'all_usda_recalls_page.dart';
import 'all_recalls_page.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../services/filter_state_service.dart';
import '../services/saved_recalls_service.dart';
import '../services/subscription_service.dart';

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

  int _totalRecalls = 0;
  int _fdaRecalls = 0;
  int _usdaRecalls = 0;
  int _filteredRecalls = 0;
  int _savedRecalls = 0;
  SubscriptionTier _subscriptionTier = SubscriptionTier.guest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecallCounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

      if (mounted) {
        setState(() {
          _totalRecalls = totalRecalls;
          _fdaRecalls = recentFdaRecalls.length;
          _usdaRecalls = recentUsdaRecalls.length;
          _filteredRecalls = filteredCount;
          _savedRecalls = savedCount;
          _subscriptionTier = tier;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF34495E),
            ], // Dark blue gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                      const Spacer(), // Push menu icon to the right
                      // Three-dot menu icon
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MainMenuPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
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
                      const Text(
                        'Recalls',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

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

                      const SizedBox(height: 16),

                      // SmartFilters Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final canAccess = _subscriptionTier == SubscriptionTier.smartFiltering ||
                                _subscriptionTier == SubscriptionTier.recallMatch;

                            if (canAccess) {
                              // Navigate to Saved SmartFilters page
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SavedFiltersPage(),
                                ),
                              );
                            } else {
                              // Show upgrade modal for Free/Guest users
                              _showSmartFiltersUpgradeModal();
                            }
                          },
                          icon: Icon(
                            Icons.filter_list,
                            size: 20,
                            color: _subscriptionTier == SubscriptionTier.guest ||
                                    _subscriptionTier == SubscriptionTier.free
                                ? Colors.black
                                : Colors.white,
                          ),
                          label: Text(
                            'SmartFilters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _subscriptionTier == SubscriptionTier.guest ||
                                      _subscriptionTier == SubscriptionTier.free
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _subscriptionTier == SubscriptionTier.guest ||
                                    _subscriptionTier == SubscriptionTier.free
                                ? Colors.grey
                                : const Color(0xFF42A5F5), // Medium blue for premium users
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 26), // Increased from 16 to 26
                      // Filter and Saved Buttons Row
                      Row(
                        children: [
                          // Filter Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AdvancedFilterPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.filter_alt,
                                      size: 20,
                                      color: Color(
                                        0xFF404040,
                                      ), // Dark gray color
                                    ),
                                    label: const Text(
                                      'Filter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF42A5F5,
                                      ), // Medium blue
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  _filteredRecalls,
                                ), // Dynamic filtered recalls count
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Saved Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SavedRecallsPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.favorite,
                                      size: 20,
                                      color: Color(
                                        0xFF92D050,
                                      ), // Light green color
                                    ),
                                    label: const Text(
                                      'Saved',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF1E88E5,
                                      ), // Darker blue
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  _savedRecalls,
                                ), // Dynamic saved recalls count
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26), // Increased from 16 to 26
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
