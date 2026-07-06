#!/usr/bin/env python3
"""Extract real-player data from FM2005/FM2006 retail-CD databases (SI 'tad.' format).

The retail discs ship the DB as InstallShield cab payload files (GUID names). After
`bin2iso.py` + `7z x PC/Data1.cab -ocab`, point this script at the cab dir. Format
was reverse-engineered 2026-07-06 (session 5) and verified on FM2005 against
Rooney/Beckham/Zidane/Messi/Vieira ground truth:

  A file (largest, no utf16 names) — one blob, four regions:
    - person records, VARIABLE length (~107-600B), core layout:
        +0 fname-idx u32, +4 sname-idx u32, +8 common-idx i32 (-1 = none),
        +12 DOB {u16 day0, u16 year}, +16 u8<=1, +17 nation u32,
        +21 city i32, +29 i32 == -1 (invariant), +36 u16 == 1900 (invariant),
        +38 club u32 (club-data id; -1/0 = none), +42 job u8 (bit0 = player),
        +43 joined-club date {u16 day0, u16 year, u8}, +48 person-id u32
      then TLVs (favourite clubs, second nations) and, for people with a career,
      the ABILITY BLOCK:
        [date 5B][pid u32][W u32][X u32][flag u8 1|2]
        [rep i16][rep i16][rep i16][CA i16][PA i16]     <- PA<0 = FM random-PA code
        flag==2 -> [attr u32 <n_players][-1 i32] ; flag==1 -> [u32][attr u32]
      Non-players (managers etc) have the same block shape (coach CA/PA) — the
      job byte at +42 is the player/staff discriminator.
    - non-player table (84B recs), player attr table (89B recs, id col @39),
      non-player attr table (43B recs).
  B file (most club-name hits) — language blocks of id+utf16-string tables:
    clubs, nations, cities, stadiums, injuries... First block = English.
  C file (names + linkage) — name sections plus club/nation DATA records that
    pair [data-id u32][name-id u32]; club pairs are followed by \\x0a\\x00.
  D file — clean name sections: first names / surnames / common names, record:
    [len u32][utf16][0000][type u16][nation u32][idx u32][D u32](+1 pad in some
    sections; the sliding scan below tolerates both).

Positions are NOT extracted: no position table was located yet (open item; the
Position column is left blank -> talent_ingest defaults to MF, curation fixes
the top rows). CA/PA, DOB, nation, club are exact.

Output (same schema as cmfm_extract.py):
  players_<season>.csv  Name,Club,Position,Nat,BirthYear,CA,PA,Season,Age (14..21)
  all_<season>.csv      every person with an ability block + a player job byte

Usage:
  python3 tools/fm0506_extract.py extracted/fm05/cab --season 2004-05
  python3 tools/fm0506_extract.py extracted/fm06/cab --season 2005-06
"""

from __future__ import annotations

import argparse
import csv
import struct
from pathlib import Path

MAGIC = b"\x02\x01tad."


# ---------------------------------------------------------------- file roles
def core_shift(data: bytes, off: int, variant: str) -> int | None:
    """Per-record offset of the DOB field relative to +12.

    fm05: DOB sits directly at +12 (shift 0). fm06 inserts an inline legal-name
    field at +12: [len u32][utf16 len*2][0000 if len>0] (len 0 = no terminator)
    -> shift 4 + 2*len (+2 when len > 0).
    Returns None if the record can't be a core under the given variant.
    """
    if variant == "fm05":
        return 0
    ln = struct.unpack_from("<I", data, off + 12)[0]
    if ln > 60:
        return None
    return 4 + 2 * ln + (2 if ln else 0)


def is_core(data: bytes, off: int, variant: str) -> int | None:
    """Validate a person core; returns the record's DOB shift or None."""
    s = core_shift(data, off, variant)
    if s is None or off + 60 + s > len(data):
        return None
    if struct.unpack_from("<i", data, off + 29 + s)[0] != -1:
        return None
    if struct.unpack_from("<H", data, off + 36 + s)[0] != 1900:
        return None
    fn, sn, cm = struct.unpack_from("<IIi", data, off)
    day, yr = struct.unpack_from("<HH", data, off + 12 + s)
    nat = struct.unpack_from("<I", data, off + 17 + s)[0]
    if (
        0 < fn < 300_000
        and 0 < sn < 300_000
        and (cm == -1 or 0 < cm < 2_100_000)
        and day <= 366
        and 1800 <= yr <= 2000
        and data[off + 16 + s] <= 1
        and 1 <= nat <= 400
    ):
        return s
    return None


def count_cores_sample(data: bytes, variant: str, limit: int = 6_000_000) -> int:
    n = min(len(data), limit)
    count = 0
    off = 0
    while off < n - 120:
        if is_core(data, off, variant) is not None:
            count += 1
            off += 90
            continue
        off += 1
    return count


