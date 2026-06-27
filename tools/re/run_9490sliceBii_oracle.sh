#!/usr/bin/env bash
# Oracle for FUN_005a9490 SLICE B-ii -- the off-ball 5-marker SCAN + APPLY (decompile L228-338 / asm
# 0x5a9a17-0x5a9d0e). We drive the REAL FUN_005a9490 from its TRUE entry 0x5a9490 (__fastcall ECX = p)
# with a NON-carrier player that reaches the scan, then read back the apply field writes at the REAL RET.
# To keep the apply writes intact we set the ball velocity HIGH so the Slice-C shot/clear tail takes its
# early return at 0x5aa274 (the `(threshold) < ball_speed` branch) instead of touching p again. Each fixture
# steers exactly ONE marker into its box (the 16 trajectory slots are FAR by default; one row is set to that
# marker's box center) so we exercise: flag-0 box (m0), the 0x19->0x1a action remap (m2), the flag-1
# goalbox+sign branch (m3), and the no-marker case (none). Marker 4 (action 5 -> arm2 tail) is deferred to
# B-ii-b, so this oracle never reaches it. Facing 0 => identity rotation, so grid[row] == traj(0x17+row)-p.
# GROUND TRUTH for Pm98Movement._lean9490_marker_scan_apply (app/tests/test_9490sliceB.gd, B-ii rows).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/9490sliceBii_oracle.txt
SPEC=$SPECDIR/_9490sliceBii_run.spec
ROUT=$SPECDIR/_9490sliceBii_run.out
LUT=$SPECDIR/_9490sliceBii_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke()  { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
poke2() { printf 'mem 0x%08x 2 0x%04x\n' "$1" $(( $2 & 0xffff )); }

THUNK="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# All 16 trajectory slots ball+0xc*(0x17+j) FAR from p.pos (p + 0x400000 each axis) -> every box fails.
mk_traj_far() {  # $1=px $2=py $3=pz
  local px=$1 py=$2 pz=$3 s
  for s in $(seq 23 38); do
    printf '%s;%s;%s;' \
      "$(poke $(( 0x280000 + 0xc*s ))     $(( px + 0x400000 )))" \
      "$(poke $(( 0x280000 + 0xc*s + 4 )) $(( py + 0x400000 )))" \
      "$(poke $(( 0x280000 + 0xc*s + 8 )) $(( pz + 0x400000 )))"
  done
}
set_grid() {  # $1=px $2=py $3=pz $4=row $5=vx $6=vy $7=vz : traj(0x17+row) = p + V (facing 0 => grid[row]=V)
  local s=$(( 0x17 + $4 ))
  printf '%s;%s;%s;' \
    "$(poke $(( 0x280000 + 0xc*s ))     $(( $1 + $5 )))" \
    "$(poke $(( 0x280000 + 0xc*s + 4 )) $(( $2 + $6 )))" \
    "$(poke $(( 0x280000 + 0xc*s + 8 )) $(( $3 + $7 )))"
}

# Common: facing 0, scan gates set (p+0x54=1, p+0x2bc=1, action 0), ball no-carrier/no-anim, ball.vel high,
# ball+0x50=0 (skip stat), ball+0x80=0x1234 (-> p+0x7c). Per fixture: p.pos/anchor/team, m goalx/orient/AABB,
# ball.pos, ball+0x4c/0x44, and the marker row override.
COMMON_P="$(poke2 0x230034 0);$(poke 0x230040 0);$(poke 0x230054 1);$(poke 0x2302bc 1)"
COMMON_B="$(poke 0x280040 0);$(poke 0x280070 0);$(poke 0x280020 0x400000);$(poke 0x280024 0x400000);$(poke 0x280028 0);$(poke 0x280050 0);$(poke 0x280080 0x1234)"

FIX=(
  # m0: row 9 = center0 [0x17fff,0,0x1e147]; flag0 box passes. action 0x14. ball+0x4c=p -> bookkeeping
  #     (ball+0x4c=0, ball+0x5c = 9*4+1 = 0x25). p.pos 0, ball.pos near, goalx +0x100000 orient 0 team 0
  #     (goal AHEAD -> e8 ~ 0, heading passes). ball+0x80=0x1234 -> p+0x7c.
  "m0|$COMMON_P;$COMMON_B;$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 0x100000);$(poke 0x2302b8 0);$(poke 0x2a19a0 0);$(poke 0x2a1820 0x100000);$(poke 0x280004 0x10000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x28004c 0x230000);$(poke 0x280044 0);$(mk_traj_far 0 0 0);$(set_grid 0 0 0 9 0x17fff 0 0x1e147)"
  # m2: row 4 = center2 [0x9998,0,0xb333]; m0/m1 far/flag-fail. orient 1 team 0 -> e8 >= 0 -> action 0x19.
  "m2|$COMMON_P;$COMMON_B;$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 0x100000);$(poke 0x2302b8 0);$(poke 0x2a19a0 1);$(poke 0x2a1820 0x100000);$(poke 0x280004 0x8000);$(poke 0x280008 0x60000);$(poke 0x28000c 0);$(poke 0x28004c 0);$(poke 0x280044 0);$(mk_traj_far 0 0 0);$(set_grid 0 0 0 4 0x9998 0 0xb333)"
  # m2neg: same marker 2, team 1 -> goal not negated, ball heading positive -> e8 < 0 -> action 0x19 remaps
  #        to 0x1a. Exercises the e8<0 path (action remap AND, since angle[2]>0, ec NOT facing-overridden).
  "m2neg|$COMMON_P;$COMMON_B;$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 0x100000);$(poke 0x2302b8 1);$(poke 0x2a19a0 1);$(poke 0x2a1820 0x100000);$(poke 0x280004 0x8000);$(poke 0x280008 0x60000);$(poke 0x28000c 0);$(poke 0x28004c 0);$(poke 0x280044 0);$(mk_traj_far 0 0 0);$(set_grid 0 0 0 4 0x9998 0 0xb333)"
  # m3: flag1 -> needs _ps_goalbox(p.pos) AND sign(p.x) != sign(anchor). p.x +0x200000, anchor -1, goal AABB
  #     wide, goalx +0x280000 orient 0 (goal AHEAD so e8 ~ 0). m0/m1/m2 rows far; row 6 = center3. action 0x16.
  "m3|$COMMON_P;$COMMON_B;$(poke 0x230004 0x200000);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 -1);$(poke 0x2302b8 0);$(poke 0x2a19a0 0);$(poke 0x2a1820 0x280000);$(poke 0x2a1828 0);$(poke 0x2a1834 0x300000);$(poke 0x2a182c -0x80000);$(poke 0x2a1838 0x80000);$(poke 0x2a1830 -0x80000);$(poke 0x2a183c 0x80000);$(poke 0x280004 0x210000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x28004c 0);$(poke 0x280044 0);$(mk_traj_far 0x200000 0 0);$(set_grid 0x200000 0 0 6 0x2b332 0 0xcccc)"
  # none: every row far, anchor sign == p.x sign (flag gate fails) -> no marker applies. p+0x80 stays 0.
  "none|$COMMON_P;$COMMON_B;$(poke 0x230004 0);$(poke 0x230008 0);$(poke 0x23000c 0);$(poke 0x2303a4 0);$(poke 0x2302b8 0);$(poke 0x2a19a0 1);$(poke 0x2a1820 0x100000);$(poke 0x280004 0x10000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x28004c 0);$(poke 0x280044 0);$(mk_traj_far 0 0 0)"
)

# Read back the apply field writes (p @0x230000, ball @0x280000).
READS="read_mem 0x00230040 4
read_mem 0x00230080 4
read_mem 0x00230084 4
read_mem 0x00230094 4
read_mem 0x00230098 4
read_mem 0x0023009c 4
read_mem 0x00230066 2
read_mem 0x0023007c 4
read_mem 0x0028004c 4
read_mem 0x0028005c 4"

emit_spec() {  # $1=pokes
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
echo "# Oracle FUN_005a9490 Slice B-ii (marker scan + apply). Driven from true entry to the real RET." >> "$OUT"
echo "# Row: B9490ii <name> | 0x230040=<action> 0x230080=<p80> ... 0x28005c=<ball5c> (signed LE)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1 || true)
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:[0-9]+\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):[0-9]+\]=/\1=/' | tr '\n' ' ' || true)
  echo "B9490ii $NAME | $KV" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+' || true) $KV"
done
echo "=== 9490 Slice B-ii oracle -> $OUT ==="
cat "$OUT"
