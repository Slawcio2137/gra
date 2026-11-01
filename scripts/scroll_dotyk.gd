extends ScrollContainer

## Pionowy scroll palcem. Dzieci nie zjadają gestu (mouse_filter IGNORE),
## a krótkie stuknięcie nadal klika przycisk. Suwaki i pola zostają STOP.

const PROG_PX := 18.0
const KROK_KOLKA := 72
## Palec, który chwilę poleżał, nie dostaje rozpędu.
const PROG_SPOCZYNKU_MS := 90
const TARCIE := 3.4
const MIN_PREDKOSC := 30.0

var _aktywny := false
var _przeciaganie := false
var _start := Vector2.ZERO
var _scroll0 := 0
var _palec := false
var _blokuj_mysz_do := 0
var _poprzednia := Vector2.ZERO
var _poprzedni_czas := 0
var _ostatni_ruch_ms := 0
var _predkosc := 0.0
var _bezwladnosc := false


## Stuknięcie bez realnego ruchu klika. Od progu wzwyż to przeciągnięcie i puszczenie nie klika.
static func klik_przy_drodze(droga_px: float, prog_px: float = PROG_PX) -> bool:
	return droga_px < prog_px


## Rozpęd w px/s. Gdy od ostatniego ruchu minął próg spoczynku, prędkość spada do zera.
static func predkosc_po_puszczeniu(predkosc_px_s: float, ms_od_ostatniego_ruchu: int, prog_spoczynku_ms: int = PROG_SPOCZYNKU_MS) -> float:
	if ms_od_ostatniego_ruchu >= prog_spoczynku_ms:
		return 0.0
	return predkosc_px_s


func _enter_tree() -> void:
	# _ready bywa odroczone do klatki. Pasek ma być szeroki od wejścia w drzewo.
	_poszerz_pionowy_pasek()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	follow_focus = false
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	set_process(false)
	_poszerz_pionowy_pasek()
	_podlacz(self)
	for dziecko in get_children():
		_skonfiguruj_wezel(dziecko)


func _process(delta: float) -> void:
	if not _bezwladnosc:
		set_process(false)
		return
	if _aktywny:
		_zatrzymaj_bezwladnosc()
		return
	var przed := scroll_vertical
	scroll_vertical = przed + int(round(_predkosc * delta))
	_predkosc *= exp(-TARCIE * delta)
	if scroll_vertical == przed or absf(_predkosc) < MIN_PREDKOSC:
		_zatrzymaj_bezwladnosc()


func _zatrzymaj_bezwladnosc() -> void:
	_bezwladnosc = false
	_predkosc = 0.0
	set_process(false)


## Pionowy chwyt na listach (zakupy i Osoby, ten sam ScrollBialy): ok. 32 px.
## Suwak zakresu zostaje suwakiem — tu ruszamy tylko VScrollBar.
func _poszerz_pionowy_pasek() -> void:
	var pasek := get_v_scroll_bar()
	if pasek == null:
		return
	pasek.custom_minimum_size = Vector2(32, 48)
	var chwyt := StyleBoxFlat.new()
	chwyt.bg_color = Color(0.32, 0.36, 0.4, 0.95)
	chwyt.set_corner_radius_all(8)
	chwyt.content_margin_left = 10.0
	chwyt.content_margin_right = 10.0
	chwyt.content_margin_top = 16.0
	chwyt.content_margin_bottom = 16.0
	var tor := StyleBoxFlat.new()
	tor.bg_color = Color(0.75, 0.76, 0.78, 0.45)
	tor.content_margin_left = 6.0
	tor.content_margin_right = 6.0
	pasek.add_theme_stylebox_override("grabber", chwyt)
	pasek.add_theme_stylebox_override("grabber_highlight", chwyt)
	pasek.add_theme_stylebox_override("grabber_pressed", chwyt)
	pasek.add_theme_stylebox_override("scroll", tor)
	pasek.add_theme_stylebox_override("scroll_focus", tor)
	pasek.add_theme_stylebox_override("grabber_area", tor)
	pasek.add_theme_stylebox_override("grabber_area_highlight", tor)


func _gui_input(zdarzenie: InputEvent) -> void:
	if zdarzenie is InputEventScreenTouch:
		var dotyk := zdarzenie as InputEventScreenTouch
		_palec = dotyk.pressed
		if not dotyk.pressed:
			_blokuj_mysz_do = Time.get_ticks_msec() + 80
		_wcisk(dotyk.position, dotyk.pressed)
		accept_event()
		return
	if zdarzenie is InputEventScreenDrag:
		_ruch((zdarzenie as InputEventScreenDrag).position)
		accept_event()
		return
	if zdarzenie is InputEventMouseButton:
		var mb := zdarzenie as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_vertical -= KROK_KOLKA
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_vertical += KROK_KOLKA
			accept_event()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if _palec or Time.get_ticks_msec() < _blokuj_mysz_do:
			accept_event()
			return
		_wcisk(mb.position, mb.pressed)
		accept_event()
		return
	if zdarzenie is InputEventMouseMotion and _aktywny:
		if _palec or Time.get_ticks_msec() < _blokuj_mysz_do:
			accept_event()
			return
		_ruch((zdarzenie as InputEventMouseMotion).position)
		accept_event()


