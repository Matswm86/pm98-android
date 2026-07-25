extends Control
class_name EndOfSeasonScreen
## PM98 END OF SEASON — step 4 of the original's season-end sequence (REFRUN R15),
## baked from `tools/re/refs/season-end-2026-07-25/21_end_of_season.png`.
##
## This is the screen whose NAME the port's invented board-verdict sheet used to steal.
## It is a four-division overview: a navy CHAMPION plate with the club's kit on the left,
## a middle column and a RELEGATED column. The Premier alone has a second navy plate
## (RUNNER-UP) and heads its middle column U.E.F.A. CUP instead of PROMOTED; the Third
## Division has no relegation column at all.
##
## The PLATE COUNTS are the chrome's own and are never assumed — Premier 4 middle + 3
## relegated, First 3 + 3, Second 3 + 4, Third 4 + none — and they agree line for line
## with the app's existing `Career.PYRAMID_ZONES`, so the screen is a view of a rule the
## app already had rather than a new one.
##
## Text, solved with tools/re/probe_text_anchor.py at ZERO differing pixels: everything
## is proman8. The middle and relegated plates centre on `x0 + x1 + 1`. The champion
## plates are LEFT-aligned, and their pen x is 50 / 50 / 49 / 49 / 48 down the five
## plates — a 1px ladder the single captured frame does not explain, so the witnessed
## values are carried verbatim rather than smoothed into an invented rule.
##
## Chrome: tools/re/build_seasonend_year_chrome_from_frames.py
## Render-diff: tools/re/diff_seasonend_year_parity.py

signal continue_pressed

const W := 640
const H := 480

# ---- geometry (tools/re/specs/seasonend_year_samples.json) ------------------
const KIT_X := 18
const KIT_W := 17
const KIT_H := 19
const NAME_PEN_DY := 5
## (plate top, WITNESSED pen x). Order: Premier champion, Premier runner-up, then the
## First, Second and Third Division champions.
const PLATES := [[100, 50], [137, 50], [219, 49], [314, 49], [418, 48]]
const MID_X := [186, 331]
const REL_X := [346, 491]
const PEN_DY := 1
## tier -> the tops of that division's middle-column plates, and its relegated plates.
const MID_ROWS := {1: [99, 116, 133, 150], 2: [204, 221, 238],
	3: [294, 311, 328], 4: [398, 415, 432, 449]}
const REL_ROWS := {1: [99, 116, 133], 2: [204, 221, 238],
	3: [294, 311, 328, 345], 4: []}

const C_INK := Color8(0, 0, 0)
const C_PLATE_INK := Color8(255, 255, 255)

const BTN_CONTINUE := Rect2(517, 426, 118, 28)

var _chrome: Texture2D
var _page: Texture2D
var _g: Dictionary = {}
var _by_tier: Dictionary = {}    # Career.season_end_overview()
var _press := false


func _ready() -> void:
	_chrome = load("res://art/screens/seasonend/endofseason.png")
	_page = PMFont.page_texture("proman8")
	_g = PMFont.chars("proman8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## by_tier: Career.season_end_overview() —
##   {tier: {champion, runner_up, mid: [...], relegated: [...]}}, each club {club, club_id}
func setup(by_tier: Dictionary) -> void:
	_by_tier = by_tier
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var s := _scale()
	var d: Vector2 = (e.position - _origin(s)) / s
	if e.pressed:
		_press = BTN_CONTINUE.has_point(d)
	else:
		if _press and BTN_CONTINUE.has_point(d):
			continue_pressed.emit()
		_press = false
	queue_redraw()


# ---- text ----------------------------------------------------------------

func _advance(s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((_g.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
	return w


func _blit(x: int, y_top: int, s: String, col: Color) -> void:
	if _page == null:
		return
	var pen := x
	for i in s.length():
		var g: Dictionary = _g.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(_page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])


@warning_ignore("integer_division")
func _blit_centre(x0: int, x1: int, y_top: int, s: String, col: Color) -> void:
	_blit((x0 + x1 + 1 - _advance(s)) / 2, y_top, s, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	# the five navy plates, in the sheet's own order
	var plate_src: Array = [
		[1, "champion"], [1, "runner_up"], [2, "champion"], [3, "champion"], [4, "champion"],
	]
	for i in PLATES.size():
		var src: Array = plate_src[i]
		var blk: Dictionary = _by_tier.get(int(src[0]), {})
		if blk.is_empty():
			continue
		var club: Dictionary = blk.get(str(src[1]), {})
		if club.is_empty():
			continue
		var p: Array = PLATES[i]
		var kit := PMChrome.kit(int(club.get("club_id", -1)))
		if kit != null:
			draw_texture_rect_region(kit, Rect2(KIT_X, int(p[0]), KIT_W, KIT_H),
				Rect2(0, 0, 31, 64))
		_blit(int(p[1]), int(p[0]) + NAME_PEN_DY, str(club.get("club", "")), C_PLATE_INK)
	for t in [1, 2, 3, 4]:
		var blk2: Dictionary = _by_tier.get(t, {})
		if blk2.is_empty():
			continue
		_draw_column(blk2.get("mid", []), MID_ROWS.get(t, []), MID_X)
		_draw_column(blk2.get("relegated", []), REL_ROWS.get(t, []), REL_X)


func _draw_column(clubs: Array, tops: Array, span: Array) -> void:
	for i in mini(clubs.size(), tops.size()):
		_blit_centre(int(span[0]), int(span[1]), int(tops[i]) + PEN_DY,
			str((clubs[i] as Dictionary).get("club", "")), C_INK)
