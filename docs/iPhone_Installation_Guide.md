# RecallSentry: iPhone Installation Guide (PC to iPhone)

## Overview
This guide will help you install the RecallSentry Flutter app on your iPhone using a PC for development and a MacBook for deployment (Xcode required for final steps).

---

## Prerequisites

### Required Hardware
- **Windows PC** with Flutter installed (your development machine)
- **MacBook** (any Mac with macOS 10.14 or later)
- **iPhone** (iOS 12.0 or later recommended)
- **USB-C to Lightning cable** (or appropriate cable for your iPhone)

### Required Software on PC
- Flutter SDK (already installed)
- Git (for version control)
- Visual Studio Code or Android Studio

### Required Software on MacBook
- **Xcode** (version 13.0 or later) - Must be installed from Mac App Store
- **CocoaPods** - iOS dependency manager
- **Apple Developer Account** (free or paid)

---

## Part 1: Prepare Your Flutter Project on PC

### Step 1: Verify Flutter iOS Support
1. Open **Command Prompt** or **PowerShell** on your PC
2. Navigate to your project:
   ```bash
   cd C:\RS_Flutter\rs_flutter
   ```

3. Check Flutter configuration:
   ```bash
   flutter doctor
   ```
   - Note: You'll see a ✗ for Xcode - this is expected on PC
   - Make sure Android toolchain and Flutter are installed correctly

### Step 2: Prepare iOS Build Files
1. Ensure your project has iOS configuration:
   ```bash
   flutter create --platforms=ios .
   ```
   - This ensures iOS folder and files exist
   - Skip if `ios` folder already exists

2. Update dependencies:
   ```bash
   flutter pub get
   ```

### Step 3: Configure App Bundle Identifier
1. Open `ios/Runner.xcodeproj` folder location
2. Note: You'll need to edit this on Mac, but verify the folder exists
3. Your bundle ID should be unique (e.g., `com.recallsentry.app`)

### Step 4: Transfer Project to MacBook

**Option A: Using Git (Recommended)**
1. Initialize Git repository (if not already done):
   ```bash
   git init
   git add .
   git commit -m "Prepare for iOS build"
   ```

2. Push to GitHub/GitLab:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/recallsentry.git
   git push -u origin main
   ```

3. On MacBook, clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/recallsentry.git
   cd recallsentry/rs_flutter
   ```

**Option B: Using Cloud Storage**
1. Compress the entire `rs_flutter` folder
2. Upload to Google Drive, Dropbox, or iCloud
3. Download on MacBook
4. Extract to a convenient location

**Option C: Using USB Drive**
1. Copy entire `rs_flutter` folder to USB drive
2. Transfer to MacBook
3. Copy to MacBook's Documents or Desktop

---

## Part 2: Set Up MacBook for iOS Development

### Step 5: Install Xcode
1. Open **Mac App Store** on your MacBook
2. Search for **"Xcode"**
3. Click **Get** or **Install** (download is ~10-15 GB, may take 30-60 minutes)
4. After installation, open Xcode
5. Accept the license agreement:
   - Xcode will prompt you on first launch
   - Or run in Terminal: `sudo xcodebuild -license accept`

6. Install command line tools:
   ```bash
   xcode-select --install
   ```

### Step 6: Install Flutter on MacBook
1. Download Flutter SDK for macOS:
   - Visit: https://docs.flutter.dev/get-started/install/macos
   - Download the latest stable release

2. Extract Flutter SDK:
   ```bash
   cd ~/development
   unzip ~/Downloads/flutter_macos_*.zip
   ```

3. Add Flutter to PATH:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```

4. Add permanently to `.zshrc` or `.bash_profile`:
   ```bash
   echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

5. Run Flutter doctor:
   ```bash
   flutter doctor
   ```

6. Accept Android licenses (if needed):
   ```bash
   flutter doctor --android-licenses
   ```

### Step 7: Install CocoaPods
1. Install CocoaPods (iOS dependency manager):
   ```bash
   sudo gem install cocoapods
   ```

2. Verify installation:
   ```bash
   pod --version
   ```

### Step 8: Set Up Apple Developer Account

**For Free Account (7-day signing):**
1. Open **Xcode**
2. Go to **Xcode → Preferences** (or **Settings** in newer versions)
3. Click **Accounts** tab
4. Click **+** button and select **Apple ID**
5. Sign in with your Apple ID (any Apple ID works)
6. A "Personal Team" will be created automatically

**For Paid Account ($99/year - required for App Store):**
1. Visit: https://developer.apple.com/programs/enroll/
2. Sign in with your Apple ID
3. Follow enrollment process (requires payment)
4. Add account to Xcode (same steps as above)

---

## Part 3: Configure Project for iOS on MacBook

### Step 9: Open Project in Xcode
1. Navigate to your project folder:
   ```bash
   cd ~/path/to/rs_flutter
   ```

2. Open the iOS project:
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Note: Open `.xcworkspace`, NOT `.xcodeproj`

### Step 10: Configure Signing & Capabilities
1. In Xcode, select **Runner** in the project navigator (left sidebar)
2. Select **Runner** target under TARGETS
3. Click **Signing & Capabilities** tab
4. Configure the following:

   **Team:**
   - Click the dropdown next to "Team"
   - Select your Personal Team or Development Team

   **Bundle Identifier:**
   - Change to a unique identifier: `com.YOUR_NAME.recallsentry`
   - Must be unique across all iOS apps
   - Example: `com.johnsmith.recallsentry`

   **Automatically manage signing:**
   - Check this box (Xcode will handle certificates automatically)

