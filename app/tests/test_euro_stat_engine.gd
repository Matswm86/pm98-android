extends SceneTree
## S5 — do European ties run on the BYTE-EXACT stat engine, or on the legacy abstraction?
##
## `MatchSim._usable` rejects an XI that is not eleven players all carrying a decoded attr
## row, and a foreign club has no live roster, so before 2026-07-27 every European tie fell
## through to `MatchEngine.simulate` (~37 a season, loudly tagged `[MATCHSIM_FALLBACK]`).
## The fix was `Career.euro_xis`: each foreign club's own shipped TRUE XI, resolved from
## `club_tactics.json` over its game_db attr squad and fed in by `Main._true_xi_index`.
##
## The s78 handoff still carried S5 as OPEN and "verified still live in MatchSim.gd". It is
## not: the only `[MATCHSIM_FALLBACK]` lines left come from `test_europe.gd`'s own rig,
## which invents clubs at ids 90000+ that have no `club_tactics.json` entry and so cannot
## be indexed. This test drives the REAL data instead — the real true-XI index, the real
## foreign pool `Main._euro_pool` builds — for a whole season, and requires ZERO fallbacks.
##
##   ~/godot462 --headless --path app --script res://tests/test_euro_stat_engine.gd

const SA := ["ARGENTINA", "BRAZIL", "URUGUAY", "CHILE", "COLOMBIA", "PERU",
	"BOLIVIA", "PARAGUAY", "ECUADOR", "VENEZUELA"]

func _initialize() -> void:
	var db: Dictionary = JSON.parse_string(
		FileAccess.open("res://data/game_db.json", FileAccess.READ).get_as_text())
	var clubs: Array = db.get("clubs", [])
	var leagues: Array = db.get("leagues", [])
	var by_id := {}
	for c in clubs:
		by_id[int(c["id"])] = c
	var tacts: Dictionary = (JSON.parse_string(
		FileAccess.open("res://data/club_tactics.json", FileAccess.READ).get_as_text()
		) as Dictionary).get("clubs", {})
	# the true-XI index, exactly as Main._true_xi_index builds it
	var xis := {}
	var no_tactic := 0
	for c in clubs:
		var cid := int(c.get("id", -1))
		var t: Variant = tacts.get(str(cid))
		if not (t is Dictionary):
			no_tactic += 1
			continue
		var ids: Variant = (t as Dictionary).get("xi")
		if not (ids is Array) or (ids as Array).size() != 11:
			continue
		var pmap := {}
		for p in c.get("players", []):
			pmap[int(p.get("id", -1))] = p
		var xi := []
		for pid in ids:
			var p: Variant = pmap.get(int(pid))
			if p == null or not ((p as Dictionary).get("attrs", {}) as Dictionary).size() > 0:
				xi = []
				break
			xi.append(p)
		if xi.size() == 11:
			xis[cid] = xi
	# the real foreign pool, as Main._euro_pool builds it
	var scored := []
	for c in clubs:
		if c.get("leagueId") != null or str(c.get("country", "")) in SA:
			continue
		if (c.get("players", []) as Array).is_empty():
			continue
		var r := MatchEngine.team_ratings(c)
		scored.append({"c": c, "s": float(r["att"]) + float(r["def"]) + float(r["gk"])})
	scored.sort_custom(func(a, b): return a["s"] > b["s"])
	var pool := []
	for e in scored.slice(0, 96):
		pool.append(e["c"])
	var covered := 0
	for c in pool:
		if xis.has(int(c["id"])):
			covered += 1
	var ok := _assert(covered == pool.size(),
		"every club of the foreign euro pool has a TRUE XI (%d of %d indexed, %d in the "
		% [covered, pool.size(), xis.size()] + "whole index)")

	var prem := []
	var league := {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in clubs:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var career := Career.create(prem[0], league, prem, leagues)
	career.euro_xis = xis
	var rng := RandomNumberGenerator.new()
	rng.seed = 31337
	career.last_champion_id = career.club_id
	career.mint_european_cups(pool, rng)
	MatchSim.fallback_count = 0
	while not career.season_over():
		career.advance_week(rng, by_id)
	var champs := 0
	for key in career.euro:
		if int((career.euro[key] as Dictionary).get("champion_id", -1)) != -1:
			champs += 1
	ok = _assert(champs == 3, "all three European competitions reached a champion (%d)" % champs) and ok
	ok = _assert(MatchSim.fallback_count == 0,
		"a whole European season ran with ZERO legacy fallbacks (got %d)"
		% MatchSim.fallback_count) and ok
	print("test_euro_stat_engine: ", "ALL PASS" if ok else "FAILURES ABOVE")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
