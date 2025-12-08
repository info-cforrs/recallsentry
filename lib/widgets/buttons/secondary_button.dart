import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/constants/design_tokens.dart';

/// A standardized secondary button widget for the app.
///
/// This button follows the app's design system with outlined styling.
/// Use this for secondary actions or when you need less visual weight.
///
/// Example:
/// ```dart
/// SecondaryButton(
///   label: 'Cancel',
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
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
        height: height ?? DesignTokens.minTouchTarget,
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
                const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXl,
                  vertical: DesignTokens.spacingMd,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
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
                      Icon(icon, size: DesignTokens.iconSizeSm),
                      const SizedBox(width: DesignTokens.spacingSm),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeMd,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A small secondary button for compact spaces.
class SmallSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const SmallSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      fullWidth: false,
      height: DesignTokens.smallTouchTarget,
      isLoading: isLoading,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingSm,
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
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMd,
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
                    Icon(icon, size: DesignTokens.iconSizeSm),
                    const SizedBox(width: DesignTokens.spacingSm),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeMd,
                      fontWeight: DesignTokens.fontWeightSemiBold,
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
    this.size = DesignTokens.iconSizeMd,
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

/// A link-style button that looks like a text link.
class LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool underline;

  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.underline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Link: $label',
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: DesignTokens.borderRadiusXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXs,
            vertical: DesignTokens.spacingXs,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.accentBlue,
              fontSize: DesignTokens.fontSizeSm,
              fontWeight: DesignTokens.fontWeightMedium,
              decoration: underline ? TextDecoration.underline : null,
              decorationColor: color ?? AppColors.accentBlue,
            ),
          ),
        ),
      ),
    );
  }
}
