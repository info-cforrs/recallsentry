import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result from VIN decoding
class VinDecodeResult {
  final bool success;
  final String? errorMessage;
  final String? make;
  final String? model;
  final String? year;
  final String? trim;
  final String? bodyClass;
  final String? driveType;
  final String? fuelType;
  final String? engineCylinders;
  final String? engineDisplacement;
  final String? manufacturer;
  final String? plantCountry;
  final String? vehicleType;

  VinDecodeResult({
    required this.success,
    this.errorMessage,
    this.make,
    this.model,
    this.year,
    this.trim,
    this.bodyClass,
    this.driveType,
    this.fuelType,
    this.engineCylinders,
    this.engineDisplacement,
    this.manufacturer,
    this.plantCountry,
    this.vehicleType,
  });

  factory VinDecodeResult.error(String message) {
    return VinDecodeResult(success: false, errorMessage: message);
  }

  factory VinDecodeResult.fromNhtsaResponse(Map<String, dynamic> json) {
    try {
      final results = json['Results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return VinDecodeResult.error('No results from VIN decode');
      }

      // NHTSA returns an array of variable/value pairs
      String? getValue(String variableName) {
        for (final item in results) {
          if (item['Variable'] == variableName) {
            final value = item['Value'];
            if (value != null && value.toString().isNotEmpty && value != 'Not Applicable') {
              return value.toString();
            }
          }
        }
        return null;
      }

      // Check for error codes
      final errorCode = getValue('Error Code');
      if (errorCode != null && errorCode != '0') {
        final errorText = getValue('Error Text') ?? 'Unknown error';
        // Error code 1 means partial data, which is still usable
        if (errorCode != '1') {
          return VinDecodeResult.error(errorText);
        }
      }

      return VinDecodeResult(
        success: true,
        make: getValue('Make'),
        model: getValue('Model'),
        year: getValue('Model Year'),
        trim: getValue('Trim'),
        bodyClass: getValue('Body Class'),
        driveType: getValue('Drive Type'),
        fuelType: getValue('Fuel Type - Primary'),
        engineCylinders: getValue('Engine Number of Cylinders'),
        engineDisplacement: getValue('Displacement (L)'),
        manufacturer: getValue('Manufacturer Name'),
        plantCountry: getValue('Plant Country'),
        vehicleType: getValue('Vehicle Type'),
      );
    } catch (e) {
      return VinDecodeResult.error('Failed to parse VIN decode response: $e');
    }
  }

  @override
  String toString() {
    if (!success) return 'VinDecodeResult(error: $errorMessage)';
    return 'VinDecodeResult(make: $make, model: $model, year: $year, trim: $trim)';
  }
}

/// Service for decoding VINs using NHTSA's vPIC API
class VinDecodeService {
  static final VinDecodeService _instance = VinDecodeService._internal();
  factory VinDecodeService() => _instance;
  VinDecodeService._internal();

  static const String _baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  /// Decode a VIN using NHTSA's API
  /// Returns decoded vehicle information including make, model, year, etc.
  Future<VinDecodeResult> decodeVin(String vin) async {
    debugPrint('🚗 VinDecodeService.decodeVin called with: $vin');

    // Validate VIN format
    final cleanVin = vin.toUpperCase().replaceAll(RegExp(r'[^A-HJ-NPR-Z0-9]'), '');
    debugPrint('🔧 Cleaned VIN: $cleanVin (length: ${cleanVin.length})');

    if (cleanVin.length != 17) {
      debugPrint('❌ Invalid VIN length');
      return VinDecodeResult.error('Invalid VIN length. VIN must be 17 characters.');
    }

    try {
      final url = Uri.parse('$_baseUrl/decodevin/$cleanVin?format=json');
      debugPrint('🌐 Calling NHTSA API: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      debugPrint('📡 API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ API returned error status: ${response.statusCode}');
        return VinDecodeResult.error('Failed to decode VIN: HTTP ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('✅ API response received, parsing...');
      final result = VinDecodeResult.fromNhtsaResponse(json);
      debugPrint('📊 Parsed result: ${result.toString()}');
      return result;
    } catch (e) {
      debugPrint('❌ VIN decode error: $e');
      return VinDecodeResult.error('Failed to decode VIN: $e');
    }
  }

  /// Extract model year from VIN character 10 (position index 9)
  /// This is a quick local decode without API call
  String? extractYearFromVin(String vin) {
    if (vin.length < 10) return null;

    final yearChar = vin[9].toUpperCase();

    // Year codes:
    // For years 1980-2000: A=1980, B=1981, ..., Y=2000 (skipping I, O, Q, U, Z)
    // For years 2001-2009: 1=2001, 2=2002, ..., 9=2009
    // For years 2010-2039: A=2010, B=2011, ..., (cycle repeats)

    const yearCodes = {
      'A': [1980, 2010], 'B': [1981, 2011], 'C': [1982, 2012],
      'D': [1983, 2013], 'E': [1984, 2014], 'F': [1985, 2015],
      'G': [1986, 2016], 'H': [1987, 2017], 'J': [1988, 2018],
      'K': [1989, 2019], 'L': [1990, 2020], 'M': [1991, 2021],
      'N': [1992, 2022], 'P': [1993, 2023], 'R': [1994, 2024],
      'S': [1995, 2025], 'T': [1996, 2026], 'V': [1997, 2027],
      'W': [1998, 2028], 'X': [1999, 2029], 'Y': [2000, 2030],
      '1': [2001, 2031], '2': [2002, 2032], '3': [2003, 2033],
      '4': [2004, 2034], '5': [2005, 2035], '6': [2006, 2036],
      '7': [2007, 2037], '8': [2008, 2038], '9': [2009, 2039],
    };

    final years = yearCodes[yearChar];
    if (years == null) return null;

    // Determine which cycle based on current year
    final currentYear = DateTime.now().year;
    // If the second cycle year is in the future or recent past (within 1 year), use it
    // Otherwise use the first cycle
    if (years[1] <= currentYear + 1) {
      return years[1].toString();
    } else {
      return years[0].toString();
    }
  }
}
