# Youth Team — reverse-engineering notes + model

The YOUTH TEAM is reached from the SQUAD MANAGEMENT (PLANTILLA) screen's bottom-right
button, which the squad-screen reverse located at `(0x20b,0x168)..(0x27b,0x181)` loading
`recursos\iconos\plantilla\juveniles.bmp` (see `squad_screen_re.md`). Until this session
that button was a painted dead-end; it now opens an interactive youth screen.

## Faithful surface (strings scanned from MANAGER.EXE)

The original game's youth surface is entirely string-resident; these are verbatim from
`extracted/Premier Manager 98/MANAGER.EXE`:

```
YOUTH TEAM            YOUTH PLAYER         PROMOTE / PROMOTED
YOUTH SCOUT          YOUTH MAN. / YOUTH MANAGER / YOUTH TEAM MANAGER
SCOUT                SCOUTS YOUTH TEAM    YOUTH TEAM SCOUT

You need to hire a scout to search youth players.
The scout is now searching for players
The youth team scout has finished his search.
The youth team scout has finished his search and hasn't found
%s has joined your Youth Team.
Your youth manager has informed you that
%s is ready to be promoted to the first team squad.
The youth player %s has rejected your offer.
```

So the original loop is: hire a **YOUTH SCOUT** → he searches → either "hasn't found" or a
youngster "has joined your Youth Team"; a **YOUTH MANAGER** develops them; when one is
ready the youth manager reports "%s is ready to be promoted to the first team squad"; you
**PROMOTE** him (a very raw prospect could reject the offer).

## THE WHOLE MODEL, PORTED FROM THE BINARY (2026-07-25, session 3)

> **The 2026-07-25 correction above was itself wrong.** `FUN_0058a360` / `FUN_00589e20`
> are NOT the youth generator: they are the SHARED offer-resolution path (competing-bid
> comparator + accept/reject), which carries youth strings only because the youth team is
> one of its pseudo-clubs (`0x26e4`, alongside `0x26de` free agent and `0x26ae`). The real
> youth code was found this session and is listed below. **There is no generator at all.**

### The academy is DATA

`DBDAT/EQUIPOS.PKF` ships **`EQ969956.DBC`** — engine club id **`0x26e4` = 9956**, the
record the extractor remaps to app club **1383, "Young players"**. It holds **51 real
player records**: names, legal names, birth dates, birthplaces, heights, weights,
positions and the full ten-attribute block (`James FRESHER`, `Keith PATTERSON`,
`Michael SHEEHAN`, …). Everything the youth part does is a rule over that table.

(The old note in `tools/re/equipos_parse.py` that `0x26e4` "does not occur in EQUIPOS"
was about the id appearing as a *field* inside an ordinary record. The club file itself
is right there, and `Free players` 9950 / `Stars` 9902 ship the same way.)

### 1. The knock-down — `FUN_005820f0` @0x582434

The DBC player loader writes every attribute **twice**, LIVE `+0x9c..+0xa5` and BASE
`+0xaa..+0xb3` (`training_screen_re.md`). Then:

```
if player.club == 0x26e4:
    d = rand(11) + 0x23                  ; 35..45, ONE roll for the whole record
    for a in all TEN live bytes +0x9c..+0xa5:
        live[a] = live[a] - d if d < live[a] else 0
    ; BASE +0xaa..+0xb3 is NOT touched
```

So a youngster ships as a finished adult and is handed to you 35-45 points below
himself. **His ceiling is his own shipped rating** — the "hidden potential" this port
used to roll was never needed. Ported in `Youth.degrade`, called from
`GameDB._apply_loader_defaults` (the same place the loader's other per-record defaults
already live).

### 2. The scout's filter — `FUN_00575d90` (youth-scout vtable `0x632fc8`, slot 0)

```
match = false
if player.club == 0x26e4:
    if crit+0x10 and base[+0xae] > 0x4f: match = true    ; PO  HANDLING
    elif crit+0x14 and base[+0xb1] > 0x4f: match = true  ; RM  DRIBBLING
    elif crit+0x18 and base[+0xaf] > 0x4f: match = true  ; EN  TACKLING
    elif crit+0x1c and base[+0xb2] > 0x4f: match = true  ; RG  HEADING
    elif crit+0x20 and base[+0xb0] > 0x4f: match = true  ; PA  PASSING
    elif crit+0x24 and base[+0xb3] > 0x4f: match = true  ; TI  SHOOTING
```

A plain **OR** over the six lit LEDs, against **BASE** (his adult rating, not the
knocked-down one), threshold **80 and up**. The attribute map is the one the TRAINING
mode codes independently pin. Ported as `Youth.scout_matches` / `Youth.CAP_ATTR`.

