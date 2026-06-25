#!/usr/bin/env bash
# Stage 3 (open-play steering trio): drive the REAL ball-holder steering dispatcher
# FUN_005a89c0 -> FUN_005a8bc0 -> FUN_005a8f20 through the Ghidra PCode emulator and
# bank the exact P (player) and ctrl (ball/controller) field mutations. GROUND TRUTH
# that Pm98Movement.steer_89c0 / steer_8bc0 / steer_8f20 must reproduce bit-for-bit
# (app/tests/test_steering.gd).
#
# WHY 89c0 IS THE WHOLE CHAIN: FUN_005a89c0(P, target_pos, speed_scale) sets the curve
# param P+0x6c (park=0, or the (P+0x70*P+0x3ac)/15000 * scale/100 + P+0x3a8 formula) and
# tail-calls FUN_005a8bc0(target_pos), which computes the steer heading (with the
# +/-0xccc arrive boxes + the +/-0x20000 curve-flip) and tail-calls FUN_005a8f20(heading):
# the FPU steering APPLY (turn facing, ramp speed P+0x68 toward P+0x6c, integrate velocity
# into P.pos, ball-carrier advance, set_position_code by speed bucket). One entry exercises
# all three. Field map decompile-verified in handoff-pm98-ee7c0-tilt-leaf-steering-trio.
#
# FPU/LUT: 8f20 uses ONE ftol(sqrt(.)) (the carrier marker->ball distance gate+scale) plus
# the cos/atan LUTs (polar_vec/atan_angle/rotate/tilt). The faithful truncating _ftol is
# injected at 0x252000 and the IAT thunk 0x6233a4 repointed (same trick as moveleaf). The
# `carrier` fixture is built so that ftol distance is a PERFECT SQUARE (marker=(P.x+0x4ccc,
# P.y,P.z) with facing=0; ball-marker = 0x30000,0x40000,0 -> dist 0x50000) so x87 fsqrt+ftol
# and GDScript int(sqrt()) agree exactly. All other math is integer LUT/fixed-point.
#
# Memory map (zeroed struct windows): P@0x230000 M@0x210000 ctrl@0x240000 gs@0x250000
# TGT@0x270000 OTHER@0x260000 (a 2nd player = ctrl.active for the non-carrier fixtures).
# Links: P+0x184->gs, P+0x18c->M, P+0x190->ctrl, ctrl+0x40->active. M+0x448 phase,
# M+0x461 wall flag, M+0x1970/+0x1978 pitch extents (huge -> integrate never bounds-rejects).
# Curve formula inputs: P+0x70, P+0x3ac, P+0x3a8. ftol gate scale: P+0x388.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/steering_oracle.txt
SPEC=$SPECDIR/_steering_run.spec
ROUT=$SPECDIR/_steering_run.out
LUT=$SPECDIR/_steering_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

P=0x00230000; M=0x00210000; CTRL=0x00240000; GS=0x00250000
TGT=0x00270000; OTHER=0x00260000

# LE-int32 poke of a possibly-negative decimal -> a `mem` directive line.
poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

# All P/ctrl fields captured after each call (absolute addrs in the emulator).
READS="
read_mem 0x00230004 4
read_mem 0x00230008 4
read_mem 0x0023000c 4
read_mem 0x00230020 4
read_mem 0x00230024 4
read_mem 0x00230028 4
read_mem 0x00230034 4
read_mem 0x00230040 4
read_mem 0x00230064 4
read_mem 0x00230068 4
read_mem 0x0023006c 4
read_mem 0x00230090 4
read_mem 0x0023002c 4
read_mem 0x00230030 4
read_mem 0x00240004 4
read_mem 0x00240008 4
read_mem 0x0024000c 4
read_mem 0x00240020 4
read_mem 0x00240024 4
read_mem 0x00240028 4
read_mem 0x00240068 4
read_mem 0x0024006c 4
"

