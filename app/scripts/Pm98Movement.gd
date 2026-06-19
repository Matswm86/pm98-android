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


# =============================================================================
# Slice 5a: the per-tick PHASE-BASED active-player selector (first half).
#   select_active = FUN_005b8f20 (__fastcall this=sim-ctx) -- chooses ctx[0x168] (the
#   active player) by the match phase (match+0x448) and sets its +0x5c flag. Branches:
#     * FORCED override: a global byte (binary DAT_006d31c4, modelled as ctx["force_active"])
#       -> active = match+0x438, set flag, return (no phase logic).
#     * phase 6           -> active = player[0].
#     * phase 4           -> drop the two players with the highest +0x39c, then pick the
#                            highest +0x394 among the rest (signed; ties keep the first).
#     * else (0/1/3/...)  -> select_nearest(ctx, find_in_front=0) (the now-ported fallback).
#   In every case it first clears the OLD active's +0x5c and resets ctx[0x168] to none, and
#   at the end sets the NEW active's +0x5c. Disasm-verified 0x5b8f20 (gate/6/4/else) + the
#   final flag set 0x5b939f. POINTER->INDEX: ctx[0x168] / match+0x438 are player indices
#   (-1 = none); the return is that index. NO RNG on these paths.
#
# Slice 5b COMPLETES FUN_005b8f20 with its two remaining branches (no RNG; oracle-validated
# by run_selectactive5b_oracle.sh -> test_selectactive5b.gd):
#   * phase 2 -> the highest-priority on-pitch player by a STATIC priority table. The binary
#     reads `LUT[player+0x2c8]` from `&DAT_006392c8` (an int32 .rdata table, extracted bit-
#     for-bit into PHASE2_LUT; 20 entries -- doubles begin at 0x639318). The comparison is
#     `LUT[active] <= LUT[cand]`, so a TIE keeps the LATER on-pitch player (strictly unlike
#     phase 4's `<`, which keeps the first). Disasm 0x5b91xx: `mov ecx,[ecx*4+0x6392c8]`.
#   * phase 5/7 -> a PERSISTENT set-piece queue (ctx+0x208 buffer / ctx+0x20c count). On an
#     EMPTY queue it BUILDS (append every player in order), runs a verbatim selection pass,
#     computes a flag, maybe truncates to 1, maybe zeroes a bookkeeping field; then EVERY
#     call (build or not) POPS the front. CRITICAL: the build pass is NOT a clean descending
#     sort -- the binary caches queue[i] once per outer iteration (edi @5b91db) and the
#     comparator keeps comparing that CACHED value even after swaps move it, so the exact
#     swap sequence (not "sort by key") is what reproduces it (_select_phase57). key =
#     player+0x3a0 (+ player+0x388 when phase 7), signed; off-pitch (cached +0x2bc == 0)
#     always swaps. flag (ctx+0x2ed) = (ctx+0x2ee != 0) AND sub-phase in {0,2,4}
#     (FUN_005943f0/d0/b0 on match+0x468 -> +0xfa0). Truncate to 1 unless (flag == 0 AND
#     match+0x19a0 == 4); zero every player's +0x8c when bVar2 (all +0x8c were != 0) OR
#     match+0x19a0 != 4. QUEUE MODEL: ctx["queue"] = Array of player INDICES (the binary's
#     int32 pointer buffer); its size IS the count; it persists across calls so pops cycle.
#     The Win32 grower FUN_005bbf10 is a no-op (the Array self-grows); the pop's memmove
#     down-shift == pop_front. The oracle stubs FUN_005bbf10 and injects a faithful memmove.
static func select_active(ctx: Dictionary) -> int:
	var players: Array = ctx.get("players", [])
	var m: Dictionary = ctx.get(0x138, {})
	var active := int(ctx.get(0x168, -1))

	# Forced-active override (global DAT_006d31c4 != 0 -> active = match+0x438).
	if int(ctx.get("force_active", 0)) != 0:
		_set_flag5c(players, active, 0)
		var forced := int(m.get(0x438, -1))
		ctx[0x168] = forced
		if forced >= 0:
			_set_flag5c(players, forced, 1)
		return forced

	# Normal path: clear the old active, reset to none.
	_set_flag5c(players, active, 0)
	ctx[0x168] = -1

	var phase := _g(m, 0x448)
	if phase == 7 or phase == 5:
		_select_phase57(ctx, players, m, phase)
	elif phase == 4:
		_select_phase4(ctx, players)
	elif phase == 2:
		_select_phase2(ctx, players)
	elif phase == 6:
		ctx[0x168] = 0 if players.size() > 0 else -1
	else:
		select_nearest(ctx, 0)

	var a := int(ctx.get(0x168, -1))
	if a >= 0:
		_set_flag5c(players, a, 1)
	return a


## phase 4: active = the highest-+0x394 player after removing the two highest-+0x39c
## players. All comparisons signed; strict `<` so ties keep the earliest. On-pitch only.
static func _select_phase4(ctx: Dictionary, players: Array) -> void:
	var top1 := _argmax_field(players, 0x39c, -1, -1)
	var top2 := _argmax_field(players, 0x39c, top1, -1)
	ctx[0x168] = _argmax_field(players, 0x394, top1, top2)


## Index of the on-pitch (+0x2bc) player with the max signed `off` field, excluding the
## two given indices; -1 if none. Strict `<` keeps the first on a tie (matches the binary).
static func _argmax_field(players: Array, off: int, ex1: int, ex2: int) -> int:
	var best := -1
	for i in players.size():
		if _g(players[i], 0x2bc) == 0 or i == ex1 or i == ex2:
			continue
		if best < 0 or Pm98Trig._i32(_g(players[best], off)) < Pm98Trig._i32(_g(players[i], off)):
			best = i
	return best


## Set player+0x5c (the active flag) when idx is a valid index; null (-1) is a no-op.
static func _set_flag5c(players: Array, idx: int, val: int) -> void:
	if idx >= 0 and idx < players.size():
		players[idx][0x5c] = val


# --- slice 5b: phase 2 (static priority LUT) + phase 5/7 (set-piece queue) ---

## The static priority table `&DAT_006392c8` (int32 .rdata), extracted bit-for-bit from
## MANAGER.EXE (file offset 0x2380c8; the next 8 bytes 0x639318 are doubles, so it is
## exactly 20 entries). Indexed by player+0x2c8 (the position code copied from the squad
## struct at *(player+0x3b8) + 0x44); the value is the phase-2 selection priority.
const PHASE2_LUT := [0, 0, 0, 0, 0, 0, 0, 1, 2, 20, 3, 4, 18, 14, 16, 5, 12, 10, 6, 0]


## phase 2: active = the on-pitch player with the highest LUT[+0x2c8]. The binary's test is
## `LUT[active] <= LUT[cand]` (not `<`), so on a tie the LATER on-pitch player wins.
static func _select_phase2(ctx: Dictionary, players: Array) -> void:
	var best := -1
	for i in players.size():
		if _g(players[i], 0x2bc) == 0:
			continue
		if best < 0 or _lut2(players[best]) <= _lut2(players[i]):
			best = i
	ctx[0x168] = best


## PHASE2_LUT[player+0x2c8]. Position codes are 0..18 in practice; an out-of-range code
## would read into the trailing doubles in the binary, which never happens in a real match.
static func _lut2(p: Dictionary) -> int:
	var idx := _g(p, 0x2c8)
	if idx < 0 or idx >= PHASE2_LUT.size():
		return 0
	return int(PHASE2_LUT[idx])


## phase 5/7: the persistent set-piece queue. Builds on an empty queue (then truncates/zeroes
## per the flag), and EVERY call pops the front into the active slot. See the slice-5b block
## comment for the full decode. Mutates ctx (incl. ctx["queue"]) and the players in place.
static func _select_phase57(ctx: Dictionary, players: Array, m: Dictionary, phase: int) -> void:
	var queue: Array = ctx.get("queue", [])
	if queue.size() == 0:
		# BUILD: append every player in order; bVar2 = "every player had +0x8c != 0".
		var all_8c_nonzero := true
		for i in players.size():
			if _g(players[i], 0x8c) == 0:
				all_8c_nonzero = false
			queue.append(i)
		# Selection pass -- VERBATIM: queue[i] (`v`) is cached once per outer iteration and
		# the comparator keeps using it even after swaps move it (binary edi @5b91db). This
		# is NOT a clean descending sort; the exact swap sequence is the observable.
		var count := queue.size()
		for i in count:
			var v: int = queue[i]
			for j in range(i + 1, count):
				var do_swap := false
				if _g(players[v], 0x2bc) == 0:                       # cached v off-pitch -> swap
					do_swap = true
				elif _s32lt(_key57(players[v], phase), _key57(players[queue[j]], phase)):
					do_swap = true
				if do_swap:
					var t: int = queue[i]
					queue[i] = queue[j]
					queue[j] = t
		# +0x2ed flag = (ctx+0x2ee != 0) AND sub-phase (match+0x468 -> +0xfa0) in {0,2,4}.
		var flag := 0
		if _g(ctx, 0x2ee) != 0:
			var sub := _g(_ref(m, 0x468), 0xfa0)
			if sub == 0 or sub == 2 or sub == 4:
				flag = 1
		ctx[0x2ed] = flag
		# Truncate the queue to 1 unless (flag == 0 AND match+0x19a0 == 4).
		if (flag != 0 or _g(m, 0x19a0) != 4) and queue.size() > 1:
			queue.resize(1)
		# Zero every player's +0x8c when bVar2 OR match+0x19a0 != 4.
		if all_8c_nonzero or _g(m, 0x19a0) != 4:
			for p in players:
				p[0x8c] = 0
	# POP the front (every call): active = queue[0], shift down, count--.
	if queue.size() > 0:
		ctx[0x168] = queue[0]
		queue.pop_front()
	else:
		ctx[0x168] = -1
	ctx["queue"] = queue


