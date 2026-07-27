#!/usr/bin/env python3
"""Keep every frame of NAMED screens while another drive is running.

`autodrive.py run` clicks a plan's `keep` list and throws the rest away, so a screen
that is not in the plan -- the channelTV card for a CUP tie, say -- flashes past and is
gone. This is a passive second pair of eyes on the SAME wine window: it grabs the window
on a timer, identifies the frame with `autodrive`'s own taught pixel signatures, and
writes it out when the name is one you asked for and the pixels differ from the last one
kept. It never clicks, so it cannot desynchronise the drive.

    DISPLAY=:8 PM98_DESKTOP=pm98agg ORACLE_OUT=/tmp/out \\
        python3 screenwatch.py channel_tv news_extra --every 1.2

Frames land in $ORACLE_OUT/watch/<name>_<n>.png. Ctrl-C (or --for SECONDS) to stop.
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import autodrive as AD  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="+", help="screen names to keep (autodrive signatures)")
    ap.add_argument("--every", type=float, default=1.5, help="seconds between grabs")
    ap.add_argument("--for", dest="secs", type=float, default=0.0, help="stop after N seconds")
    ap.add_argument("--min-score", type=float, default=0.97)
    args = ap.parse_args()

    out = Path(os.environ.get("ORACLE_OUT", "/tmp")) / "watch"
    out.mkdir(parents=True, exist_ok=True)
    wanted = set(args.names)
    kept: dict[str, list[bytes]] = {n: [] for n in wanted}
    tmp = out / "_probe.png"
    env = AD.env()
    sigs = AD.load_sigs()
    started = time.time()
    n = 0
    while True:
        if args.secs and time.time() - started > args.secs:
            break
        try:
            img = AD.grab(env, tmp)
            name, sc, _ = AD.identify(img, sigs)
        except Exception:
            time.sleep(args.every)
            continue
        score = sc
        if name in wanted and score >= args.min_score:
            raw = tmp.read_bytes()
            if raw not in kept[name]:
                kept[name].append(raw)
                n += 1
                dst = out / f"{name}_{len(kept[name]):03d}.png"
                dst.write_bytes(raw)
                print(f"kept {dst.name} (score {score:.3f})", flush=True)
        time.sleep(args.every)
    print(f"done: {n} frame(s) kept in {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
