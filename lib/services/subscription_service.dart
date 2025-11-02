import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

/// Subscription tier enum
enum SubscriptionTier {
  guest,
  free,
  smartFiltering,
  recallMatch,
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

  /// Factory for guest users (not logged in)
  factory SubscriptionInfo.guest() {
    return SubscriptionInfo(
      tier: SubscriptionTier.guest,
      filterLimit: 3,
      savedRecallsLimit: 20,
      hasPremiumAccess: false,
      isActive: true,
    );
  }

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
        return SubscriptionTier.free;
      case 'guest':
      default:
        return SubscriptionTier.guest;
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
      case SubscriptionTier.guest:
        return 'Guest';
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
      case SubscriptionTier.guest:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => tier != SubscriptionTier.guest;

  /// Check if user is on free plan
  bool get isFreePlan => tier == SubscriptionTier.free;

  /// Check if user is on premium plan
  bool get isPremium => tier == SubscriptionTier.smartFiltering || tier == SubscriptionTier.recallMatch;

  /// Get saved filter limit based on tier
  /// Free/Guest: 0, SmartFiltering: 10, RecallMatch: 999 (unlimited)
  int getSavedFilterLimit() {
    switch (tier) {
      case SubscriptionTier.recallMatch:
        return 999; // Unlimited
      case SubscriptionTier.smartFiltering:
        return 10;
      case SubscriptionTier.free:
      case SubscriptionTier.guest:
        return 0;
    }
  }
}

/// Service for managing user subscriptions
class SubscriptionService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();

  // Singleton pattern
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Cache subscription info to avoid repeated API calls
  SubscriptionInfo? _cachedSubscription;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get current user's subscription info
  Future<SubscriptionInfo> getSubscriptionInfo({bool forceRefresh = false}) async {
    print('🔐 SubscriptionService.getSubscriptionInfo() called - forceRefresh: $forceRefresh');

    // Return cached subscription if available and not expired
    if (!forceRefresh &&
        _cachedSubscription != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      print('📦 Using cached subscription - Tier: ${_cachedSubscription!.tier}, HasPremium: ${_cachedSubscription!.hasPremiumAccess}');
      return _cachedSubscription!;
    }

    final token = await _authService.getAccessToken();
    print('🔑 Access token: ${token != null && token.isNotEmpty ? "EXISTS (${token.substring(0, 20)}...)" : "NULL/EMPTY"}');

    // If no token, user is guest
    if (token == null || token.isEmpty) {
      print('👤 No token found - returning GUEST subscription (hasPremiumAccess: false)');
      final guestInfo = SubscriptionInfo.guest();
      _cachedSubscription = guestInfo;
      _cacheTime = DateTime.now();
      return guestInfo;
    }

    print('🌐 Fetching subscription from API...');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/subscription/current/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('✅ API returned 200 - parsing subscription data');
        final subscription = SubscriptionInfo.fromJson(json.decode(response.body));
        print('📋 Subscription from API - Tier: ${subscription.tier}, HasPremium: ${subscription.hasPremiumAccess}');
        _cachedSubscription = subscription;
        _cacheTime = DateTime.now();
        return subscription;
      } else {
        print('⚠️ Failed to fetch subscription: ${response.statusCode}');
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
      print('❌ Error fetching subscription: $e');
      // Return guest mode on error
      final guestInfo = SubscriptionInfo.guest();
      _cachedSubscription = guestInfo;
      _cacheTime = DateTime.now();
      return guestInfo;
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
      final response = await http.get(
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
      print('❌ Error getting usage stats: $e');
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
  Future<Map<String, dynamic>> upgradeToSmartFiltering() async {
    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'error': 'You must be logged in to upgrade',
      };
    }

    try {
      final response = await http.post(
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
      print('❌ Error upgrading subscription: $e');
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
