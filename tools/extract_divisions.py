#!/usr/bin/env python3
"""Extract the English league/division table from MANAGER.EXE.

The 1997-98 division membership is NOT stored in EQUIPOS (club enumeration order is
96/97 final-standings order) and NOT in the packed RC_DBASE/DAT databases. It lives
as a plain u16 team-id table inside the game's own executable, MANAGER.EXE.

English club team-id == 301 + (EQUIPOS idx - 38), i.e. idx == id - 263.

The table appears in two layouts; the cleanly-isolated arrays are:
    Premier League  @0x251018  (20 ids)
    Division One    @0x250e10  (24 ids)  - has Forest, Boro, Sunderland, QPR, Man City
    Division Two    @0x250ce8  (24 ids)  - Grimsby, Oldham, Southend, Watford, Fulham...
Division Three (24) is the remaining clubs by elimination (incl. Hereford - the game
keeps the 96/97 boundary club, NOT the real-97/98 Macclesfield, so external tables
would be wrong; only the executable is faithful).

Cross-checked: Premier == the real 97-98 top flight exactly; Div1 has the relegated
trio; Div3 has Hereford/Barnet/Scarborough. Output: assets/divisions_english.json.
"""
from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXE = ROOT / "extracted" / "Premier Manager 98" / "MANAGER.EXE"
SQUADS = ROOT / "assets" / "squads_english.json"
OUT = ROOT / "assets" / "divisions_english.json"

# (leagueId-ish label, file offset, count). Div3 derived by elimination.
ARRAYS = [
    ("PREMIER LEAGUE", 0x251018, 20),
    ("DIVISION ONE", 0x250E10, 24),
    ("DIVISION TWO", 0x250CE8, 24),
]
ID_TO_IDX = 263  # idx = team_id - 263


def main() -> None:
    d = EXE.read_bytes()
    names = {c["idx"]: c["name"] for c in json.loads(SQUADS.read_text())["clubs"]}

    def read_array(off: int, n: int) -> list[int]:
        return [struct.unpack_from("<H", d, off + 2 * k)[0] for k in range(n)]

    table: dict[str, list[int]] = {}
    assigned: set[int] = set()
    for label, off, n in ARRAYS:
        ids = read_array(off, n)
        if len(set(ids)) != n or any(not (301 <= t <= 392) for t in ids):
            raise SystemExit(f"{label} @0x{off:x} did not read {n} clean team ids: {ids}")
        table[label] = ids
        assigned |= set(ids)

    all_ids = {ID_TO_IDX + i for i in range(38, 130)}  # 301..392
    div3 = sorted(all_ids - assigned)
    if len(div3) != 24:
        raise SystemExit(f"Division Three (elimination) = {len(div3)} clubs, expected 24")
    table["DIVISION THREE"] = div3

    division_by_idx = {}
    for label, ids in table.items():
        for t in ids:
            division_by_idx[t - ID_TO_IDX] = label

    OUT.write_text(json.dumps({
        "note": "English 1997-98 division membership, decoded from MANAGER.EXE's own "
                "league table (plain u16 team-id arrays). Premier verified == real "
                "97-98 top flight; the game's Div3 keeps Hereford (not Macclesfield).",
        "season": "1997-98",
        "source": "MANAGER.EXE @0x251018 (Prem) / 0x250e10 (Div1) / 0x250ce8 (Div2); "
                  "Div3 by elimination",
        "divisionByIdx": {str(k): v for k, v in sorted(division_by_idx.items())},
        "table": {lab: [names.get(t - ID_TO_IDX, f"?{t}") for t in ids]
                  for lab, ids in table.items()},
    }, indent=1, ensure_ascii=False), encoding="utf-8")

    for lab, ids in table.items():
        print(f"{lab}: {len(ids)} clubs")
    print(f"-> {OUT.relative_to(ROOT)}  ({len(division_by_idx)} clubs in 4 divisions)")


if __name__ == "__main__":
    main()
