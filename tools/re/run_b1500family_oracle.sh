#!/usr/bin/env bash
# s15 (off-ball formation movement): drive the REAL FUN_005b1500 (opponent-possession
# mover) and FUN_005b1c80 (own-possession mover) through the Ghidra PCode emulator with
# NO stubs -- every callee (3b20/1330/2f30/3060/2b70/3a10/35c0/4820/3c90/3c10/31a0/1070/
# 04e0/aa490/aa4d0/aa870/aafd0/89c0/the role-leaf family 41c0/4a80/4f70/3d00/3e50/5520/
# 5150 and the 41b0 ret-0 thunks) runs REAL in-image. This is the ground truth for the
# ports Pm98Movement.offball_opp_b1500 / offball_own_b1c80 (app/tests/test_b1500family.gd).
#
# Memory map (zeroed windows): P@0x230000 (ECX), M@0x210000 (P+0x18c), C=ball@0x240000
# (P+0x190), T=own-gs@0x250000 (P+0x184; T+0=0x310000 base, T+4=count), F=foreign-gs
# @0x260000 (P+0x188; F+0=0x320000 base, F+4=count), own Q0/Q1@0x310000/0x3103bc,
# foreign R0/R1@0x320000/0x3203bc. rand seed @0x6d3184 = 1 every fixture.
# The binary's marker link p+0x150 is a POINTER here (the port models it as a foreign-
# roster INDEX; the GD test translates).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b1500family_oracle.txt
SPEC=$SPECDIR/_b1500family_run.spec
ROUT=$SPECDIR/_b1500family_run.out
LUT=$SPECDIR/_b1500family_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

