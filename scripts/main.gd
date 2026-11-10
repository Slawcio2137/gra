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
const SkryptEkranuPracy = preload("res://scripts/ekran_pracy.gd")
const SkryptEkranuFali2 = preload("res://scripts/ekran_fali2.gd")

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
var _zakupy_szukaj_tekst := ""
var _zakupy_dokladka_seria := 0
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

var _modul_pracy: EkranPracy

var _fala2: EkranFali2

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
	_modul_pracy = SkryptEkranuPracy.new(self)
	_fala2 = SkryptEkranuFali2.new(self)












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
	if ZiarnoRodzicow.new().uzupelnij_wieki(_swiat):
		SkryptZapisu.zapisz(_swiat)
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
		ZiarnoRodzicow.new().postarz_otoczenie(_swiat)
	_swiat["tydzien"] = tydzien
	_swiat["rok"] = rok
	_rynek_zakupow.regeneruj_zmeczenie_tydzien(_swiat)
	_rynek_zakupow.tick_remonty(_swiat)
	_swiat["komunikat_tury"] = ""
	_swiat["eventy_tury"] = []
	_swiat["event_odpowiedz_tekst"] = ""
	_ekran_jedzenia._odswiez_flage_jedzenia_sam()
	_rodzina._wyplata_kieszonkowego_tydzien()
	_rodzina._wyplata_kieszonkowego_dziadkow_tydzien()
	_fala2._efekt_konserwacji_auta_tydzien()
	_fala2._efekt_fala2_tydzien()
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
	_ui._wyczysc(_ui._dol_suwaka())
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
	ZiarnoRodzicow.new().uzupelnij_wieki(_swiat)
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
	_ui._wyczysc(_ui._dol_suwaka())
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
	_ui._wyczysc(_ui._dol_suwaka())
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
	_ui._wyczysc(_ui._dol_suwaka())
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
		_fala2._ekran_terapia()
	elif tresc == "praca":
		_modul_pracy._ekran_praca_fala2()
	elif tresc == "majatek":
		_dom._ekran_majatek()
	elif tresc == "konserwacja_auta":
		_fala2._ekran_konserwacja_auta()
	elif tresc == "lotnictwo":
		_fala2._ekran_lotnictwo()
	elif tresc == "szkola":
		_ui._tresc_biala().add_child(_ui._napis_ekranu("Nauka — Fala 2: korepetycje, zajęcia, szachy w podmenu.", 16))
		_fala2._stub_przedszkole()
	elif tresc == "korepetycje":
		_fala2._ekran_korepetycje()
	elif tresc == "zajecia_dodatkowe":
		_fala2._ekran_zajecia_dodatkowe()
	elif tresc == "szachy":
		_fala2._ekran_szachy()
	elif tresc == "eventy_przyklady":
		_fala2._ekran_eventy_przyklady()
	elif tresc == "imprezy":
		_fala2._ekran_imprezy()
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

