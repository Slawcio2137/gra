extends RefCounted
class_name Losowanie

## Jedno losowanie na start. Bez pętli co klatkę, także na telefonie.
## Koło świata poza Polską jest puste, dopóki nie ma ludności.

const PLIK_KOL := "res://postacie/losowanie/kolo_swiata.json"
const PLIK_CECH := "res://postacie/cechy_charakteru.json"
const PLIK_INTELIGENCJI := "res://postacie/inteligencja.json"
const PLIK_CHOROB := "res://postacie/zdrowie/od_urodzenia.json"
const PLIK_ZAROBKOW := "res://postacie/losowanie/zarobki.json"
const PLIK_TERENU := "res://postacie/losowanie/teren.json"
const PLIK_WYNIKU := "res://postacie/wylosowana.json"
const PLIK_RODZENSTWA := "res://postacie/rodzina/wylosowane.json"
const PLIK_POZIOMY := "res://postacie/losowanie/poziomy.json"
const PLIK_WYKLUCZEN := "res://postacie/losowanie/wykluczenia_cech.json"
const PLIK_ZESTAWOW := "res://postacie/losowanie/zestawy_cech.json"
const PLIK_STATYSTYK := "res://postacie/losowanie/kolo_statystyk.json"
const PLIK_TRYBOW := "res://postacie/losowanie/tryby_urodzenia.json"
const PLIK_WYGLADU := "res://postacie/zdrowie/wyglad.json"
const KOLO_POZA_POLSKA := "Koło świata poza Polską jest puste, dopóki nie ma ludności."
const KOLO_KRAJ_PUSTY := "Koło tego kraju jest puste, dopóki nie ma ludności."

var _zseedowano := false
var _miejsca: Array = []
var _miejsca_gotowe := false
var _pamiec := {}
var _wagi_stat: Dictionary = {}


func losuj_kolo(wagi: Dictionary) -> String:
	_seed_raz()
	var suma := 0.0
	var ids: Array[String] = []
	for klucz in wagi.keys():
		var waga := float(wagi[klucz])
		if waga <= 0.0:
			continue
		ids.append(str(klucz))
		suma += waga
	if ids.is_empty() or suma <= 0.0:
		return ""
	var los := randf() * suma
	var przebyte := 0.0
	for id in ids:
		przebyte += float(wagi[id])
		if los < przebyte:
			return id
	return ids[ids.size() - 1]


func losuj_miejsce(tryb: String, kontynent_lub_id: String) -> Dictionary:
	_wczytaj_miejsca()
	var wybrany := kontynent_lub_id.strip_edges()
	if tryb == "sam" or tryb == "wybor_miejsca":
		return _miejsce_po_id(wybrany)
	if tryb == "kontynent":
		return _losuj_z_kontynentu(wybrany)
	if tryb == "kraj":
		return _losuj_z_kraju(wybrany)
	if tryb == "swiat":
		return _losuj_z_wag(wszystkie_z_ludnoscia(), "")
	return _puste("Nie wybrano trybu miejsca.")


func losuj_cechy(ile: int = -1) -> Array:
	var dane: Variant = _czytaj_json(PLIK_CECH)
	if not (dane is Dictionary) or not (dane.get("cechy") is Array):
		return []
	var obroty := 3
	if dane.get("ile_obrotow") != null:
		obroty = int(dane["ile_obrotow"])
	if ile >= 0:
		obroty = ile
	var wagi := {}
	var nazwy := {}
	var nazwa_na_id := {}
	for pozycja in dane["cechy"]:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		var id := str(pozycja["id"])
		var waga := 1.0
		if pozycja.get("waga") != null:
			waga = float(pozycja["waga"])
		if waga <= 0.0:
			continue
		wagi[id] = waga
		var nazwa := str(pozycja.get("nazwa", id))
		nazwy[id] = nazwa
		nazwa_na_id[nazwa] = id
	var wplywy := _wplywy_cech(nazwa_na_id)
	var zestawy := _zestawy_cech(nazwa_na_id)
	var uzyte_strony := {}
	var pary_waga := {}
	var wynik: Array = []
	var ile_obrotow := mini(obroty, wagi.size())
	for _i in ile_obrotow:
		var trafione := losuj_kolo(wagi)
		if trafione == "":
			break
		wynik.append({"id": trafione, "nazwa": nazwy.get(trafione, trafione)})
		wagi.erase(trafione)
		_obniz_zestawy(wagi, trafione, zestawy, uzyte_strony, pary_waga)
		_obniz_po_trafieniu(wagi, trafione, wplywy, pary_waga)
	return wynik


