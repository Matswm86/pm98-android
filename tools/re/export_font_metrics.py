#!/usr/bin/env python3
"""Bake the BMFont `.fnt` char tables into `app/data/font_metrics.json`.

Why this exists: Godot imports `art/fonts/*.fnt` with the `font_data_bmfont`
importer, so the SOURCE `.fnt` is not carried into an exported APK — only the
`.import` stub and `.godot/imported/*.fontdata`.  Verified against the shipped
`pm98-6f2e598.apk`: `assets/art/fonts/proman10.fnt` is absent.  Every code path
that read the `.fnt` back with `FileAccess` (PMAlert, DataBaseCardScreen,
TacticsBoardScreen) therefore got an EMPTY glyph table on device, which is what
drew every hub alert box as a blank white rectangle.

Plain data files under `res://data/` DO survive the export (`assets/data/*.json`
are all present in the same APK), so the char table ships as JSON and the raw
`.fnt` parse is kept only as the editor-side fallback / drift check.

Run: python3 tools/re/export_font_metrics.py
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "app" / "art" / "fonts"
OUT = ROOT / "app" / "data" / "font_metrics.json"

CHAR_RE = re.compile(
    r"char id=(-?\d+)\s+x=(-?\d+)\s+y=(-?\d+)\s+width=(-?\d+)\s+height=(-?\d+)"
    r"\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(-?\d+)"
)
KV_RE = re.compile(r"(\w+)=(-?\d+)")


def parse_fnt(path: Path) -> dict:
    """One `.fnt` -> {line_height, base, scale_w, scale_h, chars{id: [...]}}."""
    common: dict[str, int] = {}
    chars: dict[str, list[int]] = {}
    for line in path.read_text(encoding="latin-1").splitlines():
        if line.startswith("common "):
            common = {k: int(v) for k, v in KV_RE.findall(line)}
        m = CHAR_RE.match(line)
        if m:
            cid, x, y, w, h, xo, yo, adv = (int(g) for g in m.groups())
            chars[str(cid)] = [x, y, w, h, xo, yo, adv]
    return {
        "line_height": common.get("lineHeight", 0),
        "base": common.get("base", 0),
        "scale_w": common.get("scaleW", 0),
        "scale_h": common.get("scaleH", 0),
        "chars": chars,
    }


def build() -> dict:
    return {p.stem: parse_fnt(p) for p in sorted(FONT_DIR.glob("*.fnt"))}


def main() -> None:
    out = build()
    OUT.write_text(json.dumps(out, separators=(",", ":"), sort_keys=True) + "\n")
    total = sum(len(f["chars"]) for f in out.values())
    print(f"{OUT.relative_to(ROOT)}: {len(out)} fonts, {total} glyphs")


if __name__ == "__main__":
    main()
