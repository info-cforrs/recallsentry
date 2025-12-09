import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'only_advanced_filtered_recalls_page.dart';
import 'subscribe_page.dart';
import '../services/filter_state_service.dart';
import '../services/subscription_service.dart';
import '../services/consent_service.dart';
import '../models/saved_filter.dart';
import '../models/allergy_preferences.dart';
import 'widgets/save_filter_dialog.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

class AdvancedFilterPage extends StatefulWidget {
  final bool clearFiltersOnInit;

  const AdvancedFilterPage({
    super.key,
    this.clearFiltersOnInit = false,
  });

  @override
  State<AdvancedFilterPage> createState() => _AdvancedFilterPageState();
}

class _AdvancedFilterPageState extends State<AdvancedFilterPage> with HideOnScrollMixin {
  final int _currentIndex = 1; // Recalls tab
  final FilterStateService _filterStateService = FilterStateService();
  SubscriptionTier _subscriptionTier = SubscriptionTier.free;

  // Brand filter state
  final List<String> _selectedBrands = [];
  final TextEditingController _brandController = TextEditingController();

  // Product Name filter state
  final List<String> _selectedProductNames = [];
  final TextEditingController _productController = TextEditingController();

  // State filter state
  final List<String> _selectedStates = [];

  // Allergy filter state
  final List<String> _selectedAllergens = [];

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _loadSavedFilters();
    _loadSubscriptionTier();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _productController.dispose();
    disposeHideOnScroll();
    super.dispose();
  }

  Future<void> _loadSubscriptionTier() async {
    final info = await SubscriptionService().getSubscriptionInfo();
    if (mounted) {
      setState(() {
        _subscriptionTier = info.tier;
      });
    }
  }

  bool get _canAccessSavedFilters {
    return _subscriptionTier == SubscriptionTier.smartFiltering ||
        _subscriptionTier == SubscriptionTier.recallMatch;
  }

  // Load previously saved filters
  Future<void> _loadSavedFilters() async {
    // If clearFiltersOnInit is true, clear saved state and start fresh
    if (widget.clearFiltersOnInit) {
      await _filterStateService.clearAllFilters();
      setState(() {
        _selectedBrands.clear();
        _selectedProductNames.clear();
        _selectedStates.clear();
      });
      return;
    }

    // Otherwise, load previously saved filters
    final filterState = await _filterStateService.loadFilterState();
    setState(() {
      _selectedBrands.clear();
      _selectedBrands.addAll(filterState.brandFilters);
      _selectedProductNames.clear();
      _selectedProductNames.addAll(filterState.productFilters);
      _selectedStates.clear();
      _selectedStates.addAll(filterState.stateFilters);
      _selectedAllergens.clear();
      _selectedAllergens.addAll(filterState.allergenFilters);
    });
  }

  // Save current filters
  Future<void> _saveFilters() async {
    await _filterStateService.saveFilterState(
      brandFilters: _selectedBrands,
      productFilters: _selectedProductNames,
      stateFilters: _selectedStates,
      allergenFilters: _selectedAllergens,
    );
  }

  // Helper method to get total filter count (brands + products only, states don't count toward 3-filter limit)
  int get _totalFilterCount =>
      _selectedBrands.length + _selectedProductNames.length;

  // Helper method to check if any filters are selected (for showing save button)
  bool get _hasAnyFiltersSelected =>
      _selectedBrands.isNotEmpty ||
      _selectedProductNames.isNotEmpty ||
      _selectedStates.isNotEmpty ||
      _selectedAllergens.isNotEmpty;

  // Helper method to check if user can add more filters
  bool get _canAddMoreFilters => _totalFilterCount < 3;

  // Get state filter limit based on tier
  // All tiers can access state filters: FREE: 1 state, SMART: 3 states, RECALL: unlimited
  int get _stateFilterLimit {
    switch (_subscriptionTier) {
      case SubscriptionTier.recallMatch:
        return 999; // Unlimited
      case SubscriptionTier.smartFiltering:
        return 3;
      case SubscriptionTier.free:
        return 1;
    }
  }

  // Method to show upgrade dialog for 3-filter limit
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Upgrade Your Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'You\'ve reached the maximum of 3 filters for the free plan. Upgrade to a paid subscription for unlimited smart filtering.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Subscribe page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscribePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Subscribe to SmartFiltering',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to show upgrade modal for Saved Filters feature access
  void _showSavedFiltersUpgradeModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Subscribe for Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Upgrade to Smart Filtering to access Saved Filters and other premium features.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Only \$1.99/month',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscribePage(),
                  ),
                );
              },
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
              child: const Text(
                'Click to Upgrade',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                  // Advanced Filters Text
                  const Expanded(
                    child: Text(
                      'Advanced Filters',
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
                controller: hideOnScrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Brand Filter Section
                    _buildAddFilterSection(
                      title: 'Filter by Brand',
                      icon: Icons.business,
                      controller: _brandController,
                      hintText:
                          'Enter brand name... (e.g. "Endico", "Quality", "Bianco")',
                      selectedItems: _selectedBrands,
                      onAdd: () {
                        if (_brandController.text.trim().isNotEmpty) {
                          if (!_canAddMoreFilters) {
                            _showUpgradeDialog();
                            return;
                          }
                          setState(() {
                            if (!_selectedBrands.contains(
                              _brandController.text.trim(),
                            )) {
                              _selectedBrands.add(_brandController.text.trim());
                            }
                            _brandController.clear();
                          });
                        }
                      },
                      onRemove: (brand) {
                        setState(() {
                          _selectedBrands.remove(brand);
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Product Name Filter Section
                    _buildAddFilterSection(
                      title: 'Filter by Product Name',
                      icon: Icons.inventory,
                      controller: _productController,
                      hintText:
                          'Enter product name... (e.g. "catfish", "vegetables", "beef")',
                      selectedItems: _selectedProductNames,
                      onAdd: () {
                        if (_productController.text.trim().isNotEmpty) {
                          if (!_canAddMoreFilters) {
                            _showUpgradeDialog();
                            return;
                          }
                          setState(() {
                            if (!_selectedProductNames.contains(
                              _productController.text.trim(),
                            )) {
                              _selectedProductNames.add(
                                _productController.text.trim(),
                              );
                            }
                            _productController.clear();
                          });
                        }
                      },
                      onRemove: (productName) {
                        setState(() {
                          _selectedProductNames.remove(productName);
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // State Filter Section (Premium Feature)
                    _buildStateFilterSection(),

                    const SizedBox(height: 24),

                    // Allergy Filter Section
                    _buildAllergyFilterSection(),

                    const SizedBox(height: 32),

                    // Filter Summary
                    if (_selectedBrands.isNotEmpty ||
                        _selectedProductNames.isNotEmpty ||
                        _selectedStates.isNotEmpty ||
                        _selectedAllergens.isNotEmpty)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A4A5C),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.summarize,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Filter Summary',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedBrands.clear();
                                        _selectedProductNames.clear();
                                        _selectedStates.clear();
                                        _selectedAllergens.clear();
                                      });
                                    },
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(
                                        color: Color(0xFF64B5F6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_selectedBrands.isNotEmpty) ...[
                                Text(
                                  'Brands (${_selectedBrands.length}): ${_selectedBrands.join(', ')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (_selectedProductNames.isNotEmpty) ...[
                                Text(
                                  'Products (${_selectedProductNames.length}): ${_selectedProductNames.join(', ')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (_selectedStates.isNotEmpty) ...[
                                Text(
                                  'States (${_selectedStates.length}): ${_selectedStates.join(', ')}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (_selectedAllergens.isNotEmpty) ...[
                                Text(
                                  _selectedAllergens.contains('all')
                                      ? 'Allergens: All 9 major allergens'
                                      : 'Allergens (${_selectedAllergens.length}): ${_selectedAllergens.map((a) => AllergyPreferences.getAllergenDisplayName(a)).join(', ')}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Save as Preset Button (only show if any filters are selected)
                    if (_hasAnyFiltersSelected) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (!_canAccessSavedFilters) {
                              _showSavedFiltersUpgradeModal();
                              return;
                            }

                            final navigator = Navigator.of(context);
                            final result = await showDialog<SavedFilter>(
                              context: context,
                              builder: (BuildContext context) {
                                return SaveFilterDialog(
                                  brandFilters: _selectedBrands,
                                  productFilters: _selectedProductNames,
                                  stateFilters: _selectedStates,
                                  allergenFilters: _selectedAllergens,
                                );
                              },
                            );

                            // Navigate to filtered recalls page if filter was saved
                            if (result != null && mounted) {
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => OnlyAdvancedFilteredRecallsPage(
                                    brandFilters: result.brandFilters,
                                    productFilters: result.productFilters,
                                    stateFilters: result.stateFilters,
                                    allergenFilters: result.allergenFilters,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.bookmark_add,
                            size: 20,
                            color: _canAccessSavedFilters ? const Color(0xFF64B5F6) : Colors.black,
                          ),
                          label: Text(
                            'Save as SmartFilter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _canAccessSavedFilters ? const Color(0xFF64B5F6) : Colors.black,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _canAccessSavedFilters ? null : const Color(0xFFD1D1D1),
                            side: BorderSide(
                              color: _canAccessSavedFilters ? const Color(0xFF64B5F6) : Colors.grey,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Show Filtered Recalls Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Save current filter state
                          final navigator = Navigator.of(context);
                          await _saveFilters();

                          // Navigate to filtered recalls page with filter criteria
                          if (mounted) {
                            navigator.push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OnlyAdvancedFilteredRecallsPage(
                                      brandFilters: _selectedBrands,
                                      productFilters: _selectedProductNames,
                                      stateFilters: _selectedStates,
                                      allergenFilters: _selectedAllergens,
                                    ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.search,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: Text(
                          _selectedBrands.isEmpty &&
                                  _selectedProductNames.isEmpty &&
                                  _selectedStates.isEmpty &&
                                  _selectedAllergens.isEmpty
                              ? 'Show All Recalls'
                              : 'Show Filtered Recalls (${_selectedBrands.length + _selectedProductNames.length + _selectedStates.length + (_selectedAllergens.contains('all') ? 9 : _selectedAllergens.length)} filters)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
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

  Widget _buildAddFilterSection({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required String hintText,
    required List<String> selectedItems,
    required VoidCallback onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Input Row with Text Field and Add Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1D3547),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Selected Items Count
            if (selectedItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${selectedItems.length} filter${selectedItems.length == 1 ? '' : 's'} added',
                  style: const TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Selected Items List with Delete Option
            if (selectedItems.isNotEmpty)
              Column(
                children: selectedItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3547),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onRemove(item),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Build State Filter Section with tier-based access
  Widget _buildStateFilterSection() {
    final int stateLimit = _stateFilterLimit;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filter by State',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description/Limit Text
            Text(
              stateLimit == 999
                  ? 'Select states (unlimited)'
                  : 'Select up to $stateLimit state${stateLimit == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            // State FilterChips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getUsStates().map((state) {
                final isSelected = _selectedStates.contains(state);
                final canSelect = isSelected || _selectedStates.length < stateLimit;

                return FilterChip(
                  label: Text(state),
                  selected: isSelected,
                  onSelected: canSelect
                      ? (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStates.add(state);
                            } else {
                              _selectedStates.remove(state);
                            }
                          });
                        }
                      : null, // Disabled when limit reached
                  selectedColor: const Color(0xFF64B5F6),
                  backgroundColor: const Color(0xFF1D3547),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                  disabledColor: Colors.grey.withValues(alpha: 0.3),
                );
              }).toList(),
            ),

            // Limit reached message - show upgrade prompt when limit is reached
            if (_selectedStates.length >= stateLimit && stateLimit != 999) ...[
              const SizedBox(height: 12),
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
                        _subscriptionTier == SubscriptionTier.free
                            ? 'Upgrade to SmartFiltering for 3 states or RecallMatch for unlimited'
                            : 'Upgrade to RecallMatch for unlimited state filters',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Selected states count
            if (_selectedStates.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  '${_selectedStates.length} state${_selectedStates.length == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Get list of US states (abbreviations)
  List<String> _getUsStates() {
    return [
      'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
      'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
      'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
      'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
      'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'
    ];
  }

  // Build Allergy Filter Section
  Widget _buildAllergyFilterSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filter by Allergy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FDA Big 9',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            const Text(
              'Get notified about recalls involving common food allergens',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            // Select Button and Selected Count
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAllergySelectionModal,
                  icon: const Icon(Icons.checklist, size: 18, color: Colors.white),
                  label: const Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64B5F6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_selectedAllergens.isNotEmpty)
                  Expanded(
                    child: Text(
                      _selectedAllergens.contains('all')
                          ? 'All allergens selected'
                          : '${_selectedAllergens.length} allergen${_selectedAllergens.length == 1 ? '' : 's'} selected',
                      style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // Selected Allergens Display
            if (_selectedAllergens.isNotEmpty && !_selectedAllergens.contains('all')) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedAllergens.map((allergenKey) {
                  final displayName = AllergyPreferences.getAllergenDisplayName(allergenKey);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getAllergenEmoji(allergenKey),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAllergens.remove(allergenKey);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Get emoji for allergen
  String _getAllergenEmoji(String allergenKey) {
    const emojis = {
      'peanuts': '🥜',
      'tree_nuts': '🌰',
      'milk_dairy': '🥛',
      'eggs': '🥚',
      'wheat_gluten': '🌾',
      'soy': '🫘',
      'fish': '🐟',
      'shellfish': '🦐',
      'sesame': '🌱',
    };
    return emojis[allergenKey] ?? '⚠️';
  }

  // Show allergy selection modal
  void _showAllergySelectionModal() async {
    // Check for health data consent first
    final hasConsent = await ConsentService().isHealthDataConsented();

    if (!hasConsent) {
      // Show consent dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Health Data Consent Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allergy preferences are considered sensitive health-related data.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text(
                'By enabling this feature, you consent to RecallSentry collecting and processing your allergy information to provide personalized allergen recall alerts.',
              ),
              SizedBox(height: 12),
              Text(
                'You can withdraw this consent at any time in Settings > Privacy & Data.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('I Consent'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await ConsentService().updatePreference(healthDataConsentGiven: true);
      } else {
        return; // User declined consent, don't show the modal
      }
    }

    if (!mounted) return;

    // Create a local copy of selected allergens for the modal
    List<String> tempSelected = List.from(_selectedAllergens);
    bool allSelected = tempSelected.contains('all');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D3547),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Select Allergens',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelected.clear();
                                allSelected = false;
                              });
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Color(0xFF64B5F6)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(color: Colors.white24, height: 1),

                    // Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // All Allergens Toggle
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: allSelected
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : const Color(0xFF2A4A5C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: allSelected ? Colors.orange : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: const Text(
                                'ALL Allergens',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Alert for all 9 major allergens',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              secondary: const Text('⚠️', style: TextStyle(fontSize: 24)),
                              value: allSelected,
                              activeColor: Colors.orange,
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                setModalState(() {
                                  allSelected = value ?? false;
                                  if (allSelected) {
                                    tempSelected.clear();
                                    tempSelected.add('all');
                                  } else {
                                    tempSelected.remove('all');
                                  }
                                });
                              },
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Or select specific allergens:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          // Individual Allergen Checkboxes
                          ...AllergyPreferences.getAllergenCategories().map((category) {
                            final isSelected = tempSelected.contains(category.key);
                            final isDisabled = allSelected;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected && !isDisabled
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : const Color(0xFF2A4A5C),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CheckboxListTile(
                                title: Row(
                                  children: [
                                    Text(
                                      _getAllergenEmoji(category.key),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category.displayName,
                                      style: TextStyle(
                                        color: isDisabled ? Colors.white38 : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(left: 26),
                                  child: Text(
                                    category.description,
                                    style: TextStyle(
                                      color: isDisabled ? Colors.white24 : Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                value: isDisabled ? true : isSelected,
                                activeColor: Colors.orange,
                                checkColor: Colors.white,
                                onChanged: isDisabled
                                    ? null
                                    : (bool? value) {
                                        setModalState(() {
                                          if (value == true) {
                                            if (!tempSelected.contains(category.key)) {
                                              tempSelected.add(category.key);
                                            }
                                          } else {
                                            tempSelected.remove(category.key);
                                          }
                                        });
                                      },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Bottom Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A4A5C),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAllergens.clear();
                                  _selectedAllergens.addAll(tempSelected);
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF64B5F6),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Apply (${tempSelected.isEmpty ? 0 : tempSelected.contains('all') ? 9 : tempSelected.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
