#!/usr/bin/env bash
# Oracle for FUN_005a7260 marker-grid MARKER SCAN (0x5a8010..0x5a826e), slice 2b-iii-c. Per PASS the binary
# scans the 9 markers i=0..8: D = work[KICK_FRAME[i]] - p.pos, score = planar_mag(D.x,D.y) - KICK_GRID1[i].x,
# a z-band gate (|work.z - g1z| < 0x6666) + a planar-threshold gate (|score| < KICK_THRESH[i]) + a heading
# gate, tracking the single best marker into the [esp] slot cluster. We drive the REAL FUN_005a7260 ENTERED
# MID-FUNCTION (the grid build runs first, then the scan) and read the best-state back off the stack:
#   pass 0: entry 0x5a7e23 (loop setup seeds best-idx=-1, best-heading/hd1=0x7c72, pass=0) -> raw-copy grid.
#   pass 1: entry 0x5a7e67 (copy start) with the per-pass-loop seeds POKED + [esp+0x48]=1 + N (ball+0x5c) for
#           the tail extrapolation; markers 0,1 (DAT_006654e8==-1) are skipped.
# Both reach the scan-loop exit 0x5a8274 (the pass increment) with esp == entry-esp; we STUB 0x5a8274 0 0 SCAN
# so the harness pops [esp] (= our retSentinel) and RETs the instant the scan ends, best-state intact.
#
# Frame: sp0 = 0x308000; mid-fn entry => esp = sp0-4 = 0x307ffc. Best-state slots (abs = 0x307ffc + off):
#   [esp+0x2c]=0x308028 best-idx   [esp+0x28]=0x308024 best-frame*4   [esp+0x38]=0x308034 best-score
#   [esp+0x4c]=0x308048 best-headAbs [esp+0x50]=0x30804c best-hd1     [esp+0x54/0x58/0x5c]=0x308050/54/58 work
# work grid at esp+0xb0=0x3080ac; [esp+0x48]=0x308044 pass. p @0x230000 (ESI), ball @0x280000 (ECX/p+0x190),
# m @0x2a0000 (p+0x18c). GROUND TRUTH for Pm98Movement._marker_scan (app/tests/test_7260markerscan.gd).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/7260markerscan_oracle.txt
SPEC=$SPECDIR/_7260markerscan_run.spec
ROUT=$SPECDIR/_7260markerscan_run.out
LUT=$SPECDIR/_7260markerscan_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# _ftol thunk (round-to-zero) for the atan/polar x87 path; same bytes as the gridbuild / kick oracles.
THUNKS="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
$(poke 0x6233a4 0x252000)"

# Constant wiring (every fixture): p+0x18c=m, p+0x190=ball, p+0x2b8=team(0); m goal-X anchor for the pass-1
# tail extrapolation (unread by the scanned markers). p.pos (p+4/8/c) stays 0 (zeroed) so D = work[frame].
CONST="$(poke 0x23018c 0x2a0000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x2a1820 0x100000);$(poke 0x2a19a0 1)"

# A trajectory slot s lives at ball + 0xc*s; work[j] = traj(0x17+j): work[3]=traj(0x1a)@0x280138,
# work[5]=traj(0x1c)@0x280150. Helper to poke one traj vec3.
traj() { local s=$1 x=$2 y=$3 z=$4; local b=$(( 0x280000 + 0xc * s )); echo "$(poke $b "$x");$(poke $((b+4)) "$y");$(poke $((b+8)) "$z")"; }
# ball.pos (ball+4/8/c) -> angle2 = atan(ball.pos - p.pos). p.pos stays 0.
bpos() { echo "$(poke 0x280004 "$1");$(poke 0x280008 "$2");$(poke 0x28000c "$3")"; }
# marker bbox m+0x1828..0x183c: xmin@1828 ymin@182c zmin@1830 xmax@1834 ymax@1838 zmax@183c.
box() { echo "$(poke 0x2a1828 "$1");$(poke 0x2a182c "$2");$(poke 0x2a1830 "$3");$(poke 0x2a1834 "$4");$(poke 0x2a1838 "$5");$(poke 0x2a183c "$6")"; }

# KICK_GRID1 (0x674280) / KICK_GRID2 (0x674438) are LAZY-INIT BSS (zero in the static PE + skipped by our
# mid-function entry); the real game inits them in FUN_005a7260's prologue. The scan reads KICK_GRID1.x/.y/.z
# (score base + heading bias + z-band centre); we restore the runtime values (== Pm98Movement.KICK_GRID1) so
# the oracle reflects the initialised state. The 0x674000 page must be mapped (a `zero` directive) first.
gv() { local i=0; local a; for a in "$@"; do echo "$(poke $(( 0x674280 + i )) "$a")"; i=$(( i + 4 )); done; }
GRID1_INIT="$(gv \
  0x1b333 0 0x4000   0x9999 0 0x10000   0x9999 0 0x1cccc \
  0x21999 0x3555 0x3333   0x21999 0x3555 0xf333   0x21999 0x3555 0x1b333 \
  0x21999 -0x3555 0x3333  0x21999 -0x3555 0xf333  0x21999 -0x3555 0x1b333 | tr '\n' ';')"

