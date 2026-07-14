# PLAYER INFORMATION (FICHA) decode — EQUIPOS.PKF + MANAGER.EXE

The centred white card the magnifying-glass opens over the LINE-UP / SQUAD (reference:
`screens/player_info_ref.jpg`). Renderer = `FUN_0052e0d0` (label layout) reading the player
struct at `*(screen+0x54)`. Reversed 2026-06-26 with Ghidra (`tools/re/ghidra_scripts/
DecompileAt.java` against `~/ghidra-projects/pm98`) + capstone. Ported to
`app/scenes/PlayerInfoScreen.gd`.

## Physical stats — stored METRIC, two bytes after the birth-year anchor

The EXTENDED English record (see `extract_english.py`) carries, right after the u16
birth-year anchor `Y`:

| offset | field        | unit | example (Schmeichel) |
|--------|--------------|------|----------------------|
| `Y`    | birth year   | u16  | 1963                 |
| `Y+2`  | **height**   | cm   | 193                  |
| `Y+3`  | **weight**   | kg   | 101                  |

`Y+2` is the byte an earlier pass mislabelled a "flag >=0x80" — an adult height in cm is
always >=150 (`0x96`), so it doubled as the anchor filter. Validated across 1950 players:
mean 180.9 cm / 75.2 kg, and exact real heights for Giggs 180, Owen 173, Schmeichel/Seaman
193, Beckham 183.

### Why imperial pairs were never found in the file
The FICHA shows weight as `stone pounds` and height as `feet inches`, but PM98 stores
**metric** and converts at render time (`FUN_0058dd70` weight, `FUN_0058de00` height):

```
stone  = floor(kg / 6.35)            # 6.35029 kg per stone   (const 0x639048 = 1/6.35)
pounds = floor((kg - stone*6.35) * 2.2046)        # 0x639050=6.35, 0x639058=14/6.35
feet   = floor(cm / 30.48)           # 30.48 cm per foot      (const 0x639060 = 1/30.48)
inches = floor((cm - feet*30.48) * 0.3937)        # 0x639068=30.48, 0x639070=1/2.54
```

Confirmed against the Bakayoko reference: 75 kg -> "11 11", 178 cm -> "5 10". In memory the
management player struct holds height at `player+0xf9` (cm) and weight at `player+0xfa`
(kg); the FICHA reads `[ebp+0xf9]`/`[ebp+0xfa]` at `0x52e906`/`0x52e881`.

**We show metric directly** (`193 cm` / `101 kg`) — the native stored unit — rather than the
original's imperial conversion (user call 2026-06-26).

## Nationality — the per-player country byte at +0x1a (ALL players; 2026-07-14)

**Authoritative source: EQUIPOS player record byte +0x1a** (`parse_player` `b1a`) — the engine's
own per-player country code, present and in valid PAISES.30 range (1..120) for **every** one of the
9,547 players, compact and extended alike. It is the byte the engine itself uses to draw the flag:
MANAGER.EXE `FUN_004f5260` reads `*(player+0x1a)` and passes it to `FUN_0058d270` (a bounds-checked
`at()` accessor over the flag-DIB collection). So +0x1a → `PAISES.30` name (the NATIONALITY text) →
`BANDERAS.PKF` index (the flag). `kind` = the EU/EEA-1997 comunitario class of that code
(NATIONAL for home-nations + EU/EEA, else NON-NATIONAL; the negative label is still un-walked).

This **replaces** the earlier bio-prose scan (3rd tail string as nationality, ENGLAND default),
which only reached the 94 extended-record clubs and mis-tagged the rest. Verified vs walked FICHAs
(Van der Gouw 27→HOLLAND / 081, Solskjaer 44→NORWAY / 084, Schmeichel 18→DENMARK / ref) and it
corrects the scan's false ENGLANDs (Yorke→TRINIDAD, Hasselbaink→SURINAM, Kinkladze→GEORGIA). The T1
birthplace / T3 `intlRaw` tail strings are still exported verbatim, but for bios, not nationality.
Pipeline: `tools/extract_squads_exact.py` (`natCode`/`nationality`/`kind`) + `build_db.py`
(`flagCode = natCode`). Full write-up: `docs/re/ficha_card_re.md` (2026-07-14 (b)).

## Card-label -> attribute mapping (confirmed vs the Babb reference)

`SPEED=VE STAMINA=RE AGGRESSION=AG QUALITY=CA` · `HANDLING=PO PASSING=PA DRIBBLING=RM
HEADING=RG TACKLING=EN SHOOTING=TI` · `RATING` = the squad-AV (mean of the 8 outfield
attrs) · `FITNESS / MORAL` = dynamic form (not static attrs; defaulted match-fit/settled
for a freshly loaded squad).

The **header subtitle** (under the name) uses the broad 4-entry role LUT
(`PTR_s_GOALKEEPER_00662d10` -> GOALKEEPER/DEFENDER/MIDFIELDER/FORWARD). The **ROLE band**,
however, shows the FINE position name: the renderer at `0x52ea9e` reads the in-memory fine
byte `player+0x18` and indexes the **SHORT fine-name table at `0x662df8`** (`mov dl,[ebp+0x18]`
/ `mov edx,[edx*4 + 0x662df8]`). The reference confirms it -- Bakayoko's subtitle is "FORWARD"
(broad) while his ROLE band reads "CENTRE FORWARD" (fine). See positions_re.md for the full
18-entry table and the posFine mapping. (An earlier pass mislabelled the ROLE band as using
the broad LUT -- corrected 2026-06-26.)

