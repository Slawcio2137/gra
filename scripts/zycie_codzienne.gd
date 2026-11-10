extends RefCounted
class_name ZycieCodzienne

## Kradzież, nauka, bójki, lekarz, sprzedaż, pożyczka, koszty po wyprowadzce.
## Liczby są propozycją do poprawki.

const SPECJALIZACJE := {
	"cialo": {"nazwa": "Internista", "cena": 180},
	"zeby": {"nazwa": "Stomatolog", "cena": 250},
	"psychika": {"nazwa": "Psychiatra", "cena": 320},
	"oczy": {"nazwa": "Okulista", "cena": 220},
}


static func kradziez_dostepna(_swiat: Dictionary, _kontekst: String) -> bool:
	## Jedyny haczyk widoczności. Późniejsze warunki dopisuj tutaj.
	return _kontekst == "sklep"


static func sprobuj_krasc(swiat: Dictionary, oferta: Dictionary) -> Dictionary:
	var out := {"ok": false, "tekst": ""}
	if not kradziez_dostepna(swiat, "sklep"):
		out["tekst"] = "Tu się nie da kraść."
		return out
	var boh: Dictionary = _bohater(swiat)
	var wiedza := 0
	if _liczba(boh.get("wiedza_pkt")):
		wiedza = int(boh["wiedza_pkt"])
	var ryzyko := clampf(0.4 - float(wiedza) / 80.0, 0.12, 0.55)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < ryzyko:
		_dodaj_liczbe(boh, "psychika", -6, -50, 100)
		_dodaj_liczbe(boh, "zmeczenie_fizyczne", 8, 0, 100)
		boh["zmeczenie"] = int(boh.get("zmeczenie_fizyczne", 0))
		_obniz_relacje_rodzicow(swiat, 8)
		var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
		var mandat := mini(80, kasa)
		boh["pieniadze"] = kasa - mandat
		swiat["bohater"] = boh
		out["zlapany"] = true
		out["tekst"] = "Złapali cię. Mandat %d zł, relacja z rodzicami spada." % mandat
		return out
	var kopia: Dictionary = oferta.duplicate(true)
	kopia["cena_zl"] = 0
	kopia["ilosc"] = 1
	if not (swiat.get("majatek") is Dictionary):
		swiat["majatek"] = {"nieruchomosci": [], "dobra": []}
	var maj: Dictionary = swiat["majatek"]
	if not (maj.get("dobra") is Array):
		maj["dobra"] = []
	maj["dobra"].append(kopia)
	swiat["majatek"] = maj
	swiat["bohater"] = boh
	out["ok"] = true
	out["tekst"] = "Udało się zabrać: %s." % str(oferta.get("nazwa", "rzecz"))
	return out


static func tick(swiat: Dictionary) -> String:
	var linie: PackedStringArray = []
	linie.append(_tick_nauki(swiat))
	linie.append(_tick_sprzedazy(swiat))
	linie.append(_tick_pozyczki(swiat))
	linie.append(_tick_lokum(swiat))
	linie.append(_tick_jedzenia(swiat))
	var lekarz := _tick_kolejki_lekarza(swiat)
	if lekarz != "":
		linie.append(lekarz)
	var tekst := ""
	for l in linie:
		if l != "":
			tekst += l + "\n"
	return tekst.strip_edges()


static func ucz_sie(swiat: Dictionary, wysilek: int) -> void:
	swiat["wysilek_nauki"] = clampi(wysilek, 0, 100)


static func bojka(swiat: Dictionary) -> Dictionary:
	var out := {"ok": true, "tekst": ""}
	if int(swiat.get("bojka_tydzien", -1)) == int(swiat.get("tydzien", 0)):
		out["ok"] = false
		out["tekst"] = "W tym tygodniu już była bójka."
		return out
	swiat["bojka_tydzien"] = int(swiat.get("tydzien", 0))
	var boh := _bohater(swiat)
	_dodaj_liczbe(boh, "zmeczenie_fizyczne", 15, 0, 100)
	boh["zmeczenie"] = int(boh.get("zmeczenie_fizyczne", 0))
	_dodaj_liczbe(boh, "psychika", -4, -50, 100)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if rng.randf() < 0.25:
		_dodaj_liczbe(boh, "zdrowie", -8, 0, 100)
		out["tekst"] = "Bójka. Jesteś poobijany, zmęczony i w gorszym nastroju."
	else:
		out["tekst"] = "Bójka bez większego urazu. Zmęczenie rośnie, nastrój spada."
	swiat["bohater"] = boh
	return out


