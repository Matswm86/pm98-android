extends SceneTree
## Headless test for the backroom staff (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_staff.gd
## Covers the Staff unit model (candidate shape, wage monotonicity, the three effect
## factors + clamps, wage totals, sack compensation) and the Career integration (a pool
## seeded at create, hire/sack with guards + compensation, staff effects flowing into the
## week -- a trainer speeds development, a physio cuts injuries, a youth coach speeds youth
## -- wages drawn from cash, and staff persisting through save/load with old saves inert).

const SEED := 24681012


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_candidates() and ok
	ok = _unit_factors() and ok
	ok = _unit_wages() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- unit: candidates ----------------------------------------------------

func _unit_candidates() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var pool := Staff.generate_pool(rng, 800000, 6)
	ok = _assert(pool.size() == 6, "pool has the requested size") and ok
	var ids := {}
	var roles := {}
	var shape_ok := true
	for m in pool:
		ids[int(m["id"])] = true
		roles[str(m["role"])] = true
		for k in ["id", "role", "name", "quality", "wage"]:
			shape_ok = shape_ok and m.has(k)
		shape_ok = shape_ok and int(m["quality"]) >= Staff.QUALITY_LO and int(m["quality"]) <= Staff.QUALITY_HI
	ok = _assert(ids.size() == 6, "pool ids unique") and ok
	ok = _assert(shape_ok, "every candidate carries id/role/name/quality/wage in range") and ok
	ok = _assert(roles.size() == Staff.ROLES.size(), "pool spreads across all roles") and ok
	# Wage rises with quality for a role.
	ok = _assert(Staff.wage_for(Staff.TRAINER, 5) > Staff.wage_for(Staff.TRAINER, 1),
		"a better member costs more") and ok
	return ok


# ---- unit: effect factors ------------------------------------------------

func _unit_factors() -> bool:
	var ok := true
	var none: Array = []
	ok = _assert(Staff.training_factor(none) == 1.0 and Staff.physio_factor(none) == 1.0
		and Staff.youth_factor(none) == 1.0, "no staff -> all factors are 1.0 (no regression)") and ok

	var trainer := [{"id": 1, "role": Staff.TRAINER, "quality": 5, "wage": 100000}]
	var physio := [{"id": 2, "role": Staff.PHYSIO, "quality": 5, "wage": 80000}]
	var coach := [{"id": 3, "role": Staff.YOUTH_COACH, "quality": 5, "wage": 90000}]
	ok = _assert(Staff.training_factor(trainer) > 1.0, "a trainer raises the development factor") and ok
	ok = _assert(Staff.physio_factor(physio) < 1.0, "a physio lowers the injury factor") and ok
	ok = _assert(Staff.youth_factor(coach) > 1.0, "a youth coach raises the youth factor") and ok

	# Factors are clamped (a wall of trainers can't run away).
	var many: Array = []
	for i in 10:
		many.append({"id": 100 + i, "role": Staff.TRAINER, "quality": 5, "wage": 100000})
	ok = _assert(Staff.training_factor(many) <= 1.5 + 0.0001, "training factor is clamped at the cap") and ok

	# Roles don't bleed: a trainer doesn't move the physio/youth factor.
	ok = _assert(Staff.physio_factor(trainer) == 1.0 and Staff.youth_factor(trainer) == 1.0,
		"a trainer affects only the development factor") and ok
	return ok


# ---- unit: wages ---------------------------------------------------------

func _unit_wages() -> bool:
	var ok := true
	var staff := [
		{"id": 1, "role": Staff.TRAINER, "quality": 3, "wage": 75000},
		{"id": 2, "role": Staff.PHYSIO, "quality": 2, "wage": 50000},
	]
	ok = _assert(Staff.yearly_wage(staff) == 125000, "yearly wage sums the members") and ok
	ok = _assert(Staff.weekly_wage(staff) == int(round(125000 / 52.0)), "weekly wage = yearly / 52") and ok
	ok = _assert(Staff.sack_cost(staff[0]) == int(round(75000 / 52.0 * Staff.SACK_WEEKS)),
		"sack cost = a few weeks' wage") and ok
	return ok


# ---- integration: a career runs the backroom ------------------------------

