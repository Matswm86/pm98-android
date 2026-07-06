#!/usr/bin/env python3
"""Extract player data from FM retro-database editor files (.fm, fmf container).

Reverse-engineered 2026-07-06 from three community retro DBs (FM24/FM26 era).
Container: magic 02 01 "fmf." + concatenated zstd or zlib frames. The decompressed
blob holds (a) a serialized DB snapshot and (b) an editor CHANGE STREAM of TLV
records — this tool reads the change stream, which carries every person the mod
creates with real-era data (names, DoB, club, nationality, CA/PA, positions).

Change-stream grammar (4cc tags appear byte-reversed in the file):
    dtty <u8>  duni <u64 uid>  prty <4cc prop>  nwvl <typed value>  vers <u16>  UpAC <u8>
Typed values: 01=i32 03/11=i8 12=i16 1a=str(u32 len+utf8) 20=date 0a=ref{u32,4cc,val}
0f=u64 (club refs hold the id twice as 2×u32).
The byte types are SIGNED: the writer promotes to i16 for values >= 128 (verified on
PPAB/PCAB: every i16 value is 128-200, every i8 value is -128..127), so a raw byte
>= 0x80 is a negative — FM's random-PA codes (-1..-10 whole stars, -15..-95 half
stars, i.e. -95 = "9.5"), which the 1999-00 retro mod uses. CA is never coded.
Date u32 = (year << 17) | (day_of_year_1based << 8) | flags. Retro mods shift birth
years forward by a constant so ages match the host game's start date; the shift is
derived per file from anchor players with known real birth years and subtracted out.

Properties used: Pfna/Psna/Pfln names, Pdob DoB, Pcti club ref (Ttea id),
Pnti nationality ref (Nnat id), PCAB/PPAB = CA/PA (1-200), PP** position ratings
(1-20; a keeper has NO PP position props — Barthez/Kahn verified).

Club names come from the snapshot's club table: records of the form
    <city u32> <id0 u32> <id0 u32> 00 <comp u32> ffffffff <comp u32> <comp u32>
    <idx u32> 00 ?? ?? 10 ?? ?? <len u32><long name> <len u32><short name>
where change-stream club id = id0 + 1 (verified: Man Utd 679+1=680 via Beckham/Giggs,
Juventus 1138+1=1139 via Zidane, Middlesbrough 684+1=685).

Output: CSV for tools/talent_ingest.py — Name,Club,Position,Nat,BirthYear,CA,PA,Season
(Nat is the raw FM nation id until the id->name map is resolved).
"""

from __future__ import annotations

import argparse
import csv
import mmap
import re
import struct
import sys
import zlib
from collections import Counter, defaultdict
from pathlib import Path

ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"
ZLIB_MAGIC = b"\x78\x9c"
CHUNK = 1 << 20

# full/display name -> real birth year, for detecting each file's year shift
DEFAULT_ANCHORS = {
    "David Robert Joseph Beckham": 1975,
    "David Beckham": 1975,
    "Zinedine Yazid Zidane": 1972,
    "Zinedine Zidane": 1972,
    "Ryan Joseph Giggs": 1973,
    "Ryan Giggs": 1973,
    "Paolo Cesare Maldini": 1968,
    "Gabriel Omar Batistuta": 1969,
    "Gabriel Batistuta": 1969,
    "Oliver Rolf Kahn": 1969,
    "Oliver Kahn": 1969,
    "Fabien Alain Barthez": 1971,
    "Fabien Barthez": 1971,
}

# Position slot props (u8 1-20), calibrated on known 1999 players (Seaman/Bosnich
# Pgoa; Stam/Ferdinand/Leboeuf Pdce; Lizarazu/Le Saux Pdls; G.Neville/Salgado Pdrs;
# Zanetti/Zambrotta Pwbr; Deschamps/Vieira/Keane Pdmc; Scholes Pmce; Giggs Pmls;
# Beckham/Kanchelskis Pmrs; Overmars Paml; Carbone/Poyet Pamc). There is NO striker
# tag anywhere in the tag census: pure STs (Saviola, Owen) carry no position props,
# so no-position-tags + not-GK => ST. PP* tags are hidden attributes, NOT positions.
POS_TAG: dict[str, str] = {
    "Pgoa": "GK",
    "Pdce": "D C",
    "Pdls": "D L",
    "Pdrs": "D R",
    "Pwbl": "D L",
    "Pwbr": "D R",
    "Pdmc": "DM",
    "Pmce": "M C",
    "Pmls": "M L",
    "Pmrs": "M R",
    "Pamc": "AM C",
    "Paml": "AM L",
    "Pamr": "AM R",
}