## phase 5/7 sort key: player+0x3a0 (+ player+0x388 when phase 7), int32-wrapped (x86 add).
static func _key57(p: Dictionary, phase: int) -> int:
	var k := Pm98Trig._i32(_g(p, 0x3a0))
	if phase == 7:
		k = Pm98Trig._i32(k + Pm98Trig._i32(_g(p, 0x388)))
	return k


## Signed 32-bit less-than (the binary's SBORROW4 / setl comparator).
static func _s32lt(a: int, b: int) -> bool:
	return Pm98Trig._i32(a) < Pm98Trig._i32(b)


# ---- DECIDE coordinate helpers (FUN_005a44f0 / 5a4510 / 0059a0e0 / 5b11f0) -----------
# The per-team-side orientation + vec-compose primitives the per-player DECIDE
# (FUN_005a3400) and the positioning fn (FUN_005b73a0) call. Pure functions of the match
# orientation bit (match+0x19a0 & 1), the team (player+0x2b8), and the input vec(s).
# Oracle-pinned bit-for-bit by tools/re/run_decidehelper_oracle.sh ->
# specs/decidehelper_oracle.txt, locked in test_decidehelper.gd.


## FUN_005a44f0 (__thiscall match; team): the goal-target X for `team` -- match+0x1820,
## negated when (match+0x19a0 & 1) == team. (Disasm 0x5a4505 `jne` skips the neg, so the
## neg fires on EQUAL.)
static func goal_target_x(orient_19a0: int, x_1820: int, team: int) -> int:
	if (orient_19a0 & 1) == team:
		return Pm98Trig._i32(-x_1820)
	return Pm98Trig._i32(x_1820)


## FUN_005a4510 / FUN_0059a0e0: mirror a vec3 to `team`'s attacking side -- negate x and y
## when (match+0x19a0 & 1) ^ team != 0, copy z. 5a4510 takes match+team explicitly;
## 0059a0e0 derives both from the player (player+0x18c->match, player+0x2b8 team) but
## computes the identical formula, so both map here.
static func mirror_to_side(orient_19a0: int, team: int, v: Array) -> Array:
	if ((orient_19a0 & 1) ^ team) != 0:
		return [Pm98Trig._i32(-v[0]), Pm98Trig._i32(-v[1]), Pm98Trig._i32(v[2])]
	return [Pm98Trig._i32(v[0]), Pm98Trig._i32(v[1]), Pm98Trig._i32(v[2])]


## FUN_005b11f0 (__thiscall out; in2d, z): compose a 3-vec from a 2-vec + an explicit z.
## out = [in2d[0], in2d[1], z]. The binary ignores in2d[2].
static func vec_compose(in2d: Array, z: int) -> Array:
	return [Pm98Trig._i32(in2d[0]), Pm98Trig._i32(in2d[1]), Pm98Trig._i32(z)]


# ---- DECIDE state setters (FUN_005a5430 set-position-code / FUN_0058eca0 engage) ------
# The two state-mutating leaves the per-player DECIDE (FUN_005a3400) calls to record a
# player's assigned formation position and its current engagement target. Oracle-pinned
# bit-for-bit by tools/re/run_decideset_oracle.sh -> specs/decideset_oracle.txt, locked in
# test_decideset.gd.

## The static position-remap table `&DAT_00665208` (int32 .data), extracted bit-for-bit from
## MANAGER.EXE (file offset 0x263808, VA 0x665208). It maps each position code to its
## "canonical" code; codes that are their own canonical entry (value == index) are unchanged,
## the rest are remaps. The coherent table runs indices 0..0x49 (74 entries); a 0x01010101
## byte-object begins at 0x4a, but FUN_005a5430 only indexes by position code (<= ~0x1e in
## practice), so the boundary is never crossed.
const POS_REMAP_LUT := [
	0, 1, 2, 3, 0, 0, 10, 10, 0, 0, 0, 0, 12, 0, 14, 15,
	0, 0, 18, 0, 0, 0, 10, 0, 0, 0, 0, 0, 28, 5, 30, 31,
	32, 33, 34, 35, 30, 30, 30, 30, 31, 31, 30, 30, 31, 31, 31, 31,
	31, 30, 30, 31, 31, 30, 30, 30, 56, 57, 58, 59, 56, 56, 62, 56,
	56, 65, 66, 67, 66, 66, 66, 66, 66, 0,
]


## POS_REMAP_LUT[code]. Out-of-range codes (which a real formation never produces) return the
## code itself so the `code != remap` test below is false -- a safe "no remap" default.
static func _pos_remap(code: int) -> int:
	if code < 0 or code >= POS_REMAP_LUT.size():
		return code
	return int(POS_REMAP_LUT[code])


## FUN_005a5430 (__thiscall player; pos_code): record the player's assigned position code at
## +0x40. When the code is NOT its own canonical remap (POS_REMAP_LUT[code] != code), the
## position has changed slot, so clear the cached +0x2c/+0x30 (remap bookkeeping).
static func set_position_code(p: Dictionary, pos_code: int) -> void:
	p[0x40] = pos_code
	if pos_code != _pos_remap(pos_code):
		p[0x2c] = 0
		p[0x30] = 0


## FUN_0058eca0 (__thiscall player; target): engage `target` (a player index into ctx
## ["players"], -1 = null/none). The binary's null pointer (0) maps to index -1 here, so the
## "non-null target" guard is `target_idx >= 0`. The match is the player's +0x1d4 ref.
## When the target DIFFERS from the current engagement (player+0x40):
##   * record it at +0x40 and clear +0x4c;
##   * for a real (non-null) target: bump match+0x458 iff the cached team tag (player+0x54)
##     changes, copy the target's team (+0x2b8) into +0x54, latch +0x44/+0x48 to the target,
##     zero the target's +0x54/+0x58, bump the engagement counter +0x80, and -- only in open
##     play (match+0x448 == 0) with a live set-piece taker (match+0x460 != 0) that is NOT this
##     target -- clear that stale taker (match+0x460 = 0, match+0x43c = none).
static func set_engagement(p: Dictionary, target_idx: int, players: Array) -> void:
	if int(p.get(0x40, -1)) == target_idx:
		return
	p[0x40] = target_idx
	p[0x4c] = 0
	if target_idx < 0:                                      # binary: param_2 == 0 (null) -> done
		return
	var target: Dictionary = players[target_idx]
	var m: Dictionary = _ref(p, 0x1d4)
	var tteam := _g(target, 0x2b8)
	m[0x458] = _g(m, 0x458) + (1 if _g(p, 0x54) != tteam else 0)
	p[0x54] = tteam
	p[0x48] = target_idx
	p[0x44] = target_idx
	target[0x58] = 0
	target[0x54] = 0
	p[0x80] = _g(p, 0x80) + 1
	if _g(m, 0x448) == 0 and _g(m, 0x460) != 0 and int(m.get(0x43c, -1)) != target_idx:
		m[0x460] = 0
		m[0x43c] = -1


# ---- FUN_005a3400 the per-player DECIDE, slice A (prologue + bbox) --------------------
# The first ~100 instructions of the per-player movement-target computer: set the goal-X
# anchor, the two target endpoints, and the movement bounding box, all oriented by side.
# Reads match +0x1820 (goal-X scale) / +0x19a0 (orient bit) and player +0x2b8 (team) /
# +0x2bc (on-pitch flag) + the on-pitch formation slots +0x1f8/+0x204/+0x228/+0x230. Pure
# integer (mirror / compose / per-axis min-max sort), NO RNG / LUT / ftol. The leading
# FUN_005ed870 (the +0x38 replay-buffer housekeeping) and the trailing DAT_006d31c4 gate
# (slices B/C, or the replay copy) are OUT OF SCOPE here. Oracle-pinned bit-for-bit by
# tools/re/run_decideA_oracle.sh -> specs/decideA_oracle.txt, locked in test_decideA.gd.


## Signed-int32 min into corner[lo] / max into corner[hi] (the binary's `if (b < a)` clamps).
static func _bbox_fold(p: Dictionary, lo: int, hi: int, v: int) -> void:
	if v < int(p[lo]):
		p[lo] = v
	if int(p[hi]) < v:
		p[hi] = v


