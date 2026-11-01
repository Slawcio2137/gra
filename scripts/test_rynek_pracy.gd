extends SceneTree

## Tablica pracy: małe okno, filtry, negocjacje, upomnienia przed zwolnieniem.
## godot --headless --path . --script res://scripts/test_rynek_pracy.gd

const Rynek = preload("res://scripts/rynek_pracy.gd")
const Katalog = preload("res://scripts/katalog_zawodow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not bool(rynek.rubryka().get("propozycja_do_poprawki", false)):
		printerr("FAIL: rubryka bez propozycji")
		return 1
	var kat = Katalog.new()
	if kat.liczba_zawodow() < 400:
		printerr("FAIL: katalog ", kat.liczba_zawodow())
		return 1
	if _okno(rynek) != 0:
		return 1
	if _filtry(rynek) != 0:
		return 1
	if _wplyw(rynek) != 0:
		return 1
	if _negocjacje(rynek) != 0:
		return 1
	if _upomnienia(rynek) != 0:
		return 1
	if _podwyzka(rynek) != 0:
		return 1
	if _tura_bez_katalogu(rynek) != 0:
		return 1
	if _paliwo() != 0:
		return 1
	print("OK rynek pracy")
	return 0


func _okno(rynek) -> int:
	var swiat := {"tydzien": 3, "bohater": {}}
	var n: int = rynek.aktywuj(swiat, {}, 3)
	var oferty: Array = swiat["rynek_pracy"]["oferty"]
	if n <= 0 or oferty.size() > rynek.okno_start() or oferty.size() >= 400:
		printerr("FAIL: otwarcie ", n, " ", oferty.size())
		return 1
	if rynek.ostatnie_proby() <= 0 or rynek.ostatnie_proby() > rynek.okno_start() * 12:
		printerr("FAIL: próby przy otwarciu ", rynek.ostatnie_proby())
		return 1
	var dodane: int = rynek.uzupelnij(swiat, {}, rynek.wyprzedzenie(), 3)
	if dodane < 1 or dodane > rynek.wyprzedzenie():
		printerr("FAIL: scroll ", dodane)
		return 1
	if swiat["rynek_pracy"]["oferty"].size() > rynek.okno_start() + rynek.wyprzedzenie():
		printerr("FAIL: za dużo ofert ", swiat["rynek_pracy"]["oferty"].size())
		return 1
	if rynek.ostatnie_proby() > 200:
		printerr("FAIL: scroll przeszedł katalog ", rynek.ostatnie_proby())
		return 1
	return 0


func _filtry(rynek) -> int:
	var tania := {"placa_zl": 5300, "wielka_grupa": "5", "nazwa": "Kioskarz", "wymagane_wyksztalcenie": 0, "wymagane_doswiadczenie": 0, "wplyw": {"sylwetka": "+"}}
	var droga := {"placa_zl": 12000, "wielka_grupa": "1", "nazwa": "Dyrektor", "wymagane_wyksztalcenie": 2, "wymagane_doswiadczenie": 4, "wplyw": {"sylwetka": "-"}}
	var studia := {"placa_zl": 9500, "wielka_grupa": "2", "nazwa": "Lekarz", "wymagane_wyksztalcenie": 3, "wymagane_doswiadczenie": 2, "wplyw": {}}
	if rynek.pasuje(tania, {"filtruj_place": true, "placa_od": 10000, "placa_do": 20000}):
		printerr("FAIL: tania weszła w wysoki przedział")
		return 1
	if not rynek.pasuje(droga, {"filtruj_place": true, "placa_od": 10000, "placa_do": 20000}):
		printerr("FAIL: droga wypadła z przedziału")
		return 1
	if rynek.pasuje(studia, {"wyksztalcenie_max": 1}):
		printerr("FAIL: wyższe przeszło filtr branżowy")
		return 1
	if not rynek.pasuje(tania, {"wyksztalcenie_max": 1}):
		printerr("FAIL: podstawowe wypadło")
		return 1
	var swiat := {"tydzien": 1, "bohater": {}}
	var filtry := {"wyksztalcenie_max": 0, "filtruj_place": true, "placa_od": 5000, "placa_do": 6000}
	var n: int = rynek.uzupelnij(swiat, filtry, 6, 1)
	if n < 1:
		printerr("FAIL: filtr nie dał żadnej oferty, próby ", rynek.ostatnie_proby())
		return 1
	for o in swiat["rynek_pracy"]["oferty"]:
		if int(o.get("wymagane_wyksztalcenie", 9)) > 0:
			printerr("FAIL: wykształcenie ", o.get("nazwa"), " ", o.get("wymagane_wyksztalcenie"))
			return 1
		var placa := int(o.get("placa_zl", 0))
		if placa < 5000 or placa > 6000:
			printerr("FAIL: płaca poza filtrem ", placa)
			return 1
	var pusto := {"tydzien": 1, "bohater": {}}
	var zero: int = rynek.uzupelnij(pusto, {"filtruj_place": true, "placa_od": 1, "placa_do": 100}, 8, 1)
	if zero != 0 or rynek.ostatnie_proby() > 8 * 12:
		printerr("FAIL: pusty filtr przebił sufit ", zero, " ", rynek.ostatnie_proby())
		return 1
	return 0


func _wplyw(rynek) -> int:
	var oferta := {
		"wplyw": {
			"zmeczenie_fizyczne": "+",
			"zmeczenie_psychiczne": "+",
			"sylwetka": "-",
			"inteligencja": "+",
			"zdrowie": "-",
			"wyglad": "",
			"sila": "+",
			"kondycja": "-",
			"psychika": "+",
		}
	}
	var tekst: String = rynek.tekst_wplywu(oferta)
	if tekst.find("+") < 0 or tekst.find("−") < 0:
		printerr("FAIL: brak znaków ", tekst)
		return 1
	var i := 0
	while i < tekst.length():
		if tekst[i] >= "0" and tekst[i] <= "9":
			printerr("FAIL: cyfra we wpływie ", tekst)
			return 1
		i += 1
	if rynek.pasuje({"placa_zl": 6400, "nazwa": "Murarz", "wielka_grupa": "7", "wplyw": {"sylwetka": "-"}, "wymagane_wyksztalcenie": 1, "wymagane_doswiadczenie": 1}, {"wplyw_stat": "sylwetka", "wplyw_znak": "+"}):
		printerr("FAIL: minus sylwetki przeszedł filtr plusa")
		return 1
	return 0


func _negocjacje(rynek) -> int:
	var oferta := {"placa_zl": 6400, "wymagane_wyksztalcenie": 2, "wymagane_doswiadczenie": 4, "kod": "1", "nazwa": "Kierownik", "zarobki_zrodlo": "grupa_nadrzedna", "efekty_tygodniowe": {}, "wplyw": {}}
	var slaby := {"poziom_wyksztalcenia": 0, "doswiadczenie_zawodowe": 0}
	var mocny := {"poziom_wyksztalcenia": 3, "doswiadczenie_zawodowe": 8}
	var bez: Dictionary = rynek.negocjuj(oferta, slaby, false, 6400, 0.1)
	if str(bez.get("wynik")) != "odmowa" or int(bez.get("placa_zl", 1)) != 0:
		printerr("FAIL: niedopasowany bez negocjacji ", bez)
		return 1
	var tak: Dictionary = rynek.negocjuj(oferta, mocny, false, 6400, 0.9)
	if str(tak.get("wynik")) != "zgoda" or int(tak.get("placa_zl")) != 6400:
		printerr("FAIL: dopasowany bez negocjacji ", tak)
		return 1
	var widziane := {}
	for rzut in [0.0, 0.02, 0.2, 0.45, 0.7, 0.95, 0.99]:
		for fit_boh in [slaby, mocny]:
			for zadana in [6400, 7000, 8300]:
				var w: Dictionary = rynek.negocjuj(oferta, fit_boh, true, zadana, rzut)
				widziane[str(w.get("wynik"))] = true
	for klucz in ["zgoda", "odmowa", "kontroferta"]:
		if not widziane.has(klucz):
			printerr("FAIL: brak wyniku ", klucz, " ", widziane)
			return 1
	var nisko: String = rynek.rozstrzygnij(true, 2, 0.0, 0.4)
	var wysoko: String = rynek.rozstrzygnij(true, 2, 0.45, 0.4)
	if _ranga(nisko) <= _ranga(wysoko):
		printerr("FAIL: wyższe żądanie nie jest gorsze ", nisko, " ", wysoko)
		return 1
	var lepszy: String = rynek.rozstrzygnij(true, 2, 0.15, 0.4)
	var gorszy: String = rynek.rozstrzygnij(true, 0, 0.15, 0.4)
	if _ranga(lepszy) <= _ranga(gorszy):
		printerr("FAIL: dopasowanie nie pomaga ", lepszy, " ", gorszy)
		return 1
	var band: Dictionary = rynek.pasmo(6400)
	if int(band.get("min_zl")) != 6400 or int(band.get("max_zl")) != 9600:
		printerr("FAIL: pasmo 100–150% ", band)
		return 1
	var srodek: Dictionary = rynek.negocjuj(oferta, mocny, true, 7000, 0.72)
	if str(srodek.get("wynik")) != "kontroferta":
		printerr("FAIL: środek żądania nie jest kontrofertą ", srodek)
		return 1
	if int(srodek.get("placa_zl")) != 6700:
		printerr("FAIL: kontroferta ", srodek)
		return 1
	var odrzucone: Dictionary = rynek.negocjuj(oferta, mocny, true, 9600, 0.99)
	if str(odrzucone.get("wynik")) != "odmowa" or bool(odrzucone.get("odmowa_konczy_aplikacje", true)):
		printerr("FAIL: odmowa żądania kończy aplikację ", odrzucone)
		return 1
	if bool(odrzucone.get("twarda_odmowa", true)):
		printerr("FAIL: spełnione wymagania dostały twardą odmowę ", odrzucone)
		return 1
	var wybory: Array = odrzucone.get("wybory", [])
	if wybory.size() < 3 or str(wybory[0]) != "Tak" or str(wybory[1]) != "Nie" or str(wybory[2]) != "Spróbuj ponownej negocjacji":
		printerr("FAIL: wybory po odmowie ", wybory)
		return 1
	return 0


func _upomnienia(rynek) -> int:
	var swiat := {
		"tydzien": 2,
		"bohater": {"pieniadze": 100, "wiedza_pkt": 0, "kondycja": 10, "zmeczenie_fizyczne": 10, "zmeczenie_psychiczne": 10, "doswiadczenie_zawodowe": 0, "sylwetka": {"punkty": 40, "etap": 1}},
		"praca_gracza": {
			"kod": "711202",
			"nazwa": "Murarz",
			"placa_zl": 6400,
			"angaz": 0,
			"upomnienia": 0,
			"szef": {"nazwa": "Kierownik", "relacja": 50},
			"efekty_tygodniowe": {"zmeczenie_fizyczne": 8, "sylwetka": 2, "propozycja_do_poprawki": true},
		},
	}
	var a: Dictionary = rynek.rozwiaz_tydzien(swiat, 0.99)
	if bool(a.get("zwolniony")) or int(swiat["praca_gracza"].get("upomnienia", 0)) != 1:
		printerr("FAIL: pierwszy zły tydzień ", a, " ", swiat.get("praca_gracza"))
		return 1
	var b: Dictionary = rynek.rozwiaz_tydzien(swiat, 0.99)
	if bool(b.get("zwolniony")) or int(swiat["praca_gracza"].get("upomnienia", 0)) != 2:
		printerr("FAIL: drugie upomnienie ", b)
		return 1
	var c: Dictionary = rynek.rozwiaz_tydzien(swiat, 0.99)
	if bool(c.get("zwolniony")) or not rynek.ma_prace(swiat):
		printerr("FAIL: trzeci zły tydzień zwolnił przy żywej satysfakcji ", c)
		return 1
	if int(swiat["praca_gracza"].get("upomnienia", 0)) != 3:
		printerr("FAIL: upomnienia po trzech tygodniach ", swiat.get("praca_gracza"))
		return 1
	if int(swiat["praca_gracza"].get("satysfakcja", 0)) <= 15:
		printerr("FAIL: satysfakcja spadła do zwolnienia ", swiat.get("praca_gracza"))
		return 1
	var zmeczony := {
		"tydzien": 4,
		"bohater": {"wiedza_pkt": 30, "kondycja": 90, "zmeczenie_fizyczne": 90, "zmeczenie_psychiczne": 10, "doswiadczenie_zawodowe": 6},
		"praca_gracza": {
			"kod": "522102",
			"nazwa": "Kioskarz",
			"placa_zl": 5300,
			"angaz": 90,
			"upomnienia": 0,
			"szef": {"relacja": 60},
			"efekty_tygodniowe": {},
		},
	}
	var d: Dictionary = rynek.rozwiaz_tydzien(zmeczony, 0.99)
	if not bool(d.get("upomnienie")) or bool(d.get("zwolniony")):
		printerr("FAIL: zmęczenie ", d)
		return 1
	return 0


func _podwyzka(rynek) -> int:
	var slaby := _swiat_pracy(10, 0, 10)
	var a: Dictionary = rynek.popros_o_podwyzke(slaby, 0.2)
	if bool(a.get("ok")) or int(a.get("relacja", 50)) >= 50:
		printerr("FAIL: słaby angaż ", a)
		return 1
	var mocny := _swiat_pracy(90, 40, 100)
	mocny["bohater"]["doswiadczenie_zawodowe"] = 10
	mocny["bohater"]["zmeczenie_fizyczne"] = 0
	mocny["bohater"]["zmeczenie_psychiczne"] = 0
	var b: Dictionary = rynek.popros_o_podwyzke(mocny, 0.2)
	if not bool(b.get("ok")) or int(b.get("relacja", 0)) <= 50:
		printerr("FAIL: wysoki angaż ", b, " skut=", rynek.skutecznosc(mocny["bohater"], 90))
		return 1
	if int(b.get("placa_zl")) <= 6400:
		printerr("FAIL: płaca nie drgnęła ", b)
		return 1
	return 0


func _tura_bez_katalogu(rynek) -> int:
	var swiat := {"tydzien": 5, "bohater": {"pieniadze": 10}}
	var przed: Dictionary = rynek.tick(swiat, 0.5)
	if swiat.has("rynek_pracy") and swiat["rynek_pracy"].get("oferty") is Array and swiat["rynek_pracy"]["oferty"].size() > 0:
		printerr("FAIL: tura urodziła oferty")
		return 1
	if int(przed.get("wyplata", 0)) != 0:
		printerr("FAIL: wypłata bez pracy")
		return 1
	rynek.aktywuj(swiat, {}, 5)
	var ile: int = swiat["rynek_pracy"]["oferty"].size()
	swiat["tydzien"] = 6
	rynek.tick(swiat, 0.99)
	if swiat["rynek_pracy"]["oferty"].size() > ile:
		printerr("FAIL: tura dodała ogłoszenia ", swiat["rynek_pracy"]["oferty"].size())
		return 1
	if swiat["rynek_pracy"]["oferty"].size() > 30:
		printerr("FAIL: tura ma za dużo ", swiat["rynek_pracy"]["oferty"].size())
		return 1
	return 0


func _swiat_pracy(angaz: int, wiedza: int, kondycja: int) -> Dictionary:
	return {
		"tydzien": 1,
		"bohater": {"wiedza_pkt": wiedza, "kondycja": kondycja, "zmeczenie_fizyczne": 0, "zmeczenie_psychiczne": 0, "doswiadczenie_zawodowe": 0},
		"praca_gracza": {
			"kod": "711202",
			"nazwa": "Murarz",
			"placa_zl": 6400,
			"angaz": angaz,
			"upomnienia": 0,
			"szef": {"nazwa": "Kierownik", "relacja": 50},
			"efekty_tygodniowe": {},
		},
	}


func _ranga(wynik: String) -> int:
	match wynik:
		"zgoda":
			return 3
		"kontroferta":
			return 2
		"odmowa":
			return 1
	return 0


func _paliwo() -> int:
	if not FileAccess.file_exists("res://świat/polska/kraj.json"):
		printerr("FAIL: brak kraj.json")
		return 1
	var plik := FileAccess.open("res://świat/polska/kraj.json", FileAccess.READ)
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if not (dane is Dictionary):
		return 1
	var paliwo: Variant = dane.get("cena_paliwa", {})
	if not (paliwo is Dictionary):
		return 1
	if float(paliwo.get("benzyna", -1)) != 6.0 or float(paliwo.get("gaz", -1)) != 2.5 or float(paliwo.get("energia", -1)) != 0.9:
		printerr("FAIL: paliwo ", paliwo)
		return 1
	if paliwo.get("olej_napedowy", "brak") != null or paliwo.has("diesel"):
		printerr("FAIL: diesel")
		return 1
	return 0
