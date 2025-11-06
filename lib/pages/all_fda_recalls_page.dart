import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../services/article_service.dart';
import '../services/subscription_service.dart';
import '../services/saved_filter_service.dart';
import '../models/recall_data.dart';
import '../models/article.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/article_card.dart';
import '../widgets/custom_back_button.dart';
import 'subscribe_page.dart';

class AllFDARecallsPage extends StatefulWidget {
  const AllFDARecallsPage({super.key});

  @override
  State<AllFDARecallsPage> createState() => _AllFDARecallsPageState();
}

class _AllFDARecallsPageState extends State<AllFDARecallsPage> {
  final RecallDataService _recallService = RecallDataService();
  final ArticleService _articleService = ArticleService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  List<RecallData> _fdaRecalls = [];
  List<RecallData> _filteredRecalls = [];
  List<Article> _fdaArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedCategory = 'all'; // 'all' or specific category
  List<String> _selectedStates = []; // Selected states for filtering
  List<String> _availableRiskLevels =
      []; // Dynamic risk levels from actual data
  List<String> _availableCategories = []; // Dynamic categories from actual data
  List<String> _availableStates = []; // Dynamic states from actual data
  bool _showSearchAndFilters = true;
  bool _isSearchFieldFocused = false; // Track if search field is currently focused
  bool _keepButtonVisible = false; // Keep button visible even when focus is lost (during save)

