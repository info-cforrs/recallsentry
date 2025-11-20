/// Error Display Utilities
///
/// Provides consistent, user-friendly error display across the application.
/// Ensures technical error details are only shown in debug mode.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/exceptions.dart';
import '../services/error_reporting_service.dart';

/// Utilities for displaying errors to users
class ErrorDisplay {
  /// Show error in a SnackBar
  ///
  /// Displays a user-friendly error message with proper styling
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    final message = _getSafeMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: showRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white70,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }

  /// Show success message in a SnackBar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info message in a SnackBar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning message in a SnackBar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error in a dialog with optional retry
  static Future<bool> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return false;

    final message = _getSafeMessage(error);
    final errorTitle = title ?? 'Error';

    return await showDialog<bool>(
          context: context,
          barrierDismissible: barrierDismissible,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 12),
                Text(errorTitle),
              ],
            ),
            content: Text(message),
            actions: [
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                    onRetry();
                  },
                  child: const Text('Retry'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: isDestructive
                    ? TextButton.styleFrom(foregroundColor: Colors.red)
                    : null,
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Get safe user-friendly error message
  ///
  /// Returns technical details in debug mode, safe messages in production
  static String _getSafeMessage(dynamic error) {
    // If it's our custom exception, use its display message
    if (error is AppException) {
      return error.displayMessage;
    }

    // In debug mode, show technical details
    if (kDebugMode) {
      return error.toString();
    }

    // In production, show generic safe message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle error with automatic reporting and display
  ///
  /// This is a convenience method that both reports and displays errors
  static Future<void> handleError(
    BuildContext context,
    dynamic error,
    StackTrace? stackTrace, {
    String? errorContext,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) async {
    // Report error to analytics if appropriate
    if (error is! AppException || error.shouldReport) {
      await ErrorReportingService.recordException(
        error,
        stackTrace,
        context: errorContext,
      );
    }

    // Display error to user
    if (!context.mounted) return;

    if (showDialog) {
      await showErrorDialog(
        context,
        error,
        onRetry: onRetry,
      );
    } else {
      showError(
        context,
        error,
        showRetry: onRetry != null,
        onRetry: onRetry,
      );
    }
  }

  /// Get error icon based on error type
  static IconData getErrorIcon(dynamic error) {
    if (error is NetworkException) return Icons.cloud_off;
    if (error is AuthException) return Icons.lock_outline;
    if (error is ValidationException) return Icons.warning_amber;
    if (error is RateLimitException) return Icons.speed;
    if (error is ConnectivityException) return Icons.wifi_off;
    if (error is SubscriptionException) return Icons.workspace_premium;
    return Icons.error_outline;
  }

  /// Get error color based on error type
  static Color getErrorColor(dynamic error) {
    if (error is ValidationException) return Colors.orange;
    if (error is RateLimitException) return Colors.orange;
    if (error is ConnectivityException) return Colors.grey;
    return Colors.red;
  }
}
