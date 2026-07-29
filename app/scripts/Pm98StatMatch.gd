class_name Pm98StatMatch
extends RefCounted
## PM98 STATISTICAL match engine -- the faithful port of the "instant result" /
## AI-vs-AI fixture simulator that MANAGER.EXE runs for every match the human does
## NOT watch positionally (career-match runner FUN_0044ee70, the PS==5 branch,
## lines 357-792). Unlike app/scripts/MatchEngine.gd (an ABSTRACTED per-shot model),
## every number here is lifted from the binary and validated against the real
## functions through the Ghidra PCode emulator. Full RE map: docs/re/stat_match_engine_re.md.
##
## Four binary functions are ported here, each oracle-anchored:
##   * FUN_0044ece0  chance/goal resolver    -> _resolve     (tools/re/run_statresolve_oracle.sh)
##   * FUN_00450510  per-segment stats accum  -> _stats       (tools/re/run_statacc_oracle.sh)
##   * FUN_0044ee70  PS==5 orchestration       -> simulate     (tools/re/run_statmatch_oracle.sh, end-to-end)
##   * FUN_00450e60  full-time / tie gate      -> ft_gate      (tools/re/run_ftgate_oracle.sh; no rand)
## plus the leaf helpers FUN_004510b0 (_emit), FUN_0044ec00 (_shot_marker),
## FUN_0044ea40 (_assist_marker), FUN_00450d20 (_count_events), and the gate's score
## readers FUN_00450d60/db0/e00/e30 (_side_score / _side_pens).
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
const TEAMID1 := 0xf88              # u16 side1 team id alias (= SIDE_STRIDE + TEAMID)
const SHAPE := 0xbb                 # u8 team shape/aggression (per team block)
const POSS := 0x64                  # i32 possession (team0); team1 at SIDE_STRIDE+0x64 = 0x804

# --- full-time / tie-resolution gate fields (FUN_00450e60 reads these) -------
# All i32 on the match struct. 0xff is the "no carry / single leg" sentinel.
const G_F20 := 0x20                 # two-legged flag (carry C/D into the aggregate when set)
const G_F24 := 0x24                 # decide-by-penalties enabled
const G_F28 := 0x28                 # aggregate-only (away-goals off) branch enable
const G_A := 0x2c                   # leg carry: side0 first-leg goals
const G_B := 0x30                   # leg carry: side1 first-leg goals
const G_C := 0x34                   # leg carry: alt side0 (used when G_F20 + G_F44 set)
const G_D := 0x38                   # leg carry: alt side1
const G_ET := 0x44                  # extra-time enabled (M+0x44)
const G_PEN := 0x48                 # penalties enabled (M+0x48)

## Position -> attacking-threat weight, DAT_006532ec @ 0x6532ec. 19 entries; the
## central-striker slot (9) carries the heaviest weight (35); GK slots (0/1) weigh 0.
const POS_WEIGHT := [0, 0, 3, 3, 3, 7, 7, 12, 10, 35, 10, 12, 15, 18, 15, 3, 18, 18, 10]

## FUN_004510b0 per-period minute offset switched on event type (= segment index).
const MINUTE_OFFSET := [0, 0x2d, 0x5a, 0x69]


## THREE UP FRONT — the port of MANAGER_HACK.EXE (docs/re/hack_three_forwards.md).
## OFF by default and OFF is bit-identical to stock: the EXE patch was proven in the
## Ghidra PCode emulator to leave draws, event count, final LCG state and score untouched
## for any XI with fewer than three forwards, and this port keeps that property by
## computing the stock `3 - rand()%3` cap (and consuming its draws) before flooring.
static var cheat_three_up_front := false

