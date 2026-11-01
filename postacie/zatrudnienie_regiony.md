# Zatrudnienie według regionu

Ta tabela jest źródłem do późniejszego podpięcia ofert pracy. Liczba ofert w mieście zostaje od liczby mieszkańców: 412 mieszkańców na jedną ofertę. Ten plik zmienia tylko skład ofert, nie ich liczbę. Miasto w województwie śląskim dostaje miks śląski z tablicy miejsca zamieszkania. Metropolia, która ma własny wiersz w tej samej tablicy, dostaje skład sekcji z tego wiersza zamiast składu województwa, bez drugiej korekty na wierzchu. Gmina GZM bez własnego wiersza zostaje przy miksie śląskim i nie dziedziczy Katowic. Chrzanów leży w małopolskim i nie dostaje miksu Krakowa.

Nie ma tu mnożnika 0,85–1,15 ani żadnej innej jednej liczby na wszystkie zawody. Czego nie było w tabeli, jest null.

## 1. Wielkie grupy, cały kraj

Eurostat, badanie siły roboczej, zbiór `lfsa_egai2d`, Polska, rok 2024, rocznie, osoby w wieku 15–74 lat, ogółem, tysiące osób. DOI 10.2908/lfsa_egai2d. Adres: https://ec.europa.eu/eurostat/databrowser/view/lfsa_egai2d/default/table

Ogółem publikowane: 17190,5 tys. Brak odpowiedzi (nie jest zawodem): 129,2 tys. Suma grup 0–9: 17061,1 tys. To jest mianownik losowania grupy. Udział w tabeli jest liczony z tych tysięcy i zaokrąglony do 1 miejsca; do wagi brać tysiące.

| Kod | Wielka grupa | Tysiące | Udział w grupach 0–9, % |
| --- | --- | ---: | ---: |
| 0 | Siły zbrojne | 158,3 | 0,9 |
| 1 | Kierownicy | 1259,4 | 7,4 |
| 2 | Specjaliści | 4062,0 | 23,8 |
| 3 | Technicy i inny średni personel | 2332,0 | 13,7 |
| 4 | Pracownicy biurowi | 1356,3 | 7,9 |
| 5 | Pracownicy usług i sprzedawcy | 2140,1 | 12,5 |
| 6 | Rolnicy, ogrodnicy, leśnicy i rybacy | 1024,9 | 6,0 |
| 7 | Robotnicy przemysłowi i rzemieślnicy | 2436,7 | 14,3 |
| 8 | Operatorzy i monterzy maszyn i urządzeń | 1561,2 | 9,2 |
| 9 | Pracownicy wykonujący prace proste | 730,2 | 4,3 |

## 2. Wewnątrz grupy

Najgłębszy wspólny poziom z tą samą populacją co wielkie grupy to 2 cyfry ISCO-08, ten sam zbiór Eurostatu. Publiczny zbiór nie schodzi do 3 ani 4 cyfr. Osobno GUS opublikował 4-cyfrowe grupy elementarne KZiS, ale dla innej populacji.

Liczebności 6-cyfrowych zawodów KZiS nie są w żadnej z tych tabel. Pole zostaje puste. Nazwy 6-cyfrowe poniżej opublikowanego poziomu losuje się równomiernie. Nie dotyczy to kodów, które na opublikowanym poziomie istnieją, ale nie dostały liczby (OC63, OC95, luki w sumie): tych miejsc nie wolno wypełniać.

### 2 cyfry, Eurostat 2024

Flaga „niska” = Eurostat `low reliability`. „brak” = liczby nie opublikowano.

| Kod | Nazwa | Tysiące | Udział w wielkiej grupie, % | Flaga |
| --- | --- | ---: | ---: | --- |
| 01 | Oficerowie sił zbrojnych | 30,2 | 19,1 |  |
| 02 | Podoficerowie sił zbrojnych | 50,3 | 31,8 |  |
| 03 | Żołnierze szeregowi | 72,0 | 45,5 |  |
| 11 | Przedstawiciele władz publicznych, wyżsi urzędnicy i dyrektorzy generalni | 233,9 | 18,6 |  |
| 12 | Kierownicy do spraw zarządzania i handlu | 344,3 | 27,3 |  |
| 13 | Kierownicy do spraw produkcji i usług | 393,4 | 31,2 |  |
| 14 | Kierownicy w branży hotelarskiej, handlu i innych branżach usługowych | 286,0 | 22,7 |  |
| 21 | Specjaliści nauk fizycznych, matematycznych i technicznych | 574,0 | 14,1 |  |
| 22 | Specjaliści do spraw zdrowia | 632,7 | 15,6 |  |
| 23 | Specjaliści nauczania i wychowania | 876,5 | 21,6 |  |
| 24 | Specjaliści do spraw ekonomicznych i zarządzania | 1097,2 | 27,0 |  |
| 25 | Specjaliści do spraw technologii informacyjno-komunikacyjnych | 480,1 | 11,8 |  |
| 26 | Specjaliści z dziedziny prawa, dziedzin społecznych i kultury | 399,6 | 9,8 |  |
| 31 | Średni personel nauk fizycznych, chemicznych i technicznych | 621,7 | 26,7 |  |
| 32 | Średni personel do spraw zdrowia | 218,5 | 9,4 |  |
| 33 | Średni personel do spraw biznesu i administracji | 1120,2 | 48,0 |  |
| 34 | Średni personel z dziedziny prawa, spraw społecznych, kultury i pokrewny | 263,0 | 11,3 |  |
| 35 | Technicy informatycy | 108,6 | 4,7 |  |
| 41 | Sekretarki, operatorzy urządzeń biurowych i pokrewni | 615,1 | 45,4 |  |
| 42 | Pracownicy obsługi klienta | 155,0 | 11,4 |  |
| 43 | Pracownicy do spraw finansowo-statystycznych i ewidencji materiałowej | 509,8 | 37,6 |  |
| 44 | Pozostali pracownicy obsługi biura | 76,2 | 5,6 |  |
| 51 | Pracownicy usług osobistych | 500,3 | 23,4 |  |
| 52 | Sprzedawcy i pokrewni | 1179,3 | 55,1 |  |
| 53 | Pracownicy opieki osobistej i pokrewni | 208,6 | 9,7 |  |
| 54 | Pracownicy usług ochrony | 251,8 | 11,8 |  |
| 61 | Rolnicy produkcji towarowej | 1006,3 | 98,2 |  |
| 62 | Leśnicy i rybacy | 15,9 | 1,6 | niska |
| 63 | Rolnicy i rybacy pracujący na własne potrzeby | brak | brak | niska |
| 71 | Robotnicy budowlani i pokrewni (z wyłączeniem elektryków) | 927,7 | 38,1 |  |
| 72 | Robotnicy obróbki metali, mechanicy maszyn i urządzeń | 710,3 | 29,2 |  |
| 73 | Rzemieślnicy i robotnicy poligraficzni | 71,3 | 2,9 |  |
| 74 | Elektrycy i elektronicy | 242,8 | 10,0 |  |
| 75 | Robotnicy w przetwórstwie spożywczym, obróbce drewna, produkcji wyrobów tekstylnych i pokrewni | 484,4 | 19,9 |  |
| 81 | Operatorzy maszyn i urządzeń wydobywczych i przetwórczych | 462,0 | 29,6 |  |
| 82 | Monterzy | 146,4 | 9,4 |  |
| 83 | Kierowcy i operatorzy pojazdów | 952,2 | 61,0 |  |
| 91 | Pomoce domowe i sprzątaczki | 311,7 | 42,7 |  |
| 92 | Robotnicy wykonujący prace proste w rolnictwie, leśnictwie i rybactwie | 36,9 | 5,1 |  |
| 93 | Robotnicy wykonujący prace proste w górnictwie, przemyśle, budownictwie i transporcie | 204,1 | 28,0 |  |
| 94 | Pracownicy wykonujący prace proste związane z przygotowywaniem posiłków | 73,9 | 10,1 |  |
| 95 | Sprzedawcy uliczni i pracownicy świadczący usługi na ulicach | brak | brak | niska |
| 96 | Ładowacze nieczystości i inni pracownicy wykonujący prace proste | 101,0 | 13,8 |  |

Luka między wielką grupą a sumą jej opublikowanych podgrup (tysiące, po zaokrągleniu składników do 0,1): grupa 0: 5,8; grupa 1: 1,8; grupa 2: 1,9; grupa 6: 2,7 (w tym cały brakujący OC63); grupa 8: 0,6; grupa 9: 2,6 (w tym cały brakujący OC95). Grupy 3, 4, 5 i 7 mieszczą się w 0,2 tys. Luki nie przypisano do żadnego kodu.

Grupa 0: wewnątrz użyć wierszy 01, 02 i 03. Wiersz GUS `000X` (167 305 osób, siły zbrojne łącznie, 31.12.2024) nie rozbija tej grupy.

Grupa 6: wewnątrz użyć tylko wierszy 61 i 62. OC63 nie ma liczby. Nie używać 4 cyfr z następnej tabeli. Ta następna tabela ma w grupie 6 tylko 61 387 osób, bo wycina gospodarstwa indywidualne, a Eurostat ma w grupie 6 1024,9 tys.

### 4 cyfry, GUS, stan na 31.12.2024

Publikacja „Zróżnicowanie zawodów na rynku pracy w Polsce”, strona https://stat.gov.pl/statystyki-eksperymentalne/kapital-ludzki/zroznicowanie-zawodow-na-rynku-pracy-w-polsce,18,1.html (data na stronie 02.07.2026). Arkusz „Struktura zawodowa i charakterystyka demograficzna pracujących w gospodarce narodowej”. Kody według KZiS na 1.01.2023. Populacja: pracujący w gospodarce narodowej bez gospodarstw indywidualnych w rolnictwie. Suma kolumny Ogółem: 13 956 473 osób. Strona GUS mówi o 14,1 mln; do tej sumy nic nie dodawano.

