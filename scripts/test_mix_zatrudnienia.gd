extends SceneTree

## Wagi zatrudnienia: grupa, górnictwo województw, Kraków kontra Chrzanów, mało plików.
## godot --headless --path . --script res://scripts/test_mix_zatrudnienia.gd

const Rynek = preload("res://scripts/rynek_pracy.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miejsca: Array = los.wszystkie_z_ludnoscia()
	if _otwarcie(rynek, miejsca) != 0:
		return 1
	if _gornictwo(rynek) != 0:
		return 1
	if _krakow(rynek) != 0:
		return 1
	if _grupy(rynek, miejsca) != 0:
		return 1
	if _paliwo() != 0:
		return 1
	print("OK miks zatrudnienia")
	return 0


func _otwarcie(rynek, miejsca: Array) -> int:
	var swiat := {"tydzien": 4, "id_miejsca_pobytu": "1203034"}
	var n: int = rynek.aktywuj(swiat, {"zasieg": "miasto"}, 4, miejsca, "1203034")
	if n < 1:
		printerr("FAIL: Chrzanów bez ofert")
		return 1
	var woj := 0
	var pliki: Array = rynek.pliki_wczytane()
	for p in pliki:
		var sciezka := str(p)
		if sciezka.find("katalog_zawodow.json") >= 0:
			printerr("FAIL: otwarcie czyta cały katalog ", sciezka)
			return 1
		if sciezka.find("metropolie.json") >= 0:
			printerr("FAIL: Chrzanów czyta metropolie")
			return 1
		if sciezka.find("udzialy.md") >= 0:
			printerr("FAIL: gra czyta markdown")
			return 1
		if sciezka.find("/wojewodztwa/") >= 0:
			woj += 1
			if sciezka.find("malopolskie.json") < 0:
				printerr("FAIL: inne województwo ", sciezka)
				return 1
	if woj != 1:
		printerr("FAIL: liczba plików województw ", woj, " ", pliki)
		return 1
	var lud: int = rynek.ludnosc_zakresu(miejsca, "miasto", "1203034")
	if rynek.pula_ofert(lud, "miasto", {}) != 81:
		printerr("FAIL: pula Chrzanowa ", rynek.pula_ofert(lud, "miasto", {}))
		return 1
	return 0


func _gornictwo(rynek) -> int:
	var slaskie: float = rynek.udzial_sekcji("Śląskie", "B")
	var mazowsze: float = rynek.udzial_sekcji("Mazowieckie", "B")
	var kujawy: float = rynek.udzial_sekcji("Kujawsko-Pomorskie", "B")
	if slaskie <= mazowsze or slaskie <= kujawy:
		printerr("FAIL: górnictwo ", slaskie, " ", mazowsze, " ", kujawy)
		return 1
	var nazwy := [
		"Dolnośląskie", "Kujawsko-Pomorskie", "Lubelskie", "Lubuskie", "Łódzkie",
		"Małopolskie", "Mazowieckie", "Opolskie", "Podkarpackie", "Podlaskie",
		"Pomorskie", "Śląskie", "Świętokrzyskie", "Warmińsko-Mazurskie",
		"Wielkopolskie", "Zachodniopomorskie", "Polska",
	]
	for nazwa in nazwy:
		var u: float = rynek.udzial_sekcji(nazwa, "B")
		print("B ", nazwa, " ", snapped(u * 100.0, 0.01), "%")
		if u <= 0.0:
			printerr("FAIL: zerowe górnictwo ", nazwa)
			return 1
	return 0


func _krakow(rynek) -> int:
	if rynek.udzial_miasta("Kraków", "Małopolskie", "A") >= rynek.udzial_miasta("Chrzanów", "Małopolskie", "A"):
		printerr("FAIL: rolnicy w Krakowie")
		return 1
	if rynek.udzial_miasta("Kraków", "Małopolskie", "B") >= rynek.udzial_miasta("Chrzanów", "Małopolskie", "B"):
		printerr("FAIL: górnicy w Krakowie")
		return 1
	var uslugi_k := 0.0
	var uslugi_c := 0.0
	for kod in ["J", "K", "M"]:
		uslugi_k += rynek.udzial_miasta("Kraków", "Małopolskie", kod)
		uslugi_c += rynek.udzial_miasta("Chrzanów", "Małopolskie", kod)
	if uslugi_k <= uslugi_c:
		printerr("FAIL: usługi ", uslugi_k, " ", uslugi_c)
		return 1
	var spec_k: float = rynek.waga_grupy_ofert("Małopolskie", "2", true)
	var spec_c: float = rynek.waga_grupy_ofert("Małopolskie", "2", false)
	var rol_k: float = rynek.waga_grupy_ofert("Małopolskie", "6", true)
	var rol_c: float = rynek.waga_grupy_ofert("Małopolskie", "6", false)
	if spec_k / spec_c <= rol_k / rol_c:
		printerr("FAIL: specjaliści względem rolników ", spec_k, " ", spec_c, " ", rol_k, " ", rol_c)
		return 1
	if rynek.udzial_miasta("Chrzanów", "Małopolskie", "B") != rynek.udzial_sekcji("Małopolskie", "B"):
		printerr("FAIL: Chrzanów nie trzyma województwa")
		return 1
	return 0


func _grupy(rynek, miejsca: Array) -> int:
	var duza: float = rynek.waga_grupy_ofert("Polska", "2", false)
	var mala: float = rynek.waga_grupy_ofert("Polska", "9", false)
	if duza <= mala:
		printerr("FAIL: waga grup ", duza, " ", mala)
		return 1
	var swiat := {"tydzien": 2}
	var licznik := {}
	for _i in 6:
		rynek.uzupelnij(swiat, {"zasieg": "polska"}, 16, 2, miejsca, "1203034")
	var oferty: Array = swiat["rynek_pracy"]["oferty"]
	for o in oferty:
		if not (o is Dictionary):
			continue
		var g := str(o.get("wielka_grupa", ""))
		licznik[g] = int(licznik.get(g, 0)) + 1
	if int(licznik.get("2", 0)) <= int(licznik.get("9", 0)):
		printerr("FAIL: losowanie grup ", licznik)
		return 1
	if oferty.size() < 40:
		printerr("FAIL: za mało losowań ", oferty.size())
		return 1
	var katalog := false
	for p in rynek.pliki_wczytane():
		if str(p).find("katalog_zawodow.json") >= 0:
			katalog = true
	if katalog:
		printerr("FAIL: losowanie czyta cały katalog")
		return 1
	return 0


func _paliwo() -> int:
	var plik := FileAccess.open("res://świat/polska/kraj.json", FileAccess.READ)
	if plik == null:
		return 1
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if not (dane is Dictionary):
		return 1
	var paliwo: Variant = dane.get("cena_paliwa", {})
	if not (paliwo is Dictionary):
		return 1
	if float(paliwo.get("benzyna", -1)) != 6.0 or float(paliwo.get("gaz", -1)) != 2.5 or float(paliwo.get("energia", -1)) != 0.9:
		printerr("FAIL: paliwo")
		return 1
	if paliwo.get("olej_napedowy", "brak") != null or paliwo.has("diesel"):
		printerr("FAIL: diesel")
		return 1
	return 0
