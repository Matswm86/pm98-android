extends SceneTree
## The M5 WIRE-IN gate: `Pm98LiveMatch` must build a real fixture from career data, expose
## in-pitch coordinates every frame, and reach the binary's own full-time dispatch with a
## scoreline the event queue agrees with.
##
## Also pins the ROUTING fact the wire-in rests on (`stat_match_engine_re.md`): the
## positional engine is the WATCH engine, and `MatchSim` keeps routing every other fixture
## to `Pm98StatMatch`, the port of the original's own `PS == 5` instant-result branch.
##
## Run: ~/godot462 --headless --path app --script res://tests/test_live_match.gd

const HOME_ID := 40      # Manchester Utd.
const AWAY_ID := 42      # Liverpool

var _fail := 0


func _init() -> void:
	var live := Pm98LiveMatch.create(HOME_ID, AWAY_ID, 1)
	_ck(live != null and not live.match_state.is_empty(), "live match builds")
	_ck((live.match_state["sim"][0] as Dictionary).get("players", []).size() == 11,
		"home XI has 11 players")
	_ck((live.match_state["sim"][1] as Dictionary).get("players", []).size() == 11,
		"away XI has 11 players")

	# Kickoff frame: every player and the ball must sit INSIDE the pitch, and the ball on
	# the deck at the centre spot.
	_positions_in_pitch(live, "at kickoff")
	var b0 := live.ball_position()
	_ck(absf(float(b0["nx"]) - 0.5) < 0.02 and absf(float(b0["ny"]) - 0.5) < 0.02,
		"ball starts on the centre spot (got %.3f, %.3f)" % [b0["nx"], b0["ny"]])
	_ck(absf(float(b0["height"])) < 0.01, "ball starts on the ground")

	# The clock must actually run, and positions must actually move.
	var before := live.player_positions()
	live.advance(400)
	_ck(live.frames == 400, "400 frames stepped (got %d)" % live.frames)
	var after := live.player_positions()
	var moved := 0
	for i in mini(before.size(), after.size()):
		if absf(float(after[i]["nx"]) - float(before[i]["nx"])) > 0.0005 \
				or absf(float(after[i]["ny"]) - float(before[i]["ny"])) > 0.0005:
			moved += 1
	_ck(moved >= 10, "the roster moves under the engine (%d of 22 players)" % moved)
	_positions_in_pitch(live, "after 400 frames")

	# The two FULL-TIME runs below are ~5 minutes of CPU each (18,458 outer frames per
	# match at ~64 frames/s on the 2026-07-28 desktop), so they are opt-in: CI runs the
	# fast half above, and `PM98_LIVE_FULL=1` runs the whole thing as the pre-release gate.
	if OS.get_environment("PM98_LIVE_FULL") == "":
		print("  (full-time + determinism SKIPPED: set PM98_LIVE_FULL=1 to run them)")
		print("test_live_match: %s" % ("ALL PASS" if _fail == 0 else "%d FAILURE(S)" % _fail))
		quit(1 if _fail > 0 else 0)
		return

	# Full time: the binary's own dispatch 10, a minute at or past 90, and a scoreline the
	# harvested goal list agrees with.
	live.run_to_full_time()
	_ck(live.over, "reaches full time")
	_ck(int(live.match_state.get(0x1a38, 0)) == Pm98LiveMatch.FULL_TIME_DISPATCH,
		"full time is dispatch 10")
	_ck(live.minute() >= 90, "clock reaches 90' (got %d)" % live.minute())
	var counted := [0, 0]
	for g in live.goals:
		counted[int(g["team"])] += 1
	_ck(counted == live.score, "goal list matches the score (%s vs %s)" % [counted, live.score])
	print("  full time %d-%d in %d frames, minute %d, %d goal event(s)" % [
		live.score[0], live.score[1], live.frames, live.minute(), live.goals.size()])

	# Determinism: the same seed must replay the same match.
	var again := Pm98LiveMatch.create(HOME_ID, AWAY_ID, 1)
	again.run_to_full_time()
	_ck(again.score == live.score and again.frames == live.frames,
		"same seed replays the same match (%s/%d vs %s/%d)" % [
			again.score, again.frames, live.score, live.frames])

	# ROUTING: a non-watched fixture stays on the statistical engine, which is what the
	# original does for it (FUN_0044ee70's PS == 5 branch).
	_ck(MatchSim.use_stat_engine, "MatchSim still routes non-watched fixtures to Pm98StatMatch")

	print("test_live_match: %s" % ("ALL PASS" if _fail == 0 else "%d FAILURE(S)" % _fail))
	quit(1 if _fail > 0 else 0)


func _positions_in_pitch(live: Pm98LiveMatch, when: String) -> void:
	var bad := 0
	for p in live.player_positions():
		var nx := float(p["nx"])
		var ny := float(p["ny"])
		if nx <= 0.0 or nx >= 1.0 or ny <= 0.0 or ny >= 1.0:
			bad += 1
	_ck(bad == 0, "every player inside the pitch %s (%d outside)" % [when, bad])


func _ck(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		printerr("  FAIL: %s" % msg)
