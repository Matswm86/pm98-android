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


## FUN_005943b0: match play-state (match+0x468 -> +0xfa0) == 0. (Thin alias of play_state_eq.)
static func _phase0(m: Dictionary) -> bool:
	return play_state_eq(m, 0)


## The OPPONENT team header for this movement context, faithful to the binary's opponent
## descriptor `match + 0x78c - 800*team` (team0 -> match[0x78c] = team1 header; team1 ->
## match[0x46c] = team0 header). Sourced from the nested m["sim"] = [team0, team1] that the
## roster build (Pm98Match.build_match / _build_team) produces, so it now works for BOTH
## team contexts -- not just the team-0 fixtures the earlier slices hardcoded.
##
## LEGACY FALLBACK: the oracle fixtures (test_relmatrix / test_marktarget / test_assignmarker)
## hand-build `m[0x78c]` as a bare opponent-players Array (no "sim"). When "sim" is absent we
## wrap that Array as a synthetic {"players": ...} header. The Array is shared by REFERENCE,
## so the in-place opponent mutations the matrix/marker passes write (+0x17c/+0x180/+0x150/
## +0x154/the matrix angle+dist keys) still flow back to what the fixture reads at m[0x78c].
static func _opp_team(ctx: Dictionary) -> Dictionary:
	var m: Dictionary = ctx.get(0x138, {})
	var sim: Variant = m.get("sim", null)
	if sim is Array and sim.size() == 2:
		return sim[1 - _g(ctx, 0x8)]
	return {"players": m.get(0x78c, [])}


## The opponent player Array: the built team's roster (team["players"]) or the legacy flat array.
static func _opp_players(ctx: Dictionary) -> Array:
	return _opp_team(ctx).get("players", [])


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
	var opp: Array = _opp_players(ctx)              # opponent roster (sim-sourced; team[0x4] count == size)
	var opp_n := opp.size()

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
# +0x188) = the opponent team header's players, fetched via _opp_players(ctx) (the
# faithful m["sim"][1-team]["players"], legacy-falling-back to flat m[0x78c]). The
# current mark target (player+0xb0) and the
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
	var opp: Array = _opp_players(ctx)               # opponent roster (sim-sourced; was m[0x78c] flat)
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
#   = opponent team descriptor (match + 0x78c - 800*team; team0 -> +0x78c), resolved here
#   via _opp_players(ctx) = m["sim"][1-team]["players"] (legacy fallback: flat match[0x78c]);
#   FUN_005b8c90 = "we are
#   in possession". POINTER->INDEX model: +0x150 holds an OPP index, +0x154 an OUR-team
#   index, both -1 = none (the binary's null pointer; index 0 is the real first player).
static func assign_markers(ctx: Dictionary) -> void:
	var players: Array = ctx.get("players", [])
	var team := _g(ctx, 0x8)
	var m: Dictionary = ctx.get(0x138, {})
	var opp: Array = _opp_players(ctx)               # opponent roster (sim-sourced; was m[0x78c] flat)

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


# ---- FUN_0058e2c0 ball ADVANCE (vtable+0xc on match+0x1610, i.e. the ball) ----------------
# The per-tick ball model the FUN_00598740 driver runs once per tick (decide companion FUN_0058e220
# = motion snapshot + replay, a no-op live). SLICE A (2026-06-19): the prologue timers + the
# lerp-to-target branch (set-piece ball placement: glide the ball toward +0x9c/+0xa0/+0xa4 over
# +0x6c steps). disasm 0x58e2c0..0x58e357.
#   timers (every call): +0x58 = +0x54; then decrement +0x5c, +0x70, +0x68 each iff nonzero.
#   lerp iff (post-decrement) +0x68 == 0 AND +0x6c != 0:
#     N = ORIGINAL +0x6c; +0x6c -= 1; pos[axis] += (target[axis] - pos[axis]) / N  (idiv, trunc->0).
#   else -> free flight / held-ball (SLICE B 2026-06-19: _ball_freeflight -- pos+=vel, gravity, bounce,
#   roll; goal/post collision + spin + tail still deferred, see _ball_freeflight header).
# The shared tail (FUN_0058fda0 trail + 0x58eb9a facing-from-velocity) writes only +0x34/+0x74+/+0x84+,
# none of which slice A/B reads, so it is intentionally omitted here (port in a later slice).
# Oracle: tools/re/run_balladvance_oracle.sh -> specs/balladvance_oracle.txt ; test_balladvance.gd.

static func ball_advance(ball: Dictionary) -> void:
	ball[0x58] = _g(ball, 0x54)                                  # +0x58 = +0x54 (prev-frame copy)
	if _g(ball, 0x5c) != 0: ball[0x5c] = Pm98Trig._i32(_g(ball, 0x5c) - 1)
	if _g(ball, 0x70) != 0: ball[0x70] = Pm98Trig._i32(_g(ball, 0x70) - 1)
	if _g(ball, 0x68) != 0: ball[0x68] = Pm98Trig._i32(_g(ball, 0x68) - 1)
	if _g(ball, 0x68) != 0 or _g(ball, 0x6c) == 0:              # not the lerp branch
		_ball_freeflight(ball)
		return
	var n := _g(ball, 0x6c)                                      # divisor = ORIGINAL step count
	ball[0x6c] = Pm98Trig._i32(n - 1)
	ball[0x4] = Pm98Trig._i32(_g(ball, 0x4) + _ball_step(_g(ball, 0x9c) - _g(ball, 0x4), n))
	ball[0x8] = Pm98Trig._i32(_g(ball, 0x8) + _ball_step(_g(ball, 0xa0) - _g(ball, 0x8), n))
	ball[0xc] = Pm98Trig._i32(_g(ball, 0xc) + _ball_step(_g(ball, 0xa4) - _g(ball, 0xc), n))
	_ball_tail(ball)                                             # lerp path jmps 0x58eb93 (trail entry, NO spin)


## One lerp axis step: (target - cur) / N, x86 idiv (truncate toward zero). N != 0 by caller guard.
static func _ball_step(delta: int, n: int) -> int:
	@warning_ignore("integer_division")
	return Pm98Trig._i32(Pm98Trig._i32(delta) / n)


# ---- FUN_0058e2c0 free-flight: integration + gravity + ground bounce/roll (SLICE B) ---------
# Constants from the disasm (gravity init FUN_0058e030 @0x58e030; bounce/roll @0x58e969..0x58eb09).
const BALL_GRAVITY := [0, 0, -178]   # DAT_0066c1b0/b4/b8: x=0, y=0, z=0xffffff4e (-178)
const BALL_BOUNCE_H := 0xc51e        # horiz restitution numerator (FUN_005edfa0 16.16, ~0.770)
const BALL_BOUNCE_V := 0x9c28        # vert  restitution numerator (~0.610), result negated
const BALL_VZ_SETTLE := 0x28f        # |vel.z| below this after a bounce -> vel.z = 0
const BALL_ROLL_STOP := 0x22         # both |vel.x| and |vel.y| below -> ball halts; else roll friction

## FUN_0058e2c0 free-flight branch -- SLICE B (the airborne/ground ball physics).
## Reached from ball_advance when NOT the lerp branch. Disasm anchors:
##   held gate 0x58e35c (byte ball+0x63 set -> tail only, no motion);
##   integration pos += vel 0x58e974..0x58e993;
##   bounce 0x58ea48, gravity 0x58ea1c, roll/stop 0x58e9b6, all then -> spin 0x58eb09.
## DELIBERATELY OUT OF SLICE B (later slices, all gated off in the oracle so this runs straight):
##   - goal/post collision sweep 0x58e497..0x58e963 (gated by match+0x5fac / post-count match+0x17f8);
##   - spin 0x58eb09 (writes +0x2c/+0x30 only) + trail/facing tail 0x58eb93 (writes +0x34/+0x74/+0xa8);
##   - the bounce's match+0x462 bit clears, bounce sound, and ball +0x61/+0x64 byte flags (match/anim
##     side, no effect on pos/vel). None of the deferred work touches pos(+0x4/+0x8/+0xc) or
##     vel(+0x20/+0x24/+0x28). The prologue's bbox build + temp `pos.z += 0x23d7` (0x58e437) is exactly
##     undone at 0x58e96c when collision is skipped, so the net z effect is just the integration here.
static func _ball_freeflight(ball: Dictionary) -> void:
	if (_g(ball, 0x60) >> 24) & 0xff != 0:                 # byte ball+0x63 -> held (0x58e361 jne 0x58eb93)
		_ball_tail(ball)                                  # held jmps the trail entry (NO spin), still faces+snapshots
		return
	_ball_collision(ball)                                 # goal/post sweep 0x58e497.. (before integration)
	var px := Pm98Trig._i32(_g(ball, 0x4) + _g(ball, 0x20))    # pos += vel (0x58e974..)
	var py := Pm98Trig._i32(_g(ball, 0x8) + _g(ball, 0x24))
	var pz := Pm98Trig._i32(_g(ball, 0xc) + _g(ball, 0x28))
	ball[0x4] = px
	ball[0x8] = py
	ball[0xc] = pz
	var vz := _g(ball, 0x28)
	if pz < 0 or (pz == 0 and vz < 0):                    # GROUND BOUNCE (0x58ea48)
		ball[0xc] = 0
		ball[0x20] = Pm98Trig.mul16(_g(ball, 0x20), BALL_BOUNCE_H)
		ball[0x24] = Pm98Trig.mul16(_g(ball, 0x24), BALL_BOUNCE_H)
		var nvz := Pm98Trig._i32(-Pm98Trig.mul16(_g(ball, 0x28), BALL_BOUNCE_V))
		ball[0x28] = 0 if absi(nvz) < BALL_VZ_SETTLE else nvz
	elif pz != 0 or vz != 0:                              # GRAVITY while airborne (0x58ea1c)
		ball[0x20] = Pm98Trig._i32(_g(ball, 0x20) + BALL_GRAVITY[0])
		ball[0x24] = Pm98Trig._i32(_g(ball, 0x24) + BALL_GRAVITY[1])
		ball[0x28] = Pm98Trig._i32(_g(ball, 0x28) + BALL_GRAVITY[2])
	else:                                                 # GROUND ROLL: pos.z==0 && vel.z==0 (0x58e9b6)
		var vx := _g(ball, 0x20)
		var vy := _g(ball, 0x24)
		if absi(vx) < BALL_ROLL_STOP and absi(vy) < BALL_ROLL_STOP:
			ball[0x20] = 0
			ball[0x24] = 0
			ball[0x28] = 0
		else:                                             # subtract a 0x22-magnitude step along heading
			var f := Pm98Trig.polar_vec(BALL_ROLL_STOP, Pm98Trig.atan_angle(vx, vy))
			ball[0x20] = Pm98Trig._i32(vx - int(f[0]))
			ball[0x24] = Pm98Trig._i32(vy - int(f[1]))
			ball[0x28] = Pm98Trig._i32(vz - int(f[2]))
	_ball_spin(ball)                                       # physics paths jmp 0x58eb09 (spin) -> tail
	_ball_tail(ball)


# ---- FUN_0058e2c0 post-physics tail (spin + facing + at-rest snapshot/drift) ------------------
# Reached after the free-flight physics (0x58eb09 spin entry) and from the lerp/held paths (0x58eb93
# trail entry, which skips spin). Pure ball-self state: spin index +0x2c/+0x30, facing +0x34, and the
# at-rest position snapshot +0x84/+0x88/+0x8c. None of it feeds match outcome (it drives the sprite
# spin frame + the ball's "predicted rest spot"); ported for fidelity. The render trail FUN_0058fda0
# (0x58eb95, writes the +0x74/+0xa8 particle history) is DEFERRED -- ~446 lines of pure draw, no sim
# read. Oracle-pinned by tools/re/run_balltail_oracle.sh -> specs/balltail_oracle.txt, test_balltail.gd.

## FUN_005ee500 dot16(a, b): (a.x*b.x + a.y*b.y + a.z*b.z) >> 16, full signed 64-bit product-sum.
static func _dot3_16(a: Array, b: Array) -> int:
	return Pm98Trig._i32(Pm98Trig._asr(int(a[0]) * int(b[0]) + int(a[1]) * int(b[1]) + int(a[2]) * int(b[2]), 16))


## SPIN (0x58eb09..0x58eb93). Advances the spin frame +0x2c (mod 32) by a step keyed on speed^2 =
## dot16(vel, vel); the slowest tier toggles parity +0x30 so it only steps every other call. Reached
## ONLY when vel != 0 (the 0x58eb09 all-zero gate falls straight through to the trail with no spin).
static func _ball_spin(ball: Dictionary) -> void:
	var vx := _g(ball, 0x20)
	var vy := _g(ball, 0x24)
	var vz := _g(ball, 0x28)
	if vx == 0 and vy == 0 and vz == 0:                   # 0x58eb09: ball stopped -> no spin
		return
	var s := _dot3_16([vx, vy, vz], [vx, vy, vz])         # FUN_005ee500(vel, vel)
	if s >= 0x4000:
		ball[0x2c] = (_g(ball, 0x2c) + 4) & 0x1f
	elif s > 0x226a:
		ball[0x2c] = (_g(ball, 0x2c) + 3) & 0x1f
	elif s > 0xc04:
		ball[0x2c] = (_g(ball, 0x2c) + 2) & 0x1f
	elif s > 0x222:
		ball[0x2c] = (_g(ball, 0x2c) + 1) & 0x1f
	else:                                                 # 0x58eb7d: slowest tier -- toggle +0x30, step every other
		var t := (_g(ball, 0x30) - 1) & 1
		ball[0x30] = t
		if t == 0:
			ball[0x2c] = (_g(ball, 0x2c) + 1) & 0x1f


## TAIL (0x58eb93 trail entry): trail (deferred) -> facing +0x34 = atan(vel) -> at-rest snapshot/drift.
static func _ball_tail(ball: Dictionary) -> void:
	# FUN_0058fda0 trail (render, +0x74/+0xa8) deferred -- writes nothing the sim/spin/facing/snapshot read.
	var vx := _g(ball, 0x20)
	var vy := _g(ball, 0x24)
	var vz := _g(ball, 0x28)
	ball[0x34] = Pm98Trig.atan_angle(vx, vy) & 0xffff     # 0x58eba2: facing word
	if vx == 0 and vy == 0 and vz == 0:                   # 0x58ebab vel==0 -> snapshot pos into +0x84
		ball[0x84] = _g(ball, 0x4)
		ball[0x88] = _g(ball, 0x8)
		ball[0x8c] = _g(ball, 0xc)
	else:                                                 # 0x58ebf2 drift branch
		_ball_drift(ball)


## DRIFT (0x58ebf2..0x58ec96): only while rolling on the deck (pos.z==0 && vel.z==0). Moves the at-rest
## snapshot +0x84 to pos + heading*max(proj,0) where proj = dot16(heading_unit, snapshot - pos). I.e. it
## keeps only the forward (along-heading) part of the snapshot's offset -- the ball's predicted stop spot.
static func _ball_drift(ball: Dictionary) -> void:
	if _g(ball, 0xc) != 0:                                # pos.z != 0 -> skip
		return
	if _g(ball, 0x28) != 0:                               # vel.z != 0 -> skip
		return
	var facing := Pm98Trig.atan_angle(_g(ball, 0x20), _g(ball, 0x24))   # eax from 0x58eba2 (vel heading)
	var u := Pm98Trig.polar_vec(0x10000, facing)          # FUN_005ee0f0(1.0, facing) = [cos, sin, 0] unit
	var d := [
		Pm98Trig._i32(_g(ball, 0x84) - _g(ball, 0x4)),    # D = snapshot - pos
		Pm98Trig._i32(_g(ball, 0x88) - _g(ball, 0x8)),
		Pm98Trig._i32(_g(ball, 0x8c) - _g(ball, 0xc)),
	]
	var d1 := _dot3_16(u, d)                              # FUN_005ee500(unit, D)
	var sc := d1 if d1 > 0 else 0                         # max(d1, 0) (0x58ec52 jle -> 0)
	var p := Pm98Trig.scale_vec3(int(u[0]), int(u[1]), int(u[2]), sc)   # FUN_005ee170 unit*sc
	ball[0x84] = Pm98Trig._i32(_g(ball, 0x4) + int(p[0])) # snapshot = pos + P
	ball[0x88] = Pm98Trig._i32(_g(ball, 0x8) + int(p[1]))
	ball[0x8c] = Pm98Trig._i32(_g(ball, 0xc) + int(p[2]))


