#!/bin/bash
# ============================================
# RecallSentry - Pull Changes from GitHub (Mac)
# ============================================
# This script pulls all changes from GitHub to your Mac
# Run this after pushing from your PC

echo "======================================"
echo "  RecallSentry - Pull from GitHub"
echo "======================================"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "ERROR: Not in a git repository!"
    echo "Please run this script from your RecallSentry project folder"
    exit 1
fi

# Get current branch
BRANCH=$(git branch --show-current)
echo "Current branch: $BRANCH"
echo ""

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "WARNING: You have uncommitted changes!"
    echo ""
    git status --short
    echo ""
    echo "Options:"
    echo "  1) Stash changes and pull (recommended)"
    echo "  2) Discard all local changes and pull (DANGEROUS)"
    echo "  3) Cancel"
    echo ""
    read -p "Choose option (1/2/3): " choice

    case $choice in
        1)
            echo ""
            echo "Stashing your local changes..."
            git stash push -m "Auto-stash before pull - $(date '+%Y-%m-%d %H:%M')"
            echo "✓ Changes stashed"
            ;;
        2)
            echo ""
            read -p "Are you SURE you want to discard all local changes? (type YES): " confirm
            if [ "$confirm" != "YES" ]; then
                echo "Cancelled."
                exit 0
            fi
            echo "Discarding all local changes..."
            git reset --hard HEAD
            git clean -fd
            echo "✓ Local changes discarded"
            ;;
        3)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid option. Cancelled."
            exit 1
            ;;
    esac
fi

# Pull latest changes
echo ""
echo "Step 1: Pulling latest changes from GitHub..."
git pull origin $BRANCH

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Failed to pull changes"
    echo "There may be merge conflicts that need to be resolved manually."
    exit 1
fi

echo ""
echo "Step 2: Cleaning Flutter project..."
flutter clean > /dev/null 2>&1
echo "✓ Flutter cache cleaned"

echo ""
echo "Step 3: Getting dependencies..."
flutter pub get > /dev/null 2>&1
echo "✓ Dependencies updated"

echo ""
echo "Step 4: Checking for iOS pod updates..."
if [ -d "ios" ]; then
    cd ios
    pod install > /dev/null 2>&1
    cd ..
    echo "✓ iOS pods updated"
fi

echo ""
echo "======================================"
echo "  ✓ SUCCESS!"
echo "======================================"
echo ""
echo "Your Mac is now synced with GitHub."
echo ""
echo "Next steps:"
echo "  1. Open in Xcode: open ios/Runner.xcworkspace"
echo "  2. Or run in VS Code: flutter run"
echo ""
echo "If you had stashed changes, restore them with:"
echo "  git stash pop"
echo ""
