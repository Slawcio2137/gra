extends RefCounted
class_name EkranMapy

## Mapa miast, transport i auto z zapisu.

var h


func _init(host) -> void:
	h = host




func _ekran_transport(_kolor: Color) -> void:
	var auto: Variant = _auto_z_zapisu()
	if auto == null:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Auta nie ma.", 20))
	else:
		var opis := _opis_auta(auto)
		if opis != "":
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(opis, 18))
		h._ui._dol_suwaka().show()
		h._ui._dol_suwaka().add_child(h._ui._z_marginesem(h._ui._kropki_dni(int(h._swiat.get("dni_auta", 0)), _ustaw_dni_auta)))
		h._ui._dol_suwaka().add_child(h._ui._z_marginesem(h._ui._napis_ekranu("Cena na tydzień: %s" % _cena_tygodnia_auta(auto), 16)))
	var mapa := Button.new()
	mapa.text = "Mapa"
	mapa.custom_minimum_size = Vector2(0, 44)
	mapa.pressed.connect(func() -> void:
		h._otworz_akcje({"id": "mapa", "nazwa": "Mapa", "tryb": "ekran", "tresc": "mapa", "kolor": "#8aa0a8"})
	)
	h._ui._tresc_biala().add_child(mapa)


func _ekran_mapa() -> void:
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
		"Mapa uproszczona: miasta i drogi między nimi (sąsiedztwo). Bez GIS / bez ulic.",
		16
	))
	if h._mapa_ikona == null and ResourceLoader.exists(h.IKONA_MIASTA):
		h._mapa_ikona = load(h.IKONA_MIASTA) as Texture2D
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	var ziarno := int(h._swiat.get("rynek_zakupow", {}).get("ziarno", 1)) if h._swiat.get("rynek_zakupow") is Dictionary else 1
	if ziarno == 0:
		ziarno = int(h._swiat.get("tydzien", 1)) * 9973 + 1
	h._mapa_graf = h._mapa_miast.zbuduj(miasta, ziarno, h._stan._id_miejsca_pobytu())
	var obszar := Control.new()
	obszar.custom_minimum_size = Vector2(0, 420)
	obszar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obszar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	obszar.clip_contents = true
	h._mapa_warstwa = obszar
	h._ui._tresc_biala().add_child(obszar)
	h._mapa_pasek = h._ui._napis_ekranu("Kliknij miasto — kto tam mieszka (bez znajomych).", 16)
	h._mapa_pasek.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h._ui._tresc_biala().add_child(h._mapa_pasek)
	h._opcje_transportu = VBoxContainer.new()
	h._opcje_transportu.add_theme_constant_override("separation", 8)
	h._ui._tresc_biala().add_child(h._opcje_transportu)
	obszar.resized.connect(_przerysuj_mape_miast)
	obszar.draw.connect(_rysuj_krawedzie_mapy)
	call_deferred("_przerysuj_mape_miast")


