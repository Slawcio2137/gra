extends RefCounted
class_name ZajeciaDodatkowe

const PLIK := "res://postacie/zajecia_dodatkowe.json"
const SkryptIE = preload("res://scripts/inteligencja_emocjonalna.gd")

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func lista(wiek: int) -> Array:
	wczytaj()
	var out: Array = []
	if not (dane.get("zajecia") is Array):
		return out
	for z in dane["zajecia"]:
		if z is Dictionary and int(z.get("wiek_min", 0)) <= wiek:
			out.append(z)
	return out


func aktywne(bohater: Dictionary) -> Array:
	if bohater.get("zajecia_dodatkowe") is Array:
		return bohater["zajecia_dodatkowe"]
	return []


func zapisz_sie(bohater: Dictionary, zajecie_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "koszt": 0, "propozycja_do_poprawki": true}
	var akt := aktywne(bohater)
	var max_a := int(dane.get("max_aktywnych", 2))
	if akt.size() >= max_a:
		out["tekst"] = "Max %d zajęć naraz." % max_a
		return out
	for a in akt:
		if str(a) == zajecie_id:
			out["tekst"] = "Już zapisany."
			return out
	var z: Dictionary = {}
	for x in lista(99):
		if x is Dictionary and str(x.get("id", "")) == zajecie_id:
			z = x
			break
	if z.is_empty():
		out["tekst"] = "Brak zajęć."
		return out
	var wiek := int(bohater.get("wiek", 0))
	if wiek < int(z.get("wiek_min", 0)):
		out["tekst"] = "Za młody."
		return out
	var koszt := _zakres(z.get("koszt_miesiac_zl", [50, 100]), rng)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł (miesiąc)." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	akt.append(zajecie_id)
	bohater["zajecia_dodatkowe"] = akt
	out["ok"] = true
	out["koszt"] = koszt
	out["tekst"] = "Zapisano: %s (−%d zł / miesiąc stub)." % [str(z.get("nazwa", zajecie_id)), koszt]
	return out


func efekt_tygodnia(bohater: Dictionary, sylwetka = null) -> Dictionary:
	wczytaj()
	var out := {"teksty": [], "propozycja_do_poprawki": true}
	var akt := aktywne(bohater)
	if akt.is_empty():
		return out
	for id in akt:
		var z: Dictionary = {}
		for x in lista(99):
			if x is Dictionary and str(x.get("id", "")) == str(id):
				z = x
				break
		if z.is_empty():
			continue
		if bool(z.get("sylwetka", false)) and sylwetka != null and sylwetka.has_method("dodaj_za_fuche"):
			sylwetka.dodaj_za_fuche(true)
			bohater["sylwetka"] = sylwetka.do_zapisu()
		if z.has("psychika"):
			var p := int(bohater.get("psychika", 50)) + int(z["psychika"])
			bohater["psychika"] = clampi(p, -50, 100)
		if z.has("wiedza_pkt"):
			bohater["wiedza_pkt"] = int(bohater.get("wiedza_pkt", 0)) + int(z["wiedza_pkt"])
		if z.has("ie_pkt"):
			var ie = SkryptIE.new()
			ie.dodaj(bohater, int(z["ie_pkt"]))
		out["teksty"].append(str(z.get("nazwa", id)))
	return out


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
