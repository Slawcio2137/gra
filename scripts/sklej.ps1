# Kolejna wersja projektu to git add i git commit. Zapisuje się tylko zmiana,
# więc nie powstaje druga kopia tych samych plików.
# sklej.ps1 odtwarza całość z historii gita, gdyby folder roboczy się zepsuł.
# Podajesz pusty albo nowy folder argumentem -Do. Przykład:
#   .\scripts\sklej.ps1 -Do "C:\Not that real life sklejone"

param(
    [Parameter(Mandatory = $true)]
    [string]$Do
)

$ErrorActionPreference = 'Stop'

function Test-SciezkaWewnatrz {
    param(
        [string]$Sciezka,
        [string]$Rodzic
    )
    $p = $Sciezka.TrimEnd('\')
    $a = $Rodzic.TrimEnd('\')
    if ($p.Equals($a, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $p.StartsWith($a + '\', [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-GitExe {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        return $cmd.Source
    }
    $kandydaci = @(
        'C:\Program Files\Git\cmd\git.exe',
        'C:\Program Files (x86)\Git\cmd\git.exe'
    )
    if ($env:LOCALAPPDATA) {
        $kandydaci += (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
    }
    foreach ($c in $kandydaci) {
        if (Test-Path -LiteralPath $c) {
            return $c
        }
    }
    throw 'Nie znaleziono git.exe. Doinstaluj: winget install --id Git.Git -e'
}

$root = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$dest = [System.IO.Path]::GetFullPath($Do)

if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    throw "Nie widzę repozytorium gita w: $root"
}

$chronione = @(
    'C:\Not that real life actuall',
    'C:\Not that real life 0.1'
)
foreach ($c in $chronione) {
    if (Test-SciezkaWewnatrz -Sciezka $dest -Rodzic $c) {
        throw "Tej ścieżki nie ruszam, to istniejąca kopia: $c"
    }
}
if (Test-SciezkaWewnatrz -Sciezka $dest -Rodzic $root) {
    throw "Cel nie może leżeć w folderze roboczym: $root"
}
if (Test-SciezkaWewnatrz -Sciezka $root -Rodzic $dest) {
    throw "Cel nie może być folderem nadrzędnym repozytorium: $dest"
}

if (Test-Path -LiteralPath $dest) {
    if (-not (Test-Path -LiteralPath $dest -PathType Container)) {
        throw "Cel nie jest folderem: $dest"
    }
    if (Get-ChildItem -LiteralPath $dest -Force | Select-Object -First 1) {
        throw "Folder docelowy nie jest pusty: $dest"
    }
} else {
    [System.IO.Directory]::CreateDirectory($dest) | Out-Null
}

$git = Get-GitExe
& $git -C $root rev-parse --verify HEAD | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'W historii gita nie ma jeszcze żadnego commita.'
}

$zip = Join-Path ([System.IO.Path]::GetTempPath()) ('sklej-' + [guid]::NewGuid().ToString('n') + '.zip')
try {
    & $git -C $root archive --format=zip --output $zip HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "git archive zakończyło się kodem $LASTEXITCODE."
    }
    $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
    & $tar -xf $zip -C $dest
    if ($LASTEXITCODE -ne 0) {
        throw "Rozpakowanie zakończyło się kodem $LASTEXITCODE."
    }
} finally {
    if (Test-Path -LiteralPath $zip) {
        Remove-Item -LiteralPath $zip -Force
    }
}

Write-Output "Złożono pełny stan z historii gita do: $dest"
