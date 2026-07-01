#!/usr/bin/env bash
# Stage 3 (POSITIONAL port, Task #1): drive the REAL FUN_005a4600 (engine_tick -- the per-player
# OPEN-PLAY ENGINE, player vtable +0xc, run x2/tick by FUN_005b8c20) through the Ghidra PCode emulator
# and bank the SKELETON's field writes + the movement-fn SELECTION that Pm98Action.engine_tick must
# reproduce bit-for-bit (app/tests/test_engine_tick.gd).
#
# Leaf calls are STUBBED (PcodeEmu `stub`): the 7 action handlers (FUN_005acc40/ad010/ad970/
# adc60/adfc0/ae4c0/ae910), the resolver case 8/9 (FUN_005aeda0), the case-0x13 shot-setup (FUN_005ac1a0),
# the teammate-count (FUN_005b0b40), 1 movement fn (FUN_005a65a0; 9490 un-stubbed s10), and the 6 DEFERRED settle sub-leaves
# (FUN_005b1420/5a8ac0/5aa4d0/5aa870/5aafd0/5b8ce0). Three movement fns now run REAL here (un-stubbed):
# FUN_005a7260 (Pm98Movement.ball_touch_7260), FUN_005a8f20 (Pm98Movement.steer_8f20, body-orient steer at
# LAB_005a4fa2 AND inside settle), and FUN_005a8680 (Pm98Movement.settle_8680, wired via _move_8680), so
# test_engine_tick verifies all three transitively. FUN_00605ff0 (atexit) is stubbed as a fault-guard for the steer box-init it
# now reaches. Each stub returns 0, pops its args, and LOGS a "STUB <label> ... arg0=.." line so the
# movement-fn selection + arg stay observable. The in-image pure helpers run REAL: tick_action=FUN_005a50c0, set_phase=005942e0,
# set_position_code=005a5430, play_state=005943b0, within_box=00590c10, FUN_00606220 (no-op).
#
# These Step-1 fixtures pick states that DRAW NO rng (no case 6/7 windup, no moving-ball 0x1c, no 0x1d,
# no case-0x13 bVar17) so FUN_005ec250 never fires -- the skeleton's own arithmetic is the surface.
#
# Memory: player P @0x230000 (ECX/ESI), match @0x260000 (P+0x18c), ball @0x270000 (P+0x190 = decompile
# "+400"), gs @0x280000 (P+0x184), play-state @0x290000 (match+0x468). +0x34/+0x66 are WORDs (read 2).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/engine_oracle.txt
SPEC=$SPECDIR/_engine_run.spec
ROUT=$SPECDIR/_engine_run.out
LUT=$SPECDIR/_engine_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 (+atan) -- harmless if unread

