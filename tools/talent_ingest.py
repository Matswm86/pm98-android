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
else --default-tier. A NEGATIVE PA is an FM random-potential code (-10..-1 whole
stars, -95..-15 half steps, -95 = "9.5"; -10 = PA 170-200, each half-step down
shifts the band by -10): the game rolls a real PA inside the band at new-game time,
and so do we — deterministically from name|birthYear, so re-runs are stable.

Club "FM#<id>" (or blank) = a club that does not exist in PM98's 476-club world:
the player is pooled as a FREE AGENT (route "free_agent", clubId -1) instead of
going through club resolution — he surfaces in the free-agent pool at his debut
season, signable for no fee. EXCEPT tier 5: bulk FA rows at tier 5 are dropped
outright (printed count) — the FA market takes 18 best-first per season, regen
FAs already fill the filler role, and with 8 bulk seasons (~100k young rows)
they'd bloat the shipped JSON past what TalentDB can sanely parse on-device.
Hand-curated rows are exempt, as everywhere.

Usage:
  python3 tools/talent_ingest.py tools/starter_talents.csv --include-eggs
  python3 tools/talent_ingest.py exports/fm_9899.html --season 1998-99
  ship: cp assets/talent_pool.json app/data/talent_pool.json

Dedupe: anyone already in app/data/game_db.json (Michael Owen is at Liverpool in the
97-98 DB) is skipped; the same talent across overlapping exports keeps his earliest
debut season -- EXCEPT a hand-curated row (one with an explicit Tier column), which
REPLACES the bulk-extracted entry outright (curation outranks extraction: ingest the
FM exports first, the curated starter file last). Unresolved club names land in
assets/talent_review.json -- edit its "resolveTo" (a club id from game_db, -1 to
drop the players entirely, or leave null to keep them as free agents) and re-run.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
import unicodedata
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

from build_db import ENGLAND_CODE, build_flag_lookup
from extract_english import EU_EEA_1997

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

# Human audit layer for junk SOURCE rows (misparse or DB oddities — e.g. the
# clubless PA-190 unknowns the FM05/06 extraction surfaced). Keyed
# fold(Name)|BirthYear; matching bulk rows are dropped and logged. Curated
# rows are exempt (curation outranks vetoes). A veto that matches nothing is
# warned about so stale entries surface.
VETOES_PATH = Path(__file__).resolve().parent / "talent_vetoes.csv"


def load_vetoes() -> dict[str, str]:
    if not VETOES_PATH.exists():
        return {}
    with open(VETOES_PATH) as fh:
        return {
            f"{fold(r['Name'])}|{int(r['BirthYear'])}": (r.get("Reason") or "").strip()
            for r in csv.DictReader(fh)
        }


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
    # The CM0102 (02-03) and FM06 (04-05/05-06) extracts carry FULL formal club
    # names ("SE Palmeiras", "AS Roma", "Grêmio FBPA") that PM98 stores short.
    # These aliases are SAFE by construction: the PM98 name is fully contained in
    # the extract name and every extra token is a corporate affix (FC/SC/AS/...),
    # never a geographic qualifier -- so no wrong-club risk (verified, 0 ambiguous).
    # Uruguay's "CA River Plate" (Montevideo) is a DIFFERENT club -> left unmapped.
    "RIVER PLATE": "River",
    "AJ AUXERRE": "Auxerre",
    "AS CANNES FOOTBALL": "Cannes",
    "AS CANNES": "Cannes",
    "AS MONACO FC": "Mónaco",
    "AS MONACO": "Mónaco",
    "AS ROMA": "Roma",
    "BARROW AFC": "Barrow",
    "CA PENAROL": "Peñarol",
    "CR FLAMENGO": "Flamengo",
    "CR VASCO DA GAMA": "Vasco da Gama",
    "CRUZEIRO EC": "Cruzeiro",
    "FENERBAHCE SK": "Fenerbahce",
    "FLUMINENSE FOOTBALL CLUB": "Fluminense",
    "FOOTBALL CLUB THE STRONGEST": "The Strongest",
    "GALATASARAY SK": "Galatasaray",
    "GREMIO FBPA": "Gremio",
    "HELSINGBORGS IF": "Helsingborgs",
    "IFK GOTEBORG": "Göteborg",
    "K LIERSE SK": "Lierse",
    "NK GORICA": "Gorica",
    "NK PRIMORJE": "Primorje",
    "NK VARTEKS": "Varteks",
    "OREBRO SK": "Orebro",
    "SANTOS FOOTBALL CLUB": "Santos",
    "SC HEERENVEEN": "Heerenveen",
    "SE PALMEIRAS": "Palmeiras",
    "SK STURM GRAZ": "Sturm Graz",
}

