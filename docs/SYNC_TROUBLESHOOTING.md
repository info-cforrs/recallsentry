# PC ↔ Mac Sync Troubleshooting Guide
## Quick Fixes for Common Issues

---

## "Mac Won't Update with GitHub Changes"

This is the most common issue. Here's the fix:

### On Your Mac:

```bash
# Step 1: Force clean everything
cd ~/Documents/RecallSentry  # Or wherever your project is
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf .dart_tool
rm -rf build

# Step 2: Pull latest from GitHub
git fetch origin
git reset --hard origin/main
git pull origin main

# Step 3: Rebuild everything
flutter pub get
cd ios
pod deintegrate  # This completely removes old pods
pod install
cd ..

# Step 4: Close and reopen Xcode
# Quit Xcode completely (Cmd+Q)
# Then open workspace (NOT .xcodeproj)
open ios/Runner.xcworkspace
```

### Why This Happens:

Flutter and iOS have multiple caches:
- Flutter build cache
- Dart analyzer cache
- CocoaPods cache
- Xcode derived data

Sometimes Git pulls the code, but these caches don't update. The commands above clear everything and rebuild fresh.

---

## "Authentication Failed" When Pushing

### PC Solution:

**Option 1: Use GitHub CLI (Easiest)**
```powershell
# Download from https://cli.github.com/
# Then run:
gh auth login
# Follow prompts
```

**Option 2: Personal Access Token**
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Give it a name: "PC Development"
4. Check these scopes:
   - ✓ repo (all)
   - ✓ workflow
