import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product_scan_result.dart';

/// Service for looking up product information from UPC codes
/// Uses Open Food Facts (for food) and UPCitemdb (for household items)
class ProductLookupService {
  static final ProductLookupService _instance = ProductLookupService._internal();
  factory ProductLookupService() => _instance;
  ProductLookupService._internal();

  // API endpoints
  static const String _openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v2';
  static const String _upcItemDbBaseUrl = 'https://api.upcitemdb.com/prod/trial';

  // Backend proxy URL (for API key protection)
  String get _backendBaseUrl => '${AppConfig.apiBaseUrl}/product-lookup';

  // User agent for Open Food Facts (required by their API)
  static const String _userAgent = 'RecallSentry/1.0 (contact@recallsentry.com)';

  /// Look up a product by UPC code
  /// Tries Open Food Facts first (for food items), then falls back to UPCitemdb
  Future<ProductLookupResult> lookupByUpc(String upc, {bool isFood = true}) async {
    // Normalize UPC
    final normalizedUpc = _normalizeUpc(upc);

    if (normalizedUpc.isEmpty) {
      return ProductLookupResult.error('Invalid UPC code');
    }

    if (isFood) {
      // Try Open Food Facts first for food items
      final offResult = await _lookupOpenFoodFacts(normalizedUpc);
      if (offResult.found) {
        return offResult;
      }

      // Fall back to UPCitemdb
      final upcDbResult = await _lookupUpcItemDb(normalizedUpc);
      if (upcDbResult.found) {
        return upcDbResult;
      }

      return ProductLookupResult.notFound(normalizedUpc);
    } else {
      // Try UPCitemdb first for household items
      final upcDbResult = await _lookupUpcItemDb(normalizedUpc);
      if (upcDbResult.found) {
        return upcDbResult;
      }

      // Fall back to Open Food Facts (some household items might be there)
      final offResult = await _lookupOpenFoodFacts(normalizedUpc);
      if (offResult.found) {
        return offResult;
      }

      return ProductLookupResult.notFound(normalizedUpc);
    }
  }

  /// Look up product via backend proxy (recommended for production)
  /// Backend handles API key management and caching
  Future<ProductLookupResult> lookupViaBackend(String upc, {bool isFood = true}) async {
    try {
      final normalizedUpc = _normalizeUpc(upc);

      final response = await http.post(
        Uri.parse('$_backendBaseUrl/lookup/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'upc': normalizedUpc,
          'is_food': isFood,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ProductLookupResult.fromJson(data);
      } else {
        return ProductLookupResult.error(
          'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Fall back to direct API calls if backend is unavailable
      print('Backend lookup failed, falling back to direct API: $e');
      return lookupByUpc(upc, isFood: isFood);
    }
  }

  /// Look up product in Open Food Facts database
  Future<ProductLookupResult> _lookupOpenFoodFacts(String upc) async {
    try {
      final response = await http.get(
        Uri.parse('$_openFoodFactsBaseUrl/product/$upc.json'),
        headers: {
          'User-Agent': _userAgent,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if product was found
        final status = data['status'] as int?;
        if (status != 1) {
          return ProductLookupResult.notFound(upc);
        }

        return ProductLookupResult.fromOpenFoodFacts(data);
      } else if (response.statusCode == 404) {
        return ProductLookupResult.notFound(upc);
      } else {
        return ProductLookupResult.error(
          'Open Food Facts API error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Open Food Facts lookup error: $e');
      return ProductLookupResult.error('Network error: $e');
    }
  }

  /// Look up product in UPCitemdb database
  /// Note: Free trial is limited to 100 requests/day
  Future<ProductLookupResult> _lookupUpcItemDb(String upc) async {
    try {
      final response = await http.get(
        Uri.parse('$_upcItemDbBaseUrl/lookup?upc=$upc'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check if product was found
        final code = data['code'] as String?;
        if (code == 'OK') {
          return ProductLookupResult.fromUpcItemDb(data);
        }

        return ProductLookupResult.notFound(upc);
      } else if (response.statusCode == 404) {
        return ProductLookupResult.notFound(upc);
      } else if (response.statusCode == 429) {
        return ProductLookupResult.error(
          'API rate limit exceeded. Please try again later.',
        );
      } else {
        return ProductLookupResult.error(
          'UPCitemdb API error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('UPCitemdb lookup error: $e');
      return ProductLookupResult.error('Network error: $e');
    }
  }

  /// Normalize a UPC code (remove non-numeric characters, pad if needed)
  String _normalizeUpc(String upc) {
    // Remove non-numeric characters
    String cleaned = upc.replaceAll(RegExp(r'[^0-9]'), '');

    // Handle common formats
    if (cleaned.length == 11) {
      // Missing check digit or leading zero - add leading zero
      cleaned = '0$cleaned';
    } else if (cleaned.length == 7) {
      // UPC-E without number system and check digit
      cleaned = '0${cleaned}0';
    }

    return cleaned;
  }

  /// Validate a UPC code
  bool isValidUpc(String upc) {
    final cleaned = _normalizeUpc(upc);

    // UPC-A is 12 digits, UPC-E is 8 digits, EAN-13 is 13 digits
    if (cleaned.length != 8 && cleaned.length != 12 && cleaned.length != 13) {
      return false;
    }

    // Verify check digit
    return _verifyCheckDigit(cleaned);
  }

  /// Verify the check digit of a UPC/EAN code
  bool _verifyCheckDigit(String code) {
    if (code.length < 8) return false;

    int sum = 0;
    final digits = code.split('').map(int.parse).toList();
    final checkDigit = digits.last;

    // Calculate check digit
    for (int i = 0; i < digits.length - 1; i++) {
      if (code.length == 13) {
        // EAN-13: odd positions * 1, even positions * 3
        sum += digits[i] * (i % 2 == 0 ? 1 : 3);
      } else {
        // UPC-A/UPC-E: odd positions * 3, even positions * 1
        sum += digits[i] * (i % 2 == 0 ? 3 : 1);
      }
    }

    final calculatedCheck = (10 - (sum % 10)) % 10;
    return calculatedCheck == checkDigit;
  }
}
