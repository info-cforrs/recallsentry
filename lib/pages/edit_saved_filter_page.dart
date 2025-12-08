import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../services/saved_filter_service.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

/// Edit Saved Filter Page with full API integration
/// Allows users to edit existing saved filters with real-time sync

class EditSavedFilterPage extends StatefulWidget {
  final int filterId;
  final String filterName;
  final String filterDescription;
  final List<String> brandFilters;
  final List<String> productFilters;

  const EditSavedFilterPage({
    super.key,
    required this.filterId,
    required this.filterName,
    required this.filterDescription,
    required this.brandFilters,
    required this.productFilters,
  });

  @override
  State<EditSavedFilterPage> createState() => _EditSavedFilterPageState();
}

class _EditSavedFilterPageState extends State<EditSavedFilterPage> with HideOnScrollMixin {
  final int _currentIndex = 1; // Recalls tab
  final _formKey = GlobalKey<FormState>();
  final SavedFilterService _filterService = SavedFilterService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _productController = TextEditingController();

  late List<String> _selectedBrands;
  late List<String> _selectedProductNames;

  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _nameController = TextEditingController(text: widget.filterName);
    _descriptionController = TextEditingController(text: widget.filterDescription);
    _selectedBrands = List.from(widget.brandFilters);
    _selectedProductNames = List.from(widget.productFilters);

    // Listen for changes
    _nameController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _productController.dispose();
    disposeHideOnScroll();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  int get _totalFilterCount => _selectedBrands.length + _selectedProductNames.length;

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A4A5C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Discard Changes?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'You have unsaved changes. Are you sure you want to discard them?',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_totalFilterCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one filter'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        await _filterService.updateSavedFilter(
          id: widget.filterId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          brandFilters: _selectedBrands,
          productFilters: _selectedProductNames,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved changes to: ${_nameController.text}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );

          setState(() {
            _hasChanges = false;
            _isSaving = false;
          });

          // Return true to indicate changes were saved
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save changes: $e'),
              backgroundColor: const Color(0xFFE53935),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _deleteFilter() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Delete Filter?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${widget.filterName}"? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await _filterService.deleteSavedFilter(widget.filterId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted: ${widget.filterName}'),
              backgroundColor: const Color(0xFFE53935),
            ),
          );

          // Return true to indicate filter was deleted
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete filter: $e'),
              backgroundColor: const Color(0xFFE53935),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1D3547),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                  const CustomBackButton(),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final shouldPop = await _onWillPop();
                        if (shouldPop && mounted) {
                          navigator.pop();
                        }
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Edit Filter',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Atlanta',
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Delete button
                    IconButton(
                      onPressed: _deleteFilter,
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 24),
                      tooltip: 'Delete Filter',
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  controller: hideOnScrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Name
                        const Text(
                          'Filter Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g., Pet Food Recalls',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2A4A5C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            if (value.trim().length > 100) {
                              return 'Name must be 100 characters or less';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Description
                        const Text(
                          'Description (Optional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add a description...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2A4A5C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Divider(color: Colors.white24),

                        const SizedBox(height: 24),

                        // Brand Filter Section
                        _buildAddFilterSection(
                          title: 'Filter by Brand',
                          icon: Icons.business,
                          controller: _brandController,
                          hintText: 'Enter brand name...',
                          selectedItems: _selectedBrands,
                          onAdd: () {
                            if (_brandController.text.trim().isNotEmpty) {
                              setState(() {
                                if (!_selectedBrands.contains(_brandController.text.trim())) {
                                  _selectedBrands.add(_brandController.text.trim());
                                  _markChanged();
                                }
                                _brandController.clear();
                              });
                            }
                          },
                          onRemove: (brand) {
                            setState(() {
                              _selectedBrands.remove(brand);
                              _markChanged();
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // Product Name Filter Section
                        _buildAddFilterSection(
                          title: 'Filter by Product Name',
                          icon: Icons.inventory,
                          controller: _productController,
                          hintText: 'Enter product name...',
                          selectedItems: _selectedProductNames,
                          onAdd: () {
                            if (_productController.text.trim().isNotEmpty) {
                              setState(() {
                                if (!_selectedProductNames.contains(_productController.text.trim())) {
                                  _selectedProductNames.add(_productController.text.trim());
                                  _markChanged();
                                }
                                _productController.clear();
                              });
                            }
                          },
                          onRemove: (productName) {
                            setState(() {
                              _selectedProductNames.remove(productName);
                              _markChanged();
                            });
                          },
                        ),

                        const SizedBox(height: 32),

                        // Filter Summary
                        if (_selectedBrands.isNotEmpty || _selectedProductNames.isNotEmpty)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A4A5C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.summarize, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Filter Summary',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (_selectedBrands.isNotEmpty) ...[
                                    Text(
                                      'Brands (${_selectedBrands.length}): ${_selectedBrands.join(', ')}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (_selectedProductNames.isNotEmpty) ...[
                                    Text(
                                      'Products (${_selectedProductNames.length}): ${_selectedProductNames.join(', ')}',
                                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: (_hasChanges && !_isSaving) ? _saveChanges : null,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save, size: 20, color: Colors.white),
                            label: Text(
                              _isSaving
                                  ? 'Saving...'
                                  : (_hasChanges ? 'Save Changes' : 'No Changes'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_hasChanges || _isSaving)
                                  ? const Color(0xFF64B5F6)
                                  : const Color(0xFF2A4A5C),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: (_hasChanges || _isSaving) ? 2 : 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
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
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            if (selectedItems.isNotEmpty)
              Column(
                children: selectedItems.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
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
