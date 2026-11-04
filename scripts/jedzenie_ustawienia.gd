extends Control
class_name JedzenieUstawienia

## Stan zatwierdzony i roboczy. Nie liczy nic co klatkę.
## Zbiorcze plusy i minusy nie zależą od trybu napisów.
## Pieniądze są w złotych. Suwaki i diety zapisują się także przy rodzicach.

const PLIK := "res://postacie/jedzenie_ustawienia.json"
const PLIK_ZIARNA := "res://postacie/losowanie/ziarno_rodzicow.json"
const PLIK_BOHATERA := "res://postacie/bohater.json"
const PLIK_ZAKUPOW := "res://postacie/zakupy_rodzicow.json"
const PLIK_WYLOSOWANEJ := "res://postacie/wylosowana.json"
const PANEL := "Scroll/PanelJedzenia/"
const ZIELONY := "#2f9e45"
const KRWISTY := "#9d0610"
const UWAGA_GOTOWANIA := "Uwaga: powrotne wyłączenie tej opcji osłabia relacje z rodzicami, oraz prowadzi do powolnej utraty wprawy w gotowaniu."
const STATYSTYKI: Array[String] = [
	"samopoczucie", "zdrowie", "zeby", "sylwetka", "kondycja", "zadowolenie_rodzicow", "zdrowe_zywienie",
]
const NAZWA_STAT := {
	"samopoczucie": "samopoczucie",
	"zdrowie": "zdrowie",
	"zeby": "zęby",
	"sylwetka": "sylwetka",
	"kondycja": "kondycja",
	"zadowolenie_rodzicow": "zadowolenie rodziców",
	"zdrowe_zywienie": "zdrowe żywienie",
}
const MAPA_POL := {
	"pozycja": [],
	"cena": ["cena", "cena_ustawiona"],
	"skladniki": ["skladniki", "skladniki_ustawione"],
	"dbanie_o_skladniki": ["skladniki", "skladniki_ustawione"],
	"diety": ["wegetarianska", "weganska", "dieta_ogolna", "dieta_ogolna_ustawiona"],
	"wegetarianska": ["wegetarianska"],
	"weganska": ["weganska"],
	"dieta_ogolna": ["dieta_ogolna", "dieta_ogolna_ustawiona"],
	"dieta_wlasna": ["dieta_wlasna", "dieta_wlasna_ustawiona"],
}
const POLA_CENY: Array[String] = ["cena", "cena_ustawiona"]
const POLA_SKLADNIKOW: Array[String] = ["skladniki", "skladniki_ustawione"]
const POLA_DIETY: Array[String] = ["wegetarianska", "weganska"]
const POLA_DIETY_OGOLNEJ: Array[String] = ["wegetarianska", "weganska", "dieta_ogolna", "dieta_ogolna_ustawiona"]
const POLA_DIETY_WLASNEJ: Array[String] = ["dieta_wlasna", "dieta_wlasna_ustawiona"]

var _dane: Variant = null
var _zatwierdzony: Dictionary = {}
var _roboczy: Dictionary = {}
var _start_rodzicow: Dictionary = {}
var _tryb_napisow := "przy_wyborze"
var _ostatnia_opcja := ""
var _stan_gotowy := false
var _podlaczone := false
var _cisza := false
var _konflikty: Array = []
var _kwestia_odblokowana := false
var _zbicie_zatwierdzone := 0
var _ile_razy := 0
var _cechy_rodzicow: Array = []
var _pieniadze_zl: Variant = null
var _pieniadze_znane := false
var _pieniadze_wczytane := false
var _komunikat := ""
var _wplyw_zjedzone: Dictionary = {}
var _pozycje_zbudowane := false
var _relacja_komunikat := ""
var _wprawa: WprawaGotowania
var _zakupy: Dictionary = {}
var _cechy_bohatera: Array = []
var _ile_wybrane: Dictionary = {}
var _efekt_gotowania := ""
var _pokaz_uwage := false
var _gotowanie_obnizone := false
var _wiersze: Dictionary = {}


func wczytaj() -> Variant:
	if _dane is Dictionary:
		return _dane
	_dane = _czytaj(PLIK)
	return _dane


func opis_widoczny(tryb: String, gracz_wlasnie_zmienia: bool) -> bool:
	if tryb == "wylaczone":
		return false
	if tryb == "ciagle":
		return true
	if tryb == "przy_wyborze":
		return gracz_wlasnie_zmienia
	return false


func opis_opcji_widoczny(tryb: String, gracz_wlasnie_zmienia: bool) -> bool:
	return opis_widoczny(tryb, gracz_wlasnie_zmienia)


func zbiorcze_widoczne(_tryb: String = "") -> bool:
	return true


func dieta_skuteczna(wegetarianska: bool, weganska: bool) -> String:
	if weganska:
		return "weganska"
	if wegetarianska:
		return "wegetarianska"
	return "brak"


func zapewnij_stan() -> void:
	if _stan_gotowy:
		return
	_stan_gotowy = true
	wczytaj()
	if _wprawa == null:
		_wprawa = WprawaGotowania.new()
		_wprawa.wczytaj()
	_wczytaj_zakupy()
	_wczytaj_cechy_bohatera()
	_wczytaj_pieniadze()
	var ziarno: Dictionary = {}
	var surowe: Variant = _czytaj(PLIK_ZIARNA)
	if surowe is Dictionary:
		ziarno = surowe
	_tryb_napisow = str(_slownik().get("wyswietlanie_wplywu", "przy_wyborze"))
	ustaw_warunki_startowe(ziarno)


func ustaw_warunki_startowe(ziarno: Dictionary) -> Dictionary:
	var reguly := zastosuj_warunki_rodzicow(ziarno)
	var stan := _stan_pusty()
	_nanies_reguly(stan, reguly)
	_cechy_rodzicow = _cechy_ziarna(ziarno)
	_start_rodzicow = _zrzut_rodzicow(stan)
	_zatwierdzony = stan.duplicate(true)
	_roboczy = stan.duplicate(true)
	_konflikty = []
	_kwestia_odblokowana = false
	_zbicie_zatwierdzone = 0
	_ile_razy = 0
	_ostatnia_opcja = ""
	_wplyw_zjedzone = {}
	_komunikat = ""
	_relacja_komunikat = ""
	_efekt_gotowania = ""
	_pokaz_uwage = false
	_gotowanie_obnizone = false
	_odswiez_ui()
	return reguly


func zastosuj_warunki_rodzicow(ziarno: Dictionary) -> Dictionary:
	var cena := {"wartosc": null, "kierunek": null, "powod": ""}
	var skladniki := {"wartosc": null, "kierunek": null, "powod": ""}
	var wege := false
	var weganie := false
	if _flaga(ziarno, "biedniejsi"):
		cena["kierunek"] = "tanio"
		cena["powod"] = "Reguła: biedniejsi idą w stronę tanio. Liczby suwaka nie ustawiono."
	elif _prog_mowi_tanio(ziarno):
		cena["kierunek"] = "tanio"
		cena["powod"] = "Próg zamożności już jest i zarobki są poniżej. Kierunek tanio. Liczby suwaka nie dopisano."
	elif not _jest_liczba(_kwota_zarobkow(ziarno)):
		if _jest_liczba(_prog(ziarno)):
			cena["powod"] = "Próg zamożności jest, ale zarobki są null. Suwaka ceny nie zgadywano."
		else:
			cena["powod"] = "Zarobki są null. Suwaka ceny nie ustawiono."
	else:
		cena["powod"] = "Jest kwota zarobków, nie ma flagi biedniejsi ani spełnionego progu. Kierunku nie zgadywano. Suwak zostaje null."
	if _flaga(ziarno, "dba_o_zdrowie"):
		skladniki["kierunek"] = "w_gore"
		skladniki["powod"] = "Cecha: dba o zdrowie. Kierunek składników w górę, bez liczby."
	else:
		skladniki["powod"] = "Brak cechy dba o zdrowie w ziarnie. Suwaka składników nie ustawiono."
	if _flaga(ziarno, "weganie") or _flaga(ziarno, "weganin") or _flaga(ziarno, "weganska"):
		weganie = true
	elif _flaga(ziarno, "wegetarianie") or _flaga(ziarno, "wegetarianin") or _flaga(ziarno, "wegetarianska"):
		wege = true
	return {
		"cena": cena,
		"skladniki": skladniki,
		"wegetarianska": wege,
		"weganska": weganie,
		"dieta_skuteczna": dieta_skuteczna(wege, weganie),
		"waga_wegetarian": null,
		"waga_wegan": null,
	}


func wplyw_stanu(stan: Dictionary, z_garami: bool) -> Dictionary:
	zapewnij_stan()
	var suma: Dictionary = {}
	if z_garami:
		if bool(stan.get("cena_ustawiona", false)) and _jest_liczba(stan.get("cena")):
			_dolacz(suma, _wplyw_suwaka("cena", float(stan["cena"])))
		if bool(stan.get("skladniki_ustawione", false)) and _jest_liczba(stan.get("skladniki")):
			_dolacz(suma, _wplyw_suwaka("dbanie_o_skladniki", float(stan["skladniki"])))
		var dieta := dieta_skuteczna(bool(stan.get("wegetarianska", false)), bool(stan.get("weganska", false)))
		if dieta == "weganska" or dieta == "wegetarianska":
			_dolacz(suma, _wplyw_bloku(_blok_diety(dieta)))
	return suma


