extends RefCounted
class_name EventyPrzyklady

## Framework 3–5 eventów przykładowych + hejt ze wsparciem rodziców (−40%).

const PLIK := "res://postacie/eventy_przyklady.json"
const PLIK_OBJAWY := "res://postacie/zdrowie/objawy_pasek.json"

var dane: Dictionary = {}
var objawy: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s
	var o: Variant = _czytaj(PLIK_OBJAWY)
	if o is Dictionary:
		objawy = o


func lista_eventow() -> Array:
	wczytaj()
	if dane.get("eventy") is Array:
		return dane["eventy"]
	return []


func event_po_id(id: String) -> Dictionary:
	for e in lista_eventow():
		if e is Dictionary and str(e.get("id", "")) == id:
			return e
	return {}


## Zastosuj opcję. Wsparcie rodziców przy hejcie: −40% spadku psychiki.
func zastosuj_opcje(bohater: Dictionary, event_id: String, opcja_id: String) -> Dictionary:
	wczytaj()
	var ev := event_po_id(event_id)
	var out := {"ok": false, "tekst": "", "delta_psychika": 0, "propozycja_do_poprawki": true}
	if ev.is_empty():
		out["tekst"] = "Brak eventu."
		return out
	var opcja: Dictionary = {}
	if ev.get("opcje") is Array:
		for o in ev["opcje"]:
			if o is Dictionary and str(o.get("id", "")) == opcja_id:
				opcja = o
				break
	if opcja.is_empty():
		out["tekst"] = "Brak opcji."
		return out
	var efekt: Dictionary = opcja.get("efekt", {}) if opcja.get("efekt") is Dictionary else {}
	var delta := int(efekt.get("psychika", 0))
	# Hejt z eventu zaczepka / hejt_przyklad.
	if bool(efekt.get("hejt", false)) or event_id == "hejt_przyklad":
		var hejt: Dictionary = {}
		if ev.get("hejt_przyklad") is Dictionary:
			hejt = ev["hejt_przyklad"]
		elif event_id == "hejt_przyklad":
			hejt = {"spadek_psychiki": 15, "wsparcie_rodzicow_redukcja": 0.4}
		var spadek := int(hejt.get("spadek_psychiki", absi(delta) if delta < 0 else 15))
		if bool(efekt.get("wsparcie_rodzicow", false)):
			var red := float(hejt.get("wsparcie_rodzicow_redukcja", 0.4))
			spadek = int(round(float(spadek) * (1.0 - red)))
			out["tekst"] = "Hejt: rodzice wspierają (−40%% spadku). Psychika %d." % -spadek
		else:
			out["tekst"] = "Hejt bez wsparcia. Psychika %d." % -spadek
		delta = -spadek
	else:
		out["tekst"] = str(opcja.get("tekst", ""))
	var psych := 50
	if bohater.get("psychika") is int or bohater.get("psychika") is float:
		psych = int(bohater["psychika"])
	# Dół może < 0; góra 100.
	psych = mini(100, psych + delta)
	bohater["psychika"] = psych
	_aktualizuj_flage_depresji(bohater)
	out["ok"] = true
	out["delta_psychika"] = delta
	return out


func _aktualizuj_flage_depresji(bohater: Dictionary) -> void:
	var psych := int(bohater.get("psychika", 50))
	var tygodnie_ponizej := int(bohater.get("tygodnie_psychika_ponizej_0", 0))
	if psych < 0:
		tygodnie_ponizej += 1
	else:
		tygodnie_ponizej = 0
	bohater["tygodnie_psychika_ponizej_0"] = tygodnie_ponizej
	# Po dłuższym czasie <0 → flaga depresji (pogłębianie stub).
	if tygodnie_ponizej >= 4:
		bohater["depresja"] = true
		bohater["depresja_stub"] = true
	elif psych >= 0:
		# Flaga nie znika automatycznie w Fali 1 — tylko stub.
		pass


func lista_objawow() -> Array:
	wczytaj()
	if objawy.get("objawy") is Array:
		return objawy["objawy"]
	return []


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
