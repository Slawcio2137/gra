extends RefCounted
class_name EkranFali2

## Ekrany fali 2: korepetycje, zajęcia, szachy, imprezy, terapia, lotnictwo, konserwacja auta.

var h


func _init(host) -> void:
	h = host




func _efekt_konserwacji_auta_tydzien() -> void:
	var auto: Variant = h._swiat.get("auto", null)
	if not (auto is Dictionary):
		return
	var stan_k: Dictionary = {}
	if auto.get("konserwacja") is Dictionary:
		stan_k = auto["konserwacja"]
	else:
		var k := KonserwacjaAuta.new()
		stan_k = k.stan_startowy()
	var kon := KonserwacjaAuta.new()
	var tydzien := int(h._swiat.get("tydzien", 1))
	var zima := tydzien <= 8 or tydzien >= 48
	var efekt: Dictionary = kon.efekt_tury(stan_k, zima)
	auto["konserwacja"] = stan_k
	h._swiat["auto"] = auto
	if efekt.get("teksty") is Array and not (efekt["teksty"] as Array).is_empty():
		var kom := str(h._swiat.get("komunikat_tury", ""))
		var dop := " · ".join(PackedStringArray(efekt["teksty"]))
		h._swiat["komunikat_tury"] = (kom + "\n" + dop).strip_edges() if kom != "" else dop


func _stub_przedszkole() -> void:
	# Stub klikalny — nie pełny system.
	var chodzi := randf() < 0.55
	var tekst := "Przedszkole: chodzisz (często)." if chodzi else "Przedszkole: nie zawsze / nie chodzisz."
	if h._swiat.has("przedszkole_tekst"):
		tekst = str(h._swiat["przedszkole_tekst"])
	else:
		h._swiat["przedszkole_tekst"] = tekst
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(tekst, 15))
	var pytania := Button.new()
	pytania.text = "Pytanie do kogoś (stub)"
	pytania.custom_minimum_size = Vector2(0, 44)
	pytania.pressed.connect(_stub_pytanie_dziecka)
	h._ui._tresc_biala().add_child(pytania)


func _efekt_fala2_tydzien() -> void:
	var bohater = h._stan._bohater()
	var ie := InteligencjaEmocjonalna.new()
	ie.reset_tydzien(bohater)
	var kor := Korepetycje.new()
	kor.reset_tydzien(bohater)
	var dep := Depresja.new()
	var dres: Dictionary = dep.tydzien(bohater)
	if bool(dres.get("zmiana", false)):
		h._pasek._dopisz_komunikat_tury(str(dres.get("tekst", "")))
	var zaj := ZajeciaDodatkowe.new()
	var syl := Sylwetka.new()
	syl.z_zapisu(bohater.get("sylwetka", {}))
	var ez: Dictionary = zaj.efekt_tygodnia(bohater, syl)
	if ez.get("teksty") is Array and not (ez["teksty"] as Array).is_empty():
		h._pasek._dopisz_komunikat_tury("Zajęcia: " + ", ".join(PackedStringArray(ez["teksty"])))
	# Doprecyzowanie zainteresowań z wiekiem.
	if bohater.get("zainteresowanie") is Dictionary:
		var zan := ZainteresowaniaLos.new()
		bohater["zainteresowanie"] = zan.doprecyzuj_z_wiekiem(bohater["zainteresowanie"], int(bohater.get("wiek", 0)), h._losowanie)
	var lot := SprowadzanieSamolotow.new()
	var odsm: Dictionary = lot.sprawdz_odblokowanie_smiglowcow(bohater)
	if bool(odsm.get("odblokowane", false)):
		h._pasek._dopisz_komunikat_tury(str(odsm.get("tekst", "")))
	h._swiat["bohater"] = bohater


