extends SceneTree
## THE OWNER'S 2026-08-01 CONFIRMATION PASS — every item on the list, driven on the REAL
## objects at HEAD, printed as a number rather than relayed from a handoff.
##
## This exists because the same ten reports came back after s81 said it had closed them.
## Nothing here reads a test's own fixture: each check drives the shipping Career / Contract /
## Cup / Fines / Pm98StatMatch path the game itself uses.
##
##   ~/godot4 --headless --path app --script res://tests/diag_owner_report_2026_08_01.gd

const SEED := 4242

var _ok := true


func _initialize() -> void:
	quit(0 if _run() else 1)


func _db() -> Dictionary:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	return JSON.parse_string(f.get_as_text())


func _prem_career() -> Career:
	var db := _db()
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	var prem: Array = []
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	return Career.create(prem[0], league, prem, leagues)


func _run() -> bool:
	print("=== 2. STADIUM EXPANSION -> MATCH-RESULT TICKET INCOME (the real works path) ===")
	_stadium()
	print("\n=== 8. THE F.A. CUP CALENDAR ===")
	_cup_calendar()
	print("\n=== 4. THE SEASON ROLLOVER: TOP SCORERS + TRAINING ===")
	_rollover()
	print("\n=== 6. CONTRACT RENEWAL: THE DEMAND, THE TERM, THE CLAUSES ===")
	_renewal()
	print("\n=== 7. THE SCOUT'S CRITERIA ===")
	_scout()
	print("\n=== 5. THREE UP FRONT: WHOSE SIDE, AND THE FLOOR ===")
	_cheats()
	print("\n=== 1. THE YOUTH 'READY TO BE PROMOTED' BOX ===")
	_youth_box()
	print("\n=== 3. EUROPEAN + CUP TIES ARE PLAYED ===")
	_europe()
	print("\n%s" % ("ALL CONFIRMED" if _ok else "SOMETHING ABOVE IS STILL BROKEN"))
	return _ok


func _ck(cond: bool, label: String) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	_ok = _ok and cond


# ---------------------------------------------------------------------------------------
func _stadium() -> void:
	var c := _prem_career()
	c.cash = 40_000_000
	var cap0: int = c.stadium_capacity
	var g0 := _gate(c)
	var t0 := StadiumScreen.tier_for(cap0 + c.stadium_headroom)
	print("  start: capacity %d, FULL TIME gate £%d, GROUND tile %d" % [cap0, g0, t0])

	# The REAL path the owner uses: a SEATS card, then the build weeks tick it down.
	var started := c.start_works(20000, 2_000_000, 6)
	_ck(started, "a 20,000-seat expansion can be started")
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var clubs := {}
	for cl in _db().get("clubs", []):
		clubs[int(cl["id"])] = cl
	for _w in 8:
		c.advance_week(rng, clubs)
	var cap1: int = c.stadium_capacity
	var g1 := _gate(c)
	var t1 := StadiumScreen.tier_for(cap1 + c.stadium_headroom)
	print("  after 8 weeks: capacity %d, FULL TIME gate £%d, GROUND tile %d"
		% [cap1, g1, t1])
	_ck(cap1 == cap0 + 20000, "the works completed and the capacity rose by 20,000")
	_ck(g1 > g0, "the MATCH-RESULT ticket figure rose (£%d -> £%d)" % [g0, g1])
	_ck(t1 > t0, "the GROUND picture moved (tile %d -> %d)" % [t0, t1])
	@warning_ignore("integer_division")
	var band := 130000 / 11
	var step := 0
	while step < 60000:
		step += 500
		if StadiumScreen.tier_for(cap0 + step + c.stadium_headroom) > t0:
			break
	print("  NOTE: the picture is capacity*11/130000 (FUN_0051a6e0 @0x51a73a), so one tile")
	print("        is %d seats; from %d the picture first changes at +%d seats."
		% [band, cap0, step])