## FUN_005a3400 slice A. Mutates the player `p` in place (m = the player's +0x18c match).
static func decide_slice_a(p: Dictionary, m: Dictionary) -> void:
	var orient := _g(m, 0x19a0)
	var team := _g(p, 0x2b8)
	var x1820 := _g(m, 0x1820)
	var gx := goal_target_x(orient, x1820, team)
	p[0x3a4] = gx

	var src: Array                                          # the 6-int target-box source
	if _g(p, 0x2bc) == 0:
		# OFF-PITCH: both endpoints sit on the goal line; the box is an explicit default.
		p[0x1e0] = gx; p[0x1e4] = 0; p[0x1e8] = 0
		p[0x1ec] = gx; p[0x1f0] = 0; p[0x1f4] = 0
		var u9 := (orient & 1) ^ team
		var s3 := Pm98Trig._i32(0x108000 - x1820)
		var s0 := Pm98Trig._i32(-x1820)
		if u9 != 0:
			s3 = Pm98Trig._i32(-s3)
			s0 = x1820
		if s3 < s0:                                         # ensure s0 = min, s3 = max
			var t := s0; s0 = s3; s3 = t
		src = [s0, Pm98Trig._i32(0xffebd70b), 0, s3, 0x1428f5, 0]
	else:
		# ON-PITCH: endpoints + box from the player's formation slots, mirrored to its side.
		var v1: Array = mirror_to_side(orient, team, [_g(p, 0x1f8), _g(p, 0x1fc), _g(p, 0x200)])
		p[0x1e0] = v1[0]; p[0x1e4] = v1[1]; p[0x1e8] = v1[2]
		var v2: Array = mirror_to_side(orient, team, [_g(p, 0x204), _g(p, 0x208), _g(p, 0x20c)])
		p[0x1ec] = v2[0]; p[0x1f0] = v2[1]; p[0x1f4] = v2[2]
		var ma: Array = mirror_to_side(orient, team, vec_compose([_g(p, 0x228), _g(p, 0x22c)], 0))
		var mb: Array = mirror_to_side(orient, team, [_g(p, 0x230), _g(p, 0x234), 0])
		src = [ma[0], ma[1], ma[2], mb[0], mb[1], mb[2]]
		for axis in 3:                                      # FUN_005b12c0: per-axis min->lo, max->hi
			if src[axis + 3] < src[axis]:
				var t: int = src[axis]; src[axis] = src[axis + 3]; src[axis + 3] = t

	# Copy the 6-int source into the bbox, reseed z, then fold both endpoints in.
	for i in 6:
		p[0x210 + i * 4] = int(src[i])
	p[0x218] = Pm98Trig._i32(0xffff0000)
	p[0x224] = 0x12c0000
	_bbox_fold(p, 0x210, 0x21c, _g(p, 0x1e0))
	_bbox_fold(p, 0x214, 0x220, _g(p, 0x1e4))
	_bbox_fold(p, 0x218, 0x224, _g(p, 0x1e8))
	_bbox_fold(p, 0x210, 0x21c, _g(p, 0x1ec))
	_bbox_fold(p, 0x214, 0x220, _g(p, 0x1f0))
	_bbox_fold(p, 0x218, 0x224, _g(p, 0x1f4))


# ---- FUN_005a3400 the per-player DECIDE, slice B (field reset + facing + position) ----
# The DAT_006d31c4==0 real-compute head (decomp lines 147-177 / disasm 0x5a374d..0x5a37f8):
# clear the per-tick movement scratch, set the s16 facing (180deg=0x8000 when defending the
# OPPOSITE side), look up the formation-position value +0xb0 from the team struct's +0x13c
# table (indexed by the squad slot player+0x2cc), then stamp the position code via
# set_position_code. The leading FUN_005bbf10(player+0x3b0,0) (queue-grow) is a no-op (Array
# self-grows). NO RNG/LUT/ftol (set_position_code reads only the static POS_REMAP_LUT).
#
# DISASM-VERIFIED CORRECTIONS vs the 2026-06-18 slice-B note:
#   * the zeroed velocity-scratch is +0x20/+0x24/+0x28 ONLY -- NOT "+0x20..+0x30". +0x2c/+0x30
#     are untouched here (and set_position_code's remap-clear never fires: pos_code is 0 or
#     0x1e, and POS_REMAP_LUT[0]==0 / POS_REMAP_LUT[0x1e]==0x1e both map to self -> no clear).
#   * +0x61 is only SET to 1 when the table value is nonzero; the binary `je`-skips otherwise,
#     so the port leaves +0x61 UNTOUCHED on a zero/absent entry (it is never cleared here).
#
# STRUCT MODEL: player+0x188 -> _ref(p, 0x188) = the player's team/formation struct; the
# position table is its int32 array at +0x13c, indexed by player+0x2cc. A negative +0x2cc
# yields 0 (no entry). player+0x18c -> the match (== the m arg). Facing (a WORD write at +0x34
# / +0x64) is stored as the raw 16-bit pattern 0x8000/0; downstream readers apply _s16.
# Oracle-pinned bit-for-bit by tools/re/run_decideB_oracle.sh -> specs/decideB_oracle.txt,
# locked in test_decideB.gd.


## FUN_005a3400 slice B. Mutates the player `p` in place (m = the player's +0x18c match).
static func decide_slice_b(p: Dictionary, m: Dictionary) -> void:
	p[0x3b4] = 0
	p[0x48] = 0
	p[0x90] = 0
	p[0x54] = 0
	p[0x58] = 0
	# facing: 0x8000 (180deg) when (orient&1) != team, else 0; written to +0x34 and +0x64 (s16).
	var facing := 0x8000 if ((_g(m, 0x19a0) & 1) ^ _g(p, 0x2b8)) != 0 else 0
	p[0x34] = facing
	p[0x64] = facing
	# +0xb0 = team_struct(+0x188)[+0x13c + idx*4], or 0 when the slot idx (+0x2cc) < 0.
	var idx := Pm98Trig._i32(_g(p, 0x2cc))
	var val := _g(_ref(p, 0x188), 0x13c + idx * 4) if idx >= 0 else 0
	p[0xb0] = val
	if val != 0:                                            # binary: je-skip -> +0x61 NOT cleared
		p[0x61] = 1
	p[0x68] = 0
	p[0x6c] = 0
	p[0x20] = 0
	p[0x24] = 0
	p[0x28] = 0
	p[0x4] = 0
	p[0x8] = 0
	p[0xc] = 0
	# set_position_code(0x1e if off-pitch else 0). Neither code remaps -> +0x2c/+0x30 unchanged.
	set_position_code(p, 0x1e if _g(p, 0x2bc) == 0 else 0)


# ---- FUN_005a3400 the per-player DECIDE, slice C1 (set-piece switch, NON-TAKER paths) ----
# The DAT_006d31c4==0 tail: a switch on the set-piece phase match+0x448 (disasm 0x5a37f8..
# 0x5a44c4). For EACH non-default case the player either IS the set-piece taker
# (player == match+0x438) or is not; this C1 slice ports the NON-TAKER move-target writes of
# cases 3 / 6 / 7 plus the shared atan-facing tail and the default (no-op) exit.
#
# Per the switch `cmp eax,7 ; ja 0x5a44ba`: match+0x448 outside 2..7 jumps straight to the
# clean RET *after* the facing tail (0x5a44ba), so DEFAULT leaves the move target and the
# slice-B facing UNTOUCHED. Cases 3/6/7 non-taker pick a move target from the two slice-A
# endpoint vectors (endpoint1 = +0x1e0/+0x1e4/+0x1e8, endpoint2 = +0x1ec/+0x1f0/+0x1f4):
#   * case 3 (5a3b0f): same team as taker -> endpoint2 ; different team -> endpoint1.
#   * case 6 (5a41cc): same team -> the per-axis midpoint of the two endpoints, each
#     (endpoint2 + endpoint1) halved truncating toward zero ; different team -> endpoint1.
#   * case 7 (5a43ea): same team -> endpoint2 ; off-pitch (+0x2bc==0) -> set_position_code(0x20),
#     endpoint1, then move[0] += (ball.x(+0x90) >= 0 ? -0x5999 : +0x5999) ; else endpoint1.
# Every non-taker case then recomputes facing in the common tail (0x5a4494/0x5a449e):
# facing = atan( (ball+0x4 vec) - (player move target) ), an s16 WORD write to +0x34 / +0x64
# (stored as the raw 16-bit pattern, like slice B). The ball is player+0x190.
#
# NOT yet ported (explicit guards): the TAKER branches of every case (player == match+0x438:
# set_engagement + stamina + aim, with RNG in case 6) and cases 2 / 4 / 5 (the bbox-blend and
# the .data set-piece position tables). Oracle-pinned bit-for-bit by
# tools/re/run_decideC_oracle.sh -> specs/decideC_oracle.txt, locked in test_decideC.gd.


## Copy one of the slice-A endpoint vectors into the move target (+0x4/+0x8/+0xc).
static func _slice_c_set_move(p: Dictionary, ep: int) -> void:
	p[0x4] = _g(p, ep)
	p[0x8] = _g(p, ep + 4)
	p[0xc] = _g(p, ep + 8)


## Common facing tail: facing = atan((ball+0x4 vec) - move target), raw-s16 to +0x34 / +0x64.
static func _slice_c_tail(p: Dictionary) -> void:
	var ball: Dictionary = _ref(p, 0x190)
	var r: Array = Pm98Trig.vec3_sub(
		[_g(ball, 0x4), _g(ball, 0x8), _g(ball, 0xc)], [_g(p, 0x4), _g(p, 0x8), _g(p, 0xc)])
	var facing := Pm98Trig.atan_angle(r[0], r[1]) & 0xffff
	p[0x34] = facing
	p[0x64] = facing


# ---- FUN_005a3400 slice C2 (set-piece switch, the TAKER paths) -----------------------
# The branch each case takes when the player IS the set-piece taker (player == match+0x438).
# Decoded from the disasm; for the player's OWN reported fields (move +0x4/+0x8/+0xc, facing
# +0x34/+0x64, position +0x40, stamina +0x48, the +0x2c/+0x30 remap-clear) every taker shares:
#   1. ball.engage(player) -- FUN_0058eca0(this=ball(player+0x190), target=player). Its only
#      player-field effect is player+0x54/+0x58 = 0 (already zeroed by slice B); the rest mutate
#      the ball / match engagement state (validated separately in test_decideset.gd).
#   2. stamina +0x48 = (flag ? 0x2d0 : 0) + 0xb4, flag = teaminfo(+0x184)+0x2ee != 0 AND
#      phase0(match) AND player+0x5c != 0.
#   3. set_position_code(code): 0 (case 2) / 0x13 (case 3) / 0x1d (cases 4/5/6/7).
# then a per-case facing + move from the ball position (ball+0x90 vec) and the goal-line aim x:
#   * cases 2 / 4 / 5 / 7: aim = [aim_x, 0, 0] with aim_x = -+match+0x1820 when (orient&1)==(1-team);
#     ang = atan(aim - ball_pos) ; move = ball_pos - polar_vec(0x6666, ang). Case 2 keeps facing
#     = ang and early-returns; cases 4/5/7 recompute facing = atan(aim - move) in the common tail.
#   * case 3: facing (+0x34 ONLY, +0x64 untouched) = (ball+0x94 < 1) ? 0x4000 : -0x4000 ;
#     move = ball_pos - polar_vec(0x6666, facing).
#   * case 6: facing (+0x34 & +0x64) = ((orient&1)^team != 0) ? 0x8000 : 0 ; move = ball_pos.
# NOT modelled (non-player global side-effects, verified player-field-inert): the case 4/5/6/7
# `.data` set-piece globals (0x665154/.../0x67455c), case 6's RNG save/restore bracket
# (5ec240/5ec230, net RNG-neutral) and its gated SFX FUN_004e9630 (skipped when match+0x180b==0).
# Oracle-pinned by tools/re/run_decideCtaker_oracle.sh -> specs/decideCtaker_oracle.txt
# (test_decideCtaker.gd). Leaves polar_vec/atan_angle/vec3_sub/set_position_code/set_engagement
# are all already oracle-pinned.


