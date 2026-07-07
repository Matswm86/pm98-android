#!/usr/bin/env python3
"""Conservative club-alias finder: a PM98 club is the SAME as an unresolved
extract club ONLY if the PM98 name's tokens are a subset of the extract name's
tokens AND every EXTRA token is a known corporate affix (FC, SC, AS, ...), never
a geographic qualifier. This maps 'AFC Ajax'->Ajax but rejects 'Ajax Cape Town'
and the fuzzy false positives (Internacional/Juventude/Bastia)."""
import csv
import json
from collections import defaultdict
from pathlib import Path

import talent_ingest as ti

# Corporate/legal affixes that carry no identity (safe to ignore). NOT geographic.
AFFIX = {
    "fc", "sc", "as", "ec", "cr", "afc", "cf", "sk", "kv", "vv", "sad", "if",
    "ifk", "fk", "cd", "aj", "ogc", "ac", "us", "ca", "rc", "sv", "bv", "sbv",
    "nv", "kaa", "ksk", "kvc", "rcd", "ud", "sd", "club", "de", "1899", "1893",
    "1921", "1999", "1900", "football", "fussball", "calcio", "spa", "srl",
    "kf", "nk", "hnk", "fbpa", "sad.", "gf", "bk", "if.", "ff", "aik",
}


def main():
    root = Path(__file__).resolve().parent.parent
    db = json.loads((root / "assets/game_db.json").read_text())
    by_norm = ti.club_index(db)
    review = ti.load_json(root / "assets/talent_review.json", {"unmatched": []})
    # PM98 clubs indexed by their token set (norm)
    pm98 = [(ti.norm(c["name"]), c["name"], c["id"], (c.get("country") or "").upper())
            for c in db["clubs"]]

    csvs = sorted((root / "extracted/cmfm").glob("players_*_mapped.csv"))
    raw = defaultdict(lambda: {"seasons": set(), "count": 0})
    for path in csvs:
        season = path.stem.replace("players_", "").replace("_mapped", "")
        for row in csv.DictReader(path.open()):
            club = (row.get("Club") or row.get("club") or "").strip()
            if not club or club.upper().startswith("FM#"):
                continue
            raw[club]["seasons"].add(season)
            raw[club]["count"] += 1

    hits, ambiguous = [], []
    for name, info in raw.items():
        if ti.resolve_club(name, by_norm, review) is not None:
            continue
        etoks = set(ti.norm(name).split())
        cands = []
        for pnorm, pname, pid, pcountry in pm98:
            ptoks = set(pnorm.split())
            if ptoks and ptoks < etoks:  # PM98 name strictly inside extract name
                extra = etoks - ptoks
                if extra <= AFFIX:  # every extra token is a corporate affix
                    cands.append((pname, pid))
        if len(cands) == 1:
            hits.append((info["count"], name, cands[0][0], cands[0][1], sorted(info["seasons"])))
        elif len(cands) > 1:
            ambiguous.append((info["count"], name, [c[0] for c in cands], sorted(info["seasons"])))

    hits.sort(reverse=True)
    ambiguous.sort(reverse=True)
    print("=== HIGH-CONFIDENCE aliases (PM98 name fully inside extract name, extras = affixes only) ===")
    print(f"{'cnt':>4}  {'extract club':34} -> {'PM98 club':20} seasons")
    for cnt, name, pm, pid, seasons in hits:
        print(f"{cnt:>4}  {name[:34]:34} -> {pm[:20]:20} {','.join(seasons)}")
    print(f"\n{len(hits)} high-confidence aliases, {sum(h[0] for h in hits)} young-player rows affected.")
    if ambiguous:
        print(f"\n=== AMBIGUOUS ({len(ambiguous)}, matched >1 PM98 club — need manual pick) ===")
        for cnt, name, pms, seasons in ambiguous[:20]:
            print(f"{cnt:>4}  {name[:34]:34} -> {pms}")
    # emit ready-to-paste CLUB_OVERRIDES lines
    print("\n=== CLUB_OVERRIDES lines ===")
    for cnt, name, pm, pid, seasons in hits:
        print(f'    "{ti.fold(name)}": "{pm}",')


if __name__ == "__main__":
    main()
