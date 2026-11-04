extends RefCounted
class_name EkranJedzenia

## Ekrany jedzenia w domu i samemu.

var h


func _init(host) -> void:
	h = host




func _jedzenie_odblok_cfg() -> Variant:
	if not FileAccess.file_exists("res://postacie/jedzenie_ustawienia.json"):
		return null
	var plik := FileAccess.open("res://postacie/jedzenie_ustawienia.json", FileAccess.READ)
	if plik == null:
		return null
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		return dane.get("odblokowanie_jedzenie_samemu", null)
	return null


func _czy_jedzenie_sam_po_wieku() -> bool:
	var cfg: Variant = _jedzenie_odblok_cfg()
	var prog := 8
	if cfg is Dictionary and h._ui._jest_liczba(cfg.get("prog_wiek_lat")):
		prog = int(cfg["prog_wiek_lat"])
	var wiek: Variant = h._stan._wiek_lat()
	return h._ui._jest_liczba(wiek) and int(wiek) >= prog


func _odswiez_flage_jedzenia_sam() -> void:
	if bool(h._swiat.get("odblokowane_jedzenie_samemu", false)):
		return
	if _czy_jedzenie_sam_po_wieku():
		h._swiat["odblokowane_jedzenie_samemu"] = true


func _ekran_jedzenie_dom(kolor: Color) -> void:
	h._zdanie = h._ui._napis_ekranu("", 18)
	h._zdanie.add_theme_color_override("font_color", Color(h.KRWISTY))
	h._ui._tresc_biala().add_child(h._zdanie)
	h._wplyw_domu = h._ui._rich_ekran()
	h._ui._tresc_biala().add_child(h._wplyw_domu)
	h._ui._tresc_biala().add_child(h._ui._ramka_suwaka("Cena", kolor, _suwak_jedzenia("cena")))
	h._ui._tresc_biala().add_child(h._ui._ramka_suwaka("Składniki odżywcze", kolor, _suwak_jedzenia("skladniki")))
	h._ui._tresc_biala().add_child(h._ui._ramka_suwaka("Dieta ogólna", kolor, _suwak_jedzenia("dieta_ogolna")))
	var diety := VBoxContainer.new()
	diety.add_theme_constant_override("separation", 4)
	var wege := CheckButton.new()
	wege.text = "Wegetariańska"
	wege.button_pressed = bool(h._jedzenie.stan_roboczy().get("wegetarianska", false))
	wege.toggled.connect(func(wlaczona: bool) -> void:
		h._jedzenie.ustaw_diete("wegetarianska", wlaczona)
		_odswiez_napisy_domu()
	)
	var weganska := CheckButton.new()
	weganska.text = "Wegańska"
	weganska.button_pressed = bool(h._jedzenie.stan_roboczy().get("weganska", false))
	weganska.toggled.connect(func(wlaczona: bool) -> void:
		h._jedzenie.ustaw_diete("weganska", wlaczona)
		_odswiez_napisy_domu()
	)
	diety.add_child(wege)
	diety.add_child(weganska)
	h._ui._tresc_biala().add_child(h._ui._ramka_z_dolnym("Dieta", kolor, diety, null))
	h._ui._tresc_biala().add_child(h._ui._ramka_suwaka("Dieta gotowania własnego", kolor, _suwak_jedzenia("dieta_wlasna")))
	h._efekt_dni = h._ui._rich_ekran()
	var dni_srodek := VBoxContainer.new()
	dni_srodek.add_child(h._efekt_dni)
	var dni = h._ui._kropki_dni(h._jedzenie.dni_gotowania(), _ustaw_dni_gotowania_z_ekranu)
	h._ui._tresc_biala().add_child(h._ui._ramka_z_dolnym("Ile dni w tygodniu gotujesz", kolor, dni_srodek, dni))
	for pozycja in h._jedzenie.pozycje_gdzie("dom"):
		if pozycja is Dictionary:
			h._ui._tresc_biala().add_child(_wiersz_pozycji(pozycja, false))
	var zatwierdz := Button.new()
	zatwierdz.text = "Zatwierdź"
	zatwierdz.custom_minimum_size = Vector2(0, 48)
	zatwierdz.pressed.connect(func() -> void:
		h._jedzenie.zatwierdz()
		_odswiez_napisy_domu()
		h._pasek._odswiez_pasek_statystyk(true)
	)
	h._ui._tresc_biala().add_child(zatwierdz)
	_odswiez_napisy_domu()


