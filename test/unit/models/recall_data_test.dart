/// RecallData Model Unit Tests
///
/// Tests for the RecallData model including:
/// - JSON parsing for all agencies (FDA, USDA, CPSC, NHTSA)
/// - Field mapping and defaults
/// - Boolean/string remedy conversion
/// - Date parsing
/// - Image URL handling
///
/// To run: flutter test test/unit/models/recall_data_test.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:rs_flutter/models/recall_data.dart';
import '../../fixtures/recall_fixtures.dart';

void main() {
  group('RecallData - fromJson', () {
    group('FDA Recall Parsing', () {
      test('parses FDA recall with all fields', () {
        final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

        expect(recall.id, 'FDA-2024-001');
        expect(recall.fdaRecallId, 'FDA-2024-001');
        expect(recall.productName, 'Organic Peanut Butter');
        expect(recall.brandName, 'NuttyHealth');
        expect(recall.riskLevel, 'HIGH');
        expect(recall.agency, 'FDA');
        expect(recall.category, 'Food');
        expect(recall.description, contains('salmonella'));
      });

      test('parses FDA recall database ID', () {
        final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);
        expect(recall.databaseId, 1);
      });

      test('parses FDA recall firm contact info', () {
        final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

        expect(recall.recallingFdaFirm, 'NuttyHealth Foods Inc.');
        expect(recall.firmContactPhone, '1-800-555-0123');
        expect(recall.firmContactEmail, 'recall@nuttyhealth.com');
      });

      test('parses FDA recall distribution info', () {
        final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

        expect(recall.stateCount, 15);
        expect(recall.distributionPattern, 'Nationwide');
        expect(recall.productQty, '50000 units');
      });
    });

    group('USDA Recall Parsing', () {
      test('parses USDA recall with all fields', () {
        final recall = RecallData.fromJson(RecallFixtures.usdaRecallSample);

        expect(recall.id, 'USDA-2024-002');
        expect(recall.usdaRecallId, 'USDA-2024-002');
        expect(recall.productName, 'Ground Beef 80/20');
        expect(recall.brandName, 'Prairie Farms');
        expect(recall.agency, 'USDA');
        expect(recall.category, 'Meat');
      });

      test('parses USDA establishment info', () {
        final recall = RecallData.fromJson(RecallFixtures.usdaRecallSample);

        expect(recall.establishmentManufacturer, 'Prairie Farms Processing');
      });

      test('parses USDA recall classification', () {
        final recall = RecallData.fromJson(RecallFixtures.usdaRecallSample);
        expect(recall.recallClassification, 'Class I');
      });
    });

    group('CPSC Recall Parsing', () {
      test('parses CPSC recall with all fields', () {
        final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);

        expect(recall.id, 'CPSC-2024-003');
        expect(recall.productName, 'Kids Power Wheels');
        expect(recall.brandName, 'SafeRide Toys');
        expect(recall.agency, 'CPSC');
        expect(recall.category, 'Toys');
      });

      test('parses CPSC model and serial number', () {
        final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);

        expect(recall.cpscModel, 'PW-2024-RED');
        expect(recall.cpscSerialNumber, 'SN-RANGE-001-500');
      });

      test('parses CPSC sold-by retailer flags', () {
        final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);

        expect(recall.cpscSoldByWalmart, 'Y');
        expect(recall.cpscSoldByAmazon, 'Y');
        expect(recall.cpscSoldByTarget, 'Y');
        expect(recall.cpscSoldByEbay, '');
        expect(recall.cpscSoldByCostco, '');
      });

      test('parses CPSC sold-by date range', () {
        final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);

        expect(recall.cpscSoldByDateStart, isNotNull);
        expect(recall.cpscSoldByDateEnd, isNotNull);
      });

      test('parses CPSC remedy recall proof flag', () {
        final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);
        expect(recall.cpscRemedyRecallProof, 'Y');
      });
    });

    group('NHTSA Vehicle Recall Parsing', () {
      test('parses NHTSA vehicle recall with all fields', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);

        expect(recall.id, 'NHTSA-2024-004');
        expect(recall.productName, 'Model X SUV');
        expect(recall.agency, 'NHTSA');
        expect(recall.category, 'Vehicles');
      });

      test('parses NHTSA campaign numbers', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);

        expect(recall.nhtsaRecallId, 'NHTSA-2024-004');
        expect(recall.nhtsaCampaignNumber, '24V-123');
        expect(recall.nhtsaMfrCampaignNumber, 'AM-2024-001');
      });

      test('parses NHTSA vehicle info', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);

        expect(recall.nhtsaVehicleMake, 'AutoMaker');
        expect(recall.nhtsaVehicleModel, 'Model X');
        expect(recall.nhtsaVehicleYearStart, '2020');
        expect(recall.nhtsaVehicleYearEnd, '2023');
        expect(recall.nhtsaVehicleYearRange, '2020-2023');
      });

      test('parses NHTSA recall metadata', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);

        expect(recall.nhtsaComponent, 'Air Bags');
        expect(recall.nhtsaRecallType, 'Vehicle');
        expect(recall.nhtsaPotentiallyAffected, 250000);
        expect(recall.nhtsaCompletionRate, '15%');
      });

      test('parses NHTSA safety flags', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);

        expect(recall.nhtsaFireRisk, false);
        expect(recall.nhtsaDoNotDrive, false);
        expect(recall.remedyOtaUpdate, false);
      });
    });

    group('NHTSA Tire Recall Parsing', () {
      test('parses NHTSA tire recall', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaTireRecallSample);

        expect(recall.nhtsaRecallType, 'Tire');
        expect(recall.nhtsaModelNum, 'TM-AS-225');
        expect(recall.nhtsaUpc, '098765432109');
      });
    });

    group('NHTSA Child Seat Recall Parsing', () {
      test('parses NHTSA child seat recall', () {
        final recall = RecallData.fromJson(RecallFixtures.nhtsaChildSeatRecallSample);

        expect(recall.nhtsaRecallType, 'Child Seat');
        expect(recall.nhtsaModelNum, 'SB-INF-2024');
      });
    });
  });

  group('RecallData - Remedy Field Conversion', () {
    test('converts boolean true to Y', () {
      final recall = RecallData.fromJson(RecallFixtures.recallWithBooleanRemedies);

      expect(recall.remedyReturn, 'Y');
      expect(recall.remedyReplace, 'Y');
    });

    test('converts boolean false to empty string', () {
      final recall = RecallData.fromJson(RecallFixtures.recallWithBooleanRemedies);

      expect(recall.remedyRepair, '');
      expect(recall.remedyDispose, '');
      expect(recall.remedyNA, '');
    });

    test('preserves Y string values', () {
      final recall = RecallData.fromJson(RecallFixtures.recallWithStringRemedies);

      expect(recall.remedyReturn, 'Y');
      expect(recall.remedyReplace, 'Y');
    });

    test('preserves empty string values', () {
      final recall = RecallData.fromJson(RecallFixtures.recallWithStringRemedies);

      expect(recall.remedyRepair, '');
      expect(recall.remedyDispose, '');
    });
  });

  group('RecallData - Default Values', () {
    test('uses defaults for missing optional fields', () {
      final recall = RecallData.fromJson(RecallFixtures.minimalRecall);

      expect(recall.imageUrl, '');
      expect(recall.stateCount, 0);
      expect(recall.negativeOutcomes, '');
      expect(recall.packagingDesc, '');
      expect(recall.recallResolutionStatus, 'Not Started');
    });

    test('handles null values gracefully', () {
      final recall = RecallData.fromJson(RecallFixtures.recallWithNulls);

      expect(recall.brandName, '');
      expect(recall.riskLevel, 'LOW');
      expect(recall.agency, 'FDA');
      expect(recall.description, '');
      expect(recall.category, '');
    });

    test('defaults risk level to LOW', () {
      final recall = RecallData.fromJson({'id': 1, 'product_name': 'Test'});
      expect(recall.riskLevel, 'LOW');
    });

    test('defaults agency to FDA', () {
      final recall = RecallData.fromJson({'id': 1, 'product_name': 'Test'});
      expect(recall.agency, 'FDA');
    });
  });

  group('RecallData - Date Parsing', () {
    test('parses date_issued correctly', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

      expect(recall.dateIssued.year, 2024);
      expect(recall.dateIssued.month, 1);
      expect(recall.dateIssued.day, 15);
    });

    test('parses production dates correctly', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

      expect(recall.productionDateStart, isNotNull);
      expect(recall.productionDateEnd, isNotNull);
    });

    test('handles null production dates', () {
      final recall = RecallData.fromJson(RecallFixtures.minimalRecall);

      expect(recall.productionDateStart, isNull);
      expect(recall.productionDateEnd, isNull);
    });

    test('handles empty production dates', () {
      final recall = RecallData.fromJson({
        ...RecallFixtures.minimalRecall,
        'production_date_start': '',
        'production_date_end': '',
      });

      expect(recall.productionDateStart, isNull);
      expect(recall.productionDateEnd, isNull);
    });
  });

  group('RecallData - ID Handling', () {
    test('uses recall_id as primary id', () {
      final recall = RecallData.fromJson({
        'id': 123,
        'recall_id': 'FDA-2024-TEST',
        'product_name': 'Test',
      });

      expect(recall.id, 'FDA-2024-TEST');
      expect(recall.databaseId, 123);
    });

    test('falls back to id field if recall_id missing', () {
      final recall = RecallData.fromJson({
        'id': 456,
        'product_name': 'Test',
      });

      expect(recall.id, '456');
      expect(recall.databaseId, 456);
    });

    test('determines agency from recall_id prefix', () {
      final fdaRecall = RecallData.fromJson({
        'id': 1,
        'recall_id': 'FDA-2024-001',
        'product_name': 'Test',
      });
      expect(fdaRecall.fdaRecallId, 'FDA-2024-001');

      final usdaRecall = RecallData.fromJson({
        'id': 2,
        'recall_id': 'USDA-2024-002',
        'product_name': 'Test',
      });
      expect(usdaRecall.usdaRecallId, 'USDA-2024-002');
    });
  });

  group('RecallData - toJson', () {
    test('serializes all fields', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);
      final json = recall.toJson();

      expect(json['product_name'], 'Organic Peanut Butter');
      expect(json['brand_name'], 'NuttyHealth');
      expect(json['risk_level'], 'HIGH');
      expect(json['agency'], 'FDA');
    });

    test('serializes dates as ISO strings', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);
      final json = recall.toJson();

      expect(json['date_issued'], isA<String>());
      expect(json['date_issued'], contains('2024-01-15'));
    });

    test('serializes CPSC fields', () {
      final recall = RecallData.fromJson(RecallFixtures.cpscRecallSample);
      final json = recall.toJson();

      expect(json['model'], 'PW-2024-RED');
      expect(json['sn'], 'SN-RANGE-001-500');
      expect(json['sold_by_walmart'], 'Y');
    });

    test('serializes NHTSA fields', () {
      final recall = RecallData.fromJson(RecallFixtures.nhtsaVehicleRecallSample);
      final json = recall.toJson();

      expect(json['nhtsa_campaign_number'], '24V-123');
      expect(json['nhtsa_vehicle_make'], 'AutoMaker');
      expect(json['nhtsa_potentially_affected'], 250000);
    });
  });

  group('RecallData - Image Handling', () {
    test('getPrimaryImageUrl returns imageUrl when no uploaded images', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);
      final primaryUrl = recall.getPrimaryImageUrl();

      expect(primaryUrl, contains('peanut-butter.jpg'));
    });

    test('getPrimaryImageUrl returns empty when no images', () {
      final recall = RecallData.fromJson(RecallFixtures.minimalRecall);
      final primaryUrl = recall.getPrimaryImageUrl();

      expect(primaryUrl, '');
    });

    test('getAllImageUrls returns all available URLs', () {
      final recall = RecallData.fromJson({
        ...RecallFixtures.fdaRecallSample,
        'image_url2': 'https://example.com/img2.jpg',
        'image_url3': 'https://example.com/img3.jpg',
      });
      final urls = recall.getAllImageUrls();

      expect(urls.length, greaterThanOrEqualTo(1));
    });

    test('getImageUrlForContext returns correct size', () {
      final recall = RecallData.fromJson({
        ...RecallFixtures.fdaRecallSample,
        'image_thumbnail': 'https://example.com/thumb.webp',
        'image_medium': 'https://example.com/medium.webp',
        'image_high_res': 'https://example.com/highres.webp',
      });

      expect(recall.getImageUrlForContext(ImageSize.thumbnail), contains('thumb.webp'));
      expect(recall.getImageUrlForContext(ImageSize.medium), contains('medium.webp'));
      expect(recall.getImageUrlForContext(ImageSize.highRes), contains('highres.webp'));
    });

    test('getImageUrlForContext falls back to imageUrl', () {
      final recall = RecallData.fromJson(RecallFixtures.fdaRecallSample);

      // When optimized versions don't exist, falls back to original
      expect(recall.getImageUrlForContext(ImageSize.thumbnail), recall.imageUrl);
      expect(recall.getImageUrlForContext(ImageSize.medium), recall.imageUrl);
      expect(recall.getImageUrlForContext(ImageSize.highRes), recall.imageUrl);
    });
  });

  group('RecallData - _parseBoolToYN Helper', () {
    test('converts various truthy values to Y', () {
      // Testing through fromJson with CPSC fields
      final testCases = [
        {'sold_by_amazon': true},
        {'sold_by_amazon': 'true'},
        {'sold_by_amazon': 'Y'},
        {'sold_by_amazon': 'y'},
        {'sold_by_amazon': 'yes'},
        {'sold_by_amazon': '1'},
      ];

      for (final testCase in testCases) {
        final recall = RecallData.fromJson({
          ...RecallFixtures.minimalRecall,
          'agency': 'CPSC',
          ...testCase,
        });
        expect(recall.cpscSoldByAmazon, 'Y',
            reason: 'Failed for value: ${testCase['sold_by_amazon']}');
      }
    });

    test('converts various falsy values to empty string', () {
      final testCases = [
        {'sold_by_amazon': false},
        {'sold_by_amazon': 'false'},
        {'sold_by_amazon': 'N'},
        {'sold_by_amazon': 'no'},
        {'sold_by_amazon': '0'},
        {'sold_by_amazon': ''},
        {'sold_by_amazon': null},
      ];

      for (final testCase in testCases) {
        final recall = RecallData.fromJson({
          ...RecallFixtures.minimalRecall,
          'agency': 'CPSC',
          ...testCase,
        });
        expect(recall.cpscSoldByAmazon, '',
            reason: 'Failed for value: ${testCase['sold_by_amazon']}');
      }
    });
  });

  group('RecallData - RecallImage', () {
    test('parses RecallImage from JSON', () {
      final imageJson = {
        'id': 1,
        'image_url': 'https://example.com/image.jpg',
        'caption': 'Product image',
        'uploaded_at': '2024-01-15T10:30:00Z',
      };

      final image = RecallImage.fromJson(imageJson);

      expect(image.id, 1);
      expect(image.imageUrl, 'https://example.com/image.jpg');
      expect(image.caption, 'Product image');
      expect(image.uploadedAt, isNotNull);
    });

    test('handles missing RecallImage fields', () {
      final image = RecallImage.fromJson({});

      expect(image.id, 0);
      expect(image.imageUrl, '');
      expect(image.caption, '');
    });
  });

  group('RecallData - Resolution Status', () {
    test('parses recall resolution status', () {
      final notStarted = RecallData.fromJson(RecallFixtures.fdaRecallSample);
      expect(notStarted.recallResolutionStatus, 'Not Started');

      final inProgress = RecallData.fromJson(RecallFixtures.usdaRecallSample);
      expect(inProgress.recallResolutionStatus, 'In Progress');
    });

    test('defaults to Not Started', () {
      final recall = RecallData.fromJson(RecallFixtures.minimalRecall);
      expect(recall.recallResolutionStatus, 'Not Started');
    });
  });
}
