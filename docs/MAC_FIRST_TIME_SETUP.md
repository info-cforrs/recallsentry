# Mac First Time Setup
## Finding and Setting Up Your Project

---

## Step 1: Find Your Project

Run these commands to locate your project:

```bash
# Search common locations
ls ~/Documents/recallsentry 2>/dev/null && echo "Found in ~/Documents/recallsentry" || echo "Not in ~/Documents"
ls ~/recallsentry 2>/dev/null && echo "Found in ~/recallsentry" || echo "Not in home directory"
ls ~/Desktop/recallsentry 2>/dev/null && echo "Found in ~/Desktop/recallsentry" || echo "Not on Desktop"

# Or search entire home directory
find ~ -name "recallsentry" -type d 2>/dev/null | head -5
```

---

## Step 2: If Project Doesn't Exist - Clone It

If the project isn't on your Mac yet, clone it from GitHub:

```bash
# Navigate to where you want the project (recommended: Documents)
cd ~/Documents

# Clone from GitHub
git clone https://github.com/info-cforrs/recallsentry.git

# Enter the project
cd recallsentry

# Verify you're in the right place
pwd
# Should show: /Users/YourName/Documents/recallsentry

# Check if sync script exists
ls -la sync_from_github.sh
```

---

## Step 3: Make Sync Script Executable

```bash
chmod +x sync_from_github.sh
```

---

## Step 4: Initial Setup

```bash
# Get dependencies
flutter pub get

# Setup iOS
cd ios
pod install
cd ..

# Verify Flutter
flutter doctor
```

---

## Step 5: Run Sync Script

```bash
./sync_from_github.sh
```

---

## Quick Fix: Where Are You?

Run this to see your current location:

```bash
pwd
```

If it shows something like `/Users/markmayeux/recallsentry` but the script isn't there, the sync script might not have been pulled yet. Run:

```bash
git pull origin main
ls -la *.sh
```

If you see the script, make it executable:

```bash
chmod +x sync_from_github.sh
./sync_from_github.sh
```

---

## Still Can't Find It?

Try this search:

```bash
# Find all directories named recallsentry
find ~ -name "*recall*" -type d 2>/dev/null

# Or find the sync script directly
find ~ -name "sync_from_github.sh" 2>/dev/null
```

---

## Manual Sync (If Script Still Missing)

If the script isn't there yet, do this manually:

```bash
# Pull latest from GitHub
git pull origin main

# Clean everything
flutter clean

# Update dependencies
flutter pub get

# Update iOS pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Now the script should be there
ls -la sync_from_github.sh
chmod +x sync_from_github.sh
```
