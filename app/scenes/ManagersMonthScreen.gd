extends Control
class_name ManagersMonthScreen
## PM98 MANAGERS OF THE MONTH — the sheet the original raises during the CONTINUE
## chain at the end of a calendar month (witnessed 2026-07-18, Bolton W career:
## week-4 CONTINUE -> the Coca-Cola Cup draw -> this sheet -> PLAYERS OF THE MONTH
## -> hub; frame `76_after_drawcont.png`).
##
## Chrome = the real frame's panel with ONLY the caption band, the four winners'
## kits and the four manager/club cells cleared
## (tools/re/build_awards_chrome_from_frames.py -> art/screens/awards/managers.png).
## This scene redraws that dynamic layer:
##   * the green caption bar. Its checker rail is a fixed tile ladder measured on
##     BOTH award frames — reading outward from the title field the tiles run
##     2, 4, 9, 11, 15 with gaps 5, 4, 3, 2, 1 and then a solid block to the panel
##     edge, IDENTICAL in the two frames and simply anchored to the caption's own
##     edge (76's caption is 10px wider, and every tile shifts by exactly 10). The
##     caption face is ProMan14 (advance sums 386 / 367 vs the frames' 384 / 365).
##   * the winning club's kit at each card's left block,
##   * the manager's surname and the club name in the card's two cells.
##
## Who wins each division is Career's own month-form pick, documented there — the
## binary's rule is not reversed. The SCREEN is the original's.

signal ok_pressed

const W := 640
const H := 480

const PANEL := Vector2i(14, 124)            # the baked panel's top-left on screen
const CAPTION_Y := Vector2i(126, 147)       # caption band rows (screen-absolute)
const OK_RECT := Rect2(536, 243, 78, 28)
const KIT_WH := Vector2i(28, 32)

# Checker rail (both frames): tiles/gaps read OUTWARD from the caption field.
const RAIL_TILES := [2, 4, 9, 11, 15]
const RAIL_GAPS := [5, 4, 3, 2, 1]
const RAIL_PAD := 35                        # caption ink x - rail inner end
const C_RAIL_DARK := Color8(0, 63, 0)       # frame-sampled tile
const C_RAIL_FIELD := Color8(17, 127, 43)   # frame-sampled field
const C_CAPTION := Color8(255, 255, 255)
const RAIL_TOP := 3                         # tiles run y0+3 .. y1-4 (frame rows 129..143)

# card cells (screen-absolute), in the frame's own order
const CARDS := [
	{"key": 1, "kit": Vector2i(18, 160), "val": Vector2i(179, 191),
		"name": Vector2i(46, 176), "club": Vector2i(177, 314)},
	{"key": 2, "kit": Vector2i(321, 160), "val": Vector2i(179, 191),
		"name": Vector2i(349, 479), "club": Vector2i(480, 617)},
	{"key": 3, "kit": Vector2i(18, 205), "val": Vector2i(224, 236),
		"name": Vector2i(46, 176), "club": Vector2i(177, 314)},
	{"key": 4, "kit": Vector2i(321, 205), "val": Vector2i(224, 236),
		"name": Vector2i(349, 479), "club": Vector2i(480, 617)},
]
# Frame-sampled inks: the manager's surname is WHITE on the dark cell, the club
# name is a per-division DARK tint on the light cell (76: brown / green / slate /
# maroon for PREMIER / FIRST / SECOND / THIRD).
const C_NAME := Color8(255, 255, 255)
const C_CLUB := {
	1: Color8(135, 73, 22), 2: Color8(0, 95, 0),
	3: Color8(60, 80, 100), 4: Color8(85, 0, 0),
}

var _chrome: Texture2D
var _f14: Font
var _f10: Font
var _month := ""
var _title := ""          # "" -> the MANAGERS OF THE MONTH caption
var _rows: Dictionary = {}     # tier(1..4) -> {club_id, club, manager}
var _press := false


