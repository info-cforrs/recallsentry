import 'google_sheets_service.dart';
import 'api_service.dart';
import '../models/recall_data.dart';
import '../config/app_config.dart';
import '../exceptions/api_exceptions.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecallDataService {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final ApiService _apiService = ApiService();
  static final RecallDataService _instance = RecallDataService._internal();
  factory RecallDataService() => _instance;
  RecallDataService._internal();

  List<RecallData> _cachedRecalls = [];
  List<RecallData> _cachedFdaRecalls = [];
  List<RecallData> _cachedUsdaRecalls = [];
  DateTime? _lastFetch;
  DateTime? _lastFdaFetch;
  DateTime? _lastUsdaFetch;
  String? _currentSpreadsheetId;

  // Default spreadsheet ID - users can override this
  static String _defaultSpreadsheetId = 'your_default_spreadsheet_id_here';

  // Method to configure the default spreadsheet ID
  static void configureSpreadsheetId(String spreadsheetId) {
    _defaultSpreadsheetId = spreadsheetId;
  }

  Future<List<RecallData>> getRecalls({
    bool forceRefresh = false,
    String? spreadsheetId,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        // Check memory cache first (30 minutes)
        if (!forceRefresh &&
            _lastFetch != null &&
            DateTime.now().difference(_lastFetch!).inMinutes < 30 &&
            _cachedRecalls.isNotEmpty) {
          return _cachedRecalls;
        }

        // Try persistent cache if memory cache expired (24 hours)
        if (!forceRefresh) {
          final persistentData = await _loadFromPersistentCache('all_recalls');
          if (persistentData != null) {
            _cachedRecalls = persistentData;
            _lastFetch = DateTime.now();
            return _cachedRecalls;
          }
        }

        // Fetch from API
        final apiRecalls = await _apiService.fetchAllRecalls();

        // Save to both caches
        _cachedRecalls = apiRecalls;
        _lastFetch = DateTime.now();
        await _saveToPersistentCache('all_recalls', apiRecalls);

        return _cachedRecalls;
      } on ApiException {
        // On API error, try to return cached data
        final cachedData = await _loadFromPersistentCache('all_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData;
        }
        // If no cache available, rethrow the API exception
        rethrow;
      } catch (e, stack) {
        // On other errors, try to return cached data
        final cachedData = await _loadFromPersistentCache('all_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          return cachedData;
        }
        // Wrap in ApiException
        throw ApiException(
          'Failed to fetch recalls',
          originalException: e,
          stackTrace: stack,
        );
      }
    }

    // Fall back to Google Sheets

    // Use provided spreadsheet ID, or app config, or default
    final targetSpreadsheetId =
        spreadsheetId ??
        (AppConfig.isGoogleSheetsConfigured
            ? AppConfig.googleSheetsSpreadsheetId
            : _defaultSpreadsheetId);


    if (targetSpreadsheetId != 'your_default_spreadsheet_id_here' &&
        AppConfig.isGoogleSheetsConfigured) {

      try {
        // Initialize service if spreadsheet ID is provided and different
        if (targetSpreadsheetId != _currentSpreadsheetId) {
          await _sheetsService.init(targetSpreadsheetId);
          _currentSpreadsheetId = targetSpreadsheetId;
          forceRefresh = true;
        }

        // Cache for 30 minutes
        if (!forceRefresh &&
            _lastFetch != null &&
            DateTime.now().difference(_lastFetch!).inMinutes < 30) {
          return _cachedRecalls;
        }

        if (!_sheetsService.isInitialized) {
          throw Exception(
            'Google Sheets service not initialized. Please provide a spreadsheet ID.',
          );
        }

        final sheetsRecalls = await _sheetsService.fetchRecalls();

        if (sheetsRecalls.isNotEmpty) {
          _cachedRecalls = sheetsRecalls;
          _lastFetch = DateTime.now();
          return _cachedRecalls;
        } else {
          return [];
        }
      } catch (e) {
        return [];
      }
    } else {
      // No valid spreadsheet ID configured
      return [];
    }
  }

  // Get FDA-specific recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getFdaRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          final fdaRecalls = await _apiService.fetchFdaRecalls(
            limit: limit,
            offset: offset,
          );
          return fdaRecalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastFdaFetch != null &&
            DateTime.now().difference(_lastFdaFetch!).inMinutes < 30) {
          return _cachedFdaRecalls;
        }

        final fdaRecalls = await _apiService.fetchFdaRecalls();

        _cachedFdaRecalls = fdaRecalls;
        _lastFdaFetch = DateTime.now();
        return _cachedFdaRecalls;
      } catch (e) {
        return [];
      }
    }

    // Fall back to Google Sheets
    if (!AppConfig.isFdaSpreadsheetConfigured) {
      return [];
    }

    try {
      // Cache for 30 minutes
      if (!forceRefresh &&
          _lastFdaFetch != null &&
          DateTime.now().difference(_lastFdaFetch!).inMinutes < 30) {
        return _cachedFdaRecalls;
      }

      await _sheetsService.init(AppConfig.fdaRecallsSpreadsheetId);
      final fdaRecalls = await _sheetsService.fetchRecalls();

      if (fdaRecalls.isNotEmpty) {
        _cachedFdaRecalls = fdaRecalls;
        _lastFdaFetch = DateTime.now();
        return _cachedFdaRecalls;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get USDA-specific recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getUsdaRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          final usdaRecalls = await _apiService.fetchUsdaRecalls(
            limit: limit,
            offset: offset,
          );
          return usdaRecalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastUsdaFetch != null &&
            DateTime.now().difference(_lastUsdaFetch!).inMinutes < 30) {
          return _cachedUsdaRecalls;
        }

        final usdaRecalls = await _apiService.fetchUsdaRecalls();

        _cachedUsdaRecalls = usdaRecalls;
        _lastUsdaFetch = DateTime.now();
        return _cachedUsdaRecalls;
      } catch (e) {
        return [];
      }
    }

    // Fall back to Google Sheets
    if (!AppConfig.isUsdaSpreadsheetConfigured) {
      return [];
    }

    try {
      // Cache for 30 minutes
      if (!forceRefresh &&
          _lastUsdaFetch != null &&
          DateTime.now().difference(_lastUsdaFetch!).inMinutes < 30) {
        return _cachedUsdaRecalls;
      }

      await _sheetsService.init(AppConfig.usdaRecallsSpreadsheetId);
      final usdaRecalls = await _sheetsService.fetchRecalls();

      if (usdaRecalls.isNotEmpty) {
        _cachedUsdaRecalls = usdaRecalls;
        _lastUsdaFetch = DateTime.now();
        return _cachedUsdaRecalls;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<RecallData>> getFilteredRecalls({
    List<String>? brands,
    List<String>? productNames,
    String? agency,
    String? riskLevel,
    String? spreadsheetId,
  }) async {
    List<RecallData> allRecalls = [];

    // If a specific agency is requested, use the dedicated spreadsheet
    if (agency != null) {
      switch (agency.toUpperCase()) {
        case 'FDA':
          allRecalls = await getFdaRecalls(forceRefresh: true);
          break;
        case 'USDA':
          allRecalls = await getUsdaRecalls(forceRefresh: true);
          break;
        default:
          // Fall back to main spreadsheet for other agencies
          allRecalls = await getRecalls(spreadsheetId: spreadsheetId);
      }
    } else {
      // No specific agency requested, get from main spreadsheet
      allRecalls = await getRecalls(spreadsheetId: spreadsheetId);
    }

    final filteredRecalls = allRecalls.where((recall) {
      if (brands != null && brands.isNotEmpty) {
        if (!brands.any(
          (brand) =>
              recall.brandName.toLowerCase().contains(brand.toLowerCase()),
        )) {
          return false;
        }
      }

      if (productNames != null && productNames.isNotEmpty) {
        if (!productNames.any(
          (product) =>
              recall.productName.toLowerCase().contains(product.toLowerCase()),
        )) {
          return false;
        }
      }

      if (agency != null) {
        final agencyMatches =
            recall.agency.toUpperCase() == agency.toUpperCase();
        if (!agencyMatches) {
          return false;
        }
      }

      if (riskLevel != null && recall.riskLevel != riskLevel) {
        return false;
      }

      return true;
    }).toList();

    return filteredRecalls;
  }

  // Add a recall to the spreadsheet
  Future<void> addRecall(RecallData recall) async {
    if (!_sheetsService.isInitialized) {
      throw Exception('Google Sheets service not initialized.');
    }
    await _sheetsService.addRecall(recall);
    // Invalidate cache to force refresh on next fetch
    _lastFetch = null;
  }

  // Get a single recall by ID
  Future<RecallData?> getRecallById(String recallId) async {

    // Try to parse as integer for API call
    final id = int.tryParse(recallId);
    if (id == null) {
      return null;
    }

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        final recall = await _apiService.fetchRecallById(id);
        return recall;
      } catch (e) {
        return null;
      }
    }

    // Fall back to searching in cached recalls

    // First try to get from cached recalls
    final allRecalls = await getRecalls();
    try {
      final recall = allRecalls.firstWhere((r) => r.id == recallId);
      return recall;
    } catch (e) {
      return null;
    }
  }

  // Check if service is ready
  bool get isInitialized => _sheetsService.isInitialized;

  /// Save recalls to persistent cache using Hive
  /// PERFORMANCE: Provides offline support and faster app restarts
  /// OPTIMIZATION: Implements cache size management with LRU eviction
  Future<void> _saveToPersistentCache(String key, List<RecallData> recalls) async {
    try {
      final box = await Hive.openBox('recallsCache');
      await box.put(key, {
        'data': recalls.map((r) => r.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accessCount': 0,
        'lastAccess': DateTime.now().millisecondsSinceEpoch,
      });

      // Manage cache size after saving
      await _manageCacheSize(box);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Manage cache size with LRU (Least Recently Used) eviction
  /// maxCacheSizeMb: 100 MB to prevent excessive storage usage
  static const int maxCacheSizeMb = 100;
  static const int maxCacheAgeDays = 30;

  Future<void> _manageCacheSize(Box box) async {
    try {
      // Calculate approximate cache size
      int totalSize = 0;
      final Map<String, int> keySizes = {};
      final Map<String, int> keyAccessTimes = {};

      for (var key in box.keys) {
        final cached = box.get(key);
        if (cached != null && cached is Map) {
          final data = cached['data'] as List?;
          if (data != null) {
            // Approximate size: each recall ~2KB
            final size = data.length * 2 * 1024; // 2KB per recall
            totalSize += size;
            keySizes[key.toString()] = size;
            keyAccessTimes[key.toString()] = cached['lastAccess'] ?? 0;
          }
        }
      }

      final maxSizeBytes = maxCacheSizeMb * 1024 * 1024;

      // If cache exceeds limit, remove oldest entries
      if (totalSize > maxSizeBytes) {
        // Sort keys by last access time (oldest first)
        final sortedKeys = keyAccessTimes.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        int removedSize = 0;
        for (var entry in sortedKeys) {
          if (totalSize - removedSize <= maxSizeBytes) {
            break;
          }
          await box.delete(entry.key);
          removedSize += keySizes[entry.key] ?? 0;
        }
      }

      // Also remove entries older than 30 days
      final now = DateTime.now();
      for (var key in box.keys) {
        final cached = box.get(key);
        if (cached != null && cached is Map) {
          final timestamp = cached['timestamp'] as int?;
          if (timestamp != null) {
            final age = now.difference(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            ).inDays;
            if (age > maxCacheAgeDays) {
              await box.delete(key);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - cache management is not critical
    }
  }

  /// Load recalls from persistent cache
  /// PERFORMANCE: Returns null if cache expired (24 hours) or invalid
  /// LRU: Updates last access time for cache management
  Future<List<RecallData>?> _loadFromPersistentCache(String key) async {
    try {
      final box = await Hive.openBox('recallsCache');
      final cached = box.get(key);

      if (cached == null) return null;

      final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp']);
      // Cache valid for 24 hours
      if (DateTime.now().difference(timestamp).inHours > 24) {
        return null;
      }

      final data = (cached['data'] as List)
          .map((json) => RecallData.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update access tracking for LRU eviction
      final accessCount = (cached['accessCount'] as int? ?? 0) + 1;
      await box.put(key, {
        'data': cached['data'],
        'timestamp': cached['timestamp'],
        'accessCount': accessCount,
        'lastAccess': DateTime.now().millisecondsSinceEpoch,
      });

      return data;
    } catch (e) {
      return null;
    }
  }
}