func losuj_inteligencje(ile: int = -1) -> Array:
	var lista := _losuj_liste(PLIK_INTELIGENCJI, "rodzaje", ile)
	for pozycja in lista:
		if pozycja is Dictionary:
			pozycja["wartosc"] = losuj_liczbe_statystyki()
	return lista


func losuj_postac(tryb: String, kontynent_lub_id: String) -> Dictionary:
	var pola := _nazwy_pol("bohater")
	var wynik := {
		"opis": "Jedno losowanie na start. Szablon postacie/bohater.json nie został zmieniony.",
		"wylosowano": false,
		"zarobki_rodziny": null,
	}
	for pole in pola:
		wynik[str(pole)] = null
	var miejsce := losuj_miejsce(tryb, kontynent_lub_id)
	_wpisz(wynik, "miejsce", miejsce)
	_wpisz(wynik, "rola", "bohater")
	var jest_miejsce := miejsce.get("id") != null
	wynik["wylosowano"] = jest_miejsce
	_wpisz_plec(wynik)
	_wpisz_orientacje(wynik)
	_wpisz_wyglad(wynik)
	_wpisz_cechy(wynik, -1)
	_wpisz_inteligencje(wynik, -1)
	_wpisz_statystyki(wynik)
	if jest_miejsce:
		_wpisz(wynik, "wiek", 0)
		var choroby := losuj_choroby(miejsce)
		_wpisz(wynik, "choroby_wypadly", choroby.get("wypadly", []))
		_wpisz(wynik, "zdrowie_skrot", _skrot_zdrowia(choroby))
	else:
		_wpisz(wynik, "choroby_wypadly", [])
		_wpisz(wynik, "zdrowie_skrot", "Bez miejsca nie kręcono chorób.")
	return wynik


func losuj_choroby(miejsce: Dictionary, rodzice: Variant = null) -> Dictionary:
	var wypadly: Array = []
	var bylo := false
	var dane: Variant = _czytaj_json(PLIK_CHOROB)
	if not (dane is Dictionary) or not (dane.get("wady") is Array):
		return {"wypadly": wypadly, "bylo_kolo": false}
	for wada in dane["wady"]:
		if not (wada is Dictionary):
			continue
		var jedna: Dictionary = _jedna_choroba(wada, miejsce, rodzice)
		if jedna.get("wynik") == null:
			continue
		bylo = true
		if str(jedna.get("wynik")) == "ma":
			wypadly.append({"id": jedna.get("id"), "nazwa": jedna.get("nazwa")})
	return {"wypadly": wypadly, "bylo_kolo": bylo}


func losuj_rodzenstwo(bohater: Dictionary) -> Array:
	var ile_txt := losuj_kolo({"0": 1.0, "1": 1.0, "2": 1.0, "3": 1.0})
	var ile := 0
	if ile_txt != "":
		ile = int(ile_txt)
	var lista: Array = []
	var miejsce: Variant = bohater.get("miejsce", {})
	if not (miejsce is Dictionary):
		miejsce = {}
	for _i in ile:
		lista.append(_jedno_rodzenstwo(miejsce))
	return lista


func losuj_przyjaciela() -> Dictionary:
	var karta := _karta("przyjaciele")
	_wpisz_plec(karta)
	_wpisz_orientacje(karta)
	_wpisz_wyglad(karta)
	_wpisz_cechy(karta, 2)
	_wpisz_inteligencje(karta, 1)
	_wpisz(karta, "rola", "przyjaciel")
	return karta


func losuj_znajomego() -> Dictionary:
	var karta := _karta("znajomi")
	_wpisz_plec(karta)
	_wpisz_cechy(karta, 1)
	_wpisz(karta, "rola", "znajomy")
	return karta


func losuj_zarobki(typ: String) -> Variant:
	var dane: Variant = _czytaj_json(PLIK_ZAROBKOW)
	if not (dane is Dictionary):
		return null
	var klucz := typ if typ == "wies" or typ == "miasto" else ""
	if klucz == "":
		return null
	var pozycja: Variant = dane.get(klucz)
	if not (pozycja is Dictionary):
		return null
	var srednia: Variant = pozycja.get("srednia")
	if srednia == null:
		return null
	return {
		"typ": klucz,
		"srednia": srednia,
		"kolo": dane.get("kolo"),
	}


