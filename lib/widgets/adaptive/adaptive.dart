/// Adaptive widgets that automatically adjust their appearance based on platform.
///
/// These widgets provide a consistent API while rendering platform-appropriate
/// UI components:
/// - On iOS: Uses Cupertino widgets (CupertinoButton, CupertinoSwitch, etc.)
/// - On Android/other: Uses Material widgets (ElevatedButton, Switch, etc.)
///
/// ## Usage
///
/// Import this file to access all adaptive widgets:
/// ```dart
/// import 'package:rs_flutter/widgets/adaptive/adaptive.dart';
/// ```
///
/// ## Available Widgets
///
/// ### Buttons
/// - [AdaptiveButton] - Primary, secondary, text, and destructive variants
/// - [AdaptivePrimaryButton] - Convenience wrapper for primary buttons
/// - [AdaptiveSecondaryButton] - Convenience wrapper for secondary buttons
/// - [AdaptiveTextButton] - Convenience wrapper for text buttons
///
/// ### Dialogs
/// - [showAdaptiveAlertDialog] - Confirmation dialogs
/// - [showAdaptiveInfoDialog] - Information dialogs
/// - [showAdaptiveDestructiveDialog] - Destructive action confirmation
/// - [showAdaptiveInputDialog] - Text input dialogs
/// - [showAdaptiveLoadingDialog] - Non-dismissible loading dialogs
///
/// ### Loading Indicators
/// - [AdaptiveLoadingIndicator] - Circular progress indicator
/// - [AdaptiveFullPageLoading] - Full-page loading state
/// - [AdaptiveInlineLoading] - Small inline loading indicator
/// - [AdaptiveLoadingButton] - Button with built-in loading state
/// - [AdaptiveRefreshIndicator] - Pull-to-refresh wrapper
///
/// ### Action Sheets
/// - [showAdaptiveActionSheet] - Bottom action sheet with options
/// - [showAdaptivePickerSheet] - Bottom picker sheet for selection
///
/// ### Form Controls
/// - [AdaptiveSwitch] - Toggle switch
/// - [AdaptiveSwitchListTile] - List tile with switch
/// - [AdaptiveSlider] - Slider control
/// - [AdaptiveSegmentedControl] - Segmented button/control
/// - [AdaptiveTextField] - Text input field
///
/// ## Example
///
/// ```dart
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         AdaptivePrimaryButton(
///           label: 'Submit',
///           onPressed: () async {
///             final confirmed = await showAdaptiveAlertDialog(
///               context: context,
///               title: 'Confirm',
///               content: 'Are you sure?',
///             );
///             if (confirmed == true) {
///               // Handle confirmation
///             }
///           },
///         ),
///         AdaptiveSwitchListTile(
///           title: 'Enable notifications',
///           value: _enabled,
///           onChanged: (v) => setState(() => _enabled = v),
///         ),
///       ],
///     );
///   }
/// }
/// ```
library;

export 'adaptive_button.dart';
export 'adaptive_dialog.dart';
export 'adaptive_loading.dart';
export 'adaptive_action_sheet.dart';
export 'adaptive_controls.dart';
