#!/usr/bin/env python3
"""Pixel-signature auto-driver for the wine MANAGER.EXE oracle harness.

The long captures (a whole season to END OF SEASON, a cup draw, a suspension) are not
reachable by a fixed click list: the original raises news boards, alert boxes, draw
drums and result screens in an order that depends on the sim, so a blind script
desynchronises within a few weeks. This driver closes that loop — it looks at the frame
before every click.

A *screen* is identified by a set of probe points inside a region of interest: a lattice
of (x, y) samples whose RGB is stable across every frame of that screen it was taught
from. Content (club names, scores, dates) moves; the chrome under the probes does not.

    learn   NAME  X,Y,W,H  frame.png [frame2.png ...]   teach a screen from real frames
    id      [--shot NAME]                               name the screen on the wire now
    probe   X Y                                         print the RGB at one point
    run     plan.json                                   drive by the rule table
    shots   DIR                                         re-identify a directory of frames

`run` loops: grab -> identify -> look the screen up in the plan's rule table -> click.
An unknown screen is saved to the output directory and the drive STOPS. That is the
point: every stop is a screen we have never witnessed, which is exactly what the
remaining capture work is short of.

Signatures live in tools/re/wine/screens.json so they are reviewable in a diff.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
SIGS = HERE / "screens.json"

# The wine desktop is 640x480; a 16 px lattice gives <=1200 candidate probes per screen,
# enough to separate every screen we hold and cheap enough to evaluate every frame.
LATTICE = 16
# Wine's 8-bit palette path is exact frame to frame, but x11grab can land mid-blit on a
# transition, so allow a small per-channel slack and require most probes to agree.
CHANNEL_TOL = 8
MATCH_FRAC = 0.97


# --------------------------------------------------------------------------- capture


def env() -> dict:
    """Read the harness env (DISPLAY, ORACLE_OUT, desktop name) out of env.sh."""
    out = subprocess.run(
        ["bash", "-c", f'source "{HERE}/env.sh"; echo "$DISPLAY"; echo "$ORACLE_OUT"; echo "$WIN_NAME"'],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.splitlines()
    return {"display": out[0], "out": Path(out[1]), "win_name": out[2]}


def window_id(e: dict) -> str:
    r = subprocess.run(
        ["xdotool", "search", "--name", e["win_name"]],
        capture_output=True,
        text=True,
        env={"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"},
    )
    ids = [ln for ln in r.stdout.split() if ln.strip()]
    if not ids:
        raise SystemExit("no game window — boot.sh first")
    return ids[0]


def grab(e: dict, path: Path) -> Image.Image:
    """Screenshot the wine desktop window (the walkthrough's ffmpeg x11grab method)."""
    path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "ffmpeg", "-loglevel", "error", "-y",
            "-f", "x11grab", "-window_id", window_id(e), "-draw_mouse", "0",
            "-i", e["display"], "-frames:v", "1", str(path),
        ],
        check=True,
        env={"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"},
    )
    return Image.open(path).convert("RGB")


def click(e: dict, x: int, y: int, n: int = 1, gap: float = 0.4) -> None:
    wid = window_id(e)
    ev = {"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"}
    # PM98_NO_RAISE=1: drive without yanking the game window to the front on every click.
    if os.environ.get("PM98_NO_RAISE") != "1":
        subprocess.run(["xdotool", "windowactivate", "--sync", wid], env=ev, check=False)
        subprocess.run(["xdotool", "windowraise", wid], env=ev, check=False)
    time.sleep(0.2)
    for _ in range(n):
        subprocess.run(
            ["xdotool", "mousemove", "--window", wid, str(x), str(y), "click", "1"],
            env=ev,
            check=True,
        )
        time.sleep(gap)


def typetext(e: dict, text: str) -> None:
    """Global XTEST typing — `xdotool key --window` (XSendEvent) is dropped by wine."""
    wid = window_id(e)
    ev = {"DISPLAY": e["display"], "PATH": "/usr/bin:/bin"}
    subprocess.run(["xdotool", "windowactivate", "--sync", wid], env=ev, check=False)
    subprocess.run(["xdotool", "mousemove", "--window", wid, "320", "240"], env=ev, check=False)
    time.sleep(0.2)
    subprocess.run(["xdotool", "type", "--delay", "80", text], env=ev, check=True)


