class_name Pm98Movement
extends RefCounted
## EXACT port of MANAGER.EXE's per-tick movement layer (docs/re/EXACT_PORT_PLAN.md,
## Stage 3 task 2 -- the driver-called movement primitives). FIRST slice:
##   * select_nearest = FUN_005b8ce0 (__thiscall, this=sim-context) -- pick the
##     eligible player nearest to the ball (3D Euclidean) and make it the active
##     player, with an optional "in front of the ball's facing" cone gate. The
##     driver (FUN_00598740) calls it 2x/tick in the default open-play path, and
##     it is the else-branch fallback of the phase selector FUN_005b8f20.
##
## NAMING CORRECTION (vs the 2026-06-18 handoff): FUN_005b8f20 is the *phase-based
## active-player selector*, NOT "ball physics". The actual physics is spread across
## FUN_005b8690 (pairwise player/ball relationship matrix), FUN_005b94f0 (marker
## assignment) and this FUN_005b8ce0 (nearest-to-ball). Those remain to be ported.
##
## FUN_005b8ce0 decoded (disasm 0x5b8ce0..0x5b8f11, no RNG):
##   1. Entry ownership guard. ctrl=match+0x1650 (controlling player ptr), with
##      match+0x1664 the controlling team index; other=match+0x165c (a 2nd control
##      ptr) with other+0x2b8 its team. If our movement-context's team (ctx+0x8)
##      already controls via ctrl -> active := ctrl (no search). Else if it controls
##      via other -> active := other. Else run the nearest-player search.
##   2. Search: min-dist accumulator = 0x12c0000 (300.0 units in 16.16). For each
##      player with the on-pitch flag player+0x2bc != 0, dist = ftol(sqrt(dx^2 +
##      dy^2 + dz^2)) where d = player.xyz(+4/+8/+0xc) - ball.xyz(match+0x1614/
##      +0x1618/+0x161c). When find_in_front, gate first: skip unless
##      abs(s16(atan_angle(dx,dy) - ball.facing(match+0x1644))) < 0x3555 (a ~+/-75
##      deg cone). Nearest within 300u wins; below that, the prior active stays.
##      Special: if find_in_front==0 and the current active has the lock byte
##      player+0x5d != 0, keep it (skip the search).
##   3. Commit: clear old active's player+0x5c flag, set new active ptr (ctx+0x168),
##      set its +0x5c. If the active CHANGED and the new player's team-info flag
##      teaminfo(+0x184)+0x2ee is set AND the match phase (FUN_005943b0: new+0x18c ->
##      +0x468 -> +0xfa0 == 0) holds, zero the new active's velocity (+0x54/+0x58).
##   ftol is the binary's unbound msvcrt _ftol = truncate-toward-zero; GDScript
##   int(sqrt(.)) reproduces it (the oracle injects a faithful truncating _ftol --
##   the binary's `jmp [0x6233a4]` thunk is unmapped in the static image).
##
## STRUCT MODEL (matches Pm98Events/Pm98Predicates' offset->Variant Dictionaries,
## with one deliberate difference): player *pointers* are modelled as INDICES into
## ctx["players"] (an Array of player Dicts), because this function compares and
## stores player identities and iterates the array. A null pointer == index -1.
##   ctx["players"]  Array[Dictionary]  the 22-player array (base = *param_1)
##   ctx[0x8]        int                this movement-context's team index (param_1[2])
##   ctx[0x138]      Dictionary         the match (param_1[0x4e])
##   ctx[0x168]      int                active-player index, -1 = null (param_1[0x5a])
## match fields: 0x1614/0x1618/0x161c ball xyz, 0x1644 ball facing (s16),
##   0x1650 controlling-player INDEX (-1 none), 0x1664 controlling team index,
##   0x165c other-control-player INDEX (-1 none), 0x468 -> {0xfa0: phase}.
## player fields: 0x4/0x8/0xc xyz, 0x2bc on-pitch flag, 0x5c active flag, 0x5d lock,
##   0x54/0x58 velocity, 0x2b8 team, 0x184 -> {0x2ee: team flag}, 0x18c -> match.
##
## Oracle-validated bit-for-bit: tools/re/run_movement_oracle.sh -> the REAL
## FUN_005b8ce0 under the Ghidra PCode emulator (faithful _ftol injected + cos/atan
## LUT injected for the cone gate) -> specs/movement_oracle.txt, locked by
## test_movement.gd (every fixture's active index + all three +0x5c flags + the
## velocity reset).

