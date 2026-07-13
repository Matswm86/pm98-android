extends Control
class_name FixturesScreen
## PM98 "THE CALENDAR" — the screen the hub FIXTURES icon opens in the original
## (walkthrough run 1: 050 MANAGER MENU -> 051..054 THE CALENDAR -> 055 hub).
## Chrome is the REAL game's frame 051 VERBATIM (barra, two spiral month sheets
## with the baked S M T W T F S header + AUGUST/SEPTEMBER 1997 titles + day grid,
## page arrows, the 10-competition colour legend, the TODAY & NEXT band interiors,
## RESULTS / LEAGUE TABLES / RETURN) — tools/re/build_fixtures_chrome_from_frames.py.
##
## PRECEDENT (PreseasonScreen / entry bake): the WITNESSED state renders as the
## frame's OWN pixels. So when setup() gets the frame-051 baseline (fresh MU
## career, Fri 1 Aug 1997), _draw() shows the baked chrome UNTOUCHED (the month
## titles / digits / TODAY / NEXT text are frame-true bitmap art) and repaints
## only the header (PMChrome.draw_match_header over the baked band — proven 0px on
## LINE-UP/VIEW RIVAL). No app-font text is drawn over the witnessed body — the
## original CALENDAR bitmap font is NOT pixel-identified, and a full font-redraw
## drifted ~9% of the frame (docs/re/fixtures_screen_re.md).
##
## When a career DIVERGES from the witnessed state (any other club / date /
## fixture set), _draw() WHITE-clears the body regions (the bake's `clear_rects`)
## and redraws the two sheets (red month title, day-cell grid coloured by
## competition, red TODAY ring), the TODAY band (flags, kits, name + stage bars)
## and the NEXT band (ball cell, kits, name bar, comp/round bars, date panel)
## with the app fonts. That redraw is an HONEST, UN-WITNESSED approximation:
## no other calendar state exists in the walkthrough to bind it, and it cannot
## be pixel-measured. Documented gaps: the CALENDAR bitmap font (kkita/PROMAN8
## stand-ins), competition bar/date shades derived procedurally from the legend
## colours for the un-walked competitions, empty TODAY/NEXT interiors, arrow
## paging semantics, and non-witnessed weekday abbreviations.

signal back_pressed
signal results_pressed
signal tables_pressed

const W := 640
const H := 480

# ---- frame-measured geometry (tools/re/specs/fixtures_chrome_samples.json) ----
const SHEET_X := [80, 280]            # sheet white body left edges (170 wide)
const CELL_X0 := 16                   # first cell col, sheet-relative
const CELL_Y0 := 114                  # first cell row (absolute y)
const CELL_PW := 20
const CELL_PH := 18
const CELL_W := 17                    # cell box incl 1px border
const CELL_H := 15
const TITLE_INK_TOP := 86             # month-title glyph rows 86..96

const TD_NAME := Rect2(99, 232, 340, 22)     # TODAY name-bar border box
const TD_BARS := Rect2(99, 258, 341, 33)     # TODAY stage-bars border box
const TD_FLAG_H := Vector2(100, 233)         # 30x20 BANDERAS at the bar ends
const TD_FLAG_A := Vector2(408, 233)
const TD_BALL_L := Vector2(100, 259)         # 28x31 ball cells
const TD_BALL_R := Vector2(411, 259)
const TD_KIT_C_L := Vector2(72, 263)         # kit slot centres (fallback anchor)
const TD_KIT_C_R := Vector2(471, 265)

const NX_Y0 := 317                    # NEXT row interior tops; borders y0-1/y0+31
const NX_PITCH := 38
const NX_BALL_X := 45                 # ball cell interior (28 wide)
const NX_KIT_H_X := 88                # 24x32 kit anchors
const NX_KIT_A_X := 389

