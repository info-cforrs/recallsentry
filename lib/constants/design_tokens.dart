/// Centralized design tokens for consistent UI across the app.
///
/// These values should be used instead of hardcoded numbers to ensure
/// consistency and make global design changes easier.
library;

import 'package:flutter/material.dart';

/// Design tokens for spacing, sizing, and other UI constants.
class DesignTokens {
  // Private constructor to prevent instantiation
  DesignTokens._();

  // ==================== Spacing ====================

  /// Extra small spacing (4px) - use for tight internal padding
  static const double spacingXs = 4.0;

  /// Small spacing (8px) - use for related elements
  static const double spacingSm = 8.0;

  /// Medium spacing (12px) - use for form field gaps
  static const double spacingMd = 12.0;

  /// Large spacing (16px) - use for section padding
  static const double spacingLg = 16.0;

  /// Extra large spacing (24px) - use for major sections
  static const double spacingXl = 24.0;

  /// Double extra large spacing (32px) - use for page margins
  static const double spacingXxl = 32.0;

  /// Triple extra large spacing (48px) - use for major separations
  static const double spacingXxxl = 48.0;

  // ==================== Border Radius ====================

  /// Extra small radius (4px) - use for badges, chips
  static const double radiusXs = 4.0;

  /// Small radius (8px) - use for buttons, inputs, small cards
  static const double radiusSm = 8.0;

  /// Medium radius (12px) - use for cards, dialogs (default)
  static const double radiusMd = 12.0;

  /// Large radius (16px) - use for bottom sheets, large modals
  static const double radiusLg = 16.0;

  /// Extra large radius (24px) - use for full-screen overlays
  static const double radiusXl = 24.0;

  /// Full/circular radius
  static const double radiusFull = 999.0;

  // Pre-built BorderRadius objects for convenience
  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);

  // ==================== Touch Targets ====================

  /// Minimum touch target size (48px) - WCAG 2.1 compliant
  static const double minTouchTarget = 48.0;

  /// Large touch target size (56px) - for primary actions
  static const double largeTouchTarget = 56.0;

  /// Small touch target size (36px) - use sparingly, for compact UIs only
  static const double smallTouchTarget = 36.0;

  // ==================== Font Sizes ====================

  /// Minimum accessible font size (12px) - WCAG compliant minimum
  static const double fontSizeMin = 12.0;

  /// Extra small (12px) - use for labels, captions
  static const double fontSizeXs = 12.0;

  /// Small (14px) - use for secondary text, body small
  static const double fontSizeSm = 14.0;

  /// Medium (16px) - use for body text (default)
  static const double fontSizeMd = 16.0;

  /// Large (18px) - use for emphasized body, subtitles
  static const double fontSizeLg = 18.0;

  /// Extra large (20px) - use for section titles
  static const double fontSizeXl = 20.0;

  /// Double extra large (24px) - use for page titles
  static const double fontSizeXxl = 24.0;

  /// Display (28px) - use for hero text
  static const double fontSizeDisplay = 28.0;

  /// Large display (32px) - use for splash/intro screens
  static const double fontSizeDisplayLg = 32.0;

  // ==================== Font Weights ====================

  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ==================== Elevation ====================

  /// No elevation (0) - flat surfaces
  static const double elevationNone = 0.0;

  /// Low elevation (2) - cards, buttons
  static const double elevationLow = 2.0;

  /// Medium elevation (4) - FABs, raised cards
  static const double elevationMedium = 4.0;

  /// High elevation (8) - dialogs, bottom sheets
  static const double elevationHigh = 8.0;

  /// Highest elevation (16) - drawers, navigation
  static const double elevationHighest = 16.0;

  // ==================== Animation Durations ====================

  /// Fast animations (150ms) - micro-interactions
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Normal animations (300ms) - standard transitions
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Slow animations (500ms) - complex transitions
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Very slow animations (750ms) - emphasis animations
  static const Duration animationVerySlow = Duration(milliseconds: 750);

  // ==================== Icon Sizes ====================

  /// Extra small icon (12px) - inline with small text
  static const double iconSizeXs = 12.0;

  /// Small icon (16px) - inline icons
  static const double iconSizeSm = 16.0;

  /// Medium icon (24px) - standard icons (default)
  static const double iconSizeMd = 24.0;

  /// Large icon (32px) - emphasized icons
  static const double iconSizeLg = 32.0;

  /// Extra large icon (48px) - feature icons
  static const double iconSizeXl = 48.0;

  /// Huge icon (64px) - empty states, heroes
  static const double iconSizeXxl = 64.0;

  // ==================== Line Heights ====================

  /// Tight line height (1.2) - headings
  static const double lineHeightTight = 1.2;

  /// Normal line height (1.4) - body text
  static const double lineHeightNormal = 1.4;

  /// Relaxed line height (1.6) - readable paragraphs
  static const double lineHeightRelaxed = 1.6;

  // ==================== Opacity Values ====================

  /// Disabled state opacity
  static const double opacityDisabled = 0.5;

  /// Hover state opacity
  static const double opacityHover = 0.8;

  /// Overlay opacity (for scrims)
  static const double opacityOverlay = 0.5;

  /// Light overlay opacity
  static const double opacityOverlayLight = 0.3;

  // ==================== Breakpoints ====================

  /// Mobile breakpoint
  static const double breakpointMobile = 600.0;

  /// Tablet breakpoint
  static const double breakpointTablet = 900.0;

  /// Desktop breakpoint
  static const double breakpointDesktop = 1200.0;

  // ==================== Helper Methods ====================

  /// Get responsive spacing based on screen width
  static double responsiveSpacing(BuildContext context, {
    double mobile = spacingLg,
    double tablet = spacingXl,
    double desktop = spacingXxl,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= breakpointDesktop) return desktop;
    if (width >= breakpointTablet) return tablet;
    return mobile;
  }

  /// Get responsive font size based on screen width
  static double responsiveFontSize(BuildContext context, {
    double mobile = fontSizeMd,
    double tablet = fontSizeLg,
    double desktop = fontSizeXl,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= breakpointDesktop) return desktop;
    if (width >= breakpointTablet) return tablet;
    return mobile;
  }
}