# ---- FUN_005a22d0 GOALKEEPER ball-tracking advance ----------------------------------------------
# The keeper entity (match+0xaac / +0xe74, idx 1/2 in +0x3bc; vtable+0xc via FUN_005a2240 -> 5a24b0)
# slides its x along the goal line to shadow the ball: accelerate +/-0x28f toward ball.x (gated by the
# goal-mouth boundary flags), decay 0xa3/frame toward 0, clamp |vel| <= 0x1555, then face by velocity
# sign (atan to the ball when stopped). Load-bearing for saves/scoreline. m = keeper+0x18c (the match);
# ball pos = match+0x1614/+0x1618; goal line = match+0x1820. Reuses Pm98Trig.planar_mag (the FUN_005edfb0
# cos/sin-LUT projection == the keeper's distance-to-ball) + atan_angle. The "close" branch (proj <
# 0x30000) deliberately inverts the chase direction (shade between ball and goal). Oracle-pinned by
# tools/re/run_keeperadv_oracle.sh -> specs/keeperadv_oracle.txt, in app/tests/test_keeperadv.gd.
const KEEP_ACCEL := 0x28f       # per-frame accel toward ball.x (0x5a23b5/0x5a23d0)
const KEEP_FRIC := 0xa3         # per-frame decay toward 0 (0x5a23e7/0x5a23f8)
const KEEP_VMAX := 0x1555       # |velocity| clamp (0x5a2413/0x5a241f)
const KEEP_REACH := 0x30000     # planar_mag(ball-keeper) below this = "close" -> inverted chase
const KEEP_BAND := 0x40000      # goal-mouth half-width boundary + the far-branch x deadband

## FUN_005a22d0. Mutates keeper +0x3c0 (velocity), +0x4 (x), +0x34 (facing), +0x40 (position code).
static func keeper_advance(k: Dictionary) -> void:
	var m: Dictionary = _ref(k, 0x18c)
	var kx := _si(k, 0x4)
	var line := _si(m, 0x1820)
	var at_left: bool
	var at_right: bool
	if _g(k, 0x3bc) == 1:                                 # 0x5a22de team-1 (left) goal
		at_left = kx < KEEP_BAND
		at_right = kx > Pm98Trig._i32(line - KEEP_BAND)
	else:                                                 # 0x5a2301 team-2 (right) goal
		at_left = kx < Pm98Trig._i32(KEEP_BAND - line)
		at_right = kx > -KEEP_BAND
	var ky := _si(k, 0x8)
	var bx := _si(m, 0x1614)
	var by := _si(m, 0x1618)
	var proj := Pm98Trig.planar_mag(Pm98Trig._i32(bx - kx), Pm98Trig._i32(by - ky))   # FUN_005edfb0
	var vel := _si(k, 0x3c0)
	if proj >= KEEP_REACH:                                # 0x5a239d far: chase ball.x past a deadband
		var diff := Pm98Trig._i32(bx - kx)
		if absi(diff) > KEEP_BAND:
			if diff < 0:                              # ball left of keeper -> move left
				if not at_left: vel = Pm98Trig._i32(vel - KEEP_ACCEL)
			else:                                     # ball right -> move right
				if not at_right: vel = Pm98Trig._i32(vel + KEEP_ACCEL)
	else:                                                 # 0x5a238f close: INVERTED shade direction
		if bx > kx:
			if not at_left: vel = Pm98Trig._i32(vel - KEEP_ACCEL)
		else:
			if not at_right: vel = Pm98Trig._i32(vel + KEEP_ACCEL)
	if vel > 0:                                           # 0x5a23db friction toward 0, no overshoot
		vel = vel - KEEP_FRIC
		if vel < 0: vel = 0
	else:
		vel = vel + KEEP_FRIC
		if vel > 0: vel = 0
	if vel >= KEEP_VMAX: vel = KEEP_VMAX                  # 0x5a240d clamp |vel|
	if vel <= -KEEP_VMAX: vel = -KEEP_VMAX
	k[0x3c0] = vel
	var nkx := Pm98Trig._i32(kx + vel)                    # 0x5a243a keeper.x += vel
	k[0x4] = nkx
	if vel == 0:                                          # 0x5a243c facing by vel sign / atan to ball
		k[0x34] = Pm98Trig.atan_angle(Pm98Trig._i32(bx - nkx), Pm98Trig._i32(by - ky)) & 0xffff
	elif vel > 0:
		k[0x34] = 0
	else:
		k[0x34] = 0x8000
	set_position_code(k, 0x42 if vel == 0 else 0x43)      # 0x5a247e/0x5a2494
	# FUN_005a50c0 sprite/anim (reads +0x40/+0x30 -> draw frame) -- render no-op, no sim write.


## FUN_005a24b0 normal-play keeper wrapper (vtable state 1). Moving -> track ball; idle -> face by team +
## a 3-step idle-anim that records a position code (0x44/0x45/0x46) and advances +0x3c4. The FUN_005a2240
## entry dispatch over match+0x1a38 (set-piece/celebration keeper states 5a2560/5a25d0) is DEFERRED to
## the driver wire-up; open play routes match+0x1a38==1 (or match+0x19a0==4) -> here.
static func keeper_step(k: Dictionary) -> void:
	if _si(k, 0x3c0) != 0:                                # 0x5a24bb moving -> track ball
		keeper_advance(k)
		return
	k[0x34] = 0x4000 if _g(k, 0x3bc) == 1 else 0xc000     # 0x5a24c4 idle facing by team
	var anim := _g(k, 0x3c4)                              # 0x5a24db idle-anim state
	if anim == 0:                                         # 0x5a2544
		set_position_code(k, 0x44)
		k[0x3c4] = Pm98Trig._i32(anim + 1)
	elif anim == 1:                                       # 0x5a24f5
		# FUN_005a50c0 sprite -- render no-op.
		if _g(k, 0x40) == 0x42:                           # 0x5a24fc only when last code was 0x42
			var orient := _g(m_of(k), 0x19a0) & 1
			var side := _g(m_of(k), 0x45c)
			var gl := _si(m_of(k), 0x1820)
			if (orient ^ side) == 0: gl = Pm98Trig._i32(-gl)   # 0x5a251f neg goal line
			var is_t1 := 1 if _g(k, 0x3bc) == 1 else 0
			var gl_neg := 1 if gl < 0 else 0
			var code := 0x46 - (1 if (is_t1 ^ gl_neg) != 0 else 0)   # 0x5a253e 0x45/0x46
			set_position_code(k, code)
			k[0x3c4] = Pm98Trig._i32(anim + 1)
	# anim == 2 -> sprite-only (render); anim >= 3 -> nothing. Both no-op for the sim.


## Convenience: the keeper's match ref (keeper+0x18c).
static func m_of(k: Dictionary) -> Dictionary:
	return _ref(k, 0x18c)


# ---- FUN_0058e2c0 collision box leaves (the goal/post sweep broad-phase) ------------------
# Two pure box primitives the ball physics' goal/post collision loop (0x58e497..0x58e963, the NEXT
# unported slice of FUN_0058e2c0) calls while building + testing the ball's swept AABB against the
# goal volumes (match+0x2884/+0x2adc) and posts (match+0x17f4). No RNG/LUT/ftol, no sub-calls.
# Oracle-pinned by tools/re/run_collbox_oracle.sh -> specs/collbox_oracle.txt, in test_collbox.gd.
# (The goal sweep FUN_005f3b80, the post narrow-phase FUN_005efac0, and the loop control flow that
# wires these in -- calling the already-ported Pm98Events.keeper_event for the actual goal -- remain.)

## FUN_00590b10 (__thiscall v3; s): add the scalar s to three consecutive int32 (a vec3 / a box
## corner). Used to push a swept-box corner out by the 0x23d7 ball radius. Wraps to int32 each axis.
static func box_add3(v3: Array, s: int) -> Array:
	return [Pm98Trig._i32(int(v3[0]) + s), Pm98Trig._i32(int(v3[1]) + s), Pm98Trig._i32(int(v3[2]) + s)]


## FUN_00590b30 (__thiscall A; B): STRICT AABB overlap of two boxes, each [minx,miny,minz,maxx,maxy,
## maxz] (6 int32). Returns 1 iff on every axis max(A.min,B.min) < min(A.max,B.max); any axis with
## lo >= hi -> 0. The broad-phase gate before the per-post narrow collision.
static func boxes_overlap(a: Array, b: Array) -> bool:
	for axis in 3:
		var lo := maxi(int(a[axis]), int(b[axis]))         # max of the two mins
		var hi := mini(int(a[axis + 3]), int(b[axis + 3])) # min of the two maxs
		if lo >= hi:
			return false
	return true


# ---- FUN_0058e2c0 goal/post COLLISION loop (0x58e497..0x58e963) -------------------------------
# Runs at the head of the free-flight branch, BEFORE integration: sweeps the ball's inflated swept AABB
# against the two goal volumes (match+0x2884/+0x2adc) and the post array (match+0x17f4 base, +0x17f8
# count, stride 0x58), clips pos/vel on a hit, and SCORES a goal when a goal-line post (id 0x9eb8) is
# crossed inward in open play. The prologue's temp `pos.z += 0x23d7` (0x58e437) is always undone
# (0x58e96c) before integration, so it has no net effect and is not modelled here.
#
# DEFERRED -- the two heavy geometry leaves, each a full bit-exact 3D swept-collision routine (~400 lines
# of axis-rotation FUN_005ee670/6e0/750 + corner/clip math): FUN_005f3b80 (goal-mouth swept-sphere vs the
# rotated goal-frame triangle mesh, mutates pos/vel on hit) and FUN_005efac0 (per-post swept-box narrow
# phase + velocity reflect). Until they land they return NO HIT, so the loop is a faithful no-op on
# pos/vel (the common per-tick case) and live goals are not yet detected. ALSO PENDING (next session,
# with the driver): the match-init that POPULATES match+0x17f4 (the post array) + match+0x2884/+0x2adc
# (goal volumes) -- without it the loop sees zero posts. The goal-scoring DETECTION below is fully ported
# + unit-tested (test_collgoal.gd) and fires the already-validated Pm98Events.keeper_event + enqueue the
# moment FUN_005efac0 reports a 0x9eb8 hit. The broad-phase box leaves were oracle-validated in 2bbdc13.

const BALL_RADIUS := 0x23d7

## The ball's swept AABB (0x58e367..0x58e404), inflated by the ball radius: per axis
## [min(pos, pos+vel) - r,  max(pos, pos+vel) + r]. Returns a 6-int box [minx,miny,minz,maxx,maxy,maxz].
static func _ball_swept_box(ball: Dictionary) -> Array:
	var p := [_si(ball, 0x4), _si(ball, 0x8), _si(ball, 0xc)]
	var e := [Pm98Trig._i32(p[0] + _si(ball, 0x20)), Pm98Trig._i32(p[1] + _si(ball, 0x24)),
		Pm98Trig._i32(p[2] + _si(ball, 0x28))]
	var mn := box_add3([mini(p[0], e[0]), mini(p[1], e[1]), mini(p[2], e[2])], -BALL_RADIUS)
	var mx := box_add3([maxi(p[0], e[0]), maxi(p[1], e[1]), maxi(p[2], e[2])], BALL_RADIUS)
	return [mn[0], mn[1], mn[2], mx[0], mx[1], mx[2]]


## Ball pos inside the goal box [match+0x1828..+0x1834] x [+0x182c..+0x1838] x [+0x1830..+0x183c],
## inclusive (the 0x58e448 prologue gate + the 0x58e7c6 goal-detect gate).
static func _in_goal_box(ball: Dictionary, m: Dictionary) -> bool:
	var x := _si(ball, 0x4)
	var y := _si(ball, 0x8)
	var z := _si(ball, 0xc)
	return (_si(m, 0x1828) <= x and x <= _si(m, 0x1834)
		and _si(m, 0x182c) <= y and y <= _si(m, 0x1838)
		and _si(m, 0x1830) <= z and z <= _si(m, 0x183c))


## FUN_005f3b80 goal-mouth swept-sphere vs the rotated goal-frame mesh. DEFERRED -- returns false (no
## hit), leaving pos/vel untouched, until the rotation/triangle-mesh port lands. tag 0x8000/0x7ae1.
static func _goal_sweep(_ball: Dictionary, _goal: Dictionary, _tag: int) -> bool:
	return false


## Win32 MulDiv(a, b, c) = round((a*b)/c), ties away from zero; -1 if c==0. Used by the post-quad
## point-in-polygon edge interpolation (the binary calls the real MulDiv import).
static func _muldiv(a: int, b: int, c: int) -> int:
	if c == 0:
		return -1
	var prod := a * b
	var neg := (prod < 0) != (c < 0)
	var m := absi(prod)
	var d := absi(c)
	@warning_ignore("integer_division")
	var r := (m + d / 2) / d
	return Pm98Trig._i32(-r if neg else r)


## FUN_005efac0 per-post swept narrow phase + velocity reflect. The post is an oriented quad: 4 corners
## post+0..+0x2c, an orientation direction post+0x48 (boxgeo), and post+0x54 = id-AND-restitution. Rotate
## the ball segment (pos -> pos+vel) into the post-local frame (2 angles from boxgeo), find where it
## crosses the post plane (local x = the normal), test if that entry point is inside the quad (a 2x2-
## sampled crossing-number point-in-polygon in the local y-z plane via MulDiv edge interpolation), and on
## a hit advance pos to the crossing + reflect vel off the quad (scaled by post-id-as-restitution) +
## write the 2-int deflect to `out`. Returns hit. (Disasm 0x5efac0..0x5f0058; decompile fn_005efac0.)
static func _post_narrow(ball: Dictionary, post: Dictionary, out: Array = []) -> bool:
	var c0 := [_si(post, 0x0), _si(post, 0x4), _si(post, 0x8)]
	var boxgeo := [_si(post, 0x48), _si(post, 0x4c), _si(post, 0x50)]
	var post_id := _g(post, 0x54)
	var pos := [_si(ball, 0x4), _si(ball, 0x8), _si(ball, 0xc)]
	var vel := [_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28)]

	# --- post orientation angles from boxgeo (local_40 = ang_z, local_58 = ang_y) ---
	var ang_z := Pm98Trig.atan_angle(boxgeo[0], boxgeo[1])
	var bg := boxgeo.duplicate()
	Pm98Trig.rot_vec3(bg, -ang_z, 0)
	var ang_y := Pm98Trig.atan_angle(bg[0], bg[2])
	var sign := 1                                          # local_50

	# velocity into the post-local frame
	var lvel := vel.duplicate()
	Pm98Trig.rot_vec3(lvel, -ang_z, 0)
	Pm98Trig.rot_vec3(lvel, -ang_y, 1)
	if lvel[0] < 0:                                        # 0x5efb7c
		sign = -1
		lvel[0] = Pm98Trig._i32(-lvel[0])
		lvel[2] = Pm98Trig._i32(-lvel[2])
		ang_y = Pm98Trig._i32(ang_y - 0x8000)

	# rel-pos (pos - c0) into the post-local frame
	var rp := [Pm98Trig._i32(pos[0] - c0[0]), Pm98Trig._i32(pos[1] - c0[1]), Pm98Trig._i32(pos[2] - c0[2])]
	Pm98Trig.rot_vec3(rp, -ang_z, 0)
	Pm98Trig.rot_vec3(rp, -ang_y, 1)

	if lvel[0] == 0:                                       # 0x5efbe8 segment parallel to the post plane
		return false

	# swept entry along the local normal (local x): the gate at 0x5efbf0..0x5efc32
	var absvx := absi(lvel[0])
	var sgnvx := 1 if lvel[0] >= 0 else -1
	var ent := Pm98Trig._i32(-((rp[0] + BALL_RADIUS) * sgnvx))
	if not (((ent >= 0) and (ent < absvx)) or ((-BALL_RADIUS < rp[0]) and (rp[0] < 1))):
		return false
	var t := Pm98Trig.ratio16(ent, absvx)                 # FUN_005edf90: fraction along the segment (16.16)

	# entry point in the local y-z plane = rp + lvel*t (only y,z used)
	var ent_vec := Pm98Trig.scale_vec3(lvel[0], lvel[1], lvel[2], t)
	var sy0 := Pm98Trig._i32(int(ent_vec[1]) + rp[1])     # local_8c
	var sx0 := Pm98Trig._i32(int(ent_vec[2]) + rp[2])     # local_88

	# the 4 quad corners -> relative to c0 -> rotated into the local frame (cv[3k+1]=y, cv[3k+2]=z)
	var cv := []
	for k in 4:
		var cc := [_si(post, k * 0xc + 0x0), _si(post, k * 0xc + 0x4), _si(post, k * 0xc + 0x8)]
		cc[0] = Pm98Trig._i32(cc[0] - c0[0])
		cc[1] = Pm98Trig._i32(cc[1] - c0[1])
		cc[2] = Pm98Trig._i32(cc[2] - c0[2])
		Pm98Trig.rot_vec3(cc, -ang_z, 0)
		Pm98Trig.rot_vec3(cc, -ang_y, 1)
		cv.append_array(cc)

	# 2x2-sampled crossing-number point-in-polygon (0x5efd47..0x5efe54). Polygon in (y,z); ray in +z.
	var hit := false
	var la := -1
	while la <= 1:
		var iv := -1
		while not hit and iv < 2:
			var parity := false
			var sy := Pm98Trig._i32(la + sy0)
			var sx := Pm98Trig._i32(iv + sx0)
			for k in 4:
				var cur_y := int(cv[k * 3 + 1])
				var cur_z := int(cv[k * 3 + 2])
				var ni := (k + 1) & 3
				var nxt_y := int(cv[ni * 3 + 1])
				var nxt_z := int(cv[ni * 3 + 2])
				var crosses := false
				if cur_y < sy:
					if sy <= nxt_y:
						crosses = true
				elif nxt_y < sy:
					crosses = true
				if crosses:
					var zc := _muldiv(nxt_z - cur_z, sy - cur_y, nxt_y - cur_y)
					if Pm98Trig._i32(zc + cur_z) < sx:
						parity = not parity
			hit = parity
			iv += 2
		la += 2
		if hit:
			break
	if not hit:
		return false

	# --- HIT: advance pos to the crossing, reflect vel, write deflect ---
	var adv := Pm98Trig.scale_vec3(vel[0], vel[1], vel[2], t)   # pos += vel_world * t
	pos[0] = Pm98Trig._i32(pos[0] + int(adv[0]))
	pos[1] = Pm98Trig._i32(pos[1] + int(adv[1]))
	pos[2] = Pm98Trig._i32(pos[2] + int(adv[2]))

	if not out.is_empty():
		_post_reflect_out(post, c0, pos, sign, out)        # the param_7 deflect (FPU edge-normal projection)

	# reflect: rotate the LOCAL-frame vel (lvel, which already carries the forward-rotation LUT artifacts)
	# back out (0x5effb3..0x5effd9), so the inverse rotation cancels them: ee750(-0x8000) [reflect across
	# the yz plane] -> ee6e0(ang_y) -> ee670(ang_z), negate, scale by post-id restitution (ee1c0).
	var rvel := lvel.duplicate()
	Pm98Trig.rot_vec3(rvel, -0x8000, 2)                    # FUN_005ee750(0xffff8000)
	Pm98Trig.rot_vec3(rvel, ang_y, 1)                      # FUN_005ee6e0(ang_y)
	Pm98Trig.rot_vec3(rvel, ang_z, 0)                      # FUN_005ee670(ang_z)
	rvel = [Pm98Trig._i32(-int(rvel[0])), Pm98Trig._i32(-int(rvel[1])), Pm98Trig._i32(-int(rvel[2]))]
	rvel = Pm98Trig.scale_vec3(rvel[0], rvel[1], rvel[2], post_id)   # FUN_005ee1c0(post_id): *restitution
	ball[0x20] = rvel[0]
	ball[0x24] = rvel[1]
	ball[0x28] = rvel[2]
	var back := Pm98Trig.scale_vec3(rvel[0], rvel[1], rvel[2], t)
	ball[0x4] = Pm98Trig._i32(pos[0] - int(back[0]))
	ball[0x8] = Pm98Trig._i32(pos[1] - int(back[1]))
	ball[0xc] = Pm98Trig._i32(pos[2] - int(back[2]))
	return true


