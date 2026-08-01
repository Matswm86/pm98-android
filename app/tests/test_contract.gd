extends SceneTree
## Headless test for player contracts & wages (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_contract.gd
## Covers the Contract unit model (market/current/demanded wage, the never-a-cut floor,
## ambition by age, renewal offer monotonicity, the accept/reject thresholds, expiring,
## the squad wage bill) and the Career integration (wages stamped at create, the live bill
## drawn from cash each week, a signing lifting the bill, the RENEW negotiation accepting /
## rejecting, auto-renew at the season rollover, and persistence incl. legacy-save migration).

const SEED := 1357911


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
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
	if prem.size() != 20 or league.is_empty():
		push_error("expected 20 Premier clubs + league dict")
		return false

	var ok := true
	ok = _unit_wages() and ok
	ok = _unit_demand() and ok
	ok = _unit_renewal() and ok
	ok = _career_bill(prem, league, leagues) and ok
	ok = _career_negotiation(prem, league, leagues) and ok
	ok = _career_autorenew(prem, league, leagues) and ok
	ok = _career_persistence(prem, league, leagues) and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- unit: wages ---------------------------------------------------------

func _unit_wages() -> bool:
	var ok := true
	var p := {"age": 26, "attrs": {"CA": 70}}
	var mkt := Contract.market_weekly(p, 1)
	ok = _assert(mkt > 0, "market wage positive (£%d/wk)" % mkt) and ok
	ok = _assert(Contract.current_weekly(p, 1) == mkt, "current wage falls back to market when unstamped") and ok
	Contract.stamp_wage(p, 1)
	ok = _assert(int(p.get("wage", -1)) == mkt, "stamp_wage stores the market wage") and ok
	p["wage"] = mkt + 5000
	ok = _assert(Contract.current_weekly(p, 1) == mkt + 5000, "current wage honours a stored (raised) wage") and ok
	# Tier scaling + yearly/monthly conversions.
	ok = _assert(Contract.market_weekly(p, 0) > Contract.market_weekly(p, 12), "band-0 (elite) wage > band-12 (lowest) wage") and ok
	ok = _assert(Contract.yearly(2000) == 2000 * Contract.SEASON_WEEKS, "yearly = weekly x season weeks") and ok
	ok = _assert(Contract.monthly(5200) == int(round(5200 * 52 / 12.0)), "monthly conversion") and ok
	# Squad bill sums current wages.
	var squad := [{"wage": 1000}, {"wage": 2500}, {"attrs": {"CA": 50}}]
	var bill := Contract.squad_weekly_bill(squad, 1)
	ok = _assert(bill == 1000 + 2500 + Contract.market_weekly(squad[2], 1), "squad bill sums current wages") and ok
	return ok


# ---- unit: demand --------------------------------------------------------

func _unit_demand() -> bool:
	var ok := true
	var young := {"age": 20, "attrs": {"CA": 75}}
	var prime := {"age": 27, "attrs": {"CA": 75}}
	var vet := {"age": 34, "attrs": {"CA": 75}}
	var dy := Contract.demanded_weekly(young, 1)
	var dp := Contract.demanded_weekly(prime, 1)
	var dv := Contract.demanded_weekly(vet, 1)
	var my := Contract.market_weekly(young, 1)
	var mp := Contract.market_weekly(prime, 1)
	var mv := Contract.market_weekly(vet, 1)
	# CORRECTED 2026-08-01 (Contract.demanded_weekly): the demand is HIS CURRENT TERMS,
	# floored at his market rate. The invented age/CA "ambition" premium is gone — the one
	# witnessed renewal on the real game accepted his exact current terms silently
	# (renew_negotiation_re.md §Mechanics witnessed), which the premium made impossible.
	# These three assertions used to pin the premium; they now pin its absence.
	ok = _assert(dy == my and dp == mp and dv == mv,
		"an unstamped player asks exactly his market wage, no premium (%d/%d/%d)" % [dy, dp, dv]) and ok
	# Never a pay cut: demand is floored at the current wage even for a veteran.
	vet["wage"] = dv + 9000
	ok = _assert(Contract.demanded_weekly(vet, 1) >= int(vet["wage"]), "demand never undercuts the current wage") and ok
	# ...and a player already ON his market wage re-signs at exactly that — the witness.
	var settled := {"age": 27, "attrs": {"CA": 75}}
	Contract.stamp_wage(settled, 1)
	ok = _assert(Contract.demanded_weekly(settled, 1) == int(settled["wage"]),
		"a player on his market wage asks for exactly it (the witnessed renewal)") and ok
	# A stronger player is still worth more, through the RE'd wage table itself.
	var weak := {"age": 27, "attrs": {"CA": 45}}
	ok = _assert(Contract.demanded_weekly(prime, 1) > Contract.demanded_weekly(weak, 1),
		"higher CA demands more at the same age") and ok
	return ok


