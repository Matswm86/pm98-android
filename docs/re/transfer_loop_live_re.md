# The transfer loop, TRAINING focus and SCOUT regions — LIVE witnesses (2026-07-24)

Everything below was read off the **real `MANAGER.EXE`** driven under wine this session
(`tools/re/wine/{boot,click,snap}.sh` on `DISPLAY=:2`), plus the message strings lifted
verbatim out of the binary. Captures:
`screenshots/wine-captures-2026-07-24-transfer-training-scout/`.

Career used: MWM / **Bolton W**, Premier League, TOTAL control, 1997-98.

---

## 1. A bid is answered on the VERY NEXT CONTINUE

| capture | state |
|---|---|
| `tr0` | TRANSFER MARKET list (week 1, Sat 9 Aug 1997) |
| `tr1` | Barlow (Rochdale, CLUB FEE £15,000) — the PLAYER INFORMATION card with the OFFER panel |
| `tr2` | OFFER pressed → back to the browse, **no message box** (matches `make_offer_re.md` 119) |
| `c5`  | after ONE hub CONTINUE (the week-1 match + its full-time board): the hub raises **"You have signed Barlow of Rochdale."** |

So the reply latency is **one CONTINUE**, not one league week and certainly not two
matches. The app resolved `pending_bids` only inside `advance_week`, so a bid placed
during the PRESEASON (whose CONTINUEs play friendlies / the Charity Shield) sat
unanswered until league round 1. `Career.play_friendly` and
`Career.play_charity_shield_match` now call `_resolve_pending_bids` too.

### The exact message strings (MANAGER.EXE, file offsets)

| offset | string |
|---|---|
| `0x261a9c` | `You have signed %s %s%s.` — renders **"You have signed Barlow of Rochdale."** |
| `0x2619e0` | `You have signed %s, %s%s.\nSince you have not payed any transition for his card...` (the Bosman variant) |
| `0x261ba0` | `%s%s has rejected your offer for %s.` — **club** has rejected your offer for **player** |
| `0x261c18` | `%s, player %s%s,\nhas rejected your offer.` (the PLAYER refusing terms) |
| `0x261b18` | `%s%s has rejected your loan request for %s.` |
| `0x26197c` | `%s has been signed by %s%s.` (a sale of ours completing) |
| `0x25a398` | `The Directors will only let you make %u offer%s\nto sign a player per week.` |

The app said *"X have rejected…"* / *"You have signed X."*; both now match the binary.

---

## 2. CURRENT OFFERS lists YOUR OUTGOING BIDS

`co0` (immediately after the Barlow bid) shows one band:

```
NAME  Barlow            EN 99 SP 54 ST 39 AG 51 QU 52 FI 70 MO 93 AV 59  ROLE  DEF
CLUB  Rochdale   CLUB OFFER £15,000   YEARLY WAGE £5,000   YEARS 1   CLAUSES —
```

`Rochdale` is the club we bid **to**. In `co1`, taken after transfer-listing our own
John Sheridan, **Sheridan does not appear** — the screen is not about your listed
players at all.

The app fed this screen `Career.transfer_listed` + incoming `sale_offers`, i.e. the
model was inverted. `Main._show_current_offers_screen` now feeds `Career.pending_bids`.
Incoming bids on your listed players are answered on the **TEAM OFFER card**, which pops
during CONTINUE processing (`team_offer_re.md`, run-3 frames 085→086) — that card and
its REFUSE→ACCEPT toggle were verified working by synthetic tap this session.

A band tap on CURRENT OFFERS was **not** exercised in the original; the app leaves it
inert rather than inventing an interaction.

---

## 3. LINE-UP: signings land in RESERVES, and only RESERVES scrolls

- `lu0` — after signing Barlow the LINE-UP shows XI (11) + SUBSTITUTES (5) + RESERVES.
- `lu1` — six presses of the reserves down-arrow: **the XI and SUBSTITUTES rows never
  move**, only the reserve list rolls, and Barlow (N. 7) appears at its foot.

The app scrolled the whole flat list, which pushed the XI off the top.
`LineupScreen._layout` now scrolls only the RESERVES tail (the fixed head is XI +
SUBSTITUTES band + bench + RESERVES band; 4 reserve rows fit, exactly as the original).

