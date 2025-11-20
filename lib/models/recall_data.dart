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
    );
  }

  // This converts a RecallData object TO a format for spreadsheet/JSON storage
  Map<String, dynamic> toJson() {
    return {
      'FDARecallID': fdaRecallId,
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

    // Convert relative path to absolute URL
    // Media files are served from the domain root, not from /api/
    // So we need to extract the base domain from apiBaseUrl
    final apiBaseUrl = AppConfig.apiBaseUrl;
    final baseUrl = apiBaseUrl.endsWith('/api')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 4)
        : apiBaseUrl;

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
