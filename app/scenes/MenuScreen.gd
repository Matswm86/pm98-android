extends Control
class_name MenuScreen
## PM98 MAIN MENU (MENUPRINCIPAL) screen rebuilt from the ORIGINAL game art at the
## coordinates reversed out of MANAGER.EXE (FUN_005469c0). See docs/re/menu_screen_re.md.
##
## The management hub: 12 picture icons in two vertical bands of 3 rows per side
## (grey label slots from trozo_fondo, mirrored for the right column), around a
## central club panel + a four-button control bar (EXIT / SAVE GAME / NEWS /
## CONTINUE). The static chrome (trozo + icons + captions + buttons) is baked into
## art/screens/menu_bg.png exactly the way fondo_marble.png is; this node blits it,
## overlays the live club panel, and turns taps into actions.
##
## Unlike the other graphical screens this one is INTERACTIVE: tapping an icon or a
## control button emits `action_selected(action)` (the calling Main routes it). Hit
## areas are the union of each icon's reversed picture rect and its caption rect.
## Native 640x480; scales to fit its parent.

signal action_selected(action: String)

const W := 640
const H := 480

const C_TITLE := Color(0.91, 0.94, 1.0)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_CASH := Color(0.98, 0.86, 0.45)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.22)

# Reversed icon hit areas: action -> the icon PICTURE rect (pos, size) from the two
# FUN_00436fb0(x,y) points. Picture rects are used (not picture+caption unions) so no
# two hit areas overlap and a tap is unambiguous; the picture is the obvious target.
const ICON_HITS := {
	"results": Rect2(7, 71, 86, 60),        # MARCA
	"table": Rect2(206, 93, 87, 72),        # CLASI
	"fixtures": Rect2(10, 147, 77, 66),     # CALEN
	"lineup": Rect2(535, 70, 93, 61),       # ALINE
	"tactics": Rect2(345, 101, 93, 63),     # TACTI
	"opponent": Rect2(536, 151, 85, 60),    # RIVAL
	"buy": Rect2(7, 327, 85, 76),           # FICHA
	"sell": Rect2(184, 353, 101, 78),       # VENDE
	"staff": Rect2(6, 403, 72, 62),         # EMPLE
	"finance": Rect2(559, 328, 78, 80),     # CAJA
	"board": Rect2(361, 370, 86, 61),       # DECIS
	"stadium": Rect2(543, 415, 95, 61),     # ESTAD
}
# Reversed control-bar buttons (y=255): action -> Rect2(pos, size).
const CTRL_HITS := {
	"exit": Rect2(6, 255, 79, 27),
	"save": Rect2(92, 255, 114, 27),
	"news": Rect2(437, 255, 95, 27),
	"continue": Rect2(540, 255, 95, 27),
}
# Centre panel band between the two icon bands (x 214..426).
const CX0 := 214
const CX1 := 426

var _bg: Texture2D
var _bezel: Texture2D            # marble fill for the landscape letterbox margins
var _f14: Font
var _f12: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _cash: int = 0
var _position: String = ""
var _press: String = ""        # action currently held down (for the highlight)
var _toast_msg: String = ""    # transient feedback (save / news / next match)


func _ready() -> void:
	_bg = load("res://art/screens/menu_bg.png")
	_bezel = load("res://art/screens/fondo_marble.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the live career chrome (club / manager / season / cash / position), repaint.
func setup(club: String, manager := "", season := "", cash := 0, position := "") -> void:
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_position = position
	queue_redraw()


## Flash a transient line in the centre panel (save / news / next-match feedback) since
## the hub has no green footer to write to. Auto-clears after a couple of seconds.
func toast(msg: String) -> void:
	_toast_msg = msg
	queue_redraw()
	var tree := get_tree()
	if tree != null:
		tree.create_timer(2.5).timeout.connect(_clear_toast)


func _clear_toast() -> void:
	_toast_msg = ""
	queue_redraw()


# ---- geometry ------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

## Map a parent-space point to the 640x480 design space.
func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

## The action whose hit rect contains a design-space point, or "".
func _hit(d: Vector2) -> String:
	for a in CTRL_HITS:
		if (CTRL_HITS[a] as Rect2).has_point(d):
			return a
	for a in ICON_HITS:
		if (ICON_HITS[a] as Rect2).has_point(d):
			return a
	return ""


# ---- input ---------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var pressed := false
	var tap := false
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		pos = mb.position
		pressed = mb.pressed
		tap = true
	elif e is InputEventScreenTouch:
		var st := e as InputEventScreenTouch
		pos = st.position
		pressed = st.pressed
		tap = true
	if not tap:
		return
	if pressed:
		_press = _hit(_to_design(pos))
		queue_redraw()
	else:
		var a := _hit(_to_design(pos))
		var was := _press
		_press = ""
		queue_redraw()
		if a != "" and a == was:
			action_selected.emit(a)


# ---- drawing -------------------------------------------------------------

func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, cw := 0) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x + (cw - w) * 0.5 if cw > 0 else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	# Marble bezel behind the letterboxed 640x480 content (landscape margins).
	if _bezel != null:
		draw_texture_rect(_bezel, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))

	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)

	# Live club panel in the centre gap between the two icon bands.
	var cw := CX1 - CX0
	if _club != "":
		_txt(_f14, CX0, 220, _club.substr(0, 20), C_TITLE, 15, cw)
	if _manager != "":
		_txt(_f12, CX0, 239, _manager.substr(0, 22), C_DIM, 13, cw)
	if _season != "":
		_txt(_f12, CX0, 290, _season, C_DIM, 13, cw)
	var foot := "£%s" % _fmt(_cash)
	if _position != "":
		foot += "   -   %s" % _position
	_txt(_f12, CX0, 306, foot, C_CASH, 13, cw)

	# Press highlight over the held icon / button.
	if _press != "":
		var r: Rect2 = ICON_HITS.get(_press, CTRL_HITS.get(_press, Rect2()))
		if r.size != Vector2.ZERO:
			draw_rect(r, C_HILITE, true)

	# Transient toast in the centre gap (save / news / next-match feedback).
	if _toast_msg != "":
		draw_rect(Rect2(120, 190, 400, 22), Color(0.0, 0.0, 0.0, 0.66), true)
		_txt(_f12, 120, 193, _toast_msg, Color(1.0, 0.95, 0.6), 13, 400)


static func _fmt(v: int) -> String:
	var neg := v < 0
	var t := str(absi(v))
	var out := ""
	var c := 0
	for i in range(t.length() - 1, -1, -1):
		out = t[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if neg else "") + out
