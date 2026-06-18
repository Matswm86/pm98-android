#!/usr/bin/env python3
"""Emit PcodeEmu `membts` directives injecting the EXACT trig LUTs into emulator
memory, so Stage-3 movement functions (which only READ 0x6d31c8 / 0x6d71c8) can be
oracle-emulated WITHOUT computing fcos. Ground truth: tools/re/specs/{cos,atan}_lut.txt
(banked from the real x87 fcos/fpatan, tools/re/lut_oracle.c)."""
import struct, pathlib
spec = pathlib.Path(__file__).parent / "specs"
cos = [int(x) for x in (spec / "cos_lut.txt").read_text().split()]
atan = [int(x) for x in (spec / "atan_lut.txt").read_text().split()]
assert len(cos) == 4096 and len(atan) == 8193
cos_bytes = b"".join(struct.pack("<i", v) for v in cos)          # 4096 * int32
atan_bytes = b"".join(struct.pack("<h", v & 0xffff) for v in atan)  # 8193 * int16
print(f"membts 0x6d31c8 {cos_bytes.hex()}")
print(f"membts 0x6d71c8 {atan_bytes.hex()}")