func _przerysuj_mape_miast() -> void:
	if h._mapa_warstwa == null or not is_instance_valid(h._mapa_warstwa):
		return
	for d in h._mapa_warstwa.get_children():
		h._mapa_warstwa.remove_child(d)
		d.queue_free()
	var wierz: Array = h._mapa_graf.get("wierzcholki", []) if h._mapa_graf is Dictionary else []
	if wierz.is_empty():
		return
	var min_x := 1e9
	var max_x := -1e9
	var min_y := 1e9
	var max_y := -1e9
	for w in wierz:
		if not (w is Dictionary):
			continue
		min_x = minf(min_x, float(w.get("x", 0)))
		max_x = maxf(max_x, float(w.get("x", 0)))
		min_y = minf(min_y, float(w.get("y", 0)))
		max_y = maxf(max_y, float(w.get("y", 0)))
	var marg := 36.0
	var szer := maxf(1.0, h._mapa_warstwa.size.x - marg * 2.0)
	var wys := maxf(1.0, h._mapa_warstwa.size.y - marg * 2.0)
	var dx := maxf(1.0, max_x - min_x)
	var dy := maxf(1.0, max_y - min_y)
	for w in wierz:
		if not (w is Dictionary):
			continue
		var nx := marg + (float(w.get("x", 0)) - min_x) / dx * szer
		var ny := marg + (float(w.get("y", 0)) - min_y) / dy * wys
		w["_sx"] = nx
		w["_sy"] = ny
		var kolumna := VBoxContainer.new()
		kolumna.position = Vector2(nx - 28, ny - 40)
		kolumna.custom_minimum_size = Vector2(56, 70)
		kolumna.alignment = BoxContainer.ALIGNMENT_CENTER
		var nazwa := Label.new()
		nazwa.text = str(w.get("nazwa", "?"))
		nazwa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nazwa.add_theme_font_size_override("font_size", 16)
		nazwa.add_theme_color_override("font_color", h.TEKST_CIEMNY)
		nazwa.autowrap_mode = TextServer.AUTOWRAP_OFF
		nazwa.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nazwa.custom_minimum_size = Vector2(56, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.focus_mode = Control.FOCUS_NONE
		btn.flat = true
		if h._mapa_ikona != null:
			btn.icon = h._mapa_ikona
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 36)
		else:
			btn.text = "●"
		var id_m := str(w.get("id", ""))
		var naz_m := str(w.get("nazwa", "?"))
		btn.pressed.connect(_on_klik_miasta_mapy.bind(id_m, naz_m))
		kolumna.add_child(nazwa)
		kolumna.add_child(btn)
		h._mapa_warstwa.add_child(kolumna)
	h._mapa_warstwa.queue_redraw()


func _rysuj_krawedzie_mapy() -> void:
	if h._mapa_warstwa == null or not is_instance_valid(h._mapa_warstwa):
		return
	var po: Dictionary = {}
	for w in h._mapa_graf.get("wierzcholki", []):
		if w is Dictionary and w.has("_sx"):
			po[str(w.get("id", ""))] = Vector2(float(w["_sx"]), float(w["_sy"]))
	for k in h._mapa_graf.get("krawedzie", []):
		if not (k is Dictionary):
			continue
		var a := str(k.get("a", ""))
		var b := str(k.get("b", ""))
		if not po.has(a) or not po.has(b):
			continue
		h._mapa_warstwa.draw_line(po[a], po[b], Color(0.45, 0.52, 0.58, 0.7), 2.0, true)


func _on_klik_miasta_mapy(id: String, nazwa: String) -> void:
	h._swiat["mapa_miasto_id"] = id
	h._swiat["mapa_miasto_nazwa"] = nazwa
	var kto: Dictionary = h._mapa_miast.mieszkancy_miasta(h._swiat, id)
	var czesci: PackedStringArray = []
	var rodzice_l: Array = kto.get("rodzice", []) if kto.get("rodzice") is Array else []
	var dziad_l: Array = kto.get("dziadkowie", []) if kto.get("dziadkowie") is Array else []
	var przyj_l: Array = kto.get("przyjaciele", []) if kto.get("przyjaciele") is Array else []
	if not rodzice_l.is_empty():
		czesci.append("Rodzice: %s" % h._ui._join_tekstow(rodzice_l))
	if not dziad_l.is_empty():
		czesci.append("Dziadkowie: %s" % h._ui._join_tekstow(dziad_l))
	if not przyj_l.is_empty():
		czesci.append("Przyjaciele: %s" % h._ui._join_tekstow(przyj_l))
	if h._mapa_pasek != null and is_instance_valid(h._mapa_pasek):
		if czesci.is_empty():
			h._mapa_pasek.text = "%s — nikt z rodziny/przyjaciół tu nie mieszka." % nazwa
		else:
			h._mapa_pasek.text = "%s — %s" % [nazwa, " · ".join(czesci)]
	_wypelnij_opcje_transportu(id, nazwa)


