extends SceneTree

## Jedna awaria, ukryta przyczyna, ceny z JSON, kasa przed naprawą, laweta, warsztat.
## godot --headless --path . --script res://scripts/test_awaria_silnika.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Konserwacja = preload("res://scripts/konserwacja_auta.gd")


func _init() -> void:
	quit(_uruchom())


func _auto(przyczyna: String, cena: int) -> Dictionary:
	var auto := {
		"kategoria": "samochod",
		"nazwa": "Test",
		"cena_zl": cena,
		"konserwacja": {"olej": 5, "filtry": 70, "opony": 70, "zatarcie": false, "rdza": false},
		"usterki_rzeczywiste": [],
		"usterki_deklarowane": [],
		"usterki_ukryte": [],
		"usterki_wykryte": [],
	}
	return auto


func _swiat(auto: Dictionary, kasa: int) -> Dictionary:
	return {
		"bohater": {"pieniadze": kasa},
		"majatek": {"dobra": [auto], "nieruchomosci": []},
	}


func _uruchom() -> int:
	var rynek = Rynek.new()
	var kon = Konserwacja.new()
	var auto := _auto("", 20000)
	rynek.zastosuj_przyczyne_awarii(auto, "zatarcie")
	if not bool(auto.get("nie_jezdzi", false)) or str(auto.get("przyczyna_awarii", "")) != "zatarcie":
		printerr("FAIL: zatarcie nie weszło w awarię ", auto)
		return 1
	if bool(auto.get("przyczyna_znana", false)):
		printerr("FAIL: przyczyna znana od razu")
		return 1
	var przed := rynek.tekst_awarii_dla_gracza(auto)
	if przed != "Awaria" or przed.find("Zatarcie") >= 0 or przed.find("zatarcie") >= 0:
		printerr("FAIL: UI zdradza przyczynę przed diagnozą: ", przed)
		return 1
	var nazwa: String = rynek.nazwa_usterki_dla_gracza("awaria_silnika", auto)
	if nazwa != "Awaria" or nazwa.find("Padnięty") >= 0 or nazwa.find("silnika") >= 0:
		printerr("FAIL: nazwa usterki zdradza przyczynę: ", nazwa)
		return 1
	print("OK zatarcie → awaria, przyczyna ukryta")

	var swiat := _swiat(auto, 100)
	var bez_lawety: Dictionary = rynek.diagnozuj_awarie(swiat, auto)
	if bool(bez_lawety.get("ok", false)) or str(bez_lawety.get("tekst", "")).find("Zatarcie") >= 0:
		printerr("FAIL: diagnoza bez lawety ", bez_lawety)
		return 1
	if bool(auto.get("przyczyna_znana", false)) or int(swiat["bohater"]["pieniadze"]) != 100:
		printerr("FAIL: diagnoza bez lawety zmieniła auto albo kasę")
		return 1
	swiat["bohater"]["pieniadze"] = 100000
	var law: Dictionary = rynek.laweta_dla_auta(swiat, auto)
	if not bool(law.get("ok", false)) or not bool(auto.get("laweta_zamowiona", false)):
		printerr("FAIL: laweta ", law)
		return 1
	var kasa_po_lawecie := int(swiat["bohater"]["pieniadze"])
	if kasa_po_lawecie != 100000 - rynek.koszt_lawety_awarii():
		printerr("FAIL: laweta nie zdjęła kasy ", kasa_po_lawecie)
		return 1
	swiat["bohater"]["pieniadze"] = 0
	var bez_kasy: Dictionary = rynek.diagnozuj_awarie(swiat, auto)
	if bool(bez_kasy.get("ok", false)) or bool(auto.get("przyczyna_znana", false)):
		printerr("FAIL: diagnoza bez kasy odsłoniła przyczynę ", bez_kasy)
		return 1
	if str(bez_kasy.get("tekst", "")).find("Zatarcie") >= 0 or str(bez_kasy.get("tekst", "")).find("Rdza") >= 0:
		printerr("FAIL: tekst braku kasy zdradza przyczynę ", bez_kasy)
		return 1
	swiat["bohater"]["pieniadze"] = 100000
	var diag: Dictionary = rynek.diagnozuj_awarie(swiat, auto)
	var po := rynek.tekst_awarii_dla_gracza(auto)
	if not bool(diag.get("ok", false)) or not bool(auto.get("przyczyna_znana", false)):
		printerr("FAIL: diagnoza ", diag)
		return 1
	if po.find("Zatarcie silnika") < 0 or po.find(str(rynek.koszt_naprawy_awarii(auto))) < 0:
		printerr("FAIL: po diagnozie brak przyczyny albo ceny: ", po)
		return 1
	print("OK diagnoza chowa i odsłania przyczynę")

	var pad := _auto("", 20000)
	rynek.zastosuj_przyczyne_awarii(pad, "padniety_silnik")
	var rdza := _auto("", 20000)
	rynek.zastosuj_przyczyne_awarii(rdza, "rdza")
	var cz := rynek.koszt_naprawy_awarii(auto)
	var cp := rynek.koszt_naprawy_awarii(pad)
	var cr := rynek.koszt_naprawy_awarii(rdza)
	if cz == cp or cz == cr or cp == cr:
		printerr("FAIL: ceny przyczyn nie są różne ", cz, " ", cp, " ", cr)
		return 1
	rynek.usterki_katalog()
	var blok: Dictionary = rynek._usterki_aut["awaria"]["przyczyny"]["zatarcie"]
	var stary_od := int(blok["mechanik_koszt_od_zl"])
	var stary_do := int(blok["mechanik_koszt_do_zl"])
	var stary_mnoz := float(blok["mechanik_mnoznik_ceny"])
	blok["mechanik_koszt_od_zl"] = 7777
	blok["mechanik_koszt_do_zl"] = 7777
	blok["mechanik_mnoznik_ceny"] = 0.01
	if rynek.koszt_naprawy_awarii(auto) != 7777:
		printerr("FAIL: cena nie jest czytana z JSON ", rynek.koszt_naprawy_awarii(auto))
		return 1
	blok["mechanik_koszt_od_zl"] = stary_od
	blok["mechanik_koszt_do_zl"] = stary_do
	blok["mechanik_mnoznik_ceny"] = stary_mnoz
	print("OK różne ceny przyczyn z JSON")

	var surowe := _auto("", 8000)
	rynek.zastosuj_przyczyne_awarii(surowe, "padniety_silnik")
	var sw_odmowa := _swiat(surowe, 50000)
	var przed_kasa := int(sw_odmowa["bohater"]["pieniadze"])
	var odmowa: Dictionary = rynek.mechanik_auta(sw_odmowa, 0)
	if bool(odmowa.get("ok", false)) or not bool(surowe.get("nie_jezdzi", false)) or int(sw_odmowa["bohater"]["pieniadze"]) != przed_kasa:
		printerr("FAIL: naprawa bez lawety ", odmowa, surowe.get("nie_jezdzi"), sw_odmowa["bohater"])
		return 1
	if str(odmowa.get("tekst", "")).find("Zatarcie") >= 0 or str(odmowa.get("tekst", "")).find("Padnięty") >= 0:
		printerr("FAIL: odmowa lawety zdradza przyczynę ", odmowa)
		return 1
	print("OK laweta jest warunkiem naprawy")

	swiat["bohater"]["pieniadze"] = 0
	var warsztat_bez: Dictionary = rynek.warsztat_zatarcia(swiat, auto)
	if bool(warsztat_bez.get("ok", false)) or not bool(auto.get("nie_jezdzi", false)):
		printerr("FAIL: warsztat bez kasy naprawił ", warsztat_bez, auto.get("nie_jezdzi"))
		return 1
	if not bool(auto.get("konserwacja", {}).get("zatarcie", false)):
		printerr("FAIL: brak kasy zdjął zatarcie")
		return 1
	swiat["bohater"]["pieniadze"] = 100000
	var warsztat: Dictionary = rynek.warsztat_zatarcia(swiat, auto)
	if not bool(warsztat.get("ok", false)) or bool(auto.get("nie_jezdzi", false)):
		printerr("FAIL: warsztat nie przywrócił jazdy ", warsztat, auto.get("nie_jezdzi"))
		return 1
	if bool(auto.get("konserwacja", {}).get("zatarcie", false)):
		printerr("FAIL: zatarcie zostało po warsztacie")
		return 1
	if int(swiat["bohater"]["pieniadze"]) >= 100000:
		printerr("FAIL: warsztat nie zdjął kasy")
		return 1
	print("OK brak kasy nic nie naprawia, warsztat od zatarcia przywraca jazdę")

	var stan := kon.stan_startowy()
	stan["olej"] = 10
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var biedny: Dictionary = kon.sprobuj_serwis(stan, "olej", "warsztat", 0, rng)
	if bool(biedny.get("zmieniono", false)) or int(stan["olej"]) != 10:
		printerr("FAIL: serwis bez kasy zmienił olej ", biedny, stan["olej"])
		return 1
	var bogaty: Dictionary = kon.sprobuj_serwis(stan, "olej", "warsztat", 1000, rng)
	if not bool(bogaty.get("zmieniono", false)) or int(stan["olej"]) != 100:
		printerr("FAIL: serwis z kasą ", bogaty, stan["olej"])
		return 1
	print("OK serwis sprawdza kasę przed zmianą stanu")
	print("PASS awaria silnika")
	return 0
