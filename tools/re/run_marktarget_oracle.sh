#!/usr/bin/env bash
# Stage 3 task 2 (movement, slice 3): drive the REAL marking-target selector
# FUN_005b36f0 through the Ghidra PCode emulator and bank the returned pointer (EAX).
# Ground truth that Pm98Movement.select_mark_target must reproduce (app/tests/
# test_marktarget.gd).
#
# FUN_005b36f0(__fastcall this=player) is a PURE selector (writes only stack locals,
# disasm-verified) that returns the opponent this player should mark: it keeps the
# current target (player+0xb0) while it stays inside the marking box (or within a
# distance band in alt mode team_desc+0x310 != 0), else scans the unmarked (+0x154==0)
# opponents (descriptor player+0x188 = {base,count}), scores each by the 8690
# relationship-matrix distance (player+0xe4+(slot+team*11)*4) inflated by mul16 when
# out-of-box (0x18000 / 0x13333) and by an x-gap term (/15), and returns the lowest-
# scoring one for which THIS player is also that opponent's nearest defender
# (reciprocity, scanning player+0x184 = our team {base,count}). NO RNG; the only callee
# float op is FUN_005edfa0 = mul16 (native integer pcode). So NO _ftol / LUT injection
# is needed -- just poke state, run, read EAX.
#
# Memory map: param player P@0x230000 (team0 slot0), teammate P1@0x2303bc (team0 slot1,
# reciprocity), opponents Q0@0x240000 / Q1@0x2403bc (team1 slots 0/1), our team
# descriptor TD@0x250000 ({+0:base=P, +4:count=2}, tactical +0x2fc/+0x300/+0x310),
# opponent descriptor OD@0x251000 ({+0:base=Q, +4:count=2}), match M@0x210000 (+0x1820
# alt-mode scale). EAX is the default read_reg, so the returned pointer is captured.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/marktarget_oracle.txt
SPEC=$SPECDIR/_marktarget_run.spec
ROUT=$SPECDIR/_marktarget_run.out

# Matrix dist offsets: P->Q0 = +0xe4+(0+1*11)*4 = +0x110 ; P->Q1 = +0x114.
#   Q->P = +0xe4 (our slot 0) ; Q->P1 = +0xe8 (our slot 1).
emit_spec() {
  cat > "$SPEC" <<EOF
entry   0x5b36f0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00210000 0x00002000
zero    0x00230000 0x00002000
zero    0x00240000 0x00002000
zero    0x00250000 0x00002000
mem 0x00230184 4 0x00250000     # P+0x184 = our team descriptor
mem 0x00230188 4 0x00251000     # P+0x188 = opponent descriptor
mem 0x0023018c 4 0x00210000     # P+0x18c = match
mem 0x002302b8 4 0x0            # P team 0
mem 0x002302bc 4 0x1            # P on-pitch
mem 0x002302c4 4 0x0            # P slot 0
mem 0x002300b0 4 0x0            # P+0xb0 current target = none
mem 0x00230004 4 0x40000        # P.x
mem 0x00230008 4 0x40000        # P.y
mem 0x0023000c 4 0x0            # P.z
mem 0x002303a4 4 0x40000        # P.anchor (= x -> p_metric 0, no x-gap penalty by default)
mem 0x002301e0 4 0x0            # P+0x1e0 (alt-mode band reference)
mem 0x00230210 4 0x0            # box xmin
mem 0x00230214 4 0x0            # box ymin
mem 0x00230218 4 0x0            # box zmin
mem 0x0023021c 4 0x1000000      # box xmax
mem 0x00230220 4 0x1000000      # box ymax
mem 0x00230224 4 0x1000000      # box zmax
mem 0x00230110 4 0x50000        # matrix P->Q0
mem 0x00230114 4 0x90000        # matrix P->Q1
mem 0x00230674 4 0x0            # P1 team 0
mem 0x00230678 4 0x1            # P1 on-pitch
mem 0x00230680 4 0x1            # P1 slot 1
mem 0x002402b8 4 0x1            # Q0 team 1
mem 0x002402bc 4 0x1            # Q0 on-pitch
mem 0x002402c4 4 0x0            # Q0 slot 0
mem 0x00240154 4 0x0            # Q0 marker-taken flag
mem 0x00240004 4 0x50000        # Q0.x
mem 0x00240008 4 0x50000        # Q0.y
mem 0x0024000c 4 0x0            # Q0.z
mem 0x002403a4 4 0x0            # Q0.anchor
mem 0x002400e4 4 0x40000        # matrix Q0->P
mem 0x002400e8 4 0x80000        # matrix Q0->P1
mem 0x00240674 4 0x1            # Q1 team 1
mem 0x00240678 4 0x1            # Q1 on-pitch
mem 0x00240680 4 0x1            # Q1 slot 1
mem 0x00240510 4 0x0            # Q1 marker-taken flag
mem 0x002403c0 4 0x30000        # Q1.x
mem 0x002403c4 4 0x30000        # Q1.y
mem 0x002403c8 4 0x0            # Q1.z
mem 0x00240760 4 0x0            # Q1.anchor
mem 0x002404a0 4 0x70000        # matrix Q1->P
mem 0x002404a4 4 0x30000        # matrix Q1->P1
mem 0x00250000 4 0x00230000     # TD base = team0 array
mem 0x00250004 4 0x2            # TD count
mem 0x002502fc 4 0x0            # TD+0x2fc (alt thr2 base)
mem 0x00250300 4 0x0            # TD+0x300 (alt thr1 base)
mem 0x00250310 4 0x0            # TD+0x310 (0 = box mode)
mem 0x00251000 4 0x00240000     # OD base = opp array
mem 0x00251004 4 0x2            # OD count
mem 0x00211820 4 0x0            # match+0x1820 alt scale
$1
maxsteps 2000000
EOF
}

