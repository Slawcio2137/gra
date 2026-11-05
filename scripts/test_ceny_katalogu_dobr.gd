extends SceneTree

## Udział 70/30, krzywa wieku per kategoria, klamra pasma i drabinka katalogów.
## godot --headless --path . --script res://scripts/test_ceny_katalogu_dobr.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")

const DRABINKA := ["budzet", "srednia", "premium", "flagowiec"]


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not _test_udzial_nowych(rynek):
		return 1
	if not _test_krzywa_wieku(rynek):
		return 1
	if not _test_pasmo(rynek):
		return 1
	if not _test_drabinka(rynek):
		return 1
	print("OK ceny katalogu dóbr")
	return 0


func _test_udzial_nowych(rynek) -> bool:
	var dane: Dictionary = rynek.wczytaj()
	var blok: Dictionary = dane.get("udzial_ofert_dobr", {}) if dane.get("udzial_ofert_dobr") is Dictionary else {}
	if absf(float(blok.get("nowy", 0)) - 0.7) > 0.001:
		printerr("FAIL: udzial_ofert_dobr.nowy nie jest 0.7")
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261105
	var miasto := {"id": "t1", "nazwa": "Testowo", "powiat_id": "p", "wojewodztwo": "mazowieckie", "kraj": "PL"}
	var nowy := 0
	var n := 2000
	for i in n:
		var o: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "t1", {})
		if str(o.get("stan", "")) == "nowy":
			nowy += 1
	var udzial := float(nowy) / float(n)
	if udzial < 0.64 or udzial > 0.76:
		printerr("FAIL: udział nowych ", udzial, " przy N=", n)
		return false
	print("OK udział nowych=", udzial, " N=", n)
	return true


func _test_krzywa_wieku(rynek) -> bool:
	var baza := 10000.0
	var poprzednia := 0.0
	for kat in ["ksiazka", "telefon", "laptop", "komputer", "rower"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var uzywany: float = rynek._cena_z_katalogu_wiekiem(baza, "uzywany", 3, 100, rng, kat)
		if uzywany <= poprzednia:
			printerr("FAIL: ", kat, " po 3 latach nie zostaje droższy od szybciej taniejącej kategorii ", uzywany, " <= ", poprzednia)
			return false
		poprzednia = uzywany
		var rng_n := RandomNumberGenerator.new()
		rng_n.seed = 11
		var nowy: float = rynek._cena_z_katalogu_wiekiem(baza, "nowy", 3, 100, rng_n, kat)
		if uzywany >= nowy:
			printerr("FAIL: używany ", kat, " nie jest tańszy od nowego ", uzywany, " ", nowy)
			return false
	var rng_pod := RandomNumberGenerator.new()
	rng_pod.seed = 3
	var podloga: float = rynek._cena_z_katalogu_wiekiem(baza, "uzywany", 40, 100, rng_pod, "telefon")
	var stosunek := podloga / baza
	if stosunek < 0.42 * 0.92 - 0.001 or stosunek > 0.42 * 1.08 + 0.001:
		printerr("FAIL: podłoga telefonu ", stosunek)
		return false
	var rng_row := RandomNumberGenerator.new()
	rng_row.seed = 3
	var podloga_row: float = rynek._cena_z_katalogu_wiekiem(baza, "uzywany", 40, 100, rng_row, "rower")
	var stosunek_row := podloga_row / baza
	if stosunek_row < 0.55 * 0.92 - 0.001 or stosunek_row > 0.55 * 1.08 + 0.001:
		printerr("FAIL: podłoga roweru ", stosunek_row)
		return false
	if not rynek._kategoria_uzywa_lat("telefon") or not rynek._kategoria_uzywa_lat("rower") or not rynek._kategoria_uzywa_lat("ksiazka"):
		printerr("FAIL: telefon, rower albo książka bez lat")
		return false
	print("OK krzywa, podłoga telefonu=", stosunek, " roweru=", stosunek_row)
	return true


func _test_pasmo(rynek) -> bool:
	if int(rynek._ogranicz_pasmem_dobra("telefon", "nowy", 100000.0)) != 9000:
		printerr("FAIL: klamra nowego telefonu")
		return false
	if int(rynek._ogranicz_pasmem_dobra("telefon", "uzywany", 10.0)) != 180:
		printerr("FAIL: klamra używanego telefonu")
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var miasto := {"id": "t1", "nazwa": "Testowo", "powiat_id": "p", "wojewodztwo": "mazowieckie", "kraj": "PL"}
	var drogi := {
		"id": "test_drogi",
		"marka": "Test",
		"model": "Poza pasmem",
		"segment": "flagowiec",
		"cena_zl": 100000,
	}
	var oferta: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "t1", {}, {}, "nowy", drogi)
	if int(oferta.get("cena_zl", 0)) != 9000:
		printerr("FAIL: oferta nowego poza pasmem ", oferta.get("cena_zl"))
		return false
	var tani := {
		"id": "test_tani",
		"marka": "Test",
		"model": "Pod pasmem",
		"segment": "budzet",
		"cena_zl": 50,
	}
	var uzywany: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "t1", {}, {}, "uzywany", tani)
	if int(uzywany.get("cena_zl", 0)) != 180:
		printerr("FAIL: oferta używanego pod pasmem ", uzywany.get("cena_zl"))
		return false
	var bez_ceny := {
		"id": "test_brak",
		"marka": "Brak",
		"model": "Cennika",
		"segment": "budzet",
	}
	var z_pasma: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "t1", {}, {}, "nowy", bez_ceny)
	var cena := int(z_pasma.get("cena_zl", -1))
	if cena < 450 or cena > 9000 or cena % 10 != 0:
		printerr("FAIL: brak ceny katalogowej nie wylosował pasma ", cena)
		return false
	var w_pasmie: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "t1", {}, {}, "nowy", {
		"id": "test_16pro",
		"marka": "Apple",
		"model": "iPhone 16 Pro 128 GB",
		"segment": "flagowiec",
		"cena_zl": 5299,
	})
	if int(w_pasmie.get("cena_zl", 0)) != 5300:
		printerr("FAIL: cena katalogowa 5299 ścięta albo źle zaokrąglona ", w_pasmie.get("cena_zl"))
		return false
	print("OK pasmo klamry i zapas")
	return true


