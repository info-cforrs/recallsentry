import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../widgets/simple_recall_card.dart';
import '../widgets/usda_recall_card.dart';
import '../widgets/fda_recall_card.dart';

class FilteredRecallsPage extends StatefulWidget {
  final List<String> brandFilters;
  final List<String> productFilters;
  final List<RecallData>? filteredRecalls;

  const FilteredRecallsPage({
    super.key,
    this.brandFilters = const [],
    this.productFilters = const [],
    this.filteredRecalls,
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
    if (widget.filteredRecalls != null) {
      setState(() {
        _filteredRecalls = widget.filteredRecalls!;
        _isLoading = false;
      });
    } else {
      _loadFilteredRecalls();
    }
  }

  Future<void> _loadFilteredRecalls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get all recalls (always fetch latest)
      final allRecalls = await _recallService.getRecalls(forceRefresh: true);

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
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3547),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
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
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Filtered Recalls by Category',
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
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Removed Filtered Recalls by Category row
                    if (widget.brandFilters.isNotEmpty ||
                        widget.productFilters.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                                if (recall.agency.toUpperCase() == 'USDA') {
                                  return UsdaRecallCard(recall: recall);
                                } else if (recall.agency.toUpperCase() ==
                                    'FDA') {
                                  return FdaRecallCard(recall: recall);
                                } else {
                                  return SimpleRecallCard(
                                    recall: recall,
                                    agency: recall.agency,
                                  );
                                }
                              },
                            )
                          : const Center(
                              child: Text(
                                'No recalls found for the selected filter.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
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
