import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../pages/manufacturer_retailer_page.dart';
import '../pages/about_item_details_page.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class CPSCRecallDetailsCard extends StatelessWidget {
  final RecallData recall;
  const CPSCRecallDetailsCard({super.key, required this.recall});

  void _navigateToManufacturerRetailer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManufacturerRetailerPage(recall: recall),
      ),
    );
  }

  void _navigateToAboutItemDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AboutItemDetailsPage(recall: recall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which section will be last (for border radius)
    bool hasDetailsFields = recall.category.isNotEmpty ||
        recall.negativeOutcomes.isNotEmpty ||
        recall.recallReason.isNotEmpty ||
        recall.brandName.isNotEmpty ||
        recall.productName.isNotEmpty ||
        recall.packagingDesc.isNotEmpty ||
        recall.cpscModel.isNotEmpty ||
        recall.cpscSerialNumber.isNotEmpty ||
        recall.soldBy.isNotEmpty ||
        recall.productQty.isNotEmpty;

    // Determine which is the last section
    bool detailsFieldsIsLast = hasDetailsFields;

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
          soldBy: recall.soldBy,
          productQty: recall.productQty,
          isLast: detailsFieldsIsLast,
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
          // Agency badge (right side) - Blue for CPSC
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0), // Blue for CPSC
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
    if (lower.contains('product safety warning')) {
      return Colors.purple;
    } else if (lower.contains('high') || lower.contains('serious')) {
      return AppColors.error;
    } else if (lower.contains('medium') || lower.contains('moderate')) {
      return Colors.orange;
    } else if (lower.contains('low')) {
      return Colors.yellow.shade700;
    }
    return AppColors.error; // Default to red for recalls
  }

  Widget _buildDetailsFields({
    required String negativeOutcomes,
    required String recallReason,
    required String brandName,
    required String productName,
    required String packagingDesc,
    required String soldBy,
    required String productQty,
    required bool isLast,
  }) {
    List<Widget> children = [];

    // Category - show above Negative Outcomes if not empty (full width row)
    // Remove newlines and extra whitespace from category
    final cleanCategory = recall.category.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    if (cleanCategory.isNotEmpty) {
      children.add(Row(
        children: [
          Expanded(
            child: Text(
              cleanCategory,
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

    // Negative Outcomes / Adverse Reactions - only show if not empty
    if (negativeOutcomes.isNotEmpty) {
      children.add(Text(
        negativeOutcomes,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
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

    // Reports of Injury - show without title as a separate row
    if (recall.reportsOfInjury.isNotEmpty && recall.reportsOfInjury != 'N/A') {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/Reports_of_Injury_icon.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.warning_amber,
                color: Colors.orange,
                size: 20,
              );
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              recall.reportsOfInjury,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ));
      children.add(const SizedBox(height: 16));
    }

    // 1px line above brand name
    if (brandName.isNotEmpty) {
      children.add(Container(
        height: 1,
        color: AppColors.textPrimary.withValues(alpha: 0.2),
      ));
      children.add(const SizedBox(height: 16));
    }

    // Brand Name - only show if not empty (with arrow and modal trigger)
    if (brandName.isNotEmpty) {
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
                      brandName,
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

    // Product Name - only show if not empty
    if (productName.isNotEmpty) {
      children.add(Text(
        productName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ));
      children.add(const SizedBox(height: 16));
    }

    // CPSC-Specific: Model Number
    if (recall.cpscModel.isNotEmpty) {
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
              recall.cpscModel,
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

    // CPSC-Specific: Serial Number
    if (recall.cpscSerialNumber.isNotEmpty) {
      children.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 140,
            child: Text(
              'Serial Number:',
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
              recall.cpscSerialNumber,
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

    // CPSC-Specific: Sold By Date Range
    if (recall.cpscSoldByDateStart != null || recall.cpscSoldByDateEnd != null) {
      String dateRange = '';
      if (recall.cpscSoldByDateStart != null && recall.cpscSoldByDateEnd != null) {
        dateRange = '${_formatDate(recall.cpscSoldByDateStart)} - ${_formatDate(recall.cpscSoldByDateEnd)}';
      } else if (recall.cpscSoldByDateStart != null) {
        dateRange = 'From ${_formatDate(recall.cpscSoldByDateStart)}';
      } else if (recall.cpscSoldByDateEnd != null) {
        dateRange = 'Until ${_formatDate(recall.cpscSoldByDateEnd)}';
      }

      if (dateRange.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 140,
              child: Text(
                'Sold Between:',
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
                dateRange,
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
    }

    // "About this Item" section - show if any of the three fields have data
    if (packagingDesc.isNotEmpty || productQty.isNotEmpty || soldBy.isNotEmpty) {
      // Section title with navigation
      children.add(Builder(
        builder: (context) {
          return GestureDetector(
            onTap: () => _navigateToAboutItemDetails(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'About this Item',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
      children.add(const SizedBox(height: 12));

      // Row 1: Packaging Description
      if (packagingDesc.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 160,
              child: Text(
                'Packaging Description:',
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
                packagingDesc,
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

      // Row 2: Product Quantity
      if (productQty.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 160,
              child: Text(
                'Product Quantity:',
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
                productQty,
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

      // Row 3: Sold By/Distributor
      if (soldBy.isNotEmpty) {
        children.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 160,
              child: Text(
                'Sold By/Distributor:',
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
                soldBy,
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

      children.add(const SizedBox(height: 4));
    }

    // Add recall ID at the bottom if this is the last section and recall number exists
    final recallId = recall.fieldRecallNumber.trim().isNotEmpty
        ? recall.fieldRecallNumber
        : recall.id;
    if (isLast && recallId.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        Text(
          'Recall Number: $recallId',
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
        color: AppColors.secondary,
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
