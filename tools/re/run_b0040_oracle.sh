#!/usr/bin/env bash
# Stage 3 (non-active open-play movement core): drive the REAL FUN_005b0040 through the
# Ghidra PCode emulator and bank the exact P (player) field mutations + the computed steer
# TARGET (local_c). GROUND TRUTH that Pm98Movement._move_b0040 must reproduce bit-for-bit
# (app/tests/test_b0040.gd).
#
# FUN_005b0040(p) is the off-ball / non-active positioning routine FUN_005a65a0 routes every
# non-controlling player through (L138 / L208 of the move_dispatch caller). It is PURE INTEGER
# (no FPU): it predicts a ball-interception / marking point and TAIL-CALLS the already-locked
# steering trio FUN_005a89c0(target, 0x5a). So one entry exercises 5b0040's targeting AND the
# whole steer chain; banking P's end state is the end-to-end lock.
#
# ALGORITHM (decompile + asm reconciled; hidden __thiscall dests resolved):
#   local_c   = p.pos - ball.pos                       (590aa0; reused later)
#   local_3c  = polar_vec(0x10000, ball.facing)        (5ee0f0; ball-facing unit)
#   local_24/20 = ball.vel.xy
#   uVar7     = dot16(local_c, local_3c)               (5ee500; initial lead estimate)
#   CARRIER-NEAR (p+0x2bc!=0 && ctrl+0x4c==p): ball too high / inside box -> local_c=ctrl+0x84, steer
#   if ball.vel==0: skip loop (local_c stays p-ball)   else: <=0x12-iter interception refine loop:
#       local_c = local_3c * uVar7  (lead point along facing); angle=atan(p-lead-ctrl);
#       step the lead by edfb0 projection / curve-rate, index a formation marker ctrl+(k+0x17)*0xc,
#       build point [ESP+0x28..] , uVar7 = (dot16(point,local_3c)+uVar7)/2 (bisection)
#   marker-adjust (p+0x2bc!=0): ctrl+0xb0/+0xbc thresholds pick ctrl+0xcc/+0xd8 marker slots
#   local_c = local_3c * uVar7                         (final lead point)
#   local_c = clamp(point, box=m+0x1828)               (5b1330) -> steer_89c0(local_c, 0x5a)
#
# Memory map (zeroed windows): P@0x230000 M@0x210000 ctrl@0x240000 gs@0x250000 OTHER@0x260000.
# local_c lives at stack S+0x64 = 0x307ff0 (sp0=0x308000, fastcall ECX, SUB 0x60 + 4 pushes);
# read AFTER return still shows the clamped target (steer frame is below S, never overwrites it).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b0040_oracle.txt
SPEC=$SPECDIR/_b0040_run.spec
ROUT=$SPECDIR/_b0040_run.out
LUT=$SPECDIR/_b0040_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

P=0x00230000; M=0x00210000; CTRL=0x00240000; GS=0x00250000; OTHER=0x00260000
LOCALC=0x00307ff0    # stack addr of local_c after return (the clamped steer target)

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# Banked fields: P pos/vel/facing/yaw/action/speed/curve/counters + local_c target.
READS="
read_mem 0x00230004 4
read_mem 0x00230008 4
read_mem 0x0023000c 4
read_mem 0x00230020 4
read_mem 0x00230024 4
read_mem 0x00230028 4
read_mem 0x00230034 4
read_mem 0x00230064 4
read_mem 0x00230068 4
read_mem 0x0023006c 4
read_mem 0x00230090 4
read_mem 0x00307ff0 4
read_mem 0x00307ff4 4
read_mem 0x00307ff8 4
"