def decompress_container(src: Path, cache: Path) -> Path:
    if cache.exists() and cache.stat().st_size > 0:
        return cache
    with open(src, "rb") as f:
        data = mmap.mmap(f.fileno(), 0, prot=mmap.PROT_READ)
    n = len(data)
    frames = 0
    with open(cache, "wb") as fh:
        for magic, make in ((ZSTD_MAGIC, None), (ZLIB_MAGIC, zlib.decompressobj)):
            if magic == ZSTD_MAGIC:
                try:
                    import zstandard
                except ImportError:
                    continue
                make = lambda: zstandard.ZstdDecompressor().decompressobj()  # noqa: E731
                errs: tuple = (zstandard.ZstdError,)
            else:
                errs = (zlib.error,)
            pos = 0
            while True:
                start = data.find(magic, pos)
                if start == -1:
                    break
                dobj = make()
                fed = 0
                buf = []
                ok = True
                try:
                    while not dobj.eof and start + fed < n:
                        piece = data[start + fed : start + fed + CHUNK]
                        buf.append(dobj.decompress(piece))
                        fed += len(piece)
                except errs:
                    ok = False
                if not ok or not dobj.eof:
                    pos = start + 1
                    continue
                for b in buf:
                    fh.write(b)
                frames += 1
                pos = start + max(fed - len(dobj.unused_data), len(magic))
            if frames:
                break
    print(f"[decompress] {src.name}: {frames} frames -> {cache.stat().st_size:,} bytes")
    return cache


def parse_value(mm, p):
    """Parse a 'nwvl' typed value starting at its 01 marker. -> (value, endpos)"""
    t = mm[p + 1]
    q = p + 2
    if t == 0x1A:
        ln = struct.unpack("<I", mm[q : q + 4])[0]
        if ln > 4096:
            raise ValueError("string too long")
        return mm[q + 4 : q + 4 + ln].decode("utf-8", "replace"), q + 4 + ln
    if t == 0x20:
        v = struct.unpack("<I", mm[q : q + 4])[0]
        return ("date", v >> 17, (v >> 8) & 0x1FF), q + 4
    if t in (0x03, 0x11):
        return struct.unpack("<b", mm[q : q + 1])[0], q + 1
    if t == 0x12:
        return struct.unpack("<h", mm[q : q + 2])[0], q + 2
    if t in (0x01, 0x02):
        return struct.unpack("<i", mm[q : q + 4])[0], q + 4
    if t == 0x0F:
        a, b = struct.unpack("<II", mm[q : q + 8])
        return ("u64", a, b), q + 8
    if t == 0x0A:
        cls = mm[q + 4 : q + 8][::-1].decode("ascii", "replace")
        if cls == "id  " and mm[q + 8 : q + 10] == b"\x01\x02" and mm[q + 10 : q + 14] == b"lvwn":
            # FM26 wraps some refs (nation ids) one level deeper:
            #   01 0a <u32> "id  " 01 02 nwvl <cls2 4cc> <typed value> [DBID i16 ...]
            # e.g. Pnti -> Nnat u64(776,776) = Italy. FM24/99-00 use the flat form.
            cls2 = mm[q + 14 : q + 18][::-1].decode("ascii", "replace")
            inner, np = parse_value(mm, q + 18)
            return ("ref", cls2, inner), np
        inner, np = parse_value(mm, q + 8)
        return ("ref", cls, inner), np
    raise ValueError(f"unknown value type {t:#x}")


def ref_id(val):
    """Numeric id out of a ('ref', cls, inner) value, or None."""
    if not (isinstance(val, tuple) and val and val[0] == "ref"):
        return None
    inner = val[2]
    while isinstance(inner, tuple) and inner and inner[0] == "ref":
        inner = inner[2]
    if isinstance(inner, int):
        return inner
    if isinstance(inner, tuple) and inner[0] == "u64":
        return inner[1]
    return None


