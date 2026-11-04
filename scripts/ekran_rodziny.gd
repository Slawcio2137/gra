extends RefCounted
class_name EkranRodziny

## Postać, rodzina, dziadkowie i kieszonkowe.

var h


func _init(host) -> void:
	h = host




func _wyplata_kieszonkowego_tydzien() -> void:
	if not bool(h._swiat.get("kieszonkowe_aktywne", false)):
		return
	var tryb := str(h._swiat.get("tryb_kieszonkowego", ""))
	if tryb == "":
		return
	var tydzien := int(h._swiat.get("tydzien", 0))
	if int(h._swiat.get("kieszonkowe_ostatnia_wyplata_tydzien", -1)) == tydzien:
		return
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.wyplata_tygodniowa_kieszonkowego(
		rodzina, tryb, true, h._swiat.get("kieszonkowe_kwota_zl", null), h._stan._wiek_lat()
	)
	if not bool(wynik.get("dodano", false)) or not h._ui._jest_liczba(wynik.get("kwota")):
		return
	h._stan._dodaj_pieniadze(int(wynik["kwota"]))
	h._stan._dodaj_wplyw(str(wynik.get("zrodlo_wplywu", "kieszonkowe")), int(wynik["kwota"]), str(wynik.get("tekst", "")))
	h._swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = tydzien
	var tekst := str(wynik.get("tekst", ""))
	h._swiat["komunikat_tury"] = tekst
	h._swiat["ostatnie_kieszonkowe_tekst"] = tekst


func _ekran_postac() -> void:
	var bohater = h._stan._bohater()
	var imie = h._ui._tekst_pusty(bohater.get("imie"))
	var nazwisko = h._ui._tekst_pusty(bohater.get("nazwisko"))
	if imie != "" or nazwisko != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(("%s %s" % [imie, nazwisko]).strip_edges(), 18))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Cechy charakteru", 18))
	var cechy := _cechy_bohatera(bohater)
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(cechy if cechy != "" else "—", 16))
	var inteligencje := _inteligencje_bohatera(bohater)
	if inteligencje != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Inteligencja", 18))
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(inteligencje, 16))
	var urodzenie := _opis_urodzenia()
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Miejsce urodzenia", 18))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(urodzenie if urodzenie != "" else "—", 16))
	var wiek = h._ui._tekst_liczby(bohater.get("wiek"))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Wiek: %s" % (wiek if wiek != "" else "—"), 16))
	var psychika = h._ui._tekst_liczby(h._pasek._wartosc_metryki("psychika"))
	var zm_f = h._ui._tekst_liczby(h._pasek._wartosc_metryki("zmeczenie_fizyczne"))
	if zm_f == "":
		zm_f = h._ui._tekst_liczby(h._pasek._wartosc_metryki("zmeczenie"))
	var zm_p = h._ui._tekst_liczby(h._pasek._wartosc_metryki("zmeczenie_psychiczne"))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Psychika (nastrój): %s" % (psychika if psychika != "" else "—"), 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Zmęczenie fizyczne: %s   Obciążenie psychiczne: %s" % [
		zm_f if zm_f != "" else "—",
		zm_p if zm_p != "" else "—"
	], 16))
	var syl_txt := _opis_sylwetki(bohater)
	if syl_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(syl_txt, 16))
		h._ui._tresc_biala().add_child(h._pasek_sylwetki(bohater))
	var ie := InteligencjaEmocjonalna.new()
	var ie_txt := ie.tekst(bohater)
	if ie_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(ie_txt, 16))
	var wiedza = h._ui._tekst_liczby(bohater.get("wiedza_pkt"))
	if wiedza != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Wiedza (pkt stub): %s" % wiedza, 15))
	var zan_txt := _opis_zainteresowania(bohater)
	if zan_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(zan_txt, 16))
	var dep := Depresja.new()
	var dep_txt := dep.tekst_stanu(bohater)
	if dep_txt != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(dep_txt, 14))
	elif bool(bohater.get("depresja", false)):
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Flaga: depresja.", 14))
	# Docelowe tylko w trybie deweloperskim — nigdy na pasku / w normalnej grze.
	if h.DostepStatystyk.POKAZ_STATYSTYKI:
		var doc_dev = h._ui._tekst_liczby(h._stan._bohater().get("zadowolenie_docelowe"))
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Docelowe (dev, ukryte): %s" % (doc_dev if doc_dev != "" else "—"), 14))


