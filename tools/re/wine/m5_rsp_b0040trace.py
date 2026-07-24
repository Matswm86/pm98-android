#!/usr/bin/env python3
"""s54: trace live silicon's FUN_005b0040 interception bisection for ONE player.

Usage: m5_rsp_b0040trace.py <port> <lpid> <ref_json> <out.jsonl> [team] [idx] [arm_clk] [stop_clk]

WHY. s53 closed every routing question: the b1420 arm (B0040), the call chain (`0x5a8eee`),
the steer ORDER and the once-per-tick guard are all identical in port and silicon, and the
heading argument silicon hands FUN_005a8f20 forks at exactly one tick — 9258 through clk 638,
then 771/767/765, where the port hands 34076/34078. s54 then showed the b0040 INPUTS are
byte-identical live (player pos, ball pos/vel/face 1854, the 16 marker slots, and
`curve_rate`: the captured `P+0x6c = 6457` IS the 89c0 formula at scale 0x5a on the port's
13429/2739/4251), and the real `FUN_005b0040` decompile has NO extra branch and NO clamp of
`ticks`. So the last measurable unknown is the LOOP ITSELF: what `lead` / `nd` ladder does
silicon actually run, and what target does it hand FUN_005a89c0?

This is the "compare the intermediate lead, not the final point" capture.

Trace points (disasm 0x5b0040 / 0x5b0285-0x5b032b / 0x5b0480-0x5b04c6):
  0x5b0040  entry, ECX = `this`      -> gate every other stop on OUR player
  0x5b0312  MOV EBX,EAX (loop tail)  -> EAX = new lead, EBX = lead going in, ECX = nd
  0x5b04a6  post-loop                -> [ESP+0x28/0x2c/0x30] = the PRE-clamp point
  0x5b04c1  PUSH 0x5a                -> EAX = FUN_005b1330's clamped point pointer
Also banked once per b0040 call: `P+0x70/0x3a8/0x3ac` (the live curve_rate terms) and the
clamp box `M+0x1828..0x183c`, neither of which any previous capture carried.

Same stub rules as m5_rsp_steer8f20.py: ONE connection, never remove a watchpoint mid-run,
capture first — the game is expendable afterwards.
"""

import json
import os
import re
import struct
import sys
from pathlib import Path

from m5_gdbrsp_seedwatch import SEED_VA, Rsp

B0040_ENTRY = 0x005B0040
B0040_ITER = 0x005B0312
B0040_POST = 0x005B04A6
B0040_CALL = 0x005B04C1
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


