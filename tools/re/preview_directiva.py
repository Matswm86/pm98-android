#!/usr/bin/env python3
"""BOARD OF DIRECTORS (DIRECTIVA) preview — frame-baked.

SUPERSEDED: the old PIL mirror here drew an invented "THE BOARD EXPECTS / YOUR RECORD"
panel (removed per SPEC_BINDING §6). The screen is now frame-baked from the real
walkthrough frame 167_154921 into app/art/screens/directiva/body.png by
`build_directiva_chrome_from_frames.py`, and the live meters/name are drawn by
app/scenes/DirectivaScreen.gd. The device-equivalent fidelity gate is the real Godot
render (app/tests/shot_directiva.gd), NOT a Python mirror.

This preview just composes the baked body under the shared marble/barra so the static
chrome can be eyeballed without a GPU. It invents nothing.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "app" / "art" / "screens"
BODY = ART / "directiva" / "body.png"


def compose(out: str) -> None:
    if not BODY.exists():
        subprocess.run([sys.executable, str(ROOT / "tools/re/build_directiva_chrome_from_frames.py")], check=True)
    cv = (Image.open(ART / "fondo_marble.png").convert("RGB").resize((640, 480), Image.NEAREST))
    bar = Image.open(ART / "barra0.png").convert("RGB")
    cv.paste(bar.resize((640, bar.height), Image.NEAREST), (0, 0))
    cv.paste(Image.open(BODY).convert("RGB"), (0, 44))
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    cv.save(out)
    print(f"wrote {out} (640x480) — BOARD OF DIRECTORS baked body over marble/barra")


if __name__ == "__main__":
    compose(sys.argv[1] if len(sys.argv) > 1 else "/tmp/pm98shots/directiva_preview.png")
