extends Control
class_name ManToManScreen
## PM98 MAN-TO-MAN MARKINGS — the last in-match door, reached from the BRIEF's
## MAN-TO-MAN button (witnessed: walkthrough frame `057_162619` -> `058_162622`).
##
## Everything here is read out of the original. `docs/re/mantoman_screen_re.md`
## carries the full record; the short version:
##
##  * layout = `MANAGER.EXE FUN_0050e980`, the screen's own init. Three panels
##    (`FUN_00510700`), ten MY outfield rows, ten OPPONENT rows, ten green
##    assignment cells, ten grey FLECHAS boxes, the pitch and the two marking-line
##    markers. Every rect below is that function's own, panel-relative arithmetic
##    resolved to screen coordinates.
##  * per-row cells = the four draw overrides `FUN_005100a0` (my row),
##    `FUN_0050fc40` (opponent row), `FUN_005103c0` (assignment cell) and
##    `FUN_0050fee0` (the panel's column headers). Alignment comes from the widget
##    flag word `+0x144`: bit 0x20 = left, bit 0x40 = right, neither = GDI-centred.
##  * the model = `team+0x234 + 4*i`, one entry per outfield lineup slot `2+i`:
##    0 = unmarked, 2..11 = the opponent lineup slot that player man-marks.
##    `session_lineup_re.md` already binds the other end — the positional engine
##    reads it as `rec+0x28 = entry - 1`.
##  * the two marking lines are `club[0x25c]` / `club[0x260]` scaled `*148/318`
##    (ctor defaults 79 and 198 -> panel x 36 and 92), the marker's left edge
##    sitting at `12 + v`. The two tracks bound each other so the lines cannot
##    cross: D travels `[12, 12+v_mid]`, M travels `[v_def+13, 162]`.
##
## Static chrome is the REAL frame (`tools/re/build_mantoman_chrome_from_frames.py`
## cuts `66_mantoman_match.png` y62..479 and blanks only the dynamic cells; the
## bake refuses to run unless the Bolton and Manchester Utd. witnesses agree on
## every chrome pixel). The pitch under the markers is the game's own
## `campo.bmp`, so a dragged line uncovers original pixels.
##
## DECLARED-OURS, the one rule not directly witnessed: no frame in the corpus
## moves a marking line, so the pixel -> field inverse `x * 318 / 148` is the
## inverse of the binary's own forward map rather than a measured value.

signal back_pressed          # RETURN
signal markings_changed(markings: Array)   # the ten-entry table, whenever it changes

const W := 640
const H := 480
const BODY_Y0 := 62

# --- panels (FUN_00510700) ---------------------------------------------------
const MAIN := Rect2(23, 82, 488, 186)
const OPP_PANEL := Rect2(23, 278, 267, 178)
const PITCH := Rect2(319, 278, 192, 178)

# --- rows (screen-absolute, i = 0..9) ---------------------------------------
const ROW_STEP := 16
const MY_ROW := Rect2(32, 102, 217, 16)
const OPP_ROW := Rect2(31, 287, 192, 16)
const CELL_ROW := Rect2(285, 102, 217, 16)
const GREY_ROW := Rect2(248, 103, 38, 14)

# row-relative cells (from the draw overrides)
const MY_NUM := Vector2(3, 21)        # x0, width  -> GDI-centred
const MY_NAME_X := 34
const MY_ROLE_X := 151
const MY_POS := Vector2(176, 40)
const OPP_NAME_X := 8
const OPP_ROLE_X := 125
const OPP_POS := Vector2(150, 40)
const CELL_POS := Vector2(2, 40)
const CELL_ROLE_X := 41
const CELL_NAME := Vector2(66, 117)   # RIGHT-aligned inside this box
const CELL_NUM := Vector2(190, 21)
const TEXT_DY := 3       # the text rect's top is row+2; the face's own leading adds 1
const ROLE_DY := 1
const ROLE_WH := Vector2(25, 14)

# --- the opponent panel's kit + vertical club plate --------------------------
const KIT_XY := Vector2(229, 283)
const PLATE_TEXT := Rect2(243, 338, 20, 107)   # opp-panel-rel (220,60)-(239,167)
const PLATE_FACE_H := 10                       # ProMan10 line height (the panel's face)
const PLATE_PEN_DX := 4                        # measured: the rotated baseline sits at x255

