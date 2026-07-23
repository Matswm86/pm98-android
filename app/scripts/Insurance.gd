class_name Insurance
extends RefCounted
## PM98 player-insurance economy — BINARY-EXACT, lifted from
## `extracted/Premier Manager 98/MANAGER.EXE`. Closes the INJURIES screen's
## PRICE / INSUR. / COST columns and the FINANCES screen's PLAYERS' INSURANCE /
## HOSPITALS / INSURANCE GROUP 3 lines (docs/re/insurance_economy_re.md).
##
## Money is in the engine's own integer unit: 200 internal = £1
## (transfer_value_re.md §10). Every constant below is the binary's own, in
## internal units, so the integer truncation happens exactly where the original's
## does; the `*_pounds` helpers divide by UNIT at the end.
##
##   FUN_0058c020(group, monthlyWage)  the PREMIUM  — monthly/{150,120,70},
##       clamped up to {40,000 / 100,000 / 200,000} = £200/£500/£1,000, then
##       floored to a multiple of 1,000 (= £5). Group 0 (uninsured) = 0.
##   FUN_0058c000(group)               the PAYOUT % — 50 (group 2), 100 (group 3),
##       0 otherwise. GROUP 1 pays NOTHING back; that is the binary, not a gap.
##   FUN_00584e00(injury)              the injury PRICE — byte[+1] (TOTAL weeks)
##       x 300,000 = £1,500 per week of the diagnosis's rolled duration.
##   FUN_0058bfd0(group)               group 3 only: premium(3, 0)/3 = £333.33,
##       booked as INSURANCE GROUP 3 income on top of the injured man's wage.
##
## The weekly finance loop @0x57f3a6 charges `premium * 12 / 52` per insured
## player and, per injured player, `price / weeksLeft` to HOSPITALS less the
## group payout; an insured injured player's wage is refunded to the club
## (setter 0x580f40, ledger PLAYERS' WAGE = +0x50 - +0x54). All eight ledger
## setters end in FUN_00580cd0, which moves the club balance by the same signed
## amount — so cash follows the ledger exactly.
##
## GameDB-free pure functions -> headless-testable (tests/test_insurance.gd).

const UNIT := 200                  # internal money units per £
const WEEKS_PER_YEAR := 52
const MONTHS_PER_YEAR := 12

# FUN_0058c020 — divisor and minimum premium per policy group (internal units).
const PREMIUM_DIV := {1: 150, 2: 120, 3: 70}
const PREMIUM_MIN := {1: 40000, 2: 100000, 3: 200000}   # £200 / £500 / £1,000
const PREMIUM_ROUND := 1000        # premiums are floored to a multiple of £5

# FUN_0058c000 — the share of the injury price the policy pays back.
const PAYOUT_PCT := {1: 0, 2: 50, 3: 100}

# FUN_00584e00 — the injury's PRICE per week of its TOTAL rolled duration.
const INJURY_WEEK_PRICE := 300000  # = £1,500


# ---- premium (FUN_0058c020) ----------------------------------------------

## The monthly premium in internal units for `group` at `monthly_internal` wage.
static func premium_internal(group: int, monthly_internal: int) -> int:
	if not PREMIUM_DIV.has(group):
		return 0
	var q: int = maxi(0, monthly_internal) / int(PREMIUM_DIV[group])
	var lo: int = int(PREMIUM_MIN[group])
	if q < lo:
		q = lo
	return q - (q % PREMIUM_ROUND)


## The monthly premium in £ for a player on `monthly_wage` £/month.
static func premium_monthly(group: int, monthly_wage: int) -> int:
	return premium_internal(group, monthly_wage * UNIT) / UNIT


## What the finance loop actually charges each week: premium x 12 / 52 (integer,
## in internal units — the £ figure is fractional, so callers sum the squad in
## internal units and convert once).
static func premium_weekly_internal(group: int, monthly_internal: int) -> int:
	return premium_internal(group, monthly_internal) * MONTHS_PER_YEAR / WEEKS_PER_YEAR


## A player's monthly wage in internal units, from his exact yearly wage (the
## INSURANCE screen's own MONTHLY WAGE column: yearly / 12, truncated).
static func monthly_internal(yearly_wage: int) -> int:
	return yearly_wage * UNIT / MONTHS_PER_YEAR


