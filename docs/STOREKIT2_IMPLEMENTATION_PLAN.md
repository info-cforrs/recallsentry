# StoreKit2 In-App Purchase Implementation Plan

**App:** RecallSentry
**Status:** REQUIRED for App Store submission
**Priority:** CRITICAL
**Estimated Time:** 1-2 weeks

---

## Overview

RecallSentry currently manages subscriptions server-side only. Apple App Store **REQUIRES** native StoreKit2 integration for all digital goods and subscriptions.

### Current Subscription Tiers
1. **Free** - $0/month
   - Last 30 days of recalls
   - FDA & USDA only
   - Save up to 5 recalls
   - Filter by 1 state

2. **SmartFiltering** - $0.99/month
   - Since Jan 1 of current year
   - FDA, USDA, CPSC
   - Save up to 50 recalls
   - Filter by 5 states
   - SmartFilters (brand/product matching)

3. **RecallMatch** - $4.99/month (Premium)
   - Since Jan 1 of current year
   - FDA, USDA, CPSC, NHTSA
   - Unlimited saved recalls
   - Unlimited state filters
   - SmartFilters + RecallMatch engine
   - Recall Management Center (RMC)
   - SmartScan barcode scanning
   - Household inventory

---

## Required Changes

### Phase 1: App Store Connect Setup (Day 1)
- [ ] Create In-App Purchase products in App Store Connect
  - Product ID: `com.recallsentry.smartfiltering.monthly`
  - Product ID: `com.recallsentry.recallmatch.monthly`
- [ ] Configure auto-renewable subscriptions
- [ ] Set up subscription groups
- [ ] Add pricing for all regions
- [ ] Submit for Apple review (can be done before app submission)

### Phase 2: Flutter Package Integration (Days 2-3)
- [ ] Add `in_app_purchase` package to pubspec.yaml
  ```yaml
  dependencies:
    in_app_purchase: ^3.1.13
  ```
- [ ] Run `flutter pub get`
- [ ] Configure iOS capabilities in Xcode

### Phase 3: iOS Native Configuration (Day 3)
- [ ] Enable In-App Purchase capability in Xcode
  - Open `ios/Runner.xcworkspace`
  - Select Runner target → Signing & Capabilities
  - Add "In-App Purchase" capability
- [ ] Update entitlements file
- [ ] Configure StoreKit configuration file for local testing

### Phase 4: Create IAP Service (Days 4-6)

**File:** `lib/services/iap_service.dart`

```dart
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'dart:async';
import 'dart:io';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;

  // Product IDs
  static const String smartFilteringMonthly = 'com.recallsentry.smartfiltering.monthly';
  static const String recallMatchMonthly = 'com.recallsentry.recallmatch.monthly';

  // Available products
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isAvailable => _iap.isAvailable();

  /// Initialize IAP service
  Future<void> initialize() async {
    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('IAP Error: $error'),
    );

    // Load products
    await loadProducts();
  }

  /// Load products from App Store
  Future<void> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      print('IAP not available');
      return;
    }

    const productIds = {
      smartFilteringMonthly,
      recallMatchMonthly,
    };

    final response = await _iap.queryProductDetails(productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  /// Purchase a product
  Future<void> purchaseProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (var purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        // Verify receipt with backend
        await _verifyAndDeliverProduct(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        print('Purchase error: ${purchase.error}');
      }

      // Complete purchase
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Verify receipt with backend
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchase) async {
    // TODO: Send receipt to backend for verification
    // Backend should validate with Apple and update user's subscription

    // Example:
    // final response = await http.post(
    //   Uri.parse('$baseUrl/iap/verify-receipt/'),
    //   headers: {
    //     'Authorization': 'Bearer $token',
    //     'Content-Type': 'application/json',
    //   },
    //   body: json.encode({
    //     'receipt_data': purchase.verificationData.serverVerificationData,
    //     'product_id': purchase.productID,
    //   }),
    // );
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }

  // Getters
  List<ProductDetails> get products => _products;
  ProductDetails? getProduct(String productId) {
    return _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );
  }
}
```

