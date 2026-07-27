#!/usr/bin/env python3
"""Write the walkthrough frame -> screen manifest the complete audit asked for.

`docs/re/AUDIT_COMPLETE_2026-07-26.md` recorded that the 2026-07-02 walkthrough has no
frame->screen index, so "which frame witnesses screen X" was answerable only by opening
638 PNGs, and ~81 % of them were never cited by any RE doc. This builds the index from
EVIDENCE rather than from memory: every frame is named by the SAME taught pixel
signatures the wine auto-driver uses (`tools/re/wine/screens.json`), so a name here means
that frame's chrome matched a signature learned from real frames of that screen.

    python3 tools/re/build_walkthrough_manifest.py [--dir <shots>] [--out <md>]

Frames that match nothing are listed as UNKNOWN with their best near-miss, which is the
useful half: an UNKNOWN run is either a screen the harness has never been taught or a
state no RE doc has claimed. Frames that are not 640x480 are reported separately rather
than skipped silently (the capture set carries a handful of desktop-sized shots).
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "re" / "wine"))

import autodrive  # noqa: E402  (path is set above)

DEFAULT_DIR = ROOT / "screenshots" / "original-walkthrough-2026-07-02"
DEFAULT_OUT = ROOT / "docs" / "re" / "WALKTHROUGH_MANIFEST.md"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", type=Path, default=DEFAULT_DIR)
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    a = ap.parse_args()
    if not a.dir.exists():
        print(f"no such directory: {a.dir}", file=sys.stderr)
        return 2

    sigs = autodrive.load_sigs()
    rows: list[tuple[str, str, float]] = []
    odd: list[tuple[str, str]] = []
    for p in sorted(a.dir.glob("*.png")):
        img = Image.open(p).convert("RGB")
        # The 2026-07-02 capture is 641x480: one extra border column on the right, which
        # every `diff_*_parity.py` in this repo already drops with `[:, :640]`. Do the
        # same here rather than call 636 of 638 frames "odd-sized".
        if img.size[1] == 480 and img.size[0] >= 640:
            img = img.crop((0, 0, 640, 480))
        if img.size != (640, 480):
            odd.append((p.name, f"{img.size[0]}x{img.size[1]}"))
            continue
        name, sc, ranked = autodrive.identify(img, sigs)
        if name is None:
            near = ranked[0] if ranked else ("-", 0.0)
            rows.append((p.name, f"UNKNOWN (best {near[0]} {near[1]:.2f})", near[1]))
        else:
            rows.append((p.name, name, sc))

    counts = Counter(r[1].split(" ")[0] for r in rows)
    known = sum(n for k, n in counts.items() if k != "UNKNOWN")

    # Second index, and the one the audit's "~81 % of frames are never cited" needs: which
    # RE docs name each frame. Docs cite frames by stem ("013_164406") or by bare index
    # ("frame 013"), so match on the stem and on the index with a `frame`/`p` lead-in.
    cited: dict[str, set[str]] = {n: set() for n, _, _ in rows}
    stem_of = {n: n[:-4] for n in cited}
    idx_of = {n: n.split("_")[0] for n in cited}
    # The manifest itself names every frame — exclude it, or the coverage reads 100 %.
    docs = [d for d in sorted((ROOT / "docs").rglob("*.md")) if d.resolve() != a.out.resolve()]
    for d in docs:
        try:
            body = d.read_text(errors="ignore")
        except OSError:
            continue
        rel = str(d.relative_to(ROOT))
        for n in cited:
            if stem_of[n] in body:
                cited[n].add(rel)
    for n in cited:  # index-only citations, e.g. "frame 013" / "witness 100"
        i = idx_of[n]
        for d in docs:
            rel = str(d.relative_to(ROOT))
            if rel in cited[n]:
                continue
            body = d.read_text(errors="ignore")
            for lead in ("frame %s" % i, "frames %s" % i, "witness %s" % i, "run-3 %s" % i):
                if lead in body:
                    cited[n].add(rel)
                    break
    n_cited = sum(1 for v in cited.values() if v)
    lines = [
        "# Walkthrough frame -> screen manifest (2026-07-02 capture)",
        "",
        "Status: GENERATED — rebuild with `python3 tools/re/build_walkthrough_manifest.py`.",
        "",
        "Every frame is named by the taught pixel signatures in `tools/re/wine/screens.json`",
        "(the wine auto-driver's own identifier), so a name here is a chrome match against",
        "signatures learned from real frames of that screen — not a guess and not a caption.",
        "This closes the `AUDIT_COMPLETE_2026-07-26.md` gap 'no frame->screen manifest'.",
        "",
        f"**{len(rows)} frames at 640x480** ({known} identified, "
        f"{counts.get('UNKNOWN', 0)} UNKNOWN)"
        + (f", **{len(odd)} at another size**." if odd else "."),
        "",
        "An UNKNOWN run is not noise: it is either a screen the harness has never been",
        "taught or a state no RE doc has claimed. Teach it with `autodrive.py learn` and",
        "it disappears from this list.",
        "",
        "## Frames per screen",
        "",
        "| screen | frames |",
        "|---|---|",
    ]
    for k, n in counts.most_common():
        lines.append(f"| `{k}` | {n} |")
    if odd:
        lines += ["", "## Not 640x480", "", "| frame | size |", "|---|---|"]
        lines += [f"| `{n}` | {s} |" for n, s in odd]
    lines += [
        "",
        "## Citation coverage",
        "",
        f"**{n_cited} of {len(rows)} frames are cited by at least one doc under `docs/`**"
        f" ({len(rows) - n_cited} uncited). A frame is counted as cited when a doc names",
        "its stem (`013_164406`) or its index behind a `frame` / `frames` / `witness` /",
        "`run-3` lead-in. The uncited set is where new evidence is cheapest to find: it is",
        "already captured, it is just unread.",
        "",
        "## Every frame",
        "",
        "| frame | screen | score | cited by |",
        "|---|---|---|---|",
    ]
    for n, s, v in rows:
        who = ", ".join(f"`{c}`" for c in sorted(cited[n])) if cited[n] else "—"
        lines.append(f"| `{n}` | {s} | {v:.3f} | {who} |")

    a.out.write_text("\n".join(lines) + "\n")
    print(f"wrote {a.out.relative_to(ROOT)}: {len(rows)} frames, {known} identified, "
          f"{counts.get('UNKNOWN', 0)} unknown, {len(odd)} odd-sized, {n_cited} cited")
    return 0


if __name__ == "__main__":
    sys.exit(main())
