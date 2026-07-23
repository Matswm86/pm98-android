#!/usr/bin/env python3
"""Stub-free free-run roster capture: poke frame0, then poll /proc/<lpid>/mem to JSONL.

Usage: m5_freerun_poll.py <lpid> <frame0_ref.json> <out.jsonl> [stop_clk] [base_hex]

The ptrace_scope=0 counterpart to m5_rsp_capture.py: NO winedbg stub, NO per-draw Z2
stops (both of which repeatedly killed the capture at clk 124/588). All memory access is
direct /proc/<lpid>/mem (needs kernel.yama.ptrace_scope=0 so Yama permits the same-uid
read of wine's double-forked-to-PPid-1 process). Run while the game sits at the KICK OFF
screen (phase 2, clock frozen):
  1. verify the match base (vtable 0x6390e0 @ +0, scale 14400 @ +0x19ac); candidate first
     (s34's 0x03dbf0d8/0x03dbf060), else scan the rw heap window.
  2. poke frame0 ref scalars + LCG seed (m5_poke_frame0 --apply semantics: skip structural
     offsets + ptr-looking pairs) and re-verify; XI fidelity check (abort on injury reroll).
  3. print ARMED; the operator clicks KICK OFF; the sim free-runs while this polls the seed
     as fast as it can and dumps the full 22-player roster + ball on every seed change (the
     orbit differ aligns samples by seed ordinal, so this need not catch every draw).
Exit when clk > stop_clk, the process dies, or the idle wall-clock guard trips.
"""

import json
import struct
import sys
import time
from pathlib import Path

VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
SEED_VA = 0x006D3184
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}
PLAYER_STRIDE = 0x3BC
PBLOB = 0x184  # covers x/y (+4/+8), +0x13c, +0x17c/+0x180, and the s45 mover tail
IDLE_GUARD_S = 300.0  # bail if no seed advance for this long (missed / failed KICK OFF)


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def main() -> None:
    lpid = int(sys.argv[1])
    ref_path = sys.argv[2]
    out = sys.argv[3]
    stop_clk = int(sys.argv[4]) if len(sys.argv) > 4 else 735
    cand = [int(sys.argv[5], 16)] if len(sys.argv) > 5 else []
    cand += [0x03DBF0D8, 0x03DBF060]  # s34: same boot+nav reproduces one of these

    with open(ref_path) as fh:
        ref = json.load(fh)
    mem = open(f"/proc/{lpid}/mem", "r+b", buffering=0)  # noqa: SIM115 — held for run
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def w32(addr: int, v: int) -> None:
        mem.seek(addr)
        mem.write(struct.pack("<I", v & 0xFFFFFFFF))

    # ---- 1. base ----
    base = 0
    for c in cand:
        try:
            if u32(c) == VTABLE and u32(c + SCALE_OFF) == SCALE_VAL:
                base = c
                break
        except OSError:
            continue
    if not base:
        needle = struct.pack("<I", VTABLE)
        spans = []
        for line in Path(f"/proc/{lpid}/maps").read_text().splitlines():
            addr, perms = line.split()[0], line.split()[1]
            start, end = (int(x, 16) for x in addr.split("-"))
            if perms.startswith("rw") and start < (1 << 32) and end - start <= 0x4000000:
                spans.append((start, end))
        spans.sort(key=lambda s: (not (0x03000000 <= s[0] < 0x05000000), s[0]))
        for start, end in spans:
            try:
                mem.seek(start)
                data = mem.read(end - start)
            except OSError:
                continue
            i = data.find(needle)
            while i != -1:
                b0 = start + i
                try:
                    if u32(b0 + SCALE_OFF) == SCALE_VAL:
                        base = b0
                        break
                except OSError:
                    pass
                i = data.find(needle, i + 1)
            if base:
                break
    if not base:
        print("NO BASE", flush=True)
        fo.write(json.dumps({"event": "no_base"}) + "\n")
        sys.exit(1)
    fo.write(json.dumps({"event": "base", "base": hex(base)}) + "\n")
    print(f"BASE {base:#010x}", flush=True)

    # ---- 2. poke frame0 + seed ----
    ref_seed = ref["meta"]["seed_0x6d3184"]
    poked, skipped = [], []
    for off_s, ref_v in ref["match"].items():
        off = int(off_s, 16)
        live_v = u32(base + off)
        if live_v == (ref_v & 0xFFFFFFFF):
            continue
        if off in SKIP or (looks_ptr(ref_v) and looks_ptr(live_v)):
            skipped.append(off)
            continue
        w32(base + off, ref_v)
        poked.append(off)
    w32(SEED_VA, ref_seed)
    post = sum(
        1 for off_s, v in ref["match"].items() if u32(base + int(off_s, 16)) == (v & 0xFFFFFFFF)
    )
    fo.write(
        json.dumps(
            {
                "event": "poke",
                "post_match": post,
                "total": len(ref["match"]),
                "poked": [hex(o) for o in poked],
                "skipped": [hex(o) for o in skipped],
                "seed": hex(u32(SEED_VA)),
            }
        )
        + "\n"
    )
    print(f"POKE {post}/{len(ref['match'])} seed={u32(SEED_VA):#010x}", flush=True)

    teams = []
    for off in (0x46C, 0x78C):
        teams.append((u32(base + off), min(u32(base + off + 4), 11)))
    fo.write(json.dumps({"event": "teams", "arrays": [[hex(a), c] for a, c in teams]}) + "\n")

    # ---- 2b. XI fidelity (injury reroll swaps a starter -> different match) ----
    def ref_pf(src: dict, off: int) -> int:
        k = f"0x{off:x}"
        if k in src:
            return int(src[k]) & 0xFFFFFFFF
        return int(src.get("dwords", {}).get(k, 0)) & 0xFFFFFFFF

    xi_bad = []
    for ti, (arr, cnt) in enumerate(teams):
        refs = ref["players"][ti]
        for i in range(min(cnt, len(refs))):
            mem.seek(arr + i * PLAYER_STRIDE)
            b = mem.read(PLAYER_STRIDE)
            for off in (0x4, 0x8, 0x2C8, 0x37C, 0x380):
                live_v = struct.unpack_from("<I", b, off)[0]
                if live_v != ref_pf(refs[i], off):
                    xi_bad.append([ti, i, hex(off), hex(live_v), hex(ref_pf(refs[i], off))])
    fo.write(json.dumps({"event": "xi_check", "mismatches": xi_bad}) + "\n")
    print(f"XI {'OK' if not xi_bad else f'MISMATCH {len(xi_bad)} rows'}", flush=True)
    if xi_bad:
        print("XI MISMATCH — reroll the boot", flush=True)
        sys.exit(2)

    def players_row() -> list:
        rows = []
        for ti, (arr, cnt) in enumerate(teams):
            mem.seek(arr)
            blk = mem.read(PLAYER_STRIDE * cnt)  # whole team array in one read
            for i in range(cnt):
                o = i * PLAYER_STRIDE
                rows.append(
                    [
                        ti,
                        i,
                        struct.unpack_from("<i", blk, o + 4)[0],
                        struct.unpack_from("<i", blk, o + 8)[0],
                        struct.unpack_from("<I", blk, o + 0x13C)[0],
                        struct.unpack_from("<i", blk, o + 0x17C)[0],
                        struct.unpack_from("<i", blk, o + 0x180)[0],
                        struct.unpack_from("<I", blk, o + 0x34)[0] & 0xFFFF,
                        struct.unpack_from("<I", blk, o + 0x64)[0] & 0xFFFF,
                        struct.unpack_from("<i", blk, o + 0x68)[0],
                        struct.unpack_from("<i", blk, o + 0x6C)[0],
                        struct.unpack_from("<i", blk, o + 0x54)[0],
                        struct.unpack_from("<i", blk, o + 0x58)[0],
                    ]
                )
        return rows

    def ball_row() -> list:
        mem.seek(base + 0x1610)
        b = mem.read(0x60)
        return [
            struct.unpack_from("<i", b, 0x4)[0],
            struct.unpack_from("<i", b, 0x8)[0],
            struct.unpack_from("<i", b, 0xC)[0],
            struct.unpack_from("<i", b, 0x20)[0],
            struct.unpack_from("<i", b, 0x24)[0],
            struct.unpack_from("<i", b, 0x28)[0],
            struct.unpack_from("<I", b, 0x34)[0] & 0xFFFF,
            struct.unpack_from("<I", b, 0x40)[0],
            struct.unpack_from("<I", b, 0x4C)[0],
            struct.unpack_from("<i", b, 0x54)[0],
            struct.unpack_from("<i", b, 0x58)[0],
            struct.unpack_from("<i", b, 0x5C)[0],
        ]

    # ---- 3. free-run poll ----
    print(f"ARMED stop_clk={stop_clk} — click KICK OFF now", flush=True)
    last_seed = None
    n = 0
    rows = 0
    torn = 0
    t0 = time.time()
    last_adv = t0
    while True:
        try:
            seed = u32(SEED_VA)
            clk = u32(base + 0x450)
        except OSError:
            fo.write(json.dumps({"event": "process_gone", "rows": rows}) + "\n")
            break
        n += 1
        if seed != last_seed:
            # ATOMICITY: the sim free-runs while we read ~8.5KB of roster, so a naive
            # sample pairs an early seed with later positions (torn -> phantom forks from
            # clk 2). Re-read the seed/clock after the roster and keep the sample ONLY if
            # nothing advanced mid-read; otherwise drop it and try again next poll.
            pl = players_row()
            ball = ball_row()
            try:
                seed2 = u32(SEED_VA)
                clk2 = u32(base + 0x450)
            except OSError:
                continue
            if seed2 != seed or clk2 != clk:
                torn += 1
                continue
            fo.write(json.dumps({"clk": clk, "seed": seed, "pl": pl, "ball": ball}) + "\n")
            last_seed = seed
            rows += 1
            last_adv = time.time()
            if rows % 500 == 0:
                print(f"rows={rows} clk={clk} torn={torn} seed={seed:#010x}", flush=True)
        if clk > stop_clk:
            fo.write(
                json.dumps({"event": "done", "rows": rows, "polls": n, "torn": torn, "clk": clk})
                + "\n"
            )
            print(f"DONE rows={rows} polls={n} torn={torn} clk={clk}", flush=True)
            break
        if time.time() - last_adv > IDLE_GUARD_S:
            fo.write(json.dumps({"event": "idle_timeout", "rows": rows, "clk": clk}) + "\n")
            print(f"IDLE TIMEOUT clk={clk} (KICK OFF not clicked?)", flush=True)
            break
    fo.close()


if __name__ == "__main__":
    main()
