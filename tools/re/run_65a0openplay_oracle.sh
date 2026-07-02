#!/usr/bin/env bash
# Stage 3 (s12, movement subtree): drive the REAL FUN_005a65a0 (the per-player movement dispatcher)
# through the Ghidra PCode emulator across its OPEN-PLAY arms -- the surface the s12 restructure of
# Pm98Movement.move_dispatch must reproduce bit-for-bit (app/tests/test_65a0openplay.gd):
#   * the velocity block (L43-109) now running for EVERY player (the p+0x54 wander re-arm),
#   * the param_2==0 FUN_005b1420 formation gate (L129-136) with the b1500/b1c80 role sub-leaves
#     STUBBED to return 1 -- exactly mirroring the port's formation_gate_b1420 stubs,
#   * arm 1: the non-active FUN_005b0040 leaf, the active goal-anchor steer (L144-152) and the
#     active chase-return (L153-204: steer + SIGNED facing gate + nearest-teammate scan +
#     FUN_005aa490 pass-handoff / plain FUN_005aa4d0, p+0x63 clear),
#   * arm 2 (m+0x440 != 0, phase 0): non-active 8f20/b0040 split + the active sideline steer +
#     FUN_005aa870(0) tail (L206-232),
#   * the IF-A anim-end (L394-401) and the phase-2 holder-steer / phase-4 free-kick run-up taker arms.
# Everything else runs REAL in-image (b0040 / the steering trio / aa4d0+aa680 / aa870 / b1420 /
# 5ec250 LCG / 5a5430). ONLY 0x5b1500 / 0x5b1c80 are stubbed (ret 1) -- the port's exact deferral.
#
# Memory map (zeroed windows): P@0x230000 (ECX), M@0x210000 (P+0x18c), C=ball@0x240000 (P+0x190),
# T=gs@0x250000 (P+0x184), Q0@0x310000 Q1@0x3103bc (the roster, T+0 base / T+4 count, stride 0x3bc).
# rand seed @0x6d3184 = 1 every fixture. param_2 is the single stack arg.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/65a0openplay_oracle.txt
SPEC=$SPECDIR/_65a0openplay_run.spec
ROUT=$SPECDIR/_65a0openplay_run.out
LUT=$SPECDIR/_65a0openplay_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos/atan LUT @0x6d31c8 -- the steer/atan leaves read it

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

