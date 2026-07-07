#!/usr/bin/env python3
"""Extract real-player data from a CM 01/02 database (Data/*.dat, 2002-03 era).

Source: the "Data and Exe and Pictures January 2026" zip = full CM01/02 game with
the champman0102.co.uk update-project database whose SQUADS are the original
2002-03 season (era bracketed by Rio Ferdinand@ManUtd + Nesta@Milan with
Beckham/Verón still@ManUtd and Rooney@Everton CA90/PA190).

Format (reversed 2026-07-06, field layout confirmed against archibalduk's
open-source TransferTool database/player.h + database/staff.cpp):
  index.dat   8B header, then 67B records: name[51] + i32 file-id + i32 count
              + i32 offset + i32 version. staff.dat appears 4x: staff table
              (110B recs @0), non-players (68B), players (70B), prefs (52B).
  staff.dat   staff rec (packed): id i32@0, first/second/common name idx @4/8/12
              (indexes into the name .dats' id field), DOB @16 {u16 day0, u16
              year, u32 leap} (year 1900 = unknown), nation i32@26, club i32@57
              (-1 = clubless), date-joined @62, player-idx i32@97 (-1 = not a
              player), own-id@101, nonplayer-idx@105.
  player rec  (70B): id i32@0, squad-no i8@4, CA i16@5, PA i16@7, home/current/
              world rep i16 @9/11/13, then u8 ratings 1-20: GK@15 SW@16 D@17
              DM@18 M@19 AM@20 ST@21 WB@22, sides R@23 L@24 C@25, free-role@26,
              43 technical/mental attrs @27-69. Position = argmax of the eight
              role ratings + best side, so (unlike the FM05/06 extracts) the
              Position column is REAL here.
  *_names.dat 60B recs: name[51] + i32 id @51. Common name '' = none.
  club.dat    581B recs, full name[51] @+4, referenced by record index.
  nation.dat  290B recs, name[51] @+4, era spellings (Holland, Yugoslavia).

Random-PA codes: CM01/02 uses ONLY -1 and -2 (this DB: 4,505 / 469 among
players) and their bands differ from FM's -1..-95 scheme, so codes are resolved
HERE, not by talent_ingest.resolve_pa (whose FM formula would turn -1 into PA
1-20). Per the champman0102.net editor threads (t=5715, Cloudflare-blocked;
via search snippets, cross-checked with the GameFAQs editor FAQ): -1 = "very
promising", rolled ~120-200 biased low; -2 = rolled high, "generally 160-200".
Empirical support in this DB: -2 carriers skew younger/stronger (Keane,
Cambiasso, Nakamura, Mantorras). Both rolls are deterministic, seeded
md5(foldedName|birthYear) — same convention as talent_ingest.

The rolls do NOT copy the game bands verbatim: 2,722 of the 19,354 young rows
are coded (the update DB leans on codes), and game-band rolls minted 364
tier-1s in this one season vs 44 real-PA tier-1s (FM 03-04 baseline: 23) —
fake-wonderkid news spam that starves real stars out of the FA market. The
pipeline precedent is FM's Messi (PA -8 -> band 130-160, tier 2-3; curation
promotes to tier 1), i.e. a coded PA is a roll, not researcher belief, so it
never outranks real-PA rows. Ceilings are pinned at 179 (tier-1 cut is 180):
-1 = 120 + min(three draws 0-59)  (low-biased, mean ~135; tier 4-5 mass)
-2 = 150 + min(two draws 0-29)    (mean ~160; tier 2 ~25%, never tier 1).

Names are emitted LEGAL-first ("Ricardo Izecson dos Santos Leite", not "Kaká"):
the shipped pool and the cmfm season CSVs key people by legal name, so
common-first would break cross-season dedupe. Common name is a fallback only.

Output (same schema as cmfm_extract.py / fm0506_extract.py):
  players_<season>.csv  Name,Club,Position,Nat,BirthYear,CA,PA,Season,Age (14..21)
  all_<season>.csv      every person with a player record + a known birth year

Usage:
  python3 tools/cm0102_extract.py "extracted/cm0102/Data and Exe and Pictures January 2026/Data" \
      --season 2002-03 --out-dir extracted/cmfm
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import struct
import unicodedata
from pathlib import Path

STAFF_REC = 110
PLAYER_REC = 70
NAME_REC = 60
CLUB_REC = 581
NATION_REC = 290

# player-rec role ratings @15..22 in TransferTool field order; ties resolve to
# the earlier role (GK beats an equal outfield rating — correct for keepers)
ROLES = ("GK", "SW", "D", "DM", "M", "AM", "ST", "WB")


def fold(s: str) -> str:
    """talent_ingest.fold — keep in sync so seeded PA rolls stay stable."""
    s = unicodedata.normalize("NFKD", str(s)).encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", s.upper()).strip()


def resolve_cm_pa(pa: int, name: str, birth_year: int) -> int:
    if pa >= 0:
        return pa
    h = int(hashlib.md5(f"{fold(name)}|{birth_year}".encode()).hexdigest(), 16)
    if pa == -1:
        return 120 + min(h % 60, (h >> 32) % 60, (h >> 64) % 60)
    return 150 + min(h % 30, (h >> 32) % 30)  # -2 (the editor clamps at -2)


def position_of(rec: bytes) -> str:
    roles = dict(zip(ROLES, rec[15:23]))
    best = max(ROLES, key=lambda r: roles[r])
    r_side, l_side, c_side = rec[23], rec[24], rec[25]
    side = "C" if c_side >= max(r_side, l_side) else ("R" if r_side >= l_side else "L")
    if best == "GK":
        return "GK"
    if best == "SW":
        return "D C"
    if best in ("D", "WB"):
        return f"D {side}"
    if best == "DM":
        return "DM"
    if best == "ST":
        return "ST"
    return f"{best} {side}"  # M / AM


def load_index(datadir: Path) -> list[tuple[str, int, int]]:
    idx = (datadir / "index.dat").read_bytes()
    out = []
    for off in range(8, len(idx) - 66, 67):
        name = idx[off : off + 51].split(b"\x00")[0].decode("ascii")
        _fid, count, offset, _ver = struct.unpack_from("<4i", idx, off + 51)
        out.append((name, count, offset))
    return out


def load_names(path: Path, count: int) -> dict[int, str]:
    data = path.read_bytes()
    out = {}
    for i in range(count):
        rec = data[i * NAME_REC : (i + 1) * NAME_REC]
        nm = rec[:51].split(b"\x00")[0].decode("cp1252", errors="replace")
        out[struct.unpack_from("<i", rec, 51)[0]] = nm
    return out


def load_table_names(path: Path, count: int, rec_size: int) -> list[str]:
    data = path.read_bytes()
    return [
        data[i * rec_size + 4 : i * rec_size + 55]
        .split(b"\x00")[0]
        .decode("cp1252", errors="replace")
        for i in range(count)
    ]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("datadir", type=Path, help="the game's Data/ directory")
    ap.add_argument("--season", default="2002-03")
    ap.add_argument("--max-age", type=int, default=21)
    ap.add_argument("--out-dir", type=Path, default=Path("extracted/cmfm"))
    args = ap.parse_args()
    season_start = int(args.season.split("-")[0])

    tables = load_index(args.datadir)
    staff_secs = sorted((c, o) for n, c, o in tables if n == "staff.dat")
    staff_secs = sorted(((c, o) for c, o in staff_secs), key=lambda t: t[1])
    (n_staff, staff_off), (_n_np, _np_off), (n_players, players_off), _prefs = staff_secs
    counts = {n: c for n, c, _ in tables}
    print(f"[index] staff={n_staff:,} players={n_players:,} clubs={counts['club.dat']:,}")

    first = load_names(args.datadir / "first_names.dat", counts["first_names.dat"])
    sur = load_names(args.datadir / "second_names.dat", counts["second_names.dat"])
    common = load_names(args.datadir / "common_names.dat", counts["common_names.dat"])
    clubs = load_table_names(args.datadir / "club.dat", counts["club.dat"], CLUB_REC)
    nations = load_table_names(args.datadir / "nation.dat", counts["nation.dat"], NATION_REC)

    staff = (args.datadir / "staff.dat").read_bytes()
    players = staff[players_off : players_off + n_players * PLAYER_REC]

    rows = []
    skipped_year = coded = 0
    for k in range(n_staff):
        off = staff_off + k * STAFF_REC
        pidx = struct.unpack_from("<i", staff, off + 97)[0]
        if pidx < 0 or pidx >= n_players:
            continue
        _day, yr = struct.unpack_from("<HH", staff, off + 16)
        if yr <= 1900:
            skipped_year += 1
            continue
        fn, sn, cn = struct.unpack_from("<3i", staff, off + 4)
        nat = struct.unpack_from("<i", staff, off + 26)[0]
        club = struct.unpack_from("<i", staff, off + 57)[0]
        f, s = first.get(fn, ""), sur.get(sn, "")
        nm = f"{f} {s}".strip() or common.get(cn, "")
        if not nm:
            continue
        prec = players[pidx * PLAYER_REC : (pidx + 1) * PLAYER_REC]
        ca, pa = struct.unpack_from("<hh", prec, 5)
        if pa < 0:
            coded += 1
            pa = resolve_cm_pa(pa, nm, yr)
        rows.append(
            {
                "Name": nm,
                "Club": clubs[club] if 0 <= club < len(clubs) else "",
                "Position": position_of(prec),
                "Nat": nations[nat].upper() if 0 <= nat < len(nations) else "",
                "BirthYear": yr,
                "CA": ca,
                "PA": pa,
                "Season": args.season,
                "Age": season_start - yr,
            }
        )
    print(
        f"[rows] {len(rows):,} players ({skipped_year:,} skipped: unknown birth year; {coded:,} random-PA codes resolved)"
    )

    young = [r for r in rows if 14 <= r["Age"] <= args.max_age]
    young.sort(key=lambda r: (-r["PA"], r["Name"]))
    print(f"[rows] {len(young):,} aged 14-{args.max_age} in {args.season}")

    def write(path: Path, rws: list[dict]) -> None:
        with path.open("w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rws[0].keys()))
            w.writeheader()
            w.writerows(rws)
        print(f"[out] {path} ({len(rws):,} rows)")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write(args.out_dir / f"all_{args.season}.csv", rows)
    write(args.out_dir / f"players_{args.season}.csv", young)

    print(
        "\nEra anchors (verify: Rooney@Everton 90/190 ST, Ferdinand@ManUtd, Nesta@Milan, Beckham@ManUtd):"
    )
    anchors = {
        "Wayne Rooney": 1985,
        "Rio Ferdinand": 1978,
        "Alessandro Nesta": 1976,
        "David Beckham": 1975,
        "Gianluigi Buffon": 1978,
        "Ronaldo de Assis Moreira": 1980,
    }
    for r in rows:
        if anchors.get(r["Name"]) == r["BirthYear"]:
            print(f"  {r['Name']}: {r['Club']} CA{r['CA']} PA{r['PA']} {r['Position']}")
    print("\nTop-15 PA young (spot-check):")
    for r in young[:15]:
        print(
            f"  PA{r['PA']:3d} CA{r['CA']:3d} {r['Name']} b.{r['BirthYear']} {r['Club']} [{r['Nat']}] {r['Position']}"
        )


if __name__ == "__main__":
    main()
