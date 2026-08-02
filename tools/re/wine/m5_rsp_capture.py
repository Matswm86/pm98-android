#!/usr/bin/env python3
"""One-connection RSP capture: base verify/scan + frame0 poke + Z2 seed-watch roster dump.

Usage: m5_rsp_capture.py <port> <lpid> <ref_json> <out.jsonl> [stop_clk] [win_lo] [win_hi] [base_hex]

ptrace_scope=1-safe variant of m5_poke_frame0.py + m5_gdbrsp_dartwatch.py: ALL memory
access goes through the winedbg --gdb stub (wineserver-mediated RSP m/M packets), zero
/proc/<lpid>/mem reads — only /proc/<lpid>/maps (PTRACE_MODE_READ, not Yama-gated) for
the fallback vtable scan. Run at the KICK OFF screen (phase 2, clock frozen):
  1. verify the match base (vtable 0x6390e0 @ +0, scale 14400 @ +0x19ac); candidates
     first (arg / s34's 0x03dbf060), else scan rw regions via RSP.
  2. poke the frame0 ref scalars + LCG seed (m5_poke_frame0 --apply semantics: SKIP
     structural offsets, skip ptr-looking pairs) and re-verify.
  3. arm Z2 on the seed, then per STORE stop (eip != the 0x5ec255 entry-load twin)
     log clk/seed/ret0 and, while win_lo <= clk <= win_hi, all 22 players'
     [team, idx, x, y, +0x13c, +0x17c, +0x180, 0x34, 0x64, 0x68, 0x6c, 0x54, 0x58]
     plus the s53 gate tail [+0x184, +0x5c, +0x2b8, +0x2bc, +0x2d7, +0x2d8], the
     per-team header row "gs" (+0x1fc/+0x200/+0x204 designations resolved to
     [team, idx], + the +0x2ee freeze flag) and "sub_fa0" (FUN_005943b0's
     *(match+0x468)+0xfa0), plus the ball row (base+0x1610) with the s51 tail: the
     FUN_0058fda0 predicted trajectory buffer ball+0x114..0x1d4 (48 i32) + segments
     +0x74/78/7c. Exit once clk > stop_clk.
     The s53 fields are the FUN_005b1420 arm decision, byte for byte: the B0040 arm
     needs `p == *(gs+0x204) && *(ball+0x40) == 0`, and FUN_005a8f20 no-ops when
     +0x2d7 is already 1 — so they separate "b1420 picked a different arm" from
     "an earlier steer call consumed the once-per-tick guard".
Same stub gotchas as the seedwatch (see README.md): ONE connection, game dies if the
stub is killed — capture first, the game is expendable after.
"""

import json
import os
import struct
import sys
from pathlib import Path

from m5_gdbrsp_seedwatch import SEED_VA, Rsp

VTABLE = 0x6390E0
SCALE_OFF, SCALE_VAL = 0x19AC, 14400
SKIP = {0x0, 0x468, 0x46C, 0x470, 0x78C, 0x790, 0x1A5C}
PLAYER_STRIDE = 0x3BC
PBLOB = 0x188  # covers x/y (+4/+8), +0x13c/+0x17c/+0x180 and the team-header ptr +0x184
# s53 tail: the FUN_005b1420 gate inputs that are NOT in the head blob —
# +0x2b8 (team id, vs ball+0x54), +0x2bc (on-pitch), +0x2d7 (FUN_005a8f20 once-per-tick
# steer guard, cleared by the per-tick prologue FUN_005a4600), +0x2d8 (its sibling flag).
PTAIL_OFF, PTAIL_LEN = 0x2B8, 0x24
# s53: team-header (player+0x184) span covering the role slots +0x1fc/+0x200/+0x204
# (FUN_005b8a60 designations, player POINTERS) and the set-piece freeze flag +0x2ee.
GS_OFF, GS_LEN = 0x1FC, 0xF4
STORE_EIP_SKIP = 0x5EC255  # rand() entry LOAD twin stop — not the draw
MAX_STOPS = int(os.environ.get("PM98_MAX_STOPS", "40000"))  # s89: the 2837..8469
# window needs ~186,000 rand stops, so the old flat cap ENDED the run mid-window and
# reported 'done'. Raise it deliberately per run rather than silently truncating.