## Taker aim: face the goal line and pull back 0x6666 toward it (cases 2 / 4 / 5 / 7). `double`
## recomputes facing from the moved spot (the common-tail second atan); else facing = the first.
static func _slice_c_taker_aim(p: Dictionary, ball: Dictionary, orient: int, team: int, x1820: int,
		bpos: Array, double: bool) -> void:
	var aim_x := Pm98Trig._i32(-x1820) if (orient & 1) == (1 - team) else Pm98Trig._i32(x1820)
	var aim := [aim_x, 0, 0]
	var ang1 := Pm98Trig.atan_angle(Pm98Trig._i32(aim_x - bpos[0]), Pm98Trig._i32(-bpos[1]))
	var polar: Array = Pm98Trig.polar_vec(0x6666, ang1)
	var move := [Pm98Trig._i32(bpos[0] - polar[0]), Pm98Trig._i32(bpos[1] - polar[1]),
		Pm98Trig._i32(bpos[2] - polar[2])]
	p[0x4] = move[0]
	p[0x8] = move[1]
	p[0xc] = move[2]
	var face := ang1
	if double:
		var r2: Array = Pm98Trig.vec3_sub(aim, move)
		face = Pm98Trig.atan_angle(r2[0], r2[1])
	p[0x34] = face & 0xffff
	p[0x64] = face & 0xffff


## The set-piece taker (player == match+0x438) branch of cases 2/3/4/5/6/7.
static func _decide_slice_c_taker(p: Dictionary, m: Dictionary, phase: int) -> void:
	var ball: Dictionary = _ref(p, 0x190)
	var orient := _g(m, 0x19a0)
	var team := _g(p, 0x2b8)
	var x1820 := _g(m, 0x1820)
	var bpos := [_g(ball, 0x90), _g(ball, 0x94), _g(ball, 0x98)]
	set_engagement(ball, 0, [p])                              # ball.engage(player); player+0x54/+0x58=0
	var flag := _g(_ref(p, 0x184), 0x2ee) != 0 and _phase0(m) and _g(p, 0x5c) != 0
	p[0x48] = (0x2d0 if flag else 0) + 0xb4
	match phase:
		2:
			set_position_code(p, 0)
			_slice_c_taker_aim(p, ball, orient, team, x1820, bpos, false)
		3:
			set_position_code(p, 0x13)
			var fc := 0x4000 if _g(ball, 0x94) < 1 else -0x4000
			p[0x34] = fc & 0xffff                             # +0x64 deliberately NOT written
			var polar: Array = Pm98Trig.polar_vec(0x6666, fc)
			p[0x4] = Pm98Trig._i32(bpos[0] - polar[0])
			p[0x8] = Pm98Trig._i32(bpos[1] - polar[1])
			p[0xc] = Pm98Trig._i32(bpos[2] - polar[2])
		6:
			set_position_code(p, 0x1d)
			var fc6 := 0x8000 if ((orient & 1) ^ team) != 0 else 0
			p[0x34] = fc6
			p[0x64] = fc6
			p[0x4] = bpos[0]
			p[0x8] = bpos[1]
			p[0xc] = bpos[2]
		_:                                                   # cases 4 / 5 / 7 (identical taker body)
			set_position_code(p, 0x1d)
			_slice_c_taker_aim(p, ball, orient, team, x1820, bpos, true)


# ---- FUN_005a3400 slice C3 (set-piece switch, NON-TAKER cases 2 / 4 / 5) -------------
# The three remaining non-taker switch branches (cases 3/6/7 = slice C1, all takers = C2).
# Decoded bit-for-bit from the disasm (the Ghidra decompile's comma-assignments are misleading
# in the case-2 clamp ladder). Oracle-pinned by tools/re/run_decideC3_oracle.sh ->
# specs/decideC3_oracle.txt, locked in test_decideC3.gd. All paths end in the shared atan
# facing tail (_slice_c_tail), exactly like C1's non-taker cases.


## Signed clamp of `v` into [lo, hi] -- the binary's `min(hi, max(lo, v))` jg/jge ladder at
## 0x5a399c..0x5a39fe (case 2). lo <= hi always here (lo = per-axis min, hi = per-axis max).
static func _clamp_i(v: int, lo: int, hi: int) -> int:
	var r := lo if lo > v else v                              # max(lo, v)
	return hi if hi < r else r                                # min(hi, .)


## FUN_005a3400 case 2 NON-TAKER (disasm 0x5a3953..0x5a3a2a): clamp endpoint1 per-axis into the
## box minmax(v, L), where v = [goal_target_x, -Yscale, -1.0], L = [0, +Yscale, +1000.0] in 16.16
## (Yscale = match+0x1824), then push the result a minimum 0x90000 off the ball (clamp_min_sep).
## The shared atan facing tail follows in the caller. Runs for ANY non-taker (no same-team split).
static func _slice_c_case2_nontaker(p: Dictionary, m: Dictionary) -> void:
	var orient := _g(m, 0x19a0)
	var team := _g(p, 0x2b8)
	var yscale := _g(m, 0x1824)
	var v := [goal_target_x(orient, _g(m, 0x1820), team), Pm98Trig._i32(-yscale), Pm98Trig._i32(0xffff0000)]
	var lvec := [0, yscale, 0x3e80000]                        # [0, Yscale, 1000.0]
	var ep1 := [_g(p, 0x1e0), _g(p, 0x1e4), _g(p, 0x1e8)]
	var mv := []
	for axis in 3:
		mv.append(_clamp_i(int(ep1[axis]), int(min(v[axis], lvec[axis])), int(max(v[axis], lvec[axis]))))
	var ball: Dictionary = _ref(p, 0x190)
	var res: Array = Pm98Trig.clamp_min_sep(mv, [_g(ball, 0x90), _g(ball, 0x94), _g(ball, 0x98)], 0x90000)
	p[0x4] = res[0]
	p[0x8] = res[1]
	p[0xc] = res[2]


## The set-piece position table &DAT_00674330 (19 entries x 3 int32, 16.16), written inline by
## the cases-4/5 one-time init at 0x5a3d57..0x5a3ed6 (gated by DAT_006742ec & 1) and indexed by
## the squad position code player+0x2c8 (0..18). Stored as raw u32; read via Pm98Trig._i32.
## (FUN_00605ff0(&DAT_005a4550) in the init is a separate global side-effect that NEVER writes
## this table -- it calls FUN_00605fc0 and returns a bool.)
const SETPIECE_POS_TABLE := [
	[0x0, 0x0, 0x0], [0x0, 0x0, 0x0], [0x0, 0x0, 0x0], [0x0, 0x0, 0x0], [0x0, 0x0, 0x0],
	[0xb0000, 0x0, 0x0], [0xb0000, 0x0, 0x0],
	[0x20000, 0xfff6d70b, 0x0], [0xc0000, 0xfff78000, 0x0], [0x70000, 0x30000, 0x0],
	[0x128000, 0x0, 0x0], [0x90000, 0xfff50000, 0x0], [0xa0000, 0xb0000, 0x0],
	[0x80000, 0x20000, 0x0], [0x68000, 0xb0000, 0x0], [0x0, 0x0, 0x0],
	[0x80000, 0xfffb0000, 0x0], [0x80000, 0x60000, 0x0], [0xb0000, 0x58000, 0x0],
]


## FUN_005a3400 cases 4/5 NON-TAKER (disasm 0x5a3d12..0x5a40ad). Three sub-branches:
##  * SAME team as taker: move = endpoint2, then a conditional override from
##    SETPIECE_POS_TABLE[+0x2c8] -- move = [+/-(match+0x1820 - entry.x), +/-entry.y, entry.z]
##    where the x sign mirrors by side and the y is negated when ball.y(+0x94) > 0. The override
##    is SKIPPED when (phase==5 && match+0x19cc==0), or the table entry is all-zero, or the pos
##    is 5/6 with player+0x2d6==0. On-pitch -> clamp_min_sep(ball, 0xa8000).
##  * DIFFERENT team, off-pitch: set_position_code(0x20); move = endpoint1; move.x += the
##    mirror-signed +/-0x4ccc wing offset; move.y += +/-0x20000 by ball.y(+0x94) sign (>=0 -> -).
##  * DIFFERENT team, on-pitch: move = endpoint1, then clamp_min_sep(ball, 0xa8000).
static func _slice_c_case45_nontaker(p: Dictionary, m: Dictionary, same_team: bool) -> void:
	var orient := _g(m, 0x19a0)
	var team := _g(p, 0x2b8)
	var ball: Dictionary = _ref(p, 0x190)
	if same_team:
		var pos := _g(p, 0x2c8)
		var entry: Array = SETPIECE_POS_TABLE[pos]
		var ex := Pm98Trig._i32(int(entry[0]))
		var ey := Pm98Trig._i32(int(entry[1]))
		var ez := Pm98Trig._i32(int(entry[2]))
		_slice_c_set_move(p, 0x1ec)                           # initial move = endpoint2
		var gate1 := not (_g(m, 0x448) == 5 and _g(m, 0x19cc) == 0)
		var nonzero := ex != 0 or ey != 0 or ez != 0
		var gate3 := (pos != 5 and pos != 6) or _g(p, 0x2d6) != 0
		if gate1 and nonzero and gate3:                       # override from the position table
			var mx := Pm98Trig._i32(_g(m, 0x1820) - ex)
			if ((orient & 1) ^ team) != 0:
				mx = Pm98Trig._i32(-mx)
			var my := Pm98Trig._i32(-ey) if _g(ball, 0x94) > 0 else ey
			p[0x4] = mx
			p[0x8] = my
			p[0xc] = ez
		if _g(p, 0x2bc) != 0:                                 # on-pitch -> minimum separation
			_slice_c_min_sep(p, ball, 0xa8000)
	elif _g(p, 0x2bc) == 0:                                   # different team, off-pitch
		set_position_code(p, 0x20)
		_slice_c_set_move(p, 0x1e0)                           # move = endpoint1
		var off_x := -0x4ccc if ((orient & 1) ^ team) != 0 else 0x4ccc
		p[0x4] = Pm98Trig._i32(_g(p, 0x4) + off_x)
		var off_y := -0x20000 if _g(ball, 0x94) >= 0 else 0x20000
		p[0x8] = Pm98Trig._i32(_g(p, 0x8) + off_y)
	else:                                                     # different team, on-pitch
		_slice_c_set_move(p, 0x1e0)                           # move = endpoint1
		_slice_c_min_sep(p, ball, 0xa8000)


