import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/usda_recall_details_pagev2.dart';

class UsdaRecallCard extends StatefulWidget {
  final RecallData recall;

  const UsdaRecallCard({super.key, required this.recall});

  @override
  State<UsdaRecallCard> createState() => _UsdaRecallCardState();
}

class _UsdaRecallCardState extends State<UsdaRecallCard> {
  // Section 2: Middle Row 1
  Widget usdaRecallCardMiddleRow1({
    required String riskLevel,
    required String negativeOutcomes,
    required String recallReason,
    required String brandName,
    required String imageUrl,
    required bool isSaved,
    required VoidCallback onToggleSaved,
    required VoidCallback onViewPdf,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '[Risk Level]',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskColor(riskLevel),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          riskLevel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '[Negative Outcomes]',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.warning, color: Colors.red, size: 15),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          negativeOutcomes.isEmpty
                              ? 'No negative outcomes specified'
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
                  const SizedBox(height: 12),
                  Text(
                    '[Recall Reason]',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.star, color: Colors.green, size: 16),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          recallReason,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ...removed Brand Name field from here...
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
                    imageUrl.toLowerCase().endsWith('.pdf')
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red.shade600,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'USDA Document',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: onViewPdf,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
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
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey.shade100,
                                      child: const Center(
                                        child: Text(
                                          '[USDA Image]',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onToggleSaved,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved
                                ? Colors.green
                                : Colors.grey.shade600,
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
        ),
        // Reports of Injury field (full width, after Recall Reason and outside Row)
        const SizedBox(height: 12),
        Text(
          'Reports of Injury:',
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          widget.recall.reportsOfInjury.isNotEmpty
              ? widget.recall.reportsOfInjury
              : 'Not specified',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Section 1: Top Row
  Widget usdaRecallCardTopRow({
    required String recallClassification,
    required DateTime dateIssued,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        // Left Column: Icon + Category
        Expanded(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recallClassification.isNotEmpty)
                      Text(
                        recallClassification.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
              _formatDate(dateIssued),
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
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'USDA',
                style: TextStyle(
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

  // Section 3: Middle Row 2
  Widget usdaRecallCardMiddleRow2({
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
      children: [
        // Brand Name above Product Name
        Text(
          '[Brand Name]',
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          widget.recall.brandName.isNotEmpty
              ? widget.recall.brandName
              : 'Not specified',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '[Product Name]',
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          productName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '[Sold By/Distributor]',
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          soldBy.isNotEmpty ? soldBy : 'Not specified',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_box, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
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
                children: [
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
  Widget usdaRecallCardBottomRow({
    required String recallId,
    required int stateCount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[USDA Recall ID]',
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              recallId,
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
            const Text(
              '[State Count]',
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            (stateCount == 0 ||
                    stateCount == 50 ||
                    (stateCount is String &&
                        (stateCount.toString().toLowerCase() == 'nationwide' ||
                            stateCount.toString() == '0')))
                ? const Text(
                    'NATIONWIDE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  )
                : Text(
                    '$stateCount States',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  // Helper for checkboxes
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
    String upperRiskLevel = riskLevel.toUpperCase();
    if (upperRiskLevel.contains('PUBLIC HEALTH ALERT')) {
      return Colors.purple;
    }
    if (upperRiskLevel.contains('HIGH') ||
        upperRiskLevel.contains('CLASS I') ||
        upperRiskLevel.contains('HIGH - CLASS I') ||
        upperRiskLevel.contains('CLASS 1')) {
      return Colors.red;
    }
    if (upperRiskLevel.contains('MEDIUM') ||
        upperRiskLevel.contains('CLASS II') ||
        upperRiskLevel.contains('MEDIUM - CLASS II') ||
        upperRiskLevel.contains('CLASS 2')) {
      return Colors.orange;
    }
    if (upperRiskLevel.contains('LOW') ||
        upperRiskLevel.contains('CLASS III') ||
        upperRiskLevel.contains('LOW - CLASS III') ||
        upperRiskLevel.contains('CLASS 3')) {
      return Colors.yellow.shade700;
    }
    return Colors.grey;
  }

  bool _isSaved = false;
  final SavedRecallsService _savedRecallsService = SavedRecallsService();

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    bool saved = await _savedRecallsService.isRecallSaved(
      widget.recall.id,
    );
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UsdaRecallDetailsPageV2(recall: widget.recall),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.98, // Increased width
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC107),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Top Row
            usdaRecallCardTopRow(
              recallClassification: widget.recall.recallClassification,
              dateIssued: widget.recall.dateIssued,
            ),
            const SizedBox(height: 16),
            // Section 2: Middle Row 1
            usdaRecallCardMiddleRow1(
              riskLevel: widget.recall.riskLevel,
              negativeOutcomes: widget.recall.negativeOutcomes,
              recallReason: widget.recall.recallReason,
              brandName: widget.recall.brandName,
              imageUrl: widget.recall.getPrimaryImageUrl(),
              isSaved: _isSaved,
              onToggleSaved: _toggleSaved,
              onViewPdf: () => _openPdf(),
            ),
            // Removed extra SizedBox to reduce space between Reports of Injury and Brand Name
            // Section 3: Middle Row 2
            usdaRecallCardMiddleRow2(
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
            usdaRecallCardBottomRow(
              recallId: widget.recall.usdaRecallId,
              stateCount: widget.recall.stateCount,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPdf() async {
    try {
      final String imageUrl = widget.recall.getPrimaryImageUrl();
      if (imageUrl.isEmpty) return;

      final Uri uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently - could add error logging here
    }
  }
}
