extends SceneTree

## Grupy Zakupów, scroll palcem, zwijana rodzina, zarobki ≤3 cyfry znaczące (zwykle 2).
## godot --headless --path . --script res://scripts/test_grupy_scroll_zarobki.gd

const ScenaMain = preload("res://scenes/main.tscn")
const Zaokr = preload("res://scripts/zaokraglenie_zarobkow.gd")
const Rynek = preload("res://scripts/rynek_zakupow.gd")

const SCROLL := "Gra/Margines/Kolumna/BialyEkran/MarginesBialy/KolumnaBiala/ScrollBialy"


func _init() -> void:
	call_deferred("_odpal")


func _odpal() -> void:
	var kod := await _uruchom()
	quit(kod)


func _uruchom() -> int:
	if _zaokraglenia() != 0:
		return 1
	var root := ScenaMain.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	if root._losowanie == null:
		printerr("FAIL: brak losowania")
		return 1
	root._on_start_pressed()
	await process_frame
	var rodzina: Dictionary = root._swiat.get("rodzina", {})
	if _cyfry_w_rodzinie(rodzina) != 0:
		return 1
	if await _zakupy(root) != 0:
		return 1
	if await _rodzina_ui(root, rodzina) != 0:
		return 1
	if await _scroll(root) != 0:
		return 1
	print("OK grupy zakupów + scroll + rodzina zwijana + zarobki 2 cyfry")
	return 0


func _zaokraglenia() -> int:
	if Zaokr.zaokraglij(4537) != 4500:
		printerr("FAIL: 4537 → ", Zaokr.zaokraglij(4537))
		return 1
	if Zaokr.zaokraglij(12800) != 13000:
		printerr("FAIL: 12800 → ", Zaokr.zaokraglij(12800))
		return 1
	if Zaokr.zaokraglij(875) != 880:
		printerr("FAIL: 875 → ", Zaokr.zaokraglij(875))
		return 1
	if Zaokr.zaokraglij(85) != 85:
		printerr("FAIL: 85 → ", Zaokr.zaokraglij(85))
		return 1
	if Zaokr.zaokraglij(12500) != 13000:
		printerr("FAIL: 12500 powinno iść w 2 cyfry → 13000, jest ", Zaokr.zaokraglij(12500))
		return 1
	for n in [1, 8, 85, 880, 4500, 13000, 100000]:
		var z := Zaokr.zaokraglij(n)
		if Zaokr.cyfry_znaczace(z) > 3:
			printerr("FAIL: więcej niż 3 cyfry ", n, " → ", z)
			return 1
	var blok := {"kolo": true, "od_zl": 4537, "do_zl": 12347}
	var txt := str(Zaokr.tekst(blok))
	if txt != "4500–12000 zł":
		printerr("FAIL: tekst zarobków ", txt, " blok=", blok)
		return 1
	if int(blok["od_zl"]) != 4500 or int(blok["do_zl"]) != 12000:
		printerr("FAIL: zapis nie równa się ekranowi ", blok)
		return 1
	if str(blok.get("zaokraglenie", "")) != "2_cyfry_znaczace":
		printerr("FAIL: brak adnotacji zaokrąglenia")
		return 1
	var rynek = Rynek.new()
	var cena_auta := rynek.zaokraglij_cene("samochod", 4537)
	if cena_auta == 4500:
		printerr("FAIL: cena auta dostała regułę zarobków")
		return 1
	if cena_auta != 4540:
		printerr("FAIL: cena auta 4537 powinna zostać przy 3 cyfrach (4540), jest ", cena_auta)
		return 1
	print("OK zaokrąglenie 4537→4500, 12800→13000, 875→880; auto 4537→", cena_auta)
	return 0


