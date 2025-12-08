import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'security_service.dart';

/// Subscription tier enum
/// NOTE: Guest and Free are merged - both use 'free' tier
enum SubscriptionTier {
  free,            // Free tier (logged in or guest users)
  smartFiltering,  // Premium tier - $1.99/month
  recallMatch,     // Coming in Rev2
}

/// Subscription information model
class SubscriptionInfo {
  final SubscriptionTier tier;
  final int filterLimit;
  final int savedRecallsLimit;
  final bool hasPremiumAccess;
  final bool isActive;
  final DateTime? subscriptionStartDate;

  SubscriptionInfo({
    required this.tier,
    required this.filterLimit,
    required this.savedRecallsLimit,
    required this.hasPremiumAccess,
    required this.isActive,
    this.subscriptionStartDate,
  });

  /// Factory for free tier users (logged in or guest)
  /// NOTE: Guest and Free are now merged into single 'free' tier
  factory SubscriptionInfo.free() {
    return SubscriptionInfo(
      tier: SubscriptionTier.free,
      filterLimit: 3,
      savedRecallsLimit: 5,  // Corrected from 20 to match backend
      hasPremiumAccess: false,
      isActive: true,
    );
  }

  /// Deprecated: Use SubscriptionInfo.free() instead
  @Deprecated('Guest and Free tiers are now merged. Use SubscriptionInfo.free()')
  factory SubscriptionInfo.guest() => SubscriptionInfo.free();

  /// Factory from JSON API response
  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      tier: _parseTier(json['tier']),
      filterLimit: json['filter_limit'] ?? 3,
      savedRecallsLimit: json['saved_recalls_limit'] ?? 20,
      hasPremiumAccess: json['has_premium_access'] ?? false,
      isActive: json['is_active'] ?? true,
      subscriptionStartDate: json['subscription_start_date'] != null
          ? DateTime.tryParse(json['subscription_start_date'])
          : null,
    );
  }

  /// Parse tier string from API
  static SubscriptionTier _parseTier(String? tier) {
    switch (tier) {
      case 'recall_match':
        return SubscriptionTier.recallMatch;
      case 'smart_filtering':
        return SubscriptionTier.smartFiltering;
      case 'free':
      case 'guest':  // Legacy: treat guest as free
      default:
        return SubscriptionTier.free;
    }
  }

  /// Get display name for tier
  String getTierDisplayName() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 'RecallMatch';
      case SubscriptionTier.smartFiltering:
        return 'SmartFiltering';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  /// Get tier badge color
  int getTierBadgeColor() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 0xFFFFD700; // Gold
      case SubscriptionTier.smartFiltering:
        return 0xFF4CAF50; // Green
      case SubscriptionTier.free:
        return 0xFF64B5F6; // Blue
    }
  }

  /// Check if user is logged in
  /// NOTE: Since Guest/Free are merged, this now checks if user has access token
  /// Will be true for logged-in free users, false for guests
  bool get isLoggedIn => tier != SubscriptionTier.free; // This should be checked via AuthService instead

  /// Check if user is on free plan
  bool get isFreePlan => tier == SubscriptionTier.free;

  /// Check if user is on premium plan
  bool get isPremium => tier == SubscriptionTier.smartFiltering || tier == SubscriptionTier.recallMatch;

  /// Get saved filter limit based on tier
  /// Free: 0, SmartFiltering: 10, RecallMatch: 999 (unlimited)
  int getSavedFilterLimit() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 999; // Unlimited
      case SubscriptionTier.smartFiltering:
        return 10;
      case SubscriptionTier.free:
        return 0;
    }
  }

  /// Get state filter limit based on tier
  /// Free: 1 state, SmartFiltering: 3 states, RecallMatch: 999 (unlimited)
  int getStateFilterLimit() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 999; // Unlimited
      case SubscriptionTier.smartFiltering:
        return 3;
      case SubscriptionTier.free:
        return 1;
    }
  }

  /// Get saved recalls limit based on tier
  /// Free: 5, SmartFiltering: 15, RecallMatch: 50
  int getSavedRecallsLimit() {
    // First check if API provided a limit
    if (savedRecallsLimit > 0) {
      return savedRecallsLimit;
    }

    // Fallback to tier-based limits
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 50;
      case SubscriptionTier.smartFiltering:
        return 15;
      case SubscriptionTier.free:
        return 5;
    }
  }

  /// Get household inventory limit based on tier
  /// Free: 0, SmartFiltering: 0, RecallMatch: 75
  int getHouseholdInventoryLimit() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 75;
      case SubscriptionTier.smartFiltering:
        return 0;
      case SubscriptionTier.free:
        return 0;
    }
  }

  /// Check if user has access to RMC (Recall Management Center)
  /// Free: No, SmartFiltering: No, RecallMatch: Yes
  bool get hasRMCAccess => tier == SubscriptionTier.recallMatch;

  /// Check if user has access to SmartScan (camera/barcode scanning)
  /// Free: No, SmartFiltering: No, RecallMatch: Yes
  bool get hasSmartScanAccess => tier == SubscriptionTier.recallMatch;

  /// Check if user has access to RecallMatch Engine (automated matching)
  /// Free: No, SmartFiltering: No, RecallMatch: Yes
  bool get hasRecallMatchEngine => tier == SubscriptionTier.recallMatch;

  /// Get allowed recall agencies based on tier
  /// Free: FDA, USDA
  /// SmartFiltering: FDA, USDA, CPSC
  /// RecallMatch: FDA, USDA, CPSC, NHTSA
  List<String> getAllowedAgencies() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return ['FDA', 'USDA', 'CPSC', 'NHTSA'];
      case SubscriptionTier.smartFiltering:
        return ['FDA', 'USDA', 'CPSC'];
      case SubscriptionTier.free:
        return ['FDA', 'USDA'];
    }
  }

  /// Check if agency is allowed for current tier
  bool isAgencyAllowed(String agency) {
    final allowed = getAllowedAgencies();
    return allowed.contains(agency.toUpperCase());
  }

  /// Get recall history limit in days based on tier
  /// Free: 30 days, SmartFiltering: Since Jan 1, RecallMatch: Since Jan 1
  int getRecallHistoryDays() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
      case SubscriptionTier.smartFiltering:
        // Calculate days since January 1 of current year
        final now = DateTime.now();
        final janFirst = DateTime(now.year, 1, 1);
        return now.difference(janFirst).inDays;
      case SubscriptionTier.free:
        return 30;
    }
  }
}

