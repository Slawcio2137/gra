extends RefCounted
class_name EkranPracy

## Ekran rynku pracy: filtry, oferty, negocjacje.

var h


func _init(host) -> void:
	h = host




func _ekran_praca_fala2() -> void:
	h._ekran_pracy = true
	_praca_filtry_start()
	h._rynek_pracy.aktywuj(h._swiat, h._praca_filtry, int(h._swiat.get("tydzien", 1)), _praca_miejsca(), h._stan._id_miejsca_pobytu())
	var txt = h._rodzina._tekst_pracy()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Praca rodziców: %s" % (txt if txt != "" else "—"), 16))
	var komunikat := str(h._swiat.get("praca_komunikat", "")).strip_edges()
	if komunikat != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(komunikat, 16))
	_praca_karta_zatrudnienia()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Ogłoszenia", 18))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Kilka ogłoszeń z wybranego zasięgu. Niżej dochodzą następne. Po kilku tygodniach same znikają.", 16))
	_praca_panel_filtrow()
	var slot := VBoxContainer.new()
	slot.set_meta("praca_slot", true)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h._ui._tresc_biala().add_child(slot)
	var fuchy := VBoxContainer.new()
	fuchy.set_meta("praca_fuchy", true)
	fuchy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuchy.add_child(h._ui._napis_ekranu("Dorywczo", 18))
	var szkic := PracaSzkielet.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(h._stan._bohater().get("sylwetka", {}))
	for p in szkic.prace_dla_wieku(h._stan._wiek_lat()):
		if not (p is Dictionary):
			continue
		var b := Button.new()
		b.text = str(p.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", 17)
		var id_p := str(p.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = szkic.wykonaj_fuche(h._stan._bohater(), id_p, syl)
			if bool(w.get("ok", false)):
				h._stan._dodaj_pieniadze(int(w.get("placa", 0)))
				h._stan._dodaj_wplyw("fucha", int(w.get("placa", 0)), str(w.get("tekst", "")))
				h._swiat["bohater"] = h._stan._bohater()
				h.SkryptZapisu.zapisz(h._swiat)
				h._pasek._odswiez_pasek_statystyk(true)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 16))
		)
		fuchy.add_child(b)
	h._ui._tresc_biala().add_child(fuchy)
	_podlacz_scroll_pracy()
	_praca_przerysuj_oferty()


func _praca_miejsca() -> Array:
	if h._losowanie == null:
		return []
	return h._losowanie.wszystkie_z_ludnoscia()


func _praca_tekst_puli() -> String:
	var poziom := str(h._praca_filtry.get("zasieg", "miasto"))
	var karta: Dictionary = h._rynek_pracy.miasto_bohatera(_praca_miejsca(), h._stan._id_miejsca_pobytu())
	var obszar := "Polska"
	var metro := false
	if poziom == "miasto" or poziom == "wojewodztwo":
		obszar = str(karta.get("wojewodztwo", "Polska"))
		metro = poziom == "miasto" and h._rynek_pracy.czy_metropolia(str(karta.get("nazwa", "")))
	var n: int = h._rynek_pracy.pula_ofert(
		h._rynek_pracy.ludnosc_zakresu(_praca_miejsca(), poziom, h._stan._id_miejsca_pobytu()),
		poziom,
		h._praca_filtry,
		obszar,
		metro
	)
	return "Ogłoszeń w tym zasięgu: %d" % n


func _praca_filtry_start() -> void:
	if not h._praca_filtry.is_empty():
		return
	h._praca_filtry = {
		"tekst": "",
		"wielka_grupa": "",
		"wyksztalcenie_max": -1,
		"doswiadczenie_max": -1,
		"filtruj_place": true,
		"placa_od": 0,
		"placa_do": 20000,
		"wplyw_stat": "",
		"wplyw_znak": "",
		"zasieg": "miasto",
	}


func _praca_karta_zatrudnienia() -> void:
	var lista: Array = h._rynek_pracy.lista_prac(h._swiat)
	if lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Nie masz etatu.", 16))
		return
	if lista.size() >= 2:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Masz dwie prace. Zmęczenie fizyczne i obciążenie psychiczne rosną co tydzień.", 16))
	for i in lista.size():
		if lista[i] is Dictionary:
			_praca_jedna_karta(lista[i], i)


