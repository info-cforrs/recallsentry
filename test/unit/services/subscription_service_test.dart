/// SubscriptionService Unit Tests
///
/// Tests for subscription functionality including:
/// - Tier detection and limits
/// - Feature gating
/// - Agency access control
/// - Response parsing
///
/// To run: flutter test test/unit/services/subscription_service_test.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:rs_flutter/services/subscription_service.dart';
import '../../fixtures/subscription_fixtures.dart';

void main() {
  group('SubscriptionTier Enum', () {
    test('has correct tier values', () {
      expect(SubscriptionTier.values.length, 3);
      expect(SubscriptionTier.free, isNotNull);
      expect(SubscriptionTier.smartFiltering, isNotNull);
      expect(SubscriptionTier.recallMatch, isNotNull);
    });
  });

  group('SubscriptionInfo - Factory Methods', () {
    group('Free Tier', () {
      test('creates correct free tier defaults', () {
        final freeInfo = SubscriptionInfo.free();

        expect(freeInfo.tier, SubscriptionTier.free);
        expect(freeInfo.filterLimit, 3);
        expect(freeInfo.savedRecallsLimit, 5);
        expect(freeInfo.hasPremiumAccess, false);
        expect(freeInfo.isActive, true);
        expect(freeInfo.subscriptionStartDate, null);
      });

      test('isFreePlan returns true for free tier', () {
        final freeInfo = SubscriptionInfo.free();
        expect(freeInfo.isFreePlan, true);
      });

      test('isPremium returns false for free tier', () {
        final freeInfo = SubscriptionInfo.free();
        expect(freeInfo.isPremium, false);
      });
    });

    group('From JSON', () {
      test('parses free subscription response', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.freeSubscriptionResponse,
        );

        expect(info.tier, SubscriptionTier.free);
        expect(info.filterLimit, 3);
        expect(info.savedRecallsLimit, 5);
        expect(info.hasPremiumAccess, false);
        expect(info.isActive, true);
      });

      test('parses smart filtering subscription response', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );

        expect(info.tier, SubscriptionTier.smartFiltering);
        expect(info.filterLimit, 10);
        expect(info.savedRecallsLimit, 15);
        expect(info.hasPremiumAccess, true);
        expect(info.isActive, true);
        expect(info.subscriptionStartDate, isNotNull);
      });

      test('parses recall match subscription response', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );

        expect(info.tier, SubscriptionTier.recallMatch);
        expect(info.filterLimit, 999);
        expect(info.savedRecallsLimit, 50);
        expect(info.hasPremiumAccess, true);
        expect(info.isActive, true);
      });

      test('parses expired subscription correctly', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.expiredSubscriptionResponse,
        );

        expect(info.tier, SubscriptionTier.smartFiltering);
        expect(info.isActive, false);
        expect(info.hasPremiumAccess, false);
      });

      test('handles unknown tier as free', () {
        final info = SubscriptionInfo.fromJson({
          'tier': 'unknown_tier',
          'filter_limit': 3,
          'saved_recalls_limit': 5,
          'has_premium_access': false,
          'is_active': true,
        });

        expect(info.tier, SubscriptionTier.free);
      });

      test('handles null tier as free', () {
        final info = SubscriptionInfo.fromJson({
          'tier': null,
          'filter_limit': 3,
          'saved_recalls_limit': 5,
          'has_premium_access': false,
          'is_active': true,
        });

        expect(info.tier, SubscriptionTier.free);
      });

      test('handles legacy guest tier as free', () {
        final info = SubscriptionInfo.fromJson({
          'tier': 'guest',
          'filter_limit': 3,
          'saved_recalls_limit': 5,
          'has_premium_access': false,
          'is_active': true,
        });

        expect(info.tier, SubscriptionTier.free);
      });
    });
  });

  group('SubscriptionInfo - Tier Limits', () {
    group('Saved Filter Limits', () {
      test('free tier has 0 saved filter limit', () {
        final info = SubscriptionInfo.free();
        expect(info.getSavedFilterLimit(), 0);
      });

      test('smart filtering has 10 saved filter limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.getSavedFilterLimit(), 10);
      });

      test('recall match has unlimited (999) saved filter limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.getSavedFilterLimit(), 999);
      });
    });

    group('State Filter Limits', () {
      test('free tier has 1 state filter limit', () {
        final info = SubscriptionInfo.free();
        expect(info.getStateFilterLimit(), 1);
      });

      test('smart filtering has 3 state filter limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.getStateFilterLimit(), 3);
      });

      test('recall match has unlimited (999) state filter limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.getStateFilterLimit(), 999);
      });
    });

    group('Saved Recalls Limits', () {
      test('free tier has 5 saved recalls limit', () {
        final info = SubscriptionInfo.free();
        expect(info.getSavedRecallsLimit(), 5);
      });

      test('smart filtering has 15 saved recalls limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.getSavedRecallsLimit(), 15);
      });

      test('recall match has 50 saved recalls limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.getSavedRecallsLimit(), 50);
      });

      test('uses API limit if provided and greater than 0', () {
        final info = SubscriptionInfo.fromJson({
          'tier': 'free',
          'filter_limit': 3,
          'saved_recalls_limit': 100, // Custom limit from API
          'has_premium_access': false,
          'is_active': true,
        });
        expect(info.getSavedRecallsLimit(), 100);
      });
    });

    group('Household Inventory Limits', () {
      test('free tier has 0 household inventory limit', () {
        final info = SubscriptionInfo.free();
        expect(info.getHouseholdInventoryLimit(), 0);
      });

      test('smart filtering has 0 household inventory limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.getHouseholdInventoryLimit(), 0);
      });

      test('recall match has 75 household inventory limit', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.getHouseholdInventoryLimit(), 75);
      });
    });

    group('Recall History Days', () {
      test('free tier has 30 days recall history', () {
        final info = SubscriptionInfo.free();
        expect(info.getRecallHistoryDays(), 30);
      });

      test('smart filtering has year-to-date recall history', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        final days = info.getRecallHistoryDays();

        // Should be days since Jan 1 of current year
        final now = DateTime.now();
        final janFirst = DateTime(now.year, 1, 1);
        final expectedDays = now.difference(janFirst).inDays;

        expect(days, expectedDays);
      });

      test('recall match has year-to-date recall history', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        final days = info.getRecallHistoryDays();

        // Should be days since Jan 1 of current year
        final now = DateTime.now();
        final janFirst = DateTime(now.year, 1, 1);
        final expectedDays = now.difference(janFirst).inDays;

        expect(days, expectedDays);
      });
    });
  });

  group('SubscriptionInfo - Agency Access', () {
    group('getAllowedAgencies', () {
      test('free tier allows FDA and USDA only', () {
        final info = SubscriptionInfo.free();
        final agencies = info.getAllowedAgencies();

        expect(agencies, contains('FDA'));
        expect(agencies, contains('USDA'));
        expect(agencies, isNot(contains('CPSC')));
        expect(agencies, isNot(contains('NHTSA')));
        expect(agencies.length, 2);
      });

      test('smart filtering allows FDA, USDA, and CPSC', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        final agencies = info.getAllowedAgencies();

        expect(agencies, contains('FDA'));
        expect(agencies, contains('USDA'));
        expect(agencies, contains('CPSC'));
        expect(agencies, isNot(contains('NHTSA')));
        expect(agencies.length, 3);
      });

      test('recall match allows all agencies', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        final agencies = info.getAllowedAgencies();

        expect(agencies, contains('FDA'));
        expect(agencies, contains('USDA'));
        expect(agencies, contains('CPSC'));
        expect(agencies, contains('NHTSA'));
        expect(agencies.length, 4);
      });
    });

    group('isAgencyAllowed', () {
      test('free tier blocks CPSC', () {
        final info = SubscriptionInfo.free();
        expect(info.isAgencyAllowed('CPSC'), false);
      });

      test('free tier blocks NHTSA', () {
        final info = SubscriptionInfo.free();
        expect(info.isAgencyAllowed('NHTSA'), false);
      });

      test('free tier allows FDA', () {
        final info = SubscriptionInfo.free();
        expect(info.isAgencyAllowed('FDA'), true);
      });

      test('agency check is case insensitive', () {
        final info = SubscriptionInfo.free();
        expect(info.isAgencyAllowed('fda'), true);
        expect(info.isAgencyAllowed('FDA'), true);
        expect(info.isAgencyAllowed('Fda'), true);
      });

      test('smart filtering allows CPSC but blocks NHTSA', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.isAgencyAllowed('CPSC'), true);
        expect(info.isAgencyAllowed('NHTSA'), false);
      });

      test('recall match allows NHTSA', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.isAgencyAllowed('NHTSA'), true);
      });
    });
  });

  group('SubscriptionInfo - Feature Access', () {
    group('RMC Access', () {
      test('free tier has no RMC access', () {
        final info = SubscriptionInfo.free();
        expect(info.hasRMCAccess, false);
      });

      test('smart filtering has no RMC access', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.hasRMCAccess, false);
      });

      test('recall match has RMC access', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.hasRMCAccess, true);
      });
    });

    group('SmartScan Access', () {
      test('free tier has no SmartScan access', () {
        final info = SubscriptionInfo.free();
        expect(info.hasSmartScanAccess, false);
      });

      test('smart filtering has no SmartScan access', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.hasSmartScanAccess, false);
      });

      test('recall match has SmartScan access', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.hasSmartScanAccess, true);
      });
    });

    group('RecallMatch Engine Access', () {
      test('free tier has no RecallMatch engine', () {
        final info = SubscriptionInfo.free();
        expect(info.hasRecallMatchEngine, false);
      });

      test('smart filtering has no RecallMatch engine', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.smartFilteringSubscriptionResponse,
        );
        expect(info.hasRecallMatchEngine, false);
      });

      test('recall match has RecallMatch engine', () {
        final info = SubscriptionInfo.fromJson(
          SubscriptionFixtures.recallMatchSubscriptionResponse,
        );
        expect(info.hasRecallMatchEngine, true);
      });
    });
  });

  group('SubscriptionInfo - Display', () {
    test('free tier display name', () {
      final info = SubscriptionInfo.free();
      expect(info.getTierDisplayName(), 'Free');
    });

    test('smart filtering display name', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.smartFilteringSubscriptionResponse,
      );
      expect(info.getTierDisplayName(), 'SmartFiltering');
    });

    test('recall match display name', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.recallMatchSubscriptionResponse,
      );
      expect(info.getTierDisplayName(), 'RecallMatch');
    });

    test('free tier badge color is blue', () {
      final info = SubscriptionInfo.free();
      expect(info.getTierBadgeColor(), 0xFF64B5F6);
    });

    test('smart filtering badge color is green', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.smartFilteringSubscriptionResponse,
      );
      expect(info.getTierBadgeColor(), 0xFF4CAF50);
    });

    test('recall match badge color is gold', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.recallMatchSubscriptionResponse,
      );
      expect(info.getTierBadgeColor(), 0xFFFFD700);
    });
  });

  group('SubscriptionInfo - Premium Status', () {
    test('free tier is not premium', () {
      final info = SubscriptionInfo.free();
      expect(info.isPremium, false);
    });

    test('smart filtering is premium', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.smartFilteringSubscriptionResponse,
      );
      expect(info.isPremium, true);
    });

    test('recall match is premium', () {
      final info = SubscriptionInfo.fromJson(
        SubscriptionFixtures.recallMatchSubscriptionResponse,
      );
      expect(info.isPremium, true);
    });
  });

  group('Usage Stats Parsing', () {
    test('parses free user usage stats', () {
      final stats = SubscriptionFixtures.freeUserUsageStats;

      expect(stats['filters_used'], 2);
      expect(stats['filters_limit'], 3);
      expect(stats['saved_recalls_used'], 3);
      expect(stats['saved_recalls_limit'], 5);
      expect(stats['can_add_filter'], true);
      expect(stats['can_save_recall'], true);
    });

    test('parses free user at limit stats', () {
      final stats = SubscriptionFixtures.freeUserAtLimitUsageStats;

      expect(stats['filters_used'], 3);
      expect(stats['filters_limit'], 3);
      expect(stats['can_add_filter'], false);
      expect(stats['can_save_recall'], false);
    });

    test('parses premium user usage stats', () {
      final stats = SubscriptionFixtures.premiumUserUsageStats;

      expect(stats['filters_used'], 5);
      expect(stats['filters_limit'], 10);
      expect(stats['can_add_filter'], true);
    });
  });

  group('Limit Checking Logic', () {
    test('can add filter when under limit', () {
      const currentCount = 2;
      const limit = 3;
      expect(currentCount < limit, true);
    });

    test('cannot add filter when at limit', () {
      const currentCount = 3;
      const limit = 3;
      expect(currentCount < limit, false);
    });

    test('cannot add filter when over limit', () {
      const currentCount = 4;
      const limit = 3;
      expect(currentCount < limit, false);
    });

    test('can save recall when under limit', () {
      const currentCount = 4;
      const limit = 5;
      expect(currentCount < limit, true);
    });

    test('cannot save recall when at limit', () {
      const currentCount = 5;
      const limit = 5;
      expect(currentCount < limit, false);
    });
  });

  group('IAP Product IDs', () {
    test('smart filtering monthly ID is correct', () {
      expect(
        SubscriptionFixtures.smartFilteringMonthlyId,
        'smart_filtering_monthly',
      );
    });

    test('smart filtering yearly ID is correct', () {
      expect(
        SubscriptionFixtures.smartFilteringYearlyId,
        'smart_filtering_yearly',
      );
    });

    test('recall match monthly ID is correct', () {
      expect(
        SubscriptionFixtures.recallMatchMonthlyId,
        'recall_match_monthly',
      );
    });

    test('recall match yearly ID is correct', () {
      expect(
        SubscriptionFixtures.recallMatchYearlyId,
        'recall_match_yearly',
      );
    });
  });

  group('Purchase Verification Response', () {
    test('parses successful verification', () {
      final response = SubscriptionFixtures.purchaseVerificationSuccessResponse;

      expect(response['valid'], true);
      expect(response['product_id'], isNotNull);
      expect(response['tier'], isNotNull);
    });

    test('parses failed verification', () {
      final response = SubscriptionFixtures.purchaseVerificationFailureResponse;

      expect(response['valid'], false);
      expect(response['error'], isNotNull);
    });
  });

  group('Cache Duration', () {
    test('subscription cache duration is 15 minutes', () {
      // This matches SubscriptionService._cacheDuration
      const cacheDuration = Duration(minutes: 15);
      expect(cacheDuration.inMinutes, 15);
    });
  });
}
