$ErrorActionPreference = 'Stop'
$root = 'C:\Not that real life'
$xlsxDir = Join-Path $root '_pobieranie\_xlsx'
$outRoot = Join-Path $root 'świat\polska'
$outMiasta = Join-Path $outRoot 'miasta'
$outReszta = Join-Path $outRoot 'reszta_powiatu'

function Get-SharedStrings([string]$path) {
    [xml]$xml = Get-Content -LiteralPath $path -Encoding UTF8
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('m', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($si in $xml.SelectNodes('//m:si', $ns)) {
        $parts = foreach ($t in $si.SelectNodes('.//m:t', $ns)) { $t.InnerText }
        $list.Add(($parts -join ''))
    }
    return $list
}

function Get-SheetRows([string]$path, $shared) {
    [xml]$xml = Get-Content -LiteralPath $path -Encoding UTF8
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('m', 'http://schemas.openxmlformats.org/spreadsheetml/2006/main')
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($row in $xml.SelectNodes('//m:sheetData/m:row', $ns)) {
        $map = @{}
        foreach ($c in $row.SelectNodes('m:c', $ns)) {
            $col = ($c.r -replace '\d', '')
            $raw = $c.v
            if ($c.t -eq 's' -and $null -ne $raw -and $raw -ne '') {
                $map[$col] = [string]$shared[[int]$raw]
            } else {
                $map[$col] = [string]$raw
            }
        }
        $rows.Add($map)
    }
    return $rows
}

function Norm([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return '' }
    return (($s.Trim() -replace '\s+', ' ').ToLowerInvariant())
}

function To-Int([string]$s) {
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    $n = 0
    if ([int]::TryParse($s, [ref]$n)) { return $n }
    return $null
}

function Write-JsonFile([string]$path, $obj) {
    $json = $obj | ConvertTo-Json -Depth 8
    $json = [regex]::Replace($json, '\\u([0-9a-fA-F]{4})', {
        param($m)
        [string][char][Convert]::ToInt32($m.Groups[1].Value, 16)
    })
    $json = [regex]::Replace($json, '"metropolie":\s+null', '"metropolie":  []')
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($path, $json + "`n", $utf8)
}

function Pretty-Woj([string]$s) {
    $ci = [cultureinfo]::GetCultureInfo('pl-PL')
    $lower = $s.ToLower($ci)
    $bits = $lower -split '(-)'
    $out = foreach ($bit in $bits) {
        if ($bit -eq '-') { '-' }
        elseif ($bit.Length -gt 0) { $bit.Substring(0, 1).ToUpper($ci) + $bit.Substring(1) }
    }
    return ($out -join '')
}

function Crime-Block([string]$uwaga) {
    return [ordered]@{
        zakres = 'niedostepny'
        rok = $null
        zrodlo = $null
        na_1000_mieszkancow = [ordered]@{
            kradziez_cudzej_rzeczy = $null
            zgwalcenie = $null
            rozboj_kradziez_i_wymuszenie_rozbojnicze = $null
            bojka_i_pobicie = $null
        }
        liczba = [ordered]@{
            kradziez_cudzej_rzeczy = $null
            zgwalcenie = $null
            rozboj_kradziez_i_wymuszenie_rozbojnicze = $null
            bojka_i_pobicie = $null
        }
        kategoria_niedostepna = 'Atak z niebezpiecznym narzędziem albo bronią nie jest osobną kategorią w danych Policji publikowanych przez GUS. Najbliższe oficjalne nazwy to rozbój oraz bójka i pobicie, i też tylko dla całego powiatu.'
        uwaga = $uwaga
    }
}

$uwagaMiastoWPowiecie = 'To jest samo miasto powiatowe. Policja i GUS podają przestępstwa dla całego powiatu razem z okolicznymi gminami, więc nie wpisałem tu liczb miasta ani „centrum”.'
$uwagaReszta = 'To są gminy powiatu bez miasta powiatowego. Policja nie podaje przestępstw osobno dla tych gmin ani dla wsi, więc liczby zostają puste. Nie dzieliłem statystyki całego powiatu na oko.'
$uwagaMiastoPowiat = 'To miasto jest całym powiatem (miasto na prawach powiatu). Gdy dojdą dane Policji, będą dotyczyły całego miasta, a nie samego centrum i nie osobnych wsi.'

$shared = Get-SharedStrings (Join-Path $xlsxDir 'xl_sharedStrings.xml')
$powiatRows = Get-SheetRows (Join-Path $xlsxDir 'xl_worksheets_sheet3.xml') $shared
$gminaRows = Get-SheetRows (Join-Path $xlsxDir 'xl_worksheets_sheet20.xml') $shared

$powiatPop = @{}
foreach ($row in $powiatRows) {
    $id = [string]$row['A']
    if ($id -match '^\d{4}$') {
        $powiatPop[$id] = To-Int $row['E']
    }
}

$gminy = New-Object System.Collections.Generic.List[object]
foreach ($row in $gminaRows) {
    $a = ([string]$row['A']).Trim()
    $gmi = $null
    $rodz = $null
    if ($a -match '^(\d{6})\s+(\d)$') {
        $gmi = $Matches[1]
        $rodz = $Matches[2]
    } elseif ($a -match '^(\d{6})(\d)$') {
        $gmi = $Matches[1]
        $rodz = $Matches[2]
    } else {
        continue
    }
    $gminy.Add([pscustomobject]@{
        id = "$gmi$rodz"
        gmina = $gmi
        powiat = $gmi.Substring(0, 4)
        woj = $gmi.Substring(0, 2)
        rodzaj = $rodz
        nazwa = ([string]$row['B']).Trim()
        ludnosc = To-Int $row['E']
        powierzchnia_km2 = To-Int $row['D']
    })
}

$terc = Import-Csv -LiteralPath (Join-Path $root '_pobieranie\TERC_Urzedowy.csv') -Delimiter ';' -Encoding UTF8
$wojNazwa = @{}
$powiatNazwa = @{}
$miastaPrawa = @{}
foreach ($r in $terc) {
    if ([string]::IsNullOrWhiteSpace($r.POW)) {
        $wojNazwa[$r.WOJ] = $r.NAZWA
    } elseif ([string]::IsNullOrWhiteSpace($r.GMI)) {
        $kod = '{0}{1}' -f $r.WOJ, $r.POW
        $powiatNazwa[$kod] = $r.NAZWA
        if ($r.NAZWA_DOD -like '*prawach powiatu*') {
            $miastaPrawa[$kod] = $r.NAZWA
        }
    }
}

$fixSeat = @{
    '3022' = 'Rawicz'
    '3218' = 'Łobez'
    '3206' = 'Gryfino'
    '2802' = 'Braniewo'
    '2205' = 'Kartuzy'
    '0217' = 'Strzelin'
}
$seats = @{}
$wd = Get-Content -LiteralPath (Join-Path $root '_pobieranie\siedziby.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($b in $wd.results.bindings) {
    $kod = $b.teryt.value
    $nazwa = $b.seatLabel.value
    if ($fixSeat.ContainsKey($kod)) { $nazwa = $fixSeat[$kod] }
    $seats[$kod] = $nazwa
}

$byPowiat = $gminy | Group-Object powiat

if (Test-Path $outMiasta) { Remove-Item -LiteralPath $outMiasta -Recurse -Force }
if (Test-Path $outReszta) { Remove-Item -LiteralPath $outReszta -Recurse -Force }
New-Item -ItemType Directory -Force -Path $outMiasta, $outReszta | Out-Null

$problemy = New-Object System.Collections.Generic.List[string]
$indeksMiasta = New-Object System.Collections.Generic.List[object]
$indeksReszta = New-Object System.Collections.Generic.List[object]
$poza = 0
$wSrodku = 0

foreach ($kod in ($powiatPop.Keys | Sort-Object)) {
    $grupa = @($byPowiat | Where-Object { $_.Name -eq $kod } | Select-Object -ExpandProperty Group)
    $pelne = @($grupa | Where-Object { $_.rodzaj -in @('1', '2', '3') })
    $sumaPelne = ($pelne | Measure-Object ludnosc -Sum).Sum
    if ($null -eq $sumaPelne) { $sumaPelne = 0 }
    if ($sumaPelne -ne $powiatPop[$kod]) {
        $problemy.Add("Suma gmin $kod = $sumaPelne, tablica powiatów = $($powiatPop[$kod])")
    }

    $woj = Pretty-Woj $wojNazwa[$kod.Substring(0, 2)]
    $nazwaPow = $powiatNazwa[$kod]

    if ($miastaPrawa.ContainsKey($kod)) {
        $miastoGmina = @($pelne | Where-Object { $_.rodzaj -eq '1' })
        if ($miastoGmina.Count -ne 1) {
            $problemy.Add("Miasto na prawach powiatu $kod ma $($miastoGmina.Count) gmin miejskich")
            continue
        }
        $m = $miastoGmina[0]
        $obj = [ordered]@{
            id = $m.id
            nazwa = $m.nazwa
            typ = 'miasto'
            panstwo = 'Polska'
            wojewodztwo = $woj
            powiat_id = $kod
            powiat_nazwa = $nazwaPow
            liczba_mieszkancow = $m.ludnosc
            powierzchnia_km2 = $m.powierzchnia_km2
            stan_podzialu = '2026-01-01'
            zrodlo_ludnosci = 'GUS, Powierzchnia i ludność w przekroju terytorialnym w 2026 r., tabl. 19'
            reszta_powiatu = $null
            dostep_transportu_publicznego = $null
            cena_transportu_publicznego = $null
            przestepczosc = Crime-Block $uwagaMiastoPowiat
        }
        Write-JsonFile (Join-Path $outMiasta ($m.id + '.json')) $obj
        $indeksMiasta.Add([ordered]@{ id = $m.id; nazwa = $m.nazwa; powiat_id = $kod; wojewodztwo = $woj; liczba_mieszkancow = $m.ludnosc; plik = "miasta/$($m.id).json" })
        continue
    }

    if (-not $seats.ContainsKey($kod)) {
        $problemy.Add("Brak siedziby dla powiatu $kod $nazwaPow")
        continue
    }
    $seatName = $seats[$kod]
    $kandydaci = @($grupa | Where-Object { (Norm $_.nazwa) -eq (Norm $seatName) -and $_.rodzaj -in @('1', '4', '3') })
    $wybrane = $null
    foreach ($r in @('1', '4', '3')) {
        $hit = @($kandydaci | Where-Object { $_.rodzaj -eq $r })
        if ($hit.Count -ge 1) { $wybrane = $hit[0]; break }
    }

    if ($null -eq $wybrane) {
        $miastoZewn = $null
        foreach ($mk in $miastaPrawa.Keys) {
            if ((Norm $miastaPrawa[$mk]) -eq (Norm $seatName)) { $miastoZewn = $mk; break }
        }
        if ($null -eq $miastoZewn) {
            $problemy.Add("Nie znaleziono siedziby '$seatName' w powiecie $kod $nazwaPow ani wśród miast na prawach powiatu")
            continue
        }
        $poza++
        $obj = [ordered]@{
            id = $kod
            nazwa = $nazwaPow
            typ = 'wies'
            panstwo = 'Polska'
            wojewodztwo = $woj
            miasto_powiatowe_poza_powiatem = $true
            siedziba_nazwa = $seatName
            siedziba_powiat_id = $miastoZewn
            liczba_mieszkancow = $sumaPelne
            dostep_transportu_publicznego = $null
            cena_transportu_publicznego = $null
            srednia_odleglosc_ludzi_od_miasta_powiatowego_km = $null
            srednia_odleglosc_metoda = 'Nie ma punktów ludności z odległością do siedziby powiatu. Nie liczone z powierzchni ani z linii prostej.'
            stan_podzialu = '2026-01-01'
            zrodlo_ludnosci = 'GUS, Powierzchnia i ludność w przekroju terytorialnym w 2026 r., tabl. 19. Suma gmin rodzaju 1, 2 i 3.'
            przestepczosc = Crime-Block $uwagaReszta
        }
        Write-JsonFile (Join-Path $outReszta ($kod + '.json')) $obj
        $indeksReszta.Add([ordered]@{ id = $kod; nazwa = $nazwaPow; wojewodztwo = $woj; siedziba = $seatName; liczba_mieszkancow = $sumaPelne; plik = "reszta_powiatu/$kod.json" })
        continue
    }

    if ($wybrane.rodzaj -eq '3') {
        $town = @($grupa | Where-Object { $_.gmina -eq $wybrane.gmina -and $_.rodzaj -eq '4' })
        if ($town.Count -ne 1) {
            $problemy.Add("Siedziba $($wybrane.nazwa) w $kod jest gminą miejsko-wiejską bez jednego wiersza miasta")
        } else {
            $wybrane = [pscustomobject]@{
                id = $town[0].id
                gmina = $town[0].gmina
                powiat = $town[0].powiat
                woj = $town[0].woj
                rodzaj = '4'
                nazwa = $wybrane.nazwa
                ludnosc = $town[0].ludnosc
                powierzchnia_km2 = $town[0].powierzchnia_km2
            }
        }
    }

    $wSrodku++
    $miastoId = $wybrane.id
    $miastoLud = $wybrane.ludnosc
    $pominGmina = $wybrane.gmina
    $dodajWies = @()
    if ($wybrane.rodzaj -eq '4') {
        $dodajWies = @($grupa | Where-Object { $_.gmina -eq $pominGmina -and $_.rodzaj -eq '5' })
        $resztaJednostki = @($pelne | Where-Object { $_.gmina -ne $pominGmina }) + $dodajWies
    } else {
        $resztaJednostki = @($pelne | Where-Object { $_.id -ne $miastoId })
    }
    $sumaReszta = ($resztaJednostki | Measure-Object ludnosc -Sum).Sum
    if ($null -eq $sumaReszta) { $sumaReszta = 0 }
    if (($miastoLud + $sumaReszta) -ne $powiatPop[$kod]) {
        $problemy.Add("Rozcięcie $kod ${seatName}: miasto $miastoLud + reszta $sumaReszta != $($powiatPop[$kod])")
    }

    $miasto = [ordered]@{
        id = $miastoId
        nazwa = $wybrane.nazwa
        typ = 'miasto'
        panstwo = 'Polska'
        wojewodztwo = $woj
        powiat_id = $kod
        powiat_nazwa = $nazwaPow
        rodzaj_teryt = $wybrane.rodzaj
        co_liczy_ludnosc = $(if ($wybrane.rodzaj -eq '4') { 'samo miasto, bez obszaru wiejskiego tej gminy' } else { 'gmina miejska' })
        liczba_mieszkancow = $miastoLud
        powierzchnia_km2 = $wybrane.powierzchnia_km2
        reszta_powiatu_id = $kod
        stan_podzialu = '2026-01-01'
        zrodlo_ludnosci = 'GUS, Powierzchnia i ludność w przekroju terytorialnym w 2026 r., tabl. 19'
        zrodlo_siedziby = 'Wikidata P36 (siedziba), poprawione 6 nazw bez polskiej etykiety'
        dostep_transportu_publicznego = $null
        cena_transportu_publicznego = $null
        przestepczosc = Crime-Block $uwagaMiastoWPowiecie
    }
    Write-JsonFile (Join-Path $outMiasta ($miastoId + '.json')) $miasto
    $indeksMiasta.Add([ordered]@{ id = $miastoId; nazwa = $wybrane.nazwa; powiat_id = $kod; wojewodztwo = $woj; liczba_mieszkancow = $miastoLud; plik = "miasta/$miastoId.json" })

    $reszta = [ordered]@{
        id = $kod
        nazwa = $nazwaPow
        typ = 'wies'
        panstwo = 'Polska'
        wojewodztwo = $woj
        miasto_powiatowe_poza_powiatem = $false
        siedziba_nazwa = $wybrane.nazwa
        siedziba_id = $miastoId
        liczba_mieszkancow = $sumaReszta
        dostep_transportu_publicznego = $null
        cena_transportu_publicznego = $null
        srednia_odleglosc_ludzi_od_miasta_powiatowego_km = $null
        srednia_odleglosc_metoda = 'Nie ma punktów ludności z odległością do siedziby powiatu. Nie liczone z powierzchni ani z linii prostej.'
        stan_podzialu = '2026-01-01'
        zrodlo_ludnosci = 'GUS, Powierzchnia i ludność w przekroju terytorialnym w 2026 r., tabl. 19, bez siedziby powiatu'
        przestepczosc = Crime-Block $uwagaReszta
    }
    Write-JsonFile (Join-Path $outReszta ($kod + '.json')) $reszta
    $indeksReszta.Add([ordered]@{ id = $kod; nazwa = $nazwaPow; wojewodztwo = $woj; siedziba = $wybrane.nazwa; liczba_mieszkancow = $sumaReszta; plik = "reszta_powiatu/$kod.json" })
}

$paczka = [ordered]@{
    nazwa = 'Polska — miasta powiatowe i reszta powiatów'
    stan_podzialu = '2026-01-01'
    zrodlo_ludnosci = 'GUS, Powierzchnia i ludność w przekroju terytorialnym w 2026 r., tablice 2 i 19'
    zrodlo_podzialu = 'GUS TERC, stan na 2026-01-01'
    zrodlo_siedzib = 'Wikidata, właściwość P36'
    liczba_miast = $indeksMiasta.Count
    liczba_reszta_powiatu = $indeksReszta.Count
    siedziba_w_powiecie = $wSrodku
    siedziba_poza_powiatem = $poza
    przestępstwa = 'Puste. GUS/Policja podają je dla całego powiatu, nie dla miasta osobno i nie dla wsi. API BDL było w chwili zbierania zablokowane limitem, więc nie wpisałem też liczb całego powiatu.'
    czas_dojazdu = 'Nie ma pola czasu dojazdu ani ceny dojazdu przy miejscu. Cena paliwa jest raz w kraj.json. Przy miejscu sa puste pola transportu publicznego.'
    aktualizacja = 'Ten zestaw nie pobiera się sam. Można go później dołożyć do gry jako paczkę danych. Odświeżenie wymaga ponownego odczytu tablic GUS, nie dzieje się w tle.'
    problemy = @($problemy)
}
Write-JsonFile (Join-Path $outRoot 'paczka.json') $paczka
Write-JsonFile (Join-Path $outRoot 'kraj.json') ([ordered]@{
    nazwa = 'Polska'
    cena_paliwa = [ordered]@{
        pb95 = $null
        olej_napedowy = $null
        jednostka = 'zl/l'
        zrodlo = $null
        data = $null
        uwaga = 'Liczby nie wpisane. Biuletyn Komisji Europejskiej (Weekly Oil Bulletin) podaje ceny, ale plik z tabelą nie został tu odczytany. Nie przepisano cen z omówień wtórnych.'
    }
    cena_pradu = [ordered]@{
        wartosc = 0.9198
        jednostka = 'zl/kWh'
        zakres = 'gospodarstwo_domowe'
        rok = 2025
        co_obejmuje = 'energia i dystrybucja, z akcyzą, bez VAT'
        zrodlo = 'Prezes URE, Informacja nr 15/2026, średnia cena energii elektrycznej dla odbiorcy w gospodarstwie domowym'
        data = '2026-03-26'
        uwaga = 'To nie jest cennik ładowania samochodu.'
    }
})
try {
    Write-JsonFile (Join-Path $outRoot 'indeks.json') ([ordered]@{
        kraj = 'kraj.json'
        metropolie = $null
        metropolie_uwaga = 'Czeka na decyzję użytkownika. Żadne miasto nie jest oznaczone jako metropolia.'
        miasta = @($indeksMiasta.ToArray())
        reszta_powiatu = @($indeksReszta.ToArray())
    })
} catch {
    Write-Output ("INDEKS_FAIL=" + $_.Exception.GetType().FullName + " " + $_.Exception.Message)
    if ($_.Exception.InnerException) { Write-Output $_.Exception.InnerException.Message }
    throw
}

Write-Output ("MIASTA=" + $indeksMiasta.Count)
Write-Output ("RESZTA=" + $indeksReszta.Count)
Write-Output ("W_SRODKU=" + $wSrodku)
Write-Output ("POZA=" + $poza)
Write-Output ("PROBLEMY=" + $problemy.Count)
$problemy | Select-Object -First 40 | ForEach-Object { Write-Output $_ }
