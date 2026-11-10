extends RefCounted
class_name EkranDomu

## Ekrany domu, zdrowia i majątku.

var h


func _init(host) -> void:
	h = host




func _ekran_dom() -> void:
	var tekst := _tekst_domu()
	if tekst != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(tekst, 20))
	else:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Dom. Brak nazwy w zapisie.", 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(h._stan._opis_lokalizacji(), 15))


func _ekran_zdrowie() -> void:
	var bohater = h._stan._bohater()
	var skrot := str(bohater.get("zdrowie_skrot", ""))
	if skrot != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(skrot, 18))
	else:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zdrowie ilościowe pojawi się, gdy będzie w zapisie. Chorób na starcie nie wypisuję.", 16))
	var zdrowie = h._ui._tekst_pusty(bohater.get("zdrowie"))
	if zdrowie != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zdrowie: %s" % zdrowie, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(dep_txt, 15))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Terapia / nastrój — w podmenu Zdrowie.", 14))


func _ekran_majatek() -> void:
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Pieniądze", 18))
	var kwota = h._stan._pieniadze_tekst()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(kwota if kwota != "" else "—", 18))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(opis_lokum, 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Nieruchomości", 18))
	var maj: Dictionary = h._swiat.get("majatek", {}) if h._swiat.get("majatek") is Dictionary else {}
	var n_lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if n_lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Własne kupione: brak — kup w Zakupach (generator, nie katalog 200).", 14))
	else:
		for i in range(n_lista.size()):
			var n: Variant = n_lista[i]
			if not (n is Dictionary):
				continue
			var linia := "%s · wygoda %s · %s" % [
				str(n.get("nazwa", "?")),
				str(n.get("wygoda", "—")),
				str(n.get("miasto_nazwa", "")),
			]
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia, 14))
			if n.get("remont_trwa") is Dictionary:
				_dopisz_postep_remontu(n["remont_trwa"])
				continue
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(h._rynek_zakupow.tekst_szacunku_remontu(n), 14))
			_dodaj_tryby_remontu(i, n)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Dobra", 18))
	var d_lista: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if d_lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Pusto.", 14))
	else:
		for i_d in range(d_lista.size()):
			var d: Variant = d_lista[i_d]
			if not (d is Dictionary):
				continue
			var nazwa_d := str(d.get("nazwa", "?"))
			if str(d.get("kategoria", "")) == "samochod":
				var linia_a := nazwa_d
				var vmax_m = h._rynek_zakupow.tekst_vmax_oferty(d, d.get("usterki_rzeczywiste", []) if d.get("usterki_rzeczywiste") is Array else [])
				if vmax_m != "":
					linia_a += " · vmax %s km/h" % vmax_m
				if bool(d.get("nie_jezdzi", false)):
					linia_a += " · NIE JEŹDZI"
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia_a, 14))
				if bool(d.get("nie_jezdzi", false)) or bool(d.get("do_naprawy", false)):
					h._ui._tresc_biala().add_child(h._mapa_ekran._panel_awarii_auta(i_d, d))
			else:
				var linia_d := nazwa_d
				if h._rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var plus_d = h._rynek_zakupow.tekst_plusow(h._rynek_zakupow.plusy_oferty(d))
					if plus_d != "":
						h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zadowolenie: %s" % plus_d, 14))
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia_d, 14))
				if h._rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var b_oddaj := Button.new()
					b_oddaj.text = "Oddaj"
					b_oddaj.custom_minimum_size = Vector2(0, 40)
					var idx_d := i_d
					b_oddaj.pressed.connect(func() -> void:
						var wynik_o: Dictionary = h._rynek_zakupow.oddaj_dobro(h._swiat, idx_d)
						if bool(wynik_o.get("ok", false)):
							h.SkryptZapisu.zapisz(h._swiat)
							h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
					)
					h._ui._tresc_biala().add_child(b_oddaj)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Wpływy", 18))
	var lista: Variant = h._swiat.get("wplywy", [])
	if not (lista is Array) or lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak wpływów.", 15))
		return
	var od := maxi(0, lista.size() - 12)
	for i in range(od, lista.size()):
		var wpis: Variant = lista[i]
		if not (wpis is Dictionary):
			continue
		var linia2 := str(wpis.get("tekst", ""))
		if linia2 == "" and h._ui._jest_liczba(wpis.get("kwota")):
			linia2 = "%s: +%d zł" % [str(wpis.get("zrodlo", "wpływ")), int(wpis["kwota"])]
		if linia2 != "":
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia2, 15))