func _pasek_sylwetki(bohater: Dictionary) -> Control:
	var blok: Variant = bohater.get("sylwetka", {})
	var syl := Sylwetka.new()
	syl.z_zapisu(blok)
	var rzad := VBoxContainer.new()
	rzad.add_theme_constant_override("separation", 2)
	var pasek := ProgressBar.new()
	pasek.min_value = 0
	pasek.max_value = syl.cap()
	pasek.value = syl.punkty
	pasek.show_percentage = false
	pasek.custom_minimum_size = Vector2(0, 18)
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(h.ZIELONY)
	styl.corner_radius_top_left = 4
	styl.corner_radius_top_right = 4
	styl.corner_radius_bottom_left = 4
	styl.corner_radius_bottom_right = 4
	pasek.add_theme_stylebox_override("fill", styl)
	rzad.add_child(pasek)
	rzad.add_child(h._ui._napis_ekranu("%d/%d" % [syl.punkty, syl.cap()], 12))
	return rzad


func _odswiez_bohatera_i_ekran(tresc: String, nazwa: String) -> void:
	h._swiat["bohater"] = h._stan._bohater()
	h.SkryptZapisu.zapisz(h._swiat)
	h._stan._zsynchronizuj_pieniadze_z_bohatera()
	h._pasek._odswiez_pasek_statystyk(true)
	h._otworz_akcje({"id": tresc, "nazwa": nazwa, "tryb": "ekran", "tresc": tresc})


func _ekran_korepetycje() -> void:
	var bohater = h._stan._bohater()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Korepetycje (propozycja kosztów). Wiedza: %d" % int(bohater.get("wiedza_pkt", 0)), 16))
	var kor := Korepetycje.new()
	for p in kor.lista():
		if not (p is Dictionary):
			continue
		var b := Button.new()
		b.text = "%s (~%s–%s zł)" % [
			str(p.get("nazwa", "")),
			str((p.get("koszt_zajecia_zl", [0, 0]) as Array)[0] if p.get("koszt_zajecia_zl") is Array else "?"),
			str((p.get("koszt_zajecia_zl", [0, 0]) as Array)[1] if p.get("koszt_zajecia_zl") is Array and (p["koszt_zajecia_zl"] as Array).size() > 1 else "?"),
		]
		b.custom_minimum_size = Vector2(0, 44)
		var id_b := str(p.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = kor.zajecie(h._stan._bohater(), id_b)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("korepetycje", "Korepetycje")
		)
		h._ui._tresc_biala().add_child(b)


func _ekran_zajecia_dodatkowe() -> void:
	var bohater = h._stan._bohater()
	var zaj := ZajeciaDodatkowe.new()
	var akt = zaj.aktywne(bohater)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Aktywne: %s" % (", ".join(PackedStringArray(akt)) if not akt.is_empty() else "brak"), 15))
	for z in zaj.lista(h._stan._wiek_lat()):
		if not (z is Dictionary):
			continue
		var b := Button.new()
		b.text = "Zapisz: %s" % str(z.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_z := str(z.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = zaj.zapisz_sie(h._stan._bohater(), id_z)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("zajecia_dodatkowe", "Zajęcia dodatkowe")
		)
		h._ui._tresc_biala().add_child(b)


func _ekran_szachy() -> void:
	var bohater = h._stan._bohater()
	var sz := Szachy.new()
	sz.zapewnij_ranking(bohater)
	h._swiat["bohater"] = bohater
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Ranking lokalny (nie ELO FIDE): %d" % sz.ranking(bohater), 16))
	var bt := Button.new()
	bt.text = "Trening"
	bt.custom_minimum_size = Vector2(0, 44)
	bt.pressed.connect(func() -> void:
		var w: Dictionary = sz.trening(h._stan._bohater())
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
		if bool(w.get("ok", false)):
			_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
	)
	h._ui._tresc_biala().add_child(bt)
	for t in sz.turnieje(h._stan._wiek_lat()):
		if not (t is Dictionary):
			continue
		var b := Button.new()
		b.text = "Turniej: %s (wpisowe %d zł)" % [str(t.get("nazwa", "")), int(t.get("wpisowe_zl", 0))]
		b.custom_minimum_size = Vector2(0, 44)
		var id_t := str(t.get("id", ""))
		b.pressed.connect(func() -> void:
			var w2: Dictionary = sz.graj_turniej(h._stan._bohater(), id_t)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("szachy", "Szachy / turnieje")
		)
		h._ui._tresc_biala().add_child(b)


func _ekran_imprezy() -> void:
	var bohater = h._stan._bohater()
	var dep := Depresja.new()
	if dep.blokada_imprez(bohater):
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Kryzys nastroju — imprezy zablokowane (stub).", 15))
		return
	var im := ImprezyUzywki.new()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Imprezy / używki (stub). Wiek %d." % h._stan._wiek_lat(), 16))
	for p in im.lista_imprez(h._stan._wiek_lat()):
		if not (p is Dictionary):
			continue
		var id_p := str(p.get("id", ""))
		var b1 := Button.new()
		b1.text = "%s (bez picia)" % str(p.get("nazwa", ""))
		b1.custom_minimum_size = Vector2(0, 44)
		b1.pressed.connect(func() -> void:
			var w: Dictionary = im.idz_na_impreze(h._stan._bohater(), h._swiat, id_p, false)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		h._ui._tresc_biala().add_child(b1)
		var b2 := Button.new()
		b2.text = "%s (+ picie stub)" % str(p.get("nazwa", ""))
		b2.custom_minimum_size = Vector2(0, 44)
		b2.pressed.connect(func() -> void:
			var w2: Dictionary = im.idz_na_impreze(h._stan._bohater(), h._swiat, id_p, true)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w2.get("tekst", "")), 14))
			if bool(w2.get("ok", false)):
				_odswiez_bohatera_i_ekran("imprezy", "Imprezy / używki")
		)
		h._ui._tresc_biala().add_child(b2)