/// Service for managing user subscriptions
class SubscriptionService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();
  late final http.Client _httpClient;

  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  // Cache subscription info to avoid repeated API calls
  SubscriptionInfo? _cachedSubscription;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current user's subscription info
  /// SECURITY: Uses certificate pinning
  Future<SubscriptionInfo> getSubscriptionInfo({bool forceRefresh = false}) async {
    // Return cached subscription if available and not expired
    if (!forceRefresh &&
        _cachedSubscription != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedSubscription!;
    }

    final token = await _authService.getAccessToken();

    // If no token, user is on free tier (not logged in)
    if (token == null || token.isEmpty) {
      final freeInfo = SubscriptionInfo.free();
      _cachedSubscription = freeInfo;
      _cacheTime = DateTime.now();
      return freeInfo;
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/user/subscription/current/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final subscription = SubscriptionInfo.fromJson(json.decode(response.body));
        _cachedSubscription = subscription;
        _cacheTime = DateTime.now();
        return subscription;
      } else {
        // If API fails, assume free plan for logged-in users
        final freePlan = SubscriptionInfo(
          tier: SubscriptionTier.free,
          filterLimit: 3,
          savedRecallsLimit: 20,
          hasPremiumAccess: false,
          isActive: true,
        );
        _cachedSubscription = freePlan;
        _cacheTime = DateTime.now();
        return freePlan;
      }
    } catch (e) {
      // Return free tier on error
      final freeInfo = SubscriptionInfo.free();
      _cachedSubscription = freeInfo;
      _cacheTime = DateTime.now();
      return freeInfo;
    }
  }

  /// Clear cached subscription (call after login/logout)
  void clearCache() {
    _cachedSubscription = null;
    _cacheTime = null;
  }

  /// Check if user can add more filters
  Future<bool> canAddFilter(int currentFilterCount) async {
    final subscription = await getSubscriptionInfo();
    return currentFilterCount < subscription.filterLimit;
  }

  /// Check if user can save more recalls
  Future<bool> canSaveRecall(int currentSavedCount) async {
    final subscription = await getSubscriptionInfo();
    return currentSavedCount < subscription.savedRecallsLimit;
  }

  /// Get usage statistics
  /// SECURITY: Uses certificate pinning
  Future<Map<String, dynamic>> getUsageStats() async {
    final token = await _authService.getAccessToken();

    // If no token, return guest usage
    if (token == null || token.isEmpty) {
      return {
        'filters_used': 0,
        'filters_limit': 3,
        'saved_recalls_used': 0,
        'saved_recalls_limit': 20,
        'subscription_tier': 'guest',
        'can_add_filter': true,
        'can_save_recall': true,
      };
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/user/usage/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get usage stats');
      }
    } catch (e) {
      // Return default free plan stats
      return {
        'filters_used': 0,
        'filters_limit': 3,
        'saved_recalls_used': 0,
        'saved_recalls_limit': 20,
        'subscription_tier': 'free',
        'can_add_filter': true,
        'can_save_recall': true,
      };
    }
  }

  /// Upgrade to Smart Filtering (placeholder for Stripe integration)
  /// SECURITY: Uses certificate pinning
  Future<Map<String, dynamic>> upgradeToSmartFiltering() async {
    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'error': 'You must be logged in to upgrade',
      };
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/user/subscription/upgrade/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        clearCache(); // Clear cache to fetch new subscription
        return {
          'success': true,
          'message': json.decode(response.body)['message'],
        };
      } else {
        return {
          'success': false,
          'error': 'Upgrade failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final token = await _authService.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
