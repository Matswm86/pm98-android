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
	c.start_scout_search({"pos": "GK", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"]})
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
	c.start_scout_search({"pos": "GK", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_div2"]}, foreign)
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Preece",
		"foreign division frozen rows return (GK only)") and ok

	# PRICE band filter: the top band (+10,000 K.) needs fee >= 10M -> no cheap player qualifies
	c.week = 3
	c.start_scout_search({"pos": "", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": 9, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.is_empty(), "top price band (+10,000 K.) filters everyone") and ok

	# QUALITY band filter: Beeney av=60 -> band 0 (50-65) returns him, band 2 (71-75) does not
	c.week = 3
	c.start_scout_search({"pos": "GK", "role": 0, "age_band": -1, "quality_band": 0,
		"price_band": -1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Beeney",
		"quality band 50-65 matches av=60 GK") and ok
	c.week = 3
	c.start_scout_search({"pos": "GK", "role": 0, "age_band": -1, "quality_band": 2,
		"price_band": -1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.is_empty(), "quality band 71-75 excludes av=60 GK") and ok

	# ---- ROLE matches ANY of the six role slots (FUN_005753e0 @0x5754bc) -----
	# posFine + the five `posAlts`. Bergsson-shaped: primary RIGHT BACK (2) with
	# INS. CENT. LEFT (5) alternate -> a search for role 5 must find him.
	var alt := _mk(11, "Bergsson", "DF", 70)
	alt["posFine"] = 2
	alt["posAlts"] = [5, 6]
	c.rosters[60] = [alt]
	c.week = 3
	c.start_scout_search({"pos": "", "role": 5, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Bergsson",
		"ROLE matches an ALTERNATE role slot, not just posFine") and ok
	c.week = 3
	c.start_scout_search({"pos": "", "role": 9, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.is_empty(), "a role he does not hold still excludes him") and ok

	# ---- the shortlist cap: (quality_byte + 2) * 5, drawn at random ----------
	ok = _assert(Career.scout_cap(6) == 40, "a 3.0-star scout (q=6) caps at 40 = witness 81") and ok
	ok = _assert(Career.scout_cap(10) == 60 and Career.scout_cap(2) == 20,
		"the cap ladder runs 20 (1.0*) .. 60 (5.0*)") and ok
	var many: Array = []
	for i in 60:
		many.append(_mk(200 + i, "Reserve%d" % i, "GK", 60))
	c.rosters[60] = many
	c.staff = [{"role": Staff.SCOUT_ROLE, "name": "K. BURROWES", "stars": 3.0, "wage": 20000}]
	c.week = 3
	c.start_scout_search({"pos": "GK", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"]})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 40, "60 matches trimmed to the 3-star cap of 40") and ok
	ok = _assert(c.scout_found_total == 60, "the pre-cap match count is kept for the panel") and ok
	var names := {}
	for r2 in c.scout_results:
		names[str((r2 as Dictionary)["name"])] = true
	ok = _assert(names.size() == 40, "the trim never repeats a player (draw without replacement)") and ok
	c.staff = []
	c.rosters[60] = [_mk(2, "Beeney", "GK", 60), _mk(3, "Kewell", "FW", 80)]

	# ---- OURS: the name box and the six attribute thresholds ----------------
	var cole := _mk(12, "Cole", "FW", 75)
	cole["attrs"] = {"VE": 87, "RE": 86, "AG": 84, "CA": 75,
		"PO": 13, "PA": 70, "RM": 86, "RG": 73, "EN": 65, "TI": 88}
	c.rosters[60] = [cole, _mk(13, "Poole", "FW", 40)]
	c.week = 3
	c.start_scout_search({"pos": "", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"], "name": "col"})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Cole",
		"OURS name search is substring + case-insensitive") and ok
	c.week = 3
	c.start_scout_search({"pos": "", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"], "attr_min": {"TI": 85}})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.size() == 1 and str(c.scout_results[0]["name"]) == "Cole",
		"OURS SHOOTING >= 85 keeps Cole (TI 88) and drops the rest") and ok
	c.week = 3
	c.start_scout_search({"pos": "", "role": 0, "age_band": -1, "quality_band": -1,
		"price_band": -1, "leagues": ["eng_prem"], "attr_min": {"TI": 85, "PO": 50}})
	c.week = 5
	c._tick_scout_search()
	ok = _assert(c.scout_results.is_empty(),
		"OURS thresholds AND together (Cole's HANDLING is 13)") and ok
	ok = _assert(Career.SCOUT_ATTR_STOPS.size() == 14
		and int(Career.SCOUT_ATTR_STOPS[0]) == 30
		and int(Career.SCOUT_ATTR_STOPS[13]) == 95,
		"14 threshold stops, 30..95 by 5") and ok
	var codes: Array = []
	for e in Career.SCOUT_ATTR_FILTERS:
		codes.append(str(e[0]))
	codes.sort()
	var trainable: Array = Training.TRAINABLE.duplicate()
	trainable.sort()
	ok = _assert(codes == trainable,
		"the six filters are exactly Training.TRAINABLE") and ok
	c.rosters[60] = [_mk(2, "Beeney", "GK", 60), _mk(3, "Kewell", "FW", 80)]

	# ---- the E.U. list is the binary's own (FUN_0058d2f0, 18 codes) ---------
	ok = _assert(Career.EU_CODES.size() == 18 and Career.EU_NATIONS.size() == 18,
		"18 E.U. country codes, 18 names") and ok
	var cc: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/country_codes.json"))["byCode"]
	var eu_ok := true
	for code in Career.EU_CODES:
		if not Career.EU_NATIONS.has(str(cc.get(str(code), "?"))):
			eu_ok = false
	ok = _assert(eu_ok, "every FUN_0058d2f0 code resolves to a listed E.U. nation") and ok

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
