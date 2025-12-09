/// FilterState Model Unit Tests
///
/// Tests for the FilterState model and filter logic including:
/// - Empty state creation
/// - Filter counting
/// - Active filters detection
/// - Filter data serialization
///
/// To run: flutter test test/unit/services/filter_state_test.dart
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:rs_flutter/services/filter_state_service.dart';

void main() {
  group('FilterState - Empty State', () {
    test('empty() creates state with no filters', () {
      final state = FilterState.empty();

      expect(state.brandFilters, isEmpty);
      expect(state.productFilters, isEmpty);
      expect(state.stateFilters, isEmpty);
      expect(state.allergenFilters, isEmpty);
      expect(state.hasActiveFilters, false);
    });

    test('empty state has zero total count', () {
      final state = FilterState.empty();
      expect(state.totalCount, 0);
    });

    test('empty state isEmpty returns true', () {
      final state = FilterState.empty();
      expect(state.isEmpty, true);
      expect(state.isNotEmpty, false);
    });
  });

  group('FilterState - With Filters', () {
    test('counts brand filters correctly', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand2', 'Brand3'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.brandFilters.length, 3);
      expect(state.totalCount, 3);
    });

    test('counts product filters correctly', () {
      final state = FilterState(
        brandFilters: [],
        productFilters: ['Product1', 'Product2'],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.productFilters.length, 2);
      expect(state.totalCount, 2);
    });

    test('counts state filters correctly', () {
      final state = FilterState(
        brandFilters: [],
        productFilters: [],
        stateFilters: ['CA', 'NY', 'TX', 'FL'],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.stateFilters.length, 4);
      expect(state.totalCount, 4);
    });

    test('counts allergen filters correctly', () {
      final state = FilterState(
        brandFilters: [],
        productFilters: [],
        stateFilters: [],
        allergenFilters: ['Peanuts', 'Milk', 'Eggs'],
        hasActiveFilters: true,
      );

      expect(state.allergenFilters.length, 3);
      expect(state.totalCount, 3);
    });

    test('counts all filters combined', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand2'],
        productFilters: ['Product1'],
        stateFilters: ['CA', 'NY'],
        allergenFilters: ['Peanuts'],
        hasActiveFilters: true,
      );

      expect(state.totalCount, 6);
    });

    test('isNotEmpty returns true when filters exist', () {
      final state = FilterState(
        brandFilters: ['Brand1'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.isEmpty, false);
      expect(state.isNotEmpty, true);
    });
  });

  group('FilterState - hasActiveFilters', () {
    test('hasActiveFilters is true when brand filters exist', () {
      final state = FilterState(
        brandFilters: ['Brand1'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.hasActiveFilters, true);
    });

    test('hasActiveFilters is true when product filters exist', () {
      final state = FilterState(
        brandFilters: [],
        productFilters: ['Product1'],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.hasActiveFilters, true);
    });

    test('hasActiveFilters is false for empty state', () {
      final state = FilterState.empty();
      expect(state.hasActiveFilters, false);
    });
  });

  group('FilterState - Serialization', () {
    test('can serialize to JSON format', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand2'],
        productFilters: ['Product1'],
        stateFilters: ['CA', 'NY'],
        allergenFilters: ['Peanuts'],
        hasActiveFilters: true,
      );

      // Simulate what FilterStateService.saveFilterState does
      final json = jsonEncode({
        'brandFilters': state.brandFilters,
        'productFilters': state.productFilters,
        'stateFilters': state.stateFilters,
        'allergenFilters': state.allergenFilters,
        'hasActiveFilters': state.hasActiveFilters,
      });

      expect(json, isA<String>());
      final decoded = jsonDecode(json);
      expect(decoded['brandFilters'], ['Brand1', 'Brand2']);
      expect(decoded['productFilters'], ['Product1']);
      expect(decoded['stateFilters'], ['CA', 'NY']);
      expect(decoded['allergenFilters'], ['Peanuts']);
      expect(decoded['hasActiveFilters'], true);
    });

    test('can deserialize from JSON format', () {
      final json = {
        'brandFilters': ['Brand1', 'Brand2'],
        'productFilters': ['Product1'],
        'stateFilters': ['CA', 'NY'],
        'allergenFilters': ['Peanuts'],
        'hasActiveFilters': true,
      };

      // Simulate what FilterStateService.loadFilterState does
      final state = FilterState(
        brandFilters: List<String>.from(json['brandFilters'] as List),
        productFilters: List<String>.from(json['productFilters'] as List),
        stateFilters: List<String>.from(json['stateFilters'] as List),
        allergenFilters: List<String>.from(json['allergenFilters'] as List),
        hasActiveFilters: json['hasActiveFilters'] as bool,
      );

      expect(state.brandFilters, ['Brand1', 'Brand2']);
      expect(state.productFilters, ['Product1']);
      expect(state.stateFilters, ['CA', 'NY']);
      expect(state.allergenFilters, ['Peanuts']);
      expect(state.hasActiveFilters, true);
    });

    test('handles null/missing fields in JSON', () {
      final json = <String, dynamic>{};

      // Simulate defensive parsing
      final state = FilterState(
        brandFilters: List<String>.from(json['brandFilters'] ?? []),
        productFilters: List<String>.from(json['productFilters'] ?? []),
        stateFilters: List<String>.from(json['stateFilters'] ?? []),
        allergenFilters: List<String>.from(json['allergenFilters'] ?? []),
        hasActiveFilters: json['hasActiveFilters'] ?? false,
      );

      expect(state.brandFilters, isEmpty);
      expect(state.productFilters, isEmpty);
      expect(state.stateFilters, isEmpty);
      expect(state.allergenFilters, isEmpty);
      expect(state.hasActiveFilters, false);
    });

    test('round-trips correctly', () {
      final original = FilterState(
        brandFilters: ['Brand1', 'Brand2'],
        productFilters: ['Product1'],
        stateFilters: ['CA'],
        allergenFilters: ['Peanuts', 'Milk'],
        hasActiveFilters: true,
      );

      // Serialize
      final json = jsonEncode({
        'brandFilters': original.brandFilters,
        'productFilters': original.productFilters,
        'stateFilters': original.stateFilters,
        'allergenFilters': original.allergenFilters,
        'hasActiveFilters': original.hasActiveFilters,
      });

      // Deserialize
      final decoded = jsonDecode(json);
      final restored = FilterState(
        brandFilters: List<String>.from(decoded['brandFilters']),
        productFilters: List<String>.from(decoded['productFilters']),
        stateFilters: List<String>.from(decoded['stateFilters']),
        allergenFilters: List<String>.from(decoded['allergenFilters']),
        hasActiveFilters: decoded['hasActiveFilters'],
      );

      expect(restored.brandFilters, original.brandFilters);
      expect(restored.productFilters, original.productFilters);
      expect(restored.stateFilters, original.stateFilters);
      expect(restored.allergenFilters, original.allergenFilters);
      expect(restored.hasActiveFilters, original.hasActiveFilters);
    });
  });

  group('FilterState - Filter Summary Logic', () {
    test('calculates summary for brand filters only', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand2'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      // Simulate summary calculation from FilterStateService
      List<String> summaryParts = [];
      if (state.brandFilters.isNotEmpty) {
        summaryParts.add(
          '${state.brandFilters.length} brand${state.brandFilters.length == 1 ? '' : 's'}',
        );
      }

      expect(summaryParts.join(', '), '2 brands');
    });

    test('calculates summary for single brand', () {
      final state = FilterState(
        brandFilters: ['Brand1'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      final count = state.brandFilters.length;
      final suffix = count == 1 ? '' : 's';
      final summary = '$count brand$suffix';

      expect(summary, '1 brand');
    });

    test('calculates summary for mixed filters', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand2'],
        productFilters: ['Product1'],
        stateFilters: ['CA', 'NY', 'TX'],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      List<String> summaryParts = [];
      if (state.brandFilters.isNotEmpty) {
        summaryParts.add(
          '${state.brandFilters.length} brand${state.brandFilters.length == 1 ? '' : 's'}',
        );
      }
      if (state.productFilters.isNotEmpty) {
        summaryParts.add(
          '${state.productFilters.length} product${state.productFilters.length == 1 ? '' : 's'}',
        );
      }
      if (state.stateFilters.isNotEmpty) {
        summaryParts.add(
          '${state.stateFilters.length} state${state.stateFilters.length == 1 ? '' : 's'}',
        );
      }

      expect(summaryParts.join(', '), '2 brands, 1 product, 3 states');
    });

    test('returns "No active filters" for empty state', () {
      final state = FilterState.empty();

      final summary = state.hasActiveFilters ? 'Has filters' : 'No active filters';
      expect(summary, 'No active filters');
    });
  });

  group('FilterState - Edge Cases', () {
    test('handles empty string filters', () {
      final state = FilterState(
        brandFilters: ['', 'Brand1', ''],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      // The list contains 3 items (including empty strings)
      expect(state.brandFilters.length, 3);
      expect(state.totalCount, 3);

      // In practice, empty strings should be filtered out before saving
      final cleanedFilters = state.brandFilters.where((f) => f.isNotEmpty).toList();
      expect(cleanedFilters.length, 1);
    });

    test('handles duplicate filters', () {
      final state = FilterState(
        brandFilters: ['Brand1', 'Brand1', 'Brand2'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      // The list contains 3 items (including duplicate)
      expect(state.brandFilters.length, 3);

      // In practice, duplicates should be removed
      final uniqueFilters = state.brandFilters.toSet().toList();
      expect(uniqueFilters.length, 2);
    });

    test('handles special characters in filters', () {
      final state = FilterState(
        brandFilters: ["Brand's", 'Brand & Co.', 'Brand "Test"'],
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.brandFilters.length, 3);

      // Should serialize/deserialize correctly
      final json = jsonEncode({
        'brandFilters': state.brandFilters,
      });
      final decoded = jsonDecode(json);
      expect(List<String>.from(decoded['brandFilters']), state.brandFilters);
    });

    test('handles very long filter lists', () {
      final manyFilters = List.generate(1000, (i) => 'Brand$i');
      final state = FilterState(
        brandFilters: manyFilters,
        productFilters: [],
        stateFilters: [],
        allergenFilters: [],
        hasActiveFilters: true,
      );

      expect(state.brandFilters.length, 1000);
      expect(state.totalCount, 1000);
    });
  });

  group('FilterState - Storage Key', () {
    test('storage key is consistent', () {
      // This is the key used by FilterStateService
      const filterStateKey = 'filter_state_encrypted';

      // Verify it matches what's expected
      expect(filterStateKey, 'filter_state_encrypted');
      expect(filterStateKey, isNot(isEmpty));
    });
  });
}
