"""Path 3 — locate plaintext financial/management constant strings in MANAGER.EXE
and the code that references them (push imm32 / mov reg,imm32 of the string VA).

The reward/wage/bonus strings are plaintext (verified anchor: "MATCH RESULT" and
"510.000 for every match won"). Finding the code that pushes a string VA, then
reading the nearby immediate operands, recovers the numeric constants the game
uses (rewards, wages, bonuses, insurance, fees).
"""
from __future__ import annotations

import re
import sys

from pe import PE

PRINTABLE = re.compile(rb"[\x20-\x7e]{4,}")

# Keywords that flag a finance/management constant string.
KEYWORDS = [
    "match won", "draw match", "match lost", "every match", "bonus", "wage",
    "salary", "insurance", "injur", "interest", "loan", "overdraft", "transfer",
    "fee", "ticket", "gate", "attendance", "sponsor", "prize", "budget", "fine",
    "fund", "income", "expenditure", "balance", "scoring", "goal bonus",
    "win bonus", "season ticket", "price", "cost", "pounds", "money",
]


def extract_strings(pe: PE, secnames=(".rdata", ".data")):
    """Yield (va, text) for printable C-strings in the given sections."""
    for s in pe.sections:
        if s.name not in secnames:
            continue
        blob = pe.data[s.foff : s.foff + s.size]
        for m in PRINTABLE.finditer(blob):
            yield s.vma + m.start(), m.group().decode("latin1")


def scan_imm_refs(pe: PE, targets: set[int]):
    """Find .text sites that load any VA in `targets` as an imm32.

    Matches `push imm32` (0x68) and `mov r32, imm32` (0xB8..0xBF). Returns
    {target_va: [site_va, ...]}.
    """
    text = next(s for s in pe.sections if s.name == ".text")
    data = pe.data[text.foff : text.foff + text.size]
    base = text.vma
    refs: dict[int, list[int]] = {t: [] for t in targets}
    n = len(data) - 5
    i = 0
    while i < n:
        b = data[i]
        if b == 0x68 or 0xB8 <= b <= 0xBF:
            imm = int.from_bytes(data[i + 1 : i + 5], "little")
            if imm in refs:
                refs[imm].append(base + i)
        i += 1
    return refs


def main():
    pe = PE()
    allstr = list(extract_strings(pe))
    print(f"{len(allstr)} printable strings in .rdata/.data")

    # Filter to finance/management keywords.
    kw = [k.lower() for k in KEYWORDS]
    hits = [(va, t) for va, t in allstr if any(k in t.lower() for k in kw)]
    # De-noise: drop very long blobs and obvious format-only strings.
    hits = [(va, t) for va, t in hits if len(t) <= 120]
    print(f"{len(hits)} finance/management keyword strings\n")

    target_vas = {va for va, _ in hits}
    refs = scan_imm_refs(pe, target_vas)

    for va, t in sorted(hits):
        sites = refs.get(va, [])
        tag = f"  refs={[hex(s) for s in sites]}" if sites else "  (no imm32 ref)"
        print(f"  VA {va:#08x}  {t!r}{tag}")

    if len(sys.argv) > 1:
        # Dump a window of strings around a given VA for context.
        center = int(sys.argv[1], 16)
        print(f"\n=== strings near {center:#x} ===")
        for va, t in allstr:
            if abs(va - center) <= 0x400:
                print(f"  {va:#08x}  {t!r}")


if __name__ == "__main__":
    main()