func _praca_jedna_karta(praca: Dictionary, indeks: int) -> void:
	var szef: Dictionary = praca.get("szef", {}) if praca.get("szef") is Dictionary else {}
	var karta := VBoxContainer.new()
	karta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karta.add_theme_constant_override("separation", 6)
	karta.add_child(h._ui._napis_ekranu(str(praca.get("nazwa", "Praca")), 18))
	karta.add_child(h._ui._napis_ekranu("Płaca: %s zł brutto" % h._ui._tekst_z_odstepami(int(praca.get("placa_zl", 0))), 16))
	var pasek := str(praca.get("ostatni_pasek", ""))
	if pasek != "":
		for linia in pasek.split("\n"):
			if str(linia) != "":
				karta.add_child(h._ui._napis_ekranu(str(linia), 16))
	var cecha := _nazwa_cechy_szefa(str(szef.get("cecha", "")))
	var linia_szefa := "Kierownik: %s" % _slowa_relacji(int(szef.get("relacja", 50)))
	if cecha != "":
		linia_szefa += ", %s" % cecha
	karta.add_child(h._ui._napis_ekranu(linia_szefa, 16))
	karta.add_child(h._ui._napis_ekranu("Upomnienia: %s" % _slowa_upomnien(int(praca.get("upomnienia", 0))), 16))
	karta.add_child(h._ui._napis_ekranu("Staż tutaj: %d tyg." % int(praca.get("staz_tygodni", 0)), 16))
	var zostalo := int(praca.get("wypowiedzenie_zostalo", 0))
	if zostalo > 0:
		karta.add_child(h._ui._napis_ekranu("Zostajesz jeszcze %d tyg." % zostalo, 16))
	karta.add_child(h._ui._napis_ekranu("Zaangażowanie", 16))
	var suwak := HSlider.new()
	suwak.min_value = 0
	suwak.max_value = 100
	suwak.step = 5
	suwak.value = int(praca.get("angaz", 50))
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var opis = h._ui._napis_ekranu(_slowa_angazu(int(suwak.value)), 16)
	var nr := indeks
	suwak.value_changed.connect(func(v: float) -> void:
		h._rynek_pracy.ustaw_angaz(h._swiat, int(v), nr)
		opis.text = _slowa_angazu(int(v))
		h.SkryptZapisu.zapisz(h._swiat)
	)
	karta.add_child(suwak)
	karta.add_child(opis)
	var prosba := Button.new()
	prosba.text = "Poproś o podwyżkę"
	prosba.custom_minimum_size = Vector2(0, 44)
	prosba.add_theme_font_size_override("font_size", 17)
	prosba.pressed.connect(func() -> void:
		_praca_popros(nr)
	)
	karta.add_child(prosba)
	if zostalo <= 0:
		var odejscie := Button.new()
		odejscie.text = "Odejdź z pracy"
		odejscie.custom_minimum_size = Vector2(0, 44)
		odejscie.add_theme_font_size_override("font_size", 17)
		odejscie.pressed.connect(func() -> void:
			_praca_odejdz(nr)
		)
		karta.add_child(odejscie)
	h._ui._tresc_biala().add_child(karta)


