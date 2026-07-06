class_name Pm98LineupFeeder
extends RefCounted
## REAL match input from the shipped game data — the career-side half of the match start.
##
## EXACT port of MANAGER.EXE's lineup filler FUN_0044d5f0 (the career match runner's
## "fill both 0x7a0 LINEUP blocks + session fields" pass), built from the exported .DBC
## data instead of live career objects. Field-by-field provenance:
## docs/re/session_lineup_re.md (§3 record map, §4 transform, §5 STR gate, §6 header);
## decompiles docs/re/move/fn_0044d5f0_FUN_0044d5f0.c + docs/re/session/
## fn_005841e0_FUN_005841e0.c + fn_0058c300/fn_0058c270. Nothing here is invented:
## every constant is a decompile line or an exported .DBC byte.
##
## Inputs (both committed, source-derived):
##   res://data/game_db.json      — engine-exact EQUIPOS squads (ids, attrs VE..PO by
##                                  name==memory offset +0x9c..+0xa5, posFine, band,
##                                  squadNo=+0xf8, b16/b17=+0x16/+0x17)
##   res://data/club_tactics.json — 11 raw tactic slot blocks (club+0x60+i*0x20), the
##                                  7 lever bytes (+0x1d9..+0x1df stream order), TRUE XI
##                                  (game_db ids per shipped slot), stadium pitch dims
##                                  (+0x36/+0x34 pair, engine substitute rule applied)
##
## RUNTIME (career-state) fields not present in the .DBC — season-init values, evidence
## in docs/re/morale_re.md (frame-128: FI 70 squad-wide + EN column == cap byte 99):
##   rec+0x34 (cap byte +0xa8)   = 99
##   rec+0x39 (fitness +0xa7)    = 70
##   rec+0x28 (marking, club+0x230 career table, ctor-zeroed) = 0 - 1 = -1
##   prior-leg cards/events (fixture vectors) = 0 — fresh league match, no prior leg
## Morale does NOT enter the lineup record: FUN_005841e0 discards FUN_00582db0's value.
##
## The away lineup uses the away club's OWN slots/levers but the SAME venue pitch dims,
## with NO coordinate mirroring at build time (fn_0044d5f0 side-1 loop L385-668).
##
## RNG: this pass draws NOTHING. The binary's only seed draws between career and
## kickoff_init are the palette re-rolls in FUN_005b63e0 (display-only, headless skips
## them) — session_lineup_re.md §2. FUN_00582e90 (inside the discarded morale calc) is
## un-audited for draws; it runs BEFORE FUN_00590fc0 in the binary, so kickoff_init's
## 4-draw inventory is unaffected either way. Flagged, not assumed resolved (M4 oracle).

const DESIGN_W := 0x13E                 # 318 — tactic design-space width
const DESIGN_H := 0xC6                  # 198 — design-space height
const FITNESS_INIT := 70                # +0xa7 season-init (morale_re.md frame 128)
const CAP_INIT := 99                    # +0xa8 season-init (morale_re.md, node ctor)
const BAND := {"GK": 0, "DF": 1, "MF": 2, "FW": 3}   # game_db pos <- +0x1c band byte


## Load + index both data files. Returns {"clubs": {id: club}, "tactics": {id: tactic}}.
static func load_data() -> Dictionary:
	var db := _load_json("res://data/game_db.json")
	var ct := _load_json("res://data/club_tactics.json")
	assert(not db.is_empty() and not ct.is_empty(), "game_db/club_tactics missing")
	var clubs := {}
	for c in (db.get("clubs", []) as Array):
		clubs[int(c["id"])] = c
	return {"clubs": clubs, "tactics": ct.get("clubs", {})}