func _cyfry_w_rodzinie(rodzina: Dictionary) -> int:
	var bloki: Array = [rodzina.get("zarobki", {})]
	for rola in ["matka", "ojciec"]:
		var os: Variant = rodzina.get(rola, {})
		if os is Dictionary:
			bloki.append(os.get("zarobki", {}))
	var dziad: Variant = rodzina.get("dziadkowie", {})
	if dziad is Dictionary and dziad.get("lista") is Array:
		for o in dziad["lista"]:
			if o is Dictionary:
				bloki.append(o.get("zarobki", {}))
	for blok in bloki:
		if not (blok is Dictionary) or not bool(blok.get("kolo", false)):
			continue
		for klucz in ["od_zl", "do_zl", "mediana_zl", "przecietne_zl"]:
			var v: Variant = blok.get(klucz, null)
			if not (v is int or v is float):
				continue
			if Zaokr.cyfry_znaczace(int(v)) > 3:
				printerr("FAIL: zarobki w zapisie mają za dużo cyfr ", klucz, "=", v)
				return 1
			if int(v) != Zaokr.zaokraglij(v):
				printerr("FAIL: zapisane zarobki nie są dociągnięte do 2 cyfr ", klucz, "=", v)
				return 1
	print("OK zarobki rodziny w zapisie ≤3 cyfry znaczące")
	return 0


func _zakupy(root) -> int:
	root._on_zakladka("zakupy")
	await process_frame
	var teksty := _teksty_przyciskow(root._tresc_biala())
	for wymagany in ["Środki transportu", "Elektronika"]:
		if not teksty.has(wymagany):
			printerr("FAIL: brak grupy na liście Zakupów ", wymagany, " jest=", teksty)
			return 1
	for ukryty in ["Samochód", "Rower", "Samolot", "Śmigłowiec", "Telefon", "Komputer", "Laptop", "Sprzęt"]:
		if teksty.has(ukryty):
			printerr("FAIL: ", ukryty, " jest na płaskiej liście Zakupów ", teksty)
			return 1
	if not teksty.has("Dom") or not teksty.has("Drobiazgi (budżet jakości)"):
		printerr("FAIL: zniknął sklep spoza grup ", teksty)
		return 1
	var przyciski := _przyciski(root._tresc_biala())
	if przyciski.is_empty() or (przyciski[0] as Button).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		printerr("FAIL: przycisk listy zjada gest, filtr=", przyciski[0].mouse_filter if not przyciski.is_empty() else "brak")
		return 1
	var btn0: Button = przyciski[0]
	var srodek := btn0.get_global_rect().get_center()
	if srodek == Vector2.ZERO:
		printerr("FAIL: przycisk grupy nie ma prostokąta na ekranie")
		return 1
	var wierzch := _kontrolka_pod_palcem(root, srodek)
	var scroll_tap: ScrollContainer = root.get_node(SCROLL)
	if wierzch != scroll_tap:
		printerr("FAIL: palec nie trafia w ScrollBialy, tylko w ", wierzch)
		return 1
	var lokalnie: Vector2 = scroll_tap.get_global_transform_with_canvas().affine_inverse() * srodek
	var stos_przed_stuk: int = int(root._stos.size())
	var wdol := InputEventMouseButton.new()
	wdol.button_index = MOUSE_BUTTON_LEFT
	wdol.pressed = true
	wdol.position = lokalnie
	scroll_tap._gui_input(wdol)
	var wgore := InputEventMouseButton.new()
	wgore.button_index = MOUSE_BUTTON_LEFT
	wgore.pressed = false
	wgore.position = lokalnie
	scroll_tap._gui_input(wgore)
	await process_frame
	await process_frame
	if int(root._stos.size()) <= stos_przed_stuk:
		printerr("FAIL: stuknięcie w grupę nie weszło głębiej, stos=", root._stos.size(), " lokalnie=", lokalnie)
		return 1
	root._on_powrot()
	await process_frame
	root._wejdz_w_grupe_zakupow({
		"id": "srodki_transportu",
		"nazwa": "Środki transportu",
		"kategorie": ["samochod", "rower", "samolot", "smiglowiec_bojowy"],
		"nazwy_wyboru": {"smiglowiec_bojowy": "Śmigłowiec"},
	})
	await process_frame
	var transport := _teksty_przyciskow(root._tresc_biala())
	for wybor in ["Samochód", "Rower", "Samolot", "Śmigłowiec"]:
		if not transport.has(wybor):
			printerr("FAIL: Środki transportu bez ", wybor, " jest=", transport)
			return 1
	if transport.has("Śmigłowiec bojowy"):
		printerr("FAIL: wybór ma starą nazwę bojową zamiast Śmigłowiec")
		return 1
	root._wejdz_w_grupe_zakupow({
		"id": "elektronika",
		"nazwa": "Elektronika",
		"kategorie": ["telefon", "komputer", "laptop", "sprzet"],
	})
	await process_frame
	var elektro := _teksty_przyciskow(root._tresc_biala())
	for wybor2 in ["Telefon", "Komputer", "Laptop", "Sprzęt"]:
		if not elektro.has(wybor2):
			printerr("FAIL: Elektronika bez ", wybor2, " jest=", elektro)
			return 1
	root._on_powrot()
	await process_frame
	if root._stos.size() != 1 or str(root._stos[0].get("id", "")) != "zakupy":
		printerr("FAIL: powrót z Elektroniki nie wraca do Zakupów ", root._stos)
		return 1
	root._wejdz_w_kategorie_zakupow({"id": "samochod", "nazwa": "Samochód", "stan_uzywany_nowy": true})
	await process_frame
	if root._stos.size() != 3:
		printerr("FAIL: auto nie siedzi pod grupą, stos=", root._stos.size())
		return 1
	if str(root._stos[1].get("id", "")) != "zakupy_grupa_srodki_transportu":
		printerr("FAIL: środek stosu nie jest Środkami transportu ", root._stos[1])
		return 1
	if not _suwak_zostawia_gest(root._tresc_biala()):
		printerr("FAIL: suwak ceny nie trzyma własnego gestu (STOP)")
		return 1
	root._on_powrot()
	await process_frame
	if str(root._stos[root._stos.size() - 1].get("tresc", "")) != "zakupy_grupa":
		printerr("FAIL: powrót z auta nie wraca do grupy ", root._stos)
		return 1
	root._on_powrot()
	await process_frame
	if root._stos.size() != 1 or str(root._stos[0].get("tresc", "")) != "zakupy":
		printerr("FAIL: powrót z grupy nie wraca do Zakupów ", root._stos)
		return 1
	print("OK Zakupy → grupy → typ → powrót")
	return 0