func zbiorcze() -> Dictionary:
	zapewnij_stan()
	return _roznica(wplyw_stanu(_roboczy, true), wplyw_stanu(_zatwierdzony, true))


func tekst_zbiorczych() -> String:
	var wplyw := zbiorcze()
	var linie: PackedStringArray = []
	if wplyw.is_empty():
		linie.append("Wynik zmian: brak niezatwierdzonych zmian")
	else:
		linie.append("Wynik zmian: " + _tekst_znakow(wplyw))
	if _zmiana_denerwuje():
		if _spadek_trwa():
			linie.append("Po zatwierdzeniu zadowolenie rodziców spadnie: " + str(_tryb_spadku().get("napis", "")))
		else:
			linie.append("Rodzice już się przyzwyczaili. Tego zatwierdzenia spadek nie dotyczy.")
	linie.append(tekst_zlotowek())
	if not _wplyw_zjedzone.is_empty():
		linie.append("Zjedzone (do poprawki, to nie statystyka): " + _tekst_znakow(_wplyw_zjedzone))
	if _komunikat != "":
		linie.append(_komunikat)
	return "\n".join(linie)


func tekst_zlotowek() -> String:
	zapewnij_stan()
	if not _pieniadze_znane or not _jest_liczba(_pieniadze_zl):
		return "Złotówki: nieustawione"
	return "Złotówki: %d zł" % int(_pieniadze_zl)


func tekst_licznika() -> String:
	zapewnij_stan()
	var prog: Variant = _blok_zdenerwowania().get("po_ilu_razach_spadek_znika", null)
	var o_progu := "Próg przyzwyczajenia nie jest ustawiony. Spadek jest za każdym razem."
	if _jest_liczba(prog):
		o_progu = "Próg przyzwyczajenia: %s." % str(int(prog))
	return "Ile już razy: %d. Łączny spadek zadowolenia: %d. %s" % [_ile_razy, absi(_zbicie_zatwierdzone), o_progu]


func tekst_spadku_charakteru() -> String:
	zapewnij_stan()
	var teraz := str(_tryb_spadku().get("napis", ""))
	return "Spadek według charakteru: %s. Zwyczajnie: 1. Nadopiekuńczy: 3 albo 4, równe koło. Inne cechy: nieustawione, na razie 1." % teraz


func zatwierdz() -> Dictionary:
	zapewnij_stan()
	var denerwuje := _zmiana_denerwuje()
	var kwestia := ""
	var spadek := 0
	if denerwuje:
		kwestia = _tresc_kwestii()
		_kwestia_odblokowana = true
		spadek = _nalicz_spadek("zatwierdzenie")
	for pole in _pola_zapisu():
		if _roboczy.has(pole):
			_zatwierdzony[pole] = _roboczy[pole]
	_odswiez_ui()
	return {
		"konflikt": denerwuje,
		"kwestia": kwestia,
		"kwestia_dostepna": kwestia_dostepna(),
		"cofniecie": false,
		"zbicie_zadowolenia_rodzicow": _zbicie_zatwierdzone,
		"ile_razy": _ile_razy,
		"spadek_tym_razem": spadek,
		"gar": gar_rodzicow(),
	}


func ustaw_suwak(id: String, wartosc: Variant) -> void:
	zapewnij_stan()
	if not _jest_liczba(wartosc):
		return
	if id == "cena":
		_roboczy["cena"] = int(wartosc)
		_roboczy["cena_ustawiona"] = true
		_ostatnia_opcja = "cena"
	elif id == "skladniki" or id == "dbanie_o_skladniki":
		_roboczy["skladniki"] = int(wartosc)
		_roboczy["skladniki_ustawione"] = true
		_ostatnia_opcja = "skladniki"
	_odswiez_ui()


func ustaw_diete(id: String, wlaczona: bool) -> void:
	zapewnij_stan()
	if id == "weganska" or id == "weganie" or id == "weganin":
		_roboczy["weganska"] = wlaczona
		if wlaczona:
			_roboczy["wegetarianska"] = false
		_ostatnia_opcja = "weganska"
	elif id == "wegetarianska" or id == "wegetarianie" or id == "wegetarianin":
		if bool(_roboczy.get("weganska", false)) and wlaczona:
			_roboczy["wegetarianska"] = false
		else:
			_roboczy["wegetarianska"] = wlaczona
		_ostatnia_opcja = "wegetarianska"
	_odswiez_ui()


func ustaw_gotowanie(wlaczona: bool) -> void:
	ustaw_dni_gotowania(7 if wlaczona else 0)


func ustaw_dni_gotowania(dni: int) -> void:
	zapewnij_stan()
	var bylo := int(_roboczy.get("dni_gotowania", 0))
	var teraz := clampi(dni, 0, 7)
	_roboczy["dni_gotowania"] = teraz
	_zatwierdzony["dni_gotowania"] = teraz
	_roboczy["gotowanie_dla_rodziny"] = teraz > 0
	_zatwierdzony["gotowanie_dla_rodziny"] = teraz > 0
	_ostatnia_opcja = "dni_gotowania"
	_gotowanie_obnizone = teraz < bylo
	if teraz > bylo:
		var plusy := 0
		if _wprawa != null:
			plusy = _wprawa.plusy_za_dni(teraz)
		_efekt_gotowania = _bb_plusow(plusy)
		if teraz > 0:
			_efekt_gotowania += "\n[color=%s]Dieta nie złości rodziców[/color]" % ZIELONY
		_pokaz_uwage = true
	elif teraz < bylo:
		var ubylo := 0
		var minusy := 1
		if _wprawa != null:
			ubylo = _wprawa.plusy_za_dni(bylo) - _wprawa.plusy_za_dni(teraz)
			minusy = ubylo + _wprawa.minus_dodatkowy()
		if minusy < 1:
			minusy = 1
		_efekt_gotowania = _bb_minusow(minusy, "zadowolenie rodziców")
		_efekt_gotowania += "\n[color=%s]Powolna utrata wprawy w gotowaniu.[/color]" % KRWISTY
		_pokaz_uwage = false
	_odswiez_ui()


func ustaw_diete_suwak(id: String, wartosc: Variant) -> void:
	zapewnij_stan()
	if not _jest_liczba(wartosc):
		return
	if id == "dieta_ogolna":
		_roboczy["dieta_ogolna"] = int(wartosc)
		_roboczy["dieta_ogolna_ustawiona"] = true
		_ostatnia_opcja = "dieta_ogolna"
	elif id == "dieta_wlasna" or id == "dieta_gotowania_wlasnego":
		_roboczy["dieta_wlasna"] = int(wartosc)
		_roboczy["dieta_wlasna_ustawiona"] = true
		_ostatnia_opcja = "dieta_wlasna"
	_odswiez_ui()


func ustaw_z_losowania(bohater: Dictionary, rodzina: Dictionary) -> void:
	zapewnij_stan()
	var cechy := _cechy_bohatera_z(bohater)
	if not cechy.is_empty():
		_cechy_bohatera = cechy
	ustaw_warunki_startowe(rodzina)
	# Szablon bohater.json ma pieniadze: null — bierzemy kwotę z wylosowanej karty.
	if _jest_liczba(bohater.get("pieniadze")):
		_ustaw_pieniadze_sesji(bohater.get("pieniadze"))


func zapis_relacji_gotowania(poprawa: Variant, spadek: Variant) -> Dictionary:
	zapewnij_stan()
	if _jest_liczba(poprawa) and _jest_liczba(spadek) and not (float(spadek) > float(poprawa)):
		return {
			"zapisano": false,
			"powod": "Spadek przy wyłączeniu ma być większy niż poprawa przy włączeniu.",
		}
	if _dane is Dictionary:
		var blok: Dictionary = _blok_gotowania()
		if not (_dane.get("gotowanie_dla_rodziny") is Dictionary):
			_dane["gotowanie_dla_rodziny"] = blok
		blok["poprawa_przy_wlaczeniu"] = poprawa
		blok["spadek_przy_wylaczeniu"] = spadek
		_dane["gotowanie_dla_rodziny"] = blok
	return {"zapisano": true, "powod": ""}


func koszt_tygodnia_gotowania() -> Dictionary:
	zapewnij_stan()
	var dni := int(_roboczy.get("dni_gotowania", 0))
	if _wprawa == null:
		return {"aktywne": dni > 0, "tura": "tydzien", "energia": null, "czas": null, "dni": dni}
	var wynik: Dictionary = _wprawa.koszt(dni, _cechy_bohatera)
	wynik["aktywne"] = dni > 0
	wynik["tura"] = "tydzien"
	return wynik


