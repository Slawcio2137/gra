extends Control

const DostepStatystyk = preload("res://scripts/statystyki_dostep.gd")
const PanelStatystykSkrypt = preload("res://scripts/statystyki_panel.gd")
const ScenaJedzenia = preload("res://scenes/jedzenie_ustawienia.tscn")
const SkryptZakresu = preload("res://scripts/suwak_zakres.gd")
const SkryptZapisu = preload("res://scripts/zapis_swiata.gd")
const SkryptEventow = preload("res://scripts/eventy_odkrycia.gd")
const SkryptRynkuZakupow = preload("res://scripts/rynek_zakupow.gd")
const ZaokraglenieZarobkow = preload("res://scripts/zaokraglenie_zarobkow.gd")
const SkryptMapyMiast = preload("res://scripts/mapa_miast.gd")
const SkryptPrzejazdu = preload("res://scripts/przejazd_auta.gd")
const PLIK_ZAKUPOW_OFERT := "res://postacie/zakupy_oferty.json"
const PLIK_DROBIAZGOW := "res://postacie/drobiazgi.json"
const IKONA_MIASTA := "res://grafika/ikony/miasto.png"
const SkryptKataloguZawodow = preload("res://scripts/katalog_zawodow.gd")
const SkryptRynkuPracy = preload("res://scripts/rynek_pracy.gd")

const KOLUMNA_USTAWIEN := "PanelUstawien/Margines/ScrollUstawien/Kolumna"
const KOLUMNA_GRY := "Gra/Margines/Kolumna"
const ZIELONY := "#2f9e45"
const KRWISTY := "#9d0610"
const TEKST_CIEMNY := Color(0.12, 0.14, 0.16, 1)
const PLIK_EMOTIKONOW := "res://ui/pasek_emotikony.json"
const SkryptUiWspolne = preload("res://scripts/ui_wspolne.gd")
const SkryptStanuGry = preload("res://scripts/stan_gry.gd")
const SkryptPaska = preload("res://scripts/pasek_statystyk.gd")
const SkryptEventowTury = preload("res://scripts/eventy_tury.gd")
const SkryptEkranuDomu = preload("res://scripts/ekran_domu.gd")
const SkryptEkranuRodziny = preload("res://scripts/ekran_rodziny.gd")
const SkryptEkranuJedzenia = preload("res://scripts/ekran_jedzenia.gd")
const SkryptEkranuMapy = preload("res://scripts/ekran_mapy.gd")
const SkryptEkranuZakupow = preload("res://scripts/ekran_zakupow.gd")

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
var _zakupy_pula_lbl: Label
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
var _zakupy_dokladka := false
var _zakupy_scroll_podpiety := false
var _zakupy_prefetch_kroki := 0
var _rynek_zakupow := SkryptRynkuZakupow.new()
var _rynek_pracy = SkryptRynkuPracy.new()
var _ekran_pracy := false
var _praca_dokladka := false
var _praca_scroll_podpiety := false
var _praca_cisza := false
var _praca_filtry: Dictionary = {}
var _praca_pula_lbl: Label
var _mapa_miast := SkryptMapyMiast.new()
var _przejazd := SkryptPrzejazdu.new()
var _mapa_graf: Dictionary = {}
var _mapa_warstwa: Control
var _mapa_pasek: Label
var _mapa_ikona: Texture2D


var _ui: UiWspolne
## Moduły ekranów. Świat, zapis i nawigacja zostają w tym skrypcie.

var _stan: StanGry

var _pasek: PasekStatystykGry

var _tury: EventyTury

var _dom: EkranDomu

var _rodzina: EkranRodziny

var _ekran_jedzenia: EkranJedzenia

var _mapa_ekran: EkranMapy

var _ekran_zakupow: EkranZakupow

func _init() -> void:
	_ui = SkryptUiWspolne.new(self)
	_stan = SkryptStanuGry.new(self)
	_pasek = SkryptPaska.new(self)
	_tury = SkryptEventowTury.new(self)
	_dom = SkryptEkranuDomu.new(self)
	_rodzina = SkryptEkranuRodziny.new(self)
	_ekran_jedzenia = SkryptEkranuJedzenia.new(self)
	_mapa_ekran = SkryptEkranuMapy.new(self)
	_ekran_zakupow = SkryptEkranuZakupow.new(self)










func _ready() -> void:
	_losowanie = Losowanie.new()
	_znak = load("res://grafika/znak_zapytania.png")
	_kropka_mala = load("res://grafika/ikony/kropka_mala.png")
	_kropka_duza = load("res://grafika/ikony/kolko_biale.png")
	_jedzenie = ScenaJedzenia.instantiate()
	_jedzenie.visible = false
	add_child(_jedzenie)
	_wyglad = WygladGracza.wczytaj()
	_ui._wczytaj_emotikony()
	_ui._zastosuj_wyglad()
	_ui._podlacz_ustawienia()
	_ui._male_przyciski()
	_wczytaj_akcje()
	_pasek._zbuduj_pasek_statystyk()
	_zbuduj_zakladki()
	_ui._styl_bialego_ekranu()
	_pasek._podlacz_pasek_gest()
	_ui._zbuduj_statystyki_menu()
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
		_swiat["odblokowane_jedzenie_samemu"] = _ekran_jedzenia._czy_jedzenie_sam_po_wieku()
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
	if not (_swiat.get("lokum_startowe") is Dictionary) or not _stan._lokum_pelne(_swiat.get("lokum_startowe")):
		_swiat["lokum_startowe"] = _stan._zbuduj_lokum_dla_swiata()
	_rynek_zakupow.przelicz_zadowolenie_docelowe(_swiat)
	_ekran_jedzenia._odswiez_flage_jedzenia_sam()
	_ekran_zakupow._odswiez_rynek_zakupow()
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
	_stan._zsynchronizuj_pieniadze_z_bohatera()
	_wejdz()


