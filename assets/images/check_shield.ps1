# PowerShell script to help setup the shield logo
# Instructions: 
# 1. Manually save the shield image from the attachment
# 2. Name it 'shield_logo.png' 
# 3. Copy it to this directory

$imagePath = "C:\RS_Flutter\rs_flutter\assets\images\shield_logo.png"

if (Test-Path $imagePath) {
    Write-Host "✅ Shield logo found at: $imagePath" -ForegroundColor Green
} else {
    Write-Host "❌ Shield logo not found. Please:" -ForegroundColor Red
    Write-Host "   1. Save the shield image from attachment as 'shield_logo.png'" -ForegroundColor Yellow
    Write-Host "   2. Copy it to: $imagePath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Current directory contents:" -ForegroundColor Cyan
Get-ChildItem "C:\RS_Flutter\rs_flutter\assets\images\" | Format-Table Name, Length, LastWriteTime