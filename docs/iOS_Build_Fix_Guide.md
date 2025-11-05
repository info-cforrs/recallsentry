# iOS Build Fix Guide
## Complete Checklist for Building on Mac After PC Sync

---

## Quick Fix (Copy/Paste This)

After pulling from GitHub on your Mac, run this complete setup script:

```bash
cd ~/recallsentry

# 1. Pull latest changes
git pull origin main

# 2. Handle any local conflicts
git reset --hard origin/main

# 3. Clean everything
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf .dart_tool
rm -rf build

# 4. Fix iOS deployment target in Podfile
sed -i '' "s/^# platform :ios.*/platform :ios, '12.0'/" ios/Podfile
sed -i '' "s/^platform :ios, '9.0'/platform :ios, '12.0'/" ios/Podfile

# 5. Get dependencies
flutter pub get

# 6. Reinstall pods
cd ios
pod deintegrate || echo "No pods to deintegrate"
pod install
cd ..

# 7. Open Xcode
open ios/Runner.xcworkspace
```

Then in Xcode:
1. Select "Runner" target
2. Go to "Signing & Capabilities"
3. Select your Team
4. Build and run

---

## Common Issues and Fixes

### Issue 1: "window_manager" Error on iOS

**Error:**
```
MissingPluginException(No implementation found for method ensureInitialized on channel window_manager)
```

**Cause:** `window_manager` is desktop-only but was being called on mobile.

**Fix:** ✅ Already fixed in `lib/main.dart` - now wrapped in platform check.

**Verify fix:**
```bash
grep -A 2 "Platform.isWindows" lib/main.dart
# Should show platform check for window_manager
```

---

### Issue 2: iOS Deployment Target Too Old

**Error:**
```
The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 9.0,
but the range of supported deployment target versions is 12.0 to 26.0.99.
```

**Fix:**

Edit `ios/Podfile` - ensure first line is:
```ruby
platform :ios, '12.0'
```

Quick command:
```bash
cd ~/recallsentry
echo "platform :ios, '12.0'" | cat - ios/Podfile | tail -n +2 > ios/Podfile.tmp
mv ios/Podfile.tmp ios/Podfile
cd ios && pod install && cd ..
```

---

### Issue 3: Development Team Not Selected

**Error:**
```
Signing for "Runner" requires a development team.
Select a development team in the Signing & Capabilities editor.
```

**Fix in Xcode:**
1. Click "Runner" (blue icon) in left sidebar
2. Select "Runner" under TARGETS
3. Click "Signing & Capabilities" tab
4. Under "Team", select your Apple ID
5. Check "Automatically manage signing"

**To verify:**
```bash
grep -A 5 "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | head -1
```

---

### Issue 4: Pod Installation Fails

**Error:**
```
[!] CocoaPods could not find compatible versions for pod...
```

**Fix:**
```bash
cd ~/recallsentry/ios

# Clear CocoaPods cache
pod cache clean --all

# Remove old pods
rm -rf Pods
rm Podfile.lock

# Update pod repo
pod repo update

# Reinstall
pod install

cd ..
```

---

### Issue 5: Xcode Shows Old Code

**Symptoms:** Changes don't appear, old code still running

**Fix:**
```bash
# Close Xcode completely (Cmd+Q)
killall Xcode

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean Flutter
cd ~/recallsentry
flutter clean

# Clean iOS
cd ios
rm -rf Pods build
rm Podfile.lock
pod install
cd ..

# Reopen workspace (NOT .xcodeproj!)
open ios/Runner.xcworkspace
```

---

### Issue 6: Git Pull Conflicts

**Error:**
```
error: Your local changes to the following files would be overwritten by merge
```

**Fix:**

**Option A - Discard local changes (recommended after PC sync):**
```bash
git reset --hard origin/main
git clean -fd
git pull origin main
```

**Option B - Save local changes:**
```bash
git stash push -m "Save Mac changes $(date)"
git pull origin main
git stash pop  # Restore changes (may have conflicts)
```

---

### Issue 7: "assets/credentials/" Missing

**Error:**
```
Error: unable to find directory entry in pubspec.yaml:
/Users/markmayeux/recallsentry/assets/credentials/
```

**Cause:** Credentials folder is in `.gitignore` (correctly not committed)

**Fix:**
```bash
cd ~/recallsentry
mkdir -p assets/credentials
echo "{}" > assets/credentials/.gitkeep
```

This is just a placeholder. The app will work without actual credentials in the folder.

---

## Complete First-Time Setup Checklist

Use this checklist when setting up on Mac for the first time or after major changes:

### ☐ Step 1: Clone/Pull Repository
```bash
cd ~/Documents
git clone https://github.com/info-cforrs/recallsentry.git
cd recallsentry
```

Or if already cloned:
```bash
cd ~/recallsentry
git pull origin main
```

### ☐ Step 2: Verify Flutter Installation
```bash
flutter doctor -v
```

Should show:
- ✓ Flutter (installed)
- ✓ Xcode (installed)
- ✓ CocoaPods (installed)

### ☐ Step 3: Install CocoaPods (if needed)
```bash
sudo gem install cocoapods
```

### ☐ Step 4: Fix iOS Deployment Target
```bash
# Edit ios/Podfile - ensure first line is:
# platform :ios, '12.0'

nano ios/Podfile
# Change the line, save (Ctrl+X, Y, Enter)
```

