#!/usr/bin/env python3
"""Poll the live MANAGER.EXE match struct + BALL + ALL 22 PLAYERS to a JSONL kickoff timeline.

Usage: m5_poll_kickoff.py <lpid> <match_base_hex> <out.jsonl>

Superset of m5_poll_traj.py: adds every outfield player's position/slot/action by following the
two team headers, so the M5 KICKOFF-divergence work can read the RECEIVER (Villa slot-8) position
through phase 2 (frozen clock) and the phase-2 -> 0 kick, which m5_poll_traj (carrier-only) cannot
see (slot-8 is not the carrier until it collects at clk ~12).

Team arrays (m4_struct_import verified): team0 header @ match_base+0x46c (word0 +0x46c = player
array base, word1 +0x470 = count); team1 @ +0x78c. Player stride 0x3bc; per player x=+0x4 y=+0x8
z=+0xc slot=+0x2bc team=+0x2b8 act=+0x40. Match scalars/ball as m5_poll_traj.

Exits when clk >= 40 (well past the kickoff collect ~clk12) after phase has left 2, or process
gone, or 90 s. Writes one row whenever any tracked field changes (~200 Hz).
"""
import json
import struct
import sys
import time

FIELDS = {"phase": 0x448, "clk": 0x450, "half": 0x19A0, "disp": 0x1A38,
          "sc0": 0x478, "sc1": 0x798}
BALL = {"bx": 0x1614, "by": 0x1618, "bz": 0x161C, "bvx": 0x1630, "bvy": 0x1634, "bvz": 0x1638}
BALL_CTRL_OFF = 0x1650
SEED_VA = 0x006D3184
TEAM_HDR = {0: 0x46C, 1: 0x78C}   # match_base + off -> [arr_base, count]
PLAYER_STRIDE = 0x3BC
PF = {"x": 0x4, "y": 0x8, "z": 0xC, "act": 0x40, "team": 0x2B8, "slot": 0x2BC}


def main() -> None:
    lpid, base, out = int(sys.argv[1]), int(sys.argv[2], 16), sys.argv[3]
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)
    fo = open(out, "a", buffering=1)

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def s32(addr: int) -> int:
        v = u32(addr)
        return v - 2**32 if v >= 2**31 else v

    # resolve the two player arrays once (allocated at frame0/KICK OFF screen).
    teams = []
    for ti in (0, 1):
        arr = u32(base + TEAM_HDR[ti])
        cnt = u32(base + TEAM_HDR[ti] + 4)
        teams.append((arr, min(cnt, 11)))
    fo.write(json.dumps({"event": "teams", "t0": [hex(teams[0][0]), teams[0][1]],
                         "t1": [hex(teams[1][0]), teams[1][1]]}) + "\n")

    last = None
    t0 = time.time()
    last_change = t0
    left_phase2 = False
    n = 0
    while True:
        try:
            snap = {k: u32(base + off) for k, off in FIELDS.items()}
            snap["seed"] = u32(SEED_VA)
            for k, off in BALL.items():
                snap[k] = s32(base + off)
            snap["ctrl"] = u32(base + BALL_CTRL_OFF)
            players = []
            for ti in (0, 1):
                arr, cnt = teams[ti]
                for i in range(cnt):
                    pa = arr + i * PLAYER_STRIDE
                    players.append([ti, i, s32(pa + PF["slot"]), s32(pa + PF["act"]),
                                    s32(pa + PF["x"]), s32(pa + PF["y"]), s32(pa + PF["z"])])
            snap["pl"] = players
        except (OSError, struct.error):
            fo.write(json.dumps({"t": time.time() - t0, "event": "process_gone"}) + "\n")
            break
        n += 1
        if snap != last:
            fo.write(json.dumps({"t": round(time.time() - t0, 4), **snap}) + "\n")
            last = snap
            last_change = time.time()
        if snap["phase"] != 2:
            left_phase2 = True
        if left_phase2 and snap["clk"] >= 40:
            fo.write(json.dumps({"t": time.time() - t0, "event": "clk40_done"}) + "\n")
            break
        if time.time() - last_change > 90:
            fo.write(json.dumps({"t": time.time() - t0, "event": "quiescent"}) + "\n")
            break
        time.sleep(0.005)
    fo.write(json.dumps({"event": "polls", "n": n}) + "\n")
    fo.close()


if __name__ == "__main__":
    main()
