#!/usr/bin/env bash
# Stage 3 task 2 (goal/pitch collision-geometry leaves): drive the four PURE vec3/quad
# primitives the collision-geometry builder FUN_005946f0 calls -- through the Ghidra PCode
# emulator -- and bank what each writes. Ground truth for Pm98Trig.vec3_div_scalar /
# quad_copy / vec3_lerp / quad_bilerp (app/tests/test_geomleaf.gd).
#
#   FUN_005a1870  vec3 / scalar       thiscall(this=in,   out, div)              ret 0x8
#   FUN_005a1990  quad copy (12 i32)  thiscall(this=out,  src)                   ret 0x4
#   FUN_005a18a0  vec3 lerp           thiscall(this=a,    out, b, mult, div)     ret 0x10
#   FUN_005a1a30  quad bilinear       thiscall(this=quad, out, m1, m2, d1, d2)   ret 0x18
#       lerp(c3,c2,m1/d1) & lerp(c0,c1,m1/d1) then lerp(those, m2/d2).
#
# All allocator-free: the only callee is FUN_005ee290 (64-bit imul/idiv), native in the
# emu -- so NO LUT, NO import stubs. this @0x200000, out @0x210000, b/src @0x220000.
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/geomleaf_oracle.txt
SPEC=$SPECDIR/_geomleaf_run.spec
ROUT=$SPECDIR/_geomleaf_run.out

THIS=0x00200000; OUTV=0x00210000; BV=0x00220000
poke() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }
run() {
  : > "$ROUT"
  "$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
    -scriptPath tools/re/ghidra_scripts \
    -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
  grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1
}
mval() { echo "$1" | grep -oE "mem\\[$2:[0-9]+\\]=[0-9-]+" | cut -d= -f2 || true; }
hdr() {
  {
    echo "entry   $1"; echo "ret     0x00100000"
    echo "stack   0x00300000 0x00010000 0x00308000"
    echo "reg     ECX $2"
    echo "zero    0x00200000 0x00001000"
    echo "zero    0x00210000 0x00001000"
    echo "zero    0x00220000 0x00001000"
    echo "maxsteps 400000"
  } > "$SPEC"
}

: > "$OUT"
echo "# Stage 3 task 2 goal-collision-geometry leaves PCode-emu truth. cols decimal (int32)." >> "$OUT"
echo "# vec3_div_scalar/quad_copy/vec3_lerp -> out +0/4/8 (+0..0x2c for copy); quad_bilerp -> out +0/4/8." >> "$OUT"

# ---- FUN_005a1870 vec3 / scalar : this=in@THIS, args out=OUTV, div ; read OUTV+0/4/8 ----
div_case() { # name X Y Z DIV
  hdr 0x5a1870 "$THIS"
  { poke $((THIS)) "$2"; poke $((THIS+4)) "$3"; poke $((THIS+8)) "$4"
    printf 'arg %s\n' "$OUTV"; printf 'arg 0x%08x\n' $(( $5 & 0xffffffff ))
    printf 'read_mem %s 4\n' "$OUTV"; printf 'read_mem 0x%08x 4\n' $((OUTV+4)); printf 'read_mem 0x%08x 4\n' $((OUTV+8))
  } >> "$SPEC"
  L=$(run); echo "FIX div_$1 $L" >> "$OUT"
  echo "[div_$1] x=$(mval "$L" 0x210000) y=$(mval "$L" 0x210004) z=$(mval "$L" 0x210008)"
}

# ---- FUN_005a1990 quad copy : this=out@OUTV, arg src=THIS ; read OUTV +0..+0x2c ----
copy_case() { # name  (fills THIS with 12 ramp ints offset by $2)
  hdr 0x5a1990 "$OUTV"
  { for i in $(seq 0 11); do poke $((THIS+4*i)) $(( $2 + i*0x1111 )); done
    printf 'arg %s\n' "$THIS"
    for i in $(seq 0 11); do printf 'read_mem 0x%08x 4\n' $((OUTV+4*i)); done
  } >> "$SPEC"
  L=$(run); echo "FIX copy_$1 $L" >> "$OUT"
  echo "[copy_$1] $(for i in 0 1 2 3 4 5 6 7 8 9 10 11; do printf '%s=%s ' $i "$(mval "$L" $(printf 0x%x $((0x210000+4*i))))"; done)"
}