func _on_nastepna_tura() -> void:
	if _swiat.is_empty():
		return
	var tydzien := int(_swiat.get("tydzien", 1)) + 1
	var rok := int(_swiat.get("rok", 1))
	if tydzien > 52:
		tydzien = 1
		rok += 1
		var bohater := _stan._bohater()
		if _ui._jest_liczba(bohater.get("wiek")):
			bohater["wiek"] = int(bohater["wiek"]) + 1
			_swiat["bohater"] = bohater
	_swiat["tydzien"] = tydzien
	_swiat["rok"] = rok
	_swiat["komunikat_tury"] = ""
	_swiat["eventy_tury"] = []
	_swiat["event_odpowiedz_tekst"] = ""
	_ekran_jedzenia._odswiez_flage_jedzenia_sam()
	_rodzina._wyplata_kieszonkowego_tydzien()
	_rodzina._wyplata_kieszonkowego_dziadkow_tydzien()
	_efekt_konserwacji_auta_tydzien()
	_efekt_fala2_tydzien()
	_tury._losuj_eventy_tury()
	_tury._fallback_nauki_szkolnej()
	_stan._efekt_wygody_tydzien()
	var wynik_pracy: Variant = _rynek_pracy.tick(_swiat)
	if wynik_pracy is Dictionary:
		var wyplata_pracy := int(wynik_pracy.get("wyplata", 0))
		var zdanie_pracy := str(wynik_pracy.get("tekst", ""))
		if wyplata_pracy > 0:
			_stan._dodaj_pieniadze(wyplata_pracy)
			_stan._dodaj_wplyw("praca", wyplata_pracy, zdanie_pracy)
		var pasek_pracy := str(wynik_pracy.get("pasek_tekst", ""))
		if pasek_pracy != "":
			_swiat["praca_komunikat"] = zdanie_pracy + "\n" + pasek_pracy if zdanie_pracy != "" else pasek_pracy
		elif zdanie_pracy != "":
			_swiat["praca_komunikat"] = zdanie_pracy
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	_swiat["dni_auta"] = int(_swiat.get("dni_auta", 0))
	_ekran_zakupow._odswiez_rynek_zakupow()
	SkryptZapisu.zapisz(_swiat)
	_pasek._odswiez_pasek_statystyk(true)
	_pasek._ukryj_zielony_komunikat_tury()
	_pasek._odswiez_lokalizacje()
	# Po turze: wyjdź z głębokiej zakładki i pokaż napisy tygodnia (treść tury → biały obszar).
	_wyjdz_do_napisow_tygodnia()


func _on_ustawienia_pressed() -> void:
	$PanelUstawien.show()
	$Powrot.show()
	_ui._na_wierzch_przyciski()


func _on_zamknij_ustawienia() -> void:
	$PanelUstawien.hide()
	_odswiez_widocznosc_powrotu()
	_ui._na_wierzch_przyciski()


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
	_ui._wyczysc(_ui._tresc_biala())
	_ui._dol_suwaka().hide()
	_ui._tytul_bialy().text = "Statystyki ilościowe"
	_pasek._wypelnij_statystyki_ilosciowe(_ui._tresc_biala())


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
	if not _ui._jest_liczba(wynik.get("pieniadze")):
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
	_stan._uzupelnij_normy_bohatera(wynik)
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
	_ekran_jedzenia._odswiez_flage_jedzenia_sam()
	_ekran_zakupow._odswiez_rynek_zakupow()
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
		var zar := _rodzina._tekst_zarobkow(rodzina["zarobki"])
		czesci.append("Zarobki rodziny: %s." % (zar if zar != "" else "przedział GUS"))
	else:
		var powod_z := ""
		if rodzina.get("zarobki") is Dictionary:
			powod_z = str(rodzina["zarobki"].get("powod", ""))
		czesci.append("Rodzina: zarobki nie wylosowane%s." % ((" — " + powod_z) if powod_z != "" else ""))
	czesci.append("Rodzeństwo: %d." % rodzenstwo.size())
	if _ui._jest_liczba(bohater.get("wiek")):
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
	_pasek._odswiez_lokalizacje()
	_pasek._odswiez_pasek_statystyk(false)
	_ui._na_wierzch_przyciski()


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


func _zbuduj_zakladki() -> void:
	var siatka: GridContainer = get_node(KOLUMNA_GRY + "/SiatkaZakladek")
	_ui._wyczysc(siatka)
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
	var baza := _ui._kolor(hex)
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
	przycisk.add_theme_color_override("font_color", _ui._kolor_napisu_na(baza))
	przycisk.add_theme_color_override("font_pressed_color", _ui._kolor_napisu_na(baza))
	przycisk.add_theme_color_override("font_hover_color", _ui._kolor_napisu_na(baza))


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
	_ui._na_wierzch_przyciski()
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
	_ui._na_wierzch_przyciski()
	_zaplanuj_stos()


func _wyjdz_do_neutralnego() -> void:
	_stos.clear()
	_zakladka_id = ""
	_odznacz_zakladki()
	$Powrot.hide()
	_pokaz_start_bialy()
	_ui._na_wierzch_przyciski()


func _wyjdz_do_napisow_tygodnia() -> void:
	_stos.clear()
	_zakladka_id = ""
	_odznacz_zakladki()
	$Powrot.hide()
	_pokaz_napisy_tygodnia()
	_ui._na_wierzch_przyciski()


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
	_ekran_pracy = false
	_ui._wyczysc(_ui._tresc_biala())
	_ui._dol_suwaka().hide()
	_ui._tytul_bialy().text = "Gra"
	var start := str(_swiat.get("komunikat_startu", ""))
	if start != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(start, 15))
	var tura_txt := str(_swiat.get("komunikat_tury", "")).strip_edges()
	if tura_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("W tym tygodniu: %s" % tura_txt, 15))
	_pasek._ukryj_zielony_komunikat_tury()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Wybierz zakładkę. Rodzina i kieszonkowe: Osoby → Rodzina. Mapa: Majątek → Transport → Mapa.", 16))


func _pokaz_napisy_tygodnia() -> void:
	_ekran_pracy = false
	_ui._wyczysc(_ui._tresc_biala())
	_ui._dol_suwaka().hide()
	var tydzien := int(_swiat.get("tydzien", 1))
	var rok := int(_swiat.get("rok", 1))
	_ui._tytul_bialy().text = "W tym tygodniu"
	# Najpierw Rok i Tydzień — pogrubione i powiększone; potem reszta napisów.
	var naglowek := HBoxContainer.new()
	naglowek.add_theme_constant_override("separation", 20)
	var rok_rich := _ui._rich_ekran()
	rok_rich.add_theme_font_size_override("normal_font_size", 24)
	rok_rich.add_theme_font_size_override("bold_font_size", 24)
	rok_rich.fit_content = true
	rok_rich.text = "[b]Rok %d[/b]" % rok
	var tydzien_rich := _ui._rich_ekran()
	tydzien_rich.add_theme_font_size_override("normal_font_size", 24)
	tydzien_rich.add_theme_font_size_override("bold_font_size", 24)
	tydzien_rich.fit_content = true
	tydzien_rich.text = "[b]Tydzień %d[/b]" % tydzien
	naglowek.add_child(rok_rich)
	naglowek.add_child(tydzien_rich)
	_ui._tresc_biala().add_child(naglowek)
	var tura_txt := str(_swiat.get("komunikat_tury", "")).strip_edges()
	if tura_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(tura_txt, 15))
	var kiesz := str(_swiat.get("ostatnie_kieszonkowe_tekst", "")).strip_edges()
	if kiesz != "" and kiesz != tura_txt:
		_ui._tresc_biala().add_child(_ui._napis_ekranu(kiesz, 14))
	var wygoda_txt := str(_swiat.get("ostatni_efekt_wygody_tekst", "")).strip_edges()
	if wygoda_txt != "" and tura_txt.find(wygoda_txt) < 0:
		_ui._tresc_biala().add_child(_ui._napis_ekranu(wygoda_txt, 14))
	var odp := str(_swiat.get("event_odpowiedz_tekst", "")).strip_edges()
	if odp != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(odp, 15))
	_tury._pokaz_eventy_tury_ui()
	var eventy: Variant = _swiat.get("eventy_tury", [])
	if (not (eventy is Array) or eventy.is_empty()) and tura_txt == "" and kiesz == "" and wygoda_txt == "" and odp == "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak szczególnych wydarzeń tygodnia.", 15))
	_pasek._ukryj_zielony_komunikat_tury()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Wybierz zakładkę, żeby kontynuować.", 14))


