extends Control
class_name ManagerHistoryScreen
## PM98 MANAGER HISTORY screen — frame-baked from the live-witnessed original
## (screenshots/promanager-career-2026-07-16/15+16, MANAGER.EXE under wine; EXE
## string block 0x25b674; docs/re/promanager_career_screens_re.md). This is the
## original counterpart of the invented "YOUR CAREER" browse (audit B5-1).
##
## Everything static is baked pixel-exact into art/screens/managerhistory/body.png
## (title bar + pitch plaque + ball, both table grids with headers + competition
## labels, scrollbar, red arrow, TOTAL-off plate, RETURN). The scene draws live,
## over blanked baked fields, ONLY what the game reads from career state:
##   - the manager name (proman12, plaque interior)
##   - one row per club spell: TEAM / DIVISION / POS. / OBJ. / DIRECTORS / PUBLIC
##     (proman8 gold, per-witness pens)
##   - the per-competition PLA/WIN/DR/LOS/GF/GA numbers (proman8 black, centred)
##   - the lit TOTAL plate (frame-16 sprite) when the toggle is ON.
##
## HONEST GAPS (single-witness calibrations, flagged in the RE doc): the POSITION
## column is witnessed empty (week-1 zero state) and its filled format is unknown
## -> stays empty. TOTAL is witnessed only as a lit/unlit plate (identical tables
## with one week-old spell) -> ON shows the career-total rows the caller passes.
## The POS. cell pen is a fixed left inset (fits the single witness); spell-row
## ordering beyond one row and the red arrow's function are un-witnessed (arrow
## baked, inert). Native 640x480; scales to fit its parent.

signal back_pressed    # RETURN -> dismiss
## OURS, not the game's: a tap on the manager-name PLAQUE opens the HONOURS + CAREER
## RESUME screen (docs/SPEC_ours_additions.md item 1). The plaque is inert in every
## captured frame and nothing is drawn to advertise the tap, so this screen still
## renders at 0 differing pixels — the same rule the SCOUT screen's extra-filters
## panel follows. If the plaque's own behaviour is ever witnessed, this moves.
signal honours_pressed

const W := 640
const H := 480

const C_GOLD := Color8(255, 223, 0)        # spell-row text (witnessed 255,223,0)
const C_INK := Color8(0, 0, 0)             # lower-table numbers (witnessed black)
const C_NAME := Color8(30, 52, 98)         # plaque name ink (witnessed 30,52,98)

# Upper spells table (design coords, from the frame probes).
const ROWS_VISIBLE := 13
const ROW_Y0 := 96
const ROW_PITCH := 15
# Cell interiors x0..x1 (inclusive).
const CELL_TEAM := Vector2i(20, 117)
const CELL_DIV := Vector2i(119, 201)
const CELL_POS := Vector2i(203, 243)
const CELL_OBJ := Vector2i(245, 285)
const CELL_DIR := Vector2i(287, 369)
const CELL_PUB := Vector2i(371, 453)
const TEAM_PAD := 3                        # "Brighton & HA" pen x=23 (cell x0 20)
const POS_PAD := 9                         # "23rd" pen x=212 (cell x0 203)

# Lower competition table: fixed 9 rows (baked labels, this order).
const LOW_Y0 := 334
const LOW_CELLS: Array[Vector2i] = [
	Vector2i(149, 183), Vector2i(185, 219), Vector2i(221, 255),
	Vector2i(257, 291), Vector2i(293, 337), Vector2i(339, 383),
]
const COMP_KEYS: Array[String] = [
	"league", "fa_cup", "coca_cola", "charity", "uefa",
	"cup_winners", "european_cup", "supercup", "intercont",
]
const STAT_KEYS: Array[String] = ["pla", "win", "dr", "los", "gf", "ga"]

# Controls (frame-measured hit rects).
const BTN_TOTAL := Rect2(508, 314, 104, 29)
const BTN_RETURN := Rect2(508, 440, 100, 26)
const BTN_SCROLL_UP := Rect2(455, 96, 16, 15)
const BTN_SCROLL_DOWN := Rect2(455, 276, 16, 15)
const PLAQUE := Rect2(366, 21, 151, 16)

var _body: Texture2D
var _total_on_tex: Texture2D
var _f8: Font
var _f12: Font

var _manager: String = ""
var _spells: Array = []          # [{team, division, pos, obj, directors, public}]
var _season_rows: Dictionary = {}   # comp key -> {pla,win,dr,los,gf,ga}
var _total_rows: Dictionary = {}    # comp key -> same shape, career totals
var _total_on: bool = false
var _scroll: int = 0


func _ready() -> void:
	_body = load("res://art/screens/managerhistory/body.png") \
		if ResourceLoader.exists("res://art/screens/managerhistory/body.png") else null
	_total_on_tex = load("res://art/screens/managerhistory/total_on.png") \
		if ResourceLoader.exists("res://art/screens/managerhistory/total_on.png") else null
	_f8 = PMChrome.font("8")
	_f12 = PMChrome.font("12")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


