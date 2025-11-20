/// Data Layer Providers
///
/// This file defines providers for commonly accessed data like subscription info,
/// user profile, recalls, etc. These providers use the service providers and
/// handle async data fetching with proper caching.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import '../models/recall_data.dart';
import '../models/safety_score.dart';
import '../services/subscription_service.dart';
import '../services/user_profile_service.dart';
import '../models/saved_filter.dart';

// ============================================================================
// SUBSCRIPTION & USER DATA PROVIDERS
// ============================================================================

/// Subscription Info Provider - Fetches and caches user subscription tier
///
/// This is one of the most frequently accessed pieces of data in the app.
/// Using a FutureProvider ensures we only fetch it once and share it everywhere.
///
/// Watches userProfile for invalidation AND awaits it for race condition prevention
final subscriptionInfoProvider = FutureProvider<SubscriptionInfo>((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  await ref.watch(userProfileProvider.future);

  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionInfo();
});

/// Subscription Tier Provider - Derived from subscription info
///
/// Provides quick access to just the tier without needing to unwrap SubscriptionInfo
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);
  return subscriptionInfoAsync.when(
    data: (info) => info.tier,
    loading: () => SubscriptionTier.free,
    error: (_, __) => SubscriptionTier.free,
  );
});

/// Has Premium Access Provider - Quick check for premium features
final hasPremiumAccessProvider = Provider<bool>((ref) {
  final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);
  return subscriptionInfoAsync.maybeWhen(
    data: (info) => info.hasPremiumAccess,
    orElse: () => false,
  );
});

/// Has RMC Access Provider - Quick check for RMC feature access
final hasRMCAccessProvider = Provider<bool>((ref) {
  final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);
  return subscriptionInfoAsync.maybeWhen(
    data: (info) => info.hasRMCAccess,
    orElse: () => false,
  );
});

/// User Profile Provider - Fetches and caches user profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return userProfileService.getUserProfile();
});

/// Is Logged In Provider - Quick check if user is authenticated
final isLoggedInProvider = Provider<bool>((ref) {
  final userProfileAsync = ref.watch(userProfileProvider);
  return userProfileAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => false,
  );
});

// ============================================================================
// RECALL DATA PROVIDERS
// ============================================================================

/// FDA Recalls Provider - Fetches all FDA recalls from Google Sheets
///
/// Data is cached automatically by Riverpod. Calling invalidate() will refetch.
final fdaRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final recallService = ref.watch(recallDataServiceProvider);
  return recallService.getFdaRecalls();
});

/// USDA Recalls Provider - Fetches all USDA recalls from Google Sheets
final usdaRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final recallService = ref.watch(recallDataServiceProvider);
  return recallService.getUsdaRecalls();
});

/// All Recalls Provider - Combines FDA and USDA recalls
final allRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final fdaRecallsAsync = ref.watch(fdaRecallsProvider);
  final usdaRecallsAsync = ref.watch(usdaRecallsProvider);

  // Wait for both to complete
  final fdaRecalls = await fdaRecallsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<RecallData>[]),
    error: (_, __) => Future.value(<RecallData>[]),
  );

  final usdaRecalls = await usdaRecallsAsync.when(
    data: (data) => Future.value(data),
    loading: () => Future.value(<RecallData>[]),
    error: (_, __) => Future.value(<RecallData>[]),
  );

  return [...fdaRecalls, ...usdaRecalls];
});

/// Filtered Recalls Provider (Tier-Based) - Applies tier-based date filtering
///
/// Free users: Last 30 days
/// Premium users: Since Jan 1 of current year
final filteredRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  final allRecalls = await ref.watch(allRecallsProvider.future);
  final subscriptionInfo = await ref.watch(subscriptionInfoProvider.future);

  final tier = subscriptionInfo.tier;
  final allowedAgencies = subscriptionInfo.getAllowedAgencies();
  final now = DateTime.now();
  final DateTime cutoff;

  if (tier == SubscriptionTier.free) {
    cutoff = now.subtract(const Duration(days: 30));
  } else {
    cutoff = DateTime(now.year, 1, 1);
  }

  return allRecalls.where((recall) {
    return recall.dateIssued.isAfter(cutoff) &&
           allowedAgencies.contains(recall.agency.toUpperCase());
  }).toList()
    ..sort((a, b) => b.dateIssued.compareTo(a.dateIssued));
});

/// Saved Recalls Provider - User's locally saved recalls
///
/// Watches userProfile for invalidation AND awaits it for race condition prevention
/// (switches between local storage and API based on login status)
final savedRecallsProvider = FutureProvider<List<RecallData>>((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  await ref.watch(userProfileProvider.future);

  final savedRecallsService = ref.watch(savedRecallsServiceProvider);
  return savedRecallsService.getSavedRecalls();
});

// ============================================================================
// SAVED FILTERS PROVIDERS
// ============================================================================

/// Saved Filters Provider - User's cloud-synced SmartFilters
///
/// Watches userProfile for invalidation AND only fetches if user is logged in
final savedFiltersProvider = FutureProvider<List<SavedFilter>>((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  final userProfile = await ref.watch(userProfileProvider.future);

  // Only fetch filters if user is logged in
  if (userProfile == null) {
    return []; // Return empty list for logged out users
  }

  final filterService = ref.watch(savedFilterServiceProvider);
  return filterService.fetchSavedFilters();
});