## clamp_min_sep on the move target in place: push it `box` off the ball position (ball+0x90).
static func _slice_c_min_sep(p: Dictionary, ball: Dictionary, box: int) -> void:
	var res: Array = Pm98Trig.clamp_min_sep(
		[_g(p, 0x4), _g(p, 0x8), _g(p, 0xc)], [_g(ball, 0x90), _g(ball, 0x94), _g(ball, 0x98)], box)
	p[0x4] = res[0]
	p[0x8] = res[1]
	p[0xc] = res[2]


## FUN_005a3400 slice C (C1 + C2 + C3). Mutates the player `p` in place (m = +0x18c match).
static func decide_slice_c(p: Dictionary, m: Dictionary) -> void:
	var phase := _g(m, 0x448)
	if phase < 2 or phase > 7:                                # switch default: clean RET, no rewrite
		return
	var taker: Dictionary = _ref(m, 0x438)
	if is_same(p, taker):
		_decide_slice_c_taker(p, m, phase)
		return
	# NON-TAKER cases 2..7: each computes a move target, then shares the atan facing tail.
	var same_team := _g(p, 0x2b8) == _g(taker, 0x2b8)
	match phase:
		2:
			_slice_c_case2_nontaker(p, m)
		3:
			_slice_c_set_move(p, 0x1ec if same_team else 0x1e0)
		4, 5:
			_slice_c_case45_nontaker(p, m, same_team)
		6:
			if same_team:                                    # per-axis midpoint, trunc toward zero
				p[0x4] = Pm98Trig._tdiv(Pm98Trig._i32(_g(p, 0x1ec) + _g(p, 0x1e0)), 2)
				p[0x8] = Pm98Trig._tdiv(Pm98Trig._i32(_g(p, 0x1f0) + _g(p, 0x1e4)), 2)
				p[0xc] = Pm98Trig._tdiv(Pm98Trig._i32(_g(p, 0x1f4) + _g(p, 0x1e8)), 2)
			else:
				_slice_c_set_move(p, 0x1e0)
		7:
			if same_team:
				_slice_c_set_move(p, 0x1ec)
			elif _g(p, 0x2bc) == 0:                          # off-pitch taker-side wing offset
				set_position_code(p, 0x20)
				_slice_c_set_move(p, 0x1e0)
				var off := -0x5999 if _g(_ref(p, 0x190), 0x90) >= 0 else 0x5999
				p[0x4] = Pm98Trig._i32(_g(p, 0x4) + off)
			else:
				_slice_c_set_move(p, 0x1e0)
	_slice_c_tail(p)


# ---- FUN_005a3400 ELSE-REPLAY branch (DAT_006d31c4 != 0) ------------------------------
# The non-real-compute path (disasm 0x5a368c..0x5a374c). When the global replay flag
# DAT_006d31c4 is set, the per-player DECIDE does NOT recompute a move target: it RESTORES the
# player's saved per-tick state and re-asserts the active-player marker.
#  1. Copy 0x51 (81) dwords from the saved buffer at *(player+0x3b0) into player+0x40..+0x180.
#  2. If the RESTORED +0x5c (active marker) is set: make this player the team's active player --
#     team(+0x184)+0x168 = player, clearing the previously-active player's +0x5c (unless it is
#     null or already this player) -- and, when this player is the set-piece taker (match+0x438),
#     stamp match+0x45c = player team.
#  3. (taker only) write the three set-piece globals 0x665154/0x66502c/0x67455c -- player-field-
#     inert (validated in slice C2), so not modelled.
# Slice A runs as the prefix (writes only +0x1e0..+0x224/+0x3a4, none of which the copy or the
# bookkeeping read), so this branch is self-contained. Oracle-pinned bit-for-bit by
# tools/re/run_decideReplay_oracle.sh -> specs/decideReplay_oracle.txt, locked in
# test_decideReplay.gd. STRUCT MODEL: player+0x3b0 -> the saved-state buffer (a ref); player+0x184
# -> the team struct, its +0x168 = the active player (a player ref, absent/null = none).
static func decide_slice_replay(p: Dictionary, m: Dictionary) -> void:
	var buf: Dictionary = _ref(p, 0x3b0)                      # *(player+0x3b0) = saved-state buffer
	for i in 0x51:                                            # 81-dword restore -> +0x40..+0x180
		p[0x40 + i * 4] = _g(buf, i * 4)
	if _g(p, 0x5c) != 0:                                      # restored active marker set
		var ts: Dictionary = _ref(p, 0x184)                   # team struct
		var old: Variant = ts.get(0x168, null)                # previously-active player (or null)
		if old != null and not is_same(old, p):
			(old as Dictionary)[0x5c] = 0                     # clear the prior active player's marker
		ts[0x168] = p                                         # this player becomes active
		if is_same(p, _ref(m, 0x438)):                        # this player is the set-piece taker
			m[0x45c] = _g(p, 0x2b8)                            # stamp the taker's team


# ---- FUN_005a4560 (vtable+0xc, the per-player ADVANCE pass) + leaf FUN_005ed8e0 -------
# The ADVANCE pass is PURE replay record/playback -- it does NO physics. The player's POSITION
# (+0x4/+0x8/+0xc) is written directly by the DECIDE pass (FUN_005a3400) every tick; there is no
# separate integration step (the match driver FUN_00598740 calls only decide(+8) + advance(+0xc)
# per player -- see docs/re/MATCH_TICK_DRIVER_MAP.md). The pass acts only on the frame-ring wrap
# (DAT_006d31bc == 0), and then only to PLAY BACK a recorded frame (DAT_006d31c4 set) or RECORD one
# (DAT_00665d8c set). A live match-outcome run (the headless engine) sets neither -> NO-OP.
#
# Two snapshots, both indexed by the replay frame DAT_006d31c0:
#   * MOTION (FUN_005ed8e0): 9 dwords at *(player+0x38), stride 0x24 -- [+0x4,+0x8,+0xc] position,
#     [+0x20,+0x24,+0x28] velocity, +0x2c, +0x30, and +0x34 facing (a WORD in the 9th dword, so the
#     high half of +0x34 is preserved). Record gathers via FUN_005ed820 (the exact inverse layout).
#   * DECIDE STATE (FUN_005a4560 body): 0x51 dwords at *(player+0x3b0), stride 0x144 -> +0x40..+0x180.
# Buffers modelled as offset-keyed Dicts (byte offsets into the whole multi-frame buffer, matching
# memory + the decide_slice_replay convention); the {count} for record lives at +0x3c (motion) /
# +0x3b4 (decide-state). Oracle-pinned (PLAYBACK + both NO-OP gates) by tools/re/run_advance_oracle.sh
# -> specs/advance_oracle.txt, locked in test_advance.gd. The RECORD path is the structural inverse
# (append the same snapshots) -- ported but exercised only structurally (the headless engine never
# records); a future replay-recording feature would validate it.

## FUN_005ed8e0: motion-state (+0x4../+0x34) record/playback. frame = DAT_006d31c0.
static func _advance_motion(p: Dictionary, ring: int, playback: bool, record: bool, frame: int) -> void:
	if ring != 0:                                             # acts only on the ring-wrap frame
		return
	if playback:
		var buf: Dictionary = _ref(p, 0x38)
		var s := frame * 0x24
		p[0x4] = _g(buf, s); p[0x8] = _g(buf, s + 4); p[0xc] = _g(buf, s + 8)
		p[0x20] = _g(buf, s + 0xc); p[0x24] = _g(buf, s + 0x10); p[0x28] = _g(buf, s + 0x14)
		p[0x2c] = _g(buf, s + 0x18); p[0x30] = _g(buf, s + 0x1c)
		p[0x34] = (_g(p, 0x34) & 0xffff0000) | (_g(buf, s + 0x20) & 0xffff)   # WORD write: high half kept
	elif record:
		var buf: Dictionary = _ref(p, 0x38)
		var n := _g(p, 0x3c)                                  # +0x3c = motion-buffer frame count
		var s := n * 0x24
		buf[s] = _g(p, 0x4); buf[s + 4] = _g(p, 0x8); buf[s + 8] = _g(p, 0xc)
		buf[s + 0xc] = _g(p, 0x20); buf[s + 0x10] = _g(p, 0x24); buf[s + 0x14] = _g(p, 0x28)
		buf[s + 0x18] = _g(p, 0x2c); buf[s + 0x1c] = _g(p, 0x30)
		buf[s + 0x20] = _g(p, 0x34) & 0xffff
		p[0x3c] = n + 1


