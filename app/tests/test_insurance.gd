extends SceneTree
## Locks the BINARY-EXACT insurance economy (docs/re/insurance_economy_re.md):
## FUN_0058c020 (premium), FUN_0058c000 (payout %), FUN_00584e00 (injury price),
## FUN_0058bfd0 (the group 3 weekly bonus), the INJURIES row's COST arithmetic
## @0x543ca7 and the weekly finance pass @0x57f3a6. Every expected number below is
## a MANAGER.EXE constant or the 2026-07-18 wine witness, not a tuned figure.
##   ~/godot462 --headless --path app --script res://tests/test_insurance.gd

var _fails := 0


func _initialize() -> void:
	_premium()
	_payout()
	_injury_price()
	_injury_cost()
	_hospital()
	_group3_bonus()
	_weekly_pass()
	_career_week()
	if _fails == 0:
		print("INSURANCE: ALL GREEN")
	else:
		print("INSURANCE: %d FAILURES" % _fails)
	quit(1 if _fails > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   %s" % msg)
	else:
		_fails += 1
		print("  FAIL %s" % msg)


# FUN_0058c020: monthly/{150,120,70}, clamped up to 40000/100000/200000 internal,
# then floored to a multiple of 1000 internal (= £5).
func _premium() -> void:
	_ok(Insurance.premium_internal(0, 10_000_000) == 0, "group 0 pays no premium")
	_ok(Insurance.premium_internal(9, 10_000_000) == 0, "unknown group pays no premium")
	# Both wine witnesses sit under the clamp -> the flat witnessed prices.
	for mw in [1250, 14583]:
		_ok(Insurance.premium_monthly(1, mw) == 200, "witness %d -> group 1 = £200" % mw)
		_ok(Insurance.premium_monthly(2, mw) == 500, "witness %d -> group 2 = £500" % mw)
		_ok(Insurance.premium_monthly(3, mw) == 1000, "witness %d -> group 3 = £1,000" % mw)
	# The clamp corners, in internal units: group 1 leaves £200 at monthly/150 == 40000.
	_ok(Insurance.premium_internal(1, 150 * 40_000) == 40_000, "group 1 exactly at the clamp")
	_ok(Insurance.premium_internal(1, 150 * 41_000) == 41_000, "group 1 just above the clamp")
	# ... and the £5 floor: 150 * 40_500 / 150 = 40_500 -> floored to 40_000.
	_ok(Insurance.premium_internal(1, 150 * 40_500) == 40_000, "premium floors to a multiple of £5")
	_ok(Insurance.premium_internal(2, 120 * 100_000) == 100_000, "group 2 exactly at the clamp")
	_ok(Insurance.premium_internal(3, 70 * 200_000) == 200_000, "group 3 exactly at the clamp")
	# £30,000 a month is where a group 1 policy leaves the clamp (30000*200/150 = 40000).
	_ok(Insurance.premium_monthly(1, 30_000) == 200, "£30,000/month is still £200")
	_ok(Insurance.premium_monthly(1, 60_000) == 400, "£60,000/month doubles the group 1 premium")
	# The weekly charge is premium x 12 / 52, integer, in internal units.
	_ok(Insurance.premium_weekly_internal(1, 0) == 40_000 * 12 / 52, "weekly charge = premium x 12/52")


# FUN_0058c000: 50 for group 2, 100 for group 3, 0 for everything else --
# GROUP 1 reimburses NOTHING. That is the binary, not a gap.
func _payout() -> void:
	_ok(Insurance.payout_pct(0) == 0, "uninsured pays back 0%")
	_ok(Insurance.payout_pct(1) == 0, "group 1 pays back 0%")
	_ok(Insurance.payout_pct(2) == 50, "group 2 pays back 50%")
	_ok(Insurance.payout_pct(3) == 100, "group 3 pays back 100%")


# FUN_00584e00: byte[injury+1] (TOTAL weeks) x 300000 internal = £1,500 a week.
func _injury_price() -> void:
	_ok(Insurance.injury_price(1) == 1500, "one week costs £1,500")
	# Wine witness 83: Branagan, pulled hamstring, 3 weeks -> PRICE £4,500.
	_ok(Insurance.injury_price(3) == 4500, "witness 83: 3 weeks -> £4,500")
	_ok(Insurance.injury_price(0) == 0, "no injury, no price")
	_ok(Insurance.injury_price(41) == 61_500, "a 41-week broken leg costs £61,500")
	# The total, not the weeks still to run.
	var p := {"injured_weeks": 1, "injury_weeks_total": 3}
	_ok(Insurance.injury_total_weeks(p) == 3, "price charges against the TOTAL duration")
	_ok(Insurance.injury_total_weeks({"injured_weeks": 2}) == 2, "legacy dict falls back to remaining")


# The row builder @0x543ca7: COST = PRICE - PRICE x pct / 100.
func _injury_cost() -> void:
	_ok(Insurance.injury_cost(3, 0) == 4500, "witness 83: uninsured COST == PRICE")
	_ok(Insurance.injury_cost(3, 1) == 4500, "group 1 still pays the full COST")
	_ok(Insurance.injury_cost(3, 2) == 2250, "group 2 halves the COST")
	_ok(Insurance.injury_cost(3, 3) == 0, "group 3 covers it entirely (cell drawn EMPTY)")


# @0x57f420: fild(price) / fidiv(weeks STILL to run) -- the original divides by the
# REMAINING weeks, so the weekly bill climbs as the man heals.
func _hospital() -> void:
	_ok(Insurance.hospital_weekly_internal(3, 3) == 300_000.0, "fresh injury bills £1,500/wk")
	_ok(Insurance.hospital_weekly_internal(3, 1) == 900_000.0, "last week bills the whole price")
	_ok(Insurance.hospital_weekly_internal(3, 0) == 0.0, "a healed man bills nothing")


# FUN_0058bfd0: group 3 only, premium(3, 0) / 3 = 200000/3 internal = £333.33.
func _group3_bonus() -> void:
	_ok(Insurance.group3_bonus_internal(3) == 200_000 / 3, "group 3 books premium(3,0)/3")
	for g in [0, 1, 2]:
		_ok(Insurance.group3_bonus_internal(g) == 0, "group %d books no bonus" % g)


# The weekly loop @0x57f3a6 over a squad, in internal units.
func _weekly_pass() -> void:
	var wage := func(_p): return 1000            # £1,000/wk
	var yearly := func(_p): return 52_000        # £52,000/yr -> £4,333/month
	var squad := [
		{"insurance_group": 0, "injured_weeks": 0},                                  # fit, uninsured
		{"insurance_group": 1, "injured_weeks": 0},                                  # fit, insured
		{"insurance_group": 0, "injured_weeks": 2, "injury_weeks_total": 2},         # hurt, uninsured
		{"insurance_group": 2, "injured_weeks": 2, "injury_weeks_total": 2},         # hurt, group 2
		{"insurance_group": 3, "injured_weeks": 2, "injury_weeks_total": 2},         # hurt, group 3
	]
	var r := Insurance.weekly_pass(squad, wage, yearly)
	var monthly_int := Insurance.monthly_internal(52_000)
	var expect_prem := (Insurance.premium_weekly_internal(1, monthly_int)
		+ Insurance.premium_weekly_internal(2, monthly_int)
		+ Insurance.premium_weekly_internal(3, monthly_int))
	_ok(int(r["premiums"]) == expect_prem, "premiums charged for the three insured men only")
	# Three injured men, each 2 weeks total with 2 to run -> £1,500 a week apiece.
	_ok(is_equal_approx(float(r["hospitals"]), 3.0 * 300_000.0), "hospital bill for all three injuries")
	_ok(is_equal_approx(float(r["payout2"]), 150_000.0), "group 2 reimburses half of one bill")
	_ok(is_equal_approx(float(r["payout3"]), 300_000.0), "group 3 reimburses one bill in full")
	_ok(int(r["wage_back"]) == 2 * 1000 * Insurance.UNIT,
		"the two INSURED injured men have their wages refunded")
	_ok(is_equal_approx(float(r["group3"]), float(200_000 / 3 + 1000 * Insurance.UNIT)),
		"GROUP 3 income = the refunded wage + £333.33")
	# A squad with nobody insured and nobody hurt moves no money at all.
	var quiet := Insurance.weekly_pass([{"injured_weeks": 0}], wage, yearly)
	_ok(int(quiet["premiums"]) == 0 and float(quiet["hospitals"]) == 0.0,
		"a fit uninsured squad costs nothing")


# End-to-end: a real Career week must move the money the ledger says it does.
func _career_week() -> void:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		_ok(false, "game_db.json missing")
		return
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
	var squad := career.my_squad()
	# One man on a GROUP 3 policy, three weeks out; nobody else insured or hurt.
	for p in squad:
		p["injured_weeks"] = 0
		p.erase("insurance_group")
	var hurt: Dictionary = squad[0]
	hurt["insurance_group"] = 3
	hurt["injured_weeks"] = 3
	hurt["injury_weeks_total"] = 3
	hurt["injury_type"] = 4

	var band := career.my_band()
	var weekly := Contract.current_weekly(hurt, band)
	var monthly_int := Insurance.monthly_internal(Contract.current_yearly(hurt, band))
	var cash0 := career.cash
	career._tick_insurance()

	@warning_ignore("integer_division")
	var prem_gbp := Insurance.premium_weekly_internal(3, monthly_int) / Insurance.UNIT
	_ok(career.ins_premiums == prem_gbp, "the GROUP 3 premium is charged for the week")
	# Group 3 reimburses the hospital bill in full -> the HOSPITALS line nets to £0.
	_ok(career.ins_hospitals == 0, "a GROUP 3 injury leaves HOSPITALS at zero")
	_ok(career.ins_wage_refund == weekly, "his wage is refunded off PLAYERS' WAGE")
	_ok(career.ins_group3_income == weekly + (200_000 / 3) / Insurance.UNIT,
		"INSURANCE GROUP 3 income = the wage + £333")
	_ok(career.cash - cash0 == career.ins_wage_refund + career.ins_group3_income
		- career.ins_premiums - career.ins_hospitals, "cash follows the ledger exactly")
	# An uninsured, fit squad must not move a penny.
	for p in squad:
		p["injured_weeks"] = 0
		p.erase("insurance_group")
	var cash1 := career.cash
	career._tick_insurance()
	_ok(career.cash == cash1, "a fit uninsured squad costs the club nothing")
	# The ledger is season-to-date and survives a save round-trip.
	var back := Career.from_dict(career.to_dict())
	_ok(back.insurance_ledger() == career.insurance_ledger(), "ledger survives save/load")
