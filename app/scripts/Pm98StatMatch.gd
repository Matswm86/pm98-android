class_name Pm98StatMatch
extends RefCounted
## PM98 STATISTICAL match engine -- the faithful port of the "instant result" /
## AI-vs-AI fixture simulator that MANAGER.EXE runs for every match the human does
## NOT watch positionally (career-match runner FUN_0044ee70, the PS==5 branch,
## lines 357-792). Unlike app/scripts/MatchEngine.gd (an ABSTRACTED per-shot model),
## every number here is lifted from the binary and validated against the real
## functions through the Ghidra PCode emulator. Full RE map: docs/re/stat_match_engine_re.md.
##
## Three binary functions are ported here, each oracle-anchored:
##   * FUN_0044ece0  chance/goal resolver    -> _resolve     (tools/re/run_statresolve_oracle.sh)
##   * FUN_00450510  per-segment stats accum  -> _stats       (tools/re/run_statacc_oracle.sh)
##   * FUN_0044ee70  PS==5 orchestration       -> simulate     (tools/re/run_statmatch_oracle.sh, end-to-end)
## plus the leaf helpers FUN_004510b0 (_emit), FUN_0044ec00 (_shot_marker),
## FUN_0044ea40 (_assist_marker), FUN_00450d20 (_count_events).
##
## MEMORY MODEL. The match struct is a flat PackedByteArray (class Mem) mirroring
## MANAGER.EXE's in-memory layout byte-for-byte, so the port is a near-verbatim
## translation of the binary's pointer arithmetic and the rand() stream stays
## bit-identical. Two team blocks of 0x7a0 bytes (side 0 at 0, side 1 at 0x7a0),
## each with 11 participant records of stride 0xac. The event vector is kept as a
## GDScript Array on the Mem (mirrors the +0xf98 vector the binary grows).
##
## RNG: the msvcrt C-runtime rand() (state*214013 + 2531011; draw = (state>>16)&0x7FFF).
## The probability idiom is `(rand()*N) >> 15`, a uniform draw in [0, N).


## msvcrt rand() LCG. `draws` counts every draw so oracle tests can assert the port
## consumes the exact same number the emulator traced (stream-alignment check).
class Rng extends RefCounted:
	var state: int
	var draws: int = 0

	func _init(seed_: int) -> void:
		state = seed_ & 0xFFFFFFFF

	## One msvcrt rand() draw in [0, 32767].
	func next() -> int:
		state = (state * 214013 + 2531011) & 0xFFFFFFFF
		draws += 1
		return (state >> 16) & 0x7FFF

	## The binary's `(rand()*n)>>15` uniform draw in [0, n).
	func mod(n: int) -> int:
		return (next() * n) >> 15


## Flat match-struct memory: a zero-filled PackedByteArray addressed by the same
## byte offsets MANAGER.EXE uses, little-endian. `events` holds the FUN_004510b0
## event vector (the binary keeps the data at the +0xf98 pointer; we keep records
## as dicts since only _count_events / readers walk it).
class Mem extends RefCounted:
	var b: PackedByteArray
	var events: Array

	func _init() -> void:
		b = PackedByteArray()
		b.resize(0x4000)        # zero-filled; covers both 0x7a0 team blocks + globals
		events = []

	func u8(off: int) -> int: return b.decode_u8(off)
	func u16(off: int) -> int: return b.decode_u16(off)
	func s32(off: int) -> int: return b.decode_s32(off)
	func set_u8(off: int, v: int) -> void: b.encode_u8(off, v & 0xFF)
	func set_u16(off: int, v: int) -> void: b.encode_u16(off, v & 0xFFFF)
	func set_s32(off: int, v: int) -> void: b.encode_s32(off, v)
	func add_s32(off: int, v: int) -> void: b.encode_s32(off, b.decode_s32(off) + v)