def looks_ptr(v: int) -> bool:
    return 0x00400000 <= v <= 0x7FFFFFFF and v % 4 == 0


def main() -> None:
    port, lpid, ref_path, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3], sys.argv[4]
    stop_clk = int(sys.argv[5]) if len(sys.argv) > 5 else 306
    win_lo = int(sys.argv[6]) if len(sys.argv) > 6 else 0
    win_hi = int(sys.argv[7]) if len(sys.argv) > 7 else 306
    cand = [int(sys.argv[8], 16)] if len(sys.argv) > 8 else []
    # Every base observed so far (README §RSP-only capture; s58 handoff: add each new
    # one here so the ~4-min HOT-band scan stays the safety net, not the path).
    cand += [0x03DBF060, 0x03DBF0D8, 0x03DBF228, 0x03DBF240, 0x03DCF1D0, 0x03DCF0D8]

    ref = json.load(open(ref_path))
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl
    r = Rsp(port)
    status = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": status}) + "\n")
    # winedbg's gdbproxy answers memory ops ONLY after Hg thread selection (probed
    # 2026-07-18: without it, 'm' never replies). Use the stop-status thread.
    import re as _re0

    tm = _re0.search(r"thread:([0-9a-fA-F]+);", status)
    if not tm:
        print(f"NO THREAD in status {status!r}", flush=True)
        sys.exit(1)
    hg = r.cmd(f"Hg{tm.group(1)}")
    fo.write(json.dumps({"event": "Hg", "tid": tm.group(1), "reply": hg}) + "\n")
    if hg != "OK":
        print(f"Hg REJECTED: {hg!r}", flush=True)
        sys.exit(1)

    def mread(addr: int, n: int) -> bytes:
        blob = b""
        while n > 0:
            k = min(n, 0x200)
            rep = r.cmd(f"m{addr:x},{k:x}", timeout=10)
            if not rep or rep.startswith("E"):
                raise OSError(f"mread {addr:#x},{k:#x} -> {rep!r}")
            b = bytes.fromhex(rep)
            blob += b
            addr += len(b)
            n -= len(b)
            if len(b) < k:
                raise OSError(f"short mread @{addr:#x}")
        return blob

    def u32(addr: int) -> int:
        return struct.unpack("<I", mread(addr, 4))[0]

    def w32(addr: int, v: int) -> None:
        rep = r.cmd(f"M{addr:x},4:{struct.pack('<I', v & 0xFFFFFFFF).hex()}")
        if rep != "OK":
            raise OSError(f"w32 {addr:#x} -> {rep!r}")

    # ---- 1. base ----
    base = 0
    for c in cand:
        try:
            if u32(c) == VTABLE and u32(c + SCALE_OFF) == SCALE_VAL:
                base = c
                break
        except OSError:
            continue
    if not base:
        needle = struct.pack("<I", VTABLE)
        spans = []
        for line in Path(f"/proc/{lpid}/maps").read_text().splitlines():
            addr, perms = line.split()[0], line.split()[1]
            start, end = (int(x, 16) for x in addr.split("-"))
            if perms.startswith("rw") and start < (1 << 32) and end - start <= 0x4000000:
                spans.append((start, end))
        # RSP `m` runs ~500 B per round trip, so a blind forward sweep of the heap costs ~20 min
        # per 2 MB (measured 2026-07-24, s53). Every observed base — 0x03dbf060 (s34),
        # 0x03dbf0d8 (s51), 0x03dcf1d0 (s53) — sits in [HOT_LO, HOT_HI), so probe that band
        # first inside each span, then fall back to the rest of the span.
        HOT_LO, HOT_HI = 0x03D00000, 0x03E00000
        spans.sort(key=lambda s: (not (0x03000000 <= s[0] < 0x05000000), s[0]))
        ranges = []
        for start, end in spans:
            hs, he = max(start, HOT_LO), min(end, HOT_HI)
            if hs < he:
                ranges.append((hs, he, True))
        ranges += [(s, e, False) for s, e in spans]
        for start, end, hot in ranges:
            print(f"scan {start:#010x}-{end:#010x}{' HOT' if hot else ''}", flush=True)
            a = start
            while a < end and not base:
                try:
                    data = mread(a, min(0x200, end - a))
                except OSError:
                    break
                i = data.find(needle)
                while i != -1:
                    b0 = a + i
                    try:
                        if u32(b0 + SCALE_OFF) == SCALE_VAL:
                            base = b0
                            break
                    except OSError:
                        pass  # candidate straddles the span end — not the match struct
                    i = data.find(needle, i + 1)
                a += 0x200 - 4  # overlap so a straddling needle is still found
            if base:
                break
    if not base:
        print("NO BASE", flush=True)
        sys.exit(1)
    fo.write(json.dumps({"event": "base", "base": hex(base)}) + "\n")
    print(f"BASE {base:#010x}", flush=True)

    # ---- 2. poke frame0 + seed ----
    # PM98_SEED overrides the reference frame-0 LCG seed. The rest of frame 0 (match scalars,
    # the 22 players, the session) is still the reference state, so the run stays the SAME
    # fixture and XI and only the RNG stream changes -- which is exactly the cross-seed sweep
    # the port can mirror (diag_m5_dart209.gd honours the same PM98_SEED).
    ref_seed = int(os.environ.get("PM98_SEED", "0"), 0) or ref["meta"]["seed_0x6d3184"]
    # PM98_NO_POKE=1 RESUMES a capture on a match that is ALREADY running from a poked frame 0
    # (s58: the stub died mid-run and took the python client with it, but the game itself kept
    # free-running the same deterministic trajectory). Re-poking there would overwrite live
    # state with frame-0 values and destroy the run, so skip the poke and the frame-0 XI check
    # and just re-arm the Z2 watch. Only ever use this on a game whose frame 0 WAS poked.
    resume = os.environ.get("PM98_NO_POKE") == "1"
    poked, skipped = [], []
    for off_s, ref_v in ({} if resume else ref["match"]).items():
        off = int(off_s, 16)
        live_v = u32(base + off)
        if live_v == (ref_v & 0xFFFFFFFF):
            continue
        if off in SKIP or (looks_ptr(ref_v) and looks_ptr(live_v)):
            skipped.append(off)
            continue
        w32(base + off, ref_v)
        poked.append(off)
    if not resume:
        w32(SEED_VA, ref_seed)
    post = sum(
        1 for off_s, v in ref["match"].items() if u32(base + int(off_s, 16)) == (v & 0xFFFFFFFF)
    )
    fo.write(
        json.dumps(
            {
                "event": "poke",
                "post_match": post,
                "total": len(ref["match"]),
                "poked": [hex(o) for o in poked],
                "skipped": [hex(o) for o in skipped],
                "seed": hex(u32(SEED_VA)),
            }
        )
        + "\n"
    )
    print(f"POKE {post}/{len(ref['match'])} seed={u32(SEED_VA):#010x}", flush=True)

    teams = []
    for off in (0x46C, 0x78C):
        teams.append((u32(base + off), min(u32(base + off + 4), 11)))
    # s53: the team-header object each player points at via +0x184 (FUN_005b1420 reads
    # its +0x204 designation and its +0x2ee freeze flag). Taken from player 0 of each
    # side and cross-checked against the whole XI — a split would mean the header model
    # is wrong and the designate rows below would be meaningless.
    hdrs, hdr_split = [], []
    for ti, (arr, cnt) in enumerate(teams):
        h0 = u32(arr + 0x184)
        hdrs.append(h0)
        for i in range(1, cnt):
            hi = u32(arr + i * PLAYER_STRIDE + 0x184)
            if hi != h0:
                hdr_split.append([ti, i, hex(hi), hex(h0)])
    fo.write(
        json.dumps(
            {
                "event": "teams",
                "arrays": [[hex(a), c] for a, c in teams],
                "headers": [hex(h) for h in hdrs],
                "header_split": hdr_split,
            }
        )
        + "\n"
    )
    print(f"HDRS {[hex(h) for h in hdrs]} split={len(hdr_split)}", flush=True)

    def resolve_p(ptr: int):
        """A raw player pointer -> [team, idx], or None when it is null/off-roster."""
        if not ptr:
            return None
        for ti, (arr, cnt) in enumerate(teams):
            d = ptr - arr
            if 0 <= d < cnt * PLAYER_STRIDE and d % PLAYER_STRIDE == 0:
                return [ti, d // PLAYER_STRIDE]
        return None

    def gs_rows() -> list:
        # Per team header: [hdr, +0x1fc, +0x200, +0x204 raw, resolved(+0x1fc/0x200/0x204),
        # +0x2ee]. +0x204 is the B0040 arm's designate (FUN_005b8a60's in-possession pick).
        rows = []
        for h in hdrs:
            b = mread(h + GS_OFF, GS_LEN)
            slots = [struct.unpack_from("<I", b, off - GS_OFF)[0] for off in (0x1FC, 0x200, 0x204)]
            rows.append(
                [
                    hex(h),
                    [hex(s) for s in slots],
                    [resolve_p(s) for s in slots],
                    b[0x2EE - GS_OFF],
                ]
            )
        return rows

    # ---- 2b. XI fidelity: live frame-0 players vs the reference (injury rolls between
    # runs can swap a starter -> different match; catch it BEFORE kick off) ----
    def ref_pf(src: dict, off: int) -> int:
        k = "0x%x" % off
        if k in src:
            return int(src[k]) & 0xFFFFFFFF
        return int(src.get("dwords", {}).get(k, 0)) & 0xFFFFFFFF

    xi_bad = []
    for ti, (arr, cnt) in enumerate([] if resume else teams):
        refs = ref["players"][ti]
        for i in range(min(cnt, len(refs))):
            b = mread(arr + i * PLAYER_STRIDE, PLAYER_STRIDE)
            for off in (0x4, 0x8, 0x2C8, 0x37C, 0x380):
                live_v = struct.unpack_from("<I", b, off)[0]
                if live_v != ref_pf(refs[i], off):
                    xi_bad.append([ti, i, hex(off), hex(live_v), hex(ref_pf(refs[i], off))])
    fo.write(json.dumps({"event": "xi_check", "mismatches": xi_bad}) + "\n")
    print(f"XI {'OK' if not xi_bad else 'MISMATCH %d rows' % len(xi_bad)}", flush=True)
    # A mismatch means a DIFFERENT match: even when the XI is the same eleven, the preseason
    # condition roll can move the derived pace/stamina (+0x37c/+0x380) and the sim forks from
    # tick 1 — s53 burned a full 20-min capture proving that (t1.i10's 0x34 ladder came out
    # 63979/58859 at clk 630 against the banked 18046/28286). Abort and re-roll the boot;
    # PM98_XI_FORCE=1 keeps the old behaviour when a run is deliberately off-reference.
    if xi_bad and os.environ.get("PM98_XI_FORCE") != "1":
        print("ABORT: re-roll the boot (or set PM98_XI_FORCE=1 to capture anyway)", flush=True)
        fo.write(json.dumps({"event": "abort", "why": "xi_mismatch"}) + "\n")
        sys.exit(2)

    # ---- 2c. THE FULL frame-0 player diff, and the poke (s90) ----
    # The five fields above are not enough, and s90 has the counter-example. A clean boot
    # passed `XI OK`, reproduced goal 1 BIT-EXACTLY — clk 2837, seed 1082620623, the banked
    # reference's own value — and then scored its second goal at **clk 4582 (2-0)** where
    # `capture2/timeline.jsonl` has **clk 7805 (1-1)**. Identical RNG state at goal 1 and a
    # different match after it: something outside those five fields, and outside the 86 match
    # scalars, differs at frame 0 and only starts to matter once the restart repositions the
    # 22 players.
    #
    # So the check is widened to EVERY dumped field of every player, both team headers, both
    # keepers and the session, and `PM98_POKE_PLAYERS=1` writes them the way the match
    # scalars are already written. Pointer-looking pairs are skipped on both sides (they are
    # per-boot addresses), as is `_va` itself.
    # The team-header dump stores `0x2ec` and `0x2ed` as single BYTES, not dwords — and
    # `0x2ec` is dword-aligned, so the alignment filter below does not catch it. Comparing
    # the live dword there against a byte is apples to oranges: it reported hdr1 as the one
    # "mismatch" of the whole frame-0 diff purely because the live `+0x2ee` set-piece freeze
    # byte sits in the same dword and the dump does not record `0x2ee` at all.
    BYTE_FIELDS = {"0x2ec", "0x2ed"}

    def _fields(src: dict, drop: set | None = None) -> dict:
        # `dwords` is the whole record where the dump has one (a player's is 0x0..0x3b8
        # contiguous, i.e. the entire 0x3bc stride). Unaligned keys are BYTE fields in the
        # dump — 0x63 / 0x2d5 / 0x2d9 and friends — and reading a dword there mixes three
        # neighbours, so they are dropped rather than compared as dwords. `drop` handles the
        # ALIGNED byte fields, which only the team headers have; a player's 0x2ec is a real
        # dword and must not be dropped with them.
        d = dict(src.get("dwords", src))
        return {
            k: v
            for k, v in d.items()
            if k.startswith("0x") and int(k, 16) % 4 == 0 and not (drop and k in drop)
        }

    poke_players = os.environ.get("PM98_POKE_PLAYERS") == "1"
    full_bad: list = []
    full_poked = 0
    if not resume:
        targets: list[tuple[str, int, dict]] = []
        for ti, (arr, cnt) in enumerate(teams):
            refs = ref["players"][ti]
            for i in range(min(cnt, len(refs))):
                targets.append((f"p{ti}.{i}", arr + i * PLAYER_STRIDE, _fields(refs[i])))
        for ti, h in enumerate(hdrs):
            targets.append((f"hdr{ti}", h, _fields(ref["team_headers"][ti], BYTE_FIELDS)))
        # `_va` in the dump is the REFERENCE boot's address and is useless here — every one
        # of these objects moves with the boot. The ball is `base + 0x1610` (the same address
        # `ball_row` reads) and the session is `*(base + 0x468)`. Using the stored `_va`
        # reported 32 phantom ball mismatches on the first run, measured 2026-08-02.
        targets.append(("ball", base + 0x1610, _fields(ref.get("ball") or {})))
        try:
            targets.append(("session", u32(base + 0x468), _fields(ref.get("session") or {})))
        except OSError:
            pass
        # The two KEEPER objects are in the dump but not in this list: their live address is
        # not derivable from `base` by anything read so far, and guessing one would compare
        # against whatever happens to sit there. Named as a gap rather than approximated.
        # ONE mread per object, not one per field. A player record is 239 dwords and there are
        # 22 of them, so the naive `u32` loop is ~5,300 RSP round trips and took over a
        # quarter of an hour on the first run; the whole span is 22 reads of 0x200 apiece.
        for name, base_addr, flds in targets:
            if not flds:
                continue
            span = max(int(k, 16) for k in flds) + 4
            try:
                blob = mread(base_addr, span)
            except OSError:
                blob = b""
            for off_s, ref_v in flds.items():
                off = int(off_s, 16)
                if off + 4 > len(blob):
                    continue
                live_v = struct.unpack_from("<I", blob, off)[0]
                ref_u = int(ref_v) & 0xFFFFFFFF
                if live_v == ref_u or (looks_ptr(ref_u) and looks_ptr(live_v)):
                    continue
                full_bad.append([name, off_s, hex(live_v), hex(ref_u)])
                if poke_players:
                    try:
                        w32(base_addr + off, ref_u)
                        full_poked += 1
                    except OSError:
                        pass
    fo.write(
        json.dumps(
            {
                "event": "frame0_full_diff",
                "mismatches": len(full_bad),
                "poked": full_poked,
                "rows": full_bad[:200],
            }
        )
        + "\n"
    )
    print(
        f"FRAME0 FULL DIFF {len(full_bad)} mismatched fields"
        + (f", poked {full_poked}" if poke_players else " (not poked; PM98_POKE_PLAYERS=1)"),
        flush=True,
    )

    def players_row() -> list:
        # Row: [team, idx, x, y, +0x13c, +0x17c, +0x180, face+0x34, yaw+0x64, spd+0x68,
        # curve+0x6c, +0x54, +0x58]. The first 7 keep the s44 layout (orbit_diff reads
        # r[0..3] positionally); the s45 tail adds the mover state for the sub-LSB drill;
        # the s53 tail (13..18) adds the FUN_005b1420 / FUN_005a8f20 gate inputs
        # [hdr+0x184, lock+0x5c, team+0x2b8, onpitch+0x2bc, guard+0x2d7, +0x2d8].
        rows = []
        for ti, (arr, cnt) in enumerate(teams):
            for i in range(cnt):
                p = arr + i * PLAYER_STRIDE
                b = mread(p, PBLOB)
                t = mread(p + PTAIL_OFF, PTAIL_LEN)
                rows.append(
                    [
                        ti,
                        i,
                        struct.unpack_from("<i", b, 4)[0],
                        struct.unpack_from("<i", b, 8)[0],
                        struct.unpack_from("<I", b, 0x13C)[0],
                        struct.unpack_from("<i", b, 0x17C)[0],
                        struct.unpack_from("<i", b, 0x180)[0],
                        struct.unpack_from("<I", b, 0x34)[0] & 0xFFFF,
                        struct.unpack_from("<I", b, 0x64)[0] & 0xFFFF,
                        struct.unpack_from("<i", b, 0x68)[0],
                        struct.unpack_from("<i", b, 0x6C)[0],
                        struct.unpack_from("<i", b, 0x54)[0],
                        struct.unpack_from("<i", b, 0x58)[0],
                        struct.unpack_from("<I", b, 0x184)[0],
                        b[0x5C],
                        struct.unpack_from("<i", t, 0x2B8 - PTAIL_OFF)[0],
                        struct.unpack_from("<i", t, 0x2BC - PTAIL_OFF)[0],
                        t[0x2D7 - PTAIL_OFF],
                        t[0x2D8 - PTAIL_OFF],
                    ]
                )
        return rows

    def ball_row() -> list:
        # s46 sub-LSB drill: the ball struct is the m+0x1610 embedding (ball+0x40 is the
        # carrier ptr the port mirrors as m[0x1650]). Row: [x, y, z, vx, vy, vz, face34,
        # carrier40, recv4c, own54, +0x58, N5c] — pos/vel signed, ptrs raw u32.
        # s51 tail (indices 12..62): the FUN_0058fda0 predicted-trajectory buffer that
        # feeds the b0040 interception bisection — ball+0x114..0x1d4 (16 vec3, stride 12
        # = 48 i32) then the 3 bounce-segment lengths ball+0x74/0x78/0x7c. Read WHOLE so
        # the capture decides whether silicon's marker ladder differs at the clk-639 fork.
        b = mread(base + 0x1610, 0x1E0)  # 0x1610..0x17f0 covers 0x0..0x1d4 + segments
        row = [
            struct.unpack_from("<i", b, 0x4)[0],
            struct.unpack_from("<i", b, 0x8)[0],
            struct.unpack_from("<i", b, 0xC)[0],
            struct.unpack_from("<i", b, 0x20)[0],
            struct.unpack_from("<i", b, 0x24)[0],
            struct.unpack_from("<i", b, 0x28)[0],
            struct.unpack_from("<I", b, 0x34)[0] & 0xFFFF,
            struct.unpack_from("<I", b, 0x40)[0],
            struct.unpack_from("<I", b, 0x4C)[0],
            struct.unpack_from("<i", b, 0x54)[0],
            struct.unpack_from("<i", b, 0x58)[0],
            struct.unpack_from("<i", b, 0x5C)[0],
        ]
        row += [struct.unpack_from("<i", b, 0x114 + 4 * k)[0] for k in range(48)]
        row += [struct.unpack_from("<i", b, off)[0] for off in (0x74, 0x78, 0x7C)]
        return row

    # ---- 2b. the ALIASING table, read on this same connection (s89) ----
    # `DAT_006b5890` is the 8,192-entry edge-classifier table `FUN_005d60a0` looks each
    # 13-bit neighbourhood code up in, and `DAT_006b7920` is the graphics-init's run-once
    # guard. Both are .bss, so a static read cannot answer what they hold at runtime, and
    # the stub takes exactly ONE connection — so the read rides along with the capture
    # rather than costing its own boot. 8 KB is ~16 round trips.
    try:
        guard = mread(0x6B7920, 1)[0]
        alias = mread(0x6B5890, 0x2000)
        Path(out).with_suffix(".aliasing.bin").write_bytes(alias)
        fo.write(json.dumps({
            "event": "aliasing", "guard": guard, "nonzero": sum(1 for b in alias if b),
            "distinct": len(set(alias)),
        }) + "\n")
        print(f"ALIASING guard={guard} nonzero={sum(1 for b in alias if b)}/8192 "
              f"distinct={len(set(alias))}", flush=True)
    except OSError as exc:  # a read failure must not cost the capture
        fo.write(json.dumps({"event": "aliasing_failed", "err": str(exc)}) + "\n")

    def t_regs(st: str) -> dict:
        import re as _re

        o = {}
        for m in _re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", st):
            o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return o

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    # ---- 3. RUN-UP on the CLOCK, then Z2 seed watch (s89) ----
    # The seed watchpoint traps every rand() draw — about 33 stops per clock tick — so
    # reaching a window that starts at clk 2837 costs ~94,000 stops of pure fast-forward
    # before the first row worth keeping. That is why the 2837..8469 capture had never
    # been run. The clock at `base+0x450` moves ONCE per frame, so watching IT instead
    # costs one stop per tick. The watchpoint is an observation, not a game input:
    # swapping which address is watched cannot change what the match computes.
    if win_lo > 2:
        ok = r.cmd(f"Z2,{base + 0x450:x},4")
        fo.write(json.dumps({"event": "Z2_clock", "reply": ok}) + "\n")
        if ok != "OK":
            print(f"Z2 clock REJECTED: {ok!r}", flush=True)
            sys.exit(1)
        print(f"RUN-UP on the clock to clk {win_lo} — click KICK OFF", flush=True)
        cont()
        runup = 0
        while True:
            try:
                r.wait_stop()
            except ConnectionError:
                fo.write(json.dumps({"event": "stub_closed_runup"}) + "\n")
                return
            runup += 1
            clk = u32(base + 0x450)
            if runup % 200 == 0:
                print(f"run-up {runup} clk={clk}", flush=True)
            if clk >= win_lo - 1:
                break
            cont()
        fo.write(json.dumps({"event": "runup_done", "stops": runup, "clk": clk}) + "\n")
        print(f"RUN-UP done at clk={clk} after {runup} stops", flush=True)
        # ⚠ Do NOT `z2` the clock watchpoint away. Measured 2026-08-02: the winedbg stub
        # CLOSES THE CONNECTION on the remove, which kills the game — the run-up reached
        # clk 2836 in 17,298 stops (against ~94,000 on the seed) and then died on the
        # tidy-up. Leaving it armed costs one extra stop per frame, ~3% on top of the
        # ~33 rand draws a tick, and every row carries its own `eip` so the clock stops
        # are trivially separable in the diff.

        # PM98_CLK_TRACE=1 (s90): stay on the CLOCK watchpoint for the whole window and
        # log one cheap row per frame instead of arming the seed. A full in-window row
        # costs ~44 RSP round trips (22 players + gs + ball) and s59 measured the result
        # at ~1 clk / 9 s, so 2837..8469 is ~14 h of wall clock. The FIRST disagreeing
        # frame does not need any of that: the port's own PM98_SEEDTRACE emits
        # "step clk banked half rng.state" per outer step, and one outer step is one
        # frame under play-state 2, so (clk, seed) per frame is directly comparable and
        # brackets the divergence in ~5,600 stops. Localise cheap, then re-capture the
        # narrow window with the full rows.
        if os.environ.get("PM98_CLK_TRACE") == "1":
            print(f"CLK-TRACE {win_lo}..{stop_clk} on the clock watchpoint", flush=True)
            frames = 0
            while True:
                cont()
                try:
                    st = r.wait_stop()
                except ConnectionError:
                    fo.write(json.dumps({"event": "stub_closed_clktrace"}) + "\n")
                    break
                frames += 1
                clk = u32(base + 0x450)
                fo.write(json.dumps({
                    "f": frames, "clk": clk, "seed": u32(SEED_VA),
                    "banked": u32(base + 0x19A8), "half": u32(base + 0x19A0),
                    "ph": u32(base + 0x448), "disp": u32(base + 0x1A38),
                    "sc": [u32(base + 0x478), u32(base + 0x798)],
                    "eip": hex(t_regs(st).get(8, 0)),
                }) + "\n")
                if frames % 200 == 0:
                    print(f"clk-trace f={frames} clk={clk}", flush=True)
                if clk > stop_clk or frames >= MAX_STOPS:
                    fo.write(json.dumps({
                        "event": "clktrace_done", "frames": frames, "clk": clk}) + "\n")
                    print(f"CLK-TRACE done f={frames} clk={clk}", flush=True)
                    break
            return

    ok = r.cmd(f"Z2,{SEED_VA:x},4")
    fo.write(json.dumps({"event": "Z2", "reply": ok}) + "\n")
    if ok != "OK":
        print(f"Z2 REJECTED: {ok!r}", flush=True)
        sys.exit(1)

    print(
        f"ARMED @{SEED_VA:#x} win=[{win_lo},{win_hi}] stop_clk={stop_clk}"
        + ("" if win_lo > 2 else " — click KICK OFF"),
        flush=True,
    )
    cont()
    stops = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        stops += 1
        rg = t_regs(st)
        eip = rg.get(8, 0)
        esp = rg.get(4, 0)
        if eip == STORE_EIP_SKIP:
            cont()
            continue
        clk = u32(base + 0x450)
        try:
            ret0 = u32(esp)
        except OSError:
            ret0 = 0
        row = {"stop": stops, "eip": hex(eip), "ret0": hex(ret0), "clk": clk, "seed": u32(SEED_VA)}
        if win_lo <= clk <= win_hi:
            row["pl"] = players_row()
            row["ball"] = ball_row()
            row["gs"] = gs_rows()
            # FUN_005943b0(m) == (*(match+0x468) + 0xfa0) == 0 — the b1420 freeze predicate.
            try:
                row["sub_fa0"] = u32(u32(base + 0x468) + 0xFA0)
            except OSError:
                row["sub_fa0"] = None
        fo.write(json.dumps(row) + "\n")
        if stops % 100 == 0:
            print(f"stop {stops} clk={clk}", flush=True)
        if clk > stop_clk or stops >= MAX_STOPS:
            fo.write(json.dumps({"event": "done", "stops": stops, "clk": clk}) + "\n")
            break
        cont()

    try:
        r.cmd(f"z2,{SEED_VA:x},4", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach; capture is already on disk
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE stops={stops} -> {out}", flush=True)


if __name__ == "__main__":
    main()
