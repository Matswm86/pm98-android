extends SceneTree
## Render-verify the TRANSFER MARKET (FICHAR) list with a REAL career behind it, so the
## four cells that used to be honest gaps show live values: AV (core4>>2), the star strip
## (halves = (AV+1) div 10), MO (displayed morale), YEARS | LEFT (the term FUN_00576cd0
## rolled) and the nationality flag. Eyeball against
## screenshots/original-walkthrough-2026-07-02/097_164707.png.
##   PM98_SHOT_DIR=out godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_transfer_market_verify.gd

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

	var f := FileAccess.open("res://data/game_db.json", FileAccess.READ)
	assert(f != null, "game_db.json missing")
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var leagues: Array = db.get("leagues", [])
	var prem: Array = []
	var league: Dictionary = {}
	for lg in leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	for c in db.get("clubs", []):
		if c.get("leagueId") == "eng_prem":
			prem.append(c)
	assert(prem.size() == 20 and not league.is_empty(), "expected 20 Premier clubs")
	var mine: Dictionary = prem[0]
	for c in prem:
		if str(c.get("name", "")).to_lower().contains("manchester utd"):
			mine = c
			break

	var career := Career.create(mine, league, prem, leagues)
	var rows := career.market()
	var real := 0
	for r in rows:
		if int(r.get("mo", -1)) > 0 and int(r.get("left", 0)) > 0 and int(r.get("av", 0)) > 0:
			real += 1
	print("market rows: %d, with live AV+MO+LEFT: %d" % [rows.size(), real])
	assert(real > 0, "no market row carried the previously-gapped cells")

	var scr: TransferScreen = load("res://scenes/TransferScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(rows, str(mine.get("name", "?")), "mwm", "1997-98", career.cash, "", 3, 3)
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join("transfer_market_live.png"))
	print("SHOT transfer_market_live.png")
	quit(0)
