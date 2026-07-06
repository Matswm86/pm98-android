# DATA BASE player card (Dbasewin) — the bios.json display surface — walked + RE 2026-07-06

**This is where the original SHOWS the EQUIPOS bio tail (T4..T9 prose pages + T10
career CSV).** Walked live under Wine 2026-07-06 (frames:
`screenshots/bio-coin-walk-2026-07-06/`, 034-072). The in-career FICHA ⓘ coin does
NOT open it — see "The coin is decorative" below. The surface lives in the
standalone **Dbasewin.exe** (MFC42), reached: title menu → DATA BASE → SELECTION
screen → player row → this card.

## The card (frames 034-046 Schmeichel = the all-pages witness)

Seven top tabs + two bottom tabs over a 640x480 view; title bar = player
`name + SURNAME` (green banner), kit top-right:

| tab | content source (bios.json per player) | witness frame |
|---|---|---|
| (default) PERSONAL DATA | structured record fields (below) | 034 |
| PROFILE | `pages[0]` | 035 |
| TECHNICAL CHAR. | `pages[1]` (+ WHERE-HE-PLAYS pitch) | 036 |
| HONOURS | `pages[2]` | 037 |
| CAREER (panel header "PROGRESS") | `career` CSV | 038, 042 |
| INTERNAT. (header "INTERNATIONAL") | `pages[3]` | 039, 043 |
| ANECDOTES | `pages[4]` | 040, 044 |
| LAST SEASON | `pages[5]` | 041, 045 |
| DATA (bottom) | = PERSONAL DATA view | 034 |
| NOTES (bottom) | user notebook (COMMON + weeks 1-38 rail), empty; file `NOTAS\e%05d%02d.not` | 046 |

Tab→page mapping is **kill-tested** against the exported bios.json: Schmeichel
PROFILE opener `* Peter Schmeichel currently enjoys…` renders verbatim on the
PROFILE tab (035), the honours witness `Chosen as "Goalkeeper of the Year" 1992`
on HONOURS (037), career first/last rows `1984,Hvidovre,1,30,0` /
`96-97,Manchester U,P,36,0` on CAREER (038/042). Klinsmann (055-058) pins the
mapping per-tab: only his two real pages (pages[1] TECHNICAL, pages[4] ANECDOTES)
are enabled.

## Prose page rendering

- Each `*` in the data renders as a **▶ bullet triangle**; the text after it is a
  paragraph. Multi-`*` pages = multiple bullet paragraphs (039 INTERNATIONAL).
- Paragraphs are **full-justified** (inter-word spacing stretched) except the last
  line of a paragraph (035/040/041); a single short line renders left-aligned
  after the bullet (072 Grodas `▶ FA Cup Champion 97.`).
- Right scrollbar with arrow steppers; up arrow washed at top, down washed at end
  (043/044/045 = scrolled-to-end states).
- Left column: player photo (BIGFOTO) when art exists, else nothing special on
  prose tabs; role word under the photo. TECHNICAL CHAR. replaces the photo with
  the **pitch graphic (RC_DBASE `CAMPO.BMP`) + position/movement markers** (ball +
  arrows: GK bottom-center Schmeichel 036, CF top Klinsmann 056, multi-arrow
  midfield rose Andersson 063) + mini face + "WHERE HE PLAYS....".

## CAREER table ("PROGRESS") — parser truth (Blackwell frame 062)

Columns SEASON | TEAM | DIVISION | MATCH | GOALS (MATCH green, digits navy).
**The EXE parses the whole CSV blob as a flat comma-token stream, 5 tokens per
row** — RE'd in Dbasewin `FUN_00410610` (career loader): rows are linked-list
nodes filled by five successive `FUN_0044c400` comma-token pulls; row count at
`this+0x2d60/0x2d68`.

Binding dirt witness — Blackwell (id 264) carries the typo row
`89-90.Plymouth A,2,7,0` (missing comma). The original renders (062, zoom
`_blackwell_zoom.png`): the merged token lands in SEASON, **every later field
shifts left one column for the REST of the table**, each following season lands
in GOALS ("90-91"… "96-97" overflowing the cell), last row's GOALS empty. Cell
text is centred and clips at both cell edges ("89-90.Plymouth A" → "0. Plymou").
A per-line parser would NOT reproduce this — the port must tokenize the whole
blob (split on `,` and line break alike) and fill 5 cells/row.

