import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recall_data.dart';
import '../models/recommended_product.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;

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

      print('🌐 Fetching recalls from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        print('✅ Successfully fetched ${results.length} recalls');

        return results
            .map((json) => _convertFromApi(json as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error fetching recalls: ${response.statusCode}');
        throw Exception('Failed to load recalls: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching recalls: $e');
      rethrow;
    }
  }

  /// Fetch FDA recalls only
  Future<List<RecallData>> fetchFdaRecalls() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiFdaEndpoint}');
      print('🌐 Fetching FDA recalls from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        print('✅ Successfully fetched ${results.length} FDA recalls');

        return results
            .map((json) => _convertFromApi(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load FDA recalls: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching FDA recalls: $e');
      rethrow;
    }
  }

  /// Fetch USDA recalls only
  Future<List<RecallData>> fetchUsdaRecalls() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiUsdaEndpoint}');
      print('🌐 Fetching USDA recalls from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        print('✅ Successfully fetched ${results.length} USDA recalls');

        return results
            .map((json) => _convertFromApi(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load USDA recalls: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching USDA recalls: $e');
      rethrow;
    }
  }

  /// Fetch recalls with active resolution status (not 'Not Started')
  Future<List<RecallData>> fetchActiveRecalls() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiRecallsEndpoint}active_recalls/');
      print('🌐 Fetching active recalls from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        print('✅ Successfully fetched ${results.length} active recalls');

        return results
            .map((json) => _convertFromApi(json as Map<String, dynamic>))
            .toList();
      } else {
        print('❌ Error fetching active recalls: ${response.statusCode}');
        throw Exception('Failed to load active recalls: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching active recalls: $e');
      rethrow;
    }
  }

  /// Fetch a single recall by ID
  Future<RecallData> fetchRecallById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiRecallsEndpoint}$id/');
      print('🌐 Fetching recall $id from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully fetched recall $id');

        return _convertFromApi(jsonData as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load recall $id: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching recall $id: $e');
      rethrow;
    }
  }

  /// Fetch API statistics
  Future<Map<String, dynamic>> fetchStats() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.apiStatsEndpoint}');
      print('🌐 Fetching stats from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully fetched stats');
        return jsonData as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching stats: $e');
      rethrow;
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
    print('=== API Response for $recallId ===');
    print('remedy_return: ${json['remedy_return']} (${json['remedy_return'].runtimeType})');
    print('remedy_repair: ${json['remedy_repair']} (${json['remedy_repair'].runtimeType})');
    print('remedy_replace: ${json['remedy_replace']} (${json['remedy_replace'].runtimeType})');

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
    );
  }

  /// Update recall resolution status
  Future<RecallData> updateRecallStatus(RecallData recall, String newStatus) async {
    if (recall.databaseId == null) {
      throw Exception('Cannot update recall: missing database ID');
    }

    try {
      print('🌐 Updating recall ${recall.databaseId} status to: $newStatus');

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
        print('✅ Successfully updated recall ${recall.databaseId} status');
        print('📦 Response recall_resolution_status: ${jsonData['recall_resolution_status']}');
        return _convertFromApi(jsonData as Map<String, dynamic>);
      } else{
        print('❌ Error updating recall status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update recall status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception updating recall status: $e');
      rethrow;
    }
  }

  /// Enroll a recall into the Recall Management Center
  /// Sets in_rmc=True and initializes recall_resolution_status to 'Open'
  Future<RecallData> enrollInRmc(RecallData recall) async {
    if (recall.databaseId == null) {
      throw Exception('Cannot enroll recall: missing database ID');
    }

    try {
      print('🌐 Enrolling recall ${recall.databaseId} in RMC');

      final response = await AuthService().authenticatedRequest(
        'POST',
        '${AppConfig.apiRecallsEndpoint}${recall.databaseId}/enroll_in_rmc/',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ Successfully enrolled recall ${recall.databaseId} in RMC');
        return _convertFromApi(jsonData as Map<String, dynamic>);
      } else {
        print('❌ Error enrolling recall in RMC: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to enroll recall in RMC: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception enrolling recall in RMC: $e');
      rethrow;
    }
  }
}
