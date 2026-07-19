extends Control
class_name LeagueTableScreen
## PM98 LEAGUE TABLES (CLASIFICACION) screen, rebuilt FRAME-TRUE from the real game.
##
## BINDING SOURCES:
##   Premier chrome — real-gallery ma_10.png, corroborated by walkthrough frame
##   045_154505 (chrome pixel-identical, MAD 0.00 — see the 2026-07-13 correction
##   in docs/re/league_table_screen_re.md; an earlier claim that no walkthrough
##   frame exists was FALSE).
##   Lower divisions — LIVE-WITNESSED 2026-07-19 (wine campaign, frames in
##   screenshots/wine-captures-2026-07-19-lowerdiv/): FIRST/SECOND/THIRD DIVISION
##   chromes baked 1:1 from the original's own screens (24-row grid, PROMOTION/
##   PLAY-OFFS/RELEGATION pennant columns, per-division selected tab), cut by
##   tools/re/build_leaguetable_division_chromes.py.
##
## The static chrome per division is the ORIGINAL pixels with only the dynamic
## layers blanked (rows, LEADER kit, date digits, plaque). This scene blits the
## selected division's chrome, OVERDRAWS the live barra (PMChrome.draw_header),
## and redraws the standings rows + movement markers + leader kit + date value.
##
## Movement markers (witnessed lt_wk2_premier): the small box beside POS is the
## POSITION-CHANGE marker — grey square (no change), white UP triangle, red DOWN
## triangle vs the previous table revision. ma_10's "placeholder square" was this
## marker in its no-change state; the rows hold NO crest/kit (the old kit draw
## was an invention — removed).
##
## Division tabs are LIVE (witnessed hit boxes x525..624, y194/224/254/284):
## tapping First/Second/Third shows that division's REAL simulated table
## (Career's living pyramid). Without pyramid data (season-sim overlay) the
## tabs stay inert.
##
## Interactive: RETURN dismisses; a standings row opens that club's squad;
## GOAL SCORERS opens the SELECTED division's chart (witnessed division-scoped).

signal back_pressed              # RETURN -> dismiss
signal club_selected(id: int)    # a standings row tap -> open that club's squad
signal scorers_pressed           # GOAL SCORERS -> the selected division's chart

const W := 640
const H := 480

# ---- 20-row grid (Premier, measured off ma_10) ----------------------------
const ROW_Y0 := 114
const ROW_PITCH := 16
const ROW_H := 14                     # coloured band (2px white gap below, baked)
# ---- 24-row grid (lower divisions, measured off the witnessed frames) -----
const ROW24_Y0 := 115
const ROW24_PITCH := 15
const ROW24_H := 12
const POS_REGION := Rect2(73, 0, 26, ROW_H)   # POS number sub-region (x only; y set live)
const MARKER_X := 106                 # movement marker slot (10x9 sprite)
const NAME_X := 127
const NAME_REGION_X0 := 123
const NAME_REGION_X1 := 270
# stat cells: [left_x, width]; order P W D L GF GA (identical on both grids —
# separators verified at 270/295/320/345/370/406/442/482 on the Div-1 frame)
const STAT_CELLS := [[271, 23], [296, 23], [321, 23], [346, 23], [371, 34], [407, 34]]
const PTS_CELL := [443, 38]
const SEP_XS := [270, 295, 320, 345, 370, 406, 442, 482]
const LEADER_KIT_BOX := Rect2(553, 97, 51, 65)
const DATE_RIGHT := 447                # right edge for the DD/MM/YYYY value
const DATE_Y := 76
const RETURN_BTN := Rect2(525, 423, 99, 25)
const SCORERS_BTN := Rect2(525, 354, 99, 24)   # GOAL SCORERS (baked)
# Division tabs (witnessed): Premier/First/Second/Third, 30px apart.
const TAB_X := 525
const TAB_W := 100
const TAB_H := 26
const TAB_YS := {1: 194, 2: 224, 3: 254, 4: 284}

