extends SceneTree

## Jedna kasa: zakup telefonu schodzi z paska, wypłata dokłada do tej samej kwoty,
## zapis i wczytanie jej nie gubią. Stary zrzut jedzenia nie przebija bohatera.
## godot --headless --path . --script res://scripts/test_wspolna_kasa.gd

const ScenaMain = preload("res://scenes/main.tscn")
const Zapis = preload("res://scripts/zapis_swiata.gd")


func _init() -> void:
	call_deferred("_odpal")


func _odpal() -> void:
	var kod := await _uruchom()
	quit(kod)


func _uruchom() -> int:
	var root := ScenaMain.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	root._on_start_pressed()
	await process_frame
	root._stan._ustaw_kase(5000)
	if not (root._swiat.get("rynek_zakupow") is Dictionary):
		root._swiat["rynek_zakupow"] = {}
	root._swiat["rynek_zakupow"]["oferty"] = [{
		"id": "telefon_test",
		"kategoria": "telefon",
		"stan": "uzywany",
		"cena_zl": 800,
		"sposob_odbioru": "osobisty",
		"nieruchomosc": false,
	}]
	if not (root._swiat.get("majatek") is Dictionary):
		root._swiat["majatek"] = {"dobra": [], "nieruchomosci": []}
	var kupno: Dictionary = root._rynek_zakupow.kup(root._swiat, "telefon_test")
	if not bool(kupno.get("ok", false)):
		printerr("FAIL: zakup ", kupno)
		return 1
	root._stan._zsynchronizuj_pieniadze_z_bohatera()
	root._pasek._odswiez_pasek_statystyk(false)
	if root._pieniadze_lbl.text != "4200" or int(root._stan._kasa()) != 4200:
		printerr("FAIL: po zakupie pasek=", root._pieniadze_lbl.text, " kasa=", root._stan._kasa())
		return 1
	if int(root._jedzenie.odczyt_statystyk().get("pieniadze")) != 4200:
		printerr("FAIL: jedzenie nie czyta kasy ", root._jedzenie.odczyt_statystyk().get("pieniadze"))
		return 1
	root._stan._dodaj_pieniadze(10)
	root._pasek._odswiez_pasek_statystyk(false)
	if root._pieniadze_lbl.text != "4210" or int(root._stan._kasa()) != 4210:
		printerr("FAIL: po +10 pasek=", root._pieniadze_lbl.text, " kasa=", root._stan._kasa())
		return 1
	var wydane: Dictionary = root._jedzenie._zjedz_raz("test", {"cena_zl": 10, "gdzie": "dom", "nazwa": "test"})
	if not bool(wydane.get("kupiono", false)) or int(root._stan._kasa()) != 4200:
		printerr("FAIL: wydatek jedzenia ", wydane, " kasa=", root._stan._kasa())
		return 1
	root._stan._dodaj_pieniadze(10)
	# Stary zrzut jedzenia z inną kwotą nie może przebić bohatera.
	var zrzut: Dictionary = root._jedzenie.zrzut_zapisu()
	zrzut["pieniadze"] = 9999
	zrzut["pieniadze_znane"] = true
	root._swiat["jedzenie"] = zrzut
	if not Zapis.zapisz(root._swiat):
		printerr("FAIL: zapis")
		return 1
	root._stan._ustaw_kase(1)
	root._on_wczytaj_pressed()
	await process_frame
	if root._pieniadze_lbl.text != "4210" or int(root._stan._kasa()) != 4210:
		printerr("FAIL: po wczytaniu pasek=", root._pieniadze_lbl.text, " kasa=", root._stan._kasa())
		return 1
	# Bohater bez liczby: zostaje kwota ze starego zrzutu jedzenia.
	root._swiat["bohater"]["pieniadze"] = null
	root._stan._przejmij_kase_ze_zrzutu({"pieniadze": 777, "pieniadze_znane": true})
	if int(root._stan._kasa()) != 777:
		printerr("FAIL: stary zrzut nie wszedł ", root._stan._kasa())
		return 1
	root._stan._ustaw_kase(4210)
	root._stan._przejmij_kase_ze_zrzutu({"pieniadze": 1, "pieniadze_znane": true})
	if int(root._stan._kasa()) != 4210:
		printerr("FAIL: zrzut przebił bohatera ", root._stan._kasa())
		return 1
	print("OK wspólna kasa: zakup 800, +10, jedzenie, zapis 4210")
	return 0
