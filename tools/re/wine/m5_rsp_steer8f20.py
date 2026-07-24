#!/usr/bin/env python3
"""s53 step 3: dump EVERY live FUN_005a8f20 (steer APPLY) call for one player, with its
once-per-tick guard, over a clock window.

Usage: m5_rsp_steer8f20.py <port> <lpid> <ref_json> <out.jsonl> [team] [idx] [arm_clk] [stop_clk]

Why: s53 proved the b1420 designate `gs+0x204` HOLDS on t1.i10 across the whole fork window,
so live silicon takes the same B0040 arm the port does — yet it applies heading 765 at clk 643
where the port applies 34078. FUN_005a8f20 no-ops when `P+0x2d7` is already 1, so whichever
steer runs FIRST in the tick is the only one that moves the player. The port's order is
`b1420 -> B0040 -> steer_89c0 -> steer_8bc0 -> steer_8f20` FIRST (applied) and engine_tick's
body-orient steer second (no-op). This capture reads the real order off silicon.

Flow (one connection, same stub rules as m5_rsp_capture.py):
  1. base (candidates, then the HOT-band scan) + frame-0 poke + XI check (ABORTS on mismatch —
     a mismatched roster is a different match, see m5_rsp_capture.py).
  2. Z2 on the LCG seed, free-run to `arm_clk` (the cheap way to reach the window: a Z1 on
     0x5a8f20 from kick-off would stop ~30x per tick for 600+ ticks).
  3. drop the Z2, arm Z1 on 0x5a8f20. Per hit: ECX = `this` (the player). For our player,
     log the caller return address [esp], the heading argument [esp+4] (thiscall puts the
     stack arg there at entry), the guard byte P+0x2d7 BEFORE the function writes it, and the
     0x34 / 0x64 / 0x68 / 0x6c state. Every hit is counted per clk so the ORDER is visible.
"""

import json
import os
import re
import struct
import sys
from pathlib import Path

from m5_gdbrsp_seedwatch import SEED_VA, Rsp

STEER_8F20_VA = 0x005A8F20
VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}
PLAYER_STRIDE = 0x3BC
STORE_EIP_SKIP = 0x5EC255
HOT_LO, HOT_HI = 0x03D00000, 0x03E00000


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def t_regs(stx: str) -> dict:
    o = {}
    for m in re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", stx):
        o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
    return o