# emit_spec PHASE ACTIVE TX TY TZ P388 CX CY CZ M461 SCALE
emit_spec() {
  local phase=$1 active=$2 tx=$3 ty=$4 tz=$5 p388=$6 cx=$7 cy=$8 cz=$9 m461=${10} scale=${11}
  {
    echo "entry   0x5a89c0"
    echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $P"
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "mem 0x006233a4 4 0x00252000"
    # 8bc0's lazy box-init registers an atexit destructor via FUN_00605ff0 -> FUN_00605fc0
    # (runtime-init helper that faults under the emu). The +/-0xccc / +/-0x20000 box DAT
    # globals are written BEFORE this call, so stubbing it (return 0, cdecl, caller-clean)
    # is behavior-preserving for the steering math.
    echo "stub 0x00605ff0 0 0 atexit"
    echo "maxsteps 4000000"
    cat "$LUT"
    echo "zero    0x00230000 0x00000400"
    echo "zero    0x00210000 0x00002000"
    echo "zero    0x00240000 0x00000400"
    echo "zero    0x00250000 0x00000400"
    echo "zero    0x00270000 0x00000010"
    echo "zero    0x00260000 0x00000400"
    poke 0x00230184 $GS
    poke 0x0023018c $M
    poke 0x00230190 $CTRL
    poke 0x00230070 15000          # P+0x70 curve-formula numerator a
    poke 0x002303ac 65536          # P+0x3ac curve-formula numerator b (0x10000)
    poke 0x002303a8 0              # P+0x3a8 curve-formula bias
    poke 0x00230388 "$p388"        # P+0x388 ftol/steer threshold scale
    poke 0x00210448 "$phase"       # M+0x448 phase
    poke 0x00210461 "$m461"        # M+0x461 wall flag byte
    poke 0x00211970 0x7f000000     # M+0x1970 pitch extent x
    poke 0x00211978 0x7f000000     # M+0x1978 pitch extent y
    poke 0x00240040 "$active"      # ctrl+0x40 active-player ref
    poke 0x00240004 "$cx"          # ctrl+0x4 ball x
    poke 0x00240008 "$cy"          # ctrl+0x8 ball y
    poke 0x0024000c "$cz"          # ctrl+0xc ball z
    poke 0x00270000 "$tx"          # target_pos x
    poke 0x00270004 "$ty"          # target_pos y
    poke 0x00270008 "$tz"          # target_pos z
    echo "arg $TGT"                            # arg0 = target_pos pointer
    printf 'arg 0x%x\n' "$scale"               # arg1 = speed_scale (PcodeEmu `arg` is HEX)
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# bank NAME : emit a `FIX <name> | <addr>=<u32> ...` row from the read_mem dump.
bank() {
  local name=$1 line
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  local kv
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  echo "FIX $name | $kv" >> "$OUT"
  echo "[$name] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 open-play steering trio (FUN_005a89c0/8bc0/8f20) PCode-emu ground truth." >> "$OUT"
echo "# Row: FIX <name> | <abs-addr>=<u32 LE> ... . P=0x230000 ctrl=0x240000. faithful _ftol" >> "$OUT"
echo "# @0x252000 + cos/atan LUT injected. Fields: P +4/8/c pos +20/24/28 vel +34 facing +40" >> "$OUT"
echo "# action +64 yaw +68 speed +6c curve +90 counter +2c/+30; ctrl +4/8/c ballpos +20/24/28 +68 +6c." >> "$OUT"

#        NAME      PHASE ACTIVE   TX        TY       TZ  P388     CX        CY       CZ  M461 SCALE
emit_spec  2     "$OTHER" 0x80000   0x10000  0   0x4000   0         0        0   0    100; run_emu; bank park
emit_spec  0     "$OTHER" 0x80000   0x10000  0   0x4000   0         0        0   0    100; run_emu; bank steer
emit_spec  0     "$P"     0x80000   0x10000  0   0x4000   0x34ccc   0x40000  0   0    100; run_emu; bank carrier
emit_spec  0     "$OTHER" 0         0        0   0x4000   0         0        0   0    100; run_emu; bank arrived
emit_spec  0     "$OTHER" -98304    0        0   0x4000   0         0        0   0    100; run_emu; bank flip
emit_spec  0     "$OTHER" 0x500     0x300    0   0x4000   0x80000   0x10000  0   0    100; run_emu; bank retarget

echo "=== steering oracle -> $OUT ==="
cat "$OUT"
