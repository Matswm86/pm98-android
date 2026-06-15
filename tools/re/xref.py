"""Capstone call-xref triage for MANAGER.EXE (cross-check for Ghidra).

Scans .text for `call rel32` (E8) and `jmp rel32` (E9), builds a target->sites
map, and uses call-targets as function-entry candidates. Lets us:
  * find the function ENTRY containing a VA (largest call-target <= VA),
  * list CALLERS of a function entry,
without trusting linear-sweep alignment (data-in-code misaligns objdump).
"""
from __future__ import annotations

import sys
from collections import defaultdict

from pe import PE


def scan_calls(pe: PE):
    """Return (call_sites, call_targets, jmp_targets).

    call_sites: list of (site_va, target_va) for E8 rel32 calls.
    call_targets[target] -> set of site_va.
    """
    text = next(s for s in pe.sections if s.name == ".text")
    data = pe.data[text.foff : text.foff + text.size]
    base = text.vma
    call_targets: dict[int, set[int]] = defaultdict(set)
    sites: list[tuple[int, int]] = []
    end = len(data) - 5
    i = 0
    while i < end:
        b = data[i]
        if b == 0xE8:  # call rel32
            rel = int.from_bytes(data[i + 1 : i + 5], "little", signed=True)
            site = base + i
            target = (site + 5 + rel) & 0xFFFFFFFF
            if text.has_va(target):
                call_targets[target].add(site)
                sites.append((site, target))
        i += 1
    return sites, call_targets


def fn_entry_containing(va: int, call_targets: dict[int, set[int]]) -> int | None:
    """Largest call-target <= va = best guess for the enclosing function entry."""
    cands = [t for t in call_targets if t <= va]
    return max(cands) if cands else None


def main():
    pe = PE()
    sites, call_targets = scan_calls(pe)
    print(f"scanned .text: {len(sites)} E8 calls, {len(call_targets)} distinct targets")

    seeds = [int(a, 16) for a in sys.argv[1:]] or [0x46A338, 0x46A35B, 0x5DA180]
    for va in seeds:
        entry = fn_entry_containing(va, call_targets)
        callers = sorted(call_targets.get(entry, set())) if entry else []
        print(f"\n=== VA {va:#x} ===")
        print(f"  enclosing fn entry (heuristic): {entry:#x}" if entry else "  no entry found")
        if entry is not None:
            caller_fns = sorted({fn_entry_containing(c, call_targets) for c in callers})
            print(f"  call-sites INTO entry: {len(callers)} -> {[hex(c) for c in callers]}")
            print(f"  distinct caller fns: {[hex(c) for c in caller_fns if c]}")


if __name__ == "__main__":
    main()