func teren_dla_typu(typ: String) -> Dictionary:
	var dane: Variant = _czytaj_json(PLIK_TERENU)
	var pusty := {
		"miejsce": null,
		"typ": typ,
		"srednie_cechy": null,
		"szanse_statystyk": null,
	}
	if not (dane is Dictionary) or not (dane.get("miejsca") is Array):
		return pusty
	for wpis in dane["miejsca"]:
		if wpis is Dictionary and str(wpis.get("typ", "")) == typ:
			return {
				"miejsce": wpis.get("miejsce"),
				"typ": typ,
				"srednie_cechy": wpis.get("srednie_cechy"),
				"szanse_statystyk": wpis.get("szanse_statystyk"),
			}
	return pusty


func zapisz(wynik: Dictionary) -> bool:
	var plik := FileAccess.open(PLIK_WYNIKU, FileAccess.WRITE)
	if plik == null:
		return false
	plik.store_string(JSON.stringify(wynik, "\t"))
	return true


func kontynenty() -> Array:
	var dane: Variant = _czytaj_json(PLIK_KOL)
	if dane is Dictionary and dane.get("kontynenty") is Array:
		return dane["kontynenty"]
	return []


func miasta_polski() -> Array:
	_wczytaj_miejsca()
	var miasta: Array = []
	for miejsce in _miejsca:
		if str(miejsce.get("typ", "")) == "miasto":
			miasta.append(miejsce)
	miasta.sort_custom(func(a, b) -> bool:
		return str(a.get("nazwa", "")).nocasecmp_to(str(b.get("nazwa", ""))) < 0
	)
	return miasta


func zapisz_rodzenstwo(lista: Array) -> bool:
	var plik := FileAccess.open(PLIK_RODZENSTWA, FileAccess.WRITE)
	if plik == null:
		return false
	plik.store_string(JSON.stringify(lista, "\t"))
	return true


func panstwa() -> Array:
	var dane: Variant = _czytaj_json(PLIK_KOL)
	if dane is Dictionary and dane.get("panstwa") is Array:
		return dane["panstwa"]
	return []


func tryby_urodzenia() -> Array:
	var dane: Variant = _czytaj_json(PLIK_TRYBOW)
	if dane is Dictionary and dane.get("tryby") is Array:
		return dane["tryby"]
	return []


func losuj_liczbe_statystyki() -> Variant:
	var wagi := _wagi_statystyk()
	if wagi.is_empty():
		return null
	var id := losuj_kolo(wagi)
	if id == "":
		return null
	return int(id)


func _losuj_liste(sciezka: String, klucz: String, ile_nadpisane: int = -1) -> Array:
	var dane: Variant = _czytaj_json(sciezka)
	if not (dane is Dictionary) or not (dane.get(klucz) is Array):
		return []
	var ile := 3
	if dane.get("ile_obrotow") != null:
		ile = int(dane["ile_obrotow"])
	if ile_nadpisane >= 0:
		ile = ile_nadpisane
	var wagi := {}
	var nazwy := {}
	for pozycja in dane[klucz]:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		var id := str(pozycja["id"])
		var waga := 1.0
		if pozycja.get("waga") != null:
			waga = float(pozycja["waga"])
		if waga <= 0.0:
			continue
		wagi[id] = waga
		nazwy[id] = str(pozycja.get("nazwa", id))
	var wynik: Array = []
	var obroty := mini(ile, wagi.size())
	for _i in obroty:
		var id := losuj_kolo(wagi)
		if id == "":
			break
		wynik.append({"id": id, "nazwa": nazwy[id]})
		wagi.erase(id)
	return wynik


