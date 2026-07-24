extends Control
class_name CupDrawScreen
## PM98 SORTEO — the cup DRAW screen, the original's own.
##
## This is the screen MANAGER.EXE raises when a knockout round is drawn: a bezelled
## left panel with the competition's name, its trophy beside the lottery drum, a yellow
## ROUND plate under them, the green MATCHES list filling one club at a time on the
## right, the 1ST LEG / 2ND LEG (or MATCH / REPLAY) plates bottom-left, and FINISH +
## CONTINUE. It replaces the invented `CupScreen` marble panels.
##
## Everything here is measured off three real frames — `74_after_wk4.png` and
## `75_scout_wk5.png` (Coca-Cola Cup ROUND 2, mid-draw and later) and
## `10_fa_cup_draw_round1.png` (F.A. Cup ROUND 1) — and the art is the game's own,
## named by MANAGER.EXE itself at 0x255670-0x255aa4 (`img\sorteo\frames\...`).
## Chrome: tools/re/build_cupdraw_chrome_from_frames.py. Art: tools/re/export_sorteo_art.py.
## Full derivation + the residual list: docs/re/cupdraw_screen_re.md.
##
## The picture layer reproduces the real frame at 100.0000% exact pixels: the window is
## cleared to black, the competition's 72x144 SORTEO strip goes at (31,76), the 188x144
## drum backdrop at (103,76), and one of the twelve 92x92 BOMBO frames at (136,76) drawn
## OPAQUE — its index-0 pixels land as black in the original, which is why a transparent
## blit left 168 stray pixels.
##
## NOT witnessed, and therefore NOT drawn: the two long value cells in the bottom-left
## panel are empty in every frame we hold, so they stay empty; the hand (MANO0..7) and
## ball (BOLA0..3) sprites the EXE loads for this screen appear in no captured frame, so
## they are exported but unused; and the CONTINUE ball's lit/unlit rule is unknown, so
## the chrome keeps frame 74's phase.

signal continue_pressed
signal finish_pressed

const W := 640
const H := 480

# ---- geometry (tools/re/specs/cupdraw_chrome_samples.json) ------------------
const PICTURE := Rect2(31, 76, 260, 144)
const STRIP_AT := Vector2(31, 76)
const FONDO_AT := Vector2(103, 76)
const BOMBO_AT := Vector2(136, 76)

# Both witnessed titles centre on the same field: pen_x = (TITLE_SUM - advance) / 2 gives
# 96 for "Coca-Cola Cup" (adv 133) and 121 for "F.A. Cup" (adv 83), which is where the two
# frames put them to the pixel. TOP is one less than the ink row because the BMFont cells
# carry an empty first row.
const TITLE_SUM := 325
const TITLE_TOP := 39
const C_TITLE := Color8(255, 255, 255)

const ROUND_SUM := 320          # 113 for "ROUND 2" (adv 93), 116 for "ROUND 1" (adv 88)
const ROUND_TOP := 236
const C_ROUND := Color8(255, 223, 0)

const LEG_SUM := 116            # 30 / 27 / 33 / 30 for 1ST LEG / 2ND LEG / MATCH / REPLAY
const LEG_TOPS := [413, 440]
const C_LEG := Color8(255, 255, 0)

const LIST_Y0 := 51
const LIST_PITCH := 16
const LIST_ROWS := 23
const LIST_TEXT_TOP := 2          # pen top inside the row band (row 0 ink lands at y 54)
const HOME_RIGHT := 465           # home club's pen END x — right-aligned
const DASH_X := 467               # the fixed "-" the game paints with the home club
const AWAY_LEFT := 475            # away club's pen START x
const C_ROW_TXT := Color8(80, 100, 120)

# Scrollbar. Trough interior y 70..401 (331 rows); the thumb is proportional and its
# height solves BOTH witnesses exactly: round(331 * 23 / ties) is 305 for the 25-tie
# Coca-Cola round 2 and 190 for the 40-tie F.A. Cup round 1, which is what they measure.
const SCROLL_X := 606           # the trough box is 18px wide; 606 and 622-623 are the
const SCROLL_W := 18            # THUMB's own black edges, and show trough colour without it
const TROUGH_Y := 70
const TROUGH_H := 331
const C_TROUGH := Color8(180, 200, 220)
const C_THUMB_CAP := Color8(220, 220, 220)
const C_THUMB_EDGE := Color8(60, 80, 100)
const C_THUMB_A := [Color8(120, 140, 160), Color8(120, 140, 160), Color8(120, 140, 160),
	Color8(100, 120, 140), Color8(100, 120, 140), Color8(100, 120, 140),
	Color8(100, 120, 140), Color8(114, 114, 114), Color8(114, 114, 114),
	Color8(114, 114, 114), Color8(114, 114, 114), Color8(80, 100, 120)]