## Build the full match input for home_id vs away_id (game_db app ids):
## {"session": Dictionary, "lineups": [home, away]} — lineups in the port's team[0x9c]
## shape {"header": [9 ints], "slots": [rec x11]} (Pm98Match._build_team contract).
static func build(home_id: int, away_id: int, data: Dictionary) -> Dictionary:
	# Venue pitch dims = the HOME club's stadium pair << 16 (fn_0044d5f0 L75-80:
	# FUN_00585ee0(fixture+0x44) -> club u16s +0x36/+0x34 << 0x10 -> session+0x4c/+0x50).
	var home_t: Dictionary = _tactic(data, home_id)
	var pitch_w: int = int((home_t["pitch"] as Dictionary)["w"]) << 16
	var pitch_h: int = int((home_t["pitch"] as Dictionary)["h"]) << 16

	var lineups: Array = []
	var lever_dwords: Array = []
	for cid in [home_id, away_id]:
		var t: Dictionary = _tactic(data, cid)
		var club: Dictionary = data["clubs"][cid]
		var is_league: bool = club.get("leagueId") != null    # club+0x5c != 0xffff
		var by_id := {}
		for p in (club.get("players", []) as Array):
			by_id[int(p["id"])] = p
		var slots: Array = []
		for i in range(11):
			var pid := int((t["xi"] as Array)[i])
			assert(pid != -1, "%s: XI slot %d unfilled" % [club["name"], i])
			var raw: Array = ((t["slots"] as Array)[i] as Dictionary)["raw"]
			slots.append(_rec(by_id[pid], i, raw, pitch_w, pitch_h, is_league))
		# header 9 dwords -> team[0xbf..0xc7] (lineup+0x4..+0x28 skip +0x0/+0xc):
		# two transformed x-lines from club+0x260/+0x25c (ctor defaults 198/79, the
		# .DBC parser never overwrites them — session_lineup_re.md §6), then the 7
		# levers in ENGINE order +0x1d9,1da,1db,1dd,1de,1df,1dc == stream indexes
		# [0,1,2,4,5,6,3] of club_tactics `levers` (loader fn_00579c70 L171-191:
		# stream byte 3 lands at +0x1dc). team[0xc7]=levers[3] picks the 0xe1 ftol C.
		var lv: Array = t["levers"]
		lineups.append({
			"header": [
				_transform_xline(0xC6, pitch_w),
				_transform_xline(0x4F, pitch_w),
				int(lv[0]), int(lv[1]), int(lv[2]),
				int(lv[4]), int(lv[5]), int(lv[6]), int(lv[3]),
			],
			"slots": slots,
		})
		lever_dwords.append([int(lv[0]), int(lv[1]), int(lv[2]),
				int(lv[4]), int(lv[5]), int(lv[6]), int(lv[3])])

	# Session (byte-keyed; binary: the career/session object, match+0x468). The port
	# consumes 0x4c/0x50 (kickoff_init scales), 0xfd0..0xfdc/0xff4 (orientation /
	# pitch-type), 0xfa0 (play-state), 0x14 (Dispatch sub counter), 0x44/0x48 (cup
	# ladder). The rest are the doc §6 fixture-derived fields with their fresh-league-
	# match values (un-modeled fixture object -> 0), kept for faithfulness.
	var session := {
		0x4c: pitch_w, 0x50: pitch_h,                        # venue pitch dims << 16
		0x54: 0,
		0x58: 1,                                             # venue == home club
		0x18: 1,                                             # competition-is-league flag
		0x10: 0, 0x1c: 0, 0x20: 0, 0x24: 0, 0x28: 0,        # fixture dwords (fresh: 0)
		0x2c: 0, 0x30: 0, 0x34: 0, 0x38: 0,                 # fixture bytes +0x34..+0x37
		0x14: 0,
		0x44: 0, 0x48: 0,                                    # extra-time/aggregate: league
		0x64: 0, 0x804: 0,                                   # fixture+0x18/+0x1a u16s
		0x7f0: 1 if (data["clubs"][away_id] as Dictionary).get("leagueId") != null else 0,
		0xfa0: 1,                                            # play-state (in play)
		0xff4: 0,                                            # pitch type -> +0x19ac 7200
		0xfd0: 0, 0xfd4: 0, 0xfd8: 0, 0xfdc: 0,             # orientation
		0xfe8: 0, 0xfec: 0, 0xff0: 0,                        # display drivers (headless)
	}
	# 7 home/away lever bytes as dwords at +0x68../+0x808.. (engine order, doc §6).
	for k in range(7):
		session[0x68 + k * 4] = (lever_dwords[0] as Array)[k]
		session[0x808 + k * 4] = (lever_dwords[1] as Array)[k]
	return {"session": session, "lineups": lineups}


