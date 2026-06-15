extends Control
class_name DirectivaScreen
## PM98 BOARD OF DIRECTORS (DIRECTIVA) screen rebuilt from the ORIGINAL game art at
## the coordinates reversed out of MANAGER.EXE (FUN_0050c350 + the bar widget
## FUN_0050b580). See docs/re/directiva_screen_re.md.
##
## Reversed: title BOARD OF DIRECTORS (150,16); the three confidence/rating meters —
## MANAGER RATING (349,107,605,149), SUPPORTERS CONFIDENCE (311,162,605,219) + crowd
## icon, DIRECTORS CONFIDENCE (6,156,297,220) + boardroom icon; the MANAGER caption
## box (47,107); the board-message panel (16,263,380,385) and manager-info panel
## (388,263,625,365); MANAGER INFO label (355,433) + icon and RETURN (515,433).
##
## The three meter VALUES are DERIVED from real career state (position vs the board
## objective + recent form) since the Career model has no stored confidence stat —
## everything else (rects/fonts/colours/assets) is reversed exact. Display-only;
## loans stay in the text menu. Native 640x480, scales to fit its parent.

const W := 640
const H := 480

const C_TITLE := Color(0.96, 0.97, 1.0)
const C_TEXT := Color(0.86, 0.90, 0.96)
const C_DIM := Color(0.59, 0.69, 0.82)
const C_HEAD := Color(0.67, 0.78, 0.92)
const C_LABEL := Color(0.63, 0.63, 0.78)        # FUN_00437020 -> (160,160,200)
const C_PANEL := Color(0.13, 0.21, 0.38)
const C_PANEL_HI := Color(0.27, 0.43, 0.65)
const C_PANEL_LO := Color(0.07, 0.13, 0.26)
const C_TRACK := Color(0.07, 0.11, 0.20)
const C_GOOD := Color(0.36, 0.78, 0.45)
const C_MID := Color(0.92, 0.78, 0.30)
const C_BAD := Color(0.85, 0.34, 0.30)
const C_BTN := Color(0.18, 0.28, 0.47)

# Reversed rects (left,top,right,bottom) -> Rect2(x,y,w,h).
const R_MANAGER := Rect2(47, 107, 251, 42)
const BAR_RATING := Rect2(349, 107, 256, 42)
const BAR_SUPPORT := Rect2(311, 162, 294, 57)
const BAR_DIRECT := Rect2(6, 156, 291, 64)
const PANEL_MSG := Rect2(16, 263, 364, 122)
const PANEL_INFO := Rect2(388, 263, 237, 102)
const LBL_INFO := Rect2(355, 433, 132, 25)
const LBL_RETURN := Rect2(515, 433, 112, 25)

var _bg: Texture2D
var _bar: Texture2D
var _ic_direct: Texture2D
var _ic_public: Texture2D
var _ic_info: Texture2D
var _f14: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _cash: int = 0
var _directors: int = 50
var _supporters: int = 50
var _rating: int = 50
var _objective: String = ""
var _record: String = ""
var _position: String = ""