const C_THUMB_B := [Color8(120, 140, 160), Color8(120, 140, 160), Color8(100, 120, 140),
	Color8(120, 140, 160), Color8(100, 120, 140), Color8(100, 120, 140),
	Color8(114, 114, 114), Color8(100, 120, 140), Color8(114, 114, 114),
	Color8(114, 114, 114), Color8(80, 100, 120), Color8(114, 114, 114)]

const BTN_FINISH := Rect2(350, 440, 112, 24)
const BTN_CONTINUE := Rect2(492, 438, 118, 28)

## The five competitions MANAGER.EXE loads a SORTEO strip for on THIS screen, plus the
## two more that ship one in IMG.PKF (charity / supercup) for the single-tie finals.
const STRIPS := {
	"fa_cup": "sorteo_facup",
	"league_cup": "sorteo_cocacola",
	"european_cup": "sorteo_european_cup",
	"uefa_cup": "sorteo_uefa",
	"cup_winners_cup": "sorteo_cup_winners",
	"charity_shield": "sorteo_charity",
	"supercup": "sorteo_supercup",
}

var _chrome: Texture2D
var _fondo: Texture2D
var _bombo: Array[Texture2D] = []
var _strip: Texture2D
var _page10: Texture2D
var _page14: Texture2D
var _g10: Dictionary = {}
var _g14: Dictionary = {}

var _title := ""                  # "Coca-Cola Cup" — the EXE's own spelling
var _round := ""                  # "ROUND 2" — the EXE's own uppercase label
var _legs: Array = ["MATCH", "REPLAY"]
var _ties: Array = []             # [{home: String, away: String}], away "" while undrawn
var _total := 0                   # ties in the round; drives the scrollbar
var _first := 0                   # first visible row
var _spin := 0.0                  # drum animation phase (seconds)
var _press := ""


func _ready() -> void:
	_chrome = load("res://art/screens/cupdraw/chrome.png")
	_fondo = load("res://art/screens/cupdraw/fondo.png")
	for i in 12:
		var t: Texture2D = load("res://art/screens/cupdraw/bombo%02d_opaque.png" % i)
		if t != null:
			_bombo.append(t)
	_page10 = PMFont.page_texture("proman10")
	_page14 = PMFont.page_texture("proman14")
	_g10 = PMFont.chars("proman10")
	_g14 = PMFont.chars("proman14")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	set_process(true)
	queue_redraw()


## Feed one round's draw.
##   key    — a STRIPS key, picks the competition's own trophy strip
##   title  — the competition name as MANAGER.EXE spells it ("F.A. Cup", "Coca-Cola Cup")
##   rnd    — the round label in the EXE's uppercase plate form ("ROUND 2", "QTR FINALS")
##   ties   — [{home, away}] in draw order; a trailing away "" is a club still waiting
##   total  — ties in the full round (>= ties.size()); sizes the scrollbar
##   legs   — the two bottom-left plates: ["1ST LEG","2ND LEG"] two-legged, else
##            ["MATCH","REPLAY"]
func setup(key: String, title: String, rnd: String, ties: Array, total: int,
		legs: Array) -> void:
	_title = title
	_round = rnd
	_ties = ties
	_total = maxi(total, ties.size())
	_legs = legs
	_first = 0
	var stem: String = str(STRIPS.get(key, "sorteo_facup"))
	_strip = load("res://art/screens/cupdraw/%s.png" % stem)
	queue_redraw()


## Hold the drum on one of the twelve frames (render-diff harness / a still capture).
func pin_drum(i: int) -> void:
	set_process(false)
	_spin = float(i) / 12.0 + 0.0001
	queue_redraw()


func _process(delta: float) -> void:
	# The drum turns: frames 74 and 10 hold BOMBO08 and BOMBO07 at the same spot, so the
	# twelve frames are a cycle. The RATE is not witnessed — 12/s is ours, flagged.
	if _bombo.is_empty():
		return
	var was := int(_spin * 12.0) % _bombo.size()
	_spin += delta
	if int(_spin * 12.0) % _bombo.size() != was:
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
		_press = "finish" if BTN_FINISH.has_point(d) else \
			("continue" if BTN_CONTINUE.has_point(d) else "")
	else:
		if _press == "finish" and BTN_FINISH.has_point(d):
			finish_pressed.emit()
		elif _press == "continue" and BTN_CONTINUE.has_point(d):
			continue_pressed.emit()
		_press = ""
	queue_redraw()


# ---- text ----------------------------------------------------------------

static func _advance(glyphs: Dictionary, s: String) -> int:
	var w := 0
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		w += int(g.get("adv", 0))
	return w


## Blit one string from a PM98 BMFont atlas. The pages are pure white masks, so the
## colour is a modulate; `x` is the PEN origin and `y_top` the pen's top row.
func _txt(page: Texture2D, glyphs: Dictionary, x: int, y_top: int, s: String,
		col: Color) -> void:
	if page == null:
		return
	var pen := x
	for i in s.length():
		var g: Dictionary = glyphs.get(s.unicode_at(i), {})
		if g.is_empty():
			continue
		var r: Rect2i = g["rect"]
		var off: Vector2i = g["off"]
		if r.size.x > 0 and r.size.y > 0:
			draw_texture_rect_region(page,
				Rect2(pen + off.x, y_top + off.y, r.size.x, r.size.y),
				Rect2(r.position.x, r.position.y, r.size.x, r.size.y), col)
		pen += int(g["adv"])


