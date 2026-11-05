# Statystyki bohatera

Tabela zrobiona ze stanu kodu na gałęzi `cursor/podzial-ekranow-bdcc`. Nie jest projektem do wdrożenia i nie zmienia gry. Jedzenie **nie zapisuje** swoich plusów w polach bohatera i **nie liczy ich w turze**.

Źródła: `postacie/bohater.json`, `postacie/losowanie/kolo_statystyk.json`, `scripts/losowanie.gd`, `ui/pasek_emotikony.json`, `scripts/pasek_statystyk.gd`, `scripts/ekran_rodziny.gd`, `scripts/jedzenie_ustawienia.gd`, `postacie/jedzenie_ustawienia.json`, `scripts/wprawa_gotowania.gd`, `scripts/rynek_zakupow.gd` (`efekt_wygody_tydzien`), `scripts/rynek_pracy.gd` (`_zastosuj_efekty`), `postacie/cechy_charakteru.json`, `postacie/inteligencja.json`, `postacie/sylwetka.json`, `postacie/inteligencja_emocjonalna.json`, `scripts/statystyki_dostep.gd`, `scripts/statystyki_panel.gd`.

## Co pokazać graczowi

Na pasku zostawić to, co już tam jest: psychika, zmęczenie fizyczne, zmęczenie psychiczne, pieniądze.

W rozwinięciu paska i na „Wszystkie statystyki” dodać całe koło: siła, zwinność, szybkość reakcji, wytrzymałość, równowaga. Dziś widać tylko siłę i kondycję. Wytrzymałość jest w kodzie UI, ale gałąź się nie wykonuje, gdy siła albo kondycja jest liczbą.

Na ekranie postaci zostawić cechy, inteligencje, wiek, wygląd, sylwetkę, wiedzę, IE, zainteresowanie i depresję.

Nie pokazywać jako statystyk bohatera plusów z jedzenia (samopoczucie, zęby, „kondycja” i „sylwetka” z talerza, zadowolenie rodziców, licznik zdrowego żywienia), dopóki tura nie zapisuje ich w bohaterze. Zostają na ekranie jedzenia jako opis dania. Nie pokazywać „Docelowe (dev)” — `POKAZ_STATYSTYKI` jest włączone, a komentarz mówi, że to nie dla gracza.

## Koło 1–100

Losowanie: `losowanie.gd` `_wpisz_statystyki`. Waga liczby `n` to `n * (101 - n)`, zakres 1–100. Zapis w `bohater` pod tą samą nazwą.

| Statystyka | Typ / zakres | Gdzie zapisana | Co ją zmienia | Gdzie używana | Pokazana graczowi | Rekomendacja |
| --- | --- | --- | --- | --- | --- | --- |
| Siła | liczba 1–100 | `bohater.sila` | Tylko los startowy. Jedzenie nie. Praca dolicza `efekty_tygodniowe.sila`, jeśli pole już jest liczbą (`rynek_pracy.gd` `_zastosuj_efekty`, clamp 0–100). | Skuteczność w pracy, gdy brak kondycji (`skutecznosc`). | Tak: rozwinięty pasek i „Wszystkie statystyki”, linia „Siła / Kondycja”. Nie na ekranie postaci. | Pokazać. Zostawić w rozwinięciu i dodać na ekran postaci. |
| Kondycja | liczba 1–100 | `bohater.kondycja` | Jak siła, klucz `efekty_tygodniowe.kondycja`. To nie jest plus „kondycja” z jedzenia. | `skutecznosc`: `kondycja/100`, a gdy brak liczby — siła. | Tak, ta sama linia co siła. | Pokazać razem z siłą. Podpisać, że to koło, nie talerz. |
| Wytrzymałość | liczba 1–100 | `bohater.wytrzymalosc` | Tylko los startowy. Jedzenie i praca jej nie ruszają. | Nigdzie poza zapisem. | Nie. W `_wypelnij_statystyki_ilosciowe` jest `elif`, a siła i kondycja są zawsze ustawione, więc gałąź nie wchodzi. | Pokazać w rozwinięciu, obok siły i kondycji. |
| Zwinność | liczba 1–100 | `bohater.zwinnosc` | Tylko los startowy. | Nigdzie poza zapisem. | Nie. | Pokazać w rozwinięciu. |
| Szybkość reakcji | liczba 1–100 | `bohater.szybkosc_reakcji` | Tylko los startowy. | Nigdzie poza zapisem. | Nie. | Pokazać w rozwinięciu. |
| Równowaga | liczba 1–100 | `bohater.rownowaga` | Tylko los startowy. | Nigdzie poza zapisem. | Nie. | Pokazać w rozwinięciu. |

