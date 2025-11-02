import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';

class SimpleRecallCard extends StatefulWidget {
  final RecallData recall;
  final String agency;

  const SimpleRecallCard({
    super.key,
    required this.recall,
    required this.agency,
  });

  @override
  State<SimpleRecallCard> createState() => _SimpleRecallCardState();
}

class _SimpleRecallCardState extends State<SimpleRecallCard> {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107), // Yellow background as shown in image
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with warning icon, RECALL text, date, and agency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'RECALL',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Date Issued
                  Text(
                    _formatDate(widget.recall.dateIssued),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Agency badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.agency == 'FDA'
                          ? const Color(0xFF4A90E2)
                          : const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.agency,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Top section with Risk Level, Category, Brand Name and Image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Top fields only
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Risk Level
                        Text(
                          '[Risk Level]',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRiskColor(widget.recall.riskLevel),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.recall.riskLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Category
                        Text(
                          '[Category]',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            // Add burger icon if category contains "food"
                            if (widget.recall.category.toLowerCase().contains(
                              'food',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.burger,
                                color: Colors.brown,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add pills icon if category contains "drug"
                            if (widget.recall.category.toLowerCase().contains(
                              'drug',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.pills,
                                color: Colors.blue,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add dog icon if category contains "veterinary"
                            if (widget.recall.category.toLowerCase().contains(
                              'veterinary',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.dog,
                                color: Colors.brown,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add ban icon if category contains "produced without benefit of inspection"
                            if (widget.recall.category.toLowerCase().contains(
                              'produced without benefit of inspection',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.ban,
                                color: Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add disease icon if category contains "allergens"
                            if (widget.recall.category.toLowerCase().contains(
                              'allergens',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.disease,
                                color: Colors.green,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add plane-circle-xmark icon if category contains "import"
                            if (widget.recall.category.toLowerCase().contains(
                              'import',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.planeCircleXmark,
                                color: Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add viruses icon if category contains "contamination"
                            if (widget.recall.category.toLowerCase().contains(
                              'contamination',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.viruses,
                                color: Colors.green.shade800,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add tag icon if category contains "mislabeling"
                            if (widget.recall.category.toLowerCase().contains(
                              'mislabeling',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.tag,
                                color: Colors.blue.shade800,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add copyright icon if category contains "misbranding"
                            if (widget.recall.category.toLowerCase().contains(
                              'misbranding',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.copyright,
                                color: Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            // Add fire icon if category contains "fire"
                            if (widget.recall.category.toLowerCase().contains(
                              'fire',
                            )) ...[
                              FaIcon(
                                FontAwesomeIcons.fire,
                                color: Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Expanded(
                              child: Text(
                                widget.recall.category,
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

                        // Brand Name
                        Text(
                          '[Brand Name]',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.recall.brandName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right side - Image or PDF viewer
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Main content (image or PDF)
                          widget.recall.getPrimaryImageUrl().isNotEmpty
                              ? _buildImageOrPdfViewer()
                              : _buildImagePlaceholder(),

                          // Heart icon in upper right corner
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _buildHeartIcon(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Full-width fields section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    '[Product Name]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.recall.productName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Packaging Description
                  Text(
                    '[Packaging Description]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.recall.packagingDesc.isEmpty
                        ? 'Not specified'
                        : widget.recall.packagingDesc,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Negative Outcomes
                  Text(
                    '[Negative_Outcomes]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.solidSquarePlus,
                        color: Colors.red,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.recall.negativeOutcomes.isEmpty
                              ? 'None reported'
                              : widget.recall.negativeOutcomes,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Resolution section
                  Text(
                    'Resolution:',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildRemedyCheckbox(
                        'Return',
                        widget.recall.remedyReturn,
                      ),
                      _buildRemedyCheckbox(
                        'Repair',
                        widget.recall.remedyRepair,
                      ),
                      _buildRemedyCheckbox(
                        'Replace',
                        widget.recall.remedyReplace,
                      ),
                      _buildRemedyCheckbox(
                        'Dispose',
                        widget.recall.remedyDispose,
                      ),
                      _buildRemedyCheckbox('N/A', widget.recall.remedyNA),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Product Quantity
                  Text(
                    '[Product Quantity]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.recall.productQty.isEmpty
                        ? 'Not specified'
                        : widget.recall.productQty,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sold By
                  Text(
                    '[Sold By]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.recall.soldBy.isEmpty
                        ? 'Sold by: Not specified'
                        : 'Sold by: ${widget.recall.soldBy}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ID
                  Text(
                    '[ID]',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.recall.id,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // State Count positioned in bottom right corner
          Positioned(
            bottom: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '[State_Count]',
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${widget.recall.stateCount} States',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            '[Image URL]',
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
            'PDF Document',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10,
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

  Widget _buildHeartIcon() {
    return GestureDetector(
      onTap: _toggleSaved,
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
          _isSaved ? Icons.favorite : Icons.favorite_border,
          color: _isSaved ? Colors.green : Colors.grey.shade600,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildRemedyCheckbox(String label, String value) {
    bool isChecked = value.toUpperCase() == 'Y';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(
          isChecked ? FontAwesomeIcons.squareCheck : FontAwesomeIcons.square,
          color: Colors.black,
          size: 14,
        ),
        const SizedBox(width: 6),
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