func _rodzina_ui(root, rodzina: Dictionary) -> int:
	root._on_zakladka("osoby")
	await process_frame
	var osoby: Dictionary = root._akcje_po_id["osoby"]
	var rodzina_akcja: Dictionary = {}
	for d in osoby.get("dzieci", []):
		if d is Dictionary and str(d.get("tresc", "")) == "rodzina":
			rodzina_akcja = d
			break
	if rodzina_akcja.is_empty():
		printerr("FAIL: brak akcji Rodzina")
		return 1
	root._otworz_akcje(rodzina_akcja)
	await process_frame
	var naglowki := {}
	var pudelka := {}
	_zbierz_sekcje(root._tresc_biala(), naglowki, pudelka)
	for id_sekcji in ["rodzice", "dziadkowie"]:
		if not naglowki.has(id_sekcji) or not pudelka.has(id_sekcji):
			printerr("FAIL: brak sekcji ", id_sekcji)
			return 1
		var pudelko: VBoxContainer = pudelka[id_sekcji]
		if pudelko.visible:
			printerr("FAIL: sekcja ", id_sekcji, " startuje rozwinięta")
			return 1
		if pudelko.get_child_count() < 1:
			printerr("FAIL: sekcja ", id_sekcji, " pusta — ludzie usunięci")
			return 1
	var matka := ""
	if rodzina.get("matka") is Dictionary and rodzina["matka"].get("imie") is Dictionary:
		matka = str(rodzina["matka"]["imie"].get("nazwa", ""))
	var tekst_rodzicow := _tekst_drzewa(pudelka["rodzice"])
	if matka != "" and tekst_rodzicow.find(matka) < 0:
		printerr("FAIL: matka nie siedzi pod Rodzice: ", tekst_rodzicow)
		return 1
	if tekst_rodzicow.find("Ojciec") < 0:
		printerr("FAIL: brak ojca w sekcji Rodzice")
		return 1
	(naglowki["rodzice"] as Button).pressed.emit()
	if not (pudelka["rodzice"] as VBoxContainer).visible:
		printerr("FAIL: stuknięcie Rodzice nie rozwija")
		return 1
	(naglowki["rodzice"] as Button).pressed.emit()
	if (pudelka["rodzice"] as VBoxContainer).visible:
		printerr("FAIL: drugie stuknięcie Rodzice nie zwija")
		return 1
	(naglowki["dziadkowie"] as Button).pressed.emit()
	var tekst_dziadkow := _tekst_drzewa(pudelka["dziadkowie"])
	if tekst_dziadkow.find("Babcia") < 0 and tekst_dziadkow.find("Dziadek") < 0 and tekst_dziadkow.find("Brak") < 0:
		printerr("FAIL: rozwinięci dziadkowie bez osób i bez uczciwego braku: ", tekst_dziadkow)
		return 1
	print("OK Rodzice/Dziadkowie zwijane")
	return 0