# ------------------------------------------------------------------------ signatures


def load_sigs() -> dict:
    if not SIGS.exists():
        return {"screens": {}}
    return json.loads(SIGS.read_text())


def save_sigs(sigs: dict) -> None:
    SIGS.write_text(json.dumps(sigs, indent=1, sort_keys=True) + "\n")


def lattice_points(roi: tuple[int, int, int, int], step: int) -> list[tuple[int, int]]:
    x0, y0, w, h = roi
    return [
        (x, y)
        for y in range(y0, y0 + h, step)
        for x in range(x0, x0 + w, step)
    ]


def as_frame(img: Image.Image) -> np.ndarray:
    """Normalise to the 640x480 desktop.

    The 2026-07 archived captures are 641 px wide — the same 640 px window plus one black
    column at x=640 (verified: 99.92% of pixels identical at offset 0). Crop, don't shift.
    """
    a = np.asarray(img.convert("RGB"), dtype=np.int16)
    if a.shape[0] != 480 or a.shape[1] < 640:
        raise SystemExit(f"frame is {a.shape[1]}x{a.shape[0]}, expected 640x480")
    return a[:, :640]


def learn(name: str, roi: tuple[int, int, int, int], frames: list[Path], step: int = LATTICE) -> dict:
    """Keep only the lattice points whose RGB is identical in EVERY teaching frame."""
    arrs = [as_frame(Image.open(f)) for f in frames]
    probes = []
    for x, y in lattice_points(roi, step):
        rgbs = [tuple(int(c) for c in a[y, x]) for a in arrs]
        if all(
            max(abs(rgbs[0][c] - r[c]) for c in range(3)) <= CHANNEL_TOL for r in rgbs[1:]
        ):
            probes.append([x, y, *rgbs[0]])
    if len(probes) < 12:
        raise SystemExit(
            f"only {len(probes)} stable probes for {name} — widen the ROI or use fewer frames"
        )
    return {"roi": list(roi), "probes": probes, "taught_from": [f.name for f in frames]}


TEMPLATES = HERE / "templates"
_PROBE_CACHE: dict = {}
_TMPL_CACHE: dict = {}


def _template(name: str) -> np.ndarray:
    if name not in _TMPL_CACHE:
        _TMPL_CACHE[name] = np.asarray(
            Image.open(TEMPLATES / name).convert("RGB"), dtype=np.int16
        )
    return _TMPL_CACHE[name]


def locate(img: Image.Image, tmpl_name: str, tol: int = CHANNEL_TOL) -> tuple[int, int] | None:
    """Find a small chrome bitmap anywhere in the frame; return its top-left, or None.

    Needed because the original's alert box is centred and sized to its message, so its
    OK button is not at a fixed point. A rare-colour prefilter keeps this cheap: only
    positions whose pixel equals the template's own rarest colour are verified.
    """
    a = as_frame(img)
    t = _template(tmpl_name)
    th, tw = t.shape[:2]
    # Pick (once per template) the pixel whose colour is rarest in the frame, then reuse
    # it: re-deriving it on every frame made identify() cost tens of seconds a step.
    if tmpl_name in _PROBE_CACHE:
        ty, tx = _PROBE_CACHE[tmpl_name]
    else:
        flat = a.reshape(-1, 3)
        best_px, best_n = (0, 0), None
        for ty in range(0, th, 2):
            for tx in range(0, tw, 2):
                n = int((np.abs(flat - t[ty, tx]).max(axis=1) <= tol).sum())
                if best_n is None or n < best_n:
                    best_px, best_n = (ty, tx), n
                if best_n <= 200:
                    break
            if best_n <= 200:
                break
        _PROBE_CACHE[tmpl_name] = best_px
        ty, tx = best_px
    ys, xs = np.nonzero(np.abs(a - t[ty, tx]).max(axis=2) <= tol)
    for y, x in zip(ys - ty, xs - tx):
        if y < 0 or x < 0 or y + th > a.shape[0] or x + tw > a.shape[1]:
            continue
        if np.abs(a[y:y + th, x:x + tw] - t).max() <= tol:
            return int(x), int(y)
    return None


