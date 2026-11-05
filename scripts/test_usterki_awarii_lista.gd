extends SceneTree

## Współczynniki napraw, wagi losowania, ukrycie przyczyny.
## godot --headless --path . --script res://scripts/test_usterki_awarii_lista.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")


func _init() -> void:
	quit(_uruchom())


func _auto(cena: int) -> Dictionary:
	return {
		"kategoria": "samochod",
		"cena_zl": cena,
		"usterki_rzeczywiste": [],
		"usterki_deklarowane": [],
		"konserwacja": {"olej": 40, "zatarcie": false, "rdza": false},
	}


func _uruchom() -> int:
	var rynek = Rynek.new()
	rynek.usterki_katalog()
	var mapa: Dictionary = rynek._usterki_aut["awaria"]["przyczyny"]
	if mapa.size() < 15:
		printerr("FAIL: za mało przyczyn ", mapa.size())
		return 1
	for id in mapa.keys():
		var wpis: Dictionary = mapa[id]
		if not rynek._liczba(wpis.get("wspolczynnik")) or float(wpis["wspolczynnik"]) <= 0.0:
			printerr("FAIL: brak współczynnika ", id)
			return 1
		if not rynek._liczba(wpis.get("waga")) or float(wpis["waga"]) <= 0.0:
			printerr("FAIL: brak wagi ", id)
			return 1
		if not rynek._liczba(wpis.get("min_zl")):
			printerr("FAIL: brak min_zl ", id)
			return 1
	if float(mapa["pasek_rozrzadu"]["wspolczynnik"]) >= float(mapa["wal_korbowy"]["wspolczynnik"]):
		printerr("FAIL: pasek nie jest tańszy współczynnikiem od wału")
		return 1
	var tanio := _auto(40000)
	var drogo := _auto(40000)
	rynek.zastosuj_przyczyne_awarii(tanio, "pasek_rozrzadu")
	rynek.zastosuj_przyczyne_awarii(drogo, "wal_korbowy")
	var cena_paska := rynek.koszt_naprawy_awarii(tanio)
	var cena_walu := rynek.koszt_naprawy_awarii(drogo)
	if cena_paska >= cena_walu:
		printerr("FAIL: przy tym samym aucie pasek nie jest tańszy ", cena_paska, " ", cena_walu)
		return 1
	var male := _auto(12000)
	var duze := _auto(80000)
	rynek.zastosuj_przyczyne_awarii(male, "pasek_rozrzadu")
	rynek.zastosuj_przyczyne_awarii(duze, "pasek_rozrzadu")
	var koszt_malego := rynek.koszt_naprawy_awarii(male)
	var koszt_duzego := rynek.koszt_naprawy_awarii(duze)
	if koszt_duzego <= koszt_malego:
		printerr("FAIL: droższe auto nie ma droższej naprawy ", koszt_malego, " ", koszt_duzego)
		return 1
	var wrak := _auto(1000)
	rynek.zastosuj_przyczyne_awarii(wrak, "pasek_rozrzadu")
	if rynek.koszt_naprawy_awarii(wrak) != int(mapa["pasek_rozrzadu"]["min_zl"]):
		printerr("FAIL: minimum nie działa ", rynek.koszt_naprawy_awarii(wrak))
		return 1
	print("OK współczynnik, wzrost z wartością auta i minimum")

	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var licznik := {}
	var proby := 2000
	for _i in proby:
		var wylosowana := rynek.losuj_przyczyne_awarii(rng)
		licznik[wylosowana] = int(licznik.get(wylosowana, 0)) + 1
	if int(licznik.get("swiece", 0)) <= int(licznik.get("wal_korbowy", 0)) * 3:
		printerr("FAIL: losowanie nie szanuje wag ", licznik.get("swiece", 0), " ", licznik.get("wal_korbowy", 0))
		return 1
	var stara: float = float(mapa["wal_korbowy"]["waga"])
	mapa["wal_korbowy"]["waga"] = 100000
	var prawie_zawsze := 0
	for _j in 40:
		if rynek.losuj_przyczyne_awarii(rng) == "wal_korbowy":
			prawie_zawsze += 1
	mapa["wal_korbowy"]["waga"] = stara
	if prawie_zawsze < 30:
		printerr("FAIL: waga z JSON nie steruje losowaniem ", prawie_zawsze)
		return 1
	print("OK losowanie według wag")

	var auto := _auto(30000)
	rynek.zastosuj_przyczyne_awarii(auto, "pasek_rozrzadu")
	var przed: String = rynek.tekst_awarii_dla_gracza(auto)
	if przed != "Awaria" or przed.find("rozrządu") >= 0 or przed.find("Pasek") >= 0:
		printerr("FAIL: nowa przyczyna widać przed diagnozą ", przed)
		return 1
	var swiat := {"bohater": {"pieniadze": 100000}, "majatek": {"dobra": [auto]}}
	var bez: Dictionary = rynek.diagnozuj_awarie(swiat, auto)
	if bool(bez.get("ok", false)) or str(bez.get("tekst", "")).find("Pasek") >= 0:
		printerr("FAIL: diagnoza bez lawety ", bez)
		return 1
	rynek.laweta_dla_auta(swiat, auto)
	var diag: Dictionary = rynek.diagnozuj_awarie(swiat, auto)
	var po: String = rynek.tekst_awarii_dla_gracza(auto)
	if not bool(diag.get("ok", false)) or po.find("Pasek rozrządu") < 0 or po.find(str(rynek.koszt_naprawy_awarii(auto))) < 0:
		printerr("FAIL: diagnoza nie odsłoniła paska ", diag, po)
		return 1
	var zat := _auto(25000)
	var rdz := _auto(25000)
	rynek.zastosuj_przyczyne_awarii(zat, "zatarcie")
	rynek.zastosuj_przyczyne_awarii(rdz, "rdza")
	if str(zat.get("przyczyna_awarii", "")) != "zatarcie" or str(rdz.get("przyczyna_awarii", "")) != "rdza":
		printerr("FAIL: konserwacja nie trzyma swoich przyczyn")
		return 1
	if rynek.koszt_lawety_awarii() != 450:
		printerr("FAIL: laweta nie jest stała ", rynek.koszt_lawety_awarii())
		return 1
	print("OK ukrycie, odsłonięcie i stała laweta")
	print("PASS lista usterek awarii")
	return 0