## The MANAGER-SIDE forced arm (2026-07-27, widened 2026-07-29): the side index (0/1)
## the manager is on when one of the manager-side triggers holds; -1 = nobody. Set by
## MatchSim around each simulate and reset after, so AI-vs-AI fixtures can never
## inherit it. Manager-side-only BY DESIGN: 178 of the 476 shipped clubs default to
## MIXED, so an any-side trigger would hand a third of the league six goals a week.
##
## Two manager-side triggers feed it (MatchSim decides, from the ratings dict
## Career._ratings_for builds):
##   * the chosen SHAPE fields three or more forward SLOTS (4-3-3, 3-4-3, 4-2-4, 5-2-3)
##   * the TEAM TACTICS MENTALITY lever is on MIXED PLAY
## The third trigger, the MANAGER_HACK.EXE original, is read off the match struct
## itself: three selected players whose NATURAL role is ATT (`_att_count`).
##
## The shape trigger was added because the natural-role one alone did not answer what
## the switch says on the tin. `Tactics.set_formation("4-3-3")` fills the front line
## with whoever is best available, and a squad with two natural forwards fields a
## midfielder in the third slot — so a manager who picked 4-3-3, saw 4-3-3 on the
## board and turned THREE UP FRONT on still got stock scorelines (Mats, 2026-07-27
## and again 2026-07-29: "the 4-3-3 cheat with guaranteed goals STILL doesn't work").
## This is a CHEAT, not an engine claim: the EXE patch's own trigger is unchanged and
## still the one the PCode oracle tests.
##
## With the switch OFF this is always -1 and every read below short-circuits
## identically to stock — the oracle fixtures are untouched.
static var cheat_manager_side := -1


static func _player(side: int, idx: int) -> int:
	return side * SIDE_STRIDE + idx * PLAYER_STRIDE


## Selected players with ROLE == 3 (ATT/FOR) in `side`'s XI — the cave's `att3` routine.
## Evaluated per side, so an AI team fielding three forwards gets the same buff.
static func _att_count(mem: Mem, side: int) -> int:
	var n := 0
	for i in range(11):
		var pb := _player(side, i)
		if mem.u16(pb + SEL) != 0 and mem.s32(pb + ROLE) == 3:
			n += 1
	return n


## Is the cheat armed for `side`? Any trigger: three natural forwards fielded (the
## MANAGER_HACK.EXE original, read off the match struct) or one of the manager-side
## triggers MatchSim resolved into `cheat_manager_side` (a three-forward SHAPE, or the
## MIXED PLAY lever).
static func _cheat_armed(mem: Mem, side: int) -> bool:
	if not cheat_three_up_front:
		return false
	return side == cheat_manager_side or _att_count(mem, side) >= 3


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
	# THREE UP FRONT (MANAGER_HACK.EXE hook 0x44ed04, docs/re/hack_three_forwards.md):
	# when the ATTACKING side triggers, the gate is skipped entirely -- draws included,
	# exactly as the cave does, so cheat-ON is not a re-roll of cheat-OFF.
	var kbase := _player(1 - side, 0)
	if not _cheat_armed(mem, side):
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
			# TAC. won (+0x110; the old "dribble" label is withdrawn, see stat_match_engine_re.md
			# §STATISTICS): GK uses its own pass seed (param_1+0xc2+side base)
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
	# THREE UP FRONT (hooks 0x44f802 / 0x44f899 / 0x44fb16 / 0x44fbb7): the stock cap
	# above has already run and consumed its draws; the cave only raises the result.
	# H1/H2 only — the extra-time loops (`_et_half`) are NOT patched, as in the EXE.
	if _cheat_armed(mem, 0):
		c0 = maxi(c0, 3)
	for _i in range(c0):
		_resolve(mem, rng, 0, seg, ((rng.next() * span) >> 15) + 1)
	var c1 := _chance_count(rng, avg1, avg0)
	if _cheat_armed(mem, 1):
		c1 = maxi(c1, 3)
	for _i in range(c1):
		_resolve(mem, rng, 1, seg, ((rng.next() * span) >> 15) + 1)


