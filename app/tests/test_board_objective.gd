extends SceneTree
## Audit O1 — the board objective is a CATEGORY, not a position, in EVERY season.
##
## The original's START OF SEASON sheet gives every club one of five labels (Champion /
## U.E.F.A. / Promotion / Mid Table / Avoid Relegation, all four English divisions
## live-witnessed 2026-07-19 and shipped in club_economy.json). The port matched that in
## season ONE only: `_set_objective`'s fallback -- which is what every rollover uses,
## because a season-2+ board is un-witnessed and it passes an empty club -- issued its own
## prose instead ("Finish 13 or higher", "Avoid relegation" with a small r).
##
## That was not only cosmetic. No fallback string is a key of `BOARD_BAND_OF_LABEL`, so from
## season two on `expectation_band()` returned -1 for the rest of the career and the board
## review, the sack ladder and the improvement test all ran on the -1 arm.
##
## Fixed 2026-07-29 by moving Main's own position->category map into
## `Career.objective_label` and having the fallback use it. This drives Bolton W (the
## audit's own example, board label "Avoid Relegation") through four seasons.
##
##   ~/godot462 --headless --path app --script res://tests/test_board_objective.gd

func _initialize() -> void:
	var db: Dictionary = JSON.parse_string(FileAccess.open("res://data/game_db.json", FileAccess.READ).get_as_text())
	var clubs: Array = db.get("clubs", [])
	var leagues: Array = db.get("leagues", [])
	var econ: Dictionary = (JSON.parse_string(FileAccess.open(
		"res://data/club_economy.json", FileAccess.READ).get_as_text()) as Dictionary).get("clubs", {})
	for c in clubs:
		var row: Variant = econ.get(str(int(c.get("id", -1))))
		if row is Dictionary and (row as Dictionary).has("objective"):
			c["objective"] = str((row as Dictionary)["objective"])
	var by_id := {}
	for c in clubs:
		by_id[int(c["id"])] = c
	var prem := []
	var league := {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in clubs:
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	var bolton := {}
	for c in prem:
		if str(c.get("name","")).to_upper().begins_with("BOLTON"):
			bolton = c
	var career := Career.create(bolton if not bolton.is_empty() else prem[0], league, prem, leagues)
	var ok := _check(career, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for s in 3:
		while not career.season_over():
			career.advance_week(rng, by_id)
		career.advance_season(leagues, rng)
		ok = _check(career, s + 2) and ok
	print("test_board_objective: ", "ALL PASS" if ok else "FAILURES ABOVE")
	quit(0 if ok else 1)


## The board only ever states a CATEGORY, in every season, and that category must be a key
## of BOARD_BAND_OF_LABEL for the club's tier -- otherwise expectation_band() answers -1 and the
## board review, the sack ladder and the improvement test all silently take the -1 arm.
func _check(career: Career, season: int) -> bool:
	var labels: Dictionary = Career.BOARD_BAND_OF_LABEL.get(career.tier, {})
	var got := career.objective_text
	var okc := labels.has(got)
	var okb := career.expectation_band() >= 0
	print("  %s  s%d %-16s objective='%s' pos=%d band=%d"
		% ["ok  " if okc and okb else "FAIL", season, career.club_name, got,
		career.objective_pos, career.expectation_band()])
	return okc and okb
