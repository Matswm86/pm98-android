extends SceneTree
## Headless wiring test for the corrected TEAM TACTICS modal (TeamTacticsScreen —
## source-true ATTACK|DEFENCE art from the RECURSOS EQWIN cluster; the modal is
## un-walked so its layout is a documented reconstruction, but its control SET is
## authoritative from MANAGER.EXE 0x25ff3c..0x260014). Confirms it mounts with a
## live career Tactics, builds a hit-rect for every source-true control, that a
## simulated click on each mutates the Tactics through the right setter, and that
## `changed` fires on levers while the EQWINX close fires `done`.
##   ~/godot462 --headless --path app --script res://tests/test_tactics_screen.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_assert(false, "game_db.json present")
		quit(1)
		return
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var club: Dictionary = {}
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem" and (c.get("players", []) as Array).size() >= 14:
			club = c
			break
	ok = _assert(not club.is_empty(), "found a Premier club with a full squad") and ok

	var t := Tactics.auto_pick(club, "4-4-2")
	var screen: TeamTacticsScreen = load("res://scenes/TeamTacticsScreen.gd").new()
	screen.size = Vector2(800, 600)
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null, "PROMAN fonts loaded into screen") and ok
	# the source-true checkbox spec loaded from the bake's samples json
	ok = _assert(not screen._cbx.is_empty(), "checkbox spec loaded from samples json") and ok

	screen.setup(t)
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	ok = _assert(screen._hits.size() >= 12, "modal built its control hit-rects (%d)" % screen._hits.size()) and ok

	# Every source-true control kind is present and reachable.
	var kinds: Dictionary = {}
	for h in screen._hits:
		kinds[str(h["kind"])] = true
	for k in ["mentality", "tackling", "marking", "clearances", "pressurise",
			"pass_inc", "pass_dec", "cnt_inc", "cnt_dec", "close"]:
		ok = _assert(kinds.has(k), "control present: %s" % k) and ok

	# Track the signals.
	var fired := {"changed": 0, "done": 0}
	screen.changed.connect(func(_d): fired["changed"] += 1)
	screen.done.connect(func(): fired["done"] += 1)

	# Clicking each radio sets that lever (values from the binary string block).
	screen._apply("mentality", "Attacking")
	ok = _assert(t.mentality == "Attacking", "click ATTACKING set mentality") and ok
	screen._apply("tackling", "Aggressive")
	ok = _assert(t.tackling == "Aggressive", "click AGGRESSIVE set tackling") and ok
	screen._apply("marking", "Man-to-man")
	ok = _assert(t.marking == "Man-to-man", "click MAN-TO-MAN set marking") and ok
	screen._apply("clearances", "Long")
	ok = _assert(t.clearances == "Long", "click LONG set clearances") and ok
	screen._apply("pressurise", "Opponent")
	ok = _assert(t.pressurise == "Opponent", "click OPPONENT set pressurise") and ok

	# Steppers move the sliders by STEP and clamp.
	var p0: int = t.passing_pct
	screen._apply("pass_inc", null)
	ok = _assert(t.passing_pct == mini(p0 + TeamTacticsScreen.STEP, 100), "pass + steps up") and ok
	screen._apply("pass_dec", null)
	ok = _assert(t.passing_pct == p0, "pass - steps back") and ok
	var c0: int = t.counter_pct
	screen._apply("cnt_inc", null)
	ok = _assert(t.counter_pct == mini(c0 + TeamTacticsScreen.STEP, 100), "counter + steps up") and ok

	# Each lever should have emitted `changed` (not done).
	ok = _assert(fired["changed"] >= 8, "mutations emitted `changed` (%d)" % fired["changed"]) and ok

	# The EQWINX close fires `done` (the modal's only exit control).
	screen._apply("close", null)
	ok = _assert(fired["done"] == 1, "close (EQWINX) emitted done") and ok

	# Hit-test math: the close rect contains its centre.
	ok = _assert(TeamTacticsScreen.CLOSE.has_point(TeamTacticsScreen.CLOSE.get_center()),
		"CLOSE rect contains its centre") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