const R_ARROW_L := Rect2(41, 100, 29, 94)
const R_ARROW_R := Rect2(461, 100, 29, 93)
const R_RESULTS := Rect2(510, 280, 126, 28)
const R_TABLES := Rect2(510, 313, 126, 28)
const R_RETURN := Rect2(519, 432, 110, 32)

## White-clear rects for the DIVERGENT redraw (== the pixels the bake would have
## cleared; tools/re/specs/fixtures_chrome_samples.json "clear_rects"). Only used
## when the career diverges from the frame-051 baseline — the baked witnessed text
## is erased to white before the app-font sheets/bands are drawn over it.
const CLEAR_TITLE := [Rect2(82, 85, 166, 14), Rect2(282, 85, 166, 14)]
const CLEAR_CELLS := [Rect2(82, 111, 166, 94), Rect2(282, 111, 166, 94)]
const CLEAR_TODAY := Rect2(40, 226, 461, 71)
const CLEAR_NEXT := Rect2(40, 311, 461, 157)

# ---- frame-sampled colours ---------------------------------------------------
const C_MONTH_RED := Color8(210, 0, 0)       # month title + today ring
const C_PRESS := Color(1, 1, 1, 0.2)
const C_PLATE := Color8(220, 220, 220)       # NEXT kit plate interior
const C_TODAY_NAME_INK := Color8(10, 15, 0)  # dark-olive TODAY title strokes

## Competition table, legend order. "cell" = the legend chip / day-cell fill
## (all 10 frame-sampled). The band shades (name/bar fills + inks + date-month
## ink) are WITNESSED for preseason + charity only; the rest derive from "cell"
## procedurally (documented approximation).
const COMPS := {
	"league": {"cell": Color8(166, 202, 240)},
	"fa_cup": {"cell": Color8(255, 255, 170)},
	"euro_league": {"cell": Color8(170, 255, 170)},
	"cup_winners": {"cell": Color8(255, 191, 170)},
	"uefa": {"cell": Color8(255, 204, 255)},
	"charity": {"cell": Color8(192, 192, 192), "bar1": Color8(80, 80, 80),
		"bar2": Color8(80, 80, 80), "dark": Color8(80, 80, 80),
		"ink1": Color8(0, 0, 0), "ink2": Color8(0, 0, 0),
		"month": Color8(192, 192, 192)},
	"supercup": {"cell": Color8(192, 192, 192)},
	"intercont": {"cell": Color8(160, 160, 164)},
	"preseason": {"cell": Color8(212, 191, 0), "bar1": Color8(212, 127, 0),
		"bar2": Color8(212, 159, 0), "dark": Color8(102, 50, 12),
		"ink1": Color8(102, 50, 12), "ink2": Color8(135, 73, 22),
		"month": Color8(212, 127, 0)},
	"cocacola": {"cell": Color8(160, 160, 200)},
}

