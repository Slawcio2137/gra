extends RefCounted
class_name EventyTury

## Losowanie i UI eventów tygodnia.

var h


func _init(host) -> void:
	h = host




func _losuj_eventy_tury() -> void:
	var kontekst := _kontekst_eventow()
	var wylosowane: Array = h._eventy.losuj_ture(kontekst, h._losowanie)
	var karty_pytan: Array = []
	for ev in wylosowane:
		if not (ev is Dictionary):
			continue
		if bool(ev.get("pytanie", false)):
			karty_pytan.append(ev)
			continue
		var wynik: Dictionary = h._eventy.zastosuj_bez_pytania(ev)
		_zastosuj_wynik_eventu(wynik)
		var t := str(wynik.get("tekst", ev.get("tekst", "")))
		if t != "":
			var kom := str(h._swiat.get("komunikat_tury", "")).strip_edges()
			h._swiat["komunikat_tury"] = t if kom == "" else kom + "\n" + t
	h._swiat["eventy_tury"] = karty_pytan


func _kontekst_eventow() -> Dictionary:
	var flagi: Dictionary = {}
	if h._swiat.get("flagi_odkrycia") is Dictionary:
		flagi = (h._swiat["flagi_odkrycia"] as Dictionary).duplicate(true)
	var rodzenstwo: Variant = h._swiat.get("rodzenstwo", [])
	var jedynak := true
	if rodzenstwo is Array and not rodzenstwo.is_empty():
		jedynak = false
	var rodzina: Variant = h._swiat.get("rodzina", {})
	var cechy: Array = []
	var przedzial := ""
	if rodzina is Dictionary:
		if rodzina.get("charakter") is Array:
			for c in rodzina["charakter"]:
				if c is Dictionary and str(c.get("id", "")) != "":
					cechy.append(str(c["id"]))
				elif c is String:
					cechy.append(c)
		if rodzina.get("zarobki") is Dictionary:
			przedzial = str(rodzina["zarobki"].get("przedzial_id", ""))
	var bohater = h._stan._bohater()
	var pieniadze_ok = h._ui._jest_liczba(bohater.get("pieniadze")) and int(bohater["pieniadze"]) > 0
	var ma := {
		"telefon": bool(flagi.get("ma_telefon", false)) or bool(flagi.get("wie_o_telefonie", false)),
		"portfel": bool(flagi.get("ma_portfel", false)),
		"pieniadze": pieniadze_ok,
	}
	# Zgubienie ważnego: jeśli ma pieniądze, wystarczy.
	if pieniadze_ok:
		ma["pieniadze"] = true
	return {
		"wiek": h._stan._wiek_lat(),
		"jedynak": jedynak,
		"flagi": flagi,
		"ma": ma,
		"cechy_rodzicow": cechy,
		"przedzial_zarobkow": przedzial,
	}


func _pokaz_eventy_tury_ui() -> void:
	var eventy: Variant = h._swiat.get("eventy_tury", [])
	if not (eventy is Array):
		return
	for ev in eventy:
		if not (ev is Dictionary):
			continue
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(ev.get("tekst", "")), 15))
		if not bool(ev.get("pytanie", false)):
			continue
		var rzad := HBoxContainer.new()
		rzad.add_theme_constant_override("separation", 8)
		var opcje: Variant = ev.get("opcje", [])
		if not (opcje is Array) or opcje.is_empty():
			opcje = [{"id": "tak", "nazwa": "Tak"}, {"id": "nie", "nazwa": "Nie"}]
		for op in opcje:
			if not (op is Dictionary):
				continue
			var b := Button.new()
			b.text = str(op.get("nazwa", op.get("id", "?")))
			b.custom_minimum_size = Vector2(72, 40)
			var ev_bind: Dictionary = ev
			var op_id := str(op.get("id", ""))
			b.pressed.connect(func() -> void:
				_on_odpowiedz_eventu(ev_bind, op_id)
			)
			rzad.add_child(b)
		h._ui._tresc_biala().add_child(rzad)


