#!/usr/bin/env bash
# Stage 3 (POSITIONAL port, Task #7): drive the REAL FUN_005a50c0 (tick_action -- the per-player
# action/animation-phase advancer that FUN_005a4600 calls first) through the Ghidra PCode emulator and
# bank the player-field writes + return (frame carry) that Pm98Action.tick_action must reproduce
# bit-for-bit (app/tests/test_tickaction.gd). Also exercises FUN_005aac30 (setup_kick) for real via the
# 0x1d windup -0x78 release branch.
#
# Sub-calls run REAL (all in-image, pure): set_position_code=FUN_005a5430, set_phase=FUN_005942e0,
# setup_kick=FUN_005aac30, polar_vec=FUN_005ee0f0. The genuinely-external ones (enqueue FUN_00594470,
# sound FUN_00590f00, RNG FUN_005ec240/230, FUN_00606220) fire ONLY at match phase 4/5/7, so the t==0
# kick-release fixture uses phase 0 -> they never run -> NO stubs needed. Const tables FRAME_COUNT
# (0x664fb8) / NEXT_ACTION (0x665208) / ANIM_E0 (0x6650e0) are real .data in the image; only the COS
# LUT (0x6d31c8, runtime-filled) is injected.
#
# Memory: player P @0x230000 (ECX), match @0x260000 (P+0x18c), ball @0x270000 (P+0x190; ball+0x40=P so
# the player IS the controller for setup_kick). +0x34/+0x66 are WORDs (read 2 bytes). Values signed LE.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/tickaction_oracle.txt
SPEC=$SPECDIR/_tickaction_run.spec
ROUT=$SPECDIR/_tickaction_run.out
LUT=$SPECDIR/_tickaction_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 (+atan, harmless)

READS=(
  "0x00230020 4" "0x00230024 4" "0x00230028 4"             # +0x20/+0x24/+0x28 velocity
  "0x0023002c 4" "0x00230030 4" "0x00230040 4" "0x00230048 4"  # +0x2c frame / +0x30 sub / +0x40 action / +0x48 timer
  "0x00230080 4" "0x00230084 4"                            # +0x80/+0x84 motion timers
  "0x00230094 4" "0x00230098 4" "0x0023009c 4"             # +0x94/+0x98/+0x9c trajectory endpoint
  "0x002300a0 4" "0x002300a4 4" "0x002300a8 4"             # +0xa0/+0xa4/+0xa8 aim
  "0x00230034 2" "0x00230066 2"                            # +0x34 facing (WORD) / +0x66 (WORD)
)

emit_spec() {
  {
    cat <<EOF
entry   0x005a50c0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00001000
zero    0x00270000 0x00001000
maxsteps 200000
EOF
    cat "$LUT"
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

# All fixtures: P+0x18c -> match, P+0x190 -> ball, ball+0x40 -> P (player is the controller).
PTRS="$(poke 0x23018c 0x260000);$(poke 0x230190 0x270000);$(poke 0x270040 0x230000)"

FIX=(
# --- common path (action != 0x1d): pure arithmetic, no sub-calls ---
"timer_lock|$(poke 0x230040 2);$(poke 0x230048 5);$(poke 0x230030 0);$(poke 0x23002c 7)"
"sub_nz|$(poke 0x230040 2);$(poke 0x230048 0);$(poke 0x230030 1);$(poke 0x23002c 7)"
"fwd_nowrap|$(poke 0x230040 2);$(poke 0x230030 3);$(poke 0x230068 5);$(poke 0x23002c 3)"
"fwd_wrap_next|$(poke 0x230040 6);$(poke 0x230030 3);$(poke 0x230068 5);$(poke 0x23002c 11)"
"reverse|$(poke 0x230040 2);$(poke 0x230030 3);$(poke 0x230068 -1);$(poke 0x23002c 0)"
"act15|$(poke 0x230040 0x15);$(poke 0x230030 3);$(poke 0x230068 5);$(poke 0x23002c 13);$(poke 0x230034 0x2000)"
# --- 0x1d windup tiers (sub != 0 so the frame logic is skipped -- the realistic, non-div0 state) ---
"w_tier1|$(poke 0x230040 0x1d);$(poke 0x230048 -0x50);$(poke 0x230030 1);$(poke 0x23002c 5)"
"w_tier2|$(poke 0x230040 0x1d);$(poke 0x230048 -0x64);$(poke 0x230030 1);$(poke 0x23002c 5);$(poke 0x230034 0x1000);$(poke 0x230004 0x40000);$(poke 0x230008 0x50000);$(poke 0x23000c 0x60000)"
"w_release|$(poke 0x230040 0x1d);$(poke 0x230048 -0x78);$(poke 0x230034 0x800);$(poke 0x230020 0x100);$(poke 0x230024 0x200);$(poke 0x230028 0x300);$(poke 0x230004 0x40000);$(poke 0x230008 0x50000);$(poke 0x23000c 0x60000)"
"kick_release|$(poke 0x230040 0x1d);$(poke 0x230048 0);$(poke 0x230030 1);$(poke 0x23002c 5);$(poke 0x230034 0x1500);$(poke 0x230004 0x40000);$(poke 0x230008 0x50000);$(poke 0x23000c 0x60000)"
)

: > "$OUT"
echo "# Stage 3 POSITIONAL Task #7: FUN_005a50c0 (tick_action) + FUN_005aac30 (setup_kick) PCode-emu truth." >> "$OUT"
echo "# Sub-calls real (set_position_code/set_phase/setup_kick/polar_vec); no stubs (t==0 uses phase 0)." >> "$OUT"
echo "# +0x34/+0x66 are WORDs (read 2). Each row: FIX <name> + the verbatim CALL line (EAX=return carry)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES="$POKES;$PTRS"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  EAX=$(echo "$LINE" | grep -oE 'EAX=[0-9-]+' | head -1)  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')  2c=$(echo "$LINE" | grep -oE 'mem\[0x23002c:4\]=[0-9-]+')  48=$(echo "$LINE" | grep -oE 'mem\[0x230048:4\]=[0-9-]+')"
done
echo "=== tickaction oracle -> $OUT ==="
cat "$OUT"
