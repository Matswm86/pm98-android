#!/usr/bin/env bash
# Oracle for FUN_005a7260 marker-grid APPLY (0x5a829a..0x5a8453), slice 2b-iii-d. After the per-pass marker
# SCAN (slice 2b-iii-c) keeps a best marker, the outer 2-pass loop EXITS to the apply at 0x5a829a. The apply
# builds a polar locomotion steer-point (FUN_005ee0f0(KICK_GRID2[idx].x + best_score, facing +
# KICK_GRID2[idx].y + best_hd1)), sets m+0x461 |= 0x10 and p+0x44 = idx, then -- for the kick-grid markers
# 0/1 (DAT_006654e8[idx] == -1) -- FIRES the kick (keeper_event, enqueue 0xf, set_position_code(DAT_006654c0
# [idx]), stat++, ball.vel = 0, ball+0x68/0x6c/0x9c.., engage ball->p, ball+0x63 = 1, m+0x458 = 0); else it
# just set_position_code(DAT_006654e8[idx]). Both paths then write the locomotion target p+0x84/0x80/0x94/
# 0x98/0x9c/0x66. We drive the REAL FUN_005a7260 ENTERED MID-FUNCTION exactly like the scan oracle (build +
# scan run first); we DO NOT stub 0x5a8274 so the loop flows through to the apply, and STUB 0x5a8457 0 0
# APPLY (the apply TAIL start, 2b-iii-e) so the harness pops [esp] (= retSentinel) and RETs the instant the
# apply finishes -- every mutated field intact.
#
# ball+0x5c = 0 => the outer loop bound is 1, so a pass-0 best exits straight to the apply; for the pass-1
# fixture we enter at 0x5a7e67 (pass-1 copy start) with the per-pass seeds + N poked, exactly as the scan
# oracle, and the early-break (cmp edi,-1; jne 0x5a829a) carries the best to the apply.
#
# Frame/slot map == run_7260markerscan_oracle.sh. p @0x230000 (ESI), ball @0x280000 (p+0x190), m @0x2a0000
# (p+0x18c), stat @0x2c0000 (p+0x3b8). The apply's leaf calls run for real under the SAME guards the kick
# oracle uses: event queue frozen (m+0x1a38=1 => enqueue early-returns), keeper null (ball+0x50=0), audio/
# commentary gated off (m+0x180b/0x180c=0), DAT_006d31c4=0 (live => stat bump fires), DAT_006d3184=0 (RNG),
# ball+0x1d4 -> m (engage turnover), ball+0x40 = 0 (carrier null != p => engage latches p), atexit guard
# stubbed. KICK_GRID2 is ALSO lazy-init BSS (skipped by the mid-fn entry) => we poke it like KICK_GRID1.
# GROUND TRUTH for Pm98Movement._marker_apply (app/tests/test_7260markerapply.gd).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260markerapply_oracle.txt
SPEC=$SPECDIR/_7260markerapply_run.spec
ROUT=$SPECDIR/_7260markerapply_run.out
LUT=$SPECDIR/_7260markerapply_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# _ftol thunk (round-to-zero) for the atan/polar x87 path (FUN_005ee0f0 in the apply); same bytes as the
# scan / gridbuild / kick oracles.
THUNKS="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring. p+0x18c=m, p+0x190=ball, p+0x2b8=team(0). The apply's leaf-call deps: p+0x3b8=stat,
# ball+0x1d4=m (engage), m+0x1a38=1 (freeze enqueue). m goal-X anchor for the pass-1 tail extrapolation
# (unread by the scanned markers). p.pos (p+4/8/c) stays 0 so the scan sees D = work[frame] and the
# locomotion steer-point reads back as the raw polar (no p.pos offset to subtract out).
CONST="$(poke 0x23018c 0x2a0000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x2303b8 0x2c0000);$(poke 0x2801d4 0x2a0000);$(poke 0x2a1a38 1)
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 1)
$(poke 0x6d31c4 0);$(poke 0x6d3184 0)"

