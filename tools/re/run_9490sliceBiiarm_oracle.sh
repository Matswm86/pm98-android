#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE B-ii-b -- the marker-4 APPLY path (action == 5 -> the arm-2 active tail
# FUN_005aa870(1), decompile L274-285 / asm 0x5a9b9f-0x5a9bf9). Marker 4 (MARK9490_ROW=3, MARK9490_ACTION=5,
# MARK9490_ANGLE=0 so the heading gate always passes) is steered to win by putting its grid row 3 at the
# box center and pushing every other marker row FAR. The apply then temp-moves p by the (rotated) offset,
# sets p.facing = local_ec, runs the REAL FUN_005aa870(1) (which draws 2 RNG values + sets the reach point
# p+0xa0/a4/a8, action via FUN_005a5430, p+0x48/0x5e), restores p.pos/facing, and writes the 9490 locomotion
# (p+0x80/84/94/66/98/9c/7c) off the restored pos. ball.vel HIGH so Slice C returns at 0x5aa274 intact.
# RNG seed DAT_006d3184 = 0x4d2 (== test SEED). GROUND TRUTH for Pm98Movement._lean9490_marker_scan_apply
# action==5 branch (app/tests/test_9490sliceB.gd, B-ii-b row).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceBiiarm_oracle.txt
SPEC=$SPECDIR/_9490sliceBiiarm_run.spec
ROUT=$SPECDIR/_9490sliceBiiarm_run.out
LUT=$SPECDIR/_9490sliceBiiarm_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

mk_traj_far() {  # all 16 slots FAR (p.pos=0 -> 0x400000 each axis)
  local s
  for s in $(seq 23 38); do
    printf '%s;%s;%s;' \
      "$(poke $(( 0x280000 + 0xc*s ))     0x400000)" \
      "$(poke $(( 0x280000 + 0xc*s + 4 )) 0x400000)" \
      "$(poke $(( 0x280000 + 0xc*s + 8 )) 0x400000)"
  done
}
set_grid() {  # traj(0x17+row) = V (facing 0, p.pos 0)
  local s=$(( 0x17 + $1 ))
  printf '%s;%s;%s;' \
    "$(poke $(( 0x280000 + 0xc*s ))     $2)" \
    "$(poke $(( 0x280000 + 0xc*s + 4 )) $3)" \
    "$(poke $(( 0x280000 + 0xc*s + 8 )) $4)"
}

# Reach gates + arm-2 tail inputs. p.vel moderate (locomotion), ball.vel HIGH (Slice C early return + the
# half-blend arm2tail reads but does not write at istack 1). ctx via p+0x188 -> 0x2b0000 -> 0x2c0000.
POKES="$(poke2 0x230034 0);$(poke 0x230040 0);$(poke 0x230054 1);$(poke 0x2302bc 1);\
$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2302b8 0);$(poke 0x2303a0 50);$(poke 0x2303a4 0x100000);\
$(poke 0x230020 0x4000);$(poke 0x230024 -0x2000);$(poke 0x230028 0x800);\
$(poke 0x280040 0);$(poke 0x280070 0);$(poke 0x280050 0);$(poke 0x280080 0x1234);$(poke 0x28004c 0);$(poke 0x280044 0);\
$(poke 0x280004 0x10000);$(poke 0x280008 0);$(poke 0x28000c 0);\
$(poke 0x280020 0x400000);$(poke 0x280024 0x400000);$(poke 0x280028 0);\
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 0);$(poke 0x2a0448 0);\
$(poke 0x2b0000 0x2c0000);$(poke 0x2c02b8 0);$(poke 0x2c02c4 0);\
$(mk_traj_far);$(set_grid 3 0x9998 0 0)"

READS="read_mem 0x00230040 4
read_mem 0x002300a0 4
read_mem 0x002300a4 4
read_mem 0x002300a8 4
read_mem 0x00230048 4
read_mem 0x0023005e 1
read_mem 0x00230080 4
read_mem 0x00230084 4
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x00230066 2
read_mem 0x0023007c 4
read_mem 0x0028004c 4
read_mem 0x0028005c 4
read_mem 0x006d3184 4"

{
  cat <<EOF
entry   0x005a9490
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
zero    0x00250000 0x00001000
zero    0x002b0000 0x00001000
zero    0x002c0000 0x00001000
zero    0x00674000 0x00001000
maxsteps 6000000
stub    0x00605ff0 0 0 atexit
EOF
  cat "$LUT"
  printf '%s\n' "$THUNK"
  printf '%s\n' "$(poke 0x230190 0x280000)"
  printf '%s\n' "$(poke 0x23018c 0x2a0000)"
  printf '%s\n' "$(poke 0x230184 0x250000)"
  printf '%s\n' "$(poke 0x230188 0x2b0000)"
  printf '%s\n' "$(poke 0x6d31c4 0)"
  printf '%s\n' "$(poke 0x6d3184 0x4d2)"
  printf '%s\n' "${POKES//;/$'\n'}"
  printf '%s\n' "$READS"
} > "$SPEC"

: > "$ROUT"
"$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
  -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true

: > "$OUT"
echo "# Oracle FUN_005a9490 Slice B-ii-b (marker-4 action==5 arm-2 tail). True entry to the real RET." >> "$OUT"
echo "# Row: B9490iiarm m4 | 0x230040=<action> 0x2300a0=<reachx> ... 0x6d3184=<rng_final> (signed LE)." >> "$OUT"
LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ' || true)
echo "B9490iiarm m4 | $KV" >> "$OUT"
echo "[m4] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+' || true) $KV"
echo "=== 9490 Slice B-ii-b oracle -> $OUT ==="
cat "$OUT"
