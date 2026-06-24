class_name Pm98Action
extends RefCounted
## In-progress EXACT port of FUN_005a4600 -- the per-player OPEN-PLAY ENGINE (player vtable +0xc,
## run x2/tick by the FUN_005b8c20 dispatcher). See docs/re/MATCH_TICK_DRIVER_MAP.md, the corrected
## player-vtable section (base 0x639228, 2026-06-23) + the "FUN_005a4600 structural map" appendix.
## This is the +0xc pass the headless port MUST run as its per-tick player engine -- NOT the
## FUN_005a4560 replay no-op the driver currently runs. Built one decompiled leaf at a time, each
## oracle-verified bit-for-bit against the REAL function under the Ghidra PCode emulator.
##
## STATE: `tick_action`/`setup_kick` (the two prologue leaves) + the full `engine_tick` SKELETON are
## ported and oracle-GREEN (test_tickaction.gd 179; test_engine_tick.gd 183). engine_tick's leaf calls
## (7 action handlers, the resolver case 8/9, the case-0x13 shot-setup, the teammate-count, the 5
## movement fns) are NO-OP stubs pending their own oracle-gated ports (handoff Tasks #2/#3). See the
## engine_tick header for the exact scope + the transcription-only caveat (case 0x13 bVar17-true).
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


