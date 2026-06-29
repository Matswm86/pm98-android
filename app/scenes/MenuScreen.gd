extends Control
class_name MenuScreen
## PM98 MAIN MENU (MENUPRINCIPAL) screen — the in-career management hub.
##
## The static chrome (the 4 quadrants of colour-coded caption bars + the 12 picture
## icons + the INFORMATION / MANAGER / TRANSFER MARKET / FINANCES section labels + the
## marble background with the BARRA quadrant cross + the EXIT / SAVE GAME / NEWS /
## CONTINUE control bar + the central club CIRCLE frame and its slot boxes) is the REAL
## game's MENUPRINCIPAL, taken from the original 640x480 screen (data/pm98-refs/
## real-gallery/ma_6.png) into art/screens/menu_bg.png with only the club-specific data
## (header text + circle text + the two crests) cleared. The reversed coordinates that
## produced this layout are in docs/re/menu_screen_re.md (FUN_005469c0).
##
## This node blits that chrome, then draws the DYNAMIC layer on top: the shared PMChrome
## header (manager / club / date / league / week) and the central circle's live slots
## (league position, manager, managed club + crest, next opponent + crest, opponent
## manager / venue, CPU). Taps over an icon, its caption bar or a control button emit
## `action_selected(action)` (Main routes it). Native 640x480; scales to fit (NEAREST).

signal action_selected(action: String)

const W := 640
const H := 480

const C_TITLE := Color(0.96, 0.98, 1.0)
const C_DIM := Color(0.80, 0.86, 0.95)
const C_HILITE := Color(1.0, 1.0, 1.0, 0.22)

# Grey circle-slot chrome (PL / manager / opponent-manager / CPU), matching the real
# beveled boxes baked into menu_bg.
const C_SLOT := Color(0.40, 0.40, 0.44)
const C_SLOT_HI := Color(0.60, 0.60, 0.65)
const C_SLOT_LO := Color(0.17, 0.17, 0.21)
# Blue-grey name band (managed club / next opponent), with a pale border and white text.
const C_BAND := Color(0.30, 0.40, 0.58)
const C_BAND_HI := Color(0.62, 0.72, 0.88)
const C_BAND_LO := Color(0.13, 0.20, 0.36)

# Reversed icon hit areas: action -> the icon PICTURE rect (pos, size) from the two
# FUN_00436fb0(x,y) points (docs/re/menu_screen_re.md). Non-overlapping; each sits on the
# visible icon in menu_bg.
const ICON_HITS := {
	"results": Rect2(7, 71, 86, 60),        # MARCA
	"table": Rect2(206, 93, 87, 72),        # CLASI
	"fixtures": Rect2(10, 147, 77, 66),     # CALEN
	"lineup": Rect2(535, 70, 93, 61),       # ALINE
	"tactics": Rect2(345, 101, 93, 63),     # TACTI
	"opponent": Rect2(536, 151, 85, 60),    # RIVAL
	"buy": Rect2(7, 327, 85, 76),           # FICHA  (caption "TRANSFERS")
	"sell": Rect2(184, 353, 101, 78),       # VENDE  (caption "PLAYERS")
	"staff": Rect2(6, 403, 72, 62),         # EMPLE
	"finance": Rect2(559, 328, 78, 80),     # CAJA
	"board": Rect2(361, 370, 86, 61),       # DECIS  (caption "BOARD ROOM")
	"stadium": Rect2(543, 415, 95, 61),     # ESTAD  (caption "GROUND")
}
# The colour caption bar beside each icon (measured off ma_6). Added to each icon's hit
# area so a tap on the visible label works too — bigger, unambiguous mobile targets.
const BAR_HITS := {
	"results": Rect2(95, 84, 132, 26),
	"table": Rect2(100, 127, 132, 26),
	"fixtures": Rect2(88, 171, 122, 26),
	"lineup": Rect2(418, 84, 122, 26),
	"tactics": Rect2(428, 127, 114, 26),
	"opponent": Rect2(408, 171, 132, 26),
	"buy": Rect2(50, 343, 132, 26),
	"sell": Rect2(85, 385, 114, 26),
	"staff": Rect2(20, 428, 165, 26),
	"finance": Rect2(446, 344, 114, 26),
	"board": Rect2(432, 387, 178, 26),
	"stadium": Rect2(350, 428, 132, 26),
}
# Control-bar buttons (measured off ma_6: y~246, h~38).
const CTRL_HITS := {
	"exit": Rect2(6, 246, 80, 38),
	"save": Rect2(90, 246, 114, 38),
	"news": Rect2(430, 246, 118, 38),
	"continue": Rect2(552, 246, 86, 38),
}

