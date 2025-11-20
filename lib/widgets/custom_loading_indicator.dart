import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// A standardized loading indicator widget for the app.
///
/// This widget provides a consistent loading experience across the app,
/// with optional message display and different size variants.
class CustomLoadingIndicator extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;

  /// Size of the loading indicator
  final LoadingIndicatorSize size;

  /// Color of the spinner
  final Color? color;

  /// Whether to show on a full page with scaffold
  final bool fullPage;

  const CustomLoadingIndicator({
    super.key,
    this.message,
    this.size = LoadingIndicatorSize.medium,
    this.color,
    this.fullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (fullPage) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: content,
      );
    }

    return content;
  }

  Widget _buildContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: message ?? 'Loading',
              child: SizedBox(
                width: _getSize(),
                height: _getSize(),
                child: CircularProgressIndicator(
                  strokeWidth: _getStrokeWidth(),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? AppColors.accentBlue,
                  ),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case LoadingIndicatorSize.small:
        return 20.0;
      case LoadingIndicatorSize.medium:
        return 40.0;
      case LoadingIndicatorSize.large:
        return 60.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingIndicatorSize.small:
        return 2.0;
      case LoadingIndicatorSize.medium:
        return 3.0;
      case LoadingIndicatorSize.large:
        return 4.0;
    }
  }
}

/// Size variants for the loading indicator
enum LoadingIndicatorSize {
  small,
  medium,
  large,
}

/// A full-page loading indicator with AppBar
class FullPageLoadingIndicator extends StatelessWidget {
  final String? title;
  final String? message;

  const FullPageLoadingIndicator({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              backgroundColor: AppColors.primary,
              elevation: 0,
            )
          : null,
      body: CustomLoadingIndicator(
        message: message,
        size: LoadingIndicatorSize.large,
      ),
    );
  }
}

/// An inline loading indicator for use within content
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;
  final LoadingIndicatorSize size;

  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size = LoadingIndicatorSize.small,
  });

  @override
  Widget build(BuildContext context) {
    return CustomLoadingIndicator(
      message: message,
      size: size,
      fullPage: false,
    );
  }
}

/// A linear progress indicator with consistent styling
class CustomLinearProgressIndicator extends StatelessWidget {
  /// Optional message to display above the progress bar
  final String? message;

  /// Optional progress value (0.0 to 1.0)
  /// If null, shows an indeterminate progress indicator
  final double? value;

  /// Color of the progress bar
  final Color? color;

  const CustomLinearProgressIndicator({
    super.key,
    this.message,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Semantics(
            label: message ?? 'Loading progress',
            child: LinearProgressIndicator(
              value: value,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.accentBlue,
              ),
              backgroundColor: AppColors.surface,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmer loading effect for content placeholders
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor ?? AppColors.surface,
                widget.highlightColor ?? AppColors.textDisabled,
                widget.baseColor ?? AppColors.surface,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A placeholder card with shimmer effect for loading states
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
