# Powiązania systemów

Krótka mapa: co rusza które pole. Nowe funkcje niech wołają te wejścia, zamiast liczyć obok.

| Element | Gdzie żyje | Kto zmienia |
|---|---|---|
| Zmęczenie fizyczne / psychiczne | `bohater.zmeczenie_fizyczne`, `zmeczenie_psychiczne` (lustro: `zmeczenie`) | Tura: najpierw `RynekZakupow.regeneruj_zmeczenie_tydzien` (50–80% ze średniej `kondycja` albo `zdrowie` i `psychika`), potem dodatki. Remont: `tick_remonty` (+22 sam, +10 kumpel). Praca: `RynekPracy.tick`. Komunikacja przy odbiorze drobiazgu: `wykonaj_odbior_drobny`. |
| Zdrowie / kondycja / psychika | `kondycja`, `zdrowie`, `psychika` | Praca (`efekty_tygodniowe`), terapia (`depresja.gd`), wygoda lokum (`efekt_wygody_tydzien`). Regeneracja zmęczenia tylko je czyta. |
| Wiedza | `wiedza_pkt` (pełna pewność około 20) | Korepetycje, zajęcia, eventy. Ocena stanu oferty: `poziom_wiedzy_oceny` + przy aucie `znajomosc_pojazdow`. Poniżej 0,2 gracz sam nie ocenia. |
| Pieniądze | `bohater.pieniadze` | `kup`, `wykonaj_odbior_drobny`, `wykonaj_dojazd`, `remont`, targowanie (`targuj`). |
| Relacja | `relacja` na osobie (0–100, brak = 55) | Podwózka i pomoc kumpla przy remoncie (`kierowca_prosi_o_paliwo`, `min_stawka_tygodniowa`). Lista osób: `kandydaci_pomocy_oceny`. |
| Odbiór / dostawa | oferta `odleglosc_km`, `ilosc`, `odbior_wybrany`; paczki w `swiat.dostawy` | Drobiazgi: `wykonaj_odbior_drobny` potem `kup`. Czas wysyłki: `tygodnie_wysylki`, odliczanie `tick_dostawy`. Auto: `koszt_dojazdu` / `wykonaj_dojazd`. |
| Paliwo | spalanie auta + `cena_nosnika_dojazdu` (benzyna / gaz / energia) | Własny odbiór: `koszt_paliwa_wlasnego_auta` (w obie strony). Podwózka do auta: `koszt_dojazdu`. |
| Szkoła / legitymacja | `uczy_sie`, `studiuje` albo wpis `edukacja` z `trwa` / `aktualna` / `uczy_sie` | `ma_legitymacje`. Bilet komunikacji powyżej 5 km: 2–5 zł, z legitymacją połowa (minimum 1 zł). Do 5 km: 0 zł. |
| Stan rzeczy | `stan_rzeczywisty`, `stan_oceniony`; książka: `stan_ksiazki` | Generacja `_losuj_dobro`. Ocena `ocen_stan`. Książka używana: skala świetny / dobry / zaczytany / rozpadający się, bez listy usterek. |
| Limit klatek | `max_fps` w `user://ustawienia_gracza.cfg`, `Engine.max_fps` | Ustawienia, `DostepAdmina.zastosuj_fps`. 0 = bez limitu. |
| Panel admina | `DostepAdmina.admin_dostepny` | Debug albo 7 stuknięć w „Wersja” i PIN. `WLACZ_ADMINA` wyłącza całość. Edycja idzie w `bohater` i zapis. |
