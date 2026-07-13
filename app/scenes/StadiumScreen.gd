extends Control
class_name StadiumScreen
## PM98 GROUND (ESTADIO) overview, rebuilt frame-true from the ORIGINAL game.
##
## Binding frame: screenshots/original-walkthrough-2026-07-02/172_154930.png — the real
## MANAGER.EXE GROUND overview (default "WORK IN PROGRESS" state). The body chrome is baked
## 1:1 from that frame (tools/re/build_stadium_chrome_from_frames.py -> chrome.png): the LEFT
## "WORK IN PROGRESS" panel (SEATS / CAR PARK / FACILITIES / SERVICES sections with their
## TO BE PAID / WEEK columns + the fixed facility rows + TOTAL IMPROVEMENTS), the RIGHT green
## ground-name header + CAPACITY / CAR PARK / PITCH table over the pre-rendered ESTADIO<tier>
## scene, and the IMPROVE / WORKS / MATCH DAY / RETURN action grid. The shared BARRA header
## (PMChrome.draw_header) and marble background (PMChrome.draw_bg) render underneath, as on
## every other career screen.
##
## The PRIOR build was rejected as invented: it showed a "MATCH DAY" ticket-price stepper and
## a "SPONSOR BOARDS" price slider and a CAPACITY/CAR PARK/PITCH="NORMAL" readout that appear
## on NO GROUND-overview frame (ticket price / sponsor boards live on the separate GROUND
## MATCH DAY sub-screen, run-3 capture). All of it is gone.
##
## Only club-specific values are drawn over the baked chrome, from the real Career model:
##   - ground name (GameDB club.stadium) in the green header
##   - CAPACITY (Career.stadium_capacity)  -> "<n> seats"
##   - the ESTADIO<tier> picture (tier = clamp(capacity*11/130000, 0, 11), reversed
##     FUN_0051a6e0), drawn 1:1 at (299,148,320,240) over the baked Old-Trafford tile
## CAR PARK spaces and PITCH quality are NOT in game_db.json (only 15/476 clubs even carry a
## real capacity) -> honest gaps, left blank rather than fabricated (the prior cap/27 car-park
## and "NORMAL" pitch were invented). Native 640x480.

signal works_pressed   # IMPROVE or WORKS -> Main opens the ground-expansion lever
signal back_pressed    # RETURN only -> dismiss (empty taps do not bounce to the hub)

const W := 640
const H := 480
const MAX_CAPACITY := 130000

# The ESTADIO<tier> scene box, pixel-measured off frame 172 (320x240 tile, drawn 1:1 over
# the baked Old-Trafford picture so any tier fully covers it — no bleed).
const SCENE_BOX := Rect2(299, 148, 320, 240)
# Dynamic-text anchors, measured off frame 172 (see docs/re/stadium_screen_re.md).
const R_GROUND := Rect2(299, 71, 320, 20)        # green header, ground name (centred)
const R_CAP_VAL := Rect2(412, 94, 200, 15)       # CAPACITY value cell (left-aligned)
const R_TOTAL := Rect2(150, 452, 126, 13)        # TOTAL IMPROVEMENTS money cell (right)
const R_SEATS_VAL := Rect2(150, 118, 128, 14)    # SEATS row value span (active-works line)

# Action-grid hit rects, reversed from FUN_0051a6e0 (the baked icons/labels are frame pixels).
const BTN_IMPROVE := Rect2(298, 407, 152, 25)
const BTN_WORKS := Rect2(484, 407, 132, 25)
const BTN_MATCHDAY := Rect2(298, 442, 152, 25)
const BTN_RETURN := Rect2(488, 442, 124, 25)

# Frame-sampled text colours.
const C_GROUND_TXT := Color8(255, 255, 255)
const C_VALUE_TXT := Color8(200, 220, 240)
const C_TOTAL_RED := Color8(170, 0, 0)
const C_SEATS_INK := Color8(40, 60, 130)         # SEATS section blue (matches its column heads)
const C_PRESS := Color(1, 1, 1, 0.18)

