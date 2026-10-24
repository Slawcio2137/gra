extends RefCounted
class_name WygladGracza

## Jedno miejsce na przejrzystość i kolory. Zapis w user://, nie w wielu scenach.

const PLIK := "user://ustawienia_gracza.cfg"
const WERSJA_UKLADU := 2


static func domyslne() -> Dictionary:
	return {
		"szerokosc_prawej": 1,
		"alpha_panelu": 1.0,
		"alpha_przyciskow": 0.75,
		"alpha_napisow": 1.0,
		"kolor_napisow": Color(1, 1, 1, 1),
		"kolor_tla": Color(0.45, 0.45, 0.48, 1),
		"wersja_ukladu": WERSJA_UKLADU,
	}


static func wczytaj() -> Dictionary:
	var wynik := domyslne()
	var cfg := ConfigFile.new()
	if cfg.load(PLIK) != OK:
		return wynik
	wynik["szerokosc_prawej"] = clampi(int(cfg.get_value("wyglad", "szerokosc_prawej", 1)), 1, 3)
	var wersja := int(cfg.get_value("wyglad", "wersja_ukladu", 0))
	if wersja < WERSJA_UKLADU:
		wynik["alpha_panelu"] = 1.0
	else:
		wynik["alpha_panelu"] = clampf(float(cfg.get_value("wyglad", "alpha_panelu", 1.0)), 0.0, 1.0)
	wynik["alpha_przyciskow"] = clampf(float(cfg.get_value("wyglad", "alpha_przyciskow", 0.75)), 0.0, 1.0)
	wynik["alpha_napisow"] = clampf(float(cfg.get_value("wyglad", "alpha_napisow", 1.0)), 0.0, 1.0)
	var napisy: Variant = cfg.get_value("wyglad", "kolor_napisow", wynik["kolor_napisow"])
	var tlo: Variant = cfg.get_value("wyglad", "kolor_tla", wynik["kolor_tla"])
	if napisy is Color:
		wynik["kolor_napisow"] = napisy
	if tlo is Color:
		wynik["kolor_tla"] = tlo
	wynik["wersja_ukladu"] = WERSJA_UKLADU
	return wynik


static func zapisz(dane: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("wyglad", "wersja_ukladu", WERSJA_UKLADU)
	cfg.set_value("wyglad", "szerokosc_prawej", int(dane.get("szerokosc_prawej", 1)))
	cfg.set_value("wyglad", "alpha_panelu", float(dane.get("alpha_panelu", 1.0)))
	cfg.set_value("wyglad", "alpha_przyciskow", float(dane.get("alpha_przyciskow", 0.75)))
	cfg.set_value("wyglad", "alpha_napisow", float(dane.get("alpha_napisow", 1.0)))
	cfg.set_value("wyglad", "kolor_napisow", dane.get("kolor_napisow", Color.WHITE))
	cfg.set_value("wyglad", "kolor_tla", dane.get("kolor_tla", Color(0.45, 0.45, 0.48)))
	cfg.save(PLIK)


static func temat(dane: Dictionary) -> Theme:
	var tlo: Color = dane.get("kolor_tla", Color(0.45, 0.45, 0.48))
	var napis: Color = dane.get("kolor_napisow", Color.WHITE)
	napis.a = float(dane.get("alpha_napisow", 1.0))
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(tlo.r, tlo.g, tlo.b, float(dane.get("alpha_panelu", 1.0)))
	panel.content_margin_left = 16.0
	panel.content_margin_right = 16.0
	panel.content_margin_top = 12.0
	panel.content_margin_bottom = 12.0
	var przycisk := StyleBoxFlat.new()
	przycisk.bg_color = Color(tlo.r, tlo.g, tlo.b, float(dane.get("alpha_przyciskow", 0.75)))
	przycisk.content_margin_left = 10.0
	przycisk.content_margin_right = 10.0
	przycisk.content_margin_top = 6.0
	przycisk.content_margin_bottom = 6.0
	var najechany: StyleBoxFlat = przycisk.duplicate()
	najechany.bg_color = Color(
		minf(tlo.r + 0.08, 1.0),
		minf(tlo.g + 0.08, 1.0),
		minf(tlo.b + 0.08, 1.0),
		przycisk.bg_color.a
	)
	var motyw := Theme.new()
	motyw.set_stylebox("panel", "PanelContainer", panel)
	for stan in ["normal", "pressed", "disabled", "focus"]:
		motyw.set_stylebox(stan, "Button", przycisk)
		motyw.set_stylebox(stan, "OptionButton", przycisk)
	motyw.set_stylebox("hover", "Button", najechany)
	motyw.set_stylebox("hover", "OptionButton", najechany)
	motyw.set_color("font_color", "Label", napis)
	motyw.set_color("font_color", "Button", napis)
	motyw.set_color("font_hover_color", "Button", napis)
	motyw.set_color("font_pressed_color", "Button", napis)
	motyw.set_color("font_disabled_color", "Button", napis)
	motyw.set_color("font_color", "CheckButton", napis)
	motyw.set_color("font_hover_color", "CheckButton", napis)
	motyw.set_color("font_pressed_color", "CheckButton", napis)
	motyw.set_color("font_color", "CheckBox", napis)
	motyw.set_color("font_color", "LineEdit", napis)
	motyw.set_color("default_color", "RichTextLabel", napis)
	return motyw


static func napis_przejrzystosci(nazwa: String, alpha: float) -> String:
	var procent := int(round((1.0 - alpha) * 100.0))
	return "%s: %d%% przejrzystości" % [nazwa, procent]
