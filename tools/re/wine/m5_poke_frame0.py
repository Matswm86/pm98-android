#!/usr/bin/env python3
"""Diff (and optionally poke) the live pre-kickoff match struct against a frame0 reference.

Usage: m5_poke_frame0.py <lpid> <match_base_hex> <frame0_struct_import.json> [--apply]

Reproduces the s28 correct-seed procedure (M5_DIVERGENCE0_KICKOFF.md: "poke seed
0x006d3184 = 0xea0d2a8d + poke 5 pre-match timers/flags to the capture2 frame0 values"):
at the KICK OFF screen (phase 2, clock frozen), diff every match scalar recorded in the
reference frame0 JSON against the live struct, plus the LCG seed. With --apply, poke the
seed and every mismatched NON-POINTER scalar to the reference value.

Pointer-valued fields (live heap VAs — e.g. the benign +0x1a5c of the s28 run, the +0x0
vtable, team-array headers) are NEVER poked: their reference values point into the
REFERENCE run's heap. Heuristic: skip offsets whose ref OR live value looks like a heap
VA (0x00400000..0x7fffffff) when both sides are pointer-like, and always skip the
known-structural offsets in SKIP. The expected end state is the s28 fidelity bar:
"85/86 match scalars + seed" matching, the pointer fields being the residue.

Run it BEFORE m5_poll_traj.py, while the game sits at the KICK OFF screen (the seed does
not advance during that pause — proven by the s28 correct-seed run reproducing the
capture2 first goal at clk 2837).
"""

import json
import struct
import sys

SEED_VA = 0x006D3184
# structural / identity fields that must never be poked:
#   0x0 vtable | 0x46c/0x470 team0 array hdr | 0x78c/0x790 team1 array hdr
#   0x468 session ptr | 0x1a5c heap ptr (benign mismatch in the s28 run)
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def main() -> None:
    lpid, base, ref_path = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    apply = "--apply" in sys.argv[4:]
    ref = json.load(open(ref_path))
    mem = open(f"/proc/{lpid}/mem", "r+b", buffering=0)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def w32(addr: int, v: int) -> None:
        mem.seek(addr)
        mem.write(struct.pack("<I", v & 0xFFFFFFFF))

    ref_seed = ref["meta"]["seed_0x6d3184"]
    live_seed = u32(SEED_VA)
    print(
        f"seed  live={live_seed:#010x} ref={ref_seed:#010x} "
        f"{'MATCH' if live_seed == ref_seed else 'DIFF'}"
    )

    total = 0
    match = 0
    poked = []
    skipped = []
    for off_s, ref_v in ref["match"].items():
        off = int(off_s, 16)
        total += 1
        live_v = u32(base + off)
        if live_v == (ref_v & 0xFFFFFFFF):
            match += 1
            continue
        tag = ""
        if off in SKIP or (looks_ptr(ref_v) and looks_ptr(live_v)):
            tag = "SKIP(ptr/structural)"
            skipped.append(off)
        elif apply:
            w32(base + off, ref_v)
            tag = "POKED"
            poked.append(off)
        else:
            tag = "would poke"
            poked.append(off)
        print(f"  +{off:#06x} live={live_v:#010x} ref={ref_v & 0xFFFFFFFF:#010x} {tag}")

    if apply and live_seed != ref_seed:
        w32(SEED_VA, ref_seed)
        print(f"seed POKED -> {u32(SEED_VA):#010x}")

    # re-verify after poking
    if apply:
        post = sum(
            1
            for off_s, ref_v in ref["match"].items()
            if u32(base + int(off_s, 16)) == (ref_v & 0xFFFFFFFF)
        )
        print(
            f"post-poke: {post}/{total} scalars match "
            f"(skipped ptr/structural: {[hex(o) for o in skipped]})"
        )
    else:
        print(
            f"dry-run: {match}/{total} match, would poke {len(poked)}, "
            f"skip {[hex(o) for o in skipped]}  (add --apply)"
        )


if __name__ == "__main__":
    main()
