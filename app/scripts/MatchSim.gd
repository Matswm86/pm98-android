class_name MatchSim
extends RefCounted
## Match-simulation facade: routes a fixture between the faithful PM98 STATISTICAL
## engine (Pm98StatMatch, the byte-exact port of the instant-result runner FUN_0044ee70)
## and the legacy abstracted per-shot model (MatchEngine), behind a flag.
##
## The stat engine needs the actual 11-player XI (slot 0 = GK); callers pass it when they
## have it (`xi_of(club)` builds one via auto-pick). When the flag is off, or an XI is
## missing / too sparse (a few fringe clubs have under-11 decoded players), it falls back
## to the ratings-only legacy path -- so every caller keeps working unchanged. The return
## shape is the legacy `{home_goals, away_goals, shots_home, shots_away, conv_home,
## conv_away}` so call sites need no downstream changes.
##
## FLAG: `MatchSim.use_stat_engine` (default ON). Flip it to A-B the two engines over a
## season, or set the env var `PM98_LEGACY_ENGINE` to force the legacy model process-wide
## (used by the engine-calibration test + perf A-B). RE map: docs/re/stat_match_engine_re.md.
##
## PERF: the faithful engine is markedly heavier per match than the legacy aggregate model
## (many rand() draws + per-player accumulation/convergence loops vs a handful of rolls) --
## ~0.4 s for a full 380-match league season vs ~0.02 s. Interactive play (advancing ONE
## week: ~10 league + a few cup matches) stays well under a second; only the offline
## PM98_CUP_SHOT harness, which crunches whole cup + euro brackets for 22 weeks back to
## back, is slow enough to want PM98_LEGACY_ENGINE=1.

static var use_stat_engine := true
static var _legacy_env := -1   # lazy cache of OS.has_environment("PM98_LEGACY_ENGINE")
# Legacy results served where a caller PASSED an XI and so expected the faithful stat
# engine (audit §B3: that fallback used to be silent). Empty XIs do not count; since
# S5 (2026-07-27) euro opponents field their shipped TRUE XIs (Career.euro_xis), so an
# empty XI only remains on a career whose euro_xis feed is missing (stale headless rig).
static var fallback_count := 0


static func _stat_on() -> bool:
	if _legacy_env == -1:
		_legacy_env = 1 if OS.has_environment("PM98_LEGACY_ENGINE") else 0
	return use_stat_engine and _legacy_env == 0


## Build the ordered 11-entry XI (slot 0 = GK, then DEF/MID/FWD) for a club dict, via
## the same auto-pick the AI uses. Returns [] for an empty / player-less club.
static func xi_of(club: Dictionary) -> Array:
	if club.is_empty() or (club.get("players", []) as Array).is_empty():
		return []
	var t := Tactics.auto_pick(club)
	var by_id: Dictionary = {}
	for p in club.get("players", []):
		by_id[int(p.get("id", -1))] = p
	var xi: Array = []
	for pid in t.xi:
		xi.append(by_id.get(int(pid)))
	return xi


## A side's XI is usable by the stat engine only if it has 11 entries all carrying a
## decoded attr row (else the strength / scorer maths degrade); otherwise -> legacy.
static func _usable(xi) -> bool:
	if not (xi is Array) or (xi as Array).size() < 11:
		return false
	for p in xi:
		if not (p is Dictionary):
			return false
		var a: Variant = (p as Dictionary).get("attrs", {})
		if not (a is Dictionary) or (a as Dictionary).is_empty():
			return false
	return true


