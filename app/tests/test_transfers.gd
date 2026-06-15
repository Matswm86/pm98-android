extends SceneTree
## Headless tests for the S7 transfer layer: valuation, the market, offer
## evaluation, sign/sell/renew with board caps, the AI round, season rollover and
## persistence.
##   ~/godot462 --headless --path app --script res://tests/test_transfers.gd


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
	ok = _valuation() and ok
	ok = _market_and_offers(prem, league, leagues) and ok
	ok = _sign_sell_renew(prem, league, leagues) and ok
	ok = _ai_and_season(prem, league, leagues) and ok
	ok = _persistence(prem, league, leagues) and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# A surplus (non-first-XI) outfielder of `club`, with the club's player id.
func _surplus_outfielder(club: Dictionary) -> Dictionary:
	var view := {"id": int(club["id"]), "name": club.get("name", "?"), "players": club.get("players", [])}
	var key := TransferMarket.best_xi_ids(view)
	for p in club.get("players", []):
		if not p.get("isGK") and not key.has(int(p["id"])):
			return p
	return club["players"][0]


func _valuation() -> bool:
	var ok := true
	var young := {"age": 25, "attrs": {"CA": 80}}
	var old := {"age": 34, "attrs": {"CA": 80}}
	var weak := {"age": 25, "attrs": {"CA": 55}}
	var v_young := TransferMarket.value_of(young, 1)
	var v_old := TransferMarket.value_of(old, 1)
	var v_weak := TransferMarket.value_of(weak, 1)
	ok = _assert(v_young > v_weak, "higher CA worth more (£%d > £%d)" % [v_young, v_weak]) and ok
	ok = _assert(v_old < v_young, "age 34 discounted vs 25 (£%d < £%d)" % [v_old, v_young]) and ok
	ok = _assert(TransferMarket.value_of(young, 1) > TransferMarket.value_of(young, 4),
		"tier-1 fee > tier-4 fee for same player") and ok
	ok = _assert(TransferMarket.value_of(young, 1) >= TransferMarket._MIN_FEE, "fee respects floor") and ok
	ok = _assert(TransferMarket.wage_yearly(young, 1) > 0, "yearly wage positive") and ok
	return ok


