#!/usr/bin/env python3
"""Poll the live MANAGER.EXE match struct + BALL/CARRIER trajectory to a JSONL timeline.

Usage: m5_poll_traj.py <lpid> <match_base_hex> <out.jsonl> [stop_clk]

Superset of m4_poll.py (the M4 oracle reference poller): it keeps every match-scalar
field m4 tracked, and ADDS the ball kinematics and the ball CONTROLLER (carrier) so the
M5-divergence disambiguation has the REAL per-tick carrier downfield trajectory to diff
against the port CSV (scratchpad m5_tick_trace.csv). See
docs/re/M5_DIVERGENCE1_OPENPLAY_TRACE.md and the s21 findings doc.

s29 (clk-9 disambiguation, M5_DIVERGENCE_CLK9_EXTRA_DRAW.md NEXT):
  * every row now carries `q60` = ball bytes 0x00..0x63 hex (covers +0x40 carrier VA and
    +0x4c receiver VA, which the old 0x00..0x3f capture2 blob missed);
  * BURST window while clk <= BURST_CLK (24): NO sleep between polls (the game ticks
    every ~15-21 ms; the old 5 ms sleep + big snapshot still dropped clk 9-11), and each
    row carries `pl` = all 22 players [team, idx, slot(+0x2bc), id(+0x2c8), act(+0x40),
    mk(+0x150 marked-man VA), x, y] so candidate-2 (wrong marked man) is decidable;
  * optional stop_clk argv[4]: exit once clk > stop_clk in half 0 (a clk-9 capture only
    needs the first goal at clk 2837 to prove seed fidelity, not FULL TIME).

Offsets (all verified against frame0_struct_import.json + keeper_advance decompile +
fn_005b1500 L36/L65: mk = player+0x150, press compares mk == ball+0x4c; base = the match
struct returned by m4_findbase.py):
  BALL is EMBEDDED at match_base + 0x1610 (frame0: ball _va - match_base == 0x1610).
    ball.x = +0x1614  ball.y = +0x1618  ball.z = +0x161c   (keeper_advance reads 0x1614/8)
    ball.vx= +0x1630  ball.vy= +0x1634  ball.vz= +0x1638
    ball.controller = +0x1650  (ball+0x40; a VA -> the carrying player struct, or 0)
    ball.receiver   = +0x165c  (ball+0x4c; the pass-target VA the b1500 press checks)
  CARRIER (if controller != 0), read at *(controller):
    x = +0x4  y = +0x8  z = +0xc  slot = +0x2bc (0..10; 0 == GK) team = +0x2b8  act = +0x40
  TEAM arrays (m5_poll_kickoff/m4_struct_import verified): header @ +0x46c (team0) /
    +0x78c (team1) = [player array base, count]; player stride 0x3bc.
  match scalars (m4): +0x448 phase | +0x450 clk | +0x19a0 half | +0x19a8 banked
    | +0x19ac scale | +0x478/+0x798 team scores | +0x1a38 disp | seed @0x006d3184

Writes one JSON line whenever ANY tracked field changes (~200 Hz sampler outside the
burst window). Because the carrier x/y is now tracked, every displacement of the
ball-holder emits a row -> a dense downfield trajectory. Exits like m4_poll (process
gone, or 90 s quiescent after half>=1), or at stop_clk.
"""

import json
import struct
import sys
import time

FIELDS = {
    "phase": 0x448,
    "clk": 0x450,
    "over": 0x454,
    "half": 0x19A0,
    "banked": 0x19A8,
    "scale": 0x19AC,
    "sc0c": 0x19B0,
    "sc1c": 0x19B4,
    "sc0": 0x478,
    "sc1": 0x798,
    "disp": 0x1A38,
}
BALL_OFF = 0x1610  # ball embedded at match_base+0x1610
Q60_LEN = 0x64  # ball 0x00..0x63 (dwords 0x00..0x60 inclusive)
# ball fields, relative to the q60 blob (== relative to ball base)
BALL_IN_Q60 = {"bx": 0x4, "by": 0x8, "bz": 0xC, "bvx": 0x20, "bvy": 0x24, "bvz": 0x28}
BALL_CTRL_IN_Q60 = 0x40  # ball+0x40 controller VA
BALL_RECV_IN_Q60 = 0x4C  # ball+0x4c pass-receiver VA (b1500 press operand)
CARRIER = {"cx": 0x4, "cy": 0x8, "cz": 0xC, "cslot": 0x2BC, "cteam": 0x2B8, "cact": 0x40}
SEED_VA = 0x006D3184
TEAM_HDR = {0: 0x46C, 1: 0x78C}
PLAYER_STRIDE = 0x3BC
PBLOB_LEN = 0x2D0  # one pread per player covers x/y/z/act/mk/team/slot/id
PF = {"x": 0x4, "y": 0x8, "act": 0x40, "mk": 0x150, "team": 0x2B8, "slot": 0x2BC, "id": 0x2C8}
BURST_CLK = 24  # tight-loop + player table while clk <= this


