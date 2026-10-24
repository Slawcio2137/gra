extends SceneTree

## Headless: usterki używanych dóbr (telefon/laptop/rower/sprzęt) + rabat ceny + wykrywanie.
## godot --headless --quit-after 3 --path . --script res://scripts/test_usterki_dobr.gd

const Rynek = preload("res://scripts/rynek_zakupow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var rynek = Rynek.new()
	if not FileAccess.file_exists("res://zakupy/usterki_dobr.json"):
		printerr("FAIL: brak zakupy/usterki_dobr.json")
		return 1
	var root := rynek.usterki_dobr_katalog()
	if not (root.get("kategorie") is Dictionary):
		printerr("FAIL: brak kategorii w usterki_dobr")
		return 1
	for kid in ["telefon", "laptop", "komputer", "rower", "sprzet"]:
		var lista: Array = rynek.lista_usterek_meta(kid)
		if lista.is_empty():
			printerr("FAIL: pusta lista usterek dla ", kid)
			return 1
	var sprzet_sluch: Array = rynek.lista_usterek_meta("sprzet", "sluchawki")
	var ma_trzesz := false
	var ma_klaw := false
	for u in sprzet_sluch:
		if not (u is Dictionary):
			continue
		if str(u.get("id", "")) == "trzeszczenie":
			ma_trzesz = true
		if str(u.get("id", "")) == "zuzyte_klawisze":
			ma_klaw = true
	if not ma_trzesz or ma_klaw:
		printerr("FAIL: filtr podkategorii słuchawek: trzesz=", ma_trzesz, " klaw=", ma_klaw)
		return 1
	print("OK katalog usterek dóbr + filtr sprzet/sluchawki")

	var rabat := rynek.rabat_ceny_z_usterek(["zbita_szybka", "slaba_bateria"], "telefon")
	# powaga 3+3=6 * 0.035 = 0.21
	if abs(rabat - 0.21) > 0.001:
		printerr("FAIL: rabat telefon oczekiwano ~0.21 jest=", rabat)
		return 1
	var rabat_max := rynek.rabat_ceny_z_usterek(
		["zbita_szybka", "slaba_bateria", "po_zalaniu", "glosnik_trzeszczy", "mikrofon_slab", "port_luzny"],
		"telefon"
	)
	if rabat_max > 0.42 + 0.001:
		printerr("FAIL: rabat ponad max_rabat: ", rabat_max)
		return 1
	print("OK rabat ceny z powagi")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var miasto := {"id": "test", "nazwa": "Testowo", "ludnosc": 100000}
	var trafione := 0
	var z_deklarowanymi := 0
	for i in 80:
		var o: Dictionary = rynek._losuj_dobro("telefon", miasto, rng, "test", {})
		if str(o.get("stan", "")) != "uzywany":
			continue
		trafione += 1
		if not (o.get("usterki_rzeczywiste") is Array):
			printerr("FAIL: brak usterki_rzeczywiste na używanym telefonie")
			return 1
		var dek: Array = o.get("usterki_deklarowane", [])
		var ukr: Array = o.get("usterki_ukryte", [])
		var rzecz: Array = o.get("usterki_rzeczywiste", [])
		if dek.size() + ukr.size() != rzecz.size():
			printerr("FAIL: deklarowane+ukryte != rzeczywiste")
			return 1
		if not dek.is_empty():
			z_deklarowanymi += 1
			if not _liczba(o.get("rabat_usterek")):
				printerr("FAIL: deklarowane bez rabat_usterek")
				return 1
	if trafione < 20:
		printerr("FAIL: za mało używanych telefonów w próbie: ", trafione)
		return 1
	print("OK losowanie telefonów używanych=", trafione, " z_deklarowanymi=", z_deklarowanymi)

	# Wykrywanie: ukryte → Oceń stan (ekspert) powinno mieć szansę ujawnić.
	var oferta := {
		"id": "t_test_1",
		"kategoria": "telefon",
		"stan": "uzywany",
		"stan_rzeczywisty": 55,
		"stan_deklarowany": 70,
		"sposob_odbioru": "osobisty",
		"cena_zl": 1000,
		"usterki_rzeczywiste": ["po_zalaniu", "slaba_bateria"],
		"usterki_deklarowane": ["slaba_bateria"],
		"usterki_ukryte": ["po_zalaniu"],
		"usterki_wykryte": [],
	}
	var swiat := {
		"bohater": {
			"inteligencja_logiczna": 90,
			"dostep_do_internetu": true,
			"dobre_wyniki_szkoly": true,
			"pieniadze": 5000,
		},
		"rynek_zakupow": {"oferty": [oferta]},
	}
	var wykryte_suma := 0
	for _j in 40:
		oferta["usterki_wykryte"] = []
		var w: Dictionary = rynek.ocen_stan(swiat, "t_test_1", true)
		if not bool(w.get("ok", false)):
			printerr("FAIL: ocen_stan: ", w)
			return 1
		var uw: Array = w.get("usterki_wykryte", []) if w.get("usterki_wykryte") is Array else []
		wykryte_suma += uw.size()
		# Reset ujawnienia stanu żeby oceniać wielokrotnie.
		oferta["stan_ujawniony"] = false
	if wykryte_suma < 1:
		printerr("FAIL: ekspert nigdy nie wykrył ukrytej usterki w 40 próbach")
		return 1
	print("OK wykrywanie ukrytych przy ocenie (trafienia=", wykryte_suma, "/40)")

	var nazwy: Array = rynek.nazwy_usterek(["zbita_szybka", "krzywe_kolo"], "telefon")
	if str(nazwy[0]) != "Zbita szybka":
		printerr("FAIL: nazwa usterki telefon=", nazwy)
		return 1
	print("OK nazwy_usterek")
	print("OK usterki dóbr używanych")
	return 0


func _liczba(v: Variant) -> bool:
	return v is int or v is float
