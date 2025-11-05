import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../services/article_service.dart';
import '../models/recall_data.dart';
import '../models/article.dart';
import '../widgets/usda_recall_card.dart';
import '../widgets/article_card.dart';
import '../widgets/custom_back_button.dart';

class AllUSDARecallsPage extends StatefulWidget {
  const AllUSDARecallsPage({super.key});

  @override
  State<AllUSDARecallsPage> createState() => _AllUSDARecallsPageState();
}

class _AllUSDARecallsPageState extends State<AllUSDARecallsPage> {
  final RecallDataService _recallService = RecallDataService();
  final ArticleService _articleService = ArticleService();
  final TextEditingController _searchController = TextEditingController();
  List<RecallData> _usdaRecalls = [];
  List<RecallData> _filteredRecalls = [];
  List<Article> _usdaArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedRecallReason = 'all'; // 'all' or specific recall reason
  String _selectedRecallClassification =
      'all'; // 'all' or specific recall classification
  List<String> _availableRiskLevels =
      []; // Dynamic risk levels from actual data
  List<String> _availableRecallReasons =
      []; // Dynamic recall reasons from actual data
  List<String> _availableRecallClassifications =
      []; // Dynamic recall classifications from actual data

  @override
  void initState() {
    super.initState();
    print(
      '🔥 USDA Recalls Page: initState() called - starting to load recalls',
    );
    _loadUSDARecalls();
  }

  Future<void> _loadUSDARecalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 USDA Page: Starting to load recalls and articles...');

      // Load both recalls and articles in parallel
      final results = await Future.wait([
        _recallService.getFilteredRecalls(agency: 'USDA'),
        _articleService.getUsdaArticles(),
      ]);

      final allRecalls = results[0] as List<RecallData>;
      final articles = results[1] as List<Article>;