static func idz_do_lekarza(swiat: Dictionary, sciezka: String, problem: String, rodzice_wybrali: String = "") -> Dictionary:
	## sciezka: rodzice | nfz | prywatnie. rodzice_wybrali: nfz | prywatnie.
	var out := {"ok": false, "tekst": ""}
	var spec: Dictionary = SPECJALIZACJE.get(problem, SPECJALIZACJE["cialo"])
	var tryb := sciezka
	if sciezka == "rodzice":
		if rodzice_wybrali == "":
			out["tekst"] = "Rodzice pytają: NFZ czy prywatnie?"
			out["pytanie"] = true
			out["ok"] = true
			return out
		tryb = rodzice_wybrali
		if tryb == "prywatnie":
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var odmowa := clampf(0.72 - float(_dochod_rodzicow(swiat)) / 18000.0, 0.12, 0.82)
			if rng.randf() < odmowa:
				out["tekst"] = "Rodzice nie chcą płacić za prywatną wizytę."
				return out
			out["tekst"] = "Rodzice płacą za %s. " % str(spec.get("nazwa", "lekarza"))
			return _wynik_wizyty(swiat, problem, 0.9, out)
	if tryb == "nfz":
		var czekanie := 3
		swiat["kolejka_lekarza"] = {"zostalo": czekanie, "problem": problem, "dokladnosc": 0.62}
		out["ok"] = true
		out["tekst"] = str(out.get("tekst", "")) + "NFZ: %s przyjmie za %d tyg." % [str(spec.get("nazwa", "")), czekanie]
		return out
	if tryb == "prywatnie":
		var cena := int(spec.get("cena", 200))
		var boh := _bohater(swiat)
		var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
		if kasa < cena:
			out["tekst"] = "Prywatna wizyta kosztuje %d zł. Masz %d." % [cena, kasa]
			return out
		boh["pieniadze"] = kasa - cena
		swiat["bohater"] = boh
		out["tekst"] = "Płacisz %d zł. " % cena
		return _wynik_wizyty(swiat, problem, 0.92, out)
	out["tekst"] = "Wybierz ścieżkę."
	return out


static func wystaw_na_sprzedaz(swiat: Dictionary, indeks: int, cena: int) -> Dictionary:
	var dobro := _dobro(swiat, indeks)
	if dobro.is_empty():
		return {"ok": false, "tekst": "Nie ma tej rzeczy."}
	var fair := _wartosc_rzeczy(dobro)
	dobro["wystawione"] = true
	dobro["cena_wystawienia"] = maxi(1, cena)
	dobro["wartosc_uczciwa"] = fair
	if cena <= int(round(float(fair) * 0.6)):
		return _sprzedaj_teraz(swiat, indeks, cena, "Schodzi od ręki za %d zł." % cena)
	return {"ok": true, "tekst": "Wystawione za %d zł. Uczciwie byłoby około %d zł." % [cena, fair]}


static func zdejmij_ze_sprzedazy(swiat: Dictionary, indeks: int) -> void:
	var dobro := _dobro(swiat, indeks)
	if dobro.is_empty():
		return
	dobro["wystawione"] = false


static func wez_pozyczke(swiat: Dictionary, kwota: int, od_rodziny: bool) -> Dictionary:
	var out := {"ok": false, "tekst": ""}
	if kwota < 100:
		out["tekst"] = "Za mała kwota."
		return out
	var boh := _bohater(swiat)
	if od_rodziny:
		var limit := 800
		if _dochod_rodzicow(swiat) >= 8000:
			limit = 2000
		if kwota > limit:
			out["tekst"] = "Rodzina pożyczy najwyżej %d zł." % limit
			return out
		_dodaj_pozyczke(swiat, kwota, 0.0, "rodzina")
		boh["pieniadze"] = int(boh.get("pieniadze", 0)) + kwota
		swiat["bohater"] = boh
		out["ok"] = true
		out["tekst"] = "Rodzina pożycza %d zł bez odsetek." % kwota
		return out
	var wiek := int(boh.get("wiek", 0))
	var pensja := _pensja_tygodniowa(swiat)
	if wiek < 18 or pensja <= 0:
		out["tekst"] = "Bank pożycza od 18. roku życia i przy stałej pensji."
		return out
	if kwota > pensja * 40:
		out["tekst"] = "Bank daje najwyżej %d zł przy tej pensji." % (pensja * 40)
		return out
	_dodaj_pozyczke(swiat, kwota, 0.0023, "bank")
	boh["pieniadze"] = int(boh.get("pieniadze", 0)) + kwota
	swiat["bohater"] = boh
	out["ok"] = true
	out["tekst"] = "Kredyt %d zł. Około 12%% w skali roku, rata co tydzień." % kwota
	return out