def detect_roles(cabdir: Path) -> tuple[dict[str, Path], int]:
    """Classify payload files by content probes; returns roles + core-layout shift
    (FM2005: 0; FM2006 inserted a u32 after the common-name idx: 4)."""
    tad = []
    for f in cabdir.iterdir():
        if not f.is_file() or f.stat().st_size < 3_000_000:
            continue
        with f.open("rb") as fh:
            if fh.read(6) != MAGIC:
                continue
        tad.append(f)
    probe_boro = "Middlesbrough".encode("utf-16-le")
    club_pair = struct.pack("<II", 593, 680) + b"\x0a\x00"  # MU data-id + name-id
    b = c = None
    b_hits = -1
    for f in tad:
        data = f.read_bytes()
        hits = data.count(probe_boro)
        if hits > b_hits:
            b, b_hits = f, hits
        if club_pair in data:
            c = f
    if c is None:
        raise SystemExit("no file with club-data records (MU 593/680 pair) found")
    # A + variant: the file/variant with the most person cores in a sample
    best = (None, "", -1)
    for f in tad:
        data = f.read_bytes()
        for variant in ("fm05", "fm06"):
            n = count_cores_sample(data, variant)
            if n > best[2]:
                best = (f, variant, n)
    a, variant, _ = best
    # D: smallest file with >=3 big name sections
    d = None
    for f in sorted(tad, key=lambda x: x.stat().st_size):
        secs = [s for s in name_sections(scan_name_records(f.read_bytes())) if len(s) > 5000]
        if len(secs) >= 3:
            d = f
            break
    if d is None:
        raise SystemExit("no name-section file found")
    roles = {"A": a, "B": b, "C": c, "D": d}
    for k, f in roles.items():
        print(f"[roles] {k} = {f.name} ({f.stat().st_size:,}B)")
    print(f"[roles] core layout variant = {variant}")
    return roles, variant


# ---------------------------------------------------------------- name tables
def scan_name_records(data: bytes) -> list[tuple[int, int, str]]:
    """Sliding scan for [len u32][utf16][0000][typ u16][B u32][idx u32][D u32]."""
    out = []
    n = len(data)
    pos = 0
    while pos < n - 30:
        ln = data[pos] | (data[pos + 1] << 8)
        if 1 <= ln <= 39 and data[pos + 2] == 0 and data[pos + 3] == 0:
            e = pos + 4 + ln * 2
            if e + 16 <= n and data[e] == 0 and data[e + 1] == 0:
                raw = data[pos + 4 : e]
                if all(
                    raw[i + 1] <= 2 and (raw[i + 1] or raw[i] >= 0x20)
                    for i in range(0, len(raw), 2)
                ):
                    try:
                        nm = raw.decode("utf-16-le")
                    except UnicodeDecodeError:
                        nm = None
                    if nm:
                        typ, _b, idx, _d = struct.unpack_from("<HIII", data, e + 2)
                        if typ <= 120 and _b <= 500 and idx < 3_000_000:
                            out.append((pos, idx, nm))
                            pos = e + 2 + 14
                            continue
        pos += 1
    return out


def name_sections(recs: list[tuple[int, int, str]]) -> list[list[tuple[int, int, str]]]:
    """Split the record stream into sections at big idx drops."""
    sections = []
    cur = [recs[0]]
    for r in recs[1:]:
        if r[1] < cur[-1][1] - 1000:
            sections.append(cur)
            cur = [r]
        else:
            cur.append(r)
    sections.append(cur)
    return sections


def load_person_names(dfile: Path) -> tuple[dict, dict, dict]:
    """first / surname / common dicts = the three biggest sections by size class."""
    recs = scan_name_records(dfile.read_bytes())
    big = [s for s in name_sections(recs) if len(s) > 5000]
    big.sort(key=len)
    if len(big) < 3:
        raise SystemExit(f"expected >=3 name sections, got {len(big)}")
    common = {i: nm for _, i, nm in big[0]}  # smallest big section
    first = {i: nm for _, i, nm in big[-2]}
    sur = {i: nm for _, i, nm in big[-1]}  # biggest
    print(f"[names] first={len(first):,} sur={len(sur):,} common={len(common):,}")
    return first, sur, common


