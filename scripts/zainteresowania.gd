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


## Fala 2: ogólne → konkret od ~10–12 lat (propozycja lokalna, nie oficjalne dane).
func doprecyzuj_z_wiekiem(zain: Dictionary, wiek: int, los) -> Dictionary:
	wczytaj()
	if not bool(zain.get("ogolne", true)) or zain.get("doprecyzowanie") != null:
		return zain
	if wiek < 10:
		return zain
	var mapa := {
		"pojazdy": [["samoloty", "Samoloty"], ["auta", "Auta"], ["rowery", "Rowery"]],
		"sport": [["pilka", "Piłka"], ["plywanie", "Pływanie"], ["bieganie", "Bieganie"]],
		"muzyka": [["gitara", "Gitara"], ["rap", "Rap"], ["klasyka", "Klasyka"]],
		"gry": [["strategiczne", "Strategiczne"], ["fps", "FPS"], ["rpg", "RPG"]],
		"kosmos": [["astronautyka", "Astronautyka"], ["astronomia", "Astronomia"]],
		"zwierzeta": [["psy", "Psy"], ["koty", "Koty"], ["ptaki", "Ptaki"]],
		"przyroda": [["las", "Las"], ["morze", "Morze"]],
		"historia": [["XX_wiek", "XX wiek"], ["starozytnosc", "Starożytność"]],
		"rysowanie": [["manga", "Manga"], ["realizm", "Realizm"]],
		"gotowanie": [["wypieki", "Wypieki"], ["kuchnia_pl", "Kuchnia PL"]],
	}
	var id0 := str(zain.get("id", ""))
	if not mapa.has(id0):
		return zain
	var opcje: Array = mapa[id0]
	var wagi := {}
	for i in opcje.size():
		wagi[str(i)] = 1.0
	var idx_s: String = los.losuj_kolo(wagi)
	var idx := int(idx_s) if idx_s.is_valid_int() else 0
	idx = clampi(idx, 0, opcje.size() - 1)
	var para: Array = opcje[idx]
	zain["doprecyzowanie"] = {"id": str(para[0]), "nazwa": str(para[1])}
	zain["ogolne"] = false
	zain["nazwa"] = "%s → %s" % [str(zain.get("nazwa", id0)), str(para[1])]
	zain["propozycja_do_poprawki"] = true
	return zain


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
