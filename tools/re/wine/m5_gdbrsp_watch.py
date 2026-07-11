#!/usr/bin/env python3
"""Raw gdb-remote (RSP) client for winedbg --gdb: HW write-watch to NAME the t1 mover.

Usage: m5_gdbrsp_watch.py <port> <lpid> <match_base_hex> <out.jsonl> [stop_clk] [pidx]

Why this exists: interactive winedbg's `watch *<addr>` is unusable on a no-debug-info
target in wine-9.0 (an integer constant has no pointer type -> "No type or type
mismatch"; casts like `(int*)` fail silently), but the SAME i386 debug-register
backend is reachable through winedbg's gdb proxy via the Z2 packet. So: the caller
starts `winedbg --gdb --no-start --port <port> 0xWPID` (attach = target stopped),
this client connects and speaks minimal RSP — Z2 write-watchpoint on
t1.i<pidx>.x (resolved live from match_base+0x78c; the heap arrays move between
runs), `c`, then the caller clicks KICK OFF. Each stop reply: `g` -> EIP (x86 DR
traps AFTER the store, so eip = the instruction FOLLOWING the write; the containing
function IS the writer), /proc/<lpid>/mem -> clk/phase/seed + player x/y/act +
caller candidates (saved-EBP chain walk + a raw stack scan for text-range return
addresses, since not every 1998-MSVC frame keeps EBP). JSONL per stop; once
clk > stop_clk: z2 remove, D detach — the game must survive.
"""

import json
import re
import socket
import struct
import sys
import time

SEED_VA = 0x006D3184
T1_HDR = 0x78C
STRIDE = 0x3BC
TEXT_LO, TEXT_HI = 0x00401000, 0x00640000  # MANAGER.EXE code range for retaddr scan
MAX_STOPS = 20000  # phase-2 placement alone burns ~500 stops of per-frame rewrites


class Rsp:
    def __init__(self, port: int):
        self.s = socket.create_connection(("127.0.0.1", port), timeout=30)
        self.buf = b""

    def _read_packet(self, timeout: float) -> str:
        self.s.settimeout(timeout)
        while True:
            m = re.search(rb"\$([^#]*)#[0-9a-fA-F]{2}", self.buf)
            if m:
                self.buf = self.buf[m.end() :]
                self.s.sendall(b"+")
                return m.group(1).decode()
            chunk = self.s.recv(4096)
            if not chunk:
                raise ConnectionError("stub closed")
            self.buf += chunk

    def cmd(self, payload: str, timeout: float = 30) -> str:
        pkt = f"${payload}#{sum(payload.encode()) % 256:02x}".encode()
        self.s.sendall(pkt)
        # consume ack '+' (retransmit on '-') interleaved before the reply packet
        deadline = time.time() + timeout
        while time.time() < deadline:
            if b"-" in self.buf.split(b"$")[0]:
                self.buf = self.buf.replace(b"-", b"", 1)
                self.s.sendall(pkt)
            if b"$" in self.buf:
                break
            self.buf = self.buf.lstrip(b"+")
            try:
                self.s.settimeout(min(1.0, deadline - time.time()))
                chunk = self.s.recv(4096)
                if not chunk:
                    raise ConnectionError("stub closed")
                self.buf += chunk
            except TimeoutError:
                continue
        return self._read_packet(max(0.1, deadline - time.time()))

    def wait_stop(self) -> str:
        """Block (no timeout) for the next stop reply after `c`."""
        self.s.settimeout(None)
        while True:
            m = re.search(rb"\$([^#]*)#[0-9a-fA-F]{2}", self.buf)
            if m:
                self.buf = self.buf[m.end() :]
                self.s.sendall(b"+")
                return m.group(1).decode()
            chunk = self.s.recv(4096)
            if not chunk:
                raise ConnectionError("stub closed")
            self.buf += chunk


