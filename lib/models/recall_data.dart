// (removed duplicate FDA fields)

import 'recommended_product.dart';
import '../config/app_config.dart';

/// Image size context for optimized image selection
enum ImageSize {
  thumbnail,  // 240x240 WebP for list views (~15-25 KB)
  medium,     // 600x600 WebP for detail pages (~40-70 KB)
  highRes,    // 1200x1200 WebP for full-screen (~80-150 KB)
}

// Model for images uploaded via admin panel
class RecallImage {
  final int id;
  final String imageUrl;
  final String caption;
  final DateTime uploadedAt;

  RecallImage({
    required this.id,
    required this.imageUrl,
    required this.caption,
    required this.uploadedAt,
  });

  factory RecallImage.fromJson(Map<String, dynamic> json) {
    return RecallImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      caption: json['caption'] ?? '',
      uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class RecallData {
  final String reportsOfInjury;
  final String distributionDateStart;
  final String distributionDateEnd;
  final String bestUsedByDateEnd;
  final String itemNumCode;
  final String firmContactForm; // FDA-only field
  final String establishmentManufacturerContactForm;
  final String distributor;
  final String usdaRecallId;
  final String fdaRecallId;
  // FDA/USDA fields for GoogleSheetsService compatibility
  final String fieldRecallNumber;
  final String expDate;
  final String batchLotCode;
  final String upc;
  final String productIdentification;
  final String recallPhaReason;
  final String recallReason;
  final String sellByDate;
  final DateTime? sellByDateStart; // Start date for sell by range (FDA/USDA)
  final DateTime? sellByDateEnd; // End date for sell by range (FDA/USDA)
  final String sku;
  final String adverseReactions;
  final String adverseReactionDetails;
  final String id;
  final int? databaseId; // Numeric database ID for API updates
  final String productName;
  final String brandName;
  final String riskLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final DateTime dateIssued;
  final String agency; // 'FDA', 'USDA'
  final String description;
  final String category;
  final String recallClassification; // USDA-specific recall classification
  final String imageUrl;
  final String imageUrl2;
  final String imageUrl3;
  final String imageUrl4;
  final String imageUrl5;
  final String distributionMapUrl; // Auto-generated distribution map image

  // Optimized image URLs (WebP format, generated from imageUrl)
  final String imageThumbnail; // 240x240 WebP (~15-25 KB) for list views
  final String imageMedium; // 600x600 WebP (~40-70 KB) for detail pages
  final String imageHighRes; // 1200x1200 WebP (~80-150 KB) for full-screen viewing

  final List<RecallImage> images; // Images uploaded via admin panel
  final List<RecommendedProduct> recommendations; // Recommended replacement products
  final int stateCount;
  final String negativeOutcomes;
  final String packagingDesc;
  final String remedyReturn;
  final String remedyRepair;
  final String remedyReplace;
  final String remedyDispose;
  final String remedyNA;
  final String productQty;
  final String soldBy;
  final String packagedOnDate;
  final DateTime? productionDateStart;
  final DateTime? productionDateEnd;
  final String bestUsedByDate;
  // --- FDA-only fields ---
  final String ndc; // National Drug Code (FDA Drug recalls)
  final String recallReasonShort;
  final String pressReleaseLink;
  final String productTypeDetail;
  final String productSizeWeight;
  final String howFound;
  final String distributionPattern;
  final String recallingFdaFirm;
  final String firmContactName;
  final String firmContactPhone;
  final String firmContactBusinessHoursDays;
  final String firmContactEmail;
  final String firmContactWebSite;
  final String firmWebSiteInfo;
  final String recommendationsActions;
  final String remedy;
  final String productDistribution;
  final String establishmentManufacturer;
  final String establishmentManufacturerContactName;
  final String establishmentManufacturerContactPhone;
  final String establishmentManufacturerContactBusinessHoursDays;
  final String establishmentManufacturerContactEmail;
  final String establishmentManufacturerWebsite;
  final String establishmentManufacturerWebsiteInfo;
  final String retailer1;
  final String retailer1SaleDateStart;
  final String retailer1SaleDateEnd;
  final String retailer1ContactName;
  final String retailer1ContactPhone;
  final String retailer1ContactBusinessHoursDays;
  final String retailer1ContactEmail;
  final String retailer1ContactWebSite;
  final String retailer1WebSiteInfo;
  final String estItemValue;
  final String recallUrl;
  final String usdaToReportAProblem;
  final String usdaFoodSafetyQuestionsPhone;
  final String usdaFoodSafetyQuestionsEmail;
  final String recallResolutionStatus;

  // --- NHTSA-specific fields ---
  final String nhtsaRecallId; // NHTSA campaign number
  final String nhtsaCampaignNumber; // Same as recall ID
  final String nhtsaMfrCampaignNumber; // Manufacturer's campaign number
  final String nhtsaComponent; // Component being recalled
  final String nhtsaRecallType; // 'Vehicle', 'Tire', 'Child Seat', 'Equipment'
  final int? nhtsaPotentiallyAffected; // Number of potentially affected units
  final bool nhtsaFireRisk; // Fire risk indicator
  final bool nhtsaDoNotDrive; // Do not drive warning
  final String nhtsaCompletionRate; // Recall completion rate
  final String nhtsaVehicleMake; // Vehicle make (manufacturer)
  final String nhtsaVehicleModel; // Vehicle model
  final String nhtsaVehicleYearStart; // Start year for affected vehicles
  final String nhtsaVehicleYearEnd; // End year for affected vehicles
  final String nhtsaVehicleYearRange; // Combined year range (e.g., "2020-2024" or "2020")
  final bool remedyOtaUpdate; // OTA software update remedy
  final DateTime? nhtsaPlannedDealerNotificationDate;
  final DateTime? nhtsaPlannedOwnerNotificationDate;
  final DateTime? nhtsaOwnerNotificationLetterMailedDate;
  final String nhtsaManufPhone; // Manufacturer phone
  final String nhtsaModelNum; // Model number (for Tire/Child Seat)
  final String nhtsaUpc; // UPC code (for Tire/Child Seat)

  // --- CPSC-specific fields ---
  final String cpscRemedyRecallProof; // Y or blank - requires proof for remedy
  final String cpscModel; // Product model number
  final String cpscSerialNumber; // Product serial number
  final DateTime? cpscSoldByDateStart; // Start date for when product was sold
  final DateTime? cpscSoldByDateEnd; // End date for when product was sold
  final String cpscSoldByWalmart; // Y or blank
  final String cpscSoldByAmazon; // Y or blank
  final String cpscSoldByEbay; // Y or blank
  final String cpscSoldByAliExpress; // Y or blank
  final String cpscSoldByBestBuy; // Y or blank
  final String cpscSoldByTarget; // Y or blank
  final String cpscSoldByTikTok; // Y or blank
  final String cpscSoldByFacebook; // Y or blank
  final String cpscSoldByEtsy; // Y or blank
  final String cpscSoldByCostco; // Y or blank
  final String cpscSoldBySamsClub; // Y or blank
  final String cpscSoldByDicksSportingGoods; // Y or blank
  final String cpscSoldByOfficeDepot; // Y or blank
  final String cpscSoldByKroger; // Y or blank
  final String cpscSoldByPublix; // Y or blank

  RecallData({
    this.usdaRecallId = '',
    this.fdaRecallId = '',
    this.fieldRecallNumber = '',
    this.expDate = '',
    this.batchLotCode = '',
    this.upc = '',
    this.productIdentification = '',
    this.recallPhaReason = '',
    this.recallReason = '',
    this.sellByDate = '',
    this.sellByDateStart,
    this.sellByDateEnd,
    this.sku = '',
    this.adverseReactions = '',
    this.adverseReactionDetails = '',
    this.reportsOfInjury = '',
    this.distributionDateStart = '',
    this.distributionDateEnd = '',
    this.bestUsedByDateEnd = '',
    this.itemNumCode = '',
    this.firmContactForm = '',
    this.establishmentManufacturerContactForm = '',
    this.distributor = '',
    this.ndc = '',
    this.recallReasonShort = '',
    this.pressReleaseLink = '',
    this.productTypeDetail = '',
    this.productSizeWeight = '',
    this.howFound = '',
    this.distributionPattern = '',
    this.recallingFdaFirm = '',
    this.firmContactName = '',
    this.firmContactPhone = '',
    this.firmContactBusinessHoursDays = '',
    this.firmContactEmail = '',
    this.firmContactWebSite = '',
    this.firmWebSiteInfo = '',
    required this.id,
    this.databaseId,
    required this.productName,
    required this.brandName,
    required this.riskLevel,
    required this.dateIssued,
    required this.agency,
    required this.description,
    required this.category,
    this.recallClassification = '',
    this.imageUrl = '',
    this.imageUrl2 = '',
    this.imageUrl3 = '',
    this.imageUrl4 = '',
    this.imageUrl5 = '',
    this.distributionMapUrl = '',
    this.imageThumbnail = '',
    this.imageMedium = '',
    this.imageHighRes = '',
    this.images = const [],
    this.recommendations = const [],
    this.stateCount = 0,
    this.negativeOutcomes = '',
    this.packagingDesc = '',
    this.remedyReturn = '',
    this.remedyRepair = '',
    this.remedyReplace = '',
    this.remedyDispose = '',
    this.remedyNA = '',
    this.productQty = '',
    this.soldBy = '',
    this.productionDateStart,
    this.productionDateEnd,
    this.bestUsedByDate = '',
    this.packagedOnDate = '',
    this.recommendationsActions = '',
    this.remedy = '',
    this.productDistribution = '',
    this.establishmentManufacturer = '',
    this.establishmentManufacturerContactName = '',
    this.establishmentManufacturerContactPhone = '',
    this.establishmentManufacturerContactBusinessHoursDays = '',
    this.establishmentManufacturerContactEmail = '',
    this.establishmentManufacturerWebsite = '',
    this.establishmentManufacturerWebsiteInfo = '',
    this.retailer1 = '',
    this.retailer1SaleDateStart = '',
    this.retailer1SaleDateEnd = '',
    this.retailer1ContactName = '',
    this.retailer1ContactPhone = '',
    this.retailer1ContactBusinessHoursDays = '',
    this.retailer1ContactEmail = '',
    this.retailer1ContactWebSite = '',
    this.retailer1WebSiteInfo = '',
    this.estItemValue = '',
    this.recallUrl = '',
    this.usdaToReportAProblem = '',
    this.usdaFoodSafetyQuestionsPhone = '',
    this.usdaFoodSafetyQuestionsEmail = '',
    this.recallResolutionStatus = 'Not Started',
    // NHTSA-specific fields
    this.nhtsaRecallId = '',
    this.nhtsaCampaignNumber = '',
    this.nhtsaMfrCampaignNumber = '',
    this.nhtsaComponent = '',
    this.nhtsaRecallType = '',
    this.nhtsaPotentiallyAffected,
    this.nhtsaFireRisk = false,
    this.nhtsaDoNotDrive = false,
    this.nhtsaCompletionRate = '',
    this.nhtsaVehicleMake = '',
    this.nhtsaVehicleModel = '',
    this.nhtsaVehicleYearStart = '',
    this.nhtsaVehicleYearEnd = '',
    this.nhtsaVehicleYearRange = '',
    this.remedyOtaUpdate = false,
    this.nhtsaPlannedDealerNotificationDate,
    this.nhtsaPlannedOwnerNotificationDate,
    this.nhtsaOwnerNotificationLetterMailedDate,
    this.nhtsaManufPhone = '',
    this.nhtsaModelNum = '',
    this.nhtsaUpc = '',
    // CPSC-specific fields
    this.cpscRemedyRecallProof = '',
    this.cpscModel = '',
    this.cpscSerialNumber = '',
    this.cpscSoldByDateStart,
    this.cpscSoldByDateEnd,
    this.cpscSoldByWalmart = '',
    this.cpscSoldByAmazon = '',
    this.cpscSoldByEbay = '',
    this.cpscSoldByAliExpress = '',
    this.cpscSoldByBestBuy = '',
    this.cpscSoldByTarget = '',
    this.cpscSoldByTikTok = '',
    this.cpscSoldByFacebook = '',
    this.cpscSoldByEtsy = '',
    this.cpscSoldByCostco = '',
    this.cpscSoldBySamsClub = '',
    this.cpscSoldByDicksSportingGoods = '',
    this.cpscSoldByOfficeDepot = '',
    this.cpscSoldByKroger = '',
    this.cpscSoldByPublix = '',
  });

  // This converts data FROM a spreadsheet/JSON into a RecallData object
  factory RecallData.fromJson(Map<String, dynamic> json) {
    final agency = (json['agency'] ?? 'FDA').toString().trim().toUpperCase();

    // Get the recall_id string (prioritize recall_id field, fallback to id)
    final recallIdString = (json['recall_id'] ?? json['id'] ?? '').toString();

    // Determine agency type from recall_id prefix if not explicitly set
    final isFda = recallIdString.startsWith('FDA') || agency == 'FDA';
    final isUsda = recallIdString.startsWith('USDA') || agency == 'USDA';

    // Accept both FDARecallID and fdaRecallId, fallback to recall_id if present and agency is FDA
    String fdaId = '';
    if (isFda) {
      fdaId = (json['FDARecallID'] ?? json['fdaRecallId'] ?? json['recall_id'] ?? json['id'] ?? '')
          .toString();
    }
    String usdaId = '';
    if (isUsda) {
      usdaId =
          (json['USDARecallID'] ?? json['usdaRecallId'] ?? json['recall_id'] ?? json['id'] ?? '')
              .toString();
    }
    return RecallData(
      fdaRecallId: fdaId,
      usdaRecallId: usdaId,
      ndc: json['ndc'] ?? '',
      recallReasonShort: json['recall_reason_short'] ?? '',
      pressReleaseLink: json['press_release_link'] ?? '',
      productTypeDetail: json['product_type_detail'] ?? '',
      productSizeWeight: json['product_size_weight'] ?? '',
      howFound: json['how_found'] ?? '',
      distributionPattern: json['distribution_pattern'] ?? '',
      recallingFdaFirm:
          json['RECALLING_FDA_FIRM'] ??
          json['recalling_fda_firm'] ??
          json['recalling_firm'] ??
          '',
      firmContactName: json['firm_contact_name'] ?? '',
      firmContactPhone: json['firm_contact_phone'] ?? '',
      firmContactBusinessHoursDays:
          json['firm_contact_business_hours_days'] ??
          json['firm_contact_business_hours'] ??
          '',
      firmContactEmail: json['firm_contact_email'] ?? '',
      firmContactWebSite:
          json['firm_contact_web_site'] ??
          json['firm_contact_website'] ??
          '',
      firmWebSiteInfo: json['firm_web_site_info'] ?? '',
      recallUrl: json['recall_url'] ?? '',
      // Prioritize recall_id field, fallback to id field (convert to string)
      id: (json['recall_id'] ?? json['id'] ?? '').toString(),
      databaseId: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      productName: json['product_name'] ?? '',
      brandName: json['brand_name'] ?? '',
      riskLevel: json['risk_level'] ?? 'LOW',
      dateIssued: DateTime.parse(
        json['date_issued'] ?? DateTime.now().toIso8601String(),
      ),
      agency: json['agency'] ?? 'FDA',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      recallClassification: json['recall_classification'] ?? '',
      imageUrl: json['image_url'] ?? '',
      imageUrl2: json['image_url2'] ?? json['Image_URL2'] ?? '',
      imageUrl3: json['image_url3'] ?? json['Image_URL3'] ?? '',
      imageUrl4: json['image_url4'] ?? json['Image_URL4'] ?? '',
      imageUrl5: json['image_url5'] ?? json['Image_URL5'] ?? '',
      distributionMapUrl: _makeAbsoluteUrl(json['distribution_map_url'] ?? ''),
      imageThumbnail: _makeAbsoluteUrl(json['image_thumbnail'] ?? ''),
      imageMedium: _makeAbsoluteUrl(json['image_medium'] ?? ''),
      imageHighRes: _makeAbsoluteUrl(json['image_high_res'] ?? ''),
      images: (json['images'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((img) => RecallImage.fromJson(img))
          .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((rec) => RecommendedProduct.fromJson(rec))
          .toList() ?? [],
      stateCount: json['state_count'] ?? 0,
      negativeOutcomes: json['negative_outcomes'] ?? '',
      packagingDesc: json['packaging_desc'] ?? '',
      // Convert remedy booleans to 'Y' or '' for checkbox display
      remedyReturn: (json['remedy_return'] is bool)
          ? ((json['remedy_return'] as bool) ? 'Y' : '')
          : (json['remedy_return']?.toString() ?? ''),
      remedyRepair: (json['remedy_repair'] is bool)
          ? ((json['remedy_repair'] as bool) ? 'Y' : '')
          : (json['remedy_repair']?.toString() ?? ''),
      remedyReplace: (json['remedy_replace'] is bool)
          ? ((json['remedy_replace'] as bool) ? 'Y' : '')
          : (json['remedy_replace']?.toString() ?? ''),
      remedyDispose: (json['remedy_dispose'] is bool)
          ? ((json['remedy_dispose'] as bool) ? 'Y' : '')
          : (json['remedy_dispose']?.toString() ?? ''),
      remedyNA: (json['remedy_na'] is bool)
          ? ((json['remedy_na'] as bool) ? 'Y' : '')
          : (json['remedy_na']?.toString() ?? ''),
      productQty: json['product_qty'] ?? '',
      soldBy: json['sold_by'] ?? '',
      productionDateStart:
          json['production_date_start'] != null &&
              json['production_date_start'] != ''
          ? DateTime.tryParse(json['production_date_start'])
          : null,
      productionDateEnd:
          json['production_date_end'] != null &&
              json['production_date_end'] != ''
          ? DateTime.tryParse(json['production_date_end'])
          : null,
      bestUsedByDate: json['best_used_by_date'] ?? '',
      bestUsedByDateEnd: json['BEST_USED_BY_DATE_END'] ?? '',
      packagedOnDate: json['packaged_on_date'] ?? '',
      expDate: json['exp_date'] ?? '',
      batchLotCode: json['batch_lot_code'] ?? '',
      upc: json['upc'] ?? '',
      reportsOfInjury:
          json['Reports_of_Injury'] ?? json['reports_of_injury'] ?? '',
      distributionDateStart:
          json['DISTRIBUTION_DATE_START'] ??
          json['distribution_date_start'] ??
          '',
      distributionDateEnd:
          json['DISTRIBUTION_DATE_END'] ?? json['distribution_date_end'] ?? '',
      itemNumCode: json['ITEM_NUM_CODE'] ?? json['item_num_code'] ?? '',
      firmContactForm:
          json['FIRM_CONTACT_FORM'] ?? json['firm_contact_form'] ?? '',
      establishmentManufacturerContactForm:
          json['establishment-manufacturer-contact-form'] ?? '',
      distributor: json['DISTRIBUTOR'] ?? json['distributor'] ?? '',
      // Robust mapping for fieldRecallNumber
      fieldRecallNumber:
          json['field_recall_number'] ??
          json['Field_Recall_Number'] ??
          json['fieldRecallNumber'] ??
          json['Field Recall Number'] ??
          '',
      productIdentification:
          json['product_identification'] ??
          json['PRODUCT_IDENTIFICATION'] ??
          '',
      recallPhaReason:
          json['recall_pha_reason'] ?? json['RECALL_PHA_REASON'] ?? '',
      recallReason: json['Recall_Reason'] ?? json['recall_reason'] ?? '',
      // --- New USDA fields ---
      sellByDate: json['sell_by_date'] ?? '',
      sellByDateStart:
          json['sell_by_date_start'] != null && json['sell_by_date_start'] != ''
              ? DateTime.tryParse(json['sell_by_date_start'])
              : null,
      sellByDateEnd:
          json['sell_by_date_end'] != null && json['sell_by_date_end'] != ''
              ? DateTime.tryParse(json['sell_by_date_end'])
              : null,
      sku: json['sku'] ?? '',
      adverseReactions: json['adverse_reactions'] ?? '',
      adverseReactionDetails: json['adverse_reaction_details'] ?? '',
      recommendationsActions: json['recommendations_actions'] ?? '',
      remedy: json['remedy'] ?? '',
      productDistribution: json['product_distribution'] ?? '',
      establishmentManufacturer:
          json['establishment-manufacturer'] ??
          json['establishment_manufacturer'] ??
          json['establishment_name'] ??
          json['establishment_number'] ??
          '',
      establishmentManufacturerContactName:
          json['establishment-manufacturer-contact-name'] ?? '',
      establishmentManufacturerContactPhone:
          json['establishment-manufacturer-contact-phone'] ?? '',
      establishmentManufacturerContactBusinessHoursDays:
          json['establishment_manufacturer-CONTACT_BUSINESS_HOURS_DAYS'] ?? '',
      establishmentManufacturerContactEmail:
          json['establishment-manufacturer-contact-email'] ?? '',
      establishmentManufacturerWebsite:
          json['establishment-manufacturer-website'] ?? '',
      establishmentManufacturerWebsiteInfo:
          json['establishment-manufacturer-website-info'] ?? '',
      retailer1: json['Retailer1'] ?? '',
      retailer1SaleDateStart: json['RETAILER1_SALE_DATE_START'] ?? '',
      retailer1SaleDateEnd: json['RETAILER1_SALE_DATE_END'] ?? '',
      retailer1ContactName: json['RETAILER1_CONTACT_NAME'] ?? '',
      retailer1ContactPhone: json['RETAILER1_CONTACT_PHONE'] ?? '',
      retailer1ContactBusinessHoursDays:
          json['RETAILER1_CONTACT_BUSINESS_HOURS_DAYS'] ?? '',
      retailer1ContactEmail: json['RETAILER1_CONTACT_EMAIL'] ?? '',
      retailer1ContactWebSite: json['RETAILER1_CONTACT_WEB_SITE'] ?? '',
      retailer1WebSiteInfo: json['RETAILER1_WEB_SITE_INFO'] ?? '',
      estItemValue: json['EST_ITEM_VALUE'] ?? '',
      usdaToReportAProblem: json['USDA-To-report-a-problem'] ?? '',
      usdaFoodSafetyQuestionsPhone:
          json['USDA-food-safety-questions-phone'] ?? '',
      usdaFoodSafetyQuestionsEmail:
          json['USDA-food-safety-questions-email'] ?? '',
      recallResolutionStatus: json['recall_resolution_status'] ?? 'Not Started',
      // NHTSA-specific fields
      nhtsaRecallId: json['nhtsa_recall_id'] ?? '',
      nhtsaCampaignNumber: json['nhtsa_campaign_number'] ?? '',
      nhtsaMfrCampaignNumber: json['nhtsa_mfr_campaign_number'] ?? '',
      nhtsaComponent: json['nhtsa_component'] ?? '',
      nhtsaRecallType: json['nhtsa_recall_type'] ?? '',
      nhtsaPotentiallyAffected: json['nhtsa_potentially_affected'] is int
          ? json['nhtsa_potentially_affected']
          : (json['nhtsa_potentially_affected'] != null
              ? int.tryParse(json['nhtsa_potentially_affected'].toString())
              : null),
      nhtsaFireRisk: json['nhtsa_fire_risk'] == true ||
          json['nhtsa_fire_risk'] == 'true' ||
          json['nhtsa_fire_risk'] == 'Y',
      nhtsaDoNotDrive: json['nhtsa_do_not_drive'] == true ||
          json['nhtsa_do_not_drive'] == 'true' ||
          json['nhtsa_do_not_drive'] == 'Y',
      nhtsaCompletionRate: json['nhtsa_completion_rate'] ?? '',
      nhtsaVehicleMake: json['nhtsa_vehicle_make'] ?? '',
      nhtsaVehicleModel: json['nhtsa_vehicle_model'] ?? '',
      nhtsaVehicleYearStart: json['nhtsa_vehicle_year_start']?.toString() ?? '',
      nhtsaVehicleYearEnd: json['nhtsa_vehicle_year_end']?.toString() ?? '',
      nhtsaVehicleYearRange: json['nhtsa_vehicle_year_range']?.toString() ?? '',
      remedyOtaUpdate: json['remedy_ota_update'] == true ||
          json['remedy_ota_update'] == 'true' ||
          json['remedy_ota_update'] == 'Y',
      nhtsaPlannedDealerNotificationDate:
          json['nhtsa_planned_dealer_notification_date'] != null &&
              json['nhtsa_planned_dealer_notification_date'] != ''
              ? DateTime.tryParse(json['nhtsa_planned_dealer_notification_date'])
              : null,
      nhtsaPlannedOwnerNotificationDate:
          json['nhtsa_planned_owner_notification_date'] != null &&
              json['nhtsa_planned_owner_notification_date'] != ''
              ? DateTime.tryParse(json['nhtsa_planned_owner_notification_date'])
              : null,
      nhtsaOwnerNotificationLetterMailedDate:
          json['nhtsa_owner_notification_letter_mailed_date'] != null &&
              json['nhtsa_owner_notification_letter_mailed_date'] != ''
              ? DateTime.tryParse(json['nhtsa_owner_notification_letter_mailed_date'])
              : null,
      nhtsaManufPhone: json['nhtsa_manuf_phone'] ?? '',
      nhtsaModelNum: json['nhtsa_model_num'] ?? '',
      nhtsaUpc: json['nhtsa_upc'] ?? '',
      // CPSC-specific fields
      cpscRemedyRecallProof: _parseBoolToYN(json['remedy_recall_proof']),
      cpscModel: json['model'] ?? '',
      cpscSerialNumber: json['sn'] ?? json['serial_number'] ?? '',
      cpscSoldByDateStart:
          json['sold_by_date_start'] != null && json['sold_by_date_start'] != ''
              ? DateTime.tryParse(json['sold_by_date_start'])
              : null,
      cpscSoldByDateEnd:
          json['sold_by_date_end'] != null && json['sold_by_date_end'] != ''
              ? DateTime.tryParse(json['sold_by_date_end'])
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

  // This converts a RecallData object TO a format for spreadsheet/JSON storage
  Map<String, dynamic> toJson() {
    return {
      'FDARecallID': fdaRecallId,
      'ndc': ndc,
      'recall_reason_short': recallReasonShort,
      'press_release_link': pressReleaseLink,
      'product_type_detail': productTypeDetail,
      'product_size_weight': productSizeWeight,
      'how_found': howFound,
      'distribution_pattern': distributionPattern,
      'RECALLING_FDA_FIRM': recallingFdaFirm,
      'firm_contact_name': firmContactName,
      'firm_contact_phone': firmContactPhone,
      'firm_contact_business_hours_days': firmContactBusinessHoursDays,
      'firm_contact_email': firmContactEmail,
      'firm_contact_web_site': firmContactWebSite,
      'firm_web_site_info': firmWebSiteInfo,
      'recall_url': recallUrl,
      'id': id,
      'field_recall_number': fieldRecallNumber,
      'product_name': productName,
      'brand_name': brandName,
      'risk_level': riskLevel,
      'date_issued': dateIssued.toIso8601String(),
      'agency': agency,
      'description': description,
      'category': category,
      'recall_classification': recallClassification,
      'image_url': imageUrl,
      'image_url2': imageUrl2,
      'image_url3': imageUrl3,
      'image_url4': imageUrl4,
      'image_url5': imageUrl5,
      'distribution_map_url': distributionMapUrl,
      'image_thumbnail': imageThumbnail,
      'image_medium': imageMedium,
      'image_high_res': imageHighRes,
      'state_count': stateCount,
      'negative_outcomes': negativeOutcomes,
      'packaging_desc': packagingDesc,
      'remedy_return': remedyReturn,
      'remedy_repair': remedyRepair,
      'remedy_replace': remedyReplace,
      'remedy_dispose': remedyDispose,
      'remedy_na': remedyNA,
      'product_qty': productQty,
      'sold_by': soldBy,
      'production_date_start': productionDateStart?.toIso8601String() ?? '',
      'production_date_end': productionDateEnd?.toIso8601String() ?? '',
      'best_used_by_date': bestUsedByDate,
      'BEST_USED_BY_DATE_END': bestUsedByDateEnd,
      'packaged_on_date': packagedOnDate,
      'exp_date': expDate,
      'batch_lot_code': batchLotCode,
      'upc': upc,
      'Reports_of_Injury': reportsOfInjury,
      'DISTRIBUTION_DATE_START': distributionDateStart,
      'DISTRIBUTION_DATE_END': distributionDateEnd,
      'ITEM_NUM_CODE': itemNumCode,
      'FIRM_CONTACT_FORM': firmContactForm,
      'establishment-manufacturer-contact-form':
          establishmentManufacturerContactForm,
      'DISTRIBUTOR': distributor,
      'product_identification': productIdentification,
      'recall_pha_reason': recallPhaReason,
      'Recall_Reason': recallReason,
      // --- New USDA fields ---
      'sell_by_date': sellByDate,
      'sell_by_date_start': sellByDateStart?.toIso8601String() ?? '',
      'sell_by_date_end': sellByDateEnd?.toIso8601String() ?? '',
      'sku': sku,
      'adverse_reactions': adverseReactions,
      'adverse_reaction_details': adverseReactionDetails,
      'recommendations_actions': recommendationsActions,
      'remedy': remedy,
      'product_distribution': productDistribution,
      'establishment-manufacturer': establishmentManufacturer,
      'establishment-manufacturer-contact-name':
          establishmentManufacturerContactName,
      'establishment-manufacturer-contact-phone':
          establishmentManufacturerContactPhone,
      'establishment_manufacturer-CONTACT_BUSINESS_HOURS_DAYS':
          establishmentManufacturerContactBusinessHoursDays,
      'establishment-manufacturer-contact-email':
          establishmentManufacturerContactEmail,
      'establishment-manufacturer-website': establishmentManufacturerWebsite,
      'establishment-manufacturer-website-info':
          establishmentManufacturerWebsiteInfo,
      'Retailer1': retailer1,
      'RETAILER1_SALE_DATE_START': retailer1SaleDateStart,
      'RETAILER1_SALE_DATE_END': retailer1SaleDateEnd,
      'RETAILER1_CONTACT_NAME': retailer1ContactName,
      'RETAILER1_CONTACT_PHONE': retailer1ContactPhone,
      'RETAILER1_CONTACT_BUSINESS_HOURS_DAYS':
          retailer1ContactBusinessHoursDays,
      'RETAILER1_CONTACT_EMAIL': retailer1ContactEmail,
      'RETAILER1_CONTACT_WEB_SITE': retailer1ContactWebSite,
      'RETAILER1_WEB_SITE_INFO': retailer1WebSiteInfo,
      'EST_ITEM_VALUE': estItemValue,
      'USDA-To-report-a-problem': usdaToReportAProblem,
      'USDA-food-safety-questions-phone': usdaFoodSafetyQuestionsPhone,
      'USDA-food-safety-questions-email': usdaFoodSafetyQuestionsEmail,
      'recall_resolution_status': recallResolutionStatus,
      // NHTSA-specific fields
      'nhtsa_recall_id': nhtsaRecallId,
      'nhtsa_campaign_number': nhtsaCampaignNumber,
      'nhtsa_mfr_campaign_number': nhtsaMfrCampaignNumber,
      'nhtsa_component': nhtsaComponent,
      'nhtsa_recall_type': nhtsaRecallType,
      'nhtsa_potentially_affected': nhtsaPotentiallyAffected,
      'nhtsa_fire_risk': nhtsaFireRisk,
      'nhtsa_do_not_drive': nhtsaDoNotDrive,
      'nhtsa_completion_rate': nhtsaCompletionRate,
      'nhtsa_vehicle_make': nhtsaVehicleMake,
      'nhtsa_vehicle_model': nhtsaVehicleModel,
      'nhtsa_vehicle_year_start': nhtsaVehicleYearStart,
      'nhtsa_vehicle_year_end': nhtsaVehicleYearEnd,
      'nhtsa_vehicle_year_range': nhtsaVehicleYearRange,
      'remedy_ota_update': remedyOtaUpdate,
      'nhtsa_planned_dealer_notification_date':
          nhtsaPlannedDealerNotificationDate?.toIso8601String() ?? '',
      'nhtsa_planned_owner_notification_date':
          nhtsaPlannedOwnerNotificationDate?.toIso8601String() ?? '',
      'nhtsa_owner_notification_letter_mailed_date':
          nhtsaOwnerNotificationLetterMailedDate?.toIso8601String() ?? '',
      'nhtsa_manuf_phone': nhtsaManufPhone,
      'nhtsa_model_num': nhtsaModelNum,
      'nhtsa_upc': nhtsaUpc,
      // CPSC-specific fields
      'remedy_recall_proof': cpscRemedyRecallProof,
      'model': cpscModel,
      'sn': cpscSerialNumber,
      'sold_by_date_start': cpscSoldByDateStart?.toIso8601String() ?? '',
      'sold_by_date_end': cpscSoldByDateEnd?.toIso8601String() ?? '',
      'sold_by_walmart': cpscSoldByWalmart,
      'sold_by_amazon': cpscSoldByAmazon,
      'sold_by_ebay': cpscSoldByEbay,
      'sold_by_aliexpress': cpscSoldByAliExpress,
      'sold_by_bestbuy': cpscSoldByBestBuy,
      'sold_by_target': cpscSoldByTarget,
      'sold_by_tiktok': cpscSoldByTikTok,
      'sold_by_facebook': cpscSoldByFacebook,
      'sold_by_etsy': cpscSoldByEtsy,
      'sold_by_costco': cpscSoldByCostco,
      'sold_by_samsclub': cpscSoldBySamsClub,
      'sold_by_dickssportinggoods': cpscSoldByDicksSportingGoods,
      'sold_by_officedepot': cpscSoldByOfficeDepot,
      'sold_by_kroger': cpscSoldByKroger,
      'sold_by_publix': cpscSoldByPublix,
    };
  }

  /// Get the primary image URL, prioritizing uploaded images from admin panel
  /// Falls back to CSV image URLs if no uploaded images exist
  String getPrimaryImageUrl() {
    // Priority 1: Use uploaded images from admin panel
    if (images.isNotEmpty) {
      final url = _makeAbsoluteUrl(images.first.imageUrl);
      return url;
    }

    // Priority 2: Use image_url field (from CSV or direct entry)
    if (imageUrl.isNotEmpty) {
      final url = _makeAbsoluteUrl(imageUrl);
      return url;
    }

    // No images available
    return '';
  }

  /// Get optimized image URL for specific context
  /// Returns thumbnail, medium, or high-res version with fallback to original
  String getImageUrlForContext(ImageSize size) {
    switch (size) {
      case ImageSize.thumbnail:
        return imageThumbnail.isNotEmpty ? imageThumbnail : imageUrl;
      case ImageSize.medium:
        return imageMedium.isNotEmpty ? imageMedium : imageUrl;
      case ImageSize.highRes:
        return imageHighRes.isNotEmpty ? imageHighRes : imageUrl;
    }
  }

  /// Convert relative URLs to absolute URLs
  static String _makeAbsoluteUrl(String url) {
    if (url.isEmpty) return '';

    // If already absolute, return as-is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Convert relative path to absolute URL using mediaBaseUrl
    // Media files are served from the domain root, not from /api/
    final baseUrl = AppConfig.mediaBaseUrl;

    if (url.startsWith('/')) {
      return '$baseUrl$url';
    } else {
      return '$baseUrl/$url';
    }
  }

  /// Get all available image URLs (both uploaded and CSV-based)
  List<String> getAllImageUrls() {
    List<String> urls = [];

    // Add all uploaded images first
    for (var img in images) {
      if (img.imageUrl.isNotEmpty) {
        final absoluteUrl = _makeAbsoluteUrl(img.imageUrl);
        urls.add(absoluteUrl);
      }
    }

    // Add CSV image URLs
    if (imageUrl.isNotEmpty) {
      final absoluteUrl = _makeAbsoluteUrl(imageUrl);
      urls.add(absoluteUrl);
    }
    if (imageUrl2.isNotEmpty) {
      final absoluteUrl = _makeAbsoluteUrl(imageUrl2);
      urls.add(absoluteUrl);
    }
    if (imageUrl3.isNotEmpty) {
      final absoluteUrl = _makeAbsoluteUrl(imageUrl3);
      urls.add(absoluteUrl);
    }
    if (imageUrl4.isNotEmpty) {
      final absoluteUrl = _makeAbsoluteUrl(imageUrl4);
      urls.add(absoluteUrl);
    }
    if (imageUrl5.isNotEmpty) {
      final absoluteUrl = _makeAbsoluteUrl(imageUrl5);
      urls.add(absoluteUrl);
    }

    return urls;
  }
}