func zjedz(id: String) -> Dictionary:
	zapewnij_stan()
	var pozycja := _pozycja(id)
	if pozycja.is_empty():
		_komunikat = "Nie ma takiej pozycji."
		_odswiez_ui()
		return {"kupiono": false, "komunikat": _komunikat}
	if _pozycja_zablokowana(id):
		var kupno := _stan_zakupu(id)
		_komunikat = "Rodzice nie kupili. " + str(kupno.get("powod", "cecha nieustawiona"))
		_odswiez_ui()
		return {"kupiono": false, "komunikat": _komunikat}
	var ile := int(_ile_wybrane.get(id, 0))
	if ile < 1:
		_komunikat = ""
		_odswiez_ui()
		return {"kupiono": false, "komunikat": "", "zjedzone": 0}
	var zjedzone := 0
	var ostatni := {"kupiono": false, "komunikat": ""}
	for _krok in ile:
		ostatni = _zjedz_raz(id, pozycja)
		if not bool(ostatni.get("kupiono", false)):
			break
		zjedzone += 1
	if zjedzone > 0:
		_komunikat = "Zjedzone: %s × %d." % [str(pozycja.get("nazwa", id)), zjedzone]
		if zjedzone < ile and str(ostatni.get("komunikat", "")) != "":
			_komunikat += " " + str(ostatni.get("komunikat"))
	elif str(ostatni.get("komunikat", "")) != "":
		_komunikat = str(ostatni.get("komunikat"))
	_odswiez_ui()
	ostatni["zjedzone"] = zjedzone
	ostatni["komunikat"] = _komunikat
	return ostatni


func _zjedz_raz(id: String, pozycja: Dictionary) -> Dictionary:
	var cena: Variant = pozycja.get("cena_zl", null)
	if not _jest_liczba(cena):
		return {"kupiono": false, "komunikat": "brak ceny"}
	var kwota := int(cena)
	if kwota < 0:
		return {"kupiono": false, "komunikat": "brak ceny"}
	if kwota > 0:
		if not _pieniadze_znane or not _jest_liczba(_pieniadze_zl) or int(_pieniadze_zl) < kwota:
			return {"kupiono": false, "komunikat": "nie masz tyle pieniędzy"}
		_pieniadze_zl = int(_pieniadze_zl) - kwota
		if int(_pieniadze_zl) < 0:
			_pieniadze_zl = 0
	var spadek := 0
	if str(pozycja.get("gdzie", "")) == "sam" and _rodzice_decyduja():
		spadek = _nalicz_spadek("jedzenie_poza_domem")
	_dolacz(_wplyw_zjedzone, _wplyw_pozycji(pozycja))
	return {"kupiono": true, "komunikat": "", "spadek": spadek, "ile_razy": _ile_razy, "id": id}


func ustaw_tryb_napisow(tryb: String) -> void:
	zapewnij_stan()
	if tryb != "wylaczone" and tryb != "ciagle" and tryb != "przy_wyborze":
		return
	_tryb_napisow = tryb
	_odswiez_ui()


func ustaw_kto_decyduje(kto: String) -> void:
	zapewnij_stan()
	if _dane is Dictionary:
		_dane["kto_decyduje"] = kto
	_odswiez_ui()


func pokaz_ustawienia() -> void:
	var scroll := get_node_or_null("Scroll")
	if scroll != null:
		scroll.visible = true
	_odswiez_ui()


func stan_zatwierdzony() -> Dictionary:
	zapewnij_stan()
	return _zatwierdzony.duplicate(true)


func stan_roboczy() -> Dictionary:
	zapewnij_stan()
	return _roboczy.duplicate(true)


func odczyt_statystyk() -> Dictionary:
	zapewnij_stan()
	var cechy: Array = []
	for id in _cechy_rodzicow:
		cechy.append(str(id))
	return {
		"pieniadze": _pieniadze_zl if _pieniadze_znane else null,
		"cena": _zatwierdzony.get("cena"),
		"cena_ustawiona": bool(_zatwierdzony.get("cena_ustawiona", false)),
		"skladniki": _zatwierdzony.get("skladniki"),
		"skladniki_ustawione": bool(_zatwierdzony.get("skladniki_ustawione", false)),
		"wegetarianska": bool(_zatwierdzony.get("wegetarianska", false)),
		"weganska": bool(_zatwierdzony.get("weganska", false)),
		"zadowolenie_rodzicow": _zbicie_zatwierdzone,
		"zdrowe_zywienie": int(_wplyw_zjedzone.get("zdrowe_zywienie", 0)),
		"dni_gotowania": int(_zatwierdzony.get("dni_gotowania", 0)),
		"cechy_rodzicow": cechy,
	}


func zakres_suwaka(id: String) -> Dictionary:
	zapewnij_stan()
	var klucz := "dbanie_o_skladniki" if id == "skladniki" else id
	var blok := _suwak(klucz)
	return {"min": blok.get("min", 0), "max": blok.get("max", 100)}


func cechy_charakteru_dostepne() -> Array:
	zapewnij_stan()
	var blok: Variant = _slownik().get("zdenerwowanie_rodzicow", {})
	if blok is Dictionary and blok.get("cechy") is Array:
		return (blok["cechy"] as Array).duplicate(true)
	return []


func zastosuj_statystyki(zapis: Dictionary) -> void:
	zapewnij_stan()
	if zapis.has("pieniadze"):
		_ustaw_pieniadze_sesji(zapis.get("pieniadze"))
	if zapis.has("cena_ustawiona"):
		if bool(zapis.get("cena_ustawiona")) and _jest_liczba(zapis.get("cena")):
			_roboczy["cena"] = int(zapis["cena"])
			_roboczy["cena_ustawiona"] = true
		else:
			_roboczy["cena"] = null
			_roboczy["cena_ustawiona"] = false
	if zapis.has("skladniki_ustawione"):
		if bool(zapis.get("skladniki_ustawione")) and _jest_liczba(zapis.get("skladniki")):
			_roboczy["skladniki"] = int(zapis["skladniki"])
			_roboczy["skladniki_ustawione"] = true
		else:
			_roboczy["skladniki"] = null
			_roboczy["skladniki_ustawione"] = false
	if zapis.has("weganska"):
		_roboczy["weganska"] = zapis.get("weganska") == true
	if zapis.has("wegetarianska"):
		_roboczy["wegetarianska"] = zapis.get("wegetarianska") == true and not bool(_roboczy.get("weganska", false))
	for pole in ["cena", "cena_ustawiona", "skladniki", "skladniki_ustawione", "wegetarianska", "weganska"]:
		_zatwierdzony[pole] = _roboczy[pole]
	_start_rodzicow = _zrzut_rodzicow(_zatwierdzony)
	if _jest_liczba(zapis.get("zadowolenie_rodzicow")):
		_zbicie_zatwierdzone = int(zapis["zadowolenie_rodzicow"])
	if zapis.has("cecha_rodzica"):
		var id := str(zapis.get("cecha_rodzica", ""))
		if id == "":
			_cechy_rodzicow = []
		else:
			_cechy_rodzicow = [id]
	_odswiez_ui()


func _ustaw_pieniadze_sesji(wartosc: Variant) -> void:
	_pieniadze_wczytane = true
	if _jest_liczba(wartosc):
		_pieniadze_zl = maxi(int(wartosc), 0)
		_pieniadze_znane = true
	else:
		_pieniadze_zl = null
		_pieniadze_znane = false


func gar_rodzicow() -> Dictionary:
	zapewnij_stan()
	return {
		"cena": _zatwierdzony.get("cena"),
		"cena_ustawiona": _zatwierdzony.get("cena_ustawiona"),
		"skladniki": _zatwierdzony.get("skladniki"),
		"skladniki_ustawione": _zatwierdzony.get("skladniki_ustawione"),
		"wegetarianska": _zatwierdzony.get("wegetarianska"),
		"weganska": _zatwierdzony.get("weganska"),
		"dieta_skuteczna": dieta_skuteczna(
			bool(_zatwierdzony.get("wegetarianska", false)),
			bool(_zatwierdzony.get("weganska", false))
		),
	}


func kwestia_dostepna() -> bool:
	zapewnij_stan()
	return _ujemny_skutek_ustawien_domu()


func zdanie_domu() -> String:
	zapewnij_stan()
	if not _ujemny_skutek_ustawien_domu():
		return ""
	return _tresc_kwestii()


func pozycje_gdzie(gdzie: String) -> Array:
	zapewnij_stan()
	var wynik: Array = []
	for pozycja in _pozycje():
		if pozycja is Dictionary and str(pozycja.get("gdzie", "")) == gdzie:
			wynik.append(pozycja)
	return wynik


func bb_pozycji(id: String) -> String:
	zapewnij_stan()
	return _bb_wplywu_pozycji(_pozycja(id))


func bb_znakow(wplyw: Dictionary) -> String:
	zapewnij_stan()
	var czesci: PackedStringArray = []
	for stat in STATYSTYKI:
		if not wplyw.has(stat) or not _jest_liczba(wplyw[stat]):
			continue
		var n := int(wplyw[stat])
		if n == 0:
			continue
		var nazwa := str(NAZWA_STAT.get(stat, stat))
		if n < 0:
			czesci.append("[color=%s]%s %s[/color]" % [KRWISTY, nazwa, _znaki(n)])
		else:
			czesci.append("[color=%s]%s %s[/color]" % [ZIELONY, nazwa, _znaki(n)])
	return ", ".join(czesci)