## Extra-time chance count (cup only) -- a DIFFERENT formula from the league halves:
## chances = (avg_own - avg_opp)/6 - 1 + rand%3; if <0 add ((avg_own/20) * rand)>>15.
## There is NO `3 - rand%3` upper clamp here (unlike _chance_count).
static func _et_chance_count(rng: Rng, avg_own: int, avg_opp: int) -> int:
	var c := (avg_own - avg_opp) / 6 - 1 + ((rng.next() * 3) >> 15)
	if c < 0:
		c += ((avg_own / 0x14) * rng.next()) >> 15
	return c


## One extra-time segment (seg 2 = ET1, seg 3 = ET2). Buildup markers, then each
## side's probabilistic tail loop -- `while count < chances/2 OR rand%4 == 0` -- so a
## segment can run on past its nominal chance budget. The `rand%4` is only drawn once
## `count` reaches `chances/2` (|| short-circuit), exactly like the binary.
static func _et_half(mem: Mem, rng: Rng, seg: int, base: int) -> void:
	_buildup(mem, rng, 0xf, base)
	var avg0 := _avg_strength(mem, 0)
	var avg1 := _avg_strength(mem, 1)
	var ch0 := _et_chance_count(rng, avg0, avg1)
	var count := 0
	while count < ch0 / 2 or ((rng.next() * 4) >> 15) == 0:
		_resolve(mem, rng, 0, seg, ((rng.next() * 0xf) >> 15) + 1)
		count += 1
	var ch1 := _et_chance_count(rng, avg1, avg0)
	count = 0
	while count < ch1 / 2 or ((rng.next() * 4) >> 15) == 0:
		_resolve(mem, rng, 1, seg, ((rng.next() * 0xf) >> 15) + 1)
		count += 1
	_stats(mem, rng, 0xf, 0, 0)


## FUN_0044ee70 penalty shootout (lines 743-787, cup only). First fix a non-level
## shootout score: s0/s1 = rand%6 each, then while level draw a coin for each side
## until they differ. Then emit one type-4 event per converted penalty for each side,
## drawing a taker idx = rand%11 until `sN` selected players have scored (an empty
## slot redraws without counting). Penalty events carry no minute offset and are
## excluded from the scoreline; they only record the shootout outcome.
static func _penalties(mem: Mem, rng: Rng) -> void:
	var s0 := (rng.next() * 6) >> 15
	var s1 := (rng.next() * 6) >> 15
	while s0 == s1:
		var r3 := rng.next()
		var r4 := rng.next()
		s1 += r4 & 1
		s0 += r3 & 1
	var tid0 := mem.u16(TEAMID)
	var tid1 := mem.u16(SIDE_STRIDE + TEAMID)
	var made := 0
	while made < s0:
		var pb := _player(0, (rng.next() * 0xb) >> 15)
		var sel := mem.u16(pb + SEL)
		if sel != 0:
			_emit(mem, 4, 0, 0, ((sel & 0xFFFF) << 16) | (tid0 & 0xFFFF))
			made += 1
	made = 0
	while made < s1:
		var pb := _player(1, (rng.next() * 0xb) >> 15)
		var sel := mem.u16(pb + SEL)
		if sel != 0:
			_emit(mem, 4, 0, 0, ((sel & 0xFFFF) << 16) | (tid1 & 0xFFFF))
			made += 1


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


