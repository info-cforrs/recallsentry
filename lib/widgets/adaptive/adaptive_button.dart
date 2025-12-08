import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/design_tokens.dart';

/// A button that adapts its appearance to the current platform.
///
/// On iOS, uses [CupertinoButton] with iOS-native styling.
/// On Android/other platforms, uses Material [ElevatedButton] or [TextButton].
///
/// Example:
/// ```dart
/// AdaptiveButton(
///   label: 'Submit',
///   onPressed: () => handleSubmit(),
///   variant: AdaptiveButtonVariant.primary,
/// )
/// ```
class AdaptiveButton extends StatelessWidget {
  /// The button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button style variant
  final AdaptiveButtonVariant variant;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Whether the button is in a loading state
  final bool isLoading;

  /// Whether the button should take full width
  final bool fullWidth;

  /// Custom background color (overrides variant)
  final Color? backgroundColor;

  /// Custom text color (overrides variant)
  final Color? textColor;

  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AdaptiveButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      return _buildCupertinoButton(context);
    }

    return _buildMaterialButton(context);
  }

  Widget _buildCupertinoButton(BuildContext context) {
    final Color bgColor = backgroundColor ?? _getBackgroundColor();
    final Color fgColor = textColor ?? _getForegroundColor();

    Widget buttonChild = isLoading
        ? CupertinoActivityIndicator(color: fgColor)
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: DesignTokens.iconSizeSm, color: fgColor),
                const SizedBox(width: DesignTokens.spacingSm),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: DesignTokens.fontSizeMd,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          );

    Widget button;

    switch (variant) {
      case AdaptiveButtonVariant.primary:
        button = CupertinoButton.filled(
          onPressed: isLoading ? null : onPressed,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl,
            vertical: DesignTokens.spacingMd,
          ),
          child: buttonChild,
        );
        // Override default filled color
        button = CupertinoTheme(
          data: CupertinoThemeData(primaryColor: bgColor),
          child: button,
        );
        break;

      case AdaptiveButtonVariant.secondary:
        button = Container(
          decoration: BoxDecoration(
            border: Border.all(color: bgColor, width: 1.5),
            borderRadius: DesignTokens.borderRadiusSm,
          ),
          child: CupertinoButton(
            onPressed: isLoading ? null : onPressed,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXl,
              vertical: DesignTokens.spacingMd,
            ),
            child: buttonChild,
          ),
        );
        break;

      case AdaptiveButtonVariant.text:
        button = CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingSm,
          ),
          child: buttonChild,
        );
        break;

      case AdaptiveButtonVariant.destructive:
        button = CupertinoButton(
          onPressed: isLoading ? null : onPressed,
          color: AppColors.error,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl,
            vertical: DesignTokens.spacingMd,
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: DesignTokens.minTouchTarget,
        child: button,
      );
    }

    return button;
  }

  Widget _buildMaterialButton(BuildContext context) {
    final Color bgColor = backgroundColor ?? _getBackgroundColor();
    final Color fgColor = textColor ?? _getForegroundColor();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
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
          );

    Widget button;

    switch (variant) {
      case AdaptiveButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: DesignTokens.elevationNone,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXl,
              vertical: DesignTokens.spacingMd,
            ),
            minimumSize: Size(0, DesignTokens.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.textDisabled,
          ),
          child: buttonChild,
        );
        break;

      case AdaptiveButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor, width: 1.5),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXl,
              vertical: DesignTokens.spacingMd,
            ),
            minimumSize: Size(0, DesignTokens.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
            ),
          ),
          child: buttonChild,
        );
        break;

      case AdaptiveButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: bgColor,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingSm,
            ),
            minimumSize: Size(0, DesignTokens.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
            ),
          ),
          child: buttonChild,
        );
        break;

      case AdaptiveButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textPrimary,
            elevation: DesignTokens.elevationNone,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXl,
              vertical: DesignTokens.spacingMd,
            ),
            minimumSize: Size(0, DesignTokens.minTouchTarget),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusMd,
            ),
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AdaptiveButtonVariant.primary:
        return AppColors.accentBlue;
      case AdaptiveButtonVariant.secondary:
        return AppColors.accentBlue;
      case AdaptiveButtonVariant.text:
        return AppColors.accentBlue;
      case AdaptiveButtonVariant.destructive:
        return AppColors.error;
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case AdaptiveButtonVariant.primary:
        return AppColors.textPrimary;
      case AdaptiveButtonVariant.secondary:
        return AppColors.accentBlue;
      case AdaptiveButtonVariant.text:
        return AppColors.accentBlue;
      case AdaptiveButtonVariant.destructive:
        return AppColors.textPrimary;
    }
  }
}

/// Button style variants
enum AdaptiveButtonVariant {
  /// Filled button for primary actions
  primary,

  /// Outlined button for secondary actions
  secondary,

  /// Text-only button for tertiary actions
  text,

  /// Red filled button for destructive actions
  destructive,
}

/// Convenience widget for primary adaptive buttons
class AdaptivePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AdaptivePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveButton(
      label: label,
      onPressed: onPressed,
      variant: AdaptiveButtonVariant.primary,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }
}

/// Convenience widget for secondary adaptive buttons
class AdaptiveSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AdaptiveSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveButton(
      label: label,
      onPressed: onPressed,
      variant: AdaptiveButtonVariant.secondary,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }
}

/// Convenience widget for text adaptive buttons
class AdaptiveTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const AdaptiveTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveButton(
      label: label,
      onPressed: onPressed,
      variant: AdaptiveButtonVariant.text,
      icon: icon,
      isLoading: isLoading,
      fullWidth: false,
    );
  }
}
