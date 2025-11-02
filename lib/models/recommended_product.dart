class RecommendedProduct {
  final int id;
  final String asin;
  final String productTitle;
  final String brandName;
  final String productPrice;
  final String productRating;
  final String productPhoto;
  final String amazonUrl;
  final bool isSafe;
  final bool fdaCheckPassed;
  final bool usdaCheckPassed;
  final int displayOrder;
  final DateTime lastVerified;

  RecommendedProduct({
    required this.id,
    required this.asin,
    required this.productTitle,
    required this.brandName,
    required this.productPrice,
    required this.productRating,
    required this.productPhoto,
    required this.amazonUrl,
    required this.isSafe,
    required this.fdaCheckPassed,
    required this.usdaCheckPassed,
    required this.displayOrder,
    required this.lastVerified,
  });

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      id: json['id'] ?? 0,
      asin: json['asin'] ?? '',
      productTitle: json['product_title'] ?? '',
      brandName: json['brand_name'] ?? '',
      productPrice: json['product_price'] ?? '',
      productRating: json['product_rating'] ?? '',
      productPhoto: json['product_photo'] ?? '',
      amazonUrl: json['amazon_url'] ?? '',
      isSafe: json['is_safe'] ?? true,
      fdaCheckPassed: json['fda_check_passed'] ?? false,
      usdaCheckPassed: json['usda_check_passed'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      lastVerified: json['last_verified'] != null
          ? DateTime.parse(json['last_verified'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asin': asin,
      'product_title': productTitle,
      'brand_name': brandName,
      'product_price': productPrice,
      'product_rating': productRating,
      'product_photo': productPhoto,
      'amazon_url': amazonUrl,
      'is_safe': isSafe,
      'fda_check_passed': fdaCheckPassed,
      'usda_check_passed': usdaCheckPassed,
      'display_order': displayOrder,
      'last_verified': lastVerified.toIso8601String(),
    };
  }
}