## FUN_005efac0 reflect deflect-output (param_7 path, 0x5efe54..0x5effb0): project the hit point onto the
## two quad edges (each normalized via fsqrt/ftol) and write the 2-int barycentric-ish deflect, x-sign by
## `sign`. Best-effort FPU port -- pinned against the oracle's `out` reads.
static func _post_reflect_out(post: Dictionary, c0: Array, pos: Array, sign: int, out: Array) -> void:
	var e0 := [_si(post, 0xc) - c0[0], _si(post, 0x10) - c0[1], _si(post, 0x14) - c0[2]]   # c1-c0
	var e1 := [_si(post, 0x18) - _si(post, 0xc), _si(post, 0x1c) - _si(post, 0x10), _si(post, 0x20) - _si(post, 0x14)]  # c2-c1
	var hp := [Pm98Trig._i32(pos[0] - c0[0]), Pm98Trig._i32(pos[1] - c0[1]), Pm98Trig._i32(pos[2] - c0[2])]
	var u0 := _normalize_edge(e0)
	var u1 := _normalize_edge(e1)
	out.resize(2)
	out[0] = Pm98Trig._i32(_dot3_16(u0, hp) * sign)
	out[1] = Pm98Trig._i32(_dot3_16(u1, hp) * sign)


## Normalize an edge by its length: len = trunc(sqrt(dot)); d = (len*len)>>16; v[i] = (0x10000*v[i])/d.
## Mirrors the binary's fsqrt -> ftol -> FUN_005edfa0(len,len) -> FUN_005ee200(d) chain.
static func _normalize_edge(e: Array) -> Array:
	var dot := int(e[0]) * int(e[0]) + int(e[1]) * int(e[1]) + int(e[2]) * int(e[2])
	var ln := int(sqrt(float(dot)))                       # ftol(sqrt) truncates toward zero
	var d := Pm98Trig.mul16(ln, ln)
	if d == 0:
		return [0, 0, 0]
	return [Pm98Trig.ratio16(int(e[0]), d), Pm98Trig.ratio16(int(e[1]), d), Pm98Trig.ratio16(int(e[2]), d)]


## GOAL-SCORING DETECTION (0x58e756..0x58e8d2), reached once FUN_005efac0 reports a post hit. Branch on
## the post id (post+0x54): 0x7ae1 = crossbar (render ripple only, no score); 0x9eb8 = goal line ->
## score iff the ball is crossing the line inward (sign(vel.x) != sign(pos.x)), inside the goal box, and
## in open play (match+0x448 == 0). On a goal: bump the keeper stat (keeper_event(ball, 1)), enqueue the
## goal commentary event (0x1b when |pos.y| >= 0x36b85 else 0x1a), and clear the latched keeper +0x50.
static func _collision_goal_check(ball: Dictionary, m: Dictionary, post: Dictionary) -> void:
	var pid := _g(post, 0x54)
	if pid == 0x7ae1:
		return                                            # crossbar -- no scoring
	if pid != 0x9eb8:
		return                                            # not a goal-line post
	if _sign1(_si(ball, 0x20)) == _sign1(_si(ball, 0x4)):  # 0x58e7a2 vel.x / pos.x sign must differ
		return
	if not _in_goal_box(ball, m):                         # 0x58e7c6
		return
	if _g(m, 0x448) != 0:                                 # 0x58e819 open play only
		return
	Pm98Events.keeper_event(ball, 1)                      # 0x58e832 FUN_005909f0 stat bump
	var evcode := 0x1b if absi(_si(ball, 0x8)) >= 0x36b85 else 0x1a   # 0x58e83f wide-goal commentary code
	Pm98Events.enqueue(m, evcode, {}, 1)                  # 0x58e8c7 FUN_00594470
	ball[0x50] = 0                                        # 0x58e8d2


## FUN_0058e2c0 collision loop control flow (0x58e497..0x58e963). Both goal sweeps + the per-post narrow
## phase are DEFERRED leaves (no-hit) and the post array is unpopulated until match-init lands, so this
## is currently a faithful no-op; the structure (gates, swept-box rebuild on hit, restart-on-hit, goal
## scoring) is in place for when those land. Runs before integration in _ball_freeflight.
static func _ball_collision(ball: Dictionary) -> void:
	var m: Dictionary = _ref(ball, 0x1d4)
	if m.is_empty():
		return
	var box := _ball_swept_box(ball)
	# Two goal-frame sweeps, gated by match+0x5fac (goals enabled) AND the ball being OUTSIDE the goal
	# box (0x58e43a/0x58e448 -- in-region skips straight to the post loop). Both leaves are deferred.
	if _g(m, 0x5fac) & 0xff != 0 and not _in_goal_box(ball, m):
		if _goal_sweep(ball, _ref(m, 0x2884), 0x8000):    # goal 1 (0x58e4a9)
			box = _ball_swept_box(ball)
		if _goal_sweep(ball, _ref(m, 0x2adc), 0x7ae1):    # goal 2 (0x58e56e)
			box = _ball_swept_box(ball)
	# Post loop: broad-phase boxes_overlap(swept, post+0x30) -> narrow FUN_005efac0 -> on hit, clip the
	# swept box and re-scan from the top (the binary's restart-on-hit at 0x58e73e). Bounded by the post
	# count to stay terminating even when a future narrow phase keeps reporting hits.
	var posts: Array = m.get(0x17f4, [])
	var count := _g(m, 0x17f8)
	var guard := count * count + 1                        # restart-on-hit terminator
	var i := 0
	while i < count and i < posts.size() and guard > 0:
		guard -= 1
		var post: Dictionary = posts[i] if posts[i] is Dictionary else {}
		var post_box := [_si(post, 0x30), _si(post, 0x34), _si(post, 0x38),
			_si(post, 0x3c), _si(post, 0x40), _si(post, 0x44)]
		if boxes_overlap(box, post_box) and _post_narrow(ball, post):
			_collision_goal_check(ball, m, post)          # 0x9eb8 goal-line -> score
			ball[0x80] = Pm98Trig._i32(_g(ball, 0x80) + 1)  # 0x58e954 collision counter
			box = _ball_swept_box(ball)                   # rebuild after the reflect
			i = 0                                         # restart the scan
			continue
		i += 1


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


## FUN_005b0bb0 (__thiscall player; tgt, angle, scale, dist -> bool): the AI "is this teammate a
## valid pass / lay-off target" test. Returns true (and marks the receiver) when the player already
## owns the ball, OR when the candidate position `tgt` lies inside the pass capsule: its projection
## onto the unit pass direction is within [~round0(thr_base/3)/... , round0(thr_base/3)+scale] AND its
## perpendicular offset |v1 x D| <= thr_base, where thr_base = 0x50000 if the ball is owned by someone
## else 0x30000. On a hit it sets match+0x43c = player (chosen receiver) and match+0x460 = the
## set-piece cooldown tier (0x5a/0x3c/0x1e/0xf) by |player.x - tgt.x|. `opponents` feeds the
## FUN_005b0b40 gate (>= 2 goalside opponents closer than self -> no target). The `this` is the PLAYER
## BASE (the FUN_005ab5a0 decompile mis-renders the call receiver as player+4; the body uses
## [player+4]/[+0x3a4]/[+0x190]/[+0x18c], confirmed by objdump _passtest_5b0bb0.asm). Geometry leaves:
## polar_vec (FUN_005ee0f0) / dot16 (FUN_005ee500) / cross16 (FUN_005ee540) + the FP perpendicular
## magnitude (FILD/FSQRT + _ftol, round-to-zero). Oracle: run_passtest_oracle.sh -> passtest_oracle.txt.
static func mark_pass_receiver(p: Dictionary, tgt: Array, angle: int, scale: int, dist: int, opponents: Array) -> bool:
	if count_goalside_opponents(p, opponents, 0) >= 2:        # FUN_005b0b40(0) >= 2 -> no target
		return _pass_tail(p, tgt, false)
	var d_self: int = 0xc80000 if p.is_empty() else abs(Pm98Trig._i32(_si(p, 0x4) + _si(p, 0x3a4)))
	if d_self >= Pm98Trig._i32(dist):
		return _pass_tail(p, tgt, false)
	var ball := _ref(p, 0x190)
	var owner: Variant = ball.get(0x4c, null)
	var hit: bool = (owner is Dictionary and owner == p)
	if not hit:
		var m := _ref(p, 0x18c)
		if _si(p, 0x68) > 0x776:                              # facing must point near the player's goal
			var goalx := _si(m, 0x1820)
			if (1 - _g(p, 0x2b8)) == (_g(m, 0x19a0) & 1):
				goalx = Pm98Trig._i32(-goalx)
			var dgx := Pm98Trig._i32(goalx - _si(p, 0x4))     # FUN_00590ae0([goalx,0,0] - player.pos)
			var dgy := Pm98Trig._i32(-_si(p, 0x8))
			var ang := Pm98Trig.atan_angle(dgx, dgy)
			if abs(Pm98Trig._s16(ang - _g(p, 0x34))) > 0x4e39:
				return _pass_tail(p, tgt, false)
		var thr_base := 0x50000 if (owner is Dictionary) else 0x30000   # ball+0x4c != 0
		var half := _div2_rz(scale)
		var v1 := Pm98Trig.polar_vec(0x10000, angle)          # unit pass direction
		var v2 := Pm98Trig.polar_vec(half, angle)
		var thr := Pm98Trig._i32(half + thr_base)
		var inside: bool = abs(Pm98Trig._i32(_si(p, 0x4) - int(v2[0]) - int(tgt[0]))) < thr \
			and abs(Pm98Trig._i32(_si(p, 0x8) - (int(v2[1]) + int(tgt[1])))) < thr \
			and abs(Pm98Trig._i32(_si(p, 0xc) - (int(v2[2]) + int(tgt[2])))) < thr
		if inside:
			var dvec := [Pm98Trig._i32(_si(p, 0x4) - int(tgt[0])), \
				Pm98Trig._i32(_si(p, 0x8) - int(tgt[1])), Pm98Trig._i32(_si(p, 0xc) - int(tgt[2]))]
			var proj := _dot3_16(v1, dvec)                    # FUN_005ee500(v1, D)
			var q3 := (thr_base * 0x55555555) >> 32           # high32 of signed product (thr_base > 0)
			var lo := _div2_rz(q3 - thr_base)                 # (iVar8>>1) - (iVar8>>31) == round0(iVar8/2)
			var hi := Pm98Trig._i32(((thr_base * 0x55555556) >> 32) + scale)
			if lo <= proj and proj <= hi:
				var cr: Array = Pm98Trig.cross16(v1, dvec)    # FUN_005ee540(v1, out, D)
				var cx := float(int(cr[0]))
				var cy := float(int(cr[1]))
				var cz := float(int(cr[2]))
				var perp := int(sqrt(cx * cx + cy * cy + cz * cz))   # FILD/FSQRT + _ftol (round to zero)
				hit = perp <= thr_base
	return _pass_tail(p, tgt, hit)


## The FUN_005b0bb0 tail: on a hit, record the chosen receiver (match+0x43c = player) and the set-piece
## cooldown tier (match+0x460) keyed on |player.x - tgt.x|. Returns `hit` unchanged.
static func _pass_tail(p: Dictionary, tgt: Array, hit: bool) -> bool:
	if hit:
		var m := _ref(p, 0x18c)
		m[0x43c] = p
		var d: int = abs(Pm98Trig._i32(_si(p, 0x4) - int(tgt[0])))
		if d > 0x1e0000:
			m[0x460] = 0x5a
		elif d > 0x140000:
			m[0x460] = 0x3c
		elif d > 0xa0000:
			m[0x460] = 0x1e
		else:
			m[0x460] = 0xf
	return hit


## Round-toward-zero halving (the binary's `cdq; sub eax,edx; sar 1`), faithful for negative operands
## where _asr would floor instead. Used for `scale / 2` and the `iVar8 / 2` capsule lower bound.
static func _div2_rz(x: int) -> int:
	return -((-x) >> 1) if x < 0 else x >> 1


# ---- FUN_005ab5a0 : the POST-SHOT / loose-ball RESOLUTION (oracle: run_postshot_oracle.sh) --------
# The open-play engine runs this after a player's action settles. Three small predicates the body uses
# (the corner/byline + goal-box tests, oriented by the player's goal anchor +0x3a4). goalx = match+0x1820.

## FUN_005ac0e0 (__thiscall player; vec): |vec.x| is past the goal line minus 0x160000 AND |vec.y| is
## beyond the box half-width 0x1428f5.
static func _ps_corner(p: Dictionary, vx: int, vy: int) -> bool:
	var goalx := _si(_ref(p, 0x18c), 0x1820)
	return abs(Pm98Trig._i32(vx)) > goalx - 0x160000 and abs(Pm98Trig._i32(vy)) > 0x1428f5


## FUN_005ac120 (__thiscall player; vec): _ps_corner AND vec.x on the OPPOSITE side from the anchor.
static func _ps_corner_oppside(p: Dictionary, vx: int, vy: int) -> bool:
	return _ps_corner(p, vx, vy) and _sign1(Pm98Trig._i32(vx)) != _sign1(_si(p, 0x3a4))


## FUN_0058fb50 (__thiscall player; vec): vec inside the goal AABB (match+0x1828..+0x183c) AND |vec.x|
## past goalx - 0x108000 AND |vec.y| < 0x1428f5.
static func _ps_goalbox(p: Dictionary, v: Array) -> bool:
	var m := _ref(p, 0x18c)
	var x := Pm98Trig._i32(int(v[0]))
	var y := Pm98Trig._i32(int(v[1]))
	var z := Pm98Trig._i32(int(v[2]))
	if x < _si(m, 0x1828) or _si(m, 0x1834) < x or y < _si(m, 0x182c) or _si(m, 0x1838) < y \
			or z < _si(m, 0x1830) or _si(m, 0x183c) < z:
		return false
	return _si(m, 0x1820) - 0x108000 < abs(x) and abs(y) < 0x1428f5


