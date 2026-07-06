#!/usr/bin/env python3
"""Export every club's OWN stored tactic from DBDAT/EQUIPOS.PKF into a Godot data asset.

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
      strings ([u16 len][bytes XOR 0x61], `FUN_0058c810`), budget/stand
      words with clamps, an optional flag==0 block with fmt-gated tail skip
      (0x51/0x73/0x7b), then:
        tactic name  = strncpy(club+0x1c0, club_name, 0x18)   (`FUN_0057a3e0`)
        11 x 8 u16   -> club slots +0x60 + i*0x20              (`FUN_0058c130`,
                        each u16 widened to u32; fields [4],[5]=mk1, [6],[7]=mk2
                        — same field order as the stock table DAT_00660240)
        7 x u8       -> club+0x1d9..+0x1df   (TEAM TACTICS levers; per-byte
                        semantics un-RE'd — EXACT_PORT_PLAN gap B)
  - Marker mapping to the 258x154 layer is (raw*258/318, raw*154/198), same as
    LINE-UP/TACTICS/VIEW RIVAL (rival_screen_re.md).

KILL-TESTS run on every export (all assert):
  1. All 476 records parse; every slot coord is in the 318x198 design space.
  2. Barcelona (EQ960001, app id 1000): mapped {mk1} / {mk2} sets equal the
     walked rival_015 disc/arrow lists in app/data/rival_chrome_samples.json
     (the frame-baked ground truth from screenshot 015_162415).
  3. Decoded club names match game_db.json names (case-insensitive) for >= 460
     of 476 clubs (the known '?'-recovered records account for the slack).

App id mapping (build_db.py convention, spot-verified): English club app id ==
PKF directory position (pos 38 = first English club); international clubs get
1000 + running count of non-English positions in directory order.

Writes `app/data/club_tactics.json` (committed, source-derived). Reproduce:
    cd tools/re && python3 export_club_tactics.py
"""

from __future__ import annotations

import json
import struct
import sys
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


class Stream:
    def __init__(self, d: bytes, p: int):
        self.d = d
        self.p = p

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
        # FUN_0058c810: [u16 len][len bytes XOR 0x61]
        n = self.u16()
        s = bytes(b ^ 0x61 for b in self.d[self.p : self.p + n])
        self.p += n
        return s.decode("latin1")

    def skip_string_plus(self, extra: int) -> None:
        # FUN_00579c70 skip idiom: cursor += u16@cursor + extra
        self.p += struct.unpack_from("<H", self.d, self.p)[0] + extra


def parse_club_tactic(d: bytes) -> dict:
    """Replicates FUN_00579c70 up to (and including) the 11-slot block + levers."""
    if not d.startswith(COPYRIGHT):
        raise ValueError("record does not start with the Copyright marker")
    s = Stream(d, 0x24)
    s.u16()  # alloc size (local_214)
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
    return {
        "name": name,
        "fmt": fmt,
        "flag": flag,
        "slotOffset": slot_off,
        "slots": slots,
        "levers": levers,
    }


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
    db_names = {c["id"]: c["name"] for c in game_db["clubs"]}
    stock = json.loads(FORMATIONS.read_text())["formations"]

    clubs: dict[str, dict] = {}
    name_hits = 0
    next_intl = 1000
    for pos, (fname, off, size) in enumerate(entries):
        dbc_id = int(fname.upper().removeprefix("EQ96").removesuffix(".DBC"))
        rec = parse_club_tactic(buf[off : off + size])
        for sl in rec["slots"]:
            for x, y in (sl["raw"][4:6], sl["raw"][6:8]):
                assert 0 <= x <= 318 and 0 <= y <= 198, (
                    f"{fname}: slot coord ({x},{y}) outside 318x198 design space"
                )
        if pos in english_positions:
            app_id = pos
        else:
            app_id = next_intl
            next_intl += 1
        if db_names.get(app_id, "").upper() == rec["name"].upper():
            name_hits += 1
        clubs[str(app_id)] = {
            "dbcId": dbc_id,
            "name": rec["name"],
            "slots": rec["slots"],
            "levers": rec["levers"],
            "stockFormation": stock_match(rec["slots"], stock),
        }

    # Kill-test 2: Barcelona vs the walked rival_015 frame bake.
    barca = clubs["1000"]
    assert barca["name"] == "F.C. Barcelona", barca["name"]
    walked = json.loads(RIVAL_SAMPLES.read_text())["rival_markers_015"]
    discs = sorted(tuple(m["mk"]) for m in walked if m["kind"] == "disc")
    arrows = sorted(tuple(m["mk"]) for m in walked if m["kind"] == "arrow")
    got1 = sorted(tuple(sl["mk1"]) for sl in barca["slots"])
    got2 = sorted(tuple(sl["mk2"]) for sl in barca["slots"])
    assert got1 == discs, f"Barcelona mk1 != walked discs:\n{got1}\n{discs}"
    assert got2 == arrows, f"Barcelona mk2 != walked arrows:\n{got2}\n{arrows}"

    # Kill-test 3: name agreement with game_db.json.
    assert name_hits >= 460, f"only {name_hits}/476 names match game_db.json"

    n_stock = sum(1 for c in clubs.values() if c["stockFormation"])
    out = {
        "_source": (
            "EQUIPOS.PKF per-club .DBC records via tools/re/export_club_tactics.py "
            "(parse = MANAGER.EXE FUN_00579c70; draw chain FUN_005733d0/FUN_005793d0; "
            "docs/re/clubtactics/)"
        ),
        "_design_space": {"w": 318, "h": 198},
        "_marker_layer": {"w": 258, "h": 154},
        "_levers_note": (
            "7 bytes at club+0x1d9..+0x1df read right after the slot block; "
            "per-byte meaning un-RE'd (EXACT_PORT_PLAN gap B) — stored raw."
        ),
        "clubs": clubs,
    }
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(
        f"wrote {OUT.relative_to(ROOT)}: {len(clubs)} clubs, "
        f"{name_hits}/476 names matched, {n_stock} on stock formations, "
        f"Barcelona == walked rival_015 ✔"
    )


if __name__ == "__main__":
    main()
