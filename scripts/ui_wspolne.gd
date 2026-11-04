extends RefCounted
class_name UiWspolne

## Wspólne helpery UI, formatowanie tekstu i ustawienia wyglądu. Stan gry jest na hoście (h).

var h


func _init(host) -> void:
	h = host




func _wczytaj_emotikony() -> void:
	h._emotikony = {}
	var dane: Variant = _czytaj_json(h.PLIK_EMOTIKONOW)
	if dane is Dictionary:
		h._emotikony = dane


func _ekran_ustawienia_w_bialym() -> void:
	_tresc_biala().add_child(_napis_ekranu("Otwiera panel wyglądu (przejrzystość, kolory). Podział poziomy 8:5 usunięty.", 15))
	var przycisk := Button.new()
	przycisk.text = "Otwórz ustawienia wyglądu"
	przycisk.custom_minimum_size = Vector2(0, 48)
	przycisk.pressed.connect(h._on_ustawienia_pressed)
	_tresc_biala().add_child(przycisk)


func _kropki_dni(wybrane: int, cel: Callable) -> Control:
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 2)
	for dzien in 8:
		var kolumna := VBoxContainer.new()
		kolumna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kolumna.add_theme_constant_override("separation", 0)
		var liczba := Button.new()
		liczba.text = str(dzien)
		liczba.flat = true
		liczba.focus_mode = Control.FOCUS_NONE
		liczba.custom_minimum_size = Vector2(0, 48)
		liczba.add_theme_color_override("font_color", h.TEKST_CIEMNY)
		liczba.pressed.connect(cel.bind(dzien))
		var kropka := TextureRect.new()
		kropka.custom_minimum_size = Vector2(0, 22)
		kropka.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		kropka.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		kropka.texture = h._kropka_duza if dzien == wybrane else h._kropka_mala
		kropka.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		kropka.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kolumna.add_child(liczba)
		kolumna.add_child(kropka)
		rzad.add_child(kolumna)
	return rzad


func _ramka_suwaka(tytul: String, kolor: Color, suwak: Control) -> Control:
	var margines := MarginContainer.new()
	margines.add_theme_constant_override("margin_left", 10)
	margines.add_theme_constant_override("margin_right", 10)
	margines.add_theme_constant_override("margin_top", 8)
	margines.add_theme_constant_override("margin_bottom", 8)
	margines.add_child(suwak)
	return _ramka_z_dolnym(tytul, kolor, null, margines)


func _ramka_z_dolnym(tytul: String, kolor: Color, srodek: Control, dol: Control) -> Control:
	var panel := PanelContainer.new()
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(0.93, 0.94, 0.95, 1)
	styl.content_margin_left = 0
	styl.content_margin_right = 0
	styl.content_margin_top = 0
	styl.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", styl)
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 8)
	var pasek := ColorRect.new()
	pasek.color = kolor
	pasek.custom_minimum_size = Vector2(0, 36)
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var napis := Label.new()
	napis.text = tytul
	napis.set_anchors_preset(Control.PRESET_FULL_RECT)
	napis.offset_left = 12.0
	napis.offset_right = -12.0
	napis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	napis.add_theme_font_size_override("font_size", 16)
	napis.add_theme_color_override("font_color", _kolor_napisu_na(kolor))
	napis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek.add_child(napis)
	kolumna.add_child(pasek)
	if srodek != null:
		var wciecie := MarginContainer.new()
		wciecie.add_theme_constant_override("margin_left", 10)
		wciecie.add_theme_constant_override("margin_right", 10)
		wciecie.add_child(srodek)
		kolumna.add_child(wciecie)
	if dol != null:
		kolumna.add_child(dol)
	panel.add_child(kolumna)
	return panel


func _napis_ekranu_lub_paska(tekst: String, rozmiar: int, na_pasku: bool) -> Label:
	if na_pasku:
		return _napis_paska(tekst, rozmiar)
	return _napis_ekranu(tekst, rozmiar)


func _styl_bialego_ekranu() -> void:
	var panel: PanelContainer = h.get_node(h.KOLUMNA_GRY + "/BialyEkran")
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(1, 1, 1, 1)
	styl.corner_radius_top_left = 12
	styl.corner_radius_top_right = 12
	styl.corner_radius_bottom_left = 12
	styl.corner_radius_bottom_right = 12
	styl.content_margin_left = 0
	styl.content_margin_right = 0
	styl.content_margin_top = 0
	styl.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", styl)


func _linia_albo_pusto(tekst: String) -> void:
	if tekst != "":
		_tresc_biala().add_child(_napis_ekranu(tekst, 20))
	else:
		_tresc_biala().add_child(_napis_ekranu("—", 18))


func _tekst_ceny(cena: Variant) -> String:
	if _jest_liczba(cena):
		return "%s zł" % str(cena)
	return "—"


func _tekst_ceny_oferty(cena: Variant, kat_id: String = "") -> String:
	if kat_id == "samochod":
		return h._rynek_zakupow.formatuj_cene_auta(cena)
	return _tekst_ceny(cena)


