class AppConfig {
  // App Version
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Legal URLs (Required for App Store compliance)
  static const String privacyPolicyUrl = 'https://recallsentry.com/privacy';
  static const String termsOfServiceUrl = 'https://recallsentry.com/terms';
  static const String eulaUrl = 'https://recallsentry.com/eula';
  static const String supportUrl = 'https://recallsentry.com/support';

  // App Store Subscription Management URLs
  static const String iosSubscriptionManagementUrl =
      'https://apps.apple.com/account/subscriptions';
  static const String androidSubscriptionManagementUrl =
      'https://play.google.com/store/account/subscriptions';

  // Data Source Configuration
  // Choose between REST API (recommended) or Google Sheets
  static const DataSource dataSource = DataSource.restApi;

  // REST API Configuration
  // CRITICAL: HTTPS is REQUIRED for app store submission
  // SSL Certificate: Let's Encrypt (valid until Feb 3, 2026)
  // Certificate Subject: api.centerforrecallsafety.com

  // =========================================================================
  // API VERSIONING
  // =========================================================================
  // All API endpoints now use versioned paths (/api/v1/)
  // This enables backwards-compatible API evolution
  static const String apiVersion = 'v1';

  // CURRENT: Using production domain with API versioning
  // This ensures SSL certificate validation works correctly
  static const String apiBaseUrl = 'https://api.centerforrecallsafety.com/api/$apiVersion';
  static const String mediaBaseUrl = 'https://api.centerforrecallsafety.com';

  // Legacy endpoint (deprecated - kept for reference only)
  // static const String apiBaseUrlLegacy = 'https://api.centerforrecallsafety.com/api';

  // DEPRECATED: Direct IP access (causes SSL certificate mismatch)
  // static const String apiBaseUrl = 'https://18.218.174.62/api';
  // static const String mediaBaseUrl = 'https://18.218.174.62';

  // =========================================================================
  // API ENDPOINTS (relative to apiBaseUrl which includes version)
  // =========================================================================
  static const String apiRecallsEndpoint = '/recalls/';
  static const String apiFdaEndpoint = '/recalls/fda/';
  static const String apiUsdaEndpoint = '/recalls/usda/';
  static const String apiCpscEndpoint = '/recalls/cpsc/';
  static const String apiNhtsaEndpoint = '/recalls/nhtsa/';
  static const String apiNhtsaVehiclesEndpoint = '/recalls/vehicles/';
  static const String apiNhtsaTiresEndpoint = '/recalls/tires/';
  static const String apiNhtsaChildSeatsEndpoint = '/recalls/child_seats/';
  static const String apiStatsEndpoint = '/recalls/stats/';

  // API Documentation URLs
  static const String apiDocsUrl = 'https://api.centerforrecallsafety.com/api/docs/';
  static const String apiSchemaUrl = 'https://api.centerforrecallsafety.com/api/schema/';

  // Google Sheets Configuration (Legacy - for testing only)
  // To enable Google Sheets integration:
  // 1. Replace the spreadsheet IDs below with your actual Google Spreadsheet IDs
  // 2. Ensure your service account JSON is in assets/credentials/service-account.json
  // 3. Make sure both spreadsheets are shared with your service account email

  // MAIN/ALL RECALLS SPREADSHEET (contains all recalls mixed together)
  static const String googleSheetsSpreadsheetId =
      '1dTAbc9OvKja24SznAKxdWC4Nh3Pi5sGUt85dOItZY5c';

  // FDA-SPECIFIC RECALLS SPREADSHEET (contains FDA recalls with FDA-specific columns)
  static const String fdaRecallsSpreadsheetId =
      '1jUrln_zv5FL_5pxIRGHyfgcwDr6MwWvCIi8QYcblhPk';

  // USDA-SPECIFIC RECALLS SPREADSHEET (contains USDA recalls with USDA-specific columns)
  static const String usdaRecallsSpreadsheetId =
      '1C4ierwOx5DIUaf9er07ELEAlFt47hUor2HFcbm62amY';

  // Configuration checks
  static bool get isRestApiConfigured =>
      apiBaseUrl.isNotEmpty && apiBaseUrl != 'your_api_url_here';

  static bool get isGoogleSheetsConfigured =>
      googleSheetsSpreadsheetId.isNotEmpty &&
      googleSheetsSpreadsheetId != 'your_spreadsheet_id_here';

  static bool get isFdaSpreadsheetConfigured =>
      fdaRecallsSpreadsheetId.isNotEmpty &&
      fdaRecallsSpreadsheetId != 'your_fda_spreadsheet_id_here';

  static bool get isUsdaSpreadsheetConfigured =>
      usdaRecallsSpreadsheetId.isNotEmpty &&
      usdaRecallsSpreadsheetId != 'your_usda_spreadsheet_id_here';
}

// Data source options
enum DataSource {
  restApi,
  googleSheets,
}
