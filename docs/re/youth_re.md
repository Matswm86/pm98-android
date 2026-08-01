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
values render in the game faces under the baked headers; ROL borrows the CAMROL fine-
position icon, the original's own compact ROL grammar 100%-pixel-witnessed on the
OFFERS list; WAGE/YEARS stay blank, youth contracts un-modelled — except the declared
OURS "PROMOTE" cue below); the filled PLAYERS FOUND list; frame 047's "3 PLAYERS" over
an empty visible list (which counter that is is unresolved — live count = youth.size(),
the oracle pins the witnessed text); the bottom-right skill-tile grid's behaviour
(baked static, taps no-op); row-tap PROMOTE is an un-walked interaction — since
2026-07-27 a READY row carries the word "PROMOTE" (the EXE's own string) in the
screen's YES-red across the empty WAGE/YEARS band, a **declared OURS cue** (B4) that
the B9 capture can replace with the original's own; the shared PMChrome live barra is
an approximation of the original textured header (app-wide, tracked separately).

---

## THE LOOP (Session D, 2026-07-27) — B1-B10

The model above was byte-exact but the LOOP around it lost state and armed dead
searches. Fixed, test-pinned in `app/tests/test_youth_loop.gd` (+ the extended
`test_youth_screen.gd`), all five witnesses re-run 0 px:

* **B1** — the six LED capability flags persist on `Career.youth_caps` (the original
  holds them in the criteria object, +0x10..+0x24 — §3). The screen emits
  `caps_changed` on every toggle; Main saves. They survive leaving the screen and
  save/load.
* **B2** — a ZERO-LED search is refused: the predicate (§2) is an OR over the lit
  flags, so an empty search could never match — arming it was a guaranteed dead
  15-28 weeks, THE "recruitment doesn't work" experience. The screen raises the EXE's
  own refusal alert ("You have to select some options to make the search.", 0x65d3c0
  — witnessed on the senior SCOUT screen; the youth-side gate itself is un-witnessed,
  declared), and `Career.start_youth_search` guards headless callers.
* **B3** — the youth manager's "ready to be promoted" report rides `pending_alerts`
  (the hub "PREMIER MANAGER 98" box), like the scout's completion lines already did.
* **B4** — READY/PROMOTE affordance: the declared OURS "PROMOTE" cue (see honest
  gaps above).
* **B5** — the ROL column draws the CAMROL fine-position icon (`posFine`), not the
  broad `pos` word.
* **B6** — the academy is de-polluted: the declared cap counts POOL-scouted members
  only (`Career._scouted_youth_count`), the pool exclude list carries pool ids only,
  and a talent entering through the academy side-door now ships `attrs_base` at his
  ceiling (`Talent._base_at_ceiling` — BASE CA == potential) so the byte-exact growth
  (§4) can actually reach it. The side-doors themselves (wonderkid, scheduled
  talents) are owner-approved easter eggs and stay.
* **B7** — `Youth.SQUAD_CAP = 12` is DECLARED OURS: MANAGER.EXE carries no
  youth-capacity string; the only join gate in the engine is the shared offer path's
  refusal (un-RE'd).
* **B8** — the two youth `randomize()` sites now draw from `Career.career_rng()`,
  ONE stream whose state persists across save/load (`career_rng_state`, stored as a
  string — 64-bit state does not survive a JSON double). First S3 step — and S3
  COMPLETED 2026-07-27: every remaining Career.gd site + Main's five career paths
  migrated, `career_rng_state` re-pins a live stream, `test_career_seed.gd` proves
  two same-seed careers identical (docs/REMAINING.md §3c).
* **B9** — OPEN: one wine capture run closes the three visual gaps at once (filled
  PLAYERS FOUND, filled roster row, DRIBBLING/HEADING training chips). Needs a
  driven career with a completed youth search (30-55 weeks at the binary's own
  cadence) — the autodriver (`tools/re/wine/autodrive.py` + `plans/season.json`)
  drove two full seasons for the euro probe, so the machinery exists.
* **B10** — the stale `Staff.gd` blurbs corrected: the YOUTH TEAM SCOUT's quality
  byte sets the search duration (§3 — his only engine effect, and it is real); the
  YOUTH TEAM MANAGER's pull only affects signing refusal odds (OURS §5); growth has
  no staff term (§4).

**Verification**: `tools/re/diff_youth_parity.py` — ALL FIVE shots (`shot_youth_parity.gd`)
diff **0px on the body** vs their binding frames (087/088/089/047/048).
`test_youth_screen.gd` (33 asserts) covers chrome json, state machine, LED geometry,
SEARCH signal gating, and the Career search model; `test_youth.gd` (model) + the full
37-file screen sweep stay green. Live render re-verified via `PM98_YOUTH_SHOT=1`.

---

## THE CONTROL SURFACE (Session E, 2026-08-01) — C1-C7

Everything above models what happens to a youngster **once he is developing**. It never
asked what starts him developing, and the answer is that nothing in the port did — which
is exactly the owner report that opened this session ("the youth team still doesn't work,
it's not exact like the original; youth training, offering of contract and promotion of a
youth player must work like the original"). Four separate binary facts were missing.

### C1. `FUN_00578b80` is the whole per-role capability table

`FUN_0057cd70(role)` fetches a staff record and `FUN_00578b80` switches on its role index
(`staff[0]`), reading the quality byte (`staff[1]`) through a five-band ladder
(`<3 / 3-4 / 5-6 / 7-8 / 9-10`). Ported verbatim as `Staff._CAPACITY_BANDS`:

| case | role | bands |
|---|---|---|
| 0-5 + default | the six TRAINERS | 1, 2, 3, 4, 5 |
| 6 | PHYSIOTHERAPIST | 1, 2, 3, 4, 5 |
| 7 | PSYCHOLOGIST | 2, 6, 10, 14, 18 |
| 8, 9, 0xb | ASSISTANT / SCOUT / **YOUTH TEAM SCOUT** | `0xffff` (uncapped) |
| 10 | **YOUTH TEAM MANAGER** | 1, 2, 2, 3, 4 |
| 0xc | GROUNDSMAN | 70, 90, 100, 115, `0xffff` |

The case order **is** `Staff.ROLE_KEYS`' order, which is the CLUB PERSONNEL screen's order
— an independent check that the port's role list was already right.

Two consequences the port had wrong:

* **The YOUTH TEAM screen's "N PLAYERS" is the youth manager's TRAINING CAPACITY, not the
  academy's size.** The app printed `youth.size()`. Both witnesses print **3** over an
  **empty** roster: walkthrough frame 047 (G. Keeping, 3.5 stars, q=7) and a live capture
  of a driven Man Utd career 2026-08-01 (B. Beckett, 4.0 stars, q=8) — the two halves of
  case 10's `7-8 -> 3` band. The old note "which counter that is is unresolved" is closed.
* `Training.skill_tp` was `floor(stars)`. That agrees with the table on whole stars (the
  witnessed 4+2=6 cannot tell them apart) but is **one short on every half star**: a
  3.5-star coach is q=7, which the ladder puts in the 4 band. Now `Staff.capacity_of`.

### C2. A youngster only develops while he is IN TRAINING (`+0xa9 == 0x20`)

The 0x20 growth branch is reached through the training-mode byte, and the **only** writer
of that byte is the TRAINING button on a youth player's own card:

```
00527820  MOV  EAX,[ECX+0x434]        ; the selected player
00527826  PUSH 0x1
00527828  MOV  BYTE PTR [EAX+0xa9],0x20
0052782f  CALL FUN_005bd200
```

`FUN_0057cd50` counts the club's youth carrying that byte (walking `club+0x3c`, next at
`player+0x100`, testing `+0xa9 == 0x20`), and `FUN_005274d0` greys TRAINING when
`FUN_0057cd30() <= FUN_0057cd50()` — capacity reached.

**So an unassigned youngster does not grow one point, ever, and with no YOUTH TEAM MANAGER
hired the capacity is 0 and nobody can be assigned at all.** The port grew every youth in
the list unconditionally, which is why the academy felt like it "worked" and yet nothing
about it matched the original. Ported as `Training.YOUTH_MODE` / the `in_training` flag,
`Training.youth_in_training_count`, `Staff.youth_training_capacity` and
`Career.set_youth_training`.

### C3. PROMOTE reads the attributes, not a flag

`FUN_005274d0` @0x5275ba greys PROMOTE unless all four CORE4 live bytes (`+0x9c..+0x9f`)
equal their BASE twins (`+0xaa..+0xad`) — the same equality the growth branch tests before
it reports him ready. `Training.youth_fully_grown` is now the gate, and
`Career.promotable_youth` uses it, so a youngster who arrives already at his ceiling is
promotable without waiting for a growth tick to set a flag.

### C4. The YOUTH PLAYER card — `FUN_005274d0`

A YOUTH TEAM roster row opens the FICHA card through `FUN_0053ec40` where a senior squad
row opens `FUN_00526a60`. Same chrome, different buttons. The rects are the source's own
`FUN_00436fb0(w,h)` / `FUN_00436fb0(x,y)` pairs, card-local, + the card origin (76,58) —
the identical transform that reproduces the senior row exactly (RENEW's local (85,325) is
the witnessed native (161,383,104,25)):

| button | size | card-local pos | native | widget id |
|---|---|---|---|---|
| TRAINING | 84x25 | (52,329) | (128,387,84,25) | 0xda |
| SACK | 84x25 | (143,329) | (219,387,84,25) | 0x67 |
| PROMOTE | 114x25 | (234,329) | (310,387,114,25) | 0xdc |
| CANCEL | 106x25 | (370,329) | (446,387,106,25) | 0x386 |

**WITNESS `screenshots/refrun-manutd-1997-98/novel/p0771_UNKNOWN.png`** — the reference
run's own youth player Darren SPINDLE, 20 October 1998. All four rects land pixel-exact:
every crop is one clean plate, one dominant ink, no bleed. Inks: TRAINING **(0,255,0)**
green, SACK **(166,202,240)** light blue, CANCEL **(255,0,0)** red — and CANCEL's red is
the `FUN_00437020(0xff,0,0)` the decompile names for it. PROMOTE is **disabled** in that
frame, exactly as C3 predicts for a youngster still short of BASE, rendered as a grey
plate with its label in a two-colour `(x+y)`-parity dither of (255,223,85)/(255,255,170) —
the washed form of its own `FUN_00437020(0xff,0xdf,0)` gold.

Cut 1:1 by `tools/re/build_youth_card_buttons_from_frames.py`. The two states no frame
holds — enabled PROMOTE and disabled TRAINING — are **declared reconstructions** built
from the witnessed plate grammar plus the witnessed glyph masks; the engine's greying is a
palette remap, not RGB arithmetic (0->128 but 80->160 and 128->192 is not one curve), so
it cannot be derived. A live capture of either replaces them.

### C5. Youth players DO have contracts

The same frame kills the port's "youth contracts are un-modelled" note: SPINDLE's card
carries **CLUB FEE £75,000 / YEARLY WAGE £15,000 / YEARS 4 / LEFT 4**. The YOUTH TEAM
roster's WAGE and YEARS columns are no longer blank, and the invented in-row "PROMOTE" cue
(B4) is **gone** — promotion lives on the card, where the source puts it. His stat block
(SPEED 19 / STAMINA 19 / AGGRESSION 17 / QUALITY 19 / FITNESS 93 / MORAL 99, RATING 44)
also re-confirms both the knock-down (§1) and the RATING formula: (19+19+17+19+93+99)/6.

### C6. PLAYERS FOUND, filled — and the prospect's offer card

**WITNESS `screenshots/refrun-manutd-1997-98/novel/p0759_UNKNOWN.png`**, 14 October 1998.
Two gaps close at once:

* The filled panel is a **list with a header strip**, not the message box the empty state
  shows. Columns, measured off the header glyph runs:
  `PLAYER` (black, ink from x357) · `AV` (132,26,26) cx471 · `ROL` (black) cx496 ·
  `WAGE` (100,0,0) cx542 · `AGE` (30,52,98) cx591; glyph rows y105..115 on the panel grey
  (160,160,164), first row under a black rule at y121. This supersedes the app's invented
  "name / age / ability / star pips" grammar, which had neither the right columns nor the
  right order. The frame is partly covered by the card it raised, so the row FILL colours
  stay the app's own — still declared, still B9's to settle.
* Tapping a found prospect raises the **contract-offer card** (`FUN_0053eaa0` ->
  `FUN_00527000`), the same family as the senior scout's row tap: CLUB OFFER £0 / CLUB FEE
  £75,000 / YEARLY WAGE £5,000 with steppers / YEARS 4 / the four clauses / CANCEL /
  OFFER. SPINDLE signs at £15,000 (C5), so the wage is negotiated up from the £5,000 the
  form opens at. The app used to sign silently on a row tap with a toast.

  **Ported 2026-08-01.** `Main._show_youth_offer_card` raises `MakeOfferScreen` in its new
  `no_club` mode — CLUB OFFER pinned to £0 with inert ◄►, because there is nobody to bid
  to — seeded CLUB FEE £75,000 / YEARLY WAGE £5,000 / YEARS 4.
  `Career.offer_youth_contract` resolves it: the refusal roll is the old
  potential-vs-pull one with the wage buying down three quarters of it (meeting his demand
  leaves only the residual, so a full offer can still be refused), and the negotiated terms
  are stamped on him, which is what finally fills the roster's WAGE / YEARS columns.
  `sign_youth_prospect` remains as the same call at the card's opening terms for the
  automated paths. `test_youth_offer_route` drives the real Main UI: row tap -> card
  mounts, on the witnessed terms, nobody signed behind it; the CLUB OFFER ◄► are dead and
  the WAGE ◄► are not; OFFER lands the terms; CANCEL signs nobody. His £75,000 CLUB FEE is
  a display constant — a single witness, and whether the engine varies it is un-RE'd.

### C7. PROMOTE / SACK semantics

* **PROMOTE** `FUN_00588180`: unlink from the youth list (`FUN_00588120`, `club+0x3c`,
  count `+0x40`), then `FUN_00588d10` — assign the first free squad number, **seeded by
  demarcación**: `pos == 0 (GK) ? 1 : pos == 3 (FW) ? 9 : 2`, scanning upward over a
  256-slot used-map of the club's `+0xf8` bytes — and clear the training mode. Board:
  `+0x2c += 5`, `+0x30 += 5`, `+0x34 += 1`, each clamped 0..1000.
* **SACK** `FUN_00588e20`: the shared release path. For a youth (`sVar5 == 0x26e4`) it
  does **not** merely re-parent him — it calls
  `FUN_00576cd0(0x26e4, 0xc, (b9c+b9d+b9e+b9f)>>2, name, age+1)`, **birthing a replacement
  into the pool** at the released man's own CORE4 average, one year older. That rebirth is
  why the shipped 51 never run dry over a long career. Board: `+0x2c += 5`, `+0x30 -= 5`,
  `+0x34 -= 1`.

The three board stats are `team+0x2c` DIRECTORS CONFIDENCE / `+0x30` SUPPORTERS CONFIDENCE
/ `+0x34` MANAGER RATING (`directiva_screen_re.md`), 0..1000, displayed /100. They are now
stored on `Career` and moved by these deltas. **The DIRECTIVA screen still renders its own
documented proxy** — rewiring it to the stored values is tracked separately so this change
cannot move that screen's 0px parity shot.

### C8. The PARAMETERS/RATING arrow MOVES

`FUN_0053e760` invalidates `(0x1db,0x10a)-(0x1e4,0x11b)` = (475,266)-(484,283) and sets
`DAT_00658a40 = 1`; `FUN_0053e7e0` invalidates `(0x1db,0x122)-(0x1e4,0x133)` =
(475,290)-(484,307) and sets it to 0. Each handler repaints its own slot, which only makes
sense if the arrow moves between them. Confirmed live on the driven career: with
PARAMETERS selected the dark-red ink sits at x476..483 y266..281, and one tap on RATING
moves it to y290..305 — the two rects the binary names, nothing else in the column
changing. It had been baked into `youth_body.png` at the PARAMETERS slot and never moved.
Un-baked and cut by `tools/re/build_youth_arrow_from_frames.py`, whose two witnesses now
live in `screenshots/wine-captures-2026-08-01-youth-arrow/` so it stays re-runnable.

**It is NOT the plaque mode.** The first port of this drove the arrow off `_mode` and the
parity shots caught it: frame **047 carries the RATING plaque pair** — 0px against the
live RATING witness y18 over *both* plaque rects (491,264,134,21) and (491,288,134,21) —
**while its arrow sits at the PARAMETERS slot**. 087/088/089/047/048 and y17 all show the
arrow at y266..282; only y18 has it at y290..306. So the plaques and the arrow are two
separate axes, and the arrow has its own hit rects: exactly the two rects the handlers
invalidate. What the arrow additionally selects is **un-RE'd** — the port defaults it to
PARAMETERS, which is what every witnessed frame but y18 shows, and flips it on a tap in
its own column. Flagged as hypothesis, not proof.

**TWO sprites, not one moved.** 11 of the arrow's 81 ink px change colour between the
slots: it is dithered against the panel and the two slots sit on different background
bands. Stamping the PARAMETERS cut at the RATING slot is 11px wrong, so the tool cuts
`arrow.png` and `arrow_rating.png` per slot, each exact. The cut takes ink as the
pixel-difference of the two witnesses, not a hand-listed colour set — the first pass
listed two colours and silently dropped 22 of the 81 px.

A third witness says the same thing from another screen. The B9 drive's probe frames
(`f0006`..`f0132`) landed on **LINE-UP**, which carries the same PARAMETERS/RATING plaque
pair: RATING is lit *and* the panel below it is showing the RATING view (TEAM RATING 80 +
Pallister's skill bars) — and the arrow still sits at the PARAMETERS slot. So the arrow is
not the active-view indicator on that screen either, and the widget is shared, not
youth-local. It is also not simply "points at the inactive one": 087 has PARAMETERS active
with the arrow on PARAMETERS.

All five YOUTH parity shots are back to **0px body** with the arrow live.

### Verification

`test_youth.gd`, `test_youth_loop.gd` (+ the new C1/C2/C3 blocks, 30 assertions),
`test_youth_screen.gd`, `test_youth_prospects.gd`, `test_staff.gd`, `test_training.gd`,
`test_career.gd`, `test_career_seed.gd`, `test_talents.gd` all pass. The new blocks pin:
the full case-10 ladder q=1..10, the physio witness, the uncapped roles; that an untrained
youngster does not move a point over 120 weeks while a trained one reaches BASE; that
promotion clears the mode byte and frees the slot; the GK/FW/other number seeds; and both
board-delta signs plus their save/load round-trip.

**Still open**: the un-occluded filled PLAYERS FOUND and a filled roster row (B9), and the
enabled-PROMOTE / disabled-TRAINING plates.

**B9's drive did not fail on the sim — it failed on navigation.** It ran 207 steps deep
(15 probes, into January 1998) and stopped on an unknown screen, but every probe frame it
banked is the **LINE-UP** screen, not YOUTH: the plan's probe path opens with a hub click
at (234,390) that does not reach SQUAD MANAGEMENT, and the follow-up (579,372) — which IS
the YOUTH TEAM plaque *on SQUAD MANAGEMENT*, witnessed at y16 — lands on LINE-UP's TRAINING
instead. Fix the hub coordinate first, live against the window; re-running the plan as it
stands will burn another 200 steps for seven more LINE-UP frames. The wine career itself
has no save (`drive_c/PM98/ACTLIGA` is empty), so a re-run restarts from a new career.
