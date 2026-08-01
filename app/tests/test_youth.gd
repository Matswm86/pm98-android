extends SceneTree
## Headless test for the YOUTH TEAM, against MANAGER.EXE rather than against our own
## old invented model.
##   ~/godot462 --headless --path app --script res://tests/test_youth.gd
##
## One assertion per binary clause in docs/re/youth_re.md:
##   FUN_005820f0 @0x582434  the club-0x26e4 load-time knock-down (rand(11)+0x23)
##   FUN_00575d90            the youth-scout predicate (any lit capability BASE > 0x4f)
##   FUN_00575e80            the search: filter the pool, keep exactly ONE at random
##   FUN_0053e860 @0x53e967  weeks = rand(6) + 0x37 - 5*((quality+1)>>1)
##   FUN_00582760 case 0x20  60% of +1 a week, hard-stopped at BASE, then "ready"
## plus the Career integration (sign from the pool, promote, persistence).

const SEED := 77881122
const POOL_CLUB := 1383

# The headless `--script` runner has no autoloads, so the test loads game_db.json and
# applies the loader pass itself — exactly what GameDB._apply_loader_defaults does.
var _db: Dictionary = {}
var _clubs_by_id: Dictionary = {}


func _initialize() -> void:
	quit(0 if _run() else 1)


func _load_db() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	_db = JSON.parse_string(f.get_as_text())
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for c in _db.get("clubs", []):
		_clubs_by_id[int(c["id"])] = c
		if int(c["id"]) == POOL_CLUB:
			for p in c.get("players", []):
				Youth.degrade(p, rng)
	return true


func _run() -> bool:
	if not _load_db():
		return false
	var ok := true
	ok = _unit_pool() and ok
	ok = _unit_degrade() and ok
	ok = _unit_predicate() and ok
	ok = _unit_search() and ok
	ok = _unit_weeks() and ok
	ok = _unit_develop() and ok
	ok = _unit_graduate() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- the shipped pool (EQ969956.DBC, engine club 0x26e4) -----------------

func _unit_pool() -> bool:
	var ok := true
	var pool := Youth.pool_of(_clubs_by_id)
	ok = _assert(Youth.POOL_CLUB_ID == POOL_CLUB, "the pool is club 1383 (0x26e4)") and ok
	ok = _assert(pool.size() == 51, "EQUIPOS ships 51 youth records (%d)" % pool.size()) and ok
	var shape_ok := true
	for p in pool:
		shape_ok = shape_ok and p.has("id") and p.has("name") and (p.get("attrs") is Dictionary)
	ok = _assert(shape_ok, "every pool record is a real player record") and ok
	# They are REAL people from the game's own database, not generated names.
	var named := false
	for p in pool:
		if str(p.get("legalName", "")) == "James FRESHER":
			named = true
	ok = _assert(named, "the pool is the shipped data (James FRESHER is in it)") and ok
	return ok


# ---- FUN_005820f0 @0x582434: the load-time knock-down --------------------

func _unit_degrade() -> bool:
	var ok := true
	var pool := Youth.pool_of(_clubs_by_id)
	var all_based := true
	var all_banded := true
	var all_consistent := true
	for p in pool:
		if not p.has("attrs_base"):
			all_based = false
			continue
		var base: Dictionary = p["attrs_base"]
		var live: Dictionary = p["attrs"]
		var d := -1
		for k in base:
			var b := int(base[k])
			var l := int(live.get(k, 0))
			if l > 0:                       # a floored-to-0 attr carries no information
				if d == -1:
					d = b - l
				elif b - l != d:
					all_consistent = false
			else:
				all_consistent = all_consistent and b <= 45
		if d != -1 and (d < Youth.DEGRADE_LO
				or d > Youth.DEGRADE_LO + Youth.DEGRADE_SPAN - 1):
			all_banded = false
	ok = _assert(all_based, "every youth record keeps its shipped BASE block") and ok
	ok = _assert(all_banded, "the knock-down is rand(11)+0x23, i.e. 35..45") and ok
	ok = _assert(all_consistent, "ONE roll knocks down all ten attributes, floored at 0") and ok
	# A senior record is NOT touched.
	var prem: Dictionary = {}
	for c in _db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem = c
			break
	var senior: Dictionary = (prem.get("players", []) as Array)[0]
	ok = _assert(not senior.has("attrs_base") or
		int((senior["attrs_base"] as Dictionary).get("CA", -1)) == int((senior["attrs"] as Dictionary).get("CA", -2)),
		"a senior record is not knocked down") and ok
	return ok


# ---- FUN_00575d90: the youth-scout predicate -----------------------------

