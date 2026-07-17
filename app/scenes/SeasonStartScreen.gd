extends Control
class_name SeasonStartScreen
## PM98 START OF SEASON (charter #4, audit C1 #8): the TEAM | MANAGER | OBJECTIVE
## division sheet shown once the season proper begins, frame-baked from the
## witnessed originals (parity-run orig/71, PREMIER 20 rows; promanager 12, 3RD
## DIVISION 24 rows; EXE 0x25546c). Chrome = the real PREMIER frame with the
## division-name band + all row texts blanked; 24-club divisions blit the
## 24-row box cut from the 3RD DIV frame. The managed club's row blits the
## witnessed black user-row style. Division tabs switch the sheet: entrants of
## other divisions render from GameDB + the transcription manager table +
## Career.objective_for (the app's own board rule -- the original's assignment
## rule is un-RE'd; divergence documented in APP_VS_SPEC_AUDIT). Only
## PREMIER-hot + 3RD-hot tab chips are witnessed; other hot tabs reuse the
## chip art with the label drawn live (approximation, flagged). CONTINUE emits.

signal continue_pressed

const W := 640
const H := 480

const C_TEAM := Color8(255, 255, 255)
const C_MGR := Color8(200, 220, 240)
const C_OBJ := Color8(60, 80, 100)
const C_USER_INK := Color8(166, 202, 240)
const C_TAB_HOT := Color8(255, 255, 0)
const C_TAB_COLD := Color8(180, 200, 220)

const BTN_CONTINUE := Rect2(513, 438, 116, 30)
const TITLE_CENTER := 263
const TEAM_X := 59
const MGR_CENTER := 271
const OBJ_CENTER := 409
const PITCH := 16
const BAND_H := 12
const ROW20_Y0 := 106
const ROW24_Y0 := 86
const TITLE20_BASE := 86
const TITLE24_BASE := 66
const BOX24_POS := Vector2(44, 52)
const TABS := [Rect2(513, 253, 111, 25), Rect2(513, 283, 111, 25),
	Rect2(513, 313, 111, 25), Rect2(513, 343, 111, 25)]
const TAB_LABELS := ["PREMIER", "1ST DIVISION", "2ND DIVISION", "3RD DIVISION"]

var _chrome: Texture2D
var _box24: Texture2D
var _row_user: Texture2D
var _tab_hot: Texture2D
var _tab_cold: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font

## per division index: {title, rows: [[team, manager, objective, is_user], ...]}
var _divisions: Array = []
var _tab := 0
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/seasonflow/season.png")
	_box24 = load("res://art/screens/seasonflow/season_box24.png")
	_row_user = load("res://art/screens/seasonflow/season_row_user.png")
	_tab_hot = load("res://art/screens/seasonflow/season_tab_hot.png")
	_tab_cold = load("res://art/screens/seasonflow/season_tab_cold.png")
	_f14 = PMChrome.font("14")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## divisions: Array of {title: String, rows: Array of [team, manager, objective,
## is_user: bool]}; start_tab = the managed club's division index.
func setup(divisions: Array, start_tab: int) -> void:
	_divisions = divisions
	_tab = clampi(start_tab, 0, maxi(divisions.size() - 1, 0))
	queue_redraw()


func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _target_at(d: Vector2) -> String:
	if BTN_CONTINUE.has_point(d):
		return "continue"
	for i in mini(TABS.size(), _divisions.size()):
		if (TABS[i] as Rect2).has_point(d):
			return "tab:%d" % i
	return ""


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _target_at(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "" or was != _target_at(d):
		return
	if was == "continue":
		continue_pressed.emit()
	elif was.begins_with("tab:"):
		_tab = int(was.substr(4))
		queue_redraw()


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	if _divisions.is_empty():
		return
	var div: Dictionary = _divisions[_tab]
	var rows: Array = div.get("rows", [])
	var big := rows.size() > 20
	var y0 := ROW20_Y0
	var title_base := TITLE20_BASE
	if big and _box24 != null:
		draw_texture(_box24, BOX24_POS)
		y0 = ROW24_Y0
		title_base = TITLE24_BASE
	_txt_center(_f14, TITLE_CENTER, title_base, str(div.get("title", "")).to_upper(),
		Color8(255, 255, 255), 15)
	for i in mini(rows.size(), 24 if big else 20):
		var ry := y0 + i * PITCH
		var user := bool(rows[i][3])
		if user and _row_user != null:
			draw_texture(_row_user, Vector2(44, ry))
		var team_ink := C_USER_INK if user else C_TEAM
		var mgr_ink := C_USER_INK if user else C_MGR
		var obj_ink := C_USER_INK if user else C_OBJ
		var base := ry + 10
		_txt(_f12, TEAM_X, base, PMChrome.title_case_name(str(rows[i][0])), team_ink, 13)
		if str(rows[i][1]) != "":
			_txt_center(_f12, MGR_CENTER, base, PMChrome.title_case_name(str(rows[i][1])), mgr_ink, 13)
		_txt_center(_f12, OBJ_CENTER, base, str(rows[i][2]), obj_ink, 13)
	# tabs: chip art per selected state + live labels (PREMIER-hot is the baked
	# default; any other arrangement repaints all four chips)
	if _tab != 0 and _tab_hot != null and _tab_cold != null:
		for i in TABS.size():
			var r: Rect2 = TABS[i]
			draw_texture_rect(_tab_hot if i == _tab else _tab_cold, r, false)
			_txt_center(_f10, int(r.position.x + r.size.x * 0.5),
				int(r.position.y + 17), TAB_LABELS[i],
				C_TAB_HOT if i == _tab else C_TAB_COLD, 10)
	if _press == "continue":
		draw_rect(BTN_CONTINUE, Color(1, 1, 1, 0.2), true)


func _txt(f: Font, x: int, baseline: int, t: String, col: Color, sz: int) -> void:
	if f != null and t != "":
		draw_string(f, Vector2(x, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _txt_center(f: Font, cx: int, baseline: int, t: String, col: Color, sz: int) -> void:
	if f == null or t == "":
		return
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(cx - w * 0.5, baseline), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