def score(img: Image.Image, entry: dict) -> float:
    a = as_frame(img)
    p = np.array(entry["probes"], dtype=np.int16)
    got = a[p[:, 1], p[:, 0]]
    ok = (np.abs(got - p[:, 2:5]).max(axis=1) <= CHANNEL_TOL)
    return float(ok.mean())


def alert_ok_point(img: Image.Image) -> tuple[int, int] | None:
    """Centre of the OK button of the PREMIER MANAGER 98 message box.

    The box is sized to its message, so the button moves. Measured on two real boxes of
    different widths (2026-07-25): the button plate always sits at
    (panel_right - 23, panel_bottom - 12) of the white message panel.
        wide   panel x104..529 y228..275 -> plate x489..523 y258..269 -> centre (506,263)
        narrow panel x178..455 y223..280 -> plate x415..449 y263..274 -> centre (432,268)
    """
    hit = locate(img, "alert_bang.png")
    if hit is None:
        return None
    ix, iy = hit
    a = as_frame(img)
    white = np.abs(a - 255).max(axis=2) <= 6
    right = bottom = None
    for y in range(iy, min(iy + 120, 480)):
        row = white[y]
        x = ix
        while x < 640 and row[x]:
            x += 1
        if x - ix >= 50:
            right = x if right is None else max(right, x)
            bottom = y
    if right is None or bottom is None:
        return None
    return right - 1 - 23, bottom - 12


# LINE-UP screen geometry. XI rows measured 2026-07-25 (30_lineup / 34_swap), pool rows
# re-measured 2026-07-26 on a live Bolton W LINE-UP with a suspension (the old
# `SUB = 294,310,326` / `RESERVE = 363..443` was wrong: the block holds FIVE substitutes,
# 294..358, and the RESERVES rows start at 395 — 363/379 are the block's own header band,
# so a swap could aim at a row that is not a player at all).
#   XI rows          y = 95 + 16*i, i = 0..10
#   SUBSTITUTES rows y = 294 + 16*i, i = 0..4
#   RESERVES rows    y = 395 + 16*i, i = 0..3   (the block scrolls; 4 are on screen)
# An unavailable player's row is repainted on a GOLD plate (212,191,85) at x=60 with a
# dark-gold status band where the EN..QU attribute cells normally are: an INJURY draws a
# medical cross at x181..189 plus "<n> WEEKS", a SUSPENSION a red card plus "MATCH".
# The plate alone is NOT sufficient — a row the user has just tapped is repainted with the
# selection blue over the plate, and that is exactly the row a swap has to find. The band
# survives the selection, so it is the discriminator: dark gold is the only ink in that
# column with B < 40 (every available row's band is a pastel or (100,100,140)).
# Witnessed values: (85,63,0) plain, (170,127,0) and (170,159,0) under a modal's dim.
LINEUP_XI_Y = tuple(95 + 16 * i for i in range(11))
LINEUP_SUB_Y = tuple(294 + 16 * i for i in range(5))
LINEUP_RESERVE_Y = tuple(395 + 16 * i for i in range(4))
LINEUP_PLATE_X = 60
LINEUP_NAME_X = 100
LINEUP_GOLD = (212, 191, 85)
LINEUP_BAND_X = (196, 233)   # the status-band column span


def _is_unavailable(a: np.ndarray, y: int) -> bool:
    if bool(np.abs(a[y, LINEUP_PLATE_X] - np.array(LINEUP_GOLD)).max() <= 8):
        return True
    band = a[max(0, y - 2):y + 7, LINEUP_BAND_X[0]:LINEUP_BAND_X[1]]
    gold = (band[..., 2] < 40) & (band[..., 0] >= 60) & (band[..., 0] > band[..., 1]) \
        & (band[..., 1] > band[..., 2])
    return bool(gold.any())


def unavailable_rows(img: Image.Image) -> dict:
    """Which LINE-UP rows carry the gold unavailable plate, by block."""
    a = as_frame(img)
    return {
        "xi": [y for y in LINEUP_XI_Y if _is_unavailable(a, y)],
        "subs": [y for y in LINEUP_SUB_Y if _is_unavailable(a, y)],
        "reserves": [y for y in LINEUP_RESERVE_Y if _is_unavailable(a, y)],
    }


