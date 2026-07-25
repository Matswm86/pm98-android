# M4 end-to-end match oracle — wine MANAGER.EXE harness

Plan `docs/re/PLAN_byte_exact_match_engine.md` **M4**, option (b): drive the real
`MANAGER.EXE` under wine to a full match and read the scoreline + event stream from the
live match struct, as the reference the byte-exact port must reproduce (M5 kill-test).

Status: **DONE (2026-07-07).** First reference captured — see
`m4_reference_villa_bolton.json`. Aston Villa 2-2 Bolton W (goals 21', 63', 66', 88'),
FULL TIME dispatch code 10, from frame-0 seed `0x8abd86a4`.

## Clean (breakpoint-free) re-drive — 2026-07-07

`m4_clean_rerun_villa_bolton.json` is a same-fixture re-drive with **zero winedbg
breakpoints** held during play: base found by `m4_findbase.py` (vtable scan, no debugger),
then `m4_poll.py` + `autoresume.py` to FULL TIME. Result **Aston Villa 0-1 Bolton W**,
dispatch code 10, with internal score offsets == on-screen scoreboard. This **settles the
H1-perturbation caveat**: the read-only breakpoints did not corrupt the banked 2-2 (the
0-1 differs only because the seed differs — exact reproduction still needs the seed poked
at 0x006d3184, untested).

## Headless display (no Xvfb / no root)

The walkthrough used the COSMIC desktop's `DISPLAY=:1`. Headless (e.g. a Claude Code run
with no seat), start a rootful Xwayland as a client of the live cosmic-comp and point the
harness at it — `env.sh` now honours a preset `DISPLAY`:
```
export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
Xwayland :2 -geometry 800x600 -retro &
export DISPLAY=:2   # boot.sh/click.sh/snap.sh follow it
```

## The harness (only mode that works on this COSMIC/Xwayland box)

Render + synthetic clicks REQUIRE a wine virtual desktop with the FULL windows path and
`MANAGER.INI` `FULL SCREEN: OFF` (proven 2026-06-24). Bare/direct wine is unusable.

| script | does |
|--------|------|
| `env.sh`            | shared env (DISPLAY=:1, WINEPREFIX=repo `.wineprefix`, out dir) — source it |
| `boot.sh`           | launch `wine explorer /desktop=pm98,640x480 C:\PM98\MANAGER.EXE` |
| `snap.sh <name>`    | screenshot the window via `ffmpeg -f x11grab -window_id` |
| `click.sh X Y [n]`  | synthetic click at window-relative coords |
| `wdbg_pid.sh`       | print `0xWPID LPID` (Windows PID for winedbg attach, Linux PID for /proc) |
| `dump_mem.py`       | `full <lpid> <dir>` snapshot all rw regions; `read <lpid> <hex> <n>` hexdump |
| `m4_findbase.py`    | find the match-struct base with ZERO winedbg (vtable 0x6390e0 + scale 14400) |
| `m4_poll.py`        | poll the match struct -> JSONL timeline (writes on change) |
| `m4_seedtrace.py`   | per-frame seed/clock trace via a winedbg breakpoint on 0x5983f0 |
| `autoresume.py`     | click KICK OFF at each WATCH segment pause until FULL TIME (KICK OFF button ONLY) |
| `m5_gdbrsp_watch.py`| HW write-watchpoint via `winedbg --gdb` + raw RSP (Z2/vCont;c); names position writers (s32) |
| `m5_gdbrsp_seedwatch.py`| Z2 on the LCG seed 0x006d3184: one stop per RNG draw, `ret0`=[esp] names the drawing call-site (s33) |

## The pixel-signature auto-driver (`autodrive.py`) — 2026-07-25

A blind click list desynchronises within a few weeks: the original raises news boards,
alert boxes, cup draws and award sheets in an order the sim decides. `autodrive.py`
looks at the frame before every click.