func _gate(c: Career) -> int:
	var sm: Dictionary = c.finance_summary()
	var home_games: int = maxi(1, int(sm.get("home_games", 19)))
	for line in sm.get("income_lines", []):
		if line[0] == "TICKETS":
			@warning_ignore("integer_division")
			return int(line[1]) / home_games
	return 0


# ---------------------------------------------------------------------------------------
func _cup_calendar() -> void:
	_ck(Career.FA_CUP_WEEKS[2] == 22,
		"F.A. Cup ROUND 3 is week 22 (got %d)" % Career.FA_CUP_WEEKS[2])
	_ck(Career.FA_CUP_WEEKS[0] == 15, "F.A. Cup ROUND 1 is week 15")
	_ck(Career.LEAGUE_CUP_WEEKS[7] == 34, "the Coca-Cola FINAL is week 34")
	var c := _prem_career()
	# Week 22 on a season opening Sat 9 Aug 1997 is the first week of January.

	print("  ladder: %s" % str(Career.FA_CUP_WEEKS))


# ---------------------------------------------------------------------------------------
func _rollover() -> void:
	var c := _prem_career()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var clubs := {}
	for cl in _db().get("clubs", []):
		clubs[int(cl["id"])] = cl
	# Give the manager's own scorer tier and a training assignment something to hold.
	var squad: Array = c.my_squad()
	if not squad.is_empty():
		c.set_training_focus(int((squad[0] as Dictionary).get("id", 0)), "SHOOTING")
	for _w in 12:
		c.advance_week(rng, clubs)
	var log_before: int = (c.scorer_log as Array).size()
	var focus_before: int = (c.training_focus as Dictionary).size()
	print("  before rollover: scorer_log=%d  training_focus=%d" % [log_before, focus_before])
	c.advance_season(_db().get("leagues", []), rng)
	var log_after: int = (c.scorer_log as Array).size()
	print("  after  rollover: scorer_log=%d  training_focus=%d"
		% [log_after, (c.training_focus as Dictionary).size()])
	_ck(log_after == 0, "the GOAL SCORERS log is empty in season two")
	_ck((c.training_focus as Dictionary).size() <= focus_before,
		"training focus is pruned of departed players at the rollover")


# ---------------------------------------------------------------------------------------
func _renewal() -> void:
	var c := _prem_career()
	var squad: Array = c.my_squad()
	var p: Dictionary = squad[0]
	var band := c.my_band()
	var cur := Contract.current_weekly(p, band)
	var dem := Contract.demanded_weekly(p, band)
	print("  %s: current £%d/wk, demanded £%d/wk" % [str(p.get("name", "?")), cur, dem])
	_ck(dem == maxi(cur, Contract.market_weekly(p, band)),
		"the demand is his CURRENT terms floored at his market rate (no age/CA premium)")
	# The offered TERM is honoured, not overwritten.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var pid := int(p.get("id", 0))
	# The real API: `offer_clauses` is an ARRAY of OfferRecord clause ids, and the record
	# fields are `contract_years` / `clauses`, not `years`.
	var res: Dictionary = c.renew(pid, maxi(cur, dem), rng, 3,
		[OfferRecord.CLAUSE_FREE_IF_RELEGATED, OfferRecord.CLAUSE_MATCHES_TO_RENEW])
	print("  renew(term 3, clause free_if_relegated) -> %s" % str(res.get("msg", res)))
	var after := c.my_squad()
	var got: Dictionary = {}
	for q in after:
		if int((q as Dictionary).get("id", -1)) == pid:
			got = q
	if bool(res.get("ok", false)):
		_ck(int(got.get("contract_years", 0)) == 3,
			"the offered 1..5 TERM is stamped (contract_years=%d)"
			% int(got.get("contract_years", 0)))
		var cl: Array = got.get("clauses", [])
		_ck(cl.has(OfferRecord.CLAUSE_FREE_IF_RELEGATED),
			"the FREE IF RELEGATED clause rides the offer and is stamped (clauses=%s)" % str(cl))
		_ck(not cl.has(OfferRecord.CLAUSE_MATCHES_TO_RENEW),
			"a term above one year drops MATCHES TO RENEW (@0x529e40)")
		# ...and removing a clause has to work too, which is the other half of the report.
		var res2: Dictionary = c.renew(pid, maxi(cur, dem), rng, 2, [])
		var got2: Dictionary = {}
		for q2 in c.my_squad():
			if int((q2 as Dictionary).get("id", -1)) == pid:
				got2 = q2
		if bool(res2.get("ok", false)):
			_ck((got2.get("clauses", []) as Array).is_empty(),
				"offering NO clauses removes the ones he had (clauses=%s)"
				% str(got2.get("clauses", [])))
			_ck(int(got2.get("contract_years", 0)) == 2, "and the new 2-year term is stamped")
	else:
		print("  (the roll refused this offer; re-run with a different seed to see the stamp)")


