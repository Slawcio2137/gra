extends SceneTree

## Zasięg ofert pracy: miasto, województwo, Polska. Pula z ludności, lista dalej po kilka.
## godot --headless --path . --script res://scripts/test_zasieg_pracy.gd

const Rynek = preload("res://scripts/rynek_pracy.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miejsca: Array = los.wszystkie_z_ludnoscia()
	if miejsca.is_empty():
		printerr("FAIL: brak miejsc")
		return 1
	if _zrodlo(rynek) != 0:
		return 1
	if _ludnosc(rynek, miejsca) != 0:
		return 1
	if _czynniki(rynek, miejsca) != 0:
		return 1
	if _okno(rynek, miejsca) != 0:
		return 1
	if _sufit(rynek) != 0:
		return 1
	if _brak_miasta(rynek, miejsca) != 0:
		return 1
	if _paliwo() != 0:
		return 1
	print("OK zasięg pracy")
	return 0


func _zrodlo(rynek) -> int:
	var blok: Variant = rynek.rubryka().get("zasieg", {})
	if not (blok is Dictionary):
		printerr("FAIL: brak zasiegu w rubryce")
		return 1
	var stawka: Dictionary = blok.get("oferta_na_mieszkancow", {})
	var wolne := int(stawka.get("wolne_miejsca_koniec_iv_kw_2024", 0))
	var lud_kraj := int(stawka.get("ludnosc_polski_31_12_2024", 0))
	var na := int(stawka.get("mieszkancow_na_oferte", 0))
	if wolne != 91000 or lud_kraj != 37489100:
		printerr("FAIL: źródła GUS ", wolne, " ", lud_kraj)
		return 1
	if na != int(round(float(lud_kraj) / float(wolne))) or na != 412 or na == 5000:
		printerr("FAIL: mieszkańcy na ofertę ", na)
		return 1
	if int(rynek.mieszkancow_na_oferte()) != 412:
		printerr("FAIL: funkcja stawki")
		return 1
	var czyn: Variant = blok.get("czynniki_branzy", {})
	if not (czyn is Dictionary) or not bool(czyn.get("propozycja_do_poprawki", false)):
		printerr("FAIL: czynniki bez propozycji")
		return 1
	return 0


func _ludnosc(rynek, miejsca: Array) -> int:
	var karta: Dictionary = rynek.miasto_bohatera(miejsca, "1203")
	if bool(karta.get("brak", false)) or str(karta.get("nazwa", "")) != "Chrzanów":
		printerr("FAIL: 1203 nie jest Chrzanowem ", karta)
		return 1
	if str(karta.get("nazwa", "")) == "Aleksandrów Kujawski":
		printerr("FAIL: siedziba to Aleksandrów")
		return 1
	var lud_m: int = int(karta.get("ludnosc", 0))
	if lud_m != 33193:
		printerr("FAIL: ludność Chrzanowa ", lud_m)
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "miasto", "1203034")) != lud_m:
		printerr("FAIL: id miasta nie trzyma ludności miasta")
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "miasto", "1203")) != lud_m:
		printerr("FAIL: wieś wzięła nie tę ludność")
		return 1
	var woj := str(karta.get("wojewodztwo", ""))
	var suma_w := 0
	var suma_p := 0
	var aleks := 0
	for m in miejsca:
		if not (m is Dictionary):
			continue
		var lud := int(m.get("ludnosc", 0))
		suma_p += lud
		if str(m.get("wojewodztwo", "")) == woj:
			suma_w += lud
		if str(m.get("nazwa", "")) == "Aleksandrów Kujawski":
			aleks = lud
	if aleks <= 0 or aleks > 20000:
		printerr("FAIL: Aleksandrów ", aleks)
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "wojewodztwo", "1203")) != suma_w:
		printerr("FAIL: województwo ", rynek.ludnosc_zakresu(miejsca, "wojewodztwo", "1203"), " != ", suma_w)
		return 1
	if suma_w < lud_m * 20 or suma_w < aleks * 20:
		printerr("FAIL: województwo za małe ", suma_w)
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "polska", "1203")) != suma_p:
		printerr("FAIL: Polska ", rynek.ludnosc_zakresu(miejsca, "polska", "nie-ma"), " != ", suma_p)
		return 1
	var pula_m: int = rynek.pula_ofert(lud_m, "miasto", {})
	var pula_w: int = rynek.pula_ofert(suma_w, "wojewodztwo", {})
	var pula_p: int = rynek.pula_ofert(suma_p, "polska", {})
	var baza_m: int = rynek.baza_ofert(lud_m)
	var baza_w: int = rynek.baza_ofert(suma_w)
	var baza_p: int = rynek.baza_ofert(suma_p)
	if pula_m != baza_m or baza_m != int(round(float(lud_m) / 412.0)):
		printerr("FAIL: miasto nie idzie za ludnością ", pula_m, " ", baza_m)
		return 1
	var mnoz_w: float = rynek.mnoznik_obszaru("wojewodztwo", {})
	var mnoz_p: float = rynek.mnoznik_obszaru("polska", {})
	if pula_w != int(round(float(baza_w) * mnoz_w)) or pula_p != int(round(float(baza_p) * mnoz_p)):
		printerr("FAIL: pula nie idzie za bazą ", pula_w, " ", pula_p)
		return 1
	if pula_m != 81 or pula_w != 9005 or pula_p != 98023:
		printerr("FAIL: przyjęte pule ", pula_m, " ", pula_w, " ", pula_p)
		return 1
	if pula_w < pula_m * 40:
		printerr("FAIL: województwo nie jest dużo większe od miasta ", pula_w, " ", pula_m)
		return 1
	if pula_p < 10000 or baza_p < 10000:
		printerr("FAIL: Polska za mała ", pula_p, " baza ", baza_p)
		return 1
	var podwojna: int = rynek.pula_ofert(suma_p * 2, "polska", {})
	if podwojna < int(float(pula_p) * 1.9) or podwojna > int(float(pula_p) * 2.1):
		printerr("FAIL: Polska nie skaluje się z ludnością ", pula_p, " ", podwojna)
		return 1
	print("Chrzanów lud=", lud_m, " pula=", pula_m, " baza=", baza_m)
	print("Województwo ", woj, " lud=", suma_w, " pula=", pula_w, " mnoznik=", mnoz_w)
	print("Polska lud=", suma_p, " pula=", pula_p, " mnoznik=", mnoz_p, " baza=", baza_p)
	print("Aleksandrów Kujawski lud=", aleks, " (nie jest zapasem)")
	return 0


