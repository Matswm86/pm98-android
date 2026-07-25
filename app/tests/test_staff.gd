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
	ok = _unit_witnessed_pools() and ok
	ok = _unit_factors() and ok
	ok = _unit_wages() and ok
	ok = _career_integration() and ok
	ok = _single_occupancy() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- unit: candidates ----------------------------------------------------

func _unit_candidates() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var per_role := 3
	var pool := Staff.generate_pool(rng, 800000, per_role)
	var want := Staff.ROLE_KEYS.size() * per_role   # 13 roles x per_role
	ok = _assert(pool.size() == want, "pool = per_role x 13 roles (%d)" % want) and ok
	var ids := {}
	var roles := {}
	var shape_ok := true
	for m in pool:
		ids[int(m["id"])] = true
		roles[str(m["role"])] = true
		for k in ["id", "role", "name", "stars", "quality", "wage"]:
			shape_ok = shape_ok and m.has(k)
		shape_ok = shape_ok and int(m["quality"]) >= Staff.QUALITY_LO and int(m["quality"]) <= Staff.QUALITY_HI
		shape_ok = shape_ok and float(m["stars"]) >= Staff.STARS_LO and float(m["stars"]) <= Staff.STARS_HI
	ok = _assert(ids.size() == want, "pool ids unique") and ok
	ok = _assert(shape_ok, "every candidate carries id/role/name/stars/quality/wage in range") and ok
	ok = _assert(roles.size() == Staff.ROLE_KEYS.size(), "pool spreads across all 13 roles") and ok
	# Wage rises with the rating for a role.
	ok = _assert(Staff.wage_for(Staff.HANDLING, 5.0) > Staff.wage_for(Staff.HANDLING, 1.0),
		"a better member costs more") and ok
	# Half-star wages sit between the whole-star ones.
	ok = _assert(Staff.wage_for(Staff.HANDLING, 4.0) < Staff.wage_for(Staff.HANDLING, 4.5)
		and Staff.wage_for(Staff.HANDLING, 4.5) < Staff.wage_for(Staff.HANDLING, 5.0),
		"a half-star rating prices between the whole stars") and ok
	return ok


# ---- unit: the witnessed pools (docs/re/staff_re.md "The real candidate pools") ----

## KILL-TEST vs the 2026-07-18 witness pass: candidate names come from the game's own
## DBDAT tables, wage_for reproduces every single-valued witnessed (stars -> wage) anchor
## exactly, banded anchors bound the rng draw, and the pool keeps generation order.
func _unit_witnessed_pools() -> bool:
	var ok := true
	var pools := Staff.name_pools()
	var fores: Array = pools["forenames"]
	var surs: Array = pools["surnames"]
	ok = _assert(fores.size() == 148 and surs.size() == 327,
		"name_pools.json = the real NOMBRES.30 (148) + APELLIDO.30 (327)") and ok
	# The witnessed hire-list surnames are table rows (sample across both careers).
	var have := true
	for s in ["Padmore", "Gelbier", "Jumblat", "Debnam", "O'brian", "Savage", "Mcgrath",
			"Burrowes", "Dongle", "Watkinson"]:
		have = have and surs.has(s)
	ok = _assert(have, "witnessed candidate surnames are APELLIDO.30 rows") and ok
	# Generated candidate names are 'I. Surname' with a table surname.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var names_ok := true
	for _i in 30:
		var m := Staff.make_candidate(rng, 1, Staff.SCOUT_ROLE)
		var nm := str(m["name"])
		names_ok = names_ok and nm.substr(1, 2) == ". " and surs.has(nm.substr(3))
	ok = _assert(names_ok, "candidate names = forename initial + real table surname") and ok
	# Exact single-valued witnessed anchors (no rng -> the anchor itself).
	var exact := [
		[Staff.TACKLING, 3.5, 21000], [Staff.SHOOTING, 4.0, 27000],
		[Staff.PHYSIOTHERAPIST, 2.0, 9000], [Staff.PHYSIOTHERAPIST, 3.0, 16000],
		[Staff.PHYSIOTHERAPIST, 5.0, 45000], [Staff.PSYCHOLOGIST, 2.0, 6000],
		[Staff.PSYCHOLOGIST, 4.5, 15000], [Staff.ASSISTANT_MANAGER, 2.0, 7000],
		[Staff.ASSISTANT_MANAGER, 2.5, 9000], [Staff.ASSISTANT_MANAGER, 4.0, 16000],
		[Staff.SCOUT_ROLE, 1.0, 4000], [Staff.SCOUT_ROLE, 2.0, 8000],
		[Staff.SCOUT_ROLE, 3.0, 20000], [Staff.SCOUT_ROLE, 4.5, 45000],
		[Staff.YOUTH_TEAM_MANAGER, 2.5, 12000], [Staff.YOUTH_TEAM_MANAGER, 3.0, 20000],
		[Staff.YOUTH_TEAM_MANAGER, 3.5, 21000], [Staff.YOUTH_TEAM_SCOUT, 5.0, 36000],
		[Staff.GROUNDSMAN, 1.0, 1000], [Staff.GROUNDSMAN, 3.0, 2000],
		[Staff.GROUNDSMAN, 4.5, 4000],
	]
	var anchors_ok := true
	for e in exact:
		if Staff.wage_for(e[0], e[1]) != e[2]:
			anchors_ok = false
			print("    anchor MISS %s %.1f -> %d (want %d)" % [e[0], e[1], Staff.wage_for(e[0], e[1]), e[2]])
	ok = _assert(anchors_ok, "every single-valued witnessed anchor reproduces exactly") and ok
	# Banded anchors bound the per-candidate draw (trainer 5.0 witnessed £47k-£52k).
	var band_ok := true
	for _i in 40:
		var w := Staff.wage_for(Staff.DRIBBLING, 5.0, rng)
		band_ok = band_ok and w >= 47000 and w <= 52000 and w % 1000 == 0
	ok = _assert(band_ok, "trainer 5.0 draws inside the witnessed £47k-£52k band, round £1,000") and ok
	# Pool order = generation order (the witnessed lists are NOT rating-sorted).
	var pool := [
		{"id": 1, "role": Staff.HANDLING, "stars": 1.5, "wage": 5000},
		{"id": 2, "role": Staff.HANDLING, "stars": 3.0, "wage": 17000},
		{"id": 3, "role": Staff.HANDLING, "stars": 1.0, "wage": 4000},
	]
	var got := Staff.pool_for_role(pool, Staff.HANDLING)
	ok = _assert(int(got[0]["id"]) == 1 and int(got[1]["id"]) == 2 and int(got[2]["id"]) == 3,
		"pool_for_role keeps generation order (witnessed 1.5 / 3.0 / 1.0)") and ok
	return ok


