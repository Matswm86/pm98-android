extends Control
class_name DataBaseScreen
## PM98 DATA BASE — the dbasewin.exe team/player browser SQUAD view, rebuilt from the
## reversed binary (NOT the invented green list it replaces). See docs/re/database_screen_re.md.
##
## Reversed 2026-06-29 from Dbasewin.exe:
##   * Background = RC_DBASE\FONDO DBASE.BMP, blitted at (0,0) (FUN_0042aba0 step 2).
##   * Four position columns built at literal widget rects (FUN_0042aba0, ebp+0x45f4 /
##     +0x4a0c / +0x4e24 / +0x523c), each titled GOALKEEPERS / DEFENDERS / MIDFIELDERS /
##     FORWARDS (str 0x493900..0x493930). Rects normalized via FUN_00404180(base, delta).
##   * Players binned into the 4 lists by their EQUIPOS demarcación category (0/1/2/3 =
##     GK/DF/MF/FW, FUN_0042c200) and sorted alphabetically by name (lstrcmp, FUN_0042c540).
##   * Each list rendered in LISTS mode (FUN_0042b540, this+0x2d4c == 0): Proman10, row
##     pitch 18px, first row y 21 within the column, name cell x=3 w=196; per row a MINIFOTO
##     thumbnail keyed by the player's photoId (FUN_0042c1c0 -> FUN_00445f10(id)) + the name.
##
## Native 640x480; scales to fit its parent (letterboxed). A row tap raises that player's
## FICHA (player_pressed); RETURN or a tap on empty space dismisses (back_pressed).

signal back_pressed
signal player_pressed(player)

const W := 640
const H := 480

# Column widget rects reversed from FUN_0042aba0, as Rect2(left, top, width, height).
const COLS := [
	{"key": "GK", "title": "GOALKEEPERS", "rect": Rect2(6, 13, 208, 115)},    # ebp+0x45f4
	{"key": "DF", "title": "DEFENDERS",   "rect": Rect2(6, 140, 209, 315)},   # ebp+0x4a0c
	{"key": "MF", "title": "MIDFIELDERS", "rect": Rect2(218, 140, 209, 315)}, # ebp+0x4e24
	{"key": "FW", "title": "FORWARDS",    "rect": Rect2(430, 140, 209, 277)}, # ebp+0x523c
]
# LISTS-mode row metrics reversed from FUN_0042b540 (this+0x2d4c == 0).
const HDR_H := 19      # column title band; rows begin at FIRST_Y below the column top
const FIRST_Y := 21    # local_270 (0x15): first row y within the column client
const PITCH := 18      # local_260 (0x12): Δy per row
const ROW_X := 3       # local_25c: cell base x within the column
const ROW_W := 196     # local_268 (0xc4): cell width
const RETURN_BTN := Rect2(516, 446, 118, 26)

# DATA BASE palette (the blue RC_DBASE chrome over the washed FONDO photo).
const C_PANEL := Color(0.08, 0.13, 0.30, 0.82)   # translucent list panel
const C_PANEL_BD := Color(0.55, 0.70, 0.95, 0.90)
const C_HDR := Color(0.13, 0.27, 0.56, 0.96)     # blue title band
const C_HDR_TXT := Color(0.86, 0.93, 1.0)
const C_ROW_A := Color(0.10, 0.17, 0.36, 0.40)   # faint row banding
const C_ROW_TXT := Color(0.95, 0.97, 1.0)
const C_SEP := Color(0.40, 0.55, 0.85, 0.30)
const C_CAPTION := Color(0.92, 0.96, 1.0)
const C_BTN := Color(0.13, 0.27, 0.56)
const C_BTN_HI := Color(0.42, 0.58, 0.86)
const C_BTN_LO := Color(0.05, 0.10, 0.26)
const C_GOLD := Color(1.0, 0.84, 0.22)

var _bg: Texture2D
var _f10: Font
var _f12: Font
var _club: Dictionary = {}
var _press := ""
var _rows: Array = []   # [{r: Rect2 (design space), p: Dictionary}] for row taps


