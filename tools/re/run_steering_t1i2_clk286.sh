#!/usr/bin/env bash
# One-off M5 s46 discriminator: drive the REAL FUN_005a89c0 steering chain on the EXACT
# t1.i2 clk-286 inputs (capture2 seed 0xea0d2a8d) where port face lands 0x7b3c but silicon
# lands 0x7b3d from a byte-identical clk-285 state (docs/re/M5_S45_CTRL_MIRROR_DESIGNATION.md
# NEXT-step). Inputs snapshotted by the diag-only block in Pm98Movement.steer_89c0
# (app/tests/diag_m5_t1i2_clk287.gd, t=311 row): pos (768985,-895007,0) face/yaw 0x7b19
# spd -4040 cur-in 0 p70 12869 p3ac 2834 p3a8 4398 p388 81 p90 27 p5c 0 gs2ee 0 phase 0
# m461 0 ball (-592842,-443043,1201) carrier=false m43c!=P; target (858960,-905589,600)
# scale 90. Expected flow: curve=+6585 (89c0 formula), 8bc0 boxes all skip, heading=
# atan_angle(89975,-10582), FLIP (-0x8000, curve->-6585, p90->28), 8f20 steps=1 ->
# face=heading. VERDICT on P+0x34: 0x7b3d -> port 8bc0/8f20/atan input-class bug (fix
# directly); 0x7b3c -> silicon target differs -> drill b1500's mark-point computation.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/steering_t1i2_clk286.txt
SPEC=$SPECDIR/_steering_t1i2.spec
ROUT=$SPECDIR/_steering_t1i2.out
LUT=$SPECDIR/_steering_t1i2_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

P=0x00230000; M=0x00210000; CTRL=0x00240000; GS=0x00250000
TGT=0x00270000; OTHER=0x00260000

poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

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
"

{
  echo "entry   0x5a89c0"
  echo "ret     0x00100000"
  echo "stack   0x00300000 0x00010000 0x00308000"
  echo "reg     ECX $P"
  echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
  echo "mem 0x006233a4 4 0x00252000"
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
  # --- t1.i2 clk-286 live P state (diag t=311 snapshot) ---
  poke 0x00230004 768985          # P.x
  poke 0x00230008 -895007         # P.y
  poke 0x0023000c 0               # P.z
  poke 0x00230034 0x7b19          # facing
  poke 0x00230064 0x7b19          # yaw
  poke 0x00230068 -4040           # speed
  poke 0x0023006c 0               # curve-in (89c0 recomputes)
  poke 0x00230070 12869           # P+0x70 curve-formula numerator a (live, stamina-decayed)
  poke 0x002303ac 2834            # P+0x3ac curve-formula numerator b
  poke 0x002303a8 4398            # P+0x3a8 curve-formula bias
  poke 0x00230388 81              # P+0x388 ftol/steer threshold scale
  poke 0x00230090 27              # P+0x90 flip counter
  poke 0x0023002c 7               # P+0x2c
  poke 0x00230030 2               # P+0x30
  # --- match / ball ---
  poke 0x00210448 0               # M+0x448 phase
  poke 0x00210461 0               # M+0x461 wall flag
  poke 0x00211970 0x7f000000      # pitch extent x
  poke 0x00211978 0x7f000000      # pitch extent y
  poke 0x00240040 $OTHER          # ctrl+0x40 active = NOT P (t0.i8 carries)
  poke 0x00240004 -592842         # ball x (mid-tick, at the steer call)
  poke 0x00240008 -443043         # ball y
  poke 0x0024000c 1201            # ball z
  poke 0x00240020 984             # ball vel (unused on non-carrier path)
  poke 0x00240024 -5895
  poke 0x00240028 -463
  poke 0x00270000 858960          # target x
  poke 0x00270004 -905589         # target y
  poke 0x00270008 600             # target z
  echo "arg $TGT"
  echo "arg 0x5a"                 # speed_scale 90
  printf '%s\n' "$READS"
} > "$SPEC"

: > "$ROUT"
"$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
  -scriptPath tools/re/ghidra_scripts \
  -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true

: > "$OUT"
echo "# M5 s46 one-off: FUN_005a89c0 on the exact t1.i2 clk-286 inputs (port=0x7b3c vs silicon=0x7b3d)." >> "$OUT"
line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
echo "FIX t1i2_clk286 | $kv" >> "$OUT"
echo "[t1i2_clk286] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
cat "$OUT"
face=$(echo "$kv" | grep -oE '0x00230034=[0-9-]+' | cut -d= -f2)
printf 'PCode face P+0x34 = %d (0x%04x)  [port 0x7b3c=31548, silicon 0x7b3d=31549]\n' "$face" "$((face & 0xffff))"