const MONTHS := ["", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
	"JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
## Witnessed: Sunday / Monday / Weds / Friday (frame 051). The other three are
## unwitnessed; full names are used (honest gap).
const WEEKDAYS := ["Sunday", "Monday", "Tuesday", "Weds", "Thursday", "Friday",
	"Saturday"]

var _chrome: Texture2D
var _title: Texture2D
var _ball_next: Texture2D
var _ball_today: Texture2D
var _kit_today: Dictionary = {}   # id -> frame-rendered TODAY patch
var _kit_row: Dictionary = {}     # "40h"/"49a"... -> frame-rendered 24x32 patch
var _fkk: Font                    # KKITA (month title, bars, names, dates)
var _f8: Font                     # PROMAN8 (day digits)

var _header: Dictionary = {}
var _entries: Array = []          # [{y,m,d, comp, comp_name, round, home_id, away_id, home, away}]
var _today: Dictionary = {}       # {y,m,d}
var _month := [1997, 8]           # left sheet [year, month]
var _mo_lo := 0                   # paging clamp (month indices from entries)
var _mo_hi := 0
var _press := ""
var _baseline := false            # setup data == the frame-051 witnessed state


func _ready() -> void:
	_chrome = load("res://art/screens/fixtures/chrome.png")
	_title = load("res://art/screens/fixtures/title_calendar.png")
	_ball_next = load("res://art/screens/fixtures/ball_next.png")
	_ball_today = load("res://art/screens/fixtures/ball_today.png")
	for cid in [1021, 40]:
		var p := "res://art/screens/fixtures/kit_today_%d.png" % cid
		if ResourceLoader.exists(p):
			_kit_today[cid] = load(p)
	for key in ["40h", "1000h", "49a", "40a", "1301a", "1361a"]:
		var p := "res://art/screens/fixtures/kit_row_%s.png" % key
		if ResourceLoader.exists(p):
			_kit_row[key] = load(p)
	_fkk = load("res://art/fonts/kkita.fnt") if ResourceLoader.exists("res://art/fonts/kkita.fnt") else null
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	gui_input.connect(_on_input)
	queue_redraw()


## header = PMChrome.draw_match_header dict (manager plaques witnessed on 051).
## entries = every dated fixture of the season the calendar can show; today
## selects the TODAY band fixture + the red ring.
func setup(header: Dictionary, entries: Array, today: Dictionary) -> void:
	_header = header
	_entries = entries.duplicate()
	_entries.sort_custom(func(a, b) -> bool:
		return _date_key(a) < _date_key(b))
	_today = today
	var ty := int(today.get("y", 1997))
	var tm := int(today.get("m", 8))
	_month = [ty, tm]
	if _entries.is_empty():
		_mo_lo = ty * 12 + (tm - 1)
		_mo_hi = _mo_lo
	else:
		_mo_lo = _mo_index(_entries[0])
		_mo_hi = _mo_index(_entries[-1])
	_clamp_month()
	_baseline = _detect_baseline()
	queue_redraw()


## True iff (header, entries, today) match the ONE witnessed CALENDAR state —
## binding frame 051: a fresh Manchester Utd. career on Friday 1 Aug 1997 with the
## preseason friendlies 1/4/6/8 AUG (Juventus opening), Charity Shield 3 AUG,
## league from 10 AUG + the 17 SEP European-League date. In that state the app
## shows the baked frame pixels (frame-true); any other career/date/fixture set
## diverges and is redrawn with the app fonts (un-witnessed approximation). The
## check is structural (order-independent) and specific enough that no other real
## season hits it by accident — a genuine fresh MU career on the opening day
## legitimately resolves to the witnessed pixels.
func _detect_baseline() -> bool:
	if int(_today.get("y", 0)) != 1997 or int(_today.get("m", 0)) != 8 \
			or int(_today.get("d", 0)) != 1:
		return false
	if _entries.size() != 15:
		return false
	var td := _entry_on(1997, 8, 1)
	if int(td.get("home_id", -1)) != 1021 or str(td.get("comp", "")) != "preseason":
		return false
	var want := {"8-3": "charity", "8-4": "preseason", "8-6": "preseason",
		"8-8": "preseason", "8-10": "league", "9-17": "euro_league"}
	for k in want:
		var p: PackedStringArray = k.split("-")
		if _comp_of(1997, int(p[0]), int(p[1])) != want[k]:
			return false
	return true


static func _date_key(e: Dictionary) -> int:
	return int(e.get("y", 0)) * 10000 + int(e.get("m", 0)) * 100 + int(e.get("d", 0))


static func _mo_index(e: Dictionary) -> int:
	return int(e.get("y", 0)) * 12 + int(e.get("m", 1)) - 1


func _clamp_month() -> void:
	var idx: int = _month[0] * 12 + (_month[1] - 1)
	idx = clampi(idx, _mo_lo, maxi(_mo_lo, _mo_hi - 1))
	@warning_ignore("integer_division")
	_month = [idx / 12, idx % 12 + 1]


# ---- calendar math -----------------------------------------------------------

static func _wd(y: int, m: int, d: int) -> int:
	## 0 = Sunday .. 6 = Saturday (Godot Time weekday convention).
	var t := Time.get_unix_time_from_datetime_dict(
		{"year": y, "month": m, "day": d, "hour": 12, "minute": 0, "second": 0})
	return int(Time.get_datetime_dict_from_unix_time(int(t)).get("weekday", 0))


static func _days_in(y: int, m: int) -> int:
	var n: int = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m]
	if m == 2 and (y % 4 == 0 and (y % 100 != 0 or y % 400 == 0)):
		n = 29
	return n


