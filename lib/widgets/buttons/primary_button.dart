import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// A standardized primary button widget for the app.
///
/// This button follows the app's design system with consistent styling,
/// sizing, and accessibility features. Use this for primary actions.
class PrimaryButton extends StatelessWidget {
  /// The text label for the button
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Whether the button should take full width
  final bool fullWidth;

  /// Optional custom height (default: 48)
  final double? height;

  /// Optional custom background color
  final Color? backgroundColor;

  /// Optional custom text color
  final Color? textColor;

  /// Whether to show a loading indicator
  final bool isLoading;

  /// Custom padding
  final EdgeInsets? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Semantics(
      label: 'Primary button: $label',
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        height: height ?? 48,
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.accentBlue,
            foregroundColor: textColor ?? AppColors.textPrimary,
            elevation: 0,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.textDisabled,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return widget;
  }
}

/// A standardized large primary button for important actions.
class LargePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;

  const LargePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      fullWidth: fullWidth,
      height: 56,
      isLoading: isLoading,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    );
  }
}
