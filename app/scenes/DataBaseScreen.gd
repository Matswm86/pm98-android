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
# Each AddColumn call (vtable [edi+0xc0]) is preceded by FUN_004042b0(color, R,G,B) which
# writes a 4-byte COLORREF {R,G,B,0} — the per-position-group identity colour. Reversed by
# objdump at the four call sites (0x42af6d / 0x42afcd-style); the original colour-codes the
# four groups, it does NOT use one shared blue.
const COLS := [
	{"key": "GK", "title": "GOALKEEPERS", "rect": Rect2(6, 13, 208, 115),  "col": Color8(80, 110, 5)},    # ebp+0x45f4 (0x50,0x6e,0x05)
	{"key": "DF", "title": "DEFENDERS",   "rect": Rect2(6, 140, 209, 315), "col": Color8(212, 63, 0)},    # ebp+0x4a0c (0xd4,0x3f,0x00)
	{"key": "MF", "title": "MIDFIELDERS", "rect": Rect2(218, 140, 209, 315), "col": Color8(170, 0, 0)},   # ebp+0x4e24 (0xaa,0x00,0x00)
	{"key": "FW", "title": "FORWARDS",    "rect": Rect2(430, 140, 209, 277), "col": Color8(108, 21, 21)}, # ebp+0x523c (0x6c,0x15,0x15)
]
# Row metrics reversed from FUN_0042b540 (the two modes toggled by this+0x2d4c).
const HDR_H := 19      # column title band; rows begin at FIRST_Y below the column top
# LISTS mode (Proman10): tight text rows, small thumbnail.
const FIRST_Y := 21    # local_270 (0x15): first row y within the column client
const PITCH := 18      # local_260 (0x12): Δy per row
const ROW_X := 3       # local_25c: cell base x within the column
const ROW_W := 196     # local_268 (0xc4): cell width
# PHOTOS mode (Futuri18): taller rows, larger photo (RE doc session 3 table).
const FIRST_Y_PH := 25 # 0x19
const PITCH_PH := 40   # 0x28
const ROW_X_PH := 9    # 0x9
const RETURN_BTN := Rect2(516, 446, 118, 26)
# Tapping the title strip toggles LISTS <-> PHOTOS (the real game uses a bitmap button whose
# on-screen position is not yet reversed; this is a documented mobile stand-in, no invented art).
const TITLE_RECT := Rect2(224, 18, 372, 39)

# DATA BASE palette. Each column's chrome is derived from its REAL per-group COLORREF (COLS
# "col"); only the alphas below are an un-reversed compositing choice (the widget paint slot
# at the row CWnds is not yet reversed — see docs/re/database_screen_re.md "open").
const A_PANEL := 0.30    # body fill alpha over FONDO
const A_HDR := 0.95      # title band alpha
const C_HDR_TXT := Color(1, 1, 1)                # white — verified 0xffffff in the setter
const C_ROW_A := Color(0, 0, 0, 0.18)            # faint row banding (neutral, readability)
const C_ROW_TXT := Color(0.95, 0.97, 1.0)
const C_SEP := Color(1, 1, 1, 0.16)
const C_TITLE := Color(1, 1, 1)   # club-name title — verified 0xffffff (FUN_004042d0)
const C_BTN := Color(0.13, 0.27, 0.56)
const C_BTN_HI := Color(0.42, 0.58, 0.86)
const C_BTN_LO := Color(0.05, 0.10, 0.26)
const C_GOLD := Color(1.0, 0.84, 0.22)

var _bg: Texture2D
var _f10: Font
var _f12: Font
var _f18: Font
var _ffut: Font   # Futuri18 — PHOTOS-mode row font
var _photos := false
var _club: Dictionary = {}
var _press := ""
var _rows: Array = []   # [{r: Rect2 (design space), p: Dictionary}] for row taps


