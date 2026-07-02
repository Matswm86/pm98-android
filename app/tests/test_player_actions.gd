extends SceneTree
## Headless tests for the PLAYER INFORMATION contract actions (the "sell" flow that lives on
## the SQUAD MANAGEMENT player card, FUN_00526a60): Career.release (SACK) with its squad-floor
## guards, and PlayerInfoScreen's RENEW / TRANSFER / SACK / OK button row (hit-tests, signals,
## and read-only hiding for another club's player).
##   ~/godot462 --headless --path app --script res://tests/test_player_actions.gd


func _initialize() -> void:
	quit(0 if await _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	var prem: Array = []
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.size() != 20 or league.is_empty():
		push_error("expected 20 Premier clubs + league")
		return false

	var ok := true
	ok = await _release(prem, league, leagues) and ok
	ok = await _card_buttons(prem) and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- Career.release (SACK) ----------------------------------------------

func _outfielder(squad: Array, skip_gk := true) -> Dictionary:
	for p in squad:
		if not (skip_gk and p.get("isGK")):
			return p
	return squad[0]


func _release(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var c := Career.create(prem[0], league, prem, leagues)
	c.cash = 50_000_000

	# A clean sack: outfielder leaves, joins the free-agent pool, compensation billed.
	var squad0 := c.my_squad().size()
	var free0 := c.free_agents.size()
	var victim := _outfielder(c.my_squad())
	var pid := int(victim["id"])
	var weekly := Contract.current_weekly(victim, c.tier)
	var years: int = maxi(1, int(victim.get("contract_years", 1)))
	var exp_comp := weekly * Contract.SEASON_WEEKS * years
	var cash0 := c.cash
	var res := c.release(pid)
	ok = _assert(res["ok"], "sack accepted") and ok
	ok = _assert(c.my_squad().size() == squad0 - 1, "squad shrank by one") and ok
	ok = _assert(c._find_in(c.club_id, pid).is_empty(), "player no longer in the squad") and ok
	ok = _assert(c.free_agents.size() == free0 + 1, "sacked player joined the free-agent pool") and ok
	ok = _assert(c.cash == cash0 - exp_comp, "compensation billed (£%d)" % exp_comp) and ok
	ok = _assert(int(res.get("compensation", 0)) == exp_comp, "compensation reported") and ok

	# Squad-floor guard: cannot sack below SQUAD_MIN.
	var c2 := Career.create(prem[1], league, prem, leagues)
	while c2.my_squad().size() > TransferMarket.SQUAD_MIN:
		(c2.rosters[c2.club_id] as Array).pop_back()
	var floor_res := c2.release(int(_outfielder(c2.my_squad())["id"]))
	ok = _assert(not floor_res["ok"] and floor_res["msg"].contains("too small"),
		"blocked at the squad floor") and ok

	# Keeper guard: cannot sack down to a single goalkeeper.
	var c3 := Career.create(prem[2], league, prem, leagues)
	var keepers: Array = c3.my_squad().filter(func(p): return p.get("isGK"))
	while keepers.size() > TransferMarket.MIN_KEEPERS:
		c3.rosters[c3.club_id].erase(keepers.pop_back())
	var gk_res := c3.release(int(keepers[0]["id"]))
	ok = _assert(not gk_res["ok"] and gk_res["msg"].contains("goalkeepers"),
		"blocked sacking the 2nd-to-last keeper") and ok

	# Loaned-in players are returned, not sackable.
	var c4 := Career.create(prem[3], league, prem, leagues)
	var loanee := _outfielder(c4.my_squad())
	loanee["on_loan"] = true
	var loan_res := c4.release(int(loanee["id"]))
	ok = _assert(not loan_res["ok"] and loan_res["msg"].contains("loan"), "loanee not sackable") and ok
	return ok


# ---- PlayerInfoScreen button row ----------------------------------------

func _card_buttons(prem: Array) -> bool:
	var ok := true
	var club: Dictionary = prem[0]
	var player: Dictionary = club["players"][1]   # an outfielder

	var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	get_root().add_child(scr)
	for _i in 2:
		await process_frame
	scr.size = Vector2(640, 480)

	# Own squad player -> the three action buttons are live.
	scr.setup(player, club, 1, true)
	ok = _assert(scr._hit(PlayerInfoScreen.RENEW_BTN.get_center()) == "renew", "_hit RENEW") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.TRANSFER_BTN.get_center()) == "transfer", "_hit TRANSFER") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.SACK_BTN.get_center()) == "sack", "_hit SACK") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OK_BTN.get_center()) == "ok", "_hit OK") and ok

	var got := {"renew": 0, "transfer": 0, "sack": 0, "back": 0}
	scr.renew_requested.connect(func(_p): got["renew"] += 1)
	scr.transfer_requested.connect(func(_p): got["transfer"] += 1)
	scr.sack_requested.connect(func(_p): got["sack"] += 1)
	scr.back_pressed.connect(func(): got["back"] += 1)
	_tap(scr, PlayerInfoScreen.RENEW_BTN.get_center())
	_tap(scr, PlayerInfoScreen.TRANSFER_BTN.get_center())
	_tap(scr, PlayerInfoScreen.SACK_BTN.get_center())
	_tap(scr, PlayerInfoScreen.OK_BTN.get_center())
	ok = _assert(got["renew"] == 1, "RENEW tap emits renew_requested") and ok
	ok = _assert(got["transfer"] == 1, "TRANSFER tap emits transfer_requested") and ok
	ok = _assert(got["sack"] == 1, "SACK tap emits sack_requested") and ok
	ok = _assert(got["back"] == 1, "OK tap emits back_pressed") and ok

	# Read-only card (another club's player): the action buttons don't exist; taps there
	# fall through to dismiss.
	scr.setup(player, club, 1, false)
	ok = _assert(scr._hit(PlayerInfoScreen.RENEW_BTN.get_center()) == "", "read-only hides RENEW") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.SACK_BTN.get_center()) == "", "read-only hides SACK") and ok
	ok = _assert(scr._hit(PlayerInfoScreen.OK_BTN.get_center()) == "ok", "OK stays live read-only") and ok
	var before: int = got["back"]
	_tap(scr, PlayerInfoScreen.RENEW_BTN.get_center())
	ok = _assert(got["renew"] == 1 and got["back"] == before + 1,
		"read-only RENEW-area tap dismisses, no renew") and ok

	scr.queue_free()
	return ok


func _tap(scr: PlayerInfoScreen, p: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.position = p
	down.pressed = true
	scr._on_input(down)
	var up := InputEventScreenTouch.new()
	up.position = p
	up.pressed = false
	scr._on_input(up)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
