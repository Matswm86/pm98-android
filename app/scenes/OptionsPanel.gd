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
##
## DECLARED DEVIATION (2026-07-26): this modal now carries ONE row the original does
## not — THREE UP FRONT, the port-side switch for the MANAGER_HACK.EXE cheat
## (docs/re/hack_three_forwards.md). It is drawn in the box's empty bottom-left band
## (R_CHEAT_BAND), left of the OK plate, in the game's own proman font and the modal's
## own frame-sampled label ink. `tools/re/diff_options_parity.py` is the gate: it proves
## the rest of the modal is still 0 px against the MANAGER.EXE capture, that the band
## overlaps none of the original's controls, and that the original draws nothing there.
## No other screen in this port carries invented pixels.

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
# THREE UP FRONT — the ONLY row on this modal that is NOT in the original. The port-side
# switch for the MANAGER_HACK.EXE cheat (docs/re/hack_three_forwards.md), placed in the
# box's empty bottom-left band (design y318..344, left of the OK plate at x432) so it
# overdraws nothing the frame cut carries. Same ON/OFF X-box idiom as TRANSITIONS.
# Its pixels are declared, not hidden: `tools/re/diff_options_parity.py` excludes exactly
# this band and asserts the REST of the modal is still 0 px vs the MANAGER.EXE capture.
const R_CHEAT_ON := Rect2(310, 322, 13, 13)
const R_CHEAT_OFF := Rect2(360, 322, 13, 13)
const R_CHEAT_BAND := Rect2(146, 318, 280, 22)   # what the parity diff excludes
const LABEL_END_X := 266.0                  # every baked label's ink ends here (measured)
const C_LABEL := Color8(255, 223, 0)        # the modal's own label ink (frame-sampled)
const C_TROUGH := Color8(0, 0, 50)          # box interior navy (frame-sampled)
const C_PRESS := Color(1, 1, 1, 0.2)

var _box: Texture2D
var _checked: Texture2D
var _empty: Texture2D
var _ok_held := false
var _drag := ""   # "music"/"sfx" while dragging a slider
## Natural forwards in the XI the career would field this week (-1 = no career
## mounted). Drawn beside the cheat row when the cheat is ON, so the THREE UP
## FRONT trigger's armed state is visible in-game (Mats QA 2026-07-27): >= 3 FW
## = armed. Set by Main._show_audio_options; stays inside R_CHEAT_BAND.
var xi_fw := -1


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
		elif R_CHEAT_ON.has_point(d):
			am.call("set_three_up_front", true, true)
		elif R_CHEAT_OFF.has_point(d):
			am.call("set_three_up_front", false, true)
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
	var cheat_on: bool = am != null and bool(am.get("cheat_three_up_front"))
	for trio in [[R_MUSIC_BOX, not music_on], [R_SFX_BOX, not sfx_on],
			[R_TRANS_ON, trans_on], [R_TRANS_OFF, not trans_on],
			[R_CHEAT_ON, cheat_on], [R_CHEAT_OFF, not cheat_on]]:
		var tex := _checked if bool(trio[1]) else _empty
		if tex != null:
			draw_texture(tex, (trio[0] as Rect2).position)
	# THREE UP FRONT caption row — port-only, drawn in the game's own proman font and the
	# modal's own frame-sampled label ink, inside R_CHEAT_BAND.
	# Geometry copied from the modal's own three rows rather than invented: all three
	# baked labels are RIGHT-aligned with their ink ending at design x=266 (measured on
	# options_box.png), and the ON/OFF captions are white, not label-gold. The captions sit
	# LEFT of the boxes here because the original's place for them — under the boxes —
	# falls outside the box on this row.
	var f := PMChrome.font("10")
	PMChrome.text(self, f, LABEL_END_X, 327, "THREE UP FRONT", C_LABEL, 10, 2)
	PMChrome.text(self, f, R_CHEAT_ON.position.x - 3, 327, "ON", Color.WHITE, 10, 2)
	PMChrome.text(self, f, R_CHEAT_OFF.position.x - 3, 327, "OFF", Color.WHITE, 10, 2)
	# the arming readout: this week's XI natural-FW count (>= 3 = the forwards
	# trigger is armed). White = armed, the label gold = not yet — both are the
	# row's own inks. Only with the cheat ON and a career mounted.
	if cheat_on and xi_fw >= 0:
		PMChrome.text(self, f, R_CHEAT_OFF.end.x + 8, 327, "%d FW" % xi_fw,
			Color.WHITE if xi_fw >= 3 else C_LABEL, 10)
	if _ok_held:
		draw_rect(R_OK, C_PRESS, true)
