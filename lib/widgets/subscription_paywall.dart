import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/iap_service.dart';
import '../services/subscription_service.dart';

/// A paywall widget that displays subscription options
class SubscriptionPaywall extends StatefulWidget {
  final VoidCallback? onPurchaseComplete;
  final VoidCallback? onClose;

  const SubscriptionPaywall({
    super.key,
    this.onPurchaseComplete,
    this.onClose,
  });

  /// Show as a bottom sheet
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SubscriptionPaywall(
            onPurchaseComplete: () => Navigator.pop(context, true),
            onClose: () => Navigator.pop(context, false),
          ),
        ),
      ),
    );
  }

  @override
  State<SubscriptionPaywall> createState() => _SubscriptionPaywallState();
}

class _SubscriptionPaywallState extends State<SubscriptionPaywall> {
  final IAPService _iapService = IAPService();

  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  ProductDetails? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _loadProducts();
  }

  void _setupCallbacks() {
    _iapService.onPurchaseSuccess = (tier) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated! Welcome to Premium!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPurchaseComplete?.call();
      }
    };

    _iapService.onPurchaseError = (error) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _iapService.initialize();

      if (!_iapService.isAvailable) {
        setState(() {
          _error = 'Store not available on this device';
          _isLoading = false;
        });
        return;
      }

      final products = _iapService.products;

      setState(() {
        _isLoading = false;
        if (products.isNotEmpty) {
          _selectedProduct = products.first;
        } else {
          _error = 'No subscription products available';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription options';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseProduct() async {
    if (_selectedProduct == null) return;

    setState(() => _isPurchasing = true);
    await _iapService.purchase(_selectedProduct!);
    // Result handled via callbacks
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    await _iapService.restorePurchases();

    // Check if anything was restored
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isPurchasing = false);

      if (_iapService.hasActiveSubscription()) {
        SubscriptionService().clearCache();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPurchaseComplete?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No previous purchases found'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final products = _iapService.products;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all features and get the most out of RecallSentry',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features list
          _buildFeaturesList(),
          const SizedBox(height: 32),

          // Product options
          if (products.isNotEmpty) ...[
            const Text(
              'Choose your plan:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...products.map(_buildProductOption),
            const SizedBox(height: 24),
          ],

          // Purchase button
          ElevatedButton(
            onPressed: _isPurchasing || _selectedProduct == null
                ? null
                : _purchaseProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3547),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isPurchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Subscribe Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(height: 16),

          // Restore purchases
          TextButton(
            onPressed: _isPurchasing ? null : _restorePurchases,
            child: const Text('Restore Purchases'),
          ),
          const SizedBox(height: 8),

          // Manage Subscription button
          TextButton(
            onPressed: _openSubscriptionManagement,
            child: const Text('Manage Subscription'),
          ),
          const SizedBox(height: 16),

          // Legal text with auto-renewal disclosure
          Text(
            'Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. '
            'Your account will be charged for renewal within 24 hours prior to the end of the current period. '
            'You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Legal links (Required for App Store compliance)
          _buildLegalLinks(),
        ],
      ),
    );
  }

  /// Open subscription management in device settings
  Future<void> _openSubscriptionManagement() async {
    final String url = Platform.isIOS
        ? AppConfig.iosSubscriptionManagementUrl
        : AppConfig.androidSubscriptionManagementUrl;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open a URL in external browser
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build legal links section (Privacy Policy, Terms, EULA)
  Widget _buildLegalLinks() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
        ),
        children: [
          const TextSpan(text: 'By subscribing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: const TextStyle(
              color: Color(0xFF1D3547),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(AppConfig.termsOfServiceUrl),
          ),
          const TextSpan(text: ', '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(
              color: Color(0xFF1D3547),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(AppConfig.privacyPolicyUrl),
          ),
          const TextSpan(text: ', and '),
          TextSpan(
            text: 'EULA',
            style: const TextStyle(
              color: Color(0xFF1D3547),
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl(AppConfig.eulaUrl),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      ('CPSC Recalls', 'Access Consumer Product Safety recalls'),
      ('Unlimited Filters', 'Save up to 10 custom filters'),
      ('Extended History', 'View recalls from January 1st'),
      ('Multi-State Alerts', 'Monitor up to 3 states'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: features
            .map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.$1,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              f.$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProductOption(ProductDetails product) {
    final isSelected = _selectedProduct?.id == product.id;

    // Check if yearly for savings badge and billing period
    final isYearly = product.id.contains('yearly');
    final billingPeriod = isYearly ? '/year' : '/month';
    final savings = isYearly ? 'Save 17%' : '';

    return GestureDetector(
      onTap: () => setState(() => _selectedProduct = product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF1D3547) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF1D3547).withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1D3547) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1D3547),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (savings.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            savings,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Price with explicit billing period
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  billingPeriod,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
