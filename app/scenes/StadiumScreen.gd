extends Control
class_name StadiumScreen
## PM98 GROUND (ESTADIO) screen, rebuilt to match the real game (ma_15): the shared
## PMChrome plaque header + blue marble background over a TWO-COLUMN layout — left a
## white MATCH DAY card (ground / league / fixture + the TICKET PRICE stepper) and the
## SPONSOR BOARDS price slider; right the CAPACITY / CAR PARK / PITCH table over the
## pre-rendered ESTADIO<tier> stadium scene — with the IMPROVE / WORKS / MATCH DAY /
## RETURN action grid along the bottom.
##
## The stadium picture is one of 12 pre-rendered ESTADIO<tier>.BMP scenes; the tier is
## tier = clamp(capacity * 11 / 130000, 0, 11) (reversed FUN_0051a6e0). The invented
## SEATS / STAND / TIER readouts the prior build showed are dropped. Native 640x480.

signal works_pressed   # the WORKS button -> Main opens the expansion options
signal back_pressed    # RETURN only -> dismiss (empty taps no longer bounce to the hub)

const W := 640
const H := 480
const MAX_CAPACITY := 130000

const C_MATCHDAY := Color(0.16, 0.28, 0.66)
const C_BLACKBAR := Color(0.07, 0.08, 0.10)
const C_BARTXT := Color(0.94, 0.96, 1.0)
const C_TICKET := Color(0.74, 0.80, 0.88)        # the ticket card body (pale blue-grey)
const C_GREEN_HDR := Color(0.22, 0.50, 0.28)
const C_ROWLBL := Color(0.40, 0.50, 0.66)        # blue-grey label cell
const C_ROWVAL := Color(0.84, 0.88, 0.92)        # light value cell
const C_VALTXT := Color(0.10, 0.16, 0.30)
const C_SLIDER := Color(0.52, 0.74, 0.24)
const C_SLIDER_BG := Color(0.30, 0.34, 0.30)
const C_BOARDLBL := Color(0.70, 0.18, 0.12)      # red "PRICE OF BOARD" label
const C_BTN := Color(0.08, 0.12, 0.24)
const C_BTN_HI := Color(0.32, 0.44, 0.68)
const C_BTN_LO := Color(0.03, 0.06, 0.14)
const C_GOLD := Color(1.0, 0.86, 0.22)
const C_PANEL_TXT := Color(0.88, 0.93, 1.0)
const C_ROW_TXT := Color(0.10, 0.13, 0.22)

const L_PANEL := Rect2(6, 50, 282, 416)
const R_HDR := Rect2(298, 50, 336, 18)
const R_TABLE_Y := 72
const SCENE_BOX := Rect2(298, 126, 336, 274)
const BTN_IMPROVE := Rect2(298, 406, 164, 28)
const BTN_WORKS := Rect2(470, 406, 164, 28)
const BTN_MATCHDAY := Rect2(298, 438, 164, 28)
const BTN_RETURN := Rect2(470, 438, 164, 28)

var _scene: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _ground: String = ""
var _league: String = ""
var _capacity: int = 0
var _parking: int = 0
var _tier: int = 0
var _ticket: int = 0
var _board: int = 0
var _week: int = 0
var _works: String = ""
var _press := ""


func _ready() -> void:
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
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


func setup(club: String, manager: String, season: String, ground: String,
		capacity: int, seated: int, standing: int, parking: int, works := "",
		ticket := 0, board := 0, week := 0, league := "") -> void:
	_club = club
	_manager = manager
	_season = season
	_ground = ground
	_league = league
	_capacity = maxi(0, capacity)
	_parking = maxi(0, parking)
	_ticket = ticket
	_board = board
	_week = week
	_works = works
	_load_scene()
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _hit(d: Vector2) -> String:
	# IMPROVE and WORKS are both "spend on the ground" — the model has one expansion lever
	# (Career.start_works), so both open it. Only RETURN leaves; a tap on empty space or the
	# (unmodelled) MATCH DAY control is a no-op, NOT a dismiss (it was bouncing to the hub).
	if BTN_WORKS.has_point(d) or BTN_IMPROVE.has_point(d):
		return "works"
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
			"works": works_pressed.emit()
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


func _txt(f: Font, x: int, y_top: int, s: String, col: Color, sz: int, right := false) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var px := x - w if right else float(x)
	draw_string(f, Vector2(px, y_top + f.get_ascent(sz)), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _centre(f: Font, r: Rect2, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)),
		s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	PMChrome.draw_header(self, "GROUND", _manager, _club, _league, _season, _week,
		_club_id_guess())

	_draw_left()
	_draw_right()
	_draw_buttons()


func _club_id_guess() -> int:
	return -1   # the ground view carries no club id; header crest omitted


