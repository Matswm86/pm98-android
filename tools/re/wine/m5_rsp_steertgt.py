#!/usr/bin/env python3
"""RSP-only steer-target + ball-input capture for one player (s38 NEXT-1, no /proc, no sudo).

Usage: m5_rsp_steertgt.py <port> <ref_json> <out.jsonl> [team] [idx] [stop_clk]

ptrace_scope=1-safe successor of m5_gdbrsp_steertgt.py: every memory access goes over the
winedbg --gdb stub (m/M packets after Hg — see m5_rsp_bpcapture.py). Run at the KICK OFF
screen. Flow:
  1. Z1 on the outer step FUN_005983f0 — first hit (fires during the pre-kickoff pause)
     gives ecx = match base; verify vtable+scale; remove bp.
  2. Poke the capture2 frame-0 scalars + LCG seed (m5_poke_frame0 --apply semantics) and
     XI-check the roster vs the ref (injury rolls can swap a starter → abort).
  3. Z1 on FUN_005a89c0 (steer dispatcher, __thiscall ECX=player). At every hit where
     ECX == the target player's VA: dump ret0 (caller leaf), the steer target [esp+4]→
     3 ints, speed scale [esp+8], the player block (pos/act/frame/sub/speed/face/yaw/
     curve/13c/140/144/148), and the BALL block (pos/vel/face/ctrl/recv/rest/traj head).
     Other hits just continue. Exit once clk > stop_clk.
The kick tick spans clk 0-1, so stop_clk=4 covers the whole arm window (s36-s38).
"""

import json
import re
import struct
import sys

from m5_gdbrsp_seedwatch import SEED_VA, Rsp

STEP_VA = 0x005983F0
STEER_VA = 0x005A89C0
VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}
PLAYER_STRIDE = 0x3BC


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def t_regs(stx: str) -> dict:
    o = {}
    for m in re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", stx):
        o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
    return o


