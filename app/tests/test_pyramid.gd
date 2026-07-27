extends SceneTree
## Headless test for the LIVING PYRAMID (all four English divisions simulated).
##   ~/godot462 --headless --path app --script res://tests/test_pyramid.gd
## Witness base (2026-07-19, screenshots/wine-captures-2026-07-19-lowerdiv/):
##   - pre-season tables list clubs in the WITNESSED seed order (P=0), never
##     alphabetically (frames w5_lt_premier / w5_lt_default / w6_lt_second_seed /
##     w7_lt_third_seed);
##   - divisions BELOW the manager's have played round 1 by the manager's week-1
##     Saturday; divisions at/above are in sync (w4/w5/w6/w7 careers);
##   - lower divisions produce real per-player goal scorers (lt_goalscorers_third);
##   - weekly revisions carry previous-position data (movement arrows, lt_wk2);
##   - zone structure: Prem releg 3 / Div1 2+4po+3rel / Div2 2+4po+4rel /
##     Div3 3+4po (tag columns on all four witnessed tables).

const SEED := 19970809


func _initialize() -> void:
	quit(0 if _run() else 1)


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _run() -> bool:
	var db := _load_json("res://data/game_db.json")
	var seeds_file := _load_json("res://data/season_seed_1997.json")
	if db.is_empty() or seeds_file.is_empty():
		push_error("game_db.json / season_seed_1997.json missing")
		return false
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])
	var by_league: Dictionary = {}
	for c in all:
		if c.get("leagueId") != null:
			if not by_league.has(c["leagueId"]):
				by_league[c["leagueId"]] = []
			(by_league[c["leagueId"]] as Array).append(c)
	var seeds: Dictionary = seeds_file.get("seeds", {})
	var divs: Array = []
	var league_by_id: Dictionary = {}
	for lg in leagues:
		league_by_id[lg["id"]] = lg
		divs.append({"league_id": lg["id"], "name": lg["name"], "tier": int(lg["tier"]),
			"clubs": by_league.get(lg["id"], [])})
	var pyramid := {"divisions": divs, "seeds": seeds}

	var ok := true

	# The div3 membership carries the LIVE game's Macclesfield (not the stale
	# static-table Hereford) — witnessed on three careers.
	var d3_names: Array = []
	for c in by_league["eng_div3"]:
		d3_names.append(c["name"])
	ok = _assert(d3_names.has("Macclesfield T."), "game_db Div3 fields Macclesfield T.") and ok
	ok = _assert(not d3_names.has("Hereford U."), "Hereford U. not in game_db Div3") and ok

	# --- Premier career: seed orders + head start ---------------------------
	var prem: Array = by_league["eng_prem"]
	var career := _pinned_career(prem[0], league_by_id["eng_prem"], prem, leagues, pyramid)
	ok = _assert(career.divisions.size() == 3, "3 other divisions built") and ok
	for t in [2, 3, 4]:
		ok = _assert(career.has_division(t), "tier %d present" % t) and ok
	# Witnessed seed order at P=0 for the manager's own table.
	var prem_rows := career.standings()
	var prem_want: Array = seeds["eng_prem"]
	var prem_ok := prem_rows.size() == 20
	for i in prem_rows.size():
		if int(prem_rows[i]["id"]) != int(prem_want[i]):
			prem_ok = false
	ok = _assert(prem_ok, "Premier week-0 table == witnessed seed order") and ok
	# Witnessed head start: below divisions have already played round 1.
	ok = _assert(int(career.divisions[2]["played"]) == 1, "Div1 pre-played 1 round") and ok
	ok = _assert(int(career.divisions[3]["played"]) == 1, "Div2 pre-played 1 round") and ok
	ok = _assert(int(career.divisions[4]["played"]) == 1, "Div3 pre-played 1 round") and ok
	var p_sum := 0
	for r in prem_rows:
		p_sum += int(r["P"])
	ok = _assert(p_sum == 0, "manager division un-played at create") and ok
	# Lower divisions already have real per-player scorers (witnessed chart).
	ok = _assert((career.divisions[4]["scorers"] as Array).size() > 0,
		"Div3 scorer ledger non-empty after its round 1") and ok
	ok = _assert(career.league_scorers_for(4).size() > 0, "Div3 scorers chart rows") and ok
	ok = _assert(not career.names_for(4).is_empty(), "names_for(4) wired") and ok

	# --- Div-1 career: offset is RELATIVE to the manager (witnessed w5) -----
	var d1: Array = by_league["eng_div1"]
	var c_d1 := _pinned_career(d1[0], league_by_id["eng_div1"], d1, leagues, pyramid)
	ok = _assert(int(c_d1.divisions[1]["played"]) == 0, "Premier in sync for a Div-1 manager") and ok
	ok = _assert(int(c_d1.divisions[3]["played"]) == 1, "Div2 a round ahead for a Div-1 manager") and ok
	ok = _assert(int(c_d1.divisions[4]["played"]) == 1, "Div3 a round ahead for a Div-1 manager") and ok
	# Witnessed Div-1 seed order for the manager's own table at P=0.
	var d1_rows := c_d1.standings()
	var d1_want: Array = seeds["eng_div1"]
	var d1_ok := d1_rows.size() == 24
	for i in d1_rows.size():
		if int(d1_rows[i]["id"]) != int(d1_want[i]):
			d1_ok = false
	ok = _assert(d1_ok, "Div-1 manager week-0 table == witnessed seed order") and ok
	# Premier seed order also witnessed from the Div-1 career (career-independent).
	var pr_rows := c_d1.standings_for(1)
	var pr_ok := pr_rows.size() == 20
	for i in pr_rows.size():
		if int(pr_rows[i]["id"]) != int(prem_want[i]):
			pr_ok = false
	ok = _assert(pr_ok, "Premier week-0 order career-independent") and ok

	# --- weekly advance: every division moves, arrows data appears ----------
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	career.advance_week(rng)
	for t in [2, 3, 4]:
		ok = _assert(int(career.divisions[t]["played"]) == 2,
			"tier %d at 2 rounds after manager week 1" % t) and ok
	ok = _assert(not career.table_prev.is_empty(), "manager prev-positions captured") and ok
	ok = _assert(not (career.divisions[2]["prev"] as Dictionary).is_empty(),
		"division prev-positions captured") and ok
	ok = _assert(not career.prev_positions_for(2).is_empty(), "prev_positions_for wired") and ok

	# --- save / load round-trip + ensure_divisions ---------------------------
	var path := "user://pyramid_test.json"
	career.save(path)
	var loaded := Career.load_save(path)
	ok = _assert(loaded != null, "career loaded") and ok
	if loaded != null:
		ok = _assert(loaded.divisions.size() == 3, "divisions survived round-trip") and ok
		ok = _assert(int(loaded.divisions[3]["played"]) == int(career.divisions[3]["played"]),
			"played counters survived") and ok
		ok = _assert((loaded.divisions[4]["scorers"] as Array).size() ==
			(career.divisions[4]["scorers"] as Array).size(), "scorer ledgers survived") and ok
		loaded.ensure_divisions(pyramid)
		ok = _assert(int(loaded.divisions[3]["played"]) == int(career.divisions[3]["played"]),
			"ensure_divisions does not re-simulate an up-to-date save") and ok
		# Pre-pyramid save: strip divisions, reload, ensure -> fast-forwarded fresh.
		var d := career.to_dict()
		d.erase("divisions")
		d.erase("seed_pos")
		var legacy := Career.from_dict(d)
		ok = _assert(legacy.divisions.is_empty(), "legacy save loads with no divisions") and ok
		legacy.ensure_divisions(pyramid)
		ok = _assert(legacy.divisions.size() == 3, "legacy save gains the pyramid") and ok
		ok = _assert(int(legacy.divisions[3]["played"]) == legacy.week + 1,
			"legacy pyramid fast-forwarded to the offset round count") and ok

	# --- full season + rollover: witnessed movement counts -------------------
	while not career.season_over():
		career.advance_week(rng)
	var final_prem: Array = []
	for r in career.standings():
		final_prem.append(int(r["id"]))
	var final_d1: Array = []
	for r in career.standings_for(2):
		final_d1.append(int(r["id"]))
	var relegated: Array = final_prem.slice(17)
	career.advance_season(leagues, rng)
	# Memberships: 20/24/24/24 after movement.
	var m_counts: Array = []
	for t in [1, 2, 3, 4]:
		if t == career.tier:
			m_counts.append(career.rosters.size())
		else:
			m_counts.append((career.divisions[t]["ids"] as Array).size())
	ok = _assert(m_counts == [20, 24, 24, 24],
		"memberships after rollover = %s" % [m_counts]) and ok
	# The witnessed movement: Premier's bottom 3 now sit in Division One, seeded
	# at the TOP in their finishing order (the witnessed construction).
	var d1_ids: Array = career.rosters.keys() if career.tier == 2 else career.divisions[2]["ids"]
	var moved_ok := true
	for id in relegated:
		if not d1_ids.has(int(id)):
			moved_ok = false
	ok = _assert(moved_ok, "Premier bottom 3 relegated into Division One") and ok
	if career.tier != 2:
		var top3: Array = (career.divisions[2]["ids"] as Array).slice(0, 3)
		ok = _assert(top3 == relegated, "relegated trio seed Div-1 rows 1-3 in finish order") and ok
	# Div 1's top two are now Premier members (auto promotion; playoff winner too).
	var prem_ids: Array = career.rosters.keys() if career.tier == 1 else career.divisions[1]["ids"]
	ok = _assert(prem_ids.has(int(final_d1[0])) and prem_ids.has(int(final_d1[1])),
		"Div-1 top two promoted to the Premier") and ok
	var promoted_count := 0
	for id in prem_ids:
		if final_d1.has(int(id)):
			promoted_count += 1
	ok = _assert(promoted_count == 3, "exactly 3 came up from Div 1 (2 auto + playoff)") and ok
	# The manager's club followed its own finish.
	var my_final_pos := final_prem.find(career.club_id) + 1
	var want_tier: int = 2 if my_final_pos >= 18 else 1
	ok = _assert(career.tier == want_tier,
		"manager (finished %d) now in tier %d" % [my_final_pos, career.tier]) and ok
	# Every live-division member has a usable roster (arrivals were seeded).
	var rosters_ok := true
	for id in career.rosters:
		if (career.rosters[id] as Array).size() < 11:
			rosters_ok = false
	ok = _assert(rosters_ok, "every live-division club fields a squad after movement") and ok
	# New season's below divisions re-open a round ahead (consistent extension).
	for t in career.divisions:
		var want_p2: int = 1 if int(t) > career.tier else 0
		ok = _assert(int(career.divisions[t]["played"]) == want_p2,
			"tier %s re-opened at %d rounds" % [t, want_p2]) and ok

	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	return ok


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond


## S3 (2026-07-27): pin the career stream BEFORE create()'s first draw, so the division
## sim and the rollover movement reproduce bit-exactly on CI.
## The flake this was written for was mis-attributed to a "sparse English squads" DATA gap.
## Measured 2026-07-27: game_db ships 9,547 players and every English club fields 17-30 of
## them. The bare roster was the MANAGER's own club, drained by contract expiry because the
## port had no release floor — MANAGER.EXE FUN_0058AC90 @0x58AE55 refuses to release from a
## squad under thirteen. Fixed in Career.advance_season; see docs/re/retirement_re.md.
## The pin stays: it is a deterministic regression baseline in its own right.
func _pinned_career(club: Dictionary, league: Dictionary, clubs: Array, leagues: Array,
		pyramid: Dictionary) -> Career:
	var c := Career.new()
	c.reputation = Manager.REP_START
	c.career_rng_state = str(SEED)
	c._init_club(club, league, clubs, leagues, pyramid)
	return c
