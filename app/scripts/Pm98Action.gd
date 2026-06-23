class_name Pm98Action
extends RefCounted
## In-progress EXACT port of FUN_005a4600 -- the per-player OPEN-PLAY ENGINE (player vtable +0xc,
## run x2/tick by the FUN_005b8c20 dispatcher). See docs/re/MATCH_TICK_DRIVER_MAP.md, the corrected
## player-vtable section (base 0x639228, 2026-06-23) + the "FUN_005a4600 structural map" appendix.
## This is the +0xc pass the headless port MUST run as its per-tick player engine -- NOT the
## FUN_005a4560 replay no-op the driver currently runs. Built one decompiled leaf at a time, each
## oracle-verified bit-for-bit against the REAL function under the Ghidra PCode emulator.
##
## STEP 1 (this slice) -- the two leaves the engine prologue needs:
##   * tick_action = FUN_005a50c0 (872B, docs/re/move/fn_005a50c0_FUN_005a50c0.c). The per-player
##     ACTION / ANIMATION-PHASE advancer that FUN_005a4600 calls first. It bumps the 2-bit sub-tick
##     counter +0x30; on its wrap (every 4th tick) it advances the animation frame +0x2c; on the
##     frame wrap it transitions to the next action (+0x40 = NEXT_ACTION[action]). The +0x68<0 path
##     plays the cycle in reverse. The 0x1d branch is the kick / GK-distribution windup (sets the
##     +0x94/0x98/0x9c trajectory endpoint, +0x80/+0x84 motion timers, +0x20/+0x24/+0x28 velocity,
##     advances the windup timer +0x48, enqueues the kick event, sets match phase 1). Returns the
##     frame "carry" (whole animation cycles elapsed this tick); the sole caller (FUN_005a4600 L72)
##     discards it, so the return is bookkeeping only -- the oracle verifies the field WRITES.
##   * setup_kick = FUN_005aac30 (247B, docs/re/move/fn_005aac30_FUN_005aac30.c). Sets the kick
##     trajectory for the ball CONTROLLER only: clears the windup timer +0x48; if the player owns
##     the ball (and action not 0x13/0x1d), a 0x36-unit (0x360000) vector along facing (+0x34) is
##     added to position -> the +0xa0 aim and +0x94 endpoint, with +0x80=1/+0x84=0xc motion timers
##     and a position-code via set_position_code.
##
## Field model identical to Pm98Movement/Pm98Events: a player / match is a Dictionary keyed by the
## integer struct offset, int32 values. `p`=player (+0x18c -> match, +0x190 -> ball), `m`=match.

# --- static tables (dumped from MANAGER.EXE .data; see tools/re/pe.py) -----------------------
# DAT_00664fb8: per-action animation FRAME COUNT, indexed by action code (+0x40). 0x40 entries.
const FRAME_COUNT: Array[int] = [
	1, 14, 14, 14, 8, 12, 12, 15, 20, 18, 12, 9, 1, 13, 14, 14,
	8, 18, 1, 11, 14, 14, 12, 8, 9, 15, 15, 10, 1, 0, 1, 1,
	1, 1, 14, 14, 12, 0, 23, 23, 23, 23, 25, 25, 25, 25, 17, 4,
	12, 19, 19, 19, 19, 12, 32, 10, 1, 14, 14, 14, 6, 6, 1, 4,
]
# DAT_00665208: per-action NEXT-ACTION on frame wrap, indexed by action code. 0x40 entries.
const NEXT_ACTION: Array[int] = [
	0, 1, 2, 3, 0, 0, 10, 10, 0, 0, 0, 0, 12, 0, 14, 15,
	0, 0, 18, 0, 0, 0, 10, 0, 0, 0, 0, 0, 28, 5, 30, 31,
	32, 33, 34, 35, 30, 30, 30, 30, 31, 31, 30, 30, 31, 31, 31, 31,
	31, 30, 30, 31, 31, 30, 30, 30, 56, 57, 58, 59, 56, 56, 62, 56,
]
# DAT_006650e0: anim-descriptor index table for the 0x1d windup (display state). 0x28 dumped.
const ANIM_E0: Array[int] = [
	7, 5, 5, 5, 8, 8, 5, 5, 5, 5, 5, 5, 8, 5, 5, 5,
	1, 1, 7, 5, 5, 5, 5, 5, 5, -8, 8, 5, 7, 0, 7, 7,
	7, 7, 5, 5, 8, 0, -8, 8,
]
# 0x1d windup direction/sequence tables: DAT_006653d0 (when +0x2bc==0) vs 0x6653c0 (when +0x2bc!=0).
const DIR_D0: Array[int] = [30, 34, 35]   # DAT_006653d0
const DIR_C0: Array[int] = [0, 1, 3]      # &s_HIJKLMNOXYZ...PQRSTUVW_006653a8 + 0x18


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