# ---- FUN_005a18a0 vec3 lerp : this=a@THIS, args out=OUTV, b=BV, mult, div ----
lerp_case() { # name  AX AY AZ  BX BY BZ  MULT DIV
  hdr 0x5a18a0 "$THIS"
  { poke $((THIS)) "$2"; poke $((THIS+4)) "$3"; poke $((THIS+8)) "$4"
    poke $((BV)) "$5"; poke $((BV+4)) "$6"; poke $((BV+8)) "$7"
    printf 'arg %s\n' "$OUTV"; printf 'arg %s\n' "$BV"
    printf 'arg 0x%08x\n' $(( $8 & 0xffffffff )); printf 'arg 0x%08x\n' $(( $9 & 0xffffffff ))
    printf 'read_mem %s 4\n' "$OUTV"; printf 'read_mem 0x%08x 4\n' $((OUTV+4)); printf 'read_mem 0x%08x 4\n' $((OUTV+8))
  } >> "$SPEC"
  L=$(run); echo "FIX lerp_$1 $L" >> "$OUT"
  echo "[lerp_$1] x=$(mval "$L" 0x210000) y=$(mval "$L" 0x210004) z=$(mval "$L" 0x210008)"
}

# ---- FUN_005a1a30 quad bilerp : this=quad@THIS (c0..c3), args out, m1, m2, d1, d2 ----
bilerp_case() { # name  c0x c0y c0z c1x c1y c1z c2x c2y c2z c3x c3y c3z  M1 M2 D1 D2
  hdr 0x5a1a30 "$THIS"
  { for i in $(seq 0 11); do poke $((THIS+4*i)) "${@:$((i+2)):1}"; done
    printf 'arg %s\n' "$OUTV"
    printf 'arg 0x%08x\n' $(( ${14} & 0xffffffff )); printf 'arg 0x%08x\n' $(( ${15} & 0xffffffff ))
    printf 'arg 0x%08x\n' $(( ${16} & 0xffffffff )); printf 'arg 0x%08x\n' $(( ${17} & 0xffffffff ))
    printf 'read_mem %s 4\n' "$OUTV"; printf 'read_mem 0x%08x 4\n' $((OUTV+4)); printf 'read_mem 0x%08x 4\n' $((OUTV+8))
  } >> "$SPEC"
  L=$(run); echo "FIX bilerp_$1 $L" >> "$OUT"
  echo "[bilerp_$1] x=$(mval "$L" 0x210000) y=$(mval "$L" 0x210004) z=$(mval "$L" 0x210008)"
}

# ---- FUN_005efa40 face normal : this=quad@THIS (c0,c1,c2 @ +0..+0x20), arg out=OUTV ----
# Pure: only callee FUN_005ee540 (16.16 cross) is native 64-bit imul/sar -- NO stub/LUT.
fnorm_case() { # name  c0x c0y c0z  c1x c1y c1z  c2x c2y c2z
  hdr 0x5efa40 "$THIS"
  { for i in $(seq 0 8); do poke $((THIS+4*i)) "${@:$((i+2)):1}"; done
    printf 'arg %s\n' "$OUTV"
    printf 'read_mem %s 4\n' "$OUTV"; printf 'read_mem 0x%08x 4\n' $((OUTV+4)); printf 'read_mem 0x%08x 4\n' $((OUTV+8))
  } >> "$SPEC"
  L=$(run); echo "FIX fnorm_$1 $L" >> "$OUT"
  echo "[fnorm_$1] x=$(mval "$L" 0x210000) y=$(mval "$L" 0x210004) z=$(mval "$L" 0x210008)"
}

# ---- FUN_005a1730 broadcast translate : this=in@THIS, args out=OUTV, scalar ----
addsc_case() { # name  X Y Z  S
  hdr 0x5a1730 "$THIS"
  { poke $((THIS)) "$2"; poke $((THIS+4)) "$3"; poke $((THIS+8)) "$4"
    printf 'arg %s\n' "$OUTV"; printf 'arg 0x%08x\n' $(( $5 & 0xffffffff ))
    printf 'read_mem %s 4\n' "$OUTV"; printf 'read_mem 0x%08x 4\n' $((OUTV+4)); printf 'read_mem 0x%08x 4\n' $((OUTV+8))
  } >> "$SPEC"
  L=$(run); echo "FIX addsc_$1 $L" >> "$OUT"
  echo "[addsc_$1] x=$(mval "$L" 0x210000) y=$(mval "$L" 0x210004) z=$(mval "$L" 0x210008)"
}