func _praca_panel_filtrow() -> void:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	panel.add_child(h._ui._napis_ekranu("Zasięg", 16))
	var zasieg := OptionButton.new()
	var nazwy_zasiegu := ["Miasto", "Województwo", "Polska"]
	var kody_zasiegu := ["miasto", "wojewodztwo", "polska"]
	var idx_zasiegu := 0
	for i in nazwy_zasiegu.size():
		zasieg.add_item(nazwy_zasiegu[i], i)
		if kody_zasiegu[i] == str(h._praca_filtry.get("zasieg", "miasto")):
			idx_zasiegu = i
	zasieg.select(idx_zasiegu)
	_przycisk_filtra(zasieg)
	zasieg.item_selected.connect(func(idx: int) -> void:
		if h._praca_cisza or idx < 0 or idx >= kody_zasiegu.size():
			return
		h._praca_filtry["zasieg"] = kody_zasiegu[idx]
		_praca_przeladuj()
	)
	panel.add_child(zasieg)
	h._praca_pula_lbl = h._ui._napis_ekranu(_praca_tekst_puli(), 16)
	h._praca_pula_lbl.set_meta("praca_pula", true)
	panel.add_child(h._praca_pula_lbl)
	panel.add_child(h._ui._napis_ekranu("Szukaj", 16))
	var pole := LineEdit.new()
	pole.placeholder_text = "Nazwa zawodu"
	pole.text = str(h._praca_filtry.get("tekst", ""))
	pole.custom_minimum_size = Vector2(0, 44)
	pole.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pole.add_theme_font_size_override("font_size", 17)
	pole.text_submitted.connect(func(t: String) -> void:
		h._praca_filtry["tekst"] = t.strip_edges()
		_praca_przeladuj()
	)
	var szukaj := Button.new()
	szukaj.text = "Szukaj"
	szukaj.custom_minimum_size = Vector2(0, 44)
	szukaj.add_theme_font_size_override("font_size", 17)
	szukaj.pressed.connect(func() -> void:
		h._praca_filtry["tekst"] = pole.text.strip_edges()
		_praca_przeladuj()
	)
	panel.add_child(pole)
	panel.add_child(szukaj)
	panel.add_child(h._ui._napis_ekranu("Rodzaj", 16))
	var rodzaj := OptionButton.new()
	rodzaj.add_item("Wszystkie", 0)
	var grupy := _praca_grupy()
	var wybrany := 0
	for i in grupy.size():
		var g: Dictionary = grupy[i]
		rodzaj.add_item(str(g.get("nazwa", g.get("kod", ""))), i + 1)
		if str(g.get("kod", "")) == str(h._praca_filtry.get("wielka_grupa", "")):
			wybrany = i + 1
	rodzaj.select(wybrany)
	_przycisk_filtra(rodzaj)
	rodzaj.item_selected.connect(func(idx: int) -> void:
		if h._praca_cisza:
			return
		if idx <= 0 or idx - 1 >= grupy.size():
			h._praca_filtry["wielka_grupa"] = ""
		else:
			h._praca_filtry["wielka_grupa"] = str(grupy[idx - 1].get("kod", ""))
		_praca_przeladuj()
	)
	panel.add_child(rodzaj)
	panel.add_child(h._ui._napis_ekranu("Wymagane wykształcenie, do", 16))
	var poziomy := [-1, 0, 1, 2, 3]
	var nazwy_poz := ["Bez filtra", "Podstawowe", "Branżowe", "Średnie", "Wyższe"]
	panel.add_child(_praca_opcja(nazwy_poz, poziomy, int(h._praca_filtry.get("wyksztalcenie_max", -1)), func(wartosc: int) -> void:
		h._praca_filtry["wyksztalcenie_max"] = wartosc
		_praca_przeladuj()
	))
	panel.add_child(h._ui._napis_ekranu("Wymagane doświadczenie, do", 16))
	var progi := [-1, 0, 1, 3, 8]
	var nazwy_staz := ["Bez filtra", "Brak", "Krótkie", "Kilkuletnie", "Długie"]
	panel.add_child(_praca_opcja(nazwy_staz, progi, int(h._praca_filtry.get("doswiadczenie_max", -1)), func(wartosc: int) -> void:
		h._praca_filtry["doswiadczenie_max"] = wartosc
		_praca_przeladuj()
	))
	panel.add_child(h._ui._napis_ekranu("Wpływ", 16))
	var opcja_wplywu := OptionButton.new()
	opcja_wplywu.add_item("Bez filtra", 0)
	var pary: Array = []
	var nazwy_stat := {
		"zmeczenie_fizyczne": "Zmęczenie fizyczne",
		"zmeczenie_psychiczne": "Obciążenie psychiczne",
		"sylwetka": "Sylwetka",
		"inteligencja": "Inteligencja",
		"zdrowie": "Zdrowie",
		"wyglad": "Wygląd",
		"sila": "Siła",
		"kondycja": "Kondycja",
		"psychika": "Psychika",
	}
	var idx_w := 0
	var k := 1
	for stat in nazwy_stat.keys():
		for znak in ["+", "-"]:
			var pokaz := "−" if znak == "-" else "+"
			opcja_wplywu.add_item("%s %s" % [str(nazwy_stat[stat]), pokaz], k)
			pary.append({"stat": stat, "znak": znak})
			if str(h._praca_filtry.get("wplyw_stat", "")) == stat and str(h._praca_filtry.get("wplyw_znak", "")) == znak:
				idx_w = k
			k += 1
	opcja_wplywu.select(idx_w)
	_przycisk_filtra(opcja_wplywu)
	opcja_wplywu.item_selected.connect(func(idx: int) -> void:
		if h._praca_cisza:
			return
		if idx <= 0 or idx - 1 >= pary.size():
			h._praca_filtry["wplyw_stat"] = ""
			h._praca_filtry["wplyw_znak"] = ""
		else:
			h._praca_filtry["wplyw_stat"] = str(pary[idx - 1].get("stat", ""))
			h._praca_filtry["wplyw_znak"] = str(pary[idx - 1].get("znak", ""))
		_praca_przeladuj()
	)
	panel.add_child(opcja_wplywu)
	panel.add_child(h._ui._napis_ekranu("Płaca", 16))
	var suwak = h.SkryptZakresu.new()
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak.custom_minimum_size = Vector2(120, 48)
	suwak.ustaw_zakres(0.0, 20000.0)
	suwak.od = float(h._praca_filtry.get("placa_od", 0))
	suwak.dokad = float(h._praca_filtry.get("placa_do", 20000))
	var opis_placy = h._ui._napis_ekranu("%s–%s zł" % [h._ui._tekst_z_odstepami(int(suwak.od)), h._ui._tekst_z_odstepami(int(suwak.dokad))], 16)
	suwak.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
		h._praca_filtry["filtruj_place"] = true
		h._praca_filtry["placa_od"] = int(od)
		h._praca_filtry["placa_do"] = int(dokad)
		opis_placy.text = "%s–%s zł" % [h._ui._tekst_z_odstepami(int(od)), h._ui._tekst_z_odstepami(int(dokad))]
		_praca_przeladuj()
	)
	panel.add_child(opis_placy)
	panel.add_child(suwak)
	h._ui._tresc_biala().add_child(panel)


