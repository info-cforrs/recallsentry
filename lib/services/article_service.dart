import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/article.dart';

class ArticleService {
  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Fetch articles filtered by tag (FDA, USDA, CPSC, NHTSA)
  /// Only returns articles from last 3 months
  Future<List<Article>> getArticles({String? tag}) async {
    try {
      final uri = Uri.parse('$_baseUrl/articles/').replace(
        queryParameters: tag != null ? {'tag': tag} : null,
      );

      print('📰 ArticleService: Fetching articles${tag != null ? " for tag: $tag" : ""}');
      print('   URL: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
        final articles = jsonList.map((json) => Article.fromJson(json as Map<String, dynamic>)).toList();

        print('   ✅ Fetched ${articles.length} articles');
        return articles;
      } else {
        print('   ❌ Failed to fetch articles: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('   ❌ Error fetching articles: $e');
      return [];
    }
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