`ND,ND,ND,ND,ND,ND` (in the Dbasewin string table) is the **fallback the EXE
sprintf's when the section blob fails to load** (FUN_00410610), NOT a compared
sentinel. The 107 data-side `ND,ND,ND,ND,ND` careers are data dirt of the same
shape.

## Tab enable/disable rule (per-tab, evidence-first)

Original greys (washed label) and dead-clicks a tab when its section is dirt.
Walked witnesses:

| player | data | tabs observed (051-072) |
|---|---|---|
| Schmeichel 1 | all 6 pages + career real | ALL enabled |
| Hiden 93 | `TXT ?` + 5×`Sin datos.` + career `Sin datos.` | ALL 7 disabled |
| Klinsmann 207 | p0 `x`, p1 real, p2/3 `No data.`, p4 real, p5/career `No data.` | only TECHNICAL + ANECDOTES enabled |
| Andersson 11 | p2 = bare `*` | only HONOURS disabled |
| Fullarton 417 | p2/p3 = `x` | HONOURS + INTERNAT. disabled |
| Friedel 68 | career `ND,ND,ND,ND,ND` (+ pages dirt) | ALL disabled |
| Grodas 184 | p2 = `* FA Cup Champion 97.` (21 ch) | HONOURS enabled |

The exact in-EXE predicate is un-RE'd (the prose sentinels `x`/`Sin datos.`/
`No data.`/`TXT ?`/`-`/`*` do NOT appear in Dbasewin's string table, so it is
computed, not compared). Dataset separation is total: every dirt value ≤14 chars
(`x X - * TXT ? No data. Sin datos. ND,ND,ND,ND,ND`), every real section ≥15
chars (`* FA Trophy 95.`). **Port rule: disable when stripped content is in the
sentinel set OR len < 15 — both fit all 2025 players and all 7 walked witnesses;
state this rule in the app doc.**

## PERSONAL DATA view (034 Schmeichel, 050/051 Hiden, 055 Klinsmann, 063, 065, 068)

- BIRTH PLACE bar + **waving nat flag** right; DATE (d/m/y, e.g. `18/11/1963`).
- AGE box — **computed from the SYSTEM clock** ("62 years" for Schmeichel b.1963
  under a 2026 clock; faithful-bug candidate: the port should compute from the
  in-game date instead — decide at build).
- NATIONALITY bar + flag; INTERNATIONAL box = country when capped, `-` when not
  (Hiden 051, Fullarton 065).
- LAST CLUB green bar: `club (yy)` e.g. `Brondby (91)`, `Rapid Vienna (98)`,
  `Columbus Crew (97)` — previous-club string + join year.
- HEIGHT / WEIGHT purple bar — **imperial** (`6 3`, `15 12`), converted at render
  (same 30.48/6.35 constants family as the FICHA, player_info_re.md).
- Left: photo when art exists (Schmeichel/Klinsmann), else the CAMPO pitch with
  position markers (Hiden 050, Andersson 063, Fullarton 065, Friedel 068).

## The in-career FICHA ⓘ coin is DECORATIVE (MANAGER.EXE RE, closes the 07-06 open item)

- Built by `FUN_00526640` (docs/re/playerinfo/): 40x40 widget at card-local (7,7)
  → screen (83,65)-(123,105), art `RECURSOS\ICONOS\info.gif` (animated — the
  spin), **control id -1, empty label**. Clicked live (single/double/right,
  frames 019-024): no reaction; the gif just cycles.
- No player deep-link into the DB exists: the only PCF5 spawn is the exit-path
  hand-off `FUN_004f8750` — `sprintf("%c:PM98.EXE PCF5%X", drive, mode)` where
  `mode = menu-result - 0x4e1e` from the main loop `FUN_004f81e0` (decompiles in
  scratch; MANAGER.EXE exits, PM98.exe dispatcher spawns dbasewin.exe). A mode
  int, not a player id.
- Under Wine that hand-off dies silently (MANAGER exits, child never appears) —
  launch `wine Dbasewin.exe` directly from the PM98 dir instead.
- **App consequence: do NOT wire the coin to bios.** The bios.json consumer is
  the DATA BASE player card above (DataBaseScreen track). The coin stays baked
  animated art on the FICHA.

## Chrome sources for the rebuild

