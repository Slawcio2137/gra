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

func _init() -> void:
	_ui = SkryptUiWspolne.new(self)
	_stan = SkryptStanuGry.new(self)
	_pasek = SkryptPaska.new(self)
	_tury = SkryptEventowTury.new(self)





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
	if not (_swiat.get("lokum_startowe") is Dictionary) or not _stan._lokum_pelne(_swiat.get("lokum_startowe")):
		_swiat["lokum_startowe"] = _stan._zbuduj_lokum_dla_swiata()
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
	_odswiez_flage_jedzenia_sam()
	_wyplata_kieszonkowego_tydzien()
	_wyplata_kieszonkowego_dziadkow_tydzien()
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
	_odswiez_rynek_zakupow()
	SkryptZapisu.zapisz(_swiat)
	_pasek._odswiez_pasek_statystyk(true)
	_pasek._ukryj_zielony_komunikat_tury()
	_pasek._odswiez_lokalizacje()
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
		rodzina, tryb, true, _swiat.get("kieszonkowe_kwota_zl", null), _stan._wiek_lat()
	)
	if not bool(wynik.get("dodano", false)) or not _ui._jest_liczba(wynik.get("kwota")):
		return
	_stan._dodaj_pieniadze(int(wynik["kwota"]))
	_stan._dodaj_wplyw(str(wynik.get("zrodlo_wplywu", "kieszonkowe")), int(wynik["kwota"]), str(wynik.get("tekst", "")))
	_swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = tydzien
	var tekst := str(wynik.get("tekst", ""))
	_swiat["komunikat_tury"] = tekst
	_swiat["ostatnie_kieszonkowe_tekst"] = tekst


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
	if tresc == "transport" and _auto_z_zapisu() != null:
		return "Ile dni w tygodniu"
	return str(akcja.get("nazwa", ""))


func _wypelnij_ekran(akcja: Dictionary) -> void:
	var tresc := str(akcja.get("tresc", ""))
	var kolor := _ui._kolor(str(akcja.get("kolor", "#9aa7b2")))
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
		_ekran_zakupy()
	elif tresc == "zakupy_grupa":
		var grupa_sl: Variant = akcja.get("grupa", {})
		if grupa_sl is Dictionary:
			_ekran_zakupy_grupa(grupa_sl)
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


func _ekran_dom() -> void:
	var tekst := _tekst_domu()
	if tekst != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(tekst, 20))
	else:
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Dom. Brak nazwy w zapisie.", 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu(_stan._opis_lokalizacji(), 15))


func _ekran_zdrowie() -> void:
	var bohater := _stan._bohater()
	var skrot := str(bohater.get("zdrowie_skrot", ""))
	if skrot != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(skrot, 18))
	else:
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Zdrowie ilościowe pojawi się, gdy będzie w zapisie. Chorób na starcie nie wypisuję.", 16))
	var zdrowie := _ui._tekst_pusty(bohater.get("zdrowie"))
	if zdrowie != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Zdrowie: %s" % zdrowie, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(dep_txt, 15))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Terapia / nastrój — w podmenu Zdrowie.", 14))


func _ekran_postac() -> void:
	var bohater := _stan._bohater()
	var imie := _ui._tekst_pusty(bohater.get("imie"))
	var nazwisko := _ui._tekst_pusty(bohater.get("nazwisko"))
	if imie != "" or nazwisko != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(("%s %s" % [imie, nazwisko]).strip_edges(), 18))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Cechy charakteru", 18))
	var cechy := _cechy_bohatera(bohater)
	_ui._tresc_biala().add_child(_ui._napis_ekranu(cechy if cechy != "" else "—", 16))
	var inteligencje := _inteligencje_bohatera(bohater)
	if inteligencje != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Inteligencja", 18))
		_ui._tresc_biala().add_child(_ui._napis_ekranu(inteligencje, 16))
	var urodzenie := _opis_urodzenia()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Miejsce urodzenia", 18))
	_ui._tresc_biala().add_child(_ui._napis_ekranu(urodzenie if urodzenie != "" else "—", 16))
	var wiek := _ui._tekst_liczby(bohater.get("wiek"))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Wiek: %s" % (wiek if wiek != "" else "—"), 16))
	var psychika := _ui._tekst_liczby(_pasek._wartosc_metryki("psychika"))
	var zm_f := _ui._tekst_liczby(_pasek._wartosc_metryki("zmeczenie_fizyczne"))
	if zm_f == "":
		zm_f = _ui._tekst_liczby(_pasek._wartosc_metryki("zmeczenie"))
	var zm_p := _ui._tekst_liczby(_pasek._wartosc_metryki("zmeczenie_psychiczne"))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Psychika (nastrój): %s" % (psychika if psychika != "" else "—"), 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Zmęczenie fizyczne: %s   Obciążenie psychiczne: %s" % [
		zm_f if zm_f != "" else "—",
		zm_p if zm_p != "" else "—"
	], 16))
	var syl_txt := _opis_sylwetki(bohater)
	if syl_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(syl_txt, 16))
		_ui._tresc_biala().add_child(_pasek_sylwetki(bohater))
	var ie := InteligencjaEmocjonalna.new()
	var ie_txt := ie.tekst(bohater)
	if ie_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(ie_txt, 16))
	var wiedza := _ui._tekst_liczby(bohater.get("wiedza_pkt"))
	if wiedza != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Wiedza (pkt stub): %s" % wiedza, 15))
	var zan_txt := _opis_zainteresowania(bohater)
	if zan_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(zan_txt, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(dep_txt, 14))
	elif bool(bohater.get("depresja", false)):
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Flaga: depresja.", 14))
	# Docelowe tylko w trybie deweloperskim — nigdy na pasku / w normalnej grze.
	if DostepStatystyk.POKAZ_STATYSTYKI:
		var doc_dev := _ui._tekst_liczby(_stan._bohater().get("zadowolenie_docelowe"))
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Docelowe (dev, ukryte): %s" % (doc_dev if doc_dev != "" else "—"), 14))


func _ekran_rodzina() -> void:
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary) or rodzina.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Rodzina nie weszła do zapisu. Spróbuj Start jeszcze raz — jeśli dalej pusto, losowanie padło.", 16))
		return
	var rodzice_box := _dodaj_sekcje_zwijana("rodzice", "Rodzice")
	rodzice_box.add_child(_ui._napis_ekranu("Matka", 18))
	rodzice_box.add_child(_ui._napis_ekranu(_opis_rodzica(rodzina.get("matka")), 16))
	rodzice_box.add_child(_ui._napis_ekranu("Ojciec", 18))
	rodzice_box.add_child(_ui._napis_ekranu(_opis_rodzica(rodzina.get("ojciec")), 16))
	var dziadkowie_box := _dodaj_sekcje_zwijana("dziadkowie", "Dziadkowie")
	_wypelnij_dziadkow(dziadkowie_box, rodzina.get("dziadkowie"))
	var prosba_d := Button.new()
	prosba_d.text = "Poproś dziadków o kieszonkowe"
	prosba_d.custom_minimum_size = Vector2(0, 48)
	prosba_d.pressed.connect(_on_kieszonkowe_dziadkowie)
	_ui._tresc_biala().add_child(prosba_d)
	var wynik_d := _ui._napis_ekranu(str(_swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")), 15)
	wynik_d.visible = str(_swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")) != ""
	_ui._tresc_biala().add_child(wynik_d)
	var zarobki := _tekst_zarobkow(rodzina.get("zarobki"))
	var etykieta_gosp := "Zarobki rodziny (suma rodziców)"
	if rodzina.get("zarobki") is Dictionary and str(rodzina["zarobki"].get("dochód_gospodarstwa", "")) == "suma_przedzialow_rodzicow":
		etykieta_gosp = "Zarobki gospodarstwa (suma przedziałów matki i ojca)"
	if zarobki == "" and rodzina.get("zarobki") is Dictionary:
		var powod := str(rodzina["zarobki"].get("powod", ""))
		_ui._tresc_biala().add_child(_ui._napis_ekranu("%s: —%s" % [etykieta_gosp, ((" (%s)" % powod) if powod != "" else "")], 16))
	else:
		_ui._tresc_biala().add_child(_ui._napis_ekranu("%s: %s" % [etykieta_gosp, zarobki if zarobki != "" else "—"], 16))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(opis_lokum, 16))
	else:
		var dom := _tekst_domu()
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Dom: %s" % (dom if dom != "" else "brak lokum w zapisie"), 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Rodzeństwo", 18))
	var rodzenstwo: Variant = _swiat.get("rodzenstwo", [])
	if not (rodzenstwo is Array) or rodzenstwo.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak rodzeństwa (wylosowano 0).", 16))
	else:
		var nr := 1
		for osoba in rodzenstwo:
			if not (osoba is Dictionary):
				continue
			_ui._tresc_biala().add_child(_ui._napis_ekranu(_opis_rodzenstwa(osoba, nr), 16))
			nr += 1
	var ziarno_ui := ZiarnoRodzicow.new()
	var tryb_id := str(_swiat.get("tryb_kieszonkowego", ""))
	var aktywne := bool(_swiat.get("kieszonkowe_aktywne", false))
	var tryb_etykieta := ziarno_ui.etykieta_trybu_kieszonkowego(tryb_id) if aktywne else "jeszcze nie proszono"
	var linia_kiesz := "Kieszonkowe: %s" % tryb_etykieta
	if aktywne and (tryb_id == "stala_kwota" or tryb_id == "stale_daje"):
		if _ui._jest_liczba(_swiat.get("kieszonkowe_kwota_zl")):
			var kwota_k := int(ZaokraglenieZarobkow.zaokraglij(_swiat["kieszonkowe_kwota_zl"]))
			_swiat["kieszonkowe_kwota_zl"] = kwota_k
			linia_kiesz += " · %d zł/tydzień" % kwota_k
		else:
			linia_kiesz += " · kwota tygodniowa: —"
	_ui._tresc_biala().add_child(_ui._napis_ekranu(linia_kiesz, 16))
	var prosba := Button.new()
	prosba.text = "Poproś o kieszonkowe"
	prosba.custom_minimum_size = Vector2(0, 48)
	prosba.pressed.connect(_on_kieszonkowe)
	_ui._tresc_biala().add_child(prosba)
	var podwyzka := Button.new()
	podwyzka.text = "Poproś o podniesienie kieszonkowego"
	podwyzka.custom_minimum_size = Vector2(0, 48)
	podwyzka.disabled = not aktywne
	podwyzka.pressed.connect(_on_kieszonkowe_podwyzka)
	_ui._tresc_biala().add_child(podwyzka)
	var jednoraz := Button.new()
	jednoraz.text = "Poproś o pieniądze na coś"
	jednoraz.custom_minimum_size = Vector2(0, 48)
	jednoraz.pressed.connect(_on_pieniadze_jednorazowo)
	_ui._tresc_biala().add_child(jednoraz)
	var wynik_lbl := _ui._napis_ekranu(str(_swiat.get("ostatnie_kieszonkowe_tekst", "")), 15)
	wynik_lbl.name = "WynikKieszonkowego"
	wynik_lbl.visible = str(_swiat.get("ostatnie_kieszonkowe_tekst", "")) != ""
	_ui._tresc_biala().add_child(wynik_lbl)


