#!/usr/bin/env python3
"""Build MANAGER_HACK.EXE — "three forwards = the keeper cannot save, and you always
get at least three chances a half" patch for the PM98 statistical (BRIEF/RESULT) engine.

Trigger: the attacking XI contains >= 3 players whose ROLE byte (participant +0xcc,
sourced from player+0x1c) is 3 = ATT/FOR. Evaluated per side, per chance, off the live
match struct, so it follows your team selection with no save-file edits.

Effects when the trigger holds for a side:
  1. `FUN_0044ee70` H1/H2 chance count for that side is floored at 3 (the stock cap
     `3 - rand()%3` is still computed first, and still consumes its rand draws, so a
     non-triggering side behaves bit-identically to the stock binary).
  2. `FUN_0044ece0` skips the defending keeper's save gate entirely for that side's
     chances, so every chance becomes a goal.
Net: a triggering side scores >= 3 per half (>= 6 a match) in a Brief/Result sim.

NOT patched: the extra-time loops (`FUN_0044ee70` @0x450100+, cup ties only) and the
positional/WATCH engine. Both sides are treated alike: an AI team fielding 3 forwards
gets the same buff.

Patch mechanism: five 5-byte E9 hooks into a code cave in the .text raw-size slack
(VA 0x622847, file 0x221c47, 441 zero bytes before .rdata). Nothing is relocated, the
image layout is untouched, and every hook site's original bytes are asserted first.

Usage:
    build_hack_exe.py [SRC_EXE] [DST_EXE]
    (defaults: $PM98_PLAY_PREFIX/drive_c/PM98/MANAGER.EXE -> MANAGER_HACK.EXE beside it)
"""

from __future__ import annotations

import os
import struct
import sys
from pathlib import Path

_PREFIX = os.environ.get("PM98_PLAY_PREFIX", str(Path.home() / "pm98/wineprefix-play"))
DEFAULT_SRC = Path(_PREFIX) / "drive_c/PM98/MANAGER.EXE"

IMAGE_BASE = 0x400000
TEXT_VA = 0x401000
TEXT_OFF = 0x400
CAVE_VA = 0x622847  # end of .text virtual size
CAVE_OFF = 0x221C47  # == CAVE_VA - TEXT_VA + TEXT_OFF
CAVE_LIMIT = 0x221E00 - CAVE_OFF  # 441 bytes to the start of .rdata raw

# --- hook sites (verified against MANAGER.EXE 2026-07-26) --------------------
# Each entry: (cap-block start VA, VA to resume at = loop init, side)
CHANCE_SITES = [
    ("h1_side0", 0x44F802, 0x44F836, 0),
    ("h1_side1", 0x44F899, 0x44F8CD, 1),
    ("h2_side0", 0x44FB16, 0x44FB4A, 0),
    ("h2_side1", 0x44FBB7, 0x44FBEB, 1),
]
CAP_HEAD = bytes.fromhex("ffd38d0440")  # call *ebx ; lea eax,[eax+eax*2]

KEEPER_HOOK_VA = 0x44ED04  # cmpw $0x0,0x88(%edx,%ebx,1)
KEEPER_HOOK_ORIG = bytes.fromhex("6683bc1a88000000")  # first 8 of the 9-byte cmpw
KEEPER_SKIP_VA = 0x44ED49  # scorer roulette (= the "no save" path)
KEEPER_RESUME_VA = 0x44ED12  # mov 0xc0(%eax),%al (normal save path)

SIDE_STRIDE = 0x7A0
P_SEL = 0x88  # participant +0x88 u16 shirt (0 = not in XI)
P_ROLE = 0xCC  # participant +0xcc i32 role (3 = ATT)
P_STRIDE = 0xAC
ROLE_ATT = 3
MIN_FORWARDS = 3
CHANCE_FLOOR = 3


