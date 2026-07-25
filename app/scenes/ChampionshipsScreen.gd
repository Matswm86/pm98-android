extends Control
class_name ChampionshipsScreen
## PM98 THE CHAMPIONSHIPS — step 3 of the original's season-end sequence (REFRUN R15),
## witnessed for the first time in the Manchester Utd. 1997-98 reference run and baked
## from its own frame `tools/re/refs/season-end-2026-07-25/20_the_championships.png`.
##
## Eight finals in eight FIXED slots, two columns of four. The slot -> trophy binding is
## the chrome's: every card's title plate and trophy bitmap are the original's own pixels
## and are never redrawn. Only the club-dependent cells are — the kit block, the club
## name and the score cell(s).
##
## The LEFT column's cards carry ONE score cell and the RIGHT column's carry TWO. That is
## the frame's own layout, and the four two-cell slots are exactly the four competitions
## PM98 can decide over two legs or a replay (F.A. Cup, U.E.F.A. Cup, European Supercup,
## Coca-Cola Cup). A single match fills only the first cell and leaves the second empty,
## which is what the frame's own F.A. CUP and U.E.F.A. CUP cards show.
##
## ROW ORDER, measured on all eight of the frame's finals: the two rows are the tie's own
## HOME and AWAY sides, NOT winner-then-loser. The frame's U.E.F.A. CUP puts Inter 0 above
## Arsenal 1 and its COCA-COLA CUP puts Southampton above Arsenal, both with the WINNER
## second. The winner is marked only by its INK — solid black (0,0,0) against the loser's
## grey (80,100,120). Nothing is ever shared: a level score means penalties (REFRUN R15).
##
## Text, solved with tools/re/probe_text_anchor.py at ZERO differing pixels against the
## frame: names are proman10 left-aligned at the column's own pen, scores are proman10
## centred on `cell_x0 + cell_x1 + 1`, both with their pen top 5 rows into the row band.
##
## Chrome: tools/re/build_seasonend_year_chrome_from_frames.py
## Render-diff: tools/re/diff_seasonend_year_parity.py

signal continue_pressed

const W := 640
const H := 480

# ---- geometry (tools/re/specs/seasonend_year_samples.json) ------------------
const CARD_TOPS := [113, 204, 295, 388]
const ROW2_DY := 22
const ROW_H := 20
const KIT_W := 17
const KIT_H := 19
const NAME_PEN_DY := 5

const COL_LEFT := {"kit_x": 56, "name_pen": 82}
const COL_RIGHT := {"kit_x": 334, "name_pen": 360}
## Score cells belong to the CARD, not the column: the U.E.F.A. Cup's card is narrower
## than its three right-column neighbours and carries only one, with the desktop showing
## to the right of it. Straight off the frame's own panel borders.
const SCORE_L := [[245, 273]]
const SCORE_1 := [[523, 551]]
const SCORE_2 := [[523, 551], [554, 582]]

## The sheet's own slot order, top-to-bottom down the left column then the right.
## Career.season_end_championships() returns its eight entries in exactly this order.
const SLOTS := [
	{"side": "left", "card": 0, "comp": "charity_shield", "scores": SCORE_L},
	{"side": "left", "card": 1, "comp": "european_cup", "scores": SCORE_L},
	{"side": "left", "card": 2, "comp": "cup_winners_cup", "scores": SCORE_L},
	{"side": "left", "card": 3, "comp": "intercontinental", "scores": SCORE_L},
	{"side": "right", "card": 0, "comp": "fa_cup", "scores": SCORE_2},
	{"side": "right", "card": 1, "comp": "uefa_cup", "scores": SCORE_1},
	{"side": "right", "card": 2, "comp": "supercup", "scores": SCORE_2},
	{"side": "right", "card": 3, "comp": "coca_cola", "scores": SCORE_2},
]

const C_WIN := Color8(0, 0, 0)
const C_LOSE := Color8(80, 100, 120)
const C_SCORE := Color8(255, 255, 255)

const BTN_CONTINUE := Rect2(502, 437, 118, 28)

var _chrome: Texture2D
var _page: Texture2D
var _g: Dictionary = {}
var _rows: Array = []            # eight entries, {} where the final was not played
var _press := false


func _ready() -> void:
	_chrome = load("res://art/screens/seasonend/championships.png")
	_page = PMFont.page_texture("proman10")
	_g = PMFont.chars("proman10")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## rows: Career.season_end_championships() — eight entries in SLOTS order.
func setup(rows: Array) -> void:
	_rows = rows
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _scale() -> float:
	return min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0


func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)


func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = BTN_CONTINUE.has_point(d)
	else:
		if _press and BTN_CONTINUE.has_point(d):
			continue_pressed.emit()
		_press = false
	queue_redraw()


# ---- text ----------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		w += int((glyphs.get(s.unicode_at(i), {}) as Dictionary).get("adv", 0))
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


## Centre on a score cell: the original's pen solves on `x0 + x1 + 1` for every score
## witnessed, in both columns and on both score cells.
@warning_ignore("integer_division")
func _blit_centre(x0: int, x1: int, y_top: int, s: String, col: Color) -> void:
	_blit((x0 + x1 + 1 - _advance(_g, s)) / 2, y_top, s, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.12), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)
	for i in mini(_rows.size(), SLOTS.size()):
		var row: Dictionary = _rows[i]
		if row.is_empty():
			continue      # never played — the card stays as the original leaves it
		var slot: Dictionary = SLOTS[i]
		var col: Dictionary = COL_LEFT if str(slot["side"]) == "left" else COL_RIGHT
		var top: int = CARD_TOPS[int(slot["card"])]
		var cells: Array = slot["scores"]
		_draw_side(col, cells, top, row.get("home", {}))
		_draw_side(col, cells, top + ROW2_DY, row.get("away", {}))
	if _press:
		draw_rect(BTN_CONTINUE, Color(1, 1, 1, 0.18), true)


func _draw_side(col: Dictionary, cells: Array, row_top: int, side: Dictionary) -> void:
	if side.is_empty():
		return
	var ink: Color = C_WIN if bool(side.get("won", false)) else C_LOSE
	var kit := PMChrome.kit(int(side.get("club_id", -1)))
	if kit != null:
		draw_texture_rect_region(kit, Rect2(int(col["kit_x"]), row_top + 1, KIT_W, KIT_H),
			Rect2(0, 0, 31, 64))
	_blit(int(col["name_pen"]), row_top + NAME_PEN_DY, str(side.get("club", "")), ink)
	var scores: Array = side.get("scores", [])
	for k in mini(scores.size(), cells.size()):
		var cell: Array = cells[k]
		_blit_centre(int(cell[0]), int(cell[1]), row_top + NAME_PEN_DY,
			str(int(scores[k])), C_SCORE)
