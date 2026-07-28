"""Read the channelTV fee table straight out of MANAGER.EXE.

Reproduces every row of `docs/re/channeltv_fee_re.md` from the bytes:

  * every write to `club+0x290` in `.text`, decoded PER FUNCTION ENTRY (a linear
    sweep desynchronises on this image's data-in-code and misses half of them --
    that is the bug that left the producer "not found" until 2026-07-28);
  * the league's own jump table at 0x417570, which proves Second and Third share
    one arm;
  * each competition class's `%c:ACTLIGA\\<TAG>%03u.CPT` template, which is what
    names the class a write belongs to;
  * the 200-internal-per-pound conversion, applied last.

Exits non-zero if any expected row is missing, so it doubles as a gate.

    python tools/re/dump_tv_fee_table.py
"""

from __future__ import annotations

import bisect
import re
import struct
import sys

from capstone.x86 import X86_OP_IMM, X86_OP_MEM
from pe import PE
from xref import scan_calls

FIELD = 0x290
MONEY_PER_POUND = 200

# The class blocks, bounded by the CPT-template references that sit inside them.
# Filled in at run time; this is only the tag -> display name mapping, which comes
# from MANAGER.EXE's own UI strings.
TAG_NAMES = {
    "CCCUP": "Coca-Cola Cup",
    "CHARI": "Charity Shield",
    "FACUP": "F.A. Cup",
    "FIRST": "First Division",
    "PREMI": "Premier League",
    "SECON": "Second Division",
    "THIRD": "Third Division",
    "INTER": "Intercontinental Cup",
    "CEURO": "European Cup",
    "CUEFA": "U.E.F.A. Cup",
    "RECOP": "Cup Winners' Cup",
    "SCEUR": "European Supercup",
}

# What the doc claims, so this file can fail instead of quietly disagreeing with it.
EXPECT_GBP = {
    "Premier League": 90_000,
    "First Division": 45_000,
    "Second Division": 35_000,
    "Third Division": 35_000,
    "European Cup": 375_000,
    "U.E.F.A. Cup": 375_000,
    "Cup Winners' Cup": 375_000,
    "European Supercup": 375_000,
    "Charity Shield": 187_500,
    "Intercontinental Cup": 187_500,
    "F.A. Cup": 0,
    "Coca-Cola Cup": 0,
}


_DECODE_CACHE: list = []


def decode_by_function(pe: PE, call_targets):
    """Every instruction in `.text`, decoded from each call target.

    Decoding from arbitrary bytes desynchronises on this image. Every entry is a
    real call target, so each decode starts on a real instruction boundary. The
    whole sweep is ~0.5 M instructions, so it is done once and cached.
    """
    if _DECODE_CACHE:
        return _DECODE_CACHE
    text = next(s for s in pe.sections if s.name == ".text")
    entries = sorted(t for t in call_targets if text.has_va(t))
    end = text.vma + text.size
    seen: set[int] = set()
    for i, start in enumerate(entries):
        stop = entries[i + 1] if i + 1 < len(entries) else end
        off = pe.va_to_foff(start)
        for insn in pe.md.disasm(pe.data[off : off + (stop - start)], start):
            if insn.address in seen:
                continue
            seen.add(insn.address)
            _DECODE_CACHE.append(insn)
    return _DECODE_CACHE


def class_blocks(pe: PE) -> list[tuple[int, str]]:
    """(block_start_va, tag) for each competition class, in address order."""
    pat = re.compile(rb"%c:ACTLIGA\\([A-Z0-9]{2,8})%03u\.CPT")
    tpl = {}
    for m in pat.finditer(pe.data):
        tpl[pe.foff_to_va(m.start())] = m.group(1).decode()
    # find the code sites that reference each template
    _sites, call_targets = scan_calls(pe)
    first_ref: dict[str, int] = {}
    for insn in decode_by_function(pe, call_targets):
        for o in insn.operands:
            v = (
                o.imm
                if o.type == X86_OP_IMM
                else (o.mem.disp if o.type == X86_OP_MEM and o.mem.base == 0 else None)
            )
            if v is None:
                continue
            v &= 0xFFFFFFFF
            if v in tpl:
                tag = tpl[v]
                if tag not in first_ref or insn.address < first_ref[tag]:
                    first_ref[tag] = insn.address
    return sorted(((va, tag) for tag, va in first_ref.items()))


