import 'package:flutter/material.dart';
import '../services/usage_service.dart';
import '../pages/subscribe_page.dart';

class UsageWidget extends StatelessWidget {
  final UsageData usageData;
  final bool showUpgradeButton;

  const UsageWidget({
    super.key,
    required this.usageData,
    this.showUpgradeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A4A5C).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),

          // Usage Items
          _buildUsageItem(
            'Saved Recalls',
            usageData.recallsSaved,
            usageData.recallsSavedLimit,
            usageData.recallsSavedPercentage,
            usageData.isUnlimited,
          ),
          const SizedBox(height: 20),

          _buildUsageItem(
            'Monthly Searches',
            usageData.searchesPerformed,
            usageData.searchesPerformedLimit,
            usageData.searchesPerformedPercentage,
            usageData.isUnlimited,
          ),
          const SizedBox(height: 20),

          _buildUsageItem(
            'Filters Applied',
            usageData.filtersApplied,
            usageData.filtersAppliedLimit,
            usageData.filtersAppliedPercentage,
            usageData.isUnlimited,
          ),

          // Footer
          if (!usageData.isUnlimited) ...[
            const SizedBox(height: 24),
            _buildFooter(context),
          ] else ...[
            const SizedBox(height: 24),
            _buildPremiumFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Usage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: usageData.isUnlimited
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFf59e0b), Color(0xFFd97706)],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 50)).toString().isNotEmpty
                      ? null
                      : const Color(0xFFf59e0b)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              usageData.tierDisplay,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: usageData.isUnlimited ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageItem(
    String label,
    int current,
    int? limit,
    int percentage,
    bool isUnlimited,
  ) {
    final Color progressColor = _getProgressColor(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                if (isUnlimited)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10b981), Color(0xFF34d399)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'UNLIMITED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              isUnlimited ? '$current' : '$current/${limit ?? '∞'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: isUnlimited ? (current % 100) / 100 : percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Usage resets in ${usageData.daysUntilReset} ${usageData.daysUntilReset == 1 ? 'day' : 'days'}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (showUpgradeButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SubscribePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2A4A5C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '✨ Upgrade to SmartFiltering',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white24,
            width: 1,
          ),
        ),
      ),
      child: const Text(
        'Thank you for supporting RecallSentry! 💙',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 90) {
      return const Color(0xFFef4444); // Red
    } else if (percentage >= 60) {
      return const Color(0xFFf59e0b); // Yellow
    } else {
      return const Color(0xFF10b981); // Green
    }
  }
}