# --- the pitch + the two markers --------------------------------------------
const MARK_W := 22
const MARK_H := 109
const MARK_D_Y := 28      # panel-relative track tops (this+0xba90 / this+0xbe84)
const MARK_M_Y := 45
const MARK_X0 := 12       # marker left = MARK_X0 + value
const LINE_SCALE_NUM := 148
const LINE_SCALE_DEN := 318
const D_LETTER := Rect2(0, 0, 19, 13)
const M_LETTER := Rect2(0, 93, 19, 13)

# --- buttons (screen-absolute, FUN_0050e980) --------------------------------
const BTN_DELETE := Rect2(520, 278, 112, 25)   # id 906
const BTN_RETURN := Rect2(520, 408, 112, 25)   # id 900

# --- colours (binary value -> the palette-realised pixel, measured) ----------
const C_MY := Color8(212, 223, 255)
const C_MY_SEL := Color8(160, 180, 200)
const C_OPP := Color8(30, 52, 98)
const C_OPP_MARKED := Color8(166, 202, 240)
const C_CELL := Color8(212, 255, 170)
const C_NUM := Color8(0, 0, 128)      # 0x840000 COLORREF
const C_BLACK := Color(0, 0, 0)
const C_WHITE := Color(1, 1, 1)
const C_ROLE_BACK := Color(0, 0, 0)   # the camrol sprite's alpha-0 ring shows black

const POS_WORD := {"GK": "GOAL", "DF": "DEF", "MF": "MID", "FW": "FOR"}

var _body: Texture2D
var _linead: Texture2D
var _lineam: Texture2D
var _flechas: Texture2D
var _f8: Font
var _f10: Font

var _my_xi: Array = []        # the ten OUTFIELD players, lineup slots 2..11
var _opp_xi: Array = []
var _my_id := -1
var _opp_id := -1
var _opp_name := ""
var _markings: Array = []     # 10 ints; 0 = none, 2..11 = the opponent slot
var _v_def := 36              # club[0x25c] * 148/318, ctor default 79 -> 36
var _v_mid := 92              # club[0x260] * 148/318, ctor default 198 -> 92
var _sel := -1                # the selected MY row, -1 = none
var _press := ""
var _drag := ""               # "d" / "m" while a marking line is being dragged
var _header := {}


func _ready() -> void:
	_body = load("res://art/screens/mantoman/body.png")
	_linead = load("res://art/screens/mantoman/linead.png")
	_lineam = load("res://art/screens/mantoman/lineam.png")
	_flechas = load("res://art/screens/mantoman/flechas.png")
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `my_xi` / `opp_xi` are the ordered XIs (slot 0 = GK); this screen lists slots
## 1..10 of each, exactly as the original asks `FUN_0057a2e0` for lineup slots
## 2..11. `markings` is the ten-entry `team+0x234` table (0 = unmarked).
## `lines` is [club[0x25c], club[0x260]] in the binary's own units.
func setup(my_id: int, my_xi: Array, opp_id: int, opp_name: String, opp_xi: Array,
		markings: Array = [], lines: Array = [], header: Dictionary = {}) -> void:
	_my_id = my_id
	_opp_id = opp_id
	_opp_name = opp_name
	_my_xi = _outfield(my_xi)
	_opp_xi = _outfield(opp_xi)
	_markings = []
	for i in 10:
		_markings.append(int(markings[i]) if i < markings.size() else 0)
	if lines.size() == 2:
		_v_def = int(lines[0]) * LINE_SCALE_NUM / LINE_SCALE_DEN
		_v_mid = int(lines[1]) * LINE_SCALE_NUM / LINE_SCALE_DEN
	_header = header
	_sel = -1
	queue_redraw()


static func _outfield(xi: Array) -> Array:
	# slot 0 is the goalkeeper; the original's screen only asks for slots 2..11.
	var out: Array = []
	for i in range(1, 11):
		out.append(xi[i] if i < xi.size() else {})
	return out