def main() -> None:
    port, lpid, base = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3], 16)
    out = sys.argv[4]
    stop_clk = int(sys.argv[5]) if len(sys.argv) > 5 else 2
    pidx = int(sys.argv[6]) if len(sys.argv) > 6 else 1
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    fo = open(out, "a", buffering=1)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def s32(addr: int) -> int:
        v = u32(addr)
        return v - 2**32 if v >= 2**31 else v

    t1arr = u32(base + T1_HDR)
    p = t1arr + pidx * STRIDE
    addr = p + 0x4
    fo.write(
        json.dumps({"event": "target", "t1arr": hex(t1arr), "pidx": pidx, "watch_addr": hex(addr)})
        + "\n"
    )

    r = Rsp(port)
    st = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": st}) + "\n")
    ok = r.cmd(f"Z2,{addr:x},4")
    fo.write(json.dumps({"event": "Z2", "reply": ok}) + "\n")
    if ok != "OK":
        print(f"Z2 REJECTED: {ok!r}", file=sys.stderr)
        sys.exit(1)

    def regs() -> list:
        g = r.cmd("g")
        return [
            int.from_bytes(bytes.fromhex(g[i * 8 : i * 8 + 8]), "little")
            for i in range(min(len(g) // 8, 16))
        ]

    def t_regs(st: str) -> dict:
        """wine's gdbproxy expedites ALL registers in the T stop packet
        ("T05thread:...;00:aabbccdd;01:...;08:<eip>;...") — parse them so the hot
        loop needs ZERO extra RSP round trips per stop."""
        out = {}
        for m in re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", st):
            out[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return out

    def callers(ebp: int, esp: int) -> dict:
        chain = []
        fp = ebp
        for _ in range(6):
            if not (0x00010000 < fp < 0x7FFF0000) or fp % 4:
                break
            try:
                ret = u32(fp + 4)
                nfp = u32(fp)
            except OSError:
                break
            if TEXT_LO <= ret <= TEXT_HI:
                chain.append(hex(ret))
            if nfp <= fp:
                break
            fp = nfp
        scan = []
        try:
            mem.seek(esp)
            blob = mem.read(0x60)
            for i in range(0, len(blob) - 3, 4):
                v = struct.unpack_from("<I", blob, i)[0]
                if TEXT_LO <= v <= TEXT_HI:
                    scan.append(hex(v))
        except OSError:
            pass
        return {"ebp_chain": chain, "stack_scan": scan[:8]}

    def cont() -> None:
        # fire-and-forget: the reply IS the next stop packet (wait_stop reads it).
        # MUST be vCont;c — wine's gdbproxy leaves the other threads suspended on a
        # plain `c` (observed: utime frozen, UI dead), real gdb always sends vCont.
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    print(
        f"ARMED watch_addr={addr:#x} (t1arr={t1arr:#x} i{pidx}.x) — sending c; click KICK OFF now",
        flush=True,
    )
    cont()
    stops = 0
    seen = {}
    last_x = last_y = last_clk = last_phase = None
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        stops += 1
        rg = t_regs(st)
        if 8 in rg:
            eip, esp, ebp = rg[8], rg[4], rg[5]
        else:  # fallback: stub didn't expedite regs
            full = regs()
            eip, esp, ebp = full[8], full[4], full[5]
        clk = u32(base + 0x450)
        phase = u32(base + 0x448)
        x, y = s32(addr), s32(addr + 4)
        moved = x != last_x or y != last_y
        fresh = seen.get(eip, 0) < 2 or moved or clk != last_clk or phase != last_phase
        seen[eip] = seen.get(eip, 0) + 1
        last_x, last_y, last_clk, last_phase = x, y, clk, phase
        if fresh:  # full row; repeats of a known same-value rewriter stay 1-line cheap
            row = {
                "stop": stops,
                "eip": hex(eip),
                "clk": clk,
                "phase": phase,
                "seed": u32(SEED_VA),
                "x": x,
                "y": y,
                "act": s32(p + 0x40),
                "moved": moved,
                **callers(ebp, esp),
            }
        else:
            row = {"stop": stops, "eip": hex(eip), "clk": clk, "x": x}
        fo.write(json.dumps(row) + "\n")
        if clk > stop_clk or stops >= MAX_STOPS:
            fo.write(json.dumps({"event": "done", "stops": stops, "clk": clk}) + "\n")
            break
        cont()

    try:
        r.cmd(f"z2,{addr:x},4", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach, game must survive
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE stops={stops} -> {out}", flush=True)


if __name__ == "__main__":
    main()
