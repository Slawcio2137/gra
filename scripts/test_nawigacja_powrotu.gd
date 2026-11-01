extends SceneTree

## Headless: stos nawigacji — Rodzina→Osoby→neutralny; po „turze” napisy, nie głęboka zakładka.
## godot --headless --path . --script res://scripts/test_nawigacja_powrotu.gd

const ScenaMain = preload("res://scenes/main.tscn")


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
	if root._losowanie == null:
		printerr("FAIL: _losowanie null po ready")
		return 1
	root._on_start_pressed()
	await process_frame
	if not root.get_node("Gra").visible:
		printerr("FAIL: Gra niewidoczna po Start")
		return 1
	var rodzina: Variant = root._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		printerr("FAIL: brak rodziny")
		return 1
	for rola in ["matka", "ojciec"]:
		var os: Variant = rodzina.get(rola, {})
		if not (os is Dictionary) or not (os.get("praca") is Dictionary) or not bool(os["praca"].get("kolo", false)):
			printerr("FAIL: brak zawodu ", rola)
			return 1
		if not (os.get("zarobki") is Dictionary) or not bool(os["zarobki"].get("kolo", false)):
			printerr("FAIL: brak zarobkow przy ", rola)
			return 1
	if not root._akcje_po_id.has("osoby"):
		printerr("FAIL: brak akcji osoby")
		return 1
	root._on_zakladka("osoby")
	await process_frame
	if root._stos.is_empty():
		printerr("FAIL: stos pusty po zakładce")
		return 1
	var osoby: Dictionary = root._akcje_po_id["osoby"]
	var dzieci: Variant = osoby.get("dzieci", [])
	var rodzina_akcja: Dictionary = {}
	if dzieci is Array:
		for d in dzieci:
			if d is Dictionary and str(d.get("tresc", "")) == "rodzina":
				rodzina_akcja = d
				break
	if rodzina_akcja.is_empty():
		printerr("FAIL: brak dziecka Rodzina")
		return 1
	root._otworz_akcje(rodzina_akcja)
	await process_frame
	if root._stos.size() < 2:
		printerr("FAIL: stos < 2 po Rodzinie ", root._stos.size())
		return 1
	if not root.get_node("Powrot").visible:
		printerr("FAIL: Powrot niewidoczny w zagłębieniu")
		return 1
	root._on_powrot()
	await process_frame
	if root._stos.size() != 1:
		printerr("FAIL: po 1. powrocie stos!=1 ", root._stos.size())
		return 1
	root._on_powrot()
	await process_frame
	if not root._stos.is_empty():
		printerr("FAIL: po 2. powrocie stos niepusty ", root._stos.size())
		return 1
	if root._zakladka_id != "":
		printerr("FAIL: zakladka_id nie wyczyszczona: ", root._zakladka_id)
		return 1
	if root.get_node("Powrot").visible:
		printerr("FAIL: Powrot widoczny na neutralnym")
		return 1
	root._on_zakladka("osoby")
	root._otworz_akcje(rodzina_akcja)
	await process_frame
	root._on_nastepna_tura()
	await process_frame
	if not root._stos.is_empty():
		printerr("FAIL: po turze stos niepusty")
		return 1
	if root._zakladka_id != "":
		printerr("FAIL: po turze zakładka żywa")
		return 1
	var tytul: Label = root._tytul_bialy()
	if tytul == null or str(tytul.text) != "W tym tygodniu":
		printerr("FAIL: po turze tytuł nie 'W tym tygodniu' jest=", tytul.text if tytul else "?")
		return 1

	# Hierarchia Zakupy → Samochody → (powrót) → Zakupy → główny — nie dowolna historia kliknięć.
	root._on_zakladka("zakupy")
	await process_frame
	if root._stos.size() != 1 or str(root._stos[0].get("id", "")) != "zakupy":
		printerr("FAIL: stos po Zakupach=", root._stos)
		return 1
	root._wejdz_w_kategorie_zakupow({"id": "samochod", "nazwa": "Samochód", "stan_uzywany_nowy": true})
	await process_frame
	if root._stos.size() != 3:
		printerr("FAIL: stos po Samochodzie != 3 (Zakupy/grupa/auto) jest=", root._stos.size())
		return 1
	if str(root._stos[0].get("id", "")) != "zakupy":
		printerr("FAIL: rodzic nie Zakupy: ", root._stos[0])
		return 1
	if str(root._stos[1].get("tresc", "")) != "zakupy_grupa":
		printerr("FAIL: brak grupy Środki transportu: ", root._stos[1])
		return 1
	if str(root._stos[2].get("tresc", "")) != "zakupy_kategoria":
		printerr("FAIL: brak kategorii na stosie: ", root._stos[2])
		return 1
	# Skok „obok” hierarchii (Mapa) nie dokleja do Zakupów — ustawia ścieżkę rodziców Mapa.
	root._otworz_akcje({"id": "mapa", "nazwa": "Mapa", "tryb": "ekran", "tresc": "mapa"})
	await process_frame
	if root._stos.is_empty() or str(root._stos[root._stos.size() - 1].get("id", "")) != "mapa":
		printerr("FAIL: mapa nie na szczycie ", root._stos)
		return 1
	for wpis in root._stos:
		if wpis is Dictionary and str(wpis.get("id", "")) == "zakupy":
			printerr("FAIL: Zakupy zostały w stosie po skoku do Mapy (to nie hierarchia)")
			return 1
	root._on_powrot()
	await process_frame
	root._on_powrot()
	await process_frame
	root._on_powrot()
	await process_frame
	if not root._stos.is_empty():
		printerr("FAIL: po powrotach z mapy stos niepusty ", root._stos.size())
		return 1
	print("OK nawigacja + napisy po turze + zarobki rodziców + hierarchia Zakupy/Samochód/Mapa")
	return 0
