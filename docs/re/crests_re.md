# Club crest / escudo (T1 #2, D3)

Evidence: tools/re/map_crests.py, app/art/kits, docs/re/pkf
  -- the mapper/exporter, the 476 exported kits it writes, and the PKF format notes underneath.

## Finding: in PM98 the "crest" IS the kit
The roadmap listed "club crests / badges (escudos)" as a separate, unrendered asset. It is
not separate. PM98 has no club badge/logo art. The club's on-screen identity is its **kit
(shirt)** — the `escudo` archives are kit graphics at four sizes, all keyed by the same
`EQ96DDNN` code (decoded in `tools/re/map_crests.py`):

| archive | size each | px | use |
|---------|-----------|-----|-----|
| NANOESC.PKF | ~0.8 KB | 24x32 | tiny |
| RIDIESC.PKF | ~0.4 KB | 17x20 | list bullet |
| MINIESC.PKF | ~3.1 KB | 48x64 | the one we export -> `app/art/kits/<id>.png` |
| BIGESC.PKF  | ~31 KB  | 160x194 | full shirt+shorts+ball (English only, 92) |

`map_crests.py --export` writes ALL 476 MINIESC kits to `app/art/kits/<club_id>.png`
plus the NANOESC pairs to `app/art/kits/nano/<club_id>.png` (committed; CI regenerates
`.import`). `KIT_SRC = Rect2(0,0,31,64)` crops the shirt half. English ids map via the
verified record==id identity; foreign ids (1000+) via the positional replay of
build_db.py's id assignment over teams_all record order — the crest-index name is
asserted EQUAL to the teams_all header name for every named foreign club, and the five
'?'-header clubs (P.S.G., CHÂTEAUROUX, GÖTEBORG, GALATASARAY, HAKA) are named by the
index itself (2026-07-04; was English-only with 32 foreign clubs unmatched by name).

## Where the kit renders
Already on the **league table**, **line-up**, and as the per-club **kit colour** in the 2D
match view. This change adds it to the three screens that lacked it:

* **Hub (MenuScreen / MENUPRINCIPAL)** — the managed club's kit centred above the club name
  (`setup(... , club_id)`, fed from `Career.club_id` in `Main._mount_hub`). PM98 shows the
  kit here; the reversed `menu_bg` carries none, so it is drawn dynamically.
* **Squad screen (SquadScreen)** — the club kit in the free right-strip gap between the
  SQUAD cell and the YOUTH button (id from the club dict).
* **Match scoreboard (MatchScreen)** — each side's kit flanking the centre score pill
  (`_home_kit` / `_away_kit`, loaded in `setup` from the home/away ids).

Coverage = all 476 clubs since 2026-07-04 (MINI + NANO + RIDI banks each hold all 476
`EQ96<code>.BMP` entries; only BIGESC is English-only at 92). The null-guard on the draws
remains for safety. Tests: `test_menu_screen`, `test_squad_screen`, `test_match_screen`
each assert the kit texture loads; verified by real GL renders of the hub, squad and
match captures.
