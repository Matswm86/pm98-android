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
