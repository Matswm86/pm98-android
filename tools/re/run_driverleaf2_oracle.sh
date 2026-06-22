#!/usr/bin/env bash
# Stage 3 task 2 (match-driver leaves, batch 2): drive four more PURE leaves of the per-tick driver
# FUN_00598740's restart-placement ladder + event-queue gate through the Ghidra PCode emulator and
# bank their effects. Ground truth for Pm98Movement.vec3_set / play_state_eq / clamp_x_goalside /
# restart_box_ok (app/tests/test_driverleaf2.gd).
#
#   FUN_00590aa0(__thiscall out; x, y, z): out[0..2] = x, y, z. Reads back out.
#   FUN_005943b0/f0/d0(__fastcall match): EAX low byte = (match+0x468 -> +0xfa0 == {0,2,4}).
#     (upper 3 bytes are CONCAT31 junk = (session_ptr>>8); the caller reads AL only -> mask & 0xff.)
#   FUN_0059a1e0(__thiscall player; vec, factor): clamp vec.x toward player's goal by 0..50 factor.
#     Reads back vec.x. match = player+0x18c; goalx = match+0x1820; attack dir = player+0x3a4.
#   FUN_0059a120(__thiscall player; vec): EAX = 1 iff vec in the box [match+0x1828..+0x183c] & past
#     abs(x)>goalx-0x108000 & abs(y)<0x1428f5 & sign(x)==sign(player+0x3a4). (clean 0/1 return.)
#
# Memory map: match @0x210000 (+session 0x468->0x216000), player @0x230000, vec @0x230100.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/driverleaf2_oracle.txt
SPEC=$SPECDIR/_driverleaf2_run.spec
ROUT=$SPECDIR/_driverleaf2_run.out

emit_spec() {  # $1 entry, $2 ECX(this), $3 args(space-sep), $4 pokes(';'->nl), $5 reads(space-sep addr)
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $2
zero    0x00210000 0x00008000
zero    0x00230000 0x00002000
EOF
    for a in $3; do printf 'arg 0x%08x\n' $(( a & 0xffffffff )); done
    printf '%s\n' "${4//;/$'\n'}"
    for r in $5; do echo "read_mem $r 4"; done
    echo "maxsteps 100000"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

bank() {  # $1 name $2 entry $3 ecx $4 args $5 pokes $6 reads
  emit_spec "$2" "$3" "$4" "$5" "$6"
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+( EAX=[0-9-]+)?')"
}

# Pointer-chain pokes shared by the player-relative leaves.
PLAYER_MATCH="$(poke 0x23018c 0x210000)"            # player+0x18c -> match@0x210000
# match positioning box + goal line for restart_box_ok (goalx big enough that the line gate bites).
BOX="$(poke 0x211828 -0x200000);$(poke 0x211834 0x200000);$(poke 0x21182c -0x200000);$(poke 0x211838 0x200000);$(poke 0x211830 0);$(poke 0x21183c 0x100000);$(poke 0x211820 0x200000)"
VEC_READ="0x00230100"
PSREADS=""   # play_state: EAX only

: > "$OUT"
echo "# Stage 3 task 2 match-driver leaves batch 2 (vec3_set FUN_00590aa0 + play_state FUN_005943b0/f0/d0" >> "$OUT"
echo "# + clamp_x_goalside FUN_0059a1e0 + restart_box_ok FUN_0059a120). PCode-emu ground truth. match" >> "$OUT"
echo "# @0x210000 (session +0x468->0x216000), player @0x230000, vec @0x230100. play_state EAX masked &0xff." >> "$OUT"

# ---- FUN_00590aa0 (this=out@0x230000; x, y, z) ----
bank vec_set 0x590aa0 0x00230000 "0x11110000 0x22220000 0x33330000" "" "0x00230000 0x00230004 0x00230008"

# ---- FUN_005943b0/f0/d0 (this=match@0x210000); session @0x216000, mode @session+0xfa0 ----
MATCH_SESS="$(poke 0x210468 0x216000)"
bank ps_eq0_T 0x5943b0 0x00210000 "" "$MATCH_SESS;$(poke 0x216fa0 0)" "$PSREADS"
bank ps_eq0_F 0x5943b0 0x00210000 "" "$MATCH_SESS;$(poke 0x216fa0 2)" "$PSREADS"
bank ps_eq2_T 0x5943f0 0x00210000 "" "$MATCH_SESS;$(poke 0x216fa0 2)" "$PSREADS"
bank ps_eq4_T 0x5943d0 0x00210000 "" "$MATCH_SESS;$(poke 0x216fa0 4)" "$PSREADS"

# ---- FUN_0059a1e0 (this=player@0x230000; vec@0x230100, factor) ----
# attack -x (player+0x3a4<0): clamp DOWN; vec.x large -> becomes boundary.
bank clamp_neg 0x59a1e0 0x00230000 "0x230100 0x5f" "$PLAYER_MATCH;$(poke 0x211820 0xb0000);$(poke 0x2303a4 -1);$(poke 0x230100 0x100000);$(poke 0x230104 0);$(poke 0x230108 0)" "$VEC_READ"
# attack +x: clamp UP; vec.x very negative -> becomes boundary.
bank clamp_pos 0x59a1e0 0x00230000 "0x230100 0x5f" "$PLAYER_MATCH;$(poke 0x211820 0xb0000);$(poke 0x2303a4 1);$(poke 0x230100 -0x100000);$(poke 0x230104 0);$(poke 0x230108 0)" "$VEC_READ"
# attack +x, vec.x=0 already past boundary -> unchanged.
bank clamp_no  0x59a1e0 0x00230000 "0x230100 0x5f" "$PLAYER_MATCH;$(poke 0x211820 0xb0000);$(poke 0x2303a4 1);$(poke 0x230100 0);$(poke 0x230104 0);$(poke 0x230108 0)" "$VEC_READ"

# ---- FUN_0059a120 (this=player@0x230000; vec@0x230100) -> EAX clean 0/1 ----
RB_VEC_IN="$(poke 0x230100 0x110000);$(poke 0x230104 0);$(poke 0x230108 0x10000)"
bank rb_same_T   0x59a120 0x00230000 "0x230100" "$PLAYER_MATCH;$BOX;$(poke 0x2303a4 1);$RB_VEC_IN" "$PSREADS"
bank rb_oppside_F 0x59a120 0x00230000 "0x230100" "$PLAYER_MATCH;$BOX;$(poke 0x2303a4 -1);$RB_VEC_IN" "$PSREADS"
bank rb_shallow_F 0x59a120 0x00230000 "0x230100" "$PLAYER_MATCH;$BOX;$(poke 0x2303a4 1);$(poke 0x230100 0xf0000);$(poke 0x230104 0);$(poke 0x230108 0x10000)" "$PSREADS"
bank rb_outbox_F  0x59a120 0x00230000 "0x230100" "$PLAYER_MATCH;$BOX;$(poke 0x2303a4 1);$(poke 0x230100 0x300000);$(poke 0x230104 0);$(poke 0x230108 0x10000)" "$PSREADS"

echo "=== driverleaf2 oracle -> $OUT ==="
cat "$OUT"