# ---- palette sampled off ma_10 (leaguetable_chrome.json "samples") ----
# normal (non-managed) row
const C_POS_BG := Color8(180, 200, 220)
const C_POS_INK := Color8(0, 0, 128)
const C_NAME_BG := Color8(0, 0, 128)
const C_NAME_INK := Color8(255, 255, 255)
const C_SEP := Color8(0, 0, 0)
# per-column cell [bg, ink] for P W D L GF GA
const CELL_BG := [Color8(220, 220, 220), Color8(180, 200, 220), Color8(212, 223, 170),
	Color8(212, 191, 170), Color8(180, 200, 220), Color8(212, 191, 170)]
const CELL_INK := [Color8(128, 128, 128), Color8(100, 120, 140), Color8(127, 159, 85),
	Color8(170, 127, 85), Color8(100, 120, 140), Color8(170, 127, 85)]
const C_PTS_BG := Color8(72, 30, 2)
const C_PTS_INK := Color8(255, 223, 0)
# managed (my-club) row — the dark/saturated variant
const C_MINE_POS_BG := Color8(42, 63, 170)
const C_MINE_POS_INK := Color8(166, 202, 240)
const C_MINE_NAME_BG := Color8(0, 0, 0)
const MINE_CELL_BG := [Color8(80, 80, 80), Color8(80, 100, 120), Color8(80, 110, 5),
	Color8(85, 0, 0), Color8(80, 100, 120), Color8(170, 127, 85)]
const MINE_CELL_INK := [Color8(192, 192, 192), Color8(166, 202, 240), Color8(170, 223, 170),
	Color8(255, 31, 0), Color8(166, 202, 240), Color8(212, 191, 170)]
const C_MINE_PTS_BG := Color8(150, 0, 0)
const C_MINE_PTS_INK := Color8(255, 255, 255)
# date stepper
const C_DATE_INK := Color8(180, 210, 50)

var _chromes: Dictionary = {}   # tier -> Texture2D
var _markers: Dictionary = {}   # "up"/"down"/"flat" -> Texture2D
var _f12: Font
var _f8: Font

var _rows: Array = []
var _prev: Dictionary = {}      # club_id -> previous-revision position (markers)
var _title_left: String = ""
var _manager: String = ""       # career manager name for the two-line barra plaque ("" = sim table)
var _season: String = "1997-98"
var _week_label: String = ""
var _tier: int = 1              # the MANAGER's division (barra plaque; witnessed to stay fixed)
var _selected: int = 1          # the division being VIEWED (tab state)
var _my_id: int = -1
var _provider: Callable = Callable()   # tier:int -> {rows: Array, prev: Dictionary}; invalid = tabs inert


func _ready() -> void:
	for t in [1, 2, 3, 4]:
		var p := "res://art/screens/leaguetable/%s" % (
			"chrome.png" if t == 1 else "chrome_%s.png" % ["first", "second", "third"][t - 2])
		_chromes[t] = load(p)
	for m in ["up", "down", "flat"]:
		_markers[m] = load("res://art/screens/leaguetable/marker_%s.png" % m)
	_f12 = PMChrome.font("12")
	_f8 = PMChrome.font("8")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size = Vector2(W, H)
	gui_input.connect(_on_input)
	queue_redraw()


func setup(rows: Array, title_left: String, season: String, week_label: String,
		tier: int = 1, my_id: int = -1, manager: String = "") -> void:
	_rows = rows
	_title_left = title_left
	_season = season
	_week_label = week_label
	_tier = tier
	_selected = tier
	_my_id = my_id
	_manager = manager
	queue_redraw()


## Wire the living pyramid: `provider.call(tier)` returns that division's live
## {rows, prev}; the witnessed division tabs then switch tables for real.
## The screen opens on the manager's division (witnessed default).
func set_pyramid(provider: Callable, prev: Dictionary = {}) -> void:
	_provider = provider
	_prev = prev
	queue_redraw()