func _ready() -> void:
	_bg = load("res://art/screens/fondo_dbase.png") if ResourceLoader.exists("res://art/screens/fondo_dbase.png") else null
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(club: Dictionary) -> void:
	_club = club
	queue_redraw()


# ---- ordering ------------------------------------------------------------

## Bin the squad into the 4 EQUIPOS categories, alphabetical by name within each (the
## FUN_0042c200 -> FUN_0042c540 order). Unknown positions fall to midfield.
func _bucket(key: String) -> Array:
	var out: Array = []
	for p in _club.get("players", []):
		if int(p.get("id", -1)) < 0:
			continue
		if _cat_of(p) == key:
			out.append(p)
	out.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	return out


func _cat_of(p: Dictionary) -> String:
	var pos := str(p.get("pos", "")).to_upper()
	if pos in ["GK", "DF", "MF", "FW"]:
		return pos
	return "GK" if p.get("isGK") else "MF"


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	if e is InputEventMouseButton:
		pos = (e as InputEventMouseButton).position
		pressed = (e as InputEventMouseButton).pressed
	elif e is InputEventScreenTouch:
		pos = (e as InputEventScreenTouch).position
		pressed = (e as InputEventScreenTouch).pressed
	else:
		return
	var d := _to_design(pos)
	if pressed:
		_press = "return" if RETURN_BTN.has_point(d) else ""
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if RETURN_BTN.has_point(d):
		if was == "return":
			back_pressed.emit()
		return
	for row in _rows:
		if (row["r"] as Rect2).has_point(d):
			player_pressed.emit(row["p"])
			return
	back_pressed.emit()


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: float, y_top: float, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else x
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.05, 0.08), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# FONDO DBASE.BMP at (0,0) — the real washed-blue football photo + grid.
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.36, 0.42, 0.56), true)

	# Club caption across the thin top strip above the GOALKEEPERS column.
	var cap := str(_club.get("name", "")).to_upper()
	if cap != "":
		_txt(_f12, 222, 2, cap, C_CAPTION, 13)
		_txt(_f10, 222, 18, "DATA BASE", Color(0.70, 0.80, 0.96), 10)

	_rows.clear()
	for col in COLS:
		_draw_column(col)

	_draw_return()


func _draw_column(col: Dictionary) -> void:
	var r: Rect2 = col["rect"]
	# Translucent list panel + 1px border, blue title band, then the rows.
	draw_rect(r, C_PANEL, true)
	draw_rect(r, C_PANEL_BD, false, 1.0)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, HDR_H), C_HDR, true)
	_txt(_f10, r.position.x + 6, r.position.y + 4, str(col["title"]), C_HDR_TXT, 11)

	var players := _bucket(str(col["key"]))
	var max_rows := int(floor((r.size.y - FIRST_Y) / PITCH))
	var y := r.position.y + FIRST_Y
	for i in players.size():
		if i >= max_rows:
			break
		var p: Dictionary = players[i]
		var row_r := Rect2(r.position.x + ROW_X, y, ROW_W, PITCH - 1)
		_rows.append({"r": row_r, "p": p})
		if i % 2 == 1:
			draw_rect(row_r, C_ROW_A, true)
		# MINIFOTO thumbnail at the row's left, fitted to the row height (FUN_0042c1c0).
		var face := PMChrome.mini_face(p.get("photoId"))
		var tx := r.position.x + ROW_X + 1
		var th := float(PITCH - 2)
		if face != null:
			draw_texture_rect(face, Rect2(tx, y + 1, th, th), false)
		# Name in Proman10 to the right of the thumbnail.
		_txt(_f10, tx + th + 4, y + 2, str(p.get("name", "?")).substr(0, 18), C_ROW_TXT, 11)
		draw_rect(Rect2(r.position.x + ROW_X, y + PITCH - 1, ROW_W, 1), C_SEP, true)
		y += PITCH


func _draw_return() -> void:
	var rb := RETURN_BTN
	PMChrome.bevel(self, rb, C_BTN_HI if _press == "return" else C_BTN, C_BTN_HI, C_BTN_LO)
	_txt(_f10, rb.position.x + 34, rb.position.y + 7, "RETURN", C_GOLD, 12)
