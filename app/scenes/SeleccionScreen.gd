extends Control
class_name SeleccionScreen
## PM98 NEW-CAREER screen (SELECCION, "ENTER YOUR NAME AND SELECT A TEAM"), rebuilt from
## the ORIGINAL game art at the coordinates reversed out of MANAGER.EXE (FUN_0055d560).
## See docs/re/seleccion_screen_re.md.
##
## The original is ONE screen: manager-name entry + club selection across the divisions,
## on FONDO0 (stadium photo) with the BARRA0 soccer-ball divider, four bottom buttons
## (RETURN / LOAD GAME / DELETE / CONTINUE). It REPLACES the old two-step Track-B
## BrowseScreen pickers (_show_career_pick_league -> _show_career_pick_club).
##
## Native 640x480; scales to fit its parent (NEAREST), letterboxed on a marble bezel.
## Interactive: cycle the division with the League plaque, tap a club to select it, type
## the manager name in the field, CONTINUE begins the career.

signal career_begun(manager_name: String, league: Dictionary, club: Dictionary)
signal back_pressed
signal load_pressed
signal delete_pressed

const W := 640
const H := 480

# Reversed widget rects (pos, size) from capstone (last push = x; pt#1 = size, pt#2 = pos).
const BARRA_Y := 0                                  # the 640x62 soccer-ball divider, top
const R_TITLE := Rect2(108, 12, 480, 27)            # "ENTER YOUR NAME AND SELECT A TEAM"
const R_PLAYER := Rect2(127, 67, 124, 25)           # PLAYER label
const R_NAME := Rect2(292, 67, 197, 25)             # manager-name input field
const R_RETURN := Rect2(25, 427, 112, 25)
const R_LOAD := Rect2(175, 427, 152, 25)
const R_DELETE := Rect2(348, 427, 112, 25)
const R_CONTINUE := Rect2(508, 427, 112, 25)
# League plaque (top-left, on the BARRA): cycles the division. Manager label sits above it.
const R_LEAGUE := Rect2(18, 40, 220, 22)
# Team grid: two columns, native 126x25 cells, first row y=104 (0x68).
const GRID_TOP := 104
const GRID_BOT := 420
const ROW_H := 26
const COL_W := 296
const COL_X := [22, 322]                            # two column left edges

# Reversed caption colours (r,g,b).
const C_TITLE := Color(1, 1, 1)
const C_GOLD := Color(1.0, 0.875, 0.0)              # PLAYER / LOAD GAME (255,223,0)
const C_YELLOW := Color(1.0, 1.0, 0.0)             # RETURN / CONTINUE
const C_RED := Color(1.0, 0.122, 0.0)              # DELETE (255,31,0)
const C_NAME := Color(1, 1, 1)
const C_DIM := Color(0.62, 0.70, 0.82)
const C_SEL := Color(1.0, 0.84, 0.22, 0.85)
const C_PRESS := Color(1.0, 1.0, 1.0, 0.20)
const C_PANEL := Color(0.04, 0.08, 0.16, 0.55)

var _bg: Texture2D
var _bezel: Texture2D
var _barra: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _name_edit: LineEdit

var _leagues: Array = []          # [{id,name,clubIds}]
var _li: int = 0                  # selected league index
var _clubs: Array = []            # clubs of the selected league (sorted)
var _sel: int = -1               # selected club index, -1 none
var _has_save: bool = false
var _press: String = ""          # held button / "club:N" / "league"