func tekst_rodzicow_przy(id: String) -> String:
	zapewnij_stan()
	return _tekst_stanu_domu(id)


func ilosc_pozycji(id: String) -> int:
	return int(_ile_wybrane.get(id, 0))


func ustaw_ilosc_pozycji(id: String, ile: int) -> void:
	_ile_wybrane[id] = clampi(ile, 0, 99)
	_odswiez_ui()


func dni_gotowania() -> int:
	zapewnij_stan()
	return int(_roboczy.get("dni_gotowania", 0))


func efekt_gotowania_tekst() -> String:
	zapewnij_stan()
	return _efekt_gotowania


func zrzut_zapisu() -> Dictionary:
	zapewnij_stan()
	return {
		"roboczy": _roboczy.duplicate(true),
		"zatwierdzony": _zatwierdzony.duplicate(true),
		"start_rodzicow": _start_rodzicow.duplicate(true),
		"pieniadze": _pieniadze_zl,
		"pieniadze_znane": _pieniadze_znane,
		"cechy_rodzicow": _cechy_rodzicow.duplicate(),
		"cechy_bohatera": _cechy_bohatera.duplicate(),
		"ile": _ile_wybrane.duplicate(true),
		"zbicie": _zbicie_zatwierdzone,
		"ile_razy": _ile_razy,
		"tryb_napisow": _tryb_napisow,
		"gotowanie_obnizone": _gotowanie_obnizone,
	}


func wczytaj_zrzut(dane: Dictionary) -> void:
	zapewnij_stan()
	if dane.get("roboczy") is Dictionary:
		_roboczy = (dane["roboczy"] as Dictionary).duplicate(true)
	if dane.get("zatwierdzony") is Dictionary:
		_zatwierdzony = (dane["zatwierdzony"] as Dictionary).duplicate(true)
	if dane.get("start_rodzicow") is Dictionary:
		_start_rodzicow = (dane["start_rodzicow"] as Dictionary).duplicate(true)
	_pieniadze_wczytane = true
	if bool(dane.get("pieniadze_znane", false)) and _jest_liczba(dane.get("pieniadze")):
		_pieniadze_zl = int(dane["pieniadze"])
		_pieniadze_znane = true
	else:
		_pieniadze_zl = null
		_pieniadze_znane = false
	if dane.get("cechy_rodzicow") is Array:
		_cechy_rodzicow = (dane["cechy_rodzicow"] as Array).duplicate()
	if dane.get("cechy_bohatera") is Array:
		_cechy_bohatera = (dane["cechy_bohatera"] as Array).duplicate()
	_ile_wybrane = {}
	if dane.get("ile") is Dictionary:
		for klucz in (dane["ile"] as Dictionary).keys():
			var ile_v: Variant = dane["ile"][klucz]
			if _jest_liczba(ile_v):
				_ile_wybrane[str(klucz)] = int(ile_v)
	if _jest_liczba(dane.get("zbicie")):
		_zbicie_zatwierdzone = int(dane["zbicie"])
	if _jest_liczba(dane.get("ile_razy")):
		_ile_razy = int(dane["ile_razy"])
	if str(dane.get("tryb_napisow", "")) != "":
		_tryb_napisow = str(dane["tryb_napisow"])
	_gotowanie_obnizone = dane.get("gotowanie_obnizone") == true
	_odswiez_ui()


func kwestia_tresc() -> String:
	zapewnij_stan()
	return _tresc_kwestii()


func konflikty() -> Array:
	zapewnij_stan()
	return _konflikty.duplicate(true)


func zbicie_zadowolenia() -> int:
	zapewnij_stan()
	return _zbicie_zatwierdzone


func ile_razy_zdenerwowania() -> int:
	zapewnij_stan()
	return _ile_razy


func _ready() -> void:
	zapewnij_stan()
	_podlacz_ui()
	_odswiez_ui()


func _podlacz_ui() -> void:
	if _podlaczone or not has_node("Gora/Zatwierdz"):
		return
	_podlaczone = true
	var przycisk_zatwierdz := get_node_or_null("Gora/Zatwierdz") as Button
	if przycisk_zatwierdz != null:
		przycisk_zatwierdz.pressed.connect(_on_zatwierdz_klik)
	var zamknij := get_node_or_null("Gora/Zamknij") as Button
	if zamknij != null:
		zamknij.pressed.connect(_on_zamknij)
	var rozwin := get_node_or_null("Rzad/RozwinJedzenie") as Button
	if rozwin != null:
		rozwin.pressed.connect(_on_rozwin)
	var zebatka := get_node_or_null("Rzad/ZebatkaJedzenie") as Button
	if zebatka != null:
		var id := "zebatka_jedzenie"
		var blok: Variant = _slownik().get("zebatka", {})
		if blok is Dictionary and str(blok.get("id", "")) != "":
			id = str(blok.get("id"))
		zebatka.set_meta("kontekst_zebatki", id)
		zebatka.pressed.connect(_on_zebatka)
	var grupa := ButtonGroup.new()
	grupa.allow_unpress = false
	for sciezka in ["PanelZebatki/Wnetrze/TrybWylaczone/Przycisk", "PanelZebatki/Wnetrze/TrybCiagle/Przycisk", "PanelZebatki/Wnetrze/TrybPrzyWyborze/Przycisk"]:
		var tryb := get_node_or_null(sciezka) as Button
		if tryb != null:
			tryb.toggle_mode = true
			tryb.button_group = grupa
			tryb.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_polacz_pressed("PanelZebatki/Wnetrze/TrybWylaczone/Przycisk", _on_tryb_wylaczone)
	_polacz_pressed("PanelZebatki/Wnetrze/TrybCiagle/Przycisk", _on_tryb_ciagle)
	_polacz_pressed("PanelZebatki/Wnetrze/TrybPrzyWyborze/Przycisk", _on_tryb_przy_wyborze)
	var cena := get_node_or_null(PANEL + "Cena") as HSlider
	if cena != null:
		_konfiguruj_suwak(cena, _suwak("cena"))
		cena.value_changed.connect(_on_cena)
	var skladniki := get_node_or_null(PANEL + "Skladniki") as HSlider
	if skladniki != null:
		_konfiguruj_suwak(skladniki, _suwak("dbanie_o_skladniki"))
		skladniki.value_changed.connect(_on_skladniki)
	var wege := get_node_or_null(PANEL + "Wegetarianska") as CheckButton
	if wege != null:
		wege.toggled.connect(_on_wegetarianska)
	var weganska := get_node_or_null(PANEL + "Weganska") as CheckButton
	if weganska != null:
		weganska.toggled.connect(_on_weganska)
	var dieta_ogolna := get_node_or_null(PANEL + "DietaOgolna") as HSlider
	if dieta_ogolna != null:
		_konfiguruj_suwak(dieta_ogolna, _suwak_diety("dieta_ogolna_suwak"))
		dieta_ogolna.value_changed.connect(_on_dieta_ogolna)
	var dieta_wlasna := get_node_or_null(PANEL + "DietaWlasna") as HSlider
	if dieta_wlasna != null:
		_konfiguruj_suwak(dieta_wlasna, _suwak_diety("dieta_gotowania_wlasnego_suwak"))
		dieta_wlasna.value_changed.connect(_on_dieta_wlasna)
	for dzien in 8:
		_polacz_pressed(PANEL + "Dni/D%d/Liczba" % dzien, _on_dzien.bind(dzien))
		_polacz_pressed(PANEL + "Dni/D%d/KropkaKlik" % dzien, _on_dzien.bind(dzien))
		var srodek := get_node_or_null(PANEL + "Dni/D%d/KropkaKlik/Srodek" % dzien)
		if srodek != null:
			_mysz_obok(srodek)
	_zbuduj_pozycje()


func _on_zatwierdz_klik() -> void:
	zatwierdz()


func _on_zamknij() -> void:
	visible = false


func _on_rozwin() -> void:
	var scroll := get_node_or_null("Scroll")
	if scroll != null:
		scroll.visible = not scroll.visible


func _on_zebatka() -> void:
	var panel := get_node_or_null("PanelZebatki")
	if panel != null:
		panel.visible = not panel.visible


func _on_tryb_wylaczone() -> void:
	if _cisza:
		return
	ustaw_tryb_napisow("wylaczone")


func _on_tryb_ciagle() -> void:
	if _cisza:
		return
	ustaw_tryb_napisow("ciagle")


func _on_tryb_przy_wyborze() -> void:
	if _cisza:
		return
	ustaw_tryb_napisow("przy_wyborze")


func _on_cena(wartosc: float) -> void:
	if _cisza:
		return
	ustaw_suwak("cena", int(wartosc))


func _on_skladniki(wartosc: float) -> void:
	if _cisza:
		return
	ustaw_suwak("skladniki", int(wartosc))