## Cells of the (y,m) sheet: {d, col, row} for rows 0..4. A day whose slot lands
## on row >= 5 OVERFLOWS the sheet and is dropped here — witnessed: 31 AUG 1997
## is missing from the AUGUST sheet and appears as SEPTEMBER's leading cell.
static func _sheet_cells(y: int, m: int) -> Array:
	var out: Array = []
	var w0 := _wd(y, m, 1)
	for d in range(1, _days_in(y, m) + 1):
		var idx := w0 + d - 1
		@warning_ignore("integer_division")
		var row := idx / 7
		if row >= 5:
			continue
		out.append({"d": d, "col": idx % 7, "row": row, "y": y, "m": m})
	return out


## Previous-month days that overflowed THEIR sheet, mapped into this sheet's
## leading row-0 cells (witnessed once: 31 AUG in the SEPTEMBER sheet).
static func _carry_cells(y: int, m: int) -> Array:
	var py := y if m > 1 else y - 1
	var pm := m - 1 if m > 1 else 12
	var out: Array = []
	var w0 := _wd(py, pm, 1)
	var lead := _wd(y, m, 1)
	for d in range(1, _days_in(py, pm) + 1):
		var idx := w0 + d - 1
		@warning_ignore("integer_division")
		if idx / 7 >= 5 and idx % 7 < lead:
			out.append({"d": d, "col": idx % 7, "row": 0, "y": py, "m": pm})
	return out


func _comp_of(y: int, m: int, d: int) -> String:
	for e in _entries:
		if int(e.get("y", 0)) == y and int(e.get("m", 0)) == m and int(e.get("d", 0)) == d:
			return str(e.get("comp", ""))
	return ""


func _entry_on(y: int, m: int, d: int) -> Dictionary:
	for e in _entries:
		if int(e.get("y", 0)) == y and int(e.get("m", 0)) == m and int(e.get("d", 0)) == d:
			return e
	return {}


func _next_entries(n: int) -> Array:
	var tk := _date_key(_today)
	var out: Array = []
	for e in _entries:
		if _date_key(e) > tk:
			out.append(e)
			if out.size() >= n:
				break
	return out


## Shades for a competition: witnessed table entry, else derived from the
## legend colour (documented approximation for the un-walked competitions).
func _shades(comp: String) -> Dictionary:
	var base: Dictionary = COMPS.get(comp, {"cell": Color8(192, 192, 192)})
	if base.has("bar1"):
		return base
	var cell: Color = base["cell"]
	return {"cell": cell, "bar1": cell.darkened(0.35), "bar2": cell.darkened(0.2),
		"dark": cell.darkened(0.62), "ink1": Color(0, 0, 0), "ink2": Color(0, 0, 0),
		"month": cell}


# ---- geometry ----------------------------------------------------------------

func _scale() -> float:
	return minf(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0

func _origin(s: float) -> Vector2:
	return Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)

func _to_design(p: Vector2) -> Vector2:
	var s := _scale()
	return (p - _origin(s)) / s

func _hit(d: Vector2) -> String:
	if R_RETURN.has_point(d): return "return"
	if R_RESULTS.has_point(d): return "results"
	if R_TABLES.has_point(d): return "tables"
	if R_ARROW_L.has_point(d): return "prev"
	if R_ARROW_R.has_point(d): return "next"
	return ""


