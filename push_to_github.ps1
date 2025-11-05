# Push RecallSentry changes to GitHub
# Run this script on Windows PC after making changes

Write-Host "=== Pushing RecallSentry changes to GitHub ===" -ForegroundColor Green

# Navigate to project directory
Set-Location C:\RS_Flutter\rs_flutter

# Check git status
Write-Host "`nCurrent status:" -ForegroundColor Yellow
git status

# Add all files except credentials and nul
Write-Host "`nAdding files..." -ForegroundColor Yellow
git add lib/
git add pubspec.yaml
git add pubspec.lock
git add android/
git add ios/
git add windows/
git add linux/
git add macos/
git add web/

# Show what will be committed
Write-Host "`nFiles to be committed:" -ForegroundColor Yellow
git status

# Prompt for commit message
$commitMessage = Read-Host "`nEnter commit message (or press Enter for default)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Update app - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
}

# Commit
Write-Host "`nCommitting changes..." -ForegroundColor Yellow
git commit -m "$commitMessage"

# Push to GitHub
Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=== SUCCESS! Changes pushed to GitHub ===" -ForegroundColor Green
    Write-Host "Now run the update script on your Mac to get these changes." -ForegroundColor Cyan
} else {
    Write-Host "`n=== ERROR: Push failed ===" -ForegroundColor Red
    Write-Host "Check the error message above." -ForegroundColor Red
}

Read-Host "`nPress Enter to exit"