# --- stat-commit cadence ----------------------------------------------------
## FUN_0044ee70 forks at @0x44eed9 on `DAT_00652a10 != 0` and, when that holds, on the
## per-team flags `M+0x7f0` / `M+0xf90` (@0x44eee6..@0x44eef4). Both zero -> the
## STATISTICAL branch at @0x44f5ce, which is what this file ports (all four
## FUN_00450510 call sites -- @0x44f90a / @0x44fc21 / @0x44ff46 / @0x450235 -- live in
## it). Otherwise the PRESENTED branch at @0x44eefa runs instead.
##
## A live read of the running career (2026-07-24, winedbg gdb proxy, RSP `m652a10,4`)
## returns **1**, so the manager's own fixture takes the PRESENTED branch. That settles
## the cadence contradiction logged in the 07-24 s4 handoff: nothing about the
## FUN_0044e440 oracle is wrong, it simply is not the branch the live sheets came from.
##
## CADENCE_PERIOD -- the statistical branch, traced instruction by instruction: commit
##   at every period transition. FUN_0044e440 zeroes participant +0xec..+0x12f
##   (@0x44e7ad..@0x44e7e0, unconditional) and FUN_00449990 overwrites the record with a
##   `rep movsd` of 0x12 dwords (@0x449a50), so a full-time record holds the SECOND HALF
##   only and MIN reads 45.
## CADENCE_MATCH -- the presented branch's MEASURED contract. Two live captures
##   (`screenshots/wine-captures-2026-07-24-statistics-live` and
##   `.../wine-captures-2026-07-24-cadence-season-store`) show the full-time sheet is
##   whole-match cumulative: MIN 45 -> 90 on every player who ran the 90, every column
##   monotone, and a player whose minutes were frozen by an event (Cole, red card at
##   20') frozen in every column too. The season store then gains exactly that sheet
##   (Beckham PASSES 61/70 -> 69/81 = +8/+11, his full-time row; MIN 630 -> 720). So the
##   report record must hold whole-match totals: commit ONCE, after the last period,
##   with no intermediate zeroing. The presented branch's internal commit sites
##   (@0x44f2b0, FUN_0044d3d0 @0x44d4d5, FUN_0044d520 @0x44d526) are NOT traced -- its
##   stat source is the positional engine, which is the separate M5 workstream -- so
##   this cadence is banked from the frames, not from the disassembly.
enum { CADENCE_PERIOD, CADENCE_MATCH }


# --- FUN_0044ee70 (PS==5): simulate a full instant-result fixture -----------
## Drives the validated resolver + stats accumulator through the binary's segment
## ordering. H1 + H2 always run. For a cup tie still level at full time the binary
## additionally plays extra time (segments 2/3) and a penalty shootout, each gated on
## a static flag (M+0x44 / M+0x48) AND the no-rand full-time gate FUN_00450e60 (which
## returns 0 only while the tie is level). That gate consumes no rand, so the caller
## passes its decision in as `run_et` / `run_pen`; league fixtures leave both false.
## On return mem.events holds the full event queue (goals = non-penalty events).
## `rep` is optional. When a Pm98StatStore.Report is passed the per-segment stat COMMIT
## is run at the exact points the binary runs it -- each period-transition handler calls
## FUN_0044e440. Traced call order inside FUN_0044ee70's PS==5 branch:
##   H1  _stats @0x44f90a -> FUN_0044d0d0 @0x44f911   (commit @0x44d0d3)
##   H2  _stats @0x44fc21 -> ft_gate      -> FUN_0044d190 @0x44fc3e (commit @0x44d193)
##   ET1 _stats @0x44ff46 -> FUN_0044d250 @0x44ff4d   (commit @0x44d253)
##   ET2 _stats @0x450235 -> ft_gate      -> FUN_0044d310 @0x450257 (commit @0x44d313)
##   pen FUN_00606220 @0x45040a -> FUN_0044d520 @0x450419 (commit @0x44d526 + MoM stamp)
## None of the handlers consumes rand(), so passing `rep` cannot perturb the stream --
## the oracle tests that omit it stay bit-identical.
## `pids` bridges the port's slot+1 participant ids to real global ids -- see
## Pm98StatStore.commit(). Ignored when `rep` is null.
## `cadence` picks WHEN the commit runs -- see the CADENCE_* block above. The default
## reproduces the statistical branch this file ports; CADENCE_MATCH reproduces the
## presented branch's measured whole-match record.
## `rep_ht`, when given under CADENCE_MATCH, receives a NON-ZEROING snapshot of the
## running per-player totals at the half transition — the half-time board's own
## STATISTICS table (Pm98StatStore.snapshot; the live sheets show it as a strict prefix
## of the full-time one). It never touches the accumulation the end-of-match commit reads.
static func simulate(mem: Mem, rng: Rng, run_et := false, run_pen := false,
		rep = null, pids := {}, cadence := CADENCE_PERIOD, rep_ht = null) -> void:
	var per_period: bool = rep != null and cadence == CADENCE_PERIOD
	# first half (segment 0): buildup minutes rand%45 + 1
	_buildup(mem, rng, 0x2d, 1)
	_half_chances(mem, rng, 0, 0x2d)
	_stats(mem, rng, 0x2d, 0, 0)
	# FUN_0044d0d0 half transition -- no rand, no event; commits the H1 stats
	if per_period:
		Pm98StatStore.commit(mem, rep, pids)
	elif rep_ht != null:
		Pm98StatStore.snapshot(mem, rep_ht, pids)
	# second half (segment 1): buildup minutes rand%45 + 46
	_buildup(mem, rng, 0x2d, 0x2e)
	_half_chances(mem, rng, 1, 0x2d)
	_stats(mem, rng, 0x2d, 0, 0)
	# (FUN_00450e60 full-time gate -- no rand; its result is `run_et` / `run_pen`.)
	# FUN_0044d190 full-time transition -- commits the H2 stats
	if per_period:
		Pm98StatStore.commit(mem, rep, pids)
	if run_et:
		# ET1 (segment 2): buildup minutes rand%15 + 91
		_et_half(mem, rng, 2, 0x5b)
		# FUN_0044d250 ET1->ET2 transition -- no rand; commits the ET1 stats
		if per_period:
			Pm98StatStore.commit(mem, rep, pids)
		# ET2 (segment 3): buildup minutes rand%15 + 106
		_et_half(mem, rng, 3, 0x6a)
		# (FUN_00450e60 ET gate) + FUN_0044d310 transition -- no rand
		if per_period:
			Pm98StatStore.commit(mem, rep, pids)
	if run_pen:
		# penalty shootout (FUN_00606220 finalize -- no rand)
		_penalties(mem, rng)
		# FUN_0044d520 -- the full-time handler; commits, then stamps the MoM flag
		if per_period:
			Pm98StatStore.commit(mem, rep, pids)
	# CADENCE_MATCH: the single end-of-match commit, on a participant block that was
	# never zeroed -- so every record holds the whole match, as the live sheets show.
	if rep != null and cadence == CADENCE_MATCH:
		Pm98StatStore.commit(mem, rep, pids)


