extends SceneTree
## The measurement behind `PMChrome.is_emulated_pointer_dup`, kept as a regression.
##
## Godot's `input_devices/pointing/emulate_mouse_from_touch` (project default, and this
## project does not override it) makes ONE finger press arrive at `gui_input` TWICE: an
## emulated `InputEventMouseButton` with `device == InputEvent.DEVICE_ID_EMULATION`,
## then the real `InputEventScreenTouch`. Screens that only navigate are idempotent
## under that; screens that TOGGLE flip twice and land back where they started.
##
## That is the 2026-07-24 owner bug: the TEAM OFFER card flips its REFUSE/ACCEPT chip on
## press, so on a phone it went ACCEPT -> REFUSE inside a single tap and looked dead. The
## headless test could not see it because it sent the touch alone.
##
##   ~/godot462 --headless --path app --script res://tests/test_pointer_dup.gd

var _seen: Array = []
var _toggle := false


func _initialize() -> void:
	_run()


func _run() -> void:
	var ok := true
	var c := Control.new()
	c.size = Vector2(640, 480)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton or e is InputEventScreenTouch:
			_seen.append(e))
	get_root().add_child(c)
	await process_frame

	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = Vector2(10, 10)
	t.pressed = true
	Input.parse_input_event(t)
	await process_frame
	await process_frame

	ok = _assert(bool(ProjectSettings.get_setting(
		"input_devices/pointing/emulate_mouse_from_touch", true)),
		"emulate_mouse_from_touch is on (the project default)") and ok
	ok = _assert(_seen.size() == 2,
		"one finger press delivers TWO events (got %d)" % _seen.size()) and ok
	var dups := 0
	for e in _seen:
		if PMChrome.is_emulated_pointer_dup(e):
			dups += 1
	ok = _assert(dups == 1,
		"exactly one of the pair is the emulated duplicate (got %d)" % dups) and ok

	# and the guard is what keeps a toggle from cancelling itself
	for e in _seen:
		if PMChrome.is_emulated_pointer_dup(e):
			continue
		if e.is_pressed():
			_toggle = not _toggle
	ok = _assert(_toggle, "a guarded toggle flips ONCE per tap") and ok

	print("test_pointer_dup: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)


func _assert(cond: bool, label: String) -> bool:
	print(("  ok   " if cond else "  FAIL ") + label)
	return cond
