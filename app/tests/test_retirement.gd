extends SceneTree
## S8 — RETIREMENT + AGEING INTAKE, and the squad-size floor the port was missing.
##   ~/godot462 --headless --path app --script res://tests/test_retirement.gd
##
## Every expectation is MANAGER.EXE's, not the app's (docs/re/retirement_re.md):
##   FUN_0058b020  retire age = 0x23 - 2*(band != 0)  -> 35 GK / 33 outfield
##   FUN_0058ac90  @0x58ae55 `cmp ecx,0xd / jb keep`  -> never released under 13 men
##   FUN_0058b030  @0x58b04f birth year += rand(3)+10 -> reborn 10..12 years younger,
##                 @0x58b06d VE/RE/AG/EN restored from the shipped base block
##   FUN_00545fd0  @0x546013 `cmp [club+0x224],3 / jbe` -> sacked past 3 loss weeks

const SEED := 19970809


func _initialize() -> void:
	quit(0 if _run() else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond


func _player(id: int, age: int, gk: bool) -> Dictionary:
	return {
		"id": id, "name": "Man%d" % id, "legalName": "MAN %d" % id,
		"age": age, "birthYear": 1997 - age, "pos": "GK" if gk else "MF", "isGK": gk,
		"posFine": 1 if gk else 6,
		"attrs": {"VE": 40, "RE": 41, "AG": 42, "CA": 60, "RM": 50, "RG": 50,
			"PA": 50, "TI": 50, "EN": 44, "PO": 55},
		"attrs_base": {"VE": 80, "RE": 81, "AG": 82, "CA": 60, "RM": 50, "RG": 50,
			"PA": 50, "TI": 50, "EN": 88, "PO": 55},
		"contract_years": 1, "contract_term": 1, "wage": 1000,
	}


func _run() -> bool:
	var ok := true

	# ---- FUN_0058b020: the two retirement ages ------------------------------
	ok = _assert(Retirement.retire_age(_player(1, 30, true)) == 35, "keeper retires at 35") and ok
	ok = _assert(Retirement.retire_age(_player(2, 30, false)) == 33, "outfielder retires at 33") and ok
	ok = _assert(not Retirement.retires(_player(3, 34, true)), "a 34-year-old keeper plays on") and ok
	ok = _assert(Retirement.retires(_player(4, 35, true)), "a 35-year-old keeper retires") and ok
	ok = _assert(Retirement.retires(_player(5, 33, false)), "a 33-year-old outfielder retires") and ok
	ok = _assert(not Retirement.retires(_player(6, 32, false)), "a 32-year-old outfielder plays on") and ok

	# ---- FUN_0058b030: the rebirth ------------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var old := _player(7, 35, false)
	var was_name := str(old["name"])
	var reborn := Retirement.rebirth(old.duplicate(true), rng, 90001)
	var back := 35 - int(reborn["age"])
	ok = _assert(back >= 10 and back <= 12, "reborn 10..12 years younger (was %d)" % back) and ok
	ok = _assert(int(reborn["birthYear"]) == (1997 - 35) + back, "birth year moved by the same span") and ok
	ok = _assert(int(reborn["attrs"]["VE"]) == 80 and int(reborn["attrs"]["RE"]) == 81
		and int(reborn["attrs"]["AG"]) == 82 and int(reborn["attrs"]["EN"]) == 88,
		"VE/RE/AG/EN restored from the base block") and ok
	ok = _assert(int(reborn["attrs"]["CA"]) == 60 and int(reborn["attrs"]["PO"]) == 55,
		"CA/PO deliberately NOT restored") and ok
	ok = _assert(int(reborn["id"]) == 90001 and str(reborn["name"]) != was_name,
		"a new id and a new name") and ok
	ok = _assert(str(reborn["name"]) != "" and str(reborn["legalName"]).contains(str(reborn["name"]).to_upper()),
		"display name is the surname of the legal name") and ok

	# ---- FUN_0058ac90 @0x58ae55: the 13-man floor, live on a career ---------
	var db := _load("res://data/game_db.json")
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if str(lg["id"]) == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if str(c.get("leagueId", "")) == "eng_prem":
			prem.append(c)
	var career := Career.new()
	career.reputation = Manager.REP_START
	career.career_rng_state = str(SEED)
	career._init_club(prem[0], league, prem, leagues, {})
	# Cut the squad to the floor and expire EVERY contract: the original releases nobody.
	var squad: Array = career.rosters[career.club_id]
	while squad.size() > Retirement.SQUAD_FLOOR:
		squad.remove_at(squad.size() - 1)
	for p in squad:
		(p as Dictionary)["contract_years"] = 1
		(p as Dictionary)["age"] = 24          # too young to retire, so only the floor can act
		(p as Dictionary).erase("auto_renew")
		(p as Dictionary).erase("clause_matches")
	career.staff = []                           # no assistant manager to re-sign anyone
	career.cash = 0                             # nothing is "affordable"
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = SEED
	career.advance_season(leagues, rng2)
	# The engine tests the count BEFORE removing the man in hand (the caller's iStack_28 is
	# decremented only after FUN_0058ac90 returns 0), so a 13-man squad gives up exactly
	# ONE and every release after that is refused: the resting point is twelve.
	ok = _assert((career.rosters[career.club_id] as Array).size() == Retirement.SQUAD_FLOOR - 1,
		"a 13-man squad gives up exactly one to expiry, then the floor holds (kept %d)"
			% (career.rosters[career.club_id] as Array).size()) and ok
	var still_signed := true
	for p in career.rosters[career.club_id]:
		if int((p as Dictionary).get("contract_years", 0)) <= 0:
			still_signed = false
	ok = _assert(still_signed, "every kept man ran his deal on (FUN_0058ac90's KEEP branch)") and ok

	# ---- a full career: veterans go, the squad never melts -------------------
	var c2 := Career.new()
	c2.reputation = Manager.REP_START
	c2.career_rng_state = str(SEED)
	c2._init_club(prem[0], league, prem, leagues, {})
	var rival_total := func(c: Career) -> int:
		var n := 0
		for cid in c.rosters:
			if int(cid) != c.club_id:
				n += (c.rosters[cid] as Array).size()
		return n
	var rivals_before: int = rival_total.call(c2)
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = SEED
	var reborn_n := 0
	var oldest := 0
	for season in 5:
		while not c2.season_over():
			c2.advance_week(rng3)
		c2.advance_season(leagues, rng3)
	for cid in c2.rosters:
		for p in c2.rosters[cid]:
			if (p as Dictionary).get("reborn"):
				reborn_n += 1
			if int(cid) != c2.club_id:
				oldest = maxi(oldest, int((p as Dictionary).get("age", 0)))
	# THE S8 HEADLINE: the population is conserved. An unmanaged club's retiree is reborn
	# in place (FUN_00576cd0's arg2 is his own club id), so five seasons of ageing move
	# players between rivals but never destroy them -- the "ages into a dead end" is gone.
	ok = _assert(rival_total.call(c2) == rivals_before,
		"rival population conserved over five seasons (%d)" % rivals_before) and ok
	ok = _assert(reborn_n > 0, "the ageing intake actually fired (%d reborn records)" % reborn_n) and ok
	ok = _assert(oldest <= Retirement.RETIRE_AGE_GK,
		"no rival is older than the keeper retirement age (oldest %d)" % oldest) and ok
	# Your own squad is NOT floored against retirement (the original floors releases only),
	# and the board's answer to a squad that thin is FUN_00545fd0's third dismissal.
	var mine: int = (c2.rosters[c2.club_id] as Array).size()
	if mine < Career.SACK_MIN_SQUAD:
		c2.finished = true
		var rv := c2.board_review()
		ok = _assert(bool(rv["sacked"]), "a squad under 16 gets you dismissed (squad %d)" % mine) and ok

	# ---- FUN_00545fd0 @0x546013: the sacking threshold ----------------------
	ok = _assert(Career.LOSS_SACK_WEEKS == 4, "sacked on the 4th loss week (cmp 3 / jbe)") and ok
	ok = _assert(Career.SACK_MIN_SQUAD == 16, "sacked with a squad under 16") and ok

	print("test_retirement: %s" % ("ALL GREEN" if ok else "FAILURES"))
	return ok


func _load(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
