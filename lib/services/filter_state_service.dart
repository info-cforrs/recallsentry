import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FilterStateService {
  static const String _filterStateKey = 'filter_state_encrypted';
  final _secureStorage = const FlutterSecureStorage();

  // Save current filter state
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<void> saveFilterState({
    required List<String> brandFilters,
    required List<String> productFilters,
    List<String>? stateFilters,
    List<String>? allergenFilters,
  }) async {
    try {
      // Mark as having active filters if any filters exist
      bool hasFilters = brandFilters.isNotEmpty ||
                        productFilters.isNotEmpty ||
                        (stateFilters?.isNotEmpty ?? false) ||
                        (allergenFilters?.isNotEmpty ?? false);

      final filterData = jsonEncode({
        'brandFilters': brandFilters,
        'productFilters': productFilters,
        'stateFilters': stateFilters ?? [],
        'allergenFilters': allergenFilters ?? [],
        'hasActiveFilters': hasFilters,
      });

      await _secureStorage.write(key: _filterStateKey, value: filterData);
    } catch (e) {
      // Silently fail - filter state saving is not critical
    }
  }

  // Load current filter state
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<FilterState> loadFilterState() async {
    try {
      final String? filterData = await _secureStorage.read(key: _filterStateKey);

      if (filterData == null) {
        return FilterState.empty();
      }

      final Map<String, dynamic> data = jsonDecode(filterData);

      return FilterState(
        brandFilters: List<String>.from(data['brandFilters'] ?? []),
        productFilters: List<String>.from(data['productFilters'] ?? []),
        stateFilters: List<String>.from(data['stateFilters'] ?? []),
        allergenFilters: List<String>.from(data['allergenFilters'] ?? []),
        hasActiveFilters: data['hasActiveFilters'] ?? false,
      );
    } catch (e) {
      return FilterState.empty();
    }
  }

  // Clear all filters (called when trash can is clicked)
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<void> clearAllFilters() async {
    try {
      await _secureStorage.delete(key: _filterStateKey);
    } catch (e) {
      // Silently fail - filter clearing is not critical
    }
  }

  // Check if there are active filters
  // SECURITY: Now uses FlutterSecureStorage for encryption
  Future<bool> hasActiveFilters() async {
    try {
      final filterState = await loadFilterState();
      return filterState.hasActiveFilters;
    } catch (e) {
      return false;
    }
  }

  // Get filter count for display purposes
  Future<int> getFilterCount() async {
    try {
      final filterState = await loadFilterState();
      return filterState.brandFilters.length +
          filterState.productFilters.length +
          filterState.stateFilters.length;
    } catch (e) {
      return 0;
    }
  }

  // Get filter summary text
  Future<String> getFilterSummary() async {
    try {
      final filterState = await loadFilterState();
      if (!filterState.hasActiveFilters) {
        return 'No active filters';
      }

      List<String> summaryParts = [];
      if (filterState.brandFilters.isNotEmpty) {
        summaryParts.add(
          '${filterState.brandFilters.length} brand${filterState.brandFilters.length == 1 ? '' : 's'}',
        );
      }
      if (filterState.productFilters.isNotEmpty) {
        summaryParts.add(
          '${filterState.productFilters.length} product${filterState.productFilters.length == 1 ? '' : 's'}',
        );
      }
      if (filterState.stateFilters.isNotEmpty) {
        summaryParts.add(
          '${filterState.stateFilters.length} state${filterState.stateFilters.length == 1 ? '' : 's'}',
        );
      }

      return summaryParts.join(', ');
    } catch (e) {
      return 'Error loading filters';
    }
  }
}

// Data class to hold filter state
class FilterState {
  final List<String> brandFilters;
  final List<String> productFilters;
  final List<String> stateFilters;
  final List<String> allergenFilters;
  final bool hasActiveFilters;

  FilterState({
    required this.brandFilters,
    required this.productFilters,
    required this.stateFilters,
    required this.allergenFilters,
    required this.hasActiveFilters,
  });

  FilterState.empty()
    : brandFilters = [],
      productFilters = [],
      stateFilters = [],
      allergenFilters = [],
      hasActiveFilters = false;

  // Total filter count
  int get totalCount => brandFilters.length + productFilters.length + stateFilters.length + allergenFilters.length;

  // Check if filters are empty
  bool get isEmpty => brandFilters.isEmpty && productFilters.isEmpty && stateFilters.isEmpty && allergenFilters.isEmpty;

  // Check if filters are not empty
  bool get isNotEmpty => !isEmpty;
}