## Nagłówek zwija wiersze. Domyślnie zwinięte. Ludzie zostają w drzewie, tylko hidden.
func _dodaj_sekcje_zwijana(id_sekcji: String, tytul: String) -> VBoxContainer:
	var naglowek := Button.new()
	naglowek.text = "%s ▸" % tytul
	naglowek.alignment = HORIZONTAL_ALIGNMENT_LEFT
	naglowek.custom_minimum_size = Vector2(0, 48)
	naglowek.add_theme_font_size_override("font_size", 18)
	naglowek.set_meta("sekcja_rodziny", id_sekcji)
	naglowek.focus_mode = Control.FOCUS_NONE
	var pudelko := VBoxContainer.new()
	pudelko.visible = false
	pudelko.set_meta("tresc_sekcji", id_sekcji)
	pudelko.add_theme_constant_override("separation", 6)
	pudelko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	naglowek.pressed.connect(func() -> void:
		pudelko.visible = not pudelko.visible
		naglowek.text = ("%s ▾" % tytul) if pudelko.visible else ("%s ▸" % tytul)
	)
	_ui._tresc_biala().add_child(naglowek)
	_ui._tresc_biala().add_child(pudelko)
	return pudelko


func _wypelnij_dziadkow(pudelko: VBoxContainer, blok: Variant) -> void:
	if not (blok is Dictionary):
		pudelko.add_child(_ui._napis_ekranu("Brak w zapisie (Start jeszcze raz).", 16))
		return
	var lista: Variant = blok.get("lista", [])
	if not (lista is Array) or lista.is_empty():
		pudelko.add_child(_ui._napis_ekranu("Brak żyjących dziadków w wylosowanym zestawie.", 16))
		return
	for o in lista:
		if not (o is Dictionary):
			continue
		pudelko.add_child(_ui._napis_ekranu(_etykieta_roli_dziadka(str(o.get("rola", ""))), 16))
		pudelko.add_child(_ui._napis_ekranu(_opis_rodzica(o), 15))


func _etykieta_roli_dziadka(rola: String) -> String:
	match rola:
		"babcia_matki":
			return "Babcia (linia matki)"
		"dziadek_matki":
			return "Dziadek (linia matki)"
		"babcia_ojca":
			return "Babcia (linia ojca)"
		"dziadek_ojca":
			return "Dziadek (linia ojca)"
		_:
			return "Dziadek / babcia" if rola == "" else rola


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
		_ui._tresc_biala().add_child(_ui._napis_ekranu(pusto, 16))
		return
	var nr := 1
	for osoba in lista:
		if not (osoba is Dictionary):
			continue
		var cechy := _cechy_listy_z_karty(osoba)
		var plec := _ui._nazwa_pola(osoba.get("plec"))
		var linia := "%d. %s" % [nr, plec if plec != "" else "osoba"]
		if cechy != "":
			linia += " — %s" % cechy
		_ui._tresc_biala().add_child(_ui._napis_ekranu(linia, 16))
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
		var nazwa := _ui._nazwa_pola(pozycja)
		if nazwa == "" and pozycja is String:
			nazwa = str(pozycja)
		if nazwa != "":
			nazwy.append(nazwa)
	return ", ".join(nazwy)