# ---- input -------------------------------------------------------------------

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
	if was == "" or was != _hit(d):
		return
	match was:
		"return":
			back_pressed.emit()
		"results":
			results_pressed.emit()
		"tables":
			tables_pressed.emit()
		"prev":
			_month[1] -= 1
			if _month[1] < 1:
				_month = [_month[0] - 1, 12]
			_clamp_month()
			queue_redraw()
		"next":
			_month[1] += 1
			if _month[1] > 12:
				_month = [_month[0] + 1, 1]
			_clamp_month()
			queue_redraw()


# ---- drawing -----------------------------------------------------------------

## KKITA glyph cells put the ink at rows 3..12 of the cell (DataBaseCard 072
## witness), so a target INK-TOP row t draws with cell top t-3.
func _kk(x: float, ink_top: float, s: String, col: Color, cw := 0.0, center := false) -> void:
	if _fkk == null or s == "":
		return
	var wtxt := _fkk.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var px := x
	if center and cw > 0.0:
		px = x + (cw - wtxt) * 0.5
	draw_string(_fkk, Vector2(px, ink_top - 3 + _fkk.get_ascent(16)), s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)


func _kk_w(s: String) -> float:
	return _fkk.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x if _fkk != null else 0.0


func _draw() -> void:
	var s := _scale()
	draw_set_transform(_origin(s), 0.0, Vector2(s, s))
	if _chrome != null:
		draw_texture_rect(_chrome, Rect2(0, 0, W, H), false)

	# header + "THE CALENDAR" title: BAKED in the verbatim chrome for the witnessed
	# state, so leave them untouched in the baseline (frame-true). Only a divergent
	# career (different club/date/status) repaints the band via draw_match_header +
	# re-blits the title sprite over it.
	if not _baseline:
		if not _header.is_empty():
			PMChrome.draw_match_header(self, "", _header)
		if _title != null:
			draw_texture(_title, Vector2(217, 22))

	# BASELINE VIEW = the witnessed frame-051 state showing its baked AUG/SEP sheets:
	# the whole body is frame-true baked art, so draw NOTHING over it. Any divergence
	# (other career/date, OR the user has paged off the baked AUG 1997 view) redraws
	# the body with the app fonts (un-witnessed approximation).
	var show_baked: bool = _baseline and int(_month[0]) == 1997 and int(_month[1]) == 8
	if not show_baked:
		_clear_body()
		_draw_sheet(0, _month[0], _month[1])
		var ny: int = _month[0] if _month[1] < 12 else _month[0] + 1
		var nm: int = _month[1] + 1 if _month[1] < 12 else 1
		_draw_sheet(1, ny, nm)
		_draw_today_band()
		var nxt := _next_entries(4)
		for i in nxt.size():
			_draw_next_row(i, nxt[i])

	for key_r in [["return", R_RETURN], ["results", R_RESULTS], ["tables", R_TABLES],
			["prev", R_ARROW_L], ["next", R_ARROW_R]]:
		if _press == str(key_r[0]):
			draw_rect(key_r[1], C_PRESS, true)


## Erase the baked frame-051 body text to white before the divergent redraw paints
## the sheets/bands (the app-font approximation) over it.
func _clear_body() -> void:
	for r in CLEAR_TITLE:
		draw_rect(r, Color.WHITE, true)
	for r in CLEAR_CELLS:
		draw_rect(r, Color.WHITE, true)
	draw_rect(CLEAR_TODAY, Color.WHITE, true)
	draw_rect(CLEAR_NEXT, Color.WHITE, true)