func _pokaz_liste_dzieci(akcja: Dictionary) -> void:
	_ui._wyczysc(_ui._tresc_biala())
	_ui._dol_suwaka().hide()
	_ui._tytul_bialy().text = str(akcja.get("nazwa", ""))
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
		_ui._tresc_biala().add_child(przycisk)


func _pokaz_ekran(akcja: Dictionary) -> void:
	_ekran_pracy = false
	_zdanie = null
	_wplyw_domu = null
	_efekt_dni = null
	_efekty_domu = []
	_wiersze_sam = []
	_lista_miast = null
	_opcje_transportu = null
	_mapa_warstwa = null
	_mapa_pasek = null
	_ui._wyczysc(_ui._tresc_biala())
	_ui._wyczysc(_ui._dol_suwaka())
	_ui._dol_suwaka().hide()
	_ui._tytul_bialy().text = _tytul_ekranu(akcja)
	_wypelnij_ekran(akcja)


func _tytul_ekranu(akcja: Dictionary) -> String:
	var tresc := str(akcja.get("tresc", ""))
	if tresc == "jedzenie_sam":
		return "Cena"
	if tresc == "transport" and _mapa_ekran._auto_z_zapisu() != null:
		return "Ile dni w tygodniu"
	return str(akcja.get("nazwa", ""))


func _wypelnij_ekran(akcja: Dictionary) -> void:
	var tresc := str(akcja.get("tresc", ""))
	var kolor := _ui._kolor(str(akcja.get("kolor", "#9aa7b2")))
	if tresc == "dom":
		_dom._ekran_dom()
	elif tresc == "jedzenie_dom":
		_ekran_jedzenia._ekran_jedzenie_dom(kolor)
	elif tresc == "jedzenie_sam":
		_ekran_jedzenia._ekran_jedzenie_sam(kolor)
	elif tresc == "transport":
		_mapa_ekran._ekran_transport(kolor)
	elif tresc == "mapa":
		_mapa_ekran._ekran_mapa()
	elif tresc == "zdrowie":
		_dom._ekran_zdrowie()
	elif tresc == "terapia":
		_ekran_terapia()
	elif tresc == "praca":
		_ekran_praca_fala2()
	elif tresc == "majatek":
		_dom._ekran_majatek()
	elif tresc == "konserwacja_auta":
		_ekran_konserwacja_auta()
	elif tresc == "lotnictwo":
		_ekran_lotnictwo()
	elif tresc == "szkola":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Nauka — Fala 2: korepetycje, zajęcia, szachy w podmenu.", 16))
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
		_ekran_zakupow._ekran_zakupy()
	elif tresc == "zakupy_grupa":
		var grupa_sl: Variant = akcja.get("grupa", {})
		if grupa_sl is Dictionary:
			_ekran_zakupow._ekran_zakupy_grupa(grupa_sl)
	elif tresc == "zakupy_kategoria":
		var kat_sl: Variant = akcja.get("kat", {})
		if kat_sl is Dictionary:
			if str(kat_sl.get("rodzaj", "")) == "budzet_jakosci" or str(kat_sl.get("id", "")) == "drobiazgi":
				_ekran_zakupow._ekran_budzet_drobiazgow()
			else:
				_ekran_zakupow._ekran_zakupy_oferty(str(kat_sl.get("id", "")), "", kat_sl)
	elif tresc == "zakupy_oferta":
		_ekran_zakupow._ekran_zakupy_karta_oferty(akcja)
	elif tresc == "postac":
		_rodzina._ekran_postac()
	elif tresc == "rodzina":
		_rodzina._ekran_rodzina()
	elif tresc == "przyjaciele":
		_rodzina._ekran_lista_osob("przyjaciele", "Nikogo jeszcze.")
	elif tresc == "znajomi":
		_rodzina._ekran_lista_osob("znajomi", "Nikogo jeszcze.")
	elif tresc == "ustawienia_gry":
		_ui._ekran_ustawienia_w_bialym()
	elif tresc == "statystyki_ilosciowe":
		_pasek._wypelnij_statystyki_ilosciowe(_ui._tresc_biala())
	if akcja.get("dzieci") is Array and tresc != "jedzenie" and tresc != "majatek" and tresc != "osoby":
		for dziecko in akcja["dzieci"]:
			if dziecko is Dictionary:
				var przycisk := Button.new()
				przycisk.text = str(dziecko.get("nazwa", ""))
				przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
				przycisk.custom_minimum_size = Vector2(0, 44)
				przycisk.pressed.connect(_otworz_akcje.bind(dziecko))
				_ui._tresc_biala().add_child(przycisk)


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


func _stub_przedszkole() -> void:
	# Stub klikalny — nie pełny system.
	var chodzi := randf() < 0.55
	var tekst := "Przedszkole: chodzisz (często)." if chodzi else "Przedszkole: nie zawsze / nie chodzisz."
	if _swiat.has("przedszkole_tekst"):
		tekst = str(_swiat["przedszkole_tekst"])
	else:
		_swiat["przedszkole_tekst"] = tekst
	_ui._tresc_biala().add_child(_ui._napis_ekranu(tekst, 15))
	var pytania := Button.new()
	pytania.text = "Pytanie do kogoś (stub)"
	pytania.custom_minimum_size = Vector2(0, 44)
	pytania.pressed.connect(_stub_pytanie_dziecka)
	_ui._tresc_biala().add_child(pytania)


