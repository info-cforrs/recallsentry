# 🔄 PC ↔ Mac Sync System

Simple, reliable sync between your Windows PC and Mac laptop using GitHub.

---

## Quick Start

### 📤 Push from PC (Windows)
```powershell
./quick_sync.ps1
```

### 📥 Pull on Mac
```bash
./sync_from_github.sh
```

---

## Files

- **`quick_sync.ps1`** - PC: One-command sync to GitHub
- **`sync_to_github.ps1`** - PC: Interactive sync with custom messages
- **`sync_from_github.sh`** - Mac: Pull all changes from GitHub
- **`docs/PC_to_Mac_Sync_Guide.md`** - Complete guide with examples
- **`docs/SYNC_TROUBLESHOOTING.md`** - Fix common issues

---

## How It Works

```
PC → GitHub → Mac
```

1. Make changes on PC
2. Run `quick_sync.ps1` to push to GitHub
3. On Mac, run `sync_from_github.sh` to pull changes
4. Continue development on Mac

Works the same way in reverse!

---

## First Time Setup

### Mac Only (One Time):

```bash
# Make script executable
chmod +x sync_from_github.sh

# Install dependencies
flutter pub get
cd ios && pod install && cd ..
```

---

## Common Issues

### "Changes don't appear on Mac"
```bash
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
```

### "Authentication failed"
```bash
# Install GitHub CLI
gh auth login
```

### More help
See: `docs/SYNC_TROUBLESHOOTING.md`

---

## Daily Workflow

**Morning:**
1. Pull latest changes
2. Start coding

**During day:**
- Commit and push frequently
- Use `quick_sync.ps1` after each feature

**When switching machines:**
- Push from current machine
- Pull on other machine

**End of day:**
- Push final changes
- All work backed up to GitHub

---

## Repository

**URL:** https://github.com/info-cforrs/recallsentry

**Branch:** main

---

## Full Documentation

📖 **[Complete Guide](docs/PC_to_Mac_Sync_Guide.md)**

🔧 **[Troubleshooting](docs/SYNC_TROUBLESHOOTING.md)**

---

Last Updated: November 2025