Zero w kolumnie udziału w arkuszu znaczy „mniej niż 0,1%”, nie zero osób. Waga wewnątrz grupy to liczba osób, nie ten zaokrąglony udział. Dla grup 1–5 i 7–9 ta waga jest do użycia po wylosowaniu wielkiej grupy z Eurostatu. Dla grup 0 i 6 wiersze są przepisane, ale nie są wagą losowania.

Dwie pary GUS skleił, bo kody były używane zamiennie: 5223 z 5230 oraz 9312 z 9313. Pary nie dzielić po połowie.

| Kody | Nazwa | Wielka grupa | Osoby | Udział w wielkiej grupie tej tabeli, % | Użyć jako wagi |
| --- | --- | ---: | ---: | ---: | --- |
| 1111 | Przedstawiciele władz publicznych | 1 | 4 140 | 0,5 | tak |
| 1112 | Wyżsi urzędnicy administracji rządowej | 1 | 16 959 | 1,9 | tak |
| 1113 | Wyżsi urzędnicy władz samorządowych | 1 | 37 202 | 4,2 | tak |
| 1114 | Zawodowi działacze organizacji członkowskich | 1 | 713 | 0,1 | tak |
| 1120 | Dyrektorzy generalni i zarządzający | 1 | 134 280 | 15,2 | tak |
| 1211 | Kierownicy do spraw finansowych | 1 | 50 560 | 5,7 | tak |
| 1212 | Kierownicy do spraw zarządzania zasobami ludzkimi | 1 | 20 269 | 2,3 | tak |
| 1213 | Kierownicy do spraw strategii i planowania | 1 | 42 636 | 4,8 | tak |
| 1219 | Kierownicy do spraw obsługi biznesu i zarządzania gdzie indziej niesklasyfikowani | 1 | 73 461 | 8,3 | tak |
| 1221 | Kierownicy do spraw marketingu i sprzedaży | 1 | 54 815 | 6,2 | tak |
| 1222 | Kierownicy do spraw reklamy i public relations | 1 | 4 660 | 0,5 | tak |
| 1223 | Kierownicy do spraw badań i rozwoju | 1 | 8 069 | 0,9 | tak |
| 1311 | Kierownicy produkcji w rolnictwie i leśnictwie | 1 | 3 297 | 0,4 | tak |
| 1312 | Kierownicy produkcji w zakładach akwakultury i rybołówstwie | 1 | 417 | 0,0 | tak |
| 1321 | Kierownicy do spraw produkcji przemysłowej | 1 | 62 162 | 7,0 | tak |
| 1322 | Kierownicy w górnictwie | 1 | 1 988 | 0,2 | tak |
| 1323 | Kierownicy do spraw budownictwa | 1 | 40 941 | 4,6 | tak |
| 1324 | Kierownicy do spraw logistyki i dziedzin pokrewnych | 1 | 58 773 | 6,7 | tak |
| 1330 | Kierownicy do spraw technologii informatycznych i telekomunikacyjnych | 1 | 13 047 | 1,5 | tak |
| 1341 | Kierownicy w instytucjach opieki nad dziećmi | 1 | 5 477 | 0,6 | tak |
| 1342 | Kierownicy w instytucjach opieki zdrowotnej | 1 | 19 958 | 2,3 | tak |
| 1343 | Kierownicy w instytucjach opieki nad osobami starszymi | 1 | 886 | 0,1 | tak |
| 1344 | Kierownicy w instytucjach pomocy społecznej | 1 | 3 713 | 0,4 | tak |
| 1345 | Kierownicy w instytucjach edukacyjnych | 1 | 4 800 | 0,5 | tak |
| 1346 | Kierownicy w instytucjach finansowych i ubezpieczeniowych | 1 | 14 103 | 1,6 | tak |
| 1349 | Kierownicy w instytucjach usług wyspecjalizowanych gdzie indziej niesklasyfikowani | 1 | 16 107 | 1,8 | tak |
| 1411 | Kierownicy w hotelarstwie | 1 | 8 049 | 0,9 | tak |
| 1412 | Kierownicy w gastronomii | 1 | 20 508 | 2,3 | tak |
| 1420 | Kierownicy w handlu detalicznym i hurtowym | 1 | 48 865 | 5,5 | tak |
| 1431 | Kierownicy do spraw sportu, rekreacji i rozrywki | 1 | 6 302 | 0,7 | tak |
| 1439 | Kierownicy do spraw innych typów usług gdzie indziej niesklasyfikowani | 1 | 105 307 | 11,9 | tak |
| 2111 | Fizycy i astronomowie | 2 | 2 390 | 0,1 | tak |
| 2112 | Meteorolodzy | 2 | 582 | 0,0 | tak |
| 2113 | Chemicy | 2 | 9 290 | 0,3 | tak |
| 2114 | Specjaliści nauk o Ziemi | 2 | 4 499 | 0,1 | tak |
| 2120 | Matematycy, aktuariusze i statystycy | 2 | 3 715 | 0,1 | tak |
| 2131 | Biolodzy i pokrewni | 2 | 8 420 | 0,3 | tak |
| 2132 | Specjaliści w zakresie rolnictwa, leśnictwa i pokrewni | 2 | 17 611 | 0,5 | tak |
| 2133 | Specjaliści do spraw ochrony środowiska | 2 | 12 438 | 0,4 | tak |
| 2141 | Inżynierowie do spraw przemysłu i produkcji | 2 | 66 821 | 2,0 | tak |
| 2142 | Inżynierowie budownictwa | 2 | 66 434 | 2,0 | tak |
| 2143 | Inżynierowie inżynierii środowiska | 2 | 14 792 | 0,4 | tak |
| 2144 | Inżynierowie mechanicy | 2 | 34 637 | 1,0 | tak |
| 2145 | Inżynierowie chemicy i pokrewni | 2 | 5 466 | 0,2 | tak |
| 2146 | Inżynierowie górnictwa i metalurgii | 2 | 7 654 | 0,2 | tak |
| 2149 | Inżynierowie gdzie indziej niesklasyfikowani | 2 | 53 850 | 1,6 | tak |
| 2151 | Inżynierowie elektrycy | 2 | 23 928 | 0,7 | tak |
| 2152 | Inżynierowie elektronicy | 2 | 14 426 | 0,4 | tak |
| 2153 | Inżynierowie telekomunikacji | 2 | 10 112 | 0,3 | tak |
| 2161 | Architekci | 2 | 36 022 | 1,1 | tak |
| 2162 | Architekci krajobrazu | 2 | 2 193 | 0,1 | tak |
| 2163 | Projektanci wzornictwa przemysłowego i odzieży | 2 | 7 096 | 0,2 | tak |
| 2164 | Urbaniści i inżynierowie ruchu drogowego | 2 | 3 363 | 0,1 | tak |
| 2165 | Kartografowie i geodeci | 2 | 18 875 | 0,6 | tak |
| 2166 | Projektanci grafiki i multimediów | 2 | 33 242 | 1,0 | tak |
| 2211 | Lekarze bez specjalizacji, w trakcie specjalizacji lub ze specjalizacją I stopnia | 2 | 54 985 | 1,6 | tak |
| 2212 | Lekarze specjaliści (ze specjalizacją II stopnia lub tytułem specjalisty) | 2 | 86 700 | 2,6 | tak |
| 2221 | Pielęgniarki bez specjalizacji lub w trakcie specjalizacji | 2 | 73 902 | 2,2 | tak |
| 2222 | Pielęgniarki z tytułem specjalisty | 2 | 23 705 | 0,7 | tak |
| 2231 | Położne bez specjalizacji lub w trakcie specjalizacji | 2 | 7 809 | 0,2 | tak |
| 2232 | Położne z tytułem specjalisty | 2 | 3 070 | 0,1 | tak |
| 2240 | Specjaliści do spraw ratownictwa medycznego | 2 | 1 661 | 0,0 | tak |
| 2251 | Lekarze weterynarii bez specjalizacji lub w trakcie specjalizacji | 2 | 7 477 | 0,2 | tak |
| 2252 | Lekarze weterynarii specjaliści | 2 | 2 404 | 0,1 | tak |
| 2261 | Lekarze dentyści bez specjalizacji, w trakcie specjalizacji lub ze specjalizacją I stopnia | 2 | 21 812 | 0,7 | tak |
| 2262 | Lekarze dentyści specjaliści (ze specjalizacją II stopnia lub tytułem specjalisty) | 2 | 10 134 | 0,3 | tak |
| 2271 | Diagności laboratoryjni bez specjalizacji lub w trakcie specjalizacji | 2 | 5 238 | 0,2 | tak |
| 2272 | Diagności laboratoryjni specjaliści | 2 | 1 612 | 0,0 | tak |
| 2281 | Farmaceuci bez specjalizacji lub w trakcie specjalizacji | 2 | 11 757 | 0,4 | tak |
| 2282 | Farmaceuci specjaliści | 2 | 11 429 | 0,3 | tak |
| 2291 | Specjaliści do spraw higieny, bezpieczeństwa pracy i ochrony środowiska | 2 | 8 300 | 0,2 | tak |
| 2292 | Fizjoterapeuci | 2 | 57 343 | 1,7 | tak |
| 2293 | Dietetycy i specjaliści do spraw żywienia | 2 | 2 152 | 0,1 | tak |
| 2294 | Audiofonolodzy i logopedzi | 2 | 6 232 | 0,2 | tak |
| 2295 | Optometryści | 2 | 2 168 | 0,1 | tak |
| 2299 | Specjaliści ochrony zdrowia gdzie indziej niesklasyfikowani | 2 | 39 221 | 1,2 | tak |
| 2310 | Nauczyciele akademiccy | 2 | 94 917 | 2,8 | tak |
| 2320 | Nauczyciele kształcenia zawodowego | 2 | 18 238 | 0,5 | tak |
| 2330 | Nauczyciele szkół ponadpodstawowych (z wyjątkiem nauczycieli kształcenia zawodowego) | 2 | 155 435 | 4,6 | tak |
| 2341 | Nauczyciele szkół podstawowych | 2 | 360 107 | 10,8 | tak |
| 2342 | Specjaliści do spraw wychowania małego dziecka | 2 | 122 200 | 3,6 | tak |
| 2351 | Wizytatorzy i specjaliści metod nauczania | 2 | 5 984 | 0,2 | tak |
| 2352 | Nauczyciele pracujący z osobami o specjalnych potrzebach edukacyjnych | 2 | 20 755 | 0,6 | tak |
| 2353 | Lektorzy języków obcych | 2 | 11 996 | 0,4 | tak |
| 2354 | Nauczyciele muzyki w placówkach pozaszkolnych  | 2 | 2 313 | 0,1 | tak |
| 2355 | Nauczyciele sztuki w placówkach pozaszkolnych | 2 | 3 063 | 0,1 | tak |
| 2356 | Instruktorzy technologii informatycznych | 2 | 465 | 0,0 | tak |
| 2359 | Specjaliści nauczania i wychowania gdzie indziej niesklasyfikowani | 2 | 86 287 | 2,6 | tak |
| 2411 | Specjaliści do spraw księgowości i rachunkowości | 2 | 94 061 | 2,8 | tak |
| 2412 | Doradcy finansowi i inwestycyjni | 2 | 24 743 | 0,7 | tak |
| 2413 | Analitycy finansowi | 2 | 97 338 | 2,9 | tak |
| 2421 | Specjaliści do spraw zarządzania i organizacji | 2 | 125 881 | 3,8 | tak |
| 2422 | Specjaliści do spraw administracji i rozwoju | 2 | 118 770 | 3,5 | tak |
| 2423 | Specjaliści do spraw zarządzania zasobami ludzkimi | 2 | 98 984 | 3,0 | tak |
| 2424 | Specjaliści do spraw szkoleń zawodowych i rozwoju kadr | 2 | 9 861 | 0,3 | tak |
| 2431 | Specjaliści do spraw reklamy i marketingu | 2 | 122 518 | 3,7 | tak |
| 2432 | Specjaliści do spraw public relations | 2 | 7 157 | 0,2 | tak |
| 2433 | Specjaliści do spraw sprzedaży (z wyłączeniem technologii informacyjno- komunikacyjnych) | 2 | 175 103 | 5,2 | tak |
| 2434 | Specjaliści do spraw sprzedaży z dziedziny technologii teleinformatycznych | 2 | 4 278 | 0,1 | tak |
| 2440 | Specjaliści do spraw rynku nieruchomości | 2 | 32 934 | 1,0 | tak |
| 2511 | Analitycy systemów komputerowych | 2 | 39 218 | 1,2 | tak |
| 2512 | Specjaliści do spraw rozwoju systemów informatycznych | 2 | 38 630 | 1,2 | tak |
| 2513 | Projektanci aplikacji sieciowych i multimediów | 2 | 6 712 | 0,2 | tak |
| 2514 | Programiści aplikacji | 2 | 143 987 | 4,3 | tak |
| 2519 | Analitycy systemów komputerowych i programiści gdzie indziej niesklasyfikowani | 2 | 53 285 | 1,6 | tak |
| 2521 | Projektanci i administratorzy baz danych | 2 | 22 195 | 0,7 | tak |
| 2522 | Administratorzy systemów komputerowych | 2 | 18 263 | 0,5 | tak |
| 2523 | Specjaliści do spraw sieci komputerowych | 2 | 15 295 | 0,5 | tak |
| 2529 | Specjaliści do spraw baz danych i sieci komputerowych gdzie indziej niesklasyfikowani | 2 | 26 480 | 0,8 | tak |
| 2611 | Adwokaci, radcy prawni i prokuratorzy | 2 | 67 708 | 2,0 | tak |
| 2612 | Sędziowie | 2 | 10 048 | 0,3 | tak |
| 2619 | Specjaliści z dziedziny prawa gdzie indziej niesklasyfikowani | 2 | 37 509 | 1,1 | tak |
| 2621 | Archiwiści i muzealnicy | 2 | 8 698 | 0,3 | tak |
| 2622 | Bibliotekoznawcy i specjaliści zarządzania informacją | 2 | 9 141 | 0,3 | tak |
| 2631 | Ekonomiści | 2 | 38 874 | 1,2 | tak |
| 2632 | Archeolodzy, socjolodzy i specjaliści dziedzin pokrewnych | 2 | 2 297 | 0,1 | tak |
| 2633 | Filozofowie, historycy i politolodzy | 2 | 2 059 | 0,1 | tak |
| 2634 | Psycholodzy i pokrewni | 2 | 29 147 | 0,9 | tak |
| 2635 | Specjaliści do spraw społecznych | 2 | 11 110 | 0,3 | tak |
| 2636 | Duchowni i osoby konsekrowane | 2 | 25 004 | 0,7 | tak |
| 2641 | Literaci i inni autorzy tekstów | 2 | 5 407 | 0,2 | tak |
| 2642 | Dziennikarze | 2 | 12 628 | 0,4 | tak |
| 2643 | Filolodzy i tłumacze | 2 | 9 224 | 0,3 | tak |
| 2651 | Artyści plastycy | 2 | 6 273 | 0,2 | tak |
| 2652 | Kompozytorzy, artyści muzycy i śpiewacy | 2 | 5 882 | 0,2 | tak |
| 2653 | Choreografowie i tancerze | 2 | 700 | 0,0 | tak |
| 2654 | Producenci filmowi, reżyserzy i pokrewni | 2 | 5 203 | 0,2 | tak |
| 2655 | Aktorzy | 2 | 2 516 | 0,1 | tak |
| 2656 | Prezenterzy radiowi, telewizyjni i pokrewni | 2 | 1 535 | 0,0 | tak |
| 2659 | Twórcy i artyści gdzie indziej niesklasyfikowani | 2 | 3 015 | 0,1 | tak |
| 3111 | Technicy nauk chemicznych, fizycznych i pokrewni | 3 | 32 950 | 1,7 | tak |
| 3112 | Technicy budownictwa | 3 | 28 228 | 1,4 | tak |
| 3113 | Technicy elektrycy | 3 | 21 732 | 1,1 | tak |
| 3114 | Technicy elektronicy i pokrewni | 3 | 17 843 | 0,9 | tak |
| 3115 | Technicy mechanicy | 3 | 40 965 | 2,1 | tak |
| 3116 | Technicy technologii chemicznej i pokrewni | 3 | 3 749 | 0,2 | tak |
| 3117 | Technicy górnictwa, metalurgii i pokrewni | 3 | 6 912 | 0,4 | tak |
| 3118 | Kreślarze | 3 | 5 877 | 0,3 | tak |
| 3119 | Technicy nauk fizycznych i technicznych gdzie indziej niesklasyfikowani | 3 | 43 052 | 2,2 | tak |
| 3121 | Osoby dozoru ruchu w górnictwie | 3 | 3 962 | 0,2 | tak |
| 3122 | Mistrzowie produkcji w przemyśle przetwórczym | 3 | 15 374 | 0,8 | tak |
| 3123 | Mistrzowie produkcji w budownictwie | 3 | 4 541 | 0,2 | tak |
| 3131 | Operatorzy urządzeń energetycznych | 3 | 16 080 | 0,8 | tak |
| 3132 | Operatorzy urządzeń do spalania odpadów, uzdatniania wody i pokrewni | 3 | 11 383 | 0,6 | tak |
| 3133 | Kontrolerzy (sterowniczy) procesów w przemyśle chemicznym | 3 | 3 555 | 0,2 | tak |
| 3134 | Kontrolerzy (sterowniczy) procesów przeróbki ropy naftowej i gazu | 3 | 4 | 0,0 | tak |
| 3135 | Kontrolerzy (sterowniczy) procesów metalurgicznych | 3 | 204 | 0,0 | tak |
| 3139 | Kontrolerzy (sterowniczy) procesów przemysłowych gdzie indziej niesklasyfikowani | 3 | 11 474 | 0,6 | tak |
| 3141 | Technicy nauk biologicznych (z wyłączeniem nauk medycznych) | 3 | 6 164 | 0,3 | tak |
| 3142 | Technicy rolnictwa i pokrewni | 3 | 5 620 | 0,3 | tak |
| 3143 | Technicy leśnictwa | 3 | 11 333 | 0,6 | tak |
| 3144 | Technicy technologii żywności | 3 | 7 468 | 0,4 | tak |
| 3151 | Pracownicy służb technicznych żeglugi | 3 | 893 | 0,0 | tak |
| 3152 | Oficerowie pokładowi, piloci żeglugi i pokrewni | 3 | 1 416 | 0,1 | tak |
| 3153 | Piloci statków powietrznych i personel pokrewny | 3 | 6 954 | 0,4 | tak |
| 3154 | Kontrolerzy ruchu lotniczego i personel pokrewny | 3 | 2 492 | 0,1 | tak |
| 3155 | Technicy urządzeń ruchu lotniczego | 3 | 335 | 0,0 | tak |
| 3211 | Operatorzy aparatury medycznej | 3 | 15 438 | 0,8 | tak |
| 3212 | Technicy analityki medycznej | 3 | 11 623 | 0,6 | tak |
| 3213 | Technicy farmaceutyczni | 3 | 32 220 | 1,6 | tak |
| 3214 | Technicy medyczni i dentystyczni | 3 | 10 628 | 0,5 | tak |
| 3220 | Dietetycy i żywieniowcy | 3 | 8 941 | 0,5 | tak |
| 3230 | Praktykujący niekonwencjonalne lub komplementarne metody terapii | 3 | 4 288 | 0,2 | tak |
| 3240 | Technicy weterynarii | 3 | 5 451 | 0,3 | tak |
| 3251 | Asystenci dentystyczni | 3 | 23 448 | 1,2 | tak |
| 3252 | Środowiskowi pracownicy ochrony zdrowia | 3 | 1 434 | 0,1 | tak |
| 3253 | Optycy okularowi | 3 | 5 337 | 0,3 | tak |
| 3254 | Technicy fizjoterapii i masażyści | 3 | 14 085 | 0,7 | tak |
| 3255 | Średni personel ochrony środowiska, medycyny pracy i bhp | 3 | 21 106 | 1,1 | tak |
| 3256 | Ratownicy medyczni | 3 | 19 140 | 1,0 | tak |
| 3259 | Średni personel do spraw zdrowia gdzie indziej niesklasyfikowany | 3 | 26 496 | 1,3 | tak |
| 3311 | Dealerzy i maklerzy aktywów finansowych | 3 | 10 943 | 0,6 | tak |
| 3312 | Pracownicy do spraw kredytów, pożyczek i pokrewni | 3 | 12 230 | 0,6 | tak |
| 3313 | Księgowi | 3 | 211 968 | 10,7 | tak |
| 3314 | Średni personel do spraw statystyki i dziedzin pokrewnych | 3 | 6 300 | 0,3 | tak |
| 3315 | Rzeczoznawcy (z wyłączeniem majątkowych) | 3 | 5 462 | 0,3 | tak |
| 3321 | Agenci ubezpieczeniowi  | 3 | 33 912 | 1,7 | tak |
| 3322 | Przedstawiciele handlowi | 3 | 134 268 | 6,8 | tak |
| 3323 | Zaopatrzeniowcy | 3 | 28 363 | 1,4 | tak |
| 3324 | Pośrednicy handlowi | 3 | 21 289 | 1,1 | tak |
| 3331 | Spedytorzy i pokrewni | 3 | 95 051 | 4,8 | tak |
| 3332 | Organizatorzy konferencji i imprez | 3 | 5 045 | 0,3 | tak |
| 3333 | Pośrednicy pracy i zatrudnienia | 3 | 6 641 | 0,3 | tak |
| 3334 | Agenci i administratorzy nieruchomości | 3 | 15 105 | 0,8 | tak |
| 3339 | Pośrednicy usług biznesowych gdzie indziej niesklasyfikowani | 3 | 5 683 | 0,3 | tak |
| 3341 | Kierownicy biura | 3 | 27 446 | 1,4 | tak |
| 3342 | Sekretarze prawni | 3 | 1 166 | 0,1 | tak |
| 3343 | Pracownicy administracyjni i sekretarze biura zarządu | 3 | 244 453 | 12,4 | tak |
| 3344 | Sekretarze medyczni i pokrewni | 3 | 13 144 | 0,7 | tak |
| 3351 | Funkcjonariusze celni i ochrony granic | 3 | 30 539 | 1,5 | tak |
| 3352 | Urzędnicy do spraw podatków | 3 | 42 038 | 2,1 | tak |
| 3353 | Urzędnicy do spraw świadczeń społecznych | 3 | 29 324 | 1,5 | tak |
| 3354 | Urzędnicy organów udzielających licencji | 3 | 6 620 | 0,3 | tak |
| 3355 | Policjanci | 3 | 98 286 | 5,0 | tak |
| 3356 | Funkcjonariusze Służby Więziennej  | 3 | 27 427 | 1,4 | tak |
| 3357 | Funkcjonariusze służb specjalnych | 3 | 6 923 | 0,4 | tak |
| 3359 | Urzędnicy państwowi do spraw nadzoru gdzie indziej niesklasyfikowani | 3 | 15 616 | 0,8 | tak |
| 3411 | Średni personel z dziedziny prawa i pokrewny | 3 | 21 661 | 1,1 | tak |
| 3412 | Pracownicy wsparcia rodziny, pomocy społecznej i pracy socjalnej | 3 | 63 716 | 3,2 | tak |
| 3413 | Pracownicy z zakresu działalności religijnej | 3 | 531 | 0,0 | tak |
| 3421 | Sportowcy i dżokeje | 3 | 1 481 | 0,1 | tak |
| 3422 | Trenerzy, instruktorzy i działacze sportowi | 3 | 15 282 | 0,8 | tak |
| 3423 | Instruktorzy fitness i rekreacji ruchowej | 3 | 8 483 | 0,4 | tak |
| 3431 | Fotografowie | 3 | 12 639 | 0,6 | tak |
| 3432 | Plastycy, dekoratorzy wnętrz i pokrewni | 3 | 12 052 | 0,6 | tak |
| 3433 | Pracownicy bibliotek, galerii, muzeów, informacji naukowej i pokrewni | 3 | 22 610 | 1,1 | tak |
| 3434 | Szefowie kuchni i organizatorzy usług gastronomicznych | 3 | 9 568 | 0,5 | tak |
| 3435 | Aktorzy cyrkowi i pokrewni | 3 | 184 | 0,0 | tak |
| 3436 | Muzycy i pokrewni  | 3 | 3 776 | 0,2 | tak |
| 3437 |  Tancerze | 3 | 458 | 0,0 | tak |
| 3439 | Średni personel w zakresie działalności artystycznej i kulturalnej gdzie indziej niesklasyfikowany | 3 | 15 595 | 0,8 | tak |
| 3511 | Operatorzy urządzeń teleinformatycznych | 3 | 2 469 | 0,1 | tak |
| 3512 | Technicy wsparcia informatycznego i technicznego | 3 | 114 415 | 5,8 | tak |
| 3513 | Operatorzy sieci i systemów komputerowych | 3 | 3 841 | 0,2 | tak |
| 3514 | Technicy sieci internetowych | 3 | 7 255 | 0,4 | tak |
| 3521 | Operatorzy urządzeń do rejestracji i transmisji obrazu i dźwięku | 3 | 9 552 | 0,5 | tak |
| 3522 | Operatorzy urządzeń telekomunikacyjnych | 3 | 3 327 | 0,2 | tak |
| 4110 | Pracownicy obsługi biurowej | 4 | 226 790 | 19,2 | tak |
| 4120 | Sekretarki (ogólne) | 4 | 61 592 | 5,2 | tak |
| 4131 | Operatorzy edytorów tekstu | 4 | 1 362 | 0,1 | tak |
| 4132 | Operatorzy wprowadzania danych | 4 | 3 282 | 0,3 | tak |
| 4211 | Kasjerzy bankowi i pokrewni  | 4 | 34 946 | 3,0 | tak |
| 4212 | Bukmacherzy, krupierzy i pokrewni | 4 | 6 578 | 0,6 | tak |
| 4213 | Pracownicy lombardów i instytucji pożyczkowych | 4 | 779 | 0,1 | tak |
| 4214 | Windykatorzy i pokrewni | 4 | 9 811 | 0,8 | tak |
| 4221 | Konsultanci i inni pracownicy biur podróży | 4 | 9 044 | 0,8 | tak |
| 4222 | Pracownicy centrów obsługi telefonicznej (pracownicy call center) | 4 | 26 564 | 2,2 | tak |
| 4223 | Operatorzy centrali telefonicznych | 4 | 1 797 | 0,2 | tak |
| 4224 | Recepcjoniści hotelowi | 4 | 13 014 | 1,1 | tak |
| 4225 | Pracownicy biur informacji | 4 | 7 840 | 0,7 | tak |
| 4226 | Recepcjoniści (z wyłączeniem hotelowych) | 4 | 59 611 | 5,0 | tak |
| 4227 | Ankieterzy | 4 | 1 782 | 0,2 | tak |
| 4311 | Pracownicy do spraw rachunkowości i księgowości | 4 | 69 704 | 5,9 | tak |
| 4312 | Pracownicy do spraw statystyki, finansów i ubezpieczeń | 4 | 13 422 | 1,1 | tak |
| 4313 | Pracownicy obsługi płacowej | 4 | 8 052 | 0,7 | tak |
| 4321 | Magazynierzy i pokrewni | 4 | 372 023 | 31,5 | tak |
| 4322 | Planiści produkcyjni | 4 | 14 212 | 1,2 | tak |
| 4323 | Pracownicy do spraw transportu | 4 | 23 911 | 2,0 | tak |
| 4411 | Pomocnicy biblioteczni | 4 | 1 011 | 0,1 | tak |
| 4412 | Listonosze i pokrewni | 4 | 39 954 | 3,4 | tak |
| 4413 | Kodowacze, korektorzy i pokrewni | 4 | 583 | 0,0 | tak |
| 4414 | Technicy archiwiści i pokrewni  | 4 | 3 085 | 0,3 | tak |
| 4415 | Pracownicy działów kadr | 4 | 25 905 | 2,2 | tak |
| 4419 | Pracownicy obsługi biura gdzie indziej niesklasyfikowani | 4 | 145 167 | 12,3 | tak |
| 5111 | Stewardzi | 5 | 4 463 | 0,2 | tak |
| 5112 | Konduktorzy i pokrewni | 5 | 7 354 | 0,4 | tak |
| 5113 | Przewodnicy turystyczni i piloci wycieczek | 5 | 2 619 | 0,1 | tak |
| 5120 | Kucharze | 5 | 121 212 | 6,3 | tak |
| 5131 | Kelnerzy | 5 | 36 455 | 1,9 | tak |
| 5132 | Barmani | 5 | 9 655 | 0,5 | tak |
| 5141 | Fryzjerzy | 5 | 92 410 | 4,8 | tak |
| 5142 | Kosmetyczki i pokrewni | 5 | 63 115 | 3,3 | tak |
| 5151 | Pracownicy obsługi technicznej biur, hoteli i innych obiektów | 5 | 22 195 | 1,2 | tak |
| 5152 | Pracownicy usług domowych | 5 | 17 015 | 0,9 | tak |
| 5153 | Gospodarze budynków | 5 | 70 636 | 3,7 | tak |
| 5161 | Astrolodzy, wróżbici i pokrewni | 5 | 353 | 0,0 | tak |
| 5162 | Osoby do towarzystwa | 5 | 13 | 0,0 | tak |
| 5163 | Pracownicy zakładów pogrzebowych | 5 | 4 101 | 0,2 | tak |
| 5164 | Opiekunowie zwierząt i pracownicy zajmujący się zwierzętami | 5 | 7 728 | 0,4 | tak |
| 5165 | Instruktorzy nauki jazdy | 5 | 5 499 | 0,3 | tak |
| 5169 |  Pracownicy usług osobistych gdzie indziej niesklasyfikowani | 5 | 15 558 | 0,8 | tak |
| 5211 | Sprzedawcy na targowiskach i bazarach | 5 | 21 628 | 1,1 | tak |
| 5212 | Uliczni sprzedawcy żywności | 5 | 1 395 | 0,1 | tak |
| 5221 | Właściciele sklepów | 5 | 86 958 | 4,5 | tak |
| 5222 | Kierownicy sprzedaży w marketach | 5 | 26 611 | 1,4 | tak |
| 5223+5230 | Sprzedawcy sklepowi (ekspedienci) oraz kasjerzy i sprzedawcy biletów | 5 | 747 570 | 38,9 | tak |
| 5241 | Modelki i modele | 5 | 167 | 0,0 | tak |
| 5242 | Demonstratorzy wyrobów | 5 | 783 | 0,0 | tak |
| 5243 | Agenci sprzedaży bezpośredniej | 5 | 20 939 | 1,1 | tak |
| 5244 | Sprzedawcy (konsultanci) w centrach sprzedaży telefonicznej / | 5 | 21 353 | 1,1 | tak |
| 5245 | Sprzedawcy w stacji paliw | 5 | 29 659 | 1,5 | tak |
| 5246 | Wydawcy posiłków | 5 | 3 707 | 0,2 | tak |
| 5249 | Pracownicy sprzedaży i pokrewni gdzie indziej niesklasyfikowani | 5 | 156 474 | 8,1 | tak |
| 5311 | Opiekunowie dziecięcy | 5 | 37 754 | 2,0 | tak |
| 5312 | Asystenci nauczycieli | 5 | 48 691 | 2,5 | tak |
| 5321 | Pomocniczy personel medyczny | 5 | 27 065 | 1,4 | tak |
| 5322 | Pracownicy domowej opieki osobistej | 5 | 3 456 | 0,2 | tak |
| 5329 | Pracownicy opieki osobistej w ochronie zdrowia i pokrewni gdzie indziej niesklasyfikowani | 5 | 20 980 | 1,1 | tak |
| 5411 | Strażacy | 5 | 35 011 | 1,8 | tak |
| 5412 | Strażnicy w zakładach dla nieletnich | 5 | 408 | 0,0 | tak |
| 5413 | Pracownicy ochrony osób i mienia | 5 | 137 331 | 7,2 | tak |
| 5419 | Pracownicy usług ochrony gdzie indziej niesklasyfikowani | 5 | 12 215 | 0,6 | tak |
| 6111 | Rolnicy upraw polowych | 6 | 4 317 | 7,0 | nie |
| 6112 | Sadownicy | 6 | 461 | 0,8 | nie |
| 6113 | Ogrodnicy | 6 | 19 059 | 31,0 | nie |
| 6114 | Rolnicy upraw mieszanych | 6 | 1 739 | 2,8 | nie |
| 6121 | Hodowcy zwierząt gospodarskich i domowych | 6 | 2 562 | 4,2 | nie |
| 6122 | Hodowcy drobiu | 6 | 2 483 | 4,0 | nie |
| 6123 | Pszczelarze i hodowcy jedwabników | 6 | 168 | 0,3 | nie |
| 6129 | Hodowcy zwierząt gdzie indziej niesklasyfikowani | 6 | 404 | 0,7 | nie |
| 6130 | Rolnicy produkcji roślinnej i zwierzęcej | 6 | 7 924 | 12,9 | nie |
| 6210 | Robotnicy leśni i pokrewni | 6 | 17 375 | 28,3 | nie |
| 6221 | Hodowcy ryb | 6 | 259 | 0,4 | nie |
| 6222 | Rybacy śródlądowi | 6 | 711 | 1,2 | nie |
| 6223 | Rybacy morscy | 6 | 674 | 1,1 | nie |
| 6310 | Rolnicy produkcji roślinnej pracujący na własne potrzeby | 6 | 96 | 0,2 | nie |
| 6320 | Hodowcy zwierząt pracujący na własne potrzeby | 6 | 63 | 0,1 | nie |
| 6330 | Rolnicy produkcji roślinnej i zwierzęcej pracujący na własne potrzeby | 6 | 2 529 | 4,1 | nie |
| 6340 | Rybacy i zbieracze pracujący na własne potrzeby | 6 | 563 | 0,9 | nie |
| 7111 | Monterzy konstrukcji budowlanych i konserwatorzy budynków | 7 | 88 380 | 4,1 | tak |
| 7112 | Murarze i pokrewni | 7 | 75 891 | 3,6 | tak |
| 7113 | Robotnicy obróbki kamienia | 7 | 8 702 | 0,4 | tak |
| 7114 | Betoniarze, betoniarze zbrojarze i pokrewni | 7 | 25 940 | 1,2 | tak |
| 7115 | Cieśle i stolarze budowlani | 7 | 52 946 | 2,5 | tak |
| 7116 | Robotnicy budowy dróg | 7 | 16 532 | 0,8 | tak |
| 7117 | Monterzy budownictwa wodnego | 7 | 3 028 | 0,1 | tak |
| 7119 | Robotnicy robót stanu surowego i pokrewni gdzie indziej | 7 | 40 033 | 1,9 | tak |
| 7121 | Dekarze | 7 | 23 829 | 1,1 | tak |
| 7122 | Posadzkarze, parkieciarze i glazurnicy | 7 | 18 063 | 0,8 | tak |
| 7123 | Tynkarze i pokrewni | 7 | 19 620 | 0,9 | tak |
| 7124 | Monterzy izolacji | 7 | 8 534 | 0,4 | tak |
| 7125 | Szklarze | 7 | 16 064 | 0,8 | tak |
| 7126 | Hydraulicy i monterzy rurociągów | 7 | 104 440 | 4,9 | tak |
| 7127 | Monterzy i konserwatorzy instalacji klimatyzacyjnych i chłodniczych | 7 | 22 558 | 1,1 | tak |
| 7129 | Robotnicy budowlani robót wykończeniowych i pokrewni gdzie indziej niesklasyfikowani | 7 | 137 276 | 6,4 | tak |
| 7131 | Malarze budowlani i pokrewni | 7 | 23 017 | 1,1 | tak |
| 7132 | Lakiernicy | 7 | 32 109 | 1,5 | tak |
| 7133 | Robotnicy czyszczący konstrukcje budowlane i pokrewni | 7 | 6 560 | 0,3 | tak |
| 7211 | Formierze odlewniczy i pokrewni | 7 | 8 444 | 0,4 | tak |
| 7212 | Spawacze i pokrewni | 7 | 101 423 | 4,8 | tak |
| 7213 | Blacharze | 7 | 14 082 | 0,7 | tak |
| 7214 | Robotnicy przygotowujący i wznoszący konstrukcje metalowe | 7 | 24 206 | 1,1 | tak |
| 7215 | Takielarze i monterzy konstrukcji linowych | 7 | 561 | 0,0 | tak |
| 7221 | Kowale i operatorzy pras kuźniczych | 7 | 2 630 | 0,1 | tak |
| 7222 | Ślusarze i pokrewni | 7 | 130 345 | 6,1 | tak |
| 7223 | Ustawiacze i operatorzy obrabiarek do metali i pokrewni | 7 | 107 188 | 5,0 | tak |
| 7224 | Szlifierze narzędzi i polerowacze metali | 7 | 3 143 | 0,1 | tak |
| 7231 | Mechanicy pojazdów samochodowych | 7 | 147 009 | 6,9 | tak |
| 7232 | Mechanicy statków powietrznych i pokrewni | 7 | 2 174 | 0,1 | tak |
| 7233 | Mechanicy maszyn i urządzeń rolniczych i przemysłowych | 7 | 67 784 | 3,2 | tak |
| 7234 | Mechanicy rowerów i pokrewni | 7 | 2 401 | 0,1 | tak |
| 7311 | Mechanicy precyzyjni | 7 | 13 554 | 0,6 | tak |
| 7312 | Monterzy instrumentów muzycznych | 7 | 317 | 0,0 | tak |
| 7313 | Jubilerzy, złotnicy i pokrewni | 7 | 4 118 | 0,2 | tak |
| 7314 | Ceramicy i pokrewni | 7 | 5 144 | 0,2 | tak |
| 7315 | Formowacze wyrobów szklanych, krajacze i szlifierze szkła | 7 | 6 558 | 0,3 | tak |
| 7316 | Szyldziarze, grawerzy i zdobnicy ceramiki, szkła i pokrewni | 7 | 5 617 | 0,3 | tak |
| 7317 | Rękodzielnicy wyrobów z drewna i pokrewnych materiałów | 7 | 1 214 | 0,1 | tak |
| 7318 | Rękodzielnicy wyrobów z tkanin, skóry i pokrewnych materiałów | 7 | 4 094 | 0,2 | tak |
| 7319 | Rzemieślnicy gdzie indziej niesklasyfikowani | 7 | 4 633 | 0,2 | tak |
| 7321 | Pracownicy przy pracach przygotowawczych do druku | 7 | 14 805 | 0,7 | tak |
| 7322 | Drukarze | 7 | 21 768 | 1,0 | tak |
| 7323 | Introligatorzy i pokrewni | 7 | 11 022 | 0,5 | tak |
| 7411 | Elektrycy budowlani i pokrewni | 7 | 128 759 | 6,0 | tak |
| 7412 | Elektromechanicy i elektromonterzy | 7 | 82 583 | 3,9 | tak |
| 7413 | Monterzy linii elektrycznych | 7 | 8 639 | 0,4 | tak |
| 7421 | Monterzy i serwisanci urządzeń elektronicznych | 7 | 28 396 | 1,3 | tak |
| 7422 | Monterzy i serwisanci instalacji i urządzeń teleinformatycznych | 7 | 19 593 | 0,9 | tak |
| 7511 | Masarze, robotnicy w przetwórstwie ryb i pokrewni | 7 | 52 569 | 2,5 | tak |
| 7512 | Piekarze, cukiernicy i pokrewni | 7 | 67 059 | 3,1 | tak |
| 7513 | Robotnicy w produkcji wyrobów mleczarskich | 7 | 6 512 | 0,3 | tak |
| 7514 | Robotnicy przetwórstwa surowców roślinnych | 7 | 7 339 | 0,3 | tak |
| 7515 | Klasyfikatorzy żywności i pokrewni | 7 | 887 | 0,0 | tak |
| 7521 | Robotnicy przygotowujący drewno i pokrewni | 7 | 11 408 | 0,5 | tak |
| 7522 | Stolarze meblowi i pokrewni | 7 | 104 950 | 4,9 | tak |
| 7523 | Ustawiacze i operatorzy maszyn do obróbki i produkcji wyrobów z drewna | 7 | 19 021 | 0,9 | tak |
| 7531 | Krawcy, kuśnierze, kapelusznicy i pokrewni | 7 | 33 968 | 1,6 | tak |
| 7532 | Konstruktorzy i krojczowie odzieży | 7 | 9 312 | 0,4 | tak |
| 7533 | Szwaczki, hafciarki i pokrewni | 7 | 32 510 | 1,5 | tak |
| 7534 | Tapicerzy i pokrewni | 7 | 22 571 | 1,1 | tak |
| 7535 | Wyprawiacze skór, garbarze i pokrewni | 7 | 1 268 | 0,1 | tak |
| 7536 | Obuwnicy i pokrewni | 7 | 5 059 | 0,2 | tak |
| 7537 | Kaletnicy, rymarze i pokrewni | 7 | 1 707 | 0,1 | tak |
| 7541 | Nurkowie | 7 | 553 | 0,0 | tak |
| 7542 | Strzałowi i pokrewni | 7 | 426 | 0,0 | tak |
| 7543 | Klasyfikatorzy wyrobów przemysłowych | 7 | 1 228 | 0,1 | tak |
| 7544 | Robotnicy zwalczania szkodników i chwastów | 7 | 2 498 | 0,1 | tak |
| 7549 | Robotnicy przemysłowi i rzemieślnicy gdzie indziej niesklasyfikowani | 7 | 54 319 | 2,5 | tak |
| 8111 | Górnicy podziemnej i odkrywkowej eksploatacji złóż i pokrewni | 8 | 51 475 | 3,7 | tak |
| 8112 | Operatorzy maszyn i urządzeń do przeróbki mechanicznej kopalin | 8 | 8 897 | 0,6 | tak |
| 8113 | Operatorzy urządzeń wiertniczych i wydobywczych ropy, gazu i innych surowców | 8 | 4 404 | 0,3 | tak |
| 8114 | Operatorzy maszyn i urządzeń do produkcji wyrobów cementowych, kamiennych i pokrewni | 8 | 9 213 | 0,7 | tak |
| 8121 | Operatorzy maszyn i urządzeń do produkcji i przetwórstwa metali | 8 | 65 722 | 4,7 | tak |
| 8122 | Operatorzy urządzeń do obróbki powierzchniowej metali i nakładania powłok | 8 | 9 334 | 0,7 | tak |
| 8131 | Operatorzy maszyn i urządzeń do produkcji wyrobów chemicznych | 8 | 32 612 | 2,3 | tak |
| 8132 | Operatorzy urządzeń do produkcji materiałów światłoczułych i obróbki filmów | 8 | 389 | 0,0 | tak |
| 8141 | Operatorzy maszyn do produkcji wyrobów gumowych | 8 | 15 867 | 1,1 | tak |
| 8142 | Operatorzy maszyn do produkcji wyrobów z tworzyw sztucznych | 8 | 41 508 | 2,9 | tak |
| 8143 | Operatorzy maszyn do produkcji wyrobów papierniczych | 8 | 9 862 | 0,7 | tak |
| 8151 | Operatorzy maszyn przędzalniczych i pokrewni | 8 | 841 | 0,1 | tak |
| 8152 | Operatorzy maszyn tkackich i dziewiarskich | 8 | 2 353 | 0,2 | tak |
| 8153 | Operatorzy maszyn do szycia | 8 | 14 661 | 1,0 | tak |
| 8154 | Operatorzy maszyn wykończalniczych wyrobów włókienniczych | 8 | 738 | 0,1 | tak |
| 8155 | Operatorzy maszyn do wyprawiania futer i skór | 8 | 140 | 0,0 | tak |
| 8156 | Operatorzy maszyn do produkcji obuwia i pokrewni | 8 | 700 | 0,0 | tak |
| 8157 | Operatorzy maszyn do prania | 8 | 3 914 | 0,3 | tak |
| 8159 | Operatorzy maszyn do produkcji wyrobów włókienniczych, futrzarskich | 8 | 2 152 | 0,2 | tak |
| 8160 | Operatorzy maszyn i urządzeń do produkcji wyrobów spożywczych i pokrewni | 8 | 48 375 | 3,4 | tak |
| 8171 | Operatorzy urządzeń do wyrobu masy papierniczej i produkcji papieru | 8 | 1 965 | 0,1 | tak |
| 8172 | Operatorzy maszyn i urządzeń do obróbki drewna | 8 | 20 152 | 1,4 | tak |
| 8181 | Operatorzy urządzeń do produkcji wyrobów szklanych i ceramicznych | 8 | 10 139 | 0,7 | tak |
| 8182 | Maszyniści kotłów parowych i pokrewni | 8 | 5 940 | 0,4 | tak |
| 8183 | Operatorzy urządzeń pakujących, znakujących i urządzeń do napełniania butelek | 8 | 4 174 | 0,3 | tak |
| 8189 | Operatorzy innych maszyn i urządzeń przetwórczych gdzie indziej niesklasyfikowani | 8 | 20 446 | 1,5 | tak |
| 8211 | Monterzy maszyn i urządzeń mechanicznych | 8 | 51 704 | 3,7 | tak |
| 8212 | Monterzy sprzętu elektrycznego | 8 | 22 303 | 1,6 | tak |
| 8213 | Monterzy sprzętu elektronicznego | 8 | 20 265 | 1,4 | tak |
| 8219 | Monterzy gdzie indziej niesklasyfikowani | 8 | 81 418 | 5,8 | tak |
| 8311 | Maszyniści kolejowi i metra | 8 | 15 467 | 1,1 | tak |
| 8312 | Dyżurni ruchu, manewrowi i pokrewni | 8 | 22 604 | 1,6 | tak |
| 8321 | Kierowcy motocykli | 8 | 199 | 0,0 | tak |
| 8322 | Kierowcy samochodów osobowych i dostawczych | 8 | 179 853 | 12,8 | tak |
| 8331 | Kierowcy autobusów i motorniczowie tramwajów | 8 | 56 988 | 4,1 | tak |
| 8332 | Kierowcy samochodów ciężarowych | 8 | 423 416 | 30,1 | tak |
| 8341 | Operatorzy wolnobieżnych maszyn rolniczych i leśnych | 8 | 15 594 | 1,1 | tak |
| 8342 | Operatorzy sprzętu do robót ziemnych i urządzeń pokrewnych | 8 | 43 382 | 3,1 | tak |
| 8343 | Maszyniści i operatorzy maszyn i urządzeń dźwigowo-transportowych | 8 | 26 391 | 1,9 | tak |
| 8344 | Kierowcy operatorzy wózków jezdniowych | 8 | 59 980 | 4,3 | tak |
| 8350 | Marynarze i pokrewni (z wyłączeniem sił zbrojnych) | 8 | 1 557 | 0,1 | tak |
| 9111 | Pomoce domowe i sprzątaczki | 9 | 8 090 | 0,9 | tak |
| 9112 | Pomoce i sprzątaczki biurowe, hotelowe i pokrewne | 9 | 234 914 | 26,6 | tak |
| 9121 | Praczki ręczne i prasowacze | 9 | 6 714 | 0,8 | tak |
| 9122 | Czyściciele pojazdów | 9 | 8 502 | 1,0 | tak |
| 9123 | Zmywacze okien | 9 | 124 | 0,0 | tak |
| 9129 | Pozostali pracownicy zajmujący się sprzątaniem | 9 | 79 221 | 9,0 | tak |
| 9211 | Robotnicy wykonujący proste prace polowe | 9 | 2 511 | 0,3 | tak |
| 9212 | Robotnicy wykonujący prace proste w hodowli zwierząt | 9 | 5 477 | 0,6 | tak |
| 9213 | Robotnicy wykonujący prace proste przy uprawie roślin i hodowli zwierząt | 9 | 4 142 | 0,5 | tak |
| 9214 | Robotnicy wykonujący prace proste w ogrodnictwie i sadownictwie | 9 | 9 740 | 1,1 | tak |
| 9215 | Robotnicy wykonujący prace proste w leśnictwie | 9 | 1 399 | 0,2 | tak |
| 9216 | Robotnicy wykonujący prace proste w rybołówstwie i zakładach akwakultury | 9 | 221 | 0,0 | tak |
| 9311 | Robotnicy wykonujący prace proste w kopalniach i kamieniołomach | 9 | 20 041 | 2,3 | tak |
| 9312+9313 | Robotnicy wykonujący prace proste w budownictwie drogowym, wodnym i pokrewni oraz robotnicy wykonujący prace proste w budownictwie ogólnym | 9 | 67 780 | 7,7 | tak |
| 9321 | Ręczni pakowacze i znakowacze | 9 | 75 815 | 8,6 | tak |
| 9329 | Robotnicy wykonujący prace proste w przemyśle gdzie indziej niesklasyfikowani | 9 | 82 315 | 9,3 | tak |
| 9331 | Prowadzący pojazdy napędzane siłą mięśni | 9 | 64 | 0,0 | tak |
| 9332 | Prowadzący pojazdy ciągnięte przez zwierzęta | 9 | 87 | 0,0 | tak |
| 9333 | Robotnicy pracujący przy przeładunku towarów | 9 | 42 330 | 4,8 | tak |
| 9334 | Układacze towarów na półkach | 9 | 2 429 | 0,3 | tak |
| 9411 | Pracownicy przygotowujący posiłki typu fast food | 9 | 31 609 | 3,6 | tak |
| 9412 | Pomoce kuchenne | 9 | 68 509 | 7,8 | tak |
| 9510 | Pracownicy świadczący usługi na ulicach | 9 | 1 113 | 0,1 | tak |
| 9520 | Uliczni sprzedawcy produktów (z wyłączeniem żywności o krótkim terminie przydatności do spożycia) | 9 | 731 | 0,1 | tak |
| 9611 | Ładowacze nieczystości | 9 | 11 893 | 1,3 | tak |
| 9612 | Sortowacze odpadów | 9 | 9 915 | 1,1 | tak |
| 9613 | Zamiatacze i pokrewni | 9 | 4 961 | 0,6 | tak |
| 9621 | Gońcy, bagażowi i pokrewni | 9 | 5 304 | 0,6 | tak |
| 9622 | Pracownicy wykonujący dorywcze prace proste | 9 | 11 853 | 1,3 | tak |
| 9623 | Odczytujący liczniki i wybierający monety z automatów | 9 | 1 096 | 0,1 | tak |
| 9629 | Pracownicy wykonujący prace proste gdzie indziej niesklasyfikowani | 9 | 83 346 | 9,4 | tak |
| 000X | Siły zbrojne | 0 | 167 305 | 100,0 | nie |

