#!/usr/bin/env python3
"""Consolidate the reverse-engineered PM98 asset JSON into ONE game database.

Inputs (all under assets/, derived from Mats's owned game files):
  - squads_english.json : 92 English-league clubs, 1948 players WITH attrs (the
                          verified, attribute-rich core -> the playable pyramid)
  - teams_all.json      : 476 detailed records (437 with squads), continental clubs
  - teams_laliga.json   : capacity + founding year for the 20 La Liga clubs
  - pcf_team_directory.json : id/name/country for 1352 clubs (best-effort country tag)

Output:
  - assets/game_db.json : { meta, leagues[], clubs[] (players nested) }

Season is 1996-97 (verified: idx 38-57 == the real 96-97 Premier League).
English clubs are idx-ordered into the four divisions; everything else is tagged
country-only (best-effort) under leagueId=null. Run from the project root.
"""

from __future__ import annotations

import json
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"

# English leagues. The division of each club is read from the game's own league
# table in MANAGER.EXE (tools/extract_divisions.py -> divisions_english.json), NOT
# from club enumeration order (which is 96/97 final-standings order) and NOT from
# external tables (the game's Div3 keeps Hereford, not the real-97/98 Macclesfield).
ENGLISH_LEAGUES = [
    ("eng_prem", "Premier League", "PREMIER LEAGUE", 1),
    ("eng_div1", "Division One", "DIVISION ONE", 2),
    ("eng_div2", "Division Two", "DIVISION TWO", 3),
    ("eng_div3", "Division Three", "DIVISION THREE", 4),
]


def load(name: str):
    return json.loads((ASSETS / name).read_text(encoding="utf-8"))


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


def build_country_lookup() -> dict[str, str]:
    """Map normalised club name -> country (Spanish directory country names)."""
    out: dict[str, str] = {}
    for t in load("pcf_team_directory.json")["teams"]:
        key = norm(t["name"])
        if key and key not in out:
            out[key] = t["country"]
        # also index the most significant single token (handles short dir names)
        toks = [w for w in key.split() if len(w) >= 4]
        if toks:
            out.setdefault(toks[0], t["country"])
    return out


def country_for(name: str, lut: dict[str, str]) -> str | None:
    key = norm(name)
    if key in lut:
        return lut[key]
    for tok in (w for w in key.split() if len(w) >= 4):
        if tok in lut:
            return lut[tok]
    return None


