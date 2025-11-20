import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';

/// A standardized secondary button widget for the app.
///
/// This button follows the app's design system with outlined styling.
/// Use this for secondary actions or when you need less visual weight.
class SecondaryButton extends StatelessWidget {
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

  /// Optional custom border color
  final Color? borderColor;

  /// Optional custom text color
  final Color? textColor;

  /// Whether to show a loading indicator
  final bool isLoading;

  /// Custom padding
  final EdgeInsets? padding;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height,
    this.borderColor,
    this.textColor,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Secondary button: $label',
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        height: height ?? 48,
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.accentBlue,
            side: BorderSide(
              color: borderColor ?? AppColors.accentBlue,
              width: 1.5,
            ),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledForegroundColor: AppColors.textDisabled,
          ).copyWith(
            side: WidgetStateProperty.resolveWith<BorderSide>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.disabled)) {
                  return const BorderSide(
                    color: AppColors.textDisabled,
                    width: 1.5,
                  );
                }
                return BorderSide(
                  color: borderColor ?? AppColors.accentBlue,
                  width: 1.5,
                );
              },
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? AppColors.accentBlue,
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
  }
}

/// A text button for minimal visual weight actions
class TertiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? textColor;
  final bool isLoading;

  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Text button: $label',
      button: true,
      enabled: onPressed != null && !isLoading,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? AppColors.accentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.accentBlue,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
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
    );
  }
}

/// An icon button with tooltip for accessibility
class IconButtonWithTooltip extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double size;

  const IconButtonWithTooltip({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon, size: size),
        onPressed: onPressed,
        color: color ?? AppColors.textPrimary,
        tooltip: tooltip,
      ),
    );
  }
}