  @override
  void initState() {
    super.initState();
    print('🔥 FDA Recalls Page: initState() called - starting to load recalls');
    _loadFDARecalls();
    _scrollController.addListener(_onScroll);

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFieldFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  void _onScroll() {
    // Hide search/filters when scrolling down, show when scrolling up or at top
    if (_scrollController.hasClients) {
      final isAtTop = _scrollController.offset <= 10;
      final shouldShow = isAtTop;

      if (shouldShow != _showSearchAndFilters) {
        setState(() {
          _showSearchAndFilters = shouldShow;
        });
      }
    }
  }

  Future<void> _loadFDARecalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('🔍 FDA Page: Starting to load recalls and articles...');

      // Load both recalls and articles in parallel
      final results = await Future.wait([
        _recallService.getFilteredRecalls(agency: 'FDA'),
        _articleService.getFdaArticles(),
      ]);

      final allRecalls = results[0] as List<RecallData>;
      final articles = results[1] as List<Article>;

      print(
        '✅ FDA Page: Received ${allRecalls.length} total FDA recalls from service',
      );
      print('✅ FDA Page: Received ${articles.length} FDA articles');

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

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _fdaRecalls = recentRecalls;
          _fdaArticles = articles;
          _applyFiltersAndSort();
          print(
            '✅ Using ${recentRecalls.length} real FDA recalls from last 30 days from Google Sheets',
          );
        } else {
          print('⚠️ No recent FDA recalls found');
          _fdaRecalls = [];
          _fdaArticles = articles;
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
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
        _fdaRecalls = [];
      });
    }
  }

  void _updateAvailableFilterOptions(List<RecallData> recalls) {
    // Extract unique risk levels, categories, and states from actual data
    Set<String> riskLevels = {};
    Set<String> categories = {};
    Set<String> states = {};

    for (var recall in recalls) {
      // Add risk level if not empty
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }

      // Add category if not empty
      if (recall.category.trim().isNotEmpty) {
        categories.add(recall.category.toLowerCase().trim());
      }

      // Extract states from distributionPattern
      if (recall.distributionPattern.trim().isNotEmpty) {
        final pattern = recall.distributionPattern.trim();

        // Skip "Nationwide" - we'll handle it separately in the filter
        if (pattern.toLowerCase() != 'nationwide') {
          // Split by comma and extract individual states
          final stateList = pattern.split(',');
          for (var state in stateList) {
            final trimmedState = state.trim();
            if (trimmedState.isNotEmpty) {
              // Add the state (could be abbreviation or full name)
              states.add(trimmedState);
            }
          }
        }
      }
    }

    // Sort the options for consistent display
    _availableRiskLevels = riskLevels.toList()..sort();
    _availableCategories = categories.toList()..sort();
    _availableStates = states.toList()..sort();

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

    // Reset state selections if any selected states are no longer available
    if (_selectedStates.isNotEmpty) {
      _selectedStates.removeWhere((state) => !_availableStates.contains(state));
      if (_selectedStates.isEmpty) {
        print('🔄 Reset state filter - selected values no longer available');
      }
    }

    print('🎯 Available Risk Levels from data: $_availableRiskLevels');
    print('🎯 Available Categories from data: $_availableCategories');
    print('🎯 Available States from data: ${_availableStates.length} states');
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

    // Apply state filter
    if (_selectedStates.isNotEmpty) {
      filtered = filtered.where((recall) {
        final pattern = recall.distributionPattern.trim();

        // If the recall is nationwide, it matches all state filters
        if (pattern.toLowerCase() == 'nationwide') {
          return true;
        }

        // Check if any of the selected states are in the distribution pattern
        for (var selectedState in _selectedStates) {
          if (pattern.contains(selectedState)) {
            return true;
          }
        }

        return false;
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

  Future<void> _showSaveSmartFilterDialog() async {
    // Get subscription info
    final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();

    // Check if user has premium access
    if (!subscriptionInfo.hasPremiumAccess) {
      // Show upgrade dialog for free users
      if (!mounted) return;
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
                  'Premium Feature',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Saving SmartFilters is a premium feature. Upgrade to SmartFiltering or RecallMatch to save your custom filter combinations.',
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
      return;
    }

    // Build filter description from current filters
    List<String> filterParts = [];
    if (_searchQuery.isNotEmpty) {
      filterParts.add('Search: "$_searchQuery"');
    }
    if (_selectedRiskLevel != 'all') {
      filterParts.add('Risk: $_selectedRiskLevel');
    }
    if (_selectedCategory != 'all') {
      filterParts.add('Category: $_selectedCategory');
    }
    if (_selectedStates.isNotEmpty) {
      filterParts.add('States: ${_selectedStates.join(', ')}');
    }

    final filterDescription = filterParts.isEmpty
        ? 'All FDA Recalls'
        : filterParts.join(' | ');

    // For now, we'll save search query as both brand and product filter
    // This is a simplified approach - you may want to enhance this
    final brandFilters = _searchQuery.isNotEmpty ? [_searchQuery] : <String>[];
    final productFilters = _searchQuery.isNotEmpty ? [_searchQuery] : <String>[];

    if (!mounted) return;

    // Show save dialog
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A4A5C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Row(
                children: [
                  Icon(Icons.save_outlined, color: Color(0xFF64B5F6), size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Save SmartFilter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3547),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Current Filters',
                                style: TextStyle(
                                  color: Color(0xFF64B5F6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filterDescription,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name field
                    const Text(
                      'Filter Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'e.g., FDA Food Recalls - High Risk',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1D3547),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description field
                    const Text(
                      'Description (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a description...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1D3547),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a filter name'),
                          backgroundColor: Color(0xFFE53935),
                        ),
                      );
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      final filterService = SavedFilterService();
                      await filterService.createSavedFilter(
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        brandFilters: brandFilters,
                        productFilters: productFilters,
                      );

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SmartFilter saved successfully!'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    } on TierLimitException catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.message),
                          backgroundColor: const Color(0xFFE53935),
                        ),
                      );
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save filter: $e'),
                          backgroundColor: const Color(0xFFE53935),
                        ),
                      );
                    }
                  },
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, size: 18, color: Colors.white),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save SmartFilter',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() async {
    // Get subscription info to determine state filter limit
    final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();
    final stateLimit = subscriptionInfo.getStateFilterLimit();

    String tempRiskLevel = _selectedRiskLevel;
    String tempCategory = _selectedCategory;
    List<String> tempSelectedStates = List.from(_selectedStates);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Build dynamic risk level options
            List<String> riskOptions = ['all', ..._availableRiskLevels];
            List<String> categoryOptions = ['all', ..._availableCategories];

            return AlertDialog(
              backgroundColor: const Color(0xFF2A4A5C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Filter Options',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Save as SmartFilter button at top of dialog
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close filter dialog
                          _showSaveSmartFilterDialog(); // Show save dialog
                        },
                        icon: Icon(
                          Icons.bookmark_add,
                          size: 18,
                          color: subscriptionInfo.hasPremiumAccess ? Colors.white : Colors.white54,
                        ),
                        label: Text(
                          'Save as SmartFilter',
                          style: TextStyle(
                            color: subscriptionInfo.hasPremiumAccess ? Colors.white : Colors.white54,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: subscriptionInfo.hasPremiumAccess
                              ? const Color(0xFF64B5F6)
                              : Colors.grey.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: subscriptionInfo.hasPremiumAccess ? 2 : 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),

                    // Risk Level Filter
                    const Text(
                      'Risk Level:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (riskOptions.isEmpty ||
                        (riskOptions.length == 1 && riskOptions[0] == 'all'))
                      const Text(
                        'No risk level data available',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      ...riskOptions.map((level) {
                        return RadioListTile<String>(
                          title: Text(
                            level == 'all' ? 'All Risk Levels' : level,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: level,
                          groupValue: tempRiskLevel,
                          onChanged: (value) {
                            setDialogState(() {
                              tempRiskLevel = value!;
                            });
                          },
                          activeColor: const Color(0xFF64B5F6),
                        );
                      }),
                    const Divider(color: Colors.white24),

                    // Category Filter
                    const Text(
                      'Category:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (categoryOptions.isEmpty ||
                        (categoryOptions.length == 1 &&
                            categoryOptions[0] == 'all'))
                      const Text(
                        'No category data available',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      ...categoryOptions.map((category) {
                        return RadioListTile<String>(
                          title: Text(
                            category == 'all'
                                ? 'All Categories'
                                : category.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: category,
                          groupValue: tempCategory,
                          onChanged: (value) {
                            setDialogState(() {
                              tempCategory = value!;
                            });
                          },
                          activeColor: const Color(0xFF64B5F6),
                        );
                      }),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),

                    // State Filter
                    const Text(
                      'States:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stateLimit == 999
                          ? 'Select states (unlimited)'
                          : 'Select up to $stateLimit state${stateLimit == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getUsStates().map((state) {
                        final isSelected = tempSelectedStates.contains(state);
                        final canSelect = isSelected || tempSelectedStates.length < stateLimit;

                        return FilterChip(
                          label: Text(state),
                          selected: isSelected,
                          onSelected: canSelect
                              ? (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      tempSelectedStates.add(state);
                                    } else {
                                      tempSelectedStates.remove(state);
                                    }
                                  });
                                }
                              : null,
                          selectedColor: const Color(0xFF64B5F6),
                          backgroundColor: const Color(0xFF1D3547),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          disabledColor: Colors.grey.withValues(alpha: 0.3),
                        );
                      }).toList(),
                    ),
                    if (tempSelectedStates.length >= stateLimit && stateLimit != 999) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3547),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Upgrade to SmartFiltering for 3 states or RecallMatch for unlimited',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRiskLevel = tempRiskLevel;
                      _selectedCategory = tempCategory;
                      _selectedStates = tempSelectedStates;
                      _applyFiltersAndSort();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                  ),
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

      // Add recall card with spacing
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SmallFdaRecallCard(recall: recall),
        ),
      );

      // Insert article card after every 3rd recall
      if ((i + 1) % 3 == 0 &&
          articleIndex < _fdaArticles.length &&
          _fdaArticles.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ArticleCard(article: _fdaArticles[articleIndex]),
          ),
        );
        articleIndex++;
      }
    }

    // Add upgrade section at the end for free users
    widgets.add(
      FutureBuilder<SubscriptionInfo>(
        future: _subscriptionService.getSubscriptionInfo(),
        builder: (context, snapshot) {
          final subscriptionInfo = snapshot.data;

          // Only show to free users
          if (subscriptionInfo == null || subscriptionInfo.hasPremiumAccess) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.only(top: 24, bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2A4A5C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(height: 16),
                const Text(
                  '30-Day Recall Limit Reached',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upgrade to SmartFiltering or RecallMatch Plans to access older recalls and unlock other great features.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SubscribePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Free users can view recalls from the last 30 days',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    return widgets;
  }

  List<String> _getUsStates() {
    return [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    ];
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
                : 'No FDA recalls found in the last 30 days.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFDARecalls,
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
      controller: _scrollController,
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
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547), // Dark blue background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button and Centered App Icon + Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  // Back button on the left
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CustomBackButton(),
                  ),
                  // Centered App Icon and Title
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
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
                        const SizedBox(width: 12),
                        const Text(
                          'All FDA Recalls',
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
                ],
              ),
            ),
            if (_showSearchAndFilters) ...[
              const SizedBox(height: 16),

              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search FDA recalls...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              _applyFiltersAndSort();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  focusNode: _searchFocusNode,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFiltersAndSort();
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Filter and Sort Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showFilterDialog,
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text('Filter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showSortDialog,
                        icon: const Icon(Icons.sort, size: 18),
                        label: const Text('Sort'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Conditionally show Save as SmartFilter button only when search field is focused or button is being interacted with
              if (_isSearchFieldFocused || _keepButtonVisible) ...[
                const SizedBox(height: 12),

                // Save as SmartFilter Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FutureBuilder<SubscriptionInfo>(
                    future: _subscriptionService.getSubscriptionInfo(),
                    builder: (context, snapshot) {
                      final hasPremiumAccess = snapshot.data?.hasPremiumAccess ?? false;

                      return Listener(
                        onPointerDown: (_) {
                          // Keep button visible when user starts interacting
                          setState(() {
                            _keepButtonVisible = true;
                          });
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: hasPremiumAccess ? () {
                              _showSaveSmartFilterDialog();
                              // Reset after a delay to allow dialog to open
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  setState(() {
                                    _keepButtonVisible = false;
                                  });
                                }
                              });
                            } : () {
                              _showSaveSmartFilterDialog();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  setState(() {
                                    _keepButtonVisible = false;
                                  });
                                }
                              });
                            },
                          icon: Icon(
                            Icons.bookmark_add,
                            size: 18,
                            color: hasPremiumAccess ? Colors.white : Colors.white54,
                          ),
                          label: Text(
                            'Save as SmartFilter',
                            style: TextStyle(
                              color: hasPremiumAccess ? Colors.white : Colors.white54,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasPremiumAccess
                                ? const Color(0xFF64B5F6)
                                : const Color(0xFF2C3E50).withValues(alpha: 0.5),
                            foregroundColor: hasPremiumAccess ? Colors.white : Colors.white54,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: hasPremiumAccess ? 2 : 0,
                          ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

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
