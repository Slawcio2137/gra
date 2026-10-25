extends Control

const DostepStatystyk = preload("res://scripts/statystyki_dostep.gd")
const PanelStatystykSkrypt = preload("res://scripts/statystyki_panel.gd")
const ScenaJedzenia = preload("res://scenes/jedzenie_ustawienia.tscn")
const SkryptZakresu = preload("res://scripts/suwak_zakres.gd")
const SkryptZapisu = preload("res://scripts/zapis_swiata.gd")
const SkryptEventow = preload("res://scripts/eventy_odkrycia.gd")
const SkryptRynkuZakupow = preload("res://scripts/rynek_zakupow.gd")
const SkryptMapyMiast = preload("res://scripts/mapa_miast.gd")
const SkryptPrzejazdu = preload("res://scripts/przejazd_auta.gd")
const PLIK_ZAKUPOW_OFERT := "res://postacie/zakupy_oferty.json"
const PLIK_DROBIAZGOW := "res://postacie/drobiazgi.json"
const IKONA_MIASTA := "res://grafika/ikony/miasto.png"

const KOLUMNA_USTAWIEN := "PanelUstawien/Margines/ScrollUstawien/Kolumna"
const KOLUMNA_GRY := "Gra/Margines/Kolumna"
const ZIELONY := "#2f9e45"
const KRWISTY := "#9d0610"
const TEKST_CIEMNY := Color(0.12, 0.14, 0.16, 1)
const PLIK_EMOTIKONOW := "res://ui/pasek_emotikony.json"

var _losowanie: Losowanie
var _jedzenie: JedzenieUstawienia
var _wyglad: Dictionary = {}
var _cisza_ustawien := false
var _swiat: Dictionary = {}
var _akcje: Array = []
var _akcje_po_id: Dictionary = {}
var _stos: Array = []
var _zakladka_id := ""
var _przyciski_zakladek: Dictionary = {}
var _emotikony: Dictionary = {}
var _znak: Texture2D
var _kropka_mala: Texture2D
var _kropka_duza: Texture2D
var _zdanie: Label
var _wplyw_domu: RichTextLabel
var _efekt_dni: RichTextLabel
var _efekty_domu: Array = []
var _wiersze_sam: Array = []
var _lista_miast: ItemList
var _opcje_transportu: VBoxContainer
var _filtr_aktywny := false
var _filtr_od := 0.0
var _filtr_do := 0.0
var _stos_czeka := false
var _pasek_rozwiniety := false
var _pasek_ciagnie := false
var _pasek_start_y := 0.0
var _rok_lbl: Label
var _tydzien_lbl: Label
var _psychika_emoji: Label
var _psychika_pasek: ProgressBar
var _psychika_liczba: Label
var _zmeczenie_emoji: Label
var _zmeczenie_pasek: ProgressBar
var _zmeczenie_liczba: Label
var _zmeczenie_psych_emoji: Label
var _zmeczenie_psych_pasek: ProgressBar
var _zmeczenie_psych_liczba: Label
var _pieniadze_emoji: Label
var _pieniadze_lbl: Label
var _pieniadze_pokazane := 0.0
var _pieniadze_znane_pokaz := false
var _pieniadze_tween: Tween
var _komunikat_tury_lbl: Label
var _rozwiniete_stat: VBoxContainer
var _eventy := SkryptEventow.new()
var _zakupy_dane: Variant = null
var _zakupy_wiersze: Array = []
var _zakupy_filtr_od := 0.0
var _zakupy_filtr_do := 0.0
var _zakupy_filtr_ceny_wlaczony := false
var _zakupy_licznik_od: Label
var _zakupy_licznik_do: Label
var _zakupy_zasieg_km := 25.0
var _zakupy_zasieg_poziom := "miasto"
var _zakupy_filtr_odbior := ""
var _zakupy_filtr_rozwiniety := false
var _zakupy_kat_id := ""
var _zakupy_stan_filtr := ""
var _zakupy_kat_slownik: Dictionary = {}
var _zakupy_przebieg_od := 0.0
var _zakupy_przebieg_do := 0.0
var _zakupy_filtr_przebiegu_wlaczony := false
var _zakupy_licznik_przebieg_od: Label
var _zakupy_licznik_przebieg_do: Label
var _zakupy_filtr_marki: Array = []  ## multi-wybór; puste = wszystkie
var _zakupy_filtr_naped := ""
var _zakupy_panel_nowe_auta: Control
var _zakupy_sort_cena := "malejaco"  ## malejaco | rosnaco
var _rynek_zakupow := SkryptRynkuZakupow.new()
var _mapa_miast := SkryptMapyMiast.new()
var _przejazd := SkryptPrzejazdu.new()
var _mapa_graf: Dictionary = {}
var _mapa_warstwa: Control
var _mapa_pasek: Label
var _mapa_ikona: Texture2D


func _ready() -> void:
	_losowanie = Losowanie.new()
	_znak = load("res://grafika/znak_zapytania.png")
	_kropka_mala = load("res://grafika/ikony/kropka_mala.png")
	_kropka_duza = load("res://grafika/ikony/kolko_biale.png")
	_jedzenie = ScenaJedzenia.instantiate()
	_jedzenie.visible = false
	add_child(_jedzenie)
	_wyglad = WygladGracza.wczytaj()
	_wczytaj_emotikony()
	_zastosuj_wyglad()
	_podlacz_ustawienia()
	_male_przyciski()
	_wczytaj_akcje()
	_zbuduj_pasek_statystyk()
	_zbuduj_zakladki()
	_styl_bialego_ekranu()
	_podlacz_pasek_gest()
	_zbuduj_statystyki_menu()
	$UstawieniaGry.hide()
	$Powrot.hide()
	$MenuEkran/BrakZapisu.hide()
	_pokaz_start_bialy()


func _on_start_pressed() -> void:
	_nowa_gra()
	_wejdz()


func _on_wczytaj_pressed() -> void:
	if not SkryptZapisu.jest():
		_brak_zapisu()
		return
	var dane: Variant = SkryptZapisu.wczytaj()
	if not (dane is Dictionary):
		_brak_zapisu()
		return
	_swiat = dane
	if not (_swiat.get("przyjaciele") is Array):
		_swiat["przyjaciele"] = []
	if not (_swiat.get("znajomi") is Array):
		_swiat["znajomi"] = []
	if not (_swiat.get("rodzenstwo") is Array):
		_swiat["rodzenstwo"] = []
	if str(_swiat.get("tryb_kieszonkowego", "")) == "":
		var rodzina_tryb: Variant = _swiat.get("rodzina", {})
		if rodzina_tryb is Dictionary and not rodzina_tryb.is_empty():
			var ziarno_tryb := ZiarnoRodzicow.new()
			_swiat["tryb_kieszonkowego"] = ziarno_tryb.tryb_domyslny_kieszonkowego(rodzina_tryb)
	if not _swiat.has("kieszonkowe_pierwsza_rozmowa"):
		_swiat["kieszonkowe_pierwsza_rozmowa"] = true
	if not _swiat.has("kieszonkowe_ostatnia_wyplata_tydzien"):
		_swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = -1
	if not _swiat.has("kieszonkowe_aktywne"):
		# Stare save'y ze stałą: traktuj jako już aktywne; reszta czeka na prośbę.
		var tryb_stary := str(_swiat.get("tryb_kieszonkowego", ""))
		_swiat["kieszonkowe_aktywne"] = tryb_stary == "stala_kwota" or tryb_stary == "stale_daje"
	if not (_swiat.get("wplywy") is Array):
		_swiat["wplywy"] = []
	if not _swiat.has("odblokowane_jedzenie_samemu"):
		_swiat["odblokowane_jedzenie_samemu"] = _czy_jedzenie_sam_po_wieku()
	if not (_swiat.get("flagi_odkrycia") is Dictionary):
		_swiat["flagi_odkrycia"] = {}
	if not (_swiat.get("odblokowane_tematy_pytan") is Array):
		_swiat["odblokowane_tematy_pytan"] = []
	if not (_swiat.get("eventy_tury") is Array):
		_swiat["eventy_tury"] = []
	if not (_swiat.get("znajomi_dzieci") is Array):
		_swiat["znajomi_dzieci"] = []
	if not _swiat.has("jakosc_zdrowotna_poza_domem"):
		_swiat["jakosc_zdrowotna_poza_domem"] = 50
	if not (_swiat.get("majatek") is Dictionary):
		_swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	if not (_swiat.get("rynek_zakupow") is Dictionary):
		_swiat["rynek_zakupow"] = {}
	if not (_swiat.get("lokum_startowe") is Dictionary) or not _lokum_pelne(_swiat.get("lokum_startowe")):
		_swiat["lokum_startowe"] = _zbuduj_lokum_dla_swiata()
	_rynek_zakupow.przelicz_zadowolenie_docelowe(_swiat)
	_odswiez_flage_jedzenia_sam()
	_odswiez_rynek_zakupow()
	if _swiat.get("jedzenie") is Dictionary:
		_jedzenie.wczytaj_zrzut(_swiat["jedzenie"])
	else:
		var bohater: Variant = _swiat.get("bohater", {})
		var rodzina: Variant = _swiat.get("rodzina", {})
		if not (bohater is Dictionary):
			bohater = {}
		if not (rodzina is Dictionary):
			rodzina = {}
		_jedzenie.ustaw_z_losowania(bohater, rodzina)
	_zsynchronizuj_pieniadze_z_bohatera()
	_wejdz()


func _on_nastepna_tura() -> void:
	if _swiat.is_empty():
		return
	var tydzien := int(_swiat.get("tydzien", 1)) + 1
	var rok := int(_swiat.get("rok", 1))
	if tydzien > 52:
		tydzien = 1
		rok += 1
		var bohater := _bohater()
		if _jest_liczba(bohater.get("wiek")):
			bohater["wiek"] = int(bohater["wiek"]) + 1
			_swiat["bohater"] = bohater
	_swiat["tydzien"] = tydzien
	_swiat["rok"] = rok
	_swiat["komunikat_tury"] = ""
	_swiat["eventy_tury"] = []
	_swiat["event_odpowiedz_tekst"] = ""
	_odswiez_flage_jedzenia_sam()
	_wyplata_kieszonkowego_tydzien()
	_wyplata_kieszonkowego_dziadkow_tydzien()
	_efekt_konserwacji_auta_tydzien()
	_efekt_fala2_tydzien()
	_losuj_eventy_tury()
	_fallback_nauki_szkolnej()
	_efekt_wygody_tydzien()
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	_swiat["dni_auta"] = int(_swiat.get("dni_auta", 0))
	_odswiez_rynek_zakupow()
	SkryptZapisu.zapisz(_swiat)
	_odswiez_pasek_statystyk(true)
	_ukryj_zielony_komunikat_tury()
	_odswiez_lokalizacje()
	# Po turze: wyjdź z głębokiej zakładki i pokaż napisy tygodnia (treść tury → biały obszar).
	_wyjdz_do_napisow_tygodnia()


func _wyplata_kieszonkowego_tydzien() -> void:
	if not bool(_swiat.get("kieszonkowe_aktywne", false)):
		return
	var tryb := str(_swiat.get("tryb_kieszonkowego", ""))
	if tryb == "":
		return
	var tydzien := int(_swiat.get("tydzien", 0))
	if int(_swiat.get("kieszonkowe_ostatnia_wyplata_tydzien", -1)) == tydzien:
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.wyplata_tygodniowa_kieszonkowego(
		rodzina, tryb, true, _swiat.get("kieszonkowe_kwota_zl", null), _wiek_lat()
	)
	if not bool(wynik.get("dodano", false)) or not _jest_liczba(wynik.get("kwota")):
		return
	_dodaj_pieniadze(int(wynik["kwota"]))
	_dodaj_wplyw(str(wynik.get("zrodlo_wplywu", "kieszonkowe")), int(wynik["kwota"]), str(wynik.get("tekst", "")))
	_swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = tydzien
	var tekst := str(wynik.get("tekst", ""))
	_swiat["komunikat_tury"] = tekst
	_swiat["ostatnie_kieszonkowe_tekst"] = tekst


func _efekt_wygody_tydzien() -> void:
	_swiat["ostatni_efekt_wygody_tekst"] = ""
	if not (_swiat.get("lokum_startowe") is Dictionary) or not _lokum_pelne(_swiat.get("lokum_startowe")):
		_swiat["lokum_startowe"] = _zbuduj_lokum_dla_swiata()
	var wynik: Dictionary = _rynek_zakupow.efekt_wygody_tydzien(_swiat)
	var tekst := str(wynik.get("tekst", "")).strip_edges()
	_swiat["ostatni_efekt_wygody_tekst"] = tekst
	if tekst == "":
		return
	var kom := str(_swiat.get("komunikat_tury", "")).strip_edges()
	_swiat["komunikat_tury"] = tekst if kom == "" else kom + "\n" + tekst


func _on_ustawienia_pressed() -> void:
	$PanelUstawien.show()
	$Powrot.show()
	_na_wierzch_przyciski()


func _on_zamknij_ustawienia() -> void:
	$PanelUstawien.hide()
	_odswiez_widocznosc_powrotu()
	_na_wierzch_przyciski()


func _on_powrot() -> void:
	if $PanelUstawien.visible:
		_on_zamknij_ustawienia()
		return
	var statystyki := get_node_or_null("PanelStatystyk")
	if statystyki != null and statystyki.visible:
		statystyki.hide()
		_odswiez_widocznosc_powrotu()
		return
	if $Gra.visible and not _stos.is_empty():
		_cofnij_poziom()
		return
	# Na poziomie napisów/neutralnym: domknij do białego startu gry (nie quit).
	if $Gra.visible:
		_wyjdz_do_neutralnego()


func _on_wyjscie() -> void:
	get_tree().quit()


func _on_wszystkie_stat() -> void:
	_zakladka_id = ""
	_odznacz_zakladki()
	_stos.clear()
	$Powrot.hide()
	_wyczysc(_tresc_biala())
	_dol_suwaka().hide()
	_tytul_bialy().text = "Statystyki ilościowe"
	_wypelnij_statystyki_ilosciowe(_tresc_biala())


func _unhandled_input(zdarzenie: InputEvent) -> void:
	if zdarzenie.is_action_pressed("ui_cancel"):
		_on_powrot()
		get_viewport().set_input_as_handled()


func _nowa_gra() -> void:
	var wynik := _losowanie.losuj_postac("kraj", "polska")
	var ziarno := ZiarnoRodzicow.new()
	var miejsce: Variant = wynik.get("miejsce")
	var rodzina: Dictionary = ziarno.losuj(_losowanie, miejsce)
	wynik["ziarno_rodzicow"] = rodzina
	wynik["zarobki_rodziny"] = rodzina.get("zarobki", null)
	if not _jest_liczba(wynik.get("pieniadze")):
		wynik["pieniadze"] = 0
	var dziad := Dziadkowie.new()
	var dziadkowie_stan: Dictionary = dziad.losuj(rodzina, _losowanie, miejsce)
	rodzina["dziadkowie"] = dziadkowie_stan
	var zan := ZainteresowaniaLos.new()
	wynik["zainteresowanie"] = zan.losuj_dominujace(_losowanie)
	var syl := Sylwetka.new()
	wynik["sylwetka"] = syl.do_zapisu()
	var ie := InteligencjaEmocjonalna.new()
	wynik["inteligencja_emocjonalna"] = ie.losuj_start()
	wynik["wiedza_pkt"] = int(wynik.get("wiedza_pkt", 0))
	wynik["zajecia_dodatkowe"] = []
	wynik["lotnictwo"] = {"licencje": [], "hangar": false, "smiglowce_odblokowane": false}
	var rodzenstwo := _losowanie.losuj_rodzenstwo(wynik)
	_uzupelnij_normy_bohatera(wynik)
	_jedzenie.ustaw_z_losowania(wynik, rodzina)
	var nazwa := ""
	var typ := ""
	var id_miejsca := ""
	var blad_miejsca := ""
	if miejsce is Dictionary and miejsce.get("id") != null:
		nazwa = str(miejsce.get("nazwa", ""))
		typ = str(miejsce.get("typ", ""))
		id_miejsca = str(miejsce.get("id", ""))
	elif miejsce is Dictionary:
		blad_miejsca = str(miejsce.get("powod", "Brak miejsca urodzenia."))
	# Wiek startu 2–4 lata + tydzień 1–52. Rok gry = wiek w latach.
	var wiek_start := randi_range(2, 4)
	var tydzien_start := randi_range(1, 52)
	wynik["wiek"] = wiek_start
	# Kieszonkowe: NIE aktywne na Start — wypłata dopiero po udanej prośbie.
	_swiat = {
		"wersja": 1,
		"rok": wiek_start,
		"tydzien": tydzien_start,
		"bohater": wynik,
		"rodzina": rodzina,
		"rodzenstwo": rodzenstwo,
		"przyjaciele": [],
		"znajomi": [],
		"nazwa_urodzenia": nazwa,
		"typ_urodzenia": typ,
		"id_urodzenia": id_miejsca,
		"nazwa_miejsca": nazwa,
		"miejsce_pobytu": "dom",
		"auto": null,
		"dni_auta": 0,
		"jedzenie": _jedzenie.zrzut_zapisu(),
		"tryb_kieszonkowego": "",
		"kieszonkowe_aktywne": false,
		"kieszonkowe_kwota_zl": null,
		"kieszonkowe_pierwsza_rozmowa": true,
		"kieszonkowe_ostatnia_wyplata_tydzien": -1,
		"wplywy": [],
		"budzet_jakosci_drobiazgow_zl": 0,
		"jakosc_zdrowotna_poza_domem": 50,
		"odblokowane_jedzenie_samemu": false,
		"flagi_odkrycia": {},
		"odblokowane_tematy_pytan": [],
		"eventy_tury": [],
		"event_odpowiedz_tekst": "",
		"znajomi_dzieci": [],
		"komunikat_tury": "",
		"komunikat_startu": _komunikat_startu(wynik, rodzina, rodzenstwo, blad_miejsca),
		"majatek": {"nieruchomosci": [], "dobra": []},
		"lokum_startowe": {},
		"rynek_zakupow": {},
		"id_miejsca_pobytu": id_miejsca,
	}
	# Lokum musi istnieć jako pełny obiekt (nie sama wygoda) — po miejscu + zarobkach rodziców.
	_swiat["lokum_startowe"] = _rynek_zakupow.zbuduj_lokum_startowe(rodzina, miejsce)
	_swiat["rodzina"] = rodzina
	if _swiat["majatek"] is Dictionary:
		_swiat["majatek"]["lokum_rodziny"] = _swiat["lokum_startowe"].duplicate(true)
	_rynek_zakupow.przelicz_zadowolenie_docelowe(_swiat)
	_odswiez_flage_jedzenia_sam()
	_odswiez_rynek_zakupow()
	_losowanie.zapisz(wynik)
	_losowanie.zapisz_rodzenstwo(rodzenstwo)
	SkryptZapisu.zapisz(_swiat)


func _komunikat_startu(bohater: Dictionary, rodzina: Dictionary, rodzenstwo: Array, blad_miejsca: String) -> String:
	var czesci: PackedStringArray = []
	if blad_miejsca != "":
		czesci.append("Miejsce: %s" % blad_miejsca)
	elif not bool(bohater.get("wylosowano", false)):
		czesci.append("Bohatera nie wylosowano w pełni.")
	else:
		czesci.append("Bohater wylosowany.")
	var imie_m := ""
	var imie_o := ""
	if rodzina.get("matka") is Dictionary and rodzina["matka"].get("imie") is Dictionary:
		imie_m = str(rodzina["matka"]["imie"].get("nazwa", ""))
	if rodzina.get("ojciec") is Dictionary and rodzina["ojciec"].get("imie") is Dictionary:
		imie_o = str(rodzina["ojciec"]["imie"].get("nazwa", ""))
	if imie_m != "" or imie_o != "":
		czesci.append("Matka: %s. Ojciec: %s." % [
			imie_m if imie_m != "" else "—",
			imie_o if imie_o != "" else "—"
		])
	if rodzina.get("zarobki") is Dictionary and bool(rodzina["zarobki"].get("kolo", false)):
		var zar := _tekst_zarobkow(rodzina["zarobki"])
		czesci.append("Zarobki rodziny: %s." % (zar if zar != "" else "przedział GUS"))
	else:
		var powod_z := ""
		if rodzina.get("zarobki") is Dictionary:
			powod_z = str(rodzina["zarobki"].get("powod", ""))
		czesci.append("Rodzina: zarobki nie wylosowane%s." % ((" — " + powod_z) if powod_z != "" else ""))
	czesci.append("Rodzeństwo: %d." % rodzenstwo.size())
	if _jest_liczba(bohater.get("wiek")):
		czesci.append("Wiek startu: %d lat." % int(bohater["wiek"]))
	czesci.append("Przyjaciele i znajomi: puste na start.")
	czesci.append("Kieszonkowe: dopiero po prośbie (Rodzina).")
	return " ".join(czesci)


func _wejdz() -> void:
	$MenuEkran/BrakZapisu.hide()
	$MenuEkran.hide()
	$PanelUstawien.hide()
	var statystyki := get_node_or_null("PanelStatystyk")
	if statystyki != null:
		statystyki.hide()
	$Gra.show()
	$UstawieniaGry.hide()
	$Powrot.hide()
	_stos.clear()
	_zakladka_id = ""
	_odznacz_zakladki()
	_pokaz_start_bialy()
	_odswiez_lokalizacje()
	_odswiez_pasek_statystyk(false)
	_na_wierzch_przyciski()


func _brak_zapisu() -> void:
	$MenuEkran/BrakZapisu.text = "Nie ma zapisu."
	$MenuEkran/BrakZapisu.show()


func _wczytaj_akcje() -> void:
	_akcje = []
	_akcje_po_id = {}
	if not FileAccess.file_exists("res://ui/akcje.json"):
		return
	var plik := FileAccess.open("res://ui/akcje.json", FileAccess.READ)
	if plik == null:
		return
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary and dane.get("akcje") is Array:
		_akcje = dane["akcje"]
		_indeksuj_akcje_rekurencyjnie(_akcje)


func _indeksuj_akcje_rekurencyjnie(lista: Array) -> void:
	for akcja in lista:
		if not (akcja is Dictionary):
			continue
		var id := str(akcja.get("id", ""))
		if id != "":
			_akcje_po_id[id] = akcja
		if akcja.get("dzieci") is Array:
			_indeksuj_akcje_rekurencyjnie(akcja["dzieci"])


func _wczytaj_emotikony() -> void:
	_emotikony = {}
	var dane: Variant = _czytaj_json(PLIK_EMOTIKONOW)
	if dane is Dictionary:
		_emotikony = dane


func _uzupelnij_normy_bohatera(bohater: Dictionary) -> void:
	var psychika: Variant = _emotikony.get("psychika", {})
	var zmeczenie: Variant = _emotikony.get("zmeczenie_fizyczne", _emotikony.get("zmeczenie", {}))
	var zmeczenie_p: Variant = _emotikony.get("zmeczenie_psychiczne", {})
	if not _jest_liczba(bohater.get("psychika")) and psychika is Dictionary and _jest_liczba(psychika.get("norma")):
		bohater["psychika"] = int(psychika["norma"])
	if not _jest_liczba(bohater.get("zmeczenie_fizyczne")):
		if _jest_liczba(bohater.get("zmeczenie")):
			bohater["zmeczenie_fizyczne"] = int(bohater["zmeczenie"])
		elif zmeczenie is Dictionary and _jest_liczba(zmeczenie.get("norma")):
			bohater["zmeczenie_fizyczne"] = int(zmeczenie["norma"])
	if _jest_liczba(bohater.get("zmeczenie_fizyczne")):
		bohater["zmeczenie"] = int(bohater["zmeczenie_fizyczne"])
	elif not _jest_liczba(bohater.get("zmeczenie")) and zmeczenie is Dictionary and _jest_liczba(zmeczenie.get("norma")):
		bohater["zmeczenie"] = int(zmeczenie["norma"])
		bohater["zmeczenie_fizyczne"] = int(zmeczenie["norma"])
	if not _jest_liczba(bohater.get("zmeczenie_psychiczne")) and zmeczenie_p is Dictionary and _jest_liczba(zmeczenie_p.get("norma")):
		bohater["zmeczenie_psychiczne"] = int(zmeczenie_p["norma"])


