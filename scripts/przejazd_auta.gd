extends RefCounted
class_name PrzejazdAuta

## Koszt przejazdu autem: dystans × zużycie(tryb) × cena_paliwa.
## Cena paliwa null → nie jedź za złotówki (UI: „—”).
## Mandat / zmęczenie: lekki stub + propozycja.

const TRYB_EKONOMICZNY := "ekonomiczna"
const TRYB_DOZWOLONA := "maksymalna_dozwolona"
const TRYB_PRZEKROCZONA := "przekroczona"

## Propozycja mnożników spalania względem katalogowego l/100 km.
const MNOZNIK_EKONOMICZNY := 0.85
const MNOZNIK_DOZWOLONA := 1.0
const MNOZNIK_BAZA_PRZEKROCZENIA := 1.15
const MNOZNIK_NA_KM_H_PONAD := 0.012

const LIMIT_DOZWOLONY_KM_H := 140  ## stub autostrada PL — propozycja_do_poprawki


func oblicz(
	dystans_km: float,
	auto: Dictionary,
	tryb: String,
	nadmiar_km_h: float,
	cena_paliwa_zl_l: Variant
) -> Dictionary:
	var out := {
		"ok": false,
		"koszt_zl": null,
		"koszt_tekst": "—",
		"zuzycie_l_na_100": null,
		"litry": null,
		"zmeczenie_fizyczne_delta": 0,
		"mandat_szansa": 0.0,
		"mandat_stub": "",
		"predkosc_jazdy_km_h": null,
		"vmax_km_h": null,
		"propozycja_do_poprawki": true,
		"powod": "",
	}
	if bool(auto.get("nie_jezdzi", false)):
		out["powod"] = "Auto nie jeździ (poważna awaria silnika)."
		return out
	if dystans_km < 0.0:
		out["powod"] = "Ujemny dystans."
		return out
	var vmax_v: Variant = predkosc_max_auta(auto)
	if vmax_v == null:
		out["powod"] = "Brak prędkości maksymalnej w danych auta."
		return out
	out["vmax_km_h"] = int(vmax_v)
	var vmax := float(out["vmax_km_h"])
	var predkosc := float(LIMIT_DOZWOLONY_KM_H)
	var nadmiar := maxf(0.0, nadmiar_km_h)
	match tryb:
		TRYB_EKONOMICZNY:
			predkosc = minf(90.0, vmax)
		TRYB_DOZWOLONA:
			predkosc = minf(float(LIMIT_DOZWOLONY_KM_H), vmax)
		TRYB_PRZEKROCZONA:
			predkosc = minf(float(LIMIT_DOZWOLONY_KM_H) + nadmiar, vmax)
			nadmiar = maxf(0.0, predkosc - float(LIMIT_DOZWOLONY_KM_H))
		_:
			out["powod"] = "Nieznany tryb jazdy."
			return out
	out["predkosc_jazdy_km_h"] = snappedf(predkosc, 1.0)
	var zuzycie: Variant = zuzycie_trybu(auto, tryb, nadmiar)
	out["zuzycie_l_na_100"] = zuzycie
	if zuzycie == null:
		out["powod"] = "Brak spalania w danych auta."
		out["koszt_tekst"] = "—"
		_wypelnij_zmeczenie_i_mandat(out, tryb, nadmiar, predkosc, vmax)
		return out
	var litry := float(dystans_km) * float(zuzycie) / 100.0
	out["litry"] = snappedf(litry, 0.01)
	if not (cena_paliwa_zl_l is int or cena_paliwa_zl_l is float):
		out["powod"] = "Cena paliwa kraju = null — nie licz złotówek."
		out["koszt_tekst"] = "—"
		_wypelnij_zmeczenie_i_mandat(out, tryb, nadmiar, predkosc, vmax)
		return out
	var koszt := litry * float(cena_paliwa_zl_l)
	out["koszt_zl"] = snappedf(koszt, 0.01)
	out["koszt_tekst"] = "%.2f zł" % float(out["koszt_zl"])
	out["ok"] = true
	out["dystans_km"] = dystans_km
	_wypelnij_zmeczenie_i_mandat(out, tryb, nadmiar, predkosc, vmax)
	return out


func dolicz_przebieg(auto: Dictionary, km: float) -> int:
	var dodatek := maxi(0, int(round(km)))
	var teraz := int(auto.get("przebieg_km", 0)) if auto.get("przebieg_km") is int or auto.get("przebieg_km") is float else 0
	auto["przebieg_km"] = teraz + dodatek
	return int(auto["przebieg_km"])


func zuzycie_trybu(auto: Dictionary, tryb: String, nadmiar_km_h: float) -> Variant:
	var baza: Variant = null
	if tryb == TRYB_PRZEKROCZONA and (auto.get("spalanie_przy_vmax") is int or auto.get("spalanie_przy_vmax") is float):
		baza = float(auto["spalanie_przy_vmax"])
	elif auto.get("spalanie") is int or auto.get("spalanie") is float:
		baza = float(auto["spalanie"])
	if baza == null:
		return null
	match tryb:
		TRYB_EKONOMICZNY:
			return snappedf(float(baza) * MNOZNIK_EKONOMICZNY, 0.01)
		TRYB_DOZWOLONA:
			return snappedf(float(baza) * MNOZNIK_DOZWOLONA, 0.01)
		TRYB_PRZEKROCZONA:
			var m := MNOZNIK_BAZA_PRZEKROCZENIA + MNOZNIK_NA_KM_H_PONAD * maxf(0.0, nadmiar_km_h)
			return snappedf(float(baza) * m, 0.01)
	return float(baza)


## Efektywna vmax (katalog + delta usterek). null gdy brak danych lub nie_jezdzi.
func predkosc_max_auta(auto: Dictionary) -> Variant:
	if bool(auto.get("nie_jezdzi", false)):
		return null
	if auto.get("predkosc_max_kmh") is int or auto.get("predkosc_max_kmh") is float:
		return clampi(int(auto["predkosc_max_kmh"]), 40, 350)
	if auto.get("vmax_katalog") is int or auto.get("vmax_katalog") is float:
		var d := int(auto.get("vmax_delta", 0))
		return clampi(int(auto["vmax_katalog"]) + d, 40, 350)
	# Brak w katalogu — nie zmyślaj typowej wartości napędu.
	return null


func _wypelnij_zmeczenie_i_mandat(out: Dictionary, tryb: String, nadmiar: float, predkosc: float, vmax: float) -> void:
	# Szybsza jazda → mniej zmęczenia fizycznego (propozycja).
	var delta := 8
	if tryb == TRYB_EKONOMICZNY:
		delta = 10
	elif tryb == TRYB_DOZWOLONA:
		delta = 6
	else:
		delta = maxi(2, 6 - int(nadmiar / 20.0))
	out["zmeczenie_fizyczne_delta"] = delta
	out["propozycja_zmeczenia"] = true
	if tryb == TRYB_PRZEKROCZONA and nadmiar > 0.0:
		var szansa := clampf(0.05 + nadmiar / 200.0, 0.05, 0.55)
		out["mandat_szansa"] = snappedf(szansa, 0.01)
		out["mandat_stub"] = "Ryzyko mandatu (stub): ~%d%% przy +%d km/h." % [int(szansa * 100.0), int(nadmiar)]
	else:
		out["mandat_szansa"] = 0.0
		out["mandat_stub"] = ""
	var _p := predkosc
	var _v := vmax