### 3. The search — `FUN_00575e80` (slot 1) and `FUN_0053e860` @0x53e967

```
if scout.weeks == 0:                       ; FUN_00575730 ticks scout+7 down
    clear the found list
    for p in club(0x26e4).players:         ; head club+0x24, next player+0x100
        if predicate(p): append p.id
    if any:
        keep exactly ONE: list = [ list[ rand(count) ] ]
```

**The youth scout finds at most ONE player, uniformly at random among the matches.**
(The senior scout's `(quality+2)*5` shortlist cap is the OTHER resolver, `FUN_00575750`,
and does not apply here.) The duration is set when SEARCH is pressed:

```
0053e967  CALL FUN_0058df90      ; rand(6), arg 6 pushed
0053e977  MOV  DL,[ECX+1]        ; the YOUTH TEAM SCOUT's quality byte q (1..10)
0053e97c  MOV  EDX,0x37
0053e981  INC  ECX               ; q+1
0053e983  SHR  ECX,1             ; (q+1)>>1
0053e985  LEA  ECX,[ECX+ECX*4]   ; *5
0053e988  SUB  EDX,ECX           ; 55 - 5*((q+1)>>1)
0053e98a  ADD  EAX,EDX
0053e98c  MOV  [ESI+7],AL        ; weeks
```

`weeks = rand(6) + 0x37 - 5 * ((q + 1) >> 1)` — **50..55 weeks at half a star, 30..35 at
five**. That is the "once a season, towards the end" cadence the owner reported. The
same commit proves the criteria object: `operator_new(0x28)` with `*obj = 0x632fc8`
(the youth vtable), `+4` club, `+6` quality, `+7` weeks, `+0x10..+0x24` the six flags.

### 4. The growth — `FUN_00582760` case `0x20`

```
gain = (rand(100) > 0x27)                  ; 60%
if gain:
    for a in CORE4 (VE RE AG CA):  live[a] = min(live[a]+gain, base[a])
    if all four live == base:
        mode = 0
        "Your youth manager has informed you that %s is ready to be
         promoted to the first team squad."
; the shared six-attribute block then runs with cap[*] = 0, so PO/EN/PA/RM/RG/TI
; climb the same point a week and stop dead at BASE. condition +1.
```

Ported as `Training.develop_youth_week`, which `Youth.develop_week` now delegates to.
So the climb back is ~1.7 weeks a point and **stops at his shipped rating, exactly**.

### 5. Signing and promotion

Signing is the shared offer path (`FUN_0058a360`), which is why `0x26e4` has its own two
lines there: `%s has joined your Youth Team.` on accept, `The youth player %s has
rejected your offer.` on refusal. The engine re-parents him out of `0x26e4`, so the
scout can never find him twice (`Career._youth_taken`).

### What is left OURS, and named

* **`Youth.SEARCH_SPEEDUP` = 2.** The owner's standing Android call (2026-07-24 owner
  report: *"it's ok to lower the amount of weeks it takes so we have 2 intakes per
  season"*). Set it to 1 for the binary's own cadence. **This is the only youth number
  that is not MANAGER.EXE's.**
* **The refusal odds** in `Career.sign_youth_prospect` (the original's are driven by the
  same DB-backed negotiation as a senior offer, not yet reversed).
* **The wonderkid / real-talent lane** — declared easter eggs, not part of the port.
* **The PLAYERS FOUND panel's filled look** — still un-witnessed (no capture holds it).

### What was DELETED as invented

`INTAKE_CA_LO/HI`, `POTENTIAL_LO/HI/CAP`, `READY_CA` as an academy rule, `_DEV_RATE`,
`GK_CHANCE`, the season-rollover **age-out and free crop** (`YOUTH_INTAKE_LO/HI`), and
`YOUTH_SEARCH_WEEKS`. Nothing in MANAGER.EXE adds to or releases from the youth list at
a rollover — the scout is the only way in and PROMOTE the only way out — and the shipped
pool is 17-19 year-olds who would have aged straight out of the old rule. The
`_make_attrs` / `_gen_name` / `random_pos` helpers survive in `Youth.gd` as the shared
**regen lane** for free agents and the talent easter egg, relabelled as such.

### One place the port deliberately differs from the engine

`Youth.scout_search` hands back a **deep copy** of the pool record, not the record
itself. The engine re-parents its own record out of `0x26e4` because it reloads the
database for every new game; `GameDB` here loads once per app launch and is shared by
every career, so handing out the live dict would leave a signed youngster's `clubId`,
`ready` flag and part-grown attributes stuck on the pool for the next career.
`Career._youth_taken` does the "he is out of the pool" half. Asserted in
`test_youth.gd` ("signing does NOT mutate the shared GameDB pool record").

