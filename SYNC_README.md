# 🔄 PC ↔ Mac Sync System

Simple, reliable sync between your Windows PC and Mac laptop using GitHub.

**STATUS:** ✅ Fully tested and working (including iOS build fixes)

---

## Quick Start

### 📤 Push from PC (Windows)
```powershell
cd C:\RS_Flutter\rs_flutter
./quick_sync.ps1
```

### 📥 Pull on Mac
```bash
cd ~/recallsentry
./sync_from_github.sh
```

**The Mac script now automatically fixes all iOS build issues!**

---

## What's Included

### Scripts
- **`quick_sync.ps1`** (PC) - One-command sync to GitHub
- **`sync_to_github.ps1`** (PC) - Interactive sync with custom messages
- **`sync_from_github.sh`** (Mac) - Pull changes + automatic iOS setup

### Documentation
- **[PC_to_Mac_Sync_Guide.md](docs/PC_to_Mac_Sync_Guide.md)** - Complete workflow guide
- **[iOS_Build_Fix_Guide.md](docs/iOS_Build_Fix_Guide.md)** - iOS-specific troubleshooting
- **[SYNC_TROUBLESHOOTING.md](docs/SYNC_TROUBLESHOOTING.md)** - Common issues
- **[MAC_FIRST_TIME_SETUP.md](docs/MAC_FIRST_TIME_SETUP.md)** - First-time setup
- **[Android_Studio_Setup_Guide.md](docs/Android_Studio_Setup_Guide.md)** - PC setup
- **[App_Icon_Setup_Guide.md](docs/App_Icon_Setup_Guide.md)** - Icon management

---

## Mac Sync Script Features

The updated `sync_from_github.sh` now automatically:

✅ Pulls latest code from GitHub
✅ Cleans Flutter and iOS caches
✅ **Fixes iOS deployment target** (9.0 → 12.0)
✅ **Creates credentials placeholder** if missing
✅ **Reinstalls CocoaPods** cleanly
✅ Updates dependencies
✅ Offers to open Xcode workspace
✅ Handles merge conflicts gracefully

**No more manual iOS fixes needed!**

---

## Tested and Fixed Issues

### ✅ window_manager Error
- **Issue:** App crashed on iOS with `MissingPluginException`
- **Fix:** Wrapped in platform check (desktop-only)
- **Status:** Fixed in `lib/main.dart`

### ✅ iOS Deployment Target
- **Issue:** Podfile had iOS 9.0 (unsupported)
- **Fix:** Sync script auto-updates to iOS 12.0
- **Status:** Automated in sync script

### ✅ Development Team Required
- **Issue:** Xcode signing error
- **Fix:** Instructions in sync output
- **Status:** Documented in guide

### ✅ Git Merge Conflicts
- **Issue:** Local Mac changes conflict with PC
- **Fix:** Sync script offers stash or discard
- **Status:** Handled automatically

### ✅ Pod Installation Failures
- **Issue:** Old pods cause conflicts
- **Fix:** Script deintegrates before reinstalling
- **Status:** Automated in sync script

### ✅ Missing Credentials Folder
- **Issue:** Build error about missing `assets/credentials/` directory
- **Fix:** Both PC and Mac scripts automatically create placeholder
- **Status:** Automated in all sync scripts
- **Note:** This folder is in `.gitignore` for security, but must exist locally

---

## How It Works

```
┌─────────────┐
│   Your PC   │
│  (Windows)  │
└──────┬──────┘
       │ ./quick_sync.ps1
       │ (commits & pushes)
       ↓
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │ ./sync_from_github.sh
       │ (pulls & fixes iOS)
       ↓
┌─────────────┐
│  Your Mac   │
│   (macOS)   │
└─────────────┘
```

---

## First Time Setup

### On Mac (One Time):

```bash
cd ~/recallsentry

# Pull latest (includes sync scripts)
git pull origin main

# Make script executable
chmod +x sync_from_github.sh

# Run it
./sync_from_github.sh
```

