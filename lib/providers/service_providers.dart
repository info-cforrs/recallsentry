/// Service Layer Providers
///
/// This file defines singleton providers for all service classes.
/// By using providers, we ensure single instances are shared across the app,
/// improving performance and enabling shared caching.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recall_data_service.dart';
import '../services/subscription_service.dart';
import '../services/api_service.dart';
import '../services/saved_recalls_service.dart';
import '../services/saved_filter_service.dart';
import '../services/gamification_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/article_service.dart';
import '../services/recallmatch_service.dart';
import '../services/recall_update_service.dart';

// ============================================================================
// SERVICE PROVIDERS (Singletons)
// ============================================================================

/// Recall Data Service - Fetches FDA and USDA recalls from Google Sheets
final recallDataServiceProvider = Provider<RecallDataService>((ref) {
  return RecallDataService();
});

/// Subscription Service - Manages user subscription tier and premium access
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// API Service - Handles backend API calls for RMC, user data, etc.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Saved Recalls Service - Manages locally saved recalls
final savedRecallsServiceProvider = Provider<SavedRecallsService>((ref) {
  return SavedRecallsService();
});

/// Saved Filter Service - Manages cloud-synced SmartFilters
final savedFilterServiceProvider = Provider<SavedFilterService>((ref) {
  return SavedFilterService();
});

/// Gamification Service - Manages SafetyScore and badges
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService();
});

/// Auth Service - Handles user authentication
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// User Profile Service - Manages user profile data
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

/// Article Service - Fetches safety articles
final articleServiceProvider = Provider<ArticleService>((ref) {
  return ArticleService();
});

/// RecallMatch Service - Manages user homes, rooms, and items for recall matching
final recallMatchServiceProvider = Provider<RecallMatchService>((ref) {
  return RecallMatchService();
});

/// Recall Update Service - Manages recall update notifications and preferences
final recallUpdateServiceProvider = Provider<RecallUpdateService>((ref) {
  return RecallUpdateService();
});
