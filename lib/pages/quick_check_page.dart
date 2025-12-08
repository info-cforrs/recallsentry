import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/subscription_service.dart';
import '../providers/service_providers.dart';
import 'subscribe_page.dart';
import 'quick_check_item_type_page.dart';

/// Quick Check Page - Entry point for Quick Check functionality
///
/// Tier-based access:
/// - Free: No access, show upgrade modal
/// - SmartFiltering: Quick Check with match confirmation only (no Homes/Rooms)
/// - RecallMatch: Full Quick Check with Homes/Rooms and RMC enrollment
class QuickCheckPage extends ConsumerStatefulWidget {
  const QuickCheckPage({super.key});

  @override
  ConsumerState<QuickCheckPage> createState() => _QuickCheckPageState();
}

class _QuickCheckPageState extends ConsumerState<QuickCheckPage> {
  bool _isLoading = true;
  SubscriptionTier? _tier;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final subscriptionInfo = await subscriptionService.getSubscriptionInfo();

      if (mounted) {
        setState(() {
          _tier = subscriptionInfo.tier;
          _isLoading = false;
        });

        // If free tier, show upgrade modal
        if (subscriptionInfo.tier == SubscriptionTier.free) {
          _showUpgradeModal();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tier = SubscriptionTier.free;
          _isLoading = false;
        });
        _showUpgradeModal();
      }
    }
  }

  void _showUpgradeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.tertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quick Check',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check Before You Buy!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick Check lets you verify if a product has any active recalls before you purchase. Simply enter the product details and we\'ll check our database for any matching recalls.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      'SmartFiltering (\$1.99/mo)',
                      'Match confirmation only',
                      const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      'RecallMatch (\$4.99/mo)',
                      'Full tracking with Homes & Rooms',
                      const Color(0xFFFFD700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Upgrade Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureRow(String tier, String feature, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tier,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                feature,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Quick Check',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
        ),
      );
    }

    // If free tier, show empty page (modal is shown on top)
    if (_tier == SubscriptionTier.free) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.secondary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Quick Check',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please upgrade to use Quick Check',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // For SmartFiltering and RecallMatch users, show the item type selection
    return QuickCheckItemTypePage(tier: _tier!);
  }
}
