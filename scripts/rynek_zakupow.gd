extends RefCounted
class_name RynekZakupow

## Oferty z miejsca. Pula to liczba, nie tysiące węzłów.
## Używane auta: round(ludność / 1500). Używane lokale: round(ludność / 5000).
## Nowe domy i mieszkania: osobno, round(ludność / 3500). Ekran dociąga po kilka.
## Drobne: nowe = liczba modeli w katalogu (nie ludność). Używane = udział stanu krajowego.
## Telefon używany: OLX styczeń >15 tys. transakcji; założenie, że ogłoszenie wisi ~miesiąc → stan 15 tys.
## Rower częściej niż telefon (×3). Laptop ~1/3 telefonu, komputer połowa laptopa, sprzęt ~1/4 telefonu.
## To propozycja_do_poprawki, nie GUS i nie round(ludność/N).
## Wysyłka drobnych: dokładnie 15 zł — reguła gracza, nie taryfa przewoźnika.
## Odległość na karcie: odleglosc_miedzy_miejscami od miasta bohatera, nie losowy 1–35 km.
## Nowe auto = salon z listy. Używane od osoby prywatnej nie mają dostawy.
## Cena auta: od katalogu. Nowe blisko cennika. Używane spada z przebiegiem, stanem i usterkami,
## bez sufitu 2–7 tys. i bez pasa 0,22–0,68, które z 50 tys. robiły ~2 tys. (propozycja_do_poprawki).
## Nieruchomości: metraż, pokoje, stan, lokalizacja, odległość, wygoda, cena ze wzoru.
## Dobra: marka/model z puli. Obrazki: lokalny placeholder albo paczka (pobrane: false).

const PLIK := "res://postacie/zakupy_oferty.json"
const PLIK_OBRAZKOW := "res://zakupy/obrazki_paczka.json"
const PLIK_DRYFU := "res://postacie/zadowolenie_dryf.json"
const PLIK_DIALOGI_TARG := "res://postacie/dialogi_targowanie.json"
const PLIK_KATALOG_AUT := "res://pojazdy/katalog_aut_pl.json"
const PLIK_KATALOG_INDEX := "res://pojazdy/katalog_aut_index.json"
const PLIK_USTERKI_AUT := "res://pojazdy/usterki_aut.json"
const PLIK_USTERKI_DOBR := "res://zakupy/usterki_dobr.json"
const PLIK_INDEKS_MIAST := "res://świat/polska/indeks.json"
const PLIK_SALONY := "res://pojazdy/salony_marek_pl.json"
const PLACEHOLDER_DIR := "res://grafika/zakupy/"
## Ekran + zapas pod kciuk. Jedno dociągnięcie nie buduje puli kraju.
const OKNO_STARTOWE_AUT := 8
const WYPRZEDZENIE_AUT := 5
const MAX_JEDNEJ_DOKLADKI_AUT := 16
## Najbliższa liczba całkowita. Połowa w górę (round w Godot od zera).
const DZIELNIK_AUT_UZYWANYCH := 1500
const DZIELNIK_LOKUM_UZYWANYCH := 5000
const DZIELNIK_LOKUM_NOWYCH := 3500
## propozycja_do_poprawki. Stojący stan używanych ogłoszeń w całej Polsce, nie dzielnik ludności.
## Telefon: cytowany obrót OLX (~15 tys. transakcji w styczniu) przy założeniu, że oferta wisi około miesiąca.
## Rower: tablica częściej niż telefon (dziecko wyrasta, sezon, przeprowadzka) → 3× stan telefonu.
## Laptop: rzadsza wymiana i stary zostaje drugim komputerem → ok. 1/3 telefonu.
## Komputer: mniej gospodarstw, zostaje na biurku → połowa laptopów.
## Sprzęt audio: tani, zwykle szuflada → ok. 1/4 telefonu.
const STAN_KRAJOWY_TELEFON_UZYWANY := 15000
const STAN_KRAJOWY_LAPTOP_UZYWANY := 5000
const STAN_KRAJOWY_KOMPUTER_UZYWANY := 2500
const STAN_KRAJOWY_ROWER_UZYWANY := 45000
const STAN_KRAJOWY_SPRZET_UZYWANY := 3750
## Reguła gracza, nie cennik przewoźnika.
const CENA_WYSYLKI_DROBNEJ_ZL := 15
## Wspólne koło wag katalogu. Waga brakująca albo <= 0 spada do podłogi, nie wypada z losowania.
const PODLOGA_WAGI_KATALOGU := 0.1
## Kotwice tylko_uzywane przy puli używanych, tak samo dla aut i dóbr.
const MNOZNIK_TYLKO_UZYWANE := 1.35
## Ile razy dobrać rekord, zanim filtr ceny albo zasięgu uzna próbę za pustą.
const PROBY_DOBORU_REKORDU := 12
## Część używanych drobiazgów jest uszkodzona. Reszta używanych nie dostaje usterek.
const SZANSA_USZKODZENIA_UZYWANEGO := 0.55
const PROG_DOCIAGANIA_PX := 960.0

var _dane: Variant = null
var _manifest: Variant = null
var _dryf: Variant = null
var _dialogi_targ: Variant = null
var _katalog_aut: Variant = null
var _usterki_aut: Variant = null
var _usterki_dobr: Variant = null
var _indeks_miast_po_id: Variant = null
var _salony_danych: Variant = null
var _miejsca_ludnosci_cache: Array = []
var _katalogi_dobr_cache: Dictionary = {}
var _praca_ref: Variant = null
var _ostatnia_pula := -1


func wczytaj() -> Dictionary:
	if _dane is Dictionary:
		return _dane
	if not FileAccess.file_exists(PLIK):
		return {}
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return {}
	var surowe: Variant = JSON.parse_string(plik.get_as_text())
	if surowe is Dictionary:
		_dane = surowe
		return surowe
	return {}


func paczka_pobrana() -> bool:
	var m: Variant = _wczytaj_manifest()
	if m is Dictionary:
		return m.get("pobrane") == true
	return false


func placeholder_sciezka(kategoria: String) -> String:
	var mapa := {
		"mieszkanie": PLACEHOLDER_DIR + "mieszkanie.png",
		"apartament": PLACEHOLDER_DIR + "mieszkanie.png",
		"dom": PLACEHOLDER_DIR + "dom.png",
		"willa": PLACEHOLDER_DIR + "dom.png",
		"telefon": PLACEHOLDER_DIR + "telefon.png",
		"samochod": PLACEHOLDER_DIR + "samochod.png",
		"laptop": PLACEHOLDER_DIR + "laptop.png",
		"komputer": PLACEHOLDER_DIR + "komputer.png",
		"rower": PLACEHOLDER_DIR + "rower.png",
		"sprzet": PLACEHOLDER_DIR + "ogolny.png",
		"samolot": PLACEHOLDER_DIR + "ogolny.png",
		"smiglowiec_bojowy": PLACEHOLDER_DIR + "ogolny.png",
		"ksiazka": PLACEHOLDER_DIR + "ogolny.png",
	}
	var sciezka := str(mapa.get(kategoria, PLACEHOLDER_DIR + "ogolny.png"))
	if FileAccess.file_exists(sciezka):
		return sciezka
	if FileAccess.file_exists("res://grafika/znak_zapytania.png"):
		return "res://grafika/znak_zapytania.png"
	return sciezka


## Inicjuje / odświeża pulę w zapisie świata. Wywołać na Start i co turę.
## Auta: licznik/odświeżanie dopiero po pierwszym wejściu w zakładkę Samochód.
func zapewnij_pule(swiat: Dictionary, miasta: Array, miasto_gracza_id: String, tydzien: int) -> void:
	var stan: Dictionary = {}
	if swiat.get("rynek_zakupow") is Dictionary:
		stan = swiat["rynek_zakupow"]
	var ziarno := int(stan.get("ziarno", 0))
	if ziarno == 0:
		ziarno = int(Time.get_unix_time_from_system()) ^ (tydzien * 9973)
		stan["ziarno"] = ziarno
	var ostatni := int(stan.get("ostatni_tydzien", -1))
	var oferty: Array = []
	if stan.get("oferty") is Array:
		oferty = stan["oferty"]
	var conf := _nieruchomosci_conf()
	var co_ile := 1
	if conf.get("odswiezanie_tur") is Dictionary and _liczba(conf["odswiezanie_tur"].get("co_ile_tur")):
		co_ile = maxi(1, int(conf["odswiezanie_tur"]["co_ile_tur"]))
	if oferty.is_empty():
		oferty = _generuj_start(miasta, miasto_gracza_id, ziarno, conf)
	elif ostatni >= 0 and tydzien != ostatni and (tydzien - ostatni) % co_ile == 0:
		oferty = _przewin_pule(oferty, miasta, miasto_gracza_id, ziarno + tydzien * 17, conf)
		if bool(stan.get("zakladka_samochodow_aktywna", false)):
			# Tura tylko zdejmuje przeterminowane auta. Nie dorzuca nowych.
			oferty = _wygas_auta(oferty, tydzien)
	stan["oferty"] = oferty
	stan["ostatni_tydzien"] = tydzien
	stan["miasto_gracza_id"] = miasto_gracza_id
	if str(stan.get("miejsce_zrodlo_id", "")) == "":
		stan["miejsce_zrodlo_id"] = miasto_gracza_id
	swiat["rynek_zakupow"] = stan
	_uzgodnij_odleglosci(swiat, miasta)


## Wejście w zakładkę Samochód. Nie zwija puli kraju. Stary preroll (setki aut) znika raz.
func aktywuj_zakladke_samochodow(swiat: Dictionary, miasta: Array, miasto_gracza_id: String, tydzien: int) -> void:
	var stan: Dictionary = {}
	if swiat.get("rynek_zakupow") is Dictionary:
		stan = swiat["rynek_zakupow"]
	var miasta_wzb: Array = _wzbogac_miasta_z_indeksu(miasta)
	var miasto := _wzbogac_jedno_miasto(_miasto_po_id(miasta_wzb, miasto_gracza_id))
	var mid_kotwica := str(miasto.get("id", ""))
	if mid_kotwica == "":
		mid_kotwica = miasto_gracza_id
	var ziarno := int(stan.get("ziarno", 0))
	if ziarno == 0:
		ziarno = int(Time.get_unix_time_from_system()) ^ (tydzien * 9973)
		stan["ziarno"] = ziarno
	var oferty: Array = []
	if stan.get("oferty") is Array:
		oferty = stan["oferty"]
	if not bool(stan.get("auta_leniwe", false)):
		var bez_aut: Array = []
		for o in oferty:
			if o is Dictionary and str(o.get("kategoria", "")) == "samochod":
				continue
			bez_aut.append(o)
		oferty = bez_aut
		stan["auta_leniwe"] = true
		stan["kursor_aut"] = 0
	stan["zakladka_samochodow_aktywna"] = true
	stan["zakladka_samochodow_aktywacja_tydzien"] = tydzien
	stan["oferty"] = oferty
	stan["ostatni_tydzien"] = tydzien
	stan["miasto_gracza_id"] = mid_kotwica
	stan["miejsce_zrodlo_id"] = miasto_gracza_id
	swiat["rynek_zakupow"] = stan
	var juz := _ile_samochodow(oferty)
	if juz >= limit_okna_aut():
		return
	var filtry := {
		"poziom": "miasto",
		"km": 9999.0,
		"stan": "",
		"tydzien": tydzien,
	}
	uzupelnij_okno_aut(swiat, miasta_wzb, filtry, limit_okna_aut() - juz)


func _ile_samochodow(oferty: Array) -> int:
	var n := 0
	for o in oferty:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod":
			n += 1
	return n


func limit_okna_aut() -> int:
	return OKNO_STARTOWE_AUT + WYPRZEDZENIE_AUT


## Dorzuca co najwyżej `ile` ogłoszeń pasujących do filtra. Nie buduje reszty puli.
func uzupelnij_okno_aut(swiat: Dictionary, miasta: Array, filtry: Dictionary, ile: int) -> int:
	var porcja := clampi(ile, 0, MAX_JEDNEJ_DOKLADKI_AUT)
	if porcja == 0:
		return 0
	var stan: Dictionary = {}
	if swiat.get("rynek_zakupow") is Dictionary:
		stan = swiat["rynek_zakupow"]
	else:
		swiat["rynek_zakupow"] = stan
	var miasta_wzb: Array = _wzbogac_miasta_z_indeksu(miasta)
	var zrodlo := str(stan.get("miejsce_zrodlo_id", stan.get("miasto_gracza_id", "")))
	var miasto := _wzbogac_jedno_miasto(_miasto_po_id(miasta_wzb, zrodlo))
	var mid := str(miasto.get("id", stan.get("miasto_gracza_id", "")))
	var ziarno := int(stan.get("ziarno", 1))
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var poziom_puli := str(filtry.get("poziom", "miasto"))
	var strona_auta := str(filtry.get("stan", ""))
	# Nowe z salonu są poza pulą ludności. Używane: 1 ogłoszenie na 1500 mieszkańców.
	if strona_auta != "nowy":
		porcja = _przytnij_porcje_do_puli(swiat, stan, "samochod", poziom_puli, porcja, "uzywany")
	if porcja == 0:
		swiat["rynek_zakupow"] = stan
		return 0
	var dodane := 0
	var proby := 0
	var sufit := porcja * 8
	while dodane < porcja and proby < sufit:
		proby += 1
		var kursor := int(stan.get("kursor_aut", 0)) + 1
		stan["kursor_aut"] = kursor
		var rng := RandomNumberGenerator.new()
		rng.seed = ziarno + kursor * 17 + 3
		var oferta := _wylosuj_auto_pod_filtr(miasto, mid, miasta_wzb, rng, filtry)
		if oferta.is_empty():
			continue
		oferta["tydzien_wystawienia"] = int(filtry.get("tydzien", swiat.get("tydzien", 1)))
		oferta["waznosc_tygodni"] = _waznosc_ogloszenia_aut()
		oferty.append(oferta)
		dodane += 1
	stan["oferty"] = oferty
	swiat["rynek_zakupow"] = stan
	return dodane


## Domy i mieszkania: ta sama zasada co auta. `ile` kart, nie cała pula ludności.
func uzupelnij_okno_lokum(swiat: Dictionary, miasta: Array, filtry: Dictionary, ile: int) -> int:
	var porcja := clampi(ile, 0, MAX_JEDNEJ_DOKLADKI_AUT)
	if porcja == 0:
		return 0
	var kat := str(filtry.get("kategoria", "mieszkanie"))
	if not kategoria_lokum(kat):
		return 0
	var stan: Dictionary = {}
	if swiat.get("rynek_zakupow") is Dictionary:
		stan = swiat["rynek_zakupow"]
	else:
		swiat["rynek_zakupow"] = stan
	var miasta_wzb: Array = _wzbogac_miasta_z_indeksu(miasta)
	var zrodlo := str(stan.get("miejsce_zrodlo_id", stan.get("miasto_gracza_id", "")))
	var hero := _wzbogac_jedno_miasto(_miasto_po_id(miasta_wzb, zrodlo))
	var poziom_puli := str(filtry.get("poziom", "miasto"))
	var strona_lok := str(filtry.get("stan", "uzywany"))
	if strona_lok != "nowy":
		strona_lok = "uzywany"
	porcja = _przytnij_porcje_do_puli(swiat, stan, kat, poziom_puli, porcja, strona_lok)
	if porcja == 0:
		swiat["rynek_zakupow"] = stan
		return 0
	var ziarno := int(stan.get("ziarno", 1))
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var dodane := 0
	var proby := 0
	var sufit := porcja * 8
	while dodane < porcja and proby < sufit:
		proby += 1
		var kursor := int(stan.get("kursor_lokum", 0)) + 1
		stan["kursor_lokum"] = kursor
		var rng := RandomNumberGenerator.new()
		rng.seed = ziarno + kursor * 29 + 11
		var oferta := _wylosuj_lokum_pod_filtr(hero, miasta_wzb, rng, filtry)
		if oferta.is_empty():
			continue
		oferty.append(oferta)
		dodane += 1
	stan["oferty"] = oferty
	swiat["rynek_zakupow"] = stan
	return dodane


func _wylosuj_lokum_pod_filtr(
	hero: Dictionary,
	miasta: Array,
	rng: RandomNumberGenerator,
	filtry: Dictionary
) -> Dictionary:
	var kat := str(filtry.get("kategoria", "mieszkanie"))
	var poziom := str(filtry.get("poziom", "miasto"))
	var pula := _miasta_poziomu(poziom, hero, miasta)
	if pula.is_empty():
		return {}
	var cel: Dictionary = pula[rng.randi_range(0, pula.size() - 1)]
	var hid := str(hero.get("id", ""))
	var strona := str(filtry.get("stan", "uzywany"))
	if strona != "nowy":
		strona = "uzywany"
	if strona == "nowy" and not kategoria_ma_nowe_lokum(kat):
		return {}
	var oferta := _losuj_nieruchomosc(kat, cel, hid, rng, _nieruchomosci_conf(), hero, strona)
	if oferta.is_empty() or not _oferta_miesci_sie_w_filtrze(oferta, filtry):
		return {}
	return oferta


## Telefon, laptop, komputer, rower, sprzęt: to samo okno co auta. Nie druga pula w pamięci.
func uzupelnij_okno_dobr(swiat: Dictionary, miasta: Array, filtry: Dictionary, ile: int) -> int:
	var porcja := clampi(ile, 0, MAX_JEDNEJ_DOKLADKI_AUT)
	if porcja == 0:
		return 0
	var kat := str(filtry.get("kategoria", "telefon"))
	if not kategoria_drobna(kat):
		return 0
	var stan: Dictionary = {}
	if swiat.get("rynek_zakupow") is Dictionary:
		stan = swiat["rynek_zakupow"]
	else:
		swiat["rynek_zakupow"] = stan
	var miasta_wzb: Array = _wzbogac_miasta_z_indeksu(miasta)
	var zrodlo := str(stan.get("miejsce_zrodlo_id", stan.get("miasto_gracza_id", "")))
	var hero := _wzbogac_jedno_miasto(_miasto_po_id(miasta_wzb, zrodlo))
	var poziom_puli := str(filtry.get("poziom", "miasto"))
	var strona := str(filtry.get("stan", "uzywany"))
	var mieszane := strona != "nowy" and strona != "uzywany"
	if mieszane:
		porcja = _przytnij_porcje_mieszana_dobr(swiat, stan, kat, poziom_puli, porcja)
	else:
		if strona != "nowy":
			strona = "uzywany"
		porcja = _przytnij_porcje_do_puli(swiat, stan, kat, poziom_puli, porcja, strona)
	if porcja == 0:
		swiat["rynek_zakupow"] = stan
		return 0
	var ziarno := int(stan.get("ziarno", 1))
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var dodane := 0
	var proby := 0
	var sufit := porcja * 8
	while dodane < porcja and proby < sufit:
		proby += 1
		var kursor := int(stan.get("kursor_dobra", 0)) + 1
		stan["kursor_dobra"] = kursor
		var rng := RandomNumberGenerator.new()
		rng.seed = ziarno + kursor * 29 + absi(kat.hash())
		if not mieszane and strona == "nowy" and _wolne_modele_nowego(kat, oferty, filtry).is_empty():
			break
		if mieszane and _zostalo_w_puli_dobr(swiat, stan, kat, poziom_puli, "nowy") <= 0 and _zostalo_w_puli_dobr(swiat, stan, kat, poziom_puli, "uzywany") <= 0:
			break
		var oferta := _wylosuj_dobro_pod_filtr(hero, miasta_wzb, rng, filtry, {}, oferty)
		if oferta.is_empty():
			continue
		if mieszane:
			var strona_oferty := str(oferta.get("stan", ""))
			if _zostalo_w_puli_dobr(swiat, stan, kat, poziom_puli, strona_oferty) <= 0:
				continue
		oferty.append(oferta)
		dodane += 1
	stan["oferty"] = oferty
	swiat["rynek_zakupow"] = stan
	return dodane


func _wylosuj_dobro_pod_filtr(
	hero: Dictionary,
	miasta: Array,
	rng: RandomNumberGenerator,
	filtry: Dictionary,
	rekord_wymuszony: Dictionary = {},
	oferty_istniejace: Array = []
) -> Dictionary:
	var kat := str(filtry.get("kategoria", "telefon"))
	if not kategoria_drobna(kat):
		return {}
	var poziom := str(filtry.get("poziom", "miasto"))
	var pula := _miasta_poziomu(poziom, hero, miasta)
	if pula.is_empty():
		return {}
	var strona_filtra := str(filtry.get("stan", "uzywany"))
	var mieszane := strona_filtra != "nowy" and strona_filtra != "uzywany"
	if not mieszane and strona_filtra != "nowy":
		strona_filtra = "uzywany"
	if not rekord_wymuszony.is_empty() and not _rekord_pasuje_do_filtra_dobra(rekord_wymuszony, filtry):
		return {}
	for _proba in PROBY_DOBORU_REKORDU:
		var strona := strona_filtra
		if mieszane:
			strona = "nowy" if rng.randf() < _udzial_nowych_dobr() else "uzywany"
		var rekord: Dictionary = rekord_wymuszony
		if rekord.is_empty():
			if strona == "nowy":
				rekord = _wolny_model_nowego(kat, oferty_istniejace, rng, filtry)
			else:
				rekord = _dobierz_uzywane_dobro(kat, rng, filtry)
		if rekord.is_empty():
			if strona == "nowy" and not mieszane:
				return {}
			continue
		var cel: Dictionary = pula[rng.randi_range(0, pula.size() - 1)]
		var oferta := _losuj_dobro(kat, cel, rng, str(hero.get("id", "")), _nieruchomosci_conf(), hero, strona, rekord)
		if oferta.is_empty() or not _oferta_miesci_sie_w_filtrze(oferta, filtry):
			continue
		if not _rekord_pasuje_do_filtra_dobra(oferta, filtry):
			continue
		return oferta
	return {}


func _waznosc_ogloszenia_aut() -> int:
	var conf := _auta_conf()
	if _liczba(conf.get("waznosc_tygodni")):
		return maxi(1, int(conf["waznosc_tygodni"]))
	return 4


func _wygas_auta(oferty: Array, tydzien: int) -> Array:
	## Schodzą ogłoszenia starsze niż waznosc_tygodni. Nic nie dochodzi.
	var waznosc := _waznosc_ogloszenia_aut()
	var out: Array = []
	for o in oferty:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			out.append(o)
			continue
		var start := tydzien
		if _liczba(o.get("tydzien_wystawienia")):
			start = int(o["tydzien_wystawienia"])
		else:
			o["tydzien_wystawienia"] = tydzien
		if tydzien - start >= waznosc:
			continue
		out.append(o)
	return out


func _wylosuj_auto_pod_filtr(
	hero: Dictionary,
	mid: String,
	miasta: Array,
	rng: RandomNumberGenerator,
	filtry: Dictionary
) -> Dictionary:
	var poziom := str(filtry.get("poziom", "miasto"))
	var stan := str(filtry.get("stan", ""))
	var marki: Array = filtry.get("marki", []) if filtry.get("marki") is Array else []
	var naped := str(filtry.get("naped", ""))
	if stan != "nowy" and stan != "uzywany":
		stan = "nowy" if rng.randf() < 0.3 else "uzywany"
	if stan == "nowy":
		return _nowe_auto_w_filtrze(hero, mid, miasta, rng, filtry, marki, naped, poziom)
	var pula := _miasta_poziomu(poziom, hero, miasta)
	if pula.is_empty():
		return {}
	var cel: Dictionary = pula[rng.randi_range(0, pula.size() - 1)]
	if (poziom == "sasiedzi" or poziom == "wysylka_zagranica") and rng.randf() < 0.2:
		var kraj_z := "DE" if poziom == "sasiedzi" else "NL"
		cel = {
			"id": "zagranica_%s" % kraj_z.to_lower(),
			"nazwa": kraj_z,
			"powiat_id": "",
			"wojewodztwo": "",
			"kraj": kraj_z,
		}
	var rekord := {}
	for _i in 12:
		var r: Dictionary = _losuj_rekord_katalogu_aut(rng, true)
		if r.is_empty():
			break
		if not marki.is_empty() and not marki.has(str(r.get("marka", ""))):
			continue
		if naped != "" and str(r.get("naped", "")) != naped:
			continue
		rekord = r
		break
	if rekord.is_empty():
		return {}
	var oferta := _losuj_samochod(hero, rng, mid, {}, "uzywany", poziom, miasta, false, cel, rekord)
	if oferta.is_empty() or not _oferta_miesci_sie_w_filtrze(oferta, filtry):
		return {}
	oferta["salon"] = false
	oferta["sprzedawca"] = "osoba_prywatna"
	oferta["sposob_odbioru"] = "osobisty"
	oferta["cena_dostawy_zl"] = null
	return oferta


func _nowe_auto_w_filtrze(
	hero: Dictionary,
	mid: String,
	miasta: Array,
	rng: RandomNumberGenerator,
	filtry: Dictionary,
	marki: Array,
	naped: String,
	poziom: String
) -> Dictionary:
	var pary: Array = []
	var marki_szukane: Array = marki
	if marki_szukane.is_empty():
		marki_szukane = _marki_z_jakimkolwiek_salonem()
	for marka_v in marki_szukane:
		var marka := str(marka_v)
		for s in miasta_salonu_marki(marka, miasta):
			if s is Dictionary and _miasto_w_poziomie(s, hero, poziom):
				pary.append({"marka": marka, "miasto": s})
	if pary.is_empty():
		if poziom == "sasiedzi" or poziom == "wysylka_zagranica":
			return _import_pod_filtr(hero, rng, filtry, marki, naped)
		return {}
	var para: Dictionary = pary[rng.randi_range(0, pary.size() - 1)]
	var modele := _modele_marki(str(para.get("marka", "")), true, naped)
	if modele.is_empty():
		return {}
	var rekord: Dictionary = _losuj_rekord_wazony(modele, rng, false)
	if rekord.is_empty():
		return {}
	var cel: Dictionary = para.get("miasto", {})
	var oferta := _oferta_nowa_z_rekordu_katalogu(rekord, rng, cel, hero, mid)
	if not _oferta_miesci_sie_w_filtrze(oferta, filtry):
		return {}
	return oferta


func _import_pod_filtr(
	hero: Dictionary,
	rng: RandomNumberGenerator,
	filtry: Dictionary,
	marki: Array,
	naped: String
) -> Dictionary:
	var kat := katalog_aut()
	var modele: Array = kat.get("modele", []) if kat.get("modele") is Array else []
	var kandydaci: Array = []
	for m in modele:
		if not (m is Dictionary):
			continue
		if bool(m.get("tylko_uzywane", false)):
			continue
		if not bool(m.get("sprowadzenie", false)) and not bool(m.get("import", false)):
			continue
		if not marki.is_empty() and not marki.has(str(m.get("marka", ""))):
			continue
		if naped != "" and str(m.get("naped", "")) != naped:
			continue
		if not miasta_salonu_marki(str(m.get("marka", "")), []).is_empty():
			continue
		kandydaci.append(m)
	if kandydaci.is_empty():
		return {}
	var rekord: Dictionary = kandydaci[rng.randi_range(0, kandydaci.size() - 1)]
	var oferta := _oferta_sprowadzona_bez_salonu(rekord, rng, hero)
	if not _oferta_miesci_sie_w_filtrze(oferta, filtry):
		return {}
	return oferta


func _modele_marki(marka: String, tylko_nowe: bool, naped: String) -> Array:
	var kat := katalog_aut()
	var modele: Array = kat.get("modele", []) if kat.get("modele") is Array else []
	var out: Array = []
	for m in modele:
		if not (m is Dictionary):
			continue
		if str(m.get("marka", "")) != marka:
			continue
		if tylko_nowe and bool(m.get("tylko_uzywane", false)):
			continue
		if naped != "" and str(m.get("naped", "")) != naped:
			continue
		out.append(m)
	return out


func _marki_z_jakimkolwiek_salonem() -> Array:
	var dane := _salony()
	var woj: Variant = dane.get("wojewodztwa", {})
	var out: Array = []
	var widziane := {}
	if not (woj is Dictionary):
		return out
	for w in (woj as Dictionary).keys():
		var blok: Variant = (woj as Dictionary)[w]
		if not (blok is Dictionary):
			continue
		for marka in (blok as Dictionary).keys():
			var nazwa := str(marka)
			if nazwa == "" or widziane.has(nazwa):
				continue
			var lista: Variant = (blok as Dictionary)[marka]
			if lista is Array and not (lista as Array).is_empty():
				widziane[nazwa] = true
				out.append(nazwa)
	return out


func _miasto_w_poziomie(cel: Dictionary, hero: Dictionary, poziom: String) -> bool:
	var idc := str(cel.get("id", ""))
	var idh := str(hero.get("id", ""))
	var ten_sam := idc != "" and idc == idh
	var pow_ok := str(hero.get("powiat_id", "")) != "" and str(cel.get("powiat_id", "")) == str(hero.get("powiat_id", ""))
	var woj_ok := str(hero.get("wojewodztwo", "")) != "" and str(cel.get("wojewodztwo", "")) == str(hero.get("wojewodztwo", ""))
	match poziom:
		"miasto", "":
			return ten_sam
		"powiat":
			return ten_sam or pow_ok
		"wojewodztwo":
			return ten_sam or pow_ok or woj_ok
		"sasiedzi", "wysylka_zagranica", "polska":
			return _kraj_polska(cel) or ten_sam
		_:
			return _kraj_polska(cel) or ten_sam


func _miasta_poziomu(poziom: String, hero: Dictionary, miasta: Array) -> Array:
	var out: Array = []
	for m in miasta:
		if m is Dictionary and _miasto_w_poziomie(m, hero, poziom):
			out.append(m)
	if out.is_empty() and (poziom == "miasto" or poziom == "") and not hero.is_empty():
		out.append(hero)
	return out


func _oferta_miesci_sie_w_filtrze(oferta: Dictionary, filtry: Dictionary) -> bool:
	var km := float(filtry.get("km", 9999.0))
	if _liczba(oferta.get("odleglosc_km")) and float(oferta["odleglosc_km"]) > km + 0.001:
		return false
	if bool(filtry.get("filtruj_cene", false)) and _liczba(oferta.get("cena_zl")):
		var c := float(oferta["cena_zl"])
		if c < float(filtry.get("cena_od", 0.0)) - 0.001 or c > float(filtry.get("cena_do", 1.0e12)) + 0.001:
			return false
	if bool(filtry.get("filtruj_przebieg", false)) and _liczba(oferta.get("przebieg_km")):
		var p := float(oferta["przebieg_km"])
		if p < float(filtry.get("przebieg_od", 0.0)) - 0.001 or p > float(filtry.get("przebieg_do", 1.0e12)) + 0.001:
			return false
	return true


func _pula_z_ludnosci(ludnosc: int, dzielnik: int) -> int:
	## round(ludność / dzielnik). Przy ludności > 0 minimum 1. Przy 0 zostaje 1, jak dawniej przy aucie.
	if ludnosc <= 0:
		return 1
	var d := maxi(1, dzielnik)
	return maxi(1, int(round(float(ludnosc) / float(d))))


func baza_ogloszen_aut(ludnosc: int) -> int:
	## Używane auta: 1 ogłoszenie na 1500 mieszkańców. Nowe z salonu poza tym limitem.
	return _pula_z_ludnosci(ludnosc, DZIELNIK_AUT_UZYWANYCH)


func baza_ogloszen_lokum(ludnosc: int) -> int:
	## Używane domy i mieszkania zostają przy 1 na 5000. To nie jest stawka aut.
	return _pula_z_ludnosci(ludnosc, DZIELNIK_LOKUM_UZYWANYCH)


func baza_ogloszen_lokum_nowych(ludnosc: int) -> int:
	## Nowe domy albo nowe mieszkania, osobno od używanych: 1 na 3500.
	## Dom i mieszkanie mają każde własną pulę tej wielkości.
	return _pula_z_ludnosci(ludnosc, DZIELNIK_LOKUM_NOWYCH)


## propozycja_do_poprawki. Stojący stan używanych w Polsce (patrz stałe STAN_KRAJOWY_*).
## Nowe nie mają dzielnika: pula to katalog, nie ludność.
func stan_krajowy_uzywanych(kategoria: String) -> int:
	match kategoria:
		"telefon":
			return STAN_KRAJOWY_TELEFON_UZYWANY
		"laptop":
			return STAN_KRAJOWY_LAPTOP_UZYWANY
		"komputer":
			return STAN_KRAJOWY_KOMPUTER_UZYWANY
		"rower":
			return STAN_KRAJOWY_ROWER_UZYWANY
		"sprzet":
			return STAN_KRAJOWY_SPRZET_UZYWANY
		_:
			return 0