func _ekran_rodzina() -> void:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary) or rodzina.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Rodzina nie weszła do zapisu. Spróbuj Start jeszcze raz — jeśli dalej pusto, losowanie padło.", 16))
		return
	var rodzice_box := _dodaj_sekcje_zwijana("rodzice", "Rodzice")
	rodzice_box.add_child(h._ui._napis_ekranu("Matka", 18))
	rodzice_box.add_child(h._ui._napis_ekranu(_opis_rodzica(rodzina.get("matka")), 16))
	rodzice_box.add_child(h._ui._napis_ekranu("Ojciec", 18))
	rodzice_box.add_child(h._ui._napis_ekranu(_opis_rodzica(rodzina.get("ojciec")), 16))
	var dziadkowie_box := _dodaj_sekcje_zwijana("dziadkowie", "Dziadkowie")
	_wypelnij_dziadkow(dziadkowie_box, rodzina.get("dziadkowie"))
	var prosba_d := Button.new()
	prosba_d.text = "Poproś dziadków o kieszonkowe"
	prosba_d.custom_minimum_size = Vector2(0, 48)
	prosba_d.pressed.connect(_on_kieszonkowe_dziadkowie)
	h._ui._tresc_biala().add_child(prosba_d)
	var wynik_d = h._ui._napis_ekranu(str(h._swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")), 15)
	wynik_d.visible = str(h._swiat.get("ostatnie_kieszonkowe_dziadkowie_tekst", "")) != ""
	h._ui._tresc_biala().add_child(wynik_d)
	var zarobki := _tekst_zarobkow(rodzina.get("zarobki"))
	var etykieta_gosp := "Zarobki rodziny (suma rodziców)"
	if rodzina.get("zarobki") is Dictionary and str(rodzina["zarobki"].get("dochód_gospodarstwa", "")) == "suma_przedzialow_rodzicow":
		etykieta_gosp = "Zarobki gospodarstwa (suma przedziałów matki i ojca)"
	if zarobki == "" and rodzina.get("zarobki") is Dictionary:
		var powod := str(rodzina["zarobki"].get("powod", ""))
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("%s: —%s" % [etykieta_gosp, ((" (%s)" % powod) if powod != "" else "")], 16))
	else:
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("%s: %s" % [etykieta_gosp, zarobki if zarobki != "" else "—"], 16))
	var opis_lokum = h._dom._opis_mieszkacie_w()
	if opis_lokum != "":
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(opis_lokum, 16))
	else:
		var dom = h._dom._tekst_domu()
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Dom: %s" % (dom if dom != "" else "brak lokum w zapisie"), 16))
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Rodzeństwo", 18))
	var rodzenstwo: Variant = h._swiat.get("rodzenstwo", [])
	if not (rodzenstwo is Array) or rodzenstwo.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu("Brak rodzeństwa (wylosowano 0).", 16))
	else:
		var nr := 1
		for osoba in rodzenstwo:
			if not (osoba is Dictionary):
				continue
			h._ui._tresc_biala().add_child(h._ui._napis_ekranu(_opis_rodzenstwa(osoba, nr), 16))
			nr += 1
	var ziarno_ui := ZiarnoRodzicow.new()
	var tryb_id := str(h._swiat.get("tryb_kieszonkowego", ""))
	var aktywne := bool(h._swiat.get("kieszonkowe_aktywne", false))
	var tryb_etykieta := ziarno_ui.etykieta_trybu_kieszonkowego(tryb_id) if aktywne else "jeszcze nie proszono"
	var linia_kiesz := "Kieszonkowe: %s" % tryb_etykieta
	if aktywne and (tryb_id == "stala_kwota" or tryb_id == "stale_daje"):
		if h._ui._jest_liczba(h._swiat.get("kieszonkowe_kwota_zl")):
			var kwota_k := int(h.ZaokraglenieZarobkow.zaokraglij(h._swiat["kieszonkowe_kwota_zl"]))
			h._swiat["kieszonkowe_kwota_zl"] = kwota_k
			linia_kiesz += " · %d zł/tydzień" % kwota_k
		else:
			linia_kiesz += " · kwota tygodniowa: —"
	h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia_kiesz, 16))
	var prosba := Button.new()
	prosba.text = "Poproś o kieszonkowe"
	prosba.custom_minimum_size = Vector2(0, 48)
	prosba.pressed.connect(_on_kieszonkowe)
	h._ui._tresc_biala().add_child(prosba)
	var podwyzka := Button.new()
	podwyzka.text = "Poproś o podniesienie kieszonkowego"
	podwyzka.custom_minimum_size = Vector2(0, 48)
	podwyzka.disabled = not aktywne
	podwyzka.pressed.connect(_on_kieszonkowe_podwyzka)
	h._ui._tresc_biala().add_child(podwyzka)
	var jednoraz := Button.new()
	jednoraz.text = "Poproś o pieniądze na coś"
	jednoraz.custom_minimum_size = Vector2(0, 48)
	jednoraz.pressed.connect(_on_pieniadze_jednorazowo)
	h._ui._tresc_biala().add_child(jednoraz)
	var wynik_lbl = h._ui._napis_ekranu(str(h._swiat.get("ostatnie_kieszonkowe_tekst", "")), 15)
	wynik_lbl.name = "WynikKieszonkowego"
	wynik_lbl.visible = str(h._swiat.get("ostatnie_kieszonkowe_tekst", "")) != ""
	h._ui._tresc_biala().add_child(wynik_lbl)


