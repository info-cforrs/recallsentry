import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../services/article_service.dart';
import '../services/subscription_service.dart';
import '../models/recall_data.dart';
import '../models/article.dart';
import '../widgets/small_cpsc_recall_card.dart';
import '../widgets/article_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import 'subscribe_page.dart';

class AllCPSCRecallsPage extends StatefulWidget {
  const AllCPSCRecallsPage({super.key});

  @override
  State<AllCPSCRecallsPage> createState() => _AllCPSCRecallsPageState();
}

class _AllCPSCRecallsPageState extends State<AllCPSCRecallsPage> with HideOnScrollMixin {
  final RecallDataService _recallService = RecallDataService();
  final ArticleService _articleService = ArticleService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<RecallData> _cpscRecalls = [];
  List<RecallData> _filteredRecalls = [];
  List<Article> _cpscArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all'; // 'all', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedCategory = 'all'; // 'all' or specific category
  List<String> _selectedStates = []; // Selected states for filtering
  List<String> _availableRiskLevels = [];
  List<String> _availableCategories = [];
  List<String> _availableStates = [];
  bool _showSearchAndFilters = true;

  // PAGINATION: Infinite scroll state
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMoreRecalls = true;

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _loadCPSCRecalls();
    hideOnScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (hideOnScrollController.hasClients) {
      final isAtTop = hideOnScrollController.offset <= 10;
      final shouldShow = isAtTop;

      if (shouldShow != _showSearchAndFilters) {
        setState(() {
          _showSearchAndFilters = shouldShow;
        });
      }

      // PAGINATION: Load more recalls when near bottom
      final maxScroll = hideOnScrollController.position.maxScrollExtent;
      final currentScroll = hideOnScrollController.position.pixels;
      final delta = 200.0;

      if (maxScroll - currentScroll <= delta &&
          !_isLoadingMore &&
          _hasMoreRecalls &&
          !_isLoading) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadCPSCRecalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 0;
      _hasMoreRecalls = true;
    });

    try {
      // PAGINATION: Load first page of recalls and articles in parallel
      final results = await Future.wait([
        _recallService.getCpscRecalls(limit: _pageSize, offset: 0),
        _articleService.getCpscArticles(),
      ]);

      final firstPageRecalls = results[0] as List<RecallData>;
      final articles = results[1] as List<Article>;

      // Filter recalls to last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRecalls = firstPageRecalls.where((recall) {
        return recall.dateIssued.isAfter(thirtyDaysAgo);
      }).toList();

      // Sort by date (most recent first)
      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));

      _updateAvailableFilterOptions(recentRecalls);

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _cpscRecalls = recentRecalls;
          _cpscArticles = articles;
          _applyFiltersAndSort();
          _hasMoreRecalls = recentRecalls.length == _pageSize;
        } else {
          _cpscRecalls = [];
          _cpscArticles = articles;
          _filteredRecalls = [];
          _hasMoreRecalls = false;
        }
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading recalls: $e';
        _isLoading = false;
        _cpscRecalls = [];
        _hasMoreRecalls = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (!mounted || _isLoadingMore || !_hasMoreRecalls) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final offset = (_currentPage + 1) * _pageSize;

      final nextPageRecalls = await _recallService.getCpscRecalls(
        limit: _pageSize,
        offset: offset,
      );

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRecalls = nextPageRecalls.where((recall) {
        return recall.dateIssued.isAfter(thirtyDaysAgo);
      }).toList();

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _cpscRecalls.addAll(recentRecalls);
          _currentPage++;
          _updateAvailableFilterOptions(_cpscRecalls);
          _applyFiltersAndSort();
          _hasMoreRecalls = recentRecalls.length == _pageSize;
        } else {
          _hasMoreRecalls = false;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _updateAvailableFilterOptions(List<RecallData> recalls) {
    Set<String> riskLevels = {};
    Set<String> categories = {};
    Set<String> states = {};

    for (var recall in recalls) {
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }

      if (recall.category.trim().isNotEmpty) {
        categories.add(recall.category.toLowerCase().trim());
      }

      if (recall.distributionPattern.trim().isNotEmpty) {
        final pattern = recall.distributionPattern.trim();

        if (pattern.toLowerCase() != 'nationwide') {
          final stateList = pattern.split(',');
          for (var state in stateList) {
            final trimmedState = state.trim();
            if (trimmedState.isNotEmpty) {
              states.add(trimmedState);
            }
          }
        }
      }
    }

    _availableRiskLevels = riskLevels.toList()..sort();
    _availableCategories = categories.toList()..sort();
    _availableStates = states.toList()..sort();

    if (_selectedRiskLevel != 'all' &&
        !_availableRiskLevels.contains(_selectedRiskLevel)) {
      _selectedRiskLevel = 'all';
    }

    if (_selectedCategory != 'all' &&
        !_availableCategories.contains(_selectedCategory)) {
      _selectedCategory = 'all';
    }

    if (_selectedStates.isNotEmpty) {
      _selectedStates.removeWhere((state) => !_availableStates.contains(state));
    }
  }

  void _applyFiltersAndSort() {
    List<RecallData> filtered = List.from(_cpscRecalls);

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

    if (_selectedRiskLevel != 'all') {
      filtered = filtered.where((recall) {
        return recall.riskLevel.toUpperCase().trim() ==
            _selectedRiskLevel.toUpperCase().trim();
      }).toList();
    }

    if (_selectedCategory != 'all') {
      filtered = filtered.where((recall) {
        return recall.category.toLowerCase().trim() ==
            _selectedCategory.toLowerCase().trim();
      }).toList();
    }

    if (_selectedStates.isNotEmpty) {
      filtered = filtered.where((recall) {
        final pattern = recall.distributionPattern.trim();

        if (pattern.toLowerCase() == 'nationwide') {
          return true;
        }

        for (var selectedState in _selectedStates) {
          if (pattern.contains(selectedState)) {
            return true;
          }
        }

        return false;
      }).toList();
    }

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

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sort Options'),
              content: RadioGroup<String>(
                groupValue: _sortOption,
                onChanged: (String? value) {
                  setState(() {
                    _sortOption = value!;
                  });
                  _applyFiltersAndSort();
                  Navigator.of(context).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Date (Newest First)'),
                      leading: Radio<String>(value: 'date'),
                    ),
                    ListTile(
                      title: const Text('Brand Name (A-Z)'),
                      leading: Radio<String>(value: 'brand_az'),
                    ),
                    ListTile(
                      title: const Text('Brand Name (Z-A)'),
                      leading: Radio<String>(value: 'brand_za'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() async {
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
            List<String> riskOptions = ['all', ..._availableRiskLevels];
            List<String> categoryOptions = ['all', ..._availableCategories];

            return AlertDialog(
              backgroundColor: const Color(0xFF2A4A5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Filter Options',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Risk Level Filter
                    const Text(
                      'Risk Level:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (riskOptions.isEmpty ||
                        (riskOptions.length == 1 && riskOptions[0] == 'all'))
                      const Text(
                        'No risk level data available',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      RadioGroup<String>(
                        groupValue: tempRiskLevel,
                        onChanged: (value) {
                          setDialogState(() {
                            tempRiskLevel = value!;
                          });
                        },
                        child: Column(
                          children: riskOptions.map((level) {
                            return RadioListTile<String>(
                              title: Text(
                                level == 'all' ? 'All Risk Levels' : level,
                                style: const TextStyle(color: Colors.white),
                              ),
                              value: level,
                              activeColor: const Color(0xFF64B5F6),
                            );
                          }).toList(),
                        ),
                      ),
                    const Divider(color: Colors.white24),

                    // Category Filter
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                      RadioGroup<String>(
                        groupValue: tempCategory,
                        onChanged: (value) {
                          setDialogState(() {
                            tempCategory = value!;
                          });
                        },
                        child: Column(
                          children: categoryOptions.map((category) {
                            return RadioListTile<String>(
                              title: Text(
                                category == 'all'
                                    ? 'All Categories'
                                    : category.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              value: category,
                              activeColor: const Color(0xFF64B5F6),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),

                    // State Filter
                    const Text(
                      'States:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stateLimit == 999
                          ? 'Select states (unlimited)'
                          : 'Select up to $stateLimit state${stateLimit == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getUsStates().map((state) {
                        final isSelected = tempSelectedStates.contains(state);
                        final canSelect =
                            isSelected ||
                            tempSelectedStates.length < stateLimit;

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

  int _getTotalItemCount() {
    if (_filteredRecalls.isEmpty) return 0;

    final articlesCount = _cpscArticles.isEmpty
        ? 0
        : (_filteredRecalls.length / 3).floor().clamp(0, _cpscArticles.length);

    return _filteredRecalls.length + articlesCount + 1;
  }

  bool _isArticleAtIndex(int index) {
    if (_cpscArticles.isEmpty) return false;

    if ((index + 1) % 4 != 0) return false;

    final articleIndex = (index + 1) ~/ 4 - 1;

    return articleIndex < _cpscArticles.length;
  }

  int _getRecallIndex(int itemIndex) {
    final articlesBefore = ((itemIndex + 1) ~/ 4);
    return itemIndex - articlesBefore;
  }

  int _getArticleIndex(int itemIndex) {
    return (itemIndex + 1) ~/ 4 - 1;
  }

  Widget _buildInterleavedListItem(int index) {
    final totalItems = _getTotalItemCount();

    // Last item is the upgrade banner
    if (index == totalItems - 1) {
      return FutureBuilder<SubscriptionInfo>(
        future: _subscriptionService.getSubscriptionInfo(),
        builder: (context, snapshot) {
          final subscriptionInfo = snapshot.data;

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
      );
    }

    if (_isArticleAtIndex(index)) {
      final articleIndex = _getArticleIndex(index);
      if (articleIndex < _cpscArticles.length) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ArticleCard(article: _cpscArticles[articleIndex]),
        );
      }
    }

    final recallIndex = _getRecallIndex(index);
    if (recallIndex < _filteredRecalls.length) {
      final recall = _filteredRecalls[recallIndex];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SmallCpscRecallCard(recall: recall),
      );
    }

    return const SizedBox.shrink();
  }

  List<String> _getUsStates() {
    return [
      'AL',
      'AK',
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'FL',
      'GA',
      'HI',
      'ID',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'LA',
      'ME',
      'MD',
      'MA',
      'MI',
      'MN',
      'MS',
      'MO',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'OH',
      'OK',
      'OR',
      'PA',
      'RI',
      'SC',
      'SD',
      'TN',
      'TX',
      'UT',
      'VT',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY',
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _errorMessage.isNotEmpty ? Icons.error_outline : Icons.info_outline,
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
                : 'No CPSC recalls found in the last 30 days.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCPSCRecalls,
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
    final totalItems = _getTotalItemCount();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _currentPage = 0;
          _hasMoreRecalls = true;
          _cpscRecalls = [];
        });
        await _loadCPSCRecalls();
      },
      color: const Color(0xFF64B5F6),
      backgroundColor: const Color(0xFF2C3E50),
      child: SingleChildScrollView(
        controller: hideOnScrollController,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                return _buildInterleavedListItem(index);
              },
            ),
            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: const Color(0xFF64B5F6),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading more recalls...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            if (!_hasMoreRecalls && _cpscRecalls.isNotEmpty && !_isLoadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'All recalls loaded',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    disposeHideOnScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Back Button and Centered App Icon + Title
            AnimatedVisibilityWrapper(
              isVisible: isHeaderVisible,
              direction: SlideDirection.up,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: CustomBackButton(),
                    ),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
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
                          const SizedBox(width: 12),
                          const Text(
                            'All CPSC Recalls',
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
                    hintText: 'Search CPSC recalls...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white54,
                            ),
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
