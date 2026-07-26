# The "three forwards" cheat — what the BRIEF engine actually rewards, and how to force it

Reversed + built 2026-07-26. Two artefacts:

* `tools/hack/build_hack_exe.py` — patches a copy of the original `MANAGER.EXE` into
  `MANAGER_HACK.EXE` (the original is never modified).
* `tools/hack/run_hack_oracle.sh` — proves the patch in the Ghidra PCode emulator against
  the REAL bytes, both for effect and for non-regression.

Everything below is about the **statistical engine** (`FUN_0044ee70` PS==5), i.e. the one
that produces BRIEF and RESULT and every AI-vs-AI fixture. The positional/WATCH engine is
untouched. Engine map: [`stat_match_engine_re.md`](stat_match_engine_re.md).

## 1. Why tactics cannot help you (the finding that motivated the patch)

The instant engine reads exactly six per-player fields — `SEL`, `STR`, `GKSAVE`, `PASS`,
`POS`, `ROLE` — plus the club ids. The TEAM TACTICS modal's levers (ATTACKING /
SPECULATIVE / MIXED PLAY, PASSING↔LONG BALL, COUNTER ATTACK, TACKLING, MARKING,
CLEARANCES, PRESSURISE FROM) are **not among them**, so no setting on that screen can
change a BRIEF scoreline. Formation only redistributes *who* scores, through the
`POS_WEIGHT` roulette (`DAT_006532ec`, striker slot = 35, defender = 3).

What decides the score:

```
chances_per_side_per_half = rand()%8 + own_avgSTR - opp_avgSTR - 1
if chances < 0:  chances += rand()%own_avgSTR
if chances > (3 - rand()%3):  chances = 3 - rand()%3      <-- HARD CAP, 1..3
goal per chance = the defending keeper fails rand()%130 < GKSAVE
```

So a match is capped at **3 chances per side per half**, the cap binds near parity, and
`GKSAVE` (attribute `PO`, shown as HANDLING; +10 when the player is in lineup slot 0,
clamped to 99) is the single biggest lever any manager actually controls.

## 2. The patch

**Trigger:** the attacking XI holds **≥ 3 selected players with `ROLE == 3` (ATT/FOR)**.
Read live off the match struct (`participant +0x88` SEL, `+0xcc` ROLE, stride `0xac`,
side stride `0x7a0`), so it follows team selection with no save-file edit. Evaluated per
side, so an AI team fielding three forwards gets the same buff.

**Effects while the trigger holds for a side:**

1. `FUN_0044ee70` H1/H2 chance count floored at 3 for that side (the stock
   `3 - rand()%3` cap is still computed first, and still consumes its draws).
2. `FUN_0044ece0` skips the defending keeper's save gate for that side's chances.

Net: **6 goals a match** for a triggering side unless the stock rolls give it more.

**Mechanism.** Five 5-byte `E9` hooks into a 226-byte code cave placed in the .text
raw-size slack (VA `0x622847`, file `0x221c47`, 441 zero bytes before `.rdata`).
`.text` VirtualSize is grown `0x221847 → 0x221a00` so the cave is inside the section;
nothing is relocated and `SizeOfImage` is unchanged. Each hook site's original bytes are
asserted before patching.

| hook VA | stock bytes | what it was | rejoins |
|---|---|---|---|
| `0x44f802` | `ff d3 8d 04 40` | H1 side 0 chance cap | `0x44f836` |
| `0x44f899` | `ff d3 8d 04 40` | H1 side 1 chance cap | `0x44f8cd` |
| `0x44fb16` | `ff d3 8d 04 40` | H2 side 0 chance cap | `0x44fb4a` |
| `0x44fbb7` | `ff d3 8d 04 40` | H2 side 1 chance cap | `0x44fbeb` |
| `0x44ed04` | `66 83 bc 1a 88 …` | keeper-save gate | `0x44ed49` (skip) / `0x44ed12` (normal) |