func _on_wegetarianska(wlaczona: bool) -> void:
	if _cisza:
		return
	ustaw_diete("wegetarianska", wlaczona)


func _on_weganska(wlaczona: bool) -> void:
	if _cisza:
		return
	ustaw_diete("weganska", wlaczona)


func _on_dieta_ogolna(wartosc: float) -> void:
	if _cisza:
		return
	ustaw_diete_suwak("dieta_ogolna", int(wartosc))


func _on_dieta_wlasna(wartosc: float) -> void:
	if _cisza:
		return
	ustaw_diete_suwak("dieta_wlasna", int(wartosc))


func _on_dzien(dzien: int) -> void:
	if _cisza:
		return
	ustaw_dni_gotowania(dzien)


func _on_pozycja(id: String) -> void:
	if _cisza:
		return
	zjedz(id)


func _odswiez_ui() -> void:
	if not has_node("Zbiorcze"):
		return
	_cisza = true
	_sync_kontrolki()
	_sync_tryb()
	_cisza = false
	_odswiez_napisy()


func _sync_kontrolki() -> void:
	var wege := get_node_or_null(PANEL + "Wegetarianska") as CheckButton
	if wege != null:
		wege.set_pressed_no_signal(bool(_roboczy.get("wegetarianska", false)))
	var weganska := get_node_or_null(PANEL + "Weganska") as CheckButton
	if weganska != null:
		weganska.set_pressed_no_signal(bool(_roboczy.get("weganska", false)))
	_sync_suwak(PANEL + "Cena", "cena", "cena_ustawiona")
	_sync_suwak(PANEL + "Skladniki", "skladniki", "skladniki_ustawione")
	_sync_suwak(PANEL + "DietaOgolna", "dieta_ogolna", "dieta_ogolna_ustawiona")
	_sync_suwak(PANEL + "DietaWlasna", "dieta_wlasna", "dieta_wlasna_ustawiona")
	_sync_dni()


func _sync_suwak(sciezka: String, pole: String, flaga: String) -> void:
	var suwak := get_node_or_null(sciezka) as HSlider
	if suwak == null or not bool(_roboczy.get(flaga, false)):
		return
	if _jest_liczba(_roboczy.get(pole)):
		suwak.set_value_no_signal(float(_roboczy[pole]))


func _sync_dni() -> void:
	var wybrane := int(_roboczy.get("dni_gotowania", 0))
	for dzien in 8:
		var duza := get_node_or_null(PANEL + "Dni/D%d/KropkaKlik/Srodek/Duza" % dzien)
		if duza != null:
			duza.visible = dzien == wybrane


func _sync_tryb() -> void:
	var mapa := {
		"wylaczone": "PanelZebatki/Wnetrze/TrybWylaczone",
		"ciagle": "PanelZebatki/Wnetrze/TrybCiagle",
		"przy_wyborze": "PanelZebatki/Wnetrze/TrybPrzyWyborze",
	}
	for klucz in mapa.keys():
		var korzen := str(mapa[klucz])
		var przycisk := get_node_or_null(korzen + "/Przycisk") as Button
		if przycisk != null:
			przycisk.set_pressed_no_signal(klucz == _tryb_napisow)
		var biala := get_node_or_null(korzen + "/Kropki/Biala")
		if biala != null:
			biala.visible = klucz == _tryb_napisow


func _odswiez_napisy() -> void:
	var pary := [
		["CenaOpis", "cena"],
		["SkladnikiOpis", "skladniki"],
		["WegetarianskaOpis", "wegetarianska"],
		["WeganskaOpis", "weganska"],
	]
	for para in pary:
		var napis := get_node_or_null(PANEL + str(para[0])) as Label
		if napis == null:
			continue
		napis.text = _tekst_opcji(str(para[1]))
		napis.visible = opis_widoczny(_tryb_napisow, _ostatnia_opcja == str(para[1]))
	var kwestia := get_node_or_null("Kwestia") as Label
	if kwestia != null:
		var jest := kwestia_dostepna()
		kwestia.text = kwestia_tresc() if jest else ""
		kwestia.visible = jest
	var zbiorcze_napis := get_node_or_null("Zbiorcze") as RichTextLabel
	if zbiorcze_napis != null:
		zbiorcze_napis.visible = zbiorcze_widoczne(_tryb_napisow)
		zbiorcze_napis.text = tekst_zbiorczych()
	var efekt := get_node_or_null(PANEL + "EfektGotowania") as RichTextLabel
	if efekt != null:
		efekt.visible = _efekt_gotowania != ""
		efekt.text = "Efekt:\n" + _efekt_gotowania if _efekt_gotowania != "" else ""
	var uwaga := get_node_or_null(PANEL + "UwagaGotowania") as Label
	if uwaga != null:
		uwaga.visible = _pokaz_uwage
		uwaga.text = UWAGA_GOTOWANIA
		uwaga.add_theme_color_override("font_color", Color(0.616, 0.024, 0.063))
	var wprawa := get_node_or_null(PANEL + "WprawaNapis") as Label
	if wprawa != null and _wprawa != null:
		wprawa.visible = true
		wprawa.text = _wprawa.tekst_stanu(int(_roboczy.get("dni_gotowania", 0)), _cechy_bohatera)
	_odswiez_wiersze()
	var pieniadze := get_node_or_null(PANEL + "PieniadzeStan") as Label
	if pieniadze != null:
		pieniadze.visible = true
		pieniadze.text = tekst_zlotowek()
	var licznik := get_node_or_null(PANEL + "LicznikPrzyzwyczajenia") as Label
	if licznik != null:
		licznik.visible = true
		licznik.text = tekst_licznika()
	var spadek := get_node_or_null(PANEL + "SpadekCharakter") as Label
	if spadek != null:
		spadek.visible = true
		spadek.text = tekst_spadku_charakteru()
	var komunikat := get_node_or_null(PANEL + "Komunikat") as Label
	if komunikat != null:
		komunikat.visible = _komunikat != ""
		komunikat.text = _komunikat


func _tekst_opcji(id: String) -> String:
	if id == "cena":
		return _tekst_suwaka("cena", "Tanio", "Drogo")
	if id == "skladniki":
		return _tekst_suwaka("dbanie_o_skladniki", "Nieważne", "Pilnuję")
	if id == "wegetarianska" or id == "weganska":
		return _tekst_diety(id)
	return ""


func _tekst_suwaka(id_json: String, nazwa_min: String, nazwa_max: String) -> String:
	var blok := _suwak(id_json)
	var linie: PackedStringArray = []
	var opis := str(blok.get("wplyw", ""))
	if opis != "":
		linie.append(opis)
	var na_min := _tekst_znakow(blok.get("wplyw_min", {}))
	var na_max := _tekst_znakow(blok.get("wplyw_max", {}))
	if na_min != "":
		linie.append("%s: %s" % [nazwa_min, na_min])
	if na_max != "":
		linie.append("%s: %s" % [nazwa_max, na_max])
	var klucz_powod := "cena_powod" if id_json == "cena" else "skladniki_powod"
	var klucz_kier := "cena_kierunek" if id_json == "cena" else "skladniki_kierunek"
	var klucz_ust := "cena_ustawiona" if id_json == "cena" else "skladniki_ustawione"
	if not bool(_roboczy.get(klucz_ust, false)):
		if _roboczy.get(klucz_kier) != null:
			linie.append("Kierunek: %s." % str(_roboczy.get(klucz_kier)))
		var powod := str(_roboczy.get(klucz_powod, ""))
		if powod != "":
			linie.append(powod)
	return "\n".join(linie)


func _tekst_diety(id: String) -> String:
	var blok := _blok_diety(id)
	var tekst := str(blok.get("wplyw_tekst", ""))
	var znaki := _tekst_znakow(blok.get("wplyw", {}))
	if znaki == "":
		return tekst
	return tekst + "\n" + znaki


func _tekst_gotowania() -> String:
	if _wprawa == null:
		return ""
	return _wprawa.tekst_stanu(int(_roboczy.get("dni_gotowania", 0)), _cechy_bohatera)


func _tekst_znakow(wplyw: Variant) -> String:
	if not (wplyw is Dictionary):
		return ""
	var czesci: PackedStringArray = []
	for stat in STATYSTYKI:
		if stat == "pieniadze":
			continue
		if not wplyw.has(stat):
			continue
		if not _jest_liczba(wplyw[stat]):
			continue
		var n := int(wplyw[stat])
		if n == 0:
			continue
		czesci.append("%s %s" % [str(NAZWA_STAT.get(stat, stat)), _znaki(n)])
	return ", ".join(czesci)


func _znaki(n: int) -> String:
	var ile := absi(n)
	var znak := "+" if n > 0 else "-"
	var tekst := ""
	for _i in ile:
		tekst += znak
	return tekst