static func koszt_lokum_tydzien(lokum: Dictionary) -> int:
	var m2 := 40.0
	if _liczba(lokum.get("metraz_m2")):
		m2 = float(lokum["metraz_m2"])
	var typ := str(lokum.get("kategoria", lokum.get("typ", "mieszkanie")))
	var za_m2 := 4.5
	if typ == "dom" or typ == "willa" or typ == "dom_jednorodzinny":
		za_m2 = 2.2
	return maxi(1, int(round(m2 * za_m2)))


static func ustaw_budzet_jedzenia(swiat: Dictionary, kwota: int) -> void:
	swiat["budzet_jedzenia_zl"] = clampi(kwota, 0, 2000)


static func _tick_nauki(swiat: Dictionary) -> String:
	var wysilek := int(swiat.get("wysilek_nauki", 0))
	var boh := _bohater(swiat)
	var intel := 40.0
	if _liczba(boh.get("inteligencja_postep")):
		intel = float(boh["inteligencja_postep"])
	elif _liczba(boh.get("inteligencja_logiczna")):
		intel = float(boh["inteligencja_logiczna"])
	if wysilek > 0:
		intel += 0.18 * (float(wysilek) / 100.0) * (1.0 - intel / 130.0)
		intel = clampf(intel, 0.0, 100.0)
	boh["inteligencja_postep"] = intel
	boh["inteligencja_logiczna"] = int(round(intel))
	var srednia := 3.0
	if _liczba(swiat.get("srednia_ocen")):
		srednia = float(swiat["srednia_ocen"])
	if wysilek > 0 or _liczba(swiat.get("srednia_ocen")):
		srednia += (float(wysilek) / 100.0) * 0.12 + (intel / 100.0) * 0.04 - 0.06
		srednia = clampf(srednia, 1.0, 6.0)
		swiat["srednia_ocen"] = snappedf(srednia, 0.1)
		boh["srednia_ocen"] = swiat["srednia_ocen"]
	swiat["bohater"] = boh
	if wysilek <= 0:
		return ""
	var ocena := "słaba"
	if srednia >= 4.0:
		ocena = "dobra"
	elif srednia >= 3.0:
		ocena = "przeciętna"
	return "Nauka: średnia %.1f (%s). Inteligencja %d." % [srednia, ocena, int(round(intel))]


static func _tick_sprzedazy(swiat: Dictionary) -> String:
	var maj: Dictionary = swiat.get("majatek", {}) if swiat.get("majatek") is Dictionary else {}
	var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	var zostaje: Array = []
	var tekst := ""
	for d in dobra:
		if not (d is Dictionary) or not bool(d.get("wystawione", false)):
			zostaje.append(d)
			continue
		var cena := int(d.get("cena_wystawienia", 1))
		var fair := int(d.get("wartosc_uczciwa", _wartosc_rzeczy(d)))
		var szansa := 0.2
		if fair > 0:
			szansa = clampf(0.85 * float(fair) / float(maxi(1, cena)), 0.05, 0.9)
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		if rng.randf() < szansa:
			var boh := _bohater(swiat)
			boh["pieniadze"] = int(boh.get("pieniadze", 0)) + cena
			swiat["bohater"] = boh
			tekst = "Sprzedane: %s za %d zł." % [str(d.get("nazwa", "rzecz")), cena]
		else:
			zostaje.append(d)
	if maj is Dictionary:
		maj["dobra"] = zostaje
		swiat["majatek"] = maj
	return tekst