func _tekst_domu() -> String:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return ""
	var dom: Variant = rodzina.get("dom", {})
	if dom is Dictionary and dom.get("kolo") == true and str(dom.get("nazwa", "")) != "":
		return str(dom.get("nazwa"))
	return ""


func _opis_mieszkacie_w() -> String:
	var lokum: Variant = h._swiat.get("lokum_startowe", {})
	if not h._stan._lokum_pelne(lokum):
		var maj: Variant = h._swiat.get("majatek", {})
		if maj is Dictionary and maj.get("lokum_rodziny") is Dictionary:
			lokum = maj["lokum_rodziny"]
		else:
			var rodzina: Variant = h._swiat.get("rodzina", {})
			if rodzina is Dictionary and rodzina.get("lokum") is Dictionary:
				lokum = rodzina["lokum"]
	return h._rynek_zakupow.opis_lokum_ui(lokum)


func _dopisz_postep_remontu(trwa: Dictionary) -> void:
	var zostalo := maxi(0, int(trwa.get("tygodni", 0)) - int(trwa.get("minelo", 0)))
	var tryb := str(trwa.get("tryb", "sam"))
	var linia := "Remont (%s): tydzień %d/%d, koniec za %d tyg." % [
		h._rynek_zakupow.nazwa_trybu_remontu(tryb),
		int(trwa.get("minelo", 0)),
		int(trwa.get("tygodni", 0)),
		zostalo,
	]
	var zm := int(trwa.get("zmeczenie_tydzien", 0))
	if zm > 0:
		linia += " Zmęczenie fiz. +%d/tydz." % zm
	if str(trwa.get("kumpel_nazwa", "")) != "":
		linia += " Pomaga %s." % str(trwa.get("kumpel_nazwa"))
	if int(trwa.get("stawka_tygodniowa", 0)) > 0:
		linia += " Stawka %d zł/tydz." % int(trwa.get("stawka_tygodniowa"))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia, 14))
	if str(trwa.get("blokada", "")) != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(trwa.get("blokada")), 14))


func _dodaj_tryby_remontu(indeks: int, n: Dictionary) -> void:
	var rynek = h._rynek_zakupow
	var mat: int = rynek.koszt_remontu_prawdziwy(n)
	if mat <= 0:
		return
	if str(n.get("stan", "")) == "surowy":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
			"Stan surowy: wykończenie droższe i 3× dłuższe niż zwykły remont w tym samym trybie.",
			14
		))
	var t_sam: int = rynek.tygodnie_remontu_trybu(n, "sam")
	var t_k: int = rynek.tygodnie_remontu_trybu(n, "kumpel")
	var t_f: int = rynek.tygodnie_remontu_trybu(n, "firma")
	var c_sam: int = rynek.koszt_startu_remontu(n, "sam")
	var c_f: int = rynek.koszt_startu_remontu(n, "firma")
	var z_sam: int = rynek.zmeczenie_remontu_tydzien("sam")
	var z_k: int = rynek.zmeczenie_remontu_tydzien("kumpel")
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
		"Samemu: %d zł materiałów, %d tyg., zmęczenie fiz. +%d/tydz." % [c_sam, t_sam, z_sam],
		14
	))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
		"Z kumplem: materiały %d zł + jego stawka, %d tyg., zmęczenie +%d/tydz." % [c_sam, t_k, z_k],
		14
	))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
		"Firma: %d zł (robocizna i materiały), %d tyg., bez zmęczenia." % [c_f, t_f],
		14
	))
	var idx := indeks
	var b_sam := Button.new()
	b_sam.text = "Rób samemu"
	b_sam.custom_minimum_size = Vector2(0, 40)
	b_sam.pressed.connect(func() -> void:
		_po_starcie_remontu(rynek.remont(h._swiat, idx, "sam"))
	)
	h._ui._tresc_biala().add_child(b_sam)
	var b_firma := Button.new()
	b_firma.text = "Zleć firmie"
	b_firma.custom_minimum_size = Vector2(0, 40)
	b_firma.pressed.connect(func() -> void:
		_po_starcie_remontu(rynek.remont(h._swiat, idx, "firma"))
	)
	h._ui._tresc_biala().add_child(b_firma)
	var b_k := Button.new()
	b_k.text = "Poproś kumpla (stawka)"
	b_k.custom_minimum_size = Vector2(0, 40)
	b_k.pressed.connect(func() -> void:
		_pokaz_oferte_kumpla(idx, n)
	)
	h._ui._tresc_biala().add_child(b_k)