# --- FUN_005a4600 : engine_tick -- the per-player OPEN-PLAY ENGINE (player vtable +0xc) -------
## EXACT port of FUN_005a4600 (2632B). Run x2/tick by the FUN_005b8c20 dispatcher (the +0xc pass)
## as the headless per-tick player sim. Faithful transcription of the decompile + objdump-verified
## thiscall receivers (ESI=player throughout; FUN_005b0b40/005943b0 take ECX=match-or-player as noted;
## FUN_00590c10 point = player+4 box = match+0x1828).
##
## STEP-1 SCOPE (this slice = handoff Task #1): the SKELETON's own inline arithmetic + control flow is
## the load-bearing surface oracle-verified here. The leaf calls are STUBS to be filled + oracle-gated
## in handoff Tasks #2 (7 action handlers FUN_005acc40/ad010/ad970/adc60/adfc0/ae4c0/ae910) and #3
## (5 movement fns FUN_005a8680/65a0/9490/7260/8f20), plus the resolver case 8/9 (FUN_005aeda0 ->
## Pm98Resolver), the case-0x13 shot-setup FUN_005ac1a0, and the teammate-count FUN_005b0b40. Each
## stub is a NO-OP here AND in the skeleton oracle (PcodeEmu `stub` directive) so the skeleton's field
## writes match bit-for-bit; the leaves get wired + re-oracled in their own tasks.
##
## CAVEAT -- case 0x13 bVar17-true block (the kick-aim teammate search + ball launch, L137-193 of the
## decompile) is transcription-only this slice: it is NOT exercised by the Step-1 oracle fixtures
## (they keep +0x2c != 5 so bVar17 is false). It gets its own oracle when case 0x13 is gated.
static func engine_tick(p: Dictionary, m: Dictionary) -> void:
	trace_calls.clear()                    # Step-1 leaf-selection hook (see STUB section)
	var gs := _ref(p, 0x184)               # player+0x184 -> game/highlights state object
	var b := _ref(p, 0x190)                # player+0x190 (decompile "+400") -> the ball

	# --- prologue flags (L30-39) ---
	# FUN_00606220() is a verified no-op (size 1, `ret`).
	p[0x2d7] = 0
	var flag := 0
	if _sign1(_si(p, 4)) != _sign1(_si(p, 0x3a4)):
		if _count_teammates_closer(p, 0xfffe0000) <= 1:   # STUB FUN_005b0b40 (>1 -> flag 0)
			flag = 1
	p[0x2d8] = flag

	# --- 16-tick stamina/recovery block (L40-71): only on the +0x88 low-nibble wrap ---
	var ctr := (_g(p, 0x88) + 1) & 0xf
	p[0x88] = ctr
	if ctr == 0:
		var s68 := _si(p, 0x68)
		if s68 < 0x777:
			var s74 := _si(p, 0x74)
			if _si(p, 0x70) < s74:
				var v := _idiv(_si(p, 0x78) * 5, 2) + _si(p, 0x70)
				if v < s74:
					s74 = v
				p[0x70] = Pm98Trig._i32(s74)              # LAB_005a46d4
		elif s68 < 0x1334:
			if 0xd55 < s68 and _si(p, 0x78) < _si(p, 0x70):
				p[0x70] = Pm98Trig._i32(_si(p, 0x70) - _idiv(_si(p, 0x78), 2))
		elif _si(p, 0x78) < _si(p, 0x70):
			p[0x70] = Pm98Trig._i32(_si(p, 0x70) - _si(p, 0x78))
		if _si(p, 0x70) < _idiv(_si(p, 0x74) * 4, 5):
			var div := _si(m, 0x19ac)
			var nv := Pm98Trig._i32(_si(p, 0x74) - _idiv(72000, div))
			p[0x74] = nv if nv >= 0 else 0               # ((nv<0)-1) & nv == clamp >=0

	# --- the per-player action / animation-phase advance (L72) ---
	tick_action(p, m)
	p[0x6c] = 0

	# --- possession / touch counters (L73-79): phase 0 only (playback flag DAT_006d31c4==0 live) ---
	if _g(m, 0x448) == 0:
		p[0x50] = Pm98Trig._i32(_si(p, 0x50) + 1)
		var bk: Variant = b.get(0x44, null)
		if bk is Dictionary and bk == p:                 # player == ball+0x44
			p[0x4c] = Pm98Trig._i32(_si(p, 0x4c) + 1)
			gs[0x2e8] = Pm98Trig._i32(_g(gs, 0x2e8) + 1)

	# --- the action-code switch (L80-236): exactly one arm fires (post-tick_action +0x40) ---
	_action_switch(p, m, gs, b)

	# --- power-button accumulators (L237-266): user input via gs+0x214/+0x215; headless = both 0 ---
	if _highlight_active(p, m, gs):
		if (_g(gs, 0x214) & 0xff) != 0:
			p[0x58] = mini(_si(p, 0x58) + 1, 0x10)
		if (_g(gs, 0x215) & 0xff) != 0:
			p[0x54] = mini(_si(p, 0x54) + 1, 0x10)

	# --- motion-timer / interpolation vs movement-decision (L267-375) ---
	if _g(p, 0x80) != 0:
		p[0x80] = Pm98Trig._i32(_si(p, 0x80) - 1)
	var steps := _si(p, 0x84)
	if _g(p, 0x80) == 0 and steps != 0:
		# interpolate facing (+0x34 WORD) + position (+4/+8/+0xc) toward (+0x66 / +0x94/+0x98/+0x9c).
		p[0x84] = Pm98Trig._i32(steps - 1)
		p[0x34] = Pm98Trig._s16(_idiv(Pm98Trig._s16(_g(p, 0x66) - _g(p, 0x34)), steps) + _g(p, 0x34))
		p[8] = Pm98Trig._i32(_si(p, 8) + _idiv(_si(p, 0x98) - _si(p, 8), steps))
		p[4] = Pm98Trig._i32(_si(p, 4) + _idiv(_si(p, 0x94) - _si(p, 4), steps))
		p[0xc] = Pm98Trig._i32(_si(p, 0xc) + _idiv(_si(p, 0x9c) - _si(p, 0xc), steps))
	else:
		_movement_decision(p, m, gs, b)

	# --- LAB_005a4e5b (L376-425): the +0x40-gated 9490 lean + the 7260 locomotion ---
	var act := _g(p, 0x40)
	if act != 0x1d and act != 5 and act != 0x24 and (_g(m, 0x461) & 0x40) == 0:
		_move_9490(p)                                    # STUB
	if _g(p, 0x2bc) == 0 and (_g(m, 0x461) & 0x40) == 0:
		var run_7260 := true
		if _g(m, 0x19a0) == 4:
			run_7260 = _penalty_box_gate_b(p, m)
		if run_7260:
			if (_g(m, 0x44c) != 7 and _g(m, 0x44c) != 5) or not _is_taker(p, m):
				_move_7260(p)                            # STUB

	# --- LAB_005a4fa2 (L426-465): the body-orient pass + the open-play power reset ---
	_move_8f20(p, _g(p, 0x34))                            # STUB (arg = facing)
	if _highlight_active(p, m, gs):
		if (_g(gs, 0x214) & 0xff) == 0 and _g(p, 0x40) >= 0 and _g(p, 0x40) <= 3:
			p[0x58] = 0
		if (_g(gs, 0x215) & 0xff) == 0 and _g(p, 0x40) >= 0 and _g(p, 0x40) <= 3:
			p[0x54] = 0


