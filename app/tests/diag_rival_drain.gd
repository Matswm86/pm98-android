extends SceneTree
func _initialize() -> void:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if str(lg["id"]) == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if str(c.get("leagueId", "")) == "eng_prem":
			prem.append(c)
	var c2 := Career.new()
	c2.reputation = Manager.REP_START
	c2.career_rng_state = "19970809"
	c2._init_club(prem[0], league, prem, leagues, {})
	var rng := RandomNumberGenerator.new()
	rng.seed = 19970809
	for season in 5:
		while not c2.season_over():
			c2.advance_week(rng)
		c2.advance_season(leagues, rng)
		var tot := 0
		var mn := 999
		var reb := 0
		for cid in c2.rosters:
			var n: int = (c2.rosters[cid] as Array).size()
			if int(cid) != c2.club_id:
				tot += n
				mn = mini(mn, n)
			for p in c2.rosters[cid]:
				if (p as Dictionary).get("reborn"):
					reb += 1
		printerr("season %d: mine=%d rivals_total=%d rival_min=%d reborn=%d youth=%d free=%d" % [
			season, (c2.rosters[c2.club_id] as Array).size(), tot, mn, reb,
			(c2.youth as Array).size(), (c2.free_agents as Array).size()])
	quit(0)
