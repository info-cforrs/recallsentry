import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';

class SharedAdverseReactionsAccordion extends StatefulWidget {
  final String adverseReactions;
  final String adverseReactionDetails;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedAdverseReactionsAccordion({
    required this.adverseReactions,
    required this.adverseReactionDetails,
    this.isPremiumUser,
    super.key,
  });

  @override
  State<SharedAdverseReactionsAccordion> createState() =>
      _SharedAdverseReactionsAccordionState();
}

class _SharedAdverseReactionsAccordionState
    extends State<SharedAdverseReactionsAccordion> {
  bool _expanded = false;

  Future<bool> _checkPremiumAccess() async {
    // If premium status is provided, use it
    if (widget.isPremiumUser != null) {
      print('🔒 [Adverse Reactions] Using provided premium status: ${widget.isPremiumUser}');
      return widget.isPremiumUser!;
    }

    // Otherwise, check via subscription service
    print('🔒 [Adverse Reactions] Checking subscription service...');
    final subscription = await SubscriptionService().getSubscriptionInfo();
    print('🔒 [Adverse Reactions] Subscription result - Tier: ${subscription.tier}, HasPremiumAccess: ${subscription.hasPremiumAccess}, IsLoggedIn: ${subscription.isLoggedIn}');
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
        print('🔒 [Adverse Reactions] Build - ConnectionState: ${snapshot.connectionState}, HasPremium: $hasPremium');

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Adverse Reactions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Builder(
                builder: (context) {
                  final hasReactions = widget.adverseReactions
                      .trim()
                      .isNotEmpty;
                  final hasDetails = widget.adverseReactionDetails
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
                              ? widget.adverseReactions
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
                              ? widget.adverseReactionDetails
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
            ),
        ],
      ),
    );
  }
}
