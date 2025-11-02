import 'package:shared_preferences/shared_preferences.dart';

class FilterStateService {
  static const String _brandFiltersKey = 'advanced_brand_filters';
  static const String _productFiltersKey = 'advanced_product_filters';
  static const String _hasActiveFiltersKey = 'has_active_filters';

  // Save current filter state
  Future<void> saveFilterState({
    required List<String> brandFilters,
    required List<String> productFilters,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save brand filters
      await prefs.setStringList(_brandFiltersKey, brandFilters);

      // Save product filters
      await prefs.setStringList(_productFiltersKey, productFilters);

      // Mark as having active filters if any filters exist
      bool hasFilters = brandFilters.isNotEmpty || productFilters.isNotEmpty;
      await prefs.setBool(_hasActiveFiltersKey, hasFilters);

      print(
        '🔧 FilterStateService: Saved filters - Brands: $brandFilters, Products: $productFilters',
      );
    } catch (e) {
      print('❌ FilterStateService: Error saving filter state: $e');
    }
  }

  // Load current filter state
  Future<FilterState> loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<String> brandFilters = prefs.getStringList(_brandFiltersKey) ?? [];
      List<String> productFilters =
          prefs.getStringList(_productFiltersKey) ?? [];
      bool hasActiveFilters = prefs.getBool(_hasActiveFiltersKey) ?? false;

      print(
        '🔧 FilterStateService: Loaded filters - Brands: $brandFilters, Products: $productFilters, Active: $hasActiveFilters',
      );

      return FilterState(
        brandFilters: brandFilters,
        productFilters: productFilters,
        hasActiveFilters: hasActiveFilters,
      );
    } catch (e) {
      print('❌ FilterStateService: Error loading filter state: $e');
      return FilterState.empty();
    }
  }

  // Clear all filters (called when trash can is clicked)
  Future<void> clearAllFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_brandFiltersKey);
      await prefs.remove(_productFiltersKey);
      await prefs.setBool(_hasActiveFiltersKey, false);

      print('🔧 FilterStateService: Cleared all filters');
    } catch (e) {
      print('❌ FilterStateService: Error clearing filters: $e');
    }
  }

  // Check if there are active filters
  Future<bool> hasActiveFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasActiveFiltersKey) ?? false;
    } catch (e) {
      print('❌ FilterStateService: Error checking active filters: $e');
      return false;
    }
  }

  // Get filter count for display purposes
  Future<int> getFilterCount() async {
    try {
      final filterState = await loadFilterState();
      return filterState.brandFilters.length +
          filterState.productFilters.length;
    } catch (e) {
      print('❌ FilterStateService: Error getting filter count: $e');
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

      return summaryParts.join(', ');
    } catch (e) {
      print('❌ FilterStateService: Error getting filter summary: $e');
      return 'Error loading filters';
    }
  }
}

// Data class to hold filter state
class FilterState {
  final List<String> brandFilters;
  final List<String> productFilters;
  final bool hasActiveFilters;

  FilterState({
    required this.brandFilters,
    required this.productFilters,
    required this.hasActiveFilters,
  });

  FilterState.empty()
    : brandFilters = [],
      productFilters = [],
      hasActiveFilters = false;

  // Total filter count
  int get totalCount => brandFilters.length + productFilters.length;

  // Check if filters are empty
  bool get isEmpty => brandFilters.isEmpty && productFilters.isEmpty;

  // Check if filters are not empty
  bool get isNotEmpty => !isEmpty;
}
