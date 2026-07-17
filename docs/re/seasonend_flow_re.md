# Season-end flow RE — END OF THE SEASON / END OF THE GAME / annual re-mount (2026-07-17)

Closes the un-chased item from `sack_path_re.md` ("which screens
`FUN_004f9800`/`FUN_004f98c0` mount was not chased") and the "screens NOT
witnessed, mechanism unknown" caveat in `promanager_career_screens_re.md`.
Method: Ghidra 12.1.2 headless (`~/ghidra-projects/pm98`, MANAGER.EXE,
readOnly, DecompileAt.java) + vtable/string dumps straight from the PE
(`.wineprefix/drive_c/PM98/MANAGER.EXE`). Every address below was read from
the binary this session; nothing inferred from memory.

## Verdict first

- `FUN_004f9800` mounts **screen 0x3b8 = "END OF THE SEASON"** (the season
  report), once per live manager. **Promanager-only** (`DAT_0066b1e4 == 0` →
  immediate return).
- `FUN_004f98c0` mounts **screen 0x3ba = "END OF THE GAME"** (career
  complete), only when the manager's Promanager level (+0x28) crosses to 12.
  Also Promanager-only (gate inline + the level itself only updates under
  `DAT_0066b1e4 != 0`).
- **Neither is the OFFERS SELECTION family.** The season-end OFFERS re-mount
  is the annual career-setup screen **0x3c1 = OFFERS SELECTION** itself:
  `FUN_004f8a00` re-runs `FUN_004f9520(0x3c1)` at the top of every season
  loop once `DAT_0066b1e4 != 0 && DAT_0066b18c > 0x7cd` (year > 1997).
- **Manager League (b1e4=0) has NO season-end screens at all**: no report, no
  END OF THE GAME, no offers re-mount. Seasons roll straight over. (App
  implication below.)

## Where they sit in the season orchestrator `FUN_004f8a00`

Decompile-verified order (season loop, label 0x4f8af4):

1. First entry: `FUN_004f9520((b1e4!=0)+0x3c0)` — career setup.
   Factory ids: **0x3c0** (ctor `FUN_0055d340`, vtable 0x626330, init
   `FUN_0055d560` = "ENTER YOUR NAME AND SELECT A TEAM", Manager/League
   plaque — the witnessed Manager League seleccion screen) vs **0x3c1**
   (ctor `FUN_00561070`, vtable 0x635f78, init `FUN_00561500` =
   **"OFFERS SELECTION"** 0x65ffbc, "Promanager" plaque, Load Game/Delete/
   RETURN/CONTINUE — the witnessed Promanager screen). Both share run slot
   +0x11c = `FUN_004fa810`.
2. Loop head, every season: `FUN_00586250()`; then if Promanager and year >
   1997 → `FUN_004f9520(0x3c1)` — **OFFERS SELECTION re-mounted each new
   season**.
3. Weeks run (the `FUN_00448b60` week driver chain, see `sack_path_re.md`).
4. When all 14 divisions (`DAT_0066b190[14]`, vtable +0xb8 poll) report the
   season complete:
   `FUN_004f9800()` → `FUN_005865b0()` (un-chased) → `FUN_004f98c0()` →
   `FUN_005c1df0(&DAT_00658a58)` + `FUN_00443180(year)` (un-chased) → back
   to 2 (year rollover → next OFFERS SELECTION).

So the Promanager season-end sequence the player sees is:
**END OF THE SEASON report → (END OF THE GAME if level hits 12) → next
season's OFFERS SELECTION.**

## Screen 0x3b8 — END OF THE SEASON (season report)

Factory case 0x3b8 → ctor `FUN_00535f70` (object 0x1d44 bytes, final vtable
**0x632250**, init +0x118 = `FUN_005360f0`, run +0x11c = `FUN_004fa810`).

`FUN_004f9800` mounts it per manager record (`DAT_0066c178` array, stride
0x9c, count `DAT_0066c17c`), skipping records whose club (+0x24) == 0xffff
(sacked/detached). Per record it calls `FUN_00585ee0(club)` (lazy-allocs a
0x20-byte per-club entry in a global sparse table) and passes
`FUN_005793d0()`'s record into the screen (stored at widget+0x2920; its
+0x10 = club id, +0x4c = start-of-season position, +0x58 = division index,
+0x50 used for division lookup). **Edge case: `DAT_0066c17c == 0` (no
manager records at all) → throws CGFXException 0x4e3e → MAIN MENU** (same
code path as the mid-season all-sacked throw in `sack_path_re.md`).

