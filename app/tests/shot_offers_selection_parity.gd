extends SceneTree
## Frame-parity captures of the OFFERS SELECTION screen in the EXACT states the
## live-witnessed originals show, for pixel-diffing (diff_offers_selection_parity.py):
##   os_03.png  fresh screen: entry cell active, no name, empty panel   vs frame 03
##   os_04.png  "mwm" typed, OFFERS plate enabled                       vs frame 04
##   os_05.png  slot 1 = mwm, the 10 witnessed offers listed            vs frame 05
##   os_06.png  Brighton & HA club-detail popup over the dimmed screen  vs frame 06
##   os_07.png  offer accepted: slot filled, panel empty, CONTINUE lit  vs frame 07
## Needs a real renderer (Xvfb / local X11):
##   DISPLAY=:1 PM98_SHOT_DIR=out ~/godot462 --rendering-driver opengl3 \
##       --path app --script res://tests/shot_offers_selection_parity.gd

const OFFERS := [
	["Brighton & HA", "Avoid Relegation"], ["Doncaster R.", "Avoid Relegation"],
	["Exeter C.", "Avoid Relegation"], ["Hartlepool U.", "Avoid Relegation"],
	["Macclesfield T.", "Avoid Relegation"], ["Torquay U.", "Avoid Relegation"],
	["Scunthorpe U.", "Mid Table"], ["Scarborough", "Mid Table"],
	["Rochdale", "Mid Table"], ["Mansfield T.", "Mid Table"],
]


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

	var scr: Control = load("res://scenes/OffersSelectionScreen.gd").new()
	get_root().add_child(scr)
	scr.position = Vector2.ZERO
	scr.size = Vector2(640, 480)

	# Frame 03: fresh screen, slot-1 entry active, nothing typed.
	scr.setup("", [])
	scr.entry_row = 0
	await _grab(dir, "os_03.png")

	# Frame 04: "mwm" typed -> the OFFERS plate switches to its enabled art.
	scr.entry_text = "mwm"
	scr.queue_redraw()
	await _grab(dir, "os_04.png")

	# Frame 05: OFFERS clicked -> slot 1 chips up with the name, panel lists the
	# 10 witnessed offers (all 3rd Div.).
	var offers: Array = []
	for o in OFFERS:
		offers.append({"team": o[0], "division": "3rd Div.", "objective": o[1],
			"division_full": "Third Division", "club_id": 107 if o[0] == "Brighton & HA" else -1,
			"stadium": "Priestfield Stadium", "capacity": "17,600 seats",
			"members": "-", "cash": "£750,000"})
	scr.setup("mwm", offers)
	await _grab(dir, "os_05.png")

	# Frame 06: row-1 arrow -> the Brighton & HA club-detail popup, screen dimmed.
	scr.show_popup(0)
	await _grab(dir, "os_06.png")

	# Frame 07: offer accepted -> slot 1 filled, next entry row active, panel
	# empty, CONTINUE lit.
	scr.close_popup()
	scr._accept(0)
	scr.entry_row = 1
	scr.queue_redraw()
	await _grab(dir, "os_07.png")

	quit(0)


func _grab(dir: String, name: String) -> void:
	await process_frame
	await process_frame
	var img := get_root().get_texture().get_image()
	img.save_png(dir.path_join(name))
	print("SHOT %s" % dir.path_join(name))
