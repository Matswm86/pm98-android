#!/usr/bin/env python3
"""PASSIVE RECORDER — Mats plays the original, this watches. No click is ever sent.

Why a human plays: the automated season drive stalled at the original's XI-validity gate
("The initial line-up is not correct. A player is either banned or injured."). Dismissing
the alert is not enough — the week will not advance until the unavailable man is swapped
out. **SUPERSEDED 2026-07-25:** that swap IS scriptable after all. Two synthetic clicks in
the LINE-UP name column — the gold-plated unavailable row, then a fit substitute — clear
the gate (verified live: Holdsworth injured 5 weeks out, Fairclough in, TEAM RATING
72 -> 79), and `autodrive.py --swap_unavailable` does it, so the season drive no longer
needs a human. This recorder stays useful for watching a HUMAN explore screens no drive
has a route to.

What it banks: a PNG only when the screen actually CHANGES (average hash differs from the
last kept frame), so a whole season is a few hundred distinct frames, not thousands of
duplicates. Every banked frame is NAMED by `autodrive.identify()` against the taught
signatures in `screens.json`; a frame that matches nothing prints **NEW SCREEN** and is
filed as `UNKNOWN`. That set is the deliverable — it is exactly the screens no drive in
this repo has ever witnessed.

It also logs the POINTER. There is no `xinput` and no `python3-evdev` on this box, so real
button events cannot be captured; but the pointer is resting on the button at the instant
the screen changes, so the sample taken just before a transition recovers *where Mats
clicked*. Without that the frame set says what the screens are but not how to reach them,
which is the gap that has stalled three drives.

    DISPLAY=:1 PM98_DESKTOP=pm98play ORACLE_OUT=<dir> python3 record_play.py [--poll 1.0]

Stop with Ctrl-C (or `kill`); the manifest is flushed on every frame, so a kill loses
nothing.
"""

from __future__ import annotations

import argparse
import signal
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path

import numpy as np
from PIL import Image

import autodrive

HERE = Path(__file__).resolve().parent

MAN_HEADER = "seq\tiso\tscreen\tscore\tahash\tptr_x\tptr_y\tfocus\tfile\n"
# Below this, the best-matching taught signature is not the same screen at all -> novel.
# Between this and autodrive.MATCH_FRAC it is the same screen with different content.
VARIANT = 0.80
_stop = threading.Event()


# ------------------------------------------------------------------ pointer + geometry


class Pointer(threading.Thread):
    """Sample the pointer in window coordinates so a transition can be attributed.

    Root coordinates minus the window origin, re-read every sample because the wine
    desktop window can be dragged mid-run.
    """

    def __init__(self, e: dict, trail: Path, period: float = 0.2) -> None:
        super().__init__(daemon=True)
        self.e = e
        self.period = period
        self.trail = trail
        self.last: tuple[int, int] = (-1, -1)
        self._env = {"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"}

    def _sh(self, args: list[str]) -> dict[str, str]:
        r = subprocess.run(args, capture_output=True, text=True, env=self._env)
        out = {}
        for ln in r.stdout.splitlines():
            if "=" in ln:
                k, v = ln.split("=", 1)
                out[k] = v
        return out

    def run(self) -> None:
        with self.trail.open("a") as fh:
            while not _stop.is_set():
                try:
                    wid = autodrive.window_id(self.e)
                    g = self._sh(["xdotool", "getwindowgeometry", "--shell", wid])
                    p = self._sh(["xdotool", "getmouselocation", "--shell"])
                    x = int(p["X"]) - int(g["X"])
                    y = int(p["Y"]) - int(g["Y"])
                    self.last = (x, y)
                    fh.write(f"{datetime.now().isoformat(timespec='milliseconds')}\t{x}\t{y}\n")
                    fh.flush()
                except (SystemExit, KeyError, ValueError, subprocess.SubprocessError):
                    pass
                _stop.wait(self.period)


def focused(e: dict) -> int:
    """1 when the game window holds the input focus.

    A frame grabbed while another window covers the game is polluted; recording the flag
    lets the post-pass filter those out instead of silently trusting them.

    Must use `getwindowfocus` (XGetInputFocus), NOT `getactivewindow`: COSMIC's rootless
    Xwayland does not set `_NET_ACTIVE_WINDOW` on the X root, so the EWMH route errors out
    and every frame would be falsely flagged occluded (measured 2026-07-25).
    """
    ev = {"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"}
    try:
        wid = autodrive.window_id(e)
        r = subprocess.run(
            ["xdotool", "getwindowfocus"], capture_output=True, text=True, env=ev
        ).stdout.strip()
        return 1 if r == wid else 0
    except (SystemExit, subprocess.SubprocessError):
        return 0


