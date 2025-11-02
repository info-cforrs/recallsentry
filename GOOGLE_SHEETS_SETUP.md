# RecallSentry - Google Sheets Integration Setup

## Overview
RecallSentry now supports real-time recall data from Google Sheets! The app will automatically try to connect to your configured Google Sheets, and if unavailable, will fall back to sample data.

## Quick Setup (3 Steps)

### Step 1: Configure Your Spreadsheet ID
1. Open `lib/config/app_config.dart`
2. Replace `'your_spreadsheet_id_here'` with your actual Google Spreadsheet ID
3. You can find your spreadsheet ID in the URL:
   ```
   https://docs.google.com/spreadsheets/d/SPREADSHEET_ID_HERE/edit
   ```

### Step 2: Set Up Google Sheets Service Account
1. Create a service account in Google Cloud Console
2. Download the JSON credentials file
3. Place it at: `assets/credentials/service-account.json`
4. Share your Google Spreadsheet with the service account email

### Step 3: Format Your Spreadsheet
Your Google Spreadsheet should have a worksheet named "Recalls" with these columns:
- **ID** (e.g., "FDA-2025-001")
- **Product Name** (e.g., "Blood Pressure Medication")
- **Brand Name** (e.g., "PharmaCorp")
- **Risk Level** (HIGH, MEDIUM, LOW)
- **Date Issued** (MM/DD/YYYY format)
- **Agency** (FDA or USDA)
- **Description** (detailed recall description)
- **Category** (e.g., "Pharmaceuticals", "Meat & Poultry")
- **Image URL** (optional)

## How It Works

### Automatic Fallback System
- **Google Sheets Configured**: App loads real-time data from your spreadsheet
- **Google Sheets Not Configured**: App automatically uses sample data (no error messages)
- **Google Sheets Connection Fails**: App shows error message and falls back to sample data

### Agency Filtering
- **FDA Page**: Automatically filters to show only FDA recalls
- **USDA Page**: Automatically filters to show only USDA recalls
- **Data Caching**: Results are cached for 30 minutes for better performance

### Visual Design
- **FDA Cards**: Yellow background (`#FCE4A6`) with blue agency badges
- **USDA Cards**: Green background (`#D4EDDA`) with green agency badges
- **Risk Indicators**: Color-coded dots (red=HIGH, orange=MEDIUM, yellow=LOW)

## Testing Your Setup

1. **Test Connection**: Use the Google Sheets Test Page (accessible from the main menu)
2. **Add Sample Data**: The test page can add sample recalls to your spreadsheet
3. **Verify Display**: Check that data appears correctly on FDA and USDA pages

## Troubleshooting

### Common Issues:
1. **"Service not initialized"**: Check that your spreadsheet ID is configured in `app_config.dart`
2. **"Permission denied"**: Ensure your spreadsheet is shared with the service account email
3. **"Worksheet not found"**: Create a worksheet named "Recalls" in your spreadsheet
4. **Data not loading**: Check your service account JSON file is in the correct location

### File Locations:
- **Configuration**: `lib/config/app_config.dart`
- **Service Account**: `assets/credentials/service-account.json`
- **Test Page**: Main Menu → Google Sheets Test

## Sample Data Structure

When Google Sheets is not configured, the app displays sample recalls for both FDA and USDA agencies, demonstrating the full functionality and visual design.

---

**Ready to Go!** Your RecallSentry app now has professional Google Sheets integration with robust fallback capabilities!