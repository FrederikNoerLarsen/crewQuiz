# Crew Quiz

Jeopardy-agtigt quizbræt med Spotify-afspilning.

## Filer

| Fil | Hvad |
|---|---|
| `index.html` | Hele appen — bræt, spørgsmål, Spotify-logik |
| `start.bat` | Starter den lokale server og åbner browseren |
| `serve.ps1` | Indbygget mini-webserver — bruges hvis Python ikke er installeret |

## Kom i gang

1. Dobbeltklik **`start.bat`** — den starter en lokal server og åbner
   `http://127.0.0.1:8080/` i browseren.
   Lad det sorte vindue stå åbent mens I spiller.
   *(Åbn ikke `index.html` direkte — Spotify-login virker ikke fra `file://`.)*
2. Klik **Spotify-opsætning** øverst til højre og følg de 5 trin.
3. Sæt flueben ved **Web API** og **Web Playback SDK** i Spotify-dashboardet,
   og brug præcis denne Redirect URI:

   ```
   http://127.0.0.1:8080/
   ```

4. Indsæt dit **Client ID**, klik *Gem & forbind*, godkend i Spotify.
   Prikken øverst bliver grøn når afspilleren er klar.

> Kræver **Spotify Premium** — det er et krav fra Spotifys Web Playback SDK.
> Uden Spotify virker quizzen stadig: “Hint” viser i stedet sangtitel og
> starttidspunkt, så du kan afspille manuelt fra din telefon.

## Sådan spiller man

- Første gang appen åbnes spørger den om de **tre holdnavne**. Derefter
  vises pointtavlen øverst på brættet — føringen markeres med 👑.
- Brættet viser kategorier i kolonner, 100 øverst til 500 nederst.
- Klik en værdi → spørgsmålet vises. Holdenes stilling ses som små
  chips oppe til højre.
  - **Hint** — afspiller sangen (fra det rigtige tidspunkt), eller viser
    svarmulighederne ved multiple choice. Tryk igen for at stoppe musikken.
  - **Vis svar** — viser facit, og nu dukker **pointknapperne** op:
    hvert hold har `+værdi` og `−værdi`. Klik holdet der svarede rigtigt.
    Kom du til at klikke forkert, ruller **↩ Fortryd sidste** det tilbage.
- Brugte felter bliver mørke. **Nulstil bræt** rydder dem.

### Genveje

| Tast | Gør |
|---|---|
| `1` `2` `3` | Giver feltets point til hold 1 / 2 / 3 *(kun på svarskærmen)* |
| `Shift` + `1` `2` `3` | Trækker feltets point fra |
| `Z` | Fortryd sidste pointtildeling |
| `Esc` | Tilbage til brættet — stopper også musikken |

### Hold og point

Klik **Hold** i toppen (eller på et holdkort på brættet) for at omdøbe hold
undervejs — pointene følger med. Samme dialog har **Nulstil point**, som
nulstiller stillingen uden at røre brættet. Holdnavne, point og brugte
felter gemmes i browseren, så et utilsigtet refresh koster ingenting.

## Redigér spørgsmål

Alt indhold ligger i `index.html` i blokken markeret
`SPØRGSMÅL — rediger frit herunder` (øverst i `<script>`).

```js
{ value:100, type:"lyric",
  prompt:"____ ____, oh yeah, ...",
  answer:"your skin, oh yeah, ...",
  track:{ q:"Yellow Coldplay", startMs:87000 },
  trackLabel:"Coldplay — “Yellow” (1:27)" }
```

| Felt | Betydning |
|---|---|
| `type` | `"song"` (gæt person), `"choice"` (3 muligheder), `"lyric"` (gæt ordene) |
| `track.q` | Søgetekst — appen slår sangen op på Spotify og husker resultatet |
| `track.uri` | Valgfri. Låser den præcise sang: `spotify:track:<id>` |
| `track.startMs` | Hvor i sangen klippet starter, i millisekunder (1:27 = 87000) |
| `trackLabel` | Vises som fallback hvis Spotify ikke er forbundet |
| `choices` / `correct` | Kun ved `type:"choice"`. `correct` er indeks 0, 1 eller 2 |
| `todo` | `true` dæmper feltet — til spørgsmål der endnu ikke er skrevet |

### Lås en bestemt sang
Hvis søgningen finder den forkerte version: i Spotify-appen højreklik på
sangen → *Del* → *Kopiér link til sang*. Linket ser sådan ud:
`https://open.spotify.com/track/`**`3AJwUDP919kvQ9QcozQPxg`**`?si=...`
Tag id'et og skriv `uri:"spotify:track:3AJwUDP919kvQ9QcozQPxg"` i `track`.

## Fejlfinding

**“Kan ikke oprette forbindelse til 127.0.0.1:8080”**

Serveren kører ikke. Kig i det sorte cmd-vindue — det lukker ikke længere af sig
selv, så fejlen står der.

- *Vinduet lukkede med det samme / blinkede væk:* du har en gammel `start.bat`.
  Brug den nye — den falder tilbage til `serve.ps1` (PowerShell er altid
  installeret på Windows), så der kræves ingen Python.
- *“Address already in use” / “Kunne ikke starte server på port 8080”:*
  porten er optaget. Åbn et cmd-vindue i mappen og kør `start.bat 8090`,
  åbn så `http://127.0.0.1:8090/` — og husk at tilføje den nye adresse som
  Redirect URI i Spotify-dashboardet.
- *Browseren åbnede for hurtigt:* tryk bare F5 et par sekunder efter.
- Brug **`127.0.0.1`**, ikke `localhost` — Spotify afviser `localhost`.

**Vil du bare teste quizzen uden musik?**
Åbn `index.html` direkte. Alt virker undtagen Spotify-afspilning; “Hint”
viser i stedet sangtitel og starttidspunkt.

## Bemærk

- `Missy Elliott — "Reverse It"` hedder i virkeligheden **"Work It"** —
  appen søger efter "Work It Missy Elliott".
- Kør alle 15 klip igennem én gang inden quizaften. Appen finder sangene
  ved søgning, så tjek at den ikke rammer en live- eller remix-version —
  ellers lås den rigtige med `uri:` som beskrevet ovenfor.
