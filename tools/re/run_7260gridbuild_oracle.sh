#!/usr/bin/env bash
# Oracle for FUN_005a7260 marker-grid GRID BUILD (0x5a7e23..0x5a800e), slice 2b-iii-b. Per outer-loop
# PASS the binary builds a 16-entry vec3 work grid on the stack (descending from esp+0x164 down to
# esp+0xb0) from the ball's predicted-trajectory array: work[j] = ball_traj(0x17+j), ball_traj(s) =
# the vec3 at ball + 0xc*s. PASS 1 additionally extrapolates the tail slots via a goal-oriented step.
# We drive the REAL FUN_005a7260 ENTERED MID-FUNCTION and read the built grid back off the stack:
#   pass 0: entry 0x5a7e23 (the loop setup: zeroes [esp+0x48]=pass, sets best-idx=-1) -> raw copy.
#   pass 1: entry 0x5a7e67 (the copy start) with [esp+0x48] POKED to 1 (the pass index) + ESI/ECX set
#           -> copy then the 0x5a7ec5 transform (atan/polar are REAL -> trig LUT + _ftol injected).
# Both paths reach 0x5a8010 (the scan setup) with the grid fully built and esp == entry-esp; we
# STUB 0x5a8010 0 0 BUILT so the harness pops [esp] (= our retSentinel) and RETs cleanly the instant
# the build finishes, leaving the work grid intact for read_mem (the scan never runs).
#
# Frame: sp0 = 0x308000; mid-fn entry => esp = sp0-4 = 0x307ffc. work grid esp+0xb0 = 0x3080ac
# (work[0]); work[j] at 0x3080ac + 12*j; [esp+0x48] = 0x308044. p @0x230000 (ESI), ball @0x280000
# (ECX + p+0x190), m @0x2a0000 (p+0x18c). GROUND TRUTH for Pm98Movement._marker_grid_build
# (app/tests/test_7260gridbuild.gd).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260gridbuild_oracle.txt
SPEC=$SPECDIR/_7260gridbuild_run.spec
ROUT=$SPECDIR/_7260gridbuild_run.out
LUT=$SPECDIR/_7260gridbuild_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# _ftol thunk (round-to-zero) for the atan x87 path; same bytes as the b05a0_phase2 / kick oracles.
THUNKS="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring (every fixture): p+0x18c=m, p+0x190=ball, p+0x2b8=team(0); m goal-X anchor.
# goalx = goal_target_x(orient=1, x=0x100000, team=0): (1&1)=1 != team0 -> NOT negated -> +0x100000.
CONST="$(poke 0x23018c 0x2a0000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 1)"

# Trajectory slots 0x17..0x26 at ball + 0xc*s. Distinct, sign-varying y to exercise atan(-anchor.y).
#   traj(s) = [0x100000 + 0x8000*s,  0x4000*(s-0x1e),  0x800*s]
TRAJ=""
for s in $(seq 23 38); do          # 0x17..0x26
  base=$(( 0x280000 + 0xc * s ))
  tx=$(( 0x100000 + 0x8000 * s ))
  ty=$(( 0x4000 * (s - 30) ))
  tz=$(( 0x800 * s ))
  TRAJ+="$(poke $base "$tx");$(poke $(( base + 4 )) "$ty");$(poke $(( base + 8 )) "$tz");"
done

# Read the 16 work-grid vec3 back: work[j] (x,y,z) at 0x3080ac + 12*j.
READS=""
for j in $(seq 0 15); do
  a=$(( 0x3080ac + 12 * j ))
  READS+="read_mem $(printf '0x%08x' $a) 4
read_mem $(printf '0x%08x' $(( a + 4 ))) 4
read_mem $(printf '0x%08x' $(( a + 8 ))) 4
"
done

# name|entry|extra-pokes  (pass 0: entry 0x5a7e23, N=0; pass 1: entry 0x5a7e67, [esp+0x48]=1, N per row).
FIX=(
  "copy0|0x005a7e23|$(poke 0x28005c 0)"
  "p1n1|0x005a7e67|$(poke 0x308044 1);$(poke 0x28005c 1)"
  "p1n13|0x005a7e67|$(poke 0x308044 1);$(poke 0x28005c 0xd)"
  "p1n33|0x005a7e67|$(poke 0x308044 1);$(poke 0x28005c 0x21)"
  "p1n61|0x005a7e67|$(poke 0x308044 1);$(poke 0x28005c 0x3d)"
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
maxsteps 200000
stub    0x005a8010 0 0 BUILT
EOF
    cat "$LUT"
    printf '%s\n' "$THUNKS"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${TRAJ//;/$'\n'}"
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
echo "# Oracle FUN_005a7260 GRID BUILD (0x5a7e23..0x5a800e). Built stack grid read back at esp+0xb0." >> "$OUT"
echo "# Row: GBUILD <name> <built=0|1> | 0x3080ac=<w0.x> 0x3080b0=<w0.y> ... (48 LE u32, work[0..15])." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ENTRY POKES <<<"$row"
  emit_spec "$ENTRY" "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  if echo "$LINE" | grep -q 'stubhits=.*BUILT'; then BUILT=1; else BUILT=0; fi
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  echo "GBUILD $NAME built=$BUILT | $KV" >> "$OUT"
  echo "[$NAME] built=$BUILT $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== 7260 grid-build oracle -> $OUT ==="
cat "$OUT"
