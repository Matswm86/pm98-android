#!/usr/bin/env bash
# Stage 3 task 2 (DECIDE else-replay): drive the REAL FUN_005a3400 down the REPLAY branch
# (DAT_006d31c4 != 0) through the Ghidra PCode emulator and bank the saved-state restore +
# active-marker bookkeeping outputs. Ground truth for Pm98Movement.decide_slice_replay
# (app/tests/test_decideReplay.gd).
#
# Replay branch (disasm 0x5a368c..0x5a374c): copy 0x51 (81) dwords from *(player+0x3b0) into
# player+0x40..+0x180; if the RESTORED +0x5c is set, make this player the team's active player
# (team+0x184 -> +0x168, clearing the prior active's +0x5c) and, when this player is the set-piece
# taker (match+0x438), stamp match+0x45c = player team. (The taker-only globals 0x665154/...
# are player-field-inert and out of scope.) Slice A runs as the prefix (writes +0x1e0..+0x224/
# +0x3a4 only -- none read here), so the branch is self-contained; NO callee stubs, NO LUT/RNG.
#
# Memory map: player P0 @0x230000, match M @0x210000, team @0x240000 (player+0x184), prior active
# OLD @0x280000, FUN_005ed870 +0x38 buffer @0x252000, saved-state buffer @0x254000 (player+0x3b0).
# DAT_006d31c4 @0x6d31c4 = 1 (replay). Values signed LE decimal.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/decideReplay_oracle.txt
SPEC=$SPECDIR/_decideReplay_run.spec
ROUT=$SPECDIR/_decideReplay_run.out

# Output addresses: player copy fields, team active ptr, prior-active +0x5c, match taker stamp.
READS=(
  "0x00230040 4" "0x00230044 4" "0x0023005c 4" "0x002300b0 4" "0x00230180 4"   # restored +0x40/+0x44/+0x5c/+0xb0/+0x180
  "0x00240168 4"                                            # team+0x168 active player ptr
  "0x0028005c 4"                                            # prior active +0x5c (cleared?)
  "0x0021045c 4"                                            # match+0x45c taker-team stamp
)

emit_spec() {
  # $1 = per-fixture pokes (newline-separated)
  {
    cat <<EOF
entry   0x005a3400
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00001000
zero    0x00240000 0x00001000
zero    0x00280000 0x00001000
zero    0x00252000 0x00000040
zero    0x00254000 0x00000400
maxsteps 400000
mem 0x006d31c4 1 0x1
mem 0x00230038 4 0x00252000
mem 0x002303b0 4 0x00254000
mem 0x00230184 4 0x00240000
mem 0x0023018c 4 0x00210000
mem 0x002302bc 4 0x0
mem 0x00211820 4 0x100000
mem 0x002119a0 4 0x0
mem 0x0021045c 4 0x7777
mem 0x00254000 4 0x11110000
mem 0x00254004 4 0x22220000
mem 0x00254070 4 0x33330000
mem 0x00254140 4 0x44440000
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

# Per-fixture: player +0x2b8 team ; buf+0x1c = restored +0x5c gate (@0x25401c) ; team+0x168 prior
# active (@0x240168: 0x280000 OLD / 0 none / 0x230000 self) ; OLD+0x5c (@0x28005c) ; match+0x438
# taker (0x230000 = this player IS taker / 0x290000 = a different player).
FIX=(
# active + taker, prior active = OLD (gets cleared); team1 so the +0x45c stamp is visible.
"active_taker_old|$(poke 0x2302b8 1);$(poke 0x25401c 1);$(poke 0x240168 0x280000);$(poke 0x28005c 1);$(poke 0x210438 0x230000)"
# active + NON-taker, prior active = OLD (cleared); match+0x45c must stay the 0x7777 sentinel.
"active_nontaker_old|$(poke 0x2302b8 0);$(poke 0x25401c 1);$(poke 0x240168 0x280000);$(poke 0x28005c 1);$(poke 0x210438 0x290000)"
# restored +0x5c == 0 -> NO bookkeeping (team+0x168 + OLD+0x5c + match+0x45c all unchanged).
"inactive|$(poke 0x2302b8 0);$(poke 0x25401c 0);$(poke 0x240168 0x280000);$(poke 0x28005c 1);$(poke 0x210438 0x230000)"
# active + taker, NO prior active (team+0x168 == 0) -> becomes active, stamp; nothing to clear.
"active_noold|$(poke 0x2302b8 1);$(poke 0x25401c 1);$(poke 0x240168 0);$(poke 0x210438 0x230000)"
# active, prior active == THIS player (self) -> not cleared; non-taker so no stamp.
"active_self|$(poke 0x2302b8 0);$(poke 0x25401c 1);$(poke 0x240168 0x230000);$(poke 0x210438 0x290000)"
)

: > "$OUT"
echo "# Stage 3 task 2 DECIDE else-replay (FUN_005a3400 DAT_006d31c4!=0 path) PCode-emu ground truth." >> "$OUT"
echo "# Replay copy *(player+0x3b0)->+0x40..+0x180 + active-marker bookkeeping; clean RET. No stubs/LUT." >> "$OUT"
echo "# buffer @0x254000 seeded [+0]=0x11110000 [+4]=0x22220000 [+0x70]=0x33330000 [+0x140]=0x44440000;" >> "$OUT"
echo "# +0x1c (-> restored +0x5c) per-fixture. match+0x45c pre-seeded 0x7777 sentinel. Each row: FIX + CALL." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')  40=$(echo "$LINE" | grep -oE 'mem\[0x230040:4\]=[0-9-]+')  168=$(echo "$LINE" | grep -oE 'mem\[0x240168:4\]=[0-9-]+')  45c=$(echo "$LINE" | grep -oE 'mem\[0x21045c:4\]=[0-9-]+')"
done
echo "=== decideReplay oracle -> $OUT ==="
cat "$OUT"
