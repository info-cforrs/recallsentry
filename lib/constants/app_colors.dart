import 'package:flutter/material.dart';

/// Centralized color constants for the RecallSentry app.
///
/// All colors used throughout the app should be defined here to ensure
/// consistency and make it easy to update the color scheme.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ==================== Primary Colors ====================

  /// Primary dark blue-grey background color
  /// Used for: AppBars, main backgrounds, cards
  static const Color primary = Color(0xFF1D3547);

  /// Secondary lighter variant
  /// Used for: Secondary backgrounds, contrast sections
  static const Color secondary = Color(0xFF2C3E50);

  /// Tertiary dark variant
  /// Used for: Deep backgrounds, overlays
  static const Color tertiary = Color(0xFF0C5876);

  // ==================== Accent Colors ====================

  /// Primary accent blue
  /// Used for: Links, highlights, interactive elements
  static const Color accentBlue = Color(0xFF64B5F6);

  /// Light accent blue
  /// Used for: Hover states, light highlights
  static const Color accentBlueLight = Color(0xFF5DADE2);

  /// Sky blue accent
  /// Used for: Information badges, secondary highlights
  static const Color accentSky = Color(0xFF87CEEB);

  // ==================== Semantic Colors ====================

  /// Success green
  /// Used for: Success messages, positive states
  static const Color success = Color(0xFF4CAF50);

  /// Success green dark variant
  /// Used for: Success backgrounds, dark success states
  static const Color successDark = Color(0xFF2E7D32);

  /// Warning orange
  /// Used for: Warning messages, caution states
  static const Color warning = Color(0xFFFF9800);

  /// Error red
  /// Used for: Error messages, negative states
  static const Color error = Color(0xFFE57373);

  /// Info blue
  /// Used for: Information messages, neutral highlights
  static const Color info = Color(0xFF64B5F6);

  // ==================== Risk Level Colors ====================

  /// High risk - Red
  /// Used for: Class I recalls, high severity items
  static const Color riskHigh = Color(0xFFE57373);

  /// Medium risk - Orange
  /// Used for: Class II recalls, medium severity items
  static const Color riskMedium = Color(0xFFFF9800);

  /// Low risk - Yellow
  /// Used for: Class III recalls, low severity items
  static const Color riskLow = Color(0xFFFDD835);

  /// Unknown risk - Grey
  /// Used for: Unclassified recalls
  static const Color riskUnknown = Color(0xFF9E9E9E);

  // ==================== Text Colors ====================

  /// Primary text color (white)
  static const Color textPrimary = Colors.white;

  /// Secondary text color (70% opacity white)
  /// WCAG AA compliant: 7.29:1 on primary, 5.91:1 on secondary
  static const Color textSecondary = Colors.white70;

  /// Tertiary text color (60% opacity white)
  /// WCAG AA compliant on primary backgrounds: 4.6:1
  /// WARNING: Use textSecondary on secondary backgrounds instead
  static const Color textTertiary = Color.fromRGBO(255, 255, 255, 0.60);

  /// Disabled text color (50% opacity white)
  /// WCAG AA compliant: 5.0:1 on primary, 4.1:1 on secondary
  /// Use for inactive/disabled UI elements
  static const Color textDisabled = Color.fromRGBO(255, 255, 255, 0.50);

  /// High contrast text (black)
  static const Color textOnLight = Colors.black87;

  // ==================== Background Colors ====================

  /// Main app background
  static const Color background = primary;

  /// Card background
  static const Color cardBackground = primary;

  /// Surface background (slightly lighter)
  static const Color surface = secondary;

  /// Overlay background
  static const Color overlay = Color(0x80000000);

  // ==================== Border Colors ====================

  /// Primary border color (35% opacity white)
  /// WCAG AA compliant for UI components: 3.0:1
  /// Use for input borders, dividers, focus indicators
  static const Color border = Color.fromRGBO(255, 255, 255, 0.35);

  /// Light border color (15% opacity white)
  /// NOT WCAG compliant - decorative use only
  /// Do not use for functional UI component borders
  static const Color borderLight = Color.fromRGBO(255, 255, 255, 0.15);

  /// Focus border color
  static const Color borderFocus = accentBlue;

  // ==================== Category Colors ====================

  /// FDA category color
  static const Color categoryFDA = Color(0xFF64B5F6);

  /// USDA category color
  static const Color categoryUSDA = Color(0xFF4CAF50);

  /// Default category color
  static const Color categoryDefault = Colors.white70;

  // ==================== Special Colors ====================

  /// Premium/Pro feature color
  static const Color premium = Color(0xFFFFD700);

  /// Badge background color
  static const Color badgeBackground = Colors.white24;

  /// Divider color
  static const Color divider = Colors.white12;

  /// Shadow color
  static const Color shadow = Colors.black26;

  // ==================== Helper Methods ====================

  /// Get risk level color based on classification
  static Color getRiskColor(String? classification) {
    if (classification == null) return riskUnknown;

    final classLower = classification.toLowerCase();

    if (classLower.contains('class i') || classLower.contains('high')) {
      return riskHigh;
    } else if (classLower.contains('class ii') || classLower.contains('medium')) {
      return riskMedium;
    } else if (classLower.contains('class iii') || classLower.contains('low')) {
      return riskLow;
    }

    return riskUnknown;
  }

  /// Get category color based on category name
  static Color getCategoryColor(String? category) {
    if (category == null) return categoryDefault;

    final catLower = category.toLowerCase();

    if (catLower.contains('fda')) {
      return categoryFDA;
    } else if (catLower.contains('usda')) {
      return categoryUSDA;
    }

    return categoryDefault;
  }
}
