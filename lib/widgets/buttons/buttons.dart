/// Standardized button widgets for the RecallSentry app.
///
/// This library provides a consistent set of buttons that follow the app's
/// design system. All buttons include proper accessibility features.
///
/// ## Usage
///
/// ```dart
/// import 'package:rs_flutter/widgets/buttons/buttons.dart';
/// ```
///
/// ## Available Buttons
///
/// ### Primary Buttons (filled, high emphasis)
/// - [PrimaryButton] - Standard primary action button
/// - [LargePrimaryButton] - Large primary button (56px height)
/// - [SmallPrimaryButton] - Compact primary button (36px height)
/// - [DangerButton] - Red button for destructive actions
/// - [SuccessButton] - Green button for positive actions
///
/// ### Secondary Buttons (outlined, medium emphasis)
/// - [SecondaryButton] - Standard outlined button
/// - [SmallSecondaryButton] - Compact outlined button
///
/// ### Tertiary Buttons (text-only, low emphasis)
/// - [TertiaryButton] - Text button with minimal styling
/// - [LinkButton] - Link-style button
///
/// ### Icon Buttons
/// - [IconButtonWithTooltip] - Icon button with accessibility tooltip
///
/// ## Example
///
/// ```dart
/// Column(
///   children: [
///     PrimaryButton(
///       label: 'Save',
///       onPressed: () => save(),
///       icon: Icons.save,
///     ),
///     SizedBox(height: 16),
///     SecondaryButton(
///       label: 'Cancel',
///       onPressed: () => Navigator.pop(context),
///     ),
///     SizedBox(height: 16),
///     DangerButton(
///       label: 'Delete',
///       onPressed: () => delete(),
///       icon: Icons.delete,
///     ),
///   ],
/// )
/// ```
library;

export 'primary_button.dart';
export 'secondary_button.dart';
