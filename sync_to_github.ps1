# ============================================
# RecallSentry - Push Changes to GitHub (PC)
# ============================================
# This script commits and pushes all changes from your PC to GitHub
# Run this before switching to your Mac

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  RecallSentry - Push to GitHub" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not in a git repository!" -ForegroundColor Red
    Write-Host "Please run this script from: C:\RS_Flutter\rs_flutter" -ForegroundColor Yellow
    pause
    exit 1
}

# Get current branch
$branch = git branch --show-current
Write-Host "Current branch: $branch" -ForegroundColor Green
Write-Host ""

# Ensure credentials directory exists
if (-not (Test-Path "assets\credentials")) {
    New-Item -ItemType Directory -Force -Path "assets\credentials" | Out-Null
    Set-Content -Path "assets\credentials\.gitkeep" -Value "{}"
    Write-Host "Created assets/credentials directory" -ForegroundColor Yellow
    Write-Host ""
}

# Show current status
Write-Host "Current changes:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Ask for confirmation
$continue = Read-Host "Do you want to push these changes to GitHub? (y/n)"
if ($continue -ne "y" -and $continue -ne "Y") {
    Write-Host "Aborted by user." -ForegroundColor Yellow
    pause
    exit 0
}

# Pull latest changes first (to avoid conflicts)
Write-Host ""
Write-Host "Step 1: Pulling latest changes from GitHub..." -ForegroundColor Cyan
git pull origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WARNING: Failed to pull changes. There may be conflicts." -ForegroundColor Red
    Write-Host "Do you want to continue anyway? (y/n)" -ForegroundColor Yellow
    $force = Read-Host
    if ($force -ne "y" -and $force -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Yellow
        pause
        exit 1
    }
}

# Add all changes
Write-Host ""
Write-Host "Step 2: Adding all changes..." -ForegroundColor Cyan
git add -A
Write-Host "✓ All changes staged" -ForegroundColor Green

# Ask for commit message
Write-Host ""
Write-Host "Step 3: Creating commit..." -ForegroundColor Cyan
$defaultMessage = "Update from PC - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "Default message: $defaultMessage" -ForegroundColor Gray
$commitMessage = Read-Host "Enter commit message (or press Enter for default)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = $defaultMessage
}

# Create commit
git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to create commit" -ForegroundColor Red
    Write-Host "This might mean there are no changes to commit." -ForegroundColor Yellow
    pause
    exit 1
}
Write-Host "✓ Commit created: $commitMessage" -ForegroundColor Green

# Push to GitHub
Write-Host ""
Write-Host "Step 4: Pushing to GitHub..." -ForegroundColor Cyan
git push origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to push to GitHub" -ForegroundColor Red
    Write-Host "Please check your internet connection and GitHub credentials." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "  ✓ SUCCESS!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your changes have been pushed to GitHub." -ForegroundColor Green
Write-Host "Repository: https://github.com/info-cforrs/recallsentry" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps on your Mac:" -ForegroundColor Yellow
Write-Host "  1. Open Terminal" -ForegroundColor White
Write-Host "  2. Navigate to your project folder" -ForegroundColor White
Write-Host "  3. Run: ./sync_from_github.sh" -ForegroundColor White
Write-Host ""

pause
