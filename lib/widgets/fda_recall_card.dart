import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';
import '../pages/fda_recall_details_page.dart';
import '../services/saved_recalls_service.dart';
import '../providers/data_providers.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class FdaRecallCard extends ConsumerStatefulWidget {
  final RecallData recall;

  const FdaRecallCard({super.key, required this.recall});

  @override
  ConsumerState<FdaRecallCard> createState() => _FdaRecallCardState();
}

class _FdaRecallCardState extends ConsumerState<FdaRecallCard> {
  // Section 1: Top Row
  Widget fdaRecallCardTopRow({
    required Widget categoryIcon,
    required String categoryText,
    required String dateIssued,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Left Column: Icon + Category (increased width for "Veterinary")
        Expanded(
          flex: 2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              categoryIcon,
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                    const Text(
                      'RECALL',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Center Column: Date
        Expanded(
          flex: 1,
          child: Center(
            child: Text(
              dateIssued,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Right Column: Badge
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Section 2: Middle Row 1
  Widget fdaRecallCardMiddleRow1({
    required String riskLevel,
    required Color riskColor,
    required String negativeOutcomes,
    required String imageUrl,
    required bool isSaved,
    required VoidCallback onToggleSaved,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: riskLevel.trim().toUpperCase() == 'CLASS III'
                          ? Colors.yellow
                          : riskColor,
                    ),
                    child: Text(
                      riskLevel,
                      style: TextStyle(
                        color: riskLevel.trim().toUpperCase() == 'CLASS III'
                            ? Colors.black
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.add_box,
                    color: Colors.red,
                    size: 17,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      negativeOutcomes.isEmpty
                          ? 'None reported'
                          : negativeOutcomes,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.recall.recallReasonShort.isNotEmpty
                    ? widget.recall.recallReasonShort
                    : 'Not specified',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              // (Brand Name field moved to below Reports of Injury, outside this column)
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Stack(
              children: <Widget>[
                widget.recall.getPrimaryImageUrl().isNotEmpty
                    ? _buildImageOrPdfViewer()
                    : _buildImagePlaceholder(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleSaved,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite : Icons.favorite_border,
                        color: isSaved ? AppColors.success : AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Section 3: Middle Row 2
  Widget fdaRecallCardMiddleRow2({
    required String productName,
    required String packagingDesc,
    required String productQty,
    required String soldBy,
    required String remedyReturn,
    required String remedyRepair,
    required String remedyReplace,
    required String remedyDispose,
    required String remedyNA,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          productName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Text(
          soldBy.isEmpty
              ? 'Distributor/Retailer: Not specified'
              : 'Distributor/Retailer: $soldBy',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.assignment_turned_in,
                    color: Colors.green.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'RESOLUTION - Consumer Actions:',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  _buildRemedyCheckbox('Return', remedyReturn),
                  _buildRemedyCheckbox('Repair', remedyRepair),
                  _buildRemedyCheckbox('Replace', remedyReplace),
                  _buildRemedyCheckbox('Dispose', remedyDispose),
                  _buildRemedyCheckbox('N/A', remedyNA),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section 4: Bottom Row
  Widget fdaRecallCardBottomRow({
    required String recallId,
    required int stateCount,
  }) {
    final String displayRecallId = (recallId.isNotEmpty) ? recallId : 'N/A';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100, // Constrain label width
              child: Text(
                '[FDA Recall ID]',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              displayRecallId,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 100, // Constrain label width
              child: Text(
                '[States Affected]',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            stateCount == 0
                ? const Text(
                    'NATIONWIDE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    '$stateCount States',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  bool _isSaved = false;
  final SavedRecallsService _savedRecallsService = SavedRecallsService();

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    bool saved = await _savedRecallsService.isRecallSaved(widget.recall.id);
    setState(() {
      _isSaved = saved;
    });
  }

  Future<void> _toggleSaved() async {
    if (_isSaved) {
      await _savedRecallsService.removeSavedRecall(widget.recall.id);
    } else {
      await _savedRecallsService.saveRecall(widget.recall);
    }
    setState(() {
      _isSaved = !_isSaved;
    });
    // Refresh provider so HomePage updates immediately
    ref.refresh(savedRecallsProvider);
    ref.refresh(safetyScoreProvider);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FdaRecallDetailsPage(recall: widget.recall),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Top Row
            fdaRecallCardTopRow(
              categoryIcon: _getCategoryIcon(),
              categoryText: widget.recall.category.toUpperCase(),
              dateIssued: _formatDate(widget.recall.dateIssued),
              badgeText: 'FDA',
              badgeColor: AppColors.accentBlue,
            ),
            const SizedBox(height: 16),
            // Section 2: Middle Row 1
            fdaRecallCardMiddleRow1(
              riskLevel: widget.recall.riskLevel,
              riskColor: _getRiskColor(widget.recall.riskLevel),
              negativeOutcomes: widget.recall.negativeOutcomes,
              imageUrl: widget.recall.imageUrl,
              isSaved: _isSaved,
              onToggleSaved: _toggleSaved,
            ),
            // Reports of Injury (full width, above Brand Name)
            const SizedBox(height: 10),
            Text(
              widget.recall.reportsOfInjury.isNotEmpty
                  ? widget.recall.reportsOfInjury
                  : 'Not specified',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Brand Name (full width, below Reports of Injury)
            const SizedBox(height: 10),
            Text(
              widget.recall.brandName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Section 3: Middle Row 2
            fdaRecallCardMiddleRow2(
              productName: widget.recall.productName,
              packagingDesc: widget.recall.packagingDesc,
              productQty: widget.recall.productQty,
              soldBy: widget.recall.soldBy,
              remedyReturn: widget.recall.remedyReturn,
              remedyRepair: widget.recall.remedyRepair,
              remedyReplace: widget.recall.remedyReplace,
              remedyDispose: widget.recall.remedyDispose,
              remedyNA: widget.recall.remedyNA,
            ),
            const SizedBox(height: 16),
            // Section 4: Bottom Row
            fdaRecallCardBottomRow(
              recallId: widget.recall.fdaRecallId,
              stateCount: widget.recall.stateCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '[FDA Image]',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrPdfViewer() {
    final String primaryImageUrl = widget.recall.getPrimaryImageUrl();
    bool isPdf = _isPdfUrl(primaryImageUrl);

    if (isPdf) {
      return _buildPdfViewer();
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          primaryImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        ),
      );
    }
  }

  Widget _buildPdfViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 32),
          const SizedBox(height: 8),
          const Text(
            'FDA Document',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _openPdf(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'View PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf');
  }

  Future<void> _openPdf() async {
    try {
      final Uri uri = Uri.parse(widget.recall.imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently - could add error logging here
    }
  }

  String _formatDate(DateTime date) {
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

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
      case 'CLASS I':
        return Colors.red;
      case 'MEDIUM':
      case 'CLASS II':
        return Colors.orange;
      case 'LOW':
      case 'CLASS III':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _getCategoryIcon() {
    String category = widget.recall.category.toLowerCase();

    // Add burger icon if category contains "food"
    if (category.contains('food')) {
      return const Icon(Icons.lunch_dining, color: Colors.brown, size: 18);
    }
    // Add pills icon if category contains "drug"
    if (category.contains('drug')) {
      return const Icon(Icons.medication, color: Colors.blue, size: 18);
    }
    // Add medical kit icon for FDA medical device category
    if (category.contains('medical device')) {
      return const Icon(Icons.medical_services, color: Colors.red, size: 18);
    }
    // Add dog icon if category contains "veterinary"
    if (category.contains('veterinary')) {
      return const Icon(Icons.pets, color: Colors.brown, size: 18);
    }
    // Add disease icon if category contains "allergens"
    if (category.contains('allergens')) {
      return const Icon(Icons.sick, color: Colors.green, size: 18);
    }
    // Add viruses icon if category contains "contamination"
    if (category.contains('contamination')) {
      return Icon(
        Icons.coronavirus,
        color: Colors.green.shade800,
        size: 18,
      );
    }
    // Add tag icon if category contains "mislabeling"
    if (category.contains('mislabeling')) {
      return Icon(
        Icons.label,
        color: Colors.blue.shade800,
        size: 18,
      );
    }
    // Default warning icon if no specific category matches
    return const Icon(Icons.warning, color: Colors.black, size: 18);
  }

  Widget _buildRemedyCheckbox(String label, String value) {
    bool isChecked = value.toUpperCase() == 'Y';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isChecked ? Icons.check_box : Icons.check_box_outline_blank,
          color: Colors.black,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
