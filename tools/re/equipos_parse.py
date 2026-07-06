#!/usr/bin/env python3
"""Exact EQUIPOS.PKF .DBC club-record parser (shared module).

Byte-exact replica of the MANAGER.EXE loaders (decompiles in
docs/re/clubtactics/, RE narrative in docs/re/club_tactics_re.md):

  FUN_00579c70  club record: header + 11-slot tactic block + 7 lever bytes
                + tag-2 side records + squad do-while loop
  FUN_005820f0  player record (fmt<600 path — all EQUIPOS fmts are
                0x1f9..0x20b); INVALID records (slot byte >= 0x62) are
                re-parsed into the same object and their heap rolled back —
                the engine DROPS them from the squad
  FUN_00579170  tag-2 side record (parsed + skipped, un-identified)
  FUN_0058c810  string field: [u16 len][len bytes XOR 0x61]; heap len+1

Consumers: tools/re/export_club_tactics.py (tactics + TRUE XI export) and
tools/extract_squads_exact.py (the game_db squad source). Both parse the
SAME stream the engine parses; this module additionally CAPTURES the fields
the engine skips unread (the flag==0 career/bio tail, the header block
strings) so the extractor can decode them — the framing is the engine's own,
only the captured bytes' interpretation is ours (validated in the extractor's
kill-tests, never guessed).

Engine load-time semantics captured here as RAW values (the randomize/default
rules live in the loader, not the data — document, don't bake):
  - birth day/month 0 -> engine substitutes the current date's day/month
    (_DAT_0066b18c); year outside 0x76d..0x7c1 (1901..1985) ->
    current_year - 0x19 - rand(0..4)  (FUN_005820f0 @ 0x58228a)
  - height byte (+0xf9) < 0x96 (150cm) -> rand(0..9) + 170cm; weight byte
    (+0xfa) < 0x14 (20kg) -> rand(0..9) + 75kg  (FUN_005820f0 @ 0x5822e6)
  - special club ids in the parser: 0x26de (validity exemption), 0x26ae
    (third string kept), 0x26e4 (attr degrade) — none occur in EQUIPOS
"""

from __future__ import annotations

import struct

COPYRIGHT = b"Copyright (c)1996 Dinamic Multimedia"
ATTR_NAMES = ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]


class Stream:
    def __init__(self, d: bytes, p: int):
        self.d = d
        self.p = p
        self.heap = 0  # local_238: string-heap write offset (bounds check)

    def u8(self) -> int:
        v = self.d[self.p]
        self.p += 1
        return v

    def u16(self) -> int:
        v = struct.unpack_from("<H", self.d, self.p)[0]
        self.p += 2
        return v

    def u32(self) -> int:
        v = struct.unpack_from("<I", self.d, self.p)[0]
        self.p += 4
        return v

    def string(self) -> str:
        # FUN_0058c810: [u16 len][len bytes XOR 0x61]; heap use = len+1 (NUL)
        n = self.u16()
        s = bytes(b ^ 0x61 for b in self.d[self.p : self.p + n])
        self.p += n
        self.heap += n + 1
        return s.decode("latin1")

    def peek_field(self) -> str:
        """Decode the len-prefixed field at the cursor WITHOUT consuming it and
        WITHOUT heap use — for capturing fields the engine skips unread."""
        n = struct.unpack_from("<H", self.d, self.p)[0]
        raw = self.d[self.p + 2 : self.p + 2 + n]
        return bytes(b ^ 0x61 for b in raw).decode("latin1")

    def skip_lenpfx(self) -> None:
        # the *param_4 = u16@cursor + 2 + cursor idiom (unread field)
        self.p += struct.unpack_from("<H", self.d, self.p)[0] + 2

    def skip_string_plus(self, extra: int) -> None:
        # FUN_00579c70 skip idiom: cursor += u16@cursor + extra
        self.p += struct.unpack_from("<H", self.d, self.p)[0] + extra


