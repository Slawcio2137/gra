extends RefCounted
class_name StanGry

## Bohater, pieniądze, lokum i miejsce pobytu. Słownik świata zostaje na hoście — nie autoload.

var h


func _init(host) -> void:
	h = host




func _efekt_wygody_tydzien() -> void:
	h._swiat["ostatni_efekt_wygody_tekst"] = ""
	if not (h._swiat.get("lokum_startowe") is Dictionary) or not _lokum_pelne(h._swiat.get("lokum_startowe")):
		h._swiat["lokum_startowe"] = _zbuduj_lokum_dla_swiata()
	var wynik: Dictionary = h._rynek_zakupow.efekt_wygody_tydzien(h._swiat)
	var tekst := str(wynik.get("tekst", "")).strip_edges()
	h._swiat["ostatni_efekt_wygody_tekst"] = tekst
	if tekst == "":
		return
	var kom = str(h._swiat.get("komunikat_tury", "")).strip_edges()
	h._swiat["komunikat_tury"] = tekst if kom == "" else kom + "\n" + tekst


func _uzupelnij_normy_bohatera(bohater: Dictionary) -> void:
	var psychika: Variant = h._emotikony.get("psychika", {})
	var zmeczenie: Variant = h._emotikony.get("zmeczenie_fizyczne", h._emotikony.get("zmeczenie", {}))
	var zmeczenie_p: Variant = h._emotikony.get("zmeczenie_psychiczne", {})
	if not h._ui._jest_liczba(bohater.get("psychika")) and psychika is Dictionary and h._ui._jest_liczba(psychika.get("norma")):
		bohater["psychika"] = int(psychika["norma"])
	if not h._ui._jest_liczba(bohater.get("zmeczenie_fizyczne")):
		if h._ui._jest_liczba(bohater.get("zmeczenie")):
			bohater["zmeczenie_fizyczne"] = int(bohater["zmeczenie"])
		elif zmeczenie is Dictionary and h._ui._jest_liczba(zmeczenie.get("norma")):
			bohater["zmeczenie_fizyczne"] = int(zmeczenie["norma"])
	if h._ui._jest_liczba(bohater.get("zmeczenie_fizyczne")):
		bohater["zmeczenie"] = int(bohater["zmeczenie_fizyczne"])
	elif not h._ui._jest_liczba(bohater.get("zmeczenie")) and zmeczenie is Dictionary and h._ui._jest_liczba(zmeczenie.get("norma")):
		bohater["zmeczenie"] = int(zmeczenie["norma"])
		bohater["zmeczenie_fizyczne"] = int(zmeczenie["norma"])
	if not h._ui._jest_liczba(bohater.get("zmeczenie_psychiczne")) and zmeczenie_p is Dictionary and h._ui._jest_liczba(zmeczenie_p.get("norma")):
		bohater["zmeczenie_psychiczne"] = int(zmeczenie_p["norma"])


func _zsynchronizuj_pieniadze_z_bohatera() -> void:
	var stan = h._jedzenie.odczyt_statystyk()
	if h._ui._jest_liczba(stan.get("pieniadze")):
		return
	var bohater := _bohater()
	if h._ui._jest_liczba(bohater.get("pieniadze")):
		h._jedzenie.zastosuj_statystyki({"pieniadze": int(bohater["pieniadze"])})


func _dodaj_pieniadze(kwota: int) -> void:
	if kwota <= 0:
		return
	var stan = h._jedzenie.odczyt_statystyk()
	var teraz := 0
	if h._ui._jest_liczba(stan.get("pieniadze")):
		teraz = int(stan["pieniadze"])
	elif h._ui._jest_liczba(_bohater().get("pieniadze")):
		teraz = int(_bohater()["pieniadze"])
	var nowe := teraz + kwota
	h._jedzenie.zastosuj_statystyki({"pieniadze": nowe})
	var bohater := _bohater()
	bohater["pieniadze"] = nowe
	h._swiat["bohater"] = bohater


func _dodaj_wplyw(zrodlo: String, kwota: int, tekst: String = "") -> void:
	if not (h._swiat.get("wplywy") is Array):
		h._swiat["wplywy"] = []
	var lista: Array = h._swiat["wplywy"]
	var etykieta := zrodlo
	if tekst != "" and tekst.find(":") >= 0:
		etykieta = tekst.get_slice(":", 0).strip_edges()
	lista.append({
		"zrodlo": zrodlo,
		"kwota": kwota,
		"tekst": ("%s: +%d zł" % [etykieta, kwota]) if tekst == "" else tekst,
		"rok": int(h._swiat.get("rok", 0)),
		"tydzien": int(h._swiat.get("tydzien", 0)),
	})
	# Trzymaj ostatnie ~30 wpisów.
	while lista.size() > 30:
		lista.remove_at(0)
	h._swiat["wplywy"] = lista


func _wiek_lat() -> Variant:
	var bohater := _bohater()
	if h._ui._jest_liczba(bohater.get("wiek")):
		return int(bohater["wiek"])
	if h._ui._jest_liczba(h._swiat.get("rok")):
		return int(h._swiat["rok"])
	return null


func _id_miejsca_pobytu() -> String:
	var mid = str(h._swiat.get("id_miejsca_pobytu", h._swiat.get("id_urodzenia", "")))
	if mid == "":
		var boh := _bohater()
		if boh.get("miejsce") is Dictionary:
			mid = str(boh["miejsce"].get("id", ""))
	return mid


func _opis_lokalizacji() -> String:
	var nazwa = str(h._swiat.get("nazwa_miejsca", ""))
	var gdzie = str(h._swiat.get("miejsce_pobytu", "dom"))
	if gdzie == "":
		gdzie = "dom"
	if nazwa == "":
		return gdzie
	return "%s - %s" % [nazwa, gdzie]


func _pieniadze_tekst() -> String:
	var stan = h._jedzenie.odczyt_statystyk()
	if h._ui._jest_liczba(stan.get("pieniadze")):
		return str(int(stan["pieniadze"]))
	if h._ui._jest_liczba(_bohater().get("pieniadze")):
		return str(int(_bohater()["pieniadze"]))
	return ""


func _lokum_pelne(lokum: Variant) -> bool:
	if not (lokum is Dictionary):
		return false
	if not h._ui._jest_liczba(lokum.get("wygoda")):
		return false
	# Pełny obiekt: typ + metraż (stary save miał tylko wygodę/dom_id).
	return str(lokum.get("typ", "")) != "" and h._ui._jest_liczba(lokum.get("metraz_m2"))


func _zbuduj_lokum_dla_swiata() -> Dictionary:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var miejsce: Variant = null
	var bohater: Variant = h._swiat.get("bohater", {})
	if bohater is Dictionary and bohater.get("miejsce") is Dictionary:
		miejsce = bohater["miejsce"]
	elif str(h._swiat.get("id_urodzenia", "")) != "":
		miejsce = {
			"id": str(h._swiat.get("id_urodzenia", "")),
			"nazwa": str(h._swiat.get("nazwa_urodzenia", "")),
			"typ": str(h._swiat.get("typ_urodzenia", "")),
		}
	var lokum: Dictionary = h._rynek_zakupow.zbuduj_lokum_startowe(rodzina, miejsce)
	h._swiat["rodzina"] = rodzina
	if not (h._swiat.get("majatek") is Dictionary):
		h._swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	h._swiat["majatek"]["lokum_rodziny"] = lokum.duplicate(true)
	return lokum


func _bohater() -> Dictionary:
	var bohater: Variant = h._swiat.get("bohater", {})
	if bohater is Dictionary:
		return bohater
	return {}