func _draw_left() -> void:
	PMChrome.draw_table_panel(self, L_PANEL)
	_txt(_f14, int(L_PANEL.position.x) + 14, int(L_PANEL.position.y) + 8, "MATCH DAY", C_MATCHDAY, 15)

	# TICKET PRICE black bar + ticket card.
	var tb := Rect2(L_PANEL.position.x + 6, L_PANEL.position.y + 32, L_PANEL.size.x - 12, 16)
	draw_rect(tb, C_BLACKBAR, true)
	_centre(_f10, tb, "TICKET PRICE", C_BARTXT, 11)
	var card := Rect2(L_PANEL.position.x + 6, tb.end.y + 4, L_PANEL.size.x - 12, 96)
	PMChrome.bevel(self, card, C_TICKET, C_TICKET.lightened(0.2), C_TICKET.darkened(0.3))
	_centre(_f10, Rect2(card.position.x, card.position.y + 4, card.size.x, 12),
		(_ground if _ground != "" else _club), C_VALTXT, 11)
	_centre(_f8, Rect2(card.position.x, card.position.y + 18, card.size.x, 10),
		_league if _league != "" else "League", Color(0.32, 0.40, 0.56), 9)
	_centre(_f12, Rect2(card.position.x, card.position.y + 36, card.size.x, 14),
		_club, C_VALTXT, 13)
	# PRICE stepper
	var py := int(card.end.y) - 22
	_txt(_f10, int(card.position.x) + 10, py + 2, "PRICE", C_GOLD.darkened(0.2), 11)
	_stepper(Rect2(card.position.x + 56, py, 16, 16))
	_txt(_f12, int(card.position.x) + 120, py, "£%d" % _ticket, C_VALTXT, 13)
	_stepper(Rect2(card.end.x - 26, py, 16, 16))

	# SPONSOR BOARDS black bar + price slider.
	var sb := Rect2(L_PANEL.position.x + 6, card.end.y + 12, L_PANEL.size.x - 12, 16)
	draw_rect(sb, C_BLACKBAR, true)
	_centre(_f10, sb, "SPONSOR BOARDS", C_BARTXT, 11)
	_txt(_f10, int(L_PANEL.position.x) + 14, int(sb.end.y) + 8, "PRICE OF BOARD", C_BOARDLBL, 11)
	var sl := Rect2(L_PANEL.position.x + 14, sb.end.y + 24, L_PANEL.size.x - 28, 14)
	PMChrome.bevel(self, sl, C_SLIDER_BG, C_SLIDER_BG.lightened(0.2), C_SLIDER_BG.darkened(0.3))
	var frac := clampf(float(_board) / float(maxi(_board, 1) * 1.4), 0.2, 0.95) if _board > 0 else 0.5
	draw_rect(Rect2(sl.position.x + 1, sl.position.y + 1, (sl.size.x - 2) * frac, sl.size.y - 2), C_SLIDER, true)
	_txt(_f10, int(sl.end.x), int(sl.end.y) + 4, "£%s per board" % fmt_int(_board), C_ROW_TXT, 10, true)


func _stepper(r: Rect2) -> void:
	PMChrome.bevel(self, r, C_BTN, C_BTN_HI, C_BTN_LO)


func _draw_right() -> void:
	# Ground-name green header.
	PMChrome.bevel(self, R_HDR, C_GREEN_HDR, C_GREEN_HDR.lightened(0.25), C_GREEN_HDR.darkened(0.4))
	_centre(_f12, R_HDR, (_ground if _ground != "" else _club), Color(0.96, 1.0, 0.94), 13)

	# CAPACITY / CAR PARK / PITCH table.
	var rows := [["CAPACITY", "%s seats" % fmt_int(_capacity)],
		["CAR PARK", "%s spaces" % fmt_int(_parking)],
		["PITCH", "NORMAL"]]
	var y := R_TABLE_Y
	for r in rows:
		var lbl := Rect2(R_HDR.position.x, y, 96, 16)
		var val := Rect2(R_HDR.position.x + 98, y, R_HDR.size.x - 98, 16)
		PMChrome.bevel(self, lbl, C_ROWLBL, C_ROWLBL.lightened(0.2), C_ROWLBL.darkened(0.3))
		PMChrome.bevel(self, val, C_ROWVAL, C_ROWVAL.lightened(0.2), C_ROWVAL.darkened(0.3))
		_txt(_f10, int(lbl.position.x) + 6, y + 2, str(r[0]), C_PANEL_TXT, 11)
		_txt(_f10, int(val.position.x) + 8, y + 2, str(r[1]), C_VALTXT, 11)
		y += 18

	# Stadium scene render inside the right box.
	if _scene != null:
		draw_texture_rect(_scene, SCENE_BOX, false)
	else:
		draw_rect(SCENE_BOX, Color(0.10, 0.20, 0.12), true)
	if _works != "":
		_txt(_f8, int(SCENE_BOX.position.x) + 6, int(SCENE_BOX.position.y) + 4,
			"GROUND WORKS: %s remaining" % _works, C_GOLD, 10)


func _draw_buttons() -> void:
	_button(BTN_IMPROVE, "IMPROVE", false)
	_button(BTN_WORKS, "WORKS", _press == "works")
	_button(BTN_MATCHDAY, "MATCH DAY", false)
	_button(BTN_RETURN, "RETURN", _press == "return")


func _button(r: Rect2, label: String, held: bool) -> void:
	PMChrome.bevel(self, r, C_BTN_HI if held else C_BTN, C_BTN_HI, C_BTN_LO)
	_centre(_f12, r, label, C_GOLD, 13)
