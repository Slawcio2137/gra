extends RefCounted
class_name DostepAdmina

## Jedna bramka panelu admina. Przed wydaniem ustaw WLACZ_ADMINA na false.
const WLACZ_ADMINA := true
const PIN_ADMINA := "4707"
const WERSJA_WIDOCZNA := "0.10"
const STUKNIECIA_WERSJI := 7
const FPS_OPCJE: Array[int] = [30, 60, 90, 120, 0]

const NAZWY_POL := {
	"psychika": "Psychika",
	"zmeczenie_fizyczne": "Zmęczenie fizyczne",
	"zmeczenie_psychiczne": "Zmęczenie psychiczne",
	"zmeczenie": "Zmęczenie",
	"kondycja": "Kondycja",
	"zdrowie": "Zdrowie",
	"wiedza_pkt": "Wiedza",
	"pieniadze": "Pieniądze",
	"wiek": "Wiek",
	"sila": "Siła",
	"wytrzymalosc": "Wytrzymałość",
	"zwinnosc": "Zwinność",
	"szybkosc_reakcji": "Szybkość reakcji",
	"rownowaga": "Równowaga",
}


static func admin_dostepny(odblokowany_pinem: bool) -> bool:
	if not WLACZ_ADMINA:
		return false
	if OS.is_debug_build():
		return true
	return odblokowany_pinem


static func pin_pasuje(wpis: String) -> bool:
	return wpis.strip_edges() == PIN_ADMINA


static func normalizuj_fps(wartosc: int) -> int:
	if wartosc <= 0:
		return 0
	for opcja in FPS_OPCJE:
		if int(opcja) == wartosc:
			return wartosc
	return 60


static func zastosuj_fps(wartosc: int) -> int:
	var fps := normalizuj_fps(wartosc)
	Engine.max_fps = fps
	return fps


static func pola_bohatera(bohater: Dictionary, emotikony: Dictionary) -> Array:
	var out: Array = []
	var widziane := {}
	for klucz in emotikony.keys():
		var blok: Variant = emotikony[klucz]
		if blok is Dictionary and (_jest_liczba(blok.get("min")) or _jest_liczba(blok.get("norma")) or _jest_liczba(blok.get("max"))):
			_dopisz_liczbe(out, widziane, str(klucz), bohater, emotikony)
	for klucz in NAZWY_POL.keys():
		_dopisz_liczbe(out, widziane, str(klucz), bohater, emotikony)
	for klucz in bohater.keys():
		var nazwa := str(klucz)
		if widziane.has(nazwa):
			continue
		var wartosc: Variant = bohater[klucz]
		if wartosc is bool:
			out.append({"klucz": nazwa, "typ": "bool", "nazwa": nazwa, "wartosc": wartosc})
			widziane[nazwa] = true
		elif _jest_liczba(wartosc):
			_dopisz_liczbe(out, widziane, nazwa, bohater, emotikony)
	return out


static func _dopisz_liczbe(out: Array, widziane: Dictionary, klucz: String, bohater: Dictionary, emotikony: Dictionary) -> void:
	if widziane.has(klucz):
		return
	var blok: Dictionary = emotikony.get(klucz, {}) if emotikony.get(klucz) is Dictionary else {}
	var min_v := 0
	var max_v := 100
	if klucz == "pieniadze":
		max_v = 10000000
	elif klucz == "wiek":
		max_v = 120
	elif klucz == "wiedza_pkt":
		max_v = 200
	if _jest_liczba(blok.get("min")):
		min_v = int(blok["min"])
	if _jest_liczba(blok.get("max")):
		max_v = int(blok["max"])
	var wartosc := 0
	if _jest_liczba(bohater.get(klucz)):
		wartosc = int(bohater[klucz])
	elif _jest_liczba(blok.get("norma")):
		wartosc = int(blok["norma"])
	var nazwa := str(NAZWY_POL.get(klucz, blok.get("nazwa", klucz)))
	out.append({
		"klucz": klucz,
		"typ": "int",
		"nazwa": nazwa,
		"min": min_v,
		"max": max_v,
		"wartosc": wartosc,
	})
	widziane[klucz] = true


static func _jest_liczba(v: Variant) -> bool:
	return v is int or v is float
