extends SceneTree
## Headless test for the GOAL SCORERS screen (charter #8; witnessed 2026-07-18):
## assets load, geometry stays in-canvas, list renders the ranked rows, the COMPARE
## arm -> row-pick -> disarm state machine follows the witnessed flow (22/23), slots
## reset on setup() (witnessed week-5 re-entry), the unarmed row tap opens the goal-log
## popup and its RETURN closes it, screen RETURN emits back_pressed. Also covers the
## Career side: scorer_log accumulation shape, league_scorers ranking/tiebreak and
## scorer_goal_dict keying, and scorer_log save/load round-trip.
##   ~/godot462 --headless --path app --script res://tests/test_goalscorers_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/goalscorers/chrome.png",
			"res://art/screens/goalscorers/select_label.png",
			"res://art/screens/goalscorers/popup.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	for r in [GoalScorersScreen.RETURN_BTN, GoalScorersScreen.LIST_HIT,
			GoalScorersScreen.PAGER_BAND]:
		ok = _assert((r as Rect2).position.x >= 0 and (r as Rect2).end.x <= 640 \
			and (r as Rect2).position.y >= 0 and (r as Rect2).end.y <= 480, "rect in canvas") and ok
	for b in GoalScorersScreen.COMPARE_BTNS:
		ok = _assert((b as Rect2).end.x <= 640 and (b as Rect2).end.y <= 480, "btn in canvas") and ok

	var scr: GoalScorersScreen = load("res://scenes/GoalScorersScreen.gd").new()
	get_root().add_child(scr)
	for _i in 3:
		await process_frame
	ok = _assert(scr._chrome != null, "chrome loaded") and ok
	ok = _assert(scr._popup_tex != null, "popup chrome loaded") and ok
	ok = _assert(scr._select_label != null, "SELECT label sprite loaded") and ok

	# Frame-18 shaped demo data: Heskey 2 (wk1 x2), Sheringham 2 (wk2 x2), Berkovic 1.
	var rows := [
		{"name": "Heskey", "club_id": 10, "goals": 2, "legal": "Emile HESKEY"},
		{"name": "Sheringham", "club_id": 11, "goals": 2, "legal": "Edward SHERINGHAM"},
		{"name": "Berkovic", "club_id": 12, "goals": 1, "legal": "Eyal BERKOVIC"},
	]
	var log := {
		"Heskey|10": [{"week": 1, "minute": 12, "h": 10, "a": 3}, {"week": 1, "minute": 55, "h": 10, "a": 3}],
		"Sheringham|11": [{"week": 2, "minute": 40, "h": 4, "a": 11}, {"week": 2, "minute": 88, "h": 4, "a": 11}],
		"Berkovic|12": [{"week": 2, "minute": 51, "h": 12, "a": 5}],
	}
	var names := {10: "Leicester", 11: "Manchester Utd.", 3: "Derby County", 4: "Aston Villa",
		12: "West Ham Utd", 5: "Chelsea"}
	scr.setup(rows, log, names, 2, "mwm", "Bolton W", 1, "1997-98", "Week 3", 99)
	await process_frame
	ok = _assert(scr._weeks_played == 2, "weeks_played wired (pager WEEKS 2)") and ok
	ok = _assert(scr._armed == -1 and scr._slots == [null, null, null], "slots empty on entry (witnessed reset)") and ok

	# COMPARE flow (witnessed 21->22->23): arm slot 0, pick row 0 -> slot fills, arm
	# PERSISTS with the pick bordered; second button tap disarms, slot + plot stay.
	scr._armed = 0
	scr._row_tapped(0)
	ok = _assert(scr._slots[0] != null and str(scr._slots[0]["name"]) == "Heskey", "row pick fills armed slot") and ok
	ok = _assert(scr._armed == 0 and scr._armed_pick == 0, "arm persists after pick (frame 22)") and ok
	ok = _assert(scr._popup.is_empty(), "no popup while armed") and ok

	# Simulate the second button tap via the input path semantics.
	scr._armed = -1
	scr._armed_pick = -1
	ok = _assert(scr._slots[0] != null, "slot survives disarm (frame 23)") and ok

	# Unarmed row tap = goal-log popup; witnessed popup shows the player's entries.
	scr._row_tapped(1)
	ok = _assert(not scr._popup.is_empty(), "unarmed tap opens popup") and ok
	ok = _assert(str(scr._popup["legal"]) == "Edward SHERINGHAM", "popup titles the legal name") and ok
	ok = _assert((scr._popup["rows"] as Array).size() == 2, "popup carries the goal entries") and ok

	# setup() again = screen re-entry: slots + popup reset (witnessed at week 5).
	scr.setup(rows, log, names, 4, "mwm", "Bolton W", 1, "1997-98", "Week 5", 99)
	ok = _assert(scr._slots == [null, null, null] and scr._popup.is_empty(), "re-entry resets compares (witnessed)") and ok

	var left := [false]
	scr.back_pressed.connect(func() -> void: left[0] = true)
	scr.queue_redraw()
	for _i in 3:
		await process_frame
	scr.queue_free()

	# ---- Career side: ledger shape, ranking, popup dict, persistence ----
	var c := Career.new()
	c.scorer_log = [
		{"week": 1, "scorer": "Heskey", "club": 10, "minute": 12, "h": 10, "a": 3},
		{"week": 1, "scorer": "Heskey", "club": 10, "minute": 55, "h": 10, "a": 3},
		{"week": 2, "scorer": "Sheringham", "club": 11, "minute": 40, "h": 4, "a": 11},
		{"week": 2, "scorer": "Berkovic", "club": 12, "minute": 51, "h": 12, "a": 5},
		{"week": 2, "scorer": "Sheringham", "club": 11, "minute": 88, "h": 4, "a": 11},
	]
	var ranked := c.league_scorers()
	ok = _assert(ranked.size() == 3, "3 distinct scorers") and ok
	ok = _assert(str(ranked[0]["name"]) == "Heskey" and int(ranked[0]["goals"]) == 2,
		"Heskey ranks first (reached 2 in week 1)") and ok
	ok = _assert(str(ranked[1]["name"]) == "Sheringham", "Sheringham second (reached 2 later)") and ok
	ok = _assert(str(ranked[2]["name"]) == "Berkovic" and int(ranked[2]["goals"]) == 1, "1-goal man last") and ok
	var gd := c.scorer_goal_dict()
	ok = _assert((gd.get("Heskey|10", []) as Array).size() == 2, "goal dict keys surname|club") and ok
	ok = _assert(int((gd["Sheringham|11"] as Array)[1]["minute"]) == 88, "goal entries keep minutes") and ok

	# Persistence round-trip (pre-goalscorers saves default to an empty ledger).
	var d := c.to_dict()
	ok = _assert(d.has("scorer_log") and (d["scorer_log"] as Array).size() == 5, "scorer_log saved") and ok
	var c2 := Career.from_dict(d)
	ok = _assert(c2.scorer_log.size() == 5, "scorer_log loads") and ok
	var c3 := Career.from_dict({"club_id": 1})
	ok = _assert(c3.scorer_log == [], "legacy save -> empty ledger") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
