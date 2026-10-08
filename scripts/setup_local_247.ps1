# ==============================================================================
# MT5 Autonomous 24/7 Local Rig Setup Script
# Purpose: Configures Windows to never sleep, configures power profiles,
#          and registers the self-healing MT5 watchdog to start on boot.
# ==============================================================================

Write-Host ">>> Configuring Windows Power & Sleep Profiles for 24/7 Trading..." -ForegroundColor Cyan

# 1. Disable Standby and Hibernate on AC Power
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0

# 2. Turn off display after 5 minutes to conserve power and protect monitor (CPU/RAM stays 100% active)
powercfg /change monitor-timeout-ac 5

Write-Host "✅ Standby & Hibernation disabled on AC power. Display timeout set to 5 min." -ForegroundColor Green

# 3. Create Windows Startup Runner for Watchdog (starts silently in background on login)
$startupFolder = [System.Environment]::GetFolderPath('Startup')
$vbsPath = Join-Path $startupFolder "Start_MT5_Watchdog.vbs"
$watchdogScript = (Resolve-Path "$PSScriptRoot\mt5_watchdog.py").Path

# VBS launcher executes python in background without keeping an open terminal window
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "python `"$watchdogScript`"", 0, False
"@

Set-Content -Path $vbsPath -Value $vbsContent -Encoding ASCII
Write-Host "✅ Startup Launcher registered at: $vbsPath" -ForegroundColor Green

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Yellow
Write-Host ">>> AUTONOMOUS 24/7 LOCAL RIG CONFIGURED SUCCESSFULLY!" -ForegroundColor Yellow
Write-Host "1. MT5 Watchdog will now start automatically whenever your PC turns on." -ForegroundColor White
Write-Host "2. If MT5 crashes or closes, the watchdog will relaunch it within 15 seconds." -ForegroundColor White
Write-Host "3. To start the watchdog right now, run:" -ForegroundColor White
Write-Host "   python $watchdogScript" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Yellow