func _stan_pusty() -> Dictionary:
	var blok := _blok_gotowania()
	var dni := 0
	if _jest_liczba(blok.get("dni")):
		dni = clampi(int(blok.get("dni")), 0, 7)
	elif blok.get("wlaczona") == true:
		dni = 7
	return {
		"gotowanie_dla_rodziny": dni > 0,
		"dni_gotowania": dni,
		"cena": null,
		"cena_ustawiona": false,
		"cena_kierunek": null,
		"cena_powod": "",
		"skladniki": null,
		"skladniki_ustawione": false,
		"skladniki_kierunek": null,
		"skladniki_powod": "",
		"wegetarianska": false,
		"weganska": false,
		"dieta_ogolna": null,
		"dieta_ogolna_ustawiona": false,
		"dieta_wlasna": null,
		"dieta_wlasna_ustawiona": false,
	}


func _nanies_reguly(stan: Dictionary, reguly: Dictionary) -> void:
	var cena: Dictionary = reguly.get("cena", {})
	stan["cena"] = cena.get("wartosc", null)
	stan["cena_ustawiona"] = _jest_liczba(stan["cena"])
	stan["cena_kierunek"] = cena.get("kierunek")
	stan["cena_powod"] = str(cena.get("powod", ""))
	var sklad: Dictionary = reguly.get("skladniki", {})
	stan["skladniki"] = sklad.get("wartosc", null)
	stan["skladniki_ustawione"] = _jest_liczba(stan["skladniki"])
	stan["skladniki_kierunek"] = sklad.get("kierunek")
	stan["skladniki_powod"] = str(sklad.get("powod", ""))
	stan["weganska"] = reguly.get("weganska") == true
	stan["wegetarianska"] = reguly.get("wegetarianska") == true and not bool(stan["weganska"])


func _zrzut_rodzicow(stan: Dictionary) -> Dictionary:
	return {
		"cena": stan.get("cena"),
		"cena_ustawiona": stan.get("cena_ustawiona"),
		"skladniki": stan.get("skladniki"),
		"skladniki_ustawione": stan.get("skladniki_ustawione"),
		"wegetarianska": stan.get("wegetarianska"),
		"weganska": stan.get("weganska"),
		"dieta_ogolna": stan.get("dieta_ogolna"),
		"dieta_ogolna_ustawiona": stan.get("dieta_ogolna_ustawiona"),
		"dieta_wlasna": stan.get("dieta_wlasna"),
		"dieta_wlasna_ustawiona": stan.get("dieta_wlasna_ustawiona"),
	}


func _wplyw_suwaka(id: String, wartosc: float) -> Dictionary:
	var blok := _suwak(id)
	var min_v := float(blok.get("min", 0))
	var max_v := float(blok.get("max", 100))
	var t := 0.0
	if max_v != min_v:
		t = clampf((wartosc - min_v) / (max_v - min_v), 0.0, 1.0)
	var na_min: Dictionary = blok.get("wplyw_min", {})
	var na_max: Dictionary = blok.get("wplyw_max", {})
	var wynik: Dictionary = {}
	for stat in STATYSTYKI:
		if stat == "pieniadze":
			continue
		var a := int(na_min.get(stat, 0)) if _jest_liczba(na_min.get(stat)) else 0
		var b := int(na_max.get(stat, 0)) if _jest_liczba(na_max.get(stat)) else 0
		if a == 0 and b == 0:
			continue
		var n := int(round(a + (b - a) * t))
		if n != 0:
			wynik[stat] = n
	return wynik


func _wplyw_bloku(blok: Dictionary) -> Dictionary:
	var wynik: Dictionary = {}
	var wplyw: Variant = blok.get("wplyw", {})
	if not (wplyw is Dictionary):
		return wynik
	for stat in STATYSTYKI:
		if stat == "pieniadze":
			continue
		if _jest_liczba(wplyw.get(stat)) and int(wplyw[stat]) != 0:
			wynik[stat] = int(wplyw[stat])
	return wynik


func _dolacz(suma: Dictionary, dodatek: Dictionary) -> void:
	for stat in STATYSTYKI:
		if not dodatek.has(stat):
			continue
		var n := int(dodatek[stat])
		if n == 0:
			continue
		suma[stat] = int(suma.get(stat, 0)) + n


func _roznica(teraz: Dictionary, bylo: Dictionary) -> Dictionary:
	var wynik: Dictionary = {}
	for stat in STATYSTYKI:
		var n := int(teraz.get(stat, 0)) - int(bylo.get(stat, 0))
		if n != 0:
			wynik[stat] = n
	return wynik


func _rodzice_decyduja() -> bool:
	return str(_slownik().get("kto_decyduje", "rodzice")) == "rodzice"


func _zmiana_denerwuje() -> bool:
	if not _rodzice_decyduja():
		return false
	var cena := _rozni(_roboczy, _zatwierdzony, POLA_CENY) and _rozni(_roboczy, _start_rodzicow, POLA_CENY)
	var sklad := _rozni(_roboczy, _zatwierdzony, POLA_SKLADNIKOW) and _rozni(_roboczy, _start_rodzicow, POLA_SKLADNIKOW)
	var ogolna := _rozni(_roboczy, _zatwierdzony, POLA_DIETY_OGOLNEJ) and _rozni(_roboczy, _start_rodzicow, POLA_DIETY_OGOLNEJ)
	var wlasna := false
	if int(_roboczy.get("dni_gotowania", 0)) <= 0:
		wlasna = _rozni(_roboczy, _zatwierdzony, POLA_DIETY_WLASNEJ) and _rozni(_roboczy, _start_rodzicow, POLA_DIETY_WLASNEJ)
	return cena or sklad or ogolna or wlasna


func _rozni(a: Dictionary, b: Dictionary, pola: Array) -> bool:
	for pole in pola:
		if a.get(pole) != b.get(pole):
			return true
	return false


func _pola_zapisu() -> Array:
	var pola: Array = []
	for pole in _pola_bohatera():
		if not pola.has(pole):
			pola.append(pole)
	for pole in _pola_rodzicow():
		if not pola.has(pole):
			pola.append(pole)
	for pole in ["gotowanie_dla_rodziny", "dni_gotowania", "dieta_ogolna", "dieta_ogolna_ustawiona", "dieta_wlasna", "dieta_wlasna_ustawiona", "cena_kierunek", "cena_powod", "skladniki_kierunek", "skladniki_powod"]:
		if not pola.has(pole):
			pola.append(pole)
	return pola


func _pola_bohatera() -> Array:
	return _pola_z_listy(_slownik().get("zakres_bohatera"), ["pozycja"])


func _pola_rodzicow() -> Array:
	return _pola_z_listy(_slownik().get("zakres_rodzicow"), ["cena", "skladniki", "diety"])


func _pola_z_listy(lista: Variant, domyslne: Array) -> Array:
	var zrodlo: Array = domyslne
	if lista is Array:
		zrodlo = lista
	var pola: Array = []
	for id in zrodlo:
		var mapped: Variant = MAPA_POL.get(str(id), [str(id)])
		for pole in mapped:
			if not pola.has(pole):
				pola.append(pole)
	return pola


func _nalicz_spadek(powod: String) -> int:
	var n := 0
	if _spadek_trwa():
		n = _ile_spadku()
		_zbicie_zatwierdzone -= n
	_ile_razy += 1
	_konflikty.append({
		"powod": powod,
		"spadek": n,
		"cofniecie": false,
		"kwestia": _tresc_kwestii() if powod == "zatwierdzenie" else "",
	})
	return n


func _spadek_trwa() -> bool:
	var prog: Variant = _blok_zdenerwowania().get("po_ilu_razach_spadek_znika", null)
	if not _jest_liczba(prog):
		return true
	return _ile_razy < int(prog)


func _ile_spadku() -> int:
	var tryb := _tryb_spadku()
	if str(tryb.get("rodzaj", "")) == "widelki":
		var widelki: Array = tryb.get("widelki", [])
		if widelki.size() >= 2 and _jest_liczba(widelki[0]) and _jest_liczba(widelki[1]):
			if randi() % 2 == 0:
				return int(widelki[0])
			return int(widelki[1])
	if _jest_liczba(tryb.get("liczba")):
		return int(tryb["liczba"])
	return _domyslny_spadek()


func _tryb_spadku() -> Dictionary:
	for id in _cechy_rodzicow:
		var wpis := _wpis_spadku(str(id))
		var widelki := _widelki_wpisu(wpis)
		if not widelki.is_empty():
			return {
				"rodzaj": "widelki",
				"widelki": widelki,
				"liczba": null,
				"napis": "%s: %s albo %s" % [str(wpis.get("nazwa", id)), str(int(widelki[0])), str(int(widelki[1]))],
			}
	for id in _cechy_rodzicow:
		var wpis := _wpis_spadku(str(id))
		if _jest_liczba(wpis.get("spadek")):
			return {
				"rodzaj": "liczba",
				"widelki": [],
				"liczba": int(wpis.get("spadek")),
				"napis": "%s: %s" % [str(wpis.get("nazwa", id)), str(int(wpis.get("spadek")))],
			}
	return {
		"rodzaj": "nieustawione",
		"widelki": [],
		"liczba": _domyslny_spadek(),
		"napis": _napis_nieustawione(),
	}


