extends SceneTree
## Minimal REAL-render capture of the original-art screens — one PNG each, then quit.
## Deliberately tiny and Main-scene-free (no career, no season sim) so it cannot hang
## the screenshot CI the way the full devshot walk can. Renders each screen's own
## background + chrome through the actual Godot renderer (Xvfb + software GL in CI), so
## the PNGs are ground-truth device-equivalent captures, not Python mirror renders.
##   PM98_SHOT_DIR=out godot --rendering-driver opengl3 --path app --script res://tests/shot_screens.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	# [scene script, png name]; both use the bezel + full-screen bg draw pattern, so a
	# grey result on either tells us the art-screen render path itself is broken.
	var screens := [
		["res://scenes/TitleScreen.gd", "title.png"],
		["res://scenes/MenuScreen.gd", "menu.png"],
		["res://scenes/SquadScreen.gd", "squad_demo.png"],
		["res://scenes/LineupScreen.gd", "lineup_demo.png"],
	]
	var club := _demo_club()
	var tactics := Tactics.auto_pick(club)
	# Render at the game's native 640x480 so each screen draws at scale 1, origin 0 (full,
	# centred, uncut). Pinning the window + node to 640x480 avoids the FULL_RECT-vs-window
	# race that drew screens offset/zoomed when sized to the OS window.
	get_root().size = Vector2i(640, 480)
	for s in screens:
		var node: Control = load(s[0]).new()
		get_root().add_child(node)
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 0.0
		node.anchor_bottom = 0.0
		node.position = Vector2.ZERO
		node.size = Vector2(640, 480)
		if node.has_method("setup") and s[1] == "menu.png":
			node.setup("SAMPLE FC", "Premier League", "1997-98", 1_000_000, "1st", 38)
		elif s[1] == "squad_demo.png":
			node.setup(club, "M. MJATVEDT", "1,000,000", false, "1997-98", 1)
		elif s[1] == "lineup_demo.png":
			node.setup(club, tactics, "M. MJATVEDT", "Premier League", "1997-98", 1)
		for _i in 14:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := get_root().get_texture().get_image()
		var err := img.save_png(dir.path_join(s[1]))
		print("SHOT %s err=%d %dx%d" % [s[1], err, img.get_width(), img.get_height()])
		node.queue_free()
		for _i in 3:
			await process_frame
	print("SHOTS DONE")
	quit(0)


## A synthetic 16-man roster whose posFine codes span the GK/DF/MF/FW role bands, so
## the SQUAD POS column and LINE-UP ROL column render the full CAMROL icon set (verify
## the role-icon wiring without booting a real career / GameDB).
func _demo_club() -> Dictionary:
	const NAMES := ["FLOWERS", "FETTIS", "ADAMS", "KEOWN", "DIXON", "BOULD", "WINTERBURN",
		"VIEIRA", "PETIT", "PARLOUR", "GRIMANDI", "PLATT", "WRIGHT", "OVERMARS",
		"ANELKA", "BERGKAMP"]
	# [posFine, broad pos, isGK]
	const ROLES := [[1, "GK", true], [1, "GK", true],
		[2, "DF", false], [3, "DF", false], [4, "DF", false], [5, "DF", false], [6, "DF", false],
		[7, "MF", false], [10, "MF", false], [11, "MF", false], [15, "MF", false], [8, "MF", false],
		[9, "FW", false], [12, "FW", false], [14, "FW", false], [17, "FW", false]]
	var players: Array = []
	for i in ROLES.size():
		var r: Array = ROLES[i]
		var base := 80 - i * 2
		players.append({
			"id": i + 1, "name": NAMES[i], "isGK": bool(r[2]),
			"pos": String(r[1]), "posFine": int(r[0]), "age": 20 + (i % 12),
			"attrs": {"EN": base, "VE": base - 2, "RE": base - 4, "AG": base - 1,
				"CA": base - 3, "TI": base - 5, "RM": base, "RG": base - 6,
				"PA": base - 2, "PO": (78 if r[2] else 12)},
		})
	return {"id": 1, "name": "ARSENAL", "players": players}
