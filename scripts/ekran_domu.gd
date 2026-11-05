extends RefCounted
class_name EkranDomu

## Ekrany domu, zdrowia i majątku.

var h


func _init(host) -> void:
	h = host




func _ekran_dom() -> void:
	var tekst := _tekst_domu()
	if tekst != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(tekst, 20))
	else:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Dom. Brak nazwy w zapisie.", 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(h._stan._opis_lokalizacji(), 15))


func _ekran_zdrowie() -> void:
	var bohater = h._stan._bohater()
	var skrot := str(bohater.get("zdrowie_skrot", ""))
	if skrot != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(skrot, 18))
	else:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zdrowie ilościowe pojawi się, gdy będzie w zapisie. Chorób na starcie nie wypisuję.", 16))
	var zdrowie = h._ui._tekst_pusty(bohater.get("zdrowie"))
	if zdrowie != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zdrowie: %s" % zdrowie, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(dep_txt, 15))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Terapia / nastrój — w podmenu Zdrowie.", 14))


func _ekran_majatek() -> void:
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Pieniądze", 18))
	var kwota = h._stan._pieniadze_tekst()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(kwota if kwota != "" else "—", 18))
	var opis_lokum := _opis_mieszkacie_w()
	if opis_lokum != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(opis_lokum, 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Nieruchomości", 18))
	var maj: Dictionary = h._swiat.get("majatek", {}) if h._swiat.get("majatek") is Dictionary else {}
	var n_lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if n_lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Własne kupione: brak — kup w Zakupach (generator, nie katalog 200).", 14))
	else:
		for i in range(n_lista.size()):
			var n: Variant = n_lista[i]
			if not (n is Dictionary):
				continue
			var linia := "%s · %s · wygoda %s · %s" % [
				str(n.get("nazwa", "?")),
				h._ekran_zakupow._etykieta_stanu_zakupu(str(n.get("stan", ""))),
				str(n.get("wygoda", "—")),
				str(n.get("miasto_nazwa", "")),
			]
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia, 14))
			var idx_bind := i
			var b_rem := Button.new()
			b_rem.text = "Remont (propozycja koszt/wygoda)"
			b_rem.custom_minimum_size = Vector2(0, 40)
			b_rem.pressed.connect(func() -> void:
				var wynik: Dictionary = h._rynek_zakupow.remont(h._swiat, idx_bind)
				if bool(wynik.get("ok", false)):
					h._rynek_zakupow.przelicz_zadowolenie_docelowe(h._swiat)
					h.SkryptZapisu.zapisz(h._swiat)
					h._stan._zsynchronizuj_pieniadze_z_bohatera()
					h._pasek._odswiez_pasek_statystyk(false)
					h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
				else:
					h._ui._tresc_biala().add_child(h._ui._napis_ekranu(str(wynik.get("powod", "Remont nieudany.")), 13))
			)
			h._ui._tresc_biala().add_child(b_rem)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Dobra", 18))
	var d_lista: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if d_lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Pusto.", 14))
	else:
		for i_d in range(d_lista.size()):
			var d: Variant = d_lista[i_d]
			if not (d is Dictionary):
				continue
			var nazwa_d := str(d.get("nazwa", "?"))
			if str(d.get("kategoria", "")) == "samochod":
				var linia_a := nazwa_d
				var vmax_m = h._rynek_zakupow.tekst_vmax_oferty(d, d.get("usterki_rzeczywiste", []) if d.get("usterki_rzeczywiste") is Array else [])
				if vmax_m != "":
					linia_a += " · vmax %s km/h" % vmax_m
				if h._ui._jest_liczba(d.get("rok_produkcji")):
					linia_a += " · rocznik %d" % int(d["rok_produkcji"])
				if bool(d.get("nie_jezdzi", false)):
					linia_a += " · " + h._rynek_zakupow.tekst_awarii_dla_gracza(d)
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia_a, 14))
				if bool(d.get("nie_jezdzi", false)) or bool(d.get("do_naprawy", false)):
					h._ui._tresc_biala().add_child(h._mapa_ekran._panel_awarii_auta(i_d, d))
			else:
				var linia_d := nazwa_d
				if h._rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var plus_d = h._rynek_zakupow.tekst_plusow(h._rynek_zakupow.plusy_oferty(d))
					if plus_d != "":
						linia_d += " · " + plus_d
				h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia_d, 14))
				if h._rynek_zakupow.kategoria_daje_plusy(str(d.get("kategoria", ""))):
					var b_oddaj := Button.new()
					b_oddaj.text = "Oddaj"
					b_oddaj.custom_minimum_size = Vector2(0, 40)
					var idx_d := i_d
					b_oddaj.pressed.connect(func() -> void:
						var wynik_o: Dictionary = h._rynek_zakupow.oddaj_dobro(h._swiat, idx_d)
						if bool(wynik_o.get("ok", false)):
							h.SkryptZapisu.zapisz(h._swiat)
							h._otworz_akcje({"id": "majatek", "nazwa": "Majątek", "tryb": "ekran", "tresc": "majatek"})
					)
					h._ui._tresc_biala().add_child(b_oddaj)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Wpływy", 18))
	var lista: Variant = h._swiat.get("wplywy", [])
	if not (lista is Array) or lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak wpływów.", 15))
		return
	var od := maxi(0, lista.size() - 12)
	for i in range(od, lista.size()):
		var wpis: Variant = lista[i]
		if not (wpis is Dictionary):
			continue
		var linia2 := str(wpis.get("tekst", ""))
		if linia2 == "" and h._ui._jest_liczba(wpis.get("kwota")):
			linia2 = "%s: +%d zł" % [str(wpis.get("zrodlo", "wpływ")), int(wpis["kwota"])]
		if linia2 != "":
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia2, 15))


func _tekst_domu() -> String:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return ""
	var dom: Variant = rodzina.get("dom", {})
	if dom is Dictionary and dom.get("kolo") == true and str(dom.get("nazwa", "")) != "":
		return str(dom.get("nazwa"))
	return ""


func _opis_mieszkacie_w() -> String:
	var lokum: Variant = h._swiat.get("lokum_startowe", {})
	if not h._stan._lokum_pelne(lokum):
		var maj: Variant = h._swiat.get("majatek", {})
		if maj is Dictionary and maj.get("lokum_rodziny") is Dictionary:
			lokum = maj["lokum_rodziny"]
		else:
			var rodzina: Variant = h._swiat.get("rodzina", {})
			if rodzina is Dictionary and rodzina.get("lokum") is Dictionary:
				lokum = rodzina["lokum"]
	return h._rynek_zakupow.opis_lokum_ui(lokum)
