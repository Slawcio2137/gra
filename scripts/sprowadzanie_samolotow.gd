extends RefCounted
class_name SprowadzanieSamolotow

## Stub sprowadzania / licencji / hangaru.

const PLIK := "res://pojazdy/sprowadzanie_samolotow.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func stan(bohater: Dictionary) -> Dictionary:
	if bohater.get("lotnictwo") is Dictionary:
		return bohater["lotnictwo"]
	return {"licencje": [], "hangar": false, "smiglowce_odblokowane": false}


func zapisz_stan(bohater: Dictionary, s: Dictionary) -> void:
	bohater["lotnictwo"] = s


func lista_licencji() -> Array:
	wczytaj()
	if dane.get("licencje") is Array:
		return dane["licencje"]
	return []


func kup_licencje(bohater: Dictionary, lic_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "propozycja_do_poprawki": true}
	var s := stan(bohater)
	var licencje: Array = s.get("licencje", []) if s.get("licencje") is Array else []
	if lic_id in licencje or str(lic_id) in licencje:
		out["tekst"] = "Masz już tę licencję (stub)."
		return out
	var conf: Dictionary = {}
	for l in lista_licencji():
		if l is Dictionary and str(l.get("id", "")) == lic_id:
			conf = l
			break
	if conf.is_empty():
		out["tekst"] = "Brak licencji."
		return out
	var wiek := int(bohater.get("wiek", 0))
	if wiek < int(conf.get("wiek_min", 17)):
		out["tekst"] = "Wiek min. %d (stub)." % int(conf.get("wiek_min", 17))
		return out
	var wymaga := str(conf.get("wymaga", ""))
	if wymaga != "" and not (wymaga in licencje):
		out["tekst"] = "Wymaga: %s." % wymaga
		return out
	var koszt := _zakres(conf.get("koszt_zl", [20000, 40000]), rng)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł na licencję." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	licencje.append(lic_id)
	s["licencje"] = licencje
	zapisz_stan(bohater, s)
	out["ok"] = true
	out["tekst"] = "Licencja %s (−%d zł, stub)." % [str(conf.get("nazwa", lic_id)), koszt]
	return out


func wynajmij_hangar(bohater: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "propozycja_do_poprawki": true}
	var s := stan(bohater)
	if bool(s.get("hangar", false)):
		out["tekst"] = "Hangar już wynajęty (stub)."
		return out
	var h: Dictionary = dane.get("hangar", {}) if dane.get("hangar") is Dictionary else {}
	var koszt := _zakres(h.get("koszt_miesiac_zl", [2000, 5000]), rng)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł na hangar." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	s["hangar"] = true
	s["hangar_koszt_miesiac"] = koszt
	zapisz_stan(bohater, s)
	out["ok"] = true
	out["tekst"] = "Hangar wynajęty (−%d zł / miesiąc stub)." % koszt
	return out


func sprawdz_odblokowanie_smiglowcow(bohater: Dictionary) -> Dictionary:
	wczytaj()
	var out := {"odblokowane": false, "tekst": ""}
	var od: Dictionary = dane.get("odblokowanie_smiglowcow_bojowych", {}) if dane.get("odblokowanie_smiglowcow_bojowych") is Dictionary else {}
	var wiek := int(bohater.get("wiek", 0))
	var min_w := int(od.get("wiek_min", 21))
	var s := stan(bohater)
	if wiek >= min_w:
		s["smiglowce_odblokowane"] = true
		zapisz_stan(bohater, s)
		out["odblokowane"] = true
		out["tekst"] = "Śmigłowce bojowe odblokowane wiekiem (katalog; stub)."
	else:
		out["tekst"] = "Śmigłowce bojowe: od wieku %d (stub)." % min_w
	return out


func tekst_ui(bohater: Dictionary) -> String:
	var s := stan(bohater)
	var lic: Array = s.get("licencje", []) if s.get("licencje") is Array else []
	return "Lotnictwo stub: licencje [%s], hangar=%s, śmigłowce=%s" % [
		", ".join(PackedStringArray(lic)) if not lic.is_empty() else "brak",
		"tak" if bool(s.get("hangar", false)) else "nie",
		"tak" if bool(s.get("smiglowce_odblokowane", false)) else "nie",
	]


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