## Nagłówek zwija wiersze. Domyślnie zwinięte. Ludzie zostają w drzewie, tylko hidden.
func _dodaj_sekcje_zwijana(id_sekcji: String, tytul: String) -> VBoxContainer:
	var naglowek := Button.new()
	naglowek.text = "%s ▸" % tytul
	naglowek.alignment = HORIZONTAL_ALIGNMENT_LEFT
	naglowek.custom_minimum_size = Vector2(0, 48)
	naglowek.add_theme_font_size_override("font_size", 18)
	naglowek.set_meta("sekcja_rodziny", id_sekcji)
	naglowek.focus_mode = Control.FOCUS_NONE
	var pudelko := VBoxContainer.new()
	pudelko.visible = false
	pudelko.set_meta("tresc_sekcji", id_sekcji)
	pudelko.add_theme_constant_override("separation", 6)
	pudelko.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	naglowek.pressed.connect(func() -> void:
		pudelko.visible = not pudelko.visible
		naglowek.text = ("%s ▾" % tytul) if pudelko.visible else ("%s ▸" % tytul)
	)
	h._ui._tresc_biala().add_child(naglowek)
	h._ui._tresc_biala().add_child(pudelko)
	return pudelko


func _wypelnij_dziadkow(pudelko: VBoxContainer, blok: Variant) -> void:
	if not (blok is Dictionary):
		pudelko.add_child(h._ui._napis_ekranu("Brak w zapisie (Start jeszcze raz).", 16))
		return
	var lista: Variant = blok.get("lista", [])
	if not (lista is Array) or lista.is_empty():
		pudelko.add_child(h._ui._napis_ekranu("Brak żyjących dziadków w wylosowanym zestawie.", 16))
		return
	for o in lista:
		if not (o is Dictionary):
			continue
		pudelko.add_child(h._ui._napis_ekranu(_etykieta_roli_dziadka(str(o.get("rola", ""))), 16))
		pudelko.add_child(h._ui._napis_ekranu(_opis_rodzica(o), 15))


func _etykieta_roli_dziadka(rola: String) -> String:
	match rola:
		"babcia_matki":
			return "Babcia (linia matki)"
		"dziadek_matki":
			return "Dziadek (linia matki)"
		"babcia_ojca":
			return "Babcia (linia ojca)"
		"dziadek_ojca":
			return "Dziadek (linia ojca)"
		_:
			return "Dziadek / babcia" if rola == "" else rola


