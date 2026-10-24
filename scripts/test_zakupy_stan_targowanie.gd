extends SceneTree

## Headless: przebieg nowego auta, zaokrąglenia, kłamstwo stanu, obraza przy zbyt niskiej ofercie.
## godot --headless --path . --script res://scripts/test_zakupy_stan_targowanie.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not _test_zaokraglenia(rynek):
		return 1
	if not _test_nowe_auto_przebieg(rynek):
		return 1
	if not _test_klamstwo_stanu(rynek):
		return 1
	if not _test_targ_obraza(rynek):
		return 1
	print("OK stan / przebieg / zaokrąglenia / targowanie")
	return 0


func _test_zaokraglenia(rynek) -> bool:
	var przypadki := [
		["ksiazka", 23, 25],
		["ksiazka", 22, 20],
		["rower", 1230, 1250],
		["samochod", 45540, 46000],
		["samochod", 1234567, 1230000],
		["samochod", 1100000, 1100000],
		["mieszkanie", 455400, 455000],
		["dom", 1234600, 1235000],
		["apartament", 1234000, 1235000],
		["willa", 2501000, 2500000],
		["telefon", 1234, 1230],
		["laptop", 1234, 1250],
	]
	for p in przypadki:
		var wynik: Variant = rynek.zaokraglij_cene(str(p[0]), p[1])
		if int(wynik) != int(p[2]):
			printerr("FAIL zaokraglij_cene(%s, %s) = %s, oczekiwano %s" % [p[0], p[1], wynik, p[2]])
			return false
	print("OK zaokraglij_cene")
	return true


func _test_nowe_auto_przebieg(rynek) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var miasto := {"id": "m1", "nazwa": "Testowo"}
	var nowe := 0
	var ok_przebieg := 0
	for i in 40:
		rng.seed = 1000 + i
		# Wymuś kilka nowych przez powtórki ziaren — filtruj po polu stan.
		var o: Dictionary = rynek._losuj_dobro("samochod", miasto, rng, "m1", {})
		if str(o.get("stan", "")) != "nowy":
			continue
		nowe += 1
		if int(o.get("przebieg_km", -1)) != 0:
			printerr("FAIL nowe auto przebieg_km=", o.get("przebieg_km"), " (ma być 0)")
			return false
		if bool(o.get("stan_klamstwo", false)):
			printerr("FAIL nowe auto ma kłamstwo stanu")
			return false
		if not (o.get("stan_rzeczywisty") is int or o.get("stan_rzeczywisty") is float):
			printerr("FAIL nowe auto bez stan_rzeczywisty")
			return false
		if int(o["stan_deklarowany"]) < int(o["stan_rzeczywisty"]):
			printerr("FAIL nowe: deklarowany < rzeczywisty")
			return false
		ok_przebieg += 1
	if ok_przebieg < 1:
		# Wymuś nowe: nadpisz przez bezpośrednie pola jak generator.
		rng.seed = 7
		var force: Dictionary = rynek._losuj_dobro("samochod", miasto, rng, "m1", {})
		force["stan"] = "nowy"
		force["przebieg_km"] = rynek._losuj_przebieg_km("samochod", "nowy", rng)
		force["stan_rzeczywisty"] = 98
		force["stan_deklarowany"] = 98
		force["stan_klamstwo"] = false
		if int(force["przebieg_km"]) != 0:
			printerr("FAIL _losuj_przebieg_km nowy != 0")
			return false
		print("OK nowe auto przebieg_km=0 (wymuszone API)")
		return true
	print("OK nowe auto przebieg_km=0 (n=", ok_przebieg, ")")
	return true


func _test_klamstwo_stanu(rynek) -> bool:
	var rng := RandomNumberGenerator.new()
	var miasto := {"id": "m1", "nazwa": "Testowo"}
	var bylo_klamstwo := false
	var uzywane := 0
	for i in 200:
		rng.seed = 5000 + i * 17
		var o: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "m1", {})
		if str(o.get("stan", "")) != "uzywany":
			continue
		uzywane += 1
		if not _liczba(o.get("stan_rzeczywisty")) or not _liczba(o.get("stan_deklarowany")):
			printerr("FAIL brak stanów jakości")
			return false
		var rz := int(o["stan_rzeczywisty"])
		var dek := int(o["stan_deklarowany"])
		if dek < rz:
			printerr("FAIL deklarowany < rzeczywisty przy używanym")
			return false
		if bool(o.get("stan_klamstwo", false)):
			if dek <= rz:
				printerr("FAIL flaga kłamstwa przy dek<=rz")
				return false
			bylo_klamstwo = true
		# Cena zaokrąglona do kroku telefonu (10).
		if _liczba(o.get("cena_zl")) and int(o["cena_zl"]) % 10 != 0:
			printerr("FAIL cena telefonu nie co 10: ", o["cena_zl"])
			return false
	if uzywane < 10:
		printerr("FAIL za mało używanych w próbce")
		return false
	if not bylo_klamstwo:
		printerr("FAIL w 200 losowaniach nie padło kłamstwo stanu (szansa~28%)")
		return false
	print("OK kłamstwo stanu możliwe (uzywane=", uzywane, ")")
	return true


func _test_targ_obraza(rynek) -> bool:
	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 100000},
		"rynek_zakupow": {
			"oferty": [
				{
					"id": "u1",
					"kategoria": "rower",
					"stan": "uzywany",
					"cena_zl": 1000,
					"cena_wyjsciowa": 1000,
					"sposob_odbioru": "osobisty",
					"stan_rzeczywisty": 60,
					"stan_deklarowany": 75,
				}
			]
		},
	}
	# 40% ceny < próg 55% → obraza / koniec.
	var w: Dictionary = rynek.targuj(swiat, "u1", 400, null)
	if not bool(w.get("ok", false)):
		printerr("FAIL targuj nie ok: ", w.get("powod"))
		return false
	if str(w.get("wynik", "")) != "obraza":
		printerr("FAIL oczekiwano obraza, jest ", w.get("wynik"), " tekst=", w.get("tekst"))
		return false
	if not bool(w.get("koniec", false)):
		printerr("FAIL obraza powinna kończyć rozmowę")
		return false
	var oferta: Dictionary = swiat["rynek_zakupow"]["oferty"][0]
	if not bool(oferta.get("targowanie_zakonczone", false)):
		printerr("FAIL brak flagi targowanie_zakonczone")
		return false
	var tekst := str(w.get("tekst", ""))
	if tekst.strip_edges() == "":
		printerr("FAIL pusty tekst obrazy")
		return false
	print("OK dialog przy zbyt niskiej ofercie kończy rozmowę: ", tekst)
	return true


func _liczba(v: Variant) -> bool:
	return v is int or v is float