# FM nationality spellings -> the game's PAISES table names (127 nations, 1997-era
# spellings: ZAIRE, BIELORUSSIA, QUATAR, COSTA MARFIL...). Verified pair by pair
# against assets/country_codes.json byName. A leading "THE " is stripped before
# lookup (FM26 uses official long names). Nations absent from the 1997 table
# (Belize, Haiti, Vanuatu...) stay unmapped -> default flag, counted + reported.
NAT_ALIASES = {
    "IRELAND": "REP. OF IRELAND",
    "REPUBLIC OF IRELAND": "REP. OF IRELAND",
    "NORTHERN IRELAND": "NORTH. IRELAND",
    "IVORY COAST": "COSTA MARFIL",
    "COTE D'IVOIRE": "COSTA MARFIL",
    "UNITED STATES": "U.S.A.",
    "UNITED STATES OF AMERICA": "U.S.A.",
    "USA": "U.S.A.",
    "NETHERLANDS": "HOLLAND",
    "TURKIYE": "TURKEY",
    "CZECHIA": "CZECH REPUBLIC",
    "BOSNIA AND HERZEGOVINA": "BOSNIA",
    "BOSNIA-HERZEGOVINA": "BOSNIA",  # CM01/02 spelling
    "FYR OF MACEDONIA": "MACEDONIA",  # CM01/02 spelling
    "CHINA PR": "CHINA",  # CM01/02 spelling
    "TRINIDAD AND TOBAGO": "TRINIDAD T.",
    "AZERBAIJAN": "AZERBAYAN",
    "DEMOCRATIC REPUBLIC OF THE CONGO": "ZAIRE",
    "DR CONGO": "ZAIRE",
    "REPUBLIC OF THE CONGO": "CONGO",
    "REPUBLIC OF NORTH MACEDONIA": "MACEDONIA",
    "NORTH MACEDONIA": "MACEDONIA",
    "ISLAMIC REPUBLIC OF IRAN": "IRAN",
    "CAPE VERDE": "CABO VERDE",
    "BELARUS": "BIELORUSSIA",
    "QATAR": "QUATAR",
    "GUINEA-BISSAU": "GUINEA BISSAU",
    "LATVIA": "LETONIA",
    "TAJIKISTAN": "TADJIKISTAN",
    "UZBEKISTAN": "UZBEKISTHAN",
    "SURINAME": "SURINAM",
    "NIGER": "NÍGER",
}

# Post-Bosman "comunitario" rule for the FICHA KIND flag: EU-15 + EEA in 1997
# (same rule game_db uses). extract_english spells Ireland EIRE / NORTHERN IRELAND;
# our canonical nats use the PAISES spellings, so both are listed.
EU_EEA_PAISES = {"REP. OF IRELAND", "NORTH. IRELAND"}


def canon_nat(raw: str, lut: dict[str, int]) -> str:
    """FM nationality string -> PAISES spelling (empty stays empty)."""
    for cand in dict.fromkeys((raw, raw[4:] if raw.startswith("THE ") else raw)):
        cand = NAT_ALIASES.get(cand, cand)
        if cand == ENGLAND or cand.upper() in lut:
            return cand
    return NAT_ALIASES.get(raw, raw)


