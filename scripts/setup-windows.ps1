<#
.SYNOPSIS
  Antumbra milestone 0: prepare a Windows build machine.

.DESCRIPTION
  Checks the build drive, creates the directory layout, points Mozilla's
  toolchain cache at the build drive instead of C:, and adds narrowly scoped
  Microsoft Defender exclusions.

  Defender exclusions are limited to the three paths that the build actually
  touches. This script never excludes a whole drive.

.PARAMETER Root
  Build root. Default D:\dev\antumbra.

.PARAMETER DryRun
  Report what would change and exit without changing anything.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1 -DryRun
  # then, in an Administrator PowerShell:
  powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
#>

[CmdletBinding()]
param(
  [string]$Root = 'D:\dev\antumbra',
  [string]$MozillaBuild = 'C:\mozilla-build',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
function Info($m) { Write-Host "[setup] $m" }
function Warn($m) { Write-Host "[setup] WARNING: $m" -ForegroundColor Yellow }
function Bad ($m) { Write-Host "[setup] BLOCKED: $m" -ForegroundColor Red }

$sourceDir  = Join-Path $Root 'firefox'
$statePath  = Join-Path $Root '.mozbuild'
$ok = $true

Info "Build root: $Root"
Info ''

# ---------------------------------------------------------------- path checks
Info '--- Path validation ---'

if ($Root -match '\s') {
  Bad "Path contains a space. Firefox will fail to build. Choose a path without spaces."
  $ok = $false
} else {
  Info 'No spaces in path: OK'
}

if ($Root -match '(?i)onedrive|dropbox|google drive') {
  Bad "Path looks like a cloud-synced folder. A sync client will corrupt builds."
  $ok = $false
} else {
  Info 'Not inside a known sync folder: OK'
}

foreach ($v in 'OneDrive','OneDriveCommercial','OneDriveConsumer') {
  $od = [Environment]::GetEnvironmentVariable($v)
  if ($od -and $Root.StartsWith($od, [StringComparison]::OrdinalIgnoreCase)) {
    Bad "Path is inside `$env:$v ($od)."
    $ok = $false
  }
}

if ($Root.Length -gt 40) {
  Warn "Root path is long ($($Root.Length) chars). Object directory paths may hit Windows path limits."
}

# ------------------------------------------------------------------ free space
Info ''
Info '--- Build drive ---'

$driveLetter = (Split-Path -Qualifier $Root).TrimEnd(':')
$drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
if (-not $drive) {
  Bad "Drive ${driveLetter}: not found."
  $ok = $false
} else {
  $freeGB  = [math]::Round($drive.Free / 1GB, 1)
  $usedGB  = [math]::Round($drive.Used / 1GB, 1)
  $totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 1)
  Info "Drive ${driveLetter}:  $freeGB GB free of $totalGB GB (in use: $usedGB GB)"

  if     ($freeGB -lt 60)  { Bad  "Under 60 GB free. A Firefox build will not complete."; $ok = $false }
  elseif ($freeGB -lt 150) { Warn "Under 150 GB free. Workable, but tight once toolchains, the object directory and sccache land." }
  else                     { Info 'Free space: OK' }
}

$fs = (Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue).FileSystemType
if ($fs) { Info "Filesystem: $fs$(if ($fs -eq 'ReFS') { '  (Dev Drive, 5 to 10 percent faster builds)' })" }

# ------------------------------------------------------------------- hardware
Info ''
Info '--- Hardware ---'
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 0)
Info "CPU: $($cpu.Name.Trim())"
Info "Cores: $($cpu.NumberOfCores) physical, $($cpu.NumberOfLogicalProcessors) logical"
Info "RAM: $ramGB GB"
if ($ramGB -lt 16) { Warn 'Under 16 GB RAM. Reduce the mach job count if a build dies while linking.' }
else { Info "RAM is ample; run mach at the default job count (-j$($cpu.NumberOfLogicalProcessors))." }
Info 'Note: the GPU does not affect build speed. Firefox compilation is CPU and IO bound.'

if (-not $ok) {
  Write-Host ''
  Bad 'Blocking problems above. Nothing was changed.'
  exit 1
}

# ------------------------------------------------------------------- the plan
$exclusions = @($sourceDir, $statePath, $MozillaBuild)

Write-Host ''
Info '--- Changes to apply ---'
Info "Create directory       : $Root"
Info "Create directory       : $sourceDir"
Info "Create directory       : $statePath"
Info "Set user env var       : MOZBUILD_STATE_PATH = $statePath"
foreach ($e in $exclusions) { Info "Defender exclusion     : $e" }
Info 'Defender exclusions are these paths only. The rest of the drive, including games, is untouched.'

if ($DryRun) {
  Write-Host ''
  Info 'DryRun: nothing changed. Re-run without -DryRun in an Administrator PowerShell.'
  exit 0
}

# ------------------------------------------------------------------- apply it
Write-Host ''
Info '--- Applying ---'

foreach ($d in @($Root, $sourceDir, $statePath)) {
  if (Test-Path $d) { Info "Exists: $d" }
  else { New-Item -ItemType Directory -Path $d -Force | Out-Null; Info "Created: $d" }
}

[Environment]::SetEnvironmentVariable('MOZBUILD_STATE_PATH', $statePath, 'User')
$env:MOZBUILD_STATE_PATH = $statePath
Info "Set MOZBUILD_STATE_PATH = $statePath (user scope; open a new shell to pick it up)"

$isAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
  Write-Host ''
  Warn 'Not running as Administrator. Directories and MOZBUILD_STATE_PATH are done.'
  Warn 'Defender exclusions were skipped. Re-run this script from an Administrator PowerShell.'
  exit 0
}

try {
  $current = (Get-MpPreference).ExclusionPath
  foreach ($e in $exclusions) {
    if ($current -contains $e) { Info "Exclusion already present: $e" }
    else { Add-MpPreference -ExclusionPath $e; Info "Added exclusion: $e" }
  }
} catch {
  Warn "Could not set Defender exclusions: $($_.Exception.Message)"
  Warn 'Add them by hand: Windows Security > Virus and threat protection > Manage settings > Exclusions.'
}

Write-Host ''
Info 'Done. Next: install MozillaBuild, then run the bootstrap step in ROADMAP.md milestone 0 step 4.'
