extends PanelContainer
class_name StatystykiPanel

## Jeden panel dla menu i dla gry. Zapis stąd czyta Start.

signal zapisano(zapis: Dictionary)

var _otwarty := false
var _pieniadze: LineEdit
var _cena_wlacz: CheckButton
var _cena: HSlider
var _cena_napis: Label
var _skladniki_wlacz: CheckButton
var _skladniki: HSlider
var _skladniki_napis: Label
var _wege: CheckButton
var _weganie: CheckButton
var _zadowolenie: LineEdit
var _charakter: OptionButton
var _charakter_napis: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var kolumna := VBoxContainer.new()
	kolumna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kolumna.add_theme_constant_override("separation", 8)
	scroll.add_child(kolumna)
	kolumna.add_child(_napis("Statystyki", 28))
	kolumna.add_child(_napis("Zapis z tego panelu gra czyta po Start. Puste pieniądze zostają nieustawione.", 16))
	kolumna.add_child(_napis("Pieniądze bohatera (zł)", 18))
	_pieniadze = LineEdit.new()
	_pieniadze.placeholder_text = "nieustawione"
	_pieniadze.custom_minimum_size = Vector2(0, 36)
	kolumna.add_child(_pieniadze)
	_cena_wlacz = CheckButton.new()
	_cena_wlacz.text = "Ustaw suwak ceny"
	_cena_wlacz.toggled.connect(_on_cena_wlacz)
	kolumna.add_child(_cena_wlacz)
	_cena = HSlider.new()
	_cena.custom_minimum_size = Vector2(0, 28)
	_cena.step = 1.0
	_cena.editable = false
	_cena.value_changed.connect(_on_cena)
	kolumna.add_child(_cena)
	_cena_napis = _napis("Cena: nieustawiona", 16)
	kolumna.add_child(_cena_napis)
	_skladniki_wlacz = CheckButton.new()
	_skladniki_wlacz.text = "Ustaw suwak składników odżywczych"
	_skladniki_wlacz.toggled.connect(_on_skladniki_wlacz)
	kolumna.add_child(_skladniki_wlacz)
	_skladniki = HSlider.new()
	_skladniki.custom_minimum_size = Vector2(0, 28)
	_skladniki.step = 1.0
	_skladniki.editable = false
	_skladniki.value_changed.connect(_on_skladniki)
	kolumna.add_child(_skladniki)
	_skladniki_napis = _napis("Składniki odżywcze: nieustawione", 16)
	kolumna.add_child(_skladniki_napis)
	_wege = CheckButton.new()
	_wege.text = "Dieta wegetariańska"
	_wege.toggled.connect(_on_wege)
	kolumna.add_child(_wege)
	_weganie = CheckButton.new()
	_weganie.text = "Dieta wegańska"
	_weganie.toggled.connect(_on_weganie)
	kolumna.add_child(_weganie)
	kolumna.add_child(_napis("Zadowolenie rodziców", 18))
	kolumna.add_child(_napis("To już zbite zmiany jedzenia. Osobnej liczby w danych nie ma. Puste pole nie wpisuje nowej.", 16))
	_zadowolenie = LineEdit.new()
	_zadowolenie.placeholder_text = "puste"
	_zadowolenie.custom_minimum_size = Vector2(0, 36)
	kolumna.add_child(_zadowolenie)
	kolumna.add_child(_napis("Charakter rodzica", 18))
	_charakter_napis = _napis("W danych rodziny lista cech jest pusta.", 16)
	kolumna.add_child(_charakter_napis)
	_charakter = OptionButton.new()
	_charakter.custom_minimum_size = Vector2(0, 36)
	kolumna.add_child(_charakter)
	var zapisz := Button.new()
	zapisz.text = "Zapisz"
	zapisz.custom_minimum_size = Vector2(0, 40)
	zapisz.add_theme_font_size_override("font_size", 20)
	zapisz.pressed.connect(_on_zapisz)
	kolumna.add_child(zapisz)
	var zamknij := Button.new()
	zamknij.text = "Zamknij"
	zamknij.custom_minimum_size = Vector2(0, 40)
	zamknij.add_theme_font_size_override("font_size", 20)
	zamknij.pressed.connect(_on_zamknij)
	kolumna.add_child(zamknij)


func byl_otwarty() -> bool:
	return _otwarty


func oznacz_otwarty() -> void:
	_otwarty = true


