import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/nhtsa_recall_details_page.dart';
import '../pages/subscribe_page.dart';
import '../providers/data_providers.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class SmallNhtsaRecallCard extends ConsumerStatefulWidget {
  final RecallData recall;

  const SmallNhtsaRecallCard({super.key, required this.recall});

  @override
  ConsumerState<SmallNhtsaRecallCard> createState() => _SmallNhtsaRecallCardState();
}

class _SmallNhtsaRecallCardState extends ConsumerState<SmallNhtsaRecallCard> {
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
        ref.invalidate(savedRecallsProvider);
        ref.invalidate(safetyScoreProvider);
      }
    } else {
      try {
        await _savedRecallsService.saveRecall(widget.recall);
        if (mounted) {
          setState(() {
            _isSaved = true;
          });
          // Refresh provider so HomePage updates immediately
          ref.invalidate(savedRecallsProvider);
          ref.invalidate(safetyScoreProvider);
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

  /// Navigate to the NHTSA details page
  void _navigateToDetailsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NhtsaRecallDetailsPage(recall: widget.recall)),
    );
  }

  /// Get recall type badge color based on NHTSA recall type
  Color _getRecallTypeBadgeColor() {
    switch (widget.recall.nhtsaRecallType.toLowerCase()) {
      case 'vehicle':
        return const Color(0xFFE65100); // Orange
      case 'tire':
        return Colors.grey.shade700;
      case 'child seat':
        return Colors.purple.shade700;
      case 'equipment':
        return Colors.blue.shade700;
      default:
        return const Color(0xFFE65100);
    }
  }

  /// Get recall type icon based on NHTSA recall type
  IconData _getRecallTypeIcon() {
    switch (widget.recall.nhtsaRecallType.toLowerCase()) {
      case 'vehicle':
        return Icons.directions_car;
      case 'tire':
        return Icons.circle;
      case 'child seat':
        return Icons.child_care;
      case 'equipment':
        return Icons.build;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetailsPage(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Brand/Make, Type Badge, Recall Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Brand Name / Vehicle Make
                Expanded(
                  child: Text(
                    widget.recall.brandName.isNotEmpty
                        ? widget.recall.brandName
                        : widget.recall.nhtsaVehicleMake.isNotEmpty
                            ? widget.recall.nhtsaVehicleMake
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
                // Center: Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRecallTypeBadgeColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getRecallTypeIcon(), color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        widget.recall.nhtsaRecallType.isNotEmpty
                            ? widget.recall.nhtsaRecallType
                            : 'Vehicle',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right: Recall Date
                Text(
                  _formatDate(widget.recall.dateIssued),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Safety warnings row
            if (widget.recall.nhtsaDoNotDrive || widget.recall.nhtsaFireRisk)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (widget.recall.nhtsaDoNotDrive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber, color: Colors.yellow, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'DO NOT DRIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.recall.nhtsaFireRisk)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade900,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'FIRE RISK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            // Row 2: Product Info and Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Product Name, Component, Consequence (2/3 width)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name / Subject
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
                      // Component
                      if (widget.recall.nhtsaComponent.isNotEmpty)
                        Text(
                          'Component: ${widget.recall.nhtsaComponent}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.recall.nhtsaComponent.isNotEmpty)
                        const SizedBox(height: 4),
                      // Consequence / Negative Outcomes
                      Text(
                        'Consequence: ${_getConsequence()}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Campaign Number
                      Text(
                        'Campaign: ${_getRecallId()}',
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
                                          return Image.asset(
                                            'assets/images/IPNA.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: Icon(
                                                _getRecallTypeIcon(),
                                                size: 30,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/IPNA.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            _getRecallTypeIcon(),
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        ),
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

  String _getConsequence() {
    if (widget.recall.negativeOutcomes.isNotEmpty) {
      return widget.recall.negativeOutcomes;
    }
    return 'None reported';
  }

  /// Get the appropriate recall ID for NHTSA recalls
  String _getRecallId() {
    if (widget.recall.nhtsaRecallId.isNotEmpty) {
      return widget.recall.nhtsaRecallId;
    }
    if (widget.recall.nhtsaCampaignNumber.isNotEmpty) {
      return widget.recall.nhtsaCampaignNumber;
    }
    if (widget.recall.id.isNotEmpty) {
      return widget.recall.id;
    }
    return 'N/A';
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