## FUN_005ab5a0 (__fastcall this=player): the post-shot / loose-ball resolution. Headless (match+0x180b
## == 0) every commentary/animation call is gated out, so this reproduces only the SIM residue + the
## match event-queue pushes:
##   * ball+0x50 = player and ball+0x64 = (|anchor+px| > 0x1e0000) (always);
##   * contested-touch stat (player[0x3b8]+0x88)++ when the ball was owned (DAT_006d31c4 is 0 in-sim);
##   * action != 0x13 + the corner/oppside gates + |bvec - pos| > 0xa0000 + match+0x44c != 4 -> enqueue
##     0x10 (bvec = ball+0xcc, the ball's predicted-rest spot);
##   * the pass-target scan: FUN_005b0bb0 from the ball owner, then each teammate, testing THIS player
##     (player+4) as the receiver -- a hit jumps straight to the tail (its receiver mark is then cleared
##     again by the tail engage, so net match+0x43c/0x460 = 0);
##   * ball+0x48 an opponent of a DIFFERENT team + the corner/sameside gate (and |player.a0| not past
##     the box) -> enqueue 0xe;
##   * else LAB_bbe8: unowned ball -> keeper counter (player[0x184]+0x2e4)++ when facing aligns with the
##     goal (<= 0x3554); owned ball -> the classification ladder draws ONE rng when it reaches the
##     004ea9f0 arm (mag <= 0x7ffff AND sign(px) != sign(anchor));
##   * the tail engages the ball to the player (FUN_0058eca0), clears ball+0x40 (FUN_0058ed70), clears
##     match+0x438 if it held this player, and resets the match phase to 0.
## `teammates` is the player[0x184] team list (the +0x3bc-stride array, self/owner skipped); `rng` is the
## match seed (Pm98Rng or null) for the lone classification draw.
static func resolve_post_shot(p: Dictionary, teammates: Array, rng = null) -> void:
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)
	var px := _si(p, 0x4)
	var py := _si(p, 0x8)
	var pz := _si(p, 0xc)
	var anchor := _si(p, 0x3a4)
	var bvx := _si(ball, 0xcc)
	var bvy := _si(ball, 0xd0)
	ball[0x50] = p                                        # ball+0x50 = player (always)
	var owner: Variant = ball.get(0x4c, null)
	var owned: bool = owner is Dictionary
	if owned:                                             # DAT_006d31c4 is 0 in-sim -> gate = "ball owned"
		var stat := _ref(p, 0x3b8)
		stat[0x88] = _g(stat, 0x88) + 1                   # contested-touch counter

	var to_tail := false
	if _g(p, 0x40) != 0x13:                               # not the case-0x13 (set-piece) action
		if _ps_corner_oppside(p, px, py):
			var okg := _ps_goalbox(p, [bvx, bvy, _si(ball, 0xd4)]) and _sign1(bvx) != _sign1(anchor)
			if not okg:
				okg = _ps_corner(p, bvx, bvy) and _sign1(bvx) != _sign1(anchor)
			if okg:
				var lcx := Pm98Trig._i32(bvx - px)        # local_c = bvec - player_pos
				var lcy := Pm98Trig._i32(bvy - py)
				if Pm98Trig.planar_mag(lcx, lcy) > 0xa0000 and _g(m, 0x44c) != 4:
					Pm98Events.enqueue(m, 0x10, p, 0)

	if m.get(0x438, null) == p:                           # player == match+0x438 (controlled) -> tail
		to_tail = true

	if not to_tail:
		var dx := Pm98Trig._i32(_si(p, 0xa0) - px)
		var dy := Pm98Trig._i32(_si(p, 0xa4) - py)
		var angle := Pm98Trig.atan_angle(dx, dy)
		var pm := Pm98Trig.planar_mag(dx, dy)
		var scale: int = pm if pm < 0x370000 else 0x370000    # local_20 = min(planar_mag, 0x370000)
		var dist: int = abs(Pm98Trig._i32(anchor + px))       # local_24
		var ppos := [px, py, pz]
		var hit := false
		if _g(m, 0x448) == 0 and _sign1(anchor) != _sign1(_si(ball, 0x20)):
			if owned:                                     # FUN_005b0bb0 from the owner's perspective
				if mark_pass_receiver(owner, ppos, angle, scale, dist, owner.get(0x188, [])):
					hit = true
			if not hit:
				for tc in teammates:                      # ... then each teammate
					var tcd: Dictionary = tc
					if tcd != p and not (owned and tcd == owner):
						if mark_pass_receiver(tcd, ppos, angle, scale, dist, tcd.get(0x188, [])):
							hit = true
							break
		if hit:
			to_tail = true

	if not to_tail:
		var do_bbe8 := false
		var bp48: Variant = ball.get(0x48, null)
		if not (bp48 is Dictionary) or _g(p, 0x2b8) == _g(bp48, 0x2b8):
			do_bbe8 = true
		else:                                             # ball+0x48 = a different-team opponent
			var ok2 := _ps_goalbox(p, [px, py, pz]) and _sign1(px) == _sign1(anchor)
			if not ok2:
				ok2 = _ps_corner(p, px, py) and _sign1(px) == _sign1(anchor)
			if not ok2:
				do_bbe8 = true
			elif _sign1(_si(p, 0xa0)) == _sign1(anchor) and abs(_si(p, 0xa0)) > 0xeffff:
				do_bbe8 = true
			else:
				Pm98Events.enqueue(m, 0xe, p, 0)
		if do_bbe8:
			if not owned:                                 # unowned -> keeper counter
				_postshot_keeper(p, m, px, py)
			else:                                         # owned -> classification ladder (lone draw)
				_postshot_classify_draw(p, px, py, anchor, rng)

	# tail (LAB_005ac069) -- always runs
	_ball_engage_player(ball, p)
	ball[0x40] = 0                                        # FUN_0058ed70 (this=ball)
	if m.get(0x438, null) == p:
		m[0x438] = 0
	set_phase(m, 0)                                       # FUN_005942e0(0)
	ball[0x64] = 1 if abs(Pm98Trig._i32(anchor + px)) > 0x1e0000 else 0


## The unowned-ball keeper arm: when the player is FACING the goal (the goal-direction angle is within
## 0x3554 of the player's facing +0x34), bump the keeper-attention counter player[0x184]+0x2e4. The rest
## of the arm is commentary-only (display gated headless), so nothing else is reproduced.
static func _postshot_keeper(p: Dictionary, m: Dictionary, px: int, py: int) -> void:
	var goalx := _si(m, 0x1820)
	if (_g(m, 0x19a0) & 1) == (1 - _g(p, 0x2b8)):
		goalx = Pm98Trig._i32(-goalx)
	var ang := Pm98Trig.atan_angle(Pm98Trig._i32(goalx - px), Pm98Trig._i32(-py))
	if abs(Pm98Trig._s16(ang - _g(p, 0x34))) <= 0x3554:
		var p184 := _ref(p, 0x184)
		p184[0x2e4] = _g(p184, 0x2e4) + 1


## The owned-ball classification ladder. Headless, every arm is commentary-only EXCEPT the innermost
## 004ea9f0 arm, which first draws one rng (the seed advances whether or not the roll picks commentary).
## Reached only when the velocity/distance gates pass AND mag <= 0x7ffff AND sign(px) != sign(anchor).
static func _postshot_classify_draw(p: Dictionary, px: int, py: int, anchor: int, rng) -> void:
	var vy := _si(p, 0x8)
	var ty := _si(p, 0xa4)
	if not (_sign1(vy) == _sign1(ty) or abs(vy) < 0xf0001 or abs(ty) < 0xf0001):
		return
	var a0 := _si(p, 0xa0)
	var s := _sign1(anchor)
	if Pm98Trig._i32((a0 - px) * s) >= 0x190001:
		return
	if not (Pm98Trig._i32((px - a0) * s) < 0x140001 or abs(Pm98Trig._i32(a0 + anchor)) > 0x1dffff):
		return
	var mag := Pm98Trig.planar_mag(Pm98Trig._i32(a0 - px), Pm98Trig._i32(ty - vy))
	if mag <= 0x7ffff and _sign1(px) != _sign1(anchor):
		if rng != null:
			rng.next()


## FUN_0058eca0 with this=ball, target=player (the post-shot tail's "engage the ball to the toucher").
## ball+0x1d4 is the match. When the engagement target changes: record it at ball+0x40, clear ball+0x4c,
## bump match+0x458 iff the cached team tag (ball+0x54) changed, copy the team into ball+0x54, latch
## ball+0x44/+0x48 to the player, zero the player's +0x54/+0x58, bump ball+0x80, and -- in open play
## (match+0x448 == 0) with a live set-piece taker (match+0x460 != 0) that is NOT this player -- clear
## that stale taker (match+0x460 = 0, match+0x43c = 0). This is the ref-model twin of set_engagement.
static func _ball_engage_player(ball: Dictionary, target: Dictionary) -> void:
	if is_same(ball.get(0x40, null), target):   # ball+0x40 may be int 0 (FUN_0058ed70 clears it); the
		return                                   # binary's pointer compare -> reference identity
	ball[0x40] = target
	ball[0x4c] = 0
	var m := _ref(ball, 0x1d4)
	var tteam := _g(target, 0x2b8)
	m[0x458] = _g(m, 0x458) + (1 if _g(ball, 0x54) != tteam else 0)
	ball[0x54] = tteam
	ball[0x48] = target
	ball[0x44] = target
	target[0x58] = 0
	target[0x54] = 0
	ball[0x80] = _g(ball, 0x80) + 1
	if _g(m, 0x448) == 0 and _g(m, 0x460) != 0 and m.get(0x43c, null) != target:
		m[0x460] = 0
		m[0x43c] = 0


# ---- FUN_005ac1a0 : the SHOT / TRAJECTORY SETUP (oracle: run_shotsetup_oracle.sh) --------------------
# The open-play engine runs this to launch the ball (case-0x13 shot etc.). It builds, from the player's
# skill (+0x394 owned / +0x3a0 unowned, all as 100-rating = iVar21), the aim target (player+0xa0/a4/a8)
# and the ball position (ball+4/8/c): a horizontal REACH (the 3D ball->aim distance jittered by a
# skill-scaled random factor near 1.0), a launch PITCH (local_28) and a horizontal DIRECTION (local_20,
# = atan(aim-ball) +/- a skill spread). It then writes the predicted landing spot (ball+0x84/88/8c =
# ball.pos + polar(mag_land, dir)) and the launch velocity (ball+0x20/24/28), runs the post-shot
# resolution (FUN_005ab5a0 = resolve_post_shot), bumps ball+0x70 to >= 4 and clears player+0x54/0x58.
# Headless: there is no display state here, so the port is the full SIM residue. Every fixed-point op,
# RNG draw (FUN_005ec250) and MulDiv is the binary's. Oracle-pinned bit-for-bit (the landing, the
# velocity, ball+0x70 and the RNG draw count) by run_shotsetup_oracle.sh -> specs/shotsetup_oracle.txt.

## FUN_005ec250 random scaled by n: the binary's `(rng * n) >> 15` with the >= 0x8000 overflow-avoiding
## split (round0(n/256) * rng round0(/128)) for large n. round0 == truncate-toward-zero (rng, n >= 0).
static func _shot_rng_scale(r: int, n: int) -> int:
	if n < 0x8000:
		return Pm98Trig._tdiv(r * n, 0x8000)
	return Pm98Trig._tdiv(Pm98Trig._tdiv(n, 0x100) * r, 0x80)


## FUN_0058f100 (__thiscall ball): the early ball-engage copy guard. Returns ball+0x63 (the AL the
## caller tests). Side effect: when ball+0x63 != 0 AND match+0x448 == 0, copy the engaged player's
## position (ball+0x40 -> +4/8/c) into ball+0x90/94/98. Only invoked when the shooter is NOT the
## ball's engaged player (the && short-circuit), so the copy reflects a hand-off.
static func _shot_engage_guard(ball: Dictionary, m: Dictionary) -> int:
	var flag := _g(ball, 0x63)
	if flag != 0 and _g(m, 0x448) == 0:
		var eng: Variant = ball.get(0x40, null)
		if eng is Dictionary:
			ball[0x90] = _g(eng, 0x4)
			ball[0x94] = _g(eng, 0x8)
			ball[0x98] = _g(eng, 0xc)
	return flag


## FUN_005ac1a0 (__fastcall this=player). Mutates ball (landing ball+0x84/88/8c, velocity ball+0x20/24/28,
## ball+0x70) and clears player+0x54/0x58. `teammates`/`rng` are forwarded to resolve_post_shot (the tail
## FUN_005ab5a0). Pass call_resolve=false to run ONLY this function's residue (the oracle stubs
## FUN_005ab5a0; resolve_post_shot is verified separately and never overwrites our ball writes).
static func setup_shot(p: Dictionary, teammates: Array = [], rng = null, call_resolve: bool = true) -> void:
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)

	# Entry guard: a non-engaged shooter with ball+0x63 set hands off (copy) and bails. ball+0x40 is a
	# pointer field (a player Dict ref, or int 0 when unengaged); `int != Dictionary` throws in GDScript,
	# so compare by reference identity (is_same) -- the binary's pointer compare.
	if not is_same(ball.get(0x40, null), p) and _shot_engage_guard(ball, m) != 0:
		p[0x54] = 0
		p[0x58] = 0
		return

	var anchor := _si(p, 0x3a4)
	var action := _g(p, 0x40)
	var goalx := _si(m, 0x1820)
	var aim := [_si(p, 0xa0), _si(p, 0xa4), _si(p, 0xa8)]
	var dx := Pm98Trig._i32(int(aim[0]) - _si(ball, 0x4))     # aim - ball.pos (the shot vector)
	var dy := Pm98Trig._i32(int(aim[1]) - _si(ball, 0x8))
	var dz := Pm98Trig._i32(int(aim[2]) - _si(ball, 0xc))

	# aim_goal: the aim point is inside the goal box on the side opposite the player's anchor.
	var aim_goal: bool = _ps_goalbox(p, aim) and _sign1(int(aim[0])) != _sign1(anchor)

	# local_20 cap (drives the C-condition below). m+0x44c==4 forces 0x500000.
	var cap: int
	if _g(m, 0x44c) == 4:
		cap = 0x500000
	elif aim_goal:
		cap = 0x500000
	elif action == 0x13 or action == 0x37:
		cap = 0x140000
	else:
		cap = 0x260000

	var owner: Variant = ball.get(0x4c, null)
	var unowned: bool = not (owner is Dictionary)

	# iVar21 = 100 - skill (owned uses +0x394, unowned +0x3a0); m+0x44c==6 thirds it.
	var iv21 := 100 - (_si(p, 0x3a0) if unowned else _si(p, 0x394))
	if _g(m, 0x44c) == 6:
		iv21 = Pm98Trig._tdiv(iv21, 3)

	# touch = max(4, unowned ? player+0x54 : player+0x58)  (the early local_24 / local_18).
	var touch := _si(p, 0x54) if unowned else _si(p, 0x58)
	if touch < 4:
		touch = 4

	# reach = 3D ball->aim distance * a skill-jittered factor near 1.0 (16.16).
	var hr := Pm98Trig._tdiv((0x9999 if unowned else 0x6666) * iv21, 100)
	var rnd0 := _shot_rng_scale(rng.next(), 2 * hr + 1)
	var pw := (rnd0 - hr) + 0x10000
	var dist := int(sqrt(float(dx * dx + dy * dy + dz * dz)))   # ftol(fsqrt), truncate
	var reach := Pm98Trig.mul16(dist, pw)

	# bVar2: a "weak/short" shot flag -- only for non-special shots (cVar4 == 0) whose reach is short.
	var cvar4 := _g(p, 0x5e) & 0xff
	var bvar2 := false
	if cvar4 == 0:
		bvar2 = reach < (rng.next() * 10 + 0xf0000)

	# power (local_24). C = cVar4==0 OR (owned AND reach >= cap).
	var power: int
	if cvar4 == 0 or (not unowned and reach >= cap):
		if bvar2:
			power = reach
		else:
			var xden := Pm98Trig._tdiv((0x10 - touch) * 0x3851, 0x10) + 0x175c2
			power = Pm98Trig.ratio16(reach, xden)
	else:
		var half := 0x20000 if aim_goal else 0
		power = Pm98Trig._i32(reach + _shot_rng_scale(rng.next(), half))

	# local_20 = atan(aim-ball horizontal) +/- a skill spread.
	var base_ang := Pm98Trig.atan_angle(dx, dy)
	var iv14 := Pm98Trig._tdiv(Pm98Trig._s16((0x160c if unowned else 0) + 0x2d8) * iv21, 100)
	var local_20 := Pm98Trig._i32((base_ang - iv14) + _shot_rng_scale(rng.next(), 2 * iv14 + 1))

	# local_28 = launch pitch.
	var local_28: int
	if cvar4 != 0:
		var sv23: int
		if unowned:
			var t58 := _si(p, 0x58)
			if t58 < 2:
				t58 = 2
			sv23 = (t58 + 1) * 0x16c
		else:
			sv23 = 0x1e94
		var iv14b := Pm98Trig._tdiv(Pm98Trig._s16((0x889 if unowned else 0) + 0x5b0) * iv21, 100)
		var sv22 := _shot_rng_scale(rng.next(), 2 * iv14b + 1)
		var fac3 := Pm98Trig._s16((0xf555 if unowned else 0) + 0xe39)
		var md3 := _muldiv(reach, fac3, 0x500000)
		local_28 = ((sv23 - iv14b) + sv22) - md3
	else:
		if bvar2:
			local_28 = 0x271c
		else:
			var sv23b := 0 if unowned else _muldiv(reach - 0xb0000, 0x5b0, 0x500000)
			var iv14c := Pm98Trig._tdiv(iv21 * 0x4fa, 100)
			var sv22b := _shot_rng_scale(rng.next(), 2 * iv14c + 1)
			var pitch_atan := Pm98Trig.atan_angle(reach, dz)   # atan(reach, aim.z - ball.z)
			local_28 = ((pitch_atan + 0x71c) + sv22b) + (sv23b - iv14c)

	# Unowned-only adjustments (two rng-gated bumps) + the local_28 clamps.
	if unowned:
		if ((rng.next() * 1000) >> 15) < iv21 * 6:
			var v := Pm98Trig._tdiv(iv21 * 0x11c7, 100) + 0x71c
			local_28 += _shot_rng_scale(rng.next(), v)
		if ((rng.next() * 1000) >> 15) < iv21 * 6:
			var v2 := Pm98Trig._tdiv(iv21 * 0x11c7, 100) + 0xaab
			local_20 += _shot_rng_scale(rng.next(), 2 * v2 + 1) - v2
		if Pm98Trig._s16(local_28) <= 0x16c:
			local_28 = 0x16c
		if power < 0xf0000:
			if Pm98Trig._s16(local_28) > 0x1dde:
				local_28 = 0x1dde
		elif power < 0x140000:
			if Pm98Trig._s16(local_28) > 0x216c:
				local_28 = 0x216c
		elif Pm98Trig._s16(local_28) > 0x238e:
			local_28 = 0x238e

	# Late goalbox bump: a special shot taken from inside the own-side goal box (not a 0x37 action).
	if _g(p, 0x2bc) == 0:
		var ppos := [_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)]
		if _ps_goalbox(p, ppos) and _sign1(int(ppos[0])) == _sign1(anchor) \
				and cvar4 != 0 and action != 0x37:
			local_28 += 0x222 + Pm98Trig._tdiv(rng.next() * 0x38e, 0x8000)

	# ---- emit landing + velocity ----
	var sin_p := Pm98Trig.sin_a(local_28)
	var cos_p := Pm98Trig.cos_a(local_28)
	var r1 := Pm98Trig.muladd16(Pm98Trig._i32(_si(ball, 0xc) - int(aim[2])), cos_p, power, sin_p)
	var l14 := Pm98Trig.mul16(2 * cos_p, r1)
	if l14 < 0x28f:
		l14 = 0x28f
	var vterm := Pm98Trig.fixmul3(power, power, 0xb2)
	# FILD vterm / FIDIV l14 / FSQRT / FMUL 65536 / ftol(TRUNCATE). MSVC runs the x87 at PC=53, so the
	# 64-bit double sequence reproduces it; int() truncates toward zero like _ftol (NOT round-nearest).
	var tof := int(sqrt(float(vterm) / float(l14)) * 65536.0)

	# landing ball+0x84/88/8c = ball.pos + polar(mag_land, local_20).
	var mag_land := Pm98Trig._tdiv(rng.next() * 0xb3, 0x80) + reach - 0x5999
	var out_land := Pm98Trig.polar_vec(mag_land, local_20)
	ball[0x84] = Pm98Trig._i32(int(out_land[0]) + _si(ball, 0x4))
	ball[0x88] = Pm98Trig._i32(int(out_land[1]) + _si(ball, 0x8))
	ball[0x8c] = Pm98Trig._i32(int(out_land[2]) + _si(ball, 0xc))

	# tof clamp: tof = min(tof, round0((MulDiv(0x9999, power-rating, 15000) + 0x13332 + MulDiv(...))/4)).
	var thr := Pm98Trig._tdiv(_muldiv(0x9999, _si(p, 0x70), 15000) + 0x13332 + _muldiv(0x9999, 100 - iv21, 100), 4)
	if thr <= tof:
		tof = thr

	# velocity ball+0x20/24/28 (horizontal uses cos, vertical uses sin).
	if bvar2:
		var ov := Pm98Trig.polar_vec(Pm98Trig.mul16(cos_p, 2 * tof), local_20)
		ball[0x20] = int(ov[0])
		ball[0x24] = int(ov[1])
		ball[0x28] = int(ov[2])
	else:
		var ov2 := Pm98Trig.polar_vec(Pm98Trig.mul16(cos_p, tof), local_20)
		ball[0x20] = int(ov2[0])
		ball[0x24] = int(ov2[1])
		ball[0x28] = Pm98Trig.mul16(sin_p, tof)

	if call_resolve:
		resolve_post_shot(p, teammates, rng)              # FUN_005ab5a0 tail

	var b70 := _g(ball, 0x70)
	ball[0x70] = b70 if b70 > 4 else 4
	p[0x54] = 0
	p[0x58] = 0