## Metryki paska

Progi emotikon i kolorów: `ui/pasek_emotikony.json`. Norma startowa 50 (`stan_gry.gd` `_uzupelnij_normy_bohatera`). Pasek: `pasek_statystyk.gd` `_zbuduj_pasek_statystyk`.

| Statystyka | Typ / zakres | Gdzie zapisana | Co ją zmienia | Gdzie używana | Pokazana graczowi | Rekomendacja |
| --- | --- | --- | --- | --- | --- | --- |
| Psychika | liczba, pasek 0–100, dół może zejść poniżej 0 | `bohater.psychika` | Nie jedzenie. Co turę wygoda lokum: `rynek_zakupow.gd` `efekt_wygody_tydzien`, krok `round(0,5 * (docelowe − obecne))`, clamp z dryfu (domyślnie −100…100). Praca: `efekty_tygodniowe.psychika`, tylko gdy pole jest liczbą. Czas poniżej 0 podbija `tygodnie_psychika_ponizej_0`; od 4 tur flaga depresji. | Pasek, ekran postaci, depresja, skuteczność pracy (obciążenie psychiczne). | Tak: emoji i pasek na górze oraz liczba na ekranie postaci („Psychika (nastrój)”). | Zostawić na pasku i na postaci. |
| Zmęczenie fizyczne | liczba 0–100 | `bohater.zmeczenie_fizyczne` (kopia w `zmeczenie`) | Nie jedzenie. Praca: efekty tygodnia. Dwie prace: `+12` (`_dolicz_brzemie`). | Pasek, ekran postaci, `skutecznosc` (kara). | Tak, na pasku. | Zostawić na pasku. |
| Zmęczenie psychiczne | liczba 0–100 | `bohater.zmeczenie_psychiczne` | Jak wyżej, bez jedzenia. Dwie prace: `+12`. | Pasek, ekran postaci, `skutecznosc`. | Tak, na pasku jako obciążenie psychiczne. | Zostawić na pasku. |
| Pieniądze | liczba zł, albo brak | `bohater.pieniadze` | Zakupy, dojazd, wypłaty, kieszonkowe. Jedzenie ma osobną kwotę sesji i przy zjedzeniu schodzi z niej, nie z bohatera (to osobny błąd kasy, nie statystyka). | Pasek. | Tak, na pasku. Kwota na pasku potrafi nie być tą, którą ruszył zakup. | Zostawić na pasku, ale jedna kasa. |

## Plusy jedzenia

Siedem nazw w `jedzenie_ustawienia.gd` `STATYSTYKI`. Liczby są w `postacie/jedzenie_ustawienia.json` (`wplyw_min` / `wplyw_max` suwaków oraz `wplyw` pozycji). Kod sam je oznacza `to_nie_statystyka`.

Wzór suwaka (`_wplyw_suwaka`): przy wartości `v` między min a max, `t = (v−min)/(max−min)`, potem `round(a + (b−a)*t)` dla każdego klucza. `wplyw_stanu` sumuje suwak ceny, suwak składników i dietę, jeśli cena albo składniki są ustawione. `zbiorcze` to różnica roboczego i zatwierdzonego stanu, nie poziom bohatera. Zjedzenie dopisuje wpływ pozycji do `_wplyw_zjedzone` i nigdzie dalej. Tura tylko robi `zrzut_zapisu` jedzenia. `WprawaGotowania.zastosuj_tydzien` nie jest wołane z gry.

