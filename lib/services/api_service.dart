import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/recall_data.dart';
import '../models/recommended_product.dart';
import '../models/rmc_enrollment.dart';
import '../config/app_config.dart';
import '../constants/rmc_status.dart';
import '../exceptions/api_exceptions.dart';
import '../utils/api_utils.dart';
import 'auth_service.dart';
import 'security_service.dart';
import 'error_logger.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  late final http.Client _httpClient;

  ApiService() {
    _httpClient = SecurityService().createSecureHttpClient();
  }

  // Default timeout for API requests
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Wraps HTTP requests with timeout and error logging
  Future<T> _withTimeout<T>(
    Future<T> Function() operation, {
    Duration? timeout,
    String? context,
  }) async {
    try {
      return await operation().timeout(
        timeout ?? _defaultTimeout,
        onTimeout: () {
          final error = NetworkException(
            'Request timeout after ${(timeout ?? _defaultTimeout).inSeconds} seconds',
          );
          ErrorLogger.log(
            message: 'Request timeout',
            service: 'ApiService',
            method: context,
            error: error,
            reportToAnalytics: true,
          );
          throw error;
        },
      );
    } catch (e, stack) {
      // Log error if it's not already an ApiException (those are logged at a higher level)
      if (e is! ApiException) {
        ErrorLogger.log(
          message: 'API request failed',
          service: 'ApiService',
          method: context,
          error: e,
          stackTrace: stack,
          reportToAnalytics: true,
        );
      }
      rethrow;
    }
  }

  /// Fetch all recalls from the API
  Future<List<RecallData>> fetchAllRecalls({
    int? limit,
    int? offset,
    String? search,
    String? agency,
    String? riskLevel,
    String? category,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (agency != null && agency.isNotEmpty) queryParams['agency'] = agency;
      if (riskLevel != null && riskLevel.isNotEmpty) {
        queryParams['risk_level'] = riskLevel;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse(
        '$baseUrl${AppConfig.apiRecallsEndpoint}',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(uri);

      // Check response status and throw appropriate exceptions
      ApiUtils.checkResponse(response, context: 'Fetch all recalls');

      // Parse response using utility
      final results = ApiUtils.parseJsonList(response.body);

      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch FDA recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchFdaRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiFdaEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch FDA recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch FDA recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch USDA recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchUsdaRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiUsdaEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch USDA recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch USDA recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch CPSC recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchCpscRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiCpscEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch CPSC recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch CPSC recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch NHTSA vehicle recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchNhtsaVehicleRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiNhtsaVehiclesEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch NHTSA vehicle recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch NHTSA vehicle recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch NHTSA tire recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchNhtsaTireRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiNhtsaTiresEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch NHTSA tire recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch NHTSA tire recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch NHTSA child seat recalls only
  /// PAGINATION: Supports limit and offset for infinite scroll
  Future<List<RecallData>> fetchNhtsaChildSeatRecalls({
    int? limit,
    int? offset,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl${AppConfig.apiNhtsaChildSeatsEndpoint}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch NHTSA child seat recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch NHTSA child seat recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch recalls with active resolution status (not 'Not Started')
  Future<List<RecallData>> fetchActiveRecalls() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiRecallsEndpoint}active_recalls/');
      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch active recalls');

      final results = ApiUtils.parseJsonList(response.body);
      return results
          .map((json) => _convertFromApi(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch active recalls',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch a single recall by ID
  Future<RecallData> fetchRecallById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiRecallsEndpoint}$id/');
      final response = await _httpClient.get(uri);
      ApiUtils.checkResponse(response, context: 'Fetch recall by ID');

      final jsonData = ApiUtils.parseJsonMap(response.body);
      return _convertFromApi(jsonData);
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch recall $id',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Fetch API statistics
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiStatsEndpoint}');

      final response = await _httpClient.get(uri);

      // Check response status and throw appropriate exceptions
      ApiUtils.checkResponse(response, context: 'Fetch stats');

      final jsonData = json.decode(response.body);
      return jsonData as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      throw ApiException(
        'Failed to fetch stats',
        originalException: e,
        stackTrace: stack,
      );
    }
  }

  /// Convert API JSON response to RecallData model
  RecallData _convertFromApi(Map<String, dynamic> json) {
    // The recall_id field contains the actual FDA/USDA recall ID
    final recallId =
        json['recall_id']?.toString() ?? json['id']?.toString() ?? '';

    // Determine if it's FDA or USDA based on the recall_id prefix
    final isFda = recallId.startsWith('FDA');
    final isUsda = recallId.startsWith('USDA');

    // Debug logging

    return RecallData(
      // Use the recall_id as the main ID for Flutter app
      id: recallId,
      // Store the numeric database ID for API updates
      databaseId: json['id'] as int?,
      // Set FDA/USDA specific fields based on the recall type
      usdaRecallId: isUsda ? recallId : '',
      fdaRecallId: isFda ? recallId : '',
      fieldRecallNumber: json['field_recall_number']?.toString() ?? '',

      productName: json['product_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      riskLevel: json['risk_level']?.toString() ?? '',

      dateIssued: json['date_issued'] != null
          ? DateTime.parse(json['date_issued'])
          : DateTime.now(),

      agency: json['agency']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',

      recallReason: json['recall_reason']?.toString() ?? '',
      recallReasonShort: json['recall_reason_short']?.toString() ?? '',
      recallClassification: json['recall_classification']?.toString() ?? '',

      imageUrl: json['image_url']?.toString() ?? '',
      imageUrl2: json['image_url2']?.toString() ?? '',
      imageUrl3: json['image_url3']?.toString() ?? '',
      imageUrl4: json['image_url4']?.toString() ?? '',
      imageUrl5: json['image_url5']?.toString() ?? '',

      stateCount: json['state_count'] as int? ?? 0,
      negativeOutcomes: json['negative_outcomes']?.toString() ?? '',
      packagingDesc: json['packaging_desc']?.toString() ?? '',

      remedyReturn: (json['remedy_return'] as bool? ?? false) ? 'Y' : '',
      remedyRepair: (json['remedy_repair'] as bool? ?? false) ? 'Y' : '',
      remedyReplace: (json['remedy_replace'] as bool? ?? false) ? 'Y' : '',
      remedyDispose: (json['remedy_dispose'] as bool? ?? false) ? 'Y' : '',
      remedyNA: (json['remedy_na'] as bool? ?? false) ? 'Y' : '',

      productQty: json['product_qty']?.toString() ?? '',
      soldBy: json['sold_by']?.toString() ?? '',

      productionDateStart: json['production_date_start'] != null
          ? DateTime.tryParse(json['production_date_start'])
          : null,
      productionDateEnd: json['production_date_end'] != null
          ? DateTime.tryParse(json['production_date_end'])
          : null,

      bestUsedByDate: json['best_used_by_date']?.toString() ?? '',
      bestUsedByDateEnd: json['best_used_by_date_end']?.toString() ?? '',
      expDate: json['exp_date']?.toString() ?? '',
      batchLotCode: json['batch_lot_code']?.toString() ?? '',
      upc: json['upc']?.toString() ?? '',

      reportsOfInjury: json['reports_of_injury']?.toString() ?? '',
      distributionDateStart: json['distribution_date_start']?.toString() ?? '',
      distributionDateEnd: json['distribution_date_end']?.toString() ?? '',
      itemNumCode: json['item_num_code']?.toString() ?? '',
      firmContactForm: json['firm_contact_form']?.toString() ?? '',
      establishmentManufacturerContactForm:
          json['establishment_manufacturer_contact_form']?.toString() ?? '',
      distributor: json['distributor']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',

      recallUrl: json['recall_url']?.toString() ?? '',
      recallPhaReason: json['recall_pha_reason']?.toString() ?? '',
      productDistribution: json['distribution_pattern']?.toString() ?? '',
      adverseReactions: json['adverse_reactions']?.toString() ?? '',
      adverseReactionDetails:
          json['adverse_reaction_details']?.toString() ?? '',
      recommendationsActions: json['recommendations_actions']?.toString() ?? '',
      remedy: json['remedy']?.toString() ?? '',

      recallingFdaFirm: json['recalling_firm']?.toString() ?? '',
      firmContactName: json['firm_contact_name']?.toString() ?? '',
      firmContactPhone: json['firm_contact_phone']?.toString() ?? '',
      firmContactBusinessHoursDays:
          json['firm_contact_business_hours']?.toString() ?? '',
      firmContactEmail: json['firm_contact_email']?.toString() ?? '',
      firmContactWebSite: json['firm_contact_website']?.toString() ?? '',
      firmWebSiteInfo: json['firm_web_site_info']?.toString() ?? '',

      pressReleaseLink: json['press_release_link']?.toString() ?? '',
      productTypeDetail: json['product_type_detail']?.toString() ?? '',
      productSizeWeight: json['product_size_weight']?.toString() ?? '',
      howFound: json['how_found']?.toString() ?? '',
      distributionPattern: json['distribution_pattern']?.toString() ?? '',

      establishmentManufacturer: json['establishment_name']?.toString() ?? '',
      establishmentManufacturerContactName:
          json['establishment_manufacturer_contact_name']?.toString() ?? '',
      establishmentManufacturerContactPhone:
          json['establishment_manufacturer_contact_phone']?.toString() ?? '',
      establishmentManufacturerContactBusinessHoursDays:
          json['establishment_manufacturer_contact_business_hours_days']
              ?.toString() ??
          '',
      establishmentManufacturerContactEmail:
          json['establishment_manufacturer_contact_email']?.toString() ?? '',
      establishmentManufacturerWebsite:
          json['establishment_manufacturer_website']?.toString() ?? '',
      establishmentManufacturerWebsiteInfo:
          json['establishment_manufacturer_website_info']?.toString() ?? '',

      retailer1: json['retailer1']?.toString() ?? '',
      retailer1SaleDateStart:
          json['retailer1_sale_date_start']?.toString() ?? '',
      retailer1SaleDateEnd: json['retailer1_sale_date_end']?.toString() ?? '',
      retailer1ContactName: json['retailer1_contact_name']?.toString() ?? '',
      retailer1ContactPhone: json['retailer1_contact_phone']?.toString() ?? '',
      retailer1ContactBusinessHoursDays:
          json['retailer1_contact_business_hours_days']?.toString() ?? '',
      retailer1ContactEmail: json['retailer1_contact_email']?.toString() ?? '',
      retailer1ContactWebSite:
          json['retailer1_contact_web_site']?.toString() ?? '',
      retailer1WebSiteInfo: json['retailer1_web_site_info']?.toString() ?? '',
      estItemValue: json['est_item_value']?.toString() ?? '',

      usdaToReportAProblem: json['usda_to_report_a_problem']?.toString() ?? '',
      usdaFoodSafetyQuestionsPhone:
          json['usda_food_safety_questions_phone']?.toString() ?? '',
      usdaFoodSafetyQuestionsEmail:
          json['usda_food_safety_questions_email']?.toString() ?? '',

      packagedOnDate: json['packaged_on_date']?.toString() ?? '',
      sellByDate: json['sell_by_date']?.toString() ?? '',
      productIdentification: json['product_identification']?.toString() ?? '',

      // Parse recommendations
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((rec) => RecommendedProduct.fromJson(rec))
          .toList() ?? [],

      // Recall resolution status
      recallResolutionStatus: json['recall_resolution_status']?.toString() ?? 'Not Started',

      // CPSC-specific fields
      cpscRemedyRecallProof: _parseBoolToYN(json['remedy_recall_proof']),
      cpscModel: json['model']?.toString() ?? '',
      cpscSerialNumber: json['sn']?.toString() ?? json['serial_number']?.toString() ?? '',
      cpscSoldByDateStart: json['sold_by_date_start'] != null
          ? DateTime.tryParse(json['sold_by_date_start'].toString())
          : null,
      cpscSoldByDateEnd: json['sold_by_date_end'] != null
          ? DateTime.tryParse(json['sold_by_date_end'].toString())
          : null,
      cpscSoldByWalmart: _parseBoolToYN(json['sold_by_walmart']),
      cpscSoldByAmazon: _parseBoolToYN(json['sold_by_amazon']),
      cpscSoldByEbay: _parseBoolToYN(json['sold_by_ebay']),
      cpscSoldByAliExpress: _parseBoolToYN(json['sold_by_aliexpress']),
      cpscSoldByBestBuy: _parseBoolToYN(json['sold_by_bestbuy']),
      cpscSoldByTarget: _parseBoolToYN(json['sold_by_target']),
      cpscSoldByTikTok: _parseBoolToYN(json['sold_by_tiktok']),
      cpscSoldByFacebook: _parseBoolToYN(json['sold_by_facebook']),
      cpscSoldByEtsy: _parseBoolToYN(json['sold_by_etsy']),
      cpscSoldByCostco: _parseBoolToYN(json['sold_by_costco']),
      cpscSoldBySamsClub: _parseBoolToYN(json['sold_by_samsclub']),
      cpscSoldByDicksSportingGoods: _parseBoolToYN(json['sold_by_dickssportinggoods']),
      cpscSoldByOfficeDepot: _parseBoolToYN(json['sold_by_officedepot']),
      cpscSoldByKroger: _parseBoolToYN(json['sold_by_kroger']),
      cpscSoldByPublix: _parseBoolToYN(json['sold_by_publix']),

      // NHTSA-specific fields
      nhtsaRecallId: json['nhtsa_recall_id']?.toString() ?? '',
      nhtsaCampaignNumber: json['nhtsa_campaign_number']?.toString() ?? '',
      nhtsaMfrCampaignNumber: json['nhtsa_mfr_campaign_number']?.toString() ?? '',
      nhtsaComponent: json['nhtsa_component']?.toString() ?? '',
      nhtsaRecallType: json['nhtsa_recall_type']?.toString() ?? '',
      nhtsaPotentiallyAffected: json['nhtsa_potentially_affected'] as int?,
      nhtsaFireRisk: json['nhtsa_fire_risk'] == true,
      nhtsaDoNotDrive: json['nhtsa_do_not_drive'] == true,
      nhtsaCompletionRate: json['nhtsa_completion_rate']?.toString() ?? '',
      nhtsaVehicleMake: json['nhtsa_vehicle_make']?.toString() ?? '',
      nhtsaVehicleModel: json['nhtsa_vehicle_model']?.toString() ?? '',
      nhtsaVehicleYearStart: json['nhtsa_vehicle_year_start']?.toString() ?? '',
      nhtsaVehicleYearEnd: json['nhtsa_vehicle_year_end']?.toString() ?? '',
      remedyOtaUpdate: json['remedy_ota_update'] == true,
      nhtsaPlannedDealerNotificationDate: json['nhtsa_planned_dealer_notification_date'] != null
          ? DateTime.tryParse(json['nhtsa_planned_dealer_notification_date'].toString())
          : null,
      nhtsaPlannedOwnerNotificationDate: json['nhtsa_planned_owner_notification_date'] != null
          ? DateTime.tryParse(json['nhtsa_planned_owner_notification_date'].toString())
          : null,
      nhtsaOwnerNotificationLetterMailedDate: json['nhtsa_owner_notification_letter_mailed_date'] != null
          ? DateTime.tryParse(json['nhtsa_owner_notification_letter_mailed_date'].toString())
          : null,
      nhtsaManufPhone: json['nhtsa_manuf_phone']?.toString() ?? '',
      nhtsaModelNum: json['nhtsa_model_num']?.toString() ?? '',
      nhtsaUpc: json['nhtsa_upc']?.toString() ?? '',
    );
  }

  /// Helper to convert bool/string values to 'Y' or ''
  static String _parseBoolToYN(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Y' : '';
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return (lower == 'y' || lower == 'yes' || lower == 'true' || lower == '1') ? 'Y' : '';
    }
    return '';
  }

  /// Update recall resolution status
  Future<RecallData> updateRecallStatus(RecallData recall, String newStatus) async {
    if (recall.databaseId == null) {
      throw Exception('Cannot update recall: missing database ID');
    }

    try {

      // Try the update_status custom endpoint
      final response = await AuthService().authenticatedRequest(
        'POST',
        '${AppConfig.apiRecallsEndpoint}${recall.databaseId}/update_status/',
        body: {
          'recall_resolution_status': newStatus,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _convertFromApi(jsonData as Map<String, dynamic>);
      } else{
        throw Exception('Failed to update recall status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Legacy method - Creates RmcEnrollment for backward compatibility
  /// Note: This method is deprecated, use enrollRecallInRmc() instead
  Future<RecallData> enrollInRmc(RecallData recall) async {
    if (recall.databaseId == null) {
      throw Exception('Cannot enroll recall: missing database ID');
    }

    try {

      final response = await AuthService().authenticatedRequest(
        'POST',
        '${AppConfig.apiRecallsEndpoint}${recall.databaseId}/enroll_in_rmc/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return _convertFromApi(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to enroll recall in RMC: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================================
  // NEW RMC ENROLLMENT API METHODS (User-specific)
  // ============================================================================

  /// Fetch all RMC enrollments for the authenticated user
  Future<List<RmcEnrollment>> fetchRmcEnrollments() async {
    try {

      final response = await AuthService().authenticatedRequest(
        'GET',
        '/rmc-enrollments/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;
        return results.map((json) => RmcEnrollment.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch RMC enrollments: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch active RMC enrollments (excluding "Not Active" status)
  Future<List<RmcEnrollment>> fetchActiveRmcEnrollments() async {
    try {

      final response = await AuthService().authenticatedRequest(
        'GET',
        '/rmc-enrollments/active/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as List;
        return jsonData.map((json) => RmcEnrollment.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch active RMC enrollments: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch RMC enrollments by status
  Future<List<RmcEnrollment>> fetchRmcEnrollmentsByStatus(String status) async {
    try {

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/rmc-enrollments/').replace(
        queryParameters: {'rmc_status': status},
      );

      final response = await AuthService().authenticatedRequest(
        'GET',
        uri.toString().replaceFirst(AppConfig.apiBaseUrl, ''),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;
        return results.map((json) => RmcEnrollment.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch RMC enrollments: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Enroll a recall in RMC for the authenticated user
  Future<RmcEnrollment> enrollRecallInRmc({
    required int recallId,
    String rmcStatus = 'Not Active',
    String? lotNumber,
    String? purchaseDate,
    String? purchaseLocation,
    double? estimatedValue,
  }) async {
    try {
      // Validate status value
      if (!RmcStatus.isValid(rmcStatus)) {
        rmcStatus = RmcStatus.notActive;
      }


      // BACKEND REQUIREMENT: Backend API must accept 'rmc_status' field
      final body = <String, dynamic>{
        'recall_id': recallId,
        'rmc_status': rmcStatus,
      };

      if (lotNumber != null && lotNumber.isNotEmpty) {
        body['lot_number'] = lotNumber;
      }
      if (purchaseDate != null && purchaseDate.isNotEmpty) {
        body['purchase_date'] = purchaseDate;
      }
      if (purchaseLocation != null && purchaseLocation.isNotEmpty) {
        body['purchase_location'] = purchaseLocation;
      }
      if (estimatedValue != null) {
        body['estimated_value'] = estimatedValue.toString();
      }

      final response = await AuthService().authenticatedRequest(
        'POST',
        '/rmc-enrollments/enroll_recall/',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return RmcEnrollment.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to enroll recall in RMC: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update RMC enrollment status
  Future<RmcEnrollment> updateRmcEnrollmentStatus(int enrollmentId, String newStatus) async {
    try {
      // Validate status value
      if (!RmcStatus.isValid(newStatus)) {
        throw ArgumentError('Invalid RMC status: $newStatus. Must be one of: ${RmcStatus.allValidStatuses.join(", ")}');
      }


      // BACKEND REQUIREMENT: Backend API must accept 'rmc_status' field
      final response = await AuthService().authenticatedRequest(
        'POST',
        '/rmc-enrollments/$enrollmentId/update_status/',
        body: {'rmc_status': newStatus},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RmcEnrollment.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update RMC enrollment status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update RMC enrollment with multiple fields (status, branch, etc.)
  Future<RmcEnrollment> updateRmcEnrollment({
    required int enrollmentId,
    String? status,
    String? resolutionBranch,
    String? notes,
  }) async {
    try {

      final Map<String, dynamic> body = {};

      if (status != null) {
        // Validate status value
        if (!RmcStatus.isValid(status)) {
          throw ArgumentError('Invalid RMC status: $status');
        }
        body['rmc_status'] = status;
      }

      if (resolutionBranch != null) {
        body['resolution_branch'] = resolutionBranch;
      }

      if (notes != null) {
        body['notes'] = notes;
      }

      final response = await AuthService().authenticatedRequest(
        'PATCH',
        '/rmc-enrollments/$enrollmentId/',
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RmcEnrollment.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update RMC enrollment: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update RMC enrollment with proof branch data including photos
  /// Uses multipart request to upload photo files
  Future<RmcEnrollment> updateRmcEnrollmentWithProof({
    required int enrollmentId,
    String? status,
    String? proofPurchaseLocation,
    String? proofPurchaseDate,
    String? proofSerialNumber,
    String? proofPhoto1Path,
    String? proofPhoto2Path,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rmc-enrollments/$enrollmentId/');

      // Create multipart request
      final request = http.MultipartRequest('PATCH', uri);

      // Add authorization header
      final token = await AuthService().getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      if (status != null) {
        if (!RmcStatus.isValid(status)) {
          throw ArgumentError('Invalid RMC status: $status');
        }
        request.fields['rmc_status'] = status;
      }

      if (proofPurchaseLocation != null && proofPurchaseLocation.isNotEmpty) {
        request.fields['proof_purchase_location'] = proofPurchaseLocation;
      }

      if (proofPurchaseDate != null && proofPurchaseDate.isNotEmpty) {
        request.fields['proof_purchase_date'] = proofPurchaseDate;
      }

      if (proofSerialNumber != null && proofSerialNumber.isNotEmpty) {
        request.fields['proof_serial_number'] = proofSerialNumber;
      }

      // Set proof email sent timestamp
      request.fields['proof_email_sent_at'] = DateTime.now().toIso8601String();

      // Add photo files if provided
      if (proofPhoto1Path != null && proofPhoto1Path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'proof_photo_1',
          proofPhoto1Path,
        ));
      }

      if (proofPhoto2Path != null && proofPhoto2Path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'proof_photo_2',
          proofPhoto2Path,
        ));
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RmcEnrollment.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update RMC enrollment with proof: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific RMC enrollment by ID
  Future<RmcEnrollment> fetchRmcEnrollmentById(int enrollmentId) async {
    try {

      final response = await AuthService().authenticatedRequest(
        'GET',
        '/rmc-enrollments/$enrollmentId/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return RmcEnrollment.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch RMC enrollment: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get RMC enrollment for a specific recall (if exists)
  Future<RmcEnrollment?> fetchRmcEnrollmentForRecall(int recallId) async {
    try {

      final enrollments = await fetchRmcEnrollmentsByRecallFilter(recallId);

      if (enrollments.isNotEmpty) {
        return enrollments.first;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Fetch RMC enrollments filtered by recall ID
  Future<List<RmcEnrollment>> fetchRmcEnrollmentsByRecallFilter(int recallId) async {
    try {

      final uri = Uri.parse('${AppConfig.apiBaseUrl}/rmc-enrollments/').replace(
        queryParameters: {'recall': recallId.toString()},
      );

      final response = await AuthService().authenticatedRequest(
        'GET',
        uri.toString().replaceFirst(AppConfig.apiBaseUrl, ''),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;
        return results.map((json) => RmcEnrollment.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch RMC enrollments: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