func wczytaj_z_gry(jedzenie: JedzenieUstawienia) -> void:
	var stan := jedzenie.odczyt_statystyk()
	var cena := jedzenie.zakres_suwaka("cena")
	var skladniki := jedzenie.zakres_suwaka("skladniki")
	_cena.min_value = float(cena.get("min", 0))
	_cena.max_value = float(cena.get("max", 100))
	_skladniki.min_value = float(skladniki.get("min", 0))
	_skladniki.max_value = float(skladniki.get("max", 100))
	if stan.get("pieniadze") == null:
		_pieniadze.text = ""
	else:
		_pieniadze.text = str(int(stan["pieniadze"]))
	var cena_jest := bool(stan.get("cena_ustawiona", false)) and _jest_liczba(stan.get("cena"))
	_cena_wlacz.set_pressed_no_signal(cena_jest)
	_cena.editable = cena_jest
	if cena_jest:
		_cena.set_value_no_signal(float(stan["cena"]))
	_odswiez_cene()
	var sklad_jest := bool(stan.get("skladniki_ustawione", false)) and _jest_liczba(stan.get("skladniki"))
	_skladniki_wlacz.set_pressed_no_signal(sklad_jest)
	_skladniki.editable = sklad_jest
	if sklad_jest:
		_skladniki.set_value_no_signal(float(stan["skladniki"]))
	_odswiez_skladniki()
	_weganie.set_pressed_no_signal(bool(stan.get("weganska", false)))
	_wege.set_pressed_no_signal(bool(stan.get("wegetarianska", false)) and not _weganie.button_pressed)
	if _jest_liczba(stan.get("zadowolenie_rodzicow")):
		_zadowolenie.text = str(int(stan["zadowolenie_rodzicow"]))
	else:
		_zadowolenie.text = ""
	_wypelnij_charakter(jedzenie, stan.get("cechy_rodzicow", []))


func oddaj_zapis() -> Dictionary:
	var pieniadze: Variant = null
	var tekst := _pieniadze.text.strip_edges()
	if tekst.is_valid_int():
		pieniadze = maxi(int(tekst), 0)
	var zadowolenie: Variant = null
	var zbite := _zadowolenie.text.strip_edges()
	if zbite.is_valid_int():
		zadowolenie = int(zbite)
	var cecha := ""
	if _charakter.selected > 0:
		cecha = str(_charakter.get_item_metadata(_charakter.selected))
	return {
		"pieniadze": pieniadze,
		"cena_ustawiona": _cena_wlacz.button_pressed,
		"cena": int(_cena.value) if _cena_wlacz.button_pressed else null,
		"skladniki_ustawione": _skladniki_wlacz.button_pressed,
		"skladniki": int(_skladniki.value) if _skladniki_wlacz.button_pressed else null,
		"wegetarianska": _wege.button_pressed and not _weganie.button_pressed,
		"weganska": _weganie.button_pressed,
		"zadowolenie_rodzicow": zadowolenie,
		"cecha_rodzica": cecha,
	}


func _on_zapisz() -> void:
	zapisano.emit(oddaj_zapis())


func _on_zamknij() -> void:
	hide()


func _on_cena_wlacz(wlaczona: bool) -> void:
	_cena.editable = wlaczona
	_odswiez_cene()


func _on_skladniki_wlacz(wlaczona: bool) -> void:
	_skladniki.editable = wlaczona
	_odswiez_skladniki()


func _on_cena(_wartosc: float) -> void:
	_odswiez_cene()


func _on_skladniki(_wartosc: float) -> void:
	_odswiez_skladniki()


func _on_wege(wlaczona: bool) -> void:
	if wlaczona and _weganie.button_pressed:
		_weganie.set_pressed_no_signal(false)


func _on_weganie(wlaczona: bool) -> void:
	if wlaczona and _wege.button_pressed:
		_wege.set_pressed_no_signal(false)


func _odswiez_cene() -> void:
	if _cena_wlacz.button_pressed:
		_cena_napis.text = "Cena: %d (koniec suwaka, nie złotówki)" % int(_cena.value)
	else:
		_cena_napis.text = "Cena: nieustawiona"


func _odswiez_skladniki() -> void:
	if _skladniki_wlacz.button_pressed:
		_skladniki_napis.text = "Składniki odżywcze: %d" % int(_skladniki.value)
	else:
		_skladniki_napis.text = "Składniki odżywcze: nieustawione"


func _wypelnij_charakter(jedzenie: JedzenieUstawienia, cechy: Variant) -> void:
	_charakter.clear()
	_charakter.add_item("nieustawione")
	_charakter.set_item_metadata(0, "")
	var indeks := 1
	var wybrane := 0
	var ids: Array = []
	if cechy is Array:
		for pozycja in cechy:
			ids.append(str(pozycja))
	for cecha in jedzenie.cechy_charakteru_dostepne():
		if not (cecha is Dictionary):
			continue
		var id := str(cecha.get("id", ""))
		if id == "":
			continue
		_charakter.add_item(str(cecha.get("nazwa", id)))
		_charakter.set_item_metadata(indeks, id)
		if wybrane == 0 and ids.has(id):
			wybrane = indeks
		indeks += 1
	_charakter.select(wybrane)
	if ids.is_empty():
		_charakter_napis.text = "W danych rodziny lista cech jest pusta. Możesz wybrać cechę, która już jest w tabeli spadku."
	else:
		_charakter_napis.text = "W danych rodziny: %s." % ", ".join(ids)


func _napis(tekst: String, rozmiar: int) -> Label:
	var napis := Label.new()
	napis.text = tekst
	napis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	napis.add_theme_font_size_override("font_size", rozmiar)
	return napis


func _jest_liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float