# --- struct geometry --------------------------------------------------------
const SIDE_STRIDE := 0x7a0          # bytes per team block
const PLAYER_STRIDE := 0xac         # bytes per participant record
# participant field offsets (from the player record base)
const SEL := 0x88                   # u16 shirt / selected (0 = not in XI)
const STR := 0xbf                   # u8 strength / condition
const GKSAVE := 0xc0                # u8 keeper save rating (player[0] only)
const PASS := 0xc2                  # u8 passing/tackling seed
const POS := 0xc8                   # i32 position code -> POS_WEIGHT
const ROLE := 0xcc                  # i32 role flag (2/3 = watched pair, 1 = special)
const D4 := 0xd4                    # i32 event slot A (assist/booking)
const D8 := 0xd8                    # i32 event slot B
const DC := 0xdc                    # i32 pending-shot marker
const E0 := 0xe0                    # i32 slot A payload
const E4 := 0xe4                    # i32 slot B payload
const E8 := 0xe8                    # i32 shot payload
const TEAMID := 0x7e8               # u16 team id (per team block)
const SHAPE := 0xbb                 # u8 team shape/aggression (per team block)
const POSS := 0x64                  # i32 possession (team0); team1 at SIDE_STRIDE+0x64 = 0x804

## Position -> attacking-threat weight, DAT_006532ec @ 0x6532ec. 19 entries; the
## central-striker slot (9) carries the heaviest weight (35); GK slots (0/1) weigh 0.
const POS_WEIGHT := [0, 0, 3, 3, 3, 7, 7, 12, 10, 35, 10, 12, 15, 18, 15, 3, 18, 18, 10]

## FUN_004510b0 per-period minute offset switched on event type (= segment index).
const MINUTE_OFFSET := [0, 0x2d, 0x5a, 0x69]


static func _player(side: int, idx: int) -> int:
	return side * SIDE_STRIDE + idx * PLAYER_STRIDE


# --- FUN_004510b0: append an event ------------------------------------------
## type is the segment index for goals (per-period minute offset applied), or 4 for
## penalties (no offset). payload = (scorerShirt << 16) | teamId.
static func _emit(mem: Mem, type: int, minute: int, p4: int, payload: int) -> void:
	var m := minute
	if type >= 1 and type <= 3:
		m += MINUTE_OFFSET[type]
	mem.events.append({"type": type, "minute": m, "p4": p4, "payload": payload})


# --- FUN_00450d20: count a shirt's scoring events ---------------------------
static func _count_events(mem: Mem, shirt: int) -> int:
	var c := 0
	for e in mem.events:
		if e["type"] != 4 and ((e["payload"] >> 16) & 0xFFFF) == shirt and e["p4"] == 0:
			c += 1
	return c


# --- FUN_0044ec00: place a shot (pending-shot) marker -----------------------
static func _shot_marker(mem: Mem, side: int, idx: int, val: int) -> void:
	if side < 0 or side >= 2 or idx < 0 or idx >= 11:
		return
	var pb := _player(side, idx)
	if mem.u16(pb + SEL) == 0:
		return
	if mem.s32(pb + DC) != 0:
		return
	if int(mem.s32(pb + D4) != 0) + int(mem.s32(pb + D8) != 0) >= 2:
		return
	mem.set_s32(pb + DC, 1)
	mem.set_s32(pb + E8, val)
	# (binary then fires a UI vtable call -- a no-op headless.)


# --- FUN_0044ea40: place an assist/booking marker ---------------------------
static func _assist_marker(mem: Mem, side: int, idx: int, val: int) -> void:
	if side < 0 or side >= 2 or idx < 0 or idx >= 11:
		return
	var pb := _player(side, idx)
	if mem.u16(pb + SEL) == 0:
		return
	var bk := int(mem.s32(pb + D4) != 0) + int(mem.s32(pb + D8) != 0)
	if bk >= 2:
		return
	if mem.s32(pb + DC) != 0:
		return
	if bk == 0 or mem.s32(pb + E0) <= val:
		if mem.s32(pb + D4) == 0:
			mem.set_s32(pb + D4, 1)
			mem.set_s32(pb + E0, val)
		else:
			mem.set_s32(pb + D8, 1)
			mem.set_s32(pb + E4, val)
	# (binary then fires a UI vtable call -- a no-op headless.)


