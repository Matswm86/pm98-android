#!/usr/bin/env bash
# Stage 3 task 2 (item 3): GROUND TRUTH for the goal/pitch collision-geometry BUILDER
# FUN_005946f0 -- the function that fills match+0x17f4 (the post/collider array the headless
# ball physics iterates). It cannot be emu-oracled the naive way because its array-grow
# helper FUN_005bbf10 is a Win32 GlobalAlloc/GlobalReAlloc wrapper (emu-uncallable).
#
# TRICK: pre-point each container's base pointer at a big pre-zeroed SCRATCH region and STUB
# the allocator + element ctors/dtors/color/net-pair as no-ops. FUN_005bbf10 only sets
# *container on the FIRST (zero) alloc and otherwise just reallocs in place, so a no-op stub
# over a sufficiently large scratch buffer reproduces the exact writes -- the +0x17f4 layout
# is identical. Every PURE geometry leaf (lerp/bilerp/quad-copy/div/add/aabb/face-normal) runs
# for REAL (native 64-bit math, no imports), so the post geometry is the binary's, bit-exact.
#
# Stubs (no-op, ret 0): 5bbf10 alloc, 404a80 elem-ctor(ret 0x10), 44cac0, 5963e0/596410/5a1d40
# dtors, 5a1c00 RGB565 color (writes master+0x64, never copied into a post), 5ba7d0 net-pair
# (ret 0x14, runs AFTER +0x17f4 is complete), 5c8f80 ctor-callback.
# Inputs = fixed arbitrary goal dims (parity only -- the GDScript test feeds the SAME dims).
# Output: tools/re/specs/collbuilder_oracle.txt  (master_count, post_count, entity_count,
# then every post's 22 words [corners 0..0x2c, AABB 0x30..0x44, normal 0x48..0x50, id 0x54]).
set -euo pipefail
cd "$(dirname "$0")/../.."
GHIDRA=~/ghidra_12.1.2_PUBLIC/support/analyzeHeadless
SPECDIR=tools/re/specs
OUT=$SPECDIR/collbuilder_oracle.txt
SPEC=$SPECDIR/_collbuilder_run.spec
ROUT=$SPECDIR/_collbuilder_run.out

M=0x00500000                          # match base (ECX)
SA=0x00600000; SB=0x00680000; SC=0x00700000; SD=0x00720000   # scratch: master/posts/entity/netpair
MAXP=64                               # posts to dump (zero-padded beyond the real count)
PSTRIDE=0x58

pk() { printf 'mem 0x%08x 4 0x%08x\n' "$1" $(( $2 & 0xffffffff )); }

{
  echo "entry   0x5946f0"
  echo "ret     0x00100000"
  echo "stack   0x00300000 0x00010000 0x00308000"
  echo "reg     ECX $M"
  echo "maxsteps 30000000"
  # zero regions (applied before mem writes by PcodeEmu)
  echo "zero    $M 0x00008000"
  echo "zero    $SA 0x00040000"
  echo "zero    $SB 0x00020000"
  echo "zero    $SC 0x00010000"
  echo "zero    $SD 0x00010000"
  # container base pointers -> scratch
  pk $((M+0x27c8)) $((SA)); pk $((M+0x17f4)) $((SB)); pk $((M+0x27d0)) $((SC)); pk $((M+0x2ba4)) $((SD))
  # goal-dimension inputs (16.16 fixed; arbitrary-but-fixed, mirrored in test_collbuilder.gd)
  pk $((M+0x194c)) 0x20000
  pk $((M+0x1950)) 0x30000
  pk $((M+0x1954)) 0x40000
  pk $((M+0x1958)) 0x18000
  pk $((M+0x195c)) 0x28000
  pk $((M+0x1960)) 0x12000
  pk $((M+0x1964)) 0x1c000
  pk $((M+0x1968)) 0x22000
  pk $((M+0x196c)) 0x14000
  pk $((M+0x1970)) 0x8000
  pk $((M+0x1974)) 0x10000
  pk $((M+0x1978)) 0xc000
  pk $((M+0x197c)) 0x6000
  pk $((M+0x1820)) 0x90000
  pk $((M+0x1988)) 0x0
  pk $((M+0x1a1b)) 0x0101          # byte +0x1a1b=1 (crossbar), +0x1a1c=1 (net)
  pk $((M+0x1a4c)) 0x5000
  pk $((M+0x27cc)) 0x0             # master count starts 0
  # reads: the three counts, then every post's 22 words
  printf 'read_mem 0x%08x 4\n' $((M+0x27cc))
  printf 'read_mem 0x%08x 4\n' $((M+0x17f8))
  printf 'read_mem 0x%08x 4\n' $((M+0x27d4))
  for ((p=0; p<MAXP; p++)); do
    base=$(( SB + p*PSTRIDE ))
    for ((w=0; w<22; w++)); do printf 'read_mem 0x%08x 4\n' $(( base + w*4 )); done
  done
  # stubs (no-op): allocator + ctors/dtors/color/net-pair
  echo "stub    0x5bbf10 0 0"
  echo "stub    0x404a80 0 16"
  echo "stub    0x44cac0 0 0"
  echo "stub    0x5963e0 0 0"
  echo "stub    0x596410 0 0"
  echo "stub    0x5a1d40 0 0"
  echo "stub    0x5a1c00 0 0"
  echo "stub    0x5ba7d0 0 20"
  echo "stub    0x5c8f80 0 0"
} > "$SPEC"

: > "$ROUT"
"$GHIDRA" ~/ghidra-projects pm98 -process MANAGER.EXE -noanalysis \
  -scriptPath tools/re/ghidra_scripts -postScript PcodeEmu.java "$SPEC" "$ROUT" >/dev/null 2>&1 || true
L=$(grep -E 'CALL 0 (RET|HALT)' "$ROUT" | head -1)

{
  echo "# Stage 3 task 2 item 3: collision-geometry BUILDER FUN_005946f0 ground truth (PCode emu,"
  echo "# allocator/ctor/dtor/color/net-pair stubbed no-op, pure geometry leaves REAL). SB=$SB."
  echo "# inputs: see run_collbuilder_oracle.sh pk() block (mirrored in test_collbuilder.gd)."
  echo "MASTER_COUNT $(echo "$L" | grep -oE "mem\[$(printf 0x%x $((M+0x27cc))):4\]=[0-9-]+" | cut -d= -f2)"
  echo "POST_COUNT   $(echo "$L" | grep -oE "mem\[$(printf 0x%x $((M+0x17f8))):4\]=[0-9-]+" | cut -d= -f2)"
  echo "ENTITY_COUNT $(echo "$L" | grep -oE "mem\[$(printf 0x%x $((M+0x27d4))):4\]=[0-9-]+" | cut -d= -f2)"
  echo "# RUN: $(echo "$L" | grep -oE 'CALL 0 (RET|HALT) steps=[0-9]+')"
  echo "POSTS_BASE $SB"
  # one POST line per post: "POST <idx> w0 w1 ... w21" (unsigned decimal int32)
  for ((p=0; p<MAXP; p++)); do
    base=$(( SB + p*PSTRIDE ))
    row="POST $p"
    for ((w=0; w<22; w++)); do
      v=$(echo "$L" | grep -oE "mem\[$(printf 0x%x $((base+w*4))):4\]=[0-9-]+" | head -1 | cut -d= -f2)
      row="$row ${v:-NA}"
    done
    echo "$row"
  done
} > "$OUT"

echo "=== collbuilder oracle -> $OUT ==="
head -7 "$OUT"
echo "..."
grep -E '^POST (0|29|30|37|38|39) ' "$OUT" | cut -c1-160