### Adjacent field found on the way (for the SUSPENSION marker item)

Chasing the youth code turned up the **ban field**, which the open suspension-marker task
needs: `FUN_0057a4c0` (the pre-match "Players banned will not be available for the next
match." gate) reads **`player + 0xb6 + DAT_0066b1dc`** — a per-competition byte array,
indexed by the live competition id — and treats **0 and 6** as "available", anything else
as banned. The injury flag it pairs with is `player + 0x68` (`FUN_0057a490`). Neither the
match-session LINE-UP feeder `FUN_0044d5f0` nor `FUN_004fc321` reads that byte for
display, so the marker (if there is one) is drawn elsewhere. **Still not witnessed** — the
handoff's rule stands: capture a banned player's LINE-UP row in the real game before
drawing anything.

### Verification

`app/tests/test_youth.gd` — **47 assertions, ALL PASS**, one per clause above: the pool
is the shipped 51, the knock-down is one 35..45 roll floored at 0 with BASE intact, the
predicate is an OR at 80 with 79/80 edges checked, the search never returns more than one
and never re-finds a signed player, the duration band per quality byte, the climb stops
at BASE and reports ready exactly once, the ~60% gate, and the Career integration
(sign → grow → promote → save/load). `test_youth_prospects.gd` and `test_youth_screen.gd`
re-pinned to the binary's duration. `test_talents.gd` had a pre-existing flake here (the
free-agent pool could hit `FREE_POOL_CAP` depending on how many contracts expired) and
its fixture is now pinned.

### Staff (EMPLE) hook — SETTLED

The YOUTH TEAM SCOUT gates the search and his **quality byte is the only staff term in
the whole model**: it sets the duration (`5 * ((q+1) >> 1)` weeks off 55). The YOUTH TEAM
MANAGER has **no effect on growth** — `FUN_00582760` case `0x20` has no staff input at
all, which is why `Youth.develop_week`'s `factor` argument is now accepted and ignored.

---

## FRAME-TRUE SCREEN REBUILD (2026-07-16) — supersedes the screen section above

The landscape-list screen described above was OUR layout, not the game's. The original
YOUTH TEAM screen **is witnessed in the walkthrough** — main run frames `087_154632` /
`088_154633` (RATING held) / `089_154635` (RETURN held) and run-3 frames `047_164509`
(active scout search) / `048_164510` (SEARCH held) — and the screen was rebuilt
frame-true against them (the earlier "staff is a separate deferred item" framing had
gone stale once CLUB PERSONNEL shipped; the roster line "no walkthrough frame" for youth
was never true — same lesson as league-tables' `feedback-verify-agent-not-found-claims`).

**Witnessed layout** (both frames): shared live barra; SCOUT panel (portrait, black bar,
purple name bar + gold stars, SEARCH CAPABILITY 2×3 tracks with YES/NO values, six LED
toggles with labels, SEARCH plaque); PLAYERS FOUND panel (white interior, message);
MANAGER panel (portrait, black bar, blue name bar + stars, "N PLAYERS" count, green
YOUTH TEAM band, NAME/SP/ST/AG/QU/AV/ROL/WAGE/YEARS headers, 11 grey rows + folder
icons + scrollbar); PARAMETERS/RATING plaque toggle (+ static red arrow); bottom-right
HANDLING..SHOOTING tile grid; RETURN.

**Build** (`tools/re/build_youth_chrome_from_frames.py` → `app/art/screens/youth/`):
frame 087's body below the barra IS the authentic empty state and is baked verbatim as
`youth_body.png` — only the six YES/NO value cells (re-striped from the tracks' own
clean columns) and the PLAYERS FOUND interior (whited) are lifted out, because live
values replace them. Sprites cut verbatim from the frames: available/lit LEDs, enabled
SEARCH, PARAMETERS-unselected + RATING-selected plaques, star cells, and the three
held-state rings (`search_held` 048 red / `rating_held` 088 white / `return_held` 089
white). Facts decoded pixel-level along the way:

- **Values are INK-CENTRED per cell** (staff-wage doctrine): NO x110..124 / YES
  x107..127 share cx 117 (left col), cx 242 (right col). Face = **proman8 @ native 11**
  (frame 'N' 7×7 = the atlas bitmap exactly).
- **Message layout**: line 1 ink-centred on cx 476, line 2 LEFT-aligned to line 1's ink
  start (087 both lines start x392; 047 both x344 — line 2 alone is NOT centred). Face =
  **proman10 @ native 10** (frame 'e' 6×7 = its atlas; proman8 lowercase does NOT match).
- **Star rows alternate TWO sprites** (cells 1/3/5 = A, 2/4 = B, pitch 11) on both the
  scout and manager bars; a uniform sprite diffs on every even cell.
- **Three LED states**: disabled (087, no scout — baked), available (047, scout hired),
  lit (047 DRIBBLING/PASSING/SHOOTING = the selected capabilities).
- **SEARCH has disabled art** (087 pale lettering, baked) vs enabled (047 yellow).
- Column headers measured off the baked band: NAME x59..99, SP cx187, ST cx211.5,
  AG cx237, QU cx262, AV cx287, ROL cx312, WAGE cx358.5, YEARS cx418.5.
- Header seam pixel (58,522) is the ORIGINAL's own phase variance (in-season 44 vs
  preseason 22 grey); excluded in the gate with that provenance.

