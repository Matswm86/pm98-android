extends SceneTree
## Regression for the audit C5 #7d "all goals credited to ONE side in BRIEF"
## candidate: MatchCommentary.narrate's engine-goal path used a home-0 default
## when a producer omitted `side`, so every such goal piled onto the home
## column. The credited side must fall back to scorer_side (flipped for own
## goals — the benefiting team is the opponent), never to a constant.
##
##   ~/godot462 --headless --path app --script res://tests/test_commentary_side.gd

var _fails := 0


func _initialize() -> void:
	_run()
	quit(1 if _fails > 0 else 0)


func _assert(cond: bool, msg: String) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _club(nm: String) -> Dictionary:
	return {"name": nm, "players": [
		{"name": nm + " GK", "isGK": true, "attrs": {}},
		{"name": nm + " FW", "isGK": false, "attrs": {}},
	]}


## The credited `side` of the single GOAL line narrate emits for `goal`.
func _credited(goal: Dictionary) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var m := MatchCommentary.narrate(rng, _club("Home FC"), _club("Away FC"), 1, 1, [goal])
	for ln in m["lines"]:
		if ln.get("goal") == true:
			return int(ln["side"])
	return -99


func _run() -> void:
	print("test_commentary_side")
	_assert(_credited({"minute": 10, "side": 1, "scorer": "X", "scorer_side": 1}) == 1,
		"explicit side is respected")
	_assert(_credited({"minute": 10, "side": 0, "scorer": "X", "scorer_side": 1, "own_goal": true}) == 0,
		"explicit side wins over scorer_side on own goals")
	_assert(_credited({"minute": 10, "scorer": "X", "scorer_side": 1}) == 1,
		"missing side falls back to scorer_side (was home-0 default)")
	_assert(_credited({"minute": 10, "scorer": "X", "scorer_side": 0}) == 0,
		"missing side, home scorer credits home")
	_assert(_credited({"minute": 10, "scorer": "X", "scorer_side": 1, "own_goal": true}) == 0,
		"missing side + own goal credits the OTHER team")
	_assert(_credited({"minute": 10, "scorer": "X", "scorer_side": 0, "own_goal": true}) == 1,
		"missing side + home own goal credits away")
	print("\n%s" % ("ALL PASS" if _fails == 0 else "FAILURES ABOVE"))
