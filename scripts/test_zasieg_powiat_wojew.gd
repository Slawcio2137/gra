extends SceneTree

## Headless: poziomy zasięgu aut z powiatem/województwem.
## godot --headless --quit-after 3 --path . --script res://scripts/test_zasieg_powiat_wojew.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")
const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const Main = preload("res://scripts/main.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	# Szukaj marki zostaje.
	var marki: Array = ["Audi", "Ford"]
	if Main.marki_pasujace_do_szukania(marki, "fo") != ["Ford"]:
		printerr("FAIL: szukaj marek zepsute")
		return 1

	var rynek = Rynek.new()
	var conf: Dictionary = rynek._nieruchomosci_conf()
	var poziomy: Array = conf.get("zasieg_szukania_poziomy", []) if conf.get("zasieg_szukania_poziomy") is Array else []
	var ids: Array = []
	for p in poziomy:
		if p is Dictionary:
			ids.append(str(p.get("id", "")))
	var oczekiwane := ["miasto", "powiat", "wojewodztwo", "polska", "sasiedzi", "wysylka_zagranica"]
	for oid in oczekiwane:
		if not ids.has(oid):
			printerr("FAIL: brak poziomu zasięgu ", oid, " w conf, jest ", ids)
			return 1
	print("OK poziomy zasięgu: ", ids)

	var los = LosowanieSkrypt.new()
	var miasta: Array = los.miasta_polski()
	if miasta.size() < 10:
		printerr("FAIL: za mało miast")
		return 1
	var miasto: Dictionary = miasta[0]
	for m in miasta:
		if m is Dictionary and str(m.get("nazwa", "")).to_lower().find("krak") >= 0:
			miasto = m
			break
	var mid := str(miasto.get("id", ""))
	var pid := str(miasto.get("powiat_id", ""))
	var woj := str(miasto.get("wojewodztwo", ""))
	if pid == "" or woj == "":
		printerr("FAIL: miasto bez powiat_id/wojewodztwo: ", miasto.get("nazwa"))
		return 1

	var swiat := {
		"tydzien": 1,
		"bohater": {"pieniadze": 0, "miejsce": miasto},
		"id_miejsca_pobytu": mid,
		"majatek": {"nieruchomosci": [], "dobra": []},
		"rynek_zakupow": {"ziarno": 424242},
	}
	rynek.zapewnij_pule(swiat, miasta, mid, 1)
	rynek.aktywuj_zakladke_samochodow(swiat, miasta, mid, 1)

	var uzywane: Array = []
	for o in swiat["rynek_zakupow"]["oferty"]:
		if o is Dictionary and str(o.get("kategoria", "")) == "samochod" and str(o.get("stan", "")) == "uzywany":
			uzywane.append(o)
	if uzywane.is_empty():
		printerr("FAIL: brak używanych")
		return 1

	var z_polami := 0
	var inne_miasto_ten_powiat := 0
	var inne_woj := 0
	for o2 in uzywane:
		if str(o2.get("powiat_id", "")) != "" or str(o2.get("wojewodztwo", "")) != "":
			z_polami += 1
		if str(o2.get("miasto_id", "")) != mid and str(o2.get("powiat_id", "")) == pid:
			inne_miasto_ten_powiat += 1
		if str(o2.get("wojewodztwo", "")) != "" and str(o2.get("wojewodztwo", "")) != woj and str(o2.get("kraj", "PL")) == "PL":
			inne_woj += 1
	if z_polami < uzywane.size() / 2:
		printerr("FAIL: za mało ofert z powiat/województwo: ", z_polami, "/", uzywane.size())
		return 1

	var po_miescie: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "miasto")
	var po_powiecie: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "powiat")
	var po_woj: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "wojewodztwo")
	var po_pl: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "polska")
	var po_sas: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "sasiedzi")
	var po_zag: Array = rynek.oferty_filtrowane(swiat, "samochod", "uzywany", 9999.0, 0.0, 0.0, false, "", 0.0, 1.0e12, false, [], "", "wysylka_zagranica")

	if po_miescie.size() > po_powiecie.size():
		printerr("FAIL: miasto > powiat (", po_miescie.size(), " > ", po_powiecie.size(), ")")
		return 1
	if po_powiecie.size() > po_woj.size():
		printerr("FAIL: powiat > województwo (", po_powiecie.size(), " > ", po_woj.size(), ")")
		return 1
	if po_woj.size() > po_pl.size():
		printerr("FAIL: województwo > PL (", po_woj.size(), " > ", po_pl.size(), ")")
		return 1
	if po_pl.size() > po_sas.size():
		printerr("FAIL: PL > sąsiedzi (", po_pl.size(), " > ", po_sas.size(), ")")
		return 1
	if po_sas.size() > po_zag.size():
		printerr("FAIL: sąsiedzi > zagranica (", po_sas.size(), " > ", po_zag.size(), ")")
		return 1
	if po_zag.size() < uzywane.size():
		printerr("FAIL: zagranica powinna obejmować wszystkie używane")
		return 1

	# Oferta z innego województwa nie przechodzi filtra „powiat”.
	var obca := {
		"kategoria": "samochod",
		"stan": "uzywany",
		"miasto_id": "inne",
		"miasto_gracza": false,
		"powiat_id": "9999",
		"wojewodztwo": "Podlaskie" if woj != "Podlaskie" else "Pomorskie",
		"kraj": "PL",
		"region_szukania": "polska",
		"odleglosc_km": 100.0,
		"cena_zl": 10000,
	}
	if rynek.oferta_w_zasiegu_poziomu(obca, "powiat", swiat):
		printerr("FAIL: obcy powiat nie powinien przejść filtra powiat")
		return 1
	if not rynek.oferta_w_zasiegu_poziomu(obca, "polska", swiat):
		printerr("FAIL: PL powinno przepuścić obcą ofertę PL")
		return 1

	print(
		"OK filtr zasięgu: miasto=", po_miescie.size(),
		" powiat=", po_powiecie.size(),
		" woj=", po_woj.size(),
		" PL=", po_pl.size(),
		" sąsiedzi=", po_sas.size(),
		" zagranica=", po_zag.size(),
		" inne_powiat=", inne_miasto_ten_powiat,
		" inne_woj=", inne_woj
	)
	return 0