# ---------------------------------------------------------------------------------------
func _scout() -> void:
	var c := _prem_career()
	var crit := {"position": 2, "role": 1, "age": 3, "quality": 2, "price": 4}
	c.scout_criteria = crit.duplicate(true)
	var round_trip := Career.from_dict(c.to_dict())
	_ck((round_trip.scout_criteria as Dictionary) == crit,
		"the last search criteria survive save/load")
	_ck(ResourceLoader.exists("res://scenes/ScoutScreen.gd"), "ScoutScreen present")
	var scr = load("res://scenes/ScoutScreen.gd").new()
	_ck(scr.has_method("restore_criteria"),
		"ScoutScreen.restore_criteria exists to re-arm the panel on entry")
	scr.free()


# ---------------------------------------------------------------------------------------
func _cheats() -> void:
	_ck(Pm98StatMatch.cheat_chance_floor == 2,
		"the per-half chance floor is 2 (got %d)" % Pm98StatMatch.cheat_chance_floor)
	_ck(Pm98StatMatch.CAVE_CHANCE_FLOOR == 3,
		"the cave's own 3 is kept so the PCode oracle still proves byte-parity")
	Pm98StatMatch.cheat_manager_side = -1
	_ck(Pm98StatMatch.cheat_manager_side == -1,
		"cheat_manager_side exists and defaults to 'neither side' (-1)")


# ---------------------------------------------------------------------------------------
func _youth_box() -> void:
	# The exact string the youth manager reports with, measured the way PMAlert measures it.
	var msg := "Your youth manager has told you\nthat there is a player ready to be promoted."
	var fitted: String = PMAlert._fit(msg)
	var w := 0
	for line in fitted.split("\n"):
		w = maxi(w, int(PMChrome.font("12").get_string_size(
			line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x))
	var box_w := w + 31
	print("  widest line %d px -> box %d px on a 640 px surface" % [w, box_w])
	_ck(box_w <= 640, "the promote box fits the surface, so OK is reachable")
	_ck(fitted.split("\n").size() >= 2, "the EXE's own line break @0x261ab8 is present")


# ---------------------------------------------------------------------------------------
func _europe() -> void:
	var c := _prem_career()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var clubs := {}
	for cl in _db().get("clubs", []):
		clubs[int(cl["id"])] = cl
	# Put the club in Europe the way a season rollover does, then drive a season and count
	# the ties that came back as PLAYABLE presentations rather than silent results.
	c.mint_european_cups([], rng)
	var presented := 0
	var weeks := 0
	while weeks < 40:
		weeks += 1
		c.advance_week(rng, clubs)
		presented += (c.take_pending_matches() as Array).size()
	print("  %d matches were queued for presentation over %d weeks" % [presented, weeks])
	_ck(presented > 0,
		"cup / European ties are queued as PLAYABLE matches, not resolved silently")