func _odswiez_liste_miast(_tekst: String) -> void:
	pass


func _on_miasto_mapy(_indeks: int) -> void:
	pass


func _wypelnij_opcje_transportu(id: String, nazwa: String) -> void:
	if h._opcje_transportu == null or not is_instance_valid(h._opcje_transportu):
		return
	h._ui._wyczysc(h._opcje_transportu)
	h._opcje_transportu.add_child(h._ui._napis_ekranu(nazwa, 18))
	var skad = h._stan._id_miejsca_pobytu()
	var dyst: Variant = h._mapa_miast.dystans_km(h._mapa_graf, skad, id)
	var dyst_txt := "—"
	if h._ui._jest_liczba(dyst):
		dyst_txt = "%.0f km (propozycja)" % float(dyst)
	h._opcje_transportu.add_child(h._ui._napis_ekranu("Dystans: %s" % dyst_txt, 14))
	var cena_publiczna: Variant = _cena_transportu_miasta(id)
	var cena_txt := "—"
	var pieniadze := "—"
	if h._ui._jest_liczba(cena_publiczna):
		cena_txt = str(cena_publiczna)
		pieniadze = "w dół"
	h._opcje_transportu.add_child(_blok_drogi("Pieszo", "w górę", "—", "—", []))
	h._opcje_transportu.add_child(_blok_drogi("Transport publiczny", "w górę", pieniadze, cena_txt, []))
	var auto: Variant = _auto_z_zapisu()
	if auto != null and h._ui._jest_liczba(dyst):
		h._opcje_transportu.add_child(_panel_przejazdu_autem(auto, float(dyst), nazwa))
	elif auto != null:
		h._opcje_transportu.add_child(h._ui._napis_ekranu("Auto: brak dystansu do wyliczenia.", 14))


func _blok_drogi(nazwa: String, zmeczenie: String, pieniadze: String, cena: String, klasy: Array) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 2)
	kolumna.add_child(h._ui._napis_ekranu(nazwa, 18))
	kolumna.add_child(h._ui._napis_ekranu("Zmęczenie: %s" % zmeczenie, 16))
	kolumna.add_child(h._ui._napis_ekranu("Pieniądze: %s" % pieniadze, 16))
	kolumna.add_child(h._ui._napis_ekranu("Cena: %s" % cena, 16))
	if not klasy.is_empty():
		kolumna.add_child(h._ui._napis_ekranu("Klasa", 16))
		for klasa in klasy:
			var przycisk := Button.new()
			przycisk.text = str(klasa.get("nazwa", ""))
			przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
			przycisk.custom_minimum_size = Vector2(0, 44)
			przycisk.pressed.connect(h._ekran_jedzenia._wybierz_klase.bind(str(klasa.get("id", ""))))
			kolumna.add_child(przycisk)
	return kolumna


