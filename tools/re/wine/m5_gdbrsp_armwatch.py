#!/usr/bin/env python3
"""Raw gdb-remote (RSP) client: seed watch PLUS per-stop ACT/ARM-counter dumps.

Usage: m5_gdbrsp_armwatch.py <port> <lpid> <match_base_hex> <out.jsonl> [stop_clk] [win_lo] [win_hi]

s35 variant for the kickoff arm-timing skew (handoff-pm98-m5-dart209-posdrift NEXT-1):
the port's taker t0.i9 exits the act-4 kick anim at clk 13 and ramps immediately;
silicon holds placement through clk 19 and ramps from clk 20 (same entry tick — the
phase-2 gate roll is draw-identical). To see WHICH transition differs, this dumps every
player's (x, y, +0x40 act, +0x2c frame, +0x30 subtick, +0x48 windup, +0x54/+0x58
power, +0x80/+0x84 motion timers, +0x34 facing, +0x64 yaw, +0x68 speed, +0x6c curve)
at each seed-watch stop while win_lo <= clk <= win_hi
(default 0..25 — clk 0 alone spans ~24 engine ticks / ~63 stops, so the intra-clk-0
evolution is visible per stop). Player arrays: u32(base+0x46c)/u32(base+0x78c), stride
0x3bc. Same RSP gotchas as the seedwatch — capture first, the game dies on detach.
"""

import json
import struct
import sys

from m5_gdbrsp_seedwatch import SEED_VA, Rsp  # same stub procedure

PLAYER_STRIDE = 0x3BC


def main() -> None:
    port, lpid, base = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3], 16)
    out = sys.argv[4]
    stop_clk = int(sys.argv[5]) if len(sys.argv) > 5 else 26
    win_lo = int(sys.argv[6]) if len(sys.argv) > 6 else 0
    win_hi = int(sys.argv[7]) if len(sys.argv) > 7 else 25
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)  # noqa: SIM115 — held for process life
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl, closed at exit

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def i32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<i", mem.read(4))[0]

    teams = []
    for off in (0x46C, 0x78C):
        arr = u32(base + off)
        cnt = u32(base + off + 4)
        teams.append((arr, min(cnt, 16)))
    fo.write(
        json.dumps({"event": "teams", "arrays": [{"base": hex(a), "count": c} for a, c in teams]})
        + "\n"
    )

    def players_row() -> list:
        rows = []
        for ti, (arr, cnt) in enumerate(teams):
            for i in range(cnt):
                va = arr + i * PLAYER_STRIDE
                rows.append(
                    [
                        ti,
                        i,
                        i32(va + 4),
                        i32(va + 8),
                        i32(va + 0x40),
                        i32(va + 0x2C),
                        i32(va + 0x30),
                        i32(va + 0x48),
                        i32(va + 0x54),
                        i32(va + 0x58),
                        i32(va + 0x80),
                        i32(va + 0x84),
                        u32(va + 0x34) & 0xFFFF,
                        u32(va + 0x64) & 0xFFFF,
                        i32(va + 0x68),
                        i32(va + 0x6C),
                    ]
                )
        return rows

    r = Rsp(port)
    st = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": st}) + "\n")
    ok = r.cmd(f"Z2,{SEED_VA:x},4")
    fo.write(json.dumps({"event": "Z2", "reply": ok, "watch_addr": hex(SEED_VA)}) + "\n")
    if ok != "OK":
        print(f"Z2 REJECTED: {ok!r}", file=sys.stderr)
        sys.exit(1)

    def t_regs(stx: str) -> dict:
        import re as _re

        o = {}
        for m in _re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", stx):
            o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return o

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    print(f"ARMED arm watch @{SEED_VA:#x} win=[{win_lo},{win_hi}] — click KICK OFF now", flush=True)
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
        clk = u32(base + 0x450)
        try:
            ret0 = u32(esp)
        except OSError:
            ret0 = 0
        row = {"stop": stops, "eip": hex(eip), "ret0": hex(ret0), "clk": clk, "seed": u32(SEED_VA)}
        if win_lo <= clk <= win_hi and eip != 0x5EC255:  # skip the entry-load twin stop
            row["pl"] = players_row()
        fo.write(json.dumps(row) + "\n")
        if clk > stop_clk or stops >= 20000:
            fo.write(json.dumps({"event": "done", "stops": stops, "clk": clk}) + "\n")
            break
        cont()

    try:
        r.cmd(f"z2,{SEED_VA:x},4", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach, game must survive
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE stops={stops} -> {out}", flush=True)


if __name__ == "__main__":
    main()
