/// Model for Saved Filter (cloud-synced filter presets)
/// Tier limits: Free (0), SmartFiltering (10), RecallMatch (unlimited)
class SavedFilter {
  final int id;
  final String name;
  final String description;
  final Map<String, dynamic> filterData;
  final List<String> brandFilters;
  final List<String> productFilters;
  final int filterCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;

  SavedFilter({
    required this.id,
    required this.name,
    required this.description,
    required this.filterData,
    required this.brandFilters,
    required this.productFilters,
    required this.filterCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  /// Create SavedFilter from API JSON response
  factory SavedFilter.fromJson(Map<String, dynamic> json) {
    print('🔍 SavedFilter.fromJson called');
    print('🔍 JSON: $json');

    final filterData = json['filter_data'] as Map<String, dynamic>? ?? {};
    print('🔍 filter_data: $filterData');

    // Try to parse from top-level fields first (backend sends these)
    // Fall back to filter_data if not present
    final brandFilters = (json['brand_filters'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (filterData['brand_filters'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final productFilters = (json['product_filters'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (filterData['product_filters'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    print('🔍 Parsed brandFilters: $brandFilters');
    print('🔍 Parsed productFilters: $productFilters');

    return SavedFilter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      filterData: filterData,
      brandFilters: brandFilters,
      productFilters: productFilters,
      filterCount: json['filter_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
    );
  }

  /// Convert SavedFilter to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'filter_data': {
        'brand_filters': brandFilters,
        'product_filters': productFilters,
      },
      'is_active': isActive,
    };
  }

  /// Create a copy with updated fields
  SavedFilter copyWith({
    int? id,
    String? name,
    String? description,
    Map<String, dynamic>? filterData,
    List<String>? brandFilters,
    List<String>? productFilters,
    int? filterCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return SavedFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filterData: filterData ?? this.filterData,
      brandFilters: brandFilters ?? this.brandFilters,
      productFilters: productFilters ?? this.productFilters,
      filterCount: filterCount ?? this.filterCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Format last used timestamp as human-readable text
  String getLastUsedText() {
    if (lastUsedAt == null) {
      return 'Never used';
    }

    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);

    if (difference.inMinutes < 60) {
      return 'Used ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Used ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Used ${difference.inDays}d ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return 'Used ${weeks}w ago';
    }
  }

  @override
  String toString() {
    return 'SavedFilter(id: $id, name: $name, filterCount: $filterCount)';
  }
}
