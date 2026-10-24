extends SceneTree

## Headless: Start → pełny obiekt lokum; miasto→częściej mieszkanie; poza→częściej dom;
## wyższe zarobki → wyższa wygoda. Dryf bierze wygodę z lokum_startowe.
## Clamp wygody per typ; willa tylko przy bardzo wysokich zarobkach; UI „Willa”.
## godot --headless --path . --script res://scripts/test_lokum_startowe.gd

const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const ZiarnoSkrypt = preload("res://scripts/ziarno_rodzicow.gd")
const RynekSkrypt = preload("res://scripts/rynek_zakupow.gd")
const ZapisSkrypt = preload("res://scripts/zapis_swiata.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var los = LosowanieSkrypt.new()
	var ziarno = ZiarnoSkrypt.new()
	var rynek = RynekSkrypt.new()

	# 1) Pojedynczy Start: obiekt lokum istnieje i ma pola.
	var bohater: Dictionary = los.losuj_postac("kraj", "polska")
	if not bool(bohater.get("wylosowano", false)):
		printerr("FAIL: bohater nie wylosowany")
		return 1
	var miejsce: Variant = bohater.get("miejsce")
	var rodzina: Dictionary = ziarno.losuj(los, miejsce)
	var lokum: Dictionary = rynek.zbuduj_lokum_startowe(rodzina, miejsce, 424242)
	for klucz in ["typ", "metraz_m2", "pokoje", "stan", "wygoda", "lokalizacja", "nazwa"]:
		if not lokum.has(klucz):
			printerr("FAIL: brak pola lokum.", klucz, " ", lokum)
			return 1
	if not (lokum.get("wygoda") is int or lokum.get("wygoda") is float):
		printerr("FAIL: wygoda nie liczba")
		return 1
	if str(lokum.get("lokalizacja", "")) != "miasto" and str(lokum.get("lokalizacja", "")) != "poza":
		printerr("FAIL: zła lokalizacja ", lokum.get("lokalizacja"))
		return 1
	if not (rodzina.get("dom") is Dictionary) or not bool(rodzina["dom"].get("kolo", false)):
		printerr("FAIL: rodzina.dom nie ustawione", rodzina.get("dom"))
		return 1
	if not (rodzina.get("lokum") is Dictionary):
		printerr("FAIL: brak rodzina.lokum")
		return 1
	var opis := rynek.opis_lokum_ui(lokum)
	if not opis.begins_with("Mieszkacie w:"):
		printerr("FAIL: opis UI ", opis)
		return 1
	print("OK obiekt lokum: ", lokum.get("nazwa"), " lokalizacja=", lokum.get("lokalizacja"), " wygoda=", lokum.get("wygoda"))
	print("OK UI: ", opis)

	# Zapis świata jak Start.
	var swiat := {
		"bohater": bohater,
		"rodzina": rodzina,
		"majatek": {"nieruchomosci": [], "dobra": [], "lokum_rodziny": lokum.duplicate(true)},
		"lokum_startowe": lokum,
	}
	rynek.przelicz_zadowolenie_docelowe(swiat)
	var wg: Dictionary = rynek.wygoda_lokum(swiat)
	if str(wg.get("zrodlo", "")) != "lokum_startowe":
		printerr("FAIL: dryf powinien brać lokum_startowe, jest ", wg)
		return 1
	if int(wg.get("wygoda", -1)) != int(lokum["wygoda"]):
		printerr("FAIL: wygoda dryfu != lokum ", wg, lokum.get("wygoda"))
		return 1
	if not ZapisSkrypt.zapisz(swiat):
		printerr("FAIL: zapis")
		return 1
	print("OK dryf zrodlo=lokum_startowe wygoda=", wg.get("wygoda"))

	# 2) Statystyka kierunku: miasto → częściej mieszkanie; poza → częściej dom.
	var n := 80
	var miasto_mieszk := 0
	var miasto_dom := 0
	var poza_mieszk := 0
	var poza_dom := 0
	for i in n:
		var r_m: Dictionary = ziarno.losuj(los, {"id": "t_m", "nazwa": "Testowo", "typ": "miasto"})
		var l_m: Dictionary = rynek.zbuduj_lokum_startowe(r_m, {"id": "t_m", "nazwa": "Testowo", "typ": "miasto"}, 1000 + i)
		if str(l_m.get("lokalizacja", "")) == "miasto":
			var kat_m := str(l_m.get("kategoria", ""))
			if kat_m == "mieszkanie" or kat_m == "apartament" or str(l_m.get("typ", "")) == "mieszkanie" or str(l_m.get("typ", "")) == "apartament":
				miasto_mieszk += 1
			else:
				miasto_dom += 1
		var r_p: Dictionary = ziarno.losuj(los, {"id": "t_p", "nazwa": "powiat-test", "typ": "wies", "siedziba_id": "t_m", "siedziba_nazwa": "Testowo"})
		var l_p: Dictionary = rynek.zbuduj_lokum_startowe(r_p, {"id": "t_p", "nazwa": "powiat-test", "typ": "wies", "siedziba_id": "t_m", "siedziba_nazwa": "Testowo"}, 2000 + i)
		if str(l_p.get("lokalizacja", "")) == "poza":
			var kat_p := str(l_p.get("kategoria", ""))
			if kat_p == "dom" or kat_p == "willa" or str(l_p.get("typ", "")) == "dom_jednorodzinny" or str(l_p.get("typ", "")) == "willa":
				poza_dom += 1
			else:
				poza_mieszk += 1
	# Przy ważonych szansach oczekujemy przewagi kierunku (nie 100%).
	if miasto_mieszk <= miasto_dom:
		printerr("FAIL: przy lokum w mieście powinno być więcej mieszkań niż domów: mieszk=", miasto_mieszk, " dom=", miasto_dom)
		return 1
	if poza_dom <= poza_mieszk:
		printerr("FAIL: przy lokum poza powinno być więcej domów niż mieszkań: dom=", poza_dom, " mieszk=", poza_mieszk)
		return 1
	print("OK kierunek miasto: mieszk=", miasto_mieszk, " dom=", miasto_dom, " | poza: dom=", poza_dom, " mieszk=", poza_mieszk)

	# 3) Wyższe zarobki → wyższa średnia wygoda (przy tym samym miejscu/ziarnie bazowym).
	var wyg_niskie: Array = []
	var wyg_wysokie: Array = []
	for i in 40:
		var r_n := {
			"zarobki": {"kolo": true, "od_zl": 9000, "do_zl": 11000, "dochód_gospodarstwa": "suma_przedzialow_rodzicow"},
			"dom": {},
		}
		var r_w := {
			"zarobki": {"kolo": true, "od_zl": 24000, "do_zl": 30000, "dochód_gospodarstwa": "suma_przedzialow_rodzicow"},
			"dom": {},
		}
		var miejsce_t := {"id": "t_m", "nazwa": "Testowo", "typ": "miasto"}
		wyg_niskie.append(int(rynek.zbuduj_lokum_startowe(r_n, miejsce_t, 5000 + i).get("wygoda", 0)))
		wyg_wysokie.append(int(rynek.zbuduj_lokum_startowe(r_w, miejsce_t, 6000 + i).get("wygoda", 0)))
	var sr_n := _srednia(wyg_niskie)
	var sr_w := _srednia(wyg_wysokie)
	if sr_w <= sr_n + 3.0:
		printerr("FAIL: wyższe zarobki powinny dawać wyraźnie wyższą wygodę: niskie=", sr_n, " wysokie=", sr_w)
		return 1
	print("OK zarobki→wygoda: niskie≈", snappedf(sr_n, 0.1), " wysokie≈", snappedf(sr_w, 0.1))

	# 4) Clamp wygody per typ + willa tylko przy bardzo wysokich zarobkach.
	var conf_n: Dictionary = rynek.wczytaj().get("nieruchomosci", {}) if rynek.wczytaj().get("nieruchomosci") is Dictionary else {}
	var clamp_map: Dictionary = conf_n.get("wygoda_clamp_typu", {}) if conf_n.get("wygoda_clamp_typu") is Dictionary else {}
	var sufit_m := int(clamp_map.get("mieszkanie", 82))
	var sufit_d := int(clamp_map.get("dom", 86))
	var sufit_a := int(clamp_map.get("apartament", 100))
	var sufit_w := int(clamp_map.get("willa", 100))
	if sufit_m >= 90 or sufit_d >= 95 or sufit_a < 98 or sufit_w < 98:
		printerr("FAIL: sufity typów poza propozycją (m≈75–85, d≈80–90, a/w→100): m=", sufit_m, " d=", sufit_d, " a=", sufit_a, " w=", sufit_w)
		return 1
	var lok_conf: Dictionary = conf_n.get("lokum_startowe", {}) if conf_n.get("lokum_startowe") is Dictionary else {}
	var tw: Dictionary = lok_conf.get("typ_wagi", {}) if lok_conf.get("typ_wagi") is Dictionary else {}
	var min_willa := float(tw.get("willa_min_poziom_zarobkow", 0.88))
	var willa_niskie := 0
	var willa_wysokie := 0
	var max_wyg_m := -1
	var max_wyg_d := -1
	var max_wyg_a := -1
	var max_wyg_w := -1
	var miejsce_t2 := {"id": "t_m", "nazwa": "Testowo", "typ": "miasto"}
	for i in 120:
		var r_niski := {
			"zarobki": {"kolo": true, "od_zl": 10000, "do_zl": 14000, "dochód_gospodarstwa": "suma_przedzialow_rodzicow"},
			"dom": {},
		}
		var r_wysoki := {
			"zarobki": {"kolo": true, "od_zl": 28000, "do_zl": 32000, "dochód_gospodarstwa": "suma_przedzialow_rodzicow"},
			"dom": {},
		}
		var l_n: Dictionary = rynek.zbuduj_lokum_startowe(r_niski, miejsce_t2, 7000 + i)
		var l_h: Dictionary = rynek.zbuduj_lokum_startowe(r_wysoki, miejsce_t2, 8000 + i)
		if str(l_n.get("kategoria", "")) == "willa" or str(l_n.get("typ", "")) == "willa":
			willa_niskie += 1
		if str(l_h.get("kategoria", "")) == "willa" or str(l_h.get("typ", "")) == "willa":
			willa_wysokie += 1
		for lok in [l_n, l_h]:
			var kat := str(lok.get("kategoria", ""))
			var wyg := int(lok.get("wygoda", 0))
			var typ_n := str(lok.get("typ_nazwa", ""))
			if kat == "willa" and typ_n != "Willa":
				printerr("FAIL: UI typ_nazwa powinno być Willa, jest ", typ_n, " ", lok)
				return 1
			if kat == "willa" and not rynek.opis_lokum_ui(lok).contains("Willa"):
				printerr("FAIL: opis UI bez Willi: ", rynek.opis_lokum_ui(lok))
				return 1
			match kat:
				"mieszkanie":
					max_wyg_m = maxi(max_wyg_m, wyg)
					if wyg > sufit_m:
						printerr("FAIL: mieszkanie powyżej sufitu ", wyg, ">", sufit_m)
						return 1
				"dom":
					max_wyg_d = maxi(max_wyg_d, wyg)
					if wyg > sufit_d:
						printerr("FAIL: dom powyżej sufitu ", wyg, ">", sufit_d)
						return 1
				"apartament":
					max_wyg_a = maxi(max_wyg_a, wyg)
					if wyg > sufit_a:
						printerr("FAIL: apartament powyżej sufitu ", wyg, ">", sufit_a)
						return 1
				"willa":
					max_wyg_w = maxi(max_wyg_w, wyg)
					if wyg > sufit_w:
						printerr("FAIL: willa powyżej sufitu ", wyg, ">", sufit_w)
						return 1
	if willa_niskie > 0:
		printerr("FAIL: willa przy niskich zarobkach (poziom poniżej ", min_willa, "): ", willa_niskie)
		return 1
	# Przy bardzo wysokich zarobkach willa powinna być możliwa (choć rzadka) — kilka prób poza miastem też.
	for i in 200:
		var r_top := {
			"zarobki": {"kolo": true, "od_zl": 29000, "do_zl": 35000, "dochód_gospodarstwa": "suma_przedzialow_rodzicow"},
			"dom": {},
		}
		var l_p: Dictionary = rynek.zbuduj_lokum_startowe(
			r_top,
			{"id": "t_p", "nazwa": "powiat-test", "typ": "wies", "siedziba_id": "t_m", "siedziba_nazwa": "Testowo"},
			9000 + i
		)
		if str(l_p.get("kategoria", "")) == "willa" or str(l_p.get("typ", "")) == "willa":
			willa_wysokie += 1
			max_wyg_w = maxi(max_wyg_w, int(l_p.get("wygoda", 0)))
			if str(l_p.get("typ_nazwa", "")) != "Willa":
				printerr("FAIL: typ_nazwa willi: ", l_p.get("typ_nazwa"))
				return 1
	if willa_wysokie < 1:
		printerr("FAIL: przy bardzo wysokich zarobkach willa powinna być możliwa (0 wylosowań)")
		return 1
	print(
		"OK clamp typów: max m=", max_wyg_m, "/", sufit_m,
		" d=", max_wyg_d, "/", sufit_d,
		" a=", max_wyg_a, "/", sufit_a,
		" w=", max_wyg_w, "/", sufit_w,
		" | willa niskie=", willa_niskie, " wysokie=", willa_wysokie,
		" (min_poziom=", snappedf(min_willa, 0.01), ")"
	)
	return 0


func _srednia(lista: Array) -> float:
	if lista.is_empty():
		return 0.0
	var s := 0.0
	for v in lista:
		s += float(v)
	return s / float(lista.size())
