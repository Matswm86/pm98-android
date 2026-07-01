#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE C -- the post-scan shot/clear/ball-control TAIL (decompile L339-553 /
# asm 0x5a9d14-0x5aa46d). We drive the REAL FUN_005a9490 from its TRUE entry 0x5a9490 (__fastcall ECX=p)
# with a NON-carrier player whose SCAN-ENTRY gate fails (p+0x54=0), so bVar5=false and the whole tail is
# exercised in isolation (the scan itself is locked by the B-ii oracles). Fixtures, one per arm:
#   clr_far / clr_close / clr_wide : fast ball (planar speed 0x10000 > 6*0x9999/10) -> LAB_005aa274 clear
#       arms; grid row 0 steers the z / |y| / |x| window (FAR tilt+0xa666, CLOSE rot+0x71c7+0x6666,
#       WIDE rot-0xe39+0x8ccc); ONE FUN_005ec250 draw each; tail FUN_0058ed80 transfer.
#   clr_out  : fast ball, row 0 outside the clear window (|x| > 0x4ccc) -> nothing, no draw.
#   chase    : slow ball (0x3000), row 0 FAR (no catch), row 2 inside the chase box, speed >= 0x23d8
#              -> FUN_005a5430(0xb) only (also pins what 5a5430 does to p+0x2c, poked 5).
#   ctl_low  : slow ball, row 0 in the catch box with z < 0xf332 -> engage + pos 0xb + ball-anim over
#              (DAT_00664fe4=9 - p+0x2c)*4 ticks + vel zeroed.
#   ctl_high : slow ball, row 0 z in [0xf332, 0x1e665] -> engage + pos 0xd + 0x34-tick anim + vel zeroed.
#   own62    : ctl_low + ball+0x4c = p, ball+0x44 = p (skip stat swap), ball+0x62 = 1, |p+0x3a4 + p.x|
#              <= 0x24ffff -> ONE commentary draw (299 gate; audio m+0x180b=0) before the engage.
#   foreign62: ctl_low + ball+0x4c = q (opposing team @0x260000), ball+0x62 = 0 -> ONE draw (199 gate).
# ball+0x1d4 -> m is poked (FUN_0058ed80/FUN_0058eca0 take the match from the BALL, not the player).
# RNG seeded at 0x6d3184 = 0x4d2 and read back, pinning the exact draw count per arm.
# GROUND TRUTH for Pm98Movement._lean9490_slice_c / lean_9490(p, true, rng) (app/tests/test_9490sliceC.gd).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceC_oracle.txt
SPEC=$SPECDIR/_9490sliceC_run.spec
ROUT=$SPECDIR/_9490sliceC_run.out
LUT=$SPECDIR/_9490sliceC_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# All 16 trajectory slots ball+0xc*(0x17+j) FAR from p.pos (p @0, so +0x400000 each axis).
mk_traj_far() {
  local s
  for s in $(seq 23 38); do
    printf '%s;%s;%s;' \
      "$(poke $(( 0x280000 + 0xc*s ))     0x400000)" \
      "$(poke $(( 0x280000 + 0xc*s + 4 )) 0x400000)" \
      "$(poke $(( 0x280000 + 0xc*s + 8 )) 0x400000)"
  done
}
set_row() {  # $1=row $2=vx $3=vy $4=vz : traj(0x17+row) = V (p @0, facing 0 => grid[row] = V)
  local s=$(( 0x17 + $1 ))
  printf '%s;%s;%s;' \
    "$(poke $(( 0x280000 + 0xc*s ))     $2)" \
    "$(poke $(( 0x280000 + 0xc*s + 4 )) $3)" \
    "$(poke $(( 0x280000 + 0xc*s + 8 )) $4)"
}

# Common: p @0 facing 0 action 0 timer 5, scan-entry FAIL (p+0x54=0) so bVar5=false, p+0x2bc=1, team 0,
# anchor 0; ball @(0x10000,0,0) heading 0, no carrier/anim-lock, ball+0x80=0x1234; seed 0x4d2.
COMMON_P="$(poke2 0x230034 0);$(poke 0x230040 0);$(poke 0x23002c 5);$(poke 0x230054 0);$(poke 0x2302bc 1);$(poke 0x2302b8 0);$(poke 0x2303a4 0);$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0)"
COMMON_B="$(poke 0x280040 0);$(poke 0x280070 0);$(poke 0x280050 0);$(poke 0x280080 0x1234);$(poke 0x280004 0x10000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke2 0x280034 0);$(poke 0x280044 0);$(poke 0x28004c 0);$(poke2 0x280062 0);$(poke 0x6d3184 0x4d2)"
FAST="$(poke 0x280020 0x10000);$(poke 0x280024 0);$(poke 0x280028 0)"
SLOW="$(poke 0x280020 0x3000);$(poke 0x280024 0);$(poke 0x280028 0)"

