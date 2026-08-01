# B9 — the TOTAL-level career path, walked live (2026-08-01, s82)

Twelve frames off the real MANAGER.EXE under wine, one per step, banked here rather than in
a session scratchpad (a reboot deletes those — the s80 lesson).

What they settle: **B9's drive never failed on a coordinate.** The hub's PLAYERS icon at
(234,390) is correct; at **TRAINER** level it answers with a modal (frame 01) because the
whole TRANSFER MARKET quarter is automatic there. Frame 02 is the same hub at **TOTAL**
level with those six icons drawn in colour instead of grey.

| # | frame | shows |
|---|---|---|
| 01 | `01_trainer_players_refused.png` | TRAINER: "This option is automatic in Trainer level." |
| 02 | `02_total_hub_icons_live.png` | TOTAL: the six TRANSFER MARKET / FINANCES icons live |
| 03 | `03_total_squad_management.png` | hub (234,390) → SQUAD MANAGEMENT |
| 04 | `04_total_youth_team_empty.png` | (579,372) → YOUTH TEAM, no scout hired |
| 05 | `05_club_personnel.png` | hub (102,441) → CLUB PERSONNEL |
| 06 | `06_sign_dialog_trainers.png` | SIGN (426,425) → the staff dialog, TRAINERS arm |
| 07 | `07_youth_scouts_available.png` | YOUTH SCOUT (493,293) → the list |
| 08 | `08_youth_scout_hired_stump.png` | top-row SIGN (131,308) → C. Stump 4.5★ £32,000 hired |
| 09 | `09_youth_managers_available.png` | YOUTH MAN. (493,263) → the list (P. Klachinsky 5★) |
| 10 | `10_six_leds_armed.png` | the six LED cards at (36\|161, 176\|194\|212) → all six YES |
| 11 | `11_scout_now_searching.png` | SEARCH (278,203) → "The scout is now searching…" |
| 12 | `12_drive_probe_banks_youth.png` | `autodrive.py run` probe #1 banking YOUTH TEAM, week 3 |

Reproduce: `PM98_LEVEL=total tools/re/wine/nav_career.sh`, then the step list in
`tools/re/wine/plans/season_youth_b9.json`'s `note`.