Suwak ceny, tanio: samopoczucie −1, zdrowie −2, zęby −1, sylwetka −1, kondycja −1. Drogo: samopoczucie +2. Składniki, „nieważne”: te same minusy co tanio. „Pilnuję”: zdrowie +3, zęby +1, sylwetka +2, kondycja +2. Dieta wege/wegańska nie ma liczbowego wpływu, tylko tekst.

| Statystyka | Typ / zakres | Gdzie zapisana | Co ją zmienia | Gdzie używana | Pokazana graczowi | Rekomendacja |
| --- | --- | --- | --- | --- | --- | --- |
| Samopoczucie | plus całkowity na danie albo suwak | tylko słowniki wpływu w module jedzenia | Suwaki i pozycje jedzenia, jak wyżej. Nie psychika. | Tekst i kolory na ekranie jedzenia (`_bb_wplywu_pozycji`, `tekst_zbiorczych`). | Tylko tam, jako plusy. Nie na pasku ani postaci. | Nie pokazywać w statystykach bohatera, dopóki tura nie doda tego do psychiki albo osobnego pola. |
| Zdrowie (plus z talerza) | plus całkowity | j.w. | Suwak składników i ceny. Nie `bohater.zdrowie`. | Ekran jedzenia. | Nie jako liczba bohatera. | Nie mieszać ze skrótem zdrowia. Albo podpiąć turę, albo zostawić opisem dania. |
| Zęby | plus całkowity | j.w. | Suwaki ceny i składników. | Ekran jedzenia. | Nie. | Nie pokazywać w UI bohatera, dopóki nie ma pola i tury. |
| Sylwetka (plus z talerza) | plus całkowity | j.w. | Pozycje i suwaki. Nie `bohater.sylwetka.punkty`. | Ekran jedzenia. | Nie. Osobno widać etapy sylwetki. | Nie pokazywać obok prawdziwej sylwetki pod tą samą nazwą. |
| Kondycja (plus z talerza) | plus całkowity | j.w. | Suwaki. Nie `bohater.kondycja`. | Ekran jedzenia. | Nie. Kondycja z koła jest osobno. | Nie pokazywać pod nazwą „kondycja”. |
| Zadowolenie rodziców | licznik spadków, nie 0–100 | `_zbicie_zatwierdzone` w module jedzenia i w zrzucie `zbicie` | `zatwierdz` i jedzenie poza domem: `_nalicz_spadek`. Domyślnie −1, nadopiekuńczy 3 albo 4. Po progu przyzwyczajenia spadek może stanąć (`po_ilu_razach_spadek_znika` jest null, więc na razie zawsze). | Napis w ustawieniach jedzenia (`tekst_licznika`). | Nie na pasku ani postaci. | Zostawić przy jedzeniu w domu. Nie dawać do paska. |
| Zdrowe żywienie | suma plusów z `_wplyw_zjedzone` | moduł jedzenia, nie bohater | Każde zjedzenie pozycji z tym kluczem. | `odczyt_statystyk` → pasek. | Tak: „Zdrowe żywienie” w rozwinięciu. To nie jest liczba 1–100. | Nie pokazywać w „Wszystkich statystykach”, dopóki to tylko licznik plusów. Zostawić przy daniu. |

## Cechy

| Statystyka | Typ / zakres | Gdzie zapisana | Co ją zmienia | Gdzie używana | Pokazana graczowi | Rekomendacja |
| --- | --- | --- | --- | --- | --- | --- |
| Cechy charakteru | do 3 nazw z puli 41 | `bohater.cecha_1` … `cecha_3` | Tylko los. Waga każdej cechy = 1. | Dialogi, dojazd (hojny / oszczędny), spadki rodziców przy jedzeniu. | Tak, ekran postaci, blok „Cechy charakteru”. | Zostawić na postaci. |
| Inteligencje | do 3 nazw z 6 rodzajów, bez punktów | `bohater.inteligencja_1` … `inteligencja_3` | Tylko los. | Ekran postaci. | Tak, jeśli coś wylosowano. | Zostawić na postaci. Nie rysować jako IQ. |

Pula cech: `postacie/cechy_charakteru.json` (41). Rodzaje: językowa, logiczno-matematyczna, przestrzenna, pamięciowa, szybkość myślenia, muzyczna (`postacie/inteligencja.json`).

## Inne pola postaci

