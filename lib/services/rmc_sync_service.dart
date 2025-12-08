import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/rmc_enrollment.dart';
import 'rmc_database_helper.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service for syncing RMC enrollments with offline support
class RmcSyncService {
  static final RmcSyncService _instance = RmcSyncService._internal();
  factory RmcSyncService() => _instance;
  RmcSyncService._internal();

  final _dbHelper = RmcDatabaseHelper();
  final _apiService = ApiService();
  final _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initialize sync service and start listening for connectivity changes
  /// MEMORY: Guards against duplicate initialization to prevent subscription leaks
  Future<void> initialize() async {
    // Guard: If already initialized, cancel existing subscription first
    // to prevent multiple subscriptions from accumulating
    if (_connectivitySubscription != null) {
      await _connectivitySubscription!.cancel();
    }

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Check initial connectivity and sync if online
    final connectivityResult = await _connectivity.checkConnectivity();
    if (_isOnline(connectivityResult)) {
      await syncAll();
    } else {
    }
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) async {
    if (_isOnline(result)) {
      _syncStatusController.add(SyncStatus.syncing);
      await syncAll();
    } else {
      _syncStatusController.add(SyncStatus.offline);
    }
  }

  /// Check if device is online
  bool _isOnline(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  /// Get current connectivity status
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  // ============================================================================
  // SYNC OPERATIONS
  // ============================================================================

  /// Sync all data: pull from server then push pending local changes
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync already in progress');
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      // Check if user is authenticated
      final isLoggedIn = await AuthService().isLoggedIn();
      if (!isLoggedIn) {
        _syncStatusController.add(SyncStatus.error);
        return SyncResult(success: false, message: 'Not authenticated');
      }

      // Check connectivity
      if (!await isOnline()) {
        _syncStatusController.add(SyncStatus.offline);
        return SyncResult(success: false, message: 'No internet connection');
      }


      // Step 1: Pull latest data from server
      final pullResult = await _pullFromServer();
      if (!pullResult.success) {
        _syncStatusController.add(SyncStatus.error);
        return pullResult;
      }

      // Step 2: Push pending local changes to server
      final pushResult = await _pushPendingChanges();
      if (!pushResult.success) {
        _syncStatusController.add(SyncStatus.error);
        return pushResult;
      }

      _lastSyncTime = DateTime.now();
      _syncStatusController.add(SyncStatus.synced);

      return SyncResult(
        success: true,
        message: 'Synced successfully',
        syncedCount: pullResult.syncedCount + pushResult.syncedCount,
      );
    } catch (e) {
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(success: false, message: 'Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Pull latest enrollments from server and save to local database
  Future<SyncResult> _pullFromServer() async {
    try {

      final enrollments = await _apiService.fetchRmcEnrollments();

      if (enrollments.isEmpty) {
        return SyncResult(success: true, message: 'No data to sync', syncedCount: 0);
      }

      // Save to local database
      await _dbHelper.saveEnrollments(enrollments);

      return SyncResult(
        success: true,
        message: 'Pulled ${enrollments.length} enrollments',
        syncedCount: enrollments.length,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Pull failed: $e');
    }
  }

  /// Push pending local changes to server
  Future<SyncResult> _pushPendingChanges() async {
    try {

      final pendingOperations = await _dbHelper.getPendingSync();

      if (pendingOperations.isEmpty) {
        return SyncResult(success: true, message: 'No pending changes', syncedCount: 0);
      }

      int successCount = 0;
      int failureCount = 0;

      for (final operation in pendingOperations) {
        try {
          final result = await _executeSyncOperation(operation);
          if (result) {
            await _dbHelper.removePendingSync(operation['id'] as int);
            successCount++;
          } else {
            await _dbHelper.incrementRetryCount(operation['id'] as int);
            failureCount++;
          }
        } catch (e) {
          await _dbHelper.incrementRetryCount(operation['id'] as int);
          failureCount++;
        }
      }


      return SyncResult(
        success: failureCount == 0,
        message: 'Pushed $successCount operations, $failureCount failed',
        syncedCount: successCount,
      );
    } catch (e) {
      return SyncResult(success: false, message: 'Push failed: $e');
    }
  }

  /// Execute a single sync operation
  Future<bool> _executeSyncOperation(Map<String, dynamic> operation) async {
    final operationType = operation['operation_type'] as String;
    final enrollmentId = operation['enrollment_id'] as int?;

    try {
      // Note: enrollment_data is stored as string, would need proper parsing
      // For now, we'll handle the most common operations

      switch (operationType) {
        case 'update_status':
          // Re-fetch the enrollment from local DB and push status update
          if (enrollmentId != null) {
            final enrollment = await _dbHelper.getEnrollmentById(enrollmentId);
            if (enrollment != null) {
              await _apiService.updateRmcEnrollmentStatus(
                enrollmentId,
                enrollment.status,
              );
              return true;
            }
          }
          return false;

        case 'create':
          // Would need to parse enrollment data and create
          // This is more complex, skip for now
          return false;

        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // ENROLLMENT OPERATIONS (with offline support)
  // ============================================================================

  /// Fetch enrollments (from local cache if offline, from server if online)
  Future<List<RmcEnrollment>> fetchEnrollments() async {
    if (await isOnline()) {
      try {
        // Try to fetch from server and update cache
        final enrollments = await _apiService.fetchRmcEnrollments();
        await _dbHelper.saveEnrollments(enrollments);
        return enrollments;
      } catch (e) {
        // Fall back to local cache
        return await _dbHelper.getAllEnrollments();
      }
    } else {
      // Offline, use local cache
      return await _dbHelper.getAllEnrollments();
    }
  }

  /// Fetch active enrollments (from local cache if offline)
  Future<List<RmcEnrollment>> fetchActiveEnrollments() async {
    if (await isOnline()) {
      try {
        final enrollments = await _apiService.fetchActiveRmcEnrollments();
        await _dbHelper.saveEnrollments(enrollments);
        return enrollments;
      } catch (e) {
        return await _dbHelper.getActiveEnrollments();
      }
    } else {
      return await _dbHelper.getActiveEnrollments();
    }
  }

  /// Update enrollment status (with offline support)
  Future<RmcEnrollment?> updateEnrollmentStatus(
    int enrollmentId,
    String newStatus,
  ) async {
    try {
      // Always update local database first
      final localEnrollment = await _dbHelper.getEnrollmentById(enrollmentId);
      if (localEnrollment == null) {
        return null;
      }

      final updatedEnrollment = localEnrollment.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      if (await isOnline()) {
        try {
          // Try to update on server
          final serverEnrollment = await _apiService.updateRmcEnrollmentStatus(
            enrollmentId,
            newStatus,
          );

          // Save server response to local database
          await _dbHelper.saveEnrollment(serverEnrollment, isSynced: true);
          return serverEnrollment;
        } catch (e) {
          // Save to local database as unsynced
          await _dbHelper.saveEnrollment(updatedEnrollment, isSynced: false);

          // Add to pending sync queue
          await _dbHelper.addPendingSync(
            operationType: 'update_status',
            enrollmentId: enrollmentId,
            enrollmentData: {'rmc_status': newStatus},
          );

          return updatedEnrollment;
        }
      } else {
        // Offline: save locally and queue for sync
        await _dbHelper.saveEnrollment(updatedEnrollment, isSynced: false);

        await _dbHelper.addPendingSync(
          operationType: 'update_status',
          enrollmentId: enrollmentId,
          enrollmentData: {'rmc_status': newStatus},
        );

        return updatedEnrollment;
      }
    } catch (e) {
      return null;
    }
  }

  /// Enroll a recall in RMC (with offline support)
  Future<RmcEnrollment?> enrollRecall({
    required int recallId,
    String rmcStatus = 'Not Active',
    String? lotNumber,
    String? purchaseDate,
    String? purchaseLocation,
    double? estimatedValue,
  }) async {
    if (await isOnline()) {
      try {
        // Create enrollment on server
        final enrollment = await _apiService.enrollRecallInRmc(
          recallId: recallId,
          rmcStatus: rmcStatus,
          lotNumber: lotNumber,
          purchaseDate: purchaseDate,
          purchaseLocation: purchaseLocation,
          estimatedValue: estimatedValue,
        );

        // Save to local cache
        await _dbHelper.saveEnrollment(enrollment, isSynced: true);
        return enrollment;
      } catch (e) {
        // Could implement offline enrollment here, but it's complex
        // because we need a server-assigned ID
        rethrow;
      }
    } else {
      throw Exception('Cannot enroll while offline');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats() async {
    final dbStats = await _dbHelper.getStats();
    return {
      ...dbStats,
      'last_sync': _lastSyncTime?.toIso8601String() ?? 'Never',
      'is_syncing': _isSyncing,
      'is_online': await isOnline(),
    };
  }

  /// Force sync now (manual trigger)
  Future<SyncResult> forceSyncNow() async {
    return await syncAll();
  }

  /// Clear local cache (use with caution)
  Future<void> clearLocalCache() async {
    await _dbHelper.clearAllData();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

enum SyncStatus {
  idle,
  syncing,
  synced,
  offline,
  error,
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
  });
}
