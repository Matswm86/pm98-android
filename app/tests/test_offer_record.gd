extends SceneTree
## Locks the BINARY-EXACT offer/contract record model (docs/re/offer_record_re.md):
## the ◄/► money-step ladder, the YEARS 1..5 stepper + its matches-clause rule, the
## age-banded contract-term roll and the AV-banded clause seeds. Every expected value
## below is a MANAGER.EXE constant, not a tuned number.
##   ~/godot462 --headless --path app --script res://tests/test_offer_record.gd

var _fails := 0


func _initialize() -> void:
	_money_ladder()
	_years_stepper()
	_term_roll()
	_clause_seeds()
	_av()
	_price_modifier()
	if _fails == 0:
		print("OFFER RECORD: ALL GREEN")
	else:
		print("OFFER RECORD: %d FAILURES" % _fails)
	quit(1 if _fails > 0 else 0)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   %s" % msg)
	else:
		_fails += 1
		print("  FAIL %s" % msg)


# 0x529a20/0x529ac0: internal 1e6/2e6/5e6 over thresholds 1e7/5e7, /200 -> £.
func _money_ladder() -> void:
	_ok(OfferRecord.step_of(0) == 5000, "step under £50,000 = £5,000")
	_ok(OfferRecord.step_of(49_999) == 5000, "step just under the first threshold")
	_ok(OfferRecord.step_of(50_000) == 10_000, "step at £50,000 = £10,000")
	_ok(OfferRecord.step_of(249_999) == 10_000, "step just under the second threshold")
	_ok(OfferRecord.step_of(250_000) == 25_000, "step at £250,000 = £25,000")
	_ok(OfferRecord.step_of(50_000_000) == 25_000, "step stays £25,000 at the top")
	# UP from the floor walks the exact ladder
	var v := 5000
	var seen: Array = []
	for _i in 12:
		v = OfferRecord.step_up(v)
		seen.append(v)
	_ok(seen.slice(0, 4) == [10_000, 15_000, 20_000, 25_000], "£5,000 rungs from the floor")
	# DOWN never crosses the floor and is inert at or below it
	_ok(OfferRecord.step_down(10_000) == 5000, "down lands on the floor")
	_ok(OfferRecord.step_down(5000) == 5000, "down is inert at the floor")
	_ok(OfferRecord.step_down(1000) == 1000, "down is inert below the floor")
	# a ceiling only clamps, it never pushes a value up
	_ok(OfferRecord.step_up(20_000, 22_000) == 22_000, "ceiling clamps the step")
	_ok(OfferRecord.step_up(20_000, 0) == 25_000, "no ceiling = unbounded")
	# up/down are exact inverses inside a band (the binary compares the SAME value)
	_ok(OfferRecord.step_down(OfferRecord.step_up(100_000)) == 100_000,
		"up then down returns inside a band")


# 0x529e40 / 0x529f90
func _years_stepper() -> void:
	_ok(OfferRecord.years_up(1) == 2 and OfferRecord.years_up(4) == 5, "years step up")
	_ok(OfferRecord.years_up(5) == 5, "years cap at 5")
	_ok(OfferRecord.years_down(5) == 4 and OfferRecord.years_down(2) == 1, "years step down")
	_ok(OfferRecord.years_down(1) == 1, "years floor at 1")
	_ok(OfferRecord.matches_clause_allowed(1), "matches clause allowed on a 1-year deal")
	_ok(not OfferRecord.matches_clause_allowed(2), "matches clause cleared above 1 year")


# FUN_00576cd0 @0x576d09 / 0x576e5c — bands and reachable terms per age.
func _term_roll() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260723
	var bands := {22: [3, 4], 25: [1, 2, 3, 4], 30: [1, 2, 3], 34: [1, 2]}
	for age in bands:
		var seen := {}
		for _i in 4000:
			var y := OfferRecord.seed_years(int(age), rng)
			seen[y] = true
		var got: Array = seen.keys()
		got.sort()
		_ok(got == (bands[age] as Array), "age %d terms %s (expected %s)" % [age, got, bands[age]])
	# The 50/50 split at the oldest band is the r<50 coin, not a drifted distribution.
	var twos := 0
	for _i in 20_000:
		if OfferRecord.seed_years(34, rng) == 2:
			twos += 1
	_ok(abs(twos - 10_000) < 600, "age 34: 2-year deals ~50%% (%d/20000)" % twos)


# FUN_00576cd0 @0x576d16..0x576d71
func _clause_seeds() -> void:
	var cf := OfferRecord.POSFINE_CENTRE_FORWARD
	var elite := OfferRecord.seed_clauses(88, cf, 3)
	_ok(elite["free_if_relegated"] and elite["house_and_car"] and int(elite["bonus"]) == 10_000,
		"AV>=85 striker: both flags + £10,000 bonus")
	var good := OfferRecord.seed_clauses(82, cf, 3)
	_ok(good["free_if_relegated"] and not good["house_and_car"] and int(good["bonus"]) == 5000,
		"AV 80..84 striker: one flag + £5,000 bonus")
	_ok(int(OfferRecord.seed_clauses(88, 4, 3)["bonus"]) == 0,
		"a defender never carries the goal bonus")
	var mid := OfferRecord.seed_clauses(77, 10, 1)
	_ok(mid["free_if_relegated"] and int(mid["matches"]) == 20,
		"AV 75..79: flag + 20-match target")
	_ok(int(OfferRecord.seed_clauses(72, 10, 1)["matches"]) == 20, "AV 70..74: target only")
	_ok(int(OfferRecord.seed_clauses(72, 10, 2)["matches"]) == 0,
		"a multi-year term clears the match target (the years-handler rule)")
	var low := OfferRecord.seed_clauses(60, 10, 1)
	_ok(not low["free_if_relegated"] and int(low["matches"]) == 0, "AV < 70: no clauses")
	_clause_checkbox_map()


