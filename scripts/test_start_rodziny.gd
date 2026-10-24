extends SceneTree

## Headless: Start → rodzice + rodzeństwo w strukturze; prośba o kieszonkowe → tekst.
## godot --headless --path . --script res://scripts/test_start_rodziny.gd

const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const ZiarnoSkrypt = preload("res://scripts/ziarno_rodzicow.gd")
const ZapisSkrypt = preload("res://scripts/zapis_swiata.gd")


func _init() -> void:
	var kod := _uruchom()
	quit(kod)


func _uruchom() -> int:
	var los = LosowanieSkrypt.new()
	var bohater: Dictionary = los.losuj_postac("kraj", "polska")
	if not bool(bohater.get("wylosowano", false)):
		printerr("FAIL: bohater nie wylosowany: ", bohater.get("miejsce"))
		return 1
	if bohater.get("cecha_1") == null:
		printerr("FAIL: brak cechy_1")
		return 1
	var ziarno = ZiarnoSkrypt.new()
	var rodzina: Dictionary = ziarno.losuj(los, bohater.get("miejsce"))
	if not (rodzina.get("zarobki") is Dictionary):
		printerr("FAIL: brak zarobkow w rodzinie")
		return 1
	for rola in ["matka", "ojciec"]:
		var os: Variant = rodzina.get(rola, {})
		if not (os is Dictionary) or not (os.get("praca") is Dictionary) or not bool(os["praca"].get("kolo", false)):
			printerr("FAIL: brak zawodu ", rola)
			return 1
		if not (os.get("zarobki") is Dictionary) or not bool(os["zarobki"].get("kolo", false)):
			printerr("FAIL: brak zarobkow powiązanych z zawodem ", rola, " ", os.get("zarobki"))
			return 1
		var zz := str(os["zarobki"].get("zarobki_z", ""))
		if not zz.begins_with("grupa_OC"):
			printerr("FAIL: zarobki_z nie z grupy ISCO ", rola, " ", zz)
			return 1
		print(rola, " zawod=", os["praca"].get("nazwa"), " zarobki_z=", zz, " od=", os["zarobki"].get("od_zl"), " do=", os["zarobki"].get("do_zl"))
	if str(rodzina["zarobki"].get("dochód_gospodarstwa", "")) != "suma_przedzialow_rodzicow":
		printerr("FAIL: dochód gospodarstwa nie jest sumą rodziców: ", rodzina["zarobki"])
		return 1
	if not (rodzina.get("charakter") is Array) or rodzina["charakter"].is_empty():
		printerr("FAIL: brak charakteru rodzicow")
		return 1
	var rodzenstwo: Array = los.losuj_rodzenstwo(bohater)
	if rodzenstwo.size() < 0 or rodzenstwo.size() > 3:
		printerr("FAIL: zla liczba rodzenstwa ", rodzenstwo.size())
		return 1
	for osoba in rodzenstwo:
		if not (osoba is Dictionary):
			printerr("FAIL: rodzenstwo nie-dict")
			return 1
		if str(osoba.get("etykieta", "")) == "":
			printerr("FAIL: brak etykiety rodzenstwa")
			return 1
	var swiat := {
		"bohater": bohater,
		"rodzina": rodzina,
		"rodzenstwo": rodzenstwo,
		"przyjaciele": [],
		"znajomi": [],
	}
	if not ZapisSkrypt.zapisz(swiat):
		printerr("FAIL: zapis")
		return 1
	var wczytane: Variant = ZapisSkrypt.wczytaj()
	if not (wczytane is Dictionary):
		printerr("FAIL: odczyt zapisu")
		return 1
	if not (wczytane.get("rodzina") is Dictionary):
		printerr("FAIL: w zapisie brak rodziny")
		return 1
	if not (wczytane.get("przyjaciele") is Array) or not (wczytane.get("znajomi") is Array):
		printerr("FAIL: brak list przyjaciele/znajomi")
		return 1
	var tryb := ziarno.tryb_domyslny_kieszonkowego(rodzina)
	if tryb != "odmowa" and tryb != "na_prosbe" and tryb != "stala_kwota":
		printerr("FAIL: zly tryb kieszonkowego ", tryb)
		return 1
	var kiesz: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, "", true)
	var tekst := str(kiesz.get("tekst", ""))
	if tekst.strip_edges() == "":
		printerr("FAIL: pusty tekst kieszonkowego")
		return 1
	if str(kiesz.get("tryb", "")) == "":
		printerr("FAIL: brak trybu w wyniku prośby")
		return 1
	print("OK bohater miejsce=", bohater.get("miejsce", {}).get("nazwa", "?"))
	print("OK rodzenstwo=", rodzenstwo.size())
	print("OK charakter=", rodzina["charakter"])
	print("OK zarobki kolo=", rodzina["zarobki"].get("kolo"), " zarobki_z=", rodzina["zarobki"].get("zarobki_z"), " od=", rodzina["zarobki"].get("od_zl"), " do=", rodzina["zarobki"].get("do_zl"))
	print("OK tryb_kiesz=", tryb, " etykieta=", ziarno.etykieta_trybu_kieszonkowego(tryb))
	print("OK kieszonkowe: ", tekst)
	return 0