# ---------------------------------------------------------------- clubs/nations
def scan_id_strings(data: bytes) -> list[tuple[int, int, str]]:
    """B-file tables: [u32 id][len u32][utf16][0000] (+ id-less alias strings, skipped)."""
    out = []
    n = len(data)
    pos = 0
    while pos < n - 12:
        rid = struct.unpack_from("<I", data, pos)[0]
        if 0 < rid < 200_000:
            ln = struct.unpack_from("<I", data, pos + 4)[0]
            if 1 <= ln <= 60:
                e = pos + 8 + ln * 2
                if e + 2 <= n and data[e] == 0 and data[e + 1] == 0:
                    raw = data[pos + 8 : e]
                    if all(
                        raw[i + 1] <= 2 and (raw[i + 1] or raw[i] >= 0x20)
                        for i in range(0, len(raw), 2)
                    ):
                        try:
                            s = raw.decode("utf-16-le")
                        except UnicodeDecodeError:
                            s = None
                        if s and s.isprintable():
                            out.append((pos, rid, s))
                            pos = e + 2
                            continue
        pos += 1
    return out


def load_entity_maps(bfile: Path, cfile: Path) -> tuple[dict, dict]:
    """club-data-id -> club name; nation-data-id -> nation name."""
    rows = scan_id_strings(bfile.read_bytes())
    cdata = cfile.read_bytes()

    # English language block = the FIRST occurrence region of anchor strings.
    def anchor(nm: str) -> int:
        for p, _i, s in rows:
            if s == nm:
                return p
        raise SystemExit(f"anchor '{nm}' not in B file")

    mu_pos = anchor("Manchester United")
    eng_pos = anchor("England")

    # position-contiguous cluster (gap > 8KB = table boundary) containing the anchor
    def cluster_around(anchor_pos: int) -> dict[int, str]:
        sel = {}
        clusters = []
        cur = [rows[0]]
        for r in rows[1:]:
            if r[0] - cur[-1][0] > 8000:
                clusters.append(cur)
                cur = [r]
            else:
                cur.append(r)
        clusters.append(cur)
        for c in clusters:
            if c[0][0] <= anchor_pos <= c[-1][0]:
                for _p, i, s in c:
                    if i < 60_000 and i not in sel:
                        sel[i] = s
        return sel

    club_names = cluster_around(mu_pos)
    nat_names = {
        i: s for p, i, s in rows if abs(p - eng_pos) < 20_000 and i < 60_000 and s[:1].isupper()
    }

    club_map: dict[int, str] = {}
    for nid, nm in club_names.items():
        nb = struct.pack("<I", nid)
        p = -1
        while True:
            p = cdata.find(nb, p + 1)
            if p < 0:
                break
            if p >= 4 and cdata[p + 4 : p + 6] == b"\x0a\x00":
                did = struct.unpack_from("<I", cdata, p - 4)[0]
                if 0 < did < 60_000 and did not in club_map:
                    club_map[did] = nm
                    break

    # nation data region: locate via England + Brazil data records, then bounded scan
    def nat_pos(country: str, did: int) -> int:
        nid = next(i for i, s in nat_names.items() if s == country)
        pat = struct.pack("<II", did, nid)
        p = cdata.find(pat)
        if p < 0:
            raise SystemExit(f"nation data rec for {country} not found")
        return p

    lo = min(nat_pos("England", 139), nat_pos("Brazil", 189)) - 300_000
    hi = max(nat_pos("England", 139), nat_pos("Brazil", 189)) + 300_000
    nat_map: dict[int, str] = {}
    for nid, nm in nat_names.items():
        nb = struct.pack("<I", nid)
        p = max(0, lo)
        while True:
            p = cdata.find(nb, p + 1)
            if p < 0 or p > hi:
                break
            did = struct.unpack_from("<I", cdata, p - 4)[0]
            if 1 <= did <= 400 and cdata[p + 4] == 0 and did not in nat_map:
                adj = struct.unpack_from("<I", cdata, p + 7)[0]
                if 0 < adj < 60_000:
                    nat_map[did] = nm
                    break
    # FIFA-alphabetical gap ids the injuries-table collision hides (verified by
    # neighbours: 66 Kyrgyzstan<->68 Lebanon, 99 Costa Rica<->101 Dominica,
    # 139 England<->141 Faroe Islands)
    for did, nm in ((67, "Laos"), (100, "Cuba"), (120, "United States"), (140, "Estonia")):
        nat_map.setdefault(did, nm)
    print(f"[maps] clubs={len(club_map):,} nations={len(nat_map)}")
    return club_map, nat_map


# ---------------------------------------------------------------- persons
def scan_person_cores(data: bytes, variant: str) -> list[tuple[int, int]]:
    """All (offset, dob-shift) person cores; stops after a 2MB dry gap."""
    cores = []
    off = 0
    last_hit = 0
    n = len(data)
    while off < n - 120:
        if off - last_hit > 2_000_000 and cores:
            break
        s = is_core(data, off, variant)
        if s is not None:
            cores.append((off, s))
            last_hit = off
            off += 90
            continue
        off += 1
    print(f"[cores] {len(cores):,} persons ({cores[0][0]:,}..{cores[-1][0]:,})")
    return cores


