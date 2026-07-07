#!/usr/bin/env python3
"""Audit: which NAMED clubs in the mapped CSVs fail resolve_club but ARE a real
PM98 club under a different spelling -> players lose their true origin (the
'River Plate' vs 'River' bug class). Ranks candidates by young-player count."""
import csv
import difflib
import json
from collections import defaultdict
from pathlib import Path

import talent_ingest as ti

ROOT = Path(__file__).resolve().parent.parent
db = json.loads((ROOT / "assets/game_db.json").read_text())
by_norm = ti.club_index(db)
review = ti.load_json(ROOT / "assets/talent_review.json", {"unmatched": []})
pm98_names = [c["name"] for c in db["clubs"]]
pm98_norm = {ti.norm(n): n for n in pm98_names}

csvs = sorted((ROOT / "extracted/cmfm").glob("players_*_mapped.csv"))
csvs += [ROOT / "extracted/fm05/players_2004-05.csv", ROOT / "extracted/fm06/players_2005-06.csv"]

# First pass: tally DISTINCT club names per season (cheap), resolve only distinct.
raw = defaultdict(lambda: {"seasons": set(), "count": 0})
for path in csvs:
    if not path.exists():
        continue
    season = path.stem.replace("players_", "").replace("_mapped", "")
    for row in csv.DictReader(path.open()):
        club = (row.get("Club") or row.get("club") or "").strip()
        if not club or club.upper().startswith("FM#"):
            continue
        raw[club]["seasons"].add(season)
        raw[club]["count"] += 1

# resolve each DISTINCT name once (was per-row -> 200k*476; now ~thousands*476)
unresolved = {n: info for n, info in raw.items()
              if ti.resolve_club(n, by_norm, review) is None}
print(f"[audit] {len(raw)} distinct named clubs, {len(unresolved)} unresolved", flush=True)

pm98_tok = {pn_norm: set(pn_norm.split()) for pn_norm in pm98_norm}
norm_keys = list(pm98_norm)

# For each unresolved name: best token-Jaccard club + a get_close_matches seq check
rows = []
for name, info in unresolved.items():
    nk = ti.norm(name)
    toks = set(nk.split())
    best, best_score = None, 0.0
    for pn_norm, pt in pm98_tok.items():
        u = toks | pt
        jacc = len(toks & pt) / len(u) if u else 0
        if jacc > best_score:
            best, best_score = pm98_norm[pn_norm], jacc
    seq_hit = difflib.get_close_matches(nk, norm_keys, n=1, cutoff=0.6)
    if seq_hit:
        seq_score = difflib.SequenceMatcher(None, nk, seq_hit[0]).ratio()
        if seq_score > best_score:
            best, best_score = pm98_norm[seq_hit[0]], seq_score
    rows.append((info["count"], name, best, round(best_score, 2), sorted(info["seasons"])))

rows.sort(reverse=True)
print(f"{'cnt':>4}  {'extract club':32} -> {'closest PM98':26} sim  seasons")
print("-" * 100)
LIKELY = 0.55  # threshold above which it's probably the same club, wrong spelling
for cnt, name, best, score, seasons in rows:
    flag = " <== LIKELY SAME CLUB" if score >= LIKELY else ""
    print(f"{cnt:>4}  {name[:32]:32} -> {str(best)[:26]:26} {score:.2f}  {','.join(seasons)}{flag}")
print(f"\n{len(rows)} distinct unresolved named clubs; "
      f"{sum(1 for r in rows if r[3] >= LIKELY)} flagged LIKELY-SAME "
      f"({sum(r[0] for r in rows if r[3] >= LIKELY)} young-player rows).")