# Fixtures: name | override pokes (';'-separated, appended AFTER the base). Defaults
# encode the search_pick scenario (Q0 reciprocal to P, Q1 nearest is P1).
FIX=(
"keep_box|mem 0x002300b0 4 0x00240000"
"invalid_search|mem 0x002300b0 4 0x002403bc ; mem 0x002403c0 4 0x2000000"
"keep_alt|mem 0x002300b0 4 0x00240000 ; mem 0x00250310 4 0x1 ; mem 0x00250300 4 0x100000 ; mem 0x002502fc 4 0x80000"
"search_pick|mem 0x00230004 4 0x40000"
"recip_filter|mem 0x002400e4 4 0x80000 ; mem 0x002400e8 4 0x40000 ; mem 0x002404a0 4 0x30000 ; mem 0x002404a4 4 0x70000"
"taken_skip|mem 0x00240154 4 0x1 ; mem 0x002404a0 4 0x30000 ; mem 0x002404a4 4 0x70000"
"penalty_box|mem 0x00230110 4 0x80000 ; mem 0x00230114 4 0x60000 ; mem 0x002403c0 4 0x2000000 ; mem 0x002404a0 4 0x30000 ; mem 0x002404a4 4 0x70000"
"penalty_flip|mem 0x00230110 4 0x80000 ; mem 0x00230114 4 0x60000 ; mem 0x0024000c 4 0x1000 ; mem 0x002403c0 4 0x2000000 ; mem 0x002404a0 4 0x30000 ; mem 0x002404a4 4 0x70000"
)

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Stage 3 task 2 slice 3 marking-target (FUN_005b36f0) ground truth (PCode emu; pure" >> "$OUT"
echo "# selector, no float-import, EAX = returned target pointer). Each row: FIX <name> CALL line." >> "$OUT"
echo "# bases: Q0=0x240000 Q1=0x2403bc ; null=0 (EAX -> opp index via (EAX-0x240000)/0x3bc)" >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  POKES=${POKES//;/$'\n'}
  emit_spec "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $LINE" >> "$OUT"
  echo "[$NAME] $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+ EAX=[0-9]+')"
done
echo "=== marktarget oracle -> $OUT ==="
cat "$OUT"