func _czynniki(rynek, miejsca: Array) -> int:
	var lud_m: int = rynek.ludnosc_zakresu(miejsca, "miasto", "1203034")
	var lud_w: int = rynek.ludnosc_zakresu(miejsca, "wojewodztwo", "1203034")
	var lud_p: int = rynek.ludnosc_zakresu(miejsca, "polska", "1203034")
	var nisko := _tabela(0.9)
	var wysoko := _tabela(1.1)
	var f_m_n := {"zasieg": "miasto", "wielka_grupa": "2", "czynniki_test": nisko}
	var f_m_w := {"zasieg": "miasto", "wielka_grupa": "2", "czynniki_test": wysoko}
	var m_n: int = rynek.pula_ofert(lud_m, "miasto", f_m_n)
	var m_w: int = rynek.pula_ofert(lud_m, "miasto", f_m_w)
	if m_n != m_w or m_n <= 0:
		printerr("FAIL: czynniki ruszyły miasto ", m_n, " ", m_w)
		return 1
	if absf(float(rynek.mnoznik_obszaru("miasto", f_m_w)) - 1.0) > 0.0001:
		printerr("FAIL: mnożnik miasta")
		return 1
	var f_w_n := {"zasieg": "wojewodztwo", "wielka_grupa": "2", "czynniki_test": nisko}
	var f_w_w := {"zasieg": "wojewodztwo", "wielka_grupa": "2", "czynniki_test": wysoko}
	var w_n: int = rynek.pula_ofert(lud_w, "wojewodztwo", f_w_n)
	var w_w: int = rynek.pula_ofert(lud_w, "wojewodztwo", f_w_w)
	if w_w <= w_n:
		printerr("FAIL: czynniki nie ruszyły województwa ", w_n, " ", w_w)
		return 1
	if w_n <= m_n * 10:
		printerr("FAIL: branża w województwie nie jest większa od miasta ", w_n, " ", m_n)
		return 1
	var p_n: int = rynek.pula_ofert(lud_p, "polska", {"zasieg": "polska", "czynniki_test": nisko})
	var p_w: int = rynek.pula_ofert(lud_p, "polska", {"zasieg": "polska", "czynniki_test": wysoko})
	if p_w <= p_n or p_n < 10000:
		printerr("FAIL: czynniki Polski ", p_n, " ", p_w)
		return 1
	var cale_m: int = rynek.pula_ofert(lud_m, "miasto", {"czynniki_test": wysoko})
	var cale_m2: int = rynek.pula_ofert(lud_m, "miasto", {"czynniki_test": nisko})
	if cale_m != cale_m2 or cale_m != rynek.baza_ofert(lud_m):
		printerr("FAIL: całe miasto ruszone czynnikami ", cale_m, " ", cale_m2)
		return 1
	var mocniej := _tabela(1.0)
	mocniej["2"] = {"nacisk_branzy": 1.15, "zaawansowanie": 1.15, "brak_pracownikow": 1.15}
	var slabiej := _tabela(1.0)
	slabiej["2"] = {"nacisk_branzy": 0.85, "zaawansowanie": 0.85, "brak_pracownikow": 0.85}
	var mix_w: int = rynek.pula_ofert(lud_m, "miasto", {"zasieg": "miasto", "wielka_grupa": "2", "czynniki_test": mocniej})
	var mix_n: int = rynek.pula_ofert(lud_m, "miasto", {"zasieg": "miasto", "wielka_grupa": "2", "czynniki_test": slabiej})
	if mix_w <= mix_n:
		printerr("FAIL: mix miasta nie bierze czynników województwa ", mix_n, " ", mix_w)
		return 1
	var suma_w: int = rynek.pula_ofert(lud_m, "miasto", {"czynniki_test": mocniej})
	var suma_n: int = rynek.pula_ofert(lud_m, "miasto", {"czynniki_test": slabiej})
	if suma_w != rynek.baza_ofert(lud_m) or suma_n != suma_w or suma_w != 81:
		printerr("FAIL: suma Chrzanowa ruszyła się z 81 ", suma_w, " ", suma_n)
		return 1
	return 0


