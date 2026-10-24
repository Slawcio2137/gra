extends RefCounted
class_name PracaSzkielet

## Szkielet pracy / fuch — odblokowania + efekt sylwetki/zmęczenia.

const PLIK := "res://postacie/praca_szkielet.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func prace_dla_wieku(wiek: int) -> Array:
	wczytaj()
	var out: Array = []
	if not (dane.get("prace") is Array):
		return out
	for p in dane["prace"]:
		if not (p is Dictionary):
			continue
		if int(p.get("wiek_min", 18)) <= wiek:
			out.append(p)
	return out


func wykonaj_fuche(bohater: Dictionary, praca_id: String, sylwetka, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	var out := {"ok": false, "placa": 0, "tekst": "", "propozycja_do_poprawki": true}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var praca: Dictionary = {}
	for p in prace_dla_wieku(99):
		if str(p.get("id", "")) == praca_id:
			praca = p
			break
	if praca.is_empty():
		out["tekst"] = "Brak fuchy."
		return out
	var przedzial: Variant = praca.get("placa_zl", [20, 40])
	var od_v := 20
	var do_v := 40
	if przedzial is Array and przedzial.size() >= 2:
		od_v = int(przedzial[0])
		do_v = int(przedzial[1])
	var placa := rng.randi_range(od_v, do_v)
	var zm := int(praca.get("zmeczenie", 10))
	var zm_f := int(bohater.get("zmeczenie_fizyczne", 0))
	bohater["zmeczenie_fizyczne"] = clampi(zm_f + zm, 0, 100)
	if sylwetka != null and sylwetka.has_method("dodaj_za_fuche"):
		sylwetka.dodaj_za_fuche(int(praca.get("sylwetka_pkt", 0)) > 0)
		if bohater.get("sylwetka") is Dictionary or true:
			bohater["sylwetka"] = sylwetka.do_zapisu()
	out["ok"] = true
	out["placa"] = placa
	out["tekst"] = "%s: +%d zł, zmęczenie +%d." % [str(praca.get("nazwa", praca_id)), placa, zm]
	return out


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
