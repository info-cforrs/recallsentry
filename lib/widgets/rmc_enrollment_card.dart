import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// Card widget specifically designed for displaying RMC enrollments
/// Shows both recall information and user-specific enrollment data
class RmcEnrollmentCard extends StatelessWidget {
  final RecallData recall;
  final RmcEnrollment enrollment;
  final VoidCallback? onTap;

  const RmcEnrollmentCard({
    super.key,
    required this.recall,
    required this.enrollment,
    this.onTap,
  });

  Color _getStatusColor() {
    if (enrollment.status == 'Not Started') {
      return AppColors.warning; // Orange
    } else if (enrollment.status == 'Completed') {
      return AppColors.success; // Green
    } else if (enrollment.status.startsWith('In Progress')) {
      return AppColors.accentBlue; // Blue
    }
    return AppColors.riskUnknown; // Grey
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getShortStatus() {
    // Remove "In Progress - " prefix for display
    if (enrollment.status.startsWith('In Progress - ')) {
      return enrollment.status.replaceFirst('In Progress - ', '');
    }
    return enrollment.status;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getShortStatus().toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Last Updated
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Updated',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _formatDate(enrollment.updatedAt),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recall Information Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand, Product, and Image
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand and Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recall.brandName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recall.productName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Builder(
                          builder: (context) {
                            final imageUrl = recall.getPrimaryImageUrl();
                            return imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.black26,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: AppColors.textDisabled,
                                          size: 32,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.black26,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textDisabled,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.black26,
                                    child: const Icon(
                                      Icons.photo,
                                      color: AppColors.textDisabled,
                                      size: 32,
                                    ),
                                  );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Recall ID
                  Row(
                    children: [
                      const Icon(Icons.numbers, color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Recall ID: ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        recall.id,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: AppColors.border,
                  ),

                  const SizedBox(height: 16),

                  // User-Specific Enrollment Information
                  const Text(
                    'Your Item Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Purchase Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Purchase Date',
                          _formatDate(enrollment.purchaseDate),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          'Estimated Value',
                          recall.estItemValue.isNotEmpty
                              ? recall.estItemValue
                              : 'Not specified',
                          Icons.attach_money,
                        ),
                      ),
                    ],
                  ),

                  if (enrollment.lotNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Lot Number',
                      enrollment.lotNumber,
                      Icons.qr_code,
                    ),
                  ],

                  if (enrollment.purchaseLocation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Purchase Location',
                      enrollment.purchaseLocation,
                      Icons.store,
                    ),
                  ],

                  if (enrollment.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.note, color: Colors.white70, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Notes',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            enrollment.notes,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tap to Continue Indicator (only for non-completed enrollments)
                  if (enrollment.status.trim().toLowerCase() != 'completed' &&
                      enrollment.status.trim().toLowerCase() != 'closed') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          enrollment.status == 'Not Started'
                              ? 'Tap to start process'
                              : 'Tap to continue',
                          style: const TextStyle(
                            color: AppColors.accentBlueLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.accentBlueLight,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