## L80-236: the action switch. Inline arms (6/7, 0x13, 0x1c, 0x1f/0x21) are ported here; the handler /
## resolver / shot-setup arms are stubs (Tasks #2). `rng` for cases 6/7 + 0x1c is the match seed; the
## Step-1 fixtures pick states where those arms draw 0 times, so engine_tick takes no rng here yet.
static func _action_switch(p: Dictionary, m: Dictionary, gs: Dictionary, b: Dictionary) -> void:
	var act := _g(p, 0x40)
	match act:
		4, 0x25:
			_h_acc40(p)                                  # STUB
		5, 0x24:
			_h_ad010(p)                                  # STUB
		6, 7:
			if _g(p, 0x2c) == FRAME_COUNT[act] - 1 and _g(p, 0x30) == 0:
				if _g(p, 0x48) == 0:
					var prepend: Variant = m.get(0x440, null)
					if prepend is Dictionary and prepend == p:   # match+0x440 == player
						p[0x48] = 5000
					else:
						# NOTE: a live windup here would draw 1 rng (FUN_005ec250); Step-1 fixtures
						# avoid this arm (bVar17 false), so the rng wire lands with Task #2.
						push_error("engine_tick case 6/7 windup-draw arm not wired (Task #2)")
				elif _si(p, 0x48) < 10:
					m[0x461] = _g(m, 0x461) & 0xf7
		8, 9:
			_resolve_action(p, m)                        # STUB -> FUN_005aeda0 / Pm98Resolver
		0x13:
			_case_distribution(p, m, gs, b)
		0x14, 0x16:
			_h_ae4c0(p)                                  # STUB
		0x15:
			_h_ae910(p)                                  # STUB
		0x19, 0x1a:
			_h_adfc0(p)                                  # STUB
		0x1c:
			# only fires the rng + set_position_code(0) when the ball still carries velocity.
			if _g(b, 0x20) != 0 or _g(b, 0x24) != 0 or _g(b, 0x28) != 0:
				push_error("engine_tick case 0x1c moving-ball arm not wired (Task #2)")
		0x1f, 0x21:
			b[0x20] = 0
			b[0x24] = 0
			b[0x28] = 0
			# the 3 anim-descriptor copies (DAT_00665158->_665154 etc.) are display-only; tracked as
			# the same m["anim_*"] slots tick_action uses, sourced from the const .data display state.
			m["anim_665154"] = m.get("anim_src_665158", 0)
			m["anim_66502c"] = m.get("anim_src_665030", 0)
			m["anim_67455c"] = m.get("anim_src_674560", 0)
		0x36:
			_h_ad970(p)                                  # STUB
		0x37:
			_h_adc60(p)                                  # STUB