# ---- FUN_005a1910 aabb init (__fastcall this only) : this=OUTV ; read OUTV +0..+0x14 ----
aabbinit_case() { # name
  hdr 0x5a1910 "$OUTV"
  { for i in $(seq 0 5); do printf 'read_mem 0x%08x 4\n' $((OUTV+4*i)); done; } >> "$SPEC"
  L=$(run); echo "FIX aabbinit_$1 $L" >> "$OUT"
  echo "[aabbinit_$1] $(for i in 0 1 2 3 4 5; do printf '%s=%s ' $i "$(mval "$L" $(printf 0x%x $((0x210000+4*i))))"; done)"
}

# ---- FUN_005a19d0 aabb expand : this=aabb@OUTV (preloaded), arg point=BV ; read OUTV +0..+0x14 ----
aabbexp_case() { # name  minX minY minZ maxX maxY maxZ  pX pY pZ
  hdr 0x5a19d0 "$OUTV"
  { for i in $(seq 0 5); do poke $((OUTV+4*i)) "${@:$((i+2)):1}"; done
    poke $((BV)) "$8"; poke $((BV+4)) "$9"; poke $((BV+8)) "${10}"
    printf 'arg %s\n' "$BV"
    for i in $(seq 0 5); do printf 'read_mem 0x%08x 4\n' $((OUTV+4*i)); done
  } >> "$SPEC"
  L=$(run); echo "FIX aabbexp_$1 $L" >> "$OUT"
  echo "[aabbexp_$1] $(for i in 0 1 2 3 4 5; do printf '%s=%s ' $i "$(mval "$L" $(printf 0x%x $((0x210000+4*i))))"; done)"
}

# ---- FUN_00590be0 copy 6 i32 : this=out@OUTV, arg src=THIS ; read OUTV +0..+0x14 ----
copy6_case() { # name base (THIS gets 6 ramp ints from base, step 0x1111)
  hdr 0x590be0 "$OUTV"
  { for i in $(seq 0 5); do poke $((THIS+4*i)) $(( $2 + i*0x1111 )); done
    printf 'arg %s\n' "$THIS"
    for i in $(seq 0 5); do printf 'read_mem 0x%08x 4\n' $((OUTV+4*i)); done
  } >> "$SPEC"
  L=$(run); echo "FIX copy6_$1 $L" >> "$OUT"
  echo "[copy6_$1] $(for i in 0 1 2 3 4 5; do printf '%s=%s ' $i "$(mval "$L" $(printf 0x%x $((0x210000+4*i))))"; done)"
}

div_case   pos   0x64    0x2710  -0x4d2   0x7
div_case   neg  -0x100000 0x30001 0x1     0x10000
div_case   tz    0x7      -0x7    0x9     0x4      # truncate toward zero both signs
copy_case  a     0x1000
copy_case  b    -0x8000
lerp_case  half  0x0      0x0     0x0     0x20000  0x40000  0x60000  0x1      0x2     # midpoint
lerp_case  third 0x10000 -0x10000 0x4000  0x70000  0x20000 -0x8000   0x1      0x3
lerp_case  off   0x12345  0x6789  -0x4321 -0x55555 0x33333  0x10000  0x5      0x8
bilerp_case mid  0x0 0x0 0x0   0x40000 0x0 0x0   0x40000 0x40000 0x0   0x0 0x40000 0x0   0x1 0x1 0x2 0x2
bilerp_case q    0x10000 0x20000 0x0   0x50000 0x20000 0x4000   0x50000 0x60000 0x8000   0x10000 0x60000 0x2000   0x1 0x2 0x4 0x3
fnorm_case axis  0x0 0x0 0x0   0x10000 0x0 0x0   0x10000 0x10000 0x0          # +Z unit (0,0,0x10000)
fnorm_case arb   0x12345 -0x6789 0x3333   0x40000 0x10000 -0x8000   -0x20000 0x50000 0x12000
addsc_case pos   0x100  -0x200  0x300    0x50
addsc_case neg   0x1000  0x2000 -0x3000 -0x1234
addsc_case wrap  0x7ffffff0 0x0 0x0      0x20      # +0x20 overflows int32 -> negative
aabbinit_case x
aabbexp_case fresh 0x70000000 0x70000000 0x70000000 0x90000000 0x90000000 0x90000000  0x100 -0x200 0x300
aabbexp_case part  0x0 0x0 0x0 0x1000 0x1000 0x1000   -0x50 0x800 0x2000
copy6_case a  0x1000
copy6_case b -0x8000
echo "=== geomleaf oracle -> $OUT ==="
cat "$OUT"