5. Repeat for **RunnerTests** target if present

### Step 11: Update iOS Deployment Target
1. Still in Xcode, under **Runner** target
2. Click **General** tab
3. Under **Deployment Info**:
   - Set **iOS Deployment Target** to **12.0** or later
   - This determines minimum iOS version supported

### Step 12: Install iOS Dependencies
1. In Terminal, navigate to iOS folder:
   ```bash
   cd ios
   ```

2. Install CocoaPods dependencies:
   ```bash
   pod install
   ```
   - This installs all iOS dependencies
   - May take 5-10 minutes

3. Return to project root:
   ```bash
   cd ..
   ```

---

## Part 4: Connect iPhone and Install App

### Step 13: Prepare Your iPhone
1. **Connect iPhone to MacBook** using USB cable
2. On iPhone, unlock the device
3. If prompted **"Trust This Computer?"**, tap **Trust**
4. Enter your iPhone passcode if requested

### Step 14: Enable Developer Mode (iOS 16+)
If your iPhone is running iOS 16 or later:
1. On iPhone, go to **Settings**
2. Scroll down to **Privacy & Security**
3. Scroll down to **Developer Mode**
4. Toggle **Developer Mode** ON
5. iPhone will restart
6. After restart, confirm by tapping **Turn On** when prompted

### Step 15: Build and Install via Flutter
1. In Terminal on MacBook, navigate to project:
   ```bash
   cd ~/path/to/rs_flutter
   ```

2. List connected devices:
   ```bash
   flutter devices
   ```
   - You should see your iPhone listed
   - Example: "John's iPhone (mobile) • 00008030-XXXXXXXXXXXX"

3. Install app to iPhone:
   ```bash
   flutter run --release
   ```
   - Use `--release` for better performance
   - Or use `--debug` for development

4. Wait for build and installation (first build takes 5-15 minutes)

### Step 16: Trust Developer Certificate on iPhone
After installation, the app won't launch immediately:

1. On iPhone, go to **Settings**
2. Go to **General**
3. Scroll down to **VPN & Device Management** (or **Device Management**)
4. Under **DEVELOPER APP**, tap your Apple ID email
5. Tap **Trust "[Your Apple ID]"**
6. Tap **Trust** in the popup

### Step 17: Launch the App
1. Go to your iPhone home screen
2. Find the **RecallSentry** app icon
3. Tap to launch
4. App should now run successfully!

---

## Part 5: Reinstalling / Updating the App

### For Free Apple ID (Personal Team)
- Apps signed with free accounts expire after **7 days**
- After 7 days, repeat Steps 15-17 to reinstall
- You'll need MacBook and cable each time

### For Paid Developer Account
- Apps remain installed until you delete them
- Can distribute to up to 100 devices via TestFlight
- No 7-day expiration

### Updating the App
1. Make changes on PC
2. Transfer updated project to MacBook (via Git, cloud, or USB)
3. On MacBook:
   ```bash
   cd ~/path/to/rs_flutter
   flutter pub get
   cd ios
   pod install
   cd ..
   flutter run --release
   ```

---

## Troubleshooting

### Issue: "No provisioning profiles found"
**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Change Bundle Identifier to something unique
4. Select your Team again
5. Try building again

### Issue: "Unable to install [app name]"
**Solution:**
1. On iPhone: Settings → General → VPN & Device Management
2. Delete old certificates
3. Rebuild and reinstall app

### Issue: "Code signing is required"
**Solution:**
1. Ensure you're signed in to Xcode (Xcode → Preferences → Accounts)
2. Ensure "Automatically manage signing" is checked
3. Clean build: `flutter clean` then rebuild

### Issue: "Device locked" or "Failed to launch"
**Solution:**
1. Unlock your iPhone
2. Keep iPhone unlocked during installation
3. Trust developer certificate (Step 16)

### Issue: CocoaPods installation fails
**Solution:**
1. Update CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```
2. Clean and reinstall:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   ```

### Issue: "Flutter not found" on MacBook
**Solution:**
1. Verify Flutter installation:
   ```bash
   which flutter
   ```
2. Add to PATH if needed (see Step 6)
3. Restart Terminal

---

## Alternative: Using Xcode Directly

If you prefer using Xcode instead of `flutter run`:

1. Open project: `open ios/Runner.xcworkspace`
2. Connect iPhone
3. In Xcode toolbar, select your iPhone from device dropdown
4. Click **Run** button (▶️) or press **Cmd + R**
5. Xcode will build and install the app

---

## Summary

**Quick Reference:**
1. ✅ Develop on PC with Flutter
2. ✅ Transfer project to MacBook (Git/Cloud/USB)
3. ✅ Install Xcode and Flutter on MacBook
4. ✅ Configure signing in Xcode
5. ✅ Run `pod install` in ios folder
6. ✅ Connect iPhone and run `flutter run --release`
7. ✅ Trust developer certificate on iPhone
8. ✅ Launch app!

**Time Estimates:**
- First-time setup: 2-4 hours (including Xcode download)
- Subsequent installations: 10-15 minutes
- Free account: Reinstall every 7 days
- Paid account ($99/year): Permanent installation

---

## Next Steps
- See **App_Store_Deployment_Guide.md** for publishing to App Store
- Consider upgrading to paid Developer Account for TestFlight and App Store access
- Set up automated builds using Codemagic or Bitrise for easier deployment

---

*Document created: 2025-11-02*
*Project: RecallSentry Flutter Application*
