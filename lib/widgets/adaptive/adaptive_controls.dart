import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/design_tokens.dart';

/// A switch that adapts to the current platform.
///
/// On iOS, displays a [CupertinoSwitch].
/// On Android/other platforms, displays a Material [Switch].
///
/// Example:
/// ```dart
/// AdaptiveSwitch(
///   value: _notificationsEnabled,
///   onChanged: (value) => setState(() => _notificationsEnabled = value),
/// )
/// ```
class AdaptiveSwitch extends StatelessWidget {
  /// Whether the switch is on
  final bool value;

  /// Callback when the switch is toggled
  final ValueChanged<bool>? onChanged;

  /// Active color (when switch is on)
  final Color? activeColor;

  /// Semantic label for accessibility
  final String? semanticsLabel;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accentBlue;

    Widget switchWidget;

    if (Platform.isIOS) {
      switchWidget = CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: color,
      );
    } else {
      switchWidget = Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        activeTrackColor: color.withValues(alpha: 0.5),
      );
    }

    if (semanticsLabel != null) {
      return Semantics(
        label: semanticsLabel,
        toggled: value,
        child: switchWidget,
      );
    }

    return switchWidget;
  }
}

/// A list tile with a switch that adapts to the platform.
///
/// Example:
/// ```dart
/// AdaptiveSwitchListTile(
///   title: 'Enable Notifications',
///   subtitle: 'Receive alerts for new recalls',
///   value: _notificationsEnabled,
///   onChanged: (value) => setState(() => _notificationsEnabled = value),
/// )
/// ```
class AdaptiveSwitchListTile extends StatelessWidget {
  /// Title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Whether the switch is on
  final bool value;

  /// Callback when the switch is toggled
  final ValueChanged<bool>? onChanged;

  /// Optional leading icon
  final IconData? icon;

  /// Active color for the switch
  final Color? activeColor;

  const AdaptiveSwitchListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
          vertical: DesignTokens.spacingSm,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: DesignTokens.spacingMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: DesignTokens.fontSizeMd,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                    ),
                ],
              ),
            ),
            AdaptiveSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: activeColor,
              semanticsLabel: title,
            ),
          ],
        ),
      );
    }

    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textSecondary),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor ?? AppColors.accentBlue,
      activeTrackColor: (activeColor ?? AppColors.accentBlue).withValues(alpha: 0.5),
      secondary: icon != null
          ? Icon(icon, color: AppColors.textSecondary)
          : null,
    );
  }
}

/// A slider that adapts to the current platform.
///
/// On iOS, displays a [CupertinoSlider].
/// On Android/other platforms, displays a Material [Slider].
///
/// Example:
/// ```dart
/// AdaptiveSlider(
///   value: _volume,
///   min: 0,
///   max: 100,
///   onChanged: (value) => setState(() => _volume = value),
/// )
/// ```
class AdaptiveSlider extends StatelessWidget {
  /// Current value
  final double value;

  /// Minimum value
  final double min;

  /// Maximum value
  final double max;

  /// Number of divisions (for discrete values)
  final int? divisions;

  /// Callback when the slider value changes
  final ValueChanged<double>? onChanged;

  /// Active color
  final Color? activeColor;

  /// Semantic label for accessibility
  final String? semanticsLabel;

  const AdaptiveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    required this.onChanged,
    this.activeColor,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.accentBlue;

    Widget sliderWidget;

    if (Platform.isIOS) {
      sliderWidget = CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        activeColor: color,
      );
    } else {
      sliderWidget = Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        activeColor: color,
        inactiveColor: color.withValues(alpha: 0.3),
      );
    }

    if (semanticsLabel != null) {
      return Semantics(
        label: semanticsLabel,
        value: '${(value * 100 / max).round()}%',
        child: sliderWidget,
      );
    }

    return sliderWidget;
  }
}

/// A segmented control that adapts to the current platform.
///
/// On iOS, displays a [CupertinoSlidingSegmentedControl].
/// On Android/other platforms, displays a [SegmentedButton].
///
/// Example:
/// ```dart
/// AdaptiveSegmentedControl<String>(
///   segments: {
///     'all': 'All',
///     'active': 'Active',
///     'completed': 'Completed',
///   },
///   selected: _selectedFilter,
///   onChanged: (value) => setState(() => _selectedFilter = value),
/// )
/// ```
class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  /// Map of value to display label
  final Map<T, String> segments;

  /// Currently selected value
  final T selected;

  /// Callback when selection changes
  final ValueChanged<T> onChanged;

  /// Background color
  final Color? backgroundColor;

  /// Selected segment color
  final Color? selectedColor;

  const AdaptiveSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: selected,
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
        backgroundColor:
            backgroundColor ?? CupertinoColors.systemGrey5.resolveFrom(context),
        thumbColor: selectedColor ?? CupertinoColors.white,
        children: segments.map(
          (key, value) => MapEntry(
            key,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              child: Text(value),
            ),
          ),
        ),
      );
    }

    return SegmentedButton<T>(
      segments: segments.entries
          .map(
            (entry) => ButtonSegment<T>(
              value: entry.key,
              label: Text(entry.value),
            ),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (selection) {
        if (selection.isNotEmpty) onChanged(selection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return selectedColor ?? AppColors.accentBlue;
          }
          return backgroundColor ?? AppColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.textPrimary;
          }
          return AppColors.textSecondary;
        }),
      ),
    );
  }
}

/// A text field that adapts to the current platform.
///
/// On iOS, displays a [CupertinoTextField].
/// On Android/other platforms, displays a Material [TextField].
///
/// Example:
/// ```dart
/// AdaptiveTextField(
///   controller: _nameController,
///   placeholder: 'Enter your name',
///   prefixIcon: Icons.person,
/// )
/// ```
class AdaptiveTextField extends StatelessWidget {
  /// Text editing controller
  final TextEditingController? controller;

  /// Placeholder text
  final String? placeholder;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon callback
  final VoidCallback? onSuffixTap;

  /// Keyboard type
  final TextInputType keyboardType;

  /// Whether text is obscured (for passwords)
  final bool obscureText;

  /// Whether the field is enabled
  final bool enabled;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when editing is complete
  final VoidCallback? onEditingComplete;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Maximum lines
  final int maxLines;

  /// Minimum lines
  final int? minLines;

  /// Maximum length
  final int? maxLength;

  /// Autofocus
  final bool autofocus;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: DesignTokens.spacingMd),
                child: Icon(
                  prefixIcon,
                  color: CupertinoColors.placeholderText,
                  size: DesignTokens.iconSizeMd,
                ),
              )
            : null,
        suffix: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
                  child: Icon(
                    suffixIcon,
                    color: CupertinoColors.placeholderText,
                    size: DesignTokens.iconSizeMd,
                  ),
                ),
              )
            : null,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
        textInputAction: textInputAction,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        autofocus: autofocus,
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.formFieldFill,
          borderRadius: DesignTokens.borderRadiusSm,
          border: Border.all(color: AppColors.border),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
        placeholderStyle: const TextStyle(color: AppColors.textTertiary),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autofocus: autofocus,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSecondary)
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(suffixIcon, color: AppColors.textSecondary),
                onPressed: onSuffixTap,
              )
            : null,
        filled: true,
        fillColor: AppColors.formFieldFill,
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusSm,
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusSm,
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