func _pokaz_oferte_kumpla(indeks: int, n: Dictionary) -> void:
	var rynek = h._rynek_zakupow
	var kandydaci: Array = rynek.kandydaci_pomocy_oceny(h._swiat)
	var box: Control = h._ui._tresc_biala()
	if kandydaci.is_empty():
		box.add_child(h._ui._napis_ekranu("Nie masz kogo poprosić o pomoc przy remoncie.", 14))
		return
	var sug: int = rynek.sugerowana_stawka_tygodniowa(n)
	var tyg: int = rynek.tygodnie_remontu_trybu(n, "kumpel")
	box.add_child(h._ui._napis_ekranu(
		"Sugerowana stawka: %d zł/tydz. przez %d tyg. (łącznie około %d zł). Lepsza relacja obniża próg zgody, przy bardzo dobrej wystarczy symboliczna kwota." % [sug, tyg, sug * tyg],
		14
	))
	for k in kandydaci:
		if not (k is Dictionary):
			continue
		var osoba: Dictionary = k.get("osoba", {}) if k.get("osoba") is Dictionary else {}
		var relacja: int = rynek._relacja_osoby(osoba)
		var min_tyg: int = rynek.min_stawka_tygodniowa(n, relacja)
		var ref := str(k.get("ref", ""))
		box.add_child(h._ui._napis_ekranu(
			"%s — relacja %d, zgodzi się od %d zł/tydz." % [str(k.get("nazwa", ref)), relacja, min_tyg],
			14
		))
		var pole := LineEdit.new()
		pole.text = str(sug)
		pole.placeholder_text = "zł"
		pole.custom_minimum_size = Vector2(0, 40)
		box.add_child(pole)
		var b_tyg := Button.new()
		b_tyg.text = "Zaproponuj stawkę tygodniową"
		b_tyg.custom_minimum_size = Vector2(0, 40)
		var b_raz := Button.new()
		b_raz.text = "Zaproponuj kwotę łączną"
		b_raz.custom_minimum_size = Vector2(0, 40)
		var idx := indeks
		var ref_b := ref
		b_tyg.pressed.connect(func() -> void:
			_po_starcie_remontu(rynek.zaproponuj_pomoc_remontu(h._swiat, idx, ref_b, int(pole.text), false))
		)
		b_raz.pressed.connect(func() -> void:
			_po_starcie_remontu(rynek.zaproponuj_pomoc_remontu(h._swiat, idx, ref_b, int(pole.text), true))
		)
		box.add_child(b_tyg)
		box.add_child(b_raz)


func _po_starcie_remontu(wynik: Dictionary) -> void:
	if bool(wynik.get("ok", false)):
		h.SkryptZapisu.zapisz(h._swiat)
		h._stan._zsynchronizuj_pieniadze_z_bohatera()
		h._pasek._odswiez_pasek_statystyk(false)
		h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
		return
	var tekst := str(wynik.get("tekst", wynik.get("powod", "Remont nieudany.")))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(tekst, 14))
