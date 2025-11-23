import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/widgets/empty_state.dart';
import 'all_fda_recalls_page.dart';
import 'all_usda_recalls_page.dart';
import 'all_cpsc_recalls_page.dart';
import 'all_recalls_page.dart';
import 'main_navigation.dart';
import 'new_recalls_page.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import '../services/subscription_service.dart';
import 'category_filter_page.dart' as category;
import 'rmc_page.dart';
import 'rmc_details_page.dart';
import '../widgets/small_main_page_recall_card.dart';
import '../widgets/safety_score_widget.dart';
import 'badges_page.dart';
import 'subscribe_page.dart';
import '../providers/data_providers.dart';
import '../providers/service_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRecalls;

  const HomePage({super.key, this.onNavigateToRecalls});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  // Only local UI state remains - scroll controller
  final ScrollController _carouselScrollController = ScrollController();

  // No more service instantiations!
  // No more state variables for data - all from providers!

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // No more manual loading - providers handle this automatically!
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _carouselScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh providers when app resumes
      // CRITICAL: Invalidate userProfile FIRST to pick up auth changes
      ref.invalidate(userProfileProvider);
      ref.invalidate(filteredRecallsProvider);
      ref.invalidate(savedRecallsProvider);
      ref.invalidate(rmcRecallsWithEnrollmentsProvider);
      ref.invalidate(smartFilterMatchedRecallsProvider);
      ref.invalidate(safetyScoreProvider);
    }
  }

  void didPopNext() {
    // Called when coming back to this page via navigation
    // CRITICAL: Refresh (not invalidate) to force IMMEDIATE recomputation
    ref.refresh(userProfileProvider);
    ref.refresh(subscriptionInfoProvider);
    ref.refresh(filteredRecallsProvider);
    ref.refresh(savedRecallsProvider);
    ref.refresh(rmcRecallsWithEnrollmentsProvider);
    ref.refresh(smartFilterMatchedRecallsProvider);
    ref.refresh(safetyScoreProvider);
  }

  // All data loading is now handled by providers - no more manual loading!

  Widget _buildRecallBadge(int count) {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textPrimary, width: 1),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String? imagePath,
    required IconData icon,
    required String label,
    required int? badgeCount,
    required String categoryKey,
    required List<String> categories,
  }) {
    return Semantics(
      label: '$label category, ${badgeCount ?? 0} recalls',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: () async {
          // Get subscription tier to determine cutoff date
          final navigator = Navigator.of(context);

          final subscriptionInfo = await ref.read(subscriptionServiceProvider).getSubscriptionInfo();
          final tier = subscriptionInfo.tier;

          final now = DateTime.now();
          final DateTime cutoff;
          if (tier == SubscriptionTier.free) {
            // Last 30 days for Free users
            cutoff = now.subtract(const Duration(days: 30));
          } else {
            // Since Jan 1 of current year for SmartFiltering/RecallMatch users
            cutoff = DateTime(now.year, 1, 1);
          }

          // Fetch FDA, USDA, and CPSC recalls
          final recallService = ref.read(recallDataServiceProvider);
          final fdaRecalls = await recallService.getFdaRecalls();
          final usdaRecalls = await recallService.getUsdaRecalls();
          final cpscRecalls = await recallService.getCpscRecalls();

          // Filter by cutoff date and matching categories
          final recentFda = fdaRecalls.where((recall) {
            if (!recall.dateIssued.isAfter(cutoff)) return false;
            final cat = recall.category.toLowerCase();
            return categories.any((c) => cat.contains(c.toLowerCase()));
          }).toList();

          final recentUsda = usdaRecalls.where((recall) {
            if (!recall.dateIssued.isAfter(cutoff)) return false;
            final cat = recall.category.toLowerCase();
            return categories.any((c) => cat.contains(c.toLowerCase()));
          }).toList();

          final recentCpsc = cpscRecalls.where((recall) {
            if (!recall.dateIssued.isAfter(cutoff)) return false;
            final cat = recall.category.toLowerCase();
            return categories.any((c) => cat.contains(c.toLowerCase()));
          }).toList();

          final List<RecallData> filtered = [...recentFda, ...recentUsda, ...recentCpsc];

          if (mounted) {
            navigator.push(
              MaterialPageRoute(
                builder: (context) => category.FilteredRecallsPage(
                  filteredRecalls: filtered,
                ),
              ),
            );
          }
        },
        child: SizedBox(
          width: 85,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentBlueLight, width: 3),
                  ),
                  child: ClipOval(
                    child: imagePath != null
                        ? Image.asset(
                            imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 36,
                                color: AppColors.secondary,
                              );
                            },
                          )
                        : Icon(
                            icon,
                            size: 36,
                            color: AppColors.secondary,
                          ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textPrimary, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showRmcUpgradeModal() {
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
                'Upgrade Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Recall Management Center (RMC) is an exclusive RecallMatch feature. Upgrade to RecallMatch (\$4.99/month) to access step-by-step recall resolution workflows, household inventory tracking, SmartScan, and automated RecallMatch engine.',
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
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF2A4A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch all providers - automatic loading and rebuilds!
    final filteredRecallsAsync = ref.watch(filteredRecallsProvider);
    final categoryCountsAsync = ref.watch(categoryCountsProvider);
    final savedRecallsAsync = ref.watch(savedRecallsProvider);
    final smartFilterMatchedAsync = ref.watch(smartFilterMatchedRecallsProvider);
    final rmcRecallsAsync = ref.watch(rmcRecallsWithEnrollmentsProvider);
    final safetyScoreAsync = ref.watch(safetyScoreProvider);
    final subscriptionTier = ref.watch(subscriptionTierProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // Check if critical data is still loading
    final isLoadingCriticalData = filteredRecallsAsync.isLoading || categoryCountsAsync.isLoading;

    // Check for errors in critical data
    final hasCriticalError = filteredRecallsAsync.hasError;

    // Extract data from async providers
    final safetyScore = safetyScoreAsync.valueOrNull;
    final categoryCounts = categoryCountsAsync.valueOrNull ?? {};
    final filteredRecalls = filteredRecallsAsync.valueOrNull ?? [];
    final savedRecallsList = savedRecallsAsync.valueOrNull ?? [];
    final smartFilterMatched = smartFilterMatchedAsync.valueOrNull ?? [];
    final rmcRecalls = rmcRecallsAsync.valueOrNull ?? [];

    // Calculate counts
    final totalRecalls = filteredRecalls.length;
    final fdaRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'FDA').length;
    final usdaRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'USDA').length;
    final cpscRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'CPSC').length;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
          child: isLoadingCriticalData
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading recalls...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : hasCriticalError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Unable to load recalls',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please check your internet connection and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Refresh all providers
                                ref.invalidate(filteredRecallsProvider);
                                ref.invalidate(categoryCountsProvider);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Custom Header with App Icon and RecallSentry Text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      // App Icon - Clickable to return to Home
                      GestureDetector(
                        onTap: () {
                          // Navigate to main home page with bottom navigation
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
                                    colors: [
                                      AppColors.success,
                                      AppColors.successDark,
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
                                  color: AppColors.textPrimary,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // 10px spacing as requested
                      // RecallSentry Text
                      const Text(
                        'RecallSentry',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Atlanta',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Title for Category Carousel
                Semantics(
                  label: 'Recalls by Category heading',
                  header: true,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Recalls by Category',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category Carousel
                SizedBox(
                  height: 140,
                  child: Listener(
                    onPointerSignal: (pointerSignal) {
                      if (pointerSignal is PointerScrollEvent) {
                        final offset = pointerSignal.scrollDelta.dy;
                        _carouselScrollController.jumpTo(
                          _carouselScrollController.offset + offset,
                        );
                      }
                    },
                    child: Scrollbar(
                      controller: _carouselScrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _carouselScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                      _buildCategoryCard(
                        imagePath: 'assets/images/food_beverage_category_button.png',
                        icon: Icons.restaurant,
                        label: 'Food &\nBeverages',
                        badgeCount: categoryCounts['food'],
                        categoryKey: 'food',
                        categories: ['food'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/cosmetics_category_button.png',
                        icon: Icons.brush,
                        label: 'Cosmetics &\nPersonal Care',
                        badgeCount: categoryCounts['cosmetics'],
                        categoryKey: 'cosmetics',
                        categories: ['cosmetics', 'personal care'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/otc_category_button.png',
                        icon: Icons.medication,
                        label: 'OTC Drugs &\nSupplements',
                        badgeCount: categoryCounts['drugs'],
                        categoryKey: 'drugs',
                        categories: ['otc drugs', 'supplements'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/home_furniture_category_button.png',
                        icon: Icons.chair,
                        label: 'Home &\nFurniture',
                        badgeCount: categoryCounts['home'],
                        categoryKey: 'home',
                        categories: ['home', 'furniture'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/clothing_category_button.png',
                        icon: Icons.checkroom,
                        label: 'Clothing',
                        badgeCount: categoryCounts['clothing'],
                        categoryKey: 'clothing',
                        categories: ['clothing', 'kids items'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/child_seats_category_button.png',
                        icon: Icons.child_care,
                        label: 'Child Seats &\nAccessories',
                        badgeCount: categoryCounts['childSeats'],
                        categoryKey: 'childSeats',
                        categories: ['child seats', 'other accessories'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/power_tools_category_button.png',
                        icon: Icons.build,
                        label: 'Power Tools &\nLawn Care',
                        badgeCount: categoryCounts['powerTools'],
                        categoryKey: 'powerTools',
                        categories: ['power tools', 'lawn care'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/electronics_category_button.png',
                        icon: Icons.devices,
                        label: 'Electronics &\nAppliances',
                        badgeCount: categoryCounts['electronics'],
                        categoryKey: 'electronics',
                        categories: ['electronics', 'appliances'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/vehicles_category_button.png',
                        icon: Icons.directions_car,
                        label: 'Vehicles',
                        badgeCount: categoryCounts['vehicles'],
                        categoryKey: 'vehicles',
                        categories: ['car', 'truck', 'suv'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/tires_category_button.png',
                        icon: Icons.trip_origin,
                        label: 'Tires',
                        badgeCount: categoryCounts['tires'],
                        categoryKey: 'tires',
                        categories: ['tires'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/toys_category_button.png',
                        icon: Icons.toys,
                        label: 'Toys',
                        badgeCount: categoryCounts['toys'],
                        categoryKey: 'toys',
                        categories: ['toys'],
                      ),
                      const SizedBox(width: 12),
                      _buildCategoryCard(
                        imagePath: 'assets/images/pets_veterinary_category_button.png',
                        icon: Icons.pets,
                        label: 'Pets &\nVeterinary',
                        badgeCount: categoryCounts['pets'],
                        categoryKey: 'pets',
                        categories: ['pet', 'veterinary', 'animal'],
                      ),
                    ],
                  ),
                ),
              ),
            ),

                const SizedBox(height: 24),

                // Main Content Card (like the Recalls card in the image)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        MainAxisSize.min, // Make column take minimum space
                    children: [
                      // All Recalls Button
                      Stack(
                        children: [
                          Semantics(
                            label: 'All Recalls button, $totalRecalls recalls available',
                            button: true,
                            enabled: true,
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to All Recalls page
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AllRecallsPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentBlue,
                                  foregroundColor: AppColors.textPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Text(
                                  'All Recalls',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildRecallBadge(
                            totalRecalls,
                          ), // Dynamic total recalls count
                        ],
                      ),

                      const SizedBox(height: 16),
                      // New Recalls Button
                      Semantics(
                        label: 'New Recalls from Today and Yesterday button',
                        button: true,
                        enabled: true,
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to New Recalls page
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const NewRecallsPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fiber_new, size: 24),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'New Recalls (Today & Yesterday)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),
                      // FDA and USDA Buttons Row
                      Row(
                        children: [
                          // FDA Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 80, // Taller than other buttons
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AllFDARecallsPage(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          child: Image.asset(
                                            'assets/images/FDA_Button.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.info,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'FDA',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  fdaRecalls,
                                ), // Dynamic FDA recalls count
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // USDA Button
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 80, // Taller than other buttons
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AllUSDARecallsPage(),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          child: Image.asset(
                                            'assets/images/USDA_Button.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: AppColors.successDark,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        'USDA',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildRecallBadge(
                                  usdaRecalls,
                                ), // Dynamic USDA recalls count
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CPSC Button (Full width below FDA/USDA)
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AllCPSCRecallsPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
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
                                    child: Image.asset(
                                      'assets/images/CPSC_Button.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1565C0),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'CPSC',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildRecallBadge(
                            cpscRecalls,
                          ), // Dynamic CPSC recalls count
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Recall Management Center Button
                      FutureBuilder<SubscriptionInfo>(
                        future: SubscriptionService().getSubscriptionInfo(),
                        builder: (context, snapshot) {
                          final hasRmcAccess = snapshot.data?.hasRMCAccess ?? false;

                          return Stack(
                            children: [
                              Semantics(
                                label: 'Recall Management Center button',
                                button: true,
                                enabled: hasRmcAccess,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: hasRmcAccess ? () {
                                      // Navigate to RMC page
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => RmcPage(key: UniqueKey()),
                                        ),
                                      );
                                    } : () {
                                      // Show upgrade modal
                                      _showRmcUpgradeModal();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasRmcAccess
                                          ? AppColors.accentBlueLight
                                          : Colors.grey[400],
                                      foregroundColor: hasRmcAccess
                                          ? AppColors.textPrimary
                                          : Colors.grey[600],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: hasRmcAccess ? 2 : 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Recall Management Center',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!hasRmcAccess) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.lock, size: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(
                        height: 20,
                      ), // 20px spacing after last button row
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // SafetyScore Widget (Gamification Rev1)
                // Styled to match All Recalls button section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SafetyScoreWidget(
                    score: safetyScore,
                    tier: subscriptionTier,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BadgesPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Saved Recalls Carousel Section
                // Show if user is logged in AND has saved recalls
                // (logged out users can have local saved recalls but we hide them)
                if (isLoggedIn && savedRecallsList.isNotEmpty) ...[
                  // Title
                  Semantics(
                    label: 'Your Saved Recalls heading',
                    header: true,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Your Saved Recalls',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Carousel
                  SizedBox(
                    height: 315,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: savedRecallsList.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 15),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: (MediaQuery.of(context).size.width - 32 - 30) / 2.5,
                            child: SmallMainPageRecallCard(
                              recall: savedRecallsList[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // SmartFiltered Recalls Carousel Section
                Builder(
                  builder: (context) {
                    final hasPremiumAccess = ref.watch(hasPremiumAccessProvider);
                    final hasRecalls = smartFilterMatched.isNotEmpty;

                    // Only show if user is logged in AND has premium access
                    if (!isLoggedIn || !hasPremiumAccess) {
                      return const SizedBox.shrink();
                    }

                    // If no recalls matched, show empty state
                    if (!hasRecalls) {
                      return const SizedBox.shrink(); // Hide completely if no matches
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Semantics(
                          label: 'Your SmartFiltered Recalls heading',
                          header: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Your SmartFiltered Recalls',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasPremiumAccess ? AppColors.textPrimary : AppColors.textDisabled,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Carousel
                        Opacity(
                          opacity: hasPremiumAccess ? 1.0 : 0.4,
                          child: SizedBox(
                            height: 345,
                            child: hasRecalls
                                ? ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context).copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                      },
                                    ),
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: smartFilterMatched.length,
                                      separatorBuilder: (context, index) => const SizedBox(width: 15),
                                      itemBuilder: (context, index) {
                                        final match = smartFilterMatched[index];
                                        return SizedBox(
                                          width: (MediaQuery.of(context).size.width - 32 - 30) / 2.5,
                                          child: IgnorePointer(
                                            ignoring: !hasPremiumAccess,
                                            child: SmallMainPageRecallCard(
                                              recall: match['recall'] as RecallData,
                                              filterName: match['filterName'] as String?,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : hasPremiumAccess
                                    ? const NoFilteredResultsEmptyState()
                                    : Center(
                                        child: Text(
                                          'Upgrade to access SmartFiltered recalls',
                                          style: const TextStyle(
                                            color: AppColors.textDisabled,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // RMC Recalls Carousel Section
                Builder(
                  builder: (context) {
                    final hasPremiumAccess = ref.watch(hasPremiumAccessProvider);
                    final hasRecalls = rmcRecalls.isNotEmpty;

                    // Hide if not logged in or no premium access
                    if (!isLoggedIn || !hasPremiumAccess) {
                      return const SizedBox.shrink();
                    }

                    // Hide if no active RMC recalls
                    if (!hasRecalls) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Semantics(
                          label: 'Your Recall Management Center Recalls heading',
                          header: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Your Recall Management Center Recalls',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasPremiumAccess ? AppColors.textPrimary : AppColors.textDisabled,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Carousel
                        Opacity(
                          opacity: hasPremiumAccess ? 1.0 : 0.4,
                          child: SizedBox(
                            height: 345,
                            child: hasRecalls
                                ? ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context).copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                      },
                                    ),
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: rmcRecalls.length,
                                      separatorBuilder: (context, index) => const SizedBox(width: 15),
                                      itemBuilder: (context, index) {
                                        final rmcData = rmcRecalls[index];
                                        final recall = rmcData['recall'] as RecallData;
                                        final enrollment = rmcData['enrollment'] as RmcEnrollment;
                                        final status = rmcData['status'] as String;

                                        return SizedBox(
                                          width: (MediaQuery.of(context).size.width - 32 - 30) / 2.5,
                                          child: IgnorePointer(
                                            ignoring: !hasPremiumAccess,
                                            child: SmallMainPageRecallCard(
                                              recall: recall,
                                              currentStatus: status,
                                              onTap: () async {
                                                // Navigate to RMC Details page (active workflow page)
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => RmcDetailsPage(
                                                      recall: recall,
                                                      enrollment: enrollment,
                                                    ),
                                                  ),
                                                );
                                                // Invalidate providers to refresh data
                                                ref.invalidate(rmcRecallsWithEnrollmentsProvider);
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      hasPremiumAccess
                                          ? 'No active RMC recalls found'
                                          : 'Upgrade to access Recall Management',
                                      style: TextStyle(
                                        color: hasPremiumAccess ? AppColors.textSecondary : AppColors.textDisabled,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
