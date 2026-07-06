#!/usr/bin/env python3
"""Build/extend assets/talent_pool.json -- the real-talent injection pool.

The pool is the season-keyed roster of REAL footballers who "come up" at their real
club as a career rolls past 1997-98 (Talent.gd / TalentDB.gd consume it; no file =
feature off). Entries carry identity + a talent TIER; the in-game attribute row is
generated at injection time, so no FM/CM ratings are shipped -- only who, where, when.

Inputs (any mix, repeatable):
  *.csv        FM/Genie-Scout view export, or the hand-curated starter file.
               Recognised columns (case-insensitive): Name, Club, Position/Pos,
               Nat/Nationality, DoB/Born, BirthYear, Age, CA, PA, Tier, Season, Notes.
  *.html/.htm  FM's Ctrl+P "web page" view export (first <table> is read with the
               same column names).

Season per row: a Season column ("2002-03" / "2002/03"), else --season for the file.
Tier per row: an explicit Tier column (1-5), else mapped from PA (FM 1-200 scale),
else --default-tier.

Usage:
  python3 tools/talent_ingest.py tools/starter_talents.csv --include-eggs
  python3 tools/talent_ingest.py exports/fm_9899.html --season 1998-99
  ship: cp assets/talent_pool.json app/data/talent_pool.json

Dedupe: anyone already in app/data/game_db.json (Michael Owen is at Liverpool in the
97-98 DB) is skipped; the same talent across overlapping exports keeps his earliest
debut season. Unresolved club names land in assets/talent_review.json -- edit its
"resolveTo" (a club id from game_db, or -1 to drop) and re-run.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import unicodedata
from html.parser import HTMLParser
from pathlib import Path

from build_db import build_flag_lookup, flag_for, norm

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
POOL_PATH = ASSETS / "talent_pool.json"
REVIEW_PATH = ASSETS / "talent_review.json"
GAME_DB = ROOT / "app" / "data" / "game_db.json"
EGGS_PATH = ASSETS / "easter_eggs.json"

TALENT_ID_BASE = 600000  # Talent.gd's band: below FREE 700000, above seniors ~8k
ENGLAND = "ENGLAND"

# The live in-game wonderkid stays hardcoded in Youth.gd; never pool him.
EXCLUDED_NAMES = {"MATS MJATVEDT", "MATS MJÅTVEDT"}

# FM club spellings that the fuzzy matcher can't bridge to the 1997 DB names.
CLUB_OVERRIDES = {
    "MAN UTD": "MANCHESTER UTD.",
    "MAN CITY": "MANCHESTER C",
    "MANCHESTER CITY": "MANCHESTER C",
    "MANCHESTER UNITED": "MANCHESTER UTD.",
    "SPURS": "TOTTENHAM H",
    "TOTTENHAM HOTSPUR": "TOTTENHAM H",
    "WEST HAM": "WEST HAM UTD",
    "WEST HAM UNITED": "WEST HAM UTD",
    "LEEDS": "LEEDS UTD",
    "LEEDS UNITED": "LEEDS UTD",
    "NEWCASTLE": "NEWCASTLE UTD",
    "NEWCASTLE UNITED": "NEWCASTLE UTD",
    "BARCELONA": "F.C. BARCELONA",
    "REAL MADRID": "REAL MADRID C.F.",
}

# FM nationality spellings -> the game's PAISES table names (build_db.FLAG_ALIASES
# covers the extractor's variants; these are the FM-side ones).
NAT_ALIASES = {
    "IRELAND": "REP. OF IRELAND",
    "REPUBLIC OF IRELAND": "REP. OF IRELAND",
    "IVORY COAST": "COSTA DE MARFIL",
    "KOREA REPUBLIC": "SOUTH KOREA",
    "SOUTH KOREA": "SOUTH KOREA",
    "UNITED STATES": "U.S.A.",
    "USA": "U.S.A.",
    "HOLLAND": "NETHERLANDS",
}

PA_TIERS = [(180, 1), (165, 2), (150, 3), (130, 4)]  # PA >= x -> tier (else 5)

COLUMN_ALIASES = {
    "name": {"name", "player", "player name"},
    "club": {"club", "team"},
    "pos": {"position", "pos", "best pos"},
    "nat": {"nat", "nationality", "nation"},
    "dob": {"dob", "born", "date of birth", "birth date"},
    "birthyear": {"birthyear", "birth year", "yob"},
    "age": {"age"},
    "ca": {"ca", "current ability"},
    "pa": {"pa", "potential ability"},
    "tier": {"tier"},
    "season": {"season", "debut", "debutseason"},
    "notes": {"notes", "note"},
}


def fold(s: str) -> str:
    """Uppercase ASCII fold for dedupe keys (build_db-style)."""
    s = unicodedata.normalize("NFKD", str(s)).encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", s.upper()).strip()


def surname(full: str) -> str:
    """DB display convention: the (folded) last name token."""
    toks = fold(full).split()
    return toks[-1] if toks else "?"


def parse_pos(raw: str) -> tuple[str, bool]:
    s = fold(raw)
    if "GK" in s or s == "G":
        return "GK", True
    if s in {"DF", "FW", "MF"}:
        return s, False
    if "ST" in s or s.startswith("F"):
        return "FW", False
    if s.startswith("D") and not s.startswith("DM"):
        return "DF", False
    return "MF", False


def parse_season(raw: str) -> tuple[str, int] | None:
    m = re.search(r"(\d{4})\s*[-/]\s*(\d{2,4})", str(raw))
    if not m:
        return None
    start = int(m.group(1))
    return f"{start}-{(start + 1) % 100:02d}", start


def tier_for(row: dict, default: int) -> int:
    if row.get("tier"):
        return max(1, min(5, int(float(row["tier"]))))
    if row.get("pa"):
        pa = int(float(row["pa"]))
        for cut, t in PA_TIERS:
            if pa >= cut:
                return t
        return 5
    return default


def birth_year(row: dict, season_start: int) -> int | None:
    if row.get("birthyear"):
        return int(float(row["birthyear"]))
    if row.get("dob"):
        m = re.search(r"(\d{4})", row["dob"])
        if m:
            return int(m.group(1))
    if row.get("age"):
        # DB age basis: age = season_start + 1 - birthYear
        return season_start + 1 - int(float(row["age"]))
    return None


class _TableParser(HTMLParser):
    """First <table> of an FM 'web page' export -> list of row dicts."""

    def __init__(self) -> None:
        super().__init__()
        self.rows: list[list[str]] = []
        self._row: list[str] | None = None
        self._cell: list[str] | None = None
        self._done = False

    def handle_starttag(self, tag: str, attrs) -> None:
        if self._done:
            return
        if tag == "tr":
            self._row = []
        elif tag in ("td", "th"):
            self._cell = []

    def handle_endtag(self, tag: str) -> None:
        if self._done:
            return
        if tag in ("td", "th") and self._cell is not None and self._row is not None:
            self._row.append(" ".join("".join(self._cell).split()))
            self._cell = None
        elif tag == "tr" and self._row:
            self.rows.append(self._row)
            self._row = None
        elif tag == "table" and self.rows:
            self._done = True

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.append(data)


def read_rows(path: Path) -> list[dict]:
    """File -> normalized row dicts keyed by canonical column names."""
    if path.suffix.lower() in (".html", ".htm"):
        p = _TableParser()
        p.feed(path.read_text(encoding="utf-8", errors="replace"))
        if not p.rows:
            sys.exit(f"{path}: no <table> rows found")
        header, data = p.rows[0], p.rows[1:]
        raw = [dict(zip(header, r)) for r in data if len(r) == len(header)]
    else:
        with path.open(encoding="utf-8-sig", newline="") as f:
            raw = list(csv.DictReader(f))
    out = []
    for r in raw:
        row: dict = {}
        for k, v in r.items():
            if k is None or v is None:
                continue
            kl = k.strip().lower()
            for canon, aliases in COLUMN_ALIASES.items():
                if kl in aliases:
                    row[canon] = v.strip()
        if row.get("name"):
            out.append(row)
    return out


def load_json(path: Path, fallback):
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return fallback


def club_index(db: dict) -> dict[str, dict]:
    return {norm(c["name"]): c for c in db["clubs"]}


def resolve_club(name: str, by_norm: dict[str, dict], review: dict) -> int | None:
    """Club name -> game_db id: overrides, review resolutions, exact norm, token subset."""
    key = fold(name)
    if key in CLUB_OVERRIDES:
        key = CLUB_OVERRIDES[key]
    for res in review.get("unmatched", []):
        if fold(res.get("clubName", "")) == fold(name) and res.get("resolveTo") is not None:
            rid = int(res["resolveTo"])
            return None if rid < 0 else rid
    nk = norm(key)
    if nk in by_norm:
        return int(by_norm[nk]["id"])
    toks = set(nk.split())
    hits = [c for k, c in by_norm.items() if toks and toks <= set(k.split())]
    if len(hits) == 1:
        return int(hits[0]["id"])
    return None


def db_player_keys(db: dict) -> set[str]:
    keys = set()
    for c in db["clubs"]:
        for p in c.get("players", []):
            by = p.get("birthYear")
            if by:
                for nm in (p.get("legalName"), p.get("name")):
                    if nm:
                        keys.add(f"{fold(nm)}|{int(by)}")
    return keys


def egg_entries() -> list[dict]:
    """Fold the standalone easter-egg wonderkids (Solli) into the pool as
    manager-routed talents. The live Youth.gd wonderkid is excluded."""
    eggs = load_json(EGGS_PATH, {}).get("players", [])
    out = []
    for e in eggs:
        if fold(e.get("name", "")) in EXCLUDED_NAMES:
            continue
        by = int(e["birthYear"])
        start = by + 15  # arrives the season he turns 15 (age 16 on the DB basis)
        out.append(
            {
                "legal": fold(e.get("legalName", e["name"])),
                "display": e.get("name", "?"),
                "birthYear": by,
                "nationality": fold(e.get("nationality", ENGLAND)),
                "pos": "FW" if not e.get("isGK") else "GK",
                "isGK": bool(e.get("isGK", False)),
                "clubId": None,
                "clubName": None,
                "route": "manager_youth",
                "season": f"{start}-{(start + 1) % 100:02d}",
                "debutYear": start,
                "tier": 1,
                "potential": 96,
                "notes": "easter egg (assets/easter_eggs.json)",
            }
        )
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("inputs", nargs="*", type=Path, help="CSV / FM html view exports")
    ap.add_argument("--season", help="season for rows without a Season column, e.g. 1998-99")
    ap.add_argument("--default-tier", type=int, default=4)
    ap.add_argument(
        "--include-eggs",
        action="store_true",
        help="fold assets/easter_eggs.json (Solli) into the pool",
    )
    args = ap.parse_args()

    db = load_json(GAME_DB, None)
    if db is None:
        sys.exit(f"{GAME_DB} missing -- run tools/build_db.py first")
    by_norm = club_index(db)
    known = db_player_keys(db)
    flags = build_flag_lookup()
    review = load_json(REVIEW_PATH, {"unmatched": []})
    pool = load_json(POOL_PATH, {"meta": {}, "talents": []})
    talents: list[dict] = pool.get("talents", [])
    by_key = {t["key"]: t for t in talents}
    next_id = max([t["id"] for t in talents] + [TALENT_ID_BASE])

    candidates: list[dict] = []
    for path in args.inputs:
        file_season = parse_season(args.season or "")
        for row in read_rows(path):
            season = parse_season(row.get("season", "")) or file_season
            if not season:
                sys.exit(f"{path}: row '{row.get('name')}' has no season (use --season)")
            label, start = season
            by = birth_year(row, start)
            if by is None:
                print(f"  SKIP {row['name']}: no DoB/BirthYear/Age", file=sys.stderr)
                continue
            pos, is_gk = parse_pos(row.get("pos", "MF"))
            nat = fold(row.get("nat", ENGLAND)) or ENGLAND
            nat = NAT_ALIASES.get(nat, nat)
            candidates.append(
                {
                    "legal": fold(row["name"]),
                    "display": surname(row["name"]),
                    "birthYear": by,
                    "nationality": nat,
                    "pos": pos,
                    "isGK": is_gk,
                    "clubName": row.get("club", ""),
                    "clubId": "unresolved",
                    "route": "club",
                    "season": label,
                    "debutYear": start,
                    "tier": tier_for(row, args.default_tier),
                    "potential": None,
                    "notes": row.get("notes") or None,
                }
            )
    if args.include_eggs:
        candidates += egg_entries()

    added = updated = skipped_known = 0
    unresolved: dict[str, list[str]] = {}
    for c in candidates:
        key = f"{c['legal']}|{c['birthYear']}"
        if c["legal"] in EXCLUDED_NAMES:
            continue
        # DB legalNames carry middle names ("MICHAEL JAMES OWEN"), so match on the
        # full fold OR the DB's surname-style display name + birth year. Slightly
        # eager (any same-surname same-year pro trips it) -- skips are printed so a
        # false positive is visible to the curator.
        if key in known or f"{c['display']}|{c['birthYear']}" in known:
            skipped_known += 1
            print(f"  in 97-98 DB already, skipped: {c['legal']} ({c['birthYear']})")
            continue
        if c["clubId"] == "unresolved":
            cid = resolve_club(c["clubName"], by_norm, review)
            if cid is None:
                unresolved.setdefault(c["clubName"], []).append(c["legal"])
                continue
            c["clubId"] = cid
            c["clubName"] = by_norm[
                norm(
                    next(  # canonical DB spelling
                        cl["name"] for cl in db["clubs"] if int(cl["id"]) == cid
                    )
                )
            ]["name"]
        if key in by_key:  # overlapping exports: keep the earliest debut
            t = by_key[key]
            if c["debutYear"] < int(t["debutYear"]):
                t["debutYear"], t["debutSeason"] = c["debutYear"], c["season"]
                updated += 1
            continue
        next_id += 1
        entry = {
            "id": next_id,
            "key": key,
            "name": c["display"],
            "legalName": c["legal"],
            "birthYear": c["birthYear"],
            "nationality": c["nationality"],
            "flagCode": flag_for(c["nationality"], flags),
            "kind": "NATIONAL" if c["nationality"] == ENGLAND else "NON-NATIONAL",
            "pos": c["pos"],
            "posFine": None,
            "isGK": c["isGK"],
            "clubId": c["clubId"],
            "clubName": c["clubName"],
            "route": c["route"],
            "debutSeason": c["season"],
            "debutYear": c["debutYear"],
            "tier": c["tier"],
            "ca": None,
            "potential": c["potential"],
            "heightCm": None,
            "weightKg": None,
        }
        if c.get("notes"):
            entry["notes"] = c["notes"]
        talents.append(entry)
        by_key[key] = entry
        added += 1

    talents.sort(key=lambda t: (t["debutYear"], t["id"]))
    seasons = sorted({t["debutSeason"] for t in talents})
    pool = {
        "meta": {
            "note": (
                "Real-talent injection pool (easter-egg lane; ORIGINAL curation -- "
                "identity + tier only, attribute rows are generated in-game)"
            ),
            "idBase": TALENT_ID_BASE,
            "seasons": seasons,
            "counts": {"talents": len(talents), "unresolvedClubs": len(unresolved)},
        },
        "talents": talents,
    }
    POOL_PATH.write_text(json.dumps(pool, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    if unresolved:
        merged = {fold(u.get("clubName", "")): u for u in review.get("unmatched", [])}
        for club, players in unresolved.items():
            merged.setdefault(fold(club), {"clubName": club, "players": players, "resolveTo": None})
        review = {"unmatched": sorted(merged.values(), key=lambda u: u["clubName"])}
        REVIEW_PATH.write_text(
            json.dumps(review, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        print(f"\nUNRESOLVED clubs -> {REVIEW_PATH.name} (set resolveTo and re-run):")
        for club, players in unresolved.items():
            print(f"  {club}: {', '.join(players)}")

    print(
        f"\n{POOL_PATH.name}: {len(talents)} talents over {len(seasons)} seasons "
        f"(+{added} new, {updated} re-dated, {skipped_known} already in 97-98 DB)"
    )
    print(f"ship: cp {POOL_PATH.relative_to(ROOT)} app/data/talent_pool.json")


if __name__ == "__main__":
    main()
