#!/usr/bin/env python3
"""Consolidate the reverse-engineered PM98 asset JSON into ONE game database.

Inputs (all under assets/, derived from Mats's owned game files):
  - squads_exact.json   : ALL 476 clubs + full squads from the EXACT engine
                          parser (tools/extract_squads_exact.py ==
                          MANAGER.EXE FUN_00579c70/FUN_005820f0, XOR-0x61
                          strings, engine drop rule). Replaces the old
                          approximate-cipher squads_english.json/teams_all.json
                          as the squad + club-header source (2026-07-06).
  - teams_laliga.json   : capacity + founding year for the 20 La Liga clubs
                          (EQUIPOS carries no verified capacity field — the
                          u32 the RE labelled capacity ranges 1..1500).
  - divisions_english.json : idx -> division from MANAGER.EXE's own league table
  - country_codes.json  : PAISES.30 country table (code <-> name; FICHA flags)

Output:
  - assets/game_db.json : { meta, leagues[], clubs[] (players nested) }
  - assets/bios.json    : game_db player id -> { name, pages[6], career } —
                          the EQUIPOS tail T4..T9 bio prose pages + T10
                          career-history CSV, VERBATIM (2025 extended-record
                          players; the CSV keeps the source's own dirt).
                          Split out so game_db stays lean; no app consumer
                          yet — the original's display surface (the FICHA
                          info coin) is un-walked and un-RE'd.

Season is 1997-98. English clubs are division-mapped from the game's own
league table (game keeps Hereford in Div3); every club now carries the game's
own PAISES country code (EQUIPOS header byte param_1[5] — exact, replaces the
old best-effort directory fuzzy match). Run from the project root.
"""

from __future__ import annotations

import json
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

# The English nationality whitelist (extract_english.COUNTRIES) uses a few names that
# differ from the game's own country table (DBDAT/PAISES.30, see tools/re/export_flags.py).
# Map each variant onto the PAISES spelling so the FICHA flag code resolves. Real, not
# fabricated: EIRE == Republic of Ireland; ZAIRE was renamed DR Congo in 1997.
FLAG_ALIASES = {
    "EIRE": "REP. OF IRELAND",
    "NORTHERN IRELAND": "NORTH. IRELAND",
    "USA": "U.S.A.",
    "UNITED STATES": "U.S.A.",
    "ITALIA": "ITALY",
    "TRINIDAD": "TRINIDAD T.",
    "DR CONGO": "ZAIRE",
}
ENGLAND_CODE = 30  # the FICHA default flag for the omitted-nationality (English) players

# The 1997 EU-15 + EEA class for the FICHA KIND flag (frame-evidenced NATIONAL for
# HOLLAND 081 / NORWAY 084; post-Bosman "comunitario" rule, extract_english.py).
from extract_english import EU_EEA_1997  # noqa: E402


def load(name: str):
    return json.loads((ASSETS / name).read_text(encoding="utf-8"))


def build_flag_lookup() -> dict[str, int]:
    """nationality string -> BANDERAS flag code, from the game's PAISES.30 table
    (assets/country_codes.json, baked by tools/re/export_flags.py) plus the English
    whitelist aliases. Unknown / absent -> ENGLAND default."""
    by_name = load("country_codes.json")["byName"]  # PAISES spelling -> code
    lut = {k.upper(): int(v) for k, v in by_name.items()}
    for alias, canon in FLAG_ALIASES.items():
        if canon.upper() in lut:
            lut[alias] = lut[canon.upper()]
    return lut


