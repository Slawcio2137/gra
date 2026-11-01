extends SceneTree

## Headless: katalog aut PL + losowanie ofert + filtry przebieg/marka/napęd.
## godot --headless --path . --script res://scripts/test_katalog_aut.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not FileAccess.file_exists("res://pojazdy/katalog_aut_pl.json"):
		printerr("FAIL: brak katalog_aut_pl.json")
		return 1
	var kat := rynek.katalog_aut()
	if not (kat.get("modele") is Array) or kat["modele"].is_empty():
		printerr("FAIL: puste modele w katalogu")
		return 1
	var z_cena := 0
	var bez_ceny := 0
	for m in kat["modele"]:
		if not (m is Dictionary):
			continue
		if m.get("cena_zl") is int or m.get("cena_zl") is float:
			z_cena += 1
		else:
			bez_ceny += 1
		if str(m.get("marka", "")) == "" or str(m.get("model", "")) == "":
			printerr("FAIL: brak marki/modelu")
			return 1
		if str(m.get("naped", "")) == "":
			printerr("FAIL: brak napędu ", m.get("id"))
			return 1
		if str(m.get("zrodlo", "")) == "":
			printerr("FAIL: brak źródła ", m.get("id"))
			return 1
	print("OK katalog: modeli=", z_cena + bez_ceny, " z_cena=", z_cena, " bez_ceny=", bez_ceny)

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
		"rynek_zakupow": {"ziarno": 424242},
	}
	rynek.zapewnij_pule(swiat, miasta, mid, 1)
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, mid, 1)
	rynek.uzupelnij_okno_aut(swiat, miasta, {"poziom": "polska", "km": 9999.0, "stan": "nowy", "tydzien": 1}, 8)
	var auta: Array = []
	var uzywane_pula: Array = []
	for o in swiat["rynek_zakupow"]["oferty"]:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod":
			auta.append(o)
			if str(o.get("stan", "")) == "uzywany" and not bool(o.get("z_katalogu_globalny", false)):
				uzywane_pula.append(o)
	if uzywane_pula.is_empty():
		printerr("FAIL: brak używanych w puli lokalnej po aktywacji")
		return 1
	var widziano_nowy := false
	var widziano_ukryte_spalanie := false
	for o in auta:
		if str(o.get("stan", "")) == "nowy":
			widziano_nowy = true
			if not bool(o.get("z_katalogu_globalny", false)):
				printerr("FAIL: nowe poza katalogiem globalnym: ", o.get("id"))
				return 1
			if int(o.get("przebieg_km", -1)) != 0:
				printerr("FAIL: nowe auto ma przebieg != 0")
				return 1
			if not (o.get("spalanie") is int or o.get("spalanie") is float):
				if o.get("spalanie") != null:
					printerr("FAIL: nowe auto bez spalania liczbowego")
					return 1
			if bool(o.get("spalanie_ukryte", false)):
				printerr("FAIL: nowe auto nie może ukrywać spalania")
				return 1
		else:
			if not (o.get("przebieg_km") is int or o.get("przebieg_km") is float):
				printerr("FAIL: używane bez przebiegu")
				return 1
			if int(o["przebieg_km"]) <= 0:
				printerr("FAIL: używane przebieg <= 0")
				return 1
			if bool(o.get("spalanie_ukryte", false)) or o.get("spalanie") == null:
				widziano_ukryte_spalanie = true
				if rynek.tekst_spalania(o) != "nie podano":
					printerr("FAIL: oczekiwano „nie podano”")
					return 1
		if str(o.get("naped", "")) == "":
			printerr("FAIL: oferta bez napędu")
			return 1
	if not widziano_nowy:
		printerr("FAIL: brak nowych z katalogu")
		return 1
	print("OK oferty aut=", auta.size(), " uzywane_pula=", uzywane_pula.size(), " nowy_z_katalogu=true")

	# Filtr przebiegu + multi-marka przy nowych.
	var nowe := rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 0.0, true, [], "")
	for o in nowe:
		if int(o.get("przebieg_km", 1)) != 0:
			printerr("FAIL: filtr przebiegu 0–0 przepuścił nie-zero")
			return 1
	var marki: Array = rynek.marki_katalogu_aut()
	if marki.size() < 2:
		printerr("FAIL: za mało marek do multi-filtra")
		return 1
	var marka0 := str(marki[0])
	var marka1 := str(marki[1])
	var po_marce := rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, marka0, "")
	for o in po_marce:
		if str(o.get("marka", "")) != marka0:
			printerr("FAIL: filtr jednej marki")
			return 1
	var multi := rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [marka0, marka1], "")
	for o in multi:
		var mk := str(o.get("marka", ""))
		if mk != marka0 and mk != marka1:
			printerr("FAIL: multi-marka przepuściła ", mk)
			return 1
	var puste_marki := rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "")
	if puste_marki.size() < multi.size():
		printerr("FAIL: puste marki powinny = wszystkie")
		return 1
	print("OK filtry: nowych=", nowe.size(), " marka ", marka0, "=", po_marce.size(), " multi=", multi.size(), " wszystkie=", puste_marki.size())
	if not widziano_ukryte_spalanie:
		var ukryte := 0
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for _j in 60:
			var o3: Dictionary = rynek._losuj_samochod(miasta[0], rng, mid, {}, "uzywany")
			if str(o3.get("stan", "")) == "uzywany" and (bool(o3.get("spalanie_ukryte", false)) or o3.get("spalanie") == null):
				ukryte += 1
				if rynek.tekst_spalania(o3) != "nie podano":
					printerr("FAIL: tekst spalania")
					return 1
		if ukryte < 1:
			printerr("FAIL: nie wylosowano ukrytego spalania w używanych")
			return 1
		print("OK używane z „nie podano” spalania: ", ukryte)
	else:
		print("OK używane z „nie podano” już w puli")
	print("OK katalog + filtry aut")
	return 0