## FUN_005a4560 (vtable+0xc): the per-player ADVANCE pass. ring = DAT_006d31bc (frame ring),
## frame = DAT_006d31c0 (replay frame index). NO-OP in a live match (no playback, no record).
static func advance(p: Dictionary, ring: int, playback: bool, record: bool, frame: int) -> void:
	_advance_motion(p, ring, playback, record, frame)         # FUN_005ed8e0 (rechecks ring itself)
	if ring != 0:
		return
	if playback:                                              # restore the 0x51-dword decide state
		var buf: Dictionary = _ref(p, 0x3b0)
		var s := frame * 0x144
		for i in 0x51:
			p[0x40 + i * 4] = _g(buf, s + i * 4)
	elif record:
		var buf: Dictionary = _ref(p, 0x3b0)
		var n := _g(p, 0x3b4)                                 # +0x3b4 = decide-state buffer frame count
		var s := n * 0x144
		for i in 0x51:
			buf[s + i * 4] = _g(p, 0x40 + i * 4)
		p[0x3b4] = n + 1


# ---- FUN_005b73a0 positioning leaves (forward-zone eligibility + goal-side count) -----
# Two pure integer predicates the off-ball positioning pass FUN_005b73a0 calls (FUN_005b04e0 x2 +
# FUN_005b0b40; the latter also serves the stamina pass FUN_005a4600). NO RNG/LUT/ftol. Oracle-
# pinned (EAX) by tools/re/run_posleaf_oracle.sh -> specs/posleaf_oracle.txt, in test_posleaf.gd.

## Signed-int32 field read.
static func _si(d: Dictionary, off: int) -> int:
	return Pm98Trig._i32(_g(d, off))


## The binary's sign bucket `((-1 < v) - 1 & 0xfffffffe) + 1`: +1 when v >= 0, -1 when v < 0.
static func _sign1(v: int) -> int:
	return 1 if v >= 0 else -1


## FUN_005b04e0 (__thiscall player; pos3): is `pos` a valid forward-positioning target -- inside the
## pitch box [match+0x1828..+0x1834] x [+0x182c..+0x1838] x [+0x1830..+0x183c], past the line
## abs(x) > match+0x1820 - 0x108000, within abs(y) < 0x1428f5, AND on the opposite side (sign of x)
## from the player's goal anchor +0x3a4.
static func pos_forward_ok(p: Dictionary, pos: Array) -> bool:
	var m: Dictionary = _ref(p, 0x18c)
	var x := Pm98Trig._i32(int(pos[0]))
	var y := Pm98Trig._i32(int(pos[1]))
	var z := Pm98Trig._i32(int(pos[2]))
	if x < _si(m, 0x1828) or x > _si(m, 0x1834) or y < _si(m, 0x182c) or y > _si(m, 0x1838) \
			or z < _si(m, 0x1830) or z > _si(m, 0x183c):
		return false
	if not (_si(m, 0x1820) - 0x108000 < abs(x) and abs(y) < 0x1428f5):
		return false
	return _sign1(x) != _sign1(_si(p, 0x3a4))


## FUN_005b0b40 (__thiscall player; thresh): count the opponents (the player+0x188 descriptor
## {base, count} -> the `opponents` array) whose abs(opp.x - opp.anchor) < thresh + abs(player.x +
## player.anchor); a null player/opponent contributes the sentinel 0xc80000. x = +0x4, anchor = +0x3a4.
## The (x +/- anchor) sums and the (thresh + base) comparand wrap to int32 (faithful to the binary's
## 32-bit add) before the signed compare.
static func count_goalside_opponents(p: Dictionary, opponents: Array, thresh: int) -> int:
	var base: int = 0xc80000 if p.is_empty() else abs(Pm98Trig._i32(_si(p, 0x4) + _si(p, 0x3a4)))
	var lim := Pm98Trig._i32(thresh + base)
	var n := 0
	for q in opponents:
		var qd: Dictionary = q
		var d: int = 0xc80000 if qd.is_empty() else abs(Pm98Trig._i32(_si(qd, 0x4) - _si(qd, 0x3a4)))
		if d < lim:
			n += 1
	return n


# ---- Match-driver leaves (FUN_00598740): within-box test + phase setter + vec copy ----
# Small leaves the per-tick match driver FUN_00598740 calls. Oracle-pinned (FUN_005a1820 EAX +
# FUN_005942e0 state) by tools/re/run_driverleaf_oracle.sh -> specs/driverleaf_oracle.txt, locked
# in test_driverleaf.gd.

## FUN_005a1820 (__thiscall p1; p2, lx, ly, lz): 1 iff p1 is within the per-axis L-inf box of
## half-extents (lx, ly, lz) around p2 (STRICT <). The driver uses it for goalkeeper-distribution
## region tests. Each per-axis difference wraps to int32 before abs (faithful to the 32-bit sub).
static func within_box(p1: Array, p2: Array, lx: int, ly: int, lz: int) -> bool:
	return abs(Pm98Trig._i32(int(p1[0]) - int(p2[0]))) < lx \
		and abs(Pm98Trig._i32(int(p1[1]) - int(p2[1]))) < ly \
		and abs(Pm98Trig._i32(int(p1[2]) - int(p2[2]))) < lz


## FUN_005942e0 (__thiscall match; phase): set the match phase match+0x448 = phase (UNLESS it is
## already 8 = locked/match-over), and mirror it to the secondary phase +0x44c unless phase == 1.
static func set_phase(m: Dictionary, phase: int) -> void:
	if _g(m, 0x448) == 8:
		return
	m[0x448] = phase
	if phase != 1:
		m[0x44c] = phase


## FUN_00590ac0 (__thiscall dst; src): copy a 3-vec src -> dst. Returns the copied vec.
static func vec3_copy(src: Array) -> Array:
	return [int(src[0]), int(src[1]), int(src[2])]


## FUN_0058f0b0 (__thiscall player; side): 1 iff sign(player.x) != sign(goalx), where goalx =
## -(match+0x1820) when (match+0x19a0 & 1) == side else +(match+0x1820) -- i.e. the player stands
## on the opposite half from `side`'s goal. match = player+0x1d4; sign bucket = +1 if >=0 else -1.
## (The driver FUN_00598740 calls it per team in the goal-area resolution branch.)
static func player_opposite_half(p: Dictionary, side: int) -> bool:
	var m: Dictionary = _ref(p, 0x1d4)
	var goalx := _si(m, 0x1820)
	if ((_g(m, 0x19a0) & 1) ^ side) == 0:
		goalx = Pm98Trig._i32(-goalx)
	return _sign1(_si(p, 0x4)) != _sign1(goalx)


# ---- FUN_005b73a0 the per-team off-ball POSITIONING pass (slice A: prologue + open play) ----
# Called per team each tick by the driver FUN_00598740 (replay gate DAT_006d31c4 is the caller's;
# this is the real-compute body). Runs the relationship matrix, resets the matrix throttle counter
# (param_1[0xb8] = ctx+0x2e0 = -1), then dispatches on the set-piece phase (match+0x448). For OPEN
# PLAY (phase 0) -- and any non-set-piece phase 1/2/6 -- it does NOTHING further: the off-ball
# positioning fires ONLY on set-pieces (phases 3/4/5/7). So ~95% of match ticks reduce to
# relationship-matrix + throttle reset. ctx model = the relationship-matrix ctx: ctx["players"]
# (our team), ctx[0x8] team, ctx[0x138] match, ctx[0x2e0] throttle. Oracle-pinned (the open-play
# path) by tools/re/run_positionteam_oracle.sh -> specs/positionteam_oracle.txt, in
# test_positionteam.gd.
#
# PORTED: phase 4 / (5 & match+0x19cc) defensive-WALL (loops 1-5); phase 7 scatter (match+0x19a0==4);
# phase 3 kickoff/restart; phase-5 tail Path C. STILL STUBBED (push_error): phase-7 wall-else
# (match+0x19a0 != 4) and phase-5 tail Path A (0x19cc != 0 && 0x45c != team, the insertion-sort).
static func position_team(ctx: Dictionary, rng = null) -> void:
	build_relationship_matrix(ctx)                            # FUN_005b8690 (throttled; DONE)
	ctx[0x2e0] = -1                                           # param_1[0xb8] = -1 (reset the throttle)
	var m: Dictionary = ctx.get(0x138, {})
	var phase := _g(m, 0x448)
	var team := _g(ctx, 0x8)
	if (phase == 4 or (phase == 5 and _g(m, 0x19cc) != 0)) and _g(m, 0x45c) != team:
		_position_wall(ctx, m, team, rng)
	elif phase == 7:
		_position_phase7(ctx, m, team, rng)
	elif phase == 3:
		_position_phase3(ctx, m, team, rng)
	# TAIL (0x5b81d6): only phase 5 continues to the follow-up positioning.
	if _g(m, 0x448) == 5:
		_position_phase5_tail(ctx, m, team)