      print(
        '✅ USDA Page: Received ${allRecalls.length} total USDA recalls from service',
      );
      print('✅ USDA Page: Received ${articles.length} USDA articles');

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
          'Recent USDA Recall: ${recall.id} - ${recall.productName} - Agency: ${recall.agency} - Date: ${recall.dateIssued}',
        );
      }

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _usdaRecalls = recentRecalls;
          _usdaArticles = articles;
          _applyFiltersAndSort();
          print(
            '✅ Using ${recentRecalls.length} real USDA recalls from last 30 days from Google Sheets',
          );
        } else {
          print('⚠️ No recent USDA recalls found');
          _usdaRecalls = [];
          _usdaArticles = articles;
          _filteredRecalls = [];
        }
        _isLoading = false;
        _errorMessage = '';
        print(
          '🎯 USDA Page setState: _usdaRecalls.length = ${_usdaRecalls.length}',
        );
        print('🎯 USDA Page setState: _isLoading = $_isLoading');
        print('🎯 USDA Page setState: _errorMessage = "$_errorMessage"');
      });
    } catch (e) {
      print('❌ USDA Page Error: $e');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
        _usdaRecalls = [];
      });
    }
  }

  void _updateAvailableFilterOptions(List<RecallData> recalls) {
    // Extract unique risk levels from actual data
    Set<String> riskLevels = {};
    Set<String> recallReasons = {};
    Set<String> recallClassifications = {};

    for (var recall in recalls) {
      // Add risk level if not empty
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }

      // Add recall reason if not empty
      if (recall.category.trim().isNotEmpty) {
        recallReasons.add(recall.category.toLowerCase().trim());
      }

      // Add recall classification if not empty
      if (recall.recallClassification.trim().isNotEmpty) {
        recallClassifications.add(
          recall.recallClassification.toLowerCase().trim(),
        );
      }
    }

    // Sort the options for consistent display
    _availableRiskLevels = riskLevels.toList()..sort();
    _availableRecallReasons = recallReasons.toList()..sort();
    _availableRecallClassifications = recallClassifications.toList()..sort();

    // Reset filters if currently selected values are no longer available
    if (_selectedRiskLevel != 'all' &&
        !_availableRiskLevels.contains(_selectedRiskLevel)) {
      _selectedRiskLevel = 'all';
      print('🔄 Reset risk level filter - selected value no longer available');
    }

    if (_selectedRecallReason != 'all' &&
        !_availableRecallReasons.contains(_selectedRecallReason)) {
      _selectedRecallReason = 'all';
      print(
        '🔄 Reset recall reason filter - selected value no longer available',
      );
    }

    if (_selectedRecallClassification != 'all' &&
        !_availableRecallClassifications.contains(
          _selectedRecallClassification,
        )) {
      _selectedRecallClassification = 'all';
      print(
        '🔄 Reset recall classification filter - selected value no longer available',
      );
    }

    print('🎯 Available Risk Levels from data: $_availableRiskLevels');
    print('🎯 Available Recall Reasons from data: $_availableRecallReasons');
    print(
      '🎯 Available Recall Classifications from data: $_availableRecallClassifications',
    );
  }

  void _applyFiltersAndSort() {
    List<RecallData> filtered = List.from(_usdaRecalls);

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
            recall.recallClassification.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.packagingDesc.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.productQty.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            recall.soldBy.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply risk level filter
    if (_selectedRiskLevel != 'all') {
      filtered = filtered.where((recall) {
        return recall.riskLevel.toUpperCase().trim() ==
            _selectedRiskLevel.toUpperCase().trim();
      }).toList();
    }

    // Apply recall reason filter
    if (_selectedRecallReason != 'all') {
      filtered = filtered.where((recall) {
        return recall.category.toLowerCase().trim() ==
            _selectedRecallReason.toLowerCase().trim();
      }).toList();
    }

    // Apply recall classification filter
    if (_selectedRecallClassification != 'all') {
      filtered = filtered.where((recall) {
        return recall.recallClassification.toLowerCase().trim() ==
            _selectedRecallClassification.toLowerCase().trim();
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
    Set<String> recallReasons = {};
    Set<String> recallClassifications = {};

    for (var recall in filtered) {
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }
      if (recall.category.trim().isNotEmpty) {
        recallReasons.add(recall.category.toLowerCase().trim());
      }
      if (recall.recallClassification.trim().isNotEmpty) {
        recallClassifications.add(
          recall.recallClassification.toLowerCase().trim(),
        );
      }
    }

    // Only update if we're in a search context, otherwise keep original full dataset options
    if (_searchQuery.isNotEmpty) {
      _availableRiskLevels = riskLevels.toList()..sort();
      _availableRecallReasons = recallReasons.toList()..sort();
      _availableRecallClassifications = recallClassifications.toList()..sort();
      print(
        '🔄 Updated filter options for search context: Risk levels: $_availableRiskLevels, Recall Reasons: $_availableRecallReasons, Recall Classifications: $_availableRecallClassifications',
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
    String tempRecallReason = _selectedRecallReason;
    String tempRecallClassification = _selectedRecallClassification;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Build dynamic risk level options
            List<String> riskOptions = ['all', ..._availableRiskLevels];
            List<String> recallReasonOptions = [
              'all',
              ..._availableRecallReasons,
            ];
            List<String> recallClassificationOptions = [
              'all',
              ..._availableRecallClassifications,
            ];

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
                      'Recall Reason:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (recallReasonOptions.isEmpty ||
                        (recallReasonOptions.length == 1 &&
                            recallReasonOptions[0] == 'all'))
                      const Text(
                        'No recall reasons found in current data',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...recallReasonOptions.map(
                        (recallReason) => ListTile(
                          title: Text(
                            recallReason == 'all'
                                ? 'All Recall Reasons'
                                : recallReason.toUpperCase(),
                          ),
                          leading: Radio<String>(
                            value: recallReason,
                            groupValue: tempRecallReason,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempRecallReason = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Recall Classification:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (recallClassificationOptions.isEmpty ||
                        (recallClassificationOptions.length == 1 &&
                            recallClassificationOptions[0] == 'all'))
                      const Text(
                        'No recall classifications found in current data',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...recallClassificationOptions.map(
                        (recallClassification) => ListTile(
                          title: Text(
                            recallClassification == 'all'
                                ? 'All Recall Classifications'
                                : recallClassification.toUpperCase(),
                          ),
                          leading: Radio<String>(
                            value: recallClassification,
                            groupValue: tempRecallClassification,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempRecallClassification = value!;
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
                      _selectedRecallReason = tempRecallReason;
                      _selectedRecallClassification = tempRecallClassification;
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

  /// Build interleaved list with recalls and articles
  /// Inserts an article card after every 3rd recall card
  List<Widget> _buildInterleavedList() {
    List<Widget> widgets = [];
    int articleIndex = 0;

    for (int i = 0; i < _filteredRecalls.length; i++) {
      final recall = _filteredRecalls[i];

      // Add recall card
      widgets.add(UsdaRecallCard(recall: recall));

      // Insert article card after every 3rd recall
      if ((i + 1) % 3 == 0 &&
          articleIndex < _usdaArticles.length &&
          _usdaArticles.isNotEmpty) {
        widgets.add(ArticleCard(article: _usdaArticles[articleIndex]));
        articleIndex++;
      }
    }

    return widgets;
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
                : 'No USDA recalls found in the last 30 days.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUSDARecalls,
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
        itemCount: _buildInterleavedList().length,
        itemBuilder: (context, index) {
          return _buildInterleavedList()[index];
        },
      ),
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
                      'All USDA Recalls',
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
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