Init `FUN_005360f0`: title "END OF THE SEASON" (VA 0x65c460), CONTINUE
button id 0x396, help ref `INFOFUT\if5fitem.htm`, body widget 0x2924 bytes
(vtable 0x632370) built by `FUN_005365e0`:

- panel rect (0x69,0x4a)–(0x171,0x173), icon
  `recursos\iconos\noticias\newsextra.bmp`,
- scroll arrows `arrowup/arrowdown[on|off].bmp`, font ProMan8, line height
  0x10 — a scrollable text report (0x800-byte buffer).

### Report text — exact assembly order

Base text `FUN_005367d0` (sprintf/strcat chain, all VAs in .rdata):

1. `"As manager %s%s, you have "` (0x65c63c; forename/surname via
   `FUN_0057cc60`)
2. if objective NOT achieved (`FUN_0057a520()==0`): + `"not "` (0x65c634)
3. + `"achieved the objective you have been signed to "` (0x65c604)
4. + `"(%s).\n\n"` (0x65c5fc; objective name = division vtable +0x7c)
5. started position (+0x4c): 0 → `"You began the season as Champion of %s
   and "` (0x65c570); 1 → `"You began the season as %s runner up and "`
   (0x65c59c); else `"You began the season in the %s position of %s and "`
   (0x65c5c8; ordinal via `FUN_0058de90`)
6. finish (`FUN_0057d1c0`): 0 → `"have finished as the Champion.\n\n"`
   (0x65c508); 1 → `"have finished as runner up.\n\n"` (0x65c52c); else
   `"have finished in the %s position.\n\n"` (0x65c54c)
7. `"The directors are "` + `"pleased"`/`"disappointed"` (by
   `FUN_0057a570()`) + `" with the results.\n"` (0x65c4f4/0x65c4dc/
   0x65c4e4/0x65c4c8)
8. if bonus `FUN_0057f790()` > 0: `"You receive a bonus of %s for last
   year.\n"` (0x65c49c; money formatted by `FUN_0058dbb0`)

Trophy lines `FUN_00536b30` — club id (record+0x10) compared against each
competition object's winner (vtable +0xa8) / runner-up (+0xac), appended in
this exact order, `"\nYou have also won the X.\n"` / `"\nYou finished
runner up in the X.\n"`:

| Global | Competition | won / runner-up VA |
|---|---|---|
| `DAT_0066b1a0` | F.A. Cup | 0x65c90c / 0x65c8e0 |
| `DAT_0066b1a8` | Charity Shield | 0x65c8b8 / 0x65c888 |
| `DAT_0066b1a4` | Coca Cola Cup | 0x65c860 / 0x65c830 |
| `DAT_0066b1b4` | European Cup | 0x65c808 / 0x65c7d8 |
| `DAT_0066b1b0` | Cup Winner's Cup | 0x65c7ac / 0x65c778 |
| `DAT_0066b1ac` | U.E.F.A. Cup | 0x65c750 / 0x65c720 |
| `DAT_0066b1b8` | European Supercup | 0x65c6f4 / 0x65c6c0 |
| `DAT_0066b1bc` | Intercontinental Cup | 0x65c690 / 0x65c658 |

(This doubles as the competition-object global map; divisions live at
`DAT_0066b190[14]`.) `"SEASON %u/%02u"` (0x65c930) sits in the same string
cluster — drawn by the shared header helper `FUN_00536520`, exact placement
un-chased.

## Screen 0x3ba — END OF THE GAME (career complete)

