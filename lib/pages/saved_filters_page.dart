import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main_navigation.dart';
import 'only_advanced_filtered_recalls_page.dart';
import 'advanced_filter_page.dart';
import 'subscribe_page.dart';
import 'edit_saved_filter_page.dart';
import '../models/saved_filter.dart';
import '../services/subscription_service.dart';
import '../widgets/custom_back_button.dart';
import '../providers/data_providers.dart';
import '../providers/service_providers.dart';

/// Saved SmartFilters Page - Cloud-synced filter presets
/// Premium feature with tier limits: Free (0), SmartFiltering (10), RecallMatch (unlimited)
class SavedFiltersPage extends ConsumerStatefulWidget {
  const SavedFiltersPage({super.key});

  @override
  ConsumerState<SavedFiltersPage> createState() => _SavedFiltersPageState();
}

class _SavedFiltersPageState extends ConsumerState<SavedFiltersPage> {
  final int _currentIndex = 1; // Recalls tab
  // No more service instantiations - using providers!
  // No more manual state management - providers handle this!

  int get _maxFiltersForTier {
    final subscriptionInfo = ref.watch(subscriptionInfoProvider).valueOrNull;
    if (subscriptionInfo == null) return 0;
    return subscriptionInfo.getSavedFilterLimit();
  }

  String get _tierDisplayName {
    final subscriptionInfo = ref.watch(subscriptionInfoProvider).valueOrNull;
    return subscriptionInfo?.getTierDisplayName() ?? 'Guest';
  }

  /// Apply a saved filter - marks as used and navigates to filtered recalls
  Future<void> _applyFilter(SavedFilter filter) async {
    try {
      final filterService = ref.read(savedFilterServiceProvider);

      // Update last_used_at via API
      final updatedFilter = await filterService.applySavedFilter(filter.id);

      // Navigate to filtered recalls page
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlyAdvancedFilteredRecallsPage(
              brandFilters: updatedFilter.brandFilters,
              productFilters: updatedFilter.productFilters,
            ),
          ),
        );

        // Invalidate provider to refresh filters when returning
        ref.invalidate(savedFiltersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply filter: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  /// Navigate to edit page for a filter
  Future<void> _editFilter(SavedFilter filter) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSavedFilterPage(
          filterId: filter.id,
          filterName: filter.name,
          filterDescription: filter.description,
          brandFilters: filter.brandFilters,
          productFilters: filter.productFilters,
        ),
      ),
    );

    // Reload if filter was updated or deleted
    if (result == true && mounted) {
      ref.invalidate(savedFiltersProvider);
    }
  }

  /// Delete a saved filter
  Future<void> _deleteFilter(SavedFilter filter) async {
    try {
      final filterService = ref.read(savedFilterServiceProvider);
      await filterService.deleteSavedFilter(filter.id);

      if (mounted) {
        // Invalidate provider to refresh filter list
        ref.invalidate(savedFiltersProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted: ${filter.name}'),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete filter: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  /// Navigate to Advanced Filters to create new filter
  void _createNewFilter() {
    final filtersAsync = ref.read(savedFiltersProvider);
    final filters = filtersAsync.valueOrNull ?? [];

    if (filters.length >= _maxFiltersForTier) {
      _showUpgradeDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdvancedFilterPage(
          clearFiltersOnInit: true,
        ),
      ),
    ).then((_) {
      // Invalidate provider when returning from Advanced Filters
      ref.invalidate(savedFiltersProvider);
    });
  }

  void _showUpgradeDialog() {
    final subscriptionInfo = ref.read(subscriptionInfoProvider).valueOrNull;
    String message = subscriptionInfo?.tier == SubscriptionTier.free
        ? 'Saved SmartFilters is a premium feature. Upgrade to SmartFiltering to save up to 10 filters, or RecallMatch for unlimited filters.'
        : 'You\'ve reached the maximum of $_maxFiltersForTier saved filters for $_tierDisplayName. Upgrade to RecallMatch for unlimited filters.';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers - automatic loading and rebuilds
    final filtersAsync = ref.watch(savedFiltersProvider);
    final subscriptionAsync = ref.watch(subscriptionInfoProvider);

    return Scaffold(
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
                  const Expanded(
                    child: Text(
                      'Saved SmartFilters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Atlanta',
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tier info banner
            subscriptionAsync.when(
              data: (subscription) {
                final filters = filtersAsync.valueOrNull ?? [];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A4A5C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subscription.tier == SubscriptionTier.free
                              ? 'Saved SmartFilters is a premium feature. Upgrade to save filters.'
                              : '$_tierDisplayName: ${filters.length}/${_maxFiltersForTier == 999 ? '∞' : _maxFiltersForTier} saved filters',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Content area
            Expanded(
              child: filtersAsync.when(
                data: (filters) {
                  if (filters.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filters.length,
                    itemBuilder: (context, index) {
                      final filter = filters[index];
                      return _buildFilterCard(filter);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
                ),
                error: (error, _) => _buildErrorState(error.toString()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: filtersAsync.when(
        data: (_) => FloatingActionButton.extended(
          onPressed: _createNewFilter,
          backgroundColor: const Color(0xFF64B5F6),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'New SmartFilter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        loading: () => null,
        error: (_, __) => null,
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
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Failed to Load Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(savedFiltersProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF2A4A5C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off,
                size: 60,
                color: Color(0xFF64B5F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Saved SmartFilters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create reusable filter presets to quickly find the recalls you care about.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewFilter,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create Your First Filter',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(SavedFilter filter) {
    return Dismissible(
      key: Key('filter-${filter.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
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
                'Are you sure you want to delete "${filter.name}"? This action cannot be undone.',
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
      },
      onDismissed: (direction) => _deleteFilter(filter),
      child: GestureDetector(
        onTap: () => _applyFilter(filter),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A4A5C),
            borderRadius: BorderRadius.circular(12),
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
                    Expanded(
                      child: Text(
                        filter.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editFilter(filter),
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF64B5F6), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (filter.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    filter.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.filter_alt, color: Color(0xFF64B5F6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${filter.filterCount} filter${filter.filterCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    if (filter.lastUsedAt != null) ...[
                      const Icon(Icons.access_time, color: Colors.white54, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        filter.getLastUsedText(),
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ] else ...[
                      const Icon(Icons.fiber_new, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Never used',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...filter.brandFilters.take(3).map((brand) => _buildFilterChip(brand, Icons.business)),
                    ...filter.productFilters.take(3).map((product) => _buildFilterChip(product, Icons.inventory)),
                    if (filter.filterCount > 6)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3547),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${filter.filterCount - 6} more',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _applyFilter(filter),
                    icon: const Icon(Icons.search, size: 18, color: Colors.white),
                    label: const Text(
                      'See Recalls',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF64B5F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3547),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF64B5F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64B5F6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