func _zbuduj_zakladki() -> void:
	var siatka: GridContainer = get_node(KOLUMNA_GRY + "/SiatkaZakladek")
	_wyczysc(siatka)
	_przyciski_zakladek.clear()
	for akcja in _akcje:
		if not (akcja is Dictionary):
			continue
		var id := str(akcja.get("id", ""))
		var przycisk := Button.new()
		przycisk.toggle_mode = true
		przycisk.focus_mode = Control.FOCUS_NONE
		przycisk.custom_minimum_size = Vector2(0, 108)
		przycisk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		przycisk.text = str(akcja.get("nazwa", ""))
		przycisk.expand_icon = true
		przycisk.alignment = HORIZONTAL_ALIGNMENT_CENTER
		przycisk.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		przycisk.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		przycisk.add_theme_constant_override("icon_max_width", 56)
		przycisk.add_theme_constant_override("h_separation", 8)
		przycisk.add_theme_font_size_override("font_size", 18)
		for stan_ikony in ["icon_normal_color", "icon_pressed_color", "icon_hover_color", "icon_disabled_color"]:
			przycisk.add_theme_color_override(stan_ikony, Color.WHITE)
		var ikona_sciezka := str(akcja.get("ikona", ""))
		if ikona_sciezka != "":
			var tex: Texture2D = load(ikona_sciezka) as Texture2D
			if tex != null:
				przycisk.icon = tex
			else:
				push_warning("Brak Texture2D zakładki: " + ikona_sciezka)
		_styl_zakladki(przycisk, str(akcja.get("kolor", "#6a7580")), false)
		przycisk.pressed.connect(_on_zakladka.bind(id))
		siatka.add_child(przycisk)
		_przyciski_zakladek[id] = przycisk


func _styl_zakladki(przycisk: Button, hex: String, zaznaczona: bool) -> void:
	var baza := _kolor(hex)
	if zaznaczona:
		baza = baza.darkened(0.35)
	var styl := StyleBoxFlat.new()
	styl.bg_color = baza
	styl.corner_radius_top_left = 10
	styl.corner_radius_top_right = 10
	styl.corner_radius_bottom_left = 10
	styl.corner_radius_bottom_right = 10
	styl.content_margin_left = 4
	styl.content_margin_right = 4
	styl.content_margin_top = 8
	styl.content_margin_bottom = 8
	for stan in ["normal", "hover", "pressed", "focus", "disabled"]:
		przycisk.add_theme_stylebox_override(stan, styl)
	przycisk.add_theme_color_override("font_color", _kolor_napisu_na(baza))
	przycisk.add_theme_color_override("font_pressed_color", _kolor_napisu_na(baza))
	przycisk.add_theme_color_override("font_hover_color", _kolor_napisu_na(baza))


func _on_zakladka(id: String) -> void:
	var akcja: Variant = _akcje_po_id.get(id)
	if not (akcja is Dictionary):
		return
	_zakladka_id = id
	_odznacz_zakladki()
	var przycisk: Button = _przyciski_zakladek.get(id)
	if przycisk != null:
		przycisk.set_pressed_no_signal(true)
		_styl_zakladki(przycisk, str(akcja.get("kolor", "#6a7580")), true)
	_stos.clear()
	_otworz_akcje(akcja)


func _odznacz_zakladki() -> void:
	for id in _przyciski_zakladek.keys():
		var przycisk: Button = _przyciski_zakladek[id]
		var akcja: Variant = _akcje_po_id.get(id)
		var kolor := "#6a7580"
		if akcja is Dictionary:
			kolor = str(akcja.get("kolor", kolor))
		przycisk.set_pressed_no_signal(id == _zakladka_id)
		_styl_zakladki(przycisk, kolor, id == _zakladka_id and _zakladka_id != "")


func _otworz_akcje(akcja: Dictionary) -> void:
	## Stos = ścieżka rodziców w hierarchii UI, nie historia dowolnych kliknięć.
	_stos = _stos_hierarchiczny(akcja)
	# Powrót zawsze przy otwartej ścieżce (także korzeń zakładki) — żeby dało się wyjść całkowicie.
	$Powrot.show()
	_na_wierzch_przyciski()
	_zaplanuj_stos()


func _stos_hierarchiczny(akcja: Dictionary) -> Array:
	if akcja.get("sciezka_rodzicow") is Array:
		var sciezka: Array = []
		for rodzic in akcja["sciezka_rodzicow"]:
			if rodzic is Dictionary:
				var kopia: Dictionary = rodzic.duplicate(true)
				kopia.erase("sciezka_rodzicow")
				sciezka.append(kopia)
		var ja: Dictionary = akcja.duplicate(true)
		ja.erase("sciezka_rodzicow")
		sciezka.append(ja)
		return sciezka
	var z_drzewa := _sciezka_w_drzewie_akcji(str(akcja.get("id", "")))
	if not z_drzewa.is_empty():
		return z_drzewa
	return [akcja]


func _sciezka_w_drzewie_akcji(cel_id: String) -> Array:
	if cel_id == "":
		return []
	for korzen in _akcje:
		if korzen is Dictionary:
			var znaleziona := _szukaj_sciezki_akcji(korzen, cel_id, [])
			if not znaleziona.is_empty():
				return znaleziona
	return []


func _szukaj_sciezki_akcji(wezel: Dictionary, cel_id: String, prefiks: Array) -> Array:
	var tu: Array = prefiks.duplicate()
	tu.append(wezel)
	if str(wezel.get("id", "")) == cel_id:
		return tu
	var dzieci: Variant = wezel.get("dzieci", [])
	if dzieci is Array:
		for dziecko in dzieci:
			if dziecko is Dictionary:
				var dalej := _szukaj_sciezki_akcji(dziecko, cel_id, tu)
				if not dalej.is_empty():
					return dalej
	return []


func _cofnij_poziom() -> void:
	if _stos.is_empty():
		_wyjdz_do_neutralnego()
		return
	_stos.pop_back()
	if _stos.is_empty():
		# Bug fix: wcześniej tu wracał korzeń zakładki i nie dało się wyjść „do końca”.
		_wyjdz_do_neutralnego()
		return
	$Powrot.show()
	_na_wierzch_przyciski()
	_zaplanuj_stos()


func _wyjdz_do_neutralnego() -> void:
	_stos.clear()
	_zakladka_id = ""
	_odznacz_zakladki()
	$Powrot.hide()
	_pokaz_start_bialy()
	_na_wierzch_przyciski()


func _wyjdz_do_napisow_tygodnia() -> void:
	_stos.clear()
	_zakladka_id = ""
	_odznacz_zakladki()
	$Powrot.hide()
	_pokaz_napisy_tygodnia()
	_na_wierzch_przyciski()


func _odswiez_widocznosc_powrotu() -> void:
	if $PanelUstawien.visible:
		$Powrot.show()
		return
	var statystyki := get_node_or_null("PanelStatystyk")
	if statystyki != null and statystyki.visible:
		$Powrot.show()
		return
	if $Gra.visible and not _stos.is_empty():
		$Powrot.show()
		return
	$Powrot.hide()


func _zaplanuj_stos() -> void:
	if _stos_czeka:
		return
	_stos_czeka = true
	call_deferred("_odswiez_stos")


func _odswiez_stos() -> void:
	_stos_czeka = false
	if not is_inside_tree():
		return
	if _stos.is_empty():
		_pokaz_start_bialy()
		return
	var gora: Dictionary = _stos[_stos.size() - 1]
	if str(gora.get("tryb", "")) == "dzieci":
		_pokaz_liste_dzieci(gora)
	else:
		_pokaz_ekran(gora)
	_odswiez_widocznosc_powrotu()


func _pokaz_start_bialy() -> void:
	_wyczysc(_tresc_biala())
	_dol_suwaka().hide()
	_tytul_bialy().text = "Gra"
	var start := str(_swiat.get("komunikat_startu", ""))
	if start != "":
		_tresc_biala().add_child(_napis_ekranu(start, 15))
	var tura_txt := str(_swiat.get("komunikat_tury", "")).strip_edges()
	if tura_txt != "":
		_tresc_biala().add_child(_napis_ekranu("W tym tygodniu: %s" % tura_txt, 15))
	_ukryj_zielony_komunikat_tury()
	_tresc_biala().add_child(_napis_ekranu("Wybierz zakładkę. Rodzina i kieszonkowe: Osoby → Rodzina. Mapa: Majątek → Transport → Mapa.", 16))


func _pokaz_napisy_tygodnia() -> void:
	_wyczysc(_tresc_biala())
	_dol_suwaka().hide()
	var tydzien := int(_swiat.get("tydzien", 1))
	var rok := int(_swiat.get("rok", 1))
	_tytul_bialy().text = "W tym tygodniu"
	# Najpierw Rok i Tydzień — pogrubione i powiększone; potem reszta napisów.
	var naglowek := HBoxContainer.new()
	naglowek.add_theme_constant_override("separation", 20)
	var rok_rich := _rich_ekran()
	rok_rich.add_theme_font_size_override("normal_font_size", 24)
	rok_rich.add_theme_font_size_override("bold_font_size", 24)
	rok_rich.fit_content = true
	rok_rich.text = "[b]Rok %d[/b]" % rok
	var tydzien_rich := _rich_ekran()
	tydzien_rich.add_theme_font_size_override("normal_font_size", 24)
	tydzien_rich.add_theme_font_size_override("bold_font_size", 24)
	tydzien_rich.fit_content = true
	tydzien_rich.text = "[b]Tydzień %d[/b]" % tydzien
	naglowek.add_child(rok_rich)
	naglowek.add_child(tydzien_rich)
	_tresc_biala().add_child(naglowek)
	var tura_txt := str(_swiat.get("komunikat_tury", "")).strip_edges()
	if tura_txt != "":
		_tresc_biala().add_child(_napis_ekranu(tura_txt, 15))
	var kiesz := str(_swiat.get("ostatnie_kieszonkowe_tekst", "")).strip_edges()
	if kiesz != "" and kiesz != tura_txt:
		_tresc_biala().add_child(_napis_ekranu(kiesz, 14))
	var wygoda_txt := str(_swiat.get("ostatni_efekt_wygody_tekst", "")).strip_edges()
	if wygoda_txt != "" and tura_txt.find(wygoda_txt) < 0:
		_tresc_biala().add_child(_napis_ekranu(wygoda_txt, 14))
	var odp := str(_swiat.get("event_odpowiedz_tekst", "")).strip_edges()
	if odp != "":
		_tresc_biala().add_child(_napis_ekranu(odp, 15))
	_pokaz_eventy_tury_ui()
	var eventy: Variant = _swiat.get("eventy_tury", [])
	if (not (eventy is Array) or eventy.is_empty()) and tura_txt == "" and kiesz == "" and wygoda_txt == "" and odp == "":
		_tresc_biala().add_child(_napis_ekranu("Brak szczególnych wydarzeń tygodnia.", 15))
	_ukryj_zielony_komunikat_tury()
	_tresc_biala().add_child(_napis_ekranu("Wybierz zakładkę, żeby kontynuować.", 14))


func _pokaz_liste_dzieci(akcja: Dictionary) -> void:
	_wyczysc(_tresc_biala())
	_dol_suwaka().hide()
	_tytul_bialy().text = str(akcja.get("nazwa", ""))
	var dzieci: Variant = akcja.get("dzieci", [])
	if not (dzieci is Array):
		return
	for dziecko in dzieci:
		if not (dziecko is Dictionary):
			continue
		var przycisk := Button.new()
		przycisk.text = str(dziecko.get("nazwa", ""))
		przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
		przycisk.custom_minimum_size = Vector2(0, 48)
		przycisk.pressed.connect(_otworz_akcje.bind(dziecko))
		_tresc_biala().add_child(przycisk)


func _pokaz_ekran(akcja: Dictionary) -> void:
	_zdanie = null
	_wplyw_domu = null
	_efekt_dni = null
	_efekty_domu = []
	_wiersze_sam = []
	_lista_miast = null
	_opcje_transportu = null
	_mapa_warstwa = null
	_mapa_pasek = null
	_wyczysc(_tresc_biala())
	_wyczysc(_dol_suwaka())
	_dol_suwaka().hide()
	_tytul_bialy().text = _tytul_ekranu(akcja)
	_wypelnij_ekran(akcja)


func _tytul_ekranu(akcja: Dictionary) -> String:
	var tresc := str(akcja.get("tresc", ""))
	if tresc == "jedzenie_sam":
		return "Cena"
	if tresc == "transport" and _auto_z_zapisu() != null:
		return "Ile dni w tygodniu"
	return str(akcja.get("nazwa", ""))


func _wypelnij_ekran(akcja: Dictionary) -> void:
	var tresc := str(akcja.get("tresc", ""))
	var kolor := _kolor(str(akcja.get("kolor", "#9aa7b2")))
	if tresc == "dom":
		_ekran_dom()
	elif tresc == "jedzenie_dom":
		_ekran_jedzenie_dom(kolor)
	elif tresc == "jedzenie_sam":
		_ekran_jedzenie_sam(kolor)
	elif tresc == "transport":
		_ekran_transport(kolor)
	elif tresc == "mapa":
		_ekran_mapa()
	elif tresc == "zdrowie":
		_ekran_zdrowie()
	elif tresc == "terapia":
		_ekran_terapia()
	elif tresc == "praca":
		_ekran_praca_fala2()
	elif tresc == "majatek":
		_ekran_majatek()
	elif tresc == "konserwacja_auta":
		_ekran_konserwacja_auta()
	elif tresc == "lotnictwo":
		_ekran_lotnictwo()
	elif tresc == "szkola":
		_tresc_biala().add_child(_napis_ekranu("Nauka — Fala 2: korepetycje, zajęcia, szachy w podmenu.", 16))
		_stub_przedszkole()
	elif tresc == "korepetycje":
		_ekran_korepetycje()
	elif tresc == "zajecia_dodatkowe":
		_ekran_zajecia_dodatkowe()
	elif tresc == "szachy":
		_ekran_szachy()
	elif tresc == "eventy_przyklady":
		_ekran_eventy_przyklady()
	elif tresc == "imprezy":
		_ekran_imprezy()
	elif tresc == "zakupy":
		_ekran_zakupy()
	elif tresc == "zakupy_kategoria":
		var kat_sl: Variant = akcja.get("kat", {})
		if kat_sl is Dictionary:
			if str(kat_sl.get("rodzaj", "")) == "budzet_jakosci" or str(kat_sl.get("id", "")) == "drobiazgi":
				_ekran_budzet_drobiazgow()
			else:
				_ekran_zakupy_oferty(str(kat_sl.get("id", "")), "", kat_sl)
	elif tresc == "zakupy_oferta":
		_ekran_zakupy_karta_oferty(akcja)
	elif tresc == "postac":
		_ekran_postac()
	elif tresc == "rodzina":
		_ekran_rodzina()
	elif tresc == "przyjaciele":
		_ekran_lista_osob("przyjaciele", "Nikogo jeszcze.")
	elif tresc == "znajomi":
		_ekran_lista_osob("znajomi", "Nikogo jeszcze.")
	elif tresc == "ustawienia_gry":
		_ekran_ustawienia_w_bialym()
	elif tresc == "statystyki_ilosciowe":
		_wypelnij_statystyki_ilosciowe(_tresc_biala())
	if akcja.get("dzieci") is Array and tresc != "jedzenie" and tresc != "majatek" and tresc != "osoby":
		for dziecko in akcja["dzieci"]:
			if dziecko is Dictionary:
				var przycisk := Button.new()
				przycisk.text = str(dziecko.get("nazwa", ""))
				przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
				przycisk.custom_minimum_size = Vector2(0, 44)
				przycisk.pressed.connect(_otworz_akcje.bind(dziecko))
				_tresc_biala().add_child(przycisk)


func _ekran_dom() -> void:
	var tekst := _tekst_domu()
	if tekst != "":
		_tresc_biala().add_child(_napis_ekranu(tekst, 20))
	else:
		_tresc_biala().add_child(_napis_ekranu("Dom. Brak nazwy w zapisie.", 16))
	_tresc_biala().add_child(_napis_ekranu(_opis_lokalizacji(), 15))