func _jedna_choroba(wada: Dictionary, miejsce: Dictionary, rodzice: Variant) -> Dictionary:
	var wpis := _czestosc_dla_miejsca(wada, miejsce)
	var wynik := {
		"id": wada.get("id"),
		"nazwa": wada.get("nazwa"),
		"wynik": null,
		"na_10000": null,
		"region": null,
		"wplyw_rodzicow": null,
	}
	if wpis == null:
		wynik["powod"] = "Brak liczby na 10000 dla tego miejsca. Koło się nie kręci."
		return wynik
	var na := float(wpis["na_10000"])
	var reszta := 10000.0 - na
	if na < 0.0 or reszta < 0.0:
		wynik["powod"] = "Liczba na 10000 nie mieści się w kole 10000. Wyniku nie wylosowano."
		return wynik
	var wagi := {"ma": na, "nie_ma": reszta}
	if wada.get("wplyw_rodzicow_na_kolo") == null or rodzice == null:
		wynik["wplyw_rodzicow"] = "bez zmiany"
	else:
		wagi = _wagi_rodzicow(wagi, wada.get("wplyw_rodzicow_na_kolo"))
		wynik["wplyw_rodzicow"] = "zrodlo"
	var id := losuj_kolo(wagi)
	wynik["wynik"] = id if id != "" else null
	wynik["na_10000"] = wpis.get("na_10000")
	wynik["region"] = wpis.get("region")
	wynik["zrodlo"] = wpis.get("zrodlo")
	wynik["url"] = wpis.get("url")
	wynik["rok"] = wpis.get("rok")
	return wynik


func _czestosc_dla_miejsca(wada: Dictionary, miejsce: Dictionary) -> Variant:
	var regiony: Variant = wada.get("czestosc_regiony")
	if not (regiony is Array):
		return null
	var najlepszy: Variant = null
	var poziom := 0
	for region in regiony:
		if not (region is Dictionary) or region.get("do_kola_urodzenia") != true:
			continue
		if region.get("na_10000") == null:
			continue
		var teraz := _poziom_dopasowania(region.get("dopasowanie"), miejsce)
		if teraz > poziom:
			poziom = teraz
			najlepszy = region
	if poziom == 0:
		return null
	return najlepszy


func _poziom_dopasowania(dopasowanie: Variant, miejsce: Dictionary) -> int:
	if not (dopasowanie is Dictionary):
		return 0
	if dopasowanie.has("panstwo") and str(dopasowanie["panstwo"]) == str(miejsce.get("panstwo", "")):
		return 2
	if dopasowanie.has("kontynent") and str(dopasowanie["kontynent"]) == str(miejsce.get("kontynent", "")):
		return 1
	return 0


func _wagi_rodzicow(wagi: Dictionary, wplyw: Variant) -> Dictionary:
	if not (wplyw is Dictionary):
		return wagi
	var kopia := wagi.duplicate()
	for klucz in wplyw.keys():
		if not kopia.has(klucz) or wplyw[klucz] == null:
			continue
		var nowa := float(kopia[klucz]) + float(wplyw[klucz])
		if nowa < 0.0:
			nowa = 0.0
		kopia[klucz] = nowa
	return kopia


func _wczytaj_miejsca() -> void:
	if _miejsca_gotowe:
		return
	_miejsca_gotowe = true
	var dane: Variant = _czytaj_json(PLIK_KOL)
	if not (dane is Dictionary) or not (dane.get("panstwa") is Array):
		return
	for panstwo in dane["panstwa"]:
		if not (panstwo is Dictionary):
			continue
		var kontynent := str(panstwo.get("kontynent", ""))
		var panstwo_id := str(panstwo.get("id", ""))
		var katalogi: Variant = panstwo.get("katalogi", [])
		if not (katalogi is Array):
			continue
		for katalog in katalogi:
			_czytaj_katalog(str(katalog), kontynent, panstwo_id)


func _czytaj_katalog(katalog: String, kontynent: String, panstwo_id: String) -> void:
	var pliki := DirAccess.get_files_at(katalog)
	for nazwa in pliki:
		if not str(nazwa).ends_with(".json"):
			continue
		var sciezka := katalog.path_join(str(nazwa))
		var dane: Variant = _czytaj_json(sciezka)
		if not (dane is Dictionary):
			continue
		var lud: Variant = dane.get("liczba_mieszkancow")
		if lud == null or not (lud is int or lud is float):
			continue
		if float(lud) <= 0.0:
			continue
		if not dane.has("id"):
			continue
		_miejsca.append({
			"id": str(dane["id"]),
			"nazwa": str(dane.get("nazwa", "")),
			"typ": str(dane.get("typ", "")),
			"ludnosc": int(lud),
			"panstwo": str(dane.get("panstwo", "")),
			"panstwo_id": panstwo_id,
			"kontynent": kontynent,
		})


func _miejsce_po_id(id: String) -> Dictionary:
	if id == "":
		return _puste("Nie wybrano miejsca.")
	for miejsce in _miejsca:
		if str(miejsce.get("id", "")) == id:
			return miejsce.duplicate()
	return _puste("Tego id nie ma wśród miejsc z ludnością.")


