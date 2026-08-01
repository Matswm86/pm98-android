extends SceneTree
## DIAG: drive the whole youth loop the way a player does, and print what happens.
##   ~/godot4 --headless --path app --script res://tests/diag_youth_e2e.gd

const SEED := 4242

func _initialize() -> void:
	_run()
	quit(0)


func _run() -> void:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var clubs_by_id: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for c in db.get("clubs", []):
		clubs_by_id[int(c["id"])] = c
		if int(c["id"]) == 1383:
			for p in c.get("players", []):
				Youth.degrade(p, rng)

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
	career.youth_pool = Youth.pool_of(clubs_by_id)
	print("POOL size=%d" % career.youth_pool.size())
	if career.youth_pool.size() > 0:
		var p0: Dictionary = career.youth_pool[0]
		print("  sample %s age=%s attrs=%s base=%s" % [p0.get("name"), p0.get("age"),
			p0.get("attrs"), p0.get("attrs_base")])

	career.staff = [
		{"id": 1, "role": Staff.YOUTH_TEAM_SCOUT, "name": "P. MITCHELL", "stars": 5.0, "wage": 40000},
		{"id": 2, "role": Staff.YOUTH_TEAM_MANAGER, "name": "G. KEEPING", "stars": 3.5, "wage": 30000},
	]
	print("scout quality_byte=%d" % Staff.quality_byte(career.staff[0]))

	# --- arm a search with all six LEDs lit ---
	var caps := ["HANDLING", "DRIBBLING", "TACKLING", "HEADING", "PASSING", "SHOOTING"]
	# how many pool records would match each single cap?
	for cap in caps:
		var n := 0
		for p in career.youth_pool:
			if Youth.scout_matches(p, [cap]):
				n += 1
		print("  cap %-10s matches %d" % [cap, n])
	var nall := 0
	for p in career.youth_pool:
		if Youth.scout_matches(p, caps):
			nall += 1
	print("  ALL SIX matches %d of %d" % [nall, career.youth_pool.size()])

	career.start_youth_search(caps)
	print("SEARCH armed weeks=%s" % career.youth_search.get("weeks"))

	var w := 0
	var signed := {}
	var promoted := false
	var seasons := 0
	while w < 300:
		if career.season_over():
			career.advance_season(db.get("leagues", []), rng, [], {}, [])
			seasons += 1
			print("---- season rollover -> %s (academy=%d) ----" % [career.season, career.youth.size()])
			if seasons > 3:
				break
		career.advance_week(rng, clubs_by_id)
		w += 1
		if not career.youth_found.is_empty() and signed.is_empty():
			var pr: Dictionary = career.youth_found[0]
			print("[w%3d] FOUND %s age=%s CA=%d ceiling=%d" % [w, pr.get("name"),
				pr.get("age"), Youth.ability(pr), Youth.potential_of(pr)])
			var tries := 0
			while not career.youth_found.is_empty() and tries < 1:
				var res := career.sign_youth_prospect(int((career.youth_found[0] as Dictionary)["id"]), rng)
				print("        OFFER -> %s" % res.get("msg"))
				tries += 1
			if career.youth.size() > 0:
				signed = career.youth[0]
				print("        academy=%d  signed CA=%d base CA=%d" % [career.youth.size(),
					Youth.ability(signed), int(Training.base_attrs(signed).get("CA", 0))])
		if not signed.is_empty() and not promoted:
			if Youth.is_ready(signed):
				print("[w%3d] READY %s CA=%d" % [w, signed.get("name"), Youth.ability(signed)])
				var r2 := career.promote_youth(int(signed["id"]))
				print("        PROMOTE -> %s" % r2)
				promoted = true
				break
		if w % 20 == 0 and not signed.is_empty():
			print("[w%3d] growing: CA=%d/%d ready=%s" % [w, Youth.ability(signed),
				int(Training.base_attrs(signed).get("CA", 0)), Youth.is_ready(signed)])
		if w % 40 == 0:
			print("[w%3d] season=%s week=%s search=%s found=%d academy=%d" % [w,
				career.season, career.week, career.youth_search, career.youth_found.size(),
				career.youth.size()])
	print("DONE weeks=%d promoted=%s academy=%d" % [w, promoted, career.youth.size()])
