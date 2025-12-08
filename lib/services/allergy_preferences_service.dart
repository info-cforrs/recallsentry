import 'dart:convert';
import '../models/allergy_preferences.dart';
import '../services/auth_service.dart';

// Service for managing user allergy preferences
// Available to both SmartFilter and RecallMatch plan users
class AllergyPreferencesService {
  static final AllergyPreferencesService _instance = AllergyPreferencesService._internal();
  factory AllergyPreferencesService() => _instance;
  AllergyPreferencesService._internal();

  final AuthService _authService = AuthService();

  static const String _endpoint = '/recall-management/allergy-preferences/';

  /// Get user's allergy preferences
  /// Creates default preferences if none exist
  Future<AllergyPreferences?> getPreferences() async {
    try {
      final response = await _authService.authenticatedRequest('GET', _endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AllergyPreferences.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user's allergy preferences
  Future<AllergyPreferences?> updatePreferences(AllergyPreferences preferences) async {
    try {
      final response = await _authService.authenticatedRequest(
        'PUT',
        _endpoint,
        body: preferences.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AllergyPreferences.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Toggle the "All Allergens" setting
  Future<AllergyPreferences?> toggleAllAllergens(bool enabled) async {
    final current = await getPreferences();
    if (current == null) return null;

    return updatePreferences(current.copyWith(alertAllAllergens: enabled));
  }

  /// Toggle a specific allergen
  Future<AllergyPreferences?> toggleAllergen(String allergenKey, bool enabled) async {
    final current = await getPreferences();
    if (current == null) return null;

    AllergyPreferences updated;
    switch (allergenKey) {
      case 'peanuts':
        updated = current.copyWith(alertPeanuts: enabled);
        break;
      case 'tree_nuts':
        updated = current.copyWith(alertTreeNuts: enabled);
        break;
      case 'milk_dairy':
        updated = current.copyWith(alertMilkDairy: enabled);
        break;
      case 'eggs':
        updated = current.copyWith(alertEggs: enabled);
        break;
      case 'wheat_gluten':
        updated = current.copyWith(alertWheatGluten: enabled);
        break;
      case 'soy':
        updated = current.copyWith(alertSoy: enabled);
        break;
      case 'fish':
        updated = current.copyWith(alertFish: enabled);
        break;
      case 'shellfish':
        updated = current.copyWith(alertShellfish: enabled);
        break;
      case 'sesame':
        updated = current.copyWith(alertSesame: enabled);
        break;
      default:
        return current;
    }

    return updatePreferences(updated);
  }
}
