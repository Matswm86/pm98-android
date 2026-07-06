extends SceneTree
## Frame-parity captures of the DATA BASE player card in the EXACT states the
## 2026-07-06 bio-coin walk shows, for pixel-diffing against those frames
## (tools/re/diff_dbase_card_parity.py):
##   dbcard_034.png  Schmeichel PERSONAL DATA        vs 034_schmeichel_db
##   dbcard_035.png  Schmeichel PROFILE              vs 035_tab_profile
##   dbcard_037.png  Schmeichel HONOURS              vs 037_tab_honours
##   dbcard_038.png  Schmeichel CAREER (top)         vs 038_tab_career
##   dbcard_055.png  Klinsmann PERSONAL DATA (tabs)  vs 055_klinsmann_data
##   dbcard_062.png  Blackwell CAREER (typo row)     vs 062_blackwell_career_typorow
##   dbcard_072.png  Grodas HONOURS (short line)     vs 072_grodas_honours_short
##   dbcard_046.png  Schmeichel NOTES                vs 046_notes_tab
## AGE is clock-computed in the original; the walk was captured 2026-07-06, so
## the card gets now_unix pinned to that date.
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_dbase_card.gd

const STATES := [
	["dbcard_034.png", 45, "pdata"],
	["dbcard_035.png", 45, "profile"],
	["dbcard_037.png", 45, "honours"],
	["dbcard_038.png", 45, "career"],
	["dbcard_055.png", 207, "pdata"],
	["dbcard_062.png", 264, "career"],
	["dbcard_072.png", 184, "honours"],
	["dbcard_046.png", 45, "notes"],
]


func _initialize() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTS SKIPPED: needs a rendering driver (xvfb/X11), not --headless")
		quit(1)
		return
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)

	var gamedb: Node = get_root().get_node_or_null("GameDB")
	if gamedb == null:
		gamedb = load("res://scripts/GameDB.gd").new()
		gamedb.name = "GameDB"
		get_root().add_child(gamedb)
	for _i in 10:
		if not gamedb.clubs.is_empty():
			break
		await process_frame
	assert(not gamedb.clubs.is_empty(), "GameDB never loaded")

	var by_id := {}
	var club_of := {}
	for c in gamedb.clubs:
		for p in c.get("players", []):
			by_id[int(p.get("id", -1))] = p
			club_of[int(p.get("id", -1))] = c

	var capture := Time.get_unix_time_from_datetime_dict(
		{"year": 2026, "month": 7, "day": 6, "hour": 12, "minute": 0, "second": 0})

	for st in STATES:
		var scr: DataBaseCardScreen = load("res://scenes/DataBaseCardScreen.gd").new()
		get_root().add_child(scr)
		scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scr.position = Vector2.ZERO
		scr.size = Vector2(640, 480)
		scr.now_unix = int(capture)
		scr.setup(by_id[st[1]], club_of[st[1]])
		scr._view = str(st[2])
		scr.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var err := img.save_png(dir.path_join(str(st[0])))
		print("SHOT %s err=%d %dx%d" % [st[0], err, img.get_width(), img.get_height()])
		scr.queue_free()
		await process_frame

	print("ALL SHOTS DONE")
	quit(0)
