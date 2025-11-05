import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../pages/rmc_details_page.dart';

class USDARmcStatusCard extends StatelessWidget {
  final RecallData recall;
  const USDARmcStatusCard({super.key, required this.recall});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RmcDetailsPage(recall: recall),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopRow(
            recallClassification: recall.recallClassification,
            dateIssued: recall.dateIssued,
            agency: recall.agency,
            brandName: recall.brandName,
            productName: recall.productName,
            imageUrl: recall.imageUrl,
          ),
          // Status section (always last, contains USDA Recall ID)
          _buildStatusSection(
            resolutionStatus: recall.recallResolutionStatus,
            usdaRecallId: recall.usdaRecallId,
          ),
        ],
      ),
    );
  }

  Widget _buildTopRow({
    required String recallClassification,
    required DateTime dateIssued,
    required String agency,
    required String brandName,
    required String productName,
    required String imageUrl,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          // Row 1: Warning icon + recall type, Date, Agency badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: Warning icon + recall type
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.black,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (recallClassification.isNotEmpty &&
                                !recallClassification.toLowerCase().contains('public health alert'))
                              Text(
                                recallClassification.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.1,
                                ),
                              ),
                            Text(
                              recallClassification.toLowerCase().contains('public health alert')
                                  ? 'PUBLIC HEALTH\nALERT'
                                  : 'RECALL',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // CENTER: Date
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      _formatDate(dateIssued),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // RIGHT: Agency badge with green background
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        agency,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row 2: Brand/Product info + Product image
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: Brand Name and Product Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brandName.isNotEmpty) ...[
                        Text(
                          brandName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (productName.isNotEmpty)
                        Text(
                          productName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // RIGHT: Product image with heart overlay
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl.startsWith('http')
                                    ? imageUrl
                                    : 'https://api.centerforrecallsafety.com$imageUrl',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey),
                                  );
                                },
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_not_supported,
                                  size: 40, color: Colors.grey),
                            ),
                    ),
                    // Green heart icon overlay
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection({
    required String resolutionStatus,
    required String usdaRecallId,
  }) {
    // Determine which step is active based on the status
    int activeStep = _getActiveStep(resolutionStatus);

    // Get the label text for each step
    String step1Label = _getStepLabel(resolutionStatus, 1);
    String step2Label = 'Mfr\nContacted';
    String step3Label = _getStepLabel(resolutionStatus, 3);
    String step4Label = 'Closed';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          // Status flow diagram - circles and connecting lines
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatusCircle(1, activeStep >= 1),
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.black,
                ),
              ),
              _buildStatusCircle(2, activeStep >= 2),
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.black,
                ),
              ),
              _buildStatusCircle(3, activeStep >= 3),
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.black,
                ),
              ),
              _buildStatusCircle(4, activeStep >= 4),
            ],
          ),
          const SizedBox(height: 4),
          // Labels below circles
          Row(
            children: [
              Expanded(
                child: Text(
                  step1Label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()), // Space for line
              Expanded(
                child: Text(
                  step2Label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()), // Space for line
              Expanded(
                child: Text(
                  step3Label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()), // Space for line
              Expanded(
                child: Text(
                  step4Label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          // USDA Recall ID at the bottom
          if (usdaRecallId.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '[USDA/FDA Recall ID]',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              usdaRecallId,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCircle(int stepNumber, bool isActive) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF4CAF50) : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          stepNumber.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  int _getActiveStep(String status) {
    // Determine the highest step number reached based on status
    switch (status) {
      case 'Not Started':
      case 'Open':
        return 0; // No steps completed yet - all grey
      case 'Stopped Using':
        return 1; // Section 1 complete
      case 'Mfr Contacted':
        return 2; // Section 2 complete
      // Section 3 - Only completed paths turn section green
      case 'Return 2: Received Refund': // Return path fully completed
      case 'Replace 1A: Received Parts': // Replace path completed (either option)
      case 'Replace 2A: Received Replacement Item': // Replace path completed (either option)
      case 'Repair 1B: Item Repaired by Service Center': // Repair left path completed
      case 'Repair 2B: Item Repaired by User': // Repair right path completed
      case 'Dispose 1B: Received Refund': // Dispose left path completed
      case 'Dispose 2A: Disposed of Item': // Dispose right path completed
        return 3; // Section 3 complete
      // Section 3 - Incomplete paths (still in progress)
      case 'Return 1A: Brought to local Retailer': // Return incomplete
      case 'Return 1B: Item Shipped Back': // Return incomplete
      case 'Repair 1A: Brought to Service Center': // Repair incomplete
      case 'Repair 2A: Received Repair Kit or Parts': // Repair incomplete
      case 'Dispose 1A: Brought to local Retailer': // Dispose incomplete
        return 2; // Stay at Section 2 (Section 3 not complete yet)
      case 'Completed':
        return 4; // Section 4 complete
      default:
        return 0; // Default to no steps if unknown status
    }
  }

  String _getStepLabel(String status, int stepNumber) {
    if (stepNumber == 1) {
      // Step 1 can be either "Open" or "Stopped Using"
      if (status == 'Open') {
        return 'Open';
      } else {
        return 'Stopped\nUsing';
      }
    } else if (stepNumber == 3) {
      // Step 3 label changes based on the resolution type
      if (status.startsWith('Return')) {
        return 'Return';
      } else if (status.startsWith('Replace')) {
        return 'Replace';
      } else if (status.startsWith('Repair')) {
        return 'Repair';
      } else if (status.startsWith('Dispose')) {
        return 'Dispose';
      } else {
        return 'Resolution';
      }
    }
    return '';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
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
