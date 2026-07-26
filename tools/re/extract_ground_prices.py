#!/usr/bin/env python3
"""Extract the GROUND IMPROVEMENTS cost table byte-exact from MANAGER.EXE.

The un-RE'd "offer cost function" flagged in docs/re/stadium_screen_re.md is
`FUN_0057ddd0` @VA 0x0057ddd0:

    void __cdecl cost(int tier, int category, int index, float *price, uint *weeks)

Its body is one 15-way jump table (categories, 1-based) over per-category
9-way jump tables (the club tier byte `ground+0x24`), each arm a single
`MOV dword ptr [EAX], <f32 imm>` optionally followed by
`FMUL float ptr [0x00638dc4]` (= 0.5).  The epilogue @0x0057e201 is

    FILD qword [weeks] ; FMUL double [0x00638dc8] (= 1e6) ; FMUL float [price]

and the money display path divides by 200 (the game-wide money convention
already reversed in docs/re/transfer_value_re.md §"Multiplier"), so

    GBP = f32(weeks * 1e6 * P) / 200        == weeks * 5000 * P  before rounding

This script walks the real jump tables in the real binary — nothing is typed
in by hand — and writes app/data/ground_cost_table.json.

Usage: python3 tools/re/extract_ground_prices.py [--check]
"""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EXE = REPO / "extracted/Premier Manager 98/MANAGER.EXE"
OUT = REPO / "app/data/ground_cost_table.json"

IMAGE_BASE = 0x400000
FN = 0x0057DDD0
OUTER_TABLE = 0x0057E224  # JMP [ECX*4 + 0x57e224], ECX = category - 1
N_CATEGORY = 15
N_TIER = 9  # switch arms 0..8; anything above falls to the arm's default

HALF_VA = 0x00638DC4  # FMUL float ptr [0x638dc4] == 0.5
MILLION_VA = 0x00638DC8  # FMUL double ptr [0x638dc8] == 1e6
DISPLAY_DIVISOR = 200  # transfer_value_re.md: the money display path divides by 200

# The GROUND panel's own section order (stadium_screen_re.md "Real layout"):
# SEATS, CAR PARK, then FACILITIES then SERVICES, each in listed order.
CATEGORY_NAMES = {
    1: "seats",
    2: "seats_alt",
    3: "car_park_ne",
    4: "car_park_nw",
    5: "car_park_se",
    6: "car_park_sw",
    7: "floodlights",
    8: "under_soil_heating",
    9: "changing_rooms",
    10: "score_board",
    11: "access_to_the_stadium",
    12: "medical_equipment",
    13: "club_shop",
    14: "cafes",
    15: "toilets",
}


class Image:
    """Flat PE reader: VA <-> file offset, plus little-endian scalar reads."""

    def __init__(self, path: Path) -> None:
        self.data = path.read_bytes()
        pe = struct.unpack_from("<I", self.data, 0x3C)[0]
        nsec = struct.unpack_from("<H", self.data, pe + 6)[0]
        optsz = struct.unpack_from("<H", self.data, pe + 20)[0]
        self.sections = []
        for i in range(nsec):
            off = pe + 24 + optsz + i * 40
            vsz, va, rsz, ra = struct.unpack_from("<IIII", self.data, off + 8)
            self.sections.append((va, vsz, ra, rsz))

    def off(self, va: int) -> int:
        rva = va - IMAGE_BASE
        for sva, vsz, ra, _rsz in self.sections:
            if sva <= rva < sva + vsz:
                return ra + (rva - sva)
        raise ValueError(f"VA {va:#x} is not mapped")

    def u32(self, va: int) -> int:
        return struct.unpack_from("<I", self.data, self.off(va))[0]

    def f64(self, va: int) -> float:
        return struct.unpack_from("<d", self.data, self.off(va))[0]

    def raw(self, va: int, n: int) -> bytes:
        o = self.off(va)
        return self.data[o : o + n]


# `MOV dword ptr [EAX], imm32` then optionally `FMUL float ptr [0x00638dc4]`.
MOV_EAX_IMM = b"\xc7\x00"
FMUL_HALF = b"\xd8\x0d" + struct.pack("<I", HALF_VA)
# `MOV dword ptr [EDX], imm32` — a weeks store that precedes the price arm.
MOV_EDX_IMM = b"\xc7\x02"
JMP_TABLE = b"\xff\x24\x8d"  # JMP dword ptr [ECX*4 + disp32]
CMP_ECX_8 = b"\x83\xf9\x08"
JA_REL32 = b"\x0f\x87"


