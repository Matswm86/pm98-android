extends Control
class_name StatisticsScreen
## PM98 STATISTICS sub-screen (LINE-UP -> STATISTICS). Static chrome is the REAL
## game's resting frame baked verbatim below the shared barra
## (tools/re/build_lineup_subs_chrome_from_frames.py; binding frames run-2
## 069_162642 XI visit / 042_162537 full-squad + run-1 zero-state 147_154839).
## See docs/re/statistics_screen_re.md. The scene draws ONLY the dynamic layer:
##  - the body title "STATISTICS FOR <CLUB>." (verbatim sprite for Manchester Utd,
##    navy text for any other club);
##  - one row per squad player: the # (shirt number) + PLAYER name.
##
## The stat columns are the REAL season store: Career keeps the per-player records the
## original keeps at playerobj+0x24 (Pm98StatStore.fold_back) and hands them in as
## `rows` + `totals`, which the widget port formats (Pm98StatStore.row_cells / totals).
## A player who has never featured yields an all-zero row, which prints as the dashes
## the real game shows for an unused squad member — so a fresh season still looks like
## frame 147_154839 without a single fabricated number. Native 640x480.

signal back_pressed        # RETURN -> Main reopens LINE-UP

const W := 640
const H := 480
const BODY_Y0 := 62
const MANUTD_ID := 40      # the club whose verbatim "STATISTICS FOR ..." sprite was baked

const TITLE_XY := Vector2(237, 22)
const TITLE_MANUTD_XY := Vector2(157, 71)
const BODY_TITLE_X := 182  # navy text start for a non-ManUtd club (after the shirt icon)
const BODY_TITLE_Y := 72
# 19 row-fill tops (design y) = 111+16i; rows h13 (baker ST_ROW_TOPS)
const ROW_TOPS := [111, 127, 143, 159, 175, 191, 207, 223, 239, 255,
	271, 287, 303, 319, 335, 351, 367, 383, 399]
# The # column is LEFT-aligned at x28, not centred: "7", "18" and "20" all start their
# ink at exactly 28 in the witness. Same proman10 face as the PLAYER name beside it.
const NUM_X := 28
const NAME_X := 66          # under the PLAYER header
# PLAYER name face: proman10 at its native 10. Measured against every bundled atlas --
# it is the only one whose "Beckham" is 60px wide with 8px ink, as the witness draws it.
const NAME_SZ := 10
const NAME_DY := 1

# The row widget's 14 column separators (docs/re/statistics_row_widget_re.md) at the
# live frames' widget origin x = 25: [25, 170, 193, 234, 273, 296, 323, 375, 427, 479,
# 502, 525, 548, 571]. Cell [25,170] is the # + PLAYER block, so the 12 numeric cells
# are the consecutive pairs from 170 on. Each value is CENTRED in its cell.
const CELL_X := [170, 193, 234, 273, 296, 323, 375, 427, 479, 502, 525, 548, 571]
# Pm98StatStore.row_cells() keys, left to right.
const CELL_KEYS := ["MP", "MIN", "RATING", "MoM", "G.", "SHOTS", "PASSES", "TAC.",
	"S.", "yellow", "red", "injury"]
const TOTAL_Y := 425        # the TEAM TOTAL widget's own row (frames 02/06, y425..437)
const CELL_SZ := 15         # calend8's native size
const CELL_DY := -1         # cell-text y nudge off the row top (frame-measured)
# The denominator's left edge sits one pixel past the slash's advance -- measured off the
# witness (the original draws the three parts with separate GDI calls, so the gap is not
# calend8's own side bearing).
const PAIR_GAP := 1

const R_RETURN := Rect2(505, 446, 128, 30)

const C_TITLE := Color8(0, 0, 128)   # "STATISTICS FOR ..." navy (frame-sampled)
const C_NUM := Color8(0, 0, 128)     # # column navy (frame 042-sampled)
const C_NAME := Color8(0, 0, 0)
const C_CELL := Color8(0, 0, 0)      # stat cells, frame-sampled black
# The TEAM TOTAL *label* is red baked chrome, but its VALUES are drawn black, exactly
# like a player row -- frame-sampled (the witness has 408 black cell pixels there).
const C_TOTAL := Color8(0, 0, 0)
const C_PRESS := Color(1, 1, 1, 0.20)

var _club: Dictionary = {}
var _header: Dictionary = {}
var _players: Array = []
var _rows: Array = []                # PackedInt32Array(17) per player, squad order
var _totals: PackedInt32Array = PackedInt32Array()
var _press := ""

var _f8: Font
var _f10: Font
var _fcell: Font       # calend8 -- the stat cells' face (digit ink 4x9, dash 3x1,
                       # both measured off the live frame against every bundled atlas)
var _chrome: Texture2D
var _title: Texture2D
var _title_manutd: Texture2D


