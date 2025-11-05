import 'package:flutter/material.dart';
import '../models/recall_data.dart';

class USDARecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const USDARecallDetailsCard({super.key, required this.recall});

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
        color: Color(0xFFFFC107),
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
          // Left Column: Icon + Category
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recallClassification.isNotEmpty &&
                          !recallClassification.toLowerCase().contains('public health alert'))
                        Text(
                          recallClassification.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      Text(
                        recallClassification.toLowerCase().contains('public health alert')
                            ? 'Public Health Alert'
                            : 'RECALL',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
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
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Right Column: Agency badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
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
      color: const Color(0xFFFFC107),
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
                        color: Colors.black,
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

    // Negative Outcomes - only show if not empty
    if (negativeOutcomes.isNotEmpty) {
      children.add(Text(
        negativeOutcomes,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Recall Reason - only show if not empty
    if (recallReason.isNotEmpty) {
      children.add(Text(
        recallReason,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Brand Name - only show if not empty
    if (brandName.isNotEmpty) {
      children.add(const SizedBox(height: 3));
      children.add(Container(
        width: double.infinity,
        height: 1,
        color: Colors.black,
      ));
      children.add(const SizedBox(height: 3));
      children.add(Text(
        brandName,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Product Name - only show if not empty
    if (productName.isNotEmpty) {
      children.add(Text(
        productName,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Packaging Desc - only show if not empty
    if (packagingDesc.isNotEmpty) {
      children.add(Text(
        packagingDesc,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
      children.add(const SizedBox(height: 10));
    }

    // Production Dates - only show if at least one is not null
    if (formattedStartDate != null || formattedEndDate != null) {
      children.add(const Text(
        'Produced:',
        style: TextStyle(
          color: Colors.black,
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
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formattedStartDate ?? "N/A",
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
          const SizedBox(width: 16),
          const Text(
            'To:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            formattedEndDate ?? "N/A",
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    // Sold By - only show if not empty
    if (soldBy.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Sold By:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              soldBy,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    // Product Qty - only show if not empty
    if (productQty.isNotEmpty) {
      children.add(Text(
        productQty,
        style: const TextStyle(
          color: Colors.black,
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
        color: const Color(0xFFFFC107),
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: upc,
                      style: const TextStyle(
                        color: Colors.black,
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: sku,
                      style: const TextStyle(
                        color: Colors.black,
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: batchLotCode,
              style: const TextStyle(
                color: Colors.black,
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            TextSpan(
              text: sellByDate,
              style: const TextStyle(
                color: Colors.black,
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
        color: const Color(0xFFFFC107),
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: expDate,
                      style: const TextStyle(
                        color: Colors.black,
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
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: bestUsedByDate,
                      style: const TextStyle(
                        color: Colors.black,
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

    // Only show container if there are children to display
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
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
