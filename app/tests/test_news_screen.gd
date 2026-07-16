extends SceneTree
## NEWS extra overlay (frame-true rebuild, 2026-07-16) — headless asserts for the
## chrome geometry + tab/filter logic decoded from walkthrough frames 155-158 (run1).
## The pixel gate lives in tools/re/diff_news_parity.py (3 shots, page 0px); this
## covers logic + wiring.

func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# --- chrome json: binding frames + geometry present ---
	var f := FileAccess.open("res://art/screens/news/news_chrome.json", FileAccess.READ)
	ok = _assert(f != null, "news_chrome.json exists") and ok
	var spec: Dictionary = {}
	if f != null:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		ok = _assert(typeof(parsed) == TYPE_DICTIONARY, "chrome json parses") and ok
		spec = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
	var bf: Dictionary = spec.get("binding_frames", {})
	ok = _assert(str(bf.get("premier", "")) == "155_154857.png", "premier binding = 155") and ok
	ok = _assert(str(bf.get("division", "")) == "158_154905.png", "division binding = 158") and ok
	var pg: Array = spec.get("page", [])
	ok = _assert(pg.size() == 4 and int(pg[0]) == 145 and int(pg[1]) == 27
		and int(pg[2]) == 350 and int(pg[3]) == 425, "page footprint rect") and ok
	for t in ["premier", "first", "second", "third"]:
		ok = _assert((spec.get("div_tabs", {}) as Dictionary).has(t), "div tab rect: %s" % t) and ok
	for t in ["market", "injuries", "bookings"]:
		ok = _assert((spec.get("cat_tabs", {}) as Dictionary).has(t), "cat tab rect: %s" % t) and ok
	var sub: Dictionary = spec.get("subtitle", {})
	ok = _assert(str(sub.get("format", "")) == "%s : %s", "EXE subtitle format string") and ok
	ok = _assert((sub.get("divisions", []) as Array) == ["Premier League", "First Division",
		"Second Division", "Third Division"], "EXE division names") and ok
	ok = _assert(str(sub.get("face", "")) == "proman10", "subtitle face = proman10") and ok
	var fm: Dictionary = spec.get("font_metrics", {})
	ok = _assert((fm.get("proman10", {}) as Dictionary).has("M"), "proman10 ink metrics") and ok

	# --- baked art present ---
	for n in ["page_premier", "page_division", "x_over", "tab_premier_on", "tab_premier_off",
			"tab_first_on", "tab_first_off", "tab_second_on", "tab_third_on",
			"tab_market_off", "tab_injuries_on", "tab_injuries_over", "tab_bookings_on"]:
		ok = _assert(ResourceLoader.exists("res://art/screens/news/%s.png" % n),
			"art exists: %s" % n) and ok

	# --- screen state machine + filtering ---
	var scr: NewsScreen = load("res://scenes/NewsScreen.gd").new()
	get_root().add_child(scr)
	scr.size = Vector2(640, 480)
	await process_frame

	var feed := [
		{"week": 3, "kind": "transfer", "text": "A. Cole has been signed by Arsenal."},
		{"week": 3, "kind": "injury", "text": "R. Giggs's hamstring is out injured for 2 matches."},
		{"week": 2, "kind": "transfer", "text": "Old market line from last week."},
		{"week": 3, "kind": "result", "text": "Matchday 3: a win."},
		{"week": 3, "kind": "staff", "text": "P. Gelbier has joined the club as Physiotherapist."},
	]
	scr.setup(feed, 3, 0)

	# default state = the witnessed 155 state
	var st := scr.state()
	ok = _assert(int(st.get("division", -1)) == 0 and str(st.get("category", "")) == "MARKET"
		and bool(st.get("weeks_actual")), "opens in the witnessed Premier/MARKET/ACTUAL state") and ok

	# MARKET shows market kinds only (transfer/contract/staff), current week
	var items := scr.visible_items()
	ok = _assert(items.size() == 2, "MARKET/ACTUAL: 2 market items this week (got %d)" % items.size()) and ok
	for n in items:
		ok = _assert(str(n.get("kind", "")) in ["transfer", "contract", "staff"],
			"market item kind %s" % n.get("kind")) and ok

	# INJURIES shows the injury; result/cup/youth kinds never surface in the paper
	scr._category = "INJURIES"
	items = scr.visible_items()
	ok = _assert(items.size() == 1 and str(items[0].get("kind", "")) == "injury",
		"INJURIES: exactly the injury item") and ok

	# BOOKINGS is honestly empty (Career does not model bookings)
	scr._category = "BOOKINGS"
	ok = _assert(scr.visible_items().is_empty(), "BOOKINGS: empty (not modelled)") and ok

	# WEEKS: LAST = the previous week's items
	scr._category = "MARKET"
	scr._weeks_actual = false
	items = scr.visible_items()
	ok = _assert(items.size() == 1 and str(items[0].get("text", "")).begins_with("Old market"),
		"LAST: previous week's market item") and ok
	scr._weeks_actual = true

	# other divisions stay empty (Career news is the managed club's own)
	scr._division = 2
	ok = _assert(scr.visible_items().is_empty(), "other division tabs: empty") and ok
	scr._division = 0

	# --- hit boxes route to the right controls ---
	ok = _assert(scr._hit(Vector2(486, 38)) == "x", "X hit box") and ok
	ok = _assert(scr._hit(Vector2(486, 130)) == "div:1", "1st Div. tab hit box") and ok
	ok = _assert(scr._hit(Vector2(486, 244)) == "div:3", "3rd Div. tab hit box") and ok
	ok = _assert(scr._hit(Vector2(246, 443)) == "cat:INJURIES", "INJURIES tab hit box") and ok
	ok = _assert(scr._hit(Vector2(218, 419)) == "weeks:last", "LAST plate hit box") and ok
	ok = _assert(scr._hit(Vector2(262, 419)) == "weeks:actual", "ACTUAL plate hit box") and ok
	ok = _assert(scr._hit(Vector2(300, 200)) == "", "page body: no control") and ok
	ok = _assert(scr._hit(Vector2(60, 240)) == "outside", "outside the page dismisses") and ok

	# --- back signal ---
	var got := [false]
	scr.back_pressed.connect(func() -> void: got[0] = true)
	scr._press = "x"
	scr._on_input(_release(Vector2(486, 38)))
	ok = _assert(got[0], "X release emits back_pressed") and ok

	print("test_news_screen: %s" % ("ALL PASS" if ok else "FAILURES"))
	quit(0 if ok else 1)


func _release(design_pos: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = design_pos  # screen == design at 640x480 root size (scale 1)
	return e


var _n := 0

func _assert(cond: bool, what: String) -> bool:
	_n += 1
	print("  [%s] %02d %s" % ["PASS" if cond else "FAIL", _n, what])
	return cond