### SUBSTITUTES ↔ RESERVES swap (the deferred swap dispatch, now witnessed)

- `lu2` — **Fairclough** (SUBSTITUTES row 1) tapped: his row goes black (selected).
- `lu3` — **Barlow** (RESERVES) tapped: Barlow is now SUBSTITUTES row 1 and Fairclough
  sits at Barlow's old reserve row. A straight **positional exchange**.

The app only moved the selection when neither man was in the XI. `Tactics.subs_order`
now stores the non-XI order (SUBSTITUTES = its first `BENCH_SLOTS`, RESERVES = the rest
— the same partition the original's squad object keeps at `team+0x1930`/`0x1934`), and
`LineupScreen._swap_bench` exchanges the two rows.

---

## 4. SQUAD MANAGEMENT does not compress rows

`sq0` (and walkthrough frame `077_154612`) show FIXED per-section slot bands of 16px
rows, each with its OWN scrollbar; a section with fewer players leaves its slots blank.
Row-band tops scanned down x=20 of frame 077:

| section | slots | row tops | label band |
|---|---|---|---|
| KEEPERS | 3 | 92 / 108 / 124 | (baked into the column-header row) |
| DEFENDERS | 6 | 156 … 236 | 140 |
| MIDFIELDERS | 6 | 268 … 348 | 252 |
| FORWARDS | 5 | 380 … 444 | 364 |

Scroll-arrow glyphs (yellow) sit at x496..503; the button cells start at x492 with the
pairs at y 92/122, 156/234, 268/346, 380/442.

The app squeezed row pitch to `clampi(avail / n_rows, 11, 16)` to fit a deep squad on
one panel, which clipped the glyphs — that is the reported VALUE/WAGE truncation.
`SquadScreen` now draws 16px rows in the fixed slots and its arrows scroll each section.

---

## 5. SCOUT: E.U. / NON E.U. / PLAYERS WITHOUT TEAM unlock by scout rating

Four careers, one scout each, same screen:

| scout | stars | E.U. PLAYERS | NON E.U. PLAYERS | PLAYERS WITHOUT TEAM |
|---|---|---|---|---|
| K. Burrowes (2026-07-18 witness, `61_scout_with_scout.png`) | ★★★ | washed | washed | washed |
| W. Crane (`sc35`) | ★★★½ | **enabled** | washed | washed |
| M. Kelso (`sc0`) | ★★★★ | **enabled** | **enabled** | washed |
| J. Loxley (`sc50`) | ★★★★★ | **enabled** | **enabled** | **enabled** |

One unlock per half-star from 3.5 → `REGION_STARS = {eu: 3.5, non_eu: 4.0, no_team: 4.5}`.
4.5 itself was not sampled (no 4.5 scout appeared in any pool) but is bracketed: off at
4.0, on at 5.0.

LED cells measured off `sc50`: faces at y 171 / 198 / 225, cells at **(284,167) /
(284,194) / (284,221)**, same 22x13 as the four division boxes at y140.

These three boxes are how the original scouts **abroad** — the screen has no
foreign-league checkbox. `E.U.` / `NON E.U.` are nationality filters over the whole
player database (the shipped DB carries 384 non-English clubs); `PLAYERS WITHOUT TEAM`
is the free-agent pool.

### Search validation (MANAGER.EXE `0x557a40`, disassembled)

```
if (any of POSITION/AGE/ROLE/QUALITY/PRICE checked)      ; checkbox flag = bit 4
   and (any of the 4 division boxes  OR  +0x4c5c
        OR E.U.(+0x60d4) OR NON E.U.(+0x64ec) OR WITHOUT TEAM(+0x6904))
       -> run the search (0x558310)
else -> "You have to select some options to make the search."   ; 0x65d3c0
```

The seven region checkboxes are one 0x418-stride array. The app required only a
left-column criterion; it now requires both, matching the binary (and the 2026-07-18
frames 64/66, where a Premier-only tap was refused).

**One un-decoded piece, flagged:** the game's own per-country E.U. flag was not located
in `MANAGER.EXE` (the player `kind` byte is NATIONAL/NON-NATIONAL relative to his CLUB's
country, not an E.U. flag — Norwegians at Norwegian clubs read NATIONAL). `Career
.EU_NATIONS` therefore uses the E.U.-15 membership of the game's own 1997-98 season,
spelled in PM98's own country names. Everything else about these checkboxes is witnessed.

---

## 6. TRAINING is a focus/capacity mechanic driven by the hired coaches

| capture | state |
|---|---|
| `tn0` | NO trainers: whole screen washed, **TOTAL TRAINABLE PLAYERS 0**, TOTAL 0, AUTO inert |
| `st3`/`st5` | hire HANDLING **F. Bush ★★★★ £30,000** and SHOOTING **G. Slattery ★★½ £6,000** |
| `tn1` | CURRENT TRAINING STAFF band now names them with a **TP** column reading **4** and **2**; **TOTAL TRAINABLE PLAYERS = 6**; AUTO lit |
| `tn2` | **AUTO**: HA tags on all 3 keepers, SH tags on 2 forwards, grid **TOTAL 5** |
| `tn3` | a grid tap opens the AVER. panel with per-row check boxes (GENERAL, FITNESS, HANDLING, PASSING, DRIBBLING, HEADING, TACKLING, SHOOTING) |
| `tn4` | ticking HANDLING for Sellars: box turns gold, his row gains an **HA** tag, TOTAL 5 → **6** |
| `tn5` | a 5th HANDLING pick (Thompson) with the coach at TP 4 is refused **SILENTLY** |
| `tn6` | ticking GENERAL with the total already at 6/6 raises **"You can´t train any more players."** |

Derived rules, all from the above:

- **TP = floor(stars)** (4.0 → 4, 2.5 → 2).
- **TOTAL TRAINABLE PLAYERS = Σ TP** over the six hired skill coaches (4 + 2 = 6).
- **Per-skill cap = that coach's TP** → silent refusal past it.
- **Global cap = TOTAL TRAINABLE PLAYERS** → the alert above.
- AUTO fills each coach to his TP, best-suited players first (keepers → HANDLING,
  forwards → SHOOTING).
- Tag chip = the 2-letter code in that skill's own CURRENT TRAINING STAFF bar colour
  (HANDLING orange `212,95,0`, SHOOTING dark red `85,0,0` — both directly witnessed).

Strings: `0x2593f0` `You can´t train any more players.` (acute accent verbatim) and
`0x2593b8` `For specific training\nyou have to have hired trainers.`

Band geometry measured off `tn1`: six rows at y 319 + 16i, height 12; name bar
x439..605 (name ink x442, star strip right-aligned to x604); TP cell x610..631.
The training grid's KEEPERS section has **3** slots (row tops 88 / 104 / 120), not 2.

This replaces `training_screen_re.md`'s honest gaps #2 (focus tags + AUTO) and #4
(CURRENT TRAINING STAFF band). Gaps #1 (FI column), #3 ("last" column) and #5
(per-section scrolling of the training grid) remain open.

---

## 7. Not a decode: why the alert box was blank on Android

Every PM98 alert renders through `PMAlert`, which read the raw font page with
`FileAccess.get_file_as_bytes("res://art/fonts/proman10.png")`. All twelve
`art/fonts/*.png` carried `importer="skip"` in their `.import` files so that only the
BMFont importer touched them — and **a skipped file is not exported**: unzipping a
shipped APK, `assets/art/fonts/` holds nothing but `.import` stubs and neither the loose
assets nor `assets.sparsepck` contains `proman10.png`.

On device the page therefore loaded empty, every glyph measured 0 ink, `line_ink()`
returned 0, and `box_rect()` collapsed to the 160-px minimum: **a small white box with
no text**, for signings, rejections, "The scout has finished his search." and every
other alert.

`importer="keep"` was tried first and **did not fix it** — the CI-built APK
`pm98-34c917e.apk` still shipped no page (checked loose and inside the sparse pack). The
working fix is to let the pages import as ORDINARY lossless textures (`compress/mode=0`,
`vram_texture: false`) and read the image off the imported `Texture2D`; the exporter
carries those the same way it carries every other sprite in the app. `PMAlert
._load_font_page` prefers that path, keeps the raw read as a fallback, and `push_error`s
if both fail so the failure can never be silent again. `DataBaseCardScreen`'s own atlas
read was on the same footing and is fixed with it. Verified by re-rendering the hub
alert: glyphs, the 3-layer drop shadow and the box metrics are unchanged.
