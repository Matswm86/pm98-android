#!/usr/bin/env python3
"""Import a FULL frame-0 memory dump of a real MANAGER.EXE match into the port's
match-struct shape (docs/re/PLAN_byte_exact_match_engine.md M5).

Reads a `dump_mem.py full` output dir (regions/*.bin + a match base) and materialises
the match struct the way Pm98Match.build_match / _build_player / kickoff_init model it:
byte-offset-keyed scalars for the match, plus the 22 player records (following the
team[0]=player-array pointer), the ball, keepers, referee, and the session object
(following match+0x468). Every field is READ FROM THE DUMP -- nothing is computed.

Unlike the earlier single-region capture, a `full` dump contains the player region
(team0/team1 arrays live on the heap, NOT inside the match struct) and the session
region, so this can follow those pointers.

Usage:
  m4_struct_import.py <dumpdir> <match_base_hex> [out.json]
     <dumpdir> holds regions/<lo>-<hi>.bin (from dump_mem.py full).

Output JSON: {"match": {...scalars...}, "session": {...}, "players": [[team0 x11],[team1 x11]],
              "ball": {...}, "keepers": [...], "referee": {...}, "meta": {...}}
Player dicts carry BOTH the decoded engine fields (keyed by the port's byte offsets)
and a "dwords" full image (offset->dword) so no field is lost.
"""
import glob
import json
import os
import struct
import sys

PLAYER_STRIDE = 0x3BC


class MemImage:
    """VA-addressable view over a set of region dump files."""

    def __init__(self, dumpdir: str):
        self.regions = []  # (lo, hi, path)
        rdir = os.path.join(dumpdir, "regions")
        for f in sorted(glob.glob(os.path.join(rdir, "*.bin"))):
            base = os.path.basename(f)[:-4]
            lo, hi = (int(x, 16) for x in base.split("-"))
            self.regions.append((lo, hi, f))
        self._cache = {}

    def _region(self, va: int):
        for lo, hi, f in self.regions:
            if lo <= va < hi:
                return lo, hi, f
        return None

    def read(self, va: int, n: int) -> bytes:
        r = self._region(va)
        if r is None:
            raise KeyError(f"VA 0x{va:08x} unmapped in dump")
        lo, hi, f = r
        if f not in self._cache:
            with open(f, "rb") as fh:
                self._cache[f] = fh.read()
        data = self._cache[f]
        off = va - lo
        if off + n > len(data):
            raise KeyError(f"VA 0x{va:08x}+{n} runs past region {f}")
        return data[off:off + n]

    def u32(self, va: int) -> int:
        return struct.unpack("<I", self.read(va, 4))[0]

    def i32(self, va: int) -> int:
        v = self.u32(va)
        return v - 0x100000000 if v >= 0x80000000 else v

    def u16(self, va: int) -> int:
        return struct.unpack("<H", self.read(va, 2))[0]

    def u8(self, va: int) -> int:
        return self.read(va, 1)[0]

    def has(self, va: int) -> bool:
        return self._region(va) is not None


# --- match scalar offsets the port's Pm98Outer/Driver/Dispatch/kickoff_init read.
# (value == the dword at that offset; a few are logically bytes but stored dword-wide.)
MATCH_SCALARS = [
    0x0, 0x448, 0x44c, 0x450, 0x454, 0x458, 0x45c, 0x464, 0x468,
    0x1804, 0x1808, 0x1809, 0x180a, 0x180b, 0x180c, 0x180d, 0x180e,
    0x1810, 0x1814, 0x1818, 0x181e, 0x1820, 0x1824,
    0x1828, 0x182c, 0x1830, 0x1834, 0x1838, 0x183c, 0x1840,
    0x1940, 0x194c, 0x1950, 0x1954, 0x1958, 0x195c, 0x1960, 0x1964, 0x1968,
    0x196c, 0x1970, 0x1974, 0x1978, 0x197c, 0x1984, 0x1988, 0x198c, 0x1990,
    0x199c, 0x19a0, 0x19a4, 0x19a8, 0x19ac, 0x19b0, 0x19b4, 0x19b8,
    0x19c0, 0x19c4, 0x19c8, 0x19d0, 0x19e0, 0x19e4, 0x19e8, 0x19ec, 0x19f0,
    0x19f4, 0x19f8, 0x19fc, 0x1a00,
    0x1a18, 0x1a19, 0x1a1b, 0x1a1c, 0x1a1d, 0x1a1e, 0x1a20,
    0x1a2c, 0x1a30, 0x1a38, 0x1a3c, 0x1a40, 0x1a5c,
    0x478, 0x798,  # team score copies (team0/team1 +0xc)
    0x758, 0xa78,  # team0/team1 +0x2ec read FLAT by the goal-draw gate (Pm98Driver L399)
]

