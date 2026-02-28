param(
  [string]$Platform
)

$ErrorActionPreference = 'Stop'

function Write-Warn($msg) {
  Write-Host "⚠️  $msg" -ForegroundColor Yellow
}

function Ask-YesNo($prompt) {
  while ($true) {
    $r = Read-Host "$prompt [y/n]"
    if ($r -match '^(?i)y(es)?$') { return $true }
    if ($r -match '^(?i)n(o)?$') { return $false }
  }
}

function Detect-Platform {
  param([string]$InputPlatform)
  if ($InputPlatform) { return $InputPlatform }

  if ($IsWindows) {
    if ([Environment]::Is64BitOperatingSystem) { return 'windows-x64' }
    return 'windows-x86'
  }

  return 'windows-x64'
}

$Platform = Detect-Platform -InputPlatform $Platform
Write-Host "=== Bootstrap tom_build_kit binaries ($Platform) ==="

$home = [Environment]::GetFolderPath('UserProfile')
$tacLink = Join-Path $home 'tac'
$workspaceHint = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

$profileChanged = $false
$envChanged = $false
$pathChanged = $false

if (-not (Test-Path $tacLink)) {
  Write-Warn "No $tacLink symlink exists."
  $target = Read-Host "Enter workspace directory for $tacLink [$workspaceHint]"
  if (-not $target) { $target = $workspaceHint }
  New-Item -ItemType SymbolicLink -Path $tacLink -Target $target | Out-Null
  Write-Host "Created symlink: $tacLink -> $target"
}

$tomBinaries = Join-Path $tacLink 'tom_binaries'
if (-not (Test-Path $tomBinaries)) {
  Write-Warn "No tom_binaries directory found in $tacLink"
  if (Ask-YesNo "Clone tom_binaries into $tomBinaries?") {
    git clone https://github.com/al-the-bear/tom_binaries.git $tomBinaries
  } else {
    throw 'Aborted: tom_binaries repository is required.'
  }
}

$defaultTomBinaryPath = Join-Path $tomBinaries 'tom'
$tomBinaryPath = $env:TOM_BINARY_PATH
if (-not $tomBinaryPath) {
  Write-Warn 'TOM_BINARY_PATH is not defined.'
  if (Ask-YesNo "Set TOM_BINARY_PATH to $defaultTomBinaryPath for current user?") {
    setx TOM_BINARY_PATH "$defaultTomBinaryPath" | Out-Null
    $env:TOM_BINARY_PATH = $defaultTomBinaryPath
    $tomBinaryPath = $defaultTomBinaryPath
    $envChanged = $true
    Write-Warn 'User environment updated. Existing terminals/apps may need restart.'
  } else {
    throw 'Aborted: TOM_BINARY_PATH is required.'
  }
}

$platformDir = Join-Path $tomBinaryPath $Platform
if (-not (Test-Path $platformDir)) {
  Write-Warn "Missing platform directory: $platformDir"
  if (Ask-YesNo "Create $platformDir?") {
    New-Item -ItemType Directory -Path $platformDir -Force | Out-Null
  } else {
    throw 'Aborted: platform output directory is required.'
  }
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $userPath) { $userPath = '' }
if ($userPath -notlike "*$platformDir*") {
  Write-Warn "$platformDir is not in user PATH"
  if (Ask-YesNo "Add $platformDir to user PATH?") {
    $newPath = if ($userPath) { "$userPath;$platformDir" } else { $platformDir }
    setx PATH "$newPath" | Out-Null
    $env:Path = "$env:Path;$platformDir"
    $pathChanged = $true
    Write-Warn 'PATH updated for user profile. Existing terminals/apps may need restart.'
  }
}

Write-Host "Compiling tools to $platformDir"
Set-Location $PSScriptRoot

if (-not (Test-Path 'lib/src/version.versioner.dart')) {
@'
// GENERATED FILE - DO NOT EDIT
// Bootstrap stub - will be regenerated

class BuildkitVersionInfo {
  BuildkitVersionInfo._();
  static const String version = '0.0.0';
  static const String buildTime = '1970-01-01T00:00:00.000000Z';
  static const String gitCommit = 'bootstrap';
  static const int buildNumber = 0;
  static const String dartSdkVersion = 'unknown';
  static String get versionShort => '$version+$buildNumber';
  static String get versionMedium => '$version+$buildNumber.$gitCommit ($buildTime)';
  static String get versionLong => '$version+$buildNumber.$gitCommit ($buildTime) [Dart $dartSdkVersion]';
}
'@ | Set-Content -Path 'lib/src/version.versioner.dart' -Encoding UTF8
}

dart run bin/buildkit.dart --scan . --no-recursive :versioner --variable-prefix buildkit

$tools = @('buildkit','findproject')
foreach ($tool in $tools) {
  $entry = "bin/$tool.dart"
  if (-not (Test-Path $entry)) {
    Write-Warn "$entry not found, skipping"
    continue
  }
  dart compile exe $entry -o (Join-Path $platformDir $tool)
}

Write-Host "=== Bootstrap complete ==="

if ($profileChanged -or $envChanged -or $pathChanged) {
  Write-Host ''
  Write-Host '############################################################' -ForegroundColor Red
  Write-Host '# ALERT: Shell/environment settings were changed.          #' -ForegroundColor Red
  Write-Host '# Restart terminals and apps to ensure setup is available. #' -ForegroundColor Red
  Write-Host '############################################################' -ForegroundColor Red
}