func baza_uzywanych_drobnych(ludnosc: int, kategoria: String) -> int:
	## Udział stanu krajowego: round(ludność × stan / ludność Polski). Polska wychodzi równo w stan.
	var stan := stan_krajowy_uzywanych(kategoria)
	var kraj := ludnosc_zakresu("polska", "")
	if ludnosc <= 0 or stan <= 0 or kraj <= 0:
		return 1
	return maxi(1, int(round(float(ludnosc) * float(stan) / float(kraj))))


func baza_ogloszen_drobnych(ludnosc: int, kategoria: String, strona: String = "uzywany") -> int:
	if strona == "nowy":
		return liczba_modeli_katalogu(kategoria)
	return baza_uzywanych_drobnych(ludnosc, kategoria)


func kategoria_drobna(kategoria: String) -> bool:
	return kategoria == "telefon" or kategoria == "laptop" or kategoria == "komputer" or kategoria == "rower" or kategoria == "sprzet"


func kategoria_lokum(kategoria: String) -> bool:
	return kategoria == "mieszkanie" or kategoria == "dom" or kategoria == "apartament" or kategoria == "willa"


## Udział puli względem mieszkania. Ta sama kolejność co rynek_wagi_typu.
func _udzial_ofert_lokum(kategoria: String) -> float:
	match kategoria:
		"mieszkanie":
			return 1.0
		"apartament":
			return 0.55
		"dom":
			return 0.34
		"willa":
			return 0.12
		_:
			return 1.0


func kategoria_daje_plusy(kategoria: String) -> bool:
	return kategoria_drobna(kategoria)


## Przy zasięgu województwo: suma baz miast w województwie (lub próbka z capem).
func baza_ogloszen_aut_wojewodztwa(miasta: Array, wojewodztwo: String, _cap_probki: int = -1) -> int:
	if wojewodztwo.strip_edges() == "":
		return 1
	var suma_lud := 0
	for m in miasta:
		if not (m is Dictionary):
			continue
		if str(m.get("wojewodztwo", "")) != wojewodztwo:
			continue
		suma_lud += _ludnosc_miasta(m)
	# Cap próbki (dawniej 120) ucinał województwo i Polskę do garści.
	# Pula jest liczbą. Do pamięci i tak wchodzi tylko okno przy przewijaniu.
	return baza_ogloszen_aut(suma_lud)


func kategoria_ma_pule_ludnosci(kategoria: String) -> bool:
	return kategoria == "samochod" or kategoria_lokum(kategoria) or kategoria_drobna(kategoria)


func kategoria_ma_nowe_lokum(kategoria: String) -> bool:
	return kategoria == "dom" or kategoria == "mieszkanie"


static func trzeba_dociagnac_przed_koncem(zostalo_px: float) -> bool:
	## Prawda, zanim palec dojedzie do ostatniej karty. 280 px było już przy samym dole.
	return zostalo_px <= PROG_DOCIAGANIA_PX


func ostatnia_pula() -> int:
	return _ostatnia_pula


## Miasto = ludność tego miasta, województwo = całe województwo, Polska = kraj.
## Ta sama ludność co rynek pracy (bez wymyślania GUS).
func ludnosc_zakresu(poziom: String, id_miejsca: String) -> int:
	var p := poziom.strip_edges()
	var miejsca := _miejsca_ludnosci()
	if p == "powiat":
		var hero := _miejsce_bohatera(id_miejsca)
		var pow := str(hero.get("powiat_id", ""))
		if pow == "":
			return 0
		var suma := 0
		for m in miejsca:
			if not (m is Dictionary):
				continue
			if str(m.get("powiat_id", "")) != pow:
				continue
			if not _miejsce_w_polsce(m):
				continue
			suma += _ludnosc_miasta(m)
		return suma
	if p != "miasto" and p != "wojewodztwo" and p != "polska":
		return 0
	return _rynek_pracy().ludnosc_zakresu(miejsca, p, id_miejsca)


## -1: kategoria albo zasięg bez ludności, albo nowe auto z salonu (poza pulą).
## Auta używane: /1500. Lokale używane: /5000. Nowe dom i mieszkanie: /3500.
## Drobne nowe: liczba modeli katalogu, ta sama w mieście i w Polsce.
## Drobne używane: udział stanu krajowego (propozycja_do_poprawki), rośnie z ludnością.
func pula_w_zasiegu(poziom: String, id_miejsca: String, kategoria: String, strona: String = "") -> int:
	if not kategoria_ma_pule_ludnosci(kategoria):
		_ostatnia_pula = -1
		return -1
	if kategoria == "samochod" and strona == "nowy":
		_ostatnia_pula = -1
		return -1
	var p := poziom.strip_edges()
	if p != "miasto" and p != "powiat" and p != "wojewodztwo" and p != "polska":
		_ostatnia_pula = -1
		return -1
	var lud := ludnosc_zakresu(p, id_miejsca)
	var n := baza_ogloszen_aut(lud)
	if kategoria_drobna(kategoria):
		var strona_d := "nowy" if strona == "nowy" else "uzywany"
		n = baza_ogloszen_drobnych(lud, kategoria, strona_d)
	elif kategoria != "samochod":
		if strona == "nowy" and kategoria_ma_nowe_lokum(kategoria):
			n = baza_ogloszen_lokum_nowych(lud)
		else:
			n = baza_ogloszen_lokum(lud)
		n = maxi(1, int(round(float(n) * _udzial_ofert_lokum(kategoria))))
	_ostatnia_pula = n
	return n


func ile_w_zasiegu(swiat: Dictionary, kategoria: String, poziom: String, stan_oferty: String = "") -> int:
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		return 0
	var n := 0
	for o in stan["oferty"]:
		if not (o is Dictionary):
			continue
		if str(o.get("kategoria", "")) != kategoria:
			continue
		if stan_oferty == "nowy" or stan_oferty == "uzywany":
			if bool(o.get("nieruchomosc", false)):
				if str(o.get("rynek_stan", "uzywany")) != stan_oferty:
					continue
			elif str(o.get("stan", "")) != stan_oferty:
				continue
		if poziom != "" and not oferta_w_zasiegu_poziomu(o, poziom, swiat):
			continue
		n += 1
	return n


func tekst_odleglosci_km(km: Variant) -> String:
	if not _liczba(km):
		return ""
	var v := maxf(0.0, float(km))
	if v < 10.0:
		return ("%.1f" % v).replace(".", ",") + " km"
	return "%d km" % int(round(v))


func tekst_linii_miejsca(oferta: Dictionary) -> String:
	var miasto := str(oferta.get("miasto_nazwa", "?"))
	var km := tekst_odleglosci_km(oferta.get("odleglosc_km"))
	if km == "":
		return miasto
	return "%s · %s" % [miasto, km]


## Druga linia karty: miasto i km od domu. Odbiór auta zostaje przy dotychczasowych regułach.
func tekst_karty_miejsca(oferta: Dictionary, odbior: String = "") -> String:
	var linia := tekst_linii_miejsca(oferta)
	if bool(oferta.get("nieruchomosc", false)):
		var stan_id := str(oferta.get("stan", ""))
		var stan_txt := etykieta_stanu(stan_id)
		if stan_id == "surowy":
			stan_txt = "stan surowy"
		elif str(oferta.get("rynek_stan", "")) == "nowy" and stan_txt != "":
			stan_txt = "nowy · " + stan_txt
		return "%s · %s · %d pok. · wygoda %d" % [linia, stan_txt, int(oferta.get("pokoje", 0)), int(oferta.get("wygoda", 0))]
	if odbior == "":
		if str(oferta.get("kategoria", "")) == "samochod":
			odbior = tekst_odbioru_auta(oferta)
		else:
			odbior = str(oferta.get("sposob_odbioru", ""))
	return "%s · %s" % [linia, odbior]


func etykieta_stanu(stan_id: String) -> String:
	var dane := wczytaj()
	if dane.get("etykiety_stanu") is Dictionary and (dane["etykiety_stanu"] as Dictionary).has(stan_id):
		return str(dane["etykiety_stanu"][stan_id])
	return stan_id


func _przytnij_porcje_do_puli(swiat: Dictionary, stan: Dictionary, kategoria: String, poziom: String, porcja: int, strona: String = "") -> int:
	var id := _id_ludnosci(stan, "")
	var pula := pula_w_zasiegu(poziom, id, kategoria, strona)
	if pula < 0:
		return porcja
	var licznik := strona
	if licznik == "" and (kategoria == "samochod" or kategoria_drobna(kategoria)):
		licznik = "uzywany"
	var juz := ile_w_zasiegu(swiat, kategoria, poziom, licznik)
	return mini(porcja, maxi(0, pula - juz))


func _id_ludnosci(stan: Dictionary, fallback: String) -> String:
	var zrodlo := str(stan.get("miejsce_zrodlo_id", "")).strip_edges()
	if zrodlo != "":
		return zrodlo
	var mid := str(stan.get("miasto_gracza_id", "")).strip_edges()
	if mid != "":
		return mid
	return fallback


func _miejsca_ludnosci() -> Array:
	if not _miejsca_ludnosci_cache.is_empty():
		return _miejsca_ludnosci_cache
	var los := Losowanie.new()
	_miejsca_ludnosci_cache = los.wszystkie_z_ludnoscia()
	return _miejsca_ludnosci_cache


func _rynek_pracy() -> RynekPracy:
	if _praca_ref == null:
		_praca_ref = RynekPracy.new()
	return _praca_ref


func _miejsce_bohatera(id_miejsca: String) -> Dictionary:
	var karta: Dictionary = _rynek_pracy().miasto_bohatera(_miejsca_ludnosci(), id_miejsca)
	if bool(karta.get("brak", false)):
		return karta
	var pelne := _wzbogac_jedno_miasto(_miasto_po_id(_miejsca_ludnosci(), str(karta.get("id", ""))))
	pelne["ludnosc"] = int(karta.get("ludnosc", 0))
	pelne["brak"] = false
	pelne["nazwa"] = str(karta.get("nazwa", pelne.get("nazwa", "")))
	if str(karta.get("wojewodztwo", "")) != "":
		pelne["wojewodztwo"] = str(karta.get("wojewodztwo", ""))
	return pelne


func _miejsce_w_polsce(miejsce: Dictionary) -> bool:
	var pid := str(miejsce.get("panstwo_id", "")).strip_edges().to_lower()
	if pid == "polska":
		return true
	var pan := str(miejsce.get("panstwo", "")).strip_edges().to_lower()
	if pan == "polska":
		return true
	if pid == "" and pan == "" and str(miejsce.get("wojewodztwo", "")).strip_edges() != "":
		return true
	return false


func pasmo_ogloszen_aut(baza: int, rozbieznosc: float = 0.30) -> Vector2i:
	var b := maxi(1, baza)
	var lo := maxi(1, int(floor(float(b) * (1.0 - rozbieznosc))))
	var hi := maxi(lo, int(ceil(float(b) * (1.0 + rozbieznosc))))
	return Vector2i(lo, hi)


func ile_aut_w_miescie(oferty: Array, miasto_id: String) -> int:
	## Licznik puli lokalnej: używane w mieście z regionem „miasto”
	## (bez nowych z katalogu i bez szerszego zasięgu powiat→zagranica).
	var n := 0
	for o in oferty:
		if not (o is Dictionary):
			continue
		if str(o.get("kategoria", "")) != "samochod":
			continue
		if str(o.get("stan", "")) != "uzywany":
			continue
		if bool(o.get("z_katalogu_globalny", false)):
			continue
		var reg := str(o.get("region_szukania", "miasto"))
		if reg != "" and reg != "miasto":
			continue
		if str(o.get("miasto_id", "")) == miasto_id or bool(o.get("miasto_gracza", false)):
			n += 1
	return n


func oferty_filtrowane(
	swiat: Dictionary,
	kategoria: String,
	stan_filtr: String,
	zasieg_km: float,
	cena_od: float,
	cena_do: float,
	filtruj_cene: bool,
	odbior_filtr: String = "",
	przebieg_od: float = 0.0,
	przebieg_do: float = 1.0e12,
	filtruj_przebieg: bool = false,
	marka_filtr: Variant = "",
	naped_filtr: String = "",
	zasieg_poziom: String = ""
) -> Array:
	var wynik: Array = []
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		return wynik
	var marki_wybrane: Array = _normalizuj_filtr_marek(marka_filtr)
	for o in stan["oferty"]:
		if not (o is Dictionary):
			continue
		if str(o.get("kategoria", "")) != kategoria:
			continue
		if stan_filtr == "nowy" or stan_filtr == "uzywany":
			if bool(o.get("nieruchomosc", false)):
				if str(o.get("rynek_stan", "uzywany")) != stan_filtr:
					continue
			elif str(o.get("stan", "")) != stan_filtr:
				continue
		elif stan_filtr != "" and not bool(o.get("nieruchomosc", false)):
			if str(o.get("stan", "")) != stan_filtr:
				continue
		# Salon i używane: zasięg km i poziom (miasto / województwo / Polska).
		if _liczba(o.get("odleglosc_km")):
			if float(o["odleglosc_km"]) > zasieg_km + 0.001:
				continue
		if zasieg_poziom != "" and not oferta_w_zasiegu_poziomu(o, zasieg_poziom, swiat):
			continue
		if filtruj_cene and _liczba(o.get("cena_zl")):
			var c := float(o["cena_zl"])
			if c < cena_od - 0.001 or c > cena_do + 0.001:
				continue
		if odbior_filtr != "" and not _pasuje_odbior(str(o.get("sposob_odbioru", "oba")), odbior_filtr):
			continue
		if filtruj_przebieg and kategoria == "samochod" and _liczba(o.get("przebieg_km")):
			var p := float(o["przebieg_km"])
			if p < przebieg_od - 0.001 or p > przebieg_do + 0.001:
				continue
		if not marki_wybrane.is_empty() and not marki_wybrane.has(str(o.get("marka", ""))):
			continue
		if naped_filtr != "" and str(o.get("naped", "")) != naped_filtr:
			continue
		wynik.append(o)
	return wynik


func _normalizuj_filtr_marek(marka_filtr: Variant) -> Array:
	## Puste = wszystkie. String (stary API) albo Array kilku marek naraz.
	var out: Array = []
	if marka_filtr is Array:
		for m in marka_filtr:
			var s := str(m).strip_edges()
			if s != "" and not out.has(s):
				out.append(s)
		return out
	var jedna := str(marka_filtr).strip_edges()
	if jedna != "":
		out.append(jedna)
	return out


func katalog_aut() -> Dictionary:
	if _katalog_aut is Dictionary:
		return _katalog_aut
	var zlaczone := {
		"opis": "Złączone paczki katalog_aut_*.json (indeks). Nie komplet wszystkich SKU EU.",
		"napedy": [],
		"modele": [],
		"paczki": [],
	}
	var sciezki: Array = []
	if FileAccess.file_exists(PLIK_KATALOG_INDEX):
		var idx: Variant = _czytaj_json_plik(PLIK_KATALOG_INDEX)
		if idx is Dictionary:
			if idx.get("napedy") is Array:
				zlaczone["napedy"] = idx["napedy"]
			if idx.get("paczki") is Array:
				sciezki = idx["paczki"]
			zlaczone["uwaga_kompletnosci"] = idx.get("uwaga_kompletnosci", "")
	if sciezki.is_empty():
		sciezki = [PLIK_KATALOG_AUT]
	var widziane_id := {}
	for sciezka_v in sciezki:
		var sciezka := str(sciezka_v)
		var paczka: Variant = _czytaj_json_plik(sciezka)
		if not (paczka is Dictionary):
			continue
		zlaczone["paczki"].append(sciezka)
		if zlaczone["napedy"].is_empty() and paczka.get("napedy") is Array:
			zlaczone["napedy"] = paczka["napedy"]
		if not (paczka.get("modele") is Array):
			continue
		for m in paczka["modele"]:
			if not (m is Dictionary):
				continue
			var mid := str(m.get("id", ""))
			if mid == "" or widziane_id.has(mid):
				continue
			widziane_id[mid] = true
			zlaczone["modele"].append(m)
	_katalog_aut = zlaczone
	return zlaczone


func _czytaj_json_plik(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())


func marki_katalogu_aut() -> Array:
	var widziane := {}
	var lista: Array = []
	var kat := katalog_aut()
	if not (kat.get("modele") is Array):
		return lista
	for m in kat["modele"]:
		if not (m is Dictionary):
			continue
		var marka := str(m.get("marka", ""))
		if marka == "" or widziane.has(marka):
			continue
		widziane[marka] = true
		lista.append(marka)
	lista.sort()
	return lista


func napedy_katalogu_aut() -> Array:
	var kat := katalog_aut()
	if kat.get("napedy") is Array:
		return kat["napedy"]
	return [
		{"id": "spalinowy", "nazwa": "Spalinowy"},
		{"id": "lpg", "nazwa": "Z gazem (LPG)"},
		{"id": "hybryda", "nazwa": "Hybryda"},
		{"id": "elektryczny", "nazwa": "Elektryczny"},
	]


func tekst_spalania(oferta: Dictionary) -> String:
	if oferta.get("spalanie_ukryte") == true or not _liczba(oferta.get("spalanie")):
		return "nie podano"
	var jedn := str(oferta.get("spalanie_jednostka", "l/100 km"))
	if jedn == "":
		jedn = "l/100 km"
	return "%.1f %s" % [float(oferta["spalanie"]), jedn]


func etykieta_napedu(naped_id: String) -> String:
	for n in napedy_katalogu_aut():
		if n is Dictionary and str(n.get("id", "")) == naped_id:
			return str(n.get("nazwa", naped_id))
	match naped_id:
		"lpg":
			return "Z gazem (LPG)"
		"spalinowy":
			return "Spalinowy"
		"hybryda":
			return "Hybryda"
		"elektryczny":
			return "Elektryczny"
		_:
			return naped_id


## odbior_filtr: "" = bez filtra, "osobisty", "wysylka"/"dostawa". Oferta "oba" przechodzi oba.
func _pasuje_odbior(sposob: String, filtr: String) -> bool:
	if filtr == "":
		return true
	if sposob == "" or sposob == "oba":
		return true
	if filtr == "wysylka" or filtr == "dostawa":
		return sposob == "wysylka" or sposob == "dostawa" or sposob == "oba"
	return sposob == filtr


## Po wyliczeniu kwoty — krok z zaokraglanie_cen (propozycja_do_poprawki).
## Samochody: 3 pierwsze znaczące + reguły >9900 / >999000 (patrz formatuj / JSON przykłady).
## Zwraca int; gdy kwota nie jest liczbą → -1 (wywołujący zostawia null).
func zaokraglij_cene(kategoria: String, kwota: Variant) -> int:
	if not _liczba(kwota):
		return -1
	var v := float(kwota)
	if v <= 0.0:
		return int(round(v))
	if kategoria == "samochod":
		return zaokraglij_cene_auta(v)
	var krok := _krok_zaokraglenia(kategoria)
	if krok <= 0:
		return int(round(v))
	return int(round(v / float(krok)) * krok)


## 3 pierwsze znaczące cyfry; powyżej 9 900 zł setki odpadają (do tysięcy);
## powyżej 999 000 zł tysiące odpadają (do dziesiątek tysięcy).
func zaokraglij_cene_auta(kwota: Variant) -> int:
	if not _liczba(kwota):
		return -1
	var v := float(kwota)
	if v <= 0.0:
		return int(round(v))
	var trzy := _zaokraglij_3_znaczace(v)
	if trzy > 999000.0:
		return int(round(trzy / 10000.0) * 10000)
	if trzy > 9900.0:
		return int(round(trzy / 1000.0) * 1000)
	return int(round(trzy))


func _zaokraglij_3_znaczace(v: float) -> float:
	if v <= 0.0:
		return 0.0
	var wykladnik: float = floor(log(v) / log(10.0)) - 2.0
	var factor: float = pow(10.0, wykladnik)
	if factor <= 0.0:
		return v
	return round(v / factor) * factor


## Wspólne formatowanie UI aut: spacje co 3 cyfry, np. „1 100 000 zł”.
func formatuj_cene_auta(cena: Variant) -> String:
	if not _liczba(cena):
		return "—"
	var n := int(cena)
	var ujemna := n < 0
	var s := str(absi(n))
	var out := ""
	var licznik := 0
	for i in range(s.length() - 1, -1, -1):
		if licznik > 0 and licznik % 3 == 0:
			out = " " + out
		out = s[i] + out
		licznik += 1
	if ujemna:
		out = "-" + out
	return "%s zł" % out


func etykieta_stanu_jakosci(wartosc: int) -> String:
	var conf := _stan_jakosci_conf()
	var progi: Array = conf.get("etykiety_progow", []) if conf.get("etykiety_progow") is Array else []
	var v := clampi(wartosc, 0, 100)
	for p in progi:
		if not (p is Dictionary):
			continue
		if v <= int(p.get("do", 100)):
			return str(p.get("nazwa", p.get("id", str(v))))
	return str(v)


## Ujawnienie stanu rzeczywistego (z szumem).
## Odbiór osobisty: zawsze przed zakupem. Sama wysyłka: po dostawie / po oględzinach
## (wolno ocenić każdy samochód z polem stanu; tryb w out["tryb_oceny"]).
func ocen_stan(swiat: Dictionary, oferta_id: String, z_pomoca: bool = false) -> Dictionary:
	var out := {
		"ok": false,
		"powod": "",
		"stan_oceniony": null,
		"stan_rzeczywisty": null,
		"tryb_oceny": "",
		"propozycja_do_poprawki": true,
	}
	var oferta: Dictionary = _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Brak oferty."
		return out
	if str(oferta.get("kategoria", "")) == "samochod" and not auto_na_miejscu(swiat, oferta):
		out["powod"] = "Najpierw wybierz dojazd do auta."
		return out
	var tryb := tryb_oceny_stanu(oferta)
	if tryb == "":
		out["powod"] = "Tej oferty nie da się ocenić."
		return out
	if tryb == "po_dostawie" and not bool(oferta.get("kupione", false)) and not bool(oferta.get("ogledziny_umowione", false)):
		# Przy samej wysyłce: ocena po oględzinach / po dostawie — umów oględziny albo kup.
		oferta["ogledziny_umowione"] = true
		_zapisz_oferte(swiat, oferta)
	if not _liczba(oferta.get("stan_rzeczywisty")):
		out["powod"] = "Ta oferta nie ma stanu jakości do oceny."
		return out
	var conf := _ocena_stanu_conf()
	var szum_blok: Dictionary = {}
	if z_pomoca:
		szum_blok = conf.get("szum_z_pomoca", {}) if conf.get("szum_z_pomoca") is Dictionary else {}
	else:
		szum_blok = conf.get("szum_wlasnej_oceny", {}) if conf.get("szum_wlasnej_oceny") is Dictionary else {}
	var szum_od := int(szum_blok.get("od", -5))
	var szum_do := int(szum_blok.get("do", 5))
	if tryb == "po_dostawie" and not z_pomoca:
		# Po oględzinach / dostawie — nieco większy szum bez eksperta.
		szum_od -= 2
		szum_do += 2
	var poz := poziom_wiedzy_oceny(swiat, str(oferta.get("kategoria", "")))
	out["poziom_wiedzy"] = poz
	if not z_pomoca and poz < 0.2:
		out["ok"] = true
		out["nieznany"] = true
		out["tekst"] = "Za mało wiedzy, żeby ocenić stan."
		return out
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rzeczywisty := clampi(int(oferta["stan_rzeczywisty"]), 0, 100)
	if not z_pomoca:
		var t := clampf((poz - 0.2) / 0.8, 0.0, 1.0)
		var polowa := int(round(lerpf(24.0, 2.0, t)))
		szum_od = -polowa
		szum_do = polowa
	var oceniony := clampi(rzeczywisty + rng.randi_range(szum_od, szum_do), 0, 100)
	oferta["stan_ujawniony"] = true
	oferta["stan_oceniony"] = oceniony
	oferta["ocena_z_pomoca"] = z_pomoca
	oferta["tryb_oceny"] = tryb
	_zapisz_oferte(swiat, oferta)
	out["ok"] = true
	out["tryb_oceny"] = tryb
	out["stan_oceniony"] = oceniony
	out["stan_rzeczywisty"] = rzeczywisty
	out["stan_deklarowany"] = oferta.get("stan_deklarowany")
	out["rozjazd"] = _liczba(oferta.get("stan_deklarowany")) and int(oferta["stan_deklarowany"]) != rzeczywisty
	out["etykieta"] = etykieta_stanu_jakosci(oceniony)
	out["usterki_wykryte"] = wykryj_usterki(swiat, oferta, z_pomoca)
	out["tekst"] = "Ocena stanu: %d (%s)." % [oceniony, str(out.get("etykieta", ""))]
	return out


## 0–1. Wiedza 20 albo znajomość aut 100 = pewna ocena. Poniżej 0,2 gracz nie ocenia sam.
func poziom_wiedzy_oceny(swiat: Dictionary, kat: String) -> float:
	var boh: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	var w := 0.0
	if _liczba(boh.get("wiedza_pkt")):
		w = clampf(float(boh["wiedza_pkt"]) / 20.0, 0.0, 1.0)
	if kat == "samochod":
		w = maxf(w, clampf(_poziom_znajomosci_pojazdow(swiat) / 100.0, 0.0, 1.0))
	return w


func ma_legitymacje(swiat: Dictionary) -> bool:
	var boh: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	if bool(boh.get("uczy_sie", false)) or bool(boh.get("studiuje", false)):
		return true
	var edukacja: Variant = boh.get("edukacja", [])
	if edukacja is Array:
		for e in edukacja:
			if e is Dictionary and (bool(e.get("trwa", false)) or bool(e.get("aktualna", false)) or bool(e.get("uczy_sie", false))):
				return true
	return false


## "" = nie; "przed_zakupem" = odbiór osobisty; "po_dostawie" = sama wysyłka.
func tryb_oceny_stanu(oferta: Dictionary) -> String:
	if not _liczba(oferta.get("stan_rzeczywisty")):
		return ""
	if bool(oferta.get("nieruchomosc", false)):
		return "przed_zakupem"
	var kat := str(oferta.get("kategoria", ""))
	var s := str(oferta.get("sposob_odbioru", "oba"))
	if kat == "samochod":
		if s == "wysylka" or s == "dostawa":
			return "po_dostawie"
		# osobisty / oba → ocena przed zakupem (przy oba: odbiór osobisty dostępny)
		return "przed_zakupem"
	if s == "osobisty" or s == "oba" or s == "":
		return "przed_zakupem"
	if s == "wysylka" or s == "dostawa":
		return "po_dostawie"
	return ""


## Osoby z zapisu: rodzice / przyjaciele / znajomi — do pomocy w ocenie.
func kandydaci_pomocy_oceny(swiat: Dictionary) -> Array:
	var out: Array = []
	var rodzina: Variant = swiat.get("rodzina", {})
	if rodzina is Dictionary:
		for rola in ["matka", "ojciec"]:
			var os: Variant = rodzina.get(rola)
			if os is Dictionary and not os.is_empty():
				out.append({
					"ref": "rodzic:%s" % rola,
					"rola": "rodzic",
					"klucz": rola,
					"osoba": os,
					"nazwa": _nazwa_osoby_pomocy(os, rola),
				})
	for klucz_listy in ["przyjaciele", "znajomi"]:
		var lista: Variant = swiat.get(klucz_listy, [])
		if not (lista is Array):
			continue
		var rola := "przyjaciel" if klucz_listy == "przyjaciele" else "znajomy"
		for i in lista.size():
			var os: Variant = lista[i]
			if not (os is Dictionary):
				continue
			out.append({
				"ref": "%s:%d" % [klucz_listy, i],
				"rola": rola,
				"klucz": i,
				"osoba": os,
				"nazwa": _nazwa_osoby_pomocy(os, rola),
			})
	return out


func popros_o_pomoc_oceny(swiat: Dictionary, oferta_id: String, kandydat_ref: String, dojazd: Dictionary = {}) -> Dictionary:
	var out := {
		"ok": false,
		"powod": "",
		"wynik": "",
		"tekst": "",
		"ocena_zaplanowana_tura": null,
		"propozycja_do_poprawki": true,
	}
	var oferta: Dictionary = _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Brak oferty."
		return out
	if str(oferta.get("kategoria", "")) == "samochod" and not auto_na_miejscu(swiat, oferta):
		if dojazd.is_empty():
			out["powod"] = "Wybierz dojazd w tym samym kroku co pomoc przy oględzinach."
			return out
		var dojazd_w := wykonaj_dojazd(swiat, oferta_id, dojazd)
		if not bool(dojazd_w.get("ok", false)):
			return dojazd_w
		out["dojazd"] = dojazd_w
	if tryb_oceny_stanu(oferta) == "":
		out["powod"] = "Pomoc w ocenie niedostępna dla tej oferty."
		return out
	var kandydat: Dictionary = {}
	for k in kandydaci_pomocy_oceny(swiat):
		if k is Dictionary and str(k.get("ref", "")) == kandydat_ref:
			kandydat = k
			break
	if kandydat.is_empty():
		out["powod"] = "Nie ma takiej osoby w zapisie."
		return out
	var conf := _ocena_stanu_conf()
	var pomoc: Dictionary = conf.get("pomoc", {}) if conf.get("pomoc") is Dictionary else {}
	var baza_map: Dictionary = pomoc.get("baza_szansy", {}) if pomoc.get("baza_szansy") is Dictionary else {}
	var rola := str(kandydat.get("rola", "znajomy"))
	var szansa := float(baza_map.get(rola, 0.3))
	var osoba: Dictionary = kandydat.get("osoba", {}) if kandydat.get("osoba") is Dictionary else {}
	var relacja := int(pomoc.get("relacja_bonus", {}).get("domyslna_relacja", 55)) if pomoc.get("relacja_bonus") is Dictionary else 55
	if _liczba(osoba.get("relacja")):
		relacja = clampi(int(osoba["relacja"]), 0, 100)
	elif _liczba(osoba.get("relacja_0_100")):
		relacja = clampi(int(osoba["relacja_0_100"]), 0, 100)
	szansa += (float(relacja) - 50.0) / 200.0
	var cechy := _ids_cech(osoba.get("charakter"))
	var chetniej: Dictionary = pomoc.get("cechy_chetniej", {}) if pomoc.get("cechy_chetniej") is Dictionary else {}
	var rzadziej: Dictionary = pomoc.get("cechy_rzadziej", {}) if pomoc.get("cechy_rzadziej") is Dictionary else {}
	for cid in cechy:
		if chetniej.has(cid):
			szansa += float(chetniej[cid])
		if rzadziej.has(cid):
			szansa += float(rzadziej[cid])
	szansa = clampf(szansa, 0.05, 0.95)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() > szansa:
		out["ok"] = true
		out["wynik"] = "odmowa"
		out["tekst"] = "%s odmawia pomocy w ocenie." % str(kandydat.get("nazwa", "Osoba"))
		return out
	var wagi_wyn: Dictionary = pomoc.get("wyniki_wagi", {}) if pomoc.get("wyniki_wagi") is Dictionary else {}
	var ids_w := ["zgoda_teraz", "odroczenie", "odmowa"]
	var wagi_w: Array = []
	for idw in ids_w:
		wagi_w.append(float(wagi_wyn.get(idw, 0.33)))
	var wybor := str(ids_w[_wazony_indeks(wagi_w, ids_w.size(), rng)])
	if wybor == "odmowa":
		out["ok"] = true
		out["wynik"] = "odmowa"
		out["tekst"] = "%s: nie tym razem." % str(kandydat.get("nazwa", "Osoba"))
		return out
	if wybor == "odroczenie":
		var od_wagi: Dictionary = pomoc.get("odroczenie_tygodnie_wagi", {}) if pomoc.get("odroczenie_tygodnie_wagi") is Dictionary else {}
		var tyg_ids: Array = []
		var tyg_wagi: Array = []
		for t in ["1", "2", "3", "4"]:
			var w := float(od_wagi.get(t, 0))
			if w <= 0.0:
				continue
			tyg_ids.append(int(t))
			tyg_wagi.append(w)
		if tyg_ids.is_empty():
			tyg_ids = [1, 2, 3, 4]
			tyg_wagi = [0.4, 0.3, 0.2, 0.1]
		var ile_tyg: int = int(tyg_ids[_wazony_indeks(tyg_wagi, tyg_ids.size(), rng)])
		var tura := int(swiat.get("tydzien", 1)) + ile_tyg
		oferta["ocena_zaplanowana_tura"] = tura
		oferta["ocena_zaplanowana_osoba"] = kandydat_ref
		_zapisz_oferte(swiat, oferta)
		out["ok"] = true
		out["wynik"] = "odroczenie"
		out["ocena_zaplanowana_tura"] = tura
		out["tekst"] = "%s: nie mogę teraz, może za %d %s." % [
			str(kandydat.get("nazwa", "Osoba")),
			ile_tyg,
			"tydzień" if ile_tyg == 1 else "tygodnie",
		]
		return out
	# zgoda teraz → od razu ocenia
	var ocena: Dictionary = ocen_stan(swiat, oferta_id, true)
	out["ok"] = bool(ocena.get("ok", false))
	out["wynik"] = "zgoda_teraz"
	out["tekst"] = "%s pomaga ocenić stan." % str(kandydat.get("nazwa", "Osoba"))
	out["ocena"] = ocena
	return out


