extends SceneTree

## Headless: vmax katalog + delta usterki + nie_jezdzi (laweta/mechanik/złom).
## godot --headless --quit-after 3 --path . --script res://scripts/test_vmax_awaria_auta.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Przejazd = preload("res://scripts/przejazd_auta.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var kat := rynek.katalog_aut()
	var modele: Array = kat.get("modele", []) if kat.get("modele") is Array else []
	var z_vmax := 0
	var z_zrodlem := 0
	for m in modele:
		if not (m is Dictionary):
			continue
		if m.get("predkosc_max_kmh") is int or m.get("predkosc_max_kmh") is float:
			z_vmax += 1
			if str(m.get("predkosc_max_zrodlo", "")).strip_edges() != "":
				z_zrodlem += 1
	if z_vmax < 80:
		printerr("FAIL: za mało vmax w katalogu: ", z_vmax)
		return 1
	if z_zrodlem < z_vmax:
		printerr("FAIL: vmax bez źródła: filled=", z_vmax, " z_zrodlem=", z_zrodlem)
		return 1
	print("OK katalog vmax=", z_vmax, "/", modele.size(), " ze źródłem=", z_zrodlem)

	# Brak zmyślania typowej wartości napędu.
	var meta_pusta: Dictionary = rynek._predkosc_max_z_rekordu({"naped": "spalinowy"}, "spalinowy")
	if meta_pusta.get("wartosc") != null:
		printerr("FAIL: pusty rekord nie powinien mieć vmax, jest=", meta_pusta.get("wartosc"))
		return 1
	print("OK brak vmax w rekordzie → null")

	var usterki_test: Array = ["spadek_mocy"]
	var ef: Dictionary = rynek.efekty_usterek_vmax(usterki_test)
	if int(ef.get("vmax_delta", 0)) != -20:
		printerr("FAIL: spadek_mocy delta!=-20 jest=", ef.get("vmax_delta"))
		return 1
	var ef2: Dictionary = rynek.efekty_usterek_vmax(["awaria_silnika"])
	if not bool(ef2.get("nie_jezdzi", false)):
		printerr("FAIL: awaria_silnika bez nie_jezdzi")
		return 1
	print("OK usterki: delta i nie_jezdzi")

	var auto := {
		"kategoria": "samochod",
		"nazwa": "Test Auto",
		"vmax_katalog": 180,
		"vmax_delta": -20,
		"predkosc_max_kmh": 160,
		"usterki_rzeczywiste": ["spadek_mocy"],
		"nie_jezdzi": false,
		"cena_zl": 12000,
	}
	var txt := rynek.tekst_vmax_oferty(auto, ["spadek_mocy"])
	if txt != "180 (−20)":
		printerr("FAIL: tekst vmax oczekiwano '180 (−20)' jest='", txt, "'")
		return 1
	# Ukryta usterka mocy — UI bez delty.
	var txt_ukryta := rynek.tekst_vmax_oferty(auto, [])
	if txt_ukryta != "180":
		printerr("FAIL: ukryta usterka nie powinna pokazywać delty, jest='", txt_ukryta, "'")
		return 1
	print("OK UI vmax 180 (−20) / ukryta=180")

	var przejazd = Przejazd.new()
	var vmax_e: Variant = przejazd.predkosc_max_auta(auto)
	if int(vmax_e) != 160:
		printerr("FAIL: efektywna vmax=", vmax_e)
		return 1

	var swiat := {
		"bohater": {"pieniadze": 50000},
		"majatek": {
			"dobra": [{
				"kategoria": "samochod",
				"nazwa": "Wrak",
				"nie_jezdzi": true,
				"do_naprawy": true,
				"vmax_katalog": 180,
				"vmax_delta": 0,
				"predkosc_max_kmh": 180,
				"usterki_rzeczywiste": ["awaria_silnika"],
				"usterki_deklarowane": ["awaria_silnika"],
				"usterki_ukryte": [],
				"usterki_wykryte": [],
				"cena_zl": 8000,
			}],
		},
	}
	var wyn_p: Dictionary = przejazd.oblicz(10.0, swiat["majatek"]["dobra"][0], Przejazd.TRYB_DOZWOLONA, 0.0, 6.0)
	if bool(wyn_p.get("ok", false)) or str(wyn_p.get("powod", "")).findn("nie jeździ") < 0:
		printerr("FAIL: przejazd przy nie_jezdzi powinien być zablokowany: ", wyn_p)
		return 1
	print("OK przejazd zablokowany przy nie_jezdzi")

	var law: Dictionary = rynek.laweta_auta(swiat, 0)
	if not bool(law.get("ok", false)):
		printerr("FAIL: laweta: ", law)
		return 1
	var mech: Dictionary = rynek.mechanik_auta(swiat, 0)
	if not bool(mech.get("ok", false)):
		printerr("FAIL: mechanik: ", mech)
		return 1
	if bool(swiat["majatek"]["dobra"][0].get("nie_jezdzi", false)):
		printerr("FAIL: po mechaniku nadal nie_jezdzi")
		return 1
	print("OK laweta+mechanik → jeździ, kasa=", swiat["bohater"]["pieniadze"])

	# Złom na drugim aucie
	swiat["majatek"]["dobra"].append({
		"kategoria": "samochod",
		"nazwa": "Na złom",
		"nie_jezdzi": true,
		"cena_zl": 3000,
		"usterki_rzeczywiste": ["awaria_silnika"],
	})
	var kasa_przed := int(swiat["bohater"]["pieniadze"])
	var zlom: Dictionary = rynek.zlom_auta(swiat, 1)
	if not bool(zlom.get("ok", false)):
		printerr("FAIL: złom: ", zlom)
		return 1
	if swiat["majatek"]["dobra"].size() != 1:
		printerr("FAIL: po złomie liczba aut=", swiat["majatek"]["dobra"].size())
		return 1
	if int(swiat["bohater"]["pieniadze"]) <= kasa_przed:
		printerr("FAIL: złom nie dodał pieniędzy")
		return 1
	print("OK złom: usunięte +", zlom.get("wykup_zl"), " zł")
	print("PASS test_vmax_awaria_auta")
	return 0
