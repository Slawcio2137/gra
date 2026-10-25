extends RefCounted
class_name InteligencjaEmocjonalna

## Osobna metryka IE 0–100 (propozycja gry).

const PLIK := "res://postacie/inteligencja_emocjonalna.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func losuj_start(rng: RandomNumberGenerator = null) -> int:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var s: Dictionary = dane.get("start", {}) if dane.get("start") is Dictionary else {}
	return rng.randi_range(int(s.get("min", 30)), int(s.get("max", 50)))


func poziom(wartosc: int) -> String:
	wczytaj()
	var p: Dictionary = dane.get("progi", {}) if dane.get("progi") is Dictionary else {}
	if wartosc >= int(p.get("wysoka", 75)):
		return "wysoka"
	if wartosc >= int(p.get("srednia", 55)):
		return "średnia"
	if wartosc >= int(p.get("niska", 35)):
		return "niska"
	return "bardzo niska"


func dodaj(bohater: Dictionary, delta: int) -> int:
	wczytaj()
	var v := int(bohater.get("inteligencja_emocjonalna", 40))
	var postep: Dictionary = dane.get("postep", {}) if dane.get("postep") is Dictionary else {}
	var max_t := int(postep.get("max_tydzien", 6))
	var juz := int(bohater.get("ie_przyrost_tydzien", 0))
	if delta > 0:
		var room := maxi(0, max_t - juz)
		delta = mini(delta, room)
		bohater["ie_przyrost_tydzien"] = juz + delta
	v = clampi(v + delta, 0, 100)
	bohater["inteligencja_emocjonalna"] = v
	return v


func reset_tydzien(bohater: Dictionary) -> void:
	bohater["ie_przyrost_tydzien"] = 0


func redukcja_hejt(bohater: Dictionary) -> float:
	wczytaj()
	var v := int(bohater.get("inteligencja_emocjonalna", 40))
	var p: Dictionary = dane.get("progi", {}) if dane.get("progi") is Dictionary else {}
	if v < int(p.get("wysoka", 75)):
		return 0.0
	var e: Dictionary = dane.get("efekty", {}) if dane.get("efekty") is Dictionary else {}
	return float(e.get("redukcja_hejt_przy_wysokiej", 0.15))


func tekst(bohater: Dictionary) -> String:
	var v := int(bohater.get("inteligencja_emocjonalna", -1))
	if v < 0:
		return ""
	return "Inteligencja emocjonalna: %d/100 (%s)" % [v, poziom(v)]


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
