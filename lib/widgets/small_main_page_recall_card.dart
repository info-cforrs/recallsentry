import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../services/saved_recalls_service.dart';
import '../pages/fda_recall_details_pagev2.dart';
import '../pages/usda_recall_details_pagev2.dart';

class SmallMainPageRecallCard extends StatefulWidget {
  final RecallData recall;

  const SmallMainPageRecallCard({super.key, required this.recall});

  @override
  State<SmallMainPageRecallCard> createState() => _SmallMainPageRecallCardState();
}

class _SmallMainPageRecallCardState extends State<SmallMainPageRecallCard> {
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
    if (widget.recall.agency.toUpperCase() == 'USDA') {
      return widget.recall.usdaRecallId.isNotEmpty
          ? widget.recall.usdaRecallId
          : 'N/A';
    } else {
      return widget.recall.fdaRecallId.isNotEmpty
          ? widget.recall.fdaRecallId
          : 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to appropriate details page based on agency
        if (widget.recall.agency.toUpperCase() == 'USDA') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsdaRecallDetailsPageV2(recall: widget.recall),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FdaRecallDetailsPageV2(recall: widget.recall),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A4A5C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Save Icon (with rounded top corners only)
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: widget.recall.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            widget.recall.imageUrl.startsWith('http')
                                ? widget.recall.imageUrl
                                : 'https://api.centerforrecallsafety.com${widget.recall.imageUrl}',
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3547),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSaved ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
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
                      color: Colors.white,
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
                      color: Colors.white,
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
                        color: Colors.white70,
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
                      color: Colors.white70,
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
