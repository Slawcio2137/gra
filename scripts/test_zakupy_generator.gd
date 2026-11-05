extends SceneTree

## Headless: generator mieszkań + ruch puli po turze + zawody budowlane.
## godot --headless --path . --script res://scripts/test_zakupy_generator.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var dane := rynek.wczytaj()
	if dane.is_empty() or not (dane.get("nieruchomosci") is Dictionary):
		printerr("FAIL: brak sekcji nieruchomosci w zakupy_oferty.json")
		return 1
	if not (dane.get("pule_marek") is Dictionary):
		printerr("FAIL: brak pul_marek")
		return 1
	if not FileAccess.file_exists("res://zakupy/obrazki_paczka.json"):
		printerr("FAIL: brak manifestu obrazkow")
		return 1
	var man_plik := FileAccess.open("res://zakupy/obrazki_paczka.json", FileAccess.READ)
	var man: Variant = JSON.parse_string(man_plik.get_as_text())
	if not (man is Dictionary) or man.get("pobrane") != false:
		printerr("FAIL: paczka powinna miec pobrane:false")
		return 1
	if not FileAccess.file_exists("res://grafika/zakupy/mieszkanie.png"):
		printerr("FAIL: brak lokalnego placeholdera mieszkanie.png")
		return 1

	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.is_empty():
		printerr("FAIL: brak miast")
		return 1
	var mid := str(miasta[0].get("id", ""))
	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 0, "miejsce": miasta[0]},
		"id_miejsca_pobytu": mid,
		"majatek": {"nieruchomosci": [], "dobra": []},
		"rynek_zakupow": {},
	}
	rynek.zapewnij_pule(swiat, miasta, mid, 1)
	var oferty1: Array = swiat["rynek_zakupow"]["oferty"]
	if oferty1.is_empty():
		printerr("FAIL: pusta pula na starcie")
		return 1
	var mieszkania: Array = []
	for o in oferty1:
		if o is Dictionary and str(o.get("kategoria", "")) == "mieszkanie":
			mieszkania.append(o)
	if mieszkania.size() < 1:
		printerr("FAIL: brak ofert mieszkanie")
		return 1
	print("OK Start→Zakupy→Mieszkanie: ofert mieszkan=", mieszkania.size(), " (pula=", oferty1.size(), ")")
	for i in mini(3, mieszkania.size()):
		var m: Dictionary = mieszkania[i]
		for klucz in ["metraz_m2", "stan", "cena_zl", "wygoda", "pokoje", "odleglosc_km", "miasto_nazwa"]:
			if not m.has(klucz):
				printerr("FAIL: brak pola ", klucz)
				return 1
		if not (m.get("cena_zl") is int or m.get("cena_zl") is float):
			printerr("FAIL: cena nie liczba")
			return 1
		print("  ", m.get("nazwa"), " · ", m.get("stan"), " · ", m.get("metraz_m2"), " m2 · ", m.get("cena_zl"), " zl · wygoda ", m.get("wygoda"))

	# Snapshot id przed turą.
	var ids1 := {}
	for o in oferty1:
		if o is Dictionary:
			ids1[str(o.get("id", ""))] = true
	swiat["tydzien"] = 2
	rynek.zapewnij_pule(swiat, miasta, mid, 2)
	var oferty2: Array = swiat["rynek_zakupow"]["oferty"]
	var ids2 := {}
	var wspolne := 0
	var nowe := 0
	for o in oferty2:
		if not (o is Dictionary):
			continue
		var id := str(o.get("id", ""))
		ids2[id] = true
		if ids1.has(id):
			wspolne += 1
		else:
			nowe += 1
	var zniknelo := ids1.size() - wspolne
	if zniknelo <= 0 and nowe <= 0:
		printerr("FAIL: pula nie ruszyla sie po turze")
		return 1
	print("OK Następna tura: zniknelo≈", zniknelo, " nowych=", nowe, " zostalo=", wspolne, " (pula=", oferty2.size(), ")")

	# Zawody: fizyczny pracownik budowlany + elektryk.
	var zaw_plik := FileAccess.open("res://postacie/losowanie/zawody_kraje.json", FileAccess.READ)
	var zaw: Variant = JSON.parse_string(zaw_plik.get_as_text())
	if not (zaw is Dictionary):
		printerr("FAIL: zawody_kraje")
		return 1
	var mezczyzni: Array = zaw["kraje"]["polska"]["mezczyzni"]
	var ma_fiz := false
	var ma_el := false
	for g in mezczyzni:
		if not (g is Dictionary) or not (g.get("zawody") is Array):
			continue
		for z in g["zawody"]:
			if not (z is Dictionary):
				continue
			if str(z.get("id")) == "oc71" and str(z.get("nazwa")).findn("fizyczny") >= 0 and float(z.get("waga", 0)) > 900:
				ma_fiz = true
			if str(z.get("id")) == "oc74" and str(z.get("nazwa")).findn("Elektryk") >= 0 and float(z.get("waga", 0)) > 200:
				ma_el = true
	if not ma_fiz or not ma_el:
		printerr("FAIL: brak fizycznego pracownika budowlanego / elektryka w wagach M")
		return 1
	print("OK zawody: Fizyczny pracownik budowlany (OC71) + Elektryk (OC74)")

	# Kontekst NACE F nie jest wagą koła.
	if not (zaw["kraje"]["polska"].get("kontekst_sektor_nie_waga_kola") is Dictionary):
		printerr("FAIL: brak kontekstu NACE F")
		return 1
	print("OK kontekst sektor F odnotowany, nie wrzucony do koła zawodów")

	# Dryf zadowolenia: wygoda → ukryte docelowe; psychika 50% dystansu / turę.
	if not FileAccess.file_exists("res://postacie/zadowolenie_dryf.json"):
		printerr("FAIL: brak postacie/zadowolenie_dryf.json")
		return 1
	var efekt_conf: Variant = dane["nieruchomosci"].get("wygoda_efekt_zadowolenia_tydzien")
	if not (efekt_conf is Dictionary) or not bool(efekt_conf.get("propozycja_do_poprawki", false)):
		printerr("FAIL: brak wygoda_efekt_zadowolenia_tydzien / propozycja_do_poprawki")
		return 1
	if efekt_conf.get("progi") is Array:
		printerr("FAIL: stare progi ±2 powinny byc usuniete")
		return 1
	var swiat_efekt := {
		"bohater": {"psychika": 50, "pieniadze": 0},
		"rodzina": {"dom": {"id": null, "nazwa": null}},
		"majatek": {"nieruchomosci": [], "dobra": []},
		# Stała wygoda — ten blok sprawdza dryf ze źródła lokum_startowe, nie losowanie typu.
		"lokum_startowe": {"wygoda": 48, "kategoria": "mieszkanie", "typ_nazwa": "Mieszkanie"},
	}
	var lokum: Dictionary = rynek.wygoda_lokum(swiat_efekt)
	if int(lokum.get("wygoda", -1)) != 48 or str(lokum.get("zrodlo", "")) != "lokum_startowe":
		printerr("FAIL: lokum startowe wygoda=", lokum)
		return 1
	# Offset liniowy: wygoda 20 → −10 → docelowe 40; z 50 dryf −5.
	swiat_efekt["lokum_startowe"] = {"wygoda": 20}
	swiat_efekt["bohater"]["psychika"] = 50
	var spad: Dictionary = rynek.efekt_wygody_tydzien(swiat_efekt)
	if int(spad.get("docelowe", -1)) != 40 or int(spad.get("delta", 0)) != -5:
		printerr("FAIL: niska wygoda dryf oczekiwano docelowe=40 delta=-5 ", spad)
		return 1
	if str(spad.get("tekst", "")).find("Samopoczucie: −5") < 0:
		printerr("FAIL: napis tygodnia bez docelowego, oczekiwano Samopoczucie: −5 ", spad)
		return 1
	if int(swiat_efekt["bohater"]["psychika"]) != 45:
		printerr("FAIL: psychika po dryfie ", swiat_efekt["bohater"], spad)
		return 1
	if str(spad.get("tekst", "")).to_lower().find("docelow") >= 0:
		printerr("FAIL: napis nie powinien wspominać docelowego ", spad)
		return 1
	print("OK niska wygoda dryf: ", spad.get("tekst"), " psychika=", swiat_efekt["bohater"]["psychika"])
	# Wysoka wygoda własnej: 80 → offset +20 → docelowe 70; z 50 → +10.
	swiat_efekt["majatek"] = {"nieruchomosci": [{"wygoda": 80, "nazwa": "Test", "zamieszkane": true}], "dobra": []}
	swiat_efekt["bohater"]["psychika"] = 50
	var plus: Dictionary = rynek.efekt_wygody_tydzien(swiat_efekt)
	if int(plus.get("docelowe", -1)) != 70 or int(plus.get("delta", 0)) != 10:
		printerr("FAIL: wysoka wygoda dryf oczekiwano docelowe=70 delta=+10 ", plus)
		return 1
	if str(plus.get("tekst", "")) != "Samopoczucie: +10":
		printerr("FAIL: napis ", plus)
		return 1
	if str(plus.get("zrodlo", "")) != "wlasna":
		printerr("FAIL: oczekiwano zrodlo wlasna ", plus)
		return 1
	print("OK wysoka wygoda wlasna dryf: ", plus.get("tekst"), " zrodlo=", plus.get("zrodlo"))
	# Arytmetyka: 50 → 80 daje +15 (niezależnie od wygody — ustawione docelowe).
	var offset100 := rynek.offset_wygody(100)
	if abs(offset100 - 30.0) > 0.001:
		printerr("FAIL: offset wygody 100 powinien byc +30, jest ", offset100)
		return 1
	var swiat_aryt := {
		"bohater": {"psychika": 50, "zadowolenie_docelowe": 80},
		"majatek": {"nieruchomosci": [{"wygoda": 100}]},
		"lokum_startowe": {"wygoda": 100},
	}
	# wygoda 100 → docelowe 80; dryf z 50 → +15.
	var aryt: Dictionary = rynek.efekt_wygody_tydzien(swiat_aryt)
	if int(aryt.get("delta", 0)) != 15 or int(swiat_aryt["bohater"]["psychika"]) != 65:
		printerr("FAIL: 50→80 powinno dac +15 → 65 ", aryt, swiat_aryt["bohater"])
		return 1
	print("OK arytmetyka 50→80: +15 → psychika=", swiat_aryt["bohater"]["psychika"])
	# Brak majatku i rodziny → 0.
	var pusty := {"bohater": {"psychika": 50}, "majatek": {"nieruchomosci": []}}
	var zero: Dictionary = rynek.wygoda_lokum(pusty)
	if int(zero.get("wygoda", -1)) != 0:
		printerr("FAIL: bez lokum wygoda powinna byc 0 ", zero)
		return 1
	print("OK brak lokum → wygoda 0")
	return 0
