import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import 'main_navigation.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class AboutItemDetailsPage extends StatelessWidget {
  final RecallData recall;

  const AboutItemDetailsPage({super.key, required this.recall});

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            tooltip: 'Go back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Semantics(
          header: true,
          child: const Text(
            'About this Item Details',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About this Item Section Title
            Semantics(
              header: true,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Item Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Produced: From/To
            if (recall.productionDateStart != null || recall.productionDateEnd != null)
              _buildDateRangeRow(
                'Produced:',
                'From:',
                _formatDate(recall.productionDateStart),
                'To:',
                _formatDate(recall.productionDateEnd),
              ),

            // UPC
            if (recall.upc.isNotEmpty && recall.upc != 'N/A')
              _buildRow('UPC:', recall.upc),

            // SKU
            if (recall.sku.isNotEmpty)
              _buildRow('SKU:', recall.sku),

            // Batch/Lot Code
            if (recall.batchLotCode.isNotEmpty)
              _buildRow('Batch/Lot Code:', recall.batchLotCode),

            // Sell By Date
            if (recall.sellByDate.isNotEmpty)
              _buildRow('Sell By Date:', recall.sellByDate),

            // Exp Date
            if (recall.expDate.isNotEmpty)
              _buildRow('Exp Date:', recall.expDate),

            // Best Used By Date: From/To
            if (recall.bestUsedByDate.isNotEmpty || recall.bestUsedByDateEnd.isNotEmpty)
              _buildDateRangeRow(
                'Best Used By Date:',
                'From:',
                recall.bestUsedByDate.isNotEmpty ? recall.bestUsedByDate : 'N/A',
                'To:',
                recall.bestUsedByDateEnd.isNotEmpty ? recall.bestUsedByDateEnd : 'N/A',
              ),

            // Estimated Value (each)
            if (recall.estItemValue.isNotEmpty)
              _buildRow('Estimated Value (each):', recall.estItemValue),

            // No data message
            if ((recall.productionDateStart == null && recall.productionDateEnd == null) &&
                (recall.upc.isEmpty || recall.upc == 'N/A') &&
                recall.sku.isEmpty &&
                recall.batchLotCode.isEmpty &&
                recall.sellByDate.isEmpty &&
                recall.expDate.isEmpty &&
                recall.bestUsedByDate.isEmpty &&
                recall.bestUsedByDateEnd.isEmpty &&
                recall.estItemValue.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No item details available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textTertiary,
        currentIndex: 1,
        elevation: 8,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 0),
                ),
                (route) => false,
              );
              break;
            case 1:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 1),
                ),
                (route) => false,
              );
              break;
            case 2:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(initialIndex: 2),
                ),
                (route) => false,
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Label (left-aligned)
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right column: Value (right-aligned)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeRow(
    String mainLabel,
    String fromLabel,
    String fromValue,
    String toLabel,
    String toValue,
  ) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main label
          Text(
            mainLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          // From/To row
          Row(
            children: [
              Text(
                fromLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fromValue,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                toLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  toValue,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
