extends SceneTree
## Headless smoke test for the match commentary feed.
##   ~/godot462 --headless --path app --script res://tests/test_commentary.gd
## Asserts the timeline is well-formed (phase markers present, goal lines match
## the scoreline, minutes in range, lines minute-ordered) and prints one feed.

const SEED := 20240615


func _initialize() -> void:
	quit(0 if _run() else 1)


func _premier_clubs() -> Array:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	var out: Array = []
	for c in (parsed as Dictionary).get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			out.append(c)
	return out


func _run() -> bool:
	var clubs := _premier_clubs()
	if clubs.size() < 2:
		push_error("need >=2 clubs, got %d" % clubs.size())
		return false
	var home: Dictionary = clubs[0]
	var away: Dictionary = clubs[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var m := MatchCommentary.timeline(rng, home, away)
	var lines: Array = m["lines"]
	print("=== %s %d : %d %s ===" % [home["name"], m["home_goals"], m["away_goals"], away["name"]])
	for ln in lines:
		var side: int = ln["side"]
		var tag := "--" if side == -1 else ("H" if side == 0 else "A")
		print("  %2d' [%s] %s%s" % [ln["minute"], tag, ln["text"], "  *GOAL*" if ln.get("goal") else ""])

	var ok := true
	# 1) phase markers KICK OFF + FULL TIME present
	var has_ko := false
	var has_ft := false
	for ln in lines:
		if ln["side"] == -1 and (ln["text"] as String).begins_with(MatchCommentary.P_KICK_OFF):
			has_ko = true
		if ln["side"] == -1 and (ln["text"] as String).begins_with(MatchCommentary.P_FULL_TIME):
			has_ft = true
	ok = _assert(has_ko and has_ft, "kick-off + full-time markers present") and ok
	# 2) goal-tagged lines per side == scoreline
	var hg := 0
	var ag := 0
	for ln in lines:
		if ln.get("goal"):
			if ln["side"] == 0:
				hg += 1
			else:
				ag += 1
	ok = _assert(hg == m["home_goals"] and ag == m["away_goals"],
		"goal lines (%d/%d) match scoreline (%d/%d)" % [hg, ag, m["home_goals"], m["away_goals"]]) and ok
	# 3) minutes within [0,90], event lines minute-ordered
	var prev := -1
	var ordered := true
	for ln in lines:
		var mn: int = ln["minute"]
		if mn < 0 or mn > 90:
			ok = _assert(false, "minute %d out of range" % mn) and ok
		if mn < prev:
			ordered = false
		prev = mn
	ok = _assert(ordered, "lines are minute-ordered") and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