# ---- unit: renewal offers + accept/reject --------------------------------

func _unit_renewal() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var young := {"age": 21, "attrs": {"CA": 78}}
	Contract.stamp_wage(young, 1)
	var opts := Contract.renewal_options(young, 1)
	ok = _assert(opts.size() == 3, "three renewal offers") and ok
	ok = _assert(int(opts[0]["weekly"]) <= int(opts[1]["weekly"]) and int(opts[1]["weekly"]) <= int(opts[2]["weekly"]),
		"offers monotonic: hold <= meet <= better") and ok
	ok = _assert(int(opts[1]["years"]) == Contract.NEW_TERM_YEARS, "a renewal runs the new term") and ok
	var dem := Contract.demanded_weekly(young, 1)
	# Meeting / bettering the demand always re-signs him.
	ok = _assert(bool(Contract.evaluate_renewal(young, dem, 1, rng)["accepted"]), "meeting the demand is accepted") and ok
	ok = _assert(bool(Contract.evaluate_renewal(young, dem + 1000, 1, rng)["accepted"]), "bettering the demand is accepted") and ok
	# His CURRENT terms are now exactly his demand, so they re-sign him — the witness
	# ("offering his exact current terms accepted silently", frame 28_offerresult).
	ok = _assert(bool(Contract.evaluate_renewal(young, int(young["wage"]), 1, rng)["accepted"]),
		"his current terms re-sign him (the witnessed silent accept)") and ok
	# A real lowball — under the soft-floor band — is still refused every time, which is
	# what the engine's "%s has rejected your offer for renewal." string exists for.
	var refusals := 0
	var low := int(round(float(dem) * (Contract.SOFT_FLOOR - 0.05)))
	for _i in 20:
		if not Contract.evaluate_renewal(young, low, 1, rng)["accepted"]:
			refusals += 1
	ok = _assert(refusals == 20, "a lowball under the soft floor is always refused") and ok
	# Expiring flag.
	ok = _assert(Contract.is_expiring({"contract_years": 1}), "1-year deal is expiring") and ok
	ok = _assert(not Contract.is_expiring({"contract_years": 3}), "3-year deal is not expiring") and ok
	return ok


# ---- Career: the live wage bill -> cash ----------------------------------