## A field read as a SIGNED 32-bit int (the store keeps a 64-bit GDScript int).
static func _si(d: Dictionary, off: int) -> int:
	return Pm98Trig._i32(int(d.get(off, 0)))


## A pointer field as the referenced Dictionary, or {} when null.
static func _ref(d: Dictionary, off: int) -> Dictionary:
	var v: Variant = d.get(off, null)
	return v if v is Dictionary else {}


## C signed integer division/modulo (truncate toward zero), matching the binary's idiv.
static func _idiv(a: int, b: int) -> int:
	if b == 0:
		return 0
	var q := int(abs(a) / abs(b))
	return -q if (a < 0) != (b < 0) else q


static func _imod(a: int, b: int) -> int:
	if b == 0:
		return 0
	return a - _idiv(a, b) * b


# --- FUN_005a50c0 : tick_action -------------------------------------------------------------
## Returns the frame carry (discarded by the caller; the field writes are load-bearing).
static func tick_action(p: Dictionary, m: Dictionary) -> int:
	var action := _g(p, 0x40)
	var sub := (_g(p, 0x30) + 1) & 3        # L18: +0x30 = (+0x30 + 1) & 3
	p[0x30] = sub

	if action != 0x1d:
		# --- common path (walking / running / most actions) (L20-57) ---
		if _g(p, 0x48) != 0:                 # action timer locked -> just count it down
			p[0x48] = Pm98Trig._i32(_si(p, 0x48) - 1)
			return sub
		if sub != 0:                         # advance the frame only on the sub-tick wrap
			return sub
		if _si(p, 0x68) < 0:                 # reverse-play branch (L28)
			if action >= 0 and action <= 3:
				var fc := FRAME_COUNT[action]
				var v := _g(p, 0x2c) - 1 + fc
				p[0x2c] = _imod(v, fc)
				return _idiv(v, fc)
		var v2 := _g(p, 0x2c) + 1            # forward frame advance (L42)
		var count := FRAME_COUNT[action]
		var carry := _idiv(v2, count)
		p[0x2c] = _imod(v2, count)
		if _g(p, 0x2c) != 0:
			return carry
		if action != 0x15:                   # frame wrapped -> next action (L49)
			var nxt := NEXT_ACTION[action]
			p[0x40] = nxt
			return nxt
		# action == 0x15: turn 90deg and restart in action 10 at frame 5 (L54)
		p[0x34] = Pm98Trig._s16(_g(p, 0x34) - 0x4000)
		p[0x40] = 10
		p[0x2c] = 5
		return carry

	# --- action == 0x1d : the kick / GK-distribution windup (L59-145) ---
	var dir: Array[int] = DIR_C0 if _g(p, 0x2bc) != 0 else DIR_D0   # piVar4 (L59-61)
	var t := _si(p, 0x48)
	if t == -0x78:                           # release frame (L64): assign role + lay the trajectory
		Pm98Movement.set_position_code(p, dir[0])
		setup_kick(p, m)
		p[0x48] = 0
		return 0                             # caller discards; binary's EAX here is a dead ptr
	if t != 0:
		if t == -0x50:                       # windup tier 1 (L71): just latch the anim descriptor
			_set_anim_descriptor(m, dir[0])
		elif t == -100:                      # windup tier 2 (L77): anim descriptor + lob trajectory
			_set_anim_descriptor(m, dir[2])
			_lay_lob_trajectory(p)
		_advance_windup(p, m, action)        # falls through to LAB_005a533e
		return _windup_frame(p)
	# t == 0 : kick release (L102-145)
	_set_anim_descriptor(m, dir[1])
	var pv := Pm98Trig.polar_vec(0x30000, _g(p, 0x34))   # FUN_005ee0f0(0x30000, facing)
	p[0x80] = 1
	p[0x94] = Pm98Trig._i32(_si(p, 0x4) - pv[0])
	p[0x66] = _g(p, 0x34) & 0xffff
	p[0x98] = Pm98Trig._i32(_si(p, 0x8) - pv[1])
	p[0x84] = 0x50
	p[0x9c] = Pm98Trig._i32(_si(p, 0xc) - pv[2])
	var phase := _g(m, 0x448)
	if phase == 4:
		Pm98Events.enqueue(m, 0xd, p, 0)
	elif phase == 5:
		Pm98Events.enqueue(m, 2, p, 0)       # (the +0x180a sound is display-only, skipped headless)
	elif phase == 7:
		Pm98Events.enqueue(m, 10, p, 0)      # (the FUN_005ec240/230 RNG bracket is net-zero headless)
	Pm98Movement.set_phase(m, 1)             # FUN_005942e0(1)
	_advance_windup(p, m, action)
	return _windup_frame(p)