const MIN_DIST := 0x12c0000   # local_44 seed = 300.0 units (16.16); search bound
const CONE := 0x3555          # half-cone for the find_in_front facing gate (~75 deg)


static func _g(d: Dictionary, off: int) -> int:
	return int(d.get(off, 0))


## A player field, or 0 when idx is null (-1) / out of range.
static func _pg(players: Array, idx: int, off: int) -> int:
	if idx < 0 or idx >= players.size():
		return 0
	return _g(players[idx], off)


## The 3D Euclidean ball-distance metric: ftol(sqrt(dx^2+dy^2+dz^2)), truncated.
## dx/dy/dz are int32 fixed-point; the sum is < 2^53 for any on-pitch geometry so
## it is exact as a float, and int() truncates toward zero like the binary's _ftol.
static func _ball_dist(p: Dictionary, bx: int, by: int, bz: int) -> int:
	var dx := _g(p, 0x4) - bx
	var dy := _g(p, 0x8) - by
	var dz := _g(p, 0xc) - bz
	return int(sqrt(float(dx * dx + dy * dy + dz * dz)))


## FUN_005b8ce0. Mutates ctx in place. find_in_front (param_2) gates the search to
## players within the +/-0x3555 cone of the ball's facing and forbids keeping a
## locked active without re-checking.
static func select_nearest(ctx: Dictionary, find_in_front: int) -> void:
	var players: Array = ctx.get("players", [])
	var team := _g(ctx, 0x8)
	var m: Dictionary = ctx.get(0x138, {})
	var active := int(ctx.get(0x168, -1))
	var best := active                                  # iVar6 = iVar8

	# Entry ownership guard (cond_A && cond_B -> search; else forced owner).
	var ctrl := int(m.get(0x1650, -1))
	if ctrl < 0 or _g(m, 0x1664) != team:               # cond_A
		var other := int(m.get(0x165c, -1))
		if other < 0 or _pg(players, other, 0x2b8) != team:   # cond_B -> search
			best = _search(players, team, m, active, find_in_front)
		else:
			best = other                                # ball owned via 0x165c
	else:
		best = ctrl                                     # ball owned via 0x1650

	# iVar8 = iVar6; bail (no commit) only when find_in_front and nothing selected.
	if find_in_front != 0 and best < 0:
		return
	_commit(ctx, players, m, active, best)


static func _search(players: Array, team: int, m: Dictionary, active: int, find_in_front: int) -> int:
	# find_in_front==0 + the current active is locked (player+0x5d) -> keep it.
	if active >= 0 and _pg(players, active, 0x5d) != 0 and find_in_front == 0:
		return active
	var bx := _g(m, 0x1614)
	var by := _g(m, 0x1618)
	var bz := _g(m, 0x161c)
	var facing := _g(m, 0x1644)
	var min_dist := MIN_DIST
	var best := active
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0:                           # not on pitch
			continue
		if find_in_front != 0:
			var dx := _g(p, 0x4) - bx
			var dy := _g(p, 0x8) - by
			var delta := Pm98Trig._s16(Pm98Trig.atan_angle(dx, dy) - facing)
			if absi(delta) >= CONE:                     # outside the facing cone
				continue
		var dist := _ball_dist(p, bx, by, bz)
		if dist < min_dist:
			best = i
			min_dist = dist
	return best


static func _commit(ctx: Dictionary, players: Array, m: Dictionary, old: int, new_idx: int) -> void:
	if old >= 0 and old < players.size():
		players[old][0x5c] = 0                          # clear old active flag
	ctx[0x168] = new_idx
	if new_idx < 0 or new_idx >= players.size():
		return
	var p: Dictionary = players[new_idx]
	p[0x5c] = 1                                          # set new active flag
	if new_idx == old:
		return
	var teaminfo: Dictionary = _ref(p, 0x184)
	# bVar2 = teaminfo+0x2ee != 0 AND phase==0 (FUN_005943b0 on new+0x18c) AND new+0x5c
	var reset := _g(teaminfo, 0x2ee) != 0 and _phase0(_ref(p, 0x18c)) and _g(p, 0x5c) != 0
	if reset:
		p[0x54] = 0
		p[0x58] = 0


