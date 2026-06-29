extends SceneTree
## Real-render capture of the DATA BASE squad view (DataBaseScreen.gd). Uses a SYNTHETIC
## 22-man squad whose photoIds are drawn from the committed MINIFOTO bank, so the four
## GK/DF/MF/FW columns + thumbnails render without loading the full game_db. One PNG, quit.
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_database.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var node: DataBaseScreen = load("res://scenes/DataBaseScreen.gd").new()
	get_root().add_child(node)
	node.size = Vector2(640, 480)
	node.setup(_demo_club())
	node.queue_redraw()
	for _i in 8:
		await process_frame
	var headless := DisplayServer.get_name() == "headless"
	if not headless:
		await RenderingServer.frame_post_draw
	var tex := get_root().get_texture()
	var img := tex.get_image() if tex != null else null
	if img != null:
		var err := img.save_png(dir.path_join("database_demo.png"))
		print("SHOT database_demo.png err=%d %dx%d" % [err, img.get_width(), img.get_height()])
	print("DB-SHOT OK headless=%s" % headless)
	print("SHOTS DONE")
	quit(0)


## Synthetic squad: invented surnames, real position spread, photoIds taken from the baked
## res://art/faces/mini bank so the thumbnails resolve (and a couple of misses to prove the
## blank-frame fallback). Mirrors shot_screens._demo_club's no-real-data principle.
func _demo_club() -> Dictionary:
	const ROWS := [
		["ASHWORTH", "GK", 1851], ["BRENNAN", "GK", 9102], ["CARLTON", "GK", 0],
		["DALEY", "DF", 9285], ["EVERTON", "DF", 10009], ["FORDE", "DF", 10021],
		["GRANGE", "DF", 10026], ["HALLAM", "DF", 8432], ["IRVINE", "DF", 8433],
		["JARVIS", "DF", 0], ["KEMP", "MF", 9067], ["LOWRY", "MF", 9069],
		["MERTON", "MF", 9072], ["NEVILLE", "MF", 9073], ["OAKES", "MF", 9076],
		["PRYCE", "MF", 9079], ["QUINN", "MF", 9083], ["ROYLE", "MF", 0],
		["STACEY", "FW", 7930], ["TANNER", "FW", 7931], ["UNWIN", "FW", 7933],
		["VOSE", "FW", 0],
	]
	var players: Array = []
	for i in ROWS.size():
		var r: Array = ROWS[i]
		players.append({
			"id": i + 1, "name": String(r[0]), "pos": String(r[1]),
			"isGK": r[1] == "GK", "photoId": int(r[2]),
		})
	return {"id": 1, "name": "DEMO COUNTY", "players": players}
