# PM98 Android — reverse-engineering toolkit

Tools and file-format documentation for reverse-engineering **Premier Manager 98**
(Dinamic Multimedia, the PC Fútbol / "OPTIMUM" engine family), with the goal of a
native **English Android clone** that reads the original game's own data and
reproduces its gameplay.

> **This repository contains code and format notes only — no game content.**
> No game files, no extracted data, no copyrighted assets are included or
> redistributed here (see `.gitignore`). To use the tools you must supply your own
> legally-owned copy of the game; everything under `extracted/` and `assets/` is
> derived locally for personal use and is never committed. This is a personal
> preservation / interoperability project for the author's own copy.

## What's been figured out

Full detail in [`docs/FORMATS.md`](docs/FORMATS.md); plan in
[`docs/ROADMAP.md`](docs/ROADMAP.md). Highlights:

- **`.30` string tables** (countries, first names, surnames) — cipher solved, decode
  to clean English.
- **`EQUIPOS.PKF` team + squad records** — fully decoded. Every detailed team record
  is marked by a `Copyright (c)1996 Dinamic Multimedia` string (476 of them). The
  per-player record carries two name fields (common + legal, with accents), birth
  year, an overall rating, and 10 attributes (VE RE AG CA RM RG PA TI EN PO).
- The **name cipher** (pair-swapped alphabet) and the **accent byte map**
  (Á Ç É Í Ï Ñ Ó Ú Ö Ü ª) are documented and verified against real 1997-98 rosters.

The extractor reproduces, for the author's own copy, the 20 Spanish Primera squads
(533 players, verified against reality) and 281 club squads across the European /
South-American leagues (5654 players). Output JSON is gitignored.

## Tools

All standalone Python 3, run from the repo root with your own game files placed
under `extracted/Premier Manager 98/`:

| script | purpose |
|--------|---------|
| `tools/pm98_strings.py`   | decode the `.30` string tables → JSON |
| `tools/extract_squads.py` | decode team headers + full squads from `EQUIPOS.PKF` |
| `tools/parse_equipos.py`  | low-level team-record index walker (research) |
| `tools/extract_clubs.py`  | English club-name census (research) |
| `tools/equipos_dump.py`   | raw cipher-string dump (research) |
| `tools/decode30.py`       | early `.30` brute-forcer (superseded) |

## Status

Asset reverse-engineering is well underway (strings + team/squad data done). Still
to do: English-league squad framing, image (PKF) decompression, audio, then the
clone engine + UI. See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Legal

*Premier Manager 98*, *PC Fútbol*, all club/player data, names, graphics, audio and
trademarks are property of their respective rights holders (Dinamic Multimedia and
others). This project is not affiliated with or endorsed by them. The code here is
original work; it ships no game data. Use it only with a copy of the game you own.

## License

Code is released under the MIT License (see [`LICENSE`](LICENSE)). The license
covers the original code and documentation in this repository only — not the game
or any of its data.
