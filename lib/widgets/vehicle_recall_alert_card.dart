import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vehicle_recall_alert.dart';
import '../providers/vehicle_recall_alert_providers.dart';
import '../constants/app_colors.dart';

/// Card widget for displaying a vehicle recall alert
///
/// Shows alert details and provides actions:
/// - "Check NHTSA.gov" button - Opens NHTSA website for VIN-specific verification
/// - After checking, shows "I'm Affected" / "Not Affected" buttons
/// - "I'm Affected" creates RMC enrollment
/// - "Not Affected" clears the alert
class VehicleRecallAlertCard extends ConsumerStatefulWidget {
  final VehicleRecallAlert alert;
  final VoidCallback? onStatusChanged;

  const VehicleRecallAlertCard({
    super.key,
    required this.alert,
    this.onStatusChanged,
  });

  @override
  ConsumerState<VehicleRecallAlertCard> createState() => _VehicleRecallAlertCardState();
}

class _VehicleRecallAlertCardState extends ConsumerState<VehicleRecallAlertCard> {
  bool _isLoading = false;
  bool _hasCheckedNhtsa = false;

  @override
  void initState() {
    super.initState();
    _hasCheckedNhtsa = widget.alert.hasCheckedNhtsa;
  }

  Future<void> _openNhtsaAndMarkChecked() async {
    setState(() => _isLoading = true);

    try {
      final alertService = ref.read(vehicleRecallAlertServiceProvider);
      final response = await alertService.markChecked(widget.alert.id);

      // Open NHTSA URL
      final uri = Uri.parse(response.nhtsaUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() {
          _hasCheckedNhtsa = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _respondNotAffected() async {
    setState(() => _isLoading = true);

    try {
      final alertService = ref.read(vehicleRecallAlertServiceProvider);
      await alertService.respondNotAffected(widget.alert.id);

      // Invalidate providers to refresh data
      ref.invalidate(pendingVehicleRecallAlertsProvider);
      ref.invalidate(pendingVehicleAlertCountProvider);
      ref.invalidate(vehicleRecallAlertsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert cleared - your vehicle is not affected'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _respondAffected() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Vehicle Affected',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          'You confirmed your VIN is listed on NHTSA.gov for this recall.\n\n'
          'This will enroll you in Recall Management so you can track the recall resolution process.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Enroll'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final alertService = ref.read(vehicleRecallAlertServiceProvider);
      final response = await alertService.respondAffected(widget.alert.id);

      // Invalidate providers to refresh data
      ref.invalidate(pendingVehicleRecallAlertsProvider);
      ref.invalidate(pendingVehicleAlertCountProvider);
      ref.invalidate(vehicleRecallAlertsProvider);

      if (mounted) {
        if (response.createdRmcEnrollment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enrolled in Recall Management - track your recall progress'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissAlert() async {
    setState(() => _isLoading = true);

    try {
      final alertService = ref.read(vehicleRecallAlertServiceProvider);
      await alertService.dismissAlert(widget.alert.id);

      ref.invalidate(pendingVehicleRecallAlertsProvider);
      ref.invalidate(pendingVehicleAlertCountProvider);
      ref.invalidate(vehicleRecallAlertsProvider);

      if (mounted) {
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with warning badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Potential Recall Alert',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.alert.vehicleName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: _isLoading ? null : _dismissAlert,
                  tooltip: 'Dismiss',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign number and date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Campaign: ${widget.alert.campaignNumber}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDate(widget.alert.recallDate),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Component
                if (widget.alert.component.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Component: ${widget.alert.component}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Summary
                Text(
                  widget.alert.shortSummary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Info box explaining what to do
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hasCheckedNhtsa
                              ? 'Did you find your VIN listed on NHTSA.gov?'
                              : 'Check NHTSA.gov with your VIN to verify if your specific vehicle is affected.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (!_hasCheckedNhtsa)
                  // Show "Check NHTSA" button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openNhtsaAndMarkChecked,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Check NHTSA.gov'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  )
                else
                  // Show response buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _respondNotAffected,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Not Affected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _respondAffected,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("I'm Affected"),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Small badge widget to show on vehicle cards when there are pending alerts
class VehicleAlertBadge extends StatelessWidget {
  final int alertCount;

  const VehicleAlertBadge({super.key, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    if (alertCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            alertCount == 1 ? '1 Alert' : '$alertCount Alerts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