## L127-194: case 0x13 (keeper-distribution / kick windup). The set_phase nudge is skeleton; the
## bVar17-true block (kick-aim teammate search + ball launch) is TRANSCRIPTION-ONLY this slice
## (not oracle-covered -- see engine_tick header). FUN_005ac1a0 (shot physics) is a Task-#2 stub.
static func _case_distribution(p: Dictionary, m: Dictionary, gs: Dictionary, b: Dictionary) -> void:
	if _g(p, 0x48) == 0 and _g(m, 0x448) == 3:
		Pm98Movement.set_phase(m, 1)
	if not (_g(p, 0x2c) == 5 and _g(p, 0x30) == 0):
		return                                           # bVar17 false -> only the set_phase nudge
	# bVar17 TRUE (transcription-only): aim toward the nearest eligible teammate, then launch the ball.
	var sc := _g(p, 0x58) * 0x280000
	var pv := Pm98Trig.polar_vec(_asr4_bias(sc), _g(p, 0x34))
	var ax: int = int(pv[0]) + _si(p, 4)
	var ay: int = int(pv[1]) + _si(p, 8)
	var best := {}
	var best_d := 0x1f40000
	var tz := 0
	var base: Variant = gs.get(0, null)                  # **(p+0x184) -> [players_base, count]
	if base is Array:
		for q in (base as Array):
			if q is Dictionary and q != p and _g(q, 700) != 0:
				var dx := _si(q, 4) - ax
				var dy := _si(q, 8) - ay
				var d := Pm98Trig.planar_mag(dx, dy)
				if d < best_d:
					best_d = d
					best = q
	if not best.is_empty():
		b[0x4c] = best
		p[0xa0] = _g(best, 4)
		tz = _g(best, 8)
		p[0xa4] = tz
		p[0xa8] = _g(best, 0xc)
	p[0xb4] = 0
	var pv2 := Pm98Trig.polar_vec(0x8000, _concat22(Pm98Trig._asr(tz, 16), _g(p, 0x34) & 0xffff))
	b[4] = Pm98Trig._i32(int(pv2[0]) + _si(p, 4))
	b[8] = Pm98Trig._i32(_si(p, 8) + int(pv2[1]))
	b[0xc] = 0x15c28                                     # L190 (pv2.z + p.c) then L191 overwrites z = launch height
	_shot_setup(p)                                       # STUB FUN_005ac1a0


## L281-375: choose between FUN_005a8680 (settle) and FUN_005a65a0(iStack_38) (the general move), or
## skip both (early goto LAB_005a4e5b). Both targets are Task-#3 stubs; the SELECTION is skeleton.
static func _movement_decision(p: Dictionary, m: Dictionary, gs: Dictionary, b: Dictionary) -> void:
	if _g(p, 0x2bc) == 0 and (_g(m, 0x461) & 0x40) == 0:
		var pen_skip := false
		if _g(m, 0x19a0) == 4:
			pen_skip = not _penalty_box_gate_a(p, m)
		if not pen_skip:
			if (_g(m, 0x44c) != 7 and _g(m, 0x44c) != 5) or not _is_taker(p, m):
				return                                   # goto LAB_005a4e5b (skip 8680/65a0)

	# LAB_005a4ce6: settle gate -> bVar17 + iStack_38.
	var bv := false
	var istack := 0
	if (_g(p, 0x63) & 0xff) == 0 and (_g(m, 0x461) & 0x40) == 0:
		var armed := _highlight_active(p, m, gs)
		if not armed \
				or (_g(p, 0x2bc) != 0 and _g(m, 0x448) == 6) \
				or (900 < _si(gs, 0x2dc)) \
				or (_truthy(m, 0x440) and _g(m, 0x448) == 0):
			bv = true                                    # LAB_005a4db0
	else:
		istack = 1
		bv = true                                        # LAB_005a4db0

	# LAB_005a4e3e: settle vs move (the controller / engaged / proximity resolution).
	var ctrl: Variant = b.get(0x40, null)
	if ctrl is Dictionary and ctrl == p:
		pass                                             # is controller -> use bv as-is
	else:
		var eng: Variant = b.get(0x4c, null)
		if eng is Dictionary and eng == p:
			bv = true
			istack = 1                                   # LAB_005a4e34
		elif not bv:
			if 0x78 < _si(gs, 0x2dc) \
					and absi(Pm98Trig._i32(_si(p, 4) - _si(b, 0xcc))) < 0x60000 \
					and absi(Pm98Trig._i32(_si(p, 8) - _si(b, 0xd0))) < 0x60000 \
					and absi(Pm98Trig._i32(_si(p, 0xc) - _si(b, 0xd4))) < 0x60000:
				bv = true
				istack = 1                               # LAB_005a4e34
	if not bv:
		_move_8680(p)                                    # STUB
		return
	_move_65a0(p, istack)                                # STUB


