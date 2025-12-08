import 'package:flutter/material.dart';
import '../models/user_item.dart';
import 'package:intl/intl.dart';

class UserItemCard extends StatelessWidget {
  final UserItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String? recallStatus; // "Recall Started", "Needs Review", or null

  const UserItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
    this.recallStatus,
  });

  String _formatDateType(String? dateType) {
    if (dateType == null || dateType.isEmpty) return '';
    return dateType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MM/dd/yy').format(date);
  }

  Color _getStatusColor() {
    if (recallStatus == 'Recall Started') {
      return Colors.orange; // Orange for RMC enrolled
    } else if (recallStatus == 'Needs Review') {
      return Colors.red; // Red for pending review
    }
    return Colors.transparent;
  }

  IconData _getStatusIcon() {
    if (recallStatus == 'Recall Started') {
      return Icons.play_circle_outline; // In progress icon
    } else if (recallStatus == 'Needs Review') {
      return Icons.warning_amber_rounded; // Alert icon
    }
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A5774),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.brandName.isNotEmpty ? item.brandName : 'Unknown Brand',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            // Recall Status Badge
            if (recallStatus != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(), size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      recallStatus!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.productName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(item.productName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.modelNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Model: ${item.modelNumber}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.upc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('UPC: ${item.upc}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.sku.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('SKU: ${item.sku}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.batchLotCode.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Lot: ${item.batchLotCode}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.serialNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('SN: ${item.serialNumber}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                        ),
                      if (item.dateType != null && item.itemDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${_formatDateType(item.dateType)}: ${_formatDate(item.itemDate)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                        ),
                      if (item.retailer != null && item.retailer!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Purchased at: ${item.retailer}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                        ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(item.location, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w400), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (item.fullPhotoUrls.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.fullPhotoUrls.first,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image_not_supported, size: 40, color: Colors.white54)),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: const Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))));
                      },
                    ),
                  )
                else
                  Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.photo_library_outlined, size: 40, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
