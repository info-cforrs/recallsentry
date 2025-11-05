# ============================================
# RecallSentry - QUICK SYNC to GitHub (PC)
# ============================================
# One-command sync: Stage, commit, and push all changes
# Usage: Right-click this file → "Run with PowerShell"

param(
    [string]$CommitMessage = ""
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  RecallSentry - QUICK SYNC" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if in git repo
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not in a git repository!" -ForegroundColor Red
    pause
    exit 1
}

# Get branch
$branch = git branch --show-current
Write-Host "Branch: $branch" -ForegroundColor Green

# Show changes
Write-Host ""
Write-Host "Changes to sync:" -ForegroundColor Yellow
$changes = git status --short
if ([string]::IsNullOrWhiteSpace($changes)) {
    Write-Host "No changes to sync!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Already up to date with GitHub." -ForegroundColor Green
    pause
    exit 0
}

git status --short
Write-Host ""

# Auto-generate commit message if not provided
if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $date = Get-Date -Format "yyyy-MM-dd HH:mm"
    $CommitMessage = "Update from PC - $date"
}

Write-Host "Commit message: $CommitMessage" -ForegroundColor Cyan
Write-Host ""

# Pull first
Write-Host "[1/4] Pulling latest changes..." -ForegroundColor Cyan
git pull origin $branch --rebase 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Pulled successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ Pull had issues (will try to push anyway)" -ForegroundColor Yellow
}

# Stage all
Write-Host "[2/4] Staging all changes..." -ForegroundColor Cyan
git add -A
Write-Host "✓ Staged" -ForegroundColor Green

# Commit
Write-Host "[3/4] Creating commit..." -ForegroundColor Cyan
git commit -m $CommitMessage 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Committed" -ForegroundColor Green
} else {
    Write-Host "⚠ No new changes to commit" -ForegroundColor Yellow
}

# Push
Write-Host "[4/4] Pushing to GitHub..." -ForegroundColor Cyan
git push origin $branch 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
} else {
    Write-Host "✗ Push failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Trying again with verbose output..." -ForegroundColor Yellow
    git push origin $branch
    pause
    exit 1
}

Write-Host ""
Write-Host "======================================"  -ForegroundColor Green
Write-Host "  ✓ SYNC COMPLETE!"  -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "View on GitHub:" -ForegroundColor Cyan
Write-Host "https://github.com/info-cforrs/recallsentry" -ForegroundColor White
Write-Host ""
Write-Host "On your Mac, run:" -ForegroundColor Yellow
Write-Host "./sync_from_github.sh" -ForegroundColor White
Write-Host ""

# Auto-close after 5 seconds
Write-Host "Closing in 5 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 5
