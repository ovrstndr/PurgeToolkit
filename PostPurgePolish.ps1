# === POST-PURGE POLISH (PowerShell-native) ===
# Run as Administrator. Safe cleanup + QoL polish + gold restore point.

# ----- Setup: logging -----
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = "$env:USERPROFILE\OneDrive\Documents\PostPurgeLogs"
$new = New-Item -ItemType Directory -Path $logDir -Force
$log = Join-Path $logDir "PostPurge_$stamp.txt"
"Post-Purge Polish started $stamp" | Out-File $log

Function Write-Log($msg){ $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg; $line | Tee-Object -FilePath $log -Append }

# ----- Safety: restore point -----
Write-Log "Creating restore point..."
Checkpoint-Computer -Description "PostPurgePolish_Begin_$stamp" -RestorePointType MODIFY_SETTINGS

# ----- Component Store (WinSxS) -----
Write-Log "Analyzing component store..."
Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore | Tee-Object -FilePath $log -Append | Out-Null
Write-Log "Running StartComponentCleanup..."
Dism.exe /Online /Cleanup-Image /StartComponentCleanup | Tee-Object -FilePath $log -Append | Out-Null

# ----- Temp & cache hygiene (PowerShell-native) -----
Write-Log "Clearing user temp..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Log "Clearing system temp..."
Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Log "Clearing Prefetch (safe skip on locked files)..."
Remove-Item "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Log "Clearing Windows Error Reporting queues..."
Remove-Item "$env:ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue

# Optional: Windows Update download cache (keeps update metadata; only temp downloads)
Write-Log "Clearing Windows Update Download cache..."
Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

# Optional: old Defender scan history (does NOT remove definitions)
Write-Log "Clearing old Defender scan history (optional)..."
$defHist = "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service"
if (Test-Path $defHist){ Remove-Item "$defHist\*" -Recurse -Force -ErrorAction SilentlyContinue }

# ----- Recycle Bin -----
Write-Log "Emptying Recycle Bin..."
try { Clear-RecycleBin -Force -ErrorAction Stop } catch { Write-Log "Recycle Bin cleanup skipped: $($_.Exception.Message)" }

# ----- SSD / Drive optimization -----
Write-Log "Optimizing fixed drives (SSD TRIM / HDD optimize)..."
Get-Volume -DriveType Fixed | ForEach-Object {
  $dl = $_.DriveLetter
  if (!$dl) { return }
  try {
    Optimize-Volume -DriveLetter $dl -ReTrim -ErrorAction Stop | Out-Null
    Write-Log "Optimized drive ${dl}:"
  } catch {
    try {
      Optimize-Volume -DriveLetter $dl -Optimize -ErrorAction Stop | Out-Null
      Write-Log "Optimized (HDD) drive ${dl}."
    } catch {
      Write-Log "Optimize skipped on ${dl}: $($_.Exception.Message)"
    }
  }
}

# ----- QoL / Aesthetic polish (no background bloat) -----
Write-Log "Applying dark mode + reducing tips/ads..."
# Dark mode
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f | Out-Null
# Kill suggestions/ads
$cdm = "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
reg add $cdm /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f | Out-Null
reg add $cdm /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f | Out-Null
reg add $cdm /v "SilentInstalledAppsEnabled"      /t REG_DWORD /d 0 /f | Out-Null
reg add $cdm /v "SystemPaneSuggestionsEnabled"    /t REG_DWORD /d 0 /f | Out-Null

# ----- Finish: gold restore point -----
Write-Log "Creating GOLD restore point..."
Checkpoint-Computer -Description "PostPurgePolish_GOLD_$stamp" -RestorePointType MODIFY_SETTINGS

Write-Log "Post-Purge Polish complete. Reboot recommended."
Write-Host "`n>> Post-Purge Polish complete. Reboot recommended. Log: $log"
