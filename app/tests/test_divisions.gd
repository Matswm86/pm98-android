extends SceneTree
## Smoke test: every English division simulates cleanly (20- and 24-team).
##   ~/godot462 --headless --path app --script res://tests/test_divisions.gd

func _initialize() -> void:
	quit(0 if _run() else 1)

func _run() -> bool:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing")
		return false
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var by_league: Dictionary = {}
	for c in db.get("clubs", []):
		var lid: Variant = c.get("leagueId")
		if lid != null:
			by_league.get_or_add(lid, []).append(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ok := true
	for lg in db.get("leagues", []):
		var clubs: Array = by_league.get(lg["id"], [])
		var res := SeasonSim.simulate_season(rng, clubs)
		var table: Array = res["table"]
		# each club must play (n-1)*2 games; total fixtures = n*(n-1)
		var n := clubs.size()
		var expect_fix := n * (n - 1)
		var per_club_ok := true
		for r in table:
			if r["P"] != (n - 1) * 2:
				per_club_ok = false
		var champ: Dictionary = table[0]
		var marker := SeasonSim.zone_marker(int(lg.get("tier", 0)), 0, n)
		print("%-14s n=%2d games=%3d (expect %3d) fixOK=%s pOK=%s  champ=%s %dpts [%s]" % [
			lg["name"], n, res["fixtures"], expect_fix,
			res["fixtures"] == expect_fix, per_club_ok, champ["name"], champ["Pts"],
			"promo" if marker == "P" else "top"])
		ok = ok and res["fixtures"] == expect_fix and per_club_ok
	print("\n%s" % ("DIVISIONS OK" if ok else "FAIL"))
	return ok