func _market_and_offers(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var mkt := career.market()
	ok = _assert(not mkt.is_empty(), "market lists players (%d)" % mkt.size()) and ok
	var none_mine := true
	for row in mkt:
		if int(row["club_id"]) == career.club_id:
			none_mine = false
	ok = _assert(none_mine, "market excludes the manager's own club") and ok
	ok = _assert(int(mkt[0]["fee"]) >= int(mkt[mkt.size() - 1]["fee"]), "market sorted dearest first") and ok

	# Offer evaluation: a surplus player sells at asking; below asking is refused.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seller: Dictionary = prem[1]
	var surplus := _surplus_outfielder(seller)
	var ask := TransferMarket.asking_price(surplus, false, career.tier)
	var at := TransferMarket.evaluate_offer(surplus, ask, false, career.tier, rng)
	var below := TransferMarket.evaluate_offer(surplus, ask - 1, false, career.tier, rng)
	ok = _assert(at["accepted"], "surplus player accepts at asking £%d" % ask) and ok
	ok = _assert(not below["accepted"], "offer below asking refused") and ok
	# A first-XI man costs the premium.
	var key_id := -1
	for pid in TransferMarket.best_xi_ids({"id": int(seller["id"]), "name": "", "players": seller["players"]}):
		key_id = int(pid)
		break
	var keyp := TransferMarket._find(seller["players"], key_id)
	ok = _assert(TransferMarket.asking_price(keyp, true, career.tier)
		> TransferMarket.value_of(keyp, career.tier), "first-XI asking carries a premium") and ok
	return ok


func _sign_sell_renew(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var seller_id := int(prem[1]["id"])
	var target := _surplus_outfielder(prem[1])
	var tid := int(target["id"])
	var ask := TransferMarket.asking_price(target, false, career.tier)

	# Money guard.
	career.cash = ask - 1
	var poor := career.sign_player(tid, seller_id, ask, rng)
	ok = _assert(not poor["ok"] and poor["msg"].contains("enough money"), "blocked when too poor") and ok

	# A clean signing mutates both squads + cash + the weekly offer allowance.
	career.cash = 50_000_000
	var my0 := career.my_squad().size()
	var sell0: int = (career.rosters[seller_id] as Array).size()
	var offers0 := career.offers_left
	var bought := career.sign_player(tid, seller_id, ask, rng)
	ok = _assert(bought["ok"], "signed surplus player at asking") and ok
	ok = _assert(career.my_squad().size() == my0 + 1, "buyer squad +1") and ok
	ok = _assert((career.rosters[seller_id] as Array).size() == sell0 - 1, "seller squad -1") and ok
	ok = _assert(career.cash == 50_000_000 - ask, "cash debited by the fee") and ok
	ok = _assert(career.offers_left == offers0 - 1, "weekly offer allowance decremented") and ok
	ok = _assert(career._find_in(career.club_id, tid).get("contract_years", 0) == TransferMarket.NEW_CONTRACT_YEARS,
		"signing gets a fresh contract") and ok

	# Offer cap.
	career.offers_left = 0
	var capped := career.sign_player(int(_surplus_outfielder(prem[2])["id"]), int(prem[2]["id"]), 1_000_000, rng)
	ok = _assert(not capped["ok"] and capped["msg"].contains("offer"), "blocked when no offers left") and ok

	# Deadline guard.
	career.offers_left = 3
	career.week = career.total_weeks()   # past the window
	ok = _assert(not career.transfers_open(), "window shut at season end") and ok
	var late := career.sign_player(int(_surplus_outfielder(prem[3])["id"]), int(prem[3]["id"]), 1_000_000, rng)
	ok = _assert(not late["ok"] and late["msg"].contains("deadline"), "blocked after the deadline") and ok

	# Renew.
	career.week = 0
	var mine: Dictionary = career.my_squad()[0]
	mine["contract_years"] = 1
	var rn := career.renew(int(mine["id"]))
	ok = _assert(rn["ok"] and int(mine["contract_years"]) == TransferMarket.NEW_CONTRACT_YEARS, "RENEW resets contract") and ok

	# Sell: solicit an AI offer, accept it, squad shrinks + cash grows.
	var to_sell: Dictionary = career.my_squad()[career.my_squad().size() - 1]
	var spid := int(to_sell["id"])
	var offer := career.solicit_sale(spid, rng)
	ok = _assert(not offer.is_empty(), "an AI club tables an offer") and ok
	var cash_b := career.cash
	var sq_b := career.my_squad().size()
	var sold := career.accept_sale(spid, int(offer["buyer_id"]), int(offer["offer"]))
	ok = _assert(sold["ok"], "sale accepted") and ok
	ok = _assert(career.my_squad().size() == sq_b - 1, "squad -1 after sale") and ok
	ok = _assert(career.cash == cash_b + int(offer["offer"]), "cash credited the fee") and ok

	# Sell guard: can't drop below the squad floor.
	while career.my_squad().size() > TransferMarket.SQUAD_MIN:
		(career.rosters[career.club_id] as Array).pop_back()
	var p_last: Dictionary = career.my_squad()[0]
	var blocked := career.accept_sale(int(p_last["id"]), seller_id, 1_000_000)
	ok = _assert(not blocked["ok"], "blocked from selling below the squad minimum") and ok
	return ok


func _ai_and_season(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99

	var total_before := 0
	for cid in career.rosters:
		total_before += (career.rosters[cid] as Array).size()
	var moved := 0
	for _i in 30:
		var news := TransferMarket.ai_round(rng, career.rosters, career.club_names, career.club_id, career.tier)
		moved += news.size()
	var total_after := 0
	for cid in career.rosters:
		total_after += (career.rosters[cid] as Array).size()
	ok = _assert(total_after == total_before, "AI round conserves total players (%d)" % total_after) and ok
	ok = _assert(moved > 0, "AI round produced some transfers over 30 rounds (%d)" % moved) and ok

	# Season rollover: contracts tick, an unrenewed player leaves, the calendar resets.
	var leaver: Dictionary = career.my_squad()[0]
	leaver["contract_years"] = 1
	var leaver_id := int(leaver["id"])
	var prev_year := career.year
	career.week = 5
	career.advance_season(leagues)
	ok = _assert(career.year == prev_year + 1, "year advanced") and ok
	ok = _assert(career.week == 0 and not career.finished, "calendar reset for the new season") and ok
	ok = _assert(career.total_weeks() == 38, "fixtures rebuilt (38 rounds)") and ok
	ok = _assert(career._find_in(career.club_id, leaver_id).is_empty(), "unrenewed player left on a free") and ok
	return ok


func _persistence(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var ok := true
	var career := Career.create(prem[0], league, prem, leagues)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	career.cash = 50_000_000
	var target := _surplus_outfielder(prem[1])
	career.sign_player(int(target["id"]), int(prem[1]["id"]), TransferMarket.asking_price(target, false, career.tier), rng)
	career.toggle_shortlist(int(_surplus_outfielder(prem[2])["id"]))

	var path := "user://transfers_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career loaded from disk") and ok
	if loaded != null:
		ok = _assert(loaded.tier == career.tier, "tier survived round-trip") and ok
		ok = _assert(loaded.rosters.size() == career.rosters.size(), "rosters survived round-trip") and ok
		ok = _assert(loaded.my_squad().size() == career.my_squad().size(), "managed squad size preserved") and ok
		ok = _assert(loaded.shortlist == career.shortlist, "shortlist preserved") and ok
		ok = _assert(loaded.transfer_log.size() == career.transfer_log.size(), "transfer log preserved") and ok
		ok = _assert(loaded.club_names.size() == career.club_names.size(), "club names preserved") and ok
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