def main() -> int:
    pe = PE()
    _sites, call_targets = scan_calls(pe)

    blocks = class_blocks(pe)
    print("competition class blocks (anchored on their own .CPT templates):")
    for va, tag in blocks:
        print(f"  {va:#010x}  {tag:<6s} {TAG_NAMES.get(tag, '?')}")
    starts = [va for va, _ in blocks]

    # The competition classes occupy one contiguous stretch of `.text`. Bound it so
    # the LAST class does not swallow the rest of the image (the club record's own
    # init / save / hub sites live far above and are NOT producers).
    CLASS_SPAN_END = starts[-1] + 0x8000

    def owner(va: int) -> str | None:
        # A class's code runs from its first template reference to the next
        # class's. Every fee writer sits AFTER its own template ref, so a bisect
        # on the anchors is exact for them.
        if not (starts[0] <= va < CLASS_SPAN_END):
            return None
        i = bisect.bisect_right(starts, va) - 1
        return blocks[i][1] if i >= 0 else None

    # --- every write to club+0x290 -------------------------------------------
    writes: dict[str, list[tuple[int, int]]] = {}
    pending_imm: dict[str, int] = {}
    for insn in decode_by_function(pe, call_targets):
        ops = insn.operands
        # `mov edx, <imm>` followed by `mov [reg+0x290], edx` is the one-off
        # finals' shape; remember the last immediate loaded into each register.
        if (
            insn.mnemonic == "mov"
            and len(ops) == 2
            and ops[0].type != X86_OP_MEM
            and ops[1].type == X86_OP_IMM
        ):
            pending_imm[insn.reg_name(ops[0].reg)] = ops[1].imm & 0xFFFFFFFF
        if not ops or ops[0].type != X86_OP_MEM:
            continue
        m = ops[0].mem
        if m.disp != FIELD or m.base == 0 or insn.reg_name(m.base) == "esp":
            continue
        # A WRITE only. `cmp [club+0x290], ebx` (the hub's raise test) also has a
        # memory first operand and must not be counted as a producer.
        if insn.mnemonic != "mov" or len(ops) < 2:
            continue
        who = owner(insn.address)
        if who is None:
            continue
        if ops[1].type == X86_OP_IMM:
            val = ops[1].imm & 0xFFFFFFFF
        else:
            val = pending_imm.get(insn.reg_name(ops[1].reg), -1)
        writes.setdefault(who, []).append((insn.address, val))

    # --- the league jump table ------------------------------------------------
    tbl = struct.unpack_from("<4I", pe.data, pe.va_to_foff(0x417570))
    arms = {}
    for insn in decode_by_function(pe, call_targets):
        if (
            insn.address in tbl
            and insn.operands
            and insn.operands[0].type == X86_OP_MEM
            and insn.operands[0].mem.disp == FIELD
        ):
            arms[insn.address] = insn.operands[1].imm & 0xFFFFFFFF
    league_order = ["Premier League", "First Division", "Second Division", "Third Division"]
    league = {league_order[i]: arms.get(t, -1) for i, t in enumerate(tbl)}
    print(f"\nleague jump table @0x417570: {[hex(t) for t in tbl]}")
    print(f"  arms 2 and 3 share one target: {tbl[2] == tbl[3]}")

    # --- the table ------------------------------------------------------------
    gbp: dict[str, int] = {}
    for name, internal in league.items():
        gbp[name] = internal // MONEY_PER_POUND
    for tag_name in TAG_NAMES.values():
        gbp.setdefault(tag_name, 0)
    for tag, sites in writes.items():
        name = TAG_NAMES.get(tag, tag)
        if name in league_order:
            continue  # the league arms are handled by the jump table
        vals = {v for _va, v in sites if v > 0}
        if len(vals) != 1:
            print(f"  !! {name}: {len(vals)} distinct fee immediates {vals}")
            return 2
        gbp[name] = vals.pop() // MONEY_PER_POUND

    print("\ncompetition                internal        GBP   writer sites")
    bad = 0
    for name in EXPECT_GBP:
        tag = next((t for t, n in TAG_NAMES.items() if n == name), "?")
        sites = (
            writes.get(tag, [])
            if name not in league_order
            else [(t, arms.get(t, -1)) for t in dict.fromkeys(tbl)]
        )
        internal = gbp[name] * MONEY_PER_POUND
        flag = "" if gbp[name] == EXPECT_GBP[name] else "   <-- MISMATCH"
        if flag:
            bad += 1
        s = " ".join(f"{va:#x}" for va, _ in sites) or "(none)"
        print(f"  {name:<22s} {internal:>11,d} {gbp[name]:>10,d}   {s}{flag}")

    if bad:
        print(f"\n{bad} row(s) disagree with docs/re/channeltv_fee_re.md")
        return 1
    print(
        "\nAll 12 rows agree with docs/re/channeltv_fee_re.md "
        "(200 internal = GBP 1, transfer_value_re.md §10)."
    )
    print("F.A. Cup and Coca-Cola Cup have NO writer: the game pays no domestic-cup TV fee at all.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
