import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/article.dart';
import '../exceptions/api_exceptions.dart';
import '../utils/api_utils.dart';
import 'security_service.dart';

class ArticleService {
  // Singleton pattern - ensures all ArticleService() calls return the same instance
  // IMPORTANT: This ensures the article cache is shared across the app
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;

  final String _baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  ArticleService._internal() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  // Cache for articles
  // OPTIMIZATION: Extended from 1 to 12 hours since article content changes infrequently
  final Map<String, List<Article>> _cachedArticles = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 12);

  /// Fetch articles filtered by tag (FDA, USDA, CPSC, NHTSA)
  /// Only returns articles from last 3 months
  /// OPTIMIZATION: Cached for 1 hour to reduce API calls
  Future<List<Article>> getArticles({String? tag, bool forceRefresh = false}) async {
    final cacheKey = tag ?? 'all';

    // Return cached data if available and not expired
    if (!forceRefresh &&
        _cachedArticles.containsKey(cacheKey) &&
        _cacheTimestamps[cacheKey] != null &&
        DateTime.now().difference(_cacheTimestamps[cacheKey]!) < _cacheDuration) {
      return _cachedArticles[cacheKey]!;
    }

    try {
      final uri = Uri.parse('$_baseUrl/articles/').replace(
        queryParameters: tag != null ? {'tag': tag} : null,
      );

      final response = await _httpClient.get(uri);

      // Use ApiUtils for response checking and parsing
      ApiUtils.checkResponse(response, context: 'Fetch articles');

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      final articles = jsonList.map((json) => Article.fromJson(json as Map<String, dynamic>)).toList();

      // Cache the results
      _cachedArticles[cacheKey] = articles;
      _cacheTimestamps[cacheKey] = DateTime.now();

      return articles;
    } on ApiException {
      // On API error, return cached data if available
      if (_cachedArticles.containsKey(cacheKey)) {
        // Log that we're using stale cache (in production, use proper logging)
        return _cachedArticles[cacheKey]!;
      }
      // If no cache available, rethrow the exception
      rethrow;
    } catch (e, stack) {
      // On other errors, return cached data if available
      if (_cachedArticles.containsKey(cacheKey)) {
        return _cachedArticles[cacheKey]!;
      }
      // Wrap in ApiException if no cache available
      throw ApiException(
        'Failed to fetch articles',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Clear all cached articles
  void clearCache() {
    _cachedArticles.clear();
    _cacheTimestamps.clear();
  }

  /// Fetch FDA articles (last 3 months)
  Future<List<Article>> getFdaArticles() async {
    return getArticles(tag: 'FDA');
  }

  /// Fetch USDA articles (last 3 months)
  Future<List<Article>> getUsdaArticles() async {
    return getArticles(tag: 'USDA');
  }

  /// Fetch CPSC articles (last 3 months)
  Future<List<Article>> getCpscArticles() async {
    return getArticles(tag: 'CPSC');
  }

  /// Fetch NHTSA articles (last 3 months)
  Future<List<Article>> getNhtsaArticles() async {
    return getArticles(tag: 'NHTSA');
  }
}
