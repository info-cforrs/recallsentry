// User Allergy Preferences Model
//
// Represents user preferences for allergen alerts in SmartFilters.
// Allows users to be notified about recalls involving common food allergens.
//
// FDA "Big 9" Allergens:
// - Peanuts, Tree Nuts, Milk/Dairy, Eggs, Wheat/Gluten,
// - Soy, Fish, Shellfish, Sesame

class AllergyPreferences {
  final int? id;
  final bool alertAllAllergens;
  final bool alertPeanuts;
  final bool alertTreeNuts;
  final bool alertMilkDairy;
  final bool alertEggs;
  final bool alertWheatGluten;
  final bool alertSoy;
  final bool alertFish;
  final bool alertShellfish;
  final bool alertSesame;
  final List<String> activeAllergens;
  final bool hasAnySelected;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AllergyPreferences({
    this.id,
    this.alertAllAllergens = false,
    this.alertPeanuts = false,
    this.alertTreeNuts = false,
    this.alertMilkDairy = false,
    this.alertEggs = false,
    this.alertWheatGluten = false,
    this.alertSoy = false,
    this.alertFish = false,
    this.alertShellfish = false,
    this.alertSesame = false,
    this.activeAllergens = const [],
    this.hasAnySelected = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create default preferences with all alerts disabled
  factory AllergyPreferences.defaults() {
    return AllergyPreferences();
  }

  factory AllergyPreferences.fromJson(Map<String, dynamic> json) {
    return AllergyPreferences(
      id: json['id'],
      alertAllAllergens: json['alert_all_allergens'] ?? false,
      alertPeanuts: json['alert_peanuts'] ?? false,
      alertTreeNuts: json['alert_tree_nuts'] ?? false,
      alertMilkDairy: json['alert_milk_dairy'] ?? false,
      alertEggs: json['alert_eggs'] ?? false,
      alertWheatGluten: json['alert_wheat_gluten'] ?? false,
      alertSoy: json['alert_soy'] ?? false,
      alertFish: json['alert_fish'] ?? false,
      alertShellfish: json['alert_shellfish'] ?? false,
      alertSesame: json['alert_sesame'] ?? false,
      activeAllergens: json['active_allergens'] != null
          ? List<String>.from(json['active_allergens'])
          : [],
      hasAnySelected: json['has_any_selected'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'alert_all_allergens': alertAllAllergens,
      'alert_peanuts': alertPeanuts,
      'alert_tree_nuts': alertTreeNuts,
      'alert_milk_dairy': alertMilkDairy,
      'alert_eggs': alertEggs,
      'alert_wheat_gluten': alertWheatGluten,
      'alert_soy': alertSoy,
      'alert_fish': alertFish,
      'alert_shellfish': alertShellfish,
      'alert_sesame': alertSesame,
    };
  }

  AllergyPreferences copyWith({
    int? id,
    bool? alertAllAllergens,
    bool? alertPeanuts,
    bool? alertTreeNuts,
    bool? alertMilkDairy,
    bool? alertEggs,
    bool? alertWheatGluten,
    bool? alertSoy,
    bool? alertFish,
    bool? alertShellfish,
    bool? alertSesame,
    List<String>? activeAllergens,
    bool? hasAnySelected,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllergyPreferences(
      id: id ?? this.id,
      alertAllAllergens: alertAllAllergens ?? this.alertAllAllergens,
      alertPeanuts: alertPeanuts ?? this.alertPeanuts,
      alertTreeNuts: alertTreeNuts ?? this.alertTreeNuts,
      alertMilkDairy: alertMilkDairy ?? this.alertMilkDairy,
      alertEggs: alertEggs ?? this.alertEggs,
      alertWheatGluten: alertWheatGluten ?? this.alertWheatGluten,
      alertSoy: alertSoy ?? this.alertSoy,
      alertFish: alertFish ?? this.alertFish,
      alertShellfish: alertShellfish ?? this.alertShellfish,
      alertSesame: alertSesame ?? this.alertSesame,
      activeAllergens: activeAllergens ?? this.activeAllergens,
      hasAnySelected: hasAnySelected ?? this.hasAnySelected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display name for an allergen key
  static String getAllergenDisplayName(String allergenKey) {
    const displayNames = {
      'peanuts': 'Peanuts',
      'tree_nuts': 'Tree Nuts',
      'milk_dairy': 'Milk/Dairy',
      'eggs': 'Eggs',
      'wheat_gluten': 'Wheat/Gluten',
      'soy': 'Soy',
      'fish': 'Fish',
      'shellfish': 'Shellfish',
      'sesame': 'Sesame',
    };
    return displayNames[allergenKey] ?? allergenKey;
  }

  /// Get all allergen categories
  static List<AllergenCategory> getAllergenCategories() {
    return [
      AllergenCategory('peanuts', 'Peanuts', 'Peanuts, groundnuts, peanut butter'),
      AllergenCategory('tree_nuts', 'Tree Nuts', 'Almonds, cashews, walnuts, pecans, etc.'),
      AllergenCategory('milk_dairy', 'Milk/Dairy', 'Milk, cheese, butter, cream, yogurt'),
      AllergenCategory('eggs', 'Eggs', 'Eggs, albumin, mayonnaise'),
      AllergenCategory('wheat_gluten', 'Wheat/Gluten', 'Wheat, gluten, flour, bread, pasta'),
      AllergenCategory('soy', 'Soy', 'Soy, soybean, tofu, edamame'),
      AllergenCategory('fish', 'Fish', 'Fish, salmon, tuna, cod, etc.'),
      AllergenCategory('shellfish', 'Shellfish', 'Shrimp, crab, lobster, scallops, etc.'),
      AllergenCategory('sesame', 'Sesame', 'Sesame seeds, tahini, hummus'),
    ];
  }

  /// Check if a specific allergen is enabled
  bool isAllergenEnabled(String allergenKey) {
    if (alertAllAllergens) return true;
    switch (allergenKey) {
      case 'peanuts': return alertPeanuts;
      case 'tree_nuts': return alertTreeNuts;
      case 'milk_dairy': return alertMilkDairy;
      case 'eggs': return alertEggs;
      case 'wheat_gluten': return alertWheatGluten;
      case 'soy': return alertSoy;
      case 'fish': return alertFish;
      case 'shellfish': return alertShellfish;
      case 'sesame': return alertSesame;
      default: return false;
    }
  }
}

/// Represents an allergen category with display info
class AllergenCategory {
  final String key;
  final String displayName;
  final String description;

  AllergenCategory(this.key, this.displayName, this.description);
}
