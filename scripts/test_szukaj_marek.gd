extends SceneTree

## Headless: filtr marek po prefiksie / contains (UI checkboxów).
## godot --headless --path . --script res://scripts/test_szukaj_marek.gd

const Main = preload("res://scripts/main.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var marki: Array = ["Audi", "BMW", "Fiat", "Ford", "Toyota", "Volkswagen"]
	var wszystkie: Array = Main.marki_pasujace_do_szukania(marki, "")
	if wszystkie.size() != marki.size():
		printerr("FAIL: puste zapytanie powinno zwrócić wszystkie marki")
		return 1
	var pref: Array = Main.marki_pasujace_do_szukania(marki, "fo")
	if pref != ["Ford"]:
		printerr("FAIL: begins_with 'fo' → Ford, jest ", pref)
		return 1
	var wielkosc: Array = Main.marki_pasujace_do_szukania(marki, "AUDI")
	if wielkosc != ["Audi"]:
		printerr("FAIL: ignorowanie wielkości liter, jest ", wielkosc)
		return 1
	var zawiera: Array = Main.marki_pasujace_do_szukania(marki, "agen")
	if zawiera != ["Volkswagen"]:
		printerr("FAIL: contains 'agen' → Volkswagen, jest ", zawiera)
		return 1
	var a: Array = Main.marki_pasujace_do_szukania(marki, "a")
	if a.is_empty() or str(a[0]) != "Audi":
		printerr("FAIL: preferuj begins_with — pierwsze powinno być Audi, jest ", a)
		return 1
	print("OK szukaj marek")
	return 0