func _losuj_z_kontynentu(kontynent: String) -> Dictionary:
	if kontynent == "":
		return _puste("Nie wybrano kontynentu.")
	var pula: Array = []
	for miejsce in _miejsca:
		if str(miejsce.get("kontynent", "")) == kontynent:
			pula.append(miejsce)
	if pula.is_empty():
		return _puste(KOLO_POZA_POLSKA)
	return _losuj_z_wag(pula, kontynent)


func _losuj_z_kraju(panstwo_id: String) -> Dictionary:
	if panstwo_id == "":
		return _puste("Nie wybrano kraju.")
	var pula: Array = []
	for miejsce in _miejsca:
		if str(miejsce.get("panstwo_id", "")) == panstwo_id:
			pula.append(miejsce)
	if pula.is_empty():
		return _puste(KOLO_KRAJ_PUSTY)
	return _losuj_z_wag(pula, "")


func wszystkie_z_ludnoscia() -> Array:
	_wczytaj_miejsca()
	return _miejsca


func _losuj_z_wag(pula: Array, kontynent: String) -> Dictionary:
	var wagi := {}
	var po_id := {}
	for miejsce in pula:
		var id := str(miejsce.get("id", ""))
		var lud := float(miejsce.get("ludnosc", 0))
		if id == "" or lud <= 0.0:
			continue
		wagi[id] = lud
		po_id[id] = miejsce
	var id := losuj_kolo(wagi)
	if id == "" or not po_id.has(id):
		if kontynent != "" and kontynent != "europa":
			return _puste(KOLO_POZA_POLSKA)
		return _puste("Koło miejsc z ludnością jest puste.")
	return po_id[id].duplicate()


func _puste(powod: String) -> Dictionary:
	return {
		"id": null,
		"nazwa": null,
		"typ": null,
		"ludnosc": null,
		"panstwo": null,
		"kontynent": null,
		"puste_kolo": true,
		"powod": powod,
	}


func _seed_raz() -> void:
	if _zseedowano:
		return
	randomize()
	_zseedowano = true


func _czytaj_json(sciezka: String) -> Variant:
	var pamietac := sciezka.find("świat/") == -1 and sciezka.find("swiat/") == -1
	if pamietac and _pamiec.has(sciezka):
		return _pamiec[sciezka]
	if not FileAccess.file_exists(sciezka):
		if pamietac:
			_pamiec[sciezka] = null
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if pamietac:
		_pamiec[sciezka] = dane
	return dane


func _wplywy_cech(nazwa_na_id: Dictionary) -> Array:
	var dane: Variant = _czytaj_json(PLIK_WYKLUCZEN)
	var wynik: Array = []
	if not (dane is Dictionary) or not (dane.get("wplywy") is Array):
		return wynik
	for wplyw in dane["wplywy"]:
		if not (wplyw is Dictionary):
			continue
		var gdy := str(nazwa_na_id.get(str(wplyw.get("gdy", "")), ""))
		var obniza := str(nazwa_na_id.get(str(wplyw.get("obniza", "")), ""))
		if gdy == "" or obniza == "":
			continue
		wynik.append({
			"gdy": gdy,
			"obniza": obniza,
			"waga": float(wplyw.get("waga", 0)),
		})
	return wynik


func _obniz_po_trafieniu(wagi: Dictionary, id: String, wplywy: Array, pary_waga: Dictionary) -> void:
	for wplyw in wplywy:
		if not (wplyw is Dictionary) or str(wplyw.get("gdy", "")) != id:
			continue
		var cel := str(wplyw.get("obniza", ""))
		if cel == "" or not wagi.has(cel):
			continue
		var nowa := float(wplyw.get("waga", 0))
		if pary_waga.has(cel):
			nowa = min(float(pary_waga[cel]), nowa)
		pary_waga[cel] = nowa
		wagi[cel] = nowa