def main() -> None:  # noqa: C901 — one linear capture script, split would hide the RSP order
    port, lpid, ref_path, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], sys.argv[4]
    team = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    idx = int(sys.argv[6]) if len(sys.argv) > 6 else 10
    arm_clk = int(sys.argv[7]) if len(sys.argv) > 7 else 634
    stop_clk = int(sys.argv[8]) if len(sys.argv) > 8 else 646

    with open(ref_path) as _rf:
        ref = json.load(_rf)
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl
    r = Rsp(port)
    status = r.cmd("?")
    tm = re.search(r"thread:([0-9a-fA-F]+);", status)
    if not tm or r.cmd(f"Hg{tm.group(1)}") != "OK":
        print("Hg/attach FAIL", flush=True)
        sys.exit(1)

    def mread(addr: int, n: int) -> bytes:
        blob = b""
        while n > 0:
            k = min(n, 0x200)
            rep = r.cmd(f"m{addr:x},{k:x}", timeout=10)
            if not rep or rep.startswith("E"):
                raise OSError(f"mread {addr:#x} -> {rep!r}")
            b = bytes.fromhex(rep)
            blob += b
            addr += len(b)
            n -= len(b)
        return blob

    def u32(addr: int) -> int:
        return struct.unpack("<I", mread(addr, 4))[0]

    def w32(addr: int, v: int) -> None:
        if r.cmd(f"M{addr:x},4:{struct.pack('<I', v & 0xFFFFFFFF).hex()}") != "OK":
            raise OSError(f"w32 {addr:#x}")

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    # ---- 1. base ----
    base = 0
    for cand in (0x03DBF228, 0x03DBF0D8, 0x03DBF060):
        try:
            if u32(cand) == VTABLE and u32(cand + SCALE_OFF) == SCALE_VAL:
                base = cand
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
        ranges = [
            (max(s, HOT_LO), min(e, HOT_HI)) for s, e in spans if max(s, HOT_LO) < min(e, HOT_HI)
        ]
        ranges += spans
        for start, end in ranges:
            print(f"scan {start:#010x}-{end:#010x}", flush=True)
            a = start
            while a < end and not base:
                try:
                    data = mread(a, min(0x200, end - a))
                except OSError:
                    break
                i = data.find(needle)
                while i != -1:
                    try:
                        if u32(a + i + SCALE_OFF) == SCALE_VAL:
                            base = a + i
                            break
                    except OSError:
                        pass
                    i = data.find(needle, i + 1)
                a += 0x200 - 4
            if base:
                break
    if not base:
        print("NO BASE", flush=True)
        sys.exit(1)
    print(f"BASE {base:#010x}", flush=True)

    # ---- 2. poke + XI ----
    for off_s, ref_v in ref["match"].items():
        off = int(off_s, 16)
        live_v = u32(base + off)
        if (
            live_v == (ref_v & 0xFFFFFFFF)
            or off in SKIP
            or (looks_ptr(ref_v) and looks_ptr(live_v))
        ):
            continue
        w32(base + off, ref_v)
    w32(SEED_VA, ref["meta"]["seed_0x6d3184"])
    post = sum(
        1 for off_s, v in ref["match"].items() if u32(base + int(off_s, 16)) == (v & 0xFFFFFFFF)
    )
    print(f"POKE {post}/{len(ref['match'])} seed={u32(SEED_VA):#010x}", flush=True)

    teams = []
    for off in (0x46C, 0x78C):
        teams.append((u32(base + off), min(u32(base + off + 4), 11)))

    def ref_pf(src: dict, off: int) -> int:
        k = f"0x{off:x}"
        if k in src:
            return int(src[k]) & 0xFFFFFFFF
        return int(src.get("dwords", {}).get(k, 0)) & 0xFFFFFFFF

    xi_bad = []
    for ti, (arr, cnt) in enumerate(teams):
        refs = ref["players"][ti]
        for i in range(min(cnt, len(refs))):
            for off in (0x4, 0x8, 0x2C8, 0x37C, 0x380):
                live_v = u32(arr + i * PLAYER_STRIDE + off)
                if live_v != ref_pf(refs[i], off):
                    xi_bad.append([ti, i, hex(off), hex(live_v), hex(ref_pf(refs[i], off))])
    fo.write(json.dumps({"event": "xi_check", "mismatches": xi_bad}) + "\n")
    if xi_bad and os.environ.get("PM98_XI_FORCE") != "1":
        print(f"XI MISMATCH {len(xi_bad)} rows — ABORT, re-roll the boot", flush=True)
        sys.exit(2)
    print("XI OK", flush=True)

    pva = teams[team][0] + idx * PLAYER_STRIDE
    va2idx = {}
    for ti, (arr, cnt) in enumerate(teams):
        for i in range(cnt):
            va2idx[arr + i * PLAYER_STRIDE] = [ti, i]
    fo.write(json.dumps({"event": "cfg", "base": hex(base), "pva": hex(pva)}) + "\n")

    # ---- 3. free-run to arm_clk on the seed watch ----
    if r.cmd(f"Z2,{SEED_VA:x},4") != "OK":
        print("Z2 REJECTED", flush=True)
        sys.exit(1)
    print(f"ARMED seed-run to clk {arm_clk} — click KICK OFF", flush=True)
    cont()
    stops = 0
    while True:
        st = r.wait_stop()
        stops += 1
        if t_regs(st).get(8, 0) == STORE_EIP_SKIP:
            cont()
            continue
        clk = u32(base + 0x450)
        if stops % 500 == 0:
            print(f"stop {stops} clk={clk}", flush=True)
        if clk >= arm_clk:
            break
        cont()
    print(
        f"reached clk {u32(base + 0x450)} after {stops} stops — swapping to the 8f20 watch",
        flush=True,
    )

    # ---- 4. arm Z1 on FUN_005a8f20. Do NOT remove the Z2 first: `z2,<seed>,4` while the
    # target sits on a seed trap KILLS winedbg's gdbproxy ("stub closed", cost a full run
    # 2026-07-24). Leaving it armed is free — the seed traps are filtered out by EIP below.
    if r.cmd(f"Z1,{STEER_8F20_VA:x},1") != "OK":
        print("Z1 8f20 REJECTED", flush=True)
        sys.exit(1)
    fo.write(json.dumps({"event": "armed_8f20", "clk": u32(base + 0x450)}) + "\n")
    cont()

    hits = rows = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        rg = t_regs(st)
        eip, ecx, esp = rg.get(8, 0), rg.get(1, 0), rg.get(4, 0)
        if eip != STEER_8F20_VA:  # a seed-watch trap, not a steer call
            cont()
            continue
        hits += 1
        clk = u32(base + 0x450)
        # ORDER matters more than volume: log a light row for EVERY player's call so the
        # position of our player's call(s) within the tick is unambiguous.
        stk = mread(esp, 8)
        row = {
            "hit": hits,
            "clk": clk,
            "who": va2idx.get(ecx),
            "ret0": hex(struct.unpack_from("<I", stk, 0)[0]),
            "heading": struct.unpack_from("<i", stk, 4)[0] & 0xFFFF,
        }
        if ecx == pva:
            pb = mread(pva, 0x2E0)
            row["mine"] = True
            row["guard_before"] = pb[0x2D7]
            row["face"] = struct.unpack_from("<I", pb, 0x34)[0] & 0xFFFF
            row["yaw"] = struct.unpack_from("<I", pb, 0x64)[0] & 0xFFFF
            row["spd"] = struct.unpack_from("<i", pb, 0x68)[0]
            row["curve"] = struct.unpack_from("<i", pb, 0x6C)[0]
            row["pos"] = list(struct.unpack_from("<iii", pb, 4))
            rows += 1
        fo.write(json.dumps(row) + "\n")
        if hits % 200 == 0:
            print(f"8f20 hit {hits} clk={clk} mine={rows}", flush=True)
        if clk > stop_clk:
            fo.write(json.dumps({"event": "done", "hits": hits, "rows": rows, "clk": clk}) + "\n")
            break
        cont()

    try:  # the capture is complete by here — do NOT remove breakpoints first (see step 4)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach; the capture is already on disk
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE hits={hits} mine={rows} -> {out}", flush=True)


if __name__ == "__main__":
    main()