func _ready() -> void:
	_f8 = PMChrome.font("8")
	_f10 = PMChrome.font("10")
	_fcell = PMChrome.font("calend8")
	_chrome = load("res://art/screens/stats/chrome.png")
	_title = load("res://art/screens/stats/title.png")
	_title_manutd = load("res://art/screens/stats/title_manutd.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## `rows` is one Pm98StatStore record (17 dwords) per squad player, in the same order as
## `club.players` — Career.season_stat_rows(). `totals` is Career.season_stat_totals().
## Both default to empty, which renders the all-dashes zero state rather than nothing.
func setup(club: Dictionary, header: Dictionary = {}, rows: Array = [],
		totals: PackedInt32Array = PackedInt32Array()) -> void:
	_club = club
	_header = header
	if _header.is_empty():
		_header = {"mode": "manager", "top": "",
			"bottom": PMChrome.title_case_name(str(club.get("name", ""))),
			"club_id": int(club.get("id", -1))}
	_players = (club.get("players", []) as Array).duplicate()
	_rows = rows
	_totals = totals
	queue_redraw()


## The 17-dword record for visible row `i`, or an all-zero one when the caller passed no
## store (or a short one) — never an invented number.
func _row(i: int) -> PackedInt32Array:
	if i < _rows.size() and _rows[i] is PackedInt32Array \
			and (_rows[i] as PackedInt32Array).size() == Pm98StatStore.REC_DWORDS:
		return _rows[i]
	var z := PackedInt32Array()
	z.resize(Pm98StatStore.REC_DWORDS)
	return z


## Draw one widget row's 12 numeric cells, each centred in its separator pair.
func _draw_cells(f: PackedInt32Array, y: int, col: Color) -> void:
	# Every cell of a squad row is drawn, including the "-" / "-/-" placeholders: the
	# baked chrome is 19 BLANK slots, and the live frames put a dash in each empty cell
	# of a real squad row (e.g. Scholes, all twelve).
	var cells := Pm98StatStore.row_cells(f)
	for c in CELL_KEYS.size():
		var x0: int = CELL_X[c]
		var x1: int = CELL_X[c + 1]
		var s: String = str(cells[CELL_KEYS[c]])
		if not s.contains("/"):
			PMChrome.text(self, _fcell, x0, y + CELL_DY, s, col, CELL_SZ, 1, float(x1 - x0))
			continue
		# An x/y pair is NOT one centred string (@0x4b075d..0x4b0938): the "/" is centred
		# in the cell, the numerator is right-aligned against it and the denominator is
		# left-aligned after it. "-/-" lays out the same way.
		var parts := s.split("/")
		var sw := _fcell.get_string_size("/", HORIZONTAL_ALIGNMENT_LEFT, -1, CELL_SZ).x
		var sx := x0 + (float(x1 - x0) - sw) * 0.5
		PMChrome.text(self, _fcell, sx, y + CELL_DY, "/", col, CELL_SZ)
		PMChrome.text(self, _fcell, sx, y + CELL_DY, parts[0], col, CELL_SZ, 2)
		# calend8's "-" carries a 1px left bearing the original's dash does not, so the
		# placeholder's pen backs off by it to land its ink on the witnessed column.
		var gap: int = PAIR_GAP if parts[1] != "-" else 0
		PMChrome.text(self, _fcell, sx + sw + gap, y + CELL_DY, parts[1], col, CELL_SZ)


# ---- geometry -------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	return (p - _origin(_scale())) / _scale()


func _hit(d: Vector2) -> String:
	return "return" if R_RETURN.has_point(d) else ""


# ---- input ----------------------------------------------------------------

func _on_input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var d := _to_design(e.position)
	if e.pressed:
		_press = _hit(d)
		queue_redraw()
		return
	var was := _press
	_press = ""
	queue_redraw()
	if was == "return" and _hit(d) == "return":
		back_pressed.emit()


# ---- drawing --------------------------------------------------------------

func _draw() -> void:
	var s := _scale()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))

	PMChrome.draw_match_header(self, "statistics", _header)
	if _chrome != null:
		draw_texture(_chrome, Vector2(0, BODY_Y0))
	if _title != null:
		draw_texture(_title, TITLE_XY)

	# body title: verbatim sprite for Man Utd, redrawn navy text otherwise
	if int(_club.get("id", -1)) == MANUTD_ID and _title_manutd != null:
		draw_texture(_title_manutd, TITLE_MANUTD_XY)
	else:
		PMChrome.text(self, _f10, BODY_TITLE_X, BODY_TITLE_Y,
			"STATISTICS FOR %s." % PMChrome.title_case_name(str(_club.get("name", ""))).to_upper(),
			C_TITLE, 13, 0)

	# one row per player: # + name + the 12 season cells out of the store
	for i in mini(_players.size(), ROW_TOPS.size()):
		var p: Dictionary = _players[i]
		var y: int = ROW_TOPS[i]
		PMChrome.text(self, _f10, NUM_X, y + NAME_DY, str(int(p.get("squadNo", 0))),
			C_NUM, NAME_SZ)
		PMChrome.text(self, _f10, NAME_X, y + NAME_DY,
			PMChrome.title_case_name(str(p.get("name", "?"))), C_NAME, NAME_SZ, 0, 100.0)
		_draw_cells(_row(i), y, C_CELL)

	# TEAM TOTAL: slot 19 of the same widget class, so the same formatter — its MP and
	# MIN come from the club counters, not from column sums (@0x4b21ed / @0x4b221a).
	if _totals.size() == Pm98StatStore.REC_DWORDS:
		_draw_cells(_totals, TOTAL_Y, C_TOTAL)

	if _press == "return":
		draw_rect(R_RETURN, C_PRESS, true)
