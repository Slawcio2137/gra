extends RefCounted

## Pasek wypłaty. Stawki tylko z świat/podatki_praca.json. Null nie odejmuje zgadywanej kwoty.

const PLIK := "res://świat/podatki_praca.json"

var _dane: Dictionary = {}
var _wczytane := false


func pasek(brutto_miesiac: int, bohater: Dictionary, kraj: String, stan: Dictionary, rok: int) -> Dictionary:
	return pasek_regul(brutto_miesiac, bohater, _regulamin(kraj), stan, rok)


func pasek_regul(brutto_miesiac: int, bohater: Dictionary, regul, stan: Dictionary, rok: int) -> Dictionary:
	var kal := _kalendarz()
	var brutto := _tydzien_z_miesiaca(brutto_miesiac, kal)
	var linie: PackedStringArray = []
	linie.append("Brutto: %s zł" % _odstepy(brutto))
	if not (regul is Dictionary):
		linie.append("Odtrącenia nie są ustawione.")
		linie.append("Netto: %s zł" % _odstepy(brutto))
		return _pakiet(brutto, brutto, 0, 0, linie, false)
	_rok_stanu(stan, rok)
	var skladki := _skladki(brutto, bohater, regul, linie)
	var pit := _pit(brutto, int(skladki.get("spoleczne", 0)), bohater, regul, stan, linie, bool(skladki.get("bez_skladek", false)))
	var netto := brutto
	if not bool(skladki.get("pomin", false)):
		netto -= int(skladki.get("kwota", 0))
	if not bool(pit.get("pomin", false)):
		netto -= int(pit.get("kwota", 0))
	if netto < 0:
		netto = 0
	linie.append("Netto: %s zł" % _odstepy(netto))
	stan["przychod_roku_zl"] = int(stan.get("przychod_roku_zl", 0)) + brutto
	return _pakiet(brutto, netto, int(skladki.get("kwota", 0)), int(pit.get("kwota", 0)), linie, true)


func czy_sie_uczy(bohater: Dictionary) -> bool:
	if bool(bohater.get("uczy_sie", false)) or bool(bohater.get("studiuje", false)):
		return true
	var edukacja: Variant = bohater.get("edukacja", [])
	if edukacja is Array:
		for e in edukacja:
			if e is Dictionary and (bool(e.get("trwa", false)) or bool(e.get("aktualna", false)) or bool(e.get("uczy_sie", false))):
				return true
	return false


func _pakiet(brutto: int, netto: int, skladki: int, pit: int, linie: PackedStringArray, ustawione: bool) -> Dictionary:
	return {
		"brutto_zl": brutto,
		"netto_zl": netto,
		"skladki_zl": skladki,
		"pit_zl": pit,
		"linie": linie,
		"tekst": "\n".join(linie),
		"ustawione": ustawione,
		"propozycja_do_poprawki": true,
	}


func _kalendarz() -> Dictionary:
	_wczytaj()
	var blok: Variant = _dane.get("kalendarz", {})
	return blok if blok is Dictionary else {}


func _tydzien_z_miesiaca(brutto_miesiac: int, kal: Dictionary) -> int:
	var dni_t := float(kal.get("dni_tygodnia", 7))
	var dni_m := float(kal.get("dni_miesiaca", 30))
	if dni_m <= 0.0:
		dni_m = 30.0
	return int(round(float(brutto_miesiac) * dni_t / dni_m))


func _rok_stanu(stan: Dictionary, rok: int) -> void:
	if int(stan.get("rok", -99999)) != rok:
		stan["rok"] = rok
		stan["przychod_roku_zl"] = 0
		stan["podstawa_roku_zl"] = 0


func _mlody(bohater: Dictionary, prog: int) -> bool:
	if not (bohater.get("wiek") is int or bohater.get("wiek") is float):
		return false
	return int(bohater.get("wiek")) < prog


func _skladki(brutto: int, bohater: Dictionary, regul: Dictionary, linie: PackedStringArray) -> Dictionary:
	var nauka: Variant = regul.get("ponizej_26_i_nauka_bez_skladek", {})
	var prog := 26
	if nauka is Dictionary and nauka.get("wiek_ponizej") is int or (nauka is Dictionary and nauka.get("wiek_ponizej") is float):
		prog = int(nauka.get("wiek_ponizej"))
	if _mlody(bohater, prog) and czy_sie_uczy(bohater):
		linie.append("Składki: 0 zł")
		return {"kwota": 0, "spoleczne": 0, "bez_skladek": true, "pomin": false}
	var lista: Array = regul.get("skladki_pracownika", []) if regul.get("skladki_pracownika") is Array else []
	if lista.is_empty():
		linie.append("Odtrącenia nie są ustawione.")
		return {"kwota": 0, "spoleczne": 0, "bez_skladek": false, "pomin": true}
	var spoleczne := 0
	var kwota := 0
	var brak_spolecznych := false
	for w in lista:
		if not (w is Dictionary):
			continue
		var nazwa := str(w.get("nazwa", "Składka"))
		if not (w.get("udzial") is int or w.get("udzial") is float):
			linie.append("%s: odtrącenie nie jest ustawione" % nazwa)
			if str(w.get("podstawa", "brutto")) != "po_spolecznych":
				brak_spolecznych = true
			continue
		if str(w.get("podstawa", "brutto")) == "po_spolecznych" and brak_spolecznych:
			linie.append("%s: odtrącenie nie jest ustawione" % nazwa)
			continue
		var baza := brutto
		if str(w.get("podstawa", "brutto")) == "po_spolecznych":
			baza = brutto - spoleczne
		var zl := int(round(float(baza) * float(w.get("udzial"))))
		if zl < 0:
			zl = 0
		linie.append("%s: %s zł" % [nazwa, _odstepy(zl)])
		kwota += zl
		if str(w.get("podstawa", "brutto")) != "po_spolecznych":
			spoleczne += zl
	return {"kwota": kwota, "spoleczne": spoleczne, "bez_skladek": false, "pomin": false}


