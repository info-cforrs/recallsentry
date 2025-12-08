import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'advanced_filter_page.dart';
import '../services/recall_data_service.dart';
import '../services/filter_state_service.dart';
import '../services/subscription_service.dart';
import '../models/recall_data.dart';
import '../widgets/small_usda_recall_card.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/custom_loading_indicator.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class OnlyAdvancedFilteredRecallsPage extends StatefulWidget {
  final List<String> brandFilters;
  final List<String> productFilters;
  final List<String> stateFilters;
  final List<String> allergenFilters;

  const OnlyAdvancedFilteredRecallsPage({
    super.key,
    this.brandFilters = const [],
    this.productFilters = const [],
    this.stateFilters = const [],
    this.allergenFilters = const [],
  });

  @override
  State<OnlyAdvancedFilteredRecallsPage> createState() =>
      _OnlyAdvancedFilteredRecallsPageState();
}

class _OnlyAdvancedFilteredRecallsPageState
    extends State<OnlyAdvancedFilteredRecallsPage> with HideOnScrollMixin {
  final int _currentIndex = 1; // Recalls tab
  final RecallDataService _recallService = RecallDataService();
  final FilterStateService _filterStateService = FilterStateService();
  List<RecallData> _filteredRecalls = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Current active filters (may be different from widget parameters)
  List<String> _activeBrandFilters = [];
  List<String> _activeProductFilters = [];
  List<String> _activeStateFilters = [];
  List<String> _activeAllergenFilters = [];

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _initializeFilters();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  // Initialize filters - use passed parameters or load saved filters
  Future<void> _initializeFilters() async {
    // If filters were passed in constructor, use those
    if (widget.brandFilters.isNotEmpty || widget.productFilters.isNotEmpty || widget.stateFilters.isNotEmpty || widget.allergenFilters.isNotEmpty) {
      _activeBrandFilters = List.from(widget.brandFilters);
      _activeProductFilters = List.from(widget.productFilters);
      _activeStateFilters = List.from(widget.stateFilters);
      _activeAllergenFilters = List.from(widget.allergenFilters);
    } else {
      // Otherwise, load saved filters
      final filterState = await _filterStateService.loadFilterState();
      _activeBrandFilters = filterState.brandFilters;
      _activeProductFilters = filterState.productFilters;
      _activeStateFilters = filterState.stateFilters;
      _activeAllergenFilters = filterState.allergenFilters;
    }

    _loadFilteredRecalls();
  }

  Future<void> _loadFilteredRecalls() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Get subscription tier to determine cutoff date
      final subscriptionService = SubscriptionService();
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();
      final tier = subscriptionInfo.tier;

      // Fetch FDA and USDA recalls from their dedicated spreadsheets
      final fdaRecalls = await _recallService.getFdaRecalls();
      final usdaRecalls = await _recallService.getUsdaRecalls();
      final allRecalls = [...fdaRecalls, ...usdaRecalls];

      // Apply tier-based date filter
      final now = DateTime.now();
      final DateTime cutoff;
      if (tier == SubscriptionTier.free) {
        // Last 30 days for Free users
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        // Since Jan 1 of current year for SmartFiltering/RecallMatch users
        cutoff = DateTime(now.year, 1, 1);
      }

      final recentRecalls = allRecalls.where((recall) {
        return recall.dateIssued.isAfter(cutoff);
      }).toList();

      // Sort by date (most recent first)
      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

      // Then apply brand/product/state/allergen filters to the 30-day filtered results
      List<RecallData> filtered = recentRecalls;

      if (_activeBrandFilters.isNotEmpty || _activeProductFilters.isNotEmpty || _activeStateFilters.isNotEmpty || _activeAllergenFilters.isNotEmpty) {
        filtered = recentRecalls.where((recall) {
          bool hasMatch = false;

          // Check brand filters (OR logic - match if ANY brand filter matches)
          if (!hasMatch && _activeBrandFilters.isNotEmpty) {
            for (String brandFilter in _activeBrandFilters) {
              if (recall.brandName.toLowerCase().contains(
                brandFilter.toLowerCase(),
              )) {
                hasMatch = true;
                break;
              }
            }
          }

          // Check product filters (OR logic - match if ANY product filter matches)
          if (!hasMatch && _activeProductFilters.isNotEmpty) {
            for (String productFilter in _activeProductFilters) {
              if (recall.productName.toLowerCase().contains(
                productFilter.toLowerCase(),
              )) {
                hasMatch = true;
                break;
              }
            }
          }

          // Check state filters (OR logic - match if ANY state filter matches)
          if (!hasMatch && _activeStateFilters.isNotEmpty) {
            for (String stateFilter in _activeStateFilters) {
              final distribution = recall.productDistribution.toLowerCase();
              if (distribution.contains(stateFilter.toLowerCase()) ||
                  distribution == 'nationwide' ||
                  distribution == 'all states') {
                hasMatch = true;
                break;
              }
            }
          }

          // Check allergen filters (OR logic - match if ANY allergen filter matches)
          if (!hasMatch && _activeAllergenFilters.isNotEmpty) {
            hasMatch = _matchesAllergenFilter(recall);
          }

          // Brand OR Product OR State OR Allergen - match if ANY filter type matches
          return hasMatch;
        }).toList();
      }

      if (mounted) {
        setState(() {
          _filteredRecalls = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading recalls: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Check if recall matches any of the active allergen filters
  bool _matchesAllergenFilter(RecallData recall) {
    // FDA Big 9 allergen keywords
    const allergenKeywords = {
      'peanuts': ['peanut', 'peanuts', 'groundnut', 'groundnuts', 'arachis', 'peanut butter', 'peanut oil'],
      'tree_nuts': ['almond', 'almonds', 'cashew', 'cashews', 'walnut', 'walnuts', 'pecan', 'pecans', 'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'brazil nut', 'brazil nuts', 'chestnut', 'chestnuts', 'pine nut', 'pine nuts', 'praline', 'pralines', 'marzipan', 'tree nut', 'tree nuts'],
      'milk_dairy': ['milk', 'dairy', 'cheese', 'butter', 'cream', 'lactose', 'whey', 'casein', 'yogurt', 'yoghurt', 'ghee', 'ice cream', 'buttermilk', 'condensed milk', 'evaporated milk', 'powdered milk', 'milk protein', 'lactalbumin', 'lactoglobulin'],
      'eggs': ['egg', 'eggs', 'albumin', 'mayonnaise', 'meringue', 'ovalbumin', 'ovomucin', 'ovomucoid', 'ovovitellin', 'lysozyme', 'globulin', 'egg white', 'egg yolk', 'dried egg', 'egg powder'],
      'wheat_gluten': ['wheat', 'gluten', 'flour', 'bread', 'pasta', 'cereal', 'semolina', 'durum', 'spelt', 'farina', 'bulgur', 'couscous', 'seitan', 'wheat starch', 'wheat germ', 'wheat bran', 'whole wheat', 'enriched flour', 'bread crumbs', 'breadcrumbs'],
      'soy': ['soy', 'soybean', 'soybeans', 'soya', 'tofu', 'edamame', 'miso', 'tempeh', 'soy sauce', 'soy milk', 'soy protein', 'soy lecithin', 'textured vegetable protein', 'tvp'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'tilapia', 'anchovy', 'anchovies', 'bass', 'halibut', 'trout', 'sardine', 'sardines', 'mackerel', 'herring', 'catfish', 'pollock', 'haddock', 'flounder', 'sole', 'snapper', 'grouper', 'swordfish', 'mahi', 'perch', 'pike', 'fish sauce', 'fish oil', 'omega-3'],
      'shellfish': ['shrimp', 'crab', 'lobster', 'shellfish', 'crawfish', 'crayfish', 'scallop', 'scallops', 'clam', 'clams', 'mussel', 'mussels', 'oyster', 'oysters', 'prawn', 'prawns', 'langoustine', 'abalone', 'snail', 'escargot', 'calamari', 'squid', 'octopus'],
      'sesame': ['sesame', 'tahini', 'halvah', 'halva', 'hummus', 'sesame oil', 'sesame seed', 'sesame seeds', 'benne', 'gingelly'],
    };

    // Build searchable text from recall (include all relevant fields)
    final searchText = '${recall.productName} ${recall.brandName} ${recall.description} ${recall.recallReason} ${recall.recallPhaReason} ${recall.adverseReactions} ${recall.category}'.toLowerCase();

    // Check if 'all' is selected (matches all allergens)
    final allergensToCheck = _activeAllergenFilters.contains('all')
        ? allergenKeywords.keys.toList()
        : _activeAllergenFilters;

    for (final allergen in allergensToCheck) {
      final keywords = allergenKeywords[allergen] ?? [];
      for (final keyword in keywords) {
        if (searchText.contains(keyword.toLowerCase())) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Standard dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Standard Header with App Icon, RecallSentry Text and Menu Button - with hide-on-scroll
            AnimatedVisibilityWrapper(
              isVisible: isHeaderVisible,
              direction: SlideDirection.up,
              child: Padding(
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
                    // Filtered Recalls Text
                    const Expanded(
                      child: Text(
                        'Filtered Recalls',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Atlanta',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                controller: hideOnScrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Filter Summary Section
                    if (_activeBrandFilters.isNotEmpty ||
                        _activeProductFilters.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A4A5C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF64B5F6),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  color: Color(0xFF64B5F6),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Active Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_activeBrandFilters.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.business,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Brands:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _activeBrandFilters.join(', '),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_activeProductFilters.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Products:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _activeProductFilters.join(', '),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    if (widget.brandFilters.isNotEmpty ||
                        widget.productFilters.isNotEmpty)
                      const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        // Modify Filters Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdvancedFilterPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text(
                              'Modify Filters',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF64B5F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Clear Filters Button
                        if (_activeBrandFilters.isNotEmpty ||
                            _activeProductFilters.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                // Clear saved filter state
                                await _filterStateService.clearAllFilters();
                                // Navigate to fresh page with no filters
                                navigator.pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const OnlyAdvancedFilteredRecallsPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text(
                                'Clear All',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Results Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLoading ? Icons.hourglass_empty : Icons.search,
                            color: const Color(0xFF64B5F6),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isLoading
                                  ? 'Searching recalls...'
                                  : _activeBrandFilters.isEmpty &&
                                        _activeProductFilters.isEmpty
                                  ? 'Showing all recalls'
                                  : 'Found ${_filteredRecalls.length} recall${_filteredRecalls.length == 1 ? '' : 's'} matching your criteria',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filtered Recalls List
                    if (_isLoading)
                      const CustomLoadingIndicator(
                        size: LoadingIndicatorSize.medium,
                        message: 'Loading recall data...',
                      )
                    else if (_errorMessage.isNotEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.orange,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFilteredRecalls,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64B5F6),
                              ),
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_filteredRecalls.isNotEmpty)
                      Column(
                        children: _filteredRecalls.map((recall) {
                          if (recall.agency == 'USDA') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SmallUsdaRecallCard(recall: recall),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SmallFdaRecallCard(recall: recall),
                            );
                          }
                        }).toList(),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.brandFilters.isEmpty &&
                                      widget.productFilters.isEmpty
                                  ? Icons.tune
                                  : Icons.search_off,
                              color: Colors.white54,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.brandFilters.isEmpty &&
                                      widget.productFilters.isEmpty
                                  ? 'No filters applied'
                                  : 'No recalls found matching your criteria',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.brandFilters.isEmpty &&
                                      widget.productFilters.isEmpty
                                  ? 'Use the Advanced Filter to search for specific recalls by brand name or product name.'
                                  : 'Try adjusting your filter criteria to find more results.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdvancedFilterPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.tune, size: 20),
                              label: Text(
                                widget.brandFilters.isEmpty &&
                                        widget.productFilters.isEmpty
                                    ? 'Set Up Filters'
                                    : 'Modify Filters',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64B5F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2C3E50),
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
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
      ),
    );
  }
}