func _domyslny_spadek() -> int:
	var gdy: Variant = _blok_zdenerwowania().get("gdy_spadek_null", {})
	if gdy is Dictionary and _jest_liczba(gdy.get("traktuj_jak")):
		return int(gdy.get("traktuj_jak"))
	return 1


func _napis_nieustawione() -> String:
	var gdy: Variant = _blok_zdenerwowania().get("gdy_spadek_null", {})
	if gdy is Dictionary and str(gdy.get("napis", "")) != "":
		return str(gdy.get("napis"))
	return "nieustawione, na razie 1"


func _wpis_spadku(id: String) -> Dictionary:
	for wpis in _lista_spadkow():
		if wpis is Dictionary and str(wpis.get("id", "")) == id:
			return wpis
	return {}


func _widelki_wpisu(wpis: Dictionary) -> Array:
	var widelki: Variant = wpis.get("spadek_widelki", null)
	if widelki is Array and widelki.size() >= 2 and _jest_liczba(widelki[0]) and _jest_liczba(widelki[1]):
		return widelki
	return []


func _lista_spadkow() -> Array:
	var blok: Variant = _blok_zdenerwowania().get("cechy", [])
	if blok is Array:
		return blok
	return []


func _ujemny_skutek_ustawien_domu() -> bool:
	if _gotowanie_obnizone:
		return true
	if _zmiana_denerwuje():
		return true
	var wplyw := zbiorcze()
	for stat in wplyw.keys():
		if _jest_liczba(wplyw[stat]) and int(wplyw[stat]) < 0:
			return true
	return false


func _tresc_kwestii() -> String:
	return "Ale to ja robię jedzenie..."


func _suwak(id: String) -> Dictionary:
	var suwaki: Variant = _slownik().get("suwaki", {})
	if suwaki is Dictionary and suwaki.get(id) is Dictionary:
		return suwaki[id]
	return {}


func _blok_diety(id: String) -> Dictionary:
	var diety: Variant = _slownik().get("diety", {})
	if diety is Dictionary and diety.get(id) is Dictionary:
		return diety[id]
	return {}


func _blok_gotowania() -> Dictionary:
	var blok: Variant = _slownik().get("gotowanie_dla_rodziny", {})
	if blok is Dictionary:
		return blok
	return {}


func _blok_zdenerwowania() -> Dictionary:
	var blok: Variant = _slownik().get("zdenerwowanie_rodzicow", {})
	if blok is Dictionary:
		return blok
	return {}


func _pary_relacji_gotowania() -> Dictionary:
	var blok := _blok_gotowania()
	var poprawa: Variant = blok.get("poprawa_przy_wlaczeniu", null)
	var spadek: Variant = blok.get("spadek_przy_wylaczeniu", null)
	var odrzucone := _jest_liczba(poprawa) and _jest_liczba(spadek) and not (float(spadek) > float(poprawa))
	return {"poprawa": poprawa, "spadek": spadek, "odrzucone": odrzucone}


func _pozycje() -> Array:
	var lista: Variant = _slownik().get("pozycje", [])
	if lista is Array:
		return lista
	return []


func _pozycja(id: String) -> Dictionary:
	for pozycja in _pozycje():
		if pozycja is Dictionary and str(pozycja.get("id", "")) == id:
			return pozycja
	return {}


func _zbuduj_pozycje() -> void:
	if _pozycje_zbudowane:
		return
	var pudlo := get_node_or_null(PANEL + "Pozycje") as VBoxContainer
	if pudlo == null:
		return
	_pozycje_zbudowane = true
	for pozycja in _pozycje():
		if not (pozycja is Dictionary):
			continue
		var id := str(pozycja.get("id", ""))
		_ile_wybrane[id] = 0
		var wiersz := HBoxContainer.new()
		wiersz.add_theme_constant_override("separation", 8)
		var lewa := VBoxContainer.new()
		lewa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var przycisk := Button.new()
		przycisk.alignment = HORIZONTAL_ALIGNMENT_LEFT
		przycisk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		przycisk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		przycisk.add_theme_font_size_override("font_size", 15)
		przycisk.pressed.connect(_on_pozycja.bind(id))
		var efekty := RichTextLabel.new()
		efekty.bbcode_enabled = true
		efekty.fit_content = true
		efekty.scroll_active = false
		efekty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		efekty.add_theme_font_size_override("normal_font_size", 14)
		var stan := Label.new()
		stan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lewa.add_child(przycisk)
		lewa.add_child(efekty)
		lewa.add_child(stan)
		var prawa := HBoxContainer.new()
		prawa.add_theme_constant_override("separation", 4)
		var licznik := Label.new()
		licznik.text = "x0"
		licznik.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(36, 32)
		plus.pressed.connect(_on_wiecej.bind(id))
		var minus := Button.new()
		minus.text = "−"
		minus.custom_minimum_size = Vector2(36, 32)
		minus.pressed.connect(_on_mniej.bind(id))
		# Lewy −, prawy +
		prawa.add_child(minus)
		prawa.add_child(licznik)
		prawa.add_child(plus)
		wiersz.add_child(lewa)
		wiersz.add_child(prawa)
		pudlo.add_child(wiersz)
		_wiersze[id] = {"przycisk": przycisk, "efekty": efekty, "stan": stan, "licznik": licznik}


func _tekst_przycisku_pozycji(pozycja: Dictionary) -> String:
	var cena: Variant = pozycja.get("cena_zl", null)
	var cena_txt := "— zł"
	var dopisek := ""
	if _jest_liczba(cena):
		cena_txt = "%d zł" % int(cena)
	else:
		dopisek = ", brak ceny"
	var gdzie := "w domu" if str(pozycja.get("gdzie", "")) == "dom" else "sam"
	return "%s, %s, %s%s" % [str(pozycja.get("nazwa", "")), gdzie, cena_txt, dopisek]


func _konfiguruj_suwak(wezel: HSlider, blok: Dictionary) -> void:
	wezel.min_value = float(blok.get("min", 0))
	wezel.max_value = float(blok.get("max", 100))
	wezel.step = 1.0
	wezel.set_value_no_signal(wezel.min_value)


func _polacz_pressed(sciezka: String, cel: Callable) -> void:
	var przycisk := get_node_or_null(sciezka) as Button
	if przycisk != null:
		przycisk.pressed.connect(cel)


func _wczytaj_pieniadze() -> void:
	if _pieniadze_wczytane:
		return
	_pieniadze_wczytane = true
	# Najpierw aktualna wylosowana karta (ma liczbę), nie szablon bohater.json (null).
	var bohater: Variant = _czytaj(PLIK_WYLOSOWANEJ)
	if not (bohater is Dictionary and _jest_liczba(bohater.get("pieniadze"))):
		bohater = _czytaj(PLIK_BOHATERA)
	if bohater is Dictionary and _jest_liczba(bohater.get("pieniadze")):
		_pieniadze_zl = int(bohater.get("pieniadze"))
		_pieniadze_znane = true
		if int(_pieniadze_zl) < 0:
			_pieniadze_zl = 0
	else:
		_pieniadze_zl = null
		_pieniadze_znane = false


func _flaga(ziarno: Dictionary, id: String) -> bool:
	if ziarno.get(id) == true:
		return true
	var wyzyw: Variant = ziarno.get("wyzywienie")
	if wyzyw is Dictionary and wyzyw.get(id) == true:
		return true
	return _ma_ceche(_cechy_ziarna(ziarno), [id])


func _cechy_ziarna(ziarno: Dictionary) -> Array:
	var wynik: Array = []
	_dopisz_cechy(wynik, ziarno.get("cechy"))
	_dopisz_cechy(wynik, ziarno.get("charakter"))
	var blok: Variant = ziarno.get("charakter_rodzicow")
	if blok is Dictionary:
		_dopisz_cechy(wynik, blok.get("cechy"))
	return wynik


func _dopisz_cechy(wynik: Array, blok: Variant) -> void:
	if not (blok is Array):
		return
	for pozycja in blok:
		if pozycja is Dictionary and pozycja.has("id"):
			wynik.append(str(pozycja["id"]))
		elif pozycja is String:
			wynik.append(pozycja)


func _ma_ceche(cechy: Array, ids: Array) -> bool:
	for cecha in cechy:
		if ids.has(str(cecha)):
			return true
	return false


func _kwota_zarobkow(ziarno: Dictionary) -> Variant:
	var blok: Variant = ziarno.get("zarobki")
	if blok is Dictionary and _jest_liczba(blok.get("kwota")):
		return blok.get("kwota")
	return null


func _prog(ziarno: Dictionary) -> Variant:
	if _jest_liczba(ziarno.get("prog_zamoznosci")):
		return ziarno.get("prog_zamoznosci")
	var wyzyw: Variant = ziarno.get("wyzywienie")
	if wyzyw is Dictionary and _jest_liczba(wyzyw.get("prog_zamoznosci")):
		return wyzyw.get("prog_zamoznosci")
	var zar: Variant = ziarno.get("zarobki")
	if zar is Dictionary and _jest_liczba(zar.get("prog_zamoznosci")):
		return zar.get("prog_zamoznosci")
	return null