emit_spec() {  # $1 = param_2 (stack arg), $2 = newline-joined pokes
  {
    cat <<EOF
entry   0x005a65a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
arg     $1
zero    0x00230000 0x00001000
zero    0x00210000 0x00002000
zero    0x00240000 0x00001000
zero    0x00250000 0x00001000
zero    0x00290000 0x00001000
zero    0x00310000 0x00001000
zero    0x00674000 0x00001000
maxsteps 4000000
EOF
    cat "$LUT"
    # _ftol thunk (membts @0x252000, ptr @0x6233a4) -- the steering trio + atan reach FPU helpers.
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    printf 'mem 0x%08x 4 0x%08x\n' 0x6233a4 0x252000
    echo "stub 0x5b1500 1 0 B1500"
    echo "stub 0x5b1c80 1 0 B1C80"
    echo "stub 0x605ff0 0 0 atexit"
    printf '%s\n' "$2"
    for r in \
      "0x00230020 4" "0x00230024 4" "0x00230028 4" "0x0023002c 4" "0x00230030 4" \
      "0x00230034 2" "0x00230040 4" "0x00230044 4" "0x00230048 4" "0x0023004c 4" \
      "0x00230054 4" "0x00230058 4" "0x0023005c 1" "0x0023005e 1" "0x0023005f 1" \
      "0x00230063 1" "0x00230066 2" "0x00230068 4" "0x0023006c 4" "0x00230070 4" \
      "0x00230080 4" "0x00230084 4" "0x00230094 4" "0x00230098 4" "0x0023009c 4" \
      "0x002300a0 4" "0x002300a4 4" "0x002300a8 4" "0x002300b4 4" "0x0023014c 4" \
      "0x002302d7 1" "0x00240040 4" "0x0024004c 4" "0x00240068 4" "0x0024006c 4" \
      "0x0024009c 4" "0x002400a0 4" "0x002400a4 4" "0x006d3184 4"; do
      echo "read_mem $r"
    done
    echo "trace 0x5b1420 b1420"
    echo "trace 0x5b0040 b0040"
    echo "trace 0x5a89c0 s89c0"
    echo "trace 0x5a8bc0 s8bc0"
    echo "trace 0x5a8f20 s8f20"
    echo "trace 0x5aa4d0 aa4d0"
    echo "trace 0x5aa490 aa490"
    echo "trace 0x5aa870 aa870"
    echo "trace 0x5aa680 aa680"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# All fixtures: P+0x184 -> T, P+0x18c -> M, P+0x190 -> C; rand seed 1.
PTRS="$(poke 0x230184 0x250000);$(poke 0x23018c 0x210000);$(poke 0x230190 0x240000);$(poke 0x6d3184 1)"
# Two-man roster (Q0 on-pitch at (0x70000, 0x10000); Q1 off-pitch): base T+0, count T+4.
ROSTER2="$(poke 0x250000 0x310000);$(poke 0x250004 2);$(poke 0x3102bc 1);$(poke 0x310004 0x70000);$(poke 0x310008 0x10000)"

# name|param_2|pokes  (all windows zeroed first; only nonzero fields poked)
FIX=(
# velocity block only: action 2, +0x48=5 blocks L127, non-active, phase 0 -> non-active velo + wander.
"velobail|0x0|$(poke 0x230040 2);$(poke 0x230048 5)"
# active velocity arms: anchor = |p+0x3a4 + p.x| picks the 3 bands (L53-72 / L107).
"veloact_near|0x0|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x240040 0x230000);$(poke 0x2303a4 0x100000)"
"veloact_mid|0x0|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x240040 0x230000);$(poke 0x2303a4 0x1b0000)"
"veloact_far|0x0|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x240040 0x230000);$(poke 0x2303a4 0x290000)"
# param_2==0 open-play gate (L129-136): b1420 -> B1500 (ball+0x54 != team) / B1C80 stub, ret 1 -> end.
"b1420_b1500|0x0|$(poke 0x230040 2);$(poke 0x240054 1)"
"b1420_b1c80|0x0|$(poke 0x230040 2)"
# param_2==1 arm-1 leaves: non-active b0040; active simple steer (p+0x63=0); chase-return trio.
"arm1_b0040|0x1|$(poke 0x230040 2)"
"arm1_simple|0x1|$(poke 0x230040 2);$(poke 0x240040 0x230000);$(poke 0x211820 0x1400000)"
# chase (p+0x63=1): facing-near quirk (aim=+/-0x8000, s16 diff -0x8000 < 0x38e PASSES) -> handoff.
"chase_pass|0x1|$(poke 0x230040 2);$(poke 0x240040 0x230000);$(poke 0x230063 1);$(poke 0x2303a4 0x100000);$(poke 0x2302bc 1);$(poke 0x211820 0x1400000);ROSTER2"
"chase_nopass|0x1|$(poke 0x230040 2);$(poke 0x240040 0x230000);$(poke 0x230063 1);$(poke 0x2303a4 0x100000);$(poke 0x2302bc 1);$(poke 0x211820 0x1400000)"
"chase_far|0x1|$(poke 0x230040 2);$(poke 0x240040 0x230000);$(poke 0x230063 1);$(poke 0x230034 0x4000);$(poke 0x211820 0x1400000)"
# arm 2 (m+0x440 != 0, phase 0): non-active 8f20/b0040 split; active sideline steer + AA870 tail.
"arm2_8f20|0x1|$(poke 0x230040 2);$(poke 0x210440 0x310000);$(poke 0x240040 0x310000)"
"arm2_b0040|0x1|$(poke 0x230040 2);$(poke 0x210440 0x310000)"
"arm2_aa870|0x1|$(poke 0x230040 2);$(poke 0x210440 0x310000);$(poke 0x240040 0x230000);$(poke 0x230034 0x4000)"
"arm2_steeronly|0x1|$(poke 0x230040 2);$(poke 0x210440 0x310000);$(poke 0x240040 0x230000);$(poke 0x230034 0x2000);$(poke 0x211824 0xd0000)"
# IF-A anim-end (L394-401): wall frame + action 0x35 at last frame (FRAME_COUNT[0x35]=12 -> +0x2c=11).
"ifa_end|0x0|$(poke 0x230040 0x35);$(poke 0x210461 0x40);$(poke 0x23002c 11)"
"ifa_notend|0x0|$(poke 0x230040 0x35);$(poke 0x210461 0x40);$(poke 0x23002c 5)"
# taker phase 2 with a HOLDER (C+0x4c=Q0) -> FUN_005a8bc0 steer + rand + kick_setup (empty roster).
"phase2_holder|0x0|$(poke 0x230040 0);$(poke 0x210448 2);$(poke 0x210438 0x230000);$(poke 0x240040 0x230000);$(poke 0x24004c 0x310000);$(poke 0x310004 0x70000);$(poke 0x310008 0x10000);$(poke 0x2302bc 1)"
# taker phase 4: the full free-kick run-up (mirror target, steer, SIGNED facing + rng gate).
"phase4_taker|0x0|$(poke 0x230040 2);$(poke 0x210448 4);$(poke 0x210438 0x230000);$(poke 0x211820 0x1400000)"
)

: > "$OUT"
echo "# s12: FUN_005a65a0 OPEN-PLAY ground truth (PCode emu; ONLY b1500/b1c80 stubbed ret 1)." >> "$OUT"
echo "# Fixtures mirror test_65a0openplay.gd. Windows: P=0x230000 M=0x210000 C=0x240000 T=0x250000 Q0=0x310000." >> "$OUT"
echo "# Each row: FIX <name> then the verbatim CALL 0 (STUB|RET|HALT) line (tracehits + mem reads)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME P2 POKES <<<"$row"
  POKES="${POKES//ROSTER2/$ROSTER2}"
  POKES="$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$P2" "$POKES"
  run_emu
  echo "## FIX $NAME param2=$P2" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || echo "NO-RESULT" >> "$OUT"
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "[$NAME] $(echo "$S" | grep -oE '(RET|HALT) steps=[0-9]+') 40=$(echo "$S" | grep -oE 'mem\[0x230040:4\]=[0-9-]+' | cut -d= -f2) 54=$(echo "$S" | grep -oE 'mem\[0x230054:4\]=[0-9-]+' | cut -d= -f2) 63=$(echo "$S" | grep -oE 'mem\[0x230063:1\]=[0-9-]+' | cut -d= -f2) $(echo "$S" | grep -oE 'tracehits=\{[^}]*\}' | head -1)"
done
echo "=== 65a0 open-play oracle -> $OUT ==="
