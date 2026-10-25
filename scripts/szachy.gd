extends RefCounted
class_name Szachy

const PLIK := "res://postacie/szachy.json"

var dane: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var s: Variant = _czytaj(PLIK)
	if s is Dictionary:
		dane = s


func ranking(bohater: Dictionary) -> int:
	return int(bohater.get("szachy_ranking", 0))


func zapewnij_ranking(bohater: Dictionary, rng: RandomNumberGenerator = null) -> int:
	wczytaj()
	if ranking(bohater) > 0:
		return ranking(bohater)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var s: Dictionary = dane.get("ranking_start", {}) if dane.get("ranking_start") is Dictionary else {}
	var r := rng.randi_range(int(s.get("min", 800)), int(s.get("max", 1100)))
	bohater["szachy_ranking"] = r
	return r


func trening(bohater: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "propozycja_do_poprawki": true}
	zapewnij_ranking(bohater, rng)
	var t: Dictionary = dane.get("trening", {}) if dane.get("trening") is Dictionary else {}
	var koszt := _zakres(t.get("koszt_zl", [0, 20]), rng)
	var pien := int(bohater.get("pieniadze", 0))
	if pien < koszt:
		out["tekst"] = "Brak %d zł na trening." % koszt
		return out
	bohater["pieniadze"] = pien - koszt
	var d := _zakres(t.get("delta_ranking", [2, 8]), rng)
	bohater["szachy_ranking"] = ranking(bohater) + d
	var p := int(bohater.get("psychika", 50)) + int(t.get("psychika", 0))
	bohater["psychika"] = clampi(p, -50, 100)
	out["ok"] = true
	out["tekst"] = "Trening szachów: ranking %d (+%d), −%d zł." % [ranking(bohater), d, koszt]
	return out


func turnieje(wiek: int) -> Array:
	wczytaj()
	var out: Array = []
	if not (dane.get("turnieje") is Array):
		return out
	for t in dane["turnieje"]:
		if t is Dictionary and int(t.get("wiek_min", 0)) <= wiek:
			out.append(t)
	return out


func graj_turniej(bohater: Dictionary, turniej_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	wczytaj()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var out := {"ok": false, "tekst": "", "wygrana": false, "nagroda": 0, "propozycja_do_poprawki": true}
	zapewnij_ranking(bohater, rng)
	var t: Dictionary = {}
	for x in turnieje(99):
		if str(x.get("id", "")) == turniej_id:
			t = x
			break
	if t.is_empty():
		out["tekst"] = "Brak turnieju."
		return out
	var wiek := int(bohater.get("wiek", 0))
	if wiek < int(t.get("wiek_min", 0)):
		out["tekst"] = "Za młody na ten turniej."
		return out
	var wpis := int(t.get("wpisowe_zl", 0))
	var pien := int(bohater.get("pieniadze", 0))
	if pien < wpis:
		out["tekst"] = "Brak wpisowego (%d zł)." % wpis
		return out
	bohater["pieniadze"] = pien - wpis
	# Prosta szansa: wyższa przy wyższym rankingu vs „średni przeciwnik”.
	var przec := 1200
	if dane.get("przeciwnicy_przyklad") is Array and not (dane["przeciwnicy_przyklad"] as Array).is_empty():
		var pr: Variant = (dane["przeciwnicy_przyklad"] as Array)[rng.randi_range(0, (dane["przeciwnicy_przyklad"] as Array).size() - 1)]
		if pr is Dictionary:
			przec = int(pr.get("ranking", przec))
	var moj := float(ranking(bohater))
	var szansa := clampf(0.5 + (moj - float(przec)) / 800.0, 0.15, 0.85)
	var wygrana := rng.randf() < szansa
	out["wygrana"] = wygrana
	if wygrana:
		var d := _zakres(t.get("delta_wygrana", [10, 25]), rng)
		bohater["szachy_ranking"] = ranking(bohater) + d
		var nagrody: Variant = t.get("nagrody_zl", [0, 0, 0])
		var nagroda := 0
		if nagrody is Array and nagrody.size() >= 1:
			nagroda = int(nagrody[mini(2, nagrody.size() - 1)])
			if nagrody.size() >= 3:
				nagroda = int(nagrody[rng.randi_range(0, 2)])
		bohater["pieniadze"] = int(bohater["pieniadze"]) + nagroda
		out["nagroda"] = nagroda
		out["tekst"] = "Turniej %s: wygrana! Ranking %d (+%d), nagroda %d zł." % [
			str(t.get("nazwa", turniej_id)), ranking(bohater), d, nagroda
		]
	else:
		var d2 := _zakres(t.get("delta_przegrana", [-15, -5]), rng)
		bohater["szachy_ranking"] = maxi(100, ranking(bohater) + d2)
		out["tekst"] = "Turniej %s: przegrana. Ranking %d (%+d)." % [
			str(t.get("nazwa", turniej_id)), ranking(bohater), d2
		]
	out["ok"] = true
	return out


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
