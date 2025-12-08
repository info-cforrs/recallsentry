import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/design_tokens.dart';

/// Represents an action in an action sheet.
class AdaptiveSheetAction {
  /// The action label
  final String label;

  /// Optional icon for the action
  final IconData? icon;

  /// Callback when the action is selected
  final VoidCallback onPressed;

  /// Whether this is a destructive action (shown in red)
  final bool isDestructive;

  /// Whether this is the default action (bold on iOS)
  final bool isDefault;

  const AdaptiveSheetAction({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// Shows a platform-appropriate action sheet.
///
/// On iOS, displays a [CupertinoActionSheet].
/// On Android/other platforms, displays a [BottomSheet].
///
/// Example:
/// ```dart
/// await showAdaptiveActionSheet(
///   context: context,
///   title: 'Share Options',
///   message: 'Choose how to share this recall',
///   actions: [
///     AdaptiveSheetAction(
///       label: 'Share via Email',
///       icon: Icons.email,
///       onPressed: () => shareViaEmail(),
///     ),
///     AdaptiveSheetAction(
///       label: 'Copy Link',
///       icon: Icons.link,
///       onPressed: () => copyLink(),
///     ),
///     AdaptiveSheetAction(
///       label: 'Delete',
///       icon: Icons.delete,
///       onPressed: () => delete(),
///       isDestructive: true,
///     ),
///   ],
/// );
/// ```
Future<void> showAdaptiveActionSheet({
  required BuildContext context,
  String? title,
  String? message,
  required List<AdaptiveSheetAction> actions,
  String cancelText = 'Cancel',
}) async {
  if (Platform.isIOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        message: message != null ? Text(message) : null,
        actions: actions.map((action) {
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              action.onPressed();
            },
            isDestructiveAction: action.isDestructive,
            isDefaultAction: action.isDefault,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(
                    action.icon,
                    color: action.isDestructive
                        ? CupertinoColors.destructiveRed
                        : CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                ],
                Text(action.label),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText),
        ),
      ),
    );
    return;
  }

  // Material design bottom sheet
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLg),
      ),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              borderRadius: DesignTokens.borderRadiusFull,
            ),
          ),

          // Title and message
          if (title != null || message != null)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              child: Column(
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: DesignTokens.fontSizeLg,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  if (message != null) ...[
                    const SizedBox(height: DesignTokens.spacingSm),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: DesignTokens.fontSizeSm,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Actions
          ...actions.map((action) => ListTile(
                leading: action.icon != null
                    ? Icon(
                        action.icon,
                        color: action.isDestructive
                            ? AppColors.error
                            : AppColors.accentBlue,
                      )
                    : null,
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive
                        ? AppColors.error
                        : AppColors.textPrimary,
                    fontWeight: action.isDefault
                        ? DesignTokens.fontWeightSemiBold
                        : DesignTokens.fontWeightRegular,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  action.onPressed();
                },
              )),

          const Divider(height: 1, color: AppColors.divider),

          // Cancel button
          ListTile(
            title: Text(
              cancelText,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            onTap: () => Navigator.of(context).pop(),
          ),

          const SizedBox(height: DesignTokens.spacingSm),
        ],
      ),
    ),
  );
}

/// Shows a platform-appropriate picker sheet for selecting from options.
///
/// Returns the selected value or null if cancelled.
///
/// Example:
/// ```dart
/// final selected = await showAdaptivePickerSheet<String>(
///   context: context,
///   title: 'Select Category',
///   options: [
///     PickerOption(value: 'fda', label: 'FDA Recalls'),
///     PickerOption(value: 'usda', label: 'USDA Recalls'),
///     PickerOption(value: 'nhtsa', label: 'Vehicle Recalls'),
///   ],
///   selectedValue: 'fda',
/// );
/// ```
Future<T?> showAdaptivePickerSheet<T>({
  required BuildContext context,
  String? title,
  required List<PickerOption<T>> options,
  T? selectedValue,
  String cancelText = 'Cancel',
  String confirmText = 'Done',
}) async {
  if (Platform.isIOS) {
    int selectedIndex = options.indexWhere((o) => o.value == selectedValue);
    if (selectedIndex < 0) selectedIndex = 0;

    T? result;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // Header with cancel/done buttons
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingLg,
              ),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: const Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelText),
                  ),
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  CupertinoButton(
                    onPressed: () {
                      result = options[selectedIndex].value;
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Picker wheel
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: options
                    .map((o) => Center(child: Text(o.label)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  // Material design bottom sheet with list
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLg),
      ),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              borderRadius: DesignTokens.borderRadiusFull,
            ),
          ),

          // Title
          if (title != null)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: DesignTokens.fontSizeLg,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Options
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  final isSelected = option.value == selectedValue;
                  return ListTile(
                    leading: isSelected
                        ? const Icon(Icons.check, color: AppColors.accentBlue)
                        : const SizedBox(width: 24),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accentBlue
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? DesignTokens.fontWeightSemiBold
                            : DesignTokens.fontWeightRegular,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(option.value),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: DesignTokens.spacingSm),
        ],
      ),
    ),
  );
}

/// Represents an option in a picker sheet.
class PickerOption<T> {
  /// The value returned when this option is selected
  final T value;

  /// The display label
  final String label;

  /// Optional icon
  final IconData? icon;

  const PickerOption({
    required this.value,
    required this.label,
    this.icon,
  });
}
