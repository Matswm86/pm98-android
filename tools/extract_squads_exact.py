#!/usr/bin/env python3
"""Extract ALL 476 club squads from EQUIPOS.PKF with the EXACT engine parser.

Replaces the approximate-cipher heuristics (extract_squads.py Copyright-scan +
extract_english.py anchor hunt) as the game_db squad source. The parse is the
byte-exact replica of MANAGER.EXE's own loaders (tools/re/equipos_parse.py:
FUN_00579c70 club record + FUN_005820f0 player record, XOR-0x61 strings via
FUN_0058c810 — decompiles in docs/re/clubtactics/, RE in
docs/re/club_tactics_re.md). What the old cipher corrupted (accents, case,
German/Portuguese names, sparse English framing) is now decoded exactly, and
the engine's own drop rule (slot byte >= 0x62 = discarded leaver) is applied.

Field identities (pinned empirically this pass, 2026-07-06, not guessed):
  - header string 2 == STADIUM (443/476 == old game_db stadium, rest = the
    clubs the old cipher mangled); header string 3 == FULL CLUB NAME
    ("Manchester United F. C.", "Fútbol Club Barcelona").
  - header byte (param_1[5]) == the PAISES.30 COUNTRY CODE: all 476 resolve
    in assets/country_codes.json; the 92 English-league records are 89x
    ENGLAND(30) + Wrexham/Cardiff/Swansea = WALES; Barcelona=SPAIN(22),
    Bayern=GERMANY(2), Celtic=SCOTLAND(19), Boca=ARGENTINA(3).
  - flag==0 block strings (94 extended records) = [chairman, sponsor, kit
    maker] ("C M Edwards", "SHARP", "UMBRO" for Man Utd) — NO manager field
    exists in EQUIPOS. The u32 the RE labelled "stadium capacity"
    (param_1[0x7a]) ranges 1..1500 (Man Utd 1500) — NOT a plausible seat
    count; kept raw as `blockU32`, semantics unresolved, never consumed.
  - NATIONALITY (2026-07-14): the engine's OWN per-player country code, player
    record byte +0x1a ('b1a'), decoded through PAISES.30 — the SAME byte
    MANAGER.EXE FUN_004f5260 reads (*(player+0x1a)) and passes to FUN_0058d270
    (bounds-checked at() over the flag DIBs) to draw the nationality flag.
    Present + in valid range (1..120, zero out-of-range) for ALL 9547 players,
    so nationality/kind/flagCode now resolve for EVERY player. Replaces the old
    bio-prose T3..T1 country scan, which only reached the 94 extended-record
    clubs and mis-defaulted the other 382 (7505 players) to null/ENGLAND. Frame-
    verified: Van der Gouw 27 HOLLAND (081), Solskjaer 44 NORWAY (084),
    Schmeichel 18 DENMARK (ref); corrects the scan's false ENGLANDs (Yorke
    TRINIDAD, Hasselbaink SURINAM, Filan AUSTRALIA; Barnes = ENGLAND, the game's
    nationality, not birthplace JAMAICA). Emitted as `natCode` (the raw +0x1a) +
    `nationality` (PAISES name). KIND = the EU/EEA-1997 comunitario class of that
    code. bios below are separate, unchanged.
  - player tail (flag==0 records): T1 birthplace ("Gladsaxe"), T2 previous club
    ("Brondby (91)"), T3 the DATA BASE INTERNATIONAL string ("Denmark"; kept
    VERBATIM as `intlRaw`, distinct from nationality above), T4..T9 six bio prose
    pages, T10 career-history CSV (season,club,div,apps,goals) — all exported
    VERBATIM since 2026-07-06 (`bioPages`/`careerCsv`; build_db.py splits them
    into assets/bios.json keyed by game_db player id). The CSV keeps the source's
    own dirt ('Sin datos.'/'No data.' sentinels, typo'd separators, short rows) —
    never repaired.
  - fullName packs "Legal Name, NICKNAME" with a real comma (cipher 0x4d ^
    0x61 == 0x2c): "Luis Filipe Madeira Caeiro, FIGO" — same legal/common
    split the old SEP marker encoded.
  - engine load-time randomize rules (FUN_005820f0) are exported as null,
    never baked: birthYear null when outside 1901..1985 (engine: current
    year - 25 - rand(0..4)); heightCm null when byte < 150 (engine: 170 +
    rand(0..9)); weightKg null when byte < 20 (engine: 75 + rand(0..9));
    birthDay/birthMonth null when 0 (engine: current date).

Output: assets/squads_exact.json — consumed by tools/build_db.py.
Reproduce: python3 tools/extract_squads_exact.py  (from the project root)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools" / "re"))
sys.path.insert(0, str(ROOT / "tools"))

import pkf_unpack as P  # noqa: E402
from equipos_parse import ATTR_NAMES, parse_club_tactic  # noqa: E402
from extract_english import EU_EEA_1997  # noqa: E402

GAME = ROOT / "extracted" / "Premier Manager 98"
OUT = ROOT / "assets" / "squads_exact.json"

# PAISES.30 spells two home nations differently from the EU_EEA_1997 (English
# whitelist) set. Map the PAISES spelling onto the set entry so the comunitario
# (KIND) rule resolves for Irish / Northern-Irish players.
EU_EEA_PAISES = {"NORTH. IRELAND": "NORTHERN IRELAND", "REP. OF IRELAND": "EIRE"}


def eu_eea_codes(code2name: dict[int, str]) -> set[int]:
    """The PAISES.30 country codes whose nation is EU/EEA-1997 (the FICHA KIND =
    NATIONAL class; frame-validated NATIONAL for HOLLAND 081 / NORWAY 084)."""
    out: set[int] = set()
    for code, name in code2name.items():
        if EU_EEA_PAISES.get(name, name) in EU_EEA_1997:
            out.add(code)
    return out


def split_legal(full: str, short: str) -> tuple[str, str]:
    """fullName packs 'Legal Name, NICKNAME' (comma == cipher 0x4d, the old
    SEP): legal = the part before the comma; display stays the short name."""
    if "," in full:
        legal = full.partition(",")[0].strip()
    else:
        legal = full.strip()
    return legal or short, short


def export_player(p: dict, code2name: dict[int, str], eu_codes: set[int]) -> dict:
    year = p["year"]
    ok_year = 0x76D <= year <= 0x7C1  # engine randomizes outside 1901..1985
    legal, _ = split_legal(p["fullName"], p["name"])
    # Nationality is the engine's OWN per-player country code: player record byte
    # +0x1a (parse_player 'b1a'), decoded through PAISES.30. This is the SAME byte
    # the engine feeds to the flag-bank accessor to draw the nationality flag —
    # MANAGER.EXE FUN_004f5260 reads *(player+0x1a) and passes it to FUN_0058d270
    # (a bounds-checked vector::at over the flag DIBs). Present and in-range
    # (1..120) for ALL 9547 players, so every player resolves. Replaces the old
    # bio-prose T3..T1 country scan, which only covered the 94 extended-record
    # clubs (compact records had no tail -> null) and mis-defaulted the rest to
    # ENGLAND. Verified vs the walked FICHAs (Van der Gouw 27 HOLLAND / frame 081,
    # Solskjaer 44 NORWAY / frame 084, Schmeichel 18 DENMARK / ref), and it
    # corrects the scan's false ENGLANDs (Yorke TRINIDAD, Hasselbaink SURINAM,
    # Filan AUSTRALIA; Barnes = ENGLAND, the game's nationality, not birthplace
    # JAMAICA). natCode == +0x1a is the BANDERAS flag index (build_db flagCode).
    code = p["b1a"]
    nat = code2name.get(code)
    return {
        "name": p["name"],
        "legalName": legal,
        "birthYear": year if ok_year else None,
        "birthDay": p["day"] or None,  # engine-defaulted when 0
        "birthMonth": p["month"] or None,
        "age": (1998 - year) if ok_year else None,
        "pos": {0: "GK", 1: "DF", 2: "MF", 3: "FW"}.get(p["band"]),
        "posFine": p["fine"],
        "isGK": p["band"] == 0,
        "photoId": p["id"] if p["id"] != 0 else None,  # 0 = engine assigns
        "squadNo": p["squadNo"],
        "nationality": nat,
        "natCode": code,  # engine byte +0x1a == PAISES.30 code == BANDERAS flag index
        "kind": "NATIONAL" if code in eu_codes else "NON-NATIONAL",
        "heightCm": p["heightRaw"] if p["heightRaw"] >= 0x96 else None,
        "weightKg": p["weightRaw"] if p["weightRaw"] >= 0x14 else None,
        # .DBC bytes +0x16/+0x17 (loader FUN_005820f0 stream bytes after the
        # fine array + +0x1a), semantics un-RE'd. The career→match lineup
        # filler FUN_0044d5f0 copies them VERBATIM to lineup rec+0x2c/+0x30
        # (engine player build then reads value−1) — exported raw for the
        # real-lineup feeder (docs/re/session_lineup_re.md §3).
        "b16": p["b16"],
        "b17": p["b17"],
        "birthplace": (p["tail"][0].strip() or None) if p["tail"] else None,
        "prevClub": (p["tail"][1].strip() or None) if p["tail"] else None,
        # T3 VERBATIM — the DATA BASE card INTERNATIONAL box renders this string
        # as-is ("Denmark"/"USA" when capped, the source's own "-"/"No" dirt when
        # not; frames 034/050/055/065/068). Distinct from `nationality`, which
        # runs the last-known-country T3..T1 rule above. build_db.py routes it
        # into bios.json as `intl`.
        "intlRaw": p["tail"][2] if p["tail"] and len(p["tail"]) > 2 else None,
        # T4..T9 / T10 VERBATIM (build_db.py splits them off into bios.json).
        # The career CSV carries the source's own dirt — 'Sin datos.'/'No data.'
        # sentinels, typo'd separators, short rows — kept as-is, never repaired;
        # the engine's own renderer for it is un-RE'd (no walked frame shows it).
        "bioPages": p["tail"][3:9] if p["tail"] else None,
        "careerCsv": p["tail"][9] if p["tail"] else None,
        "attrs": dict(zip(ATTR_NAMES, p["attrs"])),
    }


def main() -> None:
    buf = (GAME / "DBDAT" / "EQUIPOS.PKF").read_bytes()
    entries = list(P.files_of(buf))
    assert len(entries) == 476, f"expected 476 EQUIPOS entries, got {len(entries)}"
    code2name = {
        int(k): v
        for k, v in json.loads((ROOT / "assets" / "country_codes.json").read_text())[
            "byCode"
        ].items()
    }
    eu_codes = eu_eea_codes(code2name)

    clubs = []
    for pos, (fname, off, size) in enumerate(entries):
        dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
        r = parse_club_tactic(buf[off : off + size], dbc_id, collect=True)
        assert r["inBounds"], f"{fname}: parse out of bounds"
        assert r["hdrByte"] in code2name, f"{fname}: country code {r['hdrByte']} not in PAISES"
        clubs.append(
            {
                "idx": pos,
                "dbcId": dbc_id,
                "name": r["name"],
                "stadium": r["hdr2"],
                "fullName": r["hdr3"],
                "countryCode": r["hdrByte"],
                "country": code2name[r["hdrByte"]],
                "chairman": r["blockStrings"][0] if r["blockStrings"] else None,
                "sponsor": r["blockStrings"][1] if len(r["blockStrings"]) > 1 else None,
                "kitMaker": r["blockStrings"][2] if len(r["blockStrings"]) > 2 else None,
                "blockU32": r["capacity"],  # param_1[0x7a]; semantics UNRESOLVED
                "players": [export_player(p, code2name, eu_codes) for p in r["players"]],
                "dropped": [p["name"] for p in r["dropped"]],  # slot>=0x62 leavers
            }
        )

    # ---- KILL-TESTS (all assert; source truths cited in the docstring) -----
    by_name = {c["name"]: c for c in clubs}

    # 1. Barcelona: the engine's 23-man squad; the 3 leavers dropped.
    barca = by_name["F.C. Barcelona"]
    assert len(barca["players"]) == 23, len(barca["players"])
    assert barca["dropped"] == ["Dugarry", "Amunike", "Stoitchkov"], barca["dropped"]
    assert barca["countryCode"] == 22 and barca["country"] == "SPAIN"

    # 2. Man Utd: Schmeichel PO=91 + DENMARK + Gladsaxe/Brondby, Beckham's
    #    attr row (extract_english's own frame-validated witness values),
    #    Van der Gouw HOLLAND (frame 081), Solskjaer NORWAY (frame 084).
    mu = by_name["Manchester Utd."]
    assert mu["stadium"] == "Old Trafford" and mu["countryCode"] == 30
    assert mu["chairman"] == "C M Edwards" and mu["kitMaker"] == "UMBRO"
    pk = {p["name"]: p for p in mu["players"]}
    assert pk["Schmeichel"]["attrs"]["PO"] == 91
    assert pk["Schmeichel"]["nationality"] == "DENMARK"
    assert pk["Schmeichel"]["birthplace"] == "Gladsaxe"
    assert pk["Schmeichel"]["prevClub"] == "Brondby (91)"
    assert list(pk["Beckham"]["attrs"].values()) == [90, 85, 85, 90, 86, 95, 90, 88, 72, 11]
    # Nationality now off the engine's +0x1a byte (natCode == PAISES.30 code ==
    # BANDERAS flag index). Frame-validated FICHAs preserved:
    assert pk["Van der Gouw"]["nationality"] == "HOLLAND"  # code 27, frame 081
    assert pk["Van der Gouw"]["natCode"] == 27
    assert pk["Solskjaer"]["nationality"] == "NORWAY"  # code 44, frame 084
    assert pk["Solskjaer"]["natCode"] == 44
    assert pk["Solskjaer"]["kind"] == "NATIONAL"  # EU/EEA-1997 rule, frame 084
    assert pk["Schmeichel"]["natCode"] == 18  # DENMARK, player_info_ref.jpg

    # 2c. The +0x1a byte CORRECTS the old bio-prose scan (which false-defaulted
    #     these to ENGLAND / grabbed birthplace) — real footballing nationality:
    assert pk["Keane"]["nationality"] == "REP. OF IRELAND" and pk["Keane"]["kind"] == "NATIONAL"
    yorke = {p["name"]: p for p in by_name["Aston Villa"]["players"]}["Yorke"]
    assert yorke["nationality"] == "TRINIDAD T." and yorke["kind"] == "NON-NATIONAL", yorke
    kinky = {p["name"]: p for p in by_name["Manchester C"]["players"]}["Kinkladze"]
    assert kinky["nationality"] == "GEORGIA" and kinky["natCode"] == 62, kinky

    # 2d. The 7505 compact-record (foreign / reserve) players now resolve too —
    #     e.g. Barcelona's Dutch keeper Hesp (the 2026-07-14 <NULL>/ENGLAND bug):
    hesp = {p["name"]: p for p in barca["players"]}["Hesp"]
    assert hesp["nationality"] == "HOLLAND" and hesp["natCode"] == 27, hesp
    assert all(p["nationality"] and p["natCode"] for c in clubs for p in c["players"]), "null nat"

    # 2b. Bio tail export (verbatim T4..T9 + T10; witnesses read straight off
    #     Schmeichel's decoded record this pass — profile page opener, honours
    #     page marker, first + last career-CSV rows).
    sch = pk["Schmeichel"]
    assert len(sch["bioPages"]) == 6
    assert sch["bioPages"][0].startswith("* Peter Schmeichel currently enjoys")
    assert 'Chosen as "Goalkeeper of the Year" 1992' in sch["bioPages"][2]
    lines = sch["careerCsv"].strip().splitlines()
    assert lines[0] == "1984,Hvidovre,1,30,0" and lines[-1] == "96-97,Manchester U,P,36,0"

    # 3. The 3 players the old cipher lost from English squads
    #    (club_tactics_re.md corruption finding). NB the game writes the
    #    apostrophe as the acute-accent glyph: 'O´Connor' (cipher 0xd5).
    for club_name, want in (
        ("Birmingham C", "Connor"),
        ("Tranmere Rov", "Jones"),
        ("Scunthorpe U.", "Marshall"),
    ):
        club = by_name[club_name]
        assert any(want.upper() in p["name"].upper() for p in club["players"]), (
            f"{want} still missing from {club_name}"
        )

    # 4. The German-squad names the old cipher corrupted, now exact.
    german = [c for c in clubs if c["country"] == "GERMANY"]
    for want in ("Sammer", "Effenberg", "Brehme"):
        assert any(p["name"] == want for c in german for p in c["players"]), want

    # 5. Real Madrid's Raúl, whose record read 'FEARAÚLUARAÚL GONZÁL' before.
    rm = by_name["Real Madrid C.F."]
    assert any(
        p["name"] == "Raúl" and p["legalName"] == "RAÚL González Blanco" for p in rm["players"]
    ), [p["name"] for p in rm["players"]]

    # 6. Welsh clubs in the English pyramid carry the WALES code.
    for nm in ("Wrexham", "Cardiff C.", "Swansea City"):
        assert by_name[nm]["country"] == "WALES", nm

    # 7. Regression totals (observed on the shipped EQUIPOS.PKF).
    tot = sum(len(c["players"]) for c in clubs)
    ndrop = sum(len(c["dropped"]) for c in clubs)
    assert tot == 9547, tot
    assert ndrop == 189, ndrop
    # every extended-record (flag==0 club) player carries all 6 pages + CSV
    nbio = sum(1 for c in clubs for p in c["players"] if p["bioPages"] is not None)
    assert nbio == 2025, nbio
    for c in clubs:
        for p in c["players"]:
            assert all(0 <= v <= 99 for v in p["attrs"].values()), (c["name"], p["name"])
            # posFine contract: a valid POS_WEIGHT roulette index (positions_re.md).
            # The 0x63 'none stored' sentinel never occurs on a kept record.
            assert 1 <= p["posFine"] <= 18, (c["name"], p["name"], p["posFine"])

    OUT.write_text(
        json.dumps(
            {
                "note": "All 476 club squads from EQUIPOS.PKF via the EXACT engine "
                "parser (tools/re/equipos_parse.py == MANAGER.EXE FUN_00579c70/"
                "FUN_005820f0, XOR-0x61 strings). Engine drop rule applied "
                "(slot>=0x62 leavers in `dropped`). Randomize-at-load fields are "
                "null, never baked. See the module docstring for pinned field "
                "identities and kill-tests.",
                "clubs": clubs,
            },
            indent=1,
            ensure_ascii=False,
        )
    )
    n_nat = sum(1 for c in clubs for p in c["players"] if p["nationality"] != "ENGLAND")
    ndistinct = len({p["natCode"] for c in clubs for p in c["players"]})
    print(
        f"wrote {OUT.relative_to(ROOT)}: {len(clubs)} clubs, {tot} players "
        f"({ndrop} engine-dropped leavers); nationality from +0x1a for ALL "
        f"({n_nat} non-English across {ndistinct} countries) — all kill-tests passed"
    )


if __name__ == "__main__":
    main()