func _opis_rodzica(osoba: Variant) -> String:
	if not (osoba is Dictionary) or osoba.is_empty():
		return "Brak w zapisie (stary save? Start jeszcze raz)."
	var czesci: PackedStringArray = []
	var imie := ""
	if osoba.get("imie") is Dictionary:
		imie = str(osoba["imie"].get("nazwa", ""))
	if imie != "":
		czesci.append(imie)
	else:
		czesci.append("imię: —")
	var cechy := _cechy_listy(osoba.get("charakter"))
	czesci.append("cechy: %s" % (cechy if cechy != "" else "—"))
	var praca := ""
	if osoba.get("praca") is Dictionary and bool(osoba["praca"].get("kolo", false)):
		# UI: konkretny zawód (2-digit), nie sama grupa ISCO.
		if osoba["praca"].get("zawod") != null and str(osoba["praca"]["zawod"]) != "":
			praca = str(osoba["praca"]["zawod"])
		else:
			praca = str(osoba["praca"].get("nazwa", ""))
		var grupa_n := str(osoba["praca"].get("grupa_nazwa", ""))
		if grupa_n != "" and grupa_n != praca:
			praca += " (%s)" % grupa_n
	elif osoba.get("praca") is Dictionary:
		var powod_p := str(osoba["praca"].get("powod", ""))
		praca = "brak wag" + ((" — " + powod_p) if powod_p != "" else "")
	czesci.append("praca: %s" % (praca if praca != "" else "—"))
	var zar_os := _tekst_zarobkow(osoba.get("zarobki"))
	if zar_os == "" and osoba.get("zarobki") is Dictionary:
		var powod_z := str(osoba["zarobki"].get("powod", "")).strip_edges()
		czesci.append("zarobki: —%s" % ((" (%s)" % powod_z) if powod_z != "" else ""))
	else:
		var z_grupy := ""
		if osoba.get("zarobki") is Dictionary:
			z_grupy = str(osoba["zarobki"].get("zarobki_z", ""))
		if zar_os != "":
			czesci.append("zarobki: %s%s" % [zar_os, (" [%s]" % z_grupy) if z_grupy != "" else ""])
		else:
			czesci.append("zarobki: —")
	return " · ".join(czesci)


func _ekran_lista_osob(klucz: String, pusto: String) -> void:
	var lista: Variant = h._swiat.get(klucz, [])
	if not (lista is Array) or lista.is_empty():
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(pusto, 16))
		return
	var nr := 1
	for osoba in lista:
		if not (osoba is Dictionary):
			continue
		var cechy := _cechy_listy_z_karty(osoba)
		var plec = h._ui._nazwa_pola(osoba.get("plec"))
		var linia := "%d. %s" % [nr, plec if plec != "" else "osoba"]
		if cechy != "":
			linia += " — %s" % cechy
		h._ui._tresc_biala().add_child(h._ui._napis_ekranu(linia, 16))
		nr += 1


func _opis_rodzenstwa(osoba: Dictionary, nr: int) -> String:
	var etykieta := str(osoba.get("etykieta", ""))
	if etykieta == "":
		var imie_txt := ""
		if osoba.get("imie") is Dictionary:
			imie_txt = str(osoba["imie"].get("nazwa", ""))
		var plec_id := ""
		if osoba.get("plec") is Dictionary:
			plec_id = str(osoba["plec"].get("id", ""))
		if imie_txt != "":
			etykieta = "%s (%s)" % [imie_txt, "siostra" if plec_id == "kobieta" else "brat"]
		else:
			etykieta = "Siostra %d" % nr if plec_id == "kobieta" else "Brat %d" % nr
	var cechy := _cechy_listy_z_karty(osoba)
	if cechy != "":
		return "%s — %s" % [etykieta, cechy]
	return etykieta


func _cechy_listy(lista: Variant) -> String:
	if not (lista is Array):
		return ""
	var nazwy: PackedStringArray = []
	for pozycja in lista:
		var nazwa = h._ui._nazwa_pola(pozycja)
		if nazwa == "" and pozycja is String:
			nazwa = str(pozycja)
		if nazwa != "":
			nazwy.append(nazwa)
	return ", ".join(nazwy)


