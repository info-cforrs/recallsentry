import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/animated_visibility_wrapper.dart';
import '../mixins/hide_on_scroll_mixin.dart';
import '../services/auth_service.dart';
import '../services/allergy_preferences_service.dart';
import '../models/allergy_preferences.dart';
import 'auth_required_page.dart';

class AllergyPreferencesPage extends StatefulWidget {
  const AllergyPreferencesPage({super.key});

  @override
  State<AllergyPreferencesPage> createState() => _AllergyPreferencesPageState();
}

class _AllergyPreferencesPageState extends State<AllergyPreferencesPage> with HideOnScrollMixin {
  bool _isLoading = true;
  bool _isSaving = false;

  // Current preferences
  AllergyPreferences? _preferences;

  final AllergyPreferencesService _allergyService = AllergyPreferencesService();

  @override
  void initState() {
    super.initState();
    initHideOnScroll();
    _loadPreferences();
  }

  @override
  void dispose() {
    disposeHideOnScroll();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final authService = AuthService();
      final token = await authService.getAccessToken();
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AuthRequiredPage(
                pageTitle: 'Allergy Alerts',
              ),
            ),
          );
        }
        return;
      }

      final prefs = await _allergyService.getPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs ?? AllergyPreferences.defaults();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _updatePreference(AllergyPreferences newPrefs) async {
    setState(() => _isSaving = true);

    try {
      final updated = await _allergyService.updatePreferences(newPrefs);
      if (mounted) {
        if (updated != null) {
          setState(() => _preferences = updated);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preference saved'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to update preference');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleAllAllergens(bool value) {
    if (_preferences == null) return;
    final newPrefs = _preferences!.copyWith(alertAllAllergens: value);
    _updatePreference(newPrefs);
  }

  void _toggleAllergen(String key, bool value) {
    if (_preferences == null) return;

    AllergyPreferences newPrefs;
    switch (key) {
      case 'peanuts':
        newPrefs = _preferences!.copyWith(alertPeanuts: value);
        break;
      case 'tree_nuts':
        newPrefs = _preferences!.copyWith(alertTreeNuts: value);
        break;
      case 'milk_dairy':
        newPrefs = _preferences!.copyWith(alertMilkDairy: value);
        break;
      case 'eggs':
        newPrefs = _preferences!.copyWith(alertEggs: value);
        break;
      case 'wheat_gluten':
        newPrefs = _preferences!.copyWith(alertWheatGluten: value);
        break;
      case 'soy':
        newPrefs = _preferences!.copyWith(alertSoy: value);
        break;
      case 'fish':
        newPrefs = _preferences!.copyWith(alertFish: value);
        break;
      case 'shellfish':
        newPrefs = _preferences!.copyWith(alertShellfish: value);
        break;
      case 'sesame':
        newPrefs = _preferences!.copyWith(alertSesame: value);
        break;
      default:
        return;
    }
    _updatePreference(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D3547),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final prefs = _preferences ?? AllergyPreferences.defaults();

    return Scaffold(
      backgroundColor: const Color(0xFF1D3547),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CustomBackButton(),
                  const SizedBox(width: 8),
                  // App Icon - Clickable to return to Home
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              const MainNavigation(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/images/shield_logo4.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Allergy Alerts',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Atlanta',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A4A5C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Get notified about recalls involving common food allergens (FDA "Big 9"). These alerts work with your SmartFilters.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: ListView(
                controller: hideOnScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  // Master Toggle Section
                  _buildSectionHeader('Quick Settings'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Alert for ALL Allergens',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Enable alerts for all 9 major allergens at once',
                            style: TextStyle(color: Colors.white70),
                          ),
                          value: prefs.alertAllAllergens,
                          onChanged: _isSaving ? null : _toggleAllAllergens,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: prefs.alertAllAllergens
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.warning_amber,
                              color: prefs.alertAllAllergens
                                  ? Colors.orange
                                  : Colors.white70,
                            ),
                          ),
                          activeThumbColor: Colors.orange,
                          activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Individual Allergens Section
                  _buildSectionHeader('Individual Allergens'),

                  // Show note if all allergens is enabled
                  if (prefs.alertAllAllergens)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'All allergens are enabled via the master toggle above',
                        style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildAllergenTile(
                          title: 'Peanuts',
                          subtitle: 'Peanut and groundnut products',
                          icon: '🥜',
                          isEnabled: prefs.alertAllAllergens || prefs.alertPeanuts,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('peanuts', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Tree Nuts',
                          subtitle: 'Almonds, cashews, walnuts, pecans, etc.',
                          icon: '🌰',
                          isEnabled: prefs.alertAllAllergens || prefs.alertTreeNuts,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('tree_nuts', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Milk / Dairy',
                          subtitle: 'Milk, cheese, butter, lactose products',
                          icon: '🥛',
                          isEnabled: prefs.alertAllAllergens || prefs.alertMilkDairy,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('milk_dairy', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Eggs',
                          subtitle: 'Egg and egg-derived products',
                          icon: '🥚',
                          isEnabled: prefs.alertAllAllergens || prefs.alertEggs,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('eggs', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Wheat / Gluten',
                          subtitle: 'Wheat, gluten, and celiac-related',
                          icon: '🌾',
                          isEnabled: prefs.alertAllAllergens || prefs.alertWheatGluten,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('wheat_gluten', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Soy',
                          subtitle: 'Soy, soybean, and tofu products',
                          icon: '🫘',
                          isEnabled: prefs.alertAllAllergens || prefs.alertSoy,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('soy', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Fish',
                          subtitle: 'Fish and fish-derived products',
                          icon: '🐟',
                          isEnabled: prefs.alertAllAllergens || prefs.alertFish,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('fish', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Shellfish',
                          subtitle: 'Shrimp, crab, lobster, mollusks',
                          icon: '🦐',
                          isEnabled: prefs.alertAllAllergens || prefs.alertShellfish,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('shellfish', value),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        _buildAllergenTile(
                          title: 'Sesame',
                          subtitle: 'Sesame seeds and tahini',
                          icon: '🌱',
                          isEnabled: prefs.alertAllAllergens || prefs.alertSesame,
                          isDisabled: prefs.alertAllAllergens,
                          onChanged: (value) => _toggleAllergen('sesame', value),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Section
                  _buildSectionHeader('About Allergen Alerts'),
                  Card(
                    elevation: 2,
                    color: const Color(0xFF2A4A5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FDA "Big 9" Allergens',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'These are the nine major food allergens identified by the FDA that must be declared on food labels. They account for most serious allergic reactions to food.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'When enabled, we\'ll scan recall descriptions for allergen-related keywords and notify you of potential matches. This is in addition to your regular SmartFilter notifications.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedVisibilityWrapper(
        isVisible: isBottomNavVisible,
        direction: SlideDirection.down,
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF2C3E50),
          selectedItemColor: const Color(0xFF64B5F6),
          unselectedItemColor: Colors.white54,
          currentIndex: 2,
          elevation: 8,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 0),
                  ),
                  (route) => false,
                );
                break;
              case 1:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 1),
                  ),
                  (route) => false,
                );
                break;
              case 2:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(initialIndex: 2),
                  ),
                  (route) => false,
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAllergenTile({
    required String title,
    required String subtitle,
    required String icon,
    required bool isEnabled,
    required bool isDisabled,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDisabled ? Colors.white60 : Colors.white,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: isDisabled ? Colors.white38 : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
      value: isEnabled,
      onChanged: _isSaving || isDisabled ? null : onChanged,
      activeThumbColor: Colors.green,
      activeTrackColor: Colors.green.withValues(alpha: 0.5),
    );
  }
}
