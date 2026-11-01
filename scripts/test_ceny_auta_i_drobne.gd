extends SceneTree

## Cena auta od katalogu oraz drobne na tej samej puli co auta.
## godot --headless --path . --script res://scripts/test_ceny_auta_i_drobne.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if rynek.zaokraglij_cene_auta(48000) != 48000:
		printerr("FAIL: 48000 nie może spaść do 2 cyfr, jest ", rynek.zaokraglij_cene_auta(48000))
		return 1
	if rynek.zaokraglij_cene_auta(38000) < 30000:
		printerr("FAIL: zaokrąglenie auta zjadło dziesiątki tysięcy")
		return 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 50
	var min_zwykle := 100000000
	var max_zwykle := 0
	for _i in 40:
		var c: Variant = rynek._cena_auta_z_katalogu(50000, "uzywany", rng, 70, 80000, null, false)
		if not _liczba(c):
			printerr("FAIL: brak ceny używanego z katalogu 50000")
			return 1
		var v := int(c)
		min_zwykle = mini(min_zwykle, v)
		max_zwykle = maxi(max_zwykle, v)
		if v < 20000 or v > 48000:
			printerr("FAIL: 50 tys. przy 80 tys. km i stanie 70 dało ", v)
			return 1
	print("OK zwykłe 50k / 80 tys. km / stan 70: ", min_zwykle, "–", max_zwykle)
	for _j in 20:
		var c2: Variant = rynek._cena_auta_z_katalogu(50000, "uzywany", rng, 40, 180000, 4000, true)
		if not _liczba(c2) or int(c2) < 10000:
			printerr("FAIL: mediana 4 tys. albo tier zbiły 50 tys. do ", c2)
			return 1
		var c3: Variant = rynek._cena_auta_z_katalogu(50000, "uzywany", rng, 20, 320000, null, true)
		if not _liczba(c3) or int(c3) < 10000:
			printerr("FAIL: wrak 50 tys. przy 320 tys. km dał ", c3)
			return 1
	var c_nowe: Variant = rynek._cena_auta_z_katalogu(50000, "nowy", rng, 100, 0, null, false)
	if not _liczba(c_nowe) or int(c_nowe) < 50000 or int(c_nowe) > 54000:
		printerr("FAIL: nowe 50 tys. nie jest przy katalogu: ", c_nowe)
		return 1
	var c_kotw: Variant = rynek._cena_auta_z_katalogu(null, "uzywany", rng, 70, 180000, 4600, false)
	if not _liczba(c_kotw) or int(c_kotw) < 2500 or int(c_kotw) > 8000:
		printerr("FAIL: kotwica 4600 bez katalogu wyszła ", c_kotw)
		return 1
	print("OK nowe przy katalogu=", c_nowe, " kotwica bez katalogu=", c_kotw)

	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var kotwica: Dictionary = rynek._miasto_po_id(miasta, "1203")
	var mid := str(kotwica.get("id", ""))
	rng.seed = 11
	var probki := 0
	for _k in 120:
		var o: Dictionary = rynek._losuj_samochod(kotwica, rng, mid, {}, "uzywany")
		if not _liczba(o.get("cena_katalog_zl")) or not _liczba(o.get("cena_zl")):
			continue
		var kat := float(o["cena_katalog_zl"])
		if kat < 45000.0 or kat > 70000.0:
			continue
		if int(o.get("przebieg_km", 0)) > 200000:
			continue
		if bool(o.get("tier_tani", false)):
			continue
		probki += 1
		if float(o["cena_zl"]) < 12000.0:
			printerr("FAIL: katalog ", kat, " używany ", o.get("przebieg_km"), " km → ", o.get("cena_zl"))
			return 1
	if probki < 3:
		printerr("FAIL: za mało zwykłych aut z katalogu ~50 tys. w próbie: ", probki)
		return 1
	print("OK losowane auta z katalogu 45–70 tys., próbki=", probki)

	var lud_m: int = rynek.ludnosc_zakresu("miasto", "1203")
	var lud_p: int = rynek.ludnosc_zakresu("polska", "1203")
	var auta_m: int = rynek.pula_w_zasiegu("miasto", "1203", "samochod", "uzywany")
	var auta_p: int = rynek.pula_w_zasiegu("polska", "1203", "samochod", "uzywany")
	if auta_m != int(round(float(lud_m) / 1500.0)) or auta_p != int(round(float(lud_p) / 1500.0)):
		printerr("FAIL: auta zeszły z 1/1500 ", auta_m, " ", auta_p)
		return 1
	var tel_u: int = rynek.pula_w_zasiegu("miasto", "1203", "telefon", "uzywany")
	var tel_n: int = rynek.pula_w_zasiegu("miasto", "1203", "telefon", "nowy")
	var tel_up: int = rynek.pula_w_zasiegu("polska", "1203", "telefon", "uzywany")
	var tel_np: int = rynek.pula_w_zasiegu("polska", "1203", "telefon", "nowy")
	var row_u: int = rynek.pula_w_zasiegu("miasto", "1203", "rower", "uzywany")
	var row_up: int = rynek.pula_w_zasiegu("polska", "1203", "rower", "uzywany")
	var modele_tel: int = rynek.liczba_modeli_katalogu("telefon")
	if modele_tel < 2:
		printerr("FAIL: katalog telefonów pusty")
		return 1
	if tel_n != modele_tel or tel_np != modele_tel:
		printerr("FAIL: nowy telefon nie jest katalogiem ", tel_n, " ", tel_np, " modele ", modele_tel)
		return 1
	var stare_nowe_pl := int(round(float(lud_p) / 4000.0))
	if tel_np >= stare_nowe_pl / 5:
		printerr("FAIL: pula nowych telefonów w Polsce nadal jak 1/4000 ", tel_np, " vs ", stare_nowe_pl)
		return 1
	if rynek.stan_krajowy_uzywanych("telefon") != 15000 or rynek.stan_krajowy_uzywanych("rower") != 45000:
		printerr("FAIL: stan krajowy telefon/rower")
		return 1
	if rynek.stan_krajowy_uzywanych("laptop") != 5000 or rynek.stan_krajowy_uzywanych("komputer") != 2500 or rynek.stan_krajowy_uzywanych("sprzet") != 3750:
		printerr("FAIL: stan krajowy laptop/komputer/sprzet")
		return 1
	var oczek_tel := int(round(float(lud_m) * 15000.0 / float(lud_p)))
	var oczek_row := int(round(float(lud_m) * 45000.0 / float(lud_p)))
	if tel_u != oczek_tel or tel_up != 15000 or row_u != oczek_row or row_up != 45000:
		printerr("FAIL: używane telefon/rower ", tel_u, "/", tel_up, " rower ", row_u, "/", row_up, " oczek ", oczek_tel, " ", oczek_row)
		return 1
	if tel_u >= row_u or tel_up >= row_up:
		printerr("FAIL: używany telefon nie jest rzadszy od roweru ", tel_u, " ", row_u, " ", tel_up, " ", row_up)
		return 1
	if rynek.pula_w_zasiegu("polska", "1203", "laptop", "uzywany") != 5000:
		printerr("FAIL: używane laptopy Polska")
		return 1
	if rynek.pula_w_zasiegu("polska", "1203", "komputer", "uzywany") != 2500:
		printerr("FAIL: używane komputery Polska")
		return 1
	if rynek.pula_w_zasiegu("polska", "1203", "sprzet", "uzywany") != 3750:
		printerr("FAIL: używany sprzęt Polska")
		return 1
	for kat_n in ["laptop", "komputer", "rower", "sprzet"]:
		var n_m: int = rynek.pula_w_zasiegu("miasto", "1203", kat_n, "nowy")
		var n_p: int = rynek.pula_w_zasiegu("polska", "1203", kat_n, "nowy")
		var modele: int = rynek.liczba_modeli_katalogu(kat_n)
		if modele < 1 or n_m != modele or n_p != modele:
			printerr("FAIL: nowe ", kat_n, " ", n_m, " ", n_p, " katalog ", modele)
			return 1
	print("OK pula telefon używany/nowy miasto=", tel_u, "/", tel_n, " polska=", tel_up, "/", tel_np, " rower używany=", row_u, "/", row_up, " auta=", auta_m, "/", auta_p)

	var swiat := {
		"tydzien": 1,
		"rynek_zakupow": {
			"ziarno": 5,
			"miasto_gracza_id": mid,
			"miejsce_zrodlo_id": "1203",
			"oferty": [],
		},
	}
	var dodane: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "uzywany",
	}, 8)
	if dodane < 1 or dodane > 8:
		printerr("FAIL: okno telefonów ", dodane)
		return 1
	var wysylka := 0
	var oferty: Array = swiat["rynek_zakupow"]["oferty"]
	for o2 in oferty:
		if not (o2 is Dictionary) or str(o2.get("kategoria", "")) != "telefon":
			continue
		if str(o2.get("stan", "")) != "uzywany":
			printerr("FAIL: strona używana dała ", o2.get("stan"))
			return 1
		if str(o2.get("sposob_odbioru", "")) == "wysylka":
			wysylka += 1
			if int(o2.get("cena_dostawy_zl", 0)) != 15:
				printerr("FAIL: wysyłka nie 15 zł ", o2.get("cena_dostawy_zl"))
				return 1
			var tekst := " ".join(PackedStringArray(rynek.linie_karty_drobiazgu(o2)))
			if tekst.find("wysyłka 15 zł") < 0 or tekst.find("używany") < 0 or tekst.find("zł") < 0:
				printerr("FAIL: karta wysyłki ", tekst)
				return 1
			if tekst.find("Segment") >= 0 or tekst.find("lata_od") >= 0:
				printerr("FAIL: karta ma wypełniacz ", tekst)
				return 1
		var rzecz: Array = o2.get("usterki_rzeczywiste", []) if o2.get("usterki_rzeczywiste") is Array else []
		var dek: Array = o2.get("usterki_deklarowane", []) if o2.get("usterki_deklarowane") is Array else []
		if dek.size() > rzecz.size():
			printerr("FAIL: deklarowane bez rzeczywistych")
			return 1
	if wysylka < 1:
		printerr("FAIL: brak telefonu z wysyłką w oknie Polski")
		return 1
	var nowe_n: int = rynek.uzupelnij_okno_dobr(swiat, miasta, {
		"poziom": "miasto",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "nowy",
	}, 8)
	if nowe_n != modele_tel:
		printerr("FAIL: nowe telefony w mieście ", nowe_n, " katalog ", modele_tel)
		return 1
	var widziane := {}
	for o3 in swiat["rynek_zakupow"]["oferty"]:
		if not (o3 is Dictionary) or str(o3.get("stan", "")) != "nowy" or str(o3.get("kategoria", "")) != "telefon":
			continue
		var kid := str(o3.get("katalog_id", ""))
		if kid == "" or widziane.has(kid):
			printerr("FAIL: nowy telefon bez unikalnego modelu ", kid)
			return 1
		widziane[kid] = true
		var r3: Array = o3.get("usterki_rzeczywiste", []) if o3.get("usterki_rzeczywiste") is Array else []
		var d3: Array = o3.get("usterki_deklarowane", []) if o3.get("usterki_deklarowane") is Array else []
		if not r3.is_empty() or not d3.is_empty():
			printerr("FAIL: nowy telefon ma usterki")
			return 1
		var karta_n := " ".join(PackedStringArray(rynek.linie_karty_drobiazgu(o3)))
		if karta_n.find("nowy") < 0 or karta_n.find("zł") < 0 or karta_n.find("++++") < 0:
			printerr("FAIL: karta nowego telefonu ", karta_n)
			return 1
		if karta_n.find("bateria") >= 0 or karta_n.find("ekran") >= 0 or karta_n.find("szybka") >= 0:
			printerr("FAIL: nowy telefon pokazuje baterię albo ekran ", karta_n)
			return 1
	if widziane.size() != modele_tel:
		printerr("FAIL: modele nowych telefonów ", widziane.size())
		return 1
	var swiat_pl := {
		"tydzien": 1,
		"rynek_zakupow": {
			"ziarno": 9,
			"miasto_gracza_id": mid,
			"miejsce_zrodlo_id": "1203",
			"oferty": [],
		},
	}
	var nowe_pl: int = rynek.uzupelnij_okno_dobr(swiat_pl, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"kategoria": "telefon",
		"stan": "nowy",
	}, 30)
	if nowe_pl != modele_tel:
		printerr("FAIL: Polska nowych telefonów ", nowe_pl, " katalog ", modele_tel)
		return 1
	print("OK telefony: używane z wysyłką=", wysylka, " nowe bez usterek=", nowe_n, " polska nowe=", nowe_pl)

	for kat in ["laptop", "komputer", "rower"]:
		var jeden: Dictionary = rynek._losuj_dobro(kat, kotwica, rng, mid, {}, kotwica, "uzywany")
		jeden["sposob_odbioru"] = "wysylka"
		jeden["cena_dostawy_zl"] = 15
		jeden["usterki_deklarowane"] = []
		var linia := " ".join(PackedStringArray(rynek.linie_karty_drobiazgu(jeden)))
		if linia.find("używany") < 0 or linia.find("zł") < 0 or linia.find("wysyłka 15 zł") < 0:
			printerr("FAIL: karta ", kat, " ", linia)
			return 1
		if linia.find("Segment") >= 0:
			printerr("FAIL: segment na karcie ", kat)
			return 1
	var zbity := {
		"kategoria": "telefon",
		"nazwa": "Test Phone",
		"stan": "uzywany",
		"cena_zl": 450,
		"stan_deklarowany": 60,
		"usterki_deklarowane": ["zbita_szybka", "slaba_bateria"],
		"sposob_odbioru": "wysylka",
		"cena_dostawy_zl": 15,
		"miasto_nazwa": "Kraków",
		"odleglosc_km": 40,
	}
	var linia_z := " ".join(PackedStringArray(rynek.linie_karty_drobiazgu(zbity)))
	if linia_z.find("Zbita szybka") < 0 or linia_z.find("Słaba bateria") < 0 or linia_z.find("wysyłka 15 zł") < 0:
		printerr("FAIL: uszkodzony telefon nie pokazuje wady ", linia_z)
		return 1
	if rynek.tekst_plusow(4) != "++++" or rynek.tekst_plusow(2) != "++":
		printerr("FAIL: plusy z cyfrą ", rynek.tekst_plusow(4))
		return 1
	if rynek.tekst_plusow(4).find("4") >= 0:
		printerr("FAIL: karta plusów ma cyfrę przesunięcia")
		return 1
	print("OK karty laptop/komputer/rower i wady telefonu")

	var bazowy := {
		"bohater": {},
		"lokum_startowe": {"wygoda": 40},
		"majatek": {"nieruchomosci": [], "dobra": []},
	}
	if rynek.przelicz_zadowolenie_docelowe(bazowy) != 50:
		printerr("FAIL: wygoda 40 bez dóbr nie daje 50")
		return 1
	var rowny := {
		"kategoria": "telefon",
		"stan": "nowy",
		"kupiono_tydzien": 1,
		"usterki_rzeczywiste": [],
		"usterki_deklarowane": [],
		"stan_deklarowany": 100,
	}
	var dwa := bazowy.duplicate(true)
	dwa["majatek"]["dobra"] = [rowny.duplicate(true), rowny.duplicate(true)]
	var doc_dwa: int = rynek.przelicz_zadowolenie_docelowe(dwa)
	if doc_dwa != 54:
		printerr("FAIL: dwa równe telefony ++++ dały ", doc_dwa, " a nie 54 (50+4)")
		return 1
	var slabszy := {
		"kategoria": "telefon",
		"stan": "uzywany",
		"kupiono_tydzien": 1,
		"stan_deklarowany": 60,
		"usterki_rzeczywiste": ["poodzierana_obudowa"],
		"usterki_deklarowane": ["poodzierana_obudowa"],
	}
	if rynek.plusy_oferty(slabszy) != 2 or rynek.plusy_oferty(rowny) != 4:
		printerr("FAIL: mapa plusów ", rynek.plusy_oferty(slabszy), " ", rynek.plusy_oferty(rowny))
		return 1
	var progres := bazowy.duplicate(true)
	progres["majatek"]["dobra"] = [slabszy.duplicate(true)]
	var doc_2: int = rynek.przelicz_zadowolenie_docelowe(progres)
	progres["majatek"]["dobra"].append(rowny.duplicate(true))
	var doc_4: int = rynek.przelicz_zadowolenie_docelowe(progres)
	if doc_2 != 52 or doc_4 != 54 or doc_4 - doc_2 != 2:
		printerr("FAIL: ++ → ++++ dodało ", doc_4 - doc_2, " doc ", doc_2, " ", doc_4)
		return 1
	var po_oddaniu: Dictionary = rynek.oddaj_dobro(progres, 1)
	if not bool(po_oddaniu.get("ok", false)) or int(po_oddaniu.get("docelowe", -1)) != 52:
		printerr("FAIL: oddanie lepszego nie wróciło do ++ ", po_oddaniu)
		return 1
	print("OK plusy: dwa równe=4 nie 8, ++ do ++++ = +2, oddanie wraca do 52")
	print("PASS ceny aut i drobne")
	return 0


func _liczba(v: Variant) -> bool:
	return v is int or v is float
