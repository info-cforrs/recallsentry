import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'advanced_filter_page.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../widgets/simple_recall_card.dart';
import '../widgets/custom_back_button.dart';

class FilteredRecallsPage extends StatefulWidget {
  final List<String> brandFilters;
  final List<String> productFilters;

  const FilteredRecallsPage({
    super.key,
    this.brandFilters = const [],
    this.productFilters = const [],
  });

  @override
  State<FilteredRecallsPage> createState() => _FilteredRecallsPageState();
}

class _FilteredRecallsPageState extends State<FilteredRecallsPage> {
  final RecallDataService _recallService = RecallDataService();
  List<RecallData> _filteredRecalls = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab

  @override
  void initState() {
    super.initState();
    _loadFilteredRecalls();
  }

  Future<void> _loadFilteredRecalls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get all recalls
      final allRecalls = await _recallService.getRecalls();

      // Apply filters
      List<RecallData> filtered = allRecalls;

      if (widget.brandFilters.isNotEmpty || widget.productFilters.isNotEmpty) {
        filtered = allRecalls.where((recall) {
          bool matchesBrand = widget.brandFilters.isEmpty;
          bool matchesProduct = widget.productFilters.isEmpty;

          // Check brand filters
          if (widget.brandFilters.isNotEmpty) {
            for (String brandFilter in widget.brandFilters) {
              if (recall.brandName.toLowerCase().contains(
                brandFilter.toLowerCase(),
              )) {
                matchesBrand = true;
                break;
              }
            }
          }

          // Check product filters
          if (widget.productFilters.isNotEmpty) {
            for (String productFilter in widget.productFilters) {
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

      setState(() {
        _filteredRecalls = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon, RecallSentry Text and Menu Button
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
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shield,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // RecallSentry Text
                  const Expanded(
                    child: Text(
                      'RecallSentry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Title Section
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Filtered Recalls',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Search results based on your filter criteria',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Advanced Filter Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.tune, color: Colors.white, size: 32),
                          const SizedBox(height: 12),
                          const Text(
                            'Advanced Filtering',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use advanced filters to search recalls by specific criteria',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdvancedFilterPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4A90E2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Open Advanced Filter',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Filter Summary Section
                    if (widget.brandFilters.isNotEmpty ||
                        widget.productFilters.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A4A5C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Active Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (widget.brandFilters.isNotEmpty) ...[
                              Text(
                                'Brands: ${widget.brandFilters.join(', ')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (widget.productFilters.isNotEmpty) ...[
                              Text(
                                'Products: ${widget.productFilters.join(', ')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    if (widget.brandFilters.isNotEmpty ||
                        widget.productFilters.isNotEmpty)
                      const SizedBox(height: 24),

                    // Results Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLoading
                                ? 'Searching recalls...'
                                : 'Found ${_filteredRecalls.length} recall${_filteredRecalls.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filtered Recalls List
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A90E2),
                              ),
                            )
                          : _errorMessage.isNotEmpty
                          ? Center(
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
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadFilteredRecalls,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredRecalls.isNotEmpty
                          ? ListView.builder(
                              itemCount: _filteredRecalls.length,
                              itemBuilder: (context, index) {
                                final recall = _filteredRecalls[index];
                                return SimpleRecallCard(
                                  recall: recall,
                                  agency: recall.agency,
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    color: Colors.white54,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    widget.brandFilters.isEmpty &&
                                            widget.productFilters.isEmpty
                                        ? 'Use the Advanced Filter to search for specific recalls'
                                        : 'No recalls found matching your filter criteria',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AdvancedFilterPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A90E2),
                                    ),
                                    child: const Text(
                                      'Modify Filters',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
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
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.error), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
