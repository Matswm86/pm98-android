extends SceneTree
## INPUT-DRIVEN tap-through of the SQUAD MANAGEMENT -> PLAYER INFORMATION flow —
## the real Main booted the normal way, a career begun, then the squad screen
## driven by synthesized InputEventScreenTouch taps through
## Input.parse_input_event (emulate_mouse_from_touch default ON, so every tap
## also arrives as the emulated mouse twin — the device double-fire the user hit:
## a row tap opened the FICHA card and the twin release tore the stack back to
## the hub). Asserts: one row tap raises exactly ONE card and the card SURVIVES;
## card RETURN goes back to the squad, not the hub; squad RETURN exits once.
##   PM98_TAP_DIR=out/tap godot --rendering-driver opengl3 --path app \
##     --script res://tests/shot_squad_card_tapthrough.gd

var _shots := 0
var _dir := ""
var _fails := 0


func _initialize() -> void:
	_run()


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	if not cond:
		_fails += 1
	return cond


func _tap(pos: Vector2) -> void:
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.position = pos
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = pos
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	await process_frame
	await process_frame


func _shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_shots += 1
	var img := get_root().get_texture().get_image()
	var path := _dir.path_join("sqtap_%02d_%s.png" % [_shots, label])
	img.save_png(path)
	print("  SHOT %s" % path.get_file())


func _count(main: Node, type: Variant) -> int:
	var n := 0
	for c in main.get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion() and is_instance_of(c, type):
			n += 1
	return n


func _find(main: Node, type: Variant) -> Node:
	for c in main.get_children():
		if is_instance_valid(c) and not c.is_queued_for_deletion() and is_instance_of(c, type):
			return c
	return null


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("TAP-THROUGH SKIPPED: needs a rendering driver (SquadScreen row rects fill in _draw)")
		quit(1)
		return
	_dir = OS.get_environment("PM98_TAP_DIR")
	if _dir == "":
		_dir = "out/tap"
	DirAccess.make_dir_recursive_absolute(_dir)
	get_root().size = Vector2i(640, 480)

	var main: Node = load("res://scenes/Main.tscn").instantiate()
	get_root().add_child(main)
	for _i in 30:
		await process_frame

	var gamedb: Node = get_root().get_node("GameDB")
	var league: Dictionary = {}
	for lg in gamedb.leagues:
		if lg.get("id") == "eng_prem":
			league = lg
	var club: Dictionary = gamedb.clubs_in_league("eng_prem")[0]
	main._begin_career("Tap Mgr", league, club)
	for _i in 10:
		await process_frame
	_assert(main._hub != null and is_instance_valid(main._hub), "career hub up")

	# PLAYERS: mount the squad screen (the surface under test is the row tap).
	main._show_squad_screen()
	for _i in 5:
		await process_frame
	var squad: SquadScreen = _find(main, SquadScreen)
	_assert(squad != null and _count(main, SquadScreen) == 1, "one SQUAD MANAGEMENT up")
	await _shot("squad")

	# One finger tap on the first player row must raise exactly ONE card and the
	# squad must stay mounted beneath (double-fire regression: the twin release
	# hit the empty-space back_pressed and collapsed to the hub).
	_assert(squad._rows.size() > 0, "squad rows drawn")
	var r: Rect2 = squad._rows[0]["r"]
	await _tap(r.get_center())
	var card_n := _count(main, PlayerInfoScreen)
	_assert(card_n == 1, "row tap raises exactly ONE player card (no double-fire)")
	_assert(_count(main, SquadScreen) == 1, "squad survives beneath the card")
	await _shot("card")

	# The card must SURVIVE idle frames (the old bug freed it via the twin release).
	for _i in 5:
		await process_frame
	_assert(_count(main, PlayerInfoScreen) == 1, "card still up after settling")

	# Card RETURN -> back to the squad list, not the hub.
	await _tap((PlayerInfoScreen.BTN["ok"] as Rect2).get_center())
	_assert(_count(main, PlayerInfoScreen) == 0, "card RETURN dismisses the card")
	_assert(_count(main, SquadScreen) == 1, "squad still mounted after card exit")
	await _shot("back_on_squad")

	# Squad RETURN -> exits once, hub revealed.
	await _tap((SquadScreen.RETURN_BTN as Rect2).get_center())
	_assert(_count(main, SquadScreen) == 0, "squad RETURN exits")
	_assert(main._hub != null and is_instance_valid(main._hub), "hub revealed")
	await _shot("hub")

	print("\n%s" % ("SQUAD TAP-THROUGH: ALL GREEN" if _fails == 0 else "FAILURES: %d" % _fails))
	quit(0 if _fails == 0 else 1)