## 3. Mieszanka sekcji PKD według województwa

GUS, „Pracujący w gospodarce narodowej w 2023 roku”, publikacja 28.10.2024, tabl. 1: pracujący według sekcji PKD i miejsca zamieszkania, stan na 31 grudnia 2023 r., osoby. Adres: https://stat.gov.pl/obszary-tematyczne/rynek-pracy/pracujacy-zatrudnieni-wynagrodzenia-koszty-pracy/pracujacy-w-gospodarce-narodowej-w-2023-roku,7,21.html

To jest miks do podpięcia. Miasto bierze wiersz swojego województwa. Udziały poniżej są policzone z liczebności (sekcja / ogółem) i zaokrąglone do 1 miejsca. W tablicy udziałów nie było, były osoby. Suma 16 województw równa się wierszowi Polska. Sekcja S obejmuje także T i U. W każdym wierszu suma sekcji A–S równa się ogółem.

### Górnictwo i wydobywanie (PKD B)

| Jednostka | Osoby w B | Ogółem | Udział B, % |
| --- | ---: | ---: | ---: |
| Polska | 132 784 | 15 142 530 | 0,9 |
| Dolnośląskie | 20 032 | 1 159 011 | 1,7 |
| Kujawsko-Pomorskie | 923 | 754 539 | 0,1 |
| Lubelskie | 7 371 | 761 604 | 1,0 |
| Lubuskie | 1 054 | 366 298 | 0,3 |
| Łódzkie | 5 586 | 995 919 | 0,6 |
| Małopolskie | 11 854 | 1 440 804 | 0,8 |
| Mazowieckie | 1 718 | 2 463 404 | 0,1 |
| Opolskie | 946 | 342 911 | 0,3 |
| Podkarpackie | 1 934 | 758 852 | 0,3 |
| Podlaskie | 836 | 430 691 | 0,2 |
| Pomorskie | 1 273 | 927 968 | 0,1 |
| Śląskie | 71 707 | 1 705 248 | 4,2 |
| Świętokrzyskie | 3 449 | 429 924 | 0,8 |
| Warmińsko-Mazurskie | 743 | 485 299 | 0,2 |
| Wielkopolskie | 2 660 | 1 532 916 | 0,2 |
| Zachodniopomorskie | 698 | 587 142 | 0,1 |

