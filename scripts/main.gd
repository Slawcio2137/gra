extends Control

var _losowanie: Losowanie
var _tryb := ""
var _wybrane_id := ""
var _kontynent := ""
var _kraj := ""
var _kraj_sesja := false
var _grupa: ButtonGroup


func _ready() -> void:
	_losowanie = Losowanie.new()
	_grupa = ButtonGroup.new()
	for przycisk in [$BirthPanel/ButtonTrybSam, $BirthPanel/ButtonTrybKontynent, $BirthPanel/ButtonTrybSwiat]:
		przycisk.button_group = _grupa
	$BirthPanel/ButtonTrybSam.pressed.connect(_on_tryb_sam)
	$BirthPanel/ButtonTrybKontynent.pressed.connect(_on_tryb_kontynent)
	$BirthPanel/ButtonTrybSwiat.pressed.connect(_on_tryb_kraj)
	$BirthPanel/ButtonReklama.pressed.connect(_on_reklama)
	$BirthPanel/CityFilter.text_changed.connect(_on_filtr_miast)
	$BirthPanel/CityList.item_selected.connect(_on_miasto_wybrane)
	$BirthPanel/ContinentPick.item_selected.connect(_on_kontynent_wybrany)
	$BirthPanel/CountryPick.item_selected.connect(_on_kraj_wybrany)
	_zastosuj_bramki()


func _on_start_pressed() -> void:
	if _tryb == "wybor_miejsca" or _tryb == "sam":
		$GameRoot/StatusLabel.text = "Wybór miejsca jest premium i zostaje zablokowany. Sklepu nie ma."
	elif _tryb == "kraj" and not _kraj_sesja:
		$GameRoot/StatusLabel.text = "Kraj jest za bramką. Przycisk Reklama tylko otwiera kraj na tę sesję."
	elif _tryb != "":
		var wynik := _losowanie.losuj_postac(_tryb, _argument_trybu())
		_losowanie.zapisz(wynik)
		var rodzenstwo := _losowanie.losuj_rodzenstwo(wynik)
		_losowanie.zapisz_rodzenstwo(rodzenstwo)
		$GameRoot/StatusLabel.text = _tekst_wyniku(wynik, rodzenstwo)
	else:
		$GameRoot/StatusLabel.text = "Gra wystartowała. Miejsce urodzenia nie zostało wylosowane, bo nie wybrano sposobu."
	$StartButton.hide()
	$BirthPanel.hide()
	$GameRoot.show()


func _on_action_pressed() -> void:
	$GameRoot/StatusLabel.text = "Akcja wykonana. (Na razie test kliknięcia.)"


func _on_options_pressed() -> void:
	$GameRoot/OptionsPanel.visible = not $GameRoot/OptionsPanel.visible


func _on_tryb_sam() -> void:
	$BirthPanel/ButtonTrybSam.button_pressed = false
	_tryb = ""
	_schowaj_dodatki()
	$BirthPanel/BirthHint.text = "Wybór miejsca jest premium i zostaje zablokowany. Sklepu nie ma."


func _on_reklama() -> void:
	_kraj_sesja = true
	$BirthPanel/ButtonTrybSwiat.disabled = false
	$BirthPanel/ButtonReklama.disabled = true
	$BirthPanel/ButtonReklama.text = "Kraj otwarty na tę sesję"
	$BirthPanel/BirthHint.text = "Kraj odblokowany na tę sesję. To bramka, nie reklama. Wybierz kraj, potem Start."


func _on_tryb_kontynent() -> void:
	if not $BirthPanel/ButtonTrybKontynent.button_pressed:
		_tryb = ""
		_schowaj_dodatki()
		return
	_tryb = "kontynent"
	_schowaj_dodatki()
	_wypelnij_kontynenty()
	$BirthPanel/ContinentPick.show()
	_odswiez_hint_kontynentu()


func _on_tryb_kraj() -> void:
	if not _kraj_sesja or not $BirthPanel/ButtonTrybSwiat.button_pressed:
		if not _kraj_sesja:
			$BirthPanel/ButtonTrybSwiat.button_pressed = false
		_tryb = ""
		_schowaj_dodatki()
		return
	_tryb = "kraj"
	_schowaj_dodatki()
	_wypelnij_kraje()
	$BirthPanel/CountryPick.show()
	$BirthPanel/BirthHint.text = "Koło kraju to miejsca z liczbą mieszkańców. Dziś ludność jest przy Polsce. Kraj bez ludności zostawia puste koło."


func _on_filtr_miast(tekst: String) -> void:
	_wybrane_id = ""
	_wypelnij_miasta(tekst)


func _on_miasto_wybrane(indeks: int) -> void:
	if indeks < 0:
		return
	_wybrane_id = str($BirthPanel/CityList.get_item_metadata(indeks))


func _on_kontynent_wybrany(indeks: int) -> void:
	_kontynent = str($BirthPanel/ContinentPick.get_item_metadata(indeks))
	_odswiez_hint_kontynentu()


func _on_kraj_wybrany(indeks: int) -> void:
	_kraj = str($BirthPanel/CountryPick.get_item_metadata(indeks))


func _argument_trybu() -> String:
	if _tryb == "sam" or _tryb == "wybor_miejsca":
		var wpisane := $BirthPanel/CityFilter.text.strip_edges()
		if _wybrane_id != "":
			return _wybrane_id
		return wpisane
	if _tryb == "kontynent":
		return _kontynent
	if _tryb == "kraj":
		return _kraj
	return ""


