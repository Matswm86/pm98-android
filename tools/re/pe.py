"""PM98 MANAGER.EXE static-RE helpers (capstone-based, no display dependency).

Section map (VERIFIED in handoff, re-confirmed at import time against the bytes):
    section  VMA         file off    size
    .text    0x00401000  0x000400    0x221847
    .rdata   0x00623000  0x221e00    0x02e78c
    .data    0x00652000  0x250600    0x015000
    .tls     0x006dd000  0x265600    0x10
    .rsrc    0x006de000  0x265800    0x16c0

VA(.text) = fileoff - 0x400  + 0x401000
VA(.data) = fileoff - 0x250600 + 0x652000
"""
from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path

from capstone import CS_ARCH_X86, CS_MODE_32, Cs

EXE = Path(__file__).resolve().parents[2] / "extracted" / "Premier Manager 98" / "MANAGER.EXE"


@dataclass(frozen=True)
class Section:
    name: str
    vma: int
    foff: int
    size: int

    def has_va(self, va: int) -> bool:
        return self.vma <= va < self.vma + self.size

    def has_foff(self, foff: int) -> bool:
        return self.foff <= foff < self.foff + self.size


class PE:
    def __init__(self, path: Path = EXE):
        self.data = path.read_bytes()
        self.sections = self._parse_sections()
        self.md = Cs(CS_ARCH_X86, CS_MODE_32)
        self.md.detail = True

    def _parse_sections(self) -> list[Section]:
        # Parse the real PE header so VA<->foff is derived from bytes, not hardcoded.
        e_lfanew = struct.unpack_from("<I", self.data, 0x3C)[0]
        assert self.data[e_lfanew : e_lfanew + 4] == b"PE\x00\x00", "not a PE"
        coff = e_lfanew + 4
        n_sec = struct.unpack_from("<H", self.data, coff + 2)[0]
        opt_size = struct.unpack_from("<H", self.data, coff + 16)[0]
        sec_tab = coff + 20 + opt_size
        image_base = struct.unpack_from("<I", self.data, coff + 20 + 28)[0]
        out = []
        for i in range(n_sec):
            off = sec_tab + i * 40
            name = self.data[off : off + 8].rstrip(b"\x00").decode("latin1")
            vsize, vma, rsize, foff = struct.unpack_from("<IIII", self.data, off + 8)
            out.append(Section(name, image_base + vma, foff, min(vsize, rsize) or rsize))
        return out

    def sec_for_va(self, va: int) -> Section | None:
        return next((s for s in self.sections if s.has_va(va)), None)

    def sec_for_foff(self, foff: int) -> Section | None:
        return next((s for s in self.sections if s.has_foff(foff)), None)

    def va_to_foff(self, va: int) -> int:
        s = self.sec_for_va(va)
        if s is None:
            raise ValueError(f"VA {va:#x} not in any section")
        return va - s.vma + s.foff

    def foff_to_va(self, foff: int) -> int:
        s = self.sec_for_foff(foff)
        if s is None:
            raise ValueError(f"foff {foff:#x} not in any section")
        return foff - s.foff + s.vma

    def read_va(self, va: int, n: int) -> bytes:
        f = self.va_to_foff(va)
        return self.data[f : f + n]

    def cstring_at_va(self, va: int, maxlen: int = 256) -> str:
        raw = self.read_va(va, maxlen)
        end = raw.find(b"\x00")
        return raw[: end if end >= 0 else maxlen].decode("latin1", "replace")

    def disasm_va(self, va: int, n_bytes: int):
        """Linear disasm starting at a VA. Yields capstone insns."""
        code = self.read_va(va, n_bytes)
        yield from self.md.disasm(code, va)


if __name__ == "__main__":
    pe = PE()
    print(f"loaded {EXE.name}: {len(pe.data):,} B")
    for s in pe.sections:
        print(f"  {s.name:8} VMA {s.vma:#010x} foff {s.foff:#08x} size {s.size:#08x}")
    # Sanity: the proven anchor string.
    print('VA 0x653e48 =>', repr(pe.cstring_at_va(0x653E48, 32)))
