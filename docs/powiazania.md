# Powiązania systemów

Krótka mapa: co rusza które pole. Nowe funkcje niech wołają te wejścia, zamiast liczyć obok.

| Element | Gdzie żyje | Kto zmienia |
|---|---|---|
| Zmęczenie fizyczne / psychiczne | `bohater.zmeczenie_fizyczne`, `zmeczenie_psychiczne` (lustro: `zmeczenie`) | W trakcie tury źródła dopisują surowe punkty (`dodaj_zmeczenie_tury` albo zwykłe dodanie). Na końcu tury tylko `RynekZakupow.rozlicz_zmeczenie_tury`: najpierw regeneracja × m (udział zdrowia 50–80% razy m, sufit **0,95**), potem zysk tury / m, clamp 0–100. m = nastrój/100 + 0,35 (psychika obcięta do 0–100). Nastrój z końca tury. Nie mnożyć w źródle. |
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
| Kradzież | `ZycieCodzienne.kradziez_dostepna` | Jedyny haczyk widoczności. Cel i szansa: `cele_kradziezy`, `szansa_kradziezy` (wartość, rozmiar, czujność, zwinność, inteligencja, zmęczenie, nastrój, wykroczenia). |
| Nauka i oceny | `wysilek_nauki`, `srednia_ocen`, `inteligencja_logiczna` | Tura `ZycieCodzienne.tick`. Wysiłek daje też zmęczenie psychiczne (0,12 × wysiłek). Kłótnia rodziców: częściej przy niższym dochodzie. Oskarżenie: event `niesprawiedliwe_oskarzenie`. |
| Lekarz | `idz_do_lekarza` | Rodzice / NFZ (kolejka) / prywatnie. Pudło nie mówi o błędzie, tylko „brak problemów”. |
| Sprzedaż i pożyczka | `wystawione` na dobru, `pozyczki` | Majątek. Rata w turze. Bank od 18 lat i przy `praca.placa_zl`. |
| Koszty po wyprowadzce | `mieszka_sam` po kupnie nieruchomości | Czynsz+media albo ogrzewanie, plus `budzet_jedzenia_zl` (ekran jedzenia). Dom rodzinny (`lokum_startowe`) bez tego. |