func _zestawy_cech(nazwa_na_id: Dictionary) -> Array:
	var dane: Variant = _czytaj_json(PLIK_ZESTAWOW)
	var wynik: Array = []
	if not (dane is Dictionary) or not (dane.get("zestawy") is Array):
		return wynik
	for zestaw in dane["zestawy"]:
		if not (zestaw is Dictionary):
			continue
		var procent := int(zestaw.get("procent", 0))
		if procent != 20 and procent != 30 and procent != 40 and procent != 50 and procent != 60 and procent != 70 and procent != 80:
			continue
		var strona_a := _strona_zestawu(zestaw.get("strona_a", []), nazwa_na_id)
		var strona_b := _strona_zestawu(zestaw.get("strona_b", []), nazwa_na_id)
		if strona_a.is_empty() or strona_b.is_empty():
			continue
		wynik.append({
			"numer": str(zestaw.get("numer", "")),
			"zostaje": 1.0 - float(procent) / 100.0,
			"a": strona_a,
			"b": strona_b,
		})
	return wynik


func _strona_zestawu(lista: Variant, nazwa_na_id: Dictionary) -> Dictionary:
	var strona := {}
	if not (lista is Array):
		return strona
	for nazwa in lista:
		var id := str(nazwa_na_id.get(str(nazwa), ""))
		if id != "":
			strona[id] = true
	return strona


func _obniz_zestawy(wagi: Dictionary, id: String, zestawy: Array, uzyte_strony: Dictionary, pary_waga: Dictionary) -> void:
	for zestaw in zestawy:
		if not (zestaw is Dictionary):
			continue
		var numer := str(zestaw.get("numer", ""))
		var zostaje := float(zestaw.get("zostaje", 1))
		var strona_a: Variant = zestaw.get("a", {})
		var strona_b: Variant = zestaw.get("b", {})
		if strona_a is Dictionary and strona_a.has(id) and not uzyte_strony.has(numer + ":a"):
			uzyte_strony[numer + ":a"] = true
			_pomnoz_strone(wagi, strona_b, zostaje, pary_waga)
		if strona_b is Dictionary and strona_b.has(id) and not uzyte_strony.has(numer + ":b"):
			uzyte_strony[numer + ":b"] = true
			_pomnoz_strone(wagi, strona_a, zostaje, pary_waga)


func _pomnoz_strone(wagi: Dictionary, strona: Variant, zostaje: float, pary_waga: Dictionary) -> void:
	if not (strona is Dictionary):
		return
	for cel in strona.keys():
		if pary_waga.has(cel) or not wagi.has(cel):
			continue
		wagi[cel] = float(wagi[cel]) * zostaje


func _nazwy_pol(poziom: String) -> Array:
	var dane: Variant = _czytaj_json(PLIK_POZIOMY)
	if dane is Dictionary and dane.get(poziom) is Dictionary:
		var pola: Variant = dane[poziom].get("pola", [])
		if pola is Array and not pola.is_empty():
			return pola
	return _pola_zapasowe(poziom)


func _pola_zapasowe(poziom: String) -> Array:
	if poziom == "bohater":
		return ["miejsce", "plec", "orientacja", "wyglad_naturalny", "sylwetka", "cecha_1", "cecha_2", "cecha_3", "inteligencja_1", "inteligencja_2", "inteligencja_3", "zdrowie_skrot", "choroby_wypadly", "zwinnosc", "szybkosc_reakcji", "sila", "wytrzymalosc", "rownowaga", "wiek", "rola"]
	if poziom == "rodzenstwo":
		return ["miejsce", "plec", "cecha_1", "cecha_2", "rola"]
	if poziom == "przyjaciele":
		return ["plec", "orientacja", "wyglad_naturalny", "sylwetka", "cecha_1", "cecha_2", "inteligencja_1", "rola"]
	if poziom == "znajomi":
		return ["plec", "cecha_1", "rola"]
	return []


func _karta(poziom: String) -> Dictionary:
	var karta := {}
	for pole in _nazwy_pol(poziom):
		karta[str(pole)] = null
	return karta


func _wpisz(karta: Dictionary, klucz: String, wartosc: Variant) -> void:
	if karta.has(klucz):
		karta[klucz] = wartosc


func _ile_slotow(karta: Dictionary, przedrostek: String) -> int:
	var n := 0
	while karta.has("%s_%d" % [przedrostek, n + 1]):
		n += 1
	return n


func _wpisz_sloty(karta: Dictionary, przedrostek: String, lista: Array) -> void:
	var numer := 1
	for pozycja in lista:
		_wpisz(karta, "%s_%d" % [przedrostek, numer], pozycja)
		numer += 1