def main() -> None:
    english = load("squads_english.json")["clubs"]
    teams_all = load("teams_all.json")["teams"]
    laliga_caps = {t["name"]: t for t in load("teams_laliga.json")["teams"]}
    country_lut = build_country_lookup()
    # idx -> division label, decoded from MANAGER.EXE's own league table
    div_by_idx = {int(k): v for k, v in load("divisions_english.json")["divisionByIdx"].items()}

    english_names = {c["name"] for c in english}
    by_idx = {c["idx"]: c for c in english}

    clubs: list[dict] = []
    leagues: list[dict] = []
    pid = 0

    def emit_player(p: dict, club_id: int) -> dict:
        nonlocal pid
        pid += 1
        return {
            "id": pid,
            "clubId": club_id,
            "name": p["name"],
            "legalName": p.get("legalName", p["name"]),
            "birthYear": p.get("birthYear"),
            "age": p.get("age"),
            "pos": p.get("pos"),  # GK/DF/MF/FW demarcación; null for un-decoded records
            "posFine": p.get("posFine"),  # fine position (POS_WEIGHT scorer-roulette index)
            "isGK": bool(p.get("isGK")),
            "media": p.get("media"),
            "photoId": p.get("photoId"),  # J96NNNNN face-bank key (English squads); faces_re.md
            "nationality": p.get("nationality"),  # EQUIPOS cipher string; ENGLAND default
            "kind": p.get("kind"),  # FICHA NATIONAL / NON-NATIONAL flag (derived from nat)
            "heightCm": p.get("heightCm"),  # EQUIPOS Y+2 byte (cm); FICHA player+0xf9
            "weightKg": p.get("weightKg"),  # EQUIPOS Y+3 byte (kg); FICHA player+0xfa
            # Never null: a sparse record with no decoded attribute row gets {} so every
            # consumer's `attrs.get(key, default)` chain stays safe (a pos-decoded keeper
            # with no attr row is still isGK, and must not crash the commentary/sort paths).
            "attrs": p.get("attrs") or {},
        }

    # --- English pyramid (the playable core) ---
    for lid, lname, label, tier in ENGLISH_LEAGUES:
        club_ids = []
        for idx in sorted(i for i, lab in div_by_idx.items() if lab == label):
            c = by_idx.get(idx)
            if not c:
                continue
            cid = idx  # English idx is a stable, unique club id
            cap = laliga_caps.get(c["name"], {})  # (English clubs won't match; null cap)
            clubs.append(
                {
                    "id": cid,
                    "name": c["name"],
                    "fullName": c.get("fullName", c["name"]),
                    "stadium": c.get("stadium"),
                    "manager": c.get("manager"),
                    "country": "England",
                    "leagueId": lid,
                    "capacity": cap.get("capacity"),
                    "foundingYear": cap.get("founded"),
                    "players": [emit_player(p, cid) for p in c.get("players", [])],
                }
            )
            club_ids.append(cid)
        leagues.append(
            {"id": lid, "name": lname, "country": "England", "tier": tier, "clubIds": club_ids}
        )

    # --- International clubs (browseable; leagueId null, country best-effort) ---
    matched = 0
    next_id = 1000  # keep clear of English idx ids
    for t in teams_all:
        if t["name"] in english_names:
            continue  # English club: already emitted from the verified extractor
        cid = next_id
        next_id += 1
        ctry = country_for(t["name"], country_lut)
        if ctry:
            matched += 1
        cap = laliga_caps.get(t["name"], {})
        clubs.append(
            {
                "id": cid,
                "name": t["name"],
                "fullName": t.get("fullName", t["name"]),
                "stadium": t.get("stadium"),
                "manager": t.get("manager"),
                "country": ctry,
                "leagueId": None,
                "capacity": cap.get("capacity"),
                "foundingYear": cap.get("founded"),
                "players": [emit_player(p, cid) for p in t.get("players", [])],
            }
        )

    intl = [c for c in clubs if c["leagueId"] is None]
    db = {
        "meta": {
            "game": "Premier Manager 98 (Dinamic Multimedia / Gremlin Interactive)",
            "season": "1997-98",
            "source": "reverse-engineered from EQUIPOS.PKF (owned game files); personal use",
            "note": "English divisions decoded from MANAGER.EXE's own league table "
            "(Premier == real 97-98 top flight; game keeps Hereford in Div3); "
            "international clubs country-tagged best-effort.",
            "counts": {
                "leagues": len(leagues),
                "clubs": len(clubs),
                "englishClubs": sum(1 for c in clubs if c["country"] == "England"),
                "internationalClubs": len(intl),
                "players": pid,
                "intlCountryMatchRate": round(matched / max(1, len(intl)), 3),
            },
        },
        "leagues": leagues,
        "clubs": clubs,
    }

    out = ASSETS / "game_db.json"
    out.write_text(json.dumps(db, ensure_ascii=False, indent=1), encoding="utf-8")
    c = db["meta"]["counts"]
    print(f"wrote {out.relative_to(ROOT)}")
    print(
        f"  leagues={c['leagues']} clubs={c['clubs']} "
        f"(english={c['englishClubs']} intl={c['internationalClubs']}) "
        f"players={c['players']}"
    )
    print(f"  intl country-match rate: {c['intlCountryMatchRate']:.0%}")


if __name__ == "__main__":
    main()
