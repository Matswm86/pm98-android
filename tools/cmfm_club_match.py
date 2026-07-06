#!/usr/bin/env python3
"""Map FM retro-DB club ids -> PM98 clubs by squad overlap voting.

The .fm snapshot club-name table is re-indexed after mod deletions, so names read
from it drift for higher ids (Real Madrid: refs say 1736, table says 1733). Instead
of trusting it, vote: a player extracted at FM club X who also exists in PM98's
game_db (same surname + birth year) at PM98 club Y is a vote X->Y. Squad cores
persist 1997->2000, so real club pairs collect many votes; coincidental surname
collisions don't.

Reads extracted/cmfm/all_*.csv (ALL ages — stars carry the vote) and writes
  extracted/cmfm/club_map.json   {fm_id: {"pm98": name, "votes": n, "runnerUp": n}}
  extracted/cmfm/club_map_review.csv   the full vote table for eyeballing
Then rewrites players_*.csv Club fields through the map (unmapped -> FM#id kept).
"""

from __future__ import annotations

import csv
import json
import re
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CM = ROOT / "extracted" / "cmfm"
MIN_VOTES = 3
DOMINANCE = 2.0


def fold(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c)).upper().strip()


def surname(full: str) -> str:
    parts = fold(full).split()
    return parts[-1] if parts else ""


def load_pm98() -> tuple[dict[tuple[str, int], set[str]], dict[str, str]]:
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text())
    key_to_clubs: dict[tuple[str, int], set[str]] = defaultdict(set)
    for club in db["clubs"]:
        for p in club["players"]:
            key_to_clubs[(surname(p["legalName"]), p["birthYear"])].add(club["name"])
    return key_to_clubs, {c["name"]: c["name"] for c in db["clubs"]}


def club_id_of(row: dict, name_to_id: dict[str, int]) -> int | None:
    c = row["Club"]
    m = re.fullmatch(r"FM#(\d+)", c)
    if m:
        return int(m.group(1))
    return name_to_id.get(c)


def main() -> None:
    clubs_cache = json.loads((CM / "clubs_cache.json").read_text())
    name_to_id = {v: int(k) for k, v in clubs_cache.items()}
    pm98_keys, _ = load_pm98()

    votes: dict[int, Counter] = defaultdict(Counter)
    fm_names: dict[int, str] = {}
    for f in sorted(CM.glob("all_*.csv")):
        for row in csv.DictReader(open(f)):
            fid = club_id_of(row, name_to_id)
            if fid is None:
                continue
            if not row["Club"].startswith("FM#"):
                fm_names.setdefault(fid, row["Club"])
            key = (surname(row["Name"]), int(row["BirthYear"]))
            for pm_club in pm98_keys.get(key, ()):
                votes[fid][pm_club] += 1

    mapping: dict[int, dict] = {}
    with open(CM / "club_map_review.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["fm_id", "fm_table_name", "pm98_club", "votes", "runner_up", "runner_votes", "accepted"])
        for fid, ctr in sorted(votes.items()):
            (best, n), *rest = ctr.most_common(2) + [(None, 0)] * 1
            run, rn = rest[0] if rest else (None, 0)
            ok = n >= MIN_VOTES and n >= DOMINANCE * max(rn, 1)
            w.writerow([fid, fm_names.get(fid, ""), best, n, run or "", rn or "", ok])
            if ok:
                mapping[fid] = {"pm98": best, "votes": n, "runnerUp": rn}
    (CM / "club_map.json").write_text(json.dumps(mapping, indent=1))
    print(f"[map] {len(mapping)} FM clubs mapped to PM98 clubs (of {len(votes)} with any vote)")

    # nation id -> name map (sortitoutsi/fmref list; anchors 771 Germany, 801 Wales,
    # 783 Moldova, 787 Poland, 776 Italy, 800 Ukraine verified against in-file records)
    nations_file = CM / "nations.json"
    nations = (
        {int(k): v for k, v in json.loads(nations_file.read_text()).items()}
        if nations_file.exists()
        else {}
    )

    for f in sorted(CM.glob("players_*.csv")):
        if f.stem.endswith("_mapped"):
            continue
        rows = list(csv.DictReader(open(f)))
        hit = 0
        for row in rows:
            fid = club_id_of(row, name_to_id)
            if fid is not None and fid in mapping:
                row["Club"] = mapping[fid]["pm98"]
                hit += 1
            if row.get("Nat", "").isdigit():
                row["Nat"] = nations.get(int(row["Nat"]), row["Nat"]).upper()
        out = f.with_name(f.stem + "_mapped.csv")
        with open(out, "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
            w.writeheader()
            w.writerows(rows)
        print(f"[out] {out.name}: {hit}/{len(rows)} rows at PM98-mapped clubs")


if __name__ == "__main__":
    main()