## FUN_005b73a0 phase-3 (kickoff/restart) set-piece branch (disasm 0x5b7fec..0x5b81cf).
## OUR team (match+0x45c == team): pull the nearest on-pitch teammate (min |x - taker.x|, != taker)
## partway toward the taker -- x and y each jittered by a fresh RNG factor `(rand*50)>>15` taken as a
## /100 fraction of the gap (y additionally + sign(y-gap)*0x70000), z unchanged -- then aim the
## TAKER's facing (+0x34/+0x64) at the moved teammate. ELSE (opponent's set-piece): clamp the role
## player ctx[0x200]'s x to the taker's side of goal (min if attacking -x else max), z = 0.
## `rng` = the live MatchEngine.Pm98Rng. The /100 uses truncate-toward-zero (the 0x51eb851f magic).
static func _position_phase3(ctx: Dictionary, m: Dictionary, team: int, rng) -> void:
	var taker: Dictionary = _ref(m, 0x438)
	var players: Array = ctx.get("players", [])
	if _g(m, 0x45c) == team:
		var tx := _si(taker, 0x4)
		var nearest := -1
		var best := 0x640000
		for i in players.size():
			var p: Dictionary = players[i]
			if _g(p, 0x2bc) == 0 or is_same(p, taker):
				continue
			var d: int = abs(Pm98Trig._i32(_si(p, 0x4) - tx))
			if d < best:
				best = d
				nearest = i
		if nearest < 0:
			return
		var np: Dictionary = players[nearest]
		var f1: int = (rng.next() * 0x32) >> 15
		var ndx := Pm98Trig._i32(_si(np, 0x4) - _si(taker, 0x4))
		np[0x4] = Pm98Trig._i32(Pm98Trig._tdiv(Pm98Trig._i32(f1 * ndx), 100) + _si(taker, 0x4))
		var dy := Pm98Trig._i32(_si(np, 0x8) - _si(taker, 0x8))
		var f2: int = (rng.next() * 0x32) >> 15
		np[0x8] = Pm98Trig._i32(Pm98Trig._tdiv(Pm98Trig._i32(f2 * dy), 100) + _sign1(dy) * 0x70000 + _si(taker, 0x8))
		var r: Array = Pm98Trig.vec3_sub(
			[_si(np, 0x4), _si(np, 0x8), _si(np, 0xc)], [_si(taker, 0x4), _si(taker, 0x8), _si(taker, 0xc)])
		var facing := Pm98Trig.atan_angle(r[0], r[1]) & 0xffff
		taker[0x34] = facing
		taker[0x64] = facing
	else:
		var goalx := goal_target_x(_g(m, 0x19a0), _g(m, 0x1820), team)
		var role: Dictionary = players[_g(ctx, 0x200)]
		var rx := _si(role, 0x4)
		var txx := _si(taker, 0x4)
		if goalx < 0:
			role[0x4] = rx if rx < txx else txx               # min: keep role on the -x side of the taker
		else:
			role[0x4] = rx if rx > txx else txx               # max: keep role on the +x side
		role[0x8] = 0


## FUN_005b73a0 phase-7 branch (disasm 0x5b7c6d..0x5b7fe5). When match+0x19a0 == 4 (the
## penalty/extra-time scatter mode): every eligible player -- not the taker, AND on-pitch OR
## (off-pitch but on our set-piece side, team == match+0x45c) -- is scattered to a fresh random
## polar position: angle = (rand1 * 0x10000) >> 15, radius = (rand2 * 0xa00) >> 7, then
## pos (+0x4/+0x8/+0xc) = endpoint1 (+0x1e0) = endpoint2 (+0x1ec) = polar_vec(radius, angle).
## Two FUN_005ec250 draws per processed player, angle-then-radius. The other (match+0x19a0 != 4)
## wall path shares machinery with phase 4/5 and is NOT YET PORTED (push_error stub).
static func _position_phase7(ctx: Dictionary, m: Dictionary, team: int, rng) -> void:
	if _g(m, 0x19a0) != 4:
		push_error("position_team: phase 7 wall (match+0x19a0 != 4) not yet ported")
		return
	var taker: Dictionary = _ref(m, 0x438)
	var our_side := _g(m, 0x45c)
	var players: Array = ctx.get("players", [])
	for i in players.size():
		var p: Dictionary = players[i]
		if is_same(p, taker):
			continue
		if _g(p, 0x2bc) == 0 and our_side != team:            # off-pitch and not our set-piece side
			continue
		var a: int = (rng.next() * 0x10000) >> 15
		var r: int = (rng.next() * 0xa00) >> 7
		var polar: Array = Pm98Trig.polar_vec(r, a)
		p[0x4] = polar[0]; p[0x8] = polar[1]; p[0xc] = polar[2]
		p[0x1e0] = polar[0]; p[0x1e4] = polar[1]; p[0x1e8] = polar[2]
		p[0x1ec] = polar[0]; p[0x1f0] = polar[1]; p[0x1f4] = polar[2]


## FUN_005b73a0 phase-4 / phase-5(&match+0x19cc) DEFENSIVE-WALL arrangement (disasm 0x5b73a0..0x5b7c6c,
## entered when match+0x45c != team). The big two-team marking pass. Five sequential loops over OUR
## players (ctx["players"], stride 0x3bc) assigning each to mark an OPPONENT (ctx["opponents"]); both
## sides carry a per-player "claimed/assigned" bitmap keyed by player+0x2c4 (an id 0..N). Phase 4 RETs
## after loop 5 (the phase-5 tail at LAB_005b81d6 is a SEPARATE, not-yet-ported slice).
##
## PORTED THIS SLICE (oracle-pinned by tools/re/run_wall_oracle.sh -> specs/wall_oracle.txt):
##   * the bitmap seeds: opp-claimed[0]=1 + opp-claimed[keeper.+0x2c4]=1 (keeper = *(match-team*800+
##     0x8f4)); our-assigned[0]=1 (the goalkeeper id 0 is never repositioned);
##   * LOOP 1 (0x5b74e1..0x5b763d + trampoline 0x5b860c): role-based direct pulling --
##       - our role 5/6 -> pull the first UNCLAIMED opponent of role 9 (forward): copy its xyz, x-=iVar21;
##       - our role 10  -> same against opponent role 10;
##       - our role 2/3 (first one only, gated on sign(P.+0x1e4)==sign(match+0x16a4)): the WALL ANCHOR --
##         x = +/-(0x8000 - match+0x1820) (neg iff P.team+0x2b8 != (P.match.+0x19a0 & 1)),
##         y = sign(match+0x16a4)*0x40000, z = 0.
##     iVar21 = (((match+0x19a0 & 1) ^ team) ? -0x10000 : +0x10000). No break: every matching opponent
##     re-claims (faithful -- realistically one per role). Each pull/anchor marks our-assigned[P id].
##   * LOOPS 2-4 (0x5b763e..0x5b7ba0): assign players LEFT unassigned by loop 1 --
##       - LOOP 2: by the pre-set mark-target pointer (player+0xb0), snap on, x -= iVar21;
##       - LOOP 3: nearest unclaimed valid-forward opponent within 1000.0 (role-gated), snap, x -= iVar21;
##       - LOOP 4: nearest within 100.0; on a hit snap + x += (flag ? +0x10000 : -0x10000); on a MISS,
##         excluded roles -> endpoint1 (player+0x1e0), else goal_target_x + 2-draw RNG jitter.
##     The [esp+0x18] x-offset is iVar21; [esp+0x14] is the opponents {base,count} (= ctx["opponents"]).
##   * LOOP 5 (0x5b7ba0..0x5b7c66): each player's facing (+0x34/+0x64) = atan(ball - player); then for
##     every on-pitch pair i<j, FUN_005ee3f0 (mid_offset) min-separation with offset [iVar21,0,0].
static func _position_wall(ctx: Dictionary, m: Dictionary, team: int, rng = null) -> void:
	var players: Array = ctx.get("players", [])
	var opps: Array = ctx.get("opponents", [])
	var ivar21 := -0x10000 if ((_g(m, 0x19a0) & 1) ^ team) != 0 else 0x10000

	# bitmaps keyed by player+0x2c4 id. opp-claimed[0]=1 (literal) + keeper; our-assigned[0]=1 (GK).
	var opp_claimed := {0: true}
	var keeper_i := int(ctx.get("opp_keeper", 0))
	if keeper_i >= 0 and keeper_i < opps.size():
		opp_claimed[_g(opps[keeper_i], 0x2c4)] = true
	var our_assigned := {0: true}
	var wall_placed := false

	# ---- LOOP 1: role-based direct pulling / wall anchor ----
	for i in players.size():
		var p: Dictionary = players[i]
		var role := _g(p, 0x2c8)
		var pid := _g(p, 0x2c4)
		if role == 5 or role == 6:
			_wall_pull(p, pid, opps, opp_claimed, our_assigned, 9, ivar21)
		elif role == 10:
			_wall_pull(p, pid, opps, opp_claimed, our_assigned, 10, ivar21)
		elif not wall_placed and (role == 2 or role == 3):
			if _sign1(_si(p, 0x1e4)) == _sign1(_si(m, 0x16a4)):
				var pm: Dictionary = _ref(p, 0x18c)
				var ivar12 := Pm98Trig._i32(0x8000 - _si(m, 0x1820))
				if _g(p, 0x2b8) != (_g(pm, 0x19a0) & 1):
					ivar12 = Pm98Trig._i32(-ivar12)
				p[0x4] = ivar12
				p[0x8] = _sign1(_si(m, 0x16a4)) * 0x40000
				p[0xc] = 0
				our_assigned[pid] = true
				wall_placed = true

	# ---- LOOP 2 (0x5b763e): assign by the pre-set mark-target pointer (player+0xb0) ----
	# Each player carries a mark-target opponent ref at +0xb0 (set by the marker pass FUN_005b94f0).
	# If on-pitch, still-unassigned, the target unclaimed, and the target a valid forward position,
	# snap onto the target (x shifted goal-side by -iVar21) and claim both.
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0 or bool(our_assigned.get(_g(p, 0x2c4), false)):
			continue
		var mt: Dictionary = _ref(p, 0xb0)                # mark-target opponent (player+0xb0)
		if mt.is_empty() or bool(opp_claimed.get(_g(mt, 0x2c4), false)):
			continue
		if not pos_forward_ok(mt, [_si(mt, 0x4), _si(mt, 0x8), _si(mt, 0xc)]):
			continue
		our_assigned[_g(p, 0x2c4)] = true
		opp_claimed[_g(mt, 0x2c4)] = true
		p[0x4] = Pm98Trig._i32(_si(mt, 0x4) - ivar21)     # copy xyz then x -= iVar21
		p[0x8] = _si(mt, 0x8)
		p[0xc] = _si(mt, 0xc)

	# ---- LOOP 3 (0x5b76ea): nearest unclaimed opponent within 1000.0, role-gated ----
	# For each still-unassigned outfield player (role NOT in {12,13,14,16,17}), claim the closest
	# valid-forward unclaimed opponent (3D ball-distance, bound 0x3e80000), snap on, x -= iVar21.
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0 or bool(our_assigned.get(_g(p, 0x2c4), false)):
			continue
		if _g(p, 0x2c8) in [0xc, 0xd, 0xe, 0x10, 0x11]:
			continue
		var j := _wall_nearest_opp(p, opps, opp_claimed, 0x3e80000)
		if j < 0:
			continue
		var o: Dictionary = opps[j]
		our_assigned[_g(p, 0x2c4)] = true
		opp_claimed[_g(o, 0x2c4)] = true
		p[0x4] = Pm98Trig._i32(_si(o, 0x4) - ivar21)
		p[0x8] = _si(o, 0x8)
		p[0xc] = _si(o, 0xc)

	# ---- LOOP 4 (0x5b78b1): nearest unclaimed opponent within 100.0, else RNG fallback ----
	# For each still-unassigned on-pitch player, claim the closest valid-forward unclaimed opponent
	# within 0x640000; on a hit, snap on then x += (flag ? +0x10000 : -0x10000). On a MISS:
	#   * role in {12,13,14,16,17} -> snap to endpoint1 (player+0x1e0);
	#   * else -> goal_target_x + RNG jitter (x += +/-rng1*33, y = rng2*80 - 0x140000, z = 0).
	# flag = (player.match+0x19a0 & 1) ^ player+0x2b8. our_assigned is marked on EVERY sub-path.
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0 or bool(our_assigned.get(_g(p, 0x2c4), false)):
			continue
		var pm: Dictionary = _ref(p, 0x18c)
		var pteam := _g(p, 0x2b8)
		var flag := (_g(pm, 0x19a0) & 1) ^ pteam
		var j := _wall_nearest_opp(p, opps, opp_claimed, 0x640000)
		our_assigned[_g(p, 0x2c4)] = true
		if j >= 0:
			var o: Dictionary = opps[j]
			opp_claimed[_g(o, 0x2c4)] = true
			p[0x4] = _si(o, 0x4)
			p[0x8] = _si(o, 0x8)
			p[0xc] = _si(o, 0xc)
			p[0x4] = Pm98Trig._i32(_si(p, 0x4) + (0x10000 if flag != 0 else -0x10000))
		elif _g(p, 0x2c8) in [0xc, 0xd, 0xe, 0x10, 0x11]:
			p[0x4] = _si(p, 0x1e0)                         # endpoint1
			p[0x8] = _si(p, 0x1e4)
			p[0xc] = _si(p, 0x1e8)
		else:
			var goalx := goal_target_x(_g(pm, 0x19a0), _si(pm, 0x1820), pteam)
			var mag1 := Pm98Trig._tdiv(Pm98Trig._i32(rng.next() * 0x1080), 0x80)   # rng*4224/128 = rng*33
			p[0x4] = Pm98Trig._i32(goalx + (-mag1 if flag != 0 else mag1))
			var mag2 := Pm98Trig._tdiv(Pm98Trig._i32(rng.next() * 0x2800), 0x80)   # rng*10240/128 = rng*80
			p[0x8] = Pm98Trig._i32(mag2 - 0x140000)
			p[0xc] = 0

	# ---- LOOP 5: facing toward ball + pairwise min-separation (ALWAYS runs) ----
	var n := players.size()
	var ball := [_si(m, 0x1614), _si(m, 0x1618), _si(m, 0x161c)]
	for i in n:
		var pi: Dictionary = players[i]
		var d: Array = Pm98Trig.vec3_sub(ball, [_si(pi, 0x4), _si(pi, 0x8), _si(pi, 0xc)])
		var facing := Pm98Trig.atan_angle(d[0], d[1]) & 0xffff
		pi[0x34] = facing
		pi[0x64] = facing
		for j in range(i + 1, n):
			var pj: Dictionary = players[j]
			if _g(pj, 0x2bc) == 0:
				continue
			var np: Array = Pm98Trig.mid_offset(
				[_si(pj, 0x4), _si(pj, 0x8), _si(pj, 0xc)],
				[_si(pi, 0x4), _si(pi, 0x8), _si(pi, 0xc)],
				0x10000, [ivar21, 0, 0])
			pj[0x4] = np[0]; pj[0x8] = np[1]; pj[0xc] = np[2]


