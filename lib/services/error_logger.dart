/// Centralized Error Logger
///
/// Tracks error patterns, frequency, and provides debugging capabilities.
/// Maintains an in-memory log of recent errors for debugging and analysis.
library;

import 'package:flutter/foundation.dart';
import '../core/exceptions.dart';
import 'error_reporting_service.dart';

/// A single error log entry
class ErrorLogEntry {
  final DateTime timestamp;
  final String message;
  final String service;
  final String? method;
  final String errorType;
  final String errorMessage;
  final String? context;
  final bool reported;

  ErrorLogEntry({
    required this.timestamp,
    required this.message,
    required this.service,
    this.method,
    required this.errorType,
    required this.errorMessage,
    this.context,
    this.reported = false,
  });

  @override
  String toString() {
    final methodStr = method != null ? '.$method' : '';
    final contextStr = context != null ? ' [$context]' : '';
    return '[${timestamp.toIso8601String()}] $service$methodStr$contextStr: $message ($errorType)';
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'service': service,
        'method': method,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'context': context,
        'reported': reported,
      };
}

/// Statistics about error occurrences
class ErrorStatistics {
  final int totalErrors;
  final int reportedErrors;
  final int unreportedErrors;
  final Map<String, int> errorsByType;
  final Map<String, int> errorsByService;
  final DateTime? firstError;
  final DateTime? lastError;

  ErrorStatistics({
    required this.totalErrors,
    required this.reportedErrors,
    required this.unreportedErrors,
    required this.errorsByType,
    required this.errorsByService,
    this.firstError,
    this.lastError,
  });

  @override
  String toString() {
    return '''
Error Statistics:
  Total: $totalErrors
  Reported: $reportedErrors
  Unreported: $unreportedErrors
  First Error: ${firstError?.toIso8601String() ?? 'N/A'}
  Last Error: ${lastError?.toIso8601String() ?? 'N/A'}
  By Type: $errorsByType
  By Service: $errorsByService
''';
  }
}

/// Centralized error logging service
class ErrorLogger {
  static final List<ErrorLogEntry> _logs = [];
  static const int _maxLogs = 1000;
  static bool _enabled = true;

  /// Log an error with context
  static void log({
    required String message,
    required String service,
    String? method,
    dynamic error,
    StackTrace? stackTrace,
    String? context,
    bool reportToAnalytics = true,
  }) {
    if (!_enabled) return;

    final errorType = error?.runtimeType.toString() ?? 'Unknown';
    final errorMessage = error?.toString() ?? 'No error object';

    final entry = ErrorLogEntry(
      timestamp: DateTime.now(),
      message: message,
      service: service,
      method: method,
      errorType: errorType,
      errorMessage: errorMessage,
      context: context,
      reported: reportToAnalytics,
    );

    _logs.add(entry);

    // Keep only recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Report to analytics if requested
    if (reportToAnalytics && error != null) {
      ErrorReportingService.recordException(
        error,
        stackTrace,
        context: '${service}${method != null ? '.$method' : ''}',
      );
    }

    // Print in debug mode
    if (kDebugMode) {
      debugPrint('🔴 [ERROR] $entry');
    }
  }

  /// Log an info message (non-error)
  static void logInfo({
    required String message,
    required String service,
    String? method,
    String? context,
  }) {
    if (!_enabled) return;

    if (kDebugMode) {
      final methodStr = method != null ? '.$method' : '';
      final contextStr = context != null ? ' [$context]' : '';
      debugPrint('ℹ️ [INFO] $service$methodStr$contextStr: $message');
    }

    ErrorReportingService.log(message);
  }

  /// Get recent error logs
  static List<ErrorLogEntry> getRecentErrors(int count) {
    final startIndex = (_logs.length - count).clamp(0, _logs.length);
    return _logs.sublist(startIndex);
  }

  /// Get all error logs
  static List<ErrorLogEntry> getAllErrors() {
    return List.unmodifiable(_logs);
  }

  /// Get errors for a specific service
  static List<ErrorLogEntry> getErrorsByService(String service) {
    return _logs.where((log) => log.service == service).toList();
  }

  /// Get errors of a specific type
  static List<ErrorLogEntry> getErrorsByType(String errorType) {
    return _logs.where((log) => log.errorType == errorType).toList();
  }

  /// Get errors within a time range
  static List<ErrorLogEntry> getErrorsByTimeRange(DateTime start, DateTime end) {
    return _logs
        .where((log) =>
            log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
  }

  /// Get error statistics
  static ErrorStatistics getStatistics() {
    if (_logs.isEmpty) {
      return ErrorStatistics(
        totalErrors: 0,
        reportedErrors: 0,
        unreportedErrors: 0,
        errorsByType: {},
        errorsByService: {},
      );
    }

    final errorsByType = <String, int>{};
    final errorsByService = <String, int>{};
    int reportedErrors = 0;

    for (final log in _logs) {
      errorsByType[log.errorType] = (errorsByType[log.errorType] ?? 0) + 1;
      errorsByService[log.service] = (errorsByService[log.service] ?? 0) + 1;
      if (log.reported) reportedErrors++;
    }

    return ErrorStatistics(
      totalErrors: _logs.length,
      reportedErrors: reportedErrors,
      unreportedErrors: _logs.length - reportedErrors,
      errorsByType: errorsByType,
      errorsByService: errorsByService,
      firstError: _logs.first.timestamp,
      lastError: _logs.last.timestamp,
    );
  }

  /// Clear all error logs
  static void clearLogs() {
    _logs.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Error logs cleared');
    }
  }

  /// Clear logs older than specified duration
  static void clearOldLogs(Duration age) {
    final cutoffTime = DateTime.now().subtract(age);
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffTime));
    if (kDebugMode) {
      debugPrint('🗑️ Cleared logs older than $age');
    }
  }

  /// Enable/disable error logging
  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (kDebugMode) {
      debugPrint('🔧 Error logging ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  /// Check if error logging is enabled
  static bool get isEnabled => _enabled;

  /// Get total error count
  static int get errorCount => _logs.length;

  /// Print error summary (debug only)
  static void printSummary() {
    if (!kDebugMode) return;

    final stats = getStatistics();
    debugPrint('📊 Error Summary:');
    debugPrint(stats.toString());
  }

  /// Export logs as JSON (for debugging)
  static List<Map<String, dynamic>> exportLogsAsJson() {
    return _logs.map((log) => log.toJson()).toList();
  }

  /// Get recent error summary (last 10 errors)
  static String getRecentSummary() {
    if (_logs.isEmpty) return 'No errors logged';

    final recent = getRecentErrors(10);
    final buffer = StringBuffer();
    buffer.writeln('Recent Errors (${recent.length}):');
    for (final log in recent) {
      buffer.writeln('  - $log');
    }
    return buffer.toString();
  }
}