### Phase 5: Update Subscription Service (Days 7-8)

**File:** `lib/services/subscription_service.dart`

Add methods to work with IAP:
```dart
/// Check subscription status from both backend AND IAP receipt
Future<SubscriptionInfo> getSubscriptionInfo() async {
  // 1. Get from backend (current implementation)
  final backendInfo = await _getFromBackend();

  // 2. If iOS, verify with App Store receipt
  if (Platform.isIOS) {
    final iapTier = await _getIAPSubscriptionTier();
    // Use the higher tier (in case of sync issues)
    if (iapTier.index > backendInfo.tier.index) {
      return SubscriptionInfo(tier: iapTier, ...);
    }
  }

  return backendInfo;
}

/// Get subscription tier from IAP receipt
Future<SubscriptionTier> _getIAPSubscriptionTier() async {
  // Query active subscriptions from StoreKit
  // Return the tier based on active subscription
}
```

### Phase 6: Create Subscribe Page UI (Days 9-10)

**File:** `lib/pages/subscribe_page.dart`

Update to show IAP products:
```dart
class SubscribePage extends StatefulWidget {
  // Load IAP products
  // Show pricing from App Store (not hardcoded)
  // Handle purchase flow
  // Show restore purchases button
}
```

### Phase 7: Backend API Endpoints (Days 11-12)

**Backend:** Django/Python

Create new endpoints:
```python
POST /api/iap/verify-receipt/
  - Receives App Store receipt data
  - Validates with Apple's verifyReceipt API
  - Updates user's subscription in database
  - Returns verification result

POST /api/iap/webhook/
  - Receives App Store Server Notifications
  - Handles subscription lifecycle events:
    * INITIAL_BUY
    * RENEWAL
    * CANCEL
    * EXPIRED
    * DID_CHANGE_RENEWAL_STATUS
  - Updates user subscription status
```

### Phase 8: Receipt Verification (Days 13-14)

Implement server-side receipt verification:
```python
import requests
import json

def verify_receipt(receipt_data, is_sandbox=False):
    """Verify iOS receipt with Apple"""
    url = 'https://buy.itunes.apple.com/verifyReceipt'
    if is_sandbox:
        url = 'https://sandbox.itunes.apple.com/verifyReceipt'

    payload = {
        'receipt-data': receipt_data,
        'password': APPLE_SHARED_SECRET,  # From App Store Connect
        'exclude-old-transactions': True,
    }

    response = requests.post(url, json=payload)
    return response.json()
```

---

## Testing Strategy

### Local Testing (Days 15-16)
- [ ] Configure StoreKit configuration file
- [ ] Test purchase flow in iOS Simulator
- [ ] Test subscription lifecycle
- [ ] Test restore purchases

### TestFlight Testing (Days 17-19)
- [ ] Upload build to TestFlight
- [ ] Add internal testers
- [ ] Test real purchases (charged to Apple sandbox account)
- [ ] Test subscription renewal
- [ ] Test subscription cancellation

### Sandbox Testing (Days 20-21)
- [ ] Create Apple sandbox tester accounts
- [ ] Test all subscription tiers
- [ ] Test edge cases (expired cards, etc.)
- [ ] Test family sharing (if applicable)

---

## App Store Submission Requirements

### 1. App Store Connect Configuration
- [ ] In-App Purchases configured
- [ ] Subscription pricing set
- [ ] Subscription descriptions added
- [ ] Screenshots showing IAP flow

### 2. App Review Information
- [ ] Demo account credentials (with active subscription)
- [ ] Testing instructions for reviewers
- [ ] Explanation of subscription benefits

### 3. Metadata
- [ ] Privacy policy updated (mention IAP)
- [ ] Terms of Service (subscription terms)
- [ ] Refund policy

---

## Migration Plan (Existing Users)

Since RecallSentry already has paid users on server-side subscriptions:

