extends SceneTree
## Render the FINES (MULTAS) card so it can be LOOKED AT, not just asserted.
##
## There is no captured frame of this card in the corpus (the reference careers never
## triggered it), so this is not a parity gate -- it is the "run the real app and look at
## the render" step the port's standard requires before a screen is called done.
##
##   PM98_SHOT_DIR=out ~/godot4 --rendering-driver opengl3 --path app \
##       --script res://tests/shot_fines.gd

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

	var bare := func(_cat: String, _key: int) -> int:
		return 0
	var one := func(_cat: String, _key: int) -> int:
		return 1

	var cases := {
		"fines_premier_all_five": Fines.for_match("league", "eng_prem", bare),
		"fines_facup_floodlights": Fines.for_match("fa_cup", "eng_prem", bare),
		"fines_premier_one": Fines.for_match("league", "eng_prem", one),
	}
	for name in cases:
		var scr: FinesScreen = load("res://scenes/FinesScreen.gd").new()
		scr.set_anchors_preset(Control.PRESET_FULL_RECT)
		get_root().add_child(scr)
		await process_frame
		scr.setup(cases[name])
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		img.save_png("%s/%s.png" % [dir, name])
		print("  wrote %s/%s.png  (%d rows)" % [dir, name, (cases[name] as Array).size()])
		scr.queue_free()
		await process_frame
	quit(0)
