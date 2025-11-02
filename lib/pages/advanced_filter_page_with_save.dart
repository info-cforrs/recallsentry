import 'package:flutter/material.dart';
import 'main_navigation.dart';
import 'only_advanced_filtered_recalls_page.dart';
import 'subscribe_page.dart';
import 'widgets/save_filter_dialog.dart';
import '../services/filter_state_service.dart';

/// MOCKUP: Advanced Filter Page with Save Filter Button
/// This is a modified version of the existing Advanced Filter page
/// showing how the "Save Filter" button would be integrated
///
/// Key changes from original:
/// 1. Added "Save Filter" button next to "Show Filtered Recalls" button
/// 2. Opens SaveFilterDialog when clicked
/// 3. Validates tier limits before allowing save
/// 4. Shows success confirmation after saving

class AdvancedFilterPageWithSave extends StatefulWidget {
  const AdvancedFilterPageWithSave({super.key});

  @override
  State<AdvancedFilterPageWithSave> createState() => _AdvancedFilterPageWithSaveState();
}

class _AdvancedFilterPageWithSaveState extends State<AdvancedFilterPageWithSave> {
  final int _currentIndex = 1; // Recalls tab
  final FilterStateService _filterStateService = FilterStateService();

  // Brand filter state
  final List<String> _selectedBrands = [];
  final TextEditingController _brandController = TextEditingController();

  // Product Name filter state
  final List<String> _selectedProductNames = [];
  final TextEditingController _productController = TextEditingController();

  // MOCKUP: Simulate user tier and saved filter count
  final String _currentTier = 'smart_filtering'; // 'free', 'smart_filtering', 'recall_match'
  int _currentSavedFilterCount = 3;

  @override
  void initState() {
    super.initState();
    _loadSavedFilters();
  }

  // Load previously saved filters
  Future<void> _loadSavedFilters() async {
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

  // NEW: Method to save filter as preset
  void _saveFilterAsPreset() async {
    if (_totalFilterCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one filter before saving'),
          backgroundColor: Color(0xFFE53935),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show save filter dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return SaveFilterDialog(
          brandFilters: _selectedBrands,
          productFilters: _selectedProductNames,
          currentTier: _currentTier,
          currentFilterCount: _currentSavedFilterCount,
        );
      },
    );

    // If user saved the filter
    if (result != null && mounted) {
      // In real implementation, this would call API to save filter
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Saved filter: ${result['name']}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Navigate to Saved Filters page
            },
          ),
        ),
      );

      // Update saved filter count (in real app, this would come from API)
      setState(() {
        _currentSavedFilterCount++;
      });
    }
  }

  // Method to show upgrade dialog
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

                    // NEW: Save Filter Button
                    if (_selectedBrands.isNotEmpty || _selectedProductNames.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _saveFilterAsPreset,
                          icon: const Icon(
                            Icons.bookmark_add_outlined,
                            size: 20,
                            color: Color(0xFF64B5F6),
                          ),
                          label: const Text(
                            'Save as Preset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64B5F6),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF64B5F6), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    if (_selectedBrands.isNotEmpty || _selectedProductNames.isNotEmpty)
                      const SizedBox(height: 12),

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
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Recalls'),
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