func _efekt_fala2_tydzien() -> void:
	var bohater := _stan._bohater()
	var ie := InteligencjaEmocjonalna.new()
	ie.reset_tydzien(bohater)
	var kor := Korepetycje.new()
	kor.reset_tydzien(bohater)
	var dep := Depresja.new()
	var dres: Dictionary = dep.tydzien(bohater)
	if bool(dres.get("zmiana", false)):
		_pasek._dopisz_komunikat_tury(str(dres.get("tekst", "")))
	var zaj := ZajeciaDodatkowe.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(bohater.get("sylwetka", {}))
	var ez: Dictionary = zaj.efekt_tygodnia(bohater, syl)
	if ez.get("teksty") is Array and not (ez["teksty"] as Array).is_empty():
		_pasek._dopisz_komunikat_tury("Zajęcia: " + ", ".join(PackedStringArray(ez["teksty"])))
	# Doprecyzowanie zainteresowań z wiekiem.
	if bohater.get("zainteresowanie") is Dictionary:
		var zan := ZainteresowaniaLos.new()
		bohater["zainteresowanie"] = zan.doprecyzuj_z_wiekiem(bohater["zainteresowanie"], int(bohater.get("wiek", 0)), _losowanie)
	var lot := SprowadzanieSamolotow.new()
	var odsm: Dictionary = lot.sprawdz_odblokowanie_smiglowcow(bohater)
	if bool(odsm.get("odblokowane", false)):
		_pasek._dopisz_komunikat_tury(str(odsm.get("tekst", "")))
	_swiat["bohater"] = bohater


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
	rzad.add_child(_ui._napis_ekranu("%d/%d" % [syl.punkty, syl.cap()], 12))
	return rzad


func _odswiez_bohatera_i_ekran(tresc: String, nazwa: String) -> void:
	_swiat["bohater"] = _stan._bohater()
	SkryptZapisu.zapisz(_swiat)
	_stan._zsynchronizuj_pieniadze_z_bohatera()
	_pasek._odswiez_pasek_statystyk(true)
	_otworz_akcje({"id": tresc, "nazwa": nazwa, "tryb": "ekran", "tresc": tresc})


func _ekran_korepetycje() -> void:
	var bohater := _stan._bohater()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Korepetycje (propozycja kosztów). Wiedza: %d" % int(bohater.get("wiedza_pkt", 0)), 16))
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
			var w: Dictionary = kor.zajecie(_stan._bohater(), id_b)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("korepetycje", "Korepetycje")
		)
		_ui._tresc_biala().add_child(b)


func _ekran_zajecia_dodatkowe() -> void:
	var bohater := _stan._bohater()
	var zaj := ZajeciaDodatkowe.new()
	var akt := zaj.aktywne(bohater)
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Aktywne: %s" % (", ".join(PackedStringArray(akt)) if not akt.is_empty() else "brak"), 15))
	for z in zaj.lista(_stan._wiek_lat()):
		if not (z is Dictionary):
			continue
		var b := Button.new()
		b.text = "Zapisz: %s" % str(z.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_z := str(z.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = zaj.zapisz_sie(_stan._bohater(), id_z)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("zajecia_dodatkowe", "Zajęcia dodatkowe")
		)
		_ui._tresc_biala().add_child(b)


func _ekran_szachy() -> void:
	var bohater := _stan._bohater()
	var sz := Szachy.new()
	sz.zapewnij_ranking(bohater)
	_swiat["bohater"] = bohater
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Ranking lokalny (nie ELO FIDE): %d" % sz.ranking(bohater), 16))
	var bt := Button.new()
	bt.text = "Trening"
	bt.custom_minimum_size = Vector2(0, 44)
	bt.pressed.connect(func() -> void:
		var w: Dictionary = sz.trening(_stan._bohater())
		_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
		if bool(w.get("ok", false)):
			_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
	)
	_ui._tresc_biala().add_child(bt)
	for t in sz.turnieje(_stan._wiek_lat()):
		if not (t is Dictionary):
			continue
		var b := Button.new()
		b.text = "Turniej: %s (wpisowe %d zł)" % [str(t.get("nazwa", "")), int(t.get("wpisowe_zl", 0))]
		b.custom_minimum_size = Vector2(0, 44)
		var id_t := str(t.get("id", ""))
		b.pressed.connect(func() -> void:
			var w2: Dictionary = sz.graj_turniej(_stan._bohater(), id_t)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
		)
		_ui._tresc_biala().add_child(b)


func _ekran_imprezy() -> void:
	var bohater := _stan._bohater()
	var dep := Depresja.new()
	if dep.blokada_imprez(bohater):
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Kryzys nastroju — imprezy zablokowane (stub).", 15))
		return
	var im := ImprezyUzywki.new()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Imprezy / używki (stub). Wiek %d." % _stan._wiek_lat(), 16))
	for p in im.lista_imprez(_stan._wiek_lat()):
		if not (p is Dictionary):
			continue
		var id_p := str(p.get("id", ""))
		var b1 := Button.new()
		b1.text = "%s (bez picia)" % str(p.get("nazwa", ""))
		b1.custom_minimum_size = Vector2(0, 44)
		b1.pressed.connect(func() -> void:
			var w: Dictionary = im.idz_na_impreze(_stan._bohater(), _swiat, id_p, false)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		_ui._tresc_biala().add_child(b1)
		var b2 := Button.new()
		b2.text = "%s (+ picie stub)" % str(p.get("nazwa", ""))
		b2.custom_minimum_size = Vector2(0, 44)
		b2.pressed.connect(func() -> void:
			var w2: Dictionary = im.idz_na_impreze(_stan._bohater(), _swiat, id_p, true)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		_ui._tresc_biala().add_child(b2)


func _ekran_terapia() -> void:
	var bohater := _stan._bohater()
	var dep := Depresja.new()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Nastrój / terapia (stub). Nie jest to porada medyczna.", 15))
	var st := dep.tekst_stanu(bohater)
	_ui._tresc_biala().add_child(_ui._napis_ekranu(st if st != "" else "Bez flagi depresji.", 15))
	var ie := InteligencjaEmocjonalna.new()
	_ui._tresc_biala().add_child(_ui._napis_ekranu(ie.tekst(bohater), 14))
	for tryb in ["nfz", "prywatna"]:
		var b := Button.new()
		b.text = "Terapia: %s" % tryb
		b.custom_minimum_size = Vector2(0, 44)
		var tryb_b := str(tryb)
		b.pressed.connect(func() -> void:
			var w: Dictionary = dep.terapia(_stan._bohater(), tryb_b)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("terapia", "Terapia / nastrój")
		)
		_ui._tresc_biala().add_child(b)


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
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak auta — kup w Zakupach, potem wróć tu.", 15))
		return
	var kon := KonserwacjaAuta.new()
	var stan_k: Dictionary = {}
	if auto.get("konserwacja") is Dictionary:
		stan_k = auto["konserwacja"]
	else:
		stan_k = kon.stan_startowy()
		auto["konserwacja"] = stan_k
	_ui._tresc_biala().add_child(_ui._napis_ekranu(str(auto.get("nazwa", "Auto")), 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu(kon.tekst_stanu(stan_k), 15))
	for czesc in ["olej", "filtry", "opony"]:
		_ui._tresc_biala().add_child(_pasek_konserwacji(czesc, int(stan_k.get(czesc, 0))))
	var zima_btn := CheckButton.new()
	zima_btn.text = "Konserwacja zimowa"
	zima_btn.button_pressed = bool(stan_k.get("konserwacja_zima", false))
	zima_btn.toggled.connect(func(wl: bool) -> void:
		kon.ustaw_konserwacje_zimowa(stan_k, wl)
		_zapisz_konserwacje_auta(auto, stan_k)
	)
	_ui._tresc_biala().add_child(zima_btn)
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
					var boh := _stan._bohater()
					if int(boh.get("pieniadze", 0)) < koszt:
						_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak kasy na serwis.", 13))
						return
					boh["pieniadze"] = int(boh["pieniadze"]) - koszt
					_swiat["bohater"] = boh
				_zapisz_konserwacje_auta(auto, stan_k)
				_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 13))
				if bool(w.get("ok", false)):
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
			)
			_ui._tresc_biala().add_child(b)
	if bool(stan_k.get("rdza", false)) or bool(stan_k.get("zatarcie", false)):
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Poważne: rdza/zatarcie — warsztat.", 14))
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
				var boh3 := _stan._bohater()
				if bool(w3.get("ok", false)) and int(boh3.get("pieniadze", 0)) >= koszt3:
					boh3["pieniadze"] = int(boh3["pieniadze"]) - koszt3
					_swiat["bohater"] = boh3
					_zapisz_konserwacje_auta(auto, stan_k)
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
				_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w3.get("tekst", "")), 13))
			)
			_ui._tresc_biala().add_child(bw)


