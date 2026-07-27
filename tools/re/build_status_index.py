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
OPEN_MARKERS = [
    "un-RE'd", "unRE'd", "un-reversed", "unwitnessed", "honest gap", "still open",
    "OURS", "declared", "inference", "UNKNOWN", "approximated", "synthesized",
]


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
        rows.append({
            "doc": d.name,
            "status": has_status,
            "gates": gates,
            "suites": suites,
            "scenes": scenes,
            "addrs": len(set(ADDR.findall(body))),
            "open": sum(body.count(m) for m in OPEN_MARKERS),
        })

    n = len(rows)
    n_gate = sum(1 for r in rows if r["gates"])
    n_suite = sum(1 for r in rows if r["suites"])
    n_bin = sum(1 for r in rows if r["addrs"])
    n_status = sum(1 for r in rows if r["status"])
    n_none = sum(1 for r in rows if not r["gates"] and not r["suites"] and not r["addrs"])

    out = [
        "# RE doc status index",
        "",
        "Status: GENERATED — rebuild with `python3 tools/re/build_status_index.py`.",
        "",
        "`docs/REMAINING.md` delegates per-screen truth to each doc's own `Status:` line,",
        "and the 2026-07-26 complete audit found only ~12 of 125 docs carry one. This is",
        "what that delegation needs instead of 113 hand-written sentences: for every doc,",
        "the artefacts that can CONFIRM it, each of them checkable.",
        "",
        f"* **{n} docs**, {n_status} with a `Status:` line of their own.",
        f"* **{n_gate}** are covered by a `diff_*_parity.py` render-diff gate — the",
        "  strongest evidence here, since a gate compares the app to a captured frame.",
        f"* **{n_suite}** have a headless `test_*.gd` suite; **{n_bin}** cite MANAGER.EXE",
        "  addresses, i.e. their claims are anchored in the binary and not only in frames.",
        f"* **{n_none}** have none of the three. That is the audit's real backlog: not the",
        "  missing sentence, the missing evidence.",
        "",
        "`open` counts a doc's OWN gap flags (`un-RE'd`, `unwitnessed`, `declared`, `OURS`,",
        "`inference`, ...). A high count is honesty, not debt — the docs that declare",
        "nothing are the ones to distrust.",
        "",
        "| doc | own Status: | gate | suite | scene | EXE addrs | open |",
        "|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        out.append(
            "| `{doc}` | {st} | {g} | {s} | {sc} | {a} | {o} |".format(
                doc=r["doc"],
                st="yes" if r["status"] else "—",
                g=", ".join(f"`{x}`" for x in r["gates"][:2]) or "—",
                s=", ".join(f"`{x}`" for x in r["suites"][:2]) or "—",
                sc=", ".join(f"`{x}`" for x in r["scenes"][:2]) or "—",
                a=r["addrs"] or "—",
                o=r["open"] or "—",
            )
        )
    a.out.write_text("\n".join(out) + "\n")
    print(f"wrote {a.out.relative_to(ROOT)}: {n} docs, {n_gate} gated, {n_suite} suited, "
          f"{n_bin} binary-anchored, {n_none} with no evidence link")
    return 0


if __name__ == "__main__":
    sys.exit(main())