Śląskie, miejsce zamieszkania: 71 707 / 1 705 248 = 4,2%.

### Wszystkie sekcje, udział w procentach do 1 miejsca

A rolnictwo, leśnictwo, łowiectwo i rybactwo. B górnictwo i wydobywanie. C przetwórstwo przemysłowe. D energia. E woda, ścieki, odpady. F budownictwo. G handel i naprawa pojazdów. H transport i magazyny. I zakwaterowanie i gastronomia. J informacja i komunikacja. K finanse i ubezpieczenia. L nieruchomości. M działalność profesjonalna, naukowa i techniczna. N administrowanie i działalność wspierająca. O administracja publiczna i obrona. P edukacja. Q zdrowie i pomoc społeczna. R kultura, rozrywka, rekreacja. S pozostałe usługi, łącznie z T i U.

| Jednostka | A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Polska | 8,1 | 0,9 | 18,4 | 0,7 | 1,1 | 6,9 | 14,8 | 6,1 | 2,1 | 3,5 | 2,1 | 1,2 | 5,5 | 3,7 | 6,8 | 8,0 | 6,4 | 1,1 | 2,5 |
| Dolnośląskie | 4,0 | 1,7 | 20,2 | 0,7 | 1,2 | 6,4 | 13,8 | 6,2 | 2,5 | 5,0 | 2,0 | 1,3 | 6,2 | 5,0 | 5,7 | 7,7 | 6,7 | 1,1 | 2,5 |
| Kujawsko-Pomorskie | 8,7 | 0,1 | 21,3 | 0,6 | 1,3 | 7,1 | 15,4 | 5,8 | 1,7 | 2,0 | 1,5 | 1,0 | 4,0 | 3,4 | 7,8 | 7,7 | 6,9 | 1,0 | 2,5 |
| Lubelskie | 18,8 | 1,0 | 12,9 | 0,7 | 1,0 | 6,4 | 13,2 | 5,8 | 1,5 | 2,1 | 1,7 | 1,0 | 3,5 | 2,4 | 8,6 | 8,9 | 7,4 | 1,0 | 2,2 |
| Lubuskie | 5,4 | 0,3 | 21,7 | 0,8 | 1,4 | 6,8 | 15,2 | 8,7 | 2,0 | 1,4 | 1,4 | 1,1 | 3,4 | 4,6 | 8,8 | 7,4 | 6,1 | 1,0 | 2,6 |
| Łódzkie | 9,0 | 0,6 | 21,0 | 1,0 | 0,9 | 5,6 | 15,4 | 7,0 | 1,6 | 2,4 | 2,5 | 1,1 | 4,8 | 4,3 | 6,3 | 7,2 | 6,1 | 1,0 | 2,2 |
| Małopolskie | 10,0 | 0,8 | 16,1 | 0,6 | 0,9 | 8,1 | 14,5 | 4,6 | 2,8 | 5,5 | 1,8 | 1,0 | 7,0 | 3,2 | 4,8 | 8,2 | 6,3 | 1,3 | 2,6 |
| Mazowieckie | 6,8 | 0,1 | 12,0 | 0,7 | 0,8 | 6,0 | 15,4 | 6,2 | 2,1 | 5,9 | 4,3 | 1,5 | 8,8 | 3,8 | 7,6 | 8,2 | 5,7 | 1,4 | 2,6 |
| Opolskie | 8,7 | 0,3 | 23,6 | 1,0 | 1,3 | 7,7 | 13,7 | 5,4 | 1,9 | 1,8 | 1,3 | 0,8 | 3,5 | 3,2 | 7,3 | 8,0 | 6,9 | 1,0 | 2,5 |
| Podkarpackie | 11,7 | 0,3 | 21,8 | 0,9 | 1,1 | 7,2 | 14,2 | 4,6 | 1,7 | 1,9 | 1,2 | 0,8 | 3,4 | 3,0 | 7,2 | 8,2 | 7,3 | 1,0 | 2,4 |
| Podlaskie | 18,4 | 0,2 | 15,4 | 0,7 | 1,0 | 6,5 | 13,7 | 5,0 | 1,6 | 2,2 | 1,6 | 0,9 | 3,5 | 2,2 | 8,4 | 8,3 | 6,9 | 1,1 | 2,4 |
| Pomorskie | 5,0 | 0,1 | 18,2 | 0,7 | 1,0 | 8,2 | 14,4 | 6,6 | 2,8 | 4,2 | 2,2 | 1,4 | 6,0 | 3,7 | 7,1 | 8,3 | 6,3 | 1,1 | 2,8 |
| Śląskie | 2,3 | 4,2 | 21,5 | 0,9 | 1,3 | 6,7 | 15,3 | 6,5 | 2,0 | 3,2 | 1,7 | 1,4 | 5,3 | 4,3 | 5,2 | 8,0 | 6,7 | 1,2 | 2,5 |
| Świętokrzyskie | 14,5 | 0,8 | 17,3 | 0,9 | 1,2 | 7,7 | 14,6 | 5,4 | 1,8 | 1,6 | 1,2 | 0,8 | 3,5 | 3,0 | 6,7 | 7,5 | 7,9 | 1,1 | 2,5 |
| Warmińsko-Mazurskie | 9,7 | 0,2 | 20,0 | 0,7 | 1,4 | 6,7 | 13,4 | 5,1 | 2,3 | 1,4 | 1,8 | 1,0 | 3,4 | 2,8 | 11,7 | 8,1 | 6,6 | 1,1 | 2,7 |
| Wielkopolskie | 8,3 | 0,2 | 23,2 | 0,6 | 1,1 | 7,5 | 16,0 | 7,2 | 1,8 | 2,4 | 1,5 | 0,9 | 4,7 | 3,8 | 5,0 | 7,3 | 5,1 | 0,9 | 2,4 |
| Zachodniopomorskie | 5,6 | 0,1 | 17,8 | 0,9 | 1,4 | 7,1 | 14,2 | 7,6 | 3,5 | 2,2 | 1,6 | 1,4 | 4,1 | 3,6 | 9,8 | 8,1 | 6,9 | 1,2 | 2,9 |