func _unit_predicate() -> bool:
	var ok := true
	# BASE PO 85 -> HANDLING matches; PA 18 -> PASSING does not. The threshold is
	# `0x4f < byte`, so 79 misses and 80 hits.
	var keeper := {"attrs": {}, "attrs_base": {"PO": 85, "PA": 18, "RM": 19, "RG": 22, "EN": 22, "TI": 23}}
	ok = _assert(Youth.scout_matches(keeper, ["HANDLING"]), "PO 85 matches HANDLING") and ok
	ok = _assert(not Youth.scout_matches(keeper, ["PASSING"]), "PA 18 does not match PASSING") and ok
	ok = _assert(Youth.scout_matches(keeper, ["PASSING", "HANDLING"]),
		"the predicate is an OR over the lit capabilities") and ok
	ok = _assert(not Youth.scout_matches(keeper, []), "no capability lit -> no match") and ok
	var edge_lo := {"attrs": {}, "attrs_base": {"PO": 79}}
	var edge_hi := {"attrs": {}, "attrs_base": {"PO": 80}}
	ok = _assert(not Youth.scout_matches(edge_lo, ["HANDLING"]), "BASE 79 misses (0x4f < b)") and ok
	ok = _assert(Youth.scout_matches(edge_hi, ["HANDLING"]), "BASE 80 hits") and ok
	# The six criteria slots map to the TRAINING modes' own attributes.
	ok = _assert(Youth.CAP_ATTR == {
			"HANDLING": "PO", "DRIBBLING": "RM", "TACKLING": "EN",
			"HEADING": "RG", "PASSING": "PA", "SHOOTING": "TI"},
		"the six capability slots are PO/RM/EN/RG/PA/TI") and ok
	return ok


# ---- FUN_00575e80: the search keeps exactly ONE --------------------------

func _unit_search() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var pool := Youth.pool_of(_clubs_by_id)
	var sizes: Dictionary = {}
	for _i in 40:
		var got := Youth.scout_search(rng, ["HANDLING", "PASSING", "DRIBBLING"], pool)
		sizes[got.size()] = true
	ok = _assert(sizes.keys().max() <= 1, "the youth scout never returns more than one") and ok
	ok = _assert(sizes.has(1), "with capabilities lit it does find someone") and ok
	# It varies: not the same man every time (the pick is rand(n), not "the first").
	var seen: Dictionary = {}
	for _i in 60:
		for p in Youth.scout_search(rng, ["HANDLING", "PASSING", "DRIBBLING", "SHOOTING"], pool):
			seen[int(p["id"])] = true
	ok = _assert(seen.size() > 1, "the one kept is picked at random (%d distinct)" % seen.size()) and ok
	# `exclude` is the engine re-parenting a signed youngster out of club 0x26e4.
	var everyone: Array = []
	for p in pool:
		everyone.append(int(p["id"]))
	ok = _assert(Youth.scout_search(rng, ["HANDLING"], pool, everyone).is_empty(),
		"a pool with everyone already signed finds nobody") and ok
	ok = _assert(Youth.scout_search(rng, [], pool).is_empty(),
		"no capability lit -> the scout comes back empty-handed") and ok
	return ok


# ---- FUN_0053e860 @0x53e967: the duration --------------------------------

func _unit_weeks() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var band_ok := true
	var monotone_ok := true
	var prev_hi := 99999
	for q in range(1, 11):
		var lo := 99999
		var hi := -1
		for _i in 200:
			var w := Youth.search_weeks(rng, q)
			lo = mini(lo, w)
			hi = maxi(hi, w)
		# the raw binary band, before the owner's SEARCH_SPEEDUP divisor
		var raw_lo := Youth.SEARCH_BASE_WEEKS - Youth.SEARCH_PER_STAR * ((q + 1) >> 1)
		var raw_hi := raw_lo + Youth.SEARCH_SPAN - 1
		band_ok = band_ok \
			and lo >= int(ceil(float(raw_lo) / float(Youth.SEARCH_SPEEDUP))) \
			and hi <= int(ceil(float(raw_hi) / float(Youth.SEARCH_SPEEDUP)))
		monotone_ok = monotone_ok and hi <= prev_hi
		prev_hi = hi
	ok = _assert(band_ok, "weeks = rand(6) + 0x37 - 5*((q+1)>>1), over SEARCH_SPEEDUP") and ok
	ok = _assert(monotone_ok, "a better scout is never slower") and ok
	ok = _assert(Youth.SEARCH_BASE_WEEKS == 0x37 and Youth.SEARCH_SPAN == 6
		and Youth.SEARCH_PER_STAR == 5, "the three constants are the binary's own") and ok
	return ok


# ---- FUN_00582760 case 0x20: growth to BASE and no further ---------------

