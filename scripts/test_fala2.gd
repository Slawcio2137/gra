extends SceneTree

## Headless smoke Fali 2.
## godot --headless --quit-after 3 --path . --script res://scripts/test_fala2.gd

const Ev = preload("res://scripts/eventy_przyklady.gd")
const Ie = preload("res://scripts/inteligencja_emocjonalna.gd")
const Imp = preload("res://scripts/imprezy_uzywki.gd")
const Kor = preload("res://scripts/korepetycje.gd")
const Zaj = preload("res://scripts/zajecia_dodatkowe.gd")
const Sz = preload("res://scripts/szachy.gd")
const Dep = preload("res://scripts/depresja.gd")
const Kon = preload("res://scripts/konserwacja_auta.gd")
const Lot = preload("res://scripts/sprowadzanie_samolotow.gd")
const Zan = preload("res://scripts/zainteresowania.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6060

	# Pliki JSON
	for sciezka in [
		"res://postacie/imprezy_uzywki.json",
		"res://postacie/inteligencja_emocjonalna.json",
		"res://postacie/korepetycje.json",
		"res://postacie/zajecia_dodatkowe.json",
		"res://postacie/szachy.json",
		"res://postacie/depresja.json",
		"res://postacie/eventy_fala2.json",
		"res://pojazdy/sprowadzanie_samolotow.json",
		"res://docs/TODO_fala2.md",
	]:
		if not FileAccess.file_exists(sciezka):
			printerr("FAIL: brak ", sciezka)
			return 1
	print("OK pliki JSON Fali 2")

	# Eventy: Fala 1 + Fala 2 = solidny pakiet
	var ev = Ev.new()
	var n := ev.lista_eventow().size()
	if n < 15:
		printerr("FAIL: za mało eventów=", n)
		return 1
	print("OK eventy n=", n)

	# IE
	var ie = Ie.new()
	var boh := {"psychika": 50, "pieniadze": 5000, "wiek": 16, "inteligencja_emocjonalna": 80}
	ie.dodaj(boh, 2)
	if int(boh["inteligencja_emocjonalna"]) < 80:
		printerr("FAIL: IE")
		return 1
	print("OK IE=", boh["inteligencja_emocjonalna"])

	# Hejt + IE redukcja
	boh = {"psychika": 50, "inteligencja_emocjonalna": 80}
	ev.zastosuj_opcje(boh, "hejt_internet", "sam")
	if int(boh["psychika"]) >= 50:
		printerr("FAIL: hejt bez spadku")
		return 1
	print("OK hejt+IE psychika=", boh["psychika"])

	# Imprezy
	var im = Imp.new()
	boh = {"psychika": 50, "pieniadze": 500, "wiek": 17}
	var w_imp: Dictionary = im.idz_na_impreze(boh, {}, "urodziny_kolegi", false, rng)
	if not bool(w_imp.get("ok", false)):
		printerr("FAIL: impreza ", w_imp.get("tekst"))
		return 1
	print("OK impreza")

	# Korepetycje
	var kor = Kor.new()
	boh = {"pieniadze": 500, "wiedza_pkt": 0}
	var w_k: Dictionary = kor.zajecie(boh, "matematyka", rng)
	if not bool(w_k.get("ok", false)) or int(boh.get("wiedza_pkt", 0)) <= 0:
		printerr("FAIL: korepetycje")
		return 1
	print("OK korepetycje wiedza=", boh["wiedza_pkt"])

	# Zajęcia
	var zaj = Zaj.new()
	boh = {"pieniadze": 1000, "wiek": 12, "zajecia_dodatkowe": [], "psychika": 50}
	var w_z: Dictionary = zaj.zapisz_sie(boh, "pilka", rng)
	if not bool(w_z.get("ok", false)):
		printerr("FAIL: zajecia ", w_z.get("tekst"))
		return 1
	print("OK zajecia")

	# Szachy
	var sz = Sz.new()
	boh = {"pieniadze": 500, "wiek": 15}
	sz.zapewnij_ranking(boh, rng)
	var w_t: Dictionary = sz.trening(boh, rng)
	if not bool(w_t.get("ok", false)):
		printerr("FAIL: szachy trening")
		return 1
	var w_tu: Dictionary = sz.graj_turniej(boh, "szkolny", rng)
	if not bool(w_tu.get("ok", false)):
		printerr("FAIL: turniej")
		return 1
	print("OK szachy ranking=", boh.get("szachy_ranking"))

	# Depresja pogłębianie
	var dep = Dep.new()
	boh = {"psychika": -5, "tygodnie_psychika_ponizej_0": 0}
	for _i in 8:
		dep.tydzien(boh)
	if not bool(boh.get("depresja", false)):
		printerr("FAIL: depresja flaga")
		return 1
	if str(boh.get("depresja_etap", "")) == "":
		printerr("FAIL: brak etapu depresji")
		return 1
	print("OK depresja etap=", boh.get("depresja_etap"))
	boh["pieniadze"] = 2000
	boh["psychika"] = 10
	var w_ter: Dictionary = dep.terapia(boh, "prywatna", rng)
	if not bool(w_ter.get("ok", false)):
		printerr("FAIL: terapia")
		return 1
	print("OK terapia")

	# Konserwacja UI serwis
	var kon = Kon.new()
	var stan := kon.stan_startowy()
	stan["olej"] = 10
	var w_s: Dictionary = kon.serwis(stan, "olej", "warsztat", rng)
	if not bool(w_s.get("ok", false)) or int(stan["olej"]) < 100:
		printerr("FAIL: serwis oleju")
		return 1
	print("OK serwis olej")

	# Lotnictwo stub
	var lot = Lot.new()
	boh = {"pieniadze": 100000, "wiek": 18, "lotnictwo": {"licencje": []}}
	var w_l: Dictionary = lot.kup_licencje(boh, "ppl", rng)
	if not bool(w_l.get("ok", false)):
		printerr("FAIL: licencja ", w_l.get("tekst"))
		return 1
	print("OK lotnictwo")

	# Doprecyzowanie zainteresowań
	var zan = Zan.new()
	var los = LosowanieSkrypt.new()
	var zdom := {"id": "pojazdy", "nazwa": "Pojazdy", "ogolne": true, "doprecyzowanie": null, "kolo": true}
	zdom = zan.doprecyzuj_z_wiekiem(zdom, 12, los)
	if zdom.get("doprecyzowanie") == null:
		printerr("FAIL: doprecyzowanie zainteresowań")
		return 1
	print("OK zainteresowanie=", zdom.get("nazwa"))

	# Fala 1 pliki nadal
	if not FileAccess.file_exists("res://scripts/test_fala1.gd"):
		printerr("FAIL: brak test_fala1")
		return 1

	print("PASS fala2")
	return 0