# A trajectory slot s lives at ball + 0xc*s; work[j] = traj(0x17+j): work[3]=traj(0x1a)@0x280138,
# work[5]=traj(0x1c)@0x280150.
traj() { local s=$1 x=$2 y=$3 z=$4; local b=$(( 0x280000 + 0xc * s )); echo "$(poke $b "$x");$(poke $((b+4)) "$y");$(poke $((b+8)) "$z")"; }
# ball.pos (ball+4/8/c) -> angle2 = atan(ball.pos - p.pos). p.pos stays 0.
bpos() { echo "$(poke 0x280004 "$1");$(poke 0x280008 "$2");$(poke 0x28000c "$3")"; }
# marker bbox m+0x1828..0x183c.
box() { echo "$(poke 0x2a1828 "$1");$(poke 0x2a182c "$2");$(poke 0x2a1830 "$3");$(poke 0x2a1834 "$4");$(poke 0x2a1838 "$5");$(poke 0x2a183c "$6")"; }

# KICK_GRID1 (0x674280) + KICK_GRID2 (0x674438) are LAZY-INIT BSS (zero in the static PE + skipped by the
# mid-function entry). The scan reads GRID1.x/.y/.z; the apply reads GRID2.x/.y (steer radius + heading).
# Restore the runtime values (== Pm98Movement.KICK_GRID1 / KICK_GRID2). 0x674000 page mapped by `zero`.
gv() { local base=$1; shift; local i=0 a; for a in "$@"; do echo "$(poke $(( base + i )) "$a")"; i=$(( i + 4 )); done; }
GRID1_INIT="$(gv 0x674280 \
  0x1b333 0 0x4000   0x9999 0 0x10000   0x9999 0 0x1cccc \
  0x21999 0x3555 0x3333   0x21999 0x3555 0xf333   0x21999 0x3555 0x1b333 \
  0x21999 -0x3555 0x3333  0x21999 -0x3555 0xf333  0x21999 -0x3555 0x1b333 | tr '\n' ';')"
GRID2_INIT="$(gv 0x674438 \
  0x14ccc 0 0   0x6666 0 0   0x6666 0 0 \
  0x18ccc 0x3555 0   0x18ccc 0x3555 0   0x18ccc 0x3555 0 \
  0x18ccc -0x3555 0  0x18ccc -0x3555 0  0x18ccc -0x3555 0 | tr '\n' ';')"

# Best-state seeds for the pass-1 entry (the pass-0 entry seeds these itself). wx/wy/wz seeded 0 for BOTH.
SEED_WORK="$(poke 0x308050 0);$(poke 0x308054 0);$(poke 0x308058 0)"
SEED_P1="$(poke 0x308044 1);$(poke 0x308028 -1);$(poke 0x308024 0);$(poke 0x308034 0);$(poke 0x308048 0x7c72);$(poke 0x30804c 0x7c72);$SEED_WORK"

# Read back the apply field mutations (all signed LE; bytes where noted).
READS="read_mem 0x002a0461 1
read_mem 0x00230044 4
read_mem 0x00230040 4
read_mem 0x00230084 4
read_mem 0x00230080 4
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x00230066 2
read_mem 0x00280068 4
read_mem 0x0028006c 4
read_mem 0x00280063 1
read_mem 0x00280070 4
read_mem 0x0028009c 4
read_mem 0x002800a0 4
read_mem 0x002800a4 4
read_mem 0x00280020 4
read_mem 0x00280024 4
read_mem 0x00280028 4
read_mem 0x002a0458 4
read_mem 0x002c0094 4"

