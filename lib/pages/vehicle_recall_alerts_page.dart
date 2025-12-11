import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/vehicle_recall_alert.dart';
import '../providers/vehicle_recall_alert_providers.dart';
import '../widgets/vehicle_recall_alert_card.dart';
import '../widgets/custom_loading_indicator.dart';

/// Page displaying all vehicle recall alerts for the user
///
/// Shows pending alerts that need verification, plus history of
/// past alerts that were marked as affected or not affected.
class VehicleRecallAlertsPage extends ConsumerStatefulWidget {
  const VehicleRecallAlertsPage({super.key});

  @override
  ConsumerState<VehicleRecallAlertsPage> createState() => _VehicleRecallAlertsPageState();
}

class _VehicleRecallAlertsPageState extends ConsumerState<VehicleRecallAlertsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAlerts() {
    ref.invalidate(vehicleRecallAlertsProvider);
    ref.invalidate(pendingVehicleRecallAlertsProvider);
    ref.invalidate(pendingVehicleAlertCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(vehicleRecallAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        title: const Text(
          'Vehicle Recall Alerts',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentBlue,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 18),
                  const SizedBox(width: 6),
                  const Text('Pending'),
                  Consumer(
                    builder: (context, ref, _) {
                      final countAsync = ref.watch(pendingVehicleAlertCountProvider);
                      return countAsync.maybeWhen(
                        data: (count) => count > 0
                            ? Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 6),
                  Text('History'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: alertsAsync.when(
        data: (alerts) {
          final pendingAlerts = alerts
              .where((a) => a.status == VehicleRecallAlertStatus.pending)
              .toList();
          final historyAlerts = alerts
              .where((a) => a.status != VehicleRecallAlertStatus.pending)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Pending Tab
              _buildAlertsList(
                alerts: pendingAlerts,
                emptyIcon: Icons.check_circle_outline,
                emptyTitle: 'No Pending Alerts',
                emptyMessage: 'You have no vehicle recall alerts that need verification.',
              ),
              // History Tab
              _buildAlertsList(
                alerts: historyAlerts,
                emptyIcon: Icons.history,
                emptyTitle: 'No History',
                emptyMessage: 'Past vehicle recall alerts will appear here.',
                showStatusBadge: true,
              ),
            ],
          );
        },
        loading: () => const Center(child: CustomLoadingIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading alerts',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _refreshAlerts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsList({
    required List<VehicleRecallAlert> alerts,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
    bool showStatusBadge = false,
  }) {
    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, color: AppColors.textSecondary, size: 64),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshAlerts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];

          if (showStatusBadge) {
            // For history, wrap in a container with status indicator
            return _buildHistoryAlertCard(alert);
          }

          return VehicleRecallAlertCard(
            alert: alert,
            onStatusChanged: _refreshAlerts,
          );
        },
      ),
    );
  }

  Widget _buildHistoryAlertCard(VehicleRecallAlert alert) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (alert.status) {
      case VehicleRecallAlertStatus.affected:
        statusColor = Colors.orange;
        statusText = 'Affected - In RMC';
        statusIcon = Icons.warning;
        break;
      case VehicleRecallAlertStatus.notAffected:
        statusColor = AppColors.success;
        statusText = 'Not Affected';
        statusIcon = Icons.check_circle;
        break;
      case VehicleRecallAlertStatus.dismissed:
        statusColor = AppColors.textSecondary;
        statusText = 'Dismissed';
        statusIcon = Icons.remove_circle_outline;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'Unknown';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (alert.respondedAt != null)
                  Text(
                    _formatDate(alert.respondedAt!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Alert content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.vehicleName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campaign: ${alert.campaignNumber}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (alert.component.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Component: ${alert.component}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
