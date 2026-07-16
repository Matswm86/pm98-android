extends SceneTree
## Headless test for the REBUILT CLUB PERSONNEL screen (StaffScreen.gd), frame-baked
## from walkthrough frame 121. Covers the chrome load (13 measured slot rects + the
## SIGN/SACK/RETURN buttons + the witnessed reference staff), the back-compat setup
## (the pre-rebuild Main Array call must not fault), the money formatter, and the
## frame-true hit-testing (role card -> role_selected, buttons -> their signals).
##   ~/godot462 --headless --path app --script res://tests/test_staff_screen.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var scr: StaffScreen = load("res://scenes/StaffScreen.gd").new()
	get_root().add_child(scr)
	await process_frame                  # StaffScreen._ready is deferred one frame here
	scr.size = Vector2(640, 480)         # scale 1, origin 0 -> design coords == screen coords

	# --- chrome / geometry ---
	ok = _assert(scr._slots.size() == 13, "13 staff slots loaded from the chrome JSON") and ok
	var expect := ["HANDLING", "PASSING", "DRIBBLING", "HEADING", "TACKLING", "SHOOTING",
		"PHYSIOTHERAPIST", "PSYCHOLOGIST", "ASSISTANT_MANAGER", "SCOUT",
		"YOUTH_TEAM_MANAGER", "YOUTH_TEAM_SCOUT", "GROUNDSMAN"]
	var have := true
	for r in expect:
		have = have and scr._slots.has(r)
	ok = _assert(have, "all 13 witnessed role keys present") and ok
	ok = _assert(scr._buttons.has("sign") and scr._buttons.has("sack") and scr._buttons.has("return"),
		"SIGN / SACK / RETURN buttons present") and ok
	ok = _assert(scr._body != null, "personnel_body.png baked chrome loaded") and ok

	# --- wage geometry (frame-121 ink-centred cells; shot_staff ref121 = 0px oracle) ---
	var wg := true
	for r in expect:
		var s: Dictionary = scr._slots[r]
		wg = wg and s.has("wage_cx") and s.has("wage_top") \
			and (s.get("wage_cell", []) as Array).size() == 4
	ok = _assert(wg, "every slot carries wage_cx/wage_top/wage_cell") and ok
	ok = _assert(int((scr._slots["PHYSIOTHERAPIST"] as Dictionary)["wage_cx"]) == 266
		and int((scr._slots["PSYCHOLOGIST"] as Dictionary)["wage_cx"]) == 374
		and int((scr._slots["HANDLING"] as Dictionary)["wage_cx"]) == 287
		and int((scr._slots["PASSING"] as Dictionary)["wage_cx"]) == 566,
		"wage cx anchors match the frame-121 ink centres (266/374/287/566)") and ok
	var fm: Dictionary = scr._spec.get("wage_font_metrics", {})
	var fmok := fm.size() >= 12
	for c in ["£", ",", "0", "1", "9"]:
		fmok = fmok and (fm.get(c, []) as Array).size() == 3
	ok = _assert(fmok, "wage_font_metrics carries ink insets for £ , 0-9") and ok

	# --- witnessed reference staff (frame 121) ---
	var ref := scr.reference_staff()
	ok = _assert(ref.size() == 13, "reference_staff has 13 members") and ok
	var shape := true
	for k in ref:
		var m: Dictionary = ref[k]
		shape = shape and m.has("name") and m.has("stars") and m.has("wage")
	ok = _assert(shape, "each reference member has name/stars/wage") and ok
	ok = _assert(str(ref.get("HANDLING", {}).get("name", "")) == "A. Padmore",
		"HANDLING trainer = A. Padmore (witnessed frame 121)") and ok
	ok = _assert(float(ref.get("YOUTH_TEAM_MANAGER", {}).get("stars", 0.0)) == 3.5,
		"YOUTH TEAM MANAGER D. Read = 3.5 stars (half-star witnessed)") and ok

	# --- money formatter ---
	ok = _assert(scr._money(17000) == "£17,000", "money 17000 -> £17,000") and ok
	ok = _assert(scr._money(4000) == "£4,000", "money 4000 -> £4,000") and ok

	# --- back-compat setup: the pre-rebuild Main Array call must not fault ---
	scr.setup([{"id": 1}], [{"id": 2}], "", "Arsenal", "£1,000")   # old positional shape
	ok = _assert(scr._personnel.is_empty(), "old Array setup -> empty personnel (all slots vacant)") and ok
	# new Dictionary call populates live data
	scr.setup({"SCOUT": {"name": "X", "stars": 2.0, "wage": 5000}}, "MGR", "CLUB", "1997-98", 3, 7)
	ok = _assert(scr._personnel.has("SCOUT") and scr._club == "CLUB" and scr._week == 3,
		"Dictionary setup populates personnel + header") and ok

	# --- hit-testing / signals ---
	ok = _tap(scr, Vector2(150, 121), "role_selected", "HANDLING") and ok
	ok = _tap(scr, Vector2(460, 323), "role_selected", "SCOUT") and ok
	ok = _tap(scr, Vector2(574, 451), "back_pressed", null) and ok
	ok = _tap(scr, Vector2(420, 427), "sign_pressed", null) and ok
	ok = _tap(scr, Vector2(420, 459), "sack_pressed", null) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


## Press+release at a design point; assert the named signal fired (with `arg` if given).
func _tap(scr: StaffScreen, p: Vector2, sig: String, arg) -> bool:
	var got := {"hit": false, "arg": null}
	var cb := func(a = null) -> void:
		got["hit"] = true
		got["arg"] = a
	scr.connect(sig, cb)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	scr._on_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = p
	scr._on_input(up)
	scr.disconnect(sig, cb)
	var ok: bool = got["hit"]
	if arg != null:
		ok = ok and str(got["arg"]) == str(arg)
	return _assert(ok, "%s at %s -> %s%s" % [sig, p, "fired" if got["hit"] else "MISS",
		(" arg=%s" % got["arg"]) if arg != null else ""])


func _assert(cond: bool, msg: String) -> bool:
	print("  %s %s" % ["[PASS]" if cond else "[FAIL]", msg])
	return cond