func _career_bill(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# Every seed player is stamped with a wage; the bill is positive.
	var all_stamped := true
	for p in career.my_squad():
		if p.get("wage") == null:
			all_stamped = false
	ok = _assert(all_stamped, "create stamps a wage on every seed player") and ok
	var bill := career.player_weekly_wage()
	ok = _assert(bill > 0, "live player wage bill positive (£%d/wk)" % bill) and ok
	# A week's cash delta is exactly that week's BOOKS (REFRUN R5/R9): PLAYERS' WAGE +
	# STAFF WAGES are charged every week, income only on a home matchday, and the ledger
	# and the bank can never disagree because every movement posts through both.
	var cash_b := career.cash
	career.advance_week(rng)
	var rec: Dictionary = career.week_ledgers[-1]
	ok = _assert(career.cash == cash_b + FinanceModel.ledger_balance(rec),
		"the week's cash delta == the week's ledger balance") and ok
	ok = _assert(int(rec["expense"]["PLAYERS' WAGE"]) == bill,
		"PLAYERS' WAGE booked at the live squad bill (£%d)" % bill) and ok
	ok = _assert(int(rec["expense"]["STAFF WAGES"]) == career.staff_weekly_wage(),
		"STAFF WAGES booked at the live staff bill") and ok
	# Signing a player lifts the bill by his wage.
	var seller_id := int(prem[1]["id"])
	var target := _surplus_outfielder(_club_view(career, seller_id))
	career.week = 0
	career.offers_left = Career.OFFERS_PER_WEEK
	var bill_before := career.player_weekly_wage()
	var res := career.sign_player(int(target["id"]), seller_id, career.cash, rng)
	ok = _assert(res["ok"], "signed a player for the bill test") and ok
	var signed := career._find_in(career.club_id, int(target["id"]))
	ok = _assert(career.player_weekly_wage() == bill_before + Contract.current_weekly(signed, career.my_band()),
		"the wage bill rises by the new signing's wage") and ok
	return ok


# ---- Career: the RENEW negotiation ---------------------------------------

func _career_negotiation(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var p: Dictionary = career.my_squad()[0]
	p["contract_years"] = 1
	var pid := int(p["id"])
	var cur := Contract.current_weekly(p, career.my_band())
	var dem := Contract.demanded_weekly(p, career.my_band())
	# A real lowball — under the soft-floor band — is rejected with the faithful message
	# and changes nothing. (Since 2026-08-01 his CURRENT terms are his demand, so the
	# lowball has to be a genuine one; see Contract.demanded_weekly.)
	var low_offer := int(round(float(dem) * (Contract.SOFT_FLOOR - 0.05)))
	var low := career.renew(pid, low_offer, rng)
	ok = _assert(not low["ok"] and low["msg"].contains("rejected your offer for renewal"),
		"a lowball renewal is rejected (PM98 message)") and ok
	ok = _assert(int(low["demanded"]) == dem, "the rejection reports his wage demand") and ok
	ok = _assert(int(p["contract_years"]) == 1 and Contract.current_weekly(p, career.my_band()) == cur,
		"a rejected renewal leaves his deal untouched") and ok
	# Meeting the demand re-signs him: term resets and his stored wage updates to the offer.
	var good := career.renew(pid, dem, rng)
	ok = _assert(good["ok"] and good["msg"].contains("renewed his contract"), "meeting the demand renews him") and ok
	ok = _assert(int(p["contract_years"]) == Contract.NEW_TERM_YEARS, "renewal resets the term") and ok
	ok = _assert(int(p["wage"]) == dem, "renewal stores the agreed wage") and ok
	# The OFFERED term is honoured (offer_record_re.md §3: YEARS runs 1..5), instead of
	# every renewal stamping NEW_TERM_YEARS.
	p["contract_years"] = 1
	var five := career.renew(pid, dem, rng, 5, [])
	ok = _assert(five["ok"] and int(p["contract_years"]) == 5 and int(p["contract_term"]) == 5,
		"a 5-year offer signs a 5-year deal (term %d)" % int(p["contract_years"])) and ok
	# ...and so are the OFFERED clauses. On a 1-year deal MATCHES TO RENEW sticks and
	# carries the engine's own 20-match target; on a longer one the engine clears it
	# (@0x529e40), exactly as at generation.
	p["contract_years"] = 1
	var cl1 := career.renew(pid, dem, rng, 1,
		[OfferRecord.CLAUSE_FREE_IF_RELEGATED, OfferRecord.CLAUSE_MATCHES_TO_RENEW])
	ok = _assert(cl1["ok"] and (p.get("clauses", []) as Array).has(OfferRecord.CLAUSE_MATCHES_TO_RENEW)
		and int(p.get("clause_matches", 0)) == OfferRecord.MATCHES_TO_RENEW,
		"a 1-year offer can add MATCHES TO RENEW (target %d)" % int(p.get("clause_matches", 0))) and ok
	var cl3 := career.renew(pid, dem, rng, 3,
		[OfferRecord.CLAUSE_FREE_IF_RELEGATED, OfferRecord.CLAUSE_MATCHES_TO_RENEW])
	ok = _assert(cl3["ok"] and not (p.get("clauses", []) as Array).has(OfferRecord.CLAUSE_MATCHES_TO_RENEW)
		and not p.has("clause_matches"),
		"a term above one year clears MATCHES TO RENEW") and ok
	ok = _assert((p.get("clauses", []) as Array).has(OfferRecord.CLAUSE_FREE_IF_RELEGATED),
		"the other offered clauses stick") and ok
	# ...and an empty clause list REMOVES them.
	var cl0 := career.renew(pid, dem, rng, 3, [])
	ok = _assert(cl0["ok"] and (p.get("clauses", []) as Array).is_empty(),
		"offering no clauses removes them") and ok
	# Default renew(pid) meets his demand and always succeeds (back-compat with the old call).
	p["contract_years"] = 1
	ok = _assert(career.renew(pid)["ok"], "default renew(pid) meets the demand and succeeds") and ok
	return ok


# ---- Career: auto-renew at the rollover ----------------------------------

func _career_autorenew(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	career.cash = 50_000_000   # plenty to fund any auto-renewal
	# An expiring player WITH auto-renew is kept; one WITHOUT leaves on a free.
	var keep: Dictionary = career.my_squad()[0]
	var drop: Dictionary = career.my_squad()[1]
	keep["contract_years"] = 1
	drop["contract_years"] = 1
	career.set_auto_renew(int(keep["id"]), true)
	career.set_auto_renew(int(drop["id"]), false)
	var keep_id := int(keep["id"])
	var drop_id := int(drop["id"])
	var keep_dem := Contract.demanded_weekly(keep, career.my_band())
	career.week = 5
	career.advance_season(leagues)
	var kept := career._find_in(career.club_id, keep_id)
	ok = _assert(not kept.is_empty(), "auto-renew keeps an expiring player") and ok
	ok = _assert(int(kept.get("contract_years", 0)) == Contract.NEW_TERM_YEARS, "auto-renew resets his term") and ok
	ok = _assert(int(kept.get("wage", 0)) == keep_dem, "auto-renew re-signs him at his demand") and ok
	ok = _assert(career._find_in(career.club_id, drop_id).is_empty(), "no auto-renew -> left on a free") and ok
	# Auto-renew is skipped when the club can't fund the deal -> he leaves.
	var career2 := Career.create(prem[0], league, prem, leagues)
	career2.cash = 0
	var poor: Dictionary = career2.my_squad()[0]
	poor["contract_years"] = 1
	career2.set_auto_renew(int(poor["id"]), true)
	var poor_id := int(poor["id"])
	career2.week = 5
	career2.advance_season(leagues)
	ok = _assert(career2._find_in(career2.club_id, poor_id).is_empty(), "unaffordable auto-renew still leaves on a free") and ok
	return ok


# ---- Career: persistence + legacy migration ------------------------------

func _career_persistence(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var p: Dictionary = career.my_squad()[0]
	p["wage"] = 12345
	p["auto_renew"] = true
	# Round-trip keeps wages + auto-renew + the wage-free weekly_net.
	var c2 := Career.from_dict(career.to_dict())
	var p2 := c2._find_in(c2.club_id, int(p["id"]))
	ok = _assert(int(p2.get("wage", -1)) == 12345, "stored wage survives save/load") and ok
	ok = _assert(bool(p2.get("auto_renew", false)), "auto-renew flag survives save/load") and ok
	ok = _assert(c2.weekly_net == career.weekly_net, "weekly_net unchanged on a modern round-trip") and ok
	ok = _assert(c2.player_weekly_wage() == career.player_weekly_wage(), "wage bill survives save/load") and ok
	# Legacy save: weekly_net BAKED IN the player wages, no `wage` on players, no marker. The
	# migration adds the bill back so the weekly burn is identical under the live-draw loop.
	var d := career.to_dict()
	var old_net := career.weekly_net - career.player_weekly_wage()   # the old wage-inclusive net
	d["weekly_net"] = old_net
	d.erase("wages_live")
	for cid in d["rosters"]:
		for pl in d["rosters"][cid]:
			(pl as Dictionary).erase("wage")
	var c3 := Career.from_dict(d)
	ok = _assert(c3.weekly_net == old_net + c3.player_weekly_wage(), "legacy save migrates weekly_net to the wage-free basis") and ok
	# The whole point: under the live-draw loop, the migrated save's weekly burn (net minus the
	# live bill) equals the legacy stored net, so an old career's economy is unchanged.
	ok = _assert(c3.weekly_net - c3.player_weekly_wage() == old_net, "migration preserves the legacy weekly burn") and ok
	return ok


# ---- helpers -------------------------------------------------------------

func _club_view(career: Career, cid: int) -> Dictionary:
	return {"id": cid, "name": career.club_names.get(cid, "?"), "players": career.rosters.get(cid, [])}

func _surplus_outfielder(club: Dictionary) -> Dictionary:
	var view := {"id": int(club["id"]), "name": club.get("name", "?"), "players": club.get("players", [])}
	var key := TransferMarket.best_xi_ids(view)
	for p in club.get("players", []):
		if not p.get("isGK") and not key.has(int(p["id"])):
			return p
	return club["players"][0]

func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