| Statystyka | Typ / zakres | Gdzie zapisana | Co ją zmienia | Gdzie używana | Pokazana graczowi | Rekomendacja |
| --- | --- | --- | --- | --- | --- | --- |
| Skrót zdrowia | tekst | `bohater.zdrowie_skrot` | Los chorób (`losowanie.gd` `_skrot_zdrowia`). Jedzenie nie. Praca pisze w `bohater.zdrowie` (liczba), którego zwykle nie ma, więc delta zdrowia z zawodu odpada. | Rozwinięty pasek, linia „Zdrowie”. | Tak, tekst. | Zostawić. Nie udawać, że to wynik jedzenia. |
| Wygląd | nazwa z losu | `bohater.wyglad_naturalny` | Tylko los. Kolumna „Wygląd” w tabeli zawodów (`postacie/katalog_zawodow_lista.md`) nie jest nakładana w `_zastosuj_efekty`. | Rozwinięty pasek. | Tak. | Zostawić w rozwinięciu. |
| Sylwetka | etap 0–4 i punkty 0–100 | `bohater.sylwetka` `{etap, punkty}` | Praca dodaje `efekty_tygodniowe.sylwetka` do punktów (clamp 0–100). Nie przelicza etapu. Jedzenie nie. Regres z `sylwetka.json` nie jest wołany w turze. | Ekran postaci: nazwa etapu i pasek (`ekran_fali2.gd` `_pasek_sylwetki`). Rozwinięcie pokazuje nazwę pola, często słabo. | Tak, na postaci. | Zostawić na postaci. W rozwinięciu pokazać etap i punkty, nie surowy słownik. |
| Wiedza | liczba, stub | `bohater.wiedza_pkt` | Korepetycje. Start zwykle 0. | `skutecznosc` (`wiedza/20`, sufit 1). Ekran postaci. | Tak, „Wiedza (pkt stub)”, gdy pole jest liczbą. | Zostawić na postaci, bez słówka „stub”, gdy mechanika zostanie. |
| Inteligencja emocjonalna | liczba, start ok. 28–55 | `bohater.inteligencja_emocjonalna` | Imprezy, terapia, hejt — wg `postacie/inteligencja_emocjonalna.json` (progi 35 / 55 / 75). | Ekran postaci (`inteligencja_emocjonalna.gd` `tekst`). | Tak, gdy tekst niepusty. | Zostawić na postaci. |
| Zainteresowanie | nazwa | `bohater.zainteresowanie` | Los, później doprecyzowanie. | Ekran postaci. | Tak. | Zostawić na postaci. |
| Depresja | flaga i etap | `bohater.depresja`, `depresja_etap` | Psychika &lt; 0 przez 4 tury włącza flagę. `depresja.gd` `tydzien` liczy etapy, jeśli ktoś go woła. | Ekran postaci. | Tak, gdy jest tekst albo flaga. | Zostawić na postaci, nie na pasku. |
| Zadowolenie docelowe | liczba 0–100 | `bohater.zadowolenie_docelowe` | `przelicz_zadowolenie_docelowe` (wygoda lokum, nie jedzenie). Psychika co turę dryfuje w tę stronę. | Linia „Docelowe (dev)”. | Tak, bo `scripts/statystyki_dostep.gd` ma `POKAZ_STATYSTYKI = true`. | Nie pokazywać graczowi. Zostawić pod flagą wyłączoną. |
| Wprawa gotowania | etap i punkty 0–100 | obiekt `WprawaGotowania`, nie pole bohatera w turze | `zastosuj_tydzien` (plus za dni, regres gdy 0 dni). Nic tego nie woła w `_on_nastepna_tura`. | Napis na ekranie jedzenia (`tekst_stanu`). Koszt energii i czasu jest tylko w tym napisie. | Tak, lokalnie przy gotowaniu. | Zostawić przy gotowaniu. Nie dawać na pasek, dopóki tura tego nie rusza. |

Panel „Statystyki” (`statystyki_panel.gd`) edytuje suwaki jedzenia, diety, zadowolenie rodziców i kwotę z `odczyt_statystyk`. To nie jest lista statystyk bohatera.
