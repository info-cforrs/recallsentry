import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import '../models/recall_data.dart';

class GoogleSheetsService {
  static const String _credentialsPath =
      'assets/credentials/service-account.json';
  static String? _spreadsheetId; // We'll set this later

  late GSheets _gsheets;
  late Worksheet _worksheet;
  bool _isInitialized = false;

  // Initialize the service with your spreadsheet ID
  Future<void> init(String spreadsheetId) async {
    try {
      _spreadsheetId = spreadsheetId;

      // Load the service account credentials
      final credentialsJson = await rootBundle.loadString(_credentialsPath);

      // Initialize GSheets with credentials
      _gsheets = GSheets(credentialsJson);

      // Get the spreadsheet
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId!);

      // Get the first worksheet (or create one called 'Recalls')
      _worksheet =
          spreadsheet.worksheetByTitle('Recalls') ??
          await spreadsheet.addWorksheet('Recalls');

      // Set up headers if this is a new sheet
      await _setupHeaders();

      _isInitialized = true;
      print('✅ Google Sheets service initialized successfully!');
    } catch (e) {
      print('❌ Error initializing Google Sheets service: $e');
      throw Exception('Failed to initialize Google Sheets: $e');
    }
  }

  // Set up the header row in the spreadsheet
  Future<void> _setupHeaders() async {
    try {
      final firstRow = await _worksheet.values.row(1);

      // If the first row is empty, add headers
      if (firstRow.isEmpty || firstRow.every((cell) => cell.isEmpty)) {
        await _worksheet.values.insertRow(1, [
          // FDA-only fields (added at the top for clarity)
          'recall_reason_short',
          'press_release_link',
          'product_type_detail',
          'product_size_weight',
          'how_found',
          'distribution_pattern',
          'recalling_firm',
          'firm_contact_name',
          'firm_contact_phone',
          'firm_contact_business_hours_days',
          'firm_contact_email',
          'firm_contact_web_site',
          'firm_web_site_info',
          // Existing fields
          'recall_url',
          'USDARecallID',
          'FIELD_RECALL_NUMBER',
          'Product Name',
          'Brand Name',
          'Risk Level',
          'Date Issued',
          'Agency',
          'Description',
          'Recall_Reason',
          'Recall_Classification',
          'Image URL',
          'Image_URL2',
          'Image_URL3',
          'Image_URL4',
          'Image_URL5',
          'State_Count',
          'Negative_Outcomes',
          'PACKAGING_DESC',
          'Remedy-Return',
          'Remedy-Repair',
          'Remedy-Replace',
          'Remedy-Dispose',
          'Remedy-N/A',
          'Product_Qty',
          'Sold_by',
          'PRODUCTION_DATE_START',
          'PRODUCTION_DATE_END',
          'BEST_USED_BY_DATE',
          'BEST_USED_BY_DATE_END',
          'EXP_DATE',
          'BATCH-LOT_CODE',
          'UPC',
          'Reports_of_Injury',
          'DISTRIBUTION_DATE_START',
          'DISTRIBUTION_DATE_END',
          'ITEM_NUM_CODE',
          'FIRM_CONTACT_FORM',
          'establishment-manufacturer-contact-form',
          'DISTRIBUTOR',
          'PRODUCT_IDENTIFICATION',
          'RECALL_PHA_REASON',
          // --- New USDA fields ---
          'SELL_BY_DATE',
          'SKU',
          'ADVERSE_REACTIONS',
          'ADVERSE_REACTION_DETAILS',
          'RECOMMENDATIONS_ACTIONS',
          'REMEDY',
          'PRODUCT_DISTRIBUTION',
          'establishment-manufacturer',
          'establishment-manufacturer-contact-name',
          'establishment-manufacturer-contact-phone',
          'establishment_manufacturer-CONTACT_BUSINESS_HOURS_DAYS',
          'establishment-manufacturer-contact-email',
          'establishment-manufacturer-website',
          'establishment-manufacturer-website-info',
          'Retailer1',
          'RETAILER1_SALE_DATE_START',
          'RETAILER1_SALE_DATE_END',
          'RETAILER1_CONTACT_NAME',
          'RETAILER1_CONTACT_PHONE',
          'RETAILER1_CONTACT_BUSINESS_HOURS_DAYS',
          'RETAILER1_CONTACT_EMAIL',
          'RETAILER1_CONTACT_WEB_SITE',
          'RETAILER1_WEB_SITE_INFO',
          'EST_ITEM_VALUE',
          'USDA-To-report-a-problem',
          'USDA-food-safety-questions-phone',
          'USDA-food-safety-questions-email',
        ]);
        print('📝 Headers added to spreadsheet');
      }
    } catch (e) {
      print('⚠️ Warning: Could not set up headers: $e');
    }
  }

  // Fetch all recalls from the spreadsheet
  Future<List<RecallData>> fetchRecalls() async {
    if (!_isInitialized) {
      throw Exception(
        'Google Sheets service not initialized. Call init() first.',
      );
    }

    try {
      final allRows = await _worksheet.values.allRows();
      final recalls = <RecallData>[];

      print('📊 Found ${allRows.length} rows in spreadsheet');
      if (allRows.isNotEmpty) {
        print('📋 Header row: ${allRows[0]}');
      }

      // Build header-to-index map for robust column mapping
      Map<String, int> headerMap = {};
      if (allRows.isNotEmpty) {
        final headers = allRows[0];
        for (int i = 0; i < headers.length; i++) {
          headerMap[headers[i].toString().trim().toLowerCase()] = i;
        }
        print('📋 Header map: $headerMap');
      }

      // Define header keys for all fields (FDA and USDA)
      const headerKeys = {
        'reportsOfInjury': ['Reports_of_Injury', 'reports_of_injury'],
        'distributionDateStart': [
          'DISTRIBUTION_DATE_START',
          'distribution_date_start',
        ],
        'distributionDateEnd': [
          'DISTRIBUTION_DATE_END',
          'distribution_date_end',
        ],
        'bestUsedByDateEnd': ['BEST_USED_BY_DATE_END', 'best_used_by_date_end'],
        'itemNumCode': ['ITEM_NUM_CODE', 'item_num_code'],
        'firmContactForm': ['FIRM_CONTACT_FORM', 'firm_contact_form'],
        'establishmentManufacturerContactForm': [
          'establishment-manufacturer-contact-form',
        ],
        'distributor': ['DISTRIBUTOR', 'distributor'],
        'sku': ['sku', 'SKU'],
        // FDA date fields
        'packagedOnDate': [
          'packaged_on_date',
          'packaged on date',
          'Packaged On Date',
          'PACKAGED_ON_DATE',
        ],
        'sellByDate': [
          'sell_by_date',
          'sell by date',
          'Sell By Date',
          'SELL_BY_DATE',
        ],
        'recallReason': ['recall_reason', 'Recall_Reason', 'recall reason'],
        'recallUrl': ['recall_url', 'recall url', 'Recall_URL'],
        'productDistribution': ['product_distribution', 'PRODUCT_DISTRIBUTION'],
        'adverseReactions': [
          'adverse_reactions',
          'adverse reactions',
          'ADVERSE_REACTIONS',
        ],
        'adverseReactionDetails': [
          'adverse_reaction_details',
          'adverse reaction details',
          'ADVERSE_REACTION_DETAILS',
        ],
        'usdaRecallId': ['USDARecallID', 'usdaRecallId', 'ID'],
        'fieldRecallNumber': [
          'field_recall_number',
          'field recall number',
          'FIELD_RECALL_NUMBER',
        ],
        'productName': ['product name', 'product label text', 'product_name'],
        'imageUrl': ['image_url', 'image url', 'Image_URL'],
        'imageUrl2': ['image_url2', 'image url2', 'Image_URL2'],
        'imageUrl3': ['image_url3', 'image url3', 'Image_URL3'],
        'imageUrl4': ['image_url4', 'image url4', 'Image_URL4'],
        'imageUrl5': ['image_url5', 'image url5', 'Image_URL5'],
        'brandName': ['brand name', 'brand_name'],
        'riskLevel': ['risk level', 'risk_level'],
        'dateIssued': ['date issued', 'date_issued', 'date'],
        'agency': ['agency'],
        'description': ['description'],
        'category': ['recall_reason', 'recall reason', 'category'],
        'recallClassification': [
          'recall_classification',
          'recall classification',
        ],
        'stateCount': ['state_count', 'state count'],
        'negativeOutcomes': [
          'negative outcomes',
          'negative_outcomes',
          'health hazard',
        ],
        'packagingDesc': ['packaging_desc', 'packaging desc'],
        'remedyReturn': ['remedy-return', 'remedy return'],
        'remedyRepair': ['remedy-repair', 'remedy repair'],
        'remedyReplace': ['remedy-replace', 'remedy replace'],
        'remedyDispose': ['remedy-dispose', 'remedy dispose'],
        'remedyNA': ['remedy-n/a', 'remedy n/a'],
        'productQty': ['product_qty', 'product qty'],
        'soldBy': ['sold_by', 'sold by'],
        // USDA new fields
        'productionDateStart': [
          'production_date_start',
          'production date start',
          'production start',
        ],
        'productionDateEnd': [
          'production_date_end',
          'production date end',
          'production end',
        ],
        'bestUsedByDate': ['best_used_by_date', 'best used by date', 'best by', 'BEST_USED_BY_DATE'],
        'expDate': ['exp_date', 'exp date', 'expiration date'],
        'batchLotCode': ['batch-lot_code', 'batch lot code', 'batch', 'lot'],
        'upc': ['upc', 'upc code'],
        // FDA-specific fields
        'recallNumber': ['recall number', 'recall_number'],
        'recallingFdaFirm': [
          'recalling_fda_firm',
          'RECALLING_FDA_FIRM',
          'recalling firm',
          'recalling_firm',
        ],
        'codeInfo': ['code info', 'code_info'],
        'distributionPattern': ['distribution pattern', 'distribution_pattern'],
        'voluntaryMandated': ['voluntary/mandated', 'voluntary_mandated'],
        'initialFirmNotification': [
          'initial firm notification',
          'initial_firm_notification',
        ],
        'reportDate': ['report date', 'report_date'],
        'classification': ['classification'],
        'centerClassificationDate': [
          'center classification date',
          'center_classification_date',
        ],
        'reasonForRecall': ['reason for recall', 'reason_for_recall'],
        'productType': ['product type', 'product_type'],
        'country': ['country'],
        'state': ['state'],
        'city': ['city'],
        'status': ['status'],
        'productIdentification': [
          'product_identification',
          'PRODUCT_IDENTIFICATION',
        ],
        'recallPhaReason': ['recall_pha_reason', 'RECALL_PHA_REASON'],
        // USDA Recommendations fields
        'recommendationsActions': [
          'recommendations_actions',
          'recommendations actions',
          'RECOMMENDATIONS_ACTIONS',
          'recommendations',
        ],
        'remedy': ['remedy', 'remedy actions', 'REMEDY'],

        // Manufacturer fields
        'establishmentManufacturer': [
          'establishment-manufacturer',
          'establishment manufacturer',
          'establishment_manufacturer',
        ],
        'establishmentManufacturerContactName': [
          'establishment-manufacturer-contact-name',
          'establishment manufacturer contact name',
          'establishment_manufacturer_contact_name',
        ],
        'establishmentManufacturerContactPhone': [
          'establishment-manufacturer-contact-phone',
          'establishment manufacturer contact phone',
          'establishment_manufacturer_contact_phone',
        ],
        'establishmentManufacturerContactBusinessHoursDays': [
          'establishment_manufacturer-contact_business_hours_days',
          'establishment manufacturer contact business hours days',
          'establishment-manufacturer-contact-business-hours-days',
          'establishment-manufacturer-contact-business-hours/days',
        ],
        'establishmentManufacturerContactEmail': [
          'establishment-manufacturer-contact-email',
          'establishment manufacturer contact email',
          'establishment_manufacturer_contact_email',
        ],
        'establishmentManufacturerWebsite': [
          'establishment-manufacturer-website',
          'establishment manufacturer website',
          'establishment_manufacturer_website',
        ],
        'establishmentManufacturerWebsiteInfo': [
          'establishment-manufacturer-website-info',
          'establishment manufacturer website info',
          'establishment_manufacturer_website_info',
        ],

        // Retailer fields
        'retailer1': ['retailer1', 'retailer 1', 'RETAILER1'],
        'retailer1SaleDateStart': [
          'retailer1_sale_date_start',
          'retailer1 sale date start',
          'RETAILER1_SALE_DATE_START',
        ],
        'retailer1SaleDateEnd': [
          'retailer1_sale_date_end',
          'retailer1 sale date end',
          'RETAILER1_SALE_DATE_END',
        ],
        'retailer1ContactName': [
          'retailer1_contact_name',
          'retailer1 contact name',
          'RETAILER1_CONTACT_NAME',
        ],
        'retailer1ContactPhone': [
          'retailer1_contact_phone',
          'retailer1 contact phone',
          'RETAILER1_CONTACT_PHONE',
        ],
        'retailer1ContactBusinessHoursDays': [
          'retailer1_contact_business_hours_days',
          'retailer1 contact business hours days',
          'RETAILER1_CONTACT_BUSINESS_HOURS_DAYS',
        ],
        'retailer1ContactEmail': [
          'retailer1_contact_email',
          'retailer1 contact email',
          'RETAILER1_CONTACT_EMAIL',
        ],
        'retailer1ContactWebSite': [
          'retailer1_contact_web_site',
          'retailer1 contact web site',
          'RETAILER1_CONTACT_WEB_SITE',
        ],
        'retailer1WebSiteInfo': [
          'retailer1_web_site_info',
          'retailer1 web site info',
          'RETAILER1_WEB_SITE_INFO',
        ],
        'estItemValue': ['est_item_value', 'est item value', 'EST_ITEM_VALUE'],
      };

      // Helper to get value by header keys
      String getValue(List<String> keys, List row) {
        for (final key in keys) {
          final idx = headerMap[key.toLowerCase()];
          if (idx != null && idx < row.length) {
            return row[idx] ?? '';
          }
        }
        return '';
      }

      int getIntValue(List<String> keys, List row) {
        final val = getValue(keys, row);
        return int.tryParse(val) ?? 0;
      }

      // Skip the header row (index 0)
      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        print('📄 Row $i: $row');

        // Only require ID and Date for FDA/USDA rows (not Product Name)
        if (row.isNotEmpty) {
          try {
            final agency = getValue(headerKeys['agency']!, row).toUpperCase();
            final fdaRecallId = getValue([
              'fdarecallid',
              'FDARecallID',
              'ID',
            ], row);
            final usdaRecallId = getValue(headerKeys['usdaRecallId']!, row);
            final productName = getValue(headerKeys['productName']!, row);
            final dateHeaderCandidates = headerKeys['dateIssued']!;
            String foundDateHeader = '';
            String dateStr = '';
            for (final key in dateHeaderCandidates) {
              final idx = headerMap[key.toLowerCase()];
              if (idx != null && idx < row.length) {
                foundDateHeader = key;
                dateStr = row[idx].toString();
                break;
              }
            }
            print(
              '🟡 Row ${i + 1}: agency=$agency, fdaRecallId=$fdaRecallId, usdaRecallId=$usdaRecallId, productName="$productName", dateHeader="$foundDateHeader", dateStr="$dateStr"',
            );
            bool skip = false;
            if (agency == 'FDA') {
              if (fdaRecallId.isEmpty || dateStr.isEmpty) {
                print(
                  '⚠️ Warning: Skipping row ${i + 1} - missing required data (FDARecallID or Date)',
                );
                skip = true;
              }
            } else if (agency == 'USDA') {
              if (usdaRecallId.isEmpty || dateStr.isEmpty) {
                print(
                  '⚠️ Warning: Skipping row ${i + 1} - missing required data (USDARecallID or Date)',
                );
                skip = true;
              }
            } else {
              if (dateStr.isEmpty) {
                print(
                  '⚠️ Warning: Skipping row ${i + 1} - missing required data (Date)',
                );
                skip = true;
              }
            }
            if (skip) continue;

            final parsedDate = _parseDate(dateStr);
            print('🟡 Row ${i + 1}: parsedDate=$parsedDate');
            if (parsedDate == null) {
              print(
                '⚠️ Warning: Skipping row ${i + 1} - invalid date format: "$dateStr"',
              );
              continue;
            }

            final recall = RecallData(
              reportsOfInjury: getValue(headerKeys['reportsOfInjury']!, row),
              distributionDateStart: getValue(
                headerKeys['distributionDateStart']!,
                row,
              ),
              distributionDateEnd: getValue(
                headerKeys['distributionDateEnd']!,
                row,
              ),
              bestUsedByDateEnd: getValue(
                headerKeys['bestUsedByDateEnd']!,
                row,
              ),
              itemNumCode: getValue(headerKeys['itemNumCode']!, row),
              firmContactForm: getValue(headerKeys['firmContactForm']!, row),
              establishmentManufacturerContactForm: getValue(
                headerKeys['establishmentManufacturerContactForm']!,
                row,
              ),
              distributor: getValue(headerKeys['distributor']!, row),
              sku: getValue(headerKeys['sku']!, row),
              // FDA-only fields
              fdaRecallId: fdaRecallId,
              recallReasonShort: getValue(['recall_reason_short'], row),
              pressReleaseLink: getValue(['press_release_link'], row),
              productTypeDetail: getValue(['product_type_detail'], row),
              productSizeWeight: getValue(['product_size_weight'], row),
              howFound: getValue(['how_found'], row),
              distributionPattern: getValue(['distribution_pattern'], row),
              recallingFdaFirm: getValue(headerKeys['recallingFdaFirm']!, row),
              firmContactName: getValue(['firm_contact_name'], row),
              firmContactPhone: getValue(['firm_contact_phone'], row),
              firmContactBusinessHoursDays: getValue([
                'firm_contact_business_hours_days',
              ], row),
              firmContactEmail: getValue(['firm_contact_email'], row),
              firmContactWebSite: getValue(['firm_contact_web_site'], row),
              firmWebSiteInfo: getValue(['firm_web_site_info'], row),
              // Existing fields
              recallUrl: getValue(headerKeys['recallUrl']!, row),
              usdaRecallId: usdaRecallId,
              id: usdaRecallId,
              fieldRecallNumber: getValue(
                headerKeys['fieldRecallNumber']!,
                row,
              ),
              productName: productName,
              brandName: getValue(headerKeys['brandName']!, row),
              riskLevel: getValue(headerKeys['riskLevel']!, row),
              dateIssued: parsedDate,
              agency: getValue(headerKeys['agency']!, row),
              description: getValue(headerKeys['description']!, row),
              category: getValue(headerKeys['category']!, row),
              recallReason: getValue(headerKeys['recallReason']!, row),
              recallClassification: getValue(
                headerKeys['recallClassification']!,
                row,
              ),
              imageUrl: getValue(headerKeys['imageUrl']!, row),
              imageUrl2: getValue(headerKeys['imageUrl2']!, row),
              imageUrl3: getValue(headerKeys['imageUrl3']!, row),
              imageUrl4: getValue(headerKeys['imageUrl4']!, row),
              imageUrl5: getValue(headerKeys['imageUrl5']!, row),
              stateCount: getIntValue(headerKeys['stateCount']!, row),
              negativeOutcomes: getValue(headerKeys['negativeOutcomes']!, row),
              packagingDesc: getValue(headerKeys['packagingDesc']!, row),
              remedyReturn: getValue(headerKeys['remedyReturn']!, row),
              remedyRepair: getValue(headerKeys['remedyRepair']!, row),
              remedyReplace: getValue(headerKeys['remedyReplace']!, row),
              remedyDispose: getValue(headerKeys['remedyDispose']!, row),
              remedyNA: getValue(headerKeys['remedyNA']!, row),
              productQty: getValue(headerKeys['productQty']!, row),
              soldBy: getValue(headerKeys['soldBy']!, row),
              productionDateStart:
                  getValue(headerKeys['productionDateStart']!, row).isNotEmpty
                  ? _parseDate(
                      getValue(headerKeys['productionDateStart']!, row),
                    )
                  : null,
              productionDateEnd:
                  getValue(headerKeys['productionDateEnd']!, row).isNotEmpty
                  ? _parseDate(getValue(headerKeys['productionDateEnd']!, row))
                  : null,
              bestUsedByDate: getValue(headerKeys['bestUsedByDate']!, row),
              expDate: getValue(headerKeys['expDate']!, row),
              batchLotCode: getValue(headerKeys['batchLotCode']!, row),
              upc: getValue(headerKeys['upc']!, row),
              productIdentification: getValue(
                headerKeys['productIdentification']!,
                row,
              ),
              recallPhaReason: getValue(headerKeys['recallPhaReason']!, row),
              adverseReactions: getValue(headerKeys['adverseReactions']!, row),
              adverseReactionDetails: getValue(
                headerKeys['adverseReactionDetails']!,
                row,
              ),
              recommendationsActions: getValue(
                headerKeys['recommendationsActions']!,
                row,
              ),
              remedy: getValue(headerKeys['remedy']!, row),
              productDistribution: getValue(
                headerKeys['productDistribution']!,
                row,
              ),
              establishmentManufacturer: getValue(
                headerKeys['establishmentManufacturer']!,
                row,
              ),
              establishmentManufacturerContactName: getValue(
                headerKeys['establishmentManufacturerContactName']!,
                row,
              ),
              establishmentManufacturerContactPhone: getValue(
                headerKeys['establishmentManufacturerContactPhone']!,
                row,
              ),
              establishmentManufacturerContactBusinessHoursDays: getValue(
                headerKeys['establishmentManufacturerContactBusinessHoursDays']!,
                row,
              ),
              establishmentManufacturerContactEmail: getValue(
                headerKeys['establishmentManufacturerContactEmail']!,
                row,
              ),
              establishmentManufacturerWebsite: getValue(
                headerKeys['establishmentManufacturerWebsite']!,
                row,
              ),
              establishmentManufacturerWebsiteInfo: getValue(
                headerKeys['establishmentManufacturerWebsiteInfo']!,
                row,
              ),
              retailer1: getValue(headerKeys['retailer1']!, row),
              retailer1SaleDateStart: getValue(
                headerKeys['retailer1SaleDateStart']!,
                row,
              ),
              retailer1SaleDateEnd: getValue(
                headerKeys['retailer1SaleDateEnd']!,
                row,
              ),
              retailer1ContactName: getValue(
                headerKeys['retailer1ContactName']!,
                row,
              ),
              retailer1ContactPhone: getValue(
                headerKeys['retailer1ContactPhone']!,
                row,
              ),
              retailer1ContactBusinessHoursDays: getValue(
                headerKeys['retailer1ContactBusinessHoursDays']!,
                row,
              ),
              retailer1ContactEmail: getValue(
                headerKeys['retailer1ContactEmail']!,
                row,
              ),
              retailer1ContactWebSite: getValue(
                headerKeys['retailer1ContactWebSite']!,
                row,
              ),
              retailer1WebSiteInfo: getValue(
                headerKeys['retailer1WebSiteInfo']!,
                row,
              ),
              estItemValue: getValue(headerKeys['estItemValue']!, row),
              usdaToReportAProblem: getValue(['USDA-To-report-a-problem'], row),
              usdaFoodSafetyQuestionsPhone: getValue([
                'USDA-food-safety-questions-phone',
              ], row),
              usdaFoodSafetyQuestionsEmail: getValue([
                'USDA-food-safety-questions-email',
              ], row),
              packagedOnDate: getValue(headerKeys['packagedOnDate']!, row),
              sellByDate: getValue(headerKeys['sellByDate']!, row),
            );
            recalls.add(recall);
            print(
              '✅ Added recall: ${recall.id} - ${recall.productName} - Agency: ${recall.agency} - Date: ${recall.dateIssued}',
            );
          } catch (e) {
            print('⚠️ Warning: Skipping invalid row ${i + 1}: $e');
          }
        } else {
          print('⚠️ Warning: Row ${i + 1} is empty');
        }
      }

      print('📊 Fetched ${recalls.length} recalls from spreadsheet');
      return recalls;
    } catch (e) {
      print('❌ Error fetching recalls: $e');
      throw Exception('Failed to fetch recalls: $e');
    }
  }

  // Add a new recall to the spreadsheet
  Future<void> addRecall(RecallData recall) async {
    if (!_isInitialized) {
      throw Exception(
        'Google Sheets service not initialized. Call init() first.',
      );
    }

    try {
      await _worksheet.values.appendRow([
        // FDA-only fields (must match header order)
        recall.recallReasonShort,
        recall.pressReleaseLink,
        recall.productTypeDetail,
        recall.productSizeWeight,
        recall.howFound,
        recall.distributionPattern,
        recall.recallingFdaFirm,
        recall.firmContactName,
        recall.firmContactPhone,
        recall.firmContactBusinessHoursDays,
        recall.firmContactEmail,
        recall.firmContactWebSite,
        recall.firmWebSiteInfo,
        // Existing fields
        recall.recallUrl,
        recall.fdaRecallId.isNotEmpty
            ? recall.fdaRecallId
            : recall.usdaRecallId,
        recall.fieldRecallNumber,
        recall.productName,
        recall.brandName,
        recall.riskLevel,
        recall.dateIssued.toIso8601String().split('T')[0],
        recall.agency,
        recall.description,
        recall.category,
        recall.recallReason,
        recall.recallClassification,
        recall.imageUrl,
        recall.imageUrl2,
        recall.imageUrl3,
        recall.imageUrl4,
        recall.imageUrl5,
        recall.stateCount.toString(),
        recall.negativeOutcomes,
        recall.packagingDesc,
        recall.remedyReturn,
        recall.remedyRepair,
        recall.remedyReplace,
        recall.remedyDispose,
        recall.remedyNA,
        recall.productQty,
        recall.soldBy,
        recall.productionDateStart != null
            ? recall.productionDateStart!.toIso8601String().split('T')[0]
            : '',
        recall.productionDateEnd != null
            ? recall.productionDateEnd!.toIso8601String().split('T')[0]
            : '',
        recall.bestUsedByDate,
        recall.bestUsedByDateEnd,
        recall.expDate,
        recall.batchLotCode,
        recall.upc,
        recall.reportsOfInjury,
        recall.distributionDateStart,
        recall.distributionDateEnd,
        recall.itemNumCode,
        recall.firmContactForm,
        recall.establishmentManufacturerContactForm,
        recall.distributor,
        recall.productIdentification,
        recall.recallPhaReason,
        // --- New USDA fields ---
        recall.sellByDate,
        recall.sku,
        recall.adverseReactions,
        recall.adverseReactionDetails,
        recall.recommendationsActions,
        recall.remedy,
        recall.productDistribution,
        recall.establishmentManufacturer,
        recall.establishmentManufacturerContactName,
        recall.establishmentManufacturerContactPhone,
        recall.establishmentManufacturerContactBusinessHoursDays,
        recall.establishmentManufacturerContactEmail,
        recall.establishmentManufacturerWebsite,
        recall.establishmentManufacturerWebsiteInfo,
        recall.retailer1,
        recall.retailer1SaleDateStart,
        recall.retailer1SaleDateEnd,
        recall.retailer1ContactName,
        recall.retailer1ContactPhone,
        recall.retailer1ContactBusinessHoursDays,
        recall.retailer1ContactEmail,
        recall.retailer1ContactWebSite,
        recall.retailer1WebSiteInfo,
        recall.estItemValue,
        recall.usdaToReportAProblem,
        recall.usdaFoodSafetyQuestionsPhone,
        recall.usdaFoodSafetyQuestionsEmail,
      ]);

      print('✅ Added recall: ${recall.productName}');
    } catch (e) {
      print('❌ Error adding recall: $e');
      throw Exception('Failed to add recall: $e');
    }
  }

  // Helper method to parse date strings - returns null if parsing fails
  DateTime? _parseDate(String? dateString) {
    print('📅 Parsing date string: "$dateString"');

    if (dateString == null || dateString.isEmpty) {
      print('📅 Empty date string, cannot parse');
      return null;
    }

    try {
      // Try parsing as Excel serial date number first
      final serialNumber = double.tryParse(dateString);
      if (serialNumber != null && serialNumber > 0) {
        // Excel serial date: January 1, 1900 is day 1
        // Convert Excel serial number to DateTime
        // Excel base date is 1900-01-01, but Excel incorrectly treats 1900 as a leap year
        final baseDate = DateTime(
          1899,
          12,
          30,
        ); // Excel day 1 is actually 1900-01-01
        final daysToAdd = serialNumber.floor();
        final parsedDate = baseDate.add(Duration(days: daysToAdd));
        print(
          '📅 Successfully parsed Excel serial date $serialNumber: $parsedDate',
        );
        return parsedDate;
      }
    } catch (e) {
      // Continue to other parsing methods
    }

    try {
      // Try parsing ISO format
      final parsedDate = DateTime.parse(dateString);
      print('📅 Successfully parsed ISO date: $parsedDate');
      return parsedDate;
    } catch (e) {
      // If parsing fails, try common date formats
      try {
        // Try MM/DD/YYYY format
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final month = int.parse(parts[0]);
          final day = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final parsedDate = DateTime(year, month, day);
          print('📅 Successfully parsed MM/DD/YYYY date: $parsedDate');
          return parsedDate;
        }
      } catch (e2) {
        try {
          // Try DD/MM/YYYY format
          final parts = dateString.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final parsedDate = DateTime(year, month, day);
            print('📅 Successfully parsed DD/MM/YYYY date: $parsedDate');
            return parsedDate;
          }
        } catch (e3) {
          try {
            // Try YYYY-MM-DD format
            final parts = dateString.split('-');
            if (parts.length == 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              final parsedDate = DateTime(year, month, day);
              print('📅 Successfully parsed YYYY-MM-DD date: $parsedDate');
              return parsedDate;
            }
          } catch (e4) {
            // If all parsing fails, return null
            print('⚠️ Warning: Could not parse date "$dateString"');
            return null;
          }
        }
      }
    }

    // Fallback return null (should never reach here due to the structure above)
    return null;
  }

  // Check if the service is ready to use
  bool get isInitialized => _isInitialized;

  // Get the current spreadsheet ID
  String? get spreadsheetId => _spreadsheetId;
}
