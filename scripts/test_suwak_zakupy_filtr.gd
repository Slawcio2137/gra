extends SceneTree

## Headless: suwak min nie zacina się przy 0; filtry ceny/odległości/odbioru dla dóbr.
## godot --headless --path . --script res://scripts/test_suwak_zakupy_filtr.gd

const SkryptZakresu = preload("res://scripts/suwak_zakres.gd")
const Rynek = preload("res://scripts/rynek_zakupow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	if not _test_suwak_min0():
		return 1
	if not _test_filtr_dobra():
		return 1
	print("OK suwak + filtry zakupów")
	return 0


func _test_suwak_min0() -> bool:
	var s = SkryptZakresu.new()
	s.size = Vector2(400, 48)
	s.ustaw_zakres(0.0, 100.0)
	# Oba uchwyty na min (0) — wcześniej „od” pożerał hitbox i clampował w miejscu.
	s.od = 0.0
	s.dokad = 0.0
	s._zacznij(18.0)  # lewy skraj
	s._rusz(200.0)  # w prawo
	if s.dokad <= 0.001 and s.od <= 0.001:
		printerr("FAIL: suwak nadal przyklejony przy min=0 (dokad=", s.dokad, " od=", s.od, ")")
		return false
	# Po zwiększeniu max: da się podnieść min i max.
	s.od = 0.0
	s.dokad = 50.0
	s._ciagnie = "od"
	s._rusz(100.0)
	if s.od <= 0.001:
		printerr("FAIL: nie da się zwiększyć min z 0 (od=", s.od, ")")
		return false
	s._ciagnie = "dokad"
	var dokad_przed: float = s.dokad
	s._rusz(380.0)
	if s.dokad <= dokad_przed:
		printerr("FAIL: nie da się zwiększyć max (dokad=", s.dokad, ")")
		return false
	# Nakładka w środku + przeciągnięcie w prawo nie blokuje.
	s.od = 40.0
	s.dokad = 40.0
	s._zacznij(s._x(40.0))
	s._rusz(300.0)
	if is_equal_approx(s.od, s.dokad) and s.dokad <= 40.001:
		printerr("FAIL: nakładka w środku zablokowała ruch")
		return false
	print("OK suwak: min=0 potem zwiększenie min i max działa")
	return true


func _test_filtr_dobra() -> bool:
	var rynek = Rynek.new()
	var swiat := {
		"rynek_zakupow": {
			"oferty": [
				{
					"id": "a",
					"kategoria": "telefon",
					"cena_zl": 100,
					"odleglosc_km": 5.0,
					"sposob_odbioru": "osobisty",
					"stan": "uzywany",
				},
				{
					"id": "b",
					"kategoria": "telefon",
					"cena_zl": 500,
					"odleglosc_km": 40.0,
					"sposob_odbioru": "wysylka",
					"stan": "nowy",
				},
				{
					"id": "c",
					"kategoria": "telefon",
					"cena_zl": 200,
					"odleglosc_km": 10.0,
					"sposob_odbioru": "oba",
					"stan": "uzywany",
				},
			]
		}
	}
	var lokalnie: Array = rynek.oferty_filtrowane(swiat, "telefon", "", 15.0, 0.0, 1000.0, true, "")
	if lokalnie.size() != 2:
		printerr("FAIL: zasięg 15 km powinien dać 2 oferty, jest ", lokalnie.size())
		return false
	var osobisty: Array = rynek.oferty_filtrowane(swiat, "telefon", "", 999.0, 0.0, 1000.0, true, "osobisty")
	# a (osobisty) + c (oba)
	if osobisty.size() != 2:
		printerr("FAIL: filtr osobisty powinien dać 2, jest ", osobisty.size())
		return false
	var wysylka: Array = rynek.oferty_filtrowane(swiat, "telefon", "", 999.0, 0.0, 1000.0, true, "wysylka")
	# b + c
	if wysylka.size() != 2:
		printerr("FAIL: filtr wysyłka powinien dać 2, jest ", wysylka.size())
		return false
	var cena: Array = rynek.oferty_filtrowane(swiat, "telefon", "", 999.0, 0.0, 150.0, true, "")
	# tylko a (100); c=200 poza
	if cena.size() != 1 or str(cena[0].get("id")) != "a":
		printerr("FAIL: filtr ceny 0–150")
		return false
	# min=0 nie wyłącza filtra (w UI osobna flaga; tu filtruj_cene=true przy od=0)
	var od_zera: Array = rynek.oferty_filtrowane(swiat, "telefon", "", 999.0, 0.0, 100.0, true, "")
	if od_zera.size() != 1:
		printerr("FAIL: filtr od 0 do 100")
		return false
	# Budynki: UI nie pokazuje odbioru — filtr jak przy cenie+odległości (odbior="").
	swiat["rynek_zakupow"]["oferty"] = [
		{"id": "d1", "kategoria": "dom", "cena_zl": 400000, "odleglosc_km": 8.0, "sposob_odbioru": "osobisty", "stan": "uzywany"},
		{"id": "d2", "kategoria": "dom", "cena_zl": 900000, "odleglosc_km": 50.0, "sposob_odbioru": "osobisty", "stan": "uzywany"},
		{"id": "d3", "kategoria": "mieszkanie", "cena_zl": 350000, "odleglosc_km": 12.0, "sposob_odbioru": "osobisty", "stan": "uzywany"},
	]
	var domy: Array = rynek.oferty_filtrowane(swiat, "dom", "", 25.0, 0.0, 500000.0, true, "")
	if domy.size() != 1 or str(domy[0].get("id")) != "d1":
		printerr("FAIL: budynek filtr cena+odległość (bez wysyłki) powinien dać d1")
		return false
	# Auta: przedział cen z całej kategorii (UI buduje suwak nawet gdy stan=nowy pusty).
	swiat["rynek_zakupow"]["oferty"] = [
		{"id": "s1", "kategoria": "samochod", "cena_zl": 12000, "odleglosc_km": 5.0, "sposob_odbioru": "osobisty", "stan": "uzywany"},
		{"id": "s2", "kategoria": "samochod", "cena_zl": 80000, "odleglosc_km": 10.0, "sposob_odbioru": "wysylka", "stan": "nowy"},
	]
	var auta_wszystkie: Array = rynek.oferty_filtrowane(swiat, "samochod", "", 999.0, 0.0, 0.0, false, "")
	var ceny_aut: Array = []
	for o in auta_wszystkie:
		if o is Dictionary and (o.get("cena_zl") is int or o.get("cena_zl") is float):
			ceny_aut.append(float(o["cena_zl"]))
	ceny_aut.sort()
	if ceny_aut.size() < 2 or not is_equal_approx(ceny_aut[0], 12000.0) or not is_equal_approx(ceny_aut[ceny_aut.size() - 1], 80000.0):
		printerr("FAIL: przedział cen aut z kategorii")
		return false
	var tylko_nowe: Array = rynek.oferty_filtrowane(swiat, "samochod", "nowy", 999.0, 0.0, 0.0, false, "")
	if tylko_nowe.size() != 1:
		printerr("FAIL: filtr stan=nowy dla aut")
		return false
	print("OK filtry: zasięg + odbiór + cena (min=0) + budynki bez wysyłki + auta przedział")
	return true