Factory case 0x3ba → ctor `FUN_00534910` (0x1d44 bytes, final vtable
**0x631dd8**, init +0x118 = `FUN_00534a90`, run +0x11c = `FUN_004fa810`).

Init: title "END OF THE GAME" (0x65c340), CONTINUE id 0x396, body widget
0x2948 bytes (vtable 0x631ef8) built by `FUN_00535040`: icon
`RECURSOS\PREMIER\ICONOS\FinObjetivo\goal_game.bmp`, text `"Congratulations,
you have proved yourself to be an excellent manager."` (0x65c368, ProMan10,
panel rect (0x69,0x4a)–(0x171,0x173)), then `FUN_00535180` computes 9
career counters (+0x2924..+0x2944): scans the manager's season-history
records (`FUN_0058b5f0` count / `FUN_0058b600(i,buf)` fetch) counting
records where each of 9 achievement byte-fields > 1. Field→competition
mapping and on-screen rendering un-chased (needs the record builder
`FUN_0058b950`).

### Mount trigger — the Promanager level ladder

`FUN_004f98c0` per manager record: old = rec+0x28; `FUN_0058b490(rec)`;
mount 0x3ba iff Promanager && old < 0xc && new ≥ 0xc — i.e. **the season
the level reaches 12**.

`FUN_0058b490(rec)` (skips club==0xffff): appends a 0x94-byte
season-history record (`FUN_0058b950`) to the rec+0x94 array (count
+0x98), then — Promanager only — updates the level via
`FUN_0058b2e0(rec, old_level, achieved, start_pos, finish_pos, division)`
where achieved = 0 if detached else `FUN_0057a520()`, start = rec+0x4c,
finish = `FUN_0057d1c0(rec+0x58)`, division = rec+0x58.

`FUN_0058b2e0` — exact rule (level mutates only while < 12):

- **Demotion:** objective NOT achieved && finish ≥ start+4 (dropped ≥4
  places) && level > 0 → level −1.
- **Level 11 → 12 (endgame):** objective achieved && level == 11:
  - career grand slam (`FUN_0058b360`: across ALL season-history records,
    each of SEVEN achievement fields — the 9 above minus two, mapping
    un-chased — seen > 1 at least once) → level := 12;
  - else if finish ≤ start−4 (improved ≥4 places) → level +1 (= 12).
- **Champion promotion:** if level still unchanged && finish == 0
  (champion): promote (+1) iff division ≤ 12 − level (`FUN_0058b5d0` =
  `12 − level`, clamped ≥ 0; division index into `DAT_0066b190`, 0 =
  top flight). So low levels promote by winning anything; level 11 needs
  a division-≤1 title.

## App implications (RE lane only — no app code changed here)

- The app's `_show_end_of_season()` browse list is a substitute for screen
  0x3b8 — but 0x3b8 is **Promanager-only**. A faithful **Manager League**
  career must show NO end-of-season report screen (and no offers re-mount);
  the season chain (charter #4 family) rolls straight into the next season.
- A future Promanager mode now has the full season-end spec: report screen
  (exact text assembly above, witnessable via wine for pixels), END OF THE
  GAME trigger (level ladder), and OFFERS SELECTION re-mount each season.
- The all-managers-gone season-end path throws 0x4e3e → MAIN MENU, matching
  the mid-season sack surface in `sack_path_re.md`.

## Un-chased (do NOT guess)

- `FUN_005865b0` (between the two mounts), `FUN_005c1df0(&DAT_00658a58)`,
  `FUN_00443180(year)` — season-rollover helpers.
- History-record field → competition mapping (`FUN_0058b950`), and which 2
  of the 9 fields the grand-slam check skips.
- `"SEASON %u/%02u"` header placement; pixel layout of both screens (wine
  witness would pin them — needs a full simulated Promanager season).
- The `·Players aged` / `·%s level` / `·Manager League` / `·Promanager
  League` string cluster at 0x65c3e4–0x65c424 sits between the two screens'
  strings but was NOT referenced by any function chased here — owner
  unknown.
