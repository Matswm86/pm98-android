#!/usr/bin/env python3
"""Export the WITNESSED 1997-98 pre-season league-table seed orders.

The original seeds every division's week-0 table in a fixed order (NOT
alphabetical): last season's finishing order, with the clubs relegated from
the division above at the TOP (in their above-division finishing order) and
the clubs promoted from below at the BOTTOM (champions first). All four
orders were live-witnessed 2026-07-19 on fresh careers, pre-play (P=0):

  Premier  : w5_lt_premier.png  (also w4 lt_default.png, identical)
  Div One  : w5_lt_default.png  (Manchester C career, own division, P=0)
  Div Two  : w6_lt_second_seed.png (Blackpool career; w7_lt_second identical)
  Div Three: w7_lt_third_seed.png  (Barnet career)

frames: screenshots/wine-captures-2026-07-19-lowerdiv/ (local witness archive).
Transcribed row-by-row below; matched against game_db club names (exact,
normalized) and emitted as ids -> app/data/season_seed_1997.json.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent

# Row-by-row transcriptions of the witnessed P=0 tables (top to bottom).
SEEDS = {
    "eng_prem": [
        "Manchester Utd.", "Newcastle Utd", "Arsenal", "Liverpool",
        "Aston Villa", "Chelsea", "Sheffield W.", "Wimbledon", "Leicester",
        "Tottenham H", "Leeds Utd", "Derby County", "Blackburn R.",
        "West Ham Utd", "Everton", "Southampton", "Coventry", "Bolton W",
        "Barnsley", "Crystal Pal.",
    ],
    "eng_div1": [
        "Sunderland", "Middlesbrough", "Nottingham F.", "Wolverhampton",
        "Ipswich", "Sheffield Utd", "Portsmouth", "Port Vale", "QPR",
        "Birmingham C", "Tranmere Rov", "Stoke C", "Norwich C",
        "Manchester C", "Charlton Ath", "WBA", "Oxford Utd", "Reading",
        "Swindon", "Huddersfield T", "Bradford City", "Bury", "Stockport C",
        "Crewe Alex.",
    ],
    "eng_div2": [
        "Grimsby T", "Oldham Ath", "Southend Utd", "Luton T.", "Brentford",
        "Bristol Rovers", "Blackpool", "Wrexham", "Burnley", "Chesterfield",
        "Gillingham", "Walsall", "Watford", "Millwall", "Preston NE",
        "Bournemouth", "Bristol City", "Wycombe W.", "Plymouth Arg.",
        "York City", "Wigan Ath.", "Fulham", "Carlisle U.", "Northampton T.",
    ],
    "eng_div3": [
        "Peterborough", "Shrewsbury T.", "Rotherham U", "Notts C.",
        "Swansea City", "Chester C.", "Cardiff C.", "Colchester U.",
        "Lincoln C.", "Cambridge U.", "Mansfield T.", "Scarborough",
        "Scunthorpe U.", "Rochdale", "Barnet", "Leyton O.", "Hull C.",
        "Darlington", "Doncaster R.", "Hartlepool U.", "Torquay U.",
        "Exeter C.", "Brighton & HA", "Macclesfield T.",
    ],
}


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main() -> None:
    db = json.loads((ROOT / "app/data/game_db.json").read_text(encoding="utf-8"))
    by_league: dict[str, list[dict]] = {}
    names = {}
    for c in db["clubs"]:
        names[c["id"]] = c["name"]
        if c["leagueId"]:
            by_league.setdefault(c["leagueId"], []).append(c)

    out: dict[str, list[int]] = {}
    for lid, rows in SEEDS.items():
        pool = {norm(c["name"]): int(c["id"]) for c in by_league[lid]}
        assert len(pool) == len(by_league[lid]), f"{lid}: name collision in pool"
        ids = []
        for row in rows:
            key = norm(row)
            assert key in pool, f"{lid}: witnessed '{row}' not in game_db {lid}"
            ids.append(pool.pop(key))
        assert not pool, f"{lid}: unseeded clubs left: {sorted(pool)}"
        out[lid] = ids

    dest = ROOT / "app/data/season_seed_1997.json"
    dest.write_text(
        json.dumps(
            {
                "_source": "Witnessed 1997-98 pre-season table orders (P=0), live "
                "wine campaign 2026-07-19 — frames w5_lt_premier/w5_lt_default/"
                "w6_lt_second_seed/w7_lt_third_seed in screenshots/"
                "wine-captures-2026-07-19-lowerdiv/. Seed rule: prior-season "
                "finish; relegated-from-above at top, promoted-from-below at "
                "bottom. Exported by tools/re/export_season_seed.py.",
                "seeds": out,
            },
            indent=1,
        ),
        encoding="utf-8",
    )
    for lid, ids in out.items():
        print(lid, len(ids), "->", names[ids[0]], "...", names[ids[-1]])
    print(f"wrote {dest.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
