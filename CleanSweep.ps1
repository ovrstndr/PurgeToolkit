# === OPERATION CLEAN SWEEP (XBOX-SAFE) ===
# Run as Administrator. Creates restore point first.

Write-Host ">> Creating system restore point..."
Checkpoint-Computer -Description "Pre-CleanSweep" -RestorePointType "MODIFY_SETTINGS"

# --- Stop and disable telemetry services ---
Stop-Service DiagTrack -Force
Set-Service DiagTrack -StartupType Disabled
Stop-Service dmwappushservice -Force
Set-Service dmwappushservice -StartupType Disabled

# --- Kill Edge background + Bing search integration ---
reg add "HKCU\Software\Microsoft\Edge" /v "StartupBoostEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Edge\BackgroundModeEnabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f

# --- Remove standard bloat but KEEP Xbox & Gaming Services ---
$apps = @(
  "Microsoft.ZuneMusic",
  "Microsoft.ZuneVideo",
  "Microsoft.Microsoft3DViewer",
  "Microsoft.MicrosoftSolitaireCollection",
  "Microsoft.People",
  "Microsoft.BingNews",
  "Microsoft.BingWeather",
  "Microsoft.MixedReality.Portal",
  "Microsoft.OneConnect",
  "Microsoft.GetHelp",
  "Microsoft.Getstarted",
  "Microsoft.MicrosoftOfficeHub",
  "Microsoft.SkypeApp",
  "Microsoft.Todos",
  "Microsoft.YourPhone",
  "MicrosoftTeams",
  "Microsoft.MicrosoftStickyNotes"
)
foreach ($app in $apps) {
  Get-AppxPackage -AllUsers $app | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# --- Disable telemetry tasks ---
$tasks = @(
  "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
  "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
  "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
  "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
  "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
)
foreach ($task in $tasks) { schtasks /Change /TN $task /Disable }

# --- Disable inventory collector ---
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f

# --- Disable OneDrive auto start (but keep app if you use it manually) ---
reg add "HKCU\Software\Microsoft\OneDrive" /v "DisablePersonalSync" /t REG_DWORD /d 1 /f

# --- Clean system components and optimize image ---
Dism.exe /Online /Cleanup-Image /StartComponentCleanup

Write-Host "`n>> Clean Sweep complete. Reboot recommended."