## Targowanie tylko używane. propozycja_zl albo procent_ceny (suwak).
func targuj(swiat: Dictionary, oferta_id: String, propozycja_zl: Variant = null, procent_ceny: Variant = null) -> Dictionary:
	var out := {
		"ok": false,
		"powod": "",
		"wynik": "",
		"tekst": "",
		"dialog_id": "",
		"cena_zl": null,
		"koniec": false,
		"propozycja_do_poprawki": true,
	}
	var oferta: Dictionary = _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Brak oferty."
		return out
	if str(oferta.get("stan", "")) != "uzywany":
		out["powod"] = "Targowanie tylko przy używanych."
		return out
	if bool(oferta.get("targowanie_zakonczone", false)):
		out["powod"] = "Sprzedawca nie chce już rozmawiać."
		out["wynik"] = "koniec"
		out["koniec"] = true
		return out
	if not _liczba(oferta.get("cena_zl")):
		out["powod"] = "Brak ceny do targowania."
		return out
	var conf := _targowanie_conf()
	var dialogi := _wczytaj_dialogi_targ()
	var cena_wyjsciowa := int(oferta.get("cena_wyjsciowa", oferta["cena_zl"]))
	if not oferta.has("cena_wyjsciowa"):
		oferta["cena_wyjsciowa"] = cena_wyjsciowa
	var proponowana := 0
	if _liczba(propozycja_zl):
		proponowana = int(propozycja_zl)
	elif _liczba(procent_ceny):
		proponowana = int(round(float(cena_wyjsciowa) * float(procent_ceny) / 100.0))
	else:
		out["powod"] = "Podaj kwotę albo % ceny."
		return out
	proponowana = maxi(0, proponowana)
	var procent := 100.0
	if cena_wyjsciowa > 0:
		procent = 100.0 * float(proponowana) / float(cena_wyjsciowa)
	var prog_zaniz := float(conf.get("prog_bardzo_zanizona_procent_ceny", 55))
	if dialogi.get("prog_bardzo_zanizona_procent_ceny") != null and _liczba(dialogi.get("prog_bardzo_zanizona_procent_ceny")):
		prog_zaniz = float(dialogi["prog_bardzo_zanizona_procent_ceny"])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var runda := int(oferta.get("targowanie_runda", 0)) + 1
	oferta["targowanie_runda"] = runda
	if procent < prog_zaniz:
		var wpis: Dictionary = _losuj_dialog(dialogi, "obraza", rng)
		oferta["targowanie_zakonczone"] = true
		_zapisz_oferte(swiat, oferta)
		out["ok"] = true
		out["wynik"] = "obraza"
		out["koniec"] = true
		out["tekst"] = str(wpis.get("tekst", "Do widzenia."))
		out["dialog_id"] = str(wpis.get("id", ""))
		out["cena_zl"] = oferta.get("cena_zl")
		return out
	var prog_ok := float(conf.get("akceptacja_min_procent_ceny", 82))
	var max_rund := int(conf.get("max_rund", 3))
	if procent >= prog_ok or (runda >= max_rund and procent >= prog_zaniz + 10.0):
		var wpis_ok: Dictionary = _losuj_dialog(dialogi, "akceptacja", rng)
		var nowa: int = zaokraglij_cene(str(oferta.get("kategoria", "")), proponowana)
		oferta["cena_zl"] = nowa
		oferta["cena_wynegocjowana"] = nowa
		_zapisz_oferte(swiat, oferta)
		out["ok"] = true
		out["wynik"] = "akceptacja"
		out["tekst"] = str(wpis_ok.get("tekst", "Umowa stoi."))
		out["dialog_id"] = str(wpis_ok.get("id", ""))
		out["cena_zl"] = nowa
		return out
	var wpis_odm: Dictionary = _losuj_dialog(dialogi, "odmowa", rng)
	_zapisz_oferte(swiat, oferta)
	out["ok"] = true
	out["wynik"] = "odmowa"
	out["tekst"] = str(wpis_odm.get("tekst", "Za mało."))
	out["dialog_id"] = str(wpis_odm.get("id", ""))
	out["cena_zl"] = oferta.get("cena_zl")
	out["mozna_kolejna_runde"] = runda < max_rund
	return out


func kup(swiat: Dictionary, oferta_id: String) -> Dictionary:
	var out := {"ok": false, "powod": "", "oferta": null}
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		out["powod"] = "Brak puli ofert."
		return out
	var oferta: Dictionary = {}
	var idx := -1
	for i in range(stan["oferty"].size()):
		var o: Variant = stan["oferty"][i]
		if o is Dictionary and str(o.get("id", "")) == oferta_id:
			oferta = o
			idx = i
			break
	if idx < 0:
		out["powod"] = "Oferta zniknęła z rynku."
		return out
	if str(oferta.get("kategoria", "")) == "samochod" and not auto_na_miejscu(swiat, oferta):
		out["powod"] = "Najpierw wybierz dojazd do auta."
		return out
	if bool(oferta.get("targowanie_zakonczone", false)) and not oferta.has("cena_wynegocjowana"):
		out["powod"] = "Sprzedawca nie chce już sprzedawać Tobie."
		return out
	var cena: Variant = oferta.get("cena_zl")
	var bohater: Dictionary = {}
	if swiat.get("bohater") is Dictionary:
		bohater = swiat["bohater"]
	var kasa := 0
	if _liczba(bohater.get("pieniadze")):
		kasa = int(bohater["pieniadze"])
	var wysylka := 0
	var odbior_wybrany := str(oferta.get("odbior_wybrany", ""))
	if odbior_wybrany == "wysylka" or (odbior_wybrany == "" and str(oferta.get("sposob_odbioru", "")) == "wysylka"):
		wysylka = koszt_wysylki_zl(oferta)
	var do_zaplaty := wysylka
	if _liczba(cena):
		do_zaplaty += int(cena)
	if do_zaplaty > 0 and kasa < do_zaplaty:
		out["powod"] = "Za mało pieniędzy (%d < %d)." % [kasa, do_zaplaty]
		return out
	if do_zaplaty > 0:
		bohater["pieniadze"] = kasa - do_zaplaty
		swiat["bohater"] = bohater
	if not (swiat.get("majatek") is Dictionary):
		swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	var maj: Dictionary = swiat["majatek"]
	var kopia := oferta.duplicate(true)
	kopia["kupiono_tydzien"] = int(swiat.get("tydzien", 0))
	# Po zakupie gracz „widzi” rzeczywisty stan (ryzyko bez wcześniejszej oceny).
	if _liczba(kopia.get("stan_rzeczywisty")):
		kopia["stan_po_zakupie"] = int(kopia["stan_rzeczywisty"])
	if bool(oferta.get("nieruchomosc", false)):
		if not (maj.get("nieruchomosci") is Array):
			maj["nieruchomosci"] = []
		maj["nieruchomosci"].append(kopia)
		# Przeprowadzka gdy inne miasto.
		var mid := str(oferta.get("miasto_id", ""))
		var mnaz := str(oferta.get("miasto_nazwa", ""))
		var gracz_id := str(stan.get("miasto_gracza_id", ""))
		if mid != "" and mid != gracz_id:
			swiat["nazwa_miejsca"] = mnaz
			swiat["id_miejsca_pobytu"] = mid
			if bohater.get("miejsce") is Dictionary:
				bohater["miejsce"]["id"] = mid
				bohater["miejsce"]["nazwa"] = mnaz
				swiat["bohater"] = bohater
			stan["miasto_gracza_id"] = mid
			out["przeprowadzka"] = true
	else:
		if odbior_wybrany == "wysylka" and kategoria_drobna(str(kopia.get("kategoria", ""))):
			kopia["dostawa_zostalo"] = tygodnie_wysylki(kopia)
			if not (swiat.get("dostawy") is Array):
				swiat["dostawy"] = []
			(swiat["dostawy"] as Array).append(kopia)
			out["dostawa_tygodnie"] = int(kopia["dostawa_zostalo"])
		else:
			if not (maj.get("dobra") is Array):
				maj["dobra"] = []
			maj["dobra"].append(kopia)
	swiat["majatek"] = maj
	stan["oferty"].remove_at(idx)
	swiat["rynek_zakupow"] = stan
	przelicz_zadowolenie_docelowe(swiat)
	out["ok"] = true
	out["oferta"] = kopia
	return out


func auto_na_miejscu(swiat: Dictionary, oferta: Dictionary) -> bool:
	if bool(oferta.get("dojazd_oplacony", false)):
		return true
	if bool(oferta.get("miasto_gracza", false)):
		return true
	var mid := ""
	if swiat.get("rynek_zakupow") is Dictionary:
		mid = str(swiat["rynek_zakupow"].get("miasto_gracza_id", ""))
	if mid == "":
		var boh: Variant = swiat.get("bohater", {})
		if boh is Dictionary and boh.get("miejsce") is Dictionary:
			mid = str(boh["miejsce"].get("id", ""))
	return mid != "" and str(oferta.get("miasto_id", "")) == mid


func kierowca_prosi_o_paliwo(osoba: Dictionary) -> bool:
	## Propozycja: hojni rzadziej, oszczędni częściej, próg zależy od relacji.
	var relacja := _relacja_osoby(osoba)
	var cechy := _ids_cech(osoba.get("charakter"))
	var hojny := cechy.has("hojny") or cechy.has("opiekunczy") or cechy.has("zyczliwy")
	var skapy := cechy.has("oszczedny") or cechy.has("oschly")
	if hojny:
		return relacja < 40
	if skapy:
		return relacja < 80
	return relacja < 60


func koszt_wysylki_zl(oferta: Dictionary) -> int:
	if _liczba(oferta.get("cena_dostawy_zl")):
		return maxi(0, int(oferta["cena_dostawy_zl"]))
	return CENA_WYSYLKI_DROBNEJ_ZL


func tygodnie_wysylki(oferta: Dictionary) -> int:
	var km := 0.0
	if _liczba(oferta.get("odleglosc_km")):
		km = float(oferta["odleglosc_km"])
	return clampi(1 + int(km / 200.0), 1, 4)


func koszt_komunikacji_drobnej(km: float, legitymacja: bool) -> int:
	if km <= 5.0:
		return 0
	var t := clampf((km - 5.0) / 40.0, 0.0, 1.0)
	var cena := int(round(lerpf(2.0, 5.0, t)))
	if legitymacja:
		cena = maxi(1, int(round(float(cena) * 0.5)))
	return cena


func zmeczenie_komunikacji(km: float) -> int:
	return clampi(4 + int(km / 15.0), 4, 18)


func koszt_paliwa_wlasnego_auta(swiat: Dictionary, km: float) -> Dictionary:
	var out := {"ok": false, "tekst": "Nie masz auta.", "koszt_zl": 0}
	var auto := _auto_bohatera(swiat)
	if auto.is_empty():
		return out
	var spalanie: Variant = auto.get("spalanie")
	if not _liczba(spalanie):
		spalanie = 7.0
	var cena: Variant = cena_nosnika_dojazdu(auto)
	if not _liczba(cena):
		out["tekst"] = "Auto jest, ale ten nośnik nie ma ceny."
		out["ok"] = true
		out["koszt_zl"] = 0
		return out
	var litry := snappedf(2.0 * km * float(spalanie) / 100.0, 0.1)
	var koszt := int(round(litry * float(cena)))
	out["ok"] = true
	out["koszt_zl"] = koszt
	out["tekst"] = "Własne auto: %.1f l w obie strony, %d zł." % [litry, koszt]
	return out


func _auto_bohatera(swiat: Dictionary) -> Dictionary:
	if swiat.get("auto") is Dictionary and not (swiat["auto"] as Dictionary).is_empty():
		return swiat["auto"]
	var maj: Dictionary = swiat.get("majatek", {}) if swiat.get("majatek") is Dictionary else {}
	var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	for d in dobra:
		if d is Dictionary and str(d.get("kategoria", "")) == "samochod":
			return d
	return {}


func wykonaj_odbior_drobny(swiat: Dictionary, oferta_id: String, wybor: Dictionary) -> Dictionary:
	var out := {"ok": false, "powod": "", "tekst": ""}
	var oferta := _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Brak oferty."
		return out
	var km := float(oferta.get("odleglosc_km", 0.0)) if _liczba(oferta.get("odleglosc_km")) else 0.0
	var sposob := str(wybor.get("sposob", ""))
	var koszt := 0
	var tekst := ""
	if sposob == "wysylka":
		koszt = koszt_wysylki_zl(oferta)
		tekst = "Wysyłka %d zł, dojazd za %d tyg." % [koszt, tygodnie_wysylki(oferta)]
	elif sposob == "auto":
		var paliwo := koszt_paliwa_wlasnego_auta(swiat, km)
		if not bool(paliwo.get("ok", false)):
			out["powod"] = str(paliwo.get("tekst", "Nie masz auta."))
			out["tekst"] = out["powod"]
			return out
		koszt = int(paliwo.get("koszt_zl", 0))
		tekst = str(paliwo.get("tekst", ""))
	elif sposob == "komunikacja":
		koszt = koszt_komunikacji_drobnej(km, ma_legitymacje(swiat))
		var zm := zmeczenie_komunikacji(km)
		_dodaj_zmeczenie_fizyczne(swiat, zm)
		tekst = "Komunikacja: %d zł, zmęczenie fiz. +%d." % [koszt, zm]
		if ma_legitymacje(swiat) and km > 5.0:
			tekst += " Legitymacja obniża bilet."
	elif sposob == "osoba":
		var ref := str(wybor.get("osoba_ref", ""))
		var kandydat := _kandydat_po_ref(swiat, ref)
		if kandydat.is_empty():
			out["powod"] = "Nie ma takiej osoby."
			return out
		var osoba: Dictionary = kandydat.get("osoba", {}) if kandydat.get("osoba") is Dictionary else {}
		var nazwa := str(kandydat.get("nazwa", "Ktoś"))
		if kierowca_prosi_o_paliwo(osoba):
			var paliwo_o := koszt_paliwa_wlasnego_auta({"auto": {"spalanie": 7.0, "naped": "benzyna"}}, km)
			koszt = int(paliwo_o.get("koszt_zl", 0))
			tekst = "%s (relacja %d) prosi o %d zł na paliwo." % [nazwa, _relacja_osoby(osoba), koszt]
		else:
			tekst = "%s (relacja %d) podwozi cię bez opłaty." % [nazwa, _relacja_osoby(osoba)]
	else:
		out["powod"] = "Wybierz odbiór."
		return out
	if koszt > 0:
		var kasa := _kasa_bohatera(swiat)
		if kasa < koszt:
			out["powod"] = "Za mało na odbiór (%d < %d)." % [kasa, koszt]
			out["tekst"] = out["powod"]
			return out
		_ustaw_kase(swiat, kasa - koszt)
	oferta["odbior_wybrany"] = sposob
	_zapisz_oferte(swiat, oferta)
	out["ok"] = true
	out["tekst"] = tekst
	out["koszt_zl"] = koszt
	return out


func tick_dostawy(swiat: Dictionary) -> void:
	if not (swiat.get("dostawy") is Array):
		return
	var zostaje: Array = []
	var przyszlo: Array = []
	for d in swiat["dostawy"]:
		if not (d is Dictionary):
			continue
		d["dostawa_zostalo"] = int(d.get("dostawa_zostalo", 1)) - 1
		if int(d["dostawa_zostalo"]) > 0:
			zostaje.append(d)
		else:
			przyszlo.append(d)
	swiat["dostawy"] = zostaje
	if przyszlo.is_empty():
		return
	if not (swiat.get("majatek") is Dictionary):
		swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	var maj: Dictionary = swiat["majatek"]
	if not (maj.get("dobra") is Array):
		maj["dobra"] = []
	for d2 in przyszlo:
		maj["dobra"].append(d2)
	swiat["majatek"] = maj


func koszt_dojazdu(swiat: Dictionary, oferta: Dictionary, cena_paliwa_zl_l: Variant = null, bilet_nadpisany: Variant = null) -> Dictionary:
	var km := float(oferta.get("odleglosc_km", 0.0)) if _liczba(oferta.get("odleglosc_km")) else 0.0
	var bilet: Variant = bilet_nadpisany if _liczba(bilet_nadpisany) else _bilet_miasta_bohatera(swiat)
	var lokalnie := auto_na_miejscu(swiat, oferta) or bool(oferta.get("miasto_gracza", false))
	if not lokalnie:
		var mid_g := ""
		if swiat.get("rynek_zakupow") is Dictionary:
			mid_g = str(swiat["rynek_zakupow"].get("miasto_gracza_id", ""))
		lokalnie = mid_g != "" and str(oferta.get("miasto_id", "")) == mid_g
	var komunikacja := {
		"sposob": "komunikacja",
		"koszt_zl": null,
		"szacunek": false,
		"propozycja_do_poprawki": false,
		"tekst": "transport publiczny",
	}
	if lokalnie:
		if _liczba(bilet):
			komunikacja["koszt_zl"] = int(round(float(bilet)))
			komunikacja["tekst"] = "transport publiczny (%d zł)" % int(komunikacja["koszt_zl"])
		else:
			komunikacja["tekst"] = "transport publiczny — brak ceny biletu w danych miasta, nic nie naliczam"
	elif _liczba(bilet):
		var na_bilet := 25.0
		var conf := _auta_conf()
		var dojazd_conf: Dictionary = conf.get("dojazd", {}) if conf.get("dojazd") is Dictionary else {}
		if _liczba(dojazd_conf.get("km_na_bilet_lokalny")):
			na_bilet = maxf(1.0, float(dojazd_conf["km_na_bilet_lokalny"]))
		var ile_biletow := maxi(1, int(round(km / na_bilet)))
		komunikacja["koszt_zl"] = int(round(float(bilet) * float(ile_biletow)))
		komunikacja["szacunek"] = true
		komunikacja["propozycja_do_poprawki"] = true
		komunikacja["tekst"] = "transport publiczny, szacunek: %d × bilet lokalny (%d zł)" % [ile_biletow, int(komunikacja["koszt_zl"])]
	else:
		komunikacja["szacunek"] = true
		komunikacja["tekst"] = "transport międzymiastowy — brak ceny biletu w danych, nic nie naliczam"
	var spalanie: Variant = oferta.get("spalanie")
	var spalanie_szacunek := false
	if not _liczba(spalanie):
		var conf_a := _auta_conf()
		var dojazd_a: Dictionary = conf_a.get("dojazd", {}) if conf_a.get("dojazd") is Dictionary else {}
		if _liczba(dojazd_a.get("spalanie_gdy_brak_l_na_100")):
			spalanie = float(dojazd_a["spalanie_gdy_brak_l_na_100"])
			spalanie_szacunek = true
	var cena_nosnika: Variant = cena_paliwa_zl_l if _liczba(cena_paliwa_zl_l) else cena_nosnika_dojazdu(oferta)
	var litry: Variant = null
	var koszt_paliwa: Variant = null
	if _liczba(spalanie) and _liczba(cena_nosnika):
		litry = snappedf(2.0 * km * float(spalanie) / 100.0, 0.1)
		koszt_paliwa = int(round(float(litry) * float(cena_nosnika)))
	elif _liczba(spalanie):
		litry = snappedf(2.0 * km * float(spalanie) / 100.0, 0.1)
	var paliwo := {
		"litry": litry,
		"koszt_zl": koszt_paliwa,
		"jednostka": "kWh" if _naped_elektryczny(oferta) else "l",
		"cena_zl_jednostka": cena_nosnika,
		"diesel_bez_ceny": _naped_diesel(oferta) and not _liczba(cena_nosnika),
		"szacunek": spalanie_szacunek or not _liczba(cena_nosnika),
		"propozycja_do_poprawki": true,
		"w_te_i_z_powrotem": true,
	}
	return {"komunikacja": komunikacja, "paliwo": paliwo, "km": km}


func cena_nosnika_dojazdu(oferta: Dictionary) -> Variant:
	## Benzyna, LPG albo kWh z kraj.json. Olej napędowy zostaje null, dopóki nie ma liczby.
	var blok := _blok_ceny_paliwa()
	if _naped_diesel(oferta):
		return blok.get("olej_napedowy") if _liczba(blok.get("olej_napedowy")) else null
	if _naped_elektryczny(oferta):
		return blok.get("energia") if _liczba(blok.get("energia")) else null
	if _naped_lpg(oferta):
		if _liczba(blok.get("gaz")):
			return blok.get("gaz")
		return blok.get("lpg") if _liczba(blok.get("lpg")) else null
	if _liczba(blok.get("benzyna")):
		return blok.get("benzyna")
	return blok.get("pb95") if _liczba(blok.get("pb95")) else null


func _blok_ceny_paliwa() -> Dictionary:
	var kraj: Variant = _czytaj_json_plik("res://świat/polska/kraj.json")
	if not (kraj is Dictionary):
		return {}
	var paliwo: Variant = kraj.get("cena_paliwa", {})
	return paliwo if paliwo is Dictionary else {}


func _naped_diesel(oferta: Dictionary) -> bool:
	var naped := str(oferta.get("naped", "")).to_lower()
	var paliwo := str(oferta.get("paliwo", "")).to_lower()
	if naped in ["diesel", "olej_napedowy", "on"] or paliwo in ["diesel", "olej_napedowy", "on"]:
		return true
	var opis := " %s %s %s " % [str(oferta.get("id", "")), str(oferta.get("model", "")), str(oferta.get("nazwa", ""))]
	opis = opis.to_lower()
	for token in ["tdi", "dci", "cdi", "hdi", "crdi", "tdci", "multijet", "bluehdi", "d4d", "diesel"]:
		if opis.find(token) >= 0:
			return true
	return false


func _naped_elektryczny(oferta: Dictionary) -> bool:
	if str(oferta.get("naped", "")).to_lower() == "elektryczny":
		return true
	return str(oferta.get("spalanie_jednostka", "")).to_lower().find("kwh") >= 0


func _naped_lpg(oferta: Dictionary) -> bool:
	var naped := str(oferta.get("naped", "")).to_lower()
	var paliwo := str(oferta.get("paliwo", "")).to_lower()
	return naped == "lpg" or paliwo == "lpg" or paliwo == "gaz"


func wykonaj_dojazd(swiat: Dictionary, oferta_id: String, wybor: Dictionary) -> Dictionary:
	var out := {
		"ok": false,
		"powod": "",
		"tekst": "",
		"koszt_zl": null,
		"drugi_raz": false,
		"propozycja_do_poprawki": true,
		"szacunek": false,
	}
	var oferta := _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Brak oferty."
		return out
	if auto_na_miejscu(swiat, oferta):
		out["ok"] = true
		out["drugi_raz"] = true
		out["koszt_zl"] = 0
		out["tekst"] = "Jesteś już przy aucie. Drugi raz za dojazd nie płacisz."
		return out
	var sposob := str(wybor.get("sposob", ""))
	var wycena := koszt_dojazdu(swiat, oferta, wybor.get("cena_paliwa_zl_l", null), wybor.get("bilet_zl", null))
	var koszt: Variant = null
	var tekst := ""
	if sposob == "komunikacja":
		var kom: Dictionary = wycena.get("komunikacja", {})
		koszt = kom.get("koszt_zl")
		tekst = str(kom.get("tekst", "transport publiczny"))
		out["szacunek"] = bool(kom.get("szacunek", false))
	elif sposob == "podwozka":
		var ref := str(wybor.get("osoba_ref", ""))
		var kandydat := _znajdz_kandydata(swiat, ref)
		if kandydat.is_empty():
			out["powod"] = "Nie ma takiej osoby w zapisie."
			return out
		var osoba: Dictionary = kandydat.get("osoba", {}) if kandydat.get("osoba") is Dictionary else {}
		var prosi := kierowca_prosi_o_paliwo(osoba)
		var paliwo: Dictionary = wycena.get("paliwo", {})
		out["szacunek"] = bool(paliwo.get("szacunek", false))
		var nazwa := str(kandydat.get("nazwa", "Kierowca"))
		if prosi and not bool(wybor.get("dolozyc", false)):
			var delta := _delta_odmowy_paliwa()
			var po := _obniz_relacje(osoba, delta)
			out["relacja"] = po
			out["poprosil_o_paliwo"] = true
			out["odmowa_paliwa"] = true
			tekst = "%s prosi o dołożenie do paliwa. Odmawiasz. Relacja spada do %d." % [nazwa, po]
		elif prosi:
			koszt = paliwo.get("koszt_zl")
			var litry_txt := ""
			if _liczba(paliwo.get("litry")):
				litry_txt = " (%.1f %s)" % [float(paliwo["litry"]), str(paliwo.get("jednostka", "l"))]
			if _liczba(koszt):
				tekst = "%s prosi o paliwo%s. Dokładasz %d zł." % [nazwa, litry_txt, int(koszt)]
			elif bool(paliwo.get("diesel_bez_ceny", false)):
				tekst = "%s prosi o paliwo%s. Olej napędowy nie ma ceny, więc bez złotówek." % [nazwa, litry_txt]
			else:
				tekst = "%s prosi o paliwo%s. Cena tego nośnika w danych kraju jest pusta, więc bez złotówek." % [nazwa, litry_txt]
			out["poprosil_o_paliwo"] = true
		else:
			tekst = "%s wiezie cię i nie prosi o paliwo." % nazwa
			out["poprosil_o_paliwo"] = false
	else:
		out["powod"] = "Wybierz transport publiczny albo podwózkę."
		return out
	if _liczba(koszt) and int(koszt) > 0:
		var bohater: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
		var kasa := int(bohater.get("pieniadze", 0)) if _liczba(bohater.get("pieniadze")) else 0
		if kasa < int(koszt):
			out["powod"] = "Za mało pieniędzy na dojazd (%d < %d)." % [kasa, int(koszt)]
			out["tekst"] = out["powod"]
			return out
		bohater["pieniadze"] = kasa - int(koszt)
		swiat["bohater"] = bohater
		out["koszt_zl"] = int(koszt)
	oferta["dojazd_oplacony"] = true
	oferta["dojazd_sposob"] = sposob
	_zapisz_oferte(swiat, oferta)
	out["ok"] = true
	out["tekst"] = tekst
	return out


func _relacja_osoby(osoba: Dictionary) -> int:
	if _liczba(osoba.get("relacja")):
		return clampi(int(osoba["relacja"]), 0, 100)
	if _liczba(osoba.get("relacja_0_100")):
		return clampi(int(osoba["relacja_0_100"]), 0, 100)
	return 55


func _obniz_relacje(osoba: Dictionary, delta: int) -> int:
	var po := clampi(_relacja_osoby(osoba) - delta, 0, 100)
	osoba["relacja"] = po
	return po


func _delta_odmowy_paliwa() -> int:
	var conf := _auta_conf()
	var dojazd: Dictionary = conf.get("dojazd", {}) if conf.get("dojazd") is Dictionary else {}
	if _liczba(dojazd.get("spadek_relacji_odmowa_paliwa")):
		return maxi(1, int(dojazd["spadek_relacji_odmowa_paliwa"]))
	return 4


func _bilet_miasta_bohatera(swiat: Dictionary) -> Variant:
	var mid := ""
	if swiat.get("rynek_zakupow") is Dictionary:
		mid = str(swiat["rynek_zakupow"].get("miasto_gracza_id", ""))
	if mid == "":
		var boh: Variant = swiat.get("bohater", {})
		if boh is Dictionary and boh.get("miejsce") is Dictionary:
			mid = str(boh["miejsce"].get("id", ""))
	if mid == "":
		return null
	var dane := _czytaj_miasto_z_danych(mid)
	return dane.get("cena_transportu_publicznego", null)


func _znajdz_kandydata(swiat: Dictionary, ref: String) -> Dictionary:
	for k in kandydaci_pomocy_oceny(swiat):
		if k is Dictionary and str(k.get("ref", "")) == ref:
			return k
	return {}


## Wygoda aktualnego lokum: własna nieruchomość (najwyższa wygoda),
## inaczej dom rodziny / lokum startowe; gdy brak → 0.
func wygoda_lokum(swiat: Dictionary) -> Dictionary:
	var out := {
		"wygoda": 0,
		"zrodlo": "brak",
		"propozycja_do_poprawki": true,
	}
	var maj: Variant = swiat.get("majatek", {})
	if maj is Dictionary and maj.get("nieruchomosci") is Array:
		var lista: Array = maj["nieruchomosci"]
		var najlepsza := -1
		for n in lista:
			if not (n is Dictionary):
				continue
			if not _liczba(n.get("wygoda")):
				continue
			var w := int(n["wygoda"])
			if w > najlepsza:
				najlepsza = w
		if najlepsza >= 0:
			out["wygoda"] = clampi(najlepsza, 0, 100)
			out["zrodlo"] = "wlasna"
			return out
	var lokum: Variant = swiat.get("lokum_startowe", {})
	if lokum is Dictionary and _liczba(lokum.get("wygoda")):
		out["wygoda"] = clampi(int(lokum["wygoda"]), 0, 100)
		out["zrodlo"] = "lokum_startowe"
		return out
	var conf := _efekt_wygody_conf()
	var mapa: Dictionary = {}
	if conf.get("lokum_rodziny_wygoda") is Dictionary:
		mapa = conf["lokum_rodziny_wygoda"]
	var rodzina: Variant = swiat.get("rodzina", {})
	var dom_id := ""
	if rodzina is Dictionary and rodzina.get("dom") is Dictionary:
		dom_id = str(rodzina["dom"].get("id", ""))
	if dom_id != "" and mapa.has(dom_id) and _liczba(mapa.get(dom_id)):
		out["wygoda"] = clampi(int(mapa[dom_id]), 0, 100)
		out["zrodlo"] = "dom_rodziny"
		return out
	# Rodzina zawsze ma jakieś lokum startowe — gdy typ domu nie wylosowany, domyślna wygoda.
	if rodzina is Dictionary and not rodzina.is_empty():
		var domyslnie := 50
		if _liczba(mapa.get("domyslnie")):
			domyslnie = int(mapa["domyslnie"])
		out["wygoda"] = clampi(domyslnie, 0, 100)
		out["zrodlo"] = "dom_rodziny_domyslnie"
		return out
	out["wygoda"] = 0
	out["zrodlo"] = "brak"
	return out


## Offset wygody 0–100 → −20…+30 (liniowo). Wzór w postacie/zadowolenie_dryf.json.
func offset_wygody(wygoda: int) -> float:
	var conf := _dryf_conf()
	var wo: Dictionary = conf.get("wygoda_offset", {}) if conf.get("wygoda_offset") is Dictionary else {}
	var w_min := int(wo.get("wygoda_min", 0))
	var w_max := int(wo.get("wygoda_max", 100))
	var o_min := float(wo.get("offset_przy_zerze", wo.get("offset_min", -20)))
	var wsp := float(wo.get("wspolczynnik", 0.5))
	var v := clampi(wygoda, w_min, w_max)
	return o_min + float(v) * wsp


## Pola z ukryte_w_ui (np. zadowolenie_docelowe) — nie wolno pokazywać w normalnej grze.
func pole_ukryte_w_ui(klucz: String) -> bool:
	var conf := _dryf_conf()
	var lista: Variant = conf.get("ukryte_w_ui", ["zadowolenie_docelowe"])
	if lista is Array:
		return lista.has(klucz)
	return klucz == "zadowolenie_docelowe"


## Widoczna metryka nastroju (pasek / napisy gracza).
func metryka_widoczna_zadowolenia() -> String:
	var conf := _dryf_conf()
	return str(conf.get("metryka_widoczna", "psychika"))


