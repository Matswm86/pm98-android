extends SceneTree
## Engine-scorer wiring test: the match feed must name the players the STAT ENGINE
## actually picked, not a re-rolled set. Covers the path MatchSim.simulate -> `goals`
## (Pm98StatMatch.goal_events resolved to names) -> MatchCommentary.narrate.
##
## Asserts, over several fixed seeds on two real dense squads:
##   1. res has `goals`, and its size == home_goals + away_goals (feed agrees with score).
##   2. every goal: side/scorer_side in {0,1}, minute in 1..90, no own goal (this port emits
##      none), scorer_side == credited side, and the scorer is one of slots 1..10 (GK excluded)
##      of that side's fielded XI -- i.e. a real engine pick, not a stray name.
##   3. determinism: the same seed yields the identical goals list.
##   4. feed parity: narrate(..., res.goals) emits exactly one goal line per engine goal,
##      at the engine minute, naming the engine scorer.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_engine_scorers.gd

var _fail := 0
var _pass := 0


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", msg)


func _load_db() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	assert(f != null, "game_db.json missing")
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## Highest-PO GK in slot 0, then 10 outfielders by a balanced overall (slot 0 = GK).
func _xi(club: Dictionary) -> Array:
	var gks: Array = []
	var out: Array = []
	for p in club.get("players", []):
		var a: Variant = p.get("attrs", {})
		if not (a is Dictionary) or (a as Dictionary).is_empty():
			continue
		if p.get("isGK"):
			gks.append(p)
		else:
			out.append(p)
	gks.sort_custom(func(x, y): return int(x["attrs"].get("PO", 0)) > int(y["attrs"].get("PO", 0)))
	out.sort_custom(func(x, y):
		var sx: int = int(x["attrs"].get("CA", 0)) + int(x["attrs"].get("VE", 0))
		var sy: int = int(y["attrs"].get("CA", 0)) + int(y["attrs"].get("VE", 0))
		return sx > sy)
	var xi: Array = []
	xi.append(gks[0] if gks.size() > 0 else null)
	for i in range(10):
		xi.append(out[i] if i < out.size() else null)
	return xi


func _names_1_to_10(xi: Array) -> Dictionary:
	var s: Dictionary = {}   # name -> true, slots 1..10 (GK slot 0 excluded; never scores)
	for i in range(1, 11):
		if i < xi.size() and xi[i] is Dictionary:
			s[str((xi[i] as Dictionary).get("name", "?"))] = true
	return s


func _two_dense(db: Dictionary) -> Array:
	var dense: Array = []
	for c in db.get("clubs", []):
		var n := 0
		for p in c.get("players", []):
			if (p.get("attrs", {}) is Dictionary) and not (p["attrs"] as Dictionary).is_empty():
				n += 1
		if n >= 14:
			dense.append(c)
		if dense.size() >= 2:
			break
	return dense


func _init() -> void:
	var db := _load_db()
	var dense := _two_dense(db)
	_ok(dense.size() >= 2, "need >=2 dense clubs, got %d" % dense.size())
	if dense.size() < 2:
		_done()
		return

	var home: Dictionary = dense[0]
	var away: Dictionary = dense[1]
	var hid := int(home.get("id", 1))
	var aid := int(away.get("id", 2))
	var xi_h := _xi(home)
	var xi_a := _xi(away)
	_ok(MatchSim._usable(xi_h) and MatchSim._usable(xi_a), "both XIs usable -> stat engine runs")
	var names := [_names_1_to_10(xi_h), _names_1_to_10(xi_a)]

	var goals_checked := 0
	for seed in range(1, 41):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var res := MatchSim.simulate(rng, {}, {}, xi_h, xi_a, hid, aid)
		var hg := int(res["home_goals"])
		var ag := int(res["away_goals"])
		var goals: Array = res.get("goals", [])

		# 1. feed length agrees with the scoreline.
		_ok(goals.size() == hg + ag, "seed %d: goals %d == hg+ag %d" % [seed, goals.size(), hg + ag])

		# 2. each goal is a real engine pick on the crediting side.
		for g in goals:
			var side := int(g.get("side", -1))
			var ssd := int(g.get("scorer_side", -1))
			var mn := int(g.get("minute", -1))
			_ok(side == 0 or side == 1, "seed %d: side in {0,1} (%d)" % [seed, side])
			_ok(not bool(g.get("own_goal", false)), "seed %d: no own goal (port emits none)" % seed)
			_ok(ssd == side, "seed %d: scorer_side == credited side" % seed)
			_ok(mn >= 1 and mn <= 90, "seed %d: minute 1..90 (%d)" % [seed, mn])
			if side == 0 or side == 1:
				_ok((names[ssd] as Dictionary).has(str(g.get("scorer", "?"))),
					"seed %d: scorer '%s' is a fielded outfielder of side %d" % [seed, g.get("scorer", "?"), ssd])
			goals_checked += 1

		# 3. determinism: same seed -> identical goals.
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = seed
		var res2 := MatchSim.simulate(rng2, {}, {}, xi_h, xi_a, hid, aid)
		_ok(JSON.stringify(res2.get("goals", [])) == JSON.stringify(goals),
			"seed %d: goals are deterministic for a fixed seed" % seed)

		# 4. feed parity: narrate names the engine scorers at the engine minutes.
		var nr := RandomNumberGenerator.new()
		nr.seed = seed * 7 + 1
		var feed := MatchCommentary.narrate(nr, home, away, hg, ag, goals)
		var goal_lines: Array = []
		for ln in feed.get("lines", []):
			if (ln as Dictionary).get("goal") == true:
				goal_lines.append(ln)
		_ok(goal_lines.size() == goals.size(), "seed %d: one goal line per engine goal" % seed)
		for g in goals:
			var found := false
			for ln in goal_lines:
				if int((ln as Dictionary).get("minute", -1)) == int(g.get("minute", -2)) \
						and str((ln as Dictionary).get("text", "")).contains(str(g.get("scorer", "?"))):
					found = true
					break
			_ok(found, "seed %d: feed has '%s' at %d'" % [seed, g.get("scorer", "?"), g.get("minute", -1)])

	_ok(goals_checked >= 10, "checked a meaningful number of goals (%d)" % goals_checked)
	_done()


func _done() -> void:
	print("test_engine_scorers: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
