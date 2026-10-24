extends SceneTree

## Headless: dryf zadowolenia (wygoda → docelowe, 50% dystansu / turę).
## godot --headless --path . --script res://scripts/test_zadowolenie_dryf.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	if not FileAccess.file_exists("res://postacie/zadowolenie_dryf.json"):
		printerr("FAIL: brak zadowolenie_dryf.json")
		return 1
	var plik := FileAccess.open("res://postacie/zadowolenie_dryf.json", FileAccess.READ)
	var conf: Variant = JSON.parse_string(plik.get_as_text())
	if not (conf is Dictionary) or not bool(conf.get("propozycja_do_poprawki", false)):
		printerr("FAIL: zły JSON dryfu")
		return 1
	var rynek = Rynek.new()
	if not rynek.pole_ukryte_w_ui("zadowolenie_docelowe"):
		printerr("FAIL: zadowolenie_docelowe powinno być ukryte_w_ui")
		return 1
	if rynek.metryka_widoczna_zadowolenia() != "psychika":
		printerr("FAIL: widoczna metryka powinna być psychika")
		return 1
	# Wzór offsetu: −20 + wygoda*0.5
	if abs(rynek.offset_wygody(0) - (-20.0)) > 0.001:
		printerr("FAIL: offset(0)=", rynek.offset_wygody(0))
		return 1
	if abs(rynek.offset_wygody(100) - 30.0) > 0.001:
		printerr("FAIL: offset(100)=", rynek.offset_wygody(100))
		return 1
	if abs(rynek.offset_wygody(40) - 0.0) > 0.001:
		printerr("FAIL: offset(40)=", rynek.offset_wygody(40))
		return 1
	# Baza 50 + offset; wygoda 100 → docelowe 80.
	var swiat := {
		"bohater": {"psychika": 50},
		"majatek": {"nieruchomosci": [{"wygoda": 100}]},
	}
	var doc := rynek.przelicz_zadowolenie_docelowe(swiat)
	if doc != 80 or int(swiat["bohater"].get("zadowolenie_docelowe", -1)) != 80:
		printerr("FAIL: docelowe przy wygodzie 100 = ", doc, swiat["bohater"])
		return 1
	# Widoczna psychika nie skacze przy samym przeliczeniu.
	if int(swiat["bohater"]["psychika"]) != 50:
		printerr("FAIL: przeliczenie nie powinno ruszac psychiki")
		return 1
	# Arytmetyka: 50 → 80 daje +15 → 65.
	var wynik: Dictionary = rynek.efekt_wygody_tydzien(swiat)
	if int(wynik.get("delta", 0)) != 15:
		printerr("FAIL: oczekiwano delta +15, jest ", wynik)
		return 1
	if int(swiat["bohater"]["psychika"]) != 65:
		printerr("FAIL: psychika po dryfie ", swiat["bohater"])
		return 1
	if str(wynik.get("tekst", "")) != "Samopoczucie: +15":
		printerr("FAIL: napis ", wynik)
		return 1
	if str(wynik.get("tekst", "")).to_lower().find("docelow") >= 0:
		printerr("FAIL: UI nie może pokazywać docelowego")
		return 1
	print("OK offset −20…+30, baza 50, docelowe ukryte, 50→80 = +15 → 65")

	# Typowy start: mieszkanie wygoda 48 → offset +4 → docelowe 54 → z 50 dryf +2.
	var typowy := {
		"bohater": {"psychika": 50},
		"lokum_startowe": {"wygoda": 48, "zrodlo": "lokum_startowe"},
		"majatek": {"nieruchomosci": []},
	}
	var t1: Dictionary = rynek.efekt_wygody_tydzien(typowy)
	if int(t1.get("docelowe", -1)) != 54 or int(t1.get("delta", 0)) != 2:
		printerr("FAIL: lokum 48 oczekiwano docelowe=54 delta=+2 ", t1)
		return 1
	if int(typowy["bohater"]["psychika"]) != 52:
		printerr("FAIL: po turze 1 psychika powinna być 52, jest ", typowy["bohater"])
		return 1
	# Pasek gracza czyta psychikę (52), nie docelowe (54).
	var widoczna := int(typowy["bohater"][rynek.metryka_widoczna_zadowolenia()])
	var ukryta := int(typowy["bohater"].get("zadowolenie_docelowe", -1))
	if widoczna == ukryta:
		printerr("FAIL: przy lokum 48 po 1 turze widoczna nie powinna równać się docelowemu jeszcze")
		return 1
	if widoczna != 52 or ukryta != 54:
		printerr("FAIL: widoczna/ukryta ", widoczna, "/", ukryta)
		return 1
	var t2: Dictionary = rynek.efekt_wygody_tydzien(typowy)
	if int(typowy["bohater"]["psychika"]) != 53 or int(t2.get("delta", 0)) != 1:
		printerr("FAIL: tura 2 lokum 48 → 53 (+1) ", t2, typowy["bohater"])
		return 1
	var t3: Dictionary = rynek.efekt_wygody_tydzien(typowy)
	if int(typowy["bohater"]["psychika"]) != 54 or int(t3.get("delta", 0)) != 1:
		printerr("FAIL: tura 3 lokum 48 → 54 (+1) ", t3, typowy["bohater"])
		return 1
	print("OK lokum 48: 50→52→53→54 (gracz ledwo widzi +2; to nie wyciek docelowego)")

	# Wygoda 40 → docelowe = baza 50 → dryf 0: pasek zostaje 50 (norma), nie bug UI.
	var flat := {
		"bohater": {"psychika": 50},
		"lokum_startowe": {"wygoda": 40},
		"majatek": {"nieruchomosci": []},
	}
	var zero: Dictionary = rynek.efekt_wygody_tydzien(flat)
	if int(zero.get("delta", -1)) != 0 or int(flat["bohater"]["psychika"]) != 50:
		printerr("FAIL: wygoda 40 powinna dać delta 0 i psychikę 50 ", zero, flat["bohater"])
		return 1
	if int(flat["bohater"].get("zadowolenie_docelowe", -1)) != 50:
		printerr("FAIL: docelowe przy wygodzie 40 = 50 ", flat["bohater"])
		return 1
	print("OK wygoda 40: pasek 50 = bieżąca norma (docelowe też 50, ukryte)")
	return 0