func _praca_opcja(nazwy: Array, wartosci: Array, aktualna: int, po_wyborze: Callable) -> OptionButton:
	var opcja := OptionButton.new()
	var idx := 0
	for i in nazwy.size():
		opcja.add_item(str(nazwy[i]), i)
		if int(wartosci[i]) == aktualna:
			idx = i
	opcja.select(idx)
	_przycisk_filtra(opcja)
	opcja.item_selected.connect(func(i: int) -> void:
		if h._praca_cisza or i < 0 or i >= wartosci.size():
			return
		po_wyborze.call(int(wartosci[i]))
	)
	return opcja


func _przycisk_filtra(opcja: OptionButton) -> void:
	opcja.custom_minimum_size = Vector2(0, 44)
	opcja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opcja.add_theme_font_size_override("font_size", 17)


func _praca_grupy() -> Array:
	var out: Array = []
	var kat = h.SkryptKataloguZawodow.new()
	kat.wczytaj()
	var grupy: Variant = kat.dane().get("grupy", [])
	if not (grupy is Array):
		return out
	for g in grupy:
		if g is Dictionary and str(g.get("kod", "")).length() == 1:
			out.append(g)
	return out


func _praca_przeladuj() -> void:
	if h._praca_cisza or h._swiat.is_empty():
		return
	if h._swiat.get("rynek_pracy") is Dictionary:
		h._swiat["rynek_pracy"]["oferty"] = []
	h._rynek_pracy.aktywuj(h._swiat, h._praca_filtry, int(h._swiat.get("tydzien", 1)), _praca_miejsca(), h._stan._id_miejsca_pobytu())
	if is_instance_valid(h._praca_pula_lbl):
		h._praca_pula_lbl.text = _praca_tekst_puli()
	_praca_przerysuj_oferty()
	_praca_wyczysc_slot()