var _chrome: Texture2D
var _scene: Texture2D
var _f12: Font
var _f10: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _ground: String = ""
var _league: String = ""
var _capacity: int = 0
var _tier: int = 0
var _week: int = 0
var _works: String = ""
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/stadium/chrome.png")
	_f12 = PMChrome.font("12")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	_load_scene()
	queue_redraw()


static func tier_for(capacity: int) -> int:
	return clampi(capacity * 11 / MAX_CAPACITY, 0, 11)


func _load_scene() -> void:
	_tier = tier_for(_capacity)
	var p := "res://art/screens/stadium/estadio%d.png" % _tier
	_scene = load(p) if ResourceLoader.exists(p) else null


## Signature preserved for Main._show_stadium_screen (13 args). Only club / manager / season /
## ground / capacity / works / week / league are used now; seated / standing / parking / ticket
## / board are ignored — they fed the removed invented ticket-price + sponsor + split readouts.
func setup(club: String, manager: String, season: String, ground: String,
		capacity: int, _seated: int, _standing: int, _parking: int, works := "",
		_ticket := 0, _board := 0, week := 0, league := "") -> void:
	_club = club
	_manager = manager
	_season = season
	_ground = ground
	_league = league
	_capacity = maxi(0, capacity)
	_week = week
	_works = works
	_load_scene()
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _hit(d: Vector2) -> String:
	# Frame-true, IMPROVE (category picker) and WORKS (in-progress view) differ, but both
	# reach the one modelled expansion lever (Main owns that dialog); WORKS keeps the "works"
	# id the works test asserts. RETURN leaves. MATCH DAY is inert (disabled/washed in the
	# frame) and an empty-space tap is a no-op (it used to bounce to the hub mid-reading).
	if BTN_WORKS.has_point(d):
		return "works"
	if BTN_IMPROVE.has_point(d):
		return "improve"
	if BTN_RETURN.has_point(d):
		return "return"
	return ""


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
			"works", "improve": works_pressed.emit()
			"return": back_pressed.emit()


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


## Draw `s` in rect `r`, vertically centred; align left (default), right, or centre.
func _cell(f: Font, r: Rect2, s: String, col: Color, sz: int, align := "left") -> void:
	if f == null or s == "":
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := r.position.x
	if align == "right":
		px = r.end.x - w
	elif align == "centre":
		px = r.position.x + (r.size.x - w) * 0.5
	var py := r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)
	draw_string(f, Vector2(px, py), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Shared chrome (same as every career screen), then the frame-baked body over it.
	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "GROUND", _manager, _club, _league, _season, _week, -1)
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)

	# ESTADIO<tier> scene, 1:1 over the baked (Old Trafford) tile.
	if _scene != null:
		draw_texture_rect(_scene, SCENE_BOX, false)

	# Green header: the ground name (GameDB club.stadium; club as a fallback).
	_cell(_f12, R_GROUND, _ground if _ground != "" else _club, C_GROUND_TXT, 13, "centre")

	# CAPACITY value (real Career). CAR PARK / PITCH stay blank — uncaptured, honest gaps.
	_cell(_f10, R_CAP_VAL, "%s seats" % fmt_int(_capacity), C_VALUE_TXT, 11)

	# TOTAL IMPROVEMENTS: £0 in the default state. An in-progress expansion (Career.works)
	# has no £ amount threaded here (Main passes only a status string) -> the SEATS row shows
	# the status; the money total stays honest at £0 (see WIRING note in stadium_screen_re.md).
	_cell(_f10, R_TOTAL, "£0", C_TOTAL_RED, 11, "right")
	if _works != "":
		_cell(_f10, R_SEATS_VAL, _works, C_SEATS_INK, 9, "centre")

	# Press feedback over the baked buttons.
	match _press:
		"improve": draw_rect(BTN_IMPROVE, C_PRESS, true)
		"works": draw_rect(BTN_WORKS, C_PRESS, true)
		"return": draw_rect(BTN_RETURN, C_PRESS, true)
