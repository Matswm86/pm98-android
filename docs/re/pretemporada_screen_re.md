# PRESEASON screen ("Preseason for <club>") — reversed from MANAGER.EXE

Binding frames: `screenshots/original-walkthrough-2026-07-02/013-016_1543xx.png`
(013 = fresh screen for Manchester Utd.; 015 = country selected (HUNGARY strip);
011→012 diff proves SELECCION CONTINUE → this screen; after 016 → main hub).

Widget-creation function ~`0x4c6400..0x4c7a00` (xrefs: "Preseason for " 0x4c6d9c,
SKIP 0x4c6d02, S. AMERICA 0x4c6f3a, hoja_calendario ×4 at 0x4c673f..0x4c68d7,
DELETE 0x4c6c08). Full-screen 640×480, client = screen coords.

## Reversed widgets (capstone; pos=(x,y), size=w×h)

| widget | pos | size | notes |
|---|---|---|---|
| "Manager League" plaque | (26,8)+(40,21) | 120×18 / 70×18 | top-left, as other screens |
| Title "Preseason for <club>" | (150,16) | 350×27 | ProMan14 white, on BARRA |
| EUROPE tab (id 200, style 0x30000) | (3,78) | 21×112 | VERTICAL text tab |
| S. AMERICA tab (id 201, style 0x20000) | (3,190) | 21×112 | vertical |
| Map | (27,80) | 300×220 | `recursos\iconos\ofertas\EUROPA.BMP` 300×220 (SUDAMERICA.BMP for tab 2) |
| Country-name strip | (7,304) | 322×~22 | black bar, white ProMan12 text (frame 015 "HUNGARY") |
| Kit panel (white) | (8,336) | 321×130 | selected country+division club kits, 2 rows of 10 |
| 4× calendar sheet | x≈325, y≈86/144/202/260 (frame) | 40×47 | `img\premier\pretemp\HOJA_CALENDARIO.BMP`, date in Calend8 font, red day number |
| 4× RIVAL slot caption | x≈377, y≈78/136/194/252 (frame) | 252×49 | white RIVAL header + 2 rows; red number badge 24×49 at right (frame: x 605..629) |
| SKIP (id 1) | (503,333) | 112×25 | white text |
| PREMIER (id 300, style 0x20000) | (383,370) | 112×25 | division filter, yellow selected |
| FIRST (id 301) | (503,370) | 112×25 | |
| SECOND (id 302) | (383,403) | 112×25 | |
| THIRD (id 303) | (503,403) | 112×25 | (rect assumed symmetric w/ SECOND; creation past walked range) |
| DELETE (id 906) | (383,440) | 112×25 | red, icon `recursos\iconos\seleccion\borra.bmp` |
| CONTINUE (id 918) | (503,440) | 112×25 | yellow |

Aux art: `img\pretemporada\{OVER,AZULBARRAS,X}.BMP` (hover overlay, slot bars, X marker);
`recursos\iconos\seleccion\over.bmp` (button hover).

## Palettes

EUROPA.BMP embedded palette is junk → force MANAGER.PAL (VGA identical). Map = yellow
landmass / blue sea, no baked flags.

## Flags on the map

Drawn at runtime, ~18×13 black-bordered country flags (same flag art family as the
FICHA nationality flags already baked at `app/art/flags/flag_NNN.png`). ~35 markers.
Positions measured off frame 013 (inner-rect top-left, abs px, see
`tools/re/specs/pretemp_flag_markers.json` written by the build): sample
(83,94) Norway-ish … (39,241) Portugal, (60,245) Spain, (141,143) UK cluster, etc.
Identity per marker resolved at build time by SAD-matching the frame patch against the
baked flag PNGs — do NOT hand-guess countries.

## Behaviour (from frames)

1. Tap a flag → country selected: name in the black strip (015 "HUNGARY"), kit panel
   shows that country's clubs (for England the PREMIER/FIRST/SECOND/THIRD filter
   applies; buttons live only for countries with >1 division in DB).
2. Tap a kit → prospective rival; assigns into the ACTIVE rival slot (slots fill in
   order; slot 1 active = white header, others dimmed until filled).
3. 4 preseason friendly dates: 1 / 4 / 6 / 8 August 1997 (red day number on calendar
   sheet, "August 1997" beneath).
4. SKIP = no (more) friendlies; DELETE = clear a slot; CONTINUE = confirm & start the
   career (empty slots allowed — owner continued with all 4 empty).

## App wiring honesty

The app's Career/fixtures currently has no friendly-match support; the match loop is
the next engine milestone (line-up handoff). The screen stores picked rivals + dates
into the career save (`preseason_rivals`); simulation of those friendlies lands with
the match loop. SKIP/CONTINUE path fully functional. Foreign-club coverage depends on
GameDB (England fully present; foreign clubs as available in the decoded DB).
