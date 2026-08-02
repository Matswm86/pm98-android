# SELECCION (ENTER YOUR NAME AND SELECT A TEAM) — a live capture, 2026-08-02 (s90)

`manager_league_total_teamselect.png` is the real MANAGER.EXE screen, banked off this
session's Manchester Utd. career drive under Wine: title -> MANAGER LEAGUE (165,277) ->
TOTAL (445,300), before any name is typed or any kit clicked.

It exists because the NANOESC kit bank was re-baked this session (see
`docs/re/realised_palette_re.md` §5) and this panel is where the original blits those kits
1:1. Diffed against the port's own `seleccion.png`:

| | px |
|---|---|
| raw | 1,024 |
| masking the two arrow buttons at (78,63)-(120,95) and (474,63)-(536,95) | 13 |

and the 13 are one vertical line at x=390, y 73..85 — the original's blinking text caret,
white where the port's field is black. Twenty kits, the whole grid, the panel, the lists and
the four division buttons: 0 px.

`diff_entry_parity.py` already gates this screen against walkthrough frame `008_154345.png`
with the caret cell excluded. This frame is a second, independently driven witness of the
same screen, not a replacement for it.