LINEUP_ROL_X = (400, 434)   # the ROL text cell ("GOAL"/"DEF"/"MID"/"FOR"), ink only
LINEUP_ROL_DY = (-2, 3)     # the five glyph rows; the cell's own borders move per row


def _rol_mask(a: np.ndarray, y: int) -> bytes:
    """The ROL cell's ink as a bitmask, so two rows of the same role compare equal.

    The cell BACKGROUND alternates with the row band, so a raw pixel compare is useless;
    the glyphs are the same face at the same x on every row, so their ink mask is not.
    Cropped to the glyph rows: the cell's left border and its bottom edge are drawn
    differently on a selected / block-boundary row and would defeat the compare.
    """
    cell = a[max(0, y + LINEUP_ROL_DY[0]):y + LINEUP_ROL_DY[1], LINEUP_ROL_X[0]:LINEUP_ROL_X[1]]
    return (cell.max(axis=2) < 120).tobytes()


def lineup_swap_plan(img: Image.Image) -> tuple[tuple[int, int], tuple[int, int]] | None:
    """Pick (unavailable XI row, replacement row) as two name-column click points.

    Never offers a second goalkeeper: XI slot 0 is always the GK, so a pool row whose ROL
    ink matches slot 0's is one too. (Learned the hard way — the first ban this driver hit
    would have swapped a suspended defender for the backup keeper.)
    """
    a = as_frame(img)
    bad = unavailable_rows(img)
    if not bad["xi"]:
        return None
    gk = _rol_mask(a, LINEUP_XI_Y[0])
    for block in ("subs", "reserves"):
        pool = LINEUP_SUB_Y if block == "subs" else LINEUP_RESERVE_Y
        for y in pool:
            if y not in bad[block] and _rol_mask(a, y) != gk:
                return (LINEUP_NAME_X, bad["xi"][0]), (LINEUP_NAME_X, y)
    return None


def identify(img: Image.Image, sigs: dict) -> tuple[str | None, float, list[tuple[str, float]]]:
    """Name the screen. Most-specific-wins when several signatures pass.

    A modal (MATCH OPTIONS, an alert box, the save dialog) leaves the screen under it
    intact, so the covered screen's signature still passes. Ranking the passing
    signatures by probe count makes the modal — taught over the panel it draws — win
    over the hub behind it. Give overlays a generous ROI for that reason.
    """
    scored = []
    for n, e in sigs["screens"].items():
        if "template" in e:
            hit = locate(img, e["template"]) is not None
            scored.append((n, 1.0 if hit else 0.0, e.get("weight", 10**6)))
        else:
            scored.append((n, score(img, e), len(e["probes"])))
    passing = [t for t in scored if t[1] >= MATCH_FRAC]
    ranked = sorted(scored, key=lambda t: (-t[1], -t[2]))
    if passing:
        best = max(passing, key=lambda t: (t[2], t[1]))
        return best[0], best[1], [(n, s) for n, s, _ in ranked[:5]]
    return None, (ranked[0][1] if ranked else 0.0), [(n, s) for n, s, _ in ranked[:5]]


# ------------------------------------------------------------------------- the drive


def run_probe(e: dict, probe: dict, outdir: Path, tag: str) -> None:
    """Detour off the drive to photograph a screen the career itself never raises.

    The European knockout view, the domestic cup tabs and the league tables are only
    reachable by walking into RESULTS and back; the sim never shows them unprompted. A
    probe is that walk, expressed as a click/snap list, fired every `every` visits of the
    `on` screen. Frames land in the drive's own output directory named for the probe step,
    so a whole season's worth of one screen is a `ls` away.
    """
    for i, act in enumerate(probe.get("steps", [])):
        if "click" in act:
            click(e, *act["click"], act.get("count", 1))
        time.sleep(act.get("settle", 1.2))
        if "snap" in act:
            grab(e, outdir / f"probe_{tag}_{i:02d}_{act['snap']}.png")


