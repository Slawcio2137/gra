extends SceneTree

## Zużycie od km, starzenie, szansa, wagi, rocznik, przebieg z przejazdu, diagnoza z części.
## godot --headless --path . --script res://scripts/test_zuzycie_auta.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Konserwacja = preload("res://scripts/konserwacja_auta.gd")
const Przejazd = preload("res://scripts/przejazd_auta.gd")


func _init() -> void:
	quit(_uruchom())


func _auto() -> Dictionary:
	return {
		"kategoria": "samochod",
		"cena_zl": 30000,
		"przebieg_km": 1000,
		"rok_produkcji": 2024,
		"konserwacja": {"olej": 80, "filtry": 80, "opony": 80, "zatarcie": false, "rdza": false, "konserwacja_zima": false},
		"czesci": {"pasek_rozrzadu": 100},
		"usterki_rzeczywiste": [],
		"usterki_deklarowane": [],
		"nie_jezdzi": false,
	}


func _uruchom() -> int:
	var rynek = Rynek.new()
	var kon = Konserwacja.new()
	var jedzie := _auto()
	var stoi := _auto()
	kon.zuzyj_kilometry(jedzie["konserwacja"], 2000.0, true)
	kon.zuzyj_kilometry(stoi["konserwacja"], 2000.0, false)
	if int(jedzie["konserwacja"]["olej"]) >= int(stoi["konserwacja"]["olej"]):
		printerr("FAIL: jazda nie zużyła więcej oleju ", jedzie["konserwacja"]["olej"], " ", stoi["konserwacja"]["olej"])
		return 1
	print("OK zużycie od km, stojące mniejsze")

	var mlode := _auto()
	mlode["rok_produkcji"] = 2026
	var stare := _auto()
	stare["rok_produkcji"] = 2000
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for _i in 40:
		rynek.starzej_auto_tydzien(mlode, rng)
		rynek.starzej_auto_tydzien(stare, rng)
	if int(stare["czesci"]["pasek_rozrzadu"]) >= int(mlode["czesci"]["pasek_rozrzadu"]):
		printerr("FAIL: starsze auto nie starzeje paska szybciej ", stare["czesci"], mlode["czesci"])
		return 1
	print("OK starzenie paska od wieku")

	var swieze := _auto()
	swieze["przebieg_km"] = 0
	var zajezdzone := _auto()
	zajezdzone["przebieg_km"] = 280000
	zajezdzone["konserwacja"]["olej"] = 5
	zajezdzone["konserwacja"]["filtry"] = 10
	zajezdzone["konserwacja"]["opony"] = 10
	if rynek.szansa_awarii_auta(zajezdzone) <= rynek.szansa_awarii_auta(swieze):
		printerr("FAIL: szansa nie rośnie ze stanem ", rynek.szansa_awarii_auta(swieze), " ", rynek.szansa_awarii_auta(zajezdzone))
		return 1
	var rng_w := RandomNumberGenerator.new()
	rng_w.seed = 99
	var zdrowe := 0
	var krytyczne := 0
	var n := 800
	for _j in n:
		if rynek.losuj_przyczyne_awarii(rng_w, swieze) == "zatarcie":
			zdrowe += 1
		if rynek.losuj_przyczyne_awarii(rng_w, zajezdzone) == "zatarcie":
			krytyczne += 1
	if krytyczne <= zdrowe * 2:
		printerr("FAIL: krytyczny olej nie podbija zatarcia ", zdrowe, " ", krytyczne)
		return 1
	var duzy := _auto()
	duzy["przebieg_km"] = 220000
	var malo := _auto()
	malo["przebieg_km"] = 10000
	var pasek_duzo := 0
	var pasek_malo := 0
	for _k in n:
		if rynek.losuj_przyczyne_awarii(rng_w, duzy) == "pasek_rozrzadu":
			pasek_duzo += 1
		if rynek.losuj_przyczyne_awarii(rng_w, malo) == "pasek_rozrzadu":
			pasek_malo += 1
	if pasek_duzo <= pasek_malo:
		printerr("FAIL: duży przebieg nie podbija paska ", pasek_malo, " ", pasek_duzo)
		return 1
	print("OK szansa i modyfikatory wag")

	var rok_nowy := rynek.losuj_rok_produkcji("nowy", rng)
	var rok_uzywany := rynek.losuj_rok_produkcji("uzywany", rng)
	if rok_uzywany >= rok_nowy:
		printerr("FAIL: rocznik używanego ", rok_uzywany, " ", rok_nowy)
		return 1
	var przejazd = Przejazd.new()
	var auto := _auto()
	var przed := int(auto["przebieg_km"])
	if not bool(przejazd.oblicz(40.0, auto, Przejazd.TRYB_DOZWOLONA, 0.0, 6.0).get("ok", false)):
		auto["spalanie"] = 6.0
		auto["predkosc_max_kmh"] = 160
	przejazd.oblicz(40.0, auto, Przejazd.TRYB_DOZWOLONA, 0.0, 6.0)
	if int(auto["przebieg_km"]) != przed:
		printerr("FAIL: sam koszt przejazdu doliczył km")
		return 1
	przejazd.dolicz_przebieg(auto, 40.0)
	rynek.nalicz_zuzycie_przejazdu(auto, 0.0, true)
	if int(auto["przebieg_km"]) != przed + 40:
		printerr("FAIL: dolicz_przebieg ", auto["przebieg_km"])
		return 1
	print("OK rocznik i kilometry z przejazdu")

	var karta := _auto()
	karta["nie_jezdzi"] = true
	karta["konserwacja"]["olej"] = 4
	karta["usterki_rzeczywiste"] = ["awaria_silnika"]
	var swiat := {"bohater": {"pieniadze": 50000}, "majatek": {"dobra": [karta]}}
	rynek.laweta_dla_auta(swiat, karta)
	var diag: Dictionary = rynek.diagnozuj_awarie(swiat, karta)
	if str(diag.get("przyczyna", "")) != "zatarcie":
		printerr("FAIL: diagnoza nie wzięła oleju ", diag)
		return 1
	var lista: Array = karta.get("usterki_rzeczywiste", [])
	if not lista.has("zatarcie") or lista.has("awaria_silnika"):
		printerr("FAIL: karta rozjechała się z przyczyną ", lista)
		return 1
	if rynek.tekst_awarii_dla_gracza(karta).find("Zatarcie") < 0:
		printerr("FAIL: po diagnozie brak nazwy")
		return 1
	karta["przyczyna_znana"] = false
	if rynek.nazwa_usterki_dla_gracza("zatarcie", karta) != "Awaria":
		printerr("FAIL: karta zdradza przyczynę przed diagnozą")
		return 1
	print("OK diagnoza ze stanu części i spójna karta")
	print("PASS zużycie auta")
	return 0