### Ta sama sekcja B według siedziby pracy, nie do mieszania

Tabl. 2 tej samej publikacji, siedziba pracy głównej, też stan na 31.12.2023. Nie jest miksem do podpięcia obok tabl. 1. Na Śląsku górnictwo wychodzi tu 5,0% (80 197 / 1 610 926), a w małopolskim 0,2% zamiast 0,8%, bo część osób mieszkających poza śląskim ma pracę w firmie z siedzibą na Śląsku.

| Jednostka | Udział B według siedziby, % |
| --- | ---: |
| Polska | 0,9 |
| Dolnośląskie | 1,8 |
| Kujawsko-Pomorskie | 0,1 |
| Lubelskie | 1,1 |
| Lubuskie | 0,2 |
| Łódzkie | 0,6 |
| Małopolskie | 0,2 |
| Mazowieckie | 0,1 |
| Opolskie | 0,3 |
| Podkarpackie | 0,2 |
| Podlaskie | 0,2 |
| Pomorskie | 0,1 |
| Śląskie | 5,0 |
| Świętokrzyskie | 0,9 |
| Warmińsko-Mazurskie | 0,1 |
| Wielkopolskie | 0,2 |
| Zachodniopomorskie | 0,1 |

## 4. Metropolia a reszta województwa

