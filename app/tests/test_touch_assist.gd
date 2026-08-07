extends SceneTree
## The phone touch-assist layer, gated: PMTouch.Drag's tap/scroll disambiguation and
## row conversion, PMTouch.near's grown hit rects, and Main's pinch-zoom transform —
## that a scaled root Control still routes a tap to the same DESIGN point, which is
## the invariant the whole zoom feature stands on.
##
##   ~/godot462 --headless --path app --script res://tests/test_touch_assist.gd

var _hits: Array = []


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# ---- PMTouch.Drag: a short travel stays a tap --------------------------
	var d := PMTouch.Drag.new()
	d.press(100.0, true)
	ok = _assert(d.update(103.0) == 0.0, "travel under slop yields no scroll") and ok
	ok = _assert(not d.release(), "under-slop gesture releases as a TAP") and ok

	# ---- ... a long travel is a scroll and swallows the tap ----------------
	d.press(100.0, true)
	d.update(110.0)                       # crosses slop; swallowed
	var dy := d.update(130.0)
	ok = _assert(absf(dy - 20.0) < 0.001, "post-slop motion reports its delta (got %f)" % dy) and ok
	ok = _assert(d.release(), "a scrolled gesture releases as a SCROLL") and ok
	ok = _assert(d.release(), "a stray duplicate release is swallowed too") and ok

	# ---- ... a press OFF the list never scrolls ----------------------------
	d.press(100.0, false)
	ok = _assert(d.update(200.0) == 0.0, "un-armed press reports no scroll") and ok
	ok = _assert(not d.release(), "un-armed long travel still dispatches the tap") and ok

	# ---- ... row conversion carries the remainder --------------------------
	d.press(100.0, true)
	d.take_rows(110.0, 20.0)              # slop swallow
	var r1 := d.take_rows(140.0, 20.0)    # +30 px -> -1 row, 10 px carried
	var r2 := d.take_rows(152.0, 20.0)    # +12 px, 22 total -> -1 row
	ok = _assert(r1 == -1 and r2 == -1, "20 px pitch: 30+12 px = two rows (got %d,%d)" % [r1, r2]) and ok
	d.release()

	# ---- PMTouch.near: the grown stepper rect ------------------------------
	var r := Rect2(600, 100, 12, 12)
	ok = _assert(PMTouch.near(r, Vector2(598, 98)), "a 2 px miss still hits the stepper") and ok
	ok = _assert(not PMTouch.near(r, Vector2(590, 98)), "a 10 px miss does not") and ok

	# ---- the pinch transform: a zoomed root still hit-tests the same point --
	# The window applies its own stretch transform to synthetic events, so the
	# test is self-referencing: tap once UNZOOMED and record where the child
	# says the finger is; zoom 2x ANCHORED on that very point (Main._pz_apply's
	# arithmetic — the canvas point under the fingers stays put); tap the same
	# window point again and the child must report the SAME design point.
	var root := Control.new()
	root.size = Vector2(640, 480)
	var child := Control.new()
	child.size = Vector2(640, 480)
	child.mouse_filter = Control.MOUSE_FILTER_STOP
	child.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventScreenTouch and e.pressed:
			_hits.append(e.position))
	root.add_child(child)
	get_root().add_child(root)
	await process_frame
	_tap(Vector2(10, 10))
	await process_frame
	await process_frame
	ok = _assert(_hits.size() == 1, "the unzoomed tap reaches the child (got %d)" % _hits.size()) and ok
	if _hits.size() == 1:
		var anchor: Vector2 = _hits[0]     # the finger's design point, unzoomed
		root.scale = Vector2(2, 2)
		root.position = anchor - (anchor - root.position) * 2.0
		await process_frame
		_tap(Vector2(10, 10))
		await process_frame
		await process_frame
		ok = _assert(_hits.size() == 2, "the zoomed tap reaches the child (got %d)" % _hits.size()) and ok
		if _hits.size() == 2:
			ok = _assert((_hits[1] as Vector2).distance_to(anchor) < 0.5,
				"zoomed 2x about the finger: the SAME design point is hit (got %s vs %s)"
				% [str(_hits[1]), str(anchor)]) and ok

	# ---- every screen that scrolls carries the drag ------------------------
	# The regression that matters after this session: a scrolling screen wired
	# by hand and then forgotten. Each file must declare a PMTouch.Drag AND
	# consume drag/motion events.
	for f in ["BrowseScreen", "CupDrawScreen", "DataBaseCardScreen", "HonoursScreen",
			"InsuranceScreen", "KnockoutScreen", "LineupScreen", "ManagerHistoryScreen",
			"OffersScreen", "ScoutScreen", "SquadScreen", "TrainingScreen"]:
		var src := FileAccess.get_file_as_string("res://scenes/%s.gd" % f)
		var has_drag := src.contains("PMTouch.Drag.new()") or src.contains("DRAG_SLOP")
		var reads_motion := src.contains("InputEventScreenDrag")
		ok = _assert(has_drag and reads_motion,
			"%s scrolls under a finger (drag=%s motion=%s)" % [f, has_drag, reads_motion]) and ok

	print("test_touch_assist: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _tap(win_pos: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = win_pos
	t.pressed = true
	Input.parse_input_event(t)
	var u := InputEventScreenTouch.new()
	u.index = 0
	u.position = win_pos
	u.pressed = false
	Input.parse_input_event(u)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