# --- player engine fields _build_player writes (offset -> width in bytes). The
# importer reads each at its native width so byte flags stay 0/1 like the port.
PLAYER_FIELDS = {
    0x4: 4, 0x8: 4, 0xc: 4,            # actual position
    0x2c: 4, 0x30: 4, 0x34: 2,         # kick-gate counter / facing (s16)
    0x54: 4, 0x58: 4,                  # ball-control state / prev
    0x63: 1,                           # byte
    0x70: 4, 0x74: 4, 0x78: 4,         # speed-ish (0x1c/0x1d/0x1e)
    0x184: 4, 0x188: 4, 0x18c: 4, 0x190: 4,   # own hdr / opp hdr / match / ball ptrs
    0x1f8: 4, 0x1fc: 4, 0x200: 4, 0x204: 4, 0x208: 4, 0x20c: 4,  # start pos
    0x228: 4, 0x22c: 4, 0x230: 4, 0x234: 4,                      # roam box
    0x2b8: 4, 0x2bc: 4, 0x2c0: 4, 0x2c4: 4, 0x2c8: 4, 0x2cc: 4,  # team/slot/id/idx/role
    0x2d0: 4, 0x2d5: 1, 0x2d6: 1, 0x2d9: 1, 0x2da: 1, 0x2dc: 4,  # fitness/flags/captain
    0x36c: 4, 0x370: 4,
    0x378: 4, 0x37c: 4, 0x380: 4, 0x384: 4, 0x388: 4, 0x38c: 4,  # stat block 0xde..
    0x390: 4, 0x394: 4, 0x398: 4, 0x39c: 4, 0x3a0: 4, 0x3a8: 4, 0x3ac: 4,
}


def read_player(mem: MemImage, va: int) -> dict:
    p = {"_va": "0x%08x" % va}
    for off, w in PLAYER_FIELDS.items():
        rd = {1: mem.u8, 2: mem.u16, 4: mem.u32}[w]
        p["0x%x" % off] = rd(va + off)
    # full dword image of the 0x3bc record (nothing lost)
    raw = mem.read(va, PLAYER_STRIDE)
    p["dwords"] = {"0x%x" % o: struct.unpack_from("<I", raw, o)[0]
                   for o in range(0, PLAYER_STRIDE - 3, 4)}
    return p


def read_team_players(mem: MemImage, base: int, team_off: int) -> list:
    arr = mem.u32(base + team_off)          # team[0] = player-array base pointer
    cnt = mem.u32(base + team_off + 4)      # team[4] = count
    return [read_player(mem, arr + i * PLAYER_STRIDE) for i in range(cnt)]


# session fields the port's kickoff_init / Dispatch consume.
SESSION_FIELDS = [0x14, 0x18, 0x44, 0x48, 0x4c, 0x50, 0x54, 0x58, 0x64,
                  0xfa0, 0xfd0, 0xfd4, 0xfd8, 0xfdc, 0xfe8, 0xfec, 0xff0, 0xff4]


def _resolve_idx(va: int, arr: int, cnt: int):
    """Map a team-header slot pointer (VA of a player record) to its index in this
    team's player array (base=arr, stride 0x3bc). None for a null slot; a raw-VA dict
    for a pointer that does not land in the array (should not occur at frame-0)."""
    if va == 0:
        return None
    if arr and (va - arr) % PLAYER_STRIDE == 0:
        i = (va - arr) // PLAYER_STRIDE
        if 0 <= i < cnt:
            return i
    return {"_va": "0x%08x" % va}


