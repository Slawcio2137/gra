extends RefCounted
class_name KonserwacjaAuta

## Stub: olej / filtry / opony + zima / zatarcie. Efekty w turze.

const PLIK := "res://pojazdy/konserwacja_aut.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func stan_startowy() -> Dictionary:
	wczytaj()
	var s: Dictionary = {}
	if dane.get("start_stanu") is Dictionary:
		s = (dane["start_stanu"] as Dictionary).duplicate(true)
	else:
		s = {"olej": 80, "filtry": 75, "opony": 70, "konserwacja_zima": false}
	s["ostrzezenie_olej"] = false
	s["zatarcie"] = false
	s["rdza"] = false
	return s


func efekt_tury(stan: Dictionary, zima: bool = false, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"teksty": [], "olej_ostrzezenie": false, "zatarcie": false, "rdza": false}
	var progi: Dictionary = dane.get("progi", {}) if dane.get("progi") is Dictionary else {}
	var efekty: Dictionary = dane.get("efekty", {}) if dane.get("efekty") is Dictionary else {}
	# Zużycie punktów idzie z kilometrów (zuzyj_kilometry), nie z samego tygodnia.
	var ostrz := int(progi.get("olej_ostrzezenie", 25))
	var kryt := int(progi.get("olej_krytyczny", 8))
	if int(stan["olej"]) <= ostrz:
		out["olej_ostrzezenie"] = true
		out["teksty"].append("Ostrzeżenie: niski poziom oleju (%d)." % int(stan["olej"]))
	if int(stan["olej"]) <= kryt:
		var sz := float(efekty.get("brak_oleju_szansa_zatarcia", 0.08))
		if rng.randf() < sz:
			out["zatarcie"] = true
			stan["zatarcie"] = true
			out["teksty"].append("Silnik zatarł się — brak oleju.")
	if zima:
		var konserw := bool(stan.get("konserwacja_zima", false))
		var sz_r := float(efekty.get("zima_z_konserwacja_szansa_rdzy" if konserw else "zima_bez_konserwacji_szansa_rdzy", 0.05))
		if rng.randf() < sz_r:
			out["rdza"] = true
			stan["rdza"] = true
			out["teksty"].append("Pojawiła się rdza (zima%s)." % (" — mimo konserwacji" if konserw else ""))
	return out


func _blok_zuzycia() -> Dictionary:
	wczytaj()
	if dane.get("zuzycie_od_km") is Dictionary:
		return dane["zuzycie_od_km"]
	return {}


func zuzyj_kilometry(stan: Dictionary, km: float, jedzie: bool) -> void:
	wczytaj()
	var blok := _blok_zuzycia()
	var udzial := 1.0 if jedzie else float(blok.get("postoj_udzial", 0.2))
	var tys := maxf(0.0, km) / 1000.0 * udzial
	stan["olej"] = maxi(0, int(round(float(stan.get("olej", 80)) - tys * float(blok.get("olej_na_1000_km", 14)))))
	stan["filtry"] = maxi(0, int(round(float(stan.get("filtry", 75)) - tys * float(blok.get("filtry_na_1000_km", 8)))))
	stan["opony"] = maxi(0, int(round(float(stan.get("opony", 70)) - tys * float(blok.get("opony_na_1000_km", 6)))))


func ustaw_konserwacje_zimowa(stan: Dictionary, wlacz: bool) -> void:
	stan["konserwacja_zima"] = wlacz