static func _tick_pozyczki(swiat: Dictionary) -> String:
	if not (swiat.get("pozyczki") is Array):
		return ""
	var tekst := ""
	var boh := _bohater(swiat)
	for p in swiat["pozyczki"]:
		if not (p is Dictionary):
			continue
		var saldo := int(p.get("saldo", 0))
		if saldo <= 0:
			continue
		var odsetki := int(round(float(saldo) * float(p.get("stopa_tydzien", 0.0))))
		var rata := maxi(20, int(round(float(saldo) / 20.0)) + odsetki)
		rata = mini(rata, saldo + odsetki)
		var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
		if kasa >= rata:
			boh["pieniadze"] = kasa - rata
			p["saldo"] = maxi(0, saldo + odsetki - rata)
			p["zalegle"] = 0
		else:
			p["zalegle"] = int(p.get("zalegle", 0)) + 1
			p["saldo"] = saldo + odsetki
			_dodaj_liczbe(boh, "psychika", -3, -50, 100)
			tekst = "Nie ma na ratę pożyczki."
			if int(p["zalegle"]) >= 2 and str(p.get("od", "")) == "rodzina":
				_obniz_relacje_rodzicow(swiat, 6)
	swiat["bohater"] = boh
	return tekst


static func _tick_lokum(swiat: Dictionary) -> String:
	if not bool(swiat.get("mieszka_sam", false)):
		return ""
	var lokum := _lokum_wlasne(swiat)
	if lokum.is_empty():
		return ""
	var koszt := koszt_lokum_tydzien(lokum)
	var boh := _bohater(swiat)
	var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
	if kasa >= koszt:
		boh["pieniadze"] = kasa - koszt
		swiat["bohater"] = boh
		return "Utrzymanie lokum: %d zł." % koszt
	boh["pieniadze"] = 0
	_dodaj_liczbe(boh, "psychika", -2, -50, 100)
	swiat["bohater"] = boh
	return "Brakuje na utrzymanie lokum (%d zł)." % koszt


static func _tick_jedzenia(swiat: Dictionary) -> String:
	if not bool(swiat.get("mieszka_sam", false)):
		return ""
	var budzet := int(swiat.get("budzet_jedzenia_zl", 80))
	var boh := _bohater(swiat)
	var kasa := int(boh.get("pieniadze", 0)) if _liczba(boh.get("pieniadze")) else 0
	var placa := mini(budzet, kasa)
	boh["pieniadze"] = kasa - placa
	if placa >= 120:
		_dodaj_liczbe(boh, "psychika", 1, -50, 100)
		_dodaj_liczbe(boh, "zdrowie", 1, 0, 100)
	elif placa < 40:
		_dodaj_liczbe(boh, "psychika", -2, -50, 100)
		_dodaj_liczbe(boh, "kondycja", -1, 0, 100)
	swiat["bohater"] = boh
	return "Jedzenie: %d zł." % placa


static func _tick_kolejki_lekarza(swiat: Dictionary) -> String:
	if not (swiat.get("kolejka_lekarza") is Dictionary):
		return ""
	var k: Dictionary = swiat["kolejka_lekarza"]
	k["zostalo"] = int(k.get("zostalo", 1)) - 1
	if int(k["zostalo"]) > 0:
		swiat["kolejka_lekarza"] = k
		return ""
	swiat.erase("kolejka_lekarza")
	var out := {"ok": true, "tekst": ""}
	_wynik_wizyty(swiat, str(k.get("problem", "cialo")), float(k.get("dokladnosc", 0.62)), out)
	return str(out.get("tekst", ""))


static func _wynik_wizyty(swiat: Dictionary, problem: String, dokladnosc: float, out: Dictionary) -> Dictionary:
	var spec: Dictionary = SPECJALIZACJE.get(problem, SPECJALIZACJE["cialo"])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var chory := false
	var boh := _bohater(swiat)
	if problem == "psychika" and int(boh.get("psychika", 50)) < 35:
		chory = true
	elif problem == "cialo" and int(boh.get("zdrowie", 80)) < 60:
		chory = true
	elif problem == "cialo" and int(boh.get("zmeczenie_fizyczne", 0)) > 75:
		chory = true
	var pudlo := chory and rng.randf() > dokladnosc
	if pudlo or not chory:
		out["tekst"] = str(out.get("tekst", "")) + "%s: brak problemów z %s." % [str(spec.get("nazwa", "Lekarz")), _nazwa_problemu(problem)]
	else:
		if problem == "psychika":
			_dodaj_liczbe(boh, "psychika", 6, -50, 100)
		elif problem == "cialo":
			_dodaj_liczbe(boh, "zdrowie", 8, 0, 100)
			_dodaj_liczbe(boh, "zmeczenie_fizyczne", -10, 0, 100)
		out["tekst"] = str(out.get("tekst", "")) + "%s zajmuje się %s. Jest poprawa." % [str(spec.get("nazwa", "Lekarz")), _nazwa_problemu(problem)]
		swiat["bohater"] = boh
	out["ok"] = true
	return out