def read_team_header(mem: MemImage, base: int, team_off: int) -> dict:
    """The two TEAM HEADERS (match+0x46c team0 / +0x78c team1). Emits the word-indexed
    pointer tables (_build_team writes team[0x4f+slot] active table, team[0x5b+k] role
    table, team[0xbf..0xc7] squad header) as RESOLVED PLAYER INDICES so the port loader
    can wire GDScript object refs, plus the header scalars the builder/consumers read.
    Every value is READ FROM THE DUMP -- nothing computed."""
    hv = base + team_off
    arr = mem.u32(hv)          # word 0 = player-array base
    cnt = mem.u32(hv + 4)      # word 1 = count
    return {
        "_va": "0x%08x" % hv,
        "off": "0x%x" % team_off,
        "arr_base": "0x%08x" % arr,
        "count": cnt,
        "score_0xc": mem.u32(hv + 0xc),                        # team[0xc] == flat m+0x478
        "active_idx_0x168": mem.u32(hv + 0x168),               # team[0x168] (word 0x5a)
        # word-indexed pointer tables -> player index in THIS team (or None):
        "active_table": [_resolve_idx(mem.u32(hv + (0x4f + s) * 4), arr, cnt)
                         for s in range(11)],                  # team[0x4f+slot]
        "role_table": [_resolve_idx(mem.u32(hv + (0x5b + k) * 4), arr, cnt)
                       for k in range(0x24)],                  # team[0x5b+k] (0x24 entries)
        "squad_header": [mem.u32(hv + (0xbf + k) * 4) for k in range(9)],  # team[0xbf..0xc7]
        # header scalars: 0x2e0 rel-matrix throttle (word 0xb8), 0x2ec/0x2ed byte flags,
        # 0x208 sub-obj ptr (informational, not wired), 0x20c.
        "0x2e0": mem.u32(hv + 0x2e0),
        "0x2ec": mem.u8(hv + 0x2ec),
        "0x2ed": mem.u8(hv + 0x2ed),
        "0x208": mem.u32(hv + 0x208),
        "0x20c": mem.u32(hv + 0x20c),
    }


def read_body(mem: MemImage, va: int, size: int) -> dict:
    """A sub-entity BODY (ball @+0x1610, keepers @+0xaac/+0xe74, referee @+0x123c) as a
    full dword image. These are RE-PLACED by the step-1 restart (ball_restart_decide /
    keeper_restart_decide), so the loader keeps the byte-exact ctor objects from
    build_match and does NOT byte-substitute the interior; the image is emitted for
    fidelity/inspection (vtable + any frame-0 field a future loader may want)."""
    raw = mem.read(va, size)
    return {
        "_va": "0x%08x" % va,
        "vtable": "0x%x" % struct.unpack_from("<I", raw, 0)[0],
        "size": size,
        "dwords": {"0x%x" % o: struct.unpack_from("<I", raw, o)[0]
                   for o in range(0, size - 3, 4)},
    }


def main() -> None:
    dumpdir = sys.argv[1]
    base = int(sys.argv[2], 16)
    out = sys.argv[3] if len(sys.argv) > 3 else os.path.join(dumpdir, "struct_import.json")
    mem = MemImage(dumpdir)

    assert mem.u32(base) == 0x6390E0, "match vtable mismatch at base"
    match = {"0x%x" % o: mem.u32(base + o) for o in MATCH_SCALARS if mem.has(base + o)}

    players = [read_team_players(mem, base, 0x46c),
               read_team_players(mem, base, 0x78c)]

    sess_va = mem.u32(base + 0x468)
    session = {}
    if mem.has(sess_va):
        session = {"_va": "0x%08x" % sess_va}
        for o in SESSION_FIELDS:
            if mem.has(sess_va + o):
                session["0x%x" % o] = mem.u32(sess_va + o)

    team_headers = [read_team_header(mem, base, 0x46c),
                    read_team_header(mem, base, 0x78c)]

    result = {
        "meta": {
            "match_base": "0x%08x" % base,
            "ball_va": "0x%08x" % (base + 0x1610),
            "seed_0x6d3184": mem.u32(0x6D3184) if mem.has(0x6D3184) else None,
            "stride": PLAYER_STRIDE,
        },
        "match": match,
        "session": session,
        "team_headers": team_headers,
        "players": players,
        "ball": read_body(mem, base + 0x1610, 0x200),
        "keepers": [read_body(mem, base + 0xaac, PLAYER_STRIDE + 4),
                    read_body(mem, base + 0xe74, PLAYER_STRIDE + 4)],
        "referee": read_body(mem, base + 0x123c, PLAYER_STRIDE + 4),
    }
    with open(out, "w") as f:
        json.dump(result, f, indent=1)
    print("wrote %s" % out)
    print("  match scalars: %d  players: %d+%d  session: %s"
          % (len(match), len(players[0]), len(players[1]),
             "yes" if session else "MISSING"))
    for ti, h in enumerate(team_headers):
        act = sum(1 for x in h["active_table"] if isinstance(x, int))
        rol = sum(1 for x in h["role_table"] if isinstance(x, int))
        print("  team%d hdr: count=%d active_tbl=%d/11 role_tbl=%d  0x2ec=%d 0xc7=0x%x"
              % (ti, h["count"], act, rol, h["0x2ec"], h["squad_header"][8]))
    print("  seed_0x6d3184: 0x%08x" % result["meta"]["seed_0x6d3184"])


if __name__ == "__main__":
    main()