## L284-305: penalty/ET in-box + half + velocity gate (FUN_00590c10 box at match+0x1828). Returns the
## bVar17 that decides whether the first movement cascade proceeds (true) or skips to LAB_005a4ce6.
static func _penalty_box_gate_a(p: Dictionary, m: Dictionary) -> bool:
	var inb := _in_box6([_si(p, 4), _si(p, 8), _si(p, 0xc)], m, 0x1828)
	var bv: bool = inb \
		and absi(Pm98Trig._i32(_si(p, 4))) > Pm98Trig._i32(_si(m, 0x1820) - 0x108000) \
		and absi(Pm98Trig._i32(_si(p, 8))) <= 0x1428f4
	return bv and _sign1(_si(p, 4)) == _sign1(_si(p, 0x3a4))


## L389-419: the LAB_005a4e5b penalty/ET gate (explicit per-axis box, not FUN_00590c10). Returns
## whether the 7260 locomotion section proceeds (true) or jumps to LAB_005a4fa2.
static func _penalty_box_gate_b(p: Dictionary, m: Dictionary) -> bool:
	var inb := _si(p, 4) >= _si(m, 0x1828) and _si(p, 4) <= _si(m, 0x1834) \
		and _si(p, 8) >= _si(m, 0x182c) and _si(p, 8) <= _si(m, 0x1838) \
		and _si(p, 0xc) >= _si(m, 0x1830) and _si(p, 0xc) <= _si(m, 0x183c)
	var bv: bool = inb \
		and Pm98Trig._i32(_si(m, 0x1820) - 0x108000) < absi(Pm98Trig._i32(_si(p, 4))) \
		and absi(Pm98Trig._i32(_si(p, 8))) < 0x1428f5
	return bv and _sign1(_si(p, 4)) == _sign1(_si(p, 0x3a4))


# ---- skeleton helpers --------------------------------------------------------------------

## The binary's sign idiom `((-1 < x) - 1 & 0xfffffffe) + 1`: +1 for x>=0, -1 for x<0.
static func _sign1(x: int) -> int:
	return 1 if x >= 0 else -1


## L238-245 / L312-339 / L428-435: the highlight/replay-input gate -- gs+0x2ee set AND play-state 0
## AND player+0x5c set. Models the "user is steering this player during a highlight" condition; on the
## headless path gs+0x2ee is 0 so it is always false (no user input).
static func _highlight_active(p: Dictionary, m: Dictionary, gs: Dictionary) -> bool:
	return (_g(gs, 0x2ee) & 0xff) != 0 and Pm98Movement.play_state_eq(m, 0) and (_g(p, 0x5c) & 0xff) != 0


## player == match+0x438 (the active set-piece taker), by Dict identity.
static func _is_taker(p: Dictionary, m: Dictionary) -> bool:
	var t: Variant = m.get(0x438, null)
	return t is Dictionary and t == p


## a non-null pointer field (a live Dict ref or a nonzero raw int address).
static func _truthy(d: Dictionary, off: int) -> bool:
	var v: Variant = d.get(off, null)
	if v is Dictionary:
		return true
	return int(v) != 0 if (v is int or v is float) else false


## FUN_00590c10: 3D AABB containment of `point` in the 6-int box at m[off..off+0x14]
## (min = off/+4/+8, max = +0xc/+0x10/+0x14).
static func _in_box6(point: Array, m: Dictionary, off: int) -> bool:
	var px := Pm98Trig._i32(int(point[0]))
	var py := Pm98Trig._i32(int(point[1]))
	var pz := Pm98Trig._i32(int(point[2]))
	return _si(m, off) <= px and px <= _si(m, off + 0xc) \
		and _si(m, off + 4) <= py and py <= _si(m, off + 0x10) \
		and _si(m, off + 8) <= pz and pz <= _si(m, off + 0x14)


## `(x + (x >> 31 & 0xf)) >> 4` -- truncate-toward-zero divide-by-16 (the case-0x13 windup scale).
static func _asr4_bias(x: int) -> int:
	return (x + ((x >> 31) & 0xf)) >> 4


