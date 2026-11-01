extends SceneTree

## Stuknięcie klika. Przeciągnięcie nie klika. Spoczynek gasi rozpęd.
## godot --headless --path . --script res://scripts/test_scroll_bezwladnosc.gd

const Scroll = preload("res://scripts/scroll_dotyk.gd")


func _init() -> void:
	call_deferred("_odpal")


func _odpal() -> void:
	var kod := await _uruchom()
	quit(kod)


func _uruchom() -> int:
	if Scroll.klik_przy_drodze(0.0):
		pass
	else:
		printerr("FAIL: brak ruchu nie jest kliknięciem")
		return 1
	if not Scroll.klik_przy_drodze(17.9):
		printerr("FAIL: ruch pod progiem nie klika")
		return 1
	if Scroll.klik_przy_drodze(18.0) or Scroll.klik_przy_drodze(40.0):
		printerr("FAIL: przeciągnięcie nadal jest kliknięciem")
		return 1
	if not is_equal_approx(Scroll.predkosc_po_puszczeniu(1400.0, 20), 1400.0):
		printerr("FAIL: puszczenie w ruchu zgasiło rozpęd")
		return 1
	if Scroll.predkosc_po_puszczeniu(1400.0, 90) != 0.0 or Scroll.predkosc_po_puszczeniu(1400.0, 200) != 0.0:
		printerr("FAIL: spoczynek zostawił prędkość")
		return 1

	var scroll := ScrollContainer.new()
	scroll.set_script(Scroll)
	scroll.custom_minimum_size = Vector2(400, 220)
	scroll.size = Vector2(400, 220)
	root.add_child(scroll)
	var pudlo := VBoxContainer.new()
	pudlo.custom_minimum_size = Vector2(380, 1600)
	scroll.add_child(pudlo)
	var przycisk := Button.new()
	przycisk.text = "Kup"
	przycisk.custom_minimum_size = Vector2(200, 48)
	pudlo.add_child(przycisk)
	var klikniecia := {"n": 0}
	przycisk.pressed.connect(func() -> void:
		klikniecia["n"] = int(klikniecia["n"]) + 1
	)
	scroll._ready()
	await process_frame
	await process_frame
	var srodek: Vector2 = przycisk.get_global_rect().get_center()
	if srodek == Vector2.ZERO:
		printerr("FAIL: przycisk bez prostokąta")
		return 1
	var lokal: Vector2 = scroll.get_global_transform_with_canvas().affine_inverse() * srodek
	_mysz(scroll, lokal, true)
	_mysz(scroll, lokal, false)
	if int(klikniecia["n"]) != 1:
		printerr("FAIL: stuknięcie bez ruchu nie kliknęło ", klikniecia["n"], " lokal=", lokal)
		return 1
	_mysz(scroll, lokal, true)
	_mysz_ruch(scroll, lokal + Vector2(0, -80))
	_mysz(scroll, lokal + Vector2(0, -80), false)
	if int(klikniecia["n"]) != 1:
		printerr("FAIL: puszczenie po przeciągnięciu kliknęło ", klikniecia["n"])
		return 1
	print("OK tap vs drag, prog=", Scroll.PROG_PX, " spoczynek_ms=", Scroll.PROG_SPOCZYNKU_MS)
	return 0


func _mysz(scroll: ScrollContainer, lokal: Vector2, wcisniety: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = wcisniety
	ev.position = lokal
	scroll._gui_input(ev)


func _mysz_ruch(scroll: ScrollContainer, lokal: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = lokal
	scroll._gui_input(ev)
