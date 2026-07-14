extends SceneTree
## Headless test for the CLUB PERSONNEL hire overlay (StaffHireOverlay.gd), frame-baked
## from walkthrough frames 100 + 108-119 (docs/re/staff_re.md). Covers the chrome/spec load
## (7 single-role plates + the TRAINERS spec + rail/holder/rows geometry), setup (category ->
## plate + live holder + candidates), and the frame-true hit-testing: a rail category button
## -> category_selected, a green SIGN button -> sign_candidate(id), OK / tap-outside ->
## ok_pressed, TRAINERS opening its 6-skill layout, and the skill picker -> skill_selected.
##   ~/godot462 --headless --path app --script res://tests/test_staff_overlay.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var ov: StaffHireOverlay = load("res://scenes/StaffHireOverlay.gd").new()
	get_root().add_child(ov)
	await process_frame
	ov.size = Vector2(640, 480)          # scale 1, origin 0 -> design coords == screen coords

	# --- chrome / spec ---
	ok = _assert(not ov._s.is_empty(), "overlay_chrome.json single spec loaded") and ok
	var cats: Array = ov._s.get("cats", [])
	ok = _assert(cats.size() == 8 and cats[0] == "TRAINERS" and cats[4] == "SCOUT",
		"8-category rail, TRAINERS first, SCOUT at index 4") and ok
	var plates: Dictionary = ov._s.get("plates", {})
	ok = _assert(plates.size() == 7, "7 single-role plates in the spec") and ok

	# --- setup: filled ASSISTANT_MANAGER (frame-113 data) ---
	ov.setup("ASSISTANT_MANAGER", {"name": "A. Leigh", "stars": 4.0, "wage": 16000},
		[{"id": 11, "name": "P. Wright", "stars": 2.0, "wage": 7000},
		 {"id": 12, "name": "L. Malik", "stars": 2.5, "wage": 9000}])
	await process_frame
	ok = _assert(ov._cat == "ASSISTANT_MANAGER", "category set to ASSISTANT_MANAGER") and ok
	ok = _assert(ov._plate != null, "the ASSISTANT_MANAGER plate loaded") and ok
	ok = _assert(not ov._holder.is_empty() and ov._cands.size() == 2,
		"holder + 2 candidates set") and ok
	ok = _assert(ov._money(16000) == "£16,000", "money 16000 -> £16,000") and ok

	# --- hit-testing / signals (design coords) ---
	# rail: button i -> rect (452, 104 + i*30, 123, 22). i=1 PHYSIO, i=4 SCOUT, i=0 TRAINERS.
	ok = _tap(ov, Vector2(513, 145), "category_selected", "PHYSIOTHERAPIST") and ok
	ok = _tap(ov, Vector2(513, 235), "category_selected", "SCOUT") and ok
	# a SIGN button (row 0 rect [95,300,88,17]) signs that candidate's id.
	ok = _tap(ov, Vector2(139, 308), "sign_candidate", 11) and ok
	# OK button rect [478,360,90,28] and a tap OUTSIDE the dialog both close.
	ok = _tap(ov, Vector2(523, 374), "ok_pressed", null) and ok
	ok = _tap(ov, Vector2(20, 20), "ok_pressed", null) and ok
	# TRAINERS (i=0) rail now opens the 6-skill layout -> tapping it emits category_selected.
	ok = _tap(ov, Vector2(513, 115), "category_selected", "TRAINERS") and ok

	# --- vacant setup: no holder drawn, candidates still hireable ---
	ov.setup("GROUNDSMAN", {}, [{"id": 21, "name": "R. Dongle", "stars": 3.0, "wage": 2000}])
	await process_frame
	ok = _assert(ov._holder.is_empty() and ov._cat == "GROUNDSMAN",
		"vacant GROUNDSMAN: empty holder, category set") and ok
	ok = _tap(ov, Vector2(139, 308), "sign_candidate", 21) and ok

	# --- TRAINERS layout (frame 100): 6 coaches + skill-filtered pool ---
	ok = _assert(not ov._t.is_empty(), "overlay_chrome.json trainers spec loaded") and ok
	ok = _assert(ov._t.get("skills", []).size() == 6
		and ov._t.get("picker", {}).get("rects", []).size() == 6,
		"6 skills + 6 picker rects") and ok
	ov.setup("TRAINERS", {},
		[{"id": 30, "name": "P. Wren", "stars": 4.5, "wage": 41000},
		 {"id": 31, "name": "L. Gledhill", "stars": 1.0, "wage": 3000}],
		{"HANDLING": {"name": "A. Padmore", "stars": 3.0, "wage": 17000},
		 "PASSING": {"name": "D. Gledhill", "stars": 4.5, "wage": 34000}},
		"DRIBBLING")
	await process_frame
	ok = _assert(ov._mode == "trainers" and ov._cat == "TRAINERS", "mode=trainers, cat=TRAINERS") and ok
	ok = _assert(ov._plate != null, "the TRAINERS plate loaded") and ok
	ok = _assert(ov._skill == "DRIBBLING" and ov._coaches.size() == 2 and ov._cands.size() == 2,
		"selected skill + 2 coaches + 2 candidates set") and ok
	# skill picker: HANDLING [112,338,82,26] center (153,351); PASSING (253,351); DRIBBLING (353,351).
	ok = _tap(ov, Vector2(153, 351), "skill_selected", "HANDLING") and ok
	ok = _tap(ov, Vector2(253, 351), "skill_selected", "PASSING") and ok
	ok = _tap(ov, Vector2(153, 383), "skill_selected", "HEADING") and ok
	# tapping the ALREADY-selected skill (DRIBBLING, 353,351) must NOT re-emit.
	ok = _tap_silent(ov, Vector2(353, 351), "skill_selected") and ok
	# AVAILABLE SIGN row0 [94,273,86,16] center (137,281) signs candidate 30.
	ok = _tap(ov, Vector2(137, 281), "sign_candidate", 30) and ok
	# a rail category (PHYSIO i=1) still switches away; OK closes.
	ok = _tap(ov, Vector2(513, 145), "category_selected", "PHYSIOTHERAPIST") and ok
	ok = _tap(ov, Vector2(523, 374), "ok_pressed", null) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _fire(ov: StaffHireOverlay, p: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	ov._on_input(down)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = p
	ov._on_input(up)


func _tap(ov: StaffHireOverlay, p: Vector2, sig: String, arg) -> bool:
	var got := {"hit": false, "arg": null}
	var cb := func(a = null) -> void:
		got["hit"] = true
		got["arg"] = a
	ov.connect(sig, cb)
	_fire(ov, p)
	ov.disconnect(sig, cb)
	var ok: bool = got["hit"]
	if arg != null:
		ok = ok and str(got["arg"]) == str(arg)
	return _assert(ok, "%s at %s -> %s%s" % [sig, p, "fired" if got["hit"] else "MISS",
		(" arg=%s" % got["arg"]) if arg != null else ""])


## Assert that tapping `p` does NOT emit `sig`.
func _tap_silent(ov: StaffHireOverlay, p: Vector2, sig: String) -> bool:
	var got := {"hit": false}
	var cb := func(_a = null) -> void:
		got["hit"] = true
	ov.connect(sig, cb)
	_fire(ov, p)
	ov.disconnect(sig, cb)
	return _assert(not got["hit"], "TRAINERS tap is inert (no %s)" % sig)


func _assert(cond: bool, msg: String) -> bool:
	print("  %s %s" % ["[PASS]" if cond else "[FAIL]", msg])
	return cond
