extends RefCounted
class_name MapaMiast

## Uproszczony graf miast: wierzchołki + krawędzie sąsiedztwa.
## Bez współrzędnych GIS — rozmieszczenie deterministyczne z seeda.
## Odległości = propozycja (layout × skala), nie mapa drogowa.

const KATALOG_MIAST := "res://świat/polska/miasta"
const SKALA_KM_NA_JEDNOSTKE := 0.42  ## propozycja_do_poprawki
const SASIEDZI_K := 3
const WIDOK_MAX := 22


func zbuduj(miasta: Array, ziarno: int, centrum_id: String = "") -> Dictionary:
	var lista: Array = _wzbogac_miasta(miasta)
	if lista.is_empty():
		return {"wierzcholki": [], "krawedzie": [], "propozycja_do_poprawki": true}
	var pozycje := _rozmiesc(lista, ziarno)
	var krawedzie := _krawedzie(lista, pozycje, ziarno)
	var widok_ids := _ids_widoku(lista, pozycje, centrum_id, krawedzie)
	var wierzcholki: Array = []
	for m in lista:
		if not (m is Dictionary):
			continue
		var id := str(m.get("id", ""))
		if not widok_ids.has(id):
			continue
		var p: Vector2 = pozycje.get(id, Vector2.ZERO)
		wierzcholki.append({
			"id": id,
			"nazwa": str(m.get("nazwa", "?")),
			"ludnosc": int(m.get("ludnosc", 0)),
			"powiat_id": str(m.get("powiat_id", "")),
			"wojewodztwo": str(m.get("wojewodztwo", "")),
			"x": p.x,
			"y": p.y,
			"propozycja_do_poprawki": true,
		})
	var kraw_widok: Array = []
	for k in krawedzie:
		if not (k is Dictionary):
			continue
		var a := str(k.get("a", ""))
		var b := str(k.get("b", ""))
		if widok_ids.has(a) and widok_ids.has(b):
			kraw_widok.append(k)
	return {
		"wierzcholki": wierzcholki,
		"krawedzie": kraw_widok,
		"centrum_id": centrum_id,
		"skala_km": SKALA_KM_NA_JEDNOSTKE,
		"propozycja_do_poprawki": true,
		"uwaga": "Odległości i pozycje z seeda — nie GIS / nie pełna mapa dróg.",
	}


func dystans_km(graf: Dictionary, id_a: String, id_b: String) -> Variant:
	if id_a == "" or id_b == "" or id_a == id_b:
		return 0.0
	var po: Dictionary = {}
	for w in graf.get("wierzcholki", []):
		if w is Dictionary:
			po[str(w.get("id", ""))] = w
	# Najpierw krawędź bezpośrednia.
	for k in graf.get("krawedzie", []):
		if not (k is Dictionary):
			continue
		var a := str(k.get("a", ""))
		var b := str(k.get("b", ""))
		if (a == id_a and b == id_b) or (a == id_b and b == id_a):
			if k.get("dystans_km") is int or k.get("dystans_km") is float:
				return float(k["dystans_km"])
	if po.has(id_a) and po.has(id_b):
		var pa: Dictionary = po[id_a]
		var pb: Dictionary = po[id_b]
		var dx := float(pa.get("x", 0)) - float(pb.get("x", 0))
		var dy := float(pa.get("y", 0)) - float(pb.get("y", 0))
		return sqrt(dx * dx + dy * dy) * float(graf.get("skala_km", SKALA_KM_NA_JEDNOSTKE))
	return null


