import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/fda_recall_details_page.dart';
import '../pages/usda_recall_details_page.dart';
import '../pages/cpsc_recall_details_page.dart';
import '../pages/nhtsa_recall_details_page.dart';
import '../providers/data_providers.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class SmallMainPageRecallCard extends ConsumerStatefulWidget {
  final RecallData recall;
  final String? currentStatus;
  final String? filterName;
  final VoidCallback? onTap;

  const SmallMainPageRecallCard({
    super.key,
    required this.recall,
    this.currentStatus,
    this.filterName,
    this.onTap,
  });

  @override
  ConsumerState<SmallMainPageRecallCard> createState() => _SmallMainPageRecallCardState();
}

class _SmallMainPageRecallCardState extends ConsumerState<SmallMainPageRecallCard> {
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
    } else {
      await _savedRecallsService.saveRecall(widget.recall);
    }
    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
      // Refresh provider so HomePage updates immediately
      ref.invalidate(savedRecallsProvider);
      ref.invalidate(safetyScoreProvider);
    }
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

  String _getRecallId() {
    final agency = widget.recall.agency.toUpperCase();

    switch (agency) {
      case 'USDA':
        return widget.recall.usdaRecallId.isNotEmpty
            ? widget.recall.usdaRecallId
            : 'N/A';
      case 'CPSC':
        return widget.recall.fieldRecallNumber.isNotEmpty
            ? widget.recall.fieldRecallNumber
            : widget.recall.id.isNotEmpty ? widget.recall.id : 'N/A';
      case 'NHTSA':
        return widget.recall.nhtsaCampaignNumber.isNotEmpty
            ? widget.recall.nhtsaCampaignNumber
            : widget.recall.nhtsaRecallId.isNotEmpty
                ? widget.recall.nhtsaRecallId
                : 'N/A';
      case 'FDA':
      default:
        return widget.recall.fdaRecallId.isNotEmpty
            ? widget.recall.fdaRecallId
            : 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () {
        // Navigate to appropriate details page based on agency
        final agency = widget.recall.agency.toUpperCase();
        Widget detailsPage;

        switch (agency) {
          case 'USDA':
            detailsPage = UsdaRecallDetailsPage(recall: widget.recall);
            break;
          case 'CPSC':
            detailsPage = CpscRecallDetailsPage(recall: widget.recall);
            break;
          case 'NHTSA':
            detailsPage = NhtsaRecallDetailsPage(recall: widget.recall);
            break;
          case 'FDA':
          default:
            detailsPage = FdaRecallDetailsPage(recall: widget.recall);
            break;
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => detailsPage),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Save Icon (square, with rounded top corners only)
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth,
                      height: constraints.maxWidth,
                      decoration: const BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Builder(
                          builder: (context) {
                            final imageUrl = widget.recall.getPrimaryImageUrl();
                            return imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                          },
                        ),
                    ),
                    // Heart/Save overlay (top right corner with dark background)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _toggleSave,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSaved ? Icons.favorite : Icons.favorite_border,
                            color: _isSaved ? AppColors.success : AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Category row with background color #0C5876
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.tertiary,
              child: Text(
                widget.recall.category.isNotEmpty
                    ? widget.recall.category
                    : 'N/A',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // RMC Current Status row (if provided)
            if (widget.currentStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.tertiary,
                child: Text(
                  widget.currentStatus!,
                  style: const TextStyle(
                    color: AppColors.accentBlueLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // Filter Name row (if provided)
            if (widget.filterName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.tertiary,
                child: Row(
                  children: [
                    const Text(
                      'Filter: ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.filterName!,
                        style: const TextStyle(
                          color: AppColors.accentBlueLight,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Content area with padding
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Name (1 line max)
                  Text(
                    widget.recall.brandName.isNotEmpty
                        ? widget.recall.brandName
                        : 'N/A',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Product Name (2 lines max)
                  Text(
                    widget.recall.productName.isNotEmpty
                        ? widget.recall.productName
                        : 'N/A',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Recall Date (right justified)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatDate(widget.recall.dateIssued),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Recall ID
                  Text(
                    _getRecallId(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
