extends RefCounted
class_name EkranAdmina

const SkryptDostepu = preload("res://scripts/dostep_admina.gd")

var h


func _init(host) -> void:
	h = host


func _ekran() -> void:
	var box: Control = h._ui._tresc_biala()
	if h._swiat.is_empty() or not (h._swiat.get("bohater") is Dictionary):
		box.add_child(h._ui._napis_ekranu("Najpierw zacznij albo wczytaj grę.", 16))
		return
	box.add_child(h._ui._napis_ekranu("Panel admina. Zmiana zapisuje się od razu.", 16))
	var bohater: Dictionary = h._swiat["bohater"]
	for pole in SkryptDostepu.pola_bohatera(bohater, h._emotikony):
		if not (pole is Dictionary):
			continue
		var klucz_pola := str(pole.get("klucz", ""))
		if klucz_pola == "uczy_sie" or klucz_pola == "studiuje":
			continue
		if str(pole.get("typ", "")) == "bool":
			_dodaj_bool(box, klucz_pola, str(pole.get("nazwa", "")))
		else:
			_dodaj_liczbe(box, pole)
	box.add_child(h._ui._napis_ekranu("Relacje", 18))
	_dodaj_relacje(box)
	box.add_child(h._ui._napis_ekranu("Szkoła", 18))
	_dodaj_bool(box, "uczy_sie", "Uczy się (legitymacja)")
	_dodaj_bool(box, "studiuje", "Studiuje (legitymacja)")
	box.add_child(h._ui._napis_ekranu("Remonty", 18))
	_dodaj_remonty(box)
	box.add_child(h._ui._napis_ekranu("Majątek — ilość", 18))
	_dodaj_ilosci(box)


func _dodaj_liczbe(box: Control, pole: Dictionary) -> void:
	var klucz := str(pole.get("klucz", ""))
	var min_v := int(pole.get("min", 0))
	var max_v := int(pole.get("max", 100))
	box.add_child(h._ui._napis_ekranu(str(pole.get("nazwa", klucz)), 16))
	var suwak := HSlider.new()
	suwak.min_value = min_v
	suwak.max_value = maxi(max_v, min_v + 1)
	suwak.step = 1
	suwak.custom_minimum_size = Vector2(0, 28)
	var teraz := int(pole.get("wartosc", 0))
	suwak.set_value_no_signal(clampi(teraz, min_v, int(suwak.max_value)))
	var pole_txt := LineEdit.new()
	pole_txt.text = str(int(suwak.value))
	pole_txt.custom_minimum_size = Vector2(0, 36)
	suwak.value_changed.connect(func(v: float) -> void:
		pole_txt.text = str(int(v))
		_zapisz_liczbe(klucz, int(v))
	)
	pole_txt.text_submitted.connect(func(t: String) -> void:
		var n := clampi(int(t), min_v, int(suwak.max_value))
		suwak.set_value_no_signal(n)
		pole_txt.text = str(n)
		_zapisz_liczbe(klucz, n)
	)
	box.add_child(suwak)
	box.add_child(pole_txt)


func _dodaj_bool(box: Control, klucz: String, nazwa: String) -> void:
	var przelacznik := CheckButton.new()
	przelacznik.text = nazwa
	var bohater: Dictionary = h._swiat.get("bohater", {}) if h._swiat.get("bohater") is Dictionary else {}
	przelacznik.set_pressed_no_signal(bool(bohater.get(klucz, false)))
	przelacznik.toggled.connect(func(wl: bool) -> void:
		var b: Dictionary = h._swiat.get("bohater", {}) if h._swiat.get("bohater") is Dictionary else {}
		b[klucz] = wl
		h._swiat["bohater"] = b
		_zapisz()
	)
	box.add_child(przelacznik)


func _dodaj_relacje(box: Control) -> void:
	var osoby: Array = h._rynek_zakupow.kandydaci_pomocy_oceny(h._swiat)
	if osoby.is_empty():
		box.add_child(h._ui._napis_ekranu("Brak osób w zapisie.", 14))
		return
	for k in osoby:
		if not (k is Dictionary):
			continue
		var osoba: Dictionary = k.get("osoba", {}) if k.get("osoba") is Dictionary else {}
		var suwak := HSlider.new()
		suwak.min_value = 0
		suwak.max_value = 100
		suwak.step = 1
		suwak.custom_minimum_size = Vector2(0, 28)
		suwak.set_value_no_signal(h._rynek_zakupow._relacja_osoby(osoba))
		box.add_child(h._ui._napis_ekranu(str(k.get("nazwa", "?")), 14))
		suwak.value_changed.connect(_ustaw_relacje.bind(osoba))
		box.add_child(suwak)


func _dodaj_remonty(box: Control) -> void:
	var maj: Dictionary = h._swiat.get("majatek", {}) if h._swiat.get("majatek") is Dictionary else {}
	var lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	var byl := false
	for n in lista:
		if not (n is Dictionary) or not (n.get("remont_trwa") is Dictionary):
			continue
		byl = true
		var trwa: Dictionary = n["remont_trwa"]
		box.add_child(h._ui._napis_ekranu("%s — minęło tygodni" % str(n.get("nazwa", "Lokum")), 14))
		var suwak := HSlider.new()
		suwak.min_value = 0
		suwak.max_value = maxi(1, int(trwa.get("tygodni", 1)))
		suwak.step = 1
		suwak.set_value_no_signal(int(trwa.get("minelo", 0)))
		suwak.value_changed.connect(_ustaw_postep_remontu.bind(trwa))
		box.add_child(suwak)
	if not byl:
		box.add_child(h._ui._napis_ekranu("Żaden remont nie trwa.", 14))


func _dodaj_ilosci(box: Control) -> void:
	var maj: Dictionary = h._swiat.get("majatek", {}) if h._swiat.get("majatek") is Dictionary else {}
	var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if dobra.is_empty():
		box.add_child(h._ui._napis_ekranu("Brak dóbr.", 14))
		return
	for d in dobra:
		if not (d is Dictionary):
			continue
		var suwak := HSlider.new()
		suwak.min_value = 0
		suwak.max_value = 99
		suwak.step = 1
		var ile := int(d.get("ilosc", 1)) if h._ui._jest_liczba(d.get("ilosc")) else 1
		suwak.set_value_no_signal(ile)
		box.add_child(h._ui._napis_ekranu(str(d.get("nazwa", "?")), 14))
		suwak.value_changed.connect(_ustaw_ilosc.bind(d))
		box.add_child(suwak)


func _ustaw_relacje(v: float, osoba: Dictionary) -> void:
	osoba["relacja"] = int(v)
	_zapisz()


func _ustaw_postep_remontu(v: float, trwa: Dictionary) -> void:
	trwa["minelo"] = int(v)
	_zapisz()


func _ustaw_ilosc(v: float, dobro: Dictionary) -> void:
	dobro["ilosc"] = int(v)
	_zapisz()


func _zapisz_liczbe(klucz: String, wartosc: int) -> void:
	var b: Dictionary = h._swiat.get("bohater", {}) if h._swiat.get("bohater") is Dictionary else {}
	b[klucz] = wartosc
	if klucz == "zmeczenie_fizyczne":
		b["zmeczenie"] = wartosc
	h._swiat["bohater"] = b
	_zapisz()


func _zapisz() -> void:
	h.SkryptZapisu.zapisz(h._swiat)
	h._stan._zsynchronizuj_pieniadze_z_bohatera()
	h._pasek._odswiez_pasek_statystyk(false)