def parse_side_record(s: Stream, flag: int, heap_base: int) -> None:
    """FUN_00579170 (tag-2 record): heap cursor resets to heap_base first."""
    s.heap = heap_base
    s.u16()
    s.string()
    if flag == 0:
        for _ in range(7):
            s.skip_lenpfx()
        if s.u8() == 3:
            s.skip_lenpfx()
        s.skip_lenpfx()


def parse_player(s: Stream, flag: int, dbc_id: int, collect: bool = False) -> dict:
    """FUN_005820f0, fmt<600 path — exact stream order, heap committed.

    collect=True additionally captures the engine-skipped/raw fields
    (squadNo byte +0xf8, birth day/month, height/weight bytes +0xf9/+0xfa,
    the un-RE'd bytes +0x1a/+0x16/+0x17, the raw 6-byte fine array, and the
    flag==0 tail's 10 len-prefixed fields decoded XOR 0x61). Stream position
    and heap accounting are IDENTICAL in both modes.
    """
    pid = s.u16()
    squad_no = s.u8()  # -> +0xf8 (SQUAD MANAGEMENT N. column, squad_number_re.md)
    name1 = s.string()
    name2 = s.string()
    slot = s.u8()  # -> +0x19 and +0x1b; valid iff < 0x62 (club != 0x26de moot)
    s.u8()  # unread byte
    fines_raw = [s.u8() for _ in range(6)]  # -> +0x1d..: 0 -> 0x62, else raw-1
    b1a = s.u8()  # +0x1a (un-RE'd)
    b16 = s.u8()  # +0x16 (un-RE'd)
    b17 = s.u8()  # +0x17 (un-RE'd)
    band = s.u8()  # +0x1c: 0 GK / 1 DF / 2 MF / 3 FW
    day = s.u8()  # birth day (engine-defaulted when 0)
    month = s.u8()  # birth month (engine-defaulted when 0)
    year = s.u16()  # engine randomizes outside 0x76d..0x7c1 (1901..1985)
    height = s.u8()  # +0xf9 (cm; engine randomizes 170..179 when < 150)
    weight = s.u8()  # +0xfa (kg; engine randomizes 75..84 when < 20)
    tail: list[str] | None = None
    if flag == 0:
        s.p += 1
        if collect:
            tail = [s.peek_field()]
            s.skip_lenpfx()
            if dbc_id == 0x26AE:
                tail.append(s.string())
            else:
                tail.append(s.peek_field())
                s.skip_lenpfx()
            for _ in range(8):
                tail.append(s.peek_field())
                s.skip_lenpfx()
        else:
            s.skip_lenpfx()
            if dbc_id == 0x26AE:
                s.string()
            else:
                s.skip_lenpfx()
            for _ in range(8):
                s.skip_lenpfx()
    attrs = [s.u8() for _ in range(10)]
    out = {
        "id": pid,
        "name": name1,
        "fullName": name2,
        "slot": slot,
        "fine": 0x63 if fines_raw[0] == 0 else fines_raw[0],  # == +0x1d + 1
        "band": band,
        "year": year,
        "attrs": attrs,
        "valid": slot < 0x62,
    }
    if collect:
        out.update(
            {
                "squadNo": squad_no,
                "day": day,
                "month": month,
                "heightRaw": height,
                "weightRaw": weight,
                "finesRaw": fines_raw,
                "b1a": b1a,
                "b16": b16,
                "b17": b17,
                "tail": tail,
            }
        )
    return out


