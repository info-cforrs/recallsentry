/// Error State Widget
///
/// Reusable widget for displaying error states with retry capabilities.
/// Provides consistent error UX across the application.
///
/// For empty states, use [EmptyState] from 'package:rs_flutter/widgets/empty_state.dart'
/// For loading states, use [CustomLoadingIndicator] from 'package:rs_flutter/widgets/custom_loading_indicator.dart'
library;

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/design_tokens.dart';
import '../core/exceptions.dart';
import '../utils/error_display.dart';
import 'buttons/buttons.dart';

/// Widget for displaying error states with retry option.
///
/// Example:
/// ```dart
/// ErrorStateWidget(
///   message: 'Failed to load data',
///   onRetry: () => loadData(),
/// )
/// ```
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
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Error icon',
              child: Icon(
                errorIcon,
                size: DesignTokens.iconSizeXxl,
                color: errorColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Semantics(
              label: 'Error message',
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeLg,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeMd,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingXl),
            Wrap(
              spacing: DesignTokens.spacingMd,
              runSpacing: DesignTokens.spacingMd,
              alignment: WrapAlignment.center,
              children: [
                if (showRetry && onRetry != null)
                  PrimaryButton(
                    label: retryButtonText ?? 'Retry',
                    onPressed: onRetry,
                    icon: Icons.refresh,
                    fullWidth: false,
                  ),
                if (showContactSupport && onContactSupport != null)
                  SecondaryButton(
                    label: 'Contact Support',
                    onPressed: onContactSupport,
                    icon: Icons.help_outline,
                    fullWidth: false,
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
    return AppColors.error;
  }
}

/// Compact error widget for smaller spaces like list items.
///
/// Example:
/// ```dart
/// CompactErrorWidget(
///   message: 'Failed to load item',
///   onRetry: () => retry(),
/// )
/// ```
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
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      child: Row(
        children: [
          Icon(errorIcon, color: errorColor, size: DesignTokens.iconSizeMd),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeSm,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: DesignTokens.spacingMd),
            IconButtonWithTooltip(
              icon: Icons.refresh,
              onPressed: onRetry,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}

/// @Deprecated('Use EmptyState from empty_state.dart instead')
/// Legacy empty state widget - use [EmptyState] for new code.
///
/// This widget is kept for backwards compatibility.
/// For new code, use:
/// ```dart
/// import 'package:rs_flutter/widgets/empty_state.dart';
/// EmptyState(
///   title: 'No items',
///   subtitle: 'Add some items to get started',
///   icon: Icons.inbox_outlined,
/// )
/// ```
@Deprecated('Use EmptyState from empty_state.dart instead. '
    'Import: package:rs_flutter/widgets/empty_state.dart')
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
        padding: const EdgeInsets.all(DesignTokens.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: DesignTokens.iconSizeXxl,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeLg,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: AppColors.textPrimary,
              ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeMd,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onAction != null && actionButtonText != null) ...[
              const SizedBox(height: DesignTokens.spacingXl),
              PrimaryButton(
                label: actionButtonText!,
                onPressed: onAction,
                icon: Icons.add,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// @Deprecated('Use CustomLoadingIndicator from custom_loading_indicator.dart instead')
/// Legacy loading state widget - use [CustomLoadingIndicator] for new code.
///
/// This widget is kept for backwards compatibility.
/// For new code, use:
/// ```dart
/// import 'package:rs_flutter/widgets/custom_loading_indicator.dart';
/// CustomLoadingIndicator(
///   message: 'Loading...',
///   size: LoadingIndicatorSize.medium,
/// )
/// ```
@Deprecated('Use CustomLoadingIndicator from custom_loading_indicator.dart instead. '
    'Import: package:rs_flutter/widgets/custom_loading_indicator.dart')
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
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeMd,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