def main() -> None:
    lpid, base, out = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    stop_clk = int(sys.argv[4]) if len(sys.argv) > 4 else None
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    fo = open(out, "a", buffering=1)

    def rd(addr: int, n: int) -> bytes:
        mem.seek(addr)
        return mem.read(n)

    def u32(addr: int) -> int:
        return struct.unpack("<I", rd(addr, 4))[0]

    def bu32(blob: bytes, off: int) -> int:
        return struct.unpack_from("<I", blob, off)[0]

    def bs32(blob: bytes, off: int) -> int:
        return struct.unpack_from("<i", blob, off)[0]

    def s32(addr: int) -> int:
        v = u32(addr)
        return v - 2**32 if v >= 2**31 else v

    # resolve the two player arrays once (allocated at frame0/KICK OFF screen), so
    # mk/ctrl/receiver VAs are resolvable offline: VA -> (team, idx).
    teams = []
    for ti in (0, 1):
        arr = u32(base + TEAM_HDR[ti])
        cnt = min(u32(base + TEAM_HDR[ti] + 4), 11)
        teams.append((arr, cnt))
    fo.write(
        json.dumps(
            {
                "event": "teams",
                "stride": PLAYER_STRIDE,
                "t0": [hex(teams[0][0]), teams[0][1]],
                "t1": [hex(teams[1][0]), teams[1][1]],
            }
        )
        + "\n"
    )

    def players() -> list:
        rows = []
        for ti in (0, 1):
            arr, cnt = teams[ti]
            for i in range(cnt):
                b = rd(arr + i * PLAYER_STRIDE, PBLOB_LEN)
                rows.append(
                    [
                        ti,
                        i,
                        bs32(b, PF["slot"]),
                        bs32(b, PF["id"]),
                        bs32(b, PF["act"]),
                        bu32(b, PF["mk"]),
                        bs32(b, PF["x"]),
                        bs32(b, PF["y"]),
                    ]
                )
        return rows

    last = None
    t0 = time.time()
    last_change = t0
    seen_h2 = False
    n = 0
    while True:
        try:
            snap = {k: u32(base + off) for k, off in FIELDS.items()}
            snap["seed"] = u32(SEED_VA)
            q60 = rd(base + BALL_OFF, Q60_LEN)
            snap["q60"] = q60.hex()
            for k, off in BALL_IN_Q60.items():
                snap[k] = bs32(q60, off)
            ctrl = bu32(q60, BALL_CTRL_IN_Q60)
            snap["ctrl"] = ctrl
            snap["recv"] = bu32(q60, BALL_RECV_IN_Q60)
            if ctrl:
                for k, off in CARRIER.items():
                    snap[k] = s32(ctrl + off)
            else:
                for k in CARRIER:
                    snap[k] = None
            burst = snap["clk"] <= BURST_CLK
            if burst:
                snap["pl"] = players()
        except (OSError, struct.error):
            fo.write(json.dumps({"t": time.time() - t0, "event": "process_gone"}) + "\n")
            break
        n += 1
        if snap != last:
            rec = {"t": round(time.time() - t0, 4), **snap}
            fo.write(json.dumps(rec) + "\n")
            last = snap
            last_change = time.time()
            if snap["half"] >= 1:
                seen_h2 = True
        if stop_clk is not None and snap["clk"] > stop_clk and snap["phase"] != 2:
            fo.write(
                json.dumps({"t": time.time() - t0, "event": "stop_clk", "clk": snap["clk"]}) + "\n"
            )
            break
        if seen_h2 and time.time() - last_change > 90:
            fo.write(json.dumps({"t": time.time() - t0, "event": "quiescent_after_h2"}) + "\n")
            break
        if not burst:
            time.sleep(0.005)
    fo.write(json.dumps({"event": "polls", "n": n}) + "\n")
    fo.close()


if __name__ == "__main__":
    main()