## FUN_005b73a0 loop-1 inner pull (disasm 0x5b751f.. for role 10, 0x5b8626 for role 9). Scan every
## opponent; for each of role `want` not yet claimed, claim it, mark P assigned, and copy its xyz onto
## P with x shifted by -iVar21. No break (every matching opponent re-claims; one per role in practice).
static func _wall_pull(p: Dictionary, pid: int, opps: Array, opp_claimed: Dictionary,
		our_assigned: Dictionary, want: int, ivar21: int) -> void:
	for j in opps.size():
		var o: Dictionary = opps[j]
		var oid := _g(o, 0x2c4)
		if _g(o, 0x2c8) == want and not bool(opp_claimed.get(oid, false)):
			opp_claimed[oid] = true
			our_assigned[pid] = true
			p[0x4] = Pm98Trig._i32(_si(o, 0x4) - ivar21)
			p[0x8] = _si(o, 0x8)
			p[0xc] = _si(o, 0xc)


## FUN_005b73a0 loops 3+4 shared inner scan (disasm 0x5b7785../0x5b791c..): the nearest opponent (min
## 3D ball-distance) that is on-pitch (+0x2bc), not yet claimed (opp+0x2c4 id), and a valid forward
## target. Loop 3 gates with FUN_005b04e0; loop 4 with FUN_0058fb50 + an inline sign(opp.x) !=
## sign(opp+0x3a4) test -- both are bit-identical to pos_forward_ok, so it is reused for both.
## Returns the opponent index, or -1 if none is strictly within `bound`.
static func _wall_nearest_opp(p: Dictionary, opps: Array, opp_claimed: Dictionary, bound: int) -> int:
	var best := -1
	var best_dist := bound
	var px := _si(p, 0x4)
	var py := _si(p, 0x8)
	var pz := _si(p, 0xc)
	for j in opps.size():
		var o: Dictionary = opps[j]
		if _g(o, 0x2bc) == 0 or bool(opp_claimed.get(_g(o, 0x2c4), false)):
			continue
		if not pos_forward_ok(o, [_si(o, 0x4), _si(o, 0x8), _si(o, 0xc)]):
			continue
		var dist := _ball_dist(o, px, py, pz)
		if dist < best_dist:
			best = j
			best_dist = dist
	return best


## FUN_005b73a0 phase-5 TAIL (LAB_005b81d6, disasm 0x5b81d6..0x5b8603). Reached after the wall (or
## directly, when the wall branch was skipped) whenever match+0x448 == 5. Dispatch on match+0x19cc and
## match+0x45c:
##   * 0x19cc != 0 && 0x45c != team -> PATH A: the defensive-distribution insertion-sort (NOT YET PORTED);
##   * 0x19cc != 0 && 0x45c == team -> no-op return;
##   * 0x19cc == 0 && 0x45c == team -> PATH C (ported below).
## (0x45c != team with 0x19cc == 0 never reaches here through phase 5: the wall needs 0x45c != team and
## 0x19cc != 0, so a phase-5 wall implies Path A; Path C is the our-set-piece, no-19cc follow-up.)
static func _position_phase5_tail(ctx: Dictionary, m: Dictionary, team: int) -> void:
	if _g(m, 0x19cc) != 0:
		if _g(m, 0x45c) != team:
			push_error("position_team: phase-5 tail Path A (defensive distribution) not yet ported")
		return
	if _g(m, 0x45c) == team:
		_phase5_tail_pathC(ctx, m, team)


## FUN_005b73a0 phase-5 tail PATH C (disasm 0x5b8555..0x5b8603). For each OUR player whose x sits on the
## WRONG side of its anchor (sign(P+0x4) != sign(P+0x3a4)) AND that has at most 1 goal-side opponent
## (FUN_005b0b40(P, 0) <= 1), snap P.x to the team set-piece anchor x (*(match-team*800+0x98c)+0x4,
## modelled as ctx["spc_anchor"].+0x4) then push P out of the taker's 0x93333 min-separation box
## (FUN_005ee2d0 vs match+0x438). No RNG. count_goalside reads ctx["opponents"] (P+0x188 descriptor).
static func _phase5_tail_pathC(ctx: Dictionary, m: Dictionary, _team: int) -> void:
	var players: Array = ctx.get("players", [])
	var opponents: Array = ctx.get("opponents", [])
	var taker: Dictionary = _ref(m, 0x438)
	var anchor: Dictionary = ctx.get("spc_anchor", {})
	var anchor_x := _si(anchor, 0x4)
	for i in players.size():
		var p: Dictionary = players[i]
		if _sign1(_si(p, 0x4)) != _sign1(_si(p, 0x3a4)) \
				and count_goalside_opponents(p, opponents, 0) <= 1:
			p[0x4] = anchor_x
			var np: Array = Pm98Trig.clamp_min_sep(
				[_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)],
				[_si(taker, 0x4), _si(taker, 0x8), _si(taker, 0xc)],
				0x93333)
			p[0x4] = np[0]; p[0x8] = np[1]; p[0xc] = np[2]
