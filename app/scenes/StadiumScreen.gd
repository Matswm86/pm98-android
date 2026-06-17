extends Control
class_name StadiumScreen
## PM98 GROUND (ESTADIO) overview screen rebuilt from the ORIGINAL game art at the
## coordinates reversed out of MANAGER.EXE (OnDraw FUN_0051a6e0). See
## docs/re/stadium_screen_re.md.
##
## The stadium picture is one of 12 pre-rendered ESTADIO<tier>.BMP scenes (320x240,
## half res). The game picks the tier by capacity:
##   tier = clamp(capacity * 11 / 130000, 0, 11)        (FUN_0051a6e0 @0x51a728)
## and blits it across the reversed client rect CRect(0,0,640,480) at 2x (half-res
## backdrop). The title GROUND (150,16), the info panel (299,73,320,73) and the 2x2
## action grid IMPROVE(298,407) / WORKS(484,407) / MATCH DAY(298,442) / RETURN(488,442)
## are exact-reversed overlays painted on top. Display-only (works/improve/match-day
## stay in the text menu); native 640x480, self-scales + marble-bezels to fit landscape.

signal works_pressed   # the WORKS button -> Main opens the expansion options
signal back_pressed    # RETURN, or a tap on the stadium scene -> dismiss

const W := 640
const H := 480
const MAX_CAPACITY := 130000                    # tier 11 threshold (130000/11 per tier)

const C_TITLE := Color(0.96, 0.97, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_LABEL := Color(0.63, 0.63, 0.78)         # FUN_00437020 -> (160,160,200)
const C_PANEL := Color(0.13, 0.21, 0.38)
const C_PANEL_HI := Color(0.27, 0.43, 0.65)
const C_PANEL_LO := Color(0.07, 0.13, 0.26)
const C_BTN := Color(0.18, 0.28, 0.47)
const C_VAL := Color(0.96, 0.87, 0.47)

# Reversed rects (left,top,w,h) from FUN_0051a6e0.
const PANEL_INFO := Rect2(299, 73, 320, 73)
const LBL_IMPROVE := Rect2(298, 407, 152, 25)
const LBL_WORKS := Rect2(484, 407, 132, 25)
const LBL_MATCHDAY := Rect2(298, 442, 152, 25)
const LBL_RETURN := Rect2(488, 442, 124, 25)

var _bg: Texture2D
var _bar: Texture2D
var _scene: Texture2D
var _ic_works: Texture2D
var _ic_improve: Texture2D
var _ic_match: Texture2D
var _f14: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _ground: String = ""
var _capacity: int = 0
var _seated: int = 0
var _standing: int = 0
var _parking: int = 0
var _tier: int = 0
var _works: String = ""     # in-progress expansion status (e.g. "+5,000 in 12 wk"), or ""
var _press := ""            # button held down (for the highlight)


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_ic_works = load("res://art/screens/stadium/obras.png")
	_ic_improve = load("res://art/screens/stadium/remodela.png")
	_ic_match = load("res://art/screens/stadium/diapartido.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	_load_scene()
	queue_redraw()


## tier = clamp(capacity * 11 / 130000, 0, 11) — reversed FUN_0051a6e0 @0x51a728.
static func tier_for(capacity: int) -> int:
	return clampi(capacity * 11 / MAX_CAPACITY, 0, 11)


func _load_scene() -> void:
	_tier = tier_for(_capacity)
	_scene = load("res://art/screens/stadium/estadio%d.png" % _tier)


## Feed the screen the live ground view, then repaint.
func setup(club: String, manager: String, season: String, ground: String,
		capacity: int, seated: int, standing: int, parking: int, works := "") -> void:
	_club = club
	_manager = manager
	_season = season
	_ground = ground
	_capacity = maxi(0, capacity)
	_seated = maxi(0, seated)
	_standing = maxi(0, standing)
	_parking = maxi(0, parking)
	_works = works
	_load_scene()
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

## WORKS opens the expansion options; RETURN or a tap on the scene dismisses; IMPROVE /
## MATCH DAY are inert (not yet built) so they neither act nor dismiss.
func _hit(d: Vector2) -> String:
	if LBL_WORKS.has_point(d):
		return "works"
	if LBL_RETURN.has_point(d):
		return "return"
	if LBL_IMPROVE.has_point(d) or LBL_MATCHDAY.has_point(d):
		return "inert"
	return "dismiss"

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
	else:
		var a := _hit(d)
		var was := _press
		_press = ""
		queue_redraw()
		if a != was:
			return
		match a:
			"works": works_pressed.emit()
			"return", "dismiss": back_pressed.emit()


# ---- helpers -------------------------------------------------------------

static func fmt_int(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _panel(r: Rect2, base := C_PANEL) -> void:
	draw_rect(r, base, true)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1), C_PANEL_HI, true)
	draw_rect(Rect2(r.position.x, r.position.y, 1, r.size.y), C_PANEL_HI, true)
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), C_PANEL_LO, true)
	draw_rect(Rect2(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), C_PANEL_LO, true)


