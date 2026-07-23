#!/usr/bin/env python3
"""Poke live frame-0 player structs to the oracle reference XI (injury-reroll repair).

Usage: m5_poke_xi.py <lpid> <frame0_ref.json> [base_hex] [--apply]

The preseason injury roll swaps a starter roughly 1 boot in 2, so the live XI stops
matching the capture2 frame0 reference and m5_freerun_poll.py's xi_check aborts. Rather
than re-rolling the whole career (which needs the name-entry keyboard that is unreliable
on a bare Xwayland), poke the offending player's scalars back to the reference values —
the same principle m5_poke_frame0.py already applies to the match struct.

STRUCTURAL offsets are never poked: every player legitimately differs at the four heap
back-pointers (+0x184 team, +0x188 opponent team, +0x18c match, +0x190 session) and the
+0x2dc record pointer (whose misaligned +0x2da alias shows up as a phantom diff). Those
point into THIS run's heap; poking the reference's values would dangle them.

Run at the KICK OFF screen (clock frozen), before m5_freerun_poll.py.
"""

import json
import struct
import sys

PLAYER_STRIDE = 0x3BC
# per-run heap back-pointers + the misaligned alias of the +0x2dc record pointer
STRUCTURAL = {0x184, 0x188, 0x18C, 0x190, 0x2DA, 0x2DC}
VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def main() -> None:
    lpid = int(sys.argv[1])
    with open(sys.argv[2]) as fh:
        ref = json.load(fh)
    base = int(sys.argv[3], 16) if len(sys.argv) > 3 and not sys.argv[3].startswith("--") else 0
    apply = "--apply" in sys.argv

    mem = open(f"/proc/{lpid}/mem", "r+b", buffering=0)  # noqa: SIM115

    def u32(a: int) -> int:
        mem.seek(a)
        return struct.unpack("<I", mem.read(4))[0]

    def w32(a: int, v: int) -> None:
        mem.seek(a)
        mem.write(struct.pack("<I", v & 0xFFFFFFFF))

    if not base:
        base = 0x03DBF0D8
    if not (u32(base) == VTABLE and u32(base + SCALE_OFF) == SCALE_VAL):
        print(f"base {base:#x} does not verify (vtable/scale)", file=sys.stderr)
        sys.exit(1)

    teams = [(u32(base + o), min(u32(base + o + 4), 11)) for o in (0x46C, 0x78C)]
    total_poked = 0
    for ti, (arr, cnt) in enumerate(teams):
        for i in range(cnt):
            p = ref["players"][ti][i]
            fields = {k: v for k, v in p.items() if k.startswith("0x")}
            todo = []
            for k, v in fields.items():
                off = int(k, 16)
                if off in STRUCTURAL:
                    continue
                live = u32(arr + i * PLAYER_STRIDE + off)
                rv = int(v) & 0xFFFFFFFF
                if live == rv:
                    continue
                if looks_ptr(live) and looks_ptr(rv):
                    continue  # unrecorded heap pointer — never poke
                todo.append((off, live, rv))
            if not todo:
                continue
            print(f"team{ti} idx{i}: {len(todo)} scalar diffs")
            for off, live, rv in todo:
                print(f"   +{off:#05x} {live:#010x} -> {rv:#010x}" + ("" if apply else "  (dry)"))
                if apply:
                    w32(arr + i * PLAYER_STRIDE + off, rv)
                    total_poked += 1

    if apply:
        # re-verify: every player should now differ ONLY at the structural offsets
        residue = 0
        for ti, (arr, cnt) in enumerate(teams):
            for i in range(cnt):
                p = ref["players"][ti][i]
                for k, v in p.items():
                    if not k.startswith("0x"):
                        continue
                    off = int(k, 16)
                    if off in STRUCTURAL:
                        continue
                    if u32(arr + i * PLAYER_STRIDE + off) != (int(v) & 0xFFFFFFFF):
                        residue += 1
        print(f"POKED {total_poked}; non-structural residue now {residue}")
    else:
        print("dry-run (add --apply)")


if __name__ == "__main__":
    main()