## A nested struct pointer (Dictionary at d[off], or {} when unset).
static func _ref(d: Dictionary, off: int) -> Dictionary:
	var v: Variant = d.get(off, null)
	return v if v is Dictionary else {}


## FUN_005943b0: match phase (match+0x468 -> +0xfa0) == 0.
static func _phase0(m: Dictionary) -> bool:
	return _g(_ref(m, 0x468), 0xfa0) == 0


# =============================================================================
# Slice 2: the per-tick relationship matrix + role selection.
#   build_relationship_matrix = FUN_005b8690 (__fastcall this=sim-ctx) -- throttled
#     to every 8th call (ctx+0x2e0 counter & 7). Builds, per player, the pairwise
#     angle + projected-planar-distance to every other player (own team in this
#     context's slots, opponents in the other team's slots), plus +0x17c (nearest
#     opponent) and +0x180 (nearest opponent IN FRONT, within a ~65deg facing cone).
#     team-0's context additionally fills the cross-team half + every opponent's
#     fields, then calls _select_roles. NO RNG.
#   _select_roles = FUN_005b8a60 (called at 8690's tail) -- pick three OUR-team role
#     players into ctx role slots. NO RNG (the only float op is ftol(sqrt) ball dist).
#
# Disasm-verified (0x5b8690..0x5b8a4f + 0x5b8a60..0x5b8be8): tick gate `inc;and 7`,
# team-0 init gate `[ctx+8]==0`, opponent-seed const 0x3e80000 (1000.0), the cos/sin
# LUT reads (== Pm98Trig.cos_a/sin_a), the muladd16 projection (FUN_005edfb0), the
# atan (FUN_005ee080 == Pm98Trig.atan_angle), and 8a60's plain 3D ftol(sqrt(dx^2+
# dy^2+dz^2)) (x87 seq @5b8b81..5b8bb5, no axis scaling -- same metric as _ball_dist).
#
# MATRIX LAYOUT (per player, byte-offset keys, matching the binary's struct):
#   angle[slot + team*11] : short  at 0xb8 + (slot + team*0xb)*2   (s16, ang - facing)
#   dist [slot + team*11] : int32  at 0xe4 + (slot + team*0xb)*4   (projected planar)
#   +0x17c : nearest-opponent planar dist (int32, seed 1000.0)
#   +0x180 : nearest-opponent-in-front dist (int32, seed 1000.0, ~65deg cone)
# `slot` is the player's loop index == its +0x2c4; `team` its +0x2b8. The matrix keys
# never collide with the select_nearest fields (0x4/0x8/0xc/0x34/0x2b8/0x2bc/0x2c4/
# 0x3a4/0x54/0x58/0x5c/0x5d/0x184/0x18c) so both slices share one player Dict.

const MATRIX_INIT := 0x3e80000   # 1000.0 (16.16): +0x17c / +0x180 seed
const ROLE_INIT := 0x27100000    # 10000.0 (16.16): 8a60 min-ball / min-anchor seed
const FRONT_CONE := 0x2e39       # ~65deg half-cone for the +0x180 nearest-in-front gate


static func _angle_off(slot: int, team: int) -> int:
	return 0xb8 + (slot + team * 0xb) * 2


static func _dist_off(slot: int, team: int) -> int:
	return 0xe4 + (slot + team * 0xb) * 4


## Player facing angle, a `short` at +0x34.
static func _facing(p: Dictionary) -> int:
	return Pm98Trig._s16(_g(p, 0x34))


