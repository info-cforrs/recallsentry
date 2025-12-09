/// Recall Test Fixtures
///
/// Sample recall data for all supported agencies (FDA, USDA, CPSC, NHTSA).
library;

/// Sample recall data for testing
class RecallFixtures {
  /// FDA recall sample
  static Map<String, dynamic> get fdaRecallSample => {
        'id': 1,
        'recall_id': 'FDA-2024-001',
        'product_name': 'Organic Peanut Butter',
        'brand_name': 'NuttyHealth',
        'risk_level': 'HIGH',
        'date_issued': '2024-01-15T00:00:00Z',
        'agency': 'FDA',
        'description': 'Potential salmonella contamination in peanut butter products.',
        'category': 'Food',
        'recall_classification': 'Class I',
        'image_url': 'https://example.com/images/peanut-butter.jpg',
        'image_url2': '',
        'image_url3': '',
        'state_count': 15,
        'negative_outcomes': 'Salmonella infection, hospitalization',
        'packaging_desc': '16 oz jar',
        'remedy_return': true,
        'remedy_repair': false,
        'remedy_replace': true,
        'remedy_dispose': false,
        'remedy_na': false,
        'product_qty': '50000 units',
        'sold_by': 'Grocery stores nationwide',
        'production_date_start': '2024-01-01',
        'production_date_end': '2024-01-10',
        'best_used_by_date': '2025-01-01',
        'batch_lot_code': 'LOT-2024-A1',
        'upc': '012345678901',
        'recall_reason': 'Potential salmonella contamination',
        'recall_reason_short': 'Salmonella risk',
        'recalling_firm': 'NuttyHealth Foods Inc.',
        'firm_contact_phone': '1-800-555-0123',
        'firm_contact_email': 'recall@nuttyhealth.com',
        'distribution_pattern': 'Nationwide',
        'recall_resolution_status': 'Not Started',
      };

  /// USDA recall sample
  static Map<String, dynamic> get usdaRecallSample => {
        'id': 2,
        'recall_id': 'USDA-2024-002',
        'product_name': 'Ground Beef 80/20',
        'brand_name': 'Prairie Farms',
        'risk_level': 'HIGH',
        'date_issued': '2024-02-20T00:00:00Z',
        'agency': 'USDA',
        'description': 'E. coli O157:H7 contamination in ground beef.',
        'category': 'Meat',
        'recall_classification': 'Class I',
        'image_url': 'https://example.com/images/ground-beef.jpg',
        'state_count': 25,
        'negative_outcomes': 'E. coli infection, hospitalization',
        'packaging_desc': '1 lb package',
        'remedy_return': true,
        'remedy_replace': false,
        'remedy_dispose': true,
        'product_qty': '100000 lbs',
        'sold_by': 'Major retailers',
        'establishment_name': 'Prairie Farms Processing',
        'establishment_number': 'EST-12345',
        'recall_reason': 'E. coli O157:H7 contamination',
        'recall_resolution_status': 'In Progress',
      };

  /// CPSC recall sample
  static Map<String, dynamic> get cpscRecallSample => {
        'id': 3,
        'recall_id': 'CPSC-2024-003',
        'product_name': 'Kids Power Wheels',
        'brand_name': 'SafeRide Toys',
        'risk_level': 'MEDIUM',
        'date_issued': '2024-03-10T00:00:00Z',
        'agency': 'CPSC',
        'description': 'Battery can overheat and pose fire hazard.',
        'category': 'Toys',
        'image_url': 'https://example.com/images/power-wheels.jpg',
        'state_count': 50,
        'negative_outcomes': 'Fire, burns',
        'packaging_desc': 'Boxed toy vehicle',
        'remedy_return': true,
        'remedy_repair': true,
        'remedy_replace': false,
        'remedy_dispose': false,
        'remedy_recall_proof': true,
        'product_qty': '75000 units',
        'model': 'PW-2024-RED',
        'sn': 'SN-RANGE-001-500',
        'sold_by_date_start': '2023-06-01',
        'sold_by_date_end': '2024-02-28',
        'sold_by_walmart': true,
        'sold_by_amazon': true,
        'sold_by_target': true,
        'sold_by_ebay': false,
        'sold_by_costco': false,
        'recall_reason': 'Battery overheating hazard',
        'recall_resolution_status': 'Not Started',
      };