emit_spec() {  # $1 = entry VA, $2 = newline-joined pokes
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00210000 0x00002000
zero    0x00240000 0x00001000
zero    0x00250000 0x00001000
zero    0x00260000 0x00001000
zero    0x00310000 0x00001000
zero    0x00320000 0x00001000
zero    0x00674000 0x00001000
maxsteps 4000000
EOF
    cat "$LUT"
    # _ftol thunk + the hand-coded Win32 MulDiv surrogate (IAT imports uncallable in-emu;
    # same bytes as run_7260kick_oracle.sh). Event queue FROZEN (m+0x1a38=1) so the
    # FUN_00594470 enqueue early-returns (no GlobalReAlloc fault) -- the queue is locked
    # separately in test_events.gd.
    echo "membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3"
    echo "membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00"
    printf 'mem 0x%08x 4 0x%08x\n' 0x6233a4 0x252000
    printf 'mem 0x%08x 4 0x%08x\n' 0x623064 0x252100
    printf 'mem 0x%08x 4 0x%08x\n' 0x211a38 1
    echo "stub 0x605ff0 0 0 atexit"
    printf '%s\n' "$2"
    for r in \
      "0x00230034 2" "0x00230040 4" "0x00230048 4" "0x0023005e 1" "0x0023005f 1" \
      "0x00230066 2" "0x00230080 4" "0x00230084 4" "0x00230094 4" "0x00230098 4" \
      "0x0023009c 4" "0x002300b4 4" "0x0023013c 4" "0x00230140 4" "0x00230144 4" \
      "0x00230148 4" "0x00230158 4" "0x0023015c 4" "0x00230160 4" "0x00230164 4" \
      "0x00230168 4" "0x0023016c 4" "0x00230170 4" "0x00230174 4" "0x00230178 4" \
      "0x00240040 4" "0x0024004c 4" "0x00230054 4" "0x00230058 4" "0x006d3184 4"; do
      echo "read_mem $r"
    done
    echo "trace 0x5b3b20 a3b20"
    echo "trace 0x5b2f30 dart"
    echo "trace 0x5b2b70 unmark"
    echo "trace 0x5b3060 pushup"
    echo "trace 0x5b3a10 pass3a10"
    echo "trace 0x5b35c0 cross"
    echo "trace 0x5b4820 run4820"
    echo "trace 0x5b41c0 L41c0"
    echo "trace 0x5b4a80 L4a80"
    echo "trace 0x5b4f70 L4f70"
    echo "trace 0x5b3d00 L3d00"
    echo "trace 0x5b3e50 L3e50"
    echo "trace 0x5b5520 L5520"
    echo "trace 0x5b5150 L5150"
    echo "trace 0x5aafd0 aafd0"
    echo "trace 0x5aa870 aa870"
    echo "trace 0x5aa490 aa490"
    echo "trace 0x5aa4d0 aa4d0"
    echo "trace 0x5a89c0 s89c0"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

# Common wiring: P links + pitch consts (goalx 0x1400000, sideline 0xd0000, global box
# +/-0x1400000 x / +/-0xd00000 y / 0..0x100000 z) + rand seed 1.
PTRS="$(poke 0x230184 0x250000);$(poke 0x230188 0x260000);$(poke 0x23018c 0x210000);$(poke 0x230190 0x240000);$(poke 0x6d3184 1)"
PITCH="$(poke 0x211820 0x1400000);$(poke 0x211824 0xd0000);$(poke 0x211828 -0x1400000);$(poke 0x211834 0x1400000);$(poke 0x21182c -0xd00000);$(poke 0x211838 0xd00000);$(poke 0x211830 0);$(poke 0x21183c 0x100000)"
# P roam box: x [-0x800000,0x800000], y [-0x400000,0x400000], z [0,0x100000].
PBOX="$(poke 0x230210 -0x800000);$(poke 0x23021c 0x800000);$(poke 0x230214 -0x400000);$(poke 0x230220 0x400000);$(poke 0x230218 0);$(poke 0x230224 0x100000)"
# P anchors: home +0x1e0 = (-0x300000, 0x80000, 0), second +0x1ec = (-0x200000, 0x60000, 0).
PANCH="$(poke 0x2301e0 -0x300000);$(poke 0x2301e4 0x80000);$(poke 0x2301ec -0x200000);$(poke 0x2301f0 0x60000)"
# Own roster: Q0 on-pitch team 0 slot 1 at (0x70000, 0x10000), links set; Q1 off-pitch.
OWN="$(poke 0x250000 0x310000);$(poke 0x250004 2);$(poke 0x3102bc 1);$(poke 0x3102b8 0);$(poke 0x3102c4 1);$(poke 0x310004 0x70000);$(poke 0x310008 0x10000);$(poke 0x31018c 0x210000);$(poke 0x310190 0x240000);$(poke 0x310184 0x250000);$(poke 0x310188 0x260000);$(poke 0x3103a4 -0x1400000)"
# Foreign roster: R0 on-pitch team 1 slot 0 at (0x200000, -0x20000); R1 on-pitch team 1 slot 1.
FRN="$(poke 0x260000 0x320000);$(poke 0x260004 2);$(poke 0x3202bc 1);$(poke 0x3202b8 1);$(poke 0x3202c4 0);$(poke 0x320004 0x200000);$(poke 0x320008 -0x20000);$(poke 0x32018c 0x210000);$(poke 0x320190 0x240000);$(poke 0x3203a4 0x1400000)"
# R1 (base 0x3203bc): on-pitch team 1 slot 1 at (-0x100000, 0x90000), links set.
FRN2="$(poke 0x320678 1);$(poke 0x320674 1);$(poke 0x320680 1);$(poke 0x3203c0 -0x100000);$(poke 0x3203c4 0x90000);$(poke 0x320548 0x210000);$(poke 0x32054c 0x240000);$(poke 0x320760 0x1400000)"
# P identity: team 0, slot 0, on-pitch, own-goal anchor +0x3a4 = -0x1400000 (defends -x).
PID="$(poke 0x2302b8 0);$(poke 0x2302c4 0);$(poke 0x2302bc 1);$(poke 0x2303a4 -0x1400000)"

# name|entry|pokes
FIX=(
# ---- FUN_005b1500 (opponent possession) ----
# carrier held by an off-pitch player (keeper hold) -> raw 3b20 anchor steer.
"b15_keeperhold|0x005b1500|$(poke 0x240040 0x320000)"
# mark-follow SHADOW: p+0x150 = R0 (far y -> no goal-side hold; R0 not carrier/receiver).
"b15_shadow|0x005b1500|$(poke 0x230150 0x320000);$(poke 0x230008 0x400000);$(poke 0x3200e4 0x100000)"
# mark-follow PRESS (receiver): C+0x4c = R0 -> midpoint + the 0x29999 tackle roll (dist big -> no aafd0).
"b15_press_recv|0x005b1500|$(poke 0x230150 0x320000);$(poke 0x24004c 0x320000);$(poke 0x2300e8 0x300000)"
# mark-follow TACKLE: R0 carries, P parked ON the mark point band; dist small -> rolls run.
"b15_tackle|0x005b1500|$(poke 0x230150 0x320000);$(poke 0x240040 0x320000);$(poke 0x320004 0x70000);$(poke 0x320008 0x10000);$(poke 0x230004 0x90000);$(poke 0x2300e4 0x10000)"
# no mark, role 4, carrier exists -> the 4a80 press leaf.
"b15_role4|0x005b1500|$(poke 0x2302c8 4);$(poke 0x240040 0x320000)"
# no mark, role 4, NO carrier -> 3b20 anchor + designated-x override (gs+0x200 = Q0).
"b15_role4_loose|0x005b1500|$(poke 0x2302c8 4);$(poke 0x250200 0x310000)"
# no mark, role 7 -> the clamped 3b20 anchor walk (switch unreachable).
"b15_anchor|0x005b1500|$(poke 0x2302c8 7)"
# ---- FUN_005b1c80 (own possession) ----
# state 6 held (13c=6, 2d8=1) -> halfway-line steer.
"b1c_state6|0x005b1c80|$(poke 0x23013c 6);$(poke 0x2302d8 1);$(poke 0x2302c8 7)"
# state-6 ENTRY: teammate Q0 carries, P ahead in the opponent half with 2d8 set.
"b1c_state6_entry|0x005b1c80|$(poke 0x240040 0x310000);$(poke 0x2302d8 1);$(poke 0x230004 0x1200000);$(poke 0x310004 0x70000);$(poke 0x2302c8 7)"
# CARRIER near goal, lane clear, forward-ok -> the state-5 entry + burst (+ maybe AA870).
"b1c_carrier5|0x005b1c80|$(poke 0x240040 0x230000);$(poke 0x230004 0x1300000);$(poke 0x2303a4 -0x1400000);$(poke 0x2302c8 9);$(poke 0x2303a0 50);$(poke 0x230388 50);$(poke 0x230034 0)"
# CARRIER deep in own half -> the unmark/pushup/long-ball chain then the role leaf.
"b1c_carrier_deep|0x005b1c80|$(poke 0x240040 0x230000);$(poke 0x230004 -0x600000);$(poke 0x2302c8 2);$(poke 0x23017c 0x100000);$(poke 0x230180 0x100000);$(poke 0x310004 0x600000);$(poke 0x3100e4 0x100000)"
# dart continue (13c=1) then the role-9 leaf midpoint hold.
"b1c_dart_leaf9|0x005b1c80|$(poke 0x23013c 1);$(poke 0x230144 2);$(poke 0x230148 10);$(poke 0x230164 0x100000);$(poke 0x230168 0x40000);$(poke 0x2302c8 9);$(poke 0x23017c 0x100000);$(poke 0x240040 0x310000);$(poke 0x240004 0x300000)"
# role-2 leaf, non-carrier, ball same y-sign -> the 3c60 sub-state promote roll.
"b1c_leaf2_promote|0x005b1c80|$(poke 0x2302c8 2);$(poke 0x240040 0x310000);$(poke 0x230008 0x40000);$(poke 0x240008 0x30000)"
# role-2 leaf, CARRIER, sub 0 -> the decision ladder (4820 run / 31a0 passes).
"b1c_leaf2_carrier|0x005b1c80|$(poke 0x2302c8 2);$(poke 0x240040 0x230000);$(poke 0x230004 -0x200000);$(poke 0x23017c 0x100000);$(poke 0x230180 0x100000)"
# role-4 leaf, non-carrier -> anchor walk + designated override.
"b1c_leaf4|0x005b1c80|$(poke 0x2302c8 4);$(poke 0x240040 0x310000);$(poke 0x250200 0x310000)"
# role-5 leaf, CARRIER -> goal steer + the 31a0 ladder.
"b1c_leaf5_carrier|0x005b1c80|$(poke 0x2302c8 5);$(poke 0x240040 0x230000);$(poke 0x230180 0x100000);$(poke 0x23017c 0x100000)"
# role-9 leaf, LOOSE ball goal-side chase gate.
"b1c_leaf9_loose|0x005b1c80|$(poke 0x2302c8 9);$(poke 0x240004 -0x800000);$(poke 0x230004 0x200000);$(poke 0x23017c 0x100000)"
# role-10 leaf, non-carrier -> the (anchor2+3b20)/2 + ball hold.
"b1c_leaf10|0x005b1c80|$(poke 0x2302c8 10);$(poke 0x240040 0x310000);$(poke 0x240004 0x300000);$(poke 0x240008 0x80000)"
# role-13 leaf, CARRIER -> the 3c10/5% rolls then the goal run.
"b1c_leaf13_carrier|0x005b1c80|$(poke 0x2302c8 13);$(poke 0x240040 0x230000);$(poke 0x230180 0x100000);$(poke 0x23017c 0x100000)"
)

: > "$OUT"
echo "# s15: FUN_005b1500 + FUN_005b1c80 ground truth (PCode emu; NO stubs -- all leaves real)." >> "$OUT"
echo "# Windows: P=0x230000 M=0x210000 C=0x240000 T(own)=0x250000 F(foreign)=0x260000 Q=0x310000 R=0x320000." >> "$OUT"
echo "# Each row: FIX <name> then the verbatim CALL 0 (STUB|RET|HALT) line (tracehits + mem reads)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ENTRY POKES <<<"$row"
  # Common wiring FIRST, fixture pokes LAST (so a fixture can override a common field,
  # e.g. b15_keeperhold's off-pitch carrier).
  POKES="$PTRS;$PITCH;$PBOX;$PANCH;$OWN;$FRN;$FRN2;$PID;$POKES"
  POKES=${POKES//;/$'\n'}
  emit_spec "$ENTRY" "$POKES"
  run_emu
  echo "## FIX $NAME entry=$ENTRY" >> "$OUT"
  grep -E 'CALL 0 (STUB|RET|HALT)' "$ROUT" >> "$OUT" || echo "NO-RESULT" >> "$OUT"
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "[$NAME] $(echo "$S" | grep -oE '(RET|HALT)( steps=[0-9]+)?' | head -1) EAX=$(echo "$S" | grep -oE 'EAX=0x[0-9a-f]+' | head -1) $(echo "$S" | grep -oE 'tracehits=\{[^}]*\}' | head -1)"
done
echo "=== b1500-family oracle -> $OUT ==="