Lista miast: Krajowa Polityka Miejska 2030, uchwała nr 136 Rady Ministrów z 14 czerwca 2022 r., Monitor Polski 2022 poz. 746, https://eli.gov.pl/api/acts/MP/2022/746/text/O/M20220746.pdf . Za ukształtowane ośrodki metropolitalne dokument uznaje miasta mające co najmniej około 400 tys. mieszkańców: konurbację katowicką, Warszawę, Kraków, Gdańsk z Gdynią i Sopotem, Łódź, Wrocław, Poznań i Szczecin. Bydgoszcz, Lublin, Białystok, Rzeszów i inne wymienia osobno, jako metropolie potencjalne lub kształtujące się, więc tu nie dostają flagi metropolii.

Zasięg konurbacji w grze: 41 gmin Górnośląsko-Zagłębiowskiej Metropolii według „Vademecum metropolitalnego”, GZM, Katowice, październik 2023, https://infogzm.metropoliagzm.pl/wp-content/uploads/2024/03/raport_obszary-metrop_pl_2023-10_2.pdf .

Przesunięcie jest z tej samej tabl. 1, czyli z sekcji PKD według miejsca zamieszkania, nie z zawodów. Nie ma z tego częstości poszczególnych zawodów.

Dla dziesięciu miast z listy ukształtowanych ośrodków (Warszawa, Kraków, Łódź, Wrocław, Poznań, Gdańsk, Gdynia, Sopot, Szczecin, Katowice) udział sekcji A, B i C jest niższy niż w województwie tego miasta, a udział sekcji J, K i M jest wyższy. To porównanie liczebności, nie mnożnik.