func _ekran_terapia() -> void:
	var bohater = h._stan._bohater()
	var dep := Depresja.new()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Nastrój / terapia (stub). Nie jest to porada medyczna.", 15))
	var st = dep.tekst_stanu(bohater)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(st if st != "" else "Bez flagi depresji.", 15))
	var ie := InteligencjaEmocjonalna.new()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(ie.tekst(bohater), 14))
	for tryb in ["nfz", "prywatna"]:
		var b := Button.new()
		b.text = "Terapia: %s" % tryb
		b.custom_minimum_size = Vector2(0, 44)
		var tryb_b := str(tryb)
		b.pressed.connect(func() -> void:
			var w: Dictionary = dep.terapia(h._stan._bohater(), tryb_b)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("terapia", "Terapia / nastrój")
		)
		h._ui._tresc_biala().add_child(b)


func _ekran_konserwacja_auta() -> void:
	var auto: Variant = h._swiat.get("auto", null)
	if not (auto is Dictionary):
		# Szukaj w majątku.
		var maj: Dictionary = h._swiat.get("majatek", {}) if h._swiat.get("majatek") is Dictionary else {}
		var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
		for d in dobra:
			if d is Dictionary and str(d.get("kategoria", "")) == "samochod":
				auto = d
				break
	if not (auto is Dictionary):
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak auta — kup w Zakupach, potem wróć tu.", 15))
		return
	var kon := KonserwacjaAuta.new()
	var stan_k: Dictionary = {}
	if auto.get("konserwacja") is Dictionary:
		stan_k = auto["konserwacja"]
	else:
		stan_k = kon.stan_startowy()
		auto["konserwacja"] = stan_k
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(auto.get("nazwa", "Auto")), 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(kon.tekst_stanu(stan_k), 15))
	for czesc in ["olej", "filtry", "opony"]:
		h._ui._tresc_biala().add_child(_pasek_konserwacji(czesc, int(stan_k.get(czesc, 0))))
	var zima_btn := CheckButton.new()
	zima_btn.text = "Konserwacja zimowa"
	zima_btn.button_pressed = bool(stan_k.get("konserwacja_zima", false))
	zima_btn.toggled.connect(func(wl: bool) -> void:
		kon.ustaw_konserwacje_zimowa(stan_k, wl)
		_zapisz_konserwacje_auta(auto, stan_k)
	)
	h._ui._tresc_biala().add_child(zima_btn)
	for sposob in ["samodzielnie", "youtube", "przyjaciel_mechanik", "warsztat"]:
		for czesc2 in ["olej", "filtry", "opony"]:
			var b := Button.new()
			b.text = "%s → %s" % [czesc2, sposob]
			b.custom_minimum_size = Vector2(0, 40)
			var cz := str(czesc2)
			var sp := str(sposob)
			b.pressed.connect(func() -> void:
				var w: Dictionary = kon.serwis(stan_k, cz, sp)
				var koszt := int(w.get("koszt_zl", 0))
				if bool(w.get("ok", false)) and koszt > 0:
					var boh = h._stan._bohater()
					if int(boh.get("pieniadze", 0)) < koszt:
						h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak kasy na serwis.", 13))
						return
					boh["pieniadze"] = int(boh["pieniadze"]) - koszt
					h._swiat["bohater"] = boh
				_zapisz_konserwacje_auta(auto, stan_k)
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 13))
				if bool(w.get("ok", false)):
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
			)
			h._ui._tresc_biala().add_child(b)
	if bool(stan_k.get("rdza", false)) or bool(stan_k.get("zatarcie", false)):
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Poważne: rdza/zatarcie — warsztat.", 14))
		for cz3 in ["rdza", "zatarcie"]:
			if not bool(stan_k.get(cz3, false)):
				continue
			var bw := Button.new()
			bw.text = "Napraw %s (warsztat)" % cz3
			bw.custom_minimum_size = Vector2(0, 44)
			var czb := str(cz3)
			bw.pressed.connect(func() -> void:
				var w3: Dictionary = kon.serwis(stan_k, czb, "warsztat")
				var koszt3 := int(w3.get("koszt_zl", 0))
				var boh3 = h._stan._bohater()
				if bool(w3.get("ok", false)) and int(boh3.get("pieniadze", 0)) >= koszt3:
					boh3["pieniadze"] = int(boh3["pieniadze"]) - koszt3
					h._swiat["bohater"] = boh3
					_zapisz_konserwacje_auta(auto, stan_k)
					_odswiez_bohatera_i_ekran("konserwacja_auta", "Konserwacja auta")
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w3.get("tekst", "")), 13))
			)
			h._ui._tresc_biala().add_child(bw)


