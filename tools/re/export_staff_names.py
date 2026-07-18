#!/usr/bin/env python3
"""Export the ORIGINAL name pools (DBDAT/NOMBRES.30 + APELLIDO.30) for the app.

The game generates its staff-hire candidates (and regen/youth players) from these
two DMLT tables — proven by the 2026-07-18 witness pass: 43/43 staff-candidate
surnames observed across the two walkthrough careers (Man Utd run1 15:47 frames
095-120 + Bolton wine run 56-59) exist in APELLIDO.30, including the escape-byte
name "O'brian" (raw 0x46 ^ 0x61 = "'"), and every witnessed forename initial has
table forenames. See docs/re/staff_re.md "The real candidate pools".

Writes app/data/name_pools.json:
    {"forenames": [148 mixed-case strings], "surnames": [327 mixed-case strings]}

Usage:  python3 tools/re/export_staff_names.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dmlt_decode import DBDAT, read_dmlt  # noqa: E402

OUT = Path(__file__).resolve().parents[2] / "app" / "data" / "name_pools.json"


def main() -> None:
    forenames = read_dmlt(DBDAT / "NOMBRES.30")
    surnames = read_dmlt(DBDAT / "APELLIDO.30")
    assert len(forenames) == 148, f"NOMBRES.30 expected 148, got {len(forenames)}"
    assert len(surnames) == 327, f"APELLIDO.30 expected 327, got {len(surnames)}"
    assert "O'brian" in surnames, "escape-byte decode regressed (O'brian missing)"
    OUT.write_text(json.dumps({"forenames": forenames, "surnames": surnames},
                              ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {OUT} ({len(forenames)} forenames, {len(surnames)} surnames)")


if __name__ == "__main__":
    main()