The script will:
1. Pull all changes
2. Clean caches
3. Fix iOS settings
4. Install dependencies
5. Offer to open Xcode

Then in Xcode:
1. Select "Runner" target
2. "Signing & Capabilities"
3. Select your Team
4. Build (Cmd+R)

---

## Daily Workflow

### Working on PC → Moving to Mac

**PC:**
```powershell
# Make changes, test, then sync
./quick_sync.ps1
```

**Mac:**
```bash
# Pull and setup automatically
./sync_from_github.sh

# Build in Xcode or:
flutter run
```

### Working on Mac → Moving to PC

**Mac:**
```bash
git add -A
git commit -m "Update from Mac"
git push origin main
```

**PC:**
```powershell
git pull origin main
flutter clean
flutter pub get
flutter run
```

---

## Common Commands

### PC:
```powershell
# Quick sync (recommended)
./quick_sync.ps1

# Custom message
./sync_to_github.ps1

# Manual
git add -A && git commit -m "message" && git push
```

### Mac:
```bash
# Automated sync (recommended)
./sync_from_github.sh

# Manual
git pull origin main
flutter clean && flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

---

## Troubleshooting

### "Script not found" on Mac
```bash
git pull origin main
chmod +x sync_from_github.sh
./sync_from_github.sh
```

### "Build failed" on Mac
```bash
# Full reset
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

### "Git conflicts" on Mac
```bash
# Discard local changes (if PC is source of truth)
git reset --hard origin/main
./sync_from_github.sh
```

See [iOS_Build_Fix_Guide.md](docs/iOS_Build_Fix_Guide.md) for complete troubleshooting.

---

## What's New

### Version 2.0 (Current)
- ✅ Automatic iOS deployment target fix
- ✅ Automatic credentials folder creation
- ✅ Improved pod installation (deintegrate first)
- ✅ Better error messages
- ✅ Offers to open Xcode
- ✅ Complete iOS troubleshooting guide
- ✅ Platform-specific code patterns documented

### Version 1.0
- Basic sync scripts
- Manual iOS fixes required

---

## Success Indicators

Your setup is working when:

✅ `./quick_sync.ps1` pushes to GitHub without errors (PC)
✅ `./sync_from_github.sh` completes all 7 steps (Mac)
✅ App builds in Xcode without errors (Mac)
✅ App runs on iOS simulator/device (Mac)
✅ Changes from PC appear on Mac
✅ No merge conflicts

---

## Documentation Index

| Document | Purpose |
|----------|---------|
| [SYNC_README.md](SYNC_README.md) | This file - quick reference |
| [PC_to_Mac_Sync_Guide.md](docs/PC_to_Mac_Sync_Guide.md) | Complete workflow guide |
| [iOS_Build_Fix_Guide.md](docs/iOS_Build_Fix_Guide.md) | iOS troubleshooting |
| [SYNC_TROUBLESHOOTING.md](docs/SYNC_TROUBLESHOOTING.md) | Common issues |
| [MAC_FIRST_TIME_SETUP.md](docs/MAC_FIRST_TIME_SETUP.md) | Mac initial setup |
| [Android_Studio_Setup_Guide.md](docs/Android_Studio_Setup_Guide.md) | PC Android setup |
| [App_Icon_Setup_Guide.md](docs/App_Icon_Setup_Guide.md) | App icon guide |

---

## Repository

**URL:** https://github.com/info-cforrs/recallsentry

**Branch:** main

**Last Sync Test:** November 5, 2025 ✅

---

## Summary

**PC to Mac sync is now fully automated and tested!**

1. PC: `./quick_sync.ps1`
2. Mac: `./sync_from_github.sh`
3. Xcode: Set team, build, done!

All iOS build issues are handled automatically by the sync script. No more manual fixes needed! 🎉

---

**Version:** 2.0
**Status:** Production Ready
**Last Updated:** November 2025