# --- FUN_0044ece0: resolve one created chance -------------------------------
## Resolve a chance for attacking `side` at `seg` (0..3), `minute` within-period.
## Appends a goal event, or does nothing on a keeper save / no eligible scorer.
static func _resolve(mem: Mem, rng: Rng, side: int, seg: int, minute: int) -> void:
	# keeper-save gate: defending side's player[0].
	var kbase := _player(1 - side, 0)
	if mem.u16(kbase + SEL) != 0:
		if rng.mod(130) < mem.u8(kbase + GKSAVE):
			return

	var abase := side * SIDE_STRIDE
	var total := 0
	for i in range(11):
		var pb := abase + i * PLAYER_STRIDE
		if mem.u16(pb + SEL) != 0:
			total += POS_WEIGHT[mem.s32(pb + POS)]

	# Scorer roulette over players 1..10 (GK excluded); re-roll until an available
	# player past the running threshold wins.
	var scorer := -1
	while scorer < 0:
		var roll := rng.mod(total) if total > 0 else 0
		var acc := 0
		for i in range(1, 11):
			var pb := abase + i * PLAYER_STRIDE
			if mem.u16(pb + SEL) == 0:
				continue
			acc += POS_WEIGHT[mem.s32(pb + POS)]
			if roll < acc and _available(mem, pb):
				scorer = i
				break
		if total <= 0:
			break
	if scorer < 0:
		return

	var pb := abase + scorer * PLAYER_STRIDE
	var payload := ((mem.u16(pb + SEL) & 0xFFFF) << 16) | (mem.u16(abase + TEAMID) & 0xFFFF)
	_emit(mem, seg, minute, 0, payload)


## A player can score only if fewer than two event slots are set and no pending shot.
static func _available(mem: Mem, pb: int) -> bool:
	var slots := int(mem.s32(pb + D4) != 0) + int(mem.s32(pb + D8) != 0)
	return slots < 2 and mem.s32(pb + DC) == 0