**Model wiring**: scout bar = `Staff.YOUTH_TEAM_SCOUT` hire, manager bar =
`Staff.YOUTH_TEAM_MANAGER`; capabilities YES iff a scout is hired (the witnessed pair;
a per-skill gradient is un-witnessed); LED taps toggle the search-skill selection;
SEARCH → `Career.start_youth_search(skills)` → `youth_search` ticks in `advance_week`
and resolves with the MANAGER.EXE strings ("finished his search" / "...hasn't found");
the searching state renders frame 047's message. Duration (`YOUTH_SEARCH_WEEKS` = 2)
and the find-chance (0.25 + 0.11·stars) are OUR reconstruction — the strings-decoded
loop is the game's, the numbers are not RE'd.

---

## PLAYERS FOUND is now a real shortlist (2026-07-25)

Owner report: *"the youth scout is the same [as the senior scout]. The players they find
are supposed to be possible to click on to offer contract. But that youth scout result
only appears once per season towards the end on original (or rather a set of weeks); in
our android game it's ok to lower the amount of weeks it takes so we have 2 intakes per
season."*

He is right that there is an offer step, and MANAGER.EXE proves it: **"The youth player
%s has rejected your offer."** (0x663be8) can only exist because the original ASKS. The
app used to skip straight from "finished his search" to "%s has joined your Youth Team.",
so there was nothing to click and no way to be turned down.

The loop now matches the strings:

1. `Career.start_youth_search(skills)` arms it and clears the last shortlist.
2. `_tick_youth_search` resolves it into **`Career.youth_found`** — `FUN_00575e80`'s
   **exactly one** prospect, or none, with the game's own two messages (both also queued
   as hub alerts). Nobody joins on his own any more.
3. `YouthScreen` draws `youth_found` in the frame-measured `pf_interior`
   `[326, 102, 302, 117]` and a row tap emits `prospect_pressed(pid)`.
4. `Career.sign_youth_prospect(pid, rng)` signs him — *"%s has joined your Youth Team."* —
   or he refuses — *"The youth player %s has rejected your offer."* Either way he leaves
   the shortlist. Refusal odds rise with his ceiling and fall with the YOUTH MANAGER's
   pull (OURS; the original's are database-driven).

**Cadence — superseded by §3 above.** `YOUTH_SEARCH_WEEKS` is gone; the duration is now
`FUN_0053e860`'s own `rand(6) + 0x37 - 5*((q+1)>>1)`, divided by `Youth.SEARCH_SPEEDUP`
(2, the owner's call). A five-star scout therefore reports in 15..18 weeks, which is the
two intakes a season he asked for; a half-star one still takes most of it.

**Still a reconstruction:** the panel's FILLED look. No frame we hold shows it, so the row
grammar (name · age · ability · 1-5 ceiling pips, 16px pitch) is the app's own, kept
plain and inside the measured interior. Render check `app/tests/shot_youth_found.gd`
(also asserts every row hit-tests back to itself); regression `test_youth_prospects.gd`.

---

**Honest gaps (do NOT invent)**: filled roster-row rendering (rows witnessed EMPTY —
values render in the game faces under the baked headers; WAGE/YEARS stay blank, youth
contracts un-modelled); the filled PLAYERS FOUND list; frame 047's "3 PLAYERS" over an
empty visible list (which counter that is is unresolved — live count = youth.size(),
the oracle pins the witnessed text); the bottom-right skill-tile grid's behaviour
(baked static, taps no-op); row-tap PROMOTE is an un-walked interaction (kept, no
visual badge); the shared PMChrome live barra is an approximation of the original
textured header (app-wide, tracked separately).

**Verification**: `tools/re/diff_youth_parity.py` — ALL FIVE shots (`shot_youth_parity.gd`)
diff **0px on the body** vs their binding frames (087/088/089/047/048).
`test_youth_screen.gd` (33 asserts) covers chrome json, state machine, LED geometry,
SEARCH signal gating, and the Career search model; `test_youth.gd` (model) + the full
37-file screen sweep stay green. Live render re-verified via `PM98_YOUTH_SHOT=1`.
