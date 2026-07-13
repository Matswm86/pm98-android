extends Control
class_name OptionsPanel
## The original OPTIONS panel (hub top-edge dropdown -> headphones icon).
## Chrome = the REAL modal cut live from MANAGER.EXE 2026-07-12
## (screenshots/wine-captures-2026-07-12/dropdown_options_panel.png, box at
## (136,124) 367x220; build: tools/re/build_dropdown_from_frames.py): MUSIC and
## SOUND FX rows (volume gradient + X-box + OFF label) and TRANSITIONS ON/OFF
## X-boxes, red OK. Semantics pinned by the capture's known MANAGER.INI state
## (MUSIC: OFF / SOUND: OFF / TRANSITIONS: ON): an X in a slider-row box means
## that channel is OFF; the X in ON/OFF picks the transitions mode.
##
## Baked state = channels OFF, transitions ON, volumes 100. Live deltas redraw:
## the four X-boxes (box_checked/box_empty frame patches) and the volume
## truncation. Honest gap: a sub-100 volume render is unwitnessed — the
## gradient is truncated from the right with the trough navy (inferred).

signal closed

const W := 640
const H := 480
const BOX := Rect2(136, 124, 367, 220)
# frame-measured rects (app/data/dropdown_chrome_samples.json)
const R_MUSIC_SLIDER := Rect2(329, 195, 77, 15)
const R_SFX_SLIDER := Rect2(329, 236, 77, 15)
const R_MUSIC_BOX := Rect2(393, 207, 13, 13)
const R_SFX_BOX := Rect2(393, 248, 13, 13)
const R_TRANS_ON := Rect2(310, 287, 13, 13)
const R_TRANS_OFF := Rect2(360, 287, 13, 13)
const R_OK := Rect2(432, 320, 46, 22)      # plate around the red OK glyphs (446,328)
const C_TROUGH := Color8(0, 0, 50)          # box interior navy (frame-sampled)
const C_PRESS := Color(1, 1, 1, 0.2)

var _box: Texture2D
var _checked: Texture2D
var _empty: Texture2D
var _ok_held := false
var _drag := ""   # "music"/"sfx" while dragging a slider


func _ready() -> void:
	_box = load("res://art/screens/dropdown/options_box.png")
	_checked = load("res://art/screens/dropdown/box_checked.png")
	_empty = load("res://art/screens/dropdown/box_empty.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func _am() -> Node:
	return get_node_or_null("/root/AudioManager")


func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _slider_set(which: String, d: Vector2) -> void:
	var r := R_MUSIC_SLIDER if which == "music" else R_SFX_SLIDER
	var v := clampi(int(round((d.x - r.position.x) / r.size.x * 100.0)), 0, 100)
	var am := _am()
	if am != null:
		am.call("set_music_volume" if which == "music" else "set_sfx_volume", v)
	queue_redraw()


func _on_input(e: InputEvent) -> void:
	var d := Vector2.ZERO
	var pressed := false
	var motion := false
	if e is InputEventMouseButton:
		d = _to_design((e as InputEventMouseButton).position)
		pressed = (e as InputEventMouseButton).pressed
	elif e is InputEventScreenTouch:
		d = _to_design((e as InputEventScreenTouch).position)
		pressed = (e as InputEventScreenTouch).pressed
	elif e is InputEventMouseMotion or e is InputEventScreenDrag:
		d = _to_design(e.position)
		motion = true
	else:
		return
	var am := _am()
	if motion:
		if _drag != "":
			_slider_set(_drag, d)
		return
	if pressed:
		_ok_held = R_OK.has_point(d)
		if R_MUSIC_SLIDER.has_point(d):
			_drag = "music"
			_slider_set("music", d)
		elif R_SFX_SLIDER.has_point(d):
			_drag = "sfx"
			_slider_set("sfx", d)
		queue_redraw()
		return
	# release
	var was_drag := _drag
	_drag = ""
	if was_drag != "":
		queue_redraw()
		return
	if am != null:
		if R_MUSIC_BOX.has_point(d):
			am.call("set_music_enabled", not bool(am.get("music_enabled")))
		elif R_SFX_BOX.has_point(d):
			am.call("set_sfx_enabled", not bool(am.get("sfx_enabled")))
		elif R_TRANS_ON.has_point(d):
			am.call("set_transitions", true)
		elif R_TRANS_OFF.has_point(d):
			am.call("set_transitions", false)
	if R_OK.has_point(d) and _ok_held:
		if am != null:
			am.call("ui_select")
		closed.emit()
		return
	_ok_held = false
	queue_redraw()


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _box != null:
		draw_texture(_box, BOX.position)
	var am := _am()
	var music_on: bool = am != null and bool(am.get("music_enabled"))
	var sfx_on: bool = am != null and bool(am.get("sfx_enabled"))
	var trans_on: bool = am == null or bool(am.get("transitions_enabled"))
	var mv: int = int(am.get("music_volume")) if am != null else 100
	var sv: int = int(am.get("sfx_volume")) if am != null else 100
	# volume truncation (baked = full): cover the gradient right of the level
	for pair in [[R_MUSIC_SLIDER, mv], [R_SFX_SLIDER, sv]]:
		var r: Rect2 = pair[0]
		var v: int = pair[1]
		if v < 100:
			var lx := r.position.x + r.size.x * v / 100.0
			draw_rect(Rect2(lx, r.position.y, r.end.x - lx, r.size.y), C_TROUGH, true)
	# X-boxes: baked = channels OFF (checked) + transitions ON (checked)
	for trio in [[R_MUSIC_BOX, not music_on], [R_SFX_BOX, not sfx_on],
			[R_TRANS_ON, trans_on], [R_TRANS_OFF, not trans_on]]:
		var tex := _checked if bool(trio[1]) else _empty
		if tex != null:
			draw_texture(tex, (trio[0] as Rect2).position)
	if _ok_held:
		draw_rect(R_OK, C_PRESS, true)