# ---- unit: effect factors ------------------------------------------------

func _unit_factors() -> bool:
	var ok := true
	var none: Array = []
	ok = _assert(Staff.training_factor(none) == 1.0 and Staff.physio_factor(none) == 1.0
		and Staff.youth_factor(none) == 1.0, "no staff -> all factors are 1.0 (no regression)") and ok

	var trainer := [{"id": 1, "role": Staff.HANDLING, "stars": 5.0, "quality": 5, "wage": 100000}]
	var physio := [{"id": 2, "role": Staff.PHYSIOTHERAPIST, "stars": 5.0, "quality": 5, "wage": 80000}]
	var coach := [{"id": 3, "role": Staff.YOUTH_TEAM_MANAGER, "stars": 5.0, "quality": 5, "wage": 90000}]
	ok = _assert(Staff.training_factor(trainer) > 1.0, "a skill trainer raises the development factor") and ok
	ok = _assert(Staff.physio_factor(physio) < 1.0, "a physio lowers the injury factor") and ok
	ok = _assert(Staff.youth_factor(coach) > 1.0, "a youth team manager raises the youth factor") and ok

	# The full six-skill coaching bench at 5 stars hits (and is clamped at) the cap.
	var bench: Array = []
	var i := 0
	for skill in Staff.TRAINER_SKILLS:
		bench.append({"id": 200 + i, "role": skill, "stars": 5.0, "quality": 5, "wage": 100000})
		i += 1
	ok = _assert(abs(Staff.training_factor(bench) - 1.5) < 0.0001,
		"a full 5-star coaching bench reaches the development cap (1.5)") and ok
	# A single coach gives only a slice of that cap (single-occupancy, not summed per member).
	ok = _assert(Staff.training_factor(trainer) < Staff.training_factor(bench),
		"one coach develops less than the full bench") and ok

	# Roles don't bleed: a trainer doesn't move the physio/youth factor.
	ok = _assert(Staff.physio_factor(trainer) == 1.0 and Staff.youth_factor(trainer) == 1.0,
		"a trainer affects only the development factor") and ok
	# New roles with no engine hook are hireable but no-op (honest gap, never invented).
	var psych := [{"id": 9, "role": Staff.PSYCHOLOGIST, "stars": 5.0, "quality": 5, "wage": 15000}]
	ok = _assert(Staff.training_factor(psych) == 1.0 and Staff.physio_factor(psych) == 1.0
		and Staff.youth_factor(psych) == 1.0, "a psychologist has no engine effect (honest gap)") and ok
	return ok


# ---- unit: wages ---------------------------------------------------------

