extends RefCounted
class_name EkranZakupow

## Ekran zakupów: grupy, oferty, filtry, targowanie.

var h


func _init(host) -> void:
	h = host




func _ekran_zakupy() -> void:
	_odswiez_rynek_zakupow()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zakupy — losowane oferty (limit miasta × tura). Nie arkusz strategii.", 16))
	var dane := _wczytaj_zakupy_oferty()
	var kategorie: Variant = dane.get("kategorie", []) if dane is Dictionary else []
	if not (kategorie is Array) or kategorie.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak kategorii w danych.", 16))
		return
	var schowane := {}
	for grupa in _grupy_zakupow():
		if not (grupa is Dictionary):
			continue
		var ids: Variant = grupa.get("kategorie", [])
		if ids is Array:
			for id_k in ids:
				schowane[str(id_k)] = true
		_dodaj_przycisk_grupy_zakupow(grupa)
	for kat in kategorie:
		if not (kat is Dictionary):
			continue
		if schowane.has(str(kat.get("id", ""))):
			continue
		_dodaj_przycisk_kategorii_zakupow(kat)


func _dodaj_przycisk_grupy_zakupow(grupa: Dictionary) -> void:
	var przycisk := Button.new()
	przycisk.text = str(grupa.get("nazwa", grupa.get("id", "")))
	przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
	przycisk.custom_minimum_size = Vector2(0, 48)
	przycisk.add_theme_font_size_override("font_size", 18)
	przycisk.set_meta("grupa_zakupow", str(grupa.get("id", "")))
	var grupa_bind: Dictionary = grupa.duplicate(true)
	przycisk.pressed.connect(func() -> void:
		_wejdz_w_grupe_zakupow(grupa_bind)
	)
	h._ui._tresc_biala().add_child(przycisk)


func _dodaj_przycisk_kategorii_zakupow(kat: Dictionary) -> void:
	var przycisk := Button.new()
	przycisk.text = str(kat.get("nazwa", kat.get("id", "")))
	przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
	przycisk.custom_minimum_size = Vector2(0, 48)
	przycisk.add_theme_font_size_override("font_size", 18)
	przycisk.set_meta("kategoria_zakupow", str(kat.get("id", "")))
	var kat_bind: Dictionary = kat.duplicate(true)
	przycisk.pressed.connect(func() -> void:
		_wejdz_w_kategorie_zakupow(kat_bind)
	)
	h._ui._tresc_biala().add_child(przycisk)


func _grupy_zakupow() -> Array:
	var dane := _wczytaj_zakupy_oferty()
	var grupy: Variant = dane.get("grupy", [])
	if grupy is Array:
		return grupy
	return []


func _grupa_dla_kategorii(kat_id: String) -> Dictionary:
	if kat_id == "":
		return {}
	for grupa in _grupy_zakupow():
		if not (grupa is Dictionary):
			continue
		var ids: Variant = grupa.get("kategorie", [])
		if ids is Array and ids.has(kat_id):
			return grupa
	return {}


func _akcja_zakupy() -> Dictionary:
	if h._akcje_po_id.has("zakupy") and h._akcje_po_id["zakupy"] is Dictionary:
		var z: Dictionary = (h._akcje_po_id["zakupy"] as Dictionary).duplicate(true)
		z.erase("dzieci")
		z.erase("sciezka_rodzicow")
		return z
	return {"id": "zakupy", "nazwa": "Zakupy", "tryb": "ekran", "tresc": "zakupy", "kolor": "#b0a04a"}


func _akcja_grupy_zakupow(grupa: Dictionary) -> Dictionary:
	return {
		"id": "zakupy_grupa_%s" % str(grupa.get("id", "")),
		"nazwa": str(grupa.get("nazwa", "Zakupy")),
		"tryb": "ekran",
		"tresc": "zakupy_grupa",
		"grupa": grupa.duplicate(true),
		"kolor": "#b0a04a",
	}


func _wejdz_w_grupe_zakupow(grupa: Dictionary) -> void:
	var akcja := _akcja_grupy_zakupow(grupa)
	akcja["sciezka_rodzicow"] = [_akcja_zakupy()]
	h._otworz_akcje(akcja)


func _ekran_zakupy_grupa(grupa: Dictionary) -> void:
	var ids: Array = grupa.get("kategorie", []) if grupa.get("kategorie") is Array else []
	var nazwy: Dictionary = grupa.get("nazwy_wyboru", {}) if grupa.get("nazwy_wyboru") is Dictionary else {}
	var dane := _wczytaj_zakupy_oferty()
	var kategorie: Array = dane.get("kategorie", []) if dane.get("kategorie") is Array else []
	var po_id := {}
	for kat in kategorie:
		if kat is Dictionary:
			po_id[str(kat.get("id", ""))] = kat
	if ids.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak wyborów w tej kategorii.", 16))
		return
	var uwaga := str(grupa.get("uwaga", "")).strip_edges()
	if uwaga != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(uwaga, 14))
	for id_k in ids:
		var sid := str(id_k)
		if not po_id.has(sid):
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
				"%s — brak rynku w danych (null, bez wymyślonego katalogu)." % sid, 16
			))
			continue
		var kat: Dictionary = (po_id[sid] as Dictionary).duplicate(true)
		if nazwy.has(sid) and str(nazwy[sid]) != "":
			kat["nazwa"] = str(nazwy[sid])
		_dodaj_przycisk_kategorii_zakupow(kat)


func _wejdz_w_kategorie_zakupow(kat: Dictionary) -> void:
	var zakupy := _akcja_zakupy()
	var rodzice: Array = [zakupy]
	var grupa := _grupa_dla_kategorii(str(kat.get("id", "")))
	if not grupa.is_empty():
		rodzice.append(_akcja_grupy_zakupow(grupa))
	if str(kat.get("rodzaj", "")) == "budzet_jakosci" or str(kat.get("id", "")) == "drobiazgi":
		h._otworz_akcje({
			"id": "zakupy_kat_drobiazgi",
			"nazwa": str(kat.get("nazwa", "Drobiazgi")),
			"tryb": "ekran",
			"tresc": "zakupy_kategoria",
			"kat": kat,
			"kolor": str(zakupy.get("kolor", "#b0a04a")),
			"sciezka_rodzicow": rodzice,
		})
		return
	h._otworz_akcje({
		"id": "zakupy_kat_%s" % str(kat.get("id", "")),
		"nazwa": str(kat.get("nazwa", "Zakupy")),
		"tryb": "ekran",
		"tresc": "zakupy_kategoria",
		"kat": kat,
		"kolor": str(zakupy.get("kolor", "#b0a04a")),
		"sciezka_rodzicow": rodzice,
	})


func _ekran_zakupy_kategoria(kat: Dictionary) -> void:
	## Kompatybilność: wejście hierarchiczne przez _wejdz_w_kategorie_zakupow.
	_wejdz_w_kategorie_zakupow(kat)


func _ekran_budzet_drobiazgow() -> void:
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Budżet jakości drobiazgów (propozycja; szansa zdarzenia nadal null).", 14))
	var budzet: Dictionary = {}
	if FileAccess.file_exists(h.PLIK_DROBIAZGOW):
		var plik = FileAccess.open(h.PLIK_DROBIAZGOW, FileAccess.READ)
		if plik != null:
			var dane_d: Variant = JSON.parse_string(plik.get_as_text())
			if dane_d is Dictionary and dane_d.get("budzet_jakosci") is Dictionary:
				budzet = dane_d["budzet_jakosci"]
	var min_zl := int(budzet.get("min_zl", 0)) if h._ui._jest_liczba(budzet.get("min_zl")) else 0
	var max_zl := int(budzet.get("max_zl", 100)) if h._ui._jest_liczba(budzet.get("max_zl")) else 100
	var krok := int(budzet.get("krok_zl", 5)) if h._ui._jest_liczba(budzet.get("krok_zl")) else 5
	var wartosc := int(h._swiat.get("budzet_jakosci_drobiazgow_zl", budzet.get("domyslnie_zl", 0)))
	var opis = h._ui._napis_ekranu("Przeznaczam: %d zł" % wartosc, 16)
	h._ui._tresc_biala().add_child(opis)
	var suwak := HSlider.new()
	suwak.min_value = float(min_zl)
	suwak.max_value = float(max_zl)
	suwak.step = float(krok)
	suwak.value = float(clampi(wartosc, min_zl, max_zl))
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.value_changed.connect(func(v: float) -> void:
		h._swiat["budzet_jakosci_drobiazgow_zl"] = int(v)
		opis.text = "Przeznaczam: %d zł" % int(v)
	)
	h._ui._tresc_biala().add_child(suwak)


