import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/widgets/empty_state.dart';
import 'package:rs_flutter/widgets/animated_visibility_wrapper.dart';
import 'package:rs_flutter/widgets/custom_loading_indicator.dart';
import 'package:rs_flutter/mixins/hide_on_scroll_mixin.dart';
import 'all_fda_recalls_page.dart';
import 'all_usda_recalls_page.dart';
import 'all_cpsc_recalls_page.dart';
import 'all_recalls_page.dart';
import 'all_vehicle_recalls_page.dart';
import 'all_tire_recalls_page.dart';
import 'all_child_seat_recalls_page.dart';
import 'main_navigation.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import '../services/subscription_service.dart';
import '../services/recallmatch_service.dart';
import '../services/api_service.dart';
import 'category_filter_page.dart' as category;
import 'rmc_page.dart';
import 'rmc_details_page.dart';
import 'recall_match_alert_page.dart';
import '../widgets/small_main_page_recall_card.dart';
import '../widgets/safety_score_widget.dart';
import '../widgets/home_portal_widget.dart';
import 'badges_page.dart';
import '../models/user_home.dart';
import '../models/user_item.dart';
import 'advanced_filter_page.dart';
import 'home_view_page.dart';
import 'quick_check_page.dart';
import 'saved_filters_page.dart';
import '../providers/data_providers.dart';
import '../providers/service_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToRecalls;

  const HomePage({super.key, this.onNavigateToRecalls});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver, HideOnScrollMixin {
  // Only local UI state remains - scroll controller
  final ScrollController _carouselScrollController = ScrollController();
  final RecallMatchService _recallMatchService = RecallMatchService();

  // Home Portal widget data
  UserHome? _userHome;
  int _totalItems = 0;
  int _recalledItems = 0;

  // Key to force RMC card refresh when returning from RMC pages
  int _rmcCardKey = 0;

  // No more service instantiations!
  // No more state variables for data - all from providers!

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initHideOnScroll(); // Initialize hide-on-scroll
    _loadAllHomeData();
    // No more manual loading - providers handle this automatically!
  }

  /// Load all home data in a single method to avoid multiple setState calls
  Future<void> _loadAllHomeData() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _recallMatchService.getUserHomes(),
        _recallMatchService.getUserItems(),
        ApiService().fetchRmcEnrollments(),
      ]);

      final homes = results[0] as List<UserHome>;
      final items = results[1] as List<UserItem>;
      final enrollments = results[2] as List<RmcEnrollment>;

      // Count "In Progress" enrollments using SAME logic as RMC widget
      // This ensures "Recalled Items" matches "In Progress" count
      int inProgressCount = 0;
      for (var enrollment in enrollments) {
        final status = enrollment.status.trim().toLowerCase();
        // In Progress: excludes closed, completed, not started, stopped using, mfr contacted
        if (status != 'closed' &&
            status != 'completed' &&
            status != 'not started' &&
            status != 'stopped using' &&
            status != 'mfr contacted') {
          inProgressCount++;
        }
      }

      // Single setState call with all data
      if (mounted) {
        setState(() {
          _userHome = homes.isNotEmpty ? homes.first : null;
          _totalItems = items.length;
          _recalledItems = inProgressCount;
        });
      }
    } catch (e) {
      // Silently fail - widget will show placeholder
      debugPrint('Warning: Could not load home data: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeHideOnScroll(); // Clean up hide-on-scroll
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
      // Also refresh local home portal data
      _loadAllHomeData();
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
    // Also refresh local home portal data
    _loadAllHomeData();
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

  /// Build category card that navigates directly to an NHTSA page
  Widget _buildNhtsaCategoryCard({
    required String? imagePath,
    required IconData icon,
    required String label,
    required int? badgeCount,
    required Widget destinationPage,
  }) {
    return Semantics(
      label: '$label category, ${badgeCount ?? 0} recalls',
      button: true,
      enabled: true,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => destinationPage),
          );
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
    final hasRMCAccess = ref.watch(hasRMCAccessProvider);

    // Check if critical data is still loading
    final isLoadingCriticalData = filteredRecallsAsync.isLoading || categoryCountsAsync.isLoading;

    // Check for errors in critical data
    final hasCriticalError = filteredRecallsAsync.hasError;

    // Extract data from async providers
    final safetyScore = safetyScoreAsync.value;
    final categoryCounts = categoryCountsAsync.value ?? {};
    final filteredRecalls = filteredRecallsAsync.value ?? [];
    final savedRecallsList = savedRecallsAsync.value ?? [];
    final smartFilterMatched = smartFilterMatchedAsync.value ?? [];
    final rmcRecalls = rmcRecallsAsync.value ?? [];

    // Calculate counts - FDA, USDA, CPSC from filteredRecalls
    final fdaRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'FDA').length;
    final usdaRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'USDA').length;
    final cpscRecalls = filteredRecalls.where((r) => r.agency.toUpperCase() == 'CPSC').length;

    // NHTSA counts come from categoryCountsProvider (tier-filtered)
    final nhtsaVehicles = categoryCounts['vehicles'] ?? 0;
    final nhtsaTires = categoryCounts['tires'] ?? 0;
    final nhtsaChildSeats = categoryCounts['childSeats'] ?? 0;
    final nhtsaRecalls = nhtsaVehicles + nhtsaTires + nhtsaChildSeats;

    // Total includes all agencies
    final totalRecalls = filteredRecalls.length + nhtsaRecalls;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
          child: isLoadingCriticalData
              ? const CustomLoadingIndicator(
                  message: 'Loading recalls...',
                  size: LoadingIndicatorSize.medium,
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
            controller: hideOnScrollController, // Use mixin's scroll controller
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Custom Header with App Icon and RecallSentry Text - with hide-on-scroll
                AnimatedVisibilityWrapper(
                  isVisible: isHeaderVisible,
                  direction: SlideDirection.up,
                  child: Padding(
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
                      _buildNhtsaCategoryCard(
                        imagePath: 'assets/images/all_recalls_category_button.png',
                        icon: Icons.grid_view,
                        label: 'All\nRecalls',
                        badgeCount: totalRecalls,
                        destinationPage: const AllRecallsPage(),
                      ),
                      const SizedBox(width: 12),
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
                      _buildNhtsaCategoryCard(
                        imagePath: 'assets/images/child_seats_category_button.png',
                        icon: Icons.child_care,
                        label: 'Child Seats &\nAccessories',
                        badgeCount: categoryCounts['childSeats'],
                        destinationPage: const AllChildSeatRecallsPage(),
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
                      _buildNhtsaCategoryCard(
                        imagePath: 'assets/images/vehicles_category_button.png',
                        icon: Icons.directions_car,
                        label: 'Vehicles',
                        badgeCount: categoryCounts['vehicles'],
                        destinationPage: const AllVehicleRecallsPage(),
                      ),
                      const SizedBox(width: 12),
                      _buildNhtsaCategoryCard(
                        imagePath: 'assets/images/tires_category_button.png',
                        icon: Icons.trip_origin,
                        label: 'Tires',
                        badgeCount: categoryCounts['tires'],
                        destinationPage: const AllTireRecallsPage(),
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

                // Home Portal Section - Only show for RecallMatch users
                if (hasRMCAccess) ...[
                  HomePortalWidget(
                    home: _userHome,
                    totalItems: _totalItems,
                    recalledItems: _recalledItems,
                    onTap: () async {
                      // Navigate to Home View Page to see rooms
                      if (_userHome != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeViewPage(home: _userHome!),
                          ),
                        );
                        // Reload data when returning (recalls may have been completed)
                        if (mounted) {
                          setState(() {
                            _rmcCardKey++;
                          });
                          _loadAllHomeData();
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

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
                      // Quick Action Icons Row
                      _buildQuickActionIconsRow(
                        hasRMCAccess: hasRMCAccess,
                        subscriptionTier: subscriptionTier,
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

                      const SizedBox(height: 16),

                      // NHTSA Button (Full width below CPSC)
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
                                            const AllVehicleRecallsPage(),
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
                                      'assets/images/NHTSA_Button.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D47A1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'NHTSA',
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
                            nhtsaRecalls,
                          ), // Dynamic NHTSA recalls count
                        ],
                      ),

                    ],
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

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Quick Action Icons Section
  /// Row 1: Filter Recalls, Quick Check, Your SmartFilters (with labels)
  /// Row 2: RecallMatch Alerts (left 1/3) + RMC Card (right 2/3)
  Widget _buildQuickActionIconsRow({
    required bool hasRMCAccess,
    required SubscriptionTier subscriptionTier,
  }) {
    final hasSmartFilterAccess = subscriptionTier == SubscriptionTier.smartFiltering ||
                                  subscriptionTier == SubscriptionTier.recallMatch;

    return Column(
      children: [
        // Row 1: 3 icons with text labels below - equal width columns, top aligned
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Recalls - Available to all users (1/3 width)
            Expanded(
              child: _buildQuickActionIconWithLabel(
                imagePath: 'assets/images/filter_recalls_icon.png',
                fallbackIcon: Icons.filter_alt,
                backgroundColor: const Color(0xFF2D3E50),
                label: 'Filter Recalls',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdvancedFilterPage()),
                  );
                },
              ),
            ),

            // Quick Check - RMC users only (1/3 width)
            if (hasRMCAccess)
              Expanded(
                child: _buildQuickActionIconWithLabel(
                  imagePath: 'assets/images/quick_check_icon.png',
                  fallbackIcon: Icons.search,
                  backgroundColor: AppColors.success,
                  label: 'Quick Check',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QuickCheckPage()),
                    );
                  },
                ),
              ),

            // Your SmartFilters - SmartFiltering+ users (1/3 width)
            if (hasSmartFilterAccess)
              Expanded(
                child: _buildQuickActionIconWithLabel(
                  imagePath: 'assets/images/your_smartfilters_iconV2.png',
                  fallbackIcon: Icons.tune,
                  backgroundColor: const Color(0xFF1976D2),
                  label: 'Your\nSmartFilters',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedFiltersPage()),
                    );
                  },
                ),
              ),
          ],
        ),

        // Row 2: RecallMatch Alerts (left) + RMC Card (right) - RMC users only
        if (hasRMCAccess) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left 1/3: RecallMatch Alerts with badge and label
              Expanded(
                flex: 1,
                child: FutureBuilder<int>(
                  future: _recallMatchService.getPendingMatchCount(),
                  builder: (context, snapshot) {
                    final pendingCount = snapshot.data ?? 0;
                    return _buildQuickActionIconWithLabel(
                      imagePath: 'assets/images/recallmatch_alerts_icon.png',
                      fallbackIcon: Icons.notifications,
                      backgroundColor: const Color(0xFF2D3E50),
                      label: 'RecallMatch\nAlerts',
                      badgeCount: pendingCount > 0 ? pendingCount : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RecallMatchAlertPage()),
                        );
                      },
                    );
                  },
                ),
              ),

              // Right 2/3: Recall Management Card
              Expanded(
                flex: 2,
                child: _buildRecallManagementCard(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build individual Quick Action Icon button with label
  Widget _buildQuickActionIconWithLabel({
    required String imagePath,
    required IconData fallbackIcon,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        fallbackIcon,
                        color: Colors.white,
                        size: 28,
                      );
                    },
                  ),
                ),
              ),
              // Badge for notification count
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Helper method to get estimated value from enrollment's recall data
  /// Same logic as RmcPage to ensure consistent values
  double? _getEstimatedValueFromRecallData(RmcEnrollment enrollment) {
    if (enrollment.recallData == null) {
      return null;
    }

    // Use lowercase field name to match API response
    final estValue = enrollment.recallData!['est_item_value'];
    if (estValue == null || estValue == '') {
      return null;
    }

    // Try to parse the value - it might be a string like "$25.99" or "25.99"
    String valueStr = estValue.toString().replaceAll('\$', '').replaceAll(',', '').trim();
    final parsedValue = double.tryParse(valueStr);
    return parsedValue;
  }

  /// Build Recall Management Summary Card
  /// Shows Est. Value, In Progress count, and Completed count
  Widget _buildRecallManagementCard() {
    // Use FutureBuilder to fetch ALL enrollments (including completed)
    // KeyedSubtree forces rebuild when _rmcCardKey changes (e.g., after returning from RMC pages)
    return KeyedSubtree(
      key: ValueKey(_rmcCardKey),
      child: FutureBuilder<List<RmcEnrollment>>(
        future: ApiService().fetchRmcEnrollments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRecallManagementCardContent(
            estValue: 0.0,
            inProgressCount: 0,
            completedCount: 0,
            isLoading: true,
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildRecallManagementCardContent(
            estValue: 0.0,
            inProgressCount: 0,
            completedCount: 0,
          );
        }

        final enrollments = snapshot.data!;

        // Calculate stats from enrollments using same logic as RmcPage
        double totalEstValue = 0.0;
        int inProgressCount = 0;
        int completedCount = 0;

        for (var enrollment in enrollments) {
          final status = enrollment.status.trim().toLowerCase();

          // Add estimated value ONLY for completed/closed enrollments (same as RmcPage)
          if (status == 'completed' || status == 'closed') {
            final estValue = _getEstimatedValueFromRecallData(enrollment);
            if (estValue != null) {
              totalEstValue += estValue;
            }
          }

          // In Progress: excludes closed, completed, not started, stopped using, mfr contacted
          if (status != 'closed' &&
              status != 'completed' &&
              status != 'not started' &&
              status != 'stopped using' &&
              status != 'mfr contacted') {
            inProgressCount++;
          }

          // Completed: only completed or closed
          if (status == 'completed' || status == 'closed') {
            completedCount++;
          }
        }

        return _buildRecallManagementCardContent(
          estValue: totalEstValue,
          inProgressCount: inProgressCount,
          completedCount: completedCount,
        );
      },
      ),
    );
  }

  /// Build the actual Recall Management Card content
  /// Layout: Top row (icon + value), green divider, stats, footer label outside
  Widget _buildRecallManagementCardContent({
    required double estValue,
    required int inProgressCount,
    required int completedCount,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RmcPage(key: UniqueKey())),
        );
        // Refresh RMC card data when returning (recalls may have been completed)
        if (mounted) {
          setState(() {
            _rmcCardKey++;
          });
        }
      },
      child: Column(
        children: [
          // Card container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: RMC icon (left) + Est. Value (right)
                Row(
                  children: [
                    // RMC Icon
                    Image.asset(
                      'assets/images/rmc_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.list_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Est. Value
                    Text(
                      '\$${estValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Green divider (3px)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 8),

                // In Progress count
                Row(
                  children: [
                    Text(
                      'In Progress: ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$inProgressCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Completed count
                Row(
                  children: [
                    Text(
                      'Completed: ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$completedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Footer: "Recall Management Center" - outside the card
          Text(
            'Recall Management\nCenter',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
