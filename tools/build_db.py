#!/usr/bin/env python3
"""Consolidate the reverse-engineered PM98 asset JSON into ONE game database.

Inputs (all under assets/, derived from Mats's owned game files):
  - squads_exact.json   : ALL 476 clubs + full squads from the EXACT engine
                          parser (tools/extract_squads_exact.py ==
                          MANAGER.EXE FUN_00579c70/FUN_005820f0, XOR-0x61
                          strings, engine drop rule). Replaces the old
                          approximate-cipher squads_english.json/teams_all.json
                          as the squad + club-header source (2026-07-06).
  - teams_laliga.json   : founding year for the 20 La Liga clubs (real capacity
                          now comes from squads_exact param_1[6] for ALL clubs,
                          verified vs these 15 + the witnessed English grounds;
                          the param_1[0x7a] u32 the RE first labelled capacity,
                          range 400..1500, is a DIFFERENT unresolved field).
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
    # The PAISES.30 codes whose nation is EU/EEA-1997 -> FICHA KIND = NATIONAL
    # (comunitario). flag_lut carries the Irish / N.-Irish spelling aliases, so
    # this resolves every home-nation code (frame-validated NATIONAL, 081/084).
    eu_codes = {flag_lut[n] for n in EU_EEA_1997 if n in flag_lut}
    # idx -> division label, decoded from MANAGER.EXE's own league table
    div_by_idx = {int(k): v for k, v in load("divisions_english.json")["divisionByIdx"].items()}
    by_idx = {c["idx"]: c for c in exact}

    clubs: list[dict] = []
    leagues: list[dict] = []
    bios: dict[int, dict] = {}  # game_db player id -> verbatim tail content
    pid = 0

    def emit_player(p: dict, club_id: int) -> dict:
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
        # Nationality is the engine's own per-player country code (EQUIPOS byte
        # +0x1a == PAISES.30 code == BANDERAS flag index), decoded in the
        # extractor for ALL 9547 players (`natCode`/`nationality`). flagCode is
        # that raw code; KIND is its EU/EEA-1997 comunitario class. See
        # tools/extract_squads_exact.py + docs/re/ficha_card_re.md.
        nat = p.get("nationality")
        code = p.get("natCode")
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
            # The five ALTERNATIVE roles the TACTICS ROLE popup paints white beside the
            # gold natural role (engine bytes +0x1e..+0x22); [] = one-role player.
            "posAlts": p.get("posAlts") or [],
            "isGK": bool(p.get("isGK")),
            "photoId": p.get("photoId"),  # the .DBC player id u16 == J96NNNNN face-bank key
            # SQUAD MANAGEMENT N. column: the byte after the player-id u16 (+0xf8,
            # docs/re/squad_number_re.md). Emitted verbatim; lower-division records
            # often leave the whole squad at the 0x01 pad (not individuated), so
            # consumers must check per-club uniqueness before displaying.
            "squadNo": p.get("squadNo"),
            "nationality": nat,
            "flagCode": code,  # engine byte +0x1a == PAISES.30 code == BANDERAS index
            "kind": ("NATIONAL" if code in eu_codes else "NON-NATIONAL")
            if code is not None
            else None,
            "heightCm": p.get("heightCm"),  # +0xf9; null = engine randomizes 170..179
            "weightKg": p.get("weightKg"),  # +0xfa; null = engine randomizes 75..84
            # .DBC +0x16/+0x17 raw (un-RE'd semantics): the match-lineup filler
            # FUN_0044d5f0 copies them to lineup rec+0x2c/+0x30 verbatim —
            # consumed by the real-lineup feeder (docs/re/session_lineup_re.md §3).
            "b16": p.get("b16"),
            "b17": p.get("b17"),
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
            # Real stadium capacity from EQUIPOS param_1[6] (squads_exact "capacity",
            # <10->6000 engine rule applied). Matches teams_laliga's "u32 @year-12" for
            # all 15 Spanish + the witnessed English FT read-outs (Old Trafford 55,300,
            # Villa Park 39,339, The Dell 15,200). foundingYear stays laliga-only (a
            # separate real field, not yet decoded for the other 456 clubs).
            "capacity": c.get("capacity") or cap.get("capacity"),
            "foundingYear": cap.get("founded"),
            "players": [emit_player(p, cid) for p in c.get("players", [])],
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

    # --- WITNESSED Div-3 membership fix (2026-07-19) ---------------------------
    # The EXE's static league table (divisions_english.json) keeps Hereford U. in
    # DIVISION THREE, but the LIVE game fields Macclesfield T. there instead:
    # witnessed on three separate careers (w4 Barnsley lt_third / w7 Barnet
    # w7_lt_third_seed, screenshots/wine-captures-2026-07-19-lowerdiv/) and on the
    # START OF SEASON 3RD DIVISION page (s22 economics run + state_check frame).
    # The static table is the stale 96-97 layout (Hereford went down to the
    # Conference in 96-97; Macclesfield came up). Swap POST-HOC so every club id
    # (English idx / international enumeration) stays exactly as before — only the
    # league assignment moves. club_economy.json already keys Macclesfield's id.
    macc = next(c for c in clubs if c["name"] == "Macclesfield T.")
    here = next(c for c in clubs if c["name"] == "Hereford U.")
    assert here["leagueId"] == "eng_div3" and macc["leagueId"] is None
    macc["leagueId"] = "eng_div3"
    here["leagueId"] = None
    div3 = next(lg for lg in leagues if lg["id"] == "eng_div3")
    div3["clubIds"] = [macc["id"] if i == here["id"] else i for i in div3["clubIds"]]
    assert len(div3["clubIds"]) == 24 and here["id"] not in div3["clubIds"]

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
            "note": "English divisions decoded from MANAGER.EXE's own league table, "
            "with the live-witnessed Div3 fix (the static table's Hereford is the "
            "stale 96-97 layout; the running game fields Macclesfield T. — three "
            "careers witnessed 2026-07-19); country = PAISES.30 name via the "
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