func _tekst_przebiegu_zakresu(etykieta: String, km: float) -> String:
	return "%s: %s km" % [etykieta, _tekst_z_odstepami(int(km))]


## Spacje co 3 cyfry, jak cena auta. Nie zaokrągla — 376497 zostaje 376 497.
func _tekst_z_odstepami(n: int) -> String:
	var ujemna := n < 0
	var s := str(absi(n))
	var out := ""
	var licznik := 0
	for i in range(s.length() - 1, -1, -1):
		if licznik > 0 and licznik % 3 == 0:
			out = " " + out
		out = s[i] + out
		licznik += 1
	if ujemna:
		out = "-" + out
	return out


func _join_tekstow(lista: Array) -> String:
	var parts: PackedStringArray = []
	for x in lista:
		parts.append(str(x))
	return ", ".join(parts)


func _nazwa_pola(pozycja: Variant) -> String:
	if pozycja is Dictionary:
		return str(pozycja.get("nazwa", ""))
	return ""


func _tekst_pusty(wartosc: Variant) -> String:
	if wartosc == null:
		return ""
	return str(wartosc)


func _tekst_lub_pauza(a: Variant = null, b: Variant = null) -> String:
	var t := _tekst_pusty(a)
	if t != "":
		return t
	t = _tekst_pusty(b)
	if t != "":
		return t
	return "—"


func _tekst_liczby(wartosc: Variant) -> String:
	if _jest_liczba(wartosc):
		return str(int(wartosc))
	return ""


func _zbuduj_statystyki_menu() -> void:
	var w_menu := h.get_node("MenuEkran/StatystykiButton") as Button
	if not h.DostepStatystyk.POKAZ_STATYSTYKI:
		w_menu.hide()
		return
	if not w_menu.pressed.is_connected(_on_statystyki_pressed):
		w_menu.pressed.connect(_on_statystyki_pressed)
	var panel = h.get_node_or_null("PanelStatystyk")
	if panel != null:
		return
	panel = h.PanelStatystykSkrypt.new()
	panel.name = "PanelStatystyk"
	panel.visible = false
	panel.z_index = 30
	panel.zapisano.connect(_on_statystyki_zapisane)
	h.add_child(panel)


func _on_statystyki_pressed() -> void:
	var panel = h.get_node_or_null("PanelStatystyk")
	if panel == null:
		return
	if panel.visible:
		panel.hide()
		return
	panel.wczytaj_z_gry(h._jedzenie)
	panel.oznacz_otwarty()
	panel.show()
	panel.move_to_front()
	h.get_node("Powrot").show()
	_na_wierzch_przyciski()


func _on_statystyki_zapisane(zapis: Dictionary) -> void:
	h._jedzenie.zastosuj_statystyki(zapis)
	h._pasek._odswiez_pasek_statystyk(true)


func _zastosuj_wyglad() -> void:
	h.theme = WygladGracza.temat(h._wyglad)
	_styl_bialego_ekranu()
	h._pasek._styl_panelu_paska()


func _podlacz_ustawienia() -> void:
	h._cisza_ustawien = true
	var kolumna: Node = h.get_node(h.KOLUMNA_USTAWIEN)
	for i in [1, 2, 3]:
		var przycisk := kolumna.get_node("Szerokosc%d" % i) as Button
		przycisk.visible = false
	var opis: Label = kolumna.get_node("SzerokoscOpis")
	opis.visible = false
	var proporcje: Label = kolumna.get_node("Proporcje")
	proporcje.text = "Ekran pionowy (telefon). Stary podział 8:5 usunięty."
	_ustaw_suwak_alpha(kolumna, "PanelAlpha", "PanelAlphaOpis", "Przejrzystość panelu", "alpha_panelu")
	_ustaw_suwak_alpha(kolumna, "PrzyciskiAlpha", "PrzyciskiAlphaOpis", "Przejrzystość przycisków", "alpha_przyciskow")
	_ustaw_suwak_alpha(kolumna, "NapisyAlpha", "NapisyAlphaOpis", "Przejrzystość napisów", "alpha_napisow")
	var napisy := kolumna.get_node("KolorNapisow") as ColorPickerButton
	napisy.edit_alpha = false
	napisy.color = h._wyglad.get("kolor_napisow", Color.WHITE)
	if not napisy.color_changed.is_connected(_on_kolor_napisow):
		napisy.color_changed.connect(_on_kolor_napisow)
	var tlo := kolumna.get_node("KolorTla") as ColorPickerButton
	tlo.edit_alpha = false
	tlo.color = h._wyglad.get("kolor_tla", Color(0.45, 0.45, 0.48))
	if not tlo.color_changed.is_connected(_on_kolor_tla):
		tlo.color_changed.connect(_on_kolor_tla)
	h._cisza_ustawien = false