func _ready() -> void:
	_bg = load("res://art/screens/fondo_dbase.png") if ResourceLoader.exists("res://art/screens/fondo_dbase.png") else null
	_f10 = PMChrome.font("10")
	_f12 = PMChrome.font("12")
	_f18 = PMChrome.font("18")
	_ffut = PMChrome.font("futuri18")
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
	# Title strip toggles LISTS <-> PHOTOS (this+0x2d4c); stand-in for the real button.
	if TITLE_RECT.has_point(d):
		_photos = not _photos
		queue_redraw()
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

	# Header title: the club/competition name in Proman18, white, in the top strip to the
	# right of the GOALKEEPERS column. Widget this+0x5a6c, rect base (224,18) delta (372,39)
	# (FUN_0042aba0 0x42ae7e..0x42aea6), colour 0xffffff (FUN_004042d0). No "DATA BASE"
	# subtitle exists in the binary — that was invented; removed.
	var cap := str(_club.get("name", "")).to_upper()
	if cap != "":
		var tf: Font = _f18 if _f18 != null else _f12
		_txt(tf, 224, 18 + 10, cap, C_TITLE, 18)

	_rows.clear()
	for col in COLS:
		_draw_column(col)

	_draw_return()


func _draw_column(col: Dictionary) -> void:
	var r: Rect2 = col["rect"]
	var cc: Color = col["col"]   # the reversed per-group COLORREF
	# Body fill + 1px border + title band, all tinted from the column's real group colour.
	draw_rect(r, Color(cc.r, cc.g, cc.b, A_PANEL), true)
	draw_rect(r, cc.lightened(0.45), false, 1.0)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, HDR_H), Color(cc.r, cc.g, cc.b, A_HDR), true)
	_txt(_f10, r.position.x + 6, r.position.y + 4, str(col["title"]), C_HDR_TXT, 11)

	# Mode-selected row metrics (FUN_0042b540: LISTS vs PHOTOS, toggled by this+0x2d4c).
	var first_y := FIRST_Y_PH if _photos else FIRST_Y
	var pitch := PITCH_PH if _photos else PITCH
	var row_x := ROW_X_PH if _photos else ROW_X
	var row_w := int(r.size.x) - row_x * 2
	var name_f: Font = (_ffut if _ffut != null else _f12) if _photos else _f10
	var name_sz := 18 if _photos else 11

	var players := _bucket(str(col["key"]))
	var max_rows := int(floor((r.size.y - first_y) / pitch))
	var y := r.position.y + first_y
	for i in players.size():
		if i >= max_rows:
			break
		var p: Dictionary = players[i]
		var row_r := Rect2(r.position.x + row_x, y, row_w, pitch - 1)
		_rows.append({"r": row_r, "p": p})
		if i % 2 == 1:
			draw_rect(row_r, C_ROW_A, true)
		# MINIFOTO photo at the row's left, fitted to the row height (FUN_0042c1c0).
		var face := PMChrome.mini_face(p.get("photoId"))
		var tx := r.position.x + row_x + 1
		var th := float(pitch - 4)
		if face != null:
			draw_texture_rect(face, Rect2(tx, y + 2, th, th), false)
		# Name to the right of the photo (Proman10 in LISTS, Futuri18 in PHOTOS).
		var clamp := 14 if _photos else 18
		_txt(name_f, tx + th + 4, y + (pitch - name_sz) * 0.5, str(p.get("name", "?")).substr(0, clamp), C_ROW_TXT, name_sz)
		draw_rect(Rect2(r.position.x + row_x, y + pitch - 1, row_w, 1), C_SEP, true)
		y += pitch


func _draw_return() -> void:
	var rb := RETURN_BTN
	PMChrome.bevel(self, rb, C_BTN_HI if _press == "return" else C_BTN, C_BTN_HI, C_BTN_LO)
	_txt(_f10, rb.position.x + 34, rb.position.y + 7, "RETURN", C_GOLD, 12)