def read_price_arm(img: Image, va: int) -> float:
    """Follow an arm that stores the price immediate; return the f32 value."""
    blob = img.raw(va, 16)
    if not blob.startswith(MOV_EAX_IMM):
        raise ValueError(f"arm {va:#x} is not a price store: {blob[:6].hex()}")
    imm = struct.unpack_from("<I", blob, 2)[0]
    value = struct.unpack("<f", struct.pack("<I", imm))[0]
    # Categories 1 and 2 follow the store with FLD [EAX] / FMUL [0x638dc4] / FSTP [EAX];
    # the rest jump straight to the epilogue. Look only inside this arm (up to its JMP).
    tail = blob[6:]
    end = min(i for i in (tail.find(b"\xe9"), tail.find(b"\xeb"), len(tail)) if i >= 0)
    if FMUL_HALF in tail[:end]:
        value *= struct.unpack("<f", img.raw(HALF_VA, 4))[0]
    return value


def read_switch(img: Image, va: int, n: int) -> tuple[list[int], int]:
    """At `va`, expect CMP ECX,n / JA default / JMP [ECX*4+table]. Return (arms, default)."""
    blob = img.raw(va, 24)
    i = blob.find(CMP_ECX_8)
    if i < 0:
        raise ValueError(f"no CMP ECX,8 at {va:#x}: {blob.hex()}")
    j = i + 3
    if blob[j : j + 2] == JA_REL32:
        default = va + j + 6 + struct.unpack_from("<i", blob, j + 2)[0]
        j += 6
    elif blob[j] == 0x77:  # JA rel8 — MSVC picks whichever encoding reaches
        default = va + j + 2 + struct.unpack_from("<b", blob, j + 1)[0]
        j += 2
    else:
        raise ValueError(f"no JA at {va + j:#x}: {blob[j : j + 6].hex()}")
    if blob[j : j + 3] != JMP_TABLE:
        raise ValueError(f"no jump table at {va + j:#x}: {blob[j : j + 6].hex()}")
    table = struct.unpack_from("<I", blob, j + 3)[0]
    return [img.u32(table + k * 4) for k in range(n)], default


def read_weeks_chain(img: Image, va: int) -> dict[int, int]:
    """Decode the `if (index == k) weeks = W` DEC/JZ chain that opens categories 1 and 2."""
    # MOV ECX,[ESP+0x14] ; SUB ECX,0 ; JZ idx0 ; DEC ECX ; JZ idx1 ; DEC ECX ; JNZ out ;
    # <idx2 falls through>.  Each arm is MOV dword ptr [EDX],<weeks>.
    weeks: dict[int, int] = {}
    blob = img.raw(va, 0x40)
    targets: list[int] = []
    p = 4  # skip the MOV ECX,[ESP+disp8]
    if blob[p : p + 3] == b"\x83\xe9\x00":  # SUB ECX,0
        p += 3
    while True:
        if blob[p] == 0x49:  # DEC ECX
            p += 1
        elif blob[p] == 0x74:  # JZ rel8 -> this index's arm
            targets.append(va + p + 2 + struct.unpack_from("<b", blob, p + 1)[0])
            p += 2
        elif blob[p] == 0x75:  # JNZ rel8 out -> the fallthrough IS the next index
            targets.append(va + p + 2)
            break
        else:
            break
    for idx, tgt in enumerate(targets):
        arm = img.raw(tgt, 6)
        if arm.startswith(MOV_EDX_IMM):
            weeks[idx] = struct.unpack_from("<I", arm, 2)[0]
    return weeks


