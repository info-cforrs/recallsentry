import 'google_sheets_service.dart';
import 'api_service.dart';
import '../models/recall_data.dart';
import '../config/app_config.dart';

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
    print('🔍 RecallDataService.getRecalls() called');
    print('📊 Data source: ${AppConfig.dataSource}');

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {
      print('✅ Using REST API data source');

      try {
        // Cache for 30 minutes
        if (!forceRefresh &&
            _lastFetch != null &&
            DateTime.now().difference(_lastFetch!).inMinutes < 30) {
          print('📦 Using cached API data (${_cachedRecalls.length} recalls)');
          return _cachedRecalls;
        }

        print('🔽 Fetching recalls from REST API...');
        final apiRecalls = await _apiService.fetchAllRecalls();

        _cachedRecalls = apiRecalls;
        _lastFetch = DateTime.now();
        print('✅ Successfully fetched ${_cachedRecalls.length} recalls from API');
        return _cachedRecalls;
      } catch (e) {
        print('❌ Error fetching recalls from API: $e');
        return [];
      }
    }

    // Fall back to Google Sheets
    print('📊 Using Google Sheets data source');

    // Use provided spreadsheet ID, or app config, or default
    final targetSpreadsheetId =
        spreadsheetId ??
        (AppConfig.isGoogleSheetsConfigured
            ? AppConfig.googleSheetsSpreadsheetId
            : _defaultSpreadsheetId);

    print('📊 Target spreadsheet ID: $targetSpreadsheetId');

    if (targetSpreadsheetId != 'your_default_spreadsheet_id_here' &&
        AppConfig.isGoogleSheetsConfigured) {
      print('✅ Valid spreadsheet ID found, proceeding with Google Sheets');

      try {
        // Initialize service if spreadsheet ID is provided and different
        if (targetSpreadsheetId != _currentSpreadsheetId) {
          print('🔄 Initializing Google Sheets service...');
          await _sheetsService.init(targetSpreadsheetId);
          _currentSpreadsheetId = targetSpreadsheetId;
          forceRefresh = true;
          print('✅ Google Sheets service initialized successfully!');
        }

        // Cache for 30 minutes
        if (!forceRefresh &&
            _lastFetch != null &&
            DateTime.now().difference(_lastFetch!).inMinutes < 30) {
          print('📦 Using cached data (${_cachedRecalls.length} recalls)');
          return _cachedRecalls;
        }

        if (!_sheetsService.isInitialized) {
          throw Exception(
            'Google Sheets service not initialized. Please provide a spreadsheet ID.',
          );
        }

        print('🔽 Fetching recalls from Google Sheets...');
        final sheetsRecalls = await _sheetsService.fetchRecalls();

        if (sheetsRecalls.isNotEmpty) {
          _cachedRecalls = sheetsRecalls;
          _lastFetch = DateTime.now();
          print(
            '✅ Successfully fetched ${_cachedRecalls.length} recalls from Google Sheets',
          );
          return _cachedRecalls;
        } else {
          print('⚠️ Google Sheets returned empty data');
          return [];
        }
      } catch (e) {
        print('❌ Error fetching recalls from Google Sheets: $e');
        return [];
      }
    } else {
      // No valid spreadsheet ID configured
      print('⚠️ No spreadsheet ID configured in AppConfig.');
      return [];
    }
  }

  // Get FDA-specific recalls
  Future<List<RecallData>> getFdaRecalls({bool forceRefresh = false}) async {
    print('🔍 RecallDataService.getFdaRecalls() called');

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {
      print('✅ Using REST API for FDA recalls');

      try {
        // Cache for 30 minutes
        if (!forceRefresh &&
            _lastFdaFetch != null &&
            DateTime.now().difference(_lastFdaFetch!).inMinutes < 30) {
          print('📦 Using cached FDA API data (${_cachedFdaRecalls.length} recalls)');
          return _cachedFdaRecalls;
        }

        print('🔽 Fetching FDA recalls from REST API...');
        final fdaRecalls = await _apiService.fetchFdaRecalls();

        _cachedFdaRecalls = fdaRecalls;
        _lastFdaFetch = DateTime.now();
        print('✅ Successfully fetched ${_cachedFdaRecalls.length} FDA recalls from API');
        return _cachedFdaRecalls;
      } catch (e) {
        print('❌ Error fetching FDA recalls from API: $e');
        return [];
      }
    }

    // Fall back to Google Sheets
    if (!AppConfig.isFdaSpreadsheetConfigured) {
      print('⚠️ FDA spreadsheet not configured');
      return [];
    }

    try {
      // Cache for 30 minutes
      if (!forceRefresh &&
          _lastFdaFetch != null &&
          DateTime.now().difference(_lastFdaFetch!).inMinutes < 30) {
        print('📦 Using cached FDA data (${_cachedFdaRecalls.length} recalls)');
        return _cachedFdaRecalls;
      }

      print('🔽 Fetching FDA recalls from Google Sheets...');
      await _sheetsService.init(AppConfig.fdaRecallsSpreadsheetId);
      final fdaRecalls = await _sheetsService.fetchRecalls();

      if (fdaRecalls.isNotEmpty) {
        _cachedFdaRecalls = fdaRecalls;
        _lastFdaFetch = DateTime.now();
        print('✅ Successfully fetched ${_cachedFdaRecalls.length} FDA recalls');
        return _cachedFdaRecalls;
      } else {
        print('⚠️ FDA spreadsheet returned empty data');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching FDA recalls: $e');
      return [];
    }
  }

  // Get USDA-specific recalls
  Future<List<RecallData>> getUsdaRecalls({bool forceRefresh = false}) async {
    print('🔍 RecallDataService.getUsdaRecalls() called');

    // Use REST API if configured
    if (AppConfig.dataSource == DataSource.restApi && AppConfig.isRestApiConfigured) {
      print('✅ Using REST API for USDA recalls');

      try {
        // Cache for 30 minutes
        if (!forceRefresh &&
            _lastUsdaFetch != null &&
            DateTime.now().difference(_lastUsdaFetch!).inMinutes < 30) {
          print('📦 Using cached USDA API data (${_cachedUsdaRecalls.length} recalls)');
          return _cachedUsdaRecalls;
        }

        print('🔽 Fetching USDA recalls from REST API...');
        final usdaRecalls = await _apiService.fetchUsdaRecalls();

        _cachedUsdaRecalls = usdaRecalls;
        _lastUsdaFetch = DateTime.now();
        print('✅ Successfully fetched ${_cachedUsdaRecalls.length} USDA recalls from API');
        return _cachedUsdaRecalls;
      } catch (e) {
        print('❌ Error fetching USDA recalls from API: $e');
        return [];
      }
    }

    // Fall back to Google Sheets
    if (!AppConfig.isUsdaSpreadsheetConfigured) {
      print('⚠️ USDA spreadsheet not configured');
      return [];
    }

    try {
      // Cache for 30 minutes
      if (!forceRefresh &&
          _lastUsdaFetch != null &&
          DateTime.now().difference(_lastUsdaFetch!).inMinutes < 30) {
        print(
          '📦 Using cached USDA data (${_cachedUsdaRecalls.length} recalls)',
        );
        return _cachedUsdaRecalls;
      }

      print('🔽 Fetching USDA recalls from Google Sheets...');
      await _sheetsService.init(AppConfig.usdaRecallsSpreadsheetId);
      final usdaRecalls = await _sheetsService.fetchRecalls();

      if (usdaRecalls.isNotEmpty) {
        _cachedUsdaRecalls = usdaRecalls;
        _lastUsdaFetch = DateTime.now();
        print(
          '✅ Successfully fetched ${_cachedUsdaRecalls.length} USDA recalls',
        );
        return _cachedUsdaRecalls;
      } else {
        print('⚠️ USDA spreadsheet returned empty data');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching USDA recalls: $e');
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

    print('RecallDataService: Total recalls fetched: ${allRecalls.length}');

    if (agency != null) {
      print('RecallDataService: Filtering for agency: "$agency"');
      // Print all available agencies for debugging
      final allAgencies = allRecalls.map((r) => '"${r.agency}"').toSet();
      print('RecallDataService: All agencies in data: $allAgencies');
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
        print(
          'RecallDataService: Recall "${recall.productName}" agency "${recall.agency}" matches "$agency": $agencyMatches',
        );
        if (!agencyMatches) {
          return false;
        }
      }

      if (riskLevel != null && recall.riskLevel != riskLevel) {
        return false;
      }

      return true;
    }).toList();

    print(
      'RecallDataService: Filtered results: ${filteredRecalls.length} recalls',
    );
    for (var recall in filteredRecalls) {
      print(
        'Filtered Recall: ${recall.id} - ${recall.productName} - Agency: ${recall.agency}',
      );
    }

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

  // Check if service is ready
  bool get isInitialized => _sheetsService.isInitialized;
}
