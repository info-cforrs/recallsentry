# Quick Start Guide
## RecallSentry Flutter App - Android Studio

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Windows 10 or later (64-bit)
- [ ] At least 8GB RAM (16GB recommended)
- [ ] 10GB free disk space
- [ ] Administrator access
- [ ] Stable internet connection

---

## Quick Setup (5 Steps)

### 1. Install Flutter SDK (10 minutes)

```bash
# Download from: https://docs.flutter.dev/get-started/install/windows
# Extract to: C:\src\flutter
# Add to PATH: C:\src\flutter\bin
```

**Verify:**
```bash
flutter --version
flutter doctor
```

---

### 2. Install Android Studio (15 minutes)

```bash
# Download from: https://developer.android.com/studio
# Install with "Standard" setup
```

**Required SDK Components:**
- Android 14.0 (API 34)
- Android 13.0 (API 33)
- Android SDK Build-Tools
- Android SDK Command-line Tools
- Android Emulator

**Required Plugins:**
- Flutter
- Dart

---

### 3. Accept Android Licenses (2 minutes)

```bash
flutter doctor --android-licenses
# Type 'y' for each license
```

---

### 4. Open Project (5 minutes)

1. Open Android Studio
2. Click "Open"
3. Navigate to: `C:\RS_Flutter\rs_flutter`
4. Wait for indexing to complete

```bash
# In Android Studio Terminal:
flutter pub get
```

---

### 5. Run App (10 minutes first time)

**Create Emulator:**
- Device Manager → Create Device
- Select "Pixel 7" or "Pixel 8"
- Download "Tiramisu" (API 33)
- Start emulator

**Run App:**
- Select device in toolbar
- Click green ▶️ Run button
- Wait for build (5-10 min first time)

---

## Essential Commands

### Verify Setup
```bash
flutter doctor -v
flutter devices
```

### Build & Run
```bash
flutter run              # Debug mode
flutter run --release    # Release mode
flutter build apk        # Build APK
```

### Development
```bash
flutter pub get          # Get dependencies
flutter clean            # Clean build
flutter analyze          # Check code
```

### In Running App
```
r  = Hot reload (quick)
R  = Hot restart (full)
q  = Quit
```

---

## Common Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Run App | Shift + F10 |
| Debug App | Shift + F9 |
| Stop App | Ctrl + F2 |
| Open Terminal | Alt + F12 |
| Save & Reload | Ctrl + S |
| Find | Ctrl + F |
| Replace | Ctrl + R |
| Format Code | Ctrl + Alt + L |

---

## Quick Troubleshooting

### Flutter doctor issues
```bash
flutter doctor --android-licenses
flutter config --android-sdk "C:\Users\[YourUsername]\AppData\Local\Android\Sdk"
```

### Build failed
```bash
cd C:\RS_Flutter\rs_flutter
flutter clean
flutter pub get
```

### Emulator won't start
- Enable virtualization in BIOS (Intel VT-x or AMD-V)
- Install HAXM: SDK Manager → SDK Tools → HAXM

### Dependencies error
```bash
flutter pub cache repair
flutter pub get
```

---

## App Configuration

**API Endpoints (Already Configured):**
- Base URL: `https://api.centerforrecallsafety.com/api`
- Media URL: `https://api.centerforrecallsafety.com`

**Config File:** `lib/config/app_config.dart`

---

## File Structure Overview

```
rs_flutter/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── app_config.dart       # API configuration
│   ├── pages/                    # All app screens
│   ├── widgets/                  # Reusable UI components
│   ├── services/                 # API services
│   └── models/                   # Data models
├── android/                      # Android-specific files
├── ios/                          # iOS-specific files (not used)
├── assets/                       # Images, fonts, etc.
└── pubspec.yaml                  # Dependencies
```

---

## Development Workflow

1. **Start Day:**
   - Open Android Studio
   - Start emulator
   - Run app (Shift + F10)

2. **Make Changes:**
   - Edit Dart files
   - Save (Ctrl + S)
   - Hot reload (r)

3. **Test:**
   - Check emulator
   - Test features
   - Check console for errors

4. **End Day:**
   - Stop app (q)
   - Close emulator
   - Commit changes (if using git)

---

## Success Checklist

Your setup is working when:

- ✓ `flutter doctor` shows green checkmarks
- ✓ Emulator starts successfully
- ✓ App builds without errors
- ✓ Recalls load with images
- ✓ Navigation works smoothly
- ✓ Hot reload responds instantly

---

## Need More Help?

**Full Documentation:**
- See: `Android_Studio_Setup_Guide.docx`

**Official Resources:**
- Flutter Docs: https://docs.flutter.dev
- Android Studio: https://developer.android.com/studio

**Project Location:**
- `C:\RS_Flutter\rs_flutter`

---

**Quick Start Version:** 1.0
**Last Updated:** November 2025