func _cechy_listy_z_karty(karta: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while karta.has("cecha_%d" % numer):
		var nazwa = h._ui._nazwa_pola(karta["cecha_%d" % numer])
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _opis_sylwetki(bohater: Dictionary) -> String:
	var blok: Variant = bohater.get("sylwetka", {})
	if not (blok is Dictionary):
		return ""
	var syl := Sylwetka.new()
	syl.z_zapisu(blok)
	return syl.tekst_stanu()


func _opis_zainteresowania(bohater: Dictionary) -> String:
	var z: Variant = bohater.get("zainteresowanie", {})
	if not (z is Dictionary):
		return ""
	var nazwa := str(z.get("nazwa", ""))
	if nazwa == "":
		return ""
	return "Zainteresowanie (dominujące): %s" % nazwa


func _opis_dziadkow(blok: Variant) -> String:
	if not (blok is Dictionary):
		return "Brak w zapisie (Start jeszcze raz)."
	var lista: Variant = blok.get("lista", [])
	if not (lista is Array) or lista.is_empty():
		return "Brak żyjących dziadków w wylosowanym zestawie."
	var linie: PackedStringArray = []
	for o in lista:
		if not (o is Dictionary):
			continue
		linie.append(_opis_rodzica(o))
	return "\n".join(linie)


func _on_kieszonkowe_dziadkowie() -> void:
	if h._swiat.is_empty():
		return
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return
	var stan_d: Dictionary = {}
	if rodzina.get("dziadkowie") is Dictionary:
		stan_d = rodzina["dziadkowie"]
	if stan_d.get("lista") is Array and (stan_d["lista"] as Array).is_empty():
		h._swiat["ostatnie_kieszonkowe_dziadkowie_tekst"] = "Nie masz dziadków w zapisie."
		h._zaplanuj_stos()
		return
	var dziad := Dziadkowie.new()
	var inteligencja := 1
	var boh = h._stan._bohater()
	if boh.get("inteligencja") is Array and not (boh["inteligencja"] as Array).is_empty():
		inteligencja = 2
	elif h._ui._jest_liczba(boh.get("inteligencja")):
		inteligencja = clampi(int(boh["inteligencja"]) / 33, 0, 3)
	var wynik: Dictionary = dziad.popros_o_kieszonkowe(
		stan_d, rodzina, inteligencja, int(h._swiat.get("tydzien", 0)), false
	)
	rodzina["dziadkowie"] = stan_d
	h._swiat["rodzina"] = rodzina
	h._swiat["ostatnie_kieszonkowe_dziadkowie_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and h._ui._jest_liczba(wynik.get("kwota")):
		h._stan._dodaj_pieniadze(int(wynik["kwota"]))
		h._stan._dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	h.SkryptZapisu.zapisz(h._swiat)
	h._pasek._odswiez_pasek_statystyk(true)
	h._zaplanuj_stos()


func _wyplata_kieszonkowego_dziadkow_tydzien() -> void:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary) or not (rodzina.get("dziadkowie") is Dictionary):
		return
	var stan_d: Dictionary = rodzina["dziadkowie"]
	var dziad := Dziadkowie.new()
	var wynik: Dictionary = dziad.wyplata_tygodniowa(stan_d, int(h._swiat.get("tydzien", 0)))
	rodzina["dziadkowie"] = stan_d
	h._swiat["rodzina"] = rodzina
	if bool(wynik.get("ok", false)) and h._ui._jest_liczba(wynik.get("kwota")):
		h._stan._dodaj_pieniadze(int(wynik["kwota"]))
		h._stan._dodaj_wplyw("kieszonkowe_dziadkowie", int(wynik["kwota"]), str(wynik.get("tekst", "")))
		var kom := str(h._swiat.get("komunikat_tury", ""))
		var dopisek := str(wynik.get("tekst", ""))
		h._swiat["komunikat_tury"] = (kom + "\n" + dopisek).strip_edges() if kom != "" else dopisek


func _on_kieszonkowe() -> void:
	if h._swiat.is_empty():
		return
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var pierwsza := bool(h._swiat.get("kieszonkowe_pierwsza_rozmowa", true))
	var tryb_teraz := str(h._swiat.get("tryb_kieszonkowego", ""))
	var wynik: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, tryb_teraz, pierwsza, h._stan._wiek_lat())
	h._swiat["kieszonkowe_pierwsza_rozmowa"] = false
	h._swiat["ostatnie_kieszonkowe"] = wynik
	h._swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and h._ui._jest_liczba(wynik.get("kwota")):
		h._stan._dodaj_pieniadze(int(wynik["kwota"]))
		h._stan._dodaj_wplyw("kieszonkowe", int(wynik["kwota"]), str(wynik.get("tekst", "")))
		h._swiat["tryb_kieszonkowego"] = "stala_kwota"
		h._swiat["kieszonkowe_aktywne"] = true
		h._swiat["kieszonkowe_kwota_zl"] = int(wynik["kwota"])
		h._swiat["kieszonkowe_ostatnia_wyplata_tydzien"] = int(h._swiat.get("tydzien", 0))
	elif str(wynik.get("powod", "")) == "wiek_ponizej_progu" or str(wynik.get("tryb", "")) == "odmowa":
		if str(wynik.get("tryb", "")) == "odmowa":
			h._swiat["tryb_kieszonkowego"] = "odmowa"
	h._swiat["jedzenie"] = h._jedzenie.zrzut_zapisu()
	h.SkryptZapisu.zapisz(h._swiat)
	h._pasek._odswiez_pasek_statystyk(true)
	h._zaplanuj_stos()