func _button(r: Rect2, label: String, icon: Texture2D) -> void:
	_panel(r, C_BTN)
	var tx := int(r.position.x) + 8
	if icon != null:
		draw_texture(icon, Vector2(tx, r.position.y + (r.size.y - icon.get_height()) * 0.5))
		tx += icon.get_width() + 6
	_txt(_f10, tx, int(r.position.y) + 6, label, C_LABEL, 11)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	# Darkened-marble bezel across the full node rect (landscape pillarbox).
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Half-res ESTADIO<tier> scene fills the reversed client rect at 2x, then BARRA chrome.
	if _scene != null:
		draw_texture_rect(_scene, Rect2(0, 0, W, H), false)
	elif _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	# Title in the BARRA bar + live chrome corners.
	_txt(_f14, 150, 13, "GROUND", C_TITLE, 15)
	_txt(_f10, 12, 9, "Manager", C_TEXT, 11)
	_txt(_f10, 12, 26, (_manager if _manager != "" else _club).substr(0, 18), C_DIM, 11)
	_txt(_f10, 628, 9, _club.substr(0, 18), C_TEXT, 11, true)
	if _season != "":
		_txt(_f10, 628, 26, _season, C_DIM, 11, true)

	# Right info panel: ground name + the capacity readout that drives the tier.
	_panel(PANEL_INFO)
	var ix := int(PANEL_INFO.position.x) + 10
	var iy := int(PANEL_INFO.position.y) + 6
	var rx := int(PANEL_INFO.end.x) - 10
	var midx := int(PANEL_INFO.position.x + PANEL_INFO.size.x * 0.5)
	_txt(_f10, ix, iy, (_ground if _ground != "" else _club).to_upper().substr(0, 22), C_HEAD, 11)
	_txt(_f8, ix, iy + 18, "CAPACITY", C_DIM, 10)
	_txt(_f8, rx, iy + 18, fmt_int(_capacity), C_VAL, 10, true)
	_txt(_f8, ix, iy + 32, "SEATS", C_DIM, 10)
	_txt(_f8, midx - 6, iy + 32, fmt_int(_seated), C_TEXT, 10, true)
	_txt(_f8, midx + 6, iy + 32, "CAR PARK", C_DIM, 10)
	_txt(_f8, rx, iy + 32, fmt_int(_parking), C_TEXT, 10, true)
	_txt(_f8, ix, iy + 46, "STAND.  " + fmt_int(_standing), C_DIM, 10)
	_txt(_f8, rx, iy + 46, "TIER %d/11" % _tier, C_DIM, 10, true)

	# In-progress expansion banner above the button grid.
	if _works != "":
		_txt(_f8, 298, 392, "GROUND WORKS:  %s remaining" % _works, C_VAL, 10)

	# 2x2 action grid (each button + its reversed icon).
	_button(LBL_IMPROVE, "IMPROVE", _ic_improve)
	_button(LBL_WORKS, "WORKS", _ic_works)
	_button(LBL_MATCHDAY, "MATCH DAY", _ic_match)
	_button(LBL_RETURN, "RETURN", null)

	# Press highlight over the held button.
	var hit := {"works": LBL_WORKS, "return": LBL_RETURN, "improve": LBL_IMPROVE}
	if _press in ["works", "return"]:
		draw_rect(hit[_press], Color(1, 1, 1, 0.18), true)