func _unit_develop() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# in_training: the 0x20 mode byte. A youngster who is NOT in the youth manager's
	# training programme does not develop at all (Training.YOUTH_MODE) — asserted below.
	var kid := {"name": "KID", "age": 17, "ready": false, "in_training": true,
		"attrs": _flat_attrs(40), "attrs_base": _flat_attrs(70)}
	var ready_news := 0
	for _w in 200:
		for n in Youth.develop_week(rng, [kid]):
			if n["kind"] == "youth":
				ready_news += 1
	ok = _assert(int(kid["attrs"]["CA"]) == 70, "a youth climbs to his shipped BASE (%d)"
		% int(kid["attrs"]["CA"])) and ok
	var no_overshoot := true
	for k in (kid["attrs"] as Dictionary):
		no_overshoot = no_overshoot and int(kid["attrs"][k]) <= int(kid["attrs_base"][k])
	ok = _assert(no_overshoot, "no attribute goes past BASE") and ok
	ok = _assert(Youth.is_ready(kid), "reaching BASE flags him ready") and ok
	ok = _assert(ready_news == 1, "the youth manager reports it exactly once (%d)" % ready_news) and ok
	# Growth is 60%, not every week: 200 weeks of a 30-point climb must not be
	# 30 weeks' worth of luck, but it must not take the full 200 either.
	var slow := {"name": "SLOW", "ready": false, "in_training": true,
		"attrs": _flat_attrs(0), "attrs_base": _flat_attrs(99)}
	var moved := 0
	for _w in 100:
		var before := int(slow["attrs"]["CA"])
		Youth.develop_week(rng, [slow])
		if int(slow["attrs"]["CA"]) > before:
			moved += 1
	ok = _assert(moved > 40 and moved < 80, "the weekly gain gate is ~60%% (%d/100)" % moved) and ok
	# A player already at BASE holds.
	var done := {"name": "DONE", "ready": true, "in_training": true,
		"attrs": _flat_attrs(60), "attrs_base": _flat_attrs(60)}
	for _w in 30:
		Youth.develop_week(rng, [done])
	ok = _assert(int(done["attrs"]["CA"]) == 60, "a finished youth holds at BASE") and ok
	# THE GATE (0x527820 / FUN_00582760 case 0x20): no TRAINING assignment, no growth.
	var idle := {"name": "IDLE", "ready": false,
		"attrs": _flat_attrs(40), "attrs_base": _flat_attrs(90)}
	for _w in 200:
		Youth.develop_week(rng, [idle])
	ok = _assert(int(idle["attrs"]["CA"]) == 40,
		"a youth NOT in training never develops (%d)" % int(idle["attrs"]["CA"])) and ok
	ok = _assert(not Youth.is_ready(idle), "and is never flagged ready") and ok
	return ok


func _unit_graduate() -> bool:
	var ok := true
	var p := {"id": 900001, "name": "KID", "age": 17, "isGK": false, "ready": true,
		"potential": 70, "is_youth": true, "attrs": _flat_attrs(60), "dev_progress": 0.4}
	Youth.graduate(p)
	ok = _assert(not p.has("potential") and not p.has("ready") and not p.has("is_youth"),
		"graduate strips the youth markers") and ok
	for k in ["injured_weeks", "suspended_weeks", "yellows"]:
		ok = _assert(p.has(k) and int(p[k]) == 0, "graduate stamps first-team field %s" % k) and ok
	ok = _assert(p.has("attrs") and int(p["attrs"]["CA"]) == 60, "graduate keeps his ability") and ok
	return ok


# ---- integration: a career runs the academy ------------------------------

