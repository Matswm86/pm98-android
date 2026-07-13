extends Control
class_name DirectivaScreen
## PM98 BOARD OF DIRECTORS (DIRECTIVA) screen — frame-baked from the real MANAGER.EXE
## walkthrough frame `screenshots/original-walkthrough-2026-07-02/167_154921.png`
## (layout = decompile FUN_0050c350 / FUN_0050b580 / FUN_0050b5f0 / FUN_0050ae90;
## docs/re/directiva_screen_re.md). The whole body — stadium backdrop, MANAGER +
## MANAGER RATING / DIRECTORS CONFIDENCE / SUPPORTERS CONFIDENCE label bars, the two
## director + crowd figure icons, the APPLY FOR LOAN empty form, the BONUS panel (Win
## bonus / for Champion, each with flechal/flechar spinners + OK) and RETURN — is baked
## pixel-exact into art/screens/directiva/body.png and drawn 1:1. The scene draws live,
## over blanked baked fields, ONLY the values the game reads from club state:
##   - the MANAGER name (into the navy name box)
##   - the three segmented red->brown meters + their value number (into the white bars).
##
## SOURCE NOTE (pm98_stay_true_to_original): the original reads three stored club stats
## (team +0x2c/+0x30/+0x34, each /100) that the Career model does NOT keep, so the meter
## values are an HONEST PROXY derived from real career state (Main._board_panel: league
## position vs board objective + recent form), NOT a reversed constant. The APPLY FOR LOAN
## rows and BONUS amounts are likewise unmodelled -> the baked form stays empty / £0 (the
## witnessed no-loan, no-bonus state). Display-only; RETURN dismisses.
## Native 640x480; scales to fit its parent.

signal back_pressed    # RETURN only -> dismiss

const W := 640
const H := 480
const BODY_Y := 44.0                       # body.png is the frame cropped from y=44 down

const C_NAME := Color(0.96, 0.98, 1.0)     # white manager name on the navy box
const C_VALUE := Color(0.0, 0.0, 0.502)    # navy meter value digit (0,0,128)

# RETURN hit rect (decompile pos 515,433 size 112,25; baked into body.png).
const BTN_RETURN := Rect2(515, 433, 112, 25)
# MANAGER name box interior (decompile 47,107 size 251,42; the navy sub-box).
const MGR_BOX := Rect2(49, 125, 246, 21)

## Per-meter live-draw geometry, measured off frame 167_154921 (block strip + value tab):
## bx/by = first block top-left, dx/dy = value-digit centre, maxb = blocks that fit before
## the tab. Blocks are 15x17 on an 18px pitch (matches the pico.bmp segment cadence).
const BLOCK_W := 15
const BLOCK_H := 17
const BLOCK_PITCH := 18
const M_RATING := {"bx": 375, "by": 127, "dx": 581, "dy": 135, "maxb": 9}
const M_DIRECTORS := {"bx": 67, "by": 189, "dx": 270, "dy": 198, "maxb": 9}
const M_SUPPORTERS := {"bx": 366, "by": 189, "dx": 580, "dy": 198, "maxb": 10}

## Segment palette, red -> brown, sampled from the frame's five filled blocks and extended
## toward brown for the higher indices (block[i] colour depends on position, not value).
const BLOCK_COLS: Array[Color] = [
	Color(1.0, 0.0, 0.0), Color(0.824, 0.0, 0.0), Color(0.831, 0.247, 0.0),
	Color(0.831, 0.247, 0.0), Color(0.667, 0.247, 0.0), Color(0.588, 0.247, 0.0),
	Color(0.549, 0.286, 0.086), Color(0.529, 0.286, 0.086), Color(0.471, 0.259, 0.078),
	Color(0.431, 0.235, 0.078),
]

var _body: Texture2D
var _f14: Font
var _f12: Font
var _f10: Font
var _f8: Font

var _club: String = ""
var _manager: String = ""
var _season: String = ""
var _league: String = ""
var _cash: int = 0
var _directors: int = 50
var _supporters: int = 50
var _rating: int = 50
var _week: int = 0


func _ready() -> void:
	_body = load("res://art/screens/directiva/body.png") if ResourceLoader.exists("res://art/screens/directiva/body.png") else null
	_f14 = load("res://art/fonts/proman14.fnt")
	_f12 = load("res://art/fonts/proman12.fnt")
	_f10 = load("res://art/fonts/proman10.fnt")
	_f8 = load("res://art/fonts/proman8.fnt")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


# ---- input ---------------------------------------------------------------
## RETURN dismisses; every other tap is a no-op (the board is display-only, so reading it
## must not bounce back to the hub the way the old free-on-any-tap overlay did).
func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		return
	if BTN_RETURN.has_point(_to_design(e.position)):
		back_pressed.emit()


## `manager`/`club` are the header identity; `directors`/`supporters`/`rating` are the
## 0..100 derived proxies (Main._board_panel). `objective`/`record`/`position` are accepted
## for call-site compatibility but the board screen has no reversed field for them (the
## bottom panels are APPLY FOR LOAN + BONUS, not an objective read-out).
func setup(club: String, manager: String, season: String, cash: int,
		directors: int, supporters: int, rating: int,
		objective: String = "", record: String = "", position: String = "",
		week: int = 0, league: String = "") -> void:
	_club = club
	_manager = manager
	_season = season
	_league = league
	_cash = cash
	_directors = clampi(directors, 0, 100)
	_supporters = clampi(supporters, 0, 100)
	_rating = clampi(rating, 0, 100)
	_week = week
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


func _centre(f: Font, r: Rect2, s: String, col: Color, sz: int) -> void:
	if f == null:
		return
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	draw_string(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + (r.size.y - sz) * 0.5 + f.get_ascent(sz)),
		s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


## One segmented meter: `filled` = round(value/10) blocks (red->brown by index) drawn over
## the baked white bar, then the value number in the baked light-blue value tab.
func _meter(m: Dictionary, value: int) -> void:
	var filled: int = clampi(int(round(value / 10.0)), 0, int(m["maxb"]))
	for i in filled:
		var col: Color = BLOCK_COLS[mini(i, BLOCK_COLS.size() - 1)]
		draw_rect(Rect2(float(m["bx"]) + i * BLOCK_PITCH, float(m["by"]), BLOCK_W, BLOCK_H), col, true)
	if _f12 != null:
		var s := str(filled)
		var tw := _f12.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_f12, Vector2(float(m["dx"]) - tw * 0.5, float(m["dy"]) - 6 + _f12.get_ascent(13)),
			s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_VALUE)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	PMChrome.draw_bg(self)
	# Frame-baked body (stadium backdrop + all static chrome) drawn 1:1 below the barra.
	if _body != null:
		draw_texture(_body, Vector2(0, BODY_Y))
	# Shared header barra on top (club/manager plaque + title + calendar + phase plaque).
	PMChrome.draw_header(self, "BOARD OF DIRECTORS", _manager, _club, _league, _season, _week)

	# Live values over the blanked baked fields.
	if _manager != "":
		_centre(_f12, MGR_BOX, _manager, C_NAME, 13)
	_meter(M_RATING, _rating)
	_meter(M_DIRECTORS, _directors)
	_meter(M_SUPPORTERS, _supporters)
