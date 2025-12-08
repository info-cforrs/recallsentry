import 'package:flutter/material.dart';
import '../models/user_item.dart';
import '../models/recall_match.dart';
import '../constants/app_colors.dart';
import '../services/recallmatch_service.dart';
import '../services/api_service.dart';
import 'recall_match_alert_page.dart';
import 'rmc_details_page.dart';

class UserItemDetailsPage extends StatefulWidget {
  final UserItem item;

  const UserItemDetailsPage({super.key, required this.item});

  @override
  State<UserItemDetailsPage> createState() => _UserItemDetailsPageState();
}

class _UserItemDetailsPageState extends State<UserItemDetailsPage> {
  final RecallMatchService _recallMatchService = RecallMatchService();
  final ApiService _apiService = ApiService();
  String? _recallStatus;
  RecallMatchSummary? _recallMatch;

  @override
  void initState() {
    super.initState();
    _loadRecallStatus();
  }

  Future<void> _loadRecallStatus() async {
    try {
      final status = await _recallMatchService.getItemRecallStatus(widget.item.id);
      RecallMatchSummary? match;
      if (status != null) {
        match = await _recallMatchService.getMatchForItem(widget.item.id);
      }
      if (mounted) {
        setState(() {
          _recallStatus = status;
          _recallMatch = match;
        });
      }
    } catch (e) {
      debugPrint('Warning: Could not fetch recall status: $e');
    }
  }