# ---- payout (FUN_0058c000) -----------------------------------------------

static func payout_pct(group: int) -> int:
	return int(PAYOUT_PCT.get(group, 0))


# ---- injury price / cost (FUN_00584e00 + the INJURIES row @0x543960) -----

## PRICE cell: the injury's TOTAL rolled duration x £1,500, in internal units.
static func injury_price_internal(total_weeks: int) -> int:
	return maxi(0, total_weeks) * INJURY_WEEK_PRICE


static func injury_price(total_weeks: int) -> int:
	return injury_price_internal(total_weeks) / UNIT


## COST cell: PRICE - PRICE x payout% / 100 (the row builder @0x543ca7). Group 3
## covers it entirely, and a zero COST is drawn as an EMPTY cell (@0x543cd2).
static func injury_cost_internal(total_weeks: int, group: int) -> int:
	var p := injury_price_internal(total_weeks)
	return p - p * payout_pct(group) / 100


static func injury_cost(total_weeks: int, group: int) -> int:
	return injury_cost_internal(total_weeks, group) / UNIT


## The HOSPITALS charge for one week of an active injury: the whole price spread
## over the weeks STILL to run (`fild price / fidiv weeksLeft` @0x57f420). The
## original divides by the REMAINING weeks, not the total, so the weekly charge
## climbs as the man heals — that is the game's arithmetic, reproduced verbatim.
static func hospital_weekly_internal(total_weeks: int, weeks_left: int) -> float:
	if weeks_left <= 0:
		return 0.0
	return float(injury_price_internal(total_weeks)) / float(weeks_left)


## FUN_0058bfd0: a GROUP 3 policy books premium(3, 0) / 3 = £333.33 a week on top
## of the injured player's refunded wage. Zero for every other group.
static func group3_bonus_internal(group: int) -> int:
	if group != 3:
		return 0
	return premium_internal(3, 0) / 3


# ---- the weekly finance pass (@0x57f382 loop) ----------------------------

## One week of the insurance economy over a squad, in INTERNAL units, keyed by the
## ledger line each figure lands on:
##   premiums   -> PLAYERS' INSURANCE   (record +0x60, expense)
##   hospitals  -> the +0x64 gross before the payouts are netted off
##   payout2/3  -> the group 2 / 3 reimbursements (+0x68 / +0x6c)
##   wage_back  -> insured-and-injured wages refunded (+0x54, cut from PLAYERS' WAGE)
##   group3     -> INSURANCE GROUP 3 income (+0x70)
## `wage_of` is called with each player dict and must return his WEEKLY wage in £;
## `yearly_of` his exact YEARLY wage in £.
static func weekly_pass(squad: Array, wage_of: Callable, yearly_of: Callable) -> Dictionary:
	var out := {"premiums": 0, "hospitals": 0.0, "payout2": 0.0, "payout3": 0.0,
		"wage_back": 0, "group3": 0.0}
	for p in squad:
		var pd: Dictionary = p
		var group := int(pd.get("insurance_group", 0))
		var weekly_int := int(wage_of.call(pd)) * UNIT
		if group > 0:
			out["premiums"] = int(out["premiums"]) + premium_weekly_internal(
				group, monthly_internal(int(yearly_of.call(pd))))
		var left := int(pd.get("injured_weeks", 0))
		if left <= 0:
			continue
		var total := injury_total_weeks(pd)
		var wk := hospital_weekly_internal(total, left)
		out["hospitals"] = float(out["hospitals"]) + wk
		if group <= 0:
			continue
		out["wage_back"] = int(out["wage_back"]) + weekly_int
		var pct := payout_pct(group)
		if group == 2:
			out["payout2"] = float(out["payout2"]) + float(pct) * wk * 0.01
		elif group == 3:
			out["payout3"] = float(out["payout3"]) + float(pct) * wk * 0.01
			out["group3"] = float(out["group3"]) + float(group3_bonus_internal(group) + weekly_int)
	return out


## The injury's TOTAL rolled duration (player+0x69). Legacy dicts written before
## the total was stored fall back to the weeks still to run, which is what the
## total was on the week the injury landed.
static func injury_total_weeks(p: Dictionary) -> int:
	var t := int(p.get("injury_weeks_total", 0))
	return t if t > 0 else int(p.get("injured_weeks", 0))