## `spells` come oldest-first (current spell last); each row dict carries display
## strings: team, division, pos, obj ("YES"/"NO"/""), directors, public ("" = no data,
## honest empty cell — past spells never stored board confidence).
## `season_rows`/`total_rows` map COMP_KEYS -> {pla,win,dr,los,gf,ga} ints.
func setup(manager: String, spells: Array, season_rows: Dictionary,
		total_rows: Dictionary = {}) -> void:
	_manager = manager
	_spells = spells
	_season_rows = season_rows
	_total_rows = total_rows if not total_rows.is_empty() else season_rows
	_total_on = false
	_scroll = 0
	queue_redraw()


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		return
	var p := _to_design(e.position)
	if BTN_RETURN.has_point(p):
		back_pressed.emit()
	elif PLAQUE.has_point(p):
		honours_pressed.emit()      # OURS (see the signal's note)
	elif BTN_TOTAL.has_point(p):
		_total_on = not _total_on
		queue_redraw()
	elif BTN_SCROLL_UP.has_point(p):
		_set_scroll(_scroll - 1)
	elif BTN_SCROLL_DOWN.has_point(p):
		_set_scroll(_scroll + 1)


func _set_scroll(v: int) -> void:
	var m := maxi(0, _spells.size() - ROWS_VISIBLE)
	var nv := clampi(v, 0, m)
	if nv != _scroll:
		_scroll = nv
		queue_redraw()


# ---- drawing -------------------------------------------------------------

## proman8 at its native 11pt, ink TOP at y_top (StaffScreen convention:
## baseline = glyph top + 7, verified 0px there and against frame 15 here).
func _t8(pen_x: float, y_top: float, s: String, col: Color) -> void:
	if _f8 == null:
		return
	draw_string(_f8, Vector2(floorf(pen_x), y_top + 7), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


## Centred on a cell's interior (advance-box centre, floored — witnessed:
## "3rd Div." pen 137 in 119..201, "YES" 254 in 245..285, "5" 324 in 287..369).
func _t8_center(cell: Vector2i, y_top: float, s: String, col: Color) -> void:
	if _f8 == null or s == "":
		return
	var w := _f8.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var x0 := float(cell.x)
	var span := float(cell.y - cell.x + 1)
	_t8(x0 + floorf((span - w) / 2.0), y_top, s, col)


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	if _body != null:
		draw_texture(_body, Vector2.ZERO)
	if _total_on and _total_on_tex != null:
		draw_texture(_total_on_tex, BTN_TOTAL.position)

	# Manager name — proman12 native 13pt, advance-centred in the plaque
	# (witnessed "mwm" pen 422 = 366 + (151-39)/2 floored; ink top 26 -> baseline 33,
	# parity-calibrated vs frame 15).
	if _f12 != null and _manager != "":
		var nw := _f12.get_string_size(_manager, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(_f12, Vector2(floorf(PLAQUE.position.x + (PLAQUE.size.x - nw) / 2.0), 33.0),
			_manager, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, C_NAME)

	# Spell rows (window of ROWS_VISIBLE from _scroll). Ink top = row fill top + 4
	# (witnessed: fill y=96, cap top y=100). The TOTAL view recolours the rows
	# (witnessed frame 16): white on the navy cells (TEAM/OBJ), black on the slate
	# cells — season view renders them gold (frame 15).
	var c_navy := Color.WHITE if _total_on else C_GOLD
	var c_slate := C_INK if _total_on else C_GOLD
	for i in range(ROWS_VISIBLE):
		var idx := _scroll + i
		if idx >= _spells.size():
			break
		var sp: Dictionary = _spells[idx]
		var yt := float(ROW_Y0 + i * ROW_PITCH + 4)
		_t8(CELL_TEAM.x + TEAM_PAD, yt, str(sp.get("team", "")), c_navy)
		_t8_center(CELL_DIV, yt, str(sp.get("division", "")), c_slate)
		_t8(CELL_POS.x + POS_PAD, yt, str(sp.get("pos", "")), c_slate)
		_t8_center(CELL_OBJ, yt, str(sp.get("obj", "")), c_navy)
		_t8_center(CELL_DIR, yt, str(sp.get("directors", "")), c_slate)
		_t8_center(CELL_PUB, yt, str(sp.get("public", "")), c_slate)

	# Competition numbers (ink top = row fill top + 4: witnessed 334 -> 338).
	var rows: Dictionary = _total_rows if _total_on else _season_rows
	for r in range(COMP_KEYS.size()):
		var row: Dictionary = rows.get(COMP_KEYS[r], {})
		var yt := float(LOW_Y0 + r * ROW_PITCH + 4)
		for c in range(STAT_KEYS.size()):
			_t8_center(LOW_CELLS[c], yt, str(int(row.get(STAT_KEYS[c], 0))), C_INK)
		# POSITION column: filled format un-witnessed -> stays empty (RE doc).
