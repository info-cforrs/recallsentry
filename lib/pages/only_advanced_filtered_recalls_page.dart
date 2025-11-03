import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'advanced_filter_page.dart';
import '../services/recall_data_service.dart';
import '../services/filter_state_service.dart';
import '../services/subscription_service.dart';
import '../models/recall_data.dart';
import '../widgets/usda_recall_card.dart';
import '../widgets/fda_recall_card.dart';

class OnlyAdvancedFilteredRecallsPage extends StatefulWidget {
  final List<String> brandFilters;
  final List<String> productFilters;

  const OnlyAdvancedFilteredRecallsPage({
    super.key,
    this.brandFilters = const [],
    this.productFilters = const [],
  });

  @override
  State<OnlyAdvancedFilteredRecallsPage> createState() =>
      _OnlyAdvancedFilteredRecallsPageState();
}

class _OnlyAdvancedFilteredRecallsPageState
    extends State<OnlyAdvancedFilteredRecallsPage> {
  final int _currentIndex = 1; // Recalls tab
  final RecallDataService _recallService = RecallDataService();
  final FilterStateService _filterStateService = FilterStateService();
  List<RecallData> _filteredRecalls = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Current active filters (may be different from widget parameters)
  List<String> _activeBrandFilters = [];
  List<String> _activeProductFilters = [];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  // Initialize filters - use passed parameters or load saved filters
  Future<void> _initializeFilters() async {
    // If filters were passed in constructor, use those
    if (widget.brandFilters.isNotEmpty || widget.productFilters.isNotEmpty) {
      _activeBrandFilters = List.from(widget.brandFilters);
      _activeProductFilters = List.from(widget.productFilters);
    } else {
      // Otherwise, load saved filters
      final filterState = await _filterStateService.loadFilterState();
      _activeBrandFilters = filterState.brandFilters;
      _activeProductFilters = filterState.productFilters;
    }

    _loadFilteredRecalls();
  }

  Future<void> _loadFilteredRecalls() async {
    print('🔍 Advanced Filter Page: _loadFilteredRecalls() called');
    print('🔍 Active Brand filters: $_activeBrandFilters');
    print('🔍 Active Product filters: $_activeProductFilters');

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
      print(
        '🔍 Advanced Filter: Got ${allRecalls.length} total recalls (FDA + USDA)',
      );

      // Apply tier-based date filter
      final now = DateTime.now();
      final DateTime cutoff;
      if (tier == SubscriptionTier.guest || tier == SubscriptionTier.free) {
        // Last 30 days for Guest/Free users
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        // Since Jan 1 of current year for SmartFiltering/RecallMatch users
        cutoff = DateTime(now.year, 1, 1);
      }

      print('🔍 Advanced Filter: Using cutoff date: $cutoff (Tier: $tier)');

      final recentRecalls = allRecalls.where((recall) {
        return recall.dateIssued.isAfter(cutoff);
      }).toList();

      // Sort by date (most recent first)
      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

      print(
        '🔍 Advanced Filter: Found ${recentRecalls.length} recalls after cutoff date',
      );

      // Then apply brand/product filters to the 30-day filtered results
      List<RecallData> filtered = recentRecalls;

      if (_activeBrandFilters.isNotEmpty || _activeProductFilters.isNotEmpty) {
        print('🔍 Advanced Filter: Applying brand/product filters...');
        filtered = recentRecalls.where((recall) {
          bool matchesBrand = false;
          bool matchesProduct = false;

          // Check brand filters (OR logic within brand filters)
          if (_activeBrandFilters.isNotEmpty) {
            for (String brandFilter in _activeBrandFilters) {
              if (recall.brandName.toLowerCase().contains(
                brandFilter.toLowerCase(),
              )) {
                matchesBrand = true;
                print(
                  '✅ Brand match: "${recall.brandName}" contains "$brandFilter"',
                );
                break;
              }
            }
          }

          // Check product filters (OR logic within product filters)
          if (_activeProductFilters.isNotEmpty) {
            for (String productFilter in _activeProductFilters) {
              if (recall.productName.toLowerCase().contains(
                productFilter.toLowerCase(),
              )) {
                matchesProduct = true;
                print(
                  '✅ Product match: "${recall.productName}" contains "$productFilter"',
                );
                break;
              }
            }
          }

          // OR logic between brand and product filters - match if ANY filter matches
          final result = matchesBrand || matchesProduct;
          if (result) {
            print('✅ Recall matched: ${recall.id} - ${recall.productName}');
          }
          return result;
        }).toList();
        print(
          '🔍 Advanced Filter: Found ${filtered.length} matching recalls after applying brand/product filters',
        );
      } else {
        print(
          '🔍 Advanced Filter: No brand/product filters applied, showing all recalls from last 30 days',
        );
      }

      if (mounted) {
        setState(() {
          _filteredRecalls = filtered;
          _isLoading = false;
        });
        print(
          '🔍 Advanced Filter: setState completed with ${_filteredRecalls.length} recalls',
        );
      }
    } catch (e) {
      print('❌ Advanced Filter Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading recalls: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎯 Advanced Filter Page build() called');
    print('🎯 _isLoading: $_isLoading');
    print('🎯 _errorMessage: $_errorMessage');
    print('🎯 _filteredRecalls.length: ${_filteredRecalls.length}');
    print('🎯 brandFilters: $_activeBrandFilters');
    print('🎯 productFilters: $_activeProductFilters');

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Standard dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Standard Header with App Icon, RecallSentry Text and Menu Button
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

            const SizedBox(height: 16),
            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
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
                                // Clear saved filter state
                                await _filterStateService.clearAllFilters();
                                // Navigate to fresh page with no filters
                                Navigator.pushReplacement(
                                  context,
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
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF64B5F6),
                              strokeWidth: 3,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading recall data...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
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
                              child: UsdaRecallCard(recall: recall),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: FdaRecallCard(recall: recall),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              // Navigate to Home tab in main navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
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
}
