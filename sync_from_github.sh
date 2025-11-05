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
    echo "  1) Stash changes and pull (saves your work)"
    echo "  2) Discard all local changes and pull (RECOMMENDED after PC sync)"
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

echo "✓ Pulled successfully"

# Clean Flutter project
echo ""
echo "Step 2: Cleaning Flutter project..."
flutter clean > /dev/null 2>&1
echo "✓ Flutter cache cleaned"

# Clean iOS build artifacts
echo ""
echo "Step 3: Cleaning iOS build artifacts..."
if [ -d "ios" ]; then
    rm -rf ios/Pods
    rm -rf ios/Podfile.lock
    rm -rf ios/build
    echo "✓ iOS artifacts cleaned"
fi

# Clean other build artifacts
rm -rf .dart_tool > /dev/null 2>&1
rm -rf build > /dev/null 2>&1

# Fix iOS deployment target
echo ""
echo "Step 4: Checking iOS deployment target..."
if [ -f "ios/Podfile" ]; then
    if ! grep -q "platform :ios, '12.0'" ios/Podfile; then
        echo "Fixing iOS deployment target to 12.0..."
        sed -i '' "s/^# platform :ios.*/platform :ios, '12.0'/" ios/Podfile
        sed -i '' "s/^platform :ios, '9.0'/platform :ios, '12.0'/" ios/Podfile
        echo "✓ iOS deployment target fixed"
    else
        echo "✓ iOS deployment target already correct (12.0)"
    fi
fi

# Create credentials placeholder if missing
echo ""
echo "Step 5: Checking assets/credentials folder..."
if [ ! -d "assets/credentials" ]; then
    mkdir -p assets/credentials
    echo "{}" > assets/credentials/.gitkeep
    echo "✓ Created credentials placeholder"
else
    echo "✓ Credentials folder exists"
fi

# Get dependencies
echo ""
echo "Step 6: Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1
echo "✓ Dependencies updated"

# Update iOS pods
echo ""
echo "Step 7: Installing iOS pods..."
if [ -d "ios" ]; then
    cd ios

    # Deintegrate old pods
    pod deintegrate > /dev/null 2>&1 || echo "  (No previous pods to remove)"

    # Install pods
    echo "  Installing pods (this may take a minute)..."
    pod install > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✓ iOS pods installed successfully"
    else
        echo "⚠ Pod installation had issues (may still work)"
        echo "  If build fails, run: cd ios && pod cache clean --all && pod install"
    fi

    cd ..
else
    echo "⚠ No ios folder found"
fi

echo ""
echo "======================================"
echo "  ✓ SYNC COMPLETE!"
echo "======================================"
echo ""
echo "Your Mac is now synced with GitHub."
echo ""
echo "Next steps:"
echo "  1. Open Xcode: open ios/Runner.xcworkspace"
echo "  2. Select your development team in Signing & Capabilities"
echo "  3. Build and run (Cmd+R)"
echo ""
echo "Or run in terminal:"
echo "  flutter run"
echo ""

# Check if Xcode is installed
if command -v xcodebuild &> /dev/null; then
    read -p "Open Xcode workspace now? (y/n): " open_xcode
    if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
        open ios/Runner.xcworkspace
        echo "✓ Xcode opened"
    fi
fi

echo ""
echo "If you stashed changes earlier, restore them with:"
echo "  git stash pop"
echo ""
echo "For troubleshooting, see: docs/iOS_Build_Fix_Guide.md"
echo ""