func _ready() -> void:
	_bg = load("res://art/screens/seleccion_bg.png")
	_bezel = load("res://art/screens/fondo_marble.png")
	_barra = load("res://art/screens/barra0.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Real text-entry field (the original has manager-name entry here). A LineEdit child
	# positioned in screen space over the reversed R_NAME rect; repositioned on resize.
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.max_length = 18
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_override("font", _f12)
	_name_edit.add_theme_font_size_override("font_size", 13)
	add_child(_name_edit)
	resized.connect(_reposition_name)
	gui_input.connect(_on_input)
	_reposition_name()
	queue_redraw()


## Feed the database (leagues + their clubs) and whether a save exists (LOAD/DELETE state).
func setup(leagues: Array, has_save: bool) -> void:
	_leagues = leagues
	_has_save = has_save
	_li = 0
	_sel = -1
	_load_clubs()
	queue_redraw()


func _load_clubs() -> void:
	_clubs = []
	if _li >= 0 and _li < _leagues.size():
		_clubs = GameDB.clubs_in_league(str(_leagues[_li].get("id", "")))
		_clubs.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

## Keep the LineEdit aligned with R_NAME under the current scale/letterbox.
func _reposition_name() -> void:
	if _name_edit == null:
		return
	var s := _scale()
	var o := _origin(s)
	_name_edit.position = o + R_NAME.position * s
	_name_edit.size = R_NAME.size * s


func _club_at(d: Vector2) -> int:
	for col in 2:
		var x: int = COL_X[col]
		if d.x < x or d.x > x + COL_W:
			continue
		var idx := int((d.y - GRID_TOP) / ROW_H)
		if idx < 0:
			continue
		var i := idx * 2 + col
		if i >= 0 and i < _clubs.size() and _row_y(idx) + ROW_H <= GRID_BOT:
			return i
	return -1

func _row_y(row: int) -> int:
	return GRID_TOP + row * ROW_H

## What a design-space point targets: "return"/"load"/"delete"/"continue"/"league"/"club:N"/"".
func _target_at(d: Vector2) -> String:
	if R_RETURN.has_point(d): return "return"
	if _has_save and R_LOAD.has_point(d): return "load"
	if _has_save and R_DELETE.has_point(d): return "delete"
	if _sel >= 0 and R_CONTINUE.has_point(d): return "continue"
	if R_LEAGUE.has_point(d): return "league"
	var ci := _club_at(d)
	if ci >= 0: return "club:%d" % ci
	return ""


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var tap := e is InputEventMouseButton or e is InputEventScreenTouch
	if not tap:
		return
	var pressed: bool = e.pressed
	var d := _to_design(e.position)
	if pressed:
		_press = _target_at(d)
		queue_redraw()
	else:
		var was := _press
		_press = ""
		queue_redraw()
		if was == "" or was != _target_at(d):
			return
		match was:
			"return": back_pressed.emit()
			"load": load_pressed.emit()
			"delete":
				_has_save = false
				delete_pressed.emit()
				queue_redraw()
			"continue":
				if _sel >= 0 and _sel < _clubs.size():
					var nm := _name_edit.text.strip_edges()
					career_begun.emit(nm if nm != "" else "Manager",
						_leagues[_li], _clubs[_sel])
			"league":
				_li = (_li + 1) % maxi(1, _leagues.size())
				_sel = -1
				_load_clubs()
				queue_redraw()
			_:
				if was.begins_with("club:"):
					_sel = int(was.substr(5))
					queue_redraw()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, cw := 0, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := float(x)
	if right:
		px = x - w
	elif cw > 0:
		px = x + (cw - w) * 0.5
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _btn(r: Rect2, label: String, col: Color, enabled: bool, key: String) -> void:
	var bg := Color(0.0, 0.0, 0.0, 0.55 if enabled else 0.30)
	draw_rect(r, bg, true)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color(1, 1, 1, 0.25), true)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), Color(0, 0, 0, 0.5), true)
	if key != "" and _press == key:
		draw_rect(r, C_PRESS, true)
	_txt(_f12, int(r.position.x), int(r.position.y) + 5, label,
		col if enabled else C_DIM, 13, int(r.size.x))


func _draw() -> void:
	if _bezel != null:
		draw_texture_rect(_bezel, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _barra != null:
		draw_texture_rect(_barra, Rect2(0, BARRA_Y, W, _barra.get_height()), false)

	# Title + the manager-name caption (the LineEdit child renders the field itself).
	_txt(_f14, int(R_TITLE.position.x), int(R_TITLE.position.y), "ENTER YOUR NAME AND SELECT A TEAM",
		C_TITLE, 15, int(R_TITLE.size.x))
	_txt(_f12, int(R_PLAYER.position.x), int(R_PLAYER.position.y) + 4, "PLAYER", C_GOLD, 13, int(R_PLAYER.size.x))

	# League plaque (cycles the division). "Manager" sits above it on the BARRA.
	var lname: String = str(_leagues[_li].get("name", "")) if _li < _leagues.size() else ""
	draw_rect(R_LEAGUE, Color(0.0, 0.0, 0.0, 0.45), true)
	if _press == "league":
		draw_rect(R_LEAGUE, C_PRESS, true)
	_txt(_f12, int(R_LEAGUE.position.x) + 6, int(R_LEAGUE.position.y) + 4,
		"< %s >" % lname.to_upper(), C_TITLE, 13, int(R_LEAGUE.size.x) - 12)

	# Team grid (two columns of the selected division's clubs).
	draw_rect(Rect2(14, GRID_TOP - 6, W - 28, GRID_BOT - GRID_TOP + 12), C_PANEL, true)
	for i in _clubs.size():
		var col := i % 2
		var row := i / 2
		var ry := _row_y(row)
		if ry + ROW_H > GRID_BOT:
			break
		var cx: int = COL_X[col]
		var cell := Rect2(cx, ry, COL_W, ROW_H - 2)
		if i == _sel:
			draw_rect(cell, C_SEL, true)
		elif _press == "club:%d" % i:
			draw_rect(cell, C_PRESS, true)
		var nm := str(_clubs[i].get("name", "?"))
		var tcol: Color = Color(0.06, 0.10, 0.18) if i == _sel else C_TITLE
		_txt(_f12, cx + 8, ry + 4, nm.substr(0, 22), tcol, 13)

	# Bottom button row (LOAD/DELETE only active when a save exists; CONTINUE when a club is picked).
	_btn(R_RETURN, "RETURN", C_YELLOW, true, "return")
	_btn(R_LOAD, "LOAD GAME", C_GOLD, _has_save, "load")
	_btn(R_DELETE, "DELETE", C_RED, _has_save, "delete")
	_btn(R_CONTINUE, "CONTINUE", C_YELLOW, _sel >= 0, "continue")
