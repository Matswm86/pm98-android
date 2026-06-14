extends SceneTree
## Headless validation of the PM98 match engine (Phase 1).
##
## Run from the project dir:
##   ~/godot462 --headless --path app --script res://tests/test_engine.gd
##
## Simulates the real Premier League division many times and checks the
## aggregate output lands in real-football ranges. Also prints one sample final
## table for eyeballing that strong clubs finish high. Exit code 0 = all PASS.

const SEASONS := 300
const SEED := 20240615

# Real-football acceptance windows (English top flight, 38-game season).
const T_GOALS := [2.3, 3.1]      # goals per game
const T_HOME := [0.40, 0.52]     # home-win share
const T_DRAW := [0.18, 0.32]     # draw share
const T_AWAY := [0.22, 0.36]     # away-win share
const T_CHAMP := [74.0, 98.0]    # champion points (avg over seasons)
const T_BOTTOM := [16.0, 40.0]   # last-place points (avg over seasons)


func _initialize() -> void:
	quit(0 if _run() else 1)


func _run() -> bool:
	var clubs := _premier_clubs()
	if clubs.size() != 20:
		push_error("expected 20 Premier clubs, got %d" % clubs.size())
		return false
	print("=== PM98 match engine — %d-season Premier League validation ===" % SEASONS)
	print("Tunables: BASE_HOME=%.2f BASE_AWAY=%.2f SCALE=%.1f GK_WEIGHT=%.2f" % [
		MatchEngine.BASE_HOME, MatchEngine.BASE_AWAY, MatchEngine.SCALE, MatchEngine.GK_WEIGHT])
	_print_ratings(clubs)

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED

	var tot_goals := 0
	var tot_games := 0
	var hw := 0
	var dr := 0
	var aw := 0
	var champ_sum := 0.0
	var bottom_sum := 0.0
	var pts_by_club: Dictionary = {}    # id -> summed points across seasons
	var sample_table: Array = []

	for s in range(SEASONS):
		var res := SeasonSim.simulate_season(rng, clubs)
		tot_goals += int(res["goals"])
		tot_games += int(res["fixtures"])
		hw += int(res["home_wins"])
		dr += int(res["draws"])
		aw += int(res["away_wins"])
		var table: Array = res["table"]
		champ_sum += float(table[0]["Pts"])
		bottom_sum += float(table[-1]["Pts"])
		for r in table:
			pts_by_club[r["id"]] = float(pts_by_club.get(r["id"], 0.0)) + float(r["Pts"])
		if s == 0:
			sample_table = table

	var gpg := float(tot_goals) / float(tot_games)
	var home_pct := float(hw) / float(tot_games)
	var draw_pct := float(dr) / float(tot_games)
	var away_pct := float(aw) / float(tot_games)
	var champ := champ_sum / SEASONS
	var bottom := bottom_sum / SEASONS

	print("\n--- sample season final table (seed %d, run 1) ---" % SEED)
	_print_table(sample_table)

	print("\n--- average points over %d seasons (sanity: strong clubs high) ---" % SEASONS)
	_print_avg_points(pts_by_club, clubs)

	print("\n--- aggregate over %d seasons / %d games ---" % [SEASONS, tot_games])
	var ok := true
	ok = _check("goals/game", gpg, T_GOALS) and ok
	ok = _check("home-win %", home_pct, T_HOME) and ok
	ok = _check("draw %    ", draw_pct, T_DRAW) and ok
	ok = _check("away-win %", away_pct, T_AWAY) and ok
	ok = _check("champion pts", champ, T_CHAMP) and ok
	ok = _check("bottom pts  ", bottom, T_BOTTOM) and ok
	print("\n%s" % ("ALL PASS" if ok else "FAIL — tune BASE/SCALE in MatchEngine.gd"))
	return ok


func _premier_clubs() -> Array:
	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	if f == null:
		push_error("game_db.json missing (copyright DB not present locally?)")
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return []
	var out: Array = []
	for c in parsed.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			out.append(c)
	return out


func _check(label: String, value: float, window: Array) -> bool:
	var pass_: bool = value >= window[0] and value <= window[1]
	print("  [%s] %s = %.3f   (target %.2f-%.2f)" % [
		"PASS" if pass_ else "FAIL", label, value, window[0], window[1]])
	return pass_


func _print_ratings(clubs: Array) -> void:
	var rows: Array = []
	for c in clubs:
		rows.append(MatchEngine.team_ratings(c))
	rows.sort_custom(func(a, b): return (a["att"] + a["def"] + a["gk"]) > (b["att"] + b["def"] + b["gk"]))
	print("\n--- team ratings (att / def / gk), strongest first ---")
	for r in rows:
		print("  %-22s ATT %5.1f  DEF %5.1f  GK %4.0f" % [r["name"], r["att"], r["def"], r["gk"]])


func _print_table(table: Array) -> void:
	print("  %-3s %-22s %3s %3s %3s %3s %4s %4s %4s %4s" % [
		"#", "Club", "P", "W", "D", "L", "GF", "GA", "GD", "Pts"])
	var pos := 1
	for r in table:
		print("  %-3d %-22s %3d %3d %3d %3d %4d %4d %+4d %4d" % [
			pos, r["name"], r["P"], r["W"], r["D"], r["L"], r["GF"], r["GA"], r["GD"], r["Pts"]])
		pos += 1


func _print_avg_points(pts_by_club: Dictionary, clubs: Array) -> void:
	var names: Dictionary = {}
	for c in clubs:
		names[int(c["id"])] = c["name"]
	var rows: Array = []
	for id in pts_by_club:
		rows.append({"name": names.get(id, "?"), "avg": pts_by_club[id] / SEASONS})
	rows.sort_custom(func(a, b): return a["avg"] > b["avg"])
	var pos := 1
	for r in rows:
		print("  %-3d %-22s %5.1f" % [pos, r["name"], r["avg"]])
		pos += 1