func _pasek_konserwacji(nazwa: String, wartosc: int) -> Control:
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 8)
	rzad.add_child(_ui._napis_ekranu(nazwa.capitalize(), 13))
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
	rzad.add_child(_ui._napis_ekranu(str(wartosc), 12))
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
	var bohater := _stan._bohater()
	var lot := SprowadzanieSamolotow.new()
	_ui._tresc_biala().add_child(_ui._napis_ekranu(lot.tekst_ui(bohater), 15))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Sprowadzanie samolotów — stub licencji/hangaru (katalog już jest).", 14))
	for l in lot.lista_licencji():
		if not (l is Dictionary):
			continue
		var b := Button.new()
		b.text = "Licencja: %s" % str(l.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_l := str(l.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = lot.kup_licencje(_stan._bohater(), id_l)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
		)
		_ui._tresc_biala().add_child(b)
	var bh := Button.new()
	bh.text = "Wynajmij hangar (miesiąc stub)"
	bh.custom_minimum_size = Vector2(0, 44)
	bh.pressed.connect(func() -> void:
		var w2: Dictionary = lot.wynajmij_hangar(_stan._bohater())
		_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w2.get("tekst", "")), 14))
		if bool(w2.get("ok", false)):
			_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
	)
	_ui._tresc_biala().add_child(bh)
	var od := lot.sprawdz_odblokowanie_smiglowcow(bohater)
	_ui._tresc_biala().add_child(_ui._napis_ekranu(str(od.get("tekst", "")), 13))


func _ekran_eventy_przyklady() -> void:
	var ev := EventyPrzyklady.new()
	var lista := ev.lista_eventow()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Pakiet eventów: %d (Fala 1+2). Kliknij opcję." % lista.size(), 15))
	for e in lista:
		if not (e is Dictionary):
			continue
		_ui._tresc_biala().add_child(_ui._napis_ekranu("%s — %s" % [str(e.get("nazwa", "")), str(e.get("opis", ""))], 14))
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
					var w: Dictionary = ev.zastosuj_opcje(_stan._bohater(), eid, oid)
					_swiat["bohater"] = _stan._bohater()
					SkryptZapisu.zapisz(_swiat)
					_pasek._odswiez_pasek_statystyk(true)
					_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 13))
				)
				_ui._tresc_biala().add_child(b)


