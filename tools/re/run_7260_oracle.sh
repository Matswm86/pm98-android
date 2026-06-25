#!/usr/bin/env bash
# Stage 3 (ball-touch decision, slice 1): drive the REAL FUN_005a7260 through the Ghidra PCode emulator
# and bank the post-call PLAYER + BALL field mutations that Pm98Movement.ball_touch_7260 must reproduce
# bit-for-bit (app/tests/test_7260.gd).
#
# FUN_005a7260(p) is the per-tick BALL-TOUCH / dribble / pass / shot DECISION engine_tick runs at
# LAB_005a4e5b. Slice 1 = L63-176: the same-side test (FUN_0058fb50 + sign gate), the NOT-same-side
# GOAL-ANCHOR steer (steer_89c0([+/-goalx,0,0],0x5a)), and the CARRIER ball-drag (release ball + pull it
# back polar(0x6666, facing)). The dribble-grid + execute-kick blocks (L177-668) are DEFERRED; the
# fixtures here stay not-same-side so the binary never enters them (no lazy-init / atexit marker grids).
#
# Fixtures (all NOT-same-side: P.x > 0 with P+0x3a4 < 0, so sign(P.x) != sign(P+0x3a4)):
#   goalanchor    : not the carrier (ball+0x40 = OTHER). Far goal anchor -> the steer integrates; verifies
#                   the goalx team-mirror + the 7260->steer wiring. Ball is untouched.
#   carrier_drag  : the carrier (ball+0x40 = P), engage-guard CLEAR (ball+0x63 = 0). Steer arrives early
#                   (target ~= P, facing unchanged) so the ONLY ball write is the drag: ball+0x40 -> 0
#                   (FUN_0058ed70) then ball.pos -= polar(0x6666, facing).
#   carrier_guard : the carrier, engage-guard SET (ball+0x63 = 1). FUN_0058f100 returns nonzero so the &&
#                   short-circuits -> NO drag (ball+0x40 stays P, ball.pos unchanged); its SIDE EFFECT
#                   copies the engaged player's pos into ball+0x90/94/98 (m+0x448 == 0).
#
# Memory map (zeroed windows): P@0x230000 M@0x210000 ball@0x240000 (p+0x190="+400") GS@0x250000 OTHER@0x260000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260_oracle.txt
SPEC=$SPECDIR/_7260_run.spec
ROUT=$SPECDIR/_7260_run.out
LUT=$SPECDIR/_7260_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8 (steer + facing turn)

P=0x00230000; M=0x00210000; BALL=0x00240000; GS=0x00250000; OTHER=0x00260000

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# Banked fields: P pos/vel/facing/yaw/speed/curve/flip + ball carrier/pos/guard/copy + m ballpark scalar.
READS="
read_mem 0x00230004 4
read_mem 0x00230008 4
read_mem 0x0023000c 4
read_mem 0x00230020 4
read_mem 0x00230024 4
read_mem 0x00230028 4
read_mem 0x00230034 2
read_mem 0x00230064 4
read_mem 0x00230068 4
read_mem 0x0023006c 4
read_mem 0x00230090 4
read_mem 0x00240040 4
read_mem 0x00240004 4
read_mem 0x00240008 4
read_mem 0x0024000c 4
read_mem 0x00240063 1
read_mem 0x00240090 4
read_mem 0x00240094 4
read_mem 0x00240098 4
read_mem 0x002119dc 4
"

# emit_spec ACTION P48 PX PY P3A4 FACING CARRIER GUARD GOALX1820 BX BY BZ
emit_spec() {
  local action=$1 p48=$2 px=$3 py=$4 p3a4=$5 facing=$6 carrier=$7 guard=$8 goalx=$9 bx=${10} by=${11} bz=${12}
  {
    echo "entry   0x5a7260"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P"                       # __fastcall: p in ECX
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "mem 0x006233a4 4 0x00252000"          # FPU ftol thunk (steer integrator)
    echo "stub 0x00605ff0 0 0 atexit"           # steer box-init atexit (FUN_00605ff0) fault guard
    echo "maxsteps 8000000"
    cat "$LUT"
    echo "zero    0x00230000 0x00000400"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00240000 0x00000400"
    echo "zero    0x00250000 0x00000400"
    echo "zero    0x00260000 0x00000400"
    echo "zero    0x00674000 0x00001000"        # lazy-init marker grids (safety; not-same-side never enters)
    poke 0x00230184 $GS
    poke 0x0023018c $M
    poke 0x00230190 $BALL
    poke 0x00230040 "$action"      # P+0x40 action code
    poke 0x00230048 "$p48"         # P+0x48
    poke 0x00230004 "$px"          # p.x
    poke 0x00230008 "$py"          # p.y
    poke 0x0023000c 0              # p.z
    poke 0x002303a4 "$p3a4"        # P+0x3a4 side anchor (sign vs p.x = same-side gate)
    poke 0x00230034 "$facing"      # P+0x34 facing WORD
    poke 0x00230070 15000          # curve numerator a
    poke 0x002303ac 65536          # curve numerator b
    poke 0x002303a8 0              # curve bias
    poke 0x00230388 0x4000         # ftol/steer gate scale
    poke 0x002302b8 0              # P+0x2b8 team (vs m+0x19a0 bit -> goalx mirror)
    poke 0x00210448 0              # M+0x448 phase 0 (live)
    poke 0x00210461 0              # M+0x461 wall flag clear
    poke 0x002119a0 0              # M+0x19a0 orient bit (0 -> goalx mirror when ==p+0x2b8)
    poke 0x00211820 "$goalx"       # M+0x1820 goal-X scale
    poke 0x00211970 0x7f000000     # pitch extent x
    poke 0x00211978 0x7f000000     # pitch extent y
    # goal box m+0x1828.. wide so FUN_0058fb50's box-check never gates (the sign test drives same-side)
    poke 0x00211828 -0x10000000; poke 0x0021182c -0x10000000; poke 0x00211830 -0x10000000
    poke 0x00211834 0x10000000;  poke 0x00211838 0x10000000;  poke 0x0021183c 0x10000000
    poke 0x00240040 "$carrier"     # ball+0x40 carrier ref (P or OTHER)
    poke 0x00240063 "$guard"       # ball+0x63 engage-copy guard (FUN_0058f100 return)
    poke 0x00240004 "$bx"          # ball x
    poke 0x00240008 "$by"          # ball y
    poke 0x0024000c "$bz"          # ball z
    poke 0x00240020 0              # ball vel x
    poke 0x00240024 0              # ball vel y
    poke 0x00240028 0              # ball vel z
    poke 0x00240034 0              # ball facing
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {
  local name=$1 line kv
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ')
  echo "FIX $name | $kv" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 ball-touch slice-1 (FUN_005a7260 L63-176) PCode-emu ground truth." >> "$OUT"
echo "# Row: FIX <name> | <abs-addr>=<u LE> ... . P=0x230000 ball=0x240000 m=0x210000." >> "$OUT"

#         ACTION P48 PX       PY       P3A4 FACING  CARRIER  GUARD GOALX1820  BX       BY      BZ
emit_spec 2      5   0x60000  0        -1   0x2000  $OTHER   0     0x200000   0        0       0;      run_emu; bank goalanchor
emit_spec 2      5   0x500    0        -1   0x2000  $P       0     0          0x500    0x100   0;      run_emu; bank carrier_drag
emit_spec 2      5   0x500    0        -1   0x2000  $P       1     0          0x500    0x100   0;      run_emu; bank carrier_guard

echo "=== 7260 oracle -> $OUT ==="
cat "$OUT"
