import 'package:flutter/material.dart';
import '../models/recall_data.dart';

class USDARecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const USDARecallDetailsCard({super.key, required this.recall});

  @override
  Widget build(BuildContext context) {
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
        ),
        _buildDetailsGrid(
          upc: recall.upc,
          sku: recall.sku,
          batchLotCode: recall.batchLotCode,
          sellByDate: recall.sellByDate,
        ),
        _buildDatesSection(
          expDate: recall.expDate,
          bestUsedByDate: recall.bestUsedByDate,
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
          Expanded(
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
                  child: Text(
                    recallClassification.isNotEmpty
                        ? (recallClassification.toLowerCase().contains(
                                'public health alert',
                              )
                              ? 'Public Health Alert'
                              : '${recallClassification.toUpperCase()} RECALL')
                        : 'RECALL',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
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
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
              const Text(
                '[State Count]',
                style: TextStyle(color: Colors.black, fontSize: 13),
              ),
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
  }) {
    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '[Negative Outcomes]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  negativeOutcomes,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '[Recall Reason]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Row(
            children: [
              const Icon(Icons.block, color: Colors.red, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  recallReason,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 3,
                ),
              ),
            ],
          ),
          // Reports of Injury field (full width, after Recall Reason)
          const SizedBox(height: 12),
          const Text(
            'Reports of Injury:',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            recall.reportsOfInjury.isNotEmpty
                ? recall.reportsOfInjury
                : 'Not specified',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
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
            '[Packaging Description]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            packagingDesc,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
          const SizedBox(height: 12),
          const Text(
            'Produced:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Row(
            children: [
              const Text(
                'From:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(productionDateStart),
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
              const SizedBox(width: 12),
              const Text(
                'To:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(productionDateEnd),
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '[Sold By/Distributor]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Row(
            children: [
              const Text(
                'Sold By:',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                soldBy,
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '[Product Quantity]',
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
          Text(
            productQty,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid({
    required String upc,
    required String sku,
    required String batchLotCode,
    required String sellByDate,
  }) {
    return Container(
      color: const Color(0xFFFFC107),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
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
          Row(
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
                      '[Sell_By_Date]',
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    RichText(
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection({
    required String expDate,
    required String bestUsedByDate,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
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
          const SizedBox(height: 18),
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
                  text: bestUsedByDate,
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                ),
              ],
            ),
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
