extends RefCounted
class_name EventyPrzyklady

## Framework eventów Fali 1 + pakiet Fali 2 + hejt (−40% wsparcie rodziców, −IE).

const PLIK := "res://postacie/eventy_przyklady.json"
const PLIK_FALA2 := "res://postacie/eventy_fala2.json"
const PLIK_OBJAWY := "res://postacie/zdrowie/objawy_pasek.json"
const SkryptIE = preload("res://scripts/inteligencja_emocjonalna.gd")
const SkryptDep = preload("res://scripts/depresja.gd")

var dane: Dictionary = {}
var dane_fala2: Dictionary = {}
var objawy: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s
	var s2: Variant = _czytaj(PLIK_FALA2)
	if s2 is Dictionary:
		dane_fala2 = s2
	var o: Variant = _czytaj(PLIK_OBJAWY)
	if o is Dictionary:
		objawy = o


func lista_eventow() -> Array:
	wczytaj()
	var out: Array = []
	if dane.get("eventy") is Array:
		out.append_array(dane["eventy"])
	if dane_fala2.get("eventy") is Array:
		out.append_array(dane_fala2["eventy"])
	return out


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
	if bool(efekt.get("hejt", false)) or event_id == "hejt_przyklad" or str(ev.get("typ", "")) == "hejt":
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
		# IE wysoka: dodatkowa redukcja (Fala 2).
		var ie = SkryptIE.new()
		var red_ie: float = ie.redukcja_hejt(bohater)
		if red_ie > 0.0:
			spadek = int(round(float(spadek) * (1.0 - red_ie)))
			out["tekst"] += " IE −%d%%." % int(red_ie * 100.0)
		delta = -spadek
	else:
		out["tekst"] = str(opcja.get("tekst", ""))
	if efekt.has("wiedza_pkt"):
		bohater["wiedza_pkt"] = int(bohater.get("wiedza_pkt", 0)) + int(efekt["wiedza_pkt"])
	if efekt.has("ie_pkt"):
		var ie2 = SkryptIE.new()
		ie2.dodaj(bohater, int(efekt["ie_pkt"]))
	if efekt.has("zmeczenie"):
		var zm := int(bohater.get("zmeczenie_fizyczne", 0)) + int(efekt["zmeczenie"])
		bohater["zmeczenie_fizyczne"] = clampi(zm, 0, 100)
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
	# Jak Fala 1: przy psychice <0 dolicz tydzień dołka, potem oceń etap (Fala 2).
	var psych := int(bohater.get("psychika", 50))
	var tyg := int(bohater.get("tygodnie_psychika_ponizej_0", 0))
	if psych < 0:
		tyg += 1
	else:
		tyg = 0
	bohater["tygodnie_psychika_ponizej_0"] = tyg
	var dep = SkryptDep.new()
	dep.aktualizuj(bohater)


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
