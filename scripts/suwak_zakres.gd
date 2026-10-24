extends Control

## Suwak z dwiema kropkami. Nie liczy nic co klatkę.
## Uchwyt min przy 0 nie może „przykleić” się na stałe: przy nakładce
## bierzemy ten, który da się rozszerzyć; przeciągnięcie przez drugi
## zamienia role zamiast clampować w miejscu.

signal zakres_zmieniony(od: float, dokad: float)

var minimum := 0.0
var maximum := 1.0
var od := 0.0
var dokad := 1.0
var _ciagnie := ""


func _ready() -> void:
	custom_minimum_size = Vector2(0, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)


func ustaw_zakres(min_v: float, max_v: float) -> void:
	minimum = min_v
	maximum = max_v
	if maximum < minimum:
		maximum = minimum
	od = minimum
	dokad = maximum
	queue_redraw()


func _gui_input(zdarzenie: InputEvent) -> void:
	if zdarzenie is InputEventMouseButton and zdarzenie.button_index == MOUSE_BUTTON_LEFT:
		if zdarzenie.pressed:
			_zacznij(zdarzenie.position.x)
		else:
			_zakoncz()
	elif zdarzenie is InputEventScreenTouch:
		if zdarzenie.pressed:
			_zacznij(zdarzenie.position.x)
		else:
			_zakoncz()
	elif zdarzenie is InputEventScreenDrag and _ciagnie != "":
		_rusz(zdarzenie.position.x)


func _process(_dt: float) -> void:
	if _ciagnie == "":
		set_process(false)
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_zakoncz()
		return
	# Ruch poza kontrolką — _gui_input nie dostaje motion na skraju.
	_rusz(get_local_mouse_position().x)


func _zacznij(x: float) -> void:
	var xo := _x(od)
	var xd := _x(dokad)
	var do_od := absf(x - xo)
	var do_do := absf(x - xd)
	var eps_px := 14.0
	if do_od < do_do - 0.5:
		_ciagnie = "od"
	elif do_do < do_od - 0.5:
		_ciagnie = "dokad"
	else:
		# Nakładka / ten sam hitbox: nie preferuj zawsze „od” (to zacinało przy min).
		var rozpietosc := maximum - minimum
		var przy_min := rozpietosc <= 0.0 or (od <= minimum + _epsilon() and dokad <= minimum + _epsilon())
		var przy_max := rozpietosc <= 0.0 or (od >= maximum - _epsilon() and dokad >= maximum - _epsilon())
		if przy_min and not przy_max:
			_ciagnie = "dokad"
		elif przy_max and not przy_min:
			_ciagnie = "od"
		elif x >= (xo + xd) * 0.5:
			_ciagnie = "dokad"
		else:
			_ciagnie = "od"
	set_process(true)
	_rusz(x)


func _zakoncz() -> void:
	_ciagnie = ""
	set_process(false)


func _rusz(x: float) -> void:
	var wartosc := _wartosc(x)
	if _ciagnie == "od":
		if wartosc > dokad:
			# Przeciągnięcie przez max: zamień role zamiast przykleić min==max.
			od = dokad
			dokad = clampf(wartosc, minimum, maximum)
			_ciagnie = "dokad"
		else:
			od = clampf(wartosc, minimum, dokad)
	elif _ciagnie == "dokad":
		if wartosc < od:
			dokad = od
			od = clampf(wartosc, minimum, maximum)
			_ciagnie = "od"
		else:
			dokad = clampf(wartosc, od, maximum)
	queue_redraw()
	zakres_zmieniony.emit(od, dokad)


func _epsilon() -> float:
	var r := maximum - minimum
	if r <= 0.0:
		return 0.0
	return maxf(r * 1e-6, r * 0.0001)


func _x(wartosc: float) -> float:
	var marg := 18.0
	var szer := maxf(size.x - marg * 2.0, 1.0)
	var t := 0.0
	if maximum != minimum:
		t = clampf((wartosc - minimum) / (maximum - minimum), 0.0, 1.0)
	return marg + t * szer


func _wartosc(x: float) -> float:
	var marg := 18.0
	var szer := maxf(size.x - marg * 2.0, 1.0)
	var t := clampf((x - marg) / szer, 0.0, 1.0)
	if maximum == minimum:
		return minimum
	return minimum + t * (maximum - minimum)


func _draw() -> void:
	var y := size.y * 0.55
	draw_line(Vector2(18.0, y), Vector2(maxf(size.x - 18.0, 18.0), y), Color("#9aa7b2"), 4.0, true)
	_kropka(_x(od), y)
	_kropka(_x(dokad), y)


func _kropka(x: float, y: float) -> void:
	draw_circle(Vector2(x, y), 12.0, Color.WHITE)
	draw_arc(Vector2(x, y), 12.0, 0.0, TAU, 24, Color("#243844"), 2.0, true)
