extends Control

## Strzałka stanu prostokąta statystyk. W prawo gdy zwinięte, w dół gdy rozwinięte.

var w_dol := false


func _ready() -> void:
	custom_minimum_size = Vector2(36, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func ustaw(dol: bool) -> void:
	w_dol = dol
	queue_redraw()


func _draw() -> void:
	var kolor := Color.WHITE
	var punkty := PackedVector2Array()
	var szer := size.x
	var wys := size.y
	if szer < 4.0 or wys < 4.0:
		return
	if w_dol:
		punkty.append(Vector2(szer * 0.18, wys * 0.32))
		punkty.append(Vector2(szer * 0.82, wys * 0.32))
		punkty.append(Vector2(szer * 0.5, wys * 0.74))
	else:
		punkty.append(Vector2(szer * 0.32, wys * 0.18))
		punkty.append(Vector2(szer * 0.32, wys * 0.82))
		punkty.append(Vector2(szer * 0.74, wys * 0.5))
	draw_colored_polygon(punkty, kolor)
