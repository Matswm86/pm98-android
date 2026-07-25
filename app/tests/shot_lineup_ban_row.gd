extends SceneTree
## Render-verify the SUSPENDED LINE-UP row against the wine witness
## `out/refrun-manutd-9798/play/p0349_UNKNOWN.png` — the reference Manchester Utd.
## 1997-98 season's `2 Gary Neville [two yellow cards] 2 MATCHES` row.
##
## Reproduces the same ban count (2) so the three banner boxes — icon x174..197,
## count x199..222, unit x224..297 — must land pixel-for-pixel. The companion diff is
## `tools/re/diff_lineup_ban_parity.py`.
##   DISPLAY=:4 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##     --resolution 640x480 --path app --script res://tests/shot_lineup_ban_row.gd

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

	# A minimal squad: eleven fit men plus one serving a two-match ban, so the XI has a
	# suspended row exactly as the witness frame does.
	var players: Array = []
	for i in 12:
		var p := {"id": i + 1, "name": "Player%02d" % (i + 1),
			"pos": ("GK" if i == 0 else ("DEF" if i < 5 else ("MID" if i < 9 else "FOR"))),
			"isGK": i == 0, "fitness": 99, "morale": 92,
			"attrs": {"VE": 70, "RE": 70, "AG": 70, "CA": 70, "RM": 70, "RG": 70,
				"PA": 70, "TI": 70, "EN": 70, "PO": (80 if i == 0 else 5)}}
		if i == 1:
			p["name"] = "Banned"
			p["suspended_weeks"] = 2
		players.append(p)
	var club := {"id": 40, "name": "Manchester Utd.", "players": players}

	var t := Tactics.new()
	t.auto_pick(club)

	var scr: LineupScreen = load("res://scenes/LineupScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(club, t, "MWM", "Premier League", "1997-98", 30)
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("lineup_ban_row.png"))
	print("SHOT lineup_ban_row.png")
	quit(0)
