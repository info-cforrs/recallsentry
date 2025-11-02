import 'package:flutter/material.dart';
import '../models/recall_data.dart';

class FDARecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const FDARecallDetailsCard({super.key, required this.recall});

  @override
  Widget build(BuildContext context) {
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
          productionDateStart: recall.productionDateStart != null
              ? _formatDate(recall.productionDateStart)
              : null,
          productionDateEnd: recall.productionDateEnd != null
              ? _formatDate(recall.productionDateEnd)
              : null,
        ),
        _buildDetailsGrid(
          upc: recall.upc,
          sku: recall.sku,
          batchLotCode: recall.batchLotCode,
          expDate: recall.expDate,
          sellByDate: recall.sellByDate,
          packagedOnDate: recall.packagedOnDate,
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
          const SizedBox(height: 8),
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
          Row(
            children: [
              const Icon(Icons.lunch_dining, color: Colors.black, size: 22),
              const SizedBox(width: 4),
              Text(
                '${(category.isNotEmpty ? category : 'FOOD').toUpperCase()} RECALL',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          Text(
            _formatDate(dateIssued),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          Container(
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
                  const Text(
                    '[Risk Level]',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
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
                  const Text(
                    '[State Count]',
                    style: TextStyle(color: Colors.black, fontSize: 13),
                  ),
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
          const SizedBox(height: 8),
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
  }) {
    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[Recall Reason Short]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Row(
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
          ),
          const SizedBox(height: 12),
          // Reports of Injury (full width, under Recall Reason Short)
          const Text(
            '[Reports of Injury]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            recall.reportsOfInjury.isNotEmpty
                ? recall.reportsOfInjury
                : 'Not specified',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '[Brand Name]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            brandName,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            '[Product Name]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            productName,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            '[Packaging Desc]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            packagingDesc,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            '[Product Size/Weight]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            productSizeWeight,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            'Produced:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Row(
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
          ),
          const SizedBox(height: 12),
          Row(
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
          ),
          const SizedBox(height: 12),
          // ...existing code...
        ],
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
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Qty and Packaged On Date row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[Product Qty]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[Packaged On Date]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
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
          ),
          const SizedBox(height: 16),
          // UPC and SKU row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[UPC]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[SKU]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
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
          ),
          const SizedBox(height: 16),
          // Batch/Lot Code and Sell By row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[Batch_Lot_Code]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Batch or Lot: ',
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
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '[Sell By Date]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Sell By: ',
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // (No full-width Packaged On Date section)
          // Expiration Date full width
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '[Exp Date]',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Expiration Date: ',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: expDate,
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Best Used By Date full width
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '[Best Used By Date]',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
              RichText(
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
                      text: recall.bestUsedByDate,
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