| verb | does |
|---|---|
| `learn NAME X,Y,W,H frame.png [more.png] [--step N]` | teach a screen — keeps only the lattice probes whose RGB is identical in EVERY teaching frame, so club names/scores/dates drop out and the chrome stays |
| `id [--frame f.png]` | name the screen on the wire (or in a file) and print the five closest |
| `shots DIR` | re-identify a whole capture directory |
| `run plans/season.json` | drive by the rule table |
| `snap NAME` / `click X Y` / `probe X Y` | one-shot helpers |

`run` loops: grab -> identify -> look the screen up in the plan's rules -> click. Rules
are `{"click": [x, y]}`, `{"click_alert_ok": true}`, `{"click_template": "ok_button.png"}`,
`{"swap_unavailable": true}` or `{"type": "text"}`. **An unknown screen stops the drive**
and is saved — every stop is a screen never witnessed, which is the point.

- Signatures live in `screens.json`; teach with `teach.sh PLAN NAME ROI FRAME X Y` to add
  the rule in the same step.
- **Most-specific-wins**: a modal leaves the screen under it intact, so both signatures
  pass; the one with more probes (teach overlays over the panel they draw) wins.
- **Animations**: the pre-match LINE-UPS reveal takes ~35 s and the cup-draw drum plays
  once. An unknown frame is re-grabbed for `retries` rounds AND filmed at 25 fps
  (`film.sh`) so sprite order survives. `film.sh NAME SECS [FPS]` also stands alone.
