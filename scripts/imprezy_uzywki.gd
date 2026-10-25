extends RefCounted
class_name ImprezyUzywki

## Stub imprez / picia — konsekwencje.

const PLIK := "res://postacie/imprezy_uzywki.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func lista_imprez(wiek: int) -> Array:
	wczytaj()
	var out: Array = []
	var min_i := int(dane.get("wiek_min_impreza", 14))
	if wiek < min_i:
		return out
	if not (dane.get("imprezy") is Array):
		return out
	for p in dane["imprezy"]:
		if not (p is Dictionary):
			continue
		if int(p.get("wiek_min", min_i)) <= wiek:
			out.append(p)
	return out


func idz_na_impreze(bohater: Dictionary, swiat: Dictionary, impreza_id: String, z_piciem: bool, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "koszt": 0, "kac": false, "propozycja_do_poprawki": true}
	var impreza: Dictionary = {}
	for p in lista_imprez(99):
		if str(p.get("id", "")) == impreza_id:
			impreza = p
			break
	if impreza.is_empty():
		out["tekst"] = "Brak imprezy."
		return out
	var wiek := int(bohater.get("wiek", 0))
	if wiek < int(impreza.get("wiek_min", dane.get("wiek_min_impreza", 14))):
		out["tekst"] = "Za młody na tę imprezę."
		return out
	var koszt_zakres: Variant = impreza.get("koszt_zl", [20, 40])
	var koszt := _zakres(koszt_zakres, rng)
	var pieniadze := int(bohater.get("pieniadze", swiat.get("pieniadze", 0)))
	if pieniadze < koszt:
		out["tekst"] = "Za mało kasy (%d zł)." % koszt
		return out
	bohater["pieniadze"] = pieniadze - koszt
	var psych_zakres: Variant = impreza.get("psychika", [2, 6])
	var d_psych := _zakres(psych_zakres, rng)
	_zmien_psychike(bohater, d_psych)
	var rel := int(bohater.get("relacja_przyjaciel_stub", 50)) + int(impreza.get("relacja_przyjaciel", 0))
	bohater["relacja_przyjaciel_stub"] = clampi(rel, 0, 100)
	var linie: PackedStringArray = ["Impreza: %s (−%d zł, psychika %+d)." % [str(impreza.get("nazwa", impreza_id)), koszt, d_psych]]
	if rng.randf() < float(impreza.get("ryzyko_rodzice", 0.1)):
		var psych := int(bohater.get("psychika", 50))
		bohater["psychika"] = psych - 4
		linie.append("Rodzice wkurzeni (−4 psychika).")
	if z_piciem:
		var min_a := int(dane.get("wiek_min_alkohol", 18))
		var picie: Dictionary = dane.get("picie", {}) if dane.get("picie") is Dictionary else {}
		var efekty: Dictionary = picie.get("efekty", {}) if picie.get("efekty") is Dictionary else {}
		if wiek < min_a:
			linie.append("Picie poniżej 18 — ryzyko (stub).")
			if rng.randf() < float(efekty.get("rodzice_konflikt_szansa", 0.4)):
				_zmien_psychike(bohater, -6)
				linie.append("Wpadka z rodzicami (−6).")
		_zmien_psychike(bohater, _zakres(efekty.get("kac_psychika", [-6, -2]), rng))
		var zm := int(bohater.get("zmeczenie_fizyczne", 0))
		bohater["zmeczenie_fizyczne"] = clampi(zm + _zakres(efekty.get("kac_zmeczenie", [10, 25]), rng), 0, 100)
		out["kac"] = true
		bohater["kac_stub"] = true
		linie.append("Kac (stub).")
		if rng.randf() < float(efekty.get("szkola_kara_szansa", 0.25)):
			var w := int(bohater.get("wiedza_pkt", 0))
			bohater["wiedza_pkt"] = w - 2
			linie.append("Kłopoty w szkole (−2 wiedza).")
	out["ok"] = true
	out["koszt"] = koszt
	out["tekst"] = " ".join(linie)
	return out


func _zmien_psychike(bohater: Dictionary, delta: int) -> void:
	var psych := 50
	if bohater.get("psychika") is int or bohater.get("psychika") is float:
		psych = int(bohater["psychika"])
	bohater["psychika"] = clampi(psych + delta, -50, 100)


func _zakres(v: Variant, rng: RandomNumberGenerator) -> int:
	if v is Array and v.size() >= 2:
		return rng.randi_range(int(v[0]), int(v[1]))
	if v is int or v is float:
		return int(v)
	return 0


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
