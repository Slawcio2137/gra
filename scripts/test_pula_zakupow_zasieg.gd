extends SceneTree

## Pula zakupów idzie za ludnością zakresu. Ekran dociąga po kilka, karta ma km.
## godot --headless --path . --script res://scripts/test_pula_zakupow_zasieg.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.is_empty():
		printerr("FAIL: brak miast")
		return 1
	var kotwica: Dictionary = rynek._miasto_po_id(miasta, "1203")
	if str(kotwica.get("nazwa", "")) != "Chrzanów" or bool(kotwica.get("brak_miasta", false)):
		printerr("FAIL: 1203 nie jest Chrzanowem ", kotwica.get("nazwa"))
		return 1
	if str(kotwica.get("nazwa", "")) == "Aleksandrów Kujawski":
		printerr("FAIL: kotwica spadła na Aleksandrów")
		return 1
	var nie_ma: Dictionary = rynek._miasto_po_id(miasta, "nie-ma-takiego")
	if str(nie_ma.get("nazwa", "")) == "Aleksandrów Kujawski" or not bool(nie_ma.get("brak_miasta", false)):
		printerr("FAIL: nieznane id wskoczyło na miasto ", nie_ma.get("nazwa"))
		return 1
	var puste: Array = rynek._wybierz_miasta(miasta, "nie-ma-takiego", RandomNumberGenerator.new(), 3)
	if not puste.is_empty() and str(puste[0].get("nazwa", "")) == "Aleksandrów Kujawski" and puste.size() == 1:
		printerr("FAIL: wybór miast wrócił do Aleksandrowa")
		return 1

	var lud_m: int = rynek.ludnosc_zakresu("miasto", "1203")
	var lud_w: int = rynek.ludnosc_zakresu("wojewodztwo", "1203")
	var lud_p: int = rynek.ludnosc_zakresu("polska", "1203")
	var auta_m: int = rynek.pula_w_zasiegu("miasto", "1203", "samochod")
	var auta_w: int = rynek.pula_w_zasiegu("wojewodztwo", "1203", "samochod")
	var auta_p: int = rynek.pula_w_zasiegu("polska", "1203", "samochod")
	var dom_m: int = rynek.pula_w_zasiegu("miasto", "1203", "dom")
	var dom_w: int = rynek.pula_w_zasiegu("wojewodztwo", "1203", "dom")
	var dom_p: int = rynek.pula_w_zasiegu("polska", "1203", "dom")
	var nowe_m: int = rynek.pula_w_zasiegu("miasto", "1203", "dom", "nowy")
	var nowe_w: int = rynek.pula_w_zasiegu("wojewodztwo", "1203", "dom", "nowy")
	var nowe_p: int = rynek.pula_w_zasiegu("polska", "1203", "dom", "nowy")
	var nowe_miesz: int = rynek.pula_w_zasiegu("polska", "1203", "mieszkanie", "nowy")
	print("LUDNOSC miasto=", lud_m, " woj=", lud_w, " polska=", lud_p)
	print("PULA auta miasto=", auta_m, " woj=", auta_w, " polska=", auta_p)
	print("PULA dom uzywane miasto=", dom_m, " woj=", dom_w, " polska=", dom_p)
	print("PULA dom nowe miasto=", nowe_m, " woj=", nowe_w, " polska=", nowe_p)
	if lud_m != 33193 or lud_w != 3429342 or lud_p != 37332510:
		printerr("FAIL: ludność zakresu ", lud_m, " ", lud_w, " ", lud_p)
		return 1
	if auta_m != int(round(float(lud_m) / 1500.0)) or auta_w != int(round(float(lud_w) / 1500.0)) or auta_p != int(round(float(lud_p) / 1500.0)):
		printerr("FAIL: auta nie są round(ludność/1500)")
		return 1
	if dom_m != int(round(float(lud_m) / 5000.0)) or dom_w != int(round(float(lud_w) / 5000.0)) or dom_p != int(round(float(lud_p) / 5000.0)):
		printerr("FAIL: używane lokale nie zostały przy /5000")
		return 1
	if nowe_m != int(round(float(lud_m) / 3500.0)) or nowe_w != int(round(float(lud_w) / 3500.0)) or nowe_p != int(round(float(lud_p) / 3500.0)):
		printerr("FAIL: nowe lokale nie są round(ludność/3500)")
		return 1
	if nowe_miesz != nowe_p or nowe_m == dom_m or nowe_p == auta_p:
		printerr("FAIL: nowe lokale nie są osobną pulą ", nowe_m, " ", dom_m, " ", nowe_p)
		return 1
	if rynek.pula_w_zasiegu("polska", "1203", "mieszkanie", "uzywany") != dom_p:
		printerr("FAIL: używane mieszkanie zmieniło dzielnik")
		return 1
	if not (auta_m < auta_w and auta_w < auta_p):
		printerr("FAIL: pula aut nie rośnie z zakresem")
		return 1
	if auta_p < 20000:
		printerr("FAIL: Polska aut to nie ~1/1500 ", auta_p)
		return 1
	if auta_m != rynek.baza_ogloszen_aut(lud_m) or auta_p != rynek.baza_ogloszen_aut(lud_p):
		printerr("FAIL: pula aut nie jest baza_ogloszen_aut")
		return 1

	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 0, "miejsce": {"id": "1203", "nazwa": "chrzanowski"}},
		"id_miejsca_pobytu": "1203",
		"rynek_zakupow": {"ziarno": 1203},
	}
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, "1203", 1)
	var otwarte := _ile(swiat, "samochod")
	if otwarte <= 0 or otwarte > rynek.limit_okna_aut() or otwarte >= auta_p:
		printerr("FAIL: otwarcie aut ", otwarte, " okno=", rynek.limit_okna_aut(), " pula=", auta_p)
		return 1
	var filtry_pl := {"poziom": "polska", "km": 9999.0, "stan": "uzywany", "tydzien": 1}
	var d1: int = rynek.uzupelnij_okno_aut(swiat, miasta, filtry_pl, 5)
	var d2: int = rynek.uzupelnij_okno_aut(swiat, miasta, filtry_pl, 5)
	var po := _ile(swiat, "samochod")
	print("AUTA otwarte=", otwarte, " dokladka1=", d1, " dokladka2=", d2, " razem=", po)
	if d1 <= 0 or d2 <= 0:
		printerr("FAIL: scroll aut nie dociąga")
		return 1
	if po <= otwarte or po <= 8:
		printerr("FAIL: Polska została na pierwszej stronie ", po)
		return 1
	if po >= auta_p or po > 40:
		printerr("FAIL: preroll aut ", po, " pula=", auta_p)
		return 1

	var swiat_dom := {
		"tydzien": 1,
		"id_miejsca_pobytu": "1203",
		"rynek_zakupow": {"ziarno": 1203, "miejsce_zrodlo_id": "1203", "miasto_gracza_id": str(kotwica.get("id", ""))},
	}
	var filtry_dom := {"poziom": "polska", "km": 9999.0, "kategoria": "dom", "tydzien": 1}
	var h1: int = rynek.uzupelnij_okno_lokum(swiat_dom, miasta, filtry_dom, 5)
	var h2: int = rynek.uzupelnij_okno_lokum(swiat_dom, miasta, filtry_dom, 5)
	var domy := _ile(swiat_dom, "dom")
	print("DOMY dokladka1=", h1, " dokladka2=", h2, " razem=", domy)
	if h1 <= 0 or h2 <= 0 or domy <= 8 or domy >= dom_p or domy > 40:
		printerr("FAIL: scroll domów ", h1, " ", h2, " razem=", domy)
		return 1

	var daleko := _inne_wojewodztwo(miasta, kotwica)
	if daleko.is_empty():
		printerr("FAIL: brak miasta z innego województwa")
		return 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var km_tu := rynek.odleglosc_miedzy_miejscami(kotwica, kotwica, rng)
	var km_tam := rynek.odleglosc_miedzy_miejscami(kotwica, daleko, rng)
	if km_tu < 0.5 or km_tu > 12.0:
		printerr("FAIL: to samo miasto ", km_tu)
		return 1
	if km_tam < 80.0 or km_tam > 640.0:
		printerr("FAIL: inne województwo ", km_tam, " ", daleko.get("nazwa"))
		return 1
	var hid := str(kotwica.get("id", ""))
	var dom: Dictionary = rynek._losuj_nieruchomosc("dom", daleko, hid, rng, {}, kotwica)
	var dom_tu: Dictionary = rynek._losuj_nieruchomosc("dom", kotwica, hid, rng, {}, kotwica)
	var auto: Dictionary = rynek._losuj_samochod(kotwica, rng, hid, {}, "uzywany", "polska", miasta, false, daleko, {})
	var karta_dom := rynek.tekst_karty_miejsca(dom)
	var karta_dom_tu := rynek.tekst_karty_miejsca(dom_tu)
	var karta_auto := rynek.tekst_karty_miejsca(auto)
	print("KARTA dom=", karta_dom)
	print("KARTA dom_tu=", karta_dom_tu)
	print("KARTA auto=", karta_auto)
	if karta_dom.find("km") < 0 or karta_dom_tu.find("km") < 0 or karta_auto.find("km") < 0:
		printerr("FAIL: karta bez km")
		return 1
	if float(dom.get("odleglosc_km", 0)) < 80.0 or _km_z_tekstu(karta_dom) < 80.0:
		printerr("FAIL: dom z daleka wygląda blisko ", dom.get("odleglosc_km"), " ", karta_dom)
		return 1
	if float(auto.get("odleglosc_km", 0)) < 80.0 or _km_z_tekstu(karta_auto) < 80.0:
		printerr("FAIL: auto z daleka wygląda blisko ", auto.get("odleglosc_km"), " ", karta_auto)
		return 1
	if float(dom_tu.get("odleglosc_km", 0)) < 0.5 or float(dom_tu.get("odleglosc_km", 0)) > 12.0:
		printerr("FAIL: dom w mieście ", dom_tu.get("odleglosc_km"))
		return 1
	if karta_auto.find("odbiór osobisty") < 0 or karta_auto.find("dostawa") >= 0:
		printerr("FAIL: odbiór prywatnego ", karta_auto)
		return 1
	var conf: Dictionary = rynek._nieruchomosci_conf()
	var surowy: Dictionary = rynek._losuj_nieruchomosc("dom", daleko, hid, rng, conf, kotwica, "nowy", "surowy")
	var karta_surowy := rynek.tekst_karty_miejsca(surowy)
	print("KARTA nowy dom=", karta_surowy)
	if str(surowy.get("rynek_stan", "")) != "nowy" or str(surowy.get("stan", "")) != "surowy":
		printerr("FAIL: nowy dom nie jest stanem surowym ", surowy.get("rynek_stan"), " ", surowy.get("stan"))
		return 1
	if karta_surowy.find("stan surowy") < 0 or karta_surowy.find("km") < 0:
		printerr("FAIL: karta nowego domu ", karta_surowy)
		return 1
	if float(surowy.get("odleglosc_km", 0)) < 80.0:
		printerr("FAIL: nowy dom z daleka ", surowy.get("odleglosc_km"))
		return 1
	if not (surowy.get("cena_zl") is int or surowy.get("cena_zl") is float):
		printerr("FAIL: nowy dom bez ceny ze wzoru")
		return 1
	if not bool(surowy.get("cena_propozycja_do_poprawki", false)):
		printerr("FAIL: cena nowego lokalu udaje pewnik")
		return 1
	var surowe_m: Dictionary = rynek._losuj_nieruchomosc("mieszkanie", kotwica, hid, rng, conf, kotwica, "nowy", "surowy")
	var karta_m := rynek.tekst_karty_miejsca(surowe_m)
	print("KARTA nowe mieszkanie=", karta_m)
	if str(surowe_m.get("stan", "")) != "surowy" or karta_m.find("stan surowy") < 0 or karta_m.find("km") < 0:
		printerr("FAIL: nowe mieszkanie ", karta_m)
		return 1
	if float(surowe_m.get("odleglosc_km", 0)) < 0.5 or float(surowe_m.get("odleglosc_km", 0)) > 12.0:
		printerr("FAIL: nowe mieszkanie w mieście ", surowe_m.get("odleglosc_km"))
		return 1
	var uzywane_przed := _ile_strona(swiat_dom, "dom", "uzywany")
	var filtry_nowe := {"poziom": "polska", "km": 9999.0, "kategoria": "dom", "stan": "nowy", "tydzien": 1}
	var n1: int = rynek.uzupelnij_okno_lokum(swiat_dom, miasta, filtry_nowe, 5)
	var n2: int = rynek.uzupelnij_okno_lokum(swiat_dom, miasta, filtry_nowe, 5)
	var nowe_domy := _ile_strona(swiat_dom, "dom", "nowy")
	print("NOWE DOMY dokladka=", n1, "+", n2, " razem=", nowe_domy, " uzywane_zostaly=", _ile_strona(swiat_dom, "dom", "uzywany"))
	if n1 <= 0 or n2 <= 0 or nowe_domy <= 8 or nowe_domy >= nowe_p or nowe_domy > 40:
		printerr("FAIL: nowe domy ", n1, " ", n2, " ", nowe_domy)
		return 1
	if _ile_strona(swiat_dom, "dom", "uzywany") != uzywane_przed:
		printerr("FAIL: dociąg nowych ruszył używane")
		return 1
	if not rynek.trzeba_dociagnac_przed_koncem(700.0):
		printerr("FAIL: 700 px do końca nie dociąga wcześniej")
		return 1
	if rynek.trzeba_dociagnac_przed_koncem(rynek.PROG_DOCIAGANIA_PX + 80.0):
		printerr("FAIL: dociąg za daleko od końca")
		return 1
	if rynek.PROG_DOCIAGANIA_PX <= 280.0:
		printerr("FAIL: próg został przy ostatniej karcie")
		return 1
	print("OK pula i km, daleko=", daleko.get("nazwa"), " ", daleko.get("wojewodztwo"))
	return 0


