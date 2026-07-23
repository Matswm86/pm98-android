extends SceneTree
## Render-verify the FICHA RENEW OFFER panel with the BINARY-EXACT steppers
## (docs/re/offer_record_re.md): the YEARLY WAGE cell must open on the player's exact
## table wage and move in the engine's own £5,000/£10,000/£25,000 rungs.
##   PM98_SHOT_DIR=out godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_renew_offer_verify.gd

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
	var db: Dictionary = JSON.parse_string(f.get_as_text())
	var club := {}
	for c in db.get("clubs", []):
		if str(c.get("name", "")).to_lower().contains("manchester utd"):
			club = c
			break
	assert(not club.is_empty(), "Man Utd not found")
	var player: Dictionary = (club["players"] as Array)[0]

	var scr: PlayerInfoScreen = load("res://scenes/PlayerInfoScreen.gd").new()
	get_root().add_child(scr)
	scr.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)
	for _i in 3:
		await process_frame
	scr.setup(player, club, 1, true, false)
	await process_frame
	var band := TransferMarket.stature_of(club.get("players", []), 1)
	var weekly := Contract.current_weekly(player, band)
	scr.begin_renew(weekly, Contract.demanded_weekly(player, band),
		maxi(int(player.get("contract_term", 2)), 1))
	await process_frame
	var seeded: int = scr._offer_yearly
	print("seeded yearly £%d (table yearly £%d)" % [seeded, Contract.current_yearly(player, band)])
	assert(seeded == Contract.current_yearly(player, band), "offer must open on the table yearly")
	# three ► presses, the engine ladder
	for _k in 3:
		scr._offer_yearly = OfferRecord.step_up(scr._offer_yearly)
	print("after 3 up: £%d (expected +3 rungs from £%d)" % [scr._offer_yearly, seeded])
	scr.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(dir.path_join("renew_offer_live.png"))
	print("SHOT renew_offer_live.png")
	quit(0)
