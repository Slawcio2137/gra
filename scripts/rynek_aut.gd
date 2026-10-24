extends RefCounted
class_name RynekAut

## Oferta zależy od salonu i ziarna. Bez powtórzeń na jednej półce.
## Wagi bez źródła zostają null. Bez paczki obrazek to szary znak zapytania.
## Nie pobiera nic z sieci i nie liczy nic co klatkę.

const PLIK := "res://pojazdy/rynek_aut.json"
const PLIK_OBRAZKOW := "res://pojazdy/obrazki_aut.json"
const PLACEHOLDER := "szary_znak_zapytania"
const PLIK_ZNAKU := "res://grafika/znak_zapytania.png"
const _Losowanie = preload("res://scripts/losowanie.gd")

var _rynek: Variant = null
var _manifest: Variant = null


func oferty(salon_id: String, ziarno: int, ile: int = 5, paczka_nadpisanie: Variant = null) -> Dictionary:
	var pobrana := paczka_pobrana()
	if paczka_nadpisanie is bool:
		pobrana = paczka_nadpisanie
	return dobierz(_wczytaj(), salon_id, ziarno, ile, pobrana)


func paczka_pobrana() -> bool:
	var manifest: Variant = _wczytaj_manifest()
	if manifest is Dictionary:
		return manifest.get("pobrane") == true
	return false


func dobierz(rynek: Variant, salon_id: String, ziarno: int, ile: int, paczka_pobrana: bool = false) -> Dictionary:
	var wynik := {
		"wynik": null,
		"salon_id": salon_id,
		"ziarno": ziarno,
		"komentarz": "Różne auta w salonie przyjdą z danymi paczki, obrazek osobno.",
		"bez_powtorzen": true,
		"paczka_pobrana": paczka_pobrana,
		"obraz_bez_paczki": PLACEHOLDER,
	}
	if not (rynek is Dictionary):
		wynik["komentarz"] = "Brak danych rynku. Różne auta w salonie przyjdą z danymi paczki, obrazek osobno."
		return wynik
	if not _salon_jest(rynek, salon_id):
		wynik["komentarz"] = "Nie ma salonu o tym id. Oferta zależy od salonu."
		return wynik
	var swoje := _rekordy_salonu(rynek, salon_id)
	if swoje.is_empty():
		wynik["komentarz"] = "Różne auta w salonie przyjdą z danymi paczki, obrazek osobno. Na tej półce nie ma rekordów."
		return wynik
	var wagi := {}
	var po_id := {}
	for rekord in swoje:
		var id := str(rekord.get("id", ""))
		po_id[id] = rekord
		var waga: Variant = rekord.get("waga")
		if not (waga is int or waga is float) or float(waga) < 0.0:
			continue
		if rekord.get("zrodlo") == null:
			continue
		wagi[id] = float(waga)
	if wagi.is_empty():
		wynik["komentarz"] = "Różne auta w salonie przyjdą z danymi paczki, obrazek osobno. Brak wag."
		return wynik
	var limit := ile
	if limit < 0:
		limit = 0
	if limit > wagi.size():
		limit = wagi.size()
	var los = _Losowanie.new()
	var generator := RandomNumberGenerator.new()
	generator.seed = ziarno
	var pack := _id_paczki(rynek)
	var lista: Array = []
	var juz := {}
	for _i in limit:
		var id: String = los.losuj_kolo(wagi, generator)
		if id == "" or juz.has(id):
			break
		juz[id] = true
		wagi.erase(id)
		lista.append(_widok(po_id[id], paczka_pobrana, pack))
	wynik["wynik"] = lista
	wynik["komentarz"] = ""
	return wynik


func _rekordy_salonu(rynek: Dictionary, salon_id: String) -> Array:
	var lista: Array = []
	var widziane := {}
	var rekordy: Variant = rynek.get("rekordy", [])
	if not (rekordy is Array):
		return lista
	for rekord in rekordy:
		if not (rekord is Dictionary):
			continue
		if str(rekord.get("salon_id", "")) != salon_id:
			continue
		var id: Variant = rekord.get("id")
		if id == null or str(id) == "":
			continue
		var klucz := str(id)
		if widziane.has(klucz):
			continue
		widziane[klucz] = true
		lista.append(rekord)
	return lista


func _widok(rekord: Dictionary, paczka_pobrana: bool, pack: String) -> Dictionary:
	return {
		"id": rekord.get("id"),
		"salon_id": rekord.get("salon_id"),
		"marka": rekord.get("marka"),
		"model": rekord.get("model"),
		"klasa_nadwozia": rekord.get("klasa_nadwozia"),
		"paliwo": rekord.get("paliwo"),
		"rok": rekord.get("rok"),
		"przebieg": rekord.get("przebieg"),
		"przebieg_km": rekord.get("przebieg_km", rekord.get("przebieg")),
		"stan": rekord.get("stan"),
		"stan_rzeczywisty": rekord.get("stan_rzeczywisty"),
		"stan_deklarowany": rekord.get("stan_deklarowany"),
		"spalanie": rekord.get("spalanie", null),
		"cena": rekord.get("cena", null),
		"waga": rekord.get("waga"),
		"zrodlo": rekord.get("zrodlo"),
		"obraz": _obraz(rekord, paczka_pobrana, pack),
		"nazwa_zostaje": true,
		"statystyki_zostaja": true,
		"cena_zostaje": true,
	}


func _obraz(rekord: Dictionary, paczka_pobrana: bool, pack: String) -> Dictionary:
	var obrazek: Dictionary = {}
	if rekord.get("obrazek") is Dictionary:
		obrazek = rekord["obrazek"]
	var placeholder := str(obrazek.get("placeholder", PLACEHOLDER))
	if placeholder == "":
		placeholder = PLACEHOLDER
	var id_paczki := str(obrazek.get("paczka_offline", pack))
	var plik_paczki: Variant = obrazek.get("plik_paczki")
	if paczka_pobrana and plik_paczki != null and str(plik_paczki) != "":
		return {
			"wyswietl": "plik_paczki",
			"plik": str(plik_paczki),
			"placeholder": placeholder,
			"paczka_offline": id_paczki,
			"pobrana": true,
		}
	return {
		"wyswietl": placeholder,
		"plik": PLIK_ZNAKU,
		"placeholder": placeholder,
		"paczka_offline": id_paczki,
		"pobrana": false,
	}


func _salon_jest(rynek: Dictionary, salon_id: String) -> bool:
	if salon_id == "":
		return false
	var salony: Variant = rynek.get("salony", [])
	if not (salony is Array):
		return false
	for salon in salony:
		if salon is Dictionary and str(salon.get("id", "")) == salon_id:
			return true
	return false


func _id_paczki(rynek: Dictionary) -> String:
	var paczka: Variant = rynek.get("paczka_offline", {})
	if paczka is Dictionary and str(paczka.get("id", "")) != "":
		return str(paczka.get("id"))
	var obrazek: Variant = rynek.get("obrazek", {})
	if obrazek is Dictionary:
		return str(obrazek.get("paczka_offline", ""))
	return ""


func _wczytaj() -> Variant:
	if _rynek is Dictionary:
		return _rynek
	_rynek = _czytaj(PLIK)
	return _rynek


func _wczytaj_manifest() -> Variant:
	if _manifest is Dictionary:
		return _manifest
	_manifest = _czytaj(PLIK_OBRAZKOW)
	return _manifest


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
