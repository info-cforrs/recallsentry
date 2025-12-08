import 'dart:io';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

/// Service for scanning barcodes/UPCs from images using Google ML Kit
class BarcodeScanService {
  static final BarcodeScanService _instance = BarcodeScanService._internal();
  factory BarcodeScanService() => _instance;
  BarcodeScanService._internal();

  BarcodeScanner? _barcodeScanner;

  /// Get or create the barcode scanner instance
  BarcodeScanner get _scanner {
    _barcodeScanner ??= BarcodeScanner(formats: [
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417, // Common format for VIN barcodes on door jambs
    ]);
    return _barcodeScanner!;
  }

  /// Scan barcode from an XFile (image picker result)
  Future<BarcodeScanResult> scanFromXFile(XFile file) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      return await _scanImage(inputImage);
    } catch (e) {
      return BarcodeScanResult.error('Failed to scan image: $e');
    }
  }

  /// Scan barcode from a File
  Future<BarcodeScanResult> scanFromFile(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      return await _scanImage(inputImage);
    } catch (e) {
      return BarcodeScanResult.error('Failed to scan image: $e');
    }
  }

  /// Scan barcode from a file path
  Future<BarcodeScanResult> scanFromPath(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      return await _scanImage(inputImage);
    } catch (e) {
      return BarcodeScanResult.error('Failed to scan image: $e');
    }
  }

  /// Internal method to scan an InputImage
  Future<BarcodeScanResult> _scanImage(InputImage inputImage) async {
    try {
      final List<Barcode> barcodes = await _scanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        return BarcodeScanResult(
          found: false,
          message: 'No barcode found in image',
        );
      }

      // Find the best barcode (prefer UPC/EAN formats)
      Barcode? bestBarcode;
      for (final barcode in barcodes) {
        if (_isProductBarcode(barcode.format)) {
          bestBarcode = barcode;
          break;
        }
      }

      // Fall back to first barcode if no product barcode found
      bestBarcode ??= barcodes.first;

      return BarcodeScanResult(
        found: true,
        barcode: bestBarcode.rawValue,
        format: _formatToString(bestBarcode.format),
        allBarcodes: barcodes
            .map((b) => ScannedBarcode(
                  value: b.rawValue ?? '',
                  format: _formatToString(b.format),
                ))
            .toList(),
      );
    } catch (e) {
      return BarcodeScanResult.error('Barcode scanning failed: $e');
    }
  }

  /// Check if barcode format is a product barcode (UPC/EAN)
  bool _isProductBarcode(BarcodeFormat format) {
    return format == BarcodeFormat.upca ||
        format == BarcodeFormat.upce ||
        format == BarcodeFormat.ean13 ||
        format == BarcodeFormat.ean8;
  }

  /// Convert BarcodeFormat to string
  String _formatToString(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.upca:
        return 'UPC-A';
      case BarcodeFormat.upce:
        return 'UPC-E';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      default:
        return 'Unknown';
    }
  }

  /// Dispose of the scanner when no longer needed
  void dispose() {
    _barcodeScanner?.close();
    _barcodeScanner = null;
  }
}

/// Result of a barcode scan
class BarcodeScanResult {
  final bool found;
  final String? barcode;
  final String? format;
  final List<ScannedBarcode> allBarcodes;
  final String? message;
  final String? errorMessage;

  BarcodeScanResult({
    required this.found,
    this.barcode,
    this.format,
    this.allBarcodes = const [],
    this.message,
    this.errorMessage,
  });

  factory BarcodeScanResult.error(String message) {
    return BarcodeScanResult(
      found: false,
      errorMessage: message,
    );
  }

  /// Check if this is a UPC/EAN barcode
  bool get isProductBarcode {
    return format == 'UPC-A' ||
        format == 'UPC-E' ||
        format == 'EAN-13' ||
        format == 'EAN-8';
  }

  /// Get a normalized UPC (12 digits for UPC-A, convert UPC-E to UPC-A)
  String? get normalizedUpc {
    if (barcode == null) return null;

    final cleanBarcode = barcode!.replaceAll(RegExp(r'[^0-9]'), '');

    if (format == 'UPC-A' && cleanBarcode.length == 12) {
      return cleanBarcode;
    }

    if (format == 'UPC-E' && cleanBarcode.length == 8) {
      // Convert UPC-E to UPC-A
      return _upcEToUpcA(cleanBarcode);
    }

    if (format == 'EAN-13' && cleanBarcode.length == 13) {
      // If it starts with 0, it's a UPC-A with leading zero
      if (cleanBarcode.startsWith('0')) {
        return cleanBarcode.substring(1);
      }
      return cleanBarcode;
    }

    if (format == 'EAN-8' && cleanBarcode.length == 8) {
      return cleanBarcode;
    }

    return cleanBarcode;
  }

  /// Convert UPC-E (8 digits) to UPC-A (12 digits)
  String _upcEToUpcA(String upcE) {
    if (upcE.length != 8) return upcE;

    final numberSystem = upcE[0];
    final manufacturer = upcE.substring(1, 6);
    final lastDigit = upcE[6];
    final checkDigit = upcE[7];

    String expanded;
    switch (lastDigit) {
      case '0':
      case '1':
      case '2':
        expanded =
            '${manufacturer.substring(0, 2)}${lastDigit}0000${manufacturer.substring(2)}';
        break;
      case '3':
        expanded = '${manufacturer.substring(0, 3)}00000${manufacturer.substring(3, 5)}';
        break;
      case '4':
        expanded = '${manufacturer.substring(0, 4)}00000${manufacturer[4]}';
        break;
      default:
        expanded = '${manufacturer}0000$lastDigit';
    }

    return '$numberSystem$expanded$checkDigit';
  }
}

/// A single scanned barcode
class ScannedBarcode {
  final String value;
  final String format;

  ScannedBarcode({
    required this.value,
    required this.format,
  });
}