func _praca_przerysuj_oferty() -> void:
	var tresc = h._ui._tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if dziecko.has_meta("praca_oferta"):
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	var oferty: Array = []
	if h._swiat.get("rynek_pracy") is Dictionary and h._swiat["rynek_pracy"].get("oferty") is Array:
		oferty = h._swiat["rynek_pracy"]["oferty"]
	var przed: Node = null
	for dziecko in tresc.get_children():
		if dziecko.has_meta("praca_fuchy"):
			przed = dziecko
			break
	if oferty.is_empty():
		var pusty = h._ui._napis_ekranu("Brak ogłoszeń w tym filtrze.", 16)
		pusty.set_meta("praca_oferta", true)
		_praca_wstaw(tresc, pusty, przed)
		return
	for o in oferty:
		if o is Dictionary:
			_praca_wstaw(tresc, _praca_karta_oferty(o), przed)


func _praca_wstaw(tresc: VBoxContainer, karta: Control, przed: Node) -> void:
	tresc.add_child(karta)
	if przed != null:
		tresc.move_child(karta, przed.get_index())


func _praca_karta_oferty(oferta: Dictionary) -> Control:
	var karta := VBoxContainer.new()
	karta.set_meta("praca_oferta", true)
	karta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karta.add_theme_constant_override("separation", 4)
	for linia in h._rynek_pracy.tekst_ogloszenia(oferta).split("\n"):
		if str(linia) == "":
			continue
		karta.add_child(h._ui._napis_ekranu(str(linia), 17))
	var przycisk := Button.new()
	przycisk.text = "Aplikuj"
	przycisk.custom_minimum_size = Vector2(0, 44)
	przycisk.add_theme_font_size_override("font_size", 17)
	var id_oferty := str(oferta.get("id", ""))
	przycisk.pressed.connect(func() -> void:
		_praca_klik_aplikuj(id_oferty)
	)
	karta.add_child(przycisk)
	return karta


func _praca_klik_aplikuj(id_oferty: String) -> void:
	var oferta := _praca_oferta_po_id(id_oferty)
	if oferta.is_empty():
		return
	var slot := _praca_slot()
	if slot == null:
		return
	_praca_wyczysc_slot()
	if h._rynek_pracy.lista_prac(h._swiat).size() >= 2:
		slot.add_child(h._ui._napis_ekranu("Masz już dwie prace. Trzeciej nie weźmiesz.", 16))
		return
	slot.add_child(h._ui._napis_ekranu("Chcesz negocjować płacę?", 16))
	var tak := Button.new()
	tak.text = "Tak, negocjuję"
	tak.custom_minimum_size = Vector2(0, 44)
	tak.add_theme_font_size_override("font_size", 17)
	var nie := Button.new()
	nie.text = "Nie, biorę kwotę z ogłoszenia"
	nie.custom_minimum_size = Vector2(0, 44)
	nie.add_theme_font_size_override("font_size", 17)
	tak.pressed.connect(func() -> void:
		_praca_suwak_negocjacji(oferta)
	)
	nie.pressed.connect(func() -> void:
		_praca_zamknij_aplikacje(oferta, false, int(oferta.get("placa_zl", 0)))
	)
	slot.add_child(tak)
	slot.add_child(nie)


func _praca_suwak_negocjacji(oferta: Dictionary, ponownie: bool = false) -> void:
	var slot := _praca_slot()
	if slot == null:
		return
	_praca_wyczysc_slot()
	var placa := int(oferta.get("placa_zl", 0))
	var band: Dictionary = h._rynek_pracy.pasmo(placa)
	if ponownie:
		var wst = h._rynek_pracy.wstep_dialogu("ponowna_proba")
		if wst != "":
			slot.add_child(h._ui._napis_ekranu(wst, 16))
		slot.add_child(h._ui._napis_ekranu(h._rynek_pracy.linia_dialogu("ponowna_proba", placa, -1), 16))
	var opis = h._ui._napis_ekranu("Żądasz: %s zł" % h._ui._tekst_z_odstepami(placa), 16)
	var suwak := HSlider.new()
	suwak.min_value = int(band.get("min_zl", placa))
	suwak.max_value = maxi(int(band.get("max_zl", placa)), int(suwak.min_value) + 1)
	suwak.step = 100
	suwak.value = placa
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak.value_changed.connect(func(v: float) -> void:
		opis.text = "Żądasz: %s zł" % h._ui._tekst_z_odstepami(int(v))
	)
	slot.add_child(opis)
	slot.add_child(suwak)
	var zloz := Button.new()
	zloz.text = "Złóż"
	zloz.custom_minimum_size = Vector2(0, 44)
	zloz.add_theme_font_size_override("font_size", 17)
	zloz.pressed.connect(func() -> void:
		_praca_zamknij_aplikacje(oferta, true, int(suwak.value))
	)
	slot.add_child(zloz)


