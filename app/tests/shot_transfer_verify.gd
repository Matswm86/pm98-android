extends SceneTree
## Owner frame 14 (2026-07-23): the PLAYER INFORMATION card in the TRANSFER-LISTED
## state -- "PLAYER PLACED ON TRANSFER MARKET" banner + red TRANSFER outline. Renders
## a Man Utd squad player both ways for a side-by-side against frames 13 (not listed)
## and 14 (listed).
##   PM98_SHOT_DIR=out godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_transfer_verify.gd

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
	for _i in 20:
		if not gamedb.clubs.is_empty():
			break
		await process_frame
	assert(not gamedb.clubs.is_empty(), "GameDB never loaded")

	var club := {}
	for c in gamedb.clubs:
		if str(c.get("name", "")).to_lower().contains("manchester utd"):
			club = c
			break
	assert(not club.is_empty(), "Man Utd not found")
	# pick a midfielder (McClair-like) for the frame-14 comparison
	var player := {}
	for p in club.get("players", []):
		if str(p.get("pos", "")) == "MF":
			player = p
			break
	if player.is_empty():
		player = (club.get("players", []) as Array)[0]

	for st in [["transfer_notlisted.png", false], ["transfer_listed.png", true]]:
		var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
		get_root().add_child(scr)
		scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
		scr.position = Vector2.ZERO
		scr.size = Vector2(640, 480)
		scr.host_dims = true            # skip the flat backdrop dim, like the SquadScreen host
		scr.setup(player, club, 1, true, bool(st[1]))
		scr.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		img.save_png(dir.path_join(str(st[0])))
		print("SHOT %s player=%s" % [st[0], player.get("name", "?")])
		scr.queue_free()
		await process_frame

	print("ALL SHOTS DONE")
	quit(0)
