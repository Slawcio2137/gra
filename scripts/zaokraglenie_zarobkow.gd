extends RefCounted

## Wyświetlane zarobki: zwykle 2 cyfry znaczące, nigdy więcej niż 3.
## 4537 → 4500, 12800 → 13000, 875 → 880, 85 → 85.
## To zaokrąglenie liczb już policzonych ze źródła, nie nowy model płac.
## Ceny aut i towarów tu nie wchodzą.

const CYFRY := 2


static func zaokraglij(kwota: Variant, cyfry: int = CYFRY) -> int:
	if not (kwota is int or kwota is float):
		return 0
	var v := absf(float(kwota))
	var znak := -1 if float(kwota) < 0.0 else 1
	if v == 0.0:
		return 0
	var n := clampi(cyfry, 1, 3)
	# +1e-9: log10(1000) bywa 2.999999 i zjada rząd.
	var wykladnik := int(floor(log(v) / log(10.0) + 1e-9))
	var factor := pow(10.0, float(wykladnik - n + 1))
	if factor <= 0.0:
		return znak * int(round(v))
	return znak * int(round(round(v / factor) * factor))


static func cyfry_znaczace(n: int) -> int:
	var v := absi(n)
	if v == 0:
		return 1
	var s := str(v)
	var i := 0
	var j := s.length() - 1
	while j > i and s[j] == "0":
		j -= 1
	return j - i + 1


## Zaokrągla pola kwot w bloku zarobków i zapisuje je z powrotem,
## żeby liczba na ekranie była tą samą, która leży w zapisie.
static func zaokraglij_blok(blok: Dictionary) -> void:
	if blok.get("kolo") != true:
		return
	var byla := false
	for klucz in ["od_zl", "do_zl", "mediana_zl", "przecietne_zl", "kwota"]:
		var v: Variant = blok.get(klucz, null)
		if v is int or v is float:
			blok[klucz] = zaokraglij(v)
			byla = true
	if byla:
		blok["zaokraglenie"] = "2_cyfry_znaczace"


static func tekst(blok: Variant) -> String:
	if not (blok is Dictionary) or blok.get("kolo") != true:
		return ""
	zaokraglij_blok(blok)
	var od: Variant = blok.get("od_zl")
	var dok: Variant = blok.get("do_zl")
	if not (od is int or od is float) and (blok.get("mediana_zl") is int or blok.get("mediana_zl") is float):
		od = blok.get("mediana_zl")
	if not (dok is int or dok is float) and (blok.get("przecietne_zl") is int or blok.get("przecietne_zl") is float):
		dok = blok.get("przecietne_zl")
	if (od is int or od is float) and (dok is int or dok is float):
		var a := int(od)
		var b := int(dok)
		if a == b:
			return "%d zł" % a
		return "%d–%d zł" % [a, b]
	if dok is int or dok is float:
		return "do %d zł" % int(dok)
	if od is int or od is float:
		return "od %d zł" % int(od)
	return ""