# The clause -> CONTRACT-panel checkbox map, WITNESSED on the five live cards in
# screenshots/wine-captures-2026-07-24-clause-labels/ (offer_record_re.md §5.1).
# Each assertion below reproduces one of those cards.
func _clause_checkbox_map() -> void:
	var cf := OfferRecord.POSFINE_CENTRE_FORWARD
	var mid := 10
	# Southgate, AV 81, 2y: "Free if relegated" only.
	_ok(str(OfferRecord.seed_clauses(81, 4, 2)["indices"]) == str([0]),
		"Southgate 81 2y -> Free if relegated only")
	# Cole, AV 83 CENTRE FORWARD, 1y: free-if-relegated + the £5,000 scoring bonus.
	var cole: Array = OfferRecord.seed_clauses(83, cf, 1)["indices"]
	_ok(str(cole) == str([0, 2]), "Cole 83 CF 1y -> Free if relegated + Scoring bonus")
	# Keane, AV 89 MIDFIELDER, 2y: free-if-relegated + house-and-car, no bonus.
	_ok(str(OfferRecord.seed_clauses(89, mid, 2)["indices"]) == str([0, 3]),
		"Keane 89 MID 2y -> Free if relegated + House and car")
	# Sheringham, AV 75 CF, 1y: free-if-relegated + the 20-match renew target.
	_ok(str(OfferRecord.seed_clauses(75, cf, 1)["indices"]) == str([0, 1]),
		"Sheringham 75 CF 1y -> Free if relegated + Matches to renew")
	# Nevland, 3-year deal, sub-70 band: nothing ticked (the negative control).
	_ok(str(OfferRecord.seed_clauses(65, mid, 3)["indices"]) == str([]),
		"Nevland 3y low AV -> no clauses (negative control)")
	# the labels the panel prints, in checkbox-row order
	_ok(str(OfferRecord.CLAUSE_LABELS) == str(["Free if relegated", "Matches to renew",
		"Scoring bonus", "House and car"]), "clause labels in card row order")


# FUN_00534570: the on-screen AV is core4 >> 2, not CA and not the 6-attr rating.
func _av() -> void:
	var p := {"attrs": {"VE": 87, "RE": 83, "AG": 81, "CA": 84}}
	_ok(OfferRecord.av_of(p) == 83, "AV = (87+83+81+84)>>2 = 83")
	_ok(OfferRecord.av_of({}) == 0, "no attrs -> 0, never a fabricated value")


# FUN_005889c0 / 0x584960 / 0x5849a0 -- the price modifier and the accept test.
func _price_modifier() -> void:
	_ok(OfferRecord.price_modifier({}) == 1000, "a player with no stored modifier asks full price")
	_ok(OfferRecord.price_modifier({"price_modifier": 90}) == 500, "the adder clamps low at 500")
	_ok(OfferRecord.price_modifier({"price_modifier": 9999}) == 1250, "the adder clamps high at 1250")
	_ok(OfferRecord.price_modifier_add(1000, -600) == 500, "add clamps to the 500 floor")
	_ok(OfferRecord.price_modifier_add(1000, 600) == 1250, "add clamps to the 1250 ceiling")
	# The ladder: threshold 60 under arg2 4, 47 under 7, else 36; then -13/-24/-39/-50.
	_ok(OfferRecord.price_modifier_of(60, 0) == 1000, "a striker at the threshold asks full price")
	_ok(OfferRecord.price_modifier_of(59, 0) == 900, "one under the threshold: 900")
	_ok(OfferRecord.price_modifier_of(47, 0) == 900, "60-13 = 47 is still 900")
	_ok(OfferRecord.price_modifier_of(46, 0) == 800, "60-24 = 36 band: 800")
	_ok(OfferRecord.price_modifier_of(21, 0) == 700, "60-39 = 21: 700")
	_ok(OfferRecord.price_modifier_of(10, 0) == 600, "60-50 = 10: 600")
	_ok(OfferRecord.price_modifier_of(9, 0) == 500, "under the last rung: 500")
	_ok(OfferRecord.price_modifier_of(47, 5) == 1000, "arg2 in [4,7) lowers the threshold to 47")
	_ok(OfferRecord.price_modifier_of(36, 9) == 1000, "arg2 >= 7 lowers the threshold to 36")
	# The ask itself: the modifier only ever discounts.
	_ok(OfferRecord.asking_fee(1_000_000, 1000, false) == 1_000_000, "1000 permille = book value")
	_ok(OfferRecord.asking_fee(1_000_000, 1250, false) == 1_000_000,
		"above 1000 permille the engine still asks only book value")
	_ok(OfferRecord.asking_fee(1_000_000, 800, false) == 800_000, "800 permille = 80% of book")
	_ok(OfferRecord.asking_fee(1_000_000, 1000, true) == 800_000,
		"the transfer-list flag knocks 200 permille off")
	_ok(OfferRecord.asking_fee(1_000_000, 900, true) == 700_000, "flag stacks with the modifier")
	_ok(OfferRecord.offer_accepted(800_000, 1_000_000, 1000, true), "a bid at the modified ask is taken")
	_ok(not OfferRecord.offer_accepted(799_999, 1_000_000, 1000, true), "a bid a pound short is not")