func _wcisk(lokal: Vector2, wcisniety: bool) -> void:
	if wcisniety:
		_zatrzymaj_bezwladnosc()
		_aktywny = true
		_przeciaganie = false
		_start = lokal
		_poprzednia = lokal
		_scroll0 = scroll_vertical
		_poprzedni_czas = Time.get_ticks_msec()
		_ostatni_ruch_ms = _poprzedni_czas
		_predkosc = 0.0
		return
	if _aktywny and _przeciaganie:
		var teraz := Time.get_ticks_msec()
		_predkosc = predkosc_po_puszczeniu(_predkosc, teraz - _ostatni_ruch_ms)
		if absf(_predkosc) >= MIN_PREDKOSC:
			_bezwladnosc = true
			set_process(true)
		else:
			_zatrzymaj_bezwladnosc()
	elif _aktywny and klik_przy_drodze(lokal.distance_to(_start)):
		var globalna := get_global_transform_with_canvas() * lokal
		var przycisk := _przycisk_pod(globalna, self)
		if przycisk != null:
			_aktywuj(przycisk)
	_aktywny = false
	_przeciaganie = false


func _ruch(lokal: Vector2) -> void:
	if not _aktywny:
		return
	var delta := lokal - _start
	if not _przeciaganie and not klik_przy_drodze(delta.length()):
		_przeciaganie = true
	if _przeciaganie:
		var teraz := Time.get_ticks_msec()
		var dt := teraz - _poprzedni_czas
		var dy := lokal.y - _poprzednia.y
		if dt > 0 and dt < 120:
			var v := -(dy) / (float(dt) / 1000.0)
			_predkosc = lerpf(_predkosc, v, 0.55)
		elif dt >= 120:
			_predkosc = 0.0
		_poprzednia = lokal
		_poprzedni_czas = teraz
		_ostatni_ruch_ms = teraz
		# Palec w górę (delta.y < 0) odkrywa treść niżej.
		scroll_vertical = _scroll0 - int(delta.y)


func _aktywuj(przycisk: BaseButton) -> void:
	if przycisk.disabled or not przycisk.is_visible_in_tree():
		return
	if przycisk.toggle_mode:
		przycisk.button_pressed = not przycisk.button_pressed
	else:
		przycisk.pressed.emit()


func _on_dziecko(wezel: Node) -> void:
	_skonfiguruj_wezel(wezel)


func _podlacz(wezel: Node) -> void:
	if wezel.has_meta("_scroll_podpiety"):
		return
	wezel.set_meta("_scroll_podpiety", true)
	if not wezel.child_entered_tree.is_connected(_on_dziecko):
		wezel.child_entered_tree.connect(_on_dziecko)


func _skonfiguruj_wezel(wezel: Node) -> void:
	if wezel != self and wezel is ScrollContainer:
		if wezel.get_script() == null:
			wezel.set_script(load("res://scripts/scroll_dotyk.gd"))
		return
	_ustaw_filtr(wezel)
	_podlacz(wezel)
	for dziecko in wezel.get_children():
		_skonfiguruj_wezel(dziecko)


func _ustaw_filtr(wezel: Node) -> void:
	if wezel == self or not (wezel is Control):
		return
	var kontrolka := wezel as Control
	if _zostaw_natywny(kontrolka):
		kontrolka.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	kontrolka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kontrolka is BaseButton:
		kontrolka.focus_mode = Control.FOCUS_NONE


func _zostaw_natywny(kontrolka: Control) -> bool:
	if kontrolka is OptionButton or kontrolka is LineEdit or kontrolka is TextEdit:
		return true
	if kontrolka is ItemList or kontrolka is SpinBox or kontrolka is Range:
		return true
	var skrypt: Variant = kontrolka.get_script()
	if skrypt is Script:
		var sciezka := str((skrypt as Script).resource_path)
		if sciezka.ends_with("suwak_zakres.gd"):
			return true
	return false


func _przycisk_pod(global_pos: Vector2, wezel: Node) -> BaseButton:
	if wezel is CanvasItem and wezel != self and not (wezel as CanvasItem).is_visible_in_tree():
		return null
	var dzieci := wezel.get_children()
	for i in range(dzieci.size() - 1, -1, -1):
		var traf := _przycisk_pod(global_pos, dzieci[i])
		if traf != null:
			return traf
	if wezel is BaseButton and wezel is Control:
		var kontrolka := wezel as Control
		if kontrolka.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return null
		if not kontrolka.is_visible_in_tree():
			return null
		if kontrolka.get_global_rect().has_point(global_pos):
			return wezel as BaseButton
	return null
