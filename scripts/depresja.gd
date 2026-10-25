extends RefCounted
class_name Depresja

## Pogłębianie depresji — etapy + terapia stub.

const PLIK := "res://postacie/depresja.json"
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


## Tydzień gry: +1 gdy psychika<0, inaczej reset licznika.
func tydzien(bohater: Dictionary) -> Dictionary:
	var psych := int(bohater.get("psychika", 50))
	var tyg := int(bohater.get("tygodnie_psychika_ponizej_0", 0))
	if psych < 0:
		tyg += 1
	else:
		tyg = 0
	bohater["tygodnie_psychika_ponizej_0"] = tyg
	return aktualizuj(bohater)


## Ustaw etap na podstawie bieżącego licznika (bez +1).
func aktualizuj(bohater: Dictionary) -> Dictionary:
	wczytaj()
	var out := {"etap": "", "zmiana": false, "tekst": ""}
	var tyg := int(bohater.get("tygodnie_psychika_ponizej_0", 0))
	var etap_id := ""
	if dane.get("etapy") is Array:
		for e in dane["etapy"]:
			if e is Dictionary and tyg >= int(e.get("tygodnie_min", 999)):
				etap_id = str(e.get("id", ""))
	if etap_id != "":
		bohater["depresja"] = true
		bohater["depresja_stub"] = false
		var stary := str(bohater.get("depresja_etap", ""))
		bohater["depresja_etap"] = etap_id
		if stary != etap_id:
			out["zmiana"] = true
			out["tekst"] = "Depresja: etap „%s” (propozycja gry)." % nazwa_etapu(etap_id)
	out["etap"] = str(bohater.get("depresja_etap", ""))
	return out


func nazwa_etapu(etap_id: String) -> String:
	wczytaj()
	if dane.get("etapy") is Array:
		for e in dane["etapy"]:
			if e is Dictionary and str(e.get("id", "")) == etap_id:
				return str(e.get("nazwa", etap_id))
	return etap_id


func mnoznik_przyrostu(bohater: Dictionary) -> float:
	wczytaj()
	if not bool(bohater.get("depresja", false)):
		return 1.0
	var etap := str(bohater.get("depresja_etap", "objawy"))
	var efekty: Dictionary = dane.get("efekty", {}) if dane.get("efekty") is Dictionary else {}
	var e: Dictionary = efekty.get(etap, {}) if efekty.get(etap) is Dictionary else {}
	return float(e.get("mnoznik_przyrostu_psychiki", 0.7))


func blokada_imprez(bohater: Dictionary) -> bool:
	wczytaj()
	if not bool(bohater.get("depresja", false)):
		return false
	var etap := str(bohater.get("depresja_etap", ""))
	var efekty: Dictionary = dane.get("efekty", {}) if dane.get("efekty") is Dictionary else {}
	var e: Dictionary = efekty.get(etap, {}) if efekty.get(etap) is Dictionary else {}
	return bool(e.get("blokada_imprez", false))


func terapia(bohater: Dictionary, tryb: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "propozycja_do_poprawki": true}
	var stub: Dictionary = dane.get("terapia_stub", {}) if dane.get("terapia_stub") is Dictionary else {}
	var conf: Dictionary = stub.get(tryb, {}) if stub.get(tryb) is Dictionary else {}
	if conf.is_empty():
		out["tekst"] = "Brak trybu terapii."
		return out
	if rng.randf() > float(conf.get("szansa_miejsca", 1.0)):
		out["tekst"] = "NFZ: brak miejsca w kolejce (stub)."
		return out
	var koszt_v: Variant = conf.get("koszt_zl", 0)
	var koszt := 0
	if koszt_v is Array and koszt_v.size() >= 2:
		koszt = rng.randi_range(int(koszt_v[0]), int(koszt_v[1]))
	elif koszt_v is int or koszt_v is float:
		koszt = int(koszt_v)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł na terapię." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	var czek := int(conf.get("czekanie_tygodnie", 0))
	if czek > 0 and int(bohater.get("terapia_czekanie", 0)) < czek:
		bohater["terapia_czekanie"] = int(bohater.get("terapia_czekanie", 0)) + 1
		out["tekst"] = "Terapia NFZ: czekasz (%d/%d tyg.)." % [int(bohater["terapia_czekanie"]), czek]
		out["ok"] = true
		return out
	var efekt_v: Variant = conf.get("efekt_psychika", [2, 5])
	var d := 3
	if efekt_v is Array and efekt_v.size() >= 2:
		d = rng.randi_range(int(efekt_v[0]), int(efekt_v[1]))
	d = int(round(float(d) * mnoznik_przyrostu(bohater)))
	var psych := int(bohater.get("psychika", 50)) + d
	bohater["psychika"] = clampi(psych, -50, 100)
	var ie = SkryptIE.new()
	ie.dodaj(bohater, 2)
	if int(bohater["psychika"]) >= 20 and bool(bohater.get("depresja", false)):
		bohater["depresja_remisja_stub"] = true
		if int(bohater["psychika"]) >= 40:
			bohater["depresja"] = false
			bohater["depresja_etap"] = ""
			bohater["tygodnie_psychika_ponizej_0"] = 0
	out["ok"] = true
	out["tekst"] = "Terapia (%s): psychika %+d%s." % [
		tryb, d, (" (−%d zł)" % koszt) if koszt > 0 else ""
	]
	return out


func tekst_stanu(bohater: Dictionary) -> String:
	if not bool(bohater.get("depresja", false)):
		return ""
	var etap := str(bohater.get("depresja_etap", "objawy"))
	return "Depresja: %s (etykieta gry — nie diagnoza)." % nazwa_etapu(etap)


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
