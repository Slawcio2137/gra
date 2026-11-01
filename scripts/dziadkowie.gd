extends RefCounted
class_name Dziadkowie

## Losowanie dziadków + kieszonkowe + dialog (framework).

const PLIK_ZESTAWOW := "res://postacie/rodzina/dziadkowie.json"
const PLIK_KIESZ := "res://postacie/kieszonkowe_dziadkowie.json"
const PLIK_DIALOG := "res://postacie/dialogi_dziadkowie.json"
const _Ziarno = preload("res://scripts/ziarno_rodzicow.gd")
const ZaokraglenieZarobkow = preload("res://scripts/zaokraglenie_zarobkow.gd")

var _zestawy: Dictionary = {}
var _kiesz: Dictionary = {}
var _dialog: Dictionary = {}
var _wczytane := false


func wczytaj() -> void:
	if _wczytane:
		return
	_wczytane = true
	var z: Variant = _czytaj(PLIK_ZESTAWOW)
	if z is Dictionary:
		_zestawy = z
	var k: Variant = _czytaj(PLIK_KIESZ)
	if k is Dictionary:
		_kiesz = k
	var d: Variant = _czytaj(PLIK_DIALOG)
	if d is Dictionary:
		_dialog = d


func losuj(ziarno_rodzicow: Dictionary, los, miejsce: Variant = null) -> Dictionary:
	wczytaj()
	var kraj := ""
	if ziarno_rodzicow.get("kraj_rodziny") != null:
		kraj = str(ziarno_rodzicow["kraj_rodziny"])
	var zestaw := _losuj_zestaw(los)
	var out := {
		"zestaw_id": str(zestaw.get("id", "")),
		"lista": [],
		"kieszonkowe_aktywne": false,
		"kieszonkowe_kwota_zl": null,
		"podejrzliwosc": 0,
		"przerwa_do_tygodnia": -1,
		"propozycja_do_poprawki": true,
	}
	var ziarno_helper = _Ziarno.new()
	var role := [
		["babcia_matki", "kobiety", "zenskie", true],
		["dziadek_matki", "mezczyzni", "meskie", true],
		["babcia_ojca", "kobiety", "zenskie", false],
		["dziadek_ojca", "mezczyzni", "meskie", false],
	]
	for r in role:
		var rola: String = r[0]
		if not bool(zestaw.get(rola, false)):
			continue
		var osoba := _losuj_osobe(ziarno_helper, los, kraj, rola, str(r[1]), str(r[2]))
		osoba["linia_matki"] = bool(r[3])
		osoba["miejsce"] = _losuj_lokalizacje(los, miejsce)
		# Uproszczone zarobki: emerytura ≈ mnożnik względem rodzica linii.
		var rodzic_ref: Variant = ziarno_rodzicow.get("matka" if bool(r[3]) else "ojciec", {})
		osoba["zarobki"] = _zarobki_uproszczone(rodzic_ref, los)
		out["lista"].append(osoba)
	return out


func odpowiedzi_dialogu(inteligencja: int, podejrzliwosc: int, ile: int = 5) -> Array:
	wczytaj()
	var pula: Array = []
	if _dialog.get("odpowiedzi") is Array:
		for o in _dialog["odpowiedzi"]:
			if not (o is Dictionary):
				continue
			if int(o.get("wymaga_inteligencji", 0)) > inteligencja:
				continue
			if int(o.get("min_podejrzliwosc", 0)) > podejrzliwosc:
				continue
			pula.append(o)
	pula.shuffle()
	var pok: Dictionary = {}
	if _dialog.get("pokazuj_odpowiedzi") is Dictionary:
		pok = _dialog["pokazuj_odpowiedzi"]
	var mn := int(pok.get("min", 4))
	var mx := int(pok.get("max", 5))
	ile = clampi(ile, mn, mx)
	var out: Array = []
	for i in mini(ile, pula.size()):
		out.append(pula[i])
	return out


func snap_kwoty(surowa: int) -> int:
	wczytaj()
	var lista: Array = []
	if _kiesz.get("dozwolone_kwoty") is Dictionary and _kiesz["dozwolone_kwoty"].get("lista_wzorcowa") is Array:
		lista = _kiesz["dozwolone_kwoty"]["lista_wzorcowa"]
	if lista.is_empty():
		return ZaokraglenieZarobkow.zaokraglij(surowa)
	var best := int(lista[0])
	var best_d := absi(surowa - best)
	for v in lista:
		if not (v is int or v is float):
			continue
		var n := int(v)
		var d := absi(surowa - n)
		if d < best_d:
			best = n
			best_d = d
	var limit := 150
	if _kiesz.get("dozwolone_kwoty") is Dictionary and (_kiesz["dozwolone_kwoty"].get("limit_max_zl") is int or _kiesz["dozwolone_kwoty"].get("limit_max_zl") is float):
		limit = int(_kiesz["dozwolone_kwoty"]["limit_max_zl"])
	return ZaokraglenieZarobkow.zaokraglij(mini(best, limit))