static func _nazwa_problemu(problem: String) -> String:
	match problem:
		"zeby":
			return "zębami"
		"psychika":
			return "nastrojem"
		"oczy":
			return "wzrokiem"
		_:
			return "ciałem"


static func _sprzedaj_teraz(swiat: Dictionary, indeks: int, cena: int, tekst: String) -> Dictionary:
	var maj: Dictionary = swiat["majatek"]
	var dobra: Array = maj["dobra"]
	dobra.remove_at(indeks)
	maj["dobra"] = dobra
	swiat["majatek"] = maj
	var boh := _bohater(swiat)
	boh["pieniadze"] = int(boh.get("pieniadze", 0)) + cena
	swiat["bohater"] = boh
	return {"ok": true, "tekst": tekst}


static func _wartosc_rzeczy(dobro: Dictionary) -> int:
	if _liczba(dobro.get("cena_zl")):
		return maxi(1, int(round(float(dobro["cena_zl"]) * 0.7)))
	return 20


static func _dodaj_pozyczke(swiat: Dictionary, kwota: int, stopa: float, od: String) -> void:
	if not (swiat.get("pozyczki") is Array):
		swiat["pozyczki"] = []
	(swiat["pozyczki"] as Array).append({"saldo": kwota, "stopa_tydzien": stopa, "od": od, "zalegle": 0})


static func _pensja_tygodniowa(swiat: Dictionary) -> int:
	var praca: Variant = swiat.get("praca", {})
	if praca is Dictionary and _liczba(praca.get("placa_zl")):
		return maxi(0, int(round(float(praca["placa_zl"]) / 4.0)))
	return 0


static func _dochod_rodzicow(swiat: Dictionary) -> int:
	var rodzina: Dictionary = swiat.get("rodzina", {}) if swiat.get("rodzina") is Dictionary else {}
	var z: Dictionary = rodzina.get("zarobki", {}) if rodzina.get("zarobki") is Dictionary else {}
	if _liczba(z.get("mediana_zl")):
		return int(z["mediana_zl"])
	if _liczba(z.get("przecietne_zl")):
		return int(z["przecietne_zl"])
	return 4000


static func _lokum_wlasne(swiat: Dictionary) -> Dictionary:
	var maj: Dictionary = swiat.get("majatek", {}) if swiat.get("majatek") is Dictionary else {}
	var lista: Array = maj.get("nieruchomosci", []) if maj.get("nieruchomosci") is Array else []
	if lista.is_empty() or not (lista[0] is Dictionary):
		return {}
	return lista[0]


static func _dobro(swiat: Dictionary, indeks: int) -> Dictionary:
	var maj: Dictionary = swiat.get("majatek", {}) if swiat.get("majatek") is Dictionary else {}
	var dobra: Array = maj.get("dobra", []) if maj.get("dobra") is Array else []
	if indeks < 0 or indeks >= dobra.size() or not (dobra[indeks] is Dictionary):
		return {}
	return dobra[indeks]


static func _bohater(swiat: Dictionary) -> Dictionary:
	if swiat.get("bohater") is Dictionary:
		return swiat["bohater"]
	return {}


static func _dodaj_liczbe(boh: Dictionary, klucz: String, delta: int, lo: int, hi: int) -> void:
	var teraz := 0
	if _liczba(boh.get(klucz)):
		teraz = int(boh[klucz])
	boh[klucz] = clampi(teraz + delta, lo, hi)


static func _obniz_relacje_rodzicow(swiat: Dictionary, delta: int) -> void:
	var rodzina: Dictionary = swiat.get("rodzina", {}) if swiat.get("rodzina") is Dictionary else {}
	for rola in ["matka", "ojciec"]:
		if rodzina.get(rola) is Dictionary:
			var os: Dictionary = rodzina[rola]
			var rel := 55
			if _liczba(os.get("relacja")):
				rel = int(os["relacja"])
			os["relacja"] = clampi(rel - delta, 0, 100)
			rodzina[rola] = os
	swiat["rodzina"] = rodzina


static func _liczba(v: Variant) -> bool:
	return v is int or v is float