# Stubbed leaves: "VA RET ARGBYTES LABEL".
STUBS=(
  "0x5b0b40 0 4 B0B40"     # FUN_005b0b40 (thiscall player; 0xfffe0000) teammate count
  "0x5aeda0 0 0 AEDA0"     # case 8/9 resolver
  "0x5acc40 0 0 ACC40"     # case 4/0x25
  "0x5ad010 0 0 AD010"     # case 5/0x24
  "0x5ad970 0 0 AD970"     # case 0x36
  "0x5adc60 0 0 ADC60"     # case 0x37
  "0x5adfc0 0 0 ADFC0"     # case 0x19/0x1a
  "0x5ae4c0 0 0 AE4C0"     # case 0x14/0x16
  "0x5ae910 0 0 AE910"     # case 0x15
  "0x5ac1a0 0 0 AC1A0"     # case 0x13 shot setup
  "0x5a65a0 0 4 M65a0"     # general move (arg = iStack_38)
  # NOTE: FUN_005a9490 (M9490, the lean) is NO LONGER STUBBED -- ported + WIRED (Pm98Movement.lean_9490
  # (p, true, rng), called from Pm98Action._move_9490; slices A/B/C oracle-locked by run_9490sliceA/Bi/
  # Bii/Biiarm/C_oracle.sh). It runs REAL here so test_engine_tick verifies it transitively. In these
  # Step-1 fixtures every lean path bails without writes (case1f fails the action gate; settle8680 takes
  # the Slice-A close-dribble return; the rest reach Slice C but return at the p+0x2bc == 0 gate).
  # FUN_005a8680 (settle) is NO LONGER STUBBED -- it is ported + WIRED (Pm98Movement.settle_8680(p, true),
  # called from Pm98Action._move_8680) and runs REAL here so test_engine_tick verifies it transitively. Its
  # body-orient steer leaf FUN_005a8f20 stays un-stubbed (runs REAL, GREEN). The OTHER six settle leaves are
  # DEFERRED -- stubbed below (returning 0, except B1420's discarded bool 1) so the settle SELECTION + the two
  # direct writes (p+0x5d / p+0x54) are the surface; they get wired in a later gate. Argbytes per run_settle_oracle.sh.
  "0x5b1420 1 0 B1420"     # settle: off-ball reposition gate (returns bool, discarded)
  "0x5a8ac0 0 8 M8AC0"     # settle: curve-speed windup (heading, 100)
  "0x5aa4d0 0 0 AA4D0"     # settle: kick_setup (distinct call site)
  "0x5aa870 0 4 AA870"     # settle: controller possession tail (arg 0)
  "0x5aafd0 0 4 AAFD0"     # settle: non-controller possession tail (arg 1)
  "0x5b8ce0 0 4 B8CE0"     # settle: select_nearest(gs, 1)
  "0x605ff0 0 0 atexit"    # FUN_00605ff0 atexit (7260 lazy-init marker grids + steer box-init) -- fault guard
)
# NOTE: FUN_005b0b40 (B0B40, the opponent-count for the +0x2d8 flag) is now PORTED
# (Pm98Action._count_teammates_closer, oracle-locked via run_b0b40_oracle.sh -> test_b0b40.gd). It STAYS
# stubbed-to-0 HERE because these Step-1 fixtures build no opponent descriptor (P+0x188 zeroed); the
# port likewise returns 0 on the empty roster, so the two sides match. A future engine fixture that
# populates P+0x188 must drop this stub to exercise the non-trivial count.
# NOTE: FUN_005ac1a0 (AC1A0, the case-0x13 shot-setup) is now PORTED + WIRED into engine_tick
# (Pm98Movement.setup_shot, called from Pm98Action._case_distribution). It STAYS stubbed-to-noop HERE only
# because these Step-1 fixtures keep +0x2c != 5 (bVar17 false) so case 0x13 never reaches the call -- inert on
# both sides, like B0B40. The wired path is oracle-gated in run_engine_dist_oracle.sh -> test_engine_dist.gd.
# NOTE: FUN_005a7260 (M7260, the ball-touch/dribble decision) is NO LONGER STUBBED -- it is ported
# (Pm98Movement.ball_touch_7260) and runs REAL here so test_engine_tick verifies it transitively. Its
# slice-1 reachable surface for these fixtures: flag2d8 (not-same-side) takes the goal-anchor steer
# (89c0/8bc0, INERT on the zeroed box -> arrives early, no 8f20); stamina16/case1f (same-side) defer at
# the open-play gate after the lazy-init (which writes only the 0x674xxx marker grids, mapped below).
# NOTE: FUN_005a8f20 (M8f20, the body-orient steer / FPU APPLY) is NO LONGER STUBBED -- it is ported
# (Pm98Movement.steer_8f20) and runs REAL at LAB_005a4fa2 so test_engine_tick verifies it transitively.
# Reachable surface for these fixtures: facing==0 so the turn delta is 0 (no carrier ftol ball-advance,
# no steer-to-ball override); it sets the once-per-tick guard +0x2d7, ramps speed +0x68, and re-stamps
# the action/position code +0x40 via set_position_code (005a5430) -- those writes are now in the oracle.

READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"
  "0x00230020 4" "0x00230024 4" "0x00230028 4"
  "0x0023002c 4" "0x00230030 4" "0x00230040 4" "0x00230048 4"
  "0x0023004c 4" "0x00230050 4" "0x00230054 4" "0x00230058 4"
  "0x0023005d 1"
  "0x00230034 2" "0x00230066 2"
  "0x00230064 4" "0x00230068 4"
  "0x0023006c 4" "0x00230070 4" "0x00230074 4"
  "0x00230080 4" "0x00230084 4" "0x00230088 4" "0x002300b4 4"
  "0x002302d7 1" "0x002302d8 1"
  "0x00270020 4" "0x00270024 4" "0x00270028 4"
  "0x00260448 4" "0x0026044c 4" "0x00260461 4"
  "0x002802e8 4"
)

emit_spec() {
  {
    cat <<EOF
entry   0x005a4600
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00270000 0x00001000
zero    0x00280000 0x00001000
zero    0x00290000 0x00001000
zero    0x00674000 0x00001000
maxsteps 400000
EOF
    cat "$LUT"
    # _ftol thunk (membts @0x252000, ptr @0x6233a4) -- the un-stubbed lean can reach FPU helpers
    # (FUN_00436fb0) on deeper fixtures; harmless if unread, same guard as the 9490 slice oracles.
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    printf 'mem 0x%08x 4 0x%08x\n' 0x6233a4 0x252000
    for s in "${STUBS[@]}"; do echo "stub $s"; done
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# All fixtures: P+0x18c -> match, P+0x190 -> ball, P+0x184 -> gs.
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x230184 0x280000)"

FIX=(
# prologue flag = 1: sign(+4) != sign(+0x3a4) and stubbed count<=1. action 2 with +0x48 locked.
"flag2d8|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x230004 5);$(poke 0x2303a4 -5)"
# 16-tick stamina block: +0x88 wraps to 0; s68<0x777 recovery + the (p74*4)/5 + 72000/half decay.
"stamina16|$(poke 0x230040 0);$(poke 0x230048 5);$(poke 0x230088 0xf);$(poke 0x230068 0x100);$(poke 0x230070 10);$(poke 0x230074 100);$(poke 0x230078 20);$(poke 0x2619ac 2700)"
# switch case 0x1f: zero ball velocity. +0x48 locked so tick_action keeps +0x40 = 0x1f.
"case1f|$(poke 0x230040 0x1f);$(poke 0x230048 3);$(poke 0x270020 5);$(poke 0x270024 6);$(poke 0x270028 7)"
# movement-decision -> M8680 (settle): is controller (ball+0x40==P), armed highlight, bv stays false.
"settle8680|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x26044c 7);$(poke 0x260438 0x230000);$(poke 0x230184 0x280000);$(poke 0x2802ee 1);$(poke 0x23005c 1);$(poke 0x260468 0x290000);$(poke 0x270040 0x230000)"
# movement-decision -> M65a0(iStack_38=0): not controller/engaged, armed false so bv true.
"move65a0|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x26044c 7);$(poke 0x260438 0x230000)"
)

: > "$OUT"
echo "# Stage 3 POSITIONAL Task #1: FUN_005a4600 (engine_tick) SKELETON PCode-emu truth." >> "$OUT"
echo "# Leaves STUBBED (action handlers + resolver + 65a0 + teammate-count + 6 settle sub-leaves); 7260+8f20+8680+9490 + in-image helpers real." >> "$OUT"
echo "# Each row: FIX <name> + verbatim CALL/STUB lines. STUB lines show selection+arg; mem[]= the field writes." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  echo "## FIX $NAME" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT"
  RET=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "[$NAME] $(echo "$RET" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  2d8=$(echo "$RET" | grep -oE 'mem\[0x2302d8:1\]=[0-9-]+')  70=$(echo "$RET" | grep -oE 'mem\[0x230070:4\]=[0-9-]+')  74=$(echo "$RET" | grep -oE 'mem\[0x230074:4\]=[0-9-]+')  stubs=$(grep -cE 'CALL 0 STUB' "$ROUT")"
done
echo "=== engine oracle -> $OUT ==="
cat "$OUT"
