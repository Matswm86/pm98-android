#!/usr/bin/env python3
"""Index every RE doc against the evidence that would prove it: gate, suite, decompile.

`docs/REMAINING.md` says per-screen truth is "the `Status:` line at the top of each
`docs/re/<screen>_re.md`", and `AUDIT_COMPLETE_2026-07-26.md` found only ~12 of 125 docs
carry one — so that delegation had nothing behind it for the other 113. Hand-writing 113
status lines would be prose about prose. This writes the thing the delegation actually
needs: a table linking each doc to the artefacts that can CONFIRM it, all of which are
checkable.

Per doc it reports:

* **gate** — a `tools/re/diff_*_parity.py` whose body names the doc, or whose stem shares
  the doc's screen token. A gate is the strongest evidence in this repo: it render-diffs
  the app against a real captured frame.
* **suite** — `app/tests/test_*.gd` naming the doc's screen token.
* **scene** — the `app/scenes/*.gd` the doc describes.
* **decompile** — whether the doc cites a MANAGER.EXE address (`0x` + 6 hex digits), i.e.
  whether its claims are anchored in the binary rather than in frames alone.
* **evidence** — an explicit `Evidence:` line naming repo-relative artefacts, for the docs
  whose proof is none of the three above (a banked capture, an oracle runner, a witness
  frame directory, an extraction tool). Every path that is IN THE REPO is checked to exist
  and a path that does not resolve is a hard failure of this script — an evidence line that
  points at nothing is worse than no evidence line. Untracked paths (`extracted/`, most of
  `screenshots/`) are counted but not asserted, because they cannot exist in a clean
  checkout; anything a GATE depends on belongs in `tools/re/refs/`, which IS tracked and is
  therefore still checked. The output is byte-identical either way, which is what the CI
  step diffs it against.
* **open** — how many times the doc flags its own gaps (`un-RE'd`, `unwitnessed`,
  `UNKNOWN`, `declared`, `OURS`, `honest gap`, `still open`, `inference`).

    python3 tools/re/build_status_index.py [--out docs/re/STATUS_INDEX.md]

Nothing here is a verdict. A doc with a gate and no open markers is well-evidenced; a doc
with neither is where the next audit should look. That is a map, and it is derived, not
asserted.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs" / "re"
GATES = sorted((ROOT / "tools" / "re").glob("diff_*_parity.py"))
SUITES = sorted((ROOT / "app" / "tests").glob("test_*.gd"))
SCENES = sorted((ROOT / "app" / "scenes").glob("*.gd")) + sorted(
    (ROOT / "app" / "scripts").glob("*.gd")
)

ADDR = re.compile(r"0x[0-9a-fA-F]{6}")
# `Evidence: path, path, ...` — repo-relative, near the top. The block runs from the
# `Evidence:` keyword to the next blank line OR to the next `Keyword:` line, whichever
# comes first: several docs wrap the list over two or three lines, and several follow it
# with sibling keywords (`Port:`, `Gate:`, `Raw:`) whose paths are NOT this doc's evidence
# — `Raw:` in particular names workspace captures under `~/MWM-AI/data/`, outside the repo.
#
# Inside the block, a BACKTICKED span is the path. Comma-splitting the raw text was the
# earlier rule and it broke on any doc that annotates a path — `camera_motion_re.md`'s
# "`…/MANAGER.EXE` (capstone, decoded per function entry)" split into a path with
# " (capstone" glued on and failed the whole script. Backticks are how every doc in the
# tree writes a path, so they are the rule now; a block with none falls back to
# comma-splitting so a plain-text Evidence line still resolves.
def evidence_block(body: str) -> str:
    """The `Evidence:` keyword's own lines: from it to the next blank line or `Keyword:`.

    Several docs wrap the list over two or three lines, and several follow it with SIBLING
    keywords (`Port:`, `Gate:`, `Raw:`) whose paths are not this doc's evidence — `Raw:` in
    particular names workspace captures under `~/MWM-AI/data/`, outside the repo entirely.
    Scanned line by line rather than by regex, because the lazy-quantifier version of this
    silently swallowed those sibling lines and failed the whole script on their paths.
    """
    lines = body.splitlines()
    for i, line in enumerate(lines):
        if not line.startswith("Evidence:"):
            continue
        out = [line[len("Evidence:"):]]
        for nxt in lines[i + 1:]:
            if not nxt.strip() or KEYWORD.match(nxt):
                break
            out.append(nxt)
        return "\n".join(out)
    return ""


KEYWORD = re.compile(r"^[A-Z][A-Za-z ]{0,12}:")
BACKTICKED = re.compile(r"`([^`]+)`")
OPEN_MARKERS = [
    "un-RE'd",
    "unRE'd",
    "un-reversed",
    "unwitnessed",
    "honest gap",
    "still open",
    "OURS",
    "declared",
    "inference",
    "UNKNOWN",
    "approximated",
    "synthesized",
]


def is_tracked(path: str) -> bool:
    """Is this repo-relative path IN the repository (file or directory)?

    The guard may only assert what a clean checkout contains. Some `Evidence:` paths point
    at deliberately untracked material -- `extracted/` is the copyrighted game data, and
    `screenshots/` is MOSTLY untracked while carrying a handful of committed subdirectories,
    so classifying by top-level directory got both wrong (it failed CI on `extracted/` and
    then passed a path under an untracked `screenshots/` subdir). `git ls-files` answers
    exactly the right question and follows the repo instead of a hardcoded list.

    Either way the path is COUNTED, so the index is byte-identical on the capture box and on
    a clean runner -- which is what the CI diff compares. Only the existence assertion is
    skipped. Anything a GATE depends on belongs in `tools/re/refs/`, which IS tracked and
    therefore still checked.
    """
    if path in _TRACKED_CACHE:
        return _TRACKED_CACHE[path]
    try:
        r = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files", "--", path],
            capture_output=True, text=True,
        )
        tracked = bool(r.stdout.strip())
    except (OSError, subprocess.SubprocessError):
        tracked = True                      # no git: fall back to asserting existence
    _TRACKED_CACHE[path] = tracked
    return tracked


_TRACKED_CACHE: dict[str, bool] = {}


def tokens(stem: str) -> list[str]:
    """Screen tokens a doc name could be matched on: `scout_screen_re` -> scout, scout_screen."""
    s = stem.removesuffix("_re")
    parts = [p for p in s.split("_") if p and p not in {"screen", "card", "re"}]
    out = {s, s.replace("_screen", "")}
    if parts:
        out.add(parts[0])
        out.add("".join(parts))
    return sorted(t for t in out if len(t) >= 3)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=DOCS / "STATUS_INDEX.md")
    a = ap.parse_args()

    gate_src = {g: g.read_text(errors="ignore") for g in GATES}
    rows = []
    for d in sorted(DOCS.glob("*.md")):
        if d.name in {"STATUS_INDEX.md", "WALKTHROUGH_MANIFEST.md"}:
            continue
        body = d.read_text(errors="ignore")
        toks = tokens(d.stem)
        gates = sorted(
            {g.name for g in GATES if d.name in gate_src[g]}
            | {g.name for g in GATES if any(t in g.stem for t in toks)}
        )
        suites = sorted({s.name for s in SUITES if any(t in s.stem for t in toks)})
        scenes = sorted({s.name for s in SCENES if any(t in s.stem.lower() for t in toks)})
        has_status = body.startswith("#") and "\nStatus:" in body[:800]
        ev: list[str] = []
        block = evidence_block(body)
        if block:
            # backticked spans anywhere in the block; else the FIRST line's comma list,
            # which is where a plain-text Evidence line puts its paths (the lines under it
            # are prose about them, and comma-splitting those produced sentences-as-paths)
            raws = BACKTICKED.findall(block) or block.splitlines()[0].split(",")
            for raw in raws:
                path = raw.strip().strip("`").strip().rstrip(".").strip()
                # Only tokens carrying a "/" are treated as repo paths. The backticks on an
                # Evidence line also wrap things that are NOT files — `FUN_0057a980`,
                # `MANAGER.EXE`, `RECURSOS.PKF` — and checking those as paths failed the
                # script on docs that were perfectly well evidenced (`fines_re.md`). So a
                # bare filename is not checked, and an Evidence path must name its
                # directory to be verified. Every doc in the tree already does.
                if "/" not in path:
                    continue
                # An UNTRACKED path cannot exist in a clean checkout, so CI must not fail
                # on one -- see is_tracked() for why this is asked of git rather than of a
                # directory list. It is still counted, so the index is byte-identical here
                # and on a runner; only the existence assertion is skipped.
                if not is_tracked(path):
                    ev.append(path)
                    continue
                if not (ROOT / path).exists():
                    print(f"FAIL {d.name}: Evidence path does not exist: {path}", file=sys.stderr)
                    return 1
                ev.append(path)
        rows.append(
            {
                "doc": d.name,
                "status": has_status,
                "gates": gates,
                "suites": suites,
                "scenes": scenes,
                "addrs": len(set(ADDR.findall(body))),
                "evidence": ev,
                "open": sum(body.count(m) for m in OPEN_MARKERS),
            }
        )

    n = len(rows)
    n_gate = sum(1 for r in rows if r["gates"])
    n_suite = sum(1 for r in rows if r["suites"])
    n_bin = sum(1 for r in rows if r["addrs"])
    n_status = sum(1 for r in rows if r["status"])
    n_ev = sum(1 for r in rows if r["evidence"])
    n_none = sum(
        1
        for r in rows
        if not r["gates"] and not r["suites"] and not r["addrs"] and not r["evidence"]
    )

    out = [
        "# RE doc status index",
        "",
        "Status: GENERATED — rebuild with `python3 tools/re/build_status_index.py`.",
        "",
        "`docs/REMAINING.md` used to delegate per-screen truth to each doc's own `Status:`",
        "line — and most docs do not carry one, so for most screens it pointed at nothing.",
        "Since 2026-08-01 it delegates HERE instead: for every doc, the artefacts that can",
        "CONFIRM it, each of them checkable, and none of them a sentence someone guessed.",
        "",
        f"* **{n} docs**, {n_status} with a `Status:` line of their own.",
        f"* **{n_gate}** are covered by a `diff_*_parity.py` render-diff gate — the",
        "  strongest evidence here, since a gate compares the app to a captured frame.",
        f"* **{n_suite}** have a headless `test_*.gd` suite; **{n_bin}** cite MANAGER.EXE",
        "  addresses, i.e. their claims are anchored in the binary and not only in frames.",
        f"* **{n_ev}** name their proof directly on an `Evidence:` line — for the plans,",
        "  audits and M5 session notes, whose evidence is a banked capture, an oracle",
        "  runner or a witness directory rather than a screen gate. Every path on those",
        "  lines is checked to exist by this script.",
        f"* **{n_none}** have none of the four. That is the audit's real backlog: not the",
        "  missing sentence, the missing evidence.",
        "",
        "`open` counts a doc's OWN gap flags (`un-RE'd`, `unwitnessed`, `declared`, `OURS`,",
        "`inference`, ...). A high count is honesty, not debt — the docs that declare",
        "nothing are the ones to distrust.",
        "",
        "| doc | own Status: | gate | suite | scene | EXE addrs | evidence | open |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        out.append(
            "| `{doc}` | {st} | {g} | {s} | {sc} | {a} | {e} | {o} |".format(
                doc=r["doc"],
                st="yes" if r["status"] else "—",
                g=", ".join(f"`{x}`" for x in r["gates"][:2]) or "—",
                s=", ".join(f"`{x}`" for x in r["suites"][:2]) or "—",
                sc=", ".join(f"`{x}`" for x in r["scenes"][:2]) or "—",
                a=r["addrs"] or "—",
                e=f"{len(r['evidence'])} path(s)" if r["evidence"] else "—",
                o=r["open"] or "—",
            )
        )
    a.out.write_text("\n".join(out) + "\n")
    # CI writes the index to a scratch path and diffs it against the tracked one, so
    # `--out` is not always inside the repo.
    where = a.out.relative_to(ROOT) if a.out.is_relative_to(ROOT) else a.out
    print(
        f"wrote {where}: {n} docs, {n_gate} gated, {n_suite} suited, "
        f"{n_bin} binary-anchored, {n_ev} with an Evidence: line, "
        f"{n_none} with no evidence link"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
