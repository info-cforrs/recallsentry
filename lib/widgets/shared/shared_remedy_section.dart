import 'package:flutter/material.dart';
import '../premium_section_wrapper.dart';
import '../../services/subscription_service.dart';
import '../../models/recall_data.dart';

class SharedRemedySection extends StatelessWidget {
  final RecallData recall;
  final bool? isPremiumUser; // Optional override for premium status

  const SharedRemedySection({
    required this.recall,
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

  void _showRemedyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Remedy',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Remedy content
                Text(
                  recall.remedy.trim().isNotEmpty
                      ? recall.remedy
                      : 'No remedy specified.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                // Resolution checkbox section
                const Text(
                  'Resolution Status:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                _ResolutionCheckbox(
                  label: 'Return',
                  isChecked: recall.remedyReturn == 'Y',
                ),
                _ResolutionCheckbox(
                  label: 'Replace',
                  isChecked: recall.remedyReplace == 'Y',
                ),
                _ResolutionCheckbox(
                  label: 'Repair',
                  isChecked: recall.remedyRepair == 'Y',
                ),
                _ResolutionCheckbox(
                  label: 'Dispose',
                  isChecked: recall.remedyDispose == 'Y',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkPremiumAccess(),
      builder: (context, snapshot) {
        // While loading, show grey locked button by default
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PremiumSectionWrapper(
            sectionTitle: 'Remedy',
            isPremium: false,
          );
        }

        final hasPremium = snapshot.data ?? false;

        // If not premium, show grey locked button
        if (!hasPremium) {
          return PremiumSectionWrapper(
            sectionTitle: 'Remedy',
            isPremium: false,
          );
        }

        // If premium, show normal section with arrow
        return _buildSectionContent(context);
      },
    );
  }

  Widget _buildSectionContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRemedyModal(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40, right: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Remedy',
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

class _ResolutionCheckbox extends StatelessWidget {
  final String label;
  final bool isChecked;

  const _ResolutionCheckbox({
    required this.label,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
              color: isChecked ? const Color(0xFF4CAF50) : Colors.transparent,
            ),
            child: isChecked
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