# emit_spec PHASE ACTIVE CARRYFLAG OTHERCTL  PX PY  BX BY BZ  BVX BVY  BFACE
emit_spec() {
  local phase=$1 active=$2 carry=$3 octl=$4 px=$5 py=$6 bx=$7 by=$8 bz=$9 bvx=${10} bvy=${11} bface=${12}
  {
    echo "entry   0x5b0040"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P"                       # __fastcall: p in ECX, no stack args
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "mem 0x006233a4 4 0x00252000"
    echo "stub 0x00605ff0 0 0 atexit"           # 8bc0 lazy box-init atexit fault (steering tail)
    echo "maxsteps 8000000"
    cat "$LUT"
    echo "zero    0x00230000 0x00000400"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00240000 0x00000400"
    echo "zero    0x00250000 0x00000400"
    echo "zero    0x00260000 0x00000400"
    poke 0x00230184 $GS
    poke 0x0023018c $M
    poke 0x00230190 $CTRL
    poke 0x00230004 "$px"          # p.x
    poke 0x00230008 "$py"          # p.y
    poke 0x0023000c 0              # p.z
    poke 0x00230070 15000          # curve numerator a
    poke 0x002303ac 65536          # curve numerator b
    poke 0x002303a8 0              # curve bias
    poke 0x00230388 0x4000         # ftol/steer gate scale
    poke 0x002302bc "$carry"       # P+0x2bc carrier flag (p+700)
    poke 0x00210448 "$phase"       # M+0x448 phase
    poke 0x00210461 0              # M+0x461 wall flag clear
    poke 0x00211970 0x7f000000     # pitch extent x
    poke 0x00211978 0x7f000000     # pitch extent y
    # clamp box m+0x1828 (lo .. hi) wide -> no clamp
    poke 0x00211828 -0x10000000; poke 0x0021182c -0x10000000; poke 0x00211830 -0x10000000
    poke 0x00211834 0x10000000;  poke 0x00211838 0x10000000;  poke 0x0021183c 0x10000000
    poke 0x00240040 "$active"      # ctrl+0x40 active-player ref
    poke 0x0024004c "$octl"        # ctrl+0x4c other-control slot
    poke 0x00240004 "$bx"          # ball x
    poke 0x00240008 "$by"          # ball y
    poke 0x0024000c "$bz"          # ball z
    poke 0x00240020 "$bvx"         # ball vel x
    poke 0x00240024 "$bvy"         # ball vel y
    poke 0x00240028 0              # ball vel z
    poke 0x00240034 "$bface"       # ball facing
    poke 0x00240084 0x60000        # ctrl+0x84 carrier-target point (x,y,z)
    poke 0x00240088 0x20000
    poke 0x0024008c 0
    # formation marker-adjust slots (only consulted when p+0x2bc!=0 on the common path)
    poke 0x002400b0 0x30000        # ctrl+0xb0 threshold (>0x2cccc -> 1st marker active)
    poke 0x002400bc 0              # ctrl+0xbc threshold (<0x2cccc -> 2nd marker skipped)
    poke 0x002400cc 0x50000        # ctrl+0xcc/d0/d4 marker A (x,y,z)
    poke 0x002400d0 0x10000
    poke 0x002400d4 0
    poke 0x002400d8 0x40000        # ctrl+0xd8/dc/e0 marker B (x,y,z)
    poke 0x002400dc 0x18000
    poke 0x002400e0 0
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
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  echo "FIX $name | $kv" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 non-active movement core (FUN_005b0040 -> steer trio) PCode-emu ground truth." >> "$OUT"
echo "# Row: FIX <name> | <abs-addr>=<u32 LE> ... . P=0x230000; local_c(target)@0x307fe4." >> "$OUT"
echo "# P fields +4/8/c pos +20/24/28 vel +34 facing +64 yaw +68 speed +6c curve +90 flip." >> "$OUT"

#         PHASE ACTIVE   CARRY OCTL  PX       PY       BX      BY      BZ       BVX     BVY     BFACE
emit_spec  0    "$OTHER" 0     0     0x60000  0x10000  0       0       0        0       0       0;       run_emu; bank stationary
emit_spec  0    "$OTHER" 0     0     0x60000  0x10000  0       0       0        0x4000  0x2000  0x2000;  run_emu; bank intercept
emit_spec  0    "$P"     1     $P    0x60000  0x10000  0x1000  0       0x20000  0       0       0;       run_emu; bank carriernear
emit_spec  0    "$OTHER" 1     0     0x60000  0x10000  0       0       0        0x4000  0x2000  0x2000;  run_emu; bank markeradj

echo "=== b0040 oracle -> $OUT ==="
cat "$OUT"