def parse_club_tactic(d: bytes, dbc_id: int, collect: bool = False) -> dict:
    """Replicates FUN_00579c70: header + 11-slot block + levers + squad loop.

    collect=True additionally captures the header strings 2/3 + header byte,
    the flag==0 block's three skipped strings + stadium-capacity u32, and the
    per-player collected fields (see parse_player).
    """
    if not d.startswith(COPYRIGHT):
        raise ValueError("record does not start with the Copyright marker")
    s = Stream(d, 0x24)
    alloc = s.u16()  # alloc size (local_214)
    fmt = s.u16()  # local_22c, format word — gates the optional fields
    s.u8()  # byte @+0x28, never read by the parser
    flag = s.u8()  # local_230
    name = s.string()  # -> club+0x1c0 tactic name via FUN_0057a3e0
    hdr2 = s.string()  # second string (param_1[2])
    hdr_byte = s.u8()  # param_1[5]
    hdr3 = s.string()  # third string (*param_1)
    s.u32()  # param_1[6] (clamped to 6000 if <10 — post-read, no stream effect)
    if fmt >= 0x1FE:
        s.u32()  # param_1[7]
    # Stadium PITCH DIMS (session_lineup_re.md §4): +0x34/+0x36 u16 pair. The
    # engine substitutes (NOT clamps) after reading: +0x34 < 0x1e -> 0x3c,
    # +0x36 < 0x34 -> 0x69 (fn_00579c70_FUN_00579c70.c L112-117). +0x36 is the
    # x-axis (attack-axis) scale paired with design width 0x13e in
    # FUN_0058c300 — venue club's pair <<16 = session+0x4c/+0x50 = pitchW/H.
    p34 = s.u16()  # +0x34 = pitchH
    p36 = s.u16()  # +0x36 = pitchW
    s.u16()  # param_1[0xe]
    blk_strings: list[str] = []
    capacity = None
    if flag == 0:
        if fmt > 0x207:
            s.p += 2
        s.u32()  # param_1[8]
        if collect:
            blk_strings.append(s.peek_field())
        s.skip_string_plus(6)  # len-prefixed field + 4 extra bytes
        capacity = s.u32()  # stadium capacity -> param_1[0x7a]/[0x7b]
        if collect:
            blk_strings.append(s.peek_field())
        s.skip_string_plus(2)
        if collect:
            blk_strings.append(s.peek_field())
        s.skip_string_plus(2)
        s.u16()  # param_1[0x9e]
        s.u16()  # +0x27a
        s.u8()  # +0x3a
        if fmt >= 0x203:
            s.p += 0x7B
        elif fmt >= 0x1F9:
            s.p += 0x73
        else:
            s.p += 0x51
    slot_off = s.p
    slots = []
    for _ in range(11):  # FUN_0058c130 x 11: 8 u16 each -> club+0x60 + i*0x20
        f = [s.u16() for _ in range(8)]
        slots.append(
            {
                "raw": f,
                "mk1": [f[4] * 258 // 318, f[5] * 154 // 198],
                "mk2": [f[6] * 258 // 318, f[7] * 154 // 198],
            }
        )
    levers = [s.u8() for _ in range(7)]  # club+0x1d9..+0x1df

    # ---- squad loop (FUN_00579c70 tail) ------------------------------------
    heap_after_header = s.heap  # uVar11: side-records reset the heap here
    tag = s.u8()
    while tag == 2:
        parse_side_record(s, flag, heap_after_header)
        tag = s.u8()
    players = []
    dropped = []  # collect-mode only: the engine-discarded leavers (audit)
    while True:  # outer do-while: one squad object per iteration
        while True:  # inner: re-parse INVALID records into the same object
            saved_heap = s.heap  # local_228 save / local_238 restore
            p = parse_player(s, flag, dbc_id, collect)
            tag = s.u8()
            if tag == 0 or p["valid"]:
                break
            if collect:
                dropped.append(p)
            s.heap = saved_heap  # roll back the dropped record's strings
        if p["valid"]:
            players.append(p)
        elif tag == 0 and collect:
            dropped.append(p)  # final record dropped (leaver at end of list)
        if tag == 0:
            break
    in_bounds = s.heap <= alloc and s.p <= len(d)
    out = {
        "name": name,
        "fmt": fmt,
        "flag": flag,
        "slotOffset": slot_off,
        "slots": slots,
        "levers": levers,
        "players": players,
        "inBounds": in_bounds,
        # engine-effective values (substitute rule applied) + the raw pair
        "pitchW": 0x69 if p36 < 0x34 else p36,
        "pitchH": 0x3C if p34 < 0x1E else p34,
        "pitchRaw": [p34, p36],
    }
    if collect:
        out.update(
            {
                "hdr2": hdr2,
                "hdr3": hdr3,
                "hdrByte": hdr_byte,
                "blockStrings": blk_strings,
                "capacity": capacity,
                "dropped": dropped,
            }
        )
    return out
