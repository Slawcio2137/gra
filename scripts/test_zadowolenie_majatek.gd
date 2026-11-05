extends SceneTree

## Plus auta ze stanu, ból usterki bez kary w celu, wygoda miejsca zamieszkania, progi z JSON.
## godot --headless --path . --script res://scripts/test_zadowolenie_majatek.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const Dostep = preload("res://scripts/statystyki_dostep.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	if Dostep.POKAZ_STATYSTYKI:
		printerr("FAIL: POKAZ_STATYSTYKI ma być wyłączone")
		return 1
	var rynek = Rynek.new()
	if not rynek.kategoria_daje_plusy("samochod"):
		printerr("FAIL: samochód nie daje plusów")
		return 1
	rynek.offset_wygody(0)
	var plusy: Dictionary = rynek._dryf["plusy_dobr"]
	var mapa: Dictionary = plusy["mapa"]
	var progi: Dictionary = plusy["progi"]
	var nowy := {
		"kategoria": "samochod",
		"stan": "nowy",
		"usterki_deklarowane": [],
		"usterki_rzeczywiste": [],
	}
	if rynek.plusy_oferty(nowy) != int(mapa["nowy_bez_usterek"]):
		printerr("FAIL: nowe auto bez usterek ", rynek.plusy_oferty(nowy))
		return 1
	var sredni := {
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_deklarowany": 90,
		"usterki_deklarowane": [],
	}
	if rynek.plusy_oferty(sredni) != int(mapa["nowy_z_usterka_albo_uzywany_bez_usterek_stan_od_80"]):
		printerr("FAIL: używane auto stan 90 ", rynek.plusy_oferty(sredni))
		return 1
	var slaby := {
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_deklarowany": 60,
		"usterki_deklarowane": ["drobna_usterka"],
	}
	if rynek.plusy_oferty(slaby) != int(mapa["uzywany_powaga_do_3_i_stan_od_50"]):
		printerr("FAIL: używane auto z drobną usterką ", rynek.plusy_oferty(slaby))
		return 1
	var pad := {
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_deklarowany": 95,
		"nie_jezdzi": true,
		"do_naprawy": true,
		"kupiono_tydzien": 1,
		"usterki_rzeczywiste": ["awaria_silnika"],
	}
	if rynek.plusy_oferty(pad) != int(mapa["nawalajacy"]):
		printerr("FAIL: nawalające auto ma dać ", mapa["nawalajacy"], " a dało ", rynek.plusy_oferty(pad))
		return 1
	if rynek.tekst_plusow(rynek.plusy_oferty(pad)) != "":
		printerr("FAIL: plus 0 nie powinien rysować plusów")
		return 1
	var dwa := {
		"bohater": {"psychika": 50},
		"lokum_startowe": {"wygoda": 40},
		"majatek": {"nieruchomosci": [], "dobra": [nowy.duplicate(true), nowy.duplicate(true)]},
	}
	if rynek.przelicz_zadowolenie_docelowe(dwa) != 50 + int(mapa["nowy_bez_usterek"]):
		printerr("FAIL: dwa takie same auta zsumowały plus ", dwa["bohater"])
		return 1
	print("OK plus samochodu: nowe / używane / nawalające, bez sumy dubli")

	var stary_plus := int(mapa["nowy_bez_usterek"])
	mapa["nowy_bez_usterek"] = 9
	if rynek.plusy_oferty(nowy) != 9:
		printerr("FAIL: plusy nie czytają mapy z JSON")
		mapa["nowy_bez_usterek"] = stary_plus
		return 1
	mapa["nowy_bez_usterek"] = stary_plus
	var stary_prog := int(progi["stan_od_dla_2"])
	progi["stan_od_dla_2"] = 90
	if rynek.plusy_oferty(slaby) != int(mapa["reszta_uszkodzonych"]):
		printerr("FAIL: próg stan_od_dla_2 nie jest z JSON ", rynek.plusy_oferty(slaby))
		progi["stan_od_dla_2"] = stary_prog
		return 1
	progi["stan_od_dla_2"] = stary_prog
	if rynek.plusy_oferty(slaby) != int(mapa["uzywany_powaga_do_3_i_stan_od_50"]):
		printerr("FAIL: próg nie wrócił")
		return 1
	print("OK progi i mapa plusów czytane z JSON")

	var bol_sw := {
		"bohater": {"psychika": 50, "zadowolenie_docelowe": 54},
		"lokum_startowe": {"wygoda": 40},
		"majatek": {"nieruchomosci": [], "dobra": [pad.duplicate(true)]},
	}
	var minus_awarii := int(plusy["bol_zdarzenia"]["minus_awaria"])
	var bol: Dictionary = rynek.bol_zdarzenia(bol_sw, true)
	if int(bol.get("delta", 0)) != -minus_awarii:
		printerr("FAIL: delta bólu ", bol)
		return 1
	if int(bol_sw["bohater"]["psychika"]) != 50 - minus_awarii:
		printerr("FAIL: psychika po awarii ", bol_sw["bohater"])
		return 1
	if int(bol_sw["bohater"]["zadowolenie_docelowe"]) != 54 or int(bol.get("docelowe", -1)) != 54:
		printerr("FAIL: awaria zmieniła cel ", bol_sw["bohater"])
		return 1
	var po_przeliczeniu := rynek.przelicz_zadowolenie_docelowe(bol_sw)
	if po_przeliczeniu != 50:
		printerr("FAIL: cel po przeliczeniu nawalającego auta ma być 50 (brak plusa), jest ", po_przeliczeniu)
		return 1
	if po_przeliczeniu == 54 - minus_awarii:
		printerr("FAIL: kara awarii weszła w cel")
		return 1
	var dryf: Dictionary = rynek.efekt_wygody_tydzien(bol_sw)
	var oczekiwana := roundi(0.5 * float(50 - (50 - minus_awarii)))
	if int(dryf.get("delta", 0)) != oczekiwana:
		printerr("FAIL: tura powtórzyła ból zamiast dryfu ", dryf)
		return 1
	print("OK ból awarii jest chwilowy, cel nie trzyma kary")

	var dom := {
		"bohater": {"psychika": 50, "zadowolenie_docelowe": 50},
		"lokum_startowe": {"wygoda": 70, "typ_nazwa": "Dom rodziny", "lokalizacja": "miasto"},
		"majatek": {
			"nieruchomosci": [
				{"nazwa": "Kawalerka", "wygoda": 20, "kategoria": "mieszkanie"},
				{"nazwa": "Willa", "wygoda": 95, "kategoria": "willa"},
			],
			"dobra": [],
		},
	}
	var wg: Dictionary = rynek.wygoda_lokum(dom)
	if int(wg.get("wygoda", -1)) != 70 or str(wg.get("zrodlo", "")) != "lokum_startowe":
		printerr("FAIL: kupno gorszej kawalerki skasowało dom rodziny ", wg)
		return 1
	var opis: String = rynek.opis_lokum_ui(dom["lokum_startowe"])
	if not opis.begins_with("Mieszkacie w:") or opis.find("wygoda 70") < 0:
		printerr("FAIL: opis bez wygody ", opis)
		return 1
	var przeprowadzka: Dictionary = rynek.zamieszkaj_we_wlasnym(dom, 0)
	if not bool(przeprowadzka.get("ok", false)):
		printerr("FAIL: zamieszkaj ", przeprowadzka)
		return 1
	var po_przeprowadzce: Dictionary = rynek.wygoda_lokum(dom)
	if int(po_przeprowadzce.get("wygoda", -1)) != 20 or str(po_przeprowadzce.get("zrodlo", "")) != "wlasna":
		printerr("FAIL: mieszka w wyższej willi zamiast w kawalerce ", po_przeprowadzce)
		return 1
	if str(dom.get("zapowiedz_zadowolenia", "")).find(rynek.tekst_zapowiedzi_tury()) < 0:
		printerr("FAIL: brak zapowiedzi następnej tury ", dom.get("zapowiedz_zadowolenia"))
		return 1
	if not bool(rynek.zamieszkaj_u_rodziny(dom).get("ok", false)):
		printerr("FAIL: powrót do rodziny")
		return 1
	if int(rynek.wygoda_lokum(dom).get("wygoda", -1)) != 70:
		printerr("FAIL: po powrocie wygoda ", rynek.wygoda_lokum(dom))
		return 1
	print("OK wygoda z miejsca zamieszkania, nie z najwyższej w majątku")

	var kup_sw := {
		"bohater": {"psychika": 50, "pieniadze": 100, "zadowolenie_docelowe": 50},
		"lokum_startowe": {"wygoda": 40},
		"majatek": {"nieruchomosci": [], "dobra": []},
		"tydzien": 3,
		"rynek_zakupow": {
			"miasto_gracza_id": "m",
			"oferty": [{
				"id": "auto_dobre",
				"kategoria": "samochod",
				"stan": "nowy",
				"cena_zl": 0,
				"miasto_id": "m",
				"miasto_gracza": true,
				"usterki_deklarowane": [],
				"usterki_rzeczywiste": [],
			}],
		},
	}
	var kup: Dictionary = rynek.kup(kup_sw, "auto_dobre")
	if not bool(kup.get("ok", false)):
		printerr("FAIL: kupno dobrego auta ", kup)
		return 1
	if int(kup_sw["bohater"]["psychika"]) != 50:
		printerr("FAIL: dobre auto zbiło psychikę ", kup_sw["bohater"])
		return 1
	if int(kup_sw["bohater"]["zadowolenie_docelowe"]) != 50 + int(mapa["nowy_bez_usterek"]):
		printerr("FAIL: cel po dobrym aucie ", kup_sw["bohater"])
		return 1
	if str(kup.get("tekst", "")).find(rynek.tekst_zapowiedzi_tury()) < 0:
		printerr("FAIL: kupno bez zapowiedzi ", kup)
		return 1
	var zepsute := {
		"id": "auto_zle",
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_deklarowany": 30,
		"cena_zl": 0,
		"miasto_id": "m",
		"miasto_gracza": true,
		"nie_jezdzi": true,
		"usterki_rzeczywiste": ["awaria_silnika"],
		"usterki_deklarowane": ["awaria_silnika"],
	}
	kup_sw["rynek_zakupow"]["oferty"] = [zepsute]
	kup_sw["bohater"]["psychika"] = 50
	kup_sw["bohater"]["zadowolenie_docelowe"] = int(kup_sw["bohater"]["zadowolenie_docelowe"])
	var cel_przed := int(kup_sw["bohater"]["zadowolenie_docelowe"])
	var kup_z: Dictionary = rynek.kup(kup_sw, "auto_zle")
	if not bool(kup_z.get("ok", false)):
		printerr("FAIL: kupno zepsutego ", kup_z)
		return 1
	if int(kup_sw["bohater"]["psychika"]) != 50 - minus_awarii:
		printerr("FAIL: zepsute auto nie zabolało od razu ", kup_sw["bohater"])
		return 1
	if int(kup_sw["bohater"]["zadowolenie_docelowe"]) != cel_przed:
		printerr("FAIL: zepsute auto zmieniło cel o karę ", kup_sw["bohater"], " przed ", cel_przed)
		return 1
	if str(kup_z.get("tekst", "")).find("Awaria") < 0:
		printerr("FAIL: brak napisu awarii ", kup_z)
		return 1
	print("OK kupno: dobre auto zapowiada turę, zepsute boli raz i nie psuje celu")
	print("PASS zadowolenie majątek")
	return 0
