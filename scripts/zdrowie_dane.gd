extends RefCounted

const PLIKI := {
	"choroby": "res://postacie/zdrowie/choroby.json",
	"czynniki": "res://postacie/zdrowie/czynniki.json",
	"wypadki": "res://postacie/zdrowie/wypadki.json",
	"urazy": "res://postacie/zdrowie/urazy.json",
	"uczulenia": "res://postacie/zdrowie/uczulenia.json",
	"choroby_przenoszone_droga_plciowa": "res://postacie/zdrowie/choroby_przenoszone_droga_plciowa.json",
	"od_urodzenia": "res://postacie/zdrowie/od_urodzenia.json",
	"szanse_urodzenia": "res://postacie/zdrowie/szanse_urodzenia.json",
	"ceny_pomocy": "res://postacie/zdrowie/ceny_pomocy.json",
	"kraj_warunki": "res://postacie/zdrowie/kraj_warunki.json",
	"choroby_psychiczne": "res://postacie/zdrowie/choroby_psychiczne.json",
	"problemy_rodzinne": "res://postacie/zdrowie/problemy_rodzinne.json",
	"wyglad": "res://postacie/zdrowie/wyglad.json",
}


func wczytaj() -> Dictionary:
	var wynik := {}
	for klucz in PLIKI:
		var dane: Variant = _czytaj_json(str(PLIKI[klucz]))
		wynik[klucz] = {
			"dane": dane,
			"po_id": _po_id(dane),
		}
	return wynik


func _czytaj_json(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	var tekst := plik.get_as_text()
	return JSON.parse_string(tekst)


func _po_id(dane: Variant) -> Dictionary:
	var po_id := {}
	if dane is Dictionary:
		for wartosc in dane.values():
			_dopisz(wartosc, po_id)
	elif dane is Array:
		_dopisz(dane, po_id)
	return po_id


func _dopisz(wartosc: Variant, po_id: Dictionary) -> void:
	if wartosc is Array:
		for element in wartosc:
			if element is Dictionary and element.has("id"):
				po_id[str(element["id"])] = element
	elif wartosc is Dictionary:
		for zagniezdzona in wartosc.values():
			if zagniezdzona is Array:
				_dopisz(zagniezdzona, po_id)
