extends SceneTree

## Wspólne koło wag, nowe modele bez duplikatów, filtr marki i segmentu, udział 70% na Wszystkie.
## godot --headless --path . --script res://scripts/test_losowanie_ofert.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not _test_wagi(rynek):
		return 1
	if not _test_tylko_uzywane(rynek):
		return 1
	if not _test_nowe_bez_duplikatow(rynek):
		return 1
	if not _test_filtr_przed_losowaniem(rynek):
		return 1
	if not _test_wszystkie_siedemdziesiat(rynek):
		return 1
	if not _test_nowe_auta_waga(rynek):
		return 1
	print("OK losowanie ofert")
	return 0


func _test_wagi(rynek) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lista := [
		{"id": "lekki", "waga": 1},
		{"id": "ciezki", "waga": 9},
		{"id": "zero", "waga": 0},
	]
	var ciezki := 0
	var zero := 0
	var n := 4000
	for _i in n:
		var r: Dictionary = rynek._losuj_rekord_wazony(lista, rng, false)
		var id := str(r.get("id", ""))
		if id == "ciezki":
			ciezki += 1
		elif id == "zero":
			zero += 1
	var udzial_ciezki := float(ciezki) / float(n)
	var udzial_zero := float(zero) / float(n)
	# 9 / (9 + 1 + 0.1) = 0.891. Równy los dałby ~0.33.
	if udzial_ciezki < 0.84 or udzial_ciezki > 0.94:
		printerr("FAIL: waga 9 nie dominuje ", udzial_ciezki)
		return false
	# Podłoga 0.1, nie wykluczenie. 0.1 / 10.1 ≈ 0.01.
	if udzial_zero < 0.002 or udzial_zero > 0.03:
		printerr("FAIL: waga 0 nie siedzi na podłodze 0.1 ", udzial_zero)
		return false
	print("OK wagi ciezki=", udzial_ciezki, " zero=", udzial_zero)
	return true


func _test_tylko_uzywane(rynek) -> bool:
	var lista := [
		{"id": "zwykly", "waga": 10, "tylko_uzywane": false},
		{"id": "kotwica", "waga": 10, "tylko_uzywane": true},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var kotwica := 0
	var n := 4000
	for _i in n:
		var r: Dictionary = rynek._losuj_rekord_wazony(lista, rng, true)
		if str(r.get("id", "")) == "kotwica":
			kotwica += 1
	var udzial := float(kotwica) / float(n)
	# 1.35 / 2.35 ≈ 0.574. Bez mnożnika byłoby 0.5.
	if udzial < 0.54 or udzial > 0.62:
		printerr("FAIL: ×1.35 tylko_uzywane ", udzial)
		return false
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 3
	var bez := 0
	for _j in n:
		var r2: Dictionary = rynek._losuj_rekord_wazony(lista, rng2, false)
		if str(r2.get("id", "")) == "kotwica":
			bez += 1
	var udzial_bez := float(bez) / float(n)
	if udzial_bez < 0.46 or udzial_bez > 0.54:
		printerr("FAIL: bez preferencji kotwica nie jest pół na pół ", udzial_bez)
		return false
	print("OK tylko_uzywane ", udzial, " bez=", udzial_bez)
	return true


func _test_nowe_bez_duplikatow(rynek) -> bool:
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var swiat := {
		"tydzien": 1,
		"rynek_zakupow": {
			"ziarno": 4,
			"miasto_gracza_id": "1203",
			"miejsce_zrodlo_id": "1203",
			"oferty": [],
		},
	}
	var modele: int = rynek.liczba_modeli_katalogu("telefon")
	var dodane := 0
	for _k in 6:
		var porcja: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
			"poziom": "polska",
			"km": 9999.0,
			"kategoria": "telefon",
			"stan": "nowy",
		}, 16)
		dodane += porcja
		if porcja <= 0:
			break
	if dodane != modele:
		printerr("FAIL: nowe telefony ", dodane, " katalog ", modele)
		return false
	var widziane := {}
	for o in swiat["rynek_zakupow"]["oferty"]:
		if str(o.get("stan", "")) != "nowy":
			printerr("FAIL: nowe okno dało ", o.get("stan"))
			return false
		var kid := str(o.get("katalog_id", ""))
		if kid == "" or widziane.has(kid):
			printerr("FAIL: duplikat nowego modelu ", kid)
			return false
		widziane[kid] = true
	# Niezależne losowania wolnego modelu (pusta pula zajętych) idą wagą, nie po równo.
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	var a16 := 0
	var pro := 0
	for _n in 2000:
		var m: Dictionary = rynek._wolny_model_nowego("telefon", [], rng, {})
		var id := str(m.get("id", ""))
		if id == "samsung_a16_128":
			a16 += 1
		elif id == "apple_iphone_17_pro":
			pro += 1
	if a16 < pro * 2:
		printerr("FAIL: nowe telefony nie idą wagą A16=", a16, " 17 Pro=", pro)
		return false
	print("OK nowe bez duplikatów ", dodane, " A16=", a16, " 17Pro=", pro)
	return true