## The ten-entry table, for the caller to persist / feed the engine
## (`rec+0x28 = entry - 1`, session_lineup_re.md).
func markings() -> Array:
	return _markings.duplicate()


# ---- geometry ------------------------------------------------------------

func _row_rect(base: Rect2, i: int) -> Rect2:
	return Rect2(base.position.x, base.position.y + ROW_STEP * i, base.size.x, base.size.y)


func _mark_x(v: int) -> int:
	return int(PITCH.position.x) + MARK_X0 + v


func _d_rect() -> Rect2:
	return Rect2(_mark_x(_v_def), PITCH.position.y + MARK_D_Y, MARK_W, MARK_H)


func _m_rect() -> Rect2:
	return Rect2(_mark_x(_v_mid), PITCH.position.y + MARK_M_Y, MARK_W, MARK_H)


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	if BTN_RETURN.has_point(d):
		return "return"
	if BTN_DELETE.has_point(d):
		return "delete"
	if _d_rect().has_point(d):
		return "mark_d"
	if _m_rect().has_point(d):
		return "mark_m"
	for i in 10:
		if _row_rect(MY_ROW, i).has_point(d):
			return "my:%d" % i
		if _row_rect(OPP_ROW, i).has_point(d):
			return "opp:%d" % i
	return ""


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion or e is InputEventScreenDrag:
		if _drag != "":
			_drag_line(_to_design(e.position).x)
		return
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		if _press == "mark_d":
			_drag = "d"
		elif _press == "mark_m":
			_drag = "m"
		queue_redraw()
		return
	var was := _press
	_press = ""
	_drag = ""
	if was != "" and was == _hit(d):
		_activate(was)
	queue_redraw()


## The two tracks bound each other exactly as the original builds them
## (`this+0xba90` = pos (12,28) size (v_mid+22,109); `this+0xbe84` =
## CRect(v_def+13,45,184,154)), so the defending line can never pass the
## midfielding one.
func _drag_line(design_x: float) -> void:
	var v := int(round(design_x - PITCH.position.x - MARK_X0 - MARK_W * 0.5))
	if _drag == "d":
		_v_def = clampi(v, 0, _v_mid)
	else:
		_v_mid = clampi(v, _v_def, 150)
	queue_redraw()


## The binary's forward map is `px = field * 148 / 318`; this is its inverse,
## the one derived (not witnessed) rule on this screen.
func lines() -> Array:
	return [_v_def * LINE_SCALE_DEN / LINE_SCALE_NUM, _v_mid * LINE_SCALE_DEN / LINE_SCALE_NUM]


func _activate(target: String) -> void:
	if target == "return":
		back_pressed.emit()
		return
	if target == "delete":
		# DELETE clears the selected row's marking (the grey box and the green
		# cell empty, and the opponent row loses its already-marked state).
		if _sel >= 0 and _markings[_sel] != 0:
			_markings[_sel] = 0
			markings_changed.emit(markings())
		return
	if target.begins_with("my:"):
		var i := int(target.substr(3))
		_sel = -1 if _sel == i else i
		return
	if target.begins_with("opp:"):
		# Witnessed 060 -> 061: with a MY row selected, tapping an opponent commits
		# the pair. With nothing selected the tap is a no-op (059 shows a rollover
		# repaint only).
		if _sel < 0:
			return
		var slot := int(target.substr(4)) + 2   # opponent lineup slots run 2..11
		for k in 10:
			if k != _sel and _markings[k] == slot:
				_markings[k] = 0    # an opponent can only be marked once
		_markings[_sel] = slot
		markings_changed.emit(markings())


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	var origin := Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	draw_set_transform(origin, 0.0, Vector2(s, s))
	if not _header.is_empty():
		PMChrome.draw_match_header(self, "mtm", _header)
	if _body != null:
		draw_texture(_body, Vector2(0, BODY_Y0))

	_draw_my_rows()
	_draw_cells()
	_draw_opp_rows()
	_draw_opp_panel(origin, s)
	_draw_markers()
	if _press != "":
		var r := _press_rect()
		if r.size.x > 0:
			draw_rect(r, Color(1, 1, 1, 0.20), true)