## Przelicza ukryte zadowolenie_docelowe z bazy + offsetu wygody. Nie rusza widocznej psychiki.
func przelicz_zadowolenie_docelowe(swiat: Dictionary) -> int:
	var conf := _dryf_conf()
	var lokum: Dictionary = wygoda_lokum(swiat)
	var wygoda := int(lokum.get("wygoda", 0))
	var baza := int(conf.get("baza_docelowego", 50))
	var offset := offset_wygody(wygoda)
	var clamp_zakres: Array = [0, 100]
	var wo: Dictionary = conf.get("wygoda_offset", {}) if conf.get("wygoda_offset") is Dictionary else {}
	if wo.get("clamp_docelowego") is Array and (wo["clamp_docelowego"] as Array).size() >= 2:
		clamp_zakres = wo["clamp_docelowego"]
	var plusy := offset_plusow_majatku(swiat)
	var docelowe := clampi(roundi(float(baza) + offset + float(plusy)), int(clamp_zakres[0]), int(clamp_zakres[1]))
	var bohater: Dictionary = {}
	if swiat.get("bohater") is Dictionary:
		bohater = swiat["bohater"]
	var pole := str(conf.get("metryka_docelowa", "zadowolenie_docelowe"))
	bohater[pole] = docelowe
	swiat["bohater"] = bohater
	return docelowe


## propozycja_do_poprawki. Plusa nie sumują się w typie: liczy się najlepszy posiadany.
## nowy bez usterek ++++ (4). Używany bez usterek i stan ≥ 80: +++ (3).
## Używany, powaga deklarowanych/rzeczywistych ≤ 3 i stan ≥ 50: ++ (2). Reszta: + (1).
## Drugi taki sam telefon nie dodaje. Lepszy dodaje tylko różnicę. Oddanie lepszego wraca do następnego.
func plusy_oferty(oferta: Dictionary) -> int:
	if not kategoria_daje_plusy(str(oferta.get("kategoria", ""))):
		return 0
	var usterki := _usterki_do_plusow(oferta)
	var powaga := _powaga_usterek(usterki, str(oferta.get("kategoria", "")), str(oferta.get("segment", "")))
	if str(oferta.get("stan", "")) == "nowy":
		return 4 if powaga <= 0 else 3
	var stan_d := 70
	if _liczba(oferta.get("stan_deklarowany")):
		stan_d = int(oferta["stan_deklarowany"])
	if powaga <= 0 and stan_d >= 80:
		return 3
	if powaga <= 3 and stan_d >= 50:
		return 2
	return 1


func nazwa_rodzaju_oferty(oferta: Dictionary) -> String:
	var rodzaj_nazwa := str(oferta.get("rodzaj_nazwa", "")).strip_edges()
	if rodzaj_nazwa != "":
		var pod_nazwa := str(oferta.get("podrodzaj_nazwa", "")).strip_edges()
		if pod_nazwa != "":
			return "%s · %s" % [rodzaj_nazwa, pod_nazwa]
		return rodzaj_nazwa
	var pod := str(oferta.get("podkategoria", "")).strip_edges()
	if pod == "" and str(oferta.get("kategoria", "")) == "sprzet":
		pod = str(oferta.get("segment", ""))
	match pod:
		"sluchawki":
			return "Słuchawki"
		"klawiatura":
			return "Klawiatura"
		"mysz":
			return "Mysz"
		"mikrofon":
			return "Mikrofon"
	match str(oferta.get("kategoria", "")):
		"telefon":
			return "Telefon"
		"laptop":
			return "Laptop"
		"komputer":
			return "Komputer"
		"rower":
			return "Rower"
		_:
			return ""


func tekst_plusow(ile: int) -> String:
	var n := clampi(ile, 0, 4)
	if n <= 0:
		return ""
	return "+".repeat(n)


func offset_plusow_majatku(swiat: Dictionary) -> int:
	var maj: Variant = swiat.get("majatek", {})
	if not (maj is Dictionary) or not (maj.get("dobra") is Array):
		return 0
	var najlepsze := {}
	for d in maj["dobra"]:
		if not (d is Dictionary):
			continue
		var kat := str(d.get("kategoria", ""))
		if not kategoria_daje_plusy(kat):
			continue
		var p := plusy_oferty(d)
		if p > int(najlepsze.get(kat, 0)):
			najlepsze[kat] = p
	var suma := 0
	for k in najlepsze.keys():
		suma += int(najlepsze[k])
	return suma


func oddaj_dobro(swiat: Dictionary, indeks: int) -> Dictionary:
	var out := {"ok": false, "powod": ""}
	if not (swiat.get("majatek") is Dictionary):
		out["powod"] = "Brak majątku."
		return out
	var maj: Dictionary = swiat["majatek"]
	if not (maj.get("dobra") is Array):
		out["powod"] = "Brak dóbr."
		return out
	var lista: Array = maj["dobra"]
	if indeks < 0 or indeks >= lista.size():
		out["powod"] = "Zły indeks."
		return out
	lista.remove_at(indeks)
	maj["dobra"] = lista
	swiat["majatek"] = maj
	out["docelowe"] = przelicz_zadowolenie_docelowe(swiat)
	out["ok"] = true
	return out


func _usterki_do_plusow(oferta: Dictionary) -> Array:
	if _liczba(oferta.get("kupiono_tydzien")) and oferta.get("usterki_rzeczywiste") is Array:
		return oferta["usterki_rzeczywiste"]
	if oferta.get("usterki_deklarowane") is Array:
		return oferta["usterki_deklarowane"]
	return []


func _powaga_usterek(ids: Array, kategoria: String, segment: String) -> int:
	var suma := 0
	for uid_v in ids:
		var meta := _meta_usterki(str(uid_v), kategoria, segment)
		suma += int(meta.get("powaga", 1))
	return suma


func linie_karty_drobiazgu(oferta: Dictionary) -> Array:
	var kat := str(oferta.get("kategoria", ""))
	var nazwa := str(oferta.get("nazwa", "")).strip_edges()
	if nazwa == "":
		nazwa = ("%s %s" % [str(oferta.get("marka", "")), str(oferta.get("model", ""))]).strip_edges()
	if nazwa == "":
		nazwa = kat
	var stan_txt := "nowy" if str(oferta.get("stan", "")) == "nowy" else "używany"
	var cena := formatuj_cene_auta(oferta.get("cena_zl")) if _liczba(oferta.get("cena_zl")) else "—"
	var glowna := "%s · %s · %s" % [nazwa, stan_txt, cena]
	var linie: Array = [glowna]
	var rodzaj := nazwa_rodzaju_oferty(oferta)
	if rodzaj != "":
		linie.append("Rodzaj: %s" % rodzaj)
	if str(oferta.get("stan_ksiazki_nazwa", "")) != "":
		linie.append("Stan egzemplarza: %s" % str(oferta.get("stan_ksiazki_nazwa")))
	if _liczba(oferta.get("ilosc")):
		linie.append("Ilość: %d" % int(oferta["ilosc"]))
	var plus := tekst_plusow(plusy_oferty(oferta))
	if plus != "":
		linie.append("Zadowolenie: %s" % plus)
	var dek: Array = oferta.get("usterki_deklarowane", []) if oferta.get("usterki_deklarowane") is Array else []
	if str(oferta.get("stan", "")) == "uzywany" and not dek.is_empty():
		var nazwy: Array = nazwy_usterek(dek, kat, str(oferta.get("segment", "")))
		var czesci := PackedStringArray()
		for n in nazwy:
			czesci.append(str(n))
		if czesci.size() > 0:
			linie.append(", ".join(czesci))
	var sposob := str(oferta.get("sposob_odbioru", "osobisty"))
	var osobisty := sposob == "osobisty" or sposob == "oba" or sposob == ""
	var wysyla := sposob == "wysylka" or sposob == "oba" or sposob == "dostawa"
	if osobisty:
		var gdzie := tekst_linii_miejsca(oferta)
		if gdzie != "":
			linie.append(gdzie)
	if wysyla:
		var kwota := CENA_WYSYLKI_DROBNEJ_ZL
		if _liczba(oferta.get("cena_dostawy_zl")):
			kwota = int(oferta["cena_dostawy_zl"])
		if kwota == CENA_WYSYLKI_DROBNEJ_ZL:
			linie.append("wysyłka 15 zł")
		else:
			linie.append("wysyłka %d zł" % kwota)
	return linie


## Co turę: wygoda → docelowe, potem dryf 50% dystansu widocznej psychiki w stronę docelowego.
## Docelowego nie ma w napisie/UI — tylko skutek („Samopoczucie: ±N”).
func efekt_wygody_tydzien(swiat: Dictionary) -> Dictionary:
	var out := {
		"delta": 0,
		"tekst": "",
		"wygoda": 0,
		"zrodlo": "brak",
		"docelowe": 0,
		"zastosowano": false,
		"propozycja_do_poprawki": true,
	}
	var conf := _dryf_conf()
	var lokum: Dictionary = wygoda_lokum(swiat)
	var wygoda := int(lokum.get("wygoda", 0))
	out["wygoda"] = wygoda
	out["zrodlo"] = str(lokum.get("zrodlo", "brak"))
	var docelowe := przelicz_zadowolenie_docelowe(swiat)
	out["docelowe"] = docelowe
	var metryka := str(conf.get("metryka_widoczna", "psychika"))
	var bohater: Dictionary = {}
	if swiat.get("bohater") is Dictionary:
		bohater = swiat["bohater"]
	var obecne := 50
	if _liczba(bohater.get(metryka)):
		obecne = int(bohater[metryka])
	var dryf: Dictionary = conf.get("dryf_tury", {}) if conf.get("dryf_tury") is Dictionary else {}
	var udzial := float(dryf.get("udzial_odleglosci", 0.5))
	var delta := roundi(udzial * float(docelowe - obecne))
	# Góra 100; dół może < 0 (depresja / hejt). Clamp dolny z dryf JSON lub −100.
	var clamp_widoczny: Array = conf.get("clamp_widocznej", [-100, 100]) if conf.get("clamp_widocznej") is Array else [-100, 100]
	var lo := int(clamp_widoczny[0]) if clamp_widoczny.size() >= 1 else -100
	var hi := int(clamp_widoczny[1]) if clamp_widoczny.size() >= 2 else 100
	var nowe := clampi(obecne + delta, lo, hi)
	delta = nowe - obecne
	out["delta"] = delta
	if delta == 0:
		_aktualizuj_flage_depresji_dryf(bohater)
		swiat["bohater"] = bohater
		return out
	bohater[metryka] = nowe
	_aktualizuj_flage_depresji_dryf(bohater)
	swiat["bohater"] = bohater
	var napis: Dictionary = conf.get("napis_tygodnia", {}) if conf.get("napis_tygodnia") is Dictionary else {}
	var prefiks := str(napis.get("prefiks", "Samopoczucie"))
	var znak_delta := ("+%d" % delta) if delta > 0 else ("−%d" % absi(delta))
	out["tekst"] = "%s: %s" % [prefiks, znak_delta]
	out["zastosowano"] = true
	return out


## Po dłuższym czasie psychika < 0 → flaga depresji (pogłębianie stub).
func _aktualizuj_flage_depresji_dryf(bohater: Dictionary) -> void:
	var psych := int(bohater.get("psychika", 50))
	var t := int(bohater.get("tygodnie_psychika_ponizej_0", 0))
	if psych < 0:
		t += 1
	else:
		t = 0
	bohater["tygodnie_psychika_ponizej_0"] = t
	if t >= 4:
		bohater["depresja"] = true
		bohater["depresja_stub"] = true


## Pełne lokum startowe rodziny: lokalizacja, typ, metraż, stan, wygoda od zarobków.
## `miejsce` = miejsce urodzenia bohatera (typ miasto / wies). Aktualizuje rodzina.dom.
func zbuduj_lokum_startowe(rodzina: Dictionary, miejsce: Variant = null, ziarno: int = 0) -> Dictionary:
	var conf := _lokum_startowe_conf()
	var rng := RandomNumberGenerator.new()
	if ziarno != 0:
		rng.seed = ziarno
	else:
		rng.randomize()
	var miejsce_dict: Dictionary = miejsce if miejsce is Dictionary else {}
	if miejsce_dict.is_empty() and rodzina.get("miejsce") is Dictionary:
		miejsce_dict = rodzina["miejsce"]
	var typ_urodzenia := str(miejsce_dict.get("typ", ""))
	var lokalizacja := _losuj_lokalizacje_lokum(typ_urodzenia, conf, rng)
	var poziom := _poziom_zarobkow_gospodarstwa(rodzina.get("zarobki"), conf)
	var typ_kat := _losuj_typ_lokum(lokalizacja, poziom, conf, rng)
	var typ_dom_id := _typ_dom_id(typ_kat)
	var typ_nazwa := _typ_lokum_nazwa(typ_kat)
	var metraz := _losuj_metraz_od_zarobkow(typ_kat, poziom, conf, rng)
	var pokoje := _pokoje_od_metrazu(typ_kat, metraz, rng)
	var stan := _losuj_stan_od_zarobkow(typ_kat, poziom, conf, rng)
	var wygoda := _licz_wygode_lokum_start(typ_kat, metraz, stan, poziom, conf)
	var mid := ""
	var mnaz := ""
	var lokalizacja_opis := ""
	if lokalizacja == "miasto":
		if typ_urodzenia == "miasto":
			mid = str(miejsce_dict.get("id", ""))
			mnaz = str(miejsce_dict.get("nazwa", ""))
			lokalizacja_opis = mnaz if mnaz != "" else "miasto"
		else:
			# Urodzony poza miastem, ale lokum w mieście powiatowym (siedziba).
			mid = str(miejsce_dict.get("siedziba_id", miejsce_dict.get("id", "")))
			mnaz = str(miejsce_dict.get("siedziba_nazwa", miejsce_dict.get("nazwa", "")))
			lokalizacja_opis = mnaz if mnaz != "" else "miasto"
	else:
		mid = str(miejsce_dict.get("id", ""))
		mnaz = str(miejsce_dict.get("nazwa", ""))
		if typ_urodzenia == "miasto":
			lokalizacja_opis = "poza miastem (%s)" % (mnaz if mnaz != "" else "powiat")
		else:
			lokalizacja_opis = "poza miastem" + ((" (%s)" % mnaz) if mnaz != "" else "")
	var cena: Variant = null
	var cena_conf: Dictionary = conf.get("cena_szacunkowa", {}) if conf.get("cena_szacunkowa") is Dictionary else {}
	if bool(cena_conf.get("licz_ze_wzoru_rynku", true)):
		var n_conf := _nieruchomosci_conf()
		var kat_ceny := _kat_ceny_rynku(typ_kat)
		cena = _licz_cene(kat_ceny, metraz, stan, lokalizacja == "miasto", 3.0 if lokalizacja == "miasto" else 18.0, rng, n_conf)
	var lokum := {
		"id": "lokum_start_%s_%d" % [typ_kat, rng.randi()],
		"kategoria": typ_kat if typ_kat != "dom_jednorodzinny" else "dom",
		"typ": typ_dom_id,
		"typ_nazwa": typ_nazwa,
		"nieruchomosc": true,
		"lokum_rodziny": true,
		"nazwa": "%s, %d m²" % [typ_nazwa, metraz],
		"metraz_m2": metraz,
		"pokoje": pokoje,
		"stan": stan,
		"wygoda": wygoda,
		"lokalizacja": lokalizacja,
		"lokalizacja_opis": lokalizacja_opis,
		"miasto_id": mid,
		"miasto_nazwa": mnaz,
		"cena_zl": cena,
		"poziom_zarobkow": snappedf(poziom, 0.01),
		"typ_urodzenia": typ_urodzenia,
		"zrodlo": "lokum_startowe",
		"propozycja_do_poprawki": true,
		"obrazek": placeholder_sciezka(typ_kat if typ_kat != "dom_jednorodzinny" else "dom"),
	}
	# Spójność z rodzina.dom (UI / awaryjna mapa wygody).
	rodzina["dom"] = {
		"id": typ_dom_id,
		"nazwa": typ_nazwa,
		"kolo": true,
		"powod": "",
		"propozycja_do_poprawki": true,
	}
	rodzina["lokum"] = lokum.duplicate(true)
	return lokum


## Krótki opis do UI: „Mieszkacie w: …”.
func opis_lokum_ui(lokum: Variant) -> String:
	if not (lokum is Dictionary) or lokum.is_empty():
		return ""
	var typ_n := str(lokum.get("typ_nazwa", ""))
	if typ_n == "":
		typ_n = str(lokum.get("nazwa", "lokum"))
	var metraz := ""
	if _liczba(lokum.get("metraz_m2")):
		metraz = "%d m²" % int(lokum["metraz_m2"])
	var pokoje := ""
	if _liczba(lokum.get("pokoje")):
		var p := int(lokum["pokoje"])
		pokoje = "%d pok." % p
	var stan_id := str(lokum.get("stan", ""))
	var stan_etykieta := stan_id
	var dane := wczytaj()
	if dane.get("etykiety_stanu") is Dictionary and dane["etykiety_stanu"].has(stan_id):
		stan_etykieta = str(dane["etykiety_stanu"][stan_id])
	var gdzie := str(lokum.get("lokalizacja_opis", ""))
	if gdzie == "":
		gdzie = "miasto" if str(lokum.get("lokalizacja", "")) == "miasto" else "poza miastem"
	var czesci: PackedStringArray = []
	czesci.append(typ_n)
	if metraz != "":
		czesci.append(metraz)
	if pokoje != "":
		czesci.append(pokoje)
	if stan_etykieta != "":
		czesci.append(stan_etykieta)
	czesci.append(gdzie)
	return "Mieszkacie w: %s." % ", ".join(czesci)


func _lokum_startowe_conf() -> Dictionary:
	var conf := _nieruchomosci_conf()
	if conf.get("lokum_startowe") is Dictionary:
		return conf["lokum_startowe"]
	return {}


func _losuj_lokalizacje_lokum(typ_urodzenia: String, conf: Dictionary, rng: RandomNumberGenerator) -> String:
	var lok: Dictionary = conf.get("lokalizacja", {}) if conf.get("lokalizacja") is Dictionary else {}
	var p_miasto := 0.5
	if typ_urodzenia == "miasto":
		p_miasto = float(lok.get("urodzony_miasto_szansa_mieszkac_w_miescie", 0.78))
	else:
		p_miasto = float(lok.get("urodzony_reszta_szansa_mieszkac_w_miescie", 0.32))
	return "miasto" if rng.randf() < p_miasto else "poza"


func _poziom_zarobkow_gospodarstwa(zarobki: Variant, conf: Dictionary) -> float:
	var zc: Dictionary = conf.get("zarobki_poziom", {}) if conf.get("zarobki_poziom") is Dictionary else {}
	var z_min := float(zc.get("min_zl_gospodarstwa", 9000))
	var z_max := float(zc.get("max_zl_gospodarstwa", 30000))
	if z_max <= z_min:
		z_max = z_min + 1.0
	var srodek := _srodek_zarobkow(zarobki)
	if srodek < 0.0:
		return 0.45
	return clampf((srodek - z_min) / (z_max - z_min), 0.0, 1.0)


func _srodek_zarobkow(zarobki: Variant) -> float:
	if not (zarobki is Dictionary):
		return -1.0
	var od_v: Variant = zarobki.get("od_zl")
	var do_v: Variant = zarobki.get("do_zl")
	if not _liczba(od_v) and _liczba(zarobki.get("mediana_zl")):
		od_v = zarobki.get("mediana_zl")
	if not _liczba(do_v) and _liczba(zarobki.get("przecietne_zl")):
		do_v = zarobki.get("przecietne_zl")
	if _liczba(od_v) and _liczba(do_v):
		return (float(od_v) + float(do_v)) * 0.5
	if _liczba(od_v):
		return float(od_v)
	if _liczba(do_v):
		return float(do_v)
	if _liczba(zarobki.get("kwota")):
		return float(zarobki["kwota"])
	return -1.0


func _losuj_typ_lokum(lokalizacja: String, poziom: float, conf: Dictionary, rng: RandomNumberGenerator) -> String:
	var tw: Dictionary = conf.get("typ_wagi", {}) if conf.get("typ_wagi") is Dictionary else {}
	var klucz := "miasto" if lokalizacja == "miasto" else "poza"
	var wagi_map: Dictionary = tw.get(klucz, {}) if tw.get(klucz) is Dictionary else {}
	if wagi_map.is_empty():
		wagi_map = {"mieszkanie": 0.5, "dom": 0.5, "apartament": 0.0, "willa": 0.0}
	var min_apt := float(tw.get("apartament_min_poziom_zarobkow", 0.72))
	var min_willa := float(tw.get("willa_min_poziom_zarobkow", 0.88))
	var ids: Array = []
	var wagi: Array = []
	for id in ["mieszkanie", "dom", "apartament", "willa"]:
		var w := float(wagi_map.get(id, 0))
		if id == "apartament" and poziom < min_apt:
			w = 0.0
		if id == "willa" and poziom < min_willa:
			w = 0.0
		if w <= 0.0:
			continue
		ids.append(id)
		wagi.append(w)
	if ids.is_empty():
		return "mieszkanie" if lokalizacja == "miasto" else "dom"
	return str(ids[_wazony_indeks(wagi, ids.size(), rng)])


func _typ_dom_id(typ_kat: String) -> String:
	if typ_kat == "dom":
		return "dom_jednorodzinny"
	return typ_kat


func _typ_lokum_nazwa(typ_kat: String) -> String:
	match typ_kat:
		"willa":
			return "Willa"
		"apartament":
			return "Apartament"
		"dom", "dom_jednorodzinny":
			return "Dom jednorodzinny"
		_:
			return "Mieszkanie"


func _kat_ceny_rynku(typ_kat: String) -> String:
	if typ_kat == "dom" or typ_kat == "dom_jednorodzinny" or typ_kat == "willa":
		return "dom"
	return "mieszkanie"


func _sufit_wygody_typu(typ_kat: String, conf: Dictionary = {}) -> int:
	var n_conf := conf if not conf.is_empty() else _nieruchomosci_conf()
	var mapa: Dictionary = {}
	if n_conf.get("wygoda_clamp_typu") is Dictionary:
		mapa = n_conf["wygoda_clamp_typu"]
	var klucz := typ_kat
	if klucz == "dom_jednorodzinny":
		klucz = "dom"
	if mapa.has(klucz) and _liczba(mapa.get(klucz)):
		return clampi(int(mapa[klucz]), 0, 100)
	# Awaryjne sufity (propozycja): mieszkanie/dom poniżej 100; apartament/willa do 100.
	match klucz:
		"mieszkanie":
			return 82
		"dom":
			return 86
		"apartament", "willa":
			return 100
		_:
			return 100


func _losuj_metraz_od_zarobkow(typ_kat: String, poziom: float, conf: Dictionary, rng: RandomNumberGenerator) -> int:
	var blok: Dictionary = conf.get("metraz_od_zarobkow", {}) if conf.get("metraz_od_zarobkow") is Dictionary else {}
	var klucz := typ_kat
	if klucz == "dom_jednorodzinny":
		klucz = "dom"
	var zakres: Dictionary = blok.get(klucz, {}) if blok.get(klucz) is Dictionary else {}
	var od_arr: Array = zakres.get("od", [40, 55]) if zakres.get("od") is Array else [40, 55]
	var do_arr: Array = zakres.get("do", [70, 90]) if zakres.get("do") is Array else [70, 90]
	var od_lo := int(od_arr[0]) if od_arr.size() >= 1 else 40
	var od_hi := int(od_arr[1]) if od_arr.size() >= 2 else od_lo + 10
	var do_lo := int(do_arr[0]) if do_arr.size() >= 1 else 70
	var do_hi := int(do_arr[1]) if do_arr.size() >= 2 else do_lo + 20
	var lo := int(round(lerpf(float(od_lo), float(do_lo), poziom)))
	var hi := int(round(lerpf(float(od_hi), float(do_hi), poziom)))
	if hi < lo:
		var t := lo
		lo = hi
		hi = t
	return rng.randi_range(lo, hi)


func _pokoje_od_metrazu(typ_kat: String, metraz: int, rng: RandomNumberGenerator) -> int:
	var od := 1
	var dokad := 4
	if typ_kat == "willa":
		od = 5
		dokad = 10
	elif typ_kat == "dom" or typ_kat == "dom_jednorodzinny":
		od = 3
		dokad = 6
	elif typ_kat == "apartament":
		od = 2
		dokad = 5
	var dzielnik := 28.0 if typ_kat == "willa" else 22.0
	var sugerowane := clampi(int(round(float(metraz) / dzielnik)), od, dokad)
	return clampi(sugerowane + rng.randi_range(-1, 1), od, dokad)


func _losuj_stan_od_zarobkow(typ_kat: String, poziom: float, conf: Dictionary, rng: RandomNumberGenerator) -> String:
	var blok: Dictionary = conf.get("stan_od_zarobkow", {}) if conf.get("stan_od_zarobkow") is Dictionary else {}
	var poziomy: Array = blok.get("poziomy", []) if blok.get("poziomy") is Array else []
	var wagi_map: Dictionary = {"do_odswiezenia": 1}
	for p in poziomy:
		if not (p is Dictionary):
			continue
		if poziom <= float(p.get("do", 1.0)):
			if p.get("wagi") is Dictionary:
				wagi_map = p["wagi"]
			break
	var dozwolone := ["do_remontu", "do_odswiezenia", "po_remoncie"]
	if typ_kat == "dom" or typ_kat == "dom_jednorodzinny" or typ_kat == "willa":
		dozwolone.append("surowy")
	var ids: Array = []
	var wagi: Array = []
	for id in dozwolone:
		var w := float(wagi_map.get(id, 0))
		if w <= 0.0:
			continue
		ids.append(id)
		wagi.append(w)
	if ids.is_empty():
		return "do_odswiezenia"
	return str(ids[_wazony_indeks(wagi, ids.size(), rng)])


func _licz_wygode_lokum_start(typ_kat: String, metraz: int, stan: String, poziom: float, conf: Dictionary) -> int:
	var w: Dictionary = conf.get("wygoda_od_zarobkow", {}) if conf.get("wygoda_od_zarobkow") is Dictionary else {}
	var klucz := typ_kat
	if klucz == "dom_jednorodzinny":
		klucz = "dom"
	var baza_map: Dictionary = w.get("baza_typu", {}) if w.get("baza_typu") is Dictionary else {}
	var m2_map: Dictionary = w.get("baza_m2", {}) if w.get("baza_m2") is Dictionary else {}
	var v := float(baza_map.get(klucz, 45))
	v += poziom * float(w.get("za_poziom_zarobkow", 30))
	var baza_m2 := float(m2_map.get(klucz, 40))
	v += maxf(0.0, float(metraz) - baza_m2) * float(w.get("za_m2_powyzej_bazy", 0.22))
	if w.get("mnozniki_stanu") is Dictionary:
		v += float(w["mnozniki_stanu"].get(stan, 0))
	var lo := int(w.get("clamp_min", 18))
	if w.get("clamp") is Array and (w["clamp"] as Array).size() >= 1:
		lo = int(w["clamp"][0])
	var hi := _sufit_wygody_typu(klucz)
	return clampi(int(round(v)), lo, hi)


func remont(swiat: Dictionary, indeks_nieruchomosci: int, tryb: String = "sam", kumpel: Dictionary = {}) -> Dictionary:
	var out := {"ok": false, "powod": "", "tekst": ""}
	if tryb != "sam" and tryb != "kumpel" and tryb != "firma":
		tryb = "sam"
	if not (swiat.get("majatek") is Dictionary):
		out["powod"] = "Brak majątku."
		return out
	var maj: Dictionary = swiat["majatek"]
	if not (maj.get("nieruchomosci") is Array):
		out["powod"] = "Brak nieruchomości."
		return out
	var lista: Array = maj["nieruchomosci"]
	if indeks_nieruchomosci < 0 or indeks_nieruchomosci >= lista.size():
		out["powod"] = "Zły indeks."
		return out
	var n: Dictionary = lista[indeks_nieruchomosci]
	if n.get("remont_trwa") is Dictionary:
		var trwa0: Dictionary = n["remont_trwa"]
		out["powod"] = "Remont już trwa: tydzień %d z %d." % [int(trwa0.get("minelo", 0)), int(trwa0.get("tygodni", 0))]
		return out
	var materialy := koszt_remontu_prawdziwy(n)
	if materialy <= 0:
		out["powod"] = "Ten stan nie wymaga remontu."
		return out
	var do_zaplaty := koszt_startu_remontu(n, tryb)
	var stawka_tygodniowa := 0
	if tryb == "kumpel":
		if bool(kumpel.get("laczna", false)):
			do_zaplaty += int(kumpel.get("kwota_laczna", 0))
		else:
			stawka_tygodniowa = int(kumpel.get("stawka_tygodniowa", 0))
	var kasa := _kasa_bohatera(swiat)
	if kasa < do_zaplaty:
		out["powod"] = "Remont: za mało (%d < %d)." % [kasa, do_zaplaty]
		return out
	_ustaw_kase(swiat, kasa - do_zaplaty)
	var tygodni := tygodnie_remontu_trybu(n, tryb)
	var zmecz := zmeczenie_remontu_tydzien(tryb)
	n["remont_trwa"] = {
		"tygodni": tygodni,
		"minelo": 0,
		"koszt": do_zaplaty,
		"stan_przed": str(n.get("stan", "")),
		"tryb": tryb,
		"zmeczenie_tydzien": zmecz,
		"stawka_tygodniowa": stawka_tygodniowa,
		"kumpel_ref": str(kumpel.get("ref", "")),
		"kumpel_nazwa": str(kumpel.get("nazwa", "")),
	}
	lista[indeks_nieruchomosci] = n
	maj["nieruchomosci"] = lista
	swiat["majatek"] = maj
	out["ok"] = true
	out["koszt"] = do_zaplaty
	out["tygodni"] = tygodni
	out["tryb"] = tryb
	out["tekst"] = "Remont (%s) ruszył. Zapłacone %d zł, koniec za %d tyg." % [nazwa_trybu_remontu(tryb), do_zaplaty, tygodni]
	if zmecz > 0:
		out["tekst"] = str(out["tekst"]) + " Zmęczenie fizyczne +%d na tydzień." % zmecz
	return out


func tick_remonty(swiat: Dictionary) -> void:
	if not (swiat.get("majatek") is Dictionary):
		return
	var maj: Dictionary = swiat["majatek"]
	if not (maj.get("nieruchomosci") is Array):
		return
	var lista: Array = maj["nieruchomosci"]
	var zmieniono := false
	for i in lista.size():
		if not (lista[i] is Dictionary):
			continue
		var n: Dictionary = lista[i]
		if not (n.get("remont_trwa") is Dictionary):
			continue
		var trwa: Dictionary = n["remont_trwa"]
		var stawka := int(trwa.get("stawka_tygodniowa", 0))
		if stawka > 0:
			var kasa := _kasa_bohatera(swiat)
			if kasa < stawka:
				trwa["blokada"] = "Brak %d zł na stawkę kumpla. Ten tydzień się nie liczy." % stawka
				n["remont_trwa"] = trwa
				lista[i] = n
				zmieniono = true
				continue
			_ustaw_kase(swiat, kasa - stawka)
			trwa["koszt"] = int(trwa.get("koszt", 0)) + stawka
			trwa.erase("blokada")
		var zmecz := int(trwa.get("zmeczenie_tydzien", 0))
		if not _liczba(trwa.get("zmeczenie_tydzien")):
			zmecz = zmeczenie_remontu_tydzien(str(trwa.get("tryb", "sam")))
			trwa["zmeczenie_tydzien"] = zmecz
		_dodaj_zmeczenie_fizyczne(swiat, zmecz)
		trwa["minelo"] = int(trwa.get("minelo", 0)) + 1
		if int(trwa["minelo"]) < int(trwa.get("tygodni", 1)):
			n["remont_trwa"] = trwa
			lista[i] = n
			zmieniono = true
			continue
		var conf := _nieruchomosci_conf()
		var rem: Dictionary = conf.get("remont", {}) if conf.get("remont") is Dictionary else {}
		var delty: Dictionary = rem.get("delta_wygody", {}) if rem.get("delta_wygody") is Dictionary else {}
		var stan_przed := str(trwa.get("stan_przed", n.get("stan", "")))
		n["stan"] = "po_remoncie"
		var wyg := int(n.get("wygoda", 50)) + int(delty.get(stan_przed, 10))
		var typ_rem := str(n.get("kategoria", n.get("typ", "mieszkanie")))
		n["wygoda"] = clampi(wyg, 0, _sufit_wygody_typu(typ_rem, conf))
		if _liczba(n.get("cena_zl")):
			n["cena_zl"] = int(n["cena_zl"]) + int(round(float(trwa.get("koszt", 0)) * 0.3))
		n["ostatni_remont_koszt"] = int(trwa.get("koszt", 0))
		n.erase("remont_trwa")
		n["koszt_remontu_zl"] = 0
		n["szacunek_remontu_zl"] = 0
		lista[i] = n
		zmieniono = true
	if zmieniono:
		maj["nieruchomosci"] = lista
		swiat["majatek"] = maj
		przelicz_zadowolenie_docelowe(swiat)


