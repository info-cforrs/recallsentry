/// Vehicle Recall Alert Providers
///
/// Providers for managing vehicle recall alerts - these are alerts generated
/// when a new NHTSA recall is detected for a user's vehicle based on Year/Make/Model.
/// Users must verify on NHTSA.gov with their specific VIN to confirm if affected.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_providers.dart';
import '../models/vehicle_recall_alert.dart';
import '../services/vehicle_recall_alert_service.dart';

// ============================================================================
// SERVICE PROVIDER
// ============================================================================

/// Vehicle Recall Alert Service Provider
final vehicleRecallAlertServiceProvider = Provider<VehicleRecallAlertService>((ref) {
  return VehicleRecallAlertService();
});

// ============================================================================
// DATA PROVIDERS
// ============================================================================

/// All Vehicle Recall Alerts Provider - Fetches all alerts for the user
final vehicleRecallAlertsProvider = FutureProvider<List<VehicleRecallAlert>>((ref) async {
  await ref.watch(userProfileProvider.future);
  final alertService = ref.watch(vehicleRecallAlertServiceProvider);
  return alertService.getAlerts();
});

/// Pending Vehicle Recall Alerts Provider - Only pending (unverified) alerts
final pendingVehicleRecallAlertsProvider = FutureProvider<List<VehicleRecallAlert>>((ref) async {
  await ref.watch(userProfileProvider.future);
  final alertService = ref.watch(vehicleRecallAlertServiceProvider);
  return alertService.getPendingAlerts();
});

/// Pending Vehicle Recall Alert Count Provider - For badge display
final pendingVehicleAlertCountProvider = FutureProvider<int>((ref) async {
  await ref.watch(userProfileProvider.future);
  final alertService = ref.watch(vehicleRecallAlertServiceProvider);
  try {
    return await alertService.getPendingAlertCount();
  } catch (e) {
    return 0;
  }
});

/// Vehicle Recall Alerts By Item Provider - Get alerts for a specific vehicle
final vehicleRecallAlertsByItemProvider = FutureProvider.family<List<VehicleRecallAlert>, int>((ref, userItemId) async {
  await ref.watch(userProfileProvider.future);
  final alertService = ref.watch(vehicleRecallAlertServiceProvider);
  return alertService.getAlertsForItem(userItemId);
});

/// Has Pending Vehicle Alerts Provider - Quick check if any pending alerts exist
final hasPendingVehicleAlertsProvider = Provider<bool>((ref) {
  final countAsync = ref.watch(pendingVehicleAlertCountProvider);
  return countAsync.maybeWhen(
    data: (count) => count > 0,
    orElse: () => false,
  );
});

/// Pending Alert Count For Item Provider - Count pending alerts for a specific vehicle
final pendingAlertCountForItemProvider = FutureProvider.family<int, int>((ref, userItemId) async {
  final alerts = await ref.watch(vehicleRecallAlertsByItemProvider(userItemId).future);
  return alerts.where((a) => a.status == VehicleRecallAlertStatus.pending).length;
});