def read_weeks_table(img: Image, va: int, n: int) -> tuple[dict[int, int], int]:
    """CMP ECX,n / JA / JMP [ECX*4+table] where each arm stores weeks into [EDX]."""
    blob = img.raw(va, 20)
    i = blob.find(b"\x83\xf9" + bytes([n]))  # CMP ECX,n after the MOV ECX,[ESP+disp8]
    if i < 0:
        raise ValueError(f"no CMP ECX,{n} at {va:#x}: {blob[:8].hex()}")
    i += 3
    if blob[i] != 0x77:  # JA rel8
        raise ValueError(f"no JA rel8 at {va + i:#x}")
    after = va + i + 2 + struct.unpack_from("<b", blob, i + 1)[0]
    i += 2
    if blob[i : i + 3] != JMP_TABLE:
        raise ValueError(f"no jump table at {va + i:#x}")
    table = struct.unpack_from("<I", blob, i + 3)[0]
    weeks = {}
    for k in range(n + 1):
        arm = img.raw(img.u32(table + k * 4), 6)
        if arm.startswith(MOV_EDX_IMM):
            weeks[k] = struct.unpack_from("<I", arm, 2)[0]
    return weeks, after


def extract(img: Image) -> dict:
    outer = [img.u32(OUTER_TABLE + i * 4) for i in range(N_CATEGORY)]
    million = img.f64(MILLION_VA)
    half = struct.unpack("<f", img.raw(HALF_VA, 4))[0]
    cats: dict[str, dict] = {}

    for ci, entry in enumerate(outer, start=1):
        name = CATEGORY_NAMES[ci]
        rec: dict = {"category": ci, "entry": hex(entry)}
        blob = img.raw(entry, 12)

        if ci in (1, 2):
            # weeks from the index chain, then a 9-arm tier switch
            rec["weeks_by_index"] = read_weeks_chain(img, entry)
            sw = entry + 0x25 if ci == 1 else entry + 0x25
            # the tier switch starts at the first CMP ECX,8 after the chain
            span = img.raw(entry, 0x60)
            sw = entry + span.find(CMP_ECX_8) - 4
            arms, default = read_switch(img, sw, N_TIER)
            rec["price_by_tier"] = [read_price_arm(img, a) for a in arms]
            rec["price_default"] = read_price_arm(img, default)

        elif ci == 10:
            # weeks fixed at 1; price picked by index only (DEC/JZ chain on [ESP+0x14])
            rec["weeks_by_index"] = {}
            price: dict[int, float] = {}
            span = img.raw(entry, 0x30)
            p = 4
            arms = []
            while span[p] in (0x49, 0x74):
                if span[p] == 0x49:
                    p += 1
                    continue
                arms.append(entry + p + 2 + struct.unpack_from("<b", span, p + 1)[0])
                p += 2
            # the fallthrough arm is index 0, then the JZ arms are indices 1, 2 ...
            fall = entry + p
            price[0] = read_price_arm(img, fall)
            for k, a in enumerate(arms, start=1):
                price[k] = read_price_arm(img, a)
            rec["price_by_index"] = price
            rec["weeks_flat"] = 1

        elif ci in (13, 14):
            wk, after = read_weeks_table(img, entry, 3)
            rec["weeks_by_index"] = wk
            arms, default = read_switch(img, after, N_TIER)
            rec["price_by_tier"] = [read_price_arm(img, a) for a in arms]
            rec["price_default"] = read_price_arm(img, default)

        elif ci == 15:
            rec["weeks_flat"] = 1
            rec["price_flat"] = read_price_arm(img, entry)

        else:
            # MOV ECX,[ESP+0xc] ; MOV [EDX],<weeks> ; CMP ECX,8 ; JA ; JMP table
            if blob[4:6] != MOV_EDX_IMM:
                raise ValueError(f"cat {ci}: no weeks store at {entry + 4:#x}")
            rec["weeks_flat"] = struct.unpack_from("<I", blob, 6)[0]
            arms, default = read_switch(img, entry + 10, N_TIER)
            rec["price_by_tier"] = [read_price_arm(img, a) for a in arms]
            rec["price_default"] = read_price_arm(img, default)

        cats[name] = rec

    return {
        "source": "MANAGER.EXE FUN_0057ddd0 @0x0057ddd0 (jump tables walked, not transcribed)",
        "half_constant_0x638dc4": half,
        "million_constant_0x638dc8": million,
        "display_divisor": DISPLAY_DIVISOR,
        "formula": "gbp = trunc(f32(weeks * 1e6 * price) / 200)",
        "tier_source": "ground+0x24 — the club's START OF SEASON board objective index",
        "categories": cats,
    }


