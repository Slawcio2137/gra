extends RefCounted
class_name Sylwetka

## Sylwetka jak wprawa gotowania: etapy + X/100.

const PLIK := "res://postacie/sylwetka.json"

var dane: Dictionary = {}
var etap := 0
var punkty := 0
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var surowe: Variant = _czytaj(PLIK)
	if surowe is Dictionary:
		dane = surowe


func z_zapisu(blok: Variant) -> void:
	wczytaj()
	if not (blok is Dictionary):
		return
	etap = int(blok.get("etap", 0))
	punkty = int(blok.get("punkty", 0))


func do_zapisu() -> Dictionary:
	return {"etap": etap, "punkty": punkty, "propozycja_do_poprawki": true}


func nazwa_etapu(numer: int = -1) -> String:
	wczytaj()
	var indeks := etap if numer < 0 else numer
	var lista: Variant = dane.get("etapy", [])
	if lista is Array and indeks >= 0 and indeks < lista.size():
		return str(lista[indeks])
	return "wątła"


func cap() -> int:
	wczytaj()
	var c := int(dane.get("punkty_w_etapie_max", 100))
	return c if c > 0 else 100


func tekst_stanu() -> String:
	return "Sylwetka: %s, %d/%d" % [nazwa_etapu(), punkty, cap()]


func dodaj_za_fuche(fizyczna: bool = true) -> int:
	wczytaj()
	var postep: Dictionary = dane.get("postep", {}) if dane.get("postep") is Dictionary else {}
	var gain := int(postep.get("punkty_za_prace_fizyczna" if fizyczna else "punkty_za_fuche_domowa", 4))
	_dodaj_punkty(gain)
	return gain


func tydzien_bez_wysilku() -> int:
	wczytaj()
	var regres: Dictionary = dane.get("regres", {}) if dane.get("regres") is Dictionary else {}
	var spadek := int(regres.get("bazowy_spadek_punktow_na_tydzien", 2))
	_dodaj_punkty(-spadek)
	return spadek


func _dodaj_punkty(delta: int) -> void:
	var limit := cap()
	var lista: Variant = dane.get("etapy", [])
	var ostatni := 4
	if lista is Array and not lista.is_empty():
		ostatni = lista.size() - 1
	punkty += delta
	while punkty >= limit and etap < ostatni:
		punkty -= limit
		etap += 1
	if etap >= ostatni and punkty > limit:
		punkty = limit
	while punkty < 0 and etap > 0:
		etap -= 1
		punkty += limit
	if punkty < 0:
		punkty = 0


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