func kwota_bazowa_z_rodziny(ziarno: Dictionary) -> int:
	wczytaj()
	var baza := 10
	if _kiesz.get("kwoty_propozycja") is Dictionary:
		baza = int(_kiesz["kwoty_propozycja"].get("gdy_brak_przedzialu_zl", 10))
	# Uproszczenie: od gospodarstwa rodziców — niższy schodek.
	var zar: Variant = ziarno.get("zarobki", {})
	if zar is Dictionary and (zar.get("od_zl") is int or zar.get("od_zl") is float):
		var srodek := float(zar["od_zl"])
		if zar.get("do_zl") is int or zar.get("do_zl") is float:
			srodek = (srodek + float(zar["do_zl"])) * 0.5
		if srodek < 9000.0:
			baza = 5
		elif srodek < 14000.0:
			baza = 10
		elif srodek < 20000.0:
			baza = 15
		elif srodek < 30000.0:
			baza = 25
		else:
			baza = 40
	return snap_kwoty(baza)


func popros_o_kieszonkowe(stan_dziadkow: Dictionary, ziarno: Dictionary, inteligencja: int, tydzien: int, klamstwo: bool = false) -> Dictionary:
	wczytaj()
	var out := {
		"ok": false,
		"kwota": 0,
		"tekst": "",
		"odpowiedzi": [],
		"wykryto_klamstwo": false,
		"telefon_do_rodzicow": false,
		"propozycja_do_poprawki": true,
	}
	var przerwa := int(stan_dziadkow.get("przerwa_do_tygodnia", -1))
	if przerwa >= 0 and tydzien <= przerwa:
		out["tekst"] = "Dziadkowie jeszcze nie dają — przerwa do tygodnia %d." % przerwa
		return out
	var podej := int(stan_dziadkow.get("podejrzliwosc", 0))
	podej = clampi(podej + int((_dialog.get("podejrzliwosc", {}) as Dictionary).get("za_prosbe", 8)), 0, 100)
	stan_dziadkow["podejrzliwosc"] = podej
	out["odpowiedzi"] = odpowiedzi_dialogu(inteligencja, podej)
	if klamstwo:
		var kl: Dictionary = _dialog.get("klamstwo", {}) if _dialog.get("klamstwo") is Dictionary else {}
		var sz := float(kl.get("szansa_wykrycia_baza", 0.25)) + float(podej) * float(kl.get("za_podejrzliwosc", 0.004))
		if randf() < clampf(sz, 0.05, 0.95):
			out["wykryto_klamstwo"] = true
			var od := int(kl.get("przerwa_tygodnie_od", 12))
			var dok := int(kl.get("przerwa_tygodnie_do", 40))
			var ile := randi_range(od, dok)
			stan_dziadkow["przerwa_do_tygodnia"] = tydzien + ile
			out["tekst"] = "Wykryto kłamstwo. Przerwa w dawaniu: %d tygodni." % ile
			return out
	var tel: Dictionary = _dialog.get("telefon_do_rodzicow", {}) if _dialog.get("telefon_do_rodzicow") is Dictionary else {}
	var sz_t := float(tel.get("szansa_baza", 0.12)) + float(podej) * float(tel.get("za_podejrzliwosc", 0.003))
	if randf() < clampf(sz_t, 0.0, 0.6):
		out["telefon_do_rodzicow"] = true
	var kwota := kwota_bazowa_z_rodziny(ziarno)
	stan_dziadkow["kieszonkowe_aktywne"] = true
	stan_dziadkow["kieszonkowe_kwota_zl"] = kwota
	out["ok"] = true
	out["kwota"] = kwota
	var ev: Dictionary = _kiesz.get("event_tygodniowy", {}) if _kiesz.get("event_tygodniowy") is Dictionary else {}
	out["tekst"] = str(ev.get("tekst_ok", "Dziadkowie dają kieszonkowe: +%d zł.")) % kwota
	if out["telefon_do_rodzicow"]:
		out["tekst"] += " Dziadkowie dzwonią do rodziców sprawdzić sprawę."
	return out


func wyplata_tygodniowa(stan_dziadkow: Dictionary, tydzien: int) -> Dictionary:
	wczytaj()
	var out := {"ok": false, "kwota": 0, "tekst": ""}
	if not bool(stan_dziadkow.get("kieszonkowe_aktywne", false)):
		return out
	var przerwa := int(stan_dziadkow.get("przerwa_do_tygodnia", -1))
	if przerwa >= 0 and tydzien <= przerwa:
		return out
	if int(stan_dziadkow.get("ostatnia_wyplata_tydzien", -1)) == tydzien:
		return out
	var kwota := int(stan_dziadkow.get("kieszonkowe_kwota_zl", 0))
	if kwota <= 0:
		return out
	# Spadek podejrzliwości bez prośby.
	var pod: Dictionary = _dialog.get("podejrzliwosc", {}) if _dialog.get("podejrzliwosc") is Dictionary else {}
	var p := int(stan_dziadkow.get("podejrzliwosc", 0))
	p = maxi(0, p - int(pod.get("spadek_na_tydzien_bez_prosby", 3)))
	stan_dziadkow["podejrzliwosc"] = p
	stan_dziadkow["ostatnia_wyplata_tydzien"] = tydzien
	var ev: Dictionary = _kiesz.get("event_tygodniowy", {}) if _kiesz.get("event_tygodniowy") is Dictionary else {}
	out["ok"] = true
	out["kwota"] = kwota
	out["tekst"] = str(ev.get("tekst_ok", "Dziadkowie dają kieszonkowe: +%d zł.")) % kwota
	return out