func _ready() -> void:
	_bg = load("res://art/screens/fondo_marble.png")
	_bar = load("res://art/screens/barra0.png")
	_ic_direct = load("res://art/screens/directiva/directiva.png")
	_ic_public = load("res://art/screens/directiva/publico.png")
	_ic_info = load("res://art/screens/directiva/infomanager.png")
	_f14 = load("res://art/fonts/proman14.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	queue_redraw()


## Feed the screen the live board view, then repaint. Confidence values 0..100.
func setup(club: String, manager: String, season: String, cash: int,
		directors: int, supporters: int, rating: int,
		objective: String, record: String, position: String = "") -> void:
	_club = club
	_manager = manager
	_season = season
	_cash = cash
	_directors = clampi(directors, 0, 100)
	_supporters = clampi(supporters, 0, 100)
	_rating = clampi(rating, 0, 100)
	_objective = objective
	_record = record
	_position = position
	queue_redraw()


# ---- helpers -------------------------------------------------------------

static func fmt_money(v: int) -> String:
	var neg := v < 0
	var s := str(absi(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return "%s£%s" % ["-" if neg else "", out]


static func meter_color(v: int) -> Color:
	if v >= 60:
		return C_GOOD
	if v >= 35:
		return C_MID
	return C_BAD


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


## A confidence meter inside its reversed box: title, icon, horizontal fill, value%.
func _meter(box: Rect2, title: String, value: int, icon: Texture2D) -> void:
	_panel(box)
	var ix := int(box.position.x) + 6
	var inner_x := ix
	if icon != null:
		var iy := int(box.position.y) + int((box.size.y - icon.get_height()) * 0.5)
		draw_texture(icon, Vector2(ix, iy))
		inner_x = ix + icon.get_width() + 8
	_txt(_f10, inner_x, int(box.position.y) + 6, title, C_HEAD, 11)
	# Track + fill bar under the title.
	var track := Rect2(inner_x, box.position.y + box.size.y - 18, box.end.x - inner_x - 10, 10)
	draw_rect(track, C_TRACK, true)
	var fw := track.size.x * (float(value) / 100.0)
	if fw > 0:
		draw_rect(Rect2(track.position.x, track.position.y, fw, track.size.y), meter_color(value), true)
	draw_rect(track, C_PANEL_LO, false)
	_txt(_f8, int(track.end.x), int(track.position.y) - 11, "%d%%" % value, C_TEXT, 10, true)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	if _bg != null:
		draw_texture_rect(_bg, Rect2(Vector2.ZERO, size), false, Color(0.4, 0.4, 0.46))
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _bg != null:
		draw_texture_rect(_bg, Rect2(0, 0, W, H), false)
	if _bar != null:
		draw_texture_rect(_bar, Rect2(0, 0, W, _bar.get_height()), false)

	# Title in the BARRA bar + live chrome corners.
	_txt(_f14, 150, 13, "BOARD OF DIRECTORS", C_TITLE, 15)
	_txt(_f10, 12, 9, "Manager", C_TEXT, 11)
	_txt(_f10, 12, 26, _manager.substr(0, 18) if _manager != "" else _club.substr(0, 18), C_DIM, 11)
	_txt(_f10, 628, 9, _club.substr(0, 18), C_TEXT, 11, true)
	if _season != "":
		_txt(_f10, 628, 26, _season, C_DIM, 11, true)

	# MANAGER caption box (top-left header for the manager panel).
	_panel(R_MANAGER)
	_txt(_f10, int(R_MANAGER.position.x) + 10, int(R_MANAGER.position.y) + 6, "MANAGER", C_TITLE, 11)
	_txt(_f10, int(R_MANAGER.position.x) + 10, int(R_MANAGER.position.y) + 22,
		(_manager if _manager != "" else _club).substr(0, 22), C_DIM, 11)

	# The three reversed confidence/rating meters.
	_meter(BAR_RATING, "MANAGER RATING", _rating, null)
	_meter(BAR_SUPPORT, "SUPPORTERS CONFIDENCE", _supporters, _ic_public)
	_meter(BAR_DIRECT, "DIRECTORS CONFIDENCE", _directors, _ic_direct)

	# Board-message panel (the objective the board expects of you).
	_panel(PANEL_MSG)
	_txt(_f10, int(PANEL_MSG.position.x) + 10, int(PANEL_MSG.position.y) + 8, "THE BOARD EXPECTS", C_HEAD, 11)
	_wrap(_f10, int(PANEL_MSG.position.x) + 10, int(PANEL_MSG.position.y) + 30,
		int(PANEL_MSG.size.x) - 20, _objective, C_TEXT, 12)

	# Manager-info panel (your league standing + record).
	_panel(PANEL_INFO)
	_txt(_f10, int(PANEL_INFO.position.x) + 10, int(PANEL_INFO.position.y) + 8, "YOUR RECORD", C_HEAD, 11)
	if _position != "":
		_txt(_f10, int(PANEL_INFO.position.x) + 10, int(PANEL_INFO.position.y) + 32, "Position: %s" % _position, C_TEXT, 12)
	if _record != "":
		_txt(_f10, int(PANEL_INFO.position.x) + 10, int(PANEL_INFO.position.y) + 50, "Record: %s" % _record, C_TEXT, 12)
	_txt(_f10, int(PANEL_INFO.position.x) + 10, int(PANEL_INFO.position.y) + 68, "Bank: %s" % fmt_money(_cash), C_TEXT, 12)

	# Bottom buttons: MANAGER INFO (+icon) and RETURN, in the reversed periwinkle.
	_panel(LBL_INFO, C_BTN)
	var info_x := int(LBL_INFO.position.x) + 8
	if _ic_info != null:
		draw_texture(_ic_info, Vector2(info_x,
			LBL_INFO.position.y + (LBL_INFO.size.y - _ic_info.get_height()) * 0.5))
		info_x += _ic_info.get_width() + 6
	_txt(_f10, info_x, int(LBL_INFO.position.y) + 6, "MANAGER INFO", C_LABEL, 11)
	_panel(LBL_RETURN, C_BTN)
	_txt(_f10, int(LBL_RETURN.position.x) + int(LBL_RETURN.size.x * 0.5) - 24,
		int(LBL_RETURN.position.y) + 6, "RETURN", C_LABEL, 11)


## Word-wrap a string inside a width, line height ~ font ascent+descent.
func _wrap(f: Font, x: int, y_top: int, w: int, s: String, col: Color, sz: int) -> void:
	if f == null or s == "":
		return
	var lh := int(f.get_ascent(sz) + f.get_descent(sz)) + 2
	var line := ""
	var y := y_top
	for word in s.split(" ", false):
		var probe := word if line == "" else line + " " + word
		if f.get_string_size(probe, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > w and line != "":
			_txt(f, x, y, line, col, sz)
			y += lh
			line = word
		else:
			line = probe
	if line != "":
		_txt(f, x, y, line, col, sz)