func _panel_przejazdu_autem(auto: Dictionary, dystans_km: float, cel_nazwa: String) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 6)
	kolumna.add_child(h._ui._napis_ekranu("Auto → %s" % cel_nazwa, 18))
	var vmax_v: Variant = h._przejazd.predkosc_max_auta(auto)
	if vmax_v == null:
		kolumna.add_child(h._ui._napis_ekranu("Vmax: brak danych / auto nie jeździ.", 13))
		return kolumna
	var vmax := int(vmax_v)
	var vmax_txt = h._rynek_zakupow.tekst_vmax_oferty(
		auto,
		auto.get("usterki_rzeczywiste", []) if auto.get("usterki_rzeczywiste") is Array else []
	)
	if vmax_txt == "":
		vmax_txt = str(vmax)
	kolumna.add_child(h._ui._napis_ekranu("Vmax pojazdu: %s km/h" % vmax_txt, 13))
	var tryb_stan := {"id": h.SkryptPrzejazdu.TRYB_DOZWOLONA, "nadmiar": 0.0}
	var opis = h._ui._napis_ekranu("", 14)
	var suwak_box := VBoxContainer.new()
	suwak_box.visible = false
	var nad_opis = h._ui._napis_ekranu("Ponad dozwolone: 0 km/h", 13)
	var suwak := HSlider.new()
	suwak.min_value = 0
	suwak.max_value = maxf(0.0, float(vmax) - float(h.SkryptPrzejazdu.LIMIT_DOZWOLONY_KM_H))
	suwak.step = 1
	suwak.value = 0
	suwak.custom_minimum_size = Vector2(0, 32)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var odswiez := func() -> void:
		var wynik: Dictionary = h._przejazd.oblicz(
			dystans_km, auto, str(tryb_stan["id"]), float(tryb_stan["nadmiar"]), _cena_paliwa(auto)
		)
		var jedn_sp := str(auto.get("spalanie_jednostka", "l/100 km"))
		if jedn_sp == "":
			jedn_sp = "l/100 km"
		var linie := "Koszt paliwa: %s · zużycie trybu: %s %s · zmęczenie fiz. +%d" % [
			str(wynik.get("koszt_tekst", "—")),
			str(wynik.get("zuzycie_l_na_100", "—")),
			jedn_sp,
			int(wynik.get("zmeczenie_fizyczne_delta", 0)),
		]
		var mandat := str(wynik.get("mandat_stub", "")).strip_edges()
		if mandat != "":
			linie += "\n" + mandat
		opis.text = linie
	suwak.value_changed.connect(func(v: float) -> void:
		tryb_stan["nadmiar"] = v
		nad_opis.text = "Ponad dozwolone: %d km/h" % int(v)
		odswiez.call()
	)
	suwak_box.add_child(nad_opis)
	suwak_box.add_child(suwak)
	for pozycja in [
		[h.SkryptPrzejazdu.TRYB_EKONOMICZNY, "Ekonomiczna"],
		[h.SkryptPrzejazdu.TRYB_DOZWOLONA, "Maksymalna dozwolona"],
		[h.SkryptPrzejazdu.TRYB_PRZEKROCZONA, "Przekroczona"],
	]:
		var b := Button.new()
		b.text = str(pozycja[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(func() -> void:
			tryb_stan["id"] = str(pozycja[0])
			suwak_box.visible = (str(pozycja[0]) == h.SkryptPrzejazdu.TRYB_PRZEKROCZONA)
			if not suwak_box.visible:
				tryb_stan["nadmiar"] = 0.0
				suwak.value = 0
			odswiez.call()
		)
		kolumna.add_child(b)
	kolumna.add_child(suwak_box)
	kolumna.add_child(opis)
	odswiez.call()
	return kolumna


func _ustaw_dni_auta(dzien: int) -> void:
	h._swiat["dni_auta"] = clampi(dzien, 0, 7)
	h._zaplanuj_stos()


func _auto_z_zapisu() -> Variant:
	var auto: Variant = h._swiat.get("auto", null)
	if auto is Dictionary and _auto_jest(auto) and not bool(auto.get("nie_jezdzi", false)):
		return auto
	var posiadane: Variant = h._stan._bohater().get("posiadane", {})
	if posiadane is Dictionary:
		var pojazdy: Variant = posiadane.get("pojazdy", {})
		if pojazdy is Dictionary and pojazdy.get("samochody") is Array:
			for wpis in pojazdy["samochody"]:
				if wpis is Dictionary and _auto_jest(wpis) and not bool(wpis.get("nie_jezdzi", false)):
					return wpis
	var maj: Variant = h._swiat.get("majatek", {})
	if maj is Dictionary and maj.get("dobra") is Array:
		for wpis2 in maj["dobra"]:
			if wpis2 is Dictionary and str(wpis2.get("kategoria", "")) == "samochod" \
					and _auto_jest(wpis2) and not bool(wpis2.get("nie_jezdzi", false)):
				return wpis2
	return null


func _panel_awarii_auta(idx: int, auto: Dictionary) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 6)
	var kot: Dictionary = h._rynek_zakupow.kotwica_naprawy_silnika(auto)
	kolumna.add_child(h._ui._napis_ekranu(
		"Awaria silnika — stub: Laweta ~%d zł · Mechanik ~%d zł · Złom +~%d zł (propozycja)." % [
			int(kot.get("laweta_zl", 0)),
			int(kot.get("mechanik_zl", 0)),
			int(kot.get("zlom_zl", 0)),
		],
		13
	))
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 8)
	var b_law := Button.new()
	b_law.text = "Laweta"
	b_law.custom_minimum_size = Vector2(0, 40)
	b_law.pressed.connect(func() -> void:
		var w: Dictionary = h._rynek_zakupow.laweta_auta(h._swiat, idx)
		h._ekran_zakupow._pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
		if bool(w.get("ok", false)):
			h.SkryptZapisu.zapisz(h._swiat)
			h._stan._zsynchronizuj_pieniadze_z_bohatera()
			h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	var b_mech := Button.new()
	b_mech.text = "Mechanik"
	b_mech.custom_minimum_size = Vector2(0, 40)
	b_mech.pressed.connect(func() -> void:
		var w2: Dictionary = h._rynek_zakupow.mechanik_auta(h._swiat, idx)
		h._ekran_zakupow._pokaz_komunikat_zakupu(str(w2.get("tekst", w2.get("powod", ""))), w2)
		if bool(w2.get("ok", false)):
			h.SkryptZapisu.zapisz(h._swiat)
			h._stan._zsynchronizuj_pieniadze_z_bohatera()
			h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	var b_zlom := Button.new()
	b_zlom.text = "Złom"
	b_zlom.custom_minimum_size = Vector2(0, 40)
	b_zlom.pressed.connect(func() -> void:
		var w3: Dictionary = h._rynek_zakupow.zlom_auta(h._swiat, idx)
		h._ekran_zakupow._pokaz_komunikat_zakupu(str(w3.get("tekst", w3.get("powod", ""))), w3)
		if bool(w3.get("ok", false)):
			h.SkryptZapisu.zapisz(h._swiat)
			h._stan._zsynchronizuj_pieniadze_z_bohatera()
			h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	rzad.add_child(b_law)
	rzad.add_child(b_mech)
	rzad.add_child(b_zlom)
	kolumna.add_child(rzad)
	return kolumna


func _auto_jest(auto: Dictionary) -> bool:
	for klucz in ["id", "marka", "model", "nazwa"]:
		if auto.get(klucz) != null and str(auto.get(klucz)) != "":
			return true
	return false


func _opis_auta(auto: Dictionary) -> String:
	var czesci: PackedStringArray = []
	for klucz in ["marka", "model", "nazwa"]:
		if auto.get(klucz) != null and str(auto.get(klucz)) != "":
			czesci.append(str(auto[klucz]))
	return " ".join(czesci)


func _cena_tygodnia_auta(auto: Dictionary) -> String:
	if h._ui._jest_liczba(auto.get("cena_tygodnia")):
		return str(auto.get("cena_tygodnia"))
	return "—"


func _cena_paliwa(auto: Dictionary = {}) -> Variant:
	return h._rynek_zakupow.cena_nosnika_dojazdu(auto)


func _cena_transportu_miasta(id: String) -> Variant:
	if id == "":
		return null
	var dane: Variant = h._ui._czytaj_json("res://świat/polska/miasta/%s.json" % id)
	if dane is Dictionary:
		return dane.get("cena_transportu_publicznego", null)
	return null


func _klasy_nadwozia() -> Array:
	var dane: Variant = h._ui._czytaj_json("res://pojazdy/nadwozia.json")
	if dane is Dictionary and dane.get("klasy") is Array:
		return dane["klasy"]
	return []
