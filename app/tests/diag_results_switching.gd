extends SceneTree
## OWNER REPORT PROBE, 2026-08-01: "the result screen doesn't really work, can't switch
## between different competitions."
##
## Drives the REAL ResultsScreen through its own input handler — the same `_on_input` the
## game calls — and reports what each of the eight competition chips and the four division
## chips actually does. Renders each state so it can be looked at, not inferred.
##
##   PM98_SHOT_DIR=out ~/godot4 --rendering-driver opengl3 --path app \
##       --script res://tests/diag_results_switching.gd

var _ok := true


func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		gamedb = load("res://scripts/GameDB.gd").new()
		gamedb.name = "GameDB"
		get_root().add_child(gamedb)
		await process_frame

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var league := {}
	var prem: Array = []
	var clubs := {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		clubs[int(c["id"])] = c
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	# THE REAL PATH: Main passes `_pyramid_context()`, so the career simulates all four
	# divisions. Without it only the manager's own tier exists and the other three chips
	# have nothing to switch to -- which is exactly the owner's symptom, so it is worth
	# driving the real construction rather than a one-division fixture.
	var divs_ctx: Array = []
	for lg2 in leagues:
		var ids: Array = []
		for c2 in db.get("clubs", []):
			if str(c2.get("leagueId", "")) == str(lg2["id"]):
				ids.append(c2)
		divs_ctx.append({"league_id": str(lg2["id"]), "name": str(lg2["name"]),
			"tier": int(lg2.get("tier", 0)), "clubs": ids})
	var career := Career.create(prem[0], league, prem, leagues,
		{"divisions": divs_ctx, "seeds": {}})
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for _w in 10:
		career.advance_week(rng, clubs)

	var scr: ResultsScreen = load("res://scenes/ResultsScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	await process_frame

	# Exactly what Main._show_results_screen builds.
	var divs: Dictionary = {}
	for t in [1, 2, 3, 4]:
		if not career.has_division(t):
			continue
		divs[t] = {"name": career.league_name_for(t), "fixtures": career.fixtures_for(t),
			"scores": career.scores_for(t), "names": career.names_for(t)}
	print("divisions the career simulates: %s" % str(divs.keys()))
	scr.setup({}, career.league_name, career.season, career.fixtures, career.results,
		career.week, career.club_id, career.club_names, career.round_scores, divs,
		career.tier)
	await process_frame

	# --- the eight COMPETITION chips on the right rail --------------------------
	var fired: Array = []
	scr.competition_selected.connect(func(k: String) -> void: fired.append(k))
	for chip in ResultsScreen.CHIP_TOP:
		var y: int = int(ResultsScreen.CHIP_TOP[chip]) + ResultsScreen.CHIP_H / 2
		_tap(scr, Vector2(ResultsScreen.CHIP_X + ResultsScreen.CHIP_W / 2.0, y))
		await process_frame
	print("competition chips that emitted: %s" % str(fired))
	_ck(fired.size() == (ResultsScreen.CHIP_TOP as Dictionary).size(),
		"all %d competition chips are live" % (ResultsScreen.CHIP_TOP as Dictionary).size())

	# --- the four DIVISION chips along the bottom -------------------------------
	var seen: Array = []
	for dc in ResultsScreen.DIV_CHIPS:
		var x: float = float(dc[1]) + ResultsScreen.DIV_CHIP_W / 2.0
		var y2: float = ResultsScreen.DIV_CHIP_Y + ResultsScreen.DIV_CHIP_H / 2.0
		_tap(scr, Vector2(x, y2))
		await process_frame
		await process_frame
		seen.append(scr._tier)
		var img := get_root().get_texture().get_image()
		img.save_png("%s/results_div%d.png" % [dir, int(dc[0])])
	print("division shown after each chip tap: %s" % str(seen))
	var want: Array = []
	for dc2 in ResultsScreen.DIV_CHIPS:
		want.append(int(dc2[0]) if divs.has(int(dc2[0])) else -1)
	print("expected (only divisions the career simulates are live): %s" % str(want))
	var good := true
	for i in range(seen.size()):
		if int(want[i]) > 0 and int(seen[i]) != int(want[i]):
			good = false
	_ck(good, "each live division chip switches the table to its own division")

	print("\n%s" % ("RESULTS SWITCHING CONFIRMED" if _ok else "RESULTS SWITCHING BROKEN"))
	quit(0 if _ok else 1)


func _ck(cond: bool, label: String) -> void:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	_ok = _ok and cond


func _tap(scr: ResultsScreen, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		scr._on_input(e)
