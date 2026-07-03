#!/usr/bin/env python3
"""Bake PM98's 10 predefined formations from MANAGER.EXE into a Godot data asset.

Source of truth: the formation-name pointer table at VA 0x6601f8 (10 names, verbatim
"3-4-3 3-5-2 4-3-3 4-4-2 5-3-2 5-4-1 4-2-4 5-2-3 4-5-1 3-3-3-1") and the coordinate
table `DAT_00660240`, 10 formations x 11 rows x 8 int32. Each row is one formation
slot; fields [4],[5] are the PRIMARY (defensive-phase) pitch marker and [6],[7] the
SECONDARY (attacking-phase) marker. The TACTICAS screen builder FUN_00568800 and the
predef-repaint FUN_0056ac90 map both onto the 258x154 marker layer as
    mx = raw * 258 / 318 ,  my = raw * 154 / 198
(the child pitch layer size / the tactic design space). Verified: the 3-5-2 layout
reproduces walkthrough frame 014_162413 (primary discs on the own half, movement
arrows toward the opponent goal).

Slot ordering (decoded from the coord table): rows 0..9 = the ten outfield slots,
row 10 = the goalkeeper (parked at marker (0,68) = far-left centre in every formation
except 3-3-3-1, whose 11th row is a degenerate sentinel). We emit `gk_slot` so the
consumer never has to guess.

Writes `app/data/formations.json` (committed, source-derived). Reproduce:
    cd tools/re && python3 export_formations.py
"""

from __future__ import annotations

import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXE = ROOT / "extracted" / "Premier Manager 98" / "MANAGER.EXE"
OUT = ROOT / "app" / "data" / "formations.json"

IMAGE_BASE = 0x401A00  # VA - IMAGE_BASE = raw file offset (verified vs the string dump)
NAMES_VA = 0x6601F8
DATA_VA = 0x660240
N_FORMS = 10
N_ROWS = 11
ROW_INTS = 8
# marker map: raw * NUM / DEN
X_NUM, X_DEN = 258, 318
Y_NUM, Y_DEN = 154, 198


def _va(data: bytes, va: int) -> int:
    return va - IMAGE_BASE


def _str_at(data: bytes, va: int) -> str:
    off = _va(data, va)
    end = data.find(b"\0", off)
    return data[off:end].decode("latin-1")


def main() -> None:
    data = EXE.read_bytes()

    names: list[str] = []
    for i in range(N_FORMS):
        (ptr,) = struct.unpack_from("<I", data, _va(data, NAMES_VA) + 4 * i)
        names.append(_str_at(data, ptr))

    forms = []
    base = _va(data, DATA_VA)
    for f in range(N_FORMS):
        slots = []
        gk_slot = N_ROWS - 1
        best_gk_x = 1 << 30
        rows = []
        for r in range(N_ROWS):
            v = struct.unpack_from("<8i", data, base + f * (N_ROWS * ROW_INTS * 4) + r * ROW_INTS * 4)
            rows.append(v)
        for r, v in enumerate(rows):
            mk1 = [v[4] * X_NUM // X_DEN, v[5] * Y_NUM // Y_DEN]
            mk2 = [v[6] * X_NUM // X_DEN, v[7] * Y_NUM // Y_DEN]
            slots.append({"raw": list(v), "mk1": mk1, "mk2": mk2})
            # GK = the slot parked hard against the own goal line (smallest primary x).
            if mk1[0] < best_gk_x:
                best_gk_x = mk1[0]
                gk_slot = r
        forms.append({"name": names[f], "gk_slot": gk_slot, "slots": slots})

    doc = {
        "_source": "MANAGER.EXE DAT_00660240 via tools/re/export_formations.py",
        "marker_layer": {"w": X_NUM, "h": Y_NUM},
        "formations": forms,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(doc, indent=1))
    print(f"wrote {OUT} : {len(forms)} formations {[f['name'] for f in forms]}")
    for f in forms:
        print(f"  {f['name']:8s} gk_slot={f['gk_slot']}")


if __name__ == "__main__":
    main()