func _pasek_konserwacji(nazwa: String, wartosc: int) -> Control:
	var rzad := HBoxContainer.new()
	rzad.add_theme_constant_override("separation", 8)
	rzad.add_child(h._ui._napis_ekranu(nazwa.capitalize(), 13))
	var pasek := ProgressBar.new()
	pasek.min_value = 0
	pasek.max_value = 100
	pasek.value = wartosc
	pasek.show_percentage = false
	pasek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pasek.custom_minimum_size = Vector2(80, 16)
	var styl := StyleBoxFlat.new()
	styl.bg_color = Color(h.ZIELONY) if wartosc > 30 else Color(h.KRWISTY)
	pasek.add_theme_stylebox_override("fill", styl)
	rzad.add_child(pasek)
	rzad.add_child(h._ui._napis_ekranu(str(wartosc), 12))
	return rzad


func _zapisz_konserwacje_auta(auto: Variant, stan_k: Dictionary) -> void:
	if not (auto is Dictionary):
		return
	auto["konserwacja"] = stan_k
	if h._swiat.get("auto") is Dictionary:
		h._swiat["auto"]["konserwacja"] = stan_k
	var maj: Variant = h._swiat.get("majatek", {})
	if maj is Dictionary and maj.get("dobra") is Array:
		for i in range((maj["dobra"] as Array).size()):
			var d: Variant = maj["dobra"][i]
			if d is Dictionary and str(d.get("kategoria", "")) == "samochod":
				d["konserwacja"] = stan_k
				maj["dobra"][i] = d
				break
		h._swiat["majatek"] = maj
	h.SkryptZapisu.zapisz(h._swiat)


