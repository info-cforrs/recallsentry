import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../widgets/usda_recall_card.dart';
import '../widgets/fda_recall_card.dart';
import '../widgets/custom_back_button.dart';

class AllRecallsPage extends StatefulWidget {
  final bool showBottomNavigation;

  const AllRecallsPage({super.key, this.showBottomNavigation = true});

  @override
  State<AllRecallsPage> createState() => _AllRecallsPageState();
}

class _AllRecallsPageState extends State<AllRecallsPage> {
  final RecallDataService _recallService = RecallDataService();
  final TextEditingController _searchController = TextEditingController();
  List<RecallData> _allRecalls = [];
  List<RecallData> _filteredRecalls = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedCategory = 'all'; // 'all' or specific category
  String _selectedAgency = 'all'; // 'all', 'FDA', 'USDA'
  List<String> _availableRiskLevels =
      []; // Dynamic risk levels from actual data
  List<String> _availableCategories = []; // Dynamic categories from actual data
  List<String> _availableAgencies = []; // Dynamic agencies from actual data

  @override
  void initState() {
    super.initState();
    print('🔥 All Recalls Page: initState() called - starting to load recalls');
    _loadAllRecalls();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRecalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 All Recalls Page: Starting to load recalls...');
      // Fetch FDA recalls from FDA spreadsheet
      final fdaRecalls = await _recallService.getFdaRecalls();
      // Fetch USDA recalls from USDA spreadsheet
      final usdaRecalls = await _recallService.getUsdaRecalls();
      final allRecalls = [...fdaRecalls, ...usdaRecalls];
      print(
        '✅ All Recalls Page: Received ${allRecalls.length} total recalls from FDA and USDA spreadsheets',
      );

      // Filter recalls to last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRecalls = allRecalls.where((recall) {
        return recall.dateIssued.isAfter(thirtyDaysAgo);
      }).toList();

      // Sort by date (most recent first)
      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

      // Extract unique filter options from actual data
      _updateAvailableFilterOptions(recentRecalls);

      for (var recall in recentRecalls) {
        print(
          'Recent Recall: ${recall.id} - ${recall.productName} - Agency: ${recall.agency} - Date: ${recall.dateIssued}',
        );
      }

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _allRecalls = recentRecalls;
          _applyFiltersAndSort();
          print(
            '✅ Using ${recentRecalls.length} real recalls from last 30 days from FDA and USDA spreadsheets',
          );
        } else {
          print('⚠️ No recent recalls found');
          _allRecalls = [];
          _filteredRecalls = [];
        }
        _isLoading = false;
        _errorMessage = '';
        print(
          '🎯 All Recalls Page setState: _allRecalls.length = ${_allRecalls.length}',
        );
        print('🎯 All Recalls Page setState: _isLoading = $_isLoading');
        print('🎯 All Recalls Page setState: _errorMessage = "$_errorMessage"');
      });
    } catch (e) {
      print('❌ All Recalls Page Error: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
        _allRecalls = [];
        _filteredRecalls = [];
      });
    }
  }

  void _updateAvailableFilterOptions(List<RecallData> recalls) {
    // Extract unique filter options from actual data
    Set<String> riskLevels = {};
    Set<String> categories = {};
    Set<String> agencies = {};

    for (var recall in recalls) {
      // Add risk level if not empty
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }

      // Add category if not empty
      if (recall.category.trim().isNotEmpty) {
        categories.add(recall.category.toLowerCase().trim());
      }

      // Add agency if not empty
      if (recall.agency.trim().isNotEmpty) {
        agencies.add(recall.agency.toUpperCase().trim());
      }
    }

    // Sort the options for consistent display
    _availableRiskLevels = riskLevels.toList()..sort();
    _availableCategories = categories.toList()..sort();
    _availableAgencies = agencies.toList()..sort();

    // Reset filters if currently selected values are no longer available
    if (_selectedRiskLevel != 'all' &&
        !_availableRiskLevels.contains(_selectedRiskLevel)) {
      _selectedRiskLevel = 'all';
      print('🔄 Reset risk level filter - selected value no longer available');
    }

    if (_selectedCategory != 'all' &&
        !_availableCategories.contains(_selectedCategory)) {
      _selectedCategory = 'all';
      print('🔄 Reset category filter - selected value no longer available');
    }

    if (_selectedAgency != 'all' &&
        !_availableAgencies.contains(_selectedAgency)) {
      _selectedAgency = 'all';
      print('🔄 Reset agency filter - selected value no longer available');
    }

    print('🎯 Available Risk Levels from data: $_availableRiskLevels');
    print('🎯 Available Categories from data: $_availableCategories');
    print('🎯 Available Agencies from data: $_availableAgencies');
  }

  void _applyFiltersAndSort() {
    List<RecallData> filtered = List.from(_allRecalls);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recall) {
        return recall.productName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.brandName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.category.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.agency.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply risk level filter
    if (_selectedRiskLevel != 'all') {
      filtered = filtered.where((recall) {
        return recall.riskLevel.toUpperCase().trim() ==
            _selectedRiskLevel.toUpperCase().trim();
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((recall) {
        return recall.category.toLowerCase().trim() ==
            _selectedCategory.toLowerCase().trim();
      }).toList();
    }

    // Apply agency filter
    if (_selectedAgency != 'all') {
      filtered = filtered.where((recall) {
        return recall.agency.toUpperCase().trim() ==
            _selectedAgency.toUpperCase().trim();
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case 'brand_az':
        filtered.sort(
          (a, b) =>
              a.brandName.toLowerCase().compareTo(b.brandName.toLowerCase()),
        );
        break;
      case 'brand_za':
        filtered.sort(
          (a, b) =>
              b.brandName.toLowerCase().compareTo(a.brandName.toLowerCase()),
        );
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));
        break;
    }

    if (!mounted) return;

    setState(() {
      _filteredRecalls = filtered;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _errorMessage.isNotEmpty
                ? Icons.error_outline
                : Icons.info_outline,
            size: 80,
            color: _errorMessage.isNotEmpty ? Colors.red : Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty
                ? 'Error Loading Recalls'
                : 'No Recalls Found',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage.isNotEmpty
                ? _errorMessage
                : 'No recalls found in the last 30 days.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllRecalls,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecallsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredRecalls.length,
        itemBuilder: (context, index) {
          final recall = _filteredRecalls[index];
          if (recall.agency == 'USDA') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UsdaRecallCard(recall: recall),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FdaRecallCard(recall: recall),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon and Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  const SizedBox(width: 8),
                  // App Icon - Clickable to return to Home
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
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
                  // Title Text
                  const Expanded(
                    child: Text(
                      'All Recalls (last 30 days)',
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF64B5F6),
                      ),
                    )
                  : _filteredRecalls.isEmpty
                  ? _buildEmptyState()
                  : _buildRecallsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF2C3E50),
              selectedItemColor: const Color(0xFF64B5F6),
              unselectedItemColor: Colors.white54,
              currentIndex: 1, // Recalls tab
              elevation: 8,
              selectedFontSize: 14,
              unselectedFontSize: 12,
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                    break;
                  case 1:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialIndex: 1),
                      ),
                      (route) => false,
                    );
                    break;
                  case 2:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigation(initialIndex: 2),
                      ),
                      (route) => false,
                    );
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.warning),
                  label: 'Info',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }
}