FIX=(
  "clr_far|$COMMON_P;$COMMON_B;$FAST;$(mk_traj_far)$(set_row 0 0 0 0x18000)"
  "clr_close|$COMMON_P;$COMMON_B;$FAST;$(mk_traj_far)$(set_row 0 0x1000 0x1000 0x10000)"
  "clr_wide|$COMMON_P;$COMMON_B;$FAST;$(mk_traj_far)$(set_row 0 0x4000 0x6000 0x10000)"
  "clr_out|$COMMON_P;$COMMON_B;$FAST;$(mk_traj_far)$(set_row 0 0x9000 0 0x10000)"
  "chase|$COMMON_P;$COMMON_B;$SLOW;$(mk_traj_far)$(set_row 2 0x4ccc 0 0x8000)"
  "ctl_low|$COMMON_P;$COMMON_B;$SLOW;$(mk_traj_far)$(set_row 0 0x4ccc 0 0x8000)"
  "ctl_high|$COMMON_P;$COMMON_B;$(poke 0x280020 0x1000);$(poke 0x280024 0);$(poke 0x280028 0);$(mk_traj_far)$(set_row 0 0x4ccc 0 0x10000)"
  "own62|$COMMON_P;$COMMON_B;$SLOW;$(poke 0x28004c 0x230000);$(poke 0x280044 0x230000);$(poke2 0x280062 1);$(mk_traj_far)$(set_row 0 0x4ccc 0 0x8000)"
  "foreign62|$COMMON_P;$COMMON_B;$SLOW;$(poke 0x28004c 0x260000);$(poke 0x2602b8 1);$(mk_traj_far)$(set_row 0 0x4ccc 0 0x8000)"
)

# Read back the tail's field writes (p @0x230000, ball @0x280000, m @0x2a0000, LCG @0x6d3184).
READS="read_mem 0x00230040 4
read_mem 0x0023002c 4
read_mem 0x00230054 4
read_mem 0x00280020 4
read_mem 0x00280024 4
read_mem 0x00280028 4
read_mem 0x00280040 4
read_mem 0x00280044 4
read_mem 0x00280048 4
read_mem 0x00280054 4
read_mem 0x00280080 4
read_mem 0x00280068 4
read_mem 0x0028006c 4
read_mem 0x0028009c 4
read_mem 0x002800a0 4
read_mem 0x002800a4 4
read_mem 0x002a0458 4
read_mem 0x006d3184 4"

emit_spec() {  # $1=pokes
  {
    cat <<EOF
entry   0x005a9490
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00001000
zero    0x00280000 0x00001000
zero    0x002a0000 0x00002000
zero    0x00250000 0x00001000
zero    0x002b0000 0x00001000
zero    0x00674000 0x00001000
maxsteps 5000000
stub    0x00605ff0 0 0 atexit
EOF
    cat "$LUT"
    printf '%s\n' "$THUNK"
    printf '%s\n' "$(poke 0x230190 0x280000)"
    printf '%s\n' "$(poke 0x23018c 0x2a0000)"
    printf '%s\n' "$(poke 0x230184 0x250000)"
    printf '%s\n' "$(poke 0x230188 0x2b0000)"
    printf '%s\n' "$(poke 0x2801d4 0x2a0000)"
    printf '%s\n' "$(poke 0x6d31c4 0)"
    printf '%s\n' "${1//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a9490 Slice C (post-scan tail). Driven from true entry to the real RET." >> "$OUT"
echo "# Row: B9490c <name> | 0x230040=<action> ... 0x6d3184=<rng post-state> (signed LE)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ' || true)
  echo "B9490c $NAME | $KV" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+' || true) $KV"
done
echo "=== 9490 Slice C oracle -> $OUT ==="
cat "$OUT"
