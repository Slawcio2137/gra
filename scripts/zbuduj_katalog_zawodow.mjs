// Buduje postacie/katalog_zawodow.json i postacie/katalog_zawodow_lista.md
// Nazwy: API KZiS dla integratorów (broker.praca.gov.pl).
// Płace: tylko wielkie grupy już zapisane w zarobki_kraje.json (GUS X 2024).
// Reszta zawodów dziedziczy tę kwotę (zarobki_zrodlo: grupa_nadrzedna) albo ma null.
import fs from "fs";
import path from "path";

const ROOT = path.resolve("C:/Not that real life");
const KZIS_PATH = path.join(process.env.TEMP, "kzis_liniowy.json");
const PLACE_PATH = path.join(ROOT, "postacie", "losowanie", "zarobki_kraje.json");
const OUT_JSON = path.join(ROOT, "postacie", "katalog_zawodow.json");
const OUT_MD = path.join(ROOT, "postacie", "katalog_zawodow_lista.md");
const DZIEN = "2026-10-29";

const PROFILE = {
	fizyczna: {
		opis: "Ciężka praca ciałem: rzemiosło, maszyny, rolnictwo, budowa, prace proste, szeregowi i podoficerowie.",
		zmeczenie_fizyczne: 8,
		zmeczenie_psychiczne: 2,
		sylwetka: 2,
		inteligencja: 0,
		zdrowie: -1,
		wyglad: -1,
		sila: 1,
		kondycja: 1,
		psychika: -1,
	},
	fizyczna_lekka: {
		opis: "Lżejszy wariant pracy fizycznej: stanie przy sprzedaży, kierowanie pojazdem, lekka obsługa. Ta sama rodzina co fizyczna, mniejsze liczby, bo to nie jest ciężka robota.",
		zmeczenie_fizyczne: 4,
		zmeczenie_psychiczne: 4,
		sylwetka: 1,
		inteligencja: 0,
		zdrowie: 0,
		wyglad: 0,
		sila: 0,
		kondycja: 1,
		psychika: -1,
	},
	biurowa: {
		opis: "Praca przy biurku, kierowanie, prawo, administracja, informatyka biurowa, oficerowie (dowodzenie).",
		zmeczenie_fizyczne: 1,
		zmeczenie_psychiczne: 6,
		sylwetka: -1,
		inteligencja: 1,
		zdrowie: 0,
		wyglad: 1,
		sila: 0,
		kondycja: -1,
		psychika: -1,
	},
	opiekuncza: {
		opis: "Zdrowie, nauczanie, opieka, praca socjalna i usługa osobista przy ludziach. Nauczanie jest tu, nie przy biurku.",
		zmeczenie_fizyczne: 4,
		zmeczenie_psychiczne: 6,
		sylwetka: 1,
		inteligencja: 1,
		zdrowie: -1,
		wyglad: 0,
		sila: 0,
		kondycja: 1,
		psychika: -1,
	},
	kreatywna: {
		opis: "Sztuka, dziennikarstwo, projektowanie, rękodzieło artystyczne.",
		zmeczenie_fizyczne: 2,
		zmeczenie_psychiczne: 5,
		sylwetka: 0,
		inteligencja: 2,
		zdrowie: 0,
		wyglad: 1,
		sila: 0,
		kondycja: 0,
		psychika: 1,
	},
};