func _praca_zamknij_aplikacje(oferta: Dictionary, negocjuje: bool, zadana: int) -> void:
	var wynik: Dictionary = h._rynek_pracy.negocjuj(oferta, h._stan._bohater(), negocjuje, zadana, randf())
	var slot := _praca_slot()
	if slot == null:
		return
	_praca_wyczysc_slot()
	var twarda := bool(wynik.get("twarda_odmowa", false))
	var sytuacja := _praca_sytuacja(str(wynik.get("wynik", "")), negocjuje, twarda)
	var placa_oni := int(wynik.get("placa_pracodawcy", oferta.get("placa_zl", 0)))
	if placa_oni <= 0:
		placa_oni = int(oferta.get("placa_zl", 0))
	var wst = h._rynek_pracy.wstep_dialogu(sytuacja)
	if wst != "":
		slot.add_child(h._ui._napis_ekranu(wst, 16))
	slot.add_child(h._ui._napis_ekranu(h._rynek_pracy.linia_dialogu(sytuacja, placa_oni, -1), 16))
	if twarda:
		var zamknij := _praca_przycisk("Nie")
		zamknij.pressed.connect(func() -> void:
			_praca_wyczysc_slot()
			var zostaw := _praca_slot()
			if zostaw != null:
				zostaw.add_child(h._ui._napis_ekranu("Koniec rozmowy.", 16))
		)
		slot.add_child(zamknij)
		return
	var wybory: Array = wynik.get("wybory", []) if wynik.get("wybory") is Array else h._rynek_pracy.wybory_dialogu()
	var tak := _praca_przycisk(str(wybory[0]) if wybory.size() > 0 else "Tak")
	var nie := _praca_przycisk(str(wybory[1]) if wybory.size() > 1 else "Nie")
	var jeszcze := _praca_przycisk(str(wybory[2]) if wybory.size() > 2 else "Spróbuj ponownej negocjacji")
	var kod := str(wynik.get("wynik", ""))
	var placa_tak := int(wynik.get("placa_zl", 0))
	if kod == "odmowa" or placa_tak <= 0:
		placa_tak = placa_oni
	tak.pressed.connect(func() -> void:
		_praca_przyjmij(oferta, placa_tak)
	)
	nie.pressed.connect(func() -> void:
		_praca_wyczysc_slot()
		var zostaw := _praca_slot()
		if zostaw != null:
			zostaw.add_child(h._ui._napis_ekranu("Odchodzisz od tej oferty.", 16))
	)
	jeszcze.pressed.connect(func() -> void:
		_praca_suwak_negocjacji(oferta, true)
	)
	slot.add_child(tak)
	slot.add_child(nie)
	slot.add_child(jeszcze)


func _praca_sytuacja(wynik: String, negocjuje: bool, twarda: bool = false) -> String:
	if twarda:
		return "brak_kwalifikacji"
	if not negocjuje and wynik == "zgoda":
		return "zgoda_bez_negocjacji"
	if wynik == "zgoda":
		return "zgoda_na_zadanie"
	if wynik == "kontroferta":
		return "kontroferta"
	return "odrzucenie_zadania"


func _praca_przyjmij(oferta: Dictionary, placa: int) -> void:
	if h._rynek_pracy.lista_prac(h._swiat).size() >= 2:
		var slot := _praca_slot()
		if slot != null:
			slot.add_child(h._ui._napis_ekranu("Masz już dwie prace. Trzeciej nie weźmiesz.", 16))
		return
	var przyjęta: Dictionary = h._rynek_pracy.zatrudnij(h._swiat, oferta, placa)
	if not bool(przyjęta.get("ok", true)) and str(przyjęta.get("powod", "")) == "dwie_prace":
		h._swiat["praca_komunikat"] = "Masz już dwie prace. Trzeciej nie weźmiesz."
	else:
		h._swiat["praca_komunikat"] = "Zaczynasz pracę. Płaca: %s zł brutto." % h._ui._tekst_z_odstepami(placa)
	h.SkryptZapisu.zapisz(h._swiat)
	h._ui._wyczysc(h._ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_przycisk(napis: String) -> Button:
	var b := Button.new()
	b.text = napis
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 17)
	return b