KEEP_PREFIXES: tuple[str, ...] = ()
KEEP = {"Pfna", "Psna", "Pfln", "Pdob", "Pcti", "Pnti", "PCAB", "PPAB", "Psnu"} | set(POS_TAG)


def scan_change_stream(mm) -> dict[bytes, dict]:
    """One sequential pass; returns uid -> {prop: last value}."""
    people: dict[bytes, dict] = defaultdict(dict)
    pos = 0
    n = len(mm)
    parsed = bad = 0
    dropped = 0  # release scanned pages so earlyoom doesn't kill us on this 8GB box
    while pos < n:
        if pos - dropped > (64 << 20):
            mm.madvise(mmap.MADV_DONTNEED, 0, pos & ~0xFFF)
            dropped = pos
        i = mm.find(b"ytrp\x01\x02", pos)
        if i == -1:
            break
        pos = i + 6
        if mm[i - 14 : i - 8] != b"inud\x01\x0f":
            continue
        prop_raw = mm[i + 6 : i + 10]
        if mm[i + 10 : i + 14] != b"lvwn":
            continue
        prop = prop_raw[::-1].decode("ascii", "replace")
        if prop not in KEEP:
            continue
        uid = bytes(mm[i - 8 : i])
        try:
            val, _end = parse_value(mm, i + 14)
        except (ValueError, struct.error, IndexError):
            bad += 1
            continue
        people[uid][prop] = val
        parsed += 1
    print(f"[scan] kept {parsed:,} prop edits ({bad} unparsable) across {len(people):,} uids")
    return people


# <id0 u32>x2 00 <u32> ffffffff <comp u32>x2 <idx u32> <3B> 10 <2B> <len><long><len><short>
# (first u32 after the 00 usually equals comp but not always — Real Madrid has 0 there)
CLUB_RE = re.compile(rb"(?s)(.{4})\1\x00.{4}\xff\xff\xff\xff(.{4})\2.{4}.{3}\x10.{2}", re.DOTALL)


def scan_club_table(mm) -> dict[int, str]:
    """Snapshot club table -> {change-stream club id: long name}."""
    clubs: dict[int, str] = {}
    for m in CLUB_RE.finditer(mm):
        q = m.end()
        (l0,) = struct.unpack("<I", mm[q : q + 4])
        if not (2 <= l0 <= 60):
            continue
        try:
            name_s = mm[q + 4 : q + 4 + l0].decode("utf-8")
        except UnicodeDecodeError:
            continue
        if not name_s or any(ord(c) < 0x20 for c in name_s):
            continue
        (l1,) = struct.unpack("<I", mm[q + 4 + l0 : q + 8 + l0])
        if not (0 <= l1 <= 60):
            continue
        (id0,) = struct.unpack("<I", m.group(1))
        if id0 > 2_000_000:
            continue
        clubs.setdefault(id0 + 1, name_s)
    print(f"[clubs] {len(clubs):,} club records")
    return clubs


def detect_shift(people: dict, anchors: dict[str, int]) -> int | None:
    votes = Counter()
    for props in people.values():
        fln = props.get("Pfln")
        disp = f"{props.get('Pfna') or ''} {props.get('Psna') or ''}".strip()
        name = fln if isinstance(fln, str) and fln in anchors else disp
        if name in anchors:
            dob = props.get("Pdob")
            if isinstance(dob, tuple) and dob[0] == "date":
                votes[dob[1] - anchors[name]] += 1
    if not votes:
        return None
    shift, cnt = votes.most_common(1)[0]
    print(f"[shift] year shift = +{shift} (anchor votes: {dict(votes)})")
    if len(votes) > 1:
        print("[shift] WARNING: anchors disagree — check manually", file=sys.stderr)
    return shift


def position_of(props: dict) -> str:
    slots = {k: v for k, v in props.items() if k in POS_TAG and isinstance(v, int) and v > 0}
    if not slots:
        return "ST"  # striker has no slot tag in this format (verified: Saviola, Owen)
    return POS_TAG[max(slots, key=slots.get)]


