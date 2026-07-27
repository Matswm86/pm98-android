extends SceneTree
## Headless test for the FINANCES detail-view data layer (2026-07-27):
## the per-competition / sub-row DETAIL record behind the INCOME and EXPENSES
## detail views, the running-week live book, and the stored close-of-week cash.
##   ~/godot462 --headless --path app --script res://tests/test_finance_detail.gd

var _fails := 0


func _initialize() -> void:
	_run_model()
	_run_career()
	if _fails == 0:
		print("ALL PASS")
	quit(0 if _fails == 0 else 1)


func _run_model() -> void:
	var rec := FinanceModel.new_week_ledger(7)
	_assert(rec.has("detail"), "new_week_ledger carries a detail record")
	var det: Dictionary = FinanceModel.ledger_detail(rec)
	_assert(int(det.get("wage_gross", -1)) == 0 and (det.get("sales", []) as Array).is_empty(),
		"fresh detail is zeroed")
	# A legacy record (pre-2026-07-27 save) heals: gross sub-rows read the net line.
	var legacy := {"week": 3, "income": {}, "expense": {"PLAYERS' WAGE": 1000, "HOSPITALS": 200}}
	var healed := FinanceModel.ledger_detail(legacy)
	_assert(int(healed["wage_gross"]) == 1000 and int(healed["hosp_gross"]) == 200,
		"legacy record heals gross = net line")
	_assert((healed["comp"] as Dictionary).is_empty(), "legacy comp split stays honestly empty")


func _run_career() -> void:
	var c := Career.new()
	_assert(Career._comp_bucket("league") == "league", "league bucket")
	_assert(Career._comp_bucket("cup:F.A. CUP") == "domestic", "domestic-cup bucket")
	_assert(Career._comp_bucket("european_cup") == "euro", "euro bucket")
	_assert(Career._comp_bucket("charity_shield") == "charity", "charity bucket")

	# European points money lands on the line AND the euro POINTS detail cell.
	c.cash = 0
	c._post_euro_points(510_000)
	_assert(c.cash == 510_000, "euro points bank")
	var live := c.live_week_book()
	_assert(int(live["income"]["EUROPEAN CUP INCOME"]) == 510_000, "euro points line")
	var comp: Dictionary = FinanceModel.ledger_detail(live)["comp"]
	_assert(int((comp.get("euro", {}) as Dictionary).get("POINTS", 0)) == 510_000,
		"euro points detail cell")

	# A GROUND work splits by category (the frame's SEATS..EXTRAS rows).
	c.cash = 1_000_000
	_assert(c.begin_work("carpark", 1, "spaces", 40_000, 4, {"added": 100}), "begin_work ok")
	var gnd: Dictionary = FinanceModel.ledger_detail(c.live_week_book())["ground"]
	_assert(int(gnd.get("carpark", 0)) == 40_000, "ground split by category")

	# Closing the week banks the record, stores the close-of-week cash, and the
	# next live book starts empty.
	var cash_at_close := c.cash
	c._close_week_books()
	_assert(c.week_books().size() == 1, "week banked")
	_assert(c.live_week_book().is_empty(), "live book reset")
	_assert(c.cash_at_close() == cash_at_close, "close-of-week cash stored")
	# Money posted into the NEW week moves the bank but not the stored close figure.
	c._post_income("SALE + LOAN PLAY.", 9_120_000)
	_assert(c.cash == cash_at_close + 9_120_000, "sale banks into the new week")
	_assert(c.cash_at_close() == cash_at_close, "close figure is stored, not derived")


func _assert(cond: bool, label: String) -> void:
	if cond:
		print("  [PASS] %s" % label)
	else:
		_fails += 1
		printerr("  [FAIL] %s" % label)