func _schowaj_dodatki() -> void:
	$BirthPanel/CityFilter.hide()
	$BirthPanel/CityList.hide()
	$BirthPanel/ContinentPick.hide()
	$BirthPanel/CountryPick.hide()


func _zastosuj_bramki() -> void:
	$BirthPanel/ButtonTrybSam.disabled = true
	$BirthPanel/ButtonTrybSam.text = "Wybór miejsca"
	$BirthPanel/ButtonTrybSwiat.disabled = true
	$BirthPanel/ButtonTrybSwiat.text = "Kraj"
	for tryb in _losowanie.tryby_urodzenia():
		if not (tryb is Dictionary):
			continue
		var id := str(tryb.get("id", ""))
		var napis := str(tryb.get("przycisk", ""))
		if id == "kontynent" and napis != "":
			$BirthPanel/ButtonTrybKontynent.text = napis
		elif id == "kraj" and napis != "":
			$BirthPanel/ButtonTrybSwiat.text = napis
		elif id == "wybor_miejsca" and napis != "":
			$BirthPanel/ButtonTrybSam.text = napis
	$BirthPanel/BirthHint.text = "Darmowy jest kontynent. Kraj otwiera przycisk Reklama na tę sesję, bez prawdziwej reklamy. Wybór miejsca jest premium i zostaje zablokowany, bez sklepu."


func _wypelnij_miasta(filtr: String) -> void:
	var lista: ItemList = $BirthPanel/CityList
	lista.clear()
	var szukane := filtr.strip_edges().to_lower()
	for miejsce in _losowanie.miasta_polski():
		var nazwa := str(miejsce["nazwa"])
		var id := str(miejsce["id"])
		var linia := "%s (%s)" % [nazwa, id]
		if szukane != "" and not linia.to_lower().contains(szukane):
			continue
		var indeks := lista.add_item(linia)
		lista.set_item_metadata(indeks, id)


func _wypelnij_kontynenty() -> void:
	var wybor: OptionButton = $BirthPanel/ContinentPick
	if wybor.item_count > 0:
		return
	wybor.add_item("Wybierz kontynent")
	wybor.set_item_metadata(0, "")
	var indeks := 1
	for kontynent in _losowanie.kontynenty():
		wybor.add_item(str(kontynent.get("nazwa", "")))
		wybor.set_item_metadata(indeks, str(kontynent.get("id", "")))
		indeks += 1


func _wypelnij_kraje() -> void:
	var wybor: OptionButton = $BirthPanel/CountryPick
	if wybor.item_count > 0:
		return
	wybor.add_item("Wybierz kraj")
	wybor.set_item_metadata(0, "")
	var indeks := 1
	for panstwo in _losowanie.panstwa():
		wybor.add_item(str(panstwo.get("nazwa", "")))
		wybor.set_item_metadata(indeks, str(panstwo.get("id", "")))
		indeks += 1


func _odswiez_hint_kontynentu() -> void:
	if _kontynent == "":
		$BirthPanel/BirthHint.text = "Wybierz kontynent. Poza Europą koło jest puste, dopóki nie ma ludności."
		return
	for kontynent in _losowanie.kontynenty():
		if str(kontynent.get("id", "")) == _kontynent:
			$BirthPanel/BirthHint.text = str(kontynent.get("powod", ""))
			return


func _tekst_wyniku(wynik: Dictionary, rodzenstwo: Array) -> String:
	var miejsce: Variant = wynik.get("miejsce", {})
	if not (miejsce is Dictionary) or miejsce.get("id") == null:
		var powod := "Miejsce nie zostało wylosowane."
		if miejsce is Dictionary and miejsce.get("powod") != null:
			powod = str(miejsce["powod"])
		return powod
	var cechy := _sloty(wynik, "cecha")
	var inteligencje := _sloty(wynik, "inteligencja")
	var choroby := _nazwy(wynik.get("choroby_wypadly"))
	return "Urodzenie: %s, %s, ludność %s. Płeć: %s. Cechy: %s. Inteligencje: %s. Choroby: %s. Zarobki rodziny: puste. Rodzeństwo: %d." % [
		miejsce.get("nazwa"),
		miejsce.get("typ"),
		miejsce.get("ludnosc"),
		_nazwa_pola(wynik.get("plec")),
		cechy,
		inteligencje,
		choroby,
		rodzenstwo.size(),
	]


func _sloty(wynik: Dictionary, przedrostek: String) -> String:
	var lista: Array = []
	var numer := 1
	while wynik.has("%s_%d" % [przedrostek, numer]):
		var pozycja: Variant = wynik["%s_%d" % [przedrostek, numer]]
		if pozycja is Dictionary and str(pozycja.get("nazwa", "")) != "":
			lista.append(pozycja)
		numer += 1
	return _nazwy(lista)


func _nazwa_pola(pozycja: Variant) -> String:
	if pozycja is Dictionary:
		return str(pozycja.get("nazwa", "brak"))
	return "brak"


func _nazwy(lista: Variant) -> String:
	if not (lista is Array) or lista.is_empty():
		return "brak"
	var nazwy: PackedStringArray = []
	for pozycja in lista:
		if pozycja is Dictionary:
			nazwy.append(str(pozycja.get("nazwa", "")))
	return ", ".join(nazwy)


func _choroby(lista: Variant) -> String:
	if not (lista is Array):
		return "brak koła"
	var trafione: PackedStringArray = []
	for pozycja in lista:
		if pozycja is Dictionary and str(pozycja.get("wynik", "")) == "ma":
			trafione.append(str(pozycja.get("nazwa", "")))
	if trafione.is_empty():
		return "żadna nie wypadła tam, gdzie było koło"
	return ", ".join(trafione)