Cave routines: `att3` (counts ATT-role selected players, returns `cmp ecx,3` flags),
`captrig` (replays the stock cap on ESI, then floors it), four per-site stubs, and
`kcave` (keeper gate).

**Not patched:** the extra-time chance loops (`0x450100+`, cup ties only) and the
positional engine.

## 3. Validation

`tools/hack/run_hack_oracle.sh` runs `FUN_0044ee70` PS==5 for four league seeds on both
programs in the PCode emulator (`MANAGER_HACK.EXE` must be imported into the Ghidra
project alongside `MANAGER.EXE`, `-noanalysis` is enough).

| fixture | stock | hacked |
|---|---|---|
| 0 forwards, seeds A-D | 3-2 / 4-2 / 0-1 / 1-3, draws 856/836/789/891 | **identical** — same draws, same event count, same final LCG state, same score |
| 3 forwards, same seeds | 3-2 / 3-3 / 2-1 / 4-2 | **6-2 / 6-2 / 6-0 / 6-3** |

The regression row is the important one: with fewer than three forwards the patched
binary is bit-identical to stock, so ordinary matches are untouched. The patched EXE also
boots and renders normally under Wine.

## 4. The Android port — SHIPPED 2026-07-26

`app/scripts/Pm98StatMatch.gd` already reproduced this engine bit-exactly, so the cheat is
a static flag plus the cave's own two effects, at the same two sites the EXE hooks:

| EXE | port |
|---|---|
| `att3` cave routine | `Pm98StatMatch._att_count(mem, side)` — selected `ROLE == 3`, per side |
| chance-cap hooks `0x44f802` / `0x44f899` / `0x44fb16` / `0x44fbb7` | `_half_chances()`, `c0`/`c1` floored to 3 AFTER `_chance_count` has run and consumed its draws |
| keeper gate hook `0x44ed04` | `_resolve()`, the `rng.mod(130) < GKSAVE` gate skipped for the attacking side |
| not patched: the ET chance loops | `_et_half()` untouched; `_resolve`'s gate still applies there, as in the EXE |

The draw order is the binary's: the stock `3 - rand()%3` cap is computed first and only
then raised, so a career replayed with the cheat OFF still reproduces stock exactly.

**The switch.** `AudioManager.cheat_three_up_front`, persisted in `user://settings.cfg`
under its own `[cheats]` block (it is NOT a PM98 option and does not live with them), and
mirrored into `Pm98StatMatch.cheat_three_up_front` by `AudioManager.set_three_up_front`.
The UI is one row on the hub's OPTIONS modal, **the only invented pixels in this port**:
`OptionsPanel.R_CHEAT_ON` / `R_CHEAT_OFF` inside the declared `R_CHEAT_BAND`, drawn in the
game's own proman face, the modal's frame-sampled label ink `(255,223,0)` and its white
ON/OFF caption ink, right-aligned on the same `x=266` every baked label ends at.
`tools/re/diff_options_parity.py` bounds the concession: the rest of the modal is still
**0 px** against `screenshots/wine-captures-2026-07-12/dropdown_options_panel.png`, the
band overlaps none of the original's controls, and the original draws nothing under it.

**Tests.** `app/tests/test_three_up_front.gd` (41 checks, all pass) asserts all three
claims against the emulator's own numbers: cheat ON with no forwards reproduces the eight
banked stock fixtures draw-for-draw (draws + final LCG state + full event queue + score);
three forwards with the cheat OFF gives the stock 3-2 / 3-3 / 2-1 / 4-2; with it ON gives
the hacked 6-2 / 6-2 / 6-0 / 6-3. `test_options_panel.gd` pins the band's containment and
the setter wiring. Real render of both states: `PM98_OPTIONS_SHOT=1` (`Main._options_shot`).

## 5. README wording (drop under the Download section)

```markdown
### Three up front

Field three forwards and the match engine stops pretending: your chance count is floored
and the opposing keeper stops saving. Off by default, toggle it in OPTIONS. It changes
the instant-result engine only — watched matches play normally.
```