def run_plan(plan_path: Path, max_steps: int, settle: float) -> int:
    plan = json.loads(plan_path.read_text())
    sigs = load_sigs()
    e = env()
    outdir = e["out"] / plan.get("out", plan_path.stem)
    outdir.mkdir(parents=True, exist_ok=True)
    rules = plan["rules"]
    goal = plan.get("goal")
    keep = set(plan.get("keep", []))
    probe = plan.get("probe")
    probe_seen = 0
    log = []
    recent: list[str] = []
    unknown = 0
    last_screen = None
    repeat = 0

    for step in range(max_steps):
        shot = outdir / f"f{step:04d}.png"
        # A transition (the original wipes and cross-fades between screens) grabs as an
        # UNKNOWN frame that is not a screen at all. Re-grab before believing it.
        # The pre-match LINE-UPS reveal takes ~15 s to fill in, so give a frame that long
        # to become a screen before calling it unknown. An unknown frame is also the one
        # case where an animation may be playing (a cup-draw drum, a transition), and a
        # 1 fps retry loop cannot capture sprite order — so film it while we wait.
        film = None
        for attempt in range(plan.get("retries", 26)):
            img = grab(e, shot)
            name, best, ranked = identify(img, sigs)
            if name is not None:
                break
            if attempt == 0 and plan.get("film_unknown", True):
                film = subprocess.Popen(
                    ["bash", str(HERE / "film.sh"), f"unknown_{unknown:02d}",
                     str(plan.get("film_secs", 25)), "25"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            time.sleep(1.2)
        if film is not None:
            film.wait()
        log.append({"step": step, "screen": name, "score": round(best, 3)})
        print(f"[{step:4d}] {name or 'UNKNOWN'} ({best:.2f})", flush=True)

        if name is None:
            keeper = outdir / f"unknown_{unknown:02d}.png"
            shot.replace(keeper)
            (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
            print(f"UNKNOWN screen -> {keeper}; closest: "
                  + ", ".join(f"{n}={s:.2f}" for n, s in ranked), file=sys.stderr)
            return 2

        if plan.get("keep_all") or name in keep:
            shot.replace(outdir / f"keep_{step:04d}_{name}.png")
        elif shot.exists():
            shot.unlink()

        if goal and name == goal:
            (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
            print(f"GOAL {goal} reached at step {step}")
            return 0

        # A screen pair the drive cannot leave (hub -> alert -> hub ...) means the
        # original is refusing something; the plan names the way out.
        recent.append(name)
        del recent[:-6]
        breaker = plan.get("loop_breaker")
        if (
            breaker
            and len(recent) == 6
            and set(recent) == set(breaker["cycle"])
            and len(set(recent)) > 1
            and name == breaker.get("when", breaker["cycle"][0])
        ):
            print(f"   loop {'/'.join(breaker['cycle'])} -> {breaker['action']}", flush=True)
            recent.clear()
            act = breaker["action"]
            click(e, *act["click"], act.get("count", 1))
            time.sleep(act.get("settle", 2.0))
            continue

        if probe and name == probe.get("on", "hub"):
            probe_seen += 1
            if probe_seen % max(1, int(probe.get("every", 10))) == 0:
                print(f"   probe #{probe_seen // int(probe.get('every', 10))} at step {step}", flush=True)
                run_probe(e, probe, outdir, f"{step:04d}")

        rule = rules.get(name)
        if rule is None:
            (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
            print(f"no rule for known screen {name}", file=sys.stderr)
            return 3

        repeat = repeat + 1 if name == last_screen else 0
        last_screen = name
        if repeat > rule.get("max_repeat", 40):
            (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
            print(f"stuck on {name} for {repeat} steps", file=sys.stderr)
            return 4

        if "type" in rule:
            typetext(e, rule["type"])
        if rule.get("swap_unavailable"):
            # The original refuses to advance the week while an injured or banned player
            # is in the XI ("The initial line-up is not correct."). Swap him for the first
            # available substitute, the same two-click swap a human does.
            plan_pts = lineup_swap_plan(img)
            if plan_pts is None:
                print("   (no unavailable XI row to swap)", flush=True)
            else:
                click(e, *plan_pts[0])
                time.sleep(0.6)
                click(e, *plan_pts[1])
                time.sleep(0.6)
                img = grab(e, shot)
        if rule.get("click_alert_ok"):
            pt = alert_ok_point(img)
            if pt is None:
                (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
                print(f"could not find the alert OK button on {name}", file=sys.stderr)
                return 6
            click(e, pt[0], pt[1], rule.get("count", 1))
        if "click_template" in rule:
            # The alert box is centred on its own message, so its OK button moves with
            # the box height and width — find the button, do not assume its coordinates.
            hit = locate(img, rule["click_template"])
            if hit is None:
                (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
                print(f"template {rule['click_template']} not found on {name}", file=sys.stderr)
                return 6
            tw, th = Image.open(TEMPLATES / rule["click_template"]).size
            click(e, hit[0] + tw // 2, hit[1] + th // 2, rule.get("count", 1))
        if "click" in rule:
            cx, cy = rule["click"]
            click(e, cx, cy, rule.get("count", 1))
        for pt in rule.get("clicks", []):
            # A screen that needs a SEQUENCE (preseason: four SKIPs then CONTINUE) —
            # one point per entry, in order.
            click(e, int(pt[0]), int(pt[1]), int(pt[2]) if len(pt) > 2 else 1)
            time.sleep(0.5)
        time.sleep(rule.get("settle", settle))

    (outdir / "drive.json").write_text(json.dumps(log, indent=1) + "\n")
    print(f"max_steps {max_steps} exhausted", file=sys.stderr)
    return 5


# ------------------------------------------------------------------------------ main


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("learn")
    p.add_argument("name")
    p.add_argument("roi", help="X,Y,W,H")
    p.add_argument("frames", nargs="+", type=Path)
    p.add_argument("--step", type=int, default=LATTICE, help="lattice pitch inside the ROI")

    p = sub.add_parser("id")
    p.add_argument("--shot", default="id")
    p.add_argument("--frame", type=Path, help="identify a file instead of the live window")

    p = sub.add_parser("probe")
    p.add_argument("x", type=int)
    p.add_argument("y", type=int)
    p.add_argument("--frame", type=Path)

    p = sub.add_parser("shots")
    p.add_argument("dir", type=Path)

    p = sub.add_parser("click")
    p.add_argument("x", type=int)
    p.add_argument("y", type=int)
    p.add_argument("--count", type=int, default=1)

    p = sub.add_parser("snap")
    p.add_argument("name")

    p = sub.add_parser("run")
    p.add_argument("plan", type=Path)
    p.add_argument("--max-steps", type=int, default=4000)
    p.add_argument("--settle", type=float, default=0.6)

    a = ap.parse_args()

    if a.cmd == "learn":
        roi = tuple(int(v) for v in a.roi.split(","))
        if len(roi) != 4:
            raise SystemExit("roi must be X,Y,W,H")
        sigs = load_sigs()
        sigs["screens"][a.name] = learn(a.name, roi, a.frames, a.step)
        save_sigs(sigs)
        n = len(sigs["screens"][a.name]["probes"])
        print(f"{a.name}: {n} probes over roi {roi}")
        return 0

    if a.cmd == "probe":
        img = Image.open(a.frame).convert("RGB") if a.frame else grab(env(), env()["out"] / "probe.png")
        print(img.getpixel((a.x, a.y)))
        return 0

    if a.cmd == "id":
        sigs = load_sigs()
        if a.frame:
            img = Image.open(a.frame).convert("RGB")
        else:
            e = env()
            img = grab(e, e["out"] / f"{a.shot}.png")
        name, best, ranked = identify(img, sigs)
        print(f"{name or 'UNKNOWN'} {best:.3f}")
        for n, s in ranked:
            print(f"   {n:34s} {s:.3f}")
        return 0 if name else 1

    if a.cmd == "shots":
        sigs = load_sigs()
        for f in sorted(a.dir.glob("*.png")):
            img = Image.open(f).convert("RGB")
            name, best, _ = identify(img, sigs)
            print(f"{f.name:44s} {name or 'UNKNOWN':30s} {best:.3f}")
        return 0

    if a.cmd == "click":
        click(env(), a.x, a.y, a.count)
        return 0

    if a.cmd == "snap":
        e = env()
        grab(e, e["out"] / f"{a.name}.png")
        print(e["out"] / f"{a.name}.png")
        return 0

    if a.cmd == "run":
        return run_plan(a.plan, a.max_steps, a.settle)

    return 1


if __name__ == "__main__":
    sys.exit(main())