func _test_filtr_przed_losowaniem(rynek) -> bool:
	var kandydaci: Array = rynek._kandydaci_katalogu_dobra("telefon", {
		"marki": ["Samsung"],
		"segment": "flagowiec",
	}, true)
	if kandydaci.size() != 1 or str(kandydaci[0].get("id", "")) != "samsung_s25_ultra":
		printerr("FAIL: pula przed losem ", kandydaci.size(), " ", kandydaci)
		return false
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var swiat := {
		"tydzien": 1,
		"rynek_zakupow": {
			"ziarno": 8,
			"miasto_gracza_id": "1203",
			"miejsce_zrodlo_id": "1203",
			"oferty": [],
		},
	}
	var dodane: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "nowy",
		"marki": ["Samsung"],
		"segment": "flagowiec",
	}, 8)
	if dodane != 1:
		printerr("FAIL: filtr Samsung flagowiec dał ", dodane)
		return false
	for o in swiat["rynek_zakupow"]["oferty"]:
		if str(o.get("marka", "")) != "Samsung" or str(o.get("segment_ceny", "")) != "flagowiec":
			printerr("FAIL: oferta poza filtrem ", o.get("marka"), " ", o.get("segment_ceny"))
			return false
	var puste: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "uzywany",
		"marki": ["Apple"],
		"segment": "budzet",
	}, 4)
	if puste != 0:
		printerr("FAIL: Apple budżet nie jest pusty ", puste)
		return false
	var uzywane: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "uzywany",
		"marki": ["Samsung"],
		"segment": "budzet",
	}, 6)
	if uzywane < 1:
		printerr("FAIL: brak używanych Samsung budżet")
		return false
	var po_filtrze: Array = rynek.oferty_filtrowane(swiat, "telefon", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, ["Samsung"], "", "polska", "budzet")
	if po_filtrze.size() != uzywane:
		printerr("FAIL: lista filtra ", po_filtrze.size(), " generacja ", uzywane)
		return false
	for o2 in po_filtrze:
		if str(o2.get("marka", "")) != "Samsung" or str(o2.get("segment_ceny", "")) != "budzet" or str(o2.get("stan", "")) != "uzywany":
			printerr("FAIL: lista ma obcą ofertę ", o2.get("marka"), o2.get("segment_ceny"), o2.get("stan"))
			return false
	print("OK filtr marki i segmentu, używane=", uzywane)
	return true


func _test_wszystkie_siedemdziesiat(rynek) -> bool:
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var hero: Dictionary = rynek._miasto_po_id(miasta, "1203")
	var rng := RandomNumberGenerator.new()
	rng.seed = 70
	var nowy := 0
	var n := 600
	var filtry := {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "",
	}
	for _i in n:
		var o: Dictionary = rynek._wylosuj_dobro_pod_filtr(hero, miasta, rng, filtry, {}, [])
		if o.is_empty():
			printerr("FAIL: Wszystkie nie dało oferty")
			return false
		if str(o.get("stan", "")) == "nowy":
			nowy += 1
	var udzial := float(nowy) / float(n)
	if udzial < 0.62 or udzial > 0.78:
		printerr("FAIL: Wszystkie udział nowych ", udzial)
		return false
	print("OK Wszystkie nowych=", udzial)
	return true


func _test_nowe_auta_waga(rynek) -> bool:
	var modele: Array = rynek._modele_marki("Toyota", true, "")
	if modele.size() < 2:
		printerr("FAIL: brak nowych Toyot")
		return false
	var ciezkie_id := ""
	var lekkie_id := ""
	var ciezkie_w := 0.0
	var lekkie_w := 1000000.0
	for m in modele:
		var w := float(m.get("waga", 1))
		if w > ciezkie_w:
			ciezkie_w = w
			ciezkie_id = str(m.get("id", ""))
		if w < lekkie_w:
			lekkie_w = w
			lekkie_id = str(m.get("id", ""))
	if ciezkie_id == "" or ciezkie_id == lekkie_id or ciezkie_w < lekkie_w * 2.0:
		printerr("FAIL: Toyota bez rozrzutu wag")
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var ciezkie := 0
	var lekkie := 0
	for _i in 2500:
		var r: Dictionary = rynek._losuj_rekord_wazony(modele, rng, false)
		var id := str(r.get("id", ""))
		if id == ciezkie_id:
			ciezkie += 1
		elif id == lekkie_id:
			lekkie += 1
	if lekkie == 0 or float(ciezkie) / float(lekkie) < (ciezkie_w / lekkie_w) * 0.45:
		printerr("FAIL: nowe Toyoty nie idą wagą ", ciezkie, " ", lekkie, " wagi ", ciezkie_w, " ", lekkie_w)
		return false
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var hero: Dictionary = rynek._wzbogac_jedno_miasto(rynek._miasto_po_id(miasta, "1203"))
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 22
	var trafione := 0
	for _j in 40:
		var o: Dictionary = rynek._nowe_auto_w_filtrze(hero, "1203", miasta, rng2, {"km": 9999.0}, ["Toyota"], "", "polska")
		if o.is_empty():
			continue
		if str(o.get("marka", "")) != "Toyota" or str(o.get("stan", "")) != "nowy":
			printerr("FAIL: nowe auto poza Toyotą ", o.get("marka"), o.get("stan"))
			return false
		trafione += 1
	if trafione < 5:
		printerr("FAIL: za mało nowych Toyot z filtra ", trafione)
		return false
	print("OK waga nowych aut ", ciezkie_id, "/", lekkie_id, " ", ciezkie, "/", lekkie, " oferty=", trafione)
	return true
