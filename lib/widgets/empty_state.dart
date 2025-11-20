import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// A reusable empty state widget that displays when there's no content to show.
///
/// This widget provides a consistent UX across the app for empty states,
/// with optional icon, title, subtitle, and call-to-action button.
class EmptyState extends StatelessWidget {
  /// The icon to display
  final IconData? icon;

  /// The main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional call-to-action button label
  final String? actionLabel;

  /// Optional callback when action button is pressed
  final VoidCallback? onActionPressed;

  /// Icon size (default: 64)
  final double iconSize;

  /// Icon color (default: AppColors.textTertiary)
  final Color iconColor;

  /// Title text style override
  final TextStyle? titleStyle;

  /// Subtitle text style override
  final TextStyle? subtitleStyle;

  /// Custom widget to display instead of icon
  final Widget? customIcon;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
    this.iconSize = 64,
    this.iconColor = AppColors.textTertiary,
    this.titleStyle,
    this.subtitleStyle,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon or custom widget
            if (customIcon != null)
              customIcon!
            else if (icon != null)
              Semantics(
                label: 'Empty state icon',
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              ),

            const SizedBox(height: 24),

            // Title
            Semantics(
              label: 'Empty state message',
              child: Text(
                title,
                style: titleStyle ??
                    const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Empty state description',
                child: Text(
                  subtitle!,
                  style: subtitleStyle ??
                      const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Action button
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 32),
              Semantics(
                label: 'Empty state action button: $actionLabel',
                button: true,
                enabled: true,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty state for no recalls found
class NoRecallsEmptyState extends StatelessWidget {
  final VoidCallback? onBrowsePressed;

  const NoRecallsEmptyState({
    super.key,
    this.onBrowsePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No recalls found',
      subtitle: 'There are no recalls matching your current filters.',
      actionLabel: onBrowsePressed != null ? 'Browse All Recalls' : null,
      onActionPressed: onBrowsePressed,
    );
  }
}

/// Pre-configured empty state for saved recalls
class NoSavedRecallsEmptyState extends StatelessWidget {
  final VoidCallback? onBrowsePressed;

  const NoSavedRecallsEmptyState({
    super.key,
    this.onBrowsePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.bookmark_border,
      title: 'No saved recalls',
      subtitle: 'Save recalls to quickly access them later.',
      actionLabel: onBrowsePressed != null ? 'Browse Recalls' : null,
      onActionPressed: onBrowsePressed,
    );
  }
}

/// Pre-configured empty state for search results
class NoSearchResultsEmptyState extends StatelessWidget {
  final String? searchQuery;

  const NoSearchResultsEmptyState({
    super.key,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: searchQuery != null
          ? 'No recalls match "$searchQuery". Try different keywords.'
          : 'No recalls match your search. Try different keywords.',
    );
  }
}

/// Pre-configured empty state for filtered results
class NoFilteredResultsEmptyState extends StatelessWidget {
  final VoidCallback? onClearFiltersPressed;

  const NoFilteredResultsEmptyState({
    super.key,
    this.onClearFiltersPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.filter_alt_off,
      title: 'No filtered recalls',
      subtitle: 'No recalls match your current SmartFilter settings.',
      actionLabel: onClearFiltersPressed != null ? 'Clear Filters' : null,
      onActionPressed: onClearFiltersPressed,
    );
  }
}

/// Pre-configured empty state for premium features
class PremiumRequiredEmptyState extends StatelessWidget {
  final String featureName;
  final VoidCallback? onUpgradePressed;

  const PremiumRequiredEmptyState({
    super.key,
    required this.featureName,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.lock_outline,
      iconColor: AppColors.premium,
      title: 'Premium Feature',
      subtitle: '$featureName is available with RecallSentry Pro.',
      actionLabel: onUpgradePressed != null ? 'Upgrade to Pro' : null,
      onActionPressed: onUpgradePressed,
    );
  }
}

/// Pre-configured empty state for network errors
class NetworkErrorEmptyState extends StatelessWidget {
  final VoidCallback? onRetryPressed;

  const NetworkErrorEmptyState({
    super.key,
    this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Connection Error',
      subtitle: 'Unable to load data. Check your internet connection.',
      actionLabel: onRetryPressed != null ? 'Retry' : null,
      onActionPressed: onRetryPressed,
    );
  }
}

/// Pre-configured empty state for errors
class ErrorEmptyState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetryPressed;

  const ErrorEmptyState({
    super.key,
    this.errorMessage,
    this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      iconColor: AppColors.error,
      title: 'Something went wrong',
      subtitle: errorMessage ?? 'An error occurred. Please try again.',
      actionLabel: onRetryPressed != null ? 'Retry' : null,
      onActionPressed: onRetryPressed,
    );
  }
}
