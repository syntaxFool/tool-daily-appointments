# Build and Deploy Script for AIKA x Shanuzz FMT

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('build', 'run', 'clean', 'deploy-preview', 'help')]
    [string]$Action = 'help'
)

function Show-Help {
    Write-Host ""
    Write-Host "AIKA x Shanuzz FMT - Build Script" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\build.ps1 -Action <action>" -ForegroundColor White
    Write-Host ""
    Write-Host "Actions:" -ForegroundColor Yellow
    Write-Host "  build          - Build the app for production" -ForegroundColor White
    Write-Host "  run            - Run the app in development mode" -ForegroundColor White
    Write-Host "  clean          - Clean build artifacts and cache" -ForegroundColor White
    Write-Host "  deploy-preview - Build and preview the production build" -ForegroundColor White
    Write-Host "  help           - Show this help message" -ForegroundColor White
    Write-Host ""
}

function Build-App {
    Write-Host ""
    Write-Host "Building app for production..." -ForegroundColor Yellow
    Write-Host ""
    
    # Clean first
    Write-Host "Cleaning previous builds..." -ForegroundColor Cyan
    flutter clean
    
    # Get dependencies
    Write-Host "Getting dependencies..." -ForegroundColor Cyan
    flutter pub get
    
    # Build
    Write-Host "Building web app..." -ForegroundColor Cyan
    flutter build web --release --web-renderer html
    
    Write-Host ""
    Write-Host "✓ Build complete!" -ForegroundColor Green
    Write-Host "Output directory: build\web" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Test the build locally: .\build.ps1 -Action deploy-preview" -ForegroundColor White
    Write-Host "2. Deploy the 'build\web' folder to your hosting service" -ForegroundColor White
    Write-Host ""
}

function Run-App {
    Write-Host ""
    Write-Host "Running app in development mode..." -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Getting dependencies..." -ForegroundColor Cyan
    flutter pub get
    
    Write-Host ""
    Write-Host "Starting app..." -ForegroundColor Cyan
    Write-Host "Press 'r' to hot reload, 'R' to hot restart, 'q' to quit" -ForegroundColor Gray
    Write-Host ""
    
    flutter run -d chrome --web-renderer html
}

function Clean-App {
    Write-Host ""
    Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
    Write-Host ""
    
    # Flutter clean
    Write-Host "Running flutter clean..." -ForegroundColor Cyan
    flutter clean
    
    # Remove pub cache (optional)
    $removePubCache = Read-Host "Do you want to remove pub cache? (y/N)"
    if ($removePubCache -eq 'y' -or $removePubCache -eq 'Y') {
        Write-Host "Removing pub cache..." -ForegroundColor Cyan
        Remove-Item -Path "$env:LOCALAPPDATA\Pub\Cache" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "✓ Clean complete!" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Preview {
    Write-Host ""
    Write-Host "Building and previewing production build..." -ForegroundColor Yellow
    Write-Host ""
    
    # Build first
    Build-App
    
    # Check if Python is available for simple HTTP server
    Write-Host "Starting preview server..." -ForegroundColor Cyan
    
    $buildPath = Join-Path $PSScriptRoot "build\web"
    
    # Try to use Python's HTTP server
    try {
        $pythonCmd = Get-Command python -ErrorAction Stop
        Write-Host ""
        Write-Host "✓ Server started at http://localhost:8000" -ForegroundColor Green
        Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
        Write-Host ""
        
        Push-Location $buildPath
        python -m http.server 8000
        Pop-Location
    } catch {
        Write-Host ""
        Write-Host "Python not found. Trying alternative method..." -ForegroundColor Yellow
        
        # Fallback: Open in Chrome directly
        $indexPath = Join-Path $buildPath "index.html"
        if (Test-Path $indexPath) {
            Write-Host "Opening build in browser..." -ForegroundColor Cyan
            Start-Process "chrome" "file:///$indexPath"
            Write-Host ""
            Write-Host "⚠ Note: Some features may not work when opening directly from file://" -ForegroundColor Yellow
            Write-Host "For full testing, deploy to a web server or install Python." -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host "✗ Build not found. Run build first." -ForegroundColor Red
        }
    }
}

# Main script execution
switch ($Action) {
    'build' { Build-App }
    'run' { Run-App }
    'clean' { Clean-App }
    'deploy-preview' { Deploy-Preview }
    'help' { Show-Help }
    default { Show-Help }
}
