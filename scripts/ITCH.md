# itch.io — APK z aktualizacjami przez internet

Stały link do gry (np. `https://TWOJ_LOGIN.itch.io/not-that-real-life`), ziomek pobiera APK i przy nowej wersji wchodzi w ten sam link.

## Co już jest lokalnie

- Preset eksportu Godota **Android** → `build/NotThatRealLife-0.4.apk`
- `butler` (CLI itch.io) — zainstalowany oficjalnym zipem do `%LOCALAPPDATA%\butler`
- Skrypty: `itch-upload.ps1`, `zbuduj-i-wrzuc-itch.ps1`
- Wzorzec env: `itch.env.example` → skopiuj jako `itch.env` (nie commitowany)

## Pierwszy raz (Ty — ok. 4–5 kliknięć)

1. **Konto** — wejdź na [itch.io/register](https://itch.io/register), załóż konto (login = `ITCH_USER`).
2. **Nowa gra** — Dashboard → **Create new project** → tytuł `Not that real life`, URL slug `not-that-real-life`, Kind of project: **Downloadable**, zapisz.
3. **butler login** — w PowerShell: `butler login` → otworzy przeglądarkę, zatwierdź API key (albo ustaw `$env:ITCH_API_KEY` z [ustawień API](https://itch.io/user/settings/api-keys)).
4. **Lokalny login itch** — skopiuj `scripts\itch.env.example` → `scripts\itch.env` i wpisz `ITCH_USER=twoj_login`.
5. **Pierwszy upload** — w katalogu repo:
   ```powershell
   .\scripts\zbuduj-i-wrzuc-itch.ps1 -TylkoWrzuc
   ```
   (bierze istniejące `build\NotThatRealLife-0.4.apk`). Albo bez flagi — zbuduje Godotem i wrzuci.

Na stronie gry w itch: ustaw kanał **android** jako downloadable / widoczny (butler tworzy kanał przy pierwszym pushu).

## Jak ziomek pobiera

1. Otwiera `https://TWOJ_LOGIN.itch.io/not-that-real-life`
2. Klika **Download** → APK
3. Na telefonie instaluje (trzeba zezwolić na instalację z nieznanych źródeł / z przeglądarki)

Aktualizacja = znowu ten sam link, nowszy APK.

## Potem: jedna komenda

Tylko wrzucenie już zbudowanego APK:

```powershell
.\scripts\zbuduj-i-wrzuc-itch.ps1 -TylkoWrzuc
```

Albo zbuduj + wrzuć:

```powershell
.\scripts\zbuduj-i-wrzuc-itch.ps1
```

Dry-run (bez wysyłki):

```powershell
.\scripts\zbuduj-i-wrzuc-itch.ps1 -TylkoWrzuc -DryRun
```

Target butlera: `ITCH_USER/not-that-real-life:android` (kanał można zmienić przez `ITCH_CHANNEL` albo `-Channel`).

## Bezpieczeństwo

- Nie commituj `scripts/itch.env`, API key ani credentials butlera.
- Klucz: tylko `butler login` albo zmienna środowiskowa w sesji — nie do gita.