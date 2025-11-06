import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../services/article_service.dart';
import '../services/subscription_service.dart';
import '../services/saved_filter_service.dart';
import '../models/recall_data.dart';
import '../models/article.dart';
import '../widgets/small_usda_recall_card.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/article_card.dart';
import '../widgets/custom_back_button.dart';
import 'subscribe_page.dart';

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
  final ArticleService _articleService = ArticleService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<RecallData> _allRecalls = [];
  List<RecallData> _filteredRecalls = [];
  List<Article> _articles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedCategory = 'all'; // 'all' or specific category
  String _selectedAgency = 'all'; // 'all', 'FDA', 'USDA'
  List<String> _selectedStates = []; // Selected state filters
  List<String> _availableRiskLevels = []; // Dynamic risk levels from actual data
  List<String> _availableCategories = []; // Dynamic categories from actual data
  List<String> _availableAgencies = []; // Dynamic agencies from actual data
  bool _isSearchFieldFocused = false; // Track if search field is currently focused
  bool _keepButtonVisible = false; // Keep button visible even when focus is lost (during save)
  final int _currentIndex = 1; // Recalls tab

  @override
  void initState() {
    super.initState();
    if (widget.filteredRecalls != null) {
      setState(() {
        _allRecalls = widget.filteredRecalls!;
        _filteredRecalls = widget.filteredRecalls!;
        _updateAvailableFilterOptions(_filteredRecalls);
        _isLoading = false;
      });
      _loadArticles();
    } else {
      _loadFilteredRecalls();
    }

    // Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFieldFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await _articleService.getArticles();
      if (mounted) {
        setState(() {
          _articles = articles;
        });
      }
    } catch (e) {
      print('Failed to load articles: $e');
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

      // Apply category filters (brand and product)
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

      // Extract unique filter options from actual data
      _updateAvailableFilterOptions(filtered);

      // Load articles (no tag filter - get all articles)
      List<Article> articles = [];
      try {
        articles = await _articleService.getArticles();
        print('Loaded ${articles.length} articles for Category Filter page');
      } catch (e) {
        print('Failed to load articles: $e');
      }

      if (!mounted) return;

      setState(() {
        _allRecalls = filtered;
        _articles = articles;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
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
    }

    if (_selectedCategory != 'all' &&
        !_availableCategories.contains(_selectedCategory)) {
      _selectedCategory = 'all';
    }

    if (_selectedAgency != 'all' &&
        !_availableAgencies.contains(_selectedAgency)) {
      _selectedAgency = 'all';
    }
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

    // Apply state filter
    if (_selectedStates.isNotEmpty) {
      filtered = filtered.where((recall) {
        // Check if any of the selected states match the recall's product distribution
        for (var selectedState in _selectedStates) {
          if (recall.productDistribution.toLowerCase().contains(selectedState.toLowerCase()) ||
              recall.productDistribution.toLowerCase() == 'nationwide' ||
              recall.productDistribution.toLowerCase() == 'all states') {
            return true;
          }
        }
        return false;
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

  List<String> _getUsStates() {
    return [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    ];
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

    // Include category filters
    if (widget.brandFilters.isNotEmpty) {
      filterParts.add('Brands: ${widget.brandFilters.join(', ')}');
    }
    if (widget.productFilters.isNotEmpty) {
      filterParts.add('Products: ${widget.productFilters.join(', ')}');
    }

    if (_searchQuery.isNotEmpty) {
      filterParts.add('Search: "$_searchQuery"');
    }
    if (_selectedRiskLevel != 'all') {
      filterParts.add('Risk: $_selectedRiskLevel');
    }
    if (_selectedCategory != 'all') {
      filterParts.add('Category: $_selectedCategory');
    }
    if (_selectedAgency != 'all') {
      filterParts.add('Agency: $_selectedAgency');
    }
    if (_selectedStates.isNotEmpty) {
      filterParts.add('States: ${_selectedStates.join(', ')}');
    }

    final filterDescription = filterParts.isEmpty
        ? 'Filtered Recalls by Category'
        : filterParts.join(' | ');

    // Combine search query with brand/product filters
    final brandFilters = [
      ...widget.brandFilters,
      if (_searchQuery.isNotEmpty) _searchQuery,
    ];
    final productFilters = [
      ...widget.productFilters,
      if (_searchQuery.isNotEmpty) _searchQuery,
    ];

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
                        hintText: 'e.g., Category High Risk Recalls',
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
                  onPressed: isSaving
                      ? null
                      : () async {
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
    String tempAgency = _selectedAgency;
    List<String> tempStates = List.from(_selectedStates);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get available options - use ['all'] if empty
            final riskOptions = _availableRiskLevels.isEmpty ? ['all'] : ['all', ..._availableRiskLevels];
            final categoryOptions = _availableCategories.isEmpty ? ['all'] : ['all', ..._availableCategories];
            final agencyOptions = _availableAgencies.isEmpty ? ['all'] : ['all', ..._availableAgencies];

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
                    if (riskOptions.isEmpty || (riskOptions.length == 1 && riskOptions[0] == 'all'))
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
                            setState(() {
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
                    if (categoryOptions.isEmpty || (categoryOptions.length == 1 && categoryOptions[0] == 'all'))
                      const Text(
                        'No category data available',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      ...categoryOptions.map((category) {
                        return RadioListTile<String>(
                          title: Text(
                            category == 'all' ? 'All Categories' : category,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: category,
                          groupValue: tempCategory,
                          onChanged: (value) {
                            setState(() {
                              tempCategory = value!;
                            });
                          },
                          activeColor: const Color(0xFF64B5F6),
                        );
                      }),
                    const Divider(color: Colors.white24),

                    // Agency Filter
                    const Text(
                      'Agency:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    if (agencyOptions.isEmpty || (agencyOptions.length == 1 && agencyOptions[0] == 'all'))
                      const Text(
                        'No agency data available',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      ...agencyOptions.map((agency) {
                        return RadioListTile<String>(
                          title: Text(
                            agency == 'all' ? 'All Agencies' : agency,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: agency,
                          groupValue: tempAgency,
                          onChanged: (value) {
                            setState(() {
                              tempAgency = value!;
                            });
                          },
                          activeColor: const Color(0xFF64B5F6),
                        );
                      }),
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
                        final isSelected = tempStates.contains(state);
                        final canSelect = isSelected || tempStates.length < stateLimit;

                        return FilterChip(
                          label: Text(state),
                          selected: isSelected,
                          onSelected: canSelect
                              ? (selected) {
                                  setState(() {
                                    if (selected) {
                                      tempStates.add(state);
                                    } else {
                                      tempStates.remove(state);
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
                    if (tempStates.length >= stateLimit && stateLimit != 999) ...[
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
                    this.setState(() {
                      _selectedRiskLevel = tempRiskLevel;
                      _selectedCategory = tempCategory;
                      _selectedAgency = tempAgency;
                      _selectedStates = tempStates;
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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Sort By',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Most Recent', style: TextStyle(color: Colors.white)),
                value: 'date',
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                activeColor: const Color(0xFF64B5F6),
              ),
              RadioListTile<String>(
                title: const Text('Brand A-Z', style: TextStyle(color: Colors.white)),
                value: 'brand_az',
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                activeColor: const Color(0xFF64B5F6),
              ),
              RadioListTile<String>(
                title: const Text('Brand Z-A', style: TextStyle(color: Colors.white)),
                value: 'brand_za',
                groupValue: _sortOption,
                onChanged: (value) {
                  setState(() {
                    _sortOption = value!;
                    _applyFiltersAndSort();
                  });
                  Navigator.of(context).pop();
                },
                activeColor: const Color(0xFF64B5F6),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterleavedList() {
    // Build list with articles interspersed
    List<Widget> widgets = [];
    int articleIndex = 0;

    // Add recall cards with article cards interspersed every 3 recalls
    for (int i = 0; i < _filteredRecalls.length; i++) {
      final recall = _filteredRecalls[i];

      // Add recall card with spacing
      if (recall.agency.toUpperCase() == 'USDA') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SmallUsdaRecallCard(recall: recall),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SmallFdaRecallCard(recall: recall),
          ),
        );
      }

      // Insert article card after every 3rd recall
      if ((i + 1) % 3 == 0 &&
          articleIndex < _articles.length &&
          _articles.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ArticleCard(article: _articles[articleIndex]),
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

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
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
              const CustomBackButton(),
              const SizedBox(width: 8),
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
                    'assets/images/shield_logo3.png',
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
            // Active Filters Section
            if (widget.brandFilters.isNotEmpty || widget.productFilters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
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
              ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFiltersAndSort();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search recalls...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFiltersAndSort();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2C3E50),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
            const SizedBox(height: 12),

            // Found recalls count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
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

            // Main Content Area
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF64B5F6),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredRecalls.isNotEmpty
                          ? _buildInterleavedList()
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