def kind_of(nat: str) -> str:
    return "NATIONAL" if nat in EU_EEA_1997 or nat in EU_EEA_PAISES else "NON-NATIONAL"


def merge_variants(talents: list[dict]) -> list[str]:
    """Cross-file identity sweep. The three mods spell the same player differently
    ("FAIOLI"/"FAIOHLE") and occasionally shift a birth year by one, which the
    key-level dedupe cannot see. Conservative auto-merge, every merge logged:
      - same (first name token, last name token, birthYear) with compatible clubs
        (equal, or one side is a free agent), compatible nations AND similar full
        names (token subset, or a single small-typo token: FAIOLI~FAIOHLE) -> same
        person. First+last alone is NOT enough: Brazilian suffix last-tokens
        (SILVA/NETO/JUNIOR) make "ANDERSON ... DA SILVA" match distinct people;
      - same (last name token, birthYear) pairs that pass the same gates: catches
        first-token variants (XABI/XABIER ALONSO) and common-name-vs-legal subsets
        (BOJINOV vs VALERI BOJINOV) that the first-token grouping splits apart;
      - identical legalName, birth years exactly 1 apart, same position, compatible
        clubs -> same person (per-file year-shift jitter).
    Keeps the club-routed / earliest-debut entry with the fullest spelling; a
    curated pin always survives and never has its debut backdated. Same-person
    rows at DIFFERENT clubs (real transfers: CR7 Sporting->ManUtd) are out of
    scope by design — cull those via tools/talent_vetoes.csv, keep the origin row."""
    logs: list[str] = []
    dropped: set[int] = set()

    def edit1(a: str, b: str) -> bool:
        """Levenshtein distance <= 2 for short tokens (typo variants)."""
        if abs(len(a) - len(b)) > 2:
            return False
        prev = list(range(len(b) + 1))
        for i, ch in enumerate(a, 1):
            cur = [i]
            for j, ch2 in enumerate(b, 1):
                cur.append(min(prev[j] + 1, cur[-1] + 1, prev[j - 1] + (ch != ch2)))
            prev = cur
        return prev[-1] <= 2

    def similar_names(a: str, b: str) -> bool:
        ta, tb = a.split(), b.split()
        if set(ta) <= set(tb) or set(tb) <= set(ta):
            return True
        if len(ta) == len(tb):
            diff = [(x, y) for x, y in zip(ta, tb) if x != y]
            return len(diff) == 1 and edit1(*diff[0])
        return False

    def compatible(a: dict, b: dict) -> bool:
        if "manager_youth" in (a["route"], b["route"]):
            return False
        if a.get("curated") and b.get("curated"):
            return False  # two curated rows are distinct by curator intent
        if not similar_names(a["legalName"], b["legalName"]):
            return False
        ca, cb = int(a.get("clubId") or -1), int(b.get("clubId") or -1)
        if ca > 0 and cb > 0 and ca != cb:
            return False
        na, nb = a["nationality"], b["nationality"]
        unknown_a = "nat unknown" in str(a.get("notes") or "")
        unknown_b = "nat unknown" in str(b.get("notes") or "")
        return na == nb or unknown_a or unknown_b

    def merge_group(group: list[dict]) -> None:
        group = [t for t in group if id(t) not in dropped]
        if len(group) < 2:
            return
        if not all(compatible(a, b) for a in group for b in group if a is not b):
            return
        keep = sorted(
            group,
            key=lambda t: (
                not t.get("curated"),  # a curated pin always survives the merge
                int(t.get("clubId") or -1) <= 0,
                t["debutYear"],
                -len(t["legalName"]),
            ),
        )[0]
        if not keep.get("curated"):  # never backdate a curated pin's debut
            earliest = min(group, key=lambda t: t["debutYear"])
            keep["debutYear"], keep["debutSeason"] = earliest["debutYear"], earliest["debutSeason"]
        for t in group:
            if t is not keep:
                dropped.add(id(t))
                logs.append(
                    f"{t['legalName']}|{t['birthYear']} -> {keep['legalName']}|{keep['birthYear']}"
                )

    by_sig: dict[tuple, list[dict]] = {}
    for t in talents:
        toks = t["legalName"].split()
        if len(toks) >= 2:
            by_sig.setdefault((toks[0], toks[-1], t["birthYear"]), []).append(t)
    for group in by_sig.values():
        merge_group(group)

    # Second sweep keyed by (surname, birthYear) only: catches first-token variants
    # the by_sig key splits apart (XABI/XABIER ALONSO, DINIYAR/DINIJAR, a common-name
    # row that is a token-subset of the legal row: BOJINOV ⊆ VALERI BOJINOV,
    # EMMANUEL ADEBAYOR ⊆ SHEYI EMMANUEL ADEBAYOR). Pairwise, same compatible()
    # gate — full-name subset/typo + club + nation checks still guard the Brazilian
    # suffix-surname trap the docstring warns about.
    by_last: dict[tuple, list[dict]] = {}
    for t in talents:
        if id(t) not in dropped:
            toks = t["legalName"].split()
            by_last.setdefault((toks[-1] if toks else "?", t["birthYear"]), []).append(t)
    for group in by_last.values():
        if 2 <= len(group) <= 25:
            for i, a in enumerate(group):
                for b in group[i + 1 :]:
                    if id(a) not in dropped and id(b) not in dropped:
                        merge_group([a, b])

    by_name: dict[str, list[dict]] = {}
    for t in talents:
        if id(t) not in dropped:
            by_name.setdefault(t["legalName"], []).append(t)
    for group in by_name.values():
        if (
            len(group) == 2
            and abs(group[0]["birthYear"] - group[1]["birthYear"]) == 1
            and group[0]["pos"] == group[1]["pos"]
        ):
            merge_group(group)

    talents[:] = [t for t in talents if id(t) not in dropped]
    return logs


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