func _losuj_zestaw(los) -> Dictionary:
	var lista: Variant = _zestawy.get("zestawy", [])
	var wagi := {}
	var po_id := {}
	if lista is Array:
		for z in lista:
			if not (z is Dictionary) or not z.has("id"):
				continue
			var w: Variant = z.get("waga")
			if not (w is int or w is float) or float(w) <= 0.0:
				continue
			var id := str(z["id"])
			wagi[id] = float(w)
			po_id[id] = z
	if wagi.is_empty():
		return {"id": "brak"}
	var id_w: String = los.losuj_kolo(wagi)
	return po_id.get(id_w, {"id": "brak"})


func _losuj_osobe(ziarno_helper, los, kraj: String, rola: String, klucz_zawodu: String, klucz_imion: String) -> Dictionary:
	# Reużywa prywatnych helperów przez publiczne API ziarna — imię/zawód jak rodzic.
	var osoba := {
		"rola": rola,
		"imie": null,
		"charakter": [],
		"praca": {"id": null, "nazwa": null, "kolo": false},
		"zarobki": {},
	}
	# ZiarnoRodzicow nie eksportuje _losuj_rodzica — wywołaj losuj i weź wzorzec, albo lokalnie.
	# Używamy tej samej ścieżki: tymczasowy „rodzic” z losuj nie — kopiujemy logikę przez call.
	if ziarno_helper.has_method("_losuj_rodzica"):
		osoba = ziarno_helper.call("_losuj_rodzica", los, kraj, rola, klucz_zawodu, klucz_imion)
	else:
		osoba["imie"] = {"id": null, "nazwa": rola, "kolo": false}
	osoba["rola"] = rola
	return osoba


func _losuj_lokalizacje(los, miejsce: Variant) -> Dictionary:
	var wagi_blok: Dictionary = {}
	if _zestawy.get("lokalizacja") is Dictionary and _zestawy["lokalizacja"].get("wagi") is Dictionary:
		wagi_blok = _zestawy["lokalizacja"]["wagi"]
	var wagi := {}
	for k in wagi_blok.keys():
		wagi[str(k)] = float(wagi_blok[k])
	var wybor := "to_samo_miasto"
	if not wagi.is_empty():
		wybor = str(los.losuj_kolo(wagi))
	var out := {"tryb": wybor, "miasto_id": "", "miasto_nazwa": "", "propozycja_do_poprawki": true}
	if miejsce is Dictionary:
		out["miasto_id"] = str(miejsce.get("id", ""))
		out["miasto_nazwa"] = str(miejsce.get("nazwa", ""))
		out["wojewodztwo"] = str(miejsce.get("wojewodztwo", ""))
		if wybor != "to_samo_miasto":
			out["uwaga"] = "Sąsiednie/daleko — stub: to samo województwo; pełne losowanie miasta w Fali 2."
	return out


func _zarobki_uproszczone(rodzic_ref: Variant, los) -> Dictionary:
	var mnoznik := 0.55
	if _zestawy.get("zarobki") is Dictionary:
		mnoznik = float(_zestawy["zarobki"].get("mnoznik_emerytura", 0.55))
	var out := {
		"tryb": "emerytura_uproszczona",
		"od_zl": null,
		"do_zl": null,
		"kolo": false,
		"propozycja_do_poprawki": true,
	}
	if not (rodzic_ref is Dictionary):
		return out
	var z: Variant = rodzic_ref.get("zarobki", {})
	if not (z is Dictionary):
		return out
	if z.get("od_zl") is int or z.get("od_zl") is float:
		out["od_zl"] = int(round(float(z["od_zl"]) * mnoznik))
		out["kolo"] = true
	if z.get("do_zl") is int or z.get("do_zl") is float:
		out["do_zl"] = int(round(float(z["do_zl"]) * mnoznik))
		out["kolo"] = true
	if bool(out.get("kolo", false)):
		ZaokraglenieZarobkow.zaokraglij_blok(out)
	var szansa_praca := 0.22
	if _zestawy.get("zarobki") is Dictionary:
		szansa_praca = float(_zestawy["zarobki"].get("szansa_jeszcze_pracuje", 0.22))
	out["jeszcze_pracuje"] = randf() < szansa_praca
	return out


func _czytaj(sciezka: String) -> Variant:
	if not FileAccess.file_exists(sciezka):
		return null
	var plik := FileAccess.open(sciezka, FileAccess.READ)
	if plik == null:
		return null
	return JSON.parse_string(plik.get_as_text())