func _ekran_jedzenie_sam(_kolor: Color) -> void:
	_odswiez_flage_jedzenia_sam()
	if not bool(h._swiat.get("odblokowane_jedzenie_samemu", false)):
		var tekst_blok := "Jeszcze nie jesz samemu poza domem."
		var cfg: Variant = _jedzenie_odblok_cfg()
		if cfg is Dictionary and str(cfg.get("tekst_zablokowane", "")) != "":
			tekst_blok = str(cfg["tekst_zablokowane"])
		var prog_txt := ""
		if cfg is Dictionary and h._ui._jest_liczba(cfg.get("prog_wiek_lat")):
			prog_txt = " (próg wieku: %d lat — propozycja do poprawki)" % int(cfg["prog_wiek_lat"])
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(tekst_blok + prog_txt, 16))
		return
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Jakość zdrowotna poza domem (osobno od smaku/ceny; propozycja, nie medyczne %).", 13))
	var jak_cfg: Variant = null
	var dane_j: Variant = h._jedzenie.wczytaj()
	if dane_j is Dictionary:
		jak_cfg = dane_j.get("jakosc_zdrowotna_poza_domem", {})
	var j_min := 0
	var j_max := 100
	var j_krok := 5
	if jak_cfg is Dictionary:
		if h._ui._jest_liczba(jak_cfg.get("min")):
			j_min = int(jak_cfg["min"])
		if h._ui._jest_liczba(jak_cfg.get("max")):
			j_max = int(jak_cfg["max"])
		if h._ui._jest_liczba(jak_cfg.get("krok")):
			j_krok = int(jak_cfg["krok"])
	var j_wart := int(h._swiat.get("jakosc_zdrowotna_poza_domem", 50))
	var j_opis = h._ui._napis_ekranu("Jakość zdrowotna: %d" % j_wart, 15)
	h._ui._tresc_biala().add_child(j_opis)
	var j_suwak := HSlider.new()
	j_suwak.min_value = float(j_min)
	j_suwak.max_value = float(j_max)
	j_suwak.step = float(j_krok)
	j_suwak.value = float(clampi(j_wart, j_min, j_max))
	j_suwak.custom_minimum_size = Vector2(0, 36)
	j_suwak.value_changed.connect(func(v: float) -> void:
		h._swiat["jakosc_zdrowotna_poza_domem"] = int(v)
		j_opis.text = "Jakość zdrowotna: %d" % int(v)
	)
	h._ui._tresc_biala().add_child(j_suwak)
	var komunikat = h._ui._napis_ekranu("", 16)
	h._ui._tresc_biala().add_child(komunikat)
	var ceny: Array = []
	for pozycja in h._jedzenie.pozycje_gdzie("sam"):
		if not (pozycja is Dictionary):
			continue
		if h._ui._jest_liczba(pozycja.get("cena_zl")):
			ceny.append(float(pozycja["cena_zl"]))
		h._ui._tresc_biala().add_child(_wiersz_pozycji(pozycja, true, komunikat))
	h._ui._dol_suwaka().show()
	if ceny.is_empty():
		h._filtr_aktywny = false
		h._ui._dol_suwaka().add_child(h._ui._z_marginesem(h._ui._napis_ekranu("—", 20)))
		return
	ceny.sort()
	var suwak = h.SkryptZakresu.new()
	suwak.ustaw_zakres(float(ceny[0]), float(ceny[ceny.size() - 1]))
	h._filtr_aktywny = true
	h._filtr_od = suwak.od
	h._filtr_do = suwak.dokad
	suwak.zakres_zmieniony.connect(_on_filtr_ceny)
	h._ui._dol_suwaka().add_child(h._ui._z_marginesem(suwak))
	_zastosuj_filtr()


func _wiersz_pozycji(pozycja: Dictionary, sam: bool, komunikat: Label = null) -> Control:
	var id := str(pozycja.get("id", ""))
	var prawa := VBoxContainer.new()
	prawa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prawa.add_theme_constant_override("separation", 4)
	var nazwa := Button.new()
	nazwa.text = str(pozycja.get("nazwa", ""))
	nazwa.alignment = HORIZONTAL_ALIGNMENT_LEFT
	nazwa.custom_minimum_size = Vector2(0, 40)
	nazwa.pressed.connect(_zjedz_pozycje.bind(id, komunikat))
	var cena = h._ui._napis_ekranu(h._ui._tekst_ceny(pozycja.get("cena_zl")), 16)
	var jakosc_txt := ""
	if h._ui._jest_liczba(pozycja.get("jakosc_propozycja")):
		jakosc_txt = "Jakość (propozycja): %d" % int(pozycja["jakosc_propozycja"])
	elif not sam:
		jakosc_txt = "Jakość: —"
	var jakosc_lbl = h._ui._napis_ekranu(jakosc_txt, 13) if jakosc_txt != "" else null
	var ster := HBoxContainer.new()
	ster.add_theme_constant_override("separation", 6)
	var licznik = h._ui._napis_ekranu(str(h._jedzenie.ilosc_pozycji(id)), 20)
	licznik.custom_minimum_size = Vector2(36, 48)
	licznik.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(48, 48)
	plus.pressed.connect(_zmien_ilosc.bind(id, 1, licznik))
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(48, 48)
	minus.pressed.connect(_zmien_ilosc.bind(id, -1, licznik))
	# Lewy −, prawy + (naturalniej niż +/−).
	ster.add_child(minus)
	ster.add_child(licznik)
	ster.add_child(plus)
	var efekty = h._ui._rich_ekran()
	efekty.text = h._jedzenie.bb_pozycji(id)
	prawa.add_child(nazwa)
	prawa.add_child(cena)
	if jakosc_lbl != null:
		prawa.add_child(jakosc_lbl)
	prawa.add_child(ster)
	prawa.add_child(efekty)
	var rodzice = h._ui._napis_ekranu("", 15)
	if not sam:
		var stan = h._jedzenie.tekst_rodzicow_przy(id)
		rodzice.text = stan
		rodzice.visible = stan != ""
		prawa.add_child(rodzice)
		h._efekty_domu.append({"id": id, "rich": efekty, "rodzice": rodzice})
	if sam:
		h._wiersze_sam.append({"cena": pozycja.get("cena_zl", null), "wezel": prawa})
	return prawa


