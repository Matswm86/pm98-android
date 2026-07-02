extends SceneTree
## MatchSim facade routing test: the flag picks the engine, an unusable XI falls back to
## the legacy model, and xi_of builds a full ordered XI from a real club.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_matchsim.gd

var _fail := 0
var _pass := 0


func _ok(c: bool, m: String) -> void:
	if c: _pass += 1
	else:
		_fail += 1
		print("  FAIL: ", m)


func _club() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	for c in db["clubs"]:
		if (c.get("players", []) as Array).size() >= 16:
			return c
	return {}


func _init() -> void:
	var club := _club()
	var rb := MatchEngine.team_ratings(club)

	# xi_of builds 11 entries, slot 0 a GK with attrs.
	var xi := MatchSim.xi_of(club)
	_ok(xi.size() == 11, "xi_of returns 11, got %d" % xi.size())
	_ok(xi[0] is Dictionary and (xi[0] as Dictionary).get("pos", "") == "GK", "slot 0 is a GK")

	# Flag ON + usable XIs -> stat engine; deterministic for a fixed seed.
	MatchSim.use_stat_engine = true
	var r1 := RandomNumberGenerator.new(); r1.seed = 123
	var a := MatchSim.simulate(r1, rb, rb, xi, xi, 7, 19)
	var r2 := RandomNumberGenerator.new(); r2.seed = 123
	var b := MatchSim.simulate(r2, rb, rb, xi, xi, 7, 19)
	_ok(a["home_goals"] == b["home_goals"] and a["away_goals"] == b["away_goals"],
		"stat engine deterministic for a fixed seed")

	# Unusable XI (empty) -> legacy fallback even with the flag ON (no crash, sane score).
	# Empty XIs are the DOCUMENTED legacy route (euro frozen-ratings) — no fallback count.
	MatchSim.fallback_count = 0
	var rc := RandomNumberGenerator.new(); rc.seed = 5
	var c := MatchSim.simulate(rc, rb, rb, [], [], 7, 19)
	_ok(int(c["home_goals"]) >= 0 and int(c["away_goals"]) >= 0, "empty-XI fallback gives a score")
	_ok(MatchSim.fallback_count == 0, "empty-XI legacy route is not counted as a fallback")

	# A NON-empty XI that fails _usable is the silent-invention case the §B3 audit flagged:
	# it must be COUNTED (and warned) so a caller expecting the stat engine can see it.
	var rd := RandomNumberGenerator.new(); rd.seed = 6
	var short_xi := xi.slice(0, 9)   # 9 men: fails the 11-with-attrs gate
	var dd := MatchSim.simulate(rd, rb, rb, short_xi, xi, 7, 19)
	_ok(int(dd["home_goals"]) >= 0 and int(dd["away_goals"]) >= 0, "short-XI fallback gives a score")
	_ok(MatchSim.fallback_count == 1, "short-XI fallback is counted (got %d)" % MatchSim.fallback_count)
	MatchSim.fallback_count = 0

	# Flag OFF -> identical to a direct MatchEngine.simulate on the same rng stream.
	MatchSim.use_stat_engine = false
	var r3 := RandomNumberGenerator.new(); r3.seed = 77
	var viaSim := MatchSim.simulate(r3, rb, rb, xi, xi, 7, 19)
	var r4 := RandomNumberGenerator.new(); r4.seed = 77
	var viaEng := MatchEngine.simulate(r4, rb, rb)
	_ok(viaSim["home_goals"] == viaEng["home_goals"] \
		and viaSim["away_goals"] == viaEng["away_goals"], "flag OFF == legacy MatchEngine")
	MatchSim.use_stat_engine = true   # restore default

	print("test_matchsim: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
