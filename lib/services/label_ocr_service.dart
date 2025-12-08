import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/product_scan_result.dart';

/// Service for extracting text from product labels using OCR
/// Uses Google Cloud Vision API via backend proxy
class LabelOcrService {
  static final LabelOcrService _instance = LabelOcrService._internal();
  factory LabelOcrService() => _instance;
  LabelOcrService._internal();

  // Backend proxy URL for OCR (protects API key)
  String get _backendBaseUrl => '${AppConfig.apiBaseUrl}/product-lookup';

  /// Scan a label image and extract fields
  Future<LabelScanResult> scanLabel(XFile imageFile) async {
    try {
      // Read image as base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send to backend for OCR processing
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/ocr/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
          'extract_fields': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LabelScanResult.fromJson(data);
      } else {
        return LabelScanResult.error(
          'OCR service error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LabelScanResult.error('Failed to scan label: $e');
    }
  }

  /// Scan a label from file path
  Future<LabelScanResult> scanLabelFromPath(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_backendBaseUrl/ocr/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
          'extract_fields': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return LabelScanResult.fromJson(data);
      } else {
        return LabelScanResult.error(
          'OCR service error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return LabelScanResult.error('Failed to scan label: $e');
    }
  }

  /// Extract fields from raw OCR text (local processing)
  /// This can be used when backend is unavailable or for testing
  LabelScanResult extractFieldsFromText(String ocrText) {
    final List<ExtractedField> fields = [];
    final normalizedText = ocrText.toUpperCase();

    // Extract UPC/Barcode numbers
    final upcField = _extractUpc(normalizedText);
    if (upcField != null) fields.add(upcField);

    // Extract Model Number
    final modelField = _extractModelNumber(normalizedText);
    if (modelField != null) fields.add(modelField);

    // Extract Serial Number
    final serialField = _extractSerialNumber(normalizedText);
    if (serialField != null) fields.add(serialField);

    // Extract Batch/Lot Code
    final lotField = _extractBatchLotCode(normalizedText);
    if (lotField != null) fields.add(lotField);

    // Extract Dates
    final dateFields = _extractDates(normalizedText);
    fields.addAll(dateFields);

    // Extract Brand Name (usually at top of label)
    final brandField = _extractBrandName(ocrText);
    if (brandField != null) fields.add(brandField);

    return LabelScanResult(
      success: fields.isNotEmpty,
      extractedFields: fields,
      fullText: ocrText,
      confidence: fields.isEmpty ? 0.0 : _calculateAverageConfidence(fields),
    );
  }

  /// Extract UPC from text
  ExtractedField? _extractUpc(String text) {
    // Pattern for UPC-A (12 digits) or EAN-13 (13 digits)
    final patterns = [
      RegExp(r'UPC[:\s#]*(\d{12,13})', caseSensitive: false),
      RegExp(r'EAN[:\s#]*(\d{13})', caseSensitive: false),
      RegExp(r'GTIN[:\s#]*(\d{12,14})', caseSensitive: false),
      // Standalone barcode number (12-13 consecutive digits)
      RegExp(r'(?<!\d)(\d{12,13})(?!\d)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.group(1) ?? match.group(0)!;
        return ExtractedField(
          fieldType: LabelFieldType.upc,
          value: value.replaceAll(RegExp(r'[^0-9]'), ''),
          confidence: 0.85,
          rawMatch: match.group(0),
          pattern: pattern.pattern,
        );
      }
    }
    return null;
  }

  /// Extract Model Number from text
  ExtractedField? _extractModelNumber(String text) {
    final patterns = [
      RegExp(r'MODEL[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'MOD(?:EL)?[:\s#\.]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'M(?:ODEL)?\.?\s*(?:NO\.?|NUMBER|#)[:\s]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'P/N[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'PART\s*(?:NO\.?|NUMBER|#)[:\s]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'SKU[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.length >= 3) {
          return ExtractedField(
            fieldType: LabelFieldType.modelNumber,
            value: value,
            confidence: 0.80,
            rawMatch: match.group(0),
            pattern: pattern.pattern,
          );
        }
      }
    }
    return null;
  }

  /// Extract Serial Number from text
  ExtractedField? _extractSerialNumber(String text) {
    final patterns = [
      RegExp(r'SERIAL[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'S/?N[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'SER(?:IAL)?\.?\s*(?:NO\.?|NUMBER|#)[:\s]*([A-Z0-9\-\.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.length >= 4) {
          return ExtractedField(
            fieldType: LabelFieldType.serialNumber,
            value: value,
            confidence: 0.80,
            rawMatch: match.group(0),
            pattern: pattern.pattern,
          );
        }
      }
    }
    return null;
  }

  /// Extract Batch/Lot Code from text
  ExtractedField? _extractBatchLotCode(String text) {
    final patterns = [
      RegExp(r'LOT[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'BATCH[:\s#]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'LOT\s*(?:NO\.?|NUMBER|#|CODE)[:\s]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'BATCH\s*(?:NO\.?|NUMBER|#|CODE)[:\s]*([A-Z0-9\-\.]+)', caseSensitive: false),
      RegExp(r'L[:\s]?([A-Z0-9]{4,})', caseSensitive: false), // Short "L:" format
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.length >= 3) {
          return ExtractedField(
            fieldType: LabelFieldType.batchLotCode,
            value: value,
            confidence: 0.75,
            rawMatch: match.group(0),
            pattern: pattern.pattern,
          );
        }
      }
    }
    return null;
  }

  /// Extract various date formats from text
  List<ExtractedField> _extractDates(String text) {
    final List<ExtractedField> dates = [];

    // Date patterns with their field types
    final datePatterns = <String, List<RegExp>>{
      'expiration': [
        RegExp(r'EXP(?:IRES?|IRY)?[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'EXP(?:IRES?|IRY)?[:\s]*(\d{2,4}[\/\-]\d{1,2}[\/\-]\d{1,2})', caseSensitive: false),
        RegExp(r'EXP(?:IRES?|IRY)?[:\s]*([A-Z]{3}\s*\d{1,2},?\s*\d{2,4})', caseSensitive: false),
        RegExp(r'USE\s*BY[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      ],
      'bestBy': [
        RegExp(r'BEST\s*(?:BY|BEFORE|IF\s*USED\s*BY)[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'BEST\s*(?:BY|BEFORE)[:\s]*([A-Z]{3}\s*\d{1,2},?\s*\d{2,4})', caseSensitive: false),
        RegExp(r'BB[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      ],
      'sellBy': [
        RegExp(r'SELL\s*BY[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'SELL\s*BY[:\s]*([A-Z]{3}\s*\d{1,2},?\s*\d{2,4})', caseSensitive: false),
      ],
      'production': [
        RegExp(r'MFG(?:\.|D)?[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'MFD[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'PROD(?:UCED|UCTION)?[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
        RegExp(r'MADE\s*ON[:\s]*(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', caseSensitive: false),
      ],
    };

    for (final entry in datePatterns.entries) {
      final dateType = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.group(1) != null) {
          LabelFieldType fieldType;
          switch (dateType) {
            case 'expiration':
              fieldType = LabelFieldType.expirationDate;
              break;
            case 'bestBy':
              fieldType = LabelFieldType.bestByDate;
              break;
            case 'sellBy':
              fieldType = LabelFieldType.sellByDate;
              break;
            case 'production':
              fieldType = LabelFieldType.productionDate;
              break;
            default:
              continue;
          }

          dates.add(ExtractedField(
            fieldType: fieldType,
            value: match.group(1)!.trim(),
            confidence: 0.70,
            rawMatch: match.group(0),
            pattern: pattern.pattern,
          ));
          break; // Only take the first match for each type
        }
      }
    }

    return dates;
  }

  /// Extract Brand Name (heuristic: usually first line or largest text)
  ExtractedField? _extractBrandName(String text) {
    // Split into lines and look for potential brand names
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2 && l.length < 50)
        .toList();

    if (lines.isEmpty) return null;

    // First line is often the brand name
    final firstLine = lines.first;

    // Skip if it looks like a model/serial number
    if (RegExp(r'^[A-Z0-9\-\.]+$').hasMatch(firstLine.toUpperCase())) {
      return null;
    }

    // Skip if it contains common label text
    final skipWords = ['MODEL', 'SERIAL', 'LOT', 'BATCH', 'EXP', 'UPC', 'MADE IN'];
    for (final word in skipWords) {
      if (firstLine.toUpperCase().contains(word)) {
        // Try the next line
        if (lines.length > 1) {
          final secondLine = lines[1];
          if (!skipWords.any((w) => secondLine.toUpperCase().contains(w))) {
            return ExtractedField(
              fieldType: LabelFieldType.brandName,
              value: secondLine,
              confidence: 0.50,
              rawMatch: secondLine,
            );
          }
        }
        return null;
      }
    }

    return ExtractedField(
      fieldType: LabelFieldType.brandName,
      value: firstLine,
      confidence: 0.60,
      rawMatch: firstLine,
    );
  }

  /// Calculate average confidence from extracted fields
  double _calculateAverageConfidence(List<ExtractedField> fields) {
    if (fields.isEmpty) return 0.0;
    final total = fields.fold(0.0, (sum, f) => sum + f.confidence);
    return total / fields.length;
  }
}