# ---- Kick-resolution action handlers (FUN_005adfc0 / 005ae4c0 / 005ae910) -----------------------
# The three "launch the ball toward goal" open-play action handlers (engine_tick cases 0x19/0x1a,
# 0x14/0x16, 0x15). Each computes a launch SPEED (ball-velocity magnitude / div + a touch term), an aim
# YAW chosen between the two goalposts and jittered by the player's accuracy (+0x39c), and a launch
# PITCH jittered by power (+0x388); rotates the {speed,0,0} vector by pitch (about Y) then yaw (about Z)
# and writes it as the ball velocity (ball+0x20/24/28); then resets +0x54/58, ball+0x4c, bumps
# ball+0x70>=4, sets match+0x462|=flag and (FUN_005ab5a0) resolves the post-shot. The three differ ONLY
# in constants (the KICK_* cfgs). Oracle-pinned bit-for-bit by tools/re/run_adfc0_oracle.sh (etc.) ->
# specs/adfc0_oracle.txt, locked in test_adfc0.gd. The decompile DROPPED the lost-FPU ftol (= the ball
# SPEED sqrt) and mislabelled the rotate -> velocity write as a direct store; recovered from the disasm.
#
# cfg keys: g2c/g30 self-guard (player+0x2c/+0x30); sdiv ball-speed divisor (iVar10/sdiv); tmul touch
# term mul ((touch+0x10)*tmul, /0x20); pconst power-spread const; pbias launch-pitch bias; flag the
# match+0x462 OR-bit; ypre facing pre-rotate (ae910 rotates geometry by +0xb4); addv add player velocity
# to ball position (ae910 follow-through); set64 set ball+0x64=1 after resolve (ae4c0/ae910).
const KICK_ADFC0 := {"g2c": 4, "g30": 3, "sdiv": 0x18, "tmul": 0x6147, "pconst": 0x71c,
	"pbias": 0x71c, "flag": 0x20, "ypre": 0, "addv": false, "set64": false}
const KICK_AE4C0 := {"g2c": 8, "g30": 0, "sdiv": 0x20, "tmul": 0x5999, "pconst": 0x666,
	"pbias": -0x222, "flag": 0x40, "ypre": 0, "addv": false, "set64": true}
const KICK_AE910 := {"g2c": 5, "g30": 0, "sdiv": 0x18, "tmul": 0x5999, "pconst": 0x38e,
	"pbias": 0x16c, "flag": 0x20, "ypre": 0xb4, "addv": true, "set64": true}

const _KICK_POST := 0x39999     # half goal-mouth width: the +/- post offset on the goal-line y


## The signed-16 skill at player+0xb8 + idx*2 (idx = tm0+0x2b8 * 0xb + tm0+0x2c4). The oracle pins
## idx == 0 (the packed-short skill table needs a sub-word model when wired live); reads +0xb8's low 16.
static func _kick_skill16(p: Dictionary, tm0: Dictionary) -> int:
	var idx := _g(tm0, 0x2b8) * 0xb + _g(tm0, 0x2c4)
	return Pm98Trig._s16(_g(p, 0xb8 + (idx * 2 if idx != 0 else 0)))


## FUN_005adfc0 / FUN_005ae4c0 / FUN_005ae910. Mutates ball + player + match. `cfg` selects the variant.
## Pass call_resolve=false to skip the FUN_005ab5a0 tail (the oracle stubs it; the velocity is verified
## here, the post-shot residue separately).
static func kick_resolve(p: Dictionary, rng, cfg: Dictionary, call_resolve: bool = true) -> void:
	if _g(p, 0x2c) != int(cfg["g2c"]) or _g(p, 0x30) != int(cfg["g30"]):
		return
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)
	if _g(p, 0x7c) != _g(ball, 0x80):
		return
	if _shot_engage_guard(ball, m) != 0:                     # FUN_0058f100: ball+0x63 set -> bail
		return

	# ae910 rotates the whole goal geometry by +0xb4 (un-done at the end; +0x34 is not a tracked output).
	var facing := Pm98Trig._s16(_g(p, 0x34) + int(cfg["ypre"]))

	# --- launch speed (pre-rotation magnitude): ball-velocity 3D mag / sdiv + a touch term / 0x20 ---
	var spd := Pm98Trig._dist3(_si(ball, 0x20), _si(ball, 0x24), _si(ball, 0x28))
	var touch := _si(p, 0x54)
	if touch < 5:
		touch = 4
	var ivar3 := (touch + 0x10) * int(cfg["tmul"])
	var mag := Pm98Trig._tdiv(spd, int(cfg["sdiv"])) + Pm98Trig._tdiv(ivar3, 0x20)

	# --- aim yaw: angle to a goalpost (jittered by accuracy +0x39c) ---
	var goalx := _si(m, 0x1820)
	if (1 - _g(p, 0x2b8)) == (_g(m, 0x19a0) & 1):            # own-vs-attacking goal side -> negate x
		goalx = -goalx
	var px := _si(p, 0x4)
	var py := _si(p, 0x8)
	# center + the two posts on the goal line; the angle FROM the player, minus facing (signed-16).
	var s_center := Pm98Trig._s16(Pm98Trig.atan_angle(Pm98Trig._i32(goalx - px), Pm98Trig._i32(-py)) - facing)
	var s_post1 := Pm98Trig._s16(Pm98Trig.atan_angle(Pm98Trig._i32(goalx - px), Pm98Trig._i32(_KICK_POST - py)) - facing)
	var s_post2 := Pm98Trig._s16(Pm98Trig.atan_angle(Pm98Trig._i32(goalx - px), Pm98Trig._i32(-_KICK_POST - py)) - facing)
	ball[0x80] = Pm98Trig._i32(_g(ball, 0x80) + 1)           # decompile L57: claim the touch (ball+0x80++)
	var tmarr: Variant = p.get(0x188, null)
	var tm0: Dictionary = (tmarr[0] if tmarr is Array and not (tmarr as Array).is_empty() else {})
	var skill := _kick_skill16(p, tm0)
	var mn := s_post1
	var mx := s_post2
	if s_post2 < s_post1:
		mn = s_post2
		mx = s_post1
	var base_ang := Pm98Trig._s16((mx if skill < s_center else mn) - s_center)
	var spread_geo := Pm98Trig._tdiv(base_ang * 2, 3)

	var acc := _si(p, 0x39c)
	var iv15 := Pm98Trig._tdiv((100 - acc) * 0x1555, 100)
	var rng_a := _shot_rng_scale(rng.next(), 2 * iv15 + 1)   # rng draw #1 (accuracy spread)
	var yaw := Pm98Trig._s16(s_center + spread_geo + (rng_a - iv15) + facing)

	# --- launch pitch: power spread (rng draw #2) ---
	var pwr := _si(p, 0x388)
	var iv16b := Pm98Trig._tdiv((100 - pwr) * int(cfg["pconst"]), 100)
	var pitch := _shot_rng_scale(rng.next(), iv16b) + int(cfg["pbias"])

	# --- rotate {mag,0,0} by pitch (about Y) then yaw (about Z) -> ball velocity ---
	var vel := [mag, 0, 0]
	vel = Pm98Trig.rot_vec3(vel, pitch, 1)
	vel = Pm98Trig.rot_vec3(vel, yaw, 0)
	ball[0x20] = Pm98Trig._i32(int(vel[0]))
	ball[0x24] = Pm98Trig._i32(int(vel[1]))
	ball[0x28] = Pm98Trig._i32(int(vel[2]))

	if cfg["addv"]:                                          # ae910: nudge ball pos by the player's velocity
		ball[0x4] = Pm98Trig._i32(_si(ball, 0x4) + _si(p, 0x20))
		ball[0x8] = Pm98Trig._i32(_si(ball, 0x8) + _si(p, 0x24))
		ball[0xc] = Pm98Trig._i32(_si(ball, 0xc) + _si(p, 0x28))

	var kb70 := _si(ball, 0x70)
	ball[0x70] = kb70 if kb70 > 4 else 4
	m[0x462] = _g(m, 0x462) | int(cfg["flag"])
	p[0x54] = 0
	p[0x58] = 0
	ball[0x4c] = 0
	if call_resolve:
		resolve_post_shot(p, _ref(p, 0x184).get(0, []), rng)  # gs[0] roster (binary reads it from player+0x184)
	if cfg["set64"]:
		ball[0x64] = 1


# ---- AI lay-off / feed action handlers (Family A: FUN_005ad970 / 005adc60 / 005acc40) -----------
# The three "AI passes / lays the ball off to a teammate" open-play handlers; each ENDS by calling
# FUN_005ac1a0 (= setup_shot) once it has chosen an aim point (player+0xa0/a4/a8). FUN_005ad970 (case
# 0x36) is ported here. It clears ball+0x63 and sets player+0x5e=1; then UNLESS the set-piece predicate
# holds (gs+0x2ee && play_state==0 && player+0x5c) it re-rolls the touch/power (player+0x58 =
# rng*4/0x8000+0xc, player+0x54 = rng*3/0x8000+0xd) and biases the facing player+0x34 toward/away from
# the WORST-rated teammate at its pitch position (the per-position skill table player+0xe4[idx]). Then it
# casts a corridor from the (temporarily forward-displaced) player along the facing and asks FUN_005b1100
# for the nearest teammate in that corridor: a hit -> aim = that teammate's pos + ball+0x4c repointed to
# it; a miss -> a blind polar throw (one extra rng draw). Oracle-pinned bit-for-bit by
# tools/re/run_ad970_oracle.sh -> specs/ad970_oracle.txt (FUN_005ac1a0 + FUN_005943b0 stubbed, like the
# kick handlers stub FUN_005ab5a0); the corridor leaf FUN_005b1100/005b0e90 runs REAL under the emu.

## FUN_005b0e90 (__thiscall this=candidate; self_pos, angle, scale, dist): the perpendicular distance of
## `cand_pos` from the ray cast from `self_pos` along `angle`, but ONLY inside a corridor. Returns
## 0xc80000 ("infinitely far", the no-hit sentinel) when the candidate is outside the abs(.)<scale/2+dist
## L-inf box about the corridor midpoint, OR its along-ray projection is <0 or >scale. Otherwise the true
## perpendicular |unit_dir x D| (D = candidate-self) via the FP sqrt + ftol (truncate-toward-zero). The
## mid offset and unit dir are polar(scale/2, angle) and polar(1.0, angle) = FUN_005ee0f0; the projection
## is dot16 (FUN_005ee500) and the perpendicular is |cross16| (FUN_005ee540) magnitude.
static func _seg_corridor_dist(cand_pos: Array, self_pos: Array, angle: int, scale: int, dist: int) -> int:
	var unit := Pm98Trig.polar_vec(0x10000, angle)             # FUN_005ee0f0(1.0, angle)
	var half_s := Pm98Trig._tdiv(scale, 2)                     # scale/2, truncate toward zero
	var mid := Pm98Trig.polar_vec(half_s, angle)              # FUN_005ee0f0(scale/2, angle)
	var ext := half_s + dist                                  # corridor L-inf half-extent
	# box test about (self_pos + mid); each subtraction wraps to int32 like the binary's two SUBs.
	var bx: int = abs(Pm98Trig._i32(Pm98Trig._i32(int(cand_pos[0]) - int(mid[0])) - int(self_pos[0])))
	var by: int = abs(Pm98Trig._i32(Pm98Trig._i32(int(cand_pos[1]) - int(mid[1])) - int(self_pos[1])))
	var bz: int = abs(Pm98Trig._i32(Pm98Trig._i32(int(cand_pos[2]) - int(mid[2])) - int(self_pos[2])))
	if bx < ext and by < ext and bz < ext:
		var d := [Pm98Trig._i32(int(cand_pos[0]) - int(self_pos[0])),
			Pm98Trig._i32(int(cand_pos[1]) - int(self_pos[1])),
			Pm98Trig._i32(int(cand_pos[2]) - int(self_pos[2]))]
		var proj := _dot3_16(unit, d)                         # FUN_005ee500(unit, D) -- along-ray
		if proj >= 0 and proj <= scale:
			var cr: Array = Pm98Trig.cross16(unit, d)         # FUN_005ee540(unit, out, D)
			return int(sqrt(float(cr[0] * cr[0] + cr[1] * cr[1] + cr[2] * cr[2])))  # |perp|, ftol-truncated
	return 0xc80000


## FUN_005b1100 (__thiscall this=player; roster, angle, scale, dist): scan `roster` (the gs player list)
## for the teammate (NOT self, with +0x2bc != 0) of MINIMUM _seg_corridor_dist along the facing ray.
## Returns that teammate Dict, or null if none qualifies. null roster entries are skipped (the +0x2bc gate).
static func _corridor_nearest(self_p: Dictionary, roster: Array, angle: int, scale: int, dist: int) -> Variant:
	var self_pos := [_si(self_p, 0x4), _si(self_p, 0x8), _si(self_p, 0xc)]
	var best: Variant = null
	var best_d := 0xc80000
	for cand in roster:
		if not (cand is Dictionary):
			continue
		if _g(cand, 0x2bc) == 0 or cand == self_p:
			continue
		var d := _seg_corridor_dist([_si(cand, 0x4), _si(cand, 0x8), _si(cand, 0xc)], self_pos, angle, scale, dist)
		if d < best_d:
			best_d = d
			best = cand
	return best