func _on_filtr_ceny(od: float, dokad: float) -> void:
	h._filtr_aktywny = true
	h._filtr_od = od
	h._filtr_do = dokad
	_zastosuj_filtr()


func _zastosuj_filtr() -> void:
	for wpis in h._wiersze_sam:
		if not (wpis is Dictionary):
			continue
		var wezel: Variant = wpis.get("wezel")
		if not (wezel is CanvasItem) or not is_instance_valid(wezel):
			continue
		var pokaz := true
		if h._filtr_aktywny and h._ui._jest_liczba(wpis.get("cena")):
			var cena := float(wpis["cena"])
			pokaz = cena >= h._filtr_od - 0.001 and cena <= h._filtr_do + 0.001
		wezel.visible = pokaz


func _suwak_jedzenia(id: String) -> HSlider:
	var zakres = h._jedzenie.zakres_suwaka(id if id != "dieta_ogolna" and id != "dieta_wlasna" else "cena")
	if id == "dieta_ogolna" or id == "dieta_wlasna":
		zakres = {"min": 0, "max": 100}
	var suwak := HSlider.new()
	suwak.min_value = float(zakres.get("min", 0))
	suwak.max_value = float(zakres.get("max", 100))
	suwak.step = 1.0
	suwak.custom_minimum_size = Vector2(0, 36)
	var stan = h._jedzenie.stan_roboczy()
	var pole := id
	var flaga := id + "_ustawiona"
	if id == "skladniki":
		pole = "skladniki"
		flaga = "skladniki_ustawione"
	if bool(stan.get(flaga, false)) and h._ui._jest_liczba(stan.get(pole)):
		suwak.set_value_no_signal(float(stan[pole]))
	else:
		suwak.set_value_no_signal(suwak.min_value)
	suwak.value_changed.connect(func(wartosc: float) -> void:
		if id == "dieta_ogolna" or id == "dieta_wlasna":
			h._jedzenie.ustaw_diete_suwak(id, int(wartosc))
		else:
			h._jedzenie.ustaw_suwak(id, int(wartosc))
		_odswiez_napisy_domu()
	)
	return suwak


func _ustaw_dni_gotowania_z_ekranu(dzien: int) -> void:
	h._jedzenie.ustaw_dni_gotowania(dzien)
	h._zaplanuj_stos()


func _odswiez_napisy_domu() -> void:
	if h._zdanie != null and is_instance_valid(h._zdanie):
		var tekst = h._jedzenie.zdanie_domu()
		h._zdanie.text = tekst
		h._zdanie.visible = tekst != ""
	if h._wplyw_domu != null and is_instance_valid(h._wplyw_domu):
		var bb = h._jedzenie.bb_znakow(h._jedzenie.zbiorcze())
		h._wplyw_domu.text = bb
		h._wplyw_domu.visible = bb != ""
	if h._efekt_dni != null and is_instance_valid(h._efekt_dni):
		h._efekt_dni.text = h._jedzenie.efekt_gotowania_tekst()
		h._efekt_dni.visible = h._efekt_dni.text != ""
	for wpis in h._efekty_domu:
		if not (wpis is Dictionary):
			continue
		var efekty: Variant = wpis.get("rich")
		if efekty is RichTextLabel and is_instance_valid(efekty):
			efekty.text = h._jedzenie.bb_pozycji(str(wpis.get("id", "")))
		var rodzice: Variant = wpis.get("rodzice")
		if rodzice is Label and is_instance_valid(rodzice):
			var stan = h._jedzenie.tekst_rodzicow_przy(str(wpis.get("id", "")))
			rodzice.text = stan
			rodzice.visible = stan != ""


func _wybierz_klase(id: String) -> void:
	h._swiat["klasa_transportu"] = id


func _zjedz_pozycje(id: String, komunikat: Variant) -> void:
	var wynik = h._jedzenie.zjedz(id)
	if komunikat != null and is_instance_valid(komunikat):
		komunikat.text = str(wynik.get("komunikat", ""))
	h._pasek._odswiez_pasek_statystyk(true)
	_odswiez_napisy_domu()


func _zmien_ilosc(id: String, delta: int, licznik: Label) -> void:
	h._jedzenie.ustaw_ilosc_pozycji(id, h._jedzenie.ilosc_pozycji(id) + delta)
	if licznik != null and is_instance_valid(licznik):
		licznik.text = str(h._jedzenie.ilosc_pozycji(id))
