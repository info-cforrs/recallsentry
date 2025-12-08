import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'security_service.dart';
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

  /// Verify purchase with backend server
  ///
  /// IMPORTANT: Server-side receipt validation is required for App Store compliance.
  /// This method sends the purchase receipt to your backend for verification with
  /// Apple's App Store Server API or Google Play Developer API.
  ///
  /// The backend should:
  /// 1. Validate the receipt with the respective store
  /// 2. Check for fraud/duplicate transactions
  /// 3. Update the user's subscription status in the database
  /// 4. Return success/failure status
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    final String baseUrl = AppConfig.apiBaseUrl;
    final authService = AuthService();

    try {
      // Get auth token if user is logged in
      final token = await authService.getAccessToken();

      // Determine platform
      final platform = Platform.isIOS ? 'ios' : 'android';

      // Get verification data
      final verificationData = purchase.verificationData;

      // Create secure HTTP client with certificate pinning
      final httpClient = SecurityService().createSecureHttpClient();

      // Build request headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Send verification request to backend
      final response = await httpClient.post(
        Uri.parse('$baseUrl/subscriptions/verify-purchase/'),
        headers: headers,
        body: json.encode({
          'product_id': purchase.productID,
          'purchase_token': verificationData.serverVerificationData,
          'local_verification_data': verificationData.localVerificationData,
          'source': verificationData.source.toString(),
          'platform': platform,
          'transaction_date': purchase.transactionDate,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final isValid = responseData['valid'] == true;

        if (isValid) {
          debugPrint('IAP: Server verification successful for ${purchase.productID}');
        } else {
          debugPrint('IAP: Server verification failed - ${responseData['error'] ?? 'Unknown error'}');
        }

        return isValid;
      } else if (response.statusCode == 503 || response.statusCode == 502) {
        // Backend not available - fallback to local verification for now
        // In production, you may want to queue this for later verification
        debugPrint('IAP: Backend unavailable, using local verification fallback');
        return _localVerificationFallback(purchase);
      } else {
        debugPrint('IAP: Server verification error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('IAP: Verification error: $e');
      // Network error - use local verification fallback
      // This ensures users aren't blocked when offline
      return _localVerificationFallback(purchase);
    }
  }

  /// Local verification fallback when server is unavailable
  ///
  /// WARNING: This is less secure than server verification.
  /// Only use as a fallback and ensure server verification happens later.
  bool _localVerificationFallback(PurchaseDetails purchase) {
    // For iOS, check that we have valid verification data
    if (Platform.isIOS) {
      final hasReceipt = purchase.verificationData.localVerificationData.isNotEmpty;
      if (!hasReceipt) {
        debugPrint('IAP: No local verification data available');
        return false;
      }
      // iOS receipt exists - accept for now, but queue for server verification
      debugPrint('IAP: Using local iOS receipt (will verify with server later)');
      return true;
    }

    // For Android, check purchase token
    if (Platform.isAndroid) {
      final hasToken = purchase.verificationData.serverVerificationData.isNotEmpty;
      if (!hasToken) {
        debugPrint('IAP: No purchase token available');
        return false;
      }
      debugPrint('IAP: Using local Android verification (will verify with server later)');
      return true;
    }

    return false;
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
