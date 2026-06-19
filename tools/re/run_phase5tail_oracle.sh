#!/usr/bin/env bash
# Stage 3 task 2 (FUN_005b73a0 slice E): drive the REAL FUN_005b73a0 phase-5 TAIL Path C
# (LAB_005b81d6, match+0x448==5 && match+0x19cc==0 && match+0x45c==team) through the Ghidra PCode
# emulator and bank the resulting OUR-player positions. Ground truth for Pm98Movement._phase5_tail_pathC.
#
# For each our player with sign(P+0x4) != sign(P+0x3a4) AND FUN_005b0b40(P,0) (goal-side opp count)
# <= 1: P.x = *(match-team*800+0x98c)+0x4 (team set-piece anchor x), then FUN_005ee2d0 min-sep
# (box 0x93333) vs the taker (match+0x438). No RNG.
#
#   Phase 5 with 0x19cc==0 + 0x45c==team -> the WALL branch is skipped (needs 0x19cc!=0 & 0x45c!=team);
#   position_team falls straight to the tail. ctx+0x2e0=0 -> relmatrix throttle-skips. No LUT needed
#   (clamp_min_sep here keeps players inside the box so the scale path runs; that uses FUN_005ee290's
#   integer idiv + FUN_005ee0f0 only on the dist==0 branch, not hit). CALL RET rows.
#
# Memory: ctx @0x230000, match @0x210000, OUR players @0x240000 (stride 0x3bc, 3 players P0..P2),
#   goal-side-opp descriptor @0x251000 ({+0:base=0x260000,+4:count=2}), 2 opps @0x260000/@0x2603bc,
#   set-piece anchor ptr *(match+0x98c)=0x261000 (anchor.x @0x261004), taker @0x270000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/phase5tail_oracle.txt
SPEC=$SPECDIR/_phase5tail_run.spec
ROUT=$SPECDIR/_phase5tail_run.out

P() { printf '0x%08x' $(( 0x240000 + $1 * 0x3bc + $2 )); }   # our player $1, field offset $2
poke() { printf 'mem %s 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

READS=(
  "$(P 0 0x4) 4" "$(P 0 0x8) 4" "$(P 0 0xc) 4"               # P0 (sign-diff, count 0 -> MOVE+clamp)
  "$(P 1 0x4) 4"                                             # P1 (sign-same -> SKIP, sentinel)
  "$(P 2 0x4) 4"                                             # P2 (sign-diff, count 2 -> SKIP, sentinel)
)

SETUP=""
add() { SETUP+="$(poke "$1" "$2");"; }
# P0: x=+0x100000, anchor=-0x100000 (signs differ; lim=0 -> count 0 -> MOVE). desc @0x251000.
add "$(P 0 0x4)" 0x100000;  add "$(P 0 0x3a4)" -0x100000;  add "$(P 0 0x8)" 0;  add "$(P 0 0xc)" 0
add "$(P 0 0x188)" 0x251000
# P1: x=+0x100000, anchor=+0x100000 (signs same -> SKIP). sentinel x retained.
add "$(P 1 0x4)" 0x100000;  add "$(P 1 0x3a4)" 0x100000;  add "$(P 1 0x188)" 0x251000
# P2: x=+0x100000, anchor=-0x40000 (signs differ; lim=0xc0000 -> 2 opps count -> SKIP). sentinel retained.
add "$(P 2 0x4)" 0x100000;  add "$(P 2 0x3a4)" -0x40000;  add "$(P 2 0x188)" 0x251000
# goal-side-opp descriptor + 2 opps (x=0, anchor=0 -> d=0 < lim for P2, not for P0).
add 0x251000 0x260000;  add 0x251004 2
add 0x260004 0;  add 0x2603a4 0;  add 0x2603c0 0;  add 0x260760 0   # O1 @0x2603bc: +0x4=0x2603c0, +0x3a4=0x260760
# anchor.x (P0 snaps to it, then clamp_min_sep fires vs taker at origin -> dist 0x55000 < box 0x93333).
add 0x261004 0x55000
add 0x270004 0;  add 0x270008 0;  add 0x27000c 0

emit_spec() {
  {
    cat <<EOF
entry   0x005b73a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00001400
zero    0x00251000 0x00001000
zero    0x00260000 0x00001000
zero    0x00261000 0x00001000
zero    0x00270000 0x00001000
maxsteps 400000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
mem 0x006233a4 4 0x00252000
mem 0x006d31c4 1 0x0
mem 0x00230000 4 0x00240000
mem 0x00230004 4 0x3
mem 0x00230008 4 0x0
mem 0x00230138 4 0x00210000
mem 0x002302e0 4 0x0
mem 0x00210448 4 0x5
mem 0x002119cc 4 0x0
mem 0x0021045c 4 0x0
mem 0x00210438 4 0x00270000
mem 0x0021098c 4 0x00261000
EOF
    printf '%s\n' "${SETUP//;/$'\n'}"
    for r in "${READS[@]}"; do echo "read_mem $r"; done
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {  # $1 name
  emit_spec
  run_emu
  local line; line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $1 $line" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
}

: > "$OUT"
echo "# Stage 3 task 2 FUN_005b73a0 slice E (phase-5 tail Path C, our-set-piece follow-up) PCode-emu truth." >> "$OUT"
echo "# P0 sign-diff+count0 -> x=anchor then clamp vs taker; P1 sign-same SKIP; P2 count>=2 SKIP. CALL RET." >> "$OUT"
bank pathC
echo "=== phase5tail oracle -> $OUT ==="
cat "$OUT"
