#!/usr/bin/env python3
"""Export per-club ECONOMY data -> app/data/club_economy.json.

Two source-true layers, joined onto game_db club ids by exact decoded name
(the game_db names ARE the EQUIPOS decode, 476/476 — club_tactics_re.md):

1. BUDGET (all 476 clubs): the EQUIPOS club-header u32 param_1[0x7a]
   (equipos_parse.parse_club_tactic collect=True `capacity` field — historic
   misnomer, it is NOT a seat count). Live-witnessed semantics
   (wine campaign 2026-07-19, frames in
   screenshots/wine-captures-2026-07-19-economics/):
     STARTING CASH = budget x 5000
       Bolton   400 -> 1,999,999 shown as cash 1,960,096 + wk-1 expenses 39,903
                 (orig/50_finance.png; -1 = the engine's float truncation)
       A.Villa 1000 -> 4,999,998 = 4,741,346 + 2x129,326  (s25_villa_finance)
       Arsenal 1200 -> 6,000,000 = 5,767,308 + 232,692    (s10_finance)

2. OBJECTIVE (the 92 English league clubs): the START OF SEASON board
   objective, transcribed verbatim from the live-witnessed division pages
   (s29_sos_prem / s30_sos_div1 / s31_sos_div2 / s32_sos_div3, 2026-07-19).
   The label drives the GROUND IMPROVEMENTS seat-price tier (all four Premier
   tiers live-witnessed):
     Champion 4,250,000 / U.E.F.A. 3,750,000 / Mid Table 3,250,000 /
     Avoid Relegation 2,750,000  (cards x1 / x1.75 / x2.5)

KNOWN PARITY DEFECT (recorded, not fixed here): the game fields
Macclesfield T. in Div 3 (s32 witness) and NOT Hereford U.; game_db has them
swapped (Hereford eng_div3, Macclesfield international). The objective row
for Macclesfield is exported against its game_db id anyway.

Usage: python3 tools/re/export_club_economy.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import dbc_extract as DX  # noqa: E402
import equipos_parse as EP  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
DB = REPO / "app/data/game_db.json"
OUT = REPO / "app/data/club_economy.json"

# START OF SEASON objectives, alphabetical rows exactly as the frames list them.
# (Div 3 witnessed roster includes Macclesfield T., excludes Hereford U.)
OBJ_PREM = {
    "Arsenal": "Champion", "Aston Villa": "U.E.F.A.", "Barnsley": "Avoid Relegation",
    "Blackburn R.": "U.E.F.A.", "Bolton W": "Avoid Relegation", "Chelsea": "Champion",
    "Coventry": "Mid Table", "Crystal Pal.": "Avoid Relegation", "Derby County": "Mid Table",
    "Everton": "Mid Table", "Leeds Utd": "Mid Table", "Leicester": "Mid Table",
    "Liverpool": "Champion", "Manchester Utd.": "Champion", "Newcastle Utd": "Champion",
    "Sheffield W.": "Mid Table", "Southampton": "Avoid Relegation", "Tottenham H": "U.E.F.A.",
    "West Ham Utd": "Mid Table", "Wimbledon": "Mid Table",
}
OBJ_DIV1 = {
    "Birmingham C": "Mid Table", "Bradford City": "Avoid Relegation", "Bury": "Avoid Relegation",
    "Charlton Ath": "Mid Table", "Crewe Alex.": "Mid Table", "Huddersfield T": "Avoid Relegation",
    "Ipswich": "Promotion", "Manchester C": "Promotion", "Middlesbrough": "Promotion",
    "Norwich C": "Mid Table", "Nottingham F.": "Promotion", "Oxford Utd": "Avoid Relegation",
    "Port Vale": "Mid Table", "Portsmouth": "Mid Table", "QPR": "Promotion",
    "Reading": "Avoid Relegation", "Sheffield Utd": "Promotion", "Stockport C": "Avoid Relegation",
    "Stoke C": "Mid Table", "Sunderland": "Promotion", "Swindon": "Avoid Relegation",
    "Tranmere Rov": "Mid Table", "WBA": "Mid Table", "Wolverhampton": "Promotion",
}
OBJ_DIV2 = {
    "Blackpool": "Promotion", "Bournemouth": "Mid Table", "Brentford": "Promotion",
    "Bristol City": "Promotion", "Bristol Rovers": "Avoid Relegation", "Burnley": "Mid Table",
    "Carlisle U.": "Avoid Relegation", "Chesterfield": "Mid Table", "Fulham": "Promotion",
    "Gillingham": "Mid Table", "Grimsby T": "Promotion", "Luton T.": "Promotion",
    "Millwall": "Mid Table", "Northampton T.": "Mid Table", "Oldham Ath": "Promotion",
    "Plymouth Arg.": "Avoid Relegation", "Preston NE": "Mid Table", "Southend Utd": "Promotion",
    "Walsall": "Mid Table", "Watford": "Mid Table", "Wigan Ath.": "Avoid Relegation",
    "Wrexham": "Promotion", "Wycombe W.": "Avoid Relegation", "York City": "Avoid Relegation",
}
OBJ_DIV3 = {
    "Barnet": "Mid Table", "Brighton & HA": "Avoid Relegation", "Cambridge U.": "Mid Table",
    "Cardiff C.": "Promotion", "Chester C.": "Promotion", "Colchester U.": "Mid Table",
    "Darlington": "Mid Table", "Doncaster R.": "Avoid Relegation", "Exeter C.": "Avoid Relegation",
    "Hartlepool U.": "Avoid Relegation", "Hull C.": "Mid Table", "Leyton O.": "Mid Table",
    "Lincoln C.": "Mid Table", "Macclesfield T.": "Avoid Relegation", "Mansfield T.": "Mid Table",
    "Notts C.": "Promotion", "Peterborough": "Promotion", "Rochdale": "Mid Table",
    "Rotherham U": "Promotion", "Scarborough": "Mid Table", "Scunthorpe U.": "Mid Table",
    "Shrewsbury T.": "Promotion", "Swansea City": "Promotion", "Torquay U.": "Avoid Relegation",
}
OBJECTIVES = {**OBJ_PREM, **OBJ_DIV1, **OBJ_DIV2, **OBJ_DIV3}


def main() -> int:
    db = json.loads(DB.read_text())
    by_name: dict[str, list[dict]] = {}
    for c in db["clubs"]:
        by_name.setdefault(c["name"], []).append(c)

    buf = DX.find_pkf().read_bytes()
    budgets: dict[str, int] = {}
    for _pos, ids, _name, off, size in DX.entries(buf):
        d = buf[off : off + size]
        try:
            t = EP.parse_club_tactic(d, int(ids), collect=True)
        except Exception:
            continue
        s = EP.Stream(d, 0x24)
        s.u16()
        fmt = s.u16()
        s.u8()
        flag = s.u8()
        s.string()
        s.string()
        s.u8()
        s.string()
        s.u32()
        if fmt >= 0x1FE:
            s.u32()
        s.u16()
        s.u16()
        s.u16()
        if flag != 0:
            continue
        if fmt > 0x207:
            s.p += 2
        s.u32()
        s.skip_string_plus(6)
        budgets[t["name"]] = s.u32()

    clubs: dict[str, dict] = {}
    missing_budget = []
    for name, entries in by_name.items():
        b = budgets.get(name)
        if b is None:
            missing_budget.append(name)
            continue
        for c in entries:
            row: dict = {"budget": b}
            if name in OBJECTIVES:
                row["objective"] = OBJECTIVES[name]
            clubs[str(c["id"])] = row

    # Every witnessed objective must land on exactly one game_db club.
    unmatched = [n for n in OBJECTIVES if n not in by_name]
    if unmatched:
        raise SystemExit(f"objective names not in game_db: {unmatched}")
    dupes = [n for n in OBJECTIVES if len(by_name.get(n, [])) != 1]
    if dupes:
        raise SystemExit(f"objective names ambiguous in game_db: {dupes}")

    OUT.write_text(json.dumps({
        "_source": "EQUIPOS club-header budget u32 (param_1[0x7a]) + START OF SEASON "
                   "witness frames 2026-07-19; see tools/re/export_club_economy.py",
        "clubs": clubs,
    }, indent=0, sort_keys=True) + "\n")
    print(f"wrote {OUT.name}: {len(clubs)} clubs with budget, "
          f"{sum(1 for v in clubs.values() if 'objective' in v)} with witnessed objective; "
          f"{len(missing_budget)} game_db names without an EQUIPOS budget row: "
          f"{missing_budget[:5]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
