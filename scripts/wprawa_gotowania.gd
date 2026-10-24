extends RefCounted
class_name WprawaGotowania

## Współczynniki z JSON. To propozycja do poprawki, nie pomiar.

const PLIK := "res://postacie/gotowanie_wprawa.json"
const PLIK_CECH := "res://postacie/gotowanie_cechy.json"

var dane: Dictionary = {}
var cechy_pliku: Dictionary = {}
var etap := 0
var punkty := 0
var szczyt_etap := 0
var szczyt_punkty := 0
var tygodnie_regresu := 0
var tygodnie_od_gotowania := 0
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var surowe: Variant = _czytaj(PLIK)
	if surowe is Dictionary:
		dane = surowe
	var cechy: Variant = _czytaj(PLIK_CECH)
	if cechy is Dictionary and cechy.get("cechy") is Array:
		for wpis in cechy["cechy"]:
			if wpis is Dictionary and str(wpis.get("id", "")) != "":
				cechy_pliku[str(wpis.get("id"))] = wpis


func nazwa_etapu(numer: int = -1) -> String:
	wczytaj()
	var indeks := etap if numer < 0 else numer
	var lista: Variant = dane.get("etapy", [])
	if lista is Array and indeks >= 0 and indeks < lista.size():
		return str(lista[indeks])
	return "brak doświadczenia"


func plusy_za_dni(dni: int) -> int:
	wczytaj()
	var lista: Variant = dane.get("plusy_zadowolenia_za_dni", [])
	if lista is Array and dni >= 0 and dni < lista.size() and _liczba(lista[dni]):
		return int(lista[dni])
	return 0


func minus_dodatkowy() -> int:
	wczytaj()
	var n: Variant = dane.get("minus_dodatkowy_przy_obnizeniu", 1)
	if _liczba(n):
		return int(n)
	return 1


func mnozniki_cech(ids: Array) -> Dictionary:
	wczytaj()
	var energia := 1.0
	var czas := 1.0
	for id in ids:
		var wpis: Variant = cechy_pliku.get(str(id), {})
		if not (wpis is Dictionary):
			continue
		if _liczba(wpis.get("energia")):
			energia *= float(wpis.get("energia"))
		if _liczba(wpis.get("czas")):
			czas *= float(wpis.get("czas"))
	return {"energia": energia, "czas": czas}


func mnoznik_wprawy() -> float:
	wczytaj()
	var blok: Dictionary = _blok("koszt_z_wprawa")
	var na_etap := float(blok.get("obnizka_na_etap", 0.08))
	var na_punkty := float(blok.get("obnizka_na_pelne_punkty_etapu", 0.15))
	var dol := float(blok.get("mnoznik_min", 0.4))
	var cap := float(dane.get("punkty_w_etapie_max", 100))
	if cap <= 0.0:
		cap = 100.0
	var mnoznik := 1.0 - float(etap) * na_etap - (float(punkty) / cap) * na_punkty
	return maxf(mnoznik, dol)


func koszt(dni: int, ids: Array) -> Dictionary:
	wczytaj()
	var baza: Dictionary = _blok("bazowy_koszt")
	var energia_dnia := float(baza.get("energia_na_dzien_gotowania", 15))
	var czas_dnia := float(baza.get("czas_porcji_tygodnia_na_dzien", 1))
	var cechy := mnozniki_cech(ids)
	var wprawa := mnoznik_wprawy()
	return {
		"dni": dni,
		"energia": energia_dnia * float(dni) * wprawa * float(cechy["energia"]),
		"czas": czas_dnia * float(dni) * wprawa * float(cechy["czas"]),
		"propozycja_do_poprawki": true,
	}


func zastosuj_tydzien(dni: int) -> Dictionary:
	wczytaj()
	var bonus := _bonus_powrotu()
	var gain := 0.0
	if dni > 0:
		gain = float(_blok("postep").get("punkty_za_dzien", 3)) * float(dni) * bonus
		tygodnie_od_gotowania = 0
	else:
		tygodnie_od_gotowania += 1
	var spadek := _spadek(dni)
	if spadek >= 1:
		tygodnie_regresu += 1
	else:
		tygodnie_regresu = 0
	_dodaj_punkty(int(round(gain)) - spadek)
	return {
		"przybylo": int(round(gain)),
		"spadek": spadek,
		"etap": nazwa_etapu(),
		"punkty": punkty,
	}