RC_DBASE.PKF (render with `tools/re/rc_dbase_image.py`): card background =
`FONDO_SCREENS.BMP` family, top banner, tab strip, `CAMPO.BMP` 132x190 pitch,
`sombra foto1/2.bmp` photo shadows, `flecha on/off/paso.bmp` scroll arrows,
`agujero notas.bmp` + notebook art for NOTES, `bot_azul/rojo *.bmp` buttons
(PRINT blue / RETURN green live in FONDO?), fonts `Proman8/micro8/futcon8` +
proman12 for headers (exact per-label faces un-RE'd — pin at bake vs frames).
Frames 034-072 are the composed truth for every layout rect.

## APP BUILD (2026-07-06) — DataBaseCardScreen.gd + bake + parity harness

Built: `app/scenes/DataBaseCardScreen.gd` (raised from the DATA BASE squad
view row tap, replacing the interim FICHA hop), chrome bake
`tools/re/build_dbase_card_chrome_from_frames.py` (kill-tested per layer),
shots `app/tests/shot_dbase_card.gd`, differ
`tools/re/diff_dbase_card_parity.py`. Findings pinned during the build:

- **Live Dbasewin palette = LIGA_ESTRELLAS.BMP's embedded table** — BIGFOTO
  photos + BANDERAS flags decode 0px vs the card frames with it; the DAT.PKF
  @0x5ca palette does NOT match (3% of the Schmeichel photo off). The card
  ships its own decoded banks `art/faces/dbcard/` (612) + `art/flags/dbcard/`.
  (The app's FICHA faces bank is a DIFFERENT rendering — left untouched.)
- **Fonts (mask-exact pins)**: banner name PROMAN18 (fill = per-draw engine
  speckle in 4 greys {255,240,220,192} + band-darkening shadow — parity masks
  the name box); tab labels FUTCON8; panel titles PROMAN12 (noise-tinted
  white); PERSONAL DATA labels/values + career CELLS + role word PROMAN8/10;
  prose body KKITA. `futcon8` + `kkita` BMFonts exported.
- **Tabs = the FICHA piece widgets** (OFF 1/2/3: 8px caps + 8px tiles + 20px
  diagonal, width 28+8N == the reversed spans). DISABLED = a parity-gated
  palette-space halftone wash of the tab against what lies beneath — learned
  as an exact LUT (53 keys, 0 ambiguous) and used to synthesize the un-walked
  seam-pair positions (model exact on every observed seam; rd/dd are
  fondo-dependent so per-position, rr/dr shared). 15 compose kill tests incl.
  the Klinsmann mix and 062's walked (dis,sel) seam.
- **INTERNATIONAL box = tail T3 VERBATIM** ("Denmark"/"USA"/"-"/"No";
  witnesses 034/050/055/065/068) — exported as `intl` in bios.json.
  NATIONALITY = the PAISES name for flagCode ("U.S.A."), value bars are flat
  single-colour rects; both flags carry a 1px black widget frame; the big
  NATIONALITY flag is the 30x20 BANDERAS in a 33x22 frame (not stretched).
- **AGE = whole years at the SYSTEM clock** (62/53/52 in the 2026 captures) —
  implemented faithfully with `now_unix` injectable for parity.
- **Career PROGRESS**: flat comma/newline token stream, 5 cells/row (062
  Blackwell shift reproduced); cells PROMAN10 centred per cell with TRUE
  pixel clipping (partial glyphs at cell edges — drawn via atlas-region
  rects); 12 fixed grid rows; the career scrollbar chrome ≠ the prose one
  (separate stepper/slab/track cuts per view; prose carries a bar frame at
  x574..584 the career bar lacks).
- **Parity: ALL 8 walked states 0px** (differ, name-box masked as speckle
  noise): 034 PERSONAL DATA, 035 PROFILE, 037 HONOURS, 038 CAREER,
  046 NOTES, 055 Klinsmann tab-states, 062 Blackwell CAREER typo-shift,
  072 Grodas short HONOURS.

## TAP-THROUGH (2026-07-06) — the input path itself, driven

`app/tests/shot_dbase_card_tapthrough.gd` drives the booted Main end-to-end by
synthesized `InputEventScreenTouch` press/release (+ drag-scroll) — TITLE →
DATA BASE → league → club → squad row → card → CAREER tab → RETURN → RETURN —
never calling the nav methods directly (that half is `test_browse_nav.gd`).
25 asserts + a PNG per stage (`PM98_TAP_DIR`, default `out/tap`). Needs a
rendering driver (the squad view's row rects fill in `_draw`).

**Double-fire law it caught**: with `emulate_mouse_from_touch` (Android
default) every touch also arrives as an emulated mouse event. Release paths
guarded by a was-target match (buttons, tabs) absorb the twin; unguarded
fall-throughs do NOT — `DataBaseScreen`'s row/empty-space release fired twice,
stacking TWO player cards per tap (RETURN then appeared dead). Fixed with the
`BrowseScreen`-pattern `_down` gate; any new screen with a release fall-through
needs the same gate, and the harness asserts exactly-one-screen per tap.

## PROSE LAYOUT LAWS (2026-07-06, frame-fitted — closes the ±px lever)

Derived by `tools/re/fit_prose_advances.py` from ALL 12 prose frames of the
bio-coin walk (035-045, 056, 058, 072): **168/168 rows pixel-exact**,
119/119 unjustified word-pair advance equations exact. Implemented 1:1 in
`DataBaseCardScreen.gd` (`_prose_lines`/`_gdi_stretch`/`_draw_prose`).

1. **Advances**: the kkita BMFont xadvance table is exact as exported
   (space = 6). No per-glyph correction was needed — the old ±px residual
   was never advances.
2. **Bullet**: `*` renders as the ▶ glyph, advance 9, at x214; the source
   text continues VERBATIM — its leading space(s) render 6px each and are
   justification breaks ("* Peter" = 15px indent; Schmeichel internat
   para 3 is `*A member` = NO gap, walked 039/043).
3. **Multi-space gaps** render 6px per space (the data carries doubles);
   each space is its own justification break.
4. **Wrap capacity 570** (= X1+1): break before a word whose natural
   pen-end would exceed 570 ("…Rapid Vienna which" packs to 570, 041).
5. **Line table = 24 lines**; overflow DROPPED, and the 24th line
   justifies like any broken line (044 end: the huge-gap "In September
   1995 Manchester United were" is the last line ever shown).
6. **Viewport = 14 rows** (not 17); scroll max = lines-14 (039 rows 14/15
   empty; all three end-scroll frames sit at L-14).
7. **Justification** (every line except a paragraph's stored last): flush
   target 569; with deficit D over n breaks, cumulative stretch after
   break j is
   - `floor(j*(D+1)/n)` when `8*(D+1) % n == 0` ((D+1)/n representable in
     eighths — always true for n=8; total D+1, pen-end lands on 570);
   - else base `D//n` per break + remainder r placed one px each at
     breaks `floor(n*i/(r+1))`, i=1..r (evenly spread, ends bare; total
     D, pen-end 569).
8. **Glyph cell tops at y147+16*row** (PROSE_Y0-3: kkita ink rows 3-12
   land at 150+16r..; the prose `_txt` draws at y-3).
9. **Prose page border**: open-right 1px grey(128) box — rows y128 + y393
   spanning x189-575, column x189 (careers bake carries its own left edge;
   this one is prose-view drawn).
10. **Career clipped cells centre by C trunc-toward-0**, not floor:
    `cx0 + int((cellw - wpx)/2)` — differs only when the text overflows
    the cell (the 062 shifted rows; closed 062 to 0px).

## Open

- Exact tab-enable predicate in Dbasewin (upstream of FUN_00410610) — only if the
  empirical rule ever misfires.
- Scroll-thumb travel beyond the walked pair (038 off-0 pinned; 042 [+30px
  for 2 rows] fitted; other page sizes proportional, documented).
- Big-flag art for un-walked countries (framed BANDERAS fallback; the 6
  walked ones ship as frame patches).
- Banner-name speckle: deterministic stand-in; live tap-through of the full
  title→DB→card flow on a device still to be eyeballed.
- SELECTION screen (kits grid + alphabet rail + ALL/NATIONAL/OVERSEAS +
  PLAYERS/SEARCH/MANAGERS) walked in the same session (030-033, 047-054,
  059-061, 064-071) — layout RE for the app's DB browser track lives in
  database_screen_re.md; these frames extend its evidence.
- MANAGERS branch, SEARCH, COMPARE, HISTORY/PROGRESS screens: un-walked.
