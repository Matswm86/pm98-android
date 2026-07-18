extends SceneTree
## Headless test for the SCOUT screen + Career async scout search (charter #8;
## witnessed 2026-07-18, docs/re/scout_screen_re.md): assets load, geometry in
## canvas, the witnessed validation rule (criteria toggle required, leagues
## alone refused), the async arm/tick/finish loop + the hub-alert queue, the
## criteria filters, the witnessed AV formula, save round-trip, sign_external,
## and the digit-centring grammar.
##   ~/godot462 --headless --path app --script res://tests/test_scout_screen.gd

var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	get_root().size = Vector2i(640, 480)

	for path in ["res://art/screens/scout/chrome.png",
			"res://art/screens/scout/noscout_patch.png",
			"res://art/screens/scout/led_on.png",
			"res://art/screens/scout/search_armed.png",
			"res://art/screens/scout/searching_text.png",
			"res://art/screens/scout/headers.png",
			"res://art/screens/scout/plus.png",
			"res://art/screens/scout/star_full.png",
			"res://art/screens/scout/star_half.png",
			"res://art/screens/scout/scroll_up_off.png",
			"res://art/screens/scout/scroll_dn_on.png",
			"res://art/screens/scout/scroll_slider.png"]:
		ok = _assert(ResourceLoader.exists(path), "asset present: %s" % path) and ok
		ok = _assert(load(path) != null, "asset loads: %s" % path) and ok

	ok = _assert(ScoutScreen.BTN_RETURN.end.x <= 640 and ScoutScreen.BTN_RETURN.end.y <= 480,
		"RETURN rect in canvas") and ok
	ok = _assert(ScoutScreen.BTN_SEARCH.end.x <= 640, "SEARCH rect in canvas") and ok
	for k in ScoutScreen.ARROWS:
		var r: Rect2 = ScoutScreen.ARROWS[k]
		ok = _assert(r.end.x <= 640 and r.end.y <= 480, "arrow %s in canvas" % k) and ok

	# ---- screen states -----------------------------------------------------
	var scr: ScoutScreen = load("res://scenes/ScoutScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame
	scr.setup({}, false, [], "Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	ok = _assert(not scr._has_scout, "no scout -> gated") and ok
	ok = _assert(scr._hit(Vector2(200, 160)) == "", "criteria inert without scout") and ok
	ok = _assert(scr._hit(ScoutScreen.BTN_RETURN.get_center()) == "return",
		"RETURN still live without scout") and ok

	scr.setup({"name": "K. BURROWES", "stars": 3.0, "wage": 20000}, false, [],
		"Bolton W", "mwm", "1997-98", 3, "Premier League", 59)
	ok = _assert(scr._has_scout, "scout hired -> criteria live") and ok

	# the witnessed validation: leagues alone refused (64/66), toggle+league arms
	var armed: Array = []
	scr.search_started.connect(func(cr: Dictionary) -> void: armed.append(cr))
	scr._leagues["eng_prem"] = true
	scr._try_search()
	ok = _assert(scr._alert_img != null, "leagues-only SEARCH -> options alert (witnessed)") and ok
	ok = _assert(armed.is_empty(), "refused search does not arm") and ok
	scr._activate("alert_ok")
	ok = _assert(scr._alert_img == null, "alert OK dismisses") and ok
	scr._tog["pos"] = true
	scr._pos_idx = 0
	scr._try_search()
	ok = _assert(armed.size() == 1, "POSITION+league arms the search (witnessed 68)") and ok
	ok = _assert(str(armed[0].get("pos")) == "GK", "criteria carries GK") and ok
	ok = _assert(armed[0].get("leagues") == ["eng_prem"], "criteria carries the league") and ok
	ok = _assert(scr._searching, "screen shows searching state") and ok

	# digit grammar: "69" tw 16 -> px floor(246-8)=238 (witness ink x238)
	var tw := 0
	for ch in "69":
		tw += 5 if ch == "1" else 8
	ok = _assert(int(floor(ScoutScreen.CELL_AV_CX - tw / 2.0)) == 238,
		"digit-centring lands AV '69' at witness x238") and ok

	# ---- Career async loop -------------------------------------------------
	var c := Career.new()
	c.league_id = "eng_prem"
	c.club_id = 59
	c.tier = 1
	c.week = 3
	c.club_names = {59: "Bolton W", 60: "Leeds Utd"}
	c.rosters = {
		59: [_mk(1, "OwnGk", "GK", 60)],
		60: [_mk(2, "Beeney", "GK", 60), _mk(3, "Kewell", "FW", 80)],
	}
	c.start_scout_search({"pos": "GK", "age": 0, "role": 0, "quality": 0,
		"price": 0, "leagues": ["eng_prem"]})
	ok = _assert(c.scout_searching(), "search armed") and ok
	ok = _assert(int(c.scout_search["due_week"]) == 5, "due = armed week + 2 (witnessed)") and ok
	c._tick_scout_search()
	ok = _assert(c.scout_searching(), "not due yet -> still searching") and ok
	c.week = 5
	c._tick_scout_search()
	ok = _assert(not c.scout_searching(), "due week -> search done") and ok
	ok = _assert(c.scout_results.size() == 1, "one matching GK (own club + non-GK excluded)") and ok
	var row: Dictionary = c.scout_results[0]
	ok = _assert(str(row["name"]) == "Beeney", "the right player") and ok
	ok = _assert(int(row["av"]) == 60, "AV = floor(sum4/4) (witnessed formula)") and ok
	ok = _assert(c.pending_alerts == ["The scout has finished his search."],
		"the witnessed hub alert queued") and ok

	# foreign-division freeze at arm time
	var foreign := [{"id": 100, "name": "Blackpool", "players": [
		_mk(9, "Preece", "GK", 48), _mk(10, "Malkin", "FW", 59)]}]
	c.week = 3
	c.start_scout_search({"pos": "GK", "age": 0, "role": 0, "quality": 0,
		"price": 0, "leagues": ["eng_div2"]}, foreign)
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Preece",
		"foreign division frozen rows return (GK only)") and ok

	# price cap filter
	c.week = 3
	c.start_scout_search({"pos": "", "age": 0, "role": 0, "quality": 0,
		"price": 1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.is_empty(), "price cap filters everyone") and ok

	# save round-trip
	c.pending_alerts = ["The scout has finished his search."]
	c.external_signed = {77: true}
	var d := c.to_dict()
	var c2 := Career.from_dict(d)
	ok = _assert(c2.pending_alerts.size() == 1, "pending_alerts survive save") and ok
	ok = _assert(c2.external_signed.has(77), "external_signed survives save") and ok
	ok = _assert(c2.scout_results.size() == c.scout_results.size(), "results survive save") and ok

	# ---- sign_external -----------------------------------------------------
	c.cash = 100000000
	c.rosters[59] = [_mk(1, "OwnGk", "GK", 60)]
	c.week = 1
	c.fixtures = []
	c.fixtures.resize(38)   # a season's rounds so the transfer window is open
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ext_p := _mk(500, "Rivaldo", "MF", 95)
	var ext_club := {"id": 1000, "name": "F.C. Barcelona", "players": [ext_p]}
	var res := c.sign_external(ext_p, ext_club, 90000000, rng)
	ok = _assert(bool(res["ok"]), "huge offer accepted (deterministic branch)") and ok
	ok = _assert(c.my_squad().size() == 2, "player joined the squad") and ok
	ok = _assert(c.external_signed.has(500), "external ledger marks him") and ok
	var res2 := c.sign_external(ext_p, ext_club, 90000000, rng)
	ok = _assert(not bool(res2["ok"]), "re-buy refused (no longer available)") and ok

	scr.queue_free()
	await process_frame
	print("\n%s" % ("ALL PASS" if ok else "FAILURES: %d" % _fails))
	quit(0 if ok else 1)


func _mk(id: int, nm: String, pos: String, ca: int) -> Dictionary:
	return {"id": id, "name": nm, "pos": pos, "posFine": 1, "age": 25,
		"nationality": "ENGLAND", "flagCode": null,
		"attrs": {"VE": ca, "RE": ca, "AG": ca, "CA": ca}}


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_fails += 1
	return cond
