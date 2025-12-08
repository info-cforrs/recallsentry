import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../pages/manufacturer_retailer_page.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class NHTSAChildSeatRecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const NHTSAChildSeatRecallDetailsCard({super.key, required this.recall});

  void _navigateToManufacturerRetailer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManufacturerRetailerPage(recall: recall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopRow(
          dateIssued: recall.dateIssued,
          agency: recall.agency,
        ),
        _buildRiskStateRow(
          riskLevel: recall.riskLevel,
          stateCount: recall.stateCount,
        ),
        _buildDetailsFields(),
      ],
    );
  }

  Widget _buildTopRow({
    required DateTime dateIssued,
    required String agency,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondary,
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
              color: AppColors.textPrimary,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
          // Agency badge with recall type (right side) - Orange for NHTSA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100), // Orange for NHTSA
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  agency,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.child_care, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Child Seat',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Widget _buildRiskStateRow({
    required String riskLevel,
    required dynamic stateCount,
  }) {
    return Container(
      color: AppColors.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk level badge - only show if not empty and not "Not Classified"
          if (riskLevel.trim().isNotEmpty &&
              riskLevel.trim().toLowerCase() != 'not classified')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getRiskLevelColor(riskLevel),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                riskLevel,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          // Spacer to push state count to the right when risk level is empty/not classified
          if (riskLevel.trim().isEmpty ||
              riskLevel.trim().toLowerCase() == 'not classified')
            const Spacer(),
          // State count / Nationwide
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(String riskLevel) {
    final lower = riskLevel.toLowerCase();
    if (lower.contains('high') || lower.contains('serious')) {
      return AppColors.error;
    } else if (lower.contains('medium') || lower.contains('moderate')) {
      return Colors.orange;
    } else if (lower.contains('low')) {
      return Colors.yellow.shade700;
    }
    return AppColors.error; // Default to red for recalls
  }

  Widget _buildDetailsFields() {
    List<Widget> children = [];

    // Component - show as category
    final cleanComponent = recall.nhtsaComponent.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    if (cleanComponent.isNotEmpty) {
      children.add(Row(
        children: [
          Expanded(
            child: Text(
              cleanComponent,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    // Negative Outcomes / Consequence Summary
    if (recall.negativeOutcomes.isNotEmpty) {
      children.add(Text(
        recall.negativeOutcomes,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Recall Reason / Defect Summary
    if (recall.recallReason.isNotEmpty) {
      children.add(Text(
        recall.recallReason,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ));
      children.add(const SizedBox(height: 16));
    }

    // 1px line above brand name
    if (recall.brandName.isNotEmpty) {
      children.add(Container(
        height: 1,
        color: AppColors.textPrimary.withValues(alpha: 0.2),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Brand Name / Manufacturer - with arrow and modal trigger
    if (recall.brandName.isNotEmpty) {
      children.add(Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _navigateToManufacturerRetailer(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      recall.brandName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textPrimary,
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

    // Product Name / Subject
    if (recall.productName.isNotEmpty) {
      children.add(Text(
        recall.productName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Model Number
    if (recall.nhtsaModelNum.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Model:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              recall.nhtsaModelNum,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    // UPC Code
    if (recall.nhtsaUpc.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'UPC:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              recall.nhtsaUpc,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    // Potentially Affected
    if (recall.nhtsaPotentiallyAffected != null && recall.nhtsaPotentiallyAffected! > 0) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Units Affected:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _formatNumber(recall.nhtsaPotentiallyAffected!),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    // Manufacturer Phone
    if (recall.nhtsaManufPhone.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Manufacturer Phone:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              recall.nhtsaManufPhone,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    // Add recall ID at the bottom
    final recallId = recall.nhtsaRecallId.isNotEmpty
        ? recall.nhtsaRecallId
        : recall.id;
    if (recallId.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        Text(
          'Campaign Number: $recallId',
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
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
