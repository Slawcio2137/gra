extends SceneTree

## Salony, odbiór, zasięg i odległość. Nie sprawdza odrzuconego układu list.
## godot --headless --path . --script res://scripts/test_salony_zasieg_odbior.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var scroll := ScrollContainer.new()
	scroll.set_script(load("res://scripts/scroll_dotyk.gd"))
	root.add_child(scroll)
	# W --script _init węzeł nie wchodzi w drzewo, więc _ready nie zdąży. Ta sama funkcja co w grze.
	if scroll.has_method("_enter_tree"):
		scroll.call("_enter_tree")
	var pasek := scroll.get_v_scroll_bar()
	var szer := pasek.custom_minimum_size.x if pasek != null else -1.0
	if szer < 28.0 or szer > 40.0:
		printerr("FAIL: pasek pionowy ma szerokość ", szer)
		return 1
	print("OK pasek ", szer, " px")

	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var chrzanow: Dictionary = {}
	var aleks: Dictionary = {}
	for m in miasta:
		if not (m is Dictionary):
			continue
		var nazwa := str(m.get("nazwa", ""))
		if nazwa == "Chrzanów":
			chrzanow = m
		elif nazwa == "Aleksandrów Kujawski":
			aleks = m
	if chrzanow.is_empty() or aleks.is_empty():
		printerr("FAIL: brak Chrzanowa albo Aleksandrowa w miastach")
		return 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for _i in 20:
		var km := rynek.odleglosc_miedzy_miejscami(chrzanow, aleks, rng)
		if km < 40.0:
			printerr("FAIL: Chrzanów–Aleksandrów Kujawski = ", km, " km")
			return 1
	var w_miescie := rynek.odleglosc_miedzy_miejscami(chrzanow, chrzanow, rng)
	if w_miescie < 0.4 or w_miescie > 15.0:
		printerr("FAIL: odległość w tym samym mieście ", w_miescie)
		return 1

	var swiat := {
		"tydzien": 1,
		"bohater": {
			"pieniadze": 0,
			"miejsce": {"id": "1203", "nazwa": "chrzanowski", "typ": "wies", "wojewodztwo": "Małopolskie"},
		},
		"id_miejsca_pobytu": "1203",
		"rynek_zakupow": {"ziarno": 424242},
	}
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, "1203", 1)
	var mid := str(chrzanow.get("id", ""))
	if str(swiat["rynek_zakupow"].get("miasto_gracza_id", "")) != mid:
		printerr("FAIL: kotwica to nie Chrzanów, jest ", swiat["rynek_zakupow"].get("miasto_gracza_id"))
		return 1
	var lokalne := rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid)
	var wszystkie := 0
	for o_n in swiat["rynek_zakupow"]["oferty"]:
		if o_n is Dictionary and str(o_n.get("kategoria", "")) == "samochod":
			wszystkie += 1
	if wszystkie <= 0 or wszystkie > rynek.limit_okna_aut():
		printerr("FAIL: otwarcie dało ", wszystkie, " aut")
		return 1
	if lokalne <= 0:
		printerr("FAIL: brak używanych w Chrzanowie ", lokalne)
		return 1

	var po_miasto: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 25.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "miasto")
	if po_miasto.size() <= 2:
		printerr("FAIL: zasięg miasto pokazuje ", po_miasto.size(), " używanych")
		return 1
	for o in po_miasto:
		if str(o.get("miasto_nazwa", "")).find("Aleksandrów") >= 0:
			printerr("FAIL: Aleksandrów na zasięgu miasto")
			return 1
		if str(o.get("miasto_id", "")) != mid:
			printerr("FAIL: używany spoza Chrzanowa na zasięgu miasto: ", o.get("miasto_nazwa"))
			return 1
	var dodane_pl := rynek.uzupelnij_okno_aut(swiat, miasta, {"poziom": "polska", "km": 9999.0, "stan": "uzywany", "tydzien": 1}, 5)
	if dodane_pl <= 0 or dodane_pl > 5:
		printerr("FAIL: dokladka Polska=", dodane_pl)
		return 1
	var po_pl: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "polska")
	if po_pl.size() <= 2:
		printerr("FAIL: pula Polska ma tylko ", po_pl.size(), " używanych")
		return 1
	if po_pl.size() > rynek.limit_okna_aut() + 5:
		printerr("FAIL: Polska urosła za bardzo ", po_pl.size())
		return 1

	var tesla_w_miescie := 0
	var toyota_krakow_miasto := 0
	var toyota_krakow_woj := 0
	for o in swiat["rynek_zakupow"]["oferty"]:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			continue
		if str(o.get("stan", "")) == "uzywany":
			var tekst := rynek.tekst_odbioru_auta(o)
			if tekst.find("dostawa") >= 0 or str(o.get("sposob_odbioru", "")) != "osobisty":
				printerr("FAIL: prywatna oferta ma dostawę: ", tekst, " ", o.get("sposob_odbioru"))
				return 1
			if _liczba(o.get("cena_dostawy_zl")):
				printerr("FAIL: prywatna oferta ma cenę dostawy")
				return 1
			var woj := str(o.get("wojewodztwo", ""))
			if woj != "" and woj != "Małopolskie" and str(o.get("kraj", "PL")) == "PL" and float(o.get("odleglosc_km", 0)) < 40.0:
				printerr("FAIL: inne województwo za ", o.get("odleglosc_km"), " km (", o.get("miasto_nazwa"), ")")
				return 1
		if str(o.get("marka", "")) == "Tesla" and bool(o.get("salon", false)):
			if str(o.get("miasto_id", "")) == mid or str(o.get("wojewodztwo", "")) == "Małopolskie":
				tesla_w_miescie += 1
	if tesla_w_miescie > 0:
		printerr("FAIL: Tesla ma salon w Chrzanowie albo Małopolskiem")
		return 1
	rynek.uzupelnij_okno_aut(swiat, miasta, {"poziom": "wojewodztwo", "km": 9999.0, "stan": "nowy", "tydzien": 1, "marki": ["Toyota"]}, 8)
	var nowe_miasto: Array = rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "miasto")
	var nowe_woj: Array = rynek.oferty_filtrowane(swiat, "samochod", "nowy", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "wojewodztwo")
	for o2 in nowe_miasto:
		if str(o2.get("marka", "")) == "Toyota" and str(o2.get("miasto_nazwa", "")) == "Kraków":
			toyota_krakow_miasto += 1
		if str(o2.get("marka", "")) == "Tesla" and bool(o2.get("salon", false)):
			printerr("FAIL: salon Tesli na zasięgu miasto Chrzanów")
			return 1
	for o3 in nowe_woj:
		if str(o3.get("marka", "")) == "Toyota" and str(o3.get("miasto_nazwa", "")) == "Kraków" and bool(o3.get("salon", false)):
			toyota_krakow_woj += 1
	if toyota_krakow_miasto > 0:
		printerr("FAIL: Toyota Kraków widać przy zasięgu miasto")
		return 1
	if toyota_krakow_woj < 1:
		printerr("FAIL: Toyota Kraków nie widać przy zasięgu województwo")
		return 1

	var z_cena := {"stan": "nowy", "salon": true, "sposob_odbioru": "dostawa", "cena_dostawy_zl": 1200}
	if rynek.tekst_odbioru_auta(z_cena) != "dostawa (1 200 zł)":
		printerr("FAIL: etykieta dostawy ", rynek.tekst_odbioru_auta(z_cena))
		return 1
	var oba := {"stan": "nowy", "salon": true, "sposob_odbioru": "oba", "cena_dostawy_zl": 1200}
	if rynek.tekst_odbioru_auta(oba) != "odbiór osobisty / dostawa (1 200 zł)":
		printerr("FAIL: etykieta obu ", rynek.tekst_odbioru_auta(oba))
		return 1
	var prywatna := {"stan": "uzywany", "salon": false, "sposob_odbioru": "dostawa", "cena_dostawy_zl": 1200}
	if rynek.tekst_odbioru_auta(prywatna).find("dostawa") >= 0:
		printerr("FAIL: prywatna etykieta zawiera dostawę")
		return 1
	var bez_ceny := {"stan": "nowy", "salon": true, "sposob_odbioru": "dostawa", "cena_dostawy_zl": null}
	var bez_txt := rynek.tekst_odbioru_auta(bez_ceny)
	if bez_txt.find("dostawa") >= 0 or bez_txt.find("(") >= 0:
		printerr("FAIL: dostawa bez cennika dostała tekst ", bez_txt)
		return 1

	print(
		"OK salony: lokalne=", lokalne,
		" PL=", po_pl.size(),
		" Toyota Kraków woj=", toyota_krakow_woj,
		" miasto=", po_miasto.size()
	)
	return 0


func _liczba(v: Variant) -> bool:
	return v is int or v is float
