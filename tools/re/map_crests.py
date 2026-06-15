#!/usr/bin/env python3
"""Map each club to its EQ96 kit-crest code, from EQUIPOS.PKF's own club index.

The kit archives (MINIESC/RIDIESC/NANOESC/BIGESC.PKF) are keyed by an `EQ96DDNN`
code where DD = division, NN = position-in-division. That code is NOT the game_db
club id and is NOT a clean positional index (the codes have gaps, and record order
!= code order across divisions). The authoritative club->code map lives in the
EQUIPOS.PKF club INDEX: a table of 38-byte entries, each carrying the obfuscated
EQ96 code AND a u32 dataOffset that points EXACTLY at that club's "Copyright (c)1996
Dinamic Multimedia" record marker. So index entry k <-> record k, 1:1.

Index entry layout (base = the 0x02 lead byte):
    +0   u8   0x02 lead
    +1   6B   obfuscated signature 9a 91 9a be <sig5> <sig6>
    +7   u8   b7   (NN tens, ciphered)
    +8   u8   pos  (NN ones, plain)
    +9   3B   31 54 41           (constant marker)
    +12  9B   bb ef af a2 e0 fa df a3 e8   (constant blob -- the search anchor)
    +21  5B   00 00 00 00 00
    +26  u32  dataOffset  (== Copyright record marker)
    +30  u32  size
    +34  u32  01 00 00 00

EQ96 code cipher (verified: the 476 decoded codes set-equal the 476 MINIESC
filenames exactly):
    DD = (0x5f ^ sig5) * 10 + (0x68 ^ sig6)
    NN = (0x73 ^ b7)   * 10 + pos

English clubs (DD == 3) occupy records 38..129 with NN running 1..92 in record
order, so game_db English id (== record idx) maps to code 03NN, NN = idx - 37.
Cross-checked visually against the corrected palette: 0301 Blackburn (blue/white),
0303 Man Utd (red), 0307 Newcastle (black/white stripes), 0309 Arsenal (red/white
sleeves), 0312 Chelsea (blue).

Output: assets/crest_codes.json  (build artifact; runtime uses id-named PNGs).
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
GAME = ROOT / "extracted" / "Premier Manager 98"
EQUIPOS = GAME / "DBDAT" / "EQUIPOS.PKF"
MINIESC = GAME / "DBDAT" / "MINIESC.PKF"
OUT = ROOT / "assets" / "crest_codes.json"
KITS_DIR = ROOT / "app" / "art" / "kits"

BLOB = bytes.fromhex("bbefafa2e0fadfa3e8")  # entry offset +12
COPY = b"Copyright (c)1996 Dinamic Multimedia"
MM = b"Dinamic Multimedia"

# club-name decode (same cipher as parse_equipos / extract_english headers)
_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
_C2 = {c: chr(65 + L) for L, c in _FWD.items()}
_C2[1] = " "


def _name(d: bytes, off: int) -> str:
    e = d.find(MM, off, off + 80)
    if e < 0:
        return "?"
    p = e + len(MM) + 6
    ln = struct.unpack_from("<H", d, p)[0]
    if not (2 <= ln <= 60):
        return "?"

    def ch(b: int) -> str:
        if b == 0x4F:
            return "."
        if b >= 0x80:
            return "+"
        return _C2.get(b & 0x1F, "?")

    return "".join(ch(d[p + 2 + k]) for k in range(ln)).strip()


def parse_index(d: bytes) -> list[dict]:
    """Return [{record, code, dataOff, name}] in file (record) order."""
    out: list[dict] = []
    i = 0
    while True:
        f = d.find(BLOB, i)
        if f < 0:
            break
        base = f - 12
        i = f + 1
        if base < 0 or d[base] != 0x02:
            continue
        sig5, sig6, b7, pos = d[base + 5], d[base + 6], d[base + 7], d[base + 8]
        dd = (0x5F ^ sig5) * 10 + (0x68 ^ sig6)
        nn = (0x73 ^ b7) * 10 + pos
        do = struct.unpack_from("<I", d, base + 26)[0]
        out.append(
            {"record": len(out), "code": f"{dd:02d}{nn:02d}", "dataOff": do, "name": _name(d, do)}
        )
    return out


def minfile_codes() -> set[str]:
    from pkf_unpack import files_of  # noqa: PLC0415 - tool-local import

    buf = MINIESC.read_bytes()
    return {n[4:8] for n, _o, _s in files_of(buf)}


def main() -> None:
    d = EQUIPOS.read_bytes()
    idx = parse_index(d)

    # global self-check: the decoded codes must exactly reproduce the kit filenames
    decoded = {e["code"] for e in idx}
    mini = minfile_codes()
    assert len(idx) == 476, f"expected 476 index entries, got {len(idx)}"
    assert decoded == mini, f"code cipher mismatch: {sorted(decoded ^ mini)[:10]}"

    # English clubs: DD == 03, records 38..129, NN sequential 1..92
    english = [e for e in idx if e["code"].startswith("03")]
    recs = [e["record"] for e in english]
    nns = [int(e["code"][2:]) for e in english]
    assert recs == list(range(38, 130)), f"English records not 38..129: {recs[:5]}..."
    assert nns == list(range(1, 93)), f"English NN not 1..92: {nns[:5]}..."

    # game_db English id == record idx (build_db: cid = idx). Map id -> code.
    db = json.loads((ROOT / "app" / "data" / "game_db.json").read_text(encoding="utf-8"))
    eng_ids = {c["id"] for c in db["clubs"] if c.get("country") == "England"}
    by_record = {e["record"]: e for e in idx}
    id_to_code = {}
    missing = []
    for cid in sorted(eng_ids):
        e = by_record.get(cid)
        if e and e["code"].startswith("03"):
            id_to_code[str(cid)] = e["code"]
        else:
            missing.append(cid)
    assert not missing, f"English game_db ids without an 03xx record: {missing}"

    OUT.write_text(
        json.dumps(
            {
                "note": "club_id -> EQ96 kit code, decoded from EQUIPOS.PKF's own club index "
                "(dataOffset==record marker, code = XOR-deciphered DD/NN). English only "
                "for now (the playable pyramid); see tools/re/map_crests.py. Kit PNGs are "
                "exported id-named to app/art/kits/, so the runtime needs id, not code.",
                "verified": {
                    "indexEntries": len(idx),
                    "codesMatchKitFilenames": True,
                    "englishClubs": len(id_to_code),
                },
                "english": id_to_code,
                "allRecords": [
                    {"record": e["record"], "code": e["code"], "name": e["name"]} for e in idx
                ],
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )
    print(f"wrote {OUT.relative_to(ROOT)}: {len(id_to_code)} English clubs mapped")
    for cid in list(id_to_code)[:6]:
        e = by_record[int(cid)]
        print(f"  id {cid:>3} -> EQ96{id_to_code[cid]}  {e['name']}")

    if "--export" in sys.argv:
        export_kits(id_to_code)


def export_kits(id_to_code: dict[str, str]) -> None:
    """Render each mapped club's MINIESC kit (48x64, corrected VGA palette, index0
    transparent) to app/art/kits/<club_id>.png. Runs only where the owned PKFs exist
    (extracted/ is gitignored); the PNGs are committed, CI just regenerates .import."""
    from export_art import render  # noqa: PLC0415 - tool-local import

    KITS_DIR.mkdir(parents=True, exist_ok=True)
    for cid, code in id_to_code.items():
        img = render("DBDAT/MINIESC.PKF", f"EQ96{code}.BMP", force_vga=True, transparent=True)
        img.save(KITS_DIR / f"{cid}.png")
    print(f"exported {len(id_to_code)} kit PNGs -> {KITS_DIR.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
