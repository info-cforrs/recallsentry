# Multiple Spreadsheets Setup Guide

## What We're Doing (Simple Explanation)

Think of it like organizing your filing system:

**Before**: One big messy filing cabinet with all papers mixed together
**After**: Three organized filing cabinets:
1. **Main Cabinet**: All papers mixed together (backup/overview)
2. **FDA Cabinet**: Only FDA papers with FDA-specific forms
3. **USDA Cabinet**: Only USDA papers with USDA-specific forms

## Step-by-Step Setup

### Step 1: Create Your Google Spreadsheets

1. **Go to Google Sheets** (sheets.google.com)
2. **Create THREE new spreadsheets:**
   - Name: "All_Recalls_Database" (this is your existing one)
   - Name: "FDA_Recalls_Database" 
   - Name: "USDA_Recalls_Database"

### Step 2: Set Up Column Headers

#### For FDA_Recalls_Database:
Copy this EXACT row into Row 1:
```
ID	Product Name	Brand Name	Risk Level	Date Issued	Agency	Description	Category	Image URL	State_Count	Negative_Outcomes	PACKAGING_DESC	Remedy-Return	Remedy-Repair	Remedy-Replace	Remedy-Dispose	Remedy-N/A	Product_Qty	Sold_by
```

#### For USDA_Recalls_Database:
Copy this EXACT row into Row 1:
```
ID	Product Name	Brand Name	Risk Level	Date Issued	Agency	Description	Category	Image URL	Establishment_Number	Product_Code	Distribution_Pattern	Investigation_Status	Recall_Reason
```

### Step 3: Get Your Spreadsheet IDs

For each spreadsheet:
1. **Open the spreadsheet**
2. **Look at the URL in your browser**
3. **Copy the long ID** from the URL

Example URL: `https://docs.google.com/spreadsheets/d/1ABC123XYZ789EXAMPLE/edit`
The ID is: `1ABC123XYZ789EXAMPLE`

### Step 4: Update Your App Configuration

1. **Open** the file: `lib/config/app_config.dart`
2. **Replace** the placeholder IDs with your real IDs:

```dart
// MAIN/ALL RECALLS SPREADSHEET
static const String googleSheetsSpreadsheetId = 'YOUR_MAIN_SPREADSHEET_ID_HERE';

// FDA-SPECIFIC RECALLS SPREADSHEET  
static const String fdaRecallsSpreadsheetId = 'YOUR_FDA_SPREADSHEET_ID_HERE';

// USDA-SPECIFIC RECALLS SPREADSHEET
static const String usdaRecallsSpreadsheetId = 'YOUR_USDA_SPREADSHEET_ID_HERE';
```

### Step 5: Share Your Spreadsheets

For EACH of your 3 spreadsheets:
1. **Click "Share" button** in Google Sheets
2. **Add your service account email** (found in your service-account.json file)
3. **Give it "Editor" permissions**
4. **Click "Send"**

### Step 6: Test Your Setup

1. **Run your Flutter app**
2. **Check the console logs** for messages like:
   - "✅ Successfully fetched X FDA recalls"
   - "✅ Successfully fetched X USDA recalls"

## What Happens Now?

- **FDA Recalls Page**: Will automatically use the FDA spreadsheet
- **USDA Recalls Page**: Will automatically use the USDA spreadsheet  
- **All Recalls Page**: Will use the main spreadsheet (shows everything mixed)

## Troubleshooting

**Problem**: "No data found"
**Solution**: 
1. Check your spreadsheet IDs are correct
2. Make sure spreadsheets are shared with service account
3. Check that Row 1 has the exact column headers listed above

**Problem**: "Permission denied" 
**Solution**: 
1. Make sure you shared ALL THREE spreadsheets with your service account email
2. Give "Editor" permissions, not just "Viewer"

**Problem**: "Wrong data showing up"
**Solution**: 
1. Make sure the "Agency" column in your data says exactly "FDA" or "USDA"
2. Check that you're putting the right data in the right spreadsheet

## Benefits of This Setup

✅ **Better Organization**: FDA and USDA data stay separate
✅ **Different Data Fields**: Each agency can have their own special columns
✅ **Easier Maintenance**: Update FDA stuff in FDA spreadsheet, USDA stuff in USDA spreadsheet
✅ **Better Performance**: Smaller, focused data sets load faster
✅ **Future-Ready**: Easy to add more agencies later

## Next Steps

After this setup works:
1. **Create specialized recall cards** for FDA vs USDA data
2. **Add agency-specific data fields** to the cards
3. **Customize the UI** for each agency's unique requirements