func _ustaw_suwak_alpha(kolumna: Node, suwak_nazwa: String, opis_nazwa: String, tytul: String, klucz: String) -> void:
	var suwak := kolumna.get_node(suwak_nazwa) as HSlider
	suwak.min_value = 0.0
	suwak.max_value = 1.0
	suwak.step = 0.05
	var start = float(h._wyglad.get(klucz, 1.0))
	suwak.set_value_no_signal(start)
	var opis := kolumna.get_node(opis_nazwa) as Label
	opis.text = WygladGracza.napis_przejrzystosci(tytul, start)
	if not suwak.value_changed.is_connected(_on_alpha):
		suwak.value_changed.connect(_on_alpha.bind(klucz, opis, tytul))


func _on_alpha(wartosc: float, klucz: String, opis: Label, tytul: String) -> void:
	if h._cisza_ustawien:
		return
	h._wyglad[klucz] = wartosc
	opis.text = WygladGracza.napis_przejrzystosci(tytul, wartosc)
	_zapisz_wyglad()


func _on_kolor_napisow(kolor: Color) -> void:
	if h._cisza_ustawien:
		return
	kolor.a = 1.0
	h._wyglad["kolor_napisow"] = kolor
	_zapisz_wyglad()


func _on_kolor_tla(kolor: Color) -> void:
	if h._cisza_ustawien:
		return
	kolor.a = 1.0
	h._wyglad["kolor_tla"] = kolor
	_zapisz_wyglad()


func _zapisz_wyglad() -> void:
	WygladGracza.zapisz(h._wyglad)
	_zastosuj_wyglad()


func _male_przyciski() -> void:
	var pusty := StyleBoxEmpty.new()
	for sciezka in ["UstawieniaGry", "Wyjscie"]:
		var przycisk := h.get_node(sciezka) as Button
		przycisk.text = ""
		przycisk.custom_minimum_size = Vector2(56, 56)
		przycisk.expand_icon = false
		przycisk.add_theme_constant_override("icon_max_width", 28)
		for stan in ["normal", "hover", "pressed", "focus", "disabled"]:
			przycisk.add_theme_stylebox_override(stan, pusty)
	# Powrót: lewy dół, ten sam czysty styl ikony co Wyjście (bez ciemnego panelu).
	var powrot := h.get_node("Powrot") as Button
	powrot.text = ""
	powrot.custom_minimum_size = Vector2(56, 56)
	powrot.expand_icon = false
	powrot.add_theme_constant_override("icon_max_width", 28)
	for stan in ["normal", "hover", "pressed", "focus", "disabled"]:
		powrot.add_theme_stylebox_override(stan, pusty)


func _na_wierzch_przyciski() -> void:
	h.get_node("Powrot").move_to_front()
	h.get_node("Wyjscie").move_to_front()
	h.get_node("UstawieniaGry").move_to_front()


func _tresc_biala() -> VBoxContainer:
	return h.get_node(h.KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/ScrollBialy/TrescBiala")


func _tytul_bialy() -> Label:
	return h.get_node(h.KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/TytulBialy")


func _dol_suwaka() -> VBoxContainer:
	return h.get_node(h.KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/DolSuwaka")


func _wyczysc(wezel: Node) -> void:
	var dzieci := wezel.get_children()
	for dziecko in dzieci:
		wezel.remove_child(dziecko)
		dziecko.queue_free()


func _z_marginesem(wezel: Control) -> Control:
	var margines := MarginContainer.new()
	margines.add_theme_constant_override("margin_left", 8)
	margines.add_theme_constant_override("margin_right", 8)
	margines.add_theme_constant_override("margin_top", 4)
	margines.add_theme_constant_override("margin_bottom", 8)
	margines.add_child(wezel)
	return margines


func _napis_ekranu(tekst: String, rozmiar: int) -> Label:
	var napis := Label.new()
	napis.text = tekst
	napis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Czytelność na ~720 px: etykiety min ~16–18.
	napis.add_theme_font_size_override("font_size", rozmiar if rozmiar >= 16 else 16)
	napis.add_theme_color_override("font_color", h.TEKST_CIEMNY)
	return napis


func _napis_paska(tekst: String, rozmiar: int) -> Label:
	var napis := Label.new()
	napis.text = tekst
	napis.autowrap_mode = TextServer.AUTOWRAP_OFF
	napis.add_theme_font_size_override("font_size", rozmiar)
	napis.add_theme_color_override("font_color", Color(0.95, 0.96, 0.97))
	napis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return napis


func _rich_ekran() -> RichTextLabel:
	var napis := RichTextLabel.new()
	napis.bbcode_enabled = true
	napis.fit_content = true
	napis.scroll_active = false
	napis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	napis.add_theme_font_size_override("normal_font_size", 16)
	napis.add_theme_color_override("default_color", h.TEKST_CIEMNY)
	return napis


func _kolor(html: String) -> Color:
	if html.begins_with("#") and (html.length() == 7 or html.length() == 9):
		return Color(html)
	return Color("#9aa7b2")


func _kolor_napisu_na(tlo: Color) -> Color:
	var jasnosc := tlo.r * 0.3 + tlo.g * 0.59 + tlo.b * 0.11
	if jasnosc > 0.62:
		return Color("#1c2428")
	return Color.WHITE


func _czytaj_json(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())


func _jest_liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float
