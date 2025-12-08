import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'security_service.dart';
import '../config/app_config.dart';

class UsageData {
  final int recallsViewed;
  final int? recallsViewedLimit;
  final int recallsViewedPercentage;

  final int filtersApplied;
  final int? filtersAppliedLimit;
  final int filtersAppliedPercentage;

  final int searchesPerformed;
  final int? searchesPerformedLimit;
  final int searchesPerformedPercentage;

  final int recallsSaved;
  final int? recallsSavedLimit;
  final int recallsSavedPercentage;

  final int daysUntilReset;
  final String? nextReset;
  final String tier;
  final String tierDisplay;

  UsageData({
    required this.recallsViewed,
    this.recallsViewedLimit,
    required this.recallsViewedPercentage,
    required this.filtersApplied,
    this.filtersAppliedLimit,
    required this.filtersAppliedPercentage,
    required this.searchesPerformed,
    this.searchesPerformedLimit,
    required this.searchesPerformedPercentage,
    required this.recallsSaved,
    this.recallsSavedLimit,
    required this.recallsSavedPercentage,
    required this.daysUntilReset,
    this.nextReset,
    required this.tier,
    required this.tierDisplay,
  });

  factory UsageData.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>;
    final resetInfo = json['reset_info'] as Map<String, dynamic>;

    return UsageData(
      recallsViewed: usage['recalls_viewed']['current'] as int,
      recallsViewedLimit: usage['recalls_viewed']['limit'] as int?,
      recallsViewedPercentage: usage['recalls_viewed']['percentage'] as int,

      filtersApplied: usage['filters_applied']['current'] as int,
      filtersAppliedLimit: usage['filters_applied']['limit'] as int?,
      filtersAppliedPercentage: usage['filters_applied']['percentage'] as int,

      searchesPerformed: usage['searches_performed']['current'] as int,
      searchesPerformedLimit: usage['searches_performed']['limit'] as int?,
      searchesPerformedPercentage: usage['searches_performed']['percentage'] as int,

      recallsSaved: usage['recalls_saved']['current'] as int,
      recallsSavedLimit: usage['recalls_saved']['limit'] as int?,
      recallsSavedPercentage: usage['recalls_saved']['percentage'] as int,

      daysUntilReset: resetInfo['days_until_reset'] as int,
      nextReset: resetInfo['next_reset'] as String?,

      tier: json['tier'] as String,
      tierDisplay: json['tier_display'] as String,
    );
  }

  bool get isUnlimited => tier == 'smart_filtering' || tier == 'recall_match';
}

class UsageService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  UsageService() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  // Cache for usage data
  UsageData? _cachedUsageData;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get user usage statistics
  /// SECURITY: Uses certificate pinning
  Future<UsageData?> getUserUsage({bool forceRefresh = false}) async {
    // Return cached data if still valid and not forcing refresh
    if (!forceRefresh &&
        _cachedUsageData != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedUsageData;
    }

    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        return null;
      }

      final url = Uri.parse('$_baseUrl/user/usage/');
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedUsageData = UsageData.fromJson(data);
        _lastFetchTime = DateTime.now();
        return _cachedUsageData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Track user action
  /// SECURITY: Uses certificate pinning
  Future<bool> trackUsage(String actionType) async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        return false;
      }

      final url = Uri.parse('$_baseUrl/track-usage/');
      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action_type': actionType,
        }),
      );

      if (response.statusCode == 200) {
        // Clear cache to force refresh on next fetch
        clearCache();
        return true;
      } else if (response.statusCode == 429) {
        // Limit reached
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  void clearCache() {
    _cachedUsageData = null;
    _lastFetchTime = null;
  }
}
