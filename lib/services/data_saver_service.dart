import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Low Data Mode settings
/// Allows users on limited data plans to reduce data consumption
class DataSaverService {
  static final DataSaverService _instance = DataSaverService._internal();
  factory DataSaverService() => _instance;
  DataSaverService._internal();

  // Storage keys
  static const String _lowDataModeKey = 'low_data_mode';
  static const String _loadImagesOnWifiOnlyKey = 'load_images_wifi_only';
  static const String _reducedPageSizeKey = 'reduced_page_size';

  // Cached settings
  bool? _lowDataMode;
  bool? _loadImagesOnWifiOnly;
  bool? _reducedPageSize;

  /// Check if Low Data Mode is enabled
  Future<bool> isLowDataModeEnabled() async {
    if (_lowDataMode != null) return _lowDataMode!;

    final prefs = await SharedPreferences.getInstance();
    _lowDataMode = prefs.getBool(_lowDataModeKey) ?? false;
    return _lowDataMode!;
  }

  /// Enable or disable Low Data Mode
  Future<void> setLowDataMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lowDataModeKey, enabled);
    _lowDataMode = enabled;

    // When enabling low data mode, also enable related settings
    if (enabled) {
      await setLoadImagesOnWifiOnly(true);
      await setReducedPageSize(true);
    }
  }

  /// Check if images should only load on WiFi
  Future<bool> shouldLoadImagesOnWifiOnly() async {
    if (_loadImagesOnWifiOnly != null) return _loadImagesOnWifiOnly!;

    final prefs = await SharedPreferences.getInstance();
    _loadImagesOnWifiOnly = prefs.getBool(_loadImagesOnWifiOnlyKey) ?? false;
    return _loadImagesOnWifiOnly!;
  }

  /// Set whether images should only load on WiFi
  Future<void> setLoadImagesOnWifiOnly(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loadImagesOnWifiOnlyKey, enabled);
    _loadImagesOnWifiOnly = enabled;
  }

  /// Check if reduced page size is enabled
  Future<bool> isReducedPageSizeEnabled() async {
    if (_reducedPageSize != null) return _reducedPageSize!;

    final prefs = await SharedPreferences.getInstance();
    _reducedPageSize = prefs.getBool(_reducedPageSizeKey) ?? false;
    return _reducedPageSize!;
  }

  /// Set whether to use reduced page size
  Future<void> setReducedPageSize(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reducedPageSizeKey, enabled);
    _reducedPageSize = enabled;
  }

  /// Get the page size based on Low Data Mode setting
  /// Normal: 20 items, Low Data Mode: 10 items
  Future<int> getPageSize() async {
    final lowDataMode = await isLowDataModeEnabled();
    return lowDataMode ? 10 : 20;
  }

  /// Get cache duration multiplier based on Low Data Mode setting
  /// Low Data Mode extends cache durations by 4x to reduce API calls
  Future<int> getCacheDurationMultiplier() async {
    final lowDataMode = await isLowDataModeEnabled();
    return lowDataMode ? 4 : 1;
  }

  /// Get all Low Data Mode settings
  Future<DataSaverSettings> getSettings() async {
    return DataSaverSettings(
      lowDataMode: await isLowDataModeEnabled(),
      loadImagesOnWifiOnly: await shouldLoadImagesOnWifiOnly(),
      reducedPageSize: await isReducedPageSizeEnabled(),
    );
  }

  /// Update all Low Data Mode settings at once
  Future<void> updateSettings(DataSaverSettings settings) async {
    await setLowDataMode(settings.lowDataMode);
    await setLoadImagesOnWifiOnly(settings.loadImagesOnWifiOnly);
    await setReducedPageSize(settings.reducedPageSize);
  }

  /// Clear cached settings (call when user logs out)
  void clearCache() {
    _lowDataMode = null;
    _loadImagesOnWifiOnly = null;
    _reducedPageSize = null;
  }
}

/// Model class for Low Data Mode settings
class DataSaverSettings {
  final bool lowDataMode;
  final bool loadImagesOnWifiOnly;
  final bool reducedPageSize;

  DataSaverSettings({
    this.lowDataMode = false,
    this.loadImagesOnWifiOnly = false,
    this.reducedPageSize = false,
  });

  /// Get page size based on settings
  int get pageSize => reducedPageSize ? 10 : 20;

  /// Get cache duration multiplier based on settings
  int get cacheDurationMultiplier => lowDataMode ? 4 : 1;

  /// Copy with new values
  DataSaverSettings copyWith({
    bool? lowDataMode,
    bool? loadImagesOnWifiOnly,
    bool? reducedPageSize,
  }) {
    return DataSaverSettings(
      lowDataMode: lowDataMode ?? this.lowDataMode,
      loadImagesOnWifiOnly: loadImagesOnWifiOnly ?? this.loadImagesOnWifiOnly,
      reducedPageSize: reducedPageSize ?? this.reducedPageSize,
    );
  }
}