  Future<void> _handleStatusTap() async {
    if (_recallStatus == 'Needs Review') {
      // Navigate to RecallMatch Alerts page
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecallMatchAlertPage()),
      );
      // Refresh status when returning (user may have confirmed/dismissed the match)
      if (mounted) {
        _loadRecallStatus();
      }
    } else if (_recallStatus == 'Recall Started' && _recallMatch != null) {
      // Navigate to RMC Details page for this item
      try {
        // Try to get the RMC enrollment for this recall
        final enrollments = await _apiService.fetchRmcEnrollments();
        final recallDbId = _recallMatch!.recall.databaseId;
        dynamic enrollment;
        if (recallDbId != null) {
          for (final e in enrollments) {
            if (e.recallId == recallDbId) {
              enrollment = e;
              break;
            }
          }
        }

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RmcDetailsPage(
                recall: _recallMatch!.recall,
                enrollment: enrollment,
              ),
            ),
          );
          // Refresh status when returning (recall may have been completed)
          if (mounted) {
            _loadRecallStatus();
          }
        }
      } catch (e) {
        debugPrint('Error navigating to RMC page: $e');
        // Fallback: navigate without enrollment
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RmcDetailsPage(
                recall: _recallMatch!.recall,
              ),
            ),
          );
          // Refresh status when returning
          if (mounted) {
            _loadRecallStatus();
          }
        }
      }
    }
  }

  UserItem get item => widget.item;

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format production date from week and year (e.g., "Week 08, 2022")
  String _formatProductionDate(String? week, String? year) {
    if (week != null && year != null) {
      return 'Week $week, $year';
    } else if (week != null) {
      return 'Week $week';
    } else if (year != null) {
      return year;
    }
    return '';
  }

  /// Format child seat production date from month and year (e.g., "March 2022")
  String _formatChildSeatProductionDate(String? month, String? year) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month != null && year != null) {
      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return '${monthNames[monthIndex - 1]} $year';
      }
      return '$month/$year';
    } else if (month != null) {
      final monthIndex = int.tryParse(month);
      if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
        return monthNames[monthIndex - 1];
      }
      return month;
    } else if (year != null) {
      return year;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          item.isVehicle
              ? item.fullVehicleName
              : item.isTires
                  ? item.fullTireName
                  : item.isChildSeat
                      ? item.fullChildSeatName
                      : item.displayName,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Gallery Section
            if (item.fullPhotoUrls.isNotEmpty)
              Container(
                height: 300,
                color: AppColors.secondary,
                child: item.fullPhotoUrls.length == 1
                    ? _buildSinglePhoto(item.fullPhotoUrls.first)
                    : _buildPhotoCarousel(),
              )
            else
              Container(
                height: 200,
                color: AppColors.secondary,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No photos available',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Details Section
            Container(
              color: const Color(0xFF0A5774),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Details Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.isVehicle
                              ? Icons.directions_car
                              : item.isTires
                                  ? Icons.tire_repair
                                  : item.isChildSeat
                                      ? Icons.child_care
                                      : Icons.info_outline,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.isVehicle
                              ? 'Vehicle Details'
                              : item.isTires
                                  ? 'Tire Details'
                                  : item.isChildSeat
                                      ? 'Child Seat Details'
                                      : 'Item Details',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recall Status Badge (if any) - Clickable
                  if (_recallStatus != null) ...[
                    GestureDetector(
                      onTap: _handleStatusTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _recallStatus == 'Recall Started' ? Colors.orange : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _recallStatus == 'Recall Started'
                                  ? Icons.play_circle_outline
                                  : Icons.warning_amber_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _recallStatus!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location
                  _buildDetailRow('Location', item.location, Icons.location_on),

                  // Vehicle-specific fields
                  if (item.isVehicle) ...[
                    if (item.vehicleYear != null && item.vehicleYear!.isNotEmpty)
                      _buildDetailRow('Year', item.vehicleYear!, Icons.calendar_today),

                    if (item.vehicleMake != null && item.vehicleMake!.isNotEmpty)
                      _buildDetailRow('Make', item.vehicleMake!, Icons.directions_car),

                    if (item.vehicleModel != null && item.vehicleModel!.isNotEmpty)
                      _buildDetailRow('Model', item.vehicleModel!, Icons.drive_eta),

                    if (item.vehicleVin != null && item.vehicleVin!.isNotEmpty)
                      _buildDetailRow('VIN', item.vehicleVin!, Icons.confirmation_number),
                  ] else if (item.isTires) ...[
                    // Tire-specific fields
                    if (item.manufacturer.isNotEmpty)
                      _buildDetailRow('Manufacturer', item.manufacturer, Icons.business),

                    if (item.modelNumber.isNotEmpty)
                      _buildDetailRow('Model', item.modelNumber, Icons.label),

                    if (item.tireDotCode != null && item.tireDotCode!.isNotEmpty)
                      _buildDetailRow('DOT Code', item.tireDotCode!, Icons.qr_code),

                    if (item.tireProductionWeek != null || item.tireProductionYear != null)
                      _buildDetailRow(
                        'Production Date',
                        _formatProductionDate(item.tireProductionWeek, item.tireProductionYear),
                        Icons.calendar_today,
                      ),

                    if (item.tireSize != null && item.tireSize!.isNotEmpty)
                      _buildDetailRow('Tire Size', item.tireSize!, Icons.straighten),

                    if (item.tireQty != null && item.tireQty! > 0)
                      _buildDetailRow('Quantity', item.tireQty.toString(), Icons.numbers),

                    if (item.upc.isNotEmpty)
                      _buildDetailRow('UPC', item.upc, Icons.qr_code_scanner),

                    if (item.retailer != null && item.retailer!.isNotEmpty)
                      _buildDetailRow('Where Purchased', item.retailer!, Icons.store),
                  ] else if (item.isChildSeat) ...[
                    // Child seat-specific fields
                    if (item.manufacturer.isNotEmpty)
                      _buildDetailRow('Manufacturer', item.manufacturer, Icons.business),

                    if (item.modelNumber.isNotEmpty)
                      _buildDetailRow('Model', item.modelNumber, Icons.label),

                    if (item.childSeatModelNumber != null && item.childSeatModelNumber!.isNotEmpty)
                      _buildDetailRow('Model Number', item.childSeatModelNumber!, Icons.confirmation_number),

                    if (item.childSeatProductionMonth != null || item.childSeatProductionYear != null)
                      _buildDetailRow(
                        'Production Date',
                        _formatChildSeatProductionDate(item.childSeatProductionMonth, item.childSeatProductionYear),
                        Icons.calendar_today,
                      ),

                    if (item.upc.isNotEmpty)
                      _buildDetailRow('UPC', item.upc, Icons.qr_code_scanner),

                    if (item.retailer != null && item.retailer!.isNotEmpty)
                      _buildDetailRow('Where Purchased', item.retailer!, Icons.store),
                  ] else ...[
                    // Non-vehicle item fields
                    // Manufacturer
                    if (item.manufacturer.isNotEmpty)
                      _buildDetailRow('Manufacturer', item.manufacturer, Icons.business),

                    // Brand Name
                    if (item.brandName.isNotEmpty)
                      _buildDetailRow('Brand', item.brandName, Icons.label),

                    // Product Name
                    if (item.productName.isNotEmpty)
                      _buildDetailRow('Product', item.productName, Icons.shopping_bag),

                    // Model Number
                    if (item.modelNumber.isNotEmpty)
                      _buildDetailRow('Model Number', item.modelNumber, Icons.confirmation_number),

                    // UPC
                    if (item.upc.isNotEmpty)
                      _buildDetailRow('UPC', item.upc, Icons.qr_code),

                    // SKU
                    if (item.sku.isNotEmpty)
                      _buildDetailRow('SKU', item.sku, Icons.inventory),

                    // Batch/Lot Code
                    if (item.batchLotCode.isNotEmpty)
                      _buildDetailRow('Batch/Lot Code', item.batchLotCode, Icons.numbers),

                    // Serial Number
                    if (item.serialNumber.isNotEmpty)
                      _buildDetailRow('Serial Number', item.serialNumber, Icons.tag),

                    // Date Type & Item Date
                    if (item.itemDate != null)
                      _buildDetailRow(
                        item.dateType ?? 'Date',
                        _formatDate(item.itemDate!),
                        Icons.calendar_today,
                      ),

                    // Retailer
                    if (item.retailer != null && item.retailer!.isNotEmpty)
                      _buildDetailRow('Retailer', item.retailer!, Icons.store),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinglePhoto(String photoUrl) {
    return Image.network(
      photoUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.secondary,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: AppColors.textDisabled,
                ),
                SizedBox(height: 12),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.secondary,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoCarousel() {
    return PageView.builder(
      itemCount: item.fullPhotoUrls.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            _buildSinglePhoto(item.fullPhotoUrls[index]),
            // Photo counter badge
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${index + 1} / ${item.fullPhotoUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Value
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
}
