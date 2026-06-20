#!/usr/bin/env bash
# Stage 3 task 2 (post narrow-phase): drive the REAL FUN_005efac0 through the Ghidra PCode emulator and
# bank the hit flag + clipped pos + reflected vel + deflect that Pm98Movement._post_narrow must reproduce
# (app/tests/test_postnarrow.gd).
#
# The post is an oriented quad: corners post+0..+0x2c (4x3 int32), orientation dir post+0x48 (boxgeo),
# post+0x54 = id-AND-restitution. Args (thiscall this=post): boxgeo=post+0x48, pos, radius=0x23d7, vel,
# post_id, &out. It mutates pos (param_3) + vel (param_5) on hit and writes a 2-int deflect to out.
#
# FIXTURE DESIGN: boxgeo = +X so ang_z=ang_y=0 (no rotation -> the quad is axis-aligned in local space).
# The winding-test edge interpolation then only ever calls MulDiv with a 0 first arg (Δz==0 on every
# crossing edge), so the kernel32 MulDiv import (IAT 0x623064, uncallable in-emu) is stubbed to `xor eax;
# ret 0xc` -- exact for these fixtures. _ftol @0x252000 (reflect fsqrt) + cos LUT injected. This pins the
# swept test, the axis-aligned winding, the pos-clip and the reflect; the rotation path is pinned
# separately by test_rotvec, and the tilted-quad MulDiv interpolation by _muldiv vs the Win32 spec.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/postnarrow_oracle.txt
SPEC=$SPECDIR/_postnarrow_run.spec
ROUT=$SPECDIR/_postnarrow_run.out
LUT=$SPECDIR/_postnarrow_lut.txt

python3 tools/re/emit_lut_membts.py > "$LUT"

POST=0x230000; POSV=0x240000; VELV=0x240010; OUTV=0x240020
poke() { printf 'mem 0x%08x 4 0x%08x' "$1" $(( $2 & 0xffffffff )); }

# emit_spec  PX PY PZ  VX VY VZ  ID
emit_spec() {
  {
    cat <<EOF
entry   0x5efac0
ret     0x00100000
stack   0x00300000 0x00010000 0x00308000
reg     ECX $POST
zero    0x00230000 0x00001000
zero    0x00240000 0x00001000
maxsteps 2000000
membts 0x00252000 83EC08D93C248B042480CC0C6689442404D96C2404DB542404D92C248B44240483C408C3
membts 0x00252100 33C0C20C00
mem 0x006233a4 4 0x00252000
mem 0x00623064 4 0x00252100
mem 0x006d31c4 1 0x0
EOF
    # post quad corners c0..c3 (a rectangle in the world YZ plane at x=0)
    poke $((POST + 0x00)) 0x0;       echo; poke $((POST + 0x04)) -0x40000; echo; poke $((POST + 0x08)) 0x0;      echo
    poke $((POST + 0x0c)) 0x0;       echo; poke $((POST + 0x10)) 0x40000;  echo; poke $((POST + 0x14)) 0x0;      echo
    poke $((POST + 0x18)) 0x0;       echo; poke $((POST + 0x1c)) 0x40000;  echo; poke $((POST + 0x20)) 0x40000;  echo
    poke $((POST + 0x24)) 0x0;       echo; poke $((POST + 0x28)) -0x40000; echo; poke $((POST + 0x2c)) 0x40000;  echo
    poke $((POST + 0x48)) 0x10000;   echo; poke $((POST + 0x4c)) 0x0;      echo; poke $((POST + 0x50)) 0x0;      echo
    poke $((POST + 0x54)) "$7";      echo
    poke $((POSV + 0)) "$1"; echo; poke $((POSV + 4)) "$2"; echo; poke $((POSV + 8)) "$3"; echo
    poke $((VELV + 0)) "$4"; echo; poke $((VELV + 4)) "$5"; echo; poke $((VELV + 8)) "$6"; echo
    cat "$LUT"
    printf 'arg 0x%08x\n' $((POST + 0x48))
    printf 'arg 0x%08x\n' $((POSV))
    printf 'arg 0x000023d7\n'
    printf 'arg 0x%08x\n' $((VELV))
    printf 'arg 0x%08x\n' $(( $7 & 0xffffffff ))
    printf 'arg 0x%08x\n' $((OUTV))
    printf 'read_mem 0x%08x 4\n' $((POSV)); printf 'read_mem 0x%08x 4\n' $((POSV + 4)); printf 'read_mem 0x%08x 4\n' $((POSV + 8))
    printf 'read_mem 0x%08x 4\n' $((VELV)); printf 'read_mem 0x%08x 4\n' $((VELV + 4)); printf 'read_mem 0x%08x 4\n' $((VELV + 8))
    printf 'read_mem 0x%08x 4\n' $((OUTV)); printf 'read_mem 0x%08x 4\n' $((OUTV + 4))
  } > "$SPEC"
}

mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
: > "$OUT"
echo "# Stage 3 task 2 post narrow-phase (FUN_005efac0) PCode-emu truth. axis-aligned quad (boxgeo +X)." >> "$OUT"
echo "# MulDiv import stubbed ret 0 (exact: Δz==0 on every crossing edge). reads: pos +0/4/8, vel +0/4/8, out +0/4. EAX=hit." >> "$OUT"
# name      PX         PY         PZ        VX        VY    VZ    ID
MATRIX=(
  "hit_mid   -0x20000   -0x20000   0x20000   0x40000   0x0   0x0   0x9eb8"
  "miss_hi   -0x20000   -0x20000   0x60000   0x40000   0x0   0x0   0x9eb8"
  "miss_lowy -0x20000   -0x50000   0x20000   0x40000   0x0   0x0   0x9eb8"
  "hit_cross -0x20000    0x10000   0x30000   0x40000   0x0   0x0   0x7ae1"
  "miss_away -0x20000   -0x20000   0x20000  -0x40000   0x0   0x0   0x9eb8"
)
for row in "${MATRIX[@]}"; do
  read -r NAME PX PY PZ VX VY VZ ID <<<"$row"
  emit_spec "$PX" "$PY" "$PZ" "$VX" "$VY" "$VZ" "$ID"
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  L=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)
  echo "FIX $NAME $L" >> "$OUT"
  echo "[$NAME] hit=$(echo "$L" | grep -oE 'EAX=[0-9-]+' | cut -d= -f2) px=$(mval "$L" 0x240000) vx=$(mval "$L" 0x240010) out0=$(mval "$L" 0x240020) $(echo "$L" | grep -oE 'CALL 0 (RET|HALT)')"
done
echo "=== post-narrow oracle -> $OUT ==="
cat "$OUT"