func _draw_sheet(slot: int, y: int, m: int) -> void:
	var sx: int = SHEET_X[slot]
	_kk(sx + 2, TITLE_INK_TOP, "%s %d" % [MONTHS[m], y], C_MONTH_RED, 166, true)
	var cells := _sheet_cells(y, m) + _carry_cells(y, m)
	for c in cells:
		var cx: float = sx + CELL_X0 + CELL_PW * int(c["col"])
		var cy: float = CELL_Y0 + CELL_PH * int(c["row"])
		var comp := _comp_of(int(c["y"]), int(c["m"]), int(c["d"]))
		var fill: Color = Color.WHITE if comp == "" else _shades(comp)["cell"]
		var today: bool = int(c["y"]) == int(_today.get("y", 0)) \
			and int(c["m"]) == int(_today.get("m", 0)) and int(c["d"]) == int(_today.get("d", 0))
		if today:
			# witnessed ring (1 AUG): 2px red frame, 1px white ring, no black border
			draw_rect(Rect2(cx - 2, cy - 2, CELL_W + 4, CELL_H + 4), C_MONTH_RED, true)
			draw_rect(Rect2(cx, cy, CELL_W, CELL_H), Color.WHITE, true)
			draw_rect(Rect2(cx + 1, cy + 1, CELL_W - 2, CELL_H - 2), fill, true)
		else:
			draw_rect(Rect2(cx, cy, CELL_W, CELL_H), Color.BLACK, true)
			draw_rect(Rect2(cx + 1, cy + 1, CELL_W - 2, CELL_H - 2), fill, true)
		_draw_digit(cx, cy, int(c["d"]))


func _draw_digit(cx: float, cy: float, d: int) -> void:
	if _f8 == null:
		return
	var t := str(d)
	var wtxt := _f8.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(_f8, Vector2(cx + (CELL_W - wtxt) * 0.5, cy + 3 + _f8.get_ascent(11)), t,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.BLACK)


func _draw_today_band() -> void:
	var e := _entry_on(int(_today.get("y", 0)), int(_today.get("m", 0)), int(_today.get("d", 0)))
	if e.is_empty():
		return   # no fixture today: interior stays blank (un-walked state)
	var sh := _shades(str(e.get("comp", "")))
	# name bar: black border box, competition-colour fill, 30x20 flags at the ends
	draw_rect(TD_NAME, Color.BLACK, true)
	draw_rect(Rect2(100, 233, 338, 20), sh["cell"], true)
	for pair in [[int(e.get("home_flag", -1)), TD_FLAG_H], [int(e.get("away_flag", -1)), TD_FLAG_A]]:
		var ft := PMChrome.flag(pair[0])
		if ft != null:
			draw_texture(ft, pair[1])
	draw_rect(Rect2(130, 233, 1, 20), Color.BLACK, true)
	draw_rect(Rect2(407, 233, 1, 20), Color.BLACK, true)
	var title := "%s - %s" % [_plain(str(e.get("home", ""))), _plain(str(e.get("away", "")))]
	_kk(131, 236, title, C_TODAY_NAME_INK, 276, true)
	# stage bars: black box, two fills, ball cells at both ends, sep row baked black
	draw_rect(TD_BARS, Color.BLACK, true)
	draw_rect(Rect2(128, 259, 283, 15), sh["bar1"], true)
	draw_rect(Rect2(128, 275, 283, 15), sh["bar2"], true)
	if _ball_today != null:
		draw_texture(_ball_today, TD_BALL_L)
		draw_texture(_ball_today, TD_BALL_R)
	_kk(128, 262, str(e.get("comp_name", "")), sh["ink1"], 283, true)
	_kk(128, 278, str(e.get("round", "")), sh["ink2"], 283, true)
	_draw_today_kit(int(e.get("home_id", -1)), TD_KIT_C_L)
	_draw_today_kit(int(e.get("away_id", -1)), TD_KIT_C_R)


static func _plain(name: String) -> String:
	return name.to_upper().trim_suffix(".")


