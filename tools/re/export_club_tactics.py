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
    the record. Parse order (this file replicates it EXACTLY, incl. the
    fmt-word gates at 0x1f9/0x1fe/0x203/0x207):
      +0x24 u16 alloc-size, +0x26 u16 fmt, +0x28 u8 (unread), +0x29 u8 flag,
      strings ([u16 len][bytes XOR 0x61], `FUN_0058c810` — its `this` is the
      CURSOR pointer: reads len+2 off the main stream, decodes into the club's
      string heap, returns len+1 = heap bytes consumed), budget/stand words
      with clamps, an optional flag==0 block with fmt-gated tail skip
      (0x51/0x73/0x7b), then:
        tactic name  = strncpy(club+0x1c0, club_name, 0x18)   (`FUN_0057a3e0`)
        11 x 8 u16   -> club slots +0x60 + i*0x20              (`FUN_0058c130`,
                        each u16 widened to u32; fields [4],[5]=mk1, [6],[7]=mk2
                        — same field order as the stock table DAT_00660240)
        7 x u8       -> club+0x1d9..+0x1df   (TEAM TACTICS levers; per-byte
                        semantics un-RE'd — EXACT_PORT_PLAN gap B)
      then the SQUAD section (this file's TRUE-XI extension):
        1 tag byte; while tag == 2 -> `FUN_00579170` side-record
        (u16 + XOR string + flag==0-gated skips: 7 len-prefixed, 1 byte
        [== 3 -> 1 more len-prefixed], 1 len-prefixed);
        then an unconditional do-while of player records (`FUN_005820f0`,
        fmt<600 path — all EQUIPOS fmts are 0x1f9..0x20b):
          u16 player id      (== game_db photoId where extract_english found
                              one; the J96 face-bank key, export_faces.py)
          u8                 -> player+0xf8
          XOR string         short name  (player+0x4 heap ptr)
          XOR string         full name   (player+0x8 heap ptr)
          u8 SLOT            -> player+0x19 AND +0x1b; VALID iff < 0x62.
                              1..11 = the club's SHIPPED XI slot: the caller
                              writes club+0x297+slot = player+0x1d + 1, and the
                              .DBC tactic slot s-1 carries the pitch disc
                              numbered s (rival_015: 11/11 mk pairs).
          u8                 unread
          6 x u8             -> +0x1d.. decoded (0 -> 0x62, else raw-1);
                              +0x1d == game_db posFine - 1 (the POS_WEIGHT
                              scorer-roulette index, positions_re.md)
          u8 x3              -> +0x1a, +0x16, +0x17
          u8 BAND            -> +0x1c: 0 GK / 1 DF / 2 MF / 3 FW
          u8 day, u8 month, u16 year   (engine defaults/randomizes when 0 or
                                        outside 1901..1985 — FUN_0058df90)
          u8 -> +0xf9, u8 -> +0xfa     (media pair, extract_squads Y+2/Y+3)
          flag==0 only (the 94 extended/English records): 1 byte + 1
            len-prefixed + (club==0x26ae ? XOR string : 1 len-prefixed) + 8
            len-prefixed  (career/birthplace/bio tail, skipped unread)
          10 x u8 attrs      VE RE AG CA RM RG PA TI EN PO
        after each record 1 tag byte: 0 = end of squad, else next record.
        INVALID records (slot >= 0x62) are re-parsed into the same object and
        their heap strings rolled back — the engine DROPS them from the squad
        (Barcelona ships 26 records but fields a 23-man squad: Dugarry,
        Amunike, Stoitchkov are slot>=0x62 leavers).
  - Marker mapping to the 258x154 layer is (raw*258/318, raw*154/198), same as
    LINE-UP/TACTICS/VIEW RIVAL (rival_screen_re.md).

XI -> game_db id matching (game_db squads came from the APPROXIMATE-cipher
heuristic extractors; the real cipher is XOR 0x61, so names can differ):
  photoId == .DBC player id  ->  unique normalized name (+year tiebreak)  ->
  (birthYear, 10-attr tuple)  ->  attr tuple alone  ->  full/legal-name
  containment + year. Each game_db player claimable by ONE slot. Slots whose
  player is absent/corrupted in game_db stay -1 (166 clubs, mostly the German/
  Portuguese squads the old cipher mangled — a game_db rebuild lever).

KILL-TESTS run on every export (all assert):
  1. All 476 records parse; every slot coord is in the 318x198 design space.
  2. Barcelona (EQ960001, app id 1000): mapped {mk1} / {mk2} sets equal the
     walked rival_015 disc/arrow lists in app/data/rival_chrome_samples.json
     (the frame-baked ground truth from screenshot 015_162415).
  3. Decoded club names match game_db.json names (case-insensitive) for >= 460
     of 476 clubs (the known '?'-recovered records account for the slack).
  4. TRUE XI vs the walked frame 015 rows: Barcelona xiNames ==
     [Hesp, Reiziger, Abelardo, Guardiola, F. Couto, Sergi, Figo,
      Luis Enrique, Anderson, Giovanni, Rivaldo], xiFine ==
     row_truth_015["fine"] == [1,2,5,15,5,3,16,7,9,13,17], and the band bytes
     spell GOAL/DEF/DEF/MID/DEF/DEF/MID/MID/FOR/MID/MID.
  5. Every record's squad parse lands in bounds (heap use <= alloc size at
     +0x24, cursor <= record end — FUN_00579c70's own success check) and
     >= 470 clubs fill all 11 XI slots.
  6. Cross-extractor invariant: every matched XI player's game_db posFine ==
     the raw .DBC fine byte (posFine None allowed).
  7. >= 300 clubs fully matched to game_db ids; Manchester Utd (app id 40,
     all-photoId club) matches 11/11.

App id mapping (build_db.py convention, spot-verified): English club app id ==
PKF directory position (pos 38 = first English club); international clubs get
1000 + running count of non-English positions in directory order.

Writes `app/data/club_tactics.json` (committed, source-derived). Reproduce:
    cd tools/re && python3 export_club_tactics.py
"""

from __future__ import annotations

import json
import re
import struct
import sys
import unicodedata
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pkf_unpack as P

ROOT = Path(__file__).resolve().parents[2]
PKF = ROOT / "extracted" / "Premier Manager 98" / "DBDAT" / "EQUIPOS.PKF"
GAME_DB = ROOT / "app" / "data" / "game_db.json"
RIVAL_SAMPLES = ROOT / "app" / "data" / "rival_chrome_samples.json"
FORMATIONS = ROOT / "app" / "data" / "formations.json"
OUT = ROOT / "app" / "data" / "club_tactics.json"

COPYRIGHT = b"Copyright (c)1996 Dinamic Multimedia"
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


class Stream:
    def __init__(self, d: bytes, p: int):
        self.d = d
        self.p = p
        self.heap = 0  # local_238: string-heap write offset (bounds check)

    def u8(self) -> int:
        v = self.d[self.p]
        self.p += 1
        return v

    def u16(self) -> int:
        v = struct.unpack_from("<H", self.d, self.p)[0]
        self.p += 2
        return v

    def u32(self) -> int:
        v = struct.unpack_from("<I", self.d, self.p)[0]
        self.p += 4
        return v

    def string(self) -> str:
        # FUN_0058c810: [u16 len][len bytes XOR 0x61]; heap use = len+1 (NUL)
        n = self.u16()
        s = bytes(b ^ 0x61 for b in self.d[self.p : self.p + n])
        self.p += n
        self.heap += n + 1
        return s.decode("latin1")

    def skip_lenpfx(self) -> None:
        # the *param_4 = u16@cursor + 2 + cursor idiom (unread field)
        self.p += struct.unpack_from("<H", self.d, self.p)[0] + 2

    def skip_string_plus(self, extra: int) -> None:
        # FUN_00579c70 skip idiom: cursor += u16@cursor + extra
        self.p += struct.unpack_from("<H", self.d, self.p)[0] + extra


def parse_side_record(s: Stream, flag: int, heap_base: int) -> None:
    """FUN_00579170 (tag-2 record): heap cursor resets to heap_base first."""
    s.heap = heap_base
    s.u16()
    s.string()
    if flag == 0:
        for _ in range(7):
            s.skip_lenpfx()
        if s.u8() == 3:
            s.skip_lenpfx()
        s.skip_lenpfx()


def parse_player(s: Stream, flag: int, dbc_id: int) -> dict:
    """FUN_005820f0, fmt<600 path — exact stream order, heap committed."""
    pid = s.u16()
    s.u8()  # -> +0xf8
    name1 = s.string()
    name2 = s.string()
    slot = s.u8()  # -> +0x19 and +0x1b; valid iff < 0x62 (club != 0x26de moot)
    s.u8()  # unread byte
    fines_raw = [s.u8() for _ in range(6)]  # -> +0x1d..: 0 -> 0x62, else raw-1
    s.u8()  # +0x1a
    s.u8()  # +0x16
    s.u8()  # +0x17
    band = s.u8()  # +0x1c: 0 GK / 1 DF / 2 MF / 3 FW
    s.u8()  # birth day (engine-defaulted when 0)
    s.u8()  # birth month
    year = s.u16()  # engine randomizes outside 0x76d..0x7c1 (1901..1985)
    s.u8()  # +0xf9
    s.u8()  # +0xfa (media pair)
    if flag == 0:
        s.p += 1
        s.skip_lenpfx()
        if dbc_id == 0x26AE:
            s.string()
        else:
            s.skip_lenpfx()
        for _ in range(8):
            s.skip_lenpfx()
    attrs = [s.u8() for _ in range(10)]
    return {
        "id": pid,
        "name": name1,
        "fullName": name2,
        "slot": slot,
        "fine": 0x63 if fines_raw[0] == 0 else fines_raw[0],  # == +0x1d + 1
        "band": band,
        "year": year,
        "attrs": attrs,
        "valid": slot < 0x62,
    }


def parse_club_tactic(d: bytes, dbc_id: int) -> dict:
    """Replicates FUN_00579c70: header + 11-slot block + levers + squad loop."""
    if not d.startswith(COPYRIGHT):
        raise ValueError("record does not start with the Copyright marker")
    s = Stream(d, 0x24)
    alloc = s.u16()  # alloc size (local_214)
    fmt = s.u16()  # local_22c, format word — gates the optional fields
    s.u8()  # byte @+0x28, never read by the parser
    flag = s.u8()  # local_230
    name = s.string()  # -> club+0x1c0 tactic name via FUN_0057a3e0
    s.string()  # second string (param_1[2])
    s.u8()  # param_1[5]
    s.string()  # third string (*param_1)
    s.u32()  # param_1[6] (clamped to 6000 if <10 — post-read, no stream effect)
    if fmt >= 0x1FE:
        s.u32()  # param_1[7]
    s.u16()  # +0x34
    s.u16()  # +0x36
    s.u16()  # param_1[0xe]
    if flag == 0:
        if fmt > 0x207:
            s.p += 2
        s.u32()  # param_1[8]
        s.skip_string_plus(6)
        s.u32()  # stadium capacity -> param_1[0x7a]/[0x7b]
        s.skip_string_plus(2)
        s.skip_string_plus(2)
        s.u16()  # param_1[0x9e]
        s.u16()  # +0x27a
        s.u8()  # +0x3a
        if fmt >= 0x203:
            s.p += 0x7B
        elif fmt >= 0x1F9:
            s.p += 0x73
        else:
            s.p += 0x51
    slot_off = s.p
    slots = []
    for _ in range(11):  # FUN_0058c130 x 11: 8 u16 each -> club+0x60 + i*0x20
        f = [s.u16() for _ in range(8)]
        slots.append(
            {
                "raw": f,
                "mk1": [f[4] * 258 // 318, f[5] * 154 // 198],
                "mk2": [f[6] * 258 // 318, f[7] * 154 // 198],
            }
        )
    levers = [s.u8() for _ in range(7)]  # club+0x1d9..+0x1df

    # ---- squad loop (FUN_00579c70 tail) ------------------------------------
    heap_after_header = s.heap  # uVar11: side-records reset the heap here
    tag = s.u8()
    while tag == 2:
        parse_side_record(s, flag, heap_after_header)
        tag = s.u8()
    players = []
    while True:  # outer do-while: one squad object per iteration
        while True:  # inner: re-parse INVALID records into the same object
            saved_heap = s.heap  # local_228 save / local_238 restore
            p = parse_player(s, flag, dbc_id)
            tag = s.u8()
            if tag == 0 or p["valid"]:
                break
            s.heap = saved_heap  # roll back the dropped record's strings
        if p["valid"]:
            players.append(p)
        elif tag == 0:
            pass  # final record dropped (leaver at end of list)
        if tag == 0:
            break
    in_bounds = s.heap <= alloc and s.p <= len(d)
    return {
        "name": name,
        "fmt": fmt,
        "flag": flag,
        "slotOffset": slot_off,
        "slots": slots,
        "levers": levers,
        "players": players,
        "inBounds": in_bounds,
    }


def stock_match(slots: list[dict], stock: list[dict]) -> str | None:
    """Exact-match the 11 (mk1,mk2) raw pairs against the 10 predef formations."""
    key = sorted(tuple(sl["raw"][4:8]) for sl in slots)
    for f in stock:
        if sorted(tuple(sl["raw"][4:8]) for sl in f["slots"]) == key:
            return f["name"]
    return None


def _norm(s: str | None) -> str:
    s = unicodedata.normalize("NFKD", (s or "").upper())
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return re.sub(r"[^A-Z ]", "", s).strip()


def match_xi(players: list[dict], db_players: list[dict]) -> dict:
    """slot -> game_db player, via the cascade in the module docstring.
    Each game_db player is claimable by at most one slot."""
    xi_players: dict[int, dict] = {}
    for p in players:  # engine semantics: last writer wins per slot byte
        if 1 <= p["slot"] <= 11:
            xi_players[p["slot"]] = p
    claimed: set[int] = set()
    out: dict[int, dict] = {}

    def db_attrs(q: dict) -> tuple | None:
        a = q.get("attrs")
        return tuple(a.get(k, -1) for k in ATTR_NAMES) if a else None

    def claim(slot: int, q: dict) -> None:
        claimed.add(id(q))
        out[slot] = q

    def fine_ok(q: dict, p: dict) -> bool:
        # Identity guard for the name/attr passes: game_db posFine (same raw
        # byte, positions_re.md) must agree when present. Catches same-name
        # same-year different-person rows (Swansea's corrupted 'JONES').
        return q.get("posFine") in (None, p["fine"])

    for slot, p in xi_players.items():  # 1: photoId == .DBC id (hard link)
        if p["id"] != 0:
            for q in db_players:
                if q.get("photoId") == p["id"] and id(q) not in claimed:
                    claim(slot, q)
                    break
    for slot, p in xi_players.items():  # 2: unique normalized name (+year)
        if slot in out:
            continue
        nm = _norm(p["name"])
        cands = [
            q
            for q in db_players
            if id(q) not in claimed and fine_ok(q, p) and _norm(q.get("name")) == nm
        ]
        if len(cands) > 1:
            cands = [q for q in cands if q.get("birthYear") == p["year"]]
        if len(cands) == 1:
            claim(slot, cands[0])
    for slot, p in xi_players.items():  # 3: (birthYear, attrs) exact
        if slot in out:
            continue
        cands = [
            q
            for q in db_players
            if id(q) not in claimed
            and fine_ok(q, p)
            and q.get("birthYear") == p["year"]
            and db_attrs(q) == tuple(p["attrs"])
        ]
        if len(cands) == 1:
            claim(slot, cands[0])
    for slot, p in xi_players.items():  # 4: attrs alone (randomized years)
        if slot in out:
            continue
        cands = [
            q
            for q in db_players
            if id(q) not in claimed and fine_ok(q, p) and db_attrs(q) == tuple(p["attrs"])
        ]
        if len(cands) == 1:
            claim(slot, cands[0])
    for slot, p in xi_players.items():  # 5: full/legal containment + year
        if slot in out:
            continue
        fn = _norm(p["fullName"])
        if not fn:
            continue
        cands = []
        for q in db_players:
            if id(q) in claimed or not fine_ok(q, p) or q.get("birthYear") != p["year"]:
                continue
            qn, ql = _norm(q.get("name")), _norm(q.get("legalName"))
            if (qn and (fn in qn or qn in fn)) or (ql and fn in ql):
                cands.append(q)
        if len(cands) == 1:
            claim(slot, cands[0])
    return out


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
        if db_clubs.get(app_id, {}).get("name", "").upper() == rec["name"].upper():
            name_hits += 1

        xi_players: dict[int, dict] = {}
        for p in rec["players"]:
            if 1 <= p["slot"] <= 11:
                xi_players[p["slot"]] = p
        if len(xi_players) == 11:
            xi_slots_full += 1
        matched = match_xi(rec["players"], db_clubs.get(app_id, {}).get("players", []))
        # Kill-test 6: cross-extractor posFine invariant.
        for slot, q in matched.items():
            pf = q.get("posFine")
            if pf is not None:
                assert pf == xi_players[slot]["fine"], (
                    f"{fname}: slot {slot} posFine {pf} != .DBC fine {xi_players[slot]['fine']}"
                )
                fine_checked += 1
        xi = [int(matched[sl]["id"]) if sl in matched else -1 for sl in range(1, 12)]
        if -1 not in xi:
            xi_matched_full += 1
        clubs[str(app_id)] = {
            "dbcId": dbc_id,
            "name": rec["name"],
            "slots": rec["slots"],
            "levers": rec["levers"],
            "stockFormation": stock_match(rec["slots"], stock),
            "xi": xi,
            "xiNames": [xi_players[sl]["name"] if sl in xi_players else "" for sl in range(1, 12)],
            "xiFine": [xi_players[sl]["fine"] if sl in xi_players else 0 for sl in range(1, 12)],
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

    # Kill-test 3: name agreement with game_db.json.
    assert name_hits >= 460, f"only {name_hits}/476 names match game_db.json"

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

    # Kill-test 5 (floor) + 7: coverage.
    assert xi_slots_full >= 470, f"only {xi_slots_full}/476 clubs fill all 11 slots"
    assert xi_matched_full >= 300, f"only {xi_matched_full}/476 clubs fully matched"
    assert -1 not in clubs["40"]["xi"], f"Manchester Utd xi has holes: {clubs['40']['xi']}"

    n_stock = sum(1 for c in clubs.values() if c["stockFormation"])
    out = {
        "_source": (
            "EQUIPOS.PKF per-club .DBC records via tools/re/export_club_tactics.py "
            "(parse = MANAGER.EXE FUN_00579c70 + squad loop FUN_005820f0; draw chain "
            "FUN_005733d0/FUN_005793d0; docs/re/clubtactics/)"
        ),
        "_design_space": {"w": 318, "h": 198},
        "_marker_layer": {"w": 258, "h": 154},
        "_levers_note": (
            "7 bytes at club+0x1d9..+0x1df read right after the slot block; "
            "per-byte meaning un-RE'd (EXACT_PORT_PLAN gap B) — stored raw."
        ),
        "_xi_note": (
            "xi = game_db player id per SHIPPED XI slot 1..11 (player+0x1b in the "
            ".DBC squad records; slot s stands at tactic slot s-1), -1 where the "
            "player is absent/corrupted in game_db (old-cipher squads — rebuild "
            "lever). xiNames/xiFine = the exact-cipher decode + raw fine byte "
            "(== club+0x297+slot array == game_db posFine)."
        ),
        "clubs": clubs,
    }
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(
        f"wrote {OUT.relative_to(ROOT)}: {len(clubs)} clubs, "
        f"{name_hits}/476 names matched, {n_stock} on stock formations, "
        f"XI: {xi_slots_full}/476 slot-complete, {xi_matched_full}/476 fully "
        f"game_db-matched ({fine_checked} posFine cross-checks), "
        f"Barcelona == walked rival_015 + frame-015 XI ✔"
    )


if __name__ == "__main__":
    main()
