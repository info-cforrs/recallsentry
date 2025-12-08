import 'package:flutter/material.dart';
import '../models/recall_match.dart';
import '../constants/app_colors.dart';
import '../pages/user_item_details_page.dart';
import 'user_item_card.dart';
import 'small_fda_recall_card.dart';
import 'small_usda_recall_card.dart';

/// RecallMatch Card Widget
///
/// Uses existing UserItemCard widget and replicates SmallFdaRecallCard styling
/// Layout: Confidence → User Item → Helper Text → Recall → Buttons → Divider
class RecallMatchCard extends StatelessWidget {
  final RecallMatchSummary match;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final bool showDivider;

  const RecallMatchCard({
    super.key,
    required this.match,
    required this.onConfirm,
    required this.onDismiss,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CONFIDENCE BADGE + EXPLANATION TEXT (Top)
        _buildConfidenceHeader(),

        const SizedBox(height: 16),

        // USER ITEM CARD (using existing widget)
        UserItemCard(
          item: match.userItem,
          onTap: () {
            // Navigate to user item details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserItemDetailsPage(item: match.userItem),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // QUESTION ICON + HELPER TEXT (Between cards)
        _buildHelperText(),

        const SizedBox(height: 16),

        // RECALL CARD (using existing widgets based on agency)
        if (match.recall.agency == 'FDA')
          SmallFdaRecallCard(recall: match.recall)
        else if (match.recall.agency == 'USDA')
          SmallUsdaRecallCard(recall: match.recall)
        else
          SmallFdaRecallCard(recall: match.recall), // Default to FDA card

        // Expiry Warning (if applicable)
        if (match.daysUntilExpiry <= 7) ...[
          const SizedBox(height: 16),
          _buildExpiryWarning(),
        ],

        const SizedBox(height: 16),

        // ACTION BUTTONS (Below recall card)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Not My Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onConfirm,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        // DIVIDER (if more matches below)
        if (showDivider) ...[
          const SizedBox(height: 24),
          const Divider(
            color: AppColors.textSecondary,
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 24),
        ] else ...[
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Confidence badge and explanation text at the top
  Widget _buildConfidenceHeader() {
    final scoreColor = _getScoreColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Match confidence badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.15),
            border: Border.all(color: scoreColor, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt,
                color: scoreColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${match.matchScore.toStringAsFixed(0)}% Match Confidence',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper text with question icon between cards
  Widget _buildHelperText() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            size: 24,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your item above may be affected by the recall shown below. Please review and take action.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildExpiryWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning,
            size: 20,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Match expires in ${match.daysUntilExpiry} day${match.daysUntilExpiry == 1 ? "" : "s"}. Take action soon!',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (match.matchScore >= 90) {
      return AppColors.success;
    } else if (match.matchScore >= 75) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }

}