def main() -> None:  # noqa: C901 — one linear capture script; splitting hides the RSP order
    port, lpid, ref_path, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], sys.argv[4]
    team = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    idx = int(sys.argv[6]) if len(sys.argv) > 6 else 10
    arm_clk = int(sys.argv[7]) if len(sys.argv) > 7 else 636
    stop_clk = int(sys.argv[8]) if len(sys.argv) > 8 else 643

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

    def i32(addr: int) -> int:
        return struct.unpack("<i", mread(addr, 4))[0]

    def w32(addr: int, v: int) -> None:
        if r.cmd(f"M{addr:x},4:{struct.pack('<I', v & 0xFFFFFFFF).hex()}") != "OK":
            raise OSError(f"w32 {addr:#x}")

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    # ---- 1. base ----
    base = 0
    for cand in (0x03DBF240, 0x03DBF228, 0x03DBF0D8, 0x03DBF060, 0x03DCF1D0):
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

    # ---- 2. frame0 poke + XI check ----
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
        f"reached clk {u32(base + 0x450)} after {stops} stops — arming the b0040 trace", flush=True
    )

    # ---- 4. arm the four b0040 trace points. Do NOT remove the Z2 (removing a watchpoint
    # while stopped on it kills winedbg's gdbproxy, s53) — its traps are filtered by EIP.
    for va in (B0040_ENTRY, B0040_ITER, B0040_POST, B0040_CALL):
        if r.cmd(f"Z1,{va:x},1") != "OK":
            print(f"Z1 {va:#x} REJECTED", flush=True)
            sys.exit(1)
    fo.write(json.dumps({"event": "armed_b0040", "clk": u32(base + 0x450)}) + "\n")
    cont()

    calls = iters = 0
    active = False  # inside OUR player's FUN_005b0040
    k = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        rg = t_regs(st)
        eip, eax, ecx, ebx, esp = (
            rg.get(8, 0),
            rg.get(0, 0),
            rg.get(1, 0),
            rg.get(3, 0),
            rg.get(4, 0),
        )
        clk = u32(base + 0x450)

        if eip == B0040_ENTRY:
            active = ecx == pva
            k = 0
            if active:
                calls += 1
                pb = mread(pva, 0x3B0)
                ball = u32(pva + 0x190)
                bb = mread(ball, 0xE4)  # must cover +0xb0/+0xbc and the +0xcc..+0xe0 marker pair
                box = mread(base + 0x1828, 0x18)
                fo.write(
                    json.dumps(
                        {
                            "ev": "enter",
                            "call": calls,
                            "clk": clk,
                            "who": [team, idx],
                            "pos": list(struct.unpack_from("<iii", pb, 4)),
                            "p70": struct.unpack_from("<i", pb, 0x70)[0],
                            "p3a8": struct.unpack_from("<i", pb, 0x3A8)[0],
                            "p3ac": struct.unpack_from("<i", pb, 0x3AC)[0],
                            "p2bc": struct.unpack_from("<i", pb, 0x2BC)[0],
                            "p34": struct.unpack_from("<I", pb, 0x34)[0] & 0xFFFF,
                            "p68": struct.unpack_from("<i", pb, 0x68)[0],
                            "p6c": struct.unpack_from("<i", pb, 0x6C)[0],
                            "ball_pos": list(struct.unpack_from("<iii", bb, 4)),
                            "ball_vel": list(struct.unpack_from("<iii", bb, 0x20)),
                            "ball_face": struct.unpack_from("<I", bb, 0x34)[0] & 0xFFFF,
                            "ball_40": struct.unpack_from("<I", bb, 0x40)[0],
                            "ball_4c": struct.unpack_from("<I", bb, 0x4C)[0],
                            "ball_74": struct.unpack_from("<i", bb, 0x74)[0],
                            "ball_b0": struct.unpack_from("<i", bb, 0xB0)[0],
                            "ball_bc": struct.unpack_from("<i", bb, 0xBC)[0],
                            "ball_cc": list(struct.unpack_from("<iii", bb, 0xCC)),
                            "ball_d8": list(struct.unpack_from("<iii", bb, 0xD8)),
                            "clamp": list(struct.unpack_from("<iiiiii", box, 0)),
                        }
                    )
                    + "\n"
                )
        elif active and eip == B0040_ITER:
            # MOV EBX,EAX not yet executed: EAX = new lead, EBX = lead going in, ECX = nd.
            k += 1
            iters += 1
            fo.write(
                json.dumps(
                    {
                        "ev": "iter",
                        "call": calls,
                        "clk": clk,
                        "k": k,
                        "lead_in": struct.unpack("<i", struct.pack("<I", ebx))[0],
                        "nd": struct.unpack("<i", struct.pack("<I", ecx))[0],
                        "lead_out": struct.unpack("<i", struct.pack("<I", eax))[0],
                    }
                )
                + "\n"
            )
        elif active and eip == B0040_POST:
            pre = mread(esp + 0x28, 12)
            fo.write(
                json.dumps(
                    {
                        "ev": "post",
                        "call": calls,
                        "clk": clk,
                        "iters": k,
                        "preclamp": list(struct.unpack("<iii", pre)),
                    }
                )
                + "\n"
            )
            # STOP HERE, not on the 0x5b04c1 target stop: winedbg accepted that 4th Z1 but never
            # reported a hit for it (s54), so keying the exit off it runs the capture forever.
            print(f"call {calls} clk={clk} iters={k}", flush=True)
            if clk > stop_clk:
                fo.write(json.dumps({"ev": "done", "calls": calls, "iters": iters}) + "\n")
                break
        elif active and eip == B0040_CALL:
            tgt = mread(eax, 12)
            fo.write(
                json.dumps(
                    {
                        "ev": "target",
                        "call": calls,
                        "clk": clk,
                        "target": list(struct.unpack("<iii", tgt)),
                    }
                )
                + "\n"
            )
            active = False
        cont()

    try:  # capture is on disk by here — do NOT remove breakpoints first (see step 4)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE calls={calls} iters={iters} -> {out}", flush=True)


if __name__ == "__main__":
    main()