func selected_tier() -> int:
	return _selected


# ---- input ---------------------------------------------------------------

func _to_design(p: Vector2) -> Vector2:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	return (p - Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5)) / s


func _on_input(e: InputEvent) -> void:
	if not (e is InputEventScreenTouch or e is InputEventMouseButton):
		return
	if not e.pressed:
		return
	var d := _to_design(e.position)
	if RETURN_BTN.has_point(d):
		back_pressed.emit()
		return
	if SCORERS_BTN.has_point(d):
		scorers_pressed.emit()
		return
	for t in TAB_YS:
		if Rect2(TAB_X, TAB_YS[t], TAB_W, TAB_H).has_point(d):
			_select_division(int(t))
			return
	var pitch := _pitch()
	var rh := _row_h()
	for i in _rows.size():
		var rr := Rect2(73, _row_y0() + i * pitch, 482 - 73, rh)
		if rr.has_point(d):
			var id := int((_rows[i] as Dictionary).get("id", -1))
			if id >= 0:
				club_selected.emit(id)
			return


## Tab tap: fetch that division's live table off the provider. Without pyramid
## data (or for an empty division) the tab is inert — never invents a table.
func _select_division(t: int) -> void:
	if t == _selected:
		return
	if not _provider.is_valid():
		return
	var data: Dictionary = _provider.call(t)
	var rows: Array = data.get("rows", [])
	if rows.is_empty():
		return
	_selected = t
	_rows = rows
	_prev = data.get("prev", {})
	queue_redraw()


# ---- drawing -------------------------------------------------------------

func _row_y0() -> int:
	return ROW_Y0 if _selected == 1 else ROW24_Y0

func _pitch() -> int:
	return ROW_PITCH if _selected == 1 else ROW24_PITCH

func _row_h() -> int:
	return ROW_H if _selected == 1 else ROW24_H


func _draw() -> void:
	var s: float = min(size.x / W, size.y / H) if size.x > 0 and size.y > 0 else 1.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.14), true)
	draw_set_transform(Vector2((size.x - W * s) * 0.5, (size.y - H * s) * 0.5), 0.0, Vector2(s, s))

	# Baked chrome of the SELECTED division (marble bg, panel, subtitle, headers,
	# zone pennants, tabs with the right one selected, buttons).
	var chrome: Texture2D = _chromes.get(_selected)
	if chrome != null:
		draw_texture(chrome, Vector2.ZERO)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.18, 0.40), true)

	# Live barra over the baked header — manager/club/date/week stay the
	# MANAGER's (witnessed: browsing Third keeps the Premier/Week plaque).
	PMChrome.draw_header(self, "LEAGUE TABLES", _manager, _title_left, _div_name(_tier),
		_season, _week_num(), _my_id)

	_draw_date()
	_draw_rows()
	_draw_leader_kit()


## Redraw the Date-stepper value (green DD/MM/YYYY over the navy box). The
## original's box shows the date of the LAST TABLE REVISION (witnessed 11/8 vs
## calendar Tue 12/8 at week 2; ma_10 27/11 vs Sat 29/11) — our weekly model
## revises on the manager's Saturday, so the calendar-sheet date stands in
## (documented approximation).
func _draw_date() -> void:
	var d := PMChrome.date_parts(_season, _week_num())
	# UNPADDED D/M/YYYY — witnessed "9/8/1997" (w5_lt_default) / "27/11/1997" (ma_10).
	var ds := "%d/%d/%d" % [int(d["day"]), _MONTH_NUM.get(d["mon"], 1), int(d["year"])]
	PMChrome.text(self, _f12, DATE_RIGHT, DATE_Y, ds, C_DATE_INK, 12, 2)


