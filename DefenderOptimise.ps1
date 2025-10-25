### DefenderOptimise.ps1 ###
# Author: Gabriel Gonzalez
# License: MIT
# Use at your own risk. Creates restore points automatically.


# === DEFENDER OPTIMISE ===
Write-Host ">> Creating restore point for Defender tuning..."
Checkpoint-Computer -Description "DefenderOptimise_Pre" -RestorePointType "MODIFY_SETTINGS"

# Real-time & on-access
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableOnAccessProtection $false

# Cloud protection & aggressive blocking
Set-MpPreference -CloudBlockLevel High
Set-MpPreference -MAPSReporting Advanced   # chooses more data sharing for cloud
Set-MpPreference -SubmitSamplesConsent SendSafeSamples

# Controlled Folder Access (enable, and only allow trusted apps later)
Set-MpPreference -EnableControlledFolderAccess Enabled

# Exclusions: none added by default; add only your trusted paths later
# Placeholder (remove comment when you know the exact path): 
# Set-MpPreference -ExclusionPath "C:\Your\Trusted\Path"

# Performance tuning: limit CPU load for full scans (for your gaming/creative rig)
Set-MpPreference -ScanAvgCPULoadFactor 30  # aim to keep full scan avg CPU ~30%
Set-MpPreference -DisableArchiveScanning $false  # leave archive scanning ON

Write-Host "`n>> Defender optimisation applied. Reboot recommended."