func _unit_wages() -> bool:
	var ok := true
	var staff := [
		{"id": 1, "role": Staff.HANDLING, "stars": 3.0, "quality": 3, "wage": 75000},
		{"id": 2, "role": Staff.PHYSIOTHERAPIST, "stars": 2.0, "quality": 2, "wage": 50000},
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
	ok = _assert(career.staff_pool.size() == Staff.ROLE_KEYS.size() * Career.STAFF_POOL_PER_ROLE,
		"career seeds a per-role hire pool") and ok

	# Hire a skill trainer from the pool.
	var trainer_cand: Dictionary = {}
	for m in career.staff_pool:
		if str(m.get("role")) == Staff.HANDLING:
			trainer_cand = m
			break
	var cid := int(trainer_cand["id"])
	var pool_before := career.staff_pool.size()
	var res := career.hire_staff(cid)
	ok = _assert(res["ok"], "a candidate is hired") and ok
	ok = _assert(career.staff.size() == 1 and career.staff_pool.size() == pool_before - 1,
		"hire moves the member pool -> staff") and ok
	ok = _assert(Staff.training_factor(career.staff) > 1.0, "the hired trainer raises the live factor") and ok

	# Wages are drawn from cash each week. STAFF WAGES is one of the two flat costs the
	# original charges EVERY week (REFRUN R9), and it is booked to its own ledger line.
	var cash_before := career.cash
	var wage := career.staff_weekly_wage()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	career.advance_week(rng)
	var rec: Dictionary = career.week_ledgers[-1]
	ok = _assert(wage > 0, "the hired staff has a weekly wage (£%d/wk)" % wage) and ok
	ok = _assert(int(rec["expense"]["STAFF WAGES"]) == wage,
		"STAFF WAGES booked every week (£%d)" % wage) and ok
	ok = _assert(career.cash == cash_before + FinanceModel.ledger_balance(rec),
		"the week's cash delta == the week's ledger balance") and ok

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
	# Give B the full 5-star coaching bench (all six skills); align squads + cash.
	b.staff = []
	var i := 0
	for skill in Staff.TRAINER_SKILLS:
		b.staff.append({"id": 700 + i, "role": skill, "stars": 5.0, "quality": 5, "wage": 100000})
		i += 1
	b.cash = 50_000_000
	b.rosters[b.club_id] = a.rosters[a.club_id].duplicate(true)
	a.training_intensity = "Normal"
	b.training_intensity = "Normal"
	# A coach's real effect is CAPACITY: TOTAL TRAINABLE PLAYERS = the sum of every
	# hired skill coach's TP (witnessed live), and the engine only develops a player
	# who is ON a coach. So the club with no trainers can focus nobody and develops
	# nobody; the club with six 5-star coaches develops everyone AUTO puts on them.
	a.auto_training_focus()
	b.auto_training_focus()
	var dev_a := 0
	var dev_b := 0
	var ra := RandomNumberGenerator.new(); ra.seed = SEED
	var rb := RandomNumberGenerator.new(); rb.seed = SEED
	for _w in 30:
		dev_a += Training.develop_week(ra, a.my_squad(), a.training_focus).size()
		dev_b += Training.develop_week(rb, b.my_squad(), b.training_focus).size()
	print("    trainable: none=%d trainer=%d ; dev items none=%d trainer=%d" % [
		Training.total_trainable(a.staff), Training.total_trainable(b.staff), dev_a, dev_b])
	return Training.total_trainable(a.staff) == 0 and dev_a == 0 and dev_b > 0


## Single occupancy (frames 108-121): each of the 13 roles holds exactly ONE member; signing
## into an occupied role REPLACES the holder, who returns to the pool (no compensation).
func _single_occupancy() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
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
	var career := Career.create(prem[0], league, prem, leagues)
	career.cash = 50_000_000
	var ok := true

	# Two candidates for the SAME role (PHYSIOTHERAPIST).
	var a := {}
	var b := {}
	for m in career.staff_pool:
		if str(m.get("role")) == Staff.PHYSIOTHERAPIST:
			if a.is_empty():
				a = m
			elif b.is_empty():
				b = m
				break
	ok = _assert(not a.is_empty() and not b.is_empty(), "two physio candidates in the pool") and ok
	career.hire_staff(int(a["id"]))
	ok = _assert(Staff.members_in_role(career.staff, Staff.PHYSIOTHERAPIST).size() == 1,
		"first physio hired -> one in the role") and ok
	var pool_n := career.staff_pool.size()
	career.hire_staff(int(b["id"]))                     # replace
	ok = _assert(Staff.members_in_role(career.staff, Staff.PHYSIOTHERAPIST).size() == 1,
		"signing a second physio REPLACES (still one in the role)") and ok
	ok = _assert(int(Staff.member_in_role(career.staff, Staff.PHYSIOTHERAPIST)["id"]) == int(b["id"]),
		"the new signing is the holder") and ok
	var back := false
	for m in career.staff_pool:
		if int(m.get("id", -1)) == int(a["id"]):
			back = true
	ok = _assert(back and career.staff_pool.size() == pool_n,
		"the replaced holder returns to the pool (net pool size unchanged)") and ok
	ok = _assert(career.staff_personnel().has("PHYSIOTHERAPIST"),
		"staff_personnel exposes the hired role for the screen") and ok
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
