#!/usr/bin/env bash
# Stage 3 (movement subtree, kickoff unstick): drive the REAL movement dispatcher
# FUN_005a65a0 through the Ghidra PCode emulator on a kickoff-taker fixture and bank
# the exact action it assigns. This is the GROUND TRUTH the GD port of FUN_005a65a0's
# phase-2 taker branch (-> FUN_005aa4d0 -> FUN_005a5430) must reproduce.
#
# WHY THIS IS THE PHASE-2 UNSTICK (handoff-pm98-phase2-rootcause-movement-subtree-stubs):
# at kickoff the active taker (match+0x438) has DECIDE action 0 and is parked; the port
# leaves it parked forever because _move_65a0 is a NO-OP stub. The real FUN_005a65a0,
# at (phase==2 && param_1==match+0x438 && action==0 && p+0x48<600), calls FUN_005aa4d0
# which calls FUN_005a5430((-(p+0x2bc==0)&0x21)+4): action -> 4 if on-pitch (resolve-
# capable kick; engine_tick case 4 -> FUN_005acc40 -> FUN_005ac1a0 -> resolve_post_shot
# -> set_phase(0)), or 0x25 if off-pitch. Verified action 0 -> 4 against the binary here.
#
# Path is LUT-FREE and avoids the deep callees by construction:
#   * p+0xb4 (pass target) is PRESET non-null -> FUN_005aa4d0 skips FUN_005aa680
#     (the pass-target selector; needed only when p+0xb4==0, i.e. at a real kickoff).
#   * controller+0x4c (ball-holder slot) == 0 -> FUN_005a8bc0 not called.
#   * match+0x180a == 0 -> FUN_00590f00 not called.
#   * team-info+0x2ee == 0 -> FUN_005943b0 not called (the bVar14 short-circuit).
# Only in-binary callees executed: FUN_005ec250 (LCG rand x2) + FUN_005a5430 (writer).
#
# Memory map (zeroed struct windows): P@0x230000 M@0x210000 C@0x240000 T@0x250000
# TGT@0x270000. P+0x184->T, P+0x18c->M, P+0x190->C(400), P+0x2bc on-pitch(700),
# P+0xb4 pass-target. M+0x448 phase, M+0x438 taker. C+0x40 active-ref. rand seed @0x6d3184.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/kicksetup_oracle.txt
SPEC=$SPECDIR/_kicksetup_run.spec
ROUT=$SPECDIR/_kicksetup_run.out

# emit_spec ONPITCH  -> writes $SPEC for the taker fixture with p+0x2bc=ONPITCH
emit_spec() {
  local onpitch=$1
  cat > "$SPEC" <<EOF
entry   0x5a65a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
arg     0x0
zero    0x00230000 0x00001000
zero    0x00210000 0x00002000
zero    0x00240000 0x00001000
zero    0x00250000 0x00001000
zero    0x00270000 0x00001000
mem 0x00230184 4 0x00250000
mem 0x0023018c 4 0x00210000
mem 0x00230190 4 0x00240000
mem 0x002302bc 4 $onpitch
mem 0x002300b4 4 0x00270000
mem 0x00210448 4 0x2
mem 0x00210438 4 0x00230000
mem 0x00240040 4 0x00230000
mem 0x006d3184 4 0x1
maxsteps 2000000
read_mem 0x00230040 4
read_mem 0x00230054 4
read_mem 0x0024004c 4
read_mem 0x00230080 4
read_mem 0x00230048 4
trace 0x005aa4d0 aa4d0
trace 0x005a5430 setact
trace 0x005a8bc0 a8bc0
trace 0x005aa680 aa680
EOF
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }

: > "$OUT"
echo "# Stage 3 movement-subtree kickoff unstick: FUN_005a65a0 taker branch ground truth" >> "$OUT"
echo "# (PCode emu, LUT-free path, p+0xb4 preset). Row: M <name> | action | v54 | c+4c | p+80 | RET" >> "$OUT"
echo "# action 4 = on-pitch resolve-capable kick; 0x25(37) = off-pitch. addrs: P=0x230000 TGT=0x270000" >> "$OUT"

for row in "onpitch 0x1" "offpitch 0x0"; do
  set -- $row; NAME=$1; ONP=$2
  emit_spec "$ONP"
  run_emu
  S=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  RET=$(echo "$S" | grep -oE 'CALL 0 (RET|HALT)' | awk '{print $3}' || true)
  printf 'M %-9s | %-4s | %-3s | %-8s | %-4s | %s\n' \
    "$NAME" "$(mval "$S" 0x230040)" "$(mval "$S" 0x230054)" \
    "$(mval "$S" 0x24004c)" "$(mval "$S" 0x230080)" "${RET:-?}" >> "$OUT"
  echo "[$NAME] action=$(mval "$S" 0x230040) v54=$(mval "$S" 0x230054) $(echo "$S" | grep -oE 'tracehits=\{[^}]*\}') $RET"
done
echo "=== kicksetup oracle -> $OUT ==="
cat "$OUT"
