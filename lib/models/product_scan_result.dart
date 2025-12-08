/// Models for product scanning (UPC lookup and label OCR)
library;

/// Result from UPC barcode lookup
class ProductLookupResult {
  final bool found;
  final String? upc;
  final String? brandName;
  final String? productName;
  final String? manufacturer;
  final String? category;
  final String? description;
  final String? imageUrl;
  final String? source; // 'open_food_facts', 'upcitemdb', etc.
  final Map<String, dynamic>? rawData;
  final String? errorMessage;

  ProductLookupResult({
    required this.found,
    this.upc,
    this.brandName,
    this.productName,
    this.manufacturer,
    this.category,
    this.description,
    this.imageUrl,
    this.source,
    this.rawData,
    this.errorMessage,
  });

  factory ProductLookupResult.notFound(String upc) {
    return ProductLookupResult(
      found: false,
      upc: upc,
      errorMessage: 'Product not found in database',
    );
  }

  factory ProductLookupResult.error(String message) {
    return ProductLookupResult(
      found: false,
      errorMessage: message,
    );
  }

  factory ProductLookupResult.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) {
      return ProductLookupResult.notFound(json['code']?.toString() ?? '');
    }

    return ProductLookupResult(
      found: true,
      upc: product['code']?.toString() ?? json['code']?.toString(),
      brandName: product['brands']?.toString(),
      productName: product['product_name']?.toString(),
      manufacturer: product['manufacturing_places']?.toString(),
      category: product['categories']?.toString(),
      description: product['generic_name']?.toString(),
      imageUrl: product['image_url']?.toString(),
      source: 'open_food_facts',
      rawData: product,
    );
  }

  factory ProductLookupResult.fromUpcItemDb(Map<String, dynamic> json) {
    final items = json['items'] as List?;
    if (items == null || items.isEmpty) {
      return ProductLookupResult.notFound(json['code']?.toString() ?? '');
    }

    final item = items.first as Map<String, dynamic>;
    return ProductLookupResult(
      found: true,
      upc: item['upc']?.toString() ?? item['ean']?.toString(),
      brandName: item['brand']?.toString(),
      productName: item['title']?.toString(),
      manufacturer: item['manufacturer']?.toString(),
      category: item['category']?.toString(),
      description: item['description']?.toString(),
      imageUrl: (item['images'] as List?)?.firstOrNull?.toString(),
      source: 'upcitemdb',
      rawData: item,
    );
  }

  factory ProductLookupResult.fromJson(Map<String, dynamic> json) {
    return ProductLookupResult(
      found: json['found'] as bool? ?? false,
      upc: json['upc'] as String?,
      brandName: json['brand_name'] as String?,
      productName: json['product_name'] as String?,
      manufacturer: json['manufacturer'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      source: json['source'] as String?,
      rawData: json['raw_data'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'found': found,
      'upc': upc,
      'brand_name': brandName,
      'product_name': productName,
      'manufacturer': manufacturer,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'source': source,
      'raw_data': rawData,
      'error_message': errorMessage,
    };
  }
}

/// Result from label OCR scanning
class LabelScanResult {
  final bool success;
  final List<ExtractedField> extractedFields;
  final String? fullText;
  final String? errorMessage;
  final double? confidence;

  LabelScanResult({
    required this.success,
    this.extractedFields = const [],
    this.fullText,
    this.errorMessage,
    this.confidence,
  });

  factory LabelScanResult.error(String message) {
    return LabelScanResult(
      success: false,
      errorMessage: message,
    );
  }

  factory LabelScanResult.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['extracted_fields'] as List? ?? [];
    final fields = fieldsJson
        .map((f) => ExtractedField.fromJson(f as Map<String, dynamic>))
        .toList();

    return LabelScanResult(
      success: json['success'] as bool? ?? false,
      extractedFields: fields,
      fullText: json['full_text'] as String?,
      errorMessage: json['error_message'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  /// Get field by type
  ExtractedField? getField(LabelFieldType type) {
    try {
      return extractedFields.firstWhere((f) => f.fieldType == type);
    } catch (_) {
      return null;
    }
  }

  /// Get all high-confidence fields (>= 0.7)
  List<ExtractedField> get highConfidenceFields {
    return extractedFields.where((f) => f.confidence >= 0.7).toList();
  }
}

/// Types of fields that can be extracted from labels
enum LabelFieldType {
  upc,
  modelNumber,
  serialNumber,
  batchLotCode,
  productName,
  brandName,
  manufacturer,
  productionDate,
  expirationDate,
  bestByDate,
  sellByDate,
  unknown,
}

/// A single extracted field from label OCR
class ExtractedField {
  final LabelFieldType fieldType;
  final String value;
  final double confidence;
  final String? rawMatch; // The original text that was matched
  final String? pattern; // The pattern that matched (for debugging)

  ExtractedField({
    required this.fieldType,
    required this.value,
    required this.confidence,
    this.rawMatch,
    this.pattern,
  });

  factory ExtractedField.fromJson(Map<String, dynamic> json) {
    return ExtractedField(
      fieldType: _parseFieldType(json['field_type'] as String?),
      value: json['value'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      rawMatch: json['raw_match'] as String?,
      pattern: json['pattern'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_type': fieldType.name,
      'value': value,
      'confidence': confidence,
      'raw_match': rawMatch,
      'pattern': pattern,
    };
  }

  static LabelFieldType _parseFieldType(String? type) {
    switch (type?.toLowerCase()) {
      case 'upc':
        return LabelFieldType.upc;
      case 'model_number':
      case 'modelnumber':
      case 'model':
        return LabelFieldType.modelNumber;
      case 'serial_number':
      case 'serialnumber':
      case 'serial':
        return LabelFieldType.serialNumber;
      case 'batch_lot_code':
      case 'batchlotcode':
      case 'lot':
      case 'batch':
        return LabelFieldType.batchLotCode;
      case 'product_name':
      case 'productname':
        return LabelFieldType.productName;
      case 'brand_name':
      case 'brandname':
      case 'brand':
        return LabelFieldType.brandName;
      case 'manufacturer':
        return LabelFieldType.manufacturer;
      case 'production_date':
      case 'productiondate':
        return LabelFieldType.productionDate;
      case 'expiration_date':
      case 'expirationdate':
      case 'exp_date':
        return LabelFieldType.expirationDate;
      case 'best_by_date':
      case 'bestbydate':
        return LabelFieldType.bestByDate;
      case 'sell_by_date':
      case 'sellbydate':
        return LabelFieldType.sellByDate;
      default:
        return LabelFieldType.unknown;
    }
  }

  /// Human-readable label for the field type
  String get displayLabel {
    switch (fieldType) {
      case LabelFieldType.upc:
        return 'UPC';
      case LabelFieldType.modelNumber:
        return 'Model Number';
      case LabelFieldType.serialNumber:
        return 'Serial Number';
      case LabelFieldType.batchLotCode:
        return 'Batch/Lot Code';
      case LabelFieldType.productName:
        return 'Product Name';
      case LabelFieldType.brandName:
        return 'Brand Name';
      case LabelFieldType.manufacturer:
        return 'Manufacturer';
      case LabelFieldType.productionDate:
        return 'Production Date';
      case LabelFieldType.expirationDate:
        return 'Expiration Date';
      case LabelFieldType.bestByDate:
        return 'Best By Date';
      case LabelFieldType.sellByDate:
        return 'Sell By Date';
      case LabelFieldType.unknown:
        return 'Unknown';
    }
  }

  /// Whether this is a high-confidence match
  bool get isHighConfidence => confidence >= 0.7;
}

/// Combined scan result (UPC + Label OCR)
class CompleteScanResult {
  final ProductLookupResult? upcResult;
  final LabelScanResult? labelResult;
  final String? detectedBarcode;

  CompleteScanResult({
    this.upcResult,
    this.labelResult,
    this.detectedBarcode,
  });

  /// Get the best value for a field, preferring UPC lookup over OCR
  String? getBrandName() {
    if (upcResult?.brandName != null && upcResult!.brandName!.isNotEmpty) {
      return upcResult!.brandName;
    }
    return labelResult?.getField(LabelFieldType.brandName)?.value;
  }

  String? getProductName() {
    if (upcResult?.productName != null && upcResult!.productName!.isNotEmpty) {
      return upcResult!.productName;
    }
    return labelResult?.getField(LabelFieldType.productName)?.value;
  }

  String? getUpc() {
    if (detectedBarcode != null && detectedBarcode!.isNotEmpty) {
      return detectedBarcode;
    }
    if (upcResult?.upc != null && upcResult!.upc!.isNotEmpty) {
      return upcResult!.upc;
    }
    return labelResult?.getField(LabelFieldType.upc)?.value;
  }

  String? getModelNumber() {
    return labelResult?.getField(LabelFieldType.modelNumber)?.value;
  }

  String? getSerialNumber() {
    return labelResult?.getField(LabelFieldType.serialNumber)?.value;
  }

  String? getBatchLotCode() {
    return labelResult?.getField(LabelFieldType.batchLotCode)?.value;
  }

  String? getManufacturer() {
    if (upcResult?.manufacturer != null && upcResult!.manufacturer!.isNotEmpty) {
      return upcResult!.manufacturer;
    }
    return labelResult?.getField(LabelFieldType.manufacturer)?.value;
  }

  /// Check if any useful data was found
  bool get hasData {
    return (upcResult?.found == true) ||
        (labelResult?.success == true && labelResult!.extractedFields.isNotEmpty);
  }
}