func _ready() -> void:
	_chrome = load("res://art/screens/awards/managers.png")
	_f14 = PMChrome.font("14")
	_f10 = PMChrome.font("10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## month: "AUGUST"; rows: {tier -> {club_id, club, manager}} for tiers 1..4.
func setup(month: String, rows: Dictionary) -> void:
	_month = month
	_title = ""
	_rows = rows
	queue_redraw()


## The same sheet under a CAPTION OF ITS OWN. The season-end GOAL SCORERS OF THE YEAR and
## MANAGERS OF THE YEAR sheets are this exact panel: diffed against the shipped month
## chrome, tools/re/refs/season-end-2026-07-25/24_managers_of_the_year.png is identical
## everywhere but the caption text and the four card cells (REFRUN R15, and
## docs/re/season_end_sequence_re.md -- one pixel signature matches both families, so the
## title plate is what tells them apart). GOAL SCORERS puts "Fowler (19)" in the cell the
## month sheet puts a manager's surname in, and the club beside it, unchanged.
func setup_titled(title: String, rows: Dictionary) -> void:
	_title = title
	_rows = rows
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = OK_RECT.has_point(d)
	else:
		if _press and OK_RECT.has_point(d):
			ok_pressed.emit()
		_press = false
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2(PANEL))
	var caption := _title if _title != "" else "MANAGERS OF THE MONTH (%s)" % _month
	draw_caption(self, caption, CAPTION_Y.x, CAPTION_Y.y, PANEL.x + 2, 624, _f14)
	for i in CARDS.size():
		var c: Dictionary = CARDS[i]
		var row: Dictionary = _rows.get(int(c["key"]), {})
		if row.is_empty():
			continue
		var kit := PMChrome.kit(int(row.get("club_id", -1)))
		if kit != null:
			var k: Vector2i = c["kit"]
			draw_texture_rect_region(kit, Rect2(k.x, k.y, KIT_WH.x, KIT_WH.y),
				Rect2(1, 3, 45, 57))
		var v: Vector2i = c["val"]
		var nx: Vector2i = c["name"]
		var bx: Vector2i = c["club"]
		_txt(_f10, nx.x + 4, v.x + 1, PMChrome.title_case_name(str(row.get("manager", ""))),
			C_NAME, nx.y - nx.x - 8)
		_txt(_f10, bx.x + 5, v.x + 1, PMChrome.title_case_name(str(row.get("club", ""))),
			C_CLUB.get(int(c["key"]), C_NAME), bx.y - bx.x - 8)
	if _press:
		draw_rect(OK_RECT, Color(1, 1, 1, 0.2), true)


## The award sheets' shared green caption bar: a centred ProMan14 title with the
## checker rail running outward from each side of it. Static across both frames
## except for the title string, so it lives here and PlayersMonthScreen reuses it.
static func draw_caption(ci: CanvasItem, title: String, y0: int, y1: int,
		x0: int, x1: int, f: Font) -> void:
	ci.draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), C_RAIL_FIELD, true)
	if f == null:
		return
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	@warning_ignore("integer_division")
	var cx := (x0 + x1) / 2
	var tx := int(cx - w * 0.5)
	ci.draw_string(f, Vector2(tx, y0 + 3 + f.get_ascent(15)), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, C_CAPTION)
	_rail(ci, y0, y1, x0, tx - RAIL_PAD, false)
	_rail(ci, y0, y1, int(tx + w) + RAIL_PAD, x1, true)


## One rail. `outward_right` lays the ladder left-to-right (the right-hand rail);
## otherwise it runs right-to-left from the caption field toward the panel edge.
static func _rail(ci: CanvasItem, y0: int, y1: int, xa: int, xb: int, outward_right: bool) -> void:
	if xb <= xa:
		return
	var ty0 := y0 + RAIL_TOP
	var ty1 := y1 - 3
	var pos := xb if not outward_right else xa
	for i in RAIL_TILES.size():
		var wdt: int = RAIL_TILES[i]
		if outward_right:
			if pos + wdt > xb:
				break
			ci.draw_rect(Rect2(pos, ty0, wdt, ty1 - ty0), C_RAIL_DARK, true)
			pos += wdt + int(RAIL_GAPS[i])
		else:
			if pos - wdt < xa:
				break
			ci.draw_rect(Rect2(pos - wdt, ty0, wdt, ty1 - ty0), C_RAIL_DARK, true)
			pos -= wdt + int(RAIL_GAPS[i])
	# the solid block that fills what is left toward the panel edge
	if outward_right and pos < xb:
		ci.draw_rect(Rect2(pos, ty0, xb - pos, ty1 - ty0), C_RAIL_DARK, true)
	elif not outward_right and pos > xa:
		ci.draw_rect(Rect2(xa, ty0, pos - xa, ty1 - ty0), C_RAIL_DARK, true)


func _txt(f: Font, x: int, y_top: int, t: String, col: Color, maxw: int) -> void:
	if f == null or t == "":
		return
	var sz := 11
	while f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > float(maxw) and sz > 7:
		sz -= 1
	draw_string(f, Vector2(x, y_top + f.get_ascent(sz)), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)