/// Active Filters Provider - Only filters that are enabled and have criteria
final activeFiltersProvider = FutureProvider<List<SavedFilter>>((ref) async {
  final allFilters = await ref.watch(savedFiltersProvider.future);

  return allFilters.where((filter) {
    final hasFilters = filter.brandFilters.isNotEmpty ||
                      filter.productFilters.isNotEmpty ||
                      filter.stateFilters.isNotEmpty;
    return filter.isActive && hasFilters;
  }).toList();
});

/// SmartFilter Matched Recalls Provider - Recalls that match active filters
/// Returns a list of maps containing recall data and the matching filter name
///
/// Watches userProfile for invalidation AND awaits it for race condition prevention
final smartFilterMatchedRecallsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  final userProfile = await ref.watch(userProfileProvider.future);

  // Return empty list if user is not logged in
  if (userProfile == null) {
    return [];
  }

  // Fetch both in parallel for better performance
  final fetchResults = await Future.wait([
    ref.watch(activeFiltersProvider.future),
    ref.watch(filteredRecallsProvider.future),
  ]);

  final activeFilters = fetchResults[0] as List<SavedFilter>;
  final filteredRecalls = fetchResults[1] as List<RecallData>;

  if (activeFilters.isEmpty) return [];

  // Map to track recall ID to first matching filter name
  Map<String, String> recallIdToFilterName = {};

  for (var filter in activeFilters) {
    for (var recall in filteredRecalls) {
      // Skip if already matched by another filter
      if (recallIdToFilterName.containsKey(recall.id)) continue;

      // Check if recall matches any brand, product, or state filter (OR logic)
      final matchesBrand = filter.brandFilters.any((brand) =>
          recall.brandName.toLowerCase().contains(brand.toLowerCase()));
      final matchesProduct = filter.productFilters.any((product) =>
          recall.productName.toLowerCase().contains(product.toLowerCase()));
      final matchesState = filter.stateFilters.any((state) {
        final distribution = recall.productDistribution.toLowerCase();
        return distribution.contains(state.toLowerCase()) ||
               distribution == 'nationwide' ||
               distribution == 'all states';
      });

      // Brand OR Product OR State
      if (matchesBrand || matchesProduct || matchesState) {
        recallIdToFilterName[recall.id] = filter.name;
      }
    }
  }

  // Build list of maps with recall and filter name
  List<Map<String, dynamic>> results = [];
  for (var recall in filteredRecalls) {
    if (recallIdToFilterName.containsKey(recall.id)) {
      results.add({
        'recall': recall,
        'filterName': recallIdToFilterName[recall.id]!,
      });
    }
  }

  return results;
});

// ============================================================================
// GAMIFICATION PROVIDERS
// ============================================================================

/// Safety Score Provider - User's gamification SafetyScore
///
/// Watches userProfile for invalidation AND awaits it for race condition prevention
final safetyScoreProvider = FutureProvider<SafetyScore?>((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  await ref.watch(userProfileProvider.future);

  final gamificationService = ref.watch(gamificationServiceProvider);
  try {
    // Force refresh to bypass cache when provider is refreshed
    return await gamificationService.getSafetyScore(forceRefresh: true);
  } catch (e) {
    // Silent fail - gamification is not critical
    return null;
  }
});

// ============================================================================
// RMC (RECALL MONITORING CENTER) PROVIDERS
// ============================================================================

/// Active RMC Enrollments Provider - Fetches user's active RMC enrollments
/// (excludes completed and closed enrollments)
///
/// Watches userProfile for invalidation AND awaits it for race condition prevention
final activeRmcEnrollmentsProvider = FutureProvider((ref) async {
  // Watch and await - this both tracks changes AND waits for completion
  await ref.watch(userProfileProvider.future);

  final apiService = ref.watch(apiServiceProvider);
  try {
    final enrollments = await apiService.fetchActiveRmcEnrollments();
    // Filter out completed and closed enrollments
    return enrollments.where((e) {
      final status = e.status.trim().toLowerCase();
      return status != 'completed' && status != 'closed';
    }).toList();
  } catch (e) {
    return [];
  }
});

/// RMC Recalls with Enrollments Provider - Fetches recall data for active RMC enrollments
/// Returns a list of maps containing recall data and corresponding enrollment info
final rmcRecallsWithEnrollmentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final enrollments = await ref.watch(activeRmcEnrollmentsProvider.future);

  List<Map<String, dynamic>> results = [];

  for (var enrollment in enrollments) {
    try {
      final recall = await apiService.fetchRecallById(enrollment.recallId);
      results.add({
        'recall': recall,
        'enrollment': enrollment,
        'status': enrollment.status,
      });
    } catch (e) {
      // Skip recalls that fail to fetch
    }
  }

  return results;
});

/// Category Counts Provider - Calculates recall counts by category
/// Returns a map of category key to count
final categoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final filteredRecalls = await ref.watch(filteredRecallsProvider.future);

  final categories = {
    'food': ['food'],
    'cosmetics': ['cosmetics', 'personal care'],
    'drugs': ['otc drugs', 'supplements'],
    'home': ['home', 'furniture'],
    'clothing': ['clothing', 'kids items'],
    'childSeats': ['child seats', 'other accessories'],
    'powerTools': ['power tools', 'lawn care'],
    'electronics': ['electronics', 'appliances'],
    'vehicles': ['car', 'truck', 'suv'],
    'tires': ['tires'],
    'toys': ['toys'],
    'pets': ['pet', 'veterinary', 'animal'],
  };

  final counts = <String, int>{};

  categories.forEach((key, keywords) {
    final count = filteredRecalls.where((recall) {
      final cat = recall.category.toLowerCase();
      return keywords.any((k) => cat.contains(k.toLowerCase()));
    }).length;

    counts[key] = count;
  });

  return counts;
});