func _ekran_praca_fala2() -> void:
	_ekran_pracy = true
	_praca_filtry_start()
	_rynek_pracy.aktywuj(_swiat, _praca_filtry, int(_swiat.get("tydzien", 1)), _praca_miejsca(), _stan._id_miejsca_pobytu())
	var txt := _rodzina._tekst_pracy()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Praca rodziców: %s" % (txt if txt != "" else "—"), 16))
	var komunikat := str(_swiat.get("praca_komunikat", "")).strip_edges()
	if komunikat != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(komunikat, 16))
	_praca_karta_zatrudnienia()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Ogłoszenia", 18))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Kilka ogłoszeń z wybranego zasięgu. Niżej dochodzą następne. Po kilku tygodniach same znikają.", 16))
	_praca_panel_filtrow()
	var slot := VBoxContainer.new()
	slot.set_meta("praca_slot", true)
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ui._tresc_biala().add_child(slot)
	var fuchy := VBoxContainer.new()
	fuchy.set_meta("praca_fuchy", true)
	fuchy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuchy.add_child(_ui._napis_ekranu("Dorywczo", 18))
	var szkic := PracaSzkielet.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(_stan._bohater().get("sylwetka", {}))
	for p in szkic.prace_dla_wieku(_stan._wiek_lat()):
		if not (p is Dictionary):
			continue
		var b := Button.new()
		b.text = str(p.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		b.add_theme_font_size_override("font_size", 17)
		var id_p := str(p.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = szkic.wykonaj_fuche(_stan._bohater(), id_p, syl)
			if bool(w.get("ok", false)):
				_stan._dodaj_pieniadze(int(w.get("placa", 0)))
				_stan._dodaj_wplyw("fucha", int(w.get("placa", 0)), str(w.get("tekst", "")))
				_swiat["bohater"] = _stan._bohater()
				SkryptZapisu.zapisz(_swiat)
				_pasek._odswiez_pasek_statystyk(true)
			_ui._tresc_biala().add_child(_ui._napis_ekranu(str(w.get("tekst", "")), 16))
		)
		fuchy.add_child(b)
	_ui._tresc_biala().add_child(fuchy)
	_podlacz_scroll_pracy()
	_praca_przerysuj_oferty()


func _praca_miejsca() -> Array:
	if _losowanie == null:
		return []
	return _losowanie.wszystkie_z_ludnoscia()


func _praca_tekst_puli() -> String:
	var poziom := str(_praca_filtry.get("zasieg", "miasto"))
	var karta: Dictionary = _rynek_pracy.miasto_bohatera(_praca_miejsca(), _stan._id_miejsca_pobytu())
	var obszar := "Polska"
	var metro := false
	if poziom == "miasto" or poziom == "wojewodztwo":
		obszar = str(karta.get("wojewodztwo", "Polska"))
		metro = poziom == "miasto" and _rynek_pracy.czy_metropolia(str(karta.get("nazwa", "")))
	var n: int = _rynek_pracy.pula_ofert(
		_rynek_pracy.ludnosc_zakresu(_praca_miejsca(), poziom, _stan._id_miejsca_pobytu()),
		poziom,
		_praca_filtry,
		obszar,
		metro
	)
	return "Ogłoszeń w tym zasięgu: %d" % n


func _praca_filtry_start() -> void:
	if not _praca_filtry.is_empty():
		return
	_praca_filtry = {
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
	var lista: Array = _rynek_pracy.lista_prac(_swiat)
	if lista.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Nie masz etatu.", 16))
		return
	if lista.size() >= 2:
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Masz dwie prace. Zmęczenie fizyczne i obciążenie psychiczne rosną co tydzień.", 16))
	for i in lista.size():
		if lista[i] is Dictionary:
			_praca_jedna_karta(lista[i], i)


func _praca_jedna_karta(praca: Dictionary, indeks: int) -> void:
	var szef: Dictionary = praca.get("szef", {}) if praca.get("szef") is Dictionary else {}
	var karta := VBoxContainer.new()
	karta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	karta.add_theme_constant_override("separation", 6)
	karta.add_child(_ui._napis_ekranu(str(praca.get("nazwa", "Praca")), 18))
	karta.add_child(_ui._napis_ekranu("Płaca: %s zł brutto" % _ui._tekst_z_odstepami(int(praca.get("placa_zl", 0))), 16))
	var pasek := str(praca.get("ostatni_pasek", ""))
	if pasek != "":
		for linia in pasek.split("\n"):
			if str(linia) != "":
				karta.add_child(_ui._napis_ekranu(str(linia), 16))
	var cecha := _nazwa_cechy_szefa(str(szef.get("cecha", "")))
	var linia_szefa := "Kierownik: %s" % _slowa_relacji(int(szef.get("relacja", 50)))
	if cecha != "":
		linia_szefa += ", %s" % cecha
	karta.add_child(_ui._napis_ekranu(linia_szefa, 16))
	karta.add_child(_ui._napis_ekranu("Upomnienia: %s" % _slowa_upomnien(int(praca.get("upomnienia", 0))), 16))
	karta.add_child(_ui._napis_ekranu("Staż tutaj: %d tyg." % int(praca.get("staz_tygodni", 0)), 16))
	var zostalo := int(praca.get("wypowiedzenie_zostalo", 0))
	if zostalo > 0:
		karta.add_child(_ui._napis_ekranu("Zostajesz jeszcze %d tyg." % zostalo, 16))
	karta.add_child(_ui._napis_ekranu("Zaangażowanie", 16))
	var suwak := HSlider.new()
	suwak.min_value = 0
	suwak.max_value = 100
	suwak.step = 5
	suwak.value = int(praca.get("angaz", 50))
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var opis := _ui._napis_ekranu(_slowa_angazu(int(suwak.value)), 16)
	var nr := indeks
	suwak.value_changed.connect(func(v: float) -> void:
		_rynek_pracy.ustaw_angaz(_swiat, int(v), nr)
		opis.text = _slowa_angazu(int(v))
		SkryptZapisu.zapisz(_swiat)
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
	_ui._tresc_biala().add_child(karta)


func _praca_panel_filtrow() -> void:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 6)
	panel.add_child(_ui._napis_ekranu("Zasięg", 16))
	var zasieg := OptionButton.new()
	var nazwy_zasiegu := ["Miasto", "Województwo", "Polska"]
	var kody_zasiegu := ["miasto", "wojewodztwo", "polska"]
	var idx_zasiegu := 0
	for i in nazwy_zasiegu.size():
		zasieg.add_item(nazwy_zasiegu[i], i)
		if kody_zasiegu[i] == str(_praca_filtry.get("zasieg", "miasto")):
			idx_zasiegu = i
	zasieg.select(idx_zasiegu)
	_przycisk_filtra(zasieg)
	zasieg.item_selected.connect(func(idx: int) -> void:
		if _praca_cisza or idx < 0 or idx >= kody_zasiegu.size():
			return
		_praca_filtry["zasieg"] = kody_zasiegu[idx]
		_praca_przeladuj()
	)
	panel.add_child(zasieg)
	_praca_pula_lbl = _ui._napis_ekranu(_praca_tekst_puli(), 16)
	_praca_pula_lbl.set_meta("praca_pula", true)
	panel.add_child(_praca_pula_lbl)
	panel.add_child(_ui._napis_ekranu("Szukaj", 16))
	var pole := LineEdit.new()
	pole.placeholder_text = "Nazwa zawodu"
	pole.text = str(_praca_filtry.get("tekst", ""))
	pole.custom_minimum_size = Vector2(0, 44)
	pole.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pole.add_theme_font_size_override("font_size", 17)
	pole.text_submitted.connect(func(t: String) -> void:
		_praca_filtry["tekst"] = t.strip_edges()
		_praca_przeladuj()
	)
	var szukaj := Button.new()
	szukaj.text = "Szukaj"
	szukaj.custom_minimum_size = Vector2(0, 44)
	szukaj.add_theme_font_size_override("font_size", 17)
	szukaj.pressed.connect(func() -> void:
		_praca_filtry["tekst"] = pole.text.strip_edges()
		_praca_przeladuj()
	)
	panel.add_child(pole)
	panel.add_child(szukaj)
	panel.add_child(_ui._napis_ekranu("Rodzaj", 16))
	var rodzaj := OptionButton.new()
	rodzaj.add_item("Wszystkie", 0)
	var grupy := _praca_grupy()
	var wybrany := 0
	for i in grupy.size():
		var g: Dictionary = grupy[i]
		rodzaj.add_item(str(g.get("nazwa", g.get("kod", ""))), i + 1)
		if str(g.get("kod", "")) == str(_praca_filtry.get("wielka_grupa", "")):
			wybrany = i + 1
	rodzaj.select(wybrany)
	_przycisk_filtra(rodzaj)
	rodzaj.item_selected.connect(func(idx: int) -> void:
		if _praca_cisza:
			return
		if idx <= 0 or idx - 1 >= grupy.size():
			_praca_filtry["wielka_grupa"] = ""
		else:
			_praca_filtry["wielka_grupa"] = str(grupy[idx - 1].get("kod", ""))
		_praca_przeladuj()
	)
	panel.add_child(rodzaj)
	panel.add_child(_ui._napis_ekranu("Wymagane wykształcenie, do", 16))
	var poziomy := [-1, 0, 1, 2, 3]
	var nazwy_poz := ["Bez filtra", "Podstawowe", "Branżowe", "Średnie", "Wyższe"]
	panel.add_child(_praca_opcja(nazwy_poz, poziomy, int(_praca_filtry.get("wyksztalcenie_max", -1)), func(wartosc: int) -> void:
		_praca_filtry["wyksztalcenie_max"] = wartosc
		_praca_przeladuj()
	))
	panel.add_child(_ui._napis_ekranu("Wymagane doświadczenie, do", 16))
	var progi := [-1, 0, 1, 3, 8]
	var nazwy_staz := ["Bez filtra", "Brak", "Krótkie", "Kilkuletnie", "Długie"]
	panel.add_child(_praca_opcja(nazwy_staz, progi, int(_praca_filtry.get("doswiadczenie_max", -1)), func(wartosc: int) -> void:
		_praca_filtry["doswiadczenie_max"] = wartosc
		_praca_przeladuj()
	))
	panel.add_child(_ui._napis_ekranu("Wpływ", 16))
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
			if str(_praca_filtry.get("wplyw_stat", "")) == stat and str(_praca_filtry.get("wplyw_znak", "")) == znak:
				idx_w = k
			k += 1
	opcja_wplywu.select(idx_w)
	_przycisk_filtra(opcja_wplywu)
	opcja_wplywu.item_selected.connect(func(idx: int) -> void:
		if _praca_cisza:
			return
		if idx <= 0 or idx - 1 >= pary.size():
			_praca_filtry["wplyw_stat"] = ""
			_praca_filtry["wplyw_znak"] = ""
		else:
			_praca_filtry["wplyw_stat"] = str(pary[idx - 1].get("stat", ""))
			_praca_filtry["wplyw_znak"] = str(pary[idx - 1].get("znak", ""))
		_praca_przeladuj()
	)
	panel.add_child(opcja_wplywu)
	panel.add_child(_ui._napis_ekranu("Płaca", 16))
	var suwak = SkryptZakresu.new()
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak.custom_minimum_size = Vector2(120, 48)
	suwak.ustaw_zakres(0.0, 20000.0)
	suwak.od = float(_praca_filtry.get("placa_od", 0))
	suwak.dokad = float(_praca_filtry.get("placa_do", 20000))
	var opis_placy := _ui._napis_ekranu("%s–%s zł" % [_ui._tekst_z_odstepami(int(suwak.od)), _ui._tekst_z_odstepami(int(suwak.dokad))], 16)
	suwak.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
		_praca_filtry["filtruj_place"] = true
		_praca_filtry["placa_od"] = int(od)
		_praca_filtry["placa_do"] = int(dokad)
		opis_placy.text = "%s–%s zł" % [_ui._tekst_z_odstepami(int(od)), _ui._tekst_z_odstepami(int(dokad))]
		_praca_przeladuj()
	)
	panel.add_child(opis_placy)
	panel.add_child(suwak)
	_ui._tresc_biala().add_child(panel)


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
		if _praca_cisza or i < 0 or i >= wartosci.size():
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
	var kat = SkryptKataloguZawodow.new()
	kat.wczytaj()
	var grupy: Variant = kat.dane().get("grupy", [])
	if not (grupy is Array):
		return out
	for g in grupy:
		if g is Dictionary and str(g.get("kod", "")).length() == 1:
			out.append(g)
	return out


func _praca_przeladuj() -> void:
	if _praca_cisza or _swiat.is_empty():
		return
	if _swiat.get("rynek_pracy") is Dictionary:
		_swiat["rynek_pracy"]["oferty"] = []
	_rynek_pracy.aktywuj(_swiat, _praca_filtry, int(_swiat.get("tydzien", 1)), _praca_miejsca(), _stan._id_miejsca_pobytu())
	if is_instance_valid(_praca_pula_lbl):
		_praca_pula_lbl.text = _praca_tekst_puli()
	_praca_przerysuj_oferty()
	_praca_wyczysc_slot()


func _praca_przerysuj_oferty() -> void:
	var tresc := _ui._tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if dziecko.has_meta("praca_oferta"):
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	var oferty: Array = []
	if _swiat.get("rynek_pracy") is Dictionary and _swiat["rynek_pracy"].get("oferty") is Array:
		oferty = _swiat["rynek_pracy"]["oferty"]
	var przed: Node = null
	for dziecko in tresc.get_children():
		if dziecko.has_meta("praca_fuchy"):
			przed = dziecko
			break
	if oferty.is_empty():
		var pusty := _ui._napis_ekranu("Brak ogłoszeń w tym filtrze.", 16)
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
	for linia in _rynek_pracy.tekst_ogloszenia(oferta).split("\n"):
		if str(linia) == "":
			continue
		karta.add_child(_ui._napis_ekranu(str(linia), 17))
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
	if _rynek_pracy.lista_prac(_swiat).size() >= 2:
		slot.add_child(_ui._napis_ekranu("Masz już dwie prace. Trzeciej nie weźmiesz.", 16))
		return
	slot.add_child(_ui._napis_ekranu("Chcesz negocjować płacę?", 16))
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
	var band: Dictionary = _rynek_pracy.pasmo(placa)
	if ponownie:
		var wst := _rynek_pracy.wstep_dialogu("ponowna_proba")
		if wst != "":
			slot.add_child(_ui._napis_ekranu(wst, 16))
		slot.add_child(_ui._napis_ekranu(_rynek_pracy.linia_dialogu("ponowna_proba", placa, -1), 16))
	var opis := _ui._napis_ekranu("Żądasz: %s zł" % _ui._tekst_z_odstepami(placa), 16)
	var suwak := HSlider.new()
	suwak.min_value = int(band.get("min_zl", placa))
	suwak.max_value = maxi(int(band.get("max_zl", placa)), int(suwak.min_value) + 1)
	suwak.step = 100
	suwak.value = placa
	suwak.custom_minimum_size = Vector2(0, 36)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak.value_changed.connect(func(v: float) -> void:
		opis.text = "Żądasz: %s zł" % _ui._tekst_z_odstepami(int(v))
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
	var wynik: Dictionary = _rynek_pracy.negocjuj(oferta, _stan._bohater(), negocjuje, zadana, randf())
	var slot := _praca_slot()
	if slot == null:
		return
	_praca_wyczysc_slot()
	var twarda := bool(wynik.get("twarda_odmowa", false))
	var sytuacja := _praca_sytuacja(str(wynik.get("wynik", "")), negocjuje, twarda)
	var placa_oni := int(wynik.get("placa_pracodawcy", oferta.get("placa_zl", 0)))
	if placa_oni <= 0:
		placa_oni = int(oferta.get("placa_zl", 0))
	var wst := _rynek_pracy.wstep_dialogu(sytuacja)
	if wst != "":
		slot.add_child(_ui._napis_ekranu(wst, 16))
	slot.add_child(_ui._napis_ekranu(_rynek_pracy.linia_dialogu(sytuacja, placa_oni, -1), 16))
	if twarda:
		var zamknij := _praca_przycisk("Nie")
		zamknij.pressed.connect(func() -> void:
			_praca_wyczysc_slot()
			var zostaw := _praca_slot()
			if zostaw != null:
				zostaw.add_child(_ui._napis_ekranu("Koniec rozmowy.", 16))
		)
		slot.add_child(zamknij)
		return
	var wybory: Array = wynik.get("wybory", []) if wynik.get("wybory") is Array else _rynek_pracy.wybory_dialogu()
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
			zostaw.add_child(_ui._napis_ekranu("Odchodzisz od tej oferty.", 16))
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
	if _rynek_pracy.lista_prac(_swiat).size() >= 2:
		var slot := _praca_slot()
		if slot != null:
			slot.add_child(_ui._napis_ekranu("Masz już dwie prace. Trzeciej nie weźmiesz.", 16))
		return
	var przyjęta: Dictionary = _rynek_pracy.zatrudnij(_swiat, oferta, placa)
	if not bool(przyjęta.get("ok", true)) and str(przyjęta.get("powod", "")) == "dwie_prace":
		_swiat["praca_komunikat"] = "Masz już dwie prace. Trzeciej nie weźmiesz."
	else:
		_swiat["praca_komunikat"] = "Zaczynasz pracę. Płaca: %s zł brutto." % _ui._tekst_z_odstepami(placa)
	SkryptZapisu.zapisz(_swiat)
	_ui._wyczysc(_ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_przycisk(napis: String) -> Button:
	var b := Button.new()
	b.text = napis
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 17)
	return b


func _praca_popros(indeks: int = 0) -> void:
	var wynik: Dictionary = _rynek_pracy.popros_o_podwyzke(_swiat, randf(), indeks)
	_swiat["praca_komunikat"] = str(wynik.get("tekst", ""))
	SkryptZapisu.zapisz(_swiat)
	_ui._wyczysc(_ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_odejdz(indeks: int = 0) -> void:
	var n: int = _rynek_pracy.odejdz(_swiat, -1.0, indeks)
	_swiat["praca_komunikat"] = "Wypowiedzenie złożone. Zostajesz jeszcze %d tyg." % n
	SkryptZapisu.zapisz(_swiat)
	_ui._wyczysc(_ui._tresc_biala())
	_ekran_praca_fala2()


func _praca_oferta_po_id(id_oferty: String) -> Dictionary:
	if not (_swiat.get("rynek_pracy") is Dictionary):
		return {}
	var oferty: Variant = _swiat["rynek_pracy"].get("oferty", [])
	if not (oferty is Array):
		return {}
	for o in oferty:
		if o is Dictionary and str(o.get("id", "")) == id_oferty:
			return o
	return {}


func _praca_slot() -> VBoxContainer:
	for dziecko in _ui._tresc_biala().get_children():
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
	if _praca_scroll_podpiety:
		return
	var sc := _ekran_zakupow._scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek == null:
		return
	pasek.value_changed.connect(_na_scroll_pracy)
	_praca_scroll_podpiety = true


func _na_scroll_pracy(wartosc: float) -> void:
	if not _ekran_pracy or _praca_dokladka:
		return
	var sc := _ekran_zakupow._scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek == null or pasek.max_value <= sc.size.y + 8.0:
		return
	if not RynekZakupow.trzeba_dociagnac_przed_koncem(pasek.max_value - wartosc - sc.size.y):
		return
	_praca_dokladka = true
	var y := sc.scroll_vertical
	var dodano: int = _rynek_pracy.uzupelnij(_swiat, _praca_filtry, _rynek_pracy.wyprzedzenie(), int(_swiat.get("tydzien", 1)), _praca_miejsca(), _stan._id_miejsca_pobytu())
	if dodano > 0:
		_praca_przerysuj_oferty()
		sc.scroll_vertical = y
		SkryptZapisu.zapisz(_swiat)
	_praca_dokladka = false


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
	_ui._wyczysc(_ui._tresc_biala())
	_ui._tytul_bialy().text = "Pytanie"
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Temat: %s" % temat, 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Rozmówca: %s (wybór stub)" % rozmowca, 15))
	for kto in ["matka", "ojciec"]:
		var b := Button.new()
		b.text = "Zapytaj: %s" % kto
		b.custom_minimum_size = Vector2(0, 44)
		var kto_bind: String = str(kto)
		b.pressed.connect(func() -> void:
			_ui._tresc_biala().add_child(_ui._napis_ekranu("(%s) Odpowiedź stub — pełny system później." % kto_bind, 14))
		)
		_ui._tresc_biala().add_child(b)


## Wejścia zostawione na węźle, bo testy i sygnały wołają je po staremu.
func _tresc_biala() -> VBoxContainer:
	return _ui._tresc_biala()

func _tytul_bialy() -> Label:
	return _ui._tytul_bialy()



## Wejścia zostawione na węźle, bo testy i sygnały wołają je po staremu.
func _wejdz_w_grupe_zakupow(grupa: Dictionary) -> void:
	_ekran_zakupow._wejdz_w_grupe_zakupow(grupa)

func _wejdz_w_kategorie_zakupow(kat: Dictionary) -> void:
	_ekran_zakupow._wejdz_w_kategorie_zakupow(kat)

static func marki_pasujace_do_szukania(marki: Array, zapytanie: String) -> Array:
	return SkryptEkranuZakupow.marki_pasujace_do_szukania(marki, zapytanie)