func _ekran_zdrowie() -> void:
	var bohater := _bohater()
	var skrot := str(bohater.get("zdrowie_skrot", ""))
	if skrot != "":
		_tresc_biala().add_child(_napis_ekranu(skrot, 18))
	else:
		_tresc_biala().add_child(_napis_ekranu("Zdrowie ilościowe pojawi się, gdy będzie w zapisie. Chorób na starcie nie wypisuję.", 16))
	var zdrowie := _tekst_pusty(bohater.get("zdrowie"))
	if zdrowie != "":
		_tresc_biala().add_child(_napis_ekranu("Zdrowie: %s" % zdrowie, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		_tresc_biala().add_child(_napis_ekranu(dep_txt, 15))
	_tresc_biala().add_child(_napis_ekranu("Terapia / nastrój — w podmenu Zdrowie.", 14))


func _ekran_postac() -> void:
	var bohater := _bohater()
	var imie := _tekst_pusty(bohater.get("imie"))
	var nazwisko := _tekst_pusty(bohater.get("nazwisko"))
	if imie != "" or nazwisko != "":
		_tresc_biala().add_child(_napis_ekranu(("%s %s" % [imie, nazwisko]).strip_edges(), 18))
	_tresc_biala().add_child(_napis_ekranu("Cechy charakteru", 18))
	var cechy := _cechy_bohatera(bohater)
	_tresc_biala().add_child(_napis_ekranu(cechy if cechy != "" else "—", 16))
	var inteligencje := _inteligencje_bohatera(bohater)
	if inteligencje != "":
		_tresc_biala().add_child(_napis_ekranu("Inteligencja", 18))
		_tresc_biala().add_child(_napis_ekranu(inteligencje, 16))
	var urodzenie := _opis_urodzenia()
	_tresc_biala().add_child(_napis_ekranu("Miejsce urodzenia", 18))
	_tresc_biala().add_child(_napis_ekranu(urodzenie if urodzenie != "" else "—", 16))
	var wiek := _tekst_liczby(bohater.get("wiek"))
	_tresc_biala().add_child(_napis_ekranu("Wiek: %s" % (wiek if wiek != "" else "—"), 16))
	var psychika := _tekst_liczby(_wartosc_metryki("psychika"))
	var zm_f := _tekst_liczby(_wartosc_metryki("zmeczenie_fizyczne"))
	if zm_f == "":
		zm_f = _tekst_liczby(_wartosc_metryki("zmeczenie"))
	var zm_p := _tekst_liczby(_wartosc_metryki("zmeczenie_psychiczne"))
	_tresc_biala().add_child(_napis_ekranu("Psychika (nastrój): %s" % (psychika if psychika != "" else "—"), 16))
	_tresc_biala().add_child(_napis_ekranu("Zmęczenie fizyczne: %s   Obciążenie psychiczne: %s" % [
		zm_f if zm_f != "" else "—",
		zm_p if zm_p != "" else "—"
	], 16))
	var syl_txt := _opis_sylwetki(bohater)
	if syl_txt != "":
		_tresc_biala().add_child(_napis_ekranu(syl_txt, 16))
		_tresc_biala().add_child(_pasek_sylwetki(bohater))
	var ie := InteligencjaEmocjonalna.new()
	var ie_txt := ie.tekst(bohater)
	if ie_txt != "":
		_tresc_biala().add_child(_napis_ekranu(ie_txt, 16))
	var wiedza := _tekst_liczby(bohater.get("wiedza_pkt"))
	if wiedza != "":
		_tresc_biala().add_child(_napis_ekranu("Wiedza (pkt stub): %s" % wiedza, 15))
	var zan_txt := _opis_zainteresowania(bohater)
	if zan_txt != "":
		_tresc_biala().add_child(_napis_ekranu(zan_txt, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		_tresc_biala().add_child(_napis_ekranu(dep_txt, 14))
	elif bool(bohater.get("depresja", false)):
		_tresc_biala().add_child(_napis_ekranu("Flaga: depresja.", 14))
	# Docelowe tylko w trybie deweloperskim — nigdy na pasku / w normalnej grze.
	if DostepStatystyk.POKAZ_STATYSTYKI:
		var doc_dev := _tekst_liczby(_bohater().get("zadowolenie_docelowe"))
		_tresc_biala().add_child(_napis_ekranu("Docelowe (dev, ukryte): %s" % (doc_dev if doc_dev != "" else "—"), 14))


func _ekran_rodzina() -> void:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary) or rodzina.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Rodzina nie weszła do zapisu. Spróbuj Start jeszcze raz — jeśli dalej pusto, losowanie padło.", 16))
		return
	_tresc_biala().add_child(_napis_ekranu("Matka", 18))
	_tresc_biala().add_child(_napis_ekranu(_opis_rodzica(rodzina.get("matka")), 16))
	_tresc_biala().add_child(_napis_ekranu("Ojciec", 18))
	_tresc_biala().add_child(_napis_ekranu(_opis_rodzica(rodzina.get("ojciec")), 16))
	_tresc_biala().add_child(_napis_ekranu("Dziadkowie", 18))
	_tresc_biala().add_child(_napis_ekranu(_opis_dziadkow(rodzina.get("dziadkowie")), 16))
	var prosba_d := Button.new()
	prosba_d.text = "Poproś dziadków o kieszonkowe"
	prosba_d.custom_minimum_size = Vector2(0, 48)
	prosba_d.pressed.connect(_on_kieszonkowe_dziadkowie)
	_tresc_biala().add_child(prosba_d)
	var wynik_d := _napis_ekranu(str(_swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")), 15)
	wynik_d.visible = str(_swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")) != ""
	_tresc_biala().add_child(wynik_d)
	var zarobki := _tekst_zarobkow(rodzina.get("zarobki"))
	var etykieta_gosp := "Zarobki rodziny (suma rodziców)"
	if rodzina.get("zarobki") is Dictionary and str(rodzina["zarobki"].get("dochód_gospodarstwa", "")) == "suma_przedzialow_rodzicow":
		etykieta_gosp = "Zarobki gospodarstwa (suma przedziałów matki i ojca)"
	if zarobki == "" and rodzina.get("zarobki") is Dictionary:
		var powod := str(rodzina["zarobki"].get("powod", ""))
		_tresc_biala().add_child(_napis_ekranu("%s: —%s" % [etykieta_gosp, ((" (%s)" % powod) if powod != "" else "")], 16))
	else:
		_tresc_biala().add_child(_napis_ekranu("%s: %s" % [etykieta_gosp, zarobki if zarobki != "" else "—"], 16))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		_tresc_biala().add_child(_napis_ekranu(opis_lokum, 16))
	else:
		var dom := _tekst_domu()
		_tresc_biala().add_child(_napis_ekranu("Dom: %s" % (dom if dom != "" else "brak lokum w zapisie"), 16))
	_tresc_biala().add_child(_napis_ekranu("Rodzeństwo", 18))
	var rodzenstwo: Variant = _swiat.get("rodzenstwo", [])
	if not (rodzenstwo is Array) or rodzenstwo.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Brak rodzeństwa (wylosowano 0).", 16))
	else:
		var nr := 1
		for osoba in rodzenstwo:
			if not (osoba is Dictionary):
				continue
			_tresc_biala().add_child(_napis_ekranu(_opis_rodzenstwa(osoba, nr), 16))
			nr += 1
	var ziarno_ui := ZiarnoRodzicow.new()
	var tryb_id := str(_swiat.get("tryb_kieszonkowego", ""))
	var aktywne := bool(_swiat.get("kieszonkowe_aktywne", false))
	var tryb_etykieta := ziarno_ui.etykieta_trybu_kieszonkowego(tryb_id) if aktywne else "jeszcze nie proszono"
	var linia_kiesz := "Kieszonkowe: %s" % tryb_etykieta
	if aktywne and (tryb_id == "stala_kwota" or tryb_id == "stale_daje"):
		if _jest_liczba(_swiat.get("kieszonkowe_kwota_zl")):
			linia_kiesz += " · %d zł/tydzień" % int(_swiat["kieszonkowe_kwota_zl"])
		else:
			linia_kiesz += " · kwota tygodniowa: —"
	_tresc_biala().add_child(_napis_ekranu(linia_kiesz, 16))
	var prosba := Button.new()
	prosba.text = "Poproś o kieszonkowe"
	prosba.custom_minimum_size = Vector2(0, 48)
	prosba.pressed.connect(_on_kieszonkowe)
	_tresc_biala().add_child(prosba)
	var podwyzka := Button.new()
	podwyzka.text = "Poproś o podniesienie kieszonkowego"
	podwyzka.custom_minimum_size = Vector2(0, 48)
	podwyzka.disabled = not aktywne
	podwyzka.pressed.connect(_on_kieszonkowe_podwyzka)
	_tresc_biala().add_child(podwyzka)
	var jednoraz := Button.new()
	jednoraz.text = "Poproś o pieniądze na coś"
	jednoraz.custom_minimum_size = Vector2(0, 48)
	jednoraz.pressed.connect(_on_pieniadze_jednorazowo)
	_tresc_biala().add_child(jednoraz)
	var wynik_lbl := _napis_ekranu(str(_swiat.get("ostatnie_kieszonkowe_tekst", "")), 15)
	wynik_lbl.name = "WynikKieszonkowego"
	wynik_lbl.visible = str(_swiat.get("ostatnie_kieszonkowe_tekst", "")) != ""
	_tresc_biala().add_child(wynik_lbl)


func _opis_rodzica(osoba: Variant) -> String:
	if not (osoba is Dictionary) or osoba.is_empty():
		return "Brak w zapisie (stary save? Start jeszcze raz)."
	var czesci: PackedStringArray = []
	var imie := ""
	if osoba.get("imie") is Dictionary:
		imie = str(osoba["imie"].get("nazwa", ""))
	if imie != "":
		czesci.append(imie)
	else:
		czesci.append("imię: —")
	var cechy := _cechy_listy(osoba.get("charakter"))
	czesci.append("cechy: %s" % (cechy if cechy != "" else "—"))
	var praca := ""
	if osoba.get("praca") is Dictionary and bool(osoba["praca"].get("kolo", false)):
		# UI: konkretny zawód (2-digit), nie sama grupa ISCO.
		if osoba["praca"].get("zawod") != null and str(osoba["praca"]["zawod"]) != "":
			praca = str(osoba["praca"]["zawod"])
		else:
			praca = str(osoba["praca"].get("nazwa", ""))
		var grupa_n := str(osoba["praca"].get("grupa_nazwa", ""))
		if grupa_n != "" and grupa_n != praca:
			praca += " (%s)" % grupa_n
	elif osoba.get("praca") is Dictionary:
		var powod_p := str(osoba["praca"].get("powod", ""))
		praca = "brak wag" + ((" — " + powod_p) if powod_p != "" else "")
	czesci.append("praca: %s" % (praca if praca != "" else "—"))
	var zar_os := _tekst_zarobkow(osoba.get("zarobki"))
	if zar_os == "" and osoba.get("zarobki") is Dictionary:
		var powod_z := str(osoba["zarobki"].get("powod", "")).strip_edges()
		czesci.append("zarobki: —%s" % ((" (%s)" % powod_z) if powod_z != "" else ""))
	else:
		var z_grupy := ""
		if osoba.get("zarobki") is Dictionary:
			z_grupy = str(osoba["zarobki"].get("zarobki_z", ""))
		if zar_os != "":
			czesci.append("zarobki: %s%s" % [zar_os, (" [%s]" % z_grupy) if z_grupy != "" else ""])
		else:
			czesci.append("zarobki: —")
	return " · ".join(czesci)


func _ekran_lista_osob(klucz: String, pusto: String) -> void:
	var lista: Variant = _swiat.get(klucz, [])
	if not (lista is Array) or lista.is_empty():
		_tresc_biala().add_child(_napis_ekranu(pusto, 16))
		return
	var nr := 1
	for osoba in lista:
		if not (osoba is Dictionary):
			continue
		var cechy := _cechy_listy_z_karty(osoba)
		var plec := _nazwa_pola(osoba.get("plec"))
		var linia := "%d. %s" % [nr, plec if plec != "" else "osoba"]
		if cechy != "":
			linia += " — %s" % cechy
		_tresc_biala().add_child(_napis_ekranu(linia, 16))
		nr += 1


func _opis_rodzenstwa(osoba: Dictionary, nr: int) -> String:
	var etykieta := str(osoba.get("etykieta", ""))
	if etykieta == "":
		var imie_txt := ""
		if osoba.get("imie") is Dictionary:
			imie_txt = str(osoba["imie"].get("nazwa", ""))
		var plec_id := ""
		if osoba.get("plec") is Dictionary:
			plec_id = str(osoba["plec"].get("id", ""))
		if imie_txt != "":
			etykieta = "%s (%s)" % [imie_txt, "siostra" if plec_id == "kobieta" else "brat"]
		else:
			etykieta = "Siostra %d" % nr if plec_id == "kobieta" else "Brat %d" % nr
	var cechy := _cechy_listy_z_karty(osoba)
	if cechy != "":
		return "%s — %s" % [etykieta, cechy]
	return etykieta


func _cechy_listy(lista: Variant) -> String:
	if not (lista is Array):
		return ""
	var nazwy: PackedStringArray = []
	for pozycja in lista:
		var nazwa := _nazwa_pola(pozycja)
		if nazwa == "" and pozycja is String:
			nazwa = str(pozycja)
		if nazwa != "":
			nazwy.append(nazwa)
	return ", ".join(nazwy)


func _cechy_listy_z_karty(karta: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while karta.has("cecha_%d" % numer):
		var nazwa := _nazwa_pola(karta["cecha_%d" % numer])
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _opis_sylwetki(bohater: Dictionary) -> String:
	var blok: Variant = bohater.get("sylwetka", {})
	if not (blok is Dictionary):
		return ""
	var syl := Sylwetka.new()
	syl.z_zapisu(blok)
	return syl.tekst_stanu()


func _opis_zainteresowania(bohater: Dictionary) -> String:
	var z: Variant = bohater.get("zainteresowanie", {})
	if not (z is Dictionary):
		return ""
	var nazwa := str(z.get("nazwa", ""))
	if nazwa == "":
		return ""
	return "Zainteresowanie (dominujące): %s" % nazwa


func _opis_dziadkow(blok: Variant) -> String:
	if not (blok is Dictionary):
		return "Brak w zapisie (Start jeszcze raz)."
	var lista: Variant = blok.get("lista", [])
	if not (lista is Array) or lista.is_empty():
		return "Brak żyjących dziadków w wylosowanym zestawie."
	var linie: PackedStringArray = []
	for o in lista:
		if not (o is Dictionary):
			continue
		linie.append(_opis_rodzica(o))
	return "\n".join(linie)


func _on_kieszonkowe_dziadkowie() -> void:
	if _swiat.is_empty():
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return
	var stan_d: Dictionary = {}
	if rodzina.get("dziadkowie") is Dictionary:
		stan_d = rodzina["dziadkowie"]
	if stan_d.get("lista") is Array and (stan_d["lista"] as Array).is_empty():
		_swiat["ostatnie_kieszonkowe_dziadkowie_tekst"] = "Nie masz dziadków w zapisie."
		_zaplanuj_stos()
		return
	var dziad := Dziadkowie.new()
	var inteligencja := 1
	var boh := _bohater()
	if boh.get("inteligencja") is Array and not (boh["inteligencja"] as Array).is_empty():
		inteligencja = 2
	elif _jest_liczba(boh.get("inteligencja")):
		inteligencja = clampi(int(boh["inteligencja"]) / 33, 0, 3)
	var wynik: Dictionary = dziad.popros_o_kieszonkowe(
		stan_d, rodzina, inteligencja, int(_swiat.get("tydzien", 0)), false
	)
	rodzina["dziadkowie"] = stan_d
	_swiat["rodzina"] = rodzina
	_swiat["ostatnie_kieszonkowe_dziadkowie_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and _jest_liczba(wynik.get("kwota")):
		_dodaj_pieniadze(int(wynik["kwota"]))
		_dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	SkryptZapisu.zapisz(_swiat)
	_odswiez_pasek_statystyk(true)
	_zaplanuj_stos()


func _wyplata_kieszonkowego_dziadkow_tydzien() -> void:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary) or not (rodzina.get("dziadkowie") is Dictionary):
		return
	var stan_d: Dictionary = rodzina["dziadkowie"]
	var dziad := Dziadkowie.new()
	var wynik: Dictionary = dziad.wyplata_tygodniowa(stan_d, int(_swiat.get("tydzien", 0)))
	rodzina["dziadkowie"] = stan_d
	_swiat["rodzina"] = rodzina
	if bool(wynik.get("ok", false)) and _jest_liczba(wynik.get("kwota")):
		_dodaj_pieniadze(int(wynik["kwota"]))
		_dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
		var kom := str(_swiat.get("komunikat_tury", ""))
		var dopisek := str(wynik.get("tekst", ""))
		_swiat["komunikat_tury"] = (kom + "\n" + dopisek).strip_edges() if kom != "" else dopisek


func _efekt_konserwacji_auta_tydzien() -> void:
	var auto: Variant = _swiat.get("auto", null)
	if not (auto is Dictionary):
		return
	var stan_k: Dictionary = {}
	if auto.get("konserwacja") is Dictionary:
		stan_k = auto["konserwacja"]
	else:
		var k := KonserwacjaAuta.new()
		stan_k = k.stan_startowy()
	var kon := KonserwacjaAuta.new()
	var tydzien := int(_swiat.get("tydzien", 1))
	var zima := tydzien <= 8 or tydzien >= 48
	var efekt: Dictionary = kon.efekt_tury(stan_k, zima)
	auto["konserwacja"] = stan_k
	_swiat["auto"] = auto
	if efekt.get("teksty") is Array and not (efekt["teksty"] as Array).is_empty():
		var kom := str(_swiat.get("komunikat_tury", ""))
		var dop := " · ".join(PackedStringArray(efekt["teksty"]))
		_swiat["komunikat_tury"] = (kom + "\n" + dop).strip_edges() if kom != "" else dop


func _on_kieszonkowe() -> void:
	if _swiat.is_empty():
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var pierwsza := bool(_swiat.get("kieszonkowe_pierwsza_rozmowa", true))
	var tryb_teraz := str(_swiat.get("tryb_kieszonkowego", ""))
	var wynik: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, tryb_teraz, pierwsza, _wiek_lat())
	_swiat["kieszonkowe_pierwsza_rozmowa"] = false
	_swiat["ostatnie_kieszonkowe"] = wynik
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and _jest_liczba(wynik.get("kwota")):
		_dodaj_pieniadze(int(wynik["kwota"]))
		_dodaj_wplyw("kieszonkowe", int(wynik["kwota"]), str(wynik.get("tekst", "")))
		_swiat["tryb_kieszonkowego"] = "stala_kwota"
		_swiat["kieszonkowe_aktywne"] = true
		_swiat["kieszonkowe_kwota_zl"] = int(wynik["kwota"])
		_swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = int(_swiat.get("tydzien", 0))
	elif str(wynik.get("powod", "")) == "wiek_ponizej_progu" or str(wynik.get("tryb", "")) == "odmowa":
		if str(wynik.get("tryb", "")) == "odmowa":
			_swiat["tryb_kieszonkowego"] = "odmowa"
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	SkryptZapisu.zapisz(_swiat)
	_odswiez_pasek_statystyk(true)
	_zaplanuj_stos()


func _on_kieszonkowe_podwyzka() -> void:
	if _swiat.is_empty() or not bool(_swiat.get("kieszonkowe_aktywne", false)):
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.popros_o_podwyzke_kieszonkowego(
		rodzina, _swiat.get("kieszonkowe_kwota_zl", null), _wiek_lat()
	)
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and _jest_liczba(wynik.get("kwota")):
		_swiat["kieszonkowe_kwota_zl"] = int(wynik["kwota"])
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	SkryptZapisu.zapisz(_swiat)
	_zaplanuj_stos()


func _on_pieniadze_jednorazowo() -> void:
	if _swiat.is_empty():
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.popros_o_pieniadze_jednorazowo(rodzina, _wiek_lat())
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and _jest_liczba(wynik.get("kwota")):
		_dodaj_pieniadze(int(wynik["kwota"]))
		_dodaj_wplyw("pieniadze_jednorazowo", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	SkryptZapisu.zapisz(_swiat)
	_odswiez_pasek_statystyk(true)
	_zaplanuj_stos()


func _zsynchronizuj_pieniadze_z_bohatera() -> void:
	var stan := _jedzenie.odczyt_statystyk()
	if _jest_liczba(stan.get("pieniadze")):
		return
	var bohater := _bohater()
	if _jest_liczba(bohater.get("pieniadze")):
		_jedzenie.zastosuj_statystyki({"pieniadze": int(bohater["pieniadze"])})


func _dodaj_pieniadze(kwota: int) -> void:
	if kwota <= 0:
		return
	var stan := _jedzenie.odczyt_statystyk()
	var teraz := 0
	if _jest_liczba(stan.get("pieniadze")):
		teraz = int(stan["pieniadze"])
	elif _jest_liczba(_bohater().get("pieniadze")):
		teraz = int(_bohater()["pieniadze"])
	var nowe := teraz + kwota
	_jedzenie.zastosuj_statystyki({"pieniadze": nowe})
	var bohater := _bohater()
	bohater["pieniadze"] = nowe
	_swiat["bohater"] = bohater


func _dodaj_wplyw(zrodlo: String, kwota: int, tekst: String = "") -> void:
	if not (_swiat.get("wplywy") is Array):
		_swiat["wplywy"] = []
	var lista: Array = _swiat["wplywy"]
	var etykieta := zrodlo
	if tekst != "" and tekst.find(":") >= 0:
		etykieta = tekst.get_slice(":", 0).strip_edges()
	lista.append({
		"zrodlo": zrodlo,
		"kwota": kwota,
		"tekst": ("%s: +%d zł" % [etykieta, kwota]) if tekst == "" else tekst,
		"rok": int(_swiat.get("rok", 0)),
		"tydzien": int(_swiat.get("tydzien", 0)),
	})
	# Trzymaj ostatnie ~30 wpisów.
	while lista.size() > 30:
		lista.remove_at(0)
	_swiat["wplywy"] = lista


func _wiek_lat() -> Variant:
	var bohater := _bohater()
	if _jest_liczba(bohater.get("wiek")):
		return int(bohater["wiek"])
	if _jest_liczba(_swiat.get("rok")):
		return int(_swiat["rok"])
	return null


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
	if cfg is Dictionary and _jest_liczba(cfg.get("prog_wiek_lat")):
		prog = int(cfg["prog_wiek_lat"])
	var wiek: Variant = _wiek_lat()
	return _jest_liczba(wiek) and int(wiek) >= prog


func _odswiez_flage_jedzenia_sam() -> void:
	if bool(_swiat.get("odblokowane_jedzenie_samemu", false)):
		return
	if _czy_jedzenie_sam_po_wieku():
		_swiat["odblokowane_jedzenie_samemu"] = true


func _ekran_majatek() -> void:
	_tresc_biala().add_child(_napis_ekranu("Pieniądze", 18))
	var kwota := _pieniadze_tekst()
	_tresc_biala().add_child(_napis_ekranu(kwota if kwota != "" else "—", 18))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		_tresc_biala().add_child(_napis_ekranu(opis_lokum, 16))
	_tresc_biala().add_child(_napis_ekranu("Nieruchomości", 18))
	var maj: Dictionary = _swiat.get("majatek", {}) if _swiat.get("majatek") is Dictionary else {}
	var n_lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if n_lista.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Własne kupione: brak — kup w Zakupach (generator, nie katalog 200).", 14))
	else:
		for i in range(n_lista.size()):
			var n: Variant = n_lista[i]
			if not (n is Dictionary):
				continue
			var linia := "%s · %s · wygoda %s · %s" % [
				str(n.get("nazwa", "?")),
				_etykieta_stanu_zakupu(str(n.get("stan", ""))),
				str(n.get("wygoda", "—")),
				str(n.get("miasto_nazwa", "")),
			]
			_tresc_biala().add_child(_napis_ekranu(linia, 14))
			var idx_bind := i
			var b_rem := Button.new()
			b_rem.text = "Remont (propozycja koszt/wygoda)"
			b_rem.custom_minimum_size = Vector2(0, 40)
			b_rem.pressed.connect(func() -> void:
				var wynik: Dictionary = _rynek_zakupow.remont(_swiat, idx_bind)
				if bool(wynik.get("ok", false)):
					_rynek_zakupow.przelicz_zadowolenie_docelowe(_swiat)
					SkryptZapisu.zapisz(_swiat)
					_zsynchronizuj_pieniadze_z_bohatera()
					_odswiez_pasek_statystyk(false)
					_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
				else:
					_tresc_biala().add_child(_napis_ekranu(str(wynik.get("powod", "Remont nieudany.")), 13))
			)
			_tresc_biala().add_child(b_rem)
	_tresc_biala().add_child(_napis_ekranu("Dobra", 18))
	var d_lista: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if d_lista.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Pusto.", 14))
	else:
		for i_d in range(d_lista.size()):
			var d: Variant = d_lista[i_d]
			if not (d is Dictionary):
				continue
			var nazwa_d := str(d.get("nazwa", "?"))
			if str(d.get("kategoria", "")) == "samochod":
				var linia_a := nazwa_d
				var vmax_m := _rynek_zakupow.tekst_vmax_oferty(d, d.get("usterki_rzeczywiste", []) if d.get("usterki_rzeczywiste") is Array else [])
				if vmax_m != "":
					linia_a += " · vmax %s km/h" % vmax_m
				if bool(d.get("nie_jezdzi", false)):
					linia_a += " · NIE JEŹDZI"
				_tresc_biala().add_child(_napis_ekranu(linia_a, 14))
				if bool(d.get("nie_jezdzi", false)) or bool(d.get("do_naprawy", false)):
					_tresc_biala().add_child(_panel_awarii_auta(i_d, d))
			else:
				_tresc_biala().add_child(_napis_ekranu(nazwa_d, 14))
	_tresc_biala().add_child(_napis_ekranu("Wpływy", 18))
	var lista: Variant = _swiat.get("wplywy", [])
	if not (lista is Array) or lista.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Brak wpływów.", 15))
		return
	var od := maxi(0, lista.size() - 12)
	for i in range(od, lista.size()):
		var wpis: Variant = lista[i]
		if not (wpis is Dictionary):
			continue
		var linia2 := str(wpis.get("tekst", ""))
		if linia2 == "" and _jest_liczba(wpis.get("kwota")):
			linia2 = "%s: +%d zł" % [str(wpis.get("zrodlo", "wpływ")), int(wpis["kwota"])]
		if linia2 != "":
			_tresc_biala().add_child(_napis_ekranu(linia2, 15))


func _ekran_zakupy() -> void:
	_odswiez_rynek_zakupow()
	_tresc_biala().add_child(_napis_ekranu("Zakupy — losowane oferty (limit miasta × tura). Nie arkusz strategii.", 16))
	var dane := _wczytaj_zakupy_oferty()
	var kategorie: Variant = dane.get("kategorie", []) if dane is Dictionary else []
	if not (kategorie is Array) or kategorie.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Brak kategorii w danych.", 16))
		return
	for kat in kategorie:
		if not (kat is Dictionary):
			continue
		var przycisk := Button.new()
		przycisk.text = str(kat.get("nazwa", kat.get("id", "")))
		przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
		przycisk.custom_minimum_size = Vector2(0, 48)
		przycisk.add_theme_font_size_override("font_size", 18)
		var kat_bind: Dictionary = kat
		przycisk.pressed.connect(func() -> void:
			_wejdz_w_kategorie_zakupow(kat_bind)
		)
		_tresc_biala().add_child(przycisk)


func _wejdz_w_kategorie_zakupow(kat: Dictionary) -> void:
	var zakupy: Dictionary = {}
	if _akcje_po_id.has("zakupy") and _akcje_po_id["zakupy"] is Dictionary:
		zakupy = (_akcje_po_id["zakupy"] as Dictionary).duplicate(true)
	else:
		zakupy = {"id": "zakupy", "nazwa": "Zakupy", "tryb": "ekran", "tresc": "zakupy", "kolor": "#b0a04a"}
	if str(kat.get("rodzaj", "")) == "budzet_jakosci" or str(kat.get("id", "")) == "drobiazgi":
		_otworz_akcje({
			"id": "zakupy_kat_drobiazgi",
			"nazwa": str(kat.get("nazwa", "Drobiazgi")),
			"tryb": "ekran",
			"tresc": "zakupy_kategoria",
			"kat": kat,
			"kolor": str(zakupy.get("kolor", "#b0a04a")),
			"sciezka_rodzicow": [zakupy],
		})
		return
	_otworz_akcje({
		"id": "zakupy_kat_%s" % str(kat.get("id", "")),
		"nazwa": str(kat.get("nazwa", "Zakupy")),
		"tryb": "ekran",
		"tresc": "zakupy_kategoria",
		"kat": kat,
		"kolor": str(zakupy.get("kolor", "#b0a04a")),
		"sciezka_rodzicow": [zakupy],
	})


func _ekran_zakupy_kategoria(kat: Dictionary) -> void:
	## Kompatybilność: wejście hierarchiczne przez _wejdz_w_kategorie_zakupow.
	_wejdz_w_kategorie_zakupow(kat)


func _ekran_budzet_drobiazgow() -> void:
	_tresc_biala().add_child(_napis_ekranu("Budżet jakości drobiazgów (propozycja; szansa zdarzenia nadal null).", 14))
	var budzet: Dictionary = {}
	if FileAccess.file_exists(PLIK_DROBIAZGOW):
		var plik := FileAccess.open(PLIK_DROBIAZGOW, FileAccess.READ)
		if plik != null:
			var dane_d: Variant = JSON.parse_string(plik.get_as_text())
			if dane_d is Dictionary and dane_d.get("budzet_jakosci") is Dictionary:
				budzet = dane_d["budzet_jakosci"]
	var min_zl := int(budzet.get("min_zl", 0)) if _jest_liczba(budzet.get("min_zl")) else 0
	var max_zl := int(budzet.get("max_zl", 100)) if _jest_liczba(budzet.get("max_zl")) else 100
	var krok := int(budzet.get("krok_zl", 5)) if _jest_liczba(budzet.get("krok_zl")) else 5
	var wartosc := int(_swiat.get("budzet_jakosci_drobiazgow_zl", budzet.get("domyslnie_zl", 0)))
	var opis := _napis_ekranu("Przeznaczam: %d zł" % wartosc, 16)
	_tresc_biala().add_child(opis)
	var suwak := HSlider.new()
	suwak.min_value = float(min_zl)
	suwak.max_value = float(max_zl)
	suwak.step = float(krok)
	suwak.value = float(clampi(wartosc, min_zl, max_zl))
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.value_changed.connect(func(v: float) -> void:
		_swiat["budzet_jakosci_drobiazgow_zl"] = int(v)
		opis.text = "Przeznaczam: %d zł" % int(v)
	)
	_tresc_biala().add_child(suwak)


func _ekran_zakupy_oferty(kat_id: String, stan_filtr: String, kat: Dictionary) -> void:
	_wyczysc(_tresc_biala())
	_wyczysc(_dol_suwaka())
	_dol_suwaka().hide()
	_tytul_bialy().text = str(kat.get("nazwa", kat_id))
	_odswiez_rynek_zakupow()
	_zakupy_wiersze = []
	_zakupy_kat_id = kat_id
	_zakupy_stan_filtr = stan_filtr
	_zakupy_kat_slownik = kat
	_zakupy_filtr_odbior = ""
	_zakupy_zasieg_poziom = "miasto"
	_zakupy_filtr_rozwiniety = true
	_zakupy_filtr_ceny_wlaczony = false
	_zakupy_filtr_przebiegu_wlaczony = false
	_zakupy_przebieg_od = 0.0
	_zakupy_przebieg_do = 0.0
	_zakupy_filtr_marki = []
	_zakupy_filtr_naped = ""
	_zakupy_panel_nowe_auta = null
	_zakupy_sort_cena = "malejaco"
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
	_zakupy_zasieg_km = float(zas.get("domyslnie", 25))
	var poziomy_zas: Array = conf_n.get("zasieg_szukania_poziomy", []) if conf_n.get("zasieg_szukania_poziomy") is Array else []
	# Przedział cen z całej kategorii (nie tylko po stanie) — żeby suwak był widoczny także gdy
	# chwilowo brak ofert w wybranym stanie; lista i tak tnie po _zakupy_stan_filtr.
	var wszystkie := _rynek_zakupow.oferty_filtrowane(_swiat, kat_id, "", 9999.0, 0.0, 0.0, false, "")
	var ceny: Array = []
	for o in wszystkie:
		if o is Dictionary and _jest_liczba(o.get("cena_zl")):
			ceny.append(float(o["cena_zl"]))
	ceny.sort()
	if kat_id == "samochod":
		var mid_pula := _id_miejsca_pobytu()
		var oferty_stan: Array = []
		var baza_pula := 0
		if _swiat.get("rynek_zakupow") is Dictionary:
			var rz: Dictionary = _swiat["rynek_zakupow"]
			if rz.get("oferty") is Array:
				oferty_stan = rz["oferty"]
			if _jest_liczba(rz.get("baza_ogloszen_aut")):
				baza_pula = int(rz["baza_ogloszen_aut"])
		var ile_uzywanych := _rynek_zakupow.ile_aut_w_miescie(oferty_stan, mid_pula)
		_tresc_biala().add_child(_napis_ekranu(
			"Pula używanych: %d (baza ≈ ludność/5000%s)" % [
				ile_uzywanych,
				(" = %d" % baza_pula) if baza_pula > 0 else "",
			],
			17
		))
	# Filtr u góry — po wejściu w kategorię rozwinięty (widać min–max od razu).
	var przycisk_filtr := Button.new()
	przycisk_filtr.text = "Filtr ▾"
	przycisk_filtr.alignment = HORIZONTAL_ALIGNMENT_LEFT
	przycisk_filtr.custom_minimum_size = Vector2(0, 44)
	przycisk_filtr.add_theme_font_size_override("font_size", 17)
	_tresc_biala().add_child(przycisk_filtr)
	var panel_filtr := VBoxContainer.new()
	panel_filtr.visible = true
	panel_filtr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_filtr.add_theme_constant_override("separation", 8)
	_tresc_biala().add_child(panel_filtr)
	przycisk_filtr.pressed.connect(func() -> void:
		_zakupy_filtr_rozwiniety = not _zakupy_filtr_rozwiniety
		panel_filtr.visible = _zakupy_filtr_rozwiniety
		przycisk_filtr.text = "Filtr ▾" if _zakupy_filtr_rozwiniety else "Filtr ▸"
	)
	# Cena min–max: liczniki obok siebie (poziomo), nie jeden pod drugim.
	var rzad_licz := HBoxContainer.new()
	rzad_licz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rzad_licz.add_theme_constant_override("separation", 16)
	_zakupy_licznik_od = _napis_ekranu("min: —", 17)
	_zakupy_licznik_do = _napis_ekranu("max: —", 17)
	_zakupy_licznik_od.autowrap_mode = TextServer.AUTOWRAP_OFF
	_zakupy_licznik_do.autowrap_mode = TextServer.AUTOWRAP_OFF
	_zakupy_licznik_od.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_zakupy_licznik_do.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rzad_licz.add_child(_zakupy_licznik_od)
	rzad_licz.add_child(_zakupy_licznik_do)
	panel_filtr.add_child(rzad_licz)
	if ceny.is_empty():
		panel_filtr.add_child(_napis_ekranu("Przedział cen: — (brak liczb; filtr nie zmyśla).", 16))
		_zakupy_filtr_od = 0.0
		_zakupy_filtr_do = 0.0
		_zakupy_filtr_ceny_wlaczony = false
	else:
		var suwak = SkryptZakresu.new()
		suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		suwak.custom_minimum_size = Vector2(120, 48)
		suwak.ustaw_zakres(float(ceny[0]), float(ceny[ceny.size() - 1]))
		_zakupy_filtr_od = suwak.od
		_zakupy_filtr_do = suwak.dokad
		_zakupy_filtr_ceny_wlaczony = true
		_zakupy_licznik_od.text = "min: %d" % int(_zakupy_filtr_od)
		_zakupy_licznik_do.text = "max: %d" % int(_zakupy_filtr_do)
		suwak.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
			_on_zakupy_filtr_ceny(od, dokad)
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(suwak)
	# Zasięg: miasto → powiat → województwo → PL → sąsiedzi → wysyłka + strop km.
	panel_filtr.add_child(_napis_ekranu("Zasięg szukania:", 17))
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
	var opis_z := _napis_ekranu("Strop odległości: %d km" % int(_zakupy_zasieg_km), 16)
	opcje_zas.item_selected.connect(func(idx: int) -> void:
		if idx < 0 or idx >= poziomy_zas.size():
			return
		var p0: Variant = poziomy_zas[idx]
		if p0 is Dictionary:
			_zakupy_zasieg_poziom = str(p0.get("id", "miasto"))
			var mx := float(p0.get("max_km", _zakupy_zasieg_km))
			_zakupy_zasieg_km = mx
			opis_z.text = "Strop odległości: %d km" % int(mx)
		_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(opcje_zas)
	panel_filtr.add_child(opis_z)
	var suwak_z := HSlider.new()
	suwak_z.min_value = zmin
	suwak_z.max_value = zmax
	suwak_z.step = 1.0
	suwak_z.value = _zakupy_zasieg_km
	suwak_z.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak_z.custom_minimum_size = Vector2(0, 36)
	suwak_z.value_changed.connect(func(v: float) -> void:
		_zakupy_zasieg_km = v
		opis_z.text = "Strop odległości: %d km" % int(v)
		_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(suwak_z)
	# Ruchome: stan używany/nowy + odbiór osobisty/wysyłka. Budynki: tylko cena + odległość.
	_zakupy_filtr_odbior = ""
	if not nieruchomosc:
		if uzywany_nowy:
			panel_filtr.add_child(_napis_ekranu("Stan:", 17))
			var opcje_stan := OptionButton.new()
			opcje_stan.add_item("Wszystkie", 0)
			opcje_stan.add_item("Używany", 1)
			opcje_stan.add_item("Nowy", 2)
			var idx_stan := 0
			if _zakupy_stan_filtr == "uzywany":
				idx_stan = 1
			elif _zakupy_stan_filtr == "nowy":
				idx_stan = 2
			opcje_stan.select(idx_stan)
			opcje_stan.custom_minimum_size = Vector2(0, 40)
			opcje_stan.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			opcje_stan.add_theme_font_size_override("font_size", 17)
			opcje_stan.item_selected.connect(func(idx: int) -> void:
				match idx:
					1:
						_zakupy_stan_filtr = "uzywany"
					2:
						_zakupy_stan_filtr = "nowy"
					_:
						_zakupy_stan_filtr = ""
				if _zakupy_panel_nowe_auta != null and is_instance_valid(_zakupy_panel_nowe_auta):
					_zakupy_panel_nowe_auta.visible = (_zakupy_stan_filtr == "" or _zakupy_stan_filtr == "nowy")
				_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
			)
			panel_filtr.add_child(opcje_stan)
		panel_filtr.add_child(_napis_ekranu("Odbiór osobisty:", 17))
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
					_zakupy_filtr_odbior = "osobisty"
				2:
					_zakupy_filtr_odbior = "wysylka"
				_:
					_zakupy_filtr_odbior = ""
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_odbior)
	# Samochód: przebieg min–max; multi-select marek (puste = wszystkie) + napęd dla nowych.
	if kat_id == "samochod":
		panel_filtr.add_child(_napis_ekranu("Sortuj cenę:", 17))
		var opcje_sort := OptionButton.new()
		opcje_sort.add_item("Od największej", 0)
		opcje_sort.add_item("Od najmniejszej", 1)
		opcje_sort.select(0 if _zakupy_sort_cena == "malejaco" else 1)
		opcje_sort.custom_minimum_size = Vector2(0, 40)
		opcje_sort.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_sort.add_theme_font_size_override("font_size", 17)
		opcje_sort.item_selected.connect(func(idx: int) -> void:
			_zakupy_sort_cena = "malejaco" if idx == 0 else "rosnaco"
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_sort)
		var przebiegi: Array = []
		for o in wszystkie:
			if o is Dictionary and _jest_liczba(o.get("przebieg_km")):
				przebiegi.append(float(o["przebieg_km"]))
		przebiegi.sort()
		panel_filtr.add_child(_napis_ekranu("Przebieg (km):", 17))
		var rzad_p := HBoxContainer.new()
		rzad_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rzad_p.add_theme_constant_override("separation", 16)
		_zakupy_licznik_przebieg_od = _napis_ekranu("min: —", 17)
		_zakupy_licznik_przebieg_do = _napis_ekranu("max: —", 17)
		_zakupy_licznik_przebieg_od.autowrap_mode = TextServer.AUTOWRAP_OFF
		_zakupy_licznik_przebieg_do.autowrap_mode = TextServer.AUTOWRAP_OFF
		rzad_p.add_child(_zakupy_licznik_przebieg_od)
		rzad_p.add_child(_zakupy_licznik_przebieg_do)
		panel_filtr.add_child(rzad_p)
		if przebiegi.is_empty():
			panel_filtr.add_child(_napis_ekranu("Przedział przebiegu: — (brak liczb).", 16))
			_zakupy_filtr_przebiegu_wlaczony = false
		else:
			var suwak_p = SkryptZakresu.new()
			suwak_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			suwak_p.custom_minimum_size = Vector2(120, 48)
			suwak_p.ustaw_zakres(float(przebiegi[0]), float(przebiegi[przebiegi.size() - 1]))
			_zakupy_przebieg_od = suwak_p.od
			_zakupy_przebieg_do = suwak_p.dokad
			_zakupy_filtr_przebiegu_wlaczony = true
			_zakupy_licznik_przebieg_od.text = "min: %d km" % int(_zakupy_przebieg_od)
			_zakupy_licznik_przebieg_do.text = "max: %d km" % int(_zakupy_przebieg_do)
			suwak_p.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
				_zakupy_przebieg_od = od
				_zakupy_przebieg_do = dokad
				_zakupy_filtr_przebiegu_wlaczony = true
				if _zakupy_licznik_przebieg_od != null and is_instance_valid(_zakupy_licznik_przebieg_od):
					_zakupy_licznik_przebieg_od.text = "min: %d km" % int(od)
				if _zakupy_licznik_przebieg_do != null and is_instance_valid(_zakupy_licznik_przebieg_do):
					_zakupy_licznik_przebieg_do.text = "max: %d km" % int(dokad)
				_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
			)
			panel_filtr.add_child(suwak_p)
		panel_filtr.add_child(_napis_ekranu("Marki (kilka naraz; puste = wszystkie):", 17))
		var marki: Array = _rynek_zakupow.marki_katalogu_aut()
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
		panel_nowe.visible = (_zakupy_stan_filtr == "" or _zakupy_stan_filtr == "nowy")
		_zakupy_panel_nowe_auta = panel_nowe
		panel_nowe.add_child(_napis_ekranu("Napęd (nowe):", 17))
		var opcje_naped := OptionButton.new()
		opcje_naped.add_item("Wszystkie", 0)
		var napedy: Array = _rynek_zakupow.napedy_katalogu_aut()
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
				_zakupy_filtr_naped = ""
			else:
				var n2: Variant = napedy[idx - 1]
				_zakupy_filtr_naped = str(n2.get("id", "")) if n2 is Dictionary else str(n2)
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_nowe.add_child(opcje_naped)
		panel_filtr.add_child(panel_nowe)
	_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)


func _przerysuj_liste_zakupow(kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	var tresc := _tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if dziecko.has_meta("zakupy_oferta"):
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	_zakupy_wiersze = []
	# Cena: włączona gdy jest suwak — także gdy min==0 (stary warunek do>0 wyłączał filtr).
	var filtr_c := _zakupy_filtr_ceny_wlaczony and _zakupy_filtr_do >= _zakupy_filtr_od
	var filtr_p := kat_id == "samochod" and _zakupy_filtr_przebiegu_wlaczony and _zakupy_przebieg_do >= _zakupy_przebieg_od
	var marki_f: Array = []
	var naped_f := ""
	if kat_id == "samochod":
		marki_f = _zakupy_filtr_marki.duplicate()
		if stan_filtr == "nowy" or stan_filtr == "":
			naped_f = _zakupy_filtr_naped
	var oferty := _rynek_zakupow.oferty_filtrowane(
		_swiat,
		kat_id,
		"" if nieruchomosc else stan_filtr,
		_zakupy_zasieg_km,
		_zakupy_filtr_od,
		_zakupy_filtr_do if filtr_c else 1.0e12,
		filtr_c,
		_zakupy_filtr_odbior,
		_zakupy_przebieg_od,
		_zakupy_przebieg_do if filtr_p else 1.0e12,
		filtr_p,
		marki_f,
		naped_f,
		_zakupy_zasieg_poziom if kat_id == "samochod" else ""
	)
	if not nieruchomosc and stan_filtr != "":
		var tylko: Array = []
		for o in oferty:
			if o is Dictionary and str(o.get("stan", "")) == stan_filtr:
				tylko.append(o)
		oferty = tylko
	if kat_id == "samochod":
		oferty = _posortuj_oferty_cena(oferty, _zakupy_sort_cena)
	if oferty.is_empty():
		var pusto := _napis_ekranu("Brak ofert w zasięgu / filtrze. Następna tura ruszy pulą.", 16)
		pusto.set_meta("zakupy_oferta", true)
		tresc.add_child(pusto)
		return
	for o in oferty:
		if not (o is Dictionary):
			continue
		var wiersz := _buduj_skrot_karty_oferty(o, kat_id, stan_filtr, etykiety, nieruchomosc)
		tresc.add_child(wiersz)
		_zakupy_wiersze.append({"cena": o.get("cena_zl"), "wezel": wiersz})


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
	var nazwa := str(o.get("nazwa", o.get("id", "")))
	var stan_txt := str(etykiety.get(str(o.get("stan", "")), o.get("stan", "")))
	var cena_txt := _tekst_ceny_oferty(o.get("cena_zl"), kat_id)
	if nieruchomosc:
		wiersz.add_child(_napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 17))
		wiersz.add_child(_napis_ekranu(
			"%s · %d pok. · ~%.0f km · wygoda %d" % [
				str(o.get("miasto_nazwa", "?")),
				int(o.get("pokoje", 0)),
				float(o.get("odleglosc_km", 0)),
				int(o.get("wygoda", 0)),
			],
			16
		))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(_napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 17))
		wiersz.add_child(_napis_ekranu(
			"%s · ~%.0f km · %s" % [
				str(o.get("miasto_nazwa", "?")),
				float(o.get("odleglosc_km", 0)),
				_etykieta_odbioru(str(o.get("sposob_odbioru", ""))),
			],
			16
		))
		if kat_id == "samochod" and _jest_liczba(o.get("przebieg_km")):
			wiersz.add_child(_napis_ekranu("Przebieg: %d km" % int(o["przebieg_km"]), 16))
		elif _jest_liczba(o.get("lata_od_zakupu")):
			wiersz.add_child(_napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(_napis_ekranu("Segment: %s" % str(o["segment"]), 15))
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
	for wpis in _stos:
		if wpis is Dictionary:
			rodzice.append((wpis as Dictionary).duplicate(true))
	if rodzice.is_empty():
		var zakupy: Dictionary = _akcje_po_id.get("zakupy", {
			"id": "zakupy", "nazwa": "Zakupy", "tryb": "ekran", "tresc": "zakupy", "kolor": "#b0a04a"
		})
		if zakupy is Dictionary:
			rodzice.append((zakupy as Dictionary).duplicate(true))
		rodzice.append({
			"id": "zakupy_kat_%s" % kat_id,
			"nazwa": str(_zakupy_kat_slownik.get("nazwa", kat_id)),
			"tryb": "ekran",
			"tresc": "zakupy_kategoria",
			"kat": _zakupy_kat_slownik if not _zakupy_kat_slownik.is_empty() else {"id": kat_id, "nazwa": kat_id},
		})
	_otworz_akcje({
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
	var kat_id := str(akcja.get("kat_id", _zakupy_kat_id))
	var stan_filtr := str(akcja.get("stan_filtr", _zakupy_stan_filtr))
	var etykiety: Dictionary = akcja.get("etykiety", {}) if akcja.get("etykiety") is Dictionary else {}
	var nieruchomosc := bool(akcja.get("nieruchomosc", false))
	var oferta: Dictionary = {}
	if _swiat.get("rynek_zakupow") is Dictionary and _swiat["rynek_zakupow"].get("oferty") is Array:
		for o in _swiat["rynek_zakupow"]["oferty"]:
			if o is Dictionary and str(o.get("id", "")) == oid:
				oferta = o
				break
	if oferta.is_empty():
		_tresc_biala().add_child(_napis_ekranu("Oferta zniknęła z puli (sprzedana lub odświeżona).", 17))
		return
	_tytul_bialy().text = str(oferta.get("nazwa", "Oferta"))
	_tresc_biala().add_child(_buduj_pelna_karte_oferty(oferta, kat_id, stan_filtr, etykiety, nieruchomosc))


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
	var cena_txt := _tekst_ceny_oferty(cena_v, kat_id)
	if nieruchomosc:
		wiersz.add_child(_napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 18))
		wiersz.add_child(_napis_ekranu(
			"%s · %d pok. · ~%.0f km · wygoda %d" % [
				str(o.get("miasto_nazwa", "?")),
				int(o.get("pokoje", 0)),
				float(o.get("odleglosc_km", 0)),
				int(o.get("wygoda", 0)),
			],
			16
		))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(_napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 18))
		wiersz.add_child(_napis_ekranu(
			"%s · ~%.0f km · %s" % [
				str(o.get("miasto_nazwa", "?")),
				float(o.get("odleglosc_km", 0)),
				_etykieta_odbioru(str(o.get("sposob_odbioru", ""))),
			],
			16
		))
		if _jest_liczba(o.get("lata_od_zakupu")) and kat_id != "samochod":
			wiersz.add_child(_napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(_napis_ekranu("Segment: %s" % str(o["segment"]), 16))
		if o.get("czas_oczekiwania") is Dictionary and not (o["czas_oczekiwania"] as Dictionary).is_empty():
			var cz: Dictionary = o["czas_oczekiwania"]
			wiersz.add_child(_napis_ekranu(
				"Czas oczekiwania (fabryka): %d lat + %d tyg." % [int(cz.get("lata", 0)), int(cz.get("tygodnie", 0))],
				16
			))
		if kat_id == "samochod":
			if _jest_liczba(o.get("przebieg_km")):
				wiersz.add_child(_napis_ekranu("Przebieg: %d km" % int(o["przebieg_km"]), 16))
			var naped_txt := _rynek_zakupow.etykieta_napedu(str(o.get("naped", "")))
			if naped_txt != "":
				wiersz.add_child(_napis_ekranu("Napęd: %s" % naped_txt, 16))
			wiersz.add_child(_napis_ekranu("Spalanie: %s" % _rynek_zakupow.tekst_spalania(o), 16))
			if bool(o.get("sprowadzenie", false)) or bool(o.get("import", false)):
				var spr_txt := "Sprowadzenie / import"
				if bool(o.get("szacunek_ceny", false)):
					spr_txt += " (szacunek ceny)"
				var zrd := str(o.get("zrodlo_cennika", ""))
				if zrd != "":
					spr_txt += " · źródło: %s" % zrd
				wiersz.add_child(_napis_ekranu(spr_txt, 16))
			var znane_u: Array = []
			var dek_u_auto: Array = o.get("usterki_deklarowane", []) if o.get("usterki_deklarowane") is Array else []
			var wyk_u_auto: Array = o.get("usterki_wykryte", []) if o.get("usterki_wykryte") is Array else []
			for uid in dek_u_auto:
				znane_u.append(uid)
			for uid in wyk_u_auto:
				if not znane_u.has(uid):
					znane_u.append(uid)
			var vmax_ui := _rynek_zakupow.tekst_vmax_oferty(o, znane_u)
			if vmax_ui != "":
				wiersz.add_child(_napis_ekranu("Prędkość maksymalna: %s km/h" % vmax_ui, 16))
			if bool(o.get("nie_jezdzi", false)) or bool(o.get("do_naprawy", false)):
				wiersz.add_child(_napis_ekranu("Nie jeździ — do naprawy (laweta / mechanik / złom).", 16))
		var dek_u: Array = o.get("usterki_deklarowane", []) if o.get("usterki_deklarowane") is Array else []
		var wyk_u: Array = o.get("usterki_wykryte", []) if o.get("usterki_wykryte") is Array else []
		var seg_u := str(o.get("segment", ""))
		if not dek_u.is_empty():
			var linia_dek := "Usterki (sprzedawca): %s" % _join_tekstow(_rynek_zakupow.nazwy_usterek(dek_u, kat_id, seg_u))
			if bool(o.get("szacunek_usterek", false)):
				linia_dek += " (szacunek)"
			wiersz.add_child(_napis_ekranu(linia_dek, 16))
		if not wyk_u.is_empty():
			wiersz.add_child(_napis_ekranu("Usterki wykryte: %s" % _join_tekstow(_rynek_zakupow.nazwy_usterek(wyk_u, kat_id, seg_u)), 16))
		if kat_id != "samochod" or str(o.get("stan", "")) != "nowy":
			if _jest_liczba(o.get("stan_deklarowany")):
				var dek := int(o["stan_deklarowany"])
				var linia_stan := "Stan deklarowany: %d (%s)" % [dek, _rynek_zakupow.etykieta_stanu_jakosci(dek)]
				if bool(o.get("stan_ujawniony", false)) and _jest_liczba(o.get("stan_oceniony")):
					var oc := int(o["stan_oceniony"])
					linia_stan += " · ocena: %d (%s)" % [oc, _rynek_zakupow.etykieta_stanu_jakosci(oc)]
					if _jest_liczba(o.get("stan_rzeczywisty")) and int(o["stan_deklarowany"]) != int(o["stan_rzeczywisty"]):
						linia_stan += " · rozjazd z deklaracją"
				wiersz.add_child(_napis_ekranu(linia_stan, 16))
		if _jest_liczba(o.get("ocena_zaplanowana_tura")):
			wiersz.add_child(_napis_ekranu("Ocena z pomocą zaplanowana: tura %d" % int(o["ocena_zaplanowana_tura"]), 16))
	var oid := str(o.get("id", ""))
	var tryb_oc := _rynek_zakupow.tryb_oceny_stanu(o) if not nieruchomosc else "przed_zakupem"
	if tryb_oc != "" and not nieruchomosc and _jest_liczba(o.get("stan_rzeczywisty")):
		var rzad_ocena := HBoxContainer.new()
		rzad_ocena.add_theme_constant_override("separation", 8)
		var b_ocen := Button.new()
		b_ocen.text = "Oceń stan" if tryb_oc == "przed_zakupem" else "Oceń po oględzinach"
		b_ocen.custom_minimum_size = Vector2(0, 40)
		b_ocen.add_theme_font_size_override("font_size", 17)
		b_ocen.disabled = bool(o.get("stan_ujawniony", false))
		b_ocen.pressed.connect(func() -> void:
			var w: Dictionary = _rynek_zakupow.ocen_stan(_swiat, oid, false)
			_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
			if bool(w.get("ok", false)):
				var msg := "Ocena stanu: %d (%s)" % [int(w.get("stan_oceniony", 0)), str(w.get("etykieta", ""))]
				if str(w.get("tryb_oceny", "")) == "po_dostawie":
					msg += " (po oględzinach / dostawie)"
				if bool(w.get("rozjazd", false)):
					msg += " — rozjazd względem deklaracji sprzedawcy."
				var uw: Array = w.get("usterki_wykryte", []) if w.get("usterki_wykryte") is Array else []
				if not uw.is_empty():
					msg += " · wykryto: %s" % _join_tekstow(_rynek_zakupow.nazwy_usterek(uw, kat_id, str(o.get("segment", ""))))
				_pokaz_komunikat_zakupu(msg, w)
				SkryptZapisu.zapisz(_swiat)
				_zaplanuj_stos()
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
	if str(o.get("stan", "")) == "uzywany" and not nieruchomosc and _jest_liczba(cena_v):
		wiersz.add_child(_buduj_panel_targowania(o, oid, kat_id, stan_filtr, etykiety, nieruchomosc))
	var b := Button.new()
	b.text = "Kup"
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.disabled = bool(o.get("targowanie_zakonczone", false)) and not o.has("cena_wynegocjowana")
	b.pressed.connect(func() -> void:
		var wynik: Dictionary = _rynek_zakupow.kup(_swiat, oid)
		if bool(wynik.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			_zsynchronizuj_pieniadze_z_bohatera()
			_odswiez_pasek_statystyk(false)
			_cofnij_poziom()
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
	var msg := _napis_ekranu(tekst, 16)
	msg.set_meta("zakupy_oferta", true)
	_tresc_biala().add_child(msg)


func _panel_pomocy_oceny(oferta_id: String, kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	var kandydaci: Array = _rynek_zakupow.kandydaci_pomocy_oceny(_swiat)
	if kandydaci.is_empty():
		_pokaz_komunikat_zakupu("Nikogo nie ma w zapisie (rodzic / przyjaciel / znajomy), kto mógłby pomóc.")
		return
	var panel := VBoxContainer.new()
	panel.set_meta("zakupy_oferta", true)
	panel.add_theme_constant_override("separation", 4)
	panel.add_child(_napis_ekranu("Kto ma pomóc w ocenie?", 14))
	for k in kandydaci:
		if not (k is Dictionary):
			continue
		var ref := str(k.get("ref", ""))
		var btn := Button.new()
		btn.text = "%s (%s)" % [str(k.get("nazwa", "?")), str(k.get("rola", ""))]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.pressed.connect(func() -> void:
			var w: Dictionary = _rynek_zakupow.popros_o_pomoc_oceny(_swiat, oferta_id, ref)
			_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
			if bool(w.get("ok", false)):
				SkryptZapisu.zapisz(_swiat)
				_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)
		)
		panel.add_child(btn)
	_tresc_biala().add_child(panel)


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
		panel.add_child(_napis_ekranu("Targowanie zakończone — sprzedawca nie chce rozmawiać.", 13))
		return panel
	var cena0 := float(oferta.get("cena_wyjsciowa", oferta.get("cena_zl", 0)))
	var conf_dane := _wczytaj_zakupy_oferty()
	var tconf: Dictionary = conf_dane.get("targowanie", {}) if conf_dane.get("targowanie") is Dictionary else {}
	var p_od := float(tconf.get("suwak_procent_od", 50))
	var p_do := float(tconf.get("suwak_procent_do", 100))
	var etykieta := _napis_ekranu("Targuj: 90% ceny = %d zł" % int(round(cena0 * 0.9)), 13)
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
	var dialog_lbl := _napis_ekranu("", 13)
	dialog_lbl.visible = false
	panel.add_child(dialog_lbl)
	var b_targ := Button.new()
	b_targ.text = "Zaproponuj sprzedawcy"
	b_targ.custom_minimum_size = Vector2(0, 34)
	b_targ.pressed.connect(func() -> void:
		var w: Dictionary = _rynek_zakupow.targuj(_swiat, oid, null, suwak.value)
		var tekst := str(w.get("tekst", w.get("powod", "")))
		dialog_lbl.text = tekst
		dialog_lbl.visible = tekst != ""
		if bool(w.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			if str(w.get("wynik", "")) == "akceptacja" or bool(w.get("koniec", false)):
				if not _stos.is_empty() and str(_stos[_stos.size() - 1].get("tresc", "")) == "zakupy_oferta":
					_zaplanuj_stos()
				else:
					_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)
	)
	panel.add_child(b_targ)
	return panel


func _on_zakupy_filtr_ceny(od: float, dokad: float) -> void:
	_zakupy_filtr_od = od
	_zakupy_filtr_do = dokad
	_zakupy_filtr_ceny_wlaczony = true
	if _zakupy_licznik_od != null and is_instance_valid(_zakupy_licznik_od):
		_zakupy_licznik_od.text = "min: %d" % int(od)
	if _zakupy_licznik_do != null and is_instance_valid(_zakupy_licznik_do):
		_zakupy_licznik_do.text = "max: %d" % int(dokad)


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
		cb.button_pressed = _zakupy_filtr_marki.has(str(marka_n))
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.add_theme_font_size_override("font_size", 17)
		cb.toggled.connect(func(wlaczony: bool) -> void:
			var m := str(marka_n)
			if wlaczony:
				if not _zakupy_filtr_marki.has(m):
					_zakupy_filtr_marki.append(m)
			else:
				_zakupy_filtr_marki.erase(m)
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		kol_marek.add_child(cb)


func _odswiez_rynek_zakupow() -> void:
	if _swiat.is_empty():
		return
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	var mid := _id_miejsca_pobytu()
	_rynek_zakupow.zapewnij_pule(_swiat, miasta, mid, int(_swiat.get("tydzien", 1)))


func _aktywuj_zakladke_samochodow() -> void:
	if _swiat.is_empty():
		return
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	_rynek_zakupow.aktywuj_zakladke_samochodow(
		_swiat, miasta, _id_miejsca_pobytu(), int(_swiat.get("tydzien", 1))
	)


func _id_miejsca_pobytu() -> String:
	var mid := str(_swiat.get("id_miejsca_pobytu", _swiat.get("id_urodzenia", "")))
	if mid == "":
		var boh := _bohater()
		if boh.get("miejsce") is Dictionary:
			mid = str(boh["miejsce"].get("id", ""))
	return mid


func _posortuj_oferty_cena(oferty: Array, tryb: String) -> Array:
	var kopia: Array = oferty.duplicate()
	kopia.sort_custom(func(a, b) -> bool:
		var ca := float(a.get("cena_zl", -1)) if a is Dictionary and _jest_liczba(a.get("cena_zl")) else -1.0
		var cb := float(b.get("cena_zl", -1)) if b is Dictionary and _jest_liczba(b.get("cena_zl")) else -1.0
		if tryb == "rosnaco":
			return ca < cb
		return ca > cb
	)
	return kopia


func _wczytaj_zakupy_oferty() -> Dictionary:
	if _zakupy_dane is Dictionary:
		return _zakupy_dane
	if not FileAccess.file_exists(PLIK_ZAKUPOW_OFERT):
		return {}
	var plik := FileAccess.open(PLIK_ZAKUPOW_OFERT, FileAccess.READ)
	if plik == null:
		return {}
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		_zakupy_dane = dane
		return dane
	return {}


func _etykieta_stanu_zakupu(id: String) -> String:
	var dane := _wczytaj_zakupy_oferty()
	if dane.get("etykiety_stanu") is Dictionary and dane["etykiety_stanu"].has(id):
		return str(dane["etykiety_stanu"][id])
	return id


func _stub_przedszkole() -> void:
	# Stub klikalny — nie pełny system.
	var chodzi := randf() < 0.55
	var tekst := "Przedszkole: chodzisz (często)." if chodzi else "Przedszkole: nie zawsze / nie chodzisz."
	if _swiat.has("przedszkole_tekst"):
		tekst = str(_swiat["przedszkole_tekst"])
	else:
		_swiat["przedszkole_tekst"] = tekst
	_tresc_biala().add_child(_napis_ekranu(tekst, 15))
	var pytania := Button.new()
	pytania.text = "Pytanie do kogoś (stub)"
	pytania.custom_minimum_size = Vector2(0, 44)
	pytania.pressed.connect(_stub_pytanie_dziecka)
	_tresc_biala().add_child(pytania)


func _efekt_fala2_tydzien() -> void:
	var bohater := _bohater()
	var ie := InteligencjaEmocjonalna.new()
	ie.reset_tydzien(bohater)
	var kor := Korepetycje.new()
	kor.reset_tydzien(bohater)
	var dep := Depresja.new()
	var dres: Dictionary = dep.tydzien(bohater)
	if bool(dres.get("zmiana", false)):
		_dopisz_komunikat_tury(str(dres.get("tekst", "")))
	var zaj := ZajeciaDodatkowe.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(bohater.get("sylwetka", {}))
	var ez: Dictionary = zaj.efekt_tygodnia(bohater, syl)
	if ez.get("teksty") is Array and not (ez["teksty"] as Array).is_empty():
		_dopisz_komunikat_tury("Zajęcia: " + ", ".join(PackedStringArray(ez["teksty"])))
	# Doprecyzowanie zainteresowań z wiekiem.
	if bohater.get("zainteresowanie") is Dictionary:
		var zan := ZainteresowaniaLos.new()
		bohater["zainteresowanie"] = zan.doprecyzuj_z_wiekiem(bohater["zainteresowanie"], int(bohater.get("wiek", 0)), _losowanie)
	var lot := SprowadzanieSamolotow.new()
	var odsm: Dictionary = lot.sprawdz_odblokowanie_smiglowcow(bohater)
	if bool(odsm.get("odblokowane", false)):
		_dopisz_komunikat_tury(str(odsm.get("tekst", "")))
	_swiat["bohater"] = bohater


func _dopisz_komunikat_tury(txt: String) -> void:
	if txt == "":
		return
	var kom := str(_swiat.get("komunikat_tury", ""))
	_swiat["komunikat_tury"] = (kom + "\n" + txt).strip_edges() if kom != "" else txt


func _pasek_sylwetki(bohater: Dictionary) -> Control:
	var blok: Variant = bohater.get("sylwetka", {})
	var syl := Sylwetka.new()
	syl.z_zapisu(blok)
	var rzad := VBoxContainer.new()
	rzad.add_theme_constant_override("separation", 2)
	var pasek := ProgressBar.new()
	pasek.min_value = 0
	pasek.max_value = syl.cap()
	pasek.value = syl.punkty
	pasek.show_percentage = false
	pasek.custom_minimum_size = Vector2(0, 18)
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(ZIELONY)
	styl.corner_radius_top_left = 4
	styl.corner_radius_top_right = 4
	styl.corner_radius_bottom_left = 4
	styl.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("fill", styl)
	rzad.add_child(pasek)
	rzad.add_child(_napis_ekranu("%d/%d" % [syl.punkty, syl.cap()], 12))
	return rzad


func _odswiez_bohatera_i_ekran(tresc: String, nazwa: String) -> void:
	_swiat["bohater"] = _bohater()
	SkryptZapisu.zapisz(_swiat)
	_zsynchronizuj_pieniadze_z_bohatera()
	_odswiez_pasek_statystyk(true)
	_otworz_akcje({"id": tresc, "nazwa": nazwa, "tryb": "ekran", "tresc": tresc})


func _ekran_korepetycje() -> void:
	var bohater := _bohater()
	_tresc_biala().add_child(_napis_ekranu("Korepetycje (propozycja kosztów). Wiedza: %d" % int(bohater.get("wiedza_pkt", 0)), 16))
	var kor := Korepetycje.new()
	for p in kor.lista():
		if not (p is Dictionary):
			continue
		var b := Button.new()
		b.text = "%s (~%s–%s zł)" % [
			str(p.get("nazwa", "")),
			str((p.get("koszt_zajecia_zl", [0, 0]) as Array)[0] if p.get("koszt_zajecia_zl") is Array else "?"),
			str((p.get("koszt_zajecia_zl", [0, 0]) as Array)[1] if p.get("koszt_zajecia_zl") is Array and (p["koszt_zajecia_zl"] as Array).size() > 1 else "?"),
		]
		b.custom_minimum_size = Vector2(0, 44)
		var id_b := str(p.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = kor.zajecie(_bohater(), id_b)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("korepetycje", "Korepetycje")
		)
		_tresc_biala().add_child(b)


func _ekran_zajecia_dodatkowe() -> void:
	var bohater := _bohater()
	var zaj := ZajeciaDodatkowe.new()
	var akt := zaj.aktywne(bohater)
	_tresc_biala().add_child(_napis_ekranu("Aktywne: %s" % (", ".join(PackedStringArray(akt)) if not akt.is_empty() else "brak"), 15))
	for z in zaj.lista(_wiek_lat()):
		if not (z is Dictionary):
			continue
		var b := Button.new()
		b.text = "Zapisz: %s" % str(z.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_z := str(z.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = zaj.zapisz_sie(_bohater(), id_z)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("zajecia_dodatkowe", "Zajęcia dodatkowe")
		)
		_tresc_biala().add_child(b)


func _ekran_szachy() -> void:
	var bohater := _bohater()
	var sz := Szachy.new()
	sz.zapewnij_ranking(bohater)
	_swiat["bohater"] = bohater
	_tresc_biala().add_child(_napis_ekranu("Ranking lokalny (nie ELO FIDE): %d" % sz.ranking(bohater), 16))
	var bt := Button.new()
	bt.text = "Trening"
	bt.custom_minimum_size = Vector2(0, 44)
	bt.pressed.connect(func() -> void:
		var w: Dictionary = sz.trening(_bohater())
		_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
		if bool(w.get("ok", false)):
			_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
	)
	_tresc_biala().add_child(bt)
	for t in sz.turnieje(_wiek_lat()):
		if not (t is Dictionary):
			continue
		var b := Button.new()
		b.text = "Turniej: %s (wpisowe %d zł)" % [str(t.get("nazwa", "")), int(t.get("wpisowe_zl", 0))]
		b.custom_minimum_size = Vector2(0, 44)
		var id_t := str(t.get("id", ""))
		b.pressed.connect(func() -> void:
			var w2: Dictionary = sz.graj_turniej(_bohater(), id_t)
			_tresc_biala().add_child(_napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
		)
		_tresc_biala().add_child(b)


func _ekran_imprezy() -> void:
	var bohater := _bohater()
	var dep := Depresja.new()
	if dep.blokada_imprez(bohater):
		_tresc_biala().add_child(_napis_ekranu("Kryzys nastroju — imprezy zablokowane (stub).", 15))
		return
	var im := ImprezyUzywki.new()
	_tresc_biala().add_child(_napis_ekranu("Imprezy / używki (stub). Wiek %d." % _wiek_lat(), 16))
	for p in im.lista_imprez(_wiek_lat()):
		if not (p is Dictionary):
			continue
		var id_p := str(p.get("id", ""))
		var b1 := Button.new()
		b1.text = "%s (bez picia)" % str(p.get("nazwa", ""))
		b1.custom_minimum_size = Vector2(0, 44)
		b1.pressed.connect(func() -> void:
			var w: Dictionary = im.idz_na_impreze(_bohater(), _swiat, id_p, false)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		_tresc_biala().add_child(b1)
		var b2 := Button.new()
		b2.text = "%s (+ picie stub)" % str(p.get("nazwa", ""))
		b2.custom_minimum_size = Vector2(0, 44)
		b2.pressed.connect(func() -> void:
			var w2: Dictionary = im.idz_na_impreze(_bohater(), _swiat, id_p, true)
			_tresc_biala().add_child(_napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		_tresc_biala().add_child(b2)


func _ekran_terapia() -> void:
	var bohater := _bohater()
	var dep := Depresja.new()
	_tresc_biala().add_child(_napis_ekranu("Nastrój / terapia (stub). Nie jest to porada medyczna.", 15))
	var st := dep.tekst_stanu(bohater)
	_tresc_biala().add_child(_napis_ekranu(st if st != "" else "Bez flagi depresji.", 15))
	var ie := InteligencjaEmocjonalna.new()
	_tresc_biala().add_child(_napis_ekranu(ie.tekst(bohater), 14))
	for tryb in ["nfz", "prywatna"]:
		var b := Button.new()
		b.text = "Terapia: %s" % tryb
		b.custom_minimum_size = Vector2(0, 44)
		var tryb_b := str(tryb)
		b.pressed.connect(func() -> void:
			var w: Dictionary = dep.terapia(_bohater(), tryb_b)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("terapia", "Terapia / nastrój")
		)
		_tresc_biala().add_child(b)


func _ekran_konserwacja_auta() -> void:
	var auto: Variant = _swiat.get("auto", null)
	if not (auto is Dictionary):
		# Szukaj w majątku.
		var maj: Dictionary = _swiat.get("majatek", {}) if _swiat.get("majatek") is Dictionary else {}
		var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
		for d in dobra:
			if d is Dictionary and str(d.get("kategoria", "")) == "samochod":
				auto = d
				break
	if not (auto is Dictionary):
		_tresc_biala().add_child(_napis_ekranu("Brak auta — kup w Zakupach, potem wróć tu.", 15))
		return
	var kon := KonserwacjaAuta.new()
	var stan_k: Dictionary = {}
	if auto.get("konserwacja") is Dictionary:
		stan_k = auto["konserwacja"]
	else:
		stan_k = kon.stan_startowy()
		auto["konserwacja"] = stan_k
	_tresc_biala().add_child(_napis_ekranu(str(auto.get("nazwa", "Auto")), 16))
	_tresc_biala().add_child(_napis_ekranu(kon.tekst_stanu(stan_k), 15))
	for czesc in ["olej", "filtry", "opony"]:
		_tresc_biala().add_child(_pasek_konserwacji(czesc, int(stan_k.get(czesc, 0))))
	var zima_btn := CheckButton.new()
	zima_btn.text = "Konserwacja zimowa"
	zima_btn.button_pressed = bool(stan_k.get("konserwacja_zima", false))
	zima_btn.toggled.connect(func(wl: bool) -> void:
		kon.ustaw_konserwacje_zimowa(stan_k, wl)
		_zapisz_konserwacje_auta(auto, stan_k)
	)
	_tresc_biala().add_child(zima_btn)
	for sposob in ["samodzielnie", "youtube", "przyjaciel_mechanik", "warsztat"]:
		for czesc2 in ["olej", "filtry", "opony"]:
			var b := Button.new()
			b.text = "%s → %s" % [czesc2, sposob]
			b.custom_minimum_size = Vector2(0, 40)
			var cz := str(czesc2)
			var sp := str(sposob)
			b.pressed.connect(func() -> void:
				var w: Dictionary = kon.serwis(stan_k, cz, sp)
				var koszt := int(w.get("koszt_zl", 0))
				if bool(w.get("ok", false)) and koszt > 0:
					var boh := _bohater()
					if int(boh.get("pieniadze", 0)) < koszt:
						_tresc_biala().add_child(_napis_ekranu("Brak kasy na serwis.", 13))
						return
					boh["pieniadze"] = int(boh["pieniadze"]) - koszt
					_swiat["bohater"] = boh
				_zapisz_konserwacje_auta(auto, stan_k)
				_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 13))
				if bool(w.get("ok", false)):
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
			)
			_tresc_biala().add_child(b)
	if bool(stan_k.get("rdza", false)) or bool(stan_k.get("zatarcie", false)):
		_tresc_biala().add_child(_napis_ekranu("Poważne: rdza/zatarcie — warsztat.", 14))
		for cz3 in ["rdza", "zatarcie"]:
			if not bool(stan_k.get(cz3, false)):
				continue
			var bw := Button.new()
			bw.text = "Napraw %s (warsztat)" % cz3
			bw.custom_minimum_size = Vector2(0, 44)
			var czb := str(cz3)
			bw.pressed.connect(func() -> void:
				var w3: Dictionary = kon.serwis(stan_k, czb, "warsztat")
				var koszt3 := int(w3.get("koszt_zl", 0))
				var boh3 := _bohater()
				if bool(w3.get("ok", false)) and int(boh3.get("pieniadze", 0)) >= koszt3:
					boh3["pieniadze"] = int(boh3["pieniadze"]) - koszt3
					_swiat["bohater"] = boh3
					_zapisz_konserwacje_auta(auto, stan_k)
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
				_tresc_biala().add_child(_napis_ekranu(str(w3.get("tekst", "")), 13))
			)
			_tresc_biala().add_child(bw)


func _pasek_konserwacji(nazwa: String, wartosc: int) -> Control:
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 8)
	rzad.add_child(_napis_ekranu(nazwa.capitalize(), 13))
	var pasek := ProgressBar.new()
	pasek.min_value = 0
	pasek.max_value = 100
	pasek.value = wartosc
	pasek.show_percentage = false
	pasek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pasek.custom_minimum_size = Vector2(80, 16)
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(ZIELONY) if wartosc > 30 else Color(KRWISTY)
	pasek.add_theme_stylebox_override("fill", styl)
	rzad.add_child(pasek)
	rzad.add_child(_napis_ekranu(str(wartosc), 12))
	return rzad


func _zapisz_konserwacje_auta(auto: Variant, stan_k: Dictionary) -> void:
	if not (auto is Dictionary):
		return
	auto["konserwacja"] = stan_k
	if _swiat.get("auto") is Dictionary:
		_swiat["auto"]["konserwacja"] = stan_k
	var maj: Variant = _swiat.get("majatek", {})
	if maj is Dictionary and maj.get("dobra") is Array:
		for i in range((maj["dobra"] as Array).size()):
			var d: Variant = maj["dobra"][i]
			if d is Dictionary and str(d.get("kategoria", "")) == "samochod":
				d["konserwacja"] = stan_k
				maj["dobra"][i] = d
				break
		_swiat["majatek"] = maj
	SkryptZapisu.zapisz(_swiat)


func _ekran_lotnictwo() -> void:
	var bohater := _bohater()
	var lot := SprowadzanieSamolotow.new()
	_tresc_biala().add_child(_napis_ekranu(lot.tekst_ui(bohater), 15))
	_tresc_biala().add_child(_napis_ekranu("Sprowadzanie samolotów — stub licencji/hangaru (katalog już jest).", 14))
	for l in lot.lista_licencji():
		if not (l is Dictionary):
			continue
		var b := Button.new()
		b.text = "Licencja: %s" % str(l.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_l := str(l.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = lot.kup_licencje(_bohater(), id_l)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
		)
		_tresc_biala().add_child(b)
	var bh := Button.new()
	bh.text = "Wynajmij hangar (miesiąc stub)"
	bh.custom_minimum_size = Vector2(0, 44)
	bh.pressed.connect(func() -> void:
		var w2: Dictionary = lot.wynajmij_hangar(_bohater())
		_tresc_biala().add_child(_napis_ekranu(str(w2.get("tekst", "")), 14))
		if bool(w2.get("ok", false)):
			_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
	)
	_tresc_biala().add_child(bh)
	var od := lot.sprawdz_odblokowanie_smiglowcow(bohater)
	_tresc_biala().add_child(_napis_ekranu(str(od.get("tekst", "")), 13))


func _ekran_eventy_przyklady() -> void:
	var ev := EventyPrzyklady.new()
	var lista := ev.lista_eventow()
	_tresc_biala().add_child(_napis_ekranu("Pakiet eventów: %d (Fala 1+2). Kliknij opcję." % lista.size(), 15))
	for e in lista:
		if not (e is Dictionary):
			continue
		_tresc_biala().add_child(_napis_ekranu("%s — %s" % [str(e.get("nazwa", "")), str(e.get("opis", ""))], 14))
		if e.get("opcje") is Array:
			for o in e["opcje"]:
				if not (o is Dictionary):
					continue
				var b := Button.new()
				b.text = str(o.get("tekst", o.get("id", "")))
				b.custom_minimum_size = Vector2(0, 36)
				var eid := str(e.get("id", ""))
				var oid := str(o.get("id", ""))
				b.pressed.connect(func() -> void:
					var w: Dictionary = ev.zastosuj_opcje(_bohater(), eid, oid)
					_swiat["bohater"] = _bohater()
					SkryptZapisu.zapisz(_swiat)
					_odswiez_pasek_statystyk(true)
					_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 13))
				)
				_tresc_biala().add_child(b)


func _ekran_praca_fala2() -> void:
	var txt := _tekst_pracy()
	if txt != "":
		_tresc_biala().add_child(_napis_ekranu("Praca rodziców: %s" % txt, 15))
	else:
		_tresc_biala().add_child(_napis_ekranu("Praca rodziców: —", 15))
	_tresc_biala().add_child(_napis_ekranu("Twoje fuchy (szkielet Fali 1+2):", 16))
	var praca := PracaSzkielet.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(_bohater().get("sylwetka", {}))
	for p in praca.prace_dla_wieku(_wiek_lat()):
		if not (p is Dictionary):
			continue
		var b := Button.new()
		b.text = str(p.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_p := str(p.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = praca.wykonaj_fuche(_bohater(), id_p, syl)
			if bool(w.get("ok", false)):
				_dodaj_pieniadze(int(w.get("placa", 0)))
				_dodaj_wplyw("fucha", int(w.get("placa", 0)), str(w.get("tekst", "")))
				_swiat["bohater"] = _bohater()
				SkryptZapisu.zapisz(_swiat)
				_odswiez_pasek_statystyk(true)
			_tresc_biala().add_child(_napis_ekranu(str(w.get("tekst", "")), 14))
		)
		_tresc_biala().add_child(b)


func _stub_pytanie_dziecka() -> void:
	var temat := "dlaczego niebo jest niebieskie"
	var rozmowca := "matka"
	if FileAccess.file_exists("res://postacie/tematy_pytan.json"):
		var plik := FileAccess.open("res://postacie/tematy_pytan.json", FileAccess.READ)
		if plik != null:
			var dane: Variant = JSON.parse_string(plik.get_as_text())
			var tematy: Variant = null
			if dane is Dictionary:
				if dane.get("tematy_bazowe") is Array:
					tematy = dane["tematy_bazowe"]
				elif dane.get("tematy") is Array:
					tematy = dane["tematy"]
			elif dane is Array:
				tematy = dane
			if tematy is Array and not tematy.is_empty():
				var t0: Variant = tematy[0]
				if t0 is Dictionary:
					temat = str(t0.get("nazwa", t0.get("id", temat)))
				elif t0 is String:
					temat = str(t0)
	_wyczysc(_tresc_biala())
	_tytul_bialy().text = "Pytanie"
	_tresc_biala().add_child(_napis_ekranu("Temat: %s" % temat, 16))
	_tresc_biala().add_child(_napis_ekranu("Rozmówca: %s (wybór stub)" % rozmowca, 15))
	for kto in ["matka", "ojciec"]:
		var b := Button.new()
		b.text = "Zapytaj: %s" % kto
		b.custom_minimum_size = Vector2(0, 44)
		var kto_bind: String = str(kto)
		b.pressed.connect(func() -> void:
			_tresc_biala().add_child(_napis_ekranu("(%s) Odpowiedź stub — pełny system później." % kto_bind, 14))
		)
		_tresc_biala().add_child(b)


func _ekran_ustawienia_w_bialym() -> void:
	_tresc_biala().add_child(_napis_ekranu("Otwiera panel wyglądu (przejrzystość, kolory). Podział poziomy 8:5 usunięty.", 15))
	var przycisk := Button.new()
	przycisk.text = "Otwórz ustawienia wyglądu"
	przycisk.custom_minimum_size = Vector2(0, 48)
	przycisk.pressed.connect(_on_ustawienia_pressed)
	_tresc_biala().add_child(przycisk)


func _ekran_jedzenie_dom(kolor: Color) -> void:
	_zdanie = _napis_ekranu("", 18)
	_zdanie.add_theme_color_override("font_color", Color(KRWISTY))
	_tresc_biala().add_child(_zdanie)
	_wplyw_domu = _rich_ekran()
	_tresc_biala().add_child(_wplyw_domu)
	_tresc_biala().add_child(_ramka_suwaka("Cena", kolor, _suwak_jedzenia("cena")))
	_tresc_biala().add_child(_ramka_suwaka("Składniki odżywcze", kolor, _suwak_jedzenia("skladniki")))
	_tresc_biala().add_child(_ramka_suwaka("Dieta ogólna", kolor, _suwak_jedzenia("dieta_ogolna")))
	var diety := VBoxContainer.new()
	diety.add_theme_constant_override("separation", 4)
	var wege := CheckButton.new()
	wege.text = "Wegetariańska"
	wege.button_pressed = bool(_jedzenie.stan_roboczy().get("wegetarianska", false))
	wege.toggled.connect(func(wlaczona: bool) -> void:
		_jedzenie.ustaw_diete("wegetarianska", wlaczona)
		_odswiez_napisy_domu()
	)
	var weganska := CheckButton.new()
	weganska.text = "Wegańska"
	weganska.button_pressed = bool(_jedzenie.stan_roboczy().get("weganska", false))
	weganska.toggled.connect(func(wlaczona: bool) -> void:
		_jedzenie.ustaw_diete("weganska", wlaczona)
		_odswiez_napisy_domu()
	)
	diety.add_child(wege)
	diety.add_child(weganska)
	_tresc_biala().add_child(_ramka_z_dolnym("Dieta", kolor, diety, null))
	_tresc_biala().add_child(_ramka_suwaka("Dieta gotowania własnego", kolor, _suwak_jedzenia("dieta_wlasna")))
	_efekt_dni = _rich_ekran()
	var dni_srodek := VBoxContainer.new()
	dni_srodek.add_child(_efekt_dni)
	var dni := _kropki_dni(_jedzenie.dni_gotowania(), _ustaw_dni_gotowania_z_ekranu)
	_tresc_biala().add_child(_ramka_z_dolnym("Ile dni w tygodniu gotujesz", kolor, dni_srodek, dni))
	for pozycja in _jedzenie.pozycje_gdzie("dom"):
		if pozycja is Dictionary:
			_tresc_biala().add_child(_wiersz_pozycji(pozycja, false))
	var zatwierdz := Button.new()
	zatwierdz.text = "Zatwierdź"
	zatwierdz.custom_minimum_size = Vector2(0, 48)
	zatwierdz.pressed.connect(func() -> void:
		_jedzenie.zatwierdz()
		_odswiez_napisy_domu()
		_odswiez_pasek_statystyk(true)
	)
	_tresc_biala().add_child(zatwierdz)
	_odswiez_napisy_domu()


func _ekran_jedzenie_sam(_kolor: Color) -> void:
	_odswiez_flage_jedzenia_sam()
	if not bool(_swiat.get("odblokowane_jedzenie_samemu", false)):
		var tekst_blok := "Jeszcze nie jesz samemu poza domem."
		var cfg: Variant = _jedzenie_odblok_cfg()
		if cfg is Dictionary and str(cfg.get("tekst_zablokowane", "")) != "":
			tekst_blok = str(cfg["tekst_zablokowane"])
		var prog_txt := ""
		if cfg is Dictionary and _jest_liczba(cfg.get("prog_wiek_lat")):
			prog_txt = " (próg wieku: %d lat — propozycja do poprawki)" % int(cfg["prog_wiek_lat"])
		_tresc_biala().add_child(_napis_ekranu(tekst_blok + prog_txt, 16))
		return
	_tresc_biala().add_child(_napis_ekranu("Jakość zdrowotna poza domem (osobno od smaku/ceny; propozycja, nie medyczne %).", 13))
	var jak_cfg: Variant = null
	var dane_j: Variant = _jedzenie.wczytaj()
	if dane_j is Dictionary:
		jak_cfg = dane_j.get("jakosc_zdrowotna_poza_domem", {})
	var j_min := 0
	var j_max := 100
	var j_krok := 5
	if jak_cfg is Dictionary:
		if _jest_liczba(jak_cfg.get("min")):
			j_min = int(jak_cfg["min"])
		if _jest_liczba(jak_cfg.get("max")):
			j_max = int(jak_cfg["max"])
		if _jest_liczba(jak_cfg.get("krok")):
			j_krok = int(jak_cfg["krok"])
	var j_wart := int(_swiat.get("jakosc_zdrowotna_poza_domem", 50))
	var j_opis := _napis_ekranu("Jakość zdrowotna: %d" % j_wart, 15)
	_tresc_biala().add_child(j_opis)
	var j_suwak := HSlider.new()
	j_suwak.min_value = float(j_min)
	j_suwak.max_value = float(j_max)
	j_suwak.step = float(j_krok)
	j_suwak.value = float(clampi(j_wart, j_min, j_max))
	j_suwak.custom_minimum_size = Vector2(0, 36)
	j_suwak.value_changed.connect(func(v: float) -> void:
		_swiat["jakosc_zdrowotna_poza_domem"] = int(v)
		j_opis.text = "Jakość zdrowotna: %d" % int(v)
	)
	_tresc_biala().add_child(j_suwak)
	var komunikat := _napis_ekranu("", 16)
	_tresc_biala().add_child(komunikat)
	var ceny: Array = []
	for pozycja in _jedzenie.pozycje_gdzie("sam"):
		if not (pozycja is Dictionary):
			continue
		if _jest_liczba(pozycja.get("cena_zl")):
			ceny.append(float(pozycja["cena_zl"]))
		_tresc_biala().add_child(_wiersz_pozycji(pozycja, true, komunikat))
	_dol_suwaka().show()
	if ceny.is_empty():
		_filtr_aktywny = false
		_dol_suwaka().add_child(_z_marginesem(_napis_ekranu("—", 20)))
		return
	ceny.sort()
	var suwak = SkryptZakresu.new()
	suwak.ustaw_zakres(float(ceny[0]), float(ceny[ceny.size() - 1]))
	_filtr_aktywny = true
	_filtr_od = suwak.od
	_filtr_do = suwak.dokad
	suwak.zakres_zmieniony.connect(_on_filtr_ceny)
	_dol_suwaka().add_child(_z_marginesem(suwak))
	_zastosuj_filtr()


func _ekran_transport(_kolor: Color) -> void:
	var auto: Variant = _auto_z_zapisu()
	if auto == null:
		_tresc_biala().add_child(_napis_ekranu("Auta nie ma.", 20))
	else:
		var opis := _opis_auta(auto)
		if opis != "":
			_tresc_biala().add_child(_napis_ekranu(opis, 18))
		_dol_suwaka().show()
		_dol_suwaka().add_child(_z_marginesem(_kropki_dni(int(_swiat.get("dni_auta", 0)), _ustaw_dni_auta)))
		_dol_suwaka().add_child(_z_marginesem(_napis_ekranu("Cena na tydzień: %s" % _cena_tygodnia_auta(auto), 16)))
	var mapa := Button.new()
	mapa.text = "Mapa"
	mapa.custom_minimum_size = Vector2(0, 44)
	mapa.pressed.connect(func() -> void:
		_otworz_akcje({"id": "mapa", "nazwa": "Mapa", "tryb": "ekran", "tresc": "mapa", "kolor": "#8aa0a8"})
	)
	_tresc_biala().add_child(mapa)


func _ekran_mapa() -> void:
	_tresc_biala().add_child(_napis_ekranu(
		"Mapa uproszczona: miasta i drogi między nimi (sąsiedztwo). Bez GIS / bez ulic.",
		16
	))
	if _mapa_ikona == null and ResourceLoader.exists(IKONA_MIASTA):
		_mapa_ikona = load(IKONA_MIASTA) as Texture2D
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	var ziarno := int(_swiat.get("rynek_zakupow", {}).get("ziarno", 1)) if _swiat.get("rynek_zakupow") is Dictionary else 1
	if ziarno == 0:
		ziarno = int(_swiat.get("tydzien", 1)) * 9973 + 1
	_mapa_graf = _mapa_miast.zbuduj(miasta, ziarno, _id_miejsca_pobytu())
	var obszar := Control.new()
	obszar.custom_minimum_size = Vector2(0, 420)
	obszar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obszar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	obszar.clip_contents = true
	_mapa_warstwa = obszar
	_tresc_biala().add_child(obszar)
	_mapa_pasek = _napis_ekranu("Kliknij miasto — kto tam mieszka (bez znajomych).", 16)
	_mapa_pasek.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tresc_biala().add_child(_mapa_pasek)
	_opcje_transportu = VBoxContainer.new()
	_opcje_transportu.add_theme_constant_override("separation", 8)
	_tresc_biala().add_child(_opcje_transportu)
	obszar.resized.connect(_przerysuj_mape_miast)
	obszar.draw.connect(_rysuj_krawedzie_mapy)
	call_deferred("_przerysuj_mape_miast")


func _przerysuj_mape_miast() -> void:
	if _mapa_warstwa == null or not is_instance_valid(_mapa_warstwa):
		return
	for d in _mapa_warstwa.get_children():
		_mapa_warstwa.remove_child(d)
		d.queue_free()
	var wierz: Array = _mapa_graf.get("wierzcholki", []) if _mapa_graf is Dictionary else []
	if wierz.is_empty():
		return
	var min_x := 1e9
	var max_x := -1e9
	var min_y := 1e9
	var max_y := -1e9
	for w in wierz:
		if not (w is Dictionary):
			continue
		min_x = minf(min_x, float(w.get("x", 0)))
		max_x = maxf(max_x, float(w.get("x", 0)))
		min_y = minf(min_y, float(w.get("y", 0)))
		max_y = maxf(max_y, float(w.get("y", 0)))
	var marg := 36.0
	var szer := maxf(1.0, _mapa_warstwa.size.x - marg * 2.0)
	var wys := maxf(1.0, _mapa_warstwa.size.y - marg * 2.0)
	var dx := maxf(1.0, max_x - min_x)
	var dy := maxf(1.0, max_y - min_y)
	for w in wierz:
		if not (w is Dictionary):
			continue
		var nx := marg + (float(w.get("x", 0)) - min_x) / dx * szer
		var ny := marg + (float(w.get("y", 0)) - min_y) / dy * wys
		w["_sx"] = nx
		w["_sy"] = ny
		var kolumna := VBoxContainer.new()
		kolumna.position = Vector2(nx - 28, ny - 40)
		kolumna.custom_minimum_size = Vector2(56, 70)
		kolumna.alignment = BoxContainer.ALIGNMENT_CENTER
		var nazwa := Label.new()
		nazwa.text = str(w.get("nazwa", "?"))
		nazwa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nazwa.add_theme_font_size_override("font_size", 16)
		nazwa.add_theme_color_override("font_color", TEKST_CIEMNY)
		nazwa.autowrap_mode = TextServer.AUTOWRAP_OFF
		nazwa.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nazwa.custom_minimum_size = Vector2(56, 0)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.focus_mode = Control.FOCUS_NONE
		btn.flat = true
		if _mapa_ikona != null:
			btn.icon = _mapa_ikona
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 36)
		else:
			btn.text = "●"
		var id_m := str(w.get("id", ""))
		var naz_m := str(w.get("nazwa", "?"))
		btn.pressed.connect(_on_klik_miasta_mapy.bind(id_m, naz_m))
		kolumna.add_child(nazwa)
		kolumna.add_child(btn)
		_mapa_warstwa.add_child(kolumna)
	_mapa_warstwa.queue_redraw()


func _rysuj_krawedzie_mapy() -> void:
	if _mapa_warstwa == null or not is_instance_valid(_mapa_warstwa):
		return
	var po: Dictionary = {}
	for w in _mapa_graf.get("wierzcholki", []):
		if w is Dictionary and w.has("_sx"):
			po[str(w.get("id", ""))] = Vector2(float(w["_sx"]), float(w["_sy"]))
	for k in _mapa_graf.get("krawedzie", []):
		if not (k is Dictionary):
			continue
		var a := str(k.get("a", ""))
		var b := str(k.get("b", ""))
		if not po.has(a) or not po.has(b):
			continue
		_mapa_warstwa.draw_line(po[a], po[b], Color(0.45, 0.52, 0.58, 0.7), 2.0, true)


func _on_klik_miasta_mapy(id: String, nazwa: String) -> void:
	_swiat["mapa_miasto_id"] = id
	_swiat["mapa_miasto_nazwa"] = nazwa
	var kto: Dictionary = _mapa_miast.mieszkancy_miasta(_swiat, id)
	var czesci: PackedStringArray = []
	var rodzice_l: Array = kto.get("rodzice", []) if kto.get("rodzice") is Array else []
	var dziad_l: Array = kto.get("dziadkowie", []) if kto.get("dziadkowie") is Array else []
	var przyj_l: Array = kto.get("przyjaciele", []) if kto.get("przyjaciele") is Array else []
	if not rodzice_l.is_empty():
		czesci.append("Rodzice: %s" % _join_tekstow(rodzice_l))
	if not dziad_l.is_empty():
		czesci.append("Dziadkowie: %s" % _join_tekstow(dziad_l))
	if not przyj_l.is_empty():
		czesci.append("Przyjaciele: %s" % _join_tekstow(przyj_l))
	if _mapa_pasek != null and is_instance_valid(_mapa_pasek):
		if czesci.is_empty():
			_mapa_pasek.text = "%s — nikt z rodziny/przyjaciół tu nie mieszka." % nazwa
		else:
			_mapa_pasek.text = "%s — %s" % [nazwa, " · ".join(czesci)]
	_wypelnij_opcje_transportu(id, nazwa)


func _odswiez_liste_miast(_tekst: String) -> void:
	pass


func _on_miasto_mapy(_indeks: int) -> void:
	pass


func _wypelnij_opcje_transportu(id: String, nazwa: String) -> void:
	if _opcje_transportu == null or not is_instance_valid(_opcje_transportu):
		return
	_wyczysc(_opcje_transportu)
	_opcje_transportu.add_child(_napis_ekranu(nazwa, 18))
	var skad := _id_miejsca_pobytu()
	var dyst: Variant = _mapa_miast.dystans_km(_mapa_graf, skad, id)
	var dyst_txt := "—"
	if _jest_liczba(dyst):
		dyst_txt = "%.0f km (propozycja)" % float(dyst)
	_opcje_transportu.add_child(_napis_ekranu("Dystans: %s" % dyst_txt, 14))
	var cena_publiczna: Variant = _cena_transportu_miasta(id)
	var cena_txt := "—"
	var pieniadze := "—"
	if _jest_liczba(cena_publiczna):
		cena_txt = str(cena_publiczna)
		pieniadze = "w dół"
	_opcje_transportu.add_child(_blok_drogi("Pieszo", "w górę", "—", "—", []))
	_opcje_transportu.add_child(_blok_drogi("Transport publiczny", "w górę", pieniadze, cena_txt, []))
	var auto: Variant = _auto_z_zapisu()
	if auto != null and _jest_liczba(dyst):
		_opcje_transportu.add_child(_panel_przejazdu_autem(auto, float(dyst), nazwa))
	elif auto != null:
		_opcje_transportu.add_child(_napis_ekranu("Auto: brak dystansu do wyliczenia.", 14))


func _blok_drogi(nazwa: String, zmeczenie: String, pieniadze: String, cena: String, klasy: Array) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 2)
	kolumna.add_child(_napis_ekranu(nazwa, 18))
	kolumna.add_child(_napis_ekranu("Zmęczenie: %s" % zmeczenie, 16))
	kolumna.add_child(_napis_ekranu("Pieniądze: %s" % pieniadze, 16))
	kolumna.add_child(_napis_ekranu("Cena: %s" % cena, 16))
	if not klasy.is_empty():
		kolumna.add_child(_napis_ekranu("Klasa", 16))
		for klasa in klasy:
			var przycisk := Button.new()
			przycisk.text = str(klasa.get("nazwa", ""))
			przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
			przycisk.custom_minimum_size = Vector2(0, 44)
			przycisk.pressed.connect(_wybierz_klase.bind(str(klasa.get("id", ""))))
			kolumna.add_child(przycisk)
	return kolumna


func _panel_przejazdu_autem(auto: Dictionary, dystans_km: float, cel_nazwa: String) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 6)
	kolumna.add_child(_napis_ekranu("Auto → %s" % cel_nazwa, 18))
	var vmax_v: Variant = _przejazd.predkosc_max_auta(auto)
	if vmax_v == null:
		kolumna.add_child(_napis_ekranu("Vmax: brak danych / auto nie jeździ.", 13))
		return kolumna
	var vmax := int(vmax_v)
	var vmax_txt := _rynek_zakupow.tekst_vmax_oferty(
		auto,
		auto.get("usterki_rzeczywiste", []) if auto.get("usterki_rzeczywiste") is Array else []
	)
	if vmax_txt == "":
		vmax_txt = str(vmax)
	kolumna.add_child(_napis_ekranu("Vmax pojazdu: %s km/h" % vmax_txt, 13))
	var tryb_stan := {"id": SkryptPrzejazdu.TRYB_DOZWOLONA, "nadmiar": 0.0}
	var opis := _napis_ekranu("", 14)
	var suwak_box := VBoxContainer.new()
	suwak_box.visible = false
	var nad_opis := _napis_ekranu("Ponad dozwolone: 0 km/h", 13)
	var suwak := HSlider.new()
	suwak.min_value = 0
	suwak.max_value = maxf(0.0, float(vmax) - float(SkryptPrzejazdu.LIMIT_DOZWOLONY_KM_H))
	suwak.step = 1
	suwak.value = 0
	suwak.custom_minimum_size = Vector2(0, 32)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var odswiez := func() -> void:
		var wynik: Dictionary = _przejazd.oblicz(
			dystans_km, auto, str(tryb_stan["id"]), float(tryb_stan["nadmiar"]), _cena_paliwa()
		)
		var linie := "Koszt paliwa: %s · spalanie trybu: %s l/100 · zmęczenie fiz. +%d" % [
			str(wynik.get("koszt_tekst", "—")),
			str(wynik.get("zuzycie_l_na_100", "—")),
			int(wynik.get("zmeczenie_fizyczne_delta", 0)),
		]
		var mandat := str(wynik.get("mandat_stub", "")).strip_edges()
		if mandat != "":
			linie += "\n" + mandat
		opis.text = linie
	suwak.value_changed.connect(func(v: float) -> void:
		tryb_stan["nadmiar"] = v
		nad_opis.text = "Ponad dozwolone: %d km/h" % int(v)
		odswiez.call()
	)
	suwak_box.add_child(nad_opis)
	suwak_box.add_child(suwak)
	for pozycja in [
		[SkryptPrzejazdu.TRYB_EKONOMICZNY, "Ekonomiczna"],
		[SkryptPrzejazdu.TRYB_DOZWOLONA, "Maksymalna dozwolona"],
		[SkryptPrzejazdu.TRYB_PRZEKROCZONA, "Przekroczona"],
	]:
		var b := Button.new()
		b.text = str(pozycja[1])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(func() -> void:
			tryb_stan["id"] = str(pozycja[0])
			suwak_box.visible = (str(pozycja[0]) == SkryptPrzejazdu.TRYB_PRZEKROCZONA)
			if not suwak_box.visible:
				tryb_stan["nadmiar"] = 0.0
				suwak.value = 0
			odswiez.call()
		)
		kolumna.add_child(b)
	kolumna.add_child(suwak_box)
	kolumna.add_child(opis)
	odswiez.call()
	return kolumna


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
	var cena := _napis_ekranu(_tekst_ceny(pozycja.get("cena_zl")), 16)
	var jakosc_txt := ""
	if _jest_liczba(pozycja.get("jakosc_propozycja")):
		jakosc_txt = "Jakość (propozycja): %d" % int(pozycja["jakosc_propozycja"])
	elif not sam:
		jakosc_txt = "Jakość: —"
	var jakosc_lbl := _napis_ekranu(jakosc_txt, 13) if jakosc_txt != "" else null
	var ster := HBoxContainer.new()
	ster.add_theme_constant_override("separation", 6)
	var licznik := _napis_ekranu(str(_jedzenie.ilosc_pozycji(id)), 20)
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
	var efekty := _rich_ekran()
	efekty.text = _jedzenie.bb_pozycji(id)
	prawa.add_child(nazwa)
	prawa.add_child(cena)
	if jakosc_lbl != null:
		prawa.add_child(jakosc_lbl)
	prawa.add_child(ster)
	prawa.add_child(efekty)
	var rodzice := _napis_ekranu("", 15)
	if not sam:
		var stan := _jedzenie.tekst_rodzicow_przy(id)
		rodzice.text = stan
		rodzice.visible = stan != ""
		prawa.add_child(rodzice)
		_efekty_domu.append({"id": id, "rich": efekty, "rodzice": rodzice})
	if sam:
		_wiersze_sam.append({"cena": pozycja.get("cena_zl", null), "wezel": prawa})
	return prawa


func _on_filtr_ceny(od: float, dokad: float) -> void:
	_filtr_aktywny = true
	_filtr_od = od
	_filtr_do = dokad
	_zastosuj_filtr()


func _zastosuj_filtr() -> void:
	for wpis in _wiersze_sam:
		if not (wpis is Dictionary):
			continue
		var wezel: Variant = wpis.get("wezel")
		if not (wezel is CanvasItem) or not is_instance_valid(wezel):
			continue
		var pokaz := true
		if _filtr_aktywny and _jest_liczba(wpis.get("cena")):
			var cena := float(wpis["cena"])
			pokaz = cena >= _filtr_od - 0.001 and cena <= _filtr_do + 0.001
		wezel.visible = pokaz


func _suwak_jedzenia(id: String) -> HSlider:
	var zakres := _jedzenie.zakres_suwaka(id if id != "dieta_ogolna" and id != "dieta_wlasna" else "cena")
	if id == "dieta_ogolna" or id == "dieta_wlasna":
		zakres = {"min": 0, "max": 100}
	var suwak := HSlider.new()
	suwak.min_value = float(zakres.get("min", 0))
	suwak.max_value = float(zakres.get("max", 100))
	suwak.step = 1.0
	suwak.custom_minimum_size = Vector2(0, 36)
	var stan := _jedzenie.stan_roboczy()
	var pole := id
	var flaga := id + "_ustawiona"
	if id == "skladniki":
		pole = "skladniki"
		flaga = "skladniki_ustawione"
	if bool(stan.get(flaga, false)) and _jest_liczba(stan.get(pole)):
		suwak.set_value_no_signal(float(stan[pole]))
	else:
		suwak.set_value_no_signal(suwak.min_value)
	suwak.value_changed.connect(func(wartosc: float) -> void:
		if id == "dieta_ogolna" or id == "dieta_wlasna":
			_jedzenie.ustaw_diete_suwak(id, int(wartosc))
		else:
			_jedzenie.ustaw_suwak(id, int(wartosc))
		_odswiez_napisy_domu()
	)
	return suwak


func _ustaw_dni_gotowania_z_ekranu(dzien: int) -> void:
	_jedzenie.ustaw_dni_gotowania(dzien)
	_zaplanuj_stos()


func _ustaw_dni_auta(dzien: int) -> void:
	_swiat["dni_auta"] = clampi(dzien, 0, 7)
	_zaplanuj_stos()


func _odswiez_napisy_domu() -> void:
	if _zdanie != null and is_instance_valid(_zdanie):
		var tekst := _jedzenie.zdanie_domu()
		_zdanie.text = tekst
		_zdanie.visible = tekst != ""
	if _wplyw_domu != null and is_instance_valid(_wplyw_domu):
		var bb := _jedzenie.bb_znakow(_jedzenie.zbiorcze())
		_wplyw_domu.text = bb
		_wplyw_domu.visible = bb != ""
	if _efekt_dni != null and is_instance_valid(_efekt_dni):
		_efekt_dni.text = _jedzenie.efekt_gotowania_tekst()
		_efekt_dni.visible = _efekt_dni.text != ""
	for wpis in _efekty_domu:
		if not (wpis is Dictionary):
			continue
		var efekty: Variant = wpis.get("rich")
		if efekty is RichTextLabel and is_instance_valid(efekty):
			efekty.text = _jedzenie.bb_pozycji(str(wpis.get("id", "")))
		var rodzice: Variant = wpis.get("rodzice")
		if rodzice is Label and is_instance_valid(rodzice):
			var stan := _jedzenie.tekst_rodzicow_przy(str(wpis.get("id", "")))
			rodzice.text = stan
			rodzice.visible = stan != ""


func _wybierz_klase(id: String) -> void:
	_swiat["klasa_transportu"] = id


func _zjedz_pozycje(id: String, komunikat: Variant) -> void:
	var wynik := _jedzenie.zjedz(id)
	if komunikat != null and is_instance_valid(komunikat):
		komunikat.text = str(wynik.get("komunikat", ""))
	_odswiez_pasek_statystyk(true)
	_odswiez_napisy_domu()


func _zmien_ilosc(id: String, delta: int, licznik: Label) -> void:
	_jedzenie.ustaw_ilosc_pozycji(id, _jedzenie.ilosc_pozycji(id) + delta)
	if licznik != null and is_instance_valid(licznik):
		licznik.text = str(_jedzenie.ilosc_pozycji(id))


func _kropki_dni(wybrane: int, cel: Callable) -> Control:
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 2)
	for dzien in 8:
		var kolumna := VBoxContainer.new()
		kolumna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kolumna.add_theme_constant_override("separation", 0)
		var liczba := Button.new()
		liczba.text = str(dzien)
		liczba.flat = true
		liczba.focus_mode = Control.FOCUS_NONE
		liczba.custom_minimum_size = Vector2(0, 48)
		liczba.add_theme_color_override("font_color", TEKST_CIEMNY)
		liczba.pressed.connect(cel.bind(dzien))
		var kropka := TextureRect.new()
		kropka.custom_minimum_size = Vector2(0, 22)
		kropka.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		kropka.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		kropka.texture = _kropka_duza if dzien == wybrane else _kropka_mala
		kropka.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		kropka.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kolumna.add_child(liczba)
		kolumna.add_child(kropka)
		rzad.add_child(kolumna)
	return rzad


func _ramka_suwaka(tytul: String, kolor: Color, suwak: Control) -> Control:
	var margines := MarginContainer.new()
	margines.add_theme_constant_override("margin_left", 10)
	margines.add_theme_constant_override("margin_right", 10)
	margines.add_theme_constant_override("margin_top", 8)
	margines.add_theme_constant_override("margin_bottom", 8)
	margines.add_child(suwak)
	return _ramka_z_dolnym(tytul, kolor, null, margines)


func _ramka_z_dolnym(tytul: String, kolor: Color, srodek: Control, dol: Control) -> Control:
	var panel := PanelContainer.new()
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(0.93, 0.94, 0.95, 1)
	styl.content_margin_left = 0
	styl.content_margin_right = 0
	styl.content_margin_top = 0
	styl.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", styl)
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 8)
	var pasek := ColorRect.new()
	pasek.color = kolor
	pasek.custom_minimum_size = Vector2(0, 36)
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var napis := Label.new()
	napis.text = tytul
	napis.set_anchors_preset(Control.PRESET_FULL_RECT)
	napis.offset_left = 12.0
	napis.offset_right = -12.0
	napis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	napis.add_theme_font_size_override("font_size", 16)
	napis.add_theme_color_override("font_color", _kolor_napisu_na(kolor))
	napis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pasek.add_child(napis)
	kolumna.add_child(pasek)
	if srodek != null:
		var wciecie := MarginContainer.new()
		wciecie.add_theme_constant_override("margin_left", 10)
		wciecie.add_theme_constant_override("margin_right", 10)
		wciecie.add_child(srodek)
		kolumna.add_child(wciecie)
	if dol != null:
		kolumna.add_child(dol)
	panel.add_child(kolumna)
	return panel


func _zbuduj_pasek_statystyk() -> void:
	var glowny: HBoxContainer = get_node(KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/PasekGlowny")
	_rozwiniete_stat = get_node(KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/PasekRozwiniety")
	_wyczysc(glowny)
	_wyczysc(_rozwiniete_stat)
	_styl_panelu_paska()
	_rok_lbl = _napis_paska("Rok 1", 14)
	_tydzien_lbl = _napis_paska("T0", 14)
	glowny.add_child(_rok_lbl)
	glowny.add_child(_tydzien_lbl)
	var zmeczenie := _blok_metryki("zmeczenie_fizyczne")
	_zmeczenie_emoji = zmeczenie["emoji"]
	_zmeczenie_pasek = zmeczenie["pasek"]
	_zmeczenie_liczba = zmeczenie["liczba"]
	glowny.add_child(zmeczenie["wezel"])
	var zmeczenie_p := _blok_metryki("zmeczenie_psychiczne")
	_zmeczenie_psych_emoji = zmeczenie_p["emoji"]
	_zmeczenie_psych_pasek = zmeczenie_p["pasek"]
	_zmeczenie_psych_liczba = zmeczenie_p["liczba"]
	glowny.add_child(zmeczenie_p["wezel"])
	var psychika := _blok_metryki("psychika")
	_psychika_emoji = psychika["emoji"]
	_psychika_pasek = psychika["pasek"]
	_psychika_liczba = psychika["liczba"]
	glowny.add_child(psychika["wezel"])
	var pieniadze := HBoxContainer.new()
	pieniadze.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pieniadze.add_theme_constant_override("separation", 4)
	_pieniadze_emoji = _napis_paska("👛", 20)
	_pieniadze_lbl = _napis_paska("—", 16)
	_pieniadze_lbl.add_theme_color_override("font_color", Color(ZIELONY))
	pieniadze.add_child(_pieniadze_emoji)
	pieniadze.add_child(_pieniadze_lbl)
	glowny.add_child(pieniadze)
	var wnetrze: VBoxContainer = get_node(KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze")
	_komunikat_tury_lbl = get_node_or_null(KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/KomunikatTury") as Label
	if _komunikat_tury_lbl == null:
		_komunikat_tury_lbl = Label.new()
		_komunikat_tury_lbl.name = "KomunikatTury"
		_komunikat_tury_lbl.visible = false
		_komunikat_tury_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_komunikat_tury_lbl.add_theme_font_size_override("font_size", 13)
		_komunikat_tury_lbl.add_theme_color_override("font_color", Color(ZIELONY))
		# Pod głównym rzędem paska, nad rozwinięciem.
		wnetrze.add_child(_komunikat_tury_lbl)
		wnetrze.move_child(_komunikat_tury_lbl, 1)


## Treść tury idzie na biały obszar — zielonego paska u góry nie pokazujemy.
func _ukryj_zielony_komunikat_tury() -> void:
	if _komunikat_tury_lbl == null:
		return
	_komunikat_tury_lbl.text = ""
	_komunikat_tury_lbl.visible = false


func _pokaz_komunikat_tury_ui() -> void:
	# Zachowane API: dawniej zielony pasek; teraz tylko ukrycie (treść w białym).
	_ukryj_zielony_komunikat_tury()


func _losuj_eventy_tury() -> void:
	var kontekst := _kontekst_eventow()
	var wylosowane: Array = _eventy.losuj_ture(kontekst, _losowanie)
	var karty_pytan: Array = []
	for ev in wylosowane:
		if not (ev is Dictionary):
			continue
		if bool(ev.get("pytanie", false)):
			karty_pytan.append(ev)
			continue
		var wynik: Dictionary = _eventy.zastosuj_bez_pytania(ev)
		_zastosuj_wynik_eventu(wynik)
		var t := str(wynik.get("tekst", ev.get("tekst", "")))
		if t != "":
			var kom := str(_swiat.get("komunikat_tury", "")).strip_edges()
			_swiat["komunikat_tury"] = t if kom == "" else kom + "\n" + t
	_swiat["eventy_tury"] = karty_pytan


func _kontekst_eventow() -> Dictionary:
	var flagi: Dictionary = {}
	if _swiat.get("flagi_odkrycia") is Dictionary:
		flagi = (_swiat["flagi_odkrycia"] as Dictionary).duplicate(true)
	var rodzenstwo: Variant = _swiat.get("rodzenstwo", [])
	var jedynak := true
	if rodzenstwo is Array and not rodzenstwo.is_empty():
		jedynak = false
	var rodzina: Variant = _swiat.get("rodzina", {})
	var cechy: Array = []
	var przedzial := ""
	if rodzina is Dictionary:
		if rodzina.get("charakter") is Array:
			for c in rodzina["charakter"]:
				if c is Dictionary and str(c.get("id", "")) != "":
					cechy.append(str(c["id"]))
				elif c is String:
					cechy.append(c)
		if rodzina.get("zarobki") is Dictionary:
			przedzial = str(rodzina["zarobki"].get("przedzial_id", ""))
	var bohater := _bohater()
	var pieniadze_ok := _jest_liczba(bohater.get("pieniadze")) and int(bohater["pieniadze"]) > 0
	var ma := {
		"telefon": bool(flagi.get("ma_telefon", false)) or bool(flagi.get("wie_o_telefonie", false)),
		"portfel": bool(flagi.get("ma_portfel", false)),
		"pieniadze": pieniadze_ok,
	}
	# Zgubienie ważnego: jeśli ma pieniądze, wystarczy.
	if pieniadze_ok:
		ma["pieniadze"] = true
	return {
		"wiek": _wiek_lat(),
		"jedynak": jedynak,
		"flagi": flagi,
		"ma": ma,
		"cechy_rodzicow": cechy,
		"przedzial_zarobkow": przedzial,
	}


func _pokaz_eventy_tury_ui() -> void:
	var eventy: Variant = _swiat.get("eventy_tury", [])
	if not (eventy is Array):
		return
	for ev in eventy:
		if not (ev is Dictionary):
			continue
		_tresc_biala().add_child(_napis_ekranu(str(ev.get("tekst", "")), 15))
		if not bool(ev.get("pytanie", false)):
			continue
		var rzad := HBoxContainer.new()
		rzad.add_theme_constant_override("separation", 8)
		var opcje: Variant = ev.get("opcje", [])
		if not (opcje is Array) or opcje.is_empty():
			opcje = [{"id": "tak", "nazwa": "Tak"}, {"id": "nie", "nazwa": "Nie"}]
		for op in opcje:
			if not (op is Dictionary):
				continue
			var b := Button.new()
			b.text = str(op.get("nazwa", op.get("id", "?")))
			b.custom_minimum_size = Vector2(72, 40)
			var ev_bind: Dictionary = ev
			var op_id := str(op.get("id", ""))
			b.pressed.connect(func() -> void:
				_on_odpowiedz_eventu(ev_bind, op_id)
			)
			rzad.add_child(b)
		_tresc_biala().add_child(rzad)


func _on_odpowiedz_eventu(ev: Dictionary, opcja_id: String) -> void:
	var wynik: Dictionary = _eventy.zastosuj_wybor(ev, opcja_id, _kontekst_eventow())
	_zastosuj_wynik_eventu(wynik)
	# Usuń ten event z listy oczekujących pytań.
	var zostalo: Array = []
	var lista: Variant = _swiat.get("eventy_tury", [])
	if lista is Array:
		for e in lista:
			if e is Dictionary and str(e.get("id", "")) == str(ev.get("id", "")):
				continue
			zostalo.append(e)
	_swiat["eventy_tury"] = zostalo
	_swiat["event_odpowiedz_tekst"] = str(wynik.get("tekst", ""))
	if str(wynik.get("skutek", "")) == "kieszonkowe_argument_ok":
		# Lekkie otwarcie drogi do kieszonkowego — bez automatycznej wypłaty.
		var flagi: Dictionary = _swiat.get("flagi_odkrycia", {})
		if not (flagi is Dictionary):
			flagi = {}
		flagi["argument_kieszonkowe_ok"] = true
		_swiat["flagi_odkrycia"] = flagi
	elif str(wynik.get("skutek", "")) == "dodaj_znajomego_dziecka" or str(ev.get("skutek", "")) == "dodaj_znajomego_dziecka":
		_dodaj_znajomego_dziecka()
	SkryptZapisu.zapisz(_swiat)
	_pokaz_napisy_tygodnia()


func _zastosuj_wynik_eventu(wynik: Dictionary) -> void:
	var flagi: Dictionary = {}
	if _swiat.get("flagi_odkrycia") is Dictionary:
		flagi = _swiat["flagi_odkrycia"]
	for f in wynik.get("flagi", []):
		flagi[str(f)] = true
	_swiat["flagi_odkrycia"] = flagi
	var tematy: Array = []
	if _swiat.get("odblokowane_tematy_pytan") is Array:
		tematy = _swiat["odblokowane_tematy_pytan"]
	for t in wynik.get("odblokuj_pytania", []):
		var tid := str(t)
		if not tematy.has(tid):
			tematy.append(tid)
	_swiat["odblokowane_tematy_pytan"] = tematy
	var skutki: Variant = wynik.get("skutki", {})
	if skutki is Dictionary:
		# Propozycja: zapisujemy jako flagi skutków; pełny pasek psychiki później.
		for k in skutki.keys():
			flagi["skutek_%s" % str(k)] = skutki[k]
		_swiat["flagi_odkrycia"] = flagi
	if str(wynik.get("skutek", "")) == "dodaj_znajomego_dziecka":
		_dodaj_znajomego_dziecka()


func _dodaj_znajomego_dziecka() -> void:
	var lista: Array = []
	if _swiat.get("znajomi_dzieci") is Array:
		lista = _swiat["znajomi_dzieci"]
	var plec_b := str(_bohater().get("plec", _bohater().get("płeć", "")))
	var ta_sama := plec_b
	lista.append({
		"id": "dziecko_%d" % (lista.size() + 1),
		"nazwa": "Poznane dziecko",
		"plec": ta_sama,
		"rodzice": [{"rola": "rodzic", "nazwa": "Rodzic poznanego dziecka"}],
		"uwaga": "Rodzice tej osoby w Osoby→ta osoba, nie na głównej liście rodziny.",
	})
	_swiat["znajomi_dzieci"] = lista
	# Lekko też do znajomych gry (nie rodzina).
	var znajomi: Array = []
	if _swiat.get("znajomi") is Array:
		znajomi = _swiat["znajomi"]
	znajomi.append({"id": "znajomy_dziecko_%d" % znajomi.size(), "nazwa": "Poznane dziecko", "skad": "przedszkole_szkola"})
	_swiat["znajomi"] = znajomi


func _fallback_nauki_szkolnej() -> void:
	# Jak nie nauczy się w domu — i tak w podstawówce (~7).
	var wiek: Variant = _wiek_lat()
	if not _jest_liczba(wiek) or int(wiek) < 7:
		return
	var flagi: Dictionary = {}
	if _swiat.get("flagi_odkrycia") is Dictionary:
		flagi = _swiat["flagi_odkrycia"]
	if not bool(flagi.get("uczy_sie_czytac_w_domu", false)):
		flagi["nauczy_sie_czytac_w_szkole"] = true
		flagi["umie_czytac"] = true
	if not bool(flagi.get("uczy_sie_pisac_w_domu", false)):
		flagi["umie_pisac"] = true
	if not bool(flagi.get("uczy_sie_liczyc_w_domu", false)):
		flagi["umie_liczyc"] = true
	_swiat["flagi_odkrycia"] = flagi


func _blok_metryki(_id: String) -> Dictionary:
	var rzad := HBoxContainer.new()
	rzad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rzad.add_theme_constant_override("separation", 3)
	var emoji := _napis_paska("🙂", 18)
	var stos := Control.new()
	stos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stos.custom_minimum_size = Vector2(48, 22)
	var pasek := ProgressBar.new()
	pasek.set_anchors_preset(Control.PRESET_FULL_RECT)
	pasek.min_value = 0
	pasek.max_value = 100
	pasek.value = 0
	pasek.show_percentage = false
	pasek.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var liczba := Label.new()
	liczba.set_anchors_preset(Control.PRESET_FULL_RECT)
	liczba.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	liczba.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	liczba.add_theme_font_size_override("font_size", 12)
	liczba.add_theme_color_override("font_color", Color.WHITE)
	liczba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stos.add_child(pasek)
	stos.add_child(liczba)
	rzad.add_child(emoji)
	rzad.add_child(stos)
	return {"wezel": rzad, "emoji": emoji, "pasek": pasek, "liczba": liczba}


func _styl_panelu_paska() -> void:
	var panel: PanelContainer = get_node(KOLUMNA_GRY + "/PasekStatystyk")
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(0.18, 0.24, 0.28, 0.96)
	styl.corner_radius_top_left = 10
	styl.corner_radius_top_right = 10
	styl.corner_radius_bottom_left = 10
	styl.corner_radius_bottom_right = 10
	styl.content_margin_left = 8
	styl.content_margin_right = 8
	styl.content_margin_top = 8
	styl.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", styl)


func _podlacz_pasek_gest() -> void:
	var uchwyt: ColorRect = get_node(KOLUMNA_GRY + "/PasekStatystyk/PasekWnetrze/UchwytPaska")
	uchwyt.gui_input.connect(_on_pasek_input)
	var panel: PanelContainer = get_node(KOLUMNA_GRY + "/PasekStatystyk")
	panel.gui_input.connect(_on_pasek_input)


func _on_pasek_input(zdarzenie: InputEvent) -> void:
	if zdarzenie is InputEventMouseButton:
		var mysz := zdarzenie as InputEventMouseButton
		if mysz.button_index == MOUSE_BUTTON_LEFT:
			if mysz.pressed:
				_pasek_ciagnie = true
				_pasek_start_y = mysz.global_position.y
			else:
				_pasek_ciagnie = false
	elif zdarzenie is InputEventMouseMotion and _pasek_ciagnie:
		var ruch: InputEventMouseMotion = zdarzenie
		var delta := ruch.global_position.y - _pasek_start_y
		if delta > 28.0 and not _pasek_rozwiniety:
			_ustaw_pasek_rozwiniety(true)
		elif delta < -28.0 and _pasek_rozwiniety:
			_ustaw_pasek_rozwiniety(false)


func _ustaw_pasek_rozwiniety(wlacz: bool) -> void:
	_pasek_rozwiniety = wlacz
	_rozwiniete_stat.visible = wlacz
	if wlacz:
		_wypelnij_rozwiniete_stat()


func _wypelnij_rozwiniete_stat() -> void:
	_wyczysc(_rozwiniete_stat)
	_wypelnij_statystyki_ilosciowe(_rozwiniete_stat, true)


func _wypelnij_statystyki_ilosciowe(cel: VBoxContainer, kompakt: bool = false) -> void:
	var bohater := _bohater()
	var rozmiar := 13 if kompakt else 15
	cel.add_child(_napis_ekranu_lub_paska("Zdrowie: %s" % _tekst_lub_pauza(bohater.get("zdrowie_skrot"), bohater.get("zdrowie")), rozmiar, kompakt))
	cel.add_child(_napis_ekranu_lub_paska("Wygląd: %s" % _tekst_lub_pauza(_nazwa_pola(bohater.get("wyglad_naturalny"))), rozmiar, kompakt))
	var sila := _tekst_liczby(bohater.get("sila"))
	var kondycja := _tekst_liczby(bohater.get("kondycja"))
	if sila != "" or kondycja != "":
		cel.add_child(_napis_ekranu_lub_paska("Siła: %s   Kondycja: %s" % [
			sila if sila != "" else "—",
			kondycja if kondycja != "" else "—"
		], rozmiar, kompakt))
	elif _tekst_liczby(bohater.get("wytrzymalosc")) != "":
		cel.add_child(_napis_ekranu_lub_paska("Wytrzymałość: %s" % _tekst_liczby(bohater.get("wytrzymalosc")), rozmiar, kompakt))
	var zdrowe: Variant = _jedzenie.odczyt_statystyk().get("zdrowe_zywienie")
	cel.add_child(_napis_ekranu_lub_paska("Zdrowe żywienie: %s" % (_tekst_liczby(zdrowe) if _jest_liczba(zdrowe) else "—"), rozmiar, kompakt))
	cel.add_child(_napis_ekranu_lub_paska("Sylwetka: %s" % _tekst_lub_pauza(_nazwa_pola(bohater.get("sylwetka"))), rozmiar, kompakt))
	# Pasek czyta psychikę. Docelowe tylko przy POKAZ_STATYSTYKI (nigdy w normalnej grze).
	if DostepStatystyk.POKAZ_STATYSTYKI:
		var doc := _tekst_liczby(bohater.get("zadowolenie_docelowe"))
		cel.add_child(_napis_ekranu_lub_paska("Docelowe (dev): %s" % (doc if doc != "" else "—"), rozmiar, kompakt))


func _napis_ekranu_lub_paska(tekst: String, rozmiar: int, na_pasku: bool) -> Label:
	if na_pasku:
		return _napis_paska(tekst, rozmiar)
	return _napis_ekranu(tekst, rozmiar)


func _odswiez_pasek_statystyk(animuj_pieniadze: bool) -> void:
	if _rok_lbl == null:
		return
	var rok := int(_swiat.get("rok", 1))
	var tydzien := int(_swiat.get("tydzien", 0))
	_rok_lbl.text = "Rok %d" % rok
	_tydzien_lbl.text = "Tydzień %d" % tydzien
	var psychika: Variant = _wartosc_metryki("psychika")
	var zmeczenie: Variant = _wartosc_metryki("zmeczenie_fizyczne")
	if zmeczenie == null:
		zmeczenie = _wartosc_metryki("zmeczenie")
	var zmeczenie_p: Variant = _wartosc_metryki("zmeczenie_psychiczne")
	_ustaw_metryke(_psychika_emoji, _psychika_pasek, _psychika_liczba, "psychika", psychika, false)
	_ustaw_metryke(_zmeczenie_emoji, _zmeczenie_pasek, _zmeczenie_liczba, "zmeczenie_fizyczne", zmeczenie, true)
	if _zmeczenie_psych_pasek != null:
		_ustaw_metryke(_zmeczenie_psych_emoji, _zmeczenie_psych_pasek, _zmeczenie_psych_liczba, "zmeczenie_psychiczne", zmeczenie_p, true)
	_ustaw_pieniadze(animuj_pieniadze)
	if _pasek_rozwiniety:
		_wypelnij_rozwiniete_stat()


func _wartosc_metryki(klucz: String) -> Variant:
	var bohater := _bohater()
	if _jest_liczba(bohater.get(klucz)):
		return int(bohater[klucz])
	if _jest_liczba(_swiat.get(klucz)):
		return int(_swiat[klucz])
	var blok: Variant = _emotikony.get(klucz, {})
	if blok is Dictionary and _jest_liczba(blok.get("norma")):
		return int(blok["norma"])
	return null


func _ustaw_metryke(emoji: Label, pasek: ProgressBar, liczba: Label, klucz: String, wartosc: Variant, odwrotnie_kolor: bool) -> void:
	var blok: Variant = _emotikony.get(klucz, {})
	if not (blok is Dictionary) or blok.is_empty():
		if klucz == "zmeczenie_fizyczne":
			blok = _emotikony.get("zmeczenie", {})
		elif klucz == "zmeczenie_psychiczne":
			blok = _emotikony.get("zmeczenie", {})
	var v := 0
	if _jest_liczba(wartosc):
		v = clampi(int(wartosc), 0, 100)
	emoji.text = _emoji_z_progow(blok, v if _jest_liczba(wartosc) else null)
	pasek.value = float(v)
	liczba.text = str(v) if _jest_liczba(wartosc) else "—"
	var kolor_hex := _kolor_z_progow(blok, v)
	var styl := StyleBoxFlat.new()
	styl.bg_color = _kolor(kolor_hex)
	styl.corner_radius_top_left = 4
	styl.corner_radius_top_right = 4
	styl.corner_radius_bottom_left = 4
	styl.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("fill", styl)
	var tlo := StyleBoxFlat.new()
	tlo.bg_color = Color(0.12, 0.14, 0.16, 1)
	tlo.corner_radius_top_left = 4
	tlo.corner_radius_top_right = 4
	tlo.corner_radius_bottom_left = 4
	tlo.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("background", tlo)
	if odwrotnie_kolor:
		pass


func _emoji_z_progow(blok: Variant, wartosc: Variant) -> String:
	if not (blok is Dictionary):
		return "•"
	if wartosc == null and blok.has("null_emoji"):
		return str(blok.get("null_emoji"))
	var lista: Variant = blok.get("emotikony", blok.get("progi", []))
	if not (lista is Array) or not _jest_liczba(wartosc):
		return str(blok.get("null_emoji", "•"))
	var v := int(wartosc)
	for wpis in lista:
		if not (wpis is Dictionary):
			continue
		var prog: Variant = wpis.get("do")
		if prog == null:
			return str(wpis.get("emoji", "•"))
		if _jest_liczba(prog) and v <= int(prog):
			return str(wpis.get("emoji", "•"))
	return "•"


func _kolor_z_progow(blok: Variant, wartosc: int) -> String:
	if not (blok is Dictionary):
		return "#888888"
	var lista: Variant = blok.get("kolory_paska", [])
	if not (lista is Array):
		return "#888888"
	for wpis in lista:
		if wpis is Dictionary and _jest_liczba(wpis.get("do")) and wartosc <= int(wpis["do"]):
			return str(wpis.get("kolor", "#888888"))
	return "#888888"


func _ustaw_pieniadze(animuj: bool) -> void:
	var kwota: Variant = null
	var stan := _jedzenie.odczyt_statystyk()
	if _jest_liczba(stan.get("pieniadze")):
		kwota = int(stan["pieniadze"])
	elif _jest_liczba(_bohater().get("pieniadze")):
		kwota = int(_bohater()["pieniadze"])
	var blok: Variant = _emotikony.get("pieniadze", {})
	if kwota == null:
		_pieniadze_znane_pokaz = false
		_pieniadze_emoji.text = str(blok.get("null_emoji", "👛")) if blok is Dictionary else "👛"
		_pieniadze_lbl.text = str(blok.get("null_tekst", "—")) if blok is Dictionary else "—"
		return
	_pieniadze_emoji.text = _emoji_portfela(int(kwota), blok)
	if not animuj or not _pieniadze_znane_pokaz:
		_pieniadze_pokazane = float(kwota)
		_pieniadze_lbl.text = str(int(kwota))
		_pieniadze_znane_pokaz = true
		return
	if _pieniadze_tween != null and is_instance_valid(_pieniadze_tween):
		_pieniadze_tween.kill()
	_pieniadze_tween = create_tween()
	_pieniadze_tween.tween_method(_ustaw_tekst_pieniedzy, _pieniadze_pokazane, float(kwota), 0.55)


func _ustaw_tekst_pieniedzy(wartosc: float) -> void:
	_pieniadze_pokazane = wartosc
	_pieniadze_lbl.text = str(int(round(wartosc)))


func _emoji_portfela(kwota: int, blok: Variant) -> String:
	if not (blok is Dictionary):
		return "👛"
	var progi: Variant = blok.get("progi", [])
	if not (progi is Array):
		return "👛"
	for wpis in progi:
		if not (wpis is Dictionary):
			continue
		var prog: Variant = wpis.get("do")
		if prog == null:
			return str(wpis.get("emoji", "🏆"))
		if _jest_liczba(prog) and kwota <= int(prog):
			return str(wpis.get("emoji", "👛"))
	return "🏆"


func _odswiez_lokalizacje() -> void:
	var napis: Label = get_node(KOLUMNA_GRY + "/Lokalizacja")
	napis.text = _opis_lokalizacji()
	napis.add_theme_color_override("font_color", Color(0.9, 0.93, 0.95))


func _opis_lokalizacji() -> String:
	var nazwa := str(_swiat.get("nazwa_miejsca", ""))
	var gdzie := str(_swiat.get("miejsce_pobytu", "dom"))
	if gdzie == "":
		gdzie = "dom"
	if nazwa == "":
		return gdzie
	return "%s - %s" % [nazwa, gdzie]


func _styl_bialego_ekranu() -> void:
	var panel: PanelContainer = get_node(KOLUMNA_GRY + "/BialyEkran")
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(1, 1, 1, 1)
	styl.corner_radius_top_left = 12
	styl.corner_radius_top_right = 12
	styl.corner_radius_bottom_left = 12
	styl.corner_radius_bottom_right = 12
	styl.content_margin_left = 0
	styl.content_margin_right = 0
	styl.content_margin_top = 0
	styl.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", styl)


func _linia_albo_pusto(tekst: String) -> void:
	if tekst != "":
		_tresc_biala().add_child(_napis_ekranu(tekst, 20))
	else:
		_tresc_biala().add_child(_napis_ekranu("—", 18))


func _opis_urodzenia() -> String:
	var nazwa := str(_swiat.get("nazwa_urodzenia", ""))
	var typ := str(_swiat.get("typ_urodzenia", ""))
	if nazwa == "":
		return ""
	if typ == "miasto":
		return "%s, miasto" % nazwa
	if typ != "":
		return "%s, reszta powiatu" % nazwa
	return nazwa


func _pieniadze_tekst() -> String:
	var stan := _jedzenie.odczyt_statystyk()
	if _jest_liczba(stan.get("pieniadze")):
		return str(int(stan["pieniadze"]))
	if _jest_liczba(_bohater().get("pieniadze")):
		return str(int(_bohater()["pieniadze"]))
	return ""


func _tekst_domu() -> String:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return ""
	var dom: Variant = rodzina.get("dom", {})
	if dom is Dictionary and dom.get("kolo") == true and str(dom.get("nazwa", "")) != "":
		return str(dom.get("nazwa"))
	return ""


func _opis_mieszkacie_w() -> String:
	var lokum: Variant = _swiat.get("lokum_startowe", {})
	if not _lokum_pelne(lokum):
		var maj: Variant = _swiat.get("majatek", {})
		if maj is Dictionary and maj.get("lokum_rodziny") is Dictionary:
			lokum = maj["lokum_rodziny"]
		else:
			var rodzina: Variant = _swiat.get("rodzina", {})
			if rodzina is Dictionary and rodzina.get("lokum") is Dictionary:
				lokum = rodzina["lokum"]
	return _rynek_zakupow.opis_lokum_ui(lokum)


func _lokum_pelne(lokum: Variant) -> bool:
	if not (lokum is Dictionary):
		return false
	if not _jest_liczba(lokum.get("wygoda")):
		return false
	# Pełny obiekt: typ + metraż (stary save miał tylko wygodę/dom_id).
	return str(lokum.get("typ", "")) != "" and _jest_liczba(lokum.get("metraz_m2"))


func _zbuduj_lokum_dla_swiata() -> Dictionary:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var miejsce: Variant = null
	var bohater: Variant = _swiat.get("bohater", {})
	if bohater is Dictionary and bohater.get("miejsce") is Dictionary:
		miejsce = bohater["miejsce"]
	elif str(_swiat.get("id_urodzenia", "")) != "":
		miejsce = {
			"id": str(_swiat.get("id_urodzenia", "")),
			"nazwa": str(_swiat.get("nazwa_urodzenia", "")),
			"typ": str(_swiat.get("typ_urodzenia", "")),
		}
	var lokum: Dictionary = _rynek_zakupow.zbuduj_lokum_startowe(rodzina, miejsce)
	_swiat["rodzina"] = rodzina
	if not (_swiat.get("majatek") is Dictionary):
		_swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	_swiat["majatek"]["lokum_rodziny"] = lokum.duplicate(true)
	return lokum


func _tekst_pracy() -> String:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return ""
	var czesci: PackedStringArray = []
	for rola in ["matka", "ojciec"]:
		var osoba: Variant = rodzina.get(rola)
		if not (osoba is Dictionary):
			continue
		var praca: Variant = osoba.get("praca", {})
		if praca is Dictionary and praca.get("kolo") == true and str(praca.get("nazwa", "")) != "":
			czesci.append("%s: %s" % [rola.capitalize(), str(praca.get("nazwa"))])
	if not czesci.is_empty():
		return "; ".join(czesci)
	var praca_stara: Variant = rodzina.get("praca", {})
	if praca_stara is Dictionary and praca_stara.get("kolo") == true and str(praca_stara.get("nazwa", "")) != "":
		return str(praca_stara.get("nazwa"))
	return ""


func _tekst_zarobkow(blok: Variant) -> String:
	if not (blok is Dictionary) or blok.get("kolo") != true:
		return ""
	var od: Variant = blok.get("od_zl")
	var dok: Variant = blok.get("do_zl")
	if not _jest_liczba(od) and _jest_liczba(blok.get("mediana_zl")):
		od = blok.get("mediana_zl")
	if not _jest_liczba(dok) and _jest_liczba(blok.get("przecietne_zl")):
		dok = blok.get("przecietne_zl")
	if _jest_liczba(od) and _jest_liczba(dok):
		return "%s–%s zł" % [od, dok]
	if _jest_liczba(dok):
		return "do %s zł" % dok
	if _jest_liczba(od):
		return "od %s zł" % od
	return ""


func _cechy_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("cecha_%d" % numer):
		var nazwa := _nazwa_pola(bohater["cecha_%d" % numer])
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _inteligencje_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("inteligencja_%d" % numer):
		var pozycja: Variant = bohater["inteligencja_%d" % numer]
		var nazwa := _nazwa_pola(pozycja)
		if nazwa != "" and pozycja is Dictionary and _jest_liczba(pozycja.get("wartosc")):
			nazwa = "%s %s" % [nazwa, str(int(pozycja["wartosc"]))]
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _bohater() -> Dictionary:
	var bohater: Variant = _swiat.get("bohater", {})
	if bohater is Dictionary:
		return bohater
	return {}


func _auto_z_zapisu() -> Variant:
	var auto: Variant = _swiat.get("auto", null)
	if auto is Dictionary and _auto_jest(auto) and not bool(auto.get("nie_jezdzi", false)):
		return auto
	var posiadane: Variant = _bohater().get("posiadane", {})
	if posiadane is Dictionary:
		var pojazdy: Variant = posiadane.get("pojazdy", {})
		if pojazdy is Dictionary and pojazdy.get("samochody") is Array:
			for wpis in pojazdy["samochody"]:
				if wpis is Dictionary and _auto_jest(wpis) and not bool(wpis.get("nie_jezdzi", false)):
					return wpis
	var maj: Variant = _swiat.get("majatek", {})
	if maj is Dictionary and maj.get("dobra") is Array:
		for wpis2 in maj["dobra"]:
			if wpis2 is Dictionary and str(wpis2.get("kategoria", "")) == "samochod" \
					and _auto_jest(wpis2) and not bool(wpis2.get("nie_jezdzi", false)):
				return wpis2
	return null


func _panel_awarii_auta(idx: int, auto: Dictionary) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 6)
	var kot: Dictionary = _rynek_zakupow.kotwica_naprawy_silnika(auto)
	kolumna.add_child(_napis_ekranu(
		"Awaria silnika — stub: Laweta ~%d zł · Mechanik ~%d zł · Złom +~%d zł (propozycja)." % [
			int(kot.get("laweta_zl", 0)),
			int(kot.get("mechanik_zl", 0)),
			int(kot.get("zlom_zl", 0)),
		],
		13
	))
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 8)
	var b_law := Button.new()
	b_law.text = "Laweta"
	b_law.custom_minimum_size = Vector2(0, 40)
	b_law.pressed.connect(func() -> void:
		var w: Dictionary = _rynek_zakupow.laweta_auta(_swiat, idx)
		_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
		if bool(w.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			_zsynchronizuj_pieniadze_z_bohatera()
			_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	var b_mech := Button.new()
	b_mech.text = "Mechanik"
	b_mech.custom_minimum_size = Vector2(0, 40)
	b_mech.pressed.connect(func() -> void:
		var w2: Dictionary = _rynek_zakupow.mechanik_auta(_swiat, idx)
		_pokaz_komunikat_zakupu(str(w2.get("tekst", w2.get("powod", ""))), w2)
		if bool(w2.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			_zsynchronizuj_pieniadze_z_bohatera()
			_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	var b_zlom := Button.new()
	b_zlom.text = "Złom"
	b_zlom.custom_minimum_size = Vector2(0, 40)
	b_zlom.pressed.connect(func() -> void:
		var w3: Dictionary = _rynek_zakupow.zlom_auta(_swiat, idx)
		_pokaz_komunikat_zakupu(str(w3.get("tekst", w3.get("powod", ""))), w3)
		if bool(w3.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			_zsynchronizuj_pieniadze_z_bohatera()
			_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
	)
	rzad.add_child(b_law)
	rzad.add_child(b_mech)
	rzad.add_child(b_zlom)
	kolumna.add_child(rzad)
	return kolumna


func _auto_jest(auto: Dictionary) -> bool:
	for klucz in ["id", "marka", "model", "nazwa"]:
		if auto.get(klucz) != null and str(auto.get(klucz)) != "":
			return true
	return false


func _opis_auta(auto: Dictionary) -> String:
	var czesci: PackedStringArray = []
	for klucz in ["marka", "model", "nazwa"]:
		if auto.get(klucz) != null and str(auto.get(klucz)) != "":
			czesci.append(str(auto[klucz]))
	return " ".join(czesci)


func _cena_tygodnia_auta(auto: Dictionary) -> String:
	if _jest_liczba(auto.get("cena_tygodnia")):
		return str(auto.get("cena_tygodnia"))
	return "—"


func _cena_paliwa() -> Variant:
	var kraj: Variant = _czytaj_json("res://świat/polska/kraj.json")
	if not (kraj is Dictionary):
		return null
	var paliwo: Variant = kraj.get("cena_paliwa", {})
	if not (paliwo is Dictionary):
		return null
	for klucz in ["pb95", "olej_napedowy"]:
		if _jest_liczba(paliwo.get(klucz)):
			return paliwo.get(klucz)
	return null


func _cena_transportu_miasta(id: String) -> Variant:
	if id == "":
		return null
	var dane: Variant = _czytaj_json("res://świat/polska/miasta/%s.json" % id)
	if dane is Dictionary:
		return dane.get("cena_transportu_publicznego", null)
	return null


func _klasy_nadwozia() -> Array:
	var dane: Variant = _czytaj_json("res://pojazdy/nadwozia.json")
	if dane is Dictionary and dane.get("klasy") is Array:
		return dane["klasy"]
	return []


func _tekst_ceny(cena: Variant) -> String:
	if _jest_liczba(cena):
		return "%s zł" % str(cena)
	return "—"


func _tekst_ceny_oferty(cena: Variant, kat_id: String = "") -> String:
	if kat_id == "samochod":
		return _rynek_zakupow.formatuj_cene_auta(cena)
	return _tekst_ceny(cena)


func _join_tekstow(lista: Array) -> String:
	var parts: PackedStringArray = []
	for x in lista:
		parts.append(str(x))
	return ", ".join(parts)


func _nazwa_pola(pozycja: Variant) -> String:
	if pozycja is Dictionary:
		return str(pozycja.get("nazwa", ""))
	return ""


func _tekst_pusty(wartosc: Variant) -> String:
	if wartosc == null:
		return ""
	return str(wartosc)


func _tekst_lub_pauza(a: Variant = null, b: Variant = null) -> String:
	var t := _tekst_pusty(a)
	if t != "":
		return t
	t = _tekst_pusty(b)
	if t != "":
		return t
	return "—"


func _tekst_liczby(wartosc: Variant) -> String:
	if _jest_liczba(wartosc):
		return str(int(wartosc))
	return ""


func _zbuduj_statystyki_menu() -> void:
	var w_menu := $MenuEkran/StatystykiButton as Button
	if not DostepStatystyk.POKAZ_STATYSTYKI:
		w_menu.hide()
		return
	if not w_menu.pressed.is_connected(_on_statystyki_pressed):
		w_menu.pressed.connect(_on_statystyki_pressed)
	var panel := get_node_or_null("PanelStatystyk")
	if panel != null:
		return
	panel = PanelStatystykSkrypt.new()
	panel.name = "PanelStatystyk"
	panel.visible = false
	panel.z_index = 30
	panel.zapisano.connect(_on_statystyki_zapisane)
	add_child(panel)


func _on_statystyki_pressed() -> void:
	var panel := get_node_or_null("PanelStatystyk")
	if panel == null:
		return
	if panel.visible:
		panel.hide()
		return
	panel.wczytaj_z_gry(_jedzenie)
	panel.oznacz_otwarty()
	panel.show()
	panel.move_to_front()
	$Powrot.show()
	_na_wierzch_przyciski()


func _on_statystyki_zapisane(zapis: Dictionary) -> void:
	_jedzenie.zastosuj_statystyki(zapis)
	_odswiez_pasek_statystyk(true)


func _zastosuj_wyglad() -> void:
	theme = WygladGracza.temat(_wyglad)
	_styl_bialego_ekranu()
	_styl_panelu_paska()


func _podlacz_ustawienia() -> void:
	_cisza_ustawien = true
	var kolumna: Node = get_node(KOLUMNA_USTAWIEN)
	for i in [1, 2, 3]:
		var przycisk := kolumna.get_node("Szerokosc%d" % i) as Button
		przycisk.visible = false
	var opis: Label = kolumna.get_node("SzerokoscOpis")
	opis.visible = false
	var proporcje: Label = kolumna.get_node("Proporcje")
	proporcje.text = "Ekran pionowy (telefon). Stary podział 8:5 usunięty."
	_ustaw_suwak_alpha(kolumna, "PanelAlpha", "PanelAlphaOpis", "Przejrzystość panelu", "alpha_panelu")
	_ustaw_suwak_alpha(kolumna, "PrzyciskiAlpha", "PrzyciskiAlphaOpis", "Przejrzystość przycisków", "alpha_przyciskow")
	_ustaw_suwak_alpha(kolumna, "NapisyAlpha", "NapisyAlphaOpis", "Przejrzystość napisów", "alpha_napisow")
	var napisy := kolumna.get_node("KolorNapisow") as ColorPickerButton
	napisy.edit_alpha = false
	napisy.color = _wyglad.get("kolor_napisow", Color.WHITE)
	if not napisy.color_changed.is_connected(_on_kolor_napisow):
		napisy.color_changed.connect(_on_kolor_napisow)
	var tlo := kolumna.get_node("KolorTla") as ColorPickerButton
	tlo.edit_alpha = false
	tlo.color = _wyglad.get("kolor_tla", Color(0.45, 0.45, 0.48))
	if not tlo.color_changed.is_connected(_on_kolor_tla):
		tlo.color_changed.connect(_on_kolor_tla)
	_cisza_ustawien = false


func _ustaw_suwak_alpha(kolumna: Node, suwak_nazwa: String, opis_nazwa: String, tytul: String, klucz: String) -> void:
	var suwak := kolumna.get_node(suwak_nazwa) as HSlider
	suwak.min_value = 0.0
	suwak.max_value = 1.0
	suwak.step = 0.05
	var start := float(_wyglad.get(klucz, 1.0))
	suwak.set_value_no_signal(start)
	var opis := kolumna.get_node(opis_nazwa) as Label
	opis.text = WygladGracza.napis_przejrzystosci(tytul, start)
	if not suwak.value_changed.is_connected(_on_alpha):
		suwak.value_changed.connect(_on_alpha.bind(klucz, opis, tytul))


func _on_alpha(wartosc: float, klucz: String, opis: Label, tytul: String) -> void:
	if _cisza_ustawien:
		return
	_wyglad[klucz] = wartosc
	opis.text = WygladGracza.napis_przejrzystosci(tytul, wartosc)
	_zapisz_wyglad()


func _on_kolor_napisow(kolor: Color) -> void:
	if _cisza_ustawien:
		return
	kolor.a = 1.0
	_wyglad["kolor_napisow"] = kolor
	_zapisz_wyglad()


func _on_kolor_tla(kolor: Color) -> void:
	if _cisza_ustawien:
		return
	kolor.a = 1.0
	_wyglad["kolor_tla"] = kolor
	_zapisz_wyglad()


func _zapisz_wyglad() -> void:
	WygladGracza.zapisz(_wyglad)
	_zastosuj_wyglad()


func _male_przyciski() -> void:
	var pusty := StyleBoxEmpty.new()
	for sciezka in ["UstawieniaGry", "Wyjscie"]:
		var przycisk := get_node(sciezka) as Button
		przycisk.text = ""
		przycisk.custom_minimum_size = Vector2(56, 56)
		przycisk.expand_icon = false
		przycisk.add_theme_constant_override("icon_max_width", 28)
		for stan in ["normal", "hover", "pressed", "focus", "disabled"]:
			przycisk.add_theme_stylebox_override(stan, pusty)
	# Powrót: lewy dół, ten sam czysty styl ikony co Wyjście (bez ciemnego panelu).
	var powrot := $Powrot as Button
	powrot.text = ""
	powrot.custom_minimum_size = Vector2(56, 56)
	powrot.expand_icon = false
	powrot.add_theme_constant_override("icon_max_width", 28)
	for stan in ["normal", "hover", "pressed", "focus", "disabled"]:
		powrot.add_theme_stylebox_override(stan, pusty)


func _na_wierzch_przyciski() -> void:
	$Powrot.move_to_front()
	$Wyjscie.move_to_front()
	$UstawieniaGry.move_to_front()


func _tresc_biala() -> VBoxContainer:
	return get_node(KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/ScrollBialy/TrescBiala")


func _tytul_bialy() -> Label:
	return get_node(KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/TytulBialy")


func _dol_suwaka() -> VBoxContainer:
	return get_node(KOLUMNA_GRY + "/BialyEkran/MarginesBialy/KolumnaBiala/DolSuwaka")


func _wyczysc(wezel: Node) -> void:
	var dzieci := wezel.get_children()
	for dziecko in dzieci:
		wezel.remove_child(dziecko)
		dziecko.queue_free()


func _z_marginesem(wezel: Control) -> Control:
	var margines := MarginContainer.new()
	margines.add_theme_constant_override("margin_left", 8)
	margines.add_theme_constant_override("margin_right", 8)
	margines.add_theme_constant_override("margin_top", 4)
	margines.add_theme_constant_override("margin_bottom", 8)
	margines.add_child(wezel)
	return margines


func _napis_ekranu(tekst: String, rozmiar: int) -> Label:
	var napis := Label.new()
	napis.text = tekst
	napis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Czytelność na ~720 px: etykiety min ~16–18.
	napis.add_theme_font_size_override("font_size", rozmiar if rozmiar >= 16 else 16)
	napis.add_theme_color_override("font_color", TEKST_CIEMNY)
	return napis


func _napis_paska(tekst: String, rozmiar: int) -> Label:
	var napis := Label.new()
	napis.text = tekst
	napis.autowrap_mode = TextServer.AUTOWRAP_OFF
	napis.add_theme_font_size_override("font_size", rozmiar)
	napis.add_theme_color_override("font_color", Color(0.95, 0.96, 0.97))
	napis.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return napis


func _rich_ekran() -> RichTextLabel:
	var napis := RichTextLabel.new()
	napis.bbcode_enabled = true
	napis.fit_content = true
	napis.scroll_active = false
	napis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	napis.add_theme_font_size_override("normal_font_size", 16)
	napis.add_theme_color_override("default_color", TEKST_CIEMNY)
	return napis


func _kolor(html: String) -> Color:
	if html.begins_with("#") and (html.length() == 7 or html.length() == 9):
		return Color(html)
	return Color("#9aa7b2")


func _kolor_napisu_na(tlo: Color) -> Color:
	var jasnosc := tlo.r * 0.3 + tlo.g * 0.59 + tlo.b * 0.11
	if jasnosc > 0.62:
		return Color("#1c2428")
	return Color.WHITE


func _czytaj_json(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())


func _jest_liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float