func _ile_strona(swiat: Dictionary, kategoria: String, strona: String) -> int:
	var n := 0
	var oferty: Array = swiat["rynek_zakupow"]["oferty"]
	for o in oferty:
		if o is Dictionary and str(o.get("kategoria", "")) == kategoria and str(o.get("rynek_stan", "uzywany")) == strona:
			n += 1
	return n


func _ile(swiat: Dictionary, kategoria: String) -> int:
	var n := 0
	var oferty: Array = swiat["rynek_zakupow"]["oferty"]
	for o in oferty:
		if o is Dictionary and str(o.get("kategoria", "")) == kategoria:
			n += 1
	return n


func _inne_wojewodztwo(miasta: Array, hero: Dictionary) -> Dictionary:
	var woj := str(hero.get("wojewodztwo", ""))
	for m in miasta:
		if not (m is Dictionary):
			continue
		var w := str(m.get("wojewodztwo", ""))
		if w != "" and w != woj and str(m.get("id", "")) != "":
			return m
	return {}


func _km_z_tekstu(tekst: String) -> float:
	var znacznik := tekst.find(" km")
	if znacznik < 0:
		return -1.0
	var start := znacznik
	while start > 0 and (tekst.unicode_at(start - 1) == 44 or (tekst.unicode_at(start - 1) >= 48 and tekst.unicode_at(start - 1) <= 57)):
		start -= 1
	var kawalek := tekst.substr(start, znacznik - start).replace(",", ".")
	if not kawalek.is_valid_float():
		return -1.0
	return float(kawalek)