func mieszkancy_miasta(swiat: Dictionary, miasto_id: String) -> Dictionary:
	## Bez znajomych. Rodzice, dziadkowie, przyjaciele (imiona).
	var out := {
		"rodzice": [],
		"dziadkowie": [],
		"przyjaciele": [],
		"propozycja_do_poprawki": true,
	}
	if miasto_id == "":
		return out
	var domyslne := str(swiat.get("id_miejsca_pobytu", swiat.get("id_urodzenia", "")))
	var rodzina: Variant = swiat.get("rodzina", {})
	if rodzina is Dictionary:
		for rola in ["matka", "ojciec"]:
			var os: Variant = rodzina.get(rola, {})
			if not (os is Dictionary):
				continue
			var mid := _id_miejsca_osoby(os, domyslne)
			if mid != miasto_id:
				continue
			var imie := _imie_osoby(os)
			if imie != "":
				out["rodzice"].append(imie)
		for rola in ["babcia_matki", "dziadek_matki", "babcia_ojca", "dziadek_ojca", "babcia", "dziadek"]:
			var d: Variant = rodzina.get(rola, {})
			if not (d is Dictionary):
				continue
			var mid_d := _id_miejsca_osoby(d, "")
			if mid_d == "":
				continue
			if mid_d != miasto_id:
				continue
			var imie_d := _imie_osoby(d)
			if imie_d != "":
				out["dziadkowie"].append(imie_d)
		if rodzina.get("dziadkowie") is Array:
			for d2 in rodzina["dziadkowie"]:
				if not (d2 is Dictionary):
					continue
				if _id_miejsca_osoby(d2, "") != miasto_id:
					continue
				var imie2 := _imie_osoby(d2)
				if imie2 != "":
					out["dziadkowie"].append(imie2)
	var przyjaciele: Variant = swiat.get("przyjaciele", [])
	if przyjaciele is Array:
		for p in przyjaciele:
			if not (p is Dictionary):
				continue
			if _id_miejsca_osoby(p, "") != miasto_id:
				continue
			var imie_p := _imie_osoby(p)
			if imie_p != "":
				out["przyjaciele"].append(imie_p)
	return out


func _id_miejsca_osoby(osoba: Dictionary, fallback: String) -> String:
	if osoba.get("miejsce") is Dictionary and osoba["miejsce"].get("id") != null:
		return str(osoba["miejsce"]["id"])
	for klucz in ["miasto_id", "id_miejsca", "miejsce_id"]:
		if osoba.get(klucz) != null and str(osoba[klucz]) != "":
			return str(osoba[klucz])
	return fallback


func _imie_osoby(osoba: Dictionary) -> String:
	if osoba.get("imie") is Dictionary:
		return str(osoba["imie"].get("nazwa", "")).strip_edges()
	if osoba.get("imie") != null:
		return str(osoba["imie"]).strip_edges()
	return str(osoba.get("nazwa", "")).strip_edges()


func _wzbogac_miasta(miasta: Array) -> Array:
	var out: Array = []
	for m in miasta:
		if not (m is Dictionary):
			continue
		var kopia: Dictionary = m.duplicate(true)
		var id := str(kopia.get("id", ""))
		if id != "" and FileAccess.file_exists("%s/%s.json" % [KATALOG_MIAST, id]):
			var plik := FileAccess.open("%s/%s.json" % [KATALOG_MIAST, id], FileAccess.READ)
			if plik != null:
				var dane: Variant = JSON.parse_string(plik.get_as_text())
				if dane is Dictionary:
					if not kopia.has("powiat_id"):
						kopia["powiat_id"] = str(dane.get("powiat_id", ""))
					if not kopia.has("wojewodztwo"):
						kopia["wojewodztwo"] = str(dane.get("wojewodztwo", ""))
					if not (kopia.get("ludnosc") is int or kopia.get("ludnosc") is float):
						if dane.get("liczba_mieszkancow") is int or dane.get("liczba_mieszkancow") is float:
							kopia["ludnosc"] = int(dane["liczba_mieszkancow"])
		out.append(kopia)
	return out


func _rozmiesc(miasta: Array, ziarno: int) -> Dictionary:
	## Deterministyczny układ: pierścień + jitter z hasha id (bez GIS).
	var pozycje := {}
	var n := maxi(1, miasta.size())
	for i in miasta.size():
		var m: Dictionary = miasta[i]
		var id := str(m.get("id", "%d" % i))
		var h := int(hash(id) ^ ziarno)
		var kat := TAU * float(i) / float(n) + float(h % 1000) * 0.001
		var promien := 180.0 + float(absi(h) % 220)
		var x := cos(kat) * promien + float((h >> 3) % 40) - 20.0
		var y := sin(kat) * promien + float((h >> 7) % 40) - 20.0
		pozycje[id] = Vector2(x, y)
	return pozycje


