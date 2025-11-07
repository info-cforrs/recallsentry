import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';

class SharedRecommendationsAccordion extends StatelessWidget {
  final String recommendationsActions;
  final String remedy;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedRecommendationsAccordion({
    required this.recommendationsActions,
    required this.remedy,
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
            sectionTitle: 'Recommendations',
            isPremium: false,
          );
        }

        final hasPremium = snapshot.data ?? false;

        // If not premium, show grey locked button
        if (!hasPremium) {
          return PremiumSectionWrapper(
            sectionTitle: 'Recommendations',
            isPremium: false,
          );
        }

        // If premium, show normal section
        return _buildSectionContent();
      },
    );
  }

  Widget _buildSectionContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Recommendations',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          // Content (always shown)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              recommendationsActions.trim().isNotEmpty
                  ? recommendationsActions
                  : 'No recommendations specified.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