## FUN_005ad970 (__fastcall this=player), case 0x36: the AI lay-off / short-feed handler. Mutates ball
## (+0x63=0, +0x4c) and player (+0x5e=1, +0x54/58, +0x34, +0xa0/a4/a8 aim) and ends with setup_shot. The
## player position +4/8/c is displaced forward by a polar step for the corridor scan then RESTORED (net
## zero). Pass call_setup=false to skip the FUN_005ac1a0 tail (the oracle stubs it; the residue verified
## here is ball+0x63/4c, player+0x5e/54/58/34/aim and the rng seed).
static func feed_layoff_036(p: Dictionary, rng, call_setup: bool = true) -> void:
	if _g(p, 0x2c) != 0x13 or _g(p, 0x30) != 0:
		return
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)
	var gs := _ref(p, 0x184)
	ball[0x63] = 0
	p[0x5e] = 1

	# set-piece predicate: gs+0x2ee set AND play-state 0 (FUN_005943b0) AND player+0x5c.
	var special: bool = _g(gs, 0x2ee) != 0 and _phase0(m) and _g(p, 0x5c) != 0
	if special:
		p[0x58] = Pm98Trig._tdiv(_si(p, 0x58), 2) + 8
	else:
		p[0x58] = _shot_rng_scale(rng.next(), 4) + 0xc        # rng draw #1
		p[0x54] = _shot_rng_scale(rng.next(), 3) + 0xd        # rng draw #2
		# Worst-rated teammate at its pitch position (MIN of self's per-position table player+0xe4[idx]).
		var roster1: Array = p.get(0x188, [])
		var worst: Variant = null
		var worst_skill := 0x3e80000
		for cand in roster1:
			var skill: int
			if cand is Dictionary:
				var cd: Dictionary = cand
				var ci := _g(cd, 0x2b8) * 0xb + _g(cd, 0x2c4)
				skill = _si(p, 0xe4 + ci * 4)
			else:
				skill = 0xc80000
			if skill < worst_skill:
				worst_skill = skill
				worst = cand
		if worst is Dictionary:
			var wd: Dictionary = worst
			var wi := _g(wd, 0x2b8) * 0xb + _g(wd, 0x2c4)
			var sk16 := Pm98Trig._s16(_g(p, 0xb8 + wi * 2))
			if sk16 < 1:                                       # CMP word, JLE 0 -> the +0x222 bias
				p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (_shot_rng_scale(rng.next(), 0x222) + 0x222))
			else:                                              # the -0x222 bias
				p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (-0x222 - _shot_rng_scale(rng.next(), 0x222)))

	# ---- corridor scan from the forward-displaced player position ----
	var facing := _g(p, 0x34)
	var mag := Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0x120000), 0x10) + 0x120000
	var disp := Pm98Trig.polar_vec(mag, facing)
	p[0x4] = Pm98Trig._i32(_si(p, 0x4) + int(disp[0]))
	p[0x8] = Pm98Trig._i32(_si(p, 0x8) + int(disp[1]))
	p[0xc] = Pm98Trig._i32(_si(p, 0xc) + int(disp[2]))
	var groster: Array = gs.get(0, [])
	var hit: Variant = _corridor_nearest(p, groster, facing, 0x1e0000, 0xa0000)
	p[0x4] = Pm98Trig._i32(_si(p, 0x4) - int(disp[0]))
	p[0x8] = Pm98Trig._i32(_si(p, 0x8) - int(disp[1]))
	p[0xc] = Pm98Trig._i32(_si(p, 0xc) - int(disp[2]))

	if hit is Dictionary:
		var hd: Dictionary = hit
		p[0xa0] = _g(hd, 0x4)
		p[0xa4] = _g(hd, 0x8)
		p[0xa8] = _g(hd, 0xc)
		ball[0x4c] = hd
		if call_setup:
			setup_shot(p, gs.get(0, []), rng)
		return

	# no corridor teammate: a blind polar throw (one extra rng draw).
	var mag2 := Pm98Trig._tdiv(rng.next() * 0xa00, 0x80) + Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0xe0000), 0x10) + 0x120000
	var disp2 := Pm98Trig.polar_vec(mag2, facing)
	p[0xa0] = Pm98Trig._i32(_si(p, 0x4) + int(disp2[0]))
	p[0xa4] = Pm98Trig._i32(_si(p, 0x8) + int(disp2[1]))
	p[0xa8] = Pm98Trig._i32(_si(p, 0xc) + int(disp2[2]))
	if call_setup:
		setup_shot(p, gs.get(0, []), rng)


## FUN_005b3580 (__thiscall this=cand; &cand.x): 1 iff sign(cand.x) == sign(cand+0x3a4) -- the
## candidate already stands on the same side as the goal it attacks. +0x3a4 is the player's
## attacking-goal x anchor (signed). The loose-ball search uses it as the mode-1 reject gate.
static func _loose_dir_match(cand: Dictionary) -> bool:
	return _sign1(_si(cand, 0x3a4)) == _sign1(_si(cand, 0x4))


## FUN_005b3c10 (__thiscall this=player; lo, mid, hi): a zone-dependent percentage roll. The threshold
## (per-mille) is `lo` when gs+0x30c==0, `mid` when ==2, else `hi` (gs = player+0x184, +0x30c a
## phase/zone field). Returns true w.p. threshold/1000 via the rand()*1000>>15 idiom -- ONE rng draw.
static func _loose_chance(p: Dictionary, lo: int, mid: int, hi: int, rng) -> bool:
	var zone := _g(_ref(p, 0x184), 0x30c)
	var thr: int = lo if zone == 0 else (mid if zone == 2 else hi)
	return rng.chance_permil(thr)


## FUN_005b31a0 (__thiscall this=player; mode), RET 0x8: the loose-ball / open-man search. Scans the gs
## roster (gs[0], gs = player+0x184) for the best teammate to receive, scoring each by a heading-spread
## metric, and returns that teammate Dict (or null if the best score < 0x71c). Per active non-self
## candidate it applies: a distance gate `ag(player) < ag(cand)+0x60000` (else a zone chance roll
## _loose_chance, ONE rng draw); the mode gate (1 = reject candidates already in their attacking half
## via _loose_dir_match; 2 = require ag(cand) >= ag(player)-0x40000; 3 = require ag(cand) >=
## ag(player)+0x30000; 0 = none); a skill gate cand_skill > 0x40000 (cand_skill = self table
## player+0xe4[idx], idx = cand+0x2b8*0xb + cand+0x2c4). Then an inner scan over player+0x188 finds the
## minimum heading difference `ivar9` (init 0x7c72) to teammates with skill < cand_skill+0x18000, and
## score = ivar9*100 / ((abs(cand_skill-0x80000)*100/30 >> 16) + 100), halved when cand's heading short16
## >= 0x71c7 or *2/3 when >= 0x471c. ag(pl) = abs(pl.x - pl+0x3a4). Reused by adc60 (mode 0) and ad010.
static func loose_ball_search(p: Dictionary, mode: int, rng) -> Variant:
	var roster: Array = _ref(p, 0x184).get(0, [])     # gs[0]
	var inner: Array = p.get(0x188, [])               # player+0x188 inner roster
	var p_ag: int = abs(Pm98Trig._i32(_si(p, 0x4) - _si(p, 0x3a4)))
	var best_score := 0
	var best_cand: Variant = null
	for cand in roster:
		if not (cand is Dictionary):
			continue
		var cd: Dictionary = cand
		if _g(cd, 0x2bc) == 0 or cd == p:             # inactive slot / self
			continue
		var c_ag: int = abs(Pm98Trig._i32(_si(cd, 0x4) - _si(cd, 0x3a4)))
		# distance gate: pass if ag(player) < ag(cand)+0x60000, else the zone chance roll (1 rng draw).
		if not (p_ag < c_ag + 0x60000):
			if not _loose_chance(p, 0x64, 0x12c, 0x384, rng):
				continue
		if mode == 1 and _loose_dir_match(cd):
			continue
		if mode == 2 and c_ag < Pm98Trig._i32(p_ag - 0x40000):
			continue
		if mode == 3 and c_ag < Pm98Trig._i32(p_ag + 0x30000):
			continue
		var idx_c := _g(cd, 0x2b8) * 0xb + _g(cd, 0x2c4)
		var cand_skill := _si(p, 0xe4 + idx_c * 4)
		if cand_skill <= 0x40000:
			continue
		# inner heading-spread scan: minimise ivar9 over teammates with skill < cand_skill+0x18000.
		var thresh := Pm98Trig._i32(cand_skill + 0x18000)
		var thresh2 := Pm98Trig._i32(cand_skill - 0x80000)   # = thresh - 0x98000
		var ivar9 := 0x7c72
		var bp := Pm98Trig._s16(_g(p, 0xb8 + idx_c * 2))
		for c2 in inner:
			var idx2 := -1
			var skill2 := 0xc80000
			if c2 is Dictionary:
				idx2 = _g(c2, 0x2b8) * 0xb + _g(c2, 0x2c4)
				skill2 = _si(p, 0xe4 + idx2 * 4)
			if skill2 >= thresh:
				continue
			var h: int = 0
			if idx2 >= 0:
				h = abs(Pm98Trig._s16(Pm98Trig._s16(_g(p, 0xb8 + idx2 * 2)) - bp))
			if skill2 < 0x80000 and (h >> 1) < ivar9:
				ivar9 = h
				continue
			if skill2 <= thresh2:
				continue
			if h < ivar9:
				ivar9 = h
		# score the candidate (signed integer math, all operands non-negative here).
		var abs_s: int = abs(Pm98Trig._i32(cand_skill - 0x80000))
		var t30 := Pm98Trig._tdiv(abs_s * 100, 30)
		var divisor := Pm98Trig._asr(t30, 0x10) + 100
		var score := Pm98Trig._tdiv(ivar9 * 100, divisor)
		if bp >= 0x71c7:
			score = Pm98Trig._tdiv(score, 2)
		elif bp >= 0x471c:
			score = Pm98Trig._tdiv(score * 2, 3)
		if score > best_score:
			best_score = score
			best_cand = cd
	if best_score < 0x71c:
		return null
	return best_cand


## FUN_005adc60 (__fastcall this=player), case 0x37: the near-twin of feed_layoff_036. Clears ball+0x63,
## sets player+0x5e=0 (NOT 1). Unlike 0x36, the set-piece SPECIAL case does NOTHING in the top block --
## ONLY the non-special branch re-rolls touch/power, and it does so with FOUR rng draws: p58/p54 are
## rolled, then immediately RE-rolled (the first pair is overwritten but the rng IS consumed), then the
## worst-rated-teammate facing bias (same as 0x36, +1 draw if a worst teammate exists). The tail
## displaces the player forward by polar(p54*0xe0000>>4 + 0xe0000, facing) and asks for a corridor
## teammate, but the scan function depends on the set-piece predicate AGAIN: SPECIAL -> the corridor
## scan _corridor_nearest (FUN_005b1100); non-special -> the loose-ball search loose_ball_search
## (FUN_005b31a0, mode 0). Hit -> aim = teammate pos + ball+0x4c repointed; miss -> a blind polar throw
## (fallback mag p54*0x70000>>4 + 0xa0000 + rng*0xa00/0x80, +1 draw). Ends with setup_shot.
static func feed_layoff_037(p: Dictionary, rng, call_setup: bool = true) -> void:
	if _g(p, 0x2c) != 6 or _g(p, 0x30) != 0:
		return
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)
	var gs := _ref(p, 0x184)
	ball[0x63] = 0
	p[0x5e] = 0

	var special: bool = _g(gs, 0x2ee) != 0 and _phase0(m) and _g(p, 0x5c) != 0
	if not special:
		# FOUR rng draws: the first p58/p54 are immediately overwritten but DO advance the rng.
		p[0x58] = _shot_rng_scale(rng.next(), 2) + 6          # draw #1 (overwritten)
		p[0x54] = _shot_rng_scale(rng.next(), 3) + 0xd        # draw #2 (overwritten)
		p[0x58] = _shot_rng_scale(rng.next(), 4) + 0xc        # draw #3
		p[0x54] = _shot_rng_scale(rng.next(), 3) + 0xd        # draw #4
		# Worst-rated teammate facing bias (identical to feed_layoff_036).
		var roster1: Array = p.get(0x188, [])
		var worst: Variant = null
		var worst_skill := 0x3e80000
		for cand in roster1:
			var skill: int
			if cand is Dictionary:
				var cd: Dictionary = cand
				var ci := _g(cd, 0x2b8) * 0xb + _g(cd, 0x2c4)
				skill = _si(p, 0xe4 + ci * 4)
			else:
				skill = 0xc80000
			if skill < worst_skill:
				worst_skill = skill
				worst = cand
		if worst is Dictionary:
			var wd: Dictionary = worst
			var wi := _g(wd, 0x2b8) * 0xb + _g(wd, 0x2c4)
			var sk16 := Pm98Trig._s16(_g(p, 0xb8 + wi * 2))
			if sk16 < 1:
				p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (_shot_rng_scale(rng.next(), 0x222) + 0x222))
			else:
				p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (-0x222 - _shot_rng_scale(rng.next(), 0x222)))

	# ---- corridor scan from the forward-displaced player position ----
	var facing := _g(p, 0x34)
	var mag := Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0xe0000), 0x10) + 0xe0000
	var disp := Pm98Trig.polar_vec(mag, facing)
	p[0x4] = Pm98Trig._i32(_si(p, 0x4) + int(disp[0]))
	p[0x8] = Pm98Trig._i32(_si(p, 0x8) + int(disp[1]))
	p[0xc] = Pm98Trig._i32(_si(p, 0xc) + int(disp[2]))
	# the scan function is re-selected by the SAME set-piece predicate (special == top branch).
	var hit: Variant
	if special:
		hit = _corridor_nearest(p, gs.get(0, []), facing, 0x1e0000, 0xa0000)
	else:
		hit = loose_ball_search(p, 0, rng)
	p[0x4] = Pm98Trig._i32(_si(p, 0x4) - int(disp[0]))
	p[0x8] = Pm98Trig._i32(_si(p, 0x8) - int(disp[1]))
	p[0xc] = Pm98Trig._i32(_si(p, 0xc) - int(disp[2]))

	if hit is Dictionary:
		var hd: Dictionary = hit
		p[0xa0] = _g(hd, 0x4)
		p[0xa4] = _g(hd, 0x8)
		p[0xa8] = _g(hd, 0xc)
		ball[0x4c] = hd
		if call_setup:
			setup_shot(p, gs.get(0, []), rng)
		return

	# no corridor teammate: a blind polar throw (one extra rng draw).
	var mag2 := Pm98Trig._tdiv(rng.next() * 0xa00, 0x80) + Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0x70000), 0x10) + 0xa0000
	var disp2 := Pm98Trig.polar_vec(mag2, facing)
	p[0xa0] = Pm98Trig._i32(_si(p, 0x4) + int(disp2[0]))
	p[0xa4] = Pm98Trig._i32(_si(p, 0x8) + int(disp2[1]))
	p[0xa8] = Pm98Trig._i32(_si(p, 0xc) + int(disp2[2]))
	if call_setup:
		setup_shot(p, gs.get(0, []), rng)


