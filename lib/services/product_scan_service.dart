import 'package:image_picker/image_picker.dart';
import '../models/product_scan_result.dart';
import 'barcode_scan_service.dart';
import 'product_lookup_service.dart';
import 'label_ocr_service.dart';

/// Unified service for product scanning
/// Combines barcode scanning, product lookup, and label OCR
class ProductScanService {
  static final ProductScanService _instance = ProductScanService._internal();
  factory ProductScanService() => _instance;
  ProductScanService._internal();

  final BarcodeScanService _barcodeService = BarcodeScanService();
  final ProductLookupService _lookupService = ProductLookupService();
  final LabelOcrService _ocrService = LabelOcrService();

  /// Scan a UPC/barcode image and look up product info
  /// Returns product details if found in database
  Future<CompleteScanResult> scanUpcImage(XFile image, {bool isFood = true}) async {
    // Step 1: Scan for barcode
    final barcodeScan = await _barcodeService.scanFromXFile(image);

    if (!barcodeScan.found || barcodeScan.barcode == null) {
      return CompleteScanResult(
        detectedBarcode: null,
        upcResult: ProductLookupResult.error('No barcode found in image'),
      );
    }

    // Step 2: Look up product info
    final productLookup = await _lookupService.lookupByUpc(
      barcodeScan.normalizedUpc ?? barcodeScan.barcode!,
      isFood: isFood,
    );

    return CompleteScanResult(
      detectedBarcode: barcodeScan.normalizedUpc ?? barcodeScan.barcode,
      upcResult: productLookup,
    );
  }

  /// Scan a product label image and extract field information
  /// Uses OCR to identify model numbers, serial numbers, etc.
  Future<CompleteScanResult> scanLabelImage(XFile image) async {
    // Step 1: Try to scan for any barcodes on the label
    final barcodeScan = await _barcodeService.scanFromXFile(image);

    // Step 2: Perform OCR on the label
    final labelScan = await _ocrService.scanLabel(image);

    // Step 3: If barcode found, try to look up product
    ProductLookupResult? productLookup;
    if (barcodeScan.found && barcodeScan.barcode != null) {
      productLookup = await _lookupService.lookupByUpc(
        barcodeScan.normalizedUpc ?? barcodeScan.barcode!,
        isFood: false, // Labels are typically on household items
      );
    }

    return CompleteScanResult(
      detectedBarcode: barcodeScan.found ? (barcodeScan.normalizedUpc ?? barcodeScan.barcode) : null,
      upcResult: productLookup,
      labelResult: labelScan,
    );
  }

  /// Perform a complete scan of all item photos
  /// Scans UPC image for barcode lookup and label image for OCR
  Future<CompleteScanResult> scanAllPhotos({
    XFile? upcPhoto,
    XFile? labelPhoto,
    XFile? frontPhoto,
    bool isFood = true,
  }) async {
    ProductLookupResult? upcResult;
    LabelScanResult? labelResult;
    String? detectedBarcode;

    // Scan UPC photo for barcode
    if (upcPhoto != null) {
      final barcodeScan = await _barcodeService.scanFromXFile(upcPhoto);
      if (barcodeScan.found && barcodeScan.barcode != null) {
        detectedBarcode = barcodeScan.normalizedUpc ?? barcodeScan.barcode;
        upcResult = await _lookupService.lookupByUpc(
          detectedBarcode!,
          isFood: isFood,
        );
      }
    }

    // Try front photo for barcode if UPC photo didn't work
    if (detectedBarcode == null && frontPhoto != null) {
      final barcodeScan = await _barcodeService.scanFromXFile(frontPhoto);
      if (barcodeScan.found && barcodeScan.barcode != null) {
        detectedBarcode = barcodeScan.normalizedUpc ?? barcodeScan.barcode;
        upcResult = await _lookupService.lookupByUpc(
          detectedBarcode!,
          isFood: isFood,
        );
      }
    }

    // Scan label photo for OCR
    if (labelPhoto != null) {
      labelResult = await _ocrService.scanLabel(labelPhoto);

      // If no barcode found yet, check label OCR for UPC
      if (detectedBarcode == null) {
        final upcField = labelResult.getField(LabelFieldType.upc);
        if (upcField != null && upcField.value.isNotEmpty) {
          detectedBarcode = upcField.value;
          upcResult = await _lookupService.lookupByUpc(
            detectedBarcode,
            isFood: isFood,
          );
        }
      }
    }

    // Try OCR on front photo if no label photo
    if (labelResult == null && frontPhoto != null) {
      labelResult = await _ocrService.scanLabel(frontPhoto);
    }

    return CompleteScanResult(
      detectedBarcode: detectedBarcode,
      upcResult: upcResult,
      labelResult: labelResult,
    );
  }