func _ekran_lotnictwo() -> void:
	var bohater = h._stan._bohater()
	var lot := SprowadzanieSamolotow.new()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(lot.tekst_ui(bohater), 15))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Sprowadzanie samolotów — stub licencji/hangaru (katalog już jest).", 14))
	for l in lot.lista_licencji():
		if not (l is Dictionary):
			continue
		var b := Button.new()
		b.text = "Licencja: %s" % str(l.get("nazwa", ""))
		b.custom_minimum_size = Vector2(0, 44)
		var id_l := str(l.get("id", ""))
		b.pressed.connect(func() -> void:
			var w: Dictionary = lot.kup_licencje(h._stan._bohater(), id_l)
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 14))
			if bool(w.get("ok", false)):
				_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
		)
		h._ui._tresc_biala().add_child(b)
	var bh := Button.new()
	bh.text = "Wynajmij hangar (miesiąc stub)"
	bh.custom_minimum_size = Vector2(0, 44)
	bh.pressed.connect(func() -> void:
		var w2: Dictionary = lot.wynajmij_hangar(h._stan._bohater())
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w2.get("tekst", "")), 14))
		if bool(w2.get("ok", false)):
			_odswiez_bohatera_i_ekran("lotnictwo", "Lotnictwo (stub)")
	)
	h._ui._tresc_biala().add_child(bh)
	var od = lot.sprawdz_odblokowanie_smiglowcow(bohater)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(od.get("tekst", "")), 13))


func _ekran_eventy_przyklady() -> void:
	var ev := EventyPrzyklady.new()
	var lista := ev.lista_eventow()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Pakiet eventów: %d (Fala 1+2). Kliknij opcję." % lista.size(), 15))
	for e in lista:
		if not (e is Dictionary):
			continue
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("%s — %s" % [str(e.get("nazwa", "")), str(e.get("opis", ""))], 14))
		if e.get("opcje") is Array:
			for o in e["opcje"]:
				if not (o is Dictionary):
					continue
				var b := Button.new()
				b.text = str(o.get("tekst", o.get("id", "")))
				b.custom_minimum_size = Vector2(0, 36)
				var eid := str(e.get("id", ""))
				var oid := str(o.get("id", ""))
				b.pressed.connect(func() -> void:
					var w: Dictionary = ev.zastosuj_opcje(h._stan._bohater(), eid, oid)
					h._swiat["bohater"] = h._stan._bohater()
					h.SkryptZapisu.zapisz(h._swiat)
					h._pasek._odswiez_pasek_statystyk(true)
					h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(w.get("tekst", "")), 13))
				)
				h._ui._tresc_biala().add_child(b)


func _stub_pytanie_dziecka() -> void:
	var temat := "dlaczego niebo jest niebieskie"
	var rozmowca := "matka"
	if FileAccess.file_exists("res://postacie/tematy_pytan.json"):
		var plik := FileAccess.open("res://postacie/tematy_pytan.json", FileAccess.READ)
		if plik != null:
			var dane: Variant = JSON.parse_string(plik.get_as_text())
			var tematy: Variant = null
			if dane is Dictionary:
				if dane.get("tematy_bazowe") is Array:
					tematy = dane["tematy_bazowe"]
				elif dane.get("tematy") is Array:
					tematy = dane["tematy"]
			elif dane is Array:
				tematy = dane
			if tematy is Array and not tematy.is_empty():
				var t0: Variant = tematy[0]
				if t0 is Dictionary:
					temat = str(t0.get("nazwa", t0.get("id", temat)))
				elif t0 is String:
					temat = str(t0)
	h._ui._wyczysc(h._ui._tresc_biala())
	h._ui._tytul_bialy().text = "Pytanie"
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Temat: %s" % temat, 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Rozmówca: %s (wybór stub)" % rozmowca, 15))
	for kto in ["matka", "ojciec"]:
		var b := Button.new()
		b.text = "Zapytaj: %s" % kto
		b.custom_minimum_size = Vector2(0, 44)
		var kto_bind: String = str(kto)
		b.pressed.connect(func() -> void:
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu("(%s) Odpowiedź stub — pełny system później." % kto_bind, 14))
		)
		h._ui._tresc_biala().add_child(b)
