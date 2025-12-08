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
  List<RecallData> _cachedCpscRecalls = [];
  List<RecallData> _cachedNhtsaVehicleRecalls = [];
  List<RecallData> _cachedNhtsaTireRecalls = [];
  List<RecallData> _cachedNhtsaChildSeatRecalls = [];
  DateTime? _lastFetch;
  DateTime? _lastFdaFetch;
  DateTime? _lastUsdaFetch;
  DateTime? _lastCpscFetch;
  DateTime? _lastNhtsaVehicleFetch;
  DateTime? _lastNhtsaTireFetch;
  DateTime? _lastNhtsaChildSeatFetch;
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
        print('🔵 Starting FDA recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final fdaRecalls = await _apiService.fetchFdaRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ FDA recalls fetched successfully (paginated): ${fdaRecalls.length} items');
          return fdaRecalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastFdaFetch != null &&
            DateTime.now().difference(_lastFdaFetch!).inMinutes < 30) {
          print('📦 Returning cached FDA recalls: ${_cachedFdaRecalls.length} items');
          return _cachedFdaRecalls;
        }

        print('🌐 Fetching FDA recalls from API...');
        final fdaRecalls = await _apiService.fetchFdaRecalls();
        print('✅ FDA recalls fetched successfully: ${fdaRecalls.length} items');

        _cachedFdaRecalls = fdaRecalls;
        _lastFdaFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('fda_recalls', fdaRecalls);
        return _cachedFdaRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching FDA recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('fda_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached FDA recalls');
          _cachedFdaRecalls = cachedData;
          _lastFdaFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached FDA data available, returning empty list');
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
        print('🔵 Starting USDA recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final usdaRecalls = await _apiService.fetchUsdaRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ USDA recalls fetched successfully (paginated): ${usdaRecalls.length} items');
          return usdaRecalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastUsdaFetch != null &&
            DateTime.now().difference(_lastUsdaFetch!).inMinutes < 30) {
          print('📦 Returning cached USDA recalls: ${_cachedUsdaRecalls.length} items');
          return _cachedUsdaRecalls;
        }

        print('🌐 Fetching USDA recalls from API...');
        final usdaRecalls = await _apiService.fetchUsdaRecalls();
        print('✅ USDA recalls fetched successfully: ${usdaRecalls.length} items');

        _cachedUsdaRecalls = usdaRecalls;
        _lastUsdaFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('usda_recalls', usdaRecalls);
        return _cachedUsdaRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching USDA recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('usda_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached USDA recalls');
          _cachedUsdaRecalls = cachedData;
          _lastUsdaFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached USDA data available, returning empty list');
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

  // Get CPSC-specific recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getCpscRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        print('🔵 Starting CPSC recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final cpscRecalls = await _apiService.fetchCpscRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ CPSC recalls fetched successfully (paginated): ${cpscRecalls.length} items');
          return cpscRecalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastCpscFetch != null &&
            DateTime.now().difference(_lastCpscFetch!).inMinutes < 30) {
          print('📦 Returning cached CPSC recalls: ${_cachedCpscRecalls.length} items');
          return _cachedCpscRecalls;
        }

        print('🌐 Fetching CPSC recalls from API...');
        final cpscRecalls = await _apiService.fetchCpscRecalls();
        print('✅ CPSC recalls fetched successfully: ${cpscRecalls.length} items');

        _cachedCpscRecalls = cpscRecalls;
        _lastCpscFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('cpsc_recalls', cpscRecalls);
        return _cachedCpscRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching CPSC recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('cpsc_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached CPSC recalls');
          _cachedCpscRecalls = cachedData;
          _lastCpscFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached CPSC data available, returning empty list');
        return [];
      }
    }

    // No Google Sheets fallback for CPSC
    return [];
  }

  // Get NHTSA Vehicle recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getNhtsaVehicleRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        print('🔵 Starting NHTSA Vehicle recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final recalls = await _apiService.fetchNhtsaVehicleRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ NHTSA Vehicle recalls fetched successfully (paginated): ${recalls.length} items');
          return recalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastNhtsaVehicleFetch != null &&
            DateTime.now().difference(_lastNhtsaVehicleFetch!).inMinutes < 30) {
          print('📦 Returning cached NHTSA Vehicle recalls: ${_cachedNhtsaVehicleRecalls.length} items');
          return _cachedNhtsaVehicleRecalls;
        }

        print('🌐 Fetching NHTSA Vehicle recalls from API...');
        final recalls = await _apiService.fetchNhtsaVehicleRecalls();
        print('✅ NHTSA Vehicle recalls fetched successfully: ${recalls.length} items');

        _cachedNhtsaVehicleRecalls = recalls;
        _lastNhtsaVehicleFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('nhtsa_vehicle_recalls', recalls);
        return _cachedNhtsaVehicleRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching NHTSA Vehicle recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('nhtsa_vehicle_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached NHTSA Vehicle recalls');
          _cachedNhtsaVehicleRecalls = cachedData;
          _lastNhtsaVehicleFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached NHTSA Vehicle data available, returning empty list');
        return [];
      }
    }

    // No Google Sheets fallback for NHTSA
    return [];
  }

  // Get NHTSA Tire recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getNhtsaTireRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        print('🔵 Starting NHTSA Tire recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final recalls = await _apiService.fetchNhtsaTireRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ NHTSA Tire recalls fetched successfully (paginated): ${recalls.length} items');
          return recalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastNhtsaTireFetch != null &&
            DateTime.now().difference(_lastNhtsaTireFetch!).inMinutes < 30) {
          print('📦 Returning cached NHTSA Tire recalls: ${_cachedNhtsaTireRecalls.length} items');
          return _cachedNhtsaTireRecalls;
        }

        print('🌐 Fetching NHTSA Tire recalls from API...');
        final recalls = await _apiService.fetchNhtsaTireRecalls();
        print('✅ NHTSA Tire recalls fetched successfully: ${recalls.length} items');

        _cachedNhtsaTireRecalls = recalls;
        _lastNhtsaTireFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('nhtsa_tire_recalls', recalls);
        return _cachedNhtsaTireRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching NHTSA Tire recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('nhtsa_tire_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached NHTSA Tire recalls');
          _cachedNhtsaTireRecalls = cachedData;
          _lastNhtsaTireFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached NHTSA Tire data available, returning empty list');
        return [];
      }
    }

    // No Google Sheets fallback for NHTSA
    return [];
  }

  // Get NHTSA Child Seat recalls
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> getNhtsaChildSeatRecalls({
    bool forceRefresh = false,
    int? limit,
    int? offset,
  }) async {

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {

      try {
        print('🔵 Starting NHTSA Child Seat recalls fetch from REST API...');

        // If pagination is requested, skip cache and fetch from API
        if (limit != null || offset != null) {
          print('📄 Pagination requested: limit=$limit, offset=$offset');
          final recalls = await _apiService.fetchNhtsaChildSeatRecalls(
            limit: limit,
            offset: offset,
          );
          print('✅ NHTSA Child Seat recalls fetched successfully (paginated): ${recalls.length} items');
          return recalls;
        }

        // Cache for 30 minutes (only for non-paginated requests)
        if (!forceRefresh &&
            _lastNhtsaChildSeatFetch != null &&
            DateTime.now().difference(_lastNhtsaChildSeatFetch!).inMinutes < 30) {
          print('📦 Returning cached NHTSA Child Seat recalls: ${_cachedNhtsaChildSeatRecalls.length} items');
          return _cachedNhtsaChildSeatRecalls;
        }

        print('🌐 Fetching NHTSA Child Seat recalls from API...');
        final recalls = await _apiService.fetchNhtsaChildSeatRecalls();
        print('✅ NHTSA Child Seat recalls fetched successfully: ${recalls.length} items');

        _cachedNhtsaChildSeatRecalls = recalls;
        _lastNhtsaChildSeatFetch = DateTime.now();
        // Save to persistent cache
        await _saveToPersistentCache('nhtsa_child_seat_recalls', recalls);
        return _cachedNhtsaChildSeatRecalls;
      } catch (e, stackTrace) {
        print('❌ ERROR fetching NHTSA Child Seat recalls from API: $e');
        print('Stack trace: $stackTrace');

        // Try persistent cache as fallback
        final cachedData = await _loadFromPersistentCache('nhtsa_child_seat_recalls');
        if (cachedData != null && cachedData.isNotEmpty) {
          print('✅ Returning ${cachedData.length} cached NHTSA Child Seat recalls');
          _cachedNhtsaChildSeatRecalls = cachedData;
          _lastNhtsaChildSeatFetch = DateTime.now();
          return cachedData;
        }

        print('⚠️ No cached NHTSA Child Seat data available, returning empty list');
        return [];
      }
    }

    // No Google Sheets fallback for NHTSA
    return [];
  }

  Future<List<RecallData>> getFilteredRecalls({
    List<String>? brands,
    List<String>? productNames,
    String? agency,
    String? riskLevel,
    String? spreadsheetId,
  }) async {
    List<RecallData> allRecalls = [];

    // If a specific agency is requested, use the dedicated endpoint
    if (agency != null) {
      switch (agency.toUpperCase()) {
        case 'FDA':
          allRecalls = await getFdaRecalls(forceRefresh: true);
          break;
        case 'USDA':
          allRecalls = await getUsdaRecalls(forceRefresh: true);
          break;
        case 'CPSC':
          allRecalls = await getCpscRecalls(forceRefresh: true);
          break;
        default:
          // Fall back to main endpoint for other agencies
          allRecalls = await getRecalls(spreadsheetId: spreadsheetId);
      }
    } else {
      // No specific agency requested, get all recalls
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