  /// Look up a product by UPC code directly (no image scanning)
  Future<ProductLookupResult> lookupUpc(String upc, {bool isFood = true}) async {
    return _lookupService.lookupByUpc(upc, isFood: isFood);
  }

  /// Validate a UPC code format
  bool isValidUpc(String upc) {
    return _lookupService.isValidUpc(upc);
  }

  /// Dispose of resources
  void dispose() {
    _barcodeService.dispose();
  }
}

/// Extension to help populate form fields from scan results
extension CompleteScanResultFormHelper on CompleteScanResult {
  /// Get a map of field values suitable for populating a form
  Map<String, String> toFormFields() {
    final fields = <String, String>{};

    // From UPC lookup
    if (upcResult?.found == true) {
      if (upcResult!.brandName != null && upcResult!.brandName!.isNotEmpty) {
        fields['brandName'] = upcResult!.brandName!;
      }
      if (upcResult!.productName != null && upcResult!.productName!.isNotEmpty) {
        fields['productName'] = upcResult!.productName!;
      }
      if (upcResult!.manufacturer != null && upcResult!.manufacturer!.isNotEmpty) {
        fields['manufacturer'] = upcResult!.manufacturer!;
      }
    }

    // UPC code
    final upc = getUpc();
    if (upc != null && upc.isNotEmpty) {
      fields['upc'] = upc;
    }

    // From label OCR
    if (labelResult?.success == true) {
      for (final field in labelResult!.extractedFields) {
        if (field.value.isEmpty) continue;

        switch (field.fieldType) {
          case LabelFieldType.modelNumber:
            fields['modelNumber'] = field.value;
            break;
          case LabelFieldType.serialNumber:
            fields['serialNumber'] = field.value;
            break;
          case LabelFieldType.batchLotCode:
            fields['batchLotCode'] = field.value;
            break;
          case LabelFieldType.brandName:
            // Only use if not already set from UPC
            fields['brandName'] ??= field.value;
            break;
          case LabelFieldType.productName:
            // Only use if not already set from UPC
            fields['productName'] ??= field.value;
            break;
          case LabelFieldType.manufacturer:
            fields['manufacturer'] ??= field.value;
            break;
          case LabelFieldType.expirationDate:
            fields['expirationDate'] = field.value;
            fields['dateType'] = 'EXPIRATION_DATE';
            break;
          case LabelFieldType.bestByDate:
            fields['bestByDate'] = field.value;
            fields['dateType'] = 'BEST_IF_USED_BY_DATE';
            break;
          case LabelFieldType.sellByDate:
            fields['sellByDate'] = field.value;
            fields['dateType'] = 'SELL_BY_OR_SOLD_BY_DATE';
            break;
          case LabelFieldType.productionDate:
            fields['productionDate'] = field.value;
            fields['dateType'] = 'PRODUCTION_DATE';
            break;
          default:
            break;
        }
      }
    }

    return fields;
  }

  /// Get list of fields that were auto-filled with their sources
  List<AutoFilledField> getAutoFilledFields() {
    final fields = <AutoFilledField>[];

    // From UPC lookup
    if (upcResult?.found == true) {
      if (upcResult!.brandName != null && upcResult!.brandName!.isNotEmpty) {
        fields.add(AutoFilledField(
          fieldName: 'Brand Name',
          value: upcResult!.brandName!,
          source: 'UPC Database',
          confidence: 0.95,
        ));
      }
      if (upcResult!.productName != null && upcResult!.productName!.isNotEmpty) {
        fields.add(AutoFilledField(
          fieldName: 'Product Name',
          value: upcResult!.productName!,
          source: 'UPC Database',
          confidence: 0.95,
        ));
      }
    }

    // UPC code itself
    final upc = getUpc();
    if (upc != null && upc.isNotEmpty) {
      fields.add(AutoFilledField(
        fieldName: 'UPC',
        value: upc,
        source: 'Barcode Scan',
        confidence: 0.99,
      ));
    }

    // From label OCR
    if (labelResult?.success == true) {
      for (final field in labelResult!.extractedFields) {
        if (field.value.isEmpty) continue;

        fields.add(AutoFilledField(
          fieldName: field.displayLabel,
          value: field.value,
          source: 'Label OCR',
          confidence: field.confidence,
        ));
      }
    }

    return fields;
  }
}

/// Represents an auto-filled field with its source
class AutoFilledField {
  final String fieldName;
  final String value;
  final String source;
  final double confidence;

  AutoFilledField({
    required this.fieldName,
    required this.value,
    required this.source,
    required this.confidence,
  });

  bool get isHighConfidence => confidence >= 0.7;
}
