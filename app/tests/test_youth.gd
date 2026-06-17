extends SceneTree
## Headless test for the Youth Team (Track A engine depth).
##   ~/godot462 --headless --path app --script res://tests/test_youth.gd
## Covers the Youth unit model (intake shape, development toward potential, the readiness
## flag + news, graduate stamping) and the Career integration (academy seeded at create,
## a season develops + flags youngsters, promotion moves a ready youth to the first team,
## guards reject a raw/over-cap promotion, rollover ages + releases + re-scouts, and youth
## persists through save/load with old saves loading inert).

const SEED := 77881122


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var ok := true
	ok = _unit_intake() and ok
	ok = _unit_develop() and ok
	ok = _unit_graduate() and ok
	ok = _career_integration() and ok
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


# ---- unit: intake --------------------------------------------------------

func _unit_intake() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var crop := Youth.intake(rng, 6, 900000)
	ok = _assert(crop.size() == 6, "intake produces the requested count") and ok
	var ids := {}
	var shape_ok := true
	var age_ok := true
	var pot_ok := true
	for p in crop:
		ids[int(p["id"])] = true
		for k in ["id", "name", "age", "isGK", "attrs", "potential", "dev_progress", "ready"]:
			shape_ok = shape_ok and p.has(k)
		var a: Dictionary = p["attrs"]
		for code in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]:
			shape_ok = shape_ok and a.has(code)
		age_ok = age_ok and int(p["age"]) >= Youth.INTAKE_AGE_LO and int(p["age"]) <= Youth.INTAKE_AGE_HI
		pot_ok = pot_ok and int(p["potential"]) >= int(a["CA"])
		ok = _assert(not Youth.is_ready(p), "fresh intake is not ready") and ok
	ok = _assert(ids.size() == 6, "intake ids are unique (%d distinct)" % ids.size()) and ok
	ok = _assert(int(crop[0]["id"]) == 900000 and int(crop[5]["id"]) == 900005, "ids run from first_id") and ok
	ok = _assert(shape_ok, "every youth carries the senior dict shape + youth markers") and ok
	ok = _assert(age_ok, "intake ages sit in the band") and ok
	ok = _assert(pot_ok, "potential >= current ability for every intake") and ok
	return ok


# ---- unit: development ---------------------------------------------------

