#!/usr/bin/env python3
"""Bake JUG.PGF + the whole per-club KIT RECOLOUR chain, exactly as MANAGER.EXE does it.

This replaces the earlier two-layer `jug_base.png` / `jug_kit.png` bake, which pre-baked ONE
stylised colouring picked off the art's own histogram. The original never colours the sprite
at bake time at all: it keeps JUG.PGF as 8-bit PALETTE INDICES and remaps them per player
through a 256-byte LUT just before the blit (`FUN_005d34a0`). Everything that builds that LUT
is now reversed, so the app can do the same and the kit is the club's real kit.

The chain, every step read out of the binary (`docs/re/kit_palette_re.md` carries the full
write-up and the VAs):

  1. `FUN_005b63e0` (per team, at match load) reads `DatSim\\paletas\\P96A<clubid>.DAT` —
     192 bytes — falling back to `P96A0000.DAT`. If this is the AWAY side and its class byte
     equals the home side's, it reads `P96B<clubid>.DAT` instead: the CHANGE STRIP.
       bytes [0..127]   the 16x8 SHIRT PATTERN grid, each cell a palette RAMP BASE index
       bytes [128..175] 48 LUT entries, copied to palette slots 9..56
       byte  [176]      the kit CLASS colour (`team+0x2d6`), also the number patch background
     `team+0x2d8` (the number ink) is `0x67` when the class colour's GREEN component in the
     match palette exceeds 100, else `0x7f`.
  2. `FUN_005a2830` (per player) points him at `paltab + ti*0x200 + (slot==0 ? 0x100 : 0)` —
     the keeper gets the `palpor%d` palette instead — copies the team's 128-byte pattern to
     `player+0x2e0`, stamps his SHIRT NUMBER into the pattern's right half out of the 8x8
     `NumCam.bmp` glyph bank, and resolves his SKIN ramp (`DAT_006653a8`, 3 x 8 entries,
     picked by `.DBC +0x16`) and HAIR ramp (`DAT_00665380`, 4 entries, picked by `.DBC +0x17`,
     where index 1 means BALD and redirects to `skin + 6`).
  3. `FUN_005a5460` (per draw) writes skin into LUT[1..8], hair into LUT[0x15..0x18], then
     walks the pattern grid: for each (col, row, shade) it looks up
     `JUGCAM.IND[(row + (frame.h5*16 + col)*8)*6 + shade]` and, when non-zero, writes
     `ramp(pattern[row*16+col], shade)` into that LUT slot.

`JUGCAM.IND` is therefore NOT a camera table (the name misled the earlier spec): it is the
shirt-texture -> sprite-palette-index map, **72 maps x 16 cols x 8 rows x 6 shades = 55,296
bytes, which is the file's exact size**. `frame.h5` — the `.PGF` header word the spec listed
as an open GAP — is the map index, and it spans exactly 0..71.

Output (`app/art/match/`):
  jug_index.bin   every frame's 8-bit palette indices, packed contiguously at its OWN
                  visible width `h0` (the `.PGF` stores rows at stride `h4` >= `h0`; the
                  columns past `h0` are blank in all 4211 frames, verified)
  jug_bank.json   {kinds, frames:[{off,w,h,ax,ay,map}], thresholds, ramps, scale constants}
  jugcam.bin      JUGCAM.IND verbatim
  kitpal.bin      829 P96A + 829 P96B + the 256-byte P96A0000 base LUT + the 8 palpor LUTs
  simulpal.bin    SIMUL0..4.PAL (the five pitch palettes; entry N is picked by an RNG draw)
  numcam.bin      NumCam.bmp's 60 8x8 shirt-number glyphs, top-down

Usage:  python3 tools/re/pkf_unpack.py --extract /tmp/datsim_out
        python3 tools/re/export_jug_bank.py
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pe import PE  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "app" / "art" / "match"
UNPACK = Path("/tmp/datsim_out")
DATSIM = UNPACK / "DATSIM.PKF"
DAT = UNPACK / "DAT.PKF"

# VAs verified from FUN_005a5460 / FUN_005a50c0 / FUN_005a2830 (dump_jug_kind_tables.py).
VA_MODE = 0x6650E0
VA_FPD = 0x664FB8
VA_NEXT = 0x665208
VA_FLAG = 0x665330
VA_THR8 = 0x6653E0
VA_THR12 = 0x665430
# The two per-octant tilt tables the sub-octant refine block indexes (FUN_005a5460:222-230).
VA_TILT_POS = 0x6653F0
VA_TILT_NEG = 0x665410
# FUN_005a2830: the three 8-entry SKIN ramps and the ten 4-entry HAIR ramps.
VA_SKIN = 0x6653A8
VA_HAIR = 0x665380
# FUN_005a5460's two special-cased pattern colours: 0x7f (white) and 0x67 (grey) are points on
# the linear grey band, not 6-step colour bands, so they carry their own ramp tables.
VA_RAMP_WHITE = 0x6654B0
VA_RAMP_GREY = 0x6654A8
# FUN_005b63e0's keeper-strip table: the RNG draws 0..7, `palpor<N>.DAT` is the LUT and this
# table is that strip's CLASS colour, which the re-roll loop compares against the outfield kits.
VA_KEEPER_CLASS = 0x6657B0

N_KINDS = 74
JUG_FRAMES = 4211
N_CLUB_RAMPS = 829  # P96A0001..P96A0829 / P96B0001..P96B0829
RAMP_BYTES = 192
JUGCAM_BYTES = 72 * 16 * 8 * 6  # = 55296, the file's exact size
N_PALPOR = 8

# Sprite world scale, read off the draw: a frame's z span is (ay-H .. ay) * 0x1b333 / 0x30
# and its x span (-ax .. W-ax) * scale, both /0x1a on the way into world coords.
Z_NUM, Z_DEN = 0x1B333, 0x30
X_DEN = 0x1A


def pgf_frames(path: Path):
    """Decode an `LFGP` bank.

    On disk each frame is a 4-byte tag then `[h0, h1, h2, h3, h4, h5]`, and the parser
    `FUN_005caae0` binds them: `h0` -> the surface WIDTH, `h1` -> its height (the row count it
    copies), `h2`/`h3` -> the anchor pair it stores at slot `+0x38`/`+0x3c`, `h4` -> the SOURCE
    row stride it advances by, `h5` -> slot `+0x10`, which `FUN_005a5460` uses as the JUGCAM
    map index. Pixels are `h4 * h1` bytes.
    """
    b = path.read_bytes()
    if b[:4] != b"LFGP":
        raise SystemExit(f"{path}: not an LFGP bank")
    cnt = struct.unpack("<I", b[4:8])[0]
    off, out = 8, []
    for _ in range(cnt):
        h0, hh, ax, ay, stride, hmap = struct.unpack("<6i", b[off + 4 : off + 28])
        out.append(
            {
                "w": h0,
                "stride": stride,
                "h": hh,
                "ax": ax,
                "ay": ay,
                "map": hmap,
                "px": b[off + 28 : off + 28 + stride * hh],
            }
        )
        off += 28 + stride * hh
    if off != len(b):
        raise SystemExit(f"{path}: {off} bytes consumed of {len(b)} — layout wrong")
    return out


def kind_tables(pe: PE):
    def i32s(va, n):
        return list(struct.unpack_from(f"<{n}i", pe.read_va(va, 4 * n), 0))

    def u16s(va, n):
        return list(struct.unpack_from(f"<{n}H", pe.read_va(va, 2 * n), 0))

    mode = i32s(VA_MODE, N_KINDS)
    fpd = i32s(VA_FPD, N_KINDS)
    nxt = i32s(VA_NEXT, N_KINDS)
    flag = list(pe.read_va(VA_FLAG, N_KINDS))
    # FUN_005a2830: base[k] = running; if mode[k] > 0: running += fpd[k] * mode[k]
    base, run = [], 0
    for k in range(N_KINDS):
        base.append(run)
        if mode[k] > 0:
            run += fpd[k] * mode[k]
    if run != JUG_FRAMES:
        raise SystemExit(f"base[] total {run} != JUG.PGF {JUG_FRAMES} — table VAs wrong")
    return {
        "kinds": [
            {"mode": mode[k], "fpd": fpd[k], "base": base[k], "next": nxt[k], "flag": flag[k]}
            for k in range(N_KINDS)
        ],
        "thresholds8": u16s(VA_THR8, 8),
        "thresholds12": u16s(VA_THR12, 12),
        "tilt_pos": i32s(VA_TILT_POS, 8),
        "tilt_neg": i32s(VA_TILT_NEG, 8),
        "skin_ramp": list(pe.read_va(VA_SKIN, 24)),
        "hair_ramp": list(pe.read_va(VA_HAIR, 40)),
        "ramp_white": list(pe.read_va(VA_RAMP_WHITE, 6)),
        "ramp_grey": list(pe.read_va(VA_RAMP_GREY, 6)),
    }


def _pal_entries(raw: bytes) -> list[int]:
    """A RIFF `PAL ` chunk's 256 RGBQUADs start at 0x18; keep RGB, drop the pad byte."""
    if raw[:4] != b"RIFF" or raw[8:12] != b"PAL ":
        raise SystemExit("not a RIFF PAL")
    out = []
    for i in range(256):
        out += list(raw[0x18 + i * 4 : 0x18 + i * 4 + 3])
    return out


