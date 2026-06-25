#!/usr/bin/env bash
# Oracle for FUN_005b05a0 PHASE 2 (the sector-grid approach-ball steer), 0x5b07c4..0x5b0a13. Phase 2 is
# reached on EVERY phase-1 gate-fail; here we force entry by making the pitch bbox EMPTY (m+0x1828 huge
# positive => `jg` fails for every ball => the opening `je 0x5b07c4` jumps straight into phase 2). Phase 2
# is independent of the bbox, so this isolates it cleanly. Drives the REAL function under the Ghidra PCode
# emulator with FUN_005a89c0 (the steer trio) STUBBED (argbytes=8: target-ptr + 0x5a), then reads the
# COMPOSED TARGET vec back off the stack (the masked anchor+polar result the steer call would consume).
# GROUND TRUTH for Pm98Movement._near_ball_approach_steer (app/tests/test_b05a0_phase2.gd).
#
# this(ECX) = p. Phase 2 reads p+0x18c (m) / p+0x190 (ball) / p+0x2b8 (team). It builds:
#   anchor  = [goal_target_x(m,team), 0, 0]               (5a44f0 + 590aa0, REAL)
#   D1      = ball.pos - anchor  -> dot1 = planar_mag(D1.x,D1.y)
#   dot2    = planar_mag(ball.vel.x, ball.vel.y)  (ball+0x20/0x24)
#   sector  = min((dot1/(dot2+1))/3, 0xc)
#   grid    = ball[0xc*(sector+0x17)]  (a vec3 in the ball trajectory array)
#   D2      = grid - anchor  -> D2mag = planar_mag (5b1260, REAL)
#   r       = min(2*D2mag/3, MulDiv(0x30000, max(0,0x190000-D2mag), 0x190000)+0x20000)
#   target  = (anchor + polar(r, atan(D2))) with x,y masked & 0xffffc000  -> steer_89c0(target, 0x5a)
# Memory: p @0x230000 (ECX), m @0x260000, ball @0x280000. Trig LUT + _ftol + a hand-coded Win32 MulDiv
# injected (IAT imports are uncallable in-emu). The composed target lands at stack 0x307fc0 (sp0 0x308000,
# fastcall ECX => entry esp = sp0-4; prologue SUB 0x4c + 3 pushes => frame base A=sp0-0x5c; target @ A+0x1c).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/b05a0_phase2_oracle.txt
SPEC=$SPECDIR/_b05a0_phase2_run.spec
ROUT=$SPECDIR/_b05a0_phase2_run.out
LUT=$SPECDIR/_b05a0_phase2_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"    # cos@0x6d31c8 + atan@0x6d71c8

poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# _ftol thunk (round-to-zero) + hand-coded Win32 MulDiv (round half away from zero), as the kick oracle.
THUNKS="membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
membts 0x00252100 538B4C241085C97509B8FFFFFFFF5BC20C008B4424087904F7D8F7D9F76C240C8BD9D1FB85D279072BC383DA00EB0503C383D200F7F95BC20C00
$(poke 0x6233a4 0x252000)
$(poke 0x623064 0x252100)"

# Constant struct fields. EMPTY bbox (m+0x1828 huge) forces phase-2 entry for any ball. goal anchor x =
# goal_target_x(orient=1, x=0x100000, team=0): (1&1)=1 != team 0 -> NOT negated -> +0x100000.
CONST="$(poke 0x23018c 0x260000);$(poke 0x230190 0x280000);$(poke 0x2302b8 0)
$(poke 0x261820 0x100000);$(poke 0x2619a0 1);$(poke 0x261828 0x7f000000)"

# Trajectory grid: slot i (0x17..0x23) at ball + 0xc*i. grid[i].x = goalx + 0x30000*(i-0x16) so D2.x =
# 0x30000*(i-0x16) (0x30000..0x270000 -- low slots take the MulDiv num>0 path, high slots the num=0
# clamp). grid[i].y = 0x8000 (a real atan/polar angle); grid[i].z = 0.
GRID=""
for i in $(seq 23 35); do          # 0x17..0x23
  base=$(( i * 12 ))
  gx=$(( 0x100000 + 0x30000 * (i - 22) ))
  GRID+="$(poke $(( 0x280000 + base )) "$gx");$(poke $(( 0x280000 + base + 4 )) 0x8000);$(poke $(( 0x280000 + base + 8 )) 0);"
done

# Banked: the composed steer target (x,y,z) + brackets, to confirm the stack slot.
READS="
read_mem 0x00307fb8 4
read_mem 0x00307fbc 4
read_mem 0x00307fc0 4
read_mem 0x00307fc4 4
read_mem 0x00307fc8 4
read_mem 0x00307fcc 4
"

# name|pokes  (ball.pos + ball.vel per fixture; bbox always fails -> phase 2)
FIX=(
  # sector ~0: near ball, fast velocity -> low slot (0x17), MulDiv num>0 path.
  "sectorlo|$(poke 0x280004 0x110000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x80000);$(poke 0x280024 0)"
  # sector clamp 0xc: far ball, zero velocity (dot2+1=1) -> high slot (0x23), MulDiv num=0 clamp.
  "sectorclamp|$(poke 0x280004 0x280000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0);$(poke 0x280024 0)"
  # mid sector: moderate dot1, unit-ish velocity.
  "sectormid|$(poke 0x280004 0x1c0000);$(poke 0x280008 0);$(poke 0x28000c 0);$(poke 0x280020 0x10000);$(poke 0x280024 0)"
  # angled D1 + D2: diagonal ball position & velocity -> nonzero atan, exercises the x,y & 0xffffc000 mask.
  "angled|$(poke 0x280004 0x180000);$(poke 0x280008 0x80000);$(poke 0x28000c 0);$(poke 0x280020 0x20000);$(poke 0x280024 0x10000)"
)

emit_spec() {  # $1=pokes
  {
    cat <<EOF
entry   0x005b05a0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX 0x00230000
zero    0x00230000 0x00001000
zero    0x00260000 0x00002000
zero    0x00280000 0x00002000
maxsteps 2000000
stub    0x005a89c0 0 8 steer
EOF
    cat "$LUT"
    printf '%s\n' "$THUNKS"
    printf '%s\n' "${CONST//;/$'\n'}"
    printf '%s\n' "${GRID//;/$'\n'}"
    printf '%s\n' "${1//;/$'\n'}"
    printf '%s\n' "$READS"
  } > "$SPEC"
}

run_emu() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
}

bank() {  # $1=name
  local line kv
  line=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  kv=$(echo "$line" | grep -oE 'mem\[0x[0-9a-f]+:4\]=[0-9-]+' | sed -E 's/mem\[(0x[0-9a-f]+):4\]=/\1=/' | tr '\n' ' ')
  local hit; if echo "$line" | grep -q 'stubhits=.*steer'; then hit=1; else hit=0; fi
  echo "B05A0P2 $1 steer=$hit | $kv" >> "$OUT"
  echo "[$1] $(echo "$line" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+') steer=$hit"
}

: > "$OUT"
echo "# Oracle FUN_005b05a0 PHASE 2 (sector-grid approach steer). 5a89c0 stubbed; target read off stack." >> "$OUT"
echo "# Row: B05A0P2 <name> steer=<0|1> | <abs-addr>=<u32 LE> ... . target.xyz @ 0x307fc0/c4/c8." >> "$OUT"
for row in "${FIX[@]}"; do
  IFS='|' read -r NAME POKES <<<"$row"
  emit_spec "$POKES"
  run_emu
  bank "$NAME"
done
echo "=== b05a0 phase2 oracle -> $OUT ==="
cat "$OUT"
