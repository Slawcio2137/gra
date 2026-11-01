extends SceneTree

## Katalog KZiS: liczba, kody, płace ze źródłem albo dziedziczeniem, efekty jako propozycja.
## Nie rusza cen paliwa w kraj.json.
## godot --headless --path . --script res://scripts/test_katalog_zawodow.gd

const Katalog = preload("res://scripts/katalog_zawodow.gd")
const Zaokr = preload("res://scripts/zaokraglenie_zarobkow.gd")
const Ziarno = preload("res://scripts/ziarno_rodzicow.gd")
const Losowanie = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var kat = Katalog.new()
	kat.wczytaj()
	var dane: Dictionary = kat.dane()
	var zawody: Variant = dane.get("zawody", [])
	if not (zawody is Array) or zawody.size() < 400:
		printerr("FAIL: za mało zawodów ", zawody.size() if zawody is Array else -1)
		return 1
	var dziedziczone := 0
	var puste := 0
	var bezposrednie := 0
	var widziane := {}
	for z in zawody:
		if not (z is Dictionary):
			printerr("FAIL: wpis nie jest słownikiem")
			return 1
		var kod := str(z.get("kod", "")).strip_edges()
		var nazwa := str(z.get("nazwa", "")).strip_edges()
		if kod == "" or nazwa == "":
			printerr("FAIL: brak kodu albo nazwy")
			return 1
		if widziane.has(kod):
			printerr("FAIL: podwójny kod ", kod)
			return 1
		widziane[kod] = true
		var efekty: Variant = z.get("efekty_tygodniowe", null)
		if not (efekty is Dictionary) or efekty.get("propozycja_do_poprawki") != true:
			printerr("FAIL: efekty bez propozycji ", kod)
			return 1
		if efekty.get("szacunek") != true:
			printerr("FAIL: efekty bez szacunku ", kod)
			return 1
		var zrodlo: Variant = z.get("zarobki_zrodlo", null)
		var place: Variant = z.get("zarobki", null)
		if place == null:
			puste += 1
			if zrodlo != null:
				printerr("FAIL: pusta płaca ma źródło ", kod)
				return 1
			if str(z.get("zarobki_uwaga", "")).strip_edges() == "":
				printerr("FAIL: pusta płaca bez uwagi ", kod)
				return 1
			continue
		if not (place is Dictionary):
			printerr("FAIL: płaca nie jest obiektem ", kod)
			return 1
		if zrodlo != "grupa_nadrzedna" and zrodlo != "gus_z12_2024":
			printerr("FAIL: płaca bez źródła albo dziedziczenia ", kod, " ", zrodlo)
			return 1
		if str(place.get("zrodlo", "")).strip_edges() == "" and zrodlo != "grupa_nadrzedna":
			printerr("FAIL: brak cytatu źródła ", kod)
			return 1
		if zrodlo == "grupa_nadrzedna":
			dziedziczone += 1
			if str(place.get("zarobki_zrodlo", "")) != "grupa_nadrzedna":
				printerr("FAIL: brak znacznika grupa_nadrzedna ", kod)
				return 1
			if str(place.get("grupa_zrodla_isco", "")) == "":
				printerr("FAIL: dziedziczenie bez grupy ", kod)
				return 1
		else:
			bezposrednie += 1
		if _kwoty(place, kod) != 0:
			return 1
		for plec in ["mezczyzni", "kobiety"]:
			if place.get(plec) is Dictionary and _kwoty(place[plec], kod + " " + plec) != 0:
				return 1
	if dziedziczone + puste + bezposrednie != zawody.size():
		printerr("FAIL: licznik płac")
		return 1
	var opublikowane: Variant = dane.get("place_opublikowane", [])
	if not (opublikowane is Array) or opublikowane.size() != 9:
		printerr("FAIL: wiersze wielkich grup")
		return 1
	for w in opublikowane:
		if not (w is Dictionary) or str(w.get("zarobki_zrodlo", "")) != "gus_z12_2024":
			printerr("FAIL: wiersz grupy bez gus_z12_2024")
			return 1
		if w.get("zrodlo") == null or str(w.get("cytat", "")) == "":
			printerr("FAIL: wiersz grupy bez cytatu")
			return 1
	if kat.liczba_zawodow() != zawody.size():
		printerr("FAIL: liczba z loadera")
		return 1
	var oficer: Dictionary = kat.po_kodzie("011001")
	if oficer.is_empty() or oficer.get("zarobki") != null:
		printerr("FAIL: oficer powinien mieć pustą płacę")
		return 1
	var murarz: Dictionary = kat.po_kodzie("711202")
	if str(murarz.get("nazwa", "")) != "Murarz":
		printerr("FAIL: murarz ", murarz.get("nazwa"))
		return 1
	if _rodzina(kat) != 0:
		return 1
	if _paliwo() != 0:
		return 1
	print("OK katalog zawodów: ", zawody.size(), " dziedziczone ", dziedziczone, " null ", puste, " bezpośrednie na zawodzie ", bezposrednie)
	return 0


