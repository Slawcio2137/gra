extends SceneTree

## Headless: eventy Tak/Nie, kieszonkowe snap, kategorie zakupów.
## godot --headless --path . --script res://scripts/test_eventy_zakupy.gd

const EventySkrypt = preload("res://scripts/eventy_odkrycia.gd")
const ZiarnoSkrypt = preload("res://scripts/ziarno_rodzicow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var eventy = EventySkrypt.new()
	var dane: Variant = eventy.wczytaj()
	if not (dane is Dictionary) or not (dane.get("pula") is Array):
		printerr("FAIL: brak puli eventow")
		return 1
	var ids: Array = []
	for e in dane["pula"]:
		if e is Dictionary:
			ids.append(str(e.get("id", "")))
	for wymagane in ["zakupy_z_matka", "pomoc_w_gotowaniu", "nauka_czytania", "awaria_pradu"]:
		if not ids.has(wymagane):
			printerr("FAIL: brak eventu ", wymagane)
			return 1
	if ids.has(""):
		printerr("FAIL: pusty id")
		return 1
	# Punkt 5 pominięty — nie ma pustego id.
	var wyl: Array = eventy.losuj_ture({"wiek": 8, "jedynak": true, "flagi": {}, "ma": {"pieniadze": true}, "cechy_rodzicow": ["hojny"]}, null)
	print("OK eventy wylosowane=", wyl.size())
	for ev in wyl:
		if not (ev is Dictionary):
			continue
		print("  event=", ev.get("id"), " pytanie=", ev.get("pytanie"))
		if bool(ev.get("pytanie", false)):
			var odp: Dictionary = eventy.zastosuj_wybor(ev, "tak", {"cechy_rodzicow": ["hojny"], "przedzial_zarobkow": ""})
			if str(odp.get("tekst", "")) == "":
				printerr("FAIL: pusta odpowiedz Tak")
				return 1
			print("  Tak -> ", odp.get("tekst"))

	var ziarno = ZiarnoSkrypt.new()
	if ziarno._snap_kwoty_kieszonkowej(null, 35) == 35:
		printerr("FAIL: snap 35")
		return 1

	if not FileAccess.file_exists("res://postacie/zakupy_oferty.json"):
		printerr("FAIL: brak zakupy_oferty.json")
		return 1
	var plik := FileAccess.open("res://postacie/zakupy_oferty.json", FileAccess.READ)
	var zak: Variant = JSON.parse_string(plik.get_as_text())
	if not (zak is Dictionary) or not (zak.get("kategorie") is Array):
		printerr("FAIL: kategorie zakupow")
		return 1
	var kat_ids: Array = []
	for k in zak["kategorie"]:
		if k is Dictionary:
			kat_ids.append(str(k.get("id", "")))
	for kid in ["telefon", "samochod", "dom", "mieszkanie", "drobiazgi", "rower"]:
		if not kat_ids.has(kid):
			printerr("FAIL: brak kategorii ", kid)
			return 1
	# Dom ma surowy; mieszkanie nie. Stany: do_remontu / do_odswiezenia / po_remoncie.
	var dom_ok := false
	var miesz_surowy := false
	var miesz_odsw := false
	for k in zak["kategorie"]:
		if not (k is Dictionary):
			continue
		if str(k.get("id")) == "dom" and k.get("stany_nieruchomosci") is Array and k["stany_nieruchomosci"].has("surowy"):
			dom_ok = true
		if str(k.get("id")) == "mieszkanie" and k.get("stany_nieruchomosci") is Array:
			if k["stany_nieruchomosci"].has("surowy"):
				miesz_surowy = true
			if k["stany_nieruchomosci"].has("do_odswiezenia"):
				miesz_odsw = true
	if not dom_ok or miesz_surowy or not miesz_odsw:
		printerr("FAIL: stany domu/mieszkania")
		return 1
	if not (zak.get("pule_marek") is Dictionary):
		printerr("FAIL: brak pul marek")
		return 1
	print("OK kategorie=", kat_ids.size(), " generator+pule (oferty statyczne=", (zak["oferty"] as Array).size() if zak.get("oferty") is Array else 0, ")")

	# Jakość zdrowotna poza domem w JSON.
	var jed_plik := FileAccess.open("res://postacie/jedzenie_ustawienia.json", FileAccess.READ)
	var jed: Variant = JSON.parse_string(jed_plik.get_as_text())
	if not (jed is Dictionary) or not (jed.get("jakosc_zdrowotna_poza_domem") is Dictionary):
		printerr("FAIL: brak jakosc_zdrowotna_poza_domem")
		return 1
	print("OK jakosc_zdrowotna_poza_domem (przed: nie bylo; teraz jest)")
	return 0
