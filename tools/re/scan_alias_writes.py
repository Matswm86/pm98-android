"""Find memory WRITES that land on `<base> + TARGET` through an ALIASED base pointer.

Why this exists
---------------
`finance_screen_re.md` records that a byte-accurate scan of `.text` for the
displacement `0x00000290` finds no producer for the channelTV fee field
`club+0x290`, and concludes the producer must reach the field through an
aliased base. `camera_re.md` §2 proved that exact miss class is real: the
writer of `camctrl+0x3c` is `FUN_005f5850`, which does
`puVar19 = param_1 + 0xf; *puVar19 = ...` — a write with NO displacement at
all, invisible to any displacement scan.

So this tool does the search the displacement scan cannot: a forward,
intra-procedural abstract interpretation that tracks, per register, a
symbolic `(root, offset)` pair, and reports every memory write whose
`root + offset + disp` equals the target offset.

It is deliberately conservative: an instruction it does not model CLOBBERS
its destination register (fresh symbol), so a reported hit is a real
`base + TARGET` write for some base, and a miss is never silently a hit.

Usage:
    python tools/re/scan_alias_writes.py 0x290
    python tools/re/scan_alias_writes.py 0x290 --min-chain 1   # alias-only
"""

from __future__ import annotations

import argparse
from collections import defaultdict

from capstone import CS_OP_IMM, CS_OP_REG
from capstone.x86 import X86_OP_MEM
from pe import PE
from xref import scan_calls

# Registers we track. 32-bit only; a write through a 16/8-bit alias cannot
# form a struct pointer on this target.
REGS32 = {"eax", "ebx", "ecx", "edx", "esi", "edi", "ebp", "esp"}

# Instructions that WRITE their first (memory) operand.
WRITE_MNEMONICS = {
    "mov",
    "movsx",
    "movzx",
    "add",
    "sub",
    "and",
    "or",
    "xor",
    "inc",
    "dec",
    "adc",
    "sbb",
    "neg",
    "not",
    "shl",
    "shr",
    "sar",
    "rol",
    "ror",
    "fstp",
    "fst",
    "fistp",
    "fist",
    "fiadd",
    "fisub",
    "movsd",
    "movss",
    "movq",
    "movd",
    "movaps",
    "movups",
    "movlps",
    "movhps",
    "setne",
    "sete",
    "setg",
    "setl",
    "setge",
    "setle",
    "seta",
    "setb",
    "xchg",
    "cmpxchg",
    "lock",
}


class State:
    """reg -> (root_symbol, offset). Absent = unknown (fresh root at use)."""

    def __init__(self) -> None:
        self.regs: dict[str, tuple[str, int]] = {}
        self._n = 0

    def fresh(self, why: str) -> str:
        self._n += 1
        return f"{why}#{self._n}"

    def get(self, reg: str) -> tuple[str, int]:
        if reg not in self.regs:
            # An untracked register is its own root at offset 0. That is the
            # honest reading: we do not know what it points at.
            self.regs[reg] = (f"?{reg}", 0)
        return self.regs[reg]

    def clobber(self, reg: str) -> None:
        self.regs[reg] = (self.fresh(f"clob_{reg}"), 0)

    def copy(self) -> State:
        s = State()
        s.regs = dict(self.regs)
        s._n = self._n
        return s


def reg_name(insn, r) -> str | None:
    if r == 0:
        return None
    name = insn.reg_name(r)
    return name if name in REGS32 else None


def function_ranges(pe: PE, call_targets) -> list[tuple[int, int]]:
    """Function entry candidates -> [entry, next_entry) ranges over .text."""
    text = next(s for s in pe.sections if s.name == ".text")
    entries = sorted(t for t in call_targets if text.has_va(t))
    end = text.vma + text.size
    out = []
    for i, e in enumerate(entries):
        stop = entries[i + 1] if i + 1 < len(entries) else end
        out.append((e, stop))
    return out