class Asm:
    """Two-pass byte assembler with labels, for the cave."""

    def __init__(self, base_va: int) -> None:
        self.base_va = base_va
        self.buf = bytearray()
        self.labels: dict[str, int] = {}
        self.fixups: list[tuple[int, str, str]] = []  # (pos, label, kind)

    def label(self, name: str) -> None:
        self.labels[name] = len(self.buf)

    def db(self, data: bytes | str) -> None:
        self.buf += bytes.fromhex(data) if isinstance(data, str) else data

    def rel8(self, opcode: str, label: str) -> None:
        self.db(opcode)
        self.fixups.append((len(self.buf), label, "rel8"))
        self.buf += b"\x00"

    def rel32(self, opcode: str, label: str) -> None:
        self.db(opcode)
        self.fixups.append((len(self.buf), label, "rel32"))
        self.buf += b"\x00\x00\x00\x00"

    def abs_jmp(self, opcode: str, target_va: int) -> None:
        """opcode + rel32 to an absolute VA outside the cave."""
        self.db(opcode)
        pos = len(self.buf)
        self.buf += b"\x00\x00\x00\x00"
        rel = target_va - (self.base_va + pos + 4)
        struct.pack_into("<i", self.buf, pos, rel)

    def resolve(self) -> bytes:
        for pos, label, kind in self.fixups:
            if label not in self.labels:
                raise KeyError(f"undefined label {label}")
            if kind == "rel8":
                rel = self.labels[label] - (pos + 1)
                if not -128 <= rel <= 127:
                    raise ValueError(f"rel8 out of range for {label}: {rel}")
                struct.pack_into("<b", self.buf, pos, rel)
            else:
                rel = self.labels[label] - (pos + 4)
                struct.pack_into("<i", self.buf, pos, rel)
        return bytes(self.buf)

    def va(self, label: str) -> int:
        return self.base_va + self.labels[label]


def build_cave() -> tuple[bytes, dict[str, int]]:
    a = Asm(CAVE_VA)

    # ---- att3: in EAX = team base ptr. Out: flags of `cmp ecx, MIN_FORWARDS`.
    # Counts selected (SEL != 0) participants whose ROLE == ATT. Preserves EBX/EDX/ESI/EDI.
    a.label("att3")
    a.db("53")  # push ebx
    a.db("33c9")  # xor ecx,ecx
    a.db("bb0b000000")  # mov ebx,11
    a.label("att3_loop")
    a.db("6683b8" + struct.pack("<I", P_SEL).hex() + "00")  # cmpw [eax+0x88],0
    a.rel8("74", "att3_next")  # je next
    a.db("83b8" + struct.pack("<I", P_ROLE).hex() + f"{ROLE_ATT:02x}")  # cmpl [eax+0xcc],3
    a.rel8("75", "att3_next")  # jne next
    a.db("41")  # inc ecx
    a.label("att3_next")
    a.db("05" + struct.pack("<I", P_STRIDE).hex())  # add eax,0xac
    a.db("4b")  # dec ebx
    a.rel8("75", "att3_loop")  # jnz loop
    a.db("5b")  # pop ebx
    a.db(f"83f9{MIN_FORWARDS:02x}")  # cmp ecx,3
    a.db("c3")  # ret

    # ---- captrig: in EAX = side offset (0 / 0x7a0). Replays the stock chance cap on ESI
    # (same rand draws, same order), then floors ESI at 3 when the side has 3+ forwards.
    a.label("captrig")
    a.db("50")  # push eax            (side offset)
    a.db("ffd3")  # call ebx           rand()
    a.db("8d0440")  # lea eax,[eax+eax*2]
    a.db("99")  # cdq
    a.db("81e2ff7f0000")  # and edx,0x7fff
    a.db("03c2")  # add eax,edx
    a.db("c1f80f")  # sar eax,0xf        -> rand()%3
    a.db("b903000000")  # mov ecx,3
    a.db("2bc8")  # sub ecx,eax        -> cap = 3 - rand%3
    a.db("3bf1")  # cmp esi,ecx
    a.rel8("7e", "captrig_capped")  # jle capped
    a.db("ffd3")  # call ebx           rand()  (the stock re-draw)
    a.db("8d0440")  # lea eax,[eax+eax*2]
    a.db("99")  # cdq
    a.db("81e2ff7f0000")  # and edx,0x7fff
    a.db("03c2")  # add eax,edx
    a.db("c1f80f")  # sar eax,0xf
    a.db("be03000000")  # mov esi,3
    a.db("2bf0")  # sub esi,eax        -> esi = 3 - rand%3
    a.label("captrig_capped")
    a.db("8b45e8")  # mov eax,[ebp-0x18]  match ptr
    a.db("030424")  # add eax,[esp]       + side offset
    a.rel32("e8", "att3")  # call att3
    a.rel8("7c", "captrig_done")  # jl done   (< 3 forwards)
    a.db(f"83fe{CHANCE_FLOOR:02x}")  # cmp esi,3
    a.rel8("7d", "captrig_done")  # jge done
    a.db("be" + struct.pack("<I", CHANCE_FLOOR).hex())  # mov esi,3
    a.label("captrig_done")
    a.db("58")  # pop eax
    a.db("c3")  # ret

    # ---- per-site stubs: set the side offset, run captrig, rejoin the stock loop init.
    for name, _hook_va, resume_va, side in CHANCE_SITES:
        a.label(f"stub_{name}")
        a.db("b8" + struct.pack("<I", side * SIDE_STRIDE).hex())  # mov eax,sideoff
        a.rel32("e8", "captrig")  # call captrig
        a.abs_jmp("e9", resume_va)  # jmp loop init

    # ---- keeper gate: skip the save roll when the ATTACKING side has 3+ forwards.
    # On entry (from 0x44ed04): EBX = match, ESI = attacking side, EDX = defending side offset.
    a.label("kcave")
    a.db("52")  # push edx
    a.db("8bc6")  # mov eax,esi
    a.db("69c0" + struct.pack("<I", SIDE_STRIDE).hex())  # imul eax,eax,0x7a0
    a.db("03c3")  # add eax,ebx          attacking team base
    a.rel32("e8", "att3")  # call att3
    a.db("5a")  # pop edx              (POP does not touch flags)
    a.rel8("7c", "kcave_normal")  # jl normal   (< 3 forwards)
    a.abs_jmp("e9", KEEPER_SKIP_VA)  # jmp scorer roulette == no save
    a.label("kcave_normal")
    a.db("6683bc1a88000000" + "00")  # cmpw $0x0,0x88(%edx,%ebx,1)   [displaced]
    a.db("8d041a")  # lea eax,[edx+ebx]             [displaced]
    a.abs_jmp("0f84", KEEPER_SKIP_VA)  # je  0x44ed49                 [displaced]
    a.abs_jmp("e9", KEEPER_RESUME_VA)  # jmp 0x44ed12

    code = a.resolve()
    return code, {k: a.base_va + v for k, v in a.labels.items()}


