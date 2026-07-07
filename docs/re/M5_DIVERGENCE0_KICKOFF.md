# M5 Divergence #0 — the KICKOFF is wrong from tick 1 (2026-07-08)

**This supersedes the framing of div#1/#2/#3.** With a real per-tick ball reference for the
correct seed (`0xea0d2a8d`) now in hand, the port is shown to diverge at the **kickoff itself**
— every previously-chased divergence (trajbuf phantom goal, phase-6 stall, loose-ball freeze)
was a downstream symptom of a broken opening kick.

## The reference (finally correct-seed)

`~/MWM-AI/data/pm98-m4-oracle/m5_traj_correctseed_2026-07-08/m5_traj_timeline.jsonl`
Captured via `tools/re/wine/` (boot → menu-drive to Villa-vs-Bolton WATCH friendly KICK OFF
screen → **poke seed `0x006d3184 = 0xea0d2a8d`** + poke 5 pre-match timers/flags to the
capture2 frame0 values → `m5_poll_traj.py` → full time). Live frame0 matched
`capture2/frame0_struct_import.json` on **85/86 match scalars + seed** before kickoff.
**First goal reproduced EXACTLY: clk 2837, Villa 1-0** ⇒ clk 0..2837 is a bit-faithful
ball+carrier reference. (It diverges after the first goal — autoresume KICK-OFF click timing at
the restart, not the engine — so trust the clk 0..2837 window.)

Unlike the old `m5_traj_capture_2026-07-07` (which ran seed `252674751`, a *different* match —
goals 6944/8496/12244 — and is USELESS for tick-diff), this one is the same deterministic match
the app loads.

## The divergence (app CSV `m5_tick_trace` vs the reference, by clk)

| | real game | our port |
|---|---|---|
| kickoff taker | Villa slot-9 | Villa slot-9 ✓ |
| kickoff receiver | (pass) | Villa **slot-8** ✓ (`pass_target_select` correct) |
| **kickoff ball velocity** | **(-1251, -4777)** \|v\|≈4939 | **(-3865, -11828)** \|v\|≈12442 (**~2.52×**) |
| after kickoff | slot-8 **collects at clk 12** at (-19393,-47335) | ball rolls uncollected to the corner; slot-8 never reaches it |
| clk 50 ball | (-123298, -99384, z=14508) | (-183651, -562836, z=0) |

The port's opening kick is ~2.5× too powerful and slightly wrong in direction (velocity ratio
y/x: real 3.82 vs ours 3.06), so the ball **overruns the intended receiver** and rolls into the
corner where (much later) slot-9 re-collects it and dribbles the length of the pitch → the Bolton
keeper catches → the phase-6 goal-kick → the loose-ball freeze. All of that is downstream of this.

## Root-cause localisation (diag_m5_kickoff.gd)

- Taker = slot-9, receiver = slot-8 team0, **both correct**. So `pass_target_select` (FUN_005aa680)
  is NOT the bug.
- The kickoff **aim = our slot-8's post-spread position (-201452, -607696)** ≈ 640k units out.
  `setup_shot` (FUN_005ac1a0) launch power scales with `reach = dist(ball→aim) × pw`, so a 640k
  aim distance yields the ~2.5× velocity. The launch mechanism (velocity kick + roll friction) is
  the same as the real game's — only the magnitude/direction differ.
- **The real slot-8 cannot have started at (-201452, -607696):** it collects at (-19393,-47335)
  by clk 12, and no player runs 640k units in 12 ticks. So either (a) our **kickoff formation
  spread mis-places slot-8 too deep/wide**, making the aim too far, and/or (b) the **kickoff
  launch should be a short gentle tap** regardless of receiver distance (real \|v\|≈4939 is a soft
  tap), i.e. the power/skill inputs to `setup_shot` at kickoff differ.

## NEXT (invent nothing)

1. **Get the real slot-8 kickoff position.** Extend `m5_poll_traj.py` to also dump all 22 player
   positions (or at least the taker's team), re-capture the correct-seed match, and read slot-8's
   position at clk 0..12. That disambiguates (a) vs (b):
   - if real slot-8 is near center (~ -19393,-47335) → our **formation spread** is the bug
     (decompile-diff the phase-2 kickoff placement, the FUN_005b1420 / kickoff-formation path).
   - if real slot-8 is also ~640k out → the **kickoff kick power** is the bug (decompile-diff
     `setup_shot` inputs at kickoff: the aim, `m+0x19dc` ball-power, the taker skill `+0x394/+0x3a0`,
     and the RNG-draw count during phase 2 — a draw-count desync would shift power+angle).
2. Fix faithfully (oracle-lock against the binary), then re-diff: the kickoff ball velocity must
   match (-1251,-4777) and slot-8 must collect ~clk 12. Then re-run the whole M5 chain — div#1/#2/#3
   may simply dissolve once the opening kick is faithful.

## Reproduce
- Root cause: `~/godot462 --headless --path app --script res://tests/diag_m5_kickoff.gd`
  (taker slot-9, receiver slot-8 team0, aim (-201452,-607696)).
- Full trajectory diff: app CSV via `diag_m5_tick_trace.gd`, reference at
  `data/pm98-m4-oracle/m5_traj_correctseed_2026-07-08/`. First goal clk 2837 (both).