  /// NHTSA vehicle recall sample
  static Map<String, dynamic> get nhtsaVehicleRecallSample => {
        'id': 4,
        'recall_id': 'NHTSA-2024-004',
        'product_name': 'Model X SUV',
        'brand_name': 'AutoMaker',
        'risk_level': 'HIGH',
        'date_issued': '2024-04-05T00:00:00Z',
        'agency': 'NHTSA',
        'description': 'Airbag inflator may rupture during deployment.',
        'category': 'Vehicles',
        'nhtsa_recall_id': 'NHTSA-2024-004',
        'nhtsa_campaign_number': '24V-123',
        'nhtsa_mfr_campaign_number': 'AM-2024-001',
        'nhtsa_component': 'Air Bags',
        'nhtsa_recall_type': 'Vehicle',
        'nhtsa_potentially_affected': 250000,
        'nhtsa_fire_risk': false,
        'nhtsa_do_not_drive': false,
        'nhtsa_completion_rate': '15%',
        'nhtsa_vehicle_make': 'AutoMaker',
        'nhtsa_vehicle_model': 'Model X',
        'nhtsa_vehicle_year_start': '2020',
        'nhtsa_vehicle_year_end': '2023',
        'nhtsa_vehicle_year_range': '2020-2023',
        'remedy_repair': true,
        'remedy_ota_update': false,
        'nhtsa_manuf_phone': '1-800-555-AUTO',
        'recall_reason': 'Airbag inflator may rupture',
        'recall_resolution_status': 'Not Started',
      };

  /// NHTSA tire recall sample
  static Map<String, dynamic> get nhtsaTireRecallSample => {
        'id': 5,
        'recall_id': 'NHTSA-2024-005',
        'product_name': 'All-Season Radial Tire',
        'brand_name': 'TireMax',
        'risk_level': 'MEDIUM',
        'date_issued': '2024-05-15T00:00:00Z',
        'agency': 'NHTSA',
        'description': 'Tread separation may occur at highway speeds.',
        'category': 'Tires',
        'nhtsa_recall_type': 'Tire',
        'nhtsa_potentially_affected': 50000,
        'nhtsa_model_num': 'TM-AS-225',
        'nhtsa_upc': '098765432109',
        'remedy_replace': true,
        'recall_reason': 'Tread separation risk',
        'recall_resolution_status': 'Not Started',
      };

  /// NHTSA child seat recall sample
  static Map<String, dynamic> get nhtsaChildSeatRecallSample => {
        'id': 6,
        'recall_id': 'NHTSA-2024-006',
        'product_name': 'Infant Car Seat',
        'brand_name': 'SafeBaby',
        'risk_level': 'HIGH',
        'date_issued': '2024-06-01T00:00:00Z',
        'agency': 'NHTSA',
        'description': 'Harness buckle may not properly latch.',
        'category': 'Child Seats',
        'nhtsa_recall_type': 'Child Seat',
        'nhtsa_potentially_affected': 30000,
        'nhtsa_model_num': 'SB-INF-2024',
        'remedy_repair': true,
        'remedy_replace': true,
        'recall_reason': 'Harness buckle defect',
        'recall_resolution_status': 'Not Started',
      };

  /// Minimal recall with only required fields
  static Map<String, dynamic> get minimalRecall => {
        'id': 100,
        'product_name': 'Test Product',
        'brand_name': 'Test Brand',
        'risk_level': 'LOW',
        'date_issued': '2024-01-01T00:00:00Z',
        'agency': 'FDA',
        'description': 'Test description',
        'category': 'Other',
      };

  /// Recall with null/missing fields to test defaults
  static Map<String, dynamic> get recallWithNulls => {
        'id': 101,
        'product_name': 'Null Test Product',
        'brand_name': null,
        'risk_level': null,
        'date_issued': '2024-01-01T00:00:00Z',
        'agency': null,
        'description': null,
        'category': null,
        'image_url': null,
        'state_count': null,
        'remedy_return': null,
      };

  /// Recall with boolean remedy fields as booleans
  static Map<String, dynamic> get recallWithBooleanRemedies => {
        'id': 102,
        'product_name': 'Boolean Remedy Test',
        'brand_name': 'Test Brand',
        'risk_level': 'MEDIUM',
        'date_issued': '2024-01-01T00:00:00Z',
        'agency': 'FDA',
        'description': 'Testing boolean remedy conversion',
        'category': 'Food',
        'remedy_return': true,
        'remedy_repair': false,
        'remedy_replace': true,
        'remedy_dispose': false,
        'remedy_na': false,
      };

  /// Recall with string remedy fields
  static Map<String, dynamic> get recallWithStringRemedies => {
        'id': 103,
        'product_name': 'String Remedy Test',
        'brand_name': 'Test Brand',
        'risk_level': 'MEDIUM',
        'date_issued': '2024-01-01T00:00:00Z',
        'agency': 'FDA',
        'description': 'Testing string remedy conversion',
        'category': 'Food',
        'remedy_return': 'Y',
        'remedy_repair': '',
        'remedy_replace': 'Y',
        'remedy_dispose': '',
        'remedy_na': '',
      };

  /// List of sample recalls for pagination testing
  static List<Map<String, dynamic>> get recallList => [
        fdaRecallSample,
        usdaRecallSample,
        cpscRecallSample,
        nhtsaVehicleRecallSample,
        nhtsaTireRecallSample,
        nhtsaChildSeatRecallSample,
      ];

  /// API response format (list)
  static List<Map<String, dynamic>> get apiListResponse => recallList;

  /// API response format (paginated)
  static Map<String, dynamic> get apiPaginatedResponse => {
        'count': recallList.length,
        'next': null,
        'previous': null,
        'results': recallList,
      };
}