## One lineup record (= slot base, the port's byte-keyed `rec`) — fn_0044d5f0 present-
## branch L177-262, field map session_lineup_re.md §3. slot_i is the 0-based tactic
## slot (XI slot byte s = slot_i+1); slot_raw = the club's OWN 8-u16 block for it.
static func _rec(player: Dictionary, slot_i: int, slot_raw: Array,
		pitch_w: int, pitch_h: int, is_league: bool) -> Dictionary:
	var attrs: Dictionary = player.get("attrs", {})
	var ve := int(attrs.get("VE", 0))
	var re_ := int(attrs.get("RE", 0))
	var ag := int(attrs.get("AG", 0))
	var ca := int(attrs.get("CA", 0))
	assert(BAND.has(player.get("pos")), "player %s: band missing" % player.get("name"))
	var band: int = BAND[player["pos"]]

	var b := _transform_block(slot_raw, pitch_w, pitch_h)
	# roam box: min/max over transformed [0] vs [0]+[2], [1] vs [1]+[3] (int32 adds).
	var sx := _i32(b[0] + b[2])
	var sy := _i32(b[1] + b[3])

	# PO +10 clamp 99 on the GK slot; EN +10 clamp 99 for band DEF; TI -10 when the
	# club is a league club and TI > 0x1e (fn_0044d5f0 L227-250).
	var po := int(attrs.get("PO", 0))
	if slot_i == 0:
		po = mini(po + 10, 99)
	var en := int(attrs.get("EN", 0))
	if band == 1:
		en = mini(en + 10, 99)
	var ti := int(attrs.get("TI", 0))
	if is_league and ti > 0x1E:
		ti -= 10

	var rec := {
		0x4: int(player["photoId"]) if player.get("photoId") != null else 0,  # .DBC u16 id
		0x8: b[4], 0xc: b[5],                                # start pos A (mk1)
		0x10: b[6], 0x14: b[7],                              # start pos B (mk2)
		0x18: mini(b[0], sx), 0x1c: mini(b[1], sy),          # roam box min
		0x20: maxi(b[0], sx), 0x24: maxi(b[1], sy),          # roam box max
		0x28: -1,                                            # marking idx (career table 0-1)
		0x2c: int(player.get("b16", 0)),                     # .DBC +0x16 verbatim
		0x30: int(player.get("b17", 0)),                     # .DBC +0x17 verbatim
		0x34: CAP_INIT,                                      # +0xa8 cap byte
		0x35: ve, 0x36: re_, 0x37: ag, 0x38: ca,             # FUN_005841e0 raw outputs
		0x39: FITNESS_INIT,                                  # +0xa7 fitness
		0x3a: 99,                                            # constant (L225)
		0x3b: _str_gated(ve, re_, ag, ca, slot_i + 1, band, is_league, slot_raw),
		0x3c: po, 0x3d: en,
		0x3e: int(attrs.get("PA", 0)), 0x3f: int(attrs.get("RM", 0)),
		0x40: int(attrs.get("RG", 0)), 0x41: ti,
		0x42: int(player.get("squadNo", 0)),                 # +0xf8 verbatim (port clamps)
		0x44: int(player.get("posFine", 0)),                 # player+0x18+1 == posFine; present flag
		0x48: band,                                          # broad role switch 0..3
		# prior-leg cards + event entry: fresh league match, no prior leg -> all zero.
		0x50: 0, 0x54: 0, 0x58: 0, 0x5c: 0, 0x60: 0, 0x64: 0,
		0x98: 0,
	}
	assert(rec[0x44] != 0, "present player %s got posFine 0" % player.get("name"))
	return rec


