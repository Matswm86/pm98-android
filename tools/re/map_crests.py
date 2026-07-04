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

# club-name decode (same cipher as parse_equipos / extract_english headers).
# Accented letters: byte = 0x80 | (0x20 word-start flag) | accent-code — the
# SAME table extract_squads.py uses for the squad records (clear bit5 to look
# up); an unmapped accent byte stays '+' so it can never fake a match.
_FWD = {L: (L if L % 2 == 0 else L + 2) for L in range(26)}
_C2 = {c: chr(65 + L) for L, c in _FWD.items()}
_C2[1] = " "
_ACCENT = {
    0x80: "Á",
    0x86: "Ç",
    0x88: "É",
    0x8C: "Í",
    0x8E: "Ï",
    0x90: "Ñ",
    0x92: "Ó",
    0x9B: "Ú",
    0x9D: "Ö",
    0x84: "Ü",
    0xCB: "ª",
    # Witnessed in the crest-index club names (raw bytes dumped 2026-07-04):
    # record 165 = CH[83]TEAUROUX (LB Châteauroux) and record 227 = G[97]TEBORG
    # (IFK Göteborg) — the club identities pin the letters.
    0x83: "Â",
    0x97: "Ö",
}


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
            return _ACCENT.get(b & 0xDF, "+")
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

    # Foreign clubs: POSITIONAL, not name-matched. build_db.py assigns foreign ids
    # sequentially (1000, 1001, ...) over teams_all.json entries whose name is not
    # an English club's, in file order; teams_all carries each entry's EQUIPOS
    # record idx, and the crest index is one record per EQUIPOS record in record
    # order (self-checked above: 476 codes == 476 kit filenames). Replaying the
    # id assignment therefore maps every foreign id to its record's code exactly.
    # Cross-check: the crest-index name must EQUAL the teams_all header name
    # wherever both decoded (teams_all '?' headers are recovered by the index).
    teams_all = json.loads(
        (ROOT / "assets" / "teams_all.json").read_text(encoding="utf-8")
    )["teams"]
    eng_names = {
        c["name"]
        for c in json.loads(
            (ROOT / "assets" / "squads_english.json").read_text(encoding="utf-8")
        )["clubs"]
    }
    foreign = {}
    recovered = []
    next_id = 1000  # build_db.py: keep clear of English idx ids
    for t in teams_all:
        if t["name"] in eng_names:
            continue
        cid = next_id
        next_id += 1
        e = by_record[int(t["idx"])]
        if t["name"] != "?":
            assert t["name"] == e["name"], (
                f"record {t['idx']}: teams_all {t['name']!r} != index {e['name']!r}"
            )
        else:
            recovered.append((cid, t["idx"], e["name"]))
        foreign[str(cid)] = e["code"]

    OUT.write_text(
        json.dumps(
            {
                "note": "club_id -> EQ96 kit code, decoded from EQUIPOS.PKF's own club index "
                "(dataOffset==record marker, code = XOR-deciphered DD/NN). English via the "
                "record==id identity, foreign via the positional replay of build_db.py's id "
                "assignment over teams_all record order (names cross-checked); see "
                "tools/re/map_crests.py. Kit PNGs are exported id-named to app/art/kits/, "
                "so the runtime needs id, not code.",
                "verified": {
                    "indexEntries": len(idx),
                    "codesMatchKitFilenames": True,
                    "englishClubs": len(id_to_code),
                    "foreignClubs": len(foreign),
                    "foreignNamesCrossChecked": len(foreign) - len(recovered),
                },
                "english": id_to_code,
                "foreign": foreign,
                "allRecords": [
                    {"record": e["record"], "code": e["code"], "name": e["name"]} for e in idx
                ],
            },
            ensure_ascii=False,
            indent=1,
        ),
        encoding="utf-8",
    )
    print(
        f"wrote {OUT.relative_to(ROOT)}: {len(id_to_code)} English + "
        f"{len(foreign)} foreign clubs mapped"
    )
    for cid in list(id_to_code)[:6]:
        e = by_record[int(cid)]
        print(f"  id {cid:>3} -> EQ96{id_to_code[cid]}  {e['name']}")
    for cid, ridx, nm in recovered:
        print(f"  '?'-header club id {cid} (record {ridx}) named by the index: {nm!r}")

    if "--export" in sys.argv:
        export_kits({**id_to_code, **foreign})


def export_kits(id_to_code: dict[str, str]) -> None:
    """Render each mapped club's MINIESC kit (48x64, corrected VGA palette, index0
    transparent) to app/art/kits/<club_id>.png, plus its NANOESC full kit (24x32
    shirt+shorts+shadow — the art the SELECCION/PRESEASON panels blit 1:1, verified
    SAD-0.0 vs walkthrough frames 008/013 under MANAGER.PAL) to
    app/art/kits/nano/<club_id>.png. NANOESC entries are palette-less OS/2-core
    DIBs -> export_icons.decode_dib. Runs only where the owned PKFs exist
    (extracted/ is gitignored); the PNGs are committed, CI just regenerates .import."""
    from export_art import render, riff_palette  # noqa: PLC0415 - tool-local import
    from export_icons import decode_dib  # noqa: PLC0415 - tool-local import
    from pkf_unpack import parse  # noqa: PLC0415 - tool-local import

    KITS_DIR.mkdir(parents=True, exist_ok=True)
    nano_dir = KITS_DIR / "nano"
    nano_dir.mkdir(parents=True, exist_ok=True)
    buf = (GAME / "DBDAT" / "NANOESC.PKF").read_bytes()
    nano = {}
    for r in parse(buf):
        if r.get("type") == 2:
            off, size, _fid = r["u32s"]
            nano[r["name"]] = bytes(buf[off : off + size])
        if r.get("end"):
            break
    pal = riff_palette("MANAGER.PAL")
    for cid, code in id_to_code.items():
        img = render("DBDAT/MINIESC.PKF", f"EQ96{code}.BMP", force_vga=True, transparent=True)
        img.save(KITS_DIR / f"{cid}.png")
        decode_dib(nano[f"EQ96{code}.BMP"], pal).save(nano_dir / f"{cid}.png")
    print(f"exported {len(id_to_code)} kit PNG pairs -> {KITS_DIR.relative_to(ROOT)} (+nano/)")


if __name__ == "__main__":
    main()
