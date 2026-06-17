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

# The managed club's kit (escudo), drawn in the centre panel above the club name. PM98
# shows the club kit on MENUPRINCIPAL; the reversed menu_bg carries no kit, it's dynamic.
const KIT_SRC := Rect2(0, 0, 31, 64)        # shirt half of the 48x64 MINIESC kit
const KIT_BOX := Rect2(298, 150, 44, 60)    # centred on the CX0..CX1 column, above the name

var _bg: Texture2D
var _bezel: Texture2D            # marble fill for the landscape letterbox margins
var _f14: Font
var _f12: Font
var _kit_tex: Texture2D          # the managed club's kit, or null if no art for the id

var _club: String = ""
var _club_id: int = -1
var _manager: String = ""       # the caller passes the league name here (no manager name modelled)
var _season: String = ""
var _cash: int = 0
var _position: String = ""
var _week: int = 0
var _opp_name: String = ""      # next-fixture opponent (central stack, replaces the cash figure)
var _opp_id: int = -1
var _is_home: bool = true
var _opp_tex: Texture2D
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


## Feed the live career chrome (club / league / season / cash / position + the next-fixture
## opponent for the central stack + week for the calendar plaque), repaint.
func setup(club: String, manager := "", season := "", cash := 0, position := "", club_id := -1,
		week := 0, opp_name := "", opp_id := -1, is_home := true) -> void:
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_position = position
	_week = week
	_opp_name = opp_name
	_is_home = is_home
	if club_id != _club_id:
		_club_id = club_id
		var path := "res://art/kits/%d.png" % club_id
		_kit_tex = load(path) if club_id >= 0 and ResourceLoader.exists(path) else null
	if opp_id != _opp_id:
		_opp_id = opp_id
		var op := "res://art/kits/%d.png" % opp_id
		_opp_tex = load(op) if opp_id >= 0 and ResourceLoader.exists(op) else null
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

	# Shared plaque header overlaid on the baked bg's empty navy top strip (manager+club /
	# calendar date / league+week), with the MANAGER MENU title. (_manager carries the
	# league name; manager-name is not modelled, so the left plaque centres the club.)
	PMChrome.draw_header(self, "MANAGER MENU", "", _club, _manager, _season, _week, _club_id)

	# The managed club's kit (escudo), centred above the central stack.
	if _kit_tex != null:
		var sc: float = min(KIT_BOX.size.x / KIT_SRC.size.x, KIT_BOX.size.y / KIT_SRC.size.y)
		var kw := KIT_SRC.size.x * sc
		var kh := KIT_SRC.size.y * sc
		draw_texture_rect_region(_kit_tex,
			Rect2(KIT_BOX.position.x + (KIT_BOX.size.x - kw) * 0.5,
				KIT_BOX.position.y + (KIT_BOX.size.y - kh) * 0.5, kw, kh), KIT_SRC)

	# Central stack: managed club + league + position, then the next-fixture opponent
	# (with its crest) — the real game's centre panel, NOT the cash figure the remake showed.
	var cw := CX1 - CX0
	if _club != "":
		_txt(_f14, CX0, 214, _club.substr(0, 20), C_TITLE, 15, cw)
	var sub := _manager
	if _position != "":
		sub = "%s   -   %s" % [_manager, _position] if _manager != "" else _position
	if sub != "":
		_txt(_f12, CX0, 233, sub.substr(0, 28), C_DIM, 12, cw)
	if _opp_name != "":
		if _opp_tex != null:
			var os: float = min(26.0 / KIT_SRC.size.x, 34.0 / KIT_SRC.size.y)
			draw_texture_rect_region(_opp_tex,
				Rect2(CX0 + 22, 262, KIT_SRC.size.x * os, KIT_SRC.size.y * os), KIT_SRC)
		_txt(_f12, CX0 + 6, 264, "%s" % ("vs" if _is_home else "at"), C_DIM, 12, cw)
		_txt(_f14, CX0, 282, _opp_name.substr(0, 20), C_TITLE, 14, cw)

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
