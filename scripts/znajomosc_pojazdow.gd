extends RefCounted
class_name ZnajomoscPojazdow

## Jak wprawa gotowania, ale nie spada — tylko rośnie.
## JSON: postacie/znajomosc_pojazdow.json

const PLIK := "res://postacie/znajomosc_pojazdow.json"

var dane: Dictionary = {}
var etap := 0
var punkty := 0
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	if not FileAccess.file_exists(PLIK):
		dane = {}
		return
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		dane = {}
		return
	var surowe: Variant = JSON.parse_string(plik.get_as_text())
	if surowe is Dictionary:
		dane = surowe
	else:
		dane = {}


func nazwa_etapu(numer: int = -1) -> String:
	wczytaj()
	var indeks := etap if numer < 0 else numer
	var lista: Variant = dane.get("etapy", [])
	if lista is Array and indeks >= 0 and indeks < lista.size():
		return str(lista[indeks])
	return "brak doświadczenia"


func poziom_0_100() -> int:
	wczytaj()
	var cap := float(dane.get("punkty_w_etapie_max", 100))
	if cap <= 0.0:
		cap = 100.0
	var etapy: Array = dane.get("etapy", []) if dane.get("etapy") is Array else []
	var max_etap := maxi(0, etapy.size() - 1)
	if max_etap <= 0:
		return clampi(int(round(float(punkty) / cap * 100.0)), 0, 100)
	var frakcja := (float(etap) + float(punkty) / cap) / float(max_etap)
	return clampi(int(round(frakcja * 100.0)), 0, 100)


func mnoznik_inteligencji(int_logiczna: float) -> float:
	wczytaj()
	var blok: Dictionary = dane.get("inteligencja_logiczna", {}) if dane.get("inteligencja_logiczna") is Dictionary else {}
	var baza := float(blok.get("baza", 50))
	var dzielnik := float(blok.get("dzielnik", 200))
	if dzielnik <= 0.0:
		dzielnik = 200.0
	var m := 1.0 + (int_logiczna - baza) / dzielnik
	return clampf(m, float(blok.get("mnoznik_min", 0.75)), float(blok.get("mnoznik_max", 1.4)))


func dodaj_punkty(ile: int, int_logiczna: float = 50.0) -> Dictionary:
	wczytaj()
	if ile <= 0:
		return {"przybylo": 0, "etap": nazwa_etapu(), "poziom_0_100": poziom_0_100()}
	var gain := int(round(float(ile) * mnoznik_inteligencji(int_logiczna)))
	_dodaj_surowe(gain)
	return {
		"przybylo": gain,
		"etap": nazwa_etapu(),
		"poziom_0_100": poziom_0_100(),
		"nie_spada": true,
		"propozycja_do_poprawki": true,
	}


func research_telefon(int_logiczna: float = 50.0) -> Dictionary:
	wczytaj()
	var p := int(_blok_postep().get("punkty_za_research_telefon", 2))
	return dodaj_punkty(p, int_logiczna)


func ogledziny(int_logiczna: float = 50.0) -> Dictionary:
	wczytaj()
	var p := int(_blok_postep().get("punkty_za_ogledziny", 4))
	return dodaj_punkty(p, int_logiczna)


func doswiadczenie_zakupu(int_logiczna: float = 50.0) -> Dictionary:
	wczytaj()
	var p := int(_blok_postep().get("punkty_za_zakup_doswiadczenie", 3))
	return dodaj_punkty(p, int_logiczna)


func tydzien_szkoly_mechanik(int_logiczna: float = 50.0) -> Dictionary:
	wczytaj()
	var p := int(_blok_postep().get("punkty_za_tydzien_szkoly_mechanik", 6))
	return dodaj_punkty(p, int_logiczna)


func serializuj() -> Dictionary:
	return {"etap": etap, "punkty": punkty, "poziom_0_100": poziom_0_100()}


func wczytaj_ze_stanu(stan: Dictionary) -> void:
	wczytaj()
	etap = int(stan.get("etap", 0))
	punkty = int(stan.get("punkty", 0))


func _blok_postep() -> Dictionary:
	if dane.get("postep") is Dictionary:
		return dane["postep"]
	return {}


func _dodaj_surowe(gain: int) -> void:
	var cap := int(dane.get("punkty_w_etapie_max", 100))
	if cap <= 0:
		cap = 100
	var etapy: Array = dane.get("etapy", []) if dane.get("etapy") is Array else []
	var max_etap := maxi(0, etapy.size() - 1)
	var zostaje := int(dane.get("na_ostatnim_etapie_zostaje", cap))
	punkty += gain
	while punkty >= cap and etap < max_etap:
		punkty -= cap
		etap += 1
	if etap >= max_etap:
		etap = max_etap
		punkty = mini(punkty, zostaje)
