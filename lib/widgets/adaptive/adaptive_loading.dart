import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/design_tokens.dart';

/// A loading indicator that adapts to the current platform.
///
/// On iOS, displays a [CupertinoActivityIndicator].
/// On Android/other platforms, displays a [CircularProgressIndicator].
///
/// Example:
/// ```dart
/// AdaptiveLoadingIndicator(
///   size: AdaptiveLoadingSize.medium,
///   message: 'Loading...',
/// )
/// ```
class AdaptiveLoadingIndicator extends StatelessWidget {
  /// Size of the loading indicator
  final AdaptiveLoadingSize size;

  /// Optional message to display below the indicator
  final String? message;

  /// Custom color for the indicator
  final Color? color;

  /// Whether to center the indicator
  final bool centered;

  const AdaptiveLoadingIndicator({
    super.key,
    this.size = AdaptiveLoadingSize.medium,
    this.message,
    this.color,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = _buildIndicator();

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          const SizedBox(height: DesignTokens.spacingMd),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: DesignTokens.fontSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (centered) {
      content = Center(child: content);
    }

    return Semantics(
      label: message ?? 'Loading',
      child: content,
    );
  }

  Widget _buildIndicator() {
    final indicatorColor = color ?? AppColors.accentBlue;

    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        radius: _getCupertinoRadius(),
        color: indicatorColor,
      );
    }

    return SizedBox(
      width: _getMaterialSize(),
      height: _getMaterialSize(),
      child: CircularProgressIndicator(
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }

  double _getCupertinoRadius() {
    switch (size) {
      case AdaptiveLoadingSize.small:
        return 10.0;
      case AdaptiveLoadingSize.medium:
        return 14.0;
      case AdaptiveLoadingSize.large:
        return 18.0;
    }
  }

  double _getMaterialSize() {
    switch (size) {
      case AdaptiveLoadingSize.small:
        return 20.0;
      case AdaptiveLoadingSize.medium:
        return 36.0;
      case AdaptiveLoadingSize.large:
        return 48.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case AdaptiveLoadingSize.small:
        return 2.0;
      case AdaptiveLoadingSize.medium:
        return 3.0;
      case AdaptiveLoadingSize.large:
        return 4.0;
    }
  }
}

/// Size variants for the adaptive loading indicator
enum AdaptiveLoadingSize {
  /// Small (20px on Material, 10px radius on Cupertino)
  small,

  /// Medium (36px on Material, 14px radius on Cupertino) - default
  medium,

  /// Large (48px on Material, 18px radius on Cupertino)
  large,
}

/// A full-page loading indicator with platform-appropriate styling.
///
/// Example:
/// ```dart
/// AdaptiveFullPageLoading(
///   title: 'Loading Recalls',
///   message: 'Please wait...',
/// )
/// ```
class AdaptiveFullPageLoading extends StatelessWidget {
  /// Optional title for the app bar
  final String? title;

  /// Optional message to display
  final String? message;

  const AdaptiveFullPageLoading({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: title != null
            ? CupertinoNavigationBar(
                middle: Text(title!),
                backgroundColor: AppColors.primary,
              )
            : null,
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: AdaptiveLoadingIndicator(
            size: AdaptiveLoadingSize.large,
            message: message,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              backgroundColor: AppColors.primary,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: AdaptiveLoadingIndicator(
          size: AdaptiveLoadingSize.large,
          message: message,
        ),
      ),
    );
  }
}

/// An inline loading indicator for use within content.
///
/// Smaller and meant to be placed alongside other content.
///
/// Example:
/// ```dart
/// Row(
///   children: [
///     Text('Refreshing'),
///     SizedBox(width: 8),
///     AdaptiveInlineLoading(),
///   ],
/// )
/// ```
class AdaptiveInlineLoading extends StatelessWidget {
  /// Custom color for the indicator
  final Color? color;

  const AdaptiveInlineLoading({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLoadingIndicator(
      size: AdaptiveLoadingSize.small,
      color: color,
      centered: false,
    );
  }
}

/// A button with built-in loading state.
///
/// Automatically shows the appropriate loading indicator based on platform.
///
/// Example:
/// ```dart
/// AdaptiveLoadingButton(
///   label: 'Submit',
///   onPressed: handleSubmit,
///   isLoading: _isSubmitting,
/// )
/// ```
class AdaptiveLoadingButton extends StatelessWidget {
  /// Button label
  final String label;

  /// Callback when pressed (null if disabled or loading)
  final VoidCallback? onPressed;

  /// Whether to show loading state
  final bool isLoading;

  /// Whether the button should take full width
  final bool fullWidth;

  const AdaptiveLoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? _buildLoadingChild()
        : Text(
            label,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeMd,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          );

    if (Platform.isIOS) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: CupertinoButton.filled(
          onPressed: isLoading ? null : onPressed,
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: DesignTokens.minTouchTarget,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
          ),
        ),
        child: buttonChild,
      ),
    );
  }

  Widget _buildLoadingChild() {
    if (Platform.isIOS) {
      return const CupertinoActivityIndicator(
        color: AppColors.textPrimary,
      );
    }

    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
      ),
    );
  }
}

/// A refresh indicator that adapts to the platform.
///
/// On iOS, this would typically be used with [CupertinoSliverRefreshControl].
/// On Android, uses the standard [RefreshIndicator].
///
/// Example:
/// ```dart
/// AdaptiveRefreshIndicator(
///   onRefresh: () async => await refreshData(),
///   child: ListView(...),
/// )
/// ```
class AdaptiveRefreshIndicator extends StatelessWidget {
  /// Callback when refresh is triggered
  final Future<void> Function() onRefresh;

  /// The scrollable child
  final Widget child;

  /// Custom color for the indicator
  final Color? color;

  const AdaptiveRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.accentBlue;

    // Note: For iOS, consider using CustomScrollView with
    // CupertinoSliverRefreshControl for better native feel
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: indicatorColor,
      backgroundColor: Platform.isIOS ? null : AppColors.surface,
      child: child,
    );
  }
}
