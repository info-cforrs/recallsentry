/// Subscription Test Fixtures
///
/// Sample data for subscription-related tests.
library;

/// Sample subscription data for testing
class SubscriptionFixtures {
  /// Free tier subscription response
  static Map<String, dynamic> get freeSubscriptionResponse => {
        'tier': 'free',
        'filter_limit': 3,
        'saved_recalls_limit': 5,
        'has_premium_access': false,
        'is_active': true,
        'subscription_start_date': null,
      };

  /// Smart Filtering tier subscription response
  static Map<String, dynamic> get smartFilteringSubscriptionResponse => {
        'tier': 'smart_filtering',
        'filter_limit': 10,
        'saved_recalls_limit': 15,
        'has_premium_access': true,
        'is_active': true,
        'subscription_start_date': '2024-01-01T00:00:00Z',
      };

  /// RecallMatch tier subscription response
  static Map<String, dynamic> get recallMatchSubscriptionResponse => {
        'tier': 'recall_match',
        'filter_limit': 999,
        'saved_recalls_limit': 50,
        'has_premium_access': true,
        'is_active': true,
        'subscription_start_date': '2024-01-01T00:00:00Z',
      };

  /// Expired subscription response
  static Map<String, dynamic> get expiredSubscriptionResponse => {
        'tier': 'smart_filtering',
        'filter_limit': 10,
        'saved_recalls_limit': 15,
        'has_premium_access': false,
        'is_active': false,
        'subscription_start_date': '2023-01-01T00:00:00Z',
      };

  /// Usage stats for free user
  static Map<String, dynamic> get freeUserUsageStats => {
        'filters_used': 2,
        'filters_limit': 3,
        'saved_recalls_used': 3,
        'saved_recalls_limit': 5,
        'subscription_tier': 'free',
        'can_add_filter': true,
        'can_save_recall': true,
      };

  /// Usage stats for free user at limit
  static Map<String, dynamic> get freeUserAtLimitUsageStats => {
        'filters_used': 3,
        'filters_limit': 3,
        'saved_recalls_used': 5,
        'saved_recalls_limit': 5,
        'subscription_tier': 'free',
        'can_add_filter': false,
        'can_save_recall': false,
      };

  /// Usage stats for premium user
  static Map<String, dynamic> get premiumUserUsageStats => {
        'filters_used': 5,
        'filters_limit': 10,
        'saved_recalls_used': 10,
        'saved_recalls_limit': 15,
        'subscription_tier': 'smart_filtering',
        'can_add_filter': true,
        'can_save_recall': true,
      };

  /// Upgrade success response
  static Map<String, dynamic> get upgradeSuccessResponse => {
        'message': 'Successfully upgraded to Smart Filtering',
        'new_tier': 'smart_filtering',
      };

  /// IAP Product IDs
  static const String smartFilteringMonthlyId = 'smart_filtering_monthly';
  static const String smartFilteringYearlyId = 'smart_filtering_yearly';
  static const String recallMatchMonthlyId = 'recall_match_monthly';
  static const String recallMatchYearlyId = 'recall_match_yearly';

  /// IAP Purchase verification success response
  static Map<String, dynamic> get purchaseVerificationSuccessResponse => {
        'valid': true,
        'product_id': smartFilteringMonthlyId,
        'tier': 'smart_filtering',
      };

  /// IAP Purchase verification failure response
  static Map<String, dynamic> get purchaseVerificationFailureResponse => {
        'valid': false,
        'error': 'Invalid purchase receipt',
      };
}