func _krawedzie(miasta: Array, pozycje: Dictionary, ziarno: int) -> Array:
	var out: Array = []
	var widziane := {}
	# 1) Ten sam powiat.
	var po_powiecie := {}
	for m in miasta:
		if not (m is Dictionary):
			continue
		var pid := str(m.get("powiat_id", ""))
		if pid == "":
			continue
		if not po_powiecie.has(pid):
			po_powiecie[pid] = []
		po_powiecie[pid].append(m)
	for pid in po_powiecie.keys():
		var grupa: Array = po_powiecie[pid]
		for i in grupa.size():
			for j in range(i + 1, grupa.size()):
				_dodaj_krawedz(out, widziane, grupa[i], grupa[j], pozycje, "powiat")
	# 2) K najbliższych sąsiadów (layout).
	for m in miasta:
		if not (m is Dictionary):
			continue
		var id := str(m.get("id", ""))
		var p: Vector2 = pozycje.get(id, Vector2.ZERO)
		var odl: Array = []
		for inne in miasta:
			if not (inne is Dictionary):
				continue
			var id2 := str(inne.get("id", ""))
			if id2 == id:
				continue
			var p2: Vector2 = pozycje.get(id2, Vector2.ZERO)
			odl.append({"m": inne, "d": p.distance_to(p2)})
		odl.sort_custom(func(a, b) -> bool: return float(a["d"]) < float(b["d"]))
		var ile := mini(SASIEDZI_K, odl.size())
		for k in ile:
			_dodaj_krawedz(out, widziane, m, odl[k]["m"], pozycje, "sasiedzi")
	# Deterministyczny porządek (ziarno tylko dokumentuje zależność).
	out.sort_custom(func(a, b) -> bool:
		var ka := "%s|%s" % [a.get("a", ""), a.get("b", "")]
		var kb := "%s|%s" % [b.get("a", ""), b.get("b", "")]
		return ka < kb
	)
	var _z := ziarno
	return out


func _dodaj_krawedz(out: Array, widziane: Dictionary, a: Dictionary, b: Dictionary, pozycje: Dictionary, rodzaj: String) -> void:
	var id_a := str(a.get("id", ""))
	var id_b := str(b.get("id", ""))
	if id_a == "" or id_b == "" or id_a == id_b:
		return
	var klucz := id_a + "|" + id_b if id_a < id_b else id_b + "|" + id_a
	if widziane.has(klucz):
		return
	widziane[klucz] = true
	var pa: Vector2 = pozycje.get(id_a, Vector2.ZERO)
	var pb: Vector2 = pozycje.get(id_b, Vector2.ZERO)
	var dyst := pa.distance_to(pb) * SKALA_KM_NA_JEDNOSTKE
	out.append({
		"a": id_a,
		"b": id_b,
		"rodzaj": rodzaj,
		"dystans_km": snappedf(dyst, 0.1),
		"propozycja_do_poprawki": true,
	})


func _ids_widoku(miasta: Array, pozycje: Dictionary, centrum_id: String, krawedzie: Array) -> Dictionary:
	var ids := {}
	var centrum := centrum_id
	if centrum == "" and not miasta.is_empty() and miasta[0] is Dictionary:
		centrum = str(miasta[0].get("id", ""))
	if centrum != "":
		ids[centrum] = true
	# Sąsiedzi grafowi centrum.
	for k in krawedzie:
		if not (k is Dictionary):
			continue
		var a := str(k.get("a", ""))
		var b := str(k.get("b", ""))
		if a == centrum:
			ids[b] = true
		elif b == centrum:
			ids[a] = true
	# Dopełnij najbliższymi z layoutu.
	if pozycje.has(centrum):
		var p0: Vector2 = pozycje[centrum]
		var odl: Array = []
		for m in miasta:
			if not (m is Dictionary):
				continue
			var id := str(m.get("id", ""))
			if ids.has(id):
				continue
			odl.append({"id": id, "d": p0.distance_to(pozycje.get(id, Vector2.ZERO))})
		odl.sort_custom(func(a, b) -> bool: return float(a["d"]) < float(b["d"]))
		for wpis in odl:
			if ids.size() >= WIDOK_MAX:
				break
			ids[str(wpis["id"])] = true
	else:
		for m in miasta:
			if ids.size() >= WIDOK_MAX:
				break
			if m is Dictionary:
				ids[str(m.get("id", ""))] = true
	return ids