func _career_integration() -> bool:
	var db: Dictionary = _db
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
	career.youth_pool = Youth.pool_of(_clubs_by_id)
	var ok := true
	ok = _assert(career.youth.size() == 0,
		"career starts with an empty academy (witnessed orig/39)") and ok

	# NO youth manager yet: FUN_0057cd30 returns 0 without a record in role 10, so
	# `capacity <= count` holds at 0 <= 0 and TRAINING is greyed for everyone. Hiring one
	# is what opens the programme — the engine's own dependency, not the port's.
	ok = _assert(Staff.youth_training_capacity(career.staff) == 0,
		"no YOUTH TEAM MANAGER -> no training capacity") and ok
	career.staff = [{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "G. KEEPING",
		"stars": 3.5, "wage": 30000}]
	# q = 7 -> FUN_00578b80 case 10's 7-8 band -> 3, the "3 PLAYERS" both youth-screen
	# witnesses print (walkthrough 047 at 3.5 stars, live capture at 4.0).
	ok = _assert(Staff.youth_training_capacity(career.staff) == 3,
		"a 3.5-star youth manager trains 3 (%d)"
		% Staff.youth_training_capacity(career.staff)) and ok

	# Sign three straight out of the pool, the way the PLAYERS FOUND panel does.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in 3:
		career.youth_found = Youth.scout_search(rng, ["HANDLING", "PASSING", "SHOOTING"],
			career.youth_pool, career._youth_taken())
		if career.youth_found.is_empty():
			continue
		career.sign_youth_prospect(int((career.youth_found[0] as Dictionary)["id"]), rng)
	ok = _assert(career.youth.size() >= 1, "signing from the pool fills the academy (%d)"
		% career.youth.size()) and ok
	var enrolled_ok := true
	for p in career.youth:
		enrolled_ok = enrolled_ok and int(p.get("clubId", -1)) == career.club_id \
			and bool(p.get("is_youth", false)) and p.has("attrs_base")
	ok = _assert(enrolled_ok, "a signed youngster is re-parented to your club with his BASE") and ok
	# ...and the shared pool record he came from is untouched, so the NEXT career gets
	# him pristine (GameDB is loaded once per app launch, unlike the engine's per-game load).
	var pool_clean := true
	for p in career.youth:
		for src in career.youth_pool:
			if int(src.get("id", -1)) == int(p.get("id", -2)):
				pool_clean = pool_clean and int(src.get("clubId", -1)) == Youth.POOL_CLUB_ID \
					and not src.has("is_youth") and not src.has("_from_youth_pool")
	ok = _assert(pool_clean, "signing does NOT mutate the shared GameDB pool record") and ok
	# The engine drops him out of 0x26e4 -- the scout can never find him again.
	var taken := career._youth_taken()
	var re_found := false
	for _i in 60:
		for p in Youth.scout_search(rng, ["HANDLING", "PASSING", "SHOOTING"], career.youth_pool, taken):
			if int(p["id"]) in taken:
				re_found = true
	ok = _assert(not re_found, "a signed youngster is never re-found") and ok

	# Grow one to his ceiling, then promote him.
	var kid: Dictionary = career.youth[0]
	# he has to be put INTO training first — that is the whole point of the card's
	# TRAINING button, and without it the loop below moves nothing.
	ok = _assert(bool(career.set_youth_training(int(kid["id"])).get("ok", false)),
		"the TRAINING button puts him in the programme") and ok
	for _w in 400:
		Youth.develop_week(rng, [kid])
	ok = _assert(Youth.is_ready(kid), "a signed youngster reaches his shipped ceiling") and ok
	var pid := int(kid["id"])
	var squad_before := career.my_squad().size()
	var res := career.promote_youth(pid)
	ok = _assert(res["ok"], "a ready youth is promoted") and ok
	ok = _assert(career.my_squad().size() == squad_before + 1, "promotion grows the first-team squad") and ok
	var found: Dictionary = {}
	for p in career.my_squad():
		if int(p.get("id", -1)) == pid:
			found = p
	ok = _assert(not found.is_empty() and int(found.get("clubId", -1)) == career.club_id
		and int(found.get("contract_years", 0)) > 0,
		"promoted youth is on the senior roster with a contract") and ok
	ok = _assert(not found.has("is_youth"), "promoted youth lost his youth marker") and ok

	# Rollover: everyone ages, NOBODY is released and no free crop appears — the
	# scout is the only way in, which is all MANAGER.EXE does.
	var ages_before: Array = []
	for p in career.youth:
		ages_before.append(int(p.get("age", 0)))
	var n_before := career.youth.size()
	career._roll_youth(RandomNumberGenerator.new())
	var aged_ok := true
	for i in career.youth.size():
		if i < ages_before.size():
			aged_ok = aged_ok and int(career.youth[i].get("age", 0)) == int(ages_before[i]) + 1
	ok = _assert(aged_ok, "the rollover ages every youngster a year") and ok
	ok = _assert(career.youth.size() >= n_before,
		"the rollover releases nobody; only the wonderkid egg adds (%d -> %d)" % [n_before, career.youth.size()]) and ok

	# Persistence: youth + youth_seq round-trip; an old save (no youth key) loads inert.
	var path := "user://career_youth_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null and loaded.youth.size() == career.youth.size()
		and loaded.youth_seq == career.youth_seq, "youth + youth_seq survive save/load") and ok
	var legacy := Career.from_dict({"club_id": 1, "rosters": {}})
	ok = _assert(legacy.youth.is_empty() and legacy.youth_seq == Career.YOUTH_ID_BASE,
		"a pre-youth save loads an empty inert academy") and ok
	return ok


# ---- helpers -------------------------------------------------------------

func _flat_attrs(v: int) -> Dictionary:
	return {"VE": v, "RE": v, "AG": v, "CA": v, "RM": v, "RG": v, "PA": v, "TI": v, "EN": v, "PO": v}


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