- **The XI-validity gate IS scriptable** (contrary to `record_play.py`'s premise): the
  original refuses to advance the week while an injured or banned player is in the XI, and
  two synthetic clicks in the name column — the unavailable row, then a fit substitute —
  clear it. Verified live 2026-07-25: Holdsworth (injured 5 weeks) out, Fairclough in,
  TEAM RATING 72 -> 79. `swap_unavailable` does exactly that; an unavailable row is the
  gold plate `(212,191,85)` at x=60 with the dark-gold `(170,127,0)` status band.
- **`loop_breaker`** names the way out of a screen pair the drive cannot leave
  (hub -> alert -> hub is the XI gate); it fires only on the `when` screen so the click
  lands on the hub and not on the modal.
- **The 2026-07 archived captures are 641 px wide** — the same 640 px window plus one
  black column at x=640 (99.92 % of pixels identical at offset 0). `as_frame` crops.

## Reproduce the capture

1. `bash boot.sh` — game to the title screen.
2. Navigate to a match (coords in `handoff-pm98-kickoff-phase2-exit-LIVETRACED-2026-06-24`):
   MANAGER LEAGUE 165,277 -> TRAINER 175,135 -> name row 160,110 + type -> team 291,318 ->
   CONTINUE 565,438 -> preseason opp 50,385 + SKIP 557,344 x3 -> CONTINUE 567,452 -> champs
   CONTINUE 575,460 -> hub CONTINUE 588,267 -> MATCH OPTIONS WATCH 160,288 + OK 485,350 ->
   intro, click 320,240 x2 -> KICK OFF screen; KICK OFF button 320,457.
3. `WPID LPID=$(wdbg_pid.sh)`; attach winedbg, `break *0x005983f0`, `cont`, click KICK OFF;
   at the first hit `p $ecx` = the match base. Snapshot: `dump_mem.py full <LPID> <dir>`.
   Detach cleanly (`detach`/`quit`; a `kill -9` of winedbg kills the game).
4. `m4_poll.py <LPID> <base> timeline.jsonl &` then `autoresume.py autoresume.log` —
   it clicks through every segment/half-time board to FULL TIME (disp code 10).

## Gotchas (all bit us 2026-07-07)

- **`/proc/<pid>/mem` must target the GAME, not the explorer wrapper.** Both cmdlines
  contain `MANAGER.EXE`; the desktop-wrapper PID reads all-zero. `wdbg_pid.sh` matches
  `^C:.PM98.MANAGER\.EXE`.
- **winedbg driven by a FIFO blocks on `cont`** (wine suspends via wineserver, not a
  /proc stop). Recover the prompt with `kill -INT <winedbg-lpid>`; it then replays the
  queued backlog. For a clean per-frame trace this makes the seedtrace fragile — the
  `autoresume` + free-run `m4_poll` path is what actually produced the reference.
- **WATCH mode plays in ~20-min segments, pausing at the 2D events board** (`MatchScreen`
  layout). The KICK OFF button (320,457) resumes; half-time takes a few clicks. Clock
  frozen == waiting for the click. `autoresume.py` handles this.
- The seed at `0x006d3184` advances as the documented MSVC LCG (verified: 190/215 clean
  LCG steps between free-run polls).
- **A center-pitch click in the 2D WATCH view opens the player/substitution overlay**,
  which is MODAL and pauses the sim clock (`+0x450` freezes). It does NOT time out. The old
  `autoresume.py` center-nudge triggered it and trapped the drive at ~81'. `autoresume.py`
  now clicks the KICK OFF button ONLY. Dismiss the overlay with a click on an empty pitch
  corner (e.g. `155 460` or `60 180`); the sim then resumes to FULL TIME.
- **Keyboard: `xdotool key --window` (XSendEvent) is DROPPED by wine on Xwayland `:2`.**
  Use GLOBAL XTEST `xdotool key <char>` (no `--window`) after parking the pointer over
  the window (clicks via `--window` still work). Bit the name-entry step 2026-07-07.
- **For a COMPLETE frame-0 (M5 byte-load), use `dump_mem.py full` at the KICK OFF screen**
  (clean pause, no winedbg): the struct is already frame-0 (phase 2, +0x1a1e armed,
  timers set) and both 11-player heap arrays + the session are allocated, so a full dump
  captures players (@0x361xxxx/0x37xxxxx) + session (match+0x468) that a single-region
  dump MISSES. `m4_struct_import.py` then follows those pointers. (The old 2-2 single-
  region dump saved only 1/293 regions -> no players/session -> unusable for M5.)
- **The `+0x19a0` half flag stays 0 for most of the match and only flips to 1 late**
  (seen at ~74' this run); it is NOT a reliable H1/H2 gate for the poller. `+0x450` is the
  continuous match clock (0..14400 = 0..90'); full time is `+0x1a38 == 10`.
- **Hardware watchpoints (2026-07-11, s32):** interactive winedbg `watch` is UNUSABLE on this
  no-debug-info target (`watch *0x<addr>` → "No type or type mismatch"; `(int*)` casts fail
  silently). Use `winedbg --gdb --no-start --port N 0xWPID` + `m5_gdbrsp_watch.py` (raw RSP:
  Z2 watchpoint, `vCont;c`, EIP from the T05 expedited registers). Gotchas: plain `c` resumes
  ONE thread only (game stays frozen — check utime advances before clicking); the stub accepts
  exactly ONE connection; killing the stub (even SIGTERM) KILLS the game; attaching while
  another winedbg probe runs (`wdbg_pid.sh`) fails with error 87 — retry after it exits.
- **wine's Z2 fires on ACCESS, not just write** (s33): each rand() call stops TWICE — the
  entry LOAD (eip 0x5ec255, seed unchanged) then the post-store trap (eip 0x5ec271 = the
  draw). Filter on the store eip; `[esp]` at that stop is the drawing call-site (no frame).
  Detach after `done` may still kill the game ("stub closed") — capture first, game is
  expendable after.

## RSP-only capture (ptrace_scope=1, NO sudo) — 2026-07-18 (s44)

Wine double-forks every process to PPid 1, so /proc/<lpid>/mem is Yama-blocked at
scope 1. The winedbg --gdb stub works WITHOUT sudo (wineserver holds PR_SET_PTRACER):
its RSP `m`/`M`/`Z1`/`Z2` packets replace all /proc I/O — but ONLY after `Hg<tid>`
(thread from the `?` T05 reply); without it the stub never answers `m`.

- `m5_rsp_capture.py <port> <lpid> <ref_json> <out> [stop_clk] [win_lo] [win_hi] [base_hex]` —
  base candidates/scan + frame0 poke + XI check + Z2 seed-watch, full-roster row per draw.
  s53 rows carry the FUN_005b1420 gate: player tail `[+0x184, +0x5c, +0x2b8, +0x2bc, +0x2d7,
  +0x2d8]`, a per-team `gs` row (`+0x1fc/+0x200/+0x204` resolved to `[team, idx]`, `+0x2ee`)
  and `sub_fa0`. Read it with `tools/re/m5_b1420_arm_solve.py`.
- `m5_rsp_steertgt.py <port> <ref_json> <out> [team] [idx] [stop_clk]` — poke + Z1 on
  FUN_005a89c0, per-hit steer target + player + ball dump for one player.
- Gotchas: stub accepts ONE connection; client disconnect kills the stub (game usually
  dies); never wrap the stub in `timeout` (SIGTERM kills the game); a Z1 on the outer
  step 0x5983f0 held across the KICK OFF click CRASHES the stub — use the base
  candidates 0x03dbf0d8 / 0x03dbf060 (reproduce per boot) or the mem scan;
  the preseason injury roll can silently swap a starter — the XI check aborts,
  re-roll the boot (~1-in-2 clean); lpid is used ONLY for /proc/<lpid>/maps (not gated).
- **The base MOVES with the WINEPREFIX path length** (s53): the same boot+nav under a copied
  prefix landed at `0x03dcf1d0`, not `0x03dbf0d8`, so the stored candidates missed and the
  fallback mem scan ran. That scan costs ~20 min per 2 MB (RSP `m` moves ~500 B/round trip),
  so it now probes `0x03d00000-0x03e00000` first — every observed base is in that band. If a
  boot lands outside it, add the new value to the candidate list and note it here. Observed so far:
  `0x03dbf060` (s34), `0x03dbf0d8`, `0x03dbf228` (s53), `0x03dbf240` (s54, prefix copied under
  `/tmp/...`), `0x03dcf1d0`.
- **Concurrent sessions collide.** One wineprefix = one wineserver, and `explorer /desktop=<name>`
  reuses an existing desktop of that name: a second boot on another DISPLAY dies with
  `X Error … BadWindow … X_CreateWindow`. Isolate with `cp -a` of the prefix plus
  `PM98_WINEPREFIX=<copy> PM98_DESKTOP=<other-name>` (env.sh honours both, and `wdbg_pid.sh`
  picks the LPID whose `/proc/<pid>/environ` carries that prefix). s54: the reference CAREER session
  runs on `DISPLAY=:2` with the repo prefix — do not disturb it; start a second Xwayland
  (`Xwayland :3 -geometry 800x600 -retro &` with `XDG_RUNTIME_DIR=/run/user/1000
  WAYLAND_DISPLAY=wayland-1`) and drive the copy there.
- `m5_rsp_b0040trace.py <port> <lpid> <ref_json> <out> [team] [idx] [arm_clk] [stop_clk]` (s54) —
  poke + seed free-run + `Z1` inside the real `FUN_005b0040`: per-iteration `lead_in`/`nd`/`lead_out`
  from the bisection, the pre-clamp accumulator, and the live `P+0x70/0x3a8/0x3ac`, clamp box and
  `ball+0x74/0xb0/0xbc/0xcc/0xd8`. Read with `tools/re/m5_b0040_trace_solve.py`. NOTE: winedbg
  accepted a 4th `Z1` at `0x5b04c1` but never reported a hit for it — key any exit condition off the
  `0x5b04a6` stop instead, or the capture never ends.
- **The XI check is necessary but not sufficient.** It compares `+0x4/+0x8/+0x2c8/+0x37c/+0x380`.
  Two runs can share an identical XI yet differ in the derived pace/stamina fields
  (`+0x37c/+0x380`, `docs/re/session_lineup_re.md`) because the preseason condition roll differs
  — s53 hit exactly that on t0.i9. Cross-check the captured `0x34/0x64/0x68` ladder against the
  banked one (`tools/re/specs/b0040_m5_live_heading.txt`) before trusting a run.
