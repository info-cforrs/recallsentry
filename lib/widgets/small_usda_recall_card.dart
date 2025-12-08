import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/usda_recall_details_page.dart';
import '../pages/subscribe_page.dart';
import '../providers/data_providers.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class SmallUsdaRecallCard extends ConsumerStatefulWidget {
  final RecallData recall;

  const SmallUsdaRecallCard({super.key, required this.recall});

  @override
  ConsumerState<SmallUsdaRecallCard> createState() => _SmallUsdaRecallCardState();
}

class _SmallUsdaRecallCardState extends ConsumerState<SmallUsdaRecallCard> {
  final SavedRecallsService _savedRecallsService = SavedRecallsService();
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    bool saved = await _savedRecallsService.isRecallSaved(widget.recall.id);
    if (mounted) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await _savedRecallsService.removeSavedRecall(widget.recall.id);
      if (mounted) {
        setState(() {
          _isSaved = false;
        });
        // Refresh provider so HomePage updates immediately
        ref.refresh(savedRecallsProvider);
        ref.refresh(safetyScoreProvider);
      }
    } else {
      try {
        await _savedRecallsService.saveRecall(widget.recall);
        if (mounted) {
          setState(() {
            _isSaved = true;
          });
          // Refresh provider so HomePage updates immediately
          ref.refresh(savedRecallsProvider);
          ref.refresh(safetyScoreProvider);
        }
      } on SavedRecallsLimitException catch (e) {
        // Show upgrade dialog when limit is reached
        if (mounted) {
          _showUpgradeDialog(e);
        }
      } catch (e) {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving recall: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showUpgradeDialog(SavedRecallsLimitException exception) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.premium, size: 24),
              SizedBox(width: 8),
              Text(
                'Saved Recalls Limit Reached',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have reached your saved recalls limit (${exception.limit}).',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade your plan to save more recalls:',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildPlanOption('Free Plan', '5 recalls'),
              _buildPlanOption('SmartFiltering Plan', '15 recalls'),
              _buildPlanOption('RecallMatch Plan', '50 recalls'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SubscribePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanOption(String planName, String limit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Text(
            '$planName: ',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            limit,
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsdaRecallDetailsPage(recall: widget.recall),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Brand Name, State Count, Recall Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Brand Name
                Expanded(
                  child: Text(
                    widget.recall.brandName.isNotEmpty
                        ? widget.recall.brandName
                        : 'N/A',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Center: State Count
                Expanded(
                  child: Text(
                    _getStateCount(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Right: Recall Date
                Expanded(
                  child: Text(
                    _formatDate(widget.recall.dateIssued),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Product Info and Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Product Name, Negative Outcomes, Recall Reason, USDA Recall ID (2/3 width)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.recall.productName.isNotEmpty
                            ? widget.recall.productName
                            : 'N/A',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Negative Outcomes
                      Text(
                        'Outcomes: ${_getNegativeOutcomes()}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Recall Reason
                      Text(
                        'Reason: ${widget.recall.recallReason.isNotEmpty ? widget.recall.recallReason : 'N/A'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // USDA Recall ID
                      Text(
                        'ID: ${widget.recall.usdaRecallId.isNotEmpty ? widget.recall.usdaRecallId : 'N/A'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: Product Image with Heart Overlay (1/3 width)
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Builder(
                            builder: (context) {
                              final imageUrl = widget.recall.getPrimaryImageUrl();
                              return imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    );
                            },
                          ),
                      ),
                      // Heart/Save overlay (top right corner)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: _toggleSave,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isSaved ? Icons.favorite : Icons.favorite_border,
                              color: _isSaved ? AppColors.success : AppColors.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStateCount() {
    if (widget.recall.distributionPattern.isEmpty ||
        widget.recall.distributionPattern.toLowerCase() == 'nationwide') {
      return 'Nationwide';
    }
    // Try to count comma-separated states
    final states = widget.recall.distributionPattern.split(',');
    if (states.length > 1) {
      return '${states.length} States';
    }
    return widget.recall.distributionPattern;
  }

  String _getNegativeOutcomes() {
    if (widget.recall.negativeOutcomes.isEmpty) {
      return 'None reported';
    }
    return widget.recall.negativeOutcomes;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