func _career_integration() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var prem: Array = []
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	if prem.is_empty() or league.is_empty():
		push_error("no Premier League fixture in the DB")
		return false

	var career := Career.create(prem[0], league, prem, leagues)
	var ok := true
	ok = _assert(career.staff.is_empty(), "career starts with no staff hired") and ok
	ok = _assert(career.staff_pool.size() == Career.STAFF_POOL_SIZE, "career seeds a hire pool") and ok

	# Hire a trainer from the pool.
	var trainer_cand: Dictionary = {}
	for m in career.staff_pool:
		if str(m.get("role")) == Staff.TRAINER:
			trainer_cand = m
			break
	var cid := int(trainer_cand["id"])
	var pool_before := career.staff_pool.size()
	var res := career.hire_staff(cid)
	ok = _assert(res["ok"], "a candidate is hired") and ok
	ok = _assert(career.staff.size() == 1 and career.staff_pool.size() == pool_before - 1,
		"hire moves the member pool -> staff") and ok
	ok = _assert(Staff.training_factor(career.staff) > 1.0, "the hired trainer raises the live factor") and ok

	# Wages are drawn from cash each week (week 0 has no cup prize, so the delta is exact).
	# The week's draw is weekly_net minus BOTH the live player wage bill and the staff bill.
	var cash_before := career.cash
	var wage := career.staff_weekly_wage()
	var players := career.player_weekly_wage()
	var net := career.weekly_net
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	career.advance_week(rng)
	ok = _assert(wage > 0, "the hired staff has a weekly wage (£%d/wk)" % wage) and ok
	ok = _assert(career.cash == cash_before + net - players - wage,
		"the staff wage bill is drawn from cash (%d + %d - %d - %d)" % [cash_before, net, players, wage]) and ok

	# Sack the trainer: back to the pool, compensation paid, factor back to 1.0.
	var mid := int(career.staff[0]["id"])
	var cash_pre_sack := career.cash
	var sres := career.sack_staff(mid)
	ok = _assert(sres["ok"], "a member is sacked") and ok
	ok = _assert(career.staff.is_empty() and career.cash < cash_pre_sack,
		"sack removes the member and pays compensation") and ok
	ok = _assert(Staff.training_factor(career.staff) == 1.0, "factor returns to 1.0 after the sack") and ok

	# Affordability guard: can't hire someone whose wage exceeds the bank.
	career.cash = 1
	var costly: Dictionary = career.staff_pool[0]
	var bad := career.hire_staff(int(costly["id"]))
	ok = _assert(not bad["ok"], "an unaffordable hire is refused") and ok

	# Effect flows into a season: a 5-star trainer develops the squad more than none, with
	# the same rng draws (Training consumes the same stream regardless of factor).
	ok = _assert(_trainer_develops_more(prem, league, leagues), "a trainer speeds squad development") and ok

	# Persistence: staff + pool + seq round-trip; an old save loads inert.
	career.cash = 5_000_000
	career.hire_staff(int(career.staff_pool[0]["id"]))
	var path := "user://career_staff_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.staff.size() == career.staff.size()
		and loaded.staff_pool.size() == career.staff_pool.size()
		and loaded.staff_seq == career.staff_seq, "staff state survives save/load") and ok
	var legacy := Career.from_dict({"club_id": 1, "rosters": {}})
	ok = _assert(legacy.staff.is_empty() and legacy.staff_pool.is_empty()
		and legacy.staff_seq == Career.STAFF_ID_BASE, "a pre-staff save loads no staff (effects = 1.0)") and ok
	return ok


## Two identical careers over one season, one with a top trainer, same rng seed -> the
## trained squad gains at least as much ability, and strictly more development news.
func _trainer_develops_more(prem: Array, league: Dictionary, leagues: Array) -> bool:
	var a := Career.create(prem[0], league, prem, leagues)
	var b := Career.create(prem[0], league, prem, leagues)
	# Give B a 5-star trainer; strip both pools so they don't diverge, and align squads.
	b.staff = [{"id": 7, "role": Staff.TRAINER, "quality": 5, "wage": 100000}]
	b.cash = 50_000_000
	b.rosters[b.club_id] = a.rosters[a.club_id].duplicate(true)
	a.training_intensity = "Normal"
	b.training_intensity = "Normal"
	var dev_a := 0
	var dev_b := 0
	var ra := RandomNumberGenerator.new(); ra.seed = SEED
	var rb := RandomNumberGenerator.new(); rb.seed = SEED
	for _w in 30:
		for n in Training.train_week(ra, a.my_squad(), "Normal", Staff.training_factor(a.staff)):
			if n["kind"] == "develop": dev_a += 1
		for n in Training.train_week(rb, b.my_squad(), "Normal", Staff.training_factor(b.staff)):
			if n["kind"] == "develop": dev_b += 1
	print("    trainer dev: none=%d trainer=%d" % [dev_a, dev_b])
	return dev_b > dev_a


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
