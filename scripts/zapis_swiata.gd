extends RefCounted
class_name ZapisSwiata

## Jeden zapis świata. Start i każda tura piszą ten sam plik.

const PLIK := "user://zapis_swiata.json"


static func jest() -> bool:
	return FileAccess.file_exists(PLIK)


static func wczytaj() -> Variant:
	if not jest():
		return null
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())


static func zapisz(dane: Dictionary) -> bool:
	var plik := FileAccess.open(PLIK, FileAccess.WRITE)
	if plik == null:
		return false
	plik.store_string(JSON.stringify(dane, "\t"))
	return true