def va_to_off(va: int) -> int:
    return va - TEXT_VA + TEXT_OFF


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SRC
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else src.with_name("MANAGER_HACK.EXE")
    data = bytearray(src.read_bytes())

    cave, labels = build_cave()
    if len(cave) > CAVE_LIMIT:
        raise SystemExit(f"cave overflow: {len(cave)} > {CAVE_LIMIT}")
    if any(data[CAVE_OFF : CAVE_OFF + CAVE_LIMIT]):
        raise SystemExit("cave slack is not zero — refusing to overwrite real bytes")
    data[CAVE_OFF : CAVE_OFF + len(cave)] = cave

    # chance-count hooks
    for name, hook_va, _resume, _side in CHANCE_SITES:
        off = va_to_off(hook_va)
        if bytes(data[off : off + 5]) != CAP_HEAD:
            raise SystemExit(f"{name}: unexpected bytes at {hook_va:#x}: {data[off:off+5].hex()}")
        rel = labels[f"stub_{name}"] - (hook_va + 5)
        data[off : off + 5] = b"\xe9" + struct.pack("<i", rel)

    # keeper-gate hook
    off = va_to_off(KEEPER_HOOK_VA)
    if bytes(data[off : off + 8]) != KEEPER_HOOK_ORIG:
        raise SystemExit(f"keeper: unexpected bytes at {KEEPER_HOOK_VA:#x}: {data[off:off+8].hex()}")
    rel = labels["kcave"] - (KEEPER_HOOK_VA + 5)
    data[off : off + 5] = b"\xe9" + struct.pack("<i", rel)

    # The cave sits past .text's VirtualSize (0x221847) but inside its SizeOfRawData
    # (0x221a00). A loader is free to zero that tail, so grow VirtualSize to the raw size;
    # .text's page-rounded span (0x223000) is unchanged, so .rdata and SizeOfImage stand.
    pe = struct.unpack_from("<I", data, 0x3C)[0]
    sec0 = pe + 24 + struct.unpack_from("<H", data, pe + 20)[0]
    if data[sec0 : sec0 + 5] != b".text":
        raise SystemExit("section 0 is not .text")
    vsize, _va, rawsize, _ptr = struct.unpack_from("<IIII", data, sec0 + 8)
    if vsize < rawsize:
        struct.pack_into("<I", data, sec0 + 8, rawsize)
        print(f".text VirtualSize {vsize:#x} -> {rawsize:#x}")

    dst.write_bytes(bytes(data))
    print(f"wrote {dst} ({len(data)} bytes)")
    print(f"cave {len(cave)}/{CAVE_LIMIT} bytes at VA {CAVE_VA:#x} (file {CAVE_OFF:#x})")
    for k, v in labels.items():
        print(f"  {k:<18} {v:#x}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
