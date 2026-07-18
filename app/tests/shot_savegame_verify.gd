extends SceneTree
## Render-verify the SAVE GAME dialog card vs the wine witnesses (2026-07-18):
##   fresh -> 51_savegame (all 10 slots empty)
##   armed -> 52_slot1    (first slot tapped: whole row black)
##   typed -> 53_slot1_typed ("wk3" white centred in the GAME cell)
## Only the card rect (140,102)-(500,378) is compared — the hub beneath is the
## live career's (and its stadium animates even in the witnesses).
## DISPLAY=:1 ~/godot462 --path app -s tests/shot_savegame_verify.gd
func _initialize() -> void:
	_run()


func _run() -> void:
	var dir := OS.get_environment("PM98_SHOT_DIR")
	if dir == "":
		dir = "/tmp"
	get_root().size = Vector2i(640, 480)
	var dlg: SaveGameDialog = load("res://scenes/SaveGameDialog.gd").new()
	dlg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(dlg)
	await process_frame          # _ready (LineEdit creation) lands first
	dlg.setup([], "mwm")
	await _shot(dir, "shot_sg_fresh.png")

	dlg._armed = 0
	dlg._edit.text = ""
	dlg._edit.visible = true
	dlg._reposition_edit()
	dlg.queue_redraw()
	await _shot(dir, "shot_sg_armed.png")

	dlg._edit.text = "wk3"
	dlg.queue_redraw()
	await _shot(dir, "shot_sg_typed.png")

	print("SAVE GAME verify shots -> %s" % dir)
	quit(0)


func _shot(dir: String, name: String) -> void:
	for _i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/%s" % [dir, name])
