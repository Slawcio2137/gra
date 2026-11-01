extends RefCounted
class_name KatalogZawodow

## Odczyt katalogu KZiS. Nie losuje zawodu 6-cyfrowego — nie ma do tego wag.

const PLIK := "res://postacie/katalog_zawodow.json"

static var _dane: Dictionary = {}
static var _po_kodzie: Dictionary = {}
static var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		_dane = s
	for klucz in ["zawody", "grupy"]:
		var lista: Variant = _dane.get(klucz, [])
		if not (lista is Array):
			continue
		for p in lista:
			if p is Dictionary:
				_po_kodzie[str(p.get("kod", ""))] = p


func dane() -> Dictionary:
	wczytaj()
	return _dane


func liczba_zawodow() -> int:
	wczytaj()
	if _dane.get("zawody") is Array:
		return (_dane["zawody"] as Array).size()
	return 0


func po_kodzie(kod: String) -> Dictionary:
	wczytaj()
	var z: Variant = _po_kodzie.get(kod, {})
	return z if z is Dictionary else {}


## Dopina kod grupy KZiS i efekty tygodniowe, gdy cała grupa ma jeden profil.
## Nie zmienia wylosowanej nazwy ani płacy z GUS.
func dopnij_prace(praca: Dictionary) -> void:
	if not bool(praca.get("kolo", false)):
		return
	wczytaj()
	var kod := kod_z_isco(str(praca.get("isco08", "")))
	if kod == "":
		kod = kod_z_isco(str(praca.get("grupa_isco08", "")))
	praca["katalog_kzis"] = kod if kod != "" else null
	if kod == "" or not _po_kodzie.has(kod):
		praca["efekty_tygodniowe"] = null
		praca["efekty_uwaga"] = "Brak tej grupy w katalogu KZiS."
		return
	var grupa: Dictionary = _po_kodzie[kod]
	if bool(grupa.get("profil_jednolity", false)) and grupa.get("efekty_tygodniowe") is Dictionary:
		praca["profil"] = str(grupa.get("profil", ""))
		praca["efekty_tygodniowe"] = (grupa["efekty_tygodniowe"] as Dictionary).duplicate(true)
		praca["efekty_uwaga"] = "Efekty z katalogu KZiS dla jednolitej grupy. Propozycja, nie GUS."
		return
	praca["profil"] = null
	praca["efekty_tygodniowe"] = null
	praca["efekty_uwaga"] = "Grupa KZiS miesza profile. Efekty są przy zawodach 6-cyfrowych, nie jedną liczbą dla całej grupy."


func kod_z_isco(isco: String) -> String:
	var s := isco.strip_edges().to_upper()
	if s.begins_with("OC"):
		s = s.substr(2)
	if s.is_valid_int() and s.length() >= 1 and s.length() <= 6:
		return s
	return ""


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