def find_ability_block(data: bytes, off: int, nxt: int, n_players: int, pad: int):
    """Last [date 5B][pad][pid][W][X][flag][5xi16][attr...] match in the record span.

    pad = 0 (fm05) or 2 (fm06: two extra bytes between date and pid).
    """
    span = data[off:nxt]
    out = None
    for j in range(len(span) - 33 - pad):
        day, yr = struct.unpack_from("<HH", span, j)
        if not (day <= 366 and (yr == 1900 or 1930 <= yr <= 2010)):
            continue
        if span[j + 4] > 1:
            continue
        pid = struct.unpack_from("<I", span, j + 5 + pad)[0]
        if pid >= 300_000:
            continue
        flag = span[j + 17 + pad]
        if flag not in (1, 2):
            continue
        q = struct.unpack_from("<5h", span, j + 18 + pad)
        if not all(-100 <= v <= 250 for v in q):
            continue
        if not (0 < q[3] <= 250) or q[4] == 0 or q[4] > 250:
            continue
        a, b = struct.unpack_from("<ii", span, j + 28 + pad)
        if flag == 2:
            if not (0 <= a < n_players and b == -1):
                continue
        else:
            if not (0 <= b < n_players):
                continue
        out = (q[3], q[4])  # CA, PA
    return out


# ---------------------------------------------------------------- main
def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("cabdir", type=Path)
    ap.add_argument("--season", required=True, help="e.g. 2004-05")
    ap.add_argument("--max-age", type=int, default=21)
    ap.add_argument("--out-dir", type=Path, default=None, help="default: cabdir/..")
    args = ap.parse_args()

    outdir = args.out_dir or args.cabdir.parent
    season_start = int(args.season.split("-")[0])
    roles, variant = detect_roles(args.cabdir)
    block_pad = 0 if variant == "fm05" else 2
    first, sur, common = load_person_names(roles["D"])
    club_map, nat_map = load_entity_maps(roles["B"], roles["C"])

    data = roles["A"].read_bytes()
    cores = scan_person_cores(data, variant)
    # player-attr table size: the id column walk is not needed for extraction,
    # only a plausible upper bound for attr-idx validation
    n_players = 260_000

    rows = []
    no_block = 0
    for i, (off, s) in enumerate(cores):
        if data[off + 42 + s] & 1 != 1:  # staff
            continue
        nxt = cores[i + 1][0] if i + 1 < len(cores) else off + 600
        fn, sn, cm = struct.unpack_from("<IIi", data, off)
        day, yr = struct.unpack_from("<HH", data, off + 12 + s)
        nat = struct.unpack_from("<I", data, off + 17 + s)[0]
        club = struct.unpack_from("<I", data, off + 38 + s)[0]
        blk = find_ability_block(data, off + 52 + s, nxt, n_players, block_pad)
        if blk is None:
            no_block += 1
            continue
        ca, pa = blk
        nm = common.get(cm) if cm != -1 else None
        if not nm:
            f, s = first.get(fn), sur.get(sn)
            if not f or not s:
                continue
            nm = f"{f} {s}"
        rows.append(
            {
                "Name": nm,
                "Club": club_map.get(club, ""),
                "Position": "",
                "Nat": nat_map.get(nat, str(nat)).upper(),
                "BirthYear": yr,
                "CA": ca,
                "PA": pa,
                "Season": args.season,
                "Age": season_start - yr,
            }
        )
    print(f"[rows] {len(rows):,} players with ability block ({no_block:,} players without)")

    young = [r for r in rows if 14 <= r["Age"] <= args.max_age]
    young.sort(key=lambda r: (-(r["PA"] if r["PA"] > 0 else 170 + 10 * r["PA"] / 10), r["Name"]))
    print(f"[rows] {len(young):,} aged 14-{args.max_age} in {args.season}")

    def write(path: Path, rws: list[dict]) -> None:
        with path.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rws[0].keys()))
            w.writeheader()
            w.writerows(rws)
        print(f"[out] {path} ({len(rws):,} rows)")

    write(outdir / f"all_{args.season}.csv", rows)
    write(outdir / f"players_{args.season}.csv", young)

    top = sorted((r for r in young if r["PA"] > 0), key=lambda r: -r["PA"])[:15]
    print("\nTop-15 fixed-PA young (spot-check these):")
    for r in top:
        print(
            f"  PA{r['PA']:3d} CA{r['CA']:3d} {r['Name']} b.{r['BirthYear']} {r['Club']} [{r['Nat']}]"
        )
    negs = sorted((r for r in young if r["PA"] < 0), key=lambda r: r["PA"])[:8]
    print("Most-negative random-PA young:")
    for r in negs:
        print(
            f"  PA{r['PA']:3d} CA{r['CA']:3d} {r['Name']} b.{r['BirthYear']} {r['Club']} [{r['Nat']}]"
        )


if __name__ == "__main__":
    main()