func _scroll(root) -> int:
	var scroll: ScrollContainer = root.get_node(SCROLL)
	if scroll.get_script() == null or not str(scroll.get_script().resource_path).ends_with("scroll_dotyk.gd"):
		printerr("FAIL: ScrollBialy bez scroll_dotyk")
		return 1
	var tresc: Control = scroll.get_child(0)
	tresc.custom_minimum_size = Vector2(400, 5000)
	await process_frame
	await process_frame
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(120, 300)
	scroll._gui_input(ev)
	var ruch := InputEventMouseMotion.new()
	ruch.position = Vector2(120, 80)
	scroll._gui_input(ruch)
	if scroll.scroll_vertical < 150:
		printerr("FAIL: przeciągnięcie palca nie scrolluje, scroll_vertical=", scroll.scroll_vertical, " size=", scroll.size)
		return 1
	var stos_przed: int = int(root._stos.size())
	var pusc := InputEventMouseButton.new()
	pusc.button_index = MOUSE_BUTTON_LEFT
	pusc.pressed = false
	pusc.position = Vector2(120, 80)
	scroll._gui_input(pusc)
	if root._stos.size() != stos_przed:
		printerr("FAIL: przeciągnięcie wywołało klik")
		return 1
	print("OK scroll palcem vertical=", scroll.scroll_vertical)
	return 0


func _kontrolka_pod_palcem(wezel: Node, punkt: Vector2) -> Control:
	if wezel is CanvasItem and not (wezel as CanvasItem).is_visible_in_tree():
		return null
	var dzieci := wezel.get_children()
	for i in range(dzieci.size() - 1, -1, -1):
		var traf := _kontrolka_pod_palcem(dzieci[i], punkt)
		if traf != null:
			return traf
	if wezel is Control:
		var kontrolka := wezel as Control
		if kontrolka.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			return null
		if kontrolka.get_global_rect().has_point(punkt):
			return kontrolka
	return null


func _teksty_przyciskow(wezel: Node) -> Array:
	var out: Array = []
	for b in _przyciski(wezel):
		out.append(str((b as Button).text))
	return out


func _przyciski(wezel: Node) -> Array:
	var out: Array = []
	if wezel is Button:
		out.append(wezel)
	for d in wezel.get_children():
		out.append_array(_przyciski(d))
	return out


func _zbierz_sekcje(wezel: Node, naglowki: Dictionary, pudelka: Dictionary) -> void:
	if wezel is Button and str(wezel.get_meta("sekcja_rodziny", "")) != "":
		naglowki[str(wezel.get_meta("sekcja_rodziny"))] = wezel
	if wezel is VBoxContainer and str(wezel.get_meta("tresc_sekcji", "")) != "":
		pudelka[str(wezel.get_meta("tresc_sekcji"))] = wezel
	for d in wezel.get_children():
		_zbierz_sekcje(d, naglowki, pudelka)


func _tekst_drzewa(wezel: Node) -> String:
	var czesci: PackedStringArray = []
	if wezel is Label:
		czesci.append((wezel as Label).text)
	for d in wezel.get_children():
		var dalej := _tekst_drzewa(d)
		if dalej != "":
			czesci.append(dalej)
	return "\n".join(czesci)


func _suwak_zostawia_gest(wezel: Node) -> bool:
	var skrypt: Variant = wezel.get_script()
	if wezel is Control and skrypt is Script and str((skrypt as Script).resource_path).ends_with("suwak_zakres.gd"):
		if (wezel as Control).mouse_filter != Control.MOUSE_FILTER_STOP:
			return false
	for d in wezel.get_children():
		if not _suwak_zostawia_gest(d):
			return false
	return true
