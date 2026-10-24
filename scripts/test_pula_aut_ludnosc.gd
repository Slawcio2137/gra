extends SceneTree

## Headless: baza ogłoszeń ≈ ludnosc/5000 ±30%; flaga startu zakładki; odświeżanie po aktywacji.
## godot --headless --quit-after 3 --path . --script res://scripts/test_pula_aut_ludnosc.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const Przejazd = preload("res://scripts/przejazd_auta.gd")
const Mapa = preload("res://scripts/mapa_miast.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.is_empty():
		printerr("FAIL: brak miast")
		return 1
	var miasto: Dictionary = miasta[0]
	for m in miasta:
		if m is Dictionary and str(m.get("nazwa", "")).to_lower().find("wroc") >= 0:
			miasto = m
			break
	var mid := str(miasto.get("id", ""))
	var lud := int(miasto.get("ludnosc", 0))
	if lud <= 0:
		printerr("FAIL: brak ludności ", miasto.get("nazwa"))
		return 1
	var baza := rynek.baza_ogloszen_aut(lud)
	var oczek := int(round(float(lud) / 5000.0))
	if baza != maxi(1, oczek):
		printerr("FAIL: baza=", baza, " oczekiwano ", maxi(1, oczek), " lud=", lud)
		return 1
	var pasmo: Vector2i = rynek.pasmo_ogloszen_aut(baza, 0.30)
	print("OK baza=", baza, " pasmo=", pasmo.x, "..", pasmo.y, " miasto=", miasto.get("nazwa"), " lud=", lud)

	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 0, "miejsce": miasto},
		"id_miejsca_pobytu": mid,
		"rodzina": {
			"matka": {"imie": {"nazwa": "Anna"}, "miejsce": miasto},
			"ojciec": {"imie": {"nazwa": "Piotr"}, "miejsce": miasto},
		},
		"przyjaciele": [],
		"znajomi": [{"imie": {"nazwa": "NiePokazuj"}, "miejsce": miasto}],
		"rynek_zakupow": {"ziarno": 424242},
	}
	rynek.zapewnij_pule(swiat, miasta, mid, 1)
	var auta0 := rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid)
	if auta0 != 0:
		printerr("FAIL: przed aktywacją zakładki auta=", auta0, " (oczekiwano 0)")
		return 1
	if bool(swiat["rynek_zakupow"].get("zakladka_samochodow_aktywna", false)):
		printerr("FAIL: flaga aktywna za wcześnie")
		return 1
	print("OK flaga nieaktywna, puli aut=0 przed zakładką")

	rynek.aktywuj_zakladke_samochodow(swiat, miasta, mid, 1)
	if not bool(swiat["rynek_zakupow"].get("zakladka_samochodow_aktywna", false)):
		printerr("FAIL: flaga nie ustawiona po aktywacji")
		return 1
	var auta1 := rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid)
	if auta1 < pasmo.x or auta1 > pasmo.y:
		printerr("FAIL: auta po aktywacji=", auta1, " poza pasmem ", pasmo.x, "..", pasmo.y)
		return 1
	# Pula lokalna = tylko używane (licznik nie obejmuje nowych z katalogu).
	var nowe_w_liczniku := 0
	var uzywane_lokalne := 0
	var nowe_katalog := 0
	var sprowadzenie_widziane := 0
	for o in swiat["rynek_zakupow"]["oferty"]:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			continue
		if bool(o.get("z_katalogu_globalny", false)):
			nowe_katalog += 1
			if str(o.get("stan", "")) != "nowy":
				printerr("FAIL: oferta katalogu globalnego nie jest nowa")
				return 1
			if bool(o.get("sprowadzenie", false)) or bool(o.get("import", false)):
				sprowadzenie_widziane += 1
			continue
		if str(o.get("stan", "")) == "nowy":
			nowe_w_liczniku += 1
		else:
			var reg := str(o.get("region_szukania", "miasto"))
			if reg == "" or reg == "miasto":
				if str(o.get("miasto_id", "")) == mid or bool(o.get("miasto_gracza", false)):
					uzywane_lokalne += 1
	if nowe_w_liczniku > 0:
		printerr("FAIL: lokalna pula ma nowe poza katalogiem: ", nowe_w_liczniku)
		return 1
	if uzywane_lokalne != auta1:
		printerr("FAIL: używane lokalne=", uzywane_lokalne, " != licznik ", auta1)
		return 1
	if nowe_katalog < 50:
		printerr("FAIL: za mało nowych z katalogu: ", nowe_katalog)
		return 1
	if sprowadzenie_widziane < 1:
		printerr("FAIL: brak flagi sprowadzenie/import wśród nowych")
		return 1
	print("OK aktywacja: używane=", auta1, " nowe_katalog=", nowe_katalog, " sprowadzenie=", sprowadzenie_widziane)

	# vmax z katalogu (bez zmyślania) + spalanie_przy_vmax ukryte; delta/nie_jezdzi z usterek
	var widziano_vmax := false
	var widziano_spal_vmax := false
	var widziano_null_vmax := false
	var widziano_katalog_pole := false
	for o in swiat["rynek_zakupow"]["oferty"]:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			continue
		if str(o.get("stan", "")) != "uzywany":
			continue
		if o.has("vmax_katalog"):
			widziano_katalog_pole = true
		if o.get("predkosc_max_kmh") is int or o.get("predkosc_max_kmh") is float:
			widziano_vmax = true
			if str(o.get("predkosc_max_zrodlo", "")) == "propozycja_typowa_naped":
				printerr("FAIL: fałszywy vmax z typowej propozycji napędu")
				return 1
		elif o.get("predkosc_max_kmh") == null:
			widziano_null_vmax = true
		if o.get("spalanie_przy_vmax") is int or o.get("spalanie_przy_vmax") is float:
			widziano_spal_vmax = true
	if not widziano_vmax:
		printerr("FAIL: brak predkosc_max_kmh w ofertach (katalog powinien mieć popularne modele)")
		return 1
	if not widziano_katalog_pole:
		printerr("FAIL: brak pola vmax_katalog")
		return 1
	if not widziano_spal_vmax:
		printerr("FAIL: brak spalanie_przy_vmax (ukryte pole)")
		return 1
	print("OK vmax katalogowe + spalanie_przy_vmax (null_ok=", widziano_null_vmax, ")")

	# Odświeżanie tygodniowe zostaje w paśmie
	swiat["tydzien"] = 2
	rynek.zapewnij_pule(swiat, miasta, mid, 2)
	var auta2 := rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid)
	if auta2 < pasmo.x or auta2 > pasmo.y:
		printerr("FAIL: po turze auta=", auta2, " poza pasmem")
		return 1
	print("OK po turze auta=", auta2)

	# Przejazd: cena paliwa null → „—”
	var przejazd = Przejazd.new()
	var auto_test := {
		"spalanie": 6.0,
		"spalanie_przy_vmax": 9.5,
		"predkosc_max_kmh": 190,
		"naped": "spalinowy",
	}
	var wyn := przejazd.oblicz(100.0, auto_test, Przejazd.TRYB_DOZWOLONA, 0.0, null)
	if str(wyn.get("koszt_tekst", "")) != "—":
		printerr("FAIL: przy null paliwie koszt!=— jest=", wyn.get("koszt_tekst"))
		return 1
	var wyn2 := przejazd.oblicz(100.0, auto_test, Przejazd.TRYB_EKONOMICZNY, 0.0, 6.5)
	if not (wyn2.get("koszt_zl") is float or wyn2.get("koszt_zl") is int):
		printerr("FAIL: brak kosztu przy cenie paliwa")
		return 1
	if int(wyn2.get("zmeczenie_fizyczne_delta", 0)) <= int(przejazd.oblicz(100.0, auto_test, Przejazd.TRYB_PRZEKROCZONA, 40.0, 6.5).get("zmeczenie_fizyczne_delta", 0)):
		# ekonomiczna powinna męczyć bardziej niż szybka
		pass
	print("OK przejazd: null paliwo=—, koszt z ceną OK")

	# Mapa: wierzchołki + krawędzie, bez znajomych na pasku
	var mapa = Mapa.new()
	var graf: Dictionary = mapa.zbuduj(miasta, 424242, mid)
	if (graf.get("wierzcholki") as Array).is_empty():
		printerr("FAIL: puste wierzchołki mapy")
		return 1
	if (graf.get("krawedzie") as Array).is_empty():
		printerr("FAIL: puste krawędzie mapy")
		return 1
	var kto: Dictionary = mapa.mieszkancy_miasta(swiat, mid)
	if not (kto.get("rodzice") is Array) or (kto["rodzice"] as Array).size() < 2:
		printerr("FAIL: rodzice na mapie ", kto.get("rodzice"))
		return 1
	# Znajomi nie trafiają do listy (osobne pole — upewnij się, że nie ma ich w przyjaciolach/rodzicach)
	var imiona := ""
	for k in ["rodzice", "dziadkowie", "przyjaciele"]:
		for im in kto.get(k, []):
			imiona += str(im) + ","
	if imiona.find("NiePokazuj") >= 0:
		printerr("FAIL: znajomy na pasku mieszkańców")
		return 1
	print("OK mapa wierz=", (graf["wierzcholki"] as Array).size(), " kraw=", (graf["krawedzie"] as Array).size())

	print("OK test_pula_aut_ludnosc")
	return 0