# --- FUN_0044d5f0: the Mem-from-clubs bridge --------------------------------
## Build a match Mem from two selected XIs, mirroring FUN_0044d5f0 (the bridge that
## fills the participant records the stat engine reads). RE map + verified attr
## alignment: docs/re/stat_match_engine_re.md ("game_db-attr -> in-memory-offset map",
## loader FUN_00583bd0). The three attrs the stat engine actually consumes:
##   STR    = (VE + RE + AG + CA) >> 2     (FUN_005841e0 averages player+0x9c..0x9f;
##            runtime fatigue-scaling needs club-perf bands absent from game_db -> mean)
##   GKSAVE = PO                           (+10 if the GK / slot 0, clamp 99)
##   PASS   = PA
##   ROLE   = pos -> 0/1/2/3 (GK/DEF/MID/ATT)
##   POS    = posFine, the per-player fine position (game_db `posFine`, the EQUIPOS
##            Y-12 byte), used DIRECTLY as the POS_WEIGHT index = the scorer-roulette
##            weight (FUN_0044ece0); falls back to a representative per-role code when a
##            sparse record has no decoded fine position. Steers WHO scores, never the
##            goal count. Decode + cross-validation: docs/re/positions_re.md.
##
## `xi0`/`xi1` are ordered Arrays of up to 11 entries, slot 0 = the GK. An entry is a
## game_db player Dictionary ({"attrs": {...}, "pos": "GK"/"DF"/"MF"/"FW", "posFine": int});
## a null / non-Dictionary / attr-less / empty entry leaves that slot zeroed (SEL = 0).
const ROLE_OF := {"GK": 0, "DF": 1, "MF": 2, "FW": 3}
# Representative participant POS (-> POS_WEIGHT index) per broad role, used ONLY when a
# player has no decoded `posFine`. FW carries the heaviest scoring weight, GK zero,
# mirroring the central-striker bias of POS_WEIGHT.
const POS_OF := {"GK": 1, "DF": 3, "MF": 12, "FW": 9}
const POS_WEIGHT_N := 19  # POS_WEIGHT has 19 entries; a valid fine code indexes 0..18