func _praca_popros(indeks: int = 0) -> void:
	var wynik: Dictionary = h._rynek_pracy.popros_o_podwyzke(h._swiat, randf(), indeks)
	h._swiat["praca_komunikat"] = str(wynik.get("tekst", ""))
	h.SkryptZapisu.zapisz(h._swiat)
	h._ui._wyczysc(h._ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_odejdz(indeks: int = 0) -> void:
	var n: int = h._rynek_pracy.odejdz(h._swiat, -1.0, indeks)
	h._swiat["praca_komunikat"] = "Wypowiedzenie złożone. Zostajesz jeszcze %d tyg." % n
	h.SkryptZapisu.zapisz(h._swiat)
	h._ui._wyczysc(h._ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_oferta_po_id(id_oferty: String) -> Dictionary:
	if not (h._swiat.get("rynek_pracy") is Dictionary):
		return {}
	var oferty: Variant = h._swiat["rynek_pracy"].get("oferty", [])
	if not (oferty is Array):
		return {}
	for o in oferty:
		if o is Dictionary and str(o.get("id", "")) == id_oferty:
			return o
	return {}


func _praca_slot() -> VBoxContainer:
	for dziecko in h._ui._tresc_biala().get_children():
		if dziecko.has_meta("praca_slot") and dziecko is VBoxContainer:
			return dziecko
	return null


func _praca_wyczysc_slot() -> void:
	var slot := _praca_slot()
	if slot == null:
		return
	for dziecko in slot.get_children():
		slot.remove_child(dziecko)
		dziecko.queue_free()


func _nazwa_cechy_szefa(id: String) -> String:
	match id:
		"lagodny":
			return "łagodny"
		"cierpliwy":
			return "cierpliwy"
		"empatyczny":
			return "empatyczny"
		"zyczliwy":
			return "życzliwy"
		"spokojny":
			return "spokojny"
		"oschly":
			return "oschły"
		"wybuchowy":
			return "wybuchowy"
		"drazliwy":
			return "drażliwy"
		"agresywny":
			return "agresywny"
		_:
			return id


func _slowa_relacji(n: int) -> String:
	if n < 25:
		return "zła"
	if n < 45:
		return "słaba"
	if n < 65:
		return "w porządku"
	if n < 85:
		return "dobra"
	return "bardzo dobra"


func _slowa_upomnien(n: int) -> String:
	if n <= 0:
		return "brak"
	if n == 1:
		return "jedno"
	if n == 2:
		return "dwa"
	return "trzy i więcej"


func _slowa_angazu(n: int) -> String:
	if n < 35:
		return "byle jak"
	if n < 70:
		return "normalnie"
	return "na poważnie"


func _podlacz_scroll_pracy() -> void:
	if h._praca_scroll_podpiety:
		return
	var sc = h._ekran_zakupow._scroll_zakupow()
	if sc == null:
		return
	var pasek = sc.get_v_scroll_bar()
	if pasek == null:
		return
	pasek.value_changed.connect(_na_scroll_pracy)
	h._praca_scroll_podpiety = true


func _na_scroll_pracy(wartosc: float) -> void:
	if not h._ekran_pracy or h._praca_dokladka:
		return
	var sc = h._ekran_zakupow._scroll_zakupow()
	if sc == null:
		return
	var pasek = sc.get_v_scroll_bar()
	if pasek == null or pasek.max_value <= sc.size.y + 8.0:
		return
	if not RynekZakupow.trzeba_dociagnac_przed_koncem(pasek.max_value - wartosc - sc.size.y):
		return
	h._praca_dokladka = true
	var y = sc.scroll_vertical
	var dodano: int = h._rynek_pracy.uzupelnij(h._swiat, h._praca_filtry, h._rynek_pracy.wyprzedzenie(), int(h._swiat.get("tydzien", 1)), _praca_miejsca(), h._stan._id_miejsca_pobytu())
	if dodano > 0:
		_praca_przerysuj_oferty()
		sc.scroll_vertical = y
		h.SkryptZapisu.zapisz(h._swiat)
	h._praca_dokladka = false