func tekst_stanu(dni: int, ids: Array) -> String:
	wczytaj()
	var cap := int(dane.get("punkty_w_etapie_max", 100))
	var koszt_tygodnia := koszt(dni, ids)
	return "Wprawa: %s, %d/%d. Szczyt: %s, %d. Koszt tygodnia (propozycja): energia %s, czas %s." % [
		nazwa_etapu(),
		punkty,
		cap,
		nazwa_etapu(szczyt_etap),
		szczyt_punkty,
		_tekst_liczby(float(koszt_tygodnia["energia"])),
		_tekst_liczby(float(koszt_tygodnia["czas"])),
	]


func _spadek(dni: int) -> int:
	var regres: Dictionary = _blok("regres")
	var baza := float(regres.get("bazowy_spadek_punktow_na_tydzien", 10))
	var mnozniki: Variant = regres.get("mnoznik_dni", [])
	var mnoznik := 0.0
	if mnozniki is Array and dni >= 0 and dni < mnozniki.size() and _liczba(mnozniki[dni]):
		mnoznik = float(mnozniki[dni])
	var wsp_etap := float(regres.get("wspolczynnik_etapu", 0.45))
	var wsp_trwa := float(regres.get("wspolczynnik_tygodni_regresu", 0.2))
	var wsp_od := float(regres.get("wspolczynnik_tygodni_od_gotowania", 0.1))
	var dzielnik := (1.0 + float(etap) * wsp_etap) * (1.0 + float(tygodnie_regresu) * wsp_trwa)
	if dzielnik <= 0.0:
		dzielnik = 1.0
	var surowy := baza * mnoznik * (1.0 + float(tygodnie_od_gotowania) * wsp_od) / dzielnik
	if surowy <= 0.0:
		return 0
	return int(round(surowy))


func _bonus_powrotu() -> float:
	var blok: Dictionary = _blok("powrot")
	var daleko := float(blok.get("bonus_gdy_daleko_od_szczytu", 2.0))
	var blisko := float(blok.get("bonus_przy_szczycie", 1.0))
	var teraz := _calkowite(etap, punkty)
	var szczyt := _calkowite(szczyt_etap, szczyt_punkty)
	if szczyt <= 0 or teraz >= szczyt:
		return 1.0
	var t := float(teraz) / float(szczyt)
	return daleko + (blisko - daleko) * t


func _dodaj_punkty(delta: int) -> void:
	var cap := int(dane.get("punkty_w_etapie_max", 100))
	if cap <= 0:
		cap = 100
	var lista: Variant = dane.get("etapy", [])
	var ostatni := 4
	if lista is Array and not lista.is_empty():
		ostatni = lista.size() - 1
	punkty += delta
	while punkty >= cap and etap < ostatni:
		punkty -= cap
		etap += 1
	if etap >= ostatni and punkty > cap:
		punkty = cap
	while punkty < 0 and etap > 0:
		etap -= 1
		punkty += cap
	if punkty < 0:
		punkty = 0
	if _calkowite(etap, punkty) > _calkowite(szczyt_etap, szczyt_punkty):
		szczyt_etap = etap
		szczyt_punkty = punkty


func _calkowite(numer_etapu: int, liczba_punktow: int) -> int:
	var cap := int(dane.get("punkty_w_etapie_max", 100))
	return numer_etapu * cap + liczba_punktow


func _blok(klucz: String) -> Dictionary:
	var blok: Variant = dane.get(klucz, {})
	if blok is Dictionary:
		return blok
	return {}


func _tekst_liczby(n: float) -> String:
	if is_equal_approx(n, round(n)):
		return str(int(round(n)))
	return "%.1f" % n


func _liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
