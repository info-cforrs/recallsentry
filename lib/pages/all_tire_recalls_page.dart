import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/recall_data_service.dart';
import '../services/subscription_service.dart';
import '../services/article_service.dart';
import '../models/recall_data.dart';
import '../models/article.dart';
import '../widgets/small_nhtsa_recall_card.dart';
import '../widgets/article_card.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import 'subscribe_page.dart';

class AllTireRecallsPage extends StatefulWidget {
  const AllTireRecallsPage({super.key});

  @override
  State<AllTireRecallsPage> createState() => _AllTireRecallsPageState();
}

class _AllTireRecallsPageState extends State<AllTireRecallsPage> with HideOnScrollMixin {
  final RecallDataService _recallService = RecallDataService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ArticleService _articleService = ArticleService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<RecallData> _tireRecalls = [];
  List<RecallData> _filteredRecalls = [];
  List<Article> _nhtsaArticles = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final int _currentIndex = 1; // Recalls tab
  String _searchQuery = '';
  String _sortOption = 'date'; // 'date', 'brand_az', 'brand_za'
  String _selectedRiskLevel = 'all';
  List<String> _availableRiskLevels = [];
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
    _loadTireRecalls();
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

  Future<void> _loadTireRecalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 0;
      _hasMoreRecalls = true;
    });

    try {
      // Get subscription tier for date filtering
      final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();
      final tier = subscriptionInfo.tier;
      final now = DateTime.now();
      final DateTime cutoff;
      if (tier == SubscriptionTier.free) {
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        cutoff = DateTime(now.year, 1, 1);
      }

      // Load first page of recalls and articles in parallel
      final results = await Future.wait([
        _recallService.getNhtsaTireRecalls(limit: _pageSize, offset: 0),
        _articleService.getNhtsaArticles(),
      ]);

      final firstPageRecalls = results[0] as List<RecallData>;
      final articles = results[1] as List<Article>;

      final recentRecalls = firstPageRecalls.where((recall) {
        return recall.dateIssued.isAfter(cutoff);
      }).toList();

      recentRecalls.sort((a, b) => b.dateIssued.compareTo(a.dateIssued));
      _updateAvailableFilterOptions(recentRecalls);

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _tireRecalls = recentRecalls;
          _nhtsaArticles = articles;
          _applyFiltersAndSort();
          _hasMoreRecalls = recentRecalls.length == _pageSize;
        } else {
          _tireRecalls = [];
          _nhtsaArticles = articles;
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
        _tireRecalls = [];
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
      // Get subscription tier for date filtering
      final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();
      final tier = subscriptionInfo.tier;
      final now = DateTime.now();
      final DateTime cutoff;
      if (tier == SubscriptionTier.free) {
        cutoff = now.subtract(const Duration(days: 30));
      } else {
        cutoff = DateTime(now.year, 1, 1);
      }

      final offset = (_currentPage + 1) * _pageSize;

      final nextPageRecalls = await _recallService.getNhtsaTireRecalls(
        limit: _pageSize,
        offset: offset,
      );

      final recentRecalls = nextPageRecalls.where((recall) {
        return recall.dateIssued.isAfter(cutoff);
      }).toList();

      if (!mounted) return;

      setState(() {
        if (recentRecalls.isNotEmpty) {
          _tireRecalls.addAll(recentRecalls);
          _currentPage++;
          _updateAvailableFilterOptions(_tireRecalls);
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

    for (var recall in recalls) {
      if (recall.riskLevel.trim().isNotEmpty) {
        riskLevels.add(recall.riskLevel.toUpperCase().trim());
      }
    }

    _availableRiskLevels = riskLevels.toList()..sort();

    if (_selectedRiskLevel != 'all' &&
        !_availableRiskLevels.contains(_selectedRiskLevel)) {
      _selectedRiskLevel = 'all';
    }
  }

  void _applyFiltersAndSort() {
    List<RecallData> filtered = List.from(_tireRecalls);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recall) {
        return recall.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recall.brandName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recall.nhtsaModelNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recall.nhtsaComponent.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recall.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply risk level filter
    if (_selectedRiskLevel != 'all') {
      filtered = filtered.where((recall) {
        return recall.riskLevel.toUpperCase().trim() ==
            _selectedRiskLevel.toUpperCase().trim();
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case 'brand_az':
        filtered.sort((a, b) => a.brandName.toLowerCase().compareTo(b.brandName.toLowerCase()));
        break;
      case 'brand_za':
        filtered.sort((a, b) => b.brandName.toLowerCase().compareTo(a.brandName.toLowerCase()));
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
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          title: const Text('Sort Options', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Date (Newest First)', style: TextStyle(color: Colors.white)),
                value: 'date',
                groupValue: _sortOption,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  _applyFiltersAndSort();
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Brand (A-Z)', style: TextStyle(color: Colors.white)),
                value: 'brand_az',
                groupValue: _sortOption,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  _applyFiltersAndSort();
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<String>(
                title: const Text('Brand (Z-A)', style: TextStyle(color: Colors.white)),
                value: 'brand_za',
                groupValue: _sortOption,
                activeColor: const Color(0xFF64B5F6),
                onChanged: (value) {
                  setState(() => _sortOption = value!);
                  _applyFiltersAndSort();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    String tempRiskLevel = _selectedRiskLevel;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> riskOptions = ['all', ..._availableRiskLevels];

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
                    const Text(
                      'Risk Level:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    ...riskOptions.map((level) {
                      return RadioListTile<String>(
                        title: Text(
                          level == 'all' ? 'All Risk Levels' : level,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: level,
                        groupValue: tempRiskLevel,
                        activeColor: const Color(0xFF64B5F6),
                        onChanged: (value) {
                          setDialogState(() {
                            tempRiskLevel = value!;
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRiskLevel = tempRiskLevel;
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

  // Calculate total number of items (recalls + interspersed articles + upgrade banner)
  int _getTotalItemCount() {
    if (_filteredRecalls.isEmpty) return 0;

    // Number of articles to show (one after every 3rd recall)
    final articlesCount = _nhtsaArticles.isEmpty
      ? 0
      : (_filteredRecalls.length / 3).floor().clamp(0, _nhtsaArticles.length);

    // Recalls + articles + upgrade banner (1 item)
    return _filteredRecalls.length + articlesCount + 1;
  }

  // Determine if item at index should be an article
  // Articles appear at indices 3, 7, 11, 15... (every 4th position after 3 recalls)
  bool _isArticleAtIndex(int index) {
    if (_nhtsaArticles.isEmpty) return false;

    // Pattern: article at index 3, 7, 11, 15... => (n*4 + 3) where n = 0,1,2...
    if ((index + 1) % 4 != 0) return false;

    // Calculate which article this would be (0-indexed)
    final articleIndex = (index + 1) ~/ 4 - 1;

    // Make sure we have enough articles to show
    return articleIndex < _nhtsaArticles.length;
  }

  // Get recall index from item index (accounting for interspersed articles)
  int _getRecallIndex(int itemIndex) {
    final articlesBefore = ((itemIndex + 1) ~/ 4);
    return itemIndex - articlesBefore;
  }

  // Get article index from item index
  int _getArticleIndex(int itemIndex) {
    return (itemIndex + 1) ~/ 4 - 1;
  }

  Widget _buildListItem(int index) {
    final totalItems = _getTotalItemCount();

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
                const Icon(Icons.lock_outline, size: 48, color: Color(0xFFFFD700)),
                const SizedBox(height: 16),
                const Text(
                  '30-Day Recall Limit Reached',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upgrade to SmartFiltering or RecallMatch Plans to access older recalls.',
                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SubscribePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Upgrade Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Check if this index should show an article
    if (_isArticleAtIndex(index)) {
      final articleIndex = _getArticleIndex(index);
      if (articleIndex < _nhtsaArticles.length) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ArticleCard(article: _nhtsaArticles[articleIndex]),
        );
      }
    }

    // Otherwise show a recall
    final recallIndex = _getRecallIndex(index);
    if (recallIndex < _filteredRecalls.length) {
      final recall = _filteredRecalls[recallIndex];
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SmallNhtsaRecallCard(recall: recall),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _errorMessage.isNotEmpty ? Icons.error_outline : Icons.circle,
            size: 80,
            color: _errorMessage.isNotEmpty ? Colors.red : Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage.isNotEmpty ? 'Error Loading Recalls' : 'No Tire Recalls Found',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'No tire recalls found in the last 30 days.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTireRecalls,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6)),
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
          _tireRecalls = [];
        });
        await _loadTireRecalls();
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
              itemBuilder: (context, index) => _buildListItem(index),
            ),
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Color(0xFF64B5F6), strokeWidth: 2.5),
                    ),
                    SizedBox(width: 12),
                    Text('Loading more recalls...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            if (!_hasMoreRecalls && _tireRecalls.isNotEmpty && !_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('All recalls loaded', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.circle, color: Colors.black87, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Tire Recalls',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search tire recalls...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                    setState(() => _searchQuery = value);
                    _applyFiltersAndSort();
                  },
                ),
              ),
              const SizedBox(height: 12),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF64B5F6)))
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
                  MaterialPageRoute(builder: (context) => const MainNavigation(initialIndex: 0)),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavigation(initialIndex: 1)),
                  (route) => false,
                );
                break;
              case 2:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavigation(initialIndex: 2)),
                  (route) => false,
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