def scan_function(pe: PE, start: int, stop: int, target: int, hits: list) -> None:
    foff = pe.va_to_foff(start)
    code = pe.data[foff : foff + (stop - start)]
    st = State()
    for insn in pe.md.disasm(code, start):
        mnem = insn.mnemonic
        ops = insn.operands

        # --- pointer arithmetic we DO model -------------------------------
        if mnem == "lea" and len(ops) == 2 and ops[0].type == CS_OP_REG:
            dst = reg_name(insn, ops[0].reg)
            m = ops[1].mem
            base = reg_name(insn, m.base) if m.base else None
            if dst and base and not m.index:
                root, off = st.get(base)
                st.regs[dst] = (root, off + m.disp)
                continue
            if dst:
                st.clobber(dst)
                continue

        if mnem == "mov" and len(ops) == 2 and ops[0].type == CS_OP_REG:
            dst = reg_name(insn, ops[0].reg)
            if dst:
                if ops[1].type == CS_OP_REG:
                    src = reg_name(insn, ops[1].reg)
                    if src:
                        st.regs[dst] = st.get(src)
                        continue
                # mov reg, [mem] / mov reg, imm -> a NEW unknown pointer
                st.clobber(dst)
                continue

        if mnem in ("add", "sub") and len(ops) == 2 and ops[0].type == CS_OP_REG:
            dst = reg_name(insn, ops[0].reg)
            if dst and ops[1].type == CS_OP_IMM:
                root, off = st.get(dst)
                delta = ops[1].imm if mnem == "add" else -ops[1].imm
                st.regs[dst] = (root, off + delta)
                continue
            if dst:
                st.clobber(dst)
                continue

        # --- the WRITE test ------------------------------------------------
        if (
            ops
            and ops[0].type == X86_OP_MEM
            and (mnem in WRITE_MNEMONICS or mnem.startswith("mov"))
        ):
            m = ops[0].mem
            base = reg_name(insn, m.base) if m.base else None
            if base and base != "esp":
                root, off = st.get(base)
                total = off + m.disp
                if total == target:
                    hits.append(
                        {
                            "va": insn.address,
                            "fn": start,
                            "text": f"{insn.mnemonic} {insn.op_str}",
                            "root": root,
                            "chain": off,
                            "disp": m.disp,
                            "indexed": bool(m.index),
                        }
                    )

        # --- clobbers -------------------------------------------------------
        if mnem in ("call", "int", "int3"):
            # cdecl/stdcall on this target: eax, ecx, edx are volatile.
            for r in ("eax", "ecx", "edx"):
                st.clobber(r)
            continue
        if mnem in ("ret", "leave"):
            st = State()
            continue
        if mnem in (
            "pop",
            "xchg",
            "imul",
            "idiv",
            "div",
            "mul",
            "cdq",
            "movsx",
            "movzx",
            "shl",
            "shr",
            "sar",
            "and",
            "or",
            "xor",
            "neg",
            "not",
            "inc",
            "dec",
            "adc",
            "sbb",
            "setne",
            "sete",
        ):
            for o in ops:
                if o.type == CS_OP_REG:
                    r = reg_name(insn, o.reg)
                    if r:
                        st.clobber(r)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("target", help="struct offset, e.g. 0x290")
    ap.add_argument(
        "--min-chain",
        type=int,
        default=0,
        help="only report writes whose lea/add chain is >= this "
        "(1 = alias-only, i.e. what a disp32 scan cannot see)",
    )
    args = ap.parse_args()
    target = int(args.target, 0)

    pe = PE()
    _sites, call_targets = scan_calls(pe)
    ranges = function_ranges(pe, call_targets)

    hits: list = []
    for start, stop in ranges:
        try:
            scan_function(pe, start, stop, target, hits)
        except ValueError:
            continue

    by_fn: dict[int, list] = defaultdict(list)
    for h in hits:
        if abs(h["chain"]) >= args.min_chain:
            by_fn[h["fn"]].append(h)

    total = sum(len(v) for v in by_fn.values())
    print(
        f"target +{target:#x}: {total} write(s) in {len(by_fn)} function(s) "
        f"(min-chain {args.min_chain})"
    )
    for fn in sorted(by_fn):
        print(f"\n=== FUN_{fn:08x} ===")
        for h in sorted(by_fn[fn], key=lambda x: x["va"]):
            idx = " [indexed]" if h["indexed"] else ""
            print(
                f"  {h['va']:#010x}  {h['text']:<44s} "
                f"chain={h['chain']:+#x} disp={h['disp']:+#x} root={h['root']}{idx}"
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