def _club_ramp_map(ids: list[int]) -> dict[str, int]:
    """career club id -> ramp slot, through the club's own EQ96 crest code.

    `FUN_005b63e0` builds the ramp name from `lineup+0x790`, the club's EQ96 key — the SAME
    key it uses two lines later for `DBDat\\MiniEsc\\EQ96####` and `DBDat\\RidiEsc\\EQ96####`.
    `assets/crest_codes.json` already carries that decode (`tools/re/map_crests.py`), so the
    mapping is taken from there rather than re-derived. A club whose key has no ramp file is
    simply absent here and the app falls back to `P96A0000.DAT`, which is the engine's own
    `FUN_005ec1d0` miss branch.
    """
    src = ROOT / "assets" / "crest_codes.json"
    if not src.exists():
        raise SystemExit(f"{src} missing — run tools/re/map_crests.py first")
    codes = json.loads(src.read_text())
    slot = {cid: i for i, cid in enumerate(ids)}
    out: dict[str, int] = {}
    for group in ("english", "foreign"):
        for club_id, code in (codes.get(group) or {}).items():
            key = int(code)
            if key in slot:
                out[str(club_id)] = slot[key]
    return out


def numcam_glyphs(path: Path) -> bytes:
    """`DatSim\\NumCam.bmp` is 8x480 8-bit: 60 shirt-number glyphs of 8x8, one per number.

    BMPs store rows bottom-up, and `FUN_005c9f60` hands the engine a top-down surface, so the
    bank is flipped here once. `FUN_005a2830` then indexes it as `pixels + (number-1)*0x40`.
    """
    b = path.read_bytes()
    (off,) = struct.unpack_from("<I", b, 10)
    w, h, _planes, bpp = struct.unpack_from("<iiHH", b, 18)
    if (w, h, bpp) != (8, 480, 8):
        raise SystemExit(f"NumCam.bmp is {w}x{h}@{bpp}, expected 8x480@8")
    stride = (w * bpp // 8 + 3) // 4 * 4
    rows = [b[off + y * stride : off + y * stride + w] for y in range(h)]
    rows.reverse()  # bottom-up -> top-down
    return b"".join(rows)


def main() -> int:
    if not DATSIM.exists() or not DAT.exists():
        raise SystemExit(f"extract the PKFs first: python3 tools/re/pkf_unpack.py --extract {UNPACK}")
    OUT.mkdir(parents=True, exist_ok=True)
    pe = PE()
    tables = kind_tables(pe)
    frames = pgf_frames(DATSIM / "JUG.PGF")
    if len(frames) != JUG_FRAMES:
        raise SystemExit(f"JUG.PGF has {len(frames)} frames, expected {JUG_FRAMES}")

    # --- the index bank -------------------------------------------------------------------
    blob = bytearray()
    rows = []
    for f in frames:
        if f["w"] > f["stride"]:
            raise SystemExit("frame visible width exceeds its stored stride")
        off = len(blob)
        for y in range(f["h"]):
            line = f["px"][y * f["stride"] : y * f["stride"] + f["stride"]]
            if any(line[f["w"] :]):
                raise SystemExit("ink beyond the frame's own width — h0 is not the width")
            blob += line[: f["w"]]
        rows.append(
            {"off": off, "w": f["w"], "h": f["h"], "ax": f["ax"], "ay": f["ay"], "map": f["map"]}
        )
    maps = {r["map"] for r in rows}
    if min(maps) < 0 or max(maps) > 71:
        raise SystemExit(f"frame map index out of the JUGCAM range: {min(maps)}..{max(maps)}")
    (OUT / "jug_index.bin").write_bytes(bytes(blob))

    # --- JUGCAM.IND -----------------------------------------------------------------------
    jugcam = (DATSIM / "JUGCAM.IND").read_bytes()
    if len(jugcam) != JUGCAM_BYTES:
        raise SystemExit(f"JUGCAM.IND is {len(jugcam)} bytes, the 72x16x8x6 layout wants {JUGCAM_BYTES}")
    (OUT / "jugcam.bin").write_bytes(jugcam)

    # --- the per-club ramps, the base LUT, the keeper LUTs ---------------------------------
    # `FUN_005b63e0` builds the name as "000" + "%ld" of the club id, then takes the LAST FOUR
    # characters (`FUN_005e5c50(buf, -4)`), i.e. a 4-digit zero-padded key. The ids present are
    # SPARSE (829 of them, 1..9030), and an id with no file legitimately falls back to
    # `P96A0000.DAT` — the engine's own `FUN_005ec1d0` miss branch — so the blob is a dense
    # table with a JSON id -> slot map beside it rather than an id-indexed array.
    ids = sorted(
        int(p.name[4:8])
        for p in DATSIM.glob("P96A[0-9][0-9][0-9][0-9].DAT")
        if p.name[4:8] != "0000"
    )
    if len(ids) != N_CLUB_RAMPS:
        raise SystemExit(f"{len(ids)} P96A ramps present, expected {N_CLUB_RAMPS}")
    kit = bytearray()
    for tag in ("P96A", "P96B"):
        for club in ids:
            raw = (DATSIM / f"{tag}{club:04d}.DAT").read_bytes()
            if len(raw) != RAMP_BYTES:
                raise SystemExit(f"{tag}{club:04d}.DAT is {len(raw)} bytes, expected {RAMP_BYTES}")
            kit += raw
    base_lut = (DATSIM / "P96A0000.DAT").read_bytes()
    if len(base_lut) != 256:
        raise SystemExit("P96A0000.DAT is not a 256-byte LUT")
    kit += base_lut
    for i in range(N_PALPOR):
        raw = (DATSIM / f"PALPOR{i}.DAT").read_bytes()
        if len(raw) != 256:
            raise SystemExit(f"PALPOR{i}.DAT is not a 256-byte LUT")
        kit += raw
    (OUT / "kitpal.bin").write_bytes(bytes(kit))

    # --- the five pitch palettes ----------------------------------------------------------
    pal_blob = bytearray()
    pals = []
    for n in range(5):
        ent = _pal_entries((DAT / f"SIMUL{n}.PAL").read_bytes())
        pals.append(ent)
        pal_blob += bytes(ent)
    (OUT / "simulpal.bin").write_bytes(bytes(pal_blob))
    act = (DATSIM / "PALETA.ACT").read_bytes()
    if bytes(pals[0]) != act:
        raise SystemExit("SIMUL0.PAL no longer equals PALETA.ACT — the palette binding changed")

    # --- the shirt-number glyphs ----------------------------------------------------------
    num = numcam_glyphs(DATSIM / "NUMCAM.BMP")
    (OUT / "numcam.bin").write_bytes(num)

    bank = dict(tables)
    bank["frames"] = rows
    bank["index_bytes"] = len(blob)
    bank["z_num"], bank["z_den"], bank["x_den"] = Z_NUM, Z_DEN, X_DEN
    bank["kit"] = {
        "clubs": N_CLUB_RAMPS,
        "stride": RAMP_BYTES,
        "pattern_bytes": 128,
        "lut_first": 9,
        "lut_count": 48,
        "class_byte": 176,
        "base_lut_off": N_CLUB_RAMPS * RAMP_BYTES * 2,
        "palpor_off": N_CLUB_RAMPS * RAMP_BYTES * 2 + 256,
        "palpor_count": N_PALPOR,
        "numcam_glyphs": len(num) // 64,
        "slots": {str(cid): i for i, cid in enumerate(ids)},
        "club_ramp": _club_ramp_map(ids),
        "keeper_class": list(pe.read_va(VA_KEEPER_CLASS, N_PALPOR)),
    }
    (OUT / "jug_bank.json").write_text(json.dumps(bank, separators=(",", ":")))

    for stale in ("jug_base.png", "jug_kit.png", "player_base.png", "player_kit.png"):
        for p in (OUT / stale, OUT / (stale + ".import")):
            if p.exists():
                p.unlink()

    print(f"jug_index.bin  {len(blob):,} B   frames={len(frames)}  kinds={N_KINDS}")
    print(f"jugcam.bin     {len(jugcam):,} B  = 72 maps x 16 x 8 x 6   PASS (exact file size)")
    print(f"kitpal.bin     {len(kit):,} B   {N_CLUB_RAMPS} P96A + {N_CLUB_RAMPS} P96B + base + {N_PALPOR} palpor")
    print(f"simulpal.bin   {len(pal_blob):,} B   SIMUL0..4 (SIMUL0 == PALETA.ACT  PASS)")
    print(f"numcam.bin     {len(num):,} B   {len(num)//64} shirt-number glyphs")
    print(f"frame map ids  {min(maps)}..{max(maps)} of 0..71   PASS")
    print("VALIDATION: base[] total == JUG.PGF frame count == 4211  PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
