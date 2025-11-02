import 'package:flutter/material.dart';
import '../../services/saved_filter_service.dart';
import '../../services/subscription_service.dart';
import '../subscribe_page.dart';

/// Save Filter Dialog with full API integration
/// Allows users to save their current Advanced Filter settings as reusable presets

class SaveFilterDialog extends StatefulWidget {
  final List<String> brandFilters;
  final List<String> productFilters;

  const SaveFilterDialog({
    super.key,
    required this.brandFilters,
    required this.productFilters,
  });

  @override
  State<SaveFilterDialog> createState() => _SaveFilterDialogState();
}

class _SaveFilterDialogState extends State<SaveFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SavedFilterService _filterService = SavedFilterService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  SubscriptionInfo? _subscription;
  int _currentFilterCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _subscriptionService.getSubscriptionInfo(),
        _filterService.fetchSavedFilters(),
      ]);

      if (mounted) {
        setState(() {
          _subscription = results[0] as SubscriptionInfo;
          _currentFilterCount = (results[1] as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool get _canSaveFilter {
    // Always allow attempting to save - backend will enforce limits
    // This avoids frontend/backend mismatch issues
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveFilter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _filterService.createSavedFilter(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        brandFilters: widget.brandFilters,
        productFilters: widget.productFilters,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } on TierLimitException catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save filter: $e'),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A4A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A4A5C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          _error!,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64B5F6))),
          ),
        ],
      );
    }

    if (!_canSaveFilter) {
      return _buildUpgradeRequiredDialog();
    }

    final filterCount = widget.brandFilters.length + widget.productFilters.length;

    return AlertDialog(
      backgroundColor: const Color(0xFF2A4A5C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.save_outlined, color: Color(0xFF64B5F6), size: 24),
          SizedBox(width: 8),
          Text(
            'Save Filter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter count summary
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
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Saving $filterCount filter${filterCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (widget.brandFilters.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Brands: ${widget.brandFilters.join(', ')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                    if (widget.productFilters.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Products: ${widget.productFilters.join(', ')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Name field (required)
              const Text(
                'Filter Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
                  fillColor: const Color(0xFF1D3547),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name for this filter';
                  }
                  if (value.trim().length > 100) {
                    return 'Name must be 100 characters or less';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field (optional)
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a description to help you remember what this filter is for...',
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

              // Tier limit info
              if (_subscription != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3547),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark, color: Colors.white54, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_currentFilterCount + 1}/${_subscription!.getSavedFilterLimit() == 999 ? '∞' : _subscription!.getSavedFilterLimit()} saved filters',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveFilter,
          icon: _isSaving
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
            _isSaving ? 'Saving...' : 'Save Filter',
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
  }

  Widget _buildUpgradeRequiredDialog() {
    final limit = _subscription?.getSavedFilterLimit() ?? 0;
    String message = _subscription?.tier == SubscriptionTier.free || _subscription?.tier == SubscriptionTier.guest
        ? 'Saved Filters is a premium feature. Upgrade to SmartFiltering to save up to 10 filters, or RecallMatch for unlimited filters.'
        : 'You\'ve reached the maximum of $limit saved filters. Upgrade to RecallMatch for unlimited filters.';

    return AlertDialog(
      backgroundColor: const Color(0xFF2A4A5C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24),
          SizedBox(width: 8),
          Text(
            'Upgrade Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
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
  }
}
