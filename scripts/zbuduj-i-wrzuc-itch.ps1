# Buduje APK Godotem (preset Android, jak przy 0.4) i wrzuca na itch.io.
# Albo bierze istniejacy APK gdy -TylkoWrzuc / -UseExisting.
#
# Przyklady:
#   .\scripts\zbuduj-i-wrzuc-itch.ps1 -TylkoWrzuc
#   .\scripts\zbuduj-i-wrzuc-itch.ps1 -DryRun
#   .\scripts\zbuduj-i-wrzuc-itch.ps1
#   .\scripts\zbuduj-i-wrzuc-itch.ps1 -ApkPath "build\NotThatRealLife-0.4.apk" -TylkoWrzuc

param(
    [string]$ApkPath = "",
    [string]$Preset = "Android",
    [string]$Channel = "",
    [string]$UserVersion = "",
    [string]$Game = "",
    [string]$GodotExe = "",
    [switch]$TylkoWrzuc,
    [switch]$UseExisting,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Find-GodotExe {
    param([string]$Hint)
    if ($Hint) {
        if (-not (Test-Path -LiteralPath $Hint)) {
            throw "Brak Godota: $Hint"
        }
        return (Resolve-Path -LiteralPath $Hint).Path
    }
    if ($env:GODOT_EXE -and (Test-Path -LiteralPath $env:GODOT_EXE)) {
        return $env:GODOT_EXE
    }
    $cmd = Get-Command Godot_v*_console.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        return $cmd.Source
    }
    $cmd2 = Get-Command godot -ErrorAction SilentlyContinue
    if ($cmd2) {
        return $cmd2.Source
    }
    $wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $wingetRoot) {
        $found = Get-ChildItem -LiteralPath $wingetRoot -Filter 'Godot_v*_console.exe' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }
    throw 'Nie znaleziono Godota. Ustaw GODOT_EXE albo doinstaluj Godot Engine (winget).'
}

function Get-ExportPathFromPreset {
    $presetFile = Join-Path $root 'export_presets.cfg'
    if (-not (Test-Path -LiteralPath $presetFile)) {
        return (Join-Path $root 'build\NotThatRealLife-0.4.apk')
    }
    $m = Select-String -LiteralPath $presetFile -Pattern '^\s*export_path="([^"]+)"' | Select-Object -First 1
    if ($m) {
        $rel = $m.Matches[0].Groups[1].Value -replace '/', '\'
        if ([System.IO.Path]::IsPathRooted($rel)) {
            return $rel
        }
        return (Join-Path $root $rel)
    }
    return (Join-Path $root 'build\NotThatRealLife-0.4.apk')
}

$skipBuild = $TylkoWrzuc -or $UseExisting

if (-not $ApkPath) {
    $ApkPath = Get-ExportPathFromPreset
}
if (-not [System.IO.Path]::IsPathRooted($ApkPath)) {
    $ApkPath = Join-Path $root $ApkPath
}
$ApkPath = [System.IO.Path]::GetFullPath($ApkPath)

if (-not $skipBuild) {
    $godot = Find-GodotExe -Hint $GodotExe
    $buildDir = Split-Path -Parent $ApkPath
    if (-not (Test-Path -LiteralPath $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir | Out-Null
    }
    Write-Host "Godot:  $godot"
    Write-Host "Preset: $Preset"
    Write-Host "Out:    $ApkPath"
    & $godot --headless --path $root --export-release $Preset $ApkPath
    if ($LASTEXITCODE -ne 0) {
        throw "Eksport Godota zakonczyl sie kodem $LASTEXITCODE"
    }
    if (-not (Test-Path -LiteralPath $ApkPath)) {
        throw "Po eksporcie nadal brak pliku: $ApkPath"
    }
    Write-Host "Zbudowano APK."
} else {
    Write-Host "Pomijam budowanie (-TylkoWrzuc / -UseExisting)."
}

$upload = Join-Path $PSScriptRoot 'itch-upload.ps1'
$argsUpload = @{
    ApkPath = $ApkPath
}
if ($Channel) { $argsUpload.Channel = $Channel }
if ($UserVersion) { $argsUpload.UserVersion = $UserVersion }
if ($Game) { $argsUpload.Game = $Game }
if ($DryRun) { $argsUpload.DryRun = $true }

& $upload @argsUpload