## CONCAT22(hi, lo16): the binary's high:low 32-bit pack of a 16-bit angle with garbage high bits.
static func _concat22(hi: int, lo16: int) -> int:
	return Pm98Trig._i32(((hi & 0xffff) << 16) | (lo16 & 0xffff))


# ---- STUB leaves (Task #2 action handlers / Task #3 movement fns) -------------------------
# Each is a faithful NO-OP placeholder, mirrored by a PcodeEmu `stub` in run_engine_oracle.sh so the
# skeleton's own field writes match bit-for-bit. They are replaced by oracle-gated ports in their tasks.
#
# STEP-1 VERIFICATION HOOK: because a stub writes no fields, its CALL is otherwise invisible; the leaves
# append [label, arg] to `trace_calls` so test_engine_tick.gd can assert the movement-fn SELECTION +
# ORDER + arg against the oracle's STUB lines. engine_tick clears it on entry. The hook drops out once
# the real leaves (which DO write fields) replace these stubs in Tasks #2/#3.
static var trace_calls: Array = []

## FUN_005b0b40 (thiscall player; 0xfffe0000): count teammates closer to goal than self. STUB -> 0.
static func _count_teammates_closer(_p: Dictionary, arg: int) -> int:
	trace_calls.append(["B0B40", arg])
	return 0

static func _h_acc40(_p: Dictionary) -> void: trace_calls.append(["ACC40", 0])     # FUN_005acc40 (case 4/0x25)
static func _h_ad010(_p: Dictionary) -> void: trace_calls.append(["AD010", 0])     # FUN_005ad010 (case 5/0x24)
static func _h_ae4c0(_p: Dictionary) -> void: trace_calls.append(["AE4C0", 0])     # FUN_005ae4c0 (case 0x14/0x16) -- port = Pm98Movement.kick_resolve(.,.,KICK_AE4C0) (oracle GREEN); wire here in Task #4
static func _h_ae910(_p: Dictionary) -> void: trace_calls.append(["AE910", 0])     # FUN_005ae910 (case 0x15) -- port = Pm98Movement.kick_resolve(.,.,KICK_AE910) (oracle GREEN); wire here in Task #4
static func _h_adfc0(_p: Dictionary) -> void: trace_calls.append(["ADFC0", 0])     # FUN_005adfc0 (case 0x19/0x1a) -- port = Pm98Movement.kick_resolve(.,.,KICK_ADFC0) (oracle GREEN); wire here in Task #4
static func _h_ad970(_p: Dictionary) -> void: trace_calls.append(["AD970", 0])     # FUN_005ad970 (case 0x36) -- port = Pm98Movement.feed_layoff_036 (oracle GREEN); wire here in Task #4
static func _h_adc60(_p: Dictionary) -> void: trace_calls.append(["ADC60", 0])     # FUN_005adc60 (case 0x37) -- port = Pm98Movement.feed_layoff_037 (oracle GREEN); wire here in Task #4
static func _resolve_action(_p: Dictionary, _m: Dictionary) -> void: trace_calls.append(["AEDA0", 0])  # FUN_005aeda0 (case 8/9)
static func _shot_setup(_p: Dictionary) -> void: trace_calls.append(["AC1A0", 0])  # FUN_005ac1a0 (case 0x13 bVar17-true) -- port = Pm98Movement.setup_shot (oracle GREEN); wire here in Task #4

static func _move_8680(_p: Dictionary) -> void: trace_calls.append(["M8680", 0])   # FUN_005a8680 (settle)
static func _move_65a0(_p: Dictionary, arg: int) -> void: trace_calls.append(["M65a0", arg])  # FUN_005a65a0 (general move)
static func _move_9490(_p: Dictionary) -> void: trace_calls.append(["M9490", 0])   # FUN_005a9490 (lean)
static func _move_7260(_p: Dictionary) -> void: trace_calls.append(["M7260", 0])   # FUN_005a7260 (locomotion)
static func _move_8f20(_p: Dictionary, facing: int) -> void: trace_calls.append(["M8f20", facing])  # FUN_005a8f20 (body orient)
