extends SceneTree
## PROBE (2026-07-27): which club can end a rollover with < 11 men?
## Drives a full season + rollover over many career seeds and reports every bare club
## next to its STATIC record size, which separates a data gap from an in-season drain.
## ANSWER: it was never a data gap. The bare club was always the MANAGER's own (club 38,
## static record 22 men), down to 6-10 on 15 of 40 seeds because every expiring contract
## walked. MANAGER.EXE FUN_0058AC90 @0x58AE55 refuses to release below thirteen; with that
## floor ported the same sweep reports ZERO. See docs/re/retirement_re.md.
func _initialize() -> void:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	f = FileAccess.open("res://data/season_seed_1997.json", FileAccess.READ)
	var seeds_file: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var all: Array = db.get("clubs", [])
	var by_league: Dictionary = {}
	for c in all:
		if c.get("leagueId") != null:
			if not by_league.has(c["leagueId"]):
				by_league[c["leagueId"]] = []
			(by_league[c["leagueId"]] as Array).append(c)
	var divs: Array = []
	var league_by_id: Dictionary = {}
	for lg in leagues:
		league_by_id[lg["id"]] = lg
		divs.append({"league_id": lg["id"], "name": lg["name"], "tier": int(lg["tier"]),
			"clubs": by_league.get(lg["id"], [])})
	var pyramid := {"divisions": divs, "seeds": seeds_file.get("seeds", {})}
	# static squad sizes, straight from the DB
	var minsize := 999
	var minname := ""
	for lgid in ["eng_prem", "eng_div1", "eng_div2", "eng_div3"]:
		for c in by_league[lgid]:
			var n: int = (c["players"] as Array).size()
			if n < minsize:
				minsize = n
				minname = str(c["name"])
	print("static min squad over 92 English clubs: %d (%s)" % [minsize, minname])
	var bad := 0
	for s in range(20):
		var prem: Array = by_league["eng_prem"]
		var c := Career.new()
		c.reputation = Manager.REP_START
		c.career_rng_state = str(19970809 + s * 7919)
		c._init_club(prem[0], league_by_id["eng_prem"], prem, leagues, pyramid)
		var rng := RandomNumberGenerator.new()
		rng.seed = 19970809 + s * 7919
		var guard := 0
		while not c.season_over():
			c.advance_week(rng)
			guard += 1
			if guard > 80:
				print("  GUARD TRIPPED week=%d" % c.week)
				break
		print("  season done at week %d" % c.week)
		c.advance_season(leagues, rng)
		for id in c.rosters:
			if (c.rosters[id] as Array).size() < 11:
				bad += 1
				print("  seed %d: club %d '%s' has %d men (static record players=%d)" % [
					s, int(id), str(c.club_names.get(int(id), "?")),
					(c.rosters[id] as Array).size(),
					((c._div_clubs.get(int(id), {}) as Dictionary).get("players", []) as Array).size()])
	print("bare rosters over the sweep: %d" % bad)
	quit(0)
