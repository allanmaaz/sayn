# ==============================================================================
# SAYN Terminal Quick-Install Script for Windows (PowerShell)
# One-command automated installation: irm https://sayn.ai/install.ps1 | iex
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "   ____    _ __   ___   _ " -ForegroundColor DarkRed
Write-Host "  / ___)  / _  \ \   \ | |" -ForegroundColor DarkRed
Write-Host "  \___ \ / /_\  \ |   \| |" -ForegroundColor DarkRed
Write-Host "  ____) )  ___   \| |\   |" -ForegroundColor DarkRed
Write-Host " (_____/|_/   \_|_|_| \__|" -ForegroundColor DarkRed
Write-Host ""
Write-Host " SAYN — The Intelligent Voice Assistant" -ForegroundColor Yellow
Write-Host " https://sayn.ai • Native Windows Quick-Install" -ForegroundColor Gray
Write-Host ""

$is64Bit = [Environment]::Is64BitOperatingSystem
$installerName = if ($is64Bit) { "SAYN-Setup-1.1.0-x64.exe" } else { "SAYN-Setup-1.1.0-ia32.exe" }
$downloadUrl = "https://github.com/allanmaaz/sayn/releases/latest/download/$installerName"
$tempPath = Join-Path $env:TEMP $installerName

Write-Host "➜ Detected Windows $(if ($is64Bit) { '64-bit (x64)' } else { '32-bit (x86)' })" -ForegroundColor Cyan
Write-Host "➜ Downloading latest SAYN release..." -ForegroundColor Cyan

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
} catch {
    Write-Host "Error downloading SAYN installer: $_" -ForegroundColor Red
    exit 1
}

Write-Host "➜ Running silent installer..." -ForegroundColor Cyan
try {
    Start-Process -FilePath $tempPath -ArgumentList "/S" -Wait
    Write-Host ""
    Write-Host "✓ SAYN installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "• Trigger SAYN voice dictation anywhere by pressing Alt + Space" -ForegroundColor Gray
    Write-Host "• Enjoy private, zero-latency voice typing and AI polishing!" -ForegroundColor Gray

    # Launch SAYN if installed to default LocalAppData
    $installedExe = Join-Path $env:LOCALAPPDATA "Programs\sayn\SAYN.exe"
    if (Test-Path $installedExe) {
        Start-Process -FilePath $installedExe
    }
} catch {
    Write-Host "Setup completed. Please launch SAYN from your Start Menu." -ForegroundColor Yellow
} finally {
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
    }
}
