import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';
import 'us_state_map.dart';

class SharedProductDistributionAccordion extends StatelessWidget {
  final String productDistribution;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedProductDistributionAccordion({
    required this.productDistribution,
    this.isPremiumUser,
    super.key,
  });

  Future<bool> _checkPremiumAccess() async {
    if (isPremiumUser != null) {
      return isPremiumUser!;
    }
    final subscription = await SubscriptionService().getSubscriptionInfo();
    return subscription.hasPremiumAccess;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPremiumAccess(),
      builder: (context, snapshot) {
        // While loading, show grey locked button by default
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PremiumSectionWrapper(
            sectionTitle: 'Product Distribution',
            isPremium: false,
          );
        }

        final hasPremium = snapshot.data ?? false;

        // If not premium, show grey locked button
        if (!hasPremium) {
          return PremiumSectionWrapper(
            sectionTitle: 'Product Distribution',
            isPremium: false,
          );
        }

        // If premium, show normal section
        return _buildSectionContent(context);
      },
    );
  }

  void _showProductDistributionModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: const Color(0xFF2A4A5C),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with back button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Product Distribution',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // US State Map with 10px margin
                          USStateMap(productDistribution: productDistribution),
                          const SizedBox(height: 24),
                          // Distribution text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              productDistribution.trim().isNotEmpty
                                  ? productDistribution
                                  : 'Not specified',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDistributionModal(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, right: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Distribution',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
