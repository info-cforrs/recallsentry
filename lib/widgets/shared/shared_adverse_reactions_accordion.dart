import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';

class SharedAdverseReactionsAccordion extends StatelessWidget {
  final String adverseReactions;
  final String adverseReactionDetails;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedAdverseReactionsAccordion({
    required this.adverseReactions,
    required this.adverseReactionDetails,
    this.isPremiumUser,
    super.key,
  });

  Future<bool> _checkPremiumAccess() async {
    // If premium status is provided, use it
    if (isPremiumUser != null) {
      return isPremiumUser!;
    }

    // Otherwise, check via subscription service
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
            sectionTitle: 'Adverse Reactions',
            isPremium: false,
          );
        }

        final hasPremium = snapshot.data ?? false;

        // If not premium, show grey locked button
        if (!hasPremium) {
          return PremiumSectionWrapper(
            sectionTitle: 'Adverse Reactions',
            isPremium: false,
          );
        }

        // If premium, show normal accordion
        return _buildAccordionContent();
      },
    );
  }

  Widget _buildAccordionContent() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Section Title
            Text(
              'Adverse Reactions',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            // Content (always shown)
            Builder(
              builder: (context) {
                final hasReactions = adverseReactions
                    .trim()
                    .isNotEmpty;
                final hasDetails = adverseReactionDetails
                    .trim()
                    .isNotEmpty;
                if (!hasReactions && !hasDetails) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'No adverse reactions specified.',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      textAlign: TextAlign.left,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Adverse Reactions:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasReactions
                            ? adverseReactions
                            : 'Not specified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Adverse Reaction Details:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasDetails
                            ? adverseReactionDetails
                            : 'Not specified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
  }
}