static func _fill_participant(mem: Mem, side: int, idx: int, p: Variant) -> bool:
	var pb := _player(side, idx)
	if p == null or not (p is Dictionary):
		return false
	var attrs: Variant = (p as Dictionary).get("attrs", {})
	if not (attrs is Dictionary) or (attrs as Dictionary).is_empty():
		return false
	var a: Dictionary = attrs
	mem.set_u16(pb + SEL, idx + 1)   # shirt: slot+1 (game_db has no shirt; matches build_xi)
	var strg: int = (int(a.get("VE", 0)) + int(a.get("RE", 0)) \
			+ int(a.get("AG", 0)) + int(a.get("CA", 0))) >> 2
	mem.set_u8(pb + STR, strg)
	var gk: int = int(a.get("PO", 0))
	if idx == 0:
		gk = mini(gk + 10, 99)
	mem.set_u8(pb + GKSAVE, gk)
	mem.set_u8(pb + PASS, int(a.get("PA", 0)))
	var pos: String = str((p as Dictionary).get("pos", ""))
	# slot 0 is always the keeper; default an undecoded outfielder to MID.
	mem.set_s32(pb + ROLE, 0 if idx == 0 else int(ROLE_OF.get(pos, 2)))
	# POS = the per-player fine position (POS_WEIGHT index). Use the decoded `posFine`
	# when present + in range; else the representative per-role code (slot 0 = GK = 1).
	var fine: Variant = (p as Dictionary).get("posFine")
	var pos_idx: int = 1 if idx == 0 else int(POS_OF.get(pos, 12))
	if fine != null and int(fine) >= 0 and int(fine) < POS_WEIGHT_N:
		pos_idx = int(fine)
	mem.set_s32(pb + POS, pos_idx)
	return true


## Fill one team block (11 participant records + team id + shape byte). Returns the
## count actually selected. SHAPE (+0xbb) aliases participant-0's AG byte in the binary
## (the buildup loops read it as the keeper's aggression gate), so it is the GK's AG.
static func _fill_side(mem: Mem, side: int, xi: Array, team_id: int) -> int:
	var n := 0
	for idx in range(11):
		var p: Variant = xi[idx] if idx < xi.size() else null
		if _fill_participant(mem, side, idx, p):
			n += 1
	mem.set_u16(side * SIDE_STRIDE + TEAMID, team_id)
	var gk: Variant = xi[0] if xi.size() > 0 else null
	var shape := 0x32
	if gk is Dictionary and (gk as Dictionary).get("attrs", {}) is Dictionary:
		shape = int(((gk as Dictionary).get("attrs", {}) as Dictionary).get("AG", 0x32))
	mem.set_u8(side * SIDE_STRIDE + SHAPE, shape)
	return n


## Build a league-fixture Mem (no two-leg carry, ET/penalties off). For a cup tie set
## the carry / ET / pen fields on the returned Mem and pass run_et/run_pen to simulate().
static func build_mem(xi0: Array, xi1: Array, team_id0: int, team_id1: int) -> Mem:
	var mem := Mem.new()
	_fill_side(mem, 0, xi0, team_id0)
	_fill_side(mem, 1, xi1, team_id1)
	# League sentinels: single leg, no carry, ET/pen disabled (ft_gate -> straight winner).
	mem.set_s32(G_A, 0xff)
	mem.set_s32(G_B, 0xff)
	mem.set_s32(G_C, 0xff)
	mem.set_s32(G_D, 0xff)
	return mem


