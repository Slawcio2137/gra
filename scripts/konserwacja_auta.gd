extends RefCounted
class_name KonserwacjaAuta

## Stub: olej / filtry / opony + zima / zatarcie. Efekty w turze.

const PLIK := "res://pojazdy/konserwacja_aut.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func stan_startowy() -> Dictionary:
	wczytaj()
	var s: Dictionary = {}
	if dane.get("start_stanu") is Dictionary:
		s = (dane["start_stanu"] as Dictionary).duplicate(true)
	else:
		s = {"olej": 80, "filtry": 75, "opony": 70, "konserwacja_zima": false}
	s["ostrzezenie_olej"] = false
	s["zatarcie"] = false
	s["rdza"] = false
	return s


func efekt_tury(stan: Dictionary, zima: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"teksty": [], "olej_ostrzezenie": false, "zatarcie": false, "rdza": false}
	var progi: Dictionary = dane.get("progi", {}) if dane.get("progi") is Dictionary else {}
	var efekty: Dictionary = dane.get("efekty", {}) if dane.get("efekty") is Dictionary else {}
	stan["olej"] = maxi(0, int(stan.get("olej", 80)) - int(round(float(progi.get("olej_zuzycie_tydzien", 1.5)))))
	stan["filtry"] = maxi(0, int(stan.get("filtry", 75)) - int(round(float(progi.get("filtry_zuzycie_tydzien", 1.2)))))
	stan["opony"] = maxi(0, int(stan.get("opony", 70)) - int(round(float(progi.get("opony_zuzycie_tydzien", 0.8)))))
	var ostrz := int(progi.get("olej_ostrzezenie", 25))
	var kryt := int(progi.get("olej_krytyczny", 8))
	if int(stan["olej"]) <= ostrz:
		out["olej_ostrzezenie"] = true
		out["teksty"].append("Ostrzeżenie: niski poziom oleju (%d)." % int(stan["olej"]))
	if int(stan["olej"]) <= kryt:
		var sz := float(efekty.get("brak_oleju_szansa_zatarcia", 0.08))
		if rng.randf() < sz:
			out["zatarcie"] = true
			stan["zatarcie"] = true
			out["teksty"].append("Silnik zatarł się — brak oleju.")
	if zima:
		var konserw := bool(stan.get("konserwacja_zima", false))
		var sz_r := float(efekty.get("zima_z_konserwacja_szansa_rdzy" if konserw else "zima_bez_konserwacji_szansa_rdzy", 0.05))
		if rng.randf() < sz_r:
			out["rdza"] = true
			stan["rdza"] = true
			out["teksty"].append("Pojawiła się rdza (zima%s)." % (" — mimo konserwacji" if konserw else ""))
	return out


func ustaw_konserwacje_zimowa(stan: Dictionary, wlacz: bool) -> void:
	stan["konserwacja_zima"] = wlacz


func napraw(stan: Dictionary, sposob: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var naprawy: Dictionary = dane.get("naprawy", {}) if dane.get("naprawy") is Dictionary else {}
	var conf: Dictionary = naprawy.get(sposob, naprawy.get("samodzielnie", {})) if naprawy.get(sposob) is Dictionary or naprawy.get("samodzielnie") is Dictionary else {}
	if not (conf is Dictionary):
		conf = {"szansa_sukcesu": 0.5, "koszt_mnoznik": 0.5, "ryzyko_pogorszenia": 0.1}
	var out := {"ok": false, "tekst": "", "koszt_mnoznik": float(conf.get("koszt_mnoznik", 1.0))}
	if rng.randf() < float(conf.get("szansa_sukcesu", 0.5)):
		stan["olej"] = mini(100, int(stan.get("olej", 0)) + 40)
		stan["filtry"] = mini(100, int(stan.get("filtry", 0)) + 35)
		out["ok"] = true
		out["tekst"] = "Naprawa (%s) udała się." % sposob
	elif rng.randf() < float(conf.get("ryzyko_pogorszenia", 0.1)):
		stan["olej"] = maxi(0, int(stan.get("olej", 0)) - 10)
		out["tekst"] = "Naprawa (%s) pogorszyła sprawę." % sposob
	else:
		out["tekst"] = "Naprawa (%s) nie pomogła." % sposob
	return out


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
