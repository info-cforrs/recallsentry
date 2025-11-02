import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';

class SharedProductDistributionAccordion extends StatefulWidget {
  final String productDistribution;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedProductDistributionAccordion({
    required this.productDistribution,
    this.isPremiumUser,
    super.key,
  });

  @override
  State<SharedProductDistributionAccordion> createState() =>
      _SharedProductDistributionAccordionState();
}

class _SharedProductDistributionAccordionState
    extends State<SharedProductDistributionAccordion> {
  bool _expanded = false;

  Future<bool> _checkPremiumAccess() async {
    if (widget.isPremiumUser != null) {
      return widget.isPremiumUser!;
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
                      'Product Distribution',
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
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    widget.productDistribution.isNotEmpty
                        ? widget.productDistribution
                        : 'Not specified',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