# Club-name fuzzy normalizer + flag resolver, carried over verbatim from the
# pre-engine-exact build_db.py (cc06ef4 slimmed it to the EQUIPOS parser; this
# tool is now their only consumer).
def norm(s: str) -> str:
    """Uppercase, strip accents + punctuation + club-form noise for fuzzy match."""
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    s = s.upper()
    for junk in (
        "F.C.",
        "FC",
        "C.F.",
        "CF",
        "R.C.",
        "RC",
        "A.C.",
        "AC",
        "U.D.",
        "S.C.",
        "UTD",
        "UNITED",
        "REAL",
        "CLUB",
        "DEPORTIVO",
    ):
        s = s.replace(junk, " ")
    s = re.sub(r"[^A-Z0-9 ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def flag_for(nationality, lut: dict[str, int]) -> int:
    return lut.get(str(nationality or "").upper(), ENGLAND_CODE)


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


def resolve_pa(row: dict) -> int | None:
    """The row's PA as a real 1-200 value. A negative PA is an FM random-potential
    code (-10..-1 whole stars, halves stored x10 so -95 = "9.5"; -10 = band 170-200,
    each half-step down shifts the band by -10, every band spans 30). FM rolls a real
    PA inside the band at new-game time; we roll seeded from name|birthYear so the
    same player always lands on the same PA across re-runs."""
    if not row.get("pa"):
        return None
    pa = int(float(row["pa"]))
    if pa >= 0:
        return pa
    half_steps = (-pa) // 5 if pa <= -11 else (-pa) * 2  # -95 -> 19, -10 -> 20, -1 -> 2
    hi = min(200, half_steps * 10)
    lo = max(1, hi - 30)
    seed = f"{fold(row.get('name', ''))}|{row.get('birthyear', '')}".encode()
    return lo + int(hashlib.md5(seed).hexdigest(), 16) % (hi - lo + 1)


def tier_for(row: dict, default: int) -> int:
    if row.get("tier"):
        return max(1, min(5, int(float(row["tier"]))))
    pa = resolve_pa(row)
    if pa is not None:
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


def resolve_club(name: str, by_norm: dict[str, dict], review: dict) -> int | str | None:
    """Club name -> game_db id: overrides, review resolutions, exact norm, token subset.
    Returns the id, "drop" (review resolveTo -1: exclude the players entirely), or None
    (unknown club -> the caller pools the players as free agents and lists the club in
    the review file, where a later resolveTo re-routes them on the next rebuild)."""
    key = fold(name)
    if key in CLUB_OVERRIDES:
        key = CLUB_OVERRIDES[key]
    for res in review.get("unmatched", []):
        if fold(res.get("clubName", "")) == fold(name) and res.get("resolveTo") is not None:
            rid = int(res["resolveTo"])
            if rid == 0:  # force free agent (a fuzzy match would land on the WRONG
                return None  # club, e.g. Dundee FC vs PM98's Dundee U.)
            return "drop" if rid < 0 else rid
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
                "curated": False,
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
    club_country = {int(cl["id"]): fold(cl.get("country") or "") for cl in db["clubs"]}
    nat_unknown = 0
    nat_no_flag: Counter = Counter()
    review = load_json(REVIEW_PATH, {"unmatched": []})
    pool = load_json(POOL_PATH, {"meta": {}, "talents": []})
    talents: list[dict] = pool.get("talents", [])
    by_key = {t["key"]: t for t in talents}
    next_id = max([t["id"] for t in talents] + [TALENT_ID_BASE])

    candidates: list[dict] = []
    fa_t5_dropped = 0
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
            nat = canon_nat(fold(row.get("nat", "")), flags)  # "" = source blank
            club = row.get("club", "").strip()
            is_free = not club or club.upper().startswith("FM#")
            tier = tier_for(row, args.default_tier)
            curated = bool(row.get("tier"))
            # Free-agent tier-5 bulk rows never surface (the FA market takes 18
            # best-first per season and regen FAs already fill the filler role),
            # but they dominate the row count: with 8 bulk seasons they'd bloat
            # the shipped JSON past what TalentDB can sanely parse on-device.
            if is_free and tier == 5 and not curated:
                fa_t5_dropped += 1
                continue
            candidates.append(
                {
                    "legal": fold(row["name"]),
                    "display": surname(row["name"]),
                    "birthYear": by,
                    "nationality": nat,
                    "pos": pos,
                    "isGK": is_gk,
                    "clubName": None if is_free else club,
                    "clubId": -1 if is_free else "unresolved",
                    "route": "free_agent" if is_free else "club",
                    "season": label,
                    "debutYear": start,
                    "tier": tier,
                    "potential": None,
                    "notes": row.get("notes") or None,
                    "curated": curated,
                }
            )
    if args.include_eggs:
        candidates += egg_entries()

    added = updated = skipped_known = 0
    unresolved: dict[str, list[str]] = {}
    vetoes = load_vetoes()
    veto_hits: Counter = Counter()
    for c in candidates:
        key = f"{c['legal']}|{c['birthYear']}"
        if c["legal"] in EXCLUDED_NAMES:
            continue
        if key in vetoes and not c["curated"]:
            veto_hits[key] += 1
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
            if cid == "drop":
                continue
            if cid is None:
                # A club that does not exist in the PM98 world: the player goes in
                # as a free agent (the review file can re-route him to a club id).
                # Same FA tier-5 rule as at parse time — a tier-5 row that lands
                # in the FA pool via an unresolvable club is the same dead weight.
                if c["tier"] == 5 and not c["curated"]:
                    fa_t5_dropped += 1
                    continue
                unresolved.setdefault(c["clubName"], []).append(c["legal"])
                c["clubId"], c["clubName"], c["route"] = -1, None, "free_agent"
            else:
                c["clubId"] = cid
                c["clubName"] = by_norm[
                    norm(
                        next(  # canonical DB spelling
                            cl["name"] for cl in db["clubs"] if int(cl["id"]) == cid
                        )
                    )
                ]["name"]
        if not c["nationality"]:
            # Source row has no nation. The game's own omitted-nationality rule is
            # club-based (English club -> ENGLAND, frame-validated); extend it with
            # the club's game_db country. Clubless blanks default ENGLAND + a note.
            cc = club_country.get(int(c["clubId"]), "") if isinstance(c["clubId"], int) else ""
            c["nationality"] = canon_nat(cc, flags) if cc else ""
            if not c["nationality"]:
                c["nationality"] = ENGLAND
                c["notes"] = ((c.get("notes") or "") + " nat unknown (source blank)").strip()
                nat_unknown += 1
        if c["nationality"] != ENGLAND and c["nationality"].upper() not in flags:
            nat_no_flag[c["nationality"]] += 1
        if key in by_key:
            # Overlapping seasons: a talent starts at his ORIGIN club — the club of
            # his EARLIEST club-bearing row (Ronaldinho: Gremio 98-99, never the
            # PSG 01-02 row) — regardless of the order files are passed in. A
            # club-bearing row also upgrades a clubless/free-agent entry (the
            # 99-00 mod lists Rooney clubless at 14; 01-02 names Everton).
            t = by_key[key]
            if c["curated"]:
                # A hand-curated row replaces the bulk entry outright and locks it
                # (the curator's club/debut/tier is the gameplay-visible truth).
                for fld in ("nationality", "pos", "isGK", "clubId", "clubName", "route", "tier"):
                    t[fld] = c[fld]
                t["debutYear"], t["debutSeason"] = c["debutYear"], c["season"]
                t["flagCode"] = flag_for(c["nationality"], flags)
                t["kind"] = kind_of(c["nationality"])
                t["curated"] = True
                if c.get("notes"):
                    t["notes"] = c["notes"]
                updated += 1
            elif t.get("curated"):
                pass  # curation pin wins over any bulk row
            elif c["route"] == "club" and (
                t["route"] != "club" or c["debutYear"] < int(t["debutYear"])
            ):
                for fld in ("nationality", "pos", "isGK", "clubId", "clubName", "route", "tier"):
                    t[fld] = c[fld]
                t["debutYear"], t["debutSeason"] = c["debutYear"], c["season"]
                t["flagCode"] = flag_for(c["nationality"], flags)
                t["kind"] = kind_of(c["nationality"])
                updated += 1
            elif c["route"] == t["route"] and c["debutYear"] < int(t["debutYear"]):
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
            "kind": kind_of(c["nationality"]),
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
            "curated": c["curated"],
        }
        if c.get("notes"):
            entry["notes"] = c["notes"]
        talents.append(entry)
        by_key[key] = entry
        added += 1

    if fa_t5_dropped:
        print(f"\nfree-agent tier-5 bulk rows dropped (size/no-surface rule): {fa_t5_dropped:,}")
    if vetoes:
        print(f"\nvetoed source rows ({VETOES_PATH.name}):")
        for k, reason in vetoes.items():
            n = veto_hits.get(k, 0)
            flag = "" if n else "  ⚠ MATCHED NOTHING (stale veto?)"
            print(f"  {k}: {n} row(s) dropped — {reason}{flag}")

    merges = merge_variants(talents)
    if merges:
        print(f"\ncross-file variant merges ({len(merges)}):")
        for m in merges:
            print(f"  {m}")
    if nat_unknown:
        print(f"nat unknown (blank source, no club country): {nat_unknown} rows -> ENGLAND + note")
    if nat_no_flag:
        print(
            f"nations absent from the 1997 PAISES table (default flag): {dict(nat_no_flag.most_common())}"
        )

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
            "counts": {
                "talents": len(talents),
                "freeAgents": sum(1 for t in talents if t.get("route") == "free_agent"),
                "unresolvedClubs": len(unresolved),
            },
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
