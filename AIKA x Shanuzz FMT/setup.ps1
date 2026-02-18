# Setup Script for AIKA x Shanuzz FMT
# Run this script to verify and setup the project

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "AIKA x Shanuzz FMT - Setup Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
    if ($flutterVersion) {
        Write-Host "✓ Flutter is installed: $flutterVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Flutter is not installed" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Run Flutter Doctor
Write-Host "Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor

Write-Host ""

# Check if we're in the right directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Yellow

Write-Host ""

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""

# Check for Chrome
Write-Host "Checking for Chrome browser..." -ForegroundColor Yellow
$chromePath = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue).'(default)'
if ($chromePath -and (Test-Path $chromePath)) {
    Write-Host "✓ Chrome is installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Chrome not found. Please install Chrome for web development." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Deploy the Apps Script (see docs/APPS_SCRIPT_DEPLOYMENT.md)" -ForegroundColor White
Write-Host "2. Add a test user to the Google Sheet" -ForegroundColor White
Write-Host "3. Run the app: flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "For more information, see:" -ForegroundColor Cyan
Write-Host "- README.md - Main documentation" -ForegroundColor White
Write-Host "- docs/QUICK_START.md - Quick start guide" -ForegroundColor White
Write-Host "- docs/DEVELOPMENT.md - Development guide" -ForegroundColor White
Write-Host ""

# Ask if user wants to run the app now
$run = Read-Host "Do you want to run the app now? (y/N)"
if ($run -eq 'y' -or $run -eq 'Y') {
    Write-Host ""
    Write-Host "Starting the app..." -ForegroundColor Green
    flutter run -d chrome
} else {
    Write-Host ""
    Write-Host "You can run the app later with: flutter run -d chrome" -ForegroundColor Yellow
}