## FUN_005acc40 (case 4/0x25, this=player, frame guard p+0x2c==4 && p+0x30==3): the AI "aim the set-piece
## feed AT the goal" handler -- the third Family-A member, but geometry-heavy, NOT a corridor/loose-ball
## scan. Aims at the ball+0x4c teammate's position (player+0xa0/a4/a8 = target.pos), then, on a special
## set-piece touch (gs+0x2ee && play_state==0 && p+0x5c) with the full power window (p+0x58==0x10, p+0x54),
## may FLAG a goal-mouth redirect (p+0x5f=1, p+0x58=4) UNLESS the player itself already sits in a
## byline-corner / goal-box region on the side OPPOSITE its goal anchor (FUN_0058fb50 goalbox /
## FUN_005ac0e0 corner) or match+0x44c==2. When p+0x5f is set (here or on entry) it bends the aim: it
## displaces the aim by polar(dist_to_aim/4, blended_angle) where dist_to_aim = planar_mag(aim - pos) and
## blended_angle = atan(goal - target.pos) rotated halfway toward the goal-facing axis (the +0x8000 side
## term); a long feed (dist > 0x1e0000) also sets ball+0x62=1. Finally it clamps the aim into the goal
## AABB shrunk 0x4ccc per face (match+0x1828..+0x183c) and, on the special touch, sets p+0x5e=(p+0x54!=0).
## Draws NO rng. Ends with FUN_005ac1a0 (= setup_shot). Oracle-pinned bit-for-bit by
## tools/re/run_acc40_oracle.sh -> specs/acc40_oracle.txt (FUN_005ac1a0 + FUN_005943b0 stubbed; the
## commentary FUN_00590f00 is gated out headless by match+0x180a==0). All vec leaves (FUN_00590aa0 set /
## 00590ae0 sub / 00590ac0 copy / 00590b10 add-scalar / 005b1210 sub-scalar / 00590be0 6-int copy) run
## REAL under the emu and are inlined here; the angle-blend's `target.facing - target.facing == 0` and the
## pointer-high CONCAT22 garbage (masked by MOVSX AX / polar's &0xfff) were recovered from the disasm.
static func goal_aim_025(p: Dictionary, rng, call_setup: bool = true) -> void:
	if _g(p, 0x2c) != 4 or _g(p, 0x30) != 3:
		return
	var ball := _ref(p, 0x190)
	var target_v: Variant = ball.get(0x4c, 0)
	if not (target_v is Dictionary):
		return
	var target: Dictionary = target_v
	var m := _ref(p, 0x18c)
	var gs := _ref(p, 0x184)
	ball[0x62] = 0
	# aim = target.pos (player+0xa0/a4/a8 = ball+0x4c teammate's +4/+8/+c)
	p[0xa0] = _g(target, 0x4)
	p[0xa4] = _g(target, 0x8)
	p[0xa8] = _g(target, 0xc)

	var special: bool = _g(gs, 0x2ee) != 0 and _phase0(m) and _g(p, 0x5c) != 0

	# special touch with full power window -> maybe flag the goal-mouth redirect.
	if special and _g(p, 0x58) == 0x10 and _g(p, 0x54) != 0:
		var anchor_sign := _sign1(_si(p, 0x3a4))
		var oppside := _sign1(_si(p, 0x4)) != anchor_sign
		var in_goalbox := _ps_goalbox(p, [_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)]) and oppside
		if not in_goalbox:
			var in_corner := _ps_corner(p, _si(p, 0x4), _si(p, 0x8)) and oppside
			if not in_corner and _g(m, 0x44c) != 2:
				p[0x5f] = 1
				p[0x58] = 4

	# redirect bend (fires when p+0x5f set here OR on entry).
	if _g(p, 0x5f) != 0:
		var dx := Pm98Trig._i32(_si(p, 0xa0) - _si(p, 0x4))
		var dy := Pm98Trig._i32(_si(p, 0xa4) - _si(p, 0x8))
		var mag := Pm98Trig.planar_mag(dx, dy)                     # FUN_00436fb0 + FUN_005edfb0
		var team := _g(p, 0x2b8)
		var orient := _g(m, 0x19a0) & 1
		var goalx := _si(m, 0x1820)                               # FUN_00590aa0([goalx,0,0])
		if orient == (1 - team):
			goalx = Pm98Trig._i32(-goalx)
		# local_18 = goalpos - target.pos (FUN_00590ae0); angle target -> goal.
		var gdx := Pm98Trig._i32(goalx - _si(target, 0x4))
		var gdy := Pm98Trig._i32(-_si(target, 0x8))
		var ang_base := Pm98Trig.atan_angle(gdx, gdy)
		# the facing term word[target+0x34] - word[target+0x34] == 0 (both deref ball+0x4c).
		var sign_term := 0x8000 if orient != team else 0
		var t := Pm98Trig._s16(sign_term - ang_base)
		var blended := ang_base + _div2_rz(t)                     # half-rotate toward the goal axis
		var disp := Pm98Trig.polar_vec(Pm98Trig._tdiv(mag, 4), blended)
		p[0xa0] = Pm98Trig._i32(_si(p, 0xa0) + int(disp[0]))
		p[0xa4] = Pm98Trig._i32(_si(p, 0xa4) + int(disp[1]))
		p[0xa8] = Pm98Trig._i32(_si(p, 0xa8) + int(disp[2]))
		if mag > 0x1e0000:
			ball[0x62] = 1

	# clamp the aim into the goal AABB, shrunk 0x4ccc per face (FUN_00590ac0/b10/5b1210/590be0 + min/max).
	p[0xa0] = _clamp_i(_si(p, 0xa0), Pm98Trig._i32(_si(m, 0x1828) + 0x4ccc), Pm98Trig._i32(_si(m, 0x1834) - 0x4ccc))
	p[0xa4] = _clamp_i(_si(p, 0xa4), Pm98Trig._i32(_si(m, 0x182c) + 0x4ccc), Pm98Trig._i32(_si(m, 0x1838) - 0x4ccc))
	p[0xa8] = _clamp_i(_si(p, 0xa8), Pm98Trig._i32(_si(m, 0x1830) + 0x4ccc), Pm98Trig._i32(_si(m, 0x183c) - 0x4ccc))

	# special touch: latch p+0x5e = (power != 0) (predicate re-evaluated; inputs unchanged here).
	if special:
		p[0x5e] = 1 if _g(p, 0x54) != 0 else 0

	if call_setup:
		setup_shot(p, gs.get(0, []), rng)


## FUN_005a44f0 (__thiscall match; side): the opponent goal-line x. goalx = match+0x1820, NEGATED when
## (match+0x19a0 & 1) == side. ai_feed_024 calls it with side = 1 - team (the goal the player attacks),
## both in the preamble heading test and the tail re-aim. (Same orientation rule as goal_aim_025's goalx.)
static func _opp_goalx(m: Dictionary, side: int) -> int:
	var goalx := _si(m, 0x1820)
	if (_g(m, 0x19a0) & 1) == side:
		goalx = Pm98Trig._i32(-goalx)
	return goalx


## FUN_005ad010 (case 5/0x24, __fastcall this=player), frame guard p+0x2c==3 && p+0x30==3: THE MONSTER (2391 B)
## -- the AI "feed / blind-aim" handler, last of Family A. Clears ball+0x4c up front. The branches (oracle
## tools/re/run_ad010_oracle.sh -> specs/ad010_oracle.txt; setup_shot + 005943b0 stubbed, commentary headless):
## (1) POWER-BUMP preamble -- only when p+0x54 >= 0xe AND p+0x5e==0: if the player faces within ~90deg of the
##     opp goal (heading_diff to [opp_goalx,0,0] s16-abs < 0x4000) AND |anchor+x| > 0x1e0000, boost p+0x54 by
##     min((|anchor+x|-0x1e0000)/0x80000, 5). Draws NO rng.
## (2) special = gs+0x2ee && phase0 && p+0x5c. If special: p+0x5e = (p+0x58 != 0). ELSE a power roll: DRAW A,
##     p+0x5e = ((A*1000)/0x8000 < (|anchor+x|*500)/0x3c0000); if set, DRAW B, p+0x58 = shot_rng_scale(B,
##     (|anchor+x|*10)/0x3c0000) + 4. (1-2 draws.)
## (3) BIG branch on p+700 (0x2bc):
##   * p700==0 AND restart_box_ok(player pos): p+0x5e=1; special -> p+0x58 = tdiv(p58,2)+8 (0 draws); else
##     reroll p58 = scale(rng,4)+0xc, p54 = scale(rng,2)+0xe (2 draws) + worst-teammate facing bias (+1 draw
##     if a worst teammate exists; SIGN IS OPPOSITE feed_layoff_036: word>=0 -> +0x222, word<0 -> -0x222).
##     Then displace by polar(p54*0x120000/16+0x120000, facing), corridor_nearest(0x1e0000,0xa0000); HIT ->
##     aim=teammate + ball+0x4c; MISS -> blind polar(p54*0xe0000/16+0x120000 + rng*0x800/0x80) (+1 draw).
##   * else (p700!=0 OR box-fail) match+0x44c==4: reroll unless special -- p58=scale(rng,6)+0xc, p54=scale(rng,
##     3)+0xd (2 draws); if p58!=0 displace by polar(p54*0x190000/16+0xf0000, facing) + corridor(0x460000,
##     0x80000); HIT->aim; MISS-> 2nd corridor(0x460000,0xf0000) on the RESTORED position; HIT->aim.
##   * else 44c!=4: unless special, if 44c==5: 19cc==0 -> corridor(0x190000,0xf0000) (HIT->aim); 19cc!=0 ->
##     p+0x5e=1 + p+0x58 = scale(rng,8)+4 (1 draw).
## (4) TAIL (p+0x5e set && ball+0x4c==0): for p700==0, a goalbox-on-anchor-side early-out skips the re-aim.
##     Else: aim -= pos; scale by (0x10000 - p58*0x8000/16) (== 1 - p58/32) via FUN_005ee1c0; if the heading
##     to the scaled aim is within 0x2000 of the heading to the opp goal (atan(opp_goalx-x, -y)), blend in
##     polar(|anchor+x|, atan(scaled.x, scaled.y)) and halve each lane; aim += pos.
## (5) setup_shot + match+0x462 |= 0x80. ALL corridor casts are FUN_005b1100 (deterministic, no rng); ad010
##     NEVER uses loose_ball_search. The decompiler aliased local_18/14/10 as opp_goalx, but at the
##     displacement sites those slots hold the FRESH FUN_005ee0f0 polar output -- verified in the disasm.
static func ai_feed_024(p: Dictionary, rng, call_setup: bool = true) -> void:
	if _g(p, 0x2c) != 3 or _g(p, 0x30) != 3:
		return
	var ball := _ref(p, 0x190)
	var m := _ref(p, 0x18c)
	var gs := _ref(p, 0x184)
	ball[0x4c] = 0

	# ---- (1) power-bump preamble (no rng) ----
	if _si(p, 0x54) >= 0xe and _g(p, 0x5e) == 0:
		var ogoalx := _opp_goalx(m, 1 - _g(p, 0x2b8))
		var hd := Pm98Trig._s16(Pm98Trig.atan_angle(Pm98Trig._i32(ogoalx - _si(p, 0x4)), Pm98Trig._i32(-_si(p, 0x8))) - _g(p, 0x34))
		if abs(hd) < 0x4000:
			var ax0: int = abs(Pm98Trig._i32(_si(p, 0x3a4) + _si(p, 0x4)))
			if ax0 > 0x1e0000:
				var boost: int = Pm98Trig._tdiv(Pm98Trig._i32(ax0 - 0x1e0000), 0x80000)
				if boost > 5:
					boost = 5
				p[0x54] = Pm98Trig._i32(_si(p, 0x54) + boost)

	# ---- (2) special predicate + power roll ----
	var special: bool = _g(gs, 0x2ee) != 0 and _phase0(m) and _g(p, 0x5c) != 0
	if special:
		p[0x5e] = 1 if _g(p, 0x58) != 0 else 0
	else:
		var ax: int = abs(Pm98Trig._i32(_si(p, 0x3a4) + _si(p, 0x4)))
		var draw_a: int = rng.next()                                          # DRAW A
		# ax*500 and ax*10 WRAP to int32 (the imul) BEFORE the signed /0x3c0000 -- a 34M*500 product
		# overflows, so the roll is on the wrapped value, not the 64-bit one.
		var lhs := Pm98Trig._tdiv(Pm98Trig._i32(draw_a * 1000), 0x8000)
		var rhs := Pm98Trig._tdiv(Pm98Trig._i32(ax * 500), 0x3c0000)
		p[0x5e] = 1 if lhs < rhs else 0
		if lhs < rhs:
			p[0x58] = _shot_rng_scale(rng.next(), Pm98Trig._tdiv(Pm98Trig._i32(ax * 10), 0x3c0000)) + 4   # DRAW B
		# (p+0x58 left as-is when the roll fails)

	# ---- (3) big p+700 branch ----
	if _g(p, 0x2bc) == 0 and restart_box_ok(p, [_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)]):
		# --- p700==0 path ---
		p[0x5e] = 1
		if special:
			p[0x58] = Pm98Trig._tdiv(_si(p, 0x58), 2) + 8
		else:
			p[0x58] = _shot_rng_scale(rng.next(), 4) + 0xc                    # DRAW
			p[0x54] = _shot_rng_scale(rng.next(), 2) + 0xe                    # DRAW
			# worst-rated teammate facing bias (SIGN OPPOSITE feed_layoff_036).
			var roster1: Array = p.get(0x188, [])
			var worst: Variant = null
			var worst_skill := 0x3e80000
			for cand in roster1:
				var skill: int
				if cand is Dictionary:
					var cd: Dictionary = cand
					var ci := _g(cd, 0x2b8) * 0xb + _g(cd, 0x2c4)
					skill = _si(p, 0xe4 + ci * 4)
				else:
					skill = 0xc80000
				if skill < worst_skill:
					worst_skill = skill
					worst = cand
			if worst is Dictionary:
				var wd: Dictionary = worst
				var wi := _g(wd, 0x2b8) * 0xb + _g(wd, 0x2c4)
				var sk16 := Pm98Trig._s16(_g(p, 0xb8 + wi * 2))
				if sk16 >= 0:                                                 # word >= 0 (JGE) -> +0x222
					p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (_shot_rng_scale(rng.next(), 0x222) + 0x222))
				else:                                                        # word < 0 -> -0x222
					p[0x34] = Pm98Trig._s16(_g(p, 0x34) + (-0x222 - _shot_rng_scale(rng.next(), 0x222)))

		var facing := _g(p, 0x34)
		var mag := Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0x120000), 0x10) + 0x120000
		var disp := Pm98Trig.polar_vec(mag, facing)
		p[0x4] = Pm98Trig._i32(_si(p, 0x4) + int(disp[0]))
		p[0x8] = Pm98Trig._i32(_si(p, 0x8) + int(disp[1]))
		p[0xc] = Pm98Trig._i32(_si(p, 0xc) + int(disp[2]))
		var hit: Variant = _corridor_nearest(p, gs.get(0, []), facing, 0x1e0000, 0xa0000)
		p[0x4] = Pm98Trig._i32(_si(p, 0x4) - int(disp[0]))
		p[0x8] = Pm98Trig._i32(_si(p, 0x8) - int(disp[1]))
		p[0xc] = Pm98Trig._i32(_si(p, 0xc) - int(disp[2]))
		if hit is Dictionary:
			var hd2: Dictionary = hit
			p[0xa0] = _g(hd2, 0x4); p[0xa4] = _g(hd2, 0x8); p[0xa8] = _g(hd2, 0xc)
			ball[0x4c] = hd2
		else:
			var mag2 := Pm98Trig._tdiv(rng.next() * 0x800, 0x80) + Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0xe0000), 0x10) + 0x120000   # DRAW
			var disp2 := Pm98Trig.polar_vec(mag2, facing)
			p[0xa0] = Pm98Trig._i32(_si(p, 0x4) + int(disp2[0]))
			p[0xa4] = Pm98Trig._i32(_si(p, 0x8) + int(disp2[1]))
			p[0xa8] = Pm98Trig._i32(_si(p, 0xc) + int(disp2[2]))
	elif _g(m, 0x44c) == 4:
		# --- p700!=0, match+0x44c==4 ---
		if not special:
			p[0x5e] = 1
			p[0x58] = _shot_rng_scale(rng.next(), 6) + 0xc                    # DRAW
			p[0x54] = _shot_rng_scale(rng.next(), 3) + 0xd                    # DRAW
		if _g(p, 0x58) != 0:
			var facing := _g(p, 0x34)
			var mag := Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x54) * 0x190000), 0x10) + 0xf0000
			var disp := Pm98Trig.polar_vec(mag, facing)
			p[0x4] = Pm98Trig._i32(_si(p, 0x4) + int(disp[0]))
			p[0x8] = Pm98Trig._i32(_si(p, 0x8) + int(disp[1]))
			p[0xc] = Pm98Trig._i32(_si(p, 0xc) + int(disp[2]))
			var hit1: Variant = _corridor_nearest(p, gs.get(0, []), facing, 0x460000, 0x80000)
			p[0x4] = Pm98Trig._i32(_si(p, 0x4) - int(disp[0]))
			p[0x8] = Pm98Trig._i32(_si(p, 0x8) - int(disp[1]))
			p[0xc] = Pm98Trig._i32(_si(p, 0xc) - int(disp[2]))
			if hit1 is Dictionary:
				var h1: Dictionary = hit1
				p[0xa0] = _g(h1, 0x4); p[0xa4] = _g(h1, 0x8); p[0xa8] = _g(h1, 0xc)
				ball[0x4c] = h1
			else:
				var hit2: Variant = _corridor_nearest(p, gs.get(0, []), facing, 0x460000, 0xf0000)
				if hit2 is Dictionary:
					var h2: Dictionary = hit2
					p[0xa0] = _g(h2, 0x4); p[0xa4] = _g(h2, 0x8); p[0xa8] = _g(h2, 0xc)
					ball[0x4c] = h2
	else:
		# --- p700!=0, 44c != 4 ---
		if not special and _g(m, 0x44c) == 5:
			if _g(m, 0x19cc) == 0:
				var facing := _g(p, 0x34)
				var hit3: Variant = _corridor_nearest(p, gs.get(0, []), facing, 0x190000, 0xf0000)
				if hit3 is Dictionary:
					var h3: Dictionary = hit3
					p[0xa0] = _g(h3, 0x4); p[0xa4] = _g(h3, 0x8); p[0xa8] = _g(h3, 0xc)
					ball[0x4c] = h3
			else:
				p[0x5e] = 1
				p[0x58] = _shot_rng_scale(rng.next(), 8) + 4                  # DRAW

	# ---- (4) tail re-aim (blind aim refinement) ----
	# ball+0x4c is a teammate POINTER in the binary: a corridor HIT stores a Dict here, so "== 0" (no
	# target) means it is NOT a Dict.
	if _g(p, 0x5e) != 0 and not (ball.get(0x4c, 0) is Dictionary):
		var skip := false
		if _g(p, 0x2bc) == 0:
			if _ps_goalbox(p, [_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)]) and _sign1(_si(p, 0x4)) == _sign1(_si(p, 0x3a4)):
				skip = true
		if not skip:
			var amag: int = abs(Pm98Trig._i32(_si(p, 0x3a4) + _si(p, 0x4)))
			# aim relative to pos, then scaled by (1 - p58/32) (FUN_005ee1c0).
			var arx := Pm98Trig._i32(_si(p, 0xa0) - _si(p, 0x4))
			var ary := Pm98Trig._i32(_si(p, 0xa4) - _si(p, 0x8))
			var arz := Pm98Trig._i32(_si(p, 0xa8) - _si(p, 0xc))
			var sf := Pm98Trig._i32(0x10000 - Pm98Trig._tdiv(Pm98Trig._i32(_si(p, 0x58) * 0x8000), 0x10))
			var scaled := Pm98Trig.scale_vec3(arx, ary, arz, sf)
			var sx: int = int(scaled[0])
			var sy: int = int(scaled[1])
			var sz: int = int(scaled[2])
			var goalx := _opp_goalx(m, 1 - _g(p, 0x2b8))
			var s5 := Pm98Trig.atan_angle(Pm98Trig._i32(goalx - _si(p, 0x4)), Pm98Trig._i32(-_si(p, 0x8)))
			var s6 := Pm98Trig.atan_angle(Pm98Trig._i32(sx - _si(p, 0x4)), Pm98Trig._i32(sy - _si(p, 0x8)))
			if abs(Pm98Trig._s16(s6 - s5)) < 0x2000:
				var pol := Pm98Trig.polar_vec(amag, Pm98Trig.atan_angle(sx, sy))
				sx = Pm98Trig._tdiv(Pm98Trig._i32(sx + int(pol[0])), 2)
				sy = Pm98Trig._tdiv(Pm98Trig._i32(sy + int(pol[1])), 2)
				sz = Pm98Trig._tdiv(Pm98Trig._i32(sz + int(pol[2])), 2)
			p[0xa0] = Pm98Trig._i32(sx + _si(p, 0x4))
			p[0xa4] = Pm98Trig._i32(sy + _si(p, 0x8))
			p[0xa8] = Pm98Trig._i32(sz + _si(p, 0xc))

	# ---- (5) setup_shot + match+0x462 |= 0x80 (unconditional once the frame guard passes) ----
	if call_setup:
		setup_shot(p, gs.get(0, []), rng)
	m[0x462] = _g(m, 0x462) | 0x80


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


