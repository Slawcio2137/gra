extends SceneTree

## Suwak 100–150%, odmowa żądania, satysfakcja, dwie prace, wypowiedzenie, wprawa KZiS.
## godot --headless --path . --script res://scripts/test_praca_ustalenia.gd

const Rynek = preload("res://scripts/rynek_pracy.gd")
const Katalog = preload("res://scripts/katalog_zawodow.gd")
const Zaokr = preload("res://scripts/zaokraglenie_zarobkow.gd")
const Podatki = preload("res://scripts/podatki_pracy.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if _dialogi(rynek) != 0:
		return 1
	if _karta(rynek) != 0:
		return 1
	if _podatki() != 0:
		return 1
	if _pasmo(rynek) != 0:
		return 1
	if _luki(rynek) != 0:
		return 1
	if _odmowa_zostawia_oferte(rynek) != 0:
		return 1
	if _satysfakcja(rynek) != 0:
		return 1
	if _dwie_prace(rynek) != 0:
		return 1
	if _wypowiedzenie(rynek) != 0:
		return 1
	if _wprawa(rynek) != 0:
		return 1
	if _paliwo() != 0:
		return 1
	var skrypt = load("res://scripts/main.gd")
	if skrypt == null:
		printerr("FAIL: main.gd się nie parsuje")
		return 1
	print("OK ustalenia pracy")
	return 0


func _dialogi(rynek) -> int:
	var sytuacje := [
		"odrzucenie_zadania",
		"zgoda_na_zadanie",
		"kontroferta",
		"zgoda_bez_negocjacji",
		"ponowna_proba",
		"brak_kwalifikacji",
	]
	var n := 0
	for s in sytuacje:
		var k: int = rynek.liczba_linii(s)
		if k < 8 or k > 12:
			printerr("FAIL: kwestie ", s, " ", k)
			return 1
		n += k
		var linia: String = rynek.linia_dialogu(s, 6400, 0)
		if linia == "" or linia.find("____") >= 0 or linia.find("nadzwyczajnego") >= 0:
			printerr("FAIL: linia ", s, " ", linia)
			return 1
		if s != "brak_kwalifikacji" and linia.find("6 400") < 0:
			printerr("FAIL: brak kwoty ", s, " ", linia)
			return 1
		if rynek.wstep_dialogu(s) != "":
			printerr("FAIL: narrator ", s, " ", rynek.wstep_dialogu(s))
			return 1
	if rynek.liczba_dialogow() != n:
		printerr("FAIL: liczba kwestii ", rynek.liczba_dialogow(), " ", n)
		return 1
	var wybory: Array = rynek.wybory_dialogu()
	if wybory.size() < 3 or str(wybory[0]) != "Tak" or str(wybory[1]) != "Nie" or str(wybory[2]) != "Spróbuj ponownej negocjacji":
		printerr("FAIL: wybory ", wybory)
		return 1
	return 0


func _karta(rynek) -> int:
	var rub: Dictionary = rynek.rubryka()
	var pasmo: Dictionary = rub.get("wynagrodzenie_ogloszenia", {}) if rub.get("wynagrodzenie_ogloszenia") is Dictionary else {}
	if not bool(pasmo.get("propozycja_do_poprawki", false)):
		printerr("FAIL: pasmo ogłoszenia bez propozycji")
		return 1
	if not is_equal_approx(float(pasmo.get("min_udzial", 0.0)), 0.85) or not is_equal_approx(float(pasmo.get("max_udzial", 0.0)), 1.1):
		printerr("FAIL: pasmo ogłoszenia ", pasmo)
		return 1
	var teksty: Dictionary = rub.get("tekst_ogloszenia", {}) if rub.get("tekst_ogloszenia") is Dictionary else {}
	var cechy: Dictionary = teksty.get("cechy", {}) if teksty.get("cechy") is Dictionary else {}
	if not bool(cechy.get("propozycja_do_poprawki", false)):
		printerr("FAIL: cechy ogłoszenia bez propozycji")
		return 1
	var kat = Katalog.new()
	var murarz: Dictionary = kat.po_kodzie("711202")
	var kiosk: Dictionary = kat.po_kodzie("522102")
	var spec: Dictionary = kat.po_kodzie("251201")
	var mnozniki: Dictionary = rub.get("mnozniki_wymagan", {}) if rub.get("mnozniki_wymagan") is Dictionary else {}
	if not bool(mnozniki.get("propozycja_do_poprawki", false)):
		printerr("FAIL: mnożniki wymagań bez propozycji")
		return 1
	if _karta_zawodu(rynek, murarz, "Poszukiwany murarz.", "silnych fizycznie") != 0:
		return 1
	if _karta_zawodu(rynek, kiosk, "Poszukiwany kioskarz.", "umiejących pracować z klientami") != 0:
		return 1
	if _karta_zawodu(rynek, spec, "Poszukiwany specjalista do spraw doskonalenia i rozwoju aplikacji.", "umiejących pracować przy biurku") != 0:
		return 1
	if _pasmo_wystawione(rynek, murarz) != 0:
		return 1
	if _wyzsze_wymagania(rynek) != 0:
		return 1
	if rynek.linia_doswiadczenia(0) != "wymagane doświadczenie: nie jest wymagane":
		printerr("FAIL: linia braku doświadczenia ", rynek.linia_doswiadczenia(0))
		return 1
	var zbior: String = rynek.tekst_ogloszenia({
		"nazwa": "Pozostali robotnicy budowlani robót stanu surowego i pokrewni gdzie indziej niesklasyfikowani",
		"kod": "711990",
		"placa_zl": 6400,
		"zarobki_zrodlo": "grupa_nadrzedna",
		"wielka_grupa_nazwa": "ROBOTNICY PRZEMYSŁOWI I RZEMIEŚLNICY",
		"wymagane_wyksztalcenie": 1,
		"wymagane_doswiadczenie": 1,
		"profil": "fizyczna",
	})
	if not zbior.begins_with("Poszukiwany fizyczny pracownik budowlany."):
		printerr("FAIL: karta grupy budowlanej ", zbior)
		return 1
	if zbior.find("Robotnicy") >= 0 or zbior.find("fizyczni ") >= 0 or zbior.find("Pracownicy") >= 0:
		printerr("FAIL: liczba mnoga na karcie ", zbior)
		return 1
	if _karta_zle_slowa(zbior):
		return 1
	var lekarz: String = rynek.tekst_ogloszenia({
		"nazwa": "Lekarz - specjalista alergologii",
		"kod": "221201",
		"placa_zl": 9500,
		"profil": "opiekuncza",
		"wymagane_wyksztalcenie": 3,
		"wymagane_doswiadczenie": 3,
	})
	if not lekarz.begins_with("Poszukiwany lekarz - specjalista alergologii."):
		printerr("FAIL: karta lekarza ", lekarz)
		return 1
	if lekarz.find("specjaliści") >= 0 or lekarz.find("SPECJALIŚCI") >= 0 or _karta_zle_slowa(lekarz):
		return 1
	var pielegniarka: String = rynek.tekst_ogloszenia({
		"nazwa": "Pielęgniarka",
		"kod": "222101",
		"placa_zl": 9500,
		"profil": "opiekuncza",
		"wymagane_wyksztalcenie": 3,
		"wymagane_doswiadczenie": 3,
	})
	if not pielegniarka.begins_with("Poszukiwana pielęgniarka."):
		printerr("FAIL: rodzaj pielęgniarki ", pielegniarka)
		return 1
	if pielegniarka.find("cierpliwych") < 0:
		printerr("FAIL: opieka bez odmiany ", pielegniarka)
		return 1
	return 0


func _karta_zawodu(rynek, zawod: Dictionary, naglowek: String, cecha: String) -> int:
	var oferta: Dictionary = rynek.wytworz_oferte(zawod, 1, 0)
	if oferta.is_empty():
		printerr("FAIL: pusta oferta ", zawod.get("kod"))
		return 1
	var tekst: String = rynek.tekst_ogloszenia(oferta)
	if not tekst.begins_with(naglowek):
		printerr("FAIL: nagłówek ", tekst)
		return 1
	var linie := tekst.split("\n")
	if linie.size() < 6:
		printerr("FAIL: za mało linii ", tekst)
		return 1
	var placa := int(oferta.get("placa_zl", 0))
	var oczekiwana := "oferowane wynagrodzenie: %s zł brutto" % _odstepy_test(placa)
	if str(linie[1]) != oczekiwana:
		printerr("FAIL: wynagrodzenie ", linie[1], " ", oczekiwana)
		return 1
	if tekst.find("wymagane wynagrodzenie") >= 0:
		printerr("FAIL: zła etykieta płacy ", tekst)
		return 1
	var szkola := "wymagane wykształcenie: %s" % rynek.nazwa_wyksztalcenia(int(oferta.get("wymagane_wyksztalcenie", 0)))
	var doswiadczenie: String = rynek.linia_doswiadczenia(int(oferta.get("wymagane_doswiadczenie", 0)))
	if str(linie[2]) != "Wymaganie:" or str(linie[3]) != szkola:
		printerr("FAIL: wymaganie ", linie)
		return 1
	if str(linie[4]) != doswiadczenie:
		printerr("FAIL: doświadczenie ", linie[4], " ", doswiadczenie)
		return 1
	if int(oferta.get("wymagane_doswiadczenie", 0)) <= 0 and str(linie[4]) != "wymagane doświadczenie: nie jest wymagane":
		printerr("FAIL: brak doświadczenia ", linie[4])
		return 1
	var ostatnia := str(linie[linie.size() - 1])
	if not (ostatnia.begins_with("Cenimy ludzi ") or ostatnia.begins_with("Potrzebujemy ludzi ")):
		printerr("FAIL: ramka ", ostatnia)
		return 1
	if ostatnia.find(cecha) < 0 or not ostatnia.ends_with("."):
		printerr("FAIL: cechy ", ostatnia)
		return 1
	if _karta_zle_slowa(tekst):
		return 1
	if int(oferta.get("placa_kotwica_zl", 0)) != int(zawod.get("zarobki", {}).get("mediana_zl", -1)):
		printerr("FAIL: kotwica zniknęła ", oferta)
		return 1
	if str(oferta.get("zarobki_zrodlo", "")) != "grupa_nadrzedna":
		printerr("FAIL: źródło płacy ", oferta)
		return 1
	return 0


func _pasmo_wystawione(rynek, zawod: Dictionary) -> int:
	var kotwica := int(zawod.get("zarobki", {}).get("mediana_zl", 0))
	var ponizej := false
	var powyzej := false
	var cenimy := false
	var potrzebujemy := false
	var edu_wyzej := false
	var exp_nizej := false
	for k in range(0, 48):
		var oferta: Dictionary = rynek.wytworz_oferte(zawod, 1, k)
		var przesunieta := float(oferta.get("placa_kotwica_po_wymaganiach", 0))
		if przesunieta <= 0.0:
			printerr("FAIL: brak przesuniętej kotwicy ", oferta)
			return 1
		var przed := float(oferta.get("placa_przed_zaokragleniem", -1))
		var udzial := przed / przesunieta
		if int(oferta.get("wymagane_wyksztalcenie", 0)) > int(oferta.get("wymagane_wyksztalcenie_baza", 0)):
			edu_wyzej = true
		if int(oferta.get("wymagane_doswiadczenie", 0)) < int(oferta.get("wymagane_doswiadczenie_baza", 0)):
			exp_nizej = true
		if int(oferta.get("wymagane_wyksztalcenie", 0)) < int(oferta.get("wymagane_wyksztalcenie_baza", 0)):
			printerr("FAIL: wykształcenie poniżej bazy ", oferta)
			return 1
		if udzial < 0.85 - 0.000001 or udzial > 1.1 + 0.000001:
			printerr("FAIL: udział poza 85–110 przed zaokrągleniem ", udzial)
			return 1
		if int(oferta.get("placa_zl", 0)) != Zaokr.zaokraglij(przed):
			printerr("FAIL: zaokrąglenie stawki ", oferta.get("placa_zl"), " ", przed)
			return 1
		if udzial < 1.0:
			ponizej = true
		if udzial > 1.0:
			powyzej = true
		var band: Dictionary = rynek.pasmo(int(oferta.get("placa_zl", 0)))
		if int(band.get("min_zl", -1)) != Zaokr.zaokraglij(float(oferta.get("placa_zl", 0))):
			printerr("FAIL: negocjacja nie startuje od ogłoszenia ", band, " ", oferta.get("placa_zl"))
			return 1
		if int(oferta.get("placa_zl", 0)) != kotwica:
			var od_kotwicy: Dictionary = rynek.pasmo(kotwica)
			if int(band.get("min_zl", -1)) == int(od_kotwicy.get("min_zl", -2)):
				printerr("FAIL: negocjacja od kotwicy ", band)
				return 1
		var tekst: String = rynek.tekst_ogloszenia(oferta)
		if _karta_zle_slowa(tekst):
			return 1
		var ostatnia := str(tekst.split("\n")[-1])
		if ostatnia.begins_with("Cenimy ludzi "):
			cenimy = true
		elif ostatnia.begins_with("Potrzebujemy ludzi "):
			potrzebujemy = true
		else:
			printerr("FAIL: ramka ", ostatnia)
			return 1
	if not ponizej or not powyzej:
		printerr("FAIL: stawka nie schodzi pod kotwicę albo nie wchodzi nad nią")
		return 1
	if not cenimy or not potrzebujemy:
		printerr("FAIL: jedna ramka cech")
		return 1
	if not edu_wyzej or not exp_nizej:
		printerr("FAIL: wymagania nie ruszają się ", edu_wyzej, " ", exp_nizej)
		return 1
	if kotwica <= 0:
		printerr("FAIL: kotwica ", kotwica)
		return 1
	return 0


func _wyzsze_wymagania(rynek) -> int:
	var raz_wyzsza := false
	var raz_nizsza := false
	for k in range(0, 24):
		var baza: Dictionary = rynek.place_oferty(6400, "711202", k, 1, 1, 1, 1)
		var wyzej: Dictionary = rynek.place_oferty(6400, "711202", k, 1, 1, 2, 1)
		var nizej: Dictionary = rynek.place_oferty(6400, "711202", k, 1, 1, 1, 0)
		if not is_equal_approx(float(baza.get("udzial", 0)), float(wyzej.get("udzial", 1))):
			printerr("FAIL: inny los płacy przy tym samym kursorze")
			return 1
		if float(wyzej.get("przed", 0)) <= float(baza.get("przed", 0)):
			printerr("FAIL: wyższe wykształcenie nie podnosi stawki przed zaokrągleniem")
			return 1
		if float(nizej.get("przed", 0)) >= float(baza.get("przed", 0)):
			printerr("FAIL: niższe doświadczenie nie obniża stawki przed zaokrągleniem")
			return 1
		if not _w_pasnie(baza) or not _w_pasnie(wyzej) or not _w_pasnie(nizej):
			printerr("FAIL: poza 85–110 przesuniętej kotwicy ", baza, " ", wyzej)
			return 1
		if int(wyzej.get("placa_zl", 0)) > int(baza.get("placa_zl", 0)):
			raz_wyzsza = true
		if int(nizej.get("placa_zl", 0)) < int(baza.get("placa_zl", 0)):
			raz_nizsza = true
	if not raz_wyzsza or not raz_nizsza:
		printerr("FAIL: zaokrąglenie zjadło różnicę wymagań")
		return 1
	return 0


func _w_pasnie(pakiet: Dictionary) -> bool:
	var przes := float(pakiet.get("przesunieta", 0))
	if przes <= 0.0:
		return false
	var udzial := float(pakiet.get("przed", 0)) / przes
	return udzial >= 0.85 - 0.000001 and udzial <= 1.1 + 0.000001


func _podatki() -> int:
	var podatki = Podatki.new()
	var dorosly := {"wiek": 30, "uczy_sie": false}
	var stan := {"rok": 1, "przychod_roku_zl": 0, "podstawa_roku_zl": 0}
	var pelny: Dictionary = podatki.pasek(6400, dorosly, "polska", stan, 1)
	if int(pelny.get("skladki_zl", 0)) <= 0 or int(pelny.get("pit_zl", 0)) <= 0:
		printerr("FAIL: 26+ bez odtrąceń ", pelny)
		return 1
	if int(pelny.get("netto_zl", 0)) >= int(pelny.get("brutto_zl", 0)):
		printerr("FAIL: netto nie jest niższe ", pelny)
		return 1
	if str(pelny.get("tekst", "")).find("Brutto:") < 0 or str(pelny.get("tekst", "")).find("Netto:") < 0:
		printerr("FAIL: pasek bez kwot ", pelny.get("tekst"))
		return 1
	if str(pelny.get("tekst", "")).find("Składka emerytalna:") < 0 or str(pelny.get("tekst", "")).find("Podatek dochodowy:") < 0:
		printerr("FAIL: pasek bez linii ", pelny.get("tekst"))
		return 1
	var uczen := {"wiek": 20, "uczy_sie": true}
	var stan_u := {"rok": 1, "przychod_roku_zl": 0, "podstawa_roku_zl": 0}
	var bez: Dictionary = podatki.pasek(6400, uczen, "polska", stan_u, 1)
	if int(bez.get("skladki_zl", 1)) != 0 or int(bez.get("pit_zl", 1)) != 0 or int(bez.get("netto_zl", 0)) != int(bez.get("brutto_zl", 0)):
		printerr("FAIL: nauka poniżej 26 coś ściąga ", bez)
		return 1
	var bez_nauki := {"wiek": 20, "uczy_sie": false}
	var stan_b := {"rok": 1, "przychod_roku_zl": 0, "podstawa_roku_zl": 0}
	var skladki_tylko: Dictionary = podatki.pasek(6400, bez_nauki, "polska", stan_b, 1)
	if int(skladki_tylko.get("skladki_zl", 0)) <= 0 or int(skladki_tylko.get("pit_zl", 1)) != 0:
		printerr("FAIL: poniżej 26 bez nauki ", skladki_tylko)
		return 1
	var stan_k := {"rok": 1, "przychod_roku_zl": 85528, "podstawa_roku_zl": 0}
	var nad_limitem: Dictionary = podatki.pasek(6400, bez_nauki, "polska", stan_k, 1)
	if int(nad_limitem.get("pit_zl", 0)) <= 0 or int(nad_limitem.get("skladki_zl", 0)) <= 0:
		printerr("FAIL: limit ulgi nie wpuszcza PIT ", nad_limitem)
		return 1
	var obcy: Dictionary = podatki.pasek(6400, dorosly, "niemcy", {"rok": 1}, 1)
	if int(obcy.get("netto_zl", 0)) != int(obcy.get("brutto_zl", 0)) or int(obcy.get("skladki_zl", 1)) != 0 or int(obcy.get("pit_zl", 1)) != 0:
		printerr("FAIL: obcy kraj dostał polskie stawki ", obcy)
		return 1
	if str(obcy.get("tekst", "")).find("nie są ustawione") < 0 or str(obcy.get("tekst", "")).find("emerytalna") >= 0:
		printerr("FAIL: obcy pasek ", obcy.get("tekst"))
		return 1
	var pusty: Dictionary = podatki.pasek(6400, dorosly, "czechy", {"rok": 1}, 1)
	if int(pusty.get("netto_zl", -1)) != int(pusty.get("brutto_zl", -2)):
		printerr("FAIL: nieznany kraj ", pusty)
		return 1
	return 0


func _karta_zle_slowa(tekst: String) -> bool:
	var dol := tekst.to_lower()
	if dol.find("typowa płaca") >= 0 or dol.find("typowa placa") >= 0 or dol.find("grupie zawodów") >= 0 or dol.find("w tej grupie") >= 0:
		printerr("FAIL: typowa płaca na karcie ", tekst)
		return true
	if dol.find("robotnicy") >= 0 or dol.find("rzemieślnicy") >= 0 or tekst.find("Płaca:") >= 0:
		printerr("FAIL: karta jak grupa ", tekst)
		return true
	if dol.find("pracowitość") >= 0 or dol.find("siła fizyczna") >= 0 or dol.find("sila fizyczna") >= 0:
		printerr("FAIL: cecha w mianowniku ", tekst)
		return true
	if tekst.find("6400") >= 0 or tekst.find("9500") >= 0 or tekst.find("5300") >= 0:
		printerr("FAIL: kwota bez odstępów ", tekst)
		return true
	return false


func _odstepy_test(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var licznik := 0
	for i in range(s.length() - 1, -1, -1):
		if licznik > 0 and licznik % 3 == 0:
			out = " " + out
		out = s[i] + out
		licznik += 1
	return out


func _pasmo(rynek) -> int:
	var a: Dictionary = rynek.pasmo(6400)
	if int(a.get("min_zl")) != 6400 or int(a.get("max_zl")) != 9600:
		printerr("FAIL: 6400 ", a)
		return 1
	var b: Dictionary = rynek.pasmo(5300)
	if int(b.get("min_zl")) != 5300 or int(b.get("max_zl")) != 8000:
		printerr("FAIL: 5300 ", b)
		return 1
	return 0


func _oferta() -> Dictionary:
	return {
		"placa_zl": 6400,
		"wymagane_wyksztalcenie": 2,
		"wymagane_doswiadczenie": 4,
		"kod": "111201",
		"nazwa": "Kierownik",
		"zarobki_zrodlo": "grupa_nadrzedna",
		"efekty_tygodniowe": {},
		"wplyw": {},
	}


func _luki(rynek) -> int:
	var oferta := _oferta()
	var nic_ponad := {"poziom_wyksztalcenia": 2, "doswiadczenie_zawodowe": 0}
	var twarda: Dictionary = rynek.negocjuj(oferta, nic_ponad, false, 6400, 0.0)
	if str(twarda.get("wynik")) != "odmowa" or not bool(twarda.get("twarda_odmowa", false)) or int(twarda.get("placa_zl", 1)) != 0:
		printerr("FAIL: luka bez nadwyżki ", twarda)
		return 1
	var z_nadwyzka := {"poziom_wyksztalcenia": 3, "doswiadczenie_zawodowe": 0}
	var tak: Dictionary = rynek.negocjuj(oferta, z_nadwyzka, false, 6400, 0.1)
	if str(tak.get("wynik")) != "zgoda" or int(tak.get("placa_zl")) != 6400 or bool(tak.get("twarda_odmowa", true)):
		printerr("FAIL: luka z nadwyżką nie wpuściła ", tak)
		return 1
	var nie: Dictionary = rynek.negocjuj(oferta, z_nadwyzka, false, 6400, 0.9)
	if str(nie.get("wynik")) != "odmowa" or not bool(nie.get("twarda_odmowa", false)):
		printerr("FAIL: luka z nadwyżką zawsze przechodzi ", nie)
		return 1
	var prog: Dictionary = rynek.negocjuj(oferta, z_nadwyzka, false, 6400, 0.45)
	if str(prog.get("wynik")) != "odmowa":
		printerr("FAIL: próg 0,45 ", prog)
		return 1
	return 0


func _odmowa_zostawia_oferte(rynek) -> int:
	var oferta := _oferta()
	var swiat := {"rynek_pracy": {"oferty": [oferta], "kursor": 4}}
	var mocny := {"poziom_wyksztalcenia": 3, "doswiadczenie_zawodowe": 8}
	var w: Dictionary = rynek.negocjuj(oferta, mocny, true, 9600, 0.99)
	if str(w.get("wynik")) != "odmowa" or bool(w.get("odmowa_konczy_aplikacje", true)) or bool(w.get("twarda_odmowa", true)):
		printerr("FAIL: odmowa żądania ", w)
		return 1
	var wybory: Array = w.get("wybory", [])
	if wybory.size() < 3 or str(wybory[2]) != "Spróbuj ponownej negocjacji":
		printerr("FAIL: brak ponownej ", wybory)
		return 1
	var oferty: Array = swiat["rynek_pracy"]["oferty"]
	if oferty.size() != 1 or int(swiat["rynek_pracy"].get("kursor", 0)) != 4:
		printerr("FAIL: odmowa skasowała ogłoszenie")
		return 1
	return 0


func _slaby(sat: int, cecha: String) -> Dictionary:
	return {
		"tydzien": 2,
		"bohater": {
			"wiedza_pkt": 0,
			"kondycja": 10,
			"zmeczenie_fizyczne": 10,
			"zmeczenie_psychiczne": 10,
			"doswiadczenie_zawodowe": 0,
		},
		"praca_gracza": {
			"kod": "711202",
			"nazwa": "Murarz",
			"placa_zl": 6400,
			"angaz": 0,
			"upomnienia": 0,
			"satysfakcja": sat,
			"szef": {"relacja": 50, "cecha": cecha},
			"efekty_tygodniowe": {},
		},
	}


func _satysfakcja(rynek) -> int:
	var trzy := _slaby(70, "")
	for _i in 3:
		var krok: Dictionary = rynek.rozwiaz_tydzien(trzy, 0.99)
		if bool(krok.get("zwolniony")):
			printerr("FAIL: zwolnienie przy starcie 70 ", krok, " ", trzy.get("praca_gracza"))
			return 1
		var ostrzezenie := str(krok.get("tekst", "")).to_lower()
		if ostrzezenie.find("satysfakcja") >= 0 or ostrzezenie.find("pasmo") >= 0:
			printerr("FAIL: upomnienie jak opis mechaniki ", krok.get("tekst"))
			return 1
	if not rynek.ma_prace(trzy) or int(trzy["praca_gracza"].get("satysfakcja", 0)) != 28:
		printerr("FAIL: trzy tygodnie ", trzy.get("praca_gracza"))
		return 1
	var nisko := _slaby(20, "")
	var a: Dictionary = rynek.rozwiaz_tydzien(nisko, 0.99)
	if not bool(a.get("zwolniony")) or rynek.ma_prace(nisko) or int(a.get("wyplata", 1)) != 0:
		printerr("FAIL: niska satysfakcja nie zwalnia ", a)
		return 1
	var tekst_zwolnienia := str(a.get("tekst", "")).to_lower()
	if tekst_zwolnienia.find("satysfakcja") >= 0 or tekst_zwolnienia.find("zwalnia") < 0:
		printerr("FAIL: tekst zwolnienia ", a.get("tekst"))
		return 1
	var jeszcze := _slaby(30, "")
	var b: Dictionary = rynek.rozwiaz_tydzien(jeszcze, 0.99)
	if bool(b.get("zwolniony")) or int(jeszcze["praca_gracza"].get("satysfakcja", 0)) != 16:
		printerr("FAIL: 30 bez cechy ", b, " ", jeszcze.get("praca_gracza"))
		return 1
	var ostry := _slaby(30, "wybuchowy")
	var c: Dictionary = rynek.rozwiaz_tydzien(ostry, 0.99)
	if not bool(c.get("zwolniony")) or rynek.ma_prace(ostry):
		printerr("FAIL: wybuchowy nie zwolnił ", c, " ", ostry.get("praca_gracza"))
		return 1
	return 0


func _bohater_spokojny() -> Dictionary:
	return {
		"wiedza_pkt": 20,
		"kondycja": 80,
		"zmeczenie_fizyczne": 0,
		"zmeczenie_psychiczne": 0,
		"doswiadczenie_zawodowe": 0,
	}


func _dwie_prace(rynek) -> int:
	var swiat := {"tydzien": 1, "bohater": _bohater_spokojny()}
	var pierwsza: Dictionary = rynek.zatrudnij(swiat, {"kod": "711201", "nazwa": "Murarz", "placa_zl": 6400, "efekty_tygodniowe": {}}, 6400)
	var druga: Dictionary = rynek.zatrudnij(swiat, {"kod": "522102", "nazwa": "Kioskarz", "placa_zl": 5300, "efekty_tygodniowe": {}}, 5300)
	if not bool(pierwsza.get("ok", false)) or not bool(druga.get("ok", false)):
		printerr("FAIL: zatrudnienie ", pierwsza, " ", druga)
		return 1
	var lista: Array = rynek.lista_prac(swiat)
	if lista.size() != 2 or not (lista[0] is Dictionary) or not (lista[1] is Dictionary):
		printerr("FAIL: druga praca zjadła pierwszą ", lista)
		return 1
	var p0: Dictionary = lista[0]
	var p1: Dictionary = lista[1]
	if str(p0.get("kod", "")) != "711201" or str(p1.get("kod", "")) != "522102":
		printerr("FAIL: kody prac ", p0, " ", p1)
		return 1
	var trzecia: Dictionary = rynek.zatrudnij(swiat, {"kod": "221201", "nazwa": "Lekarz", "efekty_tygodniowe": {}}, 9000)
	if bool(trzecia.get("ok", true)) or str(trzecia.get("powod", "")) != "dwie_prace":
		printerr("FAIL: trzecia praca ", trzecia)
		return 1
	if rynek.lista_prac(swiat).size() != 2:
		printerr("FAIL: trzecia weszła")
		return 1
	var tydzien: Dictionary = rynek.rozwiaz_tydzien(swiat, 0.99)
	if bool(tydzien.get("zwolniony")) or rynek.lista_prac(swiat).size() != 2:
		printerr("FAIL: tydzień dwóch prac ", tydzien)
		return 1
	var boh: Dictionary = swiat["bohater"]
	if int(boh.get("zmeczenie_fizyczne", 0)) != 12 or int(boh.get("zmeczenie_psychiczne", 0)) != 12:
		printerr("FAIL: brzemię ", boh.get("zmeczenie_fizyczne"), " ", boh.get("zmeczenie_psychiczne"))
		return 1
	var opis: String = str(tydzien.get("tekst", "")).to_lower()
	if opis.find("zmęczenie fizyczne") < 0 or opis.find("obciążenie psychiczne") < 0:
		printerr("FAIL: dwie prace tekst ", tydzien.get("tekst"))
		return 1
	return 0


func _wypowiedzenie(rynek) -> int:
	if rynek.dlugosc_wypowiedzenia(0.0) != 3 or rynek.dlugosc_wypowiedzenia(1.0) != 9 or rynek.dlugosc_wypowiedzenia(0.5) != 6:
		printerr("FAIL: długość ", rynek.dlugosc_wypowiedzenia(0.0), " ", rynek.dlugosc_wypowiedzenia(1.0), " ", rynek.dlugosc_wypowiedzenia(0.5))
		return 1
	var swiat := {"tydzien": 3, "bohater": _bohater_spokojny()}
	rynek.zatrudnij(swiat, {"kod": "711201", "nazwa": "Murarz", "efekty_tygodniowe": {}}, 6400)
	rynek.zatrudnij(swiat, {"kod": "522102", "nazwa": "Kioskarz", "efekty_tygodniowe": {}}, 5300)
	var n: int = rynek.odejdz(swiat, 0.0, 0)
	var lista: Array = rynek.lista_prac(swiat)
	if n != 3 or lista.size() != 2 or not (lista[0] is Dictionary):
		printerr("FAIL: start wypowiedzenia ", n, " ", lista)
		return 1
	var start: Dictionary = lista[0]
	if int(start.get("wypowiedzenie_zostalo", 0)) != 3:
		printerr("FAIL: licznik wypowiedzenia ", start)
		return 1
	rynek.rozwiaz_tydzien(swiat, 0.99)
	rynek.rozwiaz_tydzien(swiat, 0.99)
	lista = rynek.lista_prac(swiat)
	if lista.size() != 2 or not (lista[0] is Dictionary):
		printerr("FAIL: w trakcie wypowiedzenia ", lista)
		return 1
	var w_trakcie: Dictionary = lista[0]
	if str(w_trakcie.get("kod", "")) != "711201" or int(w_trakcie.get("wypowiedzenie_zostalo", 0)) != 1 or int(w_trakcie.get("staz_tygodni", 0)) != 2:
		printerr("FAIL: staż w wypowiedzeniu ", w_trakcie)
		return 1
	rynek.rozwiaz_tydzien(swiat, 0.99)
	lista = rynek.lista_prac(swiat)
	if lista.size() != 1 or not (lista[0] is Dictionary):
		printerr("FAIL: po wypowiedzeniu ", lista)
		return 1
	var zostala: Dictionary = lista[0]
	if str(zostala.get("kod", "")) != "522102":
		printerr("FAIL: zniknął zły etat ", zostala)
		return 1
	if int(zostala.get("staz_tygodni", 0)) != 3:
		printerr("FAIL: staż drugiej pracy ", zostala)
		return 1
	return 0


func _wprawa(rynek) -> int:
	if rynek.prefiks_wprawy("711201") != "7112" or rynek.prefiks_wprawy("711202") != "7112":
		printerr("FAIL: wspólny prefiks")
		return 1
	if rynek.prefiks_wprawy("221201") != "2212":
		printerr("FAIL: daleki prefiks")
		return 1
	var boh := {}
	rynek.dodaj_wprawe(boh, "711201")
	rynek.dodaj_wprawe(boh, "711202")
	var blisko: Dictionary = rynek.stan_wprawy(boh, "711201")
	if int(blisko.get("punkty", 0)) != 16 or str(blisko.get("prefiks", "")) != "7112":
		printerr("FAIL: wspólna wprawa ", blisko)
		return 1
	var daleko: Dictionary = rynek.stan_wprawy(boh, "221201")
	if bool(daleko.get("jest", true)) or int(daleko.get("punkty", 0)) != 0:
		printerr("FAIL: daleki kod dostał wprawę ", daleko)
		return 1
	var magazyn: Dictionary = boh.get("wprawa_zawodowa", {})
	if magazyn.has("2212") or not magazyn.has("7112"):
		printerr("FAIL: klucze wprawy ", magazyn.keys())
		return 1
	return 0


func _paliwo() -> int:
	var plik := FileAccess.open("res://świat/polska/kraj.json", FileAccess.READ)
	if plik == null:
		printerr("FAIL: brak kraj.json")
		return 1
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