Pozostałe gminy GZM z własnym wierszem nie przesuwają się w tę samą stronę. Mysłowice, Ruda Śląska i Piekary Śląskie mają wyższy udział B niż śląskie. Dąbrowa Górnicza, Gliwice i Tychy mają wyższy udział C. Każda gmina bierze swój wiersz. Nie dostaje przesunięcia Katowic ani Warszawy.

W Gdańsku, Gdyni i Sopocie udział B po zaokrągleniu do 1 miejsca też jest 0,1, tak jak w pomorskim. Z liczebności jest jednak niższy: Gdańsk 198 z 215 938, Gdynia 65 z 95 950, Sopot 14 z 12 000, pomorskie 1 273 z 927 968.

Katowice mają górnictwo 3,2%, a śląskie 4,2%. Wiersz Katowic nie jest miksem całego śląskiego ani pozostałych gmin GZM.

0,0 w kolumnie B to zaokrąglenie poniżej 0,05 punktu procentowego, nie zero osób: Warszawa 238, Łódź 53, Wrocław 123, Poznań 96, Szczecin 65.

| Miasto | Województwo | A miasto | A woj. | B miasto | B woj. | C miasto | C woj. | J miasto | J woj. | M miasto | M woj. |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Warszawa | Mazowieckie | 0,6 | 6,8 | 0,0 | 0,1 | 6,2 | 12,0 | 11,1 | 5,9 | 14,2 | 8,8 |
| Kraków | Małopolskie | 0,8 | 10,0 | 0,2 | 0,8 | 9,1 | 16,1 | 13,7 | 5,5 | 14,0 | 7,0 |
| Łódź | Łódzkie | 0,6 | 9,0 | 0,0 | 0,6 | 17,5 | 21,0 | 4,8 | 2,4 | 7,8 | 4,8 |
| Wrocław | Dolnośląskie | 0,5 | 4,0 | 0,0 | 1,7 | 12,5 | 20,2 | 11,9 | 5,0 | 11,4 | 6,2 |
| Poznań | Wielkopolskie | 0,6 | 8,3 | 0,0 | 0,2 | 13,0 | 23,2 | 6,9 | 2,4 | 9,9 | 4,7 |
| Gdańsk | Pomorskie | 0,6 | 5,0 | 0,1 | 0,1 | 11,6 | 18,2 | 9,5 | 4,2 | 10,3 | 6,0 |
| Gdynia | Pomorskie | 0,9 | 5,0 | 0,1 | 0,1 | 11,6 | 18,2 | 7,0 | 4,2 | 9,5 | 6,0 |
| Sopot | Pomorskie | 0,7 | 5,0 | 0,1 | 0,1 | 8,3 | 18,2 | 8,2 | 4,2 | 11,9 | 6,0 |
| Szczecin | Zachodniopomorskie | 0,9 | 5,6 | 0,0 | 0,1 | 14,7 | 17,8 | 4,7 | 2,2 | 5,8 | 4,1 |
| Bytom | Śląskie | 0,2 | 2,3 | 4,2 | 4,2 | 15,7 | 21,5 | 3,5 | 3,2 | 5,0 | 5,3 |
| Chorzów | Śląskie | 0,2 | 2,3 | 1,8 | 4,2 | 16,2 | 21,5 | 4,3 | 3,2 | 5,9 | 5,3 |
| Dąbrowa Górnicza | Śląskie | 0,5 | 2,3 | 0,6 | 4,2 | 24,9 | 21,5 | 2,8 | 3,2 | 6,2 | 5,3 |
| Gliwice | Śląskie | 0,5 | 2,3 | 1,8 | 4,2 | 22,3 | 21,5 | 6,4 | 3,2 | 9,5 | 5,3 |
| Katowice | Śląskie | 0,3 | 2,3 | 3,2 | 4,2 | 11,7 | 21,5 | 7,3 | 3,2 | 8,6 | 5,3 |
| Mysłowice | Śląskie | 0,4 | 2,3 | 9,0 | 4,2 | 15,1 | 21,5 | 3,8 | 3,2 | 5,9 | 5,3 |
| Piekary Śląskie | Śląskie | 0,4 | 2,3 | 4,4 | 4,2 | 17,7 | 21,5 | 3,7 | 3,2 | 5,0 | 5,3 |
| Ruda Śląska | Śląskie | 0,3 | 2,3 | 7,9 | 4,2 | 15,2 | 21,5 | 3,2 | 3,2 | 5,3 | 5,3 |
| Siemianowice Śląskie | Śląskie | 0,4 | 2,3 | 1,7 | 4,2 | 18,3 | 21,5 | 4,8 | 3,2 | 5,9 | 5,3 |
| Sosnowiec | Śląskie | 0,4 | 2,3 | 1,3 | 4,2 | 20,4 | 21,5 | 3,6 | 3,2 | 5,2 | 5,3 |
| Świętochłowice | Śląskie | 0,2 | 2,3 | 2,4 | 4,2 | 17,8 | 21,5 | 3,1 | 3,2 | 5,0 | 5,3 |
| Tychy | Śląskie | 0,6 | 2,3 | 2,3 | 4,2 | 26,9 | 21,5 | 3,6 | 3,2 | 6,2 | 5,3 |
| Zabrze | Śląskie | 0,3 | 2,3 | 3,6 | 4,2 | 20,5 | 21,5 | 3,5 | 3,2 | 5,4 | 5,3 |

