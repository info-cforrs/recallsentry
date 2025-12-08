import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/design_tokens.dart';

/// Shows a platform-appropriate alert dialog.
///
/// On iOS, displays a [CupertinoAlertDialog].
/// On Android/other platforms, displays a Material [AlertDialog].
///
/// Returns `true` if the user confirmed, `false` if cancelled, or `null` if dismissed.
///
/// Example:
/// ```dart
/// final confirmed = await showAdaptiveAlertDialog(
///   context: context,
///   title: 'Delete Item',
///   content: 'Are you sure you want to delete this item?',
///   confirmText: 'Delete',
///   isDestructive: true,
/// );
///
/// if (confirmed == true) {
///   // Handle deletion
/// }
/// ```
Future<bool?> showAdaptiveAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'OK',
  String? cancelText = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) {
  if (Platform.isIOS) {
    return showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
          child: Text(content),
        ),
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          CupertinoDialogAction(
            isDestructiveAction: isDestructive,
            isDefaultAction: !isDestructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusMd,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: DesignTokens.fontSizeMd,
        ),
      ),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(foregroundColor: AppColors.error)
              : null,
          child: Text(
            confirmText,
            style: TextStyle(
              color: isDestructive ? AppColors.error : AppColors.accentBlue,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Shows a platform-appropriate info dialog with only an OK button.
///
/// Example:
/// ```dart
/// await showAdaptiveInfoDialog(
///   context: context,
///   title: 'Success',
///   content: 'Your changes have been saved.',
/// );
/// ```
Future<void> showAdaptiveInfoDialog({
  required BuildContext context,
  required String title,
  required String content,
  String buttonText = 'OK',
}) {
  return showAdaptiveAlertDialog(
    context: context,
    title: title,
    content: content,
    confirmText: buttonText,
    cancelText: null,
    barrierDismissible: true,
  );
}

/// Shows a platform-appropriate confirmation dialog for destructive actions.
///
/// Example:
/// ```dart
/// final confirmed = await showAdaptiveDestructiveDialog(
///   context: context,
///   title: 'Delete Account',
///   content: 'This action cannot be undone.',
///   confirmText: 'Delete Account',
/// );
/// ```
Future<bool?> showAdaptiveDestructiveDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
}) {
  return showAdaptiveAlertDialog(
    context: context,
    title: title,
    content: content,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: true,
    barrierDismissible: false,
  );
}

/// Shows a platform-appropriate input dialog with a text field.
///
/// Returns the entered text if confirmed, or `null` if cancelled.
///
/// Example:
/// ```dart
/// final name = await showAdaptiveInputDialog(
///   context: context,
///   title: 'Rename Item',
///   hintText: 'Enter new name',
///   initialValue: 'Current Name',
/// );
///
/// if (name != null) {
///   // Handle rename
/// }
/// ```
Future<String?> showAdaptiveInputDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? hintText,
  String? initialValue,
  String confirmText = 'OK',
  String cancelText = 'Cancel',
  TextInputType keyboardType = TextInputType.text,
  int? maxLength,
  bool obscureText = false,
}) async {
  final controller = TextEditingController(text: initialValue);

  if (Platform.isIOS) {
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            if (message != null) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              Text(message),
            ],
            const SizedBox(height: DesignTokens.spacingMd),
            CupertinoTextField(
              controller: controller,
              placeholder: hintText,
              keyboardType: keyboardType,
              maxLength: maxLength,
              obscureText: obscureText,
              autofocus: true,
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusMd,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: DesignTokens.fontSizeXl,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: DesignTokens.fontSizeMd,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMd),
          ],
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            obscureText: obscureText,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.textTertiary),
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
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            cancelText,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(
            confirmText,
            style: const TextStyle(
              color: AppColors.accentBlue,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Shows a platform-appropriate loading dialog that cannot be dismissed.
///
/// Returns a function to close the dialog.
///
/// Example:
/// ```dart
/// final closeDialog = showAdaptiveLoadingDialog(
///   context: context,
///   message: 'Saving...',
/// );
///
/// try {
///   await saveData();
/// } finally {
///   closeDialog();
/// }
/// ```
VoidCallback showAdaptiveLoadingDialog({
  required BuildContext context,
  String? message,
}) {
  if (Platform.isIOS) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingXl),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 14),
                if (message != null) ...[
                  const SizedBox(height: DesignTokens.spacingMd),
                  Text(
                    message,
                    style: const TextStyle(fontSize: DesignTokens.fontSizeSm),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingXl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
                if (message != null) ...[
                  const SizedBox(height: DesignTokens.spacingMd),
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  return () {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  };
}
