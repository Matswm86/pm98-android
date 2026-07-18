#!/usr/bin/env python3
"""One-connection RSP capture: base verify/scan + frame0 poke + Z2 seed-watch roster dump.

Usage: m5_rsp_capture.py <port> <lpid> <ref_json> <out.jsonl> [stop_clk] [win_lo] [win_hi] [base_hex]

ptrace_scope=1-safe variant of m5_poke_frame0.py + m5_gdbrsp_dartwatch.py: ALL memory
access goes through the winedbg --gdb stub (wineserver-mediated RSP m/M packets), zero
/proc/<lpid>/mem reads — only /proc/<lpid>/maps (PTRACE_MODE_READ, not Yama-gated) for
the fallback vtable scan. Run at the KICK OFF screen (phase 2, clock frozen):
  1. verify the match base (vtable 0x6390e0 @ +0, scale 14400 @ +0x19ac); candidates
     first (arg / s34's 0x03dbf060), else scan rw regions via RSP.
  2. poke the frame0 ref scalars + LCG seed (m5_poke_frame0 --apply semantics: SKIP
     structural offsets, skip ptr-looking pairs) and re-verify.
  3. arm Z2 on the seed, then per STORE stop (eip != the 0x5ec255 entry-load twin)
     log clk/seed/ret0 and, while win_lo <= clk <= win_hi, all 22 players'
     [team, idx, x, y, +0x13c, +0x17c, +0x180]. Exit once clk > stop_clk.
Same stub gotchas as the seedwatch (see README.md): ONE connection, game dies if the
stub is killed — capture first, the game is expendable after.
"""

import json
import struct
import sys
from pathlib import Path

from m5_gdbrsp_seedwatch import SEED_VA, Rsp

VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}
PLAYER_STRIDE = 0x3BC
PBLOB = 0x184  # covers x/y (+4/+8) and +0x13c/+0x17c/+0x180
STORE_EIP_SKIP = 0x5EC255  # rand() entry LOAD twin stop — not the draw
MAX_STOPS = 40000


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def main() -> None:
    port, lpid, ref_path, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], sys.argv[4]
    stop_clk = int(sys.argv[5]) if len(sys.argv) > 5 else 306
    win_lo = int(sys.argv[6]) if len(sys.argv) > 6 else 0
    win_hi = int(sys.argv[7]) if len(sys.argv) > 7 else 306
    cand = [int(sys.argv[8], 16)] if len(sys.argv) > 8 else []
    cand.append(0x03DBF060)  # s34: same boot+nav reproduced this base 3/3 runs

    ref = json.load(open(ref_path))
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl
    r = Rsp(port)
    status = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": status}) + "\n")
    # winedbg's gdbproxy answers memory ops ONLY after Hg thread selection (probed
    # 2026-07-18: without it, 'm' never replies). Use the stop-status thread.
    import re as _re0

    tm = _re0.search(r"thread:([0-9a-fA-F]+);", status)
    if not tm:
        print(f"NO THREAD in status {status!r}", flush=True)
        sys.exit(1)
    hg = r.cmd(f"Hg{tm.group(1)}")
    fo.write(json.dumps({"event": "Hg", "tid": tm.group(1), "reply": hg}) + "\n")
    if hg != "OK":
        print(f"Hg REJECTED: {hg!r}", flush=True)
        sys.exit(1)

    def mread(addr: int, n: int) -> bytes:
        blob = b""
        while n > 0:
            k = min(n, 0x200)
            rep = r.cmd(f"m{addr:x},{k:x}", timeout=10)
            if not rep or rep.startswith("E"):
                raise OSError(f"mread {addr:#x},{k:#x} -> {rep!r}")
            b = bytes.fromhex(rep)
            blob += b
            addr += len(b)
            n -= len(b)
            if len(b) < k:
                raise OSError(f"short mread @{addr:#x}")
        return blob

    def u32(addr: int) -> int:
        return struct.unpack("<I", mread(addr, 4))[0]

    def w32(addr: int, v: int) -> None:
        rep = r.cmd(f"M{addr:x},4:{struct.pack('<I', v & 0xFFFFFFFF).hex()}")
        if rep != "OK":
            raise OSError(f"w32 {addr:#x} -> {rep!r}")

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
        # the match struct has landed in the 0x03-0x04 heap window every observed boot —
        # scan that neighbourhood first, then the rest
        spans.sort(key=lambda s: (not (0x03000000 <= s[0] < 0x05000000), s[0]))
        for start, end in spans:
            print(f"scan {start:#010x}-{end:#010x}", flush=True)
            a = start
            while a < end and not base:
                try:
                    data = mread(a, min(0x200, end - a))
                except OSError:
                    break
                i = data.find(needle)
                while i != -1:
                    b0 = a + i
                    if u32(b0 + SCALE_OFF) == SCALE_VAL:
                        base = b0
                        break
                    i = data.find(needle, i + 1)
                a += 0x200 - 4  # overlap so a straddling needle is still found
            if base:
                break
    if not base:
        print("NO BASE", flush=True)
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
    fo.write(
        json.dumps({"event": "teams", "arrays": [[hex(a), c] for a, c in teams]}) + "\n"
    )

    # ---- 2b. XI fidelity: live frame-0 players vs the reference (injury rolls between
    # runs can swap a starter -> different match; catch it BEFORE kick off) ----
    def ref_pf(src: dict, off: int) -> int:
        k = "0x%x" % off
        if k in src:
            return int(src[k]) & 0xFFFFFFFF
        return int(src.get("dwords", {}).get(k, 0)) & 0xFFFFFFFF

    xi_bad = []
    for ti, (arr, cnt) in enumerate(teams):
        refs = ref["players"][ti]
        for i in range(min(cnt, len(refs))):
            b = mread(arr + i * PLAYER_STRIDE, PLAYER_STRIDE)
            for off in (0x4, 0x8, 0x2C8, 0x37C, 0x380):
                live_v = struct.unpack_from("<I", b, off)[0]
                if live_v != ref_pf(refs[i], off):
                    xi_bad.append([ti, i, hex(off), hex(live_v), hex(ref_pf(refs[i], off))])
    fo.write(json.dumps({"event": "xi_check", "mismatches": xi_bad}) + "\n")
    print(f"XI {'OK' if not xi_bad else 'MISMATCH %d rows' % len(xi_bad)}", flush=True)

    def players_row() -> list:
        # Row: [team, idx, x, y, +0x13c, +0x17c, +0x180, face+0x34, yaw+0x64, spd+0x68,
        # curve+0x6c, +0x54, +0x58]. The first 7 keep the s44 layout (orbit_diff reads
        # r[0..3] positionally); the s45 tail adds the mover state for the sub-LSB drill.
        rows = []
        for ti, (arr, cnt) in enumerate(teams):
            for i in range(cnt):
                b = mread(arr + i * PLAYER_STRIDE, PBLOB)
                rows.append(
                    [
                        ti,
                        i,
                        struct.unpack_from("<i", b, 4)[0],
                        struct.unpack_from("<i", b, 8)[0],
                        struct.unpack_from("<I", b, 0x13C)[0],
                        struct.unpack_from("<i", b, 0x17C)[0],
                        struct.unpack_from("<i", b, 0x180)[0],
                        struct.unpack_from("<I", b, 0x34)[0] & 0xFFFF,
                        struct.unpack_from("<I", b, 0x64)[0] & 0xFFFF,
                        struct.unpack_from("<i", b, 0x68)[0],
                        struct.unpack_from("<i", b, 0x6C)[0],
                        struct.unpack_from("<i", b, 0x54)[0],
                        struct.unpack_from("<i", b, 0x58)[0],
                    ]
                )
        return rows

    # ---- 3. Z2 seed watch ----
    ok = r.cmd(f"Z2,{SEED_VA:x},4")
    fo.write(json.dumps({"event": "Z2", "reply": ok}) + "\n")
    if ok != "OK":
        print(f"Z2 REJECTED: {ok!r}", flush=True)
        sys.exit(1)

    def t_regs(st: str) -> dict:
        import re as _re

        o = {}
        for m in _re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", st):
            o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return o

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    print(f"ARMED @{SEED_VA:#x} win=[{win_lo},{win_hi}] stop_clk={stop_clk} — click KICK OFF", flush=True)
    cont()
    stops = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        stops += 1
        rg = t_regs(st)
        eip = rg.get(8, 0)
        esp = rg.get(4, 0)
        if eip == STORE_EIP_SKIP:
            cont()
            continue
        clk = u32(base + 0x450)
        try:
            ret0 = u32(esp)
        except OSError:
            ret0 = 0
        row = {"stop": stops, "eip": hex(eip), "ret0": hex(ret0), "clk": clk, "seed": u32(SEED_VA)}
        if win_lo <= clk <= win_hi:
            row["pl"] = players_row()
        fo.write(json.dumps(row) + "\n")
        if stops % 100 == 0:
            print(f"stop {stops} clk={clk}", flush=True)
        if clk > stop_clk or stops >= MAX_STOPS:
            fo.write(json.dumps({"event": "done", "stops": stops, "clk": clk}) + "\n")
            break
        cont()

    try:
        r.cmd(f"z2,{SEED_VA:x},4", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach; capture is already on disk
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE stops={stops} -> {out}", flush=True)


if __name__ == "__main__":
    main()
