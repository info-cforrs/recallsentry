# Debugging: "Unable to Load Recalls" Issue

**Status:** In Progress - Need Console Logs
**Date:** November 20, 2025

---

## Current Status

The app shows "Unable to load recalls" error on startup. We've added comprehensive debug logging to identify the exact failure point.

---

## What We've Fixed So Far

### 1. ✅ SSL Certificate Pinning (Windows Desktop)
**Problem:** Certificate pinning was blocking all API requests on Windows
**Fix:** Made certificate pinning platform-aware (disabled on desktop, enabled on mobile)
**File:** `lib/services/security_service.dart`

### 2. ✅ Enhanced Error Handling
**Problem:** Errors were silently returning empty arrays
**Fix:** Added detailed error logging and cache fallback
**File:** `lib/services/recall_data_service.dart`

### 3. ✅ Debug Logging Added
**What:** Added emoji-tagged logs to track API fetch progress
**Where:** FDA and USDA recall fetch methods

---

## Next Steps - ACTION REQUIRED

### Step 1: Restart the Flutter App

```bash
# Stop the current app (Ctrl+C in terminal)
# Then restart:
flutter run
```

OR press **'R'** in the terminal to hot restart.

---

### Step 2: Watch the Console Output

Look for these log messages:

#### ✅ SUCCESS Indicators:
```
🔵 Starting FDA recalls fetch from REST API...
🌐 Fetching FDA recalls from API...
✅ FDA recalls fetched successfully: X items
✅ Returning X cached FDA recalls

🔵 Starting USDA recalls fetch from REST API...
🌐 Fetching USDA recalls from API...
✅ USDA recalls fetched successfully: X items
✅ Returning X cached USDA recalls
```

#### ❌ ERROR Indicators:
```
❌ ERROR fetching FDA recalls from API: [error message]
Stack trace: [stack trace]
⚠️ No cached FDA data available, returning empty list

❌ ERROR fetching USDA recalls from API: [error message]
Stack trace: [stack trace]
⚠️ No cached USDA data available, returning empty list
```

---

### Step 3: Copy Console Output

**Please provide the FULL console output**, especially:
1. Any error messages starting with ❌
2. Stack traces
3. The logs showing what happened during FDA/USDA fetch

---

## Likely Root Causes

Based on the investigation so far:

### Possibility 1: Network/Firewall Issue
- Windows firewall blocking Flutter app
- Antivirus blocking HTTPS requests
- Corporate proxy interfering

**Test:**
```bash
# From PowerShell/CMD, test if API is reachable:
curl https://api.centerforrecallsafety.com/api/recalls/fda/
```

### Possibility 2: JSON Parsing Error
- API response format changed
- Unexpected data type in response
- Missing required fields

**Evidence Needed:**
- Error message saying "type 'X' is not a subtype of type 'Y'"
- SerializationException in logs

### Possibility 3: HTTP Client Issue
- SecurityService still blocking on Windows
- HttpClient not initialized properly

**Evidence Needed:**
- "HandshakeException" or "CertificateException"
- SSL/TLS related errors

### Possibility 4: Provider Initialization
- Riverpod providers not initializing correctly
- Subscription check failing
- User profile provider error

**Evidence Needed:**
- Errors mentioning "Provider"
- "StateError" or "ProviderException"

---

## Quick Tests to Run

### Test 1: Check API Directly
```bash
curl -v https://api.centerforrecallsafety.com/api/recalls/fda/?limit=1
```
Should return HTTP 200 with JSON data.

### Test 2: Check Windows Firewall
```powershell
# Allow Flutter through firewall (Run as Administrator):
New-NetFirewallRule -DisplayName "Flutter Debug" -Direction Outbound -Action Allow -Program "C:\path\to\flutter\bin\flutter.bat"
```

### Test 3: Disable Antivirus Temporarily
Temporarily disable antivirus and test if app loads recalls.

---

## What to Send Back

Please provide:

1. **Full Console Output** (from app start to error screen)
2. **Any error messages** you see
3. **Result of curl test** (does API respond?)
4. **Antivirus/Firewall status** (what's running?)

---

## Expected Timeline

- **Immediate:** Console logs show the exact error
- **5 minutes:** We identify the root cause
- **10 minutes:** We implement the fix
- **15 minutes:** App loads recalls successfully

---

## Files Modified (So Far)

```
✅ lib/services/security_service.dart
   - Platform-aware certificate pinning

✅ lib/services/recall_data_service.dart
   - Enhanced error handling with cache fallback
   - Comprehensive debug logging (FDA & USDA)
   - Persistent cache saving

✅ lib/pages/home_page.dart
   - Loading/error states UI

✅ lib/main.dart
   - Firebase duplicate init fix
```

---

## Contact

**Next Response:** Please restart the app and send back the console logs!

The logs will tell us exactly what's failing, and we can fix it immediately.
