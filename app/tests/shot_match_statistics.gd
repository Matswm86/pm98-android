extends SceneTree
## Render the MATCH statistics table the HALF TIME / FULL TIME board's per-team
## STATISTICS button opens, for an eyeball against the original's own frames
## (screenshots/wine-captures-2026-07-24-statistics-live/02, 03, 05, 06).
##   DISPLAY=:5 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_match_statistics.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOT SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var xi_h := _xi(1, "MANUTD")
	var xi_a := _xi(101, "CHELSEA")
	var mem := Pm98StatMatch.build_mem(xi_h, xi_a, 40, 61)
	var prng := Pm98StatMatch.Rng.new(19970803)
	var ft := Pm98StatStore.Report.new(40, 61)
	var ht := Pm98StatStore.Report.new(40, 61)
	Pm98StatMatch.simulate(mem, prng, false, false, ft, MatchSim.pid_map(xi_h, xi_a),
		Pm98StatMatch.CADENCE_MATCH, ht)

	var node: StatisticsScreen = load("res://scenes/StatisticsScreen.gd").new()
	get_root().add_child(node)
	node.position = Vector2.ZERO
	node.size = Vector2(640, 480)
	PMChrome.header_phase = "season"
	PMChrome.header_date = {"wd": "Sunday", "day": "3", "mon": "August", "year": "1997"}
	for pair in [[ft, "ft"], [ht, "ht"]]:
		var rep = pair[0]
		var rows := Pm98StatStore.match_rows(rep, 0, xi_h)
		node.setup({"id": 40, "name": "Manchester Utd.", "players": xi_h},
			{"mode": "fixture", "top": "Manchester Utd.", "bottom": "Chelsea",
				"home_id": 40, "away_id": 61},
			rows, Pm98StatStore.totals(rows))
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png("%s/match_stats_%s.png" % [dir, str(pair[1])])
		print("wrote %s/match_stats_%s.png" % [dir, str(pair[1])])
	quit(0)


func _xi(base: int, tag: String) -> Array:
	var xi: Array = []
	for i in 11:
		var a := {}
		for k in ["VE", "RE", "AG", "CA", "RM", "RG", "PA", "TI", "EN", "PO"]:
			a[k] = 55 + (i % 7)
		xi.append({"id": base + i, "name": "%s%d" % [tag, i + 1], "isGK": i == 0,
			"squadNo": i + 1, "pos": "GK" if i == 0 else "MF", "attrs": a})
	return xi
