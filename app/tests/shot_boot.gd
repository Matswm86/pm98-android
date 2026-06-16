extends SceneTree
## FAITHFUL repro of the real boot: instantiate Main.tscn and let it run its actual
## _ready -> _boot -> _show_title_screen path (add_child + PRESET_FULL_RECT, NO manual
## size), then capture the root viewport exactly as the device shows it. Unlike
## shot_screens.gd this sets NO size and mounts through Main, so if the title comes up
## grey on a phone it must come up grey here too. PM98_SHOT_DIR is intentionally NOT
## set, so Main._boot raises the title overlay the normal way.
##   PM98_BOOT_OUT=out.png godot --rendering-driver opengl3 --resolution WxH --path app --script res://tests/shot_boot.gd

func _initialize() -> void:
	_run()


func _run() -> void:
	var out := OS.get_environment("PM98_BOOT_OUT")
	if out == "":
		out = "/tmp/boot.png"
	var main: Control = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	# Let GameDB load its sample, _boot run, the title overlay mount, and layout settle.
	for _i in 45:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	var err := img.save_png(out)
	# Diagnostics: what is actually mounted on Main, and the title's resolved size.
	var kids := []
	var title_size := "none"
	for c in main.get_children():
		kids.append(c.name)
		if c is Control and c.get_script() != null and str(c.get_script().resource_path).ends_with("TitleScreen.gd"):
			title_size = str((c as Control).size)
	print("BOOT err=%d viewport=%dx%d title_size=%s children=%s" % [
		err, img.get_width(), img.get_height(), title_size, str(kids)])
	quit(0)
