#!/usr/bin/env python3
"""Read live MANAGER.EXE memory through winedbg's gdb proxy (raw RSP `m` packets).

Why this exists: this box runs `kernel.yama.ptrace_scope = 1`, so `/proc/<pid>/mem` --
what `dump_mem.py` uses -- is unreadable for a wine process the current session did not
spawn. winedbg does the reading instead, so a career left running by an earlier session
stays inspectable (and survives: this detaches with `D` rather than killing the target).

    export WINEPREFIX=<repo>/.wineprefix DISPLAY=:2
    WPID=$(bash wdbg_pid.sh | cut -d\' \' -f1)
    winedbg --gdb --no-start --port 12345 "$WPID" &
    python3 rsp_read.py 12345 652a10:4 66afd0:8

Prints one line per request: the address then the little-endian dwords. Used 2026-07-24
to read DAT_00652a10 out of a live career and settle the stat-commit cadence
(docs/re/stat_commit_cadence_re.md).
"""

import re
import socket
import sys
import time


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
            try:
                return self._read_packet(1.0)
            except TimeoutError:
                continue
        raise TimeoutError(payload)


def main() -> None:
    port = int(sys.argv[1])
    r = Rsp(port)
    r.cmd("?")
    for spec in sys.argv[2:]:
        addr, ln = spec.split(":")
        a = int(addr, 16)
        n = int(ln)
        raw = r.cmd(f"m{a:x},{n:x}")
        if raw.startswith("E"):
            print(f"{a:#010x} ERROR {raw}")
            continue
        b = bytes.fromhex(raw)
        dwords = [int.from_bytes(b[i : i + 4], "little") for i in range(0, len(b) - 3, 4)]
        print(f"{a:#010x} " + " ".join(f"{d:#010x}" for d in dwords))
    r.cmd("D", timeout=5)


main()
