extends SceneTree
## Headless test for MATCH OPTIONS (MatchOptions.gd) -- the hub's tabbed settings dialog
## (the real modal, all four tabs cut verbatim to art/screens/matchflow/mo_modal*.png).
## Asserts: the four tab sprites load; the tab row switches tab; the MATCH tab's
## WATCH/HIGHLIGHTS/BRIEF/RESULTS row selects a view mode (no proceed) and OK confirms it
## with the control block; HIGHLIGHTS (3D .p3d absent) selects but cannot be confirmed;
## the GRAPHICS/CAMERAS/SOUND sub-controls toggle/select + ride through OK; CANCEL discards.
##   ~/godot462 --headless --path app --script res://tests/test_match_options.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	for path in ["res://art/screens/matchflow/mo_modal.png",
			"res://art/screens/matchflow/mo_modal_graphics.png",
			"res://art/screens/matchflow/mo_modal_cameras.png",
			"res://art/screens/matchflow/mo_modal_sound.png",
			"res://art/fonts/proman10.fnt"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok

	var opt: MatchOptions = load("res://scenes/MatchOptions.gd").new()
	get_root().add_child(opt)
	opt.size = Vector2(640, 480)
	for _i in 3:
		await process_frame

	ok = _assert(opt._tabtex.size() == 4 and opt._tabtex[0] != null and opt._tabtex[3] != null,
		"four tab sprites loaded") and ok
	ok = _assert(opt.SRC_RECTS[0] == Rect2(5, 100, 98, 25) and opt.SRC_RECTS[3] == Rect2(317, 100, 98, 25),
		"reversed source view-rects recorded") and ok

	var got: Array = []
	var cancelled := [false]
	opt.confirmed.connect(func(m: String, s: Dictionary) -> void: got.append([m, s]))
	opt.cancelled.connect(func() -> void: cancelled[0] = true)

	# ---- MATCH tab: view-mode row hit-tests + selection --------------------
	opt.setup("results")
	ok = _assert(opt._tab == 0 and opt._sel == opt.MODES.find("results"),
		"setup opens MATCH tab on the stored mode") and ok
	for m in ["watch", "highlights", "brief", "results", "cancel", "ok"]:
		var c: Vector2 = opt._rect(m).get_center()
		ok = _assert(opt._hit(c) == m, "%s hit-tests to itself" % m) and ok
	ok = _assert(opt._hit(Vector2(2, 2)) == "", "outside the modal is dead space") and ok

	_tap_at(opt, opt._rect("watch").get_center())
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("watch"), "WATCH tap selects, no emit") and ok
	_tap_at(opt, opt._rect("brief").get_center())
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("brief"), "BRIEF tap selects, no emit") and ok

	# ---- tab switching (live on every tab) --------------------------------
	_tap_hit(opt, "tab:graphics")
	ok = _assert(opt._tab == 1, "tab row switches to GRAPHICS") and ok
	# a GRAPHICS control is now hittable; a MATCH view button is not
	ok = _assert(opt._hit(opt.GFX_TOGGLES["gfx_sky"].get_center()) == "gfx_sky",
		"GRAPHICS: SKY toggle hittable on its tab") and ok
	ok = _assert(opt._hit(opt.PITCH["med"].get_center()) == "pitch:med",
		"GRAPHICS: PITCH DETAIL MED hittable") and ok

	# ---- GRAPHICS controls toggle / select --------------------------------
	ok = _assert(bool(opt._s["gfx_sky"]) == true, "SKY defaults ON") and ok
	_tap_hit(opt, "gfx_sky")
	ok = _assert(bool(opt._s["gfx_sky"]) == false, "SKY tap toggles OFF") and ok
	_tap_hit(opt, "pitch:min")
	ok = _assert(str(opt._s["pitch_detail"]) == "min", "PITCH DETAIL selects MIN") and ok
	_tap_hit(opt, "stad:low")
	ok = _assert(str(opt._s["stadium_detail"]) == "low", "STADIUM DETAIL selects LOW") and ok

	# ---- CAMERAS controls -------------------------------------------------
	_tap_hit(opt, "tab:cameras")
	ok = _assert(opt._tab == 2, "tab row switches to CAMERAS") and ok
	_tap_hit(opt, "cam:auto")
	ok = _assert(str(opt._s["camera_mode"]) == "auto", "CAMERAS selects AUTO") and ok
	_tap_hit(opt, "cam:auto")
	ok = _assert(str(opt._s["camera_mode"]) == "static", "re-tap AUTO releases to STATIC") and ok

	# ---- SOUND controls ---------------------------------------------------
	_tap_hit(opt, "tab:sound")
	ok = _assert(opt._tab == 3, "tab row switches to SOUND") and ok
	_tap_hit(opt, "snd_ambient")
	ok = _assert(bool(opt._s["snd_ambient"]) == false, "SOUND AMBIENT tap toggles OFF") and ok

	# ---- OK confirms mode + the whole control block -----------------------
	_tap_hit(opt, "ok")
	ok = _assert(got.size() == 1, "OK emits confirmed once") and ok
	if got.size() == 1:
		ok = _assert(got[0][0] == "brief", "OK confirms the selected view mode (brief)") and ok
		var s: Dictionary = got[0][1]
		ok = _assert(s["gfx_sky"] == false and s["pitch_detail"] == "min"
			and s["stadium_detail"] == "low" and s["snd_ambient"] == false
			and s["camera_mode"] == "static",
			"OK carries the mutated control block") and ok

	# ---- HIGHLIGHTS can be selected but not confirmed (3D .p3d absent) -----
	got.clear()
	opt.setup("brief")
	_tap_at(opt, opt._rect("highlights").get_center())
	ok = _assert(opt._sel == opt.MODES.find("highlights") and opt._note != "",
		"HIGHLIGHTS selects + notes 3D-absent") and ok
	_tap_hit(opt, "ok")
	ok = _assert(got.is_empty(), "OK does not confirm HIGHLIGHTS (3D absent)") and ok

	# ---- CANCEL discards ---------------------------------------------------
	_tap_hit(opt, "cancel")
	ok = _assert(cancelled[0], "CANCEL emits cancelled") and ok

	# press on one target, release on another -> no fire / no change
	got.clear()
	opt.setup("brief")
	opt._on_input(_touch(opt._rect("brief").get_center(), true))
	opt._on_input(_touch(opt._rect("results").get_center(), false))
	ok = _assert(got.is_empty() and opt._sel == opt.MODES.find("brief"),
		"press/release on different targets does not fire") and ok

	opt.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _tap_at(opt: MatchOptions, c: Vector2) -> void:
	opt._on_input(_touch(c, true))
	opt._on_input(_touch(c, false))


## Tap the centre of whatever rect the named hit-target resolves to.
func _tap_hit(opt: MatchOptions, target: String) -> void:
	_tap_at(opt, opt._press_rect(target).get_center())


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	return e


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
