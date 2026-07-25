extends SceneTree
## YOUTH TEAM screen (frame-true rebuild, 2026-07-16) — headless asserts for the
## chrome geometry + live-layer states decoded from walkthrough frames 087-089 (run1,
## empty) and 047-048 (run3, scout searching). The pixel gate lives in
## tools/re/diff_youth_parity.py (5 shots, body 0px); this covers logic + wiring.

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# --- chrome json: binding frames + geometry present ---
	var f := FileAccess.open("res://art/screens/youth/youth_chrome.json", FileAccess.READ)
	ok = _assert(f != null, "youth_chrome.json exists") and ok
	var spec: Dictionary = {}
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		ok = _assert(typeof(parsed) == TYPE_DICTIONARY, "chrome json parses") and ok
		spec = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	var bf: Dictionary = spec.get("binding_frames", {})
	ok = _assert(str(bf.get("empty", "")) == "087_154632.png", "empty binding = frame 087") and ok
	ok = _assert(str(bf.get("live", "")) == "047_164509.png", "live binding = frame 047") and ok
	ok = _assert((spec.get("cap_order", []) as Array).size() == 6, "6 capability skills") and ok
	ok = _assert((spec.get("rows", {}) as Dictionary).get("count", 0) == 11, "11 roster rows") and ok
	for b in ["search", "parameters", "rating", "return"]:
		ok = _assert((spec.get("buttons", {}) as Dictionary).has(b), "button rect: %s" % b) and ok
	# witnessed verbatim messages
	ok = _assert(str((spec.get("pf_msg_no_scout", []) as Array)[0]) == "You need to hire a scout",
		"hire-scout message line 1 verbatim") and ok
	ok = _assert(str((spec.get("pf_msg_searching", []) as Array)[0])
		== "The scout is now searching for players", "searching message line 1 verbatim") and ok
	# both game faces carry ink metrics for the live text layer
	var fm: Dictionary = spec.get("font_metrics", {})
	ok = _assert((fm.get("proman8", {}) as Dictionary).has("N"), "proman8 ink metrics") and ok
	ok = _assert((fm.get("proman10", {}) as Dictionary).has("e"), "proman10 ink metrics") and ok

	# --- screen state machine ---
	var scr: YouthScreen = load("res://scenes/YouthScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	await process_frame

	# fresh career: no staff -> 087 state
	scr.setup([], [], "MWM", "Manchester Utd.", "1997-98", 1, -1)
	ok = _assert(scr._scout.is_empty() and scr._ymgr.is_empty(), "no staff -> empty bars") and ok
	ok = _assert(scr._mode == "parameters", "default mode = PARAMETERS (frame 087)") and ok

	# scout + manager hired -> 047 state inputs
	var staff := [
		{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "P. Mitchell", "stars": 5.0, "wage": 40000},
		{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "G. Keeping", "stars": 3.5, "wage": 20000},
	]
	scr.setup([], staff, "asdf", "Manchester Utd.", "1997-98", 2, -1, true,
		{"DRIBBLING": true, "PASSING": true, "SHOOTING": true})
	ok = _assert(str(scr._scout.get("name", "")) == "P. Mitchell", "scout resolved from staff") and ok
	ok = _assert(str(scr._ymgr.get("name", "")) == "G. Keeping", "youth manager resolved") and ok
	ok = _assert(scr._searching, "searching flag carried") and ok
	ok = _assert(bool(scr._selected.get("DRIBBLING", false)), "LED selection carried") and ok

	# LED slot geometry: 6 distinct rects inside the scout panel, 2 cols x 3 rows
	var seen := {}
	for skill in spec.get("cap_order", []):
		var r: Rect2 = scr._led_rect(str(skill))
		ok = _assert(r.size.x > 0.0, "LED rect exists: %s" % skill) and ok
		seen["%d,%d" % [int(r.position.x), int(r.position.y)]] = true
	ok = _assert(seen.size() == 6, "6 distinct LED slots") and ok

	# search signal: armed only with a scout + not already searching
	var got: Array = []
	scr.search_pressed.connect(func(skills: Array) -> void: got.append(skills))
	scr._searching = false
	scr._press = "btn:search"
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	var c: Rect2 = scr._btn_rect("search")
	e.position = c.get_center()
	scr._on_input(e)
	ok = _assert(got.size() == 1, "SEARCH emits with a scout hired") and ok
	ok = _assert(got[0].size() == 3, "emitted skills = 3 selected LEDs") and ok

	# --- Career search model (strings-decoded loop) ---
	var career := Career.new()
	career.staff = staff
	career.start_youth_search(["DRIBBLING"])
	ok = _assert(not career.youth_search.is_empty(), "start_youth_search arms the search") and ok
	# FUN_0053e860 @0x53e967, over Youth.SEARCH_SPEEDUP: a 5-star scout (quality byte
	# 10) is armed for 30..35 / 2 weeks.
	var armed := int(career.youth_search.get("weeks", 0))
	ok = _assert(armed >= 15 and armed <= 18,
		"search runs the binary's own duration (%d weeks)" % armed) and ok
	ok = _assert(str((career.news_log[0] as Dictionary).get("text", "")).begins_with(
		"The scout is now searching"), "searching news = witnessed string") and ok
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for _i in armed:
		career._tick_youth_search(rng)
	ok = _assert(career.youth_search.is_empty(), "search resolves after its weeks") and ok
	var news_text := ""
	for n in career.news_log:
		news_text += str((n as Dictionary).get("text", "")) + "\n"
	ok = _assert("finished his search" in news_text, "resolution uses the MANAGER.EXE string") and ok
	# no scout -> no-op
	var c2 := Career.new()
	c2.start_youth_search(["PASSING"])
	ok = _assert(c2.youth_search.is_empty(), "no scout -> SEARCH is a no-op") and ok
	# persists through save shape
	career.start_youth_search(["PASSING"])
	var d := career.to_dict()
	ok = _assert((d.get("youth_search", {}) as Dictionary).has("weeks"),
		"youth_search persisted in to_dict") and ok

	scr.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