func koszt_remontu_prawdziwy(n: Dictionary) -> int:
	var conf := _nieruchomosci_conf()
	var rem: Dictionary = conf.get("remont", {}) if conf.get("remont") is Dictionary else {}
	var stawki: Dictionary = rem.get("stawka_zl_za_m2", {}) if rem.get("stawka_zl_za_m2") is Dictionary else {}
	var mnozniki: Dictionary = rem.get("mnoznik_typu", {}) if rem.get("mnoznik_typu") is Dictionary else {}
	var stan_id := str(n.get("stan", ""))
	var stawka := float(stawki.get(stan_id, 0))
	if stawka <= 0.0:
		return 0
	var metraz := float(n.get("metraz_m2", 40))
	var typ := str(n.get("kategoria", n.get("typ", "mieszkanie")))
	if typ == "dom_jednorodzinny":
		typ = "dom"
	var mnoz := float(mnozniki.get(typ, 1.0))
	return maxi(0, int(round(metraz * stawka * mnoz)))


func tygodnie_remontu(n: Dictionary) -> int:
	## Czas samemu. Zwykły remont: 4–20 tyg. Stan surowy: 3× analogicznego do_remontu.
	var stan := str(n.get("stan", ""))
	var klucz := stan
	var mnoz := 1
	if stan == "surowy":
		klucz = str(_blok_remontu().get("surowy_baza_tygodni", "do_remontu"))
		mnoz = _mnoznik_czasu_surowego()
	var baza := _losuj_tygodnie_zakresu(n, klucz)
	return maxi(1, baza * mnoz)


func tygodnie_remontu_trybu(n: Dictionary, tryb: String) -> int:
	var solo := tygodnie_remontu(n)
	if tryb == "" or tryb == "sam":
		return solo
	var tyg := int(round(float(solo) * mnoznik_tygodni_trybu(tryb)))
	return maxi(1, tyg)


func _losuj_tygodnie_zakresu(n: Dictionary, klucz: String) -> int:
	var rem := _blok_remontu()
	var mapa: Dictionary = rem.get("tygodnie", {}) if rem.get("tygodnie") is Dictionary else {}
	var para: Variant = mapa.get(klucz, [8, 16])
	var od := 8
	var dok := 16
	if para is Array and para.size() >= 2:
		od = int(para[0])
		dok = int(para[1])
	od = clampi(od, 4, 20)
	dok = clampi(dok, od, 20)
	var rng := RandomNumberGenerator.new()
	var sol := absi(str(n.get("id", "remont")).hash())
	rng.seed = sol if sol != 0 else 1
	return rng.randi_range(od, dok)


func _mnoznik_czasu_surowego() -> int:
	var v: Variant = _blok_remontu().get("surowy_mnoznik_czasu", 3)
	if _liczba(v):
		return maxi(1, int(v))
	return 3


func _blok_remontu() -> Dictionary:
	var conf := _nieruchomosci_conf()
	var rem: Variant = conf.get("remont", {})
	if rem is Dictionary:
		return rem
	return {}


func _tryb_remontu(tryb: String) -> Dictionary:
	var tryby: Variant = _blok_remontu().get("tryby", {})
	if tryby is Dictionary and tryby.get(tryb) is Dictionary:
		return tryby[tryb]
	return {}


func mnoznik_tygodni_trybu(tryb: String) -> float:
	var domyslne := {"sam": 1.0, "kumpel": 0.6, "firma": 0.15}
	var blok := _tryb_remontu(tryb)
	if _liczba(blok.get("mnoznik_tygodni")):
		return float(blok["mnoznik_tygodni"])
	return float(domyslne.get(tryb, 1.0))


func mnoznik_kosztu_trybu(tryb: String) -> float:
	var domyslne := {"sam": 1.0, "kumpel": 1.0, "firma": 2.4}
	var blok := _tryb_remontu(tryb)
	if _liczba(blok.get("mnoznik_kosztu")):
		return float(blok["mnoznik_kosztu"])
	return float(domyslne.get(tryb, 1.0))


func zmeczenie_remontu_tydzien(tryb: String) -> int:
	var domyslne := {"sam": 22, "kumpel": 10, "firma": 0}
	var blok := _tryb_remontu(tryb)
	if _liczba(blok.get("zmeczenie_fizyczne_tydzien")):
		return int(blok["zmeczenie_fizyczne_tydzien"])
	return int(domyslne.get(tryb, 0))


func nazwa_trybu_remontu(tryb: String) -> String:
	match tryb:
		"kumpel":
			return "z kumplem"
		"firma":
			return "firma"
		_:
			return "samemu"


func koszt_startu_remontu(n: Dictionary, tryb: String) -> int:
	var mat := koszt_remontu_prawdziwy(n)
	if mat <= 0:
		return 0
	return maxi(0, int(round(float(mat) * mnoznik_kosztu_trybu(tryb))))


func sugerowana_stawka_tygodniowa(n: Dictionary) -> int:
	var mat := koszt_remontu_prawdziwy(n)
	var tyg := tygodnie_remontu_trybu(n, "kumpel")
	if tyg <= 0:
		tyg = 1
	var udzial := 0.35
	var blok := _tryb_remontu("kumpel")
	if _liczba(blok.get("udzial_robocizny")):
		udzial = float(blok["udzial_robocizny"])
	return maxi(50, int(round(float(mat) * udzial / float(tyg))))


func min_stawka_tygodniowa(n: Dictionary, relacja: int) -> int:
	var sug := sugerowana_stawka_tygodniowa(n)
	var rel := clampi(relacja, 0, 100)
	var przy0 := 1.15
	var przy100 := 0.15
	var blok := _tryb_remontu("kumpel")
	if _liczba(blok.get("min_przy_relacji_0")):
		przy0 = float(blok["min_przy_relacji_0"])
	if _liczba(blok.get("min_przy_relacji_100")):
		przy100 = float(blok["min_przy_relacji_100"])
	var wsp := przy0 + (przy100 - przy0) * (float(rel) / 100.0)
	return maxi(0, int(round(float(sug) * wsp)))


func zaproponuj_pomoc_remontu(swiat: Dictionary, indeks: int, ref: String, kwota: int, laczna: bool) -> Dictionary:
	var out := {"ok": false, "powod": "", "tekst": ""}
	var kand := _kandydat_po_ref(swiat, ref)
	if kand.is_empty():
		out["powod"] = "Nie ma tej osoby."
		out["tekst"] = out["powod"]
		return out
	if not (swiat.get("majatek") is Dictionary):
		out["powod"] = "Brak majątku."
		out["tekst"] = out["powod"]
		return out
	var maj: Dictionary = swiat["majatek"]
	var lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if indeks < 0 or indeks >= lista.size() or not (lista[indeks] is Dictionary):
		out["powod"] = "Zły indeks."
		out["tekst"] = out["powod"]
		return out
	var n: Dictionary = lista[indeks]
	var osoba: Dictionary = kand.get("osoba", {}) if kand.get("osoba") is Dictionary else {}
	var relacja := _relacja_osoby(osoba)
	var tyg := tygodnie_remontu_trybu(n, "kumpel")
	var min_tyg := min_stawka_tygodniowa(n, relacja)
	var sug := sugerowana_stawka_tygodniowa(n)
	var oferowana := kwota
	var lacznie := kwota
	if laczna:
		oferowana = int(floor(float(kwota) / float(maxi(1, tyg))))
	else:
		lacznie = kwota * tyg
	var imie := str(kand.get("nazwa", ref))
	if oferowana < min_tyg:
		out["powod"] = "%s odrzuca. Relacja %d: od %d zł/tydz. (sugerowane %d)." % [imie, relacja, min_tyg, sug]
		out["tekst"] = out["powod"]
		out["min_tydzien"] = min_tyg
		out["sugerowana"] = sug
		return out
	var pakiet := {
		"ref": ref,
		"nazwa": imie,
		"laczna": laczna,
		"stawka_tygodniowa": 0 if laczna else kwota,
		"kwota_laczna": lacznie if laczna else 0,
	}
	var start: Dictionary = remont(swiat, indeks, "kumpel", pakiet)
	if not bool(start.get("ok", false)):
		out["powod"] = str(start.get("powod", "Nie udało się zacząć."))
		out["tekst"] = out["powod"]
		return out
	start["tekst"] = "%s zgadza się. " % imie + str(start.get("tekst", ""))
	return start


func _kandydat_po_ref(swiat: Dictionary, ref: String) -> Dictionary:
	for k in kandydaci_pomocy_oceny(swiat):
		if k is Dictionary and str(k.get("ref", "")) == ref:
			return k
	return {}


func _kasa_bohatera(swiat: Dictionary) -> int:
	var b: Variant = swiat.get("bohater", {})
	if b is Dictionary and _liczba(b.get("pieniadze")):
		return int(b["pieniadze"])
	return 0


func _ustaw_kase(swiat: Dictionary, kasa: int) -> void:
	var b: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	b["pieniadze"] = kasa
	swiat["bohater"] = b


func udzial_regeneracji_zmeczenia(bohater: Dictionary) -> float:
	## 50% przy zdrowiu 0, 80% przy zdrowiu 100. Średnia kondycji (albo zdrowie) i psychiki.
	var fiz := _poziom_zdrowia_0_100(bohater, "kondycja", "zdrowie")
	var psy := _poziom_zdrowia_0_100(bohater, "psychika", "")
	var srednia := (fiz + psy) / 2.0
	return clampf(0.50 + 0.30 * (srednia / 100.0), 0.50, 0.80)


func regeneruj_zmeczenie_tydzien(swiat: Dictionary) -> void:
	var b: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	var udzial := udzial_regeneracji_zmeczenia(b)
	_obniz_zmeczenie_pole(b, "zmeczenie_fizyczne", udzial)
	_obniz_zmeczenie_pole(b, "zmeczenie_psychiczne", udzial)
	if _liczba(b.get("zmeczenie_fizyczne")):
		b["zmeczenie"] = int(b["zmeczenie_fizyczne"])
	elif _liczba(b.get("zmeczenie")):
		_obniz_zmeczenie_pole(b, "zmeczenie", udzial)
	swiat["bohater"] = b


func _poziom_zdrowia_0_100(bohater: Dictionary, pole: String, zapas: String) -> float:
	var v := 50.0
	if _liczba(bohater.get(pole)):
		v = float(bohater[pole])
	elif zapas != "" and _liczba(bohater.get(zapas)):
		v = float(bohater[zapas])
	return clampf(v, 0.0, 100.0)


func _obniz_zmeczenie_pole(bohater: Dictionary, klucz: String, udzial: float) -> void:
	if not _liczba(bohater.get(klucz)):
		return
	var zostaje := int(round(float(int(bohater[klucz])) * (1.0 - udzial)))
	bohater[klucz] = clampi(zostaje, 0, 100)


func _dodaj_zmeczenie_fizyczne(swiat: Dictionary, ile: int) -> void:
	if ile <= 0:
		return
	var b: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	var z := 0
	if _liczba(b.get("zmeczenie_fizyczne")):
		z = int(b["zmeczenie_fizyczne"])
	elif _liczba(b.get("zmeczenie")):
		z = int(b["zmeczenie"])
	b["zmeczenie_fizyczne"] = clampi(z + ile, 0, 100)
	b["zmeczenie"] = int(b["zmeczenie_fizyczne"])
	swiat["bohater"] = b


func tekst_szacunku_remontu(n: Dictionary) -> String:
	var prawda := koszt_remontu_prawdziwy(n)
	if prawda <= 0:
		return "Remont: przy tym stanie nie wygląda na potrzebny."
	var kwota := prawda
	if bool(n.get("szacunek_remontu_dokladny", false)) and _liczba(n.get("szacunek_remontu_zl")):
		kwota = int(n["szacunek_remontu_zl"])
		return "Szacunek remontu po pomocy: %s zł (bliżej rzeczywistego kosztu)." % formatuj_cene_auta(kwota)
	if _liczba(n.get("szacunek_remontu_zl")):
		kwota = int(n["szacunek_remontu_zl"])
	else:
		var szum := 75 + (absi(str(n.get("id", "x")).hash()) % 51)
		kwota = int(round(float(prawda) * (float(szum) / 100.0)))
	return "Szacowany koszt remontu: %s zł. To szacunek gracza, może być nietrafiony." % formatuj_cene_auta(kwota)


func _wpisz_szacunek_remontu(oferta: Dictionary, rng: RandomNumberGenerator) -> void:
	var prawda := koszt_remontu_prawdziwy(oferta)
	oferta["koszt_remontu_zl"] = prawda
	if prawda <= 0:
		oferta["szacunek_remontu_zl"] = 0
		return
	oferta["szacunek_remontu_zl"] = int(round(float(prawda) * rng.randf_range(0.72, 1.35)))


func popros_o_pomoc_remontu(swiat: Dictionary, oferta_id: String, kandydat_ref: String) -> Dictionary:
	var out := {"ok": false, "tekst": "", "powod": ""}
	var oferta: Dictionary = _znajdz_oferte(swiat, oferta_id)
	if oferta.is_empty():
		out["powod"] = "Nie ma tej oferty."
		return out
	var prawda := koszt_remontu_prawdziwy(oferta)
	if prawda <= 0:
		out["ok"] = true
		out["tekst"] = "Pomoc: remont raczej nie jest potrzebny."
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = absi((oferta_id + kandydat_ref).hash())
	if rng.seed == 0:
		rng.seed = 1
	var dokladny := int(round(float(prawda) * rng.randf_range(0.92, 1.08)))
	oferta["szacunek_remontu_zl"] = dokladny
	oferta["szacunek_remontu_dokladny"] = true
	_zapisz_oferte(swiat, oferta)
	var imie := kandydat_ref
	for k in kandydaci_pomocy_oceny(swiat):
		if k is Dictionary and str(k.get("ref", "")) == kandydat_ref:
			imie = str(k.get("nazwa", kandydat_ref))
			break
	out["ok"] = true
	out["tekst"] = "%s ocenia remont na około %s zł." % [imie, formatuj_cene_auta(dokladny)]
	return out