## High-level convenience: simulate a fixture from two XIs and return goals per side.
## Returns { home_goals, away_goals, mem } (mem retained for event/commentary use).
## `seed` seeds the msvcrt LCG (callers pass rng.randi() for reproducibility).
static func simulate_fixture(seed: int, xi0: Array, xi1: Array, team_id0: int, \
		team_id1: int, run_et := false, run_pen := false) -> Dictionary:
	var mem := build_mem(xi0, xi1, team_id0, team_id1)
	var rng := Rng.new(seed)
	simulate(mem, rng, run_et, run_pen)
	var sc := score(mem)
	return {
		"home_goals": int(sc.get(team_id0 & 0xFFFF, 0)),
		"away_goals": int(sc.get(team_id1 & 0xFFFF, 0)),
		"mem": mem,
	}


## Standalone extra time (two 15-min segments) on a fresh Mem -- for a two-legged cup
## tie whose 90-min legs were simulated separately and whose aggregate is level. Mirrors
## FUN_0044ee70's ET tail without the preceding H1/H2. Read the ET goals via score(mem).
static func simulate_extra_time(mem: Mem, rng: Rng, rep = null, pids := {}) -> void:
	_et_half(mem, rng, 2, 0x5b)
	_et_half(mem, rng, 3, 0x6a)
	# Standalone ET is always the whole "match" here, so it commits once (CADENCE_MATCH).
	if rep != null:
		Pm98StatStore.commit(mem, rep, pids)


## Final score as { teamId: goals } from the event queue (goals = non-penalty events).
static func score(mem: Mem) -> Dictionary:
	var s := {}
	for e in mem.events:
		if e["type"] != 4:
			var tid: int = e["payload"] & 0xFFFF
			s[tid] = int(s.get(tid, 0)) + 1
	return s


## Accumulated possession counters (FUN_00450510: M+0x64 / M+0x804,
## docs/re/stat_match_engine_re.md L144). Side 0 = the first XI passed to build_mem
## (home). Returns [poss_home, poss_away] as the raw i32 totals; the POSSESSION
## PERCENTAGE bar reads home/(home+away). Byte-exact real engine output -- NOT a
## fabricated stat, so surfacing it is faithful (the RE'd counters, not an invention).
static func possession(mem: Mem) -> Array:
	return [mem.s32(POSS), mem.s32(SIDE_STRIDE + POSS)]


## The scoreline goals (penalties excluded) as resolved records, sorted by minute, so the
## commentary feed can name the engine's OWN scorers instead of re-rolling its own. Each:
##   { minute:int, shirt:int, shot_side:int(0/1), credited_side:int(0/1), own_goal:bool }
## `shot_side` is the side whose player took the shot (SEL=slot+1 -> XI slot = shirt-1 on
## that side); `credited_side` is the side the goal counts FOR (the other side for an own
## goal). This port only emits normal goals (p4==0), but the own-goal path is kept faithful.
static func goal_events(mem: Mem, tid0: int, tid1: int) -> Array:
	var out: Array = []
	for e in mem.events:
		if e["type"] == 4:
			continue
		var shot_tid: int = e["payload"] & 0xFFFF
		var shirt: int = (e["payload"] >> 16) & 0xFFFF
		var og: bool = int(e["p4"]) != 0
		var shot_side := 0 if shot_tid == (tid0 & 0xFFFF) else 1
		var credited := shot_side if not og else 1 - shot_side
		out.append({"minute": int(e["minute"]), "shirt": shirt,
			"shot_side": shot_side, "credited_side": credited, "own_goal": og})
	out.sort_custom(func(a, b): return a["minute"] < b["minute"])
	return out


# --- FUN_00450d60 / db0: this-match score for one side --------------------------
## Counts a side's goals over the event queue (penalties excluded). The binary keys
## on two team ids per record: a normal goal (p4 == 0) credits the team in the low
## short of payload; an own goal (p4 != 0) credits the OTHER side -- so each reader
## passes its "own" id for normal goals and the "other" id for own goals.
static func _side_score(mem: Mem, own_tid: int, other_tid: int) -> int:
	var c := 0
	for e in mem.events:
		if e["type"] == 4:
			continue
		var tid: int = e["payload"] & 0xFFFF
		if e["p4"] == 0:
			if tid == (own_tid & 0xFFFF):
				c += 1
		elif tid == (other_tid & 0xFFFF):
			c += 1
	return c


