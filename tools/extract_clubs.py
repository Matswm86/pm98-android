#!/usr/bin/env python3
"""First-pass club roster extraction from EQUIPOS strings.

Club display names recur (in fixtures + player bios); we collect tokens ending in
known football suffixes / starting with known prefixes, clean and dedupe them.
This is a *roster census* (which clubs exist), not the full per-club record yet —
that needs the attribute-offset map (next phase).
"""
from __future__ import annotations
import json
import re
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "assets" / "equipos_strings.txt"
OUT = Path(__file__).resolve().parent.parent / "assets" / "clubs_census.json"

SUFFIX = r"(UNITED|CITY|ROVERS|ATHLETIC|WEDNESDAY|FOREST|ALBION|COUNTY|TOWN|HOTSPUR|VILLA|WANDERERS|PALACE|ARGYLE|ORIENT|VALE|ALEXANDRA|RANGERS|CELTIC)"
PREFIX = r"(GLASGOW|QUEENS PARK|WEST HAM|WEST BROMWICH|CRYSTAL|ASTON|PORT|LEYTON|PLYMOUTH|NOTTS|HOVE)"
CLUB_RE = re.compile(rf"\b([A-Z][A-Z' .]{{2,26}}?{SUFFIX})\b")
# bio/commentary filler words that can't begin a real club name
FILLER = {"A", "AT", "THE", "OF", "FROM", "IN", "TO", "FOR", "AND", "AS", "ON", "BY",
          "PRODUCT", "MARCH", "GOAL", "GOALSCORING", "HIS", "HE", "WITH", "THIS",
          "THAT", "NEW", "OWN", "PLAYED", "PLAYS", "JOINED", "SIGNED", "DEBUT",
          "AGAINST", "SEASON", "CAPTAIN", "RANKS", "SCORER", "TRANSFERRED",
          "TRANSFERED", "MEDAL", "MEDALS", "CHAMPION", "WINNERS", "CONTRACT",
          "FINAL", "FINALS", "DELL", "GAME", "FIRST", "TOP", "LOWER", "WAS", "IS",
          "TRAINED", "CUP", "WORLD", "DERBY", "AGAINST"}


def main():
    text = SRC.read_text()
    seen = {}
    for line in text.splitlines():
        s = line.split("  ", 1)[-1]
        for m in CLUB_RE.finditer(s):
            name = " ".join(m.group(1).split())
            words = name.split()
            # reject if any word is bio filler, or DERBY appears as a non-final word
            if len(name) < 4 or any(w in FILLER for w in words):
                continue
            seen[name] = seen.get(name, 0) + 1
    # keep names seen >=3 times (filters one-off bio fragments)
    clubs = sorted(n for n, c in seen.items() if c >= 3)
    OUT.write_text(json.dumps({"count": len(clubs), "clubs": clubs}, indent=2))
    print(f"{len(clubs)} clubs -> {OUT}")
    for c in clubs:
        print("  ", c)


if __name__ == "__main__":
    main()
