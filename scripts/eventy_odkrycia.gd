extends RefCounted
class_name EventyOdkrycia

## Pula eventów „dziecko się dowiaduje”. Max 1–2 na turę. Wagi = propozycja.

const PLIK := "res://postacie/eventy_odkrycia.json"
const _Losowanie = preload("res://scripts/losowanie.gd")

var _dane: Variant = null


func wczytaj() -> Variant:
	if _dane is Dictionary:
		return _dane
	if not FileAccess.file_exists(PLIK):
		return null
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return null
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		_dane = dane
	return dane


func losuj_ture(kontekst: Dictionary, losowanie = null) -> Array:
	var wynik: Array = []
	var dane: Variant = wczytaj()
	if not (dane is Dictionary):
		return wynik
	var max_n := 2
	if _liczba(dane.get("max_na_ture")):
		max_n = clampi(int(dane["max_na_ture"]), 1, 2)
	var pula: Variant = dane.get("pula", [])
	if not (pula is Array) or pula.is_empty():
		return wynik
	var flagi: Dictionary = kontekst.get("flagi", {})
	if not (flagi is Dictionary):
		flagi = {}
	var wiek: Variant = kontekst.get("wiek", null)
	var jedynak := bool(kontekst.get("jedynak", false))
	var ma: Dictionary = kontekst.get("ma", {})
	if not (ma is Dictionary):
		ma = {}
	var wagi := {}
	var po_id := {}
	for pozycja in pula:
		if not (pozycja is Dictionary) or str(pozycja.get("id", "")) == "":
			continue
		var id := str(pozycja["id"])
		if not _pasuje(pozycja, wiek, jedynak, flagi, ma):
			continue
		var waga := _waga(pozycja)
		if waga <= 0.0:
			continue
		wagi[id] = waga
		po_id[id] = pozycja
	if wagi.is_empty():
		return wynik
	var los = losowanie if losowanie != null else _Losowanie.new()
	var ile := 1
	if max_n >= 2 and randf() < 0.35:
		ile = 2
	var uzyte: Dictionary = {}
	for _i in ile:
		var lokalne := {}
		for klucz in wagi.keys():
			if uzyte.has(klucz):
				continue
			lokalne[klucz] = wagi[klucz]
		if lokalne.is_empty():
			break
		var id_wyl: String = los.losuj_kolo(lokalne)
		if id_wyl == "" or not po_id.has(id_wyl):
			break
		uzyte[id_wyl] = true
		wynik.append(_karta(po_id[id_wyl]))
	return wynik


func zastosuj_wybor(event: Dictionary, opcja_id: String, kontekst: Dictionary) -> Dictionary:
	var wynik := {
		"tekst": "",
		"flagi": [],
		"skutki": {},
		"odblokuj_pytania": [],
		"skutek": "",
	}
	var opcje: Variant = event.get("opcje", [])
	if not (opcje is Array):
		return wynik
	var wybrana: Dictionary = {}
	for op in opcje:
		if op is Dictionary and str(op.get("id", "")) == opcja_id:
			wybrana = op
			break
	if wybrana.is_empty():
		wynik["tekst"] = "Brak takiej opcji."
		return wynik
	wynik["skutek"] = str(wybrana.get("skutek", ""))
	if wybrana.get("flagi") is Array:
		for f in wybrana["flagi"]:
			wynik["flagi"].append(str(f))
	if opcja_id == "tak" and event.get("flagi_gdy_tak") is Array:
		for f in event["flagi_gdy_tak"]:
			wynik["flagi"].append(str(f))
	if opcja_id == "nie" and event.get("flagi_gdy_nie_albo_pozniej") is Array:
		for f in event["flagi_gdy_nie_albo_pozniej"]:
			wynik["flagi"].append(str(f))
	if wybrana.get("skutki") is Dictionary:
		wynik["skutki"] = (wybrana["skutki"] as Dictionary).duplicate(true)
	var tekst := str(wybrana.get("tekst", ""))
	var skutek := str(wybrana.get("skutek", ""))
	if skutek == "argument_kieszonkowe":
		var sukces := _sukces_argumentu_kieszonkowego(kontekst)
		if sukces:
			tekst = str(wybrana.get("tekst_sukces", tekst))
			wynik["skutek"] = "kieszonkowe_argument_ok"
		else:
			tekst = str(wybrana.get("tekst_odmowa", tekst))
			wynik["skutek"] = "kieszonkowe_argument_odmowa"
	elif skutek == "pytanie_zarobki":
		if _wysokie_zarobki(kontekst) and randf() < 0.65:
			tekst = str(wybrana.get("tekst_milczenie", "Rodzic nie chce mówić o zarobkach."))
		else:
			tekst = str(wybrana.get("tekst_odpowiedz", tekst))
	elif skutek == "prosba_slodycze":
		if _odmowa_charakter(kontekst):
			tekst = str(wybrana.get("tekst_odmowa", tekst))
		else:
			tekst = str(wybrana.get("tekst_ok", tekst))
	elif skutek.begins_with("nauka_dom"):
		if bool(event.get("zalezy_od_charakteru_rodzicow", false)) and not _rodzice_chetni_uczyc(kontekst):
			tekst = "Rodzice nie mają teraz chęci uczyć. I tak dojdziesz do tego w podstawówce."
			if event.get("flagi_gdy_nie_albo_pozniej") is Array:
				for f in event["flagi_gdy_nie_albo_pozniej"]:
					wynik["flagi"].append(str(f))
			wynik["skutek"] = "nauka_fallback_szkola"
	wynik["tekst"] = tekst
	return wynik