## The anim-descriptor globals set in the 0x1d branch (display state; stored faithfully on the match
## so a later render pass would read them, but they do not affect the headless outcome). DAT_006744e8
## is BSS (zero at load) so _DAT_0067455c latches 0.
static func _set_anim_descriptor(m: Dictionary, idx: int) -> void:
	m["anim_665154"] = (ANIM_E0[idx] if idx >= 0 and idx < ANIM_E0.size() else 0)
	m["anim_66502c"] = (FRAME_COUNT[idx] if idx >= 0 and idx < FRAME_COUNT.size() else 0)
	m["anim_67455c"] = 0   # DAT_006744e8[idx] -- BSS, always 0


## The t==-100 "lob" trajectory (L77-99): a 0x30000 vector along facing -> +0x94 endpoint and a
## 0x1333 vector -> +0x20/+0x24/+0x28 velocity, with +0x80/+0x84 motion timers.
static func _lay_lob_trajectory(p: Dictionary) -> void:
	var pv := Pm98Trig.polar_vec(0x30000, _g(p, 0x34))
	var ez := Pm98Trig._i32(pv[2] + _si(p, 0xc))
	p[0x80] = 1
	p[0x84] = 0x28
	p[0x94] = Pm98Trig._i32(_si(p, 0x4) + pv[0])
	p[0x98] = Pm98Trig._i32(_si(p, 0x8) + pv[1])
	p[0x9c] = ez
	p[0x66] = _g(p, 0x34) & 0xffff
	var vv := Pm98Trig.polar_vec(0x1333, _g(p, 0x34))
	p[0x20] = vv[0]
	p[0x24] = vv[1]
	p[0x28] = vv[2]


## LAB_005a533e tail (L146-148): decrement the windup timer +0x48.
static func _advance_windup(p: Dictionary, _m: Dictionary, _action: int) -> void:
	p[0x48] = Pm98Trig._i32(_si(p, 0x48) - 1)


## LAB_005a533e frame logic (L149-162): on sub-tick wrap, advance (timer<-100) or reverse (timer<0)
## the windup animation frame. Returns the carry.
static func _windup_frame(p: Dictionary) -> int:
	var u := _si(p, 0x48)
	if _g(p, 0x30) == 0:
		if u < -100:
			var v := _g(p, 0x2c) + 1
			var c := FRAME_COUNT[_g(p, 0x40)]
			p[0x2c] = _imod(v, c)
			return _idiv(v, c)
		if u < 0:
			var c2 := FRAME_COUNT[_g(p, 0x40)]
			var v2 := _g(p, 0x2c) - 1 + c2
			p[0x2c] = _imod(v2, c2)
			return _idiv(v2, c2)
	return u


# --- FUN_005aac30 : setup_kick --------------------------------------------------------------
## Set the kick trajectory for the ball controller. No-op (only clears +0x48) when the player is not
## the controller, or its action is 0x13 / 0x1d.
static func setup_kick(p: Dictionary, _m: Dictionary) -> void:
	var action := _g(p, 0x40)
	p[0x48] = 0                              # L5aac39: clear the windup timer
	if action == 0x13 or action == 0x1d:
		return
	var ball := _ref(p, 0x190)               # player+0x190 -> ball
	# controller test: player IS the ball's controlling player (ball+0x40). Pointers are modelled by
	# identity; the port stores the controller as the same Dict ref, so compare references.
	var ctrl: Variant = ball.get(0x40, null)
	if not (ctrl is Dictionary and ctrl == p):
		return
	# aim = 0x36-unit vector along facing, added to position -> +0xa0 and +0x94 endpoint (L5aac68+).
	var av := Pm98Trig.polar_vec(0x360000, _g(p, 0x34))
	p[0xa0] = Pm98Trig._i32(av[0] + _si(p, 0x4))
	p[0xa4] = Pm98Trig._i32(av[1] + _si(p, 0x8))
	p[0xa8] = Pm98Trig._i32(av[2] + _si(p, 0xc))
	# the *12-scaled velocity (+0x20/+0x24/+0x28, each *3 via lea then <<2) added to position
	# -> +0x94/+0x98/+0x9c endpoint.
	var ex := Pm98Trig._i32(_si(p, 0x20) * 12 + _si(p, 0x4))
	var ey := Pm98Trig._i32(_si(p, 0x24) * 12 + _si(p, 0x8))
	var ez := Pm98Trig._i32(_si(p, 0x28) * 12 + _si(p, 0xc))
	# position code: 5 + (0x1f if on-pitch flag +0x2bc == 0 else 0) -> 0x24 off-pitch, 5 on-pitch.
	var pos_code := 5 + (0x1f if _g(p, 0x2bc) == 0 else 0)
	Pm98Movement.set_position_code(p, pos_code)
	p[0x80] = 1
	p[0x84] = 0xc
	p[0x66] = _g(p, 0x34) & 0xffff
	p[0x94] = ex
	p[0x98] = ey
	p[0x9c] = ez
