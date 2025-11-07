import 'package:flutter/material.dart';
import '../models/recall_data.dart';

class USDARecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const USDARecallDetailsCard({super.key, required this.recall});

  void _showManufacturerRetailerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Manufacturer & Retailer Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Establishment Manufacturer
                if (recall.establishmentManufacturer.isNotEmpty) ...[
                  const Text(
                    'Establishment/Manufacturer:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.establishmentManufacturer,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Manufacturer Contact Name
                if (recall.establishmentManufacturerContactName.isNotEmpty) ...[
                  const Text(
                    'Contact Name:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.establishmentManufacturerContactName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Manufacturer Contact Phone
                if (recall.establishmentManufacturerContactPhone.isNotEmpty) ...[
                  const Text(
                    'Contact Phone:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.establishmentManufacturerContactPhone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Manufacturer Contact Email
                if (recall.establishmentManufacturerContactEmail.isNotEmpty) ...[
                  const Text(
                    'Contact Email:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.establishmentManufacturerContactEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Retailer
                if (recall.retailer1.isNotEmpty) ...[
                  const Text(
                    'Retailer:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.retailer1,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Retailer Contact Name
                if (recall.retailer1ContactName.isNotEmpty) ...[
                  const Text(
                    'Retailer Contact Name:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.retailer1ContactName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Retailer Contact Phone
                if (recall.retailer1ContactPhone.isNotEmpty) ...[
                  const Text(
                    'Retailer Contact Phone:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.retailer1ContactPhone,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Retailer Contact Email
                if (recall.retailer1ContactEmail.isNotEmpty) ...[
                  const Text(
                    'Retailer Contact Email:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.retailer1ContactEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
                // Show message if no data
                if (recall.establishmentManufacturer.isEmpty &&
                    recall.establishmentManufacturerContactName.isEmpty &&
                    recall.establishmentManufacturerContactPhone.isEmpty &&
                    recall.establishmentManufacturerContactEmail.isEmpty &&
                    recall.retailer1.isEmpty &&
                    recall.retailer1ContactName.isEmpty &&
                    recall.retailer1ContactPhone.isEmpty &&
                    recall.retailer1ContactEmail.isEmpty)
                  const Text(
                    'No manufacturer or retailer details available.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetailsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Product Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Identification
                if (recall.productIdentification.isNotEmpty) ...[
                  const Text(
                    'Product Identification:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.productIdentification,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // UPC
                if (recall.upc.isNotEmpty && recall.upc != 'N/A') ...[
                  const Text(
                    'UPC Code:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.upc,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // SKU
                if (recall.sku.isNotEmpty && recall.sku != 'N/A') ...[
                  const Text(
                    'SKU:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.sku,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Batch/Lot Code
                if (recall.batchLotCode.isNotEmpty && recall.batchLotCode != 'N/A') ...[
                  const Text(
                    'Batch/Lot Code:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.batchLotCode,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Production Dates
                if (recall.productionDateStart != null || recall.productionDateEnd != null) ...[
                  const Text(
                    'Production Dates:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'From: ${recall.productionDateStart != null ? _formatDate(recall.productionDateStart) : "N/A"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To: ${recall.productionDateEnd != null ? _formatDate(recall.productionDateEnd) : "N/A"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Expiration Date
                if (recall.expDate.isNotEmpty && recall.expDate != 'N/A') ...[
                  const Text(
                    'Expiration Date:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.expDate,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Best Used By Date
                if (recall.bestUsedByDate.isNotEmpty && recall.bestUsedByDate != 'N/A') ...[
                  const Text(
                    'Best Used By Date:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.bestUsedByDate,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Packaging Description
                if (recall.packagingDesc.isNotEmpty) ...[
                  const Text(
                    'Packaging Info:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.packagingDesc,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
                // Show message if no data
                if (recall.productIdentification.isEmpty &&
                    (recall.upc.isEmpty || recall.upc == 'N/A') &&
                    (recall.sku.isEmpty || recall.sku == 'N/A') &&
                    (recall.batchLotCode.isEmpty || recall.batchLotCode == 'N/A') &&
                    recall.productionDateStart == null &&
                    recall.productionDateEnd == null &&
                    (recall.expDate.isEmpty || recall.expDate == 'N/A') &&
                    (recall.bestUsedByDate.isEmpty || recall.bestUsedByDate == 'N/A') &&
                    recall.packagingDesc.isEmpty)
                  const Text(
                    'No product details available.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAdverseReactionsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A4A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Adverse Reactions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Adverse Reactions
                if (recall.adverseReactions.isNotEmpty) ...[
                  const Text(
                    'Adverse Reactions:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.adverseReactions,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Negative Outcomes
                if (recall.negativeOutcomes.isNotEmpty) ...[
                  const Text(
                    'Negative Outcomes:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recall.negativeOutcomes,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
                // Show message if no data
                if (recall.adverseReactions.isEmpty && recall.negativeOutcomes.isEmpty)
                  const Text(
                    'No adverse reactions or negative outcomes reported.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which section will be last (for border radius)
    bool hasDetailsFields = recall.negativeOutcomes.isNotEmpty ||
        recall.recallReason.isNotEmpty ||
        recall.brandName.isNotEmpty ||
        recall.productName.isNotEmpty ||
        recall.packagingDesc.isNotEmpty ||
        recall.productionDateStart != null ||
        recall.productionDateEnd != null ||
        recall.soldBy.isNotEmpty ||
        recall.productQty.isNotEmpty;

    bool hasDetailsGrid = (recall.upc.isNotEmpty && recall.upc != 'N/A') ||
        (recall.sku.isNotEmpty && recall.sku != 'N/A') ||
        (recall.batchLotCode.isNotEmpty && recall.batchLotCode != 'N/A') ||
        (recall.sellByDate.isNotEmpty && recall.sellByDate != 'N/A');

    bool hasDatesSection = (recall.expDate.isNotEmpty && recall.expDate != 'N/A') ||
        (recall.bestUsedByDate.isNotEmpty && recall.bestUsedByDate != 'N/A');

    // Determine which is the last section
    bool detailsFieldsIsLast = hasDetailsFields && !hasDetailsGrid && !hasDatesSection;
    bool detailsGridIsLast = hasDetailsGrid && !hasDatesSection;
    bool datesSectionIsLast = hasDatesSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopRow(
          recallClassification: recall.recallClassification,
          dateIssued: recall.dateIssued,
          agency: recall.agency,
        ),
        _buildRiskStateRow(
          riskLevel: recall.riskLevel,
          recallClassification: recall.recallClassification,
          stateCount: recall.stateCount,
        ),
        _buildDetailsFields(
          negativeOutcomes: recall.negativeOutcomes,
          recallReason: recall.recallReason,
          brandName: recall.brandName,
          productName: recall.productName,
          packagingDesc: recall.packagingDesc,
          productionDateStart: recall.productionDateStart,
          productionDateEnd: recall.productionDateEnd,
          soldBy: recall.soldBy,
          productQty: recall.productQty,
          isLast: detailsFieldsIsLast,
        ),
        _buildDetailsGrid(
          upc: recall.upc,
          sku: recall.sku,
          batchLotCode: recall.batchLotCode,
          sellByDate: recall.sellByDate,
          isLast: detailsGridIsLast,
        ),
        _buildDatesSection(
          expDate: recall.expDate,
          bestUsedByDate: recall.bestUsedByDate,
          isLast: datesSectionIsLast,
        ),
      ],
    );
  }

  Widget _buildTopRow({
    required String recallClassification,
    required DateTime dateIssued,
    required String agency,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2A4A5C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date (left side)
          Text(
            _formatDate(dateIssued),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          // Agency badge (right side)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              agency,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskStateRow({
    required String riskLevel,
    required String recallClassification,
    required dynamic stateCount,
  }) {
    return Container(
      color: const Color(0xFF2A4A5C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          riskLevel.toLowerCase().contains(
                            'public health alert',
                          )
                          ? Colors.purple
                          : Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      riskLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              (stateCount == 0 ||
                      stateCount == 50 ||
                      (stateCount is String &&
                          (stateCount.toString().toLowerCase() ==
                                  'nationwide' ||
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsFields({
    required String negativeOutcomes,
    required String recallReason,
    required String brandName,
    required String productName,
    required String packagingDesc,
    required DateTime? productionDateStart,
    required DateTime? productionDateEnd,
    required String soldBy,
    required String productQty,
    required bool isLast,
  }) {
    List<Widget> children = [];

    // Format dates if they exist
    String? formattedStartDate = productionDateStart != null ? _formatDate(productionDateStart) : null;
    String? formattedEndDate = productionDateEnd != null ? _formatDate(productionDateEnd) : null;

    // Negative Outcomes / Adverse Reactions - only show if not empty (with arrow and modal trigger)
    if (negativeOutcomes.isNotEmpty) {
      children.add(Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _showAdverseReactionsModal(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      negativeOutcomes,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ));
      children.add(const SizedBox(height: 16));
    }

    // Recall Reason - only show if not empty
    if (recallReason.isNotEmpty) {
      children.add(Text(
        recallReason,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Brand Name - only show if not empty (with arrow and modal trigger)
    if (brandName.isNotEmpty) {
      children.add(Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _showManufacturerRetailerModal(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      brandName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ));
      children.add(const SizedBox(height: 16));
    }

    // Product Name - only show if not empty (with arrow and modal trigger)
    if (productName.isNotEmpty) {
      children.add(Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _showProductDetailsModal(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        },
      ));
      children.add(const SizedBox(height: 16));
    }

    // Packaging Desc - only show if not empty
    if (packagingDesc.isNotEmpty) {
      children.add(Text(
        packagingDesc,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Production Dates - only show if at least one is not null
    if (formattedStartDate != null || formattedEndDate != null) {
      children.add(const Text(
        'Produced:',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'From:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formattedStartDate ?? "N/A",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(width: 16),
          const Text(
            'To:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formattedEndDate ?? "N/A",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ));
      children.add(const SizedBox(height: 16));
    }

    // Sold By - only show if not empty
    if (soldBy.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sold By:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              soldBy,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 16));
    }

    // Product Qty - only show if not empty
    if (productQty.isNotEmpty) {
      children.add(Text(
        productQty,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ));
    }

    // Only show container if there are children to display
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )
            : null,
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  Widget _buildDetailsGrid({
    required String upc,
    required String sku,
    required String batchLotCode,
    required String sellByDate,
    required bool isLast,
  }) {
    List<Widget> children = [];

    // UPC and SKU row
    bool hasUpc = upc.isNotEmpty && upc != 'N/A';
    bool hasSku = sku.isNotEmpty && sku != 'N/A';

    if (hasUpc || hasSku) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasUpc)
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'UPC Code: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: upc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasUpc && hasSku) const SizedBox(width: 16),
          if (hasSku)
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'SKU: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: sku,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    // Batch/Lot Code - only show if not empty
    if (batchLotCode.isNotEmpty && batchLotCode != 'N/A') {
      children.add(RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Batch/Lot Code: ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: batchLotCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Sell By Date - only show if not empty
    if (sellByDate.isNotEmpty && sellByDate != 'N/A') {
      children.add(RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Sell By Date: ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: sellByDate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ));
    }

    // Only show container if there are children to display
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )
            : null,
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }


  Widget _buildDatesSection({
    required String expDate,
    required String bestUsedByDate,
    required bool isLast,
  }) {
    List<Widget> children = [];

    // Exp Date and Best Used By Date row
    bool hasExpDate = expDate.isNotEmpty && expDate != 'N/A';
    bool hasBestUsedBy = bestUsedByDate.isNotEmpty && bestUsedByDate != 'N/A';

    if (hasExpDate || hasBestUsedBy) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasExpDate)
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Exp Date: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: expDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasExpDate && hasBestUsedBy) const SizedBox(width: 16),
          if (hasBestUsedBy)
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Best Used By: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: bestUsedByDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ));
    }

    // Add recall ID at the bottom if this is the last section and recall number exists
    if (isLast && recall.fieldRecallNumber.trim().isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        Text(
          'Recall Number: ${recall.fieldRecallNumber}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      );
    }

    // Only show container if there are children to display
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A5C),
        borderRadius: isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )
            : null,
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
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
