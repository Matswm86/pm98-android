extends SceneTree
## Render-verify ONE populated INJURIES row against wine witness
## `screenshots/wine-captures-2026-07-18-goalscorers/83_injuries_populated.png`:
## Bolton's Branagan, pulled hamstring, Week 3, H NO, PRICE £4,500, INSUR. NO,
## COST £4,500 — the row the insurance-economy port has to reproduce.
## The companion diff is `tools/re/diff_injuries_row_parity.py`.
##   PM98_SHOT_DIR=out godot4 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_injuries_row_verify.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	# The witness squad: only the keeper is hurt, and he is uninsured.
	# type 4 = pulled hamstring, 3 weeks total with 3 still to run.
	var club := {"id": 59, "name": "Bolton W", "players": [
		{"id": 1, "name": "BRANAGAN", "pos": "GK", "isGK": true,
			"injury_type": 4, "injured_weeks": 3, "injury_weeks_total": 3},
	]}

	var scr: InjuriesScreen = load("res://scenes/InjuriesScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(club, [], {"mode": "manager", "top": "mwm", "bottom": "Bolton W", "club_id": 59})
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("injuries_row_live.png"))
	print("SHOT injuries_row_live.png")

	# ...and the INSURED row, against the second witness that carries one:
	# wine-captures-2026-07-24-cadence-season-store/07_injuries_row_insured_giggs.png --
	# Giggs on GROUP 1 with a 7-week dislocated wrist (type 6), whose INSUR. cell reads
	# [document icon] 1  0% and whose COST is the full PRICE (group 1 pays 0 %).
	# He is a MIDFIELDER, so the row lands in the MID section, not GOAL.
	var club2 := {"id": 40, "name": "Manchester Utd.", "players": [
		{"id": 2, "name": "GIGGS", "pos": "MF", "isGK": false, "insurance_group": 1,
			"injury_type": 6, "injured_weeks": 7, "injury_weeks_total": 7},
	]}
	scr.setup(club2, [], {"mode": "manager", "top": "mats", "bottom": "Manchester Utd.",
		"club_id": 40})
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("injuries_row_insured.png"))
	print("SHOT injuries_row_insured.png")
	quit(0)