# Central club CIRCLE slots (design space; over the real frame in menu_bg).
const KIT_SRC := Rect2(0, 0, 31, 64)        # shirt half of the 48x64 MINIESC kit
const R_PL := Rect2(300, 171, 52, 19)       # league position  ("PL 1")
const R_MGR := Rect2(252, 191, 146, 22)     # the manager's name
const R_CLUB := Rect2(248, 214, 156, 28)    # managed club name band
const R_CLUB_CREST := Rect2(226, 214, 30, 40)
const R_OPP := Rect2(248, 263, 156, 28)     # next-opponent name band
const R_OPP_CREST := Rect2(398, 262, 30, 40)
const R_OPPMGR := Rect2(256, 303, 135, 20)  # opponent manager / venue
const R_CPU := Rect2(300, 326, 52, 19)      # opponent control type ("CPU")

var _bg: Texture2D
var _bezel: Texture2D            # marble fill for the landscape letterbox margins
var _f10: Font
var _f12: Font
var _f14: Font
var _kit_tex: Texture2D          # the managed club's kit, or null if no art for the id

var _club: String = ""
var _club_id: int = -1
var _league: String = ""        # league name (header right plaque)
var _manager_name: String = ""  # the real manager name (SELECCION); header left + circle
var _season: String = ""
var _cash: int = 0
var _position: String = ""      # "1st" / "2nd" ...
var _week: int = 0
var _opp_name: String = ""      # next-fixture opponent (circle)
var _opp_id: int = -1
var _opp_manager: String = ""   # next-fixture opponent manager (circle), if known
var _is_home: bool = true
var _opp_tex: Texture2D
var _press: String = ""        # action currently held down (for the highlight)
var _toast_msg: String = ""    # transient feedback (save / news / next match)


func _ready() -> void:
	_bg = load("res://art/screens/menu_bg.png")
	_bezel = load("res://art/screens/fondo_marble.png")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f14 = load("res://art/fonts/proman14.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## Feed the live career chrome (club / league / season / cash / position + the next-fixture
## opponent + week + the opponent manager for the circle's lower slot), repaint.
func setup(club: String, league := "", season := "", cash := 0, position := "", club_id := -1,
		week := 0, opp_name := "", opp_id := -1, is_home := true, manager_name := "",
		opp_manager := "") -> void:
	_club = club
	_league = league
	_manager_name = manager_name
	_season = season
	_cash = cash
	_position = position
	_week = week
	_opp_name = opp_name
	_opp_manager = opp_manager
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


## Flash a transient line in the centre circle (save / news / next-match feedback) since
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

## The action whose hit rect (control / icon picture / caption bar) contains a
## design-space point, or "".
func _hit(d: Vector2) -> String:
	for a in CTRL_HITS:
		if (CTRL_HITS[a] as Rect2).has_point(d):
			return a
	for a in ICON_HITS:
		if (ICON_HITS[a] as Rect2).has_point(d):
			return a
	for a in BAR_HITS:
		if (BAR_HITS[a] as Rect2).has_point(d):
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
	if cw > 0 and w > cw:           # shrink to fit the box rather than clip
		sz = maxi(7, int(floor(sz * cw / w)))
		w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x + (cw - w) * 0.5 if cw > 0 else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## A beveled rect: solid base, light top/left edge, dark bottom/right edge.
func _bevel(r: Rect2, base: Color, hi: Color, lo: Color) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), hi, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), hi, true)
	draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), lo, true)
	draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), lo, true)


