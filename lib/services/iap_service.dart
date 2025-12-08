import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'subscription_service.dart';

/// Product IDs - must match Google Play Console exactly
class IAPProductIds {
  static const String smartFilteringMonthly = 'smart_filtering_monthly';
  static const String smartFilteringYearly = 'smart_filtering_yearly';
  static const String recallMatchMonthly = 'recall_match_monthly';
  static const String recallMatchYearly = 'recall_match_yearly';

  static const Set<String> all = {
    smartFilteringMonthly,
    smartFilteringYearly,
    recallMatchMonthly,
    recallMatchYearly,
  };
}

/// Service for handling in-app purchases via Google Play Billing
class IAPService {
  // Singleton
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  final Set<String> _purchasedProductIds = {};
  bool _isAvailable = false;
  bool _isInitialized = false;

  // Callbacks
  Function(SubscriptionTier)? onPurchaseSuccess;
  Function(String)? onPurchaseError;

  /// Initialize the IAP service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );

    // Load products
    await _loadProducts();

    _isInitialized = true;
    debugPrint('IAP: Initialized successfully');
  }

  /// Load available products from the store
  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(IAPProductIds.all);

    if (response.error != null) {
      debugPrint('IAP: Failed to load products - ${response.error}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found - ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('IAP: Loaded ${_products.length} products');
  }

  /// Handle purchase stream updates
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Process a single purchase
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('IAP: Processing purchase ${purchase.productID} - ${purchase.status}');

    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Show loading indicator
        break;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Verify purchase on your backend (recommended for security)
        final verified = await _verifyPurchase(purchase);

        if (verified) {
          _purchasedProductIds.add(purchase.productID);
          final tier = _getTierFromProductId(purchase.productID);

          // Clear subscription cache
          SubscriptionService().clearCache();

          onPurchaseSuccess?.call(tier);
          debugPrint('IAP: Purchase successful - $tier');
        } else {
          onPurchaseError?.call('Purchase verification failed');
        }
        break;

      case PurchaseStatus.error:
        onPurchaseError?.call(purchase.error?.message ?? 'Purchase failed');
        break;

      case PurchaseStatus.canceled:
        debugPrint('IAP: Purchase cancelled');
        break;
    }

    // Complete the purchase (required for Google Play)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Verify purchase with backend (stub - implement your server verification)
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Send purchase.verificationData to your backend for verification
    // For now, accept all purchases (NOT RECOMMENDED for production)
    //
    // Example backend verification:
    // final response = await http.post(
    //   Uri.parse('$baseUrl/verify-purchase/'),
    //   body: {
    //     'product_id': purchase.productID,
    //     'purchase_token': purchase.verificationData.serverVerificationData,
    //     'platform': Platform.isAndroid ? 'android' : 'ios',
    //   },
    // );
    // return response.statusCode == 200;

    return true;
  }

  /// Get subscription tier from product ID
  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('recall_match')) {
      return SubscriptionTier.recallMatch;
    } else if (productId.contains('smart_filtering')) {
      return SubscriptionTier.smartFiltering;
    }
    return SubscriptionTier.free;
  }

  /// Get available products
  List<ProductDetails> get products => _products;

  /// Check if store is available
  bool get isAvailable => _isAvailable;

  /// Purchase a product
  Future<bool> purchase(ProductDetails product) async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Use buyNonConsumable for subscriptions
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      onPurchaseError?.call('Failed to initiate purchase: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseError?.call('Store not available');
      return;
    }

    try {
      await _iap.restorePurchases();
    } catch (e) {
      onPurchaseError?.call('Failed to restore purchases: $e');
    }
  }

  /// Check if user has an active subscription
  bool hasActiveSubscription() {
    return _purchasedProductIds.isNotEmpty;
  }

  /// Get current tier based on purchases
  SubscriptionTier getCurrentTier() {
    for (final productId in _purchasedProductIds) {
      if (productId.contains('recall_match')) {
        return SubscriptionTier.recallMatch;
      }
    }
    for (final productId in _purchasedProductIds) {
      if (productId.contains('smart_filtering')) {
        return SubscriptionTier.smartFiltering;
      }
    }
    return SubscriptionTier.free;
  }

  /// Clean up
  void dispose() {
    _subscription?.cancel();
  }
}