func _test_drabinka(rynek) -> bool:
	for kat in ["telefon", "rower", "komputer", "laptop", "sprzet", "ksiazka"]:
		var lista: Array = rynek._modele_katalogu_dobra(kat)
		if lista.size() < 10:
			printerr("FAIL: za mało pozycji ", kat, " ", lista.size())
			return false
		var licznik := {"budzet": 0, "srednia": 0, "premium": 0, "flagowiec": 0}
		var waga_budzet := 0.0
		var waga_flagowiec := 0.0
		var min_cena := 100000000.0
		var max_cena := 0.0
		for m in lista:
			if not (m is Dictionary):
				printerr("FAIL: rekord nie jest słownikiem ", kat)
				return false
			var segment := str(m.get("segment", ""))
			if not licznik.has(segment):
				printerr("FAIL: segment ", segment, " w ", kat)
				return false
			licznik[segment] = int(licznik[segment]) + 1
			var waga := float(m.get("waga", 0))
			if waga <= 0.0:
				printerr("FAIL: waga ", kat, " ", m.get("id"))
				return false
			if segment == "budzet" and waga > waga_budzet:
				waga_budzet = waga
			if segment == "flagowiec" and waga > waga_flagowiec:
				waga_flagowiec = waga
			if str(m.get("id", "")) == "" or str(m.get("marka", "")) == "":
				printerr("FAIL: brak id albo marki ", kat)
				return false
			if str(m.get("model", m.get("nazwa", ""))) == "":
				printerr("FAIL: brak modelu ", kat)
				return false
			if not (m.get("cena_zl") is int or m.get("cena_zl") is float) or float(m.get("cena_zl")) <= 0.0:
				printerr("FAIL: cena ", kat, " ", m.get("id"))
				return false
			if not (m.get("szacunek") is bool):
				printerr("FAIL: szacunek nie jest bool ", kat, " ", m.get("id"))
				return false
			if str(m.get("zrodlo", "")) == "" or str(m.get("zrodlo_opis", "")) == "":
				printerr("FAIL: brak źródła ", kat, " ", m.get("id"))
				return false
			if int(m.get("rok_cennika", 0)) < 2020:
				printerr("FAIL: rok cennika ", kat, " ", m.get("id"))
				return false
			var cena := float(m.get("cena_zl"))
			if cena < min_cena:
				min_cena = cena
			if cena > max_cena:
				max_cena = cena
		for segment in DRABINKA:
			if int(licznik[segment]) < 2:
				printerr("FAIL: segment ", segment, " w ", kat, " ma ", licznik[segment])
				return false
		if waga_budzet <= waga_flagowiec:
			printerr("FAIL: budżet nie jest popularniejszy od flagowca ", kat)
			return false
		if min_cena >= max_cena * 0.4:
			printerr("FAIL: za wąski rozrzut ", kat, " ", min_cena, " ", max_cena)
			return false
	var telefony: Array = rynek._modele_katalogu_dobra("telefon")
	var szukane := {
		"iPhone 16 Pro": false,
		"iPhone 17 Pro": false,
		"S25 Ultra": false,
		"Pixel 9 Pro": false,
		"Xiaomi 15": false,
	}
	for t in telefony:
		var model := "%s %s" % [str(t.get("marka", "")), str(t.get("model", ""))]
		for klucz in szukane.keys():
			if model.find(klucz) >= 0:
				szukane[klucz] = true
	for klucz2 in szukane.keys():
		if not bool(szukane[klucz2]):
			printerr("FAIL: brak flagowca ", klucz2)
			return false
	var sluch := {
		"id": "test_airpods",
		"marka": "Apple",
		"model": "AirPods Max",
		"segment": "flagowiec",
		"podkategoria": "sluchawki",
		"cena_zl": 2499,
	}
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 9
	var miasto2 := {"id": "t1", "nazwa": "Testowo", "powiat_id": "p", "wojewodztwo": "mazowieckie", "kraj": "PL"}
	var oferta_s: Dictionary = rynek._losuj_dobro("sprzet", miasto2, rng2, "t1", {}, {}, "uzywany", sluch)
	if str(oferta_s.get("segment", "")) != "sluchawki" or str(oferta_s.get("segment_ceny", "")) != "flagowiec":
		printerr("FAIL: sprzęt zgubił podkategorię albo szczebel ", oferta_s.get("segment"), " ", oferta_s.get("segment_ceny"))
		return false
	print("OK drabinka katalogów")
	return true