# ------------------------------------------------------------------------------ hashing


def ahash(a: np.ndarray) -> str:
    """64-bit average hash of the frame — the change detector, same as season_state.py."""
    g = Image.fromarray(a.astype(np.uint8)).convert("L").resize((8, 8), Image.BILINEAR)
    px = np.asarray(g, dtype=np.int32).ravel()
    bits = 0
    avg = px.mean()
    for i, p in enumerate(px):
        if p >= avg:
            bits |= 1 << i
    return f"{bits:016x}"


# --------------------------------------------------------------------------------- main


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--poll", type=float, default=1.0, help="seconds between grabs")
    ap.add_argument("--min-px", type=int, default=20, dest="min_px",
                    help="bank a frame when at least this many pixels differ from the last kept one")
    a = ap.parse_args()

    e = autodrive.env()
    sigs = autodrive.load_sigs()
    out = e["out"] / "play"
    out.mkdir(parents=True, exist_ok=True)
    man = e["out"] / "play_manifest.tsv"
    if not man.exists():
        man.write_text(MAN_HEADER)
    newlog = e["out"] / "new_screens.log"      # the blocking watcher tails this
    trail = e["out"] / "pointer_trail.tsv"

    signal.signal(signal.SIGINT, lambda *_: _stop.set())
    signal.signal(signal.SIGTERM, lambda *_: _stop.set())

    ptr = Pointer(e, trail)
    ptr.start()

    n = len(list(out.glob("*.png")))           # resume-safe: keep counting up
    last_arr = None
    probe = out / ".probe.png"
    print(f"recording -> {out} (poll {a.poll}s, {len(sigs['screens'])} taught screens)")
    print("play the game; Ctrl-C to stop", flush=True)

    while not _stop.is_set():
        try:
            img = autodrive.grab(e, probe)
        except (SystemExit, subprocess.SubprocessError):
            _stop.wait(2.0)                    # window not up yet, or gone
            continue
        try:
            arr = autodrive.as_frame(img)
        except SystemExit:
            _stop.wait(a.poll)
            continue

        h = ahash(arr)
        # Change detection is a PIXEL COUNT, not the average hash. An 8x8 ahash cannot see a
        # small text field change — stepping the SCOUT screen's QUALITY spinner through all
        # seven bands produced ONE banked frame on 2026-07-25, because a two-word field in a
        # 640x480 frame does not move the downsampled average. The hash is still recorded in
        # the manifest (it groups identical screens cheaply); it just no longer gates.
        if last_arr is not None:
            changed = int(np.count_nonzero(np.any(arr != last_arr, axis=2)))
            if changed < a.min_px:
                _stop.wait(a.poll)
                continue
        last_arr = arr

        px, py = ptr.last                      # sampled up to 0.2 s before the change
        foc = focused(e)
        name, score, ranked = autodrive.identify(img, sigs)
        n += 1
        label = name or "UNKNOWN"
        f = out / f"p{n:04d}_{label}.png"
        probe.replace(f)
        with man.open("a") as fh:
            fh.write(
                f"{n}\t{datetime.now().isoformat(timespec='seconds')}\t{label}\t"
                f"{score:.3f}\t{h}\t{px}\t{py}\t{foc}\t{f.name}\n"
            )
        flag = "" if foc else "  [UNFOCUSED — frame may be occluded]"
        if name is not None:
            line = f"[{n:4d}] {name} ({score:.2f}) ptr=({px},{py}){flag}"
        elif ranked and ranked[0][1] >= VARIANT:
            # Known screen, different content. Every signature in screens.json was taught
            # from ONE club's career, so a Man Utd run scores ~0.89 on a Bolton-taught
            # sheet — the chrome matches, the club name band does not. Not novel; say so
            # rather than crying NEW SCREEN on every frame of the preseason.
            line = f"[{n:4d}] {ranked[0][0]}~variant ({ranked[0][1]:.2f}) ptr=({px},{py}){flag}"
        else:
            close = ", ".join(f"{k}={s:.2f}" for k, s in ranked[:3])
            line = f"[{n:4d}] *** NEW SCREEN *** ptr=({px},{py}) closest: {close}{flag}"
            with newlog.open("a") as fh:
                fh.write(f"{n}\t{f.name}\tptr={px},{py}\tclosest={close}\n")
        print(line, flush=True)
        _stop.wait(a.poll)

    _stop.set()
    print(f"\nstopped — {n} frames in {out}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