# --- FUN_00450510: per-segment player-stats accumulator ---------------------
## Consumes a data-dependent number of rand() draws (possession, an accumulation
## loop until `dur` "minutes", per-player pass/tackle/dribble/rating draws, an
## event-driven re-roll loop, and a bounded convergence loop). Its scoreline is
## unchanged, but its draw stream MUST match the binary or the second half desyncs.
static func _stats(mem: Mem, rng: Rng, dur: int, p3: int, p4: int) -> void:
	# possession bumps (M+0x64 / M+0x804)
	var iv12 := dur / 8
	mem.add_s32(POSS, ((rng.next() * iv12) >> 15) + dur / 40)
	mem.add_s32(SIDE_STRIDE + POSS, ((rng.next() * iv12) >> 15) + dur / 40)

	var cnt0 := []
	var cnt1 := []
	cnt0.resize(11); cnt0.fill(0)
	cnt1.resize(11); cnt1.fill(0)

	# accumulation loop: alternate side, advance player; each selected visit rolls
	# rand%200 vs strength (halved for role 0). Stop when total increments >= dur.
	var side := 0
	var pidx := 0
	while true:
		var pb := _player(side, pidx)
		if mem.u16(pb + SEL) != 0:
			var role := mem.s32(pb + ROLE)
			var strg := mem.u8(pb + STR)
			var thr := (strg >> 1) if role == 0 else strg
			if ((rng.next() * 200) >> 15) < thr:
				if side == 0:
					cnt0[pidx] += 1
				else:
					cnt1[pidx] += 1
		var total := 0
		for j in range(11):
			total += cnt0[j] + cnt1[j]
		side += 1
		if side == 2:
			side = 0
			pidx += 1
			if pidx > 10:
				pidx = 0
		if dur <= total:
			break

	# distribute the accumulation counters into +0xf4
	for s in range(2):
		for k in range(11):
			var pb := _player(s, k)
			if mem.u16(pb + SEL) != 0:
				mem.add_s32(pb + 0xf4, cnt0[k] if s == 0 else cnt1[k])

	# per-player stat draws
	for s in range(2):
		for idx in range(11):
			var pb := _player(s, idx)
			if mem.u16(pb + SEL) == 0:
				continue
			mem.set_s32(pb + 0xec, 0)
			var bk := int(mem.s32(pb + D8) != 0) + int(mem.s32(pb + D4) != 0)
			if bk < 2:
				if mem.s32(pb + DC) == 0:
					mem.add_s32(pb + 0xf0, dur)
				else:
					mem.set_s32(pb + 0xf0, mem.s32(pb + E8))
			else:
				mem.set_s32(pb + 0xf0, mem.s32(pb + E4))
			mem.set_s32(pb + 0xf8, 0)
			mem.set_s32(pb + 0xfc, _count_events(mem, mem.u16(pb + SEL)))
			var role := mem.s32(pb + ROLE)
			if idx != 0 and (role == 2 or role == 3):
				var i5 := (rng.next() * (p3 if s == 0 else p4))
				var i7 := rng.next()
				mem.add_s32(pb + 0x104, (i5 >> 15) + ((i7 * 2) >> 15))
			var pseed := mem.u8(pb + PASS)
			if role == 2:
				mem.add_s32(pb + 0x108, (((rng.next() * 10) >> 15) * pseed) / 100)
				mem.add_s32(pb + 0x10c, (((rng.next() * 0x19) >> 15) * (99 - pseed)) / 100)
			else:
				mem.add_s32(pb + 0x108, (((rng.next() * 8) >> 15) * pseed) / 100)
				mem.add_s32(pb + 0x10c, (((rng.next() * 0xf) >> 15) * (99 - pseed)) / 100)
			# dribble (+0x110): GK uses its own pass seed (param_1+0xc2+side base)
			var dseed := mem.u8(s * SIDE_STRIDE + PASS) if idx == 0 else pseed
			var i5b := (rng.next() * 2) if idx == 0 else (rng.next() * 5)
			mem.add_s32(pb + 0x110, ((i5b >> 15) * dseed) / 100)
			# rating (+0x114)
			var i5c := (rng.next() * 2) if idx == 0 else (rng.next() * 5)
			mem.add_s32(pb + 0x114, i5c >> 15)
			# booking / shot flags (no rand)
			var b11c := int(mem.s32(pb + D8) != 0) + int(mem.s32(pb + D4) != 0)
			mem.set_s32(pb + 0x11c, b11c)
			var s120 := int(mem.s32(pb + DC) != 0)
			mem.set_s32(pb + 0x120, s120)
			mem.set_s32(pb + 0x128, 0)
			mem.set_s32(pb + 0x124, int(b11c > 1) + s120)

	# block C: roll a per-player counter up to that player's event count (+0xfc)
	var acc := []
	acc.resize(22); acc.fill(0)
	var la8 := 0
	for s in range(2):
		for k in range(11):
			var pb := _player(s, k)
			if mem.u16(pb + SEL) != 0 and acc[k + la8] < mem.s32(pb + 0xfc):
				while true:
					acc[k + la8] += (rng.next() * 3) >> 15
					if not (acc[k + la8] < mem.s32(pb + 0xfc)):
						break
		la8 += 11

	# block D: bounded convergence loop (<=1000 iters)
	var la0 := 1000
	while true:
		var conv := true
		var base := 0
		for sd in range(2):
			for idx in range(11):
				var pb := _player(sd, idx)
				if mem.u16(pb + SEL) != 0:
					var role := mem.s32(pb + ROLE)
					if role == 2 or role == 3:
						acc[idx + base] += (rng.next() * 2) >> 15
					if role == 1 and (rng.next() & 1) == 0:
						acc[idx + base] += (rng.next() * 2) >> 15
					if acc[idx + base] < mem.s32(pb + 0xfc):
						conv = false
			base += 11
		var sum0 := 0
		for k in range(11):
			if mem.u16(_player(0, k) + SEL) != 0:
				sum0 += acc[k]
		var sum1 := 0
		for k in range(11):
			if mem.u16(_player(1, k) + SEL) != 0:
				sum1 += acc[11 + k]
		if conv and p3 <= sum0 and p4 <= sum1:
			break
		la0 -= 1
		if la0 < 1:
			break

	# block E: final distribution into +0x100 / +0x118 (no rand)
	var sum_s0 := 0
	var sum_s1 := 0
	for s in range(2):
		for k in range(10):
			var val: int = acc[s * 11 + 1 + k]
			mem.add_s32(_player(s, 1 + k) + 0x100, val)
			if s == 0:
				sum_s0 += acc[1 + k]
			else:
				sum_s1 += val
	for k in range(11):
		var p0 := _player(0, k)
		if mem.u16(p0 + SEL) != 0 and mem.s32(p0 + ROLE) == 0:
			mem.add_s32(p0 + 0x118, sum_s1 - p4)
		var p1 := _player(1, k)
		if mem.u16(p1 + SEL) != 0 and mem.s32(p1 + ROLE) == 0:
			mem.add_s32(p1 + 0x118, sum_s0 - p3)


