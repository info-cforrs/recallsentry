import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/usage_service.dart';
import '../widgets/usage_widget.dart';
import 'main_navigation.dart';
import '../providers/data_providers.dart';
import '../services/subscription_service.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';

/// App Usage Page - Shows real-time usage metrics from providers
/// Migrated to Riverpod for accurate, real-time counts
class AppUsagePage extends ConsumerStatefulWidget {
  const AppUsagePage({super.key});

  @override
  ConsumerState<AppUsagePage> createState() => _AppUsagePageState();
}

class _AppUsagePageState extends ConsumerState<AppUsagePage> with HideOnScrollMixin {
  @override
  void initState() {
    super.initState();
    initHideOnScroll();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  /// Build UsageData from provider data
  UsageData _buildUsageData({
    required int savedRecallsCount,
    required int activeFiltersCount,
    required SubscriptionInfo subscriptionInfo,
  }) {
    final tier = subscriptionInfo.tier;
    // Only RecallMatch tier has unlimited access
    final isUnlimited = tier == SubscriptionTier.recallMatch;

    // Use getter methods to ensure fallback logic is applied
    final recallsLimit = subscriptionInfo.getSavedRecallsLimit();
    final filtersLimit = subscriptionInfo.getSavedFilterLimit();

    return UsageData(
      recallsViewed: 0, // Not tracking this metric yet
      recallsViewedLimit: null,
      recallsViewedPercentage: 0,

      filtersApplied: activeFiltersCount,
      filtersAppliedLimit: isUnlimited ? null : filtersLimit,
      filtersAppliedPercentage: isUnlimited
          ? 0
          : filtersLimit > 0
              ? ((activeFiltersCount / filtersLimit) * 100).round().clamp(0, 100)
              : 0,

      searchesPerformed: 0, // Not tracking this metric yet
      searchesPerformedLimit: null,
      searchesPerformedPercentage: 0,

      recallsSaved: savedRecallsCount,
      recallsSavedLimit: isUnlimited ? null : recallsLimit,
      recallsSavedPercentage: isUnlimited
          ? 0
          : recallsLimit > 0
              ? ((savedRecallsCount / recallsLimit) * 100).round().clamp(0, 100)
              : 0,

      daysUntilReset: 0,
      nextReset: null,
      tier: tier.toString().split('.').last,
      tierDisplay: subscriptionInfo.getTierDisplayName(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for real-time data
    final savedRecallsAsync = ref.watch(savedRecallsProvider);
    final activeFiltersAsync = ref.watch(activeFiltersProvider);
    final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A4A5C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'App Usage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh all providers
              ref.invalidate(savedRecallsProvider);
              ref.invalidate(activeFiltersProvider);
              ref.invalidate(subscriptionInfoProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            // Wait for all providers to load
            if (savedRecallsAsync.isLoading ||
                activeFiltersAsync.isLoading ||
                subscriptionInfoAsync.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // Check for errors
            if (subscriptionInfoAsync.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load usage data',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(savedRecallsProvider);
                        ref.invalidate(activeFiltersProvider);
                        ref.invalidate(subscriptionInfoProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A4A5C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Get data from providers
            final savedRecalls = savedRecallsAsync.valueOrNull ?? [];
            final activeFilters = activeFiltersAsync.valueOrNull ?? [];
            final subscriptionInfo = subscriptionInfoAsync.value;

            if (subscriptionInfo == null) {
              return const Center(
                child: Text(
                  'No subscription data available',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              );
            }

            // Build UsageData from provider data
            final usageData = _buildUsageData(
              savedRecallsCount: savedRecalls.length,
              activeFiltersCount: activeFilters.length,
              subscriptionInfo: subscriptionInfo,
            );

            return SingleChildScrollView(
              controller: hideOnScrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page description
                  const Text(
                    'Track your app usage and see how close you are to your tier limits.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Usage Widget (shows real-time counts!)
                  UsageWidget(usageData: usageData),

                  const SizedBox(height: 32),

                  // Additional Info Section
                  _buildInfoSection(usageData),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2C3E50),
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.white54,
          currentIndex: 2,
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

  Widget _buildInfoSection(UsageData usageData) {
    // Determine tier-specific messaging
    final isFree = usageData.tier == 'free';
    final isSmartFiltering = usageData.tier == 'smartFiltering';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Usage Limits',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.bookmark,
            title: 'Saved Recalls',
            description: usageData.isUnlimited
                ? 'Save up to 50 recalls for quick access'
                : isFree
                    ? 'Save up to 5 recalls. Upgrade to SmartFiltering for 15, or RecallMatch for 50.'
                    : 'Save up to ${usageData.recallsSavedLimit} recalls for quick access',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.filter_list,
            title: 'Saved Filters',
            description: usageData.isUnlimited
                ? 'Create unlimited saved filters (SmartFilters)'
                : usageData.filtersAppliedLimit == 0
                    ? 'Upgrade to SmartFiltering to save custom filters'
                    : 'Save up to ${usageData.filtersAppliedLimit} custom filters',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.public,
            title: 'Recall Sources',
            description: usageData.isUnlimited
                ? 'Access all agencies: FDA, USDA, CPSC, and NHTSA'
                : isFree
                    ? 'Access FDA and USDA recalls. Upgrade for CPSC and NHTSA.'
                    : 'Access FDA, USDA, and CPSC recalls',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.history,
            title: 'Recall History',
            description: usageData.isUnlimited || isSmartFiltering
                ? 'View recalls from January 1st of this year'
                : 'View recalls from the last 30 days. Upgrade for full year access.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  usageData.isUnlimited ? Icons.star : Icons.info_outline,
                  color: usageData.isUnlimited
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF64B5F6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    usageData.isUnlimited
                        ? 'You have RecallMatch premium access!'
                        : isSmartFiltering
                            ? 'You have SmartFiltering premium access.'
                            : 'Upgrade to unlock more features and higher limits.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF64B5F6),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