func _okno(rynek, miejsca: Array) -> int:
	var swiat := {"tydzien": 4, "id_miejsca_pobytu": "1203034"}
	var filtry := {"zasieg": "polska"}
	var otwarte: int = rynek.aktywuj(swiat, filtry, 4, miejsca, "1203034")
	var oferty: Array = swiat["rynek_pracy"]["oferty"]
	var pula: int = rynek.ostatnia_pula()
	if otwarte <= 0 or otwarte > rynek.okno_start() or oferty.size() > 8:
		printerr("FAIL: otwarcie Polski ", otwarte, " kart=", oferty.size())
		return 1
	if pula < 10000 or oferty.size() >= pula:
		printerr("FAIL: pula Polski ", pula, " kart=", oferty.size())
		return 1
	if rynek.ostatnie_proby() <= 0 or rynek.ostatnie_proby() > rynek.okno_start() * 12:
		printerr("FAIL: próby przy otwarciu ", rynek.ostatnie_proby())
		return 1
	if rynek.ostatnie_proby() >= pula:
		printerr("FAIL: próby przeszły całą pulę")
		return 1
	var dok: int = rynek.uzupelnij(swiat, filtry, rynek.wyprzedzenie(), 4, miejsca, "1203034")
	if dok < 1 or dok > rynek.wyprzedzenie():
		printerr("FAIL: dokładka ", dok)
		return 1
	if swiat["rynek_pracy"]["oferty"].size() > rynek.okno_start() + rynek.wyprzedzenie():
		printerr("FAIL: za dużo kart ", swiat["rynek_pracy"]["oferty"].size())
		return 1
	if swiat["rynek_pracy"]["oferty"].size() >= rynek.ostatnia_pula():
		printerr("FAIL: karty dogoniły pulę")
		return 1
	return 0


