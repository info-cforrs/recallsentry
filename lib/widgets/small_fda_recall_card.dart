import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/fda_recall_details_pagev2.dart';

class SmallFdaRecallCard extends StatefulWidget {
  final RecallData recall;

  const SmallFdaRecallCard({super.key, required this.recall});

  @override
  State<SmallFdaRecallCard> createState() => _SmallFdaRecallCardState();
}

class _SmallFdaRecallCardState extends State<SmallFdaRecallCard> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FdaRecallDetailsPageV2(recall: widget.recall),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A4A5C),
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
                      color: Colors.white,
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
                      color: Colors.white,
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
                      color: Colors.white,
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
                // Left: Product Name, Negative Outcomes, Recall Reason (2/3 width)
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
                          color: Colors.white,
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
                          color: Colors.white,
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
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // FDA Recall ID
                      Text(
                        'ID: ${widget.recall.fdaRecallId.isNotEmpty ? widget.recall.fdaRecallId : 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: widget.recall.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.recall.imageUrl.startsWith('http')
                                      ? widget.recall.imageUrl
                                      : 'https://api.centerforrecallsafety.com${widget.recall.imageUrl}',
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
                              color: _isSaved ? Color(0xFF4CAF50) : Colors.white,
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
