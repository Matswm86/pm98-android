"""Recursive-descent function walker over MANAGER.EXE's `.text`.

Why this exists: this image has **no int3 padding between functions** and its linear sweep
desynchronises (s88), so "scan backwards for a prologue" and "disassemble the range" both
fail. The only reliable way to say which function a VA belongs to is to follow control flow
forwards from a known entry and see whether the walk reaches it.

    from funcs import walk, owner_of
    body = walk(pe, 0x4d9a00)            # {va: insn} reachable from that entry
    print(owner_of(pe, 0x4da6a4, entries))

`walk` follows conditional and unconditional jumps inside `.text`, stops at `ret`/`retn`,
and does NOT follow `call` (a call leaves the function). Tail `jmp` to a known other entry
is followed only when `follow_tail=True`, because a tail jump into another function's body
would otherwise merge two functions.
"""

from __future__ import annotations

import struct

from capstone import CS_GRP_JUMP, CS_GRP_RET
from capstone.x86 import X86_OP_IMM


def text_section(pe):
    return next(s for s in pe.sections if s.name == ".text")


def call_targets(pe) -> dict[int, list[int]]:
    """{target_va: [call_site_va, ...]} for every direct `E8 rel32` inside `.text`."""
    sec = text_section(pe)
    data = pe.data[sec.foff : sec.foff + sec.size]
    out: dict[int, list[int]] = {}
    for i in range(len(data) - 5):
        if data[i] != 0xE8:
            continue
        rel = struct.unpack_from("<i", data, i + 1)[0]
        site = sec.vma + i
        tgt = site + 5 + rel
        if sec.vma <= tgt < sec.vma + sec.size:
            out.setdefault(tgt, []).append(site)
    return out


def walk(
    pe, entry: int, limit: int = 0x20000, follow_tail: bool = False, entries: set[int] | None = None
) -> dict[int, object]:
    """Reachable instructions of the function at `entry`, keyed by VA."""
    sec = text_section(pe)
    end = sec.vma + sec.size
    seen: dict[int, object] = {}
    todo = [entry]
    while todo:
        va = todo.pop()
        while True:
            if va in seen or not (sec.vma <= va < end) or len(seen) > limit:
                break
            decoded = list(pe.disasm_va(va, 16))
            if not decoded:
                break
            ins = decoded[0]
            seen[ins.address] = ins
            groups = set(ins.groups)
            if CS_GRP_RET in groups or ins.mnemonic == "int3":
                break
            if CS_GRP_JUMP in groups:
                op = ins.operands[0] if ins.operands else None
                if op is not None and op.type == X86_OP_IMM:
                    tgt = op.imm
                    is_tail = entries is not None and tgt in entries and tgt != entry
                    if not is_tail or follow_tail:
                        todo.append(tgt)
                elif ins.mnemonic == "jmp":
                    break  # indirect jmp: switch table, handled by the caller
                if ins.mnemonic == "jmp":
                    break
            va = ins.address + ins.size
    return seen


def owner_of(pe, va: int, entries: list[int]) -> list[int]:
    """Every entry point whose walk reaches `va`. Usually exactly one."""
    hits = []
    for e in entries:
        if e > va:
            continue
        body = walk(pe, e)
        if va in body or any(a <= va < a + i.size for a, i in body.items()):
            hits.append(e)
    return hits
