# PC to Mac Sync Guide
## RecallSentry Flutter App - GitHub Workflow

---

## Overview

This guide provides a simple, reliable way to sync your Flutter app between your Windows PC and Mac development laptop using GitHub. The workflow is designed to prevent conflicts and ensure changes always update properly.

---

## Quick Start

### On Your PC (Windows):
```powershell
# Option 1: Quick sync (one command)
./quick_sync.ps1

# Option 2: Interactive sync (more control)
./sync_to_github.ps1
```

### On Your Mac:
```bash
# Pull all changes from GitHub
./sync_from_github.sh
```

That's it! Your code is synced.

---

## Table of Contents

1. [One-Time Setup](#one-time-setup)
2. [Daily Workflow](#daily-workflow)
3. [Sync Scripts Explained](#sync-scripts-explained)
4. [Troubleshooting](#troubleshooting)
5. [Common Issues](#common-issues)
6. [Best Practices](#best-practices)
7. [Advanced Topics](#advanced-topics)

---

## One-Time Setup

### PC Setup (Windows)

**1. Verify Git is installed:**
```powershell
git --version
```
If not installed, download from: https://git-scm.com/download/win

**2. Configure Git (if not done already):**
```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**3. Verify GitHub access:**
```powershell
cd C:\RS_Flutter\rs_flutter
git remote -v
```
Should show: `https://github.com/info-cforrs/recallsentry.git`

**4. Test connection:**
```powershell
git fetch origin
```
If this works, you're all set!

---

### Mac Setup

**1. Install Xcode Command Line Tools:**
```bash
xcode-select --install
```

**2. Install Flutter (if not done):**
```bash
# Download Flutter SDK for macOS
# https://docs.flutter.dev/get-started/install/macos

# Add to PATH in ~/.zshrc or ~/.bash_profile
export PATH="$PATH:/path/to/flutter/bin"
```

**3. Install CocoaPods (for iOS):**
```bash
sudo gem install cocoapods
```

**4. Clone the repository (first time only):**
```bash
# Navigate to where you want the project
cd ~/Documents

# Clone from GitHub
git clone https://github.com/info-cforrs/recallsentry.git RecallSentry
cd RecallSentry

# Make sync script executable
chmod +x sync_from_github.sh

# Initial setup
flutter pub get
cd ios && pod install && cd ..
```

**5. Configure Git:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Daily Workflow

### Scenario 1: Working on PC, Moving to Mac

**On PC:**
1. Make your code changes
2. Test locally: `flutter run`
3. Run quick sync:
   ```powershell
   ./quick_sync.ps1
   ```
4. Wait for "SYNC COMPLETE" message

**On Mac:**
1. Open Terminal
2. Navigate to project:
   ```bash
   cd ~/Documents/RecallSentry
   ```
3. Pull changes:
   ```bash
   ./sync_from_github.sh
   ```
4. Open in Xcode or VS Code
5. Continue development

---

### Scenario 2: Working on Mac, Moving to PC

**On Mac:**
1. Make your code changes
2. Test locally: `flutter run`
3. Commit and push:
   ```bash
   git add -A
   git commit -m "Update from Mac - $(date '+%Y-%m-%d %H:%M')"
   git push origin main
   ```

**On PC:**
1. Open PowerShell
2. Navigate to project:
   ```powershell
   cd C:\RS_Flutter\rs_flutter
   ```
3. Pull changes:
   ```powershell
   git pull origin main
   flutter clean
   flutter pub get
   ```
4. Continue development

---

### Scenario 3: Same Day, Multiple Syncs

You can sync as many times as you want:

**PC → GitHub → Mac → GitHub → PC**

Just run the appropriate sync script each time. The scripts handle:
- Pulling latest changes first
- Avoiding conflicts
- Merging automatically when possible

---

## Sync Scripts Explained

### 1. quick_sync.ps1 (PC - Recommended)

**Purpose:** One-command sync to GitHub

**What it does:**
1. Checks for changes
2. Pulls latest from GitHub
3. Stages all changes
4. Creates commit with timestamp
5. Pushes to GitHub

**Usage:**
```powershell
# From project root
./quick_sync.ps1

# With custom message
./quick_sync.ps1 -CommitMessage "Added new feature"
```

**When to use:**
- Quick daily syncs
- When you don't care about commit message
- When you want minimal interaction

---

### 2. sync_to_github.ps1 (PC - Interactive)

**Purpose:** Controlled sync with custom commit message

**What it does:**
1. Shows all changes
2. Asks for confirmation
3. Pulls latest changes
4. Lets you enter custom commit message
5. Creates commit and pushes

**Usage:**
```powershell
./sync_to_github.ps1
```

**When to use:**
- Important updates you want to describe
- When you want to review changes first
- When you want control over the commit message

---

### 3. sync_from_github.sh (Mac)

**Purpose:** Pull all changes from GitHub to Mac

**What it does:**
1. Checks for uncommitted local changes
2. Offers to stash or discard them
3. Pulls latest from GitHub
4. Runs `flutter clean`
5. Runs `flutter pub get`
6. Updates iOS pods

**Usage:**
```bash
./sync_from_github.sh
```

**When to use:**
- Every time you switch from PC to Mac
- When starting work on Mac
- After PC has pushed changes

---

## Troubleshooting

### Issue 1: "Changes Won't Update on Mac"

**Symptoms:**
- Mac pulls successfully
- But code changes don't appear
- Old code still running

**Solution:**
```bash
# Force clean everything
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf pubspec.lock

# Rebuild
flutter pub get
cd ios && pod install && cd ..

# Close Xcode if open, then reopen
flutter run
```

---

### Issue 2: "Merge Conflict"

**Symptoms:**
- Pull fails with merge conflict message
- Git won't let you push

**Solution on PC:**
```powershell
# See conflicted files
git status

# Option 1: Keep your changes
git checkout --ours path/to/file
git add path/to/file

# Option 2: Keep GitHub version
git checkout --theirs path/to/file
git add path/to/file

# Option 3: Edit manually in VS Code
# Open the file, resolve conflicts, then:
git add path/to/file

# Finish merge
git commit -m "Resolved merge conflict"
git push origin main
```

**Solution on Mac:**
```bash
# Same commands work on Mac
git status
# ... resolve conflicts ...
git add .
git commit -m "Resolved merge conflict"
git push origin main
```

---

### Issue 3: "Permission Denied" on Mac Script

**Symptoms:**
- `./sync_from_github.sh` fails
- "Permission denied" error

**Solution:**
```bash
chmod +x sync_from_github.sh
./sync_from_github.sh
```

---

### Issue 4: "Failed to Push - Authentication Failed"

**Symptoms:**
- Push fails with authentication error
- GitHub asks for username/password

**Solution (PC):**
```powershell
# Use GitHub CLI (recommended)
# Download from: https://cli.github.com/
gh auth login

# Or use Personal Access Token
# GitHub → Settings → Developer settings → Personal access tokens
# Generate token, then use it as password
```

**Solution (Mac):**
```bash
# Install GitHub CLI
brew install gh
gh auth login

# Or configure git credential helper
git config --global credential.helper osxkeychain
```

---

### Issue 5: "Detached HEAD State"

**Symptoms:**
- Git says you're in "detached HEAD"
- Can't push changes

**Solution:**
```bash
# Create new branch from current state
git checkout -b temp-branch

# Switch back to main
git checkout main

# Merge your changes
git merge temp-branch

# Delete temp branch
git branch -d temp-branch
```

---

## Common Issues

### "Build Failed After Sync"

**Cause:** Dependencies or cached files out of sync

**Fix (PC):**
```powershell
flutter clean
flutter pub get
```

**Fix (Mac):**
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

---

### "iOS Build Works on Mac But Not PC"

**Answer:** This is normal! iOS apps can only be built on Mac with Xcode.

PC can:
- Edit all code
- Build Android version
- Test with Android emulator

Mac can:
- Do everything PC can
- Build iOS version
- Test with iOS Simulator
- Submit to App Store

---

### "Xcode Shows Old Code"

**Fix:**
```bash
# Close Xcode completely (Cmd+Q)

# Clean Flutter
flutter clean

# Clean Xcode build
cd ios
rm -rf DerivedData
rm -rf Pods
rm Podfile.lock
pod install
cd ..

# Reopen Xcode
open ios/Runner.xcworkspace
```

---

## Best Practices

### 1. Always Pull Before Editing

Before starting work on either machine:
```bash
git pull origin main
```

This prevents conflicts.

---

### 2. Commit Often, Push Often

Don't wait until end of day. Sync after each feature or fix:
- PC: `./quick_sync.ps1`
- Mac: `git add -A && git commit -m "..." && git push`

---

### 3. Use Descriptive Commit Messages

Good:
- "Fixed image loading bug in RMC details"
- "Added export CSV feature to admin"
- "Updated app icon for iOS"

Bad:
- "stuff"
- "changes"
- "asdf"

---

### 4. Test Before Syncing

Always run the app locally before pushing:
```bash
flutter run
```

Make sure it builds successfully.

---

### 5. Don't Edit Same Files on Both Machines

If you must:
1. Finish and push from one machine
2. Pull on the other machine
3. Then continue editing

---

### 6. Keep Dependencies in Sync

When adding packages:

**PC:**
```powershell
flutter pub add package_name
./quick_sync.ps1
```

**Mac:**
```bash
./sync_from_github.sh
# Dependencies automatically updated
```

---

## Advanced Topics

### Creating a New Branch

**On PC:**
```powershell
# Create and switch to new branch
git checkout -b feature-new-ui

# Make changes
# ...

# Push new branch
git push origin feature-new-ui
```

**On Mac:**
```bash
# Switch to the new branch
git fetch origin
git checkout feature-new-ui

# Continue work
```

---

### Reviewing Commit History

```bash
# See last 10 commits
git log --oneline -10

# See changes in last commit
git show HEAD

# See all changes since yesterday
git log --since="yesterday"
```

---

### Undoing Last Commit (Not Pushed)

```bash
# Keep changes, undo commit
git reset --soft HEAD~1

# Discard changes and commit
git reset --hard HEAD~1
```

---

### Checking What Changed

**See modified files:**
```bash
git status
```

**See actual code changes:**
```bash
git diff
```

**See changes in specific file:**
```bash
git diff path/to/file.dart
```

---

## File Structure

Your project now includes these sync scripts:

```
rs_flutter/
├── quick_sync.ps1              ← PC: One-command sync
├── sync_to_github.ps1          ← PC: Interactive sync
├── sync_from_github.sh         ← Mac: Pull changes
├── docs/
│   ├── PC_to_Mac_Sync_Guide.md ← This guide
│   └── ...
└── ...
```

---

## Quick Reference

### PC Commands

```powershell
# Quick sync (recommended)
./quick_sync.ps1

# Interactive sync
./sync_to_github.ps1

# Manual commands
git pull origin main
git add -A
git commit -m "message"
git push origin main

# Clean build
flutter clean
flutter pub get
```

### Mac Commands

```bash
# Pull changes from GitHub
./sync_from_github.sh

# Manual commands
git pull origin main
git add -A
git commit -m "message"
git push origin main

# Clean build
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────┐
│                   Your PC (Windows)                  │
│                                                      │
│  1. Edit code in VS Code                            │
│  2. Test: flutter run                               │
│  3. Run: ./quick_sync.ps1                           │
│                                                      │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                    GitHub                            │
│         https://github.com/info-cforrs/              │
│                  recallsentry                        │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│                Your Mac (macOS)                      │
│                                                      │
│  1. Run: ./sync_from_github.sh                      │
│  2. Open: open ios/Runner.xcworkspace               │
│  3. Continue development                             │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Success Checklist

Your sync is working correctly when:

- ✓ PC can push to GitHub without errors
- ✓ Mac can pull from GitHub without errors
- ✓ Code changes appear on Mac after sync
- ✓ App builds successfully on both machines
- ✓ No merge conflicts
- ✓ Dependencies update automatically
- ✓ iOS builds work on Mac after sync

---

## Getting Help

### Check Git Status
```bash
git status          # See current state
git log -5          # See recent commits
git remote -v       # See repository URL
git branch -a       # See all branches
```

### Verify Connection
```bash
git fetch origin    # Test GitHub connection
git pull origin main --dry-run  # Preview what would pull
```

### Reset to Known Good State
```bash
# WARNING: This discards all local changes!
git fetch origin
git reset --hard origin/main
git clean -fd
```

---

## Summary

### The Simplest Workflow:

**PC:** Make changes → `./quick_sync.ps1` → Done

**Mac:** `./sync_from_github.sh` → Continue work → Done

That's it! The scripts handle everything else automatically.

---

**Document Version:** 1.0
**Last Updated:** November 2025
**Repository:** https://github.com/info-cforrs/recallsentry
**Branch:** main