### ☐ Step 5: Create Placeholder Credentials Folder
```bash
mkdir -p assets/credentials
echo "{}" > assets/credentials/.gitkeep
```

### ☐ Step 6: Clean and Get Dependencies
```bash
flutter clean
flutter pub get
```

### ☐ Step 7: Install iOS Pods
```bash
cd ios
pod install
cd ..
```

### ☐ Step 8: Open in Xcode
```bash
open ios/Runner.xcworkspace
```

**IMPORTANT:** Open `Runner.xcworkspace` NOT `Runner.xcodeproj`!

### ☐ Step 9: Configure Signing in Xcode
1. Select "Runner" target
2. "Signing & Capabilities" tab
3. Select your Team
4. Enable "Automatically manage signing"

### ☐ Step 10: Build and Run
- Click the Play button in Xcode
- Or: `flutter run` in Terminal

---

## Automated Setup Script

Save this as `setup_ios.sh` in your project root:

```bash
#!/bin/bash
# Complete iOS setup after pulling from GitHub

echo "======================================"
echo "  iOS Setup Script"
echo "======================================"
echo ""

# Navigate to project
cd ~/recallsentry || exit 1

echo "[1/10] Pulling latest changes..."
git pull origin main

echo "[2/10] Cleaning Flutter..."
flutter clean

echo "[3/10] Removing old iOS builds..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf build
rm -rf .dart_tool

echo "[4/10] Fixing iOS deployment target..."
if ! grep -q "platform :ios, '12.0'" ios/Podfile; then
    sed -i '' "s/^# platform :ios.*/platform :ios, '12.0'/" ios/Podfile
    sed -i '' "s/^platform :ios, '9.0'/platform :ios, '12.0'/" ios/Podfile
    echo "  Fixed deployment target to iOS 12.0"
else
    echo "  Deployment target already correct"
fi

echo "[5/10] Creating credentials placeholder..."
mkdir -p assets/credentials
echo "{}" > assets/credentials/.gitkeep

echo "[6/10] Getting Flutter dependencies..."
flutter pub get

echo "[7/10] Deintegrating old CocoaPods..."
cd ios
pod deintegrate 2>/dev/null || echo "  No pods to deintegrate"

echo "[8/10] Installing CocoaPods..."
pod install

echo "[9/10] Returning to project root..."
cd ..

echo "[10/10] Opening Xcode..."
open ios/Runner.xcworkspace

echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""
echo "Next steps in Xcode:"
echo "  1. Select 'Runner' target"
echo "  2. Go to 'Signing & Capabilities'"
echo "  3. Select your development team"
echo "  4. Build and run"
echo ""
```

Make it executable:
```bash
chmod +x setup_ios.sh
./setup_ios.sh
```

---

## Verification Commands

After setup, verify everything is ready:

```bash
# Check Flutter
flutter doctor

# Check dependencies
flutter pub get

# Check if pods are installed
ls ios/Pods/ | wc -l
# Should show multiple directories

# Check deployment target
grep "platform :ios" ios/Podfile

# Check if workspace exists
ls ios/Runner.xcworkspace/

# Test build
flutter build ios --debug --no-codesign
```

---

## Platform-Specific Code Patterns

When writing code that differs between platforms:

### Check for Mobile vs Desktop:
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Desktop only
if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
  // Desktop-specific code
}

// Mobile only
if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  // Mobile-specific code
}

// iOS only
if (!kIsWeb && Platform.isIOS) {
  // iOS-specific code
}
```

### Example (from main.dart):
```dart
// Only use window_manager on desktop
if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
  await windowManager.ensureInitialized();
  // ... desktop window setup
}
```

---

## Quick Reference

### Essential Commands:
```bash
# Full reset and rebuild
flutter clean && rm -rf ios/Pods ios/Podfile.lock && flutter pub get && cd ios && pod install && cd .. && open ios/Runner.xcworkspace

# Just rebuild pods
cd ios && pod install && cd ..

# Open Xcode workspace
open ios/Runner.xcworkspace

# Run on iOS
flutter run -d iPhone

# Build iOS
flutter build ios --debug --no-codesign
```

### Essential Xcode Shortcuts:
- `Cmd+B` - Build
- `Cmd+R` - Run
- `Cmd+.` - Stop
- `Cmd+Shift+K` - Clean build folder
- `Cmd+Q` - Quit Xcode

---

## Troubleshooting Decision Tree

```
App won't build on Mac?
│
├─ Error: "window_manager"
│  └─ Solution: Pull latest code (already fixed in main.dart)
│
├─ Error: "Deployment target 9.0"
│  └─ Solution: Edit ios/Podfile, set to iOS 12.0, run pod install
│
├─ Error: "Development team required"
│  └─ Solution: Xcode → Signing & Capabilities → Select team
│
├─ Error: "Pod installation failed"
│  └─ Solution: pod cache clean --all, pod install
│
├─ Error: "Xcode shows old code"
│  └─ Solution: Clean DerivedData, flutter clean, pod install
│
└─ Error: "Git conflicts"
   └─ Solution: git reset --hard origin/main
```

---

## Summary

After pulling from GitHub on Mac, always run:

1. `git pull origin main`
2. `flutter clean && flutter pub get`
3. `cd ios && pod install && cd ..`
4. `open ios/Runner.xcworkspace`
5. Set signing team in Xcode
6. Build

These steps ensure a clean build every time!

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Tested On:** macOS with Xcode 15+, iOS 12.0+