func _cechy_listy_z_karty(karta: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while karta.has("cecha_%d" % numer):
		var nazwa := _ui._nazwa_pola(karta["cecha_%d" % numer])
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
	var boh := _stan._bohater()
	if boh.get("inteligencja") is Array and not (boh["inteligencja"] as Array).is_empty():
		inteligencja = 2
	elif _ui._jest_liczba(boh.get("inteligencja")):
		inteligencja = clampi(int(boh["inteligencja"]) / 33, 0, 3)
	var wynik: Dictionary = dziad.popros_o_kieszonkowe(
		stan_d, rodzina, inteligencja, int(_swiat.get("tydzien", 0)), false
	)
	rodzina["dziadkowie"] = stan_d
	_swiat["rodzina"] = rodzina
	_swiat["ostatnie_kieszonkowe_dziadkowie_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and _ui._jest_liczba(wynik.get("kwota")):
		_stan._dodaj_pieniadze(int(wynik["kwota"]))
		_stan._dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	SkryptZapisu.zapisz(_swiat)
	_pasek._odswiez_pasek_statystyk(true)
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
	if bool(wynik.get("ok", false)) and _ui._jest_liczba(wynik.get("kwota")):
		_stan._dodaj_pieniadze(int(wynik["kwota"]))
		_stan._dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
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
	var wynik: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, tryb_teraz, pierwsza, _stan._wiek_lat())
	_swiat["kieszonkowe_pierwsza_rozmowa"] = false
	_swiat["ostatnie_kieszonkowe"] = wynik
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and _ui._jest_liczba(wynik.get("kwota")):
		_stan._dodaj_pieniadze(int(wynik["kwota"]))
		_stan._dodaj_wplyw("kieszonkowe", int(wynik["kwota"]), str(wynik.get("tekst", "")))
		_swiat["tryb_kieszonkowego"] = "stala_kwota"
		_swiat["kieszonkowe_aktywne"] = true
		_swiat["kieszonkowe_kwota_zl"] = int(wynik["kwota"])
		_swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = int(_swiat.get("tydzien", 0))
	elif str(wynik.get("powod", "")) == "wiek_ponizej_progu" or str(wynik.get("tryb", "")) == "odmowa":
		if str(wynik.get("tryb", "")) == "odmowa":
			_swiat["tryb_kieszonkowego"] = "odmowa"
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	SkryptZapisu.zapisz(_swiat)
	_pasek._odswiez_pasek_statystyk(true)
	_zaplanuj_stos()


func _on_kieszonkowe_podwyzka() -> void:
	if _swiat.is_empty() or not bool(_swiat.get("kieszonkowe_aktywne", false)):
		return
	var rodzina: Variant = _swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.popros_o_podwyzke_kieszonkowego(
		rodzina, _swiat.get("kieszonkowe_kwota_zl", null), _stan._wiek_lat()
	)
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and _ui._jest_liczba(wynik.get("kwota")):
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
	var wynik: Dictionary = ziarno.popros_o_pieniadze_jednorazowo(rodzina, _stan._wiek_lat())
	_swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and _ui._jest_liczba(wynik.get("kwota")):
		_stan._dodaj_pieniadze(int(wynik["kwota"]))
		_stan._dodaj_wplyw("pieniadze_jednorazowo", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	_swiat["jedzenie"] = _jedzenie.zrzut_zapisu()
	SkryptZapisu.zapisz(_swiat)
	_pasek._odswiez_pasek_statystyk(true)
	_zaplanuj_stos()


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
	if cfg is Dictionary and _ui._jest_liczba(cfg.get("prog_wiek_lat")):
		prog = int(cfg["prog_wiek_lat"])
	var wiek: Variant = _stan._wiek_lat()
	return _ui._jest_liczba(wiek) and int(wiek) >= prog


func _odswiez_flage_jedzenia_sam() -> void:
	if bool(_swiat.get("odblokowane_jedzenie_samemu", false)):
		return
	if _czy_jedzenie_sam_po_wieku():
		_swiat["odblokowane_jedzenie_samemu"] = true


func _ekran_majatek() -> void:
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Pieniądze", 18))
	var kwota := _stan._pieniadze_tekst()
	_ui._tresc_biala().add_child(_ui._napis_ekranu(kwota if kwota != "" else "—", 18))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(opis_lokum, 16))
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Nieruchomości", 18))
	var maj: Dictionary = _swiat.get("majatek", {}) if _swiat.get("majatek") is Dictionary else {}
	var n_lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if n_lista.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Własne kupione: brak — kup w Zakupach (generator, nie katalog 200).", 14))
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
			_ui._tresc_biala().add_child(_ui._napis_ekranu(linia, 14))
			var idx_bind := i
			var b_rem := Button.new()
			b_rem.text = "Remont (propozycja koszt/wygoda)"
			b_rem.custom_minimum_size = Vector2(0, 40)
			b_rem.pressed.connect(func() -> void:
				var wynik: Dictionary = _rynek_zakupow.remont(_swiat, idx_bind)
				if bool(wynik.get("ok", false)):
					_rynek_zakupow.przelicz_zadowolenie_docelowe(_swiat)
					SkryptZapisu.zapisz(_swiat)
					_stan._zsynchronizuj_pieniadze_z_bohatera()
					_pasek._odswiez_pasek_statystyk(false)
					_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
				else:
					_ui._tresc_biala().add_child(_ui._napis_ekranu(str(wynik.get("powod", "Remont nieudany.")), 13))
			)
			_ui._tresc_biala().add_child(b_rem)
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Dobra", 18))
	var d_lista: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if d_lista.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Pusto.", 14))
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
				_ui._tresc_biala().add_child(_ui._napis_ekranu(linia_a, 14))
				if bool(d.get("nie_jezdzi", false)) or bool(d.get("do_naprawy", false)):
					_ui._tresc_biala().add_child(_panel_awarii_auta(i_d, d))
			else:
				var linia_d := nazwa_d
				if _rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var plus_d := _rynek_zakupow.tekst_plusow(_rynek_zakupow.plusy_oferty(d))
					if plus_d != "":
						linia_d += " · " + plus_d
				_ui._tresc_biala().add_child(_ui._napis_ekranu(linia_d, 14))
				if _rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var b_oddaj := Button.new()
					b_oddaj.text = "Oddaj"
					b_oddaj.custom_minimum_size = Vector2(0, 40)
					var idx_d := i_d
					b_oddaj.pressed.connect(func() -> void:
						var wynik_o: Dictionary = _rynek_zakupow.oddaj_dobro(_swiat, idx_d)
						if bool(wynik_o.get("ok", false)):
							SkryptZapisu.zapisz(_swiat)
							_otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
					)
					_ui._tresc_biala().add_child(b_oddaj)
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Wpływy", 18))
	var lista: Variant = _swiat.get("wplywy", [])
	if not (lista is Array) or lista.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak wpływów.", 15))
		return
	var od := maxi(0, lista.size() - 12)
	for i in range(od, lista.size()):
		var wpis: Variant = lista[i]
		if not (wpis is Dictionary):
			continue
		var linia2 := str(wpis.get("tekst", ""))
		if linia2 == "" and _ui._jest_liczba(wpis.get("kwota")):
			linia2 = "%s: +%d zł" % [str(wpis.get("zrodlo", "wpływ")), int(wpis["kwota"])]
		if linia2 != "":
			_ui._tresc_biala().add_child(_ui._napis_ekranu(linia2, 15))


func _ekran_zakupy() -> void:
	_odswiez_rynek_zakupow()
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Zakupy — losowane oferty (limit miasta × tura). Nie arkusz strategii.", 16))
	var dane := _wczytaj_zakupy_oferty()
	var kategorie: Variant = dane.get("kategorie", []) if dane is Dictionary else []
	if not (kategorie is Array) or kategorie.is_empty():
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak kategorii w danych.", 16))
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
	_ui._tresc_biala().add_child(przycisk)


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
	_ui._tresc_biala().add_child(przycisk)


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
	if _akcje_po_id.has("zakupy") and _akcje_po_id["zakupy"] is Dictionary:
		var z: Dictionary = (_akcje_po_id["zakupy"] as Dictionary).duplicate(true)
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
	_otworz_akcje(akcja)


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
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Brak wyborów w tej kategorii.", 16))
		return
	var uwaga := str(grupa.get("uwaga", "")).strip_edges()
	if uwaga != "":
		_ui._tresc_biala().add_child(_ui._napis_ekranu(uwaga, 14))
	for id_k in ids:
		var sid := str(id_k)
		if not po_id.has(sid):
			_ui._tresc_biala().add_child(_ui._napis_ekranu(
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
		_otworz_akcje({
			"id": "zakupy_kat_drobiazgi",
			"nazwa": str(kat.get("nazwa", "Drobiazgi")),
			"tryb": "ekran",
			"tresc": "zakupy_kategoria",
			"kat": kat,
			"kolor": str(zakupy.get("kolor", "#b0a04a")),
			"sciezka_rodzicow": rodzice,
		})
		return
	_otworz_akcje({
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
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Budżet jakości drobiazgów (propozycja; szansa zdarzenia nadal null).", 14))
	var budzet: Dictionary = {}
	if FileAccess.file_exists(PLIK_DROBIAZGOW):
		var plik := FileAccess.open(PLIK_DROBIAZGOW, FileAccess.READ)
		if plik != null:
			var dane_d: Variant = JSON.parse_string(plik.get_as_text())
			if dane_d is Dictionary and dane_d.get("budzet_jakosci") is Dictionary:
				budzet = dane_d["budzet_jakosci"]
	var min_zl := int(budzet.get("min_zl", 0)) if _ui._jest_liczba(budzet.get("min_zl")) else 0
	var max_zl := int(budzet.get("max_zl", 100)) if _ui._jest_liczba(budzet.get("max_zl")) else 100
	var krok := int(budzet.get("krok_zl", 5)) if _ui._jest_liczba(budzet.get("krok_zl")) else 5
	var wartosc := int(_swiat.get("budzet_jakosci_drobiazgow_zl", budzet.get("domyslnie_zl", 0)))
	var opis := _ui._napis_ekranu("Przeznaczam: %d zł" % wartosc, 16)
	_ui._tresc_biala().add_child(opis)
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
	_ui._tresc_biala().add_child(suwak)


func _ekran_zakupy_oferty(kat_id: String, stan_filtr: String, kat: Dictionary) -> void:
	_ui._wyczysc(_ui._tresc_biala())
	_ui._wyczysc(_ui._dol_suwaka())
	_ui._dol_suwaka().hide()
	_ui._tytul_bialy().text = str(kat.get("nazwa", kat_id))
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
		if o is Dictionary and _ui._jest_liczba(o.get("cena_zl")):
			ceny.append(float(o["cena_zl"]))
	ceny.sort()
	if _rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		_ui._tresc_biala().add_child(_ui._napis_ekranu(
			"Ogłoszenia wczytują się przy wejściu i po kilka przy przewijaniu.",
			17
		))
	_zakupy_pula_lbl = _ui._napis_ekranu("", 16)
	_ui._tresc_biala().add_child(_zakupy_pula_lbl)
	# Filtr u góry — po wejściu w kategorię rozwinięty (widać min–max od razu).
	var przycisk_filtr := Button.new()
	przycisk_filtr.text = "Filtr ▾"
	przycisk_filtr.alignment = HORIZONTAL_ALIGNMENT_LEFT
	przycisk_filtr.custom_minimum_size = Vector2(0, 44)
	przycisk_filtr.add_theme_font_size_override("font_size", 17)
	_ui._tresc_biala().add_child(przycisk_filtr)
	var panel_filtr := VBoxContainer.new()
	panel_filtr.visible = true
	panel_filtr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_filtr.add_theme_constant_override("separation", 8)
	_ui._tresc_biala().add_child(panel_filtr)
	przycisk_filtr.pressed.connect(func() -> void:
		_zakupy_filtr_rozwiniety = not _zakupy_filtr_rozwiniety
		panel_filtr.visible = _zakupy_filtr_rozwiniety
		przycisk_filtr.text = "Filtr ▾" if _zakupy_filtr_rozwiniety else "Filtr ▸"
	)
	# Cena min–max: liczniki obok siebie (poziomo), nie jeden pod drugim.
	var rzad_licz := HBoxContainer.new()
	rzad_licz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rzad_licz.add_theme_constant_override("separation", 16)
	_zakupy_licznik_od = _ui._napis_ekranu("min: —", 17)
	_zakupy_licznik_do = _ui._napis_ekranu("max: —", 17)
	_zakupy_licznik_od.autowrap_mode = TextServer.AUTOWRAP_OFF
	_zakupy_licznik_do.autowrap_mode = TextServer.AUTOWRAP_OFF
	_zakupy_licznik_od.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_zakupy_licznik_do.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rzad_licz.add_child(_zakupy_licznik_od)
	rzad_licz.add_child(_zakupy_licznik_do)
	panel_filtr.add_child(rzad_licz)
	if ceny.is_empty():
		panel_filtr.add_child(_ui._napis_ekranu("Przedział cen: — (brak liczb; filtr nie zmyśla).", 16))
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
	panel_filtr.add_child(_ui._napis_ekranu("Zasięg szukania:", 17))
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
	var opis_z := _ui._napis_ekranu("Strop odległości: %d km" % int(_zakupy_zasieg_km), 16)
	var suwak_z := HSlider.new()
	suwak_z.min_value = zmin
	suwak_z.max_value = zmax
	suwak_z.step = 1.0
	suwak_z.value = _zakupy_zasieg_km
	opcje_zas.item_selected.connect(func(idx: int) -> void:
		if idx < 0 or idx >= poziomy_zas.size():
			return
		var p0: Variant = poziomy_zas[idx]
		if p0 is Dictionary:
			_zakupy_zasieg_poziom = str(p0.get("id", "miasto"))
			var mx := float(p0.get("max_km", _zakupy_zasieg_km))
			_zakupy_zasieg_km = mx
			opis_z.text = "Strop odległości: %d km" % int(mx)
			if suwak_z.max_value < mx:
				suwak_z.max_value = mx
			suwak_z.set_value_no_signal(mx)
		_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(opcje_zas)
	panel_filtr.add_child(opis_z)
	suwak_z.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suwak_z.custom_minimum_size = Vector2(0, 36)
	suwak_z.value_changed.connect(func(v: float) -> void:
		_zakupy_zasieg_km = v
		opis_z.text = "Strop odległości: %d km" % int(v)
		_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
	)
	panel_filtr.add_child(suwak_z)
	# Dom i mieszkanie: ten sam wybór Nowe / Używane co przy aucie. Nowe = wykończone i stan surowy.
	if _rynek_zakupow.kategoria_ma_nowe_lokum(kat_id):
		panel_filtr.add_child(_ui._napis_ekranu("Stan:", 17))
		var opcje_lok := OptionButton.new()
		opcje_lok.add_item("Wszystkie", 0)
		opcje_lok.add_item("Używane", 1)
		opcje_lok.add_item("Nowe", 2)
		var idx_lok := 0
		if _zakupy_stan_filtr == "uzywany":
			idx_lok = 1
		elif _zakupy_stan_filtr == "nowy":
			idx_lok = 2
		opcje_lok.select(idx_lok)
		opcje_lok.custom_minimum_size = Vector2(0, 40)
		opcje_lok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		opcje_lok.add_theme_font_size_override("font_size", 17)
		opcje_lok.item_selected.connect(func(idx: int) -> void:
			match idx:
				1:
					_zakupy_stan_filtr = "uzywany"
				2:
					_zakupy_stan_filtr = "nowy"
				_:
					_zakupy_stan_filtr = ""
			_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		)
		panel_filtr.add_child(opcje_lok)
	# Ruchome: stan używany/nowy + odbiór osobisty/wysyłka. Budynki: cena, odległość i stan rynku.
	_zakupy_filtr_odbior = ""
	if not nieruchomosc:
		if uzywany_nowy:
			panel_filtr.add_child(_ui._napis_ekranu("Stan:", 17))
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
		panel_filtr.add_child(_ui._napis_ekranu("Odbiór osobisty:", 17))
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
		panel_filtr.add_child(_ui._napis_ekranu("Sortuj cenę:", 17))
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
			if o is Dictionary and _ui._jest_liczba(o.get("przebieg_km")):
				przebiegi.append(float(o["przebieg_km"]))
		przebiegi.sort()
		panel_filtr.add_child(_ui._napis_ekranu("Przebieg (km):", 17))
		var rzad_p := HBoxContainer.new()
		rzad_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rzad_p.add_theme_constant_override("separation", 16)
		_zakupy_licznik_przebieg_od = _ui._napis_ekranu("min: —", 17)
		_zakupy_licznik_przebieg_do = _ui._napis_ekranu("max: —", 17)
		_zakupy_licznik_przebieg_od.autowrap_mode = TextServer.AUTOWRAP_OFF
		_zakupy_licznik_przebieg_do.autowrap_mode = TextServer.AUTOWRAP_OFF
		rzad_p.add_child(_zakupy_licznik_przebieg_od)
		rzad_p.add_child(_zakupy_licznik_przebieg_do)
		panel_filtr.add_child(rzad_p)
		if przebiegi.is_empty():
			panel_filtr.add_child(_ui._napis_ekranu("Przedział przebiegu: — (brak liczb).", 16))
			_zakupy_filtr_przebiegu_wlaczony = false
		else:
			var suwak_p = SkryptZakresu.new()
			suwak_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			suwak_p.custom_minimum_size = Vector2(120, 48)
			suwak_p.ustaw_zakres(float(przebiegi[0]), float(przebiegi[przebiegi.size() - 1]))
			_zakupy_przebieg_od = suwak_p.od
			_zakupy_przebieg_do = suwak_p.dokad
			_zakupy_filtr_przebiegu_wlaczony = true
			_zakupy_licznik_przebieg_od.text = _ui._tekst_przebiegu_zakresu("min", _zakupy_przebieg_od)
			_zakupy_licznik_przebieg_do.text = _ui._tekst_przebiegu_zakresu("max", _zakupy_przebieg_do)
			suwak_p.zakres_zmieniony.connect(func(od: float, dokad: float) -> void:
				_zakupy_przebieg_od = od
				_zakupy_przebieg_do = dokad
				_zakupy_filtr_przebiegu_wlaczony = true
				if _zakupy_licznik_przebieg_od != null and is_instance_valid(_zakupy_licznik_przebieg_od):
					_zakupy_licznik_przebieg_od.text = _ui._tekst_przebiegu_zakresu("min", od)
				if _zakupy_licznik_przebieg_do != null and is_instance_valid(_zakupy_licznik_przebieg_do):
					_zakupy_licznik_przebieg_do.text = _ui._tekst_przebiegu_zakresu("max", dokad)
				_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
			)
			panel_filtr.add_child(suwak_p)
		panel_filtr.add_child(_ui._napis_ekranu("Marki (kilka naraz; puste = wszystkie):", 17))
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
		panel_nowe.add_child(_ui._napis_ekranu("Napęd (nowe):", 17))
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
	_podlacz_scroll_aut()
	_przerysuj_liste_zakupow(kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)


func _przerysuj_liste_zakupow(kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	if not _zakupy_dokladka:
		if kat_id == "samochod":
			_uzupelnij_aut_do_okna(stan_filtr)
		elif _rynek_zakupow.kategoria_drobna(kat_id):
			_uzupelnij_dobra_do_okna()
		elif _rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
			_uzupelnij_lokum_do_okna()
	_odswiez_napis_puli_zakupow(kat_id)
	var tresc := _ui._tresc_biala()
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
	var stan_listy := stan_filtr if (not nieruchomosc or _rynek_zakupow.kategoria_ma_nowe_lokum(kat_id)) else ""
	var z_poziomem := kat_id == "samochod" or nieruchomosc or _rynek_zakupow.kategoria_drobna(kat_id)
	var oferty := _rynek_zakupow.oferty_filtrowane(
		_swiat,
		kat_id,
		stan_listy,
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
		_zakupy_zasieg_poziom if z_poziomem else "",
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
		var pusto := _ui._napis_ekranu("Brak ofert w tym filtrze.", 16)
		pusto.set_meta("zakupy_oferta", true)
		tresc.add_child(pusto)
		_dodaj_przycisk_kolejnych_zakupow(tresc, kat_id)
		return
	for o in oferty:
		if not (o is Dictionary):
			continue
		var wiersz := _buduj_skrot_karty_oferty(o, kat_id, stan_filtr, etykiety, nieruchomosc)
		tresc.add_child(wiersz)
		_zakupy_wiersze.append({"cena": o.get("cena_zl"), "wezel": wiersz})
	_dodaj_przycisk_kolejnych_zakupow(tresc, kat_id)
	if not _zakupy_dokladka:
		_zakupy_prefetch_kroki = 0
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
	if _rynek_zakupow.kategoria_drobna(kat_id):
		for linia_d in _rynek_zakupow.linie_karty_drobiazgu(o):
			wiersz.add_child(_ui._napis_ekranu(str(linia_d), 17))
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
	var cena_txt := _ui._tekst_ceny_oferty(o.get("cena_zl"), kat_id)
	if nieruchomosc:
		wiersz.add_child(_ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 17))
		wiersz.add_child(_ui._napis_ekranu(_rynek_zakupow.tekst_karty_miejsca(o), 16))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(_ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 17))
		var odbior_skrot := _rynek_zakupow.tekst_odbioru_auta(o) if kat_id == "samochod" else _etykieta_odbioru(str(o.get("sposob_odbioru", "")))
		wiersz.add_child(_ui._napis_ekranu(_rynek_zakupow.tekst_karty_miejsca(o, odbior_skrot), 16))
		if kat_id == "samochod" and _ui._jest_liczba(o.get("przebieg_km")):
			wiersz.add_child(_ui._napis_ekranu("Przebieg: %s km" % _ui._tekst_z_odstepami(int(o["przebieg_km"])), 16))
		elif _ui._jest_liczba(o.get("lata_od_zakupu")):
			wiersz.add_child(_ui._napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(_ui._napis_ekranu("Segment: %s" % str(o["segment"]), 15))
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
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Oferta zniknęła z puli (sprzedana lub odświeżona).", 17))
		return
	_ui._tytul_bialy().text = str(oferta.get("nazwa", "Oferta"))
	_ui._tresc_biala().add_child(_buduj_pelna_karte_oferty(oferta, kat_id, stan_filtr, etykiety, nieruchomosc))


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
	var cena_txt := _ui._tekst_ceny_oferty(cena_v, kat_id)
	if _rynek_zakupow.kategoria_drobna(kat_id):
		for linia_d in _rynek_zakupow.linie_karty_drobiazgu(o):
			wiersz.add_child(_ui._napis_ekranu(str(linia_d), 18))
	elif nieruchomosc:
		wiersz.add_child(_ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_txt, cena_txt], 18))
		wiersz.add_child(_ui._napis_ekranu(_rynek_zakupow.tekst_karty_miejsca(o), 16))
	else:
		var stan_karty := stan_txt
		if kat_id == "samochod":
			stan_karty = "stan: nowy" if str(o.get("stan", "")) == "nowy" else "stan: używany"
		wiersz.add_child(_ui._napis_ekranu("%s · %s · %s" % [nazwa, stan_karty, cena_txt], 18))
		var odbior_skrot := _rynek_zakupow.tekst_odbioru_auta(o) if kat_id == "samochod" else _etykieta_odbioru(str(o.get("sposob_odbioru", "")))
		wiersz.add_child(_ui._napis_ekranu(_rynek_zakupow.tekst_karty_miejsca(o, odbior_skrot), 16))
		if _ui._jest_liczba(o.get("lata_od_zakupu")) and kat_id != "samochod":
			wiersz.add_child(_ui._napis_ekranu("Lata od zakupu: %d" % int(o["lata_od_zakupu"]), 16))
		if str(o.get("segment", "")) != "":
			wiersz.add_child(_ui._napis_ekranu("Segment: %s" % str(o["segment"]), 16))
		if o.get("czas_oczekiwania") is Dictionary and not (o["czas_oczekiwania"] as Dictionary).is_empty():
			var cz: Dictionary = o["czas_oczekiwania"]
			wiersz.add_child(_ui._napis_ekranu(
				"Czas oczekiwania (fabryka): %d lat + %d tyg." % [int(cz.get("lata", 0)), int(cz.get("tygodnie", 0))],
				16
			))
		if kat_id == "samochod":
			if _ui._jest_liczba(o.get("przebieg_km")):
				wiersz.add_child(_ui._napis_ekranu("Przebieg: %s km" % _ui._tekst_z_odstepami(int(o["przebieg_km"])), 16))
			var naped_txt := _rynek_zakupow.etykieta_napedu(str(o.get("naped", "")))
			if naped_txt != "":
				wiersz.add_child(_ui._napis_ekranu("Napęd: %s" % naped_txt, 16))
			wiersz.add_child(_ui._napis_ekranu("Spalanie: %s" % _rynek_zakupow.tekst_spalania(o), 16))
			if bool(o.get("sprowadzenie", false)) or bool(o.get("import", false)):
				var spr_txt := "Sprowadzenie / import"
				if bool(o.get("szacunek_ceny", false)):
					spr_txt += " (szacunek ceny)"
				var zrd := str(o.get("zrodlo_cennika", ""))
				if zrd != "":
					spr_txt += " · źródło: %s" % zrd
				wiersz.add_child(_ui._napis_ekranu(spr_txt, 16))
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
				wiersz.add_child(_ui._napis_ekranu("Prędkość maksymalna: %s km/h" % vmax_ui, 16))
			if bool(o.get("nie_jezdzi", false)) or bool(o.get("do_naprawy", false)):
				wiersz.add_child(_ui._napis_ekranu("Nie jeździ — do naprawy (laweta / mechanik / złom).", 16))
		var dek_u: Array = o.get("usterki_deklarowane", []) if o.get("usterki_deklarowane") is Array else []
		var wyk_u: Array = o.get("usterki_wykryte", []) if o.get("usterki_wykryte") is Array else []
		var seg_u := str(o.get("segment", ""))
		if not dek_u.is_empty():
			var linia_dek := "Usterki (sprzedawca): %s" % _ui._join_tekstow(_rynek_zakupow.nazwy_usterek(dek_u, kat_id, seg_u))
			if bool(o.get("szacunek_usterek", false)):
				linia_dek += " (szacunek)"
			wiersz.add_child(_ui._napis_ekranu(linia_dek, 16))
		if not wyk_u.is_empty():
			wiersz.add_child(_ui._napis_ekranu("Usterki wykryte: %s" % _ui._join_tekstow(_rynek_zakupow.nazwy_usterek(wyk_u, kat_id, seg_u)), 16))
		if kat_id != "samochod" or str(o.get("stan", "")) != "nowy":
			if _ui._jest_liczba(o.get("stan_deklarowany")):
				var dek := int(o["stan_deklarowany"])
				var linia_stan := "Stan deklarowany: %d (%s)" % [dek, _rynek_zakupow.etykieta_stanu_jakosci(dek)]
				if bool(o.get("stan_ujawniony", false)) and _ui._jest_liczba(o.get("stan_oceniony")):
					var oc := int(o["stan_oceniony"])
					linia_stan += " · ocena: %d (%s)" % [oc, _rynek_zakupow.etykieta_stanu_jakosci(oc)]
					if _ui._jest_liczba(o.get("stan_rzeczywisty")) and int(o["stan_deklarowany"]) != int(o["stan_rzeczywisty"]):
						linia_stan += " · rozjazd z deklaracją"
				wiersz.add_child(_ui._napis_ekranu(linia_stan, 16))
		if _ui._jest_liczba(o.get("ocena_zaplanowana_tura")):
			wiersz.add_child(_ui._napis_ekranu("Ocena z pomocą zaplanowana: tura %d" % int(o["ocena_zaplanowana_tura"]), 16))
	var oid := str(o.get("id", ""))
	var tryb_oc := _rynek_zakupow.tryb_oceny_stanu(o) if not nieruchomosc else "przed_zakupem"
	if tryb_oc != "" and not nieruchomosc and _ui._jest_liczba(o.get("stan_rzeczywisty")):
		var rzad_ocena := HBoxContainer.new()
		rzad_ocena.add_theme_constant_override("separation", 8)
		var b_ocen := Button.new()
		b_ocen.text = "Oceń stan" if tryb_oc == "przed_zakupem" else "Oceń po oględzinach"
		b_ocen.custom_minimum_size = Vector2(0, 40)
		b_ocen.add_theme_font_size_override("font_size", 17)
		b_ocen.disabled = bool(o.get("stan_ujawniony", false))
		b_ocen.pressed.connect(func() -> void:
			if kat_id == "samochod" and not _rynek_zakupow.auto_na_miejscu(_swiat, o):
				_panel_dojazdu(oid, "ocena", kat_id, stan_filtr, etykiety, nieruchomosc)
				return
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
					msg += " · wykryto: %s" % _ui._join_tekstow(_rynek_zakupow.nazwy_usterek(uw, kat_id, str(o.get("segment", ""))))
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
	if str(o.get("stan", "")) == "uzywany" and not nieruchomosc and _ui._jest_liczba(cena_v):
		wiersz.add_child(_buduj_panel_targowania(o, oid, kat_id, stan_filtr, etykiety, nieruchomosc))
	var b := Button.new()
	b.text = "Kup"
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 18)
	b.disabled = bool(o.get("targowanie_zakonczone", false)) and not o.has("cena_wynegocjowana")
	b.pressed.connect(func() -> void:
		if kat_id == "samochod" and not _rynek_zakupow.auto_na_miejscu(_swiat, o):
			_panel_dojazdu(oid, "kup", kat_id, stan_filtr, etykiety, nieruchomosc)
			return
		var wynik: Dictionary = _rynek_zakupow.kup(_swiat, oid)
		if bool(wynik.get("ok", false)):
			SkryptZapisu.zapisz(_swiat)
			_stan._zsynchronizuj_pieniadze_z_bohatera()
			_pasek._odswiez_pasek_statystyk(false)
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
	var msg := _ui._napis_ekranu(tekst, 16)
	msg.set_meta("zakupy_oferta", true)
	_ui._tresc_biala().add_child(msg)


func _panel_pomocy_oceny(oferta_id: String, kat_id: String, stan_filtr: String, etykiety: Dictionary, nieruchomosc: bool) -> void:
	var kandydaci: Array = _rynek_zakupow.kandydaci_pomocy_oceny(_swiat)
	if kandydaci.is_empty():
		_pokaz_komunikat_zakupu("Nikogo nie ma w zapisie (rodzic / przyjaciel / znajomy), kto mógłby pomóc.")
		return
	var oferta := _rynek_zakupow._znajdz_oferte(_swiat, oferta_id)
	var trzeba_dojazd := kat_id == "samochod" and not _rynek_zakupow.auto_na_miejscu(_swiat, oferta)
	var panel := VBoxContainer.new()
	panel.set_meta("zakupy_oferta", true)
	panel.add_theme_constant_override("separation", 4)
	panel.add_child(_ui._napis_ekranu("Kto ma pomóc w ocenie?", 14))
	if trzeba_dojazd:
		panel.add_child(_ui._napis_ekranu("W tym samym kroku wybierz dojazd. Potem jesteś już na miejscu.", 14))
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
		if _rynek_zakupow.kierowca_prosi_o_paliwo(osoba):
			var wycena_p := _rynek_zakupow.koszt_dojazdu(_swiat, oferta)
			var paliwo_p: Dictionary = wycena_p.get("paliwo", {}) if wycena_p.get("paliwo") is Dictionary else {}
			var dopisek := ""
			if _ui._jest_liczba(paliwo_p.get("koszt_zl")):
				dopisek = " (%d zł)" % int(paliwo_p["koszt_zl"])
			panel.add_child(_ui._napis_ekranu("%s może poprosić o paliwo%s." % [str(k.get("nazwa", "?")), dopisek], 14))
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
	_ui._tresc_biala().add_child(panel)


func _zakoncz_prosbe_oceny(
	oferta_id: String,
	ref: String,
	dojazd: Dictionary,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var w: Dictionary = _rynek_zakupow.popros_o_pomoc_oceny(_swiat, oferta_id, ref, dojazd)
	var tekst := str(w.get("tekst", w.get("powod", "")))
	var dojazd_w: Variant = w.get("dojazd", {})
	if dojazd_w is Dictionary and str(dojazd_w.get("tekst", "")) != "":
		tekst = str(dojazd_w.get("tekst", "")) + " " + tekst
	_pokaz_komunikat_zakupu(tekst, w)
	if bool(w.get("ok", false)):
		SkryptZapisu.zapisz(_swiat)
		_przerysuj_liste_zakupow(kat_id, stan_filtr, etykiety, nieruchomosc)


func _panel_dojazdu(
	oferta_id: String,
	cel: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var oferta := _rynek_zakupow._znajdz_oferte(_swiat, oferta_id)
	var wycena := _rynek_zakupow.koszt_dojazdu(_swiat, oferta)
	var panel := VBoxContainer.new()
	panel.set_meta("zakupy_oferta", true)
	panel.add_theme_constant_override("separation", 4)
	panel.add_child(_ui._napis_ekranu("Jak dojechać do auta?", 16))
	var kom: Dictionary = wycena.get("komunikacja", {}) if wycena.get("komunikacja") is Dictionary else {}
	var b_kom := Button.new()
	b_kom.text = str(kom.get("tekst", "transport publiczny"))
	b_kom.custom_minimum_size = Vector2(0, 40)
	b_kom.pressed.connect(func() -> void:
		_po_dojezdzie(oferta_id, {"sposob": "komunikacja"}, cel, kat_id, stan_filtr, etykiety, nieruchomosc)
	)
	panel.add_child(b_kom)
	var kandydaci: Array = _rynek_zakupow.kandydaci_pomocy_oceny(_swiat)
	if kandydaci.is_empty():
		panel.add_child(_ui._napis_ekranu("Nie ma kogo poprosić o podwózkę.", 14))
	for k in kandydaci:
		if not (k is Dictionary):
			continue
		var ref := str(k.get("ref", ""))
		var osoba: Dictionary = k.get("osoba", {}) if k.get("osoba") is Dictionary else {}
		var nazwa := str(k.get("nazwa", "?"))
		if _rynek_zakupow.kierowca_prosi_o_paliwo(osoba):
			var paliwo_d: Dictionary = wycena.get("paliwo", {}) if wycena.get("paliwo") is Dictionary else {}
			var dopisek_d := ""
			if _ui._jest_liczba(paliwo_d.get("koszt_zl")):
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
	_ui._tresc_biala().add_child(panel)


func _po_dojezdzie(
	oferta_id: String,
	wybor: Dictionary,
	cel: String,
	kat_id: String,
	stan_filtr: String,
	etykiety: Dictionary,
	nieruchomosc: bool
) -> void:
	var w: Dictionary = _rynek_zakupow.wykonaj_dojazd(_swiat, oferta_id, wybor)
	_pokaz_komunikat_zakupu(str(w.get("tekst", w.get("powod", ""))), w)
	if not bool(w.get("ok", false)):
		return
	if cel == "ocena":
		var ocena: Dictionary = _rynek_zakupow.ocen_stan(_swiat, oferta_id, false)
		_pokaz_komunikat_zakupu(str(ocena.get("tekst", ocena.get("powod", ""))), ocena)
	elif cel == "kup":
		var wynik: Dictionary = _rynek_zakupow.kup(_swiat, oferta_id)
		if bool(wynik.get("ok", false)):
			_stan._zsynchronizuj_pieniadze_z_bohatera()
			_pasek._odswiez_pasek_statystyk(false)
			SkryptZapisu.zapisz(_swiat)
			_cofnij_poziom()
			return
		_pokaz_komunikat_zakupu(str(wynik.get("powod", "Nie kupiono.")), wynik)
	SkryptZapisu.zapisz(_swiat)
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
		panel.add_child(_ui._napis_ekranu("Targowanie zakończone — sprzedawca nie chce rozmawiać.", 13))
		return panel
	var cena0 := float(oferta.get("cena_wyjsciowa", oferta.get("cena_zl", 0)))
	var conf_dane := _wczytaj_zakupy_oferty()
	var tconf: Dictionary = conf_dane.get("targowanie", {}) if conf_dane.get("targowanie") is Dictionary else {}
	var p_od := float(tconf.get("suwak_procent_od", 50))
	var p_do := float(tconf.get("suwak_procent_do", 100))
	var etykieta := _ui._napis_ekranu("Targuj: 90% ceny = %d zł" % int(round(cena0 * 0.9)), 13)
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
	var dialog_lbl := _ui._napis_ekranu("", 13)
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
	var mid := _stan._id_miejsca_pobytu()
	_rynek_zakupow.zapewnij_pule(_swiat, miasta, mid, int(_swiat.get("tydzien", 1)))


func _filtry_aut(stan_filtr: String) -> Dictionary:
	var filtr_c := _zakupy_filtr_ceny_wlaczony and _zakupy_filtr_do >= _zakupy_filtr_od
	var filtr_p := _zakupy_filtr_przebiegu_wlaczony and _zakupy_przebieg_do >= _zakupy_przebieg_od
	return {
		"poziom": _zakupy_zasieg_poziom,
		"km": _zakupy_zasieg_km,
		"stan": stan_filtr,
		"cena_od": _zakupy_filtr_od,
		"cena_do": _zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"przebieg_od": _zakupy_przebieg_od,
		"przebieg_do": _zakupy_przebieg_do if filtr_p else 1.0e12,
		"filtruj_przebieg": filtr_p,
		"marki": _zakupy_filtr_marki.duplicate(),
		"naped": _zakupy_filtr_naped if stan_filtr == "nowy" or stan_filtr == "" else "",
		"tydzien": int(_swiat.get("tydzien", 1)),
	}


func _odswiez_napis_puli_zakupow(kat_id: String) -> void:
	if _zakupy_pula_lbl == null or not is_instance_valid(_zakupy_pula_lbl):
		return
	if not _rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		_zakupy_pula_lbl.visible = false
		_zakupy_pula_lbl.text = ""
		return
	if kat_id == "samochod" and _zakupy_stan_filtr == "nowy":
		_zakupy_pula_lbl.visible = true
		_zakupy_pula_lbl.text = "Nowe auta: salony, bez puli z ludności."
		return
	var strona := _strona_puli_zakupow(kat_id)
	var n: int = _rynek_zakupow.pula_w_zasiegu(_zakupy_zasieg_poziom, _stan._id_miejsca_pobytu(), kat_id, strona)
	if n < 0:
		_zakupy_pula_lbl.visible = false
		_zakupy_pula_lbl.text = ""
		return
	_zakupy_pula_lbl.visible = true
	var co := "nowych" if strona == "nowy" else "używanych"
	_zakupy_pula_lbl.text = "Ogłoszeń %s w tym zasięgu: %d" % [co, n]


func _dodaj_przycisk_kolejnych_zakupow(tresc: Node, kat_id: String) -> void:
	if not _rynek_zakupow.kategoria_ma_pule_ludnosci(kat_id):
		return
	var strona := _strona_puli_zakupow(kat_id)
	var pula: int = _rynek_zakupow.pula_w_zasiegu(_zakupy_zasieg_poziom, _stan._id_miejsca_pobytu(), kat_id, strona)
	var jest: int = _rynek_zakupow.ile_w_zasiegu(_swiat, kat_id, _zakupy_zasieg_poziom, strona)
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
	var filtr_c := _zakupy_filtr_ceny_wlaczony and _zakupy_filtr_do >= _zakupy_filtr_od
	return {
		"poziom": _zakupy_zasieg_poziom,
		"km": _zakupy_zasieg_km,
		"kategoria": _zakupy_kat_id,
		"stan": _strona_generacji_lokum(),
		"cena_od": _zakupy_filtr_od,
		"cena_do": _zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"tydzien": int(_swiat.get("tydzien", 1)),
	}


func _uzupelnij_lokum_do_okna() -> int:
	var filtry := _filtry_lokum()
	var jest: Array = _rynek_zakupow.oferty_filtrowane(
		_swiat,
		_zakupy_kat_id,
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
	var brak := _rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	return _rynek_zakupow.uzupelnij_okno_lokum(_swiat, miasta, filtry, brak)


func _uzupelnij_aut_do_okna(stan_filtr: String) -> int:
	var filtry := _filtry_aut(stan_filtr)
	var jest: Array = _rynek_zakupow.oferty_filtrowane(
		_swiat,
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
	var brak := _rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	return _rynek_zakupow.uzupelnij_okno_aut(_swiat, miasta, filtry, brak)


func _podlacz_scroll_aut() -> void:
	if _zakupy_scroll_podpiety:
		return
	var sc := _scroll_zakupow()
	if sc == null:
		return
	var pasek := sc.get_v_scroll_bar()
	if pasek == null:
		return
	pasek.value_changed.connect(_na_scroll_aut)
	_zakupy_scroll_podpiety = true


func _scroll_zakupow() -> ScrollContainer:
	var tresc := _ui._tresc_biala()
	if tresc.get_parent() is ScrollContainer:
		return tresc.get_parent() as ScrollContainer
	return null


func _na_scroll_aut(wartosc: float) -> void:
	if not _rynek_zakupow.kategoria_ma_pule_ludnosci(_zakupy_kat_id) or _zakupy_dokladka:
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
	if _zakupy_dokladka or _zakupy_prefetch_kroki >= 3:
		return
	if not _rynek_zakupow.kategoria_ma_pule_ludnosci(_zakupy_kat_id):
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
	_zakupy_prefetch_kroki += 1
	if _dokladka_zakupow() > 0:
		call_deferred("_prefetch_zakupy_jesli_blisko")


func _strona_puli_zakupow(kat_id: String) -> String:
	if _zakupy_stan_filtr == "nowy" and (_rynek_zakupow.kategoria_ma_nowe_lokum(kat_id) or _rynek_zakupow.kategoria_drobna(kat_id)):
		return "nowy"
	return "uzywany"


func _strona_generacji_lokum() -> String:
	if _rynek_zakupow.kategoria_ma_nowe_lokum(_zakupy_kat_id) and _zakupy_stan_filtr == "nowy":
		return "nowy"
	return "uzywany"


func _strona_generacji_dobr() -> String:
	if _zakupy_stan_filtr == "nowy":
		return "nowy"
	return "uzywany"


func _filtry_dobra() -> Dictionary:
	var filtr_c := _zakupy_filtr_ceny_wlaczony and _zakupy_filtr_do >= _zakupy_filtr_od
	return {
		"poziom": _zakupy_zasieg_poziom,
		"km": _zakupy_zasieg_km,
		"kategoria": _zakupy_kat_id,
		"stan": _strona_generacji_dobr(),
		"cena_od": _zakupy_filtr_od,
		"cena_do": _zakupy_filtr_do if filtr_c else 1.0e12,
		"filtruj_cene": filtr_c,
		"tydzien": int(_swiat.get("tydzien", 1)),
	}


func _uzupelnij_dobra_do_okna() -> int:
	var filtry := _filtry_dobra()
	var jest: Array = _rynek_zakupow.oferty_filtrowane(
		_swiat,
		_zakupy_kat_id,
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
	var brak := _rynek_zakupow.limit_okna_aut() - jest.size()
	if brak <= 0:
		return 0
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	return _rynek_zakupow.uzupelnij_okno_dobr(_swiat, miasta, filtry, brak)


func _dokladka_zakupow() -> int:
	if not _rynek_zakupow.kategoria_ma_pule_ludnosci(_zakupy_kat_id) or _zakupy_dokladka:
		return 0
	_zakupy_dokladka = true
	var przed := 0
	if _swiat.get("rynek_zakupow") is Dictionary and _swiat["rynek_zakupow"].get("oferty") is Array:
		przed = (_swiat["rynek_zakupow"]["oferty"] as Array).size()
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	var dodano := 0
	if _zakupy_kat_id == "samochod":
		dodano = _rynek_zakupow.uzupelnij_okno_aut(_swiat, miasta, _filtry_aut(_zakupy_stan_filtr), RynekZakupow.WYPRZEDZENIE_AUT)
	elif _rynek_zakupow.kategoria_drobna(_zakupy_kat_id):
		dodano = _rynek_zakupow.uzupelnij_okno_dobr(_swiat, miasta, _filtry_dobra(), RynekZakupow.WYPRZEDZENIE_AUT)
	else:
		dodano = _rynek_zakupow.uzupelnij_okno_lokum(_swiat, miasta, _filtry_lokum(), RynekZakupow.WYPRZEDZENIE_AUT)
	if dodano > 0:
		_dopisz_karty_zakupow(przed)
		_odswiez_napis_puli_zakupow(_zakupy_kat_id)
	_zakupy_dokladka = false
	return dodano


func _dopisz_karty_zakupow(przed: int) -> void:
	var tresc := _ui._tresc_biala()
	var do_usun: Array = []
	for dziecko in tresc.get_children():
		if not dziecko.has_meta("zakupy_oferta"):
			continue
		if dziecko is Button or dziecko is Label:
			do_usun.append(dziecko)
	for d in do_usun:
		tresc.remove_child(d)
		d.queue_free()
	var stan: Variant = _swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		_dodaj_przycisk_kolejnych_zakupow(tresc, _zakupy_kat_id)
		return
	var oferty: Array = stan["oferty"]
	var widoczne := {}
	for o in _oferty_na_liscie_zakupow():
		if o is Dictionary:
			widoczne[str(o.get("id", ""))] = o
	var dane := _wczytaj_zakupy_oferty()
	var etykiety: Dictionary = dane.get("etykiety_stanu", {}) if dane.get("etykiety_stanu") is Dictionary else {}
	var nieruchomosc := _rynek_zakupow.kategoria_lokum(_zakupy_kat_id)
	for i in range(przed, oferty.size()):
		var o: Variant = oferty[i]
		if not (o is Dictionary):
			continue
		var id := str(o.get("id", ""))
		if not widoczne.has(id):
			continue
		var wiersz := _buduj_skrot_karty_oferty(widoczne[id], _zakupy_kat_id, _zakupy_stan_filtr, etykiety, nieruchomosc)
		tresc.add_child(wiersz)
		_zakupy_wiersze.append({"cena": o.get("cena_zl"), "wezel": wiersz})
	_dodaj_przycisk_kolejnych_zakupow(tresc, _zakupy_kat_id)


func _oferty_na_liscie_zakupow() -> Array:
	var kat_id := _zakupy_kat_id
	var nieruchomosc := _rynek_zakupow.kategoria_lokum(kat_id)
	var filtr_c := _zakupy_filtr_ceny_wlaczony and _zakupy_filtr_do >= _zakupy_filtr_od
	var filtr_p := kat_id == "samochod" and _zakupy_filtr_przebiegu_wlaczony and _zakupy_przebieg_do >= _zakupy_przebieg_od
	var stan_listy := _zakupy_stan_filtr if (not nieruchomosc or _rynek_zakupow.kategoria_ma_nowe_lokum(kat_id)) else ""
	var marki_f: Array = []
	var naped_f := ""
	if kat_id == "samochod":
		marki_f = _zakupy_filtr_marki.duplicate()
		if _zakupy_stan_filtr == "nowy" or _zakupy_stan_filtr == "":
			naped_f = _zakupy_filtr_naped
	return _rynek_zakupow.oferty_filtrowane(
		_swiat,
		kat_id,
		stan_listy,
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
		_zakupy_zasieg_poziom if kat_id == "samochod" or nieruchomosc or _rynek_zakupow.kategoria_drobna(kat_id) else ""
	)


func _aktywuj_zakladke_samochodow() -> void:
	if _swiat.is_empty():
		return
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	_rynek_zakupow.aktywuj_zakladke_samochodow(
		_swiat, miasta, _stan._id_miejsca_pobytu(), int(_swiat.get("tydzien", 1))
	)


func _posortuj_oferty_cena(oferty: Array, tryb: String) -> Array:
	var kopia: Array = oferty.duplicate()
	kopia.sort_custom(func(a, b) -> bool:
		var ca := float(a.get("cena_zl", -1)) if a is Dictionary and _ui._jest_liczba(a.get("cena_zl")) else -1.0
		var cb := float(b.get("cena_zl", -1)) if b is Dictionary and _ui._jest_liczba(b.get("cena_zl")) else -1.0
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
	var txt := _tekst_pracy()
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
	var sc := _scroll_zakupow()
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
	var sc := _scroll_zakupow()
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


func _ekran_jedzenie_dom(kolor: Color) -> void:
	_zdanie = _ui._napis_ekranu("", 18)
	_zdanie.add_theme_color_override("font_color", Color(KRWISTY))
	_ui._tresc_biala().add_child(_zdanie)
	_wplyw_domu = _ui._rich_ekran()
	_ui._tresc_biala().add_child(_wplyw_domu)
	_ui._tresc_biala().add_child(_ui._ramka_suwaka("Cena", kolor, _suwak_jedzenia("cena")))
	_ui._tresc_biala().add_child(_ui._ramka_suwaka("Składniki odżywcze", kolor, _suwak_jedzenia("skladniki")))
	_ui._tresc_biala().add_child(_ui._ramka_suwaka("Dieta ogólna", kolor, _suwak_jedzenia("dieta_ogolna")))
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
	_ui._tresc_biala().add_child(_ui._ramka_z_dolnym("Dieta", kolor, diety, null))
	_ui._tresc_biala().add_child(_ui._ramka_suwaka("Dieta gotowania własnego", kolor, _suwak_jedzenia("dieta_wlasna")))
	_efekt_dni = _ui._rich_ekran()
	var dni_srodek := VBoxContainer.new()
	dni_srodek.add_child(_efekt_dni)
	var dni := _ui._kropki_dni(_jedzenie.dni_gotowania(), _ustaw_dni_gotowania_z_ekranu)
	_ui._tresc_biala().add_child(_ui._ramka_z_dolnym("Ile dni w tygodniu gotujesz", kolor, dni_srodek, dni))
	for pozycja in _jedzenie.pozycje_gdzie("dom"):
		if pozycja is Dictionary:
			_ui._tresc_biala().add_child(_wiersz_pozycji(pozycja, false))
	var zatwierdz := Button.new()
	zatwierdz.text = "Zatwierdź"
	zatwierdz.custom_minimum_size = Vector2(0, 48)
	zatwierdz.pressed.connect(func() -> void:
		_jedzenie.zatwierdz()
		_odswiez_napisy_domu()
		_pasek._odswiez_pasek_statystyk(true)
	)
	_ui._tresc_biala().add_child(zatwierdz)
	_odswiez_napisy_domu()


func _ekran_jedzenie_sam(_kolor: Color) -> void:
	_odswiez_flage_jedzenia_sam()
	if not bool(_swiat.get("odblokowane_jedzenie_samemu", false)):
		var tekst_blok := "Jeszcze nie jesz samemu poza domem."
		var cfg: Variant = _jedzenie_odblok_cfg()
		if cfg is Dictionary and str(cfg.get("tekst_zablokowane", "")) != "":
			tekst_blok = str(cfg["tekst_zablokowane"])
		var prog_txt := ""
		if cfg is Dictionary and _ui._jest_liczba(cfg.get("prog_wiek_lat")):
			prog_txt = " (próg wieku: %d lat — propozycja do poprawki)" % int(cfg["prog_wiek_lat"])
		_ui._tresc_biala().add_child(_ui._napis_ekranu(tekst_blok + prog_txt, 16))
		return
	_ui._tresc_biala().add_child(_ui._napis_ekranu("Jakość zdrowotna poza domem (osobno od smaku/ceny; propozycja, nie medyczne %).", 13))
	var jak_cfg: Variant = null
	var dane_j: Variant = _jedzenie.wczytaj()
	if dane_j is Dictionary:
		jak_cfg = dane_j.get("jakosc_zdrowotna_poza_domem", {})
	var j_min := 0
	var j_max := 100
	var j_krok := 5
	if jak_cfg is Dictionary:
		if _ui._jest_liczba(jak_cfg.get("min")):
			j_min = int(jak_cfg["min"])
		if _ui._jest_liczba(jak_cfg.get("max")):
			j_max = int(jak_cfg["max"])
		if _ui._jest_liczba(jak_cfg.get("krok")):
			j_krok = int(jak_cfg["krok"])
	var j_wart := int(_swiat.get("jakosc_zdrowotna_poza_domem", 50))
	var j_opis := _ui._napis_ekranu("Jakość zdrowotna: %d" % j_wart, 15)
	_ui._tresc_biala().add_child(j_opis)
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
	_ui._tresc_biala().add_child(j_suwak)
	var komunikat := _ui._napis_ekranu("", 16)
	_ui._tresc_biala().add_child(komunikat)
	var ceny: Array = []
	for pozycja in _jedzenie.pozycje_gdzie("sam"):
		if not (pozycja is Dictionary):
			continue
		if _ui._jest_liczba(pozycja.get("cena_zl")):
			ceny.append(float(pozycja["cena_zl"]))
		_ui._tresc_biala().add_child(_wiersz_pozycji(pozycja, true, komunikat))
	_ui._dol_suwaka().show()
	if ceny.is_empty():
		_filtr_aktywny = false
		_ui._dol_suwaka().add_child(_ui._z_marginesem(_ui._napis_ekranu("—", 20)))
		return
	ceny.sort()
	var suwak = SkryptZakresu.new()
	suwak.ustaw_zakres(float(ceny[0]), float(ceny[ceny.size() - 1]))
	_filtr_aktywny = true
	_filtr_od = suwak.od
	_filtr_do = suwak.dokad
	suwak.zakres_zmieniony.connect(_on_filtr_ceny)
	_ui._dol_suwaka().add_child(_ui._z_marginesem(suwak))
	_zastosuj_filtr()


func _ekran_transport(_kolor: Color) -> void:
	var auto: Variant = _auto_z_zapisu()
	if auto == null:
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Auta nie ma.", 20))
	else:
		var opis := _opis_auta(auto)
		if opis != "":
			_ui._tresc_biala().add_child(_ui._napis_ekranu(opis, 18))
		_ui._dol_suwaka().show()
		_ui._dol_suwaka().add_child(_ui._z_marginesem(_ui._kropki_dni(int(_swiat.get("dni_auta", 0)), _ustaw_dni_auta)))
		_ui._dol_suwaka().add_child(_ui._z_marginesem(_ui._napis_ekranu("Cena na tydzień: %s" % _cena_tygodnia_auta(auto), 16)))
	var mapa := Button.new()
	mapa.text = "Mapa"
	mapa.custom_minimum_size = Vector2(0, 44)
	mapa.pressed.connect(func() -> void:
		_otworz_akcje({"id": "mapa", "nazwa": "Mapa", "tryb": "ekran", "tresc": "mapa", "kolor": "#8aa0a8"})
	)
	_ui._tresc_biala().add_child(mapa)


func _ekran_mapa() -> void:
	_ui._tresc_biala().add_child(_ui._napis_ekranu(
		"Mapa uproszczona: miasta i drogi między nimi (sąsiedztwo). Bez GIS / bez ulic.",
		16
	))
	if _mapa_ikona == null and ResourceLoader.exists(IKONA_MIASTA):
		_mapa_ikona = load(IKONA_MIASTA) as Texture2D
	var miasta: Array = _losowanie.miasta_polski() if _losowanie != null else []
	var ziarno := int(_swiat.get("rynek_zakupow", {}).get("ziarno", 1)) if _swiat.get("rynek_zakupow") is Dictionary else 1
	if ziarno == 0:
		ziarno = int(_swiat.get("tydzien", 1)) * 9973 + 1
	_mapa_graf = _mapa_miast.zbuduj(miasta, ziarno, _stan._id_miejsca_pobytu())
	var obszar := Control.new()
	obszar.custom_minimum_size = Vector2(0, 420)
	obszar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obszar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	obszar.clip_contents = true
	_mapa_warstwa = obszar
	_ui._tresc_biala().add_child(obszar)
	_mapa_pasek = _ui._napis_ekranu("Kliknij miasto — kto tam mieszka (bez znajomych).", 16)
	_mapa_pasek.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ui._tresc_biala().add_child(_mapa_pasek)
	_opcje_transportu = VBoxContainer.new()
	_opcje_transportu.add_theme_constant_override("separation", 8)
	_ui._tresc_biala().add_child(_opcje_transportu)
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
		czesci.append("Rodzice: %s" % _ui._join_tekstow(rodzice_l))
	if not dziad_l.is_empty():
		czesci.append("Dziadkowie: %s" % _ui._join_tekstow(dziad_l))
	if not przyj_l.is_empty():
		czesci.append("Przyjaciele: %s" % _ui._join_tekstow(przyj_l))
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
	_ui._wyczysc(_opcje_transportu)
	_opcje_transportu.add_child(_ui._napis_ekranu(nazwa, 18))
	var skad := _stan._id_miejsca_pobytu()
	var dyst: Variant = _mapa_miast.dystans_km(_mapa_graf, skad, id)
	var dyst_txt := "—"
	if _ui._jest_liczba(dyst):
		dyst_txt = "%.0f km (propozycja)" % float(dyst)
	_opcje_transportu.add_child(_ui._napis_ekranu("Dystans: %s" % dyst_txt, 14))
	var cena_publiczna: Variant = _cena_transportu_miasta(id)
	var cena_txt := "—"
	var pieniadze := "—"
	if _ui._jest_liczba(cena_publiczna):
		cena_txt = str(cena_publiczna)
		pieniadze = "w dół"
	_opcje_transportu.add_child(_blok_drogi("Pieszo", "w górę", "—", "—", []))
	_opcje_transportu.add_child(_blok_drogi("Transport publiczny", "w górę", pieniadze, cena_txt, []))
	var auto: Variant = _auto_z_zapisu()
	if auto != null and _ui._jest_liczba(dyst):
		_opcje_transportu.add_child(_panel_przejazdu_autem(auto, float(dyst), nazwa))
	elif auto != null:
		_opcje_transportu.add_child(_ui._napis_ekranu("Auto: brak dystansu do wyliczenia.", 14))


func _blok_drogi(nazwa: String, zmeczenie: String, pieniadze: String, cena: String, klasy: Array) -> Control:
	var kolumna := VBoxContainer.new()
	kolumna.add_theme_constant_override("separation", 2)
	kolumna.add_child(_ui._napis_ekranu(nazwa, 18))
	kolumna.add_child(_ui._napis_ekranu("Zmęczenie: %s" % zmeczenie, 16))
	kolumna.add_child(_ui._napis_ekranu("Pieniądze: %s" % pieniadze, 16))
	kolumna.add_child(_ui._napis_ekranu("Cena: %s" % cena, 16))
	if not klasy.is_empty():
		kolumna.add_child(_ui._napis_ekranu("Klasa", 16))
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
	kolumna.add_child(_ui._napis_ekranu("Auto → %s" % cel_nazwa, 18))
	var vmax_v: Variant = _przejazd.predkosc_max_auta(auto)
	if vmax_v == null:
		kolumna.add_child(_ui._napis_ekranu("Vmax: brak danych / auto nie jeździ.", 13))
		return kolumna
	var vmax := int(vmax_v)
	var vmax_txt := _rynek_zakupow.tekst_vmax_oferty(
		auto,
		auto.get("usterki_rzeczywiste", []) if auto.get("usterki_rzeczywiste") is Array else []
	)
	if vmax_txt == "":
		vmax_txt = str(vmax)
	kolumna.add_child(_ui._napis_ekranu("Vmax pojazdu: %s km/h" % vmax_txt, 13))
	var tryb_stan := {"id": SkryptPrzejazdu.TRYB_DOZWOLONA, "nadmiar": 0.0}
	var opis := _ui._napis_ekranu("", 14)
	var suwak_box := VBoxContainer.new()
	suwak_box.visible = false
	var nad_opis := _ui._napis_ekranu("Ponad dozwolone: 0 km/h", 13)
	var suwak := HSlider.new()
	suwak.min_value = 0
	suwak.max_value = maxf(0.0, float(vmax) - float(SkryptPrzejazdu.LIMIT_DOZWOLONY_KM_H))
	suwak.step = 1
	suwak.value = 0
	suwak.custom_minimum_size = Vector2(0, 32)
	suwak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var odswiez := func() -> void:
		var wynik: Dictionary = _przejazd.oblicz(
			dystans_km, auto, str(tryb_stan["id"]), float(tryb_stan["nadmiar"]), _cena_paliwa(auto)
		)
		var jedn_sp := str(auto.get("spalanie_jednostka", "l/100 km"))
		if jedn_sp == "":
			jedn_sp = "l/100 km"
		var linie := "Koszt paliwa: %s · zużycie trybu: %s %s · zmęczenie fiz. +%d" % [
			str(wynik.get("koszt_tekst", "—")),
			str(wynik.get("zuzycie_l_na_100", "—")),
			jedn_sp,
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
	var cena := _ui._napis_ekranu(_ui._tekst_ceny(pozycja.get("cena_zl")), 16)
	var jakosc_txt := ""
	if _ui._jest_liczba(pozycja.get("jakosc_propozycja")):
		jakosc_txt = "Jakość (propozycja): %d" % int(pozycja["jakosc_propozycja"])
	elif not sam:
		jakosc_txt = "Jakość: —"
	var jakosc_lbl := _ui._napis_ekranu(jakosc_txt, 13) if jakosc_txt != "" else null
	var ster := HBoxContainer.new()
	ster.add_theme_constant_override("separation", 6)
	var licznik := _ui._napis_ekranu(str(_jedzenie.ilosc_pozycji(id)), 20)
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
	var efekty := _ui._rich_ekran()
	efekty.text = _jedzenie.bb_pozycji(id)
	prawa.add_child(nazwa)
	prawa.add_child(cena)
	if jakosc_lbl != null:
		prawa.add_child(jakosc_lbl)
	prawa.add_child(ster)
	prawa.add_child(efekty)
	var rodzice := _ui._napis_ekranu("", 15)
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
		if _filtr_aktywny and _ui._jest_liczba(wpis.get("cena")):
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
	if bool(stan.get(flaga, false)) and _ui._jest_liczba(stan.get(pole)):
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
	_pasek._odswiez_pasek_statystyk(true)
	_odswiez_napisy_domu()


func _zmien_ilosc(id: String, delta: int, licznik: Label) -> void:
	_jedzenie.ustaw_ilosc_pozycji(id, _jedzenie.ilosc_pozycji(id) + delta)
	if licznik != null and is_instance_valid(licznik):
		licznik.text = str(_jedzenie.ilosc_pozycji(id))


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
	if not _stan._lokum_pelne(lokum):
		var maj: Variant = _swiat.get("majatek", {})
		if maj is Dictionary and maj.get("lokum_rodziny") is Dictionary:
			lokum = maj["lokum_rodziny"]
		else:
			var rodzina: Variant = _swiat.get("rodzina", {})
			if rodzina is Dictionary and rodzina.get("lokum") is Dictionary:
				lokum = rodzina["lokum"]
	return _rynek_zakupow.opis_lokum_ui(lokum)


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
	return ZaokraglenieZarobkow.tekst(blok)


func _cechy_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("cecha_%d" % numer):
		var nazwa := _ui._nazwa_pola(bohater["cecha_%d" % numer])
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _inteligencje_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("inteligencja_%d" % numer):
		var pozycja: Variant = bohater["inteligencja_%d" % numer]
		var nazwa := _ui._nazwa_pola(pozycja)
		if nazwa != "" and pozycja is Dictionary and _ui._jest_liczba(pozycja.get("wartosc")):
			nazwa = "%s %s" % [nazwa, str(int(pozycja["wartosc"]))]
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _auto_z_zapisu() -> Variant:
	var auto: Variant = _swiat.get("auto", null)
	if auto is Dictionary and _auto_jest(auto) and not bool(auto.get("nie_jezdzi", false)):
		return auto
	var posiadane: Variant = _stan._bohater().get("posiadane", {})
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
	kolumna.add_child(_ui._napis_ekranu(
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
			_stan._zsynchronizuj_pieniadze_z_bohatera()
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
			_stan._zsynchronizuj_pieniadze_z_bohatera()
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
			_stan._zsynchronizuj_pieniadze_z_bohatera()
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
	if _ui._jest_liczba(auto.get("cena_tygodnia")):
		return str(auto.get("cena_tygodnia"))
	return "—"


func _cena_paliwa(auto: Dictionary = {}) -> Variant:
	return _rynek_zakupow.cena_nosnika_dojazdu(auto)


func _cena_transportu_miasta(id: String) -> Variant:
	if id == "":
		return null
	var dane: Variant = _ui._czytaj_json("res://świat/polska/miasta/%s.json" % id)
	if dane is Dictionary:
		return dane.get("cena_transportu_publicznego", null)
	return null


func _klasy_nadwozia() -> Array:
	var dane: Variant = _ui._czytaj_json("res://pojazdy/nadwozia.json")
	if dane is Dictionary and dane.get("klasy") is Array:
		return dane["klasy"]
	return []


## Wejścia zostawione na węźle, bo testy i sygnały wołają je po staremu.
func _tresc_biala() -> VBoxContainer:
	return _ui._tresc_biala()

func _tytul_bialy() -> Label:
	return _ui._tytul_bialy()

