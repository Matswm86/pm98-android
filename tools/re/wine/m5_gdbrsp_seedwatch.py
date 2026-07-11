#!/usr/bin/env python3
"""Raw gdb-remote (RSP) client for winedbg --gdb: HW write-watch on the LCG SEED global.

Usage: m5_gdbrsp_seedwatch.py <port> <lpid> <match_base_hex> <out.jsonl> [stop_clk]

s33 variant of m5_gdbrsp_watch.py (same stub procedure, same gotchas — see
tools/re/wine/README.md). The watch target is the MSVC-LCG seed at 0x006d3184
(FUN_005ec250's state), so EVERY seed-advancing draw stops the game once. The store
sits inside rand() itself, so the stop EIP is constant; the DRAWING SITE is the return
address at ESP (1998-MSVC rand() has no frame — at the post-store trap, [esp] is the
caller's return address). Rows log eip, ret0=[esp], clk, phase, seed, plus the
ebp-chain/stack-scan caller candidates so bracketed (5ec240/5ec230 save/restore)
cosmetic draws can be told apart from seed-bearing match draws.

Purpose (s33): the port underdraws 1/clk vs the reference during the clk 89-117
ball-in-flight-to-receiver window (ref 2 draws/clk, port 1). This capture names the
second per-clk drawing site in the binary.
"""

import json
import re
import socket
import struct
import sys
import time

SEED_VA = 0x006D3184
TEXT_LO, TEXT_HI = 0x00401000, 0x00640000  # MANAGER.EXE code range for retaddr scan
MAX_STOPS = 20000


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
    stop_clk = int(sys.argv[5]) if len(sys.argv) > 5 else 128
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)  # noqa: SIM115 — held for process life
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl, closed at exit

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    r = Rsp(port)
    st = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": st}) + "\n")
    ok = r.cmd(f"Z2,{SEED_VA:x},4")
    fo.write(json.dumps({"event": "Z2", "reply": ok, "watch_addr": hex(SEED_VA)}) + "\n")
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
        out = {}
        for m in re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", st):
            out[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return out

    def stack_scan(esp: int) -> list:
        scan = []
        try:
            mem.seek(esp)
            blob = mem.read(0x40)
            for i in range(0, len(blob) - 3, 4):
                v = struct.unpack_from("<I", blob, i)[0]
                if TEXT_LO <= v <= TEXT_HI:
                    scan.append(hex(v))
        except OSError:
            pass
        return scan[:6]

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    print(f"ARMED seed watch @{SEED_VA:#x} — sending c; click KICK OFF now", flush=True)
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
        if 8 in rg:
            eip, esp = rg[8], rg[4]
        else:
            full = regs()
            eip, esp = full[8], full[4]
        clk = u32(base + 0x450)
        phase = u32(base + 0x448)
        try:
            ret0 = u32(esp)
        except OSError:
            ret0 = 0
        row = {
            "stop": stops,
            "eip": hex(eip),
            "ret0": hex(ret0),
            "clk": clk,
            "phase": phase,
            "seed": u32(SEED_VA),
            "scan": stack_scan(esp),
        }
        fo.write(json.dumps(row) + "\n")
        if clk > stop_clk or stops >= MAX_STOPS:
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