func _wpisz_plec(karta: Dictionary) -> void:
	if not karta.has("plec"):
		return
	var id := losuj_kolo({"kobieta": 1.0, "mezczyzna": 1.0})
	var nazwy := {"kobieta": "Kobieta", "mezczyzna": "Mężczyzna"}
	karta["plec"] = {"id": id, "nazwa": nazwy.get(id, id)}


func _wpisz_orientacje(karta: Dictionary) -> void:
	if not karta.has("orientacja"):
		return
	var id := losuj_kolo({"hetero": 1.0, "homo": 1.0, "bi": 1.0})
	var nazwy := {"hetero": "Hetero", "homo": "Homo", "bi": "Bi"}
	karta["orientacja"] = {"id": id, "nazwa": nazwy.get(id, id)}


func _wpisz_wyglad(karta: Dictionary) -> void:
	if karta.has("wyglad_naturalny"):
		karta["wyglad_naturalny"] = _losuj_etykiete("wyglad_naturalny")
	if karta.has("sylwetka"):
		karta["sylwetka"] = _losuj_etykiete("sylwetka")


func _losuj_etykiete(klucz: String) -> Variant:
	var dane: Variant = _czytaj_json(PLIK_WYGLADU)
	if not (dane is Dictionary) or not (dane.get(klucz) is Array):
		return null
	var wagi := {}
	for etykieta in dane[klucz]:
		var id := str(etykieta)
		if id == "":
			continue
		wagi[id] = 1.0
	if wagi.is_empty():
		return null
	var id := losuj_kolo(wagi)
	if id == "":
		return null
	return {"id": id, "nazwa": id}


func _wpisz_cechy(karta: Dictionary, ile: int) -> void:
	var sloty := _ile_slotow(karta, "cecha")
	if sloty == 0:
		return
	var ile_los := sloty if ile < 0 else mini(ile, sloty)
	_wpisz_sloty(karta, "cecha", losuj_cechy(ile_los))


func _wpisz_inteligencje(karta: Dictionary, ile: int) -> void:
	var sloty := _ile_slotow(karta, "inteligencja")
	if sloty == 0:
		return
	var ile_los := sloty if ile < 0 else mini(ile, sloty)
	_wpisz_sloty(karta, "inteligencja", losuj_inteligencje(ile_los))


func _wpisz_statystyki(karta: Dictionary) -> void:
	for nazwa in ["sila", "zwinnosc", "szybkosc_reakcji", "wytrzymalosc", "rownowaga"]:
		if karta.has(nazwa):
			karta[nazwa] = losuj_liczbe_statystyki()


func _wagi_statystyk() -> Dictionary:
	if not _wagi_stat.is_empty():
		return _wagi_stat
	var dane: Variant = _czytaj_json(PLIK_STATYSTYK)
	if not (dane is Dictionary) or str(dane.get("wzor", "")) != "n * (101 - n)":
		return _wagi_stat
	var min_n := int(dane.get("min", 1))
	var max_n := int(dane.get("max", 100))
	for n in range(min_n, max_n + 1):
		var waga: int = n * (101 - n)
		if waga <= 0:
			continue
		_wagi_stat[str(n)] = waga
	return _wagi_stat


func _skrot_zdrowia(choroby: Dictionary) -> String:
	var wypadly: Variant = choroby.get("wypadly", [])
	if not choroby.get("bylo_kolo", false):
		return "Chorób nie kręcono: brak procentu dla tego miejsca."
	if not (wypadly is Array) or wypadly.is_empty():
		return "Koło chorób nic nie wypuściło."
	var nazwy: PackedStringArray = []
	for pozycja in wypadly:
		if pozycja is Dictionary:
			nazwy.append(str(pozycja.get("nazwa", "")))
	return ", ".join(nazwy)


func _jedno_rodzenstwo(miejsce_bohatera: Dictionary) -> Dictionary:
	var karta := _karta("rodzenstwo")
	_wpisz(karta, "miejsce", _miejsce_jak_bohater(miejsce_bohatera))
	_wpisz_plec(karta)
	var ile := 1
	if losuj_kolo({"1": 1.0, "2": 1.0}) == "2":
		ile = 2
	_wpisz_cechy(karta, ile)
	_wpisz(karta, "rola", "rodzenstwo")
	return karta


func _miejsce_jak_bohater(miejsce: Dictionary) -> Dictionary:
	if miejsce.get("id") == null:
		return miejsce.duplicate()
	var id := str(miejsce.get("id"))
	losuj_kolo({id: 1.0})
	return miejsce.duplicate()