func _press_rect() -> Rect2:
	match _press:
		"return":
			return BTN_RETURN
		"delete":
			return BTN_DELETE
	return Rect2()


func _cell_centre(s: String, x0: float, box_w: float) -> float:
	var w := _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	return x0 + floor((box_w - w) * 0.5)


func _pos_word(p: Dictionary) -> String:
	return str(POS_WORD.get(str(p.get("pos", "")), "OUT"))


func _role(p: Dictionary) -> Texture2D:
	return PMChrome.camrol(PMChrome.iget(p, "posFine", 10))


func _shirt(p: Dictionary, slot: int) -> int:
	var no := PMChrome.iget(p, "squadNo")
	return no if no > 0 else slot


func _draw_role(p: Dictionary, x: float, y: float) -> void:
	draw_rect(Rect2(x, y, ROLE_WH.x, ROLE_WH.y), C_ROLE_BACK, true)
	var t := _role(p)
	if t != null:
		draw_texture(t, Vector2(x, y))


func _draw_my_rows() -> void:
	for i in 10:
		var p: Dictionary = _my_xi[i]
		if p.is_empty():
			continue
		var r := _row_rect(MY_ROW, i)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, r.size.y - 4),
			C_MY_SEL if i == _sel else C_MY, true)
		var y := r.position.y + TEXT_DY
		var num := str(_shirt(p, i + 2))
		PMChrome.text(self, _f8, _cell_centre(num, r.position.x + MY_NUM.x, MY_NUM.y),
			y, num, C_NUM, 11)
		PMChrome.text(self, _f8, r.position.x + MY_NAME_X, y,
			PMChrome.title_case_name(str(p.get("name", "?"))), C_BLACK, 11)
		_draw_role(p, r.position.x + MY_ROLE_X, r.position.y + ROLE_DY)
		var pw := _pos_word(p)
		PMChrome.text(self, _f8, _cell_centre(pw, r.position.x + MY_POS.x, MY_POS.y),
			y, pw, C_BLACK, 11)


func _draw_opp_rows() -> void:
	var marked := {}
	for m in _markings:
		if int(m) >= 2:
			marked[int(m) - 2] = true
	for i in 10:
		var p: Dictionary = _opp_xi[i]
		if p.is_empty():
			continue
		var r := _row_rect(OPP_ROW, i)
		var on: bool = marked.has(i)
		# The row keeps the chrome's own 1px border; only the fill changes. (The
		# 2px border frames 059/061/063 show on one row at a time is the POINTER
		# ROLLOVER — it follows the mouse, not the marking: 062 and 064 have it on
		# neither row while both markings stand. A touch screen has no hover, so
		# this port does not draw it. Declared divergence.)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, r.size.y - 4),
			C_OPP_MARKED if on else C_OPP, true)
		var ink := C_BLACK if on else C_WHITE
		var y := r.position.y + TEXT_DY
		PMChrome.text(self, _f8, r.position.x + OPP_NAME_X, y,
			PMChrome.title_case_name(str(p.get("name", "?"))), ink, 11)
		_draw_role(p, r.position.x + OPP_ROLE_X, r.position.y + ROLE_DY)
		var pw := _pos_word(p)
		PMChrome.text(self, _f8, _cell_centre(pw, r.position.x + OPP_POS.x, OPP_POS.y),
			y, pw, ink, 11)


func _draw_cells() -> void:
	for i in 10:
		var slot := int(_markings[i])
		if slot < 2 or slot > 11:
			continue
		var p: Dictionary = _opp_xi[slot - 2]
		if p.is_empty():
			continue
		# The grey box carries the FLECHAS sprite the moment a pair is committed, and
		# it repaints its ground BLACK first (witness 063: every pixel the sprite
		# leaves transparent is black there, grey on an unassigned row).
		var g := _row_rect(GREY_ROW, i)
		draw_rect(g, C_BLACK, true)
		if _flechas != null:
			draw_texture(_flechas, g.position)
		var r := _row_rect(CELL_ROW, i)
		var y := r.position.y + TEXT_DY
		var pw := _pos_word(p)
		PMChrome.text(self, _f8, _cell_centre(pw, r.position.x + CELL_POS.x, CELL_POS.y),
			y, pw, C_BLACK, 11)
		_draw_role(p, r.position.x + CELL_ROLE_X, r.position.y + ROLE_DY)
		var nm := PMChrome.title_case_name(str(p.get("name", "?")))
		var nw := _f8.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		PMChrome.text(self, _f8, r.position.x + CELL_NAME.x + CELL_NAME.y - nw, y,
			nm, C_BLACK, 11)
		var num := str(_shirt(p, slot))
		PMChrome.text(self, _f8, _cell_centre(num, r.position.x + CELL_NUM.x, CELL_NUM.y),
			y, num, C_NUM, 11)