## FUN_005b8690. Mutates ctx (+ its players + the opponents at match+0x78c) in place.
static func build_relationship_matrix(ctx: Dictionary) -> void:
	var tick := (int(ctx.get(0x2e0, 0)) + 1) & 7
	ctx[0x2e0] = tick
	if tick != 0:                                       # throttle: 1 in 8 calls works
		return
	var players: Array = ctx.get("players", [])
	var team := _g(ctx, 0x8)
	var m: Dictionary = ctx.get(0x138, {})
	var opp: Array = m.get(0x78c, [])
	var opp_n := int(m.get(0x790, 0))

	# team-0 context seeds every opponent's nearest / nearest-in-front to 1000.0.
	if team == 0:
		for k in opp_n:
			opp[k][0x17c] = MATRIX_INIT
			opp[k][0x180] = MATRIX_INIT

	var n := players.size()
	for i in n:
		var pi: Dictionary = players[i]
		# within-team: each unordered pair (i, j), j > i, stored both directions.
		for j in range(i + 1, n):
			var pj: Dictionary = players[j]
			var dx := Pm98Trig._i32(_g(pj, 0x4) - _g(pi, 0x4))
			var dy := Pm98Trig._i32(_g(pj, 0x8) - _g(pi, 0x8))
			var ang := Pm98Trig.atan_angle(dx, dy)
			var proj := Pm98Trig.muladd16(dx, Pm98Trig.cos_a(ang), dy, Pm98Trig.sin_a(ang))
			pi[_angle_off(j, team)] = Pm98Trig._s16(ang - _facing(pi))
			pj[_angle_off(i, team)] = Pm98Trig._s16(ang - _facing(pj) - 0x8000)
			pj[_dist_off(i, team)] = proj
			pi[_dist_off(j, team)] = proj
		# cross-team half (team-0 context only). Opponents live in team slot 1.
		if team == 0:
			pi[0x17c] = MATRIX_INIT
			pi[0x180] = MATRIX_INIT
			for k in opp_n:
				var qk: Dictionary = opp[k]
				var dx := Pm98Trig._i32(_g(qk, 0x4) - _g(pi, 0x4))
				var dy := Pm98Trig._i32(_g(qk, 0x8) - _g(pi, 0x8))
				var ang := Pm98Trig.atan_angle(dx, dy)
				var proj := Pm98Trig.muladd16(dx, Pm98Trig.cos_a(ang), dy, Pm98Trig.sin_a(ang))
				pi[_angle_off(k, 1)] = Pm98Trig._s16(ang - _facing(pi))
				qk[_angle_off(i, 0)] = Pm98Trig._s16(ang - _facing(qk) - 0x8000)
				qk[_dist_off(i, 0)] = proj
				pi[_dist_off(k, 1)] = proj
				pi[0x17c] = mini(_g(pi, 0x17c), proj)
				qk[0x17c] = mini(_g(qk, 0x17c), proj)
				# nearest-IN-FRONT gates: read the angle just written into the matrix.
				var a_pi := Pm98Trig._s16(_g(pi, _angle_off(_g(qk, 0x2c4), _g(qk, 0x2b8))))
				if absi(a_pi) < FRONT_CONE:
					pi[0x180] = mini(_g(pi, 0x180), proj)
				var a_qk := Pm98Trig._s16(_g(qk, _angle_off(_g(pi, 0x2c4), _g(pi, 0x2b8))))
				if absi(a_qk) < FRONT_CONE:
					qk[0x180] = mini(_g(qk, 0x180), proj)
	_select_roles(ctx)


## FUN_005b8a60. Pick three OUR-team role players into ctx role slots (indices into
## ctx["players"], -1 = unset; match+0x1650 controller is likewise an index):
##   +0x1fc = furthest-from-anchor   (max |x - +0x3a4|)
##   +0x200 = nearest-to-anchor      (min |x - +0x3a4|)
##   +0x204 = in-possession candidate = nearest on-pitch player to the ball (3D),
##            forced to the controller (match+0x1650) when its team is ours.
## Only on-pitch players (+0x2bc != 0) count. Strict comparisons -> ties keep first.
static func _select_roles(ctx: Dictionary) -> void:
	var players: Array = ctx.get("players", [])
	var team := _g(ctx, 0x8)
	var m: Dictionary = ctx.get(0x138, {})
	var bx := _g(m, 0x1614)
	var by := _g(m, 0x1618)
	var bz := _g(m, 0x161c)
	var best_ball := ROLE_INIT
	var min_anchor := ROLE_INIT
	var max_anchor := 0
	var ctrl := int(m.get(0x1650, -1))
	if ctrl >= 0 and _g(m, 0x1664) == team:
		ctx[0x204] = ctrl
		best_ball = 0
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0:                           # off-pitch -> skip
			continue
		var anchor := absi(Pm98Trig._i32(_g(p, 0x4) - _g(p, 0x3a4)))
		if anchor > max_anchor:
			ctx[0x1fc] = i
			max_anchor = anchor
		if anchor < min_anchor:
			ctx[0x200] = i
			min_anchor = anchor
		var dist := _ball_dist(p, bx, by, bz)
		if dist < best_ball:
			ctx[0x204] = i
			best_ball = dist