5. Click "Generate token"
6. **SAVE THE TOKEN** (you can't see it again!)
7. When Git asks for password, use the token instead

### Mac Solution:

```bash
# Install GitHub CLI
brew install gh
gh auth login
```

Or use Keychain:
```bash
git config --global credential.helper osxkeychain
# Next time you push, enter your token and it'll be saved
```

---

## "Merge Conflict" Error

### What It Looks Like:
```
error: Your local changes to the following files would be overwritten by merge:
    lib/pages/home_page.dart
Please commit your changes or stash them before you merge.
```

### Fix (Safest):

**If you want to keep your local changes:**
```bash
# Save your work
git stash push -m "Saving my work before pull"

# Pull latest
git pull origin main

# Restore your work
git stash pop

# If there are conflicts, Git will mark them in files like:
# <<<<<<< HEAD
# Your code
# =======
# Code from GitHub
# >>>>>>> main

# Open the file in VS Code, resolve conflicts, then:
git add .
git commit -m "Resolved merge conflicts"
git push origin main
```

**If you want GitHub version (discard your local changes):**
```bash
git reset --hard origin/main
git pull origin main
```

---

## "Xcode Shows Old Version"

### Full Xcode Reset:

```bash
# 1. Quit Xcode completely
killall Xcode

# 2. Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 3. Clean Flutter
cd ~/Documents/RecallSentry
flutter clean

# 4. Clean iOS
cd ios
rm -rf Pods
rm -rf build
rm Podfile.lock
pod cache clean --all
pod deintegrate
pod install
cd ..

# 5. Open workspace (important!)
open ios/Runner.xcworkspace
```

**Common Mistake:** Opening `Runner.xcodeproj` instead of `Runner.xcworkspace`
- ✗ Wrong: `ios/Runner.xcodeproj`
- ✓ Right: `ios/Runner.xcworkspace`

---

## "No Podfile Found"

### Solution:

```bash
cd ~/Documents/RecallSentry/ios

# Podfile should exist. If not:
flutter create --platforms=ios ..

# Then install pods
pod install
```

---

## "Operation Not Permitted" on Mac

### Solution:

```bash
# Give Terminal full disk access:
# 1. System Preferences → Security & Privacy → Privacy
# 2. Select "Full Disk Access"
# 3. Click the lock to make changes
# 4. Click "+" and add Terminal
# 5. Restart Terminal
```

---

## Git Commands Not Working

### PC (PowerShell):

```powershell
# Check if Git is installed
git --version

# If not, download from: https://git-scm.com/download/win

# Check if you're in the right folder
pwd
# Should show: C:\RS_Flutter\rs_flutter

# If not:
cd C:\RS_Flutter\rs_flutter
```

### Mac (Terminal):

```bash
# Check if Git is installed
git --version

# If not:
xcode-select --install

# Check if you're in the right folder
pwd
# Should show: /Users/YourName/Documents/RecallSentry

# If not:
cd ~/Documents/RecallSentry
```

---

## Flutter Commands Not Working

### PC:

```powershell
# Check Flutter
flutter doctor

# If not found, add to PATH:
# 1. Windows search: "Environment Variables"
# 2. Edit "Path" variable
# 3. Add: C:\src\flutter\bin
# 4. Restart PowerShell
```

### Mac:

```bash
# Check Flutter
flutter doctor

# If not found, add to PATH:
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Or for bash:
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bash_profile
source ~/.bash_profile
```

---

## "Permission Denied" for Sync Script

### Mac Only:

```bash
chmod +x sync_from_github.sh
./sync_from_github.sh
```

If still doesn't work:
```bash
bash sync_from_github.sh
```

---

## Dependencies Out of Sync

### Symptoms:
- Import errors
- "Package not found"
- Build fails with missing dependencies

### Fix (PC):

```powershell
flutter clean
del pubspec.lock
flutter pub get
```

### Fix (Mac):

```bash
flutter clean
rm pubspec.lock
flutter pub get
cd ios && pod install && cd ..
```

---

## "Detached HEAD" State

### What It Means:
You're not on a branch. This happens if you check out a specific commit.

### Fix:

```bash
# See where you are
git status

# Go back to main branch
git checkout main

# Pull latest
git pull origin main
```

---

## Build Fails After Sync

### Full Reset (PC):

```powershell
# Clean everything
flutter clean
Remove-Item -Recurse -Force .dart_tool
Remove-Item -Recurse -Force build
Remove-Item pubspec.lock

# Rebuild
flutter pub get
flutter run
```

### Full Reset (Mac):

```bash
# Clean everything
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm pubspec.lock

# Rebuild
flutter pub get
cd ios && pod install && cd ..
flutter run
```

---

## "Different Flutter Version"

If PC and Mac have different Flutter versions, you might see build errors.

### Check Versions:

**PC:**
```powershell
flutter --version
```

**Mac:**
```bash
flutter --version
```

### Update Flutter:

```bash
flutter upgrade
```

Do this on **both** machines to stay in sync.

---

## "Can't See My Changes After Pull"

### Checklist:

1. **Did you actually pull?**
   ```bash
   git log -1
   # Check if commit date is recent
   ```

2. **Are you looking at the right file?**
   ```bash
   # Search for your changes
   grep -r "your_code_here" lib/
   ```

3. **Did you open the right project?**
   ```bash
   pwd
   # Verify you're in the right folder
   ```

4. **Try hard reset:**
   ```bash
   git fetch origin
   git reset --hard origin/main
   flutter clean
   flutter pub get
   ```

---

## Nuclear Option: Start Fresh

If nothing works, start completely fresh on Mac:

```bash
# 1. Delete local repo
cd ~/Documents
rm -rf RecallSentry

# 2. Clone again
git clone https://github.com/info-cforrs/recallsentry.git RecallSentry
cd RecallSentry

# 3. Setup
flutter pub get
cd ios && pod install && cd ..

# 4. Make sync script executable
chmod +x sync_from_github.sh

# 5. Test
flutter doctor
flutter run
```

---

## Quick Diagnostics

Run these commands to diagnose issues:

### On PC:

```powershell
# Check Git status
cd C:\RS_Flutter\rs_flutter
git status
git remote -v
git log -1

# Check Flutter
flutter doctor
flutter --version

# Check if in right folder
pwd
```

### On Mac:

```bash
# Check Git status
cd ~/Documents/RecallSentry
git status
git remote -v
git log -1

# Check Flutter
flutter doctor
flutter --version

# Check Xcode
xcodebuild -version

# Check CocoaPods
pod --version

# Check if in right folder
pwd
```

---

## Still Having Issues?

### 1. Check the Main Guide
See: `docs/PC_to_Mac_Sync_Guide.md`

### 2. Verify Your Setup

**PC Checklist:**
- ✓ Git installed and in PATH
- ✓ Flutter installed and in PATH
- ✓ Can run: `git status`
- ✓ Can run: `flutter doctor`
- ✓ GitHub credentials configured

**Mac Checklist:**
- ✓ Xcode installed
- ✓ Xcode Command Line Tools installed
- ✓ Flutter installed and in PATH
- ✓ CocoaPods installed
- ✓ Can run: `git status`
- ✓ Can run: `flutter doctor`
- ✓ GitHub credentials configured

### 3. Get More Info

```bash
# Verbose output
git pull origin main --verbose

# See what changed
git log --oneline -10
git diff HEAD~1

# Check for corruption
git fsck
```

---

## Prevention Tips

1. **Always pull before editing**
   ```bash
   git pull origin main
   ```

2. **Commit and push frequently**
   - Don't let changes pile up
   - Easier to fix small conflicts

3. **Use the sync scripts**
   - They handle edge cases
   - Less chance of errors

4. **Test before pushing**
   ```bash
   flutter run
   ```

5. **Keep Flutter updated**
   ```bash
   flutter upgrade
   ```

6. **Don't edit same file on both machines simultaneously**

---

## Emergency Contacts

### Useful Git Commands:

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard all local changes
git reset --hard HEAD

# See what's different from GitHub
git fetch origin
git diff origin/main

# Force match GitHub exactly
git fetch origin
git reset --hard origin/main
```

### Recovery Commands:

```bash
# Recover deleted file
git checkout HEAD -- path/to/file

# Recover from stash
git stash list
git stash apply stash@{0}

# Find lost commits
git reflog
git checkout <commit-hash>
```

---

**Document Version:** 1.0
**Last Updated:** November 2025
**For More Help:** See `PC_to_Mac_Sync_Guide.md`
