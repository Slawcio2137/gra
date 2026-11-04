extends RefCounted
class_name RynekPracy

## Ogłoszenia z katalogu KZiS: kilka naraz, nie cała pula.
## Kotwica płacy z katalogu. Stawka ogłoszenia jest w paśmie z praca_rynek.json.
## Reszta (wymagania, negocjacje, szef) jest propozycją z praca_rynek.json.

const PLIK := "res://postacie/praca_rynek.json"
const PLIK_DIALOGI := "res://postacie/praca_dialogi.json"
const PLIK_INDEKS := "res://postacie/zatrudnienie/indeks.json"
const Katalog = preload("res://scripts/katalog_zawodow.gd")
const Zaokr = preload("res://scripts/zaokraglenie_zarobkow.gd")
const Podatki = preload("res://scripts/podatki_pracy.gd")

const STATY := [
	"zmeczenie_fizyczne",
	"zmeczenie_psychiczne",
	"sylwetka",
	"inteligencja",
	"zdrowie",
	"wyglad",
	"sila",
	"kondycja",
	"psychika",
]
const NAZWY_STAT := {
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

var _rubryka: Dictionary = {}
var _wczytana := false
var _proby := 0
var _ostatnia_pula := -1
var _wagi_gotowe := false
var _liczba_z_placa := 0
var _waga_grupy: Dictionary = {}
var _udzial_klucz := ""
var _udzial_cache := 0.0
var _dialogi: Dictionary = {}
var _dialogi_wczytane := false
var _podatki = Podatki.new()
var _cache_plikow: Dictionary = {}
var _pliki: Array = []


func rubryka() -> Dictionary:
	_wczytaj()
	return _rubryka


func okno_start() -> int:
	return int(_okno().get("start", 8))


func wyprzedzenie() -> int:
	return int(_okno().get("wyprzedzenie", 5))


func ostatnie_proby() -> int:
	return _proby


func ostatnia_pula() -> int:
	return _ostatnia_pula


func mieszkancow_na_oferte() -> int:
	var blok := _oferta_na_mieszkancow()
	return maxi(1, int(blok.get("mieszkancow_na_oferte", 412)))


func baza_ofert(ludnosc: int) -> int:
	## round(ludność / 412). Bez progu „min. 1” i bez capu jak przy aucie.
	if ludnosc <= 0:
		return 0
	return maxi(0, int(round(float(ludnosc) / float(mieszkancow_na_oferte()))))


func miasto_bohatera(miejsca: Array, id_miejsca: String) -> Dictionary:
	## Brak id nie wskakuje na inne miasto (wcześniej przy aucie: Aleksandrów Kujawski).
	var szukany := id_miejsca.strip_edges()
	if szukany == "":
		return _brak_miasta()
	var znalezione := _miejsce_po_id(miejsca, szukany)
	if znalezione.is_empty():
		return _brak_miasta()
	if str(znalezione.get("typ", "")) == "miasto":
		return _karta_miasta(znalezione, false)
	var siedziba := _siedziba_id(szukany)
	if siedziba != "":
		var stol := _miejsce_po_id(miejsca, siedziba)
		if not stol.is_empty() and str(stol.get("typ", "")) == "miasto":
			return _karta_miasta(stol, false)
	var powiat := str(znalezione.get("powiat_id", ""))
	var jedyne: Dictionary = {}
	var ile := 0
	if powiat != "":
		for m in miejsca:
			if not (m is Dictionary):
				continue
			if str(m.get("typ", "")) != "miasto":
				continue
			if str(m.get("powiat_id", "")) != powiat:
				continue
			jedyne = m
			ile += 1
	if ile == 1:
		return _karta_miasta(jedyne, false)
	return _brak_miasta()


func ludnosc_zakresu(miejsca: Array, poziom: String, id_miejsca: String) -> int:
	var zakres := poziom.strip_edges()
	if zakres == "polska":
		return _suma_ludnosci(miejsca, "")
	var miasto := miasto_bohatera(miejsca, id_miejsca)
	if bool(miasto.get("brak", false)):
		return 0
	if zakres == "wojewodztwo":
		var woj := str(miasto.get("wojewodztwo", "")).strip_edges()
		if woj == "":
			return 0
		return _suma_ludnosci(miejsca, woj)
	return int(miasto.get("ludnosc", 0))


func udzial_filtra(filtry: Dictionary) -> float:
	## Udział kodów KZiS z płacą, które przechodzą filtr. Bez filtra = 1.
	## To nie jest waga zatrudnienia Eurostatu.
	if not _filtr_zaweza(filtry):
		return 1.0
	if _tylko_grupa(filtry):
		_przygotuj_wagi()
		if _liczba_z_placa <= 0:
			return 0.0
		var g := str(filtry.get("wielka_grupa", "")).strip_edges()
		return float(int(_waga_grupy.get(g, 0))) / float(_liczba_z_placa)
	return _udzial_skanem(filtry)


func mnoznik_obszaru(poziom: String, filtry: Dictionary) -> float:
	## Miasto zawsze 1. Bez nakładki testowej województwo i Polska biorą jedną skalę puli,
	## tę samą wszędzie, więc udziały sekcji się od niej nie zmieniają.
	if poziom != "wojewodztwo" and poziom != "polska":
		return 1.0
	if not (filtry.get("czynniki_test") is Dictionary):
		return _skala_puli()
	var nadpis: Dictionary = {}
	if filtry.get("czynniki_test") is Dictionary:
		nadpis = filtry["czynniki_test"]
	var grupa := str(filtry.get("wielka_grupa", "")).strip_edges()
	if grupa != "":
		return _produkt_grupy(grupa, nadpis)
	_przygotuj_wagi()
	if _liczba_z_placa <= 0:
		return 1.0
	var suma := 0.0
	for g in _waga_grupy.keys():
		suma += float(int(_waga_grupy[g])) * _produkt_grupy(str(g), nadpis)
	return suma / float(_liczba_z_placa)


func pula_ofert(ludnosc: int, poziom: String, filtry: Dictionary, nazwa_obszaru: String = "", metropolia: bool = false) -> int:
	if ludnosc <= 0:
		return 0
	var baza := baza_ofert(ludnosc)
	if filtry.get("czynniki_test") is Dictionary:
		var mnoz := mnoznik_obszaru(poziom, filtry)
		if poziom != "wojewodztwo" and poziom != "polska":
			mnoz = _korekta_miksu_miasta(filtry)
		var surowe := float(baza) * udzial_filtra(filtry) * mnoz
		if surowe <= 0.0:
			return 0
		return maxi(0, int(round(surowe)))
	var skala := 1.0
	if poziom == "wojewodztwo" or poziom == "polska":
		skala = _skala_puli()
	var udzial := 1.0
	var grupa := str(filtry.get("wielka_grupa", "")).strip_edges()
	if grupa != "":
		var obszar := nazwa_obszaru if nazwa_obszaru != "" else "Polska"
		var metro := metropolia and poziom != "wojewodztwo" and poziom != "polska"
		udzial = _udzial_grupy_z_zatrudnienia(obszar, grupa, metro)
	elif _filtr_zaweza(filtry):
		udzial = udzial_filtra(filtry)
	var wynik := float(baza) * skala * udzial
	if wynik <= 0.0:
		return 0
	return maxi(0, int(round(wynik)))


func aktywuj(swiat: Dictionary, filtry: Dictionary, tydzien: int, miejsca: Array = [], id_miejsca: String = "") -> int:
	var stan := _stan(swiat)
	stan["aktywna"] = true
	stan["aktywacja_tydzien"] = tydzien
	_wygas_w_stanie(stan, tydzien)
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var limit := _limit_puli(swiat, filtry, miejsca, id_miejsca)
	stan["pula"] = limit
	var brak := okno_start() - oferty.size()
	if limit >= 0:
		brak = mini(brak, maxi(0, limit - oferty.size()))
	if brak <= 0:
		swiat["rynek_pracy"] = stan
		return 0
	swiat["rynek_pracy"] = stan
	return uzupelnij(swiat, filtry, brak, tydzien, miejsca, id_miejsca)


func uzupelnij(swiat: Dictionary, filtry: Dictionary, ile: int, tydzien: int, miejsca: Array = [], id_miejsca: String = "") -> int:
	var porcja := clampi(ile, 0, int(_okno().get("max_jednej_dokladki", 16)))
	_proby = 0
	var limit := _limit_puli(swiat, filtry, miejsca, id_miejsca)
	var stan := _stan(swiat)
	stan["pula"] = limit
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	if limit >= 0:
		porcja = mini(porcja, maxi(0, limit - oferty.size()))
	if porcja == 0:
		swiat["rynek_pracy"] = stan
		return 0
	var ziarno := int(stan.get("ziarno", 1))
	var sufit := porcja * int(_okno().get("max_proby_na_oferte", 12))
	var dodane := 0
	var ctx := _kontekst_losowania(filtry, miejsca, _id_miejsca(swiat, id_miejsca))
	## Ten sam kod KZiS może wrócić później jako kolejne ogłoszenie.
	## Inaczej Polska urywa się na liczbie zawodów, nie na ludności.
	while dodane < porcja and _proby < sufit:
		_proby += 1
		var kursor := int(stan.get("kursor", 0)) + 1
		stan["kursor"] = kursor
		var oferta := _losuj_oferte(ctx, ziarno, kursor, tydzien, filtry)
		if oferta.is_empty() or not pasuje(oferta, filtry):
			continue
		oferty.append(oferta)
		dodane += 1
	stan["oferty"] = oferty
	stan["ostatnie_proby"] = _proby
	swiat["rynek_pracy"] = stan
	return dodane


func wygas(swiat: Dictionary, tydzien: int) -> void:
	var stan := _stan(swiat)
	if not bool(stan.get("aktywna", false)):
		return
	_wygas_w_stanie(stan, tydzien)
	swiat["rynek_pracy"] = stan


func wytworz_oferte(zawod: Dictionary, tydzien: int, kursor: int) -> Dictionary:
	_wczytaj()
	var place: Variant = zawod.get("zarobki", null)
	if not (place is Dictionary) or not _liczba(place.get("mediana_zl")):
		return {}
	var kod := str(zawod.get("kod", ""))
	var grupa := str(zawod.get("wielka_grupa", kod.substr(0, 1)))
	var baza: Dictionary = _wymagania(grupa, kod)
	var wym: Dictionary = _wariant_wymagan(baza, kod, kursor)
	var efekty: Dictionary = zawod.get("efekty_tygodniowe", {}) if zawod.get("efekty_tygodniowe") is Dictionary else {}
	var kotwica := int(place.get("mediana_zl"))
	var wystawione := place_oferty(kotwica, kod, kursor, int(baza.get("wyksztalcenie", 0)), int(baza.get("doswiadczenie", 0)), int(wym.get("wyksztalcenie", 0)), int(wym.get("doswiadczenie", 0)))
	return {
		"id": "oferta_%d_%s" % [kursor, kod],
		"kod": kod,
		"nazwa": str(zawod.get("nazwa", kod)),
		"profil": str(zawod.get("profil", "")),
		"wielka_grupa": grupa,
		"wielka_grupa_nazwa": str(zawod.get("wielka_grupa_nazwa", "")),
		"rodzaj_wynagrodzenia": "brutto",
		"placa_kotwica_zl": kotwica,
		"placa_kotwica_po_wymaganiach": float(wystawione.get("przesunieta", kotwica)),
		"mnoznik_wymagan": float(wystawione.get("mnoznik", 1.0)),
		"placa_udzial": float(wystawione.get("udzial", 1.0)),
		"placa_przed_zaokragleniem": float(wystawione.get("przed", kotwica)),
		"placa_zl": int(wystawione.get("placa_zl", kotwica)),
		"zarobki_zrodlo": str(zawod.get("zarobki_zrodlo", place.get("zarobki_zrodlo", ""))),
		"wymagane_wyksztalcenie_baza": int(baza.get("wyksztalcenie", 0)),
		"wymagane_doswiadczenie_baza": int(baza.get("doswiadczenie", 0)),
		"wymagane_wyksztalcenie": int(wym.get("wyksztalcenie", 0)),
		"wymagane_doswiadczenie": int(wym.get("doswiadczenie", 0)),
		"wplyw": _znaki(efekty),
		"efekty_tygodniowe": efekty.duplicate(true),
		"tydzien_wystawienia": tydzien,
		"waznosc_tygodni": int(_okno().get("waznosc_tygodni", 4)),
		"propozycja_do_poprawki": true,
	}


func pasuje(oferta: Dictionary, filtry: Dictionary) -> bool:
	if oferta.is_empty() or not _liczba(oferta.get("placa_zl")):
		return false
	var grupa := str(filtry.get("wielka_grupa", "")).strip_edges()
	if grupa != "" and str(oferta.get("wielka_grupa", "")) != grupa:
		return false
	var tekst := str(filtry.get("tekst", "")).strip_edges().to_lower()
	if tekst != "" and str(oferta.get("nazwa", "")).to_lower().find(tekst) < 0:
		return false
	if bool(filtry.get("filtruj_place", false)):
		var placa := int(oferta.get("placa_zl"))
		if placa < int(filtry.get("placa_od", 0)) or placa > int(filtry.get("placa_do", 1 << 30)):
			return false
	if int(filtry.get("wyksztalcenie_max", -1)) >= 0:
		if int(oferta.get("wymagane_wyksztalcenie", 0)) > int(filtry.get("wyksztalcenie_max")):
			return false
	if int(filtry.get("doswiadczenie_max", -1)) >= 0:
		if int(oferta.get("wymagane_doswiadczenie", 0)) > int(filtry.get("doswiadczenie_max")):
			return false
	var stat := str(filtry.get("wplyw_stat", ""))
	var znak := str(filtry.get("wplyw_znak", ""))
	if stat != "" and znak != "":
		var wplyw: Variant = oferta.get("wplyw", {})
		if not (wplyw is Dictionary) or str(wplyw.get(stat, "")) != znak:
			return false
	return true


func tekst_wplywu(oferta: Dictionary) -> String:
	var wplyw: Variant = oferta.get("wplyw", {})
	if not (wplyw is Dictionary):
		return "Wpływ: bez zmian"
	var czesci: PackedStringArray = []
	for stat in STATY:
		var znak := str(wplyw.get(stat, ""))
		if znak != "+" and znak != "-":
			continue
		var pokaz := "−" if znak == "-" else "+"
		czesci.append("%s %s" % [str(NAZWY_STAT.get(stat, stat)), pokaz])
	if czesci.is_empty():
		return "Wpływ: bez zmian"
	return "Wpływ: " + ", ".join(czesci)


## Ogłoszenie szuka osoby, nie nazwy grupy. Mediana grupy zostaje kotwicą w danych i nie wchodzi na kartę.
func tekst_ogloszenia(oferta: Dictionary) -> String:
	var nazwa := str(oferta.get("nazwa", "")).strip_edges().trim_suffix("*").strip_edges()
	var linie: PackedStringArray = []
	if nazwa != "":
		var osoba := _osoba_ogloszenia(nazwa)
		linie.append("%s %s." % [_slowo_poszukiwany(osoba), osoba])
	linie.append("oferowane wynagrodzenie: %s zł brutto" % _odstepy(int(oferta.get("placa_zl", 0))))
	linie.append("Wymaganie:")
	linie.append("wymagane wykształcenie: %s" % nazwa_wyksztalcenia(int(oferta.get("wymagane_wyksztalcenie", 0))))
	linie.append(linia_doswiadczenia(int(oferta.get("wymagane_doswiadczenie", 0))))
	linie.append(linia_cech(oferta))
	return "\n".join(linie)


func linia_doswiadczenia(poziom: int) -> String:
	var frazy := _frazy_doswiadczenia()
	if poziom <= 0:
		return "wymagane doświadczenie: %s" % str(frazy.get("0", "nie jest wymagane"))
	if poziom == 1:
		return "wymagane doświadczenie: %s" % str(frazy.get("1", "krótkie doświadczenie"))
	if poziom <= 3:
		return "wymagane doświadczenie: %s" % str(frazy.get("kilka", "kilka lat doświadczenia"))
	return "wymagane doświadczenie: %s" % str(frazy.get("dlugie", "długie doświadczenie"))


func linia_cech(oferta: Dictionary) -> String:
	var cechy := _blok_cech()
	var ramy: Array = cechy.get("ramy", []) if cechy.get("ramy") is Array else []
	if ramy.is_empty():
		ramy = ["Cenimy ludzi %s.", "Potrzebujemy ludzi %s."]
	var lista := _frazy_cech(oferta, cechy)
	var fraza := ""
	for i in lista.size():
		if i > 0:
			fraza += ", "
		fraza += str(lista[i])
	var klucz := "%s|%s" % [str(oferta.get("kod", "")), str(oferta.get("id", ""))]
	var ramka := str(ramy[posmod(klucz.hash(), ramy.size())])
	return ramka % fraza


func place_oferty(kotwica: int, kod: String, kursor: int, baza_edu: int, baza_exp: int, edu: int, exp: int) -> Dictionary:
	var mnoznik := _mnoznik_wymagan(baza_edu, baza_exp, edu, exp)
	var przesunieta := float(kotwica) * mnoznik
	var pasmo := _pasmo_ogloszenia()
	var min_u := float(pasmo.get("min_udzial", 0.85))
	var max_u := float(pasmo.get("max_udzial", 1.1))
	if min_u < 0.0:
		min_u = 0.0
	if max_u < min_u:
		max_u = min_u
	var u := _jednostka(kod.hash(), kursor, 19)
	var udzial := min_u + u * (max_u - min_u)
	var przed := przesunieta * udzial
	return {
		"mnoznik": mnoznik,
		"przesunieta": przesunieta,
		"udzial": udzial,
		"przed": przed,
		"placa_zl": Zaokr.zaokraglij(przed),
	}


func _wariant_wymagan(baza: Dictionary, kod: String, kursor: int) -> Dictionary:
	var blok := _mnozniki_wymagan()
	var edu := int(baza.get("wyksztalcenie", 0))
	var exp := int(baza.get("doswiadczenie", 0))
	var szansa := float(blok.get("szansa_wyksztalcenia_wyzej", 0.45))
	if _jednostka(kod.hash(), kursor, 23) < szansa and edu < 3:
		edu += 1
	var los := _jednostka(kod.hash(), kursor, 29)
	var nizej := float(blok.get("prog_doswiadczenia_nizej", 0.34))
	var wyzej := float(blok.get("prog_doswiadczenia_wyzej", 0.67))
	if los < nizej and exp > 0:
		exp -= 1
	elif los >= wyzej:
		exp += 1
	return {"wyksztalcenie": edu, "doswiadczenie": maxi(0, exp)}


func _mnoznik_wymagan(baza_edu: int, baza_exp: int, edu: int, exp: int) -> float:
	var blok := _mnozniki_wymagan()
	var w_edu := float(blok.get("wyksztalcenie_w_gore", 1.08))
	var w_gore := float(blok.get("doswiadczenie_w_gore", 1.06))
	var w_dol := float(blok.get("doswiadczenie_w_dol", 0.94))
	var mnoznik := 1.0
	var d_edu := maxi(0, edu - baza_edu)
	for _i in d_edu:
		mnoznik *= w_edu
	var d_exp := exp - baza_exp
	if d_exp > 0:
		for _j in d_exp:
			mnoznik *= w_gore
	elif d_exp < 0:
		for _k in -d_exp:
			mnoznik *= w_dol
	return mnoznik


func _mnozniki_wymagan() -> Dictionary:
	_wczytaj()
	var blok: Variant = _rubryka.get("mnozniki_wymagan", {})
	return blok if blok is Dictionary else {}


func _pasmo_ogloszenia() -> Dictionary:
	_wczytaj()
	var blok: Variant = _rubryka.get("wynagrodzenie_ogloszenia", {})
	return blok if blok is Dictionary else {}


func _frazy_doswiadczenia() -> Dictionary:
	var tekst := _tekst_ogloszenia_json()
	var frazy: Variant = tekst.get("doswiadczenie", {})
	return frazy if frazy is Dictionary else {}


func _blok_cech() -> Dictionary:
	var tekst := _tekst_ogloszenia_json()
	var cechy: Variant = tekst.get("cechy", {})
	return cechy if cechy is Dictionary else {}


func _tekst_ogloszenia_json() -> Dictionary:
	_wczytaj()
	var tekst: Variant = _rubryka.get("tekst_ogloszenia", {})
	return tekst if tekst is Dictionary else {}


func _frazy_cech(oferta: Dictionary, cechy: Dictionary) -> Array:
	var profile: Variant = cechy.get("profile", {})
	var klucz := _klucz_cech(oferta)
	var lista: Array = []
	if profile is Dictionary and profile.get(klucz) is Array:
		lista = profile[klucz]
	elif profile is Dictionary and profile.get("fizyczna") is Array:
		lista = profile["fizyczna"]
	if lista.is_empty():
		return ["pracowitych"]
	return lista


func _klucz_cech(oferta: Dictionary) -> String:
	var profil := str(oferta.get("profil", "")).strip_edges()
	var kod := str(oferta.get("kod", ""))
	var grupa := str(oferta.get("wielka_grupa", "")).strip_edges()
	if grupa == "" and kod.length() > 0:
		grupa = kod.substr(0, 1)
	if profil == "opiekuncza":
		return "opiekuncza"
	if profil == "fizyczna_lekka" and grupa == "5":
		return "klienci"
	if profil != "":
		return profil
	if grupa == "5":
		var nazwa := str(oferta.get("nazwa", "")).to_lower()
		if nazwa.find("kiosk") >= 0 or nazwa.find("sprzedaw") >= 0 or nazwa.find("sklep") >= 0 or nazwa.find("kasjer") >= 0 or nazwa.find("kelner") >= 0:
			return "klienci"
	if grupa == "1" or grupa == "2" or grupa == "4":
		return "biurowa"
	return "fizyczna"


func _osoba_ogloszenia(nazwa: String) -> String:
	if _etykieta_grupy(nazwa):
		return _osoba_z_grupy(nazwa)
	return _mala_pierwsza(nazwa)


func _etykieta_grupy(nazwa: String) -> bool:
	var n := nazwa.to_lower().strip_edges()
	if n.begins_with("pozostali ") or n.begins_with("pozostałe ") or n.begins_with("pozostały ") or n.begins_with("inni ") or n.begins_with("inne "):
		return true
	if n.find("gdzie indziej niesklasyfikow") >= 0 or n.find(" i pokrewn") >= 0:
		return true
	var glowa := n.split(" ")[0]
	return glowa in ["pracownicy", "robotnicy", "specjaliści", "technicy", "kierownicy", "operatorzy", "monterzy", "sprzedawcy", "kierowcy", "rolnicy", "nauczyciele", "lekarze", "pielęgniarki", "fizyczni", "rzemieślnicy"]


func _osoba_z_grupy(nazwa: String) -> String:
	var low := nazwa.to_lower()
	if _fizyczna_budowa(low):
		return "fizyczny pracownik budowlany"
	var reszta := nazwa.strip_edges()
	for prefiks in ["Pozostali ", "Pozostałe ", "Pozostały ", "Inni ", "Inne "]:
		if reszta.begins_with(prefiks):
			reszta = reszta.substr(prefiks.length()).strip_edges()
			break
	reszta = _obetnij_od(reszta, " gdzie indziej niesklasyfikow")
	reszta = _obetnij_od(reszta, " i pokrewn")
	reszta = _obetnij_od(reszta, " i personel pokrewn")
	reszta = _obetnij_od(reszta, ",")
	reszta = _obetnij_druga_role(reszta)
	reszta = reszta.strip_edges()
	if reszta == "":
		return "pracownik"
	return _fraza_lp(reszta)


func _fizyczna_budowa(low: String) -> bool:
	if low.find("murarz") >= 0 or low.find("tynkarz") >= 0 or low.find("elektryk") >= 0 or low.find("cieśl") >= 0 or low.find("cieśle") >= 0 or low.find("malar") >= 0:
		return false
	if low.find("robotnicy budowlani") >= 0 or low.find("pracownicy budowlani") >= 0:
		return true
	if low.find("fizyczn") >= 0 and low.find("budowlan") >= 0:
		return true
	return false


func _obetnij_od(s: String, znacznik: String) -> String:
	var i := s.to_lower().find(znacznik)
	if i <= 0:
		return s
	return s.substr(0, i).strip_edges()


func _obetnij_druga_role(s: String) -> String:
	var low := s.to_lower()
	var i := low.find(" i ")
	if i <= 0:
		return s
	var przed := low.substr(0, i)
	if przed.find("do spraw") >= 0 or przed.find("w zakresie") >= 0 or przed.find("w dziedzinie") >= 0 or przed.find("z dziedziny") >= 0:
		return s
	var po := s.substr(i + 3).strip_edges()
	if po == "":
		return s
	var drugie := po.split(" ")[0]
	if _lp_token(drugie).to_lower() == drugie.to_lower():
		return s
	return s.substr(0, i).strip_edges()


func _fraza_lp(s: String) -> String:
	var slowa: PackedStringArray = s.split(" ", false)
	if slowa.is_empty():
		return "pracownik"
	var glowa := str(slowa[0]).to_lower()
	if glowa == "średni" or glowa == "średnia" or glowa == "personel":
		return _pracownik_z_reszty(s)
	for i in slowa.size():
		var token := str(slowa[i])
		var lp := _lp_token(token)
		if lp.to_lower() != token.to_lower():
			slowa[i] = lp
	return _mala_pierwsza(" ".join(slowa))


func _pracownik_z_reszty(s: String) -> String:
	var low := s.to_lower()
	for znacznik in ["do spraw", "w zakresie", "w dziedzinie", "z dziedziny", "w "]:
		var i := low.find(znacznik)
		if i >= 0:
			return "pracownik " + s.substr(i).strip_edges()
	return "pracownik"


func _lp_token(slowo: String) -> String:
	var low := slowo.to_lower()
	if low == "krawcy":
		return "krawiec"
	if low == "gońcy":
		return "goniec"
	if low == "wróżbici":
		return "wróżbita"
	var pary: Array = [
		["iści", "ista"],
		["yści", "ysta"],
		["ownicy", "ownik"],
		["nicy", "nik"],
		["arki", "arka"],
		["aczki", "aczka"],
		["czki", "czka"],
		["awcy", "awca"],
		["owcy", "owca"],
		["ycy", "yk"],
		["euci", "euta"],
		["ości", "osta"],
		["oci", "ot"],
		["icy", "ik"],
		["owie", ""],
		["arze", "arz"],
		["acze", "acz"],
		["ele", "el"],
		["odzy", "og"],
		["rzy", "r"],
		["sze", "sz"],
		["śle", "śla"],
		["owi", "owy"],
		["ani", "any"],
		["enci", "ent"],
		["uni", "uny"],
		["ni", "ny"],
	]
	for para in pary:
		var suf := str(para[0])
		if low.ends_with(suf) and low.length() > suf.length():
			return low.substr(0, low.length() - suf.length()) + str(para[1])
	return slowo


func _slowo_poszukiwany(osoba: String) -> String:
	var glowa := osoba.to_lower().split(" ")[0]
	if _kobieta(glowa):
		return "Poszukiwana"
	return "Poszukiwany"


func _kobieta(glowa: String) -> bool:
	if glowa == "położna" or glowa == "siostra" or glowa == "osoba" or glowa == "praczka":
		return true
	if glowa.ends_with("ka") or glowa.ends_with("owa") or glowa.ends_with("essa") or glowa.ends_with("iana"):
		return true
	return false


func _mala_pierwsza(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_lower() + s.substr(1)


func _odstepy(n: int) -> String:
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
	return out


func nazwa_wyksztalcenia(poziom: int) -> String:
	_wczytaj()
	var lista: Variant = _rubryka.get("poziomy_wyksztalcenia", [])
	if lista is Array:
		for p in lista:
			if p is Dictionary and int(p.get("id", -1)) == poziom:
				return str(p.get("nazwa", ""))
	return str(poziom)


func nazwa_doswiadczenia(poziom: int) -> String:
	if poziom <= 0:
		return "brak"
	if poziom == 1:
		return "krótkie"
	if poziom <= 3:
		return "kilkuletnie"
	return "długie"


func poziom_wyksztalcenia(bohater: Dictionary) -> int:
	if _liczba(bohater.get("poziom_wyksztalcenia")):
		return clampi(int(bohater["poziom_wyksztalcenia"]), 0, 3)
	var edukacja: Variant = bohater.get("edukacja", [])
	var tekst := ""
	if edukacja is Array:
		for e in edukacja:
			tekst += " " + (str(e.get("id", e)) if e is Dictionary else str(e))
	elif edukacja != null:
		tekst = str(edukacja)
	tekst = tekst.to_lower()
	if tekst.find("wyzsz") >= 0 or tekst.find("studia") >= 0 or tekst.find("licencjat") >= 0 or tekst.find("magister") >= 0:
		return 3
	if tekst.find("liceum") >= 0 or tekst.find("technikum") >= 0 or tekst.find("sredni") >= 0:
		return 2
	if tekst.find("branz") >= 0 or tekst.find("zasadnic") >= 0:
		return 1
	return 0


func doswiadczenie(bohater: Dictionary, kod: String = "") -> int:
	if kod != "":
		var pula := _pula_wprawy(bohater, prefiks_wprawy(kod))
		if not pula.is_empty():
			return maxi(0, int(pula.get("etap", 0)))
	if _liczba(bohater.get("doswiadczenie_zawodowe")):
		return maxi(0, int(bohater["doswiadczenie_zawodowe"]))
	return 0


func dopasowanie(oferta: Dictionary, bohater: Dictionary) -> int:
	var kwali := _kwalifikacje(oferta, bohater)
	return 2 - int(kwali.get("luki", 0))


func pasmo(placa: int) -> Dictionary:
	_wczytaj()
	var neg: Dictionary = _rubryka.get("negocjacje", {}) if _rubryka.get("negocjacje") is Dictionary else {}
	var min_u := float(neg.get("min_udzial", 1.0))
	var max_u := float(neg.get("max_udzial", 1.5))
	if min_u < 1.0:
		min_u = 1.0
	if max_u < min_u:
		max_u = min_u
	return {
		"min_zl": Zaokr.zaokraglij(float(placa) * min_u),
		"max_zl": Zaokr.zaokraglij(float(placa) * max_u),
		"propozycja_do_poprawki": true,
	}


func rozstrzygnij(negocjuje: bool, dopasowanie_n: int, nacisk: float, rzut: float) -> String:
	if not negocjuje:
		if dopasowanie_n <= 0:
			return "odmowa"
		return "zgoda"
	var fit := clampf(float(dopasowanie_n) / 2.0, 0.0, 1.0)
	var ponad := maxf(nacisk, 0.0)
	var prog_zgody := clampf(0.15 + 0.5 * fit - 1.1 * ponad, 0.05, 0.7)
	var prog_kontro := clampf(prog_zgody + 0.28, prog_zgody + 0.08, 0.9)
	if rzut < prog_zgody:
		return "zgoda"
	if rzut < prog_kontro:
		return "kontroferta"
	return "odmowa"


func negocjuj(oferta: Dictionary, bohater: Dictionary, negocjuje: bool, zadana: int, rzut: float) -> Dictionary:
	var oferta_zl := int(oferta.get("placa_zl", 0))
	var kwali := _kwalifikacje(oferta, bohater)
	var dop := 2 - int(kwali.get("luki", 0))
	if int(kwali.get("luki", 0)) > 0 and int(kwali.get("ponad", 0)) == 0:
		return _pakiet_rozmowy("odmowa", 0, oferta_zl, dop, true)
	if not negocjuje and int(kwali.get("luki", 0)) > 0 and int(kwali.get("ponad", 0)) > 0:
		_wczytaj()
		var neg: Dictionary = _rubryka.get("negocjacje", {}) if _rubryka.get("negocjacje") is Dictionary else {}
		var szansa := float(neg.get("szansa_gdy_luka_i_nadwyzka", 0.45))
		if rzut < szansa:
			return _pakiet_rozmowy("zgoda", oferta_zl, oferta_zl, dop, false)
		return _pakiet_rozmowy("odmowa", 0, oferta_zl, dop, true)
	var band := pasmo(oferta_zl)
	var kwota := zadana
	if negocjuje:
		kwota = clampi(zadana, int(band.get("min_zl", oferta_zl)), int(band.get("max_zl", oferta_zl)))
	var nacisk := 0.0
	if negocjuje and oferta_zl > 0:
		nacisk = (float(kwota) - float(oferta_zl)) / float(oferta_zl)
	var wynik := rozstrzygnij(negocjuje, dop, nacisk, rzut)
	var placa := oferta_zl
	var u_nich := oferta_zl
	if wynik == "zgoda" and negocjuje:
		placa = Zaokr.zaokraglij(kwota)
		u_nich = placa
	elif wynik == "kontroferta":
		placa = Zaokr.zaokraglij((float(oferta_zl) + float(kwota)) * 0.5)
		u_nich = placa
	elif wynik == "odmowa":
		placa = 0
		u_nich = oferta_zl
	elif wynik == "zgoda":
		u_nich = oferta_zl
	var twarda := wynik == "odmowa" and int(kwali.get("luki", 0)) > 0
	return _pakiet_rozmowy(wynik, placa, u_nich, dop, twarda)


func lista_prac(swiat: Dictionary) -> Array:
	var out: Array = []
	if swiat.get("prace_gracza") is Array:
		for p in swiat["prace_gracza"]:
			if p is Dictionary and str(p.get("kod", "")) != "":
				out.append(p)
		if not out.is_empty():
			return out
	var jedna: Variant = swiat.get("praca_gracza", {})
	if jedna is Dictionary and str(jedna.get("kod", "")) != "":
		out.append(jedna)
	return out


func zatrudnij(swiat: Dictionary, oferta: Dictionary, placa: int) -> Dictionary:
	_wczytaj()
	var lista := lista_prac(swiat)
	var maks := int(_blok_slownika("dwie_prace").get("maks", 2))
	if lista.size() >= maxi(1, maks):
		return {"ok": false, "powod": "dwie_prace", "propozycja_do_poprawki": true}
	var szef: Dictionary = _rubryka.get("szef", {}) if _rubryka.get("szef") is Dictionary else {}
	var tydzien_b: Dictionary = _rubryka.get("tydzien", {}) if _rubryka.get("tydzien") is Dictionary else {}
	var kod := str(oferta.get("kod", ""))
	var cecha := _cecha_szefa(kod, lista.size())
	var praca := {
		"kod": kod,
		"nazwa": str(oferta.get("nazwa", "")),
		"placa_zl": placa,
		"zarobki_zrodlo": str(oferta.get("zarobki_zrodlo", "")),
		"angaz": int(tydzien_b.get("angaz_start", 50)),
		"upomnienia": 0,
		"staz_tygodni": 0,
		"satysfakcja": int(_blok_slownika("satysfakcja_szefa").get("start", int(tydzien_b.get("satysfakcja_start", 70)))),
		"wypowiedzenie_zostalo": 0,
		"szef": {
			"nazwa": str(szef.get("nazwa", "Kierownik")),
			"relacja": int(szef.get("relacja_start", 50)),
			"cecha": cecha,
		},
		"efekty_tygodniowe": oferta.get("efekty_tygodniowe", {}) if oferta.get("efekty_tygodniowe") is Dictionary else {},
		"wplyw": oferta.get("wplyw", {}) if oferta.get("wplyw") is Dictionary else {},
		"propozycja_do_poprawki": true,
		"ok": true,
	}
	lista.append(praca)
	_zapisz_liste(swiat, lista)
	return praca


func ma_prace(swiat: Dictionary) -> bool:
	return not lista_prac(swiat).is_empty()


func ustaw_angaz(swiat: Dictionary, wartosc: int, indeks: int = 0) -> void:
	var lista := lista_prac(swiat)
	if indeks < 0 or indeks >= lista.size():
		return
	var praca: Dictionary = lista[indeks]
	praca["angaz"] = clampi(wartosc, 0, 100)
	_zapisz_liste(swiat, lista)


func dlugosc_wypowiedzenia(rzut: float) -> int:
	_wczytaj()
	var blok := _blok_slownika("wypowiedzenie")
	var dol := int(blok.get("min_tygodni", 3))
	var gora := int(blok.get("max_tygodni", 9))
	if gora < dol:
		gora = dol
	var u := clampf(rzut, 0.0, 1.0)
	return clampi(dol + int(round(u * float(gora - dol))), dol, gora)


func odejdz(swiat: Dictionary, rzut: float = -1.0, indeks: int = 0) -> int:
	var lista := lista_prac(swiat)
	if indeks < 0 or indeks >= lista.size():
		return 0
	var praca: Dictionary = lista[indeks]
	if int(praca.get("wypowiedzenie_zostalo", 0)) > 0:
		return int(praca.get("wypowiedzenie_zostalo", 0))
	if rzut < 0.0:
		rzut = randf()
	var n := dlugosc_wypowiedzenia(rzut)
	praca["wypowiedzenie_zostalo"] = n
	_zapisz_liste(swiat, lista)
	return n


func tick(swiat: Dictionary, rzut: float = -1.0) -> Dictionary:
	wygas(swiat, int(swiat.get("tydzien", 1)))
	if rzut < 0.0:
		rzut = randf()
	return rozwiaz_tydzien(swiat, rzut)


func rozwiaz_tydzien(swiat: Dictionary, rzut: float) -> Dictionary:
	var out := {
		"wyplata": 0,
		"premia": 0,
		"podwyzka": false,
		"upomnienie": false,
		"zwolniony": false,
		"tekst": "",
		"propozycja_do_poprawki": true,
	}
	var lista := lista_prac(swiat)
	if lista.is_empty():
		return out
	_wczytaj()
	var reg: Dictionary = _rubryka.get("tydzien", {}) if _rubryka.get("tydzien") is Dictionary else {}
	var bohater: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	if lista.size() >= 2:
		_dolicz_brzemie(bohater)
	var zostaw: Array = []
	var teksty: Array = []
	for p in lista:
		if not (p is Dictionary):
			continue
		var praca: Dictionary = p
		var kawalek := _tydzien_jednej(praca, bohater, rzut, reg, swiat)
		if bool(kawalek.get("zostaje", true)):
			zostaw.append(praca)
			_zastosuj_efekty(bohater, praca)
		out["wyplata"] = int(out["wyplata"]) + int(kawalek.get("wyplata", 0))
		out["premia"] = int(out["premia"]) + int(kawalek.get("premia", 0))
		if bool(kawalek.get("podwyzka", false)):
			out["podwyzka"] = true
		if bool(kawalek.get("upomnienie", false)):
			out["upomnienie"] = true
		if bool(kawalek.get("zwolniony", false)):
			out["zwolniony"] = true
		if str(kawalek.get("tekst", "")) != "":
			teksty.append(str(kawalek.get("tekst", "")))
		if str(kawalek.get("pasek_tekst", "")) != "":
			if not (out.get("paski") is Array):
				out["paski"] = []
			out["paski"].append(str(kawalek.get("pasek_tekst", "")))
	if lista.size() >= 2:
		teksty.append("Dwie prace w tym tygodniu. Zmęczenie fizyczne i obciążenie psychiczne idą w górę.")
	_zapisz_liste(swiat, zostaw)
	swiat["bohater"] = bohater
	out["tekst"] = " ".join(teksty) if not teksty.is_empty() else "Mija tydzień."
	var paski: Array = out.get("paski", []) if out.get("paski") is Array else []
	out["pasek_tekst"] = "\n".join(paski)
	return out


func popros_o_podwyzke(swiat: Dictionary, rzut: float, indeks: int = 0) -> Dictionary:
	var out := {"ok": false, "relacja": 0, "placa_zl": 0, "propozycja_do_poprawki": true, "tekst": ""}
	var lista := lista_prac(swiat)
	if indeks < 0 or indeks >= lista.size():
		out["tekst"] = "Nie masz pracy."
		return out
	_wczytaj()
	var reg: Dictionary = _rubryka.get("prosba_o_podwyzke", {}) if _rubryka.get("prosba_o_podwyzke") is Dictionary else {}
	var praca: Dictionary = lista[indeks]
	var bohater: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	var angaz := int(praca.get("angaz", 50))
	var skut := skutecznosc(bohater, angaz, str(praca.get("kod", "")))
	var szef: Dictionary = praca.get("szef", {}) if praca.get("szef") is Dictionary else {}
	var relacja := int(szef.get("relacja", 50))
	var slabo := angaz < int(reg.get("slaby_angaz_ponizej", 40)) or skut < float(reg.get("slaba_skutecznosc_ponizej", 0.4))
	var prog := float(reg.get("szansa_gdy_slabo", 0.08)) if slabo else float(reg.get("szansa_gdy_dobrze", 0.55))
	relacja += int(reg.get("relacja_gdy_slabo", -12)) if slabo else int(reg.get("relacja_gdy_dobrze", 2))
	var ok := rzut < prog
	if ok:
		praca["placa_zl"] = Zaokr.zaokraglij(float(praca.get("placa_zl", 0)) * float(reg.get("udzial_podwyzki", 1.08)))
		relacja += int(reg.get("relacja_gdy_sie_uda", 6))
		out["tekst"] = "Kierownik podnosi płacę."
	else:
		out["tekst"] = "Kierownik odmawia. Robota idzie za słabo." if slabo else "Kierownik odmawia."
	relacja = clampi(relacja, 0, 100)
	szef["relacja"] = relacja
	praca["szef"] = szef
	_zapisz_liste(swiat, lista)
	out["ok"] = ok
	out["relacja"] = relacja
	out["placa_zl"] = int(praca.get("placa_zl", 0))
	return out


func skutecznosc(bohater: Dictionary, angaz: int, kod: String = "") -> float:
	var wiedza := clampf(_liczba_albo(bohater.get("wiedza_pkt"), 0) / 20.0, 0.0, 1.0)
	var kond := 40.0
	if _liczba(bohater.get("kondycja")):
		kond = float(bohater["kondycja"])
	elif _liczba(bohater.get("sila")):
		kond = float(bohater["sila"])
	var sprawnosc := clampf(kond / 100.0, 0.0, 1.0)
	var staz := clampf(float(doswiadczenie(bohater, kod)) / 10.0, 0.0, 1.0)
	var a := clampf(float(angaz) / 100.0, 0.0, 1.0)
	var zf := clampf(_liczba_albo(bohater.get("zmeczenie_fizyczne"), 0) / 100.0, 0.0, 1.0)
	var zp := clampf(_liczba_albo(bohater.get("zmeczenie_psychiczne"), 0) / 100.0, 0.0, 1.0)
	return clampf(0.35 * a + 0.2 * wiedza + 0.2 * sprawnosc + 0.15 * staz - 0.15 * zf - 0.1 * zp, 0.0, 1.0)


func _zastosuj_efekty(bohater: Dictionary, praca: Dictionary) -> void:
	var efekty: Variant = praca.get("efekty_tygodniowe", {})
	if not (efekty is Dictionary):
		return
	for stat in ["zmeczenie_fizyczne", "zmeczenie_psychiczne", "zdrowie", "sila", "kondycja", "psychika"]:
		if not _liczba(efekty.get(stat)) or not _liczba(bohater.get(stat)):
			continue
		bohater[stat] = clampi(int(bohater[stat]) + int(efekty[stat]), 0, 100)
	if _liczba(efekty.get("sylwetka")) and bohater.get("sylwetka") is Dictionary:
		var syl: Dictionary = bohater["sylwetka"]
		var pkt := int(syl.get("punkty", 0)) + int(efekty["sylwetka"])
		syl["punkty"] = clampi(pkt, 0, 100)
		bohater["sylwetka"] = syl


func _wymagania(grupa: String, kod: String) -> Dictionary:
	_wczytaj()
	var tab: Variant = _rubryka.get("wymagania_wielkiej_grupy", {})
	var baza := {"wyksztalcenie": 0, "doswiadczenie": 0}
	if tab is Dictionary and tab.get(grupa) is Dictionary:
		baza = tab[grupa]
	var dodatek := 0
	if kod.length() > 0:
		var ostatnia := kod.substr(kod.length() - 1, 1)
		if ostatnia.is_valid_int() and int(ostatnia) % 2 == 1:
			dodatek = 1
	return {
		"wyksztalcenie": int(baza.get("wyksztalcenie", 0)),
		"doswiadczenie": int(baza.get("doswiadczenie", 0)) + dodatek,
	}


func _znaki(efekty: Dictionary) -> Dictionary:
	var out := {}
	for stat in STATY:
		if not _liczba(efekty.get(stat)):
			out[stat] = ""
			continue
		var d := int(efekty[stat])
		if d > 0:
			out[stat] = "+"
		elif d < 0:
			out[stat] = "-"
		else:
			out[stat] = ""
	return out


func _wygas_w_stanie(stan: Dictionary, tydzien: int) -> void:
	var waznosc := int(_okno().get("waznosc_tygodni", 4))
	var oferty: Array = stan.get("oferty", []) if stan.get("oferty") is Array else []
	var zostaw: Array = []
	for o in oferty:
		if not (o is Dictionary):
			continue
		var start := tydzien
		if _liczba(o.get("tydzien_wystawienia")):
			start = int(o["tydzien_wystawienia"])
		if tydzien - start >= waznosc:
			continue
		zostaw.append(o)
	stan["oferty"] = zostaw


func _stan(swiat: Dictionary) -> Dictionary:
	var stan: Dictionary = {}
	if swiat.get("rynek_pracy") is Dictionary:
		stan = swiat["rynek_pracy"]
	if int(stan.get("ziarno", 0)) == 0:
		stan["ziarno"] = 17011
	if not (stan.get("oferty") is Array):
		stan["oferty"] = []
	return stan


func _okno() -> Dictionary:
	_wczytaj()
	return _rubryka.get("okno", {}) if _rubryka.get("okno") is Dictionary else {}


func _dosw() -> Dictionary:
	_wczytaj()
	return _rubryka.get("doswiadczenie_bohatera", {}) if _rubryka.get("doswiadczenie_bohatera") is Dictionary else {}


func prefiks_wprawy(kod: String) -> String:
	var cyfry := ""
	for i in kod.length():
		var znak := kod.substr(i, 1)
		if znak.is_valid_int():
			cyfry += znak
	if cyfry.length() >= 4:
		return cyfry.substr(0, 4)
	if cyfry.length() >= 3:
		return cyfry.substr(0, 3)
	return cyfry


func stan_wprawy(bohater: Dictionary, kod: String) -> Dictionary:
	var pula := _pula_wprawy(bohater, prefiks_wprawy(kod))
	if pula.is_empty():
		return {"etap": 0, "punkty": 0, "prefiks": prefiks_wprawy(kod), "jest": false}
	pula["prefiks"] = prefiks_wprawy(kod)
	pula["jest"] = true
	return pula


func dodaj_wprawe(bohater: Dictionary, kod: String, punkty: int = -1) -> Dictionary:
	_wczytaj()
	var blok := _blok_slownika("wprawa_zawodowa")
	var krok := punkty if punkty >= 0 else int(blok.get("punkty_za_tydzien", 8))
	var cap := int(blok.get("punkty_w_etapie_max", 100))
	if cap <= 0:
		cap = 100
	var etapy: Array = blok.get("etapy", []) if blok.get("etapy") is Array else []
	var ostatni := maxi(0, etapy.size() - 1)
	var prefiks := prefiks_wprawy(kod)
	var magazyn: Dictionary = bohater.get("wprawa_zawodowa", {}) if bohater.get("wprawa_zawodowa") is Dictionary else {}
	var pula: Dictionary = magazyn.get(prefiks, {}) if magazyn.get(prefiks) is Dictionary else {"etap": 0, "punkty": 0}
	var etap := int(pula.get("etap", 0))
	var pkt := int(pula.get("punkty", 0)) + krok
	while pkt >= cap and etap < ostatni:
		pkt -= cap
		etap += 1
	if etap >= ostatni:
		etap = ostatni
		pkt = mini(pkt, cap)
	pula = {"etap": etap, "punkty": pkt, "propozycja_do_poprawki": true}
	magazyn[prefiks] = pula
	bohater["wprawa_zawodowa"] = magazyn
	return pula


func pasmo_tygodnia(skut: float, angaz: int, zmeczenie_fizyczne: int, zmeczenie_psychiczne: int) -> String:
	_wczytaj()
	var reg: Dictionary = _rubryka.get("tydzien", {}) if _rubryka.get("tydzien") is Dictionary else {}
	var progi: Array = reg.get("progi_skutecznosci", [0.28, 0.42, 0.58, 0.75]) if reg.get("progi_skutecznosci") is Array else [0.28, 0.42, 0.58, 0.75]
	var nazwy := ["wyraznie_gorzej", "troche_gorzej", "w_porzadku", "dobrze", "bardzo_dobrze"]
	var indeks := nazwy.size() - 1
	for i in progi.size():
		if skut < float(progi[i]):
			indeks = i
			break
	if angaz < int(reg.get("zly_angaz_ponizej", 35)):
		indeks -= 1
	elif angaz >= 80:
		indeks += 1
	indeks = clampi(indeks, 0, nazwy.size() - 1)
	var prog_zm := int(reg.get("zmeczenie_zle_od", 80))
	if zmeczenie_fizyczne >= prog_zm or zmeczenie_psychiczne >= prog_zm:
		indeks = mini(indeks, 1)
	return nazwy[indeks]


func linia_dialogu(sytuacja: String, placa: int, indeks: int = -1) -> String:
	var grupy := _grupy_dialogu()
	var lista: Array = grupy.get(sytuacja, []) if grupy.get(sytuacja) is Array else []
	if lista.is_empty():
		return ""
	var i := indeks
	if i < 0 or i >= lista.size():
		i = randi() % lista.size()
	return str(lista[i]).replace("____", _odstepy(placa))


func wstep_dialogu(sytuacja: String) -> String:
	_wczytaj_dialogi()
	var wstep: Variant = _dialogi.get("wstep", {})
	if wstep is Dictionary:
		return str(wstep.get(sytuacja, ""))
	return ""


func wybory_dialogu() -> Array:
	_wczytaj_dialogi()
	var lista: Variant = _dialogi.get("wybory", [])
	if lista is Array and lista.size() >= 3:
		return lista
	return ["Tak", "Nie", "Spróbuj ponownej negocjacji"]


func liczba_dialogow() -> int:
	var n := 0
	var grupy := _grupy_dialogu()
	for klucz in grupy.keys():
		n += liczba_linii(str(klucz))
	return n


func liczba_linii(sytuacja: String) -> int:
	var grupy := _grupy_dialogu()
	var lista: Variant = grupy.get(sytuacja, [])
	return lista.size() if lista is Array else 0


func _korekta_miksu_miasta(filtry: Dictionary) -> float:
	## Suma miasta zostaje przy ludności. Rodzaj bierze iloczyn grupy podzielony przez średnią,
	## więc mocniejsza branża zajmuje większy kawałek tej samej puli.
	var grupa := str(filtry.get("wielka_grupa", "")).strip_edges()
	if grupa == "":
		return 1.0
	var nadpis: Dictionary = {}
	if filtry.get("czynniki_test") is Dictionary:
		nadpis = filtry["czynniki_test"]
	var produkt := _produkt_grupy(grupa, nadpis)
	var kopia := filtry.duplicate()
	kopia["wielka_grupa"] = ""
	var srednia := mnoznik_obszaru("wojewodztwo", kopia)
	if srednia <= 0.0:
		return 1.0
	return produkt / srednia


func _pakiet_rozmowy(wynik: String, placa_zl: int, u_nich: int, dop: int, twarda: bool = false) -> Dictionary:
	return {
		"wynik": wynik,
		"placa_zl": placa_zl,
		"placa_pracodawcy": u_nich,
		"dopasowanie": dop,
		"propozycja_do_poprawki": true,
		"odmowa_konczy_aplikacje": false,
		"twarda_odmowa": twarda,
		"wybory": wybory_dialogu(),
	}


func _kwalifikacje(oferta: Dictionary, bohater: Dictionary) -> Dictionary:
	var edu := poziom_wyksztalcenia(bohater)
	var exp := doswiadczenie(bohater, str(oferta.get("kod", "")))
	var edu_w := int(oferta.get("wymagane_wyksztalcenie", 0))
	var exp_w := int(oferta.get("wymagane_doswiadczenie", 0))
	var luki := 0
	var ponad := 0
	if edu < edu_w:
		luki += 1
	elif edu > edu_w:
		ponad += 1
	if exp < exp_w:
		luki += 1
	elif exp > exp_w:
		ponad += 1
	return {"luki": luki, "ponad": ponad}


func _zapisz_liste(swiat: Dictionary, lista: Array) -> void:
	swiat["prace_gracza"] = lista
	if lista.is_empty():
		swiat["praca_gracza"] = {}
	else:
		swiat["praca_gracza"] = lista[0]


func _dolicz_brzemie(bohater: Dictionary) -> void:
	var blok := _blok_slownika("dwie_prace")
	var fiz := int(blok.get("zmeczenie_fizyczne", 12))
	var psych := int(blok.get("zmeczenie_psychiczne", 12))
	var zf := _liczba_albo(bohater.get("zmeczenie_fizyczne"), 0) + fiz
	var zp := _liczba_albo(bohater.get("zmeczenie_psychiczne"), 0) + psych
	bohater["zmeczenie_fizyczne"] = clampi(zf, 0, 100)
	bohater["zmeczenie_psychiczne"] = clampi(zp, 0, 100)


func _tydzien_jednej(praca: Dictionary, bohater: Dictionary, rzut: float, reg: Dictionary, swiat: Dictionary) -> Dictionary:
	var out := {
		"zostaje": true,
		"wyplata": 0,
		"premia": 0,
		"podwyzka": false,
		"upomnienie": false,
		"zwolniony": false,
		"tekst": "",
	}
	var kod := str(praca.get("kod", ""))
	var angaz := int(praca.get("angaz", 50))
	var skut := skutecznosc(bohater, angaz, kod)
	var pasmo_id := pasmo_tygodnia(
		skut,
		angaz,
		_liczba_albo(bohater.get("zmeczenie_fizyczne"), 0),
		_liczba_albo(bohater.get("zmeczenie_psychiczne"), 0)
	)
	var pasma: Dictionary = reg.get("pasma", {}) if reg.get("pasma") is Dictionary else {}
	var pasmo_d: Dictionary = pasma.get(pasmo_id, {}) if pasma.get(pasmo_id) is Dictionary else {}
	var szef: Dictionary = praca.get("szef", {}) if praca.get("szef") is Dictionary else {}
	var mnoz := _mnoznik_cechy(str(szef.get("cecha", "")))
	var sat := int(praca.get("satysfakcja", int(reg.get("satysfakcja_start", 70))))
	var ruch := int(round(float(pasmo_d.get("satysfakcja", 0)) * mnoz))
	sat = clampi(sat + ruch, 0, 100)
	praca["satysfakcja"] = sat
	var prog := int(_blok_slownika("satysfakcja_szefa").get("zwolnienie_gdy_spadnie_do", int(reg.get("satysfakcja_zwolnienie_ponizej_lub_rowno", 15))))
	var relacja := int(szef.get("relacja", 50))
	if sat <= prog:
		out["zwolniony"] = true
		out["zostaje"] = false
		out["tekst"] = _zdanie_pracy(praca, "Kierownik ma dość i zwalnia.")
		return out
	if bool(pasmo_d.get("upomnienie", false)):
		praca["upomnienia"] = int(praca.get("upomnienia", 0)) + 1
		relacja = clampi(relacja + int(reg.get("upomnienie_relacja", -10)), 0, 100)
		out["upomnienie"] = true
		out["tekst"] = _zdanie_pracy(praca, "Kierownik daje upomnienie. Praca zostaje.")
	else:
		relacja = clampi(relacja + 2, 0, 100)
		var szansa_p := float(pasmo_d.get("szansa_podwyzki", 0.0))
		var szansa_b := float(pasmo_d.get("szansa_premii", 0.0))
		if rzut < szansa_p:
			praca["placa_zl"] = Zaokr.zaokraglij(float(praca.get("placa_zl", 0)) * float(reg.get("podwyzka_tygodnia_udzial", 1.05)))
			out["podwyzka"] = true
			out["tekst"] = _zdanie_pracy(praca, "Kierownik podnosi płacę.")
		elif rzut < szansa_b:
			out["premia"] = Zaokr.zaokraglij(float(praca.get("placa_zl", 0)) * float(reg.get("premia_udzial", 0.1)))
			out["tekst"] = _zdanie_pracy(praca, "Dostajesz premię.")
	szef["relacja"] = relacja
	praca["szef"] = szef
	praca["staz_tygodni"] = int(praca.get("staz_tygodni", 0)) + 1
	dodaj_wprawe(bohater, kod)
	var brutto_miesiac := int(praca.get("placa_zl", 0)) + int(out.get("premia", 0))
	var stan: Dictionary = swiat.get("podatki_rok", {}) if swiat.get("podatki_rok") is Dictionary else {}
	var kraj := str(swiat.get("kraj", "polska")).strip_edges().to_lower()
	if kraj == "":
		kraj = "polska"
	var slip: Dictionary = _podatki.pasek(brutto_miesiac, bohater, kraj, stan, int(swiat.get("rok", 1)))
	swiat["podatki_rok"] = stan
	praca["ostatni_pasek"] = str(slip.get("tekst", ""))
	out["pasek_tekst"] = str(slip.get("tekst", ""))
	out["wyplata"] = int(slip.get("netto_zl", 0))
	var wypowiedzenie := int(praca.get("wypowiedzenie_zostalo", 0))
	if wypowiedzenie > 0:
		wypowiedzenie -= 1
		praca["wypowiedzenie_zostalo"] = wypowiedzenie
		if wypowiedzenie <= 0:
			out["zostaje"] = false
			var dotad := str(out.get("tekst", "")).strip_edges()
			if dotad == "":
				out["tekst"] = _zdanie_pracy(praca, "Wypowiedzenie dobiega końca.")
			else:
				out["tekst"] = dotad + " Wypowiedzenie dobiega końca."
	if str(out.get("tekst", "")) == "":
		out["tekst"] = _zdanie_pracy(praca, "Mija tydzień.")
	return out


func _zdanie_pracy(praca: Dictionary, zdanie: String) -> String:
	var nazwa := str(praca.get("nazwa", "")).strip_edges()
	if nazwa == "":
		return zdanie
	return "%s. %s" % [nazwa, zdanie]


func _mnoznik_cechy(cecha: String) -> float:
	var tab: Variant = _blok_slownika("satysfakcja_szefa").get("cechy", {})
	if tab is Dictionary and _liczba(tab.get(cecha)):
		return float(tab[cecha])
	return 1.0


func _cecha_szefa(kod: String, numer: int) -> String:
	var lista: Array = []
	var surowa: Variant = _blok_slownika("satysfakcja_szefa").get("kolejnosc_losowania", [])
	if surowa is Array:
		lista = surowa
	if lista.is_empty():
		return ""
	var indeks := posmod(kod.hash() + numer * 3, lista.size())
	return str(lista[indeks])


func _pula_wprawy(bohater: Dictionary, prefiks: String) -> Dictionary:
	if prefiks == "":
		return {}
	var magazyn: Variant = bohater.get("wprawa_zawodowa", {})
	if not (magazyn is Dictionary) or not magazyn.has(prefiks):
		return {}
	var pula: Variant = magazyn[prefiks]
	return pula if pula is Dictionary else {}


func _blok_slownika(klucz: String) -> Dictionary:
	_wczytaj()
	var blok: Variant = _rubryka.get(klucz, {})
	return blok if blok is Dictionary else {}


func _wczytaj_dialogi() -> void:
	if _dialogi_wczytane:
		return
	if not FileAccess.file_exists(PLIK_DIALOGI):
		_dialogi_wczytane = true
		_dialogi = {}
		return
	var plik := FileAccess.open(PLIK_DIALOGI, FileAccess.READ)
	if plik == null:
		return
	_dialogi_wczytane = true
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		_dialogi = dane


func _grupy_dialogu() -> Dictionary:
	_wczytaj_dialogi()
	var grupy: Variant = _dialogi.get("grupy", {})
	return grupy if grupy is Dictionary else {}


func pliki_wczytane() -> Array:
	return _pliki.duplicate()


func czy_metropolia(nazwa: String) -> bool:
	var lista: Variant = _indeks().get("miasta_metropolii", [])
	if not (lista is Array):
		return false
	var szukana := nazwa.strip_edges()
	for m in lista:
		if str(m) == szukana:
			return true
	return false


func udzial_sekcji(nazwa_obszaru: String, kod: String) -> float:
	return _udzial_w_sekcjach(_sekcje_obszaru(nazwa_obszaru, false), kod)


func udzial_miasta(nazwa_miasta: String, nazwa_wojewodztwa: String, kod: String) -> float:
	return _udzial_w_sekcjach(_sekcje_obszaru(nazwa_wojewodztwa, czy_metropolia(nazwa_miasta)), kod)


func waga_grupy_ofert(nazwa_obszaru: String, grupa: String, metropolia: bool = false) -> float:
	var wagi := _wagi_grup_z_sekcji(_sekcje_obszaru(nazwa_obszaru, metropolia))
	for w in wagi:
		if str(w.get("kod", "")) == grupa:
			return float(w.get("waga", 0.0))
	return 0.0


func _skala_puli() -> float:
	var v := float(_indeks().get("skala_puli_krajowej", 1.0))
	if v <= 0.0:
		return 1.0
	return v


func _indeks() -> Dictionary:
	return _json(PLIK_INDEKS)


func _json(sciezka: String) -> Dictionary:
	if _cache_plikow.has(sciezka):
		return _cache_plikow[sciezka]
	_pliki.append(sciezka)
	if not FileAccess.file_exists(sciezka):
		_cache_plikow[sciezka] = {}
		return {}
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		_cache_plikow[sciezka] = {}
		return {}
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	var slownik: Dictionary = dane if dane is Dictionary else {}
	_cache_plikow[sciezka] = slownik
	return slownik


func _sekcje_obszaru(nazwa_obszaru: String, metropolia: bool) -> Dictionary:
	var nazwa := nazwa_obszaru.strip_edges()
	if nazwa == "":
		nazwa = "Polska"
	var pakiet := _json(_sciezka_wojewodztwa(nazwa))
	var surowe: Variant = pakiet.get("sekcje", {})
	var sekcje := {}
	if surowe is Dictionary:
		sekcje = (surowe as Dictionary).duplicate()
	if metropolia:
		return _przesun_sekcje(sekcje)
	return sekcje


func _sciezka_wojewodztwa(nazwa: String) -> String:
	var mapa: Variant = _indeks().get("wojewodztwa", {})
	if mapa is Dictionary and str(mapa.get(nazwa, "")) != "":
		return str(mapa[nazwa])
	if mapa is Dictionary:
		return str(mapa.get("Polska", ""))
	return ""


func _przesun_sekcje(woj: Dictionary) -> Dictionary:
	var met := _json(str(_indeks().get("metropolie", "")))
	var polska: Variant = met.get("polska_sekcje", {})
	var miasta: Variant = met.get("sekcje", {})
	if not (polska is Dictionary) or not (miasta is Dictionary):
		return woj
	var out := {}
	for kod in woj.keys():
		var ps := float(polska.get(kod, 0.0))
		var ms := float(miasta.get(kod, 0.0))
		var w := float(woj.get(kod, 0.0))
		if ps <= 0.0 or ms <= 0.0 or w <= 0.0:
			continue
		out[str(kod)] = w * ms / ps
	return out


func _udzial_w_sekcjach(sekcje: Dictionary, kod: String) -> float:
	var suma := 0.0
	for k in sekcje.keys():
		suma += float(sekcje[k])
	if suma <= 0.0:
		return 0.0
	return float(sekcje.get(kod, 0.0)) / suma


func _udzial_grupy_z_zatrudnienia(nazwa_obszaru: String, grupa: String, metropolia: bool) -> float:
	var wagi := _wagi_grup_z_sekcji(_sekcje_obszaru(nazwa_obszaru, metropolia))
	var suma := 0.0
	var moja := 0.0
	for w in wagi:
		var ww := float(w.get("waga", 0.0))
		suma += ww
		if str(w.get("kod", "")) == grupa:
			moja = ww
	if suma <= 0.0:
		return 0.0
	return moja / suma


func _wagi_grup_z_sekcji(sekcje: Dictionary) -> Array:
	var acc := {}
	for g in range(1, 10):
		acc[str(g)] = 0.0
	var most: Variant = _json(str(_indeks().get("zawod_w_sekcji", ""))).get("grupy", {})
	if not (most is Dictionary):
		return []
	for kod in sekcje.keys():
		var w := float(sekcje[kod])
		if w <= 0.0:
			continue
		var wiersz: Variant = most.get(str(kod), {})
		if not (wiersz is Dictionary):
			continue
		var pub := 0.0
		for g in wiersz.keys():
			pub += float(wiersz[g])
		if pub <= 0.0:
			continue
		for g in wiersz.keys():
			acc[str(g)] = float(acc[str(g)]) + w * float(wiersz[g]) / pub
	return _lista_wag(acc)


func _lista_wag(zrodlo: Dictionary) -> Array:
	var klucze: Array = zrodlo.keys()
	klucze.sort()
	var out: Array = []
	for k in klucze:
		var w := float(zrodlo[k])
		if w <= 0.0:
			continue
		out.append({"kod": str(k), "waga": w})
	return out


func _kontekst_losowania(filtry: Dictionary, miejsca: Array, id_miejsca: String) -> Dictionary:
	var poziom := str(filtry.get("zasieg", "")).strip_edges()
	var nazwa := "Polska"
	var metro := false
	if poziom == "miasto" or poziom == "wojewodztwo":
		var karta := miasto_bohatera(miejsca, id_miejsca)
		if str(karta.get("wojewodztwo", "")) != "":
			nazwa = str(karta.get("wojewodztwo", ""))
		metro = poziom == "miasto" and czy_metropolia(str(karta.get("nazwa", "")))
	elif poziom == "polska":
		nazwa = "Polska"
	return {
		"sekcje": _sekcje_obszaru(nazwa, metro),
		"nazwa": nazwa,
		"metropolia": metro,
	}


func _losuj_oferte(ctx: Dictionary, ziarno: int, kursor: int, tydzien: int, filtry: Dictionary) -> Dictionary:
	var sekcje := {}
	if ctx.get("sekcje") is Dictionary:
		sekcje = ctx["sekcje"]
	var sekcja := ""
	var grupa := str(filtry.get("wielka_grupa", "")).strip_edges()
	if grupa == "":
		var pary := _lista_wag(sekcje)
		var wybrana := _wybierz(pary, _jednostka(ziarno, kursor, 1))
		sekcja = str(wybrana.get("kod", ""))
		var grupy := _wagi_grup_sekcji(sekcja)
		var g := _wybierz(grupy, _jednostka(ziarno, kursor, 2))
		grupa = str(g.get("kod", ""))
	else:
		var pary_g := _lista_wag(sekcje)
		var wybrana_g := _wybierz(pary_g, _jednostka(ziarno, kursor, 1))
		sekcja = str(wybrana_g.get("kod", ""))
	if grupa == "":
		return {}
	var kody := _kody_grupy(grupa)
	var kod2 := _wybierz(kody, _jednostka(ziarno, kursor, 3))
	var d2 := str(kod2.get("kod", ""))
	if d2 == "":
		return {}
	var zawody := _zawody_kodu(d2)
	if zawody.is_empty():
		return {}
	var u := _jednostka(ziarno, kursor, 4)
	var idx := mini(zawody.size() - 1, int(floor(u * float(zawody.size()))))
	var zawod: Variant = zawody[idx]
	if not (zawod is Dictionary):
		return {}
	var oferta := wytworz_oferte(zawod, tydzien, kursor)
	if oferta.is_empty():
		return {}
	oferta["sekcja_pkd"] = sekcja
	oferta["kod_2"] = d2
	oferta["losowanie"] = "grupa_z_zatrudnienia, 2digit_eurostat, ponizej_rowno"
	return oferta


func _wagi_grup_sekcji(sekcja: String) -> Array:
	var most: Variant = _json(str(_indeks().get("zawod_w_sekcji", ""))).get("grupy", {})
	if not (most is Dictionary):
		return []
	var wiersz: Variant = most.get(sekcja, {})
	if not (wiersz is Dictionary):
		return []
	return _lista_wag(wiersz)


func _kody_grupy(grupa: String) -> Array:
	var mapa: Variant = _indeks().get("grupy", {})
	if not (mapa is Dictionary):
		return []
	var blok := _json(str(mapa.get(grupa, "")))
	var kody: Variant = blok.get("kody", [])
	if not (kody is Array):
		return []
	var out: Array = []
	for k in kody:
		if k is Dictionary and int(k.get("dziesiate_tys", 0)) > 0:
			out.append({"kod": str(k.get("kod", "")), "waga": float(k.get("dziesiate_tys", 0))})
	return out


func _zawody_kodu(kod2: String) -> Array:
	var wzor := str(_indeks().get("zawody", ""))
	var sciezka := wzor.replace("{kod2}", kod2)
	var blok := _json(sciezka)
	var lista: Variant = blok.get("zawody", [])
	return lista if lista is Array else []


func _wybierz(lista: Array, u: float) -> Dictionary:
	var suma := 0.0
	for p in lista:
		if p is Dictionary:
			suma += float(p.get("waga", 0.0))
	if suma <= 0.0 or lista.is_empty():
		return {}
	var cel := clampf(u, 0.0, 0.999999) * suma
	var acc := 0.0
	for p in lista:
		if not (p is Dictionary):
			continue
		acc += float(p.get("waga", 0.0))
		if cel < acc:
			return p
	var ostatni: Variant = lista[lista.size() - 1]
	return ostatni if ostatni is Dictionary else {}


func _jednostka(ziarno: int, kursor: int, sol: int) -> float:
	var x := posmod(ziarno * 17 + kursor * 1103515245 + sol * 1013904223, 2147483647)
	return float(x) / 2147483647.0


func _limit_puli(swiat: Dictionary, filtry: Dictionary, miejsca: Array, id_miejsca: String) -> int:
	if not filtry.has("zasieg"):
		_ostatnia_pula = -1
		return -1
	var poziom := str(filtry.get("zasieg", "miasto")).strip_edges()
	var id := _id_miejsca(swiat, id_miejsca)
	var lud := ludnosc_zakresu(miejsca, poziom, id)
	var obszar := "Polska"
	var metro := false
	if poziom == "miasto" or poziom == "wojewodztwo":
		var karta := miasto_bohatera(miejsca, id)
		if str(karta.get("wojewodztwo", "")) != "":
			obszar = str(karta.get("wojewodztwo", ""))
		metro = poziom == "miasto" and czy_metropolia(str(karta.get("nazwa", "")))
	var pula := pula_ofert(lud, poziom, filtry, obszar, metro)
	_ostatnia_pula = pula
	return pula


func _id_miejsca(swiat: Dictionary, id_miejsca: String) -> String:
	var id := id_miejsca.strip_edges()
	if id != "":
		return id
	id = str(swiat.get("id_miejsca_pobytu", swiat.get("id_urodzenia", ""))).strip_edges()
	if id != "":
		return id
	var boh: Variant = swiat.get("bohater", {})
	if boh is Dictionary and boh.get("miejsce") is Dictionary:
		return str(boh["miejsce"].get("id", "")).strip_edges()
	return ""


func _oferta_na_mieszkancow() -> Dictionary:
	_wczytaj()
	var zasieg: Variant = _rubryka.get("zasieg", {})
	if not (zasieg is Dictionary):
		return {}
	var blok: Variant = zasieg.get("oferta_na_mieszkancow", {})
	return blok if blok is Dictionary else {}


func _czynniki_grup() -> Dictionary:
	_wczytaj()
	var zasieg: Variant = _rubryka.get("zasieg", {})
	if not (zasieg is Dictionary):
		return {}
	var czyn: Variant = zasieg.get("czynniki_branzy", {})
	if not (czyn is Dictionary):
		return {}
	var grupy: Variant = czyn.get("grupy", {})
	return grupy if grupy is Dictionary else {}


func _produkt_grupy(grupa: String, nadpisanie: Dictionary) -> float:
	var wiersz: Dictionary = {}
	if not nadpisanie.is_empty():
		var z_testu: Variant = nadpisanie.get(grupa, {})
		if z_testu is Dictionary:
			wiersz = z_testu
	else:
		var z_pliku: Variant = _czynniki_grup().get(grupa, {})
		if z_pliku is Dictionary:
			wiersz = z_pliku
	var nacisk := _czynnik(wiersz, "nacisk_branzy")
	var poziom_branzy := _czynnik(wiersz, "zaawansowanie")
	var brak := _czynnik(wiersz, "brak_pracownikow")
	return nacisk * poziom_branzy * brak


func _czynnik(wiersz: Dictionary, klucz: String) -> float:
	var v := 1.0
	if _liczba(wiersz.get(klucz)):
		v = float(wiersz[klucz])
	return clampf(v, 0.85, 1.15)


func _filtr_zaweza(filtry: Dictionary) -> bool:
	if str(filtry.get("tekst", "")).strip_edges() != "":
		return true
	if str(filtry.get("wielka_grupa", "")).strip_edges() != "":
		return true
	if int(filtry.get("wyksztalcenie_max", -1)) >= 0:
		return true
	if int(filtry.get("doswiadczenie_max", -1)) >= 0:
		return true
	if str(filtry.get("wplyw_stat", "")) != "" and str(filtry.get("wplyw_znak", "")) != "":
		return true
	if bool(filtry.get("filtruj_place", false)):
		if int(filtry.get("placa_od", 0)) > 0 or int(filtry.get("placa_do", 20000)) < 20000:
			return true
	return false


func _tylko_grupa(filtry: Dictionary) -> bool:
	if str(filtry.get("wielka_grupa", "")).strip_edges() == "":
		return false
	if str(filtry.get("tekst", "")).strip_edges() != "":
		return false
	if int(filtry.get("wyksztalcenie_max", -1)) >= 0:
		return false
	if int(filtry.get("doswiadczenie_max", -1)) >= 0:
		return false
	if str(filtry.get("wplyw_stat", "")) != "":
		return false
	if bool(filtry.get("filtruj_place", false)):
		if int(filtry.get("placa_od", 0)) > 0 or int(filtry.get("placa_do", 20000)) < 20000:
			return false
	return true


func _przygotuj_wagi() -> void:
	if _wagi_gotowe:
		return
	_wagi_gotowe = true
	_liczba_z_placa = 0
	_waga_grupy = {}
	var katalog = Katalog.new()
	katalog.wczytaj()
	var zawody: Variant = katalog.dane().get("zawody", [])
	if not (zawody is Array):
		return
	var lista: Array = zawody
	for z in lista:
		if not (z is Dictionary):
			continue
		var place: Variant = z.get("zarobki", null)
		if not (place is Dictionary) or not _liczba(place.get("mediana_zl")):
			continue
		_liczba_z_placa += 1
		var g := str(z.get("wielka_grupa", ""))
		_waga_grupy[g] = int(_waga_grupy.get(g, 0)) + 1


func _udzial_skanem(filtry: Dictionary) -> float:
	var klucz := "%s|%s|%d|%d|%d|%d|%s|%s" % [
		str(filtry.get("tekst", "")).strip_edges().to_lower(),
		str(filtry.get("wielka_grupa", "")).strip_edges(),
		int(filtry.get("wyksztalcenie_max", -1)),
		int(filtry.get("doswiadczenie_max", -1)),
		int(filtry.get("placa_od", 0)),
		int(filtry.get("placa_do", 20000)),
		str(filtry.get("wplyw_stat", "")),
		str(filtry.get("wplyw_znak", "")),
	]
	if klucz == _udzial_klucz:
		return _udzial_cache
	_przygotuj_wagi()
	var katalog = Katalog.new()
	katalog.wczytaj()
	var zawody: Variant = katalog.dane().get("zawody", [])
	var pas := 0
	if zawody is Array:
		var lista: Array = zawody
		for i in lista.size():
			var z: Variant = lista[i]
			if not (z is Dictionary):
				continue
			var oferta: Dictionary = wytworz_oferte(z, 1, i)
			if oferta.is_empty() or not pasuje(oferta, filtry):
				continue
			pas += 1
	var u := 0.0
	if _liczba_z_placa > 0:
		u = float(pas) / float(_liczba_z_placa)
	_udzial_klucz = klucz
	_udzial_cache = u
	return u


func _suma_ludnosci(miejsca: Array, wojewodztwo: String) -> int:
	## Pusty wojewodztwo = cała Polska. Nazwa = tylko ten obszar, miasta i reszta powiatów.
	var woj := wojewodztwo.strip_edges()
	var suma := 0
	for m in miejsca:
		if not (m is Dictionary):
			continue
		if not _to_polska(m):
			continue
		if woj != "" and str(m.get("wojewodztwo", "")) != woj:
			continue
		suma += _lud(m)
	return suma


func _to_polska(miasto: Dictionary) -> bool:
	var pid := str(miasto.get("panstwo_id", "")).strip_edges().to_lower()
	if pid == "polska":
		return true
	var pan := str(miasto.get("panstwo", "")).strip_edges().to_lower()
	if pan == "polska":
		return true
	if pid == "" and pan == "" and str(miasto.get("wojewodztwo", "")).strip_edges() != "":
		return true
	return false


func _lud(miasto: Dictionary) -> int:
	if _liczba(miasto.get("ludnosc")):
		return maxi(0, int(miasto["ludnosc"]))
	if _liczba(miasto.get("liczba_mieszkancow")):
		return maxi(0, int(miasto["liczba_mieszkancow"]))
	return 0


func _miejsce_po_id(miejsca: Array, id_miejsca: String) -> Dictionary:
	for m in miejsca:
		if m is Dictionary and str(m.get("id", "")) == id_miejsca:
			return m
	return {}


func _siedziba_id(id_reszty: String) -> String:
	if id_reszty == "":
		return ""
	var sciezka := "res://świat/polska/reszta_powiatu/%s.json" % id_reszty
	if not FileAccess.file_exists(sciezka):
		return ""
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return ""
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		return str(dane.get("siedziba_id", "")).strip_edges()
	return ""


func _karta_miasta(miasto: Dictionary, brak: bool) -> Dictionary:
	return {
		"id": str(miasto.get("id", "")),
		"nazwa": str(miasto.get("nazwa", "")),
		"ludnosc": _lud(miasto),
		"wojewodztwo": str(miasto.get("wojewodztwo", "")),
		"brak": brak,
	}


func _brak_miasta() -> Dictionary:
	return {"id": "", "nazwa": "", "ludnosc": 0, "wojewodztwo": "", "brak": true}


func _wczytaj() -> void:
	if _wczytana:
		return
	if not FileAccess.file_exists(PLIK):
		_wczytana = true
		_rubryka = {}
		return
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return
	_wczytana = true
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if not (dane is Dictionary):
		return
	_rubryka = dane


func _liczba(v: Variant) -> bool:
	return v is int or v is float


func _liczba_albo(v: Variant, domysl: int) -> int:
	if _liczba(v):
		return int(v)
	return domysl
