# Shared MATCH-CONTEXT BARRA/HEADER (y0..61) — frame-decoded spec

The band above every fixture-week management screen (TACTICS / LINE-UP /
VIEW RIVAL / MAN-TO-MAN MARKINGS ...): club plaques + kit panel (left), barra
with the screen title (centre), calendar sheet + status plaques + ball (right).
Baked by `tools/re/build_match_header_from_frames.py`; rendered by
`PMChrome.draw_match_header()`; anchors recorded in
`app/art/screens/header/header_samples.json`.

Binding frame: `014_162413` (TACTICS, F.C. Barcelona / Manchester Utd.,
Monday 4 August 1997) — the tactics_014 parity pair is FULL FRAME 0px since
this pass. Witnesses recomposed pixel-exact by the bake: 014, 015_162415
(VIEW RIVAL), 155_162931 (LINE-UP, Man Utd / Sao Paulo, Wednesday 6),
138_154814 + 128_154751 (Juventus / Man Utd, Friday 1), 058_162622
(MAN-TO-MAN MARKINGS, manager mode MWM / Man Utd).

## Decoded facts (all asserted in the bake)

- **Header family**: 61 walkthrough frames share the band; outside the
  declared dynamic zones every one is pixel-identical to 014. 040_162531
  carries the mouse cursor in-band and is excluded.
- **Name plaques** (x0..107; kit-panel border at x108): flat faces
  (180,200,220) top / (80,100,120) bottom, black 1px frames, the barra dither
  showing through a 1px gap between them. Text = **PROMAN8**, black ink on the
  top plaque / white on the bottom, XOR=0 on all five walked strings.
  Centring is the GDI rule **px = (S - extent) div 2** with **S=107 top,
  S=108 bottom** (unique fit over origins of widths 27..98; extent = sum of
  FNT advances, no kerning, no clipping).
- **Kit panel, fixture mode**: the club's **RIDIESC.PKF 17x20 kit blitted 1:1
  at (116,10) home / (116,30) away — SAD 0.0**, no shadow pass. RIDIESC is
  keyed by the same EQ96 codes as MINIESC/NANOESC (assets/crest_codes.json);
  444 club kits exported to `app/art/kits/ridi/<club_id>.png` (32 foreign
  clubs have no exact name match in the EQUIPOS index — no kit exported yet).
- **Kit panel, manager mode** (frame 058): different panel furniture (no
  fixture border box) + the **NANOESC 24x32 kit at (114,15) WITH the engine's
  soft shadow pass** (the SELECCION panel-kit precedent), so the walked club
  ships as a frame patch: `app/art/kits/header/40.png` = the whole panel zone
  (108,8)-(143,52) cut from 058. Un-walked clubs fall back to the shadowless
  NANOESC blit (documented reconstruction).
- **Calendar sheet**: flat white, spiral binding baked. Four **PROMAN8**
  lines — weekday black, day red (255,0,0), month black, year blue
  (42,95,170) — glyph-canvas tops y15/26/35/46, centred **px = (968 -
  extent) div 2** (S=968 is the unique fit over all eight walked strings).
  NOT the CALEND faces.
- **Status plaques**: flat faces (127,159,85) top / (85,95,0) bottom; text =
  the **'Result' face (CALEND12.FNT**, exported as `calend12.fnt`; RESULT.FNT
  carries the same face), black top / white bottom, tops y14/y32, centred
  px = (1163 - extent) div 2 (S ambiguous {1163,1164} — only two walked
  strings, 'Preseason'/'Preparation'). The ball overlaps the plaques' right
  ends and stays baked in the band; no walked text reaches it ('Preparation'
  ends x609, ball starts x612).
- **Title**: the big chrome-gradient face is NOT a 1-bpp WINFONTS render (no
  FNT matches; glyphs carry a vertical gradient + outline + shadow), so
  walked titles are **frame sprites** over the reconstructed barra:
  `title_{tactics,viewrival,lineup,mtm}.png` at (254,22)/(240,22)/(254,22)/
  (173,22). TACTICS is witnessed identical between run 1 and run 2.
- **barra0.png is NOT this barra** (max channel-sum diff 139/px on clean
  columns) — consistent with the seleccion finding that the BARRA/FONDO
  assets don't reproduce the rendered band under any .PAL. The entry-flow
  barra (frames 010/012/016) is also a different gradient.

## Honest gaps / reconstructions (invisible in every walked state)

- **Title-zone barra**: reconstructed per pixel by majority over the 8
  DISTINCT title clusters (one title, one vote — a plain frame mode let the
  18-frame LINE-UP bloc ghost through). Pixels that every walked title inks
  with the same colour (glyph interiors share colours at equal y) remain
  unwitnessed and keep that colour in band.png. This CANNOT affect parity —
  each walked title's sprite recomposes its frame exactly over the same
  pixels — and shrinks as more titles get walked.
- **Kit-panel core** (x116..132 y15..46): covered by a kit in every walked
  layout; filled with the face colour (140,140,180). Never visible in-game.
- The name/status/calendar centring rules are proven only on the walked
  strings; in-season status strings are entirely un-walked.
- Manager-mode kit patches exist for Man Utd only (058).
- ~~Preseason-friendly fixture header un-wired~~ — CLOSED 2026-07-04:
  `Main._next_fixture()` resolves the pending friendly first (home/away from
  the pick's witnessed continent-tab rule), so the header shows the friendly
  fixture exactly as the run-2 witnesses do (014/015/155/138/128); league
  weeks show the league fixture, byes the manager plaques.
