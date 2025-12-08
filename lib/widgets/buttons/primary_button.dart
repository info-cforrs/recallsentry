import 'package:flutter/material.dart';
import 'package:rs_flutter/constants/app_colors.dart';
import 'package:rs_flutter/constants/design_tokens.dart';

/// A standardized primary button widget for the app.
///
/// This button follows the app's design system with consistent styling,
/// sizing, and accessibility features. Use this for primary actions.
///
/// Example:
/// ```dart
/// PrimaryButton(
///   label: 'Save Changes',
///   onPressed: () => handleSave(),
///   icon: Icons.save,
/// )
/// ```
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
        height: height ?? DesignTokens.minTouchTarget,
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.accentBlue,
            foregroundColor: textColor ?? AppColors.textPrimary,
            elevation: DesignTokens.elevationNone,
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingXl,
                  vertical: DesignTokens.spacingMd,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
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
      height: DesignTokens.largeTouchTarget,
      isLoading: isLoading,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXxl,
        vertical: DesignTokens.spacingLg,
      ),
    );
  }
}

/// A small primary button for compact spaces.
class SmallPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const SmallPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
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

/// A danger/destructive button for actions like delete.
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;

  const DangerButton({
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
      isLoading: isLoading,
      backgroundColor: AppColors.error,
      textColor: AppColors.textPrimary,
    );
  }
}

/// A success button for positive actions.
class SuccessButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final bool isLoading;

  const SuccessButton({
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
      isLoading: isLoading,
      backgroundColor: AppColors.success,
      textColor: AppColors.textPrimary,
    );
  }
}
