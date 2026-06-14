#!/usr/bin/env python3
"""Easter-egg youth players for PM98 (original content, NOT from the game files).

Two hidden wonderkids to add to the recruitable youth pool, with elite striker
profiles (~Ronaldo-tier potential). Same player schema as `extract_english.py`
output (attrs VE RE AG CA RM RG PA TI EN PO, each 1-99), so the engine can merge
these straight into the youth-recruitment list.

Run: python3 tools/easter_eggs.py  ->  assets/easter_eggs.json
"""

from __future__ import annotations

import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "easter_eggs.json"
ATTR_NAMES = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]
SEASON_BASE = 1998  # 1997-98 season, matches extract_english.py age basis


def player(name, dob, attrs):
    year = int(dob[:4])
    return {
        "name": name,
        "legalName": name,
        "birthYear": year,
        "birthDate": dob,  # ISO; original records store only the year
        "age": SEASON_BASE - year,
        "nationality": "NORWAY",
        "position": "Striker",
        "isGK": False,
        "isEasterEgg": True,
        "potential": "elite",  # ~Ronaldo-tier; engine should let them grow to ~99
        "attrs": dict(zip(ATTR_NAMES, attrs)),
    }


# attrs: VE  RE  AG  CA  RM  RG  PA  TI  EN  PO   (elite striker, very low GK)
EGGS = [
    player("MATS MJÅTVEDT", "1986-07-09", [96, 88, 84, 97, 95, 96, 86, 94, 24, 5]),
    player("FREDRIK SOLLI", "1985-05-23", [97, 86, 82, 96, 97, 94, 84, 96, 21, 4]),
]


def main():
    OUT.write_text(
        json.dumps(
            {
                "note": "Easter-egg youth players (ORIGINAL content, not from the game "
                "data). Two Norwegian striker wonderkids with ~Ronaldo-tier potential, "
                "to merge into the recruitable youth pool. Same schema as "
                "squads_english.json plus nationality/position/birthDate/potential.",
                "players": EGGS,
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    print(f"easter eggs: {len(EGGS)} players -> {OUT}")
    for p in EGGS:
        print(f"  {p['name']} ({p['nationality']}, b.{p['birthDate']}) {p['attrs']}")


if __name__ == "__main__":
    main()
