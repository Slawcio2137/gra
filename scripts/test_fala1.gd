extends SceneTree

## Headless smoke Fali 1.
## godot --headless --quit-after 3 --path . --script res://scripts/test_fala1.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const Ziarno = preload("res://scripts/ziarno_rodzicow.gd")
const Dziad = preload("res://scripts/dziadkowie.gd")
const Syl = preload("res://scripts/sylwetka.gd")
const Zan = preload("res://scripts/zainteresowania.gd")
const Kon = preload("res://scripts/konserwacja_auta.gd")
const Ev = preload("res://scripts/eventy_przyklady.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.is_empty():
		printerr("FAIL: brak miast")
		return 1

	# 1) lata_od_zakupu na telefonie/rowerze
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var miasto: Dictionary = miasta[0]
	var tel: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, str(miasto.get("id", "")), {})
	if not tel.has("lata_od_zakupu"):
		printerr("FAIL: telefon bez lata_od_zakupu")
		return 1
	if tel.has("przebieg_km") and tel["przebieg_km"] != null and _jest_liczba(tel["przebieg_km"]):
		# dopuszczalne null; nie chcemy prawdziwego przebiegu jak w aucie
		pass
	var rower: Dictionary = rynek._losuj_dobro("rower", miasto, rng, str(miasto.get("id", "")), {})
	if not rower.has("lata_od_zakupu"):
		printerr("FAIL: rower bez lata_od_zakupu")
		return 1
	print("OK telefon/rower lata_od_zakupu")

	# 2) katalogi samolot / śmigłowiec / sprzęt
	if not FileAccess.file_exists("res://pojazdy/katalog_samoloty.json"):
		printerr("FAIL: brak katalog_samoloty.json")
		return 1
	if not FileAccess.file_exists("res://pojazdy/katalog_smiglowce_bojowe.json"):
		printerr("FAIL: brak katalog_smiglowce_bojowe.json")
		return 1
	if not FileAccess.file_exists("res://zakupy/katalog_sprzet.json"):
		printerr("FAIL: brak katalog_sprzet.json")
		return 1
	var sprzet: Dictionary = rynek._losuj_dobro("sprzet", miasto, rng, str(miasto.get("id", "")), {})
	if str(sprzet.get("kategoria", "")) != "sprzet":
		printerr("FAIL: sprzęt kategoria")
		return 1
	var sam: Dictionary = rynek._losuj_dobro("samolot", miasto, rng, str(miasto.get("id", "")), {})
	if str(sam.get("kategoria", "")) != "samolot":
		printerr("FAIL: samolot")
		return 1
	print("OK katalogi samolot/sprzęt")

	# 3) dostawa używanych aut
	var auto_u: Dictionary = rynek._losuj_samochod(miasto, rng, str(miasto.get("id", "")), {}, "uzywany", "miasto", miasta)
	var s := str(auto_u.get("sposob_odbioru", ""))
	if s != "osobisty" and s != "dostawa" and s != "oba":
		printerr("FAIL: sposob_odbioru używanego=", s)
		return 1
	print("OK dostawa/osobisty używane=", s)

	# 4) baza województwa = suma miast
	var woj := str(miasto.get("wojewodztwo", ""))
	if woj == "":
		for m in miasta:
			if m is Dictionary and str(m.get("wojewodztwo", "")) != "":
				miasto = m
				woj = str(m["wojewodztwo"])
				break
	var baza_m := rynek.baza_ogloszen_aut(rynek._ludnosc_miasta(miasto))
	var baza_w := rynek.baza_ogloszen_aut_wojewodztwa(miasta, woj)
	if baza_w < baza_m:
		printerr("FAIL: baza woj=", baza_w, " < baza miasta=", baza_m)
		return 1
	print("OK baza woj=", baza_w, " >= miasto=", baza_m)

	# 5) dziadkowie
	var ziarno = Ziarno.new()
	var rodzina: Dictionary = ziarno.losuj(los, miasto)
	var dziad = Dziad.new()
	var stan_d: Dictionary = dziad.losuj(rodzina, los, miasto)
	if not (stan_d.get("lista") is Array):
		printerr("FAIL: dziadkowie lista")
		return 1
	print("OK dziadkowie n=", (stan_d["lista"] as Array).size(), " zestaw=", stan_d.get("zestaw_id"))

	# 6) sylwetka / zainteresowania
	var syl = Syl.new()
	syl.dodaj_za_fuche(true)
	if syl.punkty <= 0 and syl.etap <= 0:
		# po dodaniu powinno być >0
		printerr("FAIL: sylwetka bez postępu")
		return 1
	var zan = Zan.new()
	var zdom: Dictionary = zan.losuj_dominujace(los)
	if not bool(zdom.get("kolo", false)):
		printerr("FAIL: zainteresowanie koło")
		return 1
	print("OK sylwetka/zainteresowanie=", zdom.get("nazwa"))

	# 7) psychika < 0 + hejt −40%
	var ev = Ev.new()
	var boh := {"psychika": 10}
	var w1: Dictionary = ev.zastosuj_opcje(boh, "hejt_przyklad", "sam")
	if int(boh["psychika"]) >= 10:
		printerr("FAIL: hejt bez spadku")
		return 1
	var psych_bez := int(boh["psychika"])
	boh = {"psychika": 10}
	var w2: Dictionary = ev.zastosuj_opcje(boh, "hejt_przyklad", "rodzice")
	var psych_z := int(boh["psychika"])
	# ze wsparciem spadek mniejszy → psychika wyższa
	if psych_z <= psych_bez:
		printerr("FAIL: wsparcie rodziców nie zmniejszyło spadku ", psych_z, " vs ", psych_bez)
		return 1
	boh = {"psychika": -1, "tygodnie_psychika_ponizej_0": 3}
	ev.zastosuj_opcje(boh, "zabawa_zamiast_nauki", "zabawa")
	# po opcji psychika może nadal <0; ręcznie sprawdź flagę
	boh["psychika"] = -5
	ev._aktualizuj_flage_depresji(boh)
	boh["tygodnie_psychika_ponizej_0"] = 4
	ev._aktualizuj_flage_depresji(boh)
	if not bool(boh.get("depresja", false)):
		# ustaw bezpośrednio scenariusza 4 tygodni
		boh = {"psychika": -3, "tygodnie_psychika_ponizej_0": 3}
		ev._aktualizuj_flage_depresji(boh)
		if not bool(boh.get("depresja", false)):
			printerr("FAIL: flaga depresji")
			return 1
	print("OK hejt/wsparcie/depresja stub")

	# 8) konserwacja stub
	var kon = Kon.new()
	var stan_k: Dictionary = kon.stan_startowy()
	stan_k["olej"] = 5
	var efekt: Dictionary = kon.efekt_tury(stan_k, true, rng)
	if not bool(efekt.get("olej_ostrzezenie", false)):
		printerr("FAIL: brak ostrzeżenia oleju")
		return 1
	print("OK konserwacja olej")

	# 9) TODO fala 2
	if not FileAccess.file_exists("res://docs/TODO_fala2.md"):
		printerr("FAIL: brak TODO_fala2.md")
		return 1

	# 10) kategoria sprzęt w ofertach
	var dane: Dictionary = rynek.wczytaj()
	var ma_sprzet := false
	if dane.get("kategorie") is Array:
		for k in dane["kategorie"]:
			if k is Dictionary and str(k.get("id", "")) == "sprzet":
				ma_sprzet = true
	if not ma_sprzet:
		printerr("FAIL: brak kategorii sprzęt w zakupy_oferty")
		return 1
	print("OK kategoria Sprzęt")

	print("PASS fala1")
	return 0


func _jest_liczba(v: Variant) -> bool:
	return v is int or v is float
