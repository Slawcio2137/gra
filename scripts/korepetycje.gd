extends RefCounted
class_name Korepetycje

const PLIK := "res://postacie/korepetycje.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func lista() -> Array:
	wczytaj()
	if dane.get("przedmioty") is Array:
		return dane["przedmioty"]
	return []


func zajecie(bohater: Dictionary, przedmiot_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "koszt": 0, "wiedza": 0, "propozycja_do_poprawki": true}
	var ile := int(bohater.get("korepetycje_tydzien", 0))
	var limit := int(dane.get("limit_zajec_na_tydzien", 3))
	if ile >= limit:
		out["tekst"] = "Limit korepetycji w tym tygodniu (%d)." % limit
		return out
	var p: Dictionary = {}
	for x in lista():
		if x is Dictionary and str(x.get("id", "")) == przedmiot_id:
			p = x
			break
	if p.is_empty():
		out["tekst"] = "Brak przedmiotu."
		return out
	var koszt := _zakres(p.get("koszt_zajecia_zl", [40, 80]), rng)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł na korepetycje." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	var w := _zakres(p.get("wiedza_pkt", [2, 4]), rng)
	bohater["wiedza_pkt"] = int(bohater.get("wiedza_pkt", 0)) + w
	bohater["korepetycje_tydzien"] = ile + 1
	out["ok"] = true
	out["koszt"] = koszt
	out["wiedza"] = w
	out["tekst"] = "Korepetycje: %s (−%d zł, wiedza +%d)." % [str(p.get("nazwa", przedmiot_id)), koszt, w]
	return out


func reset_tydzien(bohater: Dictionary) -> void:
	bohater["korepetycje_tydzien"] = 0


func _zakres(v: Variant, rng: RandomNumberGenerator) -> int:
	if v is Array and v.size() >= 2:
		return rng.randi_range(int(v[0]), int(v[1]))
	if v is int or v is float:
		return int(v)
	return 0


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