func _draw_rows() -> void:
	var y0 := _row_y0()
	var pitch := _pitch()
	var rh := _row_h()
	var marker_dy := 3 if _selected == 1 else 2
	for i in _rows.size():
		if i >= (20 if _selected == 1 else 24):
			break
		var r: Dictionary = _rows[i]
		var y := y0 + i * pitch
		var mine := int(r.get("id", -1)) == _my_id and _my_id >= 0

		# Region 1: POS number + movement marker (witnessed: NO crest in rows).
		draw_rect(Rect2(73, y, 122 - 73, rh), C_MINE_POS_BG if mine else C_POS_BG, true)
		PMChrome.text(self, _f12, POS_REGION.position.x, y + 1, str(i + 1),
			C_MINE_POS_INK if mine else C_POS_INK, 12, 1, POS_REGION.size.x)
		_draw_marker(int(r.get("id", -1)), i + 1, y + marker_dy)

		# Region 2: team name plate.
		draw_rect(Rect2(NAME_REGION_X0, y, NAME_REGION_X1 - NAME_REGION_X0, rh),
			C_MINE_NAME_BG if mine else C_NAME_BG, true)
		PMChrome.text(self, _f12, NAME_X, y + 1, str(r.get("name", "?")),
			C_NAME_INK, 12, 0, NAME_REGION_X1 - NAME_X - 2)

		# Stat cells P W D L GF GA.
		var vals := [r.get("P", 0), r.get("W", 0), r.get("D", 0), r.get("L", 0),
			r.get("GF", 0), r.get("GA", 0)]
		for c in 6:
			var cx: int = STAT_CELLS[c][0]
			var cw: int = STAT_CELLS[c][1]
			draw_rect(Rect2(cx, y, cw, rh), (MINE_CELL_BG[c] if mine else CELL_BG[c]) as Color, true)
			PMChrome.text(self, _f12, cx, y + 1, str(int(vals[c])),
				(MINE_CELL_INK[c] if mine else CELL_INK[c]) as Color, 12, 1, cw)

		# PTS cell.
		draw_rect(Rect2(PTS_CELL[0], y, PTS_CELL[1], rh), C_MINE_PTS_BG if mine else C_PTS_BG, true)
		PMChrome.text(self, _f12, PTS_CELL[0], y + 1, str(int(r.get("Pts", 0))),
			C_MINE_PTS_INK if mine else C_PTS_INK, 12, 1, PTS_CELL[1])

		# Black 1px column separators (the frame's cell borders).
		for sx in SEP_XS:
			draw_rect(Rect2(sx, y, 1, rh), C_SEP, true)


## The witnessed movement marker: grey square (no change / no prior revision),
## white UP triangle, red DOWN triangle vs the previous revision's position.
func _draw_marker(id: int, pos: int, y: int) -> void:
	var key := "flat"
	if _prev.has(id):
		var was := int(_prev[id])
		if pos < was:
			key = "up"
		elif pos > was:
			key = "down"
	var tex: Texture2D = _markers.get(key)
	if tex != null:
		draw_texture(tex, Vector2(MARKER_X, y))


## The LEADER card kit = the current leader once the table has a played game;
## the card stays EMPTY pre-play (witnessed w5_lt_premier: blank card at P=0).
func _draw_leader_kit() -> void:
	if _rows.size() > 0 and int((_rows[0] as Dictionary).get("P", 0)) > 0:
		PMChrome.draw_crest(self, int((_rows[0] as Dictionary).get("id", -1)), LEADER_KIT_BOX)


# ---- helpers -------------------------------------------------------------

const _MONTH_NUM := {"January": 1, "February": 2, "March": 3, "April": 4, "May": 5,
	"June": 6, "July": 7, "August": 8, "September": 9, "October": 10,
	"November": 11, "December": 12}


## Parse the 1-based week number out of "Week 17" / "Final"; 0 when unknown.
func _week_num() -> int:
	var digits := ""
	for ch in _week_label:
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0


## The witnessed barra plaque short-forms ("1st Div." on the w5 career header).
func _div_name(tier: int) -> String:
	return {1: "Premier", 2: "1st Div.", 3: "2nd Div.", 4: "3rd Div."}.get(tier, "League")