func _pit(brutto: int, spoleczne: int, bohater: Dictionary, regul: Dictionary, stan: Dictionary, linie: PackedStringArray, bez_skladek: bool) -> Dictionary:
	if bez_skladek:
		linie.append("Podatek dochodowy: 0 zł")
		return {"kwota": 0, "pomin": false}
	var pit: Variant = regul.get("pit", null)
	if not (pit is Dictionary):
		linie.append("Podatek dochodowy: odtrącenie nie jest ustawione")
		return {"kwota": 0, "pomin": true}
	var ulga: Dictionary = pit.get("ulga_mlodych", {}) if pit.get("ulga_mlodych") is Dictionary else {}
	var prog := int(ulga.get("wiek_ponizej", 26))
	var limit := int(ulga.get("limit_przychodu_rok_zl", 0)) if ulga.get("limit_przychodu_rok_zl") is int or ulga.get("limit_przychodu_rok_zl") is float else 0
	var juz := int(stan.get("przychod_roku_zl", 0))
	var opodatkowane := brutto
	if _mlody(bohater, prog):
		var wolne := maxi(0, limit - juz) if limit > 0 else brutto
		opodatkowane = maxi(0, brutto - wolne)
	if opodatkowane <= 0 or brutto <= 0:
		linie.append("Podatek dochodowy: 0 zł")
		return {"kwota": 0, "pomin": false}
	var podstawa := float(opodatkowane) * float(brutto - spoleczne) / float(brutto)
	if podstawa < 0.0:
		podstawa = 0.0
	var skala: Array = pit.get("skala", []) if pit.get("skala") is Array else []
	if skala.is_empty() or not (skala[0] is Dictionary) or not (skala[0].get("stawka") is int or skala[0].get("stawka") is float):
		linie.append("Podatek dochodowy: odtrącenie nie jest ustawione")
		return {"kwota": 0, "pomin": true}
	var pierwszy: Dictionary = skala[0]
	var stawka := float(pierwszy.get("stawka"))
	var drugi_stawka := stawka
	var prog_podstawy := 120000
	if skala.size() > 1 and skala[1] is Dictionary and (skala[1].get("stawka") is int or skala[1].get("stawka") is float):
		drugi_stawka = float(skala[1].get("stawka"))
		if skala[1].get("nadwyzka_ponad_zl") is int or skala[1].get("nadwyzka_ponad_zl") is float:
			prog_podstawy = int(skala[1].get("nadwyzka_ponad_zl"))
	var ytd := float(stan.get("podstawa_roku_zl", 0))
	var w_pierwszym := podstawa
	var w_drugim := 0.0
	var miejsce := maxf(0.0, float(prog_podstawy) - ytd)
	if podstawa > miejsce:
		w_pierwszym = miejsce
		w_drugim = podstawa - miejsce
	var kredyt := 0.0
	if pierwszy.get("kwota_zmniejszajaca_rok_zl") is int or pierwszy.get("kwota_zmniejszajaca_rok_zl") is float:
		var tygodni := float(_kalendarz().get("tygodnie_w_roku_gry", 52))
		if tygodni <= 0.0:
			tygodni = 52.0
		kredyt = float(pierwszy.get("kwota_zmniejszajaca_rok_zl")) / tygodni
		if brutto > 0:
			kredyt *= float(opodatkowane) / float(brutto)
	var podatek := w_pierwszym * stawka - kredyt + w_drugim * drugi_stawka
	var zl := int(round(podatek))
	if zl < 0:
		zl = 0
	stan["podstawa_roku_zl"] = ytd + podstawa
	linie.append("Podatek dochodowy: %s zł" % _odstepy(zl))
	return {"kwota": zl, "pomin": false}


func _regulamin(kraj: String) -> Variant:
	_wczytaj()
	var kraje: Variant = _dane.get("kraje", {})
	if not (kraje is Dictionary) or not kraje.has(kraj):
		return null
	return kraje[kraj]


func _wczytaj() -> void:
	if _wczytane:
		return
	if not FileAccess.file_exists(PLIK):
		_wczytane = true
		_dane = {}
		return
	var plik := FileAccess.open(PLIK, FileAccess.READ)
	if plik == null:
		return
	_wczytane = true
	var dane: Variant = JSON.parse_string(plik.get_as_text())
	if dane is Dictionary:
		_dane = dane


func _odstepy(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var licznik := 0
	for i in range(s.length() - 1, -1, -1):
		if licznik > 0 and licznik % 3 == 0:
			out = " " + out
		out = s[i] + out
		licznik += 1
	if n < 0:
		out = "-" + out
	return out