# --- FUN_00450e00 / e30: penalty-shootout tally for one side --------------------
static func _side_pens(mem: Mem, tid: int) -> int:
	var c := 0
	for e in mem.events:
		if e["type"] == 4 and (e["payload"] & 0xFFFF) == (tid & 0xFFFF):
			c += 1
	return c


# --- FUN_00450e60: full-time / tie-resolution gate (NO rand) --------------------
## Returns the binary's byte verdict: 0 = still level (replay / play on),
## 1 = side 0 through, 2 = side 1 through. Reads the leg-carry fields and decision
## flags off the match struct and the four real score readers above. A direct
## transcription of FUN_00450e60 (docs/re/move/fn_00450e60_FUN_00450e60.c);
## oracle-anchored by tools/re/run_ftgate_oracle.sh / test_ftgate_oracle.gd.
## The caller of simulate() uses run_et := (ft_gate after H2 == 0) and
## run_pen := (ft_gate after ET == 0) for a cup tie still level.
static func ft_gate(mem: Mem) -> int:
	var tid0 := mem.u16(TEAMID)
	var tid1 := mem.u16(TEAMID1)
	# The four leaf readers are pure (no rand, no writes); the binary re-reads them,
	# so computing each once and reusing is behaviour-identical.
	var s0 := _side_score(mem, tid0, tid1)   # FUN_00450d60
	var s1 := _side_score(mem, tid1, tid0)   # FUN_00450db0
	var p0 := _side_pens(mem, tid0)          # FUN_00450e00
	var p1 := _side_pens(mem, tid1)          # FUN_00450e30

	var c := mem.s32(G_C)
	var carry0 := mem.s32(G_A)
	var carry1 := mem.s32(G_B)
	if c != 0xff and mem.s32(G_D) != 0xff and mem.s32(G_ET) != 0 and mem.s32(G_F20) != 0:
		carry1 = mem.s32(G_D)
		carry0 = c

	if mem.s32(G_PEN) == 0:
		return _gate_winner(s0, s1)

	if carry0 == 0xff and carry1 == 0xff:
		# single match (no carry): straight winner, else penalties if enabled.
		if s0 != s1:
			return 1 if s0 > s1 else 2
		if mem.s32(G_F24) == 0:
			return 0
		if p1 < p0:
			return 1
		return 0 if p1 <= p0 else 2

	if mem.s32(G_F28) != 0 and (mem.s32(G_ET) == 0 or mem.s32(G_F20) == 0 or c == 0xff):
		# aggregate only (away goals disabled): compare two-leg totals.
		var x := s0 + carry0
		var y := s1 + carry1
		if y < x:
			return 1
		return _gate_fd0(mem, x, y, p0, p1)

	# away-goals path: aggregate first, then away goals, then penalties.
	var decided := carry0 != carry1
	if not decided:
		decided = s0 != s1
	if decided:
		var x := s0 + carry0
		var y := s1 + carry1
		if x != y:
			if y < x:
				return 1
			if x < y:
				return 2
			return _gate_winner(s0, s1)   # LAB_0045106a (unreached when x != y)
	# aggregate level -> away goals: side0 carry vs side1 this-match score.
	if s1 < carry0:
		return 1
	return _gate_fd0(mem, carry0, s1, p0, p1)


## LAB_0045106a: straight this-match winner, mapped 1 / 2 / 0.
static func _gate_winner(a: int, b: int) -> int:
	if a > b:
		return 1
	return 2 if a < b else 0


## LAB_00450fd0: x <= y already; x < y -> side1, else penalties (if G_F24) else level.
static func _gate_fd0(mem: Mem, x: int, y: int, p0: int, p1: int) -> int:
	if x < y:
		return 2
	if mem.s32(G_F24) != 0:
		if p1 < p0:
			return 1
		if p0 < p1:
			return 2
	return 0
