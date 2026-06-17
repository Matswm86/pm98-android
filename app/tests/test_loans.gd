extends SceneTree
## Headless test for T2 #8 — loans (loan IN). Builds a Premier career and asserts the loan
## market lists other clubs' fringe, a loanee joins the squad for no fee (leaving his parent
## club), he can't be sold while on loan, the offer guard holds, he RETURNS to his parent at
## the season rollover, and the on-loan state round-trips through save/load.
##   ~/godot462 --headless --path app --script res://tests/test_loans.gd

const SEED := 3030


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var mkt := career.loan_market()
	ok = _assert(not mkt.is_empty(), "loan market lists fringe players (%d)" % mkt.size()) and ok
	# Loan market never lists the manager's own players.
	var own := false
	for r in mkt:
		if int(r["club_id"]) == career.club_id:
			own = true
	ok = _assert(not own, "loan market excludes your own club") and ok

	var target: Dictionary = mkt[0]
	var pid := int(target["pid"])
	var parent := int(target["club_id"])
	var squad0: int = career.my_squad().size()
	var cash0: int = career.cash
	var offers0: int = career.offers_left
	var res := career.sign_loan(pid, parent)
	ok = _assert(res["ok"], "loan signed (%s)" % res["msg"]) and ok
	ok = _assert(career.my_squad().size() == squad0 + 1, "loanee joined the squad") and ok
	ok = _assert(career.cash == cash0, "a loan costs no transfer fee") and ok
	ok = _assert(career.offers_left == offers0 - 1, "a loan spends one weekly offer") and ok
	var loanee := career._find_in(career.club_id, pid)
	ok = _assert(bool(loanee.get("on_loan")) and int(loanee.get("loan_from", -1)) == parent,
		"loanee carries the on_loan + parent state") and ok
	ok = _assert(not _has(career.rosters[parent], pid), "loanee left the parent's roster") and ok

	# Can't sell a player who is only on loan.
	var sale := career.accept_sale(pid, parent, 1_000_000)
	ok = _assert(not sale["ok"] and "loan" in sale["msg"].to_lower(), "a loanee cannot be sold") and ok

	# Offer guard: no offers left -> a loan is blocked outright.
	career.offers_left = 0
	if mkt.size() > 1:
		var blocked := career.sign_loan(int(mkt[1]["pid"]), int(mkt[1]["club_id"]))
		ok = _assert(not blocked["ok"], "no offers left -> loan blocked") and ok

	# Rollover: the loanee returns to his parent club.
	career.advance_season(leagues, rng)
	ok = _assert(not _has(career.rosters[career.club_id], pid), "loanee left your squad at the rollover") and ok
	ok = _assert(_has(career.rosters[parent], pid), "loanee returned to his parent club") and ok
	var back := career._find_in(parent, pid)
	ok = _assert(not back.get("on_loan", false), "returned player's on_loan flag is cleared") and ok

	# Save / load round-trips an active loan.
	var c2 := Career.create(prem[1], league, prem, leagues)
	var m2 := c2.loan_market()
	c2.sign_loan(int(m2[0]["pid"]), int(m2[0]["club_id"]))
	var lpid := int(m2[0]["pid"])
	var path := "user://loans_test.json"
	c2.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and bool(loaded._find_in(loaded.club_id, lpid).get("on_loan")),
		"an active loan survived save/load") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _has(pool: Array, pid: int) -> bool:
	for p in pool:
		if int(p.get("id", -1)) == pid:
			return true
	return false


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