# =============================================================================
# Slice 3: per-player marking-target selection (the leaf of FUN_005b94f0).
#   select_mark_target = FUN_005b36f0 (__fastcall this=player) -- a PURE selector
#   that returns the opponent index our player p_idx should mark (or -1). The
#   caller (FUN_005b94f0, the marker-assignment pass) writes the +0x150/+0x154
#   marker links; this function only reads + returns. NO RNG. Disasm-verified
#   0x5b36f0..0x5b3a03 (validity box/alt modes, the 0x18000/0x13333 out-of-box
#   mul16 penalty, the /15 x-gap mul16 penalty, the reciprocity inner loop).
#
# STRUCT MODEL (extends the matrix model): the player's own team descriptor (binary
# player+0x184) provides {base,count} = ctx["players"]/size + the tactical fields
# 0x2fc/0x300/0x310, modelled as ctx["team_desc"]; the opponent descriptor (player
# +0x188) = ctx[0x138][0x78c]/size. The current mark target (player+0xb0) and the
# return value are opponent INDICES (-1 = none). The 8690 relationship-matrix dists
# at _dist_off(slot, team) are consumed for both the candidate score and reciprocity.
# NULL CONVENTION: the binary's "already marked" test is `cand+0x154 != 0` (non-null
# marker pointer). In the index model the marker links (+0x150/+0x154) use -1 = none
# (index 0 is the real first player), so the faithful test is `!= -1` -- assign_markers
# (slice 4, FUN_005b94f0) writes a real our-team index 0 there, which `!= 0` would miss.

## FUN_005b36f0. Returns the opp index to mark, or -1.
static func select_mark_target(ctx: Dictionary, p_idx: int) -> int:
	var players: Array = ctx.get("players", [])
	var m: Dictionary = ctx.get(0x138, {})
	var opp: Array = m.get(0x78c, [])
	var td: Dictionary = ctx.get("team_desc", {})
	var p: Dictionary = players[p_idx]

	# Keep the current target while it stays valid (no search).
	var tgt_idx := int(p.get(0xb0, -1))
	if tgt_idx >= 0:
		var tgt: Dictionary = opp[tgt_idx]
		var valid: bool
		if _g(td, 0x310) == 0:                              # box mode: target inside box (inclusive)
			valid = _in_box_incl(p, tgt)
		else:                                               # alt mode: within a distance band
			var scale := _g(m, 0x1820)
			var thr1 := _g(td, 0x300) + scale
			var thr2 := _g(td, 0x2fc) + scale
			var band := absi(Pm98Trig._i32(_g(p, 0x1e0) - _g(p, 0x3a4)))
			var tx := absi(Pm98Trig._i32(_g(tgt, 0x4) + _g(tgt, 0x3a4)))
			valid = (tx < thr1) if band < thr1 else (tx < thr2)
		if valid:
			return tgt_idx

	# Scan for a new target: lowest score AND reciprocal (p is its nearest defender).
	var best := MATRIX_INIT
	var result := tgt_idx                                   # fallback = current target
	var p_metric := absi(Pm98Trig._i32(_g(p, 0x4) - _g(p, 0x3a4)))   # FUN_005b1c40(p)
	for k in opp.size():
		var cand: Dictionary = opp[k]
		if int(cand.get(0x154, -1)) != -1:                  # already a marker target -> skip
			continue
		var score := _g(p, _dist_off(_g(cand, 0x2c4), _g(cand, 0x2b8)))   # matrix dist p->cand
		if not _in_box_excl(p, cand):                       # out of box -> inflate score
			score = Pm98Trig.mul16(score, 0x13333 if _g(td, 0x310) != 0 else 0x18000)
		var cand_metric: int
		if _g(p, 0x2b8) == _g(cand, 0x2b8):
			cand_metric = absi(Pm98Trig._i32(_g(cand, 0x4) - _g(cand, 0x3a4)))   # FUN_005b1c40
		else:
			cand_metric = absi(Pm98Trig._i32(_g(cand, 0x4) + _g(cand, 0x3a4)))   # FUN_005b1c60
		if cand_metric <= p_metric:                         # x-gap penalty
			score = Pm98Trig.mul16(score, absi(Pm98Trig._i32(_g(cand, 0x4) - _g(p, 0x4))) / 0xf + 0x10000)
		if _g(cand, 0x2bc) != 0 and score < best:
			# reciprocity: find the nearest of OUR team to this candidate.
			var rbest := MATRIX_INIT
			var rnearest := -1
			for r in players.size():
				var rp: Dictionary = players[r]
				if _g(rp, 0x2bc) == 0:
					continue
				var rd := _g(cand, _dist_off(_g(rp, 0x2c4), _g(rp, 0x2b8)))
				if rd < rbest:
					rbest = rd
					rnearest = r
			if rnearest == p_idx:
				best = score
				result = k
	return result