## Simulate one fixture. `rh`/`ra` are legacy aggregate ratings dicts (fallback, always
## present). `xi_h`/`xi_a` are ordered XIs (slot 0 GK); `tid_h`/`tid_a` are the clubs'
## ids (the stat engine's event team ids). `minutes` 90 = a full match, 30 = standalone
## extra time (two-leg cup tie). Returns the legacy result shape PLUS a `goals` array of
## the stat engine's own resolved scorers (empty on the legacy fallback) so the commentary
## feed can name the players who actually scored instead of re-rolling its own.
static func simulate(rng: RandomNumberGenerator, rh: Dictionary, ra: Dictionary, \
		xi_h: Array, xi_a: Array, tid_h: int, tid_a: int, minutes := 90, \
		stats := false) -> Dictionary:
	if _stat_on() and _usable(xi_h) and _usable(xi_a):
		# THREE UP FRONT, manager-side triggers (hack_three_forwards.md §MIXED PLAY
		# and §THE SHAPE TRIGGER): only the MANAGER's ratings dict carries `front_three`
		# (his chosen shape fields 3+ forward SLOTS) and `mixed_play` (his MENTALITY
		# lever is on MIXED) — Career._ratings_for sets them for his club alone. Armed
		# here per simulate and ALWAYS reset, so no other fixture in the same week loop
		# can inherit it. The third trigger (3 natural forwards) needs no plumbing: the
		# engine reads it off the match struct.
		if Pm98StatMatch.cheat_three_up_front:
			# WHICH side is the manager's — `is_manager` is stamped by
			# Career._ratings_for on his club alone. Every trigger, including the
			# EXE patch's own natural-three-forwards one, is gated on this, so an
			# AI-vs-AI fixture (neither dict marked) arms nothing at all.
			if bool(rh.get("is_manager", false)):
				Pm98StatMatch.cheat_manager_side = 0
			elif bool(ra.get("is_manager", false)):
				Pm98StatMatch.cheat_manager_side = 1
			var mr: Dictionary = rh if Pm98StatMatch.cheat_manager_side == 0 else ra
			Pm98StatMatch.cheat_manager_forced = \
				Pm98StatMatch.cheat_manager_side >= 0 and \
				(bool(mr.get("front_three", false)) or bool(mr.get("mixed_play", false)))
		var mem := Pm98StatMatch.build_mem(xi_h, xi_a, tid_h, tid_a)
		var prng := Pm98StatMatch.Rng.new(rng.randi())
		var rep = null
		var rep_ht = null
		var pids := {}
		if stats:
			rep = Pm98StatStore.Report.new(tid_h, tid_a)
			rep_ht = Pm98StatStore.Report.new(tid_h, tid_a)
			pids = pid_map(xi_h, xi_a)
		if minutes >= 90:
			Pm98StatMatch.simulate(mem, prng, false, false, rep, pids,
				Pm98StatMatch.CADENCE_MATCH, rep_ht)
		else:
			Pm98StatMatch.simulate_extra_time(mem, prng, rep, pids)
		var sc := Pm98StatMatch.score(mem)
		Pm98StatMatch.cheat_manager_side = -1
		Pm98StatMatch.cheat_manager_forced = false
		return {
			"home_goals": int(sc.get(tid_h & 0xFFFF, 0)),
			"away_goals": int(sc.get(tid_a & 0xFFFF, 0)),
			"shots_home": 0, "shots_away": 0, "conv_home": 0, "conv_away": 0,
			"goals": _resolve_goals(mem, xi_h, xi_a, tid_h, tid_a),
			# real engine POSSESSION counters ([home,away]); the BRIEF bar reads the split.
			"possession": Pm98StatMatch.possession(mem),
			# Pm98StatStore.Report when `stats` was asked for, else null. `report_ht`
			# is the half-time snapshot the HALF TIME board's STATISTICS button reads.
			"report": rep,
			"report_ht": rep_ht,
		}
	# LOUD fallback (never silent): a non-empty XI that fails _usable means the caller
	# expected the faithful engine and is getting the legacy abstraction instead.
	if _stat_on() and (not xi_h.is_empty() or not xi_a.is_empty()):
		fallback_count += 1
		push_warning("[MATCHSIM_FALLBACK] #%d: XI failed _usable (h=%d ok=%s, a=%d ok=%s) -> legacy result for %d v %d" % [
			fallback_count, xi_h.size(), _usable(xi_h), xi_a.size(), _usable(xi_a), tid_h, tid_a])
	var res := MatchEngine.simulate(rng, rh, ra, minutes)
	res["goals"] = []
	res["possession"] = []   # legacy path produces no possession -> BRIEF bar stays 50/50
	res["report"] = null      # no per-player records exist on the abstracted model
	res["report_ht"] = null
	return res


## The MANDATORY `pids` bridge for Pm98StatStore.commit(). `build_mem` writes slot+1
## into participant +0x88 on BOTH sides, so records keyed on the raw value would merge
## the two teams on ids 1..11; the binary keys them on the GLOBAL player id. Maps
## `side * 11 + slot` -> the game_db player id. A slot with no id (a sparse decoded
## record) is left out, so commit() falls back to slot+1 for it rather than inventing one.
static func pid_map(xi_h: Array, xi_a: Array) -> Dictionary:
	var out: Dictionary = {}
	for side in 2:
		var xi: Array = xi_h if side == 0 else xi_a
		for slot in mini(xi.size(), 11):
			if not (xi[slot] is Dictionary):
				continue
			var pid := int((xi[slot] as Dictionary).get("id", -1))
			if pid > 0:
				out[side * 11 + slot] = pid
	return out


## Map the stat engine's raw goal events to named scorers for the commentary feed:
##   [{ minute:int, side:int(credited 0/1), scorer:String, scorer_side:int(0/1), own_goal:bool }]
## `side` is the team CREDITED (drives the on-screen score); `scorer`/`scorer_side` name the
## player who took the shot (the conceding side for an own goal). XI slot = shirt-1 (SEL=slot+1).
static func _resolve_goals(mem: Pm98StatMatch.Mem, xi_h: Array, xi_a: Array, tid_h: int, tid_a: int) -> Array:
	var out: Array = []
	for g in Pm98StatMatch.goal_events(mem, tid_h, tid_a):
		var shot_side := int(g["shot_side"])
		var xi: Array = xi_h if shot_side == 0 else xi_a
		var slot := int(g["shirt"]) - 1
		var name := "?"
		if slot >= 0 and slot < xi.size() and xi[slot] is Dictionary:
			name = str((xi[slot] as Dictionary).get("name", "?"))
		out.append({"minute": int(g["minute"]), "side": int(g["credited_side"]),
			"scorer": name, "scorer_side": shot_side, "own_goal": bool(g["own_goal"])})
	return out