## FUN_00590aa0 (__thiscall out; x, y, z): store a 3-vec out=[x,y,z]. (FUN_00590ac0 copies a vec;
## this one takes the three scalars directly.) The driver builds working positions with it in the
## restart-placement ladder. Each component wraps to int32 (faithful to the 32-bit store).
static func vec3_set(x: int, y: int, z: int) -> Array:
	return [Pm98Trig._i32(x), Pm98Trig._i32(y), Pm98Trig._i32(z)]


## FUN_005943b0 / FUN_005943f0 / FUN_005943d0 (__fastcall match): equality predicates on the
## session play-state `match+0x468 -> +0xfa0` (a global mode int, distinct from the set-piece phase
## +0x448). 5943b0 tests ==0, 5943f0 tests ==2, 5943d0 tests ==4. The event-queue layer uses them to
## gate the priority counter (+0x1a2c) and the timed dequeue. match+0x468 is the session sub-object.
static func _play_state(m: Dictionary) -> int:
	return _g(_ref(m, 0x468), 0xfa0)

static func play_state_eq(m: Dictionary, n: int) -> bool:
	return _play_state(m) == n


## FUN_0059a1e0 (__thiscall player; vec, factor): clamp vec.x toward `player`'s attacking goal by a
## 0..50 (0x32) `factor`. boundary = i32((factor-50)*goalx)/50 when the player attacks -x
## (player+0x3a4 < 0) -> clamp DOWN (take the min); else i32((50-factor)*goalx)/50 -> clamp UP (max).
## goalx = match+0x1820 (match = player+0x18c). The product wraps to int32 (imul) before the truncating
## /50 (idiv toward zero). Returns the clamped 3-vec (y, z untouched).
static func clamp_x_goalside(p: Dictionary, vec: Array, factor: int) -> Array:
	var goalx := _si(_ref(p, 0x18c), 0x1820)
	var out := [Pm98Trig._i32(int(vec[0])), Pm98Trig._i32(int(vec[1])), Pm98Trig._i32(int(vec[2]))]
	if _si(p, 0x3a4) < 0:
		var b: int = Pm98Trig._i32((factor - 0x32) * goalx) / 0x32
		if b < out[0]:
			out[0] = b
	else:
		var b: int = Pm98Trig._i32((0x32 - factor) * goalx) / 0x32
		if out[0] < b:
			out[0] = b
	return out


## FUN_0059a120 (__thiscall player; vec) -> bool: the restart-placement "deep on own attacking flank"
## test. It is the SAME-side (`==`) twin of pos_forward_ok (FUN_005b04e0, which is `!=`): vec must sit
## in the positioning box (match dims +0x1828..+0x183c), past the line abs(x) > goalx-0x108000, within
## abs(y) < 0x1428f5, AND on the SAME x-side as the player's attacking direction (+0x3a4). match = +0x18c.
static func restart_box_ok(p: Dictionary, vec: Array) -> bool:
	var m: Dictionary = _ref(p, 0x18c)
	var x := Pm98Trig._i32(int(vec[0]))
	var y := Pm98Trig._i32(int(vec[1]))
	var z := Pm98Trig._i32(int(vec[2]))
	if x < _si(m, 0x1828) or x > _si(m, 0x1834) or y < _si(m, 0x182c) or y > _si(m, 0x1838) \
			or z < _si(m, 0x1830) or z > _si(m, 0x183c):
		return false
	if not (_si(m, 0x1820) - 0x108000 < abs(x) and abs(y) < 0x1428f5):
		return false
	return _sign1(x) == _sign1(_si(p, 0x3a4))


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
# FULLY PORTED (every branch): phase 4 / (5 & match+0x19cc) defensive-WALL (loops 1-5); phase 7 scatter
# (match+0x19a0==4) + wall-else (match+0x19a0 != 4); phase 3 kickoff/restart; phase-5 tail Path A
# (0x19cc != 0 && 0x45c != team, the insertion-sort fan) + Path C (our-set-piece follow-up).
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
## branch is the role-table WALL, ported in _position_phase7_wall below.
static func _position_phase7(ctx: Dictionary, m: Dictionary, team: int, rng) -> void:
	if _g(m, 0x19a0) != 4:
		_position_phase7_wall(ctx, m, team)
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


## FUN_005b73a0 phase-7 wall-else role-priority table &DAT_00639270 (2 rows x 11 int32, file offset
## 0x238070). Row = `flag` (1 iff team != match+0x45c). Each on-pitch non-taker player whose role
## (+0x2c8) matches an as-yet-unclaimed table entry is snapped to the wall slot keyed by that index;
## the claimed-slot bitmap is SHARED across all players (a role appears at most once per row).
const PHASE7_WALL_ROLES := [
	[12, 7, 8, 16, 13, 9, 17, 10, 18, 11, 14],   # flag 0: team == set-piece side (match+0x45c)
	[3, 11, 18, 5, 15, 4, 6, 8, 7, 2, 0],        # flag 1: team != set-piece side
]


## FUN_005b73a0 phase-7 wall-ELSE (disasm 0x5b7da9..0x5b7fe5, reached when match+0x19a0 != 4). For each
## on-pitch non-taker player, scan the 11-entry role table for `flag` (= team != match+0x45c); the FIRST
## unclaimed entry matching the player's role (+0x2c8) snaps it to a defensive-wall slot:
##   x = +/-(0x109999 - goalXscale),  y = +/-(Yscale - trunc(Yscale*(flag+1+2*idx) / 11)),  z = 0,
## both negated iff (orient ^ (1 - side)) != 0  (orient = match+0x19a0 & 1, side = match+0x45c). The
## per-row claimed bitmap is shared, so two players of the same role only place the first. Then EVERY
## eligible player (matched or not) runs the shared tail: clamp_min_sep off the taker (0xa0000); if its
## x ends within 0x109999 of the near goal line snap x = +/-(goalXscale - 0x110000) (neg iff
## (orient ^ side) != 0); face the ball (+0x34/+0x64 = atan(ball - player)). RNG-free.
static func _position_phase7_wall(ctx: Dictionary, m: Dictionary, team: int) -> void:
	var players: Array = ctx.get("players", [])
	var taker: Dictionary = _ref(m, 0x438)
	var side := _g(m, 0x45c)
	var orient := _g(m, 0x19a0) & 1
	var flag := 1 if team != side else 0
	var table: Array = PHASE7_WALL_ROLES[flag]
	var claimed := [false, false, false, false, false, false, false, false, false, false, false]
	var goalx := _si(m, 0x1820)
	var yscale := _si(m, 0x1824)
	var ball := [_si(m, 0x1614), _si(m, 0x1618), _si(m, 0x161c)]
	var neg := (orient ^ (1 - side)) != 0                         # (orient&1) ^ (1-side): the wall-xy + ivar18 sign
	for i in players.size():
		var p: Dictionary = players[i]
		if is_same(p, taker) or _g(p, 0x2bc) == 0:
			continue
		var role := _g(p, 0x2c8)
		for idx in 11:
			if role == int(table[idx]) and not claimed[idx]:
				claimed[idx] = true
				var ebp := flag + 1 + 2 * idx
				var ivar12 := Pm98Trig._i32(0x109999 - goalx)
				var ivar21 := Pm98Trig._i32(yscale - Pm98Trig._tdiv(Pm98Trig._i32(yscale * ebp), 11))
				if neg:
					ivar21 = Pm98Trig._i32(-ivar21)
					ivar12 = Pm98Trig._i32(-ivar12)
				p[0x4] = ivar12
				p[0x8] = ivar21
				p[0xc] = 0
		# ---- shared tail (runs for EVERY eligible player) ----
		var np: Array = Pm98Trig.clamp_min_sep(
			[_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)],
			[_si(taker, 0x4), _si(taker, 0x8), _si(taker, 0xc)], 0xa0000)
		p[0x4] = np[0]; p[0x8] = np[1]; p[0xc] = np[2]
		var ivar18 := Pm98Trig._i32(-goalx) if not neg else goalx
		if abs(Pm98Trig._i32(_si(p, 0x4) - ivar18)) <= 0x109999:
			var snap := Pm98Trig._i32(goalx - 0x110000)
			if (orient ^ side) != 0:
				snap = Pm98Trig._i32(-snap)
			p[0x4] = snap
		var facing := Pm98Trig.atan_angle(
			Pm98Trig._i32(ball[0] - _si(p, 0x4)), Pm98Trig._i32(ball[1] - _si(p, 0x8))) & 0xffff
		p[0x34] = facing
		p[0x64] = facing


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
##   * 0x19cc != 0 && 0x45c != team -> PATH A: the defensive-distribution insertion-sort (_phase5_tail_pathA);
##   * 0x19cc != 0 && 0x45c == team -> no-op return;
##   * 0x19cc == 0 && 0x45c == team -> PATH C (ported below).
## (0x45c != team with 0x19cc == 0 never reaches here through phase 5: the wall needs 0x45c != team and
## 0x19cc != 0, so a phase-5 wall implies Path A; Path C is the our-set-piece, no-19cc follow-up.)
static func _position_phase5_tail(ctx: Dictionary, m: Dictionary, team: int) -> void:
	if _g(m, 0x19cc) != 0:
		if _g(m, 0x45c) != team:
			_phase5_tail_pathA(ctx, m, team)
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


## Faithful overlapping copy of `count` dwords inside the flat slot array, src -> dst (the binary's
## memmove import thunk ds:0x6233d4). Snapshots the source first so overlapping ranges behave exactly
## like memmove (the insertion shifts the POINTER slots but NOT the parallel priority slots, so the
## priority bytes at slot[6..] go intentionally stale -- reproduced bit-for-bit).
static func _pathA_memmove(arr: Array, dst: int, src: int, count: int) -> void:
	var tmp := []
	for k in count:
		tmp.append(arr[src + k])
	for k in count:
		arr[dst + k] = tmp[k]


## FUN_005b73a0 phase-5 tail PATH A (disasm 0x5b8211..0x5b854c; reached when match+0x448==5 &&
## match+0x19cc != 0 && match+0x45c != team -- i.e. the defensive follow-up that ALWAYS runs right
## after the phase-5 wall). Distribute the N = match+0x19cc highest-priority on-pitch players into a fan
## around the anchor = taker_pos + polar_vec(0x93333, taker_facing).
##   FIRST pass (every on-pitch player): clamp_min_sep off the taker (0xa0000); if it lands OUTSIDE the
##     pitch box [+0x1828..+0x183c] reflect it through the taker (p = 2*taker - p); face the ball; then
##     insertion-sort it by role class (role<=6 -> 0; role in {7,8,10,11,15,18} -> 1; else 2) into N
##     priority slots, highest class first.
##   SECOND pass (each filled slot s): set_position_code(0x1c); place at anchor + polar_vec(radius_s,
##     taker_facing + 0x4000), radius_s = ftol((s*0.45 - N*0.225) * 65536); face the ball. RNG-free.
## Slot bookkeeping is a flat 13-int array: [0..5] = player slots (0 = empty, players stored as
## _PATHA_PTR_BASE+index so a stale slot-pointer never compares < a 0..2 class, matching the binary's
## large positive struct pointers), [6..12] = the parallel priority bytes the memmove leaves stale.
const _PATHA_PTR_BASE := 0x10000000
static func _phase5_tail_pathA(ctx: Dictionary, m: Dictionary, _team: int) -> void:
	var players: Array = ctx.get("players", [])
	var taker: Dictionary = _ref(m, 0x438)
	var n := _g(m, 0x19cc)
	var taker_facing := _g(taker, 0x34) & 0xffff
	var polar0: Array = Pm98Trig.polar_vec(0x93333, taker_facing)
	var anchor := [
		Pm98Trig._i32(polar0[0] + _si(taker, 0x4)),
		Pm98Trig._i32(polar0[1] + _si(taker, 0x8)),
		Pm98Trig._i32(polar0[2] + _si(taker, 0xc)),
	]
	var base_angle := taker_facing + 0x4000
	var ball := [_si(m, 0x1614), _si(m, 0x1618), _si(m, 0x161c)]

	# local_3c: slot[0..5] = player pointers (0 = empty), slot[6..12] = priority bytes (-1 init).
	var slot := []
	slot.resize(13)
	for k in 6:
		slot[k] = 0
	for k in range(6, 13):
		slot[k] = -1

	# ---- FIRST pass: clamp / box-reflect / face / insertion-sort by class ----
	for i in players.size():
		var p: Dictionary = players[i]
		if _g(p, 0x2bc) == 0:
			continue
		var role := _g(p, 0x2c8)
		var cls := 0
		if role > 6:
			cls = 1 if role in [7, 8, 0xa, 0xb, 0xf, 0x12] else 2
		var np: Array = Pm98Trig.clamp_min_sep(
			[_si(p, 0x4), _si(p, 0x8), _si(p, 0xc)],
			[_si(taker, 0x4), _si(taker, 0x8), _si(taker, 0xc)], 0xa0000)
		p[0x4] = np[0]; p[0x8] = np[1]; p[0xc] = np[2]
		var px := _si(p, 0x4); var py := _si(p, 0x8); var pz := _si(p, 0xc)
		var in_box := px >= _si(m, 0x1828) and px <= _si(m, 0x1834) \
			and py >= _si(m, 0x182c) and py <= _si(m, 0x1838) \
			and pz >= _si(m, 0x1830) and pz <= _si(m, 0x183c)
		if not in_box:
			p[0x4] = Pm98Trig._i32(px + (_si(taker, 0x4) - px) * 2)
			p[0x8] = Pm98Trig._i32(py + (_si(taker, 0x8) - py) * 2)
			p[0xc] = Pm98Trig._i32(pz + (_si(taker, 0xc) - pz) * 2)
		var facing := Pm98Trig.atan_angle(
			Pm98Trig._i32(ball[0] - _si(p, 0x4)), Pm98Trig._i32(ball[1] - _si(p, 0x8))) & 0xffff
		p[0x34] = facing
		p[0x64] = facing
		for s in n:
			if cls > int(slot[6 + s]):
				_pathA_memmove(slot, s + 1, s, 6 - s)
				slot[s] = _PATHA_PTR_BASE + i
				slot[6 + s] = cls
				break

	# ---- SECOND pass: place each filled slot around the anchor ----
	for s in n:
		if int(slot[s]) == 0:
			continue
		var p: Dictionary = players[int(slot[s]) - _PATHA_PTR_BASE]
		set_position_code(p, 0x1c)
		var radius := int((float(s) * 0.45 - float(n) * 0.225) * 65536.0)
		var polar: Array = Pm98Trig.polar_vec(radius, base_angle)
		p[0x4] = Pm98Trig._i32(polar[0] + anchor[0])
		p[0x8] = Pm98Trig._i32(polar[1] + anchor[1])
		p[0xc] = Pm98Trig._i32(polar[2] + anchor[2])
		var facing := Pm98Trig.atan_angle(
			Pm98Trig._i32(ball[0] - _si(p, 0x4)), Pm98Trig._i32(ball[1] - _si(p, 0x8))) & 0xffff
		p[0x34] = facing
		p[0x64] = facing
