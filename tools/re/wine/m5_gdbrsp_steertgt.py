#!/usr/bin/env python3
"""Raw gdb-remote (RSP) client: CODE breakpoint on the steer dispatcher FUN_005a89c0,
dumping the steer TARGET (x,y,z) + the caller leaf (ret0) for one player.

Usage:
  m5_gdbrsp_steertgt.py <port> <lpid> <match_base_hex> <out.jsonl> \
      [team=1] [idx=9] [stop_clk=3] [bp_va_hex=5a89c0]

s37/s38 variant for the t1.i9 first-step steer-TARGET error (handoff-pm98-m5-t1i9-target).
s38 ADDS the b0040 INPUT capture: at every matched 89c0 stop it also dumps the ctrl (ball)
object (*(player+0x190)) fields _b0040_target reads -- ball_pos +4/8/c, ball_vel +0x20/24/28,
ball_face +0x34, ctrl+0x4c==player, carrier +0x84.., markers +0xb0/bc/cc/d8 -- plus the
player-side terms p+0x2bc/0x70/0x3ac/0x3a8. These diff 1:1 against diag_m5_b0040_inputs.gd,
so the live drive names whether the port's (1647,2) is a wrong-INPUT (stale ball) or a
wrong-COMPUTATION error. The port-side trace already showed ball_pos=[0,0,0] + ball_face=0
at the arm step -> facedir=+x -> near-origin target; silicon's ball_face here is decisive.
s36 proved (port-side) that t1.i9's one-quantum drift is a single first-step heading
error (port 0x9ef5 vs silicon 0x9dc5, +0x130), caused by the first-step steer target
being ~1.67 deg off port's (-142564, -218). The armwatch/dartwatch/seedwatch captures
NEVER dumped that target, so the leaf term cannot be named without silicon's own value.

FUN_005a89c0 is __thiscall (ECX=param_1=the steered player) and forwards its stack
param_2 straight to FUN_005a8bc0, which reads the target as three i32 at [param_2+0/4/8]
(decomp docs/re/move/fn_005a8bc0_FUN_005a8bc0.c L37-39). So at the 89c0 ENTRY breakpoint:
  ECX      = reg 1              = the player struct VA (correlate vs t1.i9)
  [esp]    = ret0              = the CALLER leaf (which computed the target)
  [esp+4]  = param_2           = pointer to the target struct
  [esp+8]  = param_3           = the speed_scale (0x5a for the arm step)
  target   = i32[param_2 + 0/4/8]

t<team>.i<idx> VA = u32(base + (0x46c if team==0 else 0x78c)) + idx*0x3bc
(m4_struct_import.py layout: team0 array @+0x46c, team1 @+0x78c, count at +4, stride
0x3bc). Only matched stops (eip==bp_va and ecx==target VA) are written, so the jsonl
stays small even though 89c0 fires for ~every moving player every tick.

Diff the arm-step row (act 0->1, scale 0x5a) target against the port's (-142564, -218)
to localize the 1.67-deg leaf term. Reusable for t0.i8 (clk 60) / t0.i9 (clk 80) by
passing team/idx/stop_clk. Same RSP gotchas as the seedwatch/dartwatch (see
tools/re/wine/README.md): capture first, the game may die on detach; the stub accepts
exactly one connection; killing the stub kills the game; match base MOVES every drive
(re-run m4_findbase.py, never reuse a prior base).
"""

import json
import struct
import sys

from m5_gdbrsp_seedwatch import Rsp  # same stub procedure

PLAYER_STRIDE = 0x3BC
MAX_STOPS = 40000
TEAM_ARR_OFF = {0: 0x46C, 1: 0x78C}


