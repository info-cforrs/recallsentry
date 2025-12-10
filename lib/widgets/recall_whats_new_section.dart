/// Recall What's New Section
/// Shows recent updates/changes to a recall on the detail page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_update.dart';
import '../providers/data_providers.dart';
import 'package:intl/intl.dart';

/// Section showing recent updates to a recall
class RecallWhatsNewSection extends ConsumerWidget {
  final int recallId;

  const RecallWhatsNewSection({
    super.key,
    required this.recallId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(recallUpdatesProvider(recallId));

    return updatesAsync.when(
      data: (updates) {
        if (updates.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildSection(context, updates);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildSection(BuildContext context, List<RecallUpdate> updates) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.new_releases_outlined,
                  size: 20,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  "What's New",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${updates.length} update${updates.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
          ),

          // Updates list
          ...updates.take(3).map((update) => _buildUpdateItem(context, update, isDark)),

          // Show more if more than 3
          if (updates.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '+ ${updates.length - 3} more update${updates.length - 3 > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(BuildContext context, RecallUpdate update, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon based on update type
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getUpdateColor(update.updateType).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getUpdateIcon(update.updateType),
              size: 14,
              color: _getUpdateColor(update.updateType),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.displayTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  update.changeSummary,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(update.detectedAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getUpdateIcon(String updateType) {
    switch (updateType) {
      case 'remedy_available':
        return Icons.check_circle_outline;
      case 'risk_level_changed':
        return Icons.warning_amber_outlined;
      case 'status_changed':
        return Icons.sync;
      case 'completion_rate_updated':
        return Icons.trending_up;
      case 'affected_products_expanded':
        return Icons.add_circle_outline;
      case 'description_updated':
        return Icons.edit_outlined;
      case 'dates_updated':
        return Icons.calendar_today;
      default:
        return Icons.info_outline;
    }
  }

  Color _getUpdateColor(String updateType) {
    switch (updateType) {
      case 'remedy_available':
        return Colors.green;
      case 'risk_level_changed':
        return Colors.orange;
      case 'status_changed':
        return Colors.purple;
      case 'completion_rate_updated':
        return Colors.teal;
      case 'affected_products_expanded':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
