#!/usr/bin/env bash
# Stage 3 task 2 (ADVANCE pass): drive the REAL FUN_005a4560 (vtable+0xc, which calls FUN_005ed8e0)
# through the Ghidra PCode emulator and bank the replay record/playback outputs that
# Pm98Movement.advance must reproduce bit-for-bit (app/tests/test_advance.gd).
#
# FUN_005a4560 is PURE replay record/playback (NO physics; the player position +0x4/+0x8/+0xc is set
# by the DECIDE pass). It acts only when the frame ring DAT_006d31bc == 0, and then:
#   * PLAYBACK (DAT_006d31c4 != 0): FUN_005ed8e0 restores the 9-dword MOTION snapshot from
#     *(player+0x38)[DAT_006d31c0*0x24] -> +0x4/+0x8/+0xc, +0x20/+0x24/+0x28, +0x2c, +0x30, +0x34(WORD);
#     then the body restores the 0x51-dword DECIDE state from *(player+0x3b0)[DAT_006d31c0*0x144] ->
#     +0x40..+0x180.
#   * NO-OP otherwise (ring != 0, or live with record off) -- the headless match-outcome path.
# Pure copies: no sub-calls beyond FUN_005ed8e0 (real), NO LUT/RNG/ftol/stubs.
#
# Memory map: player P0 @0x230000, motion buffer @0x254000 (player+0x38), decide-state buffer
# @0x256000 (player+0x3b0). Globals DAT_006d31bc/c0/c4 @0x6d31bc/c0/c4, DAT_00665d8c @0x665d8c.
# Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/advance_oracle.txt
SPEC=$SPECDIR/_advance_run.spec
ROUT=$SPECDIR/_advance_run.out

READS=(
  "0x00230004 4" "0x00230008 4" "0x0023000c 4"              # +0x4/+0x8/+0xc position
  "0x00230020 4" "0x00230024 4" "0x00230028 4"              # +0x20/+0x24/+0x28 velocity
  "0x0023002c 4" "0x00230030 4" "0x00230034 4"              # +0x2c/+0x30 + facing (+0x34 WORD)
  "0x00230040 4" "0x00230044 4" "0x00230180 4"              # +0x40/+0x44/+0x180 decide-state sample
)

emit_spec() {
  {
    cat <<EOF
entry   0x005a4560
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00254000 0x00001000
zero    0x00256000 0x00001000
zero    0x006d3000 0x00001000
zero    0x00665000 0x00001000
maxsteps 200000
mem 0x00230038 4 0x00254000
mem 0x002303b0 4 0x00256000
EOF
    printf '%s\n' "$1"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }
pokeb() { printf 'mem 0x%08x 1 0x%02x' "$1" $(( $2 & 0xff )); }

# Globals: ring=DAT_006d31bc, frame=DAT_006d31c0, playback=DAT_006d31c4, record=DAT_00665d8c.
glob() { echo "$(poke 0x6d31bc $1);$(poke 0x6d31c0 $2);$(pokeb 0x6d31c4 $3);$(pokeb 0x665d8c $4)"; }
# A 9-dword MOTION frame at buffer 0x254000 + frame*0x24 (distinct positive dwords; +0x20 is the facing WORD).
mframe() { local b=$((0x254000 + $1 * 0x24)); echo "$(poke $b 0x11110000);$(poke $((b+4)) 0x22220000);$(poke $((b+8)) 0x33330000);$(poke $((b+0xc)) 0x44440000);$(poke $((b+0x10)) 0x55550000);$(poke $((b+0x14)) 0x66660000);$(poke $((b+0x18)) 0x77770000);$(poke $((b+0x1c)) 0x78880000);$(poke $((b+0x20)) 0x1234)"; }
# A DECIDE-state frame at 0x256000 + frame*0x144: seed first two dwords + the last (i=80, +0x140).
dframe() { local b=$((0x256000 + $1 * 0x144)); echo "$(poke $b 0xa0000001);$(poke $((b+4)) 0xa0000002);$(poke $((b+0x140)) 0xa0000051)"; }
# Player sentinels (to prove NO-OP leaves fields untouched): distinct from any buffer value.
SENT="$(poke 0x230004 0xdead0004);$(poke 0x230008 0xdead0008);$(poke 0x23000c 0xdead000c);$(poke 0x230020 0xdead0020);$(poke 0x230024 0xdead0024);$(poke 0x230028 0xdead0028);$(poke 0x23002c 0xdead002c);$(poke 0x230030 0xdead0030);$(poke 0x230034 0xdead0034);$(poke 0x230040 0xdead0040);$(poke 0x230044 0xdead0044);$(poke 0x230180 0xdead0180)"

FIX=(
# PLAYBACK frame 0: restore motion +0x4../+0x34 + decide-state +0x40/+0x44/+0x180 from frame 0.
"pb_f0|$(glob 0 0 1 0);$(mframe 0);$(dframe 0)"
# PLAYBACK frame 2: validates the frame index (motion stride 0x24, decide stride 0x144).
"pb_f2|$(glob 0 2 1 0);$(mframe 2);$(dframe 2)"
# NO-OP (ring != 0): both buffers seeded but player keeps its sentinels.
"noop_ring|$(glob 1 0 1 0);$(mframe 0);$(dframe 0);$SENT"
# NO-OP (live, record off): no playback, no record -> player keeps its sentinels.
"noop_live|$(glob 0 0 0 0);$(mframe 0);$(dframe 0);$SENT"
)

: > "$OUT"
echo "# Stage 3 task 2 ADVANCE pass (FUN_005a4560 + FUN_005ed8e0, vtable+0xc) PCode-emu ground truth." >> "$OUT"
echo "# PURE replay record/playback; acts only when ring(DAT_006d31bc)==0. PLAYBACK restores the 9-dword" >> "$OUT"
echo "# motion (+0x4../+0x34) from buf@+0x38[frame*0x24] + the 0x51-dword decide state (+0x40..+0x180)" >> "$OUT"
echo "# from buf@+0x3b0[frame*0x144]. NO-OP otherwise. No stubs/LUT. Each row: FIX <name> + verbatim CALL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  4=$(echo "$LINE" | grep -oE 'mem\[0x230004:4\]=[0-9-]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')  180=$(echo "$LINE" | grep -oE 'mem\[0x230180:4\]=[0-9-]+')"
done
echo "=== advance oracle -> $OUT ==="
cat "$OUT"
