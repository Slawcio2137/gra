extends RefCounted
class_name ZainteresowaniaLos

## Koło zainteresowań — jedno dominujące na start.

const PLIK := "res://postacie/zainteresowania.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var surowe: Variant = _czytaj(PLIK)
	if surowe is Dictionary:
		dane = surowe


func losuj_dominujace(los) -> Dictionary:
	wczytaj()
	var lista: Variant = dane.get("start_ogolne", [])
	var wagi := {}
	var nazwy := {}
	if lista is Array:
		for p in lista:
			if not (p is Dictionary) or not p.has("id"):
				continue
			var w: Variant = p.get("waga")
			if not (w is int or w is float) or float(w) <= 0.0:
				continue
			var id := str(p["id"])
			wagi[id] = float(w)
			nazwy[id] = str(p.get("nazwa", id))
	if wagi.is_empty():
		return {"id": null, "nazwa": null, "kolo": false, "powod": "brak wag"}
	var id_w: String = los.losuj_kolo(wagi)
	if id_w == "":
		return {"id": null, "nazwa": null, "kolo": false, "powod": "koło puste"}
	return {
		"id": id_w,
		"nazwa": nazwy.get(id_w, id_w),
		"kolo": true,
		"dominujace": true,
		"ogolne": true,
		"doprecyzowanie": null,
		"propozycja_do_poprawki": true,
	}


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
