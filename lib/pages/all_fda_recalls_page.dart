import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../models/recall_data.dart';
import '../widgets/fda_recall_card.dart';
import '../pages/fda_recall_details_page.dart';

class AllFDARecallsPage extends StatefulWidget {
  const AllFDARecallsPage({super.key});

  @override
  State<AllFDARecallsPage> createState() => _AllFDARecallsPageState();
}

class _AllFDARecallsPageState extends State<AllFDARecallsPage> {
  final RecallDataService _recallService = RecallDataService();
  final TextEditingController _searchController = TextEditingController();
  List<RecallData> _fdaRecalls = [];
  List<RecallData> _filteredRecalls = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedCategory = 'all'; // 'all' or specific category
  List<String> _availableRiskLevels =
      []; // Dynamic risk levels from actual data
  List<String> _availableCategories = []; // Dynamic categories from actual data

  @override
  void initState() {
    super.initState();
    print('🔥 FDA Recalls Page: initState() called - starting to load recalls');
    _loadFDARecalls();
  }

  Future<void> _loadFDARecalls() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 FDA Page: Starting to load recalls...');
      final allRecalls = await _recallService.getFilteredRecalls(agency: 'FDA');
      print(
        '✅ FDA Page: Received ${allRecalls.length} total FDA recalls from service',
      );

