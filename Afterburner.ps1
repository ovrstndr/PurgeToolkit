# === AFTERBURNER: Post-Purge Performance Tuning (Xbox-Safe) ===
# Run as Administrator.

# --- Safety: Restore Point ---
Write-Host ">> Creating restore point..."
Checkpoint-Computer -Description "Afterburner_PreTuning" -RestorePointType "MODIFY_SETTINGS"

# --- Hardware-Accelerated GPU Scheduling (reboot required to take effect) ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f

# --- Game Mode ON (keeps Game Bar, disables background capture for perf) ---
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f

# --- Kill Windows power throttling globally ---
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f

# --- Multimedia scheduler: favor games & remove network throttling ---
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 0xffffffff /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f

# --- Delivery Optimization to 0 (no P2P uploads in background) ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d 0 /f

# --- Ultimate Performance Power Plan ---
# Duplicate the hidden plan if missing, then set active
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 > $null 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61

# --- CPU: unpark cores, boost aggressive, max performance on AC & DC ---
$SCHEME = "SCHEME_CURRENT"
# Core parking (min active cores = 100%)
powercfg -setacvalueindex $SCHEME SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318583 100
powercfg -setdcvalueindex $SCHEME SUB_PROCESSOR 0cc5b647-c1df-4637-891a-dec35c318583 100
# Core parking max cores (also 100% active)
powercfg -setacvalueindex $SCHEME SUB_PROCESSOR ea062031-0e34-4ff1-9b6d-eb1059334028 100
powercfg -setdcvalueindex $SCHEME SUB_PROCESSOR ea062031-0e34-4ff1-9b6d-eb1059334028 100
# Processor idle disable (1 = disable deep idle states)
powercfg -setacvalueindex $SCHEME SUB_PROCESSOR 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
powercfg -setdcvalueindex $SCHEME SUB_PROCESSOR 5d76a2ca-e8c0-402f-a133-2158492d58ad 1
# Performance/Energy preference (0 = max performance)
powercfg -setacvalueindex $SCHEME SUB_PROCESSOR 36687f9e-e3a5-4dbf-b1dc-15eb381c6863 0
powercfg -setdcvalueindex $SCHEME SUB_PROCESSOR 36687f9e-e3a5-4dbf-b1dc-15eb381c6863 0
# Processor boost mode (2 = Aggressive)
powercfg -setacvalueindex $SCHEME SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 2
powercfg -setdcvalueindex $SCHEME SUB_PROCESSOR be337238-0d82-4146-a960-4f3749d470c7 2

# --- Apply plan changes ---
powercfg -SetActive $SCHEME

Write-Host "`n>> Afterburner tuning applied. Reboot now to finalize (HAGS requires restart)."
