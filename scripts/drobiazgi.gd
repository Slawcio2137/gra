extends RefCounted
class_name Drobiazgi

## Raz na turę: sito, potem jedno koło. Przy progu null zwraca nic i nie woła losuj_kolo.
## Nie wołać z _process.

const PLIK := "res://postacie/drobiazgi.json"
const _Losowanie = preload("res://scripts/losowanie.gd")

var _dane: Variant = null


func wczytaj() -> Variant:
	if _dane is Dictionary:
		return _dane
	if not FileAccess.file_exists(PLIK):
		return null
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return null
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		_dane = dane
	return dane


func losuj_ture(losowanie = null) -> Dictionary:
	var nic := {
		"wynik": "nic",
		"id": null,
		"kolo": false,
		"powod": "Dopóki szansa_ze_cokolwiek albo skala_progu jest null, funkcja zwraca nic i nie kręci koła.",
	}
	var dane: Variant = wczytaj()
	if not (dane is Dictionary):
		nic["powod"] = "Brak pliku drobiazgów."
		return nic
	var szansa: Variant = dane.get("szansa_ze_cokolwiek")
	var skala: Variant = dane.get("skala_progu")
	if szansa == null or skala == null:
		return nic
	if not _liczba(szansa) or not _liczba(skala):
		nic["powod"] = "Próg albo skala nie jest liczbą. Koła nie kręcono."
		return nic
	if float(szansa) < 0.0 or float(skala) <= 0.0 or float(szansa) > float(skala):
		nic["powod"] = "Próg nie mieści się w skali. Koła nie kręcono."
		return nic
	var los = losowanie if losowanie != null else _Losowanie.new()
	var bramka: String = los.losuj_kolo({
		"dzieje_sie": float(szansa),
		"nic": float(skala) - float(szansa),
	})
	if bramka != "dzieje_sie":
		return {"wynik": "nic", "id": null, "kolo": false, "powod": "Sito nie przepuściło puli."}
	var wagi := _wagi(dane)
	if wagi.is_empty():
		return {"wynik": null, "id": null, "kolo": false, "powod": "brak wag"}
	var id: String = los.losuj_kolo(wagi)
	if id == "":
		return {"wynik": null, "id": null, "kolo": true, "powod": "brak wag"}
	return {
		"wynik": _po_id(dane, id),
		"id": id,
		"kolo": true,
		"wagi_sa_rowne_bo_brak_zrodla": dane.get("wagi_sa_rowne_bo_brak_zrodla") == true,
		"powod": "",
	}


func _wagi(dane: Dictionary) -> Dictionary:
	var wagi := {}
	var pula: Variant = dane.get("pula", [])
	if not (pula is Array):
		return wagi
	var placeholder: bool = dane.get("wagi_sa_rowne_bo_brak_zrodla") == true
	for pozycja in pula:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		if str(pozycja.get("rodzaj", "")) == "choroba":
			continue
		var waga: Variant = pozycja.get("waga")
		if not _liczba(waga) or float(waga) < 0.0:
			continue
		if not placeholder and pozycja.get("zrodlo") == null:
			continue
		wagi[str(pozycja["id"])] = float(waga)
	return wagi


func _po_id(dane: Dictionary, id: String) -> Variant:
	var pula: Variant = dane.get("pula", [])
	if not (pula is Array):
		return null
	for pozycja in pula:
		if pozycja is Dictionary and str(pozycja.get("id", "")) == id:
			return pozycja
	return null


func _liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float