func _draw_opp_panel(origin: Vector2, s: float) -> void:
	var kit := PMChrome.kit(_opp_id)
	if kit != null:
		# The 48x64 kit is the OTHER shadowed blit on this screen: `FUN_0050fae0`
		# pushes cap 0x84 where the markers push 0x63.
		_shadow(kit, KIT_XY, PMShadow.CAP_KIT, "mtm_kit%d" % _opp_id)
		draw_texture(kit, KIT_XY)
	if _opp_name == "" or _f10 == null:
		return
	# The vertical club plate. The panel's face is ProMan10 (the init sets it on
	# `this+0xf350` @0x50ef61) and the name is drawn rotated inside
	# opp-panel-rel (220,60)-(239,167), reading BOTTOM to TOP and CENTRED on both
	# axes — measured on the Bolton witness: "Aston Villa" is 71 px of ProMan10
	# advance and its ink runs y357..426 inside a 107-tall box (338 + (107-71)/2),
	# 9 px wide inside a 20-wide plate. Per-glyph advances 10,7,7,8,8… identify the
	# face exactly.
	var tw := _f10.get_string_size(_opp_name, HORIZONTAL_ALIGNMENT_LEFT, -1,
		PLATE_FACE_H).x
	var pen := origin + Vector2(
		PLATE_TEXT.position.x + PLATE_PEN_DX,
		PLATE_TEXT.position.y + floor((PLATE_TEXT.size.y + tw) * 0.5)) * s
	draw_set_transform(pen, -PI * 0.5, Vector2(s, s))
	draw_string(_f10, Vector2(0, _f10.get_ascent(PLATE_FACE_H)), _opp_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, PLATE_FACE_H, C_WHITE)
	draw_set_transform(origin, 0.0, Vector2(s, s))


## Lay the shadowed blit's spread stamp under `sprite` at `at`. The background is
## the baked body, whose own (0,0) sits at screen (0, BODY_Y0); the dither parity is
## resolved in screen space inside PMShadow.
func _shadow(sprite: Texture2D, at: Vector2, cap: int, key: String) -> void:
	if _body == null:
		return
	var dest := Vector2i(int(at.x), int(at.y))
	var t := PMShadow.for_sprite("%s@%d,%d" % [key, dest.x, dest.y], _body,
		Vector2i(0, BODY_Y0), sprite, dest, cap)
	if t != null:
		draw_texture(t, at)


func _draw_markers() -> void:
	# Both markers go through `FUN_0050f970` -> `FUN_004b7f60(0x10, 0x21, 0x63, ...)`,
	# so each carries the shadowed blit's spread stamp under it (PMShadow).
	if _linead != null:
		_shadow(_linead, _d_rect().position, PMShadow.CAP_MARKER, "mtm_d")
		draw_texture(_linead, _d_rect().position)
	if _lineam != null:
		_shadow(_lineam, _m_rect().position, PMShadow.CAP_MARKER, "mtm_m")
		draw_texture(_lineam, _m_rect().position)
	# the D / M letters are TEXT the original draws over the sprite
	var d := _d_rect().position
	PMChrome.text(self, _f8, _cell_centre("D", d.x + D_LETTER.position.x, D_LETTER.size.x),
		d.y + D_LETTER.position.y, "D", C_BLACK, 11)
	var m := _m_rect().position
	PMChrome.text(self, _f8, _cell_centre("M", m.x + M_LETTER.position.x, M_LETTER.size.x),
		m.y + M_LETTER.position.y, "M", C_BLACK, 11)
