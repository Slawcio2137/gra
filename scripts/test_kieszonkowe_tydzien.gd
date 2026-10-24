extends SceneTree

## Headless: wiek 2–4; kieszonkowe nie płaci przed prośbą; po prośbie (wiek≥próg) płaci; zawód ≠ sama grupa.
## godot --headless --path . --script res://scripts/test_kieszonkowe_tydzien.gd

const LosowanieSkrypt = preload("res://scripts/losowanie.gd")
const ZiarnoSkrypt = preload("res://scripts/ziarno_rodzicow.gd")


func _init() -> void:
	quit(_uruchom())


func _uruchom() -> int:
	var los = LosowanieSkrypt.new()
	var ziarno = ZiarnoSkrypt.new()
	var bohater: Dictionary = los.losuj_postac("kraj", "polska")
	if not bool(bohater.get("wylosowano", false)):
		printerr("FAIL: bohater")
		return 1
	bohater["pieniadze"] = 0
	var wiek_start := randi_range(2, 4)
	bohater["wiek"] = wiek_start
	print("wiek_start=", wiek_start)

	var rodzina: Dictionary = ziarno.losuj(los, bohater.get("miejsce"))
	rodzina["charakter"] = [{"id": "hojny", "nazwa": "Hojny"}]
	rodzina["matka"] = rodzina.get("matka", {})
	if not (rodzina["matka"] is Dictionary):
		rodzina["matka"] = {}
	rodzina["matka"]["charakter"] = [{"id": "hojny", "nazwa": "Hojny"}]

	# Zawód konkretny (nie sama grupa ISCO 1-digit).
	for rola in ["matka", "ojciec"]:
		var os: Variant = rodzina.get(rola, {})
		if not (os is Dictionary) or not (os.get("praca") is Dictionary):
			continue
		var praca: Dictionary = os["praca"]
		if not bool(praca.get("kolo", false)):
			printerr("FAIL: brak kola zawodu ", rola)
			return 1
		var nazwa := str(praca.get("nazwa", ""))
		var grupa := str(praca.get("grupa_nazwa", ""))
		var isco := str(praca.get("isco08", ""))
		print(rola, " zawod=", nazwa, " grupa=", grupa, " isco=", isco)
		if isco.length() == 3 and isco.begins_with("OC") and praca.get("zawod") == null:
			# OC5 itp. — za mało konkretne gdy brak zagnieżdżenia
			printerr("FAIL: zawod to sama grupa 1-digit ", isco)
			return 1
		if nazwa == grupa and isco.length() <= 3:
			printerr("FAIL: UI nazwa == sama grupa ISCO ", nazwa)
			return 1
		var zar: Variant = os.get("zarobki", {})
		if not (zar is Dictionary) or not bool(zar.get("kolo", false)):
			printerr("FAIL: brak zarobkow przy zawodzie ", rola)
			return 1
		if not str(zar.get("zarobki_z", "")).begins_with("grupa_OC"):
			printerr("FAIL: zarobki nie zmapowane na grupę ", zar)
			return 1
		print(rola, " zarobki_z=", zar.get("zarobki_z"), " mediana=", zar.get("mediana_zl"))

	# Przed prośbą: nawet stala_kwota + aktywne=false → nie płaci.
	var przed: Dictionary = ziarno.wyplata_tygodniowa_kieszonkowego(rodzina, "stala_kwota", false, null, 10)
	if bool(przed.get("dodano", false)):
		printerr("FAIL: nie powinno placic przed prosba")
		return 1

	# Wiek poniżej progu (5): odmowa „za małe”.
	var za_male: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, "", true, wiek_start)
	if bool(za_male.get("dodano", false)):
		printerr("FAIL: przy wieku ", wiek_start, " nie powinno dac kieszonkowego")
		return 1
	if str(za_male.get("powod", "")) != "wiek_ponizej_progu":
		printerr("FAIL: oczekiwano wiek_ponizej_progu, jest ", za_male)
		return 1
	print("OK za_male tekst=", za_male.get("tekst", ""))

	# Wiek ≥ próg: udana prośba → aktywacja.
	var prosba: Dictionary = ziarno.popros_o_kieszonkowe(rodzina, "", true, 10)
	if not bool(prosba.get("dodano", false)) or not (prosba.get("kwota") is int or prosba.get("kwota") is float):
		printerr("FAIL: prosba wieku 10 ", prosba)
		return 1
	if not bool(prosba.get("aktywuj_stale", false)):
		printerr("FAIL: brak aktywuj_stale")
		return 1
	var kwota := int(prosba["kwota"])
	var pieniadze := kwota
	print("prosba +", kwota, " tekst=", prosba.get("tekst", ""))
	# Snap: tylko dozwolone kwoty, bez 35.
	var snap35: int = ziarno._snap_kwoty_kieszonkowej(null, 35)
	if snap35 == 35:
		printerr("FAIL: 35 nadal na liscie po snap")
		return 1
	var lista: Array = ziarno._lista_dozwolonych_kwot(null)
	if lista.has(35):
		printerr("FAIL: lista zawiera 35")
		return 1
	if not lista.has(kwota):
		printerr("FAIL: kwota ", kwota, " poza dozwolonymi")
		return 1
	print("OK snap 35 -> ", snap35, " kwota_proby=", kwota)

	# Po prośbie: 3 tury płacą.
	var tur := 3
	for i in tur:
		var w: Dictionary = ziarno.wyplata_tygodniowa_kieszonkowego(rodzina, "stala_kwota", true, kwota, 10)
		if not bool(w.get("dodano", false)):
			printerr("FAIL: brak wyplaty tury ", i, " ", w)
			return 1
		pieniadze += int(w["kwota"])
		print("tura=", i + 1, " +", int(w["kwota"]), " suma=", pieniadze, " wplyw=", w.get("tekst", ""))

	if pieniadze != kwota * (1 + tur):
		printerr("FAIL: suma ", pieniadze, " != ", kwota * (1 + tur))
		return 1

	# Jednorazowo osobno.
	var jed: Dictionary = ziarno.popros_o_pieniadze_jednorazowo(rodzina, 10)
	if not bool(jed.get("dodano", false)):
		printerr("FAIL: jednorazowo ", jed)
		return 1
	print("OK jednorazowo=", jed.get("kwota"), " ", jed.get("tekst", ""))

	print("OK wiek_start=", wiek_start, " kwota=", kwota, " po_turach=", pieniadze)
	return 0
