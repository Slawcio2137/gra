extends RefCounted
class_name ZiarnoRodzicow

## Raz na start rodziny. Nie kręci koła, dopóki waga nie ma źródła. Nie liczy nic co klatkę.

const PLIK := "res://postacie/losowanie/ziarno_rodzicow.json"
const PLIK_KIESZONKOWEGO := "res://postacie/kieszonkowe.json"
const ZaokraglenieZarobkow = preload("res://scripts/zaokraglenie_zarobkow.gd")
const PLIK_DIET := "res://postacie/losowanie/diety_kraje.json"
const PLIK_ZAROBKOW_KRAJE := "res://postacie/losowanie/zarobki_kraje.json"
const PLIK_ZAWODY_KRAJE := "res://postacie/losowanie/zawody_kraje.json"
const PLIK_IMION := "res://postacie/imiona/imiona_kraje.json"
const _Losowanie = preload("res://scripts/losowanie.gd")
const SkryptKataloguZawodow = preload("res://scripts/katalog_zawodow.gd")

var _dane: Variant = null


func wczytaj() -> Variant:
	if _dane is Dictionary:
		return _dane
	_dane = _czytaj(PLIK)
	return _dane


func losuj(losowanie = null, miejsce: Variant = null) -> Dictionary:
	var dane: Variant = wczytaj()
	var wynik := {
		"raz_na_start_rodziny": true,
		"osobne_od_cech_bohatera": true,
		"trzymac_w_zapisie": true,
		"nie_co_ture": true,
		"matka": {},
		"ojciec": {},
		"praca": {"id": null, "nazwa": null, "kolo": false, "powod": "prace osobno u matki i ojca"},
		"dom": {"id": null, "nazwa": null, "kolo": false, "powod": "brak wag"},
		"zarobki": {},
		"charakter": [],
		"kolo": false,
	}
	if not (dane is Dictionary):
		wynik["powod"] = "Brak pliku ziarna."
		return wynik
	var los = losowanie if losowanie != null else _Losowanie.new()
	wynik["dom"] = _jedno_kolo(los, dane.get("dom"))
	var miejsce_rodziny: Variant = miejsce
	if miejsce_rodziny == null and dane is Dictionary:
		miejsce_rodziny = dane.get("miejsce_urodzenia", null)
	var kraj := kraj_rodziny(miejsce_rodziny)
	wynik["kraj_rodziny"] = kraj
	# Najpierw zawody (wagi Eurostat/BAEL), potem zarobki z grupy ISCO tego zawodu (GUS).
	wynik["matka"] = _losuj_rodzica(los, kraj, "matka", "kobiety", "zenskie")
	wynik["ojciec"] = _losuj_rodzica(los, kraj, "ojciec", "mezczyzni", "meskie")
	wynik["matka"]["zarobki"] = _zarobki_dla_pracy(wynik["matka"].get("praca"), "kobiety", kraj)
	wynik["ojciec"]["zarobki"] = _zarobki_dla_pracy(wynik["ojciec"].get("praca"), "mezczyzni", kraj)
	wynik["zarobki"] = _zarobki_gospodarstwa(
		wynik["matka"]["zarobki"], wynik["ojciec"]["zarobki"], kraj, los, miejsce_rodziny
	)
	# Charakter gospodarstwa = cechy obojga (do kieszonkowego / jedzenia).
	wynik["charakter"] = []
	if wynik["matka"].get("charakter") is Array:
		for c in wynik["matka"]["charakter"]:
			wynik["charakter"].append(c)
	if wynik["ojciec"].get("charakter") is Array:
		for c in wynik["ojciec"]["charakter"]:
			wynik["charakter"].append(c)
	wynik["wyzywienie"] = _wyzywienie(dane.get("wyzywienie"))
	wynik["szansa_diety"] = szansa_diety(str(wynik["kraj_rodziny"]))
	wynik["kieszonkowe"] = kieszonkowe(wynik)
	var praca_ok := bool(wynik["matka"].get("praca", {}).get("kolo")) or bool(wynik["ojciec"].get("praca", {}).get("kolo"))
	wynik["kolo"] = praca_ok or bool(wynik["dom"].get("kolo")) or bool(wynik["zarobki"].get("kolo"))
	return wynik


func uzupelnij_wieki(swiat: Dictionary) -> bool:
	## Uzupełnia brakujący wiek raz. Istniejąca liczba zostaje, ekran jej nie losuje od nowa.
	var zmieniono := false
	var ziarno := 1
	if _jest_liczba(swiat.get("ziarno_wieku")):
		ziarno = int(swiat["ziarno_wieku"])
	else:
		ziarno = absi(str(swiat.get("id_urodzenia", "rodzina")).hash())
		if ziarno == 0:
			ziarno = 1
		swiat["ziarno_wieku"] = ziarno
		zmieniono = true
	var bohater: Dictionary = swiat.get("bohater", {}) if swiat.get("bohater") is Dictionary else {}
	var wiek_h := 3
	if _jest_liczba(bohater.get("wiek")):
		wiek_h = int(bohater["wiek"])
	var rodzina: Dictionary = swiat.get("rodzina", {}) if swiat.get("rodzina") is Dictionary else {}
	var rodzenstwo: Array = swiat.get("rodzenstwo", []) if swiat.get("rodzenstwo") is Array else []
	var najstarsze := wiek_h
	for i in rodzenstwo.size():
		if not (rodzenstwo[i] is Dictionary):
			continue
		var os: Dictionary = rodzenstwo[i]
		if not _jest_liczba(os.get("wiek")):
			var rng_i := RandomNumberGenerator.new()
			rng_i.seed = ziarno + 17 * (i + 1)
			var odstep := rng_i.randi_range(1, 4)
			os["wiek"] = wiek_h + odstep if i % 2 == 0 else maxi(0, wiek_h - odstep)
			os["kolejnosc_wstepna"] = i
			rodzenstwo[i] = os
			zmieniono = true
		if int(os.get("wiek", 0)) > najstarsze:
			najstarsze = int(os["wiek"])
	swiat["rodzenstwo"] = rodzenstwo
	var matka: Dictionary = rodzina.get("matka", {}) if rodzina.get("matka") is Dictionary else {}
	if not matka.is_empty() and not _jest_liczba(matka.get("wiek")):
		var rng_m := RandomNumberGenerator.new()
		rng_m.seed = ziarno + 3
		var przy := _wiek_przy_pierwszym_dziecku(rng_m)
		matka["wiek_przy_najstarszym_dziecku"] = przy
		matka["wiek"] = najstarsze + przy
		rodzina["matka"] = matka
		zmieniono = true
	var wiek_matki := int(matka.get("wiek", najstarsze + 26))
	var ojciec: Dictionary = rodzina.get("ojciec", {}) if rodzina.get("ojciec") is Dictionary else {}
	if not ojciec.is_empty() and not _jest_liczba(ojciec.get("wiek")):
		var rng_o := RandomNumberGenerator.new()
		rng_o.seed = ziarno + 5
		var przy_o := int(matka.get("wiek_przy_najstarszym_dziecku", 26)) + rng_o.randi_range(-2, 6)
		if przy_o < 15:
			przy_o = 15
		ojciec["wiek_przy_najstarszym_dziecku"] = przy_o
		ojciec["wiek"] = najstarsze + przy_o
		rodzina["ojciec"] = ojciec
		zmieniono = true
	if rodzina.get("dziadkowie") is Dictionary:
		var dzi: Dictionary = rodzina["dziadkowie"]
		var lista: Array = dzi.get("lista", []) if dzi.get("lista") is Array else []
		for j in lista.size():
			if not (lista[j] is Dictionary):
				continue
			var g: Dictionary = lista[j]
			if _jest_liczba(g.get("wiek")):
				continue
			var rng_g := RandomNumberGenerator.new()
			rng_g.seed = ziarno + 11 * (j + 1)
			var baza := wiek_matki if bool(g.get("linia_matki", true)) else int(ojciec.get("wiek", wiek_matki))
			g["wiek"] = baza + rng_g.randi_range(18, 34)
			lista[j] = g
			zmieniono = true
		dzi["lista"] = lista
		rodzina["dziadkowie"] = dzi
	swiat["rodzina"] = rodzina
	for klucz in ["przyjaciele", "znajomi"]:
		var osoby: Array = swiat.get(klucz, []) if swiat.get(klucz) is Array else []
		for k in osoby.size():
			if not (osoby[k] is Dictionary):
				continue
			var os2: Dictionary = osoby[k]
			if _jest_liczba(os2.get("wiek")):
				continue
			var rng_f := RandomNumberGenerator.new()
			rng_f.seed = ziarno + 80 + k + (0 if klucz == "przyjaciele" else 40)
			os2["wiek"] = maxi(0, wiek_h + rng_f.randi_range(-3, 4))
			osoby[k] = os2
			zmieniono = true
		swiat[klucz] = osoby
	return zmieniono