func _on_odpowiedz_eventu(ev: Dictionary, opcja_id: String) -> void:
	var wynik: Dictionary = h._eventy.zastosuj_wybor(ev, opcja_id, _kontekst_eventow())
	_zastosuj_wynik_eventu(wynik)
	# Usuń ten event z listy oczekujących pytań.
	var zostalo: Array = []
	var lista: Variant = h._swiat.get("eventy_tury", [])
	if lista is Array:
		for e in lista:
			if e is Dictionary and str(e.get("id", "")) == str(ev.get("id", "")):
				continue
			zostalo.append(e)
	h._swiat["eventy_tury"] = zostalo
	h._swiat["event_odpowiedz_tekst"] = str(wynik.get("tekst", ""))
	if str(wynik.get("skutek", "")) == "kieszonkowe_argument_ok":
		# Lekkie otwarcie drogi do kieszonkowego — bez automatycznej wypłaty.
		var flagi: Dictionary = h._swiat.get("flagi_odkrycia", {})
		if not (flagi is Dictionary):
			flagi = {}
		flagi["argument_kieszonkowe_ok"] = true
		h._swiat["flagi_odkrycia"] = flagi
	elif str(wynik.get("skutek", "")) == "dodaj_znajomego_dziecka" or str(ev.get("skutek", "")) == "dodaj_znajomego_dziecka":
		_dodaj_znajomego_dziecka()
	h.SkryptZapisu.zapisz(h._swiat)
	h._pokaz_napisy_tygodnia()


func _zastosuj_wynik_eventu(wynik: Dictionary) -> void:
	var flagi: Dictionary = {}
	if h._swiat.get("flagi_odkrycia") is Dictionary:
		flagi = h._swiat["flagi_odkrycia"]
	for f in wynik.get("flagi", []):
		flagi[str(f)] = true
	h._swiat["flagi_odkrycia"] = flagi
	var tematy: Array = []
	if h._swiat.get("odblokowane_tematy_pytan") is Array:
		tematy = h._swiat["odblokowane_tematy_pytan"]
	for t in wynik.get("odblokuj_pytania", []):
		var tid := str(t)
		if not tematy.has(tid):
			tematy.append(tid)
	h._swiat["odblokowane_tematy_pytan"] = tematy
	var skutki: Variant = wynik.get("skutki", {})
	if skutki is Dictionary:
		# Propozycja: zapisujemy jako flagi skutków; pełny pasek psychiki później.
		for k in skutki.keys():
			flagi["skutek_%s" % str(k)] = skutki[k]
		h._swiat["flagi_odkrycia"] = flagi
	if str(wynik.get("skutek", "")) == "dodaj_znajomego_dziecka":
		_dodaj_znajomego_dziecka()


func _dodaj_znajomego_dziecka() -> void:
	var lista: Array = []
	if h._swiat.get("znajomi_dzieci") is Array:
		lista = h._swiat["znajomi_dzieci"]
	var plec_b := str(h._stan._bohater().get("plec", h._stan._bohater().get("płeć", "")))
	var ta_sama := plec_b
	lista.append({
		"id": "dziecko_%d" % (lista.size() + 1),
		"nazwa": "Poznane dziecko",
		"plec": ta_sama,
		"rodzice": [{"rola": "rodzic", "nazwa": "Rodzic poznanego dziecka"}],
		"uwaga": "Rodzice tej osoby w Osoby→ta osoba, nie na głównej liście rodziny.",
	})
	h._swiat["znajomi_dzieci"] = lista
	# Lekko też do znajomych gry (nie rodzina).
	var znajomi: Array = []
	if h._swiat.get("znajomi") is Array:
		znajomi = h._swiat["znajomi"]
	znajomi.append({"id": "znajomy_dziecko_%d" % znajomi.size(), "nazwa": "Poznane dziecko", "skad": "przedszkole_szkola"})
	h._swiat["znajomi"] = znajomi


func _fallback_nauki_szkolnej() -> void:
	# Jak nie nauczy się w domu — i tak w podstawówce (~7).
	var wiek: Variant = h._stan._wiek_lat()
	if not h._ui._jest_liczba(wiek) or int(wiek) < 7:
		return
	var flagi: Dictionary = {}
	if h._swiat.get("flagi_odkrycia") is Dictionary:
		flagi = h._swiat["flagi_odkrycia"]
	if not bool(flagi.get("uczy_sie_czytac_w_domu", false)):
		flagi["nauczy_sie_czytac_w_szkole"] = true
		flagi["umie_czytac"] = true
	if not bool(flagi.get("uczy_sie_pisac_w_domu", false)):
		flagi["umie_pisac"] = true
	if not bool(flagi.get("uczy_sie_liczyc_w_domu", false)):
		flagi["umie_liczyc"] = true
	h._swiat["flagi_odkrycia"] = flagi
