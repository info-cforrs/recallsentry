/// Error State Widget
///
/// Reusable widget for displaying error states with retry capabilities.
/// Provides consistent error UX across the application.
library;

import 'package:flutter/material.dart';
import '../core/exceptions.dart';
import '../utils/error_display.dart';

/// Widget for displaying error states with retry option
class ErrorStateWidget extends StatelessWidget {
  /// Main error message to display
  final String? message;

  /// Additional details (optional)
  final String? details;

  /// Callback when retry button is pressed
  final VoidCallback? onRetry;

  /// Callback when contact support button is pressed
  final VoidCallback? onContactSupport;

  /// The error object (optional, will extract icon/color from it)
  final dynamic error;

  /// Custom icon (optional)
  final IconData? icon;

  /// Whether to show the retry button
  final bool showRetry;

  /// Whether to show contact support button
  final bool showContactSupport;

  /// Custom button text
  final String? retryButtonText;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.details,
    this.onRetry,
    this.onContactSupport,
    this.error,
    this.icon,
    this.showRetry = true,
    this.showContactSupport = false,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = message ?? _getErrorMessage();
    final errorIcon = icon ?? _getErrorIcon();
    final errorColor = _getErrorColor();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorIcon,
              size: 64,
              color: errorColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (showRetry && onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(retryButtonText ?? 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (showContactSupport && onContactSupport != null)
                  OutlinedButton.icon(
                    onPressed: onContactSupport,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (error is AppException) {
      return (error as AppException).displayMessage;
    }
    return 'An error occurred. Please try again.';
  }

  IconData _getErrorIcon() {
    if (error != null) {
      return ErrorDisplay.getErrorIcon(error);
    }
    return Icons.error_outline;
  }

  Color _getErrorColor() {
    if (error != null) {
      return ErrorDisplay.getErrorColor(error);
    }
    return Colors.red;
  }
}

/// Compact error widget for smaller spaces
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final dynamic error;

  const CompactErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final errorIcon = error != null
        ? ErrorDisplay.getErrorIcon(error)
        : Icons.error_outline;
    final errorColor = error != null
        ? ErrorDisplay.getErrorColor(error)
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(errorIcon, color: errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget (no data, no error)
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionButtonText;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.details,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            if (onAction != null && actionButtonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionButtonText!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with optional message
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