func _wiek_przy_pierwszym_dziecku(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.008:
		return 15
	if r < 0.02:
		return 16
	if r < 0.05:
		return 17
	return rng.randi_range(20, 35)


func postarz_otoczenie(swiat: Dictionary) -> void:
	var rodzina: Dictionary = swiat.get("rodzina", {}) if swiat.get("rodzina") is Dictionary else {}
	for rola in ["matka", "ojciec"]:
		if rodzina.get(rola) is Dictionary:
			var os: Dictionary = rodzina[rola]
			if _jest_liczba(os.get("wiek")):
				os["wiek"] = int(os["wiek"]) + 1
				rodzina[rola] = os
	if rodzina.get("dziadkowie") is Dictionary:
		var dzi: Dictionary = rodzina["dziadkowie"]
		var lista: Array = dzi.get("lista", []) if dzi.get("lista") is Array else []
		for j in lista.size():
			if lista[j] is Dictionary and _jest_liczba(lista[j].get("wiek")):
				lista[j]["wiek"] = int(lista[j]["wiek"]) + 1
		dzi["lista"] = lista
		rodzina["dziadkowie"] = dzi
	swiat["rodzina"] = rodzina
	if swiat.get("rodzenstwo") is Array:
		var rod: Array = swiat["rodzenstwo"]
		for i in rod.size():
			if rod[i] is Dictionary and _jest_liczba(rod[i].get("wiek")):
				rod[i]["wiek"] = int(rod[i]["wiek"]) + 1
		swiat["rodzenstwo"] = rod
	for klucz in ["przyjaciele", "znajomi"]:
		if not (swiat.get(klucz) is Array):
			continue
		var osoby: Array = swiat[klucz]
		for k in osoby.size():
			if osoby[k] is Dictionary and _jest_liczba(osoby[k].get("wiek")):
				osoby[k]["wiek"] = int(osoby[k]["wiek"]) + 1
		swiat[klucz] = osoby


func _losuj_rodzica(los, kraj: String, rola: String, klucz_zawodu: String, klucz_imion: String) -> Dictionary:
	var wynik := {
		"rola": rola,
		"imie": null,
		"charakter": [],
		"praca": {"id": null, "nazwa": null, "kolo": false, "powod": "brak wag"},
	}
	wynik["imie"] = _losuj_imie(los, kraj, klucz_imion)
	wynik["charakter"] = _charakter({}, los)
	wynik["praca"] = _zawod_kola(los, kraj, klucz_zawodu)
	return wynik


func _losuj_imie(los, kraj: String, klucz_listy: String) -> Variant:
	var dane: Variant = _czytaj(PLIK_IMION)
	if not (dane is Dictionary) or not (dane.get("kraje") is Dictionary):
		return {"id": null, "nazwa": null, "kolo": false, "powod": "Brak pliku imion."}
	var kraje: Dictionary = dane["kraje"]
	if kraj == "" or not kraje.has(kraj) or not (kraje[kraj] is Dictionary):
		return {"id": null, "nazwa": null, "kolo": false, "powod": "Brak kraju w imionach. Nie losowano."}
	var blok: Dictionary = kraje[kraj]
	var lista: Variant = blok.get(klucz_listy, [])
	if not (lista is Array):
		return {"id": null, "nazwa": null, "kolo": false, "powod": "Brak listy imion."}
	var wagi := {}
	var nazwy := {}
	for pozycja in lista:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		var waga: Variant = pozycja.get("waga")
		if not _jest_liczba(waga) or float(waga) <= 0.0:
			continue
		if str(pozycja.get("cytat", "")) == "" and pozycja.get("zrodlo") == null:
			continue
		var id := str(pozycja["id"])
		wagi[id] = float(waga)
		nazwy[id] = str(pozycja.get("nazwa", id))
	if wagi.is_empty():
		return {"id": null, "nazwa": null, "kolo": false, "powod": "Lista imion bez wag ze źródła."}
	var id_w: String = los.losuj_kolo(wagi)
	if id_w == "":
		return {"id": null, "nazwa": null, "kolo": false, "powod": "Koło imion puste."}
	return {"id": id_w, "nazwa": nazwy.get(id_w, id_w), "kolo": true, "powod": ""}


func _zawod_kola(los, kraj: String, klucz_plci: String) -> Dictionary:
	var wynik := _zawod_kola_wagi(los, kraj, klucz_plci)
	SkryptKataloguZawodow.new().dopnij_prace(wynik)
	return wynik


func _zawod_kola_wagi(los, kraj: String, klucz_plci: String) -> Dictionary:
	var pusty := {"id": null, "nazwa": null, "kolo": false, "powod": "brak wag", "grupa_id": null, "grupa_nazwa": null, "zawod": null}
	var dane: Variant = _czytaj(PLIK_ZAWODY_KRAJE)
	if not (dane is Dictionary) or not (dane.get("kraje") is Dictionary):
		pusty["powod"] = "Brak pliku zawodów krajowych."
		return pusty
	var kraje: Dictionary = dane["kraje"]
	if kraj == "" or not kraje.has(kraj) or not (kraje[kraj] is Dictionary):
		pusty["powod"] = "Brak kraju w zawodach. Nie losowano."
		return pusty
	var blok: Dictionary = kraje[kraj]
	var lista: Variant = blok.get(klucz_plci, null)
	if lista == null and blok.get("wspolne") is Array:
		lista = blok["wspolne"]
	if not (lista is Array):
		pusty["powod"] = "Brak listy zawodów dla tej płci."
		return pusty
	var wagi_grup := {}
	var po_id_grup := {}
	for pozycja in lista:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		var waga: Variant = pozycja.get("waga")
		if not _jest_liczba(waga) or float(waga) <= 0.0:
			continue
		if str(pozycja.get("cytat", "")) == "" and pozycja.get("zrodlo") == null:
			continue
		var id := str(pozycja["id"])
		wagi_grup[id] = float(waga)
		po_id_grup[id] = pozycja
	if wagi_grup.is_empty():
		return pusty
	var id_grupy: String = los.losuj_kolo(wagi_grup)
	if id_grupy == "" or not po_id_grup.has(id_grupy):
		return pusty
	var grupa: Dictionary = po_id_grup[id_grupy]
	var zawody: Variant = grupa.get("zawody", null)
	# Flat lista bez zagnieżdżenia = sama grupa (stary format).
	if not (zawody is Array) or zawody.is_empty():
		return {
			"id": id_grupy,
			"nazwa": str(grupa.get("nazwa", id_grupy)),
			"grupa_id": id_grupy,
			"grupa_nazwa": str(grupa.get("nazwa", id_grupy)),
			"zawod": null,
			"isco08": grupa.get("isco08", null),
			"grupa_isco08": grupa.get("isco08", null),
			"kolo": true,
			"powod": "",
		}
	var wagi_z := {}
	var po_z := {}
	for z in zawody:
		if not (z is Dictionary) or not z.has("id"):
			continue
		var wz: Variant = z.get("waga")
		if not _jest_liczba(wz) or float(wz) <= 0.0:
			continue
		if str(z.get("cytat", "")) == "" and z.get("zrodlo") == null:
			continue
		var zid := str(z["id"])
		wagi_z[zid] = float(wz)
		po_z[zid] = z
	if wagi_z.is_empty():
		return {
			"id": id_grupy,
			"nazwa": str(grupa.get("nazwa", id_grupy)),
			"grupa_id": id_grupy,
			"grupa_nazwa": str(grupa.get("nazwa", id_grupy)),
			"zawod": null,
			"isco08": grupa.get("isco08", null),
			"grupa_isco08": grupa.get("isco08", null),
			"kolo": true,
			"powod": "Grupa bez wag zawodów 2-digit.",
		}
	var id_z: String = los.losuj_kolo(wagi_z)
	if id_z == "" or not po_z.has(id_z):
		return pusty
	var zawod: Dictionary = po_z[id_z]
	var nazwa_z := str(zawod.get("nazwa", id_z))
	return {
		"id": id_z,
		"nazwa": nazwa_z,
		"grupa_id": id_grupy,
		"grupa_nazwa": str(grupa.get("nazwa", id_grupy)),
		"zawod": nazwa_z,
		"isco08": zawod.get("isco08", null),
		"grupa_isco08": grupa.get("isco08", null),
		"kolo": true,
		"powod": "",
		"cytat": zawod.get("cytat", ""),
	}


func _jedno_kolo(los, blok: Variant) -> Dictionary:
	var pusty := {"id": null, "nazwa": null, "kolo": false, "powod": "brak wag"}
	if not (blok is Dictionary) or not (blok.get("pozycje") is Array):
		return pusty
	var wagi := {}
	var nazwy := {}
	for pozycja in blok["pozycje"]:
		if not (pozycja is Dictionary) or not pozycja.has("id"):
			continue
		var waga: Variant = pozycja.get("waga")
		if waga == null or not (waga is int or waga is float):
			continue
		if float(waga) < 0.0 or pozycja.get("zrodlo") == null:
			continue
		var id := str(pozycja["id"])
		wagi[id] = float(waga)
		nazwy[id] = str(pozycja.get("nazwa", id))
	if wagi.is_empty():
		return pusty
	var id: String = los.losuj_kolo(wagi)
	if id == "":
		return pusty
	return {"id": id, "nazwa": nazwy.get(id, id), "kolo": true, "powod": ""}


## Zarobki jednego rodzica z wielkiej grupy ISCO jego zawodu (GUS mediana–przeciętne wg płci).
func _zarobki_dla_pracy(praca: Variant, klucz_plci: String, kraj: String) -> Dictionary:
	var wynik := {
		"kraj": kraj,
		"kwota": null,
		"przedzial_id": null,
		"od_zl": null,
		"do_zl": null,
		"mediana_zl": null,
		"przecietne_zl": null,
		"waga": null,
		"kolo": false,
		"zarobki_z": null,
		"isco08_grupa": null,
		"grupa_nazwa": null,
		"plec_stat": klucz_plci,
		"zrodlo": null,
		"cytat": null,
		"powod": "Brak zawodu albo brak grupy w rozkładzie płac.",
	}
	if not (praca is Dictionary) or not bool(praca.get("kolo", false)):
		wynik["powod"] = "Zawód nie wylosowany — zarobków z grupy nie podstawiono."
		return wynik
	var grupa_id := _isco_wielka_grupa(praca)
	if grupa_id == "":
		wynik["powod"] = "Nie da się zmapować zawodu na wielką grupę ISCO."
		return wynik
	var dane: Variant = _czytaj(PLIK_ZAROBKOW_KRAJE)
	if not (dane is Dictionary) or not (dane.get("kraje") is Dictionary):
		wynik["powod"] = "Brak pliku rozkładu płac."
		return wynik
	var kraje: Dictionary = dane["kraje"]
	if kraj == "" or not kraje.has(kraj) or not (kraje[kraj] is Dictionary):
		wynik["powod"] = "Brak kraju w rozkładzie płac."
		return wynik
	var blok: Dictionary = kraje[kraj]
	wynik["zrodlo"] = blok.get("zrodlo", null)
	var grupy: Variant = blok.get("wielkie_grupy", {})
	if not (grupy is Dictionary) or not grupy.has(grupa_id) or not (grupy[grupa_id] is Dictionary):
		wynik["powod"] = "Brak liczb GUS dla grupy %s." % grupa_id
		wynik["isco08_grupa"] = grupa_id
		wynik["zarobki_z"] = "grupa_%s" % grupa_id
		return wynik
	var grupa: Dictionary = grupy[grupa_id]
	var plciowy: Variant = grupa.get(klucz_plci, null)
	if not (plciowy is Dictionary):
		plciowy = grupa.get("ogolem", {})
	if not (plciowy is Dictionary):
		wynik["powod"] = "Grupa %s bez mediany/przeciętnego." % grupa_id
		return wynik
	var mediana: Variant = plciowy.get("mediana_zl", null)
	var przecietne: Variant = plciowy.get("przecietne_zl", null)
	if not _jest_liczba(mediana) and not _jest_liczba(przecietne):
		wynik["powod"] = "Grupa %s: obie kwoty null." % grupa_id
		return wynik
	# Przedział UI = mediana–przeciętne (dwie oficjalne miary grupy; nie zgadywany rozrzut).
	var od_v: Variant = mediana if _jest_liczba(mediana) else przecietne
	var do_v: Variant = przecietne if _jest_liczba(przecietne) else mediana
	if _jest_liczba(od_v) and _jest_liczba(do_v) and float(od_v) > float(do_v):
		var tmp = od_v
		od_v = do_v
		do_v = tmp
	wynik["mediana_zl"] = mediana
	wynik["przecietne_zl"] = przecietne
	wynik["od_zl"] = od_v
	wynik["do_zl"] = do_v
	wynik["isco08_grupa"] = grupa_id
	wynik["zarobki_z"] = "grupa_%s" % grupa_id
	wynik["grupa_nazwa"] = str(grupa.get("nazwa", grupa_id))
	wynik["cytat"] = str(grupa.get("cytat", ""))
	wynik["kolo"] = true
	wynik["kwota"] = null
	wynik["powod"] = "Mediana i przeciętne wielkiej grupy ISCO ze źródła GUS (płeć rodzica). Rozkładu %% wewnątrz grupy nie ma — koła przedziałów nie kręcono. Zawód 2-digit zmapowany na %s. Kwoty na ekranie: 2 cyfry znaczące." % grupa_id
	ZaokraglenieZarobkow.zaokraglij_blok(wynik)
	return wynik


func _isco_wielka_grupa(praca: Dictionary) -> String:
	for klucz in ["isco08", "grupa_isco08", "isco08_grupa", "id"]:
		var isco := str(praca.get(klucz, "")).strip_edges().to_upper()
		if isco.begins_with("OC") and isco.length() >= 3:
			var cyfra := isco.substr(2, 1)
			if cyfra.is_valid_int() and int(cyfra) >= 1 and int(cyfra) <= 9:
				return "OC%s" % cyfra
	return ""


## Dochód gospodarstwa = suma przedziałów matki i ojca (gdy oboje mają grupę).
func _zarobki_gospodarstwa(matka_z: Variant, ojciec_z: Variant, kraj: String, los, miejsce: Variant) -> Dictionary:
	var wynik := {
		"kraj": kraj,
		"kwota": null,
		"przedzial_id": null,
		"od_zl": null,
		"do_zl": null,
		"mediana_zl": null,
		"przecietne_zl": null,
		"waga": null,
		"wies": null,
		"miasto": null,
		"kolo": false,
		"zarobki_z": "suma_rodzicow",
		"dochód_gospodarstwa": "suma_przedzialow_rodzicow",
		"zrodlo": null,
		"cytat": null,
		"powod": "Brak zarobków rodziców z grup zawodów.",
		"matka": matka_z if matka_z is Dictionary else {},
		"ojciec": ojciec_z if ojciec_z is Dictionary else {},
	}
	var m_ok := matka_z is Dictionary and bool(matka_z.get("kolo", false))
	var o_ok := ojciec_z is Dictionary and bool(ojciec_z.get("kolo", false))
	if not m_ok and not o_ok:
		# Awaryjnie: stary rozkład ogółem (bez zawodu) — tylko gdy naprawdę brak mapowania.
		return _zarobki_kola_ogolem(los, miejsce)
	var od_suma := 0.0
	var do_suma := 0.0
	var med_suma := 0.0
	var prz_suma := 0.0
	var ma_od := false
	var ma_do := false
	var ma_med := false
	var ma_prz := false
	var cytaty: PackedStringArray = []
	for blok in [matka_z, ojciec_z]:
		if not (blok is Dictionary) or not bool(blok.get("kolo", false)):
			continue
		if _jest_liczba(blok.get("od_zl")):
			od_suma += float(blok["od_zl"])
			ma_od = true
		if _jest_liczba(blok.get("do_zl")):
			do_suma += float(blok["do_zl"])
			ma_do = true
		if _jest_liczba(blok.get("mediana_zl")):
			med_suma += float(blok["mediana_zl"])
			ma_med = true
		if _jest_liczba(blok.get("przecietne_zl")):
			prz_suma += float(blok["przecietne_zl"])
			ma_prz = true
		var c := str(blok.get("cytat", "")).strip_edges()
		if c != "":
			cytaty.append(c)
		if wynik["zrodlo"] == null and blok.get("zrodlo") != null:
			wynik["zrodlo"] = blok.get("zrodlo")
	wynik["od_zl"] = od_suma if ma_od else null
	wynik["do_zl"] = do_suma if ma_do else null
	wynik["mediana_zl"] = med_suma if ma_med else null
	wynik["przecietne_zl"] = prz_suma if ma_prz else null
	wynik["cytat"] = " | ".join(cytaty) if not cytaty.is_empty() else null
	wynik["kolo"] = true
	wynik["kwota"] = null
	wynik["powod"] = "Dochód gospodarstwa = suma przedziałów (mediana–przeciętne) matki i ojca z ich wielkich grup ISCO (GUS). Osobne losowanie zarobków każdego rodzica po zawodzie. Suma na ekranie: 2 cyfry znaczące."
	ZaokraglenieZarobkow.zaokraglij_blok(wynik)
	return wynik


## Fallback: ogólny rozkład przedziałów kraju (bez zawodu) — tylko gdy rodzice bez mapowania.
func _zarobki_kola_ogolem(los, miejsce: Variant) -> Dictionary:
	var kraj := kraj_rodziny(miejsce)
	var wynik := {
		"kraj": kraj,
		"kwota": null,
		"przedzial_id": null,
		"od_zl": null,
		"do_zl": null,
		"waga": null,
		"wies": null,
		"miasto": null,
		"kolo": false,
		"zarobki_z": "ogolem_bez_zawodu",
		"dochód_gospodarstwa": "przedzial_ogolem",
		"zrodlo": null,
		"cytat": null,
		"powod": "Brak kraju w rozkładzie płac. Kwoty nie podstawiono.",
	}
	var dane: Variant = _czytaj(PLIK_ZAROBKOW_KRAJE)
	if not (dane is Dictionary) or not (dane.get("kraje") is Dictionary):
		wynik["powod"] = "Brak pliku rozkładu płac. Losowanie stoi."
		return wynik
	var kraje: Dictionary = dane["kraje"]
	if kraj == "" or not kraje.has(kraj) or not (kraje[kraj] is Dictionary):
		return wynik
	var blok: Dictionary = kraje[kraj]
	wynik["wies"] = blok.get("wies", null)
	wynik["miasto"] = blok.get("miasto", null)
	wynik["zrodlo"] = blok.get("zrodlo", null)
	var wagi := {}
	var po_id := {}
	var lista: Variant = blok.get("przedzialy", [])
	if lista is Array:
		for pozycja in lista:
			if not (pozycja is Dictionary):
				continue
			var id := str(pozycja.get("id", ""))
			var waga: Variant = pozycja.get("waga")
			if id == "" or not (waga is int or waga is float) or float(waga) <= 0.0:
				continue
			if str(pozycja.get("cytat", "")) == "":
				continue
			wagi[id] = float(waga)
			po_id[id] = pozycja
	if wagi.is_empty():
		wynik["powod"] = "Kraj jest, ale przedziały nie mają wagi ze źródła. Losowanie stoi."
		return wynik
	var id_wylosowane: String = los.losuj_kolo(wagi)
	if id_wylosowane == "" or not po_id.has(id_wylosowane):
		wynik["powod"] = "Koło nic nie wybrało."
		return wynik
	var wybrany: Dictionary = po_id[id_wylosowane]
	wynik["przedzial_id"] = id_wylosowane
	wynik["od_zl"] = wybrany.get("od_zl", null)
	wynik["do_zl"] = wybrany.get("do_zl", null)
	wynik["waga"] = wybrany.get("waga")
	wynik["cytat"] = wybrany.get("cytat")
	wynik["kolo"] = true
	wynik["kwota"] = null
	wynik["powod"] = "Awaryjny przedział ogółem (bez zawodu). Jednej kwoty w środku nie ma. Krańce na ekranie: 2 cyfry znaczące."
	ZaokraglenieZarobkow.zaokraglij_blok(wynik)
	return wynik


func kieszonkowe(ziarno: Dictionary = {}) -> Dictionary:
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	var wynik := {
		"kwota": null,
		"decyzja": null,
		"wagi_decyzji": {"odmowa": null, "na_prosbe": null, "stala_kwota": null},
		"kierunki": [],
		"reguly": [],
		"losowanie_kwoty": "stoi",
		"opis_losowania": "Puste nie znaczy, że kwota jest losowana z danych. Losowanie stoi, aż będzie źródło.",
		"powod": "Kwota i wagi decyzji są null, dopóki nie ma źródła. Losowanie stoi.",
		"na_poczatku_pieniadze_bohatera_glownie_stad": true,
	}
	if dane is Dictionary:
		wynik["reguly"] = dane.get("reguly_kierunku", [])
		wynik["wagi_decyzji"] = _wagi_kieszonkowego(dane)
		if _jest_liczba(dane.get("kwota")) and dane.get("zrodlo") != null:
			wynik["kwota"] = dane.get("kwota")
			wynik["powod"] = ""
	var kierunki: Array = []
	var cechy := _cechy_z(ziarno)
	if _ma_ceche(cechy, ["oszczedny", "skapy", "surowy"]):
		kierunki.append("czesciej_odmowa")
	if _ma_ceche(cechy, ["hojny"]):
		kierunki.append("czesciej_daje")
	var kwota_zarobkow: Variant = null
	var jest_przedzial := false
	if ziarno.get("zarobki") is Dictionary:
		if _jest_liczba(ziarno["zarobki"].get("kwota")):
			kwota_zarobkow = ziarno["zarobki"].get("kwota")
		elif ziarno["zarobki"].get("przedzial_id") != null:
			jest_przedzial = true
		elif bool(ziarno["zarobki"].get("kolo", false)) and (
			_jest_liczba(ziarno["zarobki"].get("od_zl"))
			or _jest_liczba(ziarno["zarobki"].get("mediana_zl"))
		):
			jest_przedzial = true
	if kwota_zarobkow != null and wynik["kwota"] == null:
		kierunki.append("zalezy_od_zarobkow")
		wynik["powod"] = "Jest kwota zarobków. Kieszonkowe ma iść z nią w górę, ale przelicznika nie ma. Kwota kieszonkowego zostaje null."
	elif jest_przedzial and wynik["kwota"] == null:
		kierunki.append("zalezy_od_zarobkow")
		wynik["powod"] = "Jest przedział zarobków ze źródła, nie ma jednej kwoty. Przelicznika kieszonkowego nie ma. Kwota zostaje null."
	elif wynik["kwota"] == null:
		wynik["powod"] = "Zarobki są null albo nie podane. Kwoty kieszonkowego nie wymyślono. Wagi decyzji są null."
	wynik["kierunki"] = kierunki
	wynik["decyzja"] = null
	return wynik


func _wagi_kieszonkowego(dane: Dictionary) -> Dictionary:
	var wagi := {"odmowa": null, "na_prosbe": null, "stala_kwota": null}
	var lista: Variant = dane.get("decyzje", [])
	if not (lista is Array):
		return wagi
	for decyzja in lista:
		if not (decyzja is Dictionary):
			continue
		var id := str(decyzja.get("id", ""))
		if not wagi.has(id):
			continue
		var waga: Variant = decyzja.get("waga")
		if not _jest_liczba(waga) or decyzja.get("zrodlo") == null:
			wagi[id] = null
			continue
		wagi[id] = waga
	return wagi


func kraj_rodziny(miejsce: Variant = null) -> String:
	if miejsce is Dictionary:
		for klucz in ["kraj_id", "kraj", "panstwo_id", "panstwo"]:
			var wartosc: Variant = miejsce.get(klucz)
			if wartosc != null and str(wartosc).strip_edges() != "":
				return str(wartosc).strip_edges().to_lower()
		return "polska"
	if miejsce is String and str(miejsce).strip_edges() != "":
		return str(miejsce).strip_edges().to_lower()
	return "polska"


func szansa_diety(kraj_id: String) -> Dictionary:
	var pusty := {
		"kraj_id": kraj_id,
		"ulamek_wegetarian": null,
		"ulamek_wegan": null,
		"rok": null,
		"zrodlo": null,
		"szansa": null,
		"brak_kraju": true,
	}
	var dane: Variant = _czytaj(PLIK_DIET)
	if not (dane is Dictionary):
		return pusty
	var kraje: Variant = dane.get("kraje", {})
	if not (kraje is Dictionary):
		return pusty
	var klucz := str(kraj_id).strip_edges().to_lower()
	if klucz == "" or not kraje.has(klucz):
		return pusty
	var kraj: Variant = kraje[klucz]
	if not (kraj is Dictionary):
		return pusty
	return {
		"kraj_id": klucz,
		"ulamek_wegetarian": kraj.get("ulamek_wegetarian", null),
		"ulamek_wegan": kraj.get("ulamek_wegan", null),
		"rok": kraj.get("rok", null),
		"zrodlo": kraj.get("zrodlo", null),
		"szansa": kraj.get("ulamek_wegetarian", null),
		"brak_kraju": false,
	}


func _wyzywienie(blok: Variant) -> Dictionary:
	var wynik := {
		"biedniejsi": null,
		"dba_o_zdrowie": null,
		"wegetarianie": null,
		"weganie": null,
		"prog_zamoznosci": null,
		"waga_wegetarian": null,
		"waga_wegan": null,
		"waga_dba_o_zdrowie": null,
		"kolo": false,
		"powod": "Brak wag. Reguł jedzenia nie losowano.",
	}
	if not (blok is Dictionary):
		return wynik
	for klucz in ["biedniejsi", "dba_o_zdrowie", "wegetarianie", "weganie", "prog_zamoznosci", "waga_wegetarian", "waga_wegan", "waga_dba_o_zdrowie"]:
		wynik[klucz] = blok.get(klucz)
	return wynik


func _charakter(blok: Variant, los = null) -> Array:
	## Uproszczone: 1–2 cechy z koła cech (jak w losowaniu). Lista w JSON zostaje pusta.
	if los != null:
		var ile_txt: String = los.losuj_kolo({"1": 1.0, "2": 1.0})
		var ile := 2 if ile_txt == "2" else 1
		var wylosowane: Array = los.losuj_cechy(ile)
		if not wylosowane.is_empty():
			return wylosowane
	var wynik: Array = []
	if blok is Dictionary:
		_dopisz_cechy(wynik, blok.get("cechy"))
	return wynik


## Tryb z charakteru (albo wag, gdy kiedyś będą). Do zapisu świata po Start / pierwszej prośbie.
func tryb_domyslny_kieszonkowego(ziarno: Dictionary) -> String:
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	return _normalizuj_tryb_kieszonkowego(_decyzja_kieszonkowego(ziarno, dane))


func etykieta_trybu_kieszonkowego(tryb: String) -> String:
	match _normalizuj_tryb_kieszonkowego(tryb):
		"stala_kwota":
			return "co tydzień"
		"na_prosbe":
			return "na prośbę"
		"odmowa":
			return "odmowa"
		_:
			return "nieustalone"


func _normalizuj_tryb_kieszonkowego(tryb: String) -> String:
	var t := tryb.strip_edges()
	if t == "stale_daje" or t == "stala_kwota":
		return "stala_kwota"
	if t == "na_prosbe" or t == "odmowa":
		return t
	return ""


## Wypłata tygodniowa tylko przy stala_kwota. Kwota z zapisu (ustalona) albo z mapy.
## aktywne=false → nie płaci (przed pierwszą udaną prośbą).
func wyplata_tygodniowa_kieszonkowego(ziarno: Dictionary, tryb: String, aktywne: bool = true, kwota_ustalona: Variant = null, wiek_lat: Variant = null) -> Dictionary:
	var tryb_n := _normalizuj_tryb_kieszonkowego(tryb)
	var wynik := {
		"tryb": tryb_n,
		"kwota": null,
		"dodano": false,
		"tekst": "",
		"powod": "",
		"zrodlo_wplywu": "kieszonkowe",
	}
	if not aktywne:
		wynik["powod"] = "Kieszonkowe nieaktywne — najpierw prośba."
		return wynik
	if tryb_n != "stala_kwota":
		wynik["powod"] = "Tryb nie wypłaca co tydzień."
		return wynik
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	if _jest_liczba(kwota_ustalona) and int(kwota_ustalona) > 0:
		wynik["kwota"] = int(kwota_ustalona)
	else:
		var kwota_info := _kwota_propozycja(ziarno, dane, wiek_lat)
		wynik["kwota"] = kwota_info.get("zl")
	if not _jest_liczba(wynik["kwota"]):
		wynik["powod"] = "kwota null"
		wynik["tekst"] = "Stałe kieszonkowe: brak kwoty w mapie przedziału."
		return wynik
	wynik["dodano"] = true
	wynik["tekst"] = "Kieszonkowe: +%d zł" % int(wynik["kwota"])
	return wynik


## Prośba o kieszonkowe. wiek_lat: poniżej progu → odmowa „za małe”.
## Po udanej prośbie: tryb stala_kwota + aktywacja wypłaty tygodniowej (robi main).
func popros_o_kieszonkowe(ziarno: Dictionary, tryb_zapisany: String = "", pierwsza_rozmowa: bool = true, wiek_lat: Variant = null) -> Dictionary:
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	var zarobki_txt := _tekst_przedzialu_zarobkow(ziarno.get("zarobki"))
	var wynik := {
		"decyzja": "odmowa",
		"decyzja_nazwa": "Odmawiają",
		"tryb": "odmowa",
		"kwota": null,
		"dodano": false,
		"aktywuj_stale": false,
		"propozycja_do_poprawki": false,
		"zarobki_rodziny": zarobki_txt,
		"tekst": "",
		"powod": "",
		"zrodlo_wplywu": "kieszonkowe",
	}
	var wiek_blok := _blok_wieku_kieszonkowego(dane, wiek_lat)
	if bool(wiek_blok.get("za_male", false)):
		wynik["tekst"] = str(wiek_blok.get("tekst", "Jesteś jeszcze za małe na kieszonkowe."))
		wynik["powod"] = "wiek_ponizej_progu"
		return wynik
	var tryb_istniejacy := _normalizuj_tryb_kieszonkowego(tryb_zapisany)
	var decyzja_id := ""
	if not pierwsza_rozmowa and tryb_istniejacy != "":
		decyzja_id = tryb_istniejacy
	else:
		decyzja_id = _normalizuj_tryb_kieszonkowego(_decyzja_kieszonkowego(ziarno, dane))
	wynik["decyzja"] = decyzja_id
	wynik["tryb"] = decyzja_id
	wynik["decyzja_nazwa"] = _nazwa_decyzji(dane, decyzja_id)
	if decyzja_id == "odmowa":
		wynik["tekst"] = "Rodzice odmawiają kieszonkowego."
		if zarobki_txt != "":
			wynik["tekst"] += " Zarobki rodziny: %s." % zarobki_txt
		wynik["powod"] = "Charakter / reguła kierunku."
		return wynik
	if decyzja_id == "stala_kwota" and not pierwsza_rozmowa and tryb_istniejacy == "stala_kwota":
		wynik["dodano"] = false
		wynik["tekst"] = "Dostajesz już stałą kwotę co tydzień (przy Następna tura)."
		wynik["powod"] = "stala_kwota_juz_ustalona"
		return wynik
	var kwota_info := _kwota_propozycja(ziarno, dane, wiek_lat)
	wynik["kwota"] = kwota_info.get("zl")
	wynik["propozycja_do_poprawki"] = bool(kwota_info.get("propozycja_do_poprawki", false))
	if not _jest_liczba(wynik["kwota"]):
		wynik["dodano"] = false
		wynik["tekst"] = "Rodzice chcą dać, ale w danych nie ma kwoty (ani propozycji). Pieniędzy nie dodano."
		if zarobki_txt != "":
			wynik["tekst"] += " Zarobki rodziny: %s." % zarobki_txt
		wynik["powod"] = "kwota null"
		return wynik
	wynik["dodano"] = true
	wynik["aktywuj_stale"] = true
	wynik["tryb"] = "stala_kwota"
	var etykieta := str(kwota_info.get("etykieta", ""))
	var nazwa_dec := str(wynik["decyzja_nazwa"])
	wynik["tekst"] = "%s: %d zł" % [nazwa_dec, int(wynik["kwota"])]
	if etykieta != "":
		wynik["tekst"] += " (%s)" % etykieta
	wynik["tekst"] += " Od teraz co tydzień."
	if bool(wynik["propozycja_do_poprawki"]):
		wynik["tekst"] += " Kwota to propozycja do poprawki, nie GUS."
	if zarobki_txt != "":
		wynik["tekst"] += " Zarobki rodziny: %s." % zarobki_txt
	wynik["powod"] = ""
	return wynik


func popros_o_podwyzke_kieszonkowego(ziarno: Dictionary, kwota_teraz: Variant, wiek_lat: Variant = null) -> Dictionary:
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	var wynik := {"ok": false, "kwota": null, "tekst": "", "dodano": false, "zrodlo_wplywu": "kieszonkowe_podwyzka"}
	var wiek_blok := _blok_wieku_kieszonkowego(dane, wiek_lat)
	if bool(wiek_blok.get("za_male", false)):
		wynik["tekst"] = str(wiek_blok.get("tekst", "Jesteś jeszcze za małe na kieszonkowe."))
		return wynik
	if not _jest_liczba(kwota_teraz) or int(kwota_teraz) <= 0:
		wynik["tekst"] = "Najpierw ustal stałe kieszonkowe (Poproś o kieszonkowe)."
		return wynik
	var pod: Variant = {}
	if dane is Dictionary:
		pod = dane.get("podwyzka", {})
	if not (pod is Dictionary):
		pod = {}
	var cechy := _cechy_z(ziarno)
	var odmowa: Variant = pod.get("odmowa_gdy_cechy", ["oszczedny", "skapy", "surowy"])
	if odmowa is Array and _ma_ceche(cechy, odmowa):
		wynik["tekst"] = str(pod.get("tekst_odmowa", "Rodzice nie chcą podnieść kieszonkowego."))
		return wynik
	var mnoznik := 1.25
	if _jest_liczba(pod.get("mnoznik")):
		mnoznik = float(pod["mnoznik"])
	var baza_info := _kwota_propozycja(ziarno, dane, wiek_lat)
	var baza := int(kwota_teraz)
	if _jest_liczba(baza_info.get("zl")):
		baza = int(baza_info["zl"])
	var nowa_surowa := int(round(float(kwota_teraz) * mnoznik))
	var max_m := 2.0
	if _jest_liczba(pod.get("max_mnoznik_od_bazy")):
		max_m = float(pod["max_mnoznik_od_bazy"])
	var sufit := int(round(float(baza) * max_m))
	if nowa_surowa > sufit:
		nowa_surowa = sufit
	var nowa := ZaokraglenieZarobkow.zaokraglij(_snap_kwoty_kieszonkowej(dane, nowa_surowa, "najblizsza_wyzsza_albo_najblizsza"))
	if nowa <= int(kwota_teraz):
		wynik["tekst"] = "Rodzice mówią, że to już maksimum."
		return wynik
	wynik["ok"] = true
	wynik["kwota"] = nowa
	var szablon := str(pod.get("tekst_ok", "Podwyżka kieszonkowego: teraz %d zł/tydzień."))
	wynik["tekst"] = szablon % nowa
	return wynik


func popros_o_pieniadze_jednorazowo(ziarno: Dictionary, wiek_lat: Variant = null) -> Dictionary:
	var dane: Variant = _czytaj(PLIK_KIESZONKOWEGO)
	var wynik := {"ok": false, "kwota": null, "dodano": false, "tekst": "", "zrodlo_wplywu": "pieniadze_jednorazowo"}
	var jed: Variant = {}
	if dane is Dictionary:
		jed = dane.get("jednorazowo", {})
	if not (jed is Dictionary):
		jed = {}
	var prog := 5
	if _jest_liczba(jed.get("minimalny_wiek_lat")):
		prog = int(jed["minimalny_wiek_lat"])
	elif dane is Dictionary and dane.get("wiek") is Dictionary and _jest_liczba(dane["wiek"].get("minimalny_wiek_lat")):
		prog = int(dane["wiek"]["minimalny_wiek_lat"])
	if _jest_liczba(wiek_lat) and int(wiek_lat) < prog:
		wynik["tekst"] = str(jed.get("tekst_za_male", "Jesteś jeszcze za małe, żeby prosić o pieniądze na zakupy."))
		return wynik
	var cechy := _cechy_z(ziarno)
	var odmowa: Variant = jed.get("odmowa_gdy_cechy", ["oszczedny", "skapy", "surowy"])
	if odmowa is Array and _ma_ceche(cechy, odmowa):
		wynik["tekst"] = str(jed.get("tekst_odmowa", "Rodzice odmawiają jednorazowej kwoty."))
		return wynik
	var baza := _kwota_propozycja(ziarno, dane, wiek_lat)
	if not _jest_liczba(baza.get("zl")):
		wynik["tekst"] = "Brak kwoty bazowej — nie da się policzyć jednorazówki."
		return wynik
	var mnoznik := 2.0
	if _jest_liczba(jed.get("mnoznik_bazy")):
		mnoznik = float(jed["mnoznik_bazy"])
	var kwota_surowa := int(round(float(baza["zl"]) * mnoznik))
	var kwota := ZaokraglenieZarobkow.zaokraglij(_snap_kwoty_kieszonkowej(dane, kwota_surowa))
	if kwota <= 0:
		wynik["tekst"] = "Kwota wyszła 0."
		return wynik
	wynik["ok"] = true
	wynik["dodano"] = true
	wynik["kwota"] = kwota
	var szablon := str(jed.get("tekst_ok", "Dostajesz jednorazowo: +%d zł (nie kieszonkowe)."))
	wynik["tekst"] = szablon % kwota
	return wynik


func _blok_wieku_kieszonkowego(dane: Variant, wiek_lat: Variant) -> Dictionary:
	var wynik := {"za_male": false, "tekst": "", "prog": null}
	if not (dane is Dictionary) or not (dane.get("wiek") is Dictionary):
		return wynik
	var wiek_cfg: Dictionary = dane["wiek"]
	var prog := 5
	if _jest_liczba(wiek_cfg.get("minimalny_wiek_lat")):
		prog = int(wiek_cfg["minimalny_wiek_lat"])
	wynik["prog"] = prog
	if not _jest_liczba(wiek_lat):
		return wynik
	if int(wiek_lat) < prog:
		wynik["za_male"] = true
		wynik["tekst"] = str(wiek_cfg.get("tekst_za_male", "Jesteś jeszcze za małe na kieszonkowe."))
	return wynik


func _decyzja_kieszonkowego(ziarno: Dictionary, dane: Variant) -> String:
	var wagi_ok := false
	var wagi := {}
	if dane is Dictionary:
		var lista: Variant = dane.get("decyzje", [])
		if lista is Array:
			for decyzja in lista:
				if not (decyzja is Dictionary):
					continue
				var id := str(decyzja.get("id", ""))
				var waga: Variant = decyzja.get("waga")
				if id == "" or not _jest_liczba(waga) or decyzja.get("zrodlo") == null:
					continue
				if float(waga) <= 0.0:
					continue
				wagi[id] = float(waga)
				wagi_ok = true
	if wagi_ok:
		var los := _Losowanie.new()
		var id_wagi: String = los.losuj_kolo(wagi)
		if id_wagi != "":
			return id_wagi
	# Bez wag: deterministycznie z charakteru, bez procentów.
	var cechy := _cechy_z(ziarno)
	var regula: Variant = {}
	if dane is Dictionary:
		regula = dane.get("decyzja_z_charakteru", {})
	if not (regula is Dictionary):
		regula = {}
	if _ma_ceche(cechy, ["hojny"]):
		return str(regula.get("hojny", "stala_kwota"))
	var odmowa: Variant = regula.get("odmowa_cechy", ["oszczedny", "skapy", "surowy"])
	if odmowa is Array and _ma_ceche(cechy, odmowa):
		return "odmowa"
	return str(regula.get("domyslnie", "na_prosbe"))


func _nazwa_decyzji(dane: Variant, id: String) -> String:
	var domyslne := {
		"odmowa": "Odmawiają",
		"na_prosbe": "Dają na prośbę",
		"stala_kwota": "Stała kwota",
	}
	if dane is Dictionary and dane.get("decyzje") is Array:
		for decyzja in dane["decyzje"]:
			if decyzja is Dictionary and str(decyzja.get("id", "")) == id:
				return str(decyzja.get("nazwa", domyslne.get(id, id)))
	return str(domyslne.get(id, id))


func _kwota_propozycja(ziarno: Dictionary, dane: Variant, wiek_lat: Variant = null) -> Dictionary:
	var wynik := {"zl": null, "etykieta": "", "propozycja_do_poprawki": false, "to_nie_gus": false, "baza_zl": null}
	if dane is Dictionary and _jest_liczba(dane.get("kwota")) and dane.get("zrodlo") != null:
		wynik["zl"] = int(dane["kwota"])
		wynik["baza_zl"] = wynik["zl"]
		return wynik
	if not (dane is Dictionary) or not (dane.get("kwoty_propozycja") is Dictionary):
		return wynik
	var blok: Dictionary = dane["kwoty_propozycja"]
	wynik["propozycja_do_poprawki"] = true
	wynik["to_nie_gus"] = bool(blok.get("to_nie_gus", blok.get("nie_gus", true)))
	var przedzial_id := ""
	if ziarno.get("zarobki") is Dictionary:
		przedzial_id = str(ziarno["zarobki"].get("przedzial_id", ""))
	var baza: Variant = null
	var etykieta := ""
	var lista: Variant = blok.get("wedlug_przedzialu", [])
	if przedzial_id != "" and lista is Array:
		for wpis in lista:
			if not (wpis is Dictionary):
				continue
			var przedzialy: Variant = wpis.get("przedzialy", [])
			if przedzialy is Array and przedzialy.has(przedzial_id) and _jest_liczba(wpis.get("zl")):
				baza = int(wpis["zl"])
				etykieta = str(wpis.get("etykieta", ""))
				break
	if baza == null and _jest_liczba(blok.get("gdy_brak_przedzialu_zl")):
		baza = int(blok["gdy_brak_przedzialu_zl"])
		etykieta = "zastępcza"
	if baza == null:
		return wynik
	wynik["baza_zl"] = int(baza)
	wynik["etykieta"] = etykieta
	var mnoznik := 1.0
	mnoznik *= _mnoznik_wieku_kieszonkowego(dane, wiek_lat)
	mnoznik *= _mnoznik_charakteru_kwoty(ziarno, dane)
	var surowa := maxi(1, int(round(float(baza) * mnoznik)))
	wynik["zl"] = ZaokraglenieZarobkow.zaokraglij(_snap_kwoty_kieszonkowej(dane, surowa))
	wynik["przed_snap_zl"] = surowa
	return wynik


func _lista_dozwolonych_kwot(dane: Variant) -> Array:
	var wynik: Array = []
	if not (dane is Dictionary) or not (dane.get("dozwolone_kwoty") is Dictionary):
		# Awaryjna lista zgodna z regułą w JSON.
		return [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120, 150, 200, 300, 400, 500, 600, 800, 1000]
	var blok: Dictionary = dane["dozwolone_kwoty"]
	if blok.get("lista_wzorcowa") is Array and not (blok["lista_wzorcowa"] as Array).is_empty():
		for v in blok["lista_wzorcowa"]:
			if _jest_liczba(v) and int(v) > 0:
				wynik.append(int(v))
	if wynik.is_empty():
		for n in range(10, 101, 10):
			wynik.append(n)
	var cykl: Array = []
	if blok.get("cykl_po_100") is Array:
		for v in blok["cykl_po_100"]:
			if _jest_liczba(v):
				cykl.append(int(v))
	if cykl.is_empty():
		cykl = [120, 150, 200, 300, 400, 500, 600, 800, 1000]
	var limit := 100000
	if _jest_liczba(blok.get("limit_max_zl")):
		limit = int(blok["limit_max_zl"])
	var mnozniki: Array = [1, 10, 100, 1000]
	if blok.get("mnozniki_rzedu") is Array:
		mnozniki = []
		for m in blok["mnozniki_rzedu"]:
			if _jest_liczba(m):
				mnozniki.append(int(m))
	for m in mnozniki:
		for baza_cykl in cykl:
			var kwota := int(baza_cykl) * int(m)
			if kwota > 100 and kwota <= limit and not wynik.has(kwota):
				wynik.append(kwota)
	wynik.sort()
	return wynik


func _snap_kwoty_kieszonkowej(dane: Variant, kwota: int, tryb: String = "najblizsza") -> int:
	var lista := _lista_dozwolonych_kwot(dane)
	if lista.is_empty():
		return maxi(1, kwota)
	if tryb == "najblizsza_wyzsza_albo_najblizsza":
		for v in lista:
			if int(v) > kwota:
				return int(v)
		return int(lista[lista.size() - 1])
	var najlepsza := int(lista[0])
	var dystans := absi(kwota - najlepsza)
	for v in lista:
		var d := absi(kwota - int(v))
		if d < dystans or (d == dystans and int(v) > najlepsza):
			dystans = d
			najlepsza = int(v)
	return najlepsza


func _mnoznik_wieku_kieszonkowego(dane: Variant, wiek_lat: Variant) -> float:
	if not _jest_liczba(wiek_lat) or not (dane is Dictionary) or not (dane.get("wiek") is Dictionary):
		return 1.0
	var lista: Variant = dane["wiek"].get("mnoznik_wieku", [])
	if not (lista is Array):
		return 1.0
	var w := int(wiek_lat)
	for wpis in lista:
		if not (wpis is Dictionary) or not _jest_liczba(wpis.get("mnoznik")):
			continue
		var od_l := int(wpis.get("od_lat", 0))
		var do_l := int(wpis.get("do_lat", 99))
		if w >= od_l and w <= do_l:
			return float(wpis["mnoznik"])
	return 1.0


func _mnoznik_charakteru_kwoty(ziarno: Dictionary, dane: Variant) -> float:
	var cfg: Variant = {}
	if dane is Dictionary:
		cfg = dane.get("charakter_kwota", {})
	if not (cfg is Dictionary):
		return 1.0
	var cechy := _cechy_z(ziarno)
	if _ma_ceche(cechy, ["hojny"]) and _jest_liczba(cfg.get("hojny_mnoznik")):
		return float(cfg["hojny_mnoznik"])
	if _ma_ceche(cechy, ["oszczedny", "skapy"]) and _jest_liczba(cfg.get("oszczedny_mnoznik")):
		return float(cfg["oszczedny_mnoznik"])
	if _jest_liczba(cfg.get("neutralny_mnoznik")):
		return float(cfg["neutralny_mnoznik"])
	return 1.0


func _tekst_przedzialu_zarobkow(blok: Variant) -> String:
	return ZaokraglenieZarobkow.tekst(blok)


func _cechy_z(ziarno: Dictionary) -> Array:
	var wynik: Array = []
	_dopisz_cechy(wynik, ziarno.get("cechy"))
	_dopisz_cechy(wynik, ziarno.get("charakter"))
	var blok: Variant = ziarno.get("charakter_rodzicow")
	if blok is Dictionary:
		_dopisz_cechy(wynik, blok.get("cechy"))
	for rola in ["matka", "ojciec"]:
		var osoba: Variant = ziarno.get(rola)
		if osoba is Dictionary:
			_dopisz_cechy(wynik, osoba.get("charakter"))
			_dopisz_cechy(wynik, osoba.get("cechy"))
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


func _jest_liczba(wartosc: Variant) -> bool:
	return wartosc is int or wartosc is float


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