      // Filter recalls to last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRecalls = allRecalls.where((recall) {
        return recall.dateIssued.isAfter(thirtyDaysAgo);
      }).toList();

      // Sort by date (most recent first)
      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

      // Extract unique risk levels and categories from actual data
      _updateAvailableFilterOptions(recentRecalls);

      for (var recall in recentRecalls) {
        print(
          'Recent FDA Recall: ${recall.id} - ${recall.productName} - Agency: ${recall.agency} - Date: ${recall.dateIssued}',
        );
      }

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _fdaRecalls = recentRecalls;
          _applyFiltersAndSort();
          print(
            '✅ Using ${recentRecalls.length} real FDA recalls from last 30 days from Google Sheets',
          );
        } else {
          print('⚠️ No recent FDA recalls found');
          _fdaRecalls = [];
          _filteredRecalls = [];
        }
        _isLoading = false;
        _errorMessage = '';
        print(
          '🎯 FDA Page setState: _fdaRecalls.length = ${_fdaRecalls.length}',
        );
        print('🎯 FDA Page setState: _isLoading = $_isLoading');
        print('🎯 FDA Page setState: _errorMessage = "$_errorMessage"');
      });
    } catch (e) {
      print('❌ FDA Page Error: $e');
      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
        _fdaRecalls = [];
      });
    }
  }

  void _updateAvailableFilterOptions(List<RecallData> recalls) {
    // Extract unique risk levels from actual data
    Set<String> riskLevels = {};
    Set<String> categories = {};

    for (var recall in recalls) {
      // Add risk level if not empty
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }

      // Add category if not empty
      if (recall.category.trim().isNotEmpty) {
        categories.add(recall.category.toLowerCase().trim());
      }
    }

    // Sort the options for consistent display
    _availableRiskLevels = riskLevels.toList()..sort();
    _availableCategories = categories.toList()..sort();

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

    print('🎯 Available Risk Levels from data: $_availableRiskLevels');
    print('🎯 Available Categories from data: $_availableCategories');
  }

  void _applyFiltersAndSort() {
    List<RecallData> filtered = List.from(_fdaRecalls);

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
            );
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

    // Update available filter options based on current filtered results
    // This provides real-time filter options based on current search/filter context
    _updateAvailableFilterOptionsForFiltered(filtered);

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

    setState(() {
      _filteredRecalls = filtered;
    });
  }

  void _updateAvailableFilterOptionsForFiltered(List<RecallData> filtered) {
    // Update filter options based on currently filtered results for real-time updates
    Set<String> riskLevels = {};
    Set<String> categories = {};

    for (var recall in filtered) {
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }
      if (recall.category.trim().isNotEmpty) {
        categories.add(recall.category.toLowerCase().trim());
      }
    }

    // Only update if we're in a search context, otherwise keep original full dataset options
    if (_searchQuery.isNotEmpty) {
      _availableRiskLevels = riskLevels.toList()..sort();
      _availableCategories = categories.toList()..sort();
      print(
        '🔄 Updated filter options for search context: Risk levels: $_availableRiskLevels, Categories: $_availableCategories',
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sort Options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Date (Newest First)'),
                    leading: Radio<String>(
                      value: 'date',
                      groupValue: _sortOption,
                      onChanged: (String? value) {
                        setState(() {
                          _sortOption = value!;
                        });
                        _applyFiltersAndSort();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Brand Name (A-Z)'),
                    leading: Radio<String>(
                      value: 'brand_az',
                      groupValue: _sortOption,
                      onChanged: (String? value) {
                        setState(() {
                          _sortOption = value!;
                        });
                        _applyFiltersAndSort();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Brand Name (Z-A)'),
                    leading: Radio<String>(
                      value: 'brand_za',
                      groupValue: _sortOption,
                      onChanged: (String? value) {
                        setState(() {
                          _sortOption = value!;
                        });
                        _applyFiltersAndSort();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    String tempRiskLevel = _selectedRiskLevel;
    String tempCategory = _selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Build dynamic risk level options
            List<String> riskOptions = ['all', ..._availableRiskLevels];
            List<String> categoryOptions = ['all', ..._availableCategories];

            return AlertDialog(
              title: const Text('Filter Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Risk Level:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (riskOptions.isEmpty ||
                        (riskOptions.length == 1 && riskOptions[0] == 'all'))
                      const Text(
                        'No risk levels found in current data',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...riskOptions.map(
                        (level) => ListTile(
                          title: Text(
                            level == 'all' ? 'All Risk Levels' : level,
                          ),
                          leading: Radio<String>(
                            value: level,
                            groupValue: tempRiskLevel,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempRiskLevel = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (categoryOptions.isEmpty ||
                        (categoryOptions.length == 1 &&
                            categoryOptions[0] == 'all'))
                      const Text(
                        'No categories found in current data',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...categoryOptions.map(
                        (category) => ListTile(
                          title: Text(
                            category == 'all'
                                ? 'All Categories'
                                : category.toUpperCase(),
                          ),
                          leading: Radio<String>(
                            value: category,
                            groupValue: tempCategory,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempCategory = value!;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRiskLevel = tempRiskLevel;
                      _selectedCategory = tempCategory;
                    });
                    _applyFiltersAndSort();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with App Icon, Title Text and Menu Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
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
                  // Title Text
                  const Expanded(
                    child: Text(
                      'All FDA Recalls',
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
            // Content area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A4A5C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3547),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Atlanta',
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search FDA recalls...',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Atlanta',
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Filter and sort options
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showFilterDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D3547),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list,
                                  color:
                                      (_selectedRiskLevel != 'all' ||
                                          _selectedCategory != 'all')
                                      ? const Color(0xFF4A90E2)
                                      : Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    color:
                                        (_selectedRiskLevel != 'all' ||
                                            _selectedCategory != 'all')
                                        ? const Color(0xFF4A90E2)
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontFamily: 'Atlanta',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _showSortDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D3547),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sort',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontFamily: 'Atlanta',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredRecalls.length} recalls found',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontFamily: 'Atlanta',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Recalls list
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF4A90E2),
                              ),
                            )
                          : _filteredRecalls.isNotEmpty
                          ? ListView.builder(
                              itemCount: _filteredRecalls.length,
                              itemBuilder: (context, index) {
                                final recall = _filteredRecalls[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FdaRecallDetailsPage(
                                              recall: recall,
                                            ),
                                      ),
                                    );
                                  },
                                  child: FdaRecallCard(recall: recall),
                                );
                              },
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage.isNotEmpty
                                        ? _errorMessage
                                        : 'No FDA recalls found.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadFDARecalls,
                                    child: const Text('Retry'),
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