// Najdłuższy pasujący prefiks wygrywa. Brak dopasowania = błąd generatora, nie domyślna liczba.
const REGULY = [
	["216", "kreatywna"],
	["261", "biurowa"],
	["262", "biurowa"],
	["263", "opiekuncza"],
	["264", "kreatywna"],
	["265", "kreatywna"],
	["3118", "biurowa"],
	["3411", "biurowa"],
	["3412", "opiekuncza"],
	["3413", "opiekuncza"],
	["342", "fizyczna"],
	["343", "kreatywna"],
	["511", "opiekuncza"],
	["512", "fizyczna"],
	["513", "fizyczna_lekka"],
	["514", "opiekuncza"],
	["515", "biurowa"],
	["516", "opiekuncza"],
	["731", "kreatywna"],
	["962", "fizyczna_lekka"],
	["01", "biurowa"],
	["02", "fizyczna"],
	["03", "fizyczna"],
	["11", "biurowa"],
	["12", "biurowa"],
	["13", "biurowa"],
	["14", "biurowa"],
	["21", "biurowa"],
	["22", "opiekuncza"],
	["23", "opiekuncza"],
	["24", "biurowa"],
	["25", "biurowa"],
	["26", "biurowa"],
	["31", "fizyczna"],
	["32", "opiekuncza"],
	["33", "biurowa"],
	["34", "biurowa"],
	["35", "biurowa"],
	["41", "biurowa"],
	["42", "biurowa"],
	["43", "biurowa"],
	["44", "biurowa"],
	["51", "opiekuncza"],
	["52", "fizyczna_lekka"],
	["53", "opiekuncza"],
	["54", "fizyczna"],
	["61", "fizyczna"],
	["62", "fizyczna"],
	["63", "fizyczna"],
	["71", "fizyczna"],
	["72", "fizyczna"],
	["73", "fizyczna"],
	["74", "fizyczna"],
	["75", "fizyczna"],
	["81", "fizyczna"],
	["82", "fizyczna"],
	["83", "fizyczna_lekka"],
	["91", "fizyczna"],
	["92", "fizyczna"],
	["93", "fizyczna"],
	["94", "fizyczna_lekka"],
	["95", "fizyczna_lekka"],
	["96", "fizyczna"],
];

const REGULY_POSORTOWANE = [...REGULY].sort((a, b) => b[0].length - a[0].length);

function profilDla(kod) {
	for (const [prefiks, profil] of REGULY_POSORTOWANE) {
		if (kod.startsWith(prefiks)) {
			return profil;
		}
	}
	return null;
}

function zaokraglij(kwota, cyfry = 2) {
	const v0 = Math.abs(Number(kwota));
	const znak = Number(kwota) < 0 ? -1 : 1;
	if (v0 === 0) {
		return 0;
	}
	const n = Math.max(1, Math.min(3, cyfry));
	const wykladnik = Math.floor(Math.log(v0) / Math.log(10) + 1e-9);
	const factor = 10 ** (wykladnik - n + 1);
	return znak * Math.round(Math.round(v0 / factor) * factor);
}

function cyfryZnaczace(n) {
	const s = String(Math.abs(n));
	return s.replace(/0+$/, "").replace(".", "").length;
}

function efekty(profil) {
	const p = PROFILE[profil];
	return {
		profil,
		propozycja_do_poprawki: true,
		szacunek: true,
		jednostka: "na_tydzien",
		uwaga: "Projekt gry. Nie jest to statystyka GUS, Eurostatu ani NBP.",
		zmeczenie_fizyczne: p.zmeczenie_fizyczne,
		zmeczenie_psychiczne: p.zmeczenie_psychiczne,
		sylwetka: p.sylwetka,
		inteligencja: p.inteligencja,
		zdrowie: p.zdrowie,
		wyglad: p.wyglad,
		sila: p.sila,
		kondycja: p.kondycja,
		psychika: p.psychika,
	};
}

function blokPlci(zrodlo) {
	return {
		mediana_zl_zrodlo: zrodlo.mediana_zl,
		przecietne_zl_zrodlo: zrodlo.przecietne_zl,
		mediana_zl: zaokraglij(zrodlo.mediana_zl),
		przecietne_zl: zaokraglij(zrodlo.przecietne_zl),
	};
}

function rodzicKodu(kod, zestaw) {
	const kawalki = [];
	if (kod.length >= 6) {
		kawalki.push(kod.slice(0, 4), kod.slice(0, 3), kod.slice(0, 2), kod.slice(0, 1));
	} else if (kod.length === 4) {
		kawalki.push(kod.slice(0, 3), kod.slice(0, 2), kod.slice(0, 1));
	} else if (kod.length === 3) {
		kawalki.push(kod.slice(0, 2), kod.slice(0, 1));
	} else if (kod.length === 2) {
		kawalki.push(kod.slice(0, 1));
	}
	for (const k of kawalki) {
		if (zestaw.has(k)) {
			return k;
		}
	}
	return null;
}

