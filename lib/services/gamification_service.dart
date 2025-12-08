import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/safety_score.dart';
import '../models/badge.dart';
import 'auth_service.dart';
import 'security_service.dart';

/// Service for managing gamification features
/// Handles SafetyScore, Badges, Streaks, and related API calls
class GamificationService {
  final String baseUrl = AppConfig.apiBaseUrl;
  final AuthService _authService = AuthService();
  late final http.Client _httpClient;

  // Singleton pattern
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  // Privacy consent - controls whether gamification tracking is enabled
  bool _isEnabled = true;

  /// Enable or disable gamification tracking (for privacy consent)
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      // Clear cached data when disabled
      clearCache();
    }
  }

  /// Check if gamification is enabled
  bool get isEnabled => _isEnabled;

  // Cache for safety score
  SafetyScore? _cachedScore;
  DateTime? _scoreCacheTime;
  static const Duration _scoreCacheDuration = Duration(minutes: 5);

  // Cache for badges
  List<UserBadge>? _cachedBadges;
  DateTime? _badgesCacheTime;
  static const Duration _badgesCacheDuration = Duration(minutes: 10);

  /// Get user's current SafetyScore
  /// SECURITY: Uses certificate pinning
  Future<SafetyScore> getSafetyScore({bool forceRefresh = false}) async {
    // Return cached score if available and not expired
    if (!forceRefresh &&
        _cachedScore != null &&
        _scoreCacheTime != null &&
        DateTime.now().difference(_scoreCacheTime!) < _scoreCacheDuration) {
      return _cachedScore!;
    }

    final token = await _authService.getAccessToken();

    // If no token, return initial score
    if (token == null || token.isEmpty) {
      final initialScore = SafetyScore.initial();
      _cachedScore = initialScore;
      _scoreCacheTime = DateTime.now();
      return initialScore;
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/gamification/safety-score/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final score = SafetyScore.fromJson(json.decode(response.body));
        _cachedScore = score;
        _scoreCacheTime = DateTime.now();
        return score;
      } else if (response.statusCode == 404) {
        // No score exists yet, return initial
        final initialScore = SafetyScore.initial();
        _cachedScore = initialScore;
        _scoreCacheTime = DateTime.now();
        return initialScore;
      } else {
        throw Exception('Failed to get safety score: ${response.statusCode}');
      }
    } catch (e) {
      // Return initial score on error
      final initialScore = SafetyScore.initial();
      _cachedScore = initialScore;
      _scoreCacheTime = DateTime.now();
      return initialScore;
    }
  }

  /// Get user's badges with progress
  /// SECURITY: Uses certificate pinning
  Future<List<UserBadge>> getUserBadges({bool forceRefresh = false}) async {
    // Return cached badges if available and not expired
    if (!forceRefresh &&
        _cachedBadges != null &&
        _badgesCacheTime != null &&
        DateTime.now().difference(_badgesCacheTime!) < _badgesCacheDuration) {
      return _cachedBadges!;
    }

    final token = await _authService.getAccessToken();

    // If no token, return starter badges with no progress
    if (token == null || token.isEmpty) {
      final starterBadges = StarterBadges.getAllStarter()
          .map((badge) => UserBadge(
                badgeId: badge.id,
                badge: badge,
                isUnlocked: false,
                currentProgress: 0,
                requiredProgress: badge.requiredCount ?? 1,
              ))
          .toList();
      _cachedBadges = starterBadges;
      _badgesCacheTime = DateTime.now();
      return starterBadges;
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/gamification/badges/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> badgesJson = json.decode(response.body);
        final badges = badgesJson.map((b) => UserBadge.fromJson(b)).toList();
        _cachedBadges = badges;
        _badgesCacheTime = DateTime.now();
        return badges;
      } else if (response.statusCode == 404) {
        // No badges yet, return starter badges
        final starterBadges = StarterBadges.getAllStarter()
            .map((badge) => UserBadge(
                  badgeId: badge.id,
                  badge: badge,
                  isUnlocked: false,
                  currentProgress: 0,
                  requiredProgress: badge.requiredCount ?? 1,
                ))
            .toList();
        _cachedBadges = starterBadges;
        _badgesCacheTime = DateTime.now();
        return starterBadges;
      } else {
        throw Exception('Failed to get badges: ${response.statusCode}');
      }
    } catch (e) {
      // Return starter badges on error
      final starterBadges = StarterBadges.getAllStarter()
          .map((badge) => UserBadge(
                badgeId: badge.id,
                badge: badge,
                isUnlocked: false,
                currentProgress: 0,
                requiredProgress: badge.requiredCount ?? 1,
              ))
          .toList();
      _cachedBadges = starterBadges;
      _badgesCacheTime = DateTime.now();
      return starterBadges;
    }
  }

  /// Record a gamification action (e.g., save recall, create filter, etc.)
  /// This updates the user's SafetyScore and checks for badge unlocks
  /// SECURITY: Uses certificate pinning
  /// PRIVACY: Respects user consent - no tracking if disabled
  Future<Map<String, dynamic>> recordAction(String actionType) async {
    // Check if gamification is enabled (privacy consent)
    if (!_isEnabled) {
      return {
        'success': false,
        'error': 'Gamification tracking is disabled',
      };
    }

    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'error': 'User must be logged in',
      };
    }

    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/gamification/record-action/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'action_type': actionType}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // Clear caches to force refresh
        clearCache();

        return {
          'success': true,
          'score_change': result['score_change'] ?? 0,
          'new_score': result['new_score'] ?? 0,
          'badges_unlocked': result['badges_unlocked'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to record action: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Check for newly unlocked badges
  /// Returns list of badge IDs that were recently unlocked
  Future<List<String>> checkNewBadges() async {
    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/gamification/check-new-badges/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> badgeIds = json.decode(response.body);
        return badgeIds.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Mark new badges as seen (dismiss notification)
  Future<void> markBadgesAsSeen(List<String> badgeIds) async {
    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty || badgeIds.isEmpty) {
      return;
    }

    try {
      await _httpClient.post(
        Uri.parse('$baseUrl/gamification/mark-badges-seen/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'badge_ids': badgeIds}),
      );
    } catch (e) {
      // Silent fail - not critical
    }
  }

  /// Get leaderboard (for Rev2)
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String scope = 'global',
    int limit = 50,
  }) async {
    final token = await _authService.getAccessToken();

    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/gamification/leaderboard/?scope=$scope&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> leaderboard = json.decode(response.body);
        return leaderboard.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Clear all gamification caches
  void clearCache() {
    _cachedScore = null;
    _scoreCacheTime = null;
    _cachedBadges = null;
    _badgesCacheTime = null;
  }

  /// Action type constants for recording actions
  static const String actionReceiveAlert = 'receive_alert';
  static const String actionSaveRecall = 'save_recall';
  static const String actionCreateFilter = 'create_filter';
  static const String actionDailyLogin = 'daily_login';
  static const String actionViewRecallDetails = 'view_recall_details';
  static const String actionShareRecall = 'share_recall';
  static const String actionCompleteRmc = 'complete_rmc';
}