# --- chance-count helpers (FUN_0044ee70 H1/H2 inner math) -------------------
## chances = rand%8 - avg_opp - 1 + avg_own; if <0 add rand%avg_own; clamp to 3-rand%3.
static func _chance_count(rng: Rng, avg_own: int, avg_opp: int) -> int:
	var c := ((rng.next() * 8) >> 15) - avg_opp - 1 + avg_own
	if c < 0:
		c += (avg_own * rng.next()) >> 15
	if (3 - ((rng.next() * 3) >> 15)) < c:
		c = 3 - ((rng.next() * 3) >> 15)
	return c


static func _avg_strength(mem: Mem, side: int) -> int:
	var total := 0
	var n := 0
	for i in range(11):
		var pb := _player(side, i)
		if mem.u16(pb + SEL) != 0:
			total += mem.u8(pb + STR)
			n += 1
	return total / n if n > 0 else 0


## One half (or extra-time segment for span 0xf): both sides' chance loops.
static func _half_chances(mem: Mem, rng: Rng, seg: int, span: int) -> void:
	var avg0 := _avg_strength(mem, 0)
	var avg1 := _avg_strength(mem, 1)
	var c0 := _chance_count(rng, avg0, avg1)
	for _i in range(c0):
		_resolve(mem, rng, 0, seg, ((rng.next() * span) >> 15) + 1)
	var c1 := _chance_count(rng, avg1, avg0)
	for _i in range(c1):
		_resolve(mem, rng, 1, seg, ((rng.next() * span) >> 15) + 1)


# --- buildup markers (1 shot pass + 2 assist passes per half) ---------------
static func _buildup_shot(mem: Mem, rng: Rng, span: int, base: int) -> void:
	# 4-coin gate (prob 1/16), short-circuit on first even draw.
	for _g in range(4):
		if (rng.next() & 1) == 0:
			return
	var side := rng.next() & 1
	var idx := (rng.next() * 0xb) >> 15
	if idx == 0:
		if mem.u8(side * SIDE_STRIDE + SHAPE) <= ((rng.next() * 100) >> 15):
			return
	_shot_marker(mem, side, idx, ((rng.next() * span) >> 15) + base)


static func _buildup_assist(mem: Mem, rng: Rng, span: int, base: int) -> void:
	if (rng.next() & 1) == 0:
		return
	var side := rng.next() & 1
	var idx := (rng.next() * 0xb) >> 15
	if idx == 0:
		if mem.u8(side * SIDE_STRIDE + SHAPE) <= ((rng.next() * 100) >> 15):
			return
	_assist_marker(mem, side, idx, ((rng.next() * span) >> 15) + base)


static func _buildup(mem: Mem, rng: Rng, span: int, base: int) -> void:
	_buildup_shot(mem, rng, span, base)
	_buildup_assist(mem, rng, span, base)
	_buildup_assist(mem, rng, span, base)


# --- FUN_0044ee70 (PS==5): simulate a full instant-result fixture -----------
## Drives the validated resolver + stats accumulator through the binary's segment
## ordering. LEAGUE matches (extra-time flag M+0x44 == 0, penalties flag M+0x48 == 0)
## are H1 + H2; ET / penalties are cup-only and not yet ported (see NEXT in the doc).
## On return mem.events holds the full goal queue (final score = goals per team id).
static func simulate(mem: Mem, rng: Rng) -> void:
	# first half (segment 0): buildup minutes rand%45 + 1
	_buildup(mem, rng, 0x2d, 1)
	_half_chances(mem, rng, 0, 0x2d)
	_stats(mem, rng, 0x2d, 0, 0)
	# (FUN_0044d0d0 half transition -- no rand, no event)
	# second half (segment 1): buildup minutes rand%45 + 46
	_buildup(mem, rng, 0x2d, 0x2e)
	_half_chances(mem, rng, 1, 0x2d)
	_stats(mem, rng, 0x2d, 0, 0)
	# (FUN_00450e60 full-time gate -- consumes no rand; result unused when ET/pen off.)
	# ET (segments 2/3) + penalties: cup-only, gated on M+0x44 / M+0x48. NOT YET PORTED.


## Final score as { teamId: goals } from the event queue (goals = non-penalty events).
static func score(mem: Mem) -> Dictionary:
	var s := {}
	for e in mem.events:
		if e["type"] != 4:
			var tid: int = e["payload"] & 0xFFFF
			s[tid] = int(s.get(tid, 0)) + 1
	return s
