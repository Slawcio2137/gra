extends RefCounted
class_name PasekStatystykGry

## Pasek statystyk, metryki i gest rozwinięcia.

var h


func _init(host) -> void:
	h = host




func _dopisz_komunikat_tury(txt: String) -> void:
	if txt == "":
		return
	var kom = str(h._swiat.get("komunikat_tury", ""))
	h._swiat["komunikat_tury"] = (kom + "\n" + txt).strip_edges() if kom != "" else txt


func _zbuduj_pasek_statystyk() -> void:
	var glowny: HBoxContainer = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/PasekGlowny")
	h._rozwiniete_stat = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/PasekRozwiniety")
	h._ui._wyczysc(glowny)
	h._ui._wyczysc(h._rozwiniete_stat)
	_styl_panelu_paska()
	h._rok_lbl = h._ui._napis_paska("Rok 1", 14)
	h._tydzien_lbl = h._ui._napis_paska("T0", 14)
	glowny.add_child(h._rok_lbl)
	glowny.add_child(h._tydzien_lbl)
	var zmeczenie := _blok_metryki("zmeczenie_fizyczne")
	h._zmeczenie_emoji = zmeczenie["emoji"]
	h._zmeczenie_pasek = zmeczenie["pasek"]
	h._zmeczenie_liczba = zmeczenie["liczba"]
	glowny.add_child(zmeczenie["wezel"])
	var zmeczenie_p := _blok_metryki("zmeczenie_psychiczne")
	h._zmeczenie_psych_emoji = zmeczenie_p["emoji"]
	h._zmeczenie_psych_pasek = zmeczenie_p["pasek"]
	h._zmeczenie_psych_liczba = zmeczenie_p["liczba"]
	glowny.add_child(zmeczenie_p["wezel"])
	var psychika := _blok_metryki("psychika")
	h._psychika_emoji = psychika["emoji"]
	h._psychika_pasek = psychika["pasek"]
	h._psychika_liczba = psychika["liczba"]
	glowny.add_child(psychika["wezel"])
	var pieniadze := HBoxContainer.new()
	pieniadze.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pieniadze.add_theme_constant_override("separation", 4)
	h._pieniadze_emoji = h._ui._napis_paska("👛", 20)
	h._pieniadze_lbl = h._ui._napis_paska("—", 16)
	h._pieniadze_lbl.add_theme_color_override("font_color", Color(h.ZIELONY))
	pieniadze.add_child(h._pieniadze_emoji)
	pieniadze.add_child(h._pieniadze_lbl)
	glowny.add_child(pieniadze)
	var wnetrze: VBoxContainer = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze")
	h._komunikat_tury_lbl = h.get_node_or_null(h.KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/KomunikatTury") as Label
	if h._komunikat_tury_lbl == null:
		h._komunikat_tury_lbl = Label.new()
		h._komunikat_tury_lbl.name = "KomunikatTury"
		h._komunikat_tury_lbl.visible = false
		h._komunikat_tury_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h._komunikat_tury_lbl.add_theme_font_size_override("font_size", 13)
		h._komunikat_tury_lbl.add_theme_color_override("font_color", Color(h.ZIELONY))
		# Pod głównym rzędem paska, nad rozwinięciem.
		wnetrze.add_child(h._komunikat_tury_lbl)
		wnetrze.move_child(h._komunikat_tury_lbl, 1)


## Treść tury idzie na biały obszar — zielonego paska u góry nie pokazujemy.
func _ukryj_zielony_komunikat_tury() -> void:
	if h._komunikat_tury_lbl == null:
		return
	h._komunikat_tury_lbl.text = ""
	h._komunikat_tury_lbl.visible = false


func _pokaz_komunikat_tury_ui() -> void:
	# Zachowane API: dawniej zielony pasek; teraz tylko ukrycie (treść w białym).
	_ukryj_zielony_komunikat_tury()


func _blok_metryki(_id: String) -> Dictionary:
	var rzad := HBoxContainer.new()
	rzad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rzad.add_theme_constant_override("separation", 3)
	var emoji = h._ui._napis_paska("🙂", 18)
	var stos := Control.new()
	stos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stos.custom_minimum_size = Vector2(48, 22)
	var pasek := ProgressBar.new()
	pasek.set_anchors_preset(Control.PRESET_FULL_RECT)
	pasek.min_value = 0
	pasek.max_value = 100
	pasek.value = 0
	pasek.show_percentage = false
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var liczba := Label.new()
	liczba.set_anchors_preset(Control.PRESET_FULL_RECT)
	liczba.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	liczba.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	liczba.add_theme_font_size_override("font_size", 12)
	liczba.add_theme_color_override("font_color", Color.WHITE)
	liczba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stos.add_child(pasek)
	stos.add_child(liczba)
	rzad.add_child(emoji)
	rzad.add_child(stos)
	return {"wezel": rzad, "emoji": emoji, "pasek": pasek, "liczba": liczba}


func _styl_panelu_paska() -> void:
	var panel: PanelContainer = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk")
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(0.18, 0.24, 0.28, 0.96)
	styl.corner_radius_top_left = 10
	styl.corner_radius_top_right = 10
	styl.corner_radius_bottom_left = 10
	styl.corner_radius_bottom_right = 10
	styl.content_margin_left = 8
	styl.content_margin_right = 8
	styl.content_margin_top = 8
	styl.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", styl)


func _podlacz_pasek_gest() -> void:
	var uchwyt: ColorRect = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/UchwytPaska")
	uchwyt.gui_input.connect(_on_pasek_input)
	var panel: PanelContainer = h.get_node(h.KOLUMNA_GRY + "/PasekStatystyk")
	panel.gui_input.connect(_on_pasek_input)


func _on_pasek_input(zdarzenie: InputEvent) -> void:
	if zdarzenie is InputEventMouseButton:
		var mysz := zdarzenie as InputEventMouseButton
		if mysz.button_index == MOUSE_BUTTON_LEFT:
			if mysz.pressed:
				h._pasek_ciagnie = true
				h._pasek_start_y = mysz.global_position.y
			else:
				h._pasek_ciagnie = false
	elif zdarzenie is InputEventMouseMotion and h._pasek_ciagnie:
		var ruch: InputEventMouseMotion = zdarzenie
		var delta = ruch.global_position.y - h._pasek_start_y
		if delta > 28.0 and not h._pasek_rozwiniety:
			_ustaw_pasek_rozwiniety(true)
		elif delta < -28.0 and h._pasek_rozwiniety:
			_ustaw_pasek_rozwiniety(false)


func _ustaw_pasek_rozwiniety(wlacz: bool) -> void:
	h._pasek_rozwiniety = wlacz
	h._rozwiniete_stat.visible = wlacz
	if wlacz:
		_wypelnij_rozwiniete_stat()


func _wypelnij_rozwiniete_stat() -> void:
	h._ui._wyczysc(h._rozwiniete_stat)
	_wypelnij_statystyki_ilosciowe(h._rozwiniete_stat, true)


func _wypelnij_statystyki_ilosciowe(cel: VBoxContainer, kompakt: bool = false) -> void:
	var bohater = h._stan._bohater()
	var rozmiar := 13 if kompakt else 15
	cel.add_child(h._ui._napis_ekranu_lub_paska("Zdrowie: %s" % h._ui._tekst_lub_pauza(bohater.get("zdrowie_skrot"), bohater.get("zdrowie")), rozmiar, kompakt))
	cel.add_child(h._ui._napis_ekranu_lub_paska("Wygląd: %s" % h._ui._tekst_lub_pauza(h._ui._nazwa_pola(bohater.get("wyglad_naturalny"))), rozmiar, kompakt))
	var sila = h._ui._tekst_liczby(bohater.get("sila"))
	var kondycja = h._ui._tekst_liczby(bohater.get("kondycja"))
	if sila != "" or kondycja != "":
		cel.add_child(h._ui._napis_ekranu_lub_paska("Siła: %s   Kondycja: %s" % [
			sila if sila != "" else "—",
			kondycja if kondycja != "" else "—"
		], rozmiar, kompakt))
	elif h._ui._tekst_liczby(bohater.get("wytrzymalosc")) != "":
		cel.add_child(h._ui._napis_ekranu_lub_paska("Wytrzymałość: %s" % h._ui._tekst_liczby(bohater.get("wytrzymalosc")), rozmiar, kompakt))
	var zdrowe: Variant = h._jedzenie.odczyt_statystyk().get("zdrowe_zywienie")
	cel.add_child(h._ui._napis_ekranu_lub_paska("Zdrowe żywienie: %s" % (h._ui._tekst_liczby(zdrowe) if h._ui._jest_liczba(zdrowe) else "—"), rozmiar, kompakt))
	cel.add_child(h._ui._napis_ekranu_lub_paska("Sylwetka: %s" % h._ui._tekst_lub_pauza(h._ui._nazwa_pola(bohater.get("sylwetka"))), rozmiar, kompakt))
	# Pasek czyta psychikę. Docelowe tylko przy POKAZ_STATYSTYKI (nigdy w normalnej grze).
	if h.DostepStatystyk.POKAZ_STATYSTYKI:
		var doc = h._ui._tekst_liczby(bohater.get("zadowolenie_docelowe"))
		cel.add_child(h._ui._napis_ekranu_lub_paska("Docelowe (dev): %s" % (doc if doc != "" else "—"), rozmiar, kompakt))


func _odswiez_pasek_statystyk(animuj_pieniadze: bool) -> void:
	if h._rok_lbl == null:
		return
	var rok = int(h._swiat.get("rok", 1))
	var tydzien = int(h._swiat.get("tydzien", 0))
	h._rok_lbl.text = "Rok %d" % rok
	h._tydzien_lbl.text = "Tydzień %d" % tydzien
	var psychika: Variant = _wartosc_metryki("psychika")
	var zmeczenie: Variant = _wartosc_metryki("zmeczenie_fizyczne")
	if zmeczenie == null:
		zmeczenie = _wartosc_metryki("zmeczenie")
	var zmeczenie_p: Variant = _wartosc_metryki("zmeczenie_psychiczne")
	_ustaw_metryke(h._psychika_emoji, h._psychika_pasek, h._psychika_liczba, "psychika", psychika, false)
	_ustaw_metryke(h._zmeczenie_emoji, h._zmeczenie_pasek, h._zmeczenie_liczba, "zmeczenie_fizyczne", zmeczenie, true)
	if h._zmeczenie_psych_pasek != null:
		_ustaw_metryke(h._zmeczenie_psych_emoji, h._zmeczenie_psych_pasek, h._zmeczenie_psych_liczba, "zmeczenie_psychiczne", zmeczenie_p, true)
	_ustaw_pieniadze(animuj_pieniadze)
	if h._pasek_rozwiniety:
		_wypelnij_rozwiniete_stat()


func _wartosc_metryki(klucz: String) -> Variant:
	var bohater = h._stan._bohater()
	if h._ui._jest_liczba(bohater.get(klucz)):
		return int(bohater[klucz])
	if h._ui._jest_liczba(h._swiat.get(klucz)):
		return int(h._swiat[klucz])
	var blok: Variant = h._emotikony.get(klucz, {})
	if blok is Dictionary and h._ui._jest_liczba(blok.get("norma")):
		return int(blok["norma"])
	return null


func _ustaw_metryke(emoji: Label, pasek: ProgressBar, liczba: Label, klucz: String, wartosc: Variant, odwrotnie_kolor: bool) -> void:
	var blok: Variant = h._emotikony.get(klucz, {})
	if not (blok is Dictionary) or blok.is_empty():
		if klucz == "zmeczenie_fizyczne":
			blok = h._emotikony.get("zmeczenie", {})
		elif klucz == "zmeczenie_psychiczne":
			blok = h._emotikony.get("zmeczenie", {})
	var v := 0
	if h._ui._jest_liczba(wartosc):
		v = clampi(int(wartosc), 0, 100)
	emoji.text = _emoji_z_progow(blok, v if h._ui._jest_liczba(wartosc) else null)
	pasek.value = float(v)
	liczba.text = str(v) if h._ui._jest_liczba(wartosc) else "—"
	var kolor_hex := _kolor_z_progow(blok, v)
	var styl := StyleBoxFlat.new()
	styl.bg_color = h._ui._kolor(kolor_hex)
	styl.corner_radius_top_left = 4
	styl.corner_radius_top_right = 4
	styl.corner_radius_bottom_left = 4
	styl.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("fill", styl)
	var tlo := StyleBoxFlat.new()
	tlo.bg_color = Color(0.12, 0.14, 0.16, 1)
	tlo.corner_radius_top_left = 4
	tlo.corner_radius_top_right = 4
	tlo.corner_radius_bottom_left = 4
	tlo.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("background", tlo)
	if odwrotnie_kolor:
		pass


func _emoji_z_progow(blok: Variant, wartosc: Variant) -> String:
	if not (blok is Dictionary):
		return "•"
	if wartosc == null and blok.has("null_emoji"):
		return str(blok.get("null_emoji"))
	var lista: Variant = blok.get("emotikony", blok.get("progi", []))
	if not (lista is Array) or not h._ui._jest_liczba(wartosc):
		return str(blok.get("null_emoji", "•"))
	var v := int(wartosc)
	for wpis in lista:
		if not (wpis is Dictionary):
			continue
		var prog: Variant = wpis.get("do")
		if prog == null:
			return str(wpis.get("emoji", "•"))
		if h._ui._jest_liczba(prog) and v <= int(prog):
			return str(wpis.get("emoji", "•"))
	return "•"


func _kolor_z_progow(blok: Variant, wartosc: int) -> String:
	if not (blok is Dictionary):
		return "#888888"
	var lista: Variant = blok.get("kolory_paska", [])
	if not (lista is Array):
		return "#888888"
	for wpis in lista:
		if wpis is Dictionary and h._ui._jest_liczba(wpis.get("do")) and wartosc <= int(wpis["do"]):
			return str(wpis.get("kolor", "#888888"))
	return "#888888"


func _ustaw_pieniadze(animuj: bool) -> void:
	var kwota: Variant = null
	var stan = h._jedzenie.odczyt_statystyk()
	if h._ui._jest_liczba(stan.get("pieniadze")):
		kwota = int(stan["pieniadze"])
	elif h._ui._jest_liczba(h._stan._bohater().get("pieniadze")):
		kwota = int(h._stan._bohater()["pieniadze"])
	var blok: Variant = h._emotikony.get("pieniadze", {})
	if kwota == null:
		h._pieniadze_znane_pokaz = false
		h._pieniadze_emoji.text = str(blok.get("null_emoji", "👛")) if blok is Dictionary else "👛"
		h._pieniadze_lbl.text = str(blok.get("null_tekst", "—")) if blok is Dictionary else "—"
		return
	h._pieniadze_emoji.text = _emoji_portfela(int(kwota), blok)
	if not animuj or not h._pieniadze_znane_pokaz:
		h._pieniadze_pokazane = float(kwota)
		h._pieniadze_lbl.text = str(int(kwota))
		h._pieniadze_znane_pokaz = true
		return
	if h._pieniadze_tween != null and is_instance_valid(h._pieniadze_tween):
		h._pieniadze_tween.kill()
	h._pieniadze_tween = h.create_tween()
	h._pieniadze_tween.tween_method(_ustaw_tekst_pieniedzy, h._pieniadze_pokazane, float(kwota), 0.55)


func _ustaw_tekst_pieniedzy(wartosc: float) -> void:
	h._pieniadze_pokazane = wartosc
	h._pieniadze_lbl.text = str(int(round(wartosc)))


func _emoji_portfela(kwota: int, blok: Variant) -> String:
	if not (blok is Dictionary):
		return "👛"
	var progi: Variant = blok.get("progi", [])
	if not (progi is Array):
		return "👛"
	for wpis in progi:
		if not (wpis is Dictionary):
			continue
		var prog: Variant = wpis.get("do")
		if prog == null:
			return str(wpis.get("emoji", "🏆"))
		if h._ui._jest_liczba(prog) and kwota <= int(prog):
			return str(wpis.get("emoji", "👛"))
	return "🏆"


func _odswiez_lokalizacje() -> void:
	var napis: Label = h.get_node(h.KOLUMNA_GRY + "/Lokalizacja")
	napis.text = h._stan._opis_lokalizacji()
	napis.add_theme_color_override("font_color", Color(0.9, 0.93, 0.95))