def main() -> None:
    port, ref_path, out = int(sys.argv[1]), sys.argv[2], sys.argv[3]
    team = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    idx = int(sys.argv[5]) if len(sys.argv) > 5 else 9
    stop_clk = int(sys.argv[6]) if len(sys.argv) > 6 else 4
    ref = json.load(open(ref_path))
    fo = open(out, "a", buffering=1)  # noqa: SIM115

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

    # ---- base: candidates (same boot+nav reproduces the heap), then scan fallback.
    # NOTE the step-bp base grab (Z1 @0x5983f0) is DEAD: the outer step does not run
    # during the KICK OFF pause and arming it across the click crashed the stub
    # (winedbg exit 5, 2026-07-18). Run this at the frozen KICK OFF screen instead.
    base = 0
    for cand in (0x03DBF0D8, 0x03DBF060):
        try:
            if u32(cand) == VTABLE and u32(cand + SCALE_OFF) == SCALE_VAL:
                base = cand
                break
        except OSError:
            continue
    if not base:
        needle = struct.pack("<I", VTABLE)
        for start, end in ((0x03B10000, 0x03DE0000), (0x03520000, 0x03720000)):
            a = start
            while a < end and not base:
                try:
                    data = mread(a, 0x200)
                except OSError:
                    break
                i = data.find(needle)
                while i != -1:
                    if u32(a + i + SCALE_OFF) == SCALE_VAL:
                        base = a + i
                        break
                    i = data.find(needle, i + 1)
                a += 0x200 - 4
            if base:
                break
    if not base:
        print("NO BASE", flush=True)
        sys.exit(1)
    print(f"BASE {base:#010x}", flush=True)

    # ---- poke + XI ----
    for off_s, ref_v in ref["match"].items():
        off = int(off_s, 16)
        live_v = u32(base + off)
        if live_v == (ref_v & 0xFFFFFFFF) or off in SKIP or (looks_ptr(ref_v) and looks_ptr(live_v)):
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
        k = "0x%x" % off
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
    if xi_bad:
        print(f"XI MISMATCH {len(xi_bad)} {xi_bad} — abort (re-roll the boot)", flush=True)
        sys.exit(2)
    print("XI OK", flush=True)

    pva = teams[team][0] + idx * PLAYER_STRIDE
    ball = u32(base + 0x46C)  # placeholder; real ball = base+0x1610 embedded
    ball = base + 0x1610
    fo.write(json.dumps({"event": "cfg", "base": hex(base), "pva": hex(pva), "ball": hex(ball)}) + "\n")

    # ---- steer bp + capture ----
    if r.cmd(f"Z1,{STEER_VA:x},1") != "OK":
        print("Z1 steer REJECTED", flush=True)
        sys.exit(1)
    print(f"ARMED steer-watch t{team}.i{idx} va={pva:#x} — click KICK OFF", flush=True)
    cont()
    hits = 0
    rows = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        hits += 1
        rg = t_regs(st)
        ecx = rg.get(1, 0)
        esp = rg.get(4, 0)
        clk = u32(base + 0x450)
        if ecx == pva:
            stk = mread(esp, 12)
            ret0 = struct.unpack_from("<I", stk, 0)[0]
            tgt_ptr = struct.unpack_from("<I", stk, 4)[0]
            scale = struct.unpack_from("<i", stk, 8)[0]
            tgt = None
            if 0x00010000 <= tgt_ptr <= 0x7FFFFFFF:
                try:
                    tgt = struct.unpack("<iii", mread(tgt_ptr, 12))
                except OSError:
                    tgt = None
            pb = mread(pva, 0x1F0)
            bb = mread(ball, 0x120)
            row = {
                "hit": hits,
                "clk": clk,
                "seed": u32(SEED_VA),
                "ret0": hex(ret0),
                "scale": scale,
                "phase": u32(base + 0x448),
                "f461": u32(base + 0x460) >> 8 & 0xFF,
                "m444": hex(u32(base + 0x444)),
                "tgt_ptr": hex(tgt_ptr),
                "target": list(tgt) if tgt else None,
                "p": {
                    "pos": list(struct.unpack_from("<iii", pb, 4)),
                    "act": struct.unpack_from("<i", pb, 0x40)[0],
                    "frm": struct.unpack_from("<i", pb, 0x2C)[0],
                    "sub": struct.unpack_from("<i", pb, 0x30)[0],
                    "face": struct.unpack_from("<I", pb, 0x34)[0] & 0xFFFF,
                    "yaw": struct.unpack_from("<I", pb, 0x64)[0] & 0xFFFF,
                    "spd": struct.unpack_from("<i", pb, 0x68)[0],
                    "curve": struct.unpack_from("<i", pb, 0x6C)[0],
                    "s13c": struct.unpack_from("<i", pb, 0x13C)[0],
                    "s140": struct.unpack_from("<i", pb, 0x140)[0],
                },
                "ball": {
                    "pos": list(struct.unpack_from("<iii", bb, 4)),
                    "vel": list(struct.unpack_from("<iii", bb, 0x20)),
                    "face": struct.unpack_from("<I", bb, 0x34)[0] & 0xFFFF,
                    "ctrl": struct.unpack_from("<I", bb, 0x40)[0],
                    "recv": struct.unpack_from("<I", bb, 0x4C)[0],
                    "rest": list(struct.unpack_from("<iii", bb, 0x84)),
                    "traj0": list(struct.unpack_from("<iii", bb, 0x114)),
                },
            }
            fo.write(json.dumps(row) + "\n")
            rows += 1
        if hits % 500 == 0:
            print(f"hit {hits} clk={clk} rows={rows}", flush=True)
        if clk > stop_clk:
            fo.write(json.dumps({"event": "done", "hits": hits, "rows": rows, "clk": clk}) + "\n")
            break
        cont()

    try:
        r.cmd(f"z1,{STEER_VA:x},1", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — capture already on disk
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE hits={hits} rows={rows} -> {out}", flush=True)


if __name__ == "__main__":
    main()