func _sufit(rynek) -> int:
	var male: Array = [{
		"id": "male",
		"nazwa": "Male",
		"typ": "miasto",
		"ludnosc": 800,
		"wojewodztwo": "Małopolskie",
		"panstwo": "Polska",
		"panstwo_id": "polska",
		"powiat_id": "male",
	}]
	var swiat := {"tydzien": 2}
	var filtry := {"zasieg": "miasto"}
	var baza: int = rynek.baza_ofert(800)
	if baza <= 0 or baza >= rynek.okno_start():
		printerr("FAIL: baza testowa ", baza)
		return 1
	var n: int = rynek.aktywuj(swiat, filtry, 2, male, "male")
	if n != baza or swiat["rynek_pracy"]["oferty"].size() != baza or rynek.ostatnia_pula() != baza:
		printerr("FAIL: sufit ", n, " pula=", rynek.ostatnia_pula())
		return 1
	var wiecej: int = rynek.uzupelnij(swiat, filtry, rynek.wyprzedzenie(), 2, male, "male")
	if wiecej != 0 or swiat["rynek_pracy"]["oferty"].size() != baza:
		printerr("FAIL: scroll przekroczył pulę ", wiecej)
		return 1
	return 0


func _brak_miasta(rynek, miejsca: Array) -> int:
	var karta: Dictionary = rynek.miasto_bohatera(miejsca, "nie-ma-takiego")
	if not bool(karta.get("brak", false)) or int(karta.get("ludnosc", -1)) != 0:
		printerr("FAIL: brak miasta coś znalazł ", karta)
		return 1
	if str(karta.get("nazwa", "")) == "Aleksandrów Kujawski":
		printerr("FAIL: zapas Aleksandrów")
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "miasto", "nie-ma-takiego")) != 0:
		printerr("FAIL: ludność znikąd")
		return 1
	if int(rynek.ludnosc_zakresu(miejsca, "wojewodztwo", "nie-ma-takiego")) != 0:
		printerr("FAIL: województwo znikąd")
		return 1
	var swiat := {"tydzien": 1, "id_miejsca_pobytu": "nie-ma-takiego"}
	var n: int = rynek.aktywuj(swiat, {"zasieg": "miasto"}, 1, miejsca, "nie-ma-takiego")
	var oferty: Array = swiat["rynek_pracy"]["oferty"] if swiat.get("rynek_pracy") is Dictionary else []
	if n != 0 or oferty.size() != 0 or rynek.ostatnia_pula() != 0:
		printerr("FAIL: puste miejsce dało oferty ", n, " ", oferty.size())
		return 1
	return 0


func _tabela(v: float) -> Dictionary:
	var out := {}
	for g in ["1", "2", "3", "4", "5", "6", "7", "8", "9"]:
		out[g] = {"nacisk_branzy": v, "zaawansowanie": v, "brak_pracownikow": v}
	return out


func _paliwo() -> int:
	if not FileAccess.file_exists("res://świat/polska/kraj.json"):
		printerr("FAIL: brak kraj.json")
		return 1
	var plik := FileAccess.open("res://świat/polska/kraj.json", FileAccess.READ)
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if not (dane is Dictionary):
		return 1
	var paliwo: Variant = dane.get("cena_paliwa", {})
	if not (paliwo is Dictionary):
		return 1
	if float(paliwo.get("benzyna", -1)) != 6.0 or float(paliwo.get("gaz", -1)) != 2.5 or float(paliwo.get("energia", -1)) != 0.9:
		printerr("FAIL: paliwo ", paliwo)
		return 1
	if paliwo.get("olej_napedowy", "brak") != null or paliwo.has("diesel"):
		printerr("FAIL: diesel")
		return 1
	return 0