func napraw(stan: Dictionary, sposob: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var naprawy: Dictionary = dane.get("naprawy", {}) if dane.get("naprawy") is Dictionary else {}
	var conf: Dictionary = naprawy.get(sposob, naprawy.get("samodzielnie", {})) if naprawy.get(sposob) is Dictionary or naprawy.get("samodzielnie") is Dictionary else {}
	if not (conf is Dictionary):
		conf = {"szansa_sukcesu": 0.5, "koszt_mnoznik": 0.5, "ryzyko_pogorszenia": 0.1}
	var out := {"ok": false, "tekst": "", "koszt_mnoznik": float(conf.get("koszt_mnoznik", 1.0))}
	if rng.randf() < float(conf.get("szansa_sukcesu", 0.5)):
		stan["olej"] = mini(100, int(stan.get("olej", 0)) + 40)
		stan["filtry"] = mini(100, int(stan.get("filtry", 0)) + 35)
		out["ok"] = true
		out["tekst"] = "Naprawa (%s) udała się." % sposob
	elif rng.randf() < float(conf.get("ryzyko_pogorszenia", 0.1)):
		stan["olej"] = maxi(0, int(stan.get("olej", 0)) - 10)
		out["tekst"] = "Naprawa (%s) pogorszyła sprawę." % sposob
	else:
		out["tekst"] = "Naprawa (%s) nie pomogła." % sposob
	return out


## Serwis konkretnej części: olej / filtry / opony / rdza / zatarcie.
func serwis(stan: Dictionary, czesc: String, sposob: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "koszt_zl": 0, "propozycja_do_poprawki": true}
	var baza := {"olej": 120, "filtry": 90, "opony": 800, "rdza": 1500, "zatarcie": 4500}
	if dane.get("cennik_czesci_zl") is Dictionary:
		baza = dane["cennik_czesci_zl"]
	var koszt_bazy := int(baza.get(czesc, 100))
	var naprawy: Dictionary = dane.get("naprawy", {}) if dane.get("naprawy") is Dictionary else {}
	var conf: Dictionary = naprawy.get(sposob, {}) if naprawy.get(sposob) is Dictionary else {"szansa_sukcesu": 0.5, "koszt_mnoznik": 1.0}
	var mnoz := float(conf.get("koszt_mnoznik", 1.0))
	var koszt := int(round(float(koszt_bazy) * mnoz))
	out["koszt_zl"] = koszt
	# Warsztat: zawsze udany (płacisz za pewność). Reszta wg szansy.
	var szansa := 1.0 if sposob == "warsztat" else float(conf.get("szansa_sukcesu", 0.5))
	if rng.randf() > szansa:
		out["tekst"] = "Serwis %s (%s) nie wyszedł." % [czesc, sposob]
		return out
	match czesc:
		"olej":
			stan["olej"] = 100
			stan["ostrzezenie_olej"] = false
		"filtry":
			stan["filtry"] = 100
		"opony":
			stan["opony"] = 100
		"rdza":
			stan["rdza"] = false
		"zatarcie":
			stan["zatarcie"] = false
			stan["olej"] = mini(100, int(stan.get("olej", 0)) + 50)
		_:
			out["tekst"] = "Nieznana część."
			return out
	out["ok"] = true
	out["tekst"] = "Serwis %s przez %s OK (−%d zł stub)." % [czesc, sposob, koszt]
	return out


## Najpierw kopia, potem kasa. Za mało pieniędzy albo nieudany rzut nie ruszają stanu.
func sprobuj_serwis(stan: Dictionary, czesc: String, sposob: String, kasa: int, rng: RandomNumberGenerator = null) -> Dictionary:
	var kopia := stan.duplicate(true)
	var w: Dictionary = serwis(kopia, czesc, sposob, rng)
	w["zmieniono"] = false
	if not bool(w.get("ok", false)):
		return w
	if kasa < int(w.get("koszt_zl", 0)):
		return {
			"ok": false,
			"zmieniono": false,
			"koszt_zl": int(w.get("koszt_zl", 0)),
			"tekst": "Brak kasy na serwis.",
			"powod": "brak_kasy",
		}
	for klucz in kopia.keys():
		stan[klucz] = kopia[klucz]
	w["zmieniono"] = true
	return w


func tekst_stanu_gracza(stan: Dictionary) -> String:
	return "Olej %d · Filtry %d · Opony %d%s" % [
		int(stan.get("olej", 0)),
		int(stan.get("filtry", 0)),
		int(stan.get("opony", 0)),
		" · ZIMA OK" if bool(stan.get("konserwacja_zima", false)) else "",
	]


func tekst_stanu(stan: Dictionary) -> String:
	return "Olej %d · Filtry %d · Opony %d%s%s%s" % [
		int(stan.get("olej", 0)),
		int(stan.get("filtry", 0)),
		int(stan.get("opony", 0)),
		" · ZIMA OK" if bool(stan.get("konserwacja_zima", false)) else "",
		" · RDZA" if bool(stan.get("rdza", false)) else "",
		" · ZATARCIE" if bool(stan.get("zatarcie", false)) else "",
	]


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
