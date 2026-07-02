extends SceneTree
## Headless tests for the CURRENT OFFERS accumulation (bids on your transfer-listed
## players): weekly accumulation caps at 5 rows per player (the FUN_00523ed0 band),
## accept routes through accept_sale's guards and clears the band, refuse removes one
## bid, unlisting withdraws every bid, and the store survives a save/load roundtrip.
##   ~/godot462 --headless --path app --script res://tests/test_current_offers.gd


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var league: Dictionary = {}
	var prem: Array = []
	for lg in db.get("leagues", []):
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.size() != 20 or league.is_empty():
		push_error("expected 20 Premier clubs + league")
		return false

	var ok := true
	var c := Career.create(prem[0], league, prem, [league])
	var rng := RandomNumberGenerator.new()
	rng.seed = 98

	# List an outfielder; bids accumulate over the weeks, never past the 5-row band.
	var victim: Dictionary = {}
	for p in c.my_squad():
		if not p.get("isGK"):
			victim = p
			break
	var pid := int(victim["id"])
	c.toggle_listed(pid)
	ok = _assert(c.is_listed(pid), "player listed") and ok
	for _i in 20:
		c._accumulate_offers(rng)
	var n := c.offers_for(pid).size()
	ok = _assert(n >= 1, "bids arrived over 20 weeks (got %d)" % n) and ok
	ok = _assert(n <= Career.MAX_OFFERS_PER_PLAYER,
		"band cap respected (%d <= 5)" % n) and ok
	var o: Dictionary = c.offers_for(pid)[0]
	for k in ["buyer_id", "buyer_name", "offer", "weekly_wage", "years", "week"]:
		ok = _assert(o.has(k), "offer row carries %s" % k) and ok
	ok = _assert(int(o["buyer_id"]) != c.club_id, "bidder is another club") and ok

	# An unlisted player never draws bids.
	var keeper_pid := -1
	for p in c.my_squad():
		if p.get("isGK"):
			keeper_pid = int(p["id"])
			break
	ok = _assert(c.offers_for(keeper_pid).is_empty(), "no bids on an unlisted player") and ok

	# Save/load roundtrip preserves the store (string->int key rehydration).
	var d := c.to_dict()
	var c2 := Career.from_dict(d)
	ok = _assert(c2.offers_for(pid).size() == n, "pending offers survive save/load") and ok
	ok = _assert(c2.offers_for(pid)[0]["buyer_name"] == o["buyer_name"],
		"offer fields survive save/load") and ok

	# Refuse one bid: the row goes, the listing stays.
	var before := c.offers_for(pid).size()
	var r := c.refuse_offer(pid, 0)
	ok = _assert(bool(r["ok"]), "refuse_offer ok") and ok
	ok = _assert(c.offers_for(pid).size() == before - 1, "refused bid removed") and ok
	ok = _assert(c.is_listed(pid), "listing survives a refusal") and ok
	ok = _assert(not bool(c.refuse_offer(pid, 99)["ok"]), "refusing a phantom bid fails") and ok

	# Accept: the sale goes through (squad shrinks, cash lands) and the band clears.
	while c.offers_for(pid).is_empty():
		c._accumulate_offers(rng)
	var offer_amt: int = int(c.offers_for(pid)[0]["offer"])
	var buyer_id: int = int(c.offers_for(pid)[0]["buyer_id"])
	var cash0 := c.cash
	var squad0 := c.my_squad().size()
	var buyer_squad0: int = (c.rosters[buyer_id] as Array).size()
	var a := c.accept_offer(pid, 0)
	ok = _assert(bool(a["ok"]), "accept_offer ok (%s)" % a.get("msg", "")) and ok
	ok = _assert(c.cash == cash0 + offer_amt, "fee lands in the bank") and ok
	ok = _assert(c.my_squad().size() == squad0 - 1, "player left the squad") and ok
	ok = _assert((c.rosters[buyer_id] as Array).size() == buyer_squad0 + 1,
		"player joined the buyer") and ok
	ok = _assert(c.offers_for(pid).is_empty(), "band cleared after the sale") and ok
	ok = _assert(not c.is_listed(pid), "listing cleared after the sale") and ok

	# Unlisting withdraws the bids.
	var victim2: Dictionary = {}
	for p in c.my_squad():
		if not p.get("isGK"):
			victim2 = p
			break
	var pid2 := int(victim2["id"])
	c.toggle_listed(pid2)
	while c.offers_for(pid2).is_empty():
		c._accumulate_offers(rng)
	c.toggle_listed(pid2)
	ok = _assert(c.offers_for(pid2).is_empty(), "unlisting withdraws the bids") and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