1. **Grandfather Existing Users**
   - Keep server-side subscriptions active
   - Gradually migrate to IAP when they renew

2. **Dual Verification**
   - Check both backend subscription AND IAP receipt
   - Grant access if EITHER is active

3. **Migration Flow**
   - When server subscription expires, prompt to subscribe via IAP
   - Offer discounted rate for existing users (if possible)

---

## Important Notes

### Apple Guidelines
- **No External Links:** Cannot link to external website for purchases
- **No Price Mentions:** Cannot mention prices outside of IAP
- **Must Use IAP:** All digital goods MUST use StoreKit
- **No Alternative Payment:** Cannot mention alternative payment methods

### Subscription Features
- **Free Trial:** Consider offering 7-day free trial
- **Promotional Offers:** Can offer discounts for new subscribers
- **Family Sharing:** Consider enabling for RecallMatch tier
- **Grace Period:** Handle failed renewals gracefully

### Revenue Share
- Apple takes 30% for first year
- Apple takes 15% after 1 year of continuous subscription
- Small Business Program: 15% if revenue < $1M/year

---

## File Changes Required

### New Files
```
lib/services/iap_service.dart (new)
lib/widgets/subscription_card.dart (new)
ios/Runner/Runner.storekit (new - for testing)
docs/IAP_TESTING_GUIDE.md (new)
```

### Modified Files
```
lib/services/subscription_service.dart (update)
lib/pages/subscribe_page.dart (update)
ios/Runner/Runner.entitlements (update)
pubspec.yaml (add dependency)
```

### Backend Files (Python/Django)
```
api/views/iap_views.py (new)
api/serializers/iap_serializers.py (new)
api/urls.py (add IAP routes)
```

---

## Timeline Summary

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 1 | 1 day | App Store Connect setup |
| Phase 2 | 2 days | Flutter package integration |
| Phase 3 | 1 day | iOS native configuration |
| Phase 4 | 3 days | IAP service implementation |
| Phase 5 | 2 days | Subscription service updates |
| Phase 6 | 2 days | Subscribe page UI |
| Phase 7 | 2 days | Backend API endpoints |
| Phase 8 | 2 days | Receipt verification |
| Testing | 7 days | Local, TestFlight, Sandbox |
| **Total** | **21 days** | **~3 weeks** |

---

## Next Steps

1. **Immediate (This Week)**
   - [ ] Create In-App Purchase products in App Store Connect
   - [ ] Generate shared secret for receipt verification
   - [ ] Set up sandbox tester accounts

2. **Short-term (Next Week)**
   - [ ] Implement IAPService
   - [ ] Update SubscriptionService
   - [ ] Create backend verification endpoint

3. **Before Submission**
   - [ ] Complete TestFlight testing
   - [ ] Document IAP flow for App Review
   - [ ] Update privacy policy

---

## Resources

- [Apple In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Flutter in_app_purchase Plugin](https://pub.dev/packages/in_app_purchase)
- [App Store Review Guidelines (3.1.1)](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [StoreKit 2 Tutorial](https://developer.apple.com/videos/play/wwdc2021/10114/)

---

## Blockers & Risks

### Potential Issues
1. **Apple Review Rejection** - IAP implementation must be perfect
2. **Receipt Verification** - Complex server-side validation
3. **Subscription Sync** - Keeping backend and IAP in sync
4. **Migration** - Moving existing users without disruption

### Mitigation
- Follow Apple's guidelines strictly
- Use robust error handling
- Implement dual verification (backend + IAP)
- Test extensively on TestFlight

---

## Success Criteria

✅ All digital subscriptions use StoreKit2
✅ Receipt verification working on backend
✅ Subscription status synced between app and server
✅ Restore purchases functional
✅ TestFlight testing complete with no issues
✅ App Store review approved on first submission

---

**Status:** NOT STARTED
**Owner:** [Assign developer]
**Deadline:** [Set based on App Store submission target]
