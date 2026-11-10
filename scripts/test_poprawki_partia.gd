extends SceneTree

## Krótki test partii: wagi lokum, remont w tygodniach, wiek rodziny, rodzaj sprzętu.
## godot --headless --path . --script res://scripts/test_poprawki_partia.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Ziarno = preload("res://scripts/ziarno_rodzicow.gd")
const EkranZakupow = preload("res://scripts/ekran_zakupow.gd")
const EkranDomu = preload("res://scripts/ekran_domu.gd")
const Scroll = preload("res://scripts/scroll_dotyk.gd")
const EkranRodziny = preload("res://scripts/ekran_rodziny.gd")
const Main = preload("res://scripts/main.gd")
const Bramka = preload("res://scripts/dostep_admina.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if rynek._udzial_ofert_lokum("mieszkanie") <= rynek._udzial_ofert_lokum("apartament"):
		printerr("FAIL: mieszkanie nie jest częstsze od apartamentu")
		return 1
	if rynek._udzial_ofert_lokum("apartament") <= rynek._udzial_ofert_lokum("dom"):
		printerr("FAIL: apartament nie jest częstszy od domu")
		return 1
	if rynek._udzial_ofert_lokum("dom") <= rynek._udzial_ofert_lokum("willa"):
		printerr("FAIL: dom nie jest częstszy od willi")
		return 1
	var lokal := {
		"id": "n1",
		"kategoria": "mieszkanie",
		"stan": "do_remontu",
		"metraz_m2": 50,
		"wygoda": 40,
		"cena_zl": 300000,
	}
	var tyg: int = rynek.tygodnie_remontu(lokal)
	if tyg < 4 or tyg > 20:
		printerr("FAIL: tygodnie remontu ", tyg)
		return 1
	var koszt: int = rynek.koszt_remontu_prawdziwy(lokal)
	if koszt <= 0:
		printerr("FAIL: koszt remontu")
		return 1
	var swiat := {
		"bohater": {"pieniadze": koszt + 100, "wiek": 4},
		"majatek": {"nieruchomosci": [lokal], "dobra": []},
		"tydzien": 3,
	}
	var start: Dictionary = rynek.remont(swiat, 0)
	if not bool(start.get("ok", false)):
		printerr("FAIL: start remontu ", start.get("powod"))
		return 1
	if not (swiat["majatek"]["nieruchomosci"][0].get("remont_trwa") is Dictionary):
		printerr("FAIL: brak remont_trwa")
		return 1
	if str(swiat["majatek"]["nieruchomosci"][0].get("stan", "")) == "po_remoncie":
		printerr("FAIL: remont skończył się od razu")
		return 1
	var solo: int = rynek.tygodnie_remontu_trybu(lokal, "sam")
	var z_kump: int = rynek.tygodnie_remontu_trybu(lokal, "kumpel")
	var z_fir: int = rynek.tygodnie_remontu_trybu(lokal, "firma")
	if z_kump != maxi(1, int(round(float(solo) * 0.6))):
		printerr("FAIL: kumpel czas ", z_kump, " solo ", solo)
		return 1
	if z_fir != maxi(1, int(round(float(solo) * 0.15))):
		printerr("FAIL: firma czas ", z_fir, " solo ", solo)
		return 1
	if rynek.koszt_startu_remontu(lokal, "firma") <= rynek.koszt_startu_remontu(lokal, "sam"):
		printerr("FAIL: firma nie jest droższa")
		return 1
	rynek.tick_remonty(swiat)
	if int(swiat["bohater"].get("zmeczenie_fizyczne", 0)) != 22:
		printerr("FAIL: zmęczenie ", swiat["bohater"].get("zmeczenie_fizyczne"))
		return 1
	var surowy := {
		"id": "s1",
		"kategoria": "dom",
		"stan": "surowy",
		"metraz_m2": 50,
	}
	var analog := {
		"id": "s1",
		"kategoria": "dom",
		"stan": "do_remontu",
		"metraz_m2": 50,
	}
	var t_sur: int = rynek.tygodnie_remontu_trybu(surowy, "sam")
	var t_ana: int = rynek.tygodnie_remontu_trybu(analog, "sam")
	if t_sur != t_ana * 3:
		printerr("FAIL: surowy czas ", t_sur, " analog ", t_ana)
		return 1
	if rynek.tygodnie_remontu_trybu(surowy, "kumpel") != maxi(1, int(round(float(t_sur) * 0.6))):
		printerr("FAIL: surowy kumpel")
		return 1
	if rynek.tygodnie_remontu_trybu(surowy, "firma") != maxi(1, int(round(float(t_sur) * 0.15))):
		printerr("FAIL: surowy firma")
		return 1
	if rynek.koszt_remontu_prawdziwy(surowy) <= rynek.koszt_remontu_prawdziwy(analog):
		printerr("FAIL: surowy nie droższy")
		return 1
	var sw_k := {
		"bohater": {"pieniadze": 5000000, "zmeczenie_fizyczne": 0},
		"majatek": {"nieruchomosci": [analog.duplicate()], "dobra": []},
		"przyjaciele": [{"imie": {"nazwa": "Olek"}, "relacja": 100}],
		"znajomi": [],
		"rodzina": {},
	}
	var odrzut: Dictionary = rynek.zaproponuj_pomoc_remontu(sw_k, 0, "przyjaciele:0", 1, false)
	if bool(odrzut.get("ok", false)):
		printerr("FAIL: za niska stawka przeszła")
		return 1
	var min100: int = rynek.min_stawka_tygodniowa(analog, 100)
	var zgoda: Dictionary = rynek.zaproponuj_pomoc_remontu(sw_k, 0, "przyjaciele:0", min100, false)
	if not bool(zgoda.get("ok", false)):
		printerr("FAIL: kumpel ", zgoda.get("powod"))
		return 1
	if str(sw_k["majatek"]["nieruchomosci"][0]["remont_trwa"].get("tryb", "")) != "kumpel":
		printerr("FAIL: tryb kumpla")
		return 1
	var ziarno = Ziarno.new()
	var rodzina := {
		"id_urodzenia": "test",
		"bohater": {"wiek": 4},
		"rodzina": {"matka": {"rola": "matka"}, "ojciec": {"rola": "ojciec"}, "dziadkowie": {"lista": [{"linia_matki": true}]}},
		"rodzenstwo": [{}, {}],
		"przyjaciele": [],
		"znajomi": [],
	}
	if not ziarno.uzupelnij_wieki(rodzina):
		printerr("FAIL: wiek nieuzupełniony")
		return 1
	var wiek_m: int = int(rodzina["rodzina"]["matka"]["wiek"])
	var naj := 4
	for s in rodzina["rodzenstwo"]:
		if int(s["wiek"]) > naj:
			naj = int(s["wiek"])
	if wiek_m < naj + 15:
		printerr("FAIL: matka za młoda ", wiek_m, " ", naj)
		return 1
	var przed := wiek_m
	if ziarno.uzupelnij_wieki(rodzina):
		printerr("FAIL: wiek wylosowany drugi raz")
		return 1
	if int(rodzina["rodzina"]["matka"]["wiek"]) != przed:
		printerr("FAIL: wiek matki się zmienił")
		return 1
	var sprzet := {"kategoria": "sprzet", "segment": "sluchawki", "marka": "Sony", "model": "WH"}
	if rynek.nazwa_rodzaju_oferty(sprzet) != "Słuchawki":
		printerr("FAIL: rodzaj")
		return 1
	var zdrowy := {"bohater": {"zmeczenie_fizyczne": 100, "zmeczenie_psychiczne": 40, "kondycja": 100, "psychika": 100}}
	var boh_z: Dictionary = zdrowy["bohater"]
	if absf(rynek.udzial_regeneracji_zmeczenia(boh_z) - 0.80) > 0.001:
		printerr("FAIL: udział przy pełnym zdrowiu")
		return 1
	rynek.regeneruj_zmeczenie_tydzien(zdrowy)
	if int(zdrowy["bohater"]["zmeczenie_fizyczne"]) != 20 or int(zdrowy["bohater"]["zmeczenie_psychiczne"]) != 8:
		printerr("FAIL: regeneracja 80% ", zdrowy["bohater"])
		return 1
	rynek._dodaj_zmeczenie_fizyczne(zdrowy, 22)
	if int(zdrowy["bohater"]["zmeczenie_fizyczne"]) != 42:
		printerr("FAIL: kolejność regen potem +22 ", zdrowy["bohater"]["zmeczenie_fizyczne"])
		return 1
	var chory := {"bohater": {"zmeczenie_fizyczne": 100, "kondycja": 0, "psychika": 0}}
	var boh_c: Dictionary = chory["bohater"]
	if absf(rynek.udzial_regeneracji_zmeczenia(boh_c) - 0.50) > 0.001:
		printerr("FAIL: udział przy złym zdrowiu")
		return 1
	rynek.regeneruj_zmeczenie_tydzien(chory)
	if int(chory["bohater"]["zmeczenie_fizyczne"]) != 50:
		printerr("FAIL: regeneracja 50% ", chory["bohater"])
		return 1
	var rng_k := RandomNumberGenerator.new()
	rng_k.seed = 3
	var miasto_k := {"id": "t", "nazwa": "Testowo"}
	var ks: Dictionary = rynek._losuj_dobro("ksiazka", miasto_k, rng_k, "t", {}, miasto_k, "uzywany")
	var skala_ok := ["swietny", "dobry", "zaczytany", "rozpadajacy"]
	if str(ks.get("rodzaj_nazwa", "")) == "" or not skala_ok.has(str(ks.get("stan_ksiazki", ""))):
		printerr("FAIL: książka ", ks.get("nazwa"), " ", ks.get("stan_ksiazki"))
		return 1
	if int(ks.get("ilosc", 0)) != 1 or not rynek._liczba(ks.get("odleglosc_km")):
		printerr("FAIL: ilość/odległość książki")
		return 1
	var cena_k := int(ks.get("cena_zl", 0))
	if cena_k < 8 or cena_k > 120:
		printerr("FAIL: cena używanej książki ", cena_k)
		return 1
	var sw_o := {"bohater": {"wiedza_pkt": 0}, "rynek_zakupow": {"oferty": [{"id": "o1", "kategoria": "ksiazka", "stan_rzeczywisty": 50, "sposob_odbioru": "osobisty"}]}}
	var oc0: Dictionary = rynek.ocen_stan(sw_o, "o1", false)
	if not bool(oc0.get("nieznany", false)):
		printerr("FAIL: niska wiedza oceniła")
		return 1
	sw_o["bohater"]["wiedza_pkt"] = 20
	var oc1: Dictionary = rynek.ocen_stan(sw_o, "o1", false)
	if bool(oc1.get("nieznany", false)) or absi(int(oc1.get("stan_oceniony", 0)) - 50) > 2:
		printerr("FAIL: wysoka wiedza ", oc1)
		return 1
	if rynek.ma_legitymacje({"bohater": {}}) or not rynek.ma_legitymacje({"bohater": {"uczy_sie": true}}):
		printerr("FAIL: legitymacja")
		return 1
	if rynek.koszt_komunikacji_drobnej(3.0, false) != 0:
		printerr("FAIL: bilet do 5 km")
		return 1
	var bilet: int = rynek.koszt_komunikacji_drobnej(45.0, false)
	var bilet_u: int = rynek.koszt_komunikacji_drobnej(45.0, true)
	if bilet < 2 or bilet > 5 or bilet_u >= bilet:
		printerr("FAIL: bilet ", bilet, " ", bilet_u)
		return 1
	if Bramka.normalizuj_fps(0) != 0 or Bramka.normalizuj_fps(90) != 90 or Bramka.normalizuj_fps(45) != 60:
		printerr("FAIL: fps")
		return 1
	if not Bramka.pin_pasuje(Bramka.PIN_ADMINA) or Bramka.pin_pasuje("0000"):
		printerr("FAIL: pin")
		return 1
	if not Bramka.WLACZ_ADMINA:
		printerr("FAIL: bramka admina wyłączona w tym buildzie testowym")
		return 1
	var pola: Array = Bramka.pola_bohatera({"wiedza_pkt": 4, "pieniadze": 10, "uczy_sie": true}, {"psychika": {"min": 0, "max": 100, "norma": 50}})
	var klucze := {}
	for p in pola:
		if p is Dictionary:
			klucze[str(p.get("klucz", ""))] = true
	if not klucze.has("psychika") or not klucze.has("wiedza_pkt") or not klucze.has("uczy_sie"):
		printerr("FAIL: pola admina ", klucze.keys())
		return 1
	print("OK partia: udziały lokum, remont ", tyg, " tyg., surowy x3, wiek matki ", wiek_m, ", regen, książka, fps i admin")
	return 0