Gminy GZM bez własnego wiersza powiatu grodzkiego w tabl. 1, więc bez własnego przesunięcia: Będzin, Bieruń, Bobrowniki, Bojszowy, Chełm Śląski, Czeladź, Gierałtowice, Imielin, Knurów, Kobiór, Lędziny, Łaziska Górne, Mierzęcice, Mikołów, Ożarowice, Pilchowice, Psary, Pyskowice, Radzionków, Rudziniec, Siewierz, Sławków, Sośnicowice, Świerklaniec, Tarnowskie Góry, Wojkowice, Wyry, Zbrosławice.

Stolice województw poza listą ukształtowanych ośrodków, bez flagi metropolii: Białystok, Bydgoszcz, Toruń, Gorzów Wielkopolski, Kielce, Lublin, Olsztyn, Opole, Rzeszów, Zielona Góra.

## 5. Czego nie stosować jako przesunięcia metropolii

GUS, BAEL, IV kwartał 2024, tabl. 2.8 publikuje wielkie grupy zawodów dla miast i wsi (wiek 15–89 lat). Specjaliści to 30,1% pracujących w miastach i 15,4% na wsi, rolnicy 0,6% i 13,6%. „Miasta” obejmują małe miasta. To nie jest skład metropolii i nie jest wagą do losowania. Pełne liczby są w JSON, z flagą żeby ich nie podpinać.