def gbp(weeks: int, price: float) -> int:
    """Reproduce the x87 epilogue + the /200 display path exactly.

    FILD qword weeks ; FMUL double 1e6 ; FMUL float price ; FSTP float  -> f32
    then the money display divides by 200 and truncates.
    """
    raw = struct.unpack("<f", struct.pack("<f", float(weeks) * 1e6 * price))[0]
    return int(raw / DISPLAY_DIVISOR)


# Every price witnessed on a real MANAGER.EXE GROUND screen.
# Man Utd = board objective "Champion" (tier 0); Bolton W = "Avoid Relegation" (tier 3).
# Sources: docs/re/stadium_screen_re.md (wine capture 2026-07-23, owner captures
# 2026-07-23) and screenshots/parity-run-2026-07-16/orig/21_ground_improve.png.
# The five SEATS ladders are the five live-witnessed board tiers from the 2026-07-19 wine
# campaign (StadiumScreen.TIER_PRICES): Arsenal/Man Utd (stature 0), Aston Villa (1),
# Wimbledon (2), Bolton W (3), Manchester C in Division One (4).
WITNESSES = [
    ("seats", 0, 0, 4_250_000, 20),
    ("seats", 0, 1, 7_437_500, 35),
    ("seats", 0, 2, 10_624_999, 50),
    ("seats", 1, 0, 3_750_000, 20),
    ("seats", 1, 1, 6_562_499, 35),
    ("seats", 1, 2, 9_375_000, 50),
    ("seats", 2, 0, 3_250_000, 20),
    ("seats", 2, 1, 5_687_500, 35),
    ("seats", 2, 2, 8_124_999, 50),
    ("seats", 3, 0, 2_750_000, 20),
    ("seats", 3, 1, 4_812_499, 35),
    ("seats", 3, 2, 6_875_000, 50),
    ("seats", 4, 0, 2_250_000, 20),
    ("seats", 4, 1, 3_937_500, 35),
    ("seats", 4, 2, 5_624_999, 50),
    ("car_park_ne", 0, 0, 2_975_000, 7),
    ("floodlights", 0, 0, 500_000, 4),
    ("under_soil_heating", 0, 0, 1_200_000, 8),
    ("changing_rooms", 0, 0, 225_000, 3),
    ("access_to_the_stadium", 0, 0, 900_000, 6),
    ("medical_equipment", 0, 0, 150_000, 2),
    ("club_shop", 0, 1, 25_000, 1),
    ("cafes", 0, 3, 500_000, 20),
    ("toilets", 0, 0, 50_000, 1),
]


def resolve(table: dict, name: str, tier: int, index: int) -> tuple[int, int]:
    rec = table["categories"][name]
    if "price_flat" in rec:
        price = rec["price_flat"]
    elif "price_by_index" in rec:
        price = rec["price_by_index"].get(index, rec["price_by_index"].get(str(index), 0.0))
    else:
        arms = rec["price_by_tier"]
        price = arms[tier] if tier < len(arms) else rec["price_default"]
    if "weeks_flat" in rec:
        weeks = rec["weeks_flat"]
    else:
        wk = rec["weeks_by_index"]
        weeks = wk.get(index, wk.get(str(index), 0))
    return gbp(weeks, price), weeks


def check(table: dict) -> int:
    bad = 0
    for name, tier, index, want_gbp, want_weeks in WITNESSES:
        got_gbp, got_weeks = resolve(table, name, tier, index)
        ok = got_gbp == want_gbp and got_weeks == want_weeks
        bad += not ok
        print(
            f"  {'OK  ' if ok else 'FAIL'} {name:<22} tier {tier} idx {index}  "
            f"£{got_gbp:,} / {got_weeks}wk   (witness £{want_gbp:,} / {want_weeks}wk)"
        )
    print(f"{len(WITNESSES) - bad}/{len(WITNESSES)} witnesses exact")
    return bad


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="only validate, do not write")
    args = ap.parse_args()

    table = extract(Image(EXE))
    bad = check(table)
    if bad:
        raise SystemExit(f"{bad} witness mismatch(es) — refusing to write {OUT}")
    if not args.check:
        OUT.write_text(json.dumps(table, indent=1, sort_keys=False) + "\n")
        print(f"wrote {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
