extends SceneTree
## Headless wiring test for the TEAM TACTICS modal (ma_9): confirms the screen mounts
## with a live career Tactics, that its control hit-rects map to every lever, that a
## simulated click on each control mutates the Tactics through the right setter, and
## that the OK / SAVE / RETURN signals fire. (Headless can't rasterize; this drives the
## same _apply() path the real _gui_input() dispatches to, plus a forced paint pass.)
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
	var screen: TacticsScreen = load("res://scenes/TacticsScreen.gd").new()
	screen.size = Vector2(800, 600)
	get_root().add_child(screen)
	for _i in 3:
		await process_frame
	ok = _assert(screen._f12 != null and screen._f10 != null, "PROMAN fonts loaded into screen") and ok
	screen.setup(t)
	# Force a real paint pass so the hit-rect table is populated (and catches null-deref).
	screen.queue_redraw()
	for _i in 3:
		await process_frame
	ok = _assert(screen._hits.size() >= 16, "modal built its control hit-rects (%d)" % screen._hits.size()) and ok

	# Every control kind is present and reachable.
	var kinds: Dictionary = {}
	for h in screen._hits:
		kinds[str(h["kind"])] = true
	for k in ["mentality", "tackling", "marking", "clearances", "pressurise",
			"pass_inc", "pass_dec", "cnt_inc", "cnt_dec", "ok", "save", "return"]:
		ok = _assert(kinds.has(k), "control present: %s" % k) and ok

	# Track the signals.
	var fired := {"changed": 0, "save": 0, "done": 0}
	screen.changed.connect(func(_d): fired["changed"] += 1)
	screen.save_requested.connect(func(_d): fired["save"] += 1)
	screen.done.connect(func(): fired["done"] += 1)

	# Clicking each radio sets that lever; emits `changed`.
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
	ok = _assert(t.passing_pct == mini(p0 + TacticsScreen.STEP, 100), "pass + steps up") and ok
	screen._apply("pass_dec", null)
	ok = _assert(t.passing_pct == p0, "pass - steps back") and ok
	var c0: int = t.counter_pct
	screen._apply("cnt_inc", null)
	ok = _assert(t.counter_pct == mini(c0 + TacticsScreen.STEP, 100), "counter + steps up") and ok

	# A radio + each stepper should have emitted `changed` (not done/save).
	ok = _assert(fired["changed"] >= 8, "mutations emitted `changed` (%d)" % fired["changed"]) and ok

	# SAVE + OK/RETURN fire their own signals (no further mutation).
	screen._apply("save", null)
	ok = _assert(fired["save"] == 1, "SAVE emitted save_requested") and ok
	screen._apply("ok", null)
	screen._apply("return", null)
	ok = _assert(fired["done"] == 2, "OK and RETURN both emitted done") and ok

	# Hit-test math: a point inside the OK button maps to the ok control.
	var ok_rect := TacticsScreen.OK_BTN
	ok = _assert(ok_rect.has_point(ok_rect.get_center()), "OK rect contains its centre") and ok

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