## Open
- **Bio pages + career history — display surface FOUND + walked 2026-07-06.**
  The tail T4..T9 pages + T10 career CSV (exported VERBATIM to `assets/bios.json`)
  display in the **standalone DATA BASE player card (Dbasewin.exe)** — tabs
  PROFILE / TECHNICAL CHAR. / HONOURS / CAREER / INTERNAT. / ANECDOTES /
  LAST SEASON. The FICHA ⓘ coin is **decorative** (FUN_00526640: 40x40 info.gif
  widget, id -1, no handler; no player deep-link exists — the only PCF5 spawn is
  the exit-path mode hand-off FUN_004f8750). Full RE + walked frames + tab
  disable rule: **docs/re/dbase_player_card_re.md**. App build = DataBaseScreen
  track, NOT the FICHA.
- ~~International (compact-record) clubs carry no per-player nationality byte; a separate DBDAT
  structure / NEW RE track is needed.~~ **REFUTED 2026-07-14.** That 2026-06-26 conclusion rested
  on an *approximate* compact-record model (`[u16 year][flag][media]...`) that predates the EXACT
  engine parser (`tools/re/equipos_parse.py`). The exact record has a per-player country byte at
  **+0x1a** for compact AND extended clubs alike (the `flag`/`media` bytes that pass mislabelled
  are the un-RE'd `b16/b17` + attrs at different offsets). Nationality IS recoverable from the
  per-player EQUIPOS bytes — no separate structure required. See the Nationality section above and
  `docs/re/ficha_card_re.md`. (photoId + physicals for compact clubs remain a separate open item:
  compact records still store no BIGFOTO key, and height/weight fall to the engine's load-time
  randomize when < the 150cm / 20kg thresholds.)

## Done
- The fine role-NAME LUT IS located (2026-06-26): SHORT table `0x662df8` / LONG `0x662db0`,
  18 entries indexed by `posFine-1`. The FICHA ROLE band now renders the fine name
  (`FINE_ROLE` in `PlayerInfoScreen.gd`); verified vs the Bakayoko reference. See positions_re.md.
- Nationality FLAG art (`DBDAT/BANDERAS.PKF`) extracted (2026-06-26): the real waving flag
  now blits left of the country name on the FICHA. See `tools/re/export_flags.py`.
- **Action button row (2026-07-02).** When opened from SQUAD MANAGEMENT for your OWN player,
  the card carries **RENEW / TRANSFER / SACK / OK** (builder `FUN_00526a60`; decompile in
  `docs/re/playerinfo/`). Card-local rects (push-tracked disasm): RENEW `(85,325) 104x25`,
  TRANSFER `(196,325) 104x25`, SACK `(307,325) 104x25`, OK `(429,325) 52x25` — three equal
  action buttons + a narrow OK. Wired to `Career.renew` / `toggle_listed` / `release`
  (PlayerInfoScreen emits `renew_/transfer_/sack_requested`; Main runs the action on the live
  roster dict). Read-only (buttons hidden) for another club's player. Frame `081_154619`.
  GAP CLOSED 2026-07-03: the whole card was rebuilt frame-baked to **pixel parity
  0px** vs walkthrough run-1 frames 081 (Van der Gouw) + 084 (Solskjaer), incl. the
  CLAUSES panel + YEARS|LEFT contract split and the host palette-dim — see
  **ficha_card_re.md** (the FICHA's own RE doc from here on). Two data corrections
  fell out of those frames: VdG's nationality decode (HOLLAND sits in the FIRST bio
  string of his record; the extractor now scans all three) and the KIND rule
  (HOLLAND/NORWAY show NATIONAL → EU/EEA-1997 "comunitario" class, not
  British-only). The FICHA RATING formula stays un-RE'd (80/82 in frames vs our
  squad-AV; box parity-excluded).

## Divergences / parity status — RE-VERIFIED 2026-07-13
The screen is `app/scenes/PlayerInfoScreen.gd` (fonts `_f8/_f10/_f12` at native .fnt
sizes — the old `_f18` name font is gone). Verified this pass:
- **Parity 0px** — `shot_entry_parity.gd` + `diff_entry_parity.py`: `ficha_081` vs
  `081_154619` and `ficha_084` vs `084_154626` both **0px, pixel-exact** (ROI = the card
  (76,58)-(564,421)). The RENEW/TRANSFER/SACK/OK row is part of that baked frame chrome, so
  its parity is included in the 0px result.
- **Contract overlay LIVE**: `test_player_actions.gd` ALL PASS — `_hit`/signals for RENEW,
  TRANSFER, SACK, OK; read-only hides the three action buttons for another club's player;
  `Career.release` guards (squad floor / keeper floor / loanee-not-sackable).
- **RATING now RE'd + parity-INCLUDED** (superseding the "un-RE'd/excluded" line above):
  the real `FUN_00581e60` = (VE+RE+AG+CA+FITNESS+MORAL)/6 renders 0px vs 081/084 (80/82).
  See morale_re.md / ficha_card_re.md.
- **Honest gaps** (full list in **ficha_card_re.md** "Honest gaps"): WEIGHT/HEIGHT shown
  METRIC by standing user call (imperial parity-excluded); BIGFOTO downscale kernel un-RE'd
  (NEAREST fit, photo block excluded); the info coin is decorative (FUN_00526640, id -1, no
  handler — NOT a bio deep-link); the read-only (DATA BASE browse) opener covers the three
  action buttons with card white — that opener state is un-walked, kept app behaviour not
  frame truth; dismissal animation un-evidenced (closes instantly); non-EU KIND = hypothesis
  (no non-EU FICHA walked). A form-less demo/GameDB dict renders `-` for WEIGHT/HEIGHT and
  the match-fit/settled defaults for FITNESS/MORAL.