def main() -> None:
    exact = load("squads_exact.json")["clubs"]
    laliga_caps = {t["name"].upper(): t for t in load("teams_laliga.json")["teams"]}
    flag_lut = build_flag_lookup()
    # idx -> division label, decoded from MANAGER.EXE's own league table
    div_by_idx = {int(k): v for k, v in load("divisions_english.json")["divisionByIdx"].items()}
    by_idx = {c["idx"]: c for c in exact}

    clubs: list[dict] = []
    leagues: list[dict] = []
    bios: dict[int, dict] = {}  # game_db player id -> verbatim tail content
    pid = 0

    def emit_player(p: dict, club_id: int, english: bool) -> dict:
        nonlocal pid
        pid += 1
        # Split the verbatim EQUIPOS tail content off into bios.json (keyed by
        # THIS pid, so the join is the id itself — no order replication risk).
        if p.get("bioPages") is not None:
            bios[pid] = {
                "name": p["name"],
                "pages": p["bioPages"],
                "career": p.get("careerCsv") or "",
                "intl": p.get("intlRaw"),
            }
        # The extended (flag==0) records store nationality ONLY for non-English
        # players — omitted == ENGLAND (extract_english rule, FICHA-frame-
        # validated). Hereford's compact record stores none at all; the same
        # omitted-default applies across the English pyramid.
        nat = p.get("nationality") or ("ENGLAND" if english else None)
        return {
            "id": pid,
            "clubId": club_id,
            "name": p["name"],
            "legalName": p.get("legalName") or p["name"],
            "birthYear": p.get("birthYear"),
            "birthDay": p.get("birthDay"),  # engine-defaulted when absent
            "birthMonth": p.get("birthMonth"),
            "age": p.get("age"),  # null = engine randomizes (25..29 at load)
            "pos": p.get("pos"),  # GK/DF/MF/FW demarcación (band byte +0x1c)
            "posFine": p.get("posFine"),  # fine position (POS_WEIGHT scorer-roulette index)
            "isGK": bool(p.get("isGK")),
            "photoId": p.get("photoId"),  # the .DBC player id u16 == J96NNNNN face-bank key
            # SQUAD MANAGEMENT N. column: the byte after the player-id u16 (+0xf8,
            # docs/re/squad_number_re.md). Emitted verbatim; lower-division records
            # often leave the whole squad at the 0x01 pad (not individuated), so
            # consumers must check per-club uniqueness before displaying.
            "squadNo": p.get("squadNo"),
            "nationality": nat,
            "flagCode": flag_lut.get(str(nat or "").upper(), ENGLAND_CODE),  # BANDERAS index
            "kind": ("NATIONAL" if nat in EU_EEA_1997 else "NON-NATIONAL") if nat else None,
            "heightCm": p.get("heightCm"),  # +0xf9; null = engine randomizes 170..179
            "weightKg": p.get("weightKg"),  # +0xfa; null = engine randomizes 75..84
            "birthplace": p.get("birthplace"),  # tail T1 (extended records only)
            "prevClub": p.get("prevClub"),  # tail T2, e.g. "Brondby (91)"
            # Never null: every consumer's `attrs.get(key, default)` chain stays safe.
            "attrs": p.get("attrs") or {},
        }

    def emit_club(c: dict, cid: int, league_id: str | None, country: str) -> dict:
        cap = laliga_caps.get(c["name"].upper(), {})
        return {
            "id": cid,
            "name": c["name"],
            "fullName": c.get("fullName") or c["name"],  # header string 3, exact
            "stadium": c.get("stadium"),  # header string 2, exact
            "manager": None,  # NOT stored in EQUIPOS (block strings = chairman/sponsor/kit)
            "chairman": c.get("chairman"),
            "sponsor": c.get("sponsor"),
            "kitMaker": c.get("kitMaker"),
            "country": country,
            "countryCode": c["countryCode"],  # PAISES.30 code (EQUIPOS header byte, exact)
            "leagueId": league_id,
            "capacity": cap.get("capacity"),
            "foundingYear": cap.get("founded"),
            "players": [emit_player(p, cid, league_id is not None) for p in c.get("players", [])],
        }

    # --- English pyramid (the playable core) ---
    english_idx = set(div_by_idx)
    for lid, lname, label, tier in ENGLISH_LEAGUES:
        club_ids = []
        for idx in sorted(i for i, lab in div_by_idx.items() if lab == label):
            c = by_idx.get(idx)
            if not c:
                continue
            cid = idx  # English idx is a stable, unique club id
            # Pyramid clubs stay country "England" (league grouping; the exact
            # PAISES code is on countryCode — Wrexham/Cardiff/Swansea = WALES).
            clubs.append(emit_club(c, cid, lid, "England"))
            club_ids.append(cid)
        leagues.append(
            {"id": lid, "name": lname, "country": "England", "tier": tier, "clubIds": club_ids}
        )

    # --- International clubs (browseable; leagueId null) ---
    # Country is the game's own PAISES.30 name via the EQUIPOS header code —
    # exact for all 476 (replaces the old fuzzy directory match + '?' recovery).
    next_id = 1000  # keep clear of English idx ids
    for c in exact:
        if c["idx"] in english_idx:
            continue
        clubs.append(emit_club(c, next_id, None, c["country"]))
        next_id += 1

    intl = [c for c in clubs if c["leagueId"] is None]
    db = {
        "meta": {
            "game": "Premier Manager 98 (Dinamic Multimedia / Gremlin Interactive)",
            "season": "1997-98",
            "source": "reverse-engineered from EQUIPOS.PKF (owned game files); personal use. "
            "Squads + club headers via the EXACT engine parser "
            "(tools/extract_squads_exact.py / tools/re/equipos_parse.py == "
            "MANAGER.EXE FUN_00579c70 + FUN_005820f0, XOR-0x61 strings, "
            "engine leaver-drop rule).",
            "note": "English divisions decoded from MANAGER.EXE's own league table "
            "(game keeps Hereford in Div3); country = PAISES.30 name via the "
            "EQUIPOS header country code (exact). Null birthYear/age/height/"
            "weight/birthDay/birthMonth = the engine randomizes or defaults "
            "these at load (FUN_005820f0) — never baked.",
            "counts": {
                "leagues": len(leagues),
                "clubs": len(clubs),
                "englishClubs": sum(1 for c in clubs if c["leagueId"] is not None),
                "internationalClubs": len(intl),
                "players": pid,
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

    # ---- bios.json (kill-tested against the extractor's own witnesses) -----
    assert len(bios) == 2025, len(bios)
    sch = next(
        b for b in bios.values() if b["name"] == "Schmeichel" and "Gladsaxe" in " ".join(b["pages"])
    )
    assert len(sch["pages"]) == 6
    assert sch["career"].strip().splitlines()[0] == "1984,Hvidovre,1,30,0"
    # T3-verbatim INTERNATIONAL witnesses (frames 034 Schmeichel / 050 Hiden)
    assert sch["intl"] == "Denmark", sch["intl"]
    hid = next(b for b in bios.values() if b["name"] == "Hiden")
    assert hid["intl"] == "-", hid["intl"]
    bout = ASSETS / "bios.json"
    bout.write_text(
        json.dumps(
            {
                "note": "EQUIPOS.PKF player tail T4..T9 (six bio prose pages) + T10 "
                "(career-history CSV: season,club,div,apps,goals) + T3 (`intl`, the "
                "DATA BASE card INTERNATIONAL string) VERBATIM, keyed by game_db "
                "player id. Source dirt ('Sin datos.'/'No data.', typo'd separators, "
                "short rows, '-'/'No' intl) is kept as-is, never repaired. Display "
                "surface: the DATA BASE player card (DataBaseCardScreen.gd; "
                "docs/re/dbase_player_card_re.md).",
                "players": {str(k): v for k, v in bios.items()},
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )
    print(f"wrote {bout.relative_to(ROOT)}: {len(bios)} player bios")


if __name__ == "__main__":
    main()