## Inclusive marking-box test (validity path): p+0x210..+0x224 contains q's xyz.
static func _in_box_incl(p: Dictionary, q: Dictionary) -> bool:
	if _g(p, 0x210) > _g(q, 0x4) or _g(q, 0x4) > _g(p, 0x21c):
		return false
	if _g(p, 0x214) > _g(q, 0x8) or _g(q, 0x8) > _g(p, 0x220):
		return false
	if _g(p, 0x218) > _g(q, 0xc) or _g(q, 0xc) > _g(p, 0x224):
		return false
	return true


## Exclusive marking-box test (candidate path): strict bounds on all three axes.
static func _in_box_excl(p: Dictionary, q: Dictionary) -> bool:
	return (
		_g(p, 0x210) < _g(q, 0x4) and _g(q, 0x4) < _g(p, 0x21c)
		and _g(p, 0x214) < _g(q, 0x8) and _g(q, 0x8) < _g(p, 0x220)
		and _g(p, 0x218) < _g(q, 0xc) and _g(q, 0xc) < _g(p, 0x224)
	)


# =============================================================================
# Slice 4: the per-tick marker-assignment PASS (assembles slice 3's selector).
#   assign_markers = FUN_005b94f0 (__fastcall this=sim-ctx). param_1 IS the sim-ctx
#   (disasm 0x5b94f6: `mov ebx,ecx`, and every helper call is `mov ecx,ebx` -- so the
#   descriptor {base,count} the function iterates and the ctx threaded into the
#   70b0/70c0/8c90 helpers are ONE object), so ctx +0/+4/+8 = our players base/count/team.
#   Runs only while WE are NOT in possession (FUN_005b8c90: match+0x1664 == ctx+8).
#   Three passes (disasm-verified 0x5b94f0..0x5b9766, NO RNG):
#     (poss) possession changed (ball+0x58 != ball+0x54 == match+0x1668 != match+0x1664)
#            -> zero each OUR player's +0x13c..+0x178 marking block (FUN_005b13c0).
#     (A)    clear every OUR player's +0x150 (who-I-mark) / +0x154 (who-marks-me).
#     (B)    for each opponent that HOLDS the ball (its +0x190->+0x40 points back to
#            itself, OR it is ball+0x4c == match+0x165c) scan OUR team for the lowest-
#            scoring eligible marker and wire the pair. score = matrix dist(our->opp)
#            (the 8690 matrix at our+_dist_off(opp.slot,opp.team)) + |our.z-opp.z|/3;
#            eligibility = our on-pitch (+0x2bc) AND our anchor-gap < the opp's anchor-gap
#            (same-team abs(x-anchor) else abs(x+anchor)); best seed 1000.0 (0x3e80000).
#     (C)    fallback: every OUR on-pitch player still unmarked (+0x150 == none) runs
#            select_mark_target (FUN_005b36f0) and wires its +0x150 / the picked opp's
#            +0x154 (the +0x154 only when that opp is not already someone's mark).
#   Helpers (all take ctx as ECX): FUN_005b70b0 = match+0x1610 ball block; FUN_005b70c0
#   = opponent team descriptor (match + 0x78c - 800*team; team0 -> +0x78c, modelled here
#   as match[0x78c] like the other slices -- fixtures are team-0); FUN_005b8c90 = "we are
#   in possession". POINTER->INDEX model: +0x150 holds an OPP index, +0x154 an OUR-team
#   index, both -1 = none (the binary's null pointer; index 0 is the real first player).
static func assign_markers(ctx: Dictionary) -> void:
	var players: Array = ctx.get("players", [])
	var team := _g(ctx, 0x8)
	var m: Dictionary = ctx.get(0x138, {})
	var opp: Array = m.get(0x78c, [])

	# (poss) possession changed -> zero each OUR player's marking block.
	if _g(m, 0x1668) != _g(m, 0x1664):
		for p in players:
			_clear_mark_block(p)

	# gate: do nothing while WE hold the ball.
	if _g(m, 0x1664) == team:
		return

	# (A) clear every OUR player's marker links.
	for p in players:
		p[0x150] = -1
		p[0x154] = -1

	# (B) assign the best eligible marker to each ball-holding opponent.
	for qi in opp.size():
		var q: Dictionary = opp[qi]
		q[0x150] = -1
		q[0x154] = -1
		if not _holds_ball(m, opp, qi):
			continue
		var best := -1
		var best_score := MATRIX_INIT                        # 0x3e80000 = 1000.0
		for oi in players.size():
			var our: Dictionary = players[oi]
			var score := _g(our, _dist_off(_g(q, 0x2c4), _g(q, 0x2b8))) \
				+ absi(Pm98Trig._i32(_g(our, 0x8) - _g(q, 0x8))) / 3
			if _g(our, 0x2bc) == 0:                          # off pitch -> skip
				continue
			var q_metric: int
			if _g(our, 0x2b8) == _g(q, 0x2b8):
				q_metric = absi(Pm98Trig._i32(_g(q, 0x4) - _g(q, 0x3a4)))
			else:
				q_metric = absi(Pm98Trig._i32(_g(q, 0x3a4) + _g(q, 0x4)))
			var our_metric := absi(Pm98Trig._i32(_g(our, 0x4) - _g(our, 0x3a4)))
			if our_metric < q_metric and score < best_score:
				best_score = score
				best = oi
		if best >= 0:
			players[best][0x150] = qi                        # marker's target = opp
			q[0x154] = best                                  # opp's marker = our player

	# (C) fallback: each still-unmarked OUR on-pitch player picks its own target.
	for oi in players.size():
		var our: Dictionary = players[oi]
		if _g(our, 0x2bc) == 0 or int(our.get(0x150, -1)) != -1:
			continue
		var t := select_mark_target(ctx, oi)
		our[0x150] = t
		if t >= 0 and int(opp[t].get(0x154, -1)) == -1:
			opp[t][0x154] = oi


## FUN_005b13c0: zero a player's +0x13c..+0x178 marking block. The two pointer links
## (+0x150/+0x154) become -1 (the model's null); the rest are scalar state (-> 0).
static func _clear_mark_block(p: Dictionary) -> void:
	for off in [0x13c, 0x140, 0x144, 0x148, 0x158, 0x15c, 0x160, 0x164, 0x168, 0x16c, 0x170, 0x174, 0x178]:
		p[off] = 0
	p[0x150] = -1
	p[0x154] = -1


## The PASS-B "this opponent holds the ball" gate (disasm 0x5b958f..0x5b95b7). Either the
## opponent's controller block (q+0x190 -> +0x40) names the opponent itself, or it is the
## ball block's other-control slot (FUN_005b70b0 +0x4c == match+0x165c).
static func _holds_ball(m: Dictionary, opp: Array, qi: int) -> bool:
	var blk: Dictionary = _ref(opp[qi], 0x190)
	if int(blk.get(0x40, -1)) == qi:
		return true
	return int(m.get(0x165c, -1)) == qi