# name|entry|extra-pokes.  (Same scan fixtures as run_7260markerscan_oracle.sh, plus hit1 for the idx-1
# kick marker.)  hit0 => idx0 kick (MARK_ACTION 0x2e); hit1 => idx1 kick (0x2f); p1hit2/bbox => idx2 no-kick
# (set_position_code 53); comp => the heading-replace winner. nohit => best-idx stays -1 (apply no-op).
FIX=(
  "hit0|0x005a7e23|$SEED_WORK;$(traj 0x1a 0x1b333 0 0x4000)"
  "hit1|0x005a7e23|$SEED_WORK;$(traj 0x1a 0x9999 0 0x10000)"
  "nohit|0x005a7e23|$SEED_WORK"
  "p1hit2|0x005a7e67|$SEED_P1;$(poke 0x28005c 0x15);$(traj 0x1c 0x9999 0 0x1cccc)"
  "comp|0x005a7e23|$SEED_WORK;$(bpos 0x100000 0 0);$(traj 0x1a 0x1b333 0x8000 0x4000);$(traj 0x1c 0x9999 0x400 0x1cccc)"
  "bbox|0x005a7e23|$SEED_WORK;$(bpos 0x100000 0 0);$(traj 0x1a 0x1b333 0 0x4000);$(traj 0x1c 0x9999 0x2000 0x1cccc);$(box 0x9000 -0x10000 0x1c000 0xa000 0x10000 0x1d000)"
  # Two-pass DISCRIMINATORS (slice 2b residual): N=8 => idxbase=trunc(7/4)=1 => pass-1 goal-extrapolation
  # rewrites the SCANNED work[5] (slot 0x1c), unlike the N=0/0x15 fixtures (idxbase 0/5 never touch work[5]).
  # Both enter at the FULL loop start 0x5a7e23 (not the pass-1 copy 0x5a7e67), so the REAL 2-pass loop runs.
  #   twopass => pass-0 MISS (slot 0x1a/0x1c parked at z=0x40000 -> every z-band fails) -> pass-1 HIT marker 6
  #              (extrapolated work[5]). Locks: n_passes=2, the L280 break does NOT fire after a miss,
  #              pass_idx=1 extrapolation feeds the scan, apply applies the pass-1 marker.
  #   brkkeep  => pass-0 HIT marker 6; the L280 break FIRES so pass 1 is suppressed and marker 6 is applied.
  #              Counterfactual (port _nobreak_loop) would extrapolate to marker 3 -> locks the break is load-bearing.
  "twopass|0x005a7e23|$SEED_WORK;$(poke 0x28005c 8);$(traj 0x18 -0x30000 -0x20000 0x3333);$(traj 0x1a 0x40000 0 0x40000);$(traj 0x1c 0x40000 0 0x40000)"
  "brkkeep|0x005a7e23|$SEED_WORK;$(poke 0x28005c 8);$(traj 0x18 -0x30000 0x18000 0x3333);$(traj 0x1a 0x40000 0 0x40000);$(traj 0x1c 0x12000 -0x8000 0x3333)"
)

emit_spec() {  # $1=entry  $2=extra-pokes
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ESI 0x00230000
reg     ECX 0x00280000
zero    0x00230000 0x00001000
zero    0x00280000 0x00002000
zero    0x002a0000 0x00002000
zero    0x002c0000 0x00001000
zero    0x00674000 0x00002000
maxsteps 2000000
stub    0x00605ff0 0 0 atexit
stub    0x005a8457 0 0 APPLY
EOF
    cat "$LUT"
    printf '%s\n' "$THUNKS"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${GRID1_INIT//;/$'\n'}"
    printf '%s\n' "${GRID2_INIT//;/$'\n'}"
    printf '%s\n' "${2//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a7260 marker APPLY (0x5a829a..0x5a8453). Field mutations read back at the 0x5a8457 tail." >> "$OUT"
echo "# Row: APPLY <name> <applied=0|1> | <abs-addr>=<signed LE> ... . p=0x230000 ball=0x280000 m=0x2a0000 stat=0x2c0000." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ENTRY POKES <<<"$row"
  emit_spec "$ENTRY" "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  # The no-op path (best-idx < 0) JUMPS to the 0x5a8457 stub too, so a stub-hit can't signal apply. The
  # apply's first write is m+0x461 |= 0x10, so anything but `0x2a0461=0` is the real "applied" discriminator.
  if echo "$KV" | grep -q '0x2a0461=0 '; then APPLIED=0; else APPLIED=1; fi
  echo "APPLY $NAME applied=$APPLIED | $KV" >> "$OUT"
  echo "[$NAME] applied=$APPLIED $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== 7260 marker-apply oracle -> $OUT ==="
cat "$OUT"