func _ekran_zakupy_oferty(kat_id: String, stan_filtr: String, kat: Dictionary) -> void:
	h._ui._wyczysc(h._ui._tresc_biala())
	h._ui._wyczysc(h._ui._dol_suwaka())
	h._ui._dol_suwaka().hide()
	h._ui._tytul_bialy().text = str(kat.get("nazwa", kat_id))
	_odswiez_rynek_zakupow()
	h._zakupy_wiersze = []
	h._zakupy_kat_id = kat_id
	h._zakupy_stan_filtr = stan_filtr
	h._zakupy_kat_slownik = kat
	h._zakupy_filtr_odbior = ""
	h._zakupy_zasieg_poziom = "miasto"
	h._zakupy_filtr_rozwiniety = true
	h._zakupy_filtr_ceny_wlaczony = false
	h._zakupy_filtr_przebiegu_wlaczony = false
	h._zakupy_przebieg_od = 0.0
	h._zakupy_przebieg_do = 0.0
	h._zakupy_filtr_marki = []
	h._zakupy_filtr_naped = ""
	h._zakupy_panel_nowe_auta = null
	h._zakupy_sort_cena = "malejaco"
	if kat_id == "samochod":
		_aktywuj_zakladke_samochodow()
	var dane := _wczytaj_zakupy_oferty()
	var etykiety: Dictionary = {}
	if dane is Dictionary and dane.get("etykiety_stanu") is Dictionary:
		etykiety = dane["etykiety_stanu"]
	var nieruchomosc := bool(kat.get("nieruchomosc", false)) or kat_id == "dom" or kat_id == "mieszkanie" or kat_id == "apartament" or kat_id == "willa"
	var uzywany_nowy := bool(kat.get("stan_uzywany_nowy", true)) and not nieruchomosc
	var conf_n: Dictionary = dane.get("nieruchomosci", {}) if dane is Dictionary and dane.get("nieruchomosci") is Dictionary else {}
	var zas: Dictionary = conf_n.get("zasieg_szukania_km", {}) if conf_n.get("zasieg_szukania_km") is Dictionary else {}
	var zmin := float(zas.get("min", 5))
	var zmax := float(zas.get("max", 80))
	h._zakupy_zasieg_km = float(zas.get("domyslnie", 25))
	var poziomy_zas: Array = conf_n.get("zasieg_szukania_poziomy", []) if conf_n.get("zasieg_szukania_poziomy") is Array else []
	# Przedział cen z całej kategorii (nie tylko po stanie) — żeby suwak był widoczny także gdy
	# chwilowo brak ofert w wybranym stanie; lista i tak tnie po _zakupy_stan_filtr.
	var wszystkie = h._rynek_zakupow.oferty_filtrowane(h._swiat, kat_id, "", 9999.0, 0.0, 0.0, false, "")
	var ceny: Array = []
	for o in wszystkie:
		if o is Dictionary and h._ui._jest_liczba(o.get("cena_zl")):
			ceny.append(float(o["cena_zl"]))
	ceny.sort()
	if h._rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(
			"Ogłoszenia wczytują się przy wejściu i po kilka przy przewijaniu.",
			17
		))
	h._zakupy_pula_lbl = h._ui._napis_ekranu("", 16)
	h._ui._tresc_biala().add_child(h._zakupy_pula_lbl)
	# Filtr u góry — po wejściu w kategorię rozwinięty (widać min–max od razu).
	var przycisk_filtr := Button.new()
	przycisk_filtr.text = "Filtr ▾"
	przycisk_filtr.alignment = HORIZONTAL_ALIGNMENT_LEFT
	przycisk_filtr.custom_minimum_size = Vector2(0, 44)
	przycisk_filtr.add_theme_font_size_override("font_size", 17)
	h._ui._tresc_biala().add_child(przycisk_filtr)
	var panel_filtr := VBoxContainer.new()
	panel_filtr.visible = true
	panel_filtr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_filtr.add_theme_constant_override("separation", 8)
	h._ui._tresc_biala().add_child(panel_filtr)
	przycisk_filtr.pressed.connect(func() -> void:
		h._zakupy_filtr_rozwiniety = not h._zakupy_filtr_rozwiniety
		panel_filtr.visible = h._zakupy_filtr_rozwiniety
		przycisk_filtr.text = "Filtr ▾" if h._zakupy_filtr_rozwiniety else "Filtr ▸"
	)
	# Cena min–max: liczniki obok siebie (poziomo), nie jeden pod drugim.
	var rzad_licz := HBoxContainer.new()
	rzad_licz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rzad_licz.add_theme_constant_override("separation", 16)
	h._zakupy_licznik_od = h._ui._napis_ekranu("min: —", 17)
	h._zakupy_licznik_do = h._ui._napis_ekranu("max: —", 17)
	h._zakupy_licznik_od.autowrap_mode = TextServer.AUTOWRAP_OFF
	h._zakupy_licznik_do.autowrap_mode = TextServer.AUTOWRAP_OFF
	h._zakupy_licznik_od.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h._zakupy_licznik_do.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rzad_licz.add_child(h._zakupy_licznik_od)
	rzad_licz.add_child(h._zakupy_licznik_do)
	panel_filtr.add_child(rzad_licz)
	if ceny.is_empty():
		panel_filtr.add_child(h._ui._napis_ekranu("Przedział cen: — (brak liczb; filtr nie zmyśla).", 16))
		h._zakupy_filtr_od = 0.0
		h._zakupy_filtr_do = 0.0
		h._zakupy_filtr_ceny_wlaczony = false
	else:
		var suwak = h.SkryptZakresu.new()
		suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		suwak.custom_minimum_size = Vector2(120, 48)
		suwak.ustaw_zakres(float(ceny[0]), float(ceny[ceny.size() - 1]))
		h._zakupy_filtr_od = suwak.od
		h._zakupy_filtr_do = suwak.dokad
		h._zakupy_filtr_ceny_wlaczony = true
		h._zakupy_licznik_od.text = "min: %d" % int(h._zakupy_filtr_od)
		h._zakupy_licznik_do.text = "max: %d" % int(h._zakupy_filtr_do)
		suwak.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
			_on_zakupy_filtr_ceny(od, dokad)
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(suwak)
	# Zasięg: miasto → powiat → województwo → PL → sąsiedzi → wysyłka + strop km.
	panel_filtr.add_child(h._ui._napis_ekranu("Zasięg szukania:", 17))
	var opcje_zas := OptionButton.new()
	opcje_zas.custom_minimum_size = Vector2(0, 44)
	opcje_zas.add_theme_font_size_override("font_size", 18)
	opcje_zas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opcje_zas.fit_to_longest_item = false
	opcje_zas.clip_text = true
	if poziomy_zas.is_empty():
		poziomy_zas = [
			{"id": "miasto", "nazwa": "Miasto", "max_km": 35},
			{"id": "powiat", "nazwa": "Powiat", "max_km": 80},
			{"id": "wojewodztwo", "nazwa": "Województwo", "max_km": 250},
			{"id": "polska", "nazwa": "Cała Polska", "max_km": 800},
			{"id": "sasiedzi", "nazwa": "Sąsiednie kraje", "max_km": 1500},
			{"id": "wysylka_zagranica", "nazwa": "Wysyłka z zagranicy", "max_km": 2500},
		]
	for i in poziomy_zas.size():
		var pz: Variant = poziomy_zas[i]
		var pn := str(pz.get("nazwa", pz.get("id", ""))) if pz is Dictionary else str(pz)
		opcje_zas.add_item(pn, i)
	opcje_zas.select(0)
	var opis_z = h._ui._napis_ekranu("Strop odległości: %d km" % int(h._zakupy_zasieg_km), 16)
	var suwak_z := HSlider.new()
	suwak_z.min_value = zmin
	suwak_z.max_value = zmax
	suwak_z.step = 1.0
	suwak_z.value = h._zakupy_zasieg_km
	opcje_zas.item_selected.connect(func(idx: int) -> void:
		if idx < 0 or idx >= poziomy_zas.size():
			return
		var p0: Variant = poziomy_zas[idx]
		if p0 is Dictionary:
			h._zakupy_zasieg_poziom = str(p0.get("id", "miasto"))
			var mx := float(p0.get("max_km", h._zakupy_zasieg_km))
			h._zakupy_zasieg_km = mx
			opis_z.text = "Strop odległości: %d km" % int(mx)
			if suwak_z.max_value < mx:
				suwak_z.max_value = mx
			suwak_z.set_value_no_signal(mx)
		_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(opcje_zas)
	panel_filtr.add_child(opis_z)
	suwak_z.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak_z.custom_minimum_size = Vector2(0, 36)
	suwak_z.value_changed.connect(func(v: float) -> void:
		h._zakupy_zasieg_km = v
		opis_z.text = "Strop odległości: %d km" % int(v)
		_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(suwak_z)
	# Dom i mieszkanie: ten sam wybór Nowe / Używane co przy aucie. Nowe = wykończone i stan surowy.
	if h._rynek_zakupow.kategoria_ma_nowe_lokum(kat_id):
		panel_filtr.add_child(h._ui._napis_ekranu("Stan:", 17))
		var opcje_lok := OptionButton.new()
		opcje_lok.add_item("Wszystkie", 0)
		opcje_lok.add_item("Używane", 1)
		opcje_lok.add_item("Nowe", 2)
		var idx_lok := 0
		if h._zakupy_stan_filtr == "uzywany":
			idx_lok = 1
		elif h._zakupy_stan_filtr == "nowy":
			idx_lok = 2
		opcje_lok.select(idx_lok)
		opcje_lok.custom_minimum_size = Vector2(0, 40)
		opcje_lok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_lok.add_theme_font_size_override("font_size", 17)
		opcje_lok.item_selected.connect(func(idx: int) -> void:
			match idx:
				1:
					h._zakupy_stan_filtr = "uzywany"
				2:
					h._zakupy_stan_filtr = "nowy"
				_:
					h._zakupy_stan_filtr = ""
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_lok)
	# Ruchome: stan używany/nowy + odbiór osobisty/wysyłka. Budynki: cena, odległość i stan rynku.
	h._zakupy_filtr_odbior = ""
	if not nieruchomosc:
		if uzywany_nowy:
			panel_filtr.add_child(h._ui._napis_ekranu("Stan:", 17))
			var opcje_stan := OptionButton.new()
			opcje_stan.add_item("Wszystkie", 0)
			opcje_stan.add_item("Używany", 1)
			opcje_stan.add_item("Nowy", 2)
			var idx_stan := 0
			if h._zakupy_stan_filtr == "uzywany":
				idx_stan = 1
			elif h._zakupy_stan_filtr == "nowy":
				idx_stan = 2
			opcje_stan.select(idx_stan)
			opcje_stan.custom_minimum_size = Vector2(0, 40)
			opcje_stan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opcje_stan.add_theme_font_size_override("font_size", 17)
			opcje_stan.item_selected.connect(func(idx: int) -> void:
				match idx:
					1:
						h._zakupy_stan_filtr = "uzywany"
					2:
						h._zakupy_stan_filtr = "nowy"
					_:
						h._zakupy_stan_filtr = ""
				if h._zakupy_panel_nowe_auta != null and is_instance_valid(h._zakupy_panel_nowe_auta):
					h._zakupy_panel_nowe_auta.visible = (h._zakupy_stan_filtr == "" or h._zakupy_stan_filtr == "nowy")
				_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
			)
			panel_filtr.add_child(opcje_stan)
		panel_filtr.add_child(h._ui._napis_ekranu("Odbiór osobisty:", 17))
		var opcje_odbior := OptionButton.new()
		opcje_odbior.add_item("Wszystkie (bez filtra)", 0)
		opcje_odbior.add_item("Tylko odbiór osobisty", 1)
		opcje_odbior.add_item("Tylko wysyłka / dostawa", 2)
		opcje_odbior.select(0)
		opcje_odbior.custom_minimum_size = Vector2(0, 40)
		opcje_odbior.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_odbior.add_theme_font_size_override("font_size", 17)
		opcje_odbior.item_selected.connect(func(idx: int) -> void:
			match idx:
				1:
					h._zakupy_filtr_odbior = "osobisty"
				2:
					h._zakupy_filtr_odbior = "wysylka"
				_:
					h._zakupy_filtr_odbior = ""
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_odbior)
	# Samochód: przebieg min–max; multi-select marek (puste = wszystkie) + napęd dla nowych.
	if kat_id == "samochod":
		panel_filtr.add_child(h._ui._napis_ekranu("Sortuj cenę:", 17))
		var opcje_sort := OptionButton.new()
		opcje_sort.add_item("Od największej", 0)
		opcje_sort.add_item("Od najmniejszej", 1)
		opcje_sort.select(0 if h._zakupy_sort_cena == "malejaco" else 1)
		opcje_sort.custom_minimum_size = Vector2(0, 40)
		opcje_sort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_sort.add_theme_font_size_override("font_size", 17)
		opcje_sort.item_selected.connect(func(idx: int) -> void:
			h._zakupy_sort_cena = "malejaco" if idx == 0 else "rosnaco"
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_sort)
		var przebiegi: Array = []
		for o in wszystkie:
			if o is Dictionary and h._ui._jest_liczba(o.get("przebieg_km")):
				przebiegi.append(float(o["przebieg_km"]))
		przebiegi.sort()
		panel_filtr.add_child(h._ui._napis_ekranu("Przebieg (km):", 17))
		var rzad_p := HBoxContainer.new()
		rzad_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rzad_p.add_theme_constant_override("separation", 16)
		h._zakupy_licznik_przebieg_od = h._ui._napis_ekranu("min: —", 17)
		h._zakupy_licznik_przebieg_do = h._ui._napis_ekranu("max: —", 17)
		h._zakupy_licznik_przebieg_od.autowrap_mode = TextServer.AUTOWRAP_OFF
		h._zakupy_licznik_przebieg_do.autowrap_mode = TextServer.AUTOWRAP_OFF
		rzad_p.add_child(h._zakupy_licznik_przebieg_od)
		rzad_p.add_child(h._zakupy_licznik_przebieg_do)
		panel_filtr.add_child(rzad_p)
		if przebiegi.is_empty():
			panel_filtr.add_child(h._ui._napis_ekranu("Przedział przebiegu: — (brak liczb).", 16))
			h._zakupy_filtr_przebiegu_wlaczony = false
		else:
			var suwak_p = h.SkryptZakresu.new()
			suwak_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			suwak_p.custom_minimum_size = Vector2(120, 48)
			suwak_p.ustaw_zakres(float(przebiegi[0]), float(przebiegi[przebiegi.size() - 1]))
			h._zakupy_przebieg_od = suwak_p.od
			h._zakupy_przebieg_do = suwak_p.dokad
			h._zakupy_filtr_przebiegu_wlaczony = true
			h._zakupy_licznik_przebieg_od.text = h._ui._tekst_przebiegu_zakresu("min", h._zakupy_przebieg_od)
			h._zakupy_licznik_przebieg_do.text = h._ui._tekst_przebiegu_zakresu("max", h._zakupy_przebieg_do)
			suwak_p.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
				h._zakupy_przebieg_od = od
				h._zakupy_przebieg_do = dokad
				h._zakupy_filtr_przebiegu_wlaczony = true
				if h._zakupy_licznik_przebieg_od != null and is_instance_valid(h._zakupy_licznik_przebieg_od):
					h._zakupy_licznik_przebieg_od.text = h._ui._tekst_przebiegu_zakresu("min", od)
				if h._zakupy_licznik_przebieg_do != null and is_instance_valid(h._zakupy_licznik_przebieg_do):
					h._zakupy_licznik_przebieg_do.text = h._ui._tekst_przebiegu_zakresu("max", dokad)
				_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
			)
			panel_filtr.add_child(suwak_p)
		panel_filtr.add_child(h._ui._napis_ekranu("Marki (kilka naraz; puste = wszystkie):", 17))
		var marki: Array = h._rynek_zakupow.marki_katalogu_aut()
		var szukaj_marek := LineEdit.new()
		szukaj_marek.placeholder_text = "Szukaj marki…"
		szukaj_marek.clear_button_enabled = true
		szukaj_marek.custom_minimum_size = Vector2(0, 40)
		szukaj_marek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		szukaj_marek.add_theme_font_size_override("font_size", 17)
		panel_filtr.add_child(szukaj_marek)
		var scroll_marek := ScrollContainer.new()
		scroll_marek.custom_minimum_size = Vector2(0, mini(180, 36 + marki.size() * 34))
		scroll_marek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kol_marek := VBoxContainer.new()
		kol_marek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kol_marek.add_theme_constant_override("separation", 4)
		scroll_marek.add_child(kol_marek)
		var odswiez_liste_marek := func(zapytanie: String) -> void:
			_wypelnij_checkboxy_marek(
				kol_marek, marki, zapytanie, kat_id, etykiety, nieruchomosc
			)
		szukaj_marek.text_changed.connect(func(t: String) -> void:
			odswiez_liste_marek.call(t)
		)
		odswiez_liste_marek.call("")
		panel_filtr.add_child(scroll_marek)
		var panel_nowe := VBoxContainer.new()
		panel_nowe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_nowe.add_theme_constant_override("separation", 6)
		panel_nowe.visible = (h._zakupy_stan_filtr == "" or h._zakupy_stan_filtr == "nowy")
		h._zakupy_panel_nowe_auta = panel_nowe
		panel_nowe.add_child(h._ui._napis_ekranu("Napęd (nowe):", 17))
		var opcje_naped := OptionButton.new()
		opcje_naped.add_item("Wszystkie", 0)
		var napedy: Array = h._rynek_zakupow.napedy_katalogu_aut()
		for i in napedy.size():
			var n: Variant = napedy[i]
			var nazwa := str(n.get("nazwa", n.get("id", ""))) if n is Dictionary else str(n)
			opcje_naped.add_item(nazwa, i + 1)
		opcje_naped.select(0)
		opcje_naped.custom_minimum_size = Vector2(0, 40)
		opcje_naped.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_naped.add_theme_font_size_override("font_size", 17)
		opcje_naped.item_selected.connect(func(idx: int) -> void:
			if idx <= 0 or idx - 1 >= napedy.size():
				h._zakupy_filtr_naped = ""
			else:
				var n2: Variant = napedy[idx - 1]
				h._zakupy_filtr_naped = str(n2.get("id", "")) if n2 is Dictionary else str(n2)
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_nowe.add_child(opcje_naped)
		panel_filtr.add_child(panel_nowe)
	_podlacz_scroll_aut()
	_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)


func _przerysuj_liste_zakupow(kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	if not h._zakupy_dokladka:
		if kat_id == "samochod":
			_uzupelnij_aut_do_okna(stan_filtr)
		elif h._rynek_zakupow.kategoria_drobna(kat_id):
			_uzupelnij_dobra_do_okna()
		elif h._rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
			_uzupelnij_lokum_do_okna()
	_odswiez_napis_puli_zakupow(kat_id)
	var tresc = h._ui._tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if dziecko.has_meta("zakupy_oferta"):
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	h._zakupy_wiersze = []
	# Cena: włączona gdy jest suwak — także gdy min==0 (stary warunek do>0 wyłączał filtr).
	var filtr_c = h._zakupy_filtr_ceny_wlaczony and h._zakupy_filtr_do >= h._zakupy_filtr_od
	var filtr_p = kat_id == "samochod" and h._zakupy_filtr_przebiegu_wlaczony and h._zakupy_przebieg_do >= h._zakupy_przebieg_od
	var marki_f: Array = []
	var naped_f := ""
	if kat_id == "samochod":
		marki_f = h._zakupy_filtr_marki.duplicate()
		if stan_filtr == "nowy" or stan_filtr == "":
			naped_f = h._zakupy_filtr_naped
	var stan_listy = stan_filtr if (not nieruchomosc or h._rynek_zakupow.kategoria_ma_nowe_lokum(kat_id)) else ""
	var z_poziomem = kat_id == "samochod" or nieruchomosc or h._rynek_zakupow.kategoria_drobna(kat_id)
	var oferty = h._rynek_zakupow.oferty_filtrowane(
		h._swiat,
		kat_id,
		stan_listy,
		h._zakupy_zasieg_km,
		h._zakupy_filtr_od,
		h._zakupy_filtr_do if filtr_c else 1.0e12,
		filtr_c,
		h._zakupy_filtr_odbior,
		h._zakupy_przebieg_od,
		h._zakupy_przebieg_do if filtr_p else 1.0e12,
		filtr_p,
		marki_f,
		naped_f,
		h._zakupy_zasieg_poziom if z_poziomem else "",
	)
	if not nieruchomosc and stan_filtr != "":
		var tylko: Array = []
		for o in oferty:
			if o is Dictionary and str(o.get("stan", "")) == stan_filtr:
				tylko.append(o)
		oferty = tylko
	if kat_id == "samochod":
		oferty = _posortuj_oferty_cena(oferty, h._zakupy_sort_cena)
	if oferty.is_empty():
		var pusto = h._ui._napis_ekranu("Brak ofert w tym filtrze.", 16)
		pusto.set_meta("zakupy_oferta", true)
		tresc.add_child(pusto)
		_dodaj_przycisk_kolejnych_zakupow(tresc, kat_id)
		return
	for o in oferty:
		if not (o is Dictionary):
			continue
		var wiersz := _buduj_skrot_karty_oferty(o, kat_id, stan_filtr, etykiety, nieruchomosc)
		tresc.add_child(wiersz)
		h._zakupy_wiersze.append({"cena": o.get("cena_zl"), "wezel": wiersz})
	_dodaj_przycisk_kolejnych_zakupow(tresc, kat_id)
	if not h._zakupy_dokladka:
		h._zakupy_prefetch_kroki = 0
		call_deferred("_prefetch_zakupy_jesli_blisko")


func _buduj_skrot_karty_oferty(
	o: Dictionary,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> VBoxContainer:
	var wiersz := VBoxContainer.new()
	wiersz.set_meta("zakupy_oferta", true)
	wiersz.add_theme_constant_override("separation", 4)
	if h._rynek_zakupow.kategoria_drobna(kat_id):
		for linia_d in h._rynek_zakupow.linie_karty_drobiazgu(o):
			wiersz.add_child(h._ui._napis_ekranu(str(linia_d), 17))
		var b_d := Button.new()
		b_d.text = "Szczegóły / kup"
		b_d.custom_minimum_size = Vector2(0, 44)
		b_d.add_theme_font_size_override("font_size", 17)
		var oid_d := str(o.get("id", ""))
		b_d.pressed.connect(func() -> void:
			_wejdz_w_karte_oferty(oid_d, kat_id, stan_filtr, etykiety, nieruchomosc)
		)
		wiersz.add_child(b_d)
		return wiersz
	var nazwa := str(o.get("nazwa", o.get("id", "")))
	var stan_txt := str(etykiety.get(str(o.get("stan", "")), o.get("stan", "")))
	var cena_txt = h._ui._tekst_ceny_oferty(o.get("cena_zl"), kat_id)
	if nieruchomosc:
		wiersz.add_child(h._ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 17))
		wiersz.add_child(h._ui._napis_ekranu(h._rynek_zakupow.tekst_karty_miejsca(o), 16))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(h._ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 17))
		var odbior_skrot = h._rynek_zakupow.tekst_odbioru_auta(o) if kat_id == "samochod" else _etykieta_odbioru(str(o.get("sposob_odbioru", "")))
		wiersz.add_child(h._ui._napis_ekranu(h._rynek_zakupow.tekst_karty_miejsca(o, odbior_skrot), 16))
		if kat_id == "samochod" and h._ui._jest_liczba(o.get("przebieg_km")):
			wiersz.add_child(h._ui._napis_ekranu("Przebieg: %s km" % h._ui._tekst_z_odstepami(int(o["przebieg_km"])), 16))
		elif h._ui._jest_liczba(o.get("lata_od_zakupu")):
			wiersz.add_child(h._ui._napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(h._ui._napis_ekranu("Segment: %s" % str(o["segment"]), 15))
	var b_sz := Button.new()
	b_sz.text = "Szczegóły / kup"
	b_sz.custom_minimum_size = Vector2(0, 44)
	b_sz.add_theme_font_size_override("font_size", 17)
	var oid := str(o.get("id", ""))
	b_sz.pressed.connect(func() -> void:
		_wejdz_w_karte_oferty(oid, kat_id, stan_filtr, etykiety, nieruchomosc)
	)
	wiersz.add_child(b_sz)
	return wiersz


func _wejdz_w_karte_oferty(
	oferta_id: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var rodzice: Array = []
	for wpis in h._stos:
		if wpis is Dictionary:
			rodzice.append((wpis as Dictionary).duplicate(true))
	if rodzice.is_empty():
		var zakupy: Dictionary = h._akcje_po_id.get("zakupy", {
			"id": "zakupy", "nazwa": "Zakupy", "tryb": "ekran", "tresc": "zakupy", "kolor": "#b0a04a"
		})
		if zakupy is Dictionary:
			rodzice.append((zakupy as Dictionary).duplicate(true))
		rodzice.append({
			"id": "zakupy_kat_%s" % kat_id,
			"nazwa": str(h._zakupy_kat_slownik.get("nazwa", kat_id)),
			"tryb": "ekran",
			"tresc": "zakupy_kategoria",
			"kat": h._zakupy_kat_slownik if not h._zakupy_kat_slownik.is_empty() else {"id": kat_id, "nazwa": kat_id},
		})
	h._otworz_akcje({
		"id": "zakupy_oferta_%s" % oferta_id,
		"nazwa": "Oferta",
		"tryb": "ekran",
		"tresc": "zakupy_oferta",
		"oferta_id": oferta_id,
		"kat_id": kat_id,
		"stan_filtr": stan_filtr,
		"etykiety": etykiety,
		"nieruchomosc": nieruchomosc,
		"sciezka_rodzicow": rodzice,
	})


func _ekran_zakupy_karta_oferty(akcja: Dictionary) -> void:
	var oid := str(akcja.get("oferta_id", ""))
	var kat_id := str(akcja.get("kat_id", h._zakupy_kat_id))
	var stan_filtr := str(akcja.get("stan_filtr", h._zakupy_stan_filtr))
	var etykiety: Dictionary = akcja.get("etykiety", {}) if akcja.get("etykiety") is Dictionary else {}
	var nieruchomosc := bool(akcja.get("nieruchomosc", false))
	var oferta: Dictionary = {}
	if h._swiat.get("rynek_zakupow") is Dictionary and h._swiat["rynek_zakupow"].get("oferty") is Array:
		for o in h._swiat["rynek_zakupow"]["oferty"]:
			if o is Dictionary and str(o.get("id", "")) == oid:
				oferta = o
				break
	if oferta.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Oferta zniknęła z puli (sprzedana lub odświeżona).", 17))
		return
	h._ui._tytul_bialy().text = str(oferta.get("nazwa", "Oferta"))
	h._ui._tresc_biala().add_child(_buduj_pelna_karte_oferty(oferta, kat_id, stan_filtr, etykiety, nieruchomosc))


func _buduj_pelna_karte_oferty(
	o: Dictionary,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> VBoxContainer:
	var wiersz := VBoxContainer.new()
	wiersz.add_theme_constant_override("separation", 6)
	var nazwa := str(o.get("nazwa", o.get("id", "")))
	var stan_txt := str(etykiety.get(str(o.get("stan", "")), o.get("stan", "")))
	var cena_v: Variant = o.get("cena_zl")
	var cena_txt = h._ui._tekst_ceny_oferty(cena_v, kat_id)
	if h._rynek_zakupow.kategoria_drobna(kat_id):
		for linia_d in h._rynek_zakupow.linie_karty_drobiazgu(o):
			wiersz.add_child(h._ui._napis_ekranu(str(linia_d), 18))
	elif nieruchomosc:
		wiersz.add_child(h._ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 18))
		wiersz.add_child(h._ui._napis_ekranu(h._rynek_zakupow.tekst_karty_miejsca(o), 16))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(h._ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 18))
		var odbior_skrot = h._rynek_zakupow.tekst_odbioru_auta(o) if kat_id == "samochod" else _etykieta_odbioru(str(o.get("sposob_odbioru", "")))
		wiersz.add_child(h._ui._napis_ekranu(h._rynek_zakupow.tekst_karty_miejsca(o, odbior_skrot), 16))
		if h._ui._jest_liczba(o.get("lata_od_zakupu")) and kat_id != "samochod":
			wiersz.add_child(h._ui._napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(h._ui._napis_ekranu("Segment: %s" % str(o["segment"]), 16))
		if o.get("czas_oczekiwania") is Dictionary and not (o["czas_oczekiwania"] as Dictionary).is_empty():
			var cz: Dictionary = o["czas_oczekiwania"]
			wiersz.add_child(h._ui._napis_ekranu(
				"Czas oczekiwania (fabryka): %d lat + %d tyg." % [int(cz.get("lata", 0)), int(cz.get("tygodnie", 0))],
				16
			))
		if kat_id == "samochod":
			if h._ui._jest_liczba(o.get("przebieg_km")):
				wiersz.add_child(h._ui._napis_ekranu("Przebieg: %s km" % h._ui._tekst_z_odstepami(int(o["przebieg_km"])), 16))
			var naped_txt = h._rynek_zakupow.etykieta_napedu(str(o.get("naped", "")))
			if naped_txt != "":
				wiersz.add_child(h._ui._napis_ekranu("Napęd: %s" % naped_txt, 16))
			wiersz.add_child(h._ui._napis_ekranu("Spalanie: %s" % h._rynek_zakupow.tekst_spalania(o), 16))
			if bool(o.get("sprowadzenie", false)) or bool(o.get("import", false)):
				var spr_txt := "Sprowadzenie / import"
				if bool(o.get("szacunek_ceny", false)):
					spr_txt += " (szacunek ceny)"
				var zrd := str(o.get("zrodlo_cennika", ""))
				if zrd != "":
					spr_txt += " · źródło: %s" % zrd
				wiersz.add_child(h._ui._napis_ekranu(spr_txt, 16))
			var znane_u: Array = []
			var dek_u_auto: Array = o.get("usterki_deklarowane", []) if o.get("usterki_deklarowane") is Array else []
			var wyk_u_auto: Array = o.get("usterki_wykryte", []) if o.get("usterki_wykryte") is Array else []
			for uid in dek_u_auto:
				znane_u.append(uid)
			for uid in wyk_u_auto:
				if not znane_u.has(uid):
					znane_u.append(uid)
			var vmax_ui = h._rynek_zakupow.tekst_vmax_oferty(o, znane_u)
			if vmax_ui != "":
				wiersz.add_child(h._ui._napis_ekranu("Prędkość maksymalna: %s km/h" % vmax_ui, 16))
			if bool(o.get("nie_jezdzi", false)) or bool(o.get("do_naprawy", false)):
				wiersz.add_child(h._ui._napis_ekranu("Nie jeździ — do naprawy (laweta / mechanik / złom).", 16))
		var dek_u: Array = o.get("usterki_deklarowane", []) if o.get("usterki_deklarowane") is Array else []
		var wyk_u: Array = o.get("usterki_wykryte", []) if o.get("usterki_wykryte") is Array else []
		var seg_u := str(o.get("segment", ""))
		if not dek_u.is_empty():
			var linia_dek = "Usterki (sprzedawca): %s" % h._ui._join_tekstow(h._rynek_zakupow.nazwy_usterek(dek_u, kat_id, seg_u))
			if bool(o.get("szacunek_usterek", false)):
				linia_dek += " (szacunek)"
			wiersz.add_child(h._ui._napis_ekranu(linia_dek, 16))
		if not wyk_u.is_empty():
			wiersz.add_child(h._ui._napis_ekranu("Usterki wykryte: %s" % h._ui._join_tekstow(h._rynek_zakupow.nazwy_usterek(wyk_u, kat_id, seg_u)), 16))
		if kat_id != "samochod" or str(o.get("stan", "")) != "nowy":
			if h._ui._jest_liczba(o.get("stan_deklarowany")):
				var dek := int(o["stan_deklarowany"])
				var linia_stan = "Stan deklarowany: %d (%s)" % [dek, h._rynek_zakupow.etykieta_stanu_jakosci(dek)]
				if bool(o.get("stan_ujawniony", false)) and h._ui._jest_liczba(o.get("stan_oceniony")):
					var oc := int(o["stan_oceniony"])
					linia_stan += " · ocena: %d (%s)" % [oc, h._rynek_zakupow.etykieta_stanu_jakosci(oc)]
					if h._ui._jest_liczba(o.get("stan_rzeczywisty")) and int(o["stan_deklarowany"]) != int(o["stan_rzeczywisty"]):
						linia_stan += " · rozjazd z deklaracją"
				wiersz.add_child(h._ui._napis_ekranu(linia_stan, 16))
		if h._ui._jest_liczba(o.get("ocena_zaplanowana_tura")):
			wiersz.add_child(h._ui._napis_ekranu("Ocena z pomocą zaplanowana: tura %d" % int(o["ocena_zaplanowana_tura"]), 16))
	var oid := str(o.get("id", ""))
	var tryb_oc = h._rynek_zakupow.tryb_oceny_stanu(o) if not nieruchomosc else "przed_zakupem"
	if tryb_oc != "" and not nieruchomosc and h._ui._jest_liczba(o.get("stan_rzeczywisty")):
		var rzad_ocena := HBoxContainer.new()
		rzad_ocena.add_theme_constant_override("separation", 8)
		var b_ocen := Button.new()
		b_ocen.text = "Oceń stan" if tryb_oc == "przed_zakupem" else "Oceń po oględzinach"
		b_ocen.custom_minimum_size = Vector2(0, 40)
		b_ocen.add_theme_font_size_override("font_size", 17)
		b_ocen.disabled = bool(o.get("stan_ujawniony", false))
		b_ocen.pressed.connect(func() -> void:
			if kat_id == "samochod" and not h._rynek_zakupow.auto_na_miejscu(h._swiat, o):
				_panel_dojazdu(oid, "ocena", kat_id, stan_filtr, etykiety, nieruchomosc)
				return
			var w: Dictionary = h._rynek_zakupow.ocen_stan(h._swiat, oid, false)
			_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
			if bool(w.get("ok", false)):
				var msg := "Ocena stanu: %d (%s)" % [int(w.get("stan_oceniony", 0)), str(w.get("etykieta", ""))]
				if str(w.get("tryb_oceny", "")) == "po_dostawie":
					msg += " (po oględzinach / dostawie)"
				if bool(w.get("rozjazd", false)):
					msg += " — rozjazd względem deklaracji sprzedawcy."
				var uw: Array = w.get("usterki_wykryte", []) if w.get("usterki_wykryte") is Array else []
				if not uw.is_empty():
					msg += " · wykryto: %s" % h._ui._join_tekstow(h._rynek_zakupow.nazwy_usterek(uw, kat_id, str(o.get("segment", ""))))
				_pokaz_komunikat_zakupu(msg, w)
				h.SkryptZapisu.zapisz(h._swiat)
				h._zaplanuj_stos()
		)
		rzad_ocena.add_child(b_ocen)
		var b_pomoc := Button.new()
		b_pomoc.text = "Poproś o pomoc w ocenie"
		b_pomoc.custom_minimum_size = Vector2(0, 40)
		b_pomoc.add_theme_font_size_override("font_size", 17)
		b_pomoc.pressed.connect(func() -> void:
			_panel_pomocy_oceny(oid, kat_id, stan_filtr, etykiety, nieruchomosc)
		)
		rzad_ocena.add_child(b_pomoc)
		wiersz.add_child(rzad_ocena)
	if str(o.get("stan", "")) == "uzywany" and not nieruchomosc and h._ui._jest_liczba(cena_v):
		wiersz.add_child(_buduj_panel_targowania(o, oid, kat_id, stan_filtr, etykiety, nieruchomosc))
	var b := Button.new()
	b.text = "Kup"
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.disabled = bool(o.get("targowanie_zakonczone", false)) and not o.has("cena_wynegocjowana")
	b.pressed.connect(func() -> void:
		if kat_id == "samochod" and not h._rynek_zakupow.auto_na_miejscu(h._swiat, o):
			_panel_dojazdu(oid, "kup", kat_id, stan_filtr, etykiety, nieruchomosc)
			return
		var wynik: Dictionary = h._rynek_zakupow.kup(h._swiat, oid)
		if bool(wynik.get("ok", false)):
			h.SkryptZapisu.zapisz(h._swiat)
			h._stan._zsynchronizuj_pieniadze_z_bohatera()
			h._pasek._odswiez_pasek_statystyk(false)
			h._cofnij_poziom()
		else:
			_pokaz_komunikat_zakupu(str(wynik.get("powod", "Nie kupiono.")), wynik)
	)
	wiersz.add_child(b)
	return wiersz


func _etykieta_odbioru(sposob: String) -> String:
	match sposob:
		"osobisty":
			return "odbiór osobisty"
		"wysylka":
			return "wysyłka"
		"dostawa":
			return "dostawa"
		"oba":
			return "odbiór osobisty / dostawa"
		_:
			return "odbiór osobisty —"


func _pokaz_komunikat_zakupu(tekst: String, _wynik: Dictionary = {}) -> void:
	if tekst.strip_edges() == "":
		return
	var msg = h._ui._napis_ekranu(tekst, 16)
	msg.set_meta("zakupy_oferta", true)
	h._ui._tresc_biala().add_child(msg)


func _panel_pomocy_oceny(oferta_id: String, kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	var kandydaci: Array = h._rynek_zakupow.kandydaci_pomocy_oceny(h._swiat)
	if kandydaci.is_empty():
		_pokaz_komunikat_zakupu("Nikogo nie ma w zapisie (rodzic / przyjaciel / znajomy), kto mógłby pomóc.")
		return
	var oferta = h._rynek_zakupow._znajdz_oferte(h._swiat, oferta_id)
	var trzeba_dojazd = kat_id == "samochod" and not h._rynek_zakupow.auto_na_miejscu(h._swiat, oferta)
	var panel := VBoxContainer.new()
	panel.set_meta("zakupy_oferta", true)
	panel.add_theme_constant_override("separation", 4)
	panel.add_child(h._ui._napis_ekranu("Kto ma pomóc w ocenie?", 14))
	if trzeba_dojazd:
		panel.add_child(h._ui._napis_ekranu("W tym samym kroku wybierz dojazd. Potem jesteś już na miejscu.", 14))
	for k in kandydaci:
		if not (k is Dictionary):
			continue
		var ref := str(k.get("ref", ""))
		var osoba: Dictionary = k.get("osoba", {}) if k.get("osoba") is Dictionary else {}
		if not trzeba_dojazd:
			var btn := Button.new()
			btn.text = "%s (%s)" % [str(k.get("nazwa", "?")), str(k.get("rola", ""))]
			btn.custom_minimum_size = Vector2(0, 34)
			btn.pressed.connect(func() -> void:
				_zakoncz_prosbe_oceny(oferta_id, ref, {}, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(btn)
			continue
		var b_kom := Button.new()
		b_kom.text = "%s — transport publiczny" % str(k.get("nazwa", "?"))
		b_kom.custom_minimum_size = Vector2(0, 36)
		b_kom.pressed.connect(func() -> void:
			_zakoncz_prosbe_oceny(oferta_id, ref, {"sposob": "komunikacja"}, kat_id, stan_filtr, etykiety, nieruchomosc)
		)
		panel.add_child(b_kom)
		if h._rynek_zakupow.kierowca_prosi_o_paliwo(osoba):
			var wycena_p = h._rynek_zakupow.koszt_dojazdu(h._swiat, oferta)
			var paliwo_p: Dictionary = wycena_p.get("paliwo", {}) if wycena_p.get("paliwo") is Dictionary else {}
			var dopisek := ""
			if h._ui._jest_liczba(paliwo_p.get("koszt_zl")):
				dopisek = " (%d zł)" % int(paliwo_p["koszt_zl"])
			panel.add_child(h._ui._napis_ekranu("%s może poprosić o paliwo%s." % [str(k.get("nazwa", "?")), dopisek], 14))
			var b_tak := Button.new()
			b_tak.text = "Podwózka, dołożę do paliwa%s" % dopisek
			b_tak.custom_minimum_size = Vector2(0, 36)
			b_tak.pressed.connect(func() -> void:
				_zakoncz_prosbe_oceny(oferta_id, ref, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": true}, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_tak)
			var b_nie := Button.new()
			b_nie.text = "Podwózka, nie dołożę"
			b_nie.custom_minimum_size = Vector2(0, 36)
			b_nie.pressed.connect(func() -> void:
				_zakoncz_prosbe_oceny(oferta_id, ref, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": false}, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_nie)
		else:
			var b_pod := Button.new()
			b_pod.text = "%s — podwózka" % str(k.get("nazwa", "?"))
			b_pod.custom_minimum_size = Vector2(0, 36)
			b_pod.pressed.connect(func() -> void:
				_zakoncz_prosbe_oceny(oferta_id, ref, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": false}, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_pod)
	h._ui._tresc_biala().add_child(panel)


func _zakoncz_prosbe_oceny(
	oferta_id: String,
	ref: String,
	dojazd: Dictionary,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var w: Dictionary = h._rynek_zakupow.popros_o_pomoc_oceny(h._swiat, oferta_id, ref, dojazd)
	var tekst := str(w.get("tekst", w.get("powod", "")))
	var dojazd_w: Variant = w.get("dojazd", {})
	if dojazd_w is Dictionary and str(dojazd_w.get("tekst", "")) != "":
		tekst = str(dojazd_w.get("tekst", "")) + " " + tekst
	_pokaz_komunikat_zakupu(tekst, w)
	if bool(w.get("ok", false)):
		h.SkryptZapisu.zapisz(h._swiat)
		_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)


func _panel_dojazdu(
	oferta_id: String,
	cel: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var oferta = h._rynek_zakupow._znajdz_oferte(h._swiat, oferta_id)
	var wycena = h._rynek_zakupow.koszt_dojazdu(h._swiat, oferta)
	var panel := VBoxContainer.new()
	panel.set_meta("zakupy_oferta", true)
	panel.add_theme_constant_override("separation", 4)
	panel.add_child(h._ui._napis_ekranu("Jak dojechać do auta?", 16))
	var kom: Dictionary = wycena.get("komunikacja", {}) if wycena.get("komunikacja") is Dictionary else {}
	var b_kom := Button.new()
	b_kom.text = str(kom.get("tekst", "transport publiczny"))
	b_kom.custom_minimum_size = Vector2(0, 40)
	b_kom.pressed.connect(func() -> void:
		_po_dojezdzie(oferta_id, {"sposob": "komunikacja"}, cel, kat_id, stan_filtr, etykiety, nieruchomosc)
	)
	panel.add_child(b_kom)
	var kandydaci: Array = h._rynek_zakupow.kandydaci_pomocy_oceny(h._swiat)
	if kandydaci.is_empty():
		panel.add_child(h._ui._napis_ekranu("Nie ma kogo poprosić o podwózkę.", 14))
	for k in kandydaci:
		if not (k is Dictionary):
			continue
		var ref := str(k.get("ref", ""))
		var osoba: Dictionary = k.get("osoba", {}) if k.get("osoba") is Dictionary else {}
		var nazwa := str(k.get("nazwa", "?"))
		if h._rynek_zakupow.kierowca_prosi_o_paliwo(osoba):
			var paliwo_d: Dictionary = wycena.get("paliwo", {}) if wycena.get("paliwo") is Dictionary else {}
			var dopisek_d := ""
			if h._ui._jest_liczba(paliwo_d.get("koszt_zl")):
				dopisek_d = " (%d zł)" % int(paliwo_d["koszt_zl"])
			var b_tak := Button.new()
			b_tak.text = "Podwózka: %s, dołożę do paliwa%s" % [nazwa, dopisek_d]
			b_tak.custom_minimum_size = Vector2(0, 36)
			b_tak.pressed.connect(func() -> void:
				_po_dojezdzie(oferta_id, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": true}, cel, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_tak)
			var b_nie := Button.new()
			b_nie.text = "Podwózka: %s, nie dołożę" % nazwa
			b_nie.custom_minimum_size = Vector2(0, 36)
			b_nie.pressed.connect(func() -> void:
				_po_dojezdzie(oferta_id, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": false}, cel, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_nie)
		else:
			var b_pod := Button.new()
			b_pod.text = "Podwózka: %s" % nazwa
			b_pod.custom_minimum_size = Vector2(0, 36)
			b_pod.pressed.connect(func() -> void:
				_po_dojezdzie(oferta_id, {"sposob": "podwozka", "osoba_ref": ref, "dolozyc": false}, cel, kat_id, stan_filtr, etykiety, nieruchomosc)
			)
			panel.add_child(b_pod)
	h._ui._tresc_biala().add_child(panel)


func _po_dojezdzie(
	oferta_id: String,
	wybor: Dictionary,
	cel: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var w: Dictionary = h._rynek_zakupow.wykonaj_dojazd(h._swiat, oferta_id, wybor)
	_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
	if not bool(w.get("ok", false)):
		return
	if cel == "ocena":
		var ocena: Dictionary = h._rynek_zakupow.ocen_stan(h._swiat, oferta_id, false)
		_pokaz_komunikat_zakupu(str(ocena.get("tekst", ocena.get("powod", ""))), ocena)
	elif cel == "kup":
		var wynik: Dictionary = h._rynek_zakupow.kup(h._swiat, oferta_id)
		if bool(wynik.get("ok", false)):
			h._stan._zsynchronizuj_pieniadze_z_bohatera()
			h._pasek._odswiez_pasek_statystyk(false)
			h.SkryptZapisu.zapisz(h._swiat)
			h._cofnij_poziom()
			return
		_pokaz_komunikat_zakupu(str(wynik.get("powod", "Nie kupiono.")), wynik)
	h.SkryptZapisu.zapisz(h._swiat)
	_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)


func _buduj_panel_targowania(
	oferta: Dictionary,
	oid: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> Control:
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 4)
	if bool(oferta.get("targowanie_zakonczone", false)) and not oferta.has("cena_wynegocjowana"):
		panel.add_child(h._ui._napis_ekranu("Targowanie zakończone — sprzedawca nie chce rozmawiać.", 13))
		return panel
	var cena0 := float(oferta.get("cena_wyjsciowa", oferta.get("cena_zl", 0)))
	var conf_dane := _wczytaj_zakupy_oferty()
	var tconf: Dictionary = conf_dane.get("targowanie", {}) if conf_dane.get("targowanie") is Dictionary else {}
	var p_od := float(tconf.get("suwak_procent_od", 50))
	var p_do := float(tconf.get("suwak_procent_do", 100))
	var etykieta = h._ui._napis_ekranu("Targuj: 90% ceny = %d zł" % int(round(cena0 * 0.9)), 13)
	panel.add_child(etykieta)
	var suwak := HSlider.new()
	suwak.min_value = p_od
	suwak.max_value = p_do
	suwak.step = 1.0
	suwak.value = 90.0
	suwak.custom_minimum_size = Vector2(0, 32)
	suwak.value_changed.connect(func(v: float) -> void:
		var kw := int(round(cena0 * v / 100.0))
		etykieta.text = "Targuj: %d%% ceny (−%d%% / −%d zł) → %d zł" % [
			int(v),
			int(100.0 - v),
			int(round(cena0 - float(kw))),
			kw,
		]
	)
	suwak.value_changed.emit(suwak.value)
	panel.add_child(suwak)
	var dialog_lbl = h._ui._napis_ekranu("", 13)
	dialog_lbl.visible = false
	panel.add_child(dialog_lbl)
	var b_targ := Button.new()
	b_targ.text = "Zaproponuj sprzedawcy"
	b_targ.custom_minimum_size = Vector2(0, 34)
	b_targ.pressed.connect(func() -> void:
		var w: Dictionary = h._rynek_zakupow.targuj(h._swiat, oid, null, suwak.value)
		var tekst := str(w.get("tekst", w.get("powod", "")))
		dialog_lbl.text = tekst
		dialog_lbl.visible = tekst != ""
		if bool(w.get("ok", false)):
			h.SkryptZapisu.zapisz(h._swiat)
			if str(w.get("wynik", "")) == "akceptacja" or bool(w.get("koniec", false)):
				if not h._stos.is_empty() and str(h._stos[h._stos.size() - 1].get("tresc", "")) == "zakupy_oferta":
					h._zaplanuj_stos()
				else:
					_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)
	)
	panel.add_child(b_targ)
	return panel


func _on_zakupy_filtr_ceny(od: float, dokad: float) -> void:
	h._zakupy_filtr_od = od
	h._zakupy_filtr_do = dokad
	h._zakupy_filtr_ceny_wlaczony = true
	if h._zakupy_licznik_od != null and is_instance_valid(h._zakupy_licznik_od):
		h._zakupy_licznik_od.text = "min: %d" % int(od)
	if h._zakupy_licznik_do != null and is_instance_valid(h._zakupy_licznik_do):
		h._zakupy_licznik_do.text = "max: %d" % int(dokad)


## Prefiks (begins_with) najpierw, potem contains; puste = cała lista. Bez zmiany wielkości liter.
static func marki_pasujace_do_szukania(marki: Array, zapytanie: String) -> Array:
	var q := zapytanie.strip_edges().to_lower()
	if q == "":
		return marki.duplicate()
	var prefiks: Array = []
	var zawiera: Array = []
	for m in marki:
		var nazwa := str(m)
		var n := nazwa.to_lower()
		if n.begins_with(q):
			prefiks.append(nazwa)
		elif n.contains(q):
			zawiera.append(nazwa)
	return prefiks + zawiera


func _wypelnij_checkboxy_marek(
	kol_marek: VBoxContainer,
	wszystkie_marki: Array,
	zapytanie: String,
	kat_id: String,
	etykiety: Dictionary,
	nieruchomosc: bool,
) -> void:
	for dziecko in kol_marek.get_children():
		kol_marek.remove_child(dziecko)
		dziecko.queue_free()
	# Zaznaczenia żyją w _zakupy_filtr_marki — niewidoczne po filtrze zostają zaznaczone.
	var widoczne: Array = marki_pasujace_do_szukania(wszystkie_marki, zapytanie)
	for marka_n in widoczne:
		var cb := CheckBox.new()
		cb.text = str(marka_n)
		cb.button_pressed = h._zakupy_filtr_marki.has(str(marka_n))
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.add_theme_font_size_override("font_size", 17)
		cb.toggled.connect(func(wlaczony: bool) -> void:
			var m := str(marka_n)
			if wlaczony:
				if not h._zakupy_filtr_marki.has(m):
					h._zakupy_filtr_marki.append(m)
			else:
				h._zakupy_filtr_marki.erase(m)
			_przerysuj_liste_zakupow(kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		kol_marek.add_child(cb)


func _odswiez_rynek_zakupow() -> void:
	if h._swiat.is_empty():
		return
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	var mid = h._stan._id_miejsca_pobytu()
	h._rynek_zakupow.zapewnij_pule(h._swiat, miasta, mid, int(h._swiat.get("tydzien", 1)))


func _filtry_aut(stan_filtr: String) -> Dictionary:
	var filtr_c = h._zakupy_filtr_ceny_wlaczony and h._zakupy_filtr_do >= h._zakupy_filtr_od
	var filtr_p = h._zakupy_filtr_przebiegu_wlaczony and h._zakupy_przebieg_do >= h._zakupy_przebieg_od
	return {
		"poziom": h._zakupy_zasieg_poziom,
		"km": h._zakupy_zasieg_km,
		"stan": stan_filtr,
		"cena_od": h._zakupy_filtr_od,
		"cena_do": h._zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"przebieg_od": h._zakupy_przebieg_od,
		"przebieg_do": h._zakupy_przebieg_do if filtr_p else 1.0e12,
		"filtruj_przebieg": filtr_p,
		"marki": h._zakupy_filtr_marki.duplicate(),
		"naped": h._zakupy_filtr_naped if stan_filtr == "nowy" or stan_filtr == "" else "",
		"tydzien": int(h._swiat.get("tydzien", 1)),
	}


func _odswiez_napis_puli_zakupow(kat_id: String) -> void:
	if h._zakupy_pula_lbl == null or not is_instance_valid(h._zakupy_pula_lbl):
		return
	if not h._rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		h._zakupy_pula_lbl.visible = false
		h._zakupy_pula_lbl.text = ""
		return
	if kat_id == "samochod" and h._zakupy_stan_filtr == "nowy":
		h._zakupy_pula_lbl.visible = true
		h._zakupy_pula_lbl.text = "Nowe auta: salony, bez puli z ludności."
		return
	var strona := _strona_puli_zakupow(kat_id)
	var n: int = h._rynek_zakupow.pula_w_zasiegu(h._zakupy_zasieg_poziom, h._stan._id_miejsca_pobytu(), kat_id, strona)
	if n < 0:
		h._zakupy_pula_lbl.visible = false
		h._zakupy_pula_lbl.text = ""
		return
	h._zakupy_pula_lbl.visible = true
	var co := "nowych" if strona == "nowy" else "używanych"
	h._zakupy_pula_lbl.text = "Ogłoszeń %s w tym zasięgu: %d" % [co, n]


func _dodaj_przycisk_kolejnych_zakupow(tresc: Node, kat_id: String) -> void:
	if not h._rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		return
	var strona := _strona_puli_zakupow(kat_id)
	var pula: int = h._rynek_zakupow.pula_w_zasiegu(h._zakupy_zasieg_poziom, h._stan._id_miejsca_pobytu(), kat_id, strona)
	var jest: int = h._rynek_zakupow.ile_w_zasiegu(h._swiat, kat_id, h._zakupy_zasieg_poziom, strona)
	if pula < 0 or jest >= pula:
		return
	var b := Button.new()
	b.text = "Pokaż kolejne"
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 17)
	b.set_meta("zakupy_oferta", true)
	b.pressed.connect(_dokladka_zakupow)
	tresc.add_child(b)


func _filtry_lokum() -> Dictionary:
	var filtr_c = h._zakupy_filtr_ceny_wlaczony and h._zakupy_filtr_do >= h._zakupy_filtr_od
	return {
		"poziom": h._zakupy_zasieg_poziom,
		"km": h._zakupy_zasieg_km,
		"kategoria": h._zakupy_kat_id,
		"stan": _strona_generacji_lokum(),
		"cena_od": h._zakupy_filtr_od,
		"cena_do": h._zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"tydzien": int(h._swiat.get("tydzien", 1)),
	}


func _uzupelnij_lokum_do_okna() -> int:
	var filtry := _filtry_lokum()
	var jest: Array = h._rynek_zakupow.oferty_filtrowane(
		h._swiat,
		h._zakupy_kat_id,
		str(filtry.get("stan", "")),
		float(filtry["km"]),
		float(filtry["cena_od"]),
		float(filtry["cena_do"]),
		bool(filtry["filtruj_cene"]),
		"",
		0.0,
		1.0e12,
		false,
		[],
		"",
		str(filtry["poziom"])
	)
	var brak = h._rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	return h._rynek_zakupow.uzupelnij_okno_lokum(h._swiat, miasta, filtry, brak)


func _uzupelnij_aut_do_okna(stan_filtr: String) -> int:
	var filtry := _filtry_aut(stan_filtr)
	var jest: Array = h._rynek_zakupow.oferty_filtrowane(
		h._swiat,
		"samochod",
		stan_filtr,
		float(filtry["km"]),
		float(filtry["cena_od"]),
		float(filtry["cena_do"]),
		bool(filtry["filtruj_cene"]),
		"",
		float(filtry["przebieg_od"]),
		float(filtry["przebieg_do"]),
		bool(filtry["filtruj_przebieg"]),
		filtry["marki"],
		str(filtry["naped"]),
		str(filtry["poziom"])
	)
	var brak = h._rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	return h._rynek_zakupow.uzupelnij_okno_aut(h._swiat, miasta, filtry, brak)


func _podlacz_scroll_aut() -> void:
	if h._zakupy_scroll_podpiety:
		return
	var sc := _scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek == null:
		return
	pasek.value_changed.connect(_na_scroll_aut)
	h._zakupy_scroll_podpiety = true


func _scroll_zakupow() -> ScrollContainer:
	var tresc = h._ui._tresc_biala()
	if tresc.get_parent() is ScrollContainer:
		return tresc.get_parent() as ScrollContainer
	return null


func _na_scroll_aut(wartosc: float) -> void:
	if not h._rynek_zakupow.kategoria_ma_pule_ludnosci(h._zakupy_kat_id) or h._zakupy_dokladka:
		return
	var sc := _scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek.max_value <= sc.size.y + 8.0:
		return
	var zostalo := pasek.max_value - wartosc - sc.size.y
	if not RynekZakupow.trzeba_dociagnac_przed_koncem(zostalo):
		return
	_dokladka_zakupow()


func _prefetch_zakupy_jesli_blisko() -> void:
	if h._zakupy_dokladka or h._zakupy_prefetch_kroki >= 3:
		return
	if not h._rynek_zakupow.kategoria_ma_pule_ludnosci(h._zakupy_kat_id):
		return
	var sc := _scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek == null or pasek.max_value <= sc.size.y + 8.0:
		return
	var zostalo := pasek.max_value - pasek.value - sc.size.y
	if not RynekZakupow.trzeba_dociagnac_przed_koncem(zostalo):
		return
	h._zakupy_prefetch_kroki += 1
	if _dokladka_zakupow() > 0:
		call_deferred("_prefetch_zakupy_jesli_blisko")


func _strona_puli_zakupow(kat_id: String) -> String:
	if h._zakupy_stan_filtr == "nowy" and (h._rynek_zakupow.kategoria_ma_nowe_lokum(kat_id) or h._rynek_zakupow.kategoria_drobna(kat_id)):
		return "nowy"
	return "uzywany"


func _strona_generacji_lokum() -> String:
	if h._rynek_zakupow.kategoria_ma_nowe_lokum(h._zakupy_kat_id) and h._zakupy_stan_filtr == "nowy":
		return "nowy"
	return "uzywany"


func _strona_generacji_dobr() -> String:
	if h._zakupy_stan_filtr == "nowy":
		return "nowy"
	return "uzywany"


func _filtry_dobra() -> Dictionary:
	var filtr_c = h._zakupy_filtr_ceny_wlaczony and h._zakupy_filtr_do >= h._zakupy_filtr_od
	return {
		"poziom": h._zakupy_zasieg_poziom,
		"km": h._zakupy_zasieg_km,
		"kategoria": h._zakupy_kat_id,
		"stan": _strona_generacji_dobr(),
		"cena_od": h._zakupy_filtr_od,
		"cena_do": h._zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"tydzien": int(h._swiat.get("tydzien", 1)),
	}


func _uzupelnij_dobra_do_okna() -> int:
	var filtry := _filtry_dobra()
	var jest: Array = h._rynek_zakupow.oferty_filtrowane(
		h._swiat,
		h._zakupy_kat_id,
		str(filtry.get("stan", "")),
		float(filtry["km"]),
		float(filtry["cena_od"]),
		float(filtry["cena_do"]),
		bool(filtry["filtruj_cene"]),
		"",
		0.0,
		1.0e12,
		false,
		[],
		"",
		str(filtry["poziom"])
	)
	var brak = h._rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	return h._rynek_zakupow.uzupelnij_okno_dobr(h._swiat, miasta, filtry, brak)


func _dokladka_zakupow() -> int:
	if not h._rynek_zakupow.kategoria_ma_pule_ludnosci(h._zakupy_kat_id) or h._zakupy_dokladka:
		return 0
	h._zakupy_dokladka = true
	var przed := 0
	if h._swiat.get("rynek_zakupow") is Dictionary and h._swiat["rynek_zakupow"].get("oferty") is Array:
		przed = (h._swiat["rynek_zakupow"]["oferty"] as Array).size()
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	var dodano := 0
	if h._zakupy_kat_id == "samochod":
		dodano = h._rynek_zakupow.uzupelnij_okno_aut(h._swiat, miasta, _filtry_aut(h._zakupy_stan_filtr), RynekZakupow.WYPRZEDZENIE_AUT)
	elif h._rynek_zakupow.kategoria_drobna(h._zakupy_kat_id):
		dodano = h._rynek_zakupow.uzupelnij_okno_dobr(h._swiat, miasta, _filtry_dobra(), RynekZakupow.WYPRZEDZENIE_AUT)
	else:
		dodano = h._rynek_zakupow.uzupelnij_okno_lokum(h._swiat, miasta, _filtry_lokum(), RynekZakupow.WYPRZEDZENIE_AUT)
	if dodano > 0:
		_dopisz_karty_zakupow(przed)
		_odswiez_napis_puli_zakupow(h._zakupy_kat_id)
	h._zakupy_dokladka = false
	return dodano


func _dopisz_karty_zakupow(przed: int) -> void:
	var tresc = h._ui._tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if not dziecko.has_meta("zakupy_oferta"):
			continue
		if dziecko is Button or dziecko is Label:
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	var stan: Variant = h._swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		_dodaj_przycisk_kolejnych_zakupow(tresc, h._zakupy_kat_id)
		return
	var oferty: Array = stan["oferty"]
	var widoczne := {}
	for o in _oferty_na_liscie_zakupow():
		if o is Dictionary:
			widoczne[str(o.get("id", ""))] = o
	var dane := _wczytaj_zakupy_oferty()
	var etykiety: Dictionary = dane.get("etykiety_stanu", {}) if dane.get("etykiety_stanu") is Dictionary else {}
	var nieruchomosc = h._rynek_zakupow.kategoria_lokum(h._zakupy_kat_id)
	for i in range(przed, oferty.size()):
		var o: Variant = oferty[i]
		if not (o is Dictionary):
			continue
		var id := str(o.get("id", ""))
		if not widoczne.has(id):
			continue
		var wiersz = _buduj_skrot_karty_oferty(widoczne[id], h._zakupy_kat_id, h._zakupy_stan_filtr, etykiety, nieruchomosc)
		tresc.add_child(wiersz)
		h._zakupy_wiersze.append({"cena": o.get("cena_zl"), "wezel": wiersz})
	_dodaj_przycisk_kolejnych_zakupow(tresc, h._zakupy_kat_id)


func _oferty_na_liscie_zakupow() -> Array:
	var kat_id = h._zakupy_kat_id
	var nieruchomosc = h._rynek_zakupow.kategoria_lokum(kat_id)
	var filtr_c = h._zakupy_filtr_ceny_wlaczony and h._zakupy_filtr_do >= h._zakupy_filtr_od
	var filtr_p = kat_id == "samochod" and h._zakupy_filtr_przebiegu_wlaczony and h._zakupy_przebieg_do >= h._zakupy_przebieg_od
	var stan_listy = h._zakupy_stan_filtr if (not nieruchomosc or h._rynek_zakupow.kategoria_ma_nowe_lokum(kat_id)) else ""
	var marki_f: Array = []
	var naped_f := ""
	if kat_id == "samochod":
		marki_f = h._zakupy_filtr_marki.duplicate()
		if h._zakupy_stan_filtr == "nowy" or h._zakupy_stan_filtr == "":
			naped_f = h._zakupy_filtr_naped
	return h._rynek_zakupow.oferty_filtrowane(
		h._swiat,
		kat_id,
		stan_listy,
		h._zakupy_zasieg_km,
		h._zakupy_filtr_od,
		h._zakupy_filtr_do if filtr_c else 1.0e12,
		filtr_c,
		h._zakupy_filtr_odbior,
		h._zakupy_przebieg_od,
		h._zakupy_przebieg_do if filtr_p else 1.0e12,
		filtr_p,
		marki_f,
		naped_f,
		h._zakupy_zasieg_poziom if kat_id == "samochod" or nieruchomosc or h._rynek_zakupow.kategoria_drobna(kat_id) else ""
	)


func _aktywuj_zakladke_samochodow() -> void:
	if h._swiat.is_empty():
		return
	var miasta: Array = h._losowanie.miasta_polski() if h._losowanie != null else []
	h._rynek_zakupow.aktywuj_zakladke_samochodow(
		h._swiat, miasta, h._stan._id_miejsca_pobytu(), int(h._swiat.get("tydzien", 1))
	)


func _posortuj_oferty_cena(oferty: Array, tryb: String) -> Array:
	var kopia: Array = oferty.duplicate()
	kopia.sort_custom(func(a, b) -> bool:
		var ca := float(a.get("cena_zl", -1)) if a is Dictionary and h._ui._jest_liczba(a.get("cena_zl")) else -1.0
		var cb := float(b.get("cena_zl", -1)) if b is Dictionary and h._ui._jest_liczba(b.get("cena_zl")) else -1.0
		if tryb == "rosnaco":
			return ca < cb
		return ca > cb
	)
	return kopia


func _wczytaj_zakupy_oferty() -> Dictionary:
	if h._zakupy_dane is Dictionary:
		return h._zakupy_dane
	if not FileAccess.file_exists(h.PLIK_ZAKUPOW_OFERT):
		return {}
	var plik = FileAccess.open(h.PLIK_ZAKUPOW_OFERT, FileAccess.READ)
	if plik == null:
		return {}
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		h._zakupy_dane = dane
		return dane
	return {}


func _etykieta_stanu_zakupu(id: String) -> String:
	var dane := _wczytaj_zakupy_oferty()
	if dane.get("etykiety_stanu") is Dictionary and dane["etykiety_stanu"].has(id):
		return str(dane["etykiety_stanu"][id])
	return id
