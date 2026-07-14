extends SceneTree
## Render the CLUB PERSONNEL hire overlay to PNGs for a by-eye parity check vs the source
## frames (docs/re/staff_re.md). Feeds the ASS. MANAGER category the walkthrough's own data
## (frame 113: A. Leigh + P. Wright + L. Malik) so the live overlay can be laid beside it, plus
## a vacant GROUNDSMAN (frame 119) to prove the empty-slot state.
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 --path app \
##     --script res://tests/shot_staff_overlay.gd

func _initialize() -> void:
	var dir := "res://tests/out"
	var env := OS.get_environment("PM98_SHOT_DIR")
	if env != "":
		dir = env
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir) if dir.begins_with("res://") else dir)
	await _shot("ASSISTANT_MANAGER",
		{"name": "A. Leigh", "stars": 4.0, "wage": 16000},
		[{"id": 1, "name": "P. Wright", "stars": 2.0, "wage": 7000},
		 {"id": 2, "name": "L. Malik", "stars": 2.5, "wage": 9000}],
		"%s/overlay_assman.png" % dir)
	await _shot("GROUNDSMAN", {},
		[{"id": 3, "name": "R. Dongle", "stars": 3.0, "wage": 2000},
		 {"id": 4, "name": "J. Davies", "stars": 1.0, "wage": 1000},
		 {"id": 5, "name": "G. Debnam", "stars": 4.5, "wage": 4000}],
		"%s/overlay_groundsman.png" % dir)
	# TRAINERS (frame 100): the walkthrough's own coaches + DRIBBLING-selected pool, so the
	# live overlay can be laid beside frame 100 (A. Padmore/D. Gledhill/S. Merrick hired; the
	# AVAILABLE pool P. Wren / L. Gledhill; HEADING/TACKLING/SHOOTING vacant).
	await _shot_trainers(
		{"HANDLING": {"name": "A. Padmore", "stars": 3.0, "wage": 17000},
		 "PASSING": {"name": "D. Gledhill", "stars": 4.5, "wage": 34000},
		 "DRIBBLING": {"name": "S. Merrick", "stars": 5.0, "wage": 47000}},
		"DRIBBLING",
		[{"id": 10, "name": "P. Wren", "stars": 4.5, "wage": 41000},
		 {"id": 11, "name": "L. Gledhill", "stars": 1.0, "wage": 3000}],
		"%s/overlay_trainers.png" % dir)
	quit(0)


func _shot_trainers(coaches: Dictionary, skill: String, cands: Array, path: String) -> void:
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
	scr.setup("TRAINERS", {}, cands, coaches, skill)
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


func _shot(cat: String, holder: Dictionary, cands: Array, path: String) -> void:
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
	scr.setup(cat, holder, cands)
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
