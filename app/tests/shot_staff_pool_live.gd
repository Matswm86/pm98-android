extends SceneTree
## Render the hire overlay fed by a LIVE-generated candidate pool (the real
## Staff.generate_pool path a new career runs), proving the 2026-07-18 rebuild by eye:
## names = the game's own NOMBRES.30/APELLIDO.30 tables, wages on the witnessed anchor
## curve, list order = generation order (docs/re/staff_re.md "The real candidate pools").
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_staff_pool_live.gd

const SEED := 19980801

func _initialize() -> void:
	var dir := "res://tests/out"
	var env := OS.get_environment("PM98_SHOT_DIR")
	if env != "":
		dir = env
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var pool := Staff.generate_pool(rng, 800000, 3)
	for role in [Staff.SCOUT_ROLE, Staff.PHYSIOTHERAPIST]:
		var cands := Staff.pool_for_role(pool, role)
		for c in cands:
			print("  %s: %s %.1f £%d" % [role, c["name"], c["stars"], c["wage"]])
		await _shot(role, cands, "%s/overlay_%s_livepool.png" % [dir, str(role).to_lower()])
	quit(0)


func _shot(cat: String, cands: Array, path: String) -> void:
	var root := get_root()
	var back := ColorRect.new()
	back.color = Color(0.10, 0.12, 0.20)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.custom_minimum_size = Vector2(640, 480)
	root.add_child(back)
	var scr = load("res://scenes/StaffHireOverlay.gd").new()
	scr.custom_minimum_size = Vector2(640, 480)
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(scr)
	scr.setup(cat, {}, cands)
	root.size = Vector2i(640, 480)
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(path)
	print("wrote ", path)
	scr.queue_free()
	back.queue_free()
	await process_frame
