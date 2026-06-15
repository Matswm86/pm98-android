#!/usr/bin/env python3
"""PCF5 .PKF container parser — reversed from MANAGER.EXE (Premier Manager 98).

The archive directory is a sequential stream of tag-tagged records, decoded by
FUN_005e81c0 (0x5e81c0). Each record starts with one tag byte; `tag & 7` selects
the record type, `tag & 0x80` flags a "compressed/region" entry (it changes how the
engine *stores* the entry but NOT how many bytes the directory reader consumes, so
parsing is flag-independent). Names are a fixed 20-byte field XOR-obfuscated by
FUN_005e6500 (0x5e6500): name[i] ^= ((i-0x21)*(i+1)) & 0xFF.

Record layout (bytes consumed AFTER the tag byte), verified against the byte reads
in FUN_005e81c0 + helpers FUN_005e6490 (20-byte name) / FUN_005e87b0 (8) / FUN_005f9a70:
  type 1  : name[20] + u32 + u32                         (folder/group header)
  type 2  : name[20] + u8 + u16 + u16 + u32 off + u32 size + u32 flag   (FILE entry)
  type 3  : u32 off + u32 size                           (raw block, unnamed)
  type 4  : u32 -> SEEK absolute (directory continuation / skip past a data region)
  type 5  : END of directory
Anything else = corrupt / wrong start offset (engine raises error 0xC).

The three type-2 u32s are (offset, size, flag): payloads are stored CONTIGUOUS and
UNCOMPRESSED (offset[i] + size[i] == offset[i+1], verified on DAT.PKF). So extracting
an entry is a pure slice buf[off:off+size]; the container applies no compression
(the high whole-file entropy is just already-encoded payloads: .IND/.PAL/.BRT/.PGF).
Usage: pkf_unpack.py                      # parse + summarize all PKFs
       pkf_unpack.py --extract OUT [F...]  # extract entries to OUT/<pkf>/<name>
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parents[2] / "extracted" / "Premier Manager 98"


def deobf_name(b: bytes) -> bytes:
    """FUN_005e6500: XOR the 20-byte name field in place."""
    return bytes((b[i] ^ (((i - 0x21) * (i + 1)) & 0xFF)) for i in range(len(b)))


def _name_str(raw20: bytes) -> str:
    d = deobf_name(raw20)
    end = d.find(b"\x00")
    return d[: end if end >= 0 else 20].decode("latin1", "replace")


def parse(buf: bytes, max_records: int = 100000):
    """Walk the directory stream. Yields dicts; stops on END/EOF/corrupt."""
    pos = 0
    n = len(buf)
    count = 0
    while pos < n and count < max_records:
        count += 1
        rec_start = pos
        tag = buf[pos]
        pos += 1
        t = tag & 7
        flag = bool(tag & 0x80)
        if t == 1:
            if pos + 28 > n:
                yield {"err": "truncated type1", "at": rec_start}
                return
            name = _name_str(buf[pos : pos + 20])
            a, b = struct.unpack_from("<II", buf, pos + 20)
            pos += 28
            yield {"type": 1, "at": rec_start, "tag": tag, "flag": flag, "name": name, "u32a": a, "u32b": b}
        elif t == 2:
            if pos + 37 > n:
                yield {"err": "truncated type2", "at": rec_start}
                return
            name = _name_str(buf[pos : pos + 20])
            b8 = buf[pos + 20]
            w1, w2 = struct.unpack_from("<HH", buf, pos + 21)
            d1, d2, d3 = struct.unpack_from("<III", buf, pos + 25)
            pos += 37
            yield {"type": 2, "at": rec_start, "tag": tag, "flag": flag, "name": name,
                   "u8": b8, "w1": w1, "w2": w2, "u32s": (d1, d2, d3)}
        elif t == 3:
            if pos + 8 > n:
                yield {"err": "truncated type3", "at": rec_start}
                return
            off, size = struct.unpack_from("<II", buf, pos)
            pos += 8
            yield {"type": 3, "at": rec_start, "tag": tag, "flag": flag, "off": off, "size": size}
        elif t == 4:
            if pos + 4 > n:
                yield {"err": "truncated type4", "at": rec_start}
                return
            (target,) = struct.unpack_from("<I", buf, pos)
            pos += 4
            yield {"type": 4, "at": rec_start, "tag": tag, "seek": target}
            pos = target  # absolute seek (FUN_005f9ae0 mode 0)
        elif t == 5:
            yield {"type": 5, "at": rec_start, "tag": tag, "end": True}
            return
        else:
            yield {"err": f"bad tag {tag:#x} (type {t})", "at": rec_start}
            return


def files_of(buf: bytes):
    """Yield (name, off, size) for every type-2 FILE entry in directory order."""
    for r in parse(buf):
        if "err" in r:
            return
        if r.get("type") == 2:
            off, size, _flag = r["u32s"]
            yield r["name"], off, size
        if r.get("end"):
            return


def summarize(fn: str, buf: bytes) -> None:
    print(f"\n### {fn}  ({len(buf):,} bytes)")
    counts: dict = {}
    names, entries = [], []
    for r in parse(buf):
        if "err" in r:
            print(f"  STOP @ {r['at']:#x}: {r['err']}")
            break
        counts[r["type"]] = counts.get(r["type"], 0) + 1
        if r["type"] in (1, 2):
            names.append(r["name"])
        if r["type"] == 2:
            entries.append(r["u32s"])
        if r.get("end"):
            break
    print(f"  record counts by type: {counts}")
    if names:
        print(f"  {len(names)} named entries; first 12: {names[:12]}")
    if entries:
        offs = [(o, s) for o, s, _ in entries]
        inb = sum(1 for o, s in offs if o + s <= len(buf))
        contig = sum(1 for i in range(len(offs) - 1) if offs[i][0] + offs[i][1] == offs[i + 1][0])
        print(f"  {len(offs)} file payloads, {inb}/{len(offs)} within bounds, "
              f"{contig}/{max(1, len(offs) - 1)} contiguous (uncompressed concat)")


def extract(fn: str, buf: bytes, outroot: Path) -> None:
    out = outroot / fn
    out.mkdir(parents=True, exist_ok=True)
    n = ok = 0
    for name, off, size in files_of(buf):
        n += 1
        if off + size > len(buf):
            print(f"  SKIP {name}: off {off}+{size} > file")
            continue
        safe = name.replace("\\", "_").replace("/", "_").strip() or f"entry_{n}"
        (out / safe).write_bytes(buf[off : off + size])
        ok += 1
    print(f"  {fn}: extracted {ok}/{n} entries to {out}")


def main():
    args = sys.argv[1:]
    if args and args[0] == "--extract":
        outroot = Path(args[1])
        files = args[2:] or ["DAT.PKF", "DATSIM.PKF", "IMG.PKF", "RECURSOS.PKF"]
        for fn in files:
            p = GAME / fn
            if p.exists():
                extract(fn, p.read_bytes(), outroot)
            else:
                print(f"### {fn}: NOT FOUND")
        return
    files = args or ["DAT.PKF", "DATSIM.PKF", "IMG.PKF", "RECURSOS.PKF"]
    for fn in files:
        p = GAME / fn
        if p.exists():
            summarize(fn, p.read_bytes())
        else:
            print(f"\n### {fn}: NOT FOUND at {p}")


if __name__ == "__main__":
    main()
