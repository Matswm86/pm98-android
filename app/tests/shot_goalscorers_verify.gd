extends SceneTree
## Render-verify GOAL SCORERS vs the ORIGINAL witness frames (2026-07-18 run):
##   empty    -> walkthrough 047_154510 (preseason, no rounds played)
##   populated-> wine 18_goalscorers (WEEKS 2 list, 14 real rows)
##   compare  -> wine 22/23 (Heskey white slot + the x67..73 y299..300 graph mark)
##   popup    -> wine 27 (Stuart Edward RIPLEY goal log)
## The barra is live PMChrome (different career fields than the frames) — the diff
## harness masks it; everything below y=64 must land on the original pixels.
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_goalscorers_verify.gd
func _initialize() -> void:
	_run()
func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	await process_frame
	var scr: GoalScorersScreen = load("res://scenes/GoalScorersScreen.gd").new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(scr)
	get_root().size = Vector2i(640, 480)

	# Frame-18's exact list (mwm / Bolton W, header Week 3, WEEKS 2).
	var names := {1: "Leicester", 2: "Manchester Utd.", 3: "Blackburn R.", 4: "West Ham Utd",
		5: "Chelsea", 6: "Coventry", 7: "Everton", 8: "Leeds Utd", 9: "Arsenal",
		10: "Sheffield W.", 11: "Derby County", 12: "Aston Villa", 99: "Bolton W"}
	var rows := [
		{"name": "Heskey", "club_id": 1, "goals": 2, "legal": "Emile HESKEY"},
		{"name": "Sheringham", "club_id": 2, "goals": 2, "legal": "Edward SHERINGHAM"},
		{"name": "Ripley", "club_id": 3, "goals": 2, "legal": "Stuart Edward RIPLEY"},
		{"name": "Berkovic", "club_id": 4, "goals": 1, "legal": "Eyal BERKOVIC"},
		{"name": "Sutton", "club_id": 3, "goals": 1, "legal": "Christopher SUTTON"},
		{"name": "Clarke", "club_id": 5, "goals": 1, "legal": "Stephen CLARKE"},
		{"name": "Whelan", "club_id": 6, "goals": 1, "legal": "Noel WHELAN"},
		{"name": "Williams", "club_id": 6, "goals": 1, "legal": "Paul WILLIAMS"},
		{"name": "Ferguson", "club_id": 7, "goals": 1, "legal": "Duncan FERGUSON"},
		{"name": "Hopkin", "club_id": 8, "goals": 1, "legal": "David HOPKIN"},
		{"name": "Petit", "club_id": 9, "goals": 1, "legal": "Emmanuel PETIT"},
		{"name": "Radebe", "club_id": 8, "goals": 1, "legal": "Lucas RADEBE"},
		{"name": "Wright", "club_id": 9, "goals": 1, "legal": "Ian WRIGHT"},
		{"name": "Carbone", "club_id": 10, "goals": 1, "legal": "Benito CARBONE"},
	]
	# Heskey 2 goals in wk1 (flat run wk1->wk2, the witnessed x67..73 mark) and
	# Ripley's witnessed popup log (wk1 Blackburn-Derby '88, wk2 Villa-Blackburn '51).
	var log := {
		"Heskey|1": [{"week": 1, "minute": 12, "h": 1, "a": 11}, {"week": 1, "minute": 55, "h": 1, "a": 11}],
		"Ripley|3": [{"week": 1, "minute": 88, "h": 3, "a": 11}, {"week": 2, "minute": 51, "h": 12, "a": 3}],
	}

	# 1) empty preseason state (walkthrough 047): no rounds, no rows.
	scr.setup([], {}, names, 0, "mwm", "Bolton W", 1, "1997-98", "Week 1", 99)
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_gs_empty.png" % dir)

	# 2) populated WEEKS-2 state (frame 18).
	scr.setup(rows, log, names, 2, "mwm", "Bolton W", 1, "1997-98", "Week 3", 99)
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_gs_populated.png" % dir)

	# 3) compare confirmed (frame 23): Heskey in the white slot, mark plotted, disarmed.
	scr._slots[0] = {"name": "Heskey", "club_id": 1}
	scr.queue_redraw()
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_gs_compare.png" % dir)

	# 4) goal-log popup (frame 27, Ripley).
	scr._slots = [null, null, null]
	scr._row_tapped(2)
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/shot_gs_popup.png" % dir)

	print("GOAL SCORERS verify shots -> %s" % dir)
	quit(0)
