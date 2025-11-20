import 'package:flutter/material.dart';
import '../models/recall_data.dart';
import '../models/rmc_enrollment.dart';
import '../widgets/small_fda_recall_card.dart';
import '../widgets/small_usda_recall_card.dart';
import '../constants/rmc_status.dart';
import 'main_navigation.dart';
import 'package:rs_flutter/constants/app_colors.dart';

class CompletedRmcDetailsPage extends StatelessWidget {
  final RecallData recall;
  final RmcEnrollment enrollment;

  const CompletedRmcDetailsPage({
    required this.recall,
    required this.enrollment,
    super.key,
  });

  // Helper method to format date
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Helper method to format time
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Helper to get the resolution branch from status
  String? _getResolutionBranch() {
    // First, try to get from the dedicated resolutionBranch field
    if (enrollment.resolutionBranch != null && enrollment.resolutionBranch!.isNotEmpty) {
      return enrollment.resolutionBranch;
    }

    // Second, try to infer from status
    final branch = RmcStatus.getBranchType(enrollment.status);
    if (branch != null) {
      return branch;
    }

    // Third, try to infer from notes
    if (enrollment.notes.isNotEmpty) {
      final notesLower = enrollment.notes.toLowerCase();
      if (notesLower.contains('return') || notesLower.contains('refund')) {
        return 'Return';
      } else if (notesLower.contains('repair')) {
        return 'Repair';
      } else if (notesLower.contains('replace')) {
        return 'Replace';
      } else if (notesLower.contains('dispos')) {
        return 'Dispose';
      }
    }

    // Default to Return if we can't determine
    return 'Return';
  }

  // Helper to get branch-specific steps
  List<Map<String, dynamic>> _getBranchSteps() {
    final branch = _getResolutionBranch();
    if (branch == null) return [];

    switch (branch) {
      case 'Return':
        return [
          {'title': 'Return Method Selected', 'icon': Icons.assignment_return},
          {'title': 'Item Returned', 'icon': Icons.local_shipping},
          {'title': 'Refund Received', 'icon': Icons.payment},
        ];
      case 'Repair':
        return [
          {'title': 'Repair Method Selected', 'icon': Icons.build},
          {'title': 'Service Initiated', 'icon': Icons.engineering},
          {'title': 'Item Repaired', 'icon': Icons.check_circle_outline},
        ];
      case 'Replace':
        return [
          {'title': 'Replacement Method Selected', 'icon': Icons.swap_horiz},
          {'title': 'Replacement Received', 'icon': Icons.inventory},
        ];
      case 'Dispose':
        return [
          {'title': 'Disposal Method Selected', 'icon': Icons.delete_outline},
          {'title': 'Item Disposed', 'icon': Icons.delete_forever},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
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
            'Completed Process',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Recall Card based on agency
              Padding(
                padding: const EdgeInsets.all(16),
                child: recall.agency.toUpperCase() == 'USDA'
                    ? SmallUsdaRecallCard(recall: recall)
                    : SmallFdaRecallCard(recall: recall),
              ),

              // Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.secondary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Status: ${enrollment.status}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Process Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            color: AppColors.textPrimary,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Process Timeline',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Timeline items - Show all steps for completed process
                      _buildTimelineItem(
                        context,
                        'Enrolled',
                        enrollment.enrolledAt,
                        Icons.app_registration,
                        true,
                      ),

                      _buildTimelineItem(
                        context,
                        'Stopped Using Product',
                        enrollment.startedAt ?? enrollment.enrolledAt,
                        Icons.warning_amber_rounded,
                        true,
                      ),

                      _buildTimelineItem(
                        context,
                        'Discontinued Use',
                        enrollment.stoppedUsingAt ?? enrollment.startedAt ?? enrollment.enrolledAt,
                        Icons.do_not_disturb_on,
                        true,
                      ),

                      _buildTimelineItem(
                        context,
                        'Contacted Manufacturer',
                        enrollment.contactedManufacturerAt ?? enrollment.stoppedUsingAt ?? enrollment.enrolledAt,
                        Icons.phone,
                        true,
                      ),

                      // Branch-specific steps
                      if (_getResolutionBranch() != null) ...[
                        ..._getBranchSteps().asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          final isLast = index == _getBranchSteps().length - 1;

                          // Use resolutionStartedAt for first step, updatedAt for subsequent steps
                          final timestamp = index == 0
                              ? (enrollment.resolutionStartedAt ?? enrollment.contactedManufacturerAt ?? enrollment.updatedAt)
                              : enrollment.updatedAt;

                          return _buildTimelineItem(
                            context,
                            step['title'] as String,
                            timestamp,
                            step['icon'] as IconData,
                            !isLast || enrollment.completedAt != null,
                          );
                        }),
                      ],

                      _buildTimelineItem(
                        context,
                        'Process Completed',
                        enrollment.completedAt ?? enrollment.updatedAt,
                        Icons.check_circle,
                        false,
                      ),
                    ],
                  ),
                ),
              ),

              // Notes section if available
              if (enrollment.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.note,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Notes',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          enrollment.notes,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Additional details if available
              if (enrollment.lotNumber.isNotEmpty ||
                  enrollment.purchaseDate != null ||
                  enrollment.purchaseLocation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.textPrimary,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Product Details',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (enrollment.lotNumber.isNotEmpty)
                          _buildDetailRow('Lot Number', enrollment.lotNumber),
                        if (enrollment.purchaseDate != null)
                          _buildDetailRow(
                            'Purchase Date',
                            _formatDate(enrollment.purchaseDate!),
                          ),
                        if (enrollment.purchaseLocation.isNotEmpty)
                          _buildDetailRow('Purchase Location', enrollment.purchaseLocation),
                        if (recall.estItemValue.isNotEmpty)
                          _buildDetailRow(
                            'Estimated Value',
                            recall.estItemValue,
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.secondary,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textTertiary,
        currentIndex: 1, // Recalls tab selected
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

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    DateTime timestamp,
    IconData icon,
    bool hasNext,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                if (hasNext)
                  Container(
                    width: 2,
                    height: 60,
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.textTertiary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(timestamp),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          color: AppColors.textTertiary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasNext) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