func _kwoty(place: Dictionary, kod: String) -> int:
	for para in [["mediana_zl_zrodlo", "mediana_zl"], ["przecietne_zl_zrodlo", "przecietne_zl"]]:
		var surowa: Variant = place.get(para[0], null)
		var pokaz: Variant = place.get(para[1], null)
		if not (surowa is int or surowa is float) or not (pokaz is int or pokaz is float):
			printerr("FAIL: kwota nie jest liczbą ", kod)
			return 1
		var oczekiwane := Zaokr.zaokraglij(surowa)
		if int(pokaz) != oczekiwane:
			printerr("FAIL: zaokrąglenie ", kod, " ", surowa, " → ", pokaz, " oczekiwane ", oczekiwane)
			return 1
		if Zaokr.cyfry_znaczace(int(pokaz)) > 3:
			printerr("FAIL: więcej niż 3 cyfry ", kod, " ", pokaz)
			return 1
	return 0


func _rodzina(kat) -> int:
	var los = Losowanie.new()
	var bohater: Dictionary = los.losuj_postac("kraj", "polska")
	if not bool(bohater.get("wylosowano", false)):
		printerr("FAIL: brak bohatera")
		return 1
	var ziarno = Ziarno.new()
	var rodzina: Dictionary = ziarno.losuj(los, bohater.get("miejsce"))
	for rola in ["matka", "ojciec"]:
		var os: Variant = rodzina.get(rola, {})
		if not (os is Dictionary):
			printerr("FAIL: brak ", rola)
			return 1
		var praca: Variant = os.get("praca", {})
		if not (praca is Dictionary) or not bool(praca.get("kolo", false)):
			printerr("FAIL: zawód rodzica ", rola)
			return 1
		if str(praca.get("katalog_kzis", "")) == "":
			printerr("FAIL: rodzic bez katalogu ", rola, " ", praca)
			return 1
		if not praca.has("efekty_uwaga"):
			printerr("FAIL: rodzic bez uwagi o efektach ", rola)
			return 1
		var efekty: Variant = praca.get("efekty_tygodniowe", null)
		if efekty != null and (not (efekty is Dictionary) or efekty.get("propozycja_do_poprawki") != true):
			printerr("FAIL: efekty rodzica ", rola)
			return 1
		var zar: Variant = os.get("zarobki", {})
		if not (zar is Dictionary):
			printerr("FAIL: zarobki rodzica ", rola)
			return 1
		var zz := str(zar.get("zarobki_z", ""))
		if not zz.begins_with("grupa_OC"):
			printerr("FAIL: płaca rodzica rozjechała się z GUS ", rola, " ", zz)
			return 1
		var grupa: Dictionary = kat.po_kodzie(str(praca.get("katalog_kzis", "")))
		if grupa.is_empty():
			printerr("FAIL: kod katalogu nie istnieje ", praca.get("katalog_kzis"))
			return 1
	return 0


func _paliwo() -> int:
	if not FileAccess.file_exists("res://świat/polska/kraj.json"):
		printerr("FAIL: brak kraj.json")
		return 1
	var plik := FileAccess.open("res://świat/polska/kraj.json", FileAccess.READ)
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if not (dane is Dictionary):
		printerr("FAIL: kraj.json")
		return 1
	var paliwo: Variant = dane.get("cena_paliwa", {})
	if not (paliwo is Dictionary):
		printerr("FAIL: cena_paliwa")
		return 1
	if float(paliwo.get("benzyna", -1)) != 6.0 or float(paliwo.get("gaz", -1)) != 2.5 or float(paliwo.get("energia", -1)) != 0.9:
		printerr("FAIL: ceny paliwa ", paliwo)
		return 1
	if paliwo.get("olej_napedowy", "brak") != null:
		printerr("FAIL: olej napędowy nie jest null ", paliwo.get("olej_napedowy"))
		return 1
	if paliwo.has("diesel"):
		printerr("FAIL: dopisany klucz diesel")
		return 1
	return 0