def main() -> None:
    port, lpid, base = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3], 16)
    out = sys.argv[4]
    team = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    idx = int(sys.argv[6]) if len(sys.argv) > 6 else 9
    stop_clk = int(sys.argv[7]) if len(sys.argv) > 7 else 3
    bp_va = int(sys.argv[8], 16) if len(sys.argv) > 8 else 0x5A89C0
    mem = open(f"/proc/{lpid}/mem", "rb", buffering=0)  # noqa: SIM115 — held for process life
    fo = open(out, "a", buffering=1)  # noqa: SIM115 — streamed jsonl, closed at exit

    def u32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<I", mem.read(4))[0]

    def i32(addr: int) -> int:
        mem.seek(addr)
        return struct.unpack("<i", mem.read(4))[0]

    def i32_safe(addr: int):
        try:
            return i32(addr)
        except OSError:
            return None

    arr = u32(base + TEAM_ARR_OFF[team])
    cnt = u32(base + TEAM_ARR_OFF[team] + 4)
    target_va = arr + idx * PLAYER_STRIDE
    fo.write(
        json.dumps(
            {
                "event": "target_player",
                "team": team,
                "idx": idx,
                "arr": hex(arr),
                "count": cnt,
                "va": hex(target_va),
                "bp": hex(bp_va),
            }
        )
        + "\n"
    )

    def t_regs(stx: str) -> dict:
        import re as _re

        o = {}
        for m in _re.finditer(r"([0-9a-fA-F]{2}):([0-9a-fA-F]{8});", stx):
            o[int(m.group(1), 16)] = int.from_bytes(bytes.fromhex(m.group(2)), "little")
        return o

    def regs_full() -> list:
        g = r.cmd("g")
        return [
            int.from_bytes(bytes.fromhex(g[i * 8 : i * 8 + 8]), "little")
            for i in range(min(len(g) // 8, 16))
        ]

    def cont() -> None:
        payload = "vCont;c"
        r.s.sendall(f"${payload}#{sum(payload.encode()) % 256:02x}".encode())

    r = Rsp(port)
    st = r.cmd("?")
    fo.write(json.dumps({"event": "attach_status", "reply": st}) + "\n")

    # Z0 software breakpoint; fall back to Z1 (HW exec) if the stub rejects Z0.
    kind = "Z0"
    ok = r.cmd(f"Z0,{bp_va:x},1")
    if ok != "OK":
        kind = "Z1"
        ok = r.cmd(f"Z1,{bp_va:x},1")
    fo.write(json.dumps({"event": "set_bp", "kind": kind, "reply": ok, "va": hex(bp_va)}) + "\n")
    if ok != "OK":
        print(f"breakpoint REJECTED at {bp_va:#x}: {ok!r}", file=sys.stderr)
        sys.exit(1)

    print(
        f"ARMED steer-target bp @{bp_va:#x} for t{team}.i{idx} ({hex(target_va)}) "
        f"stop_clk={stop_clk} — click KICK OFF now",
        flush=True,
    )
    cont()
    stops = 0
    matched = 0
    while True:
        try:
            st = r.wait_stop()
        except ConnectionError:
            fo.write(json.dumps({"event": "stub_closed"}) + "\n")
            break
        stops += 1
        rg = t_regs(st)
        if 8 in rg and 1 in rg:
            eip, esp, ecx = rg[8], rg[4], rg[1]
        else:  # stub gave a bare S/T without expedited regs -> pull the full set
            full = regs_full()
            eip, esp, ecx = full[8], full[4], full[1]
        clk = u32(base + 0x450)

        if eip == bp_va and ecx == target_va:
            matched += 1
            ret0 = i32_safe(esp)
            param2 = i32_safe(esp + 4)
            scale = i32_safe(esp + 8)
            tgt = None
            if param2 is not None:
                tgt = [i32_safe(param2), i32_safe(param2 + 4), i32_safe(param2 + 8)]
            # ctrl (ball) object VA = *(player + 0x190); dump the EXACT fields the port's
            # _b0040_target reads, so the live row diffs 1:1 vs diag_m5_b0040_inputs.gd.
            ctrl_va = u32(target_va + 0x190)
            ball = {
                "ctrl_va": hex(ctrl_va),
                "ball_pos": [i32_safe(ctrl_va + 4), i32_safe(ctrl_va + 8), i32_safe(ctrl_va + 0xC)],
                "ball_vel": [i32_safe(ctrl_va + 0x20), i32_safe(ctrl_va + 0x24), i32_safe(ctrl_va + 0x28)],
                "ball_face": u32(ctrl_va + 0x34) & 0xFFFF,
                "ctrl_4c_is_p": u32(ctrl_va + 0x4C) == target_va,
                "carrier_84": [i32_safe(ctrl_va + 0x84), i32_safe(ctrl_va + 0x88), i32_safe(ctrl_va + 0x8C)],
                "mk_b0": i32_safe(ctrl_va + 0xB0),
                "mk_bc": i32_safe(ctrl_va + 0xBC),
                "mk_cc": [i32_safe(ctrl_va + 0xCC), i32_safe(ctrl_va + 0xD0), i32_safe(ctrl_va + 0xD4)],
                "mk_d8": [i32_safe(ctrl_va + 0xD8), i32_safe(ctrl_va + 0xDC), i32_safe(ctrl_va + 0xE0)],
            }
            row = {
                "match": matched,
                "stop": stops,
                "clk": clk,
                "phase": u32(base + 0x448),
                "ecx": hex(ecx),
                "ret0": hex(ret0 & 0xFFFFFFFF) if ret0 is not None else None,
                "param2": hex(param2 & 0xFFFFFFFF) if param2 is not None else None,
                "scale": scale,
                "target": tgt,
                # pose of the steered player, to align the row to the port step table
                "pos": [i32_safe(target_va + 4), i32_safe(target_va + 8)],
                "act": i32_safe(target_va + 0x40),
                "face": u32(target_va + 0x34) & 0xFFFF,
                "yaw": u32(target_va + 0x64) & 0xFFFF,
                "speed": i32_safe(target_va + 0x68),
                "curve": i32_safe(target_va + 0x6C),
                # player-side _b0040_target inputs (carrier gate + curve_rate terms)
                "p_2bc": i32_safe(target_va + 0x2BC),
                "p_70": i32_safe(target_va + 0x70),
                "p_3ac": i32_safe(target_va + 0x3AC),
                "p_3a8": i32_safe(target_va + 0x3A8),
                "ball": ball,
            }
            fo.write(json.dumps(row) + "\n")

        if clk > stop_clk or stops >= MAX_STOPS:
            fo.write(
                json.dumps({"event": "done", "stops": stops, "matched": matched, "clk": clk}) + "\n"
            )
            break
        cont()

    try:
        r.cmd(f"{kind[0].lower()}{kind[1]},{bp_va:x},1", timeout=10)
        r.cmd("D", timeout=10)
    except Exception as e:  # noqa: BLE001 — best-effort detach, game must survive
        fo.write(json.dumps({"event": "detach_err", "err": str(e)}) + "\n")
    print(f"DONE stops={stops} matched={matched} -> {out}", flush=True)


if __name__ == "__main__":
    main()