## A grey circle slot (PL / manager / opp-manager / CPU) with centred text.
func _slot(r: Rect2, s: String, f: Font, sz: int) -> void:
	if s == "":
		return
	_bevel(r, C_SLOT, C_SLOT_HI, C_SLOT_LO)
	_txt(f, int(r.position.x) + 3, int(r.position.y) + int((r.size.y - sz) * 0.5) - 1,
		s, C_TITLE, sz, int(r.size.x) - 6)


## A blue-grey name band (managed club / next opponent) with a pale border + white text.
func _band(r: Rect2, s: String, f: Font, sz: int) -> void:
	if s == "":
		return
	_bevel(r, C_BAND, C_BAND_HI, C_BAND_LO)
	_txt(f, int(r.position.x) + 4, int(r.position.y) + int((r.size.y - sz) * 0.5) - 1,
		s, C_TITLE, sz, int(r.size.x) - 8)


## A club kit (escudo) fitted, aspect-preserved, into a circle crest box.
func _crest(tex: Texture2D, box: Rect2) -> void:
	if tex == null:
		return
	var sc: float = min(box.size.x / KIT_SRC.size.x, box.size.y / KIT_SRC.size.y)
	var kw := KIT_SRC.size.x * sc
	var kh := KIT_SRC.size.y * sc
	draw_texture_rect_region(tex,
		Rect2(box.position.x + (box.size.x - kw) * 0.5,
			box.position.y + (box.size.y - kh) * 0.5, kw, kh), KIT_SRC)


## "PL n" from the ordinal position string ("1st" -> "PL 1"); "" when unknown.
func _pl_text() -> String:
	var digits := ""
	for c in _position:
		if c >= "0" and c <= "9":
			digits += c
	return "PL %s" % digits if digits != "" else ""


func _draw() -> void:
	# Marble bezel behind the letterboxed 640x480 content (landscape margins).
	if _bezel != null:
		draw_texture_rect(_bezel, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))

	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	# The real MENUPRINCIPAL chrome (bars + icons + section labels + circle frame + bg).
	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)

	# Shared PM98 plaque header over the cleared top band (manager+club / date / league+week).
	PMChrome.draw_header(self, "MANAGER MENU", _manager_name, _club, _league, _season, _week, _club_id)

	# Central club circle: live slots over the real frame in menu_bg.
	_slot(R_PL, _pl_text(), _f10, 11)
	_slot(R_MGR, _manager_name, _f12, 13)
	_band(R_CLUB, _club, _f14, 16)
	_crest(_kit_tex, R_CLUB_CREST)
	if _opp_name != "":
		_band(R_OPP, _opp_name, _f14, 16)
		_crest(_opp_tex, R_OPP_CREST)
		var lower := _opp_manager if _opp_manager != "" else ("HOME" if _is_home else "AWAY")
		_slot(R_OPPMGR, lower, _f10, 11)
		_slot(R_CPU, "CPU", _f10, 11)

	# Press highlight over the held icon / bar / button.
	if _press != "":
		var r: Rect2 = ICON_HITS.get(_press, BAR_HITS.get(_press, CTRL_HITS.get(_press, Rect2())))
		if r.size != Vector2.ZERO:
			draw_rect(r, C_HILITE, true)

	# Transient toast across the circle centre (save / news / next-match feedback).
	if _toast_msg != "":
		draw_rect(Rect2(240, 232, 170, 22), Color(0.0, 0.0, 0.0, 0.72), true)
		_txt(_f12, 240, 235, _toast_msg, Color(1.0, 0.95, 0.6), 12, 170)
