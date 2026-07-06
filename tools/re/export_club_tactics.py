#!/usr/bin/env python3
"""Export every club's OWN stored tactic + TRUE XI from DBDAT/EQUIPOS.PKF.

Source of truth (MANAGER.EXE, decompiles in docs/re/clubtactics/):
  - The VIEW RIVAL builder `FUN_005733d0` draws the rival's BRIGHT markers from
    `*(screen+0x1928)` = the rival CLUB object, slots at club+0x60 + i*0x20,
    mk1 at +0x10/+0x14, mk2 at +0x18/+0x1c (raw 318x198 design space) — the
    SAME slot layout the ghost pass reads from your own Tactics (param_3+0x60).
  - `screen+0x1928` is fetched at 0x57340c..0x573444: rival club id = the
    fixture's ([0x66afd0]+0x38/+0x3a) side that is not yours, then
    `FUN_00585ee0(registry@0x66c0d0, id)` → per-club lazy handle (0x20 bytes:
    {count=0xff, club_id, 0, 0, club_cache, 0,0,0}) → `FUN_005793d0` →
    `FUN_005792b0(0)`: new(0x2a4) club object (`FUN_00579880` ctor) + load.
  - `FUN_00579b80` opens `sprintf("DBDAT\\equipos\\eq96%04u.dbc", id)`
    (string @0x662158) — served from EQUIPOS.PKF — and `FUN_00579c70` parses
    the record. The parse (header, fmt gates, 11 x 8-u16 slot block, 7 lever
    bytes, tag-2 side records, squad do-while with the slot>=0x62 leaver-drop
    rule) is replicated byte-exactly in tools/re/equipos_parse.py (shared with
    tools/extract_squads_exact.py — the game_db squad source).
  - Player records: `FUN_005820f0` (fmt<600 path — all EQUIPOS fmts are
    0x1f9..0x20b). The u8 SLOT byte -> player+0x19/+0x1b; 1..11 = the club's
    SHIPPED XI slot: the caller writes club+0x297+slot = player+0x1d + 1, and
    the .DBC tactic slot s-1 carries the pitch disc numbered s (rival_015:
    11/11 mk pairs).
  - Marker mapping to the 258x154 layer is (raw*258/318, raw*154/198), same as
    LINE-UP/TACTICS/VIEW RIVAL (rival_screen_re.md).

XI -> game_db id mapping (ORDER-BASED, exact): game_db squads are built from
THIS SAME parser's records in stream order (tools/extract_squads_exact.py ->
tools/build_db.py, 2026-07-06 rebuild), so the club's k-th kept record IS
game_db players[k]. The mapping asserts name + posFine + attrs identity on
every player before trusting the order (any build drift kills the export).
The old approximate-cipher match cascade is gone with the corruption it
compensated for.

KILL-TESTS run on every export (all assert):
  1. All 476 records parse; every slot coord is in the 318x198 design space.
  2. Barcelona (EQ960001, app id 1000): mapped {mk1} / {mk2} sets equal the
     walked rival_015 disc/arrow lists in app/data/rival_chrome_samples.json
     (the frame-baked ground truth from screenshot 015_162415).
  3. Decoded club names match game_db.json names for ALL 476 clubs (same
     decode on both sides since the rebuild).
  4. TRUE XI vs the walked frame 015 rows: Barcelona xiNames ==
     [Hesp, Reiziger, Abelardo, Guardiola, F. Couto, Sergi, Figo,
      Luis Enrique, Anderson, Giovanni, Rivaldo], xiFine ==
     row_truth_015["fine"] == [1,2,5,15,5,3,16,7,9,13,17], and the band bytes
     spell GOAL/DEF/DEF/MID/DEF/DEF/MID/MID/FOR/MID/MID.
  5. Every record's squad parse lands in bounds (heap use <= alloc size at
     +0x24, cursor <= record end — FUN_00579c70's own success check) and
     >= 470 clubs fill all 11 XI slots.
  6. Per-club record<->game_db identity: same squad size, same name, same
     posFine, same 10-attr row for every player (the order-based mapping's
     precondition).
  7. Every slot-complete club maps its XI to game_db ids with NO holes
     (-1 only where the .DBC itself leaves a slot unfilled); Manchester Utd
     (app id 40) matches 11/11.

App id mapping (build_db.py convention): English club app id == PKF directory
position (pos 38 = first English club); international clubs get 1000 + running
count of non-English positions in directory order.

Writes `app/data/club_tactics.json` (committed, source-derived). Reproduce:
    cd tools/re && python3 export_club_tactics.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pkf_unpack as P
from equipos_parse import parse_club_tactic

ROOT = Path(__file__).resolve().parents[2]
PKF = ROOT / "extracted" / "Premier Manager 98" / "DBDAT" / "EQUIPOS.PKF"
GAME_DB = ROOT / "app" / "data" / "game_db.json"
RIVAL_SAMPLES = ROOT / "app" / "data" / "rival_chrome_samples.json"
FORMATIONS = ROOT / "app" / "data" / "formations.json"
OUT = ROOT / "app" / "data" / "club_tactics.json"

ATTR_NAMES = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]

# Walked ground truth: screenshot 015_162415 (VIEW RIVAL, F.C. Barcelona,
# Mon 4 Aug 1997) — the 11 table rows in slot order.
FRAME_015_XI = [
    "Hesp",
    "Reiziger",
    "Abelardo",
    "Guardiola",
    "F. Couto",
    "Sergi",
    "Figo",
    "Luis Enrique",
    "Anderson",
    "Giovanni",
    "Rivaldo",
]
FRAME_015_BANDS = [0, 1, 1, 2, 1, 1, 2, 2, 3, 2, 2]  # GOAL DEF DEF MID ... (POS col)


def stock_match(slots: list[dict], stock: list[dict]) -> str | None:
    """Exact-match the 11 (mk1,mk2) raw pairs against the 10 predef formations."""
    key = sorted(tuple(sl["raw"][4:8]) for sl in slots)
    for f in stock:
        if sorted(tuple(sl["raw"][4:8]) for sl in f["slots"]) == key:
            return f["name"]
    return None


def main() -> None:
    buf = PKF.read_bytes()
    entries = list(P.files_of(buf))
    assert len(entries) == 476, f"expected 476 EQUIPOS entries, got {len(entries)}"

    game_db = json.loads(GAME_DB.read_text())
    english_positions = {c["id"] for c in game_db["clubs"] if c["id"] < 1000}
    db_clubs = {c["id"]: c for c in game_db["clubs"]}
    stock = json.loads(FORMATIONS.read_text())["formations"]

    clubs: dict[str, dict] = {}
    name_hits = 0
    xi_slots_full = 0
    xi_matched_full = 0
    fine_checked = 0
    next_intl = 1000
    for pos, (fname, off, size) in enumerate(entries):
        dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
        rec = parse_club_tactic(buf[off : off + size], dbc_id)
        # Kill-test 1 + 5: design-space bounds and squad-parse bounds.
        for sl in rec["slots"]:
            for x, y in (sl["raw"][4:6], sl["raw"][6:8]):
                assert 0 <= x <= 318 and 0 <= y <= 198, (
                    f"{fname}: slot coord ({x},{y}) outside 318x198 design space"
                )
        assert rec["inBounds"], f"{fname}: squad parse out of bounds"
        if pos in english_positions:
            app_id = pos
        else:
            app_id = next_intl
            next_intl += 1
        db_players = db_clubs.get(app_id, {}).get("players", [])
        # Kill-test 3: same decode on both sides -> names must agree exactly.
        assert db_clubs.get(app_id, {}).get("name", "").upper() == rec["name"].upper(), (
            f"{fname}: name {rec['name']!r} != game_db {db_clubs.get(app_id, {}).get('name')!r}"
        )
        name_hits += 1
        # Kill-test 6: record<->game_db identity (order-based mapping guard).
        assert len(db_players) == len(rec["players"]), (
            f"{fname}: {len(rec['players'])} records vs {len(db_players)} game_db players"
        )
        for p, q in zip(rec["players"], db_players):
            assert q["name"] == p["name"], (fname, p["name"], q["name"])
            assert q["posFine"] == p["fine"], (fname, p["name"], q["posFine"], p["fine"])
            assert [q["attrs"][k] for k in ATTR_NAMES] == p["attrs"], (fname, p["name"])
            fine_checked += 1

        # slot s (1..11) -> the LAST record carrying it (engine: last writer
        # wins on club+0x297+slot) -> game_db players[k] by stream order.
        slot_idx: dict[int, int] = {}
        for k, p in enumerate(rec["players"]):
            if 1 <= p["slot"] <= 11:
                slot_idx[p["slot"]] = k
        if len(slot_idx) == 11:
            xi_slots_full += 1
        xi = [int(db_players[slot_idx[s]]["id"]) if s in slot_idx else -1 for s in range(1, 12)]
        if -1 not in xi:
            xi_matched_full += 1
        clubs[str(app_id)] = {
            "dbcId": dbc_id,
            "name": rec["name"],
            "slots": rec["slots"],
            "levers": rec["levers"],
            # stadium pitch dims (.DBC header u16 pair +0x36/+0x34, engine
            # substitute rule applied: +0x34<0x1e->0x3c, +0x36<0x34->0x69).
            # VENUE club's pair <<16 = session+0x4c/+0x50 = the match pitch
            # scale (docs/re/session_lineup_re.md §4). raw = [+0x34, +0x36].
            "pitch": {"w": rec["pitchW"], "h": rec["pitchH"], "raw": rec["pitchRaw"]},
            "stockFormation": stock_match(rec["slots"], stock),
            "xi": xi,
            "xiNames": [
                rec["players"][slot_idx[s]]["name"] if s in slot_idx else "" for s in range(1, 12)
            ],
            "xiFine": [
                rec["players"][slot_idx[s]]["fine"] if s in slot_idx else 0 for s in range(1, 12)
            ],
        }

    # Kill-test 2: Barcelona vs the walked rival_015 frame bake.
    barca = clubs["1000"]
    assert barca["name"] == "F.C. Barcelona", barca["name"]
    samples = json.loads(RIVAL_SAMPLES.read_text())
    walked = samples["rival_markers_015"]
    discs = sorted(tuple(m["mk"]) for m in walked if m["kind"] == "disc")
    arrows = sorted(tuple(m["mk"]) for m in walked if m["kind"] == "arrow")
    got1 = sorted(tuple(sl["mk1"]) for sl in barca["slots"])
    got2 = sorted(tuple(sl["mk2"]) for sl in barca["slots"])
    assert got1 == discs, f"Barcelona mk1 != walked discs:\n{got1}\n{discs}"
    assert got2 == arrows, f"Barcelona mk2 != walked arrows:\n{got2}\n{arrows}"
    # ... and slot index i carries the disc/arrow numbered i+1 (11/11 walked).
    by_num_d = {m["num"]: m["mk"] for m in walked if m["kind"] == "disc"}
    by_num_a = {m["num"]: m["mk"] for m in walked if m["kind"] == "arrow"}
    for i, sl in enumerate(barca["slots"]):
        assert sl["mk1"] == by_num_d[i + 1] and sl["mk2"] == by_num_a[i + 1], (
            f"Barcelona slot {i} != walked marker {i + 1}"
        )

    # Kill-test 3 (coverage): every club's name agreed.
    assert name_hits == 476, f"only {name_hits}/476 names match game_db.json"

    # Kill-test 4: Barcelona TRUE XI == the walked frame 015 rows.
    assert barca["xiNames"] == FRAME_015_XI, barca["xiNames"]
    row_truth = samples["row_truth_015"]
    assert barca["xiFine"] == row_truth["fine"], (barca["xiFine"], row_truth["fine"])
    barca_db = {p["id"]: p for p in db_clubs[1000]["players"]}
    band_of = {0: "GOAL", 1: "DEF", 2: "MID", 3: "FOR"}
    got_pos = [
        {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}[barca_db[i]["pos"]]
        for i in barca["xi"]
    ]
    assert got_pos == row_truth["pos"] == [band_of[b] for b in FRAME_015_BANDS], got_pos

    # Kill-test 8: pitch dims. Range floors = the engine substitute rule
    # (post-rule w >= 0x64 observed / h >= 0x3c); witnesses pinned empirically
    # 2026-07-07 on the shipped EQUIPOS.PKF — Man Utd 116x76 (= Old Trafford's
    # real 116x76yd pitch), Barcelona 107x72.
    for c in clubs.values():
        assert 0x64 <= c["pitch"]["w"] <= 0x75 and 0x3C <= c["pitch"]["h"] <= 0x58, (
            c["name"],
            c["pitch"],
        )
    assert clubs["40"]["pitch"]["w"] == 116 and clubs["40"]["pitch"]["h"] == 76
    assert clubs["1000"]["pitch"]["w"] == 107 and clubs["1000"]["pitch"]["h"] == 72

    # Kill-test 5 (floor) + 7: coverage; order-mapping leaves NO game_db holes.
    assert xi_slots_full >= 470, f"only {xi_slots_full}/476 clubs fill all 11 slots"
    assert xi_matched_full == xi_slots_full, (
        f"{xi_matched_full} fully-matched != {xi_slots_full} slot-complete"
    )
    assert -1 not in clubs["40"]["xi"], f"Manchester Utd xi has holes: {clubs['40']['xi']}"

    n_stock = sum(1 for c in clubs.values() if c["stockFormation"])
    out = {
        "_source": (
            "EQUIPOS.PKF per-club .DBC records via tools/re/export_club_tactics.py "
            "(parse = MANAGER.EXE FUN_00579c70 + squad loop FUN_005820f0, shared "
            "module tools/re/equipos_parse.py; draw chain FUN_005733d0/"
            "FUN_005793d0; docs/re/clubtactics/)"
        ),
        "_design_space": {"w": 318, "h": 198},
        "_marker_layer": {"w": 258, "h": 154},
        "_levers_note": (
            "7 bytes at club+0x1d9..+0x1df read right after the slot block; "
            "per-byte meaning un-RE'd (EXACT_PORT_PLAN gap B) — stored raw."
        ),
        "_xi_note": (
            "xi = game_db player id per SHIPPED XI slot 1..11 (player+0x1b in the "
            ".DBC squad records; slot s stands at tactic slot s-1), -1 only where "
            "the .DBC leaves the slot unfilled. Mapping is ORDER-BASED (game_db "
            "squads are this parser's records in stream order since the 2026-07-06 "
            "exact rebuild) with per-player name/posFine/attrs identity asserts. "
            "xiNames/xiFine = the record name + raw fine byte "
            "(== club+0x297+slot array == game_db posFine)."
        ),
        "clubs": clubs,
    }
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(
        f"wrote {OUT.relative_to(ROOT)}: {len(clubs)} clubs, "
        f"{name_hits}/476 names matched, {n_stock} on stock formations, "
        f"XI: {xi_slots_full}/476 slot-complete, {xi_matched_full}/476 fully "
        f"game_db-matched ({fine_checked} identity checks), "
        f"Barcelona == walked rival_015 + frame-015 XI ✔"
    )


if __name__ == "__main__":
    main()