func _prog_mowi_tanio(ziarno: Dictionary) -> bool:
	var kwota: Variant = _kwota_zarobkow(ziarno)
	var prog: Variant = _prog(ziarno)
	if not _jest_liczba(kwota) or not _jest_liczba(prog):
		return false
	return float(kwota) < float(prog)


func _bb_plusow(ile: int) -> String:
	if ile <= 0:
		return "[color=%s]zadowolenie rodziców bez plusa[/color]" % ZIELONY
	return "[color=%s]zadowolenie rodziców %s[/color]" % [ZIELONY, _znaki(ile)]


func _bb_minusow(ile: int, nazwa: String) -> String:
	return "[color=%s]%s %s[/color]" % [KRWISTY, nazwa, _znaki(-absi(ile))]


func _suwak_diety(klucz: String) -> Dictionary:
	var blok: Variant = _slownik().get(klucz, {})
	if blok is Dictionary:
		return blok
	return {"min": 0, "max": 100}


func _wczytaj_zakupy() -> void:
	if not _zakupy.is_empty():
		return
	var surowe: Variant = _czytaj(PLIK_ZAKUPOW)
	if surowe is Dictionary:
		_zakupy = surowe


func _wczytaj_cechy_bohatera() -> void:
	if not _cechy_bohatera.is_empty():
		return
	var surowe: Variant = _czytaj(PLIK_WYLOSOWANEJ)
	if surowe is Dictionary:
		_cechy_bohatera = _cechy_bohatera_z(surowe)


func _cechy_bohatera_z(bohater: Dictionary) -> Array:
	var wynik: Array = []
	for klucz in ["cecha_1", "cecha_2", "cecha_3"]:
		var blok: Variant = bohater.get(klucz)
		if blok is Dictionary and str(blok.get("id", "")) != "":
			wynik.append(str(blok.get("id")))
	_dopisz_cechy(wynik, bohater.get("cechy"))
	return wynik


func _pozycja_zablokowana(id: String) -> bool:
	if id != "przekaska_dom" and id != "slodkie_dom":
		return false
	return not bool(_stan_zakupu(id).get("kupione", false))


func _stan_zakupu(id_pozycji: String) -> Dictionary:
	var klucz := ""
	if id_pozycji == "przekaska_dom":
		klucz = "slona_przekaska"
	elif id_pozycji == "slodkie_dom":
		klucz = "cos_slodkiego"
	elif id_pozycji == "warzywa_dom":
		klucz = "warzywa"
	else:
		return {"kupione": true, "powod": "", "dotyczy": false}
	if _cechy_rodzicow.is_empty():
		return {"kupione": false, "powod": "cecha nieustawiona", "dotyczy": true}
	var kupione := false
	var powod := "cecha nieustawiona"
	var byl_zapis := false
	for id in _cechy_rodzicow:
		var wpis := _wpis_zakupu(str(id))
		if wpis.is_empty():
			continue
		var kupuje: Variant = wpis.get("kupuje", null)
		if not (kupuje is Dictionary):
			continue
		if not kupuje.has(klucz) or kupuje.get(klucz) == null:
			continue
		byl_zapis = true
		if kupuje.get(klucz) == true:
			kupione = true
			if str(wpis.get("dlaczego", "")) != "":
				powod = str(wpis.get("dlaczego"))
		elif not kupione:
			powod = str(wpis.get("dlaczego", "cecha nieustawiona"))
			if powod == "":
				powod = "cecha nieustawiona"
	if not byl_zapis:
		powod = "cecha nieustawiona"
	return {"kupione": kupione, "powod": powod, "dotyczy": true}


func _wpis_zakupu(id: String) -> Dictionary:
	var lista: Variant = _zakupy.get("cechy", [])
	if not (lista is Array):
		return {}
	for wpis in lista:
		if wpis is Dictionary and str(wpis.get("id", "")) == id:
			return wpis
	return {}


func _wplyw_pozycji(pozycja: Dictionary) -> Dictionary:
	if bool(pozycja.get("zalezy_od_suwaka_skladnikow_odzywczych", false)):
		return _wplyw_cieplego(pozycja)
	return _wplyw_bloku(pozycja)


func _wplyw_cieplego(pozycja: Dictionary) -> Dictionary:
	var wynik := _wplyw_z_mapy(pozycja.get("wplyw_wspolny", {}))
	if not bool(_roboczy.get("skladniki_ustawione", false)) or not _jest_liczba(_roboczy.get("skladniki")):
		return wynik
	var prog := 50
	if _jest_liczba(pozycja.get("prog_wysoki")):
		prog = int(pozycja.get("prog_wysoki"))
	var wartosc := int(_roboczy.get("skladniki"))
	if wartosc > prog:
		_dolacz(wynik, _wplyw_z_mapy(pozycja.get("gdy_zdrowe", {})))
	elif wartosc < prog:
		_dolacz(wynik, _wplyw_z_mapy(pozycja.get("gdy_niezdrowe", {})))
	return wynik


func _wplyw_z_mapy(mapa: Variant) -> Dictionary:
	if not (mapa is Dictionary):
		return {}
	return _wplyw_bloku({"wplyw": mapa})


func _ocena_cieplego(pozycja: Dictionary) -> String:
	if not bool(_roboczy.get("skladniki_ustawione", false)) or not _jest_liczba(_roboczy.get("skladniki")):
		return "suwak składników odżywczych nieustawiony"
	var prog := 50
	if _jest_liczba(pozycja.get("prog_wysoki")):
		prog = int(pozycja.get("prog_wysoki"))
	var wartosc := int(_roboczy.get("skladniki"))
	if wartosc > prog:
		return "zdrowe"
	if wartosc < prog:
		return "niezdrowe"
	return "środek"


func _bb_wplywu_pozycji(pozycja: Dictionary) -> String:
	var wplyw := _wplyw_pozycji(pozycja)
	var maly := bool(pozycja.get("minus_samopoczucia_maly", false))
	var czesci: PackedStringArray = []
	for stat in STATYSTYKI:
		if not wplyw.has(stat) or not _jest_liczba(wplyw[stat]):
			continue
		var n := int(wplyw[stat])
		if n == 0:
			continue
		var nazwa := str(NAZWA_STAT.get(stat, stat))
		var znaki := _znaki(n)
		if n < 0 and stat == "samopoczucie" and maly:
			czesci.append("[color=%s][font_size=11]%s %s[/font_size][/color]" % [KRWISTY, nazwa, znaki])
		elif n < 0:
			czesci.append("[color=%s]%s %s[/color]" % [KRWISTY, nazwa, znaki])
		else:
			czesci.append("[color=%s]%s %s[/color]" % [ZIELONY, nazwa, znaki])
	var linia := ", ".join(czesci)
	if bool(pozycja.get("zalezy_od_suwaka_skladnikow_odzywczych", false)):
		var ocena := _ocena_cieplego(pozycja)
		var kolor := ZIELONY if ocena == "zdrowe" else KRWISTY if ocena == "niezdrowe" else "#dddddd"
		if linia != "":
			linia += "\n"
		linia += "[color=%s]%s[/color]" % [kolor, ocena]
	return linia


func _tekst_stanu_domu(id: String) -> String:
	if id != "przekaska_dom" and id != "slodkie_dom" and id != "warzywa_dom":
		return ""
	var kupno := _stan_zakupu(id)
	if bool(kupno.get("kupione", false)):
		return "W domu: są"
	return "Rodzice nie kupili. " + str(kupno.get("powod", "cecha nieustawiona"))


func _odswiez_wiersze() -> void:
	for pozycja in _pozycje():
		if not (pozycja is Dictionary):
			continue
		var id := str(pozycja.get("id", ""))
		var wiersz: Variant = _wiersze.get(id, {})
		if not (wiersz is Dictionary):
			continue
		var przycisk: Variant = wiersz.get("przycisk")
		if przycisk is Button:
			przycisk.text = _tekst_przycisku_pozycji(pozycja)
		var efekty: Variant = wiersz.get("efekty")
		if efekty is RichTextLabel:
			efekty.text = _bb_wplywu_pozycji(pozycja)
		var stan: Variant = wiersz.get("stan")
		if stan is Label:
			var tekst := _tekst_stanu_domu(id)
			stan.text = tekst
			stan.visible = tekst != ""
		var licznik: Variant = wiersz.get("licznik")
		if licznik is Label:
			licznik.text = "x%d" % int(_ile_wybrane.get(id, 0))


func _on_wiecej(id: String) -> void:
	var n := int(_ile_wybrane.get(id, 0)) + 1
	if n > 99:
		n = 99
	_ile_wybrane[id] = n
	_odswiez_wiersze()


func _on_mniej(id: String) -> void:
	var n := int(_ile_wybrane.get(id, 0)) - 1
	if n < 0:
		n = 0
	_ile_wybrane[id] = n
	_odswiez_wiersze()


func _mysz_obok(wezel: Node) -> void:
	if wezel is Control:
		(wezel as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for dziecko in wezel.get_children():
		_mysz_obok(dziecko)


func _slownik() -> Dictionary:
	if _dane is Dictionary:
		return _dane
	return {}


func _jest_liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
