import 'package:flutter/material.dart';
import '../models/recall_data.dart';

class FDARecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const FDARecallDetailsCard({super.key, required this.recall});

  @override
  Widget build(BuildContext context) {
    // Determine which section will be last (for border radius)
    String? formattedStartDate = recall.productionDateStart != null ? _formatDate(recall.productionDateStart) : null;
    String? formattedEndDate = recall.productionDateEnd != null ? _formatDate(recall.productionDateEnd) : null;

    bool hasDetailsFields = recall.recallReasonShort.isNotEmpty ||
        recall.brandName.isNotEmpty ||
        recall.productName.isNotEmpty ||
        recall.packagingDesc.isNotEmpty ||
        recall.productSizeWeight.isNotEmpty ||
        formattedStartDate != null ||
        formattedEndDate != null;

    bool hasDetailsGrid = (recall.upc.isNotEmpty && recall.upc != 'N/A') ||
        (recall.sku.isNotEmpty && recall.sku != 'N/A') ||
        (recall.batchLotCode.isNotEmpty && recall.batchLotCode != 'N/A') ||
        (recall.expDate.isNotEmpty && recall.expDate != 'N/A') ||
        (recall.sellByDate.isNotEmpty && recall.sellByDate != 'N/A') ||
        (recall.packagedOnDate.isNotEmpty && recall.packagedOnDate != 'N/A');

    // Determine which is the last section
    bool detailsFieldsIsLast = hasDetailsFields && !hasDetailsGrid;
    bool detailsGridIsLast = hasDetailsGrid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopRow(
          recallId: recall.fdaRecallId,
          dateIssued: recall.dateIssued,
          agency: recall.agency,
          category: recall.category,
        ),
        _buildRiskCategoryRow(
          riskLevel: recall.riskLevel,
          stateCount: recall.stateCount,
        ),
        _buildDetailsFields(
          recallReasonShort: recall.recallReasonShort,
          brandName: recall.brandName,
          productName: recall.productName,
          packagingDesc: recall.packagingDesc,
          productSizeWeight: recall.productSizeWeight,
          productionDateStart: formattedStartDate,
          productionDateEnd: formattedEndDate,
          isLast: detailsFieldsIsLast,
        ),
        _buildDetailsGrid(
          upc: recall.upc,
          sku: recall.sku,
          batchLotCode: recall.batchLotCode,
          expDate: recall.expDate,
          sellByDate: recall.sellByDate,
          packagedOnDate: recall.packagedOnDate,
          isLast: detailsGridIsLast,
        ),
      ],
    );
  }

  Widget _buildFdaFieldsSection() {
    return Container(
      color: const Color(0xFFFAFAFA),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FDA Recall Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          _buildFieldRow('Reports of Injury', recall.reportsOfInjury),
          _buildFieldRow(
            'Distribution Date Start',
            recall.distributionDateStart,
          ),
          _buildFieldRow('Distribution Date End', recall.distributionDateEnd),
          _buildFieldRow('Best Used By Date End', recall.bestUsedByDateEnd),
          _buildFieldRow('Item Num Code', recall.itemNumCode),
          _buildFieldRow('Firm Contact Form', recall.firmContactForm),
          _buildFieldRow('Distributor', recall.distributor),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value.isNotEmpty ? value : 'N/A')),
        ],
      ),
    );
  }

  Widget _buildTopRow({
    required String recallId,
    required DateTime dateIssued,
    required String agency,
    required String category,
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
          // Left Column: Icon + Category (increased width for "Veterinary")
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lunch_dining, color: Colors.black, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (category.isNotEmpty ? category : 'FOOD').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      const Text(
                        'RECALL',
                        style: TextStyle(
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
                  color: const Color(0xFF1565C0),
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

  Widget _buildRiskCategoryRow({
    required String riskLevel,
    required int stateCount,
  }) {
    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'RISK LEVEL:',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFE53935),
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
                  Row(
                    children: [
                      Text(
                        stateCount > 0 ? stateCount.toString() : 'N/A',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'States',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.add_box, color: Color(0xFFE53935), size: 20),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  recall.negativeOutcomes.isNotEmpty
                      ? recall.negativeOutcomes
                      : 'negative_outcomes',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsFields({
    required String recallReasonShort,
    required String brandName,
    required String productName,
    required String packagingDesc,
    required String productSizeWeight,
    required String? productionDateStart,
    required String? productionDateEnd,
    required bool isLast,
  }) {
    // Build list of widgets conditionally
    List<Widget> children = [];
    
    // Recall Reason Short - always show
    children.add(Row(
      children: [
        const Icon(Icons.warning, color: Colors.red, size: 18),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            recallReasonShort,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ));
    
    // Reports of Injury - only show if not empty
    if (recall.reportsOfInjury.isNotEmpty && recall.reportsOfInjury != 'Not specified') {
      children.add(const SizedBox(height: 10));
      children.add(Text(
        recall.reportsOfInjury,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ));
    }
    
    // Horizontal line and Brand Name - only show if brandName not empty
    if (brandName.isNotEmpty) {
      children.add(const SizedBox(height: 10));
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
    }
    
    // Product Name - only show if not empty
    if (productName.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Text(
        productName,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
    }
    
    // Packaging Desc - only show if not empty
    if (packagingDesc.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Text(
        packagingDesc,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
    }
    
    // Product Size/Weight - only show if not empty
    if (productSizeWeight.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Text(
        productSizeWeight,
        style: const TextStyle(color: Colors.black, fontSize: 15),
      ));
    }
    
    // Production Dates - only show if at least one is not null/N/A
    if ((productionDateStart != null && productionDateStart != "N/A") || 
        (productionDateEnd != null && productionDateEnd != "N/A")) {
      children.add(const SizedBox(height: 10));
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
            productionDateStart ?? "N/A",
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
            productionDateEnd ?? "N/A",
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ],
      ));
    }
    
    // Sold By - only show if not empty
    if (recall.soldBy.isNotEmpty) {
      children.add(const SizedBox(height: 10));
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
              recall.soldBy,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ],
      ));
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
    required String expDate,
    required String sellByDate,
    required String packagedOnDate,
    required bool isLast,
  }) {
    // Build list of widgets conditionally
    List<Widget> children = [];

    // Product Qty and Packaged On Date row
    bool hasProductQty = recall.productQty.isNotEmpty;
    bool hasPackagedOn = packagedOnDate.isNotEmpty && packagedOnDate != 'N/A';

    if (hasProductQty || hasPackagedOn) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasProductQty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recall.productQty,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          if (hasProductQty && hasPackagedOn) const SizedBox(width: 16),
          if (hasPackagedOn)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Packaged On:',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    packagedOnDate,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    // UPC and SKU row
    bool hasUpc = upc.isNotEmpty && upc != 'N/A';
    bool hasSku = sku.isNotEmpty && sku != 'N/A';

    if (hasUpc || hasSku) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasUpc)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
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
                ],
              ),
            ),
          if (hasUpc && hasSku) const SizedBox(width: 16),
          if (hasSku)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
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
                ],
              ),
            ),
        ],
      ));
      children.add(const SizedBox(height: 10));
    }

    // Batch/Lot Code row
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

    // Sell By Date and Exp Date row
    bool hasSellBy = sellByDate.isNotEmpty && sellByDate != 'N/A';
    bool hasExpDate = expDate.isNotEmpty && expDate != 'N/A';

    if (hasSellBy || hasExpDate) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSellBy)
            Expanded(
              child: RichText(
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
              ),
            ),
          if (hasSellBy && hasExpDate) const SizedBox(width: 16),
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