## FUN_0058c300 — formation grid -> pitch transform, bit-exact 32-bit x86 semantics.
## block = 8 ints (the club slot raw u16s); FUN_0058c270's scaling is UNSIGNED 32-bit
## mul+div (uint* signature): pitchW(<<16) * 318 overflows int32, wraps as u32, and the
## unsigned divide is still exact — replicated via _u32 wrap + non-negative division.
static func _transform_block(raw: Array, pitch_w: int, pitch_h: int) -> Array:
	var b: Array = []
	for k in range(8):
		b.append(int(raw[k]))
	# pre-nudge (L9-16): +designW/0x1e (=10) on [4]/[6] iff nonzero; +designH/0x12 (=11)
	# on [5]/[7] unconditionally.
	if b[4] != 0:
		b[4] += DESIGN_W / 0x1E
	b[5] += DESIGN_H / 0x12
	if b[6] != 0:
		b[6] += DESIGN_W / 0x1E
	b[7] += DESIGN_H / 0x12
	# FUN_0058c270: x fields scale by pitchW/318, y fields by pitchH/198 (unsigned).
	for k in range(8):
		var scale := pitch_w if (k & 1) == 0 else pitch_h
		var design := DESIGN_W if (k & 1) == 0 else DESIGN_H
		b[k] = _u32(scale * b[k]) / design
	# recenter/flip (L19-27, signed int32).
	b[3] = _i32(-b[3])
	b[0] = _i32(b[0] - (pitch_w >> 1))
	b[1] = _i32((pitch_h >> 1) - b[1])
	var ix := _i32(pitch_w / (DESIGN_W * 2) - (pitch_w >> 1))
	b[4] = _i32(b[4] + ix)
	b[6] = _i32(b[6] + ix)
	var iy := _i32(pitch_h / (DESIGN_H * 2) - (pitch_h >> 1))
	b[5] = _i32(-(iy + b[5]))
	b[7] = _i32(-(iy + b[7]))
	return b


## The two header x-lines: FUN_0058c300 on a single stack dword — only block[0]'s path
## lands (scale by pitchW/318 then -= pitchW>>1); the block[1..7] stack writes are
## discarded by the binary too (fn_0044d5f0 L104-108).
static func _transform_xline(v: int, pitch_w: int) -> int:
	return _i32(_u32(pitch_w * v) / DESIGN_W - (pitch_w >> 1))


## FUN_005841e0 — STR = mean of raw VE/RE/AG/CA (>>2), POSITION-FIT gated for fielded
## starters of league clubs (session_lineup_re.md §5): GK slot/role mismatch -> mean/2;
## DEF keeps full mean iff own slot mk1.x < 0x6b, MID iff 0x59 < mk1.x < 0xb6,
## ATT/other iff mk2.x > 0xd3 — else mean*3/4. Compares are on the RAW design-space
## block (club+0x60 dwords), NOT the transformed coords.
static func _str_gated(ve: int, re_: int, ag: int, ca: int, xi_slot: int, band: int,
		is_league: bool, slot_raw: Array) -> int:
	var mean := (ve + re_ + ag + ca) >> 2
	if xi_slot < 0xC and is_league:
		if xi_slot == 1:
			if band != 0:
				return mean / 2
		else:
			if band == 0:
				return mean / 2
			var fit := false
			if band == 1:
				fit = int(slot_raw[4]) < 0x6B
			elif band == 2:
				fit = int(slot_raw[4]) > 0x59 and int(slot_raw[4]) < 0xB6
			else:
				fit = int(slot_raw[6]) > 0xD3
			if not fit:
				mean = (mean * 3) >> 2
	return mean


static func _u32(v: int) -> int:
	return v & 0xFFFFFFFF


static func _i32(v: int) -> int:
	v = v & 0xFFFFFFFF
	return v - 0x100000000 if v >= 0x80000000 else v


static func _tactic(data: Dictionary, cid: int) -> Dictionary:
	var t = (data["tactics"] as Dictionary).get(str(cid))
	assert(t is Dictionary, "club %d missing from club_tactics.json" % cid)
	return t


static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
