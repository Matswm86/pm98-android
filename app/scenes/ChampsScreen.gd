extends Control
class_name ChampsScreen
## PM98 TEAMS IN CHAMPIONSHIPS (charter #4, audit C1 #7): the season-entry sheet of
## the six competitions' entrants, frame-baked from the witnessed original
## (parity-run-2026-07-16/orig/06_champs.png == promanager 09; EXE 0x255560).
## Chrome = the real frame's pixels with ONLY the six panel bodies' text rows
## blanked (tools/re/build_seasonflow_chrome_from_frames.py); this scene redraws
## the LIVE entrants: club (white) + manager (pale, 180,200,220) per row at the
## frame-measured baselines. CONTINUE (baked art, hit-tested) emits done.

signal continue_pressed

const W := 640
const H := 480

const C_CLUB := Color8(255, 255, 255)
const C_MGR := Color8(180, 200, 220)
const BTN_CONTINUE := Rect2(508, 438, 116, 30)

# [panel key, club_x, mgr_x, [row baselines]] -- frame-measured (seasonflow json)
const PANELS := [
	["european_cup", 20, 160, [145, 158]],
	["uefa_cup", 392, 532, [132, 145, 158, 171]],
	["cup_winners_cup", 20, 160, [270]],
	["charity_shield", 392, 532, [264, 277]],
	["supercup", 20, 160, [397, 410]],
	["intercontinental", 392, 532, [397, 410]],
]

var _chrome: Texture2D
var _f10: Font
var _entries: Dictionary = {}   # key -> [[club, manager], ...]
var _press := false


func _ready() -> void:
	_chrome = load("res://art/screens/seasonflow/champs.png")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## entries: {comp key -> Array of [club_name, manager_name]} (manager "" = honest blank).
func setup(entries: Dictionary) -> void:
	_entries = entries
	queue_redraw()


func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = BTN_CONTINUE.has_point(d)
		queue_redraw()
		return
	var was := _press
	_press = false
	queue_redraw()
	if was and BTN_CONTINUE.has_point(d):
		continue_pressed.emit()


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	for p in PANELS:
		var rows: Array = _entries.get(p[0], [])
		var bases: Array = p[3]
		for i in mini(rows.size(), bases.size()):
			var club := PMChrome.title_case_name(str(rows[i][0]))
			var mgr := str(rows[i][1])
			_txt(int(p[1]), int(bases[i]), club, C_CLUB)
			if mgr != "":
				_txt(int(p[2]), int(bases[i]), PMChrome.title_case_name(mgr), C_MGR)
	if _press:
		draw_rect(BTN_CONTINUE, Color(1, 1, 1, 0.2), true)


func _txt(x: int, baseline: int, t: String, col: Color) -> void:
	if _f10 != null:
		draw_string(_f10, Vector2(x, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)