function main() {
	const surowe = JSON.parse(fs.readFileSync(KZIS_PATH, "utf8")).pozycje;
	const place = JSON.parse(fs.readFileSync(PLACE_PATH, "utf8"));
	const polska = place.kraje.polska;
	const wielkie = polska.wielkie_grupy;

	const aktualne = [];
	const pominiete = [];
	for (const p of surowe) {
		const kod = String(p.kod);
		const nazwa = String(p.opis ?? "").replace(/\s+/g, " ").trim();
		if (p.dataDo && p.dataDo < DZIEN) {
			pominiete.push({ kod, nazwa, powod: "dataDo " + p.dataDo });
			continue;
		}
		if (nazwa.toLowerCase() === "bez zawodu" || kod === "0000" || kod === "000000" || kod === "00") {
			pominiete.push({ kod, nazwa, powod: "nie jest zawodem" });
			continue;
		}
		if (!/^\d{1,6}$/.test(kod) || kod.length === 5) {
			throw new Error("Nieoczekiwany kod " + kod);
		}
		aktualne.push({ kod, nazwa });
	}

	const zestaw = new Set(aktualne.map((p) => p.kod));
	const poKodzie = new Map(aktualne.map((p) => [p.kod, p]));
	const zawodySurowe = aktualne.filter((p) => p.kod.length === 6);
	const grupySurowe = aktualne.filter((p) => p.kod.length < 6);

	const niedopasowane = [];
	const zawody = zawodySurowe.map((p) => {
		const profil = profilDla(p.kod);
		if (!profil) {
			niedopasowane.push(p.kod);
		}
		const wielka = p.kod.slice(0, 1);
		const rodzic = rodzicKodu(p.kod, zestaw);
		const oc = "OC" + wielka;
		const opublikowana = wielkie[oc] ?? null;
		let zarobki = null;
		let zarobkiZrodlo = null;
		let zarobkiUwaga = null;
		if (opublikowana) {
			zarobkiZrodlo = "grupa_nadrzedna";
			const og = blokPlci(opublikowana.ogolem);
			zarobki = {
				zarobki_zrodlo: "grupa_nadrzedna",
				grupa_zrodla_kod: wielka,
				grupa_zrodla_isco: oc,
				rok: polska.rok,
				miesiac: polska.miesiac,
				waluta: polska.waluta,
				zaokraglenie: "2_cyfry_znaczace",
				mediana_zl_zrodlo: og.mediana_zl_zrodlo,
				przecietne_zl_zrodlo: og.przecietne_zl_zrodlo,
				mediana_zl: og.mediana_zl,
				przecietne_zl: og.przecietne_zl,
				mezczyzni: blokPlci(opublikowana.mezczyzni),
				kobiety: blokPlci(opublikowana.kobiety),
				zrodlo: "GUS, Struktura wynagrodzeń według zawodów za październik 2024 r., wielka grupa " + wielka + ". Ten zawód nie ma własnego wiersza: kwota wielkiej grupy, zarobki_zrodlo grupa_nadrzedna.",
			};
		} else {
			zarobkiUwaga = "Brak opublikowanego wiersza płac dla wielkiej grupy " + wielka + " w zestawie GUS z października 2024 trzymanym w grze (są grupy 1–9). Nie podstawiono płacy innej grupy.";
		}
		return {
			kod: p.kod,
			nazwa: p.nazwa,
			wielka_grupa: wielka,
			wielka_grupa_nazwa: poKodzie.get(wielka)?.nazwa ?? null,
			duza_grupa: p.kod.slice(0, 2),
			rodzic: rodzic,
			rodzic_nazwa: rodzic ? poKodzie.get(rodzic).nazwa : null,
			isco08: p.kod.slice(0, 4),
			profil,
			zarobki_zrodlo: zarobkiZrodlo,
			zarobki_uwaga: zarobkiUwaga,
			zarobki,
			efekty_tygodniowe: profil ? efekty(profil) : null,
		};
	});

	if (niedopasowane.length) {
		throw new Error("Brak profilu dla: " + niedopasowane.slice(0, 20).join(", "));
	}

	const profilePotomkow = new Map();
	for (const z of zawody) {
		for (const pre of [z.kod.slice(0, 1), z.kod.slice(0, 2), z.kod.slice(0, 3), z.kod.slice(0, 4)]) {
			if (!profilePotomkow.has(pre)) {
				profilePotomkow.set(pre, new Set());
			}
			profilePotomkow.get(pre).add(z.profil);
		}
	}

	const grupy = grupySurowe.map((p) => {
		const zest = profilePotomkow.get(p.kod) ?? new Set();
		const jednolity = zest.size === 1;
		const profil = jednolity ? [...zest][0] : null;
		const rodzic = rodzicKodu(p.kod, zestaw);
		return {
			kod: p.kod,
			nazwa: p.nazwa,
			poziom: p.kod.length,
			wielka_grupa: p.kod.slice(0, 1),
			rodzic,
			rodzic_nazwa: rodzic ? poKodzie.get(rodzic).nazwa : null,
			profil_jednolity: jednolity,
			profil,
			efekty_tygodniowe: profil ? efekty(profil) : null,
		};
	});

	const placeOpublikowane = [];
	for (const oc of Object.keys(wielkie)) {
		const g = wielkie[oc];
		const kod = oc.slice(2);
		const og = blokPlci(g.ogolem);
		placeOpublikowane.push({
			kod,
			isco08: oc,
			nazwa_gus: g.nazwa,
			nazwa_kzis: poKodzie.get(kod)?.nazwa ?? null,
			zarobki_zrodlo: "gus_z12_2024",
			rok: polska.rok,
			miesiac: polska.miesiac,
			waluta: polska.waluta,
			zaokraglenie: "2_cyfry_znaczace",
			mediana_zl_zrodlo: og.mediana_zl_zrodlo,
			przecietne_zl_zrodlo: og.przecietne_zl_zrodlo,
			mediana_zl: og.mediana_zl,
			przecietne_zl: og.przecietne_zl,
			mezczyzni: blokPlci(g.mezczyzni),
			kobiety: blokPlci(g.kobiety),
			cytat: g.cytat,
			zrodlo: polska.zrodlo,
		});
		for (const n of [og.mediana_zl, og.przecietne_zl]) {
			if (cyfryZnaczace(n) > 3) {
				throw new Error("Za dużo cyfr " + n);
			}
		}
	}

	const dziedziczone = zawody.filter((z) => z.zarobki_zrodlo === "grupa_nadrzedna").length;
	const puste = zawody.filter((z) => z.zarobki == null).length;
	const bezposrednieNaZawodzie = zawody.filter((z) => z.zarobki_zrodlo === "gus_z12_2024").length;
	if (dziedziczone + puste + bezposrednieNaZawodzie !== zawody.length) {
		throw new Error("Rozjazd licznika płac");
	}

	const licznikiGrup = {};
	for (const z of zawody) {
		licznikiGrup[z.wielka_grupa] = (licznikiGrup[z.wielka_grupa] ?? 0) + 1;
	}

	const katalog = {
		opis: "Katalog zawodów i specjalności KZiS (kody 6-cyfrowe). Nazwy z publicznego API integratorów MRPiPS. Płace tylko z wielkich grup GUS już zapisanych w grze: zawód bez własnego wiersza dziedziczy grupę (zarobki_zrodlo: grupa_nadrzedna). Wielka grupa 0 nie ma wiersza — zarobki null. Efekty tygodniowe to rubryka projektowa, nie statystyka. Koło rodziców zostaje przy wagach Eurostat 2-digit; stąd nie losujemy zawodu 6-cyfrowego równym prawdopodobieństwem.",
		propozycja_do_poprawki_efekty: true,
		zrodlo_nazw: {
			kto: "Ministerstwo Rodziny, Pracy i Polityki Społecznej",
			tytul: "Klasyfikacja zawodów i specjalności — struktura liniowa dla integratorów",
			url: "https://broker.praca.gov.pl/api/liniowy.json",
			strona: "https://psz.praca.gov.pl/dla-integratorow-kzis",
			podstawa_prawna: "Rozporządzenie Ministra Rodziny, Pracy i Polityki Społecznej z dnia 21 października 2025 r. w sprawie klasyfikacji zawodów i specjalności na potrzeby rynku pracy (Dz.U. 2025 poz. 1534)",
			stan_na: DZIEN,
			uwaga: "Zapisane są kod i nazwa. Opisów zadań zawodowych nie kopiowano. Pominięto pozycje z dataDo przed dniem stanu oraz wpis „Bez zawodu”.",
		},
		pominiete: pominiete,
		zrodlo_zarobkow: polska.zrodlo,
		rubryka_efektow_tygodniowych: {
			opis: "Cztery rodziny: praca fizyczna (w tym lżejszy wariant), biurowa, opiekuncza, kreatywna. Zawód dostaje profil po najdłuższym prefiksie kodu KZiS/ISCO. Ten sam profil ma te same liczby całkowite. To nie są dane GUS.",
			propozycja_do_poprawki: true,
			szacunek: true,
			statystyki_gry: {
				zmeczenie_fizyczne: "pasek zmęczenia fizycznego",
				zmeczenie_psychiczne: "pasek zmęczenia psychicznego",
				sylwetka: "sylwetka",
				inteligencja: "propozycja punktów sprawności umysłowej; w grze inteligencja jest na razie rodzajem, nie jedną liczbą",
				zdrowie: "zdrowie",
				wyglad: "wygląd",
				sila: "siła",
				kondycja: "kondycja na ekranie statystyk",
				psychika: "pasek psychiki",
			},
			profile: PROFILE,
			reguly_prefiks: REGULY.map(([prefiks, profil]) => ({ prefiks, profil })),
		},
		liczba_zawodow: zawody.length,
		liczba_zarobki_dziedziczone: dziedziczone,
		liczba_zarobki_null: puste,
		liczba_zarobki_bezposrednie_na_zawodzie: bezposrednieNaZawodzie,
		liczba_wierszy_plac_opublikowanych: placeOpublikowane.length,
		wielkie_grupy_liczniki: licznikiGrup,
		place_opublikowane: placeOpublikowane,
		grupy,
		zawody,
	};

	fs.writeFileSync(OUT_JSON, JSON.stringify(katalog));
	fs.writeFileSync(OUT_MD, markdown(katalog, grupy, zawody), "utf8");

	const przyklady = [];
	for (const fragment of ["Parlamentarzysta", "Lekarz", "Nauczyciel", "Murarz", "Programista", "Sprzedawca", "Aktor", "Oficer"]) {
		const z = zawody.find((w) => w.nazwa.toLowerCase().includes(fragment.toLowerCase()));
		if (z) {
			przyklady.push({
				nazwa: z.nazwa,
				kod: z.kod,
				mediana: z.zarobki ? z.zarobki.mediana_zl : null,
				mediana_zrodlo: z.zarobki ? z.zarobki.mediana_zl_zrodlo : null,
				zarobki_zrodlo: z.zarobki_zrodlo,
				profil: z.profil,
				efekty: z.efekty_tygodniowe,
			});
		}
	}
	console.log(JSON.stringify({
		zawody: zawody.length,
		grupy: grupy.length,
		dziedziczone,
		puste,
		bezposrednieNaZawodzie,
		wiersze: placeOpublikowane.length,
		licznikiGrup,
		przyklady,
		pominiete,
	}, null, 2));
}

