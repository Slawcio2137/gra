extends SceneTree

## Headless: katalog 80+, wiele ofert w mieście, używany ma odbiór osobisty,
## format ceny, pozalewowe ukryte wykrywalne przy wysokiej znajomości.
## godot --headless --quit-after 3 --path . --script res://scripts/test_rynek_aut_rozszerzony.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Znaj = preload("res://scripts/znajomosc_pojazdow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var kat := rynek.katalog_aut()
	var modele: Array = kat.get("modele", []) if kat.get("modele") is Array else []
	if modele.size() < 160:
		printerr("FAIL: oczekiwano >=160 modeli po dopisku, jest ", modele.size())
		return 1
	print("OK katalog modeli=", modele.size(), " paczek=", kat.get("paczki", []))

	# Format ceny + 3 znaczące
	var przyklady := [
		[1234, 1230, "1 230 zł"],
		[45540, 46000, "46 000 zł"],
		[123456, 123000, "123 000 zł"],
		[1100000, 1100000, "1 100 000 zł"],
		[1234567, 1230000, "1 230 000 zł"],
	]
	for p in przyklady:
		var z := rynek.zaokraglij_cene_auta(p[0])
		if z != int(p[1]):
			printerr("FAIL zaokraglij_cene_auta(%s)=%s oczekiwano %s" % [p[0], z, p[1]])
			return 1
		var t := rynek.formatuj_cene_auta(z)
		if t != str(p[2]):
			printerr("FAIL formatuj_cene_auta(%s)='%s' oczekiwano '%s'" % [z, t, p[2]])
			return 1
	print("OK format ceny aut")

	# Znajomość nie spada
	var zn = Znaj.new()
	zn.dodaj_punkty(40, 80.0)
	var poz1 := zn.poziom_0_100()
	zn.dodaj_punkty(0, 80.0)
	if zn.poziom_0_100() < poz1:
		printerr("FAIL: znajomość pojazdów spadła")
		return 1
	print("OK znajomosc_pojazdow nie spada, poziom=", zn.poziom_0_100())

	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.is_empty():
		printerr("FAIL: brak miast")
		return 1
	var miasto: Dictionary = miasta[0]
	for m in miasta:
		if m is Dictionary and str(m.get("nazwa", "")).to_lower().find("krak") >= 0:
			miasto = m
			break
	var mid := str(miasto.get("id", ""))
	var swiat := {
		"tydzien": 1,
		"bohater": {
			"pieniadze": 0,
			"miejsce": miasto,
			"inteligencja_logiczna": 90,
			"znajomosc_pojazdow": {"etap": 4, "punkty": 80},
			"edukacja": [{"id": "szkola_branzowa_mechanik"}],
			"dobre_wyniki_szkoly": true,
			"dostep_do_internetu": true,
		},
		"id_miejsca_pobytu": mid,
		"majatek": {"nieruchomosci": [], "dobra": []},
		"rynek_zakupow": {"ziarno": 777001},
	}
	rynek.zapewnij_pule(swiat, miasta, mid, 1)
	# Przed aktywacją zakładki — zero aut.
	if rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid) != 0:
		printerr("FAIL: auta przed aktywacją zakładki")
		return 1
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, mid, 1)
	var lud := int(miasto.get("ludnosc", 0))
	var baza := rynek.baza_ogloszen_aut(lud)
	var pasmo: Vector2i = rynek.pasmo_ogloszen_aut(baza, 0.30)
	var auta_miasta := 0
	var auta_wszystkie := 0
	var uzywany_bez_osobistego := 0
	var bez_ceny := 0
	for o in swiat["rynek_zakupow"]["oferty"]:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			continue
		auta_wszystkie += 1
		if str(o.get("miasto_id", "")) == mid or bool(o.get("miasto_gracza", false)):
			auta_miasta += 1
		if str(o.get("stan", "")) == "uzywany":
			var s := str(o.get("sposob_odbioru", ""))
			if s != "osobisty" and s != "oba":
				uzywany_bez_osobistego += 1
		if not (o.get("cena_zl") is int or o.get("cena_zl") is float):
			bez_ceny += 1
	# Licznik miasta = tylko używane (nie nowe z katalogu).
	auta_miasta = rynek.ile_aut_w_miescie(swiat["rynek_zakupow"]["oferty"], mid)
	if auta_wszystkie <= 0 or auta_wszystkie > rynek.limit_okna_aut():
		printerr("FAIL: otwarcie zbudowało ", auta_wszystkie, " aut")
		return 1
	if uzywany_bez_osobistego > 0:
		printerr("FAIL: używany bez odbioru osobistego: ", uzywany_bez_osobistego)
		return 1
	if bez_ceny > 0:
		printerr("FAIL: oferty aut bez ceny: ", bez_ceny)
		return 1
	var dodane_nowe := rynek.uzupelnij_okno_aut(swiat, miasta, {"poziom": "miasto", "km": 9999.0, "stan": "nowy", "tydzien": 1, "marki": ["Toyota"]}, 5)
	if dodane_nowe > 5:
		printerr("FAIL: dokladka nowych=", dodane_nowe)
		return 1
	var nowe_global := 0
	for o3c in swiat["rynek_zakupow"]["oferty"]:
		if o3c is Dictionary and bool(o3c.get("z_katalogu_globalny", false)):
			nowe_global += 1
			if str(o3c.get("miasto_nazwa", "")) != "" and not rynek._jest_salon(str(o3c.get("marka", "")), str(o3c.get("miasto_nazwa", ""))):
				printerr("FAIL: nowe poza salonem ", o3c.get("marka"), " ", o3c.get("miasto_nazwa"))
				return 1
	if nowe_global < 1:
		printerr("FAIL: brak nowego auta z salonu w oknie")
		return 1
	print("OK pula: uzywane=", auta_miasta, " nowe_katalog=", nowe_global, " dokladka=", dodane_nowe, " miasto=", miasto.get("nazwa"))

	# Używany zawsze ma tryb oceny (osobisty przed zakupem)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var widziano_uzywany_osobisty := false
	for _i in 40:
		var o2: Dictionary = rynek._losuj_samochod(miasto, rng, mid, {}, "uzywany")
		if str(o2.get("stan", "")) != "uzywany":
			printerr("FAIL: wymuszony używany dał stan=", o2.get("stan"))
			return 1
		var sp := str(o2.get("sposob_odbioru", ""))
		if sp != "osobisty" and sp != "oba":
			printerr("FAIL: wylosowany używany bez osobistego: ", sp)
			return 1
		widziano_uzywany_osobisty = true
		if rynek.tryb_oceny_stanu(o2) != "przed_zakupem":
			printerr("FAIL: używany powinien mieć ocenę przed zakupem")
			return 1
	if not widziano_uzywany_osobisty:
		printerr("FAIL: nie wylosowano używanego")
		return 1
	print("OK używany: odbiór osobisty + ocena przed zakupem")

	# Pozalewowe ukryte → wykrycie przy wysokiej znajomości
	var oferta_p := {
		"id": "test_pozalew",
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_rzeczywisty": 40,
		"stan_deklarowany": 70,
		"sposob_odbioru": "osobisty",
		"usterki_rzeczywiste": ["pozalewowe"],
		"usterki_deklarowane": [],
		"usterki_ukryte": ["pozalewowe"],
		"usterki_wykryte": [],
	}
	swiat["rynek_zakupow"]["oferty"].append(oferta_p)
	var wykryto := false
	for _j in 40:
		oferta_p["usterki_wykryte"] = []
		oferta_p["usterki_ukryte"] = ["pozalewowe"]
		var trafione: Array = rynek.wykryj_usterki(swiat, oferta_p, true)
		if trafione.has("pozalewowe"):
			wykryto = true
			break
	if not wykryto:
		printerr("FAIL: pozalewowe nie wykryte przy wysokiej znajomości+ekspert+szkoła")
		return 1
	print("OK pozalewowe ukryte wykrywalne przy wysokiej znajomości")

	# quit-after 3 ścieżka: sam skrypt kończy się 0
	print("OK test_rynek_aut_rozszerzony")
	return 0