func _generuj_start(miasta: Array, miasto_gracza_id: String, ziarno: int, conf: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = ziarno
	var out: Array = []
	# Start = okno w mieście bohatera. Reszta kraju dochodzi przy szukaniu, nie z góry.
	var hero := _wzbogac_jedno_miasto(_miasto_po_id(miasta, miasto_gracza_id))
	if bool(hero.get("brak_miasta", false)) or str(hero.get("id", "")) == "":
		return out
	var hid := str(hero.get("id", ""))
	var licznik := {}
	var dodane := 0
	var proby := 0
	while dodane < OKNO_STARTOWE_AUT and proby < OKNO_STARTOWE_AUT * 6:
		proby += 1
		var kat := "mieszkanie" if dodane == 0 else _losuj_typ_rynku(conf, rng)
		var pula := pula_w_zasiegu("miasto", miasto_gracza_id, kat)
		if pula >= 0 and int(licznik.get(kat, 0)) >= pula:
			continue
		out.append(_losuj_nieruchomosc(kat, hero, hid, rng, conf, hero))
		licznik[kat] = int(licznik.get(kat, 0)) + 1
		dodane += 1
	# Telefon, laptop, komputer, rower i sprzęt dochodzą oknem przy wejściu w kategorię.
	if rng.randf() < 0.35:
		out.append(_losuj_dobro("ksiazka", hero, rng, hid, conf, hero))
	if rng.randf() < 0.08:
		out.append(_losuj_dobro("samolot", hero, rng, hid, conf, hero))
	if rng.randf() < 0.03:
		out.append(_losuj_dobro("smiglowiec_bojowy", hero, rng, hid, conf, hero))
	return out


func _przewin_pule(stare: Array, miasta: Array, miasto_gracza_id: String, ziarno: int, conf: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = ziarno
	var odsw: Dictionary = conf.get("odswiezanie_tur", {}) if conf.get("odswiezanie_tur") is Dictionary else {}
	var znika := float(odsw.get("znika_udzial", 0.35))
	var dochodzi := float(odsw.get("dochodzi_udzial", 0.4))
	var zostaje: Array = []
	# Auta osobno — ten przebieg nie rusza samochodów.
	var auta: Array = []
	for o in stare:
		if not (o is Dictionary):
			continue
		if str(o.get("kategoria", "")) == "samochod":
			auta.append(o)
			continue
		if rng.randf() >= znika:
			zostaje.append(o)
	var bez_aut := stare.size() - auta.size()
	var ile_nowych := clampi(maxi(1, int(round(float(maxi(1, bez_aut)) * dochodzi))), 1, MAX_JEDNEJ_DOKLADKI_AUT)
	var hero := _wzbogac_jedno_miasto(_miasto_po_id(miasta, miasto_gracza_id))
	var hid := str(hero.get("id", ""))
	if bool(hero.get("brak_miasta", false)):
		hid = ""
	var pula := _wybierz_miasta(miasta, hid, rng, 6)
	var dodano := 0
	for _i in ile_nowych:
		if pula.is_empty():
			break
		var miasto: Dictionary = pula[rng.randi_range(0, pula.size() - 1)]
		var roll := rng.randf()
		if roll < 0.75:
			zostaje.append(_losuj_nieruchomosc(_losuj_typ_rynku(conf, rng), miasto, hid, rng, conf, hero))
		else:
			zostaje.append(_losuj_dobro("ksiazka", miasto, rng, hid, conf, hero))
		dodano += 1
	if dodano == 0 and hid != "":
		zostaje.append(_losuj_nieruchomosc("mieszkanie", hero, hid, rng, conf, hero))
	zostaje.append_array(auta)
	return zostaje


func _odswiez_pule_aut(stare: Array, _miasta: Array, _miasto_gracza_id: String, _ziarno: int, _conf: Dictionary) -> Array:
	## Stary przebieg dorzucał auta co tydzień. Zostaje tylko wygaśnięcie, bez nowych ogłoszeń.
	return _wygas_auta(stare, 0)


func _przytnij_per_miasto_bez_aut(oferty: Array, max_na_miasto: int, rng: RandomNumberGenerator) -> Array:
	var auta: Array = []
	var reszta: Array = []
	for o in oferty:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod":
			auta.append(o)
		else:
			reszta.append(o)
	return _przytnij_per_miasto(reszta, max_na_miasto, rng) + auta


func _losuj_typ_rynku(conf: Dictionary, rng: RandomNumberGenerator) -> String:
	var wagi_map: Dictionary = {}
	if conf.get("rynek_wagi_typu") is Dictionary:
		wagi_map = conf["rynek_wagi_typu"]
	var ids: Array = []
	var wagi: Array = []
	for id in ["mieszkanie", "dom", "apartament", "willa"]:
		var w := float(wagi_map.get(id, 0))
		if w <= 0.0:
			continue
		ids.append(id)
		wagi.append(w)
	if ids.is_empty():
		return "mieszkanie" if rng.randf() < 0.72 else "dom"
	return str(ids[_wazony_indeks(wagi, ids.size(), rng)])


func _losuj_nieruchomosc(kat: String, miasto: Dictionary, miasto_gracza_id: String, rng: RandomNumberGenerator, conf: Dictionary, miasto_gracza: Dictionary = {}, strona: String = "uzywany", stan_wymuszony: String = "") -> Dictionary:
	var mid := str(miasto.get("id", ""))
	var mnaz := str(miasto.get("nazwa", "?"))
	var to_gracz := mid != "" and mid == miasto_gracza_id
	var metraz := _losuj_metraz(kat, conf, rng)
	var pokoje := _losuj_pokoje(kat, conf, rng, metraz)
	var rynek_stan := "nowy" if strona == "nowy" and kategoria_ma_nowe_lokum(kat) else "uzywany"
	var stan := _losuj_stan(kat, conf, rng)
	if rynek_stan == "nowy":
		stan = _stan_nowego_lokum(rng, stan_wymuszony)
	# Wygoda i cena: kilometry od środka tego lokum. Karta: kilometry od miasta bohatera.
	var odl_lokalna := odleglosc_miedzy_miejscami(miasto, miasto, rng)
	var hero := _bohater_do_odleglosci(miasto, miasto_gracza_id, miasto_gracza)
	var odl := odleglosc_miedzy_miejscami(hero, miasto, rng)
	var wygoda := _licz_wygode(metraz, stan, odl_lokalna, to_gracz, conf, kat)
	var cena: Variant = _licz_cene(_kat_ceny_rynku(kat), metraz, stan, to_gracz, odl_lokalna, rng, conf)
	var id := "n_%s_%s_%d" % [kat, mid, rng.randi()]
	var oferta := {
		"id": id,
		"kategoria": kat,
		"typ": _typ_dom_id(kat),
		"typ_nazwa": _typ_lokum_nazwa(kat),
		"nieruchomosc": true,
		"nazwa": ("%s, %d m²" % [_typ_lokum_nazwa(kat), metraz]),
		"metraz_m2": metraz,
		"pokoje": pokoje,
		"stan": stan,
		"miasto_id": mid,
		"miasto_nazwa": mnaz,
		"miasto_gracza": to_gracz,
		"odleglosc_km": odl,
		"wygoda": wygoda,
		"cena_zl": _cena_lub_null(zaokraglij_cene(kat, cena), cena),
		"rynek_stan": rynek_stan,
		"sposob_odbioru": "osobisty",
		"propozycja_do_poprawki": true,
		"cena_propozycja_do_poprawki": true,
		"zrodlo_ceny": "istniejacy_wzor_lokalu_nie_gus" if rynek_stan == "nowy" else "istniejacy_wzor_lokalu",
		"obrazek": placeholder_sciezka(kat),
	}
	_wpisz_szacunek_remontu(oferta, rng)
	_wpisz_miejsce_oferty(oferta, miasto, hero)
	return oferta


func _losuj_dobro(kat: String, miasto: Dictionary, rng: RandomNumberGenerator, miasto_gracza_id: String = "", conf: Dictionary = {}, miasto_gracza: Dictionary = {}, stan_wymuszony: String = "", rekord_wymuszony: Dictionary = {}) -> Dictionary:
	if kat == "samochod":
		return _losuj_samochod(miasto, rng, miasto_gracza_id, conf)
	if kat == "samolot" or kat == "smiglowiec_bojowy":
		return _losuj_z_katalogu_pojazdu_specjalnego(kat, miasto, rng, miasto_gracza_id, conf, miasto_gracza)
	var dane := wczytaj()
	var stan := "nowy" if rng.randf() < _udzial_nowych_dobr() else "uzywany"
	if stan_wymuszony == "nowy" or stan_wymuszony == "uzywany":
		stan = stan_wymuszony
	var z_kat := rekord_wymuszony
	if z_kat.is_empty():
		z_kat = _dobierz_z_katalogu_dobra(kat, rng, stan == "uzywany")
	var marki: Array = []
	var modele: Array = []
	if dane.get("pule_marek") is Dictionary and dane["pule_marek"].get(kat) is Array:
		marki = dane["pule_marek"][kat]
	if dane.get("pule_modeli") is Dictionary and dane["pule_modeli"].get(kat) is Array:
		modele = dane["pule_modeli"][kat]
	var marka := str(z_kat.get("marka", ""))
	var model := str(z_kat.get("model", z_kat.get("nazwa", "")))
	if marka == "":
		marka = str(marki[rng.randi_range(0, marki.size() - 1)]) if not marki.is_empty() else kat
	if model == "":
		model = str(modele[rng.randi_range(0, modele.size() - 1)]) if not modele.is_empty() else ""
	var stany := _losuj_stany_jakosci(stan, rng)
	var uzywa_lat := _kategoria_uzywa_lat(kat)
	var lata := 0
	var przebieg_km := 0
	if uzywa_lat:
		lata = _losuj_lata_od_zakupu(stan, rng)
	else:
		przebieg_km = _losuj_przebieg_km(kat, stan, rng)
	var cena_dobra: Variant = null
	var stan_dekl := int(stany.get("stan_deklarowany", 80))
	if z_kat.get("cena_zl") is int or z_kat.get("cena_zl") is float:
		cena_dobra = _cena_z_katalogu_wiekiem(float(z_kat["cena_zl"]), stan, lata, stan_dekl, rng, kat)
	else:
		cena_dobra = _cena_dobra(kat, stan, rng, stan_dekl, przebieg_km)
		if uzywa_lat and (cena_dobra is int or cena_dobra is float):
			cena_dobra = _cena_z_katalogu_wiekiem(float(cena_dobra), stan, lata, stan_dekl, rng, kat)
	var skala_ksiazki: Dictionary = {}
	if kat == "ksiazka" and stan == "uzywany":
		skala_ksiazki = _skala_uzywanej_ksiazki(rng)
		stany["stan_rzeczywisty"] = int(skala_ksiazki.get("stan", 70))
		stany["stan_deklarowany"] = int(skala_ksiazki.get("stan", 70))
		stany["stan_klamstwo"] = false
		if cena_dobra is int or cena_dobra is float:
			cena_dobra = float(cena_dobra) * float(skala_ksiazki.get("mnoznik", 1.0))
	if cena_dobra is int or cena_dobra is float:
		var obcieta := _ogranicz_pasmem_dobra(kat, stan, float(cena_dobra))
		cena_dobra = _cena_lub_null(zaokraglij_cene(kat, obcieta), obcieta)
	var mid := str(miasto.get("id", ""))
	var to_gracz := mid != "" and mid == miasto_gracza_id
	var hero_d := _bohater_do_odleglosci(miasto, miasto_gracza_id, miasto_gracza)
	var odl := odleglosc_miedzy_miejscami(hero_d, miasto, rng)
	var oferta := {
		"id": "d_%s_%d" % [kat, rng.randi()],
		"kategoria": kat,
		"nieruchomosc": false,
		"nazwa": ("%s %s" % [marka, model]).strip_edges(),
		"marka": marka,
		"model": model,
		"segment": _segment_oferty_dobra(kat, z_kat),
		"segment_ceny": str(z_kat.get("segment", "")),
		"stan": stan,
		"stan_rzeczywisty": stany.get("stan_rzeczywisty"),
		"stan_deklarowany": stany.get("stan_deklarowany"),
		"stan_klamstwo": bool(stany.get("stan_klamstwo", false)),
		"stan_ujawniony": false,
		"miasto_id": mid,
		"miasto_nazwa": str(miasto.get("nazwa", "")),
		"miasto_gracza": to_gracz,
		"odleglosc_km": odl,
		"cena_zl": cena_dobra,
		"cena_wyjsciowa": cena_dobra,
		"sposob_odbioru": _losuj_sposob_odbioru(rng),
		"propozycja_do_poprawki": true,
		"obrazek": placeholder_sciezka(kat),
	}
	var kid := str(z_kat.get("id", "")).strip_edges()
	if kid != "":
		oferta["katalog_id"] = kid
	_wpisz_miejsce_oferty(oferta, miasto, hero_d)
	if kategoria_drobna(kat):
		_ustaw_odbior_drobiazgu(oferta, hero_d, mid, rng)
	if uzywa_lat:
		oferta["lata_od_zakupu"] = lata
		oferta["przebieg_km"] = null
	else:
		oferta["przebieg_km"] = przebieg_km
	var usterki := _losuj_usterki_dobra(kat, stan, rng, str(oferta.get("segment", "")))
	oferta["usterki_rzeczywiste"] = usterki.get("rzeczywiste", [])
	oferta["usterki_deklarowane"] = usterki.get("deklarowane", [])
	oferta["usterki_ukryte"] = usterki.get("ukryte", [])
	oferta["usterki_wykryte"] = []
	if bool(usterki.get("ma_szacunek", false)):
		oferta["szacunek_usterek"] = true
	if kat == "ksiazka":
		oferta["usterki_rzeczywiste"] = []
		oferta["usterki_deklarowane"] = []
		oferta["usterki_ukryte"] = []
		oferta["rodzaj_nazwa"] = str(z_kat.get("rodzaj_nazwa", ""))
		oferta["podrodzaj_nazwa"] = str(z_kat.get("podrodzaj_nazwa", ""))
		if not skala_ksiazki.is_empty():
			oferta["stan_ksiazki"] = str(skala_ksiazki.get("id", ""))
			oferta["stan_ksiazki_nazwa"] = str(skala_ksiazki.get("nazwa", ""))
	_naloz_rabat_usterek_na_cene(oferta)
	return oferta


func _skala_uzywanej_ksiazki(rng: RandomNumberGenerator) -> Dictionary:
	var opcje: Array = [
		{"id": "swietny", "nazwa": "Świetny", "stan": 92, "mnoznik": 0.9, "waga": 2},
		{"id": "dobry", "nazwa": "Dobry", "stan": 74, "mnoznik": 0.7, "waga": 4},
		{"id": "zaczytany", "nazwa": "Zaczytany", "stan": 48, "mnoznik": 0.45, "waga": 3},
		{"id": "rozpadajacy", "nazwa": "Rozpadający się", "stan": 22, "mnoznik": 0.25, "waga": 1},
	]
	return _losuj_rekord_wazony(opcje, rng, false)


func _kategoria_uzywa_lat(kat: String) -> bool:
	var dane := wczytaj()
	if dane.get("katalogi_dobr") is Dictionary and dane["katalogi_dobr"].get("wiek_zamiast_przebiegu") is Array:
		return kat in dane["katalogi_dobr"]["wiek_zamiast_przebiegu"]
	return kat in ["telefon", "rower", "laptop", "komputer", "sprzet", "ksiazka"]


func _losuj_lata_od_zakupu(stan: String, rng: RandomNumberGenerator) -> int:
	var dane := wczytaj()
	var conf: Dictionary = dane.get("lata_od_zakupu", {}) if dane.get("lata_od_zakupu") is Dictionary else {}
	if stan == "nowy":
		return int(conf.get("nowy", 0))
	var u: Variant = conf.get("uzywany", {"od": 1, "do": 8})
	if u is Dictionary:
		return rng.randi_range(int(u.get("od", 1)), int(u.get("do", 8)))
	return rng.randi_range(1, 8)


func _cena_z_katalogu_wiekiem(baza: float, stan: String, lata: int, stan_dekl: int, rng: RandomNumberGenerator, kat: String = "") -> float:
	var dane := wczytaj()
	var conf: Dictionary = dane.get("lata_od_zakupu", {}) if dane.get("lata_od_zakupu") is Dictionary else {}
	var v := baza
	if stan == "uzywany":
		var kat_blok: Dictionary = {}
		if conf.get("kategorie") is Dictionary and conf["kategorie"].get(kat) is Dictionary:
			kat_blok = conf["kategorie"][kat]
		if not kat_blok.is_empty():
			var r1 := float(kat_blok.get("spadek_rok_1", 0.22))
			var rk := float(kat_blok.get("spadek_kolejny", 0.06))
			var mn := float(kat_blok.get("mnoznik_min", 0.35))
			var retain := 1.0
			var lata_n := maxi(lata, 0)
			if lata_n >= 1:
				retain *= maxf(0.0, 1.0 - r1)
			if lata_n > 1:
				retain *= pow(maxf(0.0, 1.0 - rk), float(lata_n - 1))
			v *= maxf(mn, retain)
		else:
			var za_rok := float(conf.get("mnoznik_ceny_za_rok", 0.08))
			var mn2 := float(conf.get("mnoznik_min", 0.35))
			v *= maxf(mn2, 1.0 - float(lata) * za_rok)
		v *= 0.85 + 0.15 * (float(clampi(stan_dekl, 0, 100)) / 100.0)
		v *= rng.randf_range(0.92, 1.08)
	return v


## Sprzęt trzyma w segmencie oferty podkategorię (słuchawki, mysz), bo usterki filtrują po niej.
## Drabinka budżet–flagowiec zostaje w polu segment katalogu i w segment_ceny oferty.
func _segment_oferty_dobra(kat: String, z_kat: Dictionary) -> String:
	var pod := str(z_kat.get("podkategoria", ""))
	if kat == "sprzet" and pod != "":
		return pod
	var segment := str(z_kat.get("segment", ""))
	if segment != "":
		return segment
	return pod


## Pasmo dobra_cena_propozycja: klamra końcowej ceny katalogowej albo losowanie, gdy brak cena_zl.
func _ogranicz_pasmem_dobra(kat: String, stan: String, cena: float) -> float:
	var dane := wczytaj()
	if not (dane.get("dobra_cena_propozycja") is Dictionary):
		return cena
	var blok: Variant = dane["dobra_cena_propozycja"].get(kat)
	if not (blok is Dictionary):
		return cena
	var przedzial: Variant = blok.get(stan)
	if not (przedzial is Array) or przedzial.size() < 2:
		return cena
	if not _liczba(przedzial[0]) or not _liczba(przedzial[1]):
		return cena
	var lo := float(przedzial[0])
	var hi := float(przedzial[1])
	if hi < lo:
		var zamiana := lo
		lo = hi
		hi = zamiana
	return clampf(cena, lo, hi)


func _modele_katalogu_dobra(kat: String) -> Array:
	var dane := wczytaj()
	var sciezka := ""
	if dane.get("katalogi_dobr") is Dictionary:
		sciezka = str(dane["katalogi_dobr"].get(kat, ""))
	if sciezka == "" or not FileAccess.file_exists(sciezka):
		return []
	var surowe: Variant = _katalogi_dobr_cache.get(sciezka, null)
	if not (surowe is Dictionary):
		var plik := FileAccess.open(sciezka, FileAccess.READ)
		if plik == null:
			return []
		surowe = JSON.parse_string(plik.get_as_text())
		if not (surowe is Dictionary):
			return []
		_katalogi_dobr_cache[sciezka] = surowe
	var kat_d: Dictionary = surowe
	if kat == "komputer" and kat_d.get("komputer") is Array:
		return kat_d["komputer"]
	if kat == "laptop" and kat_d.get("laptop") is Array:
		return kat_d["laptop"]
	if kat == "ksiazka" and kat_d.get("rodzaje") is Array:
		var plasko: Array = []
		for r in kat_d["rodzaje"]:
			if not (r is Dictionary):
				continue
			var pod: Array = r.get("podrodzaje", []) if r.get("podrodzaje") is Array else []
			for p in pod:
				if not (p is Dictionary):
					continue
				var kopia: Dictionary = p.duplicate()
				kopia["rodzaj_id"] = str(r.get("id", ""))
				kopia["rodzaj_nazwa"] = str(r.get("nazwa", ""))
				kopia["podrodzaj_nazwa"] = str(p.get("nazwa", ""))
				kopia["marka"] = str(r.get("nazwa", ""))
				kopia["model"] = str(p.get("nazwa", ""))
				kopia["nazwa"] = "%s · %s" % [str(r.get("nazwa", "")), str(p.get("nazwa", ""))]
				plasko.append(kopia)
		if not plasko.is_empty():
			return plasko
	if kat == "ksiazka" and kat_d.get("tytuly") is Array:
		return kat_d["tytuly"]
	if kat_d.get("modele") is Array:
		return kat_d["modele"]
	return []


func liczba_modeli_katalogu(kat: String) -> int:
	var n := 0
	for m in _modele_katalogu_dobra(kat):
		if m is Dictionary:
			n += 1
	return n


func _id_modelu_katalogu(m: Dictionary, indeks: int) -> String:
	var id := str(m.get("id", "")).strip_edges()
	if id == "":
		return "i%d" % indeks
	return id


func _wolne_modele_nowego(kat: String, oferty: Array, filtry: Dictionary = {}) -> Array:
	## Jedna nowa oferta na model. Drugi zasięg nie dokłada kopii tego samego id.
	var zajete := {}
	for o in oferty:
		if not (o is Dictionary):
			continue
		if str(o.get("kategoria", "")) != kat or str(o.get("stan", "")) != "nowy":
			continue
		var kid := str(o.get("katalog_id", "")).strip_edges()
		if kid != "":
			zajete[kid] = true
	var wolne: Array = []
	for m in _kandydaci_katalogu_dobra(kat, filtry, true):
		var id := str(m.get("id", ""))
		if id != "" and zajete.has(id):
			continue
		wolne.append(m)
	return wolne


func _wolny_model_nowego(kat: String, oferty: Array, rng: RandomNumberGenerator, filtry: Dictionary = {}) -> Dictionary:
	var wolne := _wolne_modele_nowego(kat, oferty, filtry)
	if wolne.is_empty():
		return {}
	return _losuj_rekord_wazony(wolne, rng, false)


func _dobierz_uzywane_dobro(kat: String, rng: RandomNumberGenerator, filtry: Dictionary = {}) -> Dictionary:
	return _losuj_rekord_wazony(_kandydaci_katalogu_dobra(kat, filtry, false), rng, true)


func _dobierz_z_katalogu_dobra(kat: String, rng: RandomNumberGenerator, preferuj_uzywane: bool = false) -> Dictionary:
	return _losuj_rekord_wazony(_kandydaci_katalogu_dobra(kat, {}, not preferuj_uzywane), rng, preferuj_uzywane)


func _losuj_z_katalogu_pojazdu_specjalnego(
	kat: String,
	miasto: Dictionary,
	rng: RandomNumberGenerator,
	miasto_gracza_id: String,
	conf: Dictionary,
	miasto_gracza: Dictionary = {}
) -> Dictionary:
	var rekord := _dobierz_z_katalogu_dobra(kat, rng)
	var stan := "nowy" if rng.randf() < 0.55 else "uzywany"
	var stany := _losuj_stany_jakosci(stan, rng)
	var lata := 0 if stan == "nowy" else rng.randi_range(1, 15)
	var cena: Variant = null
	if rekord.get("cena_zl") is int or rekord.get("cena_zl") is float:
		cena = _cena_z_katalogu_wiekiem(float(rekord["cena_zl"]), stan, lata, int(stany.get("stan_deklarowany", 80)), rng, kat)
		cena = _cena_lub_null(zaokraglij_cene(kat, cena), cena)
	elif rekord.get("cena_usd") is int or rekord.get("cena_usd") is float:
		# Szacunek PLN ≈ USD * 4 — tylko gdy katalog ma USD i brak PLN.
		cena = _cena_z_katalogu_wiekiem(float(rekord["cena_usd"]) * 4.0, stan, lata, int(stany.get("stan_deklarowany", 80)), rng, kat)
		cena = _cena_lub_null(zaokraglij_cene(kat, cena), cena)
	else:
		cena = _cena_dobra(kat, stan, rng, int(stany.get("stan_deklarowany", 80)), 0)
	var mid := str(miasto.get("id", ""))
	var to_gracz := mid != "" and mid == miasto_gracza_id
	var hero_s := _bohater_do_odleglosci(miasto, miasto_gracza_id, miasto_gracza)
	var odl := odleglosc_miedzy_miejscami(hero_s, miasto, rng)
	var czas: Dictionary = rekord.get("czas_oczekiwania", {}) if rekord.get("czas_oczekiwania") is Dictionary else {}
	var oferta_s := {
		"id": "d_%s_%d" % [kat, rng.randi()],
		"kategoria": kat,
		"nieruchomosc": false,
		"nazwa": ("%s %s" % [str(rekord.get("marka", "")), str(rekord.get("model", ""))]).strip_edges(),
		"marka": str(rekord.get("marka", "")),
		"model": str(rekord.get("model", "")),
		"stan": stan,
		"stan_rzeczywisty": stany.get("stan_rzeczywisty"),
		"stan_deklarowany": stany.get("stan_deklarowany"),
		"stan_klamstwo": bool(stany.get("stan_klamstwo", false)),
		"stan_ujawniony": false,
		"lata_od_zakupu": lata if stan == "uzywany" else 0,
		"czas_oczekiwania": czas if stan == "nowy" else {},
		"szacunek": bool(rekord.get("szacunek", true)),
		"zrodlo": str(rekord.get("zrodlo", "")),
		"miasto_id": mid,
		"miasto_nazwa": str(miasto.get("nazwa", "")),
		"miasto_gracza": to_gracz,
		"odleglosc_km": odl,
		"cena_zl": cena,
		"cena_wyjsciowa": cena,
		"sposob_odbioru": "osobisty",
		"propozycja_do_poprawki": true,
		"obrazek": placeholder_sciezka(kat),
		"uwaga_odblokowanie": "Wiek/licencja — TODO fala 2",
	}
	_wpisz_miejsce_oferty(oferta_s, miasto, hero_s)
	return oferta_s


func _losuj_samochod(
	miasto: Dictionary,
	rng: RandomNumberGenerator,
	miasto_gracza_id: String = "",
	conf: Dictionary = {},
	wymusz_stan: String = "",
	wymusz_region: String = "",
	miasta: Array = [],
	pula_szersza: bool = false,
	miasto_wymuszone: Dictionary = {},
	rekord_wymuszony: Dictionary = {}
) -> Dictionary:
	var rekord := rekord_wymuszony if not rekord_wymuszony.is_empty() else _losuj_rekord_katalogu_aut(rng, wymusz_stan == "uzywany")
	var marka := str(rekord.get("marka", "Samochód"))
	var model := str(rekord.get("model", ""))
	var naped := str(rekord.get("naped", "spalinowy"))
	var tylko_uzywane := bool(rekord.get("tylko_uzywane", false))
	var stan := "uzywany"
	if wymusz_stan == "nowy" or wymusz_stan == "uzywany":
		stan = wymusz_stan
		if stan == "nowy" and tylko_uzywane:
			stan = "uzywany"
	elif tylko_uzywane:
		stan = "uzywany"
	else:
		# Awaryjnie (poza pulą lokalną): stare 38% nowych — pula lokalna zawsze wymusza używane.
		stan = "uzywany" if rng.randf() >= 0.38 else "nowy"
	var stany := _losuj_stany_jakosci(stan, rng)
	# Tier uszkodzony / bardzo tani — obniża stan rzeczywisty.
	var tier_tani := false
	if stan == "uzywany" and rng.randf() < float(_auta_conf().get("szansa_tieru_taniego", 0.18)):
		tier_tani = true
		stany["stan_rzeczywisty"] = clampi(int(stany.get("stan_rzeczywisty", 50)) - rng.randi_range(15, 40), 5, 55)
		if bool(stany.get("stan_klamstwo", false)) or rng.randf() < 0.4:
			stany["stan_deklarowany"] = clampi(int(stany["stan_rzeczywisty"]) + rng.randi_range(10, 35), 0, 100)
			stany["stan_klamstwo"] = true
	var przebieg_km := _losuj_przebieg_km("samochod", stan, rng)
	if tier_tani:
		przebieg_km = maxi(przebieg_km, rng.randi_range(180000, 380000))
	var conf_uzyte: Dictionary = conf
	if conf_uzyte.is_empty():
		conf_uzyte = _nieruchomosci_conf()
	var region: Dictionary
	var miasto_oferty: Dictionary
	if not miasto_wymuszone.is_empty():
		miasto_oferty = miasto_wymuszone
		region = {
			"id": _region_miedzy_miejscami(miasto, miasto_wymuszone),
			"kraj": str(miasto_wymuszone.get("kraj", miasto_wymuszone.get("panstwo", "PL"))),
		}
	else:
		if wymusz_region != "":
			region = _region_oferty_auta_po_id(wymusz_region, rng, conf_uzyte)
		else:
			region = _losuj_region_oferty_auta(rng, conf_uzyte, pula_szersza)
		miasto_oferty = _miasto_dla_regionu_auta(
			str(region.get("id", "miasto")), miasto, miasta, rng, str(region.get("kraj", "PL"))
		)
	var mid := str(miasto_oferty.get("id", ""))
	var to_gracz := mid != "" and mid == miasto_gracza_id
	var odl := odleglosc_miedzy_miejscami(miasto, miasto_oferty, rng)
	var spalanie_v: Variant = null
	var spalanie_jedn := str(rekord.get("spalanie_jednostka", "l/100 km"))
	var spalanie_ukryte := false
	if stan == "nowy":
		if _liczba(rekord.get("spalanie")):
			spalanie_v = float(rekord["spalanie"])
	else:
		if _liczba(rekord.get("spalanie")) and rng.randf() >= 0.32:
			spalanie_v = float(rekord["spalanie"])
		else:
			spalanie_ukryte = true
			spalanie_v = null
	var cena_katalog: Variant = rekord.get("cena_zl")
	var mediana_u: Variant = rekord.get("cena_uzywana_mediana_zl")
	var cena_dobra: Variant = _cena_auta_z_katalogu(
		cena_katalog, stan, rng, int(stany.get("stan_deklarowany", 80)), przebieg_km, mediana_u, tier_tani
	)
	# Zawsze jest cena w puli — awaryjnie z tieru taniego / dobra_cena.
	if not _liczba(cena_dobra):
		cena_dobra = _cena_dobra("samochod", stan, rng, int(stany.get("stan_deklarowany", 80)), przebieg_km)
	if not _liczba(cena_dobra):
		cena_dobra = zaokraglij_cene_auta(rng.randi_range(12000, 45000))
	var usterki := _losuj_usterki_auta(stan, rng, tier_tani)
	var vmax := _predkosc_max_z_rekordu(rekord, naped)
	var spalanie_vmax: Variant = null
	if _liczba(rekord.get("spalanie_przy_vmax")):
		spalanie_vmax = float(rekord["spalanie_przy_vmax"])
	elif _liczba(spalanie_v):
		# Ukryte pole do kosztów przejazdu — nie w UI oferty.
		spalanie_vmax = snappedf(float(spalanie_v) * float(_auta_conf().get("mnoznik_spalania_vmax", 1.55)), 0.1)
	elif _liczba(rekord.get("spalanie")):
		spalanie_vmax = snappedf(float(rekord["spalanie"]) * float(_auta_conf().get("mnoznik_spalania_vmax", 1.55)), 0.1)
	var powiat_id := str(miasto_oferty.get("powiat_id", ""))
	var wojew := str(miasto_oferty.get("wojewodztwo", ""))
	var kraj := str(region.get("kraj", miasto_oferty.get("kraj", "PL")))
	var oferta := {
		"id": "d_samochod_%d" % rng.randi(),
		"kategoria": "samochod",
		"nieruchomosc": false,
		"katalog_id": str(rekord.get("id", "")),
		"nazwa": ("%s %s" % [marka, model]).strip_edges(),
		"marka": marka,
		"model": model,
		"naped": naped,
		"stan": stan,
		"stan_rzeczywisty": stany.get("stan_rzeczywisty"),
		"stan_deklarowany": stany.get("stan_deklarowany"),
		"stan_klamstwo": bool(stany.get("stan_klamstwo", false)),
		"stan_ujawniony": false,
		"przebieg_km": przebieg_km,
		"spalanie": spalanie_v,
		"spalanie_jednostka": spalanie_jedn,
		"spalanie_ukryte": spalanie_ukryte,
		"spalanie_norma": str(rekord.get("spalanie_norma", "")),
		"spalanie_przy_vmax": spalanie_vmax,
		"cena_katalog_zl": cena_katalog if _liczba(cena_katalog) else null,
		"cena_zl": cena_dobra,
		"cena_wyjsciowa": cena_dobra,
		"tier_tani": tier_tani,
		"szacunek_ceny": bool(rekord.get("szacunek", false)) or _liczba(mediana_u),
		"zrodlo_cennika": str(rekord.get("zrodlo", "")),
		"rok_cennika": rekord.get("rok_cennika"),
		"miasto_id": mid,
		"miasto_nazwa": str(miasto_oferty.get("nazwa", "")),
		"powiat_id": powiat_id,
		"wojewodztwo": wojew,
		"miasto_gracza": to_gracz,
		"odleglosc_km": odl,
		"odleglosc_szacunek": true,
		"odleglosc_metoda": "pasmo_administracyjne_bez_gis",
		"propozycja_do_poprawki_odleglosci": true,
		"region_szukania": str(region.get("id", "miasto")),
		"kraj": kraj,
		"sposob_odbioru": "osobisty",
		"sprzedawca": "osoba_prywatna",
		"cena_dostawy_zl": null,
		"usterki_rzeczywiste": usterki.get("rzeczywiste", []),
		"usterki_deklarowane": usterki.get("deklarowane", []),
		"usterki_ukryte": usterki.get("ukryte", []),
		"usterki_wykryte": [],
		"sprowadzenie": bool(rekord.get("sprowadzenie", false)) or bool(rekord.get("import", false)),
		"import": bool(rekord.get("import", false)) or bool(rekord.get("sprowadzenie", false)),
		"z_katalogu_globalny": false,
		"propozycja_do_poprawki": true,
		"obrazek": placeholder_sciezka("samochod"),
	}
	_naloz_efekty_vmax_na_oferte(oferta, usterki.get("rzeczywiste", []), vmax)
	_naloz_rabat_usterek_na_cene(oferta)
	return oferta


func _losuj_rekord_katalogu_aut(rng: RandomNumberGenerator, preferuj_uzywane: bool = false) -> Dictionary:
	var kat := katalog_aut()
	var modele: Array = []
	if kat.get("modele") is Array:
		modele = kat["modele"]
	if modele.is_empty():
		return {"marka": "Samochód", "model": "nieznany", "naped": "spalinowy", "spalanie": null, "cena_zl": null}
	var rek := _losuj_rekord_wazony(modele, rng, preferuj_uzywane)
	if not rek.is_empty():
		return rek
	var fallback: Variant = modele[rng.randi_range(0, modele.size() - 1)]
	return fallback if fallback is Dictionary else {}


## Jedno koło dla aut i dóbr. Waga <= 0 zostaje w puli z podłogą 0,1.
## preferuj_uzywane dokłada ×1,35 rekordom tylko_uzywane.
func _losuj_rekord_wazony(lista: Array, rng: RandomNumberGenerator, preferuj_uzywane: bool = false) -> Dictionary:
	var rekordy: Array = []
	var wagi: Array = []
	for m in lista:
		if not (m is Dictionary):
			continue
		var w := maxf(PODLOGA_WAGI_KATALOGU, float(m.get("waga", 1)))
		if preferuj_uzywane and bool(m.get("tylko_uzywane", false)):
			w *= MNOZNIK_TYLKO_UZYWANE
		rekordy.append(m)
		wagi.append(w)
	if rekordy.is_empty():
		return {}
	var suma := 0.0
	for w in wagi:
		suma += float(w)
	if suma <= 0.0:
		var awaryjny: Dictionary = rekordy[rng.randi_range(0, rekordy.size() - 1)]
		return awaryjny
	var r := rng.randf() * suma
	var acc := 0.0
	for i in rekordy.size():
		acc += float(wagi[i])
		if r <= acc:
			var wybrany: Dictionary = rekordy[i]
			return wybrany
	var ostatni: Dictionary = rekordy[rekordy.size() - 1]
	return ostatni


func _udzial_nowych_dobr() -> float:
	var dane := wczytaj()
	var blok: Variant = dane.get("udzial_ofert_dobr", {})
	if blok is Dictionary and _liczba((blok as Dictionary).get("nowy")):
		return clampf(float((blok as Dictionary).get("nowy")), 0.0, 1.0)
	return 0.7


func _rekord_pasuje_do_filtra_dobra(m: Dictionary, filtry: Dictionary) -> bool:
	var marki := _normalizuj_filtr_marek(filtry.get("marki", []))
	if not marki.is_empty() and not marki.has(str(m.get("marka", ""))):
		return false
	return true


func _kandydaci_katalogu_dobra(kat: String, filtry: Dictionary, tylko_nowe: bool) -> Array:
	var out: Array = []
	var lista := _modele_katalogu_dobra(kat)
	for i in lista.size():
		var m: Variant = lista[i]
		if not (m is Dictionary):
			continue
		if tylko_nowe and bool(m.get("tylko_uzywane", false)):
			continue
		var kopia: Dictionary = (m as Dictionary).duplicate()
		kopia["id"] = _id_modelu_katalogu(m, i)
		if not _rekord_pasuje_do_filtra_dobra(kopia, filtry):
			continue
		out.append(kopia)
	return out


func marki_katalogu_dobra(kat: String) -> Array:
	var widziane := {}
	var out: Array = []
	for m in _modele_katalogu_dobra(kat):
		if not (m is Dictionary):
			continue
		var marka := str(m.get("marka", "")).strip_edges()
		if marka == "" or widziane.has(marka):
			continue
		widziane[marka] = true
		out.append(marka)
	out.sort()
	return out


func _zostalo_w_puli_dobr(swiat: Dictionary, stan: Dictionary, kat: String, poziom: String, strona: String) -> int:
	var id := _id_ludnosci(stan, "")
	var pula := pula_w_zasiegu(poziom, id, kat, strona)
	if pula < 0:
		return 1000000
	return maxi(0, pula - ile_w_zasiegu(swiat, kat, poziom, strona))


func _przytnij_porcje_mieszana_dobr(swiat: Dictionary, stan: Dictionary, kat: String, poziom: String, porcja: int) -> int:
	var zostalo := _zostalo_w_puli_dobr(swiat, stan, kat, poziom, "nowy") + _zostalo_w_puli_dobr(swiat, stan, kat, poziom, "uzywany")
	return mini(porcja, maxi(0, zostalo))


## Nowe: jeden wiersz na model i na miasto z listy salonów. Bez listy — brak salonu w Polsce.
## Sprowadzenie bez salonu: odbiór za granicą, bez dostawy.
func _generuj_oferty_nowych_z_katalogu(rng: RandomNumberGenerator, miasto_gracza_id: String, miasto: Dictionary, miasta: Array = []) -> Array:
	var out: Array = []
	var kat := katalog_aut()
	var modele: Array = kat.get("modele", []) if kat.get("modele") is Array else []
	for m in modele:
		if not (m is Dictionary):
			continue
		if bool(m.get("tylko_uzywane", false)):
			continue
		var marka := str(m.get("marka", ""))
		var miasta_salon: Array = miasta_salonu_marki(marka, miasta)
		if miasta_salon.is_empty():
			if bool(m.get("sprowadzenie", false)) or bool(m.get("import", false)):
				out.append(_oferta_sprowadzona_bez_salonu(m, rng, miasto))
			continue
		for cel_v in miasta_salon:
			if not (cel_v is Dictionary):
				continue
			out.append(_oferta_nowa_z_rekordu_katalogu(m, rng, cel_v, miasto, miasto_gracza_id))
	return out


func _oferta_nowa_z_rekordu_katalogu(rekord: Dictionary, rng: RandomNumberGenerator, miasto_oferty: Dictionary, miasto_gracza: Dictionary, miasto_gracza_id: String) -> Dictionary:
	var marka := str(rekord.get("marka", "Samochód"))
	var model := str(rekord.get("model", ""))
	var naped := str(rekord.get("naped", "spalinowy"))
	var stany := _losuj_stany_jakosci("nowy", rng)
	var spalanie_v: Variant = null
	if _liczba(rekord.get("spalanie")):
		spalanie_v = float(rekord["spalanie"])
	var cena_katalog: Variant = rekord.get("cena_zl")
	var cena_dobra: Variant = _cena_auta_z_katalogu(cena_katalog, "nowy", rng, 100, 0, null, false)
	if not _liczba(cena_dobra):
		cena_dobra = _cena_dobra("samochod", "nowy", rng, 100, 0)
	if not _liczba(cena_dobra):
		cena_dobra = zaokraglij_cene_auta(rng.randi_range(70000, 220000))
	var vmax := _predkosc_max_z_rekordu(rekord, naped)
	var spalanie_vmax: Variant = null
	if _liczba(rekord.get("spalanie_przy_vmax")):
		spalanie_vmax = float(rekord["spalanie_przy_vmax"])
	elif _liczba(spalanie_v):
		spalanie_vmax = snappedf(float(spalanie_v) * float(_auta_conf().get("mnoznik_spalania_vmax", 1.55)), 0.1)
	var sprowadzenie := bool(rekord.get("sprowadzenie", false)) or bool(rekord.get("import", false))
	var szacunek := bool(rekord.get("szacunek", false))
	if sprowadzenie:
		szacunek = true
	var oferta_n := {
		"id": "d_samochod_nowy_%s_%d" % [str(rekord.get("id", "x")), rng.randi()],
		"kategoria": "samochod",
		"nieruchomosc": false,
		"katalog_id": str(rekord.get("id", "")),
		"nazwa": ("%s %s" % [marka, model]).strip_edges(),
		"marka": marka,
		"model": model,
		"naped": naped,
		"stan": "nowy",
		"stan_rzeczywisty": stany.get("stan_rzeczywisty"),
		"stan_deklarowany": stany.get("stan_deklarowany"),
		"stan_klamstwo": false,
		"stan_ujawniony": false,
		"przebieg_km": 0,
		"spalanie": spalanie_v,
		"spalanie_jednostka": str(rekord.get("spalanie_jednostka", "l/100 km")),
		"spalanie_ukryte": false,
		"spalanie_norma": str(rekord.get("spalanie_norma", "")),
		"spalanie_przy_vmax": spalanie_vmax,
		"cena_katalog_zl": cena_katalog if _liczba(cena_katalog) else null,
		"cena_zl": cena_dobra,
		"cena_wyjsciowa": cena_dobra,
		"tier_tani": false,
		"szacunek_ceny": szacunek,
		"zrodlo_cennika": str(rekord.get("zrodlo", "")),
		"rok_cennika": rekord.get("rok_cennika"),
		"sprowadzenie": sprowadzenie,
		"import": sprowadzenie,
		"uwaga_sprowadzenia": str(rekord.get("uwaga_sprowadzenia", rekord.get("uwaga_szacunku", ""))),
		"miasto_id": str(miasto_oferty.get("id", "")),
		"miasto_nazwa": str(miasto_oferty.get("nazwa", "")),
		"powiat_id": str(miasto_oferty.get("powiat_id", "")),
		"wojewodztwo": str(miasto_oferty.get("wojewodztwo", "")),
		"miasto_gracza": str(miasto_oferty.get("id", "")) != "" and str(miasto_oferty.get("id", "")) == miasto_gracza_id,
		"odleglosc_km": odleglosc_miedzy_miejscami(miasto_gracza, miasto_oferty, rng),
		"odleglosc_szacunek": true,
		"odleglosc_metoda": "pasmo_administracyjne_bez_gis",
		"propozycja_do_poprawki_odleglosci": true,
		"region_szukania": _region_miedzy_miejscami(miasto_gracza, miasto_oferty),
		"kraj": "PL",
		"salon": true,
		"sprzedawca": "salon",
		"sposob_odbioru": "osobisty",
		"cena_dostawy_zl": null,
		"usterki_rzeczywiste": [],
		"usterki_deklarowane": [],
		"usterki_ukryte": [],
		"usterki_wykryte": [],
		"z_katalogu_globalny": true,
		"propozycja_do_poprawki": true,
		"obrazek": placeholder_sciezka("samochod"),
	}
	_naloz_efekty_vmax_na_oferte(oferta_n, [], vmax)
	return oferta_n


func _oferta_sprowadzona_bez_salonu(rekord: Dictionary, rng: RandomNumberGenerator, miasto_gracza: Dictionary) -> Dictionary:
	var kraje: Array[String] = ["DE", "CZ", "SK"]
	var kraj := kraje[rng.randi_range(0, kraje.size() - 1)]
	var cel := {
		"id": "zagranica_%s" % kraj.to_lower(),
		"nazwa": kraj,
		"powiat_id": "",
		"wojewodztwo": "",
		"kraj": kraj,
		"panstwo": kraj,
	}
	var oferta := _oferta_nowa_z_rekordu_katalogu(rekord, rng, cel, miasto_gracza, str(miasto_gracza.get("id", "")))
	oferta["salon"] = false
	oferta["sprzedawca"] = "sprowadzenie"
	oferta["kraj"] = kraj
	oferta["miasto_gracza"] = false
	oferta["region_szukania"] = "wysylka_zagranica"
	oferta["sposob_odbioru"] = "osobisty"
	oferta["cena_dostawy_zl"] = null
	oferta["uwaga_salonu"] = "Brak zweryfikowanego salonu tej marki w Polsce. Odbiór za granicą. Bez słowa dostawa i bez ceny przewozu — w danych nie ma cennika."
	oferta["propozycja_do_poprawki"] = true
	oferta["szacunek_ceny"] = true
	return oferta


## propozycja_do_poprawki. Cena od katalogu, nie od twardego sufitu 2–7 tys.
## Nowe: katalog × 1,00–1,06.
## Używane: katalog × przebieg × stan deklarowany × szum 0,96–1,04.
## Przebieg: clamp(1 − (km/200000)×0,45, 0,55, 1). Stan: 0,78–1,00.
## Podłoga zwykła 35% katalogu. Tier uszkodzony × 0,78–0,88 i podłoga 22% katalogu.
## Mediana używanych tylko gdy nie ma katalogu albo mediana ≥ 40% katalogu
## (tania kotwica starego segmentu nie zastępuje auta za ~50 tys.).
## Deklarowane usterki tną osobno, do 42%, już po tej funkcji. Zaokrąglenie: 3 cyfry znaczące auta.
func _cena_auta_z_katalogu(
	cena_katalog: Variant,
	stan: String,
	rng: RandomNumberGenerator,
	stan_deklarowany: int,
	przebieg_km: int,
	mediana_uzywana: Variant = null,
	tier_tani: bool = false
) -> Variant:
	var ma_kat := _liczba(cena_katalog)
	var kat_f := float(cena_katalog) if ma_kat else 0.0
	if stan == "nowy":
		if not ma_kat:
			return null
		var nowe := kat_f * rng.randf_range(1.0, 1.06)
		return _cena_lub_null(zaokraglij_cene_auta(nowe), nowe)
	var uzyj_mediany := false
	if _liczba(mediana_uzywana):
		if not ma_kat or float(mediana_uzywana) >= kat_f * 0.40:
			uzyj_mediany = true
	if uzyj_mediany and not ma_kat:
		var z_med := float(mediana_uzywana) * rng.randf_range(0.92, 1.08)
		z_med *= _mnoznik_stanu_auta(stan_deklarowany)
		if tier_tani:
			z_med *= rng.randf_range(0.78, 0.88)
		var podloga_m := float(mediana_uzywana) * (0.40 if tier_tani else 0.55)
		z_med = maxf(z_med, podloga_m)
		return _cena_lub_null(zaokraglij_cene_auta(z_med), z_med)
	if not ma_kat:
		var awaryjna: Variant = _cena_dobra("samochod", stan, rng, stan_deklarowany, przebieg_km)
		if tier_tani and _liczba(awaryjna):
			awaryjna = zaokraglij_cene_auta(float(awaryjna) * rng.randf_range(0.78, 0.92))
		return awaryjna
	var baza := kat_f
	if uzyj_mediany:
		baza = float(mediana_uzywana) * rng.randf_range(0.94, 1.06)
		baza *= clampf(0.85 + 0.15 * _mnoznik_przebiegu(przebieg_km), 0.85, 1.0)
	else:
		baza *= _mnoznik_przebiegu(przebieg_km)
	baza *= _mnoznik_stanu_auta(stan_deklarowany)
	baza *= rng.randf_range(0.96, 1.04)
	if tier_tani:
		baza *= rng.randf_range(0.78, 0.88)
	var podloga := kat_f * (0.22 if tier_tani else 0.35)
	baza = maxf(baza, podloga)
	return _cena_lub_null(zaokraglij_cene_auta(baza), baza)


func _mnoznik_stanu_auta(stan_deklarowany: int) -> float:
	## propozycja_do_poprawki. Stan 0 → 0,78, stan 100 → 1,00. Stare 0,55 zjadało katalog.
	return 0.78 + 0.22 * (float(clampi(stan_deklarowany, 0, 100)) / 100.0)


## Lokalnie zostaje odbiór. Dalej: wysyłka za 15 zł (reguła gracza, nie taryfa).
func _ustaw_odbior_drobiazgu(oferta: Dictionary, hero: Dictionary, miasto_id: String, rng: RandomNumberGenerator) -> void:
	var lokalnie := miasto_id != "" and miasto_id == str(hero.get("id", ""))
	oferta["wysylka_regula_gracza"] = true
	oferta["cena_dostawy_opis"] = "15 zł — reguła gracza, nie taryfa przewoźnika"
	if lokalnie:
		if rng.randf() < 0.5:
			oferta["sposob_odbioru"] = "oba"
			oferta["cena_dostawy_zl"] = CENA_WYSYLKI_DROBNEJ_ZL
		else:
			oferta["sposob_odbioru"] = "osobisty"
			oferta["cena_dostawy_zl"] = null
		return
	oferta["sposob_odbioru"] = "wysylka"
	oferta["cena_dostawy_zl"] = CENA_WYSYLKI_DROBNEJ_ZL


## osobisty / wysylka / oba — filtr UI tnie listę (dóbr innych niż auto).
func _losuj_sposob_odbioru(rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	if r < 0.34:
		return "osobisty"
	if r < 0.68:
		return "wysylka"
	return "oba"


## Samochód od osoby prywatnej i salon w Polsce: odbiór osobisty.
## Dostawa płatna nie ma cennika w danych — nie losujemy jej.
func _losuj_sposob_odbioru_auta(_stan: String, _rng: RandomNumberGenerator, _region_id: String = "miasto") -> String:
	return "osobisty"


func tekst_odbioru_auta(oferta: Dictionary) -> String:
	## Prywatne i salon bez opłaty: samo „odbiór osobisty”. Słowo „dostawa” tylko z ceną w nawiasie.
	var prywatna := str(oferta.get("stan", "")) == "uzywany" or not bool(oferta.get("salon", false))
	if prywatna:
		return "odbiór osobisty"
	var sposob := str(oferta.get("sposob_odbioru", "osobisty"))
	var ma_dostawe := sposob == "dostawa" or sposob == "wysylka" or sposob == "oba"
	if ma_dostawe and _liczba(oferta.get("cena_dostawy_zl")):
		var kwota := formatuj_cene_auta(oferta.get("cena_dostawy_zl"))
		if sposob == "oba":
			return "odbiór osobisty / dostawa (%s)" % kwota
		return "dostawa (%s)" % kwota
	return "odbiór osobisty"


## Bez GIS. To samo miasto: krótki odcinek. Inne województwo albo inny kraj: nie ~2 km.
## Szacunek administracyjny, propozycja_do_poprawki — nie pomiar drogi.
func odleglosc_miedzy_miejscami(skad: Dictionary, dokad: Dictionary, rng: RandomNumberGenerator) -> float:
	var id_a := str(skad.get("id", ""))
	var id_b := str(dokad.get("id", ""))
	if id_a != "" and id_a == id_b:
		return rng.randf_range(0.5, 12.0)
	if not _kraj_polska(skad) or not _kraj_polska(dokad):
		return rng.randf_range(200.0, 1600.0)
	var pow_a := str(skad.get("powiat_id", ""))
	var pow_b := str(dokad.get("powiat_id", ""))
	if pow_a != "" and pow_a == pow_b:
		return rng.randf_range(8.0, 40.0)
	var woj_a := str(skad.get("wojewodztwo", ""))
	var woj_b := str(dokad.get("wojewodztwo", ""))
	if woj_a != "" and woj_a == woj_b:
		return rng.randf_range(20.0, 180.0)
	return rng.randf_range(80.0, 640.0)


func _kraj_polska(miejsce: Dictionary) -> bool:
	var kraj := str(miejsce.get("kraj", miejsce.get("panstwo", "PL"))).strip_edges()
	return kraj == "" or kraj == "PL" or kraj == "Polska"


func odleglosc_ustalona(skad: Dictionary, dokad: Dictionary, sol: int) -> float:
	var rng := RandomNumberGenerator.new()
	var ziarno := absi(sol)
	rng.seed = ziarno if ziarno != 0 else 1
	return odleglosc_miedzy_miejscami(skad, dokad, rng)


func _bohater_do_odleglosci(miasto_oferty: Dictionary, miasto_gracza_id: String, miasto_gracza: Dictionary) -> Dictionary:
	if not miasto_gracza.is_empty() and (str(miasto_gracza.get("id", "")) != "" or str(miasto_gracza.get("nazwa", "")) != ""):
		return miasto_gracza
	if str(miasto_oferty.get("id", "")) != "" and str(miasto_oferty.get("id", "")) == miasto_gracza_id:
		return miasto_oferty
	if miasto_gracza_id != "":
		return {"id": miasto_gracza_id, "wojewodztwo": "", "powiat_id": "", "kraj": "PL"}
	return miasto_oferty


func _odleglosc_od_domu(miasto_oferty: Dictionary, miasto_gracza_id: String, miasto_gracza: Dictionary, rng: RandomNumberGenerator) -> float:
	return odleglosc_miedzy_miejscami(_bohater_do_odleglosci(miasto_oferty, miasto_gracza_id, miasto_gracza), miasto_oferty, rng)


func _wpisz_miejsce_oferty(oferta: Dictionary, miasto: Dictionary, hero: Dictionary) -> void:
	if str(miasto.get("powiat_id", "")) != "":
		oferta["powiat_id"] = str(miasto.get("powiat_id", ""))
	if str(miasto.get("wojewodztwo", "")) != "":
		oferta["wojewodztwo"] = str(miasto.get("wojewodztwo", ""))
	var kraj := str(miasto.get("kraj", miasto.get("panstwo", "PL"))).strip_edges()
	if kraj == "" or kraj == "Polska":
		kraj = "PL"
	oferta["kraj"] = kraj
	var skad := hero if not hero.is_empty() else miasto
	oferta["region_szukania"] = _region_miedzy_miejscami(skad, miasto)
	if not _liczba(oferta.get("ilosc")):
		oferta["ilosc"] = 1
	oferta["odleglosc_szacunek"] = true
	oferta["odleglosc_metoda"] = "pasmo_administracyjne_bez_gis"
	oferta["propozycja_do_poprawki_odleglosci"] = true


## Stare ogłoszenia miały losowe 1–35 km. Jednorazowo liczymy je od miasta bohatera.
func _uzgodnij_odleglosci(swiat: Dictionary, miasta: Array) -> void:
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		return
	var zrodlo := _id_ludnosci(stan, str(swiat.get("id_miejsca_pobytu", swiat.get("id_urodzenia", ""))))
	var hero := _wzbogac_jedno_miasto(_miasto_po_id(miasta, zrodlo))
	if bool(hero.get("brak_miasta", false)) or str(hero.get("id", "")) == "":
		var karta := _miejsce_bohatera(zrodlo)
		if not bool(karta.get("brak", false)) and str(karta.get("id", "")) != "":
			hero = karta
	if str(hero.get("id", "")) == "" and str(hero.get("nazwa", "")) == "":
		return
	for o in stan["oferty"]:
		if not (o is Dictionary):
			continue
		if str(o.get("odleglosc_metoda", "")) == "pasmo_administracyjne_bez_gis" and _liczba(o.get("odleglosc_km")):
			continue
		var cel := _wzbogac_jedno_miasto(_miasto_po_id(miasta, str(o.get("miasto_id", ""))))
		if bool(cel.get("brak_miasta", false)) or str(cel.get("nazwa", "")) == "?":
			if str(o.get("miasto_nazwa", "")) == "" and str(o.get("wojewodztwo", "")) == "":
				continue
			cel = {
				"id": str(o.get("miasto_id", "")),
				"nazwa": str(o.get("miasto_nazwa", "")),
				"powiat_id": str(o.get("powiat_id", "")),
				"wojewodztwo": str(o.get("wojewodztwo", "")),
				"kraj": str(o.get("kraj", "PL")),
			}
		var sol := absi(int(str(o.get("id", "o")).hash()))
		o["odleglosc_km"] = odleglosc_ustalona(hero, cel, sol if sol != 0 else 1)
		_wpisz_miejsce_oferty(o, cel, hero)
	swiat["rynek_zakupow"] = stan


func _region_miedzy_miejscami(skad: Dictionary, dokad: Dictionary) -> String:
	if str(skad.get("id", "")) != "" and str(skad.get("id", "")) == str(dokad.get("id", "")):
		return "miasto"
	if not _kraj_polska(dokad):
		return "wysylka_zagranica"
	var pow_a := str(skad.get("powiat_id", ""))
	if pow_a != "" and pow_a == str(dokad.get("powiat_id", "")):
		return "powiat"
	var woj_a := str(skad.get("wojewodztwo", ""))
	if woj_a != "" and woj_a == str(dokad.get("wojewodztwo", "")):
		return "wojewodztwo"
	return "polska"


func _cena_dobra(
	kat: String,
	stan: String,
	rng: RandomNumberGenerator,
	stan_deklarowany: int = 80,
	przebieg_km: int = 0
) -> Variant:
	var dane := wczytaj()
	if not (dane.get("dobra_cena_propozycja") is Dictionary):
		return null
	var blok: Variant = dane["dobra_cena_propozycja"].get(kat)
	if not (blok is Dictionary):
		return null
	var przedzial: Variant = blok.get(stan)
	if not (przedzial is Array) or przedzial.size() < 2:
		return null
	if not _liczba(przedzial[0]) or not _liczba(przedzial[1]):
		return null
	var baza := float(rng.randi_range(int(przedzial[0]), int(przedzial[1])))
	# Cena przy wystawieniu głównie od deklarowanego stanu (propozycja).
	var sj := _stan_jakosci_conf()
	var mno: Dictionary = sj.get("mnoznik_ceny_od_deklarowanego", {}) if sj.get("mnoznik_ceny_od_deklarowanego") is Dictionary else {}
	var baza_min := float(mno.get("baza_min", 0.55))
	var baza_max := float(mno.get("baza_max", 1.05))
	var m_stan := baza_min + (baza_max - baza_min) * (float(clampi(stan_deklarowany, 0, 100)) / 100.0)
	if stan == "nowy":
		m_stan = 1.0
	baza *= m_stan
	if kat == "samochod" and stan == "uzywany":
		baza *= _mnoznik_przebiegu(przebieg_km)
	return _cena_lub_null(zaokraglij_cene(kat, baza), baza)


func _losuj_metraz(kat: String, conf: Dictionary, rng: RandomNumberGenerator) -> int:
	var blok: Dictionary = {}
	if conf.get("metraz_m2") is Dictionary:
		var m: Variant = conf["metraz_m2"].get(kat)
		if m is Dictionary:
			blok = m
	var przedzialy: Array = blok.get("przedzialy", [[40, 60]]) if blok.get("przedzialy") is Array else [[40, 60]]
	var wagi: Array = blok.get("wagi", []) if blok.get("wagi") is Array else []
	var idx := _wazony_indeks(wagi, przedzialy.size(), rng)
	var p: Array = przedzialy[idx]
	return rng.randi_range(int(p[0]), int(p[1]))


func _losuj_pokoje(kat: String, conf: Dictionary, rng: RandomNumberGenerator, metraz: int) -> int:
	var od := 1
	var dokad := 3
	if conf.get("pokoje") is Dictionary and conf["pokoje"].get(kat) is Dictionary:
		var p: Dictionary = conf["pokoje"][kat]
		od = int(p.get("od", od))
		dokad = int(p.get("do", dokad))
	var sugerowane := clampi(int(round(float(metraz) / 22.0)), od, dokad)
	return clampi(sugerowane + rng.randi_range(-1, 1), od, dokad)


func _stan_nowego_lokum(rng: RandomNumberGenerator, wymuszony: String = "") -> String:
	## Nowe = wykończone albo stan surowy. Udział nie jest z GUS.
	if wymuszony == "surowy" or wymuszony == "nowy":
		return wymuszony
	return "surowy" if rng.randf() < 0.45 else "nowy"


func _losuj_stan(kat: String, conf: Dictionary, rng: RandomNumberGenerator) -> String:
	var lista: Array = ["do_odswiezenia"]
	if conf.get("stany") is Dictionary and conf["stany"].get(kat) is Array:
		lista = conf["stany"][kat]
	var wagi_map: Dictionary = {}
	if conf.get("stany") is Dictionary and conf["stany"].get("wagi_propozycja") is Dictionary:
		wagi_map = conf["stany"]["wagi_propozycja"]
	var wagi: Array = []
	for s in lista:
		wagi.append(float(wagi_map.get(str(s), 1)))
	return str(lista[_wazony_indeks(wagi, lista.size(), rng)])


func _losuj_odleglosc(to_gracz: bool, rng: RandomNumberGenerator, conf: Dictionary) -> float:
	var zas: Dictionary = conf.get("zasieg_szukania_km", {}) if conf.get("zasieg_szukania_km") is Dictionary else {}
	var mx := float(zas.get("max", 80))
	if to_gracz:
		return snappedf(rng.randf_range(0.5, mini(12.0, mx * 0.4)), 0.1)
	return snappedf(rng.randf_range(8.0, mx), 0.1)


func _licz_wygode(metraz: int, stan: String, odl: float, to_gracz: bool, conf: Dictionary, typ_kat: String = "mieszkanie") -> int:
	var w: Dictionary = conf.get("wygoda_0_100", {}) if conf.get("wygoda_0_100") is Dictionary else {}
	var v := float(w.get("baza", 40))
	v += maxf(0.0, float(metraz) - 40.0) * float(w.get("za_m2_powyzej_40", 0.35))
	if w.get("mnozniki_stanu") is Dictionary:
		v += float(w["mnozniki_stanu"].get(stan, 0))
	v += odl * float(w.get("za_km_od_centrum", -0.45))
	if to_gracz:
		v += float(w.get("bonus_miasto_gracza", 4))
	var clamp_arr: Array = w.get("clamp", [0, 100]) if w.get("clamp") is Array else [0, 100]
	var lo := int(clamp_arr[0]) if clamp_arr.size() >= 1 else 0
	var hi := _sufit_wygody_typu(typ_kat, conf)
	if clamp_arr.size() >= 2:
		hi = mini(hi, int(clamp_arr[1]))
	return clampi(int(round(v)), lo, hi)


func _licz_cene(kat: String, metraz: int, stan: String, to_gracz: bool, odl: float, rng: RandomNumberGenerator, conf: Dictionary) -> Variant:
	var cena_conf: Dictionary = conf.get("cena", {}) if conf.get("cena") is Dictionary else {}
	var kotwice: Dictionary = cena_conf.get("kotwice_nbp_barn", {}) if cena_conf.get("kotwice_nbp_barn") is Dictionary else {}
	var baza_m2 := 11000.0
	if kotwice.get("mieszkanie_zl_za_m2") is Dictionary:
		var m2: Dictionary = kotwice["mieszkanie_zl_za_m2"]
		if _liczba(m2.get("domyslna_kotwica_gry")):
			baza_m2 = float(m2["domyslna_kotwica_gry"])
	if kat == "dom":
		if kotwice.get("dom_zl_za_m2") != null and _liczba(kotwice.get("dom_zl_za_m2")):
			baza_m2 = float(kotwice["dom_zl_za_m2"])
		elif kotwice.get("dom_mnoznik_względem_mieszkania") is Dictionary:
			var mn: Dictionary = kotwice["dom_mnoznik_względem_mieszkania"]
			if _liczba(mn.get("wartosc")):
				baza_m2 *= float(mn["wartosc"])
	var mno_stan := 1.0
	if cena_conf.get("mnozniki_stanu") is Dictionary:
		mno_stan = float(cena_conf["mnozniki_stanu"].get(stan, 1.0))
	var mno_lok := 1.0
	if cena_conf.get("mnozniki_lokalizacji") is Dictionary:
		var ml: Dictionary = cena_conf["mnozniki_lokalizacji"]
		if to_gracz:
			mno_lok = float(ml.get("miasto_gracza_centrum" if odl < 4.0 else "miasto_gracza_obrzeza", 1.0))
		else:
			mno_lok = float(ml.get("inne_miasto", 0.9))
	var szum := rng.randf_range(0.92, 1.08)
	var surowa := float(metraz) * baza_m2 * mno_stan * mno_lok * szum
	return _cena_lub_null(zaokraglij_cene(kat, surowa), surowa)


func _limit_ofert(conf: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var lim: Dictionary = conf.get("limit_ofert_na_miasto", {}) if conf.get("limit_ofert_na_miasto") is Dictionary else {}
	var od := int(lim.get("od", 3))
	var dokad := int(lim.get("do", 6))
	return Vector2i(od, dokad)


func _wybierz_miasta(miasta: Array, miasto_gracza_id: String, rng: RandomNumberGenerator, ile: int) -> Array:
	var out: Array = []
	var reszta: Array = []
	for m in miasta:
		if not (m is Dictionary):
			continue
		if str(m.get("id", "")) == miasto_gracza_id and miasto_gracza_id != "":
			out.append(m)
		else:
			reszta.append(m)
	while out.size() < ile and not reszta.is_empty():
		var i := rng.randi_range(0, reszta.size() - 1)
		out.append(reszta[i])
		reszta.remove_at(i)
	# Brak id nie wskakuje na pierwsze miasto z alfabetu (Aleksandrów Kujawski).
	if out.is_empty() and miasto_gracza_id == "" and not miasta.is_empty() and miasta[0] is Dictionary:
		out.append(miasta[0])
	return out


func _przytnij_per_miasto(oferty: Array, max_na_miasto: int, rng: RandomNumberGenerator) -> Array:
	var po: Dictionary = {}
	for o in oferty:
		if not (o is Dictionary):
			continue
		var mid := str(o.get("miasto_id", ""))
		if not po.has(mid):
			po[mid] = []
		po[mid].append(o)
	var out: Array = []
	for mid in po.keys():
		var lista: Array = po[mid]
		while lista.size() > max_na_miasto:
			lista.remove_at(rng.randi_range(0, lista.size() - 1))
		out.append_array(lista)
	return out


func _nieruchomosci_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("nieruchomosci") is Dictionary:
		return dane["nieruchomosci"]
	return {}


func _efekt_wygody_conf() -> Dictionary:
	var conf := _nieruchomosci_conf()
	if conf.get("wygoda_efekt_zadowolenia_tydzien") is Dictionary:
		return conf["wygoda_efekt_zadowolenia_tydzien"]
	return {}


func _dryf_conf() -> Dictionary:
	if _dryf is Dictionary:
		return _dryf
	if not FileAccess.file_exists(PLIK_DRYFU):
		return {}
	var plik := FileAccess.open(PLIK_DRYFU, FileAccess.READ)
	if plik == null:
		return {}
	var surowe: Variant = JSON.parse_string(plik.get_as_text())
	if surowe is Dictionary:
		_dryf = surowe
		return surowe
	return {}


func _wazony_indeks(wagi: Array, n: int, rng: RandomNumberGenerator) -> int:
	if n <= 0:
		return 0
	if wagi.size() != n:
		return rng.randi_range(0, n - 1)
	var suma := 0.0
	for w in wagi:
		suma += float(w)
	if suma <= 0.0:
		return rng.randi_range(0, n - 1)
	var r := rng.randf() * suma
	var acc := 0.0
	for i in n:
		acc += float(wagi[i])
		if r <= acc:
			return i
	return n - 1


func _wczytaj_manifest() -> Variant:
	if _manifest != null:
		return _manifest
	if not FileAccess.file_exists(PLIK_OBRAZKOW):
		return null
	var plik := FileAccess.open(PLIK_OBRAZKOW, FileAccess.READ)
	if plik == null:
		return null
	_manifest = JSON.parse_string(plik.get_as_text())
	return _manifest


func _liczba(v: Variant) -> bool:
	return v is int or v is float


func _cena_lub_null(zaokraglona: int, surowa: Variant) -> Variant:
	if not _liczba(surowa):
		return null
	if zaokraglona < 0:
		return int(round(float(surowa)))
	return zaokraglona


func _krok_zaokraglenia(kategoria: String) -> int:
	var dane := wczytaj()
	var conf: Dictionary = dane.get("zaokraglanie_cen", {}) if dane.get("zaokraglanie_cen") is Dictionary else {}
	var kroki: Dictionary = conf.get("kroki_zl", {}) if conf.get("kroki_zl") is Dictionary else {}
	if kroki.has(kategoria) and _liczba(kroki.get(kategoria)):
		return maxi(1, int(kroki[kategoria]))
	return maxi(1, int(conf.get("domyslny_krok_zl", 10)))


func _stan_jakosci_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("stan_jakosci") is Dictionary:
		return dane["stan_jakosci"]
	return {}


func _przebieg_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("przebieg_auta") is Dictionary:
		return dane["przebieg_auta"]
	return {}


func _ocena_stanu_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("ocena_stanu") is Dictionary:
		return dane["ocena_stanu"]
	return {}


func _targowanie_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("targowanie") is Dictionary:
		return dane["targowanie"]
	return {}


func _losuj_stany_jakosci(stan: String, rng: RandomNumberGenerator) -> Dictionary:
	var conf := _stan_jakosci_conf()
	var blok: Dictionary = {}
	if stan == "nowy":
		blok = conf.get("nowy", {}) if conf.get("nowy") is Dictionary else {}
	else:
		blok = conf.get("uzywany", {}) if conf.get("uzywany") is Dictionary else {}
	var od_v := int(blok.get("rzeczywisty_od", 40 if stan == "uzywany" else 95))
	var do_v := int(blok.get("rzeczywisty_do", 90 if stan == "uzywany" else 100))
	if do_v < od_v:
		var t := od_v
		od_v = do_v
		do_v = t
	var rzeczywisty := clampi(rng.randi_range(od_v, do_v), 0, 100)
	var deklarowany := rzeczywisty
	var klamstwo := false
	var szansa := float(blok.get("kłamstwo_szansa", blok.get("klamstwo_szansa", 0.0)))
	if stan == "uzywany" and rng.randf() < szansa:
		var d_od := int(blok.get("kłamstwo_delta_od", blok.get("klamstwo_delta_od", 5)))
		var d_do := int(blok.get("kłamstwo_delta_do", blok.get("klamstwo_delta_do", 20)))
		deklarowany = clampi(rzeczywisty + rng.randi_range(d_od, d_do), 0, 100)
		klamstwo = deklarowany > rzeczywisty
	return {
		"stan_rzeczywisty": rzeczywisty,
		"stan_deklarowany": deklarowany,
		"stan_klamstwo": klamstwo,
	}


func _losuj_przebieg_km(kat: String, stan: String, rng: RandomNumberGenerator) -> int:
	if kat != "samochod":
		return 0
	var conf := _przebieg_conf()
	if stan == "nowy":
		return int(conf.get("nowy_km", 0))
	var uz: Dictionary = conf.get("uzywany_km", {}) if conf.get("uzywany_km") is Dictionary else {}
	var od_v := int(uz.get("od", 25000))
	var do_v := int(uz.get("do", 280000))
	if do_v < od_v:
		var t := od_v
		od_v = do_v
		do_v = t
	return rng.randi_range(od_v, do_v)


func _mnoznik_przebiegu(przebieg_km: int) -> float:
	var conf := _przebieg_conf()
	var w: Dictionary = conf.get("wplyw_na_cene", {}) if conf.get("wplyw_na_cene") is Dictionary else {}
	var bazowe := float(w.get("bazowe_km", 200000))
	if bazowe <= 0.0:
		return 1.0
	var spadek := float(w.get("spadek_przy_bazie", 0.45))
	var min_m := float(w.get("min_mnoznik", 0.55))
	return clampf(1.0 - (float(przebieg_km) / bazowe) * spadek, min_m, 1.0)


func _mozna_oceniac_osobiscie(oferta: Dictionary) -> bool:
	## Zachowane dla starych wywołań — auta ocenialne też przy wysyłce (tryb po dostawie).
	return tryb_oceny_stanu(oferta) != ""


func _auta_conf() -> Dictionary:
	var dane := wczytaj()
	if dane.get("auta") is Dictionary:
		return dane["auta"]
	return {}


func _wylosuj_ile_aut_dla_miasta(miasto: Dictionary, ziarno: int, _miasto_gracza: bool) -> int:
	## baza = ludnosc/1500, potem ±30% (propozycja_do_poprawki). Bez sztywnego 10–18.
	var baza := baza_ogloszen_aut(_ludnosc_miasta(miasto))
	var rozb := float(_auta_conf().get("rozbieznosc_ilosciowa", 0.30))
	var pasmo := pasmo_ogloszen_aut(baza, rozb)
	var rng := RandomNumberGenerator.new()
	rng.seed = ziarno
	return rng.randi_range(pasmo.x, pasmo.y)


func _ludnosc_miasta(miasto: Dictionary) -> int:
	if _liczba(miasto.get("ludnosc")):
		return maxi(0, int(miasto["ludnosc"]))
	if _liczba(miasto.get("liczba_mieszkancow")):
		return maxi(0, int(miasto["liczba_mieszkancow"]))
	return 0


func _miasto_po_id(miasta: Array, miasto_id: String) -> Dictionary:
	## Reszta powiatu (np. „chrzanowski”) nie jest miastem. Kotwica = siedziba, nie pierwsze miasto z alfabetu.
	var szukany := miasto_id
	var siedziba := _id_siedziby_jesli_reszta(miasto_id)
	if siedziba != "":
		szukany = siedziba
	if szukany != "":
		for m in miasta:
			if m is Dictionary and str(m.get("id", "")) == szukany:
				return m
		var z_pliku := _czytaj_miasto_z_danych(szukany)
		if not z_pliku.is_empty():
			return z_pliku
	return {"id": szukany, "nazwa": "?", "ludnosc": 0, "brak_miasta": true}


func _pula_aut_zgodna(stan: Dictionary, miasto: Dictionary) -> bool:
	var mid := str(miasto.get("id", ""))
	if mid == "" or bool(miasto.get("brak_miasta", false)):
		return false
	if str(stan.get("miasto_gracza_id", "")) != mid:
		return false
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var lokalne := 0
	for o in oferty:
		if not (o is Dictionary) or str(o.get("kategoria", "")) != "samochod":
			continue
		if str(o.get("stan", "")) == "uzywany":
			if str(o.get("sposob_odbioru", "")) != "osobisty":
				return false
			var reg := str(o.get("region_szukania", "miasto"))
			if reg == "" or reg == "miasto":
				if str(o.get("miasto_id", "")) != mid:
					return false
				lokalne += 1
			if str(o.get("kraj", "PL")) != "PL" and float(o.get("odleglosc_km", 0)) < 80.0:
				return false
		else:
			if bool(o.get("salon", false)):
				if not _jest_salon(str(o.get("marka", "")), str(o.get("miasto_nazwa", ""))):
					return false
			elif not bool(o.get("sprowadzenie", false)) and not bool(o.get("import", false)):
				return false
			if str(o.get("sposob_odbioru", "")) != "osobisty" and not _liczba(o.get("cena_dostawy_zl")):
				return false
	return lokalne >= 1


func miasta_salonu_marki(marka: String, miasta: Array) -> Array:
	var nazwy := _nazwy_salonow_marki(marka)
	var out: Array = []
	var widziane := {}
	for m in miasta:
		if not (m is Dictionary):
			continue
		var nazwa := str(m.get("nazwa", ""))
		if nazwa == "" or not nazwy.has(nazwa) or widziane.has(nazwa):
			continue
		widziane[nazwa] = true
		out.append(m)
	return out


func _jest_salon(marka: String, miasto_nazwa: String) -> bool:
	return _nazwy_salonow_marki(marka).has(miasto_nazwa)


func _nazwy_salonow_marki(marka: String) -> Dictionary:
	var dane := _salony()
	var out := {}
	var woj: Variant = dane.get("wojewodztwa", {})
	if not (woj is Dictionary):
		return out
	for w in (woj as Dictionary).keys():
		var blok: Variant = (woj as Dictionary)[w]
		if not (blok is Dictionary):
			continue
		var lista: Variant = (blok as Dictionary).get(marka, [])
		if not (lista is Array):
			continue
		for n in lista:
			var nazwa := str(n)
			if nazwa != "":
				out[nazwa] = true
	return out


func _salony() -> Dictionary:
	if _salony_danych is Dictionary:
		return _salony_danych
	var surowe: Variant = _czytaj_json_plik(PLIK_SALONY)
	if surowe is Dictionary:
		_salony_danych = surowe
		return surowe
	_salony_danych = {}
	return {}


func _id_siedziby_jesli_reszta(miasto_id: String) -> String:
	if miasto_id == "":
		return ""
	var sciezka := "res://świat/polska/reszta_powiatu/%s.json" % miasto_id
	if not FileAccess.file_exists(sciezka):
		return ""
	var dane: Variant = _czytaj_json_plik(sciezka)
	if dane is Dictionary:
		return str(dane.get("siedziba_id", ""))
	return ""


func _czytaj_miasto_z_danych(miasto_id: String) -> Dictionary:
	if miasto_id == "":
		return {}
	var sciezka := "res://świat/polska/miasta/%s.json" % miasto_id
	var dane: Variant = _czytaj_json_plik(sciezka)
	if not (dane is Dictionary):
		return {}
	var kopia: Dictionary = (dane as Dictionary).duplicate(true)
	if not _liczba(kopia.get("ludnosc")) and _liczba(kopia.get("liczba_mieszkancow")):
		kopia["ludnosc"] = int(kopia["liczba_mieszkancow"])
	kopia["id"] = str(kopia.get("id", miasto_id))
	return kopia


func _predkosc_max_z_rekordu(rekord: Dictionary, _naped: String) -> Dictionary:
	## Bez zmyślania: brak w katalogu → wartosc null (UI nie pokazuje fałszywego vmax).
	if _liczba(rekord.get("predkosc_max_kmh")):
		return {
			"wartosc": clampi(int(rekord["predkosc_max_kmh"]), 80, 350),
			"propozycja": bool(rekord.get("predkosc_max_propozycja", false)),
			"zrodlo": str(rekord.get("predkosc_max_zrodlo", rekord.get("zrodlo", ""))),
		}
	return {
		"wartosc": null,
		"propozycja": false,
		"zrodlo": "",
	}


## Suma vmax_delta + flaga nie_jezdzi z listy id usterek.
func efekty_usterek_vmax(usterki_ids: Array) -> Dictionary:
	var out := {"vmax_delta": 0, "nie_jezdzi": false}
	if usterki_ids.is_empty():
		return out
	var kat := usterki_katalog()
	var po_id := {}
	for u in (kat.get("usterki", []) if kat.get("usterki") is Array else []):
		if u is Dictionary:
			po_id[str(u.get("id", ""))] = u
	for uid_v in usterki_ids:
		var meta: Variant = po_id.get(str(uid_v), {})
		if not (meta is Dictionary):
			continue
		if bool(meta.get("nie_jezdzi", false)):
			out["nie_jezdzi"] = true
		if _liczba(meta.get("vmax_delta")):
			out["vmax_delta"] = int(out["vmax_delta"]) + int(meta["vmax_delta"])
	return out


## Tekst UI: „180 (−20)” albo „180”. znane_usterki=Array → delta tylko z nich (rynek);
## null → użyj auto.vmax_delta (majątek / pełna prawda).
func tekst_vmax_oferty(auto: Dictionary, znane_usterki: Variant = null) -> String:
	var katalog: Variant = auto.get("vmax_katalog", auto.get("predkosc_max_katalog_kmh"))
	if not _liczba(katalog) and _liczba(auto.get("predkosc_max_kmh")) and int(auto.get("vmax_delta", 0)) == 0:
		katalog = auto.get("predkosc_max_kmh")
	if not _liczba(katalog):
		return ""
	var delta := 0
	if znane_usterki is Array:
		delta = int(efekty_usterek_vmax(znane_usterki).get("vmax_delta", 0))
	elif _liczba(auto.get("vmax_delta")):
		delta = int(auto["vmax_delta"])
	var baza := int(katalog)
	if delta == 0:
		var t := "%d" % baza
		if bool(auto.get("predkosc_max_propozycja", false)):
			t += " (propozycja)"
		return t
	var znak := ("+%d" % delta) if delta > 0 else ("−%d" % absi(delta))
	return "%d (%s)" % [baza, znak]


func kotwica_naprawy_silnika(auto: Dictionary) -> Dictionary:
	return _kotwica_naprawy_silnika(auto)


func predkosc_efektywna_auta(auto: Dictionary) -> Variant:
	if bool(auto.get("nie_jezdzi", false)):
		return null
	if _liczba(auto.get("predkosc_max_kmh")):
		return clampi(int(auto["predkosc_max_kmh"]), 40, 350)
	if _liczba(auto.get("vmax_katalog")):
		var d := int(auto.get("vmax_delta", 0))
		return clampi(int(auto["vmax_katalog"]) + d, 40, 350)
	return null


func _naloz_efekty_vmax_na_oferte(oferta: Dictionary, usterki_ids: Array, vmax_meta: Dictionary) -> void:
	var katalog: Variant = vmax_meta.get("wartosc")
	oferta["vmax_katalog"] = katalog
	oferta["predkosc_max_propozycja"] = bool(vmax_meta.get("propozycja", false))
	oferta["predkosc_max_zrodlo"] = str(vmax_meta.get("zrodlo", ""))
	var ef := efekty_usterek_vmax(usterki_ids)
	oferta["vmax_delta"] = int(ef.get("vmax_delta", 0))
	oferta["nie_jezdzi"] = bool(ef.get("nie_jezdzi", false))
	if _liczba(katalog):
		oferta["predkosc_max_kmh"] = clampi(int(katalog) + int(oferta["vmax_delta"]), 40, 350)
	else:
		oferta["predkosc_max_kmh"] = null
	if bool(oferta["nie_jezdzi"]):
		oferta["do_naprawy"] = true


func _losuj_region_oferty_auta(rng: RandomNumberGenerator, conf: Dictionary, bez_miasta: bool = false) -> Dictionary:
	# Wagi: więcej lokalnych, mniej zagranicy. Hierarchia: miasto→powiat→województwo→PL→sąsiedzi→zagranica.
	var wagi := {
		"miasto": 0.34,
		"powiat": 0.22,
		"wojewodztwo": 0.16,
		"polska": 0.14,
		"sasiedzi": 0.09,
		"wysylka_zagranica": 0.05,
	}
	if bez_miasta:
		wagi = {
			"powiat": 0.32,
			"wojewodztwo": 0.26,
			"polska": 0.22,
			"sasiedzi": 0.13,
			"wysylka_zagranica": 0.07,
		}
	var suma := 0.0
	for k in wagi.keys():
		suma += float(wagi[k])
	var r := rng.randf() * maxf(0.0001, suma)
	var akum := 0.0
	var wybrany := "powiat" if bez_miasta else "miasto"
	for k in wagi.keys():
		akum += float(wagi[k])
		if r <= akum:
			wybrany = str(k)
			break
	return _region_oferty_auta_po_id(wybrany, rng, conf)


func _region_oferty_auta_po_id(poziom_id: String, rng: RandomNumberGenerator, conf: Dictionary) -> Dictionary:
	var poziomy: Array = []
	if conf.get("zasieg_szukania_poziomy") is Array:
		poziomy = conf["zasieg_szukania_poziomy"]
	elif _nieruchomosci_conf().get("zasieg_szukania_poziomy") is Array:
		poziomy = _nieruchomosci_conf()["zasieg_szukania_poziomy"]
	var min_km := 1.0
	var max_km := 35.0
	match poziom_id:
		"powiat":
			min_km = 5.0
			max_km = 80.0
		"wojewodztwo":
			min_km = 15.0
			max_km = 250.0
		"polska":
			min_km = 20.0
			max_km = 800.0
		"sasiedzi":
			min_km = 80.0
			max_km = 1500.0
		"wysylka_zagranica":
			min_km = 200.0
			max_km = 2500.0
		_:
			min_km = 1.0
			max_km = 35.0
	for p in poziomy:
		if p is Dictionary and str(p.get("id", "")) == poziom_id:
			min_km = float(p.get("min_km", min_km))
			max_km = float(p.get("max_km", max_km))
			break
	var kraj := "PL"
	if poziom_id == "sasiedzi":
		var kraje := ["DE", "CZ", "SK", "LT", "UA"]
		kraj = str(kraje[rng.randi_range(0, kraje.size() - 1)])
	elif poziom_id == "wysylka_zagranica":
		var kraje2 := ["DE", "NL", "BE", "FR", "IT", "ES"]
		kraj = str(kraje2[rng.randi_range(0, kraje2.size() - 1)])
	return {
		"id": poziom_id if poziom_id != "" else "miasto",
		"kraj": kraj,
		"odleglosc_km": rng.randf_range(min_km, maxf(min_km + 1.0, max_km)),
	}


func _miasto_dla_regionu_auta(
	region_id: String,
	miasto_gracza: Dictionary,
	miasta: Array,
	rng: RandomNumberGenerator,
	kraj: String = "PL"
) -> Dictionary:
	if region_id == "miasto" or miasta.is_empty():
		return miasto_gracza
	if region_id == "sasiedzi" or region_id == "wysylka_zagranica":
		var nazwa_k := kraj if kraj != "" else "DE"
		return {
			"id": "zagranica_%s" % nazwa_k.to_lower(),
			"nazwa": nazwa_k,
			"powiat_id": "",
			"wojewodztwo": "",
			"kraj": nazwa_k,
			"ludnosc": 0,
		}
	var pid := str(miasto_gracza.get("powiat_id", ""))
	var woj := str(miasto_gracza.get("wojewodztwo", ""))
	var kandydaci: Array = []
	for m in miasta:
		if not (m is Dictionary):
			continue
		match region_id:
			"powiat":
				if pid != "" and str(m.get("powiat_id", "")) == pid:
					kandydaci.append(m)
			"wojewodztwo":
				if woj != "" and str(m.get("wojewodztwo", "")) == woj:
					kandydaci.append(m)
			"polska":
				kandydaci.append(m)
			_:
				kandydaci.append(m)
	if kandydaci.is_empty():
		return miasto_gracza
	return kandydaci[rng.randi_range(0, kandydaci.size() - 1)]


func usterki_katalog() -> Dictionary:
	if _usterki_aut is Dictionary:
		return _usterki_aut
	var surowe: Variant = _czytaj_json_plik(PLIK_USTERKI_AUT)
	if surowe is Dictionary:
		_usterki_aut = surowe
		return surowe
	_usterki_aut = {"usterki": []}
	return _usterki_aut


func usterki_dobr_katalog() -> Dictionary:
	if _usterki_dobr is Dictionary:
		return _usterki_dobr
	var surowe: Variant = _czytaj_json_plik(PLIK_USTERKI_DOBR)
	if surowe is Dictionary:
		_usterki_dobr = surowe
		return surowe
	_usterki_dobr = {"kategorie": {}}
	return _usterki_dobr


## Lista meta-usterek dla kategorii oferty (auta = usterki_aut; reszta = usterki_dobr).
func lista_usterek_meta(kategoria: String, segment: String = "") -> Array:
	if kategoria == "samochod":
		var kat_a := usterki_katalog()
		return kat_a.get("usterki", []) if kat_a.get("usterki") is Array else []
	var root := usterki_dobr_katalog()
	var kategorie: Dictionary = root.get("kategorie", {}) if root.get("kategorie") is Dictionary else {}
	var blok: Variant = kategorie.get(kategoria, {})
	if not (blok is Dictionary):
		return []
	var lista: Array = blok.get("usterki", []) if blok.get("usterki") is Array else []
	if kategoria != "sprzet" or segment == "":
		return lista
	var przefiltrowane: Array = []
	for u in lista:
		if not (u is Dictionary):
			continue
		var pods: Array = u.get("podkategorie", []) if u.get("podkategorie") is Array else []
		if pods.is_empty() or pods.has(segment):
			przefiltrowane.append(u)
	return przefiltrowane


func nazwa_usterki(uid: String, kategoria: String = "", segment: String = "") -> String:
	var meta := _meta_usterki(uid, kategoria, segment)
	var n := str(meta.get("nazwa", ""))
	return n if n != "" else uid


func nazwy_usterek(ids: Array, kategoria: String = "", segment: String = "") -> Array:
	var out: Array = []
	for uid_v in ids:
		out.append(nazwa_usterki(str(uid_v), kategoria, segment))
	return out


func _losuj_usterki_auta(stan: String, rng: RandomNumberGenerator, tier_tani: bool = false) -> Dictionary:
	return _losuj_usterki_z_listy(lista_usterek_meta("samochod"), stan, rng, tier_tani)


func _losuj_usterki_dobra(kategoria: String, stan: String, rng: RandomNumberGenerator, segment: String = "") -> Dictionary:
	var puste := {"rzeczywiste": [], "deklarowane": [], "ukryte": [], "ma_szacunek": false}
	## Usterki tylko na używanym i uszkodzonym. Nowe i czyste używane zostają bez listy.
	if stan != "uzywany":
		return puste
	if rng.randf() > SZANSA_USZKODZENIA_UZYWANEGO:
		return puste
	return _losuj_usterki_z_listy(lista_usterek_meta(kategoria, segment), stan, rng, false)


func _losuj_usterki_z_listy(lista: Array, stan: String, rng: RandomNumberGenerator, tier_tani: bool = false) -> Dictionary:
	var out := {"rzeczywiste": [], "deklarowane": [], "ukryte": [], "ma_szacunek": false}
	if stan != "uzywany":
		return out
	for u in lista:
		if not (u is Dictionary):
			continue
		var szansa := float(u.get("szansa_w_uzywanym", 0.1))
		if tier_tani:
			szansa = minf(0.95, szansa * 1.6)
		if rng.randf() > szansa:
			continue
		var uid := str(u.get("id", ""))
		if uid == "":
			continue
		out["rzeczywiste"].append(uid)
		if bool(u.get("szacunek", false)):
			out["ma_szacunek"] = true
		var ukryj_sz := float(u.get("szansa_ukrycia", 0.3))
		if bool(u.get("ukrywane_preferencyjnie", false)):
			ukryj_sz = maxf(ukryj_sz, 0.8)
		# Sprzedawca: część wpisze, część nic; pozalewowe / zalanie często ukryte.
		if rng.randf() < ukryj_sz:
			out["ukryte"].append(uid)
		else:
			out["deklarowane"].append(uid)
	return out


## Rabat ceny wywoławczej od deklarowanych usterek (ukryte nie obniżają ogłoszenia). Propozycja.
func _naloz_rabat_usterek_na_cene(oferta: Dictionary) -> void:
	if str(oferta.get("stan", "")) != "uzywany":
		return
	if not _liczba(oferta.get("cena_zl")):
		return
	var dek: Array = oferta.get("usterki_deklarowane", []) if oferta.get("usterki_deklarowane") is Array else []
	if dek.is_empty():
		return
	var kat := str(oferta.get("kategoria", ""))
	var segment := str(oferta.get("segment", ""))
	var rabat := rabat_ceny_z_usterek(dek, kat, segment)
	if rabat <= 0.0:
		return
	var przed := float(oferta["cena_zl"])
	var po := przed * (1.0 - rabat)
	var zaokr := zaokraglij_cene(kat, po)
	oferta["cena_zl"] = zaokr
	oferta["cena_wyjsciowa"] = zaokr
	oferta["rabat_usterek"] = rabat
	oferta["cena_przed_rabatem_usterek"] = zaokraglij_cene(kat, przed)


func rabat_ceny_z_usterek(usterki_ids: Array, kategoria: String = "", segment: String = "") -> float:
	if usterki_ids.is_empty():
		return 0.0
	var conf: Dictionary = {}
	var root := usterki_dobr_katalog()
	if root.get("wplyw_na_cene") is Dictionary:
		conf = root["wplyw_na_cene"]
	var per := float(conf.get("procent_per_powaga", 0.035))
	var max_r := float(conf.get("max_rabat", 0.42))
	var suma_powagi := 0
	for uid_v in usterki_ids:
		var meta := _meta_usterki(str(uid_v), kategoria, segment)
		suma_powagi += int(meta.get("powaga", 1))
	return clampf(float(suma_powagi) * per, 0.0, max_r)


## Wykrywa ukryte usterki przy ocenie (odbiór osobisty / ekspert). Auta: znajomość pojazdów + mechanik.
func wykryj_usterki(swiat: Dictionary, oferta: Dictionary, z_ekspertem: bool = false) -> Array:
	var ukryte: Array = oferta.get("usterki_ukryte", []) if oferta.get("usterki_ukryte") is Array else []
	if ukryte.is_empty():
		return []
	var juz: Array = oferta.get("usterki_wykryte", []) if oferta.get("usterki_wykryte") is Array else []
	var kat_oferty := str(oferta.get("kategoria", ""))
	var segment := str(oferta.get("segment", ""))
	var jest_auto := kat_oferty == "samochod"
	var wyk: Dictionary = {}
	if jest_auto:
		var kat_a := usterki_katalog()
		wyk = kat_a.get("wykrywanie", {}) if kat_a.get("wykrywanie") is Dictionary else {}
	else:
		var root := usterki_dobr_katalog()
		wyk = root.get("wykrywanie", {}) if root.get("wykrywanie") is Dictionary else {}
	var intel := _inteligencja_logiczna_bohatera(swiat)
	var internet := bool(swiat.get("bohater", {}).get("dostep_do_internetu", true)) if swiat.get("bohater") is Dictionary else true
	var dobre_wyniki := _dobre_wyniki_szkoly(swiat)
	var baza := float(wyk.get("baza", 0.18 if not jest_auto else 0.12))
	if jest_auto:
		var znaj := _poziom_znajomosci_pojazdow(swiat)
		baza += znaj * float(wyk.get("waga_znajomosci_0_100", 0.006))
		if _ma_szkole_mechanik(swiat):
			baza += float(wyk.get("bonus_szkola_mechanik", 0.22))
	baza += intel * float(wyk.get("waga_inteligencji_logicznej_0_100", 0.0035 if jest_auto else 0.0045))
	if internet:
		baza += float(wyk.get("bonus_internet", 0.08 if jest_auto else 0.1))
	if z_ekspertem:
		baza += float(wyk.get("bonus_ekspert", 0.28 if jest_auto else 0.32))
	if dobre_wyniki:
		baza += float(wyk.get("bonus_dobre_wyniki_szkoly", 0.12 if jest_auto else 0.08))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var nowe: Array = []
	var po_id := {}
	for u in lista_usterek_meta(kat_oferty, segment):
		if u is Dictionary:
			po_id[str(u.get("id", ""))] = u
	for uid_v in ukryte:
		var uid := str(uid_v)
		if juz.has(uid) or nowe.has(uid):
			continue
		var szansa := clampf(baza, 0.0, 0.98)
		var meta: Variant = po_id.get(uid, {})
		if meta is Dictionary:
			var mid := str(meta.get("id", ""))
			if mid == "pozalewowe" or mid == "po_zalaniu":
				szansa *= float(wyk.get("pozalewowe_mnoznik_trudnosci", 0.65 if jest_auto else 0.7))
		if rng.randf() <= szansa:
			nowe.append(uid)
	if not nowe.is_empty():
		for n in nowe:
			juz.append(n)
		oferta["usterki_wykryte"] = juz
		_zapisz_oferte(swiat, oferta)
	return nowe


func _poziom_znajomosci_pojazdow(swiat: Dictionary) -> float:
	var boh: Variant = swiat.get("bohater", {})
	if boh is Dictionary:
		var z: Variant = boh.get("znajomosc_pojazdow", {})
		if z is Dictionary and _liczba(z.get("poziom_0_100")):
			return float(z["poziom_0_100"])
		if z is Dictionary:
			var zp = load("res://scripts/znajomosc_pojazdow.gd").new()
			zp.wczytaj_ze_stanu(z)
			return float(zp.poziom_0_100())
	return 0.0


func _inteligencja_logiczna_bohatera(swiat: Dictionary) -> float:
	var boh: Variant = swiat.get("bohater", {})
	if not (boh is Dictionary):
		return 50.0
	for klucz in ["inteligencja_logiczna", "int_logiczna", "inteligencja"]:
		if _liczba(boh.get(klucz)):
			return float(boh[klucz])
	var cechy: Variant = boh.get("cechy", {})
	if cechy is Dictionary and _liczba(cechy.get("inteligencja_logiczna")):
		return float(cechy["inteligencja_logiczna"])
	return 50.0


func _ma_szkole_mechanik(swiat: Dictionary) -> bool:
	var kat := usterki_katalog()
	var wyk: Dictionary = kat.get("wykrywanie", {}) if kat.get("wykrywanie") is Dictionary else {}
	var ids: Array = wyk.get("cechy_szkoly_mechanik", []) if wyk.get("cechy_szkoly_mechanik") is Array else []
	var boh: Variant = swiat.get("bohater", {})
	if not (boh is Dictionary):
		return false
	var edukacja: Variant = boh.get("edukacja", [])
	if edukacja is Array:
		for e in edukacja:
			var eid := str(e.get("id", e)) if not (e is String) else str(e)
			if ids.has(eid) or eid.findn("mechanik") >= 0:
				return true
	var szkola := str(boh.get("szkola", boh.get("szkola_branzowa", "")))
	return szkola.findn("mechanik") >= 0


func _dobre_wyniki_szkoly(swiat: Dictionary) -> bool:
	var boh: Variant = swiat.get("bohater", {})
	if not (boh is Dictionary):
		return false
	if bool(boh.get("dobre_wyniki_szkoly", false)):
		return true
	if _liczba(boh.get("srednia_ocen")) and float(boh["srednia_ocen"]) >= 4.0:
		return true
	return false


## Filtr zasięgu: miasto → powiat → województwo → PL → sąsiedzi → wysyłka.
## Powiat/województwo z pól oferty (ze świat/polska przy miastach) vs miejsce gracza.
func oferta_w_zasiegu_poziomu(oferta: Dictionary, poziom_id: String, swiat: Dictionary = {}) -> bool:
	if poziom_id == "" or poziom_id == "wysylka_zagranica":
		return true
	var reg := str(oferta.get("region_szukania", "miasto"))
	var kraj := str(oferta.get("kraj", "PL"))
	var miejsce := _miejsce_gracza_z_swiata(swiat)
	var mid_g := str(miejsce.get("id", ""))
	if mid_g == "" and swiat.get("rynek_zakupow") is Dictionary:
		mid_g = str(swiat["rynek_zakupow"].get("miasto_gracza_id", ""))
	var pid_g := str(miejsce.get("powiat_id", ""))
	var woj_g := str(miejsce.get("wojewodztwo", ""))
	var mid_o := str(oferta.get("miasto_id", ""))
	var pid_o := str(oferta.get("powiat_id", ""))
	var woj_o := str(oferta.get("wojewodztwo", ""))
	var to_gracz := bool(oferta.get("miasto_gracza", false)) or (mid_g != "" and mid_o == mid_g)
	var ten_sam_powiat := pid_g != "" and pid_o == pid_g
	var to_samo_woj := woj_g != "" and woj_o == woj_g
	var sasiedzi_kraje := ["DE", "CZ", "SK", "LT", "UA", "PL"]
	var kraj_pl := kraj == "PL" or kraj == "Polska" or (kraj == "" and reg != "sasiedzi" and reg != "wysylka_zagranica")
	match poziom_id:
		"miasto":
			return to_gracz
		"powiat":
			return to_gracz or ten_sam_powiat
		"wojewodztwo":
			return to_gracz or ten_sam_powiat or to_samo_woj
		"polska":
			return kraj_pl or to_gracz or ten_sam_powiat or to_samo_woj
		"sasiedzi":
			if kraj in sasiedzi_kraje or to_gracz or ten_sam_powiat or to_samo_woj:
				return true
			return reg != "wysylka_zagranica"
		_:
			return true


func _miejsce_gracza_z_swiata(swiat: Dictionary) -> Dictionary:
	if swiat.is_empty():
		return {}
	var boh: Variant = swiat.get("bohater", {})
	if boh is Dictionary and boh.get("miejsce") is Dictionary:
		var miejsce: Dictionary = boh["miejsce"]
		return _wzbogac_jedno_miasto(_miasto_po_id([miejsce], str(miejsce.get("id", ""))))
	var mid := ""
	if swiat.get("rynek_zakupow") is Dictionary:
		mid = str(swiat["rynek_zakupow"].get("miasto_gracza_id", ""))
	if mid == "":
		mid = str(swiat.get("id_miejsca_pobytu", swiat.get("id_urodzenia", "")))
	if mid == "":
		return {}
	return _wzbogac_jedno_miasto(_miasto_po_id([], mid))


func _indeks_miast() -> Dictionary:
	if _indeks_miast_po_id is Dictionary:
		return _indeks_miast_po_id
	var out := {}
	if not FileAccess.file_exists(PLIK_INDEKS_MIAST):
		_indeks_miast_po_id = out
		return out
	var plik := FileAccess.open(PLIK_INDEKS_MIAST, FileAccess.READ)
	if plik == null:
		_indeks_miast_po_id = out
		return out
	var surowe: Variant = JSON.parse_string(plik.get_as_text())
	if surowe is Dictionary and surowe.get("miasta") is Array:
		for m in surowe["miasta"]:
			if m is Dictionary and str(m.get("id", "")) != "":
				out[str(m["id"])] = m
	_indeks_miast_po_id = out
	return out


func _wzbogac_jedno_miasto(miasto: Dictionary) -> Dictionary:
	if miasto.is_empty():
		return miasto
	var kopia: Dictionary = miasto.duplicate(true)
	var id := str(kopia.get("id", ""))
	if id == "":
		return kopia
	var ma_powiat := str(kopia.get("powiat_id", "")) != ""
	var ma_woj := str(kopia.get("wojewodztwo", "")) != ""
	if ma_powiat and ma_woj:
		return kopia
	var indeks := _indeks_miast()
	if indeks.has(id) and indeks[id] is Dictionary:
		var wpis: Dictionary = indeks[id]
		if not ma_powiat:
			kopia["powiat_id"] = str(wpis.get("powiat_id", ""))
		if not ma_woj:
			kopia["wojewodztwo"] = str(wpis.get("wojewodztwo", ""))
	return kopia


func _wzbogac_miasta_z_indeksu(miasta: Array) -> Array:
	var out: Array = []
	for m in miasta:
		if m is Dictionary:
			out.append(_wzbogac_jedno_miasto(m))
	return out


func _oferta_pula_lokalna_miasta(oferta: Dictionary, miasto_gracza_id: String) -> bool:
	if str(oferta.get("stan", "")) != "uzywany":
		return false
	if bool(oferta.get("z_katalogu_globalny", false)):
		return false
	var reg := str(oferta.get("region_szukania", "miasto"))
	if reg != "" and reg != "miasto":
		return false
	return str(oferta.get("miasto_id", "")) == miasto_gracza_id or bool(oferta.get("miasto_gracza", false))


func _znajdz_oferte(swiat: Dictionary, oferta_id: String) -> Dictionary:
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		return {}
	for o in stan["oferty"]:
		if o is Dictionary and str(o.get("id", "")) == oferta_id:
			return o
	return {}


func _zapisz_oferte(swiat: Dictionary, oferta: Dictionary) -> void:
	var stan: Variant = swiat.get("rynek_zakupow", {})
	if not (stan is Dictionary) or not (stan.get("oferty") is Array):
		return
	var oid := str(oferta.get("id", ""))
	for i in range(stan["oferty"].size()):
		var o: Variant = stan["oferty"][i]
		if o is Dictionary and str(o.get("id", "")) == oid:
			stan["oferty"][i] = oferta
			swiat["rynek_zakupow"] = stan
			return


func _nazwa_osoby_pomocy(osoba: Dictionary, fallback: String) -> String:
	if osoba.get("imie") is Dictionary and str(osoba["imie"].get("nazwa", "")) != "":
		return str(osoba["imie"].get("nazwa"))
	if str(osoba.get("nazwa", "")) != "":
		return str(osoba["nazwa"])
	match fallback:
		"matka":
			return "Mama"
		"ojciec":
			return "Tata"
		"przyjaciel":
			return "Przyjaciel"
		"znajomy":
			return "Znajomy"
		_:
			return fallback.capitalize()


func _ids_cech(lista: Variant) -> Array:
	var out: Array = []
	if not (lista is Array):
		return out
	for c in lista:
		if c is Dictionary and str(c.get("id", "")) != "":
			out.append(str(c["id"]))
		elif c is String and c != "":
			out.append(str(c))
	return out


func _wczytaj_dialogi_targ() -> Dictionary:
	if _dialogi_targ is Dictionary:
		return _dialogi_targ
	var conf := _targowanie_conf()
	var sciezka := str(conf.get("dialogi", PLIK_DIALOGI_TARG))
	if sciezka == "":
		sciezka = PLIK_DIALOGI_TARG
	if not FileAccess.file_exists(sciezka):
		_dialogi_targ = {"wpisy": []}
		return _dialogi_targ
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		_dialogi_targ = {"wpisy": []}
		return _dialogi_targ
	var surowe: Variant = JSON.parse_string(plik.get_as_text())
	if surowe is Dictionary:
		_dialogi_targ = surowe
		return surowe
	_dialogi_targ = {"wpisy": []}
	return _dialogi_targ


func _losuj_dialog(dialogi: Dictionary, tag: String, rng: RandomNumberGenerator) -> Dictionary:
	var wpisy: Array = dialogi.get("wpisy", []) if dialogi.get("wpisy") is Array else []
	var pula: Array = []
	for w in wpisy:
		if not (w is Dictionary):
			continue
		var tagi: Variant = w.get("tagi", [])
		if not (tagi is Array):
			continue
		if not tagi.has(tag):
			continue
		# Puste sloty do_wpisania pomijamy przy losowaniu.
		if str(w.get("tekst", "")).strip_edges() == "":
			continue
		pula.append(w)
	if pula.is_empty():
		match tag:
			"akceptacja":
				return {"id": "fallback_ok", "tekst": "Umowa stoi."}
			"odmowa":
				return {"id": "fallback_nie", "tekst": "Za mało. Podbij ofertę."}
			_:
				return {"id": "fallback_koniec", "tekst": "Do widzenia."}
	return pula[rng.randi_range(0, pula.size() - 1)]


func _meta_usterki(uid: String, kategoria: String = "", segment: String = "") -> Dictionary:
	if kategoria != "":
		for u in lista_usterek_meta(kategoria, segment):
			if u is Dictionary and str(u.get("id", "")) == uid:
				return u
	# Fallback: najpierw auta, potem wszystkie kategorie dóbr.
	var kat := usterki_katalog()
	for u in (kat.get("usterki", []) if kat.get("usterki") is Array else []):
		if u is Dictionary and str(u.get("id", "")) == uid:
			return u
	var root := usterki_dobr_katalog()
	var kategorie: Dictionary = root.get("kategorie", {}) if root.get("kategorie") is Dictionary else {}
	for _kid in kategorie.keys():
		var blok: Variant = kategorie[_kid]
		if not (blok is Dictionary):
			continue
		for u2 in (blok.get("usterki", []) if blok.get("usterki") is Array else []):
			if u2 is Dictionary and str(u2.get("id", "")) == uid:
				return u2
	return {}


func _kotwica_naprawy_silnika(auto: Dictionary) -> Dictionary:
	var meta := _meta_usterki("awaria_silnika")
	var nap: Dictionary = meta.get("naprawa", {}) if meta.get("naprawa") is Dictionary else {}
	var od_m := int(nap.get("mechanik_koszt_od_zl", 2500))
	var do_m := int(nap.get("mechanik_koszt_do_zl", 12000))
	var laweta := int(nap.get("laweta_koszt_zl", 450))
	var zlom_od := int(nap.get("zlom_wykup_od_zl", 200))
	var zlom_do := int(nap.get("zlom_wykup_do_zl", 900))
	# Kotwica zależna od ceny / stanu — propozycja.
	var baza_ceny := 8000
	if _liczba(auto.get("cena_zl")):
		baza_ceny = int(auto["cena_zl"])
	elif _liczba(auto.get("cena_katalog_zl")):
		baza_ceny = int(auto["cena_katalog_zl"])
	var mechanik := clampi(int(round(float(baza_ceny) * 0.18)), od_m, do_m)
	var zlom := clampi(int(round(float(baza_ceny) * 0.04)), zlom_od, zlom_do)
	return {
		"laweta_zl": laweta,
		"mechanik_zl": mechanik,
		"zlom_zl": zlom,
		"propozycja_do_poprawki": true,
	}


## Stub: laweta przy aucie które nie jeździ (koszt, flaga).
func laweta_auta(swiat: Dictionary, auto_idx: int) -> Dictionary:
	var out := {"ok": false, "powod": "", "koszt_zl": 0}
	var auto: Variant = _auto_w_majatku(swiat, auto_idx)
	if not (auto is Dictionary):
		out["powod"] = "Brak auta w majątku."
		return out
	if not bool(auto.get("nie_jezdzi", false)):
		out["powod"] = "Auto jeździ — laweta niepotrzebna."
		return out
	var kot := _kotwica_naprawy_silnika(auto)
	var koszt := int(kot["laweta_zl"])
	if not _pobierz_pieniadze(swiat, koszt):
		out["powod"] = "Za mało pieniędzy na lawetę (%d zł)." % koszt
		return out
	auto["laweta_zamowiona"] = true
	auto["laweta_koszt_zl"] = koszt
	out["ok"] = true
	out["koszt_zl"] = koszt
	out["tekst"] = "Laweta zamówiona (stub): −%d zł." % koszt
	out["propozycja_do_poprawki"] = true
	return out


## Mechanik: usuwa awarię silnika / nie_jezdzi; auto znów jeździ.
func mechanik_auta(swiat: Dictionary, auto_idx: int) -> Dictionary:
	var out := {"ok": false, "powod": "", "koszt_zl": 0}
	var auto: Variant = _auto_w_majatku(swiat, auto_idx)
	if not (auto is Dictionary):
		out["powod"] = "Brak auta w majątku."
		return out
	if not bool(auto.get("nie_jezdzi", false)) and not _lista_ma(auto.get("usterki_rzeczywiste", []), "awaria_silnika"):
		out["powod"] = "Brak poważnej awarii silnika."
		return out
	var kot := _kotwica_naprawy_silnika(auto)
	var koszt := int(kot["mechanik_zl"])
	if not _pobierz_pieniadze(swiat, koszt):
		out["powod"] = "Za mało pieniędzy na mechanika (%d zł)." % koszt
		out["koszt_propozycja_zl"] = koszt
		return out
	_usun_usterke_z_auta(auto, "awaria_silnika")
	auto["nie_jezdzi"] = false
	auto["do_naprawy"] = false
	auto["laweta_zamowiona"] = false
	# Przelicz vmax po usunięciu awarii (inne usterki mocy mogą zostać).
	var ids: Array = auto.get("usterki_rzeczywiste", []) if auto.get("usterki_rzeczywiste") is Array else []
	var ef := efekty_usterek_vmax(ids)
	auto["vmax_delta"] = int(ef.get("vmax_delta", 0))
	if _liczba(auto.get("vmax_katalog")):
		auto["predkosc_max_kmh"] = clampi(int(auto["vmax_katalog"]) + int(auto["vmax_delta"]), 40, 350)
	out["ok"] = true
	out["koszt_zl"] = koszt
	out["tekst"] = "Mechanik naprawił silnik (stub/propozycja): −%d zł. Auto znów jeździ." % koszt
	out["propozycja_do_poprawki"] = true
	return out


## Złom: usunięcie auta z majątku + drobne złotówki.
func zlom_auta(swiat: Dictionary, auto_idx: int) -> Dictionary:
	var out := {"ok": false, "powod": "", "wykup_zl": 0}
	var maj: Variant = swiat.get("majatek", {})
	if not (maj is Dictionary) or not (maj.get("dobra") is Array):
		out["powod"] = "Brak majątku."
		return out
	var dobra: Array = maj["dobra"]
	if auto_idx < 0 or auto_idx >= dobra.size():
		out["powod"] = "Zły indeks auta."
		return out
	var auto: Variant = dobra[auto_idx]
	if not (auto is Dictionary) or str(auto.get("kategoria", "")) != "samochod":
		out["powod"] = "To nie samochód."
		return out
	var kot := _kotwica_naprawy_silnika(auto)
	var wykup := int(kot["zlom_zl"])
	dobra.remove_at(auto_idx)
	maj["dobra"] = dobra
	swiat["majatek"] = maj
	_dodaj_pieniadze(swiat, wykup)
	out["ok"] = true
	out["wykup_zl"] = wykup
	out["tekst"] = "Oddano na złom (stub): +%d zł. Auto usunięte." % wykup
	out["propozycja_do_poprawki"] = true
	return out


func _auto_w_majatku(swiat: Dictionary, auto_idx: int) -> Variant:
	var maj: Variant = swiat.get("majatek", {})
	if not (maj is Dictionary) or not (maj.get("dobra") is Array):
		return null
	var dobra: Array = maj["dobra"]
	if auto_idx < 0 or auto_idx >= dobra.size():
		return null
	var auto: Variant = dobra[auto_idx]
	if auto is Dictionary and str(auto.get("kategoria", "")) == "samochod":
		return auto
	return null


func _lista_ma(lista: Variant, uid: String) -> bool:
	if not (lista is Array):
		return false
	return lista.has(uid)


func _usun_usterke_z_auta(auto: Dictionary, uid: String) -> void:
	for klucz in ["usterki_rzeczywiste", "usterki_deklarowane", "usterki_ukryte", "usterki_wykryte"]:
		var L: Variant = auto.get(klucz, [])
		if not (L is Array):
			continue
		var nowa: Array = []
		for x in L:
			if str(x) != uid:
				nowa.append(x)
		auto[klucz] = nowa


func _pobierz_pieniadze(swiat: Dictionary, kwota: int) -> bool:
	if kwota <= 0:
		return true
	if not (swiat.get("bohater") is Dictionary):
		return false
	var boh: Dictionary = swiat["bohater"]
	var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
	if kasa < kwota:
		return false
	boh["pieniadze"] = kasa - kwota
	swiat["bohater"] = boh
	return true


func _dodaj_pieniadze(swiat: Dictionary, kwota: int) -> void:
	if kwota == 0:
		return
	if not (swiat.get("bohater") is Dictionary):
		swiat["bohater"] = {"pieniadze": maxi(0, kwota)}
		return
	var boh: Dictionary = swiat["bohater"]
	var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
	boh["pieniadze"] = kasa + kwota
	swiat["bohater"] = boh
