extends SceneTree
## Headless wiring test for the in-match "Do you want to leave the championship ?"
## confirm modal (LeaveConfirm): confirms MSG is the exact witnessed string, the
## PMAlert-derived _tex/_box/_yes/_no lay out with positive size inside the 640x480
## canvas after _ready runs, _hit() resolves the yes/no cell centres to their ids and
## an outside point to "", the real _on_input press/release path fires yes_pressed for
## a click inside the YES rect, and queue_redraw() does not crash.
##   /home/mats/godot4 --headless --path app --script res://tests/test_leave_confirm.gd


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true

	# Exact source string (docs/re/matchday_flow_witness_re.md §6 witnessed message).
	ok = _assert(LeaveConfirm.MSG == "Do you want to leave the championship ?",
		"MSG exact string") and ok

	var screen: LeaveConfirm = load("res://scenes/LeaveConfirm.gd").new()
	get_root().add_child(screen)
	for _i in 3:
		await process_frame

	ok = _assert(screen._tex != null, "_tex built by _ready") and ok

	# _box/_yes/_no laid out with positive size, inside the 640x480 canvas.
	for entry in [["_box", screen._box], ["_yes", screen._yes], ["_no", screen._no]]:
		var r = entry[1]
		ok = _assert(r.size.x > 0 and r.size.y > 0, "%s has positive size" % entry[0]) and ok
		ok = _assert(r.position.x >= 0 and r.position.y >= 0
			and r.end.x <= LeaveConfirm.W and r.end.y <= LeaveConfirm.H,
			"%s inside 640x480 canvas" % entry[0]) and ok

	# _hit(): rect centres resolve to their ids, a clearly-outside point resolves to "".
	ok = _assert(screen._hit(screen._yes.get_center()) == "yes", "_hit resolves YES centre") and ok
	ok = _assert(screen._hit(screen._no.get_center()) == "no", "_hit resolves NO centre") and ok
	ok = _assert(screen._hit(Vector2(5, 5)) == "", "_hit resolves outside point to empty") and ok

	# Real press/release path (_on_input -> _to_design -> _hit) fires yes_pressed for a
	# click inside the YES rect, mirroring how the screen itself emits.
	# Booleans boxed in an Array: GDScript lambdas capture local vars by value, not
	# by reference, so a plain `var fired := false` would never observe the mutation.
	var fired := [false, false]
	screen.yes_pressed.connect(func(): fired[0] = true)
	screen.no_pressed.connect(func(): fired[1] = true)
	var s := screen._scale()
	var origin := screen._origin(s)
	var click_pos := origin + screen._yes.get_center() * s
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = click_pos
	screen._on_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = click_pos
	screen._on_input(release)
	ok = _assert(fired[0] and not fired[1],
		"yes_pressed fires on press+release inside the YES rect") and ok

	screen.queue_redraw()
	for _i in 3:
		await process_frame

	screen.queue_free()
	print("\n%s" % ("ALL PASS" if ok else "FAILURES ABOVE"))
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["PASS" if cond else "FAIL", label])
	return cond