## Witnessed TODAY kits (frame-rendered patches for Juventus/Man Utd); other
## clubs fall back to the 48x64 PMChrome kit centred in the slot — the original
## uses a LARGER kit sprite family not yet exported (documented approximation).
func _draw_today_kit(cid: int, center: Vector2) -> void:
	if _kit_today.has(cid):
		var t: Texture2D = _kit_today[cid]
		draw_texture(t, (center - t.get_size() * 0.5).floor())
		return
	var k := PMChrome.kit(cid)
	if k != null:
		draw_texture(k, (center - k.get_size() * 0.5).floor())


func _draw_next_row(r: int, e: Dictionary) -> void:
	var y0: float = NX_Y0 + NX_PITCH * r
	var sh := _shades(str(e.get("comp", "")))
	var charity := str(e.get("comp", "")) == "charity"
	# ball cell (witnessed: preseason rows carry the ball, the charity row is
	# plain black; other competitions un-walked -> ball)
	draw_rect(Rect2(44, y0 - 1, 30, 33), Color.BLACK, true)
	if not charity and _ball_next != null:
		draw_texture(_ball_next, Vector2(NX_BALL_X, y0))
	# home kit plate
	draw_rect(Rect2(83, y0 - 1, 33, 33), Color.BLACK, true)
	draw_rect(Rect2(84, y0, 31, 31), C_PLATE, true)
	_draw_row_kit(int(e.get("home_id", -1)), NX_KIT_H_X, y0, "h")
	# name bar + the two competition/round bars
	draw_rect(Rect2(115, y0 - 1, 270, 17), Color.BLACK, true)
	draw_rect(Rect2(116, y0, 268, 15), sh["cell"], true)
	var title := "%s - %s" % [str(e.get("home", "")), str(e.get("away", ""))]
	_kk(116, y0 + 3, title, Color.BLACK, 268, true)
	draw_rect(Rect2(115, y0 + 15, 270, 17), Color.BLACK, true)
	draw_rect(Rect2(116, y0 + 16, 133, 15), sh["bar1"], true)
	draw_rect(Rect2(249, y0 + 16, 135, 15), sh["bar2"], true)
	_kk(116, y0 + 19, str(e.get("comp_name", "")), sh["ink1"], 133, true)
	_kk(249, y0 + 19, str(e.get("round", "")), sh["ink2"], 135, true)
	# away kit plate
	draw_rect(Rect2(384, y0 - 1, 33, 33), Color.BLACK, true)
	draw_rect(Rect2(385, y0, 31, 31), C_PLATE, true)
	_draw_row_kit(int(e.get("away_id", -1)), NX_KIT_A_X, y0, "a")
	# date panel: dark fill, white weekday, white day + competition-tinted month
	draw_rect(Rect2(422, y0 - 1, 73, 33), Color.BLACK, true)
	draw_rect(Rect2(423, y0, 71, 31), sh["dark"], true)
	var wd: String = WEEKDAYS[_wd(int(e.get("y", 1997)), int(e.get("m", 8)), int(e.get("d", 1)))]
	_kk(423, y0 + 3, wd, Color.WHITE, 71, true)
	var day := "%d " % int(e.get("d", 1))
	var mon: String = MONTHS[int(e.get("m", 8))].substr(0, 3)
	var x0: float = 423 + (71 - _kk_w(day + mon)) * 0.5
	_kk(x0, y0 + 18, day, Color.WHITE)
	_kk(x0 + _kk_w(day), y0 + 18, mon, sh["month"])


## Witnessed NEXT-row kits use the frame-rendered patches (the original blit
## composes a soft shadow); other clubs fall back to the shadowless NANOESC art.
func _draw_row_kit(cid: int, x: float, y0: float, col: String) -> void:
	var key := "%d%s" % [cid, col]
	if _kit_row.has(key):
		draw_texture(_kit_row[key], Vector2(x, y0))
		return
	var k := PMChrome.nano_kit(cid)
	if k != null:
		draw_texture(k, Vector2(x, y0))
