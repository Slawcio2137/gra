extends SceneTree

## Leniwe ogłoszenia i dojazd do auta.
## godot --headless --path . --script res://scripts/test_leniwe_auta_dojazd.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	var krakow: Dictionary = {}
	for m in miasta:
		if m is Dictionary and str(m.get("nazwa", "")) == "Kraków":
			krakow = m
			break
	if krakow.is_empty():
		printerr("FAIL: brak Krakowa")
		return 1
	var mid := str(krakow.get("id", ""))
	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 500, "miejsce": krakow, "relacja": 50},
		"id_miejsca_pobytu": mid,
		"rodzina": {
			"matka": {"imie": {"nazwa": "Anna"}, "miejsce": krakow, "relacja": 50, "charakter": ["oszczedny"]},
		},
		"rynek_zakupow": {"ziarno": 909},
	}
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, mid, 1)
	var n0 := _ile_aut(swiat)
	if n0 <= 0 or n0 > rynek.limit_okna_aut():
		printerr("FAIL: otwarcie ", n0)
		return 1
	var dodane := rynek.uzupelnij_okno_aut(swiat, miasta, {"poziom": "polska", "km": 9999.0, "stan": "uzywany", "tydzien": 1}, 5)
	if dodane < 1 or dodane > 5:
		printerr("FAIL: wyprzedzenie ", dodane)
		return 1
	if _ile_aut(swiat) > rynek.limit_okna_aut() + 5:
		printerr("FAIL: za dużo po scrollu ", _ile_aut(swiat))
		return 1
	for o in swiat["rynek_zakupow"]["oferty"]:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod" and str(o.get("stan", "")) == "uzywany":
			if rynek.tekst_odbioru_auta(o).find("dostawa") >= 0:
				printerr("FAIL: dostawa u prywatnego")
				return 1
	var przed := _ile_aut(swiat)
	swiat["tydzien"] = 2
	rynek.zapewnij_pule(swiat, miasta, mid, 2)
	if _ile_aut(swiat) > przed:
		printerr("FAIL: tura dodała auta")
		return 1

	var dodane_opel := rynek.uzupelnij_okno_aut(swiat, miasta, {
		"poziom": "polska",
		"km": 9999.0,
		"stan": "nowy",
		"tydzien": 2,
		"marki": ["Opel"],
	}, 4)
	if dodane_opel < 1:
		printerr("FAIL: Opel nie ma oferty salonu")
		return 1
	for o2 in swiat["rynek_zakupow"]["oferty"]:
		if not (o2 is Dictionary) or str(o2.get("marka", "")) != "Opel" or not bool(o2.get("salon", false)):
			continue
		var miasto_n := str(o2.get("miasto_nazwa", ""))
		if not rynek._jest_salon("Opel", miasto_n):
			printerr("FAIL: Opel poza listą ", miasto_n)
			return 1
		if miasto_n == "Chrzanów":
			printerr("FAIL: Opel w Chrzanowie bez źródła")
			return 1

	var obce := {
		"id": "auto_obce",
		"kategoria": "samochod",
		"stan": "uzywany",
		"stan_rzeczywisty": 60,
		"stan_deklarowany": 70,
		"sposob_odbioru": "osobisty",
		"miasto_id": "inne",
		"miasto_nazwa": "Gdańsk",
		"miasto_gracza": false,
		"odleglosc_km": 400.0,
		"spalanie": 6.0,
		"cena_zl": 10000,
		"sprzedawca": "osoba_prywatna",
	}
	swiat["rynek_zakupow"]["oferty"].append(obce)
	var bez := rynek.ocen_stan(swiat, "auto_obce", false)
	if bool(bez.get("ok", false)) or str(bez.get("powod", "")).find("dojazd") < 0:
		printerr("FAIL: ocena bez dojazdu ", bez)
		return 1
	var kasa0 := int(swiat["bohater"]["pieniadze"])
	var dojazd := rynek.wykonaj_dojazd(swiat, "auto_obce", {"sposob": "komunikacja", "bilet_zl": 4})
	if not bool(dojazd.get("ok", false)):
		printerr("FAIL: dojazd ", dojazd)
		return 1
	if not bool(dojazd.get("szacunek", false)):
		printerr("FAIL: międzymiastowy bilet nie jest szacunkiem")
		return 1
	var zaplacone := kasa0 - int(swiat["bohater"]["pieniadze"])
	if zaplacone <= 0:
		printerr("FAIL: nie pobrano biletu")
		return 1
	var ocena := rynek.ocen_stan(swiat, "auto_obce", false)
	if not bool(ocena.get("ok", false)):
		printerr("FAIL: ocena po dojeździe ", ocena)
		return 1
	var kasa1 := int(swiat["bohater"]["pieniadze"])
	var drugi := rynek.wykonaj_dojazd(swiat, "auto_obce", {"sposob": "komunikacja", "bilet_zl": 4})
	if not bool(drugi.get("drugi_raz", false)) or int(swiat["bohater"]["pieniadze"]) != kasa1:
		printerr("FAIL: drugi dojazd coś pobrał ", drugi)
		return 1

	var matka: Dictionary = swiat["rodzina"]["matka"]
	if not rynek.kierowca_prosi_o_paliwo(matka):
		printerr("FAIL: oszczędna przy relacji 50 powinna prosić")
		return 1
	var obce2 := obce.duplicate(true)
	obce2["id"] = "auto_paliwo"
	obce2["dojazd_oplacony"] = false
	swiat["rynek_zakupow"]["oferty"].append(obce2)
	var odmowa := rynek.wykonaj_dojazd(swiat, "auto_paliwo", {"sposob": "podwozka", "osoba_ref": "rodzic:matka", "dolozyc": false})
	if not bool(odmowa.get("ok", false)) or int(matka.get("relacja", 0)) >= 50:
		printerr("FAIL: odmowa paliwa nie spadła relacji ", odmowa, " rel=", matka.get("relacja"))
		return 1
	var kasa_po_podwozce := int(swiat["bohater"]["pieniadze"])
	var pomoc := rynek.popros_o_pomoc_oceny(swiat, "auto_paliwo", "rodzic:matka", {})
	if str(pomoc.get("powod", "")).find("dojazd") >= 0:
		printerr("FAIL: auto po podwózce znowu chce dojazd ", pomoc)
		return 1
	if int(swiat["bohater"]["pieniadze"]) != kasa_po_podwozce:
		printerr("FAIL: pomoc przy aucie na miejscu pobrała drugi dojazd")
		return 1
	# Świeże auto: pomoc musi dostać dojazd w tym samym wywołaniu.
	var obce3 := obce.duplicate(true)
	obce3["id"] = "auto_pomoc"
	obce3["dojazd_oplacony"] = false
	swiat["rynek_zakupow"]["oferty"].append(obce3)
	var bez_pomocy := rynek.popros_o_pomoc_oceny(swiat, "auto_pomoc", "rodzic:matka", {})
	if bool(bez_pomocy.get("ok", false)):
		printerr("FAIL: pomoc bez wyboru dojazdu")
		return 1
	var kasa2 := int(swiat["bohater"]["pieniadze"])
	var z_dojazdem := rynek.popros_o_pomoc_oceny(swiat, "auto_pomoc", "rodzic:matka", {"sposob": "komunikacja", "bilet_zl": 4})
	if not bool(z_dojazdem.get("ok", false)) and str(z_dojazdem.get("powod", "")).find("dojazd") >= 0:
		printerr("FAIL: pomoc z dojazdem ", z_dojazdem)
		return 1
	if not bool(swiat["rynek_zakupow"]["oferty"].filter(func(x): return x is Dictionary and str(x.get("id", "")) == "auto_pomoc" and bool(x.get("dojazd_oplacony", false))).size() > 0 if false else true):
		pass
	var na_miejscu := false
	for o3 in swiat["rynek_zakupow"]["oferty"]:
		if o3 is Dictionary and str(o3.get("id", "")) == "auto_pomoc" and bool(o3.get("dojazd_oplacony", false)):
			na_miejscu = true
	if not na_miejscu:
		printerr("FAIL: pomoc nie postawiła gracza przy aucie ", z_dojazdem)
		return 1
	var kasa3 := int(swiat["bohater"]["pieniadze"])
	if kasa3 >= kasa2:
		printerr("FAIL: pierwszy dojazd z pomocą nic nie kosztował")
		return 1
	rynek.ocen_stan(swiat, "auto_pomoc", true)
	if int(swiat["bohater"]["pieniadze"]) != kasa3:
		printerr("FAIL: ocena po pomocy pobrała drugi dojazd")
		return 1

	var kasa_b := int(swiat["bohater"]["pieniadze"])
	var benzyna := obce.duplicate(true)
	benzyna["id"] = "auto_benzyna"
	benzyna["dojazd_oplacony"] = false
	benzyna["naped"] = "spalinowy"
	benzyna["spalanie"] = 6.0
	benzyna["odleglosc_km"] = 100.0
	swiat["rynek_zakupow"]["oferty"].append(benzyna)
	var dokladka := rynek.wykonaj_dojazd(swiat, "auto_benzyna", {"sposob": "podwozka", "osoba_ref": "rodzic:matka", "dolozyc": true})
	if int(dokladka.get("koszt_zl", 0)) != 72 or kasa_b - int(swiat["bohater"]["pieniadze"]) != 72:
		printerr("FAIL: benzyna nie liczy 6 zł/l ", dokladka, " kasa=", swiat["bohater"]["pieniadze"])
		return 1
	var kasa_d := int(swiat["bohater"]["pieniadze"])
	var diesel := benzyna.duplicate(true)
	diesel["id"] = "auto_diesel"
	diesel["dojazd_oplacony"] = false
	diesel["naped"] = "diesel"
	swiat["rynek_zakupow"]["oferty"].append(diesel)
	var bez_on := rynek.wykonaj_dojazd(swiat, "auto_diesel", {"sposob": "podwozka", "osoba_ref": "rodzic:matka", "dolozyc": true})
	if bool(bez_on.get("ok", false)) == false or int(swiat["bohater"]["pieniadze"]) != kasa_d or _liczba_test(bez_on.get("koszt_zl")):
		printerr("FAIL: diesel dostał cenę ", bez_on)
		return 1
	var kasa_g := int(swiat["bohater"]["pieniadze"])
	var gaz := benzyna.duplicate(true)
	gaz["id"] = "auto_lpg"
	gaz["dojazd_oplacony"] = false
	gaz["naped"] = "lpg"
	swiat["rynek_zakupow"]["oferty"].append(gaz)
	var dok_gaz := rynek.wykonaj_dojazd(swiat, "auto_lpg", {"sposob": "podwozka", "osoba_ref": "rodzic:matka", "dolozyc": true})
	if int(dok_gaz.get("koszt_zl", 0)) != 30 or kasa_g - int(swiat["bohater"]["pieniadze"]) != 30:
		printerr("FAIL: LPG nie liczy 2,5 zł/l ", dok_gaz)
		return 1
	var kasa_e := int(swiat["bohater"]["pieniadze"])
	var ev := benzyna.duplicate(true)
	ev["id"] = "auto_ev"
	ev["dojazd_oplacony"] = false
	ev["naped"] = "elektryczny"
	ev["spalanie"] = 15.0
	ev["spalanie_jednostka"] = "kWh/100 km"
	swiat["rynek_zakupow"]["oferty"].append(ev)
	var dok_ev := rynek.wykonaj_dojazd(swiat, "auto_ev", {"sposob": "podwozka", "osoba_ref": "rodzic:matka", "dolozyc": true})
	if int(dok_ev.get("koszt_zl", 0)) != 27 or kasa_e - int(swiat["bohater"]["pieniadze"]) != 27:
		printerr("FAIL: prąd nie liczy 0,9 zł/kWh ", dok_ev)
		return 1

	print("OK leniwe+dojazd: okno=", n0, " +", dodane, " opel=", dodane_opel, " bilet=", zaplacone, " relacja=", matka.get("relacja"), " benzyna=", dokladka.get("koszt_zl"))
	return 0


func _liczba_test(v: Variant) -> bool:
	return v is int or v is float


func _ile_aut(swiat: Dictionary) -> int:
	var n := 0
	for o in swiat["rynek_zakupow"]["oferty"]:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod":
			n += 1
	return n