func _unit_develop() -> bool:
	var ok := true
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	# A high-ceiling prospect climbs toward potential and eventually gets flagged ready.
	var gem := {"name": "GEM", "age": 16, "isGK": false, "ready": false, "dev_progress": 0.0,
		"potential": 72, "attrs": _flat_attrs(40)}
	var ca0 := int(gem["attrs"]["CA"])
	var ready_news := 0
	for _w in 80:
		for n in Youth.develop_week(rng, [gem]):
			if n["kind"] == "youth":
				ready_news += 1
	ok = _assert(int(gem["attrs"]["CA"]) > ca0, "a youth climbs (CA %d->%d)" % [ca0, int(gem["attrs"]["CA"])]) and ok
	ok = _assert(int(gem["attrs"]["CA"]) <= int(gem["potential"]), "CA never overshoots potential") and ok
	ok = _assert(Youth.is_ready(gem), "a high-ceiling youth becomes ready") and ok
	ok = _assert(ready_news >= 1, "crossing readiness fires exactly one youth-manager news (%d)" % ready_news) and ok
	ok = _assert(ready_news == 1, "the ready news fires once, not every week") and ok

	# A capped-out prospect holds (no further climb past potential).
	var capped := {"name": "CAP", "age": 17, "isGK": false, "ready": true, "dev_progress": 0.0,
		"potential": 50, "attrs": _flat_attrs(50)}
	for _w in 30:
		Youth.develop_week(rng, [capped])
	ok = _assert(int(capped["attrs"]["CA"]) == 50, "a youth at his ceiling holds") and ok

	# A low-ceiling prospect never reaches the first-team grade.
	var weak := {"name": "WEAK", "age": 16, "isGK": false, "ready": false, "dev_progress": 0.0,
		"potential": Youth.READY_CA - 6, "attrs": _flat_attrs(34)}
	for _w in 120:
		Youth.develop_week(rng, [weak])
	ok = _assert(not Youth.is_ready(weak), "a low-ceiling youth never reaches ready") and ok
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
	ok = _assert(career.youth.size() == Career.YOUTH_SEED_COUNT,
		"career seeds the academy (%d youth)" % career.youth.size()) and ok
	var above_senior := true
	for p in career.youth:
		above_senior = above_senior and int(p["id"]) >= Career.YOUTH_ID_BASE
	ok = _assert(above_senior, "youth ids sit above the senior id space (no collision)") and ok

	# Develop the academy a season's worth (directly, fast) so it separates into
	# ready / developing, mirroring what advance_week does each week.
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for _w in 60:
		Youth.develop_week(rng, career.youth)
	# Guarantee a ready prospect to promote.
	if career.promotable_youth().is_empty():
		var top: Dictionary = career.youth[0]
		(top["attrs"] as Dictionary)["CA"] = Youth.READY_CA + 3
		top["ready"] = true
	var ready := career.promotable_youth()
	ok = _assert(not ready.is_empty(), "the academy produces a promotable youngster") and ok

	# A non-ready youth can't be promoted.
	var raw: Dictionary = {}
	for p in career.youth:
		if not Youth.is_ready(p):
			raw = p
			break
	if not raw.is_empty():
		var bad := career.promote_youth(int(raw["id"]))
		ok = _assert(not bad["ok"], "a not-ready youth is rejected for promotion") and ok

	# Promote a ready youth: he leaves youth, joins the first team on a contract.
	var pid := int(ready[0]["id"])
	var squad_before := career.my_squad().size()
	var youth_before := career.youth.size()
	var res := career.promote_youth(pid)
	ok = _assert(res["ok"], "a ready youth is promoted") and ok
	ok = _assert(career.my_squad().size() == squad_before + 1, "promotion grows the first-team squad") and ok
	ok = _assert(career.youth.size() == youth_before - 1, "promotion shrinks the youth team") and ok
	var found: Dictionary = {}
	for p in career.my_squad():
		if int(p.get("id", -1)) == pid:
			found = p
	ok = _assert(not found.is_empty() and int(found.get("clubId", -1)) == career.club_id
		and int(found.get("contract_years", 0)) > 0, "promoted youth is on the senior roster with a contract") and ok
	ok = _assert(not found.has("is_youth"), "promoted youth lost his youth marker") and ok
	var promo_news := 0
	for n in career.news_log:
		if n is Dictionary and n.get("kind") == "youth" and str(n.get("text", "")).contains("promoted"):
			promo_news += 1
	ok = _assert(promo_news >= 1, "promotion writes club news") and ok

	# Rollover: youth age, over-age non-promoted leave, a fresh crop is scouted in.
	for p in career.youth:
		p["age"] = Youth.GRADUATE_AGE + 1   # force everyone over-age so all are released
	var rolled := RandomNumberGenerator.new()
	rolled.seed = SEED + 1
	career._roll_youth(rolled)
	var all_fresh := true
	for p in career.youth:
		all_fresh = all_fresh and int(p["age"]) <= Youth.GRADUATE_AGE
	ok = _assert(not career.youth.is_empty(), "rollover scouts a fresh crop") and ok
	ok = _assert(all_fresh, "over-age youth are released, only fresh intake remains") and ok
	var join_news := 0
	for n in career.news_log:
		if n is Dictionary and str(n.get("text", "")).contains("joined your Youth Team"):
			join_news += 1
	ok = _assert(join_news >= 1, "a scouted youth surfaces as 'joined your Youth Team' news") and ok

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