func _on_kieszonkowe_podwyzka() -> void:
	if h._swiat.is_empty() or not bool(h._swiat.get("kieszonkowe_aktywne", false)):
		return
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.popros_o_podwyzke_kieszonkowego(
		rodzina, h._swiat.get("kieszonkowe_kwota_zl", null), h._stan._wiek_lat()
	)
	h._swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("ok", false)) and h._ui._jest_liczba(wynik.get("kwota")):
		h._swiat["kieszonkowe_kwota_zl"] = int(wynik["kwota"])
	h._swiat["jedzenie"] = h._jedzenie.zrzut_zapisu()
	h.SkryptZapisu.zapisz(h._swiat)
	h._zaplanuj_stos()


func _on_pieniadze_jednorazowo() -> void:
	if h._swiat.is_empty():
		return
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		rodzina = {}
	var ziarno := ZiarnoRodzicow.new()
	var wynik: Dictionary = ziarno.popros_o_pieniadze_jednorazowo(rodzina, h._stan._wiek_lat())
	h._swiat["ostatnie_kieszonkowe_tekst"] = str(wynik.get("tekst", ""))
	if bool(wynik.get("dodano", false)) and h._ui._jest_liczba(wynik.get("kwota")):
		h._stan._dodaj_pieniadze(int(wynik["kwota"]))
		h._stan._dodaj_wplyw("pieniadze_jednorazowo", int(wynik["kwota"]), str(wynik.get("tekst", "")))
	h._swiat["jedzenie"] = h._jedzenie.zrzut_zapisu()
	h.SkryptZapisu.zapisz(h._swiat)
	h._pasek._odswiez_pasek_statystyk(true)
	h._zaplanuj_stos()


func _opis_urodzenia() -> String:
	var nazwa := str(h._swiat.get("nazwa_urodzenia", ""))
	var typ := str(h._swiat.get("typ_urodzenia", ""))
	if nazwa == "":
		return ""
	if typ == "miasto":
		return "%s, miasto" % nazwa
	if typ != "":
		return "%s, reszta powiatu" % nazwa
	return nazwa


func _tekst_pracy() -> String:
	var rodzina: Variant = h._swiat.get("rodzina", {})
	if not (rodzina is Dictionary):
		return ""
	var czesci: PackedStringArray = []
	for rola in ["matka", "ojciec"]:
		var osoba: Variant = rodzina.get(rola)
		if not (osoba is Dictionary):
			continue
		var praca: Variant = osoba.get("praca", {})
		if praca is Dictionary and praca.get("kolo") == true and str(praca.get("nazwa", "")) != "":
			czesci.append("%s: %s" % [rola.capitalize(), str(praca.get("nazwa"))])
	if not czesci.is_empty():
		return "; ".join(czesci)
	var praca_stara: Variant = rodzina.get("praca", {})
	if praca_stara is Dictionary and praca_stara.get("kolo") == true and str(praca_stara.get("nazwa", "")) != "":
		return str(praca_stara.get("nazwa"))
	return ""


func _tekst_zarobkow(blok: Variant) -> String:
	return h.ZaokraglenieZarobkow.tekst(blok)


func _cechy_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("cecha_%d" % numer):
		var nazwa = h._ui._nazwa_pola(bohater["cecha_%d" % numer])
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)


func _inteligencje_bohatera(bohater: Dictionary) -> String:
	var nazwy: PackedStringArray = []
	var numer := 1
	while bohater.has("inteligencja_%d" % numer):
		var pozycja: Variant = bohater["inteligencja_%d" % numer]
		var nazwa = h._ui._nazwa_pola(pozycja)
		if nazwa != "" and pozycja is Dictionary and h._ui._jest_liczba(pozycja.get("wartosc")):
			nazwa = "%s %s" % [nazwa, str(int(pozycja["wartosc"]))]
		if nazwa != "":
			nazwy.append(nazwa)
		numer += 1
	return ", ".join(nazwy)