func zastosuj_bez_pytania(event: Dictionary) -> Dictionary:
	var wynik := {
		"tekst": str(event.get("tekst", "")),
		"flagi": [],
		"skutki": {},
		"odblokuj_pytania": [],
		"skutek": str(event.get("skutek", "")),
	}
	if event.get("flagi") is Array:
		for f in event["flagi"]:
			wynik["flagi"].append(str(f))
	if event.get("skutki") is Dictionary:
		wynik["skutki"] = (event["skutki"] as Dictionary).duplicate(true)
	if event.get("odblokuj_pytania") is Array:
		for t in event["odblokuj_pytania"]:
			wynik["odblokuj_pytania"].append(str(t))
	return wynik


func _karta(pozycja: Dictionary) -> Dictionary:
	return {
		"id": str(pozycja.get("id", "")),
		"tekst": str(pozycja.get("tekst", "")),
		"pytanie": bool(pozycja.get("pytanie", false)),
		"opcje": (pozycja.get("opcje", []) as Array).duplicate(true) if pozycja.get("opcje") is Array else [],
		"flagi": (pozycja.get("flagi", []) as Array).duplicate(true) if pozycja.get("flagi") is Array else [],
		"flagi_gdy_tak": pozycja.get("flagi_gdy_tak", []),
		"flagi_gdy_nie_albo_pozniej": pozycja.get("flagi_gdy_nie_albo_pozniej", []),
		"skutki": (pozycja.get("skutki", {}) as Dictionary).duplicate(true) if pozycja.get("skutki") is Dictionary else {},
		"odblokuj_pytania": pozycja.get("odblokuj_pytania", []),
		"skutek": str(pozycja.get("skutek", "")),
		"zalezy_od_charakteru_rodzicow": bool(pozycja.get("zalezy_od_charakteru_rodzicow", false)),
		"propozycja_do_poprawki": bool(pozycja.get("propozycja_do_poprawki", true)),
	}


func _pasuje(pozycja: Dictionary, wiek: Variant, jedynak: bool, flagi: Dictionary, ma: Dictionary) -> bool:
	if bool(pozycja.get("tylko_jedynak", false)) and not jedynak:
		return false
	if _liczba(pozycja.get("wymaga_wiek_min")) and _liczba(wiek) and int(wiek) < int(pozycja["wymaga_wiek_min"]):
		return false
	if _liczba(pozycja.get("wymaga_wiek_max")) and _liczba(wiek) and int(wiek) > int(pozycja["wymaga_wiek_max"]):
		return false
	var etap := str(pozycja.get("wymaga_etap", ""))
	if etap == "podstawowka":
		if not _liczba(wiek) or int(wiek) < 7:
			return false
	if pozycja.get("wymaga_flagi") is Array:
		for f in pozycja["wymaga_flagi"]:
			if not bool(flagi.get(str(f), false)):
				return false
	if pozycja.get("wymaga_ma") is Array:
		var tryb := str(pozycja.get("wymaga_ma_tryb", "ktokolwiek"))
		var ok := false
		var wszystkie := true
		for klucz in pozycja["wymaga_ma"]:
			var jest := bool(ma.get(str(klucz), false))
			if jest:
				ok = true
			else:
				wszystkie = false
		if tryb == "wszystkie" and not wszystkie:
			return false
		if tryb != "wszystkie" and not ok:
			return false
	# Już odkryte: nie powtarzaj tych samych flag głównych.
	if pozycja.get("flagi") is Array and not pozycja["flagi"].is_empty():
		var wszystkie_flagi := true
		for f in pozycja["flagi"]:
			if not bool(flagi.get(str(f), false)):
				wszystkie_flagi = false
				break
		if wszystkie_flagi:
			return false
	return true


func _waga(pozycja: Dictionary) -> float:
	var czestosc: Variant = pozycja.get("czestosc", null)
	if czestosc is Dictionary and _liczba(czestosc.get("prog_rzadki_tura")):
		# Rzadki próg — nie oficjalny %. Tu używany jako waga względna.
		return maxf(0.05, float(czestosc["prog_rzadki_tura"]) * 50.0)
	if _liczba(pozycja.get("waga")):
		return maxf(0.0, float(pozycja["waga"]))
	return 1.0


func _sukces_argumentu_kieszonkowego(kontekst: Dictionary) -> bool:
	var cechy: Array = kontekst.get("cechy_rodzicow", [])
	if not (cechy is Array):
		cechy = []
	for c in cechy:
		var id := str(c)
		if id == "hojny" or id == "ulegly" or id == "lagodny":
			return true
		if id == "oszczedny" or id == "skapy" or id == "surowy":
			return false
	return randf() < 0.45


func _wysokie_zarobki(kontekst: Dictionary) -> bool:
	var przedzial := str(kontekst.get("przedzial_zarobkow", ""))
	return przedzial == "powyzej_dwoch_median" or przedzial == "od_przecietnego_do_dwoch_median"


func _odmowa_charakter(kontekst: Dictionary) -> bool:
	var cechy: Array = kontekst.get("cechy_rodzicow", [])
	for c in cechy:
		var id := str(c)
		if id == "oszczedny" or id == "skapy" or id == "surowy":
			return true
	return false


func _rodzice_chetni_uczyc(kontekst: Dictionary) -> bool:
	var cechy: Array = kontekst.get("cechy_rodzicow", [])
	for c in cechy:
		var id := str(c)
		if id == "ambitny" or id == "obowiazkowy" or id == "opiekunczy" or id == "cierpliwy":
			return true
		if id == "wygodny" or id == "niedbaly":
			return false
	return randf() < 0.55


func _liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float
