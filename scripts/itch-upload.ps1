# Wrzuca gotowe APK na itch.io przez butler (kanal android).
# Wymaga: butler w PATH, ITCH_USER (env / scripts/itch.env), butler login ALBO ITCH_API_KEY.
#
# Przyklady:
#   .\scripts\itch-upload.ps1
#   .\scripts\itch-upload.ps1 -ApkPath "build\NotThatRealLife-0.4.apk" -DryRun
#   .\scripts\itch-upload.ps1 -UserVersion "0.4"

param(
    [string]$ApkPath = "",
    [string]$Channel = "",
    [string]$UserVersion = "",
    [string]$Game = "",
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))

function Import-ItchEnv {
    $envFile = Join-Path $PSScriptRoot 'itch.env'
    if (-not (Test-Path -LiteralPath $envFile)) {
        return
    }
    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) {
            return
        }
        $eq = $line.IndexOf('=')
        if ($eq -lt 1) {
            return
        }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim().Trim('"').Trim("'")
        if (-not [string]::IsNullOrWhiteSpace($key) -and -not [Environment]::GetEnvironmentVariable($key)) {
            Set-Item -Path "Env:$key" -Value $val
        }
    }
}

function Find-ButlerExe {
    $cmd = Get-Command butler -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }
    $kandydaci = @(
        (Join-Path $env:LOCALAPPDATA 'butler\butler.exe'),
        (Join-Path $env:USERPROFILE '.config\itch\butler.exe')
    )
    foreach ($c in $kandydaci) {
        if (Test-Path -LiteralPath $c) {
            return $c
        }
    }
    throw 'Nie znaleziono butler.exe. Zainstaluj: https://itch.io/docs/butler/ (Windows: zip z broth.itch.zone -> %LOCALAPPDATA%\butler)'
}

function Resolve-ApkPath {
    param([string]$Hint)
    if ($Hint) {
        $p = if ([System.IO.Path]::IsPathRooted($Hint)) { $Hint } else { Join-Path $root $Hint }
        if (-not (Test-Path -LiteralPath $p)) {
            throw "Brak APK: $p"
        }
        return [System.IO.Path]::GetFullPath($p)
    }
    $domyslne = Join-Path $root 'build\NotThatRealLife-0.4.apk'
    if (Test-Path -LiteralPath $domyslne) {
        return $domyslne
    }
    $najnowsze = Get-ChildItem -LiteralPath (Join-Path $root 'build') -Filter '*.apk' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($najnowsze) {
        return $najnowsze.FullName
    }
    throw 'Brak APK w build\. Zbuduj gre albo podaj -ApkPath.'
}

function Get-VersionFromPreset {
    $preset = Join-Path $root 'export_presets.cfg'
    if (-not (Test-Path -LiteralPath $preset)) {
        return ''
    }
    $m = Select-String -LiteralPath $preset -Pattern '^\s*version/name="([^"]+)"' | Select-Object -First 1
    if ($m) {
        return $m.Matches[0].Groups[1].Value
    }
    return ''
}

Import-ItchEnv

$user = $env:ITCH_USER
if ([string]::IsNullOrWhiteSpace($user)) {
    throw 'Ustaw ITCH_USER (env albo skopiuj scripts\itch.env.example -> scripts\itch.env).'
}

if (-not $Game) {
    $Game = if ($env:ITCH_GAME) { $env:ITCH_GAME } else { 'not-that-real-life' }
}
if (-not $Channel) {
    $Channel = if ($env:ITCH_CHANNEL) { $env:ITCH_CHANNEL } else { 'android' }
}

$apk = Resolve-ApkPath -Hint $ApkPath
if (-not $UserVersion) {
    $UserVersion = Get-VersionFromPreset
}

$butler = Find-ButlerExe
& $butler --version | Out-Host

$staging = Join-Path $root 'build\itch-android-stage'
if (Test-Path -LiteralPath $staging) {
    Remove-Item -LiteralPath $staging -Recurse -Force
}
New-Item -ItemType Directory -Path $staging | Out-Null
Copy-Item -LiteralPath $apk -Destination (Join-Path $staging (Split-Path -Leaf $apk))

$target = "{0}/{1}:{2}" -f $user, $Game, $Channel
Write-Host "APK:    $apk"
Write-Host "Target: $target"
if ($UserVersion) {
    Write-Host "Wersja: $UserVersion"
}

$apiKey = $env:ITCH_API_KEY
if (-not $apiKey) {
    $apiKey = $env:BUTLER_API_KEY
}

$identityArgs = @()
$tempIdentity = $null
if ($apiKey) {
    $tempIdentity = Join-Path $env:TEMP ("butler_identity_" + [guid]::NewGuid().ToString('N') + '.txt')
    Set-Content -LiteralPath $tempIdentity -Value $apiKey -NoNewline -Encoding ascii
    $identityArgs = @('--identity', $tempIdentity)
    Write-Host 'Auth:  ITCH_API_KEY / BUTLER_API_KEY (sesja)'
} else {
    Write-Host 'Auth:  butler login (plik credentials)'
}

$pushArgs = @('push') + $identityArgs
if ($DryRun) {
    $pushArgs += '--dry-run'
}
if ($UserVersion) {
    $pushArgs += @('--userversion', $UserVersion)
}
$pushArgs += @($staging, $target)

try {
    & $butler @pushArgs
    if ($LASTEXITCODE -ne 0) {
        throw "butler push zakonczyl sie kodem $LASTEXITCODE"
    }
} finally {
    if ($tempIdentity -and (Test-Path -LiteralPath $tempIdentity)) {
        Remove-Item -LiteralPath $tempIdentity -Force -ErrorAction SilentlyContinue
    }
}

if ($DryRun) {
    Write-Host 'Dry-run OK (nic nie wyslano).'
} else {
    Write-Host ("Wyslano. Link dla ziomka: https://{0}.itch.io/{1}" -f $user, $Game)
}