# Best-state seeds for the pass-1 entry (the pass-0 entry seeds these itself). wx/wy/wz seeded 0 for BOTH.
SEED_WORK="$(poke 0x308050 0);$(poke 0x308054 0);$(poke 0x308058 0)"
SEED_P1="$(poke 0x308044 1);$(poke 0x308028 -1);$(poke 0x308024 0);$(poke 0x308034 0);$(poke 0x308048 0x7c72);$(poke 0x30804c 0x7c72);$SEED_WORK"

# Read the 8 best-state slots back (idx, frame4, score, headAbs, hd1, wx, wy, wz).
READS="read_mem 0x00308028 4
read_mem 0x00308024 4
read_mem 0x00308034 4
read_mem 0x00308048 4
read_mem 0x0030804c 4
read_mem 0x00308050 4
read_mem 0x00308054 4
read_mem 0x00308058 4"

# name|entry|extra-pokes.
#   hit0  : pass0, marker0 hits (work[3]=traj(0x1a)=(0x1b333,0,0x4000) -> score 0, z 0).
#   nohit : pass0, all gates fail (zeroed traj -> no marker passes) -> best stays seed.
#   p1hit2: pass1 (N=0x15 -> idxbase 5, work[3]/work[5] stay raw), markers 0,1 skipped, marker2 hits
#           (work[5]=traj(0x1c)=(0x9999,0,0x1cccc) -> score 0, z 0).
#   comp  : pass0, marker0 (work[3], +y so angle1>0) AND marker2 (work[5], near-axis) both pass; the
#           smaller-heading one replaces -> tests the heading replace-by-better.
#   bbox  : pass0, marker0 hits first (heading 0) then marker2 has a WORSE heading but is inside the marker
#           bbox while the incumbent (work[3]) is outside -> tests the bbox fallback keep.
FIX=(
  "hit0|0x005a7e23|$SEED_WORK;$(traj 0x1a 0x1b333 0 0x4000)"
  "nohit|0x005a7e23|$SEED_WORK"
  "p1hit2|0x005a7e67|$SEED_P1;$(poke 0x28005c 0x15);$(traj 0x1c 0x9999 0 0x1cccc)"
  "comp|0x005a7e23|$SEED_WORK;$(bpos 0x100000 0 0);$(traj 0x1a 0x1b333 0x8000 0x4000);$(traj 0x1c 0x9999 0x400 0x1cccc)"
  "bbox|0x005a7e23|$SEED_WORK;$(bpos 0x100000 0 0);$(traj 0x1a 0x1b333 0 0x4000);$(traj 0x1c 0x9999 0x2000 0x1cccc);$(box 0x9000 -0x10000 0x1c000 0xa000 0x10000 0x1d000)"
)

emit_spec() {  # $1=entry  $2=extra-pokes
  {
    cat <<EOF
entry   $1
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ESI 0x00230000
reg     ECX 0x00280000
zero    0x00230000 0x00001000
zero    0x00280000 0x00002000
zero    0x002a0000 0x00002000
zero    0x00674000 0x00002000
maxsteps 400000
stub    0x005a8274 0 0 SCAN
EOF
    cat "$LUT"
    printf '%s\n' "$THUNKS"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${GRID1_INIT//;/$'\n'}"
    printf '%s\n' "${2//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

: > "$OUT"
echo "# Oracle FUN_005a7260 MARKER SCAN (0x5a8010..0x5a826e). Best-state read back after one scan pass." >> "$OUT"
echo "# Row: SCAN <name> <scanned=0|1> | 0x308028=<idx> 0x308024=<frame4> 0x308034=<score> ... (8 LE u32)." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME ENTRY POKES <<<"$row"
  emit_spec "$ENTRY" "$POKES"
  run_emu
  LINE=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  if echo "$LINE" | grep -q 'stubhits=.*SCAN'; then SCANNED=1; else SCANNED=0; fi
  KV=$(echo "$LINE" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  echo "SCAN $NAME scanned=$SCANNED | $KV" >> "$OUT"
  echo "[$NAME] scanned=$SCANNED $(echo "$LINE" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
done
echo "=== 7260 marker-scan oracle -> $OUT ==="
cat "$OUT"
