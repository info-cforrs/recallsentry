import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'only_advanced_filtered_recalls_page.dart';
import 'subscribe_page.dart';
import '../services/filter_state_service.dart';
import '../services/subscription_service.dart';
import '../models/saved_filter.dart';
import 'widgets/save_filter_dialog.dart';
import '../widgets/custom_back_button.dart';

class AdvancedFilterPage extends StatefulWidget {
  final bool clearFiltersOnInit;

  const AdvancedFilterPage({
    super.key,
    this.clearFiltersOnInit = false,
  });

  @override
  State<AdvancedFilterPage> createState() => _AdvancedFilterPageState();
}

class _AdvancedFilterPageState extends State<AdvancedFilterPage> {
  final int _currentIndex = 1; // Recalls tab
  final FilterStateService _filterStateService = FilterStateService();
  SubscriptionTier _subscriptionTier = SubscriptionTier.guest;

  // Brand filter state
  final List<String> _selectedBrands = [];
  final TextEditingController _brandController = TextEditingController();

  // Product Name filter state
  final List<String> _selectedProductNames = [];
  final TextEditingController _productController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
    _loadSubscriptionTier();
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
    });
  }

  // Save current filters
  Future<void> _saveFilters() async {
    await _filterStateService.saveFilterState(
      brandFilters: _selectedBrands,
      productFilters: _selectedProductNames,
    );
  }

  // Helper method to get total filter count
  int get _totalFilterCount =>
      _selectedBrands.length + _selectedProductNames.length;

  // Helper method to check if user can add more filters
  bool get _canAddMoreFilters => _totalFilterCount < 3;

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

                    const SizedBox(height: 32),

                    // Filter Summary
                    if (_selectedBrands.isNotEmpty ||
                        _selectedProductNames.isNotEmpty)
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
                              ],
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Save as Preset Button (only show if filters are selected)
                    if (_totalFilterCount > 0) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (!_canAccessSavedFilters) {
                              _showSavedFiltersUpgradeModal();
                              return;
                            }

                            final result = await showDialog<SavedFilter>(
                              context: context,
                              builder: (BuildContext context) {
                                return SaveFilterDialog(
                                  brandFilters: _selectedBrands,
                                  productFilters: _selectedProductNames,
                                );
                              },
                            );

                            // Navigate to filtered recalls page if filter was saved
                            if (result != null && mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => OnlyAdvancedFilteredRecallsPage(
                                    brandFilters: result.brandFilters,
                                    productFilters: result.productFilters,
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
                          await _saveFilters();

                          // Navigate to filtered recalls page with filter criteria
                          if (mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OnlyAdvancedFilteredRecallsPage(
                                      brandFilters: _selectedBrands,
                                      productFilters: _selectedProductNames,
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
                                  _selectedProductNames.isEmpty
                              ? 'Show All Recalls'
                              : 'Show Filtered Recalls (${_selectedBrands.length + _selectedProductNames.length} filters)',
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              // Navigate to Home tab in main navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
              break;
            case 1:
              // Navigate to Recalls tab in main navigation
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              // Navigate to Settings tab in main navigation
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
        backgroundColor: const Color(0xFF2C3E50), // Dark blue-grey background
        selectedItemColor: const Color(0xFF64B5F6), // Light blue for selected
        unselectedItemColor: Colors.grey.shade500, // Grey for unselected
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
}