def rosetta(people: dict) -> None:
    """Print, per position tag, top-CA players rated 20 there (sanity check)."""
    samples = defaultdict(list)
    for props in people.values():
        ca = props.get("PCAB")
        if not isinstance(ca, int) or ca < 150:
            continue
        for k, v in props.items():
            if k in POS_TAG and v == 20:
                samples[k].append((ca, f"{props.get('Pfna', '?')} {props.get('Psna', '?')}"))
    for tag in sorted(samples):
        top = [n for _, n in sorted(samples[tag], reverse=True)[:6]]
        print(f"{tag} ({POS_TAG[tag]}): {len(samples[tag]):4d} | {', '.join(top)}")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("src", type=Path, help=".fm container or decompressed .bin blob")
    ap.add_argument("--season", help="season the DB represents, e.g. 1999-00")
    ap.add_argument("--out", type=Path, help="output CSV (young players)")
    ap.add_argument("--full-out", type=Path, help="optional CSV of ALL people with DoB+CA")
    ap.add_argument("--max-age", type=int, default=21, help="age cap at season start (default 21)")
    ap.add_argument("--rosetta", action="store_true", help="print PP-tag calibration and exit")
    ap.add_argument(
        "--clubs-from",
        type=Path,
        help="blob to read the snapshot club table from (default: the input itself); "
        "club ids are FM-baseline-stable, so the FM26 blob's table serves all files",
    )
    args = ap.parse_args()

    blob = args.src
    if args.src.suffix.lower() == ".fm":
        cache = args.src.parent / (args.src.stem.replace(" ", "_") + ".bin")
        blob = decompress_container(args.src, cache)
    with open(blob, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, prot=mmap.PROT_READ)

    people = scan_change_stream(mm)
    if args.rosetta:
        rosetta(people)
        return
    if not args.season:
        ap.error("--season is required unless --rosetta")
    season_start = int(args.season.split("-")[0])

    import json

    if args.clubs_from and args.clubs_from.suffix == ".json":
        clubs = {int(k): v for k, v in json.loads(args.clubs_from.read_text()).items()}
        print(f"[clubs] {len(clubs):,} from {args.clubs_from.name}")
    elif args.clubs_from and args.clubs_from != blob:
        with open(args.clubs_from, "rb") as cf:
            cmm = mmap.mmap(cf.fileno(), 0, prot=mmap.PROT_READ)
        clubs = scan_club_table(cmm)
        cmm.close()
    else:
        clubs = scan_club_table(mm)
    cache_json = blob.parent / "clubs_cache.json"
    if len(clubs) > 1000 and not cache_json.exists():
        cache_json.write_text(json.dumps(clubs))
        print(f"[clubs] cached -> {cache_json}")
    shift = detect_shift(people, DEFAULT_ANCHORS)
    if shift is None:
        sys.exit("no anchor players found — cannot derive year shift")

    rows = []
    for props in people.values():
        dob = props.get("Pdob")
        fna, sna = props.get("Pfna"), props.get("Psna")
        if not (isinstance(dob, tuple) and dob[0] == "date" and (fna or sna)):
            continue
        ca, pa = props.get("PCAB"), props.get("PPAB")
        if not isinstance(pa, int):
            continue
        birth_year = dob[1] - shift
        club_id = ref_id(props.get("Pcti"))
        nat_id = ref_id(props.get("Pnti"))
        if nat_id is not None and nat_id > 100_000:
            nat_id = None  # u64 uid of a mod-created nation record, not a baseline id
        rows.append(
            {
                "Name": f"{fna or ''} {sna or ''}".strip(),
                "Club": clubs.get(club_id, f"FM#{club_id}" if club_id else ""),
                "Position": position_of(props),
                "Nat": nat_id if nat_id is not None else "",
                "BirthYear": birth_year,
                "CA": ca if isinstance(ca, int) else "",
                "PA": pa,
                "Season": args.season,
                "Age": season_start - birth_year,
            }
        )

    young = [r for r in rows if 14 <= r["Age"] <= args.max_age]
    print(
        f"[rows] {len(rows):,} people with DoB+PA; {len(young):,} aged 14-{args.max_age} in {args.season}"
    )

    def write(path: Path, data: list[dict]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(data[0].keys()))
            w.writeheader()
            w.writerows(data)
        print(f"[out] {path} ({len(data):,} rows)")

    if args.out and young:
        write(args.out, sorted(young, key=lambda r: -r["PA"]))
    if args.full_out and rows:
        write(args.full_out, sorted(rows, key=lambda r: -r["PA"]))


if __name__ == "__main__":
    main()