## Centre on a field given as the SUM of its two edges, which is how both witnessed
## title/round/leg strings land: pen = (sum - advance) / 2, floored.
@warning_ignore("integer_division")
func _txt_field(page: Texture2D, glyphs: Dictionary, field_sum: int, y_top: int, s: String,
		col: Color) -> void:
	_txt(page, glyphs, (field_sum - _advance(glyphs, s)) / 2, y_top, s, col)


# ---- drawing -------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0), true)
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture(_chrome, Vector2.ZERO)

	_draw_picture()
	_txt_field(_page14, _g14, TITLE_SUM, TITLE_TOP, _title, C_TITLE)
	_txt_field(_page14, _g14, ROUND_SUM, ROUND_TOP, _round, C_ROUND)
	for i in mini(_legs.size(), LEG_TOPS.size()):
		_txt_field(_page10, _g10, LEG_SUM, int(LEG_TOPS[i]), str(_legs[i]), C_LEG)
	_draw_rows()
	_draw_scrollbar()
	if _press != "":
		draw_rect(BTN_FINISH if _press == "finish" else BTN_CONTINUE,
			Color(1, 1, 1, 0.18), true)


## Black window, competition strip, drum backdrop, drum frame (opaque). Exactly the
## original's layer order — see the module docstring.
func _draw_picture() -> void:
	draw_rect(PICTURE, Color(0, 0, 0), true)
	if _strip != null:
		draw_texture(_strip, STRIP_AT)
	if _fondo != null:
		draw_texture(_fondo, FONDO_AT)
	if not _bombo.is_empty():
		draw_texture(_bombo[int(_spin * 12.0) % _bombo.size()], BOMBO_AT)


## The MATCHES list. Home club right-aligned so its pen ENDS at 465, the fixed "-" at
## 466, away club's pen starting at 475 — all three measured identical on eight witnessed
## rows across the two careers. A tie whose away club has not been drawn yet shows the
## home club and the dash alone, which is what frames 74 and 75 both catch mid-draw.
func _draw_rows() -> void:
	for k in LIST_ROWS:
		var i := _first + k
		if i >= _ties.size():
			break
		var tie: Dictionary = _ties[i]
		var home := str(tie.get("home", ""))
		var away := str(tie.get("away", ""))
		if home == "":
			continue
		var y := LIST_Y0 + LIST_PITCH * k + LIST_TEXT_TOP
		_txt(_page10, _g10, HOME_RIGHT - _advance(_g10, home), y, home, C_ROW_TXT)
		_txt(_page10, _g10, DASH_X, y, "-", C_ROW_TXT)
		if away != "":
			_txt(_page10, _g10, AWAY_LEFT, y, away, C_ROW_TXT)


## The proportional thumb, rebuilt from the frame's own rows: a white cap, a 2-row
## alternating body keyed on absolute y, a dark edge row and a 2px black foot.
func _draw_scrollbar() -> void:
	if _total <= LIST_ROWS:
		var h := TROUGH_H
		_thumb(TROUGH_Y, h)
		return
	var th := int(round(float(TROUGH_H) * float(LIST_ROWS) / float(_total)))
	var ty := TROUGH_Y + int(round(float(TROUGH_H) * float(_first) / float(_total)))
	_thumb(ty, maxi(th, 8))


func _thumb(y0: int, h: int) -> void:
	var x := SCROLL_X
	draw_rect(Rect2(x, y0, 1, h), Color(0, 0, 0), true)               # left black edge
	draw_rect(Rect2(x + 16, y0, 2, h), Color(0, 0, 0), true)          # right black edge
	draw_rect(Rect2(x + 1, y0, 15, 1), C_THUMB_CAP, true)             # top cap
	draw_rect(Rect2(x + 1, y0 + 1, 1, h - 3), C_THUMB_CAP, true)      # cap column
	draw_rect(Rect2(x + 2, y0 + 1, 13, 1), C_TROUGH, true)
	draw_rect(Rect2(x + 15, y0 + 1, 1, 1), C_THUMB_EDGE, true)
	for y in range(y0 + 2, y0 + h - 3):
		var band: Array = C_THUMB_A if (y & 1) == 0 else C_THUMB_B
		draw_rect(Rect2(x + 2, y, 1, 1), C_TROUGH, true)
		for i in band.size():
			draw_rect(Rect2(x + 3 + i, y, 1, 1), band[i], true)
		draw_rect(Rect2(x + 15, y, 1, 1), C_THUMB_EDGE, true)
	draw_rect(Rect2(x + 2, y0 + h - 3, 14, 1), C_THUMB_EDGE, true)
	draw_rect(Rect2(x + 1, y0 + h - 2, 15, 2), Color(0, 0, 0), true)
