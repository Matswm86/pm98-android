extends SceneTree
## The Coca-Cola Cup's PER-ROUND leg count, pinned to the frames that witness it.
##
## The cup-draw screen's bottom-left plates are not decoration: they say how the round is
## played. `tools/re/probe_cupdraw_per_round.py` scores four rounds of this competition
## from ONE career (`tools/re/refs/cupdraw-rounds-2026-08-01/`) and finds the plates are
## its ONLY per-round variation -- 397 px on the plates between ROUND 2 and each of the
## others, and 0 px anywhere outside the round plate, the MATCHES panel and the animated
## drum:
##
## | frame | round | plates |
## |---|---|---|
## | `keep_0019_cup_draw.png` | ROUND 2 | **1ST LEG / 2ND LEG** |
## | `keep_0049_cup_draw.png` | ROUND 3 | MATCH / REPLAY |
## | `keep_0076_cup_draw.png` | ROUND 4 | MATCH / REPLAY |
## | `keep_0111_cup_draw.png` | QTR. FINALS | MATCH / REPLAY |
##
## ROUND 1 is NOT witnessed and is deliberately NOT pinned here.
##
## Run: godot4 --headless --path app --script res://tests/test_cup_round_legs.gd

var _fail := 0
var _pass := 0


func _init() -> void:
	var opts: Dictionary = Career.LEAGUE_CUP_OPTS
	var per: Dictionary = opts.get("round_legs_by_round", {})
	_ok(per.has(2) and int(per[2]) == 2,
		"LEAGUE_CUP_OPTS pins ROUND 2 at two legs (got %s)" % [per])
	_ok(not per.has(1), "ROUND 1 is unwitnessed and stays unpinned (got %s)" % [per])

	# Drive the real bracket and read the leg count off each round it actually plays.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260801
	var ids: Array = []
	for i in 64:
		ids.append(100 + i)
	var b := Cup.create(ids, 38, opts)
	var seen: Array = []
	var guard := 0
	while not Cup.is_finished(b) and guard < 12:
		var r := Cup.play_round(b, rng, _ratings_fn(), -1, _names_fn())
		seen.append({"round": guard + 1, "label": str(r.get("label", "")),
			"two": _round_two_legged(b)})
		guard += 1

	_ok(seen.size() >= 4, "the bracket plays at least four rounds (got %d)" % seen.size())
	for row in seen:
		var rd := int(row["round"])
		var two := bool(row["two"])
		if rd == 2:
			_ok(two, "round 2 (%s) is TWO-LEGGED" % row["label"])
		elif rd == 3 or rd == 4:
			_ok(not two, "round %d (%s) is ONE match" % [rd, row["label"]])

	# And the plates the screen draws follow the round, through the same call Main makes.
	for two in [true, false]:
		var bb := {"pending_draw": {"round_legs": 2 if two else 1}}
		var plates := Cup.draw_leg_plates(bb)
		var want := ["1ST LEG", "2ND LEG"] if two else ["MATCH", "REPLAY"]
		_ok(plates == want, "round_legs=%d -> plates %s (want %s)" % [
			2 if two else 1, plates, want])

	print("CUP ROUND LEGS: %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)


## Did the LAST played round's ties carry two legs? `_play_tie` stamps `two_legged` on
## each tie, which is the same field `Cup.draw_leg_plates` falls back to.
func _round_two_legged(b: Dictionary) -> bool:
	var rounds: Array = b.get("rounds", [])
	if rounds.is_empty():
		return false
	for tie in ((rounds[-1] as Dictionary).get("ties", []) as Array):
		if bool((tie as Dictionary).get("two_legged", false)):
			return true
	return false


func _ratings_fn() -> Callable:
	return func(cid: int) -> Dictionary:
		return {"att": 50 + (cid % 7), "def": 50 + (cid % 5), "mid": 50 + (cid % 3),
			"gk": 50 + (cid % 4)}


func _names_fn() -> Callable:
	return func(cid: int) -> String:
		return "C%d" % cid


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL %s" % msg)