function markdown(katalog, grupy, zawody) {
	const nazwaGrupy = new Map(grupy.map((g) => [g.kod, g.nazwa]));
	const grupaPo = new Map(grupy.map((g) => [g.kod, g]));
	const linie = [];
	linie.push("# Katalog zawodów KZiS");
	linie.push("");
	linie.push("Nazwy i kody: klasyfikacja zawodów i specjalności (API integratorów MRPiPS, podstawa Dz.U. 2025 poz. 1534). To nie jest tabela płac.");
	linie.push("");
	linie.push("Płace: GUS, Struktura wynagrodzeń według zawodów za październik 2024 r., tylko wielkie grupy 1–9 już zapisane w `postacie/losowanie/zarobki_kraje.json`. Zawód 6-cyfrowy dziedziczy tę kwotę (`zarobki_zrodlo: grupa_nadrzedna`). Grupa 0 nie ma wiersza, więc płaca jest pusta. Kwota na ekran ma 2 cyfry znaczące; obok w JSON zostaje kwota źródłowa.");
	linie.push("");
	linie.push("Efekty tygodniowe są projektem gry (propozycja do poprawki), nie faktem GUS. Ten sam profil kodu ma te same liczby.");
	linie.push("");
	linie.push("## Rubryka");
	linie.push("");
	linie.push("| Profil | Zm. fiz. | Zm. psych. | Sylwetka | Inteligencja | Zdrowie | Wygląd | Siła | Kondycja | Psychika |");
	linie.push("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |");
	for (const [id, p] of Object.entries(PROFILE)) {
		linie.push(`| ${id} | ${znak(p.zmeczenie_fizyczne)} | ${znak(p.zmeczenie_psychiczne)} | ${znak(p.sylwetka)} | ${znak(p.inteligencja)} | ${znak(p.zdrowie)} | ${znak(p.wyglad)} | ${znak(p.sila)} | ${znak(p.kondycja)} | ${znak(p.psychika)} |`);
	}
	linie.push("");
	linie.push("fizyczna_lekka jest lżejszym wariantem pracy fizycznej (sprzedaż, kierowcy, lekka obsługa), nie osobną statystyką urzędu.");
	linie.push("");
	linie.push("## Wielkie grupy");
	linie.push("");
	linie.push("| Kod | Nazwa KZiS | Zawodów | Płaca |");
	linie.push("| --- | --- | ---: | --- |");
	const placePo = new Map(katalog.place_opublikowane.map((p) => [p.kod, p]));
	for (const kod of Object.keys(katalog.wielkie_grupy_liczniki).sort()) {
		const nazwa = nazwaGrupy.get(kod) ?? kod;
		const n = katalog.wielkie_grupy_liczniki[kod];
		const plac = placePo.get(kod);
		const opisPlacy = plac
			? `dziedziczone z OC${kod}: mediana ${plac.mediana_zl} zł (źródło ${plac.mediana_zl_zrodlo})`
			: "brak wiersza GUS, zarobki null";
		linie.push(`| ${kod} | ${nazwa} | ${n} | ${opisPlacy} |`);
	}
	linie.push("");
	linie.push(`Razem zawodów 6-cyfrowych: ${katalog.liczba_zawodow}. Płace dziedziczone: ${katalog.liczba_zarobki_dziedziczone}. Płace puste: ${katalog.liczba_zarobki_null}. Własny wiersz GUS na zawodzie 6-cyfrowym: ${katalog.liczba_zarobki_bezposrednie_na_zawodzie}. Opublikowane wiersze wielkich grup: ${katalog.liczba_wierszy_plac_opublikowanych}.`);
	linie.push("");

	const poWielkiej = new Map();
	for (const z of zawody) {
		if (!poWielkiej.has(z.wielka_grupa)) {
			poWielkiej.set(z.wielka_grupa, []);
		}
		poWielkiej.get(z.wielka_grupa).push(z);
	}
	for (const kod of [...poWielkiej.keys()].sort()) {
		const lista = poWielkiej.get(kod);
		const nazwa = nazwaGrupy.get(kod) ?? kod;
		linie.push(`## ${kod} ${nazwa} (${lista.length})`);
		linie.push("");
		const plac = placePo.get(kod);
		if (plac) {
			linie.push(`Płaca każdego zawodu poniżej: grupa_nadrzedna OC${kod}, GUS październik 2024. Mediana ogółem ${plac.mediana_zl_zrodlo} zł → wyświetlane ${plac.mediana_zl} zł. Przeciętne ${plac.przecietne_zl_zrodlo} zł → ${plac.przecietne_zl} zł.`);
		} else {
			linie.push("Płaca: null. W zestawie GUS z gry nie ma wielkiej grupy " + kod + ". Nie wpisano kwoty z innej grupy.");
		}
		linie.push("");
		const poDuzej = new Map();
		for (const z of lista) {
			if (!poDuzej.has(z.duza_grupa)) {
				poDuzej.set(z.duza_grupa, []);
			}
			poDuzej.get(z.duza_grupa).push(z);
		}
		for (const d of [...poDuzej.keys()].sort()) {
			const dzieci = poDuzej.get(d);
			const g = grupaPo.get(d);
			const nazwaD = nazwaGrupy.get(d) ?? d;
			linie.push(`### ${d} ${nazwaD} (${dzieci.length})`);
			linie.push("");
			if (g && g.profil_jednolity) {
				const e = g.efekty_tygodniowe;
				linie.push(`Profil: ${g.profil}. Efekty na tydzień (propozycja): zmęczenie fizyczne ${znak(e.zmeczenie_fizyczne)}, zmęczenie psychiczne ${znak(e.zmeczenie_psychiczne)}, sylwetka ${znak(e.sylwetka)}, inteligencja ${znak(e.inteligencja)}, zdrowie ${znak(e.zdrowie)}, wygląd ${znak(e.wyglad)}, siła ${znak(e.sila)}, kondycja ${znak(e.kondycja)}, psychika ${znak(e.psychika)}.`);
				linie.push("");
				for (const z of dzieci) {
					linie.push(`- ${z.kod} ${z.nazwa}`);
				}
			} else {
				linie.push("Profil mieszany wewnątrz tej grupy. Przy nazwisku jest profil, efekty są w rubryce u góry.");
				linie.push("");
				for (const z of dzieci) {
					linie.push(`- ${z.kod} ${z.nazwa} — ${z.profil}`);
				}
			}
			linie.push("");
		}
	}
	return linie.join("\n");
}

function znak(n) {
	return n > 0 ? "+" + n : String(n);
}

main();
