# Android Studio Setup Guide for Flutter
## RecallSentry Mobile App - Windows PC

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Install Flutter SDK](#step-1-install-flutter-sdk)
3. [Install Android Studio](#step-2-install-android-studio)
4. [Configure Flutter in Android Studio](#step-3-configure-flutter-in-android-studio)
5. [Open Your Flutter Project](#step-4-open-your-flutter-project)
6. [Set Up Android Emulator](#step-5-set-up-android-emulator)
7. [Run Your Flutter App](#step-6-run-your-flutter-app)
8. [Verify App Configuration](#step-7-verify-app-configuration)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)
10. [Quick Verification Checklist](#quick-verification-checklist)
11. [First Run Tips](#first-run-tips)

---

## Prerequisites

### System Requirements:
- **Operating System:** Windows 10 or later (64-bit)
- **RAM:** At least 8GB (16GB recommended)
- **Disk Space:** 10GB free disk space minimum
- **Access:** Administrator access required for installation
- **Internet:** Stable internet connection for downloads

---

## Step 1: Install Flutter SDK

### A. Download Flutter

1. Open your web browser and navigate to: https://docs.flutter.dev/get-started/install/windows
2. Click the **"flutter_windows_[version]-stable.zip"** button to download the latest stable version
3. Once downloaded, extract the ZIP file to **`C:\src\flutter`**
   - **Important:** Do NOT extract to `Program Files` (spaces in path cause issues)
   - Create the `C:\src` folder if it doesn't exist

### B. Add Flutter to System PATH

1. Press **Win + X** and select **"System"**
2. Click **"Advanced system settings"** on the left side
3. Click the **"Environment Variables"** button at the bottom
4. In the "User variables" section, find the **"Path"** variable and click **"Edit"**
5. Click **"New"** and add: `C:\src\flutter\bin`
6. Click **"OK"** on all dialog boxes to save changes
7. **Restart any open Command Prompt windows** for changes to take effect

### C. Verify Flutter Installation

1. Open **Command Prompt** (Press Win + R, type `cmd`, press Enter)
2. Run the following commands:

```bash
flutter --version
```

This should display the Flutter version information.

3. Now run:

```bash
flutter doctor
```

This command checks your environment and displays a report of Flutter installation status. Don't worry if you see issues related to Android - we'll fix those in the next steps.

---

## Step 2: Install Android Studio

### A. Download and Install Android Studio

1. Open your web browser and go to: https://developer.android.com/studio
2. Click **"Download Android Studio"**
3. Accept the terms and conditions
4. Run the downloaded installer file
5. Follow the setup wizard:
   - Select **"Standard"** installation type
   - Accept the default installation location
   - Click **"Finish"** when complete
6. Wait for Android Studio to download additional components

### B. Install Required Android SDK Components

1. Open **Android Studio**
2. Navigate to **"Tools" → "SDK Manager"**
   - Alternatively: **File → Settings → Appearance & Behavior → System Settings → Android SDK**

3. In the **"SDK Platforms"** tab:
   - ✓ Check **Android 14.0 (UpsideDownCake) - API Level 34** (or latest available)
   - ✓ Check **Android 13.0 (Tiramisu) - API Level 33**
   - Click **"Show Package Details"** at the bottom right
   - For each API level checked, ensure **"Android SDK Platform"** is selected

4. Switch to the **"SDK Tools"** tab:
   - ✓ Check **Android SDK Build-Tools**
   - ✓ Check **Android SDK Command-line Tools (latest)**
   - ✓ Check **Android Emulator**
   - ✓ Check **Android SDK Platform-Tools**
   - ✓ Check **Intel x86 Emulator Accelerator (HAXM installer)** - if you have an Intel CPU
   - ✓ Check **Google Play services**

5. Click **"Apply"** at the bottom right
6. Click **"OK"** in the confirmation dialog
7. Wait for all components to download and install
8. Click **"Finish"** when complete

### C. Install Flutter & Dart Plugins

1. In Android Studio, go to **"File" → "Settings"** (or press Ctrl + Alt + S)
2. Navigate to **"Plugins"** in the left sidebar
3. Click the **"Marketplace"** tab at the top
4. In the search box, type **"Flutter"**
5. Find the **Flutter** plugin and click **"Install"**
6. A dialog will appear asking to install the **Dart** plugin as well
7. Click **"Yes"** to install both plugins
8. Click **"Restart IDE"** when prompted
9. Wait for Android Studio to restart

---

## Step 3: Configure Flutter in Android Studio

### Accept Android Licenses

1. Open **Command Prompt**
2. Run the following command:

```bash
flutter doctor --android-licenses
```

3. You'll be prompted to accept several licenses
4. Type **`y`** (yes) for each license and press Enter
5. Continue until all licenses are accepted

### Verify Setup

1. Run `flutter doctor` again:

```bash
flutter doctor
```

2. You should now see green checkmarks (✓) for:
   - Flutter (Channel stable)
   - Android toolchain
   - Android Studio

3. Don't worry if you see warnings about Chrome or other platforms - those are optional for mobile development

---

## Step 4: Open Your Flutter Project

### A. Open the RecallSentry Project

1. Launch **Android Studio**
2. On the Welcome screen, click **"Open"**
   - If Android Studio is already open with a project, go to **File → Open**
3. Navigate to **`C:\RS_Flutter\rs_flutter`**
4. Click **"OK"**
5. Wait for Android Studio to:
   - Index the project (progress bar at bottom)
   - Download dependencies automatically
   - This may take 2-5 minutes on first open

### B. Install Project Dependencies

1. Once the project loads, open the **Terminal** in Android Studio:
   - **View → Tool Windows → Terminal**
   - Or press **Alt + F12**

2. In the terminal, run:

```bash
flutter pub get
```

3. Wait for all dependencies to download
4. You should see a message: **"Got dependencies!"**

---

## Step 5: Set Up Android Emulator

You have two options: use an **Android Virtual Device (emulator)** or a **physical Android phone**.

### Option A: Create Android Virtual Device (AVD) - Emulator

1. In Android Studio, click the **"Device Manager"** icon in the toolbar
   - Look for the phone/tablet icon
   - Or go to **Tools → Device Manager**

2. Click **"Create Device"** (the + icon)

3. **Select Hardware:**
   - Choose a device definition (recommended: **"Pixel 7"** or **"Pixel 8"**)
   - Click **"Next"**

4. **Select System Image:**
   - Recommended: **"Tiramisu"** (API Level 33) or **"UpsideDownCake"** (API Level 34)
   - If not already installed, click **"Download"** next to the system image
   - Wait for download to complete
   - Click **"Next"**

5. **Verify Configuration:**
   - Give your AVD a name (e.g., **"Pixel_7_API_33"**)
   - Review settings (defaults are usually fine)
   - Click **"Finish"**

6. **Start the Emulator:**
   - In Device Manager, find your newly created AVD
   - Click the **▶️ Play** button next to it
   - Wait 1-2 minutes for the emulator to boot up
   - You should see an Android home screen

### Option B: Use Physical Android Device

1. **Enable Developer Options on your Android phone:**
   - Go to **Settings → About Phone**
   - Find **"Build Number"**
   - Tap **"Build Number"** 7 times rapidly
   - You'll see a message: "You are now a developer!"

2. **Enable USB Debugging:**
   - Go back to **Settings**
   - Navigate to **System → Developer Options**
   - Toggle **"USB Debugging"** to ON
   - Confirm the prompt

3. **Connect to PC:**
   - Connect your phone to your PC using a USB cable
   - On your phone, you'll see a prompt: **"Allow USB debugging?"**
   - Check **"Always allow from this computer"**
   - Tap **"OK"**

4. **Verify Connection:**
   - Open Command Prompt
   - Run:
   ```bash
   adb devices
   ```
   - You should see your device listed
   - If you see "unauthorized", check your phone for the USB debugging prompt

---

## Step 6: Run Your Flutter App

### A. Select Your Target Device

1. In the Android Studio toolbar, look for the **device selector dropdown**
   - It shows the currently selected device/emulator
2. Click the dropdown and select:
   - Your running emulator (e.g., "Pixel 7 API 33")
   - OR your connected physical device

### B. Run the Application

**Method 1: Using Android Studio UI**
1. Click the green **▶️ "Run"** button in the toolbar
2. Or press **Shift + F10**

**Method 2: Using Terminal**
1. Open Terminal in Android Studio (**Alt + F12**)
2. Run:
```bash
flutter run
```

### C. Wait for Initial Build

- **First build takes 5-10 minutes** (Gradle downloads dependencies)
- Subsequent builds are much faster (30-60 seconds)
- You'll see build progress in the terminal/run window

### D. App Should Launch

Once the build completes:
- The app will automatically launch on your device/emulator
- You'll see the RecallSentry home screen
- The app will connect to the production API

### E. Hot Reload During Development

While the app is running, you can make changes and see them instantly:

- **Hot Reload (Quick Refresh):**
  - Press **`r`** in the terminal
  - Or click the **⚡ Lightning bolt** icon in Android Studio

- **Hot Restart (Full Restart):**
  - Press **`R`** in the terminal
  - Or click the **🔄 Restart** icon in Android Studio

- **Stop the App:**
  - Press **`q`** in the terminal
  - Or click the **⏹️ Stop** button in Android Studio

---

## Step 7: Verify App Configuration

Your RecallSentry app is already configured to use the production API:

### API Configuration
- **API Base URL:** `https://api.centerforrecallsafety.com/api`
- **Media Base URL:** `https://api.centerforrecallsafety.com`

These settings are configured in:
- **File Location:** `lib/config/app_config.dart`
- **Lines:** 7-8

### Test App Functionality

1. **Home Screen:** Should display recall cards with images
2. **Navigation:** Test bottom navigation between Home, Saved, Info, Settings
3. **Recall Details:** Tap a recall to view full details
4. **Images:** Product images should load from the API
5. **Search:** Search functionality should work
6. **Filters:** Apply filters to narrow down recalls

If any of these don't work, check the troubleshooting section below.

---

## Troubleshooting Common Issues

### Issue 1: "cmdline-tools component is missing"

**Symptoms:** Flutter doctor shows Android toolchain issue

**Solution:**
```bash
flutter doctor --android-licenses
```

Or in Android Studio:
1. Go to **Tools → SDK Manager**
2. Switch to **"SDK Tools"** tab
3. Check **"Android SDK Command-line Tools (latest)"**
4. Click **"Apply"**

---

### Issue 2: "Unable to locate Android SDK"

**Symptoms:** Flutter can't find Android SDK

**Solution:**
1. Open **Command Prompt as Administrator**
2. Run (replace `[YourUsername]` with your Windows username):
```bash
flutter config --android-sdk "C:\Users\[YourUsername]\AppData\Local\Android\Sdk"
```

---

### Issue 3: Emulator Won't Start

**Symptoms:** Emulator fails to launch or shows black screen

**Solution A - Enable Virtualization:**
1. Restart your PC
2. Enter BIOS/UEFI settings (usually press F2, F10, or Del during startup)
3. Find and enable:
   - **Intel VT-x** (Intel processors)
   - **AMD-V** (AMD processors)
4. Save and exit BIOS
5. Try starting emulator again

**Solution B - Install HAXM:**
1. Open Android Studio
2. Go to **Tools → SDK Manager → SDK Tools**
3. Check **"Intel x86 Emulator Accelerator (HAXM installer)"**
4. Click **"Apply"**

---

### Issue 4: "Gradle build failed"

**Symptoms:** Build errors with Gradle

**Solution:**
1. Open **Command Prompt**
2. Navigate to your project:
```bash
cd C:\RS_Flutter\rs_flutter\android
```
3. Clean Gradle:
```bash
gradlew clean
```
4. Go back to project root:
```bash
cd ..
```
5. Clean Flutter:
```bash
flutter clean
flutter pub get
```
6. Try running the app again

---

### Issue 5: Dependencies Not Resolving

**Symptoms:** "pub get failed" or package errors

**Solution:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

---

### Issue 6: "Waiting for another flutter command to release the startup lock"

**Symptoms:** Flutter commands hang

**Solution:**
1. Open **Task Manager** (Ctrl + Shift + Esc)
2. Find and end all **"dart.exe"** and **"flutter.exe"** processes
3. Delete the lock file:
```bash
del "C:\src\flutter\bin\cache\lockfile"
```
4. Try your command again

---

### Issue 7: App Shows "Connection Error" or Blank Data

**Symptoms:** App loads but shows no recalls

**Solution:**
1. Check your internet connection
2. Verify API is accessible:
   - Open browser and visit: https://api.centerforrecallsafety.com/api/recalls/
   - You should see JSON data
3. Check app configuration in `lib/config/app_config.dart`
4. Restart the app

---

## Quick Verification Checklist

Run these commands in **Command Prompt** to verify your setup:

### 1. Check Flutter Installation
```bash
flutter --version
```
**Expected:** Displays Flutter version (e.g., Flutter 3.x.x)

### 2. Check for Issues
```bash
flutter doctor -v
```
**Expected:** Green checkmarks (✓) for Flutter, Android toolchain, and Android Studio

### 3. Check Connected Devices
```bash
flutter devices
```
**Expected:** Lists your emulator or connected phone

### 4. Verify Project Dependencies
```bash
cd C:\RS_Flutter\rs_flutter
flutter pub get
```
**Expected:** "Got dependencies!" message

### 5. Check Android SDK
```bash
flutter doctor --android-licenses
```
**Expected:** "All SDK package licenses accepted"

---

## First Run Tips

### 1. First Build Takes Time
- **Initial build:** 5-10 minutes (normal)
- **Subsequent builds:** 30-60 seconds
- Be patient on first run!

### 2. Enable Hot Reload
- Makes development much faster
- Press `r` in terminal for hot reload
- Changes appear instantly without full restart

### 3. Use Physical Device When Possible
- Often faster than emulator
- More accurate for testing real-world scenarios
- Better performance

### 4. Check Console Logs
- **View logs:** View → Tool Windows → Run
- Helpful for debugging issues
- Shows API calls and errors

### 5. Enable Debugging
- Click **🐛 Debug** button instead of **▶️ Run**
- Allows setting breakpoints
- Inspect variables during runtime

### 6. Useful Keyboard Shortcuts
- **Run App:** Shift + F10
- **Debug App:** Shift + F9
- **Stop App:** Ctrl + F2
- **Hot Reload:** Ctrl + S (after saving changes)
- **Open Terminal:** Alt + F12

### 7. Monitor Performance
- **View → Tool Windows → Flutter Performance**
- Check FPS and frame rendering
- Identify performance bottlenecks

### 8. Use Flutter DevTools
- Run app in debug mode
- Click **"Open DevTools"** in run window
- Advanced debugging and performance tools

---

## Development Workflow

### Daily Development Routine

1. **Start Android Studio**
2. **Open Project:** `C:\RS_Flutter\rs_flutter`
3. **Start Emulator or Connect Device**
4. **Run App:** Shift + F10
5. **Make Changes:** Edit Dart files
6. **Hot Reload:** Press `r` or save file
7. **Test Changes:** Verify in app
8. **Repeat:** Steps 5-7 as needed

### Building Release APK

When you're ready to create a release version:

```bash
cd C:\RS_Flutter\rs_flutter
flutter build apk --release
```

APK will be created at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Additional Resources

### Official Documentation
- **Flutter Docs:** https://docs.flutter.dev
- **Dart Language:** https://dart.dev/guides
- **Android Studio Guide:** https://developer.android.com/studio/intro

### Flutter Commands Reference
```bash
flutter doctor          # Check environment setup
flutter devices         # List connected devices
flutter run            # Run app in debug mode
flutter build apk      # Build release APK
flutter clean          # Clean build artifacts
flutter pub get        # Get dependencies
flutter pub upgrade    # Upgrade dependencies
flutter analyze        # Analyze Dart code
```

### Useful Android Studio Plugins
- **Flutter Enhancement Suite** - Additional Flutter tools
- **Dart Data Class Generator** - Generate model classes
- **Flutter Intl** - Internationalization support

---

## Success Indicators

Your setup is complete when:

✓ `flutter doctor` shows all green checkmarks
✓ Android Studio recognizes Flutter SDK
✓ Emulator or device is detected
✓ App builds and runs successfully
✓ Recalls load from API with images
✓ Hot reload works smoothly

---

## Support and Next Steps

### If You're Still Having Issues:
1. Review the troubleshooting section
2. Check Flutter doctor output carefully
3. Verify all prerequisites are met
4. Ensure stable internet connection
5. Try restarting Android Studio and emulator

### Ready to Develop:
- App is connected to production API
- All features are functional
- You can now test, debug, and develop new features

---

**Document Version:** 1.0
**Last Updated:** November 2025
**App Version:** RecallSentry v1.0
**API Endpoint:** https://api.centerforrecallsafety.com/api

---

## Contact Information

For technical support or questions about the RecallSentry app development, contact your development team or refer to the project documentation.

**API Status:** https://api.centerforrecallsafety.com/admin/
**Project Location:** C:\RS_Flutter\rs_flutter

---

*End of Android Studio Setup Guide*
