#!/usr/bin/env python3
"""Extract all decodable text strings from EQUIPOS.PKF (both cipher variants).

Two text encodings coexist in EQUIPOS:
  - low-byte form  : letters 0x00-0x1b, first byte +0x20 start flag (sort names)
  - base-0x20 form : letters 0x20-0x3b, space 0x41/0x21 (display names, club/stadium)
Both decode through alphabet[b & 0x1f]. We scan for maximal clean runs and keep
ones that read as words. Numeric attribute blocks are skipped by requiring the
run to be majority real letters and to contain a vowel.
"""
from __future__ import annotations
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "extracted" / "Premier Manager 98"
OUT = Path(__file__).resolve().parent.parent / "assets" / "equipos_strings.txt"

_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
C2 = {c: chr(65 + L) for L, c in _FWD.items()}
C2[1] = " "
C2[26] = "'"
VOWELS = set("AEIOU")


def decode(bs: bytes) -> str:
    return "".join(C2.get(b & 0x1F, "?") for b in bs)


def clean(s: str) -> str:
    return " ".join(s.split()).strip()


def looks_word(s: str) -> bool:
    s = s.strip()
    if len(s) < 3:
        return False
    letters = [c for c in s if c.isalpha()]
    if len(letters) < 3:
        return False
    if not any(c in VOWELS for c in letters):
        return False
    # reject runs dominated by spaces (attribute noise)
    return len(letters) / len(s) >= 0.7


def scan(d: bytes):
    n = len(d)
    out = []
    i = 16
    while i < n - 2:
        b = d[i]
        # candidate run: bytes that are either low letters or base-0x20 letters/space
        if (0x20 <= b <= 0x3b) and (d[i + 1] & 0x1f) in C2:
            j = i
            while j < n and ((0x20 <= d[j] <= 0x3b) or (d[j] <= 0x1b) or d[j] in (0x41, 0x21)):
                j += 1
            s = clean(decode(d[i:j]))
            if "?" not in s and looks_word(s):
                out.append((i, s))
            i = max(j, i + 1)
        else:
            i += 1
    return out


def main():
    d = (GAME / "DBDAT/EQUIPOS.PKF").read_bytes()
    strings = scan(d)
    lines = [f"{off:7d}  {s}" for off, s in strings]
    OUT.write_text("\n".join(lines))
    print(f"extracted {len(strings)} strings -> {OUT}")
    # heuristics: club markers and a sample
    clubs = [s for _, s in strings if s.startswith(("CLUB ", "FC ", "REAL ", "ATLETICO", "DEPORTIVO"))]
    print(f"\n'CLUB/REAL/...' candidates ({len(clubs)}):")
    for c in clubs[:60]:
        print("   ", c)
    print("\nfirst 40 strings overall:")
    for off, s in strings[:40]:
        print(f"   @{off:7d} {s}")


if __name__ == "__main__":
